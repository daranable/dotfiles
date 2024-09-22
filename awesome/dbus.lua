local _ENV = require("stdlib")

local debug = require("debug")
local naughty = require("naughty")

local lgi  = require("lgi")
local GLib = lgi.require("GLib")
local Gio  = lgi.require("Gio")

local Connection = {}
Connection.__index = Connection

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




local Proxy = {}
Proxy.__index = Proxy

function Connection:bind(owner, object, interface)
    local proxy = Gio.DBusProxy.async_new(
        self.gdbus,          -- GDBusConnection
        {},                  -- GDBusProxyFlags
        nil,                 -- GDBusInterfaceInfo
        owner,               -- bus name
        object,              -- object path
        interface            -- interface name
    )

    local this = {
        __index = Proxy,
        connection = self,
        gdbus = proxy,
        _handlers = {},
        _onUpdate = {},
    }

    proxy.on_g_signal:connect(function(_, sender, signal, params)
        if this._handlers[signal] then
            for _, handler in pairs(this._handlers[signal]) do
                pcall(handler, sender, signal, params)
            end
        end
    end)

    proxy.on_g_properties_changed:connect(function(_, changed, inval)
        for _, handler in pairs(this._onUpdate) do
            pcall(handler)
        end
    end)

    return setmetatable(this, this)
end

--- Gets the name this proxy is connected to.
-- @treturn string
function Proxy:getName()
    return self.gdbus:get_name()
end

--- Gets the unique name that owns the name this proxy is connected to.
-- @treturn string
function Proxy:getNameOwner()
    return self.gdbus:get_name_owner()
end

--- Gets the object path this proxy is for.
-- @treturn string
function Proxy:getObjectPath()
    return self.gdbus:get_object_path()
end

--- Gets the interface name this proxy is for.
-- @treturn string
function Proxy:getInterfaceName()
    return self.gdbus:get_interface_name()
end

function Proxy:on(signal, handler)
    local handlers = self._handlers[signal]
    if not handlers then
        handlers = {}
        self._handlers[signal] = handlers
    end
    handlers[handler] = handler
end

function Proxy:off(signal, handler)
    local handlers = self._handlers[signal]
    if handlers then
        handlers[handler] = nil
    end
end

function Proxy:onUpdate(handler)
    self._onUpdate[handler] = handler
end

function Proxy:offUpdate(handler)
    self._onUpdate[handler] = nil
end

function Proxy:get(name)
    return self.gdbus:get_cached_property(name)
end

function Proxy:call(method)
    return self.gdbus:async_call(
        method,
        nil,
        {},
        -1
    )
end





local busTypes = {
    ["system" ] = Gio.BusType.SYSTEM,
    ["session"] = Gio.BusType.SESSION,
}

local dbus = setmetatable({}, {
    __index = function (table, key)
        if nil ~= busTypes[key] then
            local conn = Gio.async_bus_get(busTypes[key])
            conn = setmetatable({gdbus = conn}, Connection)
            table[key] = conn
            return conn
        end
    end
})

local function pcall_notify(callback, ...)
    xpcall(callback, function(err)
        local msg = debug.traceback(tostring(err))
        print("!DBus Error! " .. msg)

        naughty.notify {
            preset = naughty.config.presets.critical,
            ignore_suspend = true,
            title = "Error in DBus Async Thread",
            text = msg,
        }
    end, ...)
end

function dbus.async(callback, ...)
    Gio.Async.start(pcall_notify)(callback, ...)
end

function dbus.sync(callback, ...)
    Gio.Async.call(pcall_notify)(callback, ...)
end

return dbus
