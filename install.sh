#!/bin/bash
# Dotfiles installer for GitHub Codespaces
# Sets up Claude Code helper functions and custom status bar

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install tmux and jq if not present
if ! command -v tmux &> /dev/null || ! command -v jq &> /dev/null; then
  echo "Installing tmux and jq..."
  sudo apt-get update && sudo apt-get install -y tmux jq
fi

# Remove any existing claude-dotfiles block, then add fresh
if grep -q ">>> claude-dotfiles >>>" "$HOME/.bashrc" 2>/dev/null; then
  # Create temp file without the claude-dotfiles block
  awk '/>>> claude-dotfiles >>>/{skip=1} /<<< claude-dotfiles <<</{skip=0; next} !skip' "$HOME/.bashrc" > "$HOME/.bashrc.tmp"
  mv "$HOME/.bashrc.tmp" "$HOME/.bashrc"
  echo "Removed old Claude Code functions"
fi

# Remove any stray clauded/resumed aliases (from old configs)
sed -i '/^alias clauded=/d' "$HOME/.bashrc"
sed -i '/^alias resumed=/d' "$HOME/.bashrc"

# Append fresh functions (ensure newline before appending)
echo "" >> "$HOME/.bashrc"
cat "$SCRIPT_DIR/.claude_functions" >> "$HOME/.bashrc"
echo "Installed Claude Code functions"

# Set up Claude Code config directory
mkdir -p "$HOME/.claude"

# Copy scripts
for script in statusline-command.sh chime-on-stop.sh get-session-id.sh; do
  if [ -f "$SCRIPT_DIR/.claude/$script" ]; then
    cp "$SCRIPT_DIR/.claude/$script" "$HOME/.claude/"
    chmod +x "$HOME/.claude/$script"
  fi
done
echo "Installed Claude scripts"

# Copy slash commands
if [ -d "$SCRIPT_DIR/.claude/commands" ]; then
  mkdir -p "$HOME/.claude/commands"
  cp -r "$SCRIPT_DIR/.claude/commands/"* "$HOME/.claude/commands/"
  echo "Installed slash commands (chimeon, chimeoff)"
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

# Install tmux config
if [ -f "$SCRIPT_DIR/.tmux.conf" ]; then
  cp "$SCRIPT_DIR/.tmux.conf" "$HOME/.tmux.conf"
  echo "Installed tmux config"
fi

# Install Claude Code CLI if not present
if ! command -v claude &> /dev/null; then
  echo "Installing Claude Code CLI..."
  npm install -g @anthropic-ai/claude-code
fi

# VS Code settings (terminal on right, no bottom panel)
if [ -f "$SCRIPT_DIR/.vscode/settings.json" ]; then
  mkdir -p "$HOME/.vscode-remote/data/Machine"
  cp "$SCRIPT_DIR/.vscode/settings.json" "$HOME/.vscode-remote/data/Machine/settings.json"
  echo "Installed VS Code settings"
fi

echo "Dotfiles setup complete!"
