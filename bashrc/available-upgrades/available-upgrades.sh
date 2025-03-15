#!/bin/bash

UPDATES_FILE="/tmp/.package-available-upgrades"

# Setup UPDATES_FILE with correct permissions
if [[ ! -f "$UPDATES_FILE" ]]; then
  touch "$UPDATES_FILE"
  chmod 644 "$UPDATES_FILE"
fi

# Check if --count option is provided
if [[ "$1" == "--update" ]]; then
  # Default behavior: Check for updates and write to the file
  pacman -Qu > "$UPDATES_FILE" 2>/dev/null
  paru -Qu >> "$UPDATES_FILE" 2>/dev/null
else
  # Check if the updates file exists and is not empty
  if [[ -s "$UPDATES_FILE" ]]; then
    # Count the number of lines (updates)
    update_count=$(wc -l "$UPDATES_FILE" | awk '{print $1}')
    exit 0
  else
    # Return non-zero if the file does not exist
    exit -1
  fi
  exit 0
fi
