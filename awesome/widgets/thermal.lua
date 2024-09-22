local _ENV = require("stdlib")


local gears = require("gears")
local wibox = require("wibox")
local xres = require("beautiful.xresources")

local fs = gears.filesystem



local whitelist = {
    k10temp = true,
    amdgpu = true,
}


local poller = gears.object()

function poller:init()
    if self.sources then return end
    self.sources = {}

    if not fs.is_dir("/sys/class/hwmon") then return end

    local idx = 0
    while true do
        local path = "/sys/class/hwmon/hwmon" .. tostring(idx)
        if not fs.is_dir(path) then break end

        local inputPath = path .. "/temp1_input"
        if fs.file_readable(inputPath) then
            local nameFile = io.open(path .. "/name", "r")
            if nameFile then
                local name = nameFile:read()
                nameFile:close()

                if whitelist[name] then
                    table.insert(self.sources, inputPath)
                end
            end
        end

        idx = idx + 1
    end
end

function poller:start()
    if self._timer then return end

    self._timer = gears.timer({timeout = 5})
    self._timer:connect_signal("timeout", function()
        local values = {}

        for idx, source in ipairs(self.sources) do
            local file = io.open(source, "r")
            local value = file:read()
            file:close()

            values[idx] = value / 1000
        end

        self.values = values
        self:emit_signal("update")
    end)
    self._timer:start()
    self._timer:emit_signal("timeout")
end



return function()
    poller:init()

    local box = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = xres.apply_dpi(4),
    }

    local values = {}


    for idx, source in ipairs(poller.sources) do
        local text = wibox.widget {
            widget = wibox.widget.textbox,
        }

        values[idx] = text
        box:add(text)
    end


    poller:connect_signal("update", function(data)
        for idx, value in ipairs(poller.values) do
            local round = tostring(math.floor(value + 0.5))
            if value >= 70 then
                values[idx].markup = '<span color="#ff6666">' .. round .. '°</span>'
            else
                values[idx].markup = round .. "°"
            end
        end
    end)
    poller:start()

    return wibox.widget {
        layout = wibox.container.margin,
        margins = xres.apply_dpi(4),
        box,
    }
end
