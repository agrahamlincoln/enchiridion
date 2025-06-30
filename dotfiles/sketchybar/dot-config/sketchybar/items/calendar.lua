local settings = require("settings")
local colors = require("colors")

-- Clock item styled as a pill matching waybar
local clock = sbar.add("item", "widgets.clock", {
  position = "right",
  icon = {
    string = "󰥔", -- Clock icon
    color = colors.arch_text,
    font = { size = 14 },
    padding_left = 8,
    padding_right = 8,
  },
  label = {
    color = colors.arch_text,
    padding_left = 8,
    padding_right = 8,
    font = {
      family = settings.font.numbers,
      size = 13,
      style = settings.font.style_map["Regular"]
    },
  },
  update_freq = 30,
  background = {
    color = colors.arch_mine_shaft,
    corner_radius = 10,
    height = 24,
  },
})

-- Add spacing after the clock pill
sbar.add("item", "widgets.clock.padding", {
  position = "right",
  width = 6,
})

-- Date popup
local popup_width = 200
local date_popup = sbar.add("item", {
  position = "popup." .. clock.name,
  width = popup_width,
  align = "center",
  icon = {
    string = "📅",
    font = { size = 16 },
    color = colors.arch_blue,
  },
  label = {
    string = "Today",
    font = { size = 14, style = settings.font.style_map["Bold"] },
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

-- Full date display in popup
local full_date = sbar.add("item", {
  position = "popup." .. clock.name,
  width = popup_width,
  icon = {
    drawing = false,
  },
  label = {
    string = "Loading...",
    align = "center",
    font = { size = 12 },
    color = colors.arch_text,
  },
  background = {
    color = colors.arch_mine_shaft,
    height = 25,
  }
})

-- Update clock and date
clock:subscribe({ "forced", "routine", "system_woke" }, function(env)
  local time = os.date("%H:%M")
  local date_str = os.date("%A, %B %d, %Y")

  clock:set({
    label = time
  })

  full_date:set({
    label = date_str
  })
end)

-- Mouse interactions
clock:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    -- Right click opens Date & Time preferences
    sbar.exec("open /System/Library/PreferencePanes/DateAndTime.prefpane")
  else
    -- Left click toggles popup
    local should_draw = clock:query().popup.drawing == "off"
    clock:set({ popup = { drawing = should_draw } })
  end
end)

clock:subscribe("mouse.exited.global", function()
  clock:set({ popup = { drawing = false } })
end)

-- Hover effects with smooth animations
clock:subscribe("mouse.entered", function()
  sbar.animate("tanh", 10, function()
    clock:set({
      background = {
        color = colors.arch_blue,
        border_width = 0,
        corner_radius = 10,
        height = 24,
      }
    })
  end)
end)

clock:subscribe("mouse.exited", function()
  sbar.animate("tanh", 10, function()
    clock:set({
      background = {
        color = colors.arch_mine_shaft,
        border_width = 0,
        corner_radius = 10,
        height = 24,
      }
    })
  end)
end)

-- Initialize
clock:set({
  icon = "󰥔",
  label = os.date("%H:%M")
})
