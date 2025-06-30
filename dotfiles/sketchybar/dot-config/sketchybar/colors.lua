return {
  -- Waybar-inspired Arch Linux colors
  arch_blue = 0xff1793d1,
  arch_mine_shaft = 0xff333333,
  arch_text = 0xffffffff,
  arch_alt_bg = 0xff444444,
  arch_urgent = 0xffff6b6b,

  -- Original colors (kept for compatibility)
  black = 0xff121212,
  white = 0xfffffaf3,
  red = 0xffff273f,
  green = 0xff8ce00a,
  blue = 0xff008df8,
  yellow = 0xffffd141,
  orange = 0xffffb900,
  magenta = 0xff9a5feb,
  grey = 0xffaaaaaa,
  transparent = 0x00000000,

  bar = {
    bg = 0xf0121212,
    border = 0xff383838,
  },
  popup = {
    bg = 0xc0121212,
    border = 0xff383838
  },
  bg1 = 0xff363944,
  bg2 = 0xff414550,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
