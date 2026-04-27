#!/usr/bin/env bash
# afk-bundled-hook-test.sh — empirical test of plugin.json `hooks` lifetime
#
# Question: does Claude Code fire a Stop hook declared in plugin.json's
# `hooks` field on EVERY session Stop after the plugin is installed and
# enabled (Interpretation A — what users expect, would let us drop
# install.sh)? Or only when the plugin's skill was invoked in the
# current conversation (Interpretation B — same as skill-scoped, no
# improvement over today)?
#
# This script does nothing functional: it just writes one line per fire
# to a log file with timestamp, event name, and session id (when set).
# After install of v0.3.2:
#   1. Open a fresh Claude Code session in any project
#   2. Do NOT invoke /afk in that session
#   3. Send any message and let the agent finish (triggers Stop)
#   4. Check /tmp/afk-bundled-hook-test.log
#
# If the log has an entry → Interpretation A confirmed → bundled hooks
#   fire always-on after install → AFK can drop install.sh in v0.4.0.
# If the log is empty → Interpretation B → bundled hooks are
#   skill-scoped in disguise → install.sh stays mandatory.

set -uo pipefail

LOG="${AFK_BUNDLED_HOOK_TEST_LOG:-/tmp/afk-bundled-hook-test.log}"
ts=$(date '+%Y-%m-%d %H:%M:%S')
event="${CLAUDE_HOOK_EVENT:-unknown}"
sid="${CLAUDE_SESSION_ID:-unknown}"

echo "[$ts] plugin-bundled hook FIRED — event=${event} session_id=${sid}" >> "$LOG"
exit 0
