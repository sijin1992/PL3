local core_money = require "core_money"
local core_user = require "core_user_funcs"
local core_task = require "core_task"
local core_drop = require "core_drop"

local cjsz_rank = cjsz_rank
local huodong = {}

function huodong.caishendao(main_data)
    local csd = global_huodong.get_huodong(main_data,"csd")
    assert(csd)
    local csd_level = main_data.huodong.caishendao
    assert(csd_level, "caishendao level is nil")
    local conf = Activity_Cai_conf[csd_level]
    assert(conf, "caishendao conf not find")
    local ret = core_money.use_money(conf.Grade, main_data, 0, 400)
    local get_money = 0
    local get_money_1 = 0
    if ret.use_money > 0 then
        local real_tab = {}
        local t = 0
        local k = 1
        while conf.RealGold[k] do
            table.insert(real_tab, {conf.RealGold[k], conf.RealGold[k + 1]})
            t = t + conf.RealGold[k + 1]
            k = k + 2
        end
        local tt = math.random(t)
        for k,v in ipairs(real_tab) do
            if tt <= v[2] then
                get_money = math.floor(ret.use_money * v[1] / 100)
                break
            else
                tt = tt - v[2]
            end
        end
    end
    if ret.use_money_1 > 0 then
        local unreal_tab = {}
        local t = 0
        local k = 1
        while conf.Fake[k] do
            table.insert(unreal_tab, {conf.Fake[k], conf.Fake[k + 1]})
            t = t + conf.Fake[k + 1]
            k = k + 2
        end
        local tt = math.random(t)
        for k,v in ipairs(unreal_tab) do
            if tt <= v[2] then
                get_money_1 = math.floor(ret.use_money_1 * v[1] / 100)
                break
            else
                tt = tt - v[2]
            end
        end
    end
    core_user.get_item(191010099, get_money, main_data, 400)
    core_user.get_item(191010003, get_money_1, main_data, 400)
    main_data.huodong.caishendao = conf.Nex_Index
    --刷新红点
    local t = main_data.ext_data.huodong.caishen
    t = t - 1
    if t < 0 then t = 0 end
    main_data.ext_data.huodong.caishen = t
    return get_money + get_money_1
end

function huodong.cangjian_refresh(cangjian)
	
	local shop_list = {}
    local item_list = {}
    local huodong_idx = 432010000 + cangjian.sub_id
    local total = 0
	--先选取weight=0的
    for k,v in ipairs(Cang_Goods_conf.index) do
		local conf = Cang_Goods_conf[v]
        if conf.Activity_ID == huodong_idx then
			if conf.Weight == 0 then
				local shop_item = {
					item_id = conf.Goods_ID, 
					soldout = 0,
					src_item = {
						id = conf.Coin_Item[1],
						num = conf.Coin_Item[2],
					},	--新增,消耗的物品
					tar_item = {
						id = conf.Good_Item[1],
						num = conf.Good_Item[2],
					},	--新增,兑换的物品
					score = conf.Add_Devote, --新增,获得的声望
				}
				table.insert(shop_list, shop_item)
				if rawlen(shop_list) >= 3 then break end
			else
				table.insert(item_list, conf)
				total = total + conf.Weight
			end
        elseif conf.Activity_ID > huodong_idx then break
        end
	end
	--不满足数量时，随机选取
	for k = rawlen(shop_list) + 1,3 do
		local add = false
		while not add do
			local t = math.random(total)
			local id = 0
			for k,v in ipairs(item_list) do
				local conf = v
				assert(conf.Goods_ID > 0)
				local weight = conf.Weight
				if weight > 0 then
					if t <= weight then
						id = conf.Goods_ID
						break
					else
						t = t - weight
					end
				end
			end
			add = true
			for k,v in ipairs(shop_list) do
				if v.item_id == id then
					add = false
					break
				end
			end
			if add then
				local conf = Cang_Goods_conf[id]
				local shop_item = {
					item_id = conf.Goods_ID, 
					soldout = 0,
					src_item = {
						id = conf.Coin_Item[1],
						num = conf.Coin_Item[2],
					},	--新增,消耗的物品
					tar_item = {
						id = conf.Good_Item[1],
						num = conf.Good_Item[2],
					},	--新增,兑换的物品
					score = conf.Add_Devote, --新增,获得的声望
				}
				table.insert(shop_list, shop_item)
			end
		end
	end
		
	cangjian.shop_list = shop_list
end

function huodong.get_shoplist(force, main_data)
    local cangjian_data = global_huodong.get_huodong(main_data,"cangjian")
    local rsync = nil
    assert(cangjian_data, "has no cang_jian_shan_zhuang")
    local begin_t = cangjian_data.begin_time
    local end_t = cangjian_data.end_time
    local now_t = os.time()
    
    local thuodong = main_data.huodong
    local t = thuodong.cangjian.next_time
    local cangjian = rawget(thuodong, "cangjian")
    local reflesh_shoplist = false
    if not cangjian or cangjian.sub_id ~= cangjian_data.sub_id then
    --新的藏剑山庄活动
        local cang_quan = global_huodong.get_cur_cang_quan(cangjian_data)
        assert(force == 0)
        local next_time = begin_t + 3600
        while next_time <= now_t do next_time = next_time + 3600 end
        local reward = {}
        for k = 1, rawlen(cang_quan) do
            table.insert(reward, 0)
        end
        cangjian = {
            next_time = next_time,
            shengwang = 0,
            sub_id = cangjian_data.sub_id,
            reward_list = reward, --已领取全服奖励
        }
        main_data.huodong.cangjian = cangjian
        reflesh_shoplist = true
    else
        local next_time = cangjian.next_time
        if force == 1 then
            local max_shengwang = cangjian.max_shengwang
            cangjian.next_time = now_t + 3600
            reflesh_shoplist = true
            cangjian.shengwang = cangjian.shengwang + 100
            max_shengwang = max_shengwang + 100
            --[[
            if max_shengwang < 5000 then
                max_shengwang = 5000
            end]]
            cangjian.max_shengwang = max_shengwang
            cjsz_rank.add_global_sw(100)
            if max_shengwang >= 5000 then
                cjsz_rank.change_rank(main_data.user_name, max_shengwang, main_data.lead.sex, main_data.lead.star, main_data.nickname)
                cangjian.last_sub = cangjian_data.sub_id
            end
            core_money.use_money(10, main_data, 0, 406)
            rsync = {cost_money = 10, cur_money = main_data.money}
        else
            while next_time <= now_t do
                next_time = next_time + 3600
                reflesh_shoplist = true
            end
            cangjian.next_time = next_time
        end
    end
    if reflesh_shoplist then
       huodong.cangjian_refresh(cangjian)
    end

    return cangjian, rsync
