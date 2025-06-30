local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "network_update"
-- for the network interface "en0", which is fired every 2.0 seconds.
sbar.exec("killall network_load >/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load en0 network_update 2.0")

local popup_width = 250

local wifi = sbar.add("item", "widgets.wifi", {
  position = "right",
  padding_left = 12,
  padding_right = 12,
  icon = {
    string = icons.wifi.connected,
    color = colors.arch_text,
    font = { size = 14 },
    padding_left = 8,
    padding_right = 8,
  },
  label = {
    string = "WiFi",
    color = colors.arch_text,
    font = { family = settings.font.text, size = 12 },
    padding_left = 8,
    padding_right = 8,
  },
  background = {
    color = colors.arch_alt_bg,
    corner_radius = 10,
    height = 24,
  },
})

-- Add spacing after wifi pill
sbar.add("item", "widgets.wifi.padding", {
  position = "right",
  width = 6,
})

local ssid = sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    font = {
      style = settings.font.style_map["Bold"]
    },
    string = icons.wifi.router,
    color = colors.arch_text,
  },
  width = popup_width,
  align = "center",
  label = {
    font = {
      size = 15,
      style = settings.font.style_map["Bold"]
    },
    max_chars = 18,
    string = "????????????",
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

local hostname = sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    align = "left",
    string = "Hostname:",
    width = popup_width / 2,
    color = colors.arch_text,
  },
  label = {
    max_chars = 20,
    string = "????????????",
    width = popup_width / 2,
    align = "right",
    color = colors.arch_text,
  },
  background = {
    color = colors.arch_mine_shaft,
    corner_radius = 8,
    height = 25,
  }
})

local ip = sbar.add("item", {
  position = "popup." .. wifi.name,
  icon = {
    align = "left",
    string = "IP:",
    width = popup_width / 2,
    color = colors.arch_text,
  },
  label = {
    string = "???.???.???.???",
    width = popup_width / 2,
    align = "right",
    color = colors.arch_text,
  },
  background = {
    color = colors.arch_mine_shaft,
    corner_radius = 8,
    height = 25,
  }
})



wifi:subscribe({"wifi_change", "system_woke"}, function(env)
  sbar.exec("ipconfig getifaddr en0", function(ip)
    local connected = not (ip == "")
    wifi:set({
      icon = {
        string = connected and icons.wifi.connected or icons.wifi.disconnected,
        color = connected and colors.arch_text or colors.arch_urgent,
      },
      label = {
        string = connected and "WiFi" or "No WiFi",
        color = connected and colors.arch_text or colors.arch_urgent,
      }
    })
  end)
end)

local function hide_details()
  wifi:set({ popup = { drawing = false } })
end

local function toggle_details()
  local should_draw = wifi:query().popup.drawing == "off"
  if should_draw then
    wifi:set({ popup = { drawing = true }})
    sbar.exec("networksetup -getcomputername", function(result)
      hostname:set({ label = result })
    end)
    sbar.exec("ipconfig getifaddr en0", function(result)
      ip:set({ label = result })
    end)
    sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
      ssid:set({ label = result })
    end)
  else
    hide_details()
  end
end

-- Mouse interactions
wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", hide_details)

-- Hover effects with smooth animations
wifi:subscribe("mouse.entered", function()
  sbar.animate("tanh", 10, function()
    wifi:set({
      background = {
        color = colors.arch_blue,
        border_width = 0,
        corner_radius = 10,
        height = 24,
      }
    })
  end)
end)

wifi:subscribe("mouse.exited", function()
  sbar.animate("tanh", 10, function()
    wifi:set({
      background = {
        color = colors.arch_alt_bg,
        border_width = 0,
        corner_radius = 10,
        height = 24,
      }
    })
  end)
end)

local function copy_label_to_clipboard(env)
  local label = sbar.query(env.NAME).label.value
  sbar.exec("echo \"" .. label .. "\" | pbcopy")
  sbar.set(env.NAME, { label = { string = icons.clipboard, align="center" } })
  sbar.delay(1, function()
    sbar.set(env.NAME, { label = { string = label, align = "right" } })
  end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
