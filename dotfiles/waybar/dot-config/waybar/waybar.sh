#!/usr/bin/env bash

# Launcher for Waybar with automatic config reloading and Hyprland IPC watchdog.
# Selects config based on effective display width (resolution / scale):
#   < 2000px effective → compact (icon-only, values in tooltips)
#   >= 2000px effective → full (icons with text labels)
#
# Watchdog strategy:
#   - inotifywait on Hyprland runtime dir: catches Hyprland restarts, which
#     orphan waybar's IPC socket connections
#
# Logs: all output (including waybar's own stderr) is tagged to the systemd
# journal as 'waybar'. View with: journalctl -t waybar -f

# Redirect all stdout+stderr through systemd-cat so waybar.sh's own log()
# messages and waybar's [info]/[warning] lines both land in the journal.
exec > >(systemd-cat -t waybar --priority=info) 2>&1

COMPACT_THRESHOLD=2000
WAYBAR_DIR="$HOME/.config/waybar"

log() { echo "[waybar.sh] $*"; }

select_config() {
  if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "$WAYBAR_DIR/config.jsonc"
    return
  fi

  min_width=$(hyprctl monitors -j 2>/dev/null \
    | jq '[.[] | (.width / .scale)] | min | floor' 2>/dev/null)

  if [ -n "$min_width" ] && [ "$min_width" -lt "$COMPACT_THRESHOLD" ]; then
    echo "$WAYBAR_DIR/config-compact.jsonc"
  else
    echo "$WAYBAR_DIR/config.jsonc"
  fi
}

cleanup() {
  kill 0 2>/dev/null
  exit 0
}
trap cleanup INT TERM

# Terminate any already running instances
killall -q waybar
while pgrep -x waybar >/dev/null; do sleep 1; done

if command -v inotifywait >/dev/null 2>&1; then
  # Config file watcher: restart waybar when config or style changes.
  # Note: SIGUSR2 (in-place reload) crashes waybar 0.15.0 with a GLib D-Bus
  # assertion failure, so we do a full restart via the main loop instead.
  (
    while true; do
      config=$(select_config)
      inotifywait -qq -e create,modify "$config" "$WAYBAR_DIR/style.css" 2>/dev/null
      log "config change detected, restarting waybar"
      pkill -x waybar 2>/dev/null
    done
  ) &

  # Hyprland IPC watchdog: restart waybar when Hyprland's socket is recreated.
  # The socket path changes on each Hyprland start, leaving waybar's existing
  # IPC connections pointing at a defunct socket.
  (
    hypr_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"
    while true; do
      inotifywait -qq -e create,moved_to "$hypr_dir" 2>/dev/null || sleep 10
      log "Hyprland socket change detected, restarting waybar"
      sleep 2  # give Hyprland time to finish initialising
      pkill -x waybar 2>/dev/null
    done
  ) &
else
  log "Warning: inotify-tools not found. Config reloading and IPC watchdog disabled."
fi

# Main loop: run waybar, restart automatically if it exits for any reason
while true; do
  config=$(select_config)
  log "starting waybar with config: $config"
  waybar -c "$config" -s "$WAYBAR_DIR/style.css"
  log "waybar exited (code $?), restarting in 1s"
  sleep 1
done
