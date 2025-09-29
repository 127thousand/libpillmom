#!/bin/bash

# Build script with explicit deployment target

# Go to native directory (parent of scripts)
cd "$(dirname "$0")/.."

echo "Building shared library with explicit deployment target..."

# Set the minimum macOS version to match the SDK
export MACOSX_DEPLOYMENT_TARGET=15.5

# Ensure CGO is enabled for go-libsql
export CGO_ENABLED=1

# You can also set CGO flags to specify the target
# export CGO_CFLAGS="-mmacosx-version-min=15.5"
# export CGO_LDFLAGS="-mmacosx-version-min=15.5"

go mod download

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building for macOS (deployment target: $MACOSX_DEPLOYMENT_TARGET)..."
    mkdir -p ../macos
    go build -buildmode=c-shared -o ../macos/libpillmom.dylib .
    echo "Built ../macos/libpillmom.dylib"

    # Check the deployment target of the built library
    echo "Checking deployment target of built library:"
    otool -l ../macos/libpillmom.dylib | grep -A 3 LC_VERSION_MIN_MACOSX || otool -l ../macos/libpillmom.dylib | grep -A 3 LC_BUILD_VERSION

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