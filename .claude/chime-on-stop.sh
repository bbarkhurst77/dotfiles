#!/bin/bash
# Chime notification when Claude Code stops
# Triggered by Stop hook in settings.json
# Checks both global (~/.claude/) and project (.claude/) for flag files

# Read hook input from stdin
input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // empty')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
transcript_path="${transcript_path/#\~/$HOME}"
cwd=$(echo "$input" | jq -r '.cwd // empty')
cwd="${cwd/#\~/$HOME}"

# Determine project .claude/ directory (from cwd if available)
project_claude_dir=""
if [ -n "$cwd" ] && [ -d "$cwd/.claude" ]; then
    project_claude_dir="$cwd/.claude"
fi

# Check which chime modes are enabled for THIS session
# Check both global and project locations
chime_enabled=false
chime_pi_enabled=false

if [ -n "$session_id" ]; then
    # Check global flags
    [ -f "$HOME/.claude/.chime-enabled-$session_id" ] && chime_enabled=true
    [ -f "$HOME/.claude/.chime-pi-enabled-$session_id" ] && chime_pi_enabled=true

    # Check project flags (if project has .claude/)
    if [ -n "$project_claude_dir" ]; then
        [ -f "$project_claude_dir/.chime-enabled-$session_id" ] && chime_enabled=true
        [ -f "$project_claude_dir/.chime-pi-enabled-$session_id" ] && chime_pi_enabled=true
    fi
fi

# Exit if no chime flags are set
if [ "$chime_enabled" = false ] && [ "$chime_pi_enabled" = false ]; then
    exit 0
fi

# Gather context info for notification
device=$(hostname 2>/dev/null || echo "unknown")
branch="unknown"
repo="unknown"
if [ -n "$cwd" ]; then
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    repo=$(basename "$cwd" 2>/dev/null || echo "unknown")
fi
tmux_session=""
if [ -n "$TMUX" ]; then
    tmux_session=$(tmux display-message -p '#S' 2>/dev/null || echo "")
fi

# Extract last ~256 chars of Claude's output from transcript
msg="Done"
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Get last assistant message text from JSONL transcript
    last_text=$(tac "$transcript_path" | grep -m1 '"type":"assistant"' | jq -r '.message.content[-1].text // empty' 2>/dev/null | tr '\n' ' ')
    if [ -n "$last_text" ]; then
        msg=$(echo "$last_text" | tail -c 256 | sed 's/^[[:space:]]*//')
    fi
fi

# 1. Terminal bell (if standard chime enabled)
if [ "$chime_enabled" = true ]; then
    printf '\a'
fi

# 2. Pi speaker audio chime (if Pi chime enabled)
if [ "$chime_pi_enabled" = true ]; then
    # Play bell chime through Pi's HDMI audio (file is recorded quiet, boost 2x)
    if command -v ffplay &> /dev/null; then
        ffplay -nodisp -autoexit -loglevel quiet -af "volume=2.0" /usr/share/sounds/freedesktop/stereo/bell.oga 2>/dev/null &
    fi
fi

# 3. Push notification via ntfy.sh (if standard chime enabled)
if [ "$chime_enabled" = true ]; then
    NTFY_TOPIC="${CLAUDE_NTFY_TOPIC:-devpi16-claude}"

    # Build title with context: "Claude @ device"
    title="Claude @ ${device}"

    # Build context line: repo/branch (tmux-session)
    context_line="${repo}/${branch}"
    if [ -n "$tmux_session" ]; then
        context_line="${context_line} (${tmux_session})"
    fi

    # Full message body: context header + blank line + message
    body="${context_line}

${msg}"

    curl -s -o /dev/null \
      -H "Title: ${title}" \
      -H "Priority: default" \
      -H "Actions: view, Connect, ssh://PiUser@devpi16, clear=true" \
      -d "$body" \
      "https://ntfy.sh/${NTFY_TOPIC}" &
fi

exit 0
