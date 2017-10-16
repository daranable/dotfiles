local _ENV = require("stdlib")

local lgi = require("lgi")
local Gio = lgi.require("Gio")

local Connection = {}
Connection.__index = Connection

local busTypes = {
    ["system" ] = Gio.BusType.SYSTEM,
    ["session"] = Gio.BusType.SESSION,
}

local function bus_get (busType)
    -- the Gio.Async shim doesn't recognize bus_get as async
    -- see https://github.com/pavouk/lgi/issues/142
    Gio.bus_get(busTypes[busType], nil, coroutine.running())
    local _, result = coroutine.yield()
    local conn = Gio.bus_get_finish(result)

    return setmetatable({gdbus = conn}, Connection)
end


--- Closes the connection.
-- Once the connection is closed, operations such as sending a message
-- will return with an error. Closing a connection won't automatically
-- flush it, so queued messages may be lost. Use the `:flush()` method
-- to avoid that if you need to.
-- @treturn bool whether the call was successful
-- @treturn string an error message, or `nil` if no error
function Connection:close()
    return self.gdbus:async_close()
end

--- Gets whether the connection has been closed.
-- @treturn bool whether the connection has been closed
function Connection:isClosed()
    return self.gdbus:is_closed()
end

--- Flushes queued messages on the connection.
-- First all queued messages will be written, then the transport
-- channel will be flushed. This is useful in programs that want to
-- emit a DBus signal and then exit immediately. Without flushing the
-- connection, there's no guarantee such a message would be delivered.
-- @treturn bool whether the call was successful
-- @treturn string an error message, or `nil` if no error
function Connection:flush()
    return self.gdbus:async_flush()
end

--- Gets the unique name of the connection assigned by the message bus.
-- @treturn string the unique name of this connection,
--          or `nil` if this is not a message bus connection
function Connection:getUniqueName()
    return self.gdbus:get_unique_name()
end

--- Checks whether it is possible to exchange UNIX file descriptors.
-- This will typically be supported when connecting to local peers via
-- AF_UNIX sockets and not for other transport channels.
-- @treturn bool whether FDs can be exchanged with the remote peer
function Connection:canPassFileDescriptor()
    return true == self.gdbus:get_capabilities().UNIX_FD_PASSING
end




local dbus = setmetatable({}, {
    __index = function (table, key)
        if nil ~= busTypes[key] then
            local conn = bus_get(key)
            table[key] = conn
            return conn
        end
    end
})


Gio.Async.call(function()
    local ok, err = pcall(function()
        local result = dbus.system.gdbus:async_call(
            "org.freedesktop.UPower",
            "/org/freedesktop/UPower",
            "org.freedesktop.UPower",
            "EnumerateDevices",
            nil, -- arguments
            nil, -- reply type
            {}, -- flags
            -1 -- timeout
        )

        print("call " .. tostring(result.value[1].value[1]))
    end)
    if not ok then
        print("!ERROR! " .. tostring(err))
    end
end)()
