#!/bin/bash

# Build script for all platforms

# Go to native directory (parent of scripts)
cd "$(dirname "$0")/.."

echo "Building libraries for all platforms..."
echo "======================================="

# Ensure CGO is enabled for go-libsql
export CGO_ENABLED=1

go mod download

# Detect current platform and build native library
echo ""
echo "1. Building for current platform..."
echo "------------------------------------"
./scripts/build.sh

# Check if we have cross-compilation tools available
echo ""
echo "2. Cross-compilation builds"
echo "------------------------------------"

# Try to build for other platforms if tools are available
if command -v gomobile &> /dev/null; then
    echo "gomobile found - attempting iOS and Android builds..."
    ./scripts/build_ios.sh
    ./scripts/build_android.sh
else
    echo "gomobile not found - skipping iOS and Android builds"
    echo "To enable cross-compilation:"
    echo "  go install golang.org/x/mobile/cmd/gomobile@latest"
    echo "  gomobile init"
fi

# Linux cross-compilation (if on macOS/Windows)
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    if command -v docker &> /dev/null; then
        echo ""
        echo "Docker found - could build Linux library in Docker container"
        echo "Run: docker run --rm -v $(pwd):/app -w /app golang:latest bash scripts/build.sh"
    fi
fi

echo ""
echo "======================================="
echo "Build process complete!"
echo ""
echo "Built libraries are in their respective platform directories:"
echo "  - macOS:   ../macos/libpillmom.dylib"
echo "  - Linux:   ../linux/libpillmom.so"
echo "  - Windows: ../windows/libpillmom.dll"
echo "  - iOS:     ../ios/libpillmom.a"
echo "  - Android: ../android/src/main/jniLibs/*/libpillmom.so"