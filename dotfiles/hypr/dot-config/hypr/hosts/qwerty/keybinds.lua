-- QWERTY window-management keybindings.
-- Mapped for QWERTY physical key positions.

local prog    = require("programs")
local mainMod = prog.mainMod

-- Window management - QWERTY layout
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + V",         hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.pin())

-- File manager and menu - using QWERTY positions
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(prog.fileManager))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(prog.menu))

-- Window and layout management using natural QWERTY positions
-- (avoiding J conflict with vim navigation)
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
