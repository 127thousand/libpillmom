#!/bin/bash

echo "Building shared library for current platform..."

# Create lib directory if it doesn't exist
mkdir -p ../lib

go mod download

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building for macOS..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]]; then
        go build -buildmode=c-shared -o ../lib/libpillmom_darwin_arm64.dylib ffi_bridge.go
        echo "Built ../lib/libpillmom_darwin_arm64.dylib"
    else
        go build -buildmode=c-shared -o ../lib/libpillmom_darwin_amd64.dylib ffi_bridge.go
        echo "Built ../lib/libpillmom_darwin_amd64.dylib"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Building for Linux..."
    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" ]]; then
        go build -buildmode=c-shared -o ../lib/libpillmom_linux_arm64.so ffi_bridge.go
        echo "Built ../lib/libpillmom_linux_arm64.so"
    else
        go build -buildmode=c-shared -o ../lib/libpillmom_linux_amd64.so ffi_bridge.go
        echo "Built ../lib/libpillmom_linux_amd64.so"
    fi
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "Building for Windows..."
    go build -buildmode=c-shared -o ../lib/libpillmom_windows_amd64.dll ffi_bridge.go
    echo "Built ../lib/libpillmom_windows_amd64.dll"
else
    echo "Unknown operating system: $OSTYPE"
    exit 1
fi

echo "Build complete!"