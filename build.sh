#!/bin/bash

# Dials Build Script
# Builds the Dials CLI tool and optionally installs it to /usr/local/bin

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
BUILD_TYPE="release"
INSTALL=false
INSTALL_PATH="/usr/local/bin"
BINARY_NAME="dials"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="debug"
            shift
            ;;
        --install)
            INSTALL=true
            shift
            ;;
        --install-path)
            INSTALL_PATH="$2"
            shift 2
            ;;
        -h|--help)
            echo "Dials Build Script"
            echo ""
            echo "Usage: ./build.sh [options]"
            echo ""
            echo "Options:"
            echo "  --debug          Build in debug mode (default: release)"
            echo "  --install        Install to system after building"
            echo "  --install-path   Custom installation path (default: /usr/local/bin)"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./build.sh                    # Build release version"
            echo "  ./build.sh --debug           # Build debug version"
            echo "  ./build.sh --install         # Build and install to /usr/local/bin"
            echo "  ./build.sh --install --install-path ~/bin  # Build and install to custom path"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}🔨 Building Dials...${NC}"
echo "Build type: $BUILD_TYPE"

# Clean previous builds
echo "Cleaning previous builds..."
swift package clean

# Build the project
if [ "$BUILD_TYPE" == "release" ]; then
    echo "Building release version..."
    swift build -c release
    BUILD_PATH=".build/release/$BINARY_NAME"
else
    echo "Building debug version..."
    swift build
    BUILD_PATH=".build/debug/$BINARY_NAME"
fi

# Check if build was successful
if [ ! -f "$BUILD_PATH" ]; then
    echo -e "${RED}❌ Build failed! Binary not found at $BUILD_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful!${NC}"

# Get binary size
BINARY_SIZE=$(du -h "$BUILD_PATH" | cut -f1)
echo "Binary size: $BINARY_SIZE"

# Show version
VERSION=$("$BUILD_PATH" --version 2>/dev/null || echo "Unknown")
echo "Version: $VERSION"

# Install if requested
if [ "$INSTALL" = true ]; then
    echo ""
    echo -e "${YELLOW}📦 Installing Dials...${NC}"
    
    # Check if install path exists
    if [ ! -d "$INSTALL_PATH" ]; then
        echo "Creating install directory: $INSTALL_PATH"
        mkdir -p "$INSTALL_PATH"
    fi
    
    # Check if we need sudo
    if [ -w "$INSTALL_PATH" ]; then
        echo "Installing to $INSTALL_PATH/$BINARY_NAME"
        cp "$BUILD_PATH" "$INSTALL_PATH/$BINARY_NAME"
    else
        echo "Installing to $INSTALL_PATH/$BINARY_NAME (requires sudo)"
        sudo cp "$BUILD_PATH" "$INSTALL_PATH/$BINARY_NAME"
    fi
    
    # Make sure it's executable
    if [ -w "$INSTALL_PATH/$BINARY_NAME" ]; then
        chmod +x "$INSTALL_PATH/$BINARY_NAME"
    else
        sudo chmod +x "$INSTALL_PATH/$BINARY_NAME"
    fi
    
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo ""
    echo "You can now run 'dials' from anywhere in your terminal."
    echo "Try: dials --help"
else
    echo ""
    echo "Binary location: $BUILD_PATH"
    echo "To install system-wide, run: ./build.sh --install"
fi

echo ""
echo -e "${GREEN}🎉 Done!${NC}"