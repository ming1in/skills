---
name: afk
description: Manage AFK mode — agent operates autonomously while you're away. Verbs is `on` (default) / `off` / `status`. Bare /afk = enable. /afk "task" = enable with task context. /afk on/off/status [task] for explicit verb. As of v0.3.0 this is one consolidated skill (was three).
allowed-tools: Bash
argument-hint: '[on|off|status] [task context]'
---

Dispatch the requested AFK action.

- `/afk` → enable AFK mode (default verb is `on`)
- `/afk "<task>"` → enable AFK mode with focus context (default verb is still `on`)
- `/afk on [task]` → enable explicitly
- `/afk off` → disable AFK mode for this session
- `/afk status` → show current state and other sessions in the AFK stack

!`bash "${CLAUDE_SKILL_DIR}/scripts/afk-dispatch.sh" "${CLAUDE_SESSION_ID}" $ARGUMENTS`

---

**If the action above ENABLED AFK mode** (verb `on` or default), the human is now away from their keyboard. Continue the current session's in-flight work — plus the registered task if one was supplied — autonomously per these principles:

1. **Never ask clarifying questions to the human.** Make the call yourself: enumerate options, state your reasoning, pick the best one, proceed.
2. **Don't pause for permission on reversible / low-stakes work** (file edits, builds, tests, KG maintenance, lint, docs). Just do it.
3. **Still pause for hard approval gates** — merging app code to main, sending external messages, money movement, destructive shared-state ops, security-sensitive changes (per `feedback_approval_gates`). If one of those is the only path forward, write `task_status: "blocked"` to your AFK state file with a one-line `block_reason`, then stop on the next turn.
4. **When the work is genuinely complete** (the session's in-flight work and any registered task), write `task_status: "done"` to your AFK state file (or run `/afk off`). The Stop hook will then release the session.
5. **Plan deliberately.** Break decisions into options, think through tradeoffs, recommend, execute. Repeat.
6. **For browser-use work, write before browsing again.** Persist current findings to `knowledge/` before each Stop event, then continue browsing or automation. Ephemeral browser state that never lands in the KG is wasted AFK iteration.

The Stop hook will keep blocking session exit until `task_status` is `done` / `blocked` or the iteration cap (50) is reached. Resume / continue working now.

**If the action above was `off` or `status`**, the principles above don't apply to this invocation — they're for AFK enable. Just acknowledge the action and return control to the user.
