# The Enchiridion

The Enchiridion is a repository of configuration for my systems. The mission of
this codebase is to provide a single source of truth to opinionate any system to
my likings.

## What's Included?

This repository contains configurations for a variety of tools, including:

*   **Window Managers:** Hyprland
*   **Editors:** Vim, Zed
*   **Terminal:** Kitty
*   **Status Bars:** Waybar, Sketchybar
*   **Shell:** Bash, with a custom prompt and virtualenvwrapper support
*   **Other Tools:** Git, Gammastep, and more.

## Installation

### New Machine

1. Clone this repo:
   ```bash
   git clone https://github.com/<user>/enchiridion.git ~/projects/enchiridion
   ```

2. Run setup:
   ```bash
   cd ~/projects/enchiridion
   ./setup.sh
   ```

   This installs prerequisites (stow, paru), system packages,
   dotfiles, and bash configuration.

### Updating

```bash
cd ~/projects/enchiridion
git pull
./setup.sh
```

### Adding a Package

Add the package name to the appropriate file in `packages/` and run `./setup.sh`.

## Why `stow`?

This repository uses `stow` to manage dotfiles. `stow` is a symlink farm
manager that makes it easy to manage dotfiles across multiple machines. It
allows you to keep your dotfiles in a single repository and then symlink them
into place on each machine. This makes it easy to keep your dotfiles in sync
and to share them with others.
