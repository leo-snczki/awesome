local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local keys = require("hotkeys.keys")

local bar = {}

local separator = wibox.widget {
    text = " | ",
    widget = wibox.widget.textbox,
    align = "center",
    valign = "center"
}

-- Taglist buttons
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ keys.super }, 1, function(t)
        if client.focus then
            client.focus:move_to_tag(t)
        end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ keys.super }, 3, function(t)
        if client.focus then client.focus:toggle_tag(t) end
    end),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

-- Tasklist buttons
local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", { raise = true })
        end
    end),
    awful.button({}, 3, function() awful.menu.client_list({ theme = { width = 250 } }) end),
    awful.button({}, 4, function() awful.client.focus.byidx(1) end),
    awful.button({}, 5, function() awful.client.focus.byidx(-1) end)
)

function bar.setup(s)
    -- Promptbox
    s.mypromptbox = awful.widget.prompt()

    -- Taglist
    s.mytaglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Tasklist
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
    }

    -- Widgets
    local clock_widget = wibox.widget.textclock("%H:%M:%S | %d %b", 1)

    local systray = wibox.widget.systray()

    -- Wibar
    s.mywibox = awful.wibar({ position = "top", screen = s, height = dpi(32) })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            separator,
            s.mypromptbox
        },
        s.mytasklist, -- Middle: tasklist
        {             -- Right
            layout = wibox.layout.fixed.horizontal,
            separator,
            clock_widget,
            separator,
            systray
        }
    }
end

return bar
