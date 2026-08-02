#!/usr/bin/env bash

input=$(cat)

model_full=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
model="${model_full#Claude }"

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
worktree=$(echo "$input" | jq -r '.workspace.git_worktree // .worktree.name // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
rate_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
branch=$(echo "$input" | jq -r '.worktree.branch // empty')
[ -z "$branch" ] && branch=$(git --no-optional-locks branch --show-current 2>/dev/null)

dirty=""
if [ -n "$(git --no-optional-locks status --porcelain 2>/dev/null)" ]; then
  dirty="*"
fi

PURPLE='\033[1;35m'
PURPLE_SOFT='\033[38;5;141m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[38;5;27m'
RESET='\033[0m'

# Context square: purple ≤90k, green ≤130k, yellow <70%, red ≥70%
ctx_square=""
if [ -n "$used_pct" ]; then
  used_tokens=$(awk -v p="$used_pct" -v w="$window_size" 'BEGIN { printf "%d", p * w / 100 }')
  if [ "$used_tokens" -le 90000 ]; then
    color="$PURPLE"
  elif [ "$used_tokens" -le 130000 ]; then
    color="$GREEN"
  elif awk -v p="$used_pct" 'BEGIN { exit !(p < 70) }'; then
    color="$YELLOW"
  else
    color="$RED"
  fi
  ctx_square=$(printf " | ${color}■${RESET} %.0f%%" "$used_pct")
fi

# Line 1: model (effort) | ■ | 5h N%
printf "%b%s%b" "$PURPLE" "$model" "$RESET"
[ -n "$effort" ] && printf "%b (%s)%b" "$PURPLE_SOFT" "$effort" "$RESET"
printf "%b" "$ctx_square"
if [ -n "$rate_5h" ]; then
  printf " | 5h %.0f%%" "$rate_5h"
fi
printf "\n"

# Line 2: branch* | worktree
if [ -n "$branch" ] || [ -n "$worktree" ]; then
  if [ -n "$branch" ]; then
    printf "%b%s%b" "$BLUE" "$branch" "$RESET"
    [ -n "$dirty" ] && printf "%b*%b" "$RED" "$RESET"
    [ -n "$worktree" ] && printf " | %s" "$worktree"
  else
    printf "%s" "$worktree"
  fi
  printf "\n"
fi
