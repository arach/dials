#!/bin/bash

# Dials Watch Script
# Simple file watching with entr
# Based on Grab development patterns

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BINARY_NAME="dials"
BUILD_DIR=".build/debug"
BINARY_PATH="$BUILD_DIR/$BINARY_NAME"

# Function to show colored output
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] $1${NC}"
}

# Function to build the project
build() {
    info "Building $BINARY_NAME..."
    if swift build; then
        log "Build successful"
        return 0
    else
        error "Build failed"
        return 1
    fi
}

# Function to run command center
run_command_center() {
    if [ -f "$BINARY_PATH" ]; then
        log "Running command center..."
        "$BINARY_PATH" command-center &
        local pid=$!
        info "Command center started with PID $pid"
    else
        error "Binary not found at $BINARY_PATH"
        return 1
    fi
}

# Function to rebuild
rebuild() {
    info "File change detected, rebuilding..."
    build
}

# Check dependencies
if ! command -v entr &> /dev/null; then
    error "entr not found. Install it with: brew install entr"
    exit 1
fi

# Initial build
log "Starting Dials watch mode with entr"
info "Watching Swift files in Sources/"
echo
info "Controls:"
info "  - Press 'r' + Enter to force rebuild"
info "  - Press 'q' + Enter to quit"
info "  - Press Ctrl+C to stop"
echo

# Initial build
if ! build; then
    error "Initial build failed"
    exit 1
fi

# Watch for changes using entr
find Sources -name "*.swift" | entr -r sh -c '
    echo -e "\033[0;34m[$(date +%H:%M:%S)] File change detected, rebuilding...\033[0m"
    if swift build > /dev/null 2>&1; then
        echo -e "\033[0;32m[$(date +%H:%M:%S)] Build successful\033[0m"
    else
        echo -e "\033[0;31m[$(date +%H:%M:%S)] Build failed\033[0m"
        swift build 2>&1 | head -5
    fi
'