pub mod commands;
pub mod exif;
pub mod indexer;
pub mod lib_state;
pub mod mdns;
pub mod models;
pub mod server;

use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use tokio::sync::Mutex as TokioMutex;
use tauri::{Manager, State};

use crate::indexer::Indexer;
use crate::lib_state::AppState;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    let app_data_dir = dirs_or_local();
    let db_path = app_data_dir.join("lifeframe.db");
    let storage_root = app_data_dir.join("photos");
    let thumb_cache_dir = app_data_dir.join("thumbnails");

    std::fs::create_dir_all(&storage_root).ok();
    std::fs::create_dir_all(&thumb_cache_dir).ok();

    let mut indexer = Indexer::new(&db_path, &storage_root)
        .unwrap_or_else(|_| Indexer::in_memory(&storage_root).expect("In-memory indexer"));
    indexer.set_thumb_cache_dir(&thumb_cache_dir);

    let state = AppState {
        indexer: Arc::new(TokioMutex::new(indexer)),
        server_handle: Mutex::new(None),
        mdns_handle: Mutex::new(None),
        thumb_cache_dir: thumb_cache_dir.clone(),
    };

    tauri::Builder::default()
        .manage(state)
        .invoke_handler(tauri::generate_handler![
            commands::get_server_status,
            commands::start_server,
            commands::stop_server,
            commands::select_folder,
            commands::scan_folder,
            commands::get_manifest,
            commands::get_photos,
            commands::get_albums,
            commands::get_people,
            // Library / Collection management
            commands::get_library_paths,
            commands::add_library_path,
            commands::remove_library_path,
            commands::get_folder_tree,
        ])
        .setup(|app| {
            let state: State<AppState> = app.state();
            let indexer_arc = state.indexer.clone();
            let indexer_arc_precach = state.indexer.clone();
            let thumb_dir = state.thumb_cache_dir.clone();
            let app_handle = app.handle().clone();

            tauri::async_runtime::spawn(async move {
                match server::start_server(indexer_arc, 8080, thumb_dir).await {
                    Ok(handle) => {
                        let state = app_handle.state::<AppState>();
                        if let Ok(mut server_lock) = state.server_handle.lock() {
                            *server_lock = Some(handle);
                        };
                    }
                    Err(e) => {
                        eprintln!("Failed to start Axum server on startup: {e}");
                    }
                }
            });

            // 6.1.2 Background pre-caching worker on startup
            tauri::async_runtime::spawn(async move {
                let indexer = indexer_arc_precach.lock().await;
                indexer.pregenerate_all_thumbnails_background();
            });

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

fn dirs_or_local() -> PathBuf {
    if let Some(base) = std::env::var_os("APPDATA") {
        PathBuf::from(base).join("Lifeframe")
    } else if let Some(base) = std::env::var_os("HOME") {
        PathBuf::from(base).join(".lifeframe")
    } else {
        PathBuf::from("./lifeframe_data")
    }
}
