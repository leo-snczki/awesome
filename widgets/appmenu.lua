-- Global menu (macOS style) for the focused client.
--
-- Awesome itself acts as the com.canonical.AppMenu.Registrar, so Qt and
-- Electron apps export their menubar over D-Bus (com.canonical.dbusmenu)
-- instead of drawing it inside the window. KDE apps that publish the
-- _KDE_NET_WM_APPMENU_* X properties are supported too.
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local lgi = require("lgi")
local Gio, GLib, GObject = lgi.Gio, lgi.GLib, lgi.GObject

local DBUSMENU = "com.canonical.dbusmenu"
local PROPS = { "label", "visible", "enabled", "type", "children-display", "toggle-type", "toggle-state" }

-- The menu location is stored on the client window itself so it survives
-- an awesome restart (apps only register once, when the window is created).
local SERVICE_PROP = "_KDE_NET_WM_APPMENU_SERVICE_NAME"
local PATH_PROP    = "_KDE_NET_WM_APPMENU_OBJECT_PATH"
awesome.register_xproperty(SERVICE_PROP, "string")
awesome.register_xproperty(PATH_PROP, "string")

local bus = Gio.bus_get_sync(Gio.BusType.SESSION)
local instances = setmetatable({}, { __mode = "k" })

-- Registrations for windows that are not managed yet: window id -> { service, path }
local pending = {}

local function refresh_all()
    for w in pairs(instances) do w:refresh() end
end

local function set_client_menu(c, service, path)
    c:set_xproperty(SERVICE_PROP, service or "")
    c:set_xproperty(PATH_PROP, path or "")
    if c == client.focus then refresh_all() end
end

local function set_window_menu(window, service, path)
    for _, c in ipairs(client.get()) do
        if c.window == window then
            return set_client_menu(c, service, path)
        end
    end
    pending[window] = service and { service, path } or nil
end

local function get_client_menu(c)
    if not c or not c.valid then return end
    local service, path = c:get_xproperty(SERVICE_PROP), c:get_xproperty(PATH_PROP)
    if service and service ~= "" and path and path ~= "" and path ~= "/" then
        return service, path
    end
end

client.connect_signal("manage", function(c)
    local entry = pending[c.window]
    if entry then
        pending[c.window] = nil
        set_client_menu(c, entry[1], entry[2])
    end
end)

-- {{{ Registrar
local registrar_xml = [[
<node>
  <interface name="com.canonical.AppMenu.Registrar">
    <method name="RegisterWindow">
      <arg name="windowId" type="u" direction="in"/>
      <arg name="menuObjectPath" type="o" direction="in"/>
    </method>
    <method name="UnregisterWindow">
      <arg name="windowId" type="u" direction="in"/>
    </method>
    <method name="GetMenuForWindow">
      <arg name="windowId" type="u" direction="in"/>
      <arg name="service" type="s" direction="out"/>
      <arg name="menuObjectPath" type="o" direction="out"/>
    </method>
  </interface>
</node>]]
local registrar_info = Gio.DBusNodeInfo.new_for_xml(registrar_xml).interfaces[1]

local function on_registrar_call(_, sender, _, _, method, params, invocation)
    local window = params.value[1]
    if method == "RegisterWindow" then
        set_window_menu(window, sender, params.value[2])
        invocation:return_value(nil)
    elseif method == "UnregisterWindow" then
        set_window_menu(window, nil, nil)
        invocation:return_value(nil)
    elseif method == "GetMenuForWindow" then
        local service, path
        for _, c in ipairs(client.get()) do
            if c.window == window then service, path = get_client_menu(c) end
        end
        invocation:return_value(GLib.Variant("(so)", { service or "", path or "/" }))
    else
        invocation:return_dbus_error("org.freedesktop.DBus.Error.UnknownMethod", method)
    end
end

Gio.bus_own_name(Gio.BusType.SESSION, "com.canonical.AppMenu.Registrar",
    Gio.BusNameOwnerFlags.NONE,
    GObject.Closure(function(conn)
        conn:register_object("/com/canonical/AppMenu/Registrar", registrar_info,
            GObject.Closure(on_registrar_call), nil, nil)
    end),
    nil, nil)
-- }}}

