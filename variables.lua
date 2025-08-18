local awful = require("awful")
local beautiful = require("beautiful")

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
local themes = {
    "default", -- 1
    "sky",
    "zenburn",
}

local chosen_theme = themes[3]
-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(string.format("%s/.dotfiles/awesome/themes/%s/theme.lua", os.getenv("HOME"), chosen_theme))
-- This is used later as the default terminal and editor to run.
terminal = "kitty"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.magnifier,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.floating,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}