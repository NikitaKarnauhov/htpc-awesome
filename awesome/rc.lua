-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local spawn = require("awful.spawn")
local posix = require('posix')
local gettext = require('gettext')
require("fade_to_wallpaper")
require("settings")

-- Settigns.
load_settings()

-- Locale.

if settings.locale then
    os.setlocale(settings.locale)
    posix.setenv("LC_ALL", settings.locale)
end

local gettext_domain = "htpc-awesome"
local gettext_domain_dir = gears.filesystem.get_xdg_data_home() .. "locale/"
gettext.bindtextdomain(gettext_domain, gettext_domain_dir)
gettext.textdomain(gettext_domain)

function set_language(locale_name)
    settings.locale = locale_name
    save_settings()
    os.setlocale(settings.locale)
    posix.setenv("LC_ALL", settings.locale)
end

-- Autostart.
local run_once_lock_file = os.getenv("XDG_RUNTIME_DIR") .. "/autostart." .. tostring(posix.getppid()) .. ".lock"
local run_once = posix.stat(run_once_lock_file) == nil
io.open(run_once_lock_file, "w"):close()

local function spawn_once(command)
    if run_once then
        spawn(command, false)
    end
end

spawn_once("xset s off -dpms")
spawn_once("picom --dbus")
spawn_once("scc-daemon --alone start")
spawn_once("kodi -fs")
spawn_once("lansinkd.sh")
spawn_once("onboard.sh start")

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Errors during startup",
        text = awesome.startup_errors
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Error",
            text = tostring(err)
        })
        in_error = false
    end)
end

beautiful.init(gears.filesystem.get_configuration_dir() .. "theme/theme.lua")

modkey = "Mod4"

awful.layout.layouts = {
    awful.layout.suit.fair
}

-- Fullscreen unredirection.

awesome.register_xproperty("_NET_WM_BYPASS_COMPOSITOR", "number")

function get_bypass_compositor(c)
    local cl = c or client.focus
    if not cl then
        return 0
    end

    local value = cl:get_xproperty("_NET_WM_BYPASS_COMPOSITOR")
    if value ~= nil and value >= 1 and value <= 2 then
        return value
    end

    return 0
end

function set_bypass_compositor(c, value)
    local cl = c or client.focus
    if not cl then
        return nil
    end

    if value ~= nil then
        cl:set_xproperty("_NET_WM_BYPASS_COMPOSITOR", value)
    end
end

local function get_default_bypass_compositor(c)
    local cl = c or client.focus
    if not cl then
        return nil
    end

    if cl.class == "Kodi" then
        return 2
    end

    return nil
end

local function set_default_bypass_compositor(c)
    local cl = c or client.focus
    if not cl then
        return
    end

    local value = get_default_bypass_compositor(cl)
    if value ~= nil then
        set_bypass_compositor(cl, value)
    end
end

-- Controller profiles.

awesome.register_xproperty("STEAM_GAME", "number")

local current_profile = nil

local function set_profile(profile)
    if profile == current_profile then
        return
    end
    current_profile = profile
    spawn("scc set-profile " .. profile, false)
    if profile ~= "Desktop" then
        spawn({"onboard.sh", "hide"}, false)
    end
end

local client_profiles = {}

local function get_client_auto_profile(cl)
    if not cl then
        return ""
    end

    if cl.class == "Kodi" then
        return "Kodi"
    elseif (cl.class == "RPCS3" and string.find(cl.name, "FPS")) then
        return "RPCS3"
    elseif (cl.class == "dolphin-emu" and string.find(cl.name, "JIT64")) or
        cl.class == "PPSSPPSDL" or
        cl.class == "pegasus-frontend" or
        (cl.class == "steam" and cl.name == "Steam") or
        cl:get_xproperty("STEAM_GAME") then
        return "XBoxController"
    else
        return "Desktop"
    end
end

local function get_client_custom_profile(cl)
    if cl then
        cp = client_profiles[cl.window]
        if cp then
            return cp
        end
    end

    return ""
end

local function get_client_profile(cl)
    local cp = get_client_custom_profile(cl)

    if cp ~= "" then
        return cp
    end

    return get_client_auto_profile(cl)
end

function set_client_profile(cl, profile)
    client_profiles[cl.window] = profile
end

local is_rofi_running = false

