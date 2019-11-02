local _ENV = require("stdlib")


local gears = require("gears")
local wibox = require("wibox")
local xres = require("beautiful.xresources")
--local naughty = require("naughty")

local fs = gears.filesystem

local toggl = require("toggl")



return function()
    toggl:start()

    local box = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = xres.apply_dpi(4),
    }


    local text_today = wibox.widget {
        widget = wibox.widget.textbox,
    }
    box:add(text_today)

    local timer = gears.timer({timeout = 1})
    timer:connect_signal("timeout", function()
        local total = toggl:getTotalTimeToday()
        text_today.markup = string.format(
            "%02d:%02d:%02d",
            math.floor(total / 3600),
            math.floor(total % 3600 / 60),
            total % 60
        )
    end)
    timer:start()
    timer:emit_signal("timeout")

    return wibox.widget {
        layout = wibox.container.margin,
        margins = xres.apply_dpi(4),
        box,
    }
end
