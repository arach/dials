#!/bin/bash
# Script for launcher integration (Hyper-D, Raycast, Alfred, etc.)
# Shows the Dials Command Center

# Check if dials CLI is in PATH
if command -v dials &> /dev/null; then
    dials show
else
    # Fallback to local build
    if [ -f "$HOME/dev/dials/.build/debug/dials" ]; then
        "$HOME/dev/dials/.build/debug/dials" show
    else
        echo "Error: Dials CLI not found. Please install with 'make install'"
        exit 1
    fi
fi