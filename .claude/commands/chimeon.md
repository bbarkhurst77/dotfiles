---
description: Enable chime notifications for this session
allowed-tools: Bash
---

Enable chime notifications for the current session. Run this command:

```bash
SESSION_ID=$(~/.claude/get-session-id.sh) && touch ~/.claude/.chime-enabled-$SESSION_ID && echo "Chime enabled for session $SESSION_ID"
```
