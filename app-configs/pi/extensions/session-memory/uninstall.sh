#!/bin/bash
# Uninstall session-memory launchd job
set -e

PLIST_NAME="dev.eunjae.pi.session-memory"
PLIST_DST="$HOME/Library/LaunchAgents/$PLIST_NAME.plist"

launchctl bootout "gui/$(id -u)/$PLIST_NAME" 2>/dev/null || true
rm -f "$PLIST_DST"

echo "Unloaded and removed $PLIST_NAME"
