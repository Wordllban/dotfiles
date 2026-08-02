#!/usr/bin/env bash
# Ask before destructive shell / gh / acli commands.
# Works for Claude Code PreToolUse and Cursor beforeShellExecution (stdin JSON).

set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // .command // empty')

if [[ -z "$command" ]]; then
  exit 0
fi

is_destructive() {
  local cmd=$1
  local pattern

  # Keep this list the single source of truth for hard ask guards.
  local patterns=(
    'rm[[:space:]]+(-[[:alnum:]]*r[[:alnum:]]*f|-[[:alnum:]]*f[[:alnum:]]*r)'
    'git[[:space:]]+push[[:space:]].*(--force-with-lease|--force|-f)([[:space:]]|$)'
    'git[[:space:]]+reset[[:space:]]+--hard'
    'git[[:space:]]+clean[[:space:]]+-[[:alnum:]]*f'
    'gh[[:space:]]+repo[[:space:]]+(delete|archive|rename)([[:space:]]|$)'
    'gh[[:space:]]+secret[[:space:]]+(set|delete)([[:space:]]|$)'
    'gh[[:space:]]+variable[[:space:]]+delete([[:space:]]|$)'
    'gh[[:space:]]+release[[:space:]]+delete([[:space:]]|$)'
    'gh[[:space:]]+gist[[:space:]]+delete([[:space:]]|$)'
    'gh[[:space:]]+issue[[:space:]]+delete([[:space:]]|$)'
    'gh[[:space:]]+cache[[:space:]]+delete([[:space:]]|$)'
    'gh[[:space:]]+run[[:space:]]+delete([[:space:]]|$)'
    'gh[[:space:]]+(ssh-key|gpg-key|deploy-key)[[:space:]]+delete([[:space:]]|$)'
    'gh[[:space:]]+auth[[:space:]]+logout([[:space:]]|$)'
    'gh[[:space:]]+(project|label)[[:space:]]+delete([[:space:]]|$)'
    'gh[[:space:]]+workflow[[:space:]]+disable([[:space:]]|$)'
    'acli[[:space:]].*\b(delete|deactivate|remove)\b'
  )

  for pattern in "${patterns[@]}"; do
    if printf '%s' "$cmd" | grep -Eiq -- "$pattern"; then
      return 0
    fi
  done
  return 1
}

if ! is_destructive "$command"; then
  exit 0
fi

reason='Destructive command requires approval'
is_claude=false
if printf '%s' "$input" | jq -e 'has("tool_input")' >/dev/null 2>&1; then
  is_claude=true
fi

if [[ "$is_claude" == true ]]; then
  jq -n \
    --arg reason "$reason" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: $reason
      }
    }'
else
  jq -n \
    --arg reason "$reason" \
    '{
      permission: "ask",
      user_message: $reason,
      agent_message: $reason
    }'
fi
