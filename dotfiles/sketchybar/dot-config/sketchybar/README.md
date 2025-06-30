# SketchyBar Configuration

This directory contains the configuration for [SketchyBar](https://github.com/FelixKratz/SketchyBar), a highly customizable macOS status bar replacement.

## Files

- `sketchybarrc` - Main executable configuration script
- `init.lua` - Lua initialization script
- `bar.lua` - Bar appearance configuration
- `colors.lua` - Color scheme definitions
- `default.lua` - Default item configurations
- `icons.lua` - Icon definitions and styling
- `settings.lua` - General settings and configuration
- `helpers/` - Helper scripts and utilities
- `items/` - Individual bar item configurations

## Installation

This configuration is automatically installed when running:

```bash
just setup
```

Or manually with:

```bash
just install-dotfiles sketchybar
```

This will create a symlink from `~/.config/sketchybar` to this configuration directory.

## Usage

After installation, you can start SketchyBar with:

```bash
brew services start sketchybar
```

Or run it manually:

```bash
sketchybar
```

## Dependencies

Make sure you have SketchyBar installed:

```bash
brew install sketchybar
```

## Customization

The configuration is written in Lua and provides a modular structure for easy customization. Modify the individual files to adjust colors, icons, items, and behavior to your preferences.