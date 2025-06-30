local colors = require("colors")
local settings = require("settings")

local front_app = sbar.add("item", "front_app", {
  position = "center",
  icon = { drawing = false },
  label = {
    font = {
      style = settings.font.style_map["Regular"],
      size = 14.0,
    },
    max_chars = 50,
    color = colors.arch_text,
    padding_left = 12,
    padding_right = 12,
  },
  background = {
    color = colors.arch_alt_bg,
    corner_radius = 10,
    height = 24,
    border_width = 0,
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  local app_name = env.INFO or "Desktop"
  front_app:set({ label = { string = app_name } })
end)

front_app:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)

-- Hover effects to match waybar styling
front_app:subscribe("mouse.entered", function()
  front_app:set({
    background = {
      color = colors.with_alpha(colors.arch_blue, 0.3)
    }
  })
end)

front_app:subscribe("mouse.exited", function()
  front_app:set({
    background = {
      color = colors.arch_alt_bg
    }
  })
end)
