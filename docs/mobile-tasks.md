# Mobile App Redesign & Navigation Tasks

## Phase 1: Navigation & Architecture
- [x] Update `MainNavigationScreen` in `main.dart` with 4 Bottom Navigation tabs (Photos, Explorer, Albums, Settings).
- [x] Create skeleton placeholder pages for `PhotosPage`, `ExplorerPage`, `AlbumsPage`, and integrate existing `SyncPage`.

## Phase 2: Database & State Engine (`SyncEngine`)
- [x] Implement query for Tab 1 (Photos): Get all photos sorted by date descending.
- [x] Implement query for Tab 2 (Explorer): Get child folders and photos for a given `parent_path`.
- [x] Implement query for Tab 3 (Albums): Get distinct folder paths and their cover photo/item counts.

## Phase 3: UI Implementation
- [x] Build **Tab 1 (Photos)**:
  - Responsive Grid layout for all chronological photos.
- [x] Build **Tab 2 (Explorer)**:
  - Replicate Jetpack Compose Gallery pattern: mixed view of folder cards and media files.
  - Implement nested navigation (Click on folder -> push new Explorer view for that path).
  - Click on photo -> Open Fullscreen Viewer.
- [x] Build **Tab 3 (Albums)**:
  - Flat grid of Album Cards.
  - Show Cover image, Album Name, and item count.
  - Click on Album -> Open a filtered view scoped to that exact folder.

## Phase 4: Polish & Integration
- [x] Integrate existing fullscreen `photo_view` seamlessly with the new grids.
- [x] Ensure Settings/Sync Tab retains the LAN Sync & Network Discovery UI.
- [x] Test Android back button handling for Explorer nested navigation.
