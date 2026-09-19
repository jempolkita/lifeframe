# Lifeframe - Scaffolding & Implementation Tasks

This document contains a highly detailed, structured, and executable task breakdown for building the Lifeframe application.

## Phase 1: Shared Schema & Generator Setup

### 1.1 OpenAPI Specification
- [x] Create `schemas/openapi.json`.
  - **Path**: `schemas/openapi.json`
  - **Acceptance Criteria**: The file contains a valid OpenAPI 3.0/3.1 specification. It defines schemas for Photo, Album, DeviceStatus, SyncManifest, FaceTag, BoundingBox, and Person.
- [x] Define `/api/manifest` endpoint in `schemas/openapi.json`.
  - **Acceptance Criteria**: Endpoint defined with GET method returning the current sync manifest (state of files).
- [x] Define `/image` endpoint in `schemas/openapi.json`.
  - **Acceptance Criteria**: Endpoint defined with GET method accepting photo ID/path and returning binary image data (with optional thumbnail parameters).
- [x] Define `/upload` endpoint in `schemas/openapi.json`.
  - **Acceptance Criteria**: Endpoint defined with POST method for multipart/form-data to accept image uploads.
- [x] Define `/api/device-status` endpoint in `schemas/openapi.json`.
  - **Acceptance Criteria**: Endpoint defined with POST/PUT method to report device battery, storage, and sync state.

### 1.2 Generator Scripts
- [x] Initialize root `package.json`.
  - **Path**: `package.json`
  - **Acceptance Criteria**: Standard npm/yarn/pnpm workspace or root config setup.
- [x] Add OpenAPI Generator CLI dependency.
  - **Path**: `package.json`
  - **Acceptance Criteria**: `@openapitools/openapi-generator-cli` installed as a dev dependency.
- [x] Create script to generate TypeScript (Angular) client.
  - **Path**: `package.json` (scripts section)
  - **Acceptance Criteria**: `npm run generate:angular` command successfully generates Angular service and DTO models into `apps/desktop/src/app/core/api/`.
- [x] Create script to generate Dart (Flutter) client.
  - **Path**: `package.json` (scripts section)
  - **Acceptance Criteria**: `npm run generate:flutter` command successfully generates Dart API client and models into `packages/lifeframe_api/` and linked to `apps/mobile/`.

## Phase 2: Desktop Backend Core (Tauri v2 & Rust)

### 2.1 Rust Module Structure
- [x] Setup Rust module tree.
  - **Paths**: `apps/desktop/src-tauri/src/server.rs`, `apps/desktop/src-tauri/src/indexer.rs`, `apps/desktop/src-tauri/src/exif.rs`, `apps/desktop/src-tauri/src/mdns.rs`, `apps/desktop/src-tauri/src/main.rs`
  - **Acceptance Criteria**: Files created and properly declared as modules in `main.rs`. Code compiles.

### 2.2 Axum HTTP Server & Endpoints
- [x] Setup Axum local server.
  - **Path**: `apps/desktop/src-tauri/src/server.rs`
  - **Acceptance Criteria**: Tauri command can start/stop an Axum server binding to `0.0.0.0` on a specific port.
- [x] Implement REST endpoints matching OpenAPI.
  - **Path**: `apps/desktop/src-tauri/src/server.rs`
  - **Acceptance Criteria**: Handlers for `/api/manifest`, `/image`, `/upload`, and `/api/device-status` are wired up and returning dummy/mock data initially.

### 2.3 mDNS / UDP Broadcast
- [x] Implement mDNS service registration.
  - **Path**: `apps/desktop/src-tauri/src/mdns.rs`
  - **Acceptance Criteria**: Desktop app registers `_http._tcp.local` service with its local IP and Axum server port upon startup.

### 2.4 SQLite & Metadata
- [x] Implement basic SQLite indexer.
  - **Path**: `apps/desktop/src-tauri/src/indexer.rs`
  - **Acceptance Criteria**: Functions to init DB schema, insert photo paths, and query state.
- [x] Implement EXIF/XMP parsing.
  - **Path**: `apps/desktop/src-tauri/src/exif.rs`
  - **Acceptance Criteria**: Function to extract basic EXIF data (date taken, location) from a given image path.

## Phase 3: Desktop Frontend UI (Angular 21 + PrimeNG)

### 3.1 Angular & PrimeNG Setup
- [x] Initialize Angular PrimeNG configuration.
  - **Path**: `apps/desktop/angular.json`, `apps/desktop/src/styles.css`
  - **Acceptance Criteria**: PrimeNG theme and icons configured. Global styles applied.

### 3.2 Layout & 3-Panel Structure
- [x] Create Shell Component with 3-Panel Layout.
  - **Path**: `apps/desktop/src/app/layout/`
  - **Acceptance Criteria**: Responsive layout using CSS Grid or Flexbox establishing Left, Center, and Right panels.
- [x] Implement Sidebar Folder Tree.
  - **Path**: `apps/desktop/src/app/features/sidebar/`
  - **Acceptance Criteria**: Implement `p-tree` to display local folder structure.
- [x] Implement Photo Grid.
  - **Path**: `apps/desktop/src/app/features/gallery/`
  - **Acceptance Criteria**: Implement `p-dataView` (or VirtualScroller) displaying mock photo thumbnails.
