local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert

local kc = require "kyotocabinet"
local db = kc.DB:new()

if not db:open("pvp_rcd.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
    db:set("total", "0")
end
if not db:get("total") then db:set("total", "0") end

local function add_new_rcd(string, old_idx)
    local cur_idx = db:get("total")
    assert(cur_idx)
    cur_idx = tonumber(cur_idx)
    assert(cur_idx)
    if not db:set(cur_idx, string) then
        error("somethine err")
    end
    if old_idx >= 0 then
        db:remove(old_idx)
    end
    local new_idx = cur_idx + 1
    db:set("total", new_idx)
    return cur_idx
end

local function get_rcd(idx)
    local rcd = db:get(idx)
    return rcd
end

local pvp_rcd = {
    kc = kc,
    db = db,
    add_rcd = add_new_rcd,
    get_rcd = get_rcd,
    }

    
return pvp_rcd