end

function huodong.cangjian_shopping(id, main_data, item_list)
    local cangjian_data = global_huodong.get_huodong(main_data,"cangjian")
    assert(cangjian_data, "has no cang_jian_shan_zhuang")
    local huodong = main_data.huodong
    local t = huodong.cangjian.next_time
    local cangjian = rawget(huodong, "cangjian")
    assert(cangjian, "no cangjian struct")
    assert(cangjian.sub_id == cangjian_data.sub_id, "shop list is old")
    local shoplist = cangjian.shop_list
    local item_entry = nil
    for k,v in ipairs(shoplist) do
        if v.item_id == id then
            assert(v.soldout == 0, "has sold out")
            item_entry = v
            break
        end
    end
    assert(item_entry, "has no this item")
    local good_conf = Cang_Goods_conf[id]
    assert(good_conf, "Cang_Goods conf not find")
    local t_item_list = {}
    local rsync = {item_list = t_item_list, gold = 0, money = 0}
    if good_conf.Coin_Item[1] == 191010003 or good_conf.Coin_Item[1] == 191010099 then
        core_money.use_money(good_conf.Coin_Item[2], main_data, 0, 401)
    else
        core_user.expend_item(good_conf.Coin_Item[1], good_conf.Coin_Item[2], main_data, 401, item_list, t_item_list)
    end
    core_user.get_item(good_conf.Good_Item[1], good_conf.Good_Item[2], main_data, 401, nil, item_list, rsync, nil, nil)
    rsync.gold = main_data.gold
    rsync.money = main_data.money
    local add_sw = good_conf.Add_Devote
    cangjian.shengwang = cangjian.shengwang + add_sw
    cjsz_rank.add_global_sw(add_sw)
    local max_shengwang = cangjian.max_shengwang + add_sw
    cangjian.max_shengwang = max_shengwang
    if max_shengwang >= 5000 then
        cjsz_rank.change_rank(main_data.user_name, max_shengwang, main_data.lead.sex, main_data.lead.star, main_data.nickname)
        cangjian.last_sub = cangjian_data.sub_id
    end
    item_entry.soldout = 1
    return cangjian, rsync
end

function huodong.cangjian_shengwang_shopping(id, num,main_data, item_list)
    local cangjian_data = global_huodong.get_huodong(main_data,"cangjian")
    assert(num >= 0)
    assert(cangjian_data, "has no cang_jian_shan_zhuang")
    local huodong = main_data.huodong
    local shengwang = huodong.cangjian.shengwang
    local cangjian = rawget(huodong, "cangjian")
    assert(cangjian, "no cangjian struct")
    assert(cangjian.sub_id == cangjian_data.sub_id, "cangjian subid err") 
    
    local item_conf = Cang_Shop_conf[id]
    assert(item_conf, "Cang_Shop conf not find")
    local cost = item_conf.Devote * num
    assert(shengwang >= cost, "shengwang not enough")
    cangjian.shengwang = shengwang - cost
    local t_item_list = {}
    local rsync = {item_list = t_item_list, cur_shengwang = cangjian.shengwang}
    core_user.get_item(item_conf.CShop_Item, num, main_data, 402, nil, item_list, rsync, nil, nil)
    return rsync
end

function huodong.qiandao(main_data, item_list, task_struct)
    local t = main_data.huodong.qiandao.sub_id
    local qiandao = rawget(main_data.huodong, "qiandao")
    assert(qiandao ~= nil)
    assert(qiandao.status == 0 or qiandao.status == 2)
    local type = 0
    if qiandao.status == 2 then type = 1 end
    local qian_id = 480000000 + qiandao.sub_id * 1000 + qiandao.day_idx
    local qian_conf = Activity_Qian_conf[qian_id]
    assert(qian_conf, "qian conf not find")
    
    local item_id = qian_conf.Reward[1]
    local item_num = qian_conf.Reward[2]
    local vip_limit = tonumber(qian_conf.VIP_LV)
    if type == 1 then
        local vip = main_data.vip_lev
        if vip_limit == -1 or vip < vip_limit then
            error("can not bu qian")
        end
    else
        local vip = main_data.vip_lev
        if vip_limit > 0 and vip >= vip_limit then
            item_num = item_num * 2
        end
    end
    qiandao.status = 1
    local t_item_list = {}
    local rsync = {item_list = t_item_list, cur_money = 0, cur_gold = 0}
    core_user.get_item(item_id, item_num, main_data, 403, nil, item_list, rsync, nil, nil)
    rsync.cur_money = main_data.money
    rsync.cur_gold = main_data.gold
    -- 检测活跃
    core_task.check_daily_qiandao(task_struct, main_data)
    t = main_data.ext_data.huodong.qiandao
    main_data.ext_data.huodong.qiandao = 0
    return qiandao.day_idx, rsync
end

function huodong.czfl(main_data, level, item_list)
    local r, chongzhi = global_huodong.check_chongzhi(main_data)
    assert(r == 0 and chongzhi, "chongzhi struct not find")
    
    local chongzhi_huodong = global_huodong.get_huodong(main_data,"chongzhi")
    local t = rawlen(chongzhi.reward_level)
    assert(level <= t and chongzhi.reward_level[level] == 0, "czfl|level error")
    local conf = Activity_Chong_conf[Activity_Chong_conf.index[level]]
    assert(conf, "czfl|Activity_Chong_conf not find")
    assert(chongzhi.total_money >= conf.Limit)
    local reward = conf.Reward
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list, chongzhi = chongzhi, gold = 0}
    t = 1
    while reward[t] do
        core_user.get_item(reward[t], reward[t + 1], main_data, 404, nil, item_list, rsync, nil, nil)
        t = t + 2
    end
    chongzhi.reward_level[level] = 1
    rsync.gold = main_data.gold
    
    local tt = 0
    for k,v in ipairs(chongzhi_huodong.reward_list) do
        if chongzhi.total_money >= v.amount and chongzhi.reward_level[k] == 0 then tt = tt + 1 end
    end
    main_data.ext_data.huodong.czfl = tt
    global_huodong.reflesh_hongdian_flag(main_data, 42101, tt)
    
    return rsync
