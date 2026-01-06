#!/bin/bash
# Dotfiles installer for GitHub Codespaces
# Sets up Claude Code helper functions and custom status bar

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Remove old claude functions block if present, then add fresh ones
if grep -q ">>> claude-dotfiles >>>" "$HOME/.bashrc" 2>/dev/null; then
  sed -i '/>>> claude-dotfiles >>>/,/<<< claude-dotfiles <<</d' "$HOME/.bashrc"
  echo "Removed old Claude Code functions"
elif grep -q "clauded()" "$HOME/.bashrc" 2>/dev/null; then
  # Legacy: remove old-style functions without markers
  sed -i '/# Claude Code helpers/,/^# <<< claude-dotfiles <<</d' "$HOME/.bashrc" 2>/dev/null
  # Also try removing just the function definitions
  sed -i '/^clauded()/,/^}/d' "$HOME/.bashrc" 2>/dev/null
  sed -i '/^resumed()/,/^}/d' "$HOME/.bashrc" 2>/dev/null
  sed -i '/^resumedf()/,/^}/d' "$HOME/.bashrc" 2>/dev/null
  echo "Removed legacy Claude Code functions"
fi
echo "" >> "$HOME/.bashrc"
cat "$SCRIPT_DIR/.claude_functions" >> "$HOME/.bashrc"
echo "Installed Claude Code functions"

# Set up Claude Code config directory
mkdir -p "$HOME/.claude"

# Copy statusline script
if [ -f "$SCRIPT_DIR/.claude/statusline-command.sh" ]; then
  cp "$SCRIPT_DIR/.claude/statusline-command.sh" "$HOME/.claude/"
  chmod +x "$HOME/.claude/statusline-command.sh"
  echo "Installed custom status bar"
fi

# Merge or create settings.json
if [ -f "$HOME/.claude/settings.json" ]; then
  # Merge statusLine into existing settings using jq
  if command -v jq &> /dev/null; then
    DOTFILE_SETTINGS="$SCRIPT_DIR/.claude/settings.json"
    TMP_SETTINGS=$(mktemp)
    jq -s '.[0] * .[1]' "$HOME/.claude/settings.json" "$DOTFILE_SETTINGS" > "$TMP_SETTINGS"
    mv "$TMP_SETTINGS" "$HOME/.claude/settings.json"
    echo "Merged status bar config into existing settings"
  else
    echo "Warning: jq not installed, skipping settings merge"
  fi
else
  cp "$SCRIPT_DIR/.claude/settings.json" "$HOME/.claude/"
  echo "Installed Claude Code settings"
fi

# Install Claude Code CLI if not present
if ! command -v claude &> /dev/null; then
  echo "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code
fi

echo "Dotfiles setup complete!"
