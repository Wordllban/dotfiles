#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
LIB_DIR="$SCRIPT_DIR/lib"

# shellcheck source=lib/common.sh
source "$LIB_DIR/common.sh"
# shellcheck source=lib/ui.sh
source "$LIB_DIR/ui.sh"
# shellcheck source=lib/manifest.sh
source "$LIB_DIR/manifest.sh"
# shellcheck source=lib/files.sh
source "$LIB_DIR/files.sh"
# shellcheck source=lib/extensions.sh
source "$LIB_DIR/extensions.sh"

usage() {
  cat <<'EOF'
Usage: scripts/update.sh [--dry-run]

Copy the current portable configuration files from the home directory back
into this repository. The allowlist in scripts/lib/manifest.sh prevents logs,
caches, histories, databases, sockets, generated state, and plugin data from
being collected. Also refreshes home/.cursor/extensions.txt from the cursor
CLI when available.

  --dry-run   Print changes without writing anything.
  -h, --help  Show this help.
EOF
}

parse_args() {
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
}

main() {
  local relative_destination source

  parse_args "$@"
  ui_init
  trap 'files_cleanup; ui_cleanup' EXIT

  ui_header "Update"
  ui_section "Config files"
  while IFS='|' read -r relative_destination source; do
    files_update "$relative_destination" "$source"
  done < <(dotfiles_manifest)

  ui_blank
  ui_section "Cursor extensions"
  ext_refresh_list

  ui_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
