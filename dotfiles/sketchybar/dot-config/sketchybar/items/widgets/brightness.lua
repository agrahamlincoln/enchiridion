local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local brightness = sbar.add("item", "widgets.brightness", {
  position = "right",
  padding_left = 2,
  padding_right = 2,
  update_freq = 15,
  icon = {
    string = icons.brightness.full,
    color = colors.arch_text,
    font = { size = 14 },
    padding_left = 8,
    padding_right = 8,
  },
  label = {
    string = "100%",
    color = colors.arch_text,
    font = { family = settings.font.numbers, size = 12 },
    padding_left = 8,
    padding_right = 8,
  },
  background = {
    color = colors.arch_alt_bg,
    corner_radius = 10,
    height = 24,
  },
})

local has_backlight = false

local function update_brightness()
  sbar.exec(
    "ioreg -c AppleBacklightDisplay -r -d 1 | grep -i '\"brightness\"' | head -1",
    function(result)
      local current = result:match('"brightness"%s*=%s*(%d+)')
      if not current then
        -- No built-in display backlight (external monitors only); hide widget
        if not has_backlight then
          brightness:set({ drawing = false })
        end
        return
      end

      has_backlight = true

      current = tonumber(current)

      -- ioreg brightness is typically 0-1024 on modern macOS
      -- Detect scale: if value > 100, assume 0-1024 range
      local pct
      if current > 100 then
        pct = math.floor(current / 1024 * 100 + 0.5)
      else
        pct = current
      end
      pct = math.max(0, math.min(100, pct))

      local icon = icons.brightness.full
      if pct < 33 then
        icon = icons.brightness.low
      elseif pct < 66 then
        icon = icons.brightness.half
      end

      brightness:set({
        icon = { string = icon },
        label = { string = pct .. "%" },
      })
    end
  )
end

brightness:subscribe({ "routine", "system_woke" }, update_brightness)

brightness:subscribe("mouse.clicked", function()
  sbar.exec("open x-apple.systempreferences:com.apple.Displays-Settings.extension")
end)

-- Scroll to adjust brightness via media key simulation
brightness:subscribe("mouse.scrolled", function(env)
  local delta = env.SCROLL_DELTA
  if delta > 0 then
    -- Brightness up (F2 media key)
    sbar.exec("osascript -e 'tell application \"System Events\" to key code 144'")
  elseif delta < 0 then
    -- Brightness down (F1 media key)
    sbar.exec("osascript -e 'tell application \"System Events\" to key code 145'")
  end
  -- Refresh display after a short delay for the system to apply the change
  sbar.delay(0.3, update_brightness)
end)

brightness:subscribe("mouse.entered", function()
  sbar.animate("tanh", 10, function()
    brightness:set({
      background = {
        color = colors.arch_blue,
        border_width = 0,
        corner_radius = 10,
        height = 24,
      },
    })
  end)
end)

brightness:subscribe("mouse.exited", function()
  sbar.animate("tanh", 10, function()
    brightness:set({
      background = {
        color = colors.arch_alt_bg,
        border_width = 0,
        corner_radius = 10,
        height = 24,
      },
    })
  end)
end)
