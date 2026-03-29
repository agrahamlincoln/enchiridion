#!/bin/bash

UPDATES_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/available-upgrades"
UPDATES_FILE="$UPDATES_DIR/packages"

if [[ "$1" == "--update" ]]; then
  mkdir -p "$UPDATES_DIR"
  # Write to temp file and atomically swap to avoid readers seeing partial data
  TMPFILE="$UPDATES_DIR/.packages.tmp"
  # checkupdates syncs to a temp database so counts reflect actually available
  # upgrades without creating a partial-upgrade state
  checkupdates > "$TMPFILE" 2>/dev/null
  # AUR-only flag avoids double-counting repo packages already in checkupdates
  paru -Qua >> "$TMPFILE" 2>/dev/null
  mv -f "$TMPFILE" "$UPDATES_FILE"
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
