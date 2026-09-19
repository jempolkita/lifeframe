use axum::http::{Request, StatusCode};
use lifeframe_desktop_lib::indexer::Indexer;
use lifeframe_desktop_lib::server::{create_app, start_server, ServerState};
use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::sync::Mutex;
use tower::ServiceExt;

#[tokio::test]
async fn test_axum_manifest_endpoint_in_memory() {
    let storage_root = PathBuf::from("./test_photos_server");
    let thumb_dir = PathBuf::from("./test_thumbs_server");
    let indexer = Indexer::in_memory(&storage_root).expect("Indexer");
    let state = ServerState::new(Arc::new(Mutex::new(indexer)), thumb_dir);
    let app = create_app(state);

    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/manifest")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);
}

#[tokio::test]
async fn test_axum_device_status_endpoint() {
    let storage_root = PathBuf::from("./test_photos_server");
    let thumb_dir = PathBuf::from("./test_thumbs_server");
    let indexer = Indexer::in_memory(&storage_root).expect("Indexer");
    let state = ServerState::new(Arc::new(Mutex::new(indexer)), thumb_dir);
    let app = create_app(state);

    let payload = r#"{
        "device_id": "test-phone-123",
        "device_name": "Test Pixel",
        "device_type": "mobile_android",
        "client_version": "1.0.0"
    }"#;

    let response = app
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/api/device-status")
                .header("Content-Type", "application/json")
                .body(axum::body::Body::from(payload))
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);
}

#[tokio::test]
async fn test_axum_people_endpoint() {
    let storage_root = PathBuf::from("./test_photos_server");
    let thumb_dir = PathBuf::from("./test_thumbs_server");
    let indexer = Indexer::in_memory(&storage_root).expect("Indexer");
    let state = ServerState::new(Arc::new(Mutex::new(indexer)), thumb_dir);
    let app = create_app(state);

    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/people")
                .body(axum::body::Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn test_server_network_lifecycle() {
    let storage_root = PathBuf::from("./test_photos_server");
    let thumb_dir = PathBuf::from("./test_thumbs_server");
    let indexer = Indexer::in_memory(&storage_root).expect("Indexer");
    let indexer_arc = Arc::new(Mutex::new(indexer));

    let mut handle = start_server(indexer_arc, 0, thumb_dir).await.expect("start_server");
    let port = handle.port;
    assert!(port > 0);

    // Make an async TCP connection with timeout
    let test_fut = async {
        let mut stream = TcpStream::connect(format!("127.0.0.1:{}", port)).await?;
        let req = format!(
            "GET /api/manifest HTTP/1.1\r\nHost: 127.0.0.1:{}\r\nConnection: close\r\n\r\n",
            port
        );
        stream.write_all(req.as_bytes()).await?;

        let mut buf = vec![0u8; 1024];
        let n = stream.read(&mut buf).await?;
        let response_str = String::from_utf8_lossy(&buf[..n]);
        Ok::<bool, std::io::Error>(response_str.starts_with("HTTP/1.1 200 OK"))
    };

    let result = tokio::time::timeout(Duration::from_secs(3), test_fut)
        .await
        .expect("Network request timed out")
        .expect("TCP stream error");

    assert!(result);

    // Shutdown cleanly
    if let Some(tx) = handle.shutdown_tx.take() {
        let _ = tx.send(());
    }
}
