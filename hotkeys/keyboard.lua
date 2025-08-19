local gears = require("gears")
local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
local menubar = require("menubar")

keys = require("hotkeys.keys")

globalkeys = gears.table.join(
    awful.key({ keys.super, }, "s", hotkeys_popup.show_help,
        { description = "show help", group = "awesome" }),
    awful.key({ keys.super, }, "Left", awful.tag.viewprev,
        { description = "view previous", group = "tag" }),
    awful.key({ keys.super, }, "Right", awful.tag.viewnext,
        { description = "view next", group = "tag" }),
    awful.key({ keys.super, }, "Escape", awful.tag.history.restore,
        { description = "go back", group = "tag" }),

    awful.key({ keys.super, }, "j",
        function()
            awful.client.focus.byidx(1)
        end,
        { description = "focus next by index", group = "client" }
    ),
    awful.key({ keys.super, }, "k",
        function()
            awful.client.focus.byidx(-1)
        end,
        { description = "focus previous by index", group = "client" }
    ),
    awful.key({ keys.super, keys.ctrl }, "w", function() mymainmenu:show() end,
        { description = "show main menu", group = "awesome" }),

    -- Layout manipulation
    awful.key({ keys.super, keys.shift }, "j", function() awful.client.swap.byidx(1) end,
        { description = "swap with next client by index", group = "client" }),
    awful.key({ keys.super, keys.shift }, "k", function() awful.client.swap.byidx(-1) end,
        { description = "swap with previous client by index", group = "client" }),
    awful.key({ keys.super, keys.ctrl }, "j", function() awful.screen.focus_relative(1) end,
        { description = "focus the next screen", group = "screen" }),
    awful.key({ keys.super, keys.ctrl }, "k", function() awful.screen.focus_relative(-1) end,
        { description = "focus the previous screen", group = "screen" }),
    awful.key({ keys.super, }, "u", awful.client.urgent.jumpto,
        { description = "jump to urgent client", group = "client" }),
    awful.key({ keys.super, }, "Tab",
        function()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        { description = "go back", group = "client" }),

    -- Standard program
    awful.key({ keys.super, }, "Return", function() awful.spawn(terminal) end,
        { description = "open a terminal", group = "launcher" }),
    awful.key({ keys.super, keys.ctrl }, "r", awesome.restart,
        { description = "reload awesome", group = "awesome" }),
    awful.key({ keys.super, keys.shift }, "q", awesome.quit,
        { description = "quit awesome", group = "awesome" }),
    awful.key({ keys.super, }, "l", function() awful.tag.incmwfact(0.05) end,
        { description = "increase master width factor", group = "layout" }),
    awful.key({ keys.super, }, "h", function() awful.tag.incmwfact(-0.05) end,
        { description = "decrease master width factor", group = "layout" }),
    awful.key({ keys.super, keys.shift }, "h", function() awful.tag.incnmaster(1, nil, true) end,
        { description = "increase the number of master clients", group = "layout" }),
    awful.key({ keys.super, keys.shift }, "l", function() awful.tag.incnmaster(-1, nil, true) end,
        { description = "decrease the number of master clients", group = "layout" }),
    awful.key({ keys.super, keys.ctrl }, "h", function() awful.tag.incncol(1, nil, true) end,
        { description = "increase the number of columns", group = "layout" }),
    awful.key({ keys.super, keys.ctrl }, "l", function() awful.tag.incncol(-1, nil, true) end,
        { description = "decrease the number of columns", group = "layout" }),
    awful.key({ keys.super, }, "space", function() awful.layout.inc(1) end,
        { description = "select next", group = "layout" }),
    awful.key({ keys.super, keys.shift }, "space", function() awful.layout.inc(-1) end,
        { description = "select previous", group = "layout" }),

    awful.key({ keys.super, keys.ctrl }, "n",
        function()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                c:emit_signal(
                    "request::activate", "key.unminimize", { raise = true }
                )
            end
        end,
        { description = "restore minimized", group = "client" }),

    -- Audio

    awful.key({}, "XF86AudioPrev", function() awful.spawn("playerctl previous") end,
        { description = "Previous track" }),
    awful.key({}, "XF86AudioNext", function() awful.spawn("playerctl next") end,
        { description = "Next track" }),
    awful.key({}, "XF86AudioPlay", function() awful.spawn("playerctl play-pause") end,
        { description = "Play/Pause media" }),
    awful.key({}, "XF86AudioStop", function() awful.spawn("playerctl stop") end,
        { description = "Stop media" }),
    awful.key({}, "XF86AudioLowerVolume", function() awful.spawn("wpctl set-volume @DEFAULT_SINK@ 5%-") end,
        { description = "Lower volume" }),
    awful.key({}, "XF86AudioRaiseVolume", function() awful.spawn("wpctl set-volume @DEFAULT_SINK@ 5%+") end,
        { description = "Raise volume" }),
    awful.key({}, "XF86AudioMute", function() awful.spawn("wpctl set-mute @DEFAULT_SINK@ toggle") end,
        { description = "Mute volume" }),

    -- Prompt
    awful.key({ keys.super, keys.alt }, "r", function() awful.screen.focused().mypromptbox:run() end,
        { description = "run prompt", group = "launcher" }),
    awful.key({ keys.super }, "r", function() awful.spawn("rofi -show drun -show-icons") end,
        { description = "run rofi", group = "launcher" }
    ),

    awful.key({ keys.super }, "v", function() awful.spawn("copyq show") end,
        { description = "show clipboard", group = "launcher" }
    ),

        awful.key({ keys.super }, "e", function() awful.spawn("thunar") end,
        { description = "open thunar", group = "launcher" }
    ),

    awful.key({ keys.super }, "x",
        function()
            awful.prompt.run {
                prompt       = "Run Lua code: ",
                textbox      = awful.screen.focused().mypromptbox.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval"
            }
        end,
        { description = "lua execute prompt", group = "awesome" }),
    -- Menubar
    awful.key({ keys.super }, "p", function() menubar.show() end,
        { description = "show the menubar", group = "launcher" })
)

