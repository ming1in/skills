---
name: afk
description: Enable AFK mode — agent operates autonomously while you're away. Bare /afk continues current session work; optional task arg adds focus context.
allowed-tools: Bash
argument-hint: '[optional task context]'
---

Enable AFK (away-from-keyboard) mode for this session. The argument is optional — bare `/afk` means "continue current session work autonomously." A task argument is added focus, not a replacement for the session's in-flight work.

Optional task context: $ARGUMENTS

!`bash "${CLAUDE_SKILL_DIR}/scripts/afk-enable.sh" "${CLAUDE_SESSION_ID}" "$ARGUMENTS"`

You are now in **AFK mode**. The human is away from their keyboard. Continue the current session's in-flight work — plus the registered task if one was supplied — autonomously per these principles:

1. **Never ask clarifying questions to the human.** Make the call yourself: enumerate options, state your reasoning, pick the best one, proceed.
2. **Don't pause for permission on reversible / low-stakes work** (file edits, builds, tests, KG maintenance, lint, docs). Just do it.
3. **Still pause for hard approval gates** — merging app code to main, sending external messages, money movement, destructive shared-state ops, security-sensitive changes (per `feedback_approval_gates`). If one of those is the only path forward, write `task_status: "blocked"` to your AFK state file with a one-line `block_reason`, then stop on the next turn.
4. **When the work is genuinely complete** (the session's in-flight work and any registered task), write `task_status: "done"` to your AFK state file (or run `/afk-off`). The Stop hook will then release the session.
5. **Plan deliberately.** Break decisions into options, think through tradeoffs, recommend, execute. Repeat.
6. **For browser-use work, write before browsing again.** Persist current findings to `knowledge/` before each Stop event, then continue browsing or automation. Ephemeral browser state that never lands in the KG is wasted AFK iteration.

The Stop hook will keep blocking session exit until `task_status` is `done` / `blocked` or the iteration cap (50) is reached. Resume / continue working now.
