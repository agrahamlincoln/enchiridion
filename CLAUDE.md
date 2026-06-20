# CLAUDE.md

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

**Stow creates symlinks, not copies.** Editing a source file in this repo directly modifies the live config — no re-stow needed. Only re-stow when files are added/removed from a package or its directory structure changes (symlinks must be created/deleted). Never re-stow just because you edited an existing file's contents.

### Adding a New Dotfiles Package

1. Create `dotfiles/<app>/dot-config/<app>/` with the config files
2. Add the system package to the appropriate file in `packages/` (one package per line, `#` comments)
3. Add `<app>` to the OS dotfiles list in `setup.sh`
4. Stow it with the command under Common Commands above.

### Host-Specific Configuration (Linux / Hyprland)

Two independent config axes, combined at startup by `update-host-config.sh`:
- **Host type** (`~/.config/hypr/host-type`): `desktop` or `laptop` — gaps, touchpad, visual effects
- **Keyboard layout** (`~/.config/hypr/kb-layout`): `dvorak` or `qwerty` — keybinds and `kb_variant`

Edit the source files in `hosts/<type>/` and `hosts/<layout>/`, not the generated `host-settings.conf`/`host-keybinds.conf`.

### Display-Adaptive Configuration

Configs adapt to screen size rather than hostname. The pattern is to query effective display width (`resolution / scale`) and select a profile:
- **Compact** (< 2000px effective) — icon-only with tooltips
- **Full** (>= 2000px effective) — icons with text labels

Tool-specific details live in subdirectory `CLAUDE.md` files (e.g., `dotfiles/hypr/CLAUDE.md`, `dotfiles/wayle/CLAUDE.md`).

## UX Cohesion

Every change to the Enchiridion is a change to a complete desktop environment. A single config edit can break visual or behavioral consistency across the system.

### Cross-Cutting Change Checklist

Most changes touch multiple files. Before considering a change complete, check each affected layer:

| Change type | Files to check |
|---|---|
| **Color or font** | kitty.conf, wayle config.base.toml (palette), wofi style.css + scale-menu.css, wlogout style.css, hyprlock.conf, GTK settings.ini, bash-prompt.sh |
| **Border-radius or spacing** | wayle config.base.toml (rounding), wofi style.css, wlogout style.css, hyprlock.conf, hyprland hosts/desktop + hosts/laptop settings |
| **Wlogout invocation** | hyprland.conf (keybind + XF86PowerOff), wayle config.base.toml (power module) |
| **Suspend/hibernate** | hypridle.conf, wlogout layout, setup.sh (swap/hibernate + lid sections), logind + sleep.conf.d drop-ins |
| **Screenshot workflow** | hyprland.conf keybinds (3 binds: Print, Super+Print, Super+Shift+Print) |
| **New dotfiles package** | See "Adding a New Dotfiles Package" above |
| **System config change** | `setup.sh` (for new installs), use drop-in files under `/etc/systemd/*.conf.d/` rather than editing main configs |

### Design System

Full color palette, semantic roles, attention-hierarchy rationale, and visual tokens (border radius, fonts, cursor, icon theme) live in `docs/design-system.md`. Canonical color source is `kitty.conf`. Read that doc before any color or visual change. The always-on invariants:

- **Arch Blue `#1793d1` is the only interactive accent.** Use palette values only — never one-off hex.
- **Normal/good states are invisible** (default text color); color appears only when attention is needed.
- **Warnings use amber `#d97706`, not yellow** — yellow outshines red (critical), breaking the urgency hierarchy.

### Behavioral UX Principles

- **Power button** opens a power menu (wlogout), never instant shutdown. Configured via logind drop-in, handled by Hyprland keybind.
- **Notifications** go through Wayle's built-in notification daemon. Any action that benefits from user feedback (screenshots, errors) should use `notify-send`.
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

Beyond the standard formatter/syntax checks:
- Hyprland: `hyprctl reload` to test config changes live
- GTK theme: open `thunar` or `pavucontrol` to verify dark mode and icon theme
- Notifications: `notify-send "Test" "message"` to verify Wayle's notification daemon is running
- Screenshots: test all three Print key combos after any keybind changes
