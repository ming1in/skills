#!/usr/bin/env bash
# afk-dispatch.sh — verb dispatcher for the consolidated /afk skill.
#
# As of v0.3.0, /afk is one skill with subcommands instead of three
# top-level skills (afk, afk-off, afk-status). This script parses the
# first argument as a verb and dispatches to the appropriate worker
# script. If the first argument isn't a recognized verb, it's treated
# as task context and the default verb (`on`) is used.
#
# Recognized verbs:
#   on      enable AFK mode (default)
#   off     disable AFK mode
#   status  show current state
#
# Usage examples:
#   afk-dispatch.sh <session_id>                       → on, no task
#   afk-dispatch.sh <session_id> "continue refactor"   → on, with task
#   afk-dispatch.sh <session_id> on "continue refactor" → on, with task (explicit)
#   afk-dispatch.sh <session_id> off                   → off
#   afk-dispatch.sh <session_id> status                → status

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_ID="${1:-}"
shift || true
ARGS="${*:-}"

if [[ -z "$SESSION_ID" ]]; then
    echo "ERROR: afk-dispatch.sh requires session_id as arg 1." >&2
    echo "If invoked from /afk, the slash command should pass \${CLAUDE_SESSION_ID}." >&2
    exit 1
fi

# Extract first whitespace-delimited token as potential verb.
FIRST="${ARGS%% *}"
REST="${ARGS#* }"
# When ARGS has no space, ${ARGS#* } returns ARGS unchanged — so REST==FIRST.
# That means there's only one token and it's potentially a verb.
[[ "$REST" == "$ARGS" ]] && REST=""

case "$FIRST" in
    on)
        exec bash "$SCRIPT_DIR/afk-enable.sh" "$SESSION_ID" "$REST"
        ;;
    off)
        exec bash "$SCRIPT_DIR/afk-disable.sh" "$SESSION_ID"
        ;;
    status)
        exec bash "$SCRIPT_DIR/afk-status.sh" "$SESSION_ID"
        ;;
    *)
        # Default verb: on. The full ARGS (including FIRST) becomes task context.
        exec bash "$SCRIPT_DIR/afk-enable.sh" "$SESSION_ID" "$ARGS"
        ;;
esac
