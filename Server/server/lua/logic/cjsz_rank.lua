local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert

local sw_list = {}      -- 声望-->{name1,name2}
local name_list = {}    -- name-->data
local total_sw = 0
local max_sw = 0        --榜上最高
local min_sw = 5000     --榜上最低
local cur_sub = -1

local last_sub = -1
local last_name_list = {}   --name-->名次

local kc = require "kyotocabinet"
local db = kc.DB:new()

if not db:open("cjsz.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
    error("cjsz_rank.lua open err")
else
    if db:count() == 0 then
        db:set("total_sw", "0")
        db:set("sub_id", cur_sub)
    end
    db:iterate(
        function(k,v)
            if k == "total_sw" then total_sw = tonumber(v)
            elseif k == "sub_id" then cur_sub = tonumber(v)
            elseif string.sub(k, 1, 4) == "last" then
                local tstr = string.sub(k, 5)
                if tstr == "subid" then
                    last_sub = tonumber(v)
                else
                    rawset(last_name_list, tstr, tonumber(v))
                end
            else
                local pb = require "protobuf"
                local d = pb.decode("cjsz_rank", v)
                local sw = d.shengwang
                if sw > max_sw then max_sw = sw end
                if sw < min_sw then min_sw = sw end
                local sw_entry = rawget(sw_list, sw)
                if not sw_entry then
                    sw_entry = {}
                    rawset(sw_list, sw, sw_entry)
                end
                tinsert(sw_entry, k)
                name_list[k] = d
            end
        end, false
    ) 
end

local function change_rank(user_name, sw, sex, star, nickname)
    local data = rawget(name_list, user_name)
    local changed = false
    local old_sw = 0
    if not data then    -- 新上榜
        data = {name = user_name, nickname = nickname, shengwang = sw, sex = sex,star = star}
        rawset(name_list, user_name, data)
        changed = true
        old_sw = -1
        if sw > max_sw then max_sw = sw end
    else
        if data.star ~= star then
            data.star = star
            changed = true
        end
        if data.shengwang < sw then
            old_sw = data.shengwang
            data.shengwang = sw
            changed = true
            if sw > max_sw then max_sw = sw end
        else
            return
        end
    end
    if old_sw > 0 then  -- 声望变更，移除原来的声望
        local old_entry = sw_list[old_sw]
        for k,v in ipairs(old_entry) do
            if v == user_name then
                table.remove(old_entry, k)
            end
        end
    end
    if old_sw ~= 0 then
        local sw_entry = rawget(sw_list, sw)
        if not sw_entry then
            sw_entry = {}
            rawset(sw_list, sw, sw_entry)
        end
        tinsert(sw_entry, user_name)
    end
    if changed then
        local pb = require "protobuf"
        local t = pb.encode("cjsz_rank", data)
        db:set(user_name, t)
    end
end

local function change_star(user_name, star)
    local data = rawget(name_list, user_name)
    local changed = false
    if not data then    -- 新上榜
        return
    end
    if data.star ~= star then
        data.star = star
        changed = true
    end
    if changed then
        local pb = require "protobuf"
        local t = pb.encode("cjsz_rank", data)
        db:set(user_name, t)
    end
end

local function add_global_sw(value)
    --TODO:
    --if total_sw < 1000 then total_sw = 5000000 end
    total_sw = total_sw + value
    db:set("total_sw", total_sw)
end

local function get_global_sw()
    return total_sw
end

local function get_top50()
    local top50 = {}
    local n = 0
    for k = max_sw,min_sw,-1 do
        local e = rawget(sw_list, k)
        if e then
            for k1,v1 in ipairs(e) do
                tinsert(top50, clonetab(name_list[v1]))
                n = n + 1
                if n >= 50 then break end
            end
            if n >= 50 then break end
        end
    end
    return top50
end

local function get_self_rank(user_name)
    local rank = -1
    local rank_data = rawget(name_list, user_name)
    if rank_data then
        rank = 1
        for k = max_sw, rank_data.shengwang + 1, -1 do
            local e = rawget(sw_list, k)
            if e then
                rank = rank + rawlen(e)
            end
        end
    end
    return rank
end

local function get_last_rank(user_name, sub_id)
    local rank = -1
    if sub_id == cur_sub then--可能定时刷新还没刷到
        return get_self_rank(user_name)
    else
        if sub_id ~= last_sub then return rank end
        local t = rawget(last_name_list, user_name)
        if t and t < 10000 then
            rank = t
            t = rank + 10000
            rawset(last_name_list, user_name, t)
            db:set("last"..user_name, t)
        end
        return rank
    end
end

local function reflesh_cur_sub(_cur_sub)
    if cur_sub ~= _cur_sub then
        last_sub = cur_sub
        last_name_list = {}
        local idx = 1
        for k = max_sw, 5000, -1 do
            local e = rawget(sw_list, k)
            if e then
                for k1,v1 in ipairs(e) do
                    last_name_list[v1] = idx
                end
                idx = idx + rawlen(e)
            end
        end
        db:clear()
        db:set("total_sw", "0")
        db:set("sub_id", _cur_sub)
        db:set("lastsubid", last_sub)
        for k,v in pairs(last_name_list) do
            db:set("last"..k, v)
        end
        cur_sub = _cur_sub
        sw_list = {}
        name_list = {}
        total_sw = 0
        max_sw = 0
        min_sw = 5000
    end
end

local function get_cur_sub()
    return cur_sub
end

local cjsz_rank = {
    get_top50 = get_top50,
    get_global_sw = get_global_sw,
    add_global_sw = add_global_sw,
    change_rank = change_rank,
    change_star = change_star,
    get_self_rank = get_self_rank,
    cur_sub = reflesh_cur_sub,
    get_cur_sub = get_cur_sub,
    get_last_rank = get_last_rank,
}

    
return cjsz_rank