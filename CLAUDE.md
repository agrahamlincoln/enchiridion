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

### Adding a New Dotfiles Package

1. Create `dotfiles/<app>/dot-config/<app>/` with the config files
2. Stow it: `cd dotfiles && stow -t ~ --dotfiles --ignore='CLAUDE\.md' --ignore='README\.md' -S <app>`
3. Add the system package to the appropriate file in `packages/` (e.g., `arch-pacman.txt`, `brew-formulae.txt`)
4. Add `<app>` to the appropriate OS dotfiles list in `setup.sh`

The stow invocations use `--dotfiles` (converts `dot-` prefixes to `.`) and ignore `CLAUDE.md`/`README.md` so documentation files are not symlinked into `~`.

### Package Management

System packages are defined in `packages/`, one package per line with `#` comments and blank lines for grouping:
- `arch-pacman.txt` — Official Arch repo packages (installed via `pacman`)
- `arch-aur.txt` — AUR packages (installed via `paru`)
- `brew-taps.txt` — Homebrew taps
- `brew-formulae.txt` — Homebrew formulae
- `brew-casks.txt` — Homebrew casks

To add a new system dependency, append it to the relevant file and run `./setup.sh`.

## Architecture

### Directory Structure
- `setup.sh` - Idempotent setup script (prerequisites, packages, dotfiles, bash config)
- `packages/` - Package list files (one package per line, `#` comments)
- `dotfiles/` - Stow-managed configs (kitty, hypr, waybar, zed, vim, etc.)
- `bashrc/bashinit/` - Bash initialization scripts

Tool-specific details live in subdirectory `CLAUDE.md` files (e.g., `dotfiles/hypr/CLAUDE.md`, `dotfiles/waybar/CLAUDE.md`) and are loaded automatically when working in those directories.

### Stow Convention
Files in `dotfiles/<app>/dot-config/<app>/` become `~/.config/<app>/` when stowed. The `--dotfiles` flag converts `dot-` prefixes to `.` prefixes.

### Color Palette

All configs share a unified color palette derived from Tailwind CSS colors. The canonical source is `kitty.conf`, and other tools (waybar, wlogout, wofi, hyprlock, bash-prompt, Zed theme) are aligned to it.

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
- **Surface**: `#333333`

When adding or modifying colors in any config, use values from this palette. Do not introduce one-off hex values.

### Display-Adaptive Configuration

Some configs adapt to screen size rather than hostname. The pattern is to query the effective display width (`resolution / scale`) and select a profile:
- **Compact** (< 2000px effective) - icon-only with tooltips, smaller fonts
- **Full** (>= 2000px effective) - icons with text labels

This approach works across different machines without hostname checks. See `dotfiles/waybar/CLAUDE.md` for the specific implementation.

### Host-Specific Configuration (Linux / Hyprland)

The Hyprland setup uses two independent config axes:
- **Host type** (`~/.config/hypr/host-type`): `desktop` or `laptop` — gaps, touchpad, visual effects
- **Keyboard layout** (`~/.config/hypr/kb-layout`): `dvorak` or `qwerty` — keybinds and `kb_variant`

Configuration flow:
1. `hyprland.conf` sources `host-settings.conf` and `host-keybinds.conf`
2. `update-host-config.sh` runs at startup, reads both files, and generates the config
3. Host-type settings live in `hosts/desktop/` and `hosts/laptop/`
4. Keyboard keybinds live in `hosts/dvorak/` and `hosts/qwerty/`

Edit the source files in `hosts/<type>/` and `hosts/<layout>/`, not the generated `host-*.conf` files.
To switch: `echo "laptop" > ~/.config/hypr/host-type && echo "dvorak" > ~/.config/hypr/kb-layout && hyprctl reload`

### Bash Initialization Chain
`bashinit.sh` sources these in order:
- `bash-prompt.sh` - Custom prompt with git integration (uses ANSI colors mapped to kitty palette)
- `bash-history.sh` - History configuration
- `ssh-agent.sh` - SSH agent setup
- `bash-linux.sh` or `bash-osx.sh` - Platform-specific settings

### OS-Specific Installations
- **Linux (Arch)**: hypr, waybar, gammastep, wofi, wlogout, mako, gtk, kitty, zed, vim
- **macOS**: yabai, skhd, sketchybar, kitty, zed, vim

### macOS Window Management
- **yabai + skhd**: BSP tiling WM with hotkey daemon, requires SIP disable
- **Sketchybar**: Custom status bar with SbarLua plugin and app font (installed by `setup.sh`)

## UX Cohesion

Every change to the Enchiridion is a change to a complete desktop environment. A single config edit can break visual or behavioral consistency across the system. Follow these rules to maintain cohesion.

### Cross-Cutting Change Checklist

Most changes touch multiple files. Before considering a change complete, check each affected layer:

| Change type | Files to check |
|---|---|
| **Color or font** | kitty.conf, waybar style.css, wofi style.css + scale-menu.css, wlogout style.css, hyprlock.conf, mako config, GTK settings.ini, bash-prompt.sh |
| **Border-radius or spacing** | waybar style.css, wofi style.css, wlogout style.css, hyprlock.conf, mako config, hyprland hosts/desktop + hosts/laptop settings |
| **Wlogout invocation** | hyprland.conf (keybind + XF86PowerOff), waybar config.jsonc, waybar config-compact.jsonc |
| **Screenshot workflow** | hyprland.conf keybinds (3 binds: Print, Super+Print, Super+Shift+Print) |
| **New dotfiles package** | Create `dotfiles/<app>/`, add to `packages/`, add to `setup.sh` stow list, add to OS-Specific Installations in this file |
| **System config change** | `setup.sh` (for new installs), use drop-in files under `/etc/systemd/*.conf.d/` rather than editing main configs |

### Visual Design Tokens

These values are used consistently across all UI components:

| Token | Value | Used in |
|---|---|---|
| Border radius (standard) | `10px` | waybar pills, wofi, wlogout, hyprlock, mako |
| Border radius (tight) | `6px` | wofi entries, scale-menu entries |
| Border width | `2px` | All component borders |
| Transition duration | `0.3s ease` | waybar, wlogout, wofi hover states |
| Font (UI) | `FiraCode Nerd Font` | waybar, wofi, wlogout, hyprlock |
| Font (GTK apps) | `Adwaita Sans 11` | GTK settings, gsettings |
| Cursor size | `32` | hyprland env, GTK settings, gsettings |
| Icon theme | `Papirus-Dark` | GTK settings, gsettings, mako |

### Semantic Colors

Use Arch Blue (`#1793d1`) as the **only** interactive accent. Other palette colors have fixed semantic roles:

| Color | Semantic role |
|---|---|
| `#1793d1` (Arch Blue) | Active/selected states, interactive borders, focus rings |
| `#f43f5e` (Red) | Errors, critical alerts, muted/disconnected states |
| `#22c55e` (Green) | Success, auth check passed, battery good |
| `#fcd34d` (Yellow) | Warnings, caps/num lock, battery mid, high resource use |
| `#333333` (Surface) | Module/container backgrounds, inactive borders |
| `#444444` (Alt surface) | Hover states, secondary surfaces |
| `#0a0a0a` (Background) | Window/app backgrounds |
| `#d6d3d1` (Foreground) | Primary text in all components |

### Behavioral UX Principles

These reflect how a polished desktop environment should behave, informed by macOS/Windows conventions:

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

- `setup.sh` is idempotent - safe to run multiple times
- Check for existing symlinks/configs before creating new ones
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
