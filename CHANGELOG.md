# Changelog

## 0.3.2 — 2026-04-27 (test release)

### Added (test infrastructure — temporary)

- **Plugin-bundled Stop hook** declared in `.claude-plugin/plugin.json`'s `hooks` field, pointing at `skills/afk/scripts/afk-bundled-hook-test.sh`. The hook just appends a timestamped line to `/tmp/afk-bundled-hook-test.log` and exits 0 — no functional behavior change to AFK.
- **`scripts/afk-bundled-hook-test.sh`** — empirical test of whether Claude Code's plugin-bundled hooks fire always-on once the plugin is enabled, or only when the skill is actively invoked. The Claude Code research at `operations-pod/claude-code/engineering.md` flagged this as an open question; this release answers it empirically.

### Test protocol

After installing v0.3.2:
1. Open a fresh Claude Code session in any project
2. Do NOT invoke `/afk` in that session
3. Send any message and let the agent finish (triggers Stop)
4. Check `/tmp/afk-bundled-hook-test.log`

- **Log has an entry** → bundled hooks fire always-on after install → AFK can drop `install.sh` in v0.4.0 (single-step install becomes the entire setup).
- **Log is empty** → bundled hooks are skill-scoped in disguise → `install.sh` stays mandatory until Claude Code adds always-on plugin hook support.

The test hook will be removed in v0.3.3 (pass) or v0.4.0 (fail) once results are recorded.

## 0.3.1 — 2026-04-27

### Fixed

- **`install.sh` was writing broken hook entries.** The `# afk-skill <path>` identity tag was placed BEFORE the script path in the `command` field, making the entire line a shell comment that the shell silently no-opped. Hooks appeared installed but never fired. Fixed by moving the tag to a trailing comment: `bash "<path>" # afk-skill`. Idempotent install/remove logic unchanged (it matches on `# afk-skill` appearing anywhere in the command string). **Anyone who installed 0.3.0 should re-run `install.sh --remove` then `install.sh` to refresh broken entries.**

### Added

- **GitHub issue + PR templates** in `.github/`. Three issue forms (bug report, skill/feature request, contact-links config) and a PR template that nudges contributors toward focused PRs, CI awareness, and the version-uniformity gotcha. Updated for the post-consolidation single-skill reality.

## 0.3.0 — 2026-04-27

### Changed (BREAKING)

- **Consolidated three top-level skills (`afk`, `afk-off`, `afk-status`) into one `/afk` skill with verb subcommands.** New surface:
  - `/afk` → enable AFK mode (default verb `on`, matches prior bare `/afk` behavior)
  - `/afk "<task>"` → enable with focus context (matches prior `/afk "<task>"` behavior)
  - `/afk on [task]` → enable explicitly
  - `/afk off` → disable (replaces `/afk-off`)
  - `/afk status` → inspect (replaces `/afk-status`)

  **Why:** three top-level slash commands sharing one state file was poor CLI design. The mental model is "AFK is one feature with three actions," not "three independent things." Consolidation also resolves the à la carte install question — one skill = one plugin install, no per-skill plugin restructure needed.

  **Migration:** users of `/afk-off` switch to `/afk off`; users of `/afk-status` switch to `/afk status`. Bare `/afk` and `/afk "<task>"` continue to work unchanged. Underlying state file (`~/.claude/afk-stack/<session-id>.json`) and lifecycle hooks are unchanged.

### Added

- **`scripts/afk-dispatch.sh`** — verb dispatcher that parses `$ARGUMENTS`, routes to the appropriate worker script (`afk-enable.sh`, `afk-disable.sh`, `afk-status.sh`), defaults to `on` when no recognized verb is the first token. Worker scripts unchanged from 0.2.0 — just called through the dispatcher now.

### Removed

- `skills/afk-off/` directory (its functionality is now `/afk off`)
- `skills/afk-status/` directory (its functionality is now `/afk status`)

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
