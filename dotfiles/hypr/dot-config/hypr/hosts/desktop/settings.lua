-- Desktop-specific Hyprland settings.
-- Optimized for desktop systems with larger screens and more power.

local host = require("hostenv")

-- Auto scaling for desktop monitors; monitor_scale is "auto" unless
-- hypr-scale.sh has persisted a computed scale.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = host.monitor_scale,
})

-- Desktop animations are inherited from hyprland.lua -- the defaults work well
-- here, so there is nothing to override.

hl.config({
    -- Desktop input settings (no touchpad configuration).
    input = {
        kb_layout  = "us",
        kb_variant = host.kb_variant,
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,
    },

    -- Larger gaps for desktop screens.
    general = {
        gaps_in  = 5,
        gaps_out = 20,

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

    -- Full visual effects for desktop.
    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(0a0a0abb)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },

        glow = {
            enabled        = true,
            range          = 8,
            render_power   = 3,
            color          = "rgba(1793d166)",   -- Arch blue, ~40% -- subtle active-window glow
            color_inactive = "rgba(00000000)",   -- no glow on inactive
        },
    },
})
