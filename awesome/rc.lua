-- agony and despair

pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")

local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")

require("awful.hotkeys_popup.keys")

if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical, title = "Oops, there were errors during startup!", text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical, title = "Oops, an error happened!", text = tostring(err) })
        in_error = false
    end)
end

beautiful.titlebar_bg_normal = "#121212"
beautiful.titlebar_fg_normal = "#404040"
beautiful.titlebar_bg_focus  = "#151515"
beautiful.titlebar_fg_focus  = "#ffffff"
beautiful.border_width       = 1
beautiful.border_normal      = "#121212"
beautiful.border_focus       = "#202020"

naughty.config.defaults.bg   = "#151515"
naughty.config.defaults.fg   = "#FFFFFF"
naughty.config.defaults.border_color = "#202020"
naughty.config.defaults.border_width = 1
naughty.config.defaults.icon_size = 32
naughty.config.defaults.width = 400
naughty.config.defaults.max_width = 400
naughty.config.defaults.opacity = 0.9

terminal = "kitty"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

modkey = "Mod4"

awful.layout.layouts = {
    awful.layout.suit.floating,
}

myawesomemenu = {
   { "Hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "Manual", terminal .. " -e man awesome" },
   { "Edit config", editor_cmd .. " " .. awesome.conffile },
   { "Respring", awesome.restart },
   { "Quit", function() awesome.quit() end },
}

mymainmenu = awful.menu({ items = {
    { "Window Manager", myawesomemenu, beautiful.awesome_icon },
    { "Open terminal", terminal }
} })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })

menubar.utils.terminal = terminal

mytextclock = wibox.widget.textclock()

local function set_wallpaper(s)
    gears.wallpaper.maximized(os.getenv("HOME") .. "/.config/awesome/background.jpg", s, true)
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    awful.tag({ "1" }, s, awful.layout.layouts[1])

    s.mypromptbox = awful.widget.prompt()
end)

root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))

