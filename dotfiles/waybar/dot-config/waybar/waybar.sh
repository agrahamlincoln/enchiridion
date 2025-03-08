#!/usr/bin/env sh

# Terminate already running waybar instances
killall -q waybar

# Wait until processes have shut down
while pgrep -x waybar >/dev/null; do sleep 1; done

CONFIG_FILES="$HOME/.config/waybar/config.jsonc $HOME/.config/waybar/style.css"

# Check if inotifywait is available
if command -v inotifywait >/dev/null 2>&1; then
  USE_INOTIFY=true
else
  USE_INOTIFY=false
  echo "Warning: inotify-tools not found. Automatic config reloading disabled. Install inotify-tools for this functionality." >&2
fi

# Launch Waybar based on inotify availability
if [ "$USE_INOTIFY" = true ]; then
    while true; do
        waybar &
        inotifywait -e create,modify $CONFIG_FILES
        killall waybar
    done
else
    waybar
fi
