#!/usr/bin/env sh

# Terminate already running waybar instances
killall -q waybar

# Wait until processes have shut down
while pgrep -x waybar >/dev/null; do sleep 1; done

#Launch main
waybar

