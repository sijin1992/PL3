local kc = require "kyotocabinet"
local db = kc.DB:new()

db:open("cangjian.kch", kc.DB.OWRITER + kc.DB.OCREATE)

if db:count() == 0 then
    for k = 1, 100 do
        local name = string.format("%d", k)
        local idx = math.random()
        db:set(name, idx)
    end
end

local cache = {}

db:iterate(function(k,v)
                local t = rawget(cache, v)
                if not t then
                    t = {}
                    rawset(cache, v, t)
                end
                table.insert(t, k)
            end, false)

            
local function change_power(name, power)
    local old_power = db:get(name)
    if old_power then
        local t = rawget(cache, old_power)
        assert(t)
        for k,v in ipairs(t) do
            if v == name then
                table.remove(t, k)
                break
            end
        end
    end
    local t = rawget(cache, power)
    if not t then
        t = {}
        rawset(cache, power, t)
    end
    table.insert(t, name)
    db:set(name, power)
end

local function get_tags(name, power)
    if not db:get(name) then change_power(name, power) end
    local count = 0
    local max
    
    local ret = {}
    for k = 1, 15 do
        table.insert(ret, math.random(100))
    end
    return ret
end

local pve2 = {
    change_power = change_power,
    get_tags = get_tags,
}

return pve2