# Shared helpers for setup.sh and update.sh.
# Source only; do not execute.

dry_run=false
had_error=false

common_mark_error() {
  had_error=true
}

common_print_command() {
  local rendered=

  printf -v rendered '%q ' "$@"
  ui_detail "+ ${rendered% }"
}

common_run() {
  if [[ "$dry_run" == true ]]; then
    if [[ "${VERBOSE:-}" == 1 ]]; then
      common_print_command "$@"
    fi
  else
    "$@"
  fi
}
