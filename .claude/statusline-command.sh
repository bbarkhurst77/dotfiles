#!/bin/bash
input=$(cat)

# Colors
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
RESET='\033[0m'

# Environment detection and hostname coloring
HOSTNAME=$(hostname)
if [ "$CODESPACES" = "true" ]; then
    HOST="${BLUE}codespaces${RESET}"
elif [ "$HOSTNAME" = "devpi16" ]; then
    HOST="${GREEN}devpi16${RESET}"
else
    HOST="$HOSTNAME"
fi

# Model name (compact)
MODEL_FULL=$(echo "$input" | jq -r '.model.display_name // "?"')
case "$MODEL_FULL" in
    *"Opus"*"4.5"*|*"opus"*"4.5"*) MODEL="O4.5" ;;
    *"Opus"*|*"opus"*) MODEL="Opus" ;;
    *"Sonnet"*|*"sonnet"*) MODEL="Son" ;;
    *"Haiku"*|*"haiku"*) MODEL="Hai" ;;
    *) MODEL="$MODEL_FULL" ;;
esac

# Git branch
BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$BRANCH" ]; then
    BRANCH_INFO=" │ $BRANCH"
else
    BRANCH_INFO=""
fi

# Directory
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "?"')
DIR_NAME="${DIR##*/}"

# Context window info
INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

# Calculate usage percentage
TOTAL_TOKENS=$((INPUT_TOKENS + OUTPUT_TOKENS))
if [ "$CONTEXT_SIZE" -gt 0 ]; then
    PERCENT=$((TOTAL_TOKENS * 100 / CONTEXT_SIZE))
else
    PERCENT=0
fi

# Color based on percentage
if [ "$PERCENT" -lt 50 ]; then
    BAR_COLOR="$GREEN"
elif [ "$PERCENT" -lt 80 ]; then
    BAR_COLOR="$YELLOW"
else
    BAR_COLOR="$RED"
fi

# Build context bar (10 chars wide)
BAR_WIDTH=10
FILLED=$((PERCENT * BAR_WIDTH / 100))
[ "$FILLED" -gt "$BAR_WIDTH" ] && FILLED=$BAR_WIDTH
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="█"; done
for ((i=0; i<EMPTY; i++)); do BAR+="░"; done
[ -z "$BAR" ] && BAR="░░░░░░░░░░"

# Lines changed (from cost object)
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
if [ "$LINES_ADDED" -gt 0 ] || [ "$LINES_REMOVED" -gt 0 ]; then
    LINES_INFO=" │ ${GREEN}+${LINES_ADDED}${RESET} ${RED}-${LINES_REMOVED}${RESET}"
else
    LINES_INFO=""
fi

# Subagent info
SUBAGENTS=$(echo "$input" | jq -r '.subagents // [] | length')
if [ "$SUBAGENTS" -gt 0 ]; then
    SUBAGENT_INFO=" │ 🤖${SUBAGENTS}"
else
    SUBAGENT_INFO=""
fi

# Output
echo -e "${HOST} │ ${MODEL}${BRANCH_INFO} │ 📁 ${DIR_NAME} │ ${BAR_COLOR}${BAR}${RESET} ${PERCENT}%${LINES_INFO}${SUBAGENT_INFO}"
