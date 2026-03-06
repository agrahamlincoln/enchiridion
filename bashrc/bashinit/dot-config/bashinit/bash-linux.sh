#!/usr/bin/env bash

# linux-specific bashinit scripts
# this assumes you're using arch linux

export PATH="$HOME/.local/bin:$PATH"
alias pacman-orphans="sudo pacman -Rns $(pacman -Qtdq)"
alias pacman-update="sudo pacman -Syu"
