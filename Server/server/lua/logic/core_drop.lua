math.randomseed(os.time())

local function do_drop(id)
    local conf = Drop_conf[id]
    assert(conf)
    if conf.Num > 0 then
        return conf.DROP_ITEM, conf.Num
    end
    local t = math.random(100)
    local num = 0
    for k,v in ipairs(conf.DROP_PROBABILITY) do
        if t <= v then
            num = k
            break
        else
            t = t - v
        end
    end
    return conf.DROP_ITEM, num
end

local function do_choujiang_from_34(conf, pool_list, repeated)
    local done = false
    local t_tab = {}
    local total = 0
    local k = 1
    while conf.BOX_SORT[k] do
        table.insert(t_tab, {conf.BOX_SORT[k], conf.BOX_SORT[k + 1]})
        total = total + conf.BOX_SORT[k + 1]
        k = k + 2
    end
    local total_num = 0
    for k,v in ipairs(t_tab) do
        v[2] = v[2]/total*1000
        total_num = total_num + 1
    end

    while not done do
        local t = math.random(1000)
        
        local idx = 0
        assert(#t_tab > 0, string.format("%d", conf.BOX_ID))
        for k,v in ipairs(t_tab) do
            idx = idx + 1
            local id = v[1]
            local num = 1
            local proc = v[2]
            if t <= proc or idx == total_num then
                if id >= 3500000 and id < 3600000 then
                    id, num = do_drop(id)
                end
                if num > 0 then
                    done = true
                    if not repeated then
                        for _,v1 in ipairs(pool_list) do
                            if v1[1] == id then
                                done = false
                                table.remove(t_tab, k)
                                break
                            end
                        end
                    end
                    if done then
                        table.insert(pool_list, {id, num})
                    end
                end
                break
            else
                t = t - proc
            end
        end
    end
end

local function do_choujiang_from_1(conf, pool_list, repeated)
    if conf.LOTTERY_TYPE == 1 then -- N in 1
        local t = math.random(100)
        local k = 1
        while conf.LOTTERY_LIST[k] do
            local id = conf.LOTTERY_LIST[k]
            local num = conf.LOTTERY_LIST[k + 1]
            local proc = conf.LOTTERY_LIST[k + 2]
            if t <= proc then
                if id  >= 100001 and id < 100100 then
                    local n_conf = Lottery_conf[id]
                    do_choujiang_from_1(n_conf, pool_list, repeated)
                else
                    for i = 1, num do
                        local n_conf = Lottery_Pool_conf[id]
                        assert(n_conf)
                        do_choujiang_from_34(n_conf, pool_list, repeated) 
                    end
                end
                break
            else
                t = t - proc
                k = k + 3
            end
        end
    else--多抽
        local k = 1
        while conf.LOTTERY_LIST[k] do
            local id = conf.LOTTERY_LIST[k]
            local num = conf.LOTTERY_LIST[k + 1]
            local percent = conf.LOTTERY_LIST[k + 2]
            local randnum = math.random(100)               
            if randnum <= percent then
                --Tools._print("id:"..id.." ".. randnum.." ".. percent)
                if id  >= 100001 and id < 100100 then
                    local n_conf = Lottery_conf[id]
                    do_choujiang_from_1(n_conf, pool_list, repeated)
                else
                    for i = 1, num do
                        local n_conf = Lottery_Pool_conf[id]
                        assert(n_conf)
                        do_choujiang_from_34(n_conf, pool_list, repeated) 
                    end
                end
            end
            k = k + 3
        end
    end
end

local function get_item_list_from_id(id--[[物品id]], item_list--[[存放的list]], repeated--[[默认nil（false），是否需要检测重复项]])
    local t_list = {}
    if id >= 100000 and id <= 199999 then
        local conf = Lottery_conf[id]
        assert(conf)
        do_choujiang_from_1(conf, t_list, repeated)
    elseif id >= 3400000 and id <= 3499999 then
        local conf = Lottery_Pool_conf[id]
        assert(conf)
        do_choujiang_from_34(conf, t_list, repeated)
    elseif id >= 3500000 and id <= 3599999 then
        local id, num = do_drop(id)
        if num > 0 then
            table.insert(t_list, {id, num})
        end
    elseif id >= 190000000 and id <= 199999999 then
        --在掉落表中，直接填物品id的话，意味着物品数量必然是1，否则要填35表
        table.insert(t_list, {id, 1})
    else
        assert(false, "id error")
    end

    for k,v in ipairs(t_list) do
        table.insert(item_list, v)
    end
end

local core_drop = {
    do_drop = do_drop,
    do_choujiang_from_34 = do_choujiang_from_34,
    do_choujiang_from_1 = do_choujiang_from_1,
    get_item_list_from_id = get_item_list_from_id,
}

return core_drop