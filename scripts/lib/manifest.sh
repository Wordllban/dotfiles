# Allowlist mapping repository files to home-directory destinations.
# Source only; do not execute.

case "$(uname -s)" in
  Darwin)
    DOTFILES_CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
    ;;
  Linux)
    DOTFILES_CURSOR_USER_DIR="${XDG_CONFIG_HOME:-"$HOME/.config"}/Cursor/User"
    ;;
  *)
    printf 'Unsupported operating system: %s\n' "$(uname -s)" >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

dotfiles_manifest() {
  printf '%s|%s\n' \
    'home/AGENTS.md' "$HOME/AGENTS.md" \
    'home/.config/wezterm/wezterm.lua' "$HOME/.wezterm.lua" \
    'home/.config/herdr/config.toml' "$HOME/.config/herdr/config.toml" \
    'home/.claude/CLAUDE.md' "$HOME/.claude/CLAUDE.md" \
    'home/.claude/settings.json' "$HOME/.claude/settings.json" \
    'home/.claude/statusline.sh' "$HOME/.claude/statusline.sh" \
    'home/.cursor/settings.json' "$DOTFILES_CURSOR_USER_DIR/settings.json" \
    'home/.cursor/keybindings.json' "$DOTFILES_CURSOR_USER_DIR/keybindings.json"
}
