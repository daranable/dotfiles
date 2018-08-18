local _ENV = require("stdlib")

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local xres = require("beautiful.xresources")



local poller = gears.object()

function poller:start()
    if self._timer then return end

    local meminfo = io.open("/proc/meminfo", "r")
    self._timer = gears.timer({timeout = 5})
    self._timer:connect_signal("timeout", function()
        meminfo:seek("set", 0)
        for line in meminfo:lines() do
            local key, value = line:match("^([^%s]+):%s*(%d+)")
            if key == "MemTotal" then
                self.memTotal = tonumber(value)
            elseif key == "MemAvailable" then
                self.memAvail = tonumber(value)
            elseif key == "MemFree" then
                self.memFree = tonumber(value)
            elseif key == "SwapTotal" then
                self.swapTotal = tonumber(value)
            elseif key == "SwapFree" then
                self.swapFree = tonumber(value)
            end
        end


        self.memUsed = self.memTotal - self.memAvail
        self.memCached = self.memAvail - self.memFree
        self.swapUsed = self.swapTotal - self.swapFree

        self:emit_signal("update")
    end)
    self._timer:start()
    self._timer:emit_signal("timeout")
end



return function()
    local swap_chart = wibox.widget {
        layout = wibox.container.arcchart,
        bg = "#555555",
        start_angle = 1.5 * math.pi,
        thickness = xres.apply_dpi(2),
        paddings = xres.apply_dpi(2),
        min_value = 0,
    }

    local mem_chart = wibox.widget {
        layout = wibox.container.arcchart,
        bg = "#555555",
        start_angle = 1.5 * math.pi,
        thickness = xres.apply_dpi(2),
        paddings = xres.apply_dpi(2),
        min_value = 0,

        swap_chart,
    }

    -- mirror the chart so it goes up clockwise
    -- arcchart can only go up counterclockwise
    local widget = wibox.widget {
        layout = wibox.container.mirror,
        reflection = {
            horizontal = true,
            vertical = false,
        },

        -- the chart needs a little bit of standoff
        {   layout = wibox.container.margin,
            margins = xres.apply_dpi(2),

            mem_chart,
        },
    }

    local tooltip = awful.tooltip {
        objects = { widget },
        timer_function = function()
            local memPercent = math.floor(
                poller.memUsed / poller.memTotal * 100 + 0.5
            )

            local cachePercent = math.floor(
                poller.memCached / poller.memTotal * 100 + 0.5
            )

            local swapPercent
            if poller.swapTotal > 0 then
                swapPercent = math.floor(
                    poller.swapUsed / poller.swapTotal * 100 + 0.5
                )
            else
                swapPercent = 0
            end


            return (
                "RAM Used: " .. tostring(memPercent) .. "%\n"
                .. "RAM Cached: " .. tostring(cachePercent) .. "%\n"
                .. "Swap Used: " .. tostring(swapPercent) .. "%"
            )
        end,
    }

    poller:connect_signal("update", function(data)
        swap_chart.max_value = data.swapTotal
        swap_chart.value = data.swapUsed ~= 0 and data.swapUsed or nil

        mem_chart.max_value = data.memTotal
        mem_chart.value = data.memUsed ~= 0 and data.memUsed or nil
    end)
    poller:start()

    return widget
end
