local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Bluetooth is a private SF Symbol with no Unicode character in SF Pro.
-- Override icon font to Hack Nerd Font which has bluetooth glyphs.
local bt_icon_font = "Hack Nerd Font Mono"

local bluetooth = sbar.add("item", "widgets.bluetooth", {
  position = "right",
  padding_left = 2,
  padding_right = 2,
  update_freq = 30,
  icon = {
    string = icons.bluetooth.on,
    color = colors.arch_text,
    font = { family = bt_icon_font, size = 14 },
    padding_left = 6,
    padding_right = 0,
  },
  label = {
    string = "BT",
    color = colors.arch_text,
    font = { family = settings.font.text, size = 12 },
    max_chars = 22,
    padding_left = 4,
    padding_right = 6,
  },
  background = {
    color = colors.arch_alt_bg,
    corner_radius = 10,
    height = 24,
  },
})

local function update_bluetooth()
  sbar.exec("system_profiler SPBluetoothDataType 2>/dev/null", function(result)
    local power_on = result:match("State: (.-)%s") == "On"

    if not power_on then
      bluetooth:set({
        icon = {
          string = icons.bluetooth.off,
          color = colors.arch_urgent,
        },
        label = {
          string = "Off",
          color = colors.arch_urgent,
        },
      })
      return
    end

    -- Parse connected devices and their battery levels
    local devices = {}
    local in_connected = false
    local current_device = nil
    for line in result:gmatch("[^\r\n]+") do
      if line:match("Connected:") then
        in_connected = true
      elseif in_connected then
        local device = line:match("^%s%s%s%s%s%s%s%s(.-):%s*$")
        if device then
          current_device = { name = device, battery = nil }
          table.insert(devices, current_device)
        elseif current_device then
          local batt = line:match("Battery Level: (%d+)%%")
          if batt then
            current_device.battery = tonumber(batt)
          end
        end
        if line:match("^%s%s%s%s%S") and not line:match("^%s%s%s%s%s%s%s%s") then
          in_connected = false
          current_device = nil
        end
      end
    end

    if #devices > 0 then
      local dev = devices[1]
      local label = dev.name
      if dev.battery then
        label = label .. " " .. dev.battery .. "%"
      end
      if #label > 19 then
        label = label:sub(1, 19) .. "…"
      end
      bluetooth:set({
        icon = {
          string = icons.bluetooth.connected,
          color = colors.arch_text,
        },
        label = {
          string = label,
          color = colors.arch_text,
        },
      })
    else
      bluetooth:set({
        icon = {
          string = icons.bluetooth.on,
          color = colors.grey,
        },
        label = {
          string = "On",
          color = colors.grey,
        },
      })
    end
  end)
end

bluetooth:subscribe({ "routine", "system_woke" }, update_bluetooth)

bluetooth:subscribe("mouse.clicked", function()
  sbar.exec("open x-apple.systempreferences:com.apple.BluetoothSettings")
end)

bluetooth:subscribe("mouse.entered", function()
  sbar.animate("tanh", 10, function()
    bluetooth:set({
      background = {
        color = colors.arch_blue,
        border_width = 0,
        corner_radius = 10,
        height = 24,
      },
    })
  end)
end)

bluetooth:subscribe("mouse.exited", function()
  sbar.animate("tanh", 10, function()
    bluetooth:set({
      background = {
        color = colors.arch_alt_bg,
        border_width = 0,
        corner_radius = 10,
        height = 24,
      },
    })
  end)
end)
