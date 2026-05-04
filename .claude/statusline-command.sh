#!/usr/bin/env bash
# Claude Code status line script

# ANSI color codes
RESET="\033[0m"
PURPLE="\033[35m"
BLUE="\033[34m"
YELLOW="\033[33m"
GREEN="\033[32m"
RED="\033[31m"

SEP=" \033[37m❯\033[0m "
BRANCH_ICON=$(printf '\xef\x84\xa6')

input=$(cat)

# --- Current model (purple, brain emoji prefix) ---
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty' 2>/dev/null)

# --- Current working directory (blue) ---
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd="$PWD"
short_cwd="${cwd/#$HOME/~}"

# --- Git branch (yellow, branch icon separator, no brackets) ---
branch=""
if [ -f "$cwd/.git/HEAD" ]; then
  head_content=$(< "$cwd/.git/HEAD")
  if [[ "$head_content" == ref:* ]]; then
    branch="${head_content#ref: refs/heads/}"
  else
    branch="${head_content:0:7}"
  fi
fi

# --- Usage from rate limits ---
session_raw=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
week_raw=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' 2>/dev/null)

color_pct() {
  local pct="$1"
  local rounded
  rounded=$(printf '%.0f' "$pct" 2>/dev/null || echo "0")
  if [ "$rounded" -le 50 ]; then
    printf '%s' "${GREEN}${rounded}%${RESET}"
  elif [ "$rounded" -le 75 ]; then
    printf '%s' "${YELLOW}${rounded}%${RESET}"
  else
    printf '%s' "${RED}${rounded}%${RESET}"
  fi
}

usage_str=""
if [ -n "$session_raw" ] && [ "$session_raw" != "null" ]; then
  session_pct=$(printf '%.0f' "$session_raw" 2>/dev/null || echo "0")
  usage_str="Session: $(color_pct "$session_pct")"
fi

if [ -n "$week_raw" ] && [ "$week_raw" != "null" ]; then
  week_pct=$(printf '%.0f' "$week_raw" 2>/dev/null || echo "0")
  if [ -n "$usage_str" ]; then
    usage_str="${usage_str}, Week: $(color_pct "$week_pct")"
  else
    usage_str="Week: $(color_pct "$week_pct")"
  fi
fi

# --- Context window progress bar ---
ctx_raw=$(printf '%s' "$input" | jq -r '
  if .context_window.used_percentage != null then .context_window.used_percentage
  elif (.context_window.tokens_used != null and .context_window.tokens_limit != null and .context_window.tokens_limit > 0) then
    (.context_window.tokens_used / .context_window.tokens_limit * 100)
  else empty end' 2>/dev/null)

CTX_ICON=$(printf '\xf3\xb0\x88\x99')

make_bar() {
  local pct="$1"
  local filled=$(( pct * 20 / 100 ))
  local empty=$(( 20 - filled ))
  local bar="" i
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty; i++)); do bar="${bar}░"; done
  printf '%s' "$bar"
}

ctx_pct=$(printf '%.0f' "${ctx_raw:-0}" 2>/dev/null || echo "0")
ctx_bar=$(make_bar "$ctx_pct")
if [ "$ctx_pct" -le 50 ]; then
  ctx_color="$GREEN"
elif [ "$ctx_pct" -le 75 ]; then
  ctx_color="$YELLOW"
else
  ctx_color="$RED"
fi
ctx_line="${ctx_color}${CTX_ICON} ${ctx_bar} ${ctx_pct}%${RESET}"

# --- Assemble ---
output=""

# Model: purple with brain emoji
if [ -n "$model" ]; then
  output="${PURPLE}🧠 ${model}${RESET}${SEP}"
fi

# Directory: blue
output="${output}${BLUE}${short_cwd}${RESET}"

# Branch: yellow git branch icon + branch name
if [ -n "$branch" ]; then
  output="${output} ${YELLOW}${BRANCH_ICON} ${branch}${RESET}"
fi

# Assemble second line with context bar and usage
second_line="$ctx_line"
if [ -n "$usage_str" ]; then
  second_line="${second_line}${SEP}${usage_str}"
fi

printf '%b\n%b' "$output" "$second_line"
