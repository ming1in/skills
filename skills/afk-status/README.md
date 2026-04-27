# `/afk-status` — Show AFK State

Prints the current Claude Code session's AFK state plus a one-line summary of any other sessions in the AFK stack. Useful for cross-session debugging.

Companion to [`/afk`](../afk/) — install both together.

## Usage

```text
/afk-status
```

Example output (this session has AFK on, two other sessions in the stack):

```text
AFK mode (this session, abc12345…): ON
  Task:        scaffold the new project
  Started:     2026-04-27T10:00:00-0400
  Iterations:  3 / 50
  Status:      active

Other sessions in AFK stack:
  [ON ] def67890… status=active task='research run'
  [off] 12345678… status=done   task='build pipeline'
```

If AFK isn't on for the current session, the first line shows `OFF`. The "Other sessions" block shows up only when there are other entries in `~/.claude/afk-stack/`.

## Install

### Claude Code

Shipped together with [`/afk`](../afk/) when you install the `ming-skills` plugin:

```text
/plugin marketplace add ming1in/skills
/plugin install ming-skills@ming-skills
```

`/afk-status` is read-only — it doesn't need additional hook setup beyond what AFK already requires. See [`skills/afk/README.md`](../afk/README.md#install) for the lifecycle-hook setup.

### Codex

```bash
INSTALLER="$HOME/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py"
python3 "$INSTALLER" \
  --repo ming1in/skills \
  --path skills/afk-status
```

Restart Codex after installing. (You'll typically install this alongside `skills/afk` and `skills/afk-off` — see [the top-level README](../../README.md#codex).)

## Why show other sessions

AFK is per-session keyed (canonical Claude Code session ID). Enabling AFK in Session A doesn't affect Session B. The status command surfaces other entries in `~/.claude/afk-stack/` so cross-session leakage stays visible during dogfooding — if you forgot to `/afk-off` in another session, you'll see it here.

## Related

- [`/afk`](../afk/) — enable AFK mode (the primary skill).
- [`/afk-off`](../afk-off/) — disable AFK for the current session.
