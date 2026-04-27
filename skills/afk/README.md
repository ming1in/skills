# `/afk` — Away From Keyboard Skill

Enable autonomous agent operation while you step away. The agent keeps working on the current session's in-flight tasks; an optional task argument adds focused context without replacing what's already in flight.

## What it does

Running `/afk` writes a per-session state file at `~/.claude/afk-stack/<session-id>.json`. A `Stop` hook reads that file on every session stop event and returns `{"decision": "block"}` to prevent the session from closing — keeping the agent running autonomously. A `SessionEnd` hook cleans up the state file on clean exit.

Three escape valves prevent runaway loops:

1. **`/afk-off`** — manual disable from any Claude Code session
2. **`task_status: "done"` or `"blocked"`** — the agent writes this itself when work is complete or hits a hard blocker
3. **Iteration cap** — the hook stops blocking after 50 Stop events (configurable in the state file)

## How it differs from `--dangerously-skip-permissions`

`--dangerously-skip-permissions` silences all permission prompts globally and permanently for the session. AFK is different:

- AFK keeps approval gates intact — the agent still pauses for merge-to-main, external messages, money movement, and destructive ops. It just handles everything else without asking.
- AFK is reversible mid-session. `/afk-off` returns the session to normal interactive mode.
- AFK is session-scoped and keyed by session ID — enabling it in Session A doesn't affect Session B running concurrently.
- AFK gives the agent operating principles to reason with, not just a blanket permission removal.

The canonical framing: **AFK is a smarter loop that writes itself** — the agent owns its own continue/done/blocked signal rather than a fixed re-injected prompt. `--dangerously-skip-permissions` is a blunt tool for a different use case (fully automated pipelines where human oversight is a bug, not a feature).

## Developer flow

> "I start working with Claude. As I work through things with Claude, I can run `/afk`, step away, and the agent will continue to work as if I'm away from my keyboard. It will keep executing the work even while I'm away." — Ming

Typical session:

```
# Start a session, do some work together
/afk "continue the autobrowse rate-limit investigation"

# Step away. Agent keeps working.
# On return — check what happened:
/afk-status

# Disable when you're back:
/afk-off
```

Bare `/afk` (no argument) tells the agent to continue the current session's in-flight work. The argument is optional added context, not a replacement for session state.

## Install

### 1. Register the hook scripts

AFK requires three lifecycle hooks registered in your `.claude/settings.json`: `Stop` (blocks session exit while active), `SessionEnd` (cleans up state file on clean exit), and `SessionStart` (resume-reminder if a previous session crashed mid-AFK). The fastest path is the bundled installer.

#### Option A — bundled `install.sh` (recommended)

From the skill directory:

```bash
bash install.sh                         # add to ~/.claude/settings.json (user-scope)
bash install.sh --target /project/.claude/settings.json   # project-scope
bash install.sh --print                 # preview the resulting JSON, no write
bash install.sh --remove                # uninstall (idempotent)
```

The installer auto-detects its own location (`$BASH_SOURCE/scripts/...`) and writes absolute paths to the three hook scripts. Re-running is idempotent — entries are tagged `# afk-skill <path>` so the script can find and dedupe them. `--remove` cleanly removes only the AFK entries; unrelated hooks in the same settings file are preserved.

#### Option B — manual settings.json edit

If you'd rather wire it up by hand:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/path/to/skills/afk/scripts/afk-stop-hook.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/path/to/skills/afk/scripts/afk-session-end.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/path/to/skills/afk/scripts/afk-session-start.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Replace `path/to/skills` with the actual path to where you've installed the skill directory.

Optional: pass `AFK_TIMING_LOG` to write per-hook timing to a log file:

```json
"command": "AFK_TIMING_LOG=\"$CLAUDE_PROJECT_DIR/tmp/hook-timing.log\" \"$CLAUDE_PROJECT_DIR\"/path/to/skills/afk/scripts/afk-stop-hook.sh"
```

#### Why settings.json registration is required

Skill-scoped hooks declared via SKILL.md frontmatter `hooks` field only fire when the skill is active in the conversation. AFK needs `Stop` to fire on **every** session Stop regardless of whether `/afk` was the most-recently-invoked skill, so settings.json registration is necessary. Verified against [code.claude.com/docs/en/hooks § Hooks in Skills and Agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents).

### 2. Install the skill (Claude Code plugin)

If this repo is registered as a Claude Code plugin marketplace, install via:

```text
/plugin install ming-skills@ming-skills
```

For local development from a git checkout (e.g. as a submodule):

```json
{
  "extraKnownMarketplaces": {
    "ming-skills-local": {
      "source": {
        "source": "directory",
        "path": "${CLAUDE_PROJECT_DIR}/path/to/skills-repo"
      }
    }
  },
  "enabledPlugins": {
    "ming-skills@ming-skills-local": true
  }
}
```

### 3. Companion skills

Install `afk-off` and `afk-status` from the same repo — they share the AFK state stack and make the workflow complete:

| Skill | Command | What it does |
|-------|---------|--------------|
| `afk` | `/afk [task]` | Enable AFK mode for this session |
| `afk-off` | `/afk-off` | Disable AFK mode for this session |
| `afk-status` | `/afk-status` | Show current AFK state + other active sessions |

## State file format

```json
{
  "enabled": true,
  "session_id": "<claude-session-id>",
  "task": "optional task description",
  "started_at": "2026-04-27T12:00:00+0000",
  "iterations": 12,
  "max_iterations": 50,
  "task_status": "active"
}
```

The agent writes `task_status: "done"` or `task_status: "blocked"` (with a `block_reason` field) to signal the hook to release. `/afk-off` deletes the state file entirely.

## Testing

Smoke-test the Stop hook directly with a mock payload:

```bash
echo '{"session_id": "test-session-001", "hook_event_name": "Stop"}' \
  | AFK_STATE_FILE=/tmp/afk-test.json ./scripts/afk-stop-hook.sh
```

First run (no state file): exits 0, no output — correct.

```bash
AFK_SESSION_OVERRIDE=test-session-001 ./scripts/afk-enable.sh test-session-001 "test task"
echo '{"session_id": "test-session-001"}' | ./scripts/afk-stop-hook.sh
```

Second run (AFK active): prints JSON `{"decision": "block", "reason": "..."}` — correct.

## Known limitations

- **Hook wiring is not self-contained.** The `Stop` and `SessionEnd` hooks must be registered manually in `.claude/settings.json`. Skill-scoped hook support (where hooks come with the skill directory automatically) is a planned Claude Code feature — when it ships, AFK will be updated to use it.
- **Session-ID availability.** The `${CLAUDE_SESSION_ID}` substitution is only available in `SKILL.md` files, not in `.claude/commands/*.md` files. Don't move this skill to the commands format.
- **Iteration cap is per-session.** The cap resets if the session restarts. For very long tasks, increase `max_iterations` in the state file manually.
