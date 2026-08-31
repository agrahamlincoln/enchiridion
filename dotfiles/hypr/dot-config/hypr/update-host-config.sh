#!/bin/bash
# Apply DPI-based monitor scaling at startup.
#
# This script used to also generate host-settings.conf and host-keybinds.conf by
# concatenating the hosts/<profile>/ sources and patching them with sed. The Lua
# config reads ~/.config/hypr/host-type and ~/.config/hypr/kb-layout directly and
# require()s the matching module (see hostenv.lua), so that codegen step is gone
# and there is no generated file left to drift from its sources.
#
# To change profiles: echo "laptop" > ~/.config/hypr/host-type && hyprctl reload
#                     echo "dvorak" > ~/.config/hypr/kb-layout && hyprctl reload

HYPR_DIR="$HOME/.config/hypr"

# Report the active profiles so startup logs still show what was applied.
read_axis() {
    local file="$HYPR_DIR/$1" default="$2"
    if [[ -f "$file" ]]; then
        local value
        value="$(tr -d '[:space:]' < "$file")"
        [[ -n "$value" ]] && { echo "$value"; return; }
    fi
    echo "$default"
}

echo "Host type: $(read_axis host-type desktop) | Keyboard layout: $(read_axis kb-layout dvorak)"

# DPI-based monitor scaling — targets 140 effective DPI for consistent sizing.
# Uses hypr-scale.sh which computes valid scales mathematically (no probing).
SCALE_SCRIPT="$HYPR_DIR/hypr-scale.sh"
if [[ -x "$SCALE_SCRIPT" ]] && command -v hyprctl >/dev/null 2>&1; then
    "$SCALE_SCRIPT" auto 140
else
    echo "hypr-scale.sh or hyprctl not available, skipping DPI-based scaling"
fi
