# AeroSpace Configuration

Migrated from yabai + skhd to AeroSpace tiling window manager.

## Why AeroSpace?

- **No SIP disabling required** - Uses minimal private APIs
- **More stable** - Fewer breaks across macOS updates
- **Simpler** - One tool instead of yabai + skhd
- **i3-like** - Familiar workflow for Linux users

## Installation

```bash
# Install via Homebrew
brew install --cask nikitabobko/tap/aerospace

# The cask includes automatic updates
```

## Setup

This configuration is managed via dotfiles. To activate:

```bash
# Using stow from the dotfiles directory
cd ~/projects/enchiridion/dotfiles
stow aerospace

# Or manually symlink
ln -sf ~/projects/enchiridion/dotfiles/aerospace/dot-config/aerospace/aerospace.toml ~/.config/aerospace/aerospace.toml
```

## Configuration Overview

The `aerospace.toml` file mirrors your previous yabai + skhd setup:

### Keybindings

Most keybindings remain the same:

| Action | Keybinding | Notes |
|--------|-----------|-------|
| **Workspace Navigation** |
| Switch to workspace 1-9 | `cmd-1` through `cmd-9` | Same as yabai |
| Previous/next workspace | `cmd-alt-left/right` | Same as yabai |
| **Window Navigation** |
| Focus window | `cmd-arrow` | Same as yabai |
| **Window Movement** |
| Move window in space | `cmd-shift-arrow` | Same as yabai |
| Move window to workspace | `cmd-shift-1` through `cmd-shift-9` | Same as yabai |
| **Workspace/Monitor** |
| Move workspace to monitor | `cmd-ctrl-left/right` | Same as yabai |
| Move workspace to monitor # | `cmd-ctrl-1/2/3` | Same as yabai |
| **Layout** |
| Toggle fullscreen | `cmd-shift-f` | Same as yabai |
| Toggle split orientation | `cmd-shift-s` | Same as yabai |
| Balance windows | `cmd-shift-p` | Same as yabai "tidy up" |
| **Resize Mode** |
| Enter resize mode | `cmd-p` | Same as yabai |
| (In resize mode) Resize | `cmd-arrow` | Same as yabai |
| Exit resize mode | `cmd-p` or `esc` | Same as yabai |
| **Other** |
| Open terminal | `cmd-return` | Opens Kitty |
| Service mode | `cmd-shift-;` | Advanced operations |

### Layout

- Default layout: `tiles` (similar to yabai's BSP)
- Focus follows mouse: Enabled
- Gaps: Match yabai settings (top=35px, others=5px)

### Application Rules

Float apps that shouldn't be tiled:
- System Preferences
- Zoom

## Differences from yabai

### What's Different

1. **No window borders** - AeroSpace doesn't support window borders like yabai/JankyBorders
2. **Virtual workspaces** - Uses its own workspace system instead of macOS Spaces
3. **No create/destroy spaces** - Workspaces are pre-configured (1-9)
4. **Different layout paradigm** - i3-like tree structure vs yabai's BSP

### What's Better

1. **More stable** - Fewer private APIs means fewer macOS update breakages
2. **Simpler** - One tool instead of yabai + skhd
3. **No SIP disable** - Works without disabling System Integrity Protection
4. **Better maintained** - Active development with clear roadmap

## Migration Steps

1. **Install AeroSpace**: `brew install --cask nikitabobko/tap/aerospace`
2. **Stop yabai**: `brew services stop yabai`
3. **Stop skhd**: `brew services stop skhd`
4. **Deploy config**: `stow aerospace` (from dotfiles directory)
5. **Start AeroSpace**: It should auto-start, or run `/Applications/AeroSpace.app`
6. **Test**: Try your keybindings
7. **Iterate**: Adjust config in `~/.config/aerospace/aerospace.toml`
8. **Reload config**: `aerospace reload-config` after changes

## Sketchybar Integration

Your sketchybar config will need updates to work with AeroSpace:

```bash
# AeroSpace triggers events differently than yabai
# Update your sketchybar plugins to listen for:
sketchybar --trigger aerospace_workspace_change
```

See the `exec-on-workspace-change` section in `aerospace.toml` for how this is configured.

## Troubleshooting

### Config not loading
```bash
# Check for syntax errors
aerospace debug-config

# Reload config manually
aerospace reload-config
```

### Keybindings not working
```bash
# Check if AeroSpace has accessibility permissions
# System Settings > Privacy & Security > Accessibility > AeroSpace
```

### Windows not tiling
```bash
# Check if app is in floating mode
# Try: cmd-shift-f to toggle fullscreen
# Or use service mode (cmd-shift-;) then 'f' to toggle floating/tiling
```

## Resources

- [AeroSpace Guide](https://nikitabobko.github.io/AeroSpace/guide)
- [AeroSpace Commands](https://nikitabobko.github.io/AeroSpace/commands)
- [Default Config Example](https://github.com/nikitabobko/AeroSpace/blob/main/docs/config-examples/default-config.toml)

## Reverting to yabai

If you need to go back:

```bash
# Stop AeroSpace
osascript -e 'quit app "AeroSpace"'

# Start yabai and skhd
brew services start yabai
brew services start skhd
```
