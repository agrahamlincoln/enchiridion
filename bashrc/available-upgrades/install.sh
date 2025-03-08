#!/bin/bash

# Script to install the available-upgrades systemd service and timer.

# --- Configuration ---
SERVICE_FILE="available-upgrades.service"
TIMER_FILE="available-upgrades.timer"
SCRIPT_FILE="available-upgrades.sh" # the name was changed in the .service file
SCRIPT_DESTINATION="/usr/local/bin/"
SYSTEMD_DESTINATION="/etc/systemd/system/"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_UPDATES_FILE="/tmp/available-upgrades"

# --- Functions ---
log_info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_success() {
  echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

log_error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1"
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (using sudo)."
    exit 1
  fi
}

install_file() {
  local source_file="$1"
  local destination_dir="$2"
  local destination_file="$3"
  local permissions="$4"

  log_info "Installing $source_file to $destination_dir"
  if [[ -f "$CURRENT_DIR/$source_file" ]]; then
    if [[ -f "$destination_dir/$destination_file" ]] && [[ "$destination_dir/$destination_file" -ef "$CURRENT_DIR/$source_file" ]]; then
      log_info "$destination_file is already installed and up to date."
    else
      cp "$CURRENT_DIR/$source_file" "$destination_dir/$destination_file"
      if [[ ! -z "$permissions" ]]; then
        chmod "$permissions" "$destination_dir/$destination_file"
      fi
      log_success "$destination_file installed successfully."
    fi
  else
    log_error "File $source_file not found in the current directory."
    exit 1
  fi
}

enable_timer() {
  local timer_name="$1"
  log_info "Enabling timer: $timer_name"
  systemctl enable "$timer_name" &>/dev/null
  if [[ $? -eq 0 ]]; then
    log_success "Timer $timer_name enabled successfully."
  else
    log_error "Failed to enable timer $timer_name."
    exit 1
  fi
}
start_timer() {
    local timer_name="$1"
    log_info "Starting timer: $timer_name"
    systemctl start "$timer_name" &>/dev/null
    if [[ $? -eq 0 ]]; then
        log_success "Timer $timer_name started successfully"
    else
        log_error "Failed to start timer $timer_name."
        exit 1
    fi
}

reload_systemd() {
  log_info "Reloading systemd daemon."
  systemctl daemon-reload &>/dev/null
  if [[ $? -eq 0 ]]; then
    log_success "systemd daemon reloaded."
  else
    log_error "Failed to reload systemd daemon."
    exit 1
  fi
}

check_file_readable() {
    if [[ -r "$1" ]]; then
        log_success "Temp updates file is readable"
    else
        log_error "Temp updates file is not readable"
        exit 1
    fi
}
# --- Main Script ---

check_root

log_info "Starting installation of available-upgrades..."

# Install service file
install_file "$SERVICE_FILE" "$SYSTEMD_DESTINATION" "$SERVICE_FILE" ""

# Install timer file
install_file "$TIMER_FILE" "$SYSTEMD_DESTINATION" "$TIMER_FILE" ""

# Install the script
install_file "$SCRIPT_FILE" "$SCRIPT_DESTINATION" "$SCRIPT_FILE" "0755"

touch "$TEMP_UPDATES_FILE"
chmod 600 "$TEMP_UPDATES_FILE"

# Reload systemd
reload_systemd

# Enable the timer
enable_timer "available-upgrades.timer"

#start the timer
start_timer "available-upgrades.timer"

# Check the tmp file is readable
log_info "Checking temp updates file is readable"

check_file_readable "$TEMP_UPDATES_FILE"

log_success "Installation of available-upgrades complete!"
log_info "You can check the status with:"
log_info "sudo systemctl status available-upgrades.timer"
log_info "sudo systemctl status available-upgrades.service"
log_info "Also run: /usr/local/bin/$SCRIPT_FILE"
