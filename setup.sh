#!/usr/bin/env bash
# Idempotent setup for the Enchiridion dotfiles.
# Installs prerequisites, system packages, dotfiles, and bash configuration.
# Safe to run on a fresh machine or an already-configured one.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$REPO_DIR/dotfiles"

echo "--- Enchiridion Setup ---"
echo "Repository: $REPO_DIR"

OS="$(uname)"

# Helper: read a package list file, stripping comments and blank lines
read_packages() {
    grep -v '^\s*#' "$REPO_DIR/packages/$1" | grep -v '^\s*$' | tr '\n' ' '
}

# Helper: stow a dotfiles target idempotently
stow_target() {
    local target="$1"
    if [[ ! -L "$HOME/.config/$target" ]]; then
        if stow -t ~ --dotfiles --ignore='CLAUDE\.md' --ignore='README\.md' -S "$target"; then
            echo "  Stowed $target."
        else
            echo "  Error: Failed to stow $target." >&2
        fi
    else
        echo "  - $target already stowed."
    fi
}

# ── Prerequisites ─────────────────────────────────────────────────────

echo -e "\n--- Prerequisites ---"

if [[ "$OS" == "Linux" ]]; then
    echo "Detected Linux (Arch)."

    if ! command -v stow &>/dev/null; then
        echo "-> Installing base prerequisites..."
        sudo pacman -S --noconfirm --needed base-devel git stow
    else
        echo "- stow already installed."
    fi

    if ! command -v paru &>/dev/null; then
        echo "-> Building paru from AUR..."
        PARU_DIR="$(mktemp -d)"
        git clone https://aur.archlinux.org/paru.git "$PARU_DIR/paru"
        pushd "$PARU_DIR/paru" > /dev/null
        makepkg -si --noconfirm
        popd > /dev/null
        rm -rf "$PARU_DIR"
        echo "- paru installed."
    else
        echo "- paru already installed."
    fi

elif [[ "$OS" == "Darwin" ]]; then
    echo "Detected macOS."

    if ! xcode-select -p &>/dev/null; then
        echo "-> Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "   Re-run this script after installation completes."
        exit 0
    else
        echo "- Xcode CLI tools already installed."
    fi

    if ! command -v brew &>/dev/null; then
        echo "-> Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo "- Homebrew already installed."
    fi

    if ! command -v stow &>/dev/null; then
        echo "-> Installing stow..."
        brew install stow
    else
        echo "- stow already installed."
    fi

else
    echo "Unsupported OS: $OS" >&2
    exit 1
fi

# ── System Packages ───────────────────────────────────────────────────

echo -e "\n--- System Packages ---"

if [[ "$OS" == "Linux" ]]; then
    echo "-> Installing pacman packages..."
    sudo pacman -S --noconfirm --needed $(read_packages arch-pacman.txt)

    echo "-> Installing AUR packages..."
    paru -S --noconfirm --needed $(read_packages arch-aur.txt)

elif [[ "$OS" == "Darwin" ]]; then
    echo "-> Checking Homebrew taps..."
    for tap in $(read_packages brew-taps.txt); do
        if ! brew tap | grep -q "^${tap}$"; then
            echo "   Tapping $tap..."
            brew tap "$tap"
        else
            echo "   - $tap already tapped."
        fi
    done

    echo "-> Installing Homebrew formulae..."
    brew install $(read_packages brew-formulae.txt) 2>/dev/null || true

    echo "-> Installing Homebrew casks..."
    brew install --cask $(read_packages brew-casks.txt) 2>/dev/null || true

    # Build SbarLua if not present
    if ! lua -e "require('sketchybar')" &>/dev/null; then
        echo "-> Building SbarLua from source..."
        SBARLUA_DIR="$(mktemp -d)"
        git clone https://github.com/FelixKratz/SbarLua.git "$SBARLUA_DIR/SbarLua"
        pushd "$SBARLUA_DIR/SbarLua" > /dev/null
        make install
        popd > /dev/null
        rm -rf "$SBARLUA_DIR"
        echo "- SbarLua installed."
    else
        echo "- SbarLua already installed."
    fi

    # Download sketchybar-app-font if not present
    FONT_FILE="$HOME/Library/Fonts/sketchybar-app-font.ttf"
    if [[ ! -f "$FONT_FILE" ]]; then
        echo "-> Downloading sketchybar-app-font..."
        mkdir -p "$HOME/Library/Fonts"
        curl -fsSL -o "$FONT_FILE" \
            "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf"
        echo "- sketchybar-app-font installed."
    else
        echo "- sketchybar-app-font already installed."
    fi
fi

# ── Dotfiles ──────────────────────────────────────────────────────────

echo -e "\n--- Dotfiles ---"

pushd "$DOTFILES_DIR" > /dev/null
if [[ "$OS" == "Darwin" ]]; then
    for target in kitty yabai skhd sketchybar zed vim; do
        stow_target "$target"
    done
else
    for target in kitty hypr waybar wlogout zed vim gammastep wofi; do
        stow_target "$target"
    done
fi
popd > /dev/null

# ── Bash Configuration ────────────────────────────────────────────────

echo -e "\n--- Bash Configuration ---"

pushd "$REPO_DIR/bashrc" > /dev/null
stow -t ~ --dotfiles --ignore='CLAUDE\.md' --ignore='README\.md' -S bashinit
popd > /dev/null
echo "- bashinit stowed."

if ! grep -q "source ~/.config/bashinit/bashinit.sh" ~/.bashrc; then
    echo "source ~/.config/bashinit/bashinit.sh" >> ~/.bashrc
    echo "- Added source line to ~/.bashrc."
else
    echo "- ~/.bashrc already configured."
fi

# ──────────────────────────────────────────────────────────────────────

echo -e "\n--- Setup Complete ---"
