local core_user = require "core_user_funcs"
local core_money = require "core_money"
local core_drop = require "core_drop"
local core_task = require "core_task"

local do_choujiang_from_1 = core_drop.do_choujiang_from_1
local do_choujiang_from_34 = core_drop.do_choujiang_from_34

local function get_choujiang_pool(id)--这个conf是Lottery中的条目
    local pool_list = {}
    local conf = Lottery_conf[id]
    assert(conf)
    do_choujiang_from_1(conf, pool_list)
    return pool_list
end

local function get_item(items, main_data, knight_list, item_list, cost_gold, cost_money, ext_item)
    local list = {}
    local ext_items = {}
    local ret = {
        gold = main_data.gold,
        money = main_data.money,
        choujiang_struct = main_data.choujiang,
        list = list,
        cost_gold = cost_gold,
        cost_money = cost_money,
        chengjiu_list = nil,
        ext_item = ext_items
    }
    for k,v in ipairs(items) do
        local id = v[1]
        local num = v[2]
        local entry = nil
        if id > 10000000 and id < 20000000 then
            local ret = core_user.get_item(id, 1, main_data, 300, knight_list, item_list)
            entry = ret
        else
            local t_item = {}
            core_user.get_item(id, num, main_data, 300, knight_list, item_list, {item_list = t_item}, nil)
            assert(rawlen(t_item) == 1)
            entry = {item = t_item[1]}
        end
        table.insert(list, entry)
    end
    if ext_item then
        local t = {item_list = ext_items}
        for k,v in ipairs(ext_item) do
            core_user.get_item(v[1], v[2], main_data, 300, nil, item_list, t)
        end
    end
    
    return ret
end

local function gold1(is_free, main_data, knight_list, item_list)
    --验证是否免费
    local max_num = 5
    local cost = 20000
    local today_num = main_data.choujiang.today_gold_num
    local pool_id = 100036
    if is_free == 1 then
        if today_num < max_num then
            local time = os.time()
            local next_gold_time = main_data.choujiang.next_gold_time
            assert(time >= next_gold_time, "gold1, cd 10min")
            main_data.choujiang.next_gold_time = time + 600
            cost = 0
            main_data.choujiang.today_gold_num = today_num + 1
            local t = main_data.choujiang.gold_free_num
            t = t + 1
            main_data.choujiang.gold_free_num = t
            if t == 1 then
                pool_id = 100043
            end
        else
            error("gold1, no more free chance")
        end
    else
        main_data.choujiang.gold_num = main_data.choujiang.gold_num + 1
    end

    if cost > 0 then
        assert(is_free == 0, "want free, cost is not 0")
        core_user.expend_item(191010001, cost, main_data, 300, nil, nil)
    end
    
    local pool_list = get_choujiang_pool(pool_id)
    return get_item(pool_list, main_data, knight_list, item_list, cost, 0,
        {{192010009, 1}})
end

