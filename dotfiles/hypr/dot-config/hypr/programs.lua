-- Programs and the main modifier, shared between hyprland.lua and the
-- per-layout keybind modules.
--
-- These were $terminal/$fileManager/$menu/$mainMod variables under hyprlang.
-- Lua locals do not cross a require() boundary, so they live in a module that
-- both the main config and hosts/<layout>/keybinds.lua pull in.

return {
    mainMod     = "SUPER",
    terminal    = "kitty",
    fileManager = "thunar",
    menu        = "wofi --show drun",
}