-- {{{ dbusmenu client
local function dbusmenu_call(service, path, method, params, reply_type, callback)
    bus:call(service, path, DBUSMENU, method, params,
        reply_type and GLib.VariantType.new(reply_type), Gio.DBusCallFlags.NONE, 2000, nil,
        function(conn, res)
            local ret = conn:call_finish(res)
            if callback then callback(ret) end
        end)
end

-- Turns a (ia{sv}av) variant into { id, props, children }
local function parse_item(v)
    local item = { id = v:get_child_value(0):get_int32(), props = {}, children = {} }
    local props = v:get_child_value(1)
    for i = 0, props:n_children() - 1 do
        local entry = props:get_child_value(i)
        item.props[(entry:get_child_value(0):get_string())] = entry:get_child_value(1):get_variant().value
    end
    local children = v:get_child_value(2)
    for i = 0, children:n_children() - 1 do
        table.insert(item.children, parse_item(children:get_child_value(i):get_variant()))
    end
    return item
end

local function get_layout(service, path, parent, depth, callback)
    dbusmenu_call(service, path, "GetLayout", GLib.Variant("(iias)", { parent, depth, PROPS }),
        "(u(ia{sv}av))", function(ret)
            callback(ret and parse_item(ret:get_child_value(1)))
        end)
end

local function send_event(service, path, id)
    dbusmenu_call(service, path, "Event",
        GLib.Variant("(isvu)", { id, "clicked", GLib.Variant("i", 0), os.time() }))
end

-- dbusmenu uses "_" for mnemonics, awful.menu uses "&"
local function clean_label(label)
    return (label or ""):gsub("__", "\0"):gsub("_", "&"):gsub("%z", "_")
end

local function is_visible(item)
    return item.props.visible ~= false
end

local function to_awful_items(service, path, item)
    local items = {}
    for _, child in ipairs(item.children) do
        local p = child.props
        if is_visible(child) then
            if p.type == "separator" then
                table.insert(items, { "──────────" })
            else
                local label = clean_label(p.label)
                if p["toggle-type"] and p["toggle-state"] == 1 then
                    label = (p["toggle-type"] == "radio" and "● " or "✔ ") .. label
                end
                if p.enabled == false then
                    table.insert(items, { label })
                elseif #child.children > 0 or p["children-display"] == "submenu" then
                    table.insert(items, { label, to_awful_items(service, path, child) })
                else
                    table.insert(items, { label, function() send_event(service, path, child.id) end })
                end
            end
        end
    end
    return items
end
-- }}}

-- {{{ Widget
local appmenu = {}

local open_menu
local function show_menu(items, geo)
    if open_menu then open_menu:hide() end
    if #items == 0 then return end
    open_menu = awful.menu({ items = items, theme = { width = dpi(220) } })
    open_menu:show({ coords = { x = geo.x, y = geo.y } })
end

-- Screen coordinates just below the clicked widget
local function below(geometry)
    local wb = mouse.current_wibox
    return { x = wb.x + geometry.x, y = wb.y + wb.height }
end

local function make_button(text, on_click)
    local textbox = wibox.widget {
        markup = text,
        widget = wibox.widget.textbox,
    }
    local button = wibox.widget {
        textbox,
        left = dpi(6),
        right = dpi(6),
        widget = wibox.container.margin,
    }
    button:connect_signal("button::press", function(_, _, _, btn, _, geometry)
        if btn == 1 then on_click(below(geometry)) end
    end)
    return button
end

local function client_actions(c)
    return {
        { "Minimizar", function() c.minimized = true end },
        { c.maximized and "Restaurar" or "Maximizar", function() c.maximized = not c.maximized; c:raise() end },
        { c.floating and "Desativar flutuante" or "Flutuante", function() c.floating = not c.floating end },
        { c.ontop and "Desativar sempre no topo" or "Sempre no topo", function() c.ontop = not c.ontop end },
        { "Fechar", function() c:kill() end },
    }
end

function appmenu.new(s)
    local layout = wibox.layout.fixed.horizontal()
    local generation = 0
    local subscription

    local function unsubscribe()
        if subscription then
            bus:signal_unsubscribe(subscription)
            subscription = nil
        end
    end

    function layout:refresh()
        generation = generation + 1
        local current = generation
        unsubscribe()
        layout:reset()

        local c = client.focus
        if not c or c.screen ~= s then return end

        local name = gears.string.xml_escape(c.class or c.name or "")
        layout:add(make_button("<b>" .. name .. "</b>", function(geo)
            show_menu(client_actions(c), geo)
        end))

        local service, path = get_client_menu(c)
        if not service then return end

        get_layout(service, path, 0, 1, function(root)
            if not root or current ~= generation then return end
            for _, top in ipairs(root.children) do
                if is_visible(top) and top.props.label then
                    layout:add(make_button(gears.string.xml_escape((clean_label(top.props.label):gsub("&", ""))),
                        function(geo)
                            dbusmenu_call(service, path, "AboutToShow", GLib.Variant("(i)", { top.id }), "(b)",
                                function()
                                    get_layout(service, path, top.id, -1, function(item)
                                        if item then show_menu(to_awful_items(service, path, item), geo) end
                                    end)
                                end)
                        end))
                end
            end
        end)

        -- Apps such as Electron fill their menus after registering.
        subscription = bus:signal_subscribe(service, DBUSMENU, "LayoutUpdated", path, nil,
            Gio.DBusSignalFlags.NONE, function(_, _, _, _, _, params)
                if params:get_child_value(1):get_int32() == 0 then
                    gears.timer.delayed_call(function()
                        if current == generation then layout:refresh() end
                    end)
                end
            end)
    end

    instances[layout] = true
    layout:refresh()
    return layout
end

client.connect_signal("focus", refresh_all)
client.connect_signal("unfocus", function()
    gears.timer.delayed_call(function()
        if not client.focus then refresh_all() end
    end)
end)
client.connect_signal("property::class", function(c)
    if c == client.focus then refresh_all() end
end)
-- }}}

return appmenu
