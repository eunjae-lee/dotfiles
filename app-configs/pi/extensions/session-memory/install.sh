#!/bin/bash
# Install session-memory launchd job
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST_NAME="dev.eunjae.pi.session-memory"
PLIST_SRC="$SCRIPT_DIR/$PLIST_NAME.plist"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

# Create config if missing
CONFIG="$HOME/.pi/agent/session-memory.json"
if [ ! -f "$CONFIG" ]; then
  cp "$SCRIPT_DIR/config.example.json" "$CONFIG"
  echo "Created config at $CONFIG — edit sources/paths as needed."
fi

# Create memory directory
MEMORY_PATH=$(node -e "const c=JSON.parse(require('fs').readFileSync('$CONFIG','utf8')); console.log(c.memoryPath.replace('~',process.env.HOME))" 2>/dev/null)
if [ -n "$MEMORY_PATH" ]; then
  mkdir -p "$MEMORY_PATH/archive"
  echo "Memory directory ready: $MEMORY_PATH"
fi

# Unload existing if present
launchctl bootout "gui/$(id -u)/$PLIST_NAME" 2>/dev/null || true

# Symlink and load
ln -sf "$PLIST_SRC" "$PLIST_DST"
launchctl load "$PLIST_DST"

echo "Installed and loaded $PLIST_NAME"
echo "Verify: launchctl list | grep session-memory"
