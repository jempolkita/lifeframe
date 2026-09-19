# Antigravity Agents Guidelines & Best Practices

This document outlines the coding standards, best practices, and architectural rules for agents working on the Lifeframe project.

## Angular (v21) Best Practices
- **Standalone Components**: Default to standalone components (`standalone: true`). Avoid `NgModules` unless integrating legacy libraries.
- **Signals**: Use Angular Signals (`signal`, `computed`, `effect`) for state management instead of RxJS `BehaviorSubject` where possible, especially for synchronous local state.
- **Control Flow**: Use the new built-in control flow (`@if`, `@for`, `@switch`) instead of structural directives (`*ngIf`, `*ngFor`).
- **Dependency Injection**: Use the `inject()` function over constructor injection for cleaner classes and better inheritance handling.
- **Lazy Loading**: Lazy load routes and standalone components to optimize initial bundle size.

## UI Components (PrimeNG & TailwindCSS)
- **PrimeNG First**: Always check if PrimeNG provides a component that fits the requirement (e.g., `p-tree`, `p-dataView`, `p-sidebar`, `p-button`, `p-dropdown`).
- **TailwindCSS for Layout & Utilities**: Use TailwindCSS for general layout (grid, flexbox), spacing (margins, padding), typography, and custom styling that PrimeNG components do not cover.
- **Customizing PrimeNG**: If a PrimeNG component needs styling adjustments, use Tailwind utility classes in combination with PrimeNG's `styleClass` or `[ngClass]` inputs, or use CSS variables if using PrimeNG headless/unstyled mode.

## Flutter & Dart Best Practices
- **Material Design 3 (MD3)**: Always use Material Design 3 components and color schemes (`useMaterial3: true` in `ThemeData`). Prefer MD3 widgets like `NavigationBar`, `FilledButton`, `Card.filled`, etc.
- **State Management**: Use a robust and predictable state management solution (e.g., Riverpod, Provider, or BLoC). For this app, Riverpod is recommended for managing sync state and local DB streams.
- **Null Safety**: Strictly adhere to Dart's sound null safety. Avoid using the `!` operator unless absolutely certain; prefer safe unwrapping.
- **Asynchronous Operations**: Use `async`/`await` clearly. Handle UI states (Loading, Error, Success) comprehensively when dealing with network or database calls.
- **Widget Composition**: Keep `build` methods small. Extract complex sub-trees into independent Stateless/Stateful widgets to optimize rebuilds.

## Tauri v2 & Rust Best Practices
- **Security**: Minimize the exposed attack surface. Only expose necessary Tauri commands to the frontend via `invoke`. Validate all inputs coming from the frontend.
- **Async Rust**: Use Tokio for asynchronous operations (like Axum server, mDNS, file I/O). Do not block the main Tauri thread.
- **Error Handling**: Use `Result` and custom Error types (e.g., using `thiserror` crate). Implement `serde::Serialize` for your custom errors so they can be sent back to the Angular frontend smoothly.
- **State Management**: Use Tauri's managed state (`app.manage()`) to hold shared resources like database connection pools or Arc-wrapped configurations.
- **Separation of Concerns**: Keep Tauri-specific command bindings thin. The core logic (indexer, sync, EXIF parsing) should reside in pure Rust modules independent of Tauri contexts, making them testable.
