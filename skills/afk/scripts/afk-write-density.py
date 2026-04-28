#!/usr/bin/env python3
"""afk-write-density.py — Compute write-density metric from JSONL audit log.

Usage:
    afk-write-density.py <session_id>

Reads ~/.claude/afk-stack/<session_id>.json.events.jsonl and computes:
    write_density = (distinct state_write events) / (total iteration_block events)

A session with 15 iterations and 8 distinct state writes has density 8/15 ≈ 0.53.
This measures whether the agent is "writing itself" (high density) vs. behaving
like a dumb loop (density near 0).

Output format (JSON):
    {
      "session_id": "...",
      "iterations": 15,
      "state_writes": 8,
      "write_density": 0.53,
      "events_by_type": {"iteration_block": 15, "state_write": 8}
    }
"""
import json
import os
import sys
from collections import Counter


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    session_id = sys.argv[1]
    log_path = os.path.expanduser(f"~/.claude/afk-stack/{session_id}.json.events.jsonl")

    if not os.path.exists(log_path):
        print(f"No event log found: {log_path}", file=sys.stderr)
        sys.exit(0)

    events = []
    with open(log_path) as f:
        for line in f:
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue

    if not events:
        print(
            json.dumps(
                {
                    "session_id": session_id,
                    "iterations": 0,
                    "state_writes": 0,
                    "write_density": 0.0,
                    "events_by_type": {},
                }
            )
        )
        return

    event_types = Counter(e["event_type"] for e in events)
    iterations = event_types.get("iteration_block", 0)
    state_writes = event_types.get("state_write", 0)

    # Write-density = distinct state writes / iterations
    # (If iterations=0, density is undefined; report 0.0)
    write_density = state_writes / iterations if iterations > 0 else 0.0

    result = {
        "session_id": session_id,
        "iterations": iterations,
        "state_writes": state_writes,
        "write_density": round(write_density, 3),
        "events_by_type": dict(event_types),
    }

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
