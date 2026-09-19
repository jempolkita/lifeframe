# Lifeframe - Fundamental Features & Tasks

This document outlines the core functional requirements and the implementation tasks for the 5 fundamental adjustments requested. These adjustments will transition Lifeframe into a robust, modern photo management application.

## 1. Multi-folder Collection/Library Settings
**Requirement:** Users can select which folders will serve as their photo collections/libraries (storage roots).

**Tasks:**
- [x] **Rust/Tauri:** Create a `Config` or `Settings` manager to persist user-selected library paths (e.g., in a JSON config file inside Tauri's `app_config_dir` or inside a `settings` table in SQLite).
- [x] **Rust/Tauri:** Expose Tauri commands to `add_library_path`, `remove_library_path`, and `get_library_paths`. Use `tauri::api::dialog::FileDialogBuilder` to allow native directory selection.
- [x] **Angular:** Create a "Settings" view/modal with a "Collections/Libraries" tab.
- [x] **Angular:** Implement the UI to list current library paths, a button to add new directories, and buttons to remove existing ones.

## 2. Dynamic Folder Tree (Sidebar)
**Requirement:** The folder tree in the sidebar should only display the folders registered in the Collection/Library settings.

**Tasks:**
- [x] **Rust/Tauri:** Update the backend state to accept multiple root directories instead of a single hardcoded path.
- [x] **Rust/Tauri:** Modify the `get_folder_tree` logic to aggregate the file system tree starting from the user's registered collection paths.
- [x] **Angular:** Update the PrimeNG `p-tree` component in the sidebar to bind to the new multi-root data structure.
- [x] **Angular:** Ensure the tree refreshes automatically when a new library is added or removed in the settings.

## 3. Asynchronous Scanning & Progress Indicator (Non-blocking UI)
**Requirement:** Scanning folders should not freeze the UI. A footer or progress indicator should be shown during the scan.

**Tasks:**
- [x] **Rust/Tauri:** Move the file scanning/indexing logic (`indexer.rs`) inside a `tokio::spawn` asynchronous task so it does not block the main Tauri thread.
- [x] **Rust/Tauri:** Implement event emission using `AppHandle::emit_all` to send scan progress updates (e.g., `ScanProgress { current: i32, total: i32, current_dir: String, status: String }`).
- [x] **Angular:** Create a persistent `Footer` or `StatusBar` component in the main layout.
- [x] **Angular:** Use `@tauri-apps/api/event` to `listen` for `scan-progress` events.
- [x] **Angular:** Display the progress in the footer (using PrimeNG `p-progressBar` and status text, mimicking IDE-like background tasks).

## 4. Full-size Image Viewer Mode
**Requirement:** Implement a viewer mode to display full-size images in the app, similar to PrimeNG's `p-galleria`.

**Tasks:**
- [x] **Angular:** Implement PrimeNG `p-galleria` (or a custom fullscreen overlay using `p-image`) in the main gallery component.
- [x] **Angular:** Bind the Galleria model to the current active album/folder's photo list.
- [x] **Angular:** Add click events to thumbnails in the grid to open the Galleria at the specific image index.
- [x] **Angular:** Ensure keyboard navigation (Left/Right arrows) and close (Escape) work intuitively.

## 5. Thumbnail Generation & Display
**Requirement:** Display thumbnails instead of full-size images in the grid view to improve UI performance and resolve missing images.

**Tasks:**
- [x] **Rust/Tauri:** Integrate an image processing crate (like `image`) to generate thumbnails.
- [x] **Rust/Tauri (Optimization):** Cache generated thumbnails locally (e.g., in a `thumbnails/` cache directory inside `app_data_dir`) so subsequent loads are instant.
- [x] **Rust/Tauri:** Implement a robust image serving mechanism. Update the HTTP server or Custom Protocol to serve the thumbnail if a query parameter (e.g., `?thumb=true`) is present.
- [x] **Angular:** Update the gallery grid component to request the thumbnail URL for the initial grid view.
- [x] **Angular:** Add CSS/Tailwind rules for object-fit to ensure thumbnails look uniform (e.g., `object-cover`, `aspect-square`).
