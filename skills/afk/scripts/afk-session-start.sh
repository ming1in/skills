#!/usr/bin/env bash
# afk-session-start.sh — SessionStart hook for AFK resume reminder
#
# When a Claude Code session starts and ~/.claude/afk-stack/<session-id>.json
# already shows enabled=true with task_status=active, inject a banner via
# the SessionStart hook's `additionalContext` so the resumed agent knows
# AFK is on without waiting for the first Stop event.
#
# Catches the crash-resume case (SessionEnd hook didn't fire because
# Claude Code crashed or was killed). On a clean exit, SessionEnd cleans
# up the stack file, so this hook then sees no state and exits silently.
#
# Per code.claude.com/docs/en/hooks: SessionStart hooks can return JSON
# with `additionalContext` to inject context into the new session.

set -uo pipefail

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    print(json.load(sys.stdin).get('session_id', ''))
except Exception:
    pass
")

[[ -z "$SESSION_ID" ]] && exit 0

STATE_FILE="$HOME/.claude/afk-stack/$SESSION_ID.json"
[[ -f "$STATE_FILE" ]] || exit 0

python3 - "$STATE_FILE" <<'PY'
import json, sys

with open(sys.argv[1]) as f:
    state = json.load(f)

if not state.get("enabled"):
    sys.exit(0)
status = state.get("task_status", "active")
if status in ("done", "blocked"):
    sys.exit(0)

task = (state.get("task") or "").strip()
iterations = int(state.get("iterations", 0))
max_iter = int(state.get("max_iterations", 50))

if task:
    msg = (
        f"AFK MODE RESUMED — this session was previously in AFK mode and "
        f"appears to have restarted (state file persisted). Continue the "
        f"registered task plus current session work autonomously.\n\n"
        f"Task: {task}\n"
        f"Iterations: {iterations}/{max_iter}\n\n"
        "Operating principles still apply: don't ask clarifying questions, "
        "don't pause on reversible work, do pause for hard approval gates, "
        "write task_status='done' when complete."
    )
else:
    msg = (
        f"AFK MODE RESUMED — this session was previously in AFK mode and "
        f"appears to have restarted (state file persisted). Continue "
        f"current session work autonomously. Iterations: {iterations}/{max_iter}."
    )

print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart",
                                          "additionalContext": msg}}))
PY
