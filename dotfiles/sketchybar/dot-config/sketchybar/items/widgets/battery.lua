local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local battery = sbar.add("item", "widgets.battery", {
  position = "right",
  padding_left = 12,
  padding_right = 12,
  icon = {
    font = { size = 14 },
    color = colors.arch_text,
    padding_left = 8,
    padding_right = 8,
  },
  label = {
    font = { family = settings.font.numbers, size = 12 },
    color = colors.arch_text,
    padding_left = 8,
    padding_right = 8,
  },
  background = {
    color = colors.arch_alt_bg,
    corner_radius = 10,
    height = 24,
  },
  update_freq = 180,
  popup = { align = "center" }
})

local remaining_time = sbar.add("item", {
  position = "popup." .. battery.name,
  icon = {
    string = "Time remaining:",
    width = 100,
    align = "left",
    color = colors.arch_text,
  },
  label = {
    string = "??:??h",
    width = 100,
    align = "right",
    color = colors.arch_text,
  },
  background = {
    color = colors.arch_mine_shaft,
    corner_radius = 8,
    height = 30,
    border_width = 1,
    border_color = colors.arch_alt_bg,
  }
})


battery:subscribe({"routine", "power_source_change", "system_woke"}, function()
  sbar.exec("pmset -g batt", function(batt_info)
    local icon = "!"
    local label = "?"

    local found, _, charge = batt_info:find("(%d+)%%")
    if found then
      charge = tonumber(charge)
      label = charge .. "%"
    end

    local color = colors.arch_text
    local charging, _, _ = batt_info:find("AC Power")

    if charging then
      icon = icons.battery.charging
    else
      if found and charge > 80 then
        icon = icons.battery._100
      elseif found and charge > 60 then
        icon = icons.battery._75
      elseif found and charge > 40 then
        icon = icons.battery._50
      elseif found and charge > 20 then
        icon = icons.battery._25
        color = colors.orange
      else
        icon = icons.battery._0
        color = colors.arch_urgent
      end
    end

    local lead = ""
    if found and charge < 10 then
      lead = "0"
    end

    battery:set({
      icon = {
        string = icon,
        color = color
      },
      label = {
        string = lead .. label,
        color = color
      },
    })
  end)
end)

battery:subscribe("mouse.clicked", function(env)
  local drawing = battery:query().popup.drawing
  battery:set( { popup = { drawing = "toggle" } })

  if drawing == "off" then
    sbar.exec("pmset -g batt", function(batt_info)
      local found, _, remaining = batt_info:find(" (%d+:%d+) remaining")
      local label = found and remaining .. "h" or "No estimate"
      remaining_time:set( { label = label })
    end)
  end
end)

-- Add spacing after battery pill
sbar.add("item", "widgets.battery.padding", {
  position = "right",
  width = 6,
})

-- Hover effects with smooth animations
battery:subscribe("mouse.entered", function()
  sbar.animate("tanh", 10, function()
    battery:set({
      background = {
        color = colors.arch_blue,
        border_width = 0,
        corner_radius = 10,
        height = 24,
      }
    })
  end)
end)

battery:subscribe("mouse.exited", function()
  sbar.animate("tanh", 10, function()
    battery:set({
      background = {
        color = colors.arch_alt_bg,
        border_width = 0,
        corner_radius = 10,
        height = 24,
      }
    })
  end)
end)
