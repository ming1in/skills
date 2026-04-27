---
name: afk-off
description: Disable AFK mode for this session. Stop hook becomes a no-op for this session; other sessions in the AFK stack are unaffected.
allowed-tools: Bash
---

!`bash "${CLAUDE_SKILL_DIR}/../../scripts/afk-disable.sh" "${CLAUDE_SESSION_ID}"`

AFK mode is now off for this session. The Stop hook will no longer block this session's termination. Other sessions in the AFK stack (if any) are unaffected.
