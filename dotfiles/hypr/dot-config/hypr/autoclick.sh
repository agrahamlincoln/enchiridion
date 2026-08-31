#!/usr/bin/env bash
# Starts ydotoold (which owns the /dev/uinput device clicks are injected
# through) and hands off to autoclick.py. Run from hyprland.lua's startup hook.

set -euo pipefail

# Opt-in per host (same pattern as tap-indicator.sh): the feature needs evdev
# read access to every input device, so hosts that won't use it shouldn't carry
# that. Enable with `touch ~/.config/hypr/autoclick-enabled && ./setup.sh`.
[[ -f "$HOME/.config/hypr/autoclick-enabled" ]] || exit 0

if ! command -v ydotoold > /dev/null; then
    notify-send -a "Autoclick" "ydotool is not installed" "Run setup.sh to install it" || true
    exit 1
fi

SOCKET="${XDG_RUNTIME_DIR:-/tmp}/.ydotool_socket"
export YDOTOOL_SOCKET="$SOCKET"

if ! pgrep -u "$UID" -x ydotoold > /dev/null; then
    ydotoold --socket-path="$SOCKET" &
    # Poll rather than sleep a fixed amount: usually ready in well under 100ms,
    # but slower on a cold boot when it contends with the rest of startup.
    for _ in $(seq 1 50); do
        [[ -S "$SOCKET" ]] && break
        sleep 0.1
    done
fi

if [[ ! -S "$SOCKET" ]]; then
    notify-send -a "Autoclick" "ydotoold failed to start" "No socket at $SOCKET" || true
    exit 1
fi

# Resolve through the stow symlink so this works from ~/.config or the repo.
exec "$(dirname "$(readlink -f "$0")")/autoclick.py"
