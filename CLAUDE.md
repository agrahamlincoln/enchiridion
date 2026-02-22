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

The Hyprland setup detects hostname for laptop vs desktop settings:
- **zaxtec** - laptop (QWERTY keybinds, touchpad, smaller gaps)
- **other** - desktop (Dvorak keybinds, larger gaps)

Configuration flow:
1. `hyprland.conf` sources `host-settings.conf` and `host-keybinds.conf`
2. `update-host-config.sh` runs at startup to generate these files
3. Source configs live in `hosts/laptop/` and `hosts/desktop/`

Edit the source files in `hosts/<type>/`, not the generated `host-*.conf` files.

### Bash Initialization Chain
`bashinit.sh` sources these in order:
- `bash-prompt.sh` - Custom prompt with git integration (uses ANSI colors mapped to kitty palette)
- `bash-history.sh` - History configuration
- `ssh-agent.sh` - SSH agent setup
- `zed-workspaces.sh` - Zed workspace management (`z` command)
- `bash-linux.sh` or `bash-osx.sh` - Platform-specific settings

### OS-Specific Installations
- **Linux (Arch)**: hypr, waybar, gammastep, wofi, wlogout, kitty, zed, vim
- **macOS**: yabai, skhd, sketchybar, kitty, zed, vim

### macOS Window Management
- **yabai + skhd**: BSP tiling WM with hotkey daemon, requires SIP disable
- **Sketchybar**: Custom status bar with SbarLua plugin and app font (installed by `setup.sh`)

## Development Patterns

- `setup.sh` is idempotent - safe to run multiple times
- Check for existing symlinks/configs before creating new ones
- Use `grep -q` for idempotent file modifications
- Platform detection uses `uname` to branch Linux/Darwin behavior

## Validation

- Shell scripts: `bash -n <script>` for syntax checking
- CSS: verify balanced braces after edits
- JSONC: strip comments and parse as JSON to validate
- Hyprland: `hyprctl reload` to test config changes live
