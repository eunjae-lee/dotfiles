#!/bin/bash
# Session Memory — Scheduled Runner
# Called by launchd every hour. Runs the orchestrator.
# On Sundays, also runs the promoter.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_PREFIX="[session-memory]"

log() { echo "$LOG_PREFIX $(date -u +%Y-%m-%dT%H:%M:%SZ) $1"; }

log "Starting scheduled run"

# Run summarizer
node "$SCRIPT_DIR/index.mjs" 2>&1 || {
  log "ERROR: Summarizer failed with exit code $?"
}

# Run promoter on Sundays
DOW=$(date +%u)  # 7 = Sunday
if [ "$DOW" = "7" ]; then
  HOUR=$(date +%H)
  if [ "$HOUR" = "00" ]; then
    log "Sunday midnight — running promoter"
    node "$SCRIPT_DIR/index.mjs" --promote 2>&1 || {
      log "ERROR: Promoter failed with exit code $?"
    }
  fi
fi

log "Done"
