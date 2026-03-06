#!/usr/bin/env bash
# Build a custom Arch Linux ISO with the enchiridion installer embedded.
#
# Prerequisites: sudo pacman -S --needed archiso edk2-ovmf qemu-desktop
#
# Usage:
#   ./archiso/build.sh          # Build the ISO
#   ./archiso/build.sh flash    # Build and write to /dev/sda
#   ./archiso/build.sh test     # Build (if needed) and test in QEMU
#   ./archiso/build.sh clean    # Remove scaffolded releng files and work dir

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="/tmp/archiso-work"
OUT_DIR="$SCRIPT_DIR/out"
RELENG="/usr/share/archiso/configs/releng"

# ── Scaffold releng base files ───────────────────────────────────────

# Copy stock releng profile files that we don't customize.
# These are not checked into git because they come from the archiso package
# and should match the installed version. Our custom files (motd, vconsole.conf,
# install-enchiridion) are committed directly in airootfs/ and take priority
# via rsync --ignore-existing.
scaffold_releng() {
    if [[ ! -d "$RELENG" ]]; then
        echo "ERROR: releng profile not found at $RELENG"
        echo "Install archiso first: sudo pacman -S --needed archiso"
        exit 1
    fi

    local changed=false

    # Copy top-level files/dirs that we don't customize
    for item in efiboot grub syslinux pacman.conf bootstrap_packages; do
        if [[ ! -e "$SCRIPT_DIR/$item" ]]; then
            cp -r "$RELENG/$item" "$SCRIPT_DIR/$item"
            echo "  Copied $item"
            changed=true
        fi
    done

    # Merge stock airootfs with our custom overlay (our files take priority)
    if [[ -d "$RELENG/airootfs" ]]; then
        rsync -a --ignore-existing "$RELENG/airootfs/" "$SCRIPT_DIR/airootfs/"
        # Fix ownership so committed files stay editable without sudo
        if [[ -n "${SUDO_USER:-}" ]]; then
            chown -R "$SUDO_USER:$SUDO_USER" "$SCRIPT_DIR/airootfs"
        fi
        changed=true
    fi

    # Build packages.x86_64 from releng base + our additions
    if [[ ! -f "$SCRIPT_DIR/packages.x86_64" ]]; then
        cp "$RELENG/packages.x86_64" "$SCRIPT_DIR/packages.x86_64"
        if ! grep -q '^git$' "$SCRIPT_DIR/packages.x86_64"; then
            echo "" >> "$SCRIPT_DIR/packages.x86_64"
            echo "# Enchiridion additions for the live environment" >> "$SCRIPT_DIR/packages.x86_64"
            echo "git" >> "$SCRIPT_DIR/packages.x86_64"
        fi
        echo "  Created packages.x86_64 with git appended"
        changed=true
    fi

    # Build profiledef.sh from releng base with our overrides
    if [[ ! -f "$SCRIPT_DIR/profiledef.sh" ]]; then
        cp "$RELENG/profiledef.sh" "$SCRIPT_DIR/profiledef.sh"
        sed -i 's/^iso_name=.*/iso_name="enchiridion"/' "$SCRIPT_DIR/profiledef.sh"
        sed -i 's/^iso_label=.*/iso_label="ENCHIRIDION"/' "$SCRIPT_DIR/profiledef.sh"
        if ! grep -q 'install-enchiridion' "$SCRIPT_DIR/profiledef.sh"; then
            sed -i '/^file_permissions=(/a\  ["/usr/local/bin/install-enchiridion"]="0:0:755"' "$SCRIPT_DIR/profiledef.sh"
        fi
        echo "  Created profiledef.sh"
        changed=true
    fi

    if $changed; then
        echo "Scaffolding complete."
    fi
}

# ── Build ────────────────────────────────────────────────────────────

build_iso() {
    # Skip rebuild if an ISO already exists and no source files have changed
    local latest_iso
    latest_iso="$(ls -t "$OUT_DIR"/enchiridion-*.iso 2>/dev/null | head -1)" || true
    local installer="$SCRIPT_DIR/airootfs/usr/local/bin/install-enchiridion"
    if [[ -n "$latest_iso" && -f "$installer" && "$latest_iso" -nt "$installer" ]]; then
        echo "ISO is up to date: $latest_iso"
        echo "  Run './archiso/build.sh clean' first to force a rebuild."
        return
    fi

    echo ""
    echo "Building ISO..."
    echo "  Profile: $SCRIPT_DIR"
    echo "  Work:    $WORK_DIR"
    echo "  Output:  $OUT_DIR"
    echo ""

    sudo rm -rf "$WORK_DIR"
    mkdir -p "$OUT_DIR"

    sudo mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$SCRIPT_DIR"

    echo ""
    echo "Build complete. ISO:"
    ls -lh "$OUT_DIR"/enchiridion-*.iso
}

