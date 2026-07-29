#!/usr/bin/env bash

input=$(cat)

# --- Fields from Claude Code ---
model_full=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
# Strip "Claude " prefix → "Opus 4.6" instead of "Claude Opus 4.6"
model="${model_full#Claude }"

used_pct=$(echo "$input"       | jq -r '.context_window.used_percentage      // 0')
remaining_pct=$(echo "$input"  | jq -r '.context_window.remaining_percentage  // 100')
window_size=$(echo "$input"    | jq -r '.context_window.context_window_size   // 200000')
total_input=$(echo "$input"    | jq -r '.context_window.total_input_tokens    // 0')
total_output=$(echo "$input"   | jq -r '.context_window.total_output_tokens   // 0')
total_cost=$(echo "$input"     | jq -r '.cost.total_cost_usd                  // 0')

# --- Git info ---
cwd=$(pwd)
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
git_hash=$(git -C "$cwd" --no-optional-locks log -1 --format="%h" 2>/dev/null)
git_msg=$(git -C "$cwd" --no-optional-locks log -1 --format="%s" 2>/dev/null)
git_dirty=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
dir=$(basename "$cwd")

# --- Context bar (32 blocks wide) ---
filled=$(awk "BEGIN {printf \"%d\", int($used_pct / 100 * 32 + 0.5)}")
[ "$filled" -gt 32 ] && filled=32
empty=$((32 - filled))

# Build bar with awk to avoid macOS seq 1 0 issue
bar=$(awk -v f="$filled" -v e="$empty" 'BEGIN {
  s=""
  for (i=0; i<f; i++) s=s"█"
  for (i=0; i<e; i++) s=s"░"
  printf "%s", s
}')

# --- Free tokens: context_window_size * remaining_percentage / 100 ---
free_tokens=$(awk "BEGIN { printf \"%d\", int($window_size * ($remaining_pct / 100) + 0.5) }")
free_k=$(awk      "BEGIN { printf \"%dk\", int($window_size * ($remaining_pct / 100) / 1000 + 0.5) }")

# --- Color-code free tokens: green >100k, yellow 40k-100k, red <=40k ---
if [ "$free_tokens" -gt 100000 ]; then
  FREE_COLOR="\033[1;32m"   # Green
elif [ "$free_tokens" -gt 40000 ]; then
  FREE_COLOR="\033[1;33m"   # Yellow
else
  FREE_COLOR="\033[0;31m"   # Red
fi

# --- Session duration (keyed by project dir) ---
dir_hash=$(echo "$cwd" | md5 2>/dev/null | cut -c1-8 || echo "$cwd" | cksum | cut -d' ' -f1)
session_file="/tmp/claude_session_${dir_hash}"
if [ ! -f "$session_file" ]; then
  date +%s > "$session_file"
fi
start_time=$(cat "$session_file")
now=$(date +%s)
elapsed=$((now - start_time))
hours=$((elapsed / 3600))
mins=$(((elapsed % 3600) / 60))
time_seg="${hours}h${mins}m"

# --- Cost (actual from Claude Code, not estimated) ---
spend=$(awk "BEGIN {printf \"%.4f\", $total_cost}")

# --- Colors ---
PURPLE="\033[1;35m"        # [Model]
GREEN="\033[1;32m"         # project name
GRAY="\033[38;5;245m"      # : separator
DARK_BLUE="\033[38;5;27m"  # branch name
YELLOW="\033[1;33m"        # [hash], free tokens
INDIGO="\033[38;5;99m"     # context bar blocks
RED="\033[0;31m"            # dirty *
WHITE="\033[0;37m"          # commit message, %, time, money
RESET="\033[0m"

# --- Line 1: [Model] project:branch * ---
dirty_part=""
[ -n "$git_dirty" ] && dirty_part=" *"
printf "${PURPLE}[%s]${RESET} ${GREEN}%s${RESET}${GRAY}:${RESET}${DARK_BLUE}%s${RESET}${RED}%s${RESET}\n" \
  "$model" "$dir" "${branch:-main}" "$dirty_part"

# --- Line 2: [hash] commit message ---
if [ -n "$git_hash" ]; then
  msg_short="${git_msg:0:52}"
  printf "${YELLOW}[%s]${RESET} ${WHITE}%s${RESET}\n" "$git_hash" "$msg_short"
fi

# --- Line 3: [bar] X% | Yk free | time | $spend ---
printf "[${INDIGO}%s${RESET}] ${WHITE}%s%%${RESET} | ${FREE_COLOR}%s free${RESET} | ${WHITE}%s${RESET} | ${GREEN}\$%s${RESET}" \
  "$bar" "$used_pct" "$free_k" "$time_seg" "$spend"
