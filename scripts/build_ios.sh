#!/usr/bin/env bash
# Build the Rust core lib as a universal static library for iOS device + sim,
# then assemble an XCFramework for the Flutter iOS project to link.
#
# Prereqs:
#   rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
set -euo pipefail

cd "$(dirname "$0")/../rust"

NAME=flutter_rust_core_ffi
LIB=lib${NAME}.a
OUT=../ios/Frameworks
mkdir -p "$OUT"

cargo build --release --target aarch64-apple-ios
cargo build --release --target aarch64-apple-ios-sim
cargo build --release --target x86_64-apple-ios

# Combine the two simulator slices (arm64 + x86_64) into a single fat lib.
SIM_FAT="target/sim-universal/$LIB"
mkdir -p "$(dirname "$SIM_FAT")"
lipo -create \
  "target/aarch64-apple-ios-sim/release/$LIB" \
  "target/x86_64-apple-ios/release/$LIB" \
  -output "$SIM_FAT"

rm -rf "$OUT/${NAME}.xcframework"
xcodebuild -create-xcframework \
  -library "target/aarch64-apple-ios/release/$LIB" \
  -library "$SIM_FAT" \
  -output "$OUT/${NAME}.xcframework"

echo "Wrote $OUT/${NAME}.xcframework"
