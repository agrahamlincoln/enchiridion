require("items.apple")
require("items.menus")
require("items.spaces")
require("items.front_app")
require("items.calendar")
require("items.widgets")
require("items.media")

-- Execute shell-based brew widget
sbar.exec("$CONFIG_DIR/items/brew.sh")
