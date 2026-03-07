#!/bin/bash
# Launcher for tap-indicator.py — called from hyprland.conf exec-once.
# Only starts if the opt-in flag file exists.

FLAG="$HOME/.config/hypr/tap-indicator-enabled"
SCRIPT="$HOME/.config/hypr/tap-indicator.py"
LOG="$XDG_RUNTIME_DIR/tap-indicator.log"

[[ -f "$FLAG" ]] || exit 0

exec python3 "$SCRIPT" >"$LOG" 2>&1