end

function huodong.cangjian_reward(main_data, item_list, reward_idx)
    local cangjian_data = global_huodong.get_huodong(main_data,"cangjian")
    local huodong = main_data.huodong
    local t = huodong.cangjian.next_time
    local cangjian = rawget(huodong, "cangjian")
    local reflesh_shoplist = false
    assert(cangjian and cangjian.sub_id == cangjian_data.sub_id)
    local conf_idx = Cang_Quan_conf.index[reward_idx]
    assert(conf_idx)
    local conf = Cang_Quan_conf[conf_idx]
    assert(cjsz_rank.get_global_sw() >= conf.Devote, "devote not enough")
    t = cangjian.reward_list[1]
    local reward_list = rawget(cangjian, "reward_list")
    assert(reward_list[reward_idx] == 0, "cangjian_reward|this idx is not 0")
    local t_item_list = {}
    local rsync = {item_list = t_item_list, money = 0}
    t = 1
    while conf.Reward_List[t] do
        core_user.get_item(conf.Reward_List[t], conf.Reward_List[t + 1], main_data, 405, nil, item_list, rsync, nil, nil)
        t = t + 2
    end
    reward_list[reward_idx] = 1
    rsync.money = main_data.money
    --刷新红点
    local t = main_data.ext_data.huodong.cjsz
    t = t - 1
    if t < 0 then t = 0 end
    main_data.ext_data.huodong.cjsz = t
    return rsync
end

function huodong.day7_gift(main_data, day_idx, item_list)
    local r,day7 = global_huodong.check_day7(main_data)
    assert(r == 0 and day7, "day7 outofday")
    local t = day7.day_id
    assert(day_idx <= t, "can not get the 7day gift")
    assert(day7.gift_list[day_idx] == 0, "the gift is not 0")
    local conf_id = 540010000 + day_idx
    local conf = LoginEvent_conf[conf_id]
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list, money = 0, gold = 0}
    t = 1
    while conf.REWARD[t] do
        core_user.get_item(conf.REWARD[t], conf.REWARD[t + 1], main_data, 406, nil, item_list, rsync)
        t = t + 2
    end
    day7.gift_list[day_idx] = 1
    rsync.money = main_data.money
    rsync.gold = main_data.gold
    --红点
    local tt = 0
    for k = 1, day7.day_id do
        if day7.gift_list[k] == 0 then tt = tt + 1 end
    end
    main_data.ext_data.huodong.denglu = tt
    global_huodong.reflesh_hongdian_flag(main_data, 53001, tt)
    return rsync
end

function huodong.level_gift(main_data, level_idx, item_list)
    local r,level_gift = global_huodong.check_level(main_data)
    assert(r == 0 and level_gift, "level_gift outofday")
    
    local t = level_gift.entry_list[level_idx].status
    assert(level_idx > 0 and level_idx <= rawlen(level_gift.entry_list), "level_idx err")
    assert(main_data.lead.level >= level_gift.entry_list[level_idx].level, "level not enough")
    assert(t == 0, "the gift is not 0")
    local conf_id = 560010000 + level_idx
    local conf = LevelEvent_conf[conf_id]
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list, money = 0, gold = 0}
    t = 1
    while conf.REWARD[t] do
        core_user.get_item(conf.REWARD[t], conf.REWARD[t + 1], main_data, 407, nil, item_list, rsync)
        t = t + 2
    end
    level_gift.entry_list[level_idx].status = 1
    rsync.money = main_data.money
    rsync.gold = main_data.gold
    
    --刷新红点
    t = main_data.ext_data.huodong.chongji
    t = t - 1
    if t < 0 then t = 0 end
    main_data.ext_data.huodong.chongji = t
    return rsync
end

function huodong.new_task_reward(main_data, day_idx, item_list)
    local r,new_task_list = global_huodong.check_new_task(main_data)
    assert(r == 0 and new_task_list, "new_task outofday")
    local day_len = rawlen(new_task_list.event_list)
    assert(day_idx <= day_len, "day idx > day_len")
    assert(day_idx <= new_task_list.open_day, "day idx > open_day")
    local day_data = new_task_list.event_list[day_idx]
    local t = day_data.status
    assert(t == 0, "day status != 0")
    for k,v in ipairs(day_data.task_list) do
        assert(v.status == 1, "task status != 1")
    end
    local conf = NewEvent_conf[day_data.event_id]
    local t_item_list = {}
    local rsync = {item_list = t_item_list, money = 0, gold = 0}
    t = 1
    while conf.REWARD[t] do
        core_user.get_item(conf.REWARD[t], conf.REWARD[t + 1], main_data, 408, nil, item_list, rsync)
        t = t + 2
    end
    day_data.status = 1
    rsync.money = main_data.money
    rsync.gold = main_data.gold
    t = main_data.ext_data.huodong.xinshou
    t = t - 1
    if t < 0 then t = 0 end
    main_data.ext_data.huodong.xinshou = t
    return rsync
end

function huodong.cdkey_reward(main_data, item_list)
    local conf = {REWARD={191010001, 1000, 191010003, 1000}}
    local t_item_list = {}
    local rsync = {item_list = t_item_list, cur_money = 0, cur_gold = 0}
    local k = 1
    while conf.REWARD[k] do
        core_user.get_item(conf.REWARD[k], conf.REWARD[k + 1], main_data, 409, nil, item_list, rsync)
        k = k + 2
    end
    rsync.cur_money = main_data.money
    rsync.cur_gold = main_data.gold
    return rsync
end

function huodong.get_meiri_leiji(main_data)
    local s, t = global_huodong.check_drljcz(main_data)
    return t
end

