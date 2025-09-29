#!/bin/bash

# Build script for Android (builds for all Android architectures)

# Go to native directory (parent of scripts)
cd "$(dirname "$0")/.."

echo "Building Android libraries..."

# Ensure CGO is enabled for go-libsql
export CGO_ENABLED=1

go mod download

# Android JNI libs base directory
ANDROID_DIR="../android/src/main/jniLibs"

# Build for Android arm64-v8a
echo "Building for Android arm64-v8a..."
mkdir -p "$ANDROID_DIR/arm64-v8a"
GOOS=android GOARCH=arm64 go build -buildmode=c-shared -o "$ANDROID_DIR/arm64-v8a/libpillmom.so" .
echo "Built $ANDROID_DIR/arm64-v8a/libpillmom.so"

# Build for Android armeabi-v7a
echo "Building for Android armeabi-v7a..."
mkdir -p "$ANDROID_DIR/armeabi-v7a"
GOOS=android GOARCH=arm GOARM=7 go build -buildmode=c-shared -o "$ANDROID_DIR/armeabi-v7a/libpillmom.so" .
echo "Built $ANDROID_DIR/armeabi-v7a/libpillmom.so"

# Build for Android x86_64
echo "Building for Android x86_64..."
mkdir -p "$ANDROID_DIR/x86_64"
GOOS=android GOARCH=amd64 go build -buildmode=c-shared -o "$ANDROID_DIR/x86_64/libpillmom.so" .
echo "Built $ANDROID_DIR/x86_64/libpillmom.so"

# Build for Android x86
echo "Building for Android x86..."
mkdir -p "$ANDROID_DIR/x86"
GOOS=android GOARCH=386 go build -buildmode=c-shared -o "$ANDROID_DIR/x86/libpillmom.so" .
echo "Built $ANDROID_DIR/x86/libpillmom.so"

echo ""
echo "Android libraries built successfully for all architectures!"