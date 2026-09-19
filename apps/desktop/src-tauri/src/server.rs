use axum::{
    extract::{Multipart, Query, State},
    http::{header, HeaderMap, HeaderValue, StatusCode},
    response::{IntoResponse, Response},
    routing::{get, post},
    Json, Router,
};
use chrono::Utc;
use serde::Deserialize;
use std::io::Cursor;
use std::net::SocketAddr;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::sync::{oneshot, Mutex as TokioMutex};
use tower_http::cors::{Any, CorsLayer};

use std::collections::{HashMap, VecDeque};
use std::sync::Mutex as StdMutex;

use crate::indexer::Indexer;
use crate::models::{
    DeviceStatus, DeviceStatusResponse, ErrorResponse, UploadResponse,
};

/// In-memory LRU cache for hot thumbnails (holding up to 64MB in RAM).
pub struct ThumbnailMemoryCache {
    max_bytes: usize,
    inner: StdMutex<MemoryCacheInner>,
}

struct MemoryCacheInner {
    current_bytes: usize,
    entries: HashMap<String, Vec<u8>>,
    order: VecDeque<String>,
}

impl Default for ThumbnailMemoryCache {
    fn default() -> Self {
        Self::new(64 * 1024 * 1024) // 64MB default
    }
}

impl ThumbnailMemoryCache {
    pub fn new(max_bytes: usize) -> Self {
        Self {
            max_bytes,
            inner: StdMutex::new(MemoryCacheInner {
                current_bytes: 0,
                entries: HashMap::new(),
                order: VecDeque::new(),
            }),
        }
    }

    pub fn get(&self, key: &str) -> Option<Vec<u8>> {
        let mut inner = self.inner.lock().ok()?;
        if let Some(bytes) = inner.entries.get(key) {
            let b = bytes.clone();
            if let Some(pos) = inner.order.iter().position(|k| k == key) {
                inner.order.remove(pos);
            }
            inner.order.push_back(key.to_string());
            Some(b)
        } else {
            None
        }
    }

    pub fn insert(&self, key: String, bytes: Vec<u8>) {
        let mut inner = match self.inner.lock() {
            Ok(g) => g,
            Err(_) => return,
        };

        let new_len = bytes.len();
        if new_len > self.max_bytes {
            return;
        }

        while inner.current_bytes + new_len > self.max_bytes && !inner.order.is_empty() {
            if let Some(oldest_key) = inner.order.pop_front() {
                if let Some(old_val) = inner.entries.remove(&oldest_key) {
                    inner.current_bytes = inner.current_bytes.saturating_sub(old_val.len());
                }
            }
        }

        if let Some(old_val) = inner.entries.insert(key.clone(), bytes) {
            inner.current_bytes = inner.current_bytes.saturating_sub(old_val.len());
        }
        inner.current_bytes += new_len;
        if let Some(pos) = inner.order.iter().position(|k| k == &key) {
            inner.order.remove(pos);
        }
        inner.order.push_back(key);
    }
}

/// Shared state available to every Axum request handler.
#[derive(Clone)]
pub struct ServerState {
    pub indexer: Arc<TokioMutex<Indexer>>,
    /// Directory where generated thumbnail JPEGs are cached on disk.
    pub thumb_cache_dir: PathBuf,
    /// In-memory LRU cache for hot thumbnails
    pub memory_cache: Arc<ThumbnailMemoryCache>,
}

impl ServerState {
    pub fn new(indexer: Arc<TokioMutex<Indexer>>, thumb_cache_dir: PathBuf) -> Self {
        Self {
            indexer,
            thumb_cache_dir,
            memory_cache: Arc::new(ThumbnailMemoryCache::default()),
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct ImageQueryParams {
    pub id: Option<String>,
    pub path: Option<String>,
    pub thumbnail: Option<bool>,
    pub max_width: Option<u32>,
    pub max_height: Option<u32>,
}

#[derive(Debug, Deserialize)]
pub struct ManifestQueryParams {
    pub since: Option<String>,
}

pub struct ServerHandle {
    pub port: u16,
    pub shutdown_tx: Option<oneshot::Sender<()>>,
    pub udp_shutdown_tx: Option<oneshot::Sender<()>>,
}

pub fn create_app(state: ServerState) -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    Router::new()
        .route("/health", get(handle_health))
        .route("/api/manifest", get(handle_get_manifest))
        .route("/image", get(handle_get_image))
        .route("/upload", post(handle_upload_photo))
        .route("/api/device-status", post(handle_device_status))
        .route("/api/people", get(handle_get_people))
        .layer(cors)
        .with_state(state)
}

async fn handle_health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "ok",
        "service": "lifeframe",
        "version": "1.0.0"
    }))
}

