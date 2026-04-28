#!/usr/bin/env bash
# afk-status.sh — print AFK state for THIS session + summary of stack
#
# Shows this session's state file plus any other sessions in the AFK
# stack so cross-session bleed is visible. session_id is passed in via
# ${CLAUDE_SESSION_ID} substitution.
#
# Usage: afk-status.sh <session_id>
set -uo pipefail

SESSION_ID="${AFK_SESSION_OVERRIDE:-${1:-}}"

if [[ -z "$SESSION_ID" ]]; then
    echo "ERROR: afk-status.sh requires a session id as arg 1." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 - "$SESSION_ID" "$SCRIPT_DIR" <<'PY'
import json, os, sys, glob, subprocess

session_id = sys.argv[1]
script_dir = sys.argv[2]
stack_dir = os.path.expanduser("~/.claude/afk-stack")
my_path = os.path.join(stack_dir, f"{session_id}.json")

if os.path.exists(my_path):
    with open(my_path) as f:
        state = json.load(f)
    enabled = state.get("enabled", False)
    print(f"AFK mode (this session, {session_id[:8]}…): {'ON' if enabled else 'OFF'}", flush=True)
    print(f"  Task:        {state.get('task') or '(none — continue session work)'}", flush=True)
    print(f"  Started:     {state.get('started_at', '?')}", flush=True)
    print(f"  Iterations:  {state.get('iterations', 0)} / {state.get('max_iterations', 50)}", flush=True)
    print(f"  Status:      {state.get('task_status', 'active')}", flush=True)
    if state.get("block_reason"):
        print(f"  Blocked:     {state['block_reason']}", flush=True)

    # Compute and display write-density if event log exists
    density_script = os.path.join(script_dir, "afk-write-density.py")
    try:
        result = subprocess.run(
            [sys.executable, density_script, session_id],
            capture_output=True,
            text=True,
            check=True,
        )
        density_data = json.loads(result.stdout)
        print(f"  Write-density: {density_data['write_density']:.3f} ({density_data['state_writes']} writes / {density_data['iterations']} iterations)", flush=True)
    except Exception:
        pass  # fail silent — if no event log or error, skip density line
else:
    print(f"AFK mode (this session, {session_id[:8]}…): OFF", flush=True)

others = sorted(glob.glob(os.path.join(stack_dir, "*.json"))) if os.path.isdir(stack_dir) else []
foreign = [p for p in others if p != my_path]
if foreign:
    print("", flush=True)
    print(f"Other sessions in AFK stack:", flush=True)
    for path in foreign:
        try:
            with open(path) as f:
                s = json.load(f)
            sid = os.path.basename(path).removesuffix(".json")
            on = "ON " if s.get("enabled") else "off"
            task = (s.get("task") or "(no task)")[:50]
            status = s.get("task_status", "active")
            print(f"  [{on}] {sid[:8]}… status={status} task={task!r}", flush=True)
        except Exception:
            pass
PY
