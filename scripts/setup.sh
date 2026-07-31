#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)

# shellcheck source=config-manifest.sh
source "$SCRIPT_DIR/config-manifest.sh"

mode=link
dry_run=false
backup_root="$HOME/.dotfiles-backups/$(date '+%Y%m%d-%H%M%S')-$$"
had_error=false

usage() {
  cat <<'EOF'
Usage: scripts/setup.sh [--link|--copy] [--dry-run]

Install the repository's portable configuration files and Cursor extensions.

  --link      Symlink files into the home directory (default).
  --copy      Copy files instead of creating symlinks.
  --dry-run   Print changes without writing anything.
  -h, --help  Show this help.

Existing destinations are moved to a timestamped directory under
~/.dotfiles-backups before replacement.

Cursor extensions are installed from home/.cursor/extensions.txt when the
cursor CLI is available.
EOF
}

print_command() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
}

run() {
  if "$dry_run"; then
    print_command "$@"
  else
    "$@"
  fi
}

backup_destination() {
  local destination=$1
  local relative backup

  relative=${destination#"$HOME"/}
  backup="$backup_root/$relative"

  printf 'Backing up %s -> %s\n' "$destination" "$backup"
  run mkdir -p "$(dirname -- "$backup")"
  run mv -- "$destination" "$backup"
}

install_file() {
  local relative_source=$1
  local destination=$2
  local source="$REPO_ROOT/$relative_source"
  local current_target

  if [[ ! -f "$source" ]]; then
    printf 'Missing repository file: %s\n' "$source" >&2
    had_error=true
    return
  fi

  if [[ "$mode" == link && -L "$destination" ]]; then
    current_target=$(readlink "$destination")
    if [[ "$current_target" == "$source" ]]; then
      printf 'Already linked: %s\n' "$destination"
      return
    fi
  elif [[ "$mode" == copy && -f "$destination" ]] && cmp -s "$source" "$destination"; then
    printf 'Already current: %s\n' "$destination"
    return
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    backup_destination "$destination"
  fi

  run mkdir -p "$(dirname -- "$destination")"
  if [[ "$mode" == link ]]; then
    printf 'Linking %s -> %s\n' "$destination" "$source"
    run ln -s -- "$source" "$destination"
  else
    printf 'Copying %s -> %s\n' "$source" "$destination"
    run cp -p -- "$source" "$destination"
  fi
}

while (($#)); do
  case "$1" in
    --link)
      mode=link
      ;;
    --copy)
      mode=copy
      ;;
    --dry-run)
      dry_run=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

install_cursor_extensions() {
  local list="$REPO_ROOT/home/.cursor/extensions.txt"
  local extension
  local installed

  if [[ ! -f "$list" ]]; then
    printf 'Skipping Cursor extensions: missing %s\n' "$list" >&2
    return
  fi

  if ! command -v cursor >/dev/null 2>&1; then
    printf 'Skipping Cursor extensions: cursor CLI not found\n' >&2
    return
  fi

  installed=$(cursor --list-extensions 2>/dev/null || true)

  while IFS= read -r extension || [[ -n "$extension" ]]; do
    [[ -z "$extension" || "$extension" == \#* ]] && continue

    if printf '%s\n' "$installed" | grep -Fxq -- "$extension"; then
      printf 'Cursor extension already installed: %s\n' "$extension"
      continue
    fi

    if "$dry_run"; then
      print_command cursor --install-extension "$extension"
    else
      printf 'Installing Cursor extension: %s\n' "$extension"
      if ! cursor --install-extension "$extension"; then
        printf 'Failed to install Cursor extension: %s\n' "$extension" >&2
        had_error=true
      fi
    fi
  done < "$list"
}

while IFS='|' read -r relative_source destination; do
  install_file "$relative_source" "$destination"
done < <(dotfiles_manifest)

install_cursor_extensions

if "$had_error"; then
  exit 1
fi

if "$dry_run"; then
  printf 'Dry run complete; no files were changed.\n'
else
  printf 'Configuration setup complete.\n'
fi
