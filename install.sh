#!/bin/bash
# Dotfiles installer for GitHub Codespaces
# Appends Claude Code helper functions to .bashrc

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add claude functions to bashrc if not already present
if ! grep -q "clauded()" "$HOME/.bashrc" 2>/dev/null; then
  echo "" >> "$HOME/.bashrc"
  echo "# Claude Code helpers (from dotfiles)" >> "$HOME/.bashrc"
  cat "$SCRIPT_DIR/.claude_functions" >> "$HOME/.bashrc"
  echo "Added Claude Code functions to .bashrc"
else
  echo "Claude Code functions already in .bashrc"
fi

# Install Claude Code CLI if not present
if ! command -v claude &> /dev/null; then
  echo "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code
fi

echo "Dotfiles setup complete!"
