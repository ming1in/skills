#!/usr/bin/env bash
# afk-stop-hook.sh — AFK-mode Stop hook
#
# When AFK mode is on (~/.claude/afk-stack/<session_id>.json has enabled=true and
# task_status=active), blocks the Stop event and instructs Claude to keep
# working autonomously on the registered task. When disabled, the state
# file is missing, or task_status is done/blocked, exits 0 so the session
# ends normally.
#
# Iteration cap prevents runaway loops: once max_iterations Stop events
# have been blocked, the hook stops blocking and lets the session exit.
# Override the state file path with AFK_STATE_FILE for testing.

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
    printf '%s\tafk-stop-hook.sh\tduration_ms=%s\texit=%s\n' \
        "$ts" "$((end_ms - HOOK_START_MS))" "$exit_code" >> "$TIMING_LOG"
}

# Read hook input from stdin and extract session_id (per
# code.claude.com/docs/en/hooks: every hook event payload includes
# session_id, transcript_path, cwd, hook_event_name, ...).
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    print(json.load(sys.stdin).get('session_id', ''))
except Exception:
    pass
")

# AFK_STATE_FILE keeps test override; otherwise look up the per-session
# state file in the AFK stack.
if [[ -n "${AFK_STATE_FILE:-}" ]]; then
    STATE_FILE="$AFK_STATE_FILE"
elif [[ -n "$SESSION_ID" ]]; then
    STATE_FILE="$HOME/.claude/afk-stack/$SESSION_ID.json"
else
    # No session_id available → no per-session state to honor.
    _log_timing 0
    exit 0
fi

if [[ ! -f "$STATE_FILE" ]]; then
    _log_timing 0
    exit 0
fi

python3 - "$STATE_FILE" <<'PY'
import json, os, sys, time, subprocess

state_path = sys.argv[1]
try:
    with open(state_path) as f:
        state = json.load(f)
except Exception:
    sys.exit(0)  # malformed state → fail open, let session stop

if not state.get("enabled"):
    sys.exit(0)

status = state.get("task_status", "active")
if status in ("done", "blocked"):
    print(f"[afk-stop-hook] task_status={status} — releasing session.",
          file=sys.stderr)
    sys.exit(0)

iterations = int(state.get("iterations", 0))
max_iter = int(state.get("max_iterations", 50))
if iterations >= max_iter:
    print(
        f"[afk-stop-hook] iteration cap {max_iter} reached for task "
        f"{state.get('task','?')!r}; allowing session to end.",
        file=sys.stderr,
    )
    sys.exit(0)

state["iterations"] = iterations + 1
state["last_block_at"] = int(time.time())
tmp = state_path + ".tmp"
with open(tmp, "w") as f:
    json.dump(state, f, indent=2)
os.replace(tmp, state_path)

# Log iteration_block event to JSONL audit log
import subprocess
script_dir = os.path.dirname(os.path.abspath(__file__))
log_script = os.path.join(script_dir, "afk-log-event.py")
try:
    subprocess.run(
        [sys.executable, log_script, state_path, "iteration_block"],
        check=False,
        capture_output=True,
    )
except Exception:
    pass  # fail open — don't block hook on logging errors

task = (state.get("task") or "").strip()
started = state.get("started_at", "?")
remaining = max_iter - state["iterations"]

if task:
    focus_line = (
        f"Registered task context: {task}\n"
        "Continue both this task AND whatever the current session is already "
        "focused on — they are complementary, not exclusive. The task is "
        "added focus, not a constraint that overrides session context.\n"
    )
else:
    focus_line = (
        "No specific task was registered with /afk — continue working on "
        "whatever the current session is already focused on (the user's "
        "most recent in-flight requests + any queued follow-ups).\n"
    )

reason = (
    "AFK MODE ACTIVE — the human is away from keyboard. Operate "
    "autonomously until the work is genuinely complete or you hit a hard "
    "blocker.\n\n"
    f"{focus_line}"
    f"Started: {started}\n"
    f"Stop-block iterations remaining before auto-release: {remaining}\n\n"
    "Operating principles while AFK is on:\n"
    "  1. Do not ask the human clarifying questions — they cannot answer. "
    "Make the call yourself: enumerate options, state your reasoning, "
    "pick the best one, proceed.\n"
    "  2. Do not pause for permission on reversible / low-stakes work "
    "(file edits, builds, tests, KG maintenance, lint, docs). Just do "
    "it.\n"
    "  3. STILL pause for the hard approval gates (merging app code to "
    "main, sending external messages, money movement, destructive "
    "shared-state ops, security-sensitive changes). If one of those is "
    "the only path forward, mark blocked via: "
    "`bash submodules/skills/skills/afk/scripts/afk-state-write.sh "
    f"{session_id} task_status blocked && "
    f"bash submodules/skills/skills/afk/scripts/afk-state-write.sh "
    f"{session_id} block_reason 'reason here'`, "
    "then stop on the next turn.\n"
    "  4. When the work is genuinely complete (the session's in-flight "
    "work AND any registered task), mark done via: "
    "`bash submodules/skills/skills/afk/scripts/afk-state-write.sh "
    f"{session_id} task_status done` (or run /afk off). The hook will then "
    "release the session.\n"
    "  5. Plan deliberately AND log plan transitions. Break decisions into "
    "options, weigh tradeoffs, recommend, execute. When your approach "
    "changes (pivoting from one subtask to another, discovering a better "
    "path, hitting a blocker that requires replanning), log it via: "
    "`bash submodules/skills/skills/afk/scripts/afk-state-write.sh "
    f"{session_id} current_subtask 'new subtask'` or "
    "`bash submodules/skills/skills/afk/scripts/afk-state-write.sh "
    f"{session_id} last_decision 'decision context'`. "
    "The state file is your working memory — write to it.\n"
    "  6. Browser-use AFK discipline. If any part of this task involves "
    "browser automation: (a) write current findings to a KG file before "
    "each Stop event — ephemeral browser state that doesn't land in "
    "knowledge/ is wasted AFK iteration; (b) Write before Browse in "
    "each iteration, not after; (c) if the task direction pivots, "
    "log the pivot via: "
    "`bash submodules/skills/skills/afk/scripts/afk-state-write.sh "
    f"{session_id} block_reason 'pivot: <one-liner>'` "
    "so the scope trail is auditable on return.\n\n"
    "Otherwise: continue. Plan the next concrete step and execute it."
)

print(json.dumps({"decision": "block", "reason": reason}))
PY

exit_code=$?
_log_timing "$exit_code"
exit "$exit_code"
