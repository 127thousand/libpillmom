#!/bin/bash

# Build script for current platform

set -e

echo "Building Rust library for current platform..."

# Build in release mode
cargo build --release

# Detect platform and copy to appropriate location
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building for macOS..."
    cp target/release/libpillmom.dylib ../macos/libpillmom.dylib
    echo "Library built: ../macos/libpillmom.dylib"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Building for Linux..."
    cp target/release/libpillmom.so ../linux/libpillmom.so
    echo "Library built: ../linux/libpillmom.so"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "Building for Windows..."
    cp target/release/pillmom.dll ../windows/libpillmom.dll
    echo "Library built: ../windows/libpillmom.dll"
else
    echo "Unknown platform: $OSTYPE"
    exit 1
fi

echo "Build complete!"