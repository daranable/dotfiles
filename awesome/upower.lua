local _ENV = require("stdlib")

local dbus = require("dbus")



local Device = {}
Device.__index = Device

--- Gets the name of the device manufacturer.
-- @treturn string
function Device:getVendor()
    return self.dbus:get("Vendor").value
end

--- Gets the model name/number of the device.
-- @treturn string
function Device:getModel()
    return self.dbus:get("Model").value
end

--- Gets the serial number of the device.
-- @treturn string
function Device:getSerial()
    return self.dbus:get("Serial").value
end

local typeCodes = {
    [1] = "line",
    [2] = "battery",
    [3] = "ups",
    [4] = "monitor",
    [5] = "mouse",
    [6] = "keyboard",
    [7] = "pda",
    [8] = "phone",
}

--- Gets the general type of the device.
-- @treturn string a fixed name for the device class
function Device:getType()
    local code = self.dbus:get("Type").value
    if typeCodes[code] then
        return typeCodes[code]
    else
        return "unknown"
    end
end

--- Gets whether the device supplies power to this computer.
-- This will be true for e.g. UPSes, AC adaptors, and laptop batteries
-- and false for peripherals like mice, keyboards, or mobile phones.
-- @treturn bool
function Device:isSystemSupply()
    return self.dbus:get("PowerSupply").value
end

--- Gets whether the device is currently powered from the mains.
-- This is only valid for types like line and ups that have a direct
-- mains input and not e.g. for the battery type.
-- @treturn bool
function Device:isOnline()
    return self.dbus:get("Online").value
end

--- Gets the current amount of energy stored in the device.
-- This is only valid for energy storage types like battery or ups.
-- @treturn number the amount of energy in watt-hours
function Device:getEnergy()
    return self.dbus:get("Energy").value
end

--- Gets the expected energy reading when the device is empty.
-- This is only valid for energy storage types like battery or ups.
-- @treturn number the amount of energy in watt-hours
function Device:getEnergyAtEmpty()
    return self.dbus:get("EnergyEmpty").value
end

--- Gets the expected energy reading when the device is fully charged.
-- This is only valid for energy storage types like battery or ups.
-- @treturn number the amount of energy in watt-hours
function Device:getEnergyAtFull()
    return self.dbus:get("EnergyFull").value
end

--- Gets the designed energy reading when the device is fully charged.
-- This is only valid for energy storage types like battery or ups.
-- @treturn number the amount of energy in watt-hours
function Device:getEnergyAtDesignFull()
    return self.dbus:get("EnergyFullDesign").value
end

--- Gets the rate at which the device is being discharged.
-- The value with be positive if the device is discharging and
-- negative if the device is charging.
-- This is only valid for energy storage types like battery or ups.
-- @treturn number the discharge rate in watts
function Device:getDischargeRate()
    return self.dbus:get("EnergyRate").value
end

--- Gets the time until the device is fully discharged.
-- This is only valid for energy storage types like battery or ups.
-- @treturn number the time to empty in whole seconds
function Device:getTimeToEmpty()
    return self.dbus:get("TimeToEmpty").value
end

--- Gets the time until the device is full charged.
-- This is only valid for energy storage types like battery or ups.
-- @treturn number the time to full in whole seconds
function Device:getTimeToFull()
    return self.dbus:get("TimeToFull").value
end

--- Gets the energy remaining in the device as percentage of capacity.
-- @treturn number the percentage of remaining charge
function Device:getEnergyPercentage()
    return self.dbus:get("Percentage").value
end

local stateCodes = {
    [1] = "Charging",
    [2] = "Discharging",
    [3] = "Empty",
    [4] = "Charged",
}

function Device:getState()
    local code = self.dbus:get("State").value
    if stateCodes[code] then
        return stateCodes[code]
    else
        return "Unknown"
    end
end

function Device:isCharging()
    return 1 == self.dbus:get("State").value
end

function Device:isFull()
    return 4 == self.dbus:get("State").value
end

function Device:onUpdate(handler)
    self._onUpdate[handler] = handler
end

function Device:offUpdate(handler)
    self._onUpdate[handler] = nil
end



local upower = {}
upower._devices = {}
upower._onAdd = {}
upower._onRemove = {}

function upower:_connect()
    if self._upower then return end

    dbus.async(function()
        self._upower = dbus.system:bind(
            "org.freedesktop.UPower",
            "/org/freedesktop/UPower",
            "org.freedesktop.UPower"
        )

        self._upower:on("DeviceAdded", function (sender, signal, args)
            self:_deviceAdd(args.value[1])
        end)

        self._upower:on("DeviceRemoved", function (sender, signal, args)
            self:_deviceRemove(args.value[1])
        end)

        local devs = self._upower:call("EnumerateDevices")
        for _, dev in ipairs(devs.value[1]) do
            self:_deviceAdd(dev)
        end
    end)
end

--- Internal hook when a device becomes managed.
-- This will only be called from within a DBus coroutine.
function upower:_deviceAdd(path)
    local proxy = dbus.system:bind(
        self._upower:getName(),
        path,
        "org.freedesktop.UPower.Device"
    )

    local device = setmetatable({
        dbus = proxy,
        _onUpdate = {},
    }, Device)

    proxy:on("Changed", function (sender, signal, args)
        for _, handler in pairs(device._onUpdate) do
            pcall(handler)
        end
    end)

    self._devices[path] = device
    for _, handler in pairs(self._onAdd) do
        pcall(handler, path, device)
    end
end

--- Internal hook when a device disappears.
-- This will only be called from within a DBus coroutine.
function upower:_deviceRemove(path)
    for _, handler in pairs(self._onRemove) do
        pcall(handler, path, self._devices[path])
    end

    self._devices[path] = nil
end

function upower:getDevices()
    self:_connect()
    return self._devices
end

function upower:onDeviceAdded(handler)
    self._onAdd[handler] = handler
    self:_connect()
end

function upower:onDeviceRemoved(handler)
    self._onRemove[handler] = handler
    self:_connect()
end

return upower
