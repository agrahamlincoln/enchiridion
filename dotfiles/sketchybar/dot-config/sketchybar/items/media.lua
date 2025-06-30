local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local whitelist = {
  ["Spotify"] = true,
  ["Music"] = true
};

-- Media item styled as a pill matching waybar
local media = sbar.add("item", "widgets.media", {
  position = "left",
  padding_left = 8,
  padding_right = 8,
  icon = {
    string = "󰋋", -- Music note icon
    color = colors.arch_text,
    font = { size = 14 },
    padding_right = 6,
  },
  label = {
    string = "No Music",
    color = colors.arch_text,
    font = { size = 12 },
    max_chars = 25,
  },
  background = {
    color = colors.arch_blue,
    corner_radius = 10,
    height = 24,
  },
  drawing = false,
  updates = true,
  popup = {
    align = "center",
    horizontal = true,
  }
})

-- Add spacing after the media pill
sbar.add("item", "widgets.media.padding", {
  position = "left",
  width = 6,
  drawing = false,
})

-- Media control popup
sbar.add("item", {
  position = "popup." .. media.name,
  icon = {
    string = icons.media.back,
    color = colors.arch_text,
    font = { size = 16 }
  },
  label = { drawing = false },
  background = {
    color = colors.arch_mine_shaft,
    corner_radius = 8,
    height = 30,
  },
  click_script = "nowplaying-cli previous",
})
sbar.add("item", {
  position = "popup." .. media.name,
  icon = {
    string = icons.media.play_pause,
    color = colors.arch_blue,
    font = { size = 16 }
  },
  label = { drawing = false },
  background = {
    color = colors.arch_mine_shaft,
    corner_radius = 8,
    height = 30,
  },
  click_script = "nowplaying-cli togglePlayPause",
})
sbar.add("item", {
  position = "popup." .. media.name,
  icon = {
    string = icons.media.forward,
    color = colors.arch_text,
    font = { size = 16 }
  },
  label = { drawing = false },
  background = {
    color = colors.arch_mine_shaft,
    corner_radius = 8,
    height = 30,
  },
  click_script = "nowplaying-cli next",
})

media:subscribe("media_change", function(env)
  if whitelist[env.INFO.app] then
    local playing = (env.INFO.state == "playing")
    local title = env.INFO.title or "Unknown Track"
    local artist = env.INFO.artist or "Unknown Artist"

    -- Format the display text
    local display_text = title .. " - " .. artist
    if not playing then
      display_text = "No Music"
    end

    media:set({
      drawing = playing,
      label = {
        string = display_text,
        color = colors.arch_mine_shaft -- Dark text on blue background
      },
      icon = {
        string = playing and "󰝚" or "󰋋", -- Playing or music note icon
        color = colors.arch_mine_shaft
      }
    })

    -- Show/hide the spacing item based on media state
    sbar.set("widgets.media.padding", { drawing = playing })

    if not playing then
      media:set({ popup = { drawing = false } })
    end
  end
end)

-- Mouse interactions
media:subscribe("mouse.clicked", function(env)
  if env.BUTTON == "right" then
    -- Right click opens music app
    sbar.exec("open -a Music")
  else
    -- Left click toggles popup
    local should_draw = media:query().popup.drawing == "off"
    media:set({ popup = { drawing = should_draw } })
  end
end)

media:subscribe("mouse.exited.global", function()
  media:set({ popup = { drawing = false } })
end)

-- Hover effects
media:subscribe("mouse.entered", function()
  media:set({
    background = {
      color = colors.with_alpha(colors.arch_blue, 0.8)
    }
  })
end)

media:subscribe("mouse.exited", function()
  media:set({
    background = {
      color = colors.arch_blue
    }
  })
end)
