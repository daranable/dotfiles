local _ENV = require("stdlib")

local awful = require("awful")
local beautiful = require("beautiful")
local gtable = require("gears.table")
local icon_theme = require("menubar.icon_theme")
local upower = require("upower")
local wibox = require("wibox")


local Module = {}


local Device = {}
Device.widget_name = "upower_device"

function Module.newDevice(upowerDevice)
    local this = wibox.layout.fixed.horizontal()
    gtable.crush(this, Device, true)

    this.upower = upowerDevice

    this._charge = wibox.widget {
        widget = wibox.widget.imagebox,
        image = "/home/sam/.files/awesome/charging.svg",
    }

    this._chart = wibox.widget {
        layout = wibox.container.arcchart,
        bg = "#555555",
        start_angle = 1.5 * math.pi,
        thickness = 2,
        paddings = 2,

        min_value = 0,
        max_value = 100,

        -- mirror the text to compensate for the mirroring below
        {   layout = wibox.container.mirror,
            reflection = {
                horizontal = true,
                vertical = false,
            },
            this._charge,
        },
    }

    -- mirror the chart so it goes clockwise
    -- arcchart can only go up counterclockwise
    this:add(wibox.widget {
        layout = wibox.container.mirror,
        reflection = {
            horizontal = true,
            vertical = false,
        },
        {   layout = wibox.container.margin,
            margins = 2,
            this._chart,
        },
    })

    this._tooltip = awful.tooltip({
        objects = { this },
        timer_function = function()
            return this:getDetailMarkup()
        end,
    })

    this.upower:onUpdate(function()
        this:update()
    end)

    this:update()
    return this
end

function Device:getDetailMarkup()
    local message = (
        self.upower:getState()
        .. " " .. tostring(self.upower:getEnergyPercentage()) .. "%"
    )

    if self.upower:isUPS() then
        message = message .. (
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
end



local Container = {}
Container.widget_name = "upower"

function Module.new(args)
    local this = wibox.layout.fixed.horizontal()
    gtable.crush(this, Container, true)

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
