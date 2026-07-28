# Wayle Configuration

Linux-only desktop shell replacing both Waybar (statusbar) and mako (notification daemon).

## Host-Type Config Generation

`config.base.toml` is the source of truth (stowed as a symlink); `config.toml` is generated at launch by `wayle.sh` and is neither stowed nor committed.

`wayle.sh` reads `~/.config/hypr/host-type` (same file as Hyprland) and generates `config.toml` from `config.base.toml` with host-specific overrides:

| Setting | Laptop (base) | Desktop override |
|---|---|---|
| `bar.scale` | `0.8` | `1.0` |
| Battery module | enabled | removed |
| Backlight module | enabled | removed |

The base config represents laptop defaults. Desktop overrides are applied via `sed` in `wayle.sh`. Edit `config.base.toml` for shared changes, edit the sed commands in `wayle.sh` to change what differs per host type.

**Important:** `config.toml` is regenerated on every launch. Never edit it directly — changes will be lost.

## Icons

Wayle uses GTK symbolic SVG icons, not Nerd Font glyphs. Icons are installed to `~/.local/share/wayle/icons/` on first launch via `wayle icons setup` (bundled icons from package) and `wayle icons install` (CDN icons from lucide, tabler, simple-icons).

The package (`wayle-agrahamlincoln`) installs bundled icons to `/usr/share/wayle/icons/`, which the runtime discovers automatically.

## Color Thresholds

Modules with numeric metrics support dynamic color thresholds via `[[modules.<name>.thresholds]]` TOML arrays. Each entry has `above` and/or `below` conditions with color overrides. Follow the attention hierarchy: normal states invisible, amber (`#d97706`) for warning, red (`#f43f5e`) for critical.

## Logging

All output is routed to the systemd journal:

```bash
journalctl -t wayle -f
```

## Validation

- TOML: `wayle config get bar.scale` (parses the config and reports errors)
- Icons: `wayle icons list` to verify installed icons
