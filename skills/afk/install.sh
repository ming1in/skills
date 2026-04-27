#!/usr/bin/env bash
# install.sh — register AFK hooks in user-scope ~/.claude/settings.json
#
# Adds Stop, SessionEnd, and SessionStart hook entries pointing at this
# skill's scripts. Idempotent — re-running won't create duplicate entries.
#
# Why this exists: skill-scoped hooks (declared in SKILL.md frontmatter)
# only fire when the skill is active in the current conversation. AFK
# needs Stop to fire on EVERY session Stop regardless of whether /afk was
# the last skill invoked, so settings.json registration is required.
#
# Usage:
#   bash install.sh                         # add to ~/.claude/settings.json
#   bash install.sh --target /path/to/.json # custom settings file
#   bash install.sh --remove                # remove entries (idempotent)
#   bash install.sh --print                 # print what would change, no write

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.claude/settings.json"
MODE="install"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --remove) MODE="remove"; shift ;;
        --print)  MODE="print"; shift ;;
        --help|-h)
            sed -n '2,15p' "${BASH_SOURCE[0]}"
            exit 0 ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

STOP_SCRIPT="$SCRIPT_DIR/scripts/afk-stop-hook.sh"
SESSION_END_SCRIPT="$SCRIPT_DIR/scripts/afk-session-end.sh"
SESSION_START_SCRIPT="$SCRIPT_DIR/scripts/afk-session-start.sh"

for s in "$STOP_SCRIPT" "$SESSION_END_SCRIPT" "$SESSION_START_SCRIPT"; do
    if [[ ! -x "$s" ]]; then
        echo "ERROR: $s not found or not executable" >&2
        exit 1
    fi
done

python3 - "$TARGET" "$STOP_SCRIPT" "$SESSION_END_SCRIPT" "$SESSION_START_SCRIPT" "$MODE" <<'PY'
import json, os, sys

target, stop_path, session_end_path, session_start_path, mode = sys.argv[1:]
os.makedirs(os.path.dirname(target), exist_ok=True)

if os.path.exists(target):
    with open(target) as f:
        try:
            settings = json.load(f)
        except Exception as e:
            print(f"ERROR: {target} is not valid JSON: {e}", file=sys.stderr)
            sys.exit(1)
else:
    settings = {}

settings.setdefault("hooks", {})
hooks = settings["hooks"]

# AFK identity tag — embedded in the command string so we can find/remove
# our own entries idempotently without touching unrelated user hooks.
TAG = "# afk-skill"

def has_afk_entry(event_hooks_list, script_path):
    for group in event_hooks_list:
        for h in group.get("hooks", []):
            cmd = h.get("command", "")
            if TAG in cmd and script_path in cmd:
                return True
    return False

def add_entry(event, script_path, timeout):
    event_hooks = hooks.setdefault(event, [])
    if has_afk_entry(event_hooks, script_path):
        return False
    event_hooks.append({
        "hooks": [{
            "type": "command",
            "command": f"{TAG} {script_path}",
            "timeout": timeout,
        }]
    })
    return True

def remove_entries():
    removed = 0
    for event, event_hooks in list(hooks.items()):
        new_groups = []
        for group in event_hooks:
            kept = [h for h in group.get("hooks", []) if TAG not in h.get("command", "")]
            removed += len(group.get("hooks", [])) - len(kept)
            if kept:
                new_groups.append({"hooks": kept})
        if new_groups:
            hooks[event] = new_groups
        else:
            del hooks[event]
    return removed

if mode == "remove":
    n = remove_entries()
    if mode == "print":
        print(json.dumps(settings, indent=2))
    else:
        with open(target + ".tmp", "w") as f:
            json.dump(settings, f, indent=2)
        os.replace(target + ".tmp", target)
    print(f"Removed {n} AFK hook entries from {target}")
    sys.exit(0)

added = 0
added += int(add_entry("Stop", stop_path, 10))
added += int(add_entry("SessionEnd", session_end_path, 5))
added += int(add_entry("SessionStart", session_start_path, 5))

if mode == "print":
    print(json.dumps(settings, indent=2))
    sys.exit(0)

with open(target + ".tmp", "w") as f:
    json.dump(settings, f, indent=2)
os.replace(target + ".tmp", target)

if added == 0:
    print(f"AFK hooks already installed in {target} (no changes).")
else:
    print(f"Added {added} AFK hook entries to {target}:")
    print(f"  Stop          → {stop_path}")
    print(f"  SessionEnd    → {session_end_path}")
    print(f"  SessionStart  → {session_start_path}")
PY