clientkeys = gears.table.join(
    awful.key({ keys.super, }, "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        { description = "toggle fullscreen", group = "client" }),
    awful.key({ keys.super }, "w", function(c) c:kill() end,
        { description = "close", group = "client" }),
    awful.key({ keys.super, keys.ctrl }, "space", awful.client.floating.toggle,
        { description = "toggle floating", group = "client" }),
    awful.key({ keys.super, keys.ctrl }, "Return", function(c) c:swap(awful.client.getmaster()) end,
        { description = "move to master", group = "client" }),
    awful.key({ keys.super, }, "o", function(c) c:move_to_screen() end,
        { description = "move to screen", group = "client" }),
    awful.key({ keys.super, }, "t", function(c) c.ontop = not c.ontop end,
        { description = "toggle keep on top", group = "client" }),
    awful.key({ keys.super, }, "n",
        function(c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end,
        { description = "minimize", group = "client" }),
    awful.key({ keys.super, }, "m",
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end,
        { description = "(un)maximize", group = "client" }),
    awful.key({ keys.super, keys.ctrl }, "m",
        function(c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end,
        { description = "(un)maximize vertically", group = "client" }),
    awful.key({ keys.super, keys.shift }, "m",
        function(c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end,
        { description = "(un)maximize horizontally", group = "client" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ keys.super }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
            { description = "view tag #" .. i, group = "tag" }),
        -- Toggle tag display.
        awful.key({ keys.super, keys.ctrl }, "#" .. i + 9,
            function()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    awful.tag.viewtoggle(tag)
                end
            end,
            { description = "toggle tag #" .. i, group = "tag" }),
        -- Move client to tag.
        awful.key({ keys.super, keys.shift }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:move_to_tag(tag)
                    end
                end
            end,
            { description = "move focused client to tag #" .. i, group = "tag" }),
        -- Toggle tag on focused client.
        awful.key({ keys.super, keys.ctrl, keys.shift }, "#" .. i + 9,
            function()
                if client.focus then
                    local tag = client.focus.screen.tags[i]
                    if tag then
                        client.focus:toggle_tag(tag)
                    end
                end
            end,
            { description = "toggle focused client on tag #" .. i, group = "tag" })
    )
end

clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ keys.super }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ keys.super }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

return root.keys(globalkeys)
