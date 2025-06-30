local colors = require("colors")

-- Equivalent to the --bar domain
sbar.bar({
  topmost = "window",
  height = 30,
  color = colors.transparent,
  padding_right = 6,
  padding_left = 6,
  notch_width = 200,
})
