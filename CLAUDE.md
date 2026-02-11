# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Enchiridion is a personal dotfiles repository for managing system configurations across multiple machines (laptops and desktops). It uses `stow` for symlink management and `just` for automation.

## Common Commands

```bash
# Full environment setup (installs packages, dotfiles, and configures bash)
just setup

# Install specific dotfiles
just install-dotfiles kitty hypr waybar zed vim

# Configure bash initialization
just install-bashinit

# Fetch GitHub token from Bitwarden
just setup-env
```

## Architecture

### Directory Structure
- `dotfiles/` - Stow-managed configs (kitty, hypr, waybar, zed, vim, etc.)
- `bashrc/bashinit/` - Bash initialization scripts
- `Justfile` - Main automation targets

### Stow Convention
Files in `dotfiles/<app>/dot-config/<app>/` become `~/.config/<app>/` when stowed. The `--dotfiles` flag converts `dot-` prefixes to `.` prefixes.

### Host-Specific Configuration (Hyprland)
The system detects hostname to apply laptop vs desktop settings:
- **zaxtec** → laptop (QWERTY keybinds, touchpad, smaller gaps)
- **other** → desktop (Dvorak keybinds, larger gaps)

Configuration flow:
1. `hyprland.conf` sources `host-settings.conf` and `host-keybinds.conf`
2. `update-host-config.sh` runs at startup to generate these files
3. Source configs live in `hosts/laptop/` and `hosts/desktop/`

Edit the source files in `hosts/<type>/`, not the generated `host-*.conf` files.

### Bash Initialization Chain
`bashinit.sh` sources these in order:
- `bash-prompt.sh` - Custom prompt with git integration
- `bash-history.sh` - History configuration
- `ssh-agent.sh` - SSH agent setup
- `zed-workspaces.sh` - Zed workspace management (`z` command)
- `bash-linux.sh` or `bash-osx.sh` - Platform-specific settings

### OS-Specific Installations
- **Linux (Arch)**: hypr, waybar, gammastep, wofi, kitty, zed, vim
- **macOS**: aerospace (or yabai+skhd), sketchybar, kitty, zed, vim

### macOS Window Management
Two options are available:
- **AeroSpace** (recommended): i3-like tiling WM, no SIP disable required, more stable
- **yabai + skhd**: Traditional BSP layout, requires SIP disable

AeroSpace configuration is in `dotfiles/aerospace/` with keybindings matching the previous yabai setup.

## Development Patterns

- All justfile targets are idempotent - safe to run multiple times
- Check for existing symlinks/configs before creating new ones
- Use `grep -q` for idempotent file modifications
- Platform detection uses `uname` to branch Linux/Darwin behavior
