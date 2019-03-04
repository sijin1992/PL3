local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert

local level = {}
local max_level = Player_Exp_conf.index[rawlen(Player_Exp_conf.index)]
for k = 1,max_level do
    tinsert(level, {})
end

local kc = require "kyotocabinet"
local db = kc.DB:new()

local is_block = require "block"
if not db:open("pve2_pool.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
    error("pve2_power.lua open err")
else
    local remove_list = {}
    db:iterate(
        function(k,v)
            if not is_block(k) then
                local l = tonumber(v)
                assert(l <= max_level and l > 0)
                rawset(level[l], k, 1)
            else
                table.insert(remove_list, k)
            end
        end, false
    )
    for k,v in ipairs(remove_list) do
        db:remove(v)
        LOG_INFO(v.." del from pve2list")
    end
end

local function change_level(user_name, old_level, new_level)
    assert(old_level <= max_level and old_level > 0)
    assert(new_level <= max_level and new_level > 0)
    rawset(level[old_level], user_name, nil)
    rawset(level[new_level], user_name, 1)
    db:set(user_name, new_level)
end

local function get_tags_by_level(minlev, maxlev, num, tags_pool, self_name)
    local pool = {}
    for k = minlev,maxlev do
        local lev_pool = level[k]
        local poollen = rawlen(lev_pool)
        local get_num = 0
        for k1,_ in pairs(lev_pool) do
            tinsert(pool, k1)
            get_num = get_num + 1
            if get_num >= 20 then break end
        end
    end
    local get_pool = {} --匹配目标先放这里，最后要乱序插入队列中
    local get_num = 0
    while get_num < num do
        local total_num = rawlen(pool)
        if total_num == 0 then break end
        local t = mrandom(total_num)
        local name = pool[t]
        table.remove(pool, t)
        local new_tag = true
        if name ~= self_name then
            for k,v in ipairs(get_pool) do
                if v == name then
                    new_tag = false
                    break
                end
            end
            if new_tag then
                for k,v in ipairs(tags_pool) do
                    if v == name then
                        new_tag = false
                        break
                    end
                end 
            end
            if new_tag then
                tinsert(get_pool, name)
                get_num = get_num + 1
            end
        end
    end
    if get_num < num then
        local ttt = 1
        while get_num < num do
            local name = string.format("Robot_%d", ttt)
            ttt = ttt +1
            local new_tag = true
            for k,v in ipairs(get_pool) do
                if v == name then
                    new_tag = false
                    break
                end
            end
            if new_tag then
                for k,v in ipairs(tags_pool) do
                    if v == name then
                        new_tag = false
                        break
                    end
                end 
            end
            if new_tag then
                tinsert(get_pool, name)
                get_num = get_num + 1
            end
        end
    end
    while 1 do
        local len = rawlen(get_pool)
        if len == 0 then break end
        local t = mrandom(len)
        tinsert(tags_pool, get_pool[t])
        table.remove(get_pool, t)
    end
end

local function get_tags(level, user_name)
    local level_lev = 0--当前等级在配置表中的level
    for k = Dispute_Lay_conf.len,1,-1 do
        if level >= Dispute_Lay_conf.index[k] then
            level_lev = Dispute_Lay_conf.index[k]
            break
        end
    end
    local conf = Dispute_Lay_conf[level_lev]
    local tags_pool = {}
    local lay = conf.LAY_1
    get_tags_by_level(lay[1], lay[2], lay[3], tags_pool, user_name)
    lay = conf.LAY_2
    get_tags_by_level(lay[1], lay[2], lay[3], tags_pool, user_name)
    lay = conf.LAY_3
    get_tags_by_level(lay[1], lay[2], lay[3], tags_pool, user_name)
    lay = conf.LAY_4
    get_tags_by_level(lay[1], lay[2], lay[3], tags_pool, user_name)
    return tags_pool, level_lev
end

local pve2_module = {
    get_tags = get_tags,
    change_level = change_level,
}

    
return pve2_module