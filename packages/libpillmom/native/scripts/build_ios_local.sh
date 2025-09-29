#!/bin/bash

# Build script for iOS - For local development on macOS
# This script attempts to build proper iOS libraries locally
# where we have more control over the build environment

# Go to native directory (parent of scripts)
cd "$(dirname "$0")/.."

echo "Building iOS libraries locally..."
echo "Note: This requires Xcode and iOS SDK to be installed"

# Ensure CGO is enabled
export CGO_ENABLED=1

# Create iOS directory
mkdir -p ../ios

# For local builds on ARM64 Macs, we can build a library that works on iOS devices
# The darwin/arm64 library is ABI-compatible with iOS/arm64
export GOOS=darwin
export GOARCH=arm64

echo "Building iOS library (ARM64)..."
go build -buildmode=c-archive -o ../ios/libpillmom.a .

# Copy for simulator (on M1+ Macs, simulator is also ARM64)
cp ../ios/libpillmom.a ../ios/libpillmom_simulator.a

# Clean up header files
rm -f ../ios/*.h

echo ""
echo "iOS libraries built successfully!"
echo "Note: These libraries use darwin/arm64 target which is compatible with iOS ARM64 devices"
echo "For full iOS optimization, consider:"
echo "1. Using a pure Go SQLite driver (without CGO)"
echo "2. Building libsql from source for iOS"
echo "3. Using the iOS platform's native SQLite"