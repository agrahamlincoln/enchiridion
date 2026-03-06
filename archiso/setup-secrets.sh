#!/usr/bin/env bash
# Populate gitignored files for the custom ISO build.
# Run once after cloning the repo on a new machine.
#
# These files are not committed because they contain secrets or are
# binary/version-specific. The ISO builds fine without them — paru
# falls back to building from source, SSH/git/repo setup is skipped,
# and Wi-Fi requires manual iwctl on the live ISO.
#
# Usage: ./archiso/setup-secrets.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SECRETS="$SCRIPT_DIR/airootfs/root/secrets"
AIROOTFS="$SCRIPT_DIR/airootfs"

echo "Setting up gitignored files for ISO build..."

# ── SSH keys ─────────────────────────────────────────────────────────
# Baked into the ISO so the installed system has SSH ready on first login.

SSH_DIR="$SECRETS/ssh"
if [[ -f ~/.ssh/key-per ]]; then
    mkdir -p "$SSH_DIR"
    cp ~/.ssh/key-per ~/.ssh/key-per.pub "$SSH_DIR/"
    [[ -f ~/.ssh/config ]] && cp ~/.ssh/config "$SSH_DIR/"
    echo "  Copied SSH keys and config."
else
    echo "  SKIP: ~/.ssh/key-per not found."
fi

# ── Git config ───────────────────────────────────────────────────────
# Installed as ~/.gitconfig on the target system.

if [[ -f ~/.gitconfig ]]; then
    mkdir -p "$SECRETS"
    cp ~/.gitconfig "$SECRETS/gitconfig"
    echo "  Copied gitconfig."
elif git config --global user.name &>/dev/null; then
    mkdir -p "$SECRETS"
    git config --global --list | while IFS='=' read -r key value; do
        section="${key%%.*}"
        param="${key#*.}"
        git config -f "$SECRETS/gitconfig" "$section.$param" "$value"
    done
    echo "  Generated gitconfig from git global config."
else
    echo "  SKIP: No git global config found."
fi

# ── Custom pacman repositories ───────────────────────────────────────
# Appended to /etc/pacman.conf on the target system.

REPOS_FILE="$SECRETS/pacman-repos.conf"
if [[ ! -f "$REPOS_FILE" ]]; then
    # Extract custom repos from the current machine's pacman.conf
    # (anything after the standard [multilib] section)
    if grep -q '\[tatara\]' /etc/pacman.conf 2>/dev/null; then
        mkdir -p "$SECRETS"
        sed -n '/^\[tatara\]/,$ p' /etc/pacman.conf | grep -v '^#.*MANAGED BY' > "$REPOS_FILE"
        echo "  Extracted custom pacman repos from /etc/pacman.conf."
    else
        echo "  SKIP: No custom pacman repos found in /etc/pacman.conf."
        echo "         Create $REPOS_FILE manually if needed."
    fi
else
    echo "  pacman-repos.conf already exists."
fi

# ── Pre-built paru package ──────────────────────────────────────────
# Speeds up install by avoiding compilation in the chroot.

PKG_DIR="$AIROOTFS/root/pkg"
PARU_PKG="$(find ~/.cache/paru/clone/paru/ -name 'paru-*.pkg.tar.zst' 2>/dev/null | sort -V | tail -1)"
if [[ -n "$PARU_PKG" ]]; then
    mkdir -p "$PKG_DIR"
    cp "$PARU_PKG" "$PKG_DIR/"
    echo "  Copied paru package: $(basename "$PARU_PKG")"
elif command -v paru &>/dev/null; then
    echo "  SKIP: paru is installed but no cached package found."
    echo "         Run 'paru -S paru' to rebuild and cache it, then re-run this script."
else
    echo "  SKIP: paru not installed. Installer will build from source."
fi

# ── Wi-Fi credentials for live ISO ──────────────────────────────────
# Allows the live ISO to auto-connect to Wi-Fi on boot via iwd.

IWD_DIR="$AIROOTFS/var/lib/iwd"
if ! ls "$IWD_DIR"/*.psk &>/dev/null; then
    echo ""
    read -rp "  Configure Wi-Fi for the live ISO? [y/N]: " wifi
    if [[ "$wifi" =~ ^[Yy]$ ]]; then
        read -rp "  SSID: " ssid
        read -rsp "  Passphrase: " pass
        echo ""
        mkdir -p "$IWD_DIR"
        cat > "$IWD_DIR/${ssid}.psk" <<EOF
[Security]
Passphrase=${pass}
EOF
        echo "  Created iwd profile for '$ssid'."
    else
        echo "  SKIP: No Wi-Fi configured. Use iwctl manually on the live ISO."
    fi
else
    echo "  Wi-Fi profile already exists."
fi

echo ""
echo "Done. Run 'sudo ./archiso/build.sh' to build the ISO."
