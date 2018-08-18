local _ENV = require("stdlib")

local awesome = require("awesome")
local beautiful = require("beautiful")
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")

local widget_cpu = require("widgets.cpu")
local widget_ram = require("widgets.ram")
local widget_thermal = require("widgets.thermal")
local widget_upower = require("widgets.upower")



return function(screen)
    local theme = beautiful.get()

    local prompt = awful.widget.prompt()

    local layoutIcon = awful.widget.layoutbox(screen)
    layoutIcon:buttons(gears.table.join(
        -- scroll wheel down - next layout
        awful.button({}, 5, function() awful.layout.inc(1) end),
        -- scroll wheel up - previous layout
        awful.button({}, 4, function() awful.layout.inc(-1) end)
    ))

    local taglist = awful.widget.taglist(
        screen,
        awful.widget.taglist.filter.noempty,
        gears.table.join()
    )

    local iconTasks = awful.widget.tasklist(
        screen,
        awful.widget.tasklist.filter.minimizedcurrenttags,
        gears.table.join(
            awful.button({}, 1, function(client)
                client.minimized = false
                client:raise()
            end)
        ),
        {   disable_task_name = true,
        }
    )

    local focusedTask = awful.widget.tasklist(
        screen,
        function(client)
            return client == awesome.client.focus
        end,
        gears.table.join(),
        {   fg_focus = theme.fg_normal,
            bg_focus = theme.bg_normal,
        }
    )

    local bar = awful.wibar({
        position = "top",
        screen = screen,
    })

    bar:setup({
        layout = wibox.layout.align.horizontal,
        {   layout = wibox.layout.fixed.horizontal,
            layoutIcon,
            taglist,
        },
        {   layout = wibox.layout.fixed.horizontal,
            iconTasks,
            focusedTask,
            prompt,
        },
        {   layout = wibox.layout.fixed.horizontal,
            {   layout = awful.widget.only_on_screen,
                screen = "primary",
                { widget = wibox.widget.systray },
            },
            widget_thermal(),
            widget_cpu(),
            widget_ram(),
            widget_upower(),
            {   widget = wibox.widget.textclock,
                format = "%_d %a %H:%M:%S",
                timeout = 1,
            },
        },
    })

    return {
        bar = bar,
        prompt = prompt,
    }
end
