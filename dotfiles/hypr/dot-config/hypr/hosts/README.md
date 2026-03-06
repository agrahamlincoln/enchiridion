# Hyprland Host-Specific Configuration

This directory contains host-specific configurations for different device types (laptop vs desktop).

## Structure

```
hosts/
├── laptop/
│   ├── settings.conf   # Laptop-specific settings (touchpad, scaling, smaller gaps)
│   └── keybinds.conf   # QWERTY window-management keybinds
├── desktop/
│   ├── settings.conf   # Desktop-specific settings (full visual effects, larger gaps)
│   └── keybinds.conf   # Dvorak window-management keybinds
└── README.md          # This file
```

## How It Works

1. **Profile Selection**: `update-host-config.sh` reads `~/.config/hypr/host-type` to determine the device profile:
   - `laptop` → touchpad, smaller gaps, QWERTY window-management keybinds
   - `desktop` (default) → no touchpad, larger gaps, Dvorak window-management keybinds

2. **Configuration Generation**: The script generates two files in the main hypr directory:
   - `host-settings.conf` → Device-specific settings, input, monitor config
   - `host-keybinds.conf` → Layout-specific keybindings

3. **Auto-sourcing**: Main `hyprland.conf` sources these generated files

## Device Type Differences

### Laptop
- **Touchpad**: Full touchpad configuration with tap-to-click, natural scroll
- **Gaps**: Smaller gaps (3/15) for limited screen space
- **Visual Effects**: Slightly reduced for battery life (smaller blur, shadows)
- **WM Keybinds**: Mapped for QWERTY physical positions (Q, V keys)

### Desktop (default)
- **Input**: Keyboard-only, no touchpad config
- **Gaps**: Larger gaps (5/20) for bigger screens
- **Visual Effects**: Full effects for desktop experience
- **WM Keybinds**: Mapped for Dvorak physical positions (', . keys)

## Manual Updates

To change profile or force a configuration update:
```bash
echo "laptop" > ~/.config/hypr/host-type   # or "desktop"
~/.config/hypr/update-host-config.sh
hyprctl reload
```

## Adding New Host Types

1. Create a new directory under `hosts/` (e.g., `hosts/workstation/`)
2. Add `settings.conf` and `keybinds.conf` files
3. Write the type name to `~/.config/hypr/host-type`
4. Test with the update script

## Generated Files

These files are auto-generated and should not be edited manually:
- `host-settings.conf`
- `host-keybinds.conf`

They are also gitignored to prevent conflicts across different machines.