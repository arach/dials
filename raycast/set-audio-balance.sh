#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Set Audio Balance
# @raycast.mode compact
# @raycast.argument1 { "type": "text", "placeholder": "left | center | right" }

# Optional parameters:
# @raycast.icon 🎚️
# @raycast.packageName Audio

set -euo pipefail

# Ensure /usr/local/bin is in PATH for Raycast
export PATH="/usr/local/bin:$PATH"

if dials balance --"$1"; then
  echo "Audio balance set to $1"
else
  echo "⚠️  Failed to set balance to $1" >&2
  exit 1
fi 