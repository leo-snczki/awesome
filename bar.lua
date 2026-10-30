local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local keys = require("hotkeys.keys")
local appmenu = require("widgets.appmenu")

local bar = {}

-- {{{ Buttons
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ keys.super }, 1, function(t)
        if client.focus then client.focus:move_to_tag(t) end
    end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", { raise = true })
        end
    end),
    awful.button({}, 3, function() awful.menu.client_list({ theme = { width = dpi(250) } }) end),
    awful.button({}, 4, function() awful.client.focus.byidx(1) end),
    awful.button({}, 5, function() awful.client.focus.byidx(-1) end)
)

-- Same as super+space / super+shift+space
local layoutbox_buttons = gears.table.join(
    awful.button({}, 1, function() awful.layout.inc(1) end),
    awful.button({}, 3, function() awful.layout.inc(-1) end),
    awful.button({}, 4, function() awful.layout.inc(1) end),
    awful.button({}, 5, function() awful.layout.inc(-1) end)
)
-- }}}

local function separator()
    return wibox.widget {
        orientation = "vertical",
        forced_width = dpi(12),
        thickness = dpi(1),
        span_ratio = 0.5,
        color = beautiful.border_focus,
        widget = wibox.widget.separator,
    }
end

-- Shared by every screen (the systray is only drawn on the primary one).
-- Created on first use, since this module is loaded before the theme.
local systray, clock
local function shared_widgets()
    if not clock then
        systray = wibox.widget.systray()
        clock = wibox.widget.textclock(" %a %d %b %Y  <b>%H:%M:%S</b> ", 1)
        awful.widget.calendar_popup.month({ start_sunday = false }):attach(clock, "tr")
    end
    return systray, clock
end

function bar.setup(s)
    local systray, clock = shared_widgets()

    s.mypromptbox = awful.widget.prompt()

    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(layoutbox_buttons)
    awful.tooltip({
        objects = { s.mylayoutbox },
        timer_function = function() return "Layout: " .. awful.layout.getname() end,
    })

    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Minimized clients are shown dimmed (and prefixed with "_").
    s.mytasklist = awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons,
        style = {
            fg_minimize = beautiful.fg_minimize or "#7F7F6F",
            bg_minimize = beautiful.bg_minimize or beautiful.bg_normal,
        },
        layout = {
            spacing = dpi(4),
            max_widget_size = dpi(200),
            layout = wibox.layout.flex.horizontal,
        },
    }

    s.mywibox = awful.wibar({ position = "top", screen = s, height = dpi(24) })

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
            s.mylayoutbox,
            separator(),
            appmenu.new(s),
            s.mypromptbox,
            separator(),
        },
        s.mytasklist, -- Middle
        { -- Right
            layout = wibox.layout.fixed.horizontal,
            separator(),
            systray,
            clock,
        },
    }
end

return bar
