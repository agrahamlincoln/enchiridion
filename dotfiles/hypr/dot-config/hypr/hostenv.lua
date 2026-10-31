-- Host configuration axes, read once and shared between hyprland.lua and the
-- host modules it require()s.
--
-- The config reads host-type and kb-layout directly at load time, so there is
-- no generated file that can drift from its sources.

local M = {}

local CONFIG_DIR = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")) .. "/hypr"

--- Read a single whitespace-delimited token from a file in ~/.config/hypr.
--- @param name string file name, e.g. "host-type"
--- @param default string value used when the file is absent, empty, or blank
--- @return string
local function readToken(name, default)
    local handle = io.open(CONFIG_DIR .. "/" .. name, "r")
    if not handle then
        return default
    end

    local line = handle:read("l")
    handle:close()

    local token = line and line:match("^%s*(%S+)")
    if token == nil or token == "" then
        return default
    end

    return token
end

--- Fall back to `default` when hosts/<value>/<module>.lua does not exist.
--- Mirrors the directory check the old shell script did, so a typo in
--- host-type or kb-layout degrades to a working config instead of erroring.
--- @param value string the requested profile name
--- @param module string the module the profile must provide ("settings"/"keybinds")
--- @param default string profile to fall back to
--- @return string
local function validated(value, module, default)
    local handle = io.open(string.format("%s/hosts/%s/%s.lua", CONFIG_DIR, value, module), "r")
    if handle then
        handle:close()
        return value
    end

    print(string.format("hostenv: unknown profile '%s' for %s, falling back to '%s'", value, module, default))
    return default
end

M.host_type = validated(readToken("host-type", "desktop"), "settings", "desktop")
M.kb_layout = validated(readToken("kb-layout", "dvorak"), "keybinds", "dvorak")

-- Written by hypr-scale.sh so a chosen scale survives a config reload.
M.monitor_scale = readToken("monitor-scale", "auto")

--- True when a flag file exists in ~/.config/hypr.
--- @param name string flag file name
--- @return boolean
local function flag(name)
    local handle = io.open(CONFIG_DIR .. "/" .. name, "r")
    if not handle then
        return false
    end

    handle:close()
    return true
end

-- Per-host opt-in, matching the flag autoclick.sh and setup.sh check. Gates the
-- keybind too, so Pause stays an ordinary key where the feature is off.
M.autoclick = flag("autoclick-enabled")

-- Only Dvorak needs an XKB variant; QWERTY is the bare "us" layout.
M.kb_variant = M.kb_layout == "dvorak" and "dvorak" or ""

return M
