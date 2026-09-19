use axum::http::{Request, StatusCode};
use lifeframe_desktop_lib::indexer::Indexer;
use lifeframe_desktop_lib::server::{create_app, ServerState};
use serde_json::Value;
use std::io::Cursor;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;
use tower::ServiceExt;

fn create_sample_jpeg() -> Vec<u8> {
    let img = image::RgbImage::new(16, 16);
    let mut buf = Cursor::new(Vec::new());
    img.write_to(&mut buf, image::ImageFormat::Jpeg)
        .expect("Failed to create sample JPEG");
    buf.into_inner()
}

async fn get_body_bytes(response: axum::response::Response) -> axum::body::Bytes {
    axum::body::to_bytes(response.into_body(), usize::MAX)
        .await
        .expect("Failed to read response body")
}

#[tokio::test]
async fn test_e2e_health_check() {
    let storage_root = PathBuf::from("./target/test_e2e_health");
    let thumb_dir = PathBuf::from("./target/test_e2e_health_thumbs");
    std::fs::create_dir_all(&storage_root).ok();
    let indexer = Indexer::in_memory(&storage_root).expect("Indexer initialization");
    let state = ServerState::new(Arc::new(Mutex::new(indexer)), thumb_dir);
    let app = create_app(state);

    let response = app
        .oneshot(
            Request::builder()
                .uri("/health")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);
    let body_bytes = get_body_bytes(response).await;
    let val: Value = serde_json::from_slice(&body_bytes).unwrap();
    assert_eq!(val["status"], "ok");
    assert_eq!(val["service"], "lifeframe");
}

