local _ENV = require("stdlib")

local awesome = require("awesome")
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup.widget")
local naughty = require("naughty")
local wibox = require("wibox")

require("awful.autofocus")

local systembar = require("systembar")



-- Handle runtime errors after startup
do
    local in_error = false
    awesome.core.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end



-- Themes define colours, icons, font and wallpapers.
beautiful.init(awful.util.get_themes_dir() .. "default/theme.lua")
gears.wallpaper.set("solid:black")



-- This is used later as the default terminal and editor to run.
local terminal = "alacritty"
local editor = "vim"
local editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    --awful.layout.suit.spiral,
    --awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    --awful.layout.suit.max.fullscreen,
    --awful.layout.suit.magnifier,
    --awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
    awful.layout.suit.floating
}



-- the names of the 24 tags
-- these match the keys used to activate them
local tagNames = {
    "1", "2", "3", "4", "5", "6",
    "7", "8", "9", "0", "-", "+",
    "^1", "^2", "^3", "^4", "^5", "^6",
    "^7", "^8", "^9", "^0", "^-", "^+"
}

-- the 12 keycodes used to activate tags
-- these are combined with Ctrl for the second set of 12 tags
local tagKeyCodes = {
    "#10", "#11", "#12", "#13", "#14", "#15",
    "#16", "#17", "#18", "#19", "#20", "#21"
}

-- create tags and set up their key bindings
local tagKeys = {}
for index, name in ipairs(tagNames) do
    local key = index > 12 and tagKeyCodes[index - 12] or tagKeyCodes[index]
    local ctrl = index > 12 and "Control" or nil

    local tag = awful.tag.add(name, {
        index  = index,
        screen = awesome.screen.primary,
        layout = awful.layout.layouts[1],
        selected = (index == 1)
    })

    tagKeys = gears.table.join(tagKeys,
        -- Super+key: display tag exclusively
        awful.key({ modkey, ctrl }, key,
            function ()
                tag.screen = awful.screen.focused()
                tag:view_only()
            end,
            {description = "view tag " .. name, group = "tag"}
        ),

        -- Super+Alt+key: toggle tag display
        awful.key({ modkey, "Mod1", ctrl }, key,
            function ()
                local screen = awful.screen.focused()
                local selected = tag.screen ~= screen or not tag.selected
                tag.screen = screen
                tag.selected = selected
            end,
            {description = "toggle tag " .. name, group = "tag"}
        ),

        -- Super+Shift+key: set tag exclusively on focused client
        awful.key({ modkey, "Shift", ctrl }, key,
            function ()
                if awesome.client.focus then
                    awesome.client.focus:move_to_tag(tag)
                end
            end,
            {description = "move focused client to tag " .. name, group = "tag"}
        ),

        -- Super+Shift+Alt+key: toggle tag on focused client
        awful.key({ modkey, "Shift", "Mod1", ctrl }, key,
            function ()
                if awesome.client.focus then
                    awesome.client.focus:toggle_tag(tag)
                end
            end,
            {description = "toggle focused client on tag " .. name, group = "tag"}
        )
    )
end




awful.screen.connect_for_each_screen(function(screen)
    screen.x_systembar = systembar(screen)
end)




