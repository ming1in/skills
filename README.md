# Ming's Agent Skills

[![CI](https://github.com/ming1in/skills/actions/workflows/test.yml/badge.svg)](https://github.com/ming1in/skills/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Reusable agent skills for **Claude Code**, **Codex**, and **OpenCode**. Install once, use across surfaces. Each skill is a self-contained directory with a `SKILL.md`, optional supporting scripts, and its own `README.md`.

## Skills

| Skill | What it does | Audience |
| --- | --- | --- |
| [`afk`](skills/afk/) | Step away from your keyboard and have your agent keep working autonomously. Subcommands: `/afk` (or `/afk on`) enables, `/afk off` disables, `/afk status` inspects. | Claude Code power users running long sessions |

## Install

### Claude Code

Add this repo as a plugin marketplace, then install the bundle:

```text
/plugin marketplace add ming1in/skills
/plugin install ming-skills@ming-skills
```

Some skills (like `afk`) need lifecycle hooks registered in your `.claude/settings.json`. Each skill's README documents the additional setup. AFK ships a bundled installer:

```bash
bash skills/afk/install.sh                       # add to ~/.claude/settings.json
bash skills/afk/install.sh --print               # preview, no write
bash skills/afk/install.sh --remove              # uninstall, idempotent
```

See [`skills/afk/README.md`](skills/afk/README.md) for full details.

### Codex

```bash
INSTALLER="$HOME/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py"
python3 "$INSTALLER" --repo ming1in/skills --path skills/afk
```

As of v0.3.0 there's only one skill (`afk`) — earlier versions had three (`afk`, `afk-off`, `afk-status`) and you'd pass them all to one `--path` invocation. The repeatable `--path` mechanism still works for future skills.

Restart Codex after installing. The installer drops files into `$CODEX_HOME/skills/` (default `~/.codex/skills/`). It aborts if a destination already exists — to update, delete the destination directory and re-run.

> **Note:** AFK's autonomous Stop-hook behavior currently uses Claude-Code-specific env substitutions (`${CLAUDE_SKILL_DIR}`, `${CLAUDE_SESSION_ID}`). Codex has compatible `SessionStart` and `Stop` hooks (the `Stop` hook supports the same `decision: "block"` continuation pattern), so the AFK-on-Codex adapter is a small port — not blocked on missing platform features. Until that adapter ships, installing under Codex makes the skill source available for review.

### OpenCode

Install path TBD — see [`.opencode/INSTALL.md`](.opencode/INSTALL.md).

### Local development

If you've cloned this repo (or use it as a git submodule like `big-one` does at `submodules/skills`), point Claude Code at the local checkout instead of GitHub:

```text
/plugin marketplace add ./submodules/skills
/plugin install ming-skills@ming-skills
```

For Codex, symlink the skill directory into `$CODEX_HOME/skills/`:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
ln -s "$PWD/skills/afk" "${CODEX_HOME:-$HOME/.codex}/skills/afk"
```

## Quick start (Claude Code + AFK)

```text
# Plugin registered, hooks installed, /afk available

# Start working with Claude on something long-running:
"Help me refactor the user-auth module"
…work, work…

# Step away — AFK keeps the agent going on the in-flight work:
/afk

# (close laptop, get coffee)

# Check what happened:
/afk status

# Done?
/afk off
```

The agent keeps working through Stop events until it self-marks `task_status: "done"` (work complete) or `task_status: "blocked"` (hard approval gate hit), or you run `/afk off`. A 50-iteration cap prevents runaway loops.

## Repository shape

```text
.
├── .claude-plugin/         # Claude Code marketplace + plugin manifests
├── .codex-plugin/          # Codex plugin manifest
├── .opencode/              # OpenCode install notes (placeholder)
├── .github/workflows/      # CI: shellcheck + JSON validation + AFK smoke test
├── skills/
│   └── afk/                # /afk slash command (verbs: on/off/status) + scripts + install.sh
├── CHANGELOG.md
├── LICENSE                 # MIT
└── README.md
```

The `afk` directory has a `SKILL.md` (the slash-command body that dispatches on verb), a `README.md` (human-facing docs), bundled `scripts/`, and `install.sh` for hook registration.

## Why settings.json hooks (not skill-scoped frontmatter)

Skills can declare hooks in their `SKILL.md` frontmatter via the `hooks` field, but those hooks fire **only when the skill is active in the current conversation**. AFK needs `Stop` to fire on *every* session Stop regardless of whether `/afk` was the most-recently-invoked skill, so AFK uses settings.json hook registration. Verified against [code.claude.com/docs/en/hooks § Hooks in Skills and Agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents).

## For contributors

This repo is the public, portable home for skills that are dogfooded in a private monorepo (`big-one`) before being shared. Development protocol:

1. Make reusable skill changes in this repo (or via `big-one/submodules/skills` checkout).
2. Keep skill folders minimal — `SKILL.md` plus only what the skill needs at runtime.
3. Monorepo-specific context goes in `big-one/knowledge/`, not here.
4. Commit and push this repo before bumping the submodule gitlink in `big-one`.
5. Use a temporary `$HOME` when smoke-testing scripts that touch user-level state.

CI ([`.github/workflows/test.yml`](.github/workflows/test.yml)) runs on every push and pull request to `main`:

- `shellcheck` on every `*.sh` under `skills/`
- JSON parse validation of plugin manifests + version uniformity across `marketplace.json`, `.claude-plugin/plugin.json`, and `.codex-plugin/plugin.json`
- 7-step end-to-end AFK pipeline smoke test (no-state silence → enable → stop hook block → disable → release → re-enable → status → SessionEnd cleanup)

## Why these skills

`afk` was the seed — Ming wanted to step away during long sessions without losing autonomous progress, and the existing patterns (ralph-loop, `--dangerously-skip-permissions`) didn't fit. The skill became a reference design for "smarter loops that write themselves" — the agent owns its own continue/done/blocked signal via a state file rather than re-injecting a fixed prompt. As of v0.3.0, AFK is one consolidated skill with verb subcommands (`on`/`off`/`status`); earlier versions split these as three separate slash commands.

## Planned skills

- `people-search` — privacy-preserving people lookup and friend-entry draft workflow.
- `kg-merge-resolution` — knowledge graph merge conflict resolution workflow.

## Prior art

Borrowing README patterns from these public skills repos:

- [`anthropics/skills`](https://github.com/anthropics/skills) — self-contained `SKILL.md` per directory model.
- [`openai/skills`](https://github.com/openai/skills) — concise catalog and installer-focused README.
- [`vercel-labs/agent-skills`](https://github.com/vercel-labs/agent-skills) — repository guidance and skill authoring conventions.
- [`mxyhi/ok-skills`](https://github.com/mxyhi/ok-skills) — browseable cross-agent skill index.

## License

MIT — see [`LICENSE`](LICENSE).
