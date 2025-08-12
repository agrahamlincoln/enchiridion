#!/bin/bash
# Script to update host-specific Hyprland configuration
# Detects laptop vs desktop and applies appropriate settings and keybinds

HYPR_DIR="$HOME/.config/hypr"
HOSTNAME=$(cat /etc/hostname 2>/dev/null || hostname)

# Determine host type
if [[ "$HOSTNAME" == "zaxtec" ]]; then
    HOST_TYPE="laptop"
    LAYOUT="QWERTY"
else
    HOST_TYPE="desktop"
    LAYOUT="Dvorak"
fi

echo "Detected hostname: $HOSTNAME"
echo "Host type: $HOST_TYPE"
echo "Keyboard layout: $LAYOUT"

# Generate host-specific settings config
echo "# This file is auto-generated based on hostname - DO NOT EDIT MANUALLY" > "$HYPR_DIR/host-settings.conf"
echo "# Generated for hostname: $HOSTNAME" >> "$HYPR_DIR/host-settings.conf"
echo "# Host type: $HOST_TYPE" >> "$HYPR_DIR/host-settings.conf"
echo "# Layout: $LAYOUT" >> "$HYPR_DIR/host-settings.conf"
echo "" >> "$HYPR_DIR/host-settings.conf"
cat "$HYPR_DIR/hosts/$HOST_TYPE/settings.conf" >> "$HYPR_DIR/host-settings.conf"

echo "Generated host-settings.conf for $HOST_TYPE"

# Generate host-specific keybindings config  
echo "# This file is auto-generated based on hostname - DO NOT EDIT MANUALLY" > "$HYPR_DIR/host-keybinds.conf"
echo "# Generated for hostname: $HOSTNAME" >> "$HYPR_DIR/host-keybinds.conf"
echo "# Host type: $HOST_TYPE" >> "$HYPR_DIR/host-keybinds.conf"
echo "# Layout: $LAYOUT" >> "$HYPR_DIR/host-keybinds.conf"
echo "" >> "$HYPR_DIR/host-keybinds.conf"
cat "$HYPR_DIR/hosts/$HOST_TYPE/keybinds.conf" >> "$HYPR_DIR/host-keybinds.conf"

echo "Generated host-keybinds.conf for $HOST_TYPE"

echo "Host configuration updated successfully!"
echo "Reload Hyprland config to apply changes: hyprctl reload"