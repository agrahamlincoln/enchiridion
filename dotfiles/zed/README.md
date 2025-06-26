# Zed Editor Configuration

This directory contains the configuration for the Zed editor.

## Files

- `settings.json` - Main Zed configuration file with:
  - Vim mode enabled
  - Copilot AI agent configuration
  - Font settings (Fira Code with ligatures)
  - Language-specific settings for Python, TypeScript, Terraform, etc.
  - Theme and UI preferences
  - LSP configurations

## Installation

To install this configuration, use stow from the dotfiles directory:

```bash
cd /path/to/enchiridion/dotfiles
stow zed
```

This will create symlinks in `~/.config/zed/` pointing to the files in this directory.
