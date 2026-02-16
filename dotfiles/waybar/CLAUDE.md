# Waybar Configuration

Linux-only status bar for Hyprland.

## Key Files

- `dot-config/waybar/config.jsonc` - Full config (icons + text labels, for large displays)
- `dot-config/waybar/config-compact.jsonc` - Compact config (icons only, values in tooltips)
- `dot-config/waybar/style.css` - Shared stylesheet for both configs
- `dot-config/waybar/waybar.sh` - Launcher script with automatic config selection and live reload

## Display-Adaptive Config Selection

`waybar.sh` selects the config based on the smallest connected monitor's effective width (`resolution / scale`):
- **< 2000px effective** -> `config-compact.jsonc` (icon-only, values in tooltips)
- **>= 2000px effective** -> `config.jsonc` (full layout with text)

The threshold is defined as `COMPACT_THRESHOLD=2000` in `waybar.sh`. This replaces hostname-based selection and works automatically across different machines and monitor configurations.

## Live Reload

The launcher uses `inotifywait` to watch config and style files. When modified, it sends `SIGUSR2` to waybar for in-place config reload without restart. Requires `inotify-tools`.

## Styling

- CSS uses `@define-color` variables based on the shared palette (see root `CLAUDE.md`)
- Right-side modules are grouped into rounded "pill" clusters
- Workspaces are styled as individual pills on the left
- Requires `ttf-firacode-nerd` and `ttf-font-awesome` fonts

## Adding Modules

When adding modules, add them to **both** `config.jsonc` and `config-compact.jsonc`. The compact version should use icon-only format with details in `tooltip-format`.

## Validation

- JSONC: strip comments and parse as JSON to verify syntax
- CSS: check for balanced braces after edits