function huodong.get_jieduan_leiji(main_data)
    local s, t = global_huodong.check_ljcz(main_data)
    return t
end

function huodong.get_meiri_danbi(main_data)
    local s, t = global_huodong.check_dbcz(main_data)
    return t
end

function huodong.get_meiri_xiaofei(main_data)
    local s, t = global_huodong.check_xffl(main_data)
    return t
end

function huodong.get_leiji_xiaofei(main_data)
    local s, t = global_huodong.check_ljxffl(main_data)
    return t
end

function huodong.get_login(main_data)
    local s, t = global_huodong.check_login(main_data)
    return t
end

function huodong.meiri_leiji_reward(main_data, item_list, idx)
    local s, data = global_huodong.check_drljcz(main_data)
    assert(s == 0 and data, "drljcz out of the date")
    local reward_list = rawget(data, "reward_list")
    local t = reward_list[1].status
    local len = rawlen(reward_list)
    assert(idx >= 1 and idx <= len)
    t = reward_list[idx]
    assert(t.status == 0)
    assert(data.total_money >= t.conf)
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list}
    for k,v in ipairs(t.item_list) do
        core_user.get_item(v.id, v.num, main_data, 305, nil, item_list, rsync)
    end
    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili
    t.status = 2
    
    --刷新红点
    local tt = main_data.ext_data.huodong.drljcz
    tt = 0
    for k,v in ipairs(data.reward_list) do
        if v.status == 0 and data.total_money >= v.conf then tt = tt + 1 end
    end
    main_data.ext_data.huodong.drljcz = tt
    global_huodong.reflesh_hongdian_flag(main_data, 57001, tt)
    return data, rsync
end

function huodong.jieduan_leiji_reward(main_data, item_list, idx)
    local s, data = global_huodong.check_ljcz(main_data)
    assert(s == 0 and data, "ljcz out of the date")
    local reward_list = rawget(data, "reward_list")
    local t = reward_list[1].status
    local len = rawlen(reward_list)
    assert(idx >= 1 and idx <= len)
    t = reward_list[idx]
    assert(t.status == 0)
    assert(data.total_money >= t.conf)
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list}
    for k,v in ipairs(t.item_list) do
        core_user.get_item(v.id, v.num, main_data, 306, nil, item_list, rsync)
    end
    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili
    t.status = 2
    
    --刷新红点
    local tt = main_data.ext_data.huodong.drljcz
    tt = 0
    for k,v in ipairs(data.reward_list) do
        if v.status == 0 and data.total_money >= v.conf then tt = tt + 1 end
    end
    main_data.ext_data.huodong.drljcz = tt
    global_huodong.reflesh_hongdian_flag(main_data, 60001, tt)
    return data, rsync
end

function huodong.meiri_danbi_reward(main_data, item_list, idx)
    local s, data = global_huodong.check_dbcz(main_data)
    assert(s == 0 and data, "dbcz out of the date")
    local reward_list = rawget(data, "reward_list")
    local t = reward_list[1].money
    local len = rawlen(reward_list)
    assert(idx >= 1 and idx <= len)
    t = reward_list[idx]
    assert(t.reward_num > 0)
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list}
    for k,v in ipairs(t.item_list) do
        core_user.get_item(v.id, v.num, main_data, 307, nil, item_list, rsync)
    end
    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili
    t.reward_num = t.reward_num - 1
    
    --刷新红点
    local tt = main_data.ext_data.huodong.dbcz
    tt = 0
    for k,v in ipairs(data.reward_list) do
        tt = tt + v.reward_num
    end
    main_data.ext_data.huodong.dbcz = tt
    global_huodong.reflesh_hongdian_flag(main_data, 56001, tt)
    return data, rsync
end

function huodong.meiri_xiaofei_reward(main_data, item_list, idx)
    local s, data = global_huodong.check_xffl(main_data)
    assert(s == 0 and data, "xffl out of the date")
    local reward_list = rawget(data, "reward_list")
    local t = reward_list[1].status
    local len = rawlen(reward_list)
    assert(idx >= 1 and idx <= len)
    t = reward_list[idx]
    assert(t.status == 0)
    assert(data.total_money >= t.conf)
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list}
    for k,v in ipairs(t.item_list) do
        core_user.get_item(v.id, v.num, main_data, 308, nil, item_list, rsync)
    end
    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili
    t.status = 2
    
    --刷新红点
    local tt = main_data.ext_data.huodong.xffl
    tt = 0
    for k,v in ipairs(data.reward_list) do
        if v.status == 0 and data.total_money >= v.conf then tt = tt + 1 end
    end
    main_data.ext_data.huodong.xffl = tt
    global_huodong.reflesh_hongdian_flag(main_data, 59001, tt)
    return data, rsync
end

function huodong.leiji_xiaofei_reward(main_data, item_list, idx)
    local s, data = global_huodong.check_ljxffl(main_data)
    assert(s == 0 and data, "ljxffl out of the date")
    local reward_list = rawget(data, "reward_list")
    local t = reward_list[1].status
    local len = rawlen(reward_list)
    assert(idx >= 1 and idx <= len)
    t = reward_list[idx]
    assert(t.status == 0)
    assert(data.total_money >= t.conf)
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list}
    for k,v in ipairs(t.item_list) do
        core_user.get_item(v.id, v.num, main_data, 312, nil, item_list, rsync)
    end
    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili
    t.status = 2
    
    --刷新红点
    local tt = main_data.ext_data.huodong.xffl
    tt = 0
    for k,v in ipairs(data.reward_list) do
        if v.status == 0 and data.total_money >= v.conf then tt = tt + 1 end
    end
    main_data.ext_data.huodong.xffl = tt
    global_huodong.reflesh_hongdian_flag(main_data, 67001, tt)
    return data, rsync
end

