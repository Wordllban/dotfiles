# Cursor extension helpers for setup.sh and update.sh.
# Source only; do not execute.

ext_list_path() {
  printf '%s\n' "$REPO_ROOT/home/.cursor/extensions.txt"
}

ext_install_from_list() {
  local list
  local extension
  local installed

  list=$(ext_list_path)

  if [[ ! -f "$list" ]]; then
    ui_warn "Skipping extensions: missing home/.cursor/extensions.txt"
    return
  fi

  if ! command -v cursor >/dev/null 2>&1; then
    ui_warn "Skipping extensions: cursor CLI not found"
    return
  fi

  ui_spin_start "Reading installed extensions…"
  installed=$(cursor --list-extensions 2>/dev/null || true)
  ui_spin_stop

  while IFS= read -r extension || [[ -n "$extension" ]]; do
    [[ -z "$extension" || "$extension" == \#* ]] && continue

    if printf '%s\n' "$installed" | grep -Fxq -- "$extension"; then
      ui_skip "$extension"
      continue
    fi

    if [[ "$dry_run" == true ]]; then
      ui_ok "Would install  $extension"
      continue
    fi

    ui_spin_start "Installing $extension…"
    if cursor --install-extension "$extension" >/dev/null 2>&1; then
      ui_spin_ok "Installed  $extension"
    else
      ui_spin_fail "Failed to install  $extension"
      common_mark_error
    fi
  done < "$list"
}

ext_refresh_list() {
  local destination
  local temporary_list

  destination=$(ext_list_path)

  if ! command -v cursor >/dev/null 2>&1; then
    ui_warn "Skipping extensions list: cursor CLI not found"
    return
  fi

  ui_spin_start "Reading installed extensions…"
  temporary_list=$(mktemp)
  {
    printf '%s\n' \
      '# Cursor extensions managed by scripts/setup.sh (one publisher.name per line).' \
      '# Refresh with: ./scripts/update.sh'
    cursor --list-extensions | LC_ALL=C sort -u
  } >"$temporary_list"
  ui_spin_stop

  if [[ -f "$destination" ]] && cmp -s "$temporary_list" "$destination"; then
    ui_skip "Unchanged  home/.cursor/extensions.txt"
    rm -f -- "$temporary_list"
    return
  fi

  if [[ "$dry_run" == true ]]; then
    ui_ok "Would update  home/.cursor/extensions.txt"
    rm -f -- "$temporary_list"
    return
  fi

  mkdir -p "$(dirname -- "$destination")"
  mv -- "$temporary_list" "$destination"
  ui_ok "Updated  home/.cursor/extensions.txt"
}
