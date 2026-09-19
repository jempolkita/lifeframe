use std::path::PathBuf;
use tauri::{Emitter, State};

use crate::lib_state::AppState;
use crate::models::{Album, FolderNode, Person, Photo, SyncManifest};
use crate::{mdns, server};

/// Payload emitted as a Tauri event during a library scan.
#[derive(Debug, Clone, serde::Serialize)]
pub struct ScanProgress {
    pub current: usize,
    pub total: usize,
    pub filename: String,
    pub percent: u8,
}

/// Payload emitted when a scan completes.
#[derive(Debug, Clone, serde::Serialize)]
pub struct ScanComplete {
    pub indexed: usize,
    pub removed: usize,
}


#[derive(serde::Serialize)]
pub struct ServerStatus {
    pub is_running: bool,
    pub port: u16,
    pub local_ip: String,
    pub storage_path: String,
    pub total_photos: i64,
}

#[tauri::command]
pub async fn get_server_status(state: State<'_, AppState>) -> Result<ServerStatus, String> {
    let (is_running, port) = {
        let server_lock = state.server_handle.lock().map_err(|e| e.to_string())?;
        let running = server_lock.is_some();
        let p = server_lock.as_ref().map(|s| s.port).unwrap_or(8080);
        (running, p)
    };

    let local_ip = local_ip_address::local_ip()
        .map(|ip| ip.to_string())
        .unwrap_or_else(|_| "127.0.0.1".to_string());

    let indexer = state.indexer.lock().await;
    let storage_path = indexer.get_storage_root().to_string_lossy().to_string();
    let total_photos = indexer.get_all_photos().map(|p| p.len() as i64).unwrap_or(0);

    Ok(ServerStatus {
        is_running,
        port,
        local_ip,
        storage_path,
        total_photos,
    })
}

#[tauri::command]
pub async fn start_server(
    state: State<'_, AppState>,
    port: Option<u16>,
) -> Result<ServerStatus, String> {
    let requested_port = port.unwrap_or(8080);

    let is_running = {
        let server_lock = state.server_handle.lock().map_err(|e| e.to_string())?;
        server_lock.is_some()
    };

    if is_running {
        return get_server_status(state).await;
    }

    let thumb_dir = state.thumb_cache_dir.clone();
    let handle = server::start_server(state.indexer.clone(), requested_port, thumb_dir)
        .await
        .map_err(|e| e.to_string())?;

    let bound_port = handle.port;

    // Register mDNS
    let mdns = mdns::register_service(bound_port).ok();

    {
        let mut server_lock = state.server_handle.lock().map_err(|e| e.to_string())?;
        *server_lock = Some(handle);

        let mut mdns_lock = state.mdns_handle.lock().map_err(|e| e.to_string())?;
        *mdns_lock = mdns;
    }

    get_server_status(state).await
}

#[tauri::command]
pub async fn stop_server(state: State<'_, AppState>) -> Result<ServerStatus, String> {
    {
        let mut server_lock = state.server_handle.lock().map_err(|e| e.to_string())?;
        if let Some(mut s) = server_lock.take() {
            if let Some(tx) = s.shutdown_tx.take() {
                let _ = tx.send(());
            }
            if let Some(tx) = s.udp_shutdown_tx.take() {
                let _ = tx.send(());
            }
        }
    }

    get_server_status(state).await
}

/// Opens a native folder-picker dialog (kept for general use).
#[tauri::command]
pub async fn select_folder() -> Result<Option<String>, String> {
    tokio::task::spawn_blocking(|| {
        let folder = rfd::FileDialog::new()
            .set_title("Select Photos Folder")
            .pick_folder();
        folder.map(|f| f.to_string_lossy().to_string())
    })
    .await
    .map_err(|e| e.to_string())
}

// ─── Library / Collection Commands ──────────────────────────────────────────

/// Returns all user-registered library root paths.
#[tauri::command]
pub async fn get_library_paths(state: State<'_, AppState>) -> Result<Vec<String>, String> {
    let indexer = state.indexer.lock().await;
    let paths = indexer.get_library_paths().map_err(|e| e.to_string())?;
    Ok(paths.iter().map(|p| p.to_string_lossy().to_string()).collect())
}

