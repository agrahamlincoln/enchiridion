#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Exit immediately if an unset variable is used.
set -u

WALLPAPER_DIR="$HOME/Images/Wallpapers/"

# Ensure the wallpaper directory exists
if [[ ! -d "$WALLPAPER_DIR" ]]; then
  echo "Error: Wallpaper directory not found at $WALLPAPER_DIR" >&2
  exit 1
fi

while true; do
  # Get the name of the focused monitor with hyprctl, handle potential errors.
  FOCUSED_MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' 2>/dev/null)

  if [[ -z "$FOCUSED_MONITOR" ]]; then
    echo "Warning: No focused monitor found or hyprctl failed. Retrying in 60 seconds." >&2
    sleep 60
    continue
  fi

  # Get the currently loaded wallpaper for the focused monitor, if any.
  # Use '|| true' to prevent 'set -e' from exiting if grep finds no match.
  CURRENT_WALL=$(hyprctl hyprpaper listloaded | grep "$FOCUSED_MONITOR" | awk '{print $2}' 2>/dev/null || true)

  # Find a random image file (jpg, jpeg, png, gif, bmp) that is not the current one.
  # Using -iregex for case-insensitive matching of extensions.
  # File paths are handled robustly, ensuring correct exclusion and random selection.
  # 'grep -v -F -i' is used for case-insensitive fixed string exclusion of the current wallpaper.
  if [[ -z "$CURRENT_WALL" ]]; then
    # No wallpaper loaded, pick any random one from the directory.
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f -iregex '.*\.\(jpg\|jpeg\|png\|gif\|bmp\)$' | shuf -n 1)
  else
    # A wallpaper is loaded, pick a random one that is not the current one.
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f -iregex '.*\.\(jpg\|jpeg\|png\|gif\|bmp\)$' | \
                grep -v -F -i "$CURRENT_WALL" | shuf -n 1)
  fi

  if [[ -z "$WALLPAPER" ]]; then
    echo "Warning: No suitable new wallpaper found (or only current wallpaper available). Retrying in 60 seconds." >&2
    sleep 60
    continue
  fi

  echo "Changing wallpaper on $FOCUSED_MONITOR to $WALLPAPER"
  if ! hyprctl hyprpaper reload "$FOCUSED_MONITOR","$WALLPAPER"; then
    echo "Error: Failed to set wallpaper for $FOCUSED_MONITOR to $WALLPAPER. Retrying in 60 seconds." >&2
  fi
  sleep 60
done
