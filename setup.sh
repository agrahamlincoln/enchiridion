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
    if stow -t ~ --dotfiles --ignore='CLAUDE\.md' --ignore='README\.md' -S "$target" 2>/dev/null; then
        echo "  Stowed $target."
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

    # SOF firmware: install only if SOF/ACP PDM audio hardware is detected
    # (needed for internal speakers/mic on modern AMD/Intel laptops)
    if grep -qiE 'sof|acppdm|acp-pdm' /proc/asound/cards 2>/dev/null; then
        echo "-> SOF/ACP PDM audio hardware detected, installing sof-firmware..."
        sudo pacman -S --noconfirm --needed sof-firmware
        echo "- sof-firmware installed."
    else
        echo "- No SOF audio hardware detected, skipping sof-firmware."
    fi

    # Bluetooth: install only if hardware is detected
    has_bluetooth=false
    if (command -v lspci &>/dev/null && lspci | grep -qi bluetooth) || \
       (command -v lsusb &>/dev/null && lsusb | grep -qi bluetooth) || \
       { [[ -d /sys/class/bluetooth ]] && compgen -G "/sys/class/bluetooth/hci*" &>/dev/null; }; then
        has_bluetooth=true
    fi

    if $has_bluetooth; then
        echo "-> Bluetooth hardware detected, installing bluez..."
        sudo pacman -S --noconfirm --needed bluez bluez-utils blueman
        sudo systemctl enable bluetooth.service
        echo "- bluez + blueman installed and bluetooth.service enabled."
    else
        echo "- No Bluetooth hardware detected, skipping bluez."
    fi

    # Fingerprint: install and configure only if a sensor is detected
    # Strategy: keep fprintd OUT of PAM entirely — ly and sudo don't handle
    # concurrent fingerprint+password well. Only hyprlock uses fingerprint,
    # via its native D-Bus auth block (parallel with password).
    if compgen -G "/sys/class/fingerprint/*" &>/dev/null; then
        echo "-> Fingerprint sensor detected, installing fprintd..."
        sudo pacman -S --noconfirm --needed fprintd
        # Clean up fprintd from system-wide and login PAM (blocks ly)
        for pamfile in system-auth ly; do
            if grep -q pam_fprintd /etc/pam.d/$pamfile; then
                sudo sed -i '/pam_fprintd/d' /etc/pam.d/$pamfile
                echo "- Removed pam_fprintd from $pamfile."
            fi
        done
        # Add fprintd to sudo (scan finger or wait 10s for password fallback)
        if ! grep -q pam_fprintd /etc/pam.d/sudo; then
            sudo sed -i '/^auth/i auth       sufficient   pam_fprintd.so max_tries=1 timeout=10' /etc/pam.d/sudo
            echo "- PAM configured for fingerprint sudo (10s timeout)."
        else
            echo "- sudo already configured for fingerprint."
        fi
        # Enroll fingerprint interactively (used by hyprlock only)
        if ! fprintd-list "$USER" 2>/dev/null | grep -q "right-index-finger"; then
            echo "-> Enrolling right index finger (touch the sensor repeatedly)..."
            sudo fprintd-enroll -f right-index-finger "$USER"
            echo "- Fingerprint enrolled."
        else
            echo "- Fingerprint already enrolled."
        fi
    else
        echo "- No fingerprint sensor detected, skipping fprintd."
    fi

    # Power button: open power menu instead of instant shutdown
    # Uses a logind.conf.d drop-in so it survives systemd upgrades
    if [[ ! -f /etc/systemd/logind.conf.d/power-button.conf ]]; then
        echo "-> Configuring power button to open power menu..."
        sudo mkdir -p /etc/systemd/logind.conf.d
        printf '[Login]\nHandlePowerKey=ignore\n' | sudo tee /etc/systemd/logind.conf.d/power-button.conf > /dev/null
        echo "- Power button set to ignore (Hyprland handles it via wlogout)."
    else
        echo "- Power button already configured."
    fi

    # TPM2 disk unlock: auto-unlock LUKS root via TPM2 so users only enter
    # their password once (at ly login) instead of twice (cryptroot + login).
    # Only runs if: TPM2 exists, LUKS root is detected, and not already enrolled.
    luks_dev=""
    if [[ -c /dev/tpmrm0 ]]; then
        # Find the LUKS device backing cryptroot
        luks_dev=$(lsblk -nrpo NAME,FSTYPE | awk '$2 == "crypto_LUKS" {print $1; exit}')
    fi
    if [[ -n "$luks_dev" ]]; then
        if sudo systemd-cryptenroll "$luks_dev" --tpm2-device=list &>/dev/null; then
            # Check if TPM2 is already enrolled
            if ! sudo cryptsetup luksDump "$luks_dev" 2>/dev/null | grep -q "systemd-tpm2"; then
                echo "-> Enrolling TPM2 for automatic disk unlock..."
                echo "   (You will be prompted for your LUKS passphrase)"
                sudo systemd-cryptenroll "$luks_dev" --tpm2-device=auto --tpm2-pcrs=7
                echo "- TPM2 enrolled. Disk will auto-unlock on trusted boot."
                echo "  NOTE: Your passphrase still works as a fallback."
            else
                echo "- TPM2 already enrolled for disk unlock."
            fi
        fi
    else
        echo "- No TPM2 + LUKS detected, skipping auto-unlock."
    fi

    # Quiet boot: suppress normal systemd/kernel output during boot.
    # Errors and interactive prompts (e.g. LUKS passphrase) still show.
    BOOT_ENTRY="/boot/loader/entries/arch.conf"
    if [[ -f "$BOOT_ENTRY" ]] && ! grep -q 'quiet' "$BOOT_ENTRY"; then
        echo "-> Enabling quiet boot..."
        sudo sed -i '/^options / s/$/ quiet loglevel=3 systemd.show_status=auto splash/' "$BOOT_ENTRY"
        echo "- Quiet boot enabled (errors and prompts still visible)."
    elif [[ -f "$BOOT_ENTRY" ]] && ! grep -q 'splash' "$BOOT_ENTRY"; then
        echo "-> Adding splash to boot entry..."
        sudo sed -i '/^options / s/$/ splash/' "$BOOT_ENTRY"
        echo "- splash parameter added."
    else
        echo "- Quiet boot already configured (or no systemd-boot entry found)."
    fi

    # Plymouth boot splash: show Arch logo animation during boot instead
    # of a black screen. Requires plymouth hook in initramfs.
    if command -v plymouth-set-default-theme &>/dev/null; then
        CURRENT_THEME="$(plymouth-set-default-theme 2>/dev/null)"
        if [[ "$CURRENT_THEME" != "arch-logo" ]]; then
            echo "-> Setting Plymouth theme to arch-logo..."
            sudo plymouth-set-default-theme -R arch-logo
            echo "- Plymouth theme set and initramfs rebuilt."
        else
            echo "- Plymouth theme already set to arch-logo."
        fi
        # Ensure plymouth hook is in mkinitcpio
        if ! grep -q 'plymouth' /etc/mkinitcpio.conf; then
            echo "-> Adding plymouth hook to mkinitcpio..."
            sudo sed -i 's/\(base systemd\)/\1 plymouth/' /etc/mkinitcpio.conf
            sudo mkinitcpio -P
            echo "- plymouth hook added and initramfs rebuilt."
        else
            echo "- plymouth hook already configured."
        fi
    else
        echo "- Plymouth not installed, skipping boot splash."
    fi

    # Swap and hibernate support: create swap file sized to RAM.
    # Swap file lives inside the LUKS volume, so it's encrypted at rest automatically.
    # Hibernate is opt-in: only enabled when ~/.config/hypr/use-hibernate exists.
    # hypridle and wlogout check this flag at runtime to choose hibernate vs suspend.
    BOOT_ENTRY="/boot/loader/entries/arch.conf"
    SWAPFILE="/swapfile"
    # Swap must be >= RAM for hibernate to write the full memory image
    SWAP_SIZE_GB=$(awk '/MemTotal/ {printf "%d", ($2 / 1048576) + 1}' /proc/meminfo)

    if [[ -f "$BOOT_ENTRY" ]] && grep -q 'cryptroot' "$BOOT_ENTRY"; then
        # Create swap file if it doesn't exist
        if [[ ! -f "$SWAPFILE" ]]; then
            echo "-> Creating ${SWAP_SIZE_GB}G swap file..."
            sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count=$((SWAP_SIZE_GB * 1024)) status=progress
            sudo chmod 600 "$SWAPFILE"
            sudo mkswap "$SWAPFILE"
            sudo swapon "$SWAPFILE"
            echo "- Swap file created and activated."
        else
            # Ensure swap is active
            if ! swapon --show | grep -q "$SWAPFILE"; then
                sudo swapon "$SWAPFILE"
            fi
            echo "- Swap file already exists."
        fi

        # Add swap to /etc/fstab if not already present
        if ! grep -q "$SWAPFILE" /etc/fstab; then
            echo "$SWAPFILE none swap defaults 0 0" | sudo tee -a /etc/fstab > /dev/null
            echo "- Swap file added to /etc/fstab."
        else
            echo "- Swap file already in /etc/fstab."
        fi

        # Add resume kernel parameters (needed for hibernate)
        if ! grep -q 'resume=' "$BOOT_ENTRY"; then
            RESUME_OFFSET=$(sudo filefrag -v "$SWAPFILE" | awk '$1=="0:" {print $4}' | sed 's/\.\.//')
            if [[ -n "$RESUME_OFFSET" ]]; then
                echo "-> Adding resume parameters to boot entry..."
                sudo sed -i "/^options / s|$| resume=/dev/mapper/cryptroot resume_offset=${RESUME_OFFSET}|" "$BOOT_ENTRY"
                echo "- resume=/dev/mapper/cryptroot resume_offset=${RESUME_OFFSET} added."
                echo "  NOTE: Run 'sudo mkinitcpio -P' and reboot before first hibernate."
            else
                echo "- WARNING: Could not determine swap file offset. Run 'sudo filefrag -v $SWAPFILE' manually."
            fi
        else
            echo "- Resume parameters already in boot entry."
        fi

        # Hibernate opt-in: configure lid close and flag file
        # Enable with: touch ~/.config/hypr/use-hibernate
        # Disable with: rm ~/.config/hypr/use-hibernate
        if [[ -f "$HOME/.config/hypr/use-hibernate" ]]; then
            if [[ ! -f /etc/systemd/logind.conf.d/lid-hibernate.conf ]]; then
                echo "-> Configuring lid close to hibernate (use-hibernate flag set)..."
                sudo mkdir -p /etc/systemd/logind.conf.d
                printf '[Login]\nHandleLidSwitch=hibernate\nHandleLidSwitchExternalPower=hibernate\nHandleLidSwitchDocked=ignore\n' \
                    | sudo tee /etc/systemd/logind.conf.d/lid-hibernate.conf > /dev/null
                echo "- Lid close set to hibernate."
            else
                echo "- Lid close hibernate already configured."
            fi
        else
            # Clean up hibernate lid config if flag was removed
            if [[ -f /etc/systemd/logind.conf.d/lid-hibernate.conf ]]; then
                echo "-> Removing hibernate lid config (use-hibernate flag not set)..."
                sudo rm /etc/systemd/logind.conf.d/lid-hibernate.conf
                echo "- Lid close reverted to default (suspend)."
            fi
            echo "- Hibernate not enabled (touch ~/.config/hypr/use-hibernate to enable)."
        fi
    else
        echo "- No LUKS + systemd-boot detected, skipping swap/hibernate setup."
    fi

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
    for target in kitty hypr wayle wlogout zed vim gammastep wofi gtk; do
        stow_target "$target"
    done
