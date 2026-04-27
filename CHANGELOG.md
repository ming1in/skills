# Changelog

## 0.2.0 — 2026-04-27

### Added

- **`install.sh`** — bundled installer for `skills/afk/`. Registers AFK's three lifecycle hooks (`Stop`, `SessionEnd`, `SessionStart`) in user-scope or project-scope `settings.json`. Idempotent (entries tagged `# afk-skill <path>` for dedupe), supports `--target`, `--print`, `--remove` flags. Auto-detects own location so it works regardless of how the skill was installed.
- **`afk-session-start.sh`** — SessionStart hook for AFK resume reminder. When a session restarts and `~/.claude/afk-stack/<session-id>.json` already shows `enabled=true` with `task_status=active`, injects an `additionalContext` banner via the documented `hookSpecificOutput` JSON shape so the resumed agent knows AFK is still on without waiting for the first Stop event. Catches the crash-resume case.
- **GitHub Actions CI** — `.github/workflows/test.yml` runs three jobs on every push/PR: shellcheck on all bundled scripts, JSON-parse validation of plugin manifests + version-divergence check, and an end-to-end AFK pipeline smoke test (enable → block → disable → release → SessionEnd cleanup).

### Documentation

- Per-skill README and top-level README updated with both the bundled-installer (Option A, recommended) and manual settings.json (Option B) install paths. Both now include a docs-grounded explanation of why settings.json registration is required for AFK (skill-scoped hooks fire only when the skill is active in conversation; AFK needs every-Stop).

### Why settings.json registration is required

Verified against [code.claude.com/docs/en/hooks § Hooks in Skills and Agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents): *"These hooks are scoped to the component's lifecycle and only run when that component is active."* AFK's `Stop` hook needs to fire on every session Stop regardless of whether `/afk` was the most-recently-invoked skill, so a skill-scoped hook would not work.

## 0.1.0 — 2026-04-26

### Added

- Initial scaffold: `.claude-plugin/marketplace.json` + `plugin.json`, `.codex-plugin/plugin.json`, `.opencode/INSTALL.md` placeholder, MIT `LICENSE`, top-level `README.md`.
- **`skills/afk/`** — first migrated skill from `big-one`. Self-contained directory with `SKILL.md`, `scripts/afk-{enable,disable,status,stop-hook,session-end}.sh`, and per-skill `README.md`. Per-session keyed via canonical Claude Code session_id; three-escape-valves loop guard (manual `/afk-off`, agent-written `task_status`, hard 50-iteration cap).
- **`skills/afk-off/`** and **`skills/afk-status/`** — companion skills sharing the AFK state stack.
