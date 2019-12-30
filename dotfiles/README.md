# Dotfiles

These are my dotfiles!

I use `stow` to install these. See [stow(8)](https://linux.die.net/man/8/stow) for more details.

Recommended pairings and installation commands:

```bash
cd /path/to/dotfiles/
# i3-polybar-kitty combo
stow -t ~ -S i3 polybar kitty
# tmux and vim
stow -t ~ -S tmux vim

# Experimental: this uses wayland
# sway waybar kitty combo
# stow -t ~ -S sway waybar kitty
```

## Required packages

### i3-polybar combo

the i3-polybar combo requires the following packages:

* python-i3ipc
* ttf-fira-code [aur]
* udiskie
* rofi
* redshift
* pulseaudio
* scrot
* i3-gaps
* polybar
* python-fontawesome [aur]