fi
popd > /dev/null

# Zen Browser: symlink theme into active profile (can't use stow — random profile dir)
# Zen manages its own chrome/ directory, so we symlink individual files into it.
# The workspace accent color lives in zen-sessions.jsonlz4 (binary), patched separately.
# Zen stores profiles in ~/.zen or ~/.config/zen depending on install method.
if [[ "$OS" == "Linux" ]]; then
    ZEN_DIR=""
    for candidate in "$HOME/.zen" "$HOME/.config/zen"; do
        if [[ -f "$candidate/profiles.ini" ]]; then
            ZEN_DIR="$candidate"
            break
        fi
    done
    ZEN_SRC="$DOTFILES_DIR/zen-browser"
    if [[ -n "$ZEN_DIR" ]]; then
        # Find the active profile — [Install*] Default= takes precedence
        ZEN_PROFILE_REL=$(awk -F= '/^\[Install/{inst=1} /^\[/{if(!/^\[Install/)inst=0} inst && /^Default=/{print $2; exit}' "$ZEN_DIR/profiles.ini")
        # Fallback: [Profile*] with Default=1
        if [[ -z "$ZEN_PROFILE_REL" ]]; then
            ZEN_PROFILE_REL=$(awk -F= '/^\[/{section=$0} /^Default=1/{found=section} /^Path=/{if(section==found) print $2}' "$ZEN_DIR/profiles.ini")
        fi
        if [[ -n "$ZEN_PROFILE_REL" ]]; then
            ZEN_PROFILE="$ZEN_DIR/$ZEN_PROFILE_REL"
            mkdir -p "$ZEN_PROFILE/chrome"
            # Symlink userChrome.css and userContent.css into existing chrome/ dir
            for cssfile in userChrome.css userContent.css; do
                if [[ -L "$ZEN_PROFILE/chrome/$cssfile" ]]; then
                    echo "- Zen Browser $cssfile already symlinked."
                else
                    ln -sf "$ZEN_SRC/chrome/$cssfile" "$ZEN_PROFILE/chrome/$cssfile"
                    echo "  Symlinked Zen Browser $cssfile."
                fi
            done
            # Symlink user.js
            if [[ -L "$ZEN_PROFILE/user.js" ]]; then
                echo "- Zen Browser user.js already symlinked."
            else
                ln -sf "$ZEN_SRC/user.js" "$ZEN_PROFILE/user.js"
                echo "  Symlinked Zen Browser user.js."
            fi
            # Patch workspace accent color to Arch Blue
            if [[ -f "$ZEN_PROFILE/zen-sessions.jsonlz4" ]]; then
                python3 "$ZEN_SRC/patch-zen-theme.py"
            else
                echo "- Zen Browser: no session file yet. Launch Zen, close it, and re-run setup.sh."
            fi
        else
            echo "- Zen Browser: no profile found in profiles.ini."
        fi
    else
        echo "- Zen Browser: not installed or no profile yet, skipping theme."
    fi
