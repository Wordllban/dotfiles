#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)

# shellcheck source=config-manifest.sh
source "$SCRIPT_DIR/config-manifest.sh"

dry_run=false
had_error=false
temporary_file=

usage() {
  cat <<'EOF'
Usage: scripts/update.sh [--dry-run]

Copy the current portable configuration files from the home directory back
into this repository. The explicit allowlist in config-manifest.sh prevents
logs, caches, histories, databases, sockets, generated state, and plugin data
from being collected. Also refreshes home/.cursor/extensions.txt from the
cursor CLI when available.

  --dry-run   Print changes without writing anything.
  -h, --help  Show this help.
EOF
}

cleanup() {
  if [[ -n "$temporary_file" ]]; then
    rm -f -- "$temporary_file"
  fi
}
trap cleanup EXIT

contains_sensitive_value() {
  local file=$1

  LC_ALL=C grep -Eiq \
    '(ctx7sk-|sk-[A-Za-z0-9_-]{16,}|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|(api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret|password|authorization)[[:space:]]*[=:][[:space:]]*.{0,2}[A-Za-z0-9_./+-]{8,})' \
    "$file"
}

update_file() {
  local relative_destination=$1
  local source=$2
  local destination="$REPO_ROOT/$relative_destination"

  if [[ ! -f "$source" ]]; then
    printf 'Skipping missing local file: %s\n' "$source" >&2
    return
  fi

  if contains_sensitive_value "$source"; then
    printf 'Refusing to copy a file that appears to contain a secret: %s\n' "$source" >&2
    had_error=true
    return
  fi

  if [[ -f "$destination" ]] && cmp -s "$source" "$destination"; then
    printf 'Unchanged: %s\n' "$relative_destination"
    return
  fi

  if "$dry_run"; then
    printf 'Would update: %s\n' "$relative_destination"
    return
  fi

  mkdir -p "$(dirname -- "$destination")"
  temporary_file="$destination.tmp.$$"
  cp -p -- "$source" "$temporary_file"
  mv -- "$temporary_file" "$destination"
  temporary_file=
  printf 'Updated: %s\n' "$relative_destination"
}

while (($#)); do
  case "$1" in
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

update_cursor_extensions() {
  local destination="$REPO_ROOT/home/.cursor/extensions.txt"
  local temporary_list

  if ! command -v cursor >/dev/null 2>&1; then
    printf 'Skipping Cursor extensions list: cursor CLI not found\n' >&2
    return
  fi

  temporary_list=$(mktemp)
  {
    printf '%s\n' \
      '# Cursor extensions managed by scripts/setup.sh (one publisher.name per line).' \
      '# Refresh with: ./scripts/update.sh'
    cursor --list-extensions | LC_ALL=C sort -u
  } >"$temporary_list"

  if [[ -f "$destination" ]] && cmp -s "$temporary_list" "$destination"; then
    printf 'Unchanged: home/.cursor/extensions.txt\n'
    rm -f -- "$temporary_list"
    return
  fi

  if "$dry_run"; then
    printf 'Would update: home/.cursor/extensions.txt\n'
    rm -f -- "$temporary_list"
    return
  fi

  mkdir -p "$(dirname -- "$destination")"
  mv -- "$temporary_list" "$destination"
  printf 'Updated: home/.cursor/extensions.txt\n'
}

while IFS='|' read -r relative_destination source; do
  update_file "$relative_destination" "$source"
done < <(dotfiles_manifest)

update_cursor_extensions

if "$had_error"; then
  exit 1
fi

if "$dry_run"; then
  printf 'Dry run complete; no files were changed.\n'
else
  printf 'Repository configuration update complete.\n'
fi
