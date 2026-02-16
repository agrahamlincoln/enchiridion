return {
  -- Waybar-inspired Arch Linux colors
  arch_blue = 0xff1793d1,
  arch_mine_shaft = 0xff333333,
  arch_text = 0xffffffff,
  arch_alt_bg = 0xff444444,
  arch_urgent = 0xfff43f5e,

  -- Semantic colors (Tailwind-derived)
  black = 0xff292524,
  white = 0xffd4d4d8,
  red = 0xfff43f5e,
  green = 0xff22c55e,
  blue = 0xff3b82f6,
  yellow = 0xfffcd34d,
  orange = 0xfffb923c,
  magenta = 0xffe879f9,
  grey = 0xffd4d4d8,
  transparent = 0x00000000,

  bar = {
    bg = 0xf00a0a0a,
    border = 0xff333333,
  },
  popup = {
    bg = 0xc00a0a0a,
    border = 0xff333333
  },
  bg1 = 0xff333333,
  bg2 = 0xff444444,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
