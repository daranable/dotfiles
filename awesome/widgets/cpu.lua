local _ENV = require("stdlib")


local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local xres = require("beautiful.xresources")



local poller = gears.object()

function poller:start()
    if self._timer then return end

    self._timer = gears.timer({timeout = 5})
    self._timer:connect_signal("timeout", function()
        local stat = io.open("/proc/stat", "r")
        local line = stat:lines()()
        stat:close()

        local user, nice, system, idle, iowait, irq, softirq, steal =
            line:match('^cpu%s*' .. string.rep('(%d+)%s*', 8))

        local total = user + nice + system + idle + iowait + irq + softirq + steal
        local deltaTotal = self.total ~= nil and (total - self.total) or 0
        self.total = total

        local deltaIdle = self.idle and (idle - self.idle) or 0
        self.idle = idle


        self.usage = (deltaTotal - deltaIdle) / deltaTotal * 100
        self:emit_signal("update")
    end)
    self._timer:start()
    self._timer:emit_signal("timeout")
end



return function()
    local theme = beautiful.get()

    local graph = wibox.widget {
        widget = wibox.widget.graph,
        min_value = 0,
        max_value = 100,
        step_width = xres.apply_dpi(2),
        step_spacing = xres.apply_dpi(1),
        forced_width = xres.apply_dpi(50),
        color = theme.fg_normal,
        background_color = theme.bg_normal,
    }

    -- mirror the graph so it goes right-to-left
    -- the graph widget can only go left-to-right
    local widget = wibox.widget {
        layout = wibox.container.mirror,
        reflection = {
            horizontal = true,
            vertical = false,
        },

        -- the graph needs a little bit of standoff
        {   layout = wibox.container.margin,
            margins = xres.apply_dpi(2),

            graph,
        },
    }


    poller:connect_signal("update", function(data)
        graph:add_value(data.usage)
    end)
    poller:start()

    return widget
end
