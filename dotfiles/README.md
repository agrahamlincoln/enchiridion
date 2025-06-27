# Dotfiles

These are my dotfiles!

I use `stow` to install these. See [stow(8)](https://linux.die.net/man/8/stow) for more details.

Recommended pairings and installation commands:

```bash
cd /path/to/dotfiles/
# kitty / waybar / hyprland setup
stow -t ~ --dotfiles -S hypr kitty waybar

# i3-polybar-kitty combo
stow -t ~ -S i3 polybar kitty

# Experimental: this uses wayland
# sway waybar kitty combo
# stow -t ~ -S sway waybar kitty
```
