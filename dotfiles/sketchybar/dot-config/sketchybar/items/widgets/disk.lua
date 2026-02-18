local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local disk = sbar.add("item", "widgets.disk", {
  position = "right",
  padding_left = 2,
  padding_right = 2,
  update_freq = 300,
  icon = {
    string = icons.disk,
    color = colors.arch_text,
    font = { size = 12 },
    padding_left = 8,
    padding_right = 4,
  },
  label = {
    string = "0%",
    color = colors.arch_text,
    font = { family = settings.font.numbers, size = 12 },
    padding_left = 4,
    padding_right = 8,
  },
  background = {
    color = colors.arch_alt_bg,
    corner_radius = 10,
    height = 24,
    drawing = true,
    border_width = 0,
  },
})

disk:subscribe({ "routine", "system_woke" }, function()
  sbar.exec("df -H /System/Volumes/Data | awk 'NR==2 {print $5}'", function(result)
    local pct = tonumber(result:match("(%d+)")) or 0

    local color = colors.arch_text
    if pct >= 95 then
      color = colors.arch_urgent
    elseif pct >= 90 then
      color = colors.orange
    elseif pct >= 80 then
      color = colors.yellow
    end

    disk:set({
      icon = { color = color },
      label = {
        string = pct .. "%",
        color = color,
      },
    })
  end)
end)

-- Force initial update since update_freq=300 means a 5 min wait otherwise
sbar.exec("df -H /System/Volumes/Data | awk 'NR==2 {print $5}'", function(result)
  local pct = tonumber(result:match("(%d+)")) or 0
  disk:set({ label = { string = pct .. "%" } })
end)

disk:subscribe("mouse.clicked", function()
  sbar.exec("open x-apple.systempreferences:com.apple.settings.Storage")
end)

disk:subscribe("mouse.entered", function()
  sbar.animate("tanh", 10, function()
    disk:set({
      background = {
        color = colors.arch_blue,
        corner_radius = 10,
        height = 24,
        border_width = 0,
        drawing = true,
      },
    })
  end)
end)

disk:subscribe("mouse.exited", function()
  sbar.animate("tanh", 10, function()
    disk:set({
      background = {
        color = colors.arch_alt_bg,
        corner_radius = 10,
        height = 24,
        border_width = 0,
        drawing = true,
      },
    })
  end)
end)
