#!/usr/bin/env bash

# linux-specific bashinit scripts
# this assumes you're using arch linux

export PATH="$HOME/.local/bin:$PATH"
alias pacman-orphans="sudo pacman -Rns $(pacman -Qtdq)"
alias pacman-update="sudo pacman -Syu"

# Smart pacman sync — skips tatara if grahamcube is unreachable
pac() {
    if ping -c1 -W1 grahamcube &>/dev/null 2>&1; then
        sudo pacman -Sy "$@"
    else
        echo "[pac] tatara unreachable, syncing official repos only"
        local tmpconf
        tmpconf=$(mktemp /tmp/pacman-XXXXXX.conf)
        awk '/^\[tatara\]/{skip=1} /^\[/ && !/^\[tatara\]/{skip=0} !skip' /etc/pacman.conf > "$tmpconf"
        sudo pacman --config "$tmpconf" -Sy "$@"
        rm -f "$tmpconf"
    fi
}