function huodong.lxdl_reward(main_data, item_list, idx)
    local s, data = global_huodong.check_login(main_data)
    assert(s == 0 and data, "lxdl out of the date")
    local reward_list = rawget(data, "reward_list")
    
    local t = reward_list[1].status
    local len = rawlen(reward_list)
    assert(idx >= 1 and idx <= len)
    t = reward_list[idx]
    assert(t.status == 1)
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list}
    for k,v in ipairs(t.item_list) do
        core_user.get_item(v.id, v.num, main_data, 309, nil, item_list, rsync)
    end
    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili
    
    t.status = 2
    --刷新红点
    local tt = main_data.ext_data.huodong.lxdl
    tt = 0
    for k,v in ipairs(reward_list) do
        if v.status == 1 then tt = tt + 1 end
    end
    main_data.ext_data.huodong.lxdl = tt
    global_huodong.reflesh_hongdian_flag(main_data, 58001, tt)
    return data, rsync
end

function huodong.get_cz_rank(user_name)
    local data = global_huodong.get_huodong(nil, "cz_rank")
    assert(data)
    local top10, self, self_rank = cz_rank.get_topn(user_name, data.sub_id)
    return top10, self, self_rank
end

function huodong.get_new_level(main_data)
    local s, t = global_huodong.check_new_level(main_data)
    return t
end

function huodong.new_level_reward(main_data, item_list, idx)
    local s, data = global_huodong.check_new_level(main_data)
    assert(s == 0 and data, "new_level out of the date")
    local reward_list = rawget(data, "reward_list")
    
    local cur_level = main_data.lead.level
    local t = reward_list[1].status
    local len = rawlen(reward_list)
    assert(idx >= 1 and idx <= len)
    t = reward_list[idx]
    assert(t.status == 0)
    assert(cur_level >= t.level)
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list}
    for k,v in ipairs(t.item_list) do
        core_user.get_item(v.id, v.num, main_data, 310, nil, item_list, rsync)
    end
    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili
    t.status = 1
    
    --刷新红点
    local tt = 0
    for k,v in ipairs(data.reward_list) do
        if v.status == 0 and (cur_level >= v.level) then tt = tt + 1 end
    end
    global_huodong.reflesh_hongdian_flag(main_data, 63001, tt)
    return data, rsync
end

function huodong.get_duihuan(main_data)
    local s = global_huodong.check_duihuan(main_data)
    assert(s)
    local item_list = s.reward_list
    local item = s.item
    return item_list, item
end

function huodong.duihuan(main_data, item_list, idx, num)
    local s = global_huodong.check_duihuan(main_data)
    assert(s)
    assert(num > 0)
    local reward_list = s.reward_list
    
    local len = rawlen(reward_list)
    assert(idx >= 1 and idx <= len)
    local t = reward_list[idx]
    
    local t_item_list = {}
    local rsync = {item_list = t_item_list}
    
    
    for k,v in ipairs(t.src_list) do
        core_user.expend_item(v.id, v.num * num, main_data, 311, item_list, t_item_list)
    end
    
    for k,v in ipairs(t.tag_list) do
        core_user.get_item(v.id, v.num * num, main_data, 311, nil, item_list, rsync)
    end
    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili
    return rsync
end

function huodong.get_tianji(main_data)
    local r, s = global_huodong.check_tianji(main_data)
    assert(s, r.." error")
    local bagnum = 0
    local vipnum = 0
    local maxtime = 3
    local maxvip = 0

    if main_data.vip_lev > 0 then
        local t = Activity_Tianji_Vip_Rank_conf[main_data.vip_lev]
        if not t then
            t = Activity_Tianji_Vip_Rank_conf[Activity_Tianji_Vip_Rank_conf.len]
        end
        maxvip = t.FREQUENCY
    end

    if not rawget(main_data, "tianji") then
        --print("init tianji")
        main_data.tianji = {
            bagnum = 0, 
            vipnum = 0,
            totalnum = 0, 
            rewardsflag = {}, 
        }
    end
    --print("get|", maxtime, main_data.tianji.bagnum, maxvip, main_data.tianji.vipnum)
    if main_data.tianji.bagnum then
        bagnum = main_data.tianji.bagnum
    end
    if main_data.tianji.vipnum then
        vipnum = main_data.tianji.vipnum
    end

    local resp = {
        result = "OK",
        rsync = {
            lefttime = maxtime-bagnum,
            viplefttime = maxvip-vipnum,
            totalnum = main_data.tianji.totalnum,
            msg = {},
            redpoint = 0,
            costyuanbao = 0,
        }
    }
    
    if resp.rsync.viplefttime < 0 then resp.rsync.viplefttime = 0 end
    if resp.rsync.lefttime < 0 then resp.rsync.lefttime = 0 end

    local len = Activity_Tianji_Cost_conf.len
    if not main_data.tianji.bagnum then main_data.tianji.bagnum = 0 end
    local conf = Activity_Tianji_Cost_conf[main_data.tianji.bagnum + 1]
    if not conf then conf = Activity_Tianji_Cost_conf[len] end
    if conf.Cost > 0 then
        resp.rsync.costyuanbao = conf.Cost
    end 

    local msglist = tianji_msg.get_all_msg(s.sub_id)
    if msglist then
        for k,v in ipairs(msglist) do
            local str = string.format(lang.tianji_msg, v.nickname, Item_conf[v.special_item.id].CN_NAME, v.special_item.num)
            table.insert(resp.rsync.msg, str)
        end
    end

    for k,v in ipairs(s.reward_list) do
        if v.status <= main_data.tianji.totalnum 
            and ((not rawget(main_data.tianji,"rewardsflag")) or (not main_data.tianji.rewardsflag[k]) or main_data.tianji.rewardsflag[k] ~= 1) then
            resp.rsync.redpoint = resp.rsync.redpoint + 1
        end
    end

    local flag = resp.rsync.lefttime + resp.rsync.viplefttime + resp.rsync.redpoint

    global_huodong.reflesh_hongdian_flag(main_data, 65001, flag)

    return resp
end