pub async fn start_server(
    indexer: Arc<TokioMutex<Indexer>>,
    requested_port: u16,
    thumb_cache_dir: PathBuf,
) -> Result<ServerHandle, Box<dyn std::error::Error + Send + Sync>> {
    std::fs::create_dir_all(&thumb_cache_dir).ok();

    let state = ServerState::new(indexer, thumb_cache_dir);
    let app = create_app(state);

    let mut port = requested_port;
    let listener = loop {
        let addr = SocketAddr::from(([0, 0, 0, 0], port));
        match tokio::net::TcpListener::bind(addr).await {
            Ok(l) => break l,
            Err(e) if port < requested_port + 20 => {
                eprintln!("Port {port} in use or failed ({e}), trying {}", port + 1);
                port += 1;
            }
            Err(e) => return Err(Box::new(e)),
        }
    };
    let bound_port = listener.local_addr()?.port();

    let (shutdown_tx, shutdown_rx) = oneshot::channel::<()>();
    let (udp_shutdown_tx, mut udp_shutdown_rx) = oneshot::channel::<()>();

    tokio::spawn(async move {
        axum::serve(listener, app)
            .with_graceful_shutdown(async {
                let _ = shutdown_rx.await;
            })
            .await
            .ok();
    });

    // Spawn UDP discovery responder on port 8081
    let udp_port = 8081;
    tokio::spawn(async move {
        match tokio::net::UdpSocket::bind(format!("0.0.0.0:{}", udp_port)).await {
            Ok(socket) => {
                let mut buf = [0u8; 1024];
                loop {
                    tokio::select! {
                        _ = &mut udp_shutdown_rx => {
                            break;
                        }
                        res = socket.recv_from(&mut buf) => {
                            match res {
                                Ok((len, peer_addr)) => {
                                    let msg = String::from_utf8_lossy(&buf[..len]);
                                    if msg.trim() == "LIFEFRAME_DISCOVERY" {
                                        let local_ip = local_ip_address::local_ip()
                                            .map(|ip| ip.to_string())
                                            .unwrap_or_else(|_| "127.0.0.1".to_string());

                                        let resp = serde_json::json!({
                                            "ip": local_ip,
                                            "port": bound_port,
                                            "name": "Lifeframe Desktop",
                                            "server_id": "lifeframe-desktop-server"
                                        });

                                        let resp_str = resp.to_string();
                                        let _ = socket.send_to(resp_str.as_bytes(), peer_addr).await;
                                    }
                                }
                                Err(_) => break,
                            }
                        }
                    }
                }
            }
            Err(e) => {
                eprintln!("Failed to bind UDP discovery socket on port {}: {}", udp_port, e);
            }
        }
    });

    Ok(ServerHandle {
        port: bound_port,
        shutdown_tx: Some(shutdown_tx),
        udp_shutdown_tx: Some(udp_shutdown_tx),
    })
}

async fn handle_get_manifest(
    State(state): State<ServerState>,
    Query(_params): Query<ManifestQueryParams>,
) -> Result<Response, (StatusCode, Json<ErrorResponse>)> {
    let indexer = state.indexer.lock().await;

    match indexer.get_manifest() {
        Ok(manifest) => Ok(Json(manifest).into_response()),
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                code: "DB_ERROR".to_string(),
                message: e.to_string(),
                details: None,
            }),
        )),
    }
}

// ─── Thumbnail caching & Multi-tier Store ────────────────────────────────────

fn get_tier_label(w: u32, h: u32) -> String {
    let max_dim = std::cmp::max(w, h);
    if max_dim <= 256 {
        "256".to_string()
    } else if max_dim <= 720 {
        "720".to_string()
    } else {
        format!("{w}x{h}")
    }
}

/// Returns the multi-tier hash-indexed thumbnail path.
/// Format: `%APPDATA%/Lifeframe/thumbnails/{short_hash}_{size}.jpg`
pub fn thumb_cache_path(cache_dir: &Path, source: &Path, w: u32, h: u32) -> PathBuf {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(source.to_string_lossy().as_bytes());
    let hash_hex = format!("{:x}", hasher.finalize());
    let short_hash = &hash_hex[..16];
    let tier = get_tier_label(w, h);
    cache_dir.join(format!("{short_hash}_{tier}.jpg"))
}

