# `/afk` — Away From Keyboard Skill

Enable autonomous agent operation while you step away. The agent keeps working on the current session's in-flight tasks; an optional task argument adds focused context without replacing what's already in flight.

## What it does

Running `/afk` writes a per-session state file at `~/.claude/afk-stack/<session-id>.json`. A `Stop` hook reads that file on every session stop event and returns `{"decision": "block"}` to prevent the session from closing — keeping the agent running autonomously. A `SessionEnd` hook cleans up the state file on clean exit.

Three escape valves prevent runaway loops:

1. **`/afk off`** — manual disable from any Claude Code session
2. **`task_status: "done"` or `"blocked"`** — the agent writes this itself when work is complete or hits a hard blocker
3. **Iteration cap** — the hook stops blocking after 50 Stop events (configurable in the state file)

## How it differs from `--dangerously-skip-permissions`

`--dangerously-skip-permissions` silences all permission prompts globally and permanently for the session. AFK is different:

- AFK keeps approval gates intact — the agent still pauses for merge-to-main, external messages, money movement, and destructive ops. It just handles everything else without asking.
- AFK is reversible mid-session. `/afk off` returns the session to normal interactive mode.
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
/afk status

# Disable when you're back:
/afk off
```

Bare `/afk` (no argument) tells the agent to continue the current session's in-flight work. The argument is optional added context, not a replacement for session state.

## Install

### Claude Code

```text
/plugin marketplace add ming1in/skills
/plugin install ming-skills@ming-skills
```

That's it — single step. As of v0.4.0, AFK's three lifecycle hooks (`Stop`, `SessionEnd`, `SessionStart`) ship inside the plugin (declared in `.claude-plugin/plugin.json` `hooks` field) and activate automatically whenever the plugin is enabled. No `install.sh` to run, no `~/.claude/settings.json` edit required.

For local development from a checkout (e.g. as a submodule), point Claude Code at the local directory instead:

```text
/plugin marketplace add ./submodules/skills
/plugin install ming-skills@ming-skills
```

> **Migrating from v0.3.x?** Earlier versions required running `bash install.sh` after install to register the hooks in your `~/.claude/settings.json`. Those entries are now redundant — they'll fire alongside the bundled hooks, doubling every event. Clean them up before upgrading: any line in `~/.claude/settings.json` `hooks` containing `# afk-skill` should be removed. One-liner:
> ```bash
> python3 -c "
> import json, os
> p = os.path.expanduser('~/.claude/settings.json')
> s = json.load(open(p))
> s['hooks'] = {e: [g for g in groups if not any('afk-skill' in h.get('command','') for h in g.get('hooks', []))] for e, groups in s.get('hooks', {}).items()}
> s['hooks'] = {k: v for k, v in s['hooks'].items() if v}
> json.dump(s, open(p, 'w'), indent=2)"
> ```

### Codex

```bash
INSTALLER="$HOME/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py"
python3 "$INSTALLER" --repo ming1in/skills --path skills/afk
```

Restart Codex after installing.

> **Note:** AFK's autonomous Stop-hook behavior currently uses Claude-Code-specific env substitutions (`${CLAUDE_SKILL_DIR}`, `${CLAUDE_SESSION_ID}`). Codex has compatible `SessionStart` and `Stop` hooks (the `Stop` hook supports the same `decision: "block"` continuation pattern), so the AFK-on-Codex adapter is a small port — not blocked on missing platform features. Until that adapter ships, installing under Codex makes the skill source available for review.

For local development, install from a checked-out repo by symlinking the skill directory into `$CODEX_HOME/skills`:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
ln -s "$PWD/skills/afk" "${CODEX_HOME:-$HOME/.codex}/skills/afk"
```

### Verb subcommands

`/afk` is one slash command with three verbs (consolidated in v0.3.0 from three separate skills). All verbs share the AFK state stack at `~/.claude/afk-stack/<session-id>.json`:

| Invocation | What it does |
|------------|--------------|
| `/afk` | Enable AFK mode (default verb is `on`) |
| `/afk "<task>"` | Enable with focus context (first arg is treated as task because it's not a recognized verb) |
| `/afk on [task]` | Enable explicitly |
| `/afk off` | Disable for this session |
| `/afk status` | Show current state + other sessions in the AFK stack |

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

The agent writes `task_status: "done"` or `task_status: "blocked"` (with a `block_reason` field) to signal the hook to release. `/afk off` deletes the state file entirely.

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

## Troubleshooting

### `/afk` runs but the session ends anyway

Check `~/.claude/afk-stack/<your-session-id>.json` exists and shows `"enabled": true, "task_status": "active"`. If the file is missing or `enabled` is `false`, AFK didn't actually engage. Likely causes:

- The skill body's path resolution failed (older `${CLAUDE_SKILL_DIR}` regression). Re-run `/afk status` — if it errors with a path not found, your install is stale; reinstall via `/plugin uninstall ming-skills@ming-skills` then `/plugin install ming-skills@ming-skills` (use `--scope project` if installed at project scope).
- Hooks not loaded. The three lifecycle hooks (`Stop`, `SessionEnd`, `SessionStart`) ship inside the plugin's `.claude-plugin/plugin.json` and are wired automatically when the plugin is enabled. Verify with `/plugin` picker → ming-skills entry → check for the hooks. If still on v0.3.x, follow the v0.4.0 migration in the install section above.
- A different session beat you to a Stop event. The state file is keyed by canonical session ID — the hook only fires on Stop events from your session. Run `/afk status` to confirm your session's entry exists.

### Install ran but hooks aren't firing

Verify the hook scripts are executable and the paths in `settings.json` resolve:

```bash
# Verify the bundled hooks are registered + executable:
python3 -c "
import json, os
with open(os.path.expanduser('~/.claude/settings.json')) as f:
    s = json.load(f)
