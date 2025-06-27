#!/usr/bin/env bash

# linux-specific bashinit scripts
# this assumes you're using arch linux
alias pacman-orphans="sudo pacman -Rns $(pacman -Qtdq)"
alias pacman-update="sudo pacman -Syu"
