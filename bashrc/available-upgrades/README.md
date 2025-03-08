# Available Upgrades Indicator

This project provides a simple way to fetch the number of available system upgrades somewhere (like on Waybar, or your terminal prompt) using a custom module. It utilizes a bash script to check for upgrades and a systemd timer and service to periodically update the information.

## How It Works

1.  **`available-upgrades.sh` Script:** This bash script is responsible for checking the number of available package upgrades using your system's package manager (e.g., `pacman` for Arch-based systems, `apt` for Debian/Ubuntu). It then outputs the count, which can be picked up by a status bar.
2.  **Systemd Service:** The `available-upgrades.service` file defines a systemd service that runs the `available-upgrades.sh` script.
3.  **Systemd Timer:** The `available-upgrades.timer` file defines a systemd timer that triggers the `available-upgrades.service` at regular intervals (e.g., every 30 minutes).

## Installation

Use the `install.sh` script in this directory to install (script is callable from anywhere)

```bash
sudo ./install.sh
```
