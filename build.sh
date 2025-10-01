#!/bin/bash

set -e  # Exit on error

echo "🔨 Building libpillmom..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if flutter_rust_bridge_codegen is installed
if ! command -v flutter_rust_bridge_codegen &> /dev/null; then
    echo -e "${YELLOW}flutter_rust_bridge_codegen not found. Installing...${NC}"
    dart pub global activate flutter_rust_bridge_cli
fi

# Generate Flutter Rust Bridge code
echo -e "${GREEN}Generating Flutter Rust Bridge code...${NC}"
flutter_rust_bridge_codegen generate

# Build Rust library
echo -e "${GREEN}Building Rust library...${NC}"
cd packages/libpillmom/rust

# Detect platform and build
OS=$(uname -s)
ARCH=$(uname -m)

# Function to copy library files
copy_library() {
    local src=$1
    local dst=$2
    if [ -f "$src" ]; then
        cp "$src" "$dst"
        echo -e "${BLUE}Copied: $(basename $src) -> $dst${NC}"
    else
        echo -e "${YELLOW}Warning: $src not found${NC}"
    fi
}

case "$OS" in
    Darwin)
        echo "Building for macOS..."

        # Build for macOS
        if [ "$ARCH" = "arm64" ]; then
            cargo build --release --target aarch64-apple-darwin
            copy_library "target/aarch64-apple-darwin/release/libpillmom.dylib" "../macos/libpillmom.dylib"
            # Fix install name to use @rpath
            install_name_tool -id "@rpath/libpillmom.dylib" "../macos/libpillmom.dylib"
            echo -e "${GREEN}✅ Built for macOS Apple Silicon${NC}"
        else
            cargo build --release --target x86_64-apple-darwin
            copy_library "target/x86_64-apple-darwin/release/libpillmom.dylib" "../macos/libpillmom.dylib"
            # Fix install name to use @rpath
            install_name_tool -id "@rpath/libpillmom.dylib" "../macos/libpillmom.dylib"
            echo -e "${GREEN}✅ Built for macOS Intel${NC}"
        fi

        # Optional: Build for iOS if requested via argument
        if [ "$1" = "--ios" ] || [ "$1" = "--all" ]; then
            echo -e "${GREEN}Building for iOS...${NC}"

            # Build for iOS device
            cargo build --release --target aarch64-apple-ios

            # Build for iOS simulator
            cargo build --release --target aarch64-apple-ios-sim

            # Create XCFramework
            rm -rf ../ios/libpillmom.xcframework
            xcodebuild -create-xcframework \
                -library target/aarch64-apple-ios/release/libpillmom.a \
                -library target/aarch64-apple-ios-sim/release/libpillmom.a \
                -output ../ios/libpillmom.xcframework

            echo -e "${GREEN}✅ Built iOS XCFramework${NC}"
        fi
        ;;

    Linux)
        echo "Building for Linux..."
        cargo build --release
        copy_library "target/release/libpillmom.so" "../linux/libpillmom.so"
        echo -e "${GREEN}✅ Built for Linux${NC}"

        # Optional: Build for Android if requested and NDK is available
        if ([ "$1" = "--android" ] || [ "$1" = "--all" ]) && [ -n "$ANDROID_NDK_HOME" ]; then
            echo -e "${GREEN}Building for Android...${NC}"

            # ARM64
            cargo build --release --target aarch64-linux-android
            copy_library "target/aarch64-linux-android/release/libpillmom.so" "../android/src/main/jniLibs/arm64-v8a/libpillmom.so"

            # ARMv7
            cargo build --release --target armv7-linux-androideabi
            copy_library "target/armv7-linux-androideabi/release/libpillmom.so" "../android/src/main/jniLibs/armeabi-v7a/libpillmom.so"

            # x86
            cargo build --release --target i686-linux-android
            copy_library "target/i686-linux-android/release/libpillmom.so" "../android/src/main/jniLibs/x86/libpillmom.so"

            # x86_64
            cargo build --release --target x86_64-linux-android
            copy_library "target/x86_64-linux-android/release/libpillmom.so" "../android/src/main/jniLibs/x86_64/libpillmom.so"

            echo -e "${GREEN}✅ Built for Android${NC}"
        fi
        ;;

    MINGW*|CYGWIN*|MSYS*)
        echo "Building for Windows..."
        cargo build --release
        copy_library "target/release/pillmom.dll" "../windows/libpillmom.dll"
        echo -e "${GREEN}✅ Built for Windows${NC}"
        ;;

    *)
        echo "Unknown platform: $OS"
        cargo build --release
        echo -e "${YELLOW}⚠️  Platform not recognized. Manual copy may be required.${NC}"
        ;;
esac

echo -e "${GREEN}🎉 Build complete!${NC}"

# Show usage hint
if [ "$OS" = "Darwin" ] && [ "$1" != "--ios" ] && [ "$1" != "--all" ]; then
    echo -e "${BLUE}Tip: Use './build.sh --ios' to also build for iOS${NC}"
    echo -e "${BLUE}     Use './build.sh --all' to build for all available platforms${NC}"
elif [ "$OS" = "Linux" ] && [ "$1" != "--android" ] && [ "$1" != "--all" ]; then
    echo -e "${BLUE}Tip: Use './build.sh --android' to also build for Android (requires NDK)${NC}"
    echo -e "${BLUE}     Use './build.sh --all' to build for all available platforms${NC}"
fi