function huodong.open_tianji(main_data, item_list, isvip)
    local r, s = global_huodong.check_tianji(main_data)
    assert(s)

    local maxtime = 3
    local maxvip = 0

    if main_data.vip_lev > 0 then
        local t = Activity_Tianji_Vip_Rank_conf[main_data.vip_lev]
        if not t then
            t = Activity_Tianji_Vip_Rank_conf[Activity_Tianji_Vip_Rank_conf.len]
        end
        maxvip = t.FREQUENCY
    end

    local costyuanbao = 0

    if not rawget(main_data, "tianji") then
        --print("init")
        main_data.tianji = {
            bagnum = 0, 
            vipnum = 0,
            totalnum = 0, 
            rewardsflag = {}, 
        }
    end

    --print("open|", main_data.tianji.bagnum, main_data.tianji.vipnum)
    local conf = nil
    if isvip == 1 then
        assert(main_data.vip_lev > 0, "TianJi|vip < 1 can't open vipbag")

        assert(maxvip > main_data.tianji.vipnum, "TianJi|can't open more!")
        if main_data.tianji.vipnum then
            main_data.tianji.vipnum = main_data.tianji.vipnum + 1
        else
            main_data.tianji.vipnum = 1
        end

        conf = Activity_Tianji_Pool_conf[2]
    else
        if main_data.tianji.bagnum then
            main_data.tianji.bagnum = main_data.tianji.bagnum + 1
        else
            main_data.tianji.bagnum = 1
        end

        local len = Activity_Tianji_Cost_conf.len
        local conf1 = Activity_Tianji_Cost_conf[main_data.tianji.bagnum]
        if not conf1 then conf1 = Activity_Tianji_Cost_conf[len] end
        if conf1.Cost > 0 then
            core_money.use_money(conf1.Cost, main_data, 1, 702)
            costyuanbao = conf1.Cost
        end

        conf = Activity_Tianji_Pool_conf[1]
    end
    if main_data.tianji.totalnum then
        main_data.tianji.totalnum = main_data.tianji.totalnum + 1
    else
        main_data.tianji.totalnum = 1
    end

    --开池子
    local poolid = conf.POOL_ID
    --print("poolid|", poolid)

    local list = {}
    core_drop.get_item_list_from_id(poolid, list, false)
    
    local rsync = {item_list = {}}
    
    for k,v in ipairs(list) do
        --print("open|", v[1], v[2])
        core_user.get_item(v[1], v[2], main_data, 701, nil, item_list, rsync)
    end
    
    local redpoint = 0
    for k,v in ipairs(s.reward_list) do
        if v.status <= main_data.tianji.totalnum 
            and ((not rawget(main_data.tianji,"rewardsflag")) or (not main_data.tianji.rewardsflag[k]) or main_data.tianji.rewardsflag[k] ~= 1) then
            redpoint = redpoint + 1
        end
    end
    --print("redpoint", redpoint)

    --检查获得物品公告
    for k,v in ipairs(list) do
        if false then
            local item = {id = v[1], num = v[2]}
            tianji_msg.add_new_msg(main_data, s.sub_id, item)
        else
            for k1,v1 in ipairs(conf.HIGHLIGHT_ITEM) do
                --print("check|", v[1], v1)
                if v[1] == v1 then
                    local item = {id = v[1], num = v[2]}
                    tianji_msg.add_new_msg(main_data, s.sub_id, item)
                end
            end
        end
    end
    local msg = {}
    local msglist = tianji_msg.get_all_msg(s.sub_id)
    if msglist then
        for k,v in ipairs(msglist) do
            local str = string.format(lang.tianji_msg, v.nickname, Item_conf[v.special_item.id].CN_NAME, v.special_item.num)
            table.insert(msg, str)
        end
    end

    local rsyncdata = {
        lefttime = maxtime-main_data.tianji.bagnum,
        viplefttime = maxvip-main_data.tianji.vipnum,
        totalnum = main_data.tianji.totalnum,
        msg = msg,
        redpoint = redpoint,
        costyuanbao = 0,
    }

    if rsyncdata.lefttime < 0 then rsyncdata.lefttime = 0 end
    local len = Activity_Tianji_Cost_conf.len
    local conf1 = Activity_Tianji_Cost_conf[main_data.tianji.bagnum + 1]
    if not conf1 then conf1 = Activity_Tianji_Cost_conf[len] end
    if conf1.Cost > 0 then
        rsyncdata.costyuanbao = conf1.Cost
    end
    local flag = rsyncdata.lefttime + rsyncdata.viplefttime + redpoint
    global_huodong.reflesh_hongdian_flag(main_data, 65001, flag)

    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili

    return rsync,rsyncdata
end

