#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Images/Wallpapers/"
# Get the name of the focused monitor with hyprctl
FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

while true; do
  CURRENT_WALL=$(hyprctl hyprpaper listloaded)
  # Get a random wallpaper that is not the current one
  WALLPAPER=$(find "$WALLPAPER_DIR" -type f ! -name "$(basename "$CURRENT_WALL")" | shuf -n 1)
  hyprctl hyprpaper reload "$FOCUSED_MONITOR","$WALLPAPER"
  sleep 60
done