/// Legacy fallback path format: `{short_hash}_{w}x{h}.jpg`
pub fn legacy_thumb_cache_path(cache_dir: &Path, source: &Path, w: u32, h: u32) -> PathBuf {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(source.to_string_lossy().as_bytes());
    let hash_hex = format!("{:x}", hasher.finalize());
    let short_hash = &hash_hex[..16];
    cache_dir.join(format!("{short_hash}_{w}x{h}.jpg"))
}

/// Generates a JPEG thumbnail at `max_w × max_h` and saves it to `cache_path`.
/// First attempts fast-path embedded EXIF preview before falling back to full image decoding.
pub fn generate_and_cache_thumbnail(
    source: &Path,
    cache_path: &Path,
    max_w: u32,
    max_h: u32,
) -> Option<Vec<u8>> {
    // ── 6.1.1 FAST PATH: Try embedded EXIF preview directly ──
    if let Some(embedded_bytes) = crate::exif::extract_exif_thumbnail(source) {
        if let Ok(embedded_img) = image::load_from_memory_with_format(&embedded_bytes, image::ImageFormat::Jpeg) {
            let resized = embedded_img.thumbnail(max_w, max_h);
            let mut buffer = Cursor::new(Vec::new());
            if resized.write_to(&mut buffer, image::ImageFormat::Jpeg).is_ok() {
                let bytes = buffer.into_inner();
                std::fs::write(cache_path, &bytes).ok();
                return Some(bytes);
            }
        }
    }

    // ── FALLBACK PATH: Decode full image ──
    let img = image::open(source).ok()?;
    let resized = img.thumbnail(max_w, max_h);
    let mut buffer = Cursor::new(Vec::new());
    resized
        .write_to(&mut buffer, image::ImageFormat::Jpeg)
        .ok()?;
    let bytes = buffer.into_inner();
    // Persist to disk (ignore errors — cache is best-effort)
    std::fs::write(cache_path, &bytes).ok();
    Some(bytes)
}

// ─── Image handler ─────────────────────────────────────────────────────────────

