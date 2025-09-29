#!/bin/bash

# Go to native directory (parent of scripts)
cd "$(dirname "$0")/.."

echo "Building shared library for current platform..."

# Ensure CGO is enabled for go-libsql
export CGO_ENABLED=1

# Set deployment target to match SDK version to avoid warnings
export MACOSX_DEPLOYMENT_TARGET=15.5

go mod download

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building for macOS..."
    mkdir -p ../macos
    go build -buildmode=c-shared -o ../macos/libpillmom.dylib .
    echo "Built ../macos/libpillmom.dylib"

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Building for Linux..."
    mkdir -p ../linux
    go build -buildmode=c-shared -o ../linux/libpillmom.so .
    echo "Built ../linux/libpillmom.so"

elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "Building for Windows..."
    mkdir -p ../windows
    go build -buildmode=c-shared -o ../windows/libpillmom.dll .
    echo "Built ../windows/libpillmom.dll"

else
    echo "Unknown operating system: $OSTYPE"
    exit 1
fi

echo "Build complete!"