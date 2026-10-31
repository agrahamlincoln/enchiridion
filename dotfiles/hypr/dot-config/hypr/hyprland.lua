-- Main Hyprland configuration.
--
-- Refer to the wiki for more information:
-- https://wiki.hypr.land/Configuring/Start/
--
-- Host-specific settings and keybinds are require()d from hosts/<profile>/
-- based on ~/.config/hypr/host-type and ~/.config/hypr/kb-layout. See
-- hostenv.lua -- there is no generated host-*.conf step any more.

local host = require("hostenv")
local prog = require("programs")

local mainMod = prog.mainMod

hl.config({
    debug = {
        disable_logs = false,
    },
})

-- MONITORS are configured by the host profile (hosts/<type>/settings.lua),
-- since scaling differs between the desktop and laptop displays.

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Export session env to systemd/D-Bus, then bring up the graphical session
    -- target. That activates graphical-session.target, which
    -- xdg-desktop-portal.service requires (Requisite=) before it will start.
    -- Without it the ScreenCast portal never runs and screen sharing silently
    -- fails in Discord and other apps. See hyprland-session.target.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user start hyprland-session.target")

    -- Blue-light filter daemon. Starts as a no-op; toggled manually via Wayle.
    hl.exec_cmd("hyprsunset --identity")
    hl.exec_cmd("~/.config/wayle/wayle.sh")
    -- Requires phinger cursors (paru -S phinger-cursors).
    hl.exec_cmd([[hyprctl setcursor "Phinger Cursors (light)" 32]])
    -- Wallpaper daemon; cycles ~/Images/Wallpapers (see ~/.config/wpaperd/config.toml).
    hl.exec_cmd("wpaperd")
    hl.exec_cmd("hypridle")
    -- Touchpad tap visual feedback (opt-in: touch ~/.config/hypr/tap-indicator-enabled).
    hl.exec_cmd("~/.config/hypr/tap-indicator.sh")
    -- Hold-to-autoclick daemon (opt-in: touch ~/.config/hypr/autoclick-enabled).
    hl.exec_cmd("~/.config/hypr/autoclick.sh")
    -- DPI-based monitor scaling. This config applies the host settings and
    -- keybinds itself, so the script only handles scaling now.
    hl.exec_cmd("~/.config/hypr/apply-scale.sh")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "32")
hl.env("HYPRCURSOR_SIZE", "32")

-- Dark theme for GTK/QT apps.
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Host-specific settings (laptop vs desktop): monitors, input, gaps,
-- decoration and visual effects.
require("hosts." .. host.host_type .. ".settings")

hl.config({
    animations = {
        enabled = true,
    },
})

-- Default animations, shared by both host types.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,     -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

---------------------
---- KEYBINDINGS ----
---------------------

-- Base keybindings that work on any keyboard layout. These use keys that sit in
-- the same position on QWERTY and Dvorak; layout-dependent binds live in
-- hosts/<layout>/keybinds.lua.

local wlogout = "wlogout -b 5 -c 10 -T 400 -B 400 -L 150 -R 150"

-- Core application shortcuts
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(prog.terminal))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd(wlogout))
hl.bind("XF86PowerOff", hl.dsp.exec_cmd(wlogout))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Numbers are in the same position on both layouts.
-- Switch workspaces with mainMod + [0-9], move the active window with + SHIFT.
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Screenshotting
-- Print         = area select -> clipboard
-- Super+Print   = full screen -> file + clipboard
-- Super+S+Print = area select -> file + clipboard
hl.bind("Print", hl.dsp.exec_cmd(
    [[grim -g "$(slurp)" - | wl-copy && notify-send -a "Screenshot" "Area copied to clipboard"]]))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(
    [[bash -c 'f=~/Pictures/$(date +%Y-%m-%d_%H-%M-%S).png && mkdir -p ~/Pictures && grim "$f" && wl-copy < "$f" && notify-send -a "Screenshot" "Saved & copied" "$f"']]))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd(
    [[bash -c 'f=~/Pictures/$(date +%Y-%m-%d_%H-%M-%S).png && mkdir -p ~/Pictures && grim -g "$(slurp)" "$f" && wl-copy < "$f" && notify-send -a "Screenshot" "Area saved & copied" "$f"']]))

-- Screen locking
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("loginctl lock-session"))

-- Re-apply DPI scaling and reload. The host profile is picked up by the reload
-- itself, since this config reads host-type/kb-layout on every load.
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("~/.config/hypr/apply-scale.sh && hyprctl reload"))

-- Mouse bindings
-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),   { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),{ locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"),                        { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"),                        { locked = true, repeating = true })

-- Media controls (requires playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Discord push to talk global keybind
hl.bind("mouse:276", hl.dsp.pass({ window = "class:^(discord)$" }))

-- AUTOCLICK: hold Pause to repeat left-click. The clicking is driven by
-- autoclick.py off evdev, not from here -- see dotfiles/hypr/CLAUDE.md for why a
-- bind/bindr pair can't do it. This bind only swallows the key so games don't
-- see Pause; the daemon still observes it. Skipped where the feature is off, so
-- Pause reaches applications normally.
-- no_op rather than exec_cmd("true"): the bind exists purely to consume the
-- key, and no_op does that without forking a shell on every press.
if host.autoclick then
    hl.bind("Pause", hl.dsp.no_op(), { ignore_mods = true })
end

-- Layout-specific window-management keybinds (set by the kb-layout profile).
require("hosts." .. host.kb_layout .. ".keybinds")

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Steam's hidden zero-size helper window steals focus on launch unless it is
-- kept focused and given a non-zero minimum size.
hl.window_rule({
    name  = "steam-focus-fix",
    match = { title = "^()$", class = "^(steam)$" },

    stay_focused = true,
    min_size     = "1 1",
})
