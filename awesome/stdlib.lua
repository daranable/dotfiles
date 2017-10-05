local _G, _ENV = _G, nil

local error = _G.error
local package = _G.package
local rawget = _G.rawget
local setmetatable = _G.setmetatable


-- expose the Awesome C API as a module
package.loaded["awesome"] = {
    button = _G.button,
    client = _G.client,
    core = _G.awesome,
    dbus = _G.dbus,
    drawable = _G.drawable,
    drawin = _G.drawin,
    key = _G.key,
    keygrabber = _G.keygrabber,
    mouse = _G.mouse,
    mousegrabber = _G.mousegrabber,
    root = _G.root,
    screen = _G.screen,
    selection = _G.selection,
    tag = _G.tag,
    window = _G.window,
}


-- capture the global interface to the Lua standard library
local luastd = {
    -- escape valve to real global env
    _G = _G,

    -- Lua standard library constants
    _VERSION = _G._VERSION,

    -- Lua standard library functions
    assert = _G.assert,
    collectgarbage = _G.collectgarbage,
    dofile = _G.dofile,
    error = _G.error,
    getmetatable = _G.getmetatable,
    ipairs = _G.ipairs,
    load = _G.load,
    loadfile = _G.loadfile,
    next = _G.next,
    pairs = _G.pairs,
    pcall = _G.pcall,
    print = _G.print,
    rawequal = _G.rawequal,
    rawget = _G.rawget,
    rawlen = _G.rawlen,
    rawset = _G.rawset,
    require = _G.require,
    select = _G.select,
    setmetatable = _G.setmetatable,
    tonumber = _G.tonumber,
    tostring = _G.tostring,
    type = _G.type,
    xpcall = _G.xpcall,

    -- Lua standard library modules
    coroutine = _G.coroutine,
    debug = _G.debug,
    io = _G.io,
    math = _G.math,
    os = _G.os,
    package = _G.package,
    string = _G.string,
    table = _G.table,
    utf8 = _G.utf8,

    -- don't include deprecated Lua features:
    -- - _G.loadstring is replaced by _G.load
    -- - _G.module is replaced by _ENV
    -- - _G.unpack is replaced by _G.table.unpack
    -- - _G.bit32 is deprecated in favor of native bitwise operators
}


-- return a table suitable for assignment to _ENV
-- this exposes only the Lua standard library globals
-- and raises errors on attempts to reference other global names
return setmetatable({}, {
    __newindex = function(env, key, value)
        if nil ~= rawget(luastd, key) then
            error("cannot assign to Lua builtin '" .. key .. "'", 2)
        else
            error("variable '" .. key .. "' is not defined", 2)
        end
    end,

    __index = setmetatable(luastd, {
        __index = function(env, key)
            error("variable '" .. key .. "' is not defined", 2)
        end,
    }),
})