local function update_profile()
    if is_rofi_running then
        set_profile("Desktop")
        return
    end

    local cl = client.focus

    if not cl or not cl.fullscreen then
        if cl and cl.floating then
            local cls = awful.client.visible()
            for _, c in ipairs(cls) do
                -- A dialog above fullscreen client.
                if c.fullscreen then
                    set_profile("Desktop")
                    return
                end
            end
        end
        set_profile("Overview")
        return
    end

    set_profile(get_client_profile(cl))
end

set_profile("Overview")

-- Rounded rects.

local function small_rounded_rect(cr, width, height)
    gears.shape.rounded_rect(cr, width, height, 8)
end

local function large_rounded_rect(cr, width, height)
    gears.shape.rounded_rect(cr, width, height, 10)
end

-- Wallpaper.

local current_wallpaper = ""

-- Load wallpaper name from settings.
if settings.wallpaper_name then
    beautiful.wallpaper_name = settings.wallpaper_name
end

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        if wallpaper ~= current_wallpaper then
            if #current_wallpaper > 0 then
                fade_to_wallpaper(wallpaper, 120, 1/60, function(surf)
                    gears.wallpaper.maximized(surf, s, true)
                end)
            else
                gears.wallpaper.maximized(wallpaper, s, true)
            end
            current_wallpaper = wallpaper
        end
    end
end

function set_wallpaper_name(name)
    beautiful.wallpaper_name = name
    set_wallpaper()
    settings.wallpaper_name = name
    save_settings()
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution).
screen.connect_signal("property::geometry", set_wallpaper)

-- Re-set wallpaper every 10 minutes.
gears.timer {
    timeout   = 600,
    call_now  = true,
    autostart = true,
    callback  = function()
        set_wallpaper(nil)
    end
}

function show_wallpaper_menu()
    spawn({"rofi-wallpaper-menu.sh", beautiful.wallpaper_dir}, false)
end

-- Prefer Papyrus icons.

local function find_icon(name)
    if not name then
        return nil
    end

    local paths = {
        gears.filesystem.get_configuration_dir(),
        "/usr/share/icons/Papirus/64x64/apps/",
        gears.filesystem.get_xdg_data_home() .. "icons/"
    }
    local names = {name, name:lower()}

    for _, path in ipairs(paths) do
        for _, filename in ipairs(names) do
            local f = path .. filename .. ".svg"
            if posix.stat(f) then
                return f
            end
        end
    end

    return nil
end

-- Launcher button.

local launcher = function(args)
    local launcher_args = {
        command = args.command,
        fullscreen = args.fullscreen or false
    }

    function launcher_args:execute()
        if args.fullscreen then
            spawn(self.command, {fullscreen = true})
        else
            spawn(self.command, false)
        end
    end

    local launcher_widget = awful.widget.button{
        image = args.image
    }

    local background_widget = {
        {
            launcher_widget,
            top = 8,
            bottom = 8,
            left = 8,
            right = 8,
            widget = wibox.container.margin
        },
        shape_border_width = 4,
        shape = small_rounded_rect,
        widget = wibox.container.background
    }

    local w = wibox.widget{
        background_widget,
        buttons = awful.button({ }, 1, nil, function()
            launcher_args:execute()
        end),
        widget = wibox.container.place
    }

    function w:set_focused(is_focused)
        local background_widget = self:get_children()[1]
        if is_focused then
            background_widget.bg                 = beautiful.bg_focus
            background_widget.shape_border_color = beautiful.border_focus
        else
            background_widget.bg                 = gears.color.transparent
            background_widget.shape_border_color = gears.color.transparent
        end
    end

    function w:set_icon(icon)
        launcher_widget.image = icon
    end

    function w:set_command(command)
        launcher_args.command = command
    end

    function w:execute()
        launcher_args:execute()
    end

    return w
end

-- Right-side buttons (defined later).

local controls = nil

-- Left-side buttons.

