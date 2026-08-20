#!/usr/bin/env bash
set -euo pipefail

# Truecolor (24-bit) projections of tufte-dracula.css's dark :root tokens, computed the
# same way mermaid-palette.json documents its own hex projections: oklch() through
# Oklab -> linear sRGB, gamut-clipped. Recompute with .github/palette-check.py's
# oklch_to_hex() if tufte-dracula.css's :root values move.
PURPLE='170;140;219'    # --purple  #aa8cdb
LINK='143;201;217'      # --link    #8fc9d9
LABEL='183;191;228'     # --label   #b7bfe4
MUTED='151;159;196'     # --muted   #979fc4
RULE='112;115;136'      # --rule-light #707388
GREEN='109;205;147'     # --green   #6dcd93
ORANGE='234;164;101'    # --orange  #eaa465
RED='255;122;123'       # --red     #ff7a7b
PINK='240;129;186'      # --pink    #f081ba
DATA1='150;190;240'     # --data-1  #96bef0

DATA=$(cat)

# Extract fields via single jq call
IFS=$'\t' read -r CLI_VERSION MODEL MODEL_ID DIR PCT DURATION_MS ADDED REMOVED < <(
    echo "$DATA" | jq -r '[
        (.version // ""),
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
[ -n "$VERSION" ] && CI_ICON="\033[38;2;${PINK}m🏷  $VERSION\033[0m"

# Build progress bar
FILLED=$((PCT * 10 / 100))
EMPTY=$((10 - FILLED))
BAR=""
for ((i=0; i<FILLED; i++)); do
  if [ $i -lt 3 ]; then BAR+="\033[38;2;${DATA1}m█"
  elif [ $i -lt 6 ]; then BAR+="\033[38;2;${LINK}m█"
  else BAR+="\033[38;2;${PURPLE}m█"
  fi
done
for ((i=0; i<EMPTY; i++)); do BAR+="\033[38;2;${RULE}m⣀"; done

# Format duration
TOTAL_SEC=$((DURATION_MS / 1000))
H=$((TOTAL_SEC / 3600))
M=$(((TOTAL_SEC % 3600) / 60))
S=$((TOTAL_SEC % 60))
if [ "$H" -gt 0 ]; then TIME="${H}h ${M}m"
elif [ "$M" -gt 0 ]; then TIME="${M}m ${S}s"
else TIME="${S}s"
fi

# Threshold colors (mirrors tufte-dracula.css's .verdict-pass/-partial/-failed hues)
if [ "$PCT" -gt 80 ]; then CTX_CLR="\033[38;2;${RED}m"
elif [ "$PCT" -gt 50 ]; then CTX_CLR="\033[38;2;${ORANGE}m"
else CTX_CLR="\033[38;2;${GREEN}m"
fi

# Split display name into model + version (e.g. "Opus 4.6" → "Opus" + "4.6")
MODEL_BASE="${MODEL%% *}"
MODEL_VER="${MODEL#* }"
[ "$MODEL_VER" = "$MODEL_BASE" ] && MODEL_VER=""

MODEL_STR="\033[1;38;2;${PURPLE}m$MODEL_BASE\033[0m"
[ -n "$MODEL_VER" ] && MODEL_STR="$MODEL_STR \033[38;2;${MUTED}m$MODEL_VER\033[0m"

CLI_VER_STR=""
[ -n "$CLI_VERSION" ] && CLI_VER_STR="\033[38;2;${MUTED}mv$CLI_VERSION\033[0m\033[2;38;2;${RULE}m ║ \033[0m"

echo -e "\033[38;2;${PURPLE}m🏴‍☠️\033[0m ${CLI_VER_STR}$MODEL_STR\033[2;38;2;${RULE}m ║ \033[0m\033[38;2;${LABEL}m📁 $DIR\033[0m\033[2;38;2;${RULE}m ║ \033[0m$([ -n "$BRANCH" ] && printf '%b' "\033[38;2;${GREEN}m🌿 $BRANCH\033[0m")\033[2;38;2;${RULE}m ║ \033[0m$CI_ICON\033[0m\033[2;38;2;${RULE}m ║ \033[0m$BAR\033[0m ${CTX_CLR}$PCT%\033[0m\033[2;38;2;${RULE}m ║ \033[0m\033[38;2;${LINK}m$TIME\033[0m\033[2;38;2;${RULE}m ║ \033[0m\033[38;2;${GREEN}m+$ADDED\033[0m \033[38;2;${RED}m-$REMOVED\033[0m\033[0m"