globalkeys = gears.table.join(
    awful.key({ modkey, }, "s", hotkeys_popup.show_help, { description="Show keybinds", group="awesome" }),
    awful.key({ modkey, }, "Tab", function() awful.spawn("rofi -show window") end, { description = "window switcher", group = "launcher" }),

    awful.key({ modkey, "Shift" }, "s",
    function()
        local random_str = tostring(math.random(100000, 999999))
        local tmpfile = "/tmp/screenshot_selection_" .. random_str .. ".png"
        local cmd = "/usr/bin/maim --select " .. tmpfile .. " && xclip -selection clipboard -t image/png -i " .. tmpfile .. " && rm " .. tmpfile
        awful.spawn.easy_async_with_shell(cmd, function()
            naughty.notify({ title = "Screenshot taken", text = "Selection copied to clipboard", timeout = 2 })
        end)
    end, {description = "Take a screenshot of a selection", group = "launcher"}),
    awful.key({ "Control", "Shift" }, "s",
    function()
        local random_str = tostring(math.random(100000, 999999))
        local tmpfile = "/tmp/screenshot_full_" .. random_str .. ".png"
        local cmd = "/usr/bin/maim " .. tmpfile .. " && xclip -selection clipboard -t image/png -i " .. tmpfile .. " && rm " .. tmpfile
        awful.spawn.easy_async_with_shell(cmd, function()
            naughty.notify({ title = "Screenshot taken", text = "Full screenshot copied to clipboard", timeout = 2 })
        end)
    end, {description = "Take a full screenshot", group = "launcher"}),

    awful.key({ "Control", "Shift" }, "r",
    function()
        local random_str = tostring(math.random(100000, 999999))
        local tmpfile = "/tmp/screenshot_delayed_" .. random_str .. ".png"
        local cmd = "sleep 3 && /usr/bin/maim " .. tmpfile .. " && xclip -selection clipboard -t image/png -i " .. tmpfile .. " && rm " .. tmpfile
        awful.spawn.easy_async_with_shell(cmd, function()
            naughty.notify({ title = "Screenshot taken", text = "Delayed full screenshot copied to clipboard", timeout = 2 })
        end)
    end, {description = "Take a delayed (3s) full screenshot", group = "launcher"}),

    awful.key({ modkey, "Shift" }, "r",
    function()
        awful.spawn.easy_async_with_shell("slop -f '%x %y %w %h'", function(stdout)
            local x, y, w, h = stdout:match("(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
            if not (x and y and w and h) then
                naughty.notify({ title = "❌ Recording failed", text = "Could not get region from slop", timeout = 2 })
                return
            end

            naughty.notify({ title = "🎥 Recording started", text = "Recording selected region...", timeout = 4 })

            local output_file = os.date(os.getenv("HOME") .. "/Videos/recording_%F_%H-%M-%S.mkv")
            local cmd = string.format(
                'ffmpeg -y -video_size %sx%s -framerate 60 -f x11grab -i :0.0+%s,%s -preset ultrafast "%s" & echo $! > /tmp/ffmpeg_recording.pid',
                w, h, x, y, output_file
            )

            awful.spawn.with_shell(cmd)
        end)
    end, {description = "Start screen recording of selected area", group = "custom"}),
    awful.key({ modkey, "Shift" }, "e",
    function()
        local output_file = os.date(os.getenv("HOME") .. "/Videos/recording_%F_%H-%M-%S.mkv")
        local script = string.format([[
            tmp_pid_file="/tmp/ffmpeg_recording.pid"
            if [ -f "$tmp_pid_file" ]; then
                kill "$(cat "$tmp_pid_file")" && rm "$tmp_pid_file"
            fi
            echo "%s" > /tmp/last_recording_path
        ]], output_file)

        awful.spawn.easy_async_with_shell(script, function()
            naughty.notify({
                title = "🛑 Recording stopped",
                text = "Click to open with mpv",
                timeout = 5,
            })
        end)
    end, {description = "Stop screen recording", group = "custom"}),


    awful.key({ modkey, }, "Return", function () awful.spawn(terminal) end, { description = "Open a terminal", group = "launcher" }),
    awful.key({ modkey, "Control" }, "r", awesome.restart, { description = "Respring", group = "awesome" }),
    awful.key({ modkey, }, "space", function() awful.spawn("rofi -show drun") end, { description = "Spotlight", group = "launcher" }),

    awful.key({ modkey, "Control" }, "n", function ()
        local c = awful.client.restore()
        if c then
            c:emit_signal("request::activate", "key.unminimize", {raise = true})
        end
    end, { description = "Restore minimized", group = "client" }),

    awful.key({ modkey, }, "w", function() awful.spawn(os.getenv("HOME") .. "/.config/rofi/rofi-wifi-menu.sh") end, { description = "Spotlight", group = "launcher" }),
    awful.key({ modkey, }, ".", function() awful.spawn(os.getenv("HOME") .. "/.config/rofi/rofi-emoji-picker.sh") end, { description = "Spotlight", group = "launcher" })
)

clientkeys = gears.table.join(
    awful.key({ modkey, }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end, { description = "Toggle fullscreen", group = "client" }),

    awful.key({ modkey }, "q", function (c) c:kill() end, { description = "Quit application", group = "client" }),
    awful.key({ modkey, }, "n", function (c) c.minimized = true end, { description = "Minimize", group = "client" }),
    awful.key({ modkey, }, "m", function (c) c.maximized = not c.maximized c:raise() end, { description = "(Un)maximize", group = "client" })
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

awful.rules.rules = {
    {
        rule = { },
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen
        }
    },
    {
        rule_any = {
            instance = {
                "DTA",  -- Firefox addon DownThemAll.
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
            name = {
                "Event Tester",  -- xev.
            },
            role = {
                "AlarmWindow",  -- Thunderbird's calendar.
                "ConfigManager",  -- Thunderbird's about:config.
                "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
            }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    {
        rule_any = {
            type = { "normal", "dialog" }
        },
        properties = { titlebars_enabled = true }
    },
    {
        rule = { class = "farcry5.exe" },
        properties = {
            floating = true,
            fullscreen = true,
            focus = true,
            ontop = true,
            placement = awful.placement.centered
        }
    },
}

client.connect_signal("manage", function (c)
    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

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

    awful.titlebar(c):setup {
        { -- Left
            layout  = wibox.layout.fixed.horizontal,
            buttons = buttons,
            bg      = bg_color,
            fg      = fg_color,
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c),
                font   = "monospace 8",
                bg     = bg_color,
                fg     = fg_color,
            },
            layout  = wibox.layout.flex.horizontal,
            buttons = buttons,
            bg      = bg_color,
            fg      = fg_color,
        },
        { -- Right
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal,
            bg     = bg_color,
            fg     = fg_color,
        },
        layout = wibox.layout.align.horizontal,
        bg = bg_color,
        fg = fg_color,
    }
end)


client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

naughty.connect_signal("destroyed", function(n, reason)
    if reason == require("naughty.constants").notification_closed_reason.dismissed_by_user then
        if n.title == "🛑 Recording stopped" then
            awful.spawn("mpv --geometry=1280x720 $(cat /tmp/last_recording_path)", false)
        end

        if not n.clients then return end
        local jumped = false
        for _, c in ipairs(n.clients) do
            c.urgent = true
            if jumped then
                c:activate{ context = "client.jumpto" }
            else
                c:jump_to()
                jumped = true
            end
        end
    end
end)

awful.spawn.with_shell("picom --config ~/.config/picom/picom.conf &")
awful.spawn.with_shell("killall -q polybar; polybar example &")