async fn handle_get_image(
    State(state): State<ServerState>,
    Query(params): Query<ImageQueryParams>,
) -> Result<Response, (StatusCode, Json<ErrorResponse>)> {
    // ── Resolve the file path ─────────────────────────────────────────────────
    let target_path = {
        let indexer = state.indexer.lock().await;

        // Try to look up via id or relative_path in the DB
        let photo = if let Some(ref id) = params.id {
            indexer.get_photo_by_id(id).ok().flatten()
        } else if let Some(ref path) = params.path {
            indexer.get_photo_by_path(path).ok().flatten()
        } else {
            None
        };

        if let Some(p) = photo {
            // First try resolving via the photo's recorded library_path
            let mut found: Option<PathBuf> = None;
            let rel = &p.relative_path;

            if let Some(ref lib_path) = p.library_path {
                let candidate = Path::new(lib_path).join(rel);
                if candidate.exists() {
                    found = Some(candidate);
                }
            }

            if found.is_none() {
                // Resolve using all registered library roots (find first that contains the file)
                let roots = indexer
                    .get_library_paths()
                    .unwrap_or_else(|_| vec![indexer.get_storage_root().to_path_buf()]);

                for root in &roots {
                    let candidate = root.join(rel);
                    if candidate.exists() {
                        found = Some(candidate);
                        break;
                    }
                }
            }
            // Fallback to legacy storage_root
            found.unwrap_or_else(|| indexer.get_storage_root().join(rel))
        } else if let Some(ref raw_path) = params.path {
            // Raw path not in DB — try all library roots
            let roots = indexer
                .get_library_paths()
                .unwrap_or_else(|_| vec![indexer.get_storage_root().to_path_buf()]);
            let mut found: Option<PathBuf> = None;
            for root in &roots {
                let candidate = root.join(raw_path);
                if candidate.exists() {
                    found = Some(candidate);
                    break;
                }
            }
            found.unwrap_or_else(|| {
                // Last resort: treat as absolute path
                PathBuf::from(raw_path)
            })
        } else {
            return Err((
                StatusCode::BAD_REQUEST,
                Json(ErrorResponse {
                    code: "MISSING_PARAM".to_string(),
                    message: "Provide either 'id' or 'path' query parameter".to_string(),
                    details: None,
                }),
            ));
        }
    };

    if !target_path.exists() {
        return Err((
            StatusCode::NOT_FOUND,
            Json(ErrorResponse {
                code: "FILE_NOT_FOUND".to_string(),
                message: format!("File {:?} does not exist", target_path.file_name()),
                details: None,
            }),
        ));
    }

    // ── Thumbnail path ────────────────────────────────────────────────────────
    let is_thumbnail = params.thumbnail.unwrap_or(false);
    let max_w = params.max_width.unwrap_or(if is_thumbnail { 400 } else { 0 });
    let max_h = params.max_height.unwrap_or(if is_thumbnail { 400 } else { 0 });

    if is_thumbnail || max_w > 0 || max_h > 0 {
        let w = if max_w > 0 { max_w } else { 400 };
        let h = if max_h > 0 { max_h } else { 400 };
        let mem_key = format!("{}:{}:{}", target_path.to_string_lossy(), w, h);

        // ── 1. In-Memory LRU Cache check (0ms perceptual lag) ────────────────
        if let Some(cached_bytes) = state.memory_cache.get(&mem_key) {
            let mut headers = HeaderMap::new();
            headers.insert(header::CONTENT_TYPE, HeaderValue::from_static("image/jpeg"));
            headers.insert(header::CACHE_CONTROL, HeaderValue::from_static("public, max-age=31536000, immutable"));
            headers.insert(header::CONNECTION, HeaderValue::from_static("keep-alive"));
            headers.insert(header::ETAG, HeaderValue::from_str(&format!("\"{:x}\"", cached_bytes.len())).unwrap());
            return Ok((headers, cached_bytes).into_response());
        }

        let cache_path = thumb_cache_path(&state.thumb_cache_dir, &target_path, w, h);
        let legacy_path = legacy_thumb_cache_path(&state.thumb_cache_dir, &target_path, w, h);

        // ── 2. Disk Cache check ──────────────────────────────────────────────
        let disk_path = if cache_path.exists() {
            Some(cache_path.clone())
        } else if legacy_path.exists() {
            Some(legacy_path)
        } else {
            None
        };

        if let Some(dp) = disk_path {
            if let Ok(cached_bytes) = tokio::fs::read(&dp).await {
                // Store in memory LRU cache for future hot hits
                state.memory_cache.insert(mem_key, cached_bytes.clone());

                let mut headers = HeaderMap::new();
                headers.insert(
                    header::CONTENT_TYPE,
                    HeaderValue::from_static("image/jpeg"),
                );
                headers.insert(
                    header::CACHE_CONTROL,
                    HeaderValue::from_static("public, max-age=31536000, immutable"),
                );
                headers.insert(header::CONNECTION, HeaderValue::from_static("keep-alive"));
                headers.insert(header::ETAG, HeaderValue::from_str(&format!("\"{:x}\"", cached_bytes.len())).unwrap());
                return Ok((headers, cached_bytes).into_response());
            }
        }

        // ── 3. Generate thumbnail on a blocking worker thread ────────────────
        let target_path_clone = target_path.clone();
        let cache_path_clone = cache_path.clone();
        let thumb_bytes = tokio::task::spawn_blocking(move || {
            generate_and_cache_thumbnail(&target_path_clone, &cache_path_clone, w, h)
        })
        .await
        .ok()
        .flatten();

        if let Some(bytes) = thumb_bytes {
            // Populate memory cache
            state.memory_cache.insert(mem_key, bytes.clone());

            let mut headers = HeaderMap::new();
            headers.insert(
                header::CONTENT_TYPE,
                HeaderValue::from_static("image/jpeg"),
            );
            headers.insert(
                header::CACHE_CONTROL,
                HeaderValue::from_static("public, max-age=31536000, immutable"),
            );
            headers.insert(header::CONNECTION, HeaderValue::from_static("keep-alive"));
            headers.insert(header::ETAG, HeaderValue::from_str(&format!("\"{:x}\"", bytes.len())).unwrap());
            return Ok((headers, bytes).into_response());
        }
        // If thumbnail generation failed, fall through to serve the original
    }

    // ── Serve original full-size image ────────────────────────────────────────
    match tokio::fs::read(&target_path).await {
        Ok(bytes) => {
            let mime = match target_path
                .extension()
                .and_then(|s| s.to_str())
                .unwrap_or("")
            {
                "png" => "image/png",
                "webp" => "image/webp",
                _ => "image/jpeg",
            };
            let mut headers = HeaderMap::new();
            headers.insert(
                header::CONTENT_TYPE,
                HeaderValue::from_str(mime).unwrap(),
            );
            headers.insert(
                header::CACHE_CONTROL,
                HeaderValue::from_static("public, max-age=3600"),
            );
            headers.insert(header::CONNECTION, HeaderValue::from_static("keep-alive"));
            headers.insert(header::ETAG, HeaderValue::from_str(&format!("\"{:x}\"", bytes.len())).unwrap());
            Ok((headers, bytes).into_response())
        }
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                code: "READ_ERROR".to_string(),
                message: e.to_string(),
                details: None,
            }),
        )),
    }
}