for event in ('Stop', 'SessionEnd', 'SessionStart'):
    for group in s.get('hooks', {}).get(event, []):
        for h in group.get('hooks', []):
            cmd = h.get('command', '')
            if 'afk-skill' not in cmd:
                continue
            path = cmd.split()[-1]  # last token is the script path
            print(f'{event}: {path} {\"✅\" if os.access(path, os.X_OK) else \"❌ NOT EXECUTABLE\"}')
"
```

If a path shows ❌, run `chmod +x` on it. If a path doesn't exist, the plugin install is broken — uninstall + reinstall via `/plugin uninstall ming-skills@ming-skills` then `/plugin install ming-skills@ming-skills`.

### How to see what the hooks are doing

Hook activity logs to `$AFK_TIMING_LOG` if set, otherwise to `<repo-root>/tmp/hook-timing.log` adjacent to the plugin's scripts directory. To enable timing logs in the plugin-bundled hook context, set `AFK_TIMING_LOG` in your shell environment before launching Claude Code, OR add a project-scope settings.json hook that wraps the bundled hook with the env var prefix (note: this duplicates the bundled hook firing, only worth it if you specifically need the timing log).

Then `tail -f tmp/hook-timing.log` shows one line per fire: `<ISO-ts>\t<script-name>\tduration_ms=<ms>\texit=<code>`. If you don't see entries when AFK should be active, the hook isn't being invoked — check `settings.json` registration first.

### Stuck `task_status: active` after agent should be done

The agent is supposed to write `task_status: "done"` to the state file when work completes. If it forgot:

```bash
# Replace SESSION_ID with yours from /afk status output
python3 -c "
import json, os
p = os.path.expanduser(f'~/.claude/afk-stack/SESSION_ID.json')
s = json.load(open(p))
s['task_status'] = 'done'
json.dump(s, open(p, 'w'), indent=2)
"
```

Or simpler: run `/afk off` (flips `enabled` to `false`; same release effect).

### Iteration cap kept hitting before work completed

The default cap is 50 Stop events per AFK invocation. If your work routinely exceeds that, either:

- Bump the cap by editing the state file directly: `python3 -c "import json,os; p=os.path.expanduser('~/.claude/afk-stack/<id>.json'); s=json.load(open(p)); s['max_iterations']=200; json.dump(s,open(p,'w'),indent=2)"`
- Break the work into smaller, more focused tasks per `/afk` invocation
- File a feature request for a `/afk --cap N "<task>"` flag

### Cross-session bleed (Session B's Stop blocks even though /afk was in Session A)

This was a real bug pre-v0.2.0 (the state file was user-scope single-file). If you see this on v0.2.0+: run `/afk status` and inspect "Other sessions in AFK stack" — confirm the entry is keyed by the *correct* session ID. If multiple entries exist for the same session ID (shouldn't happen), report it as a bug with the contents of `ls ~/.claude/afk-stack/`.

### Removing AFK from a project / user setup

```bash
/plugin uninstall ming-skills@ming-skills   # removes the plugin and its bundled hooks together
```

To also clear any lingering state files: `rm -rf ~/.claude/afk-stack/`. State files are ephemeral runtime state — safe to delete when no AFK session is active.

## Known limitations

- **Hook wiring is not self-contained.** The `Stop` and `SessionEnd` hooks must be registered manually in `.claude/settings.json`. Skill-scoped hook support (where hooks come with the skill directory automatically) is a planned Claude Code feature — when it ships, AFK will be updated to use it.
- **Session-ID availability.** The `${CLAUDE_SESSION_ID}` substitution is only available in `SKILL.md` files, not in `.claude/commands/*.md` files. Don't move this skill to the commands format.
- **Iteration cap is per-session.** The cap resets if the session restarts. For very long tasks, increase `max_iterations` in the state file manually.
