-- Dvorak window-management keybindings.
-- Mapped for Dvorak physical key positions.

local prog    = require("programs")
local mainMod = prog.mainMod

-- Window management - Dvorak layout
-- Q -> apostrophe in Dvorak, V -> period in Dvorak
hl.bind(mainMod .. " + SHIFT + apostrophe", hl.dsp.window.close())
hl.bind(mainMod .. " + period",             hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + period",     hl.dsp.window.pin())

-- File manager and menu - using Dvorak positions
-- T -> Y in Dvorak, D -> E in Dvorak
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd(prog.fileManager))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(prog.menu))

-- Window and layout management using natural Dvorak positions
-- (semicolon is in the same position on both layouts)
hl.bind(mainMod .. " + semicolon", hl.dsp.layout("togglesplit")) -- dwindle

-- Movement with arrow keys (universal)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move windows with arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Dvorak-optimized navigation using DHTN (equivalent to QWERTY's HJKL)
-- D = left, H = down, T = up, N = right
hl.bind(mainMod .. " + D", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + N", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + T", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "down" }))

-- Move windows with Dvorak navigation keys
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "down" }))
