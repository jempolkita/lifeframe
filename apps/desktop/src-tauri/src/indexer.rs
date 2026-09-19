use std::path::{Path, PathBuf};
use rusqlite::{params, Connection, Result};
use sha2::{Digest, Sha256};
use std::fs::File;
use std::io::Read;
use uuid::Uuid;
use chrono::Utc;
use crate::models::{
    Album, DeviceStatus, ExifData, FolderNode, GeoLocation, Person, Photo, SyncManifest,
};
use crate::exif::parse_exif;

#[derive(Debug, Default, Clone, serde::Serialize, serde::Deserialize)]
pub struct SyncStats {
    pub added: usize,
    pub updated: usize,
    pub removed: usize,
}

pub struct Indexer {
    conn: Connection,
    storage_root: PathBuf,
    thumb_cache_dir: Option<PathBuf>,
}

impl Indexer {
    pub fn new(db_path: &Path, storage_root: &Path) -> Result<Self> {
        let conn = Connection::open(db_path)?;
        let indexer = Self {
            conn,
            storage_root: storage_root.to_path_buf(),
            thumb_cache_dir: None,
        };
        indexer.init_db()?;
        Ok(indexer)
    }

    pub fn in_memory(storage_root: &Path) -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        let indexer = Self {
            conn,
            storage_root: storage_root.to_path_buf(),
            thumb_cache_dir: None,
        };
        indexer.init_db()?;
        Ok(indexer)
    }

    pub fn get_storage_root(&self) -> &Path {
        &self.storage_root
    }

    pub fn set_storage_root(&mut self, path: &Path) {
        self.storage_root = path.to_path_buf();
    }

    pub fn set_thumb_cache_dir(&mut self, dir: &Path) {
        self.thumb_cache_dir = Some(dir.to_path_buf());
    }

    pub fn get_thumb_cache_dir(&self) -> Option<&Path> {
        self.thumb_cache_dir.as_deref()
    }

    /// 6.1.2 Background Thumbnail Pre-caching Worker:
    /// Pre-generate multi-tier thumbnails (256px micro-grid & 720px preview) for a single photo file.
    pub fn pregenerate_thumbnails_for_file(full_path: &Path, thumb_cache_dir: &Path) {
        use crate::server::{generate_and_cache_thumbnail, thumb_cache_path};

        // 1. Tier 256px micro-grid
        let path_256 = thumb_cache_path(thumb_cache_dir, full_path, 256, 256);
        if !path_256.exists() {
            let _ = generate_and_cache_thumbnail(full_path, &path_256, 256, 256);
        }

        // 2. Tier 720px preview
        let path_720 = thumb_cache_path(thumb_cache_dir, full_path, 720, 720);
        if !path_720.exists() {
            let _ = generate_and_cache_thumbnail(full_path, &path_720, 720, 720);
        }
    }

    /// Spawns background worker thread to pre-cache multi-tier thumbnails for a list of photos.
    pub fn spawn_precaching_worker(files: Vec<PathBuf>, thumb_cache_dir: PathBuf) {
        if files.is_empty() {
            return;
        }
        std::thread::spawn(move || {
            for file in files {
                Self::pregenerate_thumbnails_for_file(&file, &thumb_cache_dir);
            }
        });
    }

    /// Pre-generate thumbnails for all indexed photos missing on disk in background threads.
    pub fn pregenerate_all_thumbnails_background(&self) {
        if let Some(ref thumb_dir) = self.thumb_cache_dir {
            if let Ok(photos) = self.get_all_photos() {
                let roots = self
                    .get_library_paths()
                    .unwrap_or_else(|_| vec![self.storage_root.clone()]);
                let mut files = Vec::new();
                for photo in photos {
                    for root in &roots {
                        let candidate = root.join(&photo.relative_path);
                        if candidate.exists() {
                            files.push(candidate);
                            break;
                        }
                    }
                }
                Self::spawn_precaching_worker(files, thumb_dir.clone());
            }
        }
    }

    fn init_db(&self) -> Result<()> {
        self.conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS albums (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                relative_path TEXT NOT NULL UNIQUE
            );

            CREATE UNIQUE INDEX IF NOT EXISTS idx_albums_rel_path ON albums(relative_path);

            -- Clean up duplicate albums from previous scans
            DELETE FROM albums WHERE id NOT IN (
                SELECT MIN(id) FROM albums GROUP BY relative_path
            );

            CREATE TABLE IF NOT EXISTS people (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                thumbnail_face_id TEXT
            );

            CREATE TABLE IF NOT EXISTS photos (
                id TEXT PRIMARY KEY,
                filename TEXT NOT NULL,
                relative_path TEXT NOT NULL UNIQUE,
                size_bytes INTEGER NOT NULL,
                hash_sha256 TEXT NOT NULL,
                mime_type TEXT NOT NULL,
                width INTEGER,
                height INTEGER,
                rating INTEGER DEFAULT 0,
                date_taken TEXT,
                date_modified TEXT NOT NULL,
                album_id TEXT,
                tags_json TEXT DEFAULT '[]',
                gps_json TEXT,
                exif_json TEXT,
                library_path TEXT,
                FOREIGN KEY(album_id) REFERENCES albums(id)
            );

            CREATE TABLE IF NOT EXISTS face_tags (
                id TEXT PRIMARY KEY,
                photo_id TEXT NOT NULL,
                person_id TEXT,
                person_name TEXT,
                confidence REAL,
                is_confirmed INTEGER DEFAULT 0,
                box_x REAL NOT NULL,
                box_y REAL NOT NULL,
                box_w REAL NOT NULL,
                box_h REAL NOT NULL,
                FOREIGN KEY(photo_id) REFERENCES photos(id),
                FOREIGN KEY(person_id) REFERENCES people(id)
            );

            CREATE TABLE IF NOT EXISTS devices (
                device_id TEXT PRIMARY KEY,
                device_name TEXT NOT NULL,
                device_type TEXT NOT NULL,
                battery_percentage INTEGER,
                is_charging INTEGER,
                storage_free_bytes INTEGER,
                storage_total_bytes INTEGER,
                client_version TEXT NOT NULL,
                last_sync_at TEXT,
                sync_status TEXT
            );

            -- Persists key/value application settings (e.g. library_paths JSON array)
            CREATE TABLE IF NOT EXISTS settings (
                key   TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
            ",
        )?;
        let _ = self.conn.execute("ALTER TABLE photos ADD COLUMN library_path TEXT", []);
        Ok(())
    }

    // ─── Library / Collection management ────────────────────────────────────────

    /// Returns the list of all user-registered library root paths.
    pub fn get_library_paths(&self) -> Result<Vec<std::path::PathBuf>> {
        let mut stmt = self
            .conn
            .prepare("SELECT value FROM settings WHERE key = 'library_paths'")?;
        let json: Option<String> = stmt.query_row([], |r| r.get(0)).ok();
        let paths: Vec<String> = json
            .and_then(|j| serde_json::from_str(&j).ok())
            .unwrap_or_default();
        Ok(paths.into_iter().map(std::path::PathBuf::from).collect())
    }

    /// Adds a path to the library list (no-op if already present).
    pub fn add_library_path(&mut self, path: &Path) -> Result<()> {
        let mut paths = self.get_library_paths()?;
        let canonical = path.to_path_buf();
        if paths.iter().any(|p| p == &canonical) {
            return Ok(()); // already registered
        }
        paths.push(canonical);
        let json = serde_json::to_string(&paths.iter().map(|p| p.to_string_lossy().to_string()).collect::<Vec<_>>())
            .unwrap_or_default();
        self.conn.execute(
            "INSERT INTO settings (key, value) VALUES ('library_paths', ?1)
             ON CONFLICT(key) DO UPDATE SET value = excluded.value",
            params![json],
        )?;
        Ok(())
    }

    /// Removes a path from the library list.
    pub fn remove_library_path(&mut self, path: &Path) -> Result<()> {
        let mut paths = self.get_library_paths()?;
        let canonical = path.to_path_buf();
        paths.retain(|p| p != &canonical);
        let json = serde_json::to_string(&paths.iter().map(|p| p.to_string_lossy().to_string()).collect::<Vec<_>>())
            .unwrap_or_default();
        self.conn.execute(
            "INSERT INTO settings (key, value) VALUES ('library_paths', ?1)
             ON CONFLICT(key) DO UPDATE SET value = excluded.value",
            params![json],
        )?;
        Ok(())
    }

    /// Builds a hierarchical folder tree from the registered library paths.
    /// Each library root is a top-level FolderNode; only actual sub-directories containing photos
    /// under that root are included as children.
    pub fn get_folder_tree(&self) -> Result<Vec<FolderNode>> {
        let library_paths = self.get_library_paths()?;
        let roots: Vec<std::path::PathBuf> = if library_paths.is_empty() {
            vec![self.storage_root.clone()]
        } else {
            library_paths
        };

        let mut root_nodes: Vec<FolderNode> = Vec::new();
        for root in &roots {
            if let Some(node) = Self::build_folder_tree_node(root, true) {
                root_nodes.push(node);
            }
        }

        Ok(root_nodes)
    }

    fn is_supported_image_path(path: &Path) -> bool {
        if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
            matches!(
                ext.to_lowercase().as_str(),
                "jpg" | "jpeg" | "png" | "webp" | "heic"
            )
        } else {
            false
        }
    }

    fn build_folder_tree_node(dir: &Path, is_root: bool) -> Option<FolderNode> {
        let dir_str = dir.to_string_lossy().replace('\\', "/");
        let dir_label = dir
            .file_name()
            .map(|n| n.to_string_lossy().to_string())
            .unwrap_or_else(|| dir_str.clone());

        if !dir.exists() || !dir.is_dir() {
            if is_root {
                return Some(FolderNode {
                    label: dir_label,
                    path: dir_str,
                    photo_count: 0,
                    is_library_root: true,
                    children: vec![],
                });
            }
            return None;
        }

        let mut direct_photos: i64 = 0;
        let mut sub_dirs: Vec<PathBuf> = Vec::new();

        if let Ok(entries) = std::fs::read_dir(dir) {
            let mut sorted: Vec<_> = entries.flatten().collect();
            sorted.sort_by_key(|e| e.file_name());

            for entry in sorted {
                let p = entry.path();
                if p.is_dir() {
                    let name = p.file_name().and_then(|s| s.to_str()).unwrap_or("");
                    if !name.starts_with('.') {
                        sub_dirs.push(p);
                    }
                } else if p.is_file() && Self::is_supported_image_path(&p) {
                    direct_photos += 1;
                }
            }
        }

        let mut children: Vec<FolderNode> = Vec::new();
        let mut total_child_photos: i64 = 0;

        for sub_dir in sub_dirs {
            if let Some(child_node) = Self::build_folder_tree_node(&sub_dir, false) {
                if child_node.photo_count > 0 || !child_node.children.is_empty() {
                    total_child_photos += child_node.photo_count;
                    children.push(child_node);
                }
            }
        }

        let total_photo_count = direct_photos + total_child_photos;

        if !is_root && total_photo_count == 0 && children.is_empty() {
            return None;
        }

        Some(FolderNode {
            label: dir_label,
            path: dir_str,
            photo_count: total_photo_count,
            is_library_root: is_root,
            children,
        })
    }



    /// Core scan implementation. Calls `on_progress(processed, total, current_filename)`
    /// after indexing each file, allowing the caller to emit progress events.
    pub fn sync_folder_with_progress<F>(&mut self, mut on_progress: F) -> Result<SyncStats>
    where
        F: FnMut(usize, usize, &str),
    {
        let mut stats = SyncStats::default();

        // Use the registered library paths; fall back to storage_root for backward compat.
        let library_paths = self.get_library_paths()?;
        let roots: Vec<std::path::PathBuf> = if library_paths.is_empty() {
            vec![self.storage_root.clone()]
        } else {
            library_paths
        };

        let mut disk_rel_paths = std::collections::HashSet::new();

        // ── Pass 1: Collect all files across all roots so we know the total ──
        let mut all_entries: Vec<(std::path::PathBuf, std::path::PathBuf)> = Vec::new();
        for root in &roots {
            if !root.exists() {
                std::fs::create_dir_all(root).ok();
            }
            let mut entries = Vec::new();
            Self::collect_files(root, &mut entries);
            for path in entries {
                all_entries.push((root.clone(), path));
            }
        }
        let total = all_entries.len();

        // ── Pass 2: Index each file and report progress ──
        let mut indexed_files: Vec<PathBuf> = Vec::new();
        for (idx, (root, path)) in all_entries.iter().enumerate() {
            if let Ok(rel_path) = path.strip_prefix(root) {
                let rel_str = rel_path.to_string_lossy().replace('\\', "/");
                let root_str = root.to_string_lossy().replace('\\', "/");
                disk_rel_paths.insert(rel_str.clone());
                if self.index_single_file(path, &rel_str, Some(&root_str)).is_ok() {
                    stats.added += 1;
                    indexed_files.push(path.clone());
                }
                let filename = path
                    .file_name()
                    .map(|n| n.to_string_lossy().into_owned())
                    .unwrap_or_default();
                on_progress(idx + 1, total, &filename);
            }
        }

        // ── Pass 3: Clean up photos deleted from disk ──
        let all_photos = self.get_all_photos()?;
        for photo in all_photos {
            let exists_on_disk = if let Some(ref lib_path) = photo.library_path {
                Path::new(lib_path).join(&photo.relative_path).exists()
            } else {
                roots.iter().any(|r| r.join(&photo.relative_path).exists())
            };

            if !exists_on_disk {
                let _ = self.conn.execute(
                    "DELETE FROM photos WHERE id = ?1",
                    rusqlite::params![photo.id],
                );
                stats.removed += 1;
            }
        }

        // ── Background Thumbnail Pre-caching Worker (Task 6.1.2) ──
        if let Some(ref thumb_dir) = self.thumb_cache_dir {
            Self::spawn_precaching_worker(indexed_files, thumb_dir.clone());
        }

        Ok(stats)
    }

    /// Convenience wrapper — scans without emitting progress events.
    pub fn sync_folder(&mut self) -> Result<SyncStats> {
        self.sync_folder_with_progress(|_, _, _| {})
    }

    pub fn scan_directory(&mut self) -> Result<usize> {
        self.sync_folder().map(|s| s.added)
    }

    fn collect_files(dir: &Path, out: &mut Vec<PathBuf>) {
        if let Ok(read_dir) = std::fs::read_dir(dir) {
            for entry in read_dir.flatten() {
                let path = entry.path();
                if path.is_dir() {
                    Self::collect_files(&path, out);
                } else if path.is_file() {
                    if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
                        match ext.to_lowercase().as_str() {
                            "jpg" | "jpeg" | "png" | "webp" | "heic" => {
                                out.push(path);
                            }
                            _ => {}
                        }
                    }
                }
            }
        }
    }

    pub fn index_single_file(&self, full_path: &Path, rel_path: &str, library_path: Option<&str>) -> Result<()> {
        let metadata = std::fs::metadata(full_path).map_err(|e| rusqlite::Error::ToSqlConversionFailure(Box::new(e)))?;
        let size_bytes = metadata.len() as i64;
        let date_modified = Utc::now().to_rfc3339();

        let filename = full_path
            .file_name()
            .map(|s| s.to_string_lossy().to_string())
            .unwrap_or_else(|| "unknown.jpg".to_string());

        let mime_type = match full_path.extension().and_then(|s| s.to_str()).unwrap_or("").to_lowercase().as_str() {
            "jpg" | "jpeg" => "image/jpeg",
            "png" => "image/png",
            "webp" => "image/webp",
            "heic" => "image/heic",
            _ => "application/octet-stream",
        };

        // SHA256
        let hash_sha256 = Self::compute_sha256(full_path).unwrap_or_else(|_| "unknown_hash".to_string());

        // EXIF & GPS
        let parsed = parse_exif(full_path);

        // Dimensions
        let (width, height) = if let Ok(reader) = image::ImageReader::open(full_path) {
            if let Ok(dimensions) = reader.into_dimensions() {
                (Some(dimensions.0), Some(dimensions.1))
            } else {
                (None, None)
            }
        } else {
            (None, None)
        };

        let id = Uuid::new_v4().to_string();
        let exif_json = parsed.exif.map(|e| serde_json::to_string(&e).unwrap_or_default());
        let gps_json = parsed.gps.map(|g| serde_json::to_string(&g).unwrap_or_default());

        // Check if album folder exists
        let album_id = if let Some(parent) = Path::new(rel_path).parent() {
            let parent_str = parent.to_string_lossy().replace('\\', "/");
            if !parent_str.is_empty() {
                let a_id = Uuid::new_v4().to_string();
                let a_name = parent.file_name().map(|n| n.to_string_lossy().to_string()).unwrap_or(parent_str.clone());
                self.conn.execute(
                    "INSERT INTO albums (id, name, relative_path) VALUES (?1, ?2, ?3)
                     ON CONFLICT(relative_path) DO NOTHING",
                    params![a_id, a_name, parent_str],
                ).ok();

                let mut stmt = self.conn.prepare("SELECT id FROM albums WHERE relative_path = ?1")?;
                stmt.query_row(params![parent_str], |r| r.get::<_, String>(0)).ok()
            } else {
                None
            }
        } else {
            None
        };

        self.conn.execute(
            "
            INSERT INTO photos (
                id, filename, relative_path, size_bytes, hash_sha256, mime_type,
                width, height, rating, date_taken, date_modified, album_id,
                tags_json, gps_json, exif_json, library_path
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, 0, ?9, ?10, ?11, '[]', ?12, ?13, ?14)
            ON CONFLICT(relative_path) DO UPDATE SET
                size_bytes = excluded.size_bytes,
                hash_sha256 = excluded.hash_sha256,
                date_modified = excluded.date_modified,
                width = excluded.width,
                height = excluded.height,
                date_taken = excluded.date_taken,
                gps_json = excluded.gps_json,
                exif_json = excluded.exif_json,
                library_path = excluded.library_path
            ",
            params![
                id, filename, rel_path, size_bytes, hash_sha256, mime_type,
                width, height, parsed.date_taken, date_modified, album_id,
                gps_json, exif_json, library_path
            ],
        )?;

        if let Some(ref thumb_dir) = self.thumb_cache_dir {
            let fp = full_path.to_path_buf();
            let td = thumb_dir.clone();
            std::thread::spawn(move || {
                Self::pregenerate_thumbnails_for_file(&fp, &td);
            });
        }

        Ok(())
    }

    pub fn compute_sha256(path: &Path) -> std::io::Result<String> {
        let mut file = File::open(path)?;
        let mut hasher = Sha256::new();
        let mut buffer = [0u8; 8192];
        loop {
            let bytes_read = file.read(&mut buffer)?;
            if bytes_read == 0 {
                break;
            }
            hasher.update(&buffer[..bytes_read]);
        }
        Ok(format!("{:x}", hasher.finalize()))
    }

    pub fn get_manifest(&self) -> Result<SyncManifest> {
        let photos = self.get_all_photos()?;
        let albums = self.get_all_albums()?;
        let people = self.get_all_people()?;

        let total_photos = photos.len() as i64;
        let total_size_bytes = photos.iter().map(|p| p.size_bytes).sum();

        Ok(SyncManifest {
            server_id: "lifeframe-desktop-server".to_string(),
            server_name: "Lifeframe Primary Node".to_string(),
            generated_at: Utc::now().to_rfc3339(),
            total_photos,
            total_size_bytes,
            photos,
            albums,
            people,
        })
    }

    pub fn get_all_photos(&self) -> Result<Vec<Photo>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, filename, relative_path, size_bytes, hash_sha256, mime_type,
                    width, height, rating, date_taken, date_modified, album_id,
                    tags_json, gps_json, exif_json, library_path
             FROM photos ORDER BY date_modified DESC LIMIT 500"
        )?;

        let photo_iter = stmt.query_map([], |row| {
            let tags_json: String = row.get(12)?;
            let gps_json: Option<String> = row.get(13)?;
            let exif_json: Option<String> = row.get(14)?;
            let library_path: Option<String> = row.get(15)?;

            let tags: Vec<String> = serde_json::from_str(&tags_json).unwrap_or_default();
            let gps: Option<GeoLocation> = gps_json.and_then(|s| serde_json::from_str(&s).ok());
            let exif: Option<ExifData> = exif_json.and_then(|s| serde_json::from_str(&s).ok());

            Ok(Photo {
                id: row.get(0)?,
                filename: row.get(1)?,
                relative_path: row.get(2)?,
                size_bytes: row.get(3)?,
                hash_sha256: row.get(4)?,
                mime_type: row.get(5)?,
                width: row.get(6)?,
                height: row.get(7)?,
                rating: row.get(8)?,
                date_taken: row.get(9)?,
                date_modified: row.get(10)?,
                album_id: row.get(11)?,
                tags,
                faces: Vec::new(),
                gps,
                exif,
                library_path,
            })
        })?;

        let mut photos = Vec::new();
        for p in photo_iter {
            photos.push(p?);
        }
        Ok(photos)
    }

    pub fn get_photo_by_id(&self, id: &str) -> Result<Option<Photo>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, filename, relative_path, size_bytes, hash_sha256, mime_type,
                    width, height, rating, date_taken, date_modified, album_id,
                    tags_json, gps_json, exif_json, library_path
             FROM photos WHERE id = ?1"
        )?;

        let mut rows = stmt.query(params![id])?;
        if let Some(row) = rows.next()? {
            let tags_json: String = row.get(12)?;
            let gps_json: Option<String> = row.get(13)?;
            let exif_json: Option<String> = row.get(14)?;
            let library_path: Option<String> = row.get(15)?;

            let tags: Vec<String> = serde_json::from_str(&tags_json).unwrap_or_default();
            let gps: Option<GeoLocation> = gps_json.and_then(|s| serde_json::from_str(&s).ok());
            let exif: Option<ExifData> = exif_json.and_then(|s| serde_json::from_str(&s).ok());

            Ok(Some(Photo {
                id: row.get(0)?,
                filename: row.get(1)?,
                relative_path: row.get(2)?,
                size_bytes: row.get(3)?,
                hash_sha256: row.get(4)?,
                mime_type: row.get(5)?,
                width: row.get(6)?,
                height: row.get(7)?,
                rating: row.get(8)?,
                date_taken: row.get(9)?,
                date_modified: row.get(10)?,
                album_id: row.get(11)?,
                tags,
                faces: Vec::new(),
                gps,
                exif,
                library_path,
            }))
        } else {
            Ok(None)
        }
    }

    pub fn get_photo_by_path(&self, rel_path: &str) -> Result<Option<Photo>> {
        let mut stmt = self.conn.prepare(
            "SELECT id, filename, relative_path, size_bytes, hash_sha256, mime_type,
                    width, height, rating, date_taken, date_modified, album_id,
                    tags_json, gps_json, exif_json, library_path
             FROM photos WHERE relative_path = ?1"
        )?;

        let mut rows = stmt.query(params![rel_path])?;
        if let Some(row) = rows.next()? {
            let tags_json: String = row.get(12)?;
            let gps_json: Option<String> = row.get(13)?;
            let exif_json: Option<String> = row.get(14)?;
            let library_path: Option<String> = row.get(15)?;

            let tags: Vec<String> = serde_json::from_str(&tags_json).unwrap_or_default();
            let gps: Option<GeoLocation> = gps_json.and_then(|s| serde_json::from_str(&s).ok());
            let exif: Option<ExifData> = exif_json.and_then(|s| serde_json::from_str(&s).ok());

            Ok(Some(Photo {
                id: row.get(0)?,
                filename: row.get(1)?,
                relative_path: row.get(2)?,
                size_bytes: row.get(3)?,
                hash_sha256: row.get(4)?,
                mime_type: row.get(5)?,
                width: row.get(6)?,
                height: row.get(7)?,
                rating: row.get(8)?,
                date_taken: row.get(9)?,
                date_modified: row.get(10)?,
                album_id: row.get(11)?,
                tags,
                faces: Vec::new(),
                gps,
                exif,
                library_path,
            }))
        } else {
            Ok(None)
        }
    }

    pub fn get_all_albums(&self) -> Result<Vec<Album>> {
        let mut stmt = self.conn.prepare(
            "SELECT a.id, a.name, a.relative_path, COUNT(p.id) as count
             FROM albums a
             LEFT JOIN photos p ON p.album_id = a.id
             GROUP BY a.id, a.name, a.relative_path
             ORDER BY a.name ASC"
        )?;

        let iter = stmt.query_map([], |row| {
            Ok(Album {
                id: row.get(0)?,
                name: row.get(1)?,
                relative_path: row.get(2)?,
                photo_count: row.get(3)?,
            })
        })?;

        let mut albums = Vec::new();
        for a in iter {
            albums.push(a?);
        }
        Ok(albums)
    }

    pub fn get_all_people(&self) -> Result<Vec<Person>> {
        let mut stmt = self.conn.prepare(
            "SELECT p.id, p.name, p.thumbnail_face_id, COUNT(f.id) as count
             FROM people p
             LEFT JOIN face_tags f ON f.person_id = p.id
             GROUP BY p.id, p.name, p.thumbnail_face_id"
        )?;

        let iter = stmt.query_map([], |row| {
            Ok(Person {
                id: row.get(0)?,
                name: row.get(1)?,
                thumbnail_face_id: row.get(2)?,
                photo_count: row.get(3)?,
            })
        })?;

        let mut people = Vec::new();
        for p in iter {
            people.push(p?);
        }
        Ok(people)
    }

    pub fn record_device_status(&self, status: &DeviceStatus) -> Result<()> {
        let is_charging = status.is_charging.map(|b| if b { 1 } else { 0 });
        self.conn.execute(
            "
            INSERT INTO devices (
                device_id, device_name, device_type, battery_percentage,
                is_charging, storage_free_bytes, storage_total_bytes,
                client_version, last_sync_at, sync_status
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)
            ON CONFLICT(device_id) DO UPDATE SET
                device_name = excluded.device_name,
                device_type = excluded.device_type,
                battery_percentage = excluded.battery_percentage,
                is_charging = excluded.is_charging,
                storage_free_bytes = excluded.storage_free_bytes,
                storage_total_bytes = excluded.storage_total_bytes,
                client_version = excluded.client_version,
                last_sync_at = excluded.last_sync_at,
                sync_status = excluded.sync_status
            ",
            params![
                status.device_id,
                status.device_name,
                status.device_type,
                status.battery_percentage,
                is_charging,
                status.storage_free_bytes,
                status.storage_total_bytes,
                status.client_version,
                status.last_sync_at,
                status.sync_status,
            ],
        )?;
        Ok(())
    }
}
