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
| Claude Code | Local plugin scaffold | [`.claude-plugin/`](.claude-plugin/) |
| Codex | Local plugin scaffold | [`.codex-plugin/`](.codex-plugin/) |
| OpenCode | Install notes placeholder | [`.opencode/INSTALL.md`](.opencode/INSTALL.md) |

The repository follows the Agent Skills convention: each skill is a directory
with a required `SKILL.md`, optional scripts, and optional references or assets.

## Included Skills

| Skill | What it does | Notes |
| --- | --- | --- |
| [`afk`](skills/afk/) | Enables away-from-keyboard autonomous work for the current session. | First migrated skill from `big-one`. |
| [`afk-off`](skills/afk-off/) | Disables AFK mode for the current session. | Shares the AFK state stack. |
| [`afk-status`](skills/afk-status/) | Shows current AFK state and other active AFK sessions. | Useful for cross-session dogfooding. |

## Install And Use

### Claude Code From `big-one`

`big-one` consumes this repo as a git submodule at `submodules/skills`. Its
project settings register the local plugin source and point AFK hooks at this
repo's scripts:

```text
big-one/
  .claude/settings.json
  submodules/skills/
```

When developing from `big-one`, commit skill implementation changes inside this
repo first, then update the submodule pointer in `big-one`.

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
├── scripts/
│   └── afk-*.sh
├── skills/
│   ├── afk/
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
