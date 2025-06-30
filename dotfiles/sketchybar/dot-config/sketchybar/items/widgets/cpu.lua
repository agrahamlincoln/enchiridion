local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "cpu_update" for
-- the cpu load data, which is fired every 2.0 seconds.
sbar.exec("killall cpu_load >/dev/null; $CONFIG_DIR/helpers/event_providers/cpu_load/bin/cpu_load cpu_update 2.0")

-- CPU History for sparkline
local cpu_history = {}
local max_history = 8

-- Unicode block characters for sparkline (from bottom to top)
local blocks = {'▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'}

-- Function to convert CPU value to block character
local function value_to_block(value)
  if value <= 0 then
    return blocks[1]
  end

  -- Normalize value to 0-1 range (assuming max 100%)
  local normalized = math.min(1.0, value / 100.0)

  -- Map to block index (1-8)
  local block_index = math.max(1, math.ceil(normalized * #blocks))
  return blocks[block_index]
end

-- Function to generate sparkline text
local function generate_sparkline()
  if #cpu_history == 0 then
    return string.rep(blocks[1], max_history)
  end

  local sparkline = ""

  -- Pad with zeros if we don't have enough history
  if #cpu_history < max_history then
    for i = 1, max_history - #cpu_history do
      sparkline = sparkline .. blocks[1]
    end
  end

  -- Take the last max_history values
  local start_idx = math.max(1, #cpu_history - max_history + 1)
  for i = start_idx, #cpu_history do
    sparkline = sparkline .. value_to_block(cpu_history[i])
  end

  return sparkline
end

local cpu = sbar.add("item", "widgets.cpu", {
  position = "right",
  padding_left = 2,
  padding_right = 2,
  icon = {
    string = icons.cpu,
    color = colors.arch_text,
    font = { size = 12 },
    padding_left = 8,
    padding_right = 4,
  },
  label = {
    string = blocks[1]:rep(max_history) .. " 0%",
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

cpu:subscribe("cpu_update", function(env)
  local load = tonumber(env.total_load) or 0

  -- Add to history
  table.insert(cpu_history, load)
  if #cpu_history > max_history then
    table.remove(cpu_history, 1)
  end

  -- Generate sparkline
  local sparkline = generate_sparkline()

  -- Color coding based on CPU load
  local color = colors.arch_text
  local sparkline_color = colors.arch_blue
  if load > 30 then
    if load < 60 then
      color = colors.yellow
      sparkline_color = colors.yellow
    elseif load < 80 then
      color = colors.orange
      sparkline_color = colors.orange
    else
      color = colors.arch_urgent
      sparkline_color = colors.arch_urgent
    end
  end

  cpu:set({
    icon = { color = color },
    label = {
      string = sparkline .. " " .. math.floor(load) .. "%",
      color = color,
      font = { family = settings.font.numbers, size = 12 }
    }
  })
end)

-- Mouse interactions
cpu:subscribe("mouse.clicked", function(env)
  sbar.exec("open -a 'Activity Monitor'")
end)

-- Hover effects with smooth animations
cpu:subscribe("mouse.entered", function()
  sbar.animate("tanh", 10, function()
    cpu:set({
      background = {
        color = colors.arch_blue,
        corner_radius = 10,
        height = 24,
        border_width = 0,
        drawing = true,
      }
    })
  end)
end)

cpu:subscribe("mouse.exited", function()
  sbar.animate("tanh", 10, function()
    cpu:set({
      background = {
        color = colors.arch_alt_bg,
        corner_radius = 10,
        height = 24,
        border_width = 0,
        drawing = true,
      }
    })
  end)
end)
