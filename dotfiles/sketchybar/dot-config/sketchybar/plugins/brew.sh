#!/bin/bash

source "$HOME/.config/sketchybar/colors.lua" 2>/dev/null || {
  # Define colors directly if colors.lua doesn't work
  arch_blue=0xff1793d1
  arch_text=0xffffffff
  yellow=0xffffd141
  orange=0xffffb900
  arch_urgent=0xffff6b6b
  green=0xff8ce00a
}

COUNT=$(brew outdated 2>/dev/null | wc -l | tr -d ' ')

COLOR=$arch_text

case "$COUNT" in
  [3-5][0-9]) COLOR=$arch_urgent
  ;;
  [1-2][0-9]) COLOR=$orange
  ;;
  [1-9]) COLOR=$yellow
  ;;
  0) COLOR=$green
     COUNT=✓
  ;;
esac

sketchybar --set $NAME label="$COUNT" icon.color=$COLOR label.color=$COLOR
