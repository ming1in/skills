# Contributing to `ming1in/skills`

Reusable agent skills for Claude Code, Codex, and OpenCode. This repo is small, opinionated, and dogfooded — contributions welcome but the bar is "is this skill genuinely reusable across agent surfaces?"

## Repository shape

```text
.
├── .claude-plugin/         # Claude Code marketplace + plugin manifests
├── .codex-plugin/          # Codex plugin manifest
├── .opencode/              # OpenCode install notes (placeholder)
├── .github/workflows/      # CI: shellcheck + JSON validation + AFK smoke test
├── skills/
│   ├── <skill-name>/
│   │   ├── SKILL.md        # required — the slash-command body
│   │   ├── README.md       # required — human-facing docs
│   │   ├── scripts/        # optional — implementation scripts
│   │                       # lifecycle hooks declared in plugin.json `hooks`
│   └── ...
├── CHANGELOG.md
├── LICENSE                 # MIT
└── README.md
```

Each skill is a self-contained directory. No shared `scripts/` at the repo root — if scripts are part of a skill, they live under `skills/<name>/scripts/` so the directory is the unit of distribution.

## Adding a new skill

1. **Decide audience.** Is this useful to anyone running a coding agent? If it's specific to one person's setup or one project's KG, it belongs in that project's monorepo, not here.
2. **Create the directory:**
   ```text
   skills/<skill-name>/
   ├── SKILL.md
   └── README.md
   ```
3. **`SKILL.md`** is the slash-command body. Frontmatter must include `name` and `description`. Use `${CLAUDE_SKILL_DIR}` for any paths to bundled scripts — that substitution gives you the absolute path to the skill directory regardless of how the skill was installed.
4. **`README.md`** documents what the skill does, install steps for each agent surface (Claude Code via plugin marketplace, Codex via `install-skill-from-github.py`, OpenCode TBD), and any gotchas.
5. **`scripts/`** if needed. Make scripts shellcheck-clean (CI runs shellcheck on `**/*.sh` under `skills/`).
6. **Add to top-level `README.md`** "Included Skills" table so discoverability is preserved.
7. **Bump version** in all three plugin manifests:
   - `.claude-plugin/marketplace.json` (the `plugins[0].version` field)
   - `.claude-plugin/plugin.json`
   - `.codex-plugin/plugin.json`

   CI's "Plugin version uniformity" step fails if the three diverge.
8. **Add CHANGELOG entry** describing what shipped.

## CI checks

`.github/workflows/test.yml` runs on every push and PR to `main`:

- **`shellcheck`** on every `*.sh` file under `skills/`. No warnings allowed.
- **JSON parse validation** of `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`.
- **Plugin version uniformity** — all three plugin manifests must share the same version string. Catches the most common version-bump mistake (bumping one and forgetting the others).
- **AFK pipeline smoke test** — 7 steps exercising enable → block → disable → release → re-enable → status → SessionEnd cleanup. Lives in `test.yml` because AFK is the canonical reference skill in this repo; if you add a similar lifecycle skill, add a corresponding smoke test job.

## Versioning

[Semantic Versioning](https://semver.org/). Roughly:

- **Patch** (0.x.Y): bug fixes, doc improvements, no behavior change for existing users.
- **Minor** (0.X.0): new features, additive changes, backward-compatible.
- **Major** (X.0.0): breaking changes, removed features, incompatible behavior changes.

The repo is pre-1.0 right now (0.x), so minor bumps are the typical rhythm; we'll commit to API stability when something is genuinely battle-tested across multiple users and surfaces.

## Local development

The `big-one` private monorepo consumes this repo as a git submodule at `submodules/skills`. Development typically happens from inside `big-one`:

```bash
cd big-one/submodules/skills
# make changes
git commit -m "..."
git push origin main          # CI runs on this push
cd ../..
git add submodules/skills     # advance big-one's recorded pointer
git commit + git push          # OR let big-one's GH Action auto-bump it
```

The `big-one`-side automation (`sync-submodules.yml` + `auto-approve-bumps.yml`) auto-bumps the submodule pointer in `big-one` when this repo gets a new green-CI commit — so often you don't need to manually advance the pointer at all.

## Testing locally before pushing

For shell scripts, install `shellcheck` (via `brew install shellcheck` on macOS) and run:

```bash
find skills -name '*.sh' -exec shellcheck {} +
```

For the AFK pipeline specifically:

```bash
# In a temp directory:
SESSION_ID="local-test-$(uuidgen)"
bash skills/afk/scripts/afk-enable.sh "$SESSION_ID" "test"
echo "{\"session_id\":\"$SESSION_ID\"}" | bash skills/afk/scripts/afk-stop-hook.sh   # should print block JSON
bash skills/afk/scripts/afk-disable.sh "$SESSION_ID"
echo "{\"session_id\":\"$SESSION_ID\"}" | bash skills/afk/scripts/afk-session-end.sh  # cleans up
```

## License

MIT — by contributing, you agree your contribution is licensed under the same terms. See [`LICENSE`](LICENSE).
