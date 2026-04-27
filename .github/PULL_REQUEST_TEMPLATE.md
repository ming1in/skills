<!-- Thanks for contributing! Keep PRs focused — one skill change or one infra change per PR. -->

## What changed

<!-- One paragraph. What does this PR do? Reference any related issue (e.g., "Closes #12"). -->

## Why

<!-- What problem does this solve, or what use case does it enable? -->

## Skill(s) affected

- [ ] `afk` (any of the `on`/`off`/`status` subcommands or shared scripts)
- [ ] new skill: `<name>`
- [ ] repo infra only (CI, docs, install, manifests, plugin metadata)

## Testing

<!--
For skill changes: paste the commands you ran and what you observed.
For infra changes: note which CI jobs you expect to pass/fail.

For AFK changes specifically, run the local pipeline before pushing:
  SESSION_ID="local-test-$(uuidgen)"
  bash skills/afk/scripts/afk-enable.sh "$SESSION_ID" "test"
  echo "{\"session_id\":\"$SESSION_ID\"}" | bash skills/afk/scripts/afk-stop-hook.sh
  bash skills/afk/scripts/afk-disable.sh "$SESSION_ID"
-->

## Checklist

- [ ] CI passes locally where possible (`shellcheck` on changed `*.sh`, JSON parse on changed manifests)
- [ ] CHANGELOG updated under `## [Unreleased]` (or under a new release section if cutting a version)
- [ ] Plugin version bumped in **all three** manifests if this is a new release (`marketplace.json` + `.claude-plugin/plugin.json` + `.codex-plugin/plugin.json`) — CI's version-uniformity check will fail otherwise
- [ ] If adding a new skill: README "Included Skills" table updated, per-skill `README.md` and `SKILL.md` present
- [ ] If changing AFK lifecycle hooks: verified the `hooks` field in `.claude-plugin/plugin.json` declares all three (`Stop`, `SessionEnd`, `SessionStart`) using `${CLAUDE_PLUGIN_ROOT}` and that the AFK pipeline smoke test still passes
