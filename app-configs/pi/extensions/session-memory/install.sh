#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLIST="$SCRIPT_DIR/dev.eunjae.pi.session-memory.plist"
LA_DIR="$HOME/Library/LaunchAgents"
LA_PLIST="$LA_DIR/dev.eunjae.pi.session-memory.plist"

echo "Installing session-memory launchd job..."

# Create state directory
mkdir -p "$HOME/.pi/agent/session-memory/sessions"

# Symlink plist
mkdir -p "$LA_DIR"
ln -sf "$PLIST" "$LA_PLIST"

# Load
launchctl unload "$LA_PLIST" 2>/dev/null || true
launchctl load "$LA_PLIST"

echo "✅ Installed. Job runs every hour."
echo "   Logs: /tmp/session-memory-stdout.log"
echo "   Test: node $SCRIPT_DIR/index.mjs --dry-run"