# ── Flash to USB ─────────────────────────────────────────────────────

flash_usb() {
    local iso
    iso="$(ls -t "$OUT_DIR"/enchiridion-*.iso 2>/dev/null | head -1)"
    if [[ -z "$iso" ]]; then
        echo "ERROR: No ISO found in $OUT_DIR. Build first."
        exit 1
    fi

    echo ""
    echo "Target device: /dev/sda"
    lsblk -o NAME,SIZE,MODEL,VENDOR,TYPE,FSTYPE,LABEL,MOUNTPOINTS /dev/sda 2>/dev/null || true
    echo ""
    echo "ISO: $iso ($(du -h "$iso" | cut -f1))"
    echo ""
    echo "WARNING: This will overwrite ALL data on /dev/sda."
    read -rp "Type YES to confirm: " confirm
    if [[ "$confirm" != "YES" ]]; then
        echo "Aborted."
        exit 1
    fi

    sudo dd bs=4M if="$iso" of=/dev/sda conv=fsync oflag=direct status=progress
    sync
    echo "Flash complete."
}

# ── Test in QEMU ─────────────────────────────────────────────────────

test_qemu() {
    local iso
    iso="$(ls -t "$OUT_DIR"/enchiridion-*.iso 2>/dev/null | head -1)"
    if [[ -z "$iso" ]]; then
        echo "ERROR: No ISO found in $OUT_DIR. Build first."
        exit 1
    fi

    local ovmf_code="/usr/share/edk2/x64/OVMF_CODE.4m.fd"
    local ovmf_vars="/usr/share/edk2/x64/OVMF_VARS.4m.fd"
    if [[ ! -f "$ovmf_code" ]]; then
        echo "ERROR: OVMF not found. Install it: sudo pacman -S edk2-ovmf"
        exit 1
    fi

    # Create a writable copy of OVMF_VARS and a virtual disk for the install target.
    # If running under sudo, fix ownership so QEMU (dropped to real user) can access them.
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    cp "$ovmf_vars" "$tmp_dir/OVMF_VARS.4m.fd"

    local disk="$tmp_dir/disk.qcow2"
    qemu-img create -f qcow2 "$disk" 20G

    if [[ -n "${SUDO_USER:-}" ]]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$tmp_dir"
    fi

    echo "Launching ISO in QEMU..."
    echo "  Temp dir: $tmp_dir"

    local qemu_cmd=(
        qemu-system-x86_64
        -enable-kvm
        -m 4G
        -boot d
        -cdrom "$iso"
        -drive "file=$disk,format=qcow2,if=virtio"
        -drive "if=pflash,format=raw,readonly=on,file=$ovmf_code"
        -drive "if=pflash,format=raw,file=$tmp_dir/OVMF_VARS.4m.fd"
        -device virtio-net-pci,netdev=net0
        -netdev user,id=net0
        -display gtk
        -vga virtio
    )

    if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]]; then
        runuser -u "$SUDO_USER" -- "${qemu_cmd[@]}"
    else
        "${qemu_cmd[@]}"
    fi

    rm -rf "$tmp_dir"
}

# ── Clean ────────────────────────────────────────────────────────────

clean() {
    echo "Cleaning scaffolded releng files and build artifacts..."
    # Top-level scaffolded files
    rm -rf "$SCRIPT_DIR"/{efiboot,grub,syslinux,pacman.conf,bootstrap_packages,packages.x86_64,profiledef.sh}
    # Scaffolded airootfs files (preserve our committed customizations)
    rm -f "$SCRIPT_DIR"/airootfs/root/{.automated_script.sh,.zlogin}
    rm -rf "$SCRIPT_DIR"/airootfs/root/.gnupg
    rm -f "$SCRIPT_DIR"/airootfs/usr/local/bin/{choose-mirror,Installation_guide,livecd-sound}
    rm -rf "$SCRIPT_DIR"/airootfs/usr/local/share
    # Scaffolded etc files (preserve motd and vconsole.conf)
    find "$SCRIPT_DIR/airootfs/etc" -mindepth 1 \
        ! -name motd ! -name vconsole.conf \
        -delete 2>/dev/null || true
    # Build output
    rm -rf "$OUT_DIR"
    sudo rm -rf "$WORK_DIR"
    echo "Clean."
}

# ── Main ─────────────────────────────────────────────────────────────

scaffold_releng

case "${1:-build}" in
    build)
        build_iso
        ;;
    flash)
        build_iso
        flash_usb
        ;;
    test)
        build_iso
        test_qemu
        ;;
    clean)
        clean
        ;;
    *)
        echo "Usage: $0 [build|flash|test|clean]"
        exit 1
        ;;
esac
