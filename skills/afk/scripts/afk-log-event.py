#!/usr/bin/env python3
"""afk-log-event.py — Append state-change events to JSONL audit log.

Usage:
    afk-log-event.py <state_file> <event_type> [key=value ...]

Examples:
    afk-log-event.py ~/.claude/afk-stack/abc.json iteration_block
    afk-log-event.py ~/.claude/afk-stack/abc.json state_write task="new task"
    afk-log-event.py ~/.claude/afk-stack/abc.json state_write task_status=done

Writes to <state_file>.events.jsonl. Each line is a JSON object with:
    {
      "ts": "2026-04-28T12:34:56Z",
      "event_type": "state_write",
      "session_id": "...",
      "changes": {"task": "...", "task_status": "done"},
      "snapshot": {<full state after write>}
    }

For iteration_block events, no changes field is emitted (just ts + event_type).
"""
import json
import os
import sys
import time
from datetime import datetime, timezone


def main():
    if len(sys.argv) < 3:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    state_path = sys.argv[1]
    event_type = sys.argv[2]
    kv_args = sys.argv[3:]

    # Parse state file to get session_id and current snapshot
    try:
        with open(state_path) as f:
            state = json.load(f)
    except Exception as e:
        print(f"[afk-log-event] Failed to read state file: {e}", file=sys.stderr)
        sys.exit(0)  # fail open — don't block hook

    session_id = state.get("session_id", "unknown")
    log_path = state_path + ".events.jsonl"

    # Build event record
    event = {
        "ts": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "event_type": event_type,
        "session_id": session_id,
    }

    # Parse key=value changes if provided
    if kv_args:
        changes = {}
        for kv in kv_args:
            if "=" in kv:
                k, v = kv.split("=", 1)
                changes[k] = v
        if changes:
            event["changes"] = changes

    # Always include snapshot for state_write events
    if event_type == "state_write":
        event["snapshot"] = state

    # Append to JSONL log
    try:
        with open(log_path, "a") as f:
            f.write(json.dumps(event) + "\n")
    except Exception as e:
        print(f"[afk-log-event] Failed to write log: {e}", file=sys.stderr)
        sys.exit(0)  # fail open


if __name__ == "__main__":
    main()
