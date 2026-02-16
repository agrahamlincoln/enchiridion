#!/bin/bash

source "$HOME/.config/sketchybar/colors.lua" 2>/dev/null || {
  # Define colors directly if colors.lua doesn't work
  arch_blue=0xff1793d1
  arch_text=0xffffffff
  arch_alt_bg=0xff444444
  arch_urgent=0xfff43f5e
}

PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

brew_item=(
  icon=🍺
  label="?"
  padding_left=2
  padding_right=2
  icon.color=$arch_text
  icon.font.size=12
  icon.padding_left=8
  icon.padding_right=4
  label.color=$arch_text
  label.font="SF Mono:Bold:12"
  label.padding_left=4
  label.padding_right=8
  background.color=$arch_alt_bg
  background.corner_radius=10
  background.height=24
  background.drawing=on
  background.border_width=0
  script="$PLUGIN_DIR/brew.sh"
  update_freq=3600
)

sketchybar --add event brew_update \
           --add item brew right \
           --set brew "${brew_item[@]}" \
           --subscribe brew brew_update routine
