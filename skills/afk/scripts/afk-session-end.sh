#!/usr/bin/env bash
# afk-session-end.sh — SessionEnd hook for AFK stack cleanup
#
# Reads session_id from the SessionEnd hook's stdin JSON payload and
# removes ~/.claude/afk-stack/<session_id>.json, so a forgotten /afk
# doesn't leave stale entries in the stack after Claude Code exits.
#
# Per code.claude.com/docs/en/hooks: hook events receive a JSON payload
# on stdin with session_id, transcript_path, cwd, etc.

set -uo pipefail

HOOK_START_MS=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo 0)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TIMING_LOG="${AFK_TIMING_LOG:-$REPO_DIR/tmp/hook-timing.log}"

_log_timing() {
    local exit_code="${1:-0}"
    local end_ms
    end_ms=$(python3 -c "import time; print(int(time.time()*1000))" 2>/dev/null || echo 0)
    local ts
    ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    mkdir -p "$(dirname "$TIMING_LOG")"
    printf '%s\tafk-session-end.sh\tduration_ms=%s\texit=%s\n' \
        "$ts" "$((end_ms - HOOK_START_MS))" "$exit_code" >> "$TIMING_LOG"
}

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('session_id', ''))
except Exception:
    pass
")

if [[ -z "$SESSION_ID" ]]; then
    _log_timing 0
    exit 0
fi

STATE_FILE="$HOME/.claude/afk-stack/$SESSION_ID.json"
[[ -f "$STATE_FILE" ]] && rm -f "$STATE_FILE"
_log_timing 0
exit 0
