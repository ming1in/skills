# Skills

Reusable skills live here. Each directory should contain a `SKILL.md` file with
clear trigger metadata and only the runtime resources needed by that skill.

## Included

| Skill | Purpose |
| --- | --- |
| [`afk`](afk/) | Enable autonomous AFK mode for the current session. |
| [`afk-off`](afk-off/) | Disable AFK mode for the current session. |
| [`afk-status`](afk-status/) | Inspect AFK state for this session and the rest of the stack. |

## Planned

- `people-search`
- `kg-merge-resolution`

## Authoring Notes

- Keep the skill folder itself lean: `SKILL.md` plus necessary `scripts/`,
  `references/`, or `assets/`.
- Prefer shared repo-level scripts when multiple related skills use the same
  state machine.
- Do not copy private `big-one` KG context into public skills; link back to the
  private project docs from `big-one` instead.
