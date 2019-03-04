local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert

local crank = require "rank_module.c"
local ud = nil


local rank_list = {}

rank_list.max = 10000

rank_list.rank_list_id = {}
rank_list.rank_list_name = {}

function rank_list.load()
    local ret = nil
    ud, ret = crank.load(rank_list.rank_list_id, "rank_list.mmap", 10000)
    local total_entry = #rank_list.rank_list_id
    if total_entry > rank_list.max then total_entry = rank_list.max end
    
    for k,v in ipairs(rank_list.rank_list_id) do
        rawset(rank_list.rank_list_name, v.name, {idx = k, lock = false})
    end
    local robot_list = robot_list10
    
    if total_entry < 50 then
        total_entry = 0        
        for k,v in ipairs(robot_list) do
            local a = string.format("Robot_%d", k)
            local data = {name = a, nickname = v.nickname, power = v.power10, level = 10, sex = v.lead.sex,reputation = v.PVP.reputation, star = v.lead.star}
            table.insert(rank_list.rank_list_id, data)
            rawset(rank_list.rank_list_name, a, {idx = k, lock = false})
            local r = crank.add_rank(ud, k, data)
            total_entry = total_entry + 1
        end
    end
    
    ----[[
    --封号玩家要被踢出榜单
    local is_block = require "block"
    local t_idx = 4001
    for k,v in pairs(rank_list.rank_list_name) do
        if is_block(k) then
            local a = string.format("Robot_%d", t_idx)
            local rob = robot_list[t_idx % 3000]
            local data = {name = a, nickname = rob.nickname, power = rob.power10, level = 10, sex = rob.lead.sex,reputation = rob.PVP.reputation, star = rob.lead.star}
            local idx = v.idx
            local name_data = {idx = idx, lock = false}
            if not crank.force_modify(ud, idx, data) then
                error("modify err")
            end
            rank_list.rank_list_id[idx] = data
            rawset(rank_list.rank_list_name, a, name_data)
            rawset(rank_list.rank_list_name, k, nil)
            LOG_INFO(k.." del from ranklist, use "..a)
            t_idx = t_idx + 1
        end
    end
    --]]

    rank_list.total = total_entry
end

local function get_tag_by_idx(self_idx)
    --[[
        rank取值区间为：
        [cur-1, cur-10],(mid+10, mid-10),[limit+10,limit]
    ]]
    local last = 0
    local first = 0
    local mid = 0
    if self_idx > 610 then
        last = mrandom(self_idx - 10, self_idx - 1)
        first = mrandom(self_idx - 510, self_idx - 490)
        mid = mrandom(self_idx - 259, self_idx - 241)
    elseif self_idx > 600 then
        last = mrandom(self_idx - 10, self_idx - 1)
        first = mrandom(101, self_idx - 490)
        local tmid = mfloor((self_idx + 100) / 2)
        mid = mrandom(tmid - 9, tmid + 9)
    elseif self_idx > 300 then
        last = mrandom(self_idx - 10, self_idx - 1)
        first = mrandom(101, 110)
        local tmid = mfloor((self_idx + 100) / 2)
        mid = mrandom(tmid - 9, tmid + 9)
    elseif self_idx > 100 then
        last = mrandom(self_idx - 10, self_idx - 1)
        first = mrandom(11, 21)
        local tmid = mfloor((self_idx + 10) / 2)
        mid = mrandom(tmid - 9, tmid + 9)
    elseif self_idx > 40 then
        last = mrandom(self_idx - 10, self_idx - 1)
        first = mrandom(2, 12)
        local tmid = mfloor((self_idx + 2) / 2)
        mid = mrandom(tmid - 9, tmid + 9)
    elseif self_idx > 10 then
        last = mrandom(self_idx - 3, self_idx - 1)
        first = mrandom(2, 4)
        local tmid = mfloor((self_idx + 2) / 2)
        mid = mrandom(tmid - 1, tmid + 1)
    elseif self_idx > 7 then
        first = mrandom(1,2)
        local tmid = mfloor((self_idx + 1) / 2)
        mid = mrandom(tmid - 1, tmid + 1)
        last = mrandom(self_idx - 2, self_idx - 1)
    elseif self_idx == 7 then
        first = mrandom(1,2)
        mid = mrandom(3,4)
        last = mrandom(5,6)
    elseif self_idx == 6 then
        first = mrandom(1,2)
        mid = 3
        last = mrandom(4,5)
    elseif self_idx == 5 then
        first = mrandom(1,2)
        mid = 3
        last = 4
    elseif self_idx == 4 then
        first = 1
        mid = 2
        last = 3
    elseif self_idx == 3 then
        first = 1
        mid = 2
        last = 4
    elseif self_idx == 2 then
        first = 1
        mid = 3
        last = 4
    elseif self_idx == 1 then
        first = 2
        mid = 3
        last = 4
    end
    return first, mid, last
