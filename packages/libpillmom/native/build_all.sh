#!/bin/bash

# Build script for all platforms using cross-compilation
# Requires: cargo install cross

set -e

echo "Building libpillmom for all platforms..."

# Create output directories
mkdir -p ../macos
mkdir -p ../linux
mkdir -p ../windows
mkdir -p ../android/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86,x86_64}
mkdir -p ../ios

# macOS
echo "Building for macOS (Apple Silicon)..."
cargo build --release --target aarch64-apple-darwin
cp target/aarch64-apple-darwin/release/libpillmom.dylib ../macos/libpillmom.dylib

# iOS
echo "Building for iOS..."
cargo build --release --target aarch64-apple-ios
cp target/aarch64-apple-ios/release/libpillmom.a ../ios/libpillmom.a

# iOS Simulator
echo "Building for iOS Simulator..."
cargo build --release --target aarch64-apple-ios-sim
cp target/aarch64-apple-ios-sim/release/libpillmom.a ../ios/libpillmom_simulator.a

# Linux
echo "Building for Linux x86_64..."
cross build --release --target x86_64-unknown-linux-gnu
cp target/x86_64-unknown-linux-gnu/release/libpillmom.so ../linux/libpillmom.so

# Windows
echo "Building for Windows x86_64..."
cross build --release --target x86_64-pc-windows-gnu
cp target/x86_64-pc-windows-gnu/release/pillmom.dll ../windows/libpillmom.dll

# Android
echo "Building for Android arm64..."
cross build --release --target aarch64-linux-android
cp target/aarch64-linux-android/release/libpillmom.so ../android/src/main/jniLibs/arm64-v8a/libpillmom.so

echo "Building for Android armv7..."
cross build --release --target armv7-linux-androideabi
cp target/armv7-linux-androideabi/release/libpillmom.so ../android/src/main/jniLibs/armeabi-v7a/libpillmom.so

echo "Building for Android x86..."
cross build --release --target i686-linux-android
cp target/i686-linux-android/release/libpillmom.so ../android/src/main/jniLibs/x86/libpillmom.so

echo "Building for Android x86_64..."
cross build --release --target x86_64-linux-android
cp target/x86_64-linux-android/release/libpillmom.so ../android/src/main/jniLibs/x86_64/libpillmom.so

echo "All builds complete!"