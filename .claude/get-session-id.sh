#!/bin/bash
# Get the current Claude Code session ID by finding the most recently modified transcript
# Usage: source this or call it to get SESSION_ID

# Find most recently modified .jsonl transcript file
latest=$(find ~/.claude/projects -name "*.jsonl" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)

if [ -n "$latest" ]; then
    # Extract session ID from filename (UUID before .jsonl)
    basename "$latest" .jsonl
else
    echo ""
fi
