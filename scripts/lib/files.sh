# Config file install/update helpers for setup.sh and update.sh.
# Source only; do not execute.

files_backup_root=
files_temporary=

files_cleanup() {
  if [[ -n "${files_temporary:-}" ]]; then
    rm -f -- "$files_temporary"
    files_temporary=
  fi
}

files_init_backup_root() {
  files_backup_root="$HOME/.dotfiles-backups/$(date '+%Y%m%d-%H%M%S')-$$"
}

files_backup_destination() {
  local destination=$1
  local relative backup

  relative=${destination#"$HOME"/}
  backup="$files_backup_root/$relative"

  ui_info "Backup $(ui_path "$destination")"
  ui_detail "→ $(ui_path "$backup")"
  common_run mkdir -p "$(dirname -- "$backup")"
  common_run mv -- "$destination" "$backup"
}

files_install() {
  local relative_source=$1
  local destination=$2
  local mode=$3
  local source="$REPO_ROOT/$relative_source"
  local current_target
  local display

  display=$(ui_path "$destination")

  if [[ ! -f "$source" ]]; then
    ui_fail "Missing repository file: $relative_source"
    common_mark_error
    return
  fi

  if [[ "$mode" == link && -L "$destination" ]]; then
    current_target=$(readlink "$destination")
    if [[ "$current_target" == "$source" ]]; then
      ui_skip "Already linked  $display"
      return
    fi
  elif [[ "$mode" == copy && -f "$destination" ]] && cmp -s "$source" "$destination"; then
    ui_skip "Already current  $display"
    return
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    files_backup_destination "$destination"
  fi

  if [[ "$mode" == link ]]; then
    ui_ok "Link  $display"
    common_run mkdir -p "$(dirname -- "$destination")"
    common_run ln -s -- "$source" "$destination"
  else
    ui_ok "Copy  $display"
    common_run mkdir -p "$(dirname -- "$destination")"
    common_run cp -p -- "$source" "$destination"
  fi
}

files_contains_sensitive() {
  local file=$1

  LC_ALL=C grep -Eiq \
    '(ctx7sk-|sk-[A-Za-z0-9_-]{16,}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|(api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret|password|authorization)[[:space:]]*[=:][[:space:]]*.{0,2}[A-Za-z0-9_./+-]{8,})' \
    "$file"
}

files_update() {
  local relative_destination=$1
  local source=$2
  local destination="$REPO_ROOT/$relative_destination"

  if [[ ! -f "$source" ]]; then
    ui_warn "Missing local file  $(ui_path "$source")"
    return
  fi

  if files_contains_sensitive "$source"; then
    ui_fail "Refusing secret-looking file  $(ui_path "$source")"
    common_mark_error
    return
  fi

  if [[ -f "$destination" ]] && cmp -s "$source" "$destination"; then
    ui_skip "Unchanged  $relative_destination"
    return
  fi

  if [[ "$dry_run" == true ]]; then
    ui_ok "Would update  $relative_destination"
    return
  fi

  mkdir -p "$(dirname -- "$destination")"
  files_temporary="$destination.tmp.$$"
  cp -p -- "$source" "$files_temporary"
  mv -- "$files_temporary" "$destination"
  files_temporary=
  ui_ok "Updated  $relative_destination"
}
