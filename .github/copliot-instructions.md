The Enchiridion is a repository for system configuration, providing a single source of truth for personal customizations.

Its `dotfiles` directory contains `stow`-managed configurations for: `gammastep`, `hypr`, `i3`, `kitty`, `polybar`, `skhd`, `sway`, `vim`, `waybar`, `yabai`, and `zed`. Installation details for various setups are in `enchiridion/dotfiles/README.md`.

## Styling Waybar

Waybar uses GTK/Pango to render CSS, which does not support all css directives, some examples that it does not support:

* `display`
* `text-align`
