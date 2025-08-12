# Hyprland Host-Specific Configuration

This directory contains host-specific configurations for different device types (laptop vs desktop).

## Structure

```
hosts/
├── laptop/
│   ├── settings.conf   # Laptop-specific settings (touchpad, scaling, smaller gaps)
│   └── keybinds.conf   # QWERTY keybindings for laptop
├── desktop/
│   ├── settings.conf   # Desktop-specific settings (full visual effects, larger gaps)
│   └── keybinds.conf   # Dvorak keybindings for desktop
└── README.md          # This file
```

## How It Works

1. **Host Detection**: `update-host-config.sh` detects the hostname and determines device type:
   - `zaxtec` → laptop (QWERTY)
   - All others → desktop (Dvorak)

2. **Configuration Generation**: The script generates two files in the main hypr directory:
   - `host-settings.conf` → Device-specific settings, input, monitor config
   - `host-keybinds.conf` → Layout-specific keybindings

3. **Auto-sourcing**: Main `hyprland.conf` sources these generated files

## Device Type Differences

### Laptop (zaxtec)
- **DPI Scaling**: 1.25x for smaller laptop screen
- **Touchpad**: Full touchpad configuration with tap-to-click, natural scroll
- **Gaps**: Smaller gaps (3/15) for limited screen space
- **Visual Effects**: Slightly reduced for battery life (smaller blur, shadows)
- **Keybindings**: QWERTY layout (Q, V keys in physical positions)

### Desktop (default)
- **DPI Scaling**: Auto-detect for desktop monitors
- **Input**: Keyboard-only, no touchpad config
- **Gaps**: Larger gaps (5/20) for bigger screens
- **Visual Effects**: Full effects for desktop experience
- **Keybindings**: Dvorak layout (', . keys in same physical positions)

## Manual Updates

To force a configuration update:
```bash
~/.config/hypr/update-host-config.sh
hyprctl reload
```

## Adding New Host Types

1. Create a new directory under `hosts/` (e.g., `hosts/workstation/`)
2. Add `settings.conf` and `keybinds.conf` files
3. Update `update-host-config.sh` to detect your hostname/type
4. Test with the update script

## Generated Files

These files are auto-generated and should not be edited manually:
- `host-settings.conf`
- `host-keybinds.conf`

They are also gitignored to prevent conflicts across different machines.