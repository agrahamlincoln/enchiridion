# Available Upgrades Indicator

Displays the number of pending package upgrades in the Wayle status bar. Uses `checkupdates` (pacman-contrib) for official repo packages and `paru -Qua` for AUR packages.

## How It Works

1. **`available-upgrades.sh --update`** — Syncs a temporary pacman database via `checkupdates`, queries AUR via `paru`, and writes the combined list to `~/.cache/available-upgrades/packages`.
2. **`available-upgrades.sh`** (no flag) — Returns exit 0 if the packages file is non-empty, exit 1 otherwise. Used by the Wayle widget to gate display.
3. **Systemd user timer** — Runs `--update` every 5 minutes (first run 15 minutes after boot).
4. **Wayle custom module** — Polls the packages file every 60 seconds and displays the line count. Hidden when no updates are available.

## Dependencies

- `pacman-contrib` (provides `checkupdates`)
- `paru` (AUR helper)

Both are listed in `packages/arch-pacman.txt` and `packages/arch-aur.txt` respectively.

## Installation

Handled automatically by `setup.sh`, which symlinks the script to `/usr/local/bin/` and installs the systemd user units.

## Migrating from System Units

Machines with the old root-owned system unit setup need manual cleanup before running `setup.sh`:

```bash
# Remove old system units
sudo systemctl disable --now available-upgrades.timer
sudo rm -f /etc/systemd/system/available-upgrades.{service,timer}
sudo systemctl daemon-reload

# Remove old data directory (now uses ~/.cache/available-upgrades/)
sudo rm -rf /var/lib/available-upgrades

# Replace old copied script with symlink
sudo ln -sf ~/projects/enchiridion/bashrc/available-upgrades/available-upgrades.sh /usr/local/bin/available-upgrades.sh

# Install checkupdates dependency
sudo pacman -S pacman-contrib

# setup.sh handles the rest (user units, enabling timer)
./setup.sh
```
