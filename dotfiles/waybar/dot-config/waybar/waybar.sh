#!/usr/bin/env sh

# Launcher script for Waybar with automatic config reloading.
# Selects config based on effective display width (resolution / scale):
#   < 2000px effective → compact (icon-only, values in tooltips)
#   >= 2000px effective → full (icons with text labels)
# Uses inotifywait + SIGUSR2 for live reload without restarting.

COMPACT_THRESHOLD=2000

# Terminate already running waybar instances
killall -q waybar

# Wait until processes have shut down
while pgrep -x waybar >/dev/null; do sleep 1; done

WAYBAR_DIR="$HOME/.config/waybar"

# Determine effective width of the smallest connected monitor.
# Falls back to the full config if hyprctl or jq are unavailable.
select_config() {
  if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "$WAYBAR_DIR/config.jsonc"
    return
  fi

  min_width=$(hyprctl monitors -j 2>/dev/null \
    | jq '[.[] | (.width / .scale)] | min | floor' 2>/dev/null)

  if [ -n "$min_width" ] && [ "$min_width" -lt "$COMPACT_THRESHOLD" ]; then
    echo "$WAYBAR_DIR/config-compact.jsonc"
  else
    echo "$WAYBAR_DIR/config.jsonc"
  fi
}

CONFIG=$(select_config)
STYLE="$WAYBAR_DIR/style.css"
WATCH_FILES="$CONFIG $STYLE"

# Clean up child processes on exit
cleanup() {
  kill 0 2>/dev/null
  exit 0
}
trap cleanup INT TERM

waybar -c "$CONFIG" -s "$STYLE" &
WAYBAR_PID=$!

if command -v inotifywait >/dev/null 2>&1; then
  while true; do
    # Block until a config file is modified
    inotifywait -qq -e create,modify $WATCH_FILES
    # Signal waybar to reload config in-place rather than restarting
    kill -SIGUSR2 "$WAYBAR_PID" 2>/dev/null || break
  done
else
  echo "Warning: inotify-tools not found. Automatic config reloading disabled." >&2
  echo "Install inotify-tools for this functionality." >&2
  # Without inotify, just wait for waybar to exit on its own
  wait "$WAYBAR_PID"
fi