async fn handle_upload_photo(
    State(state): State<ServerState>,
    mut multipart: Multipart,
) -> Result<(StatusCode, Json<UploadResponse>), (StatusCode, Json<ErrorResponse>)> {
    let mut file_data: Option<Vec<u8>> = None;
    let mut relative_path = String::new();
    let mut album_name = String::new();

    while let Ok(Some(field)) = multipart.next_field().await {
        let name = field.name().unwrap_or("").to_string();
        if name == "file" {
            let filename = field.file_name().unwrap_or("upload.jpg").to_string();
            if relative_path.is_empty() {
                relative_path = filename;
            }
            if let Ok(bytes) = field.bytes().await {
                file_data = Some(bytes.to_vec());
            }
        } else if name == "relative_path" {
            if let Ok(text) = field.text().await {
                relative_path = text;
            }
        } else if name == "album_id" || name == "album" {
            if let Ok(text) = field.text().await {
                album_name = text;
            }
        }
    }

    let bytes = match file_data {
        Some(b) => b,
        None => {
            return Err((
                StatusCode::BAD_REQUEST,
                Json(ErrorResponse {
                    code: "MISSING_FILE".to_string(),
                    message: "No file field found in multipart request".to_string(),
                    details: None,
                }),
            ));
        }
    };

    let storage_root = {
        let indexer = state.indexer.lock().await;
        indexer.get_storage_root().to_path_buf()
    };

    if relative_path.is_empty() {
        relative_path = format!("Uploads/{}.jpg", Utc::now().timestamp());
    } else if !album_name.is_empty() && !relative_path.contains('/') {
        relative_path = format!("{}/{}", album_name, relative_path);
    }

    let full_path = storage_root.join(&relative_path);
    if let Some(parent) = full_path.parent() {
        tokio::fs::create_dir_all(parent).await.ok();
    }

    tokio::fs::write(&full_path, &bytes).await.map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                code: "WRITE_ERROR".to_string(),
                message: e.to_string(),
                details: None,
            }),
        )
    })?;

    // Index the newly uploaded file into SQLite
    {
        let indexer = state.indexer.lock().await;
        let rel_str = relative_path.replace('\\', "/");
        let storage_root_str = storage_root.to_string_lossy().replace('\\', "/");
        let _ = indexer.index_single_file(&full_path, &rel_str, Some(&storage_root_str));
    }

    Ok((
        StatusCode::CREATED,
        Json(UploadResponse {
            success: true,
            photo_id: uuid::Uuid::new_v4().to_string(),
            relative_path,
            message: "Photo uploaded successfully".to_string(),
        }),
    ))
}

async fn handle_device_status(
    State(state): State<ServerState>,
    Json(payload): Json<DeviceStatus>,
) -> Result<Json<DeviceStatusResponse>, (StatusCode, Json<ErrorResponse>)> {
    let indexer = state.indexer.lock().await;

    indexer.record_device_status(&payload).map_err(|e| {
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                code: "DB_ERROR".to_string(),
                message: e.to_string(),
                details: None,
            }),
        )
    })?;

    Ok(Json(DeviceStatusResponse {
        success: true,
        message: format!("Device {} registered", payload.device_name),
        server_time: Utc::now().to_rfc3339(),
    }))
}

async fn handle_get_people(
    State(state): State<ServerState>,
) -> Result<Response, (StatusCode, Json<ErrorResponse>)> {
    let indexer = state.indexer.lock().await;

    match indexer.get_all_people() {
        Ok(people) => Ok(Json(people).into_response()),
        Err(e) => Err((
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(ErrorResponse {
                code: "DB_ERROR".to_string(),
                message: e.to_string(),
                details: None,
            }),
        )),
    }
}
