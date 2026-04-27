# `/afk-off` — Disable AFK Mode

Disables [`/afk`](../afk/) mode for the current Claude Code session. The `Stop` hook becomes a no-op for this session; other sessions in the AFK stack are unaffected.

Companion to [`/afk`](../afk/) — install both together.

## Usage

```text
/afk-off
```

Updates `~/.claude/afk-stack/<session-id>.json` to set `enabled: false`. Prints final stats (last task, iterations used).

## Install

### Claude Code

Shipped together with [`/afk`](../afk/) when you install the `ming-skills` plugin:

```text
/plugin marketplace add ming1in/skills
/plugin install ming-skills@ming-skills
```

`/afk-off` only flips the `enabled` flag in the per-session state file — it doesn't need additional hook setup beyond what AFK already requires. See [`skills/afk/README.md`](../afk/README.md#install) for the lifecycle-hook setup `/afk` needs.

### Codex

```bash
INSTALLER="$HOME/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py"
python3 "$INSTALLER" \
  --repo ming1in/skills \
  --path skills/afk-off
```

Restart Codex after installing. (You'll typically install this alongside `skills/afk` and `skills/afk-status` — see [the top-level README](../../README.md#codex).)

## Why session-scoped, not user-scoped

AFK's state file is keyed by canonical Claude Code session ID. Disabling AFK in Session A only affects Session A — other sessions in the AFK stack stay enabled. Run [`/afk-status`](../afk-status/) to see the full stack before disabling if you're not sure which session you're in.

## Related

- [`/afk`](../afk/) — enable AFK mode (the primary skill).
- [`/afk-status`](../afk-status/) — inspect AFK state across sessions.
