#!/usr/bin/env bash
# Wayle launcher — starts the desktop shell panel
# Mirrors waybar.sh's approach: kill existing, launch, log to journal

LOGTAG="wayle"

log() { echo "$1" | systemd-cat -t "$LOGTAG"; }

# Kill any existing wayle-shell instances
if pgrep -x wayle-shell >/dev/null; then
    log "Killing existing wayle-shell..."
    pkill -x wayle-shell
    sleep 0.5
fi

# Install icons if not present
ICON_DIR="$HOME/.local/share/wayle/icons"
if [[ ! -d "$ICON_DIR" ]] || [[ -z "$(ls -A "$ICON_DIR" 2>/dev/null)" ]]; then
    log "Installing wayle icons..."
    wayle icons setup 2>&1 | systemd-cat -t "$LOGTAG"

    # Install icon sets we need for workspace app icons and modules
    wayle icons install lucide terminal brain globe zap app-window sun monitor \
        thermometer bell bell-dot bell-off package 2>&1 | systemd-cat -t "$LOGTAG"
    wayle icons install tabler brand-vscode sword minus 2>&1 | systemd-cat -t "$LOGTAG"
    wayle icons install simple-icons discord steam firefox 2>&1 | systemd-cat -t "$LOGTAG"
fi

log "Starting wayle-shell..."
exec wayle panel start 2>&1 | systemd-cat -t "$LOGTAG"