local function make_launchers(args)
    local launchers = {
        layout = wibox.layout.fixed.horizontal,
        focused_index = 0
    }

    for index, launcher in ipairs(args) do
        launchers[index] = launcher
    end

    for key, launcher in pairs(args) do
        launchers[key] = launcher
    end

    function launchers:get_focused()
        return self.focused_index
    end

    function launchers:set_focused(focused_index)
        for index, launcher in ipairs(self) do
            launcher:set_focused(index == focused_index)
        end
        if focused_index >= 1 and focused_index <= #self then
            current = client.focus
            if current then
            awful.client.focus.history.add(current)
            client.focus = nil
            end
            self.focused_index = focused_index
            set_profile("Overview")
        else
            self.focused_index = 0
        end
    end

    function launchers:is_focused()
        return self.focused_index >= 1 and self.focused_index <= #self
    end

    function launchers:execute_focused()
        if self.focused_index >= 1 and self.focused_index <= #self then
            self[self.focused_index]:execute()
        end
    end

    function launchers:focus_left()
        if self.focused_index > 1 then
            self:set_focused(self.focused_index - 1)
        elseif self.focus_exit_left then
            self:set_focused(0)
            self.focus_exit_left()
        end
    end

    function launchers:focus_right()
        if self.focused_index < #self then
            self:set_focused(self.focused_index + 1)
        elseif self.focus_exit_right then
            self:set_focused(0)
            self.focus_exit_right()
        end
    end

    function launchers:set_icon(index, icon)
        self[index]:set_icon(icon)
    end

    function launchers:set_command(index, command)
        self[index]:set_command(command)
    end

    for index, launcher in ipairs(launchers) do
        launcher:connect_signal("mouse::enter", function() launchers:set_focused(index) end)
        launcher:connect_signal("mouse::leave", function() launchers:set_focused(0) end)
    end

    return launchers
end

local local_bin_dir = os.getenv("HOME") .. '/.local/bin/'

local launchers = make_launchers({
    launcher{
        image   = find_icon("applications-all"),
        command = local_bin_dir .. "rofi-applications-menu.sh",
    },
    launcher{
        image   = find_icon("kodi"),
        command = "/usr/bin/kodi",
    },
    launcher{
        image   = find_icon("pegasus-fe"),
        command = local_bin_dir .. "pegasus-fe",
    },
    launcher{
        image   = find_icon("steam"),
        command = local_bin_dir .. "steam",
    },
    launcher{
        image   = find_icon("youtube"),
        command = "/usr/bin/dex-autostart " .. gears.filesystem.get_xdg_data_home() .. "applications/youtube.desktop",
        fullscreen = true,
    },
    launcher{
        image   = find_icon("yandex_music"),
        command = "/usr/bin/dex-autostart " .. gears.filesystem.get_xdg_data_home() .. "applications/yandex_music.desktop",
        fullscreen = true,
    },
    launcher{
        image   = find_icon("kinopoisk"),
        command = "/usr/bin/dex-autostart " .. gears.filesystem.get_xdg_data_home() .. "applications/kinopoisk.desktop",
        fullscreen = true,
    },
    launcher{
        image   = find_icon("okko"),
        command = "/usr/bin/dex-autostart " .. gears.filesystem.get_xdg_data_home() .. "applications/okko.desktop",
        fullscreen = true,
    },
    launcher{
        image   = find_icon("beeline_tv"),
        command = "/usr/bin/dex-autostart " .. gears.filesystem.get_xdg_data_home() .. "applications/beeline_tv.desktop",
        fullscreen = true,
    },
    focus_exit_left = function()
        controls:set_focused(#controls)
    end,
    focus_exit_right = function()
        controls:set_focused(1)
    end
})

launchers:set_focused(0)

-- Bluetooth.

spawn(gears.filesystem.get_configuration_dir() .. "bluetooth-monitor.py", false)

local bluetooth_powered_on = false

local function get_bluetooth_icon()
    if bluetooth_powered_on then
        return find_icon("bluetooth-on")
    else
        return find_icon("bluetooth-off")
    end
end

function handle_bluetooth_power(value)
    bluetooth_powered_on = value
    controls:set_icon(1, get_bluetooth_icon())
    controls:set_command(1, {"rofi-bluetooth-menu.sh", tostring(bluetooth_powered_on)})
end

-- Right-side buttons.

controls = make_launchers({
    launcher{
        image   = get_bluetooth_icon(),
        command = "rofi-bluetooth-menu.sh",
    },
    launcher{
        image   = find_icon("systemsettings"),
        command = "rofi-settings-menu.sh",
    },
    launcher{
        image   = find_icon("system-shutdown"),
        command = "rofi-power-menu.sh",
    },
    focus_exit_left = function()
        launchers:set_focused(#launchers)
    end,
    focus_exit_right = function()
        launchers:set_focused(1)
    end
})

controls:set_focused(0)

-- Top bar.

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "" }, s, awful.layout.layouts[1])

    s.mywibox = awful.wibar({
        position = "top",
        screen = s,
        height = 116,
        bg = gears.color.transparent
    })

    s.mywibox:setup {
        {
            {
                {
                    layout = wibox.layout.align.horizontal,
                    launchers,
                    nil,
                    {
                        layout = wibox.layout.fixed.horizontal,
                        wibox.widget.systray(),
                        {
                            wibox.widget.textclock('<span font="Play 30">%H:%M</span>', 5),
                            left = 8,
                            right = 8,
                            bottom = 4,
                            widget = wibox.container.margin
                        },
                        controls
                    }
                },
                top = 8,
                bottom = 8,
                left = 8,
                right = 8,
                widget = wibox.container.margin
            },
            bg = {
                type = "linear",
                from = {0, 0},
                to = {1280, 0},
                stops = {
                    {0.0, "#00000040"},
                    {0.25,"#00000040"},
                    {0.75, beautiful.bg_systray},
                    {1.0, beautiful.bg_systray}
                }
            },
            shape = large_rounded_rect,
            widget = wibox.container.background
        },
        top = 30,
        bottom = 0,
        left = 40,
        right = 40,
        widget = wibox.container.margin
    }
