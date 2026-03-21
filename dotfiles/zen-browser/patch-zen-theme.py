#!/usr/bin/env python3
"""Patch Zen Browser workspace theme colors to Arch Blue.

Modifies zen-sessions.jsonlz4 in the active Zen profile to set all
workspace gradient colors to Arch Blue (#1793d1 / rgb(23, 147, 209)).

Zen must be closed before running this script — it overwrites the
session file on exit and would clobber our changes.

Usage: python3 patch-zen-theme.py
"""

import json
import sys
from pathlib import Path

try:
    import lz4.block
except ImportError:
    print("Error: python-lz4 not installed. Run: sudo pacman -S python-lz4")
    sys.exit(1)

ARCH_BLUE = [23, 147, 209]  # #1793d1
ZEN_DIR = Path.home() / ".config" / "zen"
MAGIC = b"mozLz40\0"


def find_active_profile():
    """Find the active Zen profile path from profiles.ini."""
    profiles_ini = ZEN_DIR / "profiles.ini"
    if not profiles_ini.exists():
        return None

    lines = profiles_ini.read_text().splitlines()
    # The [Install*] section's Default= is what Zen actually uses
    install_default = None
    in_install = False
    for line in lines:
        if line.startswith("[Install"):
            in_install = True
        elif line.startswith("["):
            in_install = False
        elif in_install and line.startswith("Default="):
            install_default = line.split("=", 1)[1]

    # Fallback to [Profile*] with Default=1
    if not install_default:
        current_section_path = None
        current_section_default = False
        for line in lines:
            if line.startswith("["):
                if current_section_default and current_section_path:
                    install_default = current_section_path
                    break
                current_section_path = None
                current_section_default = False
            elif line.startswith("Path="):
                current_section_path = line.split("=", 1)[1]
            elif line.startswith("Default=1"):
                current_section_default = True
        if current_section_default and current_section_path:
            install_default = current_section_path

    if install_default:
        return ZEN_DIR / install_default
    return None


def patch_session(profile_path):
    """Patch workspace gradient colors in zen-sessions.jsonlz4."""
    session_file = profile_path / "zen-sessions.jsonlz4"
    if not session_file.exists():
        print(f"No session file at {session_file} — launch Zen once first.")
        return False

    # Read and decompress
    raw = session_file.read_bytes()
    assert raw[:8] == MAGIC, f"Bad magic: {raw[:8]}"
    size = int.from_bytes(raw[8:12], "little")
    data = lz4.block.decompress(raw[12:], uncompressed_size=size)
    obj = json.loads(data)

    # Patch workspace colors
    patched = 0
    for space in obj.get("spaces", []):
        theme = space.get("theme", {})
        for color in theme.get("gradientColors", []):
            if color.get("c") != ARCH_BLUE:
                color["c"] = ARCH_BLUE
                color["isCustom"] = True
                patched += 1
        theme["texture"] = 0.0

    if patched == 0:
        print("All workspaces already use Arch Blue.")
        return True

    # Compress and write back
    out = json.dumps(obj).encode("utf-8")
    compressed = lz4.block.compress(out, store_size=False)
    with open(session_file, "wb") as f:
        f.write(MAGIC)
        f.write(len(out).to_bytes(4, "little"))
        f.write(compressed)

    print(f"Patched {patched} workspace color(s) to Arch Blue (#1793d1).")
    return True


def main():
    profile = find_active_profile()
    if not profile:
        print("No Zen Browser profile found — launch Zen once first.")
        sys.exit(1)

    if not profile.exists():
        print(f"Profile directory {profile} does not exist.")
        sys.exit(1)

    print(f"Profile: {profile.name}")
    patch_session(profile)


if __name__ == "__main__":
    main()
