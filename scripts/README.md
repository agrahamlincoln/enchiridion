# Some Scripts

This directory has some scripts

### i3-setdisplays

Provides a set of profiles to configure displays. Each profile has a name, DPI setting, and a screen layouts

A screen layout is a simple xrandr command that configures which displays are used, and the resolution and orientation of other displays. These scripts can be built by hand, can also be easily configured via arandr. These layouts can be found in screenlayouts/.

### polybar-lauch

This script can be used to launch polybar. The script will terminate an existing polybar instance if found, and will start polybar with 3 bars.

internal-display: a bar for the laptop display
vertical-display: a bar for a display oriented vertically (may work on horizontal too)
asus-display: a bar for the primary connected desktop

Configuration for each of these bars can be found within the polybar config