/// Opens a native folder-picker, adds the selected path to the library, and
/// returns the full updated list of library paths.
#[tauri::command]
pub async fn add_library_path(state: State<'_, AppState>) -> Result<Vec<String>, String> {
    // Show native folder dialog (must be blocking because rfd is not async)
    let selected = tokio::task::spawn_blocking(|| {
        rfd::FileDialog::new()
            .set_title("Add Library Folder")
            .pick_folder()
    })
    .await
    .map_err(|e| e.to_string())?;

    let path = match selected {
        Some(p) => p,
        None => {
            // User cancelled — return the existing list unchanged
            let indexer = state.indexer.lock().await;
            let paths = indexer.get_library_paths().map_err(|e| e.to_string())?;
            return Ok(paths.iter().map(|p| p.to_string_lossy().to_string()).collect());
        }
    };

    let mut indexer = state.indexer.lock().await;
    indexer.add_library_path(&path).map_err(|e| e.to_string())?;
    let paths = indexer.get_library_paths().map_err(|e| e.to_string())?;
    Ok(paths.iter().map(|p| p.to_string_lossy().to_string()).collect())
}

/// Removes a path from the library list and returns the updated list.
#[tauri::command]
pub async fn remove_library_path(
    state: State<'_, AppState>,
    path: String,
) -> Result<Vec<String>, String> {
    let mut indexer = state.indexer.lock().await;
    indexer
        .remove_library_path(&PathBuf::from(&path))
        .map_err(|e| e.to_string())?;
    let paths = indexer.get_library_paths().map_err(|e| e.to_string())?;
    Ok(paths.iter().map(|p| p.to_string_lossy().to_string()).collect())
}

/// Returns the hierarchical folder tree for the sidebar.
#[tauri::command]
pub async fn get_folder_tree(state: State<'_, AppState>) -> Result<Vec<FolderNode>, String> {
    let indexer = state.indexer.lock().await;
    indexer.get_folder_tree().map_err(|e| e.to_string())
}

// ─── Scan / Index Commands ───────────────────────────────────────────────────

/// Scans all registered library paths and indexes their photos.
/// Emits real-time `scan-progress` and `scan-complete` Tauri events so the
/// Angular frontend can show a non-blocking progress indicator.
#[tauri::command]
pub async fn scan_folder(
    app: tauri::AppHandle,
    state: State<'_, AppState>,
) -> Result<usize, String> {
    let indexer_arc = state.indexer.clone();
    let app_clone = app.clone();

    let stats = tokio::task::spawn_blocking(move || {
        let rt = tokio::runtime::Handle::current();
        let mut indexer = rt.block_on(indexer_arc.lock());

        indexer
            .sync_folder_with_progress(|current, total, filename| {
                let percent = if total > 0 {
                    ((current as f64 / total as f64) * 100.0) as u8
                } else {
                    0
                };
                // Throttle: emit every 5 files (or always for small/final events)
                if current % 5 == 0 || current == total || total < 20 {
                    let _ = app_clone.emit(
                        "scan-progress",
                        ScanProgress {
                            current,
                            total,
                            filename: filename.to_string(),
                            percent,
                        },
                    );
                }
            })
            .map_err(|e| e.to_string())
    })
    .await
    .map_err(|e| e.to_string())??;

    // Emit completion event so the UI can refresh and clear the progress bar
    let _ = app.emit(
        "scan-complete",
        ScanComplete {
            indexed: stats.added,
            removed: stats.removed,
        },
    );

    Ok(stats.added)
}

#[tauri::command]
pub async fn get_manifest(state: State<'_, AppState>) -> Result<SyncManifest, String> {
    let indexer = state.indexer.lock().await;
    indexer.get_manifest().map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_photos(state: State<'_, AppState>) -> Result<Vec<Photo>, String> {
    let indexer = state.indexer.lock().await;
    indexer.get_all_photos().map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_albums(state: State<'_, AppState>) -> Result<Vec<Album>, String> {
    let indexer = state.indexer.lock().await;
    indexer.get_all_albums().map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_people(state: State<'_, AppState>) -> Result<Vec<Person>, String> {
    let indexer = state.indexer.lock().await;
    indexer.get_all_people().map_err(|e| e.to_string())
}