- [x] Implement Metadata Inspector.
  - **Path**: `apps/desktop/src/app/features/metadata/`
  - **Acceptance Criteria**: Implement `p-sidebar` or right-docked panel showing EXIF details for a selected photo.

### 3.3 API Integration
- [x] Integrate generated Angular API Client.
  - **Path**: `apps/desktop/src/app/core/services/sync.service.ts`
  - **Acceptance Criteria**: Angular services can call the local Axum server endpoints.

## Phase 4: Mobile Integration & Alignment (Flutter)

### 4.1 API & Model Integration
- [x] Integrate generated Dart API Client.
  - **Path**: `apps/mobile/lib/api/`
  - **Acceptance Criteria**: Generated code compiles and is accessible from Flutter repositories.

### 4.2 Discovery & Sync Engine
- [x] Implement mDNS Discovery.
  - **Path**: `apps/mobile/lib/services/discovery_service.dart`
  - **Acceptance Criteria**: App can listen for `_http._tcp.local` and resolve the Desktop's IP address.
- [x] Implement Sync Engine Logic.
  - **Path**: `apps/mobile/lib/services/sync_engine.dart`
  - **Acceptance Criteria**: Engine can fetch `/api/manifest`, compare with local SQLite, and enqueue download/upload tasks.

### 4.3 Gallery UI
- [x] Build Gallery Grid UI.
  - **Path**: `apps/mobile/lib/ui/gallery/`
  - **Acceptance Criteria**: Material Design 3 grid displaying photos, grouped by date/album.

## Phase 5: Integration & Verification

### 5.1 End-to-End Testing
- [x] Verify Local Network Connectivity.
  - **Acceptance Criteria**: Mobile app successfully pings Desktop app over Wi-Fi without manual IP entry.
- [x] Test Desktop to Mobile Sync (Download).
  - **Acceptance Criteria**: Adding a photo to Desktop folder automatically (or via sync trigger) appears in Mobile app.
- [x] Test Mobile to Desktop Sync (Upload).
  - **Acceptance Criteria**: Taking a photo on Mobile pushes the file to the Desktop's Axum server via `/upload` endpoint.
- [x] Verify Conflict Resolution & Manifest Integrity.
  - **Acceptance Criteria**: Modifying metadata or deleting files on one side correctly updates the manifest and reflects on the other side.

## Phase 6: High-Performance Media Pipeline & UI Virtualization (digiKam Architecture)

### 6.1 Backend Media Engine (Rust & Pre-caching)
- [x] **6.1.1 Embedded EXIF Thumbnail Fast-Path**
  - **Path**: `apps/desktop/src-tauri/src/exif.rs`, `apps/desktop/src-tauri/src/server.rs`
  - **Acceptance Criteria**: Extract embedded JPEG preview thumbnail directly from camera/smartphone EXIF headers without decoding full 24-48MP raw image data (~1ms response time).
- [x] **6.1.2 Background Thumbnail Pre-caching Worker**
  - **Path**: `apps/desktop/src-tauri/src/indexer.rs`
  - **Acceptance Criteria**: Pre-generate multi-tier thumbnails (256px micro-grid & 720px preview) in background worker threads during directory indexing/scanning so thumbnails are already on disk before scrolling.
- [x] **6.1.3 Dedicated Multi-tier Thumbnail Store & Memory Cache**
  - **Path**: `apps/desktop/src-tauri/src/server.rs`
  - **Acceptance Criteria**: Multi-tier hash-indexed storage (`%APPDATA%/Lifeframe/thumbnails/{hash}_{size}.jpg`) with LRU/memory cache for hot thumbnails.

### 6.2 Frontend DOM & Virtual Scrolling Architecture (Angular 21)
- [x] **6.2.1 Virtual Grid Scrolling with Angular CDK**
  - **Path**: `apps/desktop/src/app/features/gallery/photo-grid.component.ts`
  - **Acceptance Criteria**: Implement `@angular/cdk/scrolling` virtual scroll viewport to only mount viewport-visible cards into the DOM (~30-40 elements vs thousands), maintaining 60-120 FPS during rapid scroll.
- [x] **6.2.2 CSS Containment & Layout Optimization**
  - **Path**: `apps/desktop/src/app/features/gallery/photo-grid.component.ts`
  - **Acceptance Criteria**: Apply `content-visibility: auto`, `contain-intrinsic-size`, and skeleton placeholders to prevent layout reflows and paint thrashing.
- [x] **6.2.3 Fast Transport & Connection Reuse**
  - **Path**: `apps/desktop/src/app/core/services/sync.service.ts`
  - **Acceptance Criteria**: Optimize thumbnail image streaming with HTTP keep-alive and proper batch sizing to bypass browser concurrent connection limits.

### 6.3 Progressive Loading in Photo Viewer
- [x] **6.3.1 Two-Stage Progressive Image Loading**
  - **Path**: `apps/desktop/src/app/features/gallery/photo-viewer.component.ts`
  - **Acceptance Criteria**: Instant display of pre-cached 720px thumbnail preview as backdrop immediately on click (0ms perceptual lag), followed by smooth background swap when full-resolution original finishes loading.