function huodong.tianji_reward(main_data, item_list, idx)
    local r, s = global_huodong.check_tianji(main_data)
    assert(s)
    assert(idx > 0 and idx < #s.reward_list + 1)
    if not rawget(main_data, "tianji") then
        --print("init")
        main_data.tianji = {
            bagnum = 0, 
            vipnum = 0,
            totalnum = 0, 
            rewardsflag = {}, 
        }
    end
    local flags = main_data.tianji.rewardsflag
    flags = rawget(main_data.tianji, "rewardsflag")
    if not flags then
        flags = {}
    end
    
    for i = 1, idx do
        if not flags[i] then
            flags[i] = 0
        end
        --print("rewardflags|", i, flags[i])
    end
    
    assert(flags[idx] ~= 1)
    assert(main_data.tianji.totalnum and s.reward_list[idx].status <= main_data.tianji.totalnum)

    flags[idx] = 1
    local list = s.reward_list[idx].item_list
    
    local rsync = {item_list = {}}
    
    for k,v in ipairs(list) do
        core_user.get_item(v.id, v.num, main_data, 702, nil, item_list, rsync)
    end

    main_data.tianji.rewardsflag = flags

    local redpoint = 0
    for k,v in ipairs(s.reward_list) do
        if v.status <= main_data.tianji.totalnum 
            and ((not rawget(main_data.tianji,"rewardsflag")) or (not main_data.tianji.rewardsflag[k]) or main_data.tianji.rewardsflag[k] ~= 1) then
            redpoint = redpoint + 1
        end
    end
    local msg = {}
    local msglist = tianji_msg.get_all_msg(s.sub_id)
    if msglist then
        for k,v in ipairs(msglist) do
            local str = string.format(lang.tianji_msg, v.nickname, Item_conf[v.special_item.id].CN_NAME, v.special_item.num)
            table.insert(msg, str)
        end
    end

    local maxtime = 3
    local maxvip = 0

    if main_data.vip_lev > 0 then
        local t = Activity_Tianji_Vip_Rank_conf[main_data.vip_lev]
        if not t then
            t = Activity_Tianji_Vip_Rank_conf[Activity_Tianji_Vip_Rank_conf.len]
        end
        maxvip = t.FREQUENCY
    end

    local rsyncdata = {
        lefttime = maxtime-main_data.tianji.bagnum,
        viplefttime = maxvip-main_data.tianji.vipnum,
        totalnum = main_data.tianji.totalnum,
        msg = msg,
        redpoint = redpoint,
        costyuanbao = 0,
    }

    if rsyncdata.viplefttime < 0 then rsyncdata.viplefttime = 0 end
    if rsyncdata.lefttime < 0 then rsyncdata.lefttime = 0 end

    local len = Activity_Tianji_Cost_conf.len
    if not main_data.tianji.bagnum then main_data.tianji.bagnum = 0 end
    local conf = Activity_Tianji_Cost_conf[main_data.tianji.bagnum + 1]
    if not conf then conf = Activity_Tianji_Cost_conf[len] end
    if conf.Cost > 0 then
        rsyncdata.costyuanbao = conf.Cost
    end 

    local flag = rsyncdata.lefttime + rsyncdata.viplefttime + redpoint
    global_huodong.reflesh_hongdian_flag(main_data, 65001, flag)

    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili
    return rsync, rsyncdata
end


function huodong.tianji_reward_info(main_data)
    local r, s = global_huodong.check_tianji(main_data)
    assert(s)
    --print("rewardinfo")
    local tr = main_data.tianji.rewardsflag
    tr = rawget(main_data.tianji,"rewardsflag")
    --assert(rawget(main_data.tianji,"rewardsflag"))

    local list = {}
    for k,v in ipairs(s.reward_list) do
        local t = {} 
        t.item_list = {}
        for k1,v1 in ipairs(v.item_list) do
            local t2 = {}
            table.insert(t.item_list, t2)
            t2.id = v1.id
            t2.num = v1.num
        end

        t.status = v.status
        if not tr or not tr[k] then
            LOG_INFO("TianJi| rewardsflag:".. k.. ", nil->0")
            t.getflag = 0
        else
            t.getflag = tr[k]
        end
        table.insert(list, t)
    end

    return list
end


function huodong.limit_shop_info(main_data)
    local r, s = global_huodong.check_limitshop(main_data)
    assert(s, "ret:"..r)
    if r >= 2 then 
        LOG_INFO("init limitshop ".. r)
        --main_data.limitshop = {} 
    end
    local tr = main_data.limitshop
    tr = rawget(main_data, "limitshop")
    --assert(rawget(main_data,"limitshop"))
    local list = {}
    for k,v in ipairs(s.reward_list) do
        local t = {} 
        t.item_list = {}
        for k1,v1 in ipairs(v.item_list) do
            local t2 = {}
            table.insert(t.item_list, t2)
            t2.id = v1.id
            t2.num = v1.num
        end

        t.status = v.status
        t.gift_name = v.gift_name
        t.iconid = v.iconid
        t.maxtime = v.limittime
        if not tr or not tr[k] then
            LOG_INFO("LimitShop| buy_num:".. k.. ", nil->0")
            t.buytime = 0
        else
            t.buytime = tr[k]
        end
        table.insert(list, t)
    end

    return list
end

function huodong.limit_shopping(main_data, item_list, idx)
    local r, s = global_huodong.check_limitshop(main_data)
    if r >= 2 then 
        LOG_INFO("init limitshop "..r)
        --main_data.limitshop = {} 
    end
    assert(s)
    assert(s.reward_list[idx], "idx error|"..idx)
    --print("limitshop")
    if not rawget(main_data, "limitshop") then
        --print("init")
        main_data.limitshop = {}
    end

    local flags = main_data.limitshop
    flags = rawget(main_data, "limitshop")
    if not flags then
        flags = {}
    end
    
    for i = 1, idx do
        if not flags[i] then
            flags[i] = 0
        end
        --print("rewardflags|", i, flags[i])
    end
    
    assert(flags[idx] < s.reward_list[idx].limittime)

    flags[idx] = flags[idx] + 1
    local list = s.reward_list[idx].item_list
    
    local rsync = {item_list = {}}
    
    core_money.use_money(s.reward_list[idx].status, main_data, 0, 701)

    for k,v in ipairs(list) do
        core_user.get_item(v.id, v.num, main_data, 703, nil, item_list, rsync)
    end

    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili

    main_data.limitshop = flags

    return rsync, flags[idx]
end

function huodong.get_qhaoxia(main_data)
    local r, s = global_huodong.check_qhaoxia(main_data)
    assert(s, r.." error")

    local flag = 0
    local nowtime = os.time()
    
    for k,v in ipairs(s.reward_list) do
        if v.needpoint <= s.haoxiainfo.point and v.getflag == 0 then
            flag = flag + 1
        end
    end

    local redpoint = flag

    if s.haoxiainfo.next_chou_time <= nowtime then
        flag = flag + 1
    end

    global_huodong.reflesh_hongdian_flag(main_data, 68001, flag)

    local qhaoxiarank = qhaoxia_rank.get_rank(s.sub_id)
    --local qhaoxiarank = {}
    local resp = {
        result = "OK",
        rsyncdata = {
            qhaoxiainfo = s.haoxiainfo,
            qhaoxiarank = qhaoxiarank,
            redpoint = redpoint,
        },
        rank_reward = s.rank_reward,
    }
    --printtab(resp)
    return resp
end

function huodong.qhaoxia_choujiang(main_data, knight_list, item_list, req, task_struct, notify_struct)
    local r, s = global_huodong.check_qhaoxia(main_data)
    assert(s)

    local conf = nil
    for k,v in ipairs(QiangHX_conf.index) do
        local t = QiangHX_conf[v]
        if t.Activity_ID == s.sub_id + 680010000 then
            conf = QiangHX_conf[v]
            break
        end
    end
    assert(conf)
    local type = req.type
    local is_free = req.is_free
    local nowtime = os.time()
    local cost1 =  200
    local cost10 = 2000
    local poolid = 0
    local poolid2 = 0
    if is_free == 1 then
        assert(s.haoxiainfo.next_chou_time <= nowtime)
        s.haoxiainfo.next_chou_time = nowtime + s.haoxiainfo.interval
        s.haoxiainfo.point = s.haoxiainfo.point + 10
        --开池子
        poolid = conf.Free_Pool
        --print("poolid|", poolid)
    else
        --poolid = conf.TenPick_Pool
        if type == 1 then
            local ret = core_money.use_money(cost1, main_data, 0, 905)
            poolid = conf.Free_Pool
            s.haoxiainfo.point = s.haoxiainfo.point + 10
        elseif type == 2 then
            local ret = core_money.use_money(cost10, main_data, 0, 906)
            poolid = conf.TenPick_Pool
            s.haoxiainfo.point = s.haoxiainfo.point + 100
            poolid2 = conf.HotPoint
            if not rawget(s.haoxiainfo, "tencount") then
                s.haoxiainfo.tencount = 0
            end
            s.haoxiainfo.tencount = s.haoxiainfo.tencount + 1
            if s.haoxiainfo.tencount > 0 and s.haoxiainfo.tencount%(conf.limit_Time) == 0 then
                poolid2 = conf.limit_Pool
            end
        end
    end

    assert(poolid > 0)

    --开池子
    local choujianglist = {}
    local rsync = {item_list = {}}

    local list = {}
    core_drop.get_item_list_from_id(poolid, list, false)
    local where = 906
    if type == 2 then
        where = 907
    end
    if is_free == 1 then
        where = 908
    end
    for k,v in ipairs(list) do
        local entry = nil
        if v[1] > 10000000 and v[1] < 20000000 then
            local ret = core_user.get_item(v[1], 1, main_data, where, knight_list, item_list)
            entry = ret
        else
            local len = #rsync.item_list
            core_user.get_item(v[1], v[2], main_data, where, knight_list, item_list, rsync)
            assert(#rsync.item_list == len + 1)
            entry = {item = rsync.item_list[len+1]}
        end
        table.insert(choujianglist, entry)
    end

    if poolid2 > 0 then 
        local list = {}
        core_drop.get_item_list_from_id(poolid2, list, false)
        for k,v in ipairs(list) do
            local entry = nil
            if v[1] > 10000000 and v[1] < 20000000 then
                local ret = core_user.get_item(v[1], 1, main_data, where, knight_list, item_list)
                entry = ret
            else
                local len = #rsync.item_list
                core_user.get_item(v[1], v[2], main_data, where, knight_list, item_list, rsync)
                for i = len + 1, #rsync.item_list do
                --assert(#rsync.item_list == len + 1)
                    printtab(rsync.item_list[i], i..":")
                    entry = {item = rsync.item_list[i]}
                end
            end
            table.insert(choujianglist, entry)
        end
    end

    --print("redpoint", redpoint)
    local sevenweapon = nil
    for k,v in ipairs(choujianglist) do
        if v.knight then
            sevenweapon = core_user.check_sevenweapon_init(main_data, knight_list)
            local c_conf = Character_conf[v.knight.id ]
            if c_conf.STAR_LEVEL >= 5 then
                if notify_struct.ret == false then
                    notify_struct.ret = true
                end
                notify_struct.data = notify_sys.add_message(main_data.user_name, main_data.nickname, 1, v.knight.id)
            end
        end
    end
    
    -- 检测成就
    core_task.check_chengjiu_knight_star_num(task_struct, main_data, knight_list)
    core_task.check_chengjiu_knight_special(task_struct, main_data, knight_list)
    --core_task.check_daily_choujiang(task_struct, main_data, t)
    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili

    local rsyncdata = {
            list = choujianglist,
            chengjiu_list = task_struct.chengjiu_list,        
            rsync = rsync,    
            sevenweapon = sevenweapon,
        }
    local flag = 0
    for k,v in ipairs(s.reward_list) do
        if v.needpoint <= s.haoxiainfo.point and v.getflag == 0 then
            flag = flag + 1
        end
    end

    local redpoint = flag

    if s.haoxiainfo.next_chou_time <= nowtime then
        flag = flag + 1
    end

    global_huodong.reflesh_hongdian_flag(main_data, 68001, flag)  

    local qhaoxiarank = qhaoxia_rank.add_new_rank(main_data, s.sub_id, s.haoxiainfo.point)
    
    --local qhaoxiarank = {}
    local resp = {
        result = "OK",
        req = req,
        rsyncdata1 = rsyncdata,
        rsyncdata2 = {
            qhaoxiainfo = s.haoxiainfo,
            qhaoxiarank = qhaoxiarank,
            redpoint = redpoint,
        },
    }
    
    return resp
end

function huodong.qhaoxia_reward(main_data, item_list, idx)
    local r, s = global_huodong.check_qhaoxia(main_data)
    assert(s)
    local totalnum = s.haoxiainfo.point
    assert(s.reward_list[idx].getflag ~= 1)
    assert(s.reward_list[idx].needpoint <= totalnum)

    s.reward_list[idx].getflag = 1
    local list = s.reward_list[idx].item_list
    
    local rsync = {item_list = {}}
    
    for k,v in ipairs(list) do
        core_user.get_item(v.id, v.num, main_data, 908, nil, item_list, rsync)
    end
    local flag = 0
    for k,v in ipairs(s.reward_list) do
        if v.needpoint <= s.haoxiainfo.point and v.getflag == 0 then
            flag = flag + 1
        end
    end

    local rsyncdata = {
        qhaoxiainfo = s.haoxiainfo,
        qhaoxiarank = {},
        redpoint = 0,
    }

    rsyncdata.redpoint = flag
    local nowtime = os.time()

    if s.haoxiainfo.next_chou_time <= nowtime then
        flag = flag + 1
    end

    global_huodong.reflesh_hongdian_flag(main_data, 68001, flag)

    rsyncdata.qhaoxiarank = qhaoxia_rank.get_rank(s.sub_id)

    rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili
    return rsync, rsyncdata
end


function huodong.qhaoxia_reward_info(main_data)
    local r, s = global_huodong.check_qhaoxia(main_data)
    assert(s)

    local list = s.reward_list

    return list
end

return huodong