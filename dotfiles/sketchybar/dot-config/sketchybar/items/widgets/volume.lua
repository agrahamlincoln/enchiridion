local colors = require("colors")
local icons = require("icons")
local settings = require("settings")

-- Single volume widget styled as waybar pill
local volume = sbar.add("item", "widgets.volume", {
  position = "right",
  padding_left = 8,
  padding_right = 8,
  icon = {
    string = icons.volume._100,
    color = colors.arch_text,
    font = { size = 14 },
    padding_right = 6,
  },
  label = {
    string = "50%",
    color = colors.arch_text,
    font = { family = settings.font.numbers, size = 12 },
  },
  background = {
    color = colors.arch_alt_bg,
    corner_radius = 10,
    height = 24,
  },
})

-- Add spacing after volume pill
sbar.add("item", "widgets.volume.padding", {
  position = "right",
  width = 6,
})

-- Volume slider popup
local popup_width = 200
local volume_slider = sbar.add("slider", popup_width, {
  position = "popup." .. volume.name,
  slider = {
    highlight_color = colors.arch_blue,
    background = {
      height = 6,
      corner_radius = 3,
      color = colors.arch_alt_bg,
    },
    knob = {
      string = "􀀁",
      drawing = true,
      color = colors.arch_blue,
    },
  },
  background = {
    color = colors.arch_mine_shaft,
    corner_radius = 8,
    height = 30,
    border_width = 1,
    border_color = colors.arch_alt_bg,
  },
  click_script = 'osascript -e "set volume output volume $PERCENTAGE"'
})

-- Volume change event handler
volume:subscribe("volume_change", function(env)
  local vol = tonumber(env.INFO) or 0
  local icon = icons.volume._100
  local color = colors.arch_text

  -- Determine icon and color based on volume level
  if vol == 0 then
    icon = icons.volume._0
    color = colors.arch_urgent
  elseif vol < 30 then
    icon = icons.volume._10
  elseif vol < 70 then
    icon = icons.volume._66
  else
    icon = icons.volume._100
  end

  volume:set({
    icon = {
      string = icon,
      color = color
    },
    label = {
      string = vol .. "%",
      color = color
    }
  })

  volume_slider:set({
    slider = { percentage = vol }
  })
end)

-- Mouse interactions
volume:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    -- Right click opens sound preferences
    sbar.exec("open /System/Library/PreferencePanes/Sound.prefpane")
  else
    -- Left click toggles popup
    local should_draw = volume:query().popup.drawing == "off"
    volume:set({ popup = { drawing = should_draw } })
  end
end)

volume:subscribe("mouse.scrolled", function(env)
  local delta = env.SCROLL_DELTA * 2
  sbar.exec('osascript -e "set volume output volume (output volume of (get volume settings) + ' .. delta .. ')"')
end)

volume:subscribe("mouse.exited.global", function()
  volume:set({ popup = { drawing = false } })
end)

-- Hover effects
volume:subscribe("mouse.entered", function()
  volume:set({
    background = {
      color = colors.with_alpha(colors.arch_blue, 0.3)
    }
  })
end)

volume:subscribe("mouse.exited", function()
  volume:set({
    background = {
      color = colors.arch_alt_bg
    }
  })
end)

-- Initialize volume
sbar.exec("osascript -e 'output volume of (get volume settings)'", function(result)
  local vol = tonumber(result) or 50
  volume:set({ label = vol .. "%" })
end)
