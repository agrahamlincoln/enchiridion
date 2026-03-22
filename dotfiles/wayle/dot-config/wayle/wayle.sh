#!/usr/bin/env bash
# Wayle launcher — generates host-specific config and starts the desktop shell.
# Reads ~/.config/hypr/host-type (desktop/laptop) to apply overrides:
#   - Desktop: bar scale 1.0, no battery or backlight modules
#   - Laptop:  bar scale 0.8, all modules enabled (base config defaults)

LOGTAG="wayle"
WAYLE_DIR="$HOME/.config/wayle"
HOST_TYPE_FILE="$HOME/.config/hypr/host-type"

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
        thermometer bell bell-dot bell-off package hard-drive music cat 2>&1 | systemd-cat -t "$LOGTAG"
    wayle icons install tabler brand-vscode sword minus 2>&1 | systemd-cat -t "$LOGTAG"
    wayle icons install simple-icons discord steam firefox 2>&1 | systemd-cat -t "$LOGTAG"
fi

# --- Generate config.toml from base + host-type overrides ---

BASE_CONFIG="$WAYLE_DIR/config.base.toml"
CONFIG="$WAYLE_DIR/config.toml"

if [[ ! -f "$BASE_CONFIG" ]]; then
    log "ERROR: config.base.toml not found"
    exit 1
fi

# Read host type; default to desktop
if [[ -f "$HOST_TYPE_FILE" ]]; then
    HOST_TYPE="$(tr -d '[:space:]' < "$HOST_TYPE_FILE")"
else
    HOST_TYPE="desktop"
fi

log "Generating config for host type: $HOST_TYPE"
cp "$BASE_CONFIG" "$CONFIG"

if [[ "$HOST_TYPE" == "desktop" ]]; then
    # Desktop: larger bar scale, remove battery and backlight modules
    sed -i 's/^scale = 0\.8$/scale = 1.0/' "$CONFIG"
    sed -i 's/"battery", //' "$CONFIG"
    sed -i 's/"custom-backlight", //' "$CONFIG"
fi

log "Starting wayle-shell..."
exec wayle panel start 2>&1 | systemd-cat -t "$LOGTAG"