end

--[[
function rank_list.test()
    print("num = ", rank_list.total)
    print("1000:", get_tag_by_idx(1000))
    print("611", get_tag_by_idx(611))
    print("600", get_tag_by_idx(600))
    print("301", get_tag_by_idx(301))
    print("300", get_tag_by_idx(300))
    print("101", get_tag_by_idx(101))
    print("99", get_tag_by_idx(99))
    print("42", get_tag_by_idx(42))
    print("41", get_tag_by_idx(41))
    print("40", get_tag_by_idx(40))
    print("11", get_tag_by_idx(11))
    print("10", get_tag_by_idx(10))
    print("9", get_tag_by_idx(9))
    print("8", get_tag_by_idx(8))
    print("7", get_tag_by_idx(7))
    print("6", get_tag_by_idx(6))
    print("5", get_tag_by_idx(5))
    print("4", get_tag_by_idx(4))
    print("3", get_tag_by_idx(3))
    print("2", get_tag_by_idx(2))
    print("1", get_tag_by_idx(1))
end
]]

function rank_list.get_target(player, main_data)
    --rank_list.test()
    local self_entry = rawget(rank_list.rank_list_name, player)
    local self_idx = 0
    if self_entry == nil or self_entry.idx == 0 then self_idx = rank_list.total + 1
    else self_idx = self_entry.idx end
    local last = 0
    local mid = 0
    local first = 0
    first, mid, last = get_tag_by_idx(self_idx)
    local ret = {}
    tinsert(ret, {idx = first, entry = rank_list.rank_list_id[first]})
    tinsert(ret, {idx = mid, entry = rank_list.rank_list_id[mid]})
    tinsert(ret, {idx = last, entry = rank_list.rank_list_id[last]})
    return ret
end

function rank_list.get_self(player, main_data)
    local pvp = main_data.PVP
    local rank_data = nil
    local self_entry = rawget(rank_list.rank_list_name, player)
    if self_entry == nil or self_entry.idx == 0 then
        rank_data = {idx = 0, entry = {
                    name = player,
                    nickname = main_data.nickname,
                    power = main_data.power,
                    level = main_data.lead.level,
                    sex = main_data.lead.sex,
                    reputation = main_data.PVP.reputation,
                    star = main_data.lead.star}}
    else
        rank_data = {idx = self_entry.idx, entry = rank_list.rank_list_id[self_entry.idx]}
    end
    return pvp, rank_data
end

function rank_list.get_idx_by_name(name)
    local entry = rawget(rank_list.rank_list_name, name)
    local idx = 10001
    if entry and entry.idx > 0 then
        idx = entry.idx
    end
    return idx
end

function rank_list.check_fight(player, tag_idx)
    local self_entry = rawget(rank_list.rank_list_name, player)
    local self_idx = 0
    if self_entry == nil or self_entry.idx == 0 then self_idx = rank_list.total + 1
    else self_idx = self_entry.idx end
    if tag_idx == 1 then assert(self_idx <= 10)
    elseif tag_idx <= 10 then assert(self_idx <= 100)
    elseif tag_idx <= 100 then assert(self_idx <= 300)
    else assert(self_idx <= (tag_idx + 500))
    end
