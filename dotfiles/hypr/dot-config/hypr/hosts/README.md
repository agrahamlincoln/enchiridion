# Hyprland Host-Specific Configuration

This directory contains host-specific configurations split across two independent axes:
- **Host type** (desktop/laptop) — controls gaps, touchpad, visual effects
- **Keyboard layout** (dvorak/qwerty) — controls keybinds and `kb_variant`

## Structure

```
hosts/
├── desktop/
│   └── settings.conf   # Desktop-specific settings (full visual effects, larger gaps)
├── laptop/
│   └── settings.conf   # Laptop-specific settings (touchpad, smaller gaps, battery-friendly)
├── dvorak/
│   └── keybinds.conf   # Dvorak window-management keybinds (', . keys)
├── qwerty/
│   └── keybinds.conf   # QWERTY window-management keybinds (Q, V keys)
└── README.md
```

## How It Works

1. **Profile Selection**: `update-host-config.sh` reads two files:
   - `~/.config/hypr/host-type` → `desktop` (default) or `laptop`
   - `~/.config/hypr/kb-layout` → `dvorak` (default) or `qwerty`

2. **Configuration Generation**: The script generates two files in the main hypr directory:
   - `host-settings.conf` → Device-specific settings with `kb_variant` patched from kb-layout
   - `host-keybinds.conf` → Layout-specific keybindings

3. **Auto-sourcing**: Main `hyprland.conf` sources these generated files

## Current Machines

| Machine | Host type | Keyboard |
|---------|-----------|----------|
| plibter | desktop   | dvorak   |
| tomei   | laptop    | dvorak   |
| zaxtec  | laptop    | qwerty   |

## Manual Updates

To change profile or force a configuration update:
```bash
echo "laptop" > ~/.config/hypr/host-type    # or "desktop"
echo "dvorak" > ~/.config/hypr/kb-layout    # or "qwerty"
~/.config/hypr/update-host-config.sh
hyprctl reload
```

## Generated Files

These files are auto-generated and should not be edited manually:
- `host-settings.conf`
- `host-keybinds.conf`

They are also gitignored to prevent conflicts across different machines.
