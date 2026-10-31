# Hyprland Host-Specific Configuration

This directory contains host-specific configurations split across two independent axes:
- **Host type** (desktop/laptop) — controls gaps, touchpad, visual effects
- **Keyboard layout** (dvorak/qwerty) — controls keybinds and `kb_variant`

## Structure

```
hosts/
├── desktop/
│   └── settings.lua    # Desktop-specific settings (full visual effects, larger gaps)
├── laptop/
│   └── settings.lua    # Laptop-specific settings (touchpad, smaller gaps, battery-friendly)
├── dvorak/
│   └── keybinds.lua    # Dvorak window-management keybinds (', . keys)
├── qwerty/
│   └── keybinds.lua    # QWERTY window-management keybinds (Q, V keys)
└── README.md
```

## How It Works

1. **Profile Selection**: `hostenv.lua` reads two files:
   - `~/.config/hypr/host-type` → `desktop` (default) or `laptop`
   - `~/.config/hypr/kb-layout` → `dvorak` (default) or `qwerty`

   An unknown value falls back to the default and logs a warning, so a typo
   degrades to a working config rather than an error.

2. **Direct require**: `hyprland.lua` requires `hosts.<type>.settings` and
   `hosts.<layout>.keybinds`. Hyprland puts the config directory on
   `package.path`, so these resolve to the files above.

3. **Shared values**: `hostenv.lua` also exposes `kb_variant` (derived from the
   layout) and `monitor_scale` (persisted by `hypr-scale.sh`), which the
   settings modules read. `programs.lua` holds the terminal/file manager/menu
   and the main modifier shared by the keybind modules.

There is **no generated file and no codegen step**.

## Current Machines

| Machine | Host type | Keyboard |
|---------|-----------|----------|
| plibter | desktop   | dvorak   |
| tomei   | laptop    | dvorak   |
| zaxtec  | laptop    | qwerty   |

## Manual Updates

To change profile:
```bash
echo "laptop" > ~/.config/hypr/host-type    # or "desktop"
echo "dvorak" > ~/.config/hypr/kb-layout    # or "qwerty"
hyprctl reload
```

`hyprctl reload` is enough — the Lua config re-reads both files on every load.
