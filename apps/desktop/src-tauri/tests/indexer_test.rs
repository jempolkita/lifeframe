use lifeframe_desktop_lib::indexer::Indexer;
use lifeframe_desktop_lib::models::DeviceStatus;
use std::path::PathBuf;

#[test]
fn test_indexer_in_memory_lifecycle() {
    let storage_root = PathBuf::from("./test_photos");
    let indexer = Indexer::in_memory(&storage_root).expect("Failed to initialize in-memory indexer");

    // Check manifest on empty indexer
    let manifest = indexer.get_manifest().expect("Failed to get manifest");
    assert_eq!(manifest.total_photos, 0);
    assert_eq!(manifest.total_size_bytes, 0);
    assert!(manifest.photos.is_empty());
    assert!(manifest.albums.is_empty());

    // Record a device status
    let device = DeviceStatus {
        device_id: "mobile-device-1".to_string(),
        device_name: "Pixel 8".to_string(),
        device_type: "mobile_android".to_string(),
        battery_percentage: Some(85),
        is_charging: Some(false),
        storage_free_bytes: Some(64_000_000_000),
        storage_total_bytes: Some(128_000_000_000),
        client_version: "1.0.0".to_string(),
        last_sync_at: None,
        sync_status: Some("idle".to_string()),
    };

    indexer.record_device_status(&device).expect("Failed to record device status");
}

fn create_sample_jpeg() -> Vec<u8> {
    let img = image::RgbImage::new(16, 16);
    let mut buf = std::io::Cursor::new(Vec::new());
    img.write_to(&mut buf, image::ImageFormat::Jpeg)
        .expect("Failed to create sample JPEG");
    buf.into_inner()
}

#[test]
fn test_folder_tree_multi_library_isolation() {
    let base_dir = PathBuf::from("./target/test_multi_lib");
    let fb_dir = base_dir.join("Facebook");
    let iphone_dir = base_dir.join("iPhone");
    let iphone_sub = iphone_dir.join("2026-05");

    std::fs::create_dir_all(&fb_dir).unwrap();
    std::fs::create_dir_all(&iphone_sub).unwrap();

    let jpeg = create_sample_jpeg();
    // Facebook has 2 photos directly in its root
    std::fs::write(fb_dir.join("fb1.jpg"), &jpeg).unwrap();
    std::fs::write(fb_dir.join("fb2.jpg"), &jpeg).unwrap();

    // iPhone has 3 photos inside subfolder 2026-05
    std::fs::write(iphone_sub.join("ip1.jpg"), &jpeg).unwrap();
    std::fs::write(iphone_sub.join("ip2.jpg"), &jpeg).unwrap();
    std::fs::write(iphone_sub.join("ip3.jpg"), &jpeg).unwrap();

    let storage_root = base_dir.join("fallback");
    std::fs::create_dir_all(&storage_root).unwrap();

    let mut indexer = Indexer::in_memory(&storage_root).unwrap();
    indexer.add_library_path(&fb_dir).unwrap();
    indexer.add_library_path(&iphone_dir).unwrap();

    let stats = indexer.sync_folder().unwrap();
    assert_eq!(stats.added, 5);

    let tree = indexer.get_folder_tree().unwrap();
    assert_eq!(tree.len(), 2);

    let fb_node = tree.iter().find(|n| n.label == "Facebook").expect("Facebook root found");
    assert_eq!(fb_node.photo_count, 2);
    // Facebook must NOT have 2026-05 as child
    assert_eq!(fb_node.children.len(), 0);

    let ip_node = tree.iter().find(|n| n.label == "iPhone").expect("iPhone root found");
    assert_eq!(ip_node.photo_count, 3);
    assert_eq!(ip_node.children.len(), 1);
    assert_eq!(ip_node.children[0].label, "2026-05");
    assert_eq!(ip_node.children[0].photo_count, 3);

    // Clean up
    std::fs::remove_dir_all(&base_dir).ok();
}

