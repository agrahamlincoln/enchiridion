local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Cache total memory once at load (bytes -> GiB)
local total_mem_gib = 0
sbar.exec("sysctl -n hw.memsize", function(result)
  total_mem_gib = tonumber(result) / (1024 * 1024 * 1024)
end)

local popup_width = 200

local memory = sbar.add("item", "widgets.memory", {
  position = "right",
  padding_left = 2,
  padding_right = 2,
  update_freq = 10,
  icon = {
    string = icons.memory,
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
  popup = { align = "center" },
})

local mem_detail = sbar.add("item", {
  position = "popup." .. memory.name,
  icon = {
    string = "Used / Total:",
    width = popup_width / 2,
    align = "left",
    color = colors.arch_text,
  },
  label = {
    string = "? / ? GiB",
    width = popup_width / 2,
    align = "right",
    color = colors.arch_text,
  },
  background = {
    color = colors.arch_mine_shaft,
    corner_radius = 8,
    height = 30,
    border_width = 1,
    border_color = colors.arch_alt_bg,
  },
})

memory:subscribe({ "routine", "system_woke" }, function()
  sbar.exec("vm_stat", function(result)
    -- Parse page size
    local page_size = tonumber(result:match("page size of (%d+) bytes")) or 16384

    -- Parse page counts (handle both "Pages active" and "Pages active" formats)
    local active = tonumber(result:match("Pages active:%s+(%d+)")) or 0
    local wired = tonumber(result:match("Pages wired down:%s+(%d+)")) or 0
    local compressed = tonumber(result:match("Pages occupied by compressor:%s+(%d+)")) or 0

    local used_gib = (active + wired + compressed) * page_size / (1024 * 1024 * 1024)
    local pct = 0
    if total_mem_gib > 0 then
      pct = math.floor((used_gib / total_mem_gib) * 100 + 0.5)
    end

    local color = colors.arch_text
    if pct >= 90 then
      color = colors.arch_urgent
    elseif pct >= 80 then
      color = colors.orange
    elseif pct >= 60 then
      color = colors.yellow
    end

    memory:set({
      icon = { color = color },
      label = {
        string = pct .. "%",
        color = color,
      },
    })

    mem_detail:set({
      label = string.format("%.1f / %.0f GiB", used_gib, total_mem_gib),
    })
  end)
end)

memory:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    sbar.exec("open -a 'Activity Monitor'")
  else
    local should_draw = memory:query().popup.drawing == "off"
    memory:set({ popup = { drawing = should_draw } })
  end
end)

memory:subscribe("mouse.exited.global", function()
  memory:set({ popup = { drawing = false } })
end)

memory:subscribe("mouse.entered", function()
  sbar.animate("tanh", 10, function()
    memory:set({
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

memory:subscribe("mouse.exited", function()
  sbar.animate("tanh", 10, function()
    memory:set({
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
