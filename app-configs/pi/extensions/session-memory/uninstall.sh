#!/bin/bash
set -euo pipefail

LA_PLIST="$HOME/Library/LaunchAgents/dev.eunjae.pi.session-memory.plist"

echo "Uninstalling session-memory launchd job..."

launchctl unload "$LA_PLIST" 2>/dev/null || true
rm -f "$LA_PLIST"

echo "✅ Uninstalled. State data preserved at ~/.pi/agent/session-memory/"