awesome.root.keys(gears.table.join(
    awful.key({modkey}, "Escape",
        awesome.core.restart,
        {description = "reload awesome", group = "awesome"}
    ),

    awful.key({modkey, "Shift"}, "Escape",
        awesome.core.quit,
        {description = "quit awesome", group = "awesome"}
    ),

    awful.key({modkey, "Shift"}, "/",
        hotkeys_popup.show_help,
        {description="show help", group="awesome"}
    ),

    awful.key({modkey}, "b",
        function () awful.spawn("xscreensaver-command -lock") end,
        {description="lock screen", group="awesome"}
    ),
        


    awful.key({modkey}, "j",
        function() awful.client.focus.byidx( 1) end,
        {description = "focus next by index", group = "client"}
    ),

    awful.key({modkey}, "k",
        function() awful.client.focus.byidx(-1) end,
        {description = "focus previous by index", group = "client"}
    ),


    awful.key({modkey, "Shift"}, "j",
        function() awful.client.swap.byidx(1) end,
        {description = "swap with next client by index", group = "client"}
    ),

    awful.key({modkey, "Shift"}, "k",
        function() awful.client.swap.byidx(-1) end,
        {description = "swap with previous client by index", group = "client"}
    ),


    awful.key({modkey, "Control"}, "j",
        function() awful.screen.focus_relative( 1) end,
        {description = "focus the next screen", group = "screen"}
    ),

    awful.key({modkey, "Control"}, "k",
        function() awful.screen.focus_relative(-1) end,
        {description = "focus the previous screen", group = "screen"}
    ),


    awful.key({modkey}, "u",
        awful.client.urgent.jumpto,
        {description = "jump to urgent client", group = "client"}
    ),


    awful.key({modkey}, "Tab",
        function()
            awful.client.focus.history.previous()
            if awesome.client.focus then
                awesome.client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}
    ),

    awful.key({modkey, "Control"}, "Tab",
        awful.tag.history.restore,
        {description = "go back", group = "tag"}
    ),


    awful.key({modkey}, "l",
        function() awful.tag.incmwfact(0.05) end,
        {description = "increase master width factor", group = "layout"}
    ),

    awful.key({modkey}, "h",
        function() awful.tag.incmwfact(-0.05) end,
        {description = "decrease master width factor", group = "layout"}
    ),


    awful.key({modkey, "Shift"}, "h",
        function() awful.tag.incnmaster(1, nil, true) end,
        {description = "increase the number of master clients", group = "layout"}
    ),

    awful.key({modkey, "Shift"}, "l",
        function () awful.tag.incnmaster(-1, nil, true) end,
        {description = "decrease the number of master clients", group = "layout"}
    ),


    awful.key({modkey, "Control"}, "h",
        function() awful.tag.incncol( 1, nil, true) end,
        {description = "increase the number of columns", group = "layout"}
    ),

    awful.key({modkey, "Control"}, "l",
        function() awful.tag.incncol(-1, nil, true) end,
        {description = "decrease the number of columns", group = "layout"}
    ),


    awful.key({modkey}, "space",
        function() awful.layout.inc(1) end,
        {description = "select next", group = "layout"}
    ),

    awful.key({modkey, "Shift"}, "space",
        function() awful.layout.inc(-1) end,
        {description = "select previous", group = "layout"}
    ),


    awful.key({modkey, "Control"}, "n",
        function()
            local c = awful.client.restore()
            -- Focus restored client
            if c then
                awesome.client.focus = c
                c:raise()
            end
        end,
        {description = "restore minimized", group = "client"}
    ),


    awful.key({modkey}, "Return",
        function() awful.screen.focused().x_systembar.prompt:run() end,
        {description = "run prompt", group = "launcher"}
    ),

    awful.key({modkey, "Shift"}, "Return",
        function() awful.spawn(terminal) end,
        {description = "open a terminal", group = "launcher"}
    ),

    awful.key({modkey, "Control"}, "Return",
        function()
            awful.prompt.run({
                prompt       = "Run Lua code: ",
                textbox      = awful.screen.focused().x_systembar.prompt.widget,
                exe_callback = awful.util.eval,
                history_path = awful.util.get_cache_dir() .. "/history_eval"
            })
        end,
        {description = "lua execute prompt", group = "awesome"}
    ),


    tagKeys
))

local clientkeys = gears.table.join(
    awful.key({modkey}, "f",
        function(c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}
    ),

    awful.key({modkey, "Shift"}, "c",
        function(c) c:kill() end,
        {description = "close", group = "client"}
    ),

    awful.key({modkey, "Control"}, "space",
        awful.client.floating.toggle,
        {description = "toggle floating", group = "client"}
    ),

    awful.key({modkey}, "t",
        function(c) c.ontop = not c.ontop end,
        {description = "toggle keep on top", group = "client"}
    ),

    awful.key({modkey}, "n",
        function(c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end,
        {description = "minimize", group = "client"}
    ),

    awful.key({modkey}, "m",
        function(c)
            c.maximized = not c.maximized
            c:raise()
        end,
        {description = "(un)maximize", group = "client"}
    ),

    awful.key({modkey, "Control"}, "m",
        function(c)
            c.maximized_vertical = not c.maximized_vertical
            c:raise()
        end,
        {description = "(un)maximize vertically", group = "client"}
    ),

    awful.key({modkey, "Shift"}, "m",
        function(c)
            c.maximized_horizontal = not c.maximized_horizontal
            c:raise()
        end,
        {description = "(un)maximize horizontally", group = "client"}
    )
)



local clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) awesome.client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))


-- Rules to apply to new clients (through the "manage" signal).
--
-- Get window values with xprop(1).
--   instance  WM_CLASS, first string
--   class     WM_CLASS, second string
--   name      WM_NAME
--   role      WM_WINDOW_ROLE
awful.rules.rules = {
    -- all clients will match this rule
    {   rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen
        },
    },

    -- floating clients
    {   rule_any = {
            instance = {
                "DTA", -- Firefox addon DownThemAll.
                "copyq", -- Includes session name in class.
                "crx_gaedmjdfmmahhbjefcbgaolhhanlaolb", -- Authy
            },
            class = {
                "Arandr",
                "Gimp",
                "Gpick",
                "Kruler",
                "MessageWin", -- kalarm.
                "pinentry", -- gpg
                "Pinentry", -- gpg2
                "Sxiv",
                "veromix",
                "Wpa_gui",
                "xtightvncviewer"
            },
            name = {
                "Event Tester", -- xev.
            },
            role = {
                "AlarmWindow", -- Thunderbird's calendar.
                "pop-up", -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = {floating = true},
    },

    -- non-floating clients
    {   rule_any = {
            instance = {
                -- Tabs Outliner main window
                "crx_eggkanocgddhmamlbiijnphhppkpkmkl",
                -- Tabs Outliner via --app hack
                "eggkanocgddhmamlbiijnphhppkpkmkl__activesessionview.html",
            },
        },
        properties = {floating = false},
    },

    -- add titlebars to normal clients and dialogs
    {   rule_any = {type = {"normal", "dialog"}},
        properties = {titlebars_enabled = true},
    },
}

-- {{{ Signals
-- Signal function to execute when a new client appears.
awesome.client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.core.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
awesome.client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            awesome.client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            awesome.client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
awesome.client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        awesome.client.focus = c
    end
end)

awesome.client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
awesome.client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

