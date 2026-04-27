#!/usr/bin/env bash
# afk-enable.sh — write AFK state file for THIS session; called by /afk
#
# Per-session keying using the canonical Claude Code session_id (passed in
# from /afk via the ${CLAUDE_SESSION_ID} skill substitution). The AFK
# stack at ~/.claude/afk-stack/ holds one state file per active session,
# keyed by session_id. Stop hooks read session_id from their stdin
# payload and look up the matching file — so /afk in Session A doesn't
# block Session B's exits.
#
# Usage: afk-enable.sh <session_id> [task description]
# AFK_SESSION_OVERRIDE env var overrides session_id for testing.
set -uo pipefail

SESSION_ID="${AFK_SESSION_OVERRIDE:-${1:-}}"
TASK="${2:-}"

if [[ -z "$SESSION_ID" ]]; then
    echo "ERROR: afk-enable.sh requires a session id as arg 1." >&2
    echo "If invoked from /afk, the slash command should pass \${CLAUDE_SESSION_ID}." >&2
    exit 1
fi

python3 - "$SESSION_ID" "$TASK" <<'PY'
import json, os, sys, time

session_id = sys.argv[1]
raw = sys.argv[2].strip() if len(sys.argv) > 2 else ""
task = raw if raw else ""

state = {
    "enabled": True,
    "session_id": session_id,
    "task": task,
    "started_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
    "iterations": 0,
    "max_iterations": 50,
    "task_status": "active",
}
stack_dir = os.path.expanduser("~/.claude/afk-stack")
os.makedirs(stack_dir, exist_ok=True)
path = os.path.join(stack_dir, f"{session_id}.json")
tmp = path + ".tmp"
with open(tmp, "w") as f:
    json.dump(state, f, indent=2)
os.replace(tmp, path)
display_task = task if task else "(none — continue current session work)"
print(f"AFK mode ENABLED for session {session_id[:8]}…", flush=True)
print(f"Task: {display_task}", flush=True)
print(f"Started: {state['started_at']}", flush=True)
print(f"Iteration cap: {state['max_iterations']}", flush=True)
print(f"State file: {path}", flush=True)
PY
