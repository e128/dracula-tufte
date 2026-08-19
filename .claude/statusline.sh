#!/usr/bin/env bash
set -euo pipefail

DATA=$(cat)

# Extract fields via single jq call
IFS=$'\t' read -r MODEL MODEL_ID DIR PCT DURATION_MS ADDED REMOVED < <(
    echo "$DATA" | jq -r '[
        (.model.display_name // "Claude"),
        (try (.model.id // "unknown") catch "unknown"),
        (.cwd // "~" | split("/") | last),
        (try (
    if (.context_window.remaining_percentage // null) != null then
      100 - (.context_window.remaining_percentage | floor)
    elif (.context_window.context_window_size // 0) > 0 then
      (((.context_window.current_usage.input_tokens // 0) +
        (.context_window.current_usage.cache_creation_input_tokens // 0) +
        (.context_window.current_usage.cache_read_input_tokens // 0)) * 100 /
       .context_window.context_window_size) | floor
    else 0 end
  ) catch 0),
        (.cost.total_duration_ms // 0),
        (.cost.total_lines_added // 0),
        (.cost.total_lines_removed // 0)
    ] | @tsv'
)

# Git info
BRANCH=$(git -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null || echo "")

# Latest released version (local tag, whatever repo cwd is in)
VERSION=$(git -c core.useBuiltinFSMonitor=false describe --tags --abbrev=0 2>/dev/null || echo "")
CI_ICON=""
[ -n "$VERSION" ] && CI_ICON="\033[38;5;212m🏷  $VERSION\033[0m"

# Build progress bar
FILLED=$((PCT * 10 / 100))
EMPTY=$((10 - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do
  if [ $i -lt 3 ]; then BAR+="\033[38;5;51m█"
  elif [ $i -lt 6 ]; then BAR+="\033[38;5;33m█"
  else BAR+="\033[38;5;57m█"
  fi
done
for ((i=0; i<EMPTY; i++)); do BAR+="\033[38;5;242m⣀"; done

# Format duration
TOTAL_SEC=$((DURATION_MS / 1000))
H=$((TOTAL_SEC / 3600))
M=$(((TOTAL_SEC % 3600) / 60))
S=$((TOTAL_SEC % 60))
if [ "$H" -gt 0 ]; then TIME="${H}h ${M}m"
elif [ "$M" -gt 0 ]; then TIME="${M}m ${S}s"
else TIME="${S}s"
fi

# Threshold colors
if [ "$PCT" -gt 80 ]; then CTX_CLR="\033[38;5;203m"
elif [ "$PCT" -gt 50 ]; then CTX_CLR="\033[38;5;228m"
else CTX_CLR="\033[38;5;84m"
fi

# Split display name into model + version (e.g. "Opus 4.6" → "Opus" + "4.6")
MODEL_BASE="${MODEL%% *}"
MODEL_VER="${MODEL#* }"
[ "$MODEL_VER" = "$MODEL_BASE" ] && MODEL_VER=""

MODEL_STR="\033[38;5;99;1m$MODEL_BASE\033[0m"
[ -n "$MODEL_VER" ] && MODEL_STR="$MODEL_STR \033[38;5;245m$MODEL_VER\033[0m"

echo -e "\033[38;5;99m🏴‍☠️\033[0m $MODEL_STR\033[2m\033[38;5;242m ║ \033[0m\033[38;5;222m📁 $DIR\033[0m\033[2m\033[38;5;242m ║ \033[0m$([ -n "$BRANCH" ] && printf '%b' "\033[38;5;84m🌿 $BRANCH\033[0m")\033[2m\033[38;5;242m ║ \033[0m$CI_ICON\033[0m\033[2m\033[38;5;242m ║ \033[0m$BAR\033[0m ${CTX_CLR}$PCT%\033[0m\033[2m\033[38;5;242m ║ \033[0m\033[38;5;216m$TIME\033[0m\033[2m\033[38;5;242m ║ \033[0m\033[38;5;84m+$ADDED\033[0m \033[38;5;203m-$REMOVED\033[0m\033[0m"
