local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "cpu_update" for
-- the cpu load data, which is fired every 2.0 seconds.
sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

local cpu = sbar.add("item", "widgets.cpu", {
  position = "right",
  padding_left = 8,
  padding_right = 8,
  icon = {
    string = icons.cpu,
    color = colors.arch_text,
    font = { size = 14 },
    padding_right = 6,
  },
  label = {
    string = "CPU 0%",
    color = colors.arch_text,
    font = { family = settings.font.numbers, size = 12 },
  },
  background = {
    color = colors.arch_alt_bg,
    corner_radius = 10,
    height = 24,
  },
})

cpu:subscribe("cpu_update", function(env)
  local load = tonumber(env.total_load)

  local color = colors.arch_text
  if load > 30 then
    if load < 60 then
      color = colors.yellow
    elseif load < 80 then
      color = colors.orange
    else
      color = colors.arch_urgent
    end
  end

  cpu:set({
    icon = { color = color },
    label = {
      string = "CPU " .. env.total_load .. "%",
      color = color
    }
  })
end)

-- Add spacing after cpu pill
sbar.add("item", "widgets.cpu.padding", {
  position = "right",
  width = 6,
})

-- Mouse interactions
cpu:subscribe("mouse.clicked", function(env)
  sbar.exec("open -a 'Activity Monitor'")
end)

-- Hover effects
cpu:subscribe("mouse.entered", function()
  cpu:set({
    background = {
      color = colors.with_alpha(colors.arch_blue, 0.3)
    }
  })
end)

cpu:subscribe("mouse.exited", function()
  cpu:set({
    background = {
      color = colors.arch_alt_bg
    }
  })
end)
