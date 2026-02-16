# Hyprland Configuration

Linux-only desktop environment config for Hyprland (compositor), Hyprpaper (wallpapers), and Hyprlock (lock screen).

## Key Files

- `dot-config/hypr/hyprland.conf` - Main config, sources host-specific files
- `dot-config/hypr/hyprlock.conf` - Lock screen appearance
- `dot-config/hypr/hyprpaper.conf` - Wallpaper rotation (block syntax, IPC disabled)
- `dot-config/hypr/hosts/laptop/` and `hosts/desktop/` - Host-specific settings and keybinds
- `dot-config/hypr/update-host-config.sh` - Generates `host-settings.conf` and `host-keybinds.conf` at startup

## Host Configuration

Edit `hosts/laptop/` or `hosts/desktop/` source files, never the generated `host-*.conf` files. The startup script copies the correct host profile based on hostname (`zaxtec` = laptop, otherwise desktop).

## Window Rules

Hyprland uses `windowrule` (not the deprecated `windowrulev2`). Check the Hyprland wiki for current syntax when adding rules -- field names change across releases.

## Testing Changes

```bash
hyprctl reload        # Reload hyprland config live
hyprctl monitors -j   # Query monitor info (JSON)
```

## Hyprpaper

Hyprpaper uses block syntax for wallpaper configuration. IPC is disabled (`ipc = false`). Wallpapers are loaded from `~/Images/Wallpapers/` with automatic rotation. Do not attempt to interact with hyprpaper via `hyprctl hyprpaper` subcommands -- these are not supported in current versions; hyprpaper uses its own Unix socket.

## Colors

All colors in hyprlock and other Hypr configs should use the shared palette defined in the root `CLAUDE.md`. The accent color is Arch Blue (`#1793d1`), surfaces use `#333333`, and status colors (red, green, yellow) come from the Tailwind ANSI palette.
