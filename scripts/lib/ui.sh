# Shared UI helpers for setup.sh and update.sh.
# Source only; do not execute.

ui_count_ok=0
ui_count_skip=0
ui_count_warn=0
ui_count_fail=0
ui_count_info=0

ui_bold=
ui_dim=
ui_green=
ui_yellow=
ui_red=
ui_cyan=
ui_reset=
ui_tty=false
ui_spinner_pid=

ui_init() {
  if [[ -t 1 ]]; then
    ui_tty=true
  fi

  if [[ "$ui_tty" == true && -z "${NO_COLOR:-}" ]]; then
    ui_bold=$'\033[1m'
    ui_dim=$'\033[2m'
    ui_green=$'\033[32m'
    ui_yellow=$'\033[33m'
    ui_red=$'\033[31m'
    ui_cyan=$'\033[36m'
    ui_reset=$'\033[0m'
  fi
}

ui_cleanup() {
  ui_spin_stop
}

# Shorten $HOME paths to ~/... for display.
ui_path() {
  local path=$1

  if [[ "$path" == "$HOME" || "$path" == "$HOME"/* ]]; then
    printf '~/%s' "${path#"$HOME"/}"
  else
    printf '%s' "$path"
  fi
}

ui_header() {
  local title=$1
  local detail=${2:-}

  printf '\n'
  printf '  %s%s%s' "$ui_bold" "$title" "$ui_reset"
  if [[ -n "$detail" ]]; then
    printf '  %s%s%s' "$ui_dim" "$detail" "$ui_reset"
  fi
  if [[ "${dry_run:-false}" == true ]]; then
    printf '  %sdry-run%s' "$ui_yellow" "$ui_reset"
  fi
  printf '\n\n'
}

ui_section() {
  printf '  %s%s%s\n\n' "$ui_bold$ui_cyan" "$1" "$ui_reset"
}

ui_blank() {
  printf '\n'
}

ui_status() {
  local kind=$1
  local message=$2
  local color=
  local mark=

  case "$kind" in
    ok)
      color=$ui_green
      mark='✓'
      ui_count_ok=$((ui_count_ok + 1))
      ;;
    skip)
      color=$ui_dim
      mark='·'
      ui_count_skip=$((ui_count_skip + 1))
      ;;
    warn)
      color=$ui_yellow
      mark='!'
      ui_count_warn=$((ui_count_warn + 1))
      ;;
    fail)
      color=$ui_red
      mark='✗'
      ui_count_fail=$((ui_count_fail + 1))
      ;;
    info)
      color=$ui_dim
      mark='→'
      ui_count_info=$((ui_count_info + 1))
      ;;
  esac

  printf '    %s%s%s  %s\n' "$color" "$mark" "$ui_reset" "$message"
}

ui_ok() { ui_status ok "$1"; }
ui_skip() { ui_status skip "$1"; }
ui_warn() { ui_status warn "$1"; }
ui_fail() { ui_status fail "$1"; }
ui_info() { ui_status info "$1"; }

# Nested detail under the previous status line (e.g. dry-run commands).
ui_detail() {
  printf '       %s%s%s\n' "$ui_dim" "$1" "$ui_reset"
}

ui_spin_start() {
  local message=$1

  ui_spin_stop

  if [[ "$ui_tty" != true ]]; then
    return
  fi

  (
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while true; do
      printf '\r    %s%s%s  %s' "$ui_cyan" "${frames[i]}" "$ui_reset" "$message"
      i=$(((i + 1) % ${#frames[@]}))
      sleep 0.08
    done
  ) &
  ui_spinner_pid=$!
  disown "$ui_spinner_pid" 2>/dev/null || true
}

ui_spin_stop() {
  if [[ -z "${ui_spinner_pid:-}" ]]; then
    return
  fi

  kill "$ui_spinner_pid" 2>/dev/null || true
  wait "$ui_spinner_pid" 2>/dev/null || true
  ui_spinner_pid=

  if [[ "$ui_tty" == true ]]; then
    printf '\r\033[K'
  fi
}

# Replace an active spinner line with a final status.
ui_spin_ok() {
  ui_spin_stop
  ui_ok "$1"
}

ui_spin_fail() {
  ui_spin_stop
  ui_fail "$1"
}

ui_spin_skip() {
  ui_spin_stop
  ui_skip "$1"
}

ui_summary() {
  ui_spin_stop
  printf '\n'
  printf '  %sSummary%s\n' "$ui_bold" "$ui_reset"
  printf '    %s✓%s  %s\n' "$ui_green" "$ui_reset" "$ui_count_ok ok"
  printf '    %s·%s  %s\n' "$ui_dim" "$ui_reset" "$ui_count_skip skipped"
  printf '    %s!%s  %s\n' "$ui_yellow" "$ui_reset" "$ui_count_warn warned"
  printf '    %s✗%s  %s\n' "$ui_red" "$ui_reset" "$ui_count_fail failed"
  printf '\n'

  if ((ui_count_fail > 0)) || [[ "${had_error:-false}" == true ]]; then
    printf '  %sFinished with errors%s\n\n' "$ui_red$ui_bold" "$ui_reset"
    return 1
  fi

  if [[ "${dry_run:-false}" == true ]]; then
    printf '  %sDry run complete%s\n\n' "$ui_yellow$ui_bold" "$ui_reset"
  else
    printf '  %sAll done%s\n\n' "$ui_green$ui_bold" "$ui_reset"
  fi
  return 0
}