fi

# ── Desktop Theme (Linux) ────────────────────────────────────────────

if [[ "$OS" == "Linux" ]]; then
    echo -e "\n--- Desktop Theme ---"
    # Set dark mode preference for GTK apps via gsettings
    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
        gsettings set org.gnome.desktop.interface cursor-theme 'Phinger Cursors (light)'
        gsettings set org.gnome.desktop.interface cursor-size 32
        gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11'
        gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
        gsettings set org.gnome.desktop.interface font-hinting 'slight'
        echo "- Dark theme and font settings applied via gsettings."
    else
        echo "- gsettings not available, skipping desktop theme."
    fi
fi

# ── Available Upgrades (Linux) ────────────────────────────────────────

if [[ "$OS" == "Linux" ]]; then
    echo -e "\n--- Available Upgrades ---"
    AVAIL_UP_SRC="$REPO_DIR/bashrc/available-upgrades"

    echo "-> Linking available-upgrades.sh..."
    sudo ln -sf "$AVAIL_UP_SRC/available-upgrades.sh" /usr/local/bin/available-upgrades.sh
    echo "- available-upgrades.sh linked."

    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    for unit in available-upgrades.service available-upgrades.timer; do
        echo "-> Installing user unit $unit..."
        ln -sf "$AVAIL_UP_SRC/$unit" "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/$unit"
    done
    systemctl --user daemon-reload
    if ! systemctl --user is-enabled --quiet available-upgrades.timer 2>/dev/null; then
        systemctl --user enable --now available-upgrades.timer
        echo "- available-upgrades.timer enabled (user unit)."
    else
        echo "- available-upgrades.timer already enabled."
    fi
fi

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
