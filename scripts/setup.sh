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
# shellcheck source=lib/skills.sh
source "$LIB_DIR/skills.sh"

mode=link
install_skills=false

usage() {
  cat <<'EOF'
Usage: scripts/setup.sh [--link|--copy] [--dry-run] [--skills]

Install the repository's portable configuration files and Cursor extensions.
Agent skills install only when --skills is passed.

  --link      Symlink files into the home directory (default).
  --copy      Copy files instead of creating symlinks.
  --dry-run   Print changes without writing anything.
  --skills    Install/update agent skills and apply Claude/Cursor modes
  -h, --help  Show this help.

Existing destinations are moved to a timestamped directory under
~/.dotfiles-backups before replacement.

Cursor extensions are installed from home/.cursor/extensions.txt when the
cursor CLI is available. With --skills, agent skills are updated and installed
via npx skills, Claude skillOverrides are written, and Cursor frontmatter is
re-applied.
EOF
}

parse_args() {
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
      --skills)
        install_skills=true
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
  local relative_source destination

  parse_args "$@"
  ui_init
  trap ui_cleanup EXIT
  files_init_backup_root

  ui_header "Setup" "$mode"
  ui_section "Config files"
  while IFS='|' read -r relative_source destination; do
    files_install "$relative_source" "$destination" "$mode"
  done < <(dotfiles_manifest)

  ui_blank
  ui_section "Cursor extensions"
  ext_install_from_list

  ui_blank
  ui_section "Agent skills"
  if [[ "$install_skills" == true ]]; then
    skills_install_from_list
  else
    ui_skip "Skipped (pass --skills to install)"
  fi

  ui_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
