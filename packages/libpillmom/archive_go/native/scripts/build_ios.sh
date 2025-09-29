#!/bin/bash

# Build script for iOS (builds both device and simulator architectures)

# Go to native directory (parent of scripts)
cd "$(dirname "$0")/.."

echo "Building iOS libraries..."

# Ensure CGO is enabled for go-libsql
export CGO_ENABLED=1

go mod download

mkdir -p ../ios

# Build for iOS device (arm64)
echo "Building for iOS device (arm64)..."
GOOS=ios GOARCH=arm64 go build -buildmode=c-archive -o ../ios/libpillmom.a .
echo "Built ../ios/libpillmom.a"

# Build for iOS simulator (requires gomobile or manual cross-compilation setup)
# Note: This requires additional setup for cross-compilation
echo ""
echo "Note: iOS simulator build requires additional cross-compilation setup."
echo "For simulator support, you'll need to:"
echo "1. Install gomobile: go install golang.org/x/mobile/cmd/gomobile@latest"
echo "2. Initialize gomobile: gomobile init"
echo "3. Use gomobile bind or configure cross-compilation manually"

echo ""
echo "iOS device library built successfully!"