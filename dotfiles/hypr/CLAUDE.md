# Hyprland Configuration

Linux-only desktop environment config for Hyprland (compositor) and Hyprlock (lock screen). Wallpapers are handled by wpaperd, which lives in its own dotfiles package (`dotfiles/wpaperd/`).

## Key Files

- `dot-config/hypr/hyprland.conf` - Main config, sources host-specific files
- `dot-config/hypr/hyprlock.conf` - Lock screen appearance
- `dot-config/hypr/hosts/desktop/` and `hosts/laptop/` - Host-type settings (gaps, touchpad, effects)
- `dot-config/hypr/hosts/dvorak/` and `hosts/qwerty/` - Keyboard-layout keybinds
- `dot-config/hypr/update-host-config.sh` - Generates `host-settings.conf` and `host-keybinds.conf` at startup

## Host Configuration

Configuration is split across two independent axes:
- **Host type** (`~/.config/hypr/host-type`): `desktop` or `laptop` — controls gaps, touchpad, visual effects
- **Keyboard layout** (`~/.config/hypr/kb-layout`): `dvorak` or `qwerty` — controls keybinds and `kb_variant`

Edit source files in `hosts/<type>/` and `hosts/<layout>/`, never the generated `host-*.conf` files. The startup script reads both config files and composes the result. Defaults to `desktop` and `dvorak` if files are absent.

## Window Rules

Hyprland uses `windowrule` (not the deprecated `windowrulev2`). Check the Hyprland wiki for current syntax when adding rules -- field names change across releases.

## Testing Changes

```bash
hyprctl reload        # Reload hyprland config live
hyprctl monitors -j   # Query monitor info (JSON)
```

## Wallpapers

Wallpapers are handled by **wpaperd** (`exec-once = wpaperd` in `hyprland.conf`), configured in `dotfiles/wpaperd/dot-config/wpaperd/config.toml`. wpaperd natively cycles through a directory (`~/Images/Wallpapers`) on a timer. hyprpaper was used previously but has **no rotation feature** — it only assigns one static image per monitor — so directory cycling never worked with it. Do not reintroduce hyprpaper for rotation.

## Colors

All colors in hyprlock and other Hypr configs should use the shared palette defined in the root `CLAUDE.md`. The accent color is Arch Blue (`#1793d1`), surfaces use `#333333`, and status colors (red, green, yellow) come from the Tailwind ANSI palette.
