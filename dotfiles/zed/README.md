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
stow -t ~ --dotfiles --ignore='CLAUDE\.md' --ignore='README\.md' -S zed
```

This will create symlinks in `~/.config/zed/` pointing to the files in this directory.

## Themes

The custom generated themes in `dot-config/zed/themes/` are produced by [zed-irodori](https://github.com/agrahamlincoln/zed-irodori), a statistical analysis tool that generates "average" Zed themes from the community theme ecosystem. See that project for details on the analysis pipeline.
