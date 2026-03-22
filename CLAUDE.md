# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Enchiridion is a personal dotfiles repository for managing system configurations across multiple machines (laptops and desktops). It uses `stow` for symlink management and a single `setup.sh` script for automation.

## Common Commands

```bash
# Full environment setup (installs packages, dotfiles, and configures bash)
./setup.sh

# Manually stow a single dotfiles package
cd dotfiles && stow -t ~ --dotfiles --ignore='CLAUDE\.md' --ignore='README\.md' -S <app>
```

## Key Conventions

### Stow

Files in `dotfiles/<app>/dot-config/<app>/` become `~/.config/<app>/` when stowed. The `--dotfiles` flag converts `dot-` prefixes to `.` prefixes. `CLAUDE.md` and `README.md` are excluded from stowing.

**Stow creates symlinks, not copies.** Editing a source file in this repo directly modifies the live config — no re-stow needed. Only re-stow when:
- A new file is added to or removed from a package (symlinks need to be created/deleted)
- The directory structure of a package changes

**Never** re-stow just because you edited an existing file's contents. The symlink already points to it.

### Adding a New Dotfiles Package

1. Create `dotfiles/<app>/dot-config/<app>/` with the config files
2. Add the system package to the appropriate file in `packages/` (one package per line, `#` comments)
3. Add `<app>` to the OS dotfiles list in `setup.sh`
4. Stow it: `cd dotfiles && stow -t ~ --dotfiles --ignore='CLAUDE\.md' --ignore='README\.md' -S <app>`

### Host-Specific Configuration (Linux / Hyprland)

Two independent config axes, combined at startup by `update-host-config.sh`:
- **Host type** (`~/.config/hypr/host-type`): `desktop` or `laptop` — gaps, touchpad, visual effects
- **Keyboard layout** (`~/.config/hypr/kb-layout`): `dvorak` or `qwerty` — keybinds and `kb_variant`

Edit the source files in `hosts/<type>/` and `hosts/<layout>/`, not the generated `host-settings.conf`/`host-keybinds.conf`.

### Display-Adaptive Configuration

Configs adapt to screen size rather than hostname. The pattern is to query effective display width (`resolution / scale`) and select a profile:
- **Compact** (< 2000px effective) — icon-only with tooltips
- **Full** (>= 2000px effective) — icons with text labels

Tool-specific details live in subdirectory `CLAUDE.md` files (e.g., `dotfiles/hypr/CLAUDE.md`, `dotfiles/waybar/CLAUDE.md`).

## UX Cohesion

Every change to the Enchiridion is a change to a complete desktop environment. A single config edit can break visual or behavioral consistency across the system.

### Cross-Cutting Change Checklist

Most changes touch multiple files. Before considering a change complete, check each affected layer:

| Change type | Files to check |
|---|---|
| **Color or font** | kitty.conf, waybar style.css, wofi style.css + scale-menu.css, wlogout style.css, hyprlock.conf, mako config, GTK settings.ini, bash-prompt.sh |
| **Border-radius or spacing** | waybar style.css, wofi style.css, wlogout style.css, hyprlock.conf, mako config, hyprland hosts/desktop + hosts/laptop settings |
| **Wlogout invocation** | hyprland.conf (keybind + XF86PowerOff), waybar config.jsonc, waybar config-compact.jsonc |
| **Suspend/hibernate** | hypridle.conf, wlogout layout, setup.sh (swap/hibernate section), logind drop-in, `~/.config/hypr/use-hibernate` flag |
| **Screenshot workflow** | hyprland.conf keybinds (3 binds: Print, Super+Print, Super+Shift+Print) |
| **New dotfiles package** | See "Adding a New Dotfiles Package" above |
| **System config change** | `setup.sh` (for new installs), use drop-in files under `/etc/systemd/*.conf.d/` rather than editing main configs |

### Color Palette

All configs share a unified color palette derived from Tailwind CSS colors. The canonical source is `kitty.conf`.

| Role     | Normal  | Bright  |
|----------|---------|---------|
| Black    | #292524 | #525252 |
| Red      | #f43f5e | #fb7185 |
| Green    | #22c55e | #4ade80 |
| Yellow   | #fcd34d | #fde68a |
| Blue     | #3b82f6 | #60a5fa |
| Magenta  | #e879f9 | #f0abfc |
| Cyan     | #06b6d4 | #22d3ee |
| White    | #d4d4d8 | #e7e5e4 |

Additional shared values:
- **Background**: `#0a0a0a`
- **Foreground**: `#d6d3d1`
- **Accent (Arch Blue)**: `#1793d1`
- **Amber (Warning)**: `#d97706`
- **Surface**: `#333333`
- **Alt Surface**: `#444444`