local function random_list(list)
    local new_list = {}
    while #list > 0 do
        local i = math.random(#list)
        table.insert(new_list, list[i])
        table.remove(list,i)
    end
    return new_list
end

local function gold10(main_data, knight_list, item_list)
    local cost = 180000
    core_user.expend_item(191010001, cost, main_data, 300)
    main_data.choujiang.gold10_num = main_data.choujiang.gold10_num + 1
    local pool_list = get_choujiang_pool(100004)
    pool_list = random_list(pool_list)
    return get_item(pool_list, main_data, knight_list, item_list, cost, 0,
        {{192010009, 10}})
end

local function money1(is_free, main_data, knight_list, item_list)
    --验证是否免费
    local cost = 288
    local pool_id = 100035
    if is_free == 1 then
        local time = os.time()
        local next_money_time = main_data.choujiang.next_money_time
        assert(time >= next_money_time, "money1, cd 46hour")
        local t = main_data.choujiang.money1_free_num
        if t == 0 then
            pool_id = 100026
        end
        main_data.choujiang.money1_free_num = t + 1
        main_data.choujiang.next_money_time = time + 165600
        cost = 0
    end
    if cost > 0 then
        local t = main_data.choujiang.money1_num
        if t == 0 then
            pool_id = 100037
        end
        main_data.choujiang.money1_num = t + 1
        local ret = core_money.use_money(cost, main_data, 1, 303)
    end
    main_data.choujiang.total_money_num = main_data.choujiang.total_money_num + 1
    
    local pool_list = get_choujiang_pool(pool_id)
    return get_item(pool_list, main_data, knight_list, item_list, 0, cost,
        {{193010010, 1}})
end

local function money10(main_data, knight_list, item_list)
    local hot_pool = 3400107
    local hot_point = global_huodong.get_choujiang()
    if hot_point then
        hot_pool = hot_point.pool
    end
    
    local cost = 2590
    local pool = 0
    local ret = core_money.use_money(cost, main_data, 1, 304)
    local use_money = true
    --真元宝使用量超过60%才算真元宝抽奖
    if (ret.use_money_1 / cost) > 0.4 then use_money = false end
    local total_count = 0
    
    if use_money then
        total_count = main_data.choujiang.money10_num + 1
        main_data.choujiang.money10_num = total_count
    else
        total_count = main_data.choujiang.money10_1_num + 1
        main_data.choujiang.money10_1_num = total_count
    end
    
    local total_count_a = main_data.choujiang.total_money10_num + 1
    main_data.choujiang.total_money10_num = total_count_a
    
    local old_money = main_data.choujiang.total_money
    local old_money_1 = main_data.choujiang.total_money_1
    local new_money = old_money + ret.use_money
    local new_money_1 = old_money_1 + ret.use_money_1
    main_data.choujiang.total_money = new_money
    main_data.choujiang.total_money_1 = new_money_1
    
    local special_knight = 0
    --逢2赠送
    if total_count_a > 1 --[[and ((total_count_a - 1) % 2) == 0 ]]then
        local sp_list = Lottery_Pool_conf[3400108].BOX_SORT
        local s_len = rawlen(sp_list) / 2
        local idx = math.random(s_len)
        
        special_knight = sp_list[idx * 2 - 1]
    end
    
    --选择池子
    local pool_id = 0
    if use_money then
        pool_id = 100001
    else
        pool_id = 100008
    end
    
    if total_count_a == 1 then
        pool_id = 100071
    end
    
    local pool_list = get_choujiang_pool(pool_id)
    if special_knight ~= 0 then
        pool_list[1][1] = special_knight
        pool_list[1][2] = 1
    end
    local n_conf = Lottery_Pool_conf[hot_pool]
    assert(n_conf)
    do_choujiang_from_34(n_conf, pool_list, true)
    pool_list = random_list(pool_list)
    return get_item(pool_list, main_data, knight_list, item_list, 0, cost,
        {{193010010, 10}})
end

local function getHaoxiaItems(main_data)
	local money_num_week = main_data.choujiang.money_num_week
	local money_hao_index = main_data.choujiang.money_hao_index
	local haoxia = global_huodong.get_haoxia()
	if haoxia == nil then
		return nil
	end
	if haoxia.index > money_hao_index then		
		money_num_week = 0
	end
	money_num_week = money_num_week + 1
	local wday = os.date("*t").wday	
	local pool_day = haoxia[string.format("xia_%d", wday)]
	local pool_hot;
	if money_num_week < haoxia.num_week then
		pool_hot = haoxia.xia_week
	else
		if money_num_week > haoxia.num_week then
			pool_hot = haoxia.xia_spec
		else
			pool_hot = haoxia.xia_equl
		end
	end
	
	local pools = {[pool_day] = {}, [pool_hot] = {}}
	for key, val in pairs(pools) do
		for i = 1, #Lottery_conf[key].LOTTERY_LIST, 3 do
			local poolId = Lottery_conf[key].LOTTERY_LIST[i]			
			for j = 1, #Lottery_Pool_conf[poolId].BOX_SORT, 2 do
				local dropId = Lottery_Pool_conf[poolId].BOX_SORT[j]
				local itemId
				if dropId >= 3500000 and dropId < 3600000 then
					itemId = Drop_conf[dropId].DROP_ITEM					
				else
					itemId = dropId					
				end
				table.insert(val, {item_id = itemId, item_num = 1})
			end
		end
	end	
	for key, val in pairs(pools) do
		for i = #val, 1, -1 do
			local isExist = false
			for j = 1, i-1 do
				if val[i].item_id + 180000000 == val[j].item_id then
					isExist = true
					break
				end
			end
			if isExist then
				table.remove(val, i)
			else
				if val[i].item_id > 180000000 then
					val[i].item_id = val[i].item_id - 180000000
				end
			end
		end
	end
	
	return pools[pool_day], pools[pool_hot]
end

local function money_haoxia(main_data, knight_list, item_list)
	local money_num_week = main_data.choujiang.money_num_week
	local money_num_total = main_data.choujiang.money_num_total
	local money_hao_index = main_data.choujiang.money_hao_index
	local money_num_luck = main_data.choujiang.money_num_luck
	--LOG_INFO(string.format("user:%s,vip:%d,money:%d,hao_index:%d,money_week:%d,money_luck:%d,money_total:%d", main_data.user_name, main_data.vip_lev, main_data.money, money_hao_index, money_num_week, money_num_luck, money_num_total))
	local retVal =
	{
        gold = main_data.gold,
        money = main_data.money,
        choujiang_struct = main_data.choujiang,
        list = {},
        cost_gold = 0,
        cost_money = 0,
        chengjiu_list = nil,
        ext_item = {}
	}
	local pool_list
	local haoxia = global_huodong.get_haoxia()
	if haoxia then
		if haoxia.index > money_hao_index then
			money_hao_index = haoxia.index
			money_num_week = 0
			money_num_luck = 0
		end

		local isVip = main_data.vip_lev > 7
		if isVip then
			money_num_week = money_num_week + 1
			money_num_total = money_num_total + 1
	
			local wday = os.date("*t").wday	
			local pool_day = haoxia[string.format("xia_%d", wday)]
			pool_list = get_choujiang_pool(pool_day)
			local pool_list_hot
			if money_num_week < haoxia.num_week then
				pool_list_hot = get_choujiang_pool(haoxia.xia_week)
			else
				if money_num_week > haoxia.num_week then
					if money_num_week - money_num_luck < haoxia.num_week then
						pool_list_hot = get_choujiang_pool(haoxia.xia_spec)
					else
						pool_list_hot = get_choujiang_pool(haoxia.xia_equl)
					end
				else
					pool_list_hot = get_choujiang_pool(haoxia.xia_equl)
				end
			end
			for k, v in ipairs(pool_list_hot) do
				table.insert(pool_list, v)
			end

			for k, v in ipairs(pool_list) do
				if v[1] > 10010000 and v[1] < 19990000 then
					money_num_luck = money_num_week
					break
				end
			end
			pool_list = random_list(pool_list)

			local cost = 850
			local ret = core_money.use_money(cost, main_data, 1, 312)
			
			main_data.choujiang.money_num_week = money_num_week
			main_data.choujiang.money_num_total = money_num_total
			main_data.choujiang.money_hao_index = money_hao_index
			main_data.choujiang.money_num_luck = money_num_luck
			retVal = get_item(pool_list, main_data, knight_list, item_list, 0, cost, {{193010010, 10}})
		end
	end
	--LOG_INFO(string.format("money_week:%d,pool_list:%s", money_num_week, print_t(retVal.list)))
	return retVal
end

local choujiang = {
    gold1 = gold1,
    gold10 = gold10,
    money1 = money1,
    money10 = money10,
    money_haoxia = money_haoxia,
    getHaoxiaItems = getHaoxiaItems
}
return choujiang