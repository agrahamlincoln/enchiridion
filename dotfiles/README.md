# Dotfiles

These are my dotfiles!

I use `stow` to install these. See [stow(8)](https://linux.die.net/man/8/stow) for more details.

Recommended pairings and installation commands:

```bash
cd /path/to/dotfiles/
# kitty / waybar / hyprland setup
stow -t ~ --dotfiles -S hypr kitty waybar
```
