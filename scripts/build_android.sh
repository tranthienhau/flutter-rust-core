#!/usr/bin/env bash
# Build the Rust core lib for every Android ABI Flutter ships, then copy each
# resulting .so into the Android project's jniLibs tree where Gradle picks them
# up automatically.
#
# Prereqs: cargo-ndk + the Rust targets installed:
#   cargo install cargo-ndk
#   rustup target add aarch64-linux-android armv7-linux-androideabi \
#                     x86_64-linux-android i686-linux-android
set -euo pipefail

cd "$(dirname "$0")/../rust"

OUT="../android/app/src/main/jniLibs"
mkdir -p "$OUT"

cargo ndk \
  -t arm64-v8a \
  -t armeabi-v7a \
  -t x86_64 \
  -t x86 \
  -o "$OUT" \
  build --release

echo "Wrote .so files to $OUT"
