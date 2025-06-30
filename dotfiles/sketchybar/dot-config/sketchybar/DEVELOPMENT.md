# SketchyBar Development Guide

This guide documents the development workflow, common issues, and debugging techniques discovered while working with SketchyBar configuration.

## 🏗️ Development Workflow

### Quick Commands

```bash
# Restart SketchyBar (most common command)
brew services restart sketchybar

# Reload configuration without full restart
sketchybar --reload

# Check if SketchyBar is drawing
sketchybar --query bar | grep drawing

# Force enable drawing if it gets disabled
sketchybar --bar drawing=on

# Test a specific item
sketchybar --set clock label="TEST"

# List all current items
sketchybar --query bar | jq -r '.items[]'
```

### Using Zed Tasks

This directory includes `.zed/tasks.json` with predefined tasks accessible via `Cmd+Shift+P > Tasks: Spawn`:

- **Restart SketchyBar** - Full service restart
- **Check SketchyBar Status** - Query current bar state
- **Reload SketchyBar Config** - Reload without restart
- **Test SketchyBar Item** - Quick item test
- **Enable SketchyBar Drawing** - Force drawing on
- **List All SketchyBar Items** - Show current items
- **Validate Lua Syntax** - Check for syntax errors
- **Check SketchyBar Logs** - View recent logs
- **Backup Working Config** - Create timestamped backup
- **Build SketchyBar Helpers** - Compile helper binaries

## 🐛 Common Issues & Solutions

### 1. Empty SketchyBar (Most Common)

**Symptoms:**
- `"drawing": "off"` in query output
- `"items": []` (empty items array)
- No visible bar

**Causes & Solutions:**

1. **Lua Syntax Error in Any File**
   ```bash
   # Check syntax of all Lua files
   find . -name "*.lua" -exec lua -c "loadfile('{}')" \;
   ```

2. **Missing Color/Variable References**
   ```lua
   -- BAD: References non-existent color
   color = colors.nonexistent_color
   
   -- GOOD: Use existing colors or define first
   color = colors.white
   ```

3. **Broken Item Files**
   - Test by loading items one by one in `items/init.lua`
   - Comment out suspicious items to isolate the problem

4. **Helper Binary Issues**
   ```bash
   cd helpers && make
   ```

### 2. Configuration Not Loading

**Check Configuration Path:**
```bash
ls -la ~/.config/sketchybar/
# Should show symlinks to your dotfiles
```

**Verify SketchyBar is Using Correct Config:**
- SketchyBar looks for config in `$XDG_CONFIG_HOME/sketchybar` or `~/.config/sketchybar`
- Ensure proper symlinks exist

### 3. Items Not Updating

**Common Causes:**
- Event subscriptions not working
- Update frequencies set incorrectly
- Helper binaries not compiled
- Network/system permissions

**Debug Steps:**
```bash
# Check if item exists
sketchybar --query ITEM_NAME

# Manually trigger update
sketchybar --trigger EVENT_NAME

# Check system logs
log show --last 1m --predicate 'process == "sketchybar"' --style compact
```

## 📁 File Structure

```
sketchybar/
├── .zed/                    # Zed editor configuration
│   ├── tasks.json          # Development tasks
│   └── settings.json       # Lua-optimized settings
├── helpers/                # Compiled helper binaries
│   ├── event_providers/    # System monitoring tools
│   └── menus/              # Menu system
├── items/                  # SketchyBar items
│   ├── widgets/            # System widgets (volume, wifi, etc.)
│   └── *.lua              # Individual item configurations
├── bar.lua                 # Bar appearance settings
├── colors.lua              # Color palette
├── default.lua             # Default item settings
├── icons.lua               # Icon definitions
├── init.lua                # Main configuration entry point
├── settings.lua            # Global settings
└── sketchybarrc           # Shell script entry point
```

## 🎨 Color System

### Waybar-Inspired Colors
```lua
-- Added to colors.lua for waybar theme consistency
arch_blue = 0xff1793d1      -- Primary accent (waybar blue)
arch_mine_shaft = 0xff333333 -- Dark background
arch_text = 0xffffffff      -- Primary text
arch_alt_bg = 0xff444444    -- Secondary background
arch_urgent = 0xffff5555    -- Error/warning color
```

### Using Colors
```lua
local colors = require("colors")

-- Use waybar-inspired colors
background = { color = colors.arch_mine_shaft }
label = { color = colors.arch_text }

-- Or original colors for compatibility
background = { color = colors.bg1 }
label = { color = colors.white }
```

## 🔧 Safe Development Practices

### 1. Incremental Changes
- Make one small change at a time
- Test after each change
- Commit working states frequently

### 2. Backup Strategy
```bash
# Create timestamped backup before major changes
cp -r ~/.config/sketchybar ~/.config/sketchybar.backup.$(date +%Y%m%d_%H%M%S)
```

### 3. Testing New Items
```lua
-- In items/init.lua, add new items gradually
require("items.apple")      -- ✓ Test each
require("items.menus")      -- ✓ one by one
require("items.new_item")   -- ✓ New item
```

### 4. Error Isolation
If configuration breaks:
1. Check `sketchybar --query bar` for drawing status
2. Comment out recent changes in `items/init.lua`
3. Test items individually
4. Check Lua syntax with tasks or manual validation

## 📊 Monitoring & Debugging

### System Logs
```bash
# Recent SketchyBar logs
log show --last 5m --predicate 'process == "sketchybar"' --style compact

# Filter for errors only
log show --last 5m --predicate 'process == "sketchybar"' --style compact | grep -i error
```

### Configuration State
```bash
# Full bar configuration
sketchybar --query bar

# Specific item configuration
sketchybar --query ITEM_NAME

# All items summary
sketchybar --query default
```

## 🎯 Best Practices

### 1. Naming Conventions
- Items: `descriptive_name` (snake_case)
- Widgets: `widgets.category_name`
- Colors: `arch_*` for waybar theme, original names for compatibility

### 2. Error Handling
```lua
-- Safe color access
local color = colors.some_color or colors.white

-- Safe function calls
local success, result = pcall(function()
  -- potentially failing code
end)
```

### 3. Performance
- Use appropriate update frequencies
- Avoid complex computations in frequent updates
- Cache expensive operations

### 4. Documentation
- Comment complex color hex values
- Document item dependencies
- Note any system requirements

## 🔄 Git Workflow

### Commit Working States
```bash
# Before major changes
git add dotfiles/sketchybar/
git commit -m "sketchybar: working configuration before theme changes"

# After successful changes
git add dotfiles/sketchybar/
git commit -m "sketchybar: apply waybar-inspired theme to spaces"
```

### Reverting Changes
```bash
# Revert to last working commit
git checkout HEAD~1 -- dotfiles/sketchybar/

# Or restore from backup
cp -r ~/.config/sketchybar.backup.TIMESTAMP/* ~/.config/sketchybar/
```

---

## 📚 References

- [SketchyBar Documentation](https://felixkratz.github.io/SketchyBar/)
- [SketchyBar GitHub](https://github.com/FelixKratz/SketchyBar)
- [Lua 5.4 Reference](https://www.lua.org/manual/5.4/)