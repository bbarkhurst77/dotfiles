#!/bin/bash
# Dotfiles installer for GitHub Codespaces
# Sets up Claude Code helper functions and custom status bar

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Remove any existing claude-dotfiles block, then add fresh
if grep -q ">>> claude-dotfiles >>>" "$HOME/.bashrc" 2>/dev/null; then
  # Create temp file without the claude-dotfiles block
  awk '/>>> claude-dotfiles >>>/{skip=1} /<<< claude-dotfiles <<</{skip=0; next} !skip' "$HOME/.bashrc" > "$HOME/.bashrc.tmp"
  mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
  echo "Removed old Claude Code functions"
fi

# Append fresh functions
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
  if command -v jq &> /dev/null; then
    jq -s '.[0] * .[1]' "$HOME/.claude/settings.json" "$SCRIPT_DIR/.claude/settings.json" > "$HOME/.claude/settings.tmp"
    mv "$HOME/.claude/settings.tmp" "$HOME/.claude/settings.json"
    echo "Merged status bar config into existing settings"
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
