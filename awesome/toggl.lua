local _ENV = require("stdlib")

local gears = require("gears")
local naughty = require("naughty")

local lgi = require("lgi")
local soup = lgi.require("Soup")

local basexx = require("basexx")
local json = require("json")


local API_URL = "https://www.toggl.com"
local WS_URL = "wss://stream.toggl.com/ws"


local toggl = {}


local function datetime_3339(time)
    local date = os.date("%Y-%m-%dT%H:%M:%S%z", os.time(time))
    return string.sub(date, 0, -3) .. ":" .. string.sub(date, -2)
end

local function parse_3339(input)
    local year, month, day, hour, min, sec = string.match(
        input,
        "^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z"
    )

    local result = {
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec),
    }

    -- correct for UTC offset
    local now = os.time()
    local offset = os.time(os.date("!*t", now)) - now
    return os.date("*t", os.time(result) - offset)
end

local function show_error(title, message)
    print(string.format("!! Toggl %s: %s", title, message))
    naughty.notify {
        preset = naughty.config.presets.critical,
        ignore_suspend = true,
        title = title,
        text = message,
    }
end


local function pcall_notify(callback, ...)
    xpcall(
        callback,
        function (err)
            local msg = debug.traceback(tostring(err), 2)
            show_error("Error in Toggl Async Thread", msg)
        end,
        ...
    )
end

local function async(callback, ...)
    lgi.Gio.Async.start(pcall_notify)(callback, ...)
end

function toggl:start()
    if self._timer then return end
    self._entries = {}

    local config_file = os.getenv("HOME") .. "/.config/awesome_toggl.json"
    local config = io.open(config_file, "r")
    if not config then
        show_error("Toggl", "failed to load ~/.config/awesome_toggl.json")
        return
    end
    self._config = json.decode(config:read("*a"))

    self._ignore_projects = {}
    for _, id in pairs(self._config.ignore_projects) do
        self._ignore_projects[id] = true
    end

    self._soup = soup.Session {
        user_agent = "awesome-toggl/0.1 ",
    }

    async(function()
        local sock, err = self._soup:async_websocket_connect(
            soup.Message.new("GET", WS_URL),
            "https://localhost", -- origin
            {} -- protocols
        )

        if not sock then
            show_error("Toggl WebSocket", "failed to connect: " .. tostring(err))
        end

        sock.on_closed = function()
            show_error("Toggl Websocket", "socket closed.")
        end

        sock.on_message = function(_, _, buf)
            local raw = buf:get_data()
            local msg = json.decode(raw)
            if msg.type == "ping" then
                sock:send_text('{"type": "pong"}')
            elseif msg.session_id then
                -- ignore post-auth message
            elseif msg.model == "time_entry" then
                if msg.action == "INSERT" or msg.action == "UPDATE" then
                    local now = os.date("*t")
                    local start = parse_3339(msg.data.start)
                    if start.year == now.year and start.month == now.month and start.day == now.day then
                        self._entries[msg.data.id] = msg.data
                    end
                elseif msg.action == "DELETE" then
                    self._entries[msg.data.id] = nil
                else
                    print("Toggl WS: unrecognized time_entry action " .. raw)
                end
            else
                print("Toggl WS: unrecognized message " .. raw)
            end
        end

        sock:send_text(json.encode {
            type = "authenticate",
            api_token = self._config.token,
        })
    end)


    self._timer = gears.timer({timeout = 5 * 60})
    self._timer:connect_signal("timeout", function()
        self:poll()
    end)
    self._timer:start()
    self._timer:emit_signal("timeout")
end

function toggl:poll()
    local time = os.date("*t")

    -- the midnight preceding today
    time.hour = 0
    time.min = 0
    time.sec = 0
    local start_date = datetime_3339(time)

    -- the midnight following today
    time.day = time.day + 1
    local end_date = datetime_3339(time)

    local msg = soup.Message.new(
        "GET",
        API_URL .. "/api/v8/time_entries"
        .. "?start_date=" .. start_date
        .. "&end_date=" .. end_date
    )

    msg.request_headers:replace(
        "Authorization",
        "Basic " .. basexx.to_base64(self._config.token .. ":api_token")
    )

    self._soup:queue_message(msg, function(_, msg, _)
        if msg.status_code == 200 then
            local body = msg.response_body:flatten():get_data()

            local entries = {}
            for _, entry in pairs(json.decode(body)) do
                if not self._ignore_projects[entry.pid] then
                    entries[entry.id] = entry
                end
            end

            self._entries = entries
        else
            show_error(
                "Error in Toggl Poller",
                string.format("Server returned %d %s", msg.status_code, msg.reason_phrase)
            )
        end
    end)
end

function toggl:getTotalTimeToday()
    if not self._entries then return 0 end

    local total = 0
    for _, entry in pairs(self._entries) do
        if entry.duration < 0 then
            total = total + (os.time() + entry.duration)
        else
            total = total + entry.duration
        end
    end

    return total
end

function toggl:getCurrentEntryTime()
    for _, entry in pairs(self._entries) do
        if entry.duration < 0 then
            return os.time() + entry.duration
        end
    end
    return nil
end

return toggl