When adding or modifying colors in any config, use values from this palette. Do not introduce one-off hex values. Arch Blue is the **only** interactive accent color.

#### Semantic Color Roles

| Color | Role |
|---|---|
| Arch Blue `#1793d1` | Active/selected states, interactive borders, focus rings |
| Red `#f43f5e` | Errors, critical alerts, muted/disconnected |
| Green `#22c55e` | Transient success confirmations (auth passed, connected). Never for "normal/good" steady states — normal should be invisible (default text color) |
| Amber `#d97706` | Warnings in persistent UI (battery mid, high resource use). Lower luminance than yellow to avoid outshining red alerts |
| Yellow `#fcd34d` | High-visibility lock indicators (caps lock, num lock on lock screen) |
| Surface `#333333` | Container backgrounds, inactive borders, default notification borders |
| Alt Surface `#444444` | Hover states, secondary surfaces |

#### Attention Hierarchy Principles

Color usage follows perceptual science — saturated color on dark backgrounds triggers involuntary pre-attentive orienting (pop-out effect). Use this sparingly:

- **Normal/good states should be invisible.** Don't color the battery green when it's fine. Use the default text color. Color only appears when attention is needed.
- **Warning (amber) must not outshine critical (red).** Yellow #fcd34d has 3x the perceived luminance of red #f43f5e (Helmholtz-Kohlrausch effect). Use the lower-luminance amber #d97706 for warnings so red remains the most urgent signal.
- **Notification borders reflect urgency.** Low → #525252 (invisible), Normal → #525252 (quiet), Critical → #f43f5e (demands attention). Don't use the accent color for routine notifications.

### Visual Design Tokens

These values are used consistently across all UI components. Do not deviate without updating all components listed in the cross-cutting checklist.

| Token | Value |
|---|---|
| Border radius (standard) | `10px` |
| Border radius (tight) | `6px` |
| Border width | `2px` |
| Transition duration | `0.3s ease` |
| Font (UI) | `FiraCode Nerd Font` |
| Font (GTK apps) | `Adwaita Sans 11` |
| Cursor size | `32` |
| Icon theme | `Papirus-Dark` |

### Behavioral UX Principles

These reflect how a polished desktop should behave, informed by macOS/Windows conventions:

- **Power button** opens a power menu (wlogout), never instant shutdown. Configured via logind drop-in, handled by Hyprland keybind.
- **Notifications** go through mako. Any action that benefits from user feedback (screenshots, errors) should use `notify-send`.
- **Dark mode** is signaled to all apps: `GTK_THEME=Adwaita:dark` env var, `prefer-dark` gsettings, GTK3/GTK4 `settings.ini`.
- **Fingerprint auth** only works reliably through hyprlock's native D-Bus (parallel with password) and sudo PAM (with timeout fallback). Never add `pam_fprintd` to `system-auth` or display manager PAM — it blocks.
- **Boot should be quiet** (`quiet loglevel=3 systemd.show_status=auto`) — errors and LUKS prompts still show, but normal startup is silent.
- **TPM2 auto-unlocks** LUKS root when available, so users only type their password once (at login). Passphrase is kept as fallback.

### Multi-Machine Portability

All configs must work across different machines without hostname checks:

- Use display-adaptive thresholds (effective pixel width) not hardcoded monitor names
- Host-type settings (`desktop`/`laptop`) control gaps, blur, shadows — not machine identity
- Pixel values in wlogout margins, hyprlock sizing, etc. should be reasonable across 1080p–4K
- The installer (`setup.sh`) auto-detects hardware (fingerprint, bluetooth, TPM, SOF audio) and only configures what's present

## Development Patterns

- `setup.sh` is idempotent — safe to run multiple times
- Use `grep -q` for idempotent file modifications
- Platform detection uses `uname` to branch Linux/Darwin behavior
- System config changes use drop-in directories (e.g. `/etc/systemd/logind.conf.d/`) to survive package upgrades
- PAM changes go in per-service files (`/etc/pam.d/sudo`), not in global `system-auth`

## Validation

- Shell scripts: `bash -n <script>` for syntax checking
- CSS: verify balanced braces after edits
- JSONC: strip comments and parse as JSON to validate
- Hyprland: `hyprctl reload` to test config changes live
- GTK theme: open `thunar` or `pavucontrol` to verify dark mode and icon theme
- Notifications: `notify-send "Test" "message"` to verify mako is running and themed
- Screenshots: test all three Print key combos after any keybind changes
