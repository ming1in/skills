# Ming's Agent Skills

Reusable agent skills, workflows, and adapters developed by Ming Lin.

This repo is intended to be used across multiple agent surfaces:

- Claude Code via `.claude-plugin/`
- Codex via `.codex-plugin/`
- OpenCode via `.opencode/`

The first planned skill is AFK mode: a session-level autonomous-work toggle
originally dogfooded in `big-one`.

## Repository Shape

```text
skills/
├── .claude-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── .codex-plugin/
│   └── plugin.json
├── .opencode/
│   └── INSTALL.md
├── skills/
│   └── README.md
└── README.md
```

## Development Model

This repo is developed from inside `big-one` as a submodule at:

```text
big-one/submodules/skills
```

`ming1in/skills` owns reusable implementation, release metadata, and public
docs. `big-one` owns private operating context, KG notes, and dogfooding
configuration.

## Planned Skills

- `afk` - Continue an in-flight agent session while the human is away from the
  keyboard.
- `people-search` - Privacy-preserving people lookup and friend-entry draft
  workflow.
- `kg-merge-resolution` - Knowledge graph merge conflict resolution workflow.

## License

MIT
