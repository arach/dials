#!/bin/bash

# Dials Development Script
# Auto-rebuild on file changes with pause/resume functionality
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
PID_FILE=".pid"
PAUSE_FILE=".pause"

# Watch patterns
WATCH_PATHS="Sources"
WATCH_EXTENSIONS="swift"

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

# Function to kill any running process
cleanup() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            info "Stopping process $pid"
            kill $pid 2>/dev/null || true
            sleep 0.5
            if ps -p $pid > /dev/null 2>&1; then
                warn "Force killing process $pid"
                kill -9 $pid 2>/dev/null || true
            fi
        fi
        rm -f "$PID_FILE"
    fi
}

# Function to build the project
build() {
    info "Building $BINARY_NAME..."
    if swift build > /dev/null 2>&1; then
        log "Build successful"
        return 0
    else
        error "Build failed"
        swift build 2>&1 | head -10
        return 1
    fi
}

# Function to run the binary
run_binary() {
    if [ -f "$BINARY_PATH" ]; then
        log "Starting $BINARY_NAME command-center..."
        "$BINARY_PATH" command-center &
        local pid=$!
        echo $pid > "$PID_FILE"
        info "Process started with PID $pid"
    else
        error "Binary not found at $BINARY_PATH"
        return 1
    fi
}

# Function to handle pause/resume
check_pause() {
    if [ -f "$PAUSE_FILE" ]; then
        warn "Development paused. Delete .pause file to resume."
        return 1
    fi
    return 0
}

# Function to rebuild and restart
rebuild_and_restart() {
    if ! check_pause; then
        return
    fi
    
    info "File change detected, rebuilding..."
    cleanup
    
    if build; then
        run_binary
    else
        error "Build failed, not starting process"
    fi
}

# Trap to cleanup on exit
trap cleanup EXIT INT TERM

# Check dependencies
if ! command -v fswatch &> /dev/null; then
    error "fswatch not found. Install it with: brew install fswatch"
    exit 1
fi

# Initial build and run
log "Starting Dials development mode"
info "Watching: $WATCH_PATHS"
info "Extensions: $WATCH_EXTENSIONS"
echo
info "Controls:"
info "  - Create '.pause' file to pause auto-reload"
info "  - Delete '.pause' file to resume"
info "  - Press Ctrl+C to stop"
echo

# Remove pause file if it exists
rm -f "$PAUSE_FILE"

# Initial build
if build; then
    run_binary
else
    error "Initial build failed"
    exit 1
fi

# Watch for changes
info "Watching for file changes..."
fswatch -o -r -e ".*" -i "\\.swift$" "$WATCH_PATHS" | while read f; do
    rebuild_and_restart
done