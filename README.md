# Lifeframe

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Tauri v2](https://img.shields.io/badge/Tauri-v2-blue?logo=tauri)](https://tauri.app/)
[![Angular v21](https://img.shields.io/badge/Angular-v21-red?logo=angular)](https://angular.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-v3.29+-blue?logo=flutter)](https://flutter.dev/)
[![OpenAPI 3.0](https://img.shields.io/badge/OpenAPI-3.0.3-green?logo=openapi-initiative)](schemas/openapi.json)

**Lifeframe** is an open-source, privacy-first, folder-based photo management and peer-to-peer local network (LAN) synchronization system for **Desktop** and **Mobile**.

It pairs deep power-user metadata capabilities (EXIF/GPS parsing and digiKam/YOLO-compatible face detection regions) with a fluid, Google Photos-inspired gallery experience—providing rapid local indexing, dynamic thumbnail streaming, and reliable peer-to-peer Wi-Fi synchronization with zero cloud lock-in.

---

## Table of Contents

- [Key Features](#key-features)
- [Architecture & Monorepo Structure](#architecture--monorepo-structure)
- [Sync Protocol & Schema](#sync-protocol--schema)
- [Prerequisites & System Requirements](#prerequisites--system-requirements)
- [Getting Started & Running](#getting-started--running)
  - [1. Initial Setup](#1-initial-setup)
  - [2. Code Generation (OpenAPI)](#2-code-generation-openapi)
  - [3. Running the Desktop Application](#3-running-the-desktop-application)
  - [4. Running the Mobile Application](#4-running-the-mobile-application)
- [Development Workflow & Best Practices](#development-workflow--best-practices)
- [Testing & Quality Verification](#testing--quality-verification)
- [Troubleshooting & FAQs](#troubleshooting--faqs)
- [License](#license)

---

## Key Features

- **Folder-Centric & Non-Destructive**: Your folder structure remains the primary organization system on disk. Photos are never buried in proprietary databases or encrypted blobs.
- **Bi-Directional LAN Synchronization**: Synchronize photos between your Desktop workstation and Mobile phones over local Wi-Fi without uploading a single byte to external clouds.
- **Zero-Config Discovery**: Automatic server discovery over local networks via **mDNS** (`_http._tcp.local`) with manual IP fallback and heartbeat health checks.
- **digiKam & AI Face Tag Compatibility**: Structured face detection regions with normalized bounding boxes `[x, y, w, h]` and confidence scores compatible with YOLO/ONNX models and digiKam tag regions.
- **High-Performance Rust Core**: Embedded SQLite indexer with SHA-256 integrity validation, multi-threaded EXIF/GPS parsing, and on-the-fly thumbnail generation with HTTP cache headers.
- **Modern Desktop UI**: Built with Angular 21 (Signals, standalone components, `inject()`) and PrimeNG with the **Aura** dark preset. Includes dual-mode operation (native Tauri v2 IPC and in-browser mock studio).
- **Responsive Mobile App**: Built with Flutter and Material Design 3 (`useMaterial3: true`), interactive multi-touch photo viewing (`photo_view`), and background synchronization queues.

---

## Architecture & Monorepo Structure

```
                          ┌────────────────────────┐
                          │   schemas/openapi.json  │  (Single Source of Truth)
                          └───────────┬────────────┘
                                      │
               ┌──────────────────────┴──────────────────────┐
               ▼                                             ▼
  ┌─────────────────────────┐                   ┌─────────────────────────┐
  │      apps/desktop       │                   │       apps/mobile       │
  │                         │                   │                         │
  │ • Tauri v2 + Rust Core  │                   │ • Flutter (Dart 3.9+)   │
  │   - Bundled SQLite      │                   │   - Material Design 3   │
  │   - Axum 0.7 HTTP Server│ ◄─── Wi-Fi LAN ──►│   - mDNS Discovery      │
  │   - mDNS Broadcast      │   (/api/manifest, │   - Local SQLite Cache  │
  │ • Angular 21 + PrimeNG  │     /image,       │   - SyncEngine Worker   │
  │   - Signal Architecture │     /upload,      │   - Interactive Viewer  │
  │   - Aura Theme Preset   │   /device-status) │                         │
  └─────────────────────────┘                   └─────────────────────────┘
```

### Directory Structure

```
lifeframe/
├── apps/
│   ├── desktop/                 # Desktop Application (Tauri v2 + Angular 21 + PrimeNG)
│   │   ├── src/                 # Angular UI (Signals, PrimeNG, 3-panel layout)
│   │   │   ├── app/core/api/    # Generated TypeScript HTTP client
│   │   │   ├── app/core/services# TauriService (Signals) & SyncService
│   │   │   └── app/features/    # Folder Tree, Photo Grid, Metadata Inspector
│   │   └── src-tauri/           # Rust Core Backend
│   │       ├── src/             # Indexer, Axum server, mDNS, EXIF parser, Commands
│   │       └── tests/           # Unit & End-to-End Integration tests
│   └── mobile/                  # Mobile Application (Flutter MD3 Client)
│       ├── lib/api/             # Re-export of generated Lifeframe API client
│       ├── lib/services/        # DiscoveryService (mDNS) & SyncEngine (SQLite)
│       └── lib/ui/              # MD3 Gallery Grid & Sync Management Screens
├── packages/
│   └── lifeframe_api/           # Generated typed Dart client package
├── schemas/
│   └── openapi.json             # Shared OpenAPI 3.0.3 Sync Specification
├── docs/
│   └── scaffolding-tasks.md     # 5-Phase Scaffolding & Verification Tracker
├── package.json                 # Monorepo generator scripts
└── README.md                    # Project Documentation
```

---

## Sync Protocol & Schema

All communication between Desktop and Mobile is governed strictly by [`schemas/openapi.json`](schemas/openapi.json).

### Core Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/health` | Heartbeat endpoint returning node status and server version. |
| `GET` | `/api/manifest` | Returns full catalog snapshot (photos, albums, people, SHA-256 hashes, timestamps). |
| `GET` | `/image` | High-speed binary image streaming (`?path=...`) with on-the-fly thumbnail generation (`&thumbnail=true`). |
| `POST` | `/upload` | Multipart form upload (`file`, `relative_path`, `album_id`) pushing mobile photos to desktop. |
| `POST` | `/api/device-status`| Telemetry sync reporting device battery level, storage free/total bytes, and client version. |
| `GET` | `/api/people` | Retrives identified person clusters and thumbnail faces. |

---

## Prerequisites & System Requirements

Ensure the following tools are installed on your workstation:

### 1. Node.js & Package Manager
- **Node.js**: `v20.x` or higher (LTS recommended)
- **npm**: `v10.x` or higher

### 2. Rust Toolchain
- **Rust & Cargo**: `v1.80` or higher (`stable`)
  ```bash
  # Check installation
  rustc --version
  cargo --version
  ```
  *(To install, visit [rustup.rs](https://rustup.rs/))*

### 3. Tauri v2 Prerequisites
- **Windows**: Microsoft Visual Studio C++ Build Tools (with "Desktop development with C++") and WebView2 runtime.
- **macOS**: Xcode Command Line Tools (`xcode-select --install`).
- **Linux**: Standard development libraries:
  ```bash
  sudo apt install libwebkit2gtk-4.1-dev build-essential curl wget file libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev
  ```

### 4. Flutter SDK
- **Flutter**: `v3.29.x` or higher (Dart SDK `^3.9.x`)
  ```bash
  flutter doctor
  ```

### 5. Java (Optional, for Code Generation)
- **Java JRE/JDK**: Java 11+ (only needed if you update `schemas/openapi.json` and run `npm run generate`).

---

## Getting Started & Running

### 1. Initial Setup

Clone the repository and install root dependencies:
```bash
git clone https://github.com/jempolkita/lifeframe.git
cd lifeframe
npm install
```

### 2. Code Generation (OpenAPI)

If you modify [`schemas/openapi.json`](schemas/openapi.json), regenerate both the Angular TypeScript client and Flutter Dart client in a single command:
```bash
npm run generate
```
Individual generator commands:
```bash
npm run generate:angular   # Generates apps/desktop/src/app/core/api/
npm run generate:flutter   # Generates packages/lifeframe_api/
```

---

### 3. Running the Desktop Application

The desktop app can run in two modes:

#### Option A: Native Tauri v2 Mode (Full Native Desktop App)
Runs the Rust backend, embedded SQLite, Axum server, and Angular UI within the native Tauri window:
```bash
cd apps/desktop
npm install
npm run tauri dev
```

#### Option B: Standalone In-Browser Studio Mode (Rapid Frontend UI Dev)
If you are iterating on the Angular UI, layout, or themes without running Rust:
```bash
cd apps/desktop
npm install
npm start
```
Open your browser at `http://localhost:4200`. The frontend automatically detects the browser environment and activates mock studio data with interactive filters, album switches, and metadata previews.

---

### 4. Running the Mobile Application

1. Connect an Android or iOS device (or launch an emulator).
2. Ensure your workstation and mobile device are connected to the same Wi-Fi network.
3. Launch the mobile app:
   ```bash
   cd apps/mobile
   flutter pub get
   flutter run
   ```
4. In the app:
   - Go to the **Sync** tab (`NavigationBar`).
   - The app will automatically scan for desktop instances via mDNS.
   - Alternatively, use **Manual IP Pairing** to enter your Desktop's LAN IP address and port (e.g. `192.168.1.100:8080`).
   - Tap **Sync Now** to pull the desktop catalog into your local gallery.

---

## Development Workflow & Best Practices

Please adhere to the coding standards documented in [`AGENTS.md`](AGENTS.md):

### Angular (v21)
- **Signals**: Always use Angular Signals (`signal`, `computed`, `effect`) for state management rather than RxJS subjects for local state.
- **Standalone Components**: All components must be standalone (`standalone: true`).
- **Built-in Control Flow**: Use `@if`, `@for`, and `@switch` syntax instead of legacy structural directives (`*ngIf`, `*ngFor`).
- **Dependency Injection**: Use `inject()` instead of constructor injection.
- **UI System**: Prefer PrimeNG components first (`p-tree`, `p-dataView`, `p-sidebar`, `p-button`, `p-tag`). Complement with TailwindCSS for spacing, grid, and layout utilities.

### Rust & Tauri v2
- **Separation of Concerns**: Keep business logic (SQLite indexing, SHA-256 calculation, EXIF extraction, thumbnail generation) in pure Rust modules independent of Tauri contexts.
- **Async Execution**: Use Tokio for asynchronous operations (Axum HTTP server, file I/O). Never block the main Tauri event loop.
- **Embedded Database**: Use bundled SQLite via `rusqlite` to eliminate external runtime DLL dependencies.
- **Safe Error Handling**: Use structured `Result` types with `thiserror` and `serde::Serialize` for IPC and REST error responses.

### Flutter & Dart
- **Material Design 3**: Always use Material Design 3 (`useMaterial3: true` in `ThemeData`). Prefer MD3 components like `NavigationBar`, `FilledButton`, `Card.filled`.
- **Null Safety**: Maintain sound null safety. Avoid forceful unwrapping with `!`; prefer explicit pattern matching and safe fallbacks.
- **Clean Architecture**: Keep widgets composable and lightweight. Delegate business logic to services (`DiscoveryService`, `SyncEngine`).

---

## Testing & Quality Verification

All layers of the monorepo contain comprehensive test suites and static analysis verification:

### 1. Rust Backend & End-to-End Test Suite
Tests in-memory SQLite lifecycles, server REST endpoints, thumbnail generation, multipart file upload, and conflict resolution:
```bash
cd apps/desktop/src-tauri
cargo test
```
**Test Coverage Includes:**
- `test_e2e_health_check`: Heartbeat verification.
- `test_e2e_desktop_to_mobile_sync_download`: Desktop-to-mobile sync and streaming thumbnails.
- `test_e2e_mobile_to_desktop_sync_upload`: Mobile-to-desktop multipart upload and instantaneous indexing.
- `test_e2e_conflict_resolution_and_manifest_integrity`: File deletion detection, SQLite cleanup, and 404 enforcement.
- `test_e2e_device_status_telemetry`: Client battery and storage telemetry logging.
- `test_server_network_lifecycle`: Multi-threaded TCP network connection and graceful shutdown.

### 2. Angular Desktop Frontend Production Build
Validates TypeScript compilation, template types, and bundle budgets:
```bash
cd apps/desktop
npm run build
```

### 3. Flutter Mobile Quality Checks
Verifies zero lint warnings and tests the smoke widget navigation:
```bash
cd apps/mobile
flutter analyze
flutter test
```

---

## Troubleshooting & FAQs

### 1. Desktop and Mobile are on the same Wi-Fi, but mDNS does not discover the desktop automatically
- Some home or corporate Wi-Fi routers disable multicast/mDNS traffic between wireless clients (AP isolation or IGMP snooping).
- **Solution**: Open the **Sync** tab in the mobile app, tap **Manual IP Pairing**, and enter your Desktop's local IP address and port (e.g. `http://192.168.1.15:8080`).

### 2. Windows Defender / Search Indexer file-lock collision during `cargo build`
- On Windows, rapid creation of intermediate `.o` object files during parallel compilation can occasionally trigger transient file locks (OS Error 32).
- **Solution**: Set `CARGO_TARGET_DIR` to a directory on drive `C:`:
  ```powershell
  $env:CARGO_TARGET_DIR="C:\Users\<username>\.cargo_target\lifeframe"
  cargo test
  ```

### 3. Regenerating OpenAPI client fails
- Ensure Java 11+ is installed and available in your `PATH` (`java -version`).
- Run `npm run generate` from the repository root directory.

---

## License

This project is licensed under the **MIT License**. You are free to use, modify, distribute, and contribute to Lifeframe.
