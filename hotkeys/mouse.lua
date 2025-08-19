local awful = require("awful")
local gears = require("gears")

 -- Happens when u stare the "desktop"

-- {{{ Mouse bindings
return root.buttons(gears.table.join(
    awful.button({}, 3, function() mymainmenu:toggle() end),
    awful.button({}, 4, awful.tag.viewnext),
    awful.button({}, 5, awful.tag.viewprev)
))
-- }