#[tokio::test]
async fn test_e2e_desktop_to_mobile_sync_download() {
    let storage_root = PathBuf::from("./target/test_e2e_download");
    let album_dir = storage_root.join("Holiday2026");
    std::fs::create_dir_all(&album_dir).ok();

    // 1. Simulate photo placed in desktop folder
    let jpeg_bytes = create_sample_jpeg();
    let photo_path = album_dir.join("photo1.jpg");
    std::fs::write(&photo_path, &jpeg_bytes).expect("Write test photo");

    // 2. Indexer scans local library
    let thumb_dir = PathBuf::from("./target/test_e2e_download_thumbs");
    let indexer = Indexer::in_memory(&storage_root).expect("Indexer initialization");
    let indexer_arc = Arc::new(Mutex::new(indexer));
    {
        let mut indexer = indexer_arc.lock().await;
        let stats = indexer.sync_folder().expect("sync_folder");
        assert_eq!(stats.added, 1);
    }

    let state = ServerState::new(indexer_arc.clone(), thumb_dir);
    let app = create_app(state);

    // 3. Client calls /api/manifest to fetch sync manifest
    let manifest_resp = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/api/manifest")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(manifest_resp.status(), StatusCode::OK);
    let manifest_bytes = get_body_bytes(manifest_resp).await;
    let manifest: Value = serde_json::from_slice(&manifest_bytes).unwrap();

    assert_eq!(manifest["photos"].as_array().unwrap().len(), 1);
    let rel_path = manifest["photos"][0]["relative_path"]
        .as_str()
        .unwrap()
        .replace('\\', "/");
    assert!(rel_path.contains("Holiday2026/photo1.jpg"));
    assert!(!manifest["photos"][0]["hash_sha256"].as_str().unwrap().is_empty());

    // 4. Client downloads full photo via /image endpoint
    // 4. Client downloads full photo via /image endpoint
    let image_resp = app
        .clone()
        .oneshot(
            Request::builder()
                .uri(format!("/image?path={}", rel_path))
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(image_resp.status(), StatusCode::OK);
    let downloaded_bytes = get_body_bytes(image_resp).await;
    assert_eq!(downloaded_bytes.as_ref(), jpeg_bytes.as_slice());

    // 5. Client requests thumbnail
    let thumb_resp = app
        .oneshot(
            Request::builder()
                .uri(format!("/image?path={}&thumbnail=true", rel_path))
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(thumb_resp.status(), StatusCode::OK);
    assert_eq!(
        thumb_resp.headers().get("content-type").unwrap(),
        "image/jpeg"
    );
    let thumb_bytes = get_body_bytes(thumb_resp).await;
    assert!(!thumb_bytes.is_empty());

    // Clean up test files
    std::fs::remove_dir_all(&storage_root).ok();
}

#[tokio::test]
async fn test_e2e_mobile_to_desktop_sync_upload() {
    let storage_root = PathBuf::from("./target/test_e2e_upload");
    let thumb_dir = PathBuf::from("./target/test_e2e_upload_thumbs");
    std::fs::create_dir_all(&storage_root).ok();

    let indexer = Indexer::in_memory(&storage_root).expect("Indexer initialization");
    let indexer_arc = Arc::new(Mutex::new(indexer));
    let state = ServerState::new(indexer_arc.clone(), thumb_dir);
    let app = create_app(state);

    // 1. Prepare multipart upload payload from mobile
    let boundary = "---------------------------LifeframeBoundary123";
    let jpeg_bytes = create_sample_jpeg();
    let mut body_bytes = Vec::new();

    // Field: relative_path
    body_bytes.extend_from_slice(format!("--{}\r\n", boundary).as_bytes());
    body_bytes.extend_from_slice(
        b"Content-Disposition: form-data; name=\"relative_path\"\r\n\r\nMobileUploads/captured.jpg\r\n",
    );

    // Field: file
    body_bytes.extend_from_slice(format!("--{}\r\n", boundary).as_bytes());
    body_bytes.extend_from_slice(
        b"Content-Disposition: form-data; name=\"file\"; filename=\"captured.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n",
    );
    body_bytes.extend_from_slice(&jpeg_bytes);
    body_bytes.extend_from_slice(b"\r\n");

    // Close boundary
    body_bytes.extend_from_slice(format!("--{}--\r\n", boundary).as_bytes());

    // 2. Mobile sends POST /upload
    let upload_resp = app
        .clone()
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/upload")
                .header(
                    "Content-Type",
                    format!("multipart/form-data; boundary={}", boundary),
                )
                .body(axum::body::Body::from(body_bytes))
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(upload_resp.status(), StatusCode::CREATED);
    let upload_body_bytes = get_body_bytes(upload_resp).await;
    let upload_result: Value = serde_json::from_slice(&upload_body_bytes).unwrap();
    assert_eq!(upload_result["success"], true);

    // 3. Verify file exists on Desktop filesystem
    let uploaded_file_on_disk = storage_root.join("MobileUploads/captured.jpg");
    assert!(uploaded_file_on_disk.exists());

    // 4. Verify Desktop manifest immediately includes the newly uploaded photo
    let manifest_resp = app
        .oneshot(
            Request::builder()
                .uri("/api/manifest")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(manifest_resp.status(), StatusCode::OK);
    let manifest_bytes = get_body_bytes(manifest_resp).await;
    let manifest: Value = serde_json::from_slice(&manifest_bytes).unwrap();
    assert_eq!(manifest["photos"].as_array().unwrap().len(), 1);
    let path_in_manifest = manifest["photos"][0]["relative_path"]
        .as_str()
        .unwrap()
        .replace('\\', "/");
    assert!(path_in_manifest.contains("MobileUploads/captured.jpg"));

    // Clean up
    std::fs::remove_dir_all(&storage_root).ok();
}

#[tokio::test]
async fn test_e2e_conflict_resolution_and_manifest_integrity() {
    let storage_root = PathBuf::from("./target/test_e2e_integrity");
    let thumb_dir = PathBuf::from("./target/test_e2e_integrity_thumbs");
    std::fs::create_dir_all(&storage_root).ok();

    let photo_file = storage_root.join("delete_me.jpg");
    std::fs::write(&photo_file, create_sample_jpeg()).unwrap();

    let indexer = Indexer::in_memory(&storage_root).expect("Indexer initialization");
    let indexer_arc = Arc::new(Mutex::new(indexer));

    // Initial sync - 1 photo present
    {
        let mut indexer = indexer_arc.lock().await;
        let stats = indexer.sync_folder().unwrap();
        assert_eq!(stats.added, 1);
    }

    let state = ServerState::new(indexer_arc.clone(), thumb_dir);
    let app = create_app(state);

    let resp1 = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/api/manifest")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    let body1 = get_body_bytes(resp1).await;
    let manifest1: Value = serde_json::from_slice(&body1).unwrap();
    assert_eq!(manifest1["photos"].as_array().unwrap().len(), 1);

    // Delete photo on desktop filesystem
    std::fs::remove_file(&photo_file).unwrap();

    // Sync folder again - indexer detects deletion and cleans SQLite database
    {
        let mut indexer = indexer_arc.lock().await;
        let stats = indexer.sync_folder().unwrap();
        assert_eq!(stats.removed, 1);
    }

    // Verify manifest now has 0 photos
    let resp2 = app
        .clone()
        .oneshot(
            Request::builder()
                .uri("/api/manifest")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    let body2 = get_body_bytes(resp2).await;
    let manifest2: Value = serde_json::from_slice(&body2).unwrap();
    assert_eq!(manifest2["photos"].as_array().unwrap().len(), 0);

    // Verify GET /image returns 404 NOT_FOUND
    let resp3 = app
        .oneshot(
            Request::builder()
                .uri("/image?path=delete_me.jpg")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(resp3.status(), StatusCode::NOT_FOUND);

    // Clean up
    std::fs::remove_dir_all(&storage_root).ok();
}

#[tokio::test]
async fn test_e2e_device_status_telemetry() {
    let storage_root = PathBuf::from("./target/test_e2e_telemetry");
    let thumb_dir = PathBuf::from("./target/test_e2e_telemetry_thumbs");
    std::fs::create_dir_all(&storage_root).ok();

    let indexer = Indexer::in_memory(&storage_root).expect("Indexer initialization");
    let state = ServerState::new(Arc::new(Mutex::new(indexer)), thumb_dir);
    let app = create_app(state);

    let telemetry_payload = serde_json::json!({
        "device_id": "pixel-9-pro-uuid",
        "device_name": "Google Pixel 9 Pro",
        "device_type": "mobile_android",
        "client_version": "1.0.0",
        "storage_total_bytes": 256000000000u64,
        "storage_free_bytes": 128000000000u64,
        "battery_level": 88
    });

    let resp = app
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/api/device-status")
                .header("Content-Type", "application/json")
                .body(axum::body::Body::from(telemetry_payload.to_string()))
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(resp.status(), StatusCode::OK);
    let bytes = get_body_bytes(resp).await;
    let res: Value = serde_json::from_slice(&bytes).unwrap();
    assert_eq!(res["success"], true);

    std::fs::remove_dir_all(&storage_root).ok();
}
