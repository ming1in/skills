#!/usr/bin/env bash
# afk-disable.sh — disable AFK for THIS session only; called by /afk-off
#
# Operates on ~/.claude/afk-stack/<session_id>.json. Other sessions'
# AFK state is untouched. session_id is passed in via the
# ${CLAUDE_SESSION_ID} slash-command substitution. AFK_SESSION_OVERRIDE
# overrides for testing.
#
# Usage: afk-disable.sh <session_id>
set -uo pipefail

SESSION_ID="${AFK_SESSION_OVERRIDE:-${1:-}}"

if [[ -z "$SESSION_ID" ]]; then
    echo "ERROR: afk-disable.sh requires a session id as arg 1." >&2
    exit 1
fi

python3 - "$SESSION_ID" <<'PY'
import json, os, sys

session_id = sys.argv[1]
path = os.path.expanduser(f"~/.claude/afk-stack/{session_id}.json")
if not os.path.exists(path):
    print(f"AFK mode is already off for session {session_id[:8]}…",
          flush=True)
    raise SystemExit(0)

with open(path) as f:
    state = json.load(f)

state["enabled"] = False
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(state, f, indent=2)
os.replace(tmp, path)

print(f"AFK mode DISABLED for session {session_id[:8]}…", flush=True)
print(f"Last task:      {state.get('task', '?')}", flush=True)
print(f"Iterations:     {state.get('iterations', 0)} / {state.get('max_iterations', 50)}", flush=True)
print(f"Final status:   {state.get('task_status', 'active')}", flush=True)
PY
