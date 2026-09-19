use axum::http::{Request, StatusCode};
use lifeframe_desktop_lib::exif::extract_exif_thumbnail;
use lifeframe_desktop_lib::indexer::Indexer;
use lifeframe_desktop_lib::server::{
    create_app, thumb_cache_path, ServerState, ThumbnailMemoryCache,
};
use std::io::Cursor;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;
use tower::ServiceExt;

fn create_test_jpeg(w: u32, h: u32) -> Vec<u8> {
    let img = image::RgbImage::new(w, h);
    let mut buf = Cursor::new(Vec::new());
    img.write_to(&mut buf, image::ImageFormat::Jpeg)
        .expect("Failed to create test JPEG");
    buf.into_inner()
}

#[test]
fn test_thumbnail_memory_cache_lru() {
    // 100 bytes max capacity
    let cache = ThumbnailMemoryCache::new(100);

    let key1 = "file1:256".to_string();
    let data1 = vec![1u8; 40];
    cache.insert(key1.clone(), data1.clone());

    let key2 = "file2:256".to_string();
    let data2 = vec![2u8; 40];
    cache.insert(key2.clone(), data2.clone());

    // Both should be in memory
    assert_eq!(cache.get(&key1), Some(data1));
    assert_eq!(cache.get(&key2), Some(data2));

    // Inserting key3 (40 bytes) should evict key1 (the least recently used)
    let key3 = "file3:256".to_string();
    let data3 = vec![3u8; 40];
    cache.insert(key3.clone(), data3.clone());

    assert!(cache.get(&key1).is_none(), "key1 should be evicted by LRU");
    assert!(cache.get(&key2).is_some());
    assert!(cache.get(&key3).is_some());
}

#[test]
fn test_multi_tier_thumbnail_store_paths() {
    let cache_dir = PathBuf::from("./target/test_tier_paths");
    let source = PathBuf::from("C:/photos/vacation.jpg");

    // Tier 256
    let p256 = thumb_cache_path(&cache_dir, &source, 256, 256);
    assert!(p256.to_string_lossy().ends_with("_256.jpg"));

    // Tier 720
    let p720 = thumb_cache_path(&cache_dir, &source, 720, 720);
    assert!(p720.to_string_lossy().ends_with("_720.jpg"));

    // Custom dimensions
    let p_custom = thumb_cache_path(&cache_dir, &source, 1024, 768);
    assert!(p_custom.to_string_lossy().ends_with("_1024x768.jpg"));
}

#[test]
fn test_embedded_exif_fast_path_extraction() {
    let temp_dir = PathBuf::from("./target/test_exif_fast_path");
    std::fs::create_dir_all(&temp_dir).ok();
    let file_path = temp_dir.join("dummy.jpg");
    std::fs::write(&file_path, create_test_jpeg(32, 32)).unwrap();

    // Plain test image with no EXIF thumbnail should gracefully return None
    let result = extract_exif_thumbnail(&file_path);
    assert!(result.is_none());

    std::fs::remove_dir_all(&temp_dir).ok();
}

#[test]
fn test_background_thumbnail_precaching() {
    let temp_dir = PathBuf::from("./target/test_precaching");
    let thumb_dir = temp_dir.join("thumbs");
    std::fs::create_dir_all(&thumb_dir).ok();

    let photo_file = temp_dir.join("landscape.jpg");
    std::fs::write(&photo_file, create_test_jpeg(120, 80)).unwrap();

    // Run multi-tier pregeneration
    Indexer::pregenerate_thumbnails_for_file(&photo_file, &thumb_dir);

    let path_256 = thumb_cache_path(&thumb_dir, &photo_file, 256, 256);
    let path_720 = thumb_cache_path(&thumb_dir, &photo_file, 720, 720);

    assert!(path_256.exists(), "256px micro thumbnail must be cached on disk");
    assert!(path_720.exists(), "720px preview thumbnail must be cached on disk");

    std::fs::remove_dir_all(&temp_dir).ok();
}

#[tokio::test]
async fn test_server_thumbnail_streaming_with_keepalive() {
    let storage_root = PathBuf::from("./target/test_streaming_srv");
    let thumb_dir = storage_root.join("thumbs");
    std::fs::create_dir_all(&storage_root).ok();

    let photo_file = storage_root.join("sample.jpg");
    std::fs::write(&photo_file, create_test_jpeg(64, 64)).unwrap();

    let mut indexer = Indexer::in_memory(&storage_root).expect("Indexer initialization");
    indexer.set_thumb_cache_dir(&thumb_dir);
    indexer.index_single_file(&photo_file, "sample.jpg", None).unwrap();

    let state = ServerState::new(Arc::new(Mutex::new(indexer)), thumb_dir);
    let app = create_app(state);

    // Request thumbnail with 256px micro-grid tier
    let response = app
        .oneshot(
            Request::builder()
                .uri("/image?path=sample.jpg&thumbnail=true&max_width=256&max_height=256")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);
    let headers = response.headers();
    assert_eq!(headers.get("content-type").unwrap(), "image/jpeg");
    assert_eq!(headers.get("connection").unwrap(), "keep-alive");
    assert!(headers.get("cache-control").unwrap().to_str().unwrap().contains("immutable"));
    assert!(headers.get("etag").is_some());

    std::fs::remove_dir_all(&storage_root).ok();
}
