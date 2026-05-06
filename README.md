# flutter-rust-core

Flutter app driven by a shared Rust core library. The same Rust crate is the
single source of truth for cross-platform business logic and is linked into
iOS, Android, macOS, Windows, and (via `wasm32-unknown-unknown`) the web,
exactly the architecture described in the Upwork "Senior App Developer
(Cross-Platform / Rust)" brief.

## Layout

```
rust/                    Rust core, cdylib + staticlib, C-ABI surface
lib/src/rust_ffi.dart    dart:ffi binding (one place to manage memory)
lib/src/providers.dart   Riverpod state on top of the FFI layer
lib/main.dart            Demo screens: SHA-256, email check, JSON enrich
scripts/build_ios.sh     Builds an .xcframework for device + simulator
scripts/build_android.sh Uses cargo-ndk to drop .so into jniLibs
```

## Why this shape

- `extern "C"` + `#[no_mangle]` keeps the ABI portable across every target,
  no codegen tools required.
- All Rust-allocated strings are freed through one Dart helper (`_consume`)
  so memory ownership lives in one place. That removes the most common class
  of FFI leak.
- Every entry point catches panics, so a Rust bug becomes a null return
  instead of an app crash.
- Riverpod `StateNotifier`s wrap each call so the UI never touches FFI
  pointers directly.

## Build

```bash
# Rust unit tests for the host
( cd rust && cargo test --release )

# iOS xcframework
./scripts/build_ios.sh

# Android jniLibs (needs `cargo install cargo-ndk` + Android NDK)
./scripts/build_android.sh

# Run
flutter pub get
flutter run
```

## Adding a new shared function

1. Add the Rust function in `rust/src/lib.rs` with `#[no_mangle] extern "C"`.
2. Add its lookup + Dart wrapper in `lib/src/rust_ffi.dart`.
3. Expose it through a Riverpod provider in `lib/src/providers.dart`.

## Stack

Flutter, Dart, Rust, dart:ffi, C-ABI, Riverpod, sha2, serde, cargo-ndk,
xcframework, iOS, Android.
