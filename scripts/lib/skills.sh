# Agent skills helpers for setup.sh (skills.sh / npx skills).
# Aligns Claude Code skillOverrides with Cursor SKILL.md frontmatter.
# Source only; do not execute.

skills_list_path() {
  printf '%s\n' "$REPO_ROOT/home/.agents/skills.txt"
}

skills_settings_path() {
  printf '%s\n' "$REPO_ROOT/home/.claude/settings.json"
}

skills_inventory_json() {
  npx --yes skills list -g --json 2>/dev/null || true
}

skills_installed_names() {
  local json=$1

  printf '%s' "$json" | jq -r '.[].name // empty' 2>/dev/null || true
}

skills_skill_path() {
  local json=$1
  local skill=$2

  printf '%s' "$json" | jq -r --arg skill "$skill" '
    .[] | select(.name == $skill) | .path // empty
  ' 2>/dev/null | head -n 1
}

# Normalize aliases to Claude skillOverrides values.
skills_normalize_mode() {
  case "$1" in
    auto|on) printf 'on\n' ;;
    manual|user-invocable-only) printf 'user-invocable-only\n' ;;
    name-only) printf 'name-only\n' ;;
    off) printf 'off\n' ;;
    *) return 1 ;;
  esac
}

# Cursor has no skillOverrides; map Claude modes onto frontmatter.
# See https://cursor.com/docs/skills — disable-model-invocation only.
skills_cursor_disable_model_invocation() {
  case "$1" in
    user-invocable-only|off) printf 'true\n' ;;
    on|name-only) printf 'false\n' ;;
    *) return 1 ;;
  esac
}

skills_apply_cursor_frontmatter() {
  local skill_dir=$1
  local mode=$2
  local skill_file="$skill_dir/SKILL.md"
  local disable

  if [[ ! -f "$skill_file" ]]; then
    ui_warn "Missing SKILL.md in $skill_dir"
    return 1
  fi

  disable=$(skills_cursor_disable_model_invocation "$mode") || return 1

  if [[ "$dry_run" == true ]]; then
    ui_detail "Cursor: disable-model-invocation: $disable"
    return 0
  fi

  python3 - "$skill_file" "$disable" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
disable = sys.argv[2]
text = path.read_text()

if text.startswith("---"):
    end = text.find("\n---", 3)
    if end == -1:
        sys.exit("invalid frontmatter")
    fm = text[3:end]
    body = text[end + 4 :]
    if body.startswith("\n"):
        body = body[1:]
else:
    fm = ""
    body = text

lines = [ln for ln in fm.splitlines() if not ln.startswith("disable-model-invocation:")]
lines.append(f"disable-model-invocation: {disable}")
path.write_text(f"---\n" + "\n".join(lines).strip("\n") + f"\n---\n{body}")
PY
}

# Merge skillOverrides into home/.claude/settings.json (Claude Code standard).
skills_write_claude_overrides() {
  local settings
  local overrides_json=$1

  settings=$(skills_settings_path)

  if [[ ! -f "$settings" ]]; then
    ui_warn "Missing $settings"
    return 1
  fi

  if [[ "$dry_run" == true ]]; then
    ui_detail "Claude: would write skillOverrides"
    printf '%s\n' "$overrides_json" | jq -r 'to_entries[] | "       \(.key): \(.value)"' 2>/dev/null || true
    return 0
  fi

  python3 - "$settings" "$overrides_json" <<'PY'
import json
import pathlib
import sys

settings_path = pathlib.Path(sys.argv[1])
overrides = json.loads(sys.argv[2])
data = json.loads(settings_path.read_text())
existing = data.get("skillOverrides") or {}
if not isinstance(existing, dict):
    existing = {}
existing.update(overrides)
data["skillOverrides"] = existing
settings_path.write_text(json.dumps(data, indent=2) + "\n")
PY
}

skills_install_from_list() {
  local list
  local package
  local skill
  local mode_raw
  local mode
  local inventory
  local installed
  local skill_dir
  local agents
  local overrides_json='{}'

  list=$(skills_list_path)

  if [[ ! -f "$list" ]]; then
    ui_warn "Skipping skills: missing home/.agents/skills.txt"
    return
  fi

  if ! command -v npx >/dev/null 2>&1; then
    ui_warn "Skipping skills: npx not found (need Node.js)"
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    ui_warn "Skipping skills: jq not found"
    return
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    ui_warn "Skipping skills: python3 not found"
    return
  fi

  ui_spin_start "Updating installed skills…"
  if [[ "$dry_run" == true ]]; then
    ui_spin_stop
    ui_detail "Would run: npx skills update -g -y"
  else
    npx --yes skills update -g -y >/dev/null 2>&1 || true
    ui_spin_stop
    ui_ok "Ran skills update"
  fi

  ui_spin_start "Reading installed skills…"
  inventory=$(skills_inventory_json)
  installed=$(skills_installed_names "$inventory")
  ui_spin_stop

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* ]] && continue

    # shellcheck disable=SC2086
    set -- $line
    package=${1:-}
    skill=${2:-}
    mode_raw=${3:-user-invocable-only}

    if [[ -z "$package" || -z "$skill" ]]; then
      ui_warn "Invalid skills.txt line: $line"
      continue
    fi

    if ! mode=$(skills_normalize_mode "$mode_raw"); then
      ui_warn "Invalid mode for $skill: $mode_raw"
      continue
    fi

    overrides_json=$(printf '%s' "$overrides_json" | jq -c --arg k "$skill" --arg v "$mode" '. + {($k): $v}')

    if [[ "$mode" == off ]]; then
      agents=(--agent claude-code)
    else
      agents=(--agent claude-code --agent cursor)
    fi

    if printf '%s\n' "$installed" | grep -Fxq -- "$skill"; then
      ui_skip "Already installed  $skill"
    elif [[ "$dry_run" == true ]]; then
      ui_ok "Would install  $skill  ($package)"
    else
      ui_spin_start "Installing $skill…"
      if npx --yes skills add "$package" --skill "$skill" -g -y "${agents[@]}" >/dev/null 2>&1; then
        ui_spin_ok "Installed  $skill"
        inventory=$(skills_inventory_json)
        installed=$(skills_installed_names "$inventory")
      else
        ui_spin_fail "Failed to install  $skill"
        common_mark_error
        continue
      fi
    fi

    skill_dir=$(skills_skill_path "$inventory" "$skill")
    if [[ -z "$skill_dir" && "$dry_run" == true ]]; then
      ui_detail "Claude: $mode | Cursor: mapped after install"
      continue
    fi

    if [[ -z "$skill_dir" ]]; then
      ui_warn "Could not resolve path for $skill"
      common_mark_error
      continue
    fi

    # Cursor: frontmatter only (no skillOverrides). Re-applied after update.
    if [[ "$mode" != off ]]; then
      if skills_apply_cursor_frontmatter "$skill_dir" "$mode"; then
        ui_detail "Cursor frontmatter ok ($mode)"
      else
        common_mark_error
      fi
    else
      ui_detail "Cursor: not targeted (mode off)"
    fi

    ui_ok "Claude mode  $skill → $mode"
  done < "$list"

  if skills_write_claude_overrides "$overrides_json"; then
    if [[ "$dry_run" == true ]]; then
      ui_ok "Claude skillOverrides planned"
    else
      ui_ok "Wrote Claude skillOverrides"
    fi
  else
    common_mark_error
  fi
}