end)

local function client_set_fullscreen(cl, is_fullscreen)
    if cl.fullscreen == is_fullscreen then
        return
    end
    if cl.class == "Kodi" then
        spawn("kodi-send --action=togglefullscreen", false)
    else
        cl.fullscreen = is_fullscreen
    end
end

function client_toggle_fullscreen(c)
    cl = c or client.focus
    if cl then
        client_set_fullscreen(cl, not cl.fullscreen)
        cl:raise()
    end
end

local close_times = {}

function client_close(c)
    cl = c or client.focus
    if cl then
        ct = close_times[cl.window]
        t = os.time()
        if ct and t - ct >= 2 then
            close_times[cl.window] = nil
            spawn("xkill -id " .. tostring(cl.window), false)
        else
            close_times[cl.window] = t
            cl:kill()
        end
    end
end

function handle_a_button()
    local cl = client.focus
    if cl then
        client_toggle_fullscreen(cl)
    elseif launchers:is_focused() then
        launchers:execute_focused()
    elseif controls:is_focused() then
        controls:execute_focused()
    end
end

local function client_menu_button(cl)
    local button = awful.titlebar.widget.button(cl, "client_menu", function(c)
        return true
    end, function(c, state)
        client_show_menu(c)
    end)

    return {
        {
            button,
            wibox.widget{
                text = _("Menu"),
                valign = "center",
                widget = wibox.widget.textbox
            },
            layout = wibox.layout.fixed.horizontal()
        },
        bottom = 8,
        widget = wibox.container.margin
    }
end

local function maximize_button(cl)
    if cl:is_fixed() then
        return nil
    end

    local button = awful.titlebar.widget.button(cl, "maximized", function(c)
        return c.fullscreen
    end, function(c, state)
        c.fullscreen = not state
        c:raise()
    end)

    cl:connect_signal("property::fullscreen", button.update)

    return {
        {
            button,
            wibox.widget{
                text = _("Maximize"),
                valign = "center",
                widget = wibox.widget.textbox
            },
            layout = wibox.layout.fixed.horizontal()
        },
        bottom = 8,
        widget = wibox.container.margin
    }
end

local steam_rule = {
    type = "normal",
    class = "steam",
    instance = "steam"
}

local origin_overlay_rule = {
    name = "Origin",
    class = "^steam_app_",
    skip_taskbar = true
}

function should_add_titlebar(c)
    if awful.rules.match(c, origin_overlay_rule) then
        return false
    end

    if awful.rules.match(c, steam_rule) then
        return true
    end

    if c.requests_no_titlebar then
        return false
    end

    return c.type == "normal"
end

local function update_titlebar(c)
    if not should_add_titlebar(c) then
        return
    end

    local t = awful.titlebar(c, "top")
    t:setup {
        maximize_button(c),
        client_menu_button(c),
        {
            {
                awful.titlebar.widget.closebutton(c),
                wibox.widget{
                    text = _("Close"),
                    valign = "center",
                    widget = wibox.widget.textbox
                },
                layout = wibox.layout.fixed.horizontal()
            },
            bottom = 8,
            widget = wibox.container.margin
        },
        expand = "none",
        layout = wibox.layout.align.horizontal
    }
end

function unfullscreen_all()
    local cls = awful.client.visible()
    for _, cl in ipairs(cls) do
        client_set_fullscreen(cl, false)
    end
    local cl = client.focus
    if cl then
        update_titlebar(cl)
    end
