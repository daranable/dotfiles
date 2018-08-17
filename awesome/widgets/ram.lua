local _ENV = require("stdlib")

local awesome = require("awesome")
local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")
local naughty = require("naughty")

local poller = gears.object()

function poller:start()
    if self._timer then return end

    local meminfo = io.open("/proc/meminfo", "r")
    self._timer = gears.timer({timeout = 2})
    self._timer:connect_signal("timeout", function()
        local vars = {}
        local total, avail, free

        meminfo:seek("set", 0)
        for line in meminfo:lines() do
            local key, value = line:match("^([^%s]+):%s*(%d+)")
            if key == "MemTotal" then
                total = value
            elseif key == "MemAvailable" then
                avail = value
            elseif key == "MemFree" then
                free = value
            end
        end

        self.percent = math.floor((total - avail) / total * 100 + 0.5)
        self.data_list = {
            {"used",  total - avail},
            {"cache", avail - free},
            {"free",  free},
        }
        self:emit_signal("update")
    end)
    self._timer:start()
    self._timer:emit_signal("timeout")
end

return function()
    local theme = beautiful.get()

    local textbox = wibox.widget {
        widget = wibox.widget.textbox,
    }

    local chart_box = wibox {
        width = 400,
        height = 200,
        ontop = true,
        screen = awesome.mouse.screen,
        expand = true,
        visible = false,
    }

    chart_box:setup {
        id = 'chart',
        widget = wibox.widget.piechart,
        border_width = 0,
        forced_width = 30,
        forced_height = 30,
        colors = {
            "#aaaaaa",
            "#888888",
            "#555555",
        },
    }

    textbox:buttons(awful.util.table.join(
        awful.button({}, 1, function()
            if not chart_box.visible then
                awful.placement.top_right(
                    chart_box, {margins = {top = 25, right = 10}}
                )
                chart_box.visible = true
            else
                chart_box.visible = false
            end
        end)
    ))

    chart_box:buttons(awful.util.table.join(
        awful.button({}, 1, function()
            chart_box.visible = false
        end)
    ))

    poller:connect_signal("update", function()
        textbox.text = tostring(poller.percent) .. "%"
        chart_box.chart.data_list = poller.data_list
    end)
    poller:start()

    return textbox
end
