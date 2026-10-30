-- Icon-only tasklist. Hovering a client shows a popup with its title and a
-- live thumbnail of the window (or its icon when the window isn't visible,
-- since an unmapped window has no content to grab).
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local cairo = require("lgi").cairo

local tasklist = {}

local THUMB_W, THUMB_H = dpi(240), dpi(150)

-- One preview popup shared by every screen.
local preview

local function get_preview()
    if preview then return preview end

    preview = awful.popup {
        widget = {
            {
                {
                    id = "title",
                    align = "center",
                    ellipsize = "end",
                    forced_width = THUMB_W,
                    widget = wibox.widget.textbox,
                },
                {
                    {
                        id = "thumb",
                        resize = true,
                        widget = wibox.widget.imagebox,
                    },
                    halign = "center",
                    valign = "center",
                    forced_width = THUMB_W,
                    forced_height = THUMB_H,
                    widget = wibox.container.place,
                },
                spacing = dpi(6),
                layout = wibox.layout.fixed.vertical,
            },
            margins = dpi(8),
            widget = wibox.container.margin,
        },
        border_width = dpi(1),
        border_color = beautiful.border_focus,
        bg = beautiful.bg_normal,
        ontop = true,
        visible = false,
    }
    return preview
end

local function show_preview(c, anchor)
    local p = get_preview()
    local title = p.widget:get_children_by_id("title")[1]
    local thumb = p.widget:get_children_by_id("thumb")[1]

    title:set_text(c.name or c.class or "")

    if c:isvisible() and not c.minimized then
        -- c.content is an X surface without a size, which imagebox can't
        -- handle, so paint it scaled down into an image surface.
        local geo = c:geometry()
        local scale = math.min(THUMB_W / geo.width, THUMB_H / geo.height)
        local w, h = math.floor(geo.width * scale), math.floor(geo.height * scale)
        local img = cairo.ImageSurface(cairo.Format.RGB24, w, h)
        local cr = cairo.Context(img)
        cr:scale(scale, scale)
        cr:set_source_surface(gears.surface(c.content), 0, 0)
        cr:paint()
        thumb.image = img
        thumb.forced_width = w
        thumb.forced_height = h
    else
        thumb.image = c.icon
        thumb.forced_width = dpi(64)
        thumb.forced_height = dpi(64)
    end

    p.screen = c.screen
    p:move_next_to(anchor)
    p.visible = true
end

local function hide_preview()
    if preview then preview.visible = false end
end

function tasklist.new(s, buttons)
    return awful.widget.tasklist {
        screen = s,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = buttons,
        style = {
            bg_minimize = beautiful.bg_minimize or beautiful.bg_normal,
        },
        layout = {
            spacing = dpi(4),
            layout = wibox.layout.fixed.horizontal,
        },
        widget_template = {
            {
                {
                    id = "clienticon",
                    widget = awful.widget.clienticon,
                },
                margins = dpi(3),
                widget = wibox.container.margin,
            },
            id = "background_role",
            widget = wibox.container.background,
            create_callback = function(self, c)
                self.client = c
                self:get_children_by_id("clienticon")[1].client = c
                -- Minimized clients are shown dimmed.
                self.opacity = c.minimized and 0.4 or 1
                self:connect_signal("mouse::enter", function() show_preview(self.client, mouse.current_widget_geometry) end)
                self:connect_signal("mouse::leave", hide_preview)
            end,
            update_callback = function(self, c)
                self.opacity = c.minimized and 0.4 or 1
                self.client = c
            end,
        },
    }
end

-- The thumbnail would be stale once the client goes away or is (un)minimized.
client.connect_signal("unmanage", hide_preview)
client.connect_signal("property::minimized", hide_preview)

return tasklist
