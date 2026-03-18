#!/bin/bash
# Session Memory — Scheduled Runner
#
# Runs preprocessing for each configured source. If there are new sessions
# to process, invokes pi in one-shot mode to summarize them.
#
# Usage: called by launchd on a schedule (e.g. every hour)

set -euo pipefail

EXTENSION_DIR="$(cd "$(dirname "$0")" && pwd)"
PREPROCESS_SCRIPT="$EXTENSION_DIR/preprocess.mjs"
TMP_DIR="/tmp/session-memory"
LOG_TAG="[session-memory-scheduled]"

log() { echo "$LOG_TAG $(date '+%Y-%m-%d %H:%M:%S') $1"; }

mkdir -p "$TMP_DIR"

# Source definitions: name|path
# These must match the sources in ~/.pi/agent/session-memory.json
SOURCES=(
  "sessions|$HOME/.pi/agent/sessions"
  "bridge|$HOME/workspace/pi_workspace/.pi/bridge-sessions"
)

for entry in "${SOURCES[@]}"; do
  IFS='|' read -r name path <<< "$entry"

  log "Preprocessing source: $name ($path)"

  if [ ! -d "$path" ]; then
    log "Source path does not exist: $path — skipping"
    continue
  fi

  output_file="$TMP_DIR/${name}.json"

  # Run preprocessing
  if ! node "$PREPROCESS_SCRIPT" "$path" "$name" > "$output_file" 2>/dev/null; then
    log "Preprocessing failed for $name"
    rm -f "$output_file"
    continue
  fi

  # Check if there are sessions to process
  session_count=$(node -e "
    const d = JSON.parse(require('fs').readFileSync('$output_file', 'utf8'));
    console.log(d.sessions.length);
  " 2>/dev/null || echo "0")

  if [ "$session_count" = "0" ]; then
    log "No new sessions for $name"
    rm -f "$output_file"
    continue
  fi

  log "Found $session_count session(s) for $name — invoking pi"

  pi -p "Call the session_memory_summarize tool with preprocessedFile \"$output_file\". For each session returned, read the summarization prompt carefully, write a summary (or respond SKIP if below the importance threshold), then call session_memory_save with the sessionId and your summary." --allowedTools "session_memory_summarize,session_memory_save,Read" 2>&1 | while read -r line; do
    log "[pi:$name] $line"
  done

  rm -f "$output_file"
  log "Done processing $name"
done

# Run promoter on Sundays
if [ "$(date +%u)" = "7" ] && [ "$(date +%H)" = "00" ]; then
  log "Sunday midnight — running promoter"
  pi -p "Call the session_memory_promote tool. Read the returned prompt, generate updated long-term memory, then call session_memory_save_long_term with the result." --allowedTools "session_memory_promote,session_memory_save_long_term,Read" 2>&1 | while read -r line; do
    log "[pi:promoter] $line"
  done
  log "Done promoting"
fi

log "Scheduled run complete"
