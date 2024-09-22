local _ENV = require("stdlib")

local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local icon_theme = require("menubar.icon_theme")
local upower = require("upower")
local wibox = require("wibox")
local xres = require("beautiful.xresources")


local Module = {}


local Device = {}
Device.widget_name = "upower_device"
Device.show_time = false

function Module.newDevice(upowerDevice)
    local this = wibox.layout.fixed.horizontal()
    gears.table.crush(this, Device, true)

    this.upower = upowerDevice

    local icon_dir = gears.filesystem.get_configuration_dir() .. "/icons"

    this._charge = wibox.widget {
        widget = wibox.widget.imagebox,
        image = icon_dir .. "/power_charging.svg",
    }

    this._discharge = wibox.widget {
        widget = wibox.widget.imagebox,
        image = icon_dir .. "/power_discharging.svg",
    }

    this._chart = wibox.widget {
        layout = wibox.container.arcchart,
        bg = "#555555",
        start_angle = 1.5 * math.pi,
        thickness = xres.apply_dpi(2),
        paddings = xres.apply_dpi(2),

        min_value = 0,
        max_value = 100,

        -- mirror the icon to compensate for the mirroring below
        {   layout = wibox.container.mirror,
            reflection = {
                horizontal = true,
                vertical = false,
            },
            {   layout = wibox.layout.stack,
                this._charge,
                this._discharge,
            },
        },
    }

    -- mirror the chart so it goes up clockwise
    -- arcchart can only go up counterclockwise
    this:add(wibox.widget {
        layout = wibox.container.mirror,
        reflection = {
            horizontal = true,
            vertical = false,
        },

        -- the chart needs a little bit of standoff
        {   layout = wibox.container.margin,
            margins = xres.apply_dpi(2),
            this._chart,
        },
    })

    this._tooltip = awful.tooltip({
        objects = { this },
        timer_function = function()
            return this:getDetailMarkup()
        end,
    })

    this._time = wibox.widget {
        widget = wibox.widget.textbox,
        visible = false,
    }
    this:add(this._time)

    this.upower:onUpdate(function()
        this:update()
    end)

    this:update()
    return this
end

function Device:getTimeRemaining()
    local seconds
    if self.upower:isCharging() then
        seconds = self.upower:getTimeToFull()
    elseif self.upower:isDischarging() then
        seconds = self.upower:getTimeToEmpty()
    else
        return nil
    end

    local str = ""

    if seconds > 3600 then
        str = str .. tostring(math.floor(seconds / 3600)) .. "h "
    end

    str = str .. tostring(math.floor(seconds % 3600 / 60)) .. "m"
    return str
end

function Device:getDetailMarkup()
    local message = (
        self.upower:getState()
        .. " " .. tostring(self.upower:getEnergyPercentage()) .. "%"
    )

    if self.upower:isCharging() or self.upower:isDischarging() then
        local legend
        if self.upower:isCharging() then
            legend = "to full"
        else
            legend = "to empty"
        end

        message = message .. (
            "\n" .. self:getTimeRemaining() .. " " .. legend
        )
    end

    if self.upower:isUPS() then
        message = "UPS " .. message .. (
            "\nModel: " .. self.upower:getVendor()
                .. " " .. self.upower:getModel()
            .. "\nSerial: " .. self.upower:getSerial()
        )
    end

    return message
end

function Device:update()
    local value = self.upower:getEnergyPercentage()
    self._chart.value = value

    if value < 10 then
        self._chart.colors = { "#ff3333" }
    else
        self._chart.colors = { "#aaaaaa" }
    end

    self._charge.visible = (
        self.upower:isCharging()
        or self.upower:isOnline()
    )
    self._discharge.visible = not self._charge.visible

    if self.upower:isCharging() or self.upower:isDischarging() then
        self._time.markup = self:getTimeRemaining()
        self._time.visible = self.show_time
    else
        self._time.visible = false
    end
end



local Container = {}
Container.widget_name = "upower"

function Module.new(args)
    local this = wibox.layout.fixed.horizontal()
    gears.table.crush(this, Container, true)

    this._devices = {}

    upower:onDeviceAdded(function(path, device)
        this:_deviceAdd(path, device)
    end)

    upower:onDeviceRemoved(function(path, device)
        this:_deviceRemove(path, device)
    end)

    for path, device in pairs(upower:getDevices()) do
        this:_deviceAdd(path, device)
    end

    return this
end

function Container:_deviceAdd(path, dev)
    if self._devices[path] then return end
    if not dev:isBattery() and not dev:isUPS() then return end

    local device = Module.newDevice(dev)
    self._devices[path] = device
    self:add(device)
end

function Container:_deviceRemove(path, upowerDevice)
    if self._devices[path] then
        self:remove_widgets(self._devices[path])
        self._devices[path] = nil
    end
end



return setmetatable(Module, {
    __call = function (_, ...)
        return Module.new(...)
    end,
})
