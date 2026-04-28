#!/usr/bin/env bash
# afk-state-write.sh — Write to AFK state file and log the change
#
# Usage:
#   afk-state-write.sh <session_id> <key> <value>
#
# Examples:
#   afk-state-write.sh abc123 task_status done
#   afk-state-write.sh abc123 block_reason "approval gate hit"
#   afk-state-write.sh abc123 task "new task context"
#
# Updates ~/.claude/afk-stack/<session_id>.json atomically and logs
# the change to <session_id>.json.events.jsonl via afk-log-event.py.

set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: afk-state-write.sh <session_id> <key> <value>" >&2
    exit 1
fi

SESSION_ID="$1"
KEY="$2"
VALUE="$3"

STATE_FILE="$HOME/.claude/afk-stack/$SESSION_ID.json"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "[afk-state-write] State file not found: $STATE_FILE" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Update state file atomically
python3 - "$STATE_FILE" "$KEY" "$VALUE" <<'PY'
import json, os, sys

state_path = sys.argv[1]
key = sys.argv[2]
value = sys.argv[3]

try:
    with open(state_path) as f:
        state = json.load(f)
except Exception as e:
    print(f"[afk-state-write] Failed to read state: {e}", file=sys.stderr)
    sys.exit(1)

# Update the key
state[key] = value

# Write atomically
tmp = state_path + ".tmp"
with open(tmp, "w") as f:
    json.dump(state, f, indent=2)
os.replace(tmp, state_path)

print(f"[afk-state-write] Updated {key}={value!r}", file=sys.stderr)
PY

# Log the change to JSONL audit log
"$SCRIPT_DIR/afk-log-event.py" "$STATE_FILE" "state_write" "$KEY=$VALUE"
