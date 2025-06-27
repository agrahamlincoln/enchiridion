# The Enchiridion

The Enchiridion is a repository of configuration for my systems. The mission of
this codebase is to provide a single source of truth to opinionate any system to
my likings.

## What's Included?

This repository contains configurations for a variety of tools, including:

*   **Window Managers:** Hyprland
*   **Editors:** Vim, Zed
*   **Terminal:** Kitty
*   **Status Bars:** Polybar, Waybar
*   **Shell:** Bash, with a custom prompt and virtualenvwrapper support
*   **Other Tools:** Git, Gammastep, and more.

## Installation

The recommended way to install these dotfiles is with `just`. `just` is a command
runner that provides a simple way to automate tasks. You can learn more about
`just` [here](https://github.com/casey/just).

To get started, run the following command:

```bash
just setup
```

This will install the relevant dotfiles and bash configuration for your operating
system. It will also install any necessary dependencies.

For more advanced or manual installation instructions, please see the READMEs in
the relevant subdirectories.

## Why `stow` and `just`?

This repository uses `stow` to manage dotfiles and `just` to automate setup.
Here's why:

*   **`stow`:** `stow` is a symlink farm manager that makes it easy to manage
    dotfiles across multiple machines. It allows you to keep your dotfiles in a
    single repository and then symlink them into place on each machine. This
    makes it easy to keep your dotfiles in sync and to share them with others.
*   **`just`:** `just` is a command runner that provides a simple way to
    automate tasks. It's similar to `make`, but it's simpler and more modern.
    `just` is used in this repository to automate the installation of dotfiles
    and other dependencies. This makes it easy to get up and running quickly on a
    new machine.
