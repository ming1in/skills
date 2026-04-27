# Ming's Agent Skills

Reusable agent skills, workflows, and adapters developed by Ming Lin.

This repository is the public, portable home for skills that are dogfooded in
`big-one` and then shared across agent surfaces. The goal is simple: write the
skill once, keep the implementation public, and consume it from private or
product monorepos without copy-paste drift.

## Start Here

- Browse available skills in [`skills/`](skills/).
- Use [`skills/afk`](skills/afk/) when an agent should continue current session
  work while the human is away.
- Develop locally from `big-one/submodules/skills` when working inside the
  private monorepo.
- Keep private operating notes, KG entries, and dogfood logs in `big-one`; keep
  reusable skill source and public docs here.

## Supported Agents

| Agent surface | Status | Entry point |
| --- | --- | --- |
| Claude Code | Plugin marketplace | [`.claude-plugin/`](.claude-plugin/) |
| Codex | Skill install or plugin scaffold | [`.codex-plugin/`](.codex-plugin/) |
| OpenCode | Install notes placeholder | [`.opencode/INSTALL.md`](.opencode/INSTALL.md) |

The repository follows the Agent Skills convention: each skill is a directory
with a required `SKILL.md`, optional scripts, and optional references or assets.

## Included Skills

| Skill | What it does | Notes |
| --- | --- | --- |
| [`afk`](skills/afk/) | Enables away-from-keyboard autonomous work for the current session. | First migrated skill from `big-one`. |
| [`afk-off`](skills/afk-off/) | Disables AFK mode for the current session. | Shares the AFK state stack. |
| [`afk-status`](skills/afk-status/) | Shows current AFK state and other active AFK sessions. | Useful for cross-session dogfooding. |

## Setup

### Claude Code

Claude Code installs skills through plugins and plugin marketplaces. Add this
repo as a marketplace, then install the `ming-skills` plugin:

```text
/plugin marketplace add ming1in/skills
/plugin install ming-skills@ming-skills
```

For local development from a checkout, add the checkout as a local marketplace:

```text
/plugin marketplace add ./submodules/skills
/plugin install ming-skills@ming-skills
```

Project teams can also register this marketplace in `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "ming-skills": {
      "source": {
        "source": "github",
        "repo": "ming1in/skills"
      }
    }
  },
  "enabledPlugins": {
    "ming-skills@ming-skills": true
  }
}
```

AFK needs three Claude Code lifecycle hooks to enforce and clean up AFK state: `Stop` (block session exit while active), `SessionEnd` (clean up the per-session state file on clean exit), and `SessionStart` (resume-reminder if the previous session crashed mid-AFK). The fastest path is the bundled installer:

```bash
bash skills/afk/install.sh                         # add to ~/.claude/settings.json
bash skills/afk/install.sh --target /project/.claude/settings.json
bash skills/afk/install.sh --print                 # preview, no write
bash skills/afk/install.sh --remove                # uninstall (idempotent)
```

The installer is idempotent (entries are tagged so re-runs dedupe) and `--remove` cleans up only AFK entries, preserving any other hooks in the file.

If you'd rather wire hooks by hand, point them at the installed or checked-out scripts (the `big-one` monorepo dogfoods this exact shape):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/submodules/skills/skills/afk/scripts/afk-stop-hook.sh",
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
            "command": "\"$CLAUDE_PROJECT_DIR\"/submodules/skills/skills/afk/scripts/afk-session-end.sh",
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
            "command": "\"$CLAUDE_PROJECT_DIR\"/submodules/skills/skills/afk/scripts/afk-session-start.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

The `big-one` monorepo consumes this repo as a git submodule at
`submodules/skills` and uses that hook shape while dogfooding AFK.

**Why settings.json hooks (not skill-scoped frontmatter):** skill-scoped hooks declared in SKILL.md `hooks:` only fire when the skill is currently active in the conversation. AFK needs `Stop` to fire on every session Stop regardless of whether `/afk` was the most-recently-invoked skill, so settings.json registration is required. Verified against [code.claude.com/docs/en/hooks § Hooks in Skills and Agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents).

### Codex

Codex can install individual skills from a GitHub repo path into
`$CODEX_HOME/skills`. This makes the skill source available to Codex for
development and review; AFK's autonomous Stop-hook behavior is currently
Claude-Code-specific until a Codex lifecycle adapter exists.

```bash
INSTALLER="$HOME/.codex/skills/.system/skill-installer/scripts/install-skill-from-github.py"
python3 "$INSTALLER" \
  --repo ming1in/skills \
  --path skills/afk skills/afk-off skills/afk-status
```

Restart Codex after installing skills.

For local development, install from the checked-out repo by copying or symlinking
the skill directories into `$CODEX_HOME/skills`:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
ln -s "$PWD/skills/afk" "${CODEX_HOME:-$HOME/.codex}/skills/afk"
ln -s "$PWD/skills/afk-off" "${CODEX_HOME:-$HOME/.codex}/skills/afk-off"
ln -s "$PWD/skills/afk-status" "${CODEX_HOME:-$HOME/.codex}/skills/afk-status"
```

The `.codex-plugin/plugin.json` manifest is kept in this repo so the same source
can also be exposed through Codex plugin workflows as that surface matures.

### Manual Skill Use

For tools that can load a directory of `SKILL.md` folders, point the tool at the
skill directory you need:

```text
skills/afk/
skills/afk-off/
skills/afk-status/
```

AFK currently expects Claude Code session metadata and project hook wiring. Other
agent adapters should preserve the same state-machine behavior while replacing
Claude-specific session and hook plumbing.

## Repository Shape

```text
.
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── .codex-plugin/
│   └── plugin.json
├── .opencode/
│   └── INSTALL.md
├── skills/
│   ├── afk/
│   │   ├── SKILL.md
│   │   └── scripts/
│   ├── afk-off/
│   ├── afk-status/
│   └── README.md
└── README.md
```

## Development Protocol

1. Make reusable skill changes in this repo, even when editing from the
   `big-one/submodules/skills` checkout.
2. Keep skill folders minimal: `SKILL.md` plus only the scripts, references, or
   assets that the skill needs at runtime.
3. Put monorepo-specific context in `big-one/knowledge`, not in this public repo.
4. Commit and push this repo before staging the updated submodule gitlink in
   `big-one`.
5. Run the moved scripts with a temporary `HOME` before publishing changes that
   touch user-level state.

## Prior Art

This repo is intentionally borrowing proven README patterns from public skills
catalogs:

- [`openai/skills`](https://github.com/openai/skills) for a concise catalog and
  installer-focused README.
- [`anthropics/skills`](https://github.com/anthropics/skills) for the
  self-contained `SKILL.md` per directory model.
- [`vercel-labs/agent-skills`](https://github.com/vercel-labs/agent-skills) for
  agent-facing repository guidance and skill authoring conventions.
- [`mxyhi/ok-skills`](https://github.com/mxyhi/ok-skills) for a browseable
  cross-agent skill index.

## Planned Skills

- `people-search` - Privacy-preserving people lookup and friend-entry draft
  workflow.
- `kg-merge-resolution` - Knowledge graph merge conflict resolution workflow.

## License

MIT