end

function rank_list.change_rank(tag_idx, self_name, main_data)
    local delta_rank = 0
    local self_entry = rawget(rank_list.rank_list_name, self_name)
    local tag_idx_entry = rawget(rank_list.rank_list_id, tag_idx)
    local tag_entry = rawget(rank_list.rank_list_name, tag_idx_entry.name)
    local self_idx_entry = nil
    local self_idx = 0
    local add_flag = false
    if self_entry == nil or self_entry.idx == 0 then
        -- 玩家不在榜上
        add_flag = true
        self_idx = rank_list.total + 1
        self_idx_entry = {  name = self_name,
                            nickname = main_data.nickname,
                            power = main_data.power,
                            level = main_data.lead.level,
                            sex = main_data.lead.sex,
                            reputation = main_data.PVP.reputation,
                            star = main_data.lead.star}
        local ret = crank.add_rank(ud, tag_idx, self_idx_entry)
        assert(ret, "c.add_rank err")
        rawset(rank_list.rank_list_name, self_name, {idx = tag_idx, lock = false})
        rawset(rank_list.rank_list_id, tag_idx, self_idx_entry)
        if self_idx <= rank_list.max then
            if self_idx < rank_list.max then
                rank_list.total = rank_list.total + 1
            end
            tag_entry.idx = self_idx
            rawset(rank_list.rank_list_id, self_idx, tag_idx_entry)
        else    -- 目标被挤下榜
            rawset(rank_list.rank_list_name, tag_idx_entry.name, nil)
        end
        delta_rank = self_idx - tag_idx
    else
        self_idx = self_entry.idx
        self_idx_entry = rawget(rank_list.rank_list_id, self_idx)
        if self_idx > tag_idx then -- 如果玩家排名在前，则不更换排名
            --玩家在榜上，直接交换
            assert(crank.change_rank(ud, self_idx, tag_idx), "c.change_rank err")
            rawset(rank_list.rank_list_id, tag_idx, self_idx_entry)
            rawset(rank_list.rank_list_id, self_idx, tag_idx_entry)
            tag_entry.idx = self_idx
            self_entry.idx = tag_idx
            delta_rank = self_idx - tag_idx
        else
            tag_idx = self_idx
        end
    end
    return {idx = tag_idx, entry = self_idx_entry}, delta_rank
end

function rank_list.get_top_n()
    local ret = {}
    for k = 1,50 do
        tinsert(ret, {idx = k, entry = rank_list.rank_list_id[k]})
    end
    return ret
end

function rank_list.modify_power(name, power)
    local idx = rawget(rank_list.rank_list_name, name)
    if idx then
        local ret = crank.modify(ud, idx.idx, power, 0)
        assert(ret, "c.modify err")
        local entry = rawget(rank_list.rank_list_id, idx.idx)
        assert(entry)
        entry.power = power
    end
end

function rank_list.modify_star(name, star)
    local idx = rawget(rank_list.rank_list_name, name)
    if idx then
        local ret = crank.modify(ud, idx.idx, star, 2)
        assert(ret, "c.modify err")
        local entry = rawget(rank_list.rank_list_id, idx.idx)
        assert(entry)
        entry.star = star
    end
end

function rank_list.modify_level(name, level)
    local idx = rawget(rank_list.rank_list_name, name)
    if idx then
        local ret = crank.modify(ud, idx.idx, level, 1)
        assert(ret, "c.modify err")
        local entry = rawget(rank_list.rank_list_id, idx.idx)
        assert(entry)
        entry.level = level
    end
end

function rank_list.modify_reputation(name, reputation)
    local idx = rawget(rank_list.rank_list_name, name)
    if idx then
        local ret = crank.modify(ud, idx.idx, reputation, 3)
        assert(ret, "c.modify err")
        local entry = rawget(rank_list.rank_list_id, idx.idx)
        assert(entry)
        entry.reputation = reputation
    end
end

return rank_list