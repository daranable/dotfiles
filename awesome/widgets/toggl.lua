local _ENV = require("stdlib")


local gears = require("gears")
local wibox = require("wibox")
local xres = require("beautiful.xresources")
--local naughty = require("naughty")

local fs = gears.filesystem

local toggl = require("toggl")


local function format_time(seconds)
    return string.format(
        "%02d:%02d",
        math.floor(seconds / 3600),
        math.floor(seconds % 3600 / 60)
    )
end


return function()
    toggl:start()

    local box = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = xres.apply_dpi(4),
    }

    local text_current = wibox.widget {
        widget = wibox.widget.textbox,
    }
    box:add(text_current)

    local text_today = wibox.widget {
        widget = wibox.widget.textbox,
    }
    box:add(text_today)

    local timer = gears.timer({timeout = 1})
    timer:connect_signal("timeout", function()
        local total = toggl:getTotalTimeToday()
        text_today.markup = format_time(total)

        local current = toggl:getCurrentEntryTime()
        if current == nil then
            text_current.markup = '<span color="#cccccc">stopped</span'
        else
            text_current.markup = format_time(current)
        end
    end)
    timer:start()
    timer:emit_signal("timeout")

    return wibox.widget {
        layout = wibox.container.margin,
        margins = xres.apply_dpi(4),
        box,
    }
end
