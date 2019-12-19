local _ENV = require("stdlib")

local gears = require("gears")

local lgi = require("lgi")
local soup = lgi.require("Soup")

local basexx = require("basexx")
local json = require("json")


local API_URL = "https://api_token@www.toggl.com"
local WS_URL = "wss://stream.toggl.com/ws"


local toggl = {}


local function datetime_3339(time)
    local date = os.date("%Y-%m-%dT%H:%M:%S%z", os.time(time))
    return string.sub(date, 0, -3) .. ":" .. string.sub(date, -2)
end

local function today_3339()
    local time = os.date("*t")

    -- the midnight preceding today
    time.hour = 0
    time.min = 0
    time.sec = 0
    local start_date = datetime_3339(time)

    -- the midnight following today
    time.day = time.day + 1
    local end_date = datetime_3339(time)

    return start_date, end_date
end

function toggl:start()
    if self._timer then return end

    local config_file = os.getenv("HOME") .. "/.config/awesome_toggl.json"
    local config = io.open(config_file, "r")
    if not config then return end
    self._config = json.decode(config:read("*a"))

    self._ignore_projects = {}
    for _, id in pairs(self._config.ignore_projects) do
        self._ignore_projects[id] = true
    end

    self._soup = soup.Session()

    self._entries = {}

    self._timer = gears.timer({timeout = 5 * 60})
    self._timer:connect_signal("timeout", function()
        self:poll()
    end)
    self._timer:start()
    self._timer:emit_signal("timeout")
end

function toggl:poll()
    local start_date, end_date = today_3339()

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
        local body = msg.response_body:flatten():get_data()

        local entries = {}
        for _, entry in pairs(json.decode(body)) do
            if not self._ignore_projects[entry.pid] then
                entries[entry.id] = entry
            end
        end

        self._entries = entries
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
