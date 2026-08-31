-- Laptop-specific Hyprland settings.
-- Optimized for portable devices with touchpad and smaller screens.

local host = require("hostenv")

-- monitor_scale is "auto" unless hypr-scale.sh has persisted a DPI-derived
-- scale for this display.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = host.monitor_scale,
})

hl.config({
    -- Laptop-specific input settings.
    input = {
        kb_layout  = "us",
        kb_variant = host.kb_variant,
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll       = true,
            clickfinger_behavior = true,
            tap_to_click         = true,
            disable_while_typing = true,
            scroll_factor        = 1,
        },
    },

    -- Slightly smaller gaps for laptop screens.
    general = {
        gaps_in  = 2,   -- Reduced from 5
        gaps_out = 5,   -- Reduced from 20

        border_size = 2,

        -- Arch Linux Color Theme
        col = {
            active_border   = "rgb(1793d1)",
            inactive_border = "rgb(333333)",
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    -- Slightly reduced visual effects for better battery life.
    decoration = {
        rounding       = 8,   -- Reduced from 10
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 3,   -- Reduced from 4
            render_power = 2,   -- Reduced from 3
            color        = "rgba(0a0a0abb)",
        },

        blur = {
            enabled  = true,
            size     = 2,       -- Reduced from 3
            passes   = 1,
            vibrancy = 0.1696,
        },

        glow = {
            enabled        = true,
            range          = 6,                  -- Reduced from 8 (desktop) for battery
            render_power   = 3,
            color          = "rgba(1793d166)",   -- Arch blue, ~40% -- subtle active-window glow
            color_inactive = "rgba(00000000)",   -- no glow on inactive
        },
    },
})

-- Kitty scrolls too slowly on the touchpad at its default rate.
hl.window_rule({
    name  = "kitty-touchpad-scroll",
    match = { class = "^(kitty)$" },

    scroll_touchpad = 8,
})

-- Workspace swipe gesture for the laptop touchpad.
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
