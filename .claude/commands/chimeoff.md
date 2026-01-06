---
description: Disable chime notifications for this session
allowed-tools: Bash
---

Disable chime notifications for the current session. Run this command:

```bash
SESSION_ID=$(~/.claude/get-session-id.sh) && rm -f ~/.claude/.chime-enabled-$SESSION_ID && echo "Chime disabled for session $SESSION_ID"
```
