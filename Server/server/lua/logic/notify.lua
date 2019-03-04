local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert

local notify = {}
local notify_system = {}

local function add_message(user_name, string)
    local msg = {expire = os.time() + 360, name = user_name, data = string}
    tinsert(notify, msg)
    return msg
end

local function discard_message()
    local t = os.time()
    while notify[1] and notify[1].expire < t do
        table.remove(notify, 1)
    end
end

local function get_message(limit, user_name)
    local t = limit
    local ret = {}
    for k,v in ipairs(notify) do
        if v.name ~= user_name then
            table.insert(ret, v)
            t = t - 1
            if t <= 0 then break end
        end
    end
    return ret
end

local function format_string(user_name, nickname, type, data)
    local str = nil
    if type == 1 then
        str = string.format(lang.notify1,
            nickname, Character_conf[data].CN_NAME)
    elseif type == 2 then
        str = string.format(lang.notify2, nickname, Character_conf[data].CN_NAME)
    elseif type == 3 then
        str = string.format(lang.notify3, nickname)
    elseif type == 4 then
        str = string.format(lang.notify4, nickname)
    elseif type == 5 then
        str = string.format(lang.notify5, nickname, Character_conf[data].CN_NAME)
    end
    return str
end

function notify_system.add_message(user_name, nickname, type, data)
    discard_message()
    local string = format_string(user_name, nickname, type, data)
    local s = add_message(user_name, string)
    local o = get_message(39, user_name)
    local ret = {} 
    tinsert(ret, s)
    for k,v in ipairs(o) do
        tinsert(ret, v)
    end
    return ret
end

function notify_system.get_message(user_name)
    discard_message()
    local ret = get_message(40, user_name)
    if rawlen(ret) == 0 then return nil end
    return ret
end

return notify_system