end

function focus_left()
    if client.focus then
        awful.client.focus.bydirection("left")
        client.focus:raise()
    elseif launchers:is_focused() then
        launchers:focus_left()
    elseif controls:is_focused() then
        controls:focus_left()
    end
end

function focus_right()
    if client.focus then
        awful.client.focus.bydirection("right")
        client.focus:raise()
    elseif launchers:is_focused() then
        launchers:focus_right()
    elseif controls:is_focused() then
        controls:focus_right()
    end
end

function focus_up()
    current = client.focus
    if current then
        awful.client.focus.bydirection("up")
        client.focus:raise()
    end
    if client.focus == current then
        launchers:set_focused(1)
    end
end

function focus_down()
    if client.focus then
        awful.client.focus.bydirection("down")
        client.focus:raise()
    elseif launchers:is_focused() or controls:is_focused() then
        launchers:set_focused(0)
        controls:set_focused(0)
        client.focus = awful.client.focus.history.get(1, 0, nil)
        if client.focus then
            client.focus:raise()
        end
    end
end

function focus_prev_client()
    local cls = awful.client.visible()
    if #cls == 0 then
        return
    end
    local prev = cls[#cls]
    for _, cl in ipairs(cls) do
        if cl == client.focus then
            break
        end
        prev = cl
    end
    client.focus = prev
    client.focus:raise()
end

function focus_next_client()
    local cls = awful.client.visible()
    if #cls == 0 then
        return
    end
    local prev = cls[#cls]
    for _, cl in ipairs(cls) do
        if prev == client.focus then
            client.focus = cl
            client.focus:raise()
            break
        end
        prev = cl
    end
end

local function is_webapp_client(cl)
    return cl.instance == "Navigator" and cl.class ~= "firefox"
end

local function adjust_webapp_name(text)
    local suffix_pos = text:find("%S+%sMozilla Firefox")
    if suffix_pos and suffix_pos > 1 then
        return text:sub(1, suffix_pos - 1)
    end
    return nil
end

local function get_client_name(cl)
    -- Strip Firefox window title suffix from webapps.
    if is_webapp_client(cl) then
        local text = adjust_webapp_name(cl.name)
        if text then
            return text
        end
    end
    return cl.name
end

function client_show_menu(c)
    local cl = c or client.focus
    if not cl then
        return
    end

    local custom_profile = get_client_custom_profile(cl)
    local auto_profile = get_client_auto_profile(cl)
    local bypass_compositor = tostring(get_bypass_compositor(cl))
    spawn({"rofi-client-menu.sh", get_client_name(cl), custom_profile, auto_profile, tostring(cl.fullscreen), bypass_compositor}, false)
end

-- Functions called from Rofi scripts.

rofi_target_client = nil

local rofi_target_launcher_index = 0
local rofi_target_control_index = 0
local rofi_submenu_function = nil

function handle_rofi_start()
    if rofi_submenu_function then
        rofi_submenu_function = nil
        return
    end

    is_rofi_running = true

    rofi_target_client = client.focus
    if rofi_target_client then
        -- awful.client.focus.history.add(rofi_target_client)
        client.focus = nil
    end

    rofi_target_launcher_index = launchers:get_focused()
    if rofi_target_launcher_index > 0 then
        launchers:set_focused(0)
    end

    rofi_target_control_index = controls:get_focused()
    if rofi_target_control_index > 0 then
        controls:set_focused(0)
    end

    update_profile()
end

function handle_rofi_submenu(submenu_function)
    rofi_submenu_function = submenu_function
end

function handle_rofi_finish()
    if rofi_submenu_function then
        rofi_submenu_function()
        return
    end

    is_rofi_running = false

    if not client.focus and rofi_target_client then
        client.focus = rofi_target_client
    elseif rofi_target_launcher_index > 0 then
        launchers:set_focused(rofi_target_launcher_index)
    elseif rofi_target_control_index > 0 then
        controls:set_focused(rofi_target_control_index)
    end

    update_profile()
end

-- Key bindings and mouse events.

globalkeys = gears.table.join(
    awful.key({modkey}, "Left", focus_left),
    awful.key({modkey}, "Right", focus_right),
    awful.key({modkey}, "Up", focus_up),
    awful.key({modkey}, "Down", focus_down),
    awful.key({modkey}, "a", handle_a_button),
    awful.key({modkey}, "y", unfullscreen_all),
    awful.key({modkey}, "[", focus_prev_client),
    awful.key({modkey}, "]", focus_next_client)
)

clientkeys = gears.table.join(
    awful.key({modkey}, "b", client_close)
)

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

root.keys(globalkeys)

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    {
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred
        }
    },

    -- Floating clients.
    {
        rule_any = {
            instance = {
              "DTA",    -- Firefox addon DownThemAll.
              "copyq",  -- Includes session name in class.
              "pinentry",
            },
            class = {
              "Arandr",
              "Blueman-manager",
              "Gpick",
              "Kruler",
              "MessageWin",  -- kalarm.
              "Sxiv",
              "Tor Browser", -- Needs a fixed window size to avoid fingerprinting by screen size.
              "Wpa_gui",
              "veromix",
              "xtightvncviewer"
            },
            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = {
              "Event Tester",  -- xev.
            },
            role = {
              "AlarmWindow",    -- Thunderbird's calendar.
              "ConfigManager",  -- Thunderbird's about:config.
              "pop-up",         -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true }
    },

    -- Add titlebars to normal clients.
    {
        rule = {
            type = "normal"
        },
        except = {
            requests_no_titlebar = true
        },
        properties = {
            titlebars_enabled = true
        }
    },

    -- Add titlebars to Steam window anyway.
    {
        rule = {
            type = "normal",
            class = "steam",
            instance = "steam"
        },
        properties = {
            titlebars_enabled = true
        }
    },

    -- Proton dialogs.
    {
        rule = {
            class = "steam_proton"
        },
        properties = {
           floating = true,
        }
    },

    -- Main origin window.
    {
        rule = {
            name = "Origin",
            class = "^steam_app_"
        },
        properties = {
           floating = true,
        }
    },

    -- Origin overlay windows.
    {
        rule = origin_overlay_rule,
        properties = {
           titlebars_enabled = false,
           hidden = true
        }
    },

    -- Onboard
    {
        rule = {
            class = "Onboard"
        },
        properties = {
           titlebars_enabled = false,
           floating = true,
           focusable = false
        }
    },
}

--
-- Window borders and signals
--

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end

    if not c.fullscreen then
        c.shape = large_rounded_rect
    end

    set_default_bypass_compositor(c)

    close_times[c.window] = nil
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    local iconwidget = nil
    local custom_icon = find_icon(c.class)

    if custom_icon then
        iconwidget = wibox.widget {
            image  = custom_icon,
            resize = true,
            widget = wibox.widget.imagebox
        }
    else
        iconwidget = awful.titlebar.widget.iconwidget(c)
    end

    local titlewidget = awful.titlebar.widget.titlewidget(c)

    if is_webapp_client(c) then
        titlewidget:connect_signal("widget::redraw_needed", function(w)
            local adjusted_text = adjust_webapp_name(titlewidget.text)
            if adjusted_text then
                titlewidget.text = adjusted_text
            end
        end)
    end

    awful.titlebar(c, { size = 40, position = "top" })
    awful.titlebar(c, { size = 40, position = "bottom" }):setup {
        { -- Left
            {
                iconwidget,
                top = 8,
                right = 8,
                widget = wibox.container.margin
            },
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            {
                { -- Title
                    align  = "center",
                    widget = titlewidget
                },
                top = 8,
                widget = wibox.container.margin
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        nil,
        layout = wibox.layout.align.horizontal
    }
end)

-- Disable toolptips.
awful.titlebar.enable_tooltip = false

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if not client.focus then
        c:emit_signal("request::activate", "mouse_enter", {raise = true})
    end
end)

client.connect_signal("property::fullscreen", function(c)
    if c.fullscreen then
        c.shape = nil
        c.opacity = 1
    else
        c.border_width = 10
        c.shape = large_rounded_rect
        if c ~= client.focus then
            c.opacity = 0.75
        end
    end
    update_profile()
end)

client.connect_signal("focus", function(c)
    launchers:set_focused(0)
    controls:set_focused(0)
    c.border_color = beautiful.border_focus
    c.opacity = 1
    update_titlebar(c)
    update_profile()
end)

client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal

    if not c.fullscreen then
        c.opacity = 0.75
    end

    if not should_add_titlebar(c) then
        return
    end

    local t = awful.titlebar(c, "top")
    t:setup {
        nil,
        nil,
        nil,
        layout = wibox.layout.align.horizontal
    }
end)

client.connect_signal("unmanage", function(c)
    update_profile()
end)
