local core_user = require "core_user_funcs"
local core_money = require "core_money"
local time_checking = require "time_checking"
local logic_knight = require "logic_knight"
local core_power = require "core_calc_power"
local core_task = require "core_task"
local rank = rank
local core_drop = require "core_drop"
local worldboss = require "worldboss"
local core_send_mail = require "core_send_mail"

local rank = rank

local Fortress_conf = Fortress_conf

local logic_user = {}

function logic_user.set_zhenxing(main_data, knight_bag, new_zhenxing, username)
	assert(#new_zhenxing == 7)
	local change_list = {}
	local level = main_data.lead.level
	if level < 5 then assert(new_zhenxing[6] == -2) end
	if level < 10 then assert(new_zhenxing[1] == -2) end
	if level < 15 then assert(new_zhenxing[4] == -2) end
	if level < 23 then assert(new_zhenxing[3] == -2) end
	if level < 30 then assert(new_zhenxing[7] == -2) end
	local zhanwei_list = main_data.zhenxing.zhanwei_list
	-- 清除原来阵型
	for k,v in ipairs(zhanwei_list) do
		if v.status == 1 then
			v.status = 0
		elseif v.status == 2 then
			v.knight.data.lock = v.knight.data.lock - 1
			table.insert(knight_bag, v.knight)
			table.insert(change_list, v.knight)
			v.knight = nil
			v.status = 0
		end
	end
	local has_lead = false
	for k,v in ipairs(new_zhenxing) do
		if v  == -1 then
			assert(not has_lead)
			has_lead = true
			zhanwei_list[k].status = 1
		elseif v == -2 then
			zhanwei_list[k].status = 0
		else
			local t = core_user.get_knight_from_bag_by_guid(v, knight_bag)
			assert(t[2])
			local jiban = rawget(t[2].data, "jiban_list")
			assert(t[2].data.master == 0, "this knight has master")
			table.remove(knight_bag, t[1])
			zhanwei_list[k].status = 2
			zhanwei_list[k].knight = t[2]
			core_user.init_knight(t[2])
			t[2].data.lock = t[2].data.lock + 1
			local done = false
			for k1,v1 in ipairs(change_list) do
				if v1.guid == t[2].guid then
					done = true
					table.remove(change_list, k1)
					break
				end
			end
			if not done then
				table.insert(change_list, t[2])
			end
		end
	end
	assert(has_lead)
	--刷新战斗力
	core_power.reflesh_team_power(main_data, knight_bag, core_power.create_modify_power(rank.modify_power, username))
	--print(string.format("POWER CHANGE T:%s|%d)",
	--        main_data.user_name, main_data.power))
	return change_list
end

function logic_user.lead_starup(main_data, item_list, username)
	local lead = main_data.lead
	assert(lead)
	local star = lead.star + lead.evolution
	local old_star = star
	-- 验证资源
	local conf_data = Character_Expend_conf[star]
	assert(conf_data and conf_data.NEXT_LEVEL ~= 0)
	local num = conf_data.NEXT_LEVEL
	local cost_gold = conf_data.NEXT_MONEY
	local ret = {item_list = {}, gold = 0}
	core_user.expend_item(193010005, num, main_data, 15,item_list, ret.item_list)
	if conf_data.PIECE[1] ~= 0 then
		core_user.expend_item(conf_data.PIECE[1], conf_data.PIECE[2], main_data, 15, item_list, ret.item_list)
	end
	if cost_gold ~= 0 then
		core_user.expend_item(191010001, cost_gold, main_data, 15, nil, ret.item_list)
	end
	ret.gold = main_data.gold
	
	star = star + 1
	if star <= 6 then
		lead.star = star
		local id = 10000000 + star * 10000
		conf_data = Character_conf[id]
		assert(conf_data)
		local old_skill = lead.skill.id
		lead.skill.id = conf_data.SKILL_ID
		local cangjian_data = global_huodong.get_huodong(main_data,"cangjian")
		if cangjian_data then
			cjsz_rank.change_star(username, star)
		end
	else lead.evolution = star - 6 end
	
	-- 刷新战斗力
	core_power.reflesh_knight_power(main_data, nil, 0, core_power.create_modify_power(rank.modify_power, username))
	rank.modify_star(username, lead.star)
	group_cache.update_user_info(main_data)
	if star <= 6 then
		--LOG_EXT(string.format("LEAD STARUP:%s|%d--->%d)",
			--username, old_star, star))
	else
		--LOG_EXT(string.format("LEAD EUP:%s|%d--->%d)",
			--username, old_star - 5, star - 5))
	end
	return ret
end


function logic_user.pve_get_reward(fortress_id, idx, main_data, knight_list, item_list)
	local reward_list = nil
	local f_idx = fortress_id % 10000
	if idx == 1 or idx == 2 or idx == 3 then
		local data = Fortress_conf[fortress_id]
		assert(data)
		local need = 0
		if idx == 1 then
			need = data.PHASE_REWARD_1_OPEN
			reward_list = data.PHASE_REWARD_1_ID
		elseif idx == 2 then
			need = data.PHASE_REWARD_2_OPEN
			reward_list = data.PHASE_REWARD_2_ID
		elseif idx == 3 then
			need = data.PHASE_REWARD_3_OPEN
			reward_list = data.PHASE_REWARD_3_ID
		end
		assert(need > 0)
		local fortress_info = main_data.PVE.fortress_list[f_idx]
		assert(fortress_info)
		local phase_reward = fortress_info.phase_reward[idx]
		assert(phase_reward and phase_reward == 0)
		assert(fortress_info.star >= need, "pve_get_reward|star not enough")
		fortress_info.phase_reward[idx] = 1
	elseif idx == 0 then
		local data = Jing_Fortress_conf[fortress_id]
		assert(data)
		reward_list = data.PHASE_REWARD_1_ID
		local fortress_info = main_data.PVE.jingying[f_idx]
		assert(fortress_info)
		local t = fortress_info.reward
		assert(t == 0)
		--必须通关最后一关
		t = fortress_info.stage_list[1].pass_num
		t = rawlen(fortress_info.stage_list)
		t = fortress_info.stage_list[t].pass_num
		assert(t > 0)
		fortress_info.reward = 1
	else
		error("pve get reward, idx error")
	end
	local k = 1
	local ret_struct = {
		item_list = {},
		new_knight_list = {},
		gold = 0,
		exp = 0,
	}
	while reward_list[k] do
		core_user.get_item(reward_list[k], reward_list[k + 1], main_data, 100, knight_list, item_list, ret_struct)
		k = k + 2
	end
	ret_struct.gold = main_data.gold
	ret_struct.exp = main_data.lead.exp
	return ret_struct
end

function logic_user.open_book(book_id, main_data, username, task_struct, knight_list)
	local book_list = rawget(main_data, "book_list")
	if book_list == nil then
		book_list = {}
		rawset(main_data, "book_list", book_list)
	end
	for _,v in ipairs(book_list) do
		if v.id == book_id then error("when open book, book id is opened") end
	end
	
	-- 验证pve进度
	local book_idx = 80000001 + book_id * 10000
	local conf = Book_conf[book_idx]
	assert(conf)
	local open_fortress = conf.OPEN_Fortress % 100
	local f_data = main_data.PVE.fortress_list[open_fortress]
	assert(f_data)
	assert(f_data.stage_list[#f_data.stage_list].difficulty_list[1].pass_num > 0)
	
	local book_info = {id = book_id, level = 1, exp = 0}
	table.insert(book_list, book_info)
	--刷新战斗力
	core_power.reflesh_team_power(main_data, knight_list, core_power.create_modify_power(rank.modify_power, username))
	
	-- 检测成就
	core_task.check_chengjiu_book(task_struct, main_data)
	-- 检测开服任务
	core_task.check_newtask_by_event(main_data, 3)
	return book_info
end

function logic_user.book_levelup(book_id, main_data, item_list, item_cost_list, username, knight_list)
	local book_list = rawget(main_data, "book_list")
	if book_list == nil then
		book_list = {}
		rawset(main_data, "book_list", book_list)
	end
	local book_data = nil
	for _,v in ipairs(book_list) do
		if v.id == book_id then book_data = v end
	end
	assert(book_data ~= nil,"when book levelup, book id is not opened")
	
	local book_id_base = 80000000 + book_id * 10000
	local conf = Book_conf[book_id_base + book_data.level]
	assert(conf, "unknow book level")
	assert(conf.EXPEND_ID > 0, "max level")
	
	local ret = {item_list = {}}
	local exp = 0
	for _,v in ipairs(item_cost_list) do
		assert(v.item_id == 191010215, "need cangshu canye")
		assert(v.item_num > 0)
		exp = exp + v.item_num
		core_user.expend_item(v.item_id, v.item_num, main_data, 16, item_list, ret.item_list)
	end
	
	exp = exp + book_data.exp
	local new_level = book_data.level
	local old_level = new_level
	while(exp >= conf.EXPEND_ID) do
		new_level = new_level + 1
		exp = exp - conf.EXPEND_ID
		conf = Book_conf[book_id_base + new_level]
		assert(conf, "unknow book level")
		if conf.EXPEND_ID == 0 then
			exp = 0
			break
		end
	end
	book_data.level = new_level
	book_data.exp = exp
	if old_level ~= new_level then
		--刷新战斗力
		core_power.reflesh_team_power(main_data, knight_list, core_power.create_modify_power(rank.modify_power, username))
		--LOG_EXT(string.format("BOOK L:%s|%d  %d--->%d",
		--username, book_id, old_level, new_level))
	end
	return book_data, ret
end

function logic_user.open_lover(lover_id, main_data, item_list, username, knight_list)
	-- 必须先通关50020008
	local f_data = main_data.PVE.fortress_list[2]
	assert(f_data)
	assert(f_data.stage_list[8].difficulty_list[1].pass_num > 0)
	
	local lover_list = rawget(main_data, "lover_list")
	if lover_list == nil then
		lover_list = {}
		rawset(main_data, "lover_list", lover_list)
	end
	local real_lover_id = math.floor(lover_id / 10000)
	assert(lover_id % 10000 == 1, "when open lover, lover level must be 1")
	for _,v in ipairs(lover_list) do
		if (math.floor(v.id / 10000)) == real_lover_id then error("when open lover, lover id is opened") end
	end
	local conf = Lovers_conf[lover_id]
	assert(conf)
	local level = main_data.lead.level
	assert(level >= conf.CHARACTER_LEVEL, "when open lover, lead level err")
	local book_id = conf.BOOK_ID
	local book_list = rawget(main_data, "book_list")
	assert(book_list, "open_lover|book_list is nil")
	local done = false
	for _,v in ipairs(book_list) do
		if v.id == book_id then
			done = true
			break
		end
	end
	assert(done, "when open lover, book not open")
	assert(main_data.PVP.reputation >= conf.CHARACTER_POPULARITY, "open_lover|reputation not enough")
	
	local cost_list = {}
	if conf.LOVE_LOCK > 0 then
		core_user.expend_item(193010007, conf.LOVE_LOCK, main_data, 17, item_list, cost_list)
	end
	local lover_skill = nil
	if conf.SKILL_ID ~= 0 then lover_skill = {id = conf.SKILL_ID, level = 1} end
	local lover = {id = lover_id, skill = lover_skill}
	table.insert(lover_list, lover)
	--刷新战斗力
	core_power.reflesh_team_power(main_data, knight_list, core_power.create_modify_power(rank.modify_power, username))
	core_task.check_newtask_by_event(main_data, 8)
	--LOG_EXT(string.format("LOVER O:%s|%d",
		--username, lover_id))
	return lover, cost_list
end

function logic_user.lover_levelup(lover_id, main_data, item_list, username, knight_list)
	local lover_list = rawget(main_data, "lover_list")
	assert(lover_list, "lover_levelup|lover_list is nil")
	local lover_data = nil
	for _,v in ipairs(lover_list) do
		if v.id == lover_id then
			lover_data = v
			break
		end
	end
	assert(lover_data, "lover_levelup|lover id not find")
	local conf = Lovers_conf[lover_id]
	assert(conf, "lover_levelup|config not find")
	assert(conf.EXPEND_ID[1] > 0,"lover_levelup|lover level is max")
	local cost_list = {}
	local k = 1
	while conf.EXPEND_ID[k] do
		core_user.expend_item(conf.EXPEND_ID[k], conf.EXPEND_ID[k + 1], main_data, 18, item_list, cost_list)
		k = k + 2
	end
	lover_data.id = lover_id + 1
	--刷新战斗力
	core_power.reflesh_team_power(main_data, knight_list, core_power.create_modify_power(rank.modify_power, username))
	--LOG_EXT(string.format("LOVER L:%s|%d--->%d",
		--username, lover_id, lover_id + 1))
	return lover_data, cost_list
end

function logic_user.update_timestamp(main_data, item_list, mail_list, name, task_struct)
	local time = os.time()
	local dayid = time_checking.get_dayid_from(time)
	local ret = time_checking.update_at_0am(main_data, dayid, mail_list)
	time_checking.update_tili_per_6min(main_data, 1, mail_list)
	dayid = time_checking.get_dayid_from(time, 5)
	local ret1 = time_checking.update_at_5am(main_data, dayid, mail_list)
	dayid = time_checking.get_dayid_from(time, 12)
	ret1 = time_checking.update_at_12am(main_data, dayid, mail_list)
	dayid = time_checking.get_dayid_from(time, 21)
	ret1 = time_checking.update_at_9pm(main_data, dayid, item_list, mail_list, rank.get_idx_by_name(name))
	--更新世界BOSS信息
	worldboss.update_user_info(main_data, mail_list)

	core_task.check_daily_tili(task_struct, main_data)
	core_send_mail.limit_mail_count(main_data, item_list, mail_list)
	local unread_mail = core_user.unread_mail_num(mail_list)
	ret = ret or ret1
	return unread_mail
end

function logic_user.money2gold(main_data, task_struct)
	local lev = main_data.lead.level
	assert(lev >= Open_conf[8].OPEN_PARA)
	local max_num = core_vip.money2gold_num(main_data)
	local vip_rate = core_vip.money2gold_rate(main_data)
	local vip_crit = core_vip.money2gold_crit(main_data)
	
	local m2g_struct = main_data.money2gold
	assert(m2g_struct.m2g_num < max_num)
	local cost_money = m2g_struct.last_money
	local get_gold = m2g_struct.last_gold * m2g_struct.last_baoji
	local last_baoji = m2g_struct.last_baoji
	local level = main_data.lead.level
	local vip_level = main_data.vip_lev
	--[[
	if m2g_struct.m2g_num == 0 then
		local m2g = core_money.reflesh_m2g(1, Gold_Money_conf[1].YUANBAO, level, vip_level)
		cost_money = m2g.money
		get_gold = m2g.gold
		last_baoji = m2g.baoji
	end
	]]
	core_money.use_money(cost_money, main_data, 0, 20)
	core_user.get_item(191010001, get_gold, main_data, 20)
	-- 检测成就
	core_task.check_chengjiu_total_gold(task_struct, main_data)
	core_task.check_chengjiu_max_gold(task_struct, main_data)
	core_task.check_daily_m2g(task_struct, main_data)
	
	m2g_struct.m2g_num = m2g_struct.m2g_num + 1
	if(m2g_struct.m2g_num == 50) then
		m2g_struct.last_money = 0
		m2g_struct.last_gold = 0
		m2g_struct.last_baoji = 0
		m2g_struct.last_num = 0
	else
		local n_num = m2g_struct.m2g_num + 1
		local m2g = core_money.reflesh_m2g(n_num, Gold_Money_conf[n_num].YUANBAO, level, vip_rate, vip_crit)
		m2g_struct.last_money = m2g.money
		m2g_struct.last_gold = m2g.gold
		m2g_struct.last_baoji = m2g.baoji
		m2g_struct.last_num = m2g.num
	end
	local ret ={
		cost_money = cost_money,
		get_gold = get_gold,
		baoji = last_baoji,
		count = m2g_struct.m2g_num,
		now_money = main_data.money,
		now_gold = main_data.gold,
		next_money = m2g_struct.last_money,
		next_gold = m2g_struct.last_gold,
		next_baoji = m2g_struct.last_baoji,
	}
	return ret
end

function logic_user.money2hp(main_data, task_struct)
	local max_num = core_vip.money2hp_num(main_data)
	
	local cur_num = main_data.timestamp.money2hp
	assert(cur_num < max_num)
	
	local next_num = cur_num + 1
	
	local conf = nil
	for _,v in ipairs(Gold_Stamnia_conf.index) do
		if v >= next_num then
			conf = Gold_Stamnia_conf[v]
			break
		end
	end
	assert(conf, "conf not find")
	local cost = conf.YUANBAO
	local hp = conf.STAMINA
	
	core_money.use_money(cost, main_data, 0, 4)
	core_user.get_item(191040211, hp, main_data, 4)
	main_data.timestamp.money2hp = next_num
	
	core_task.check_daily_m2h(task_struct, main_data)
	local ret ={
		cost_money = cost,
		get_hp = hp,
		count = next_num,
		now_money = main_data.money,
		now_hp = main_data.tili
	}
	return ret
end

local choujiang = require "choujiang"
function logic_user.choujiang(type, is_free, main_data, knight_list, item_list, task_struct, notify_struct)
	local ret = nil
	local t = 1
	if type == 1 then
		ret = choujiang.gold1(is_free, main_data, knight_list, item_list)
	elseif type == 2 then
		t = 10
		ret = choujiang.gold10(main_data, knight_list, item_list)
	elseif type == 3 then
		ret = choujiang.money1(is_free, main_data, knight_list, item_list)
	elseif type == 4 then
		t = 10
		ret = choujiang.money10(main_data, knight_list, item_list)
	elseif type == 5 then
		t = 5
		ret = choujiang.money_haoxia(main_data, knight_list, item_list)
	else
		error("Choujiang type is wrong")
	end
	local sevenweapon = nil
	for k,v in ipairs(ret.list) do
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
	core_task.check_daily_choujiang(task_struct, main_data, t)
	return ret, sevenweapon
end

--出售物品
function logic_user.sell_item(item_id, item_num, main_data, item_list, task_struct)
	local cost_list = {}
	core_user.expend_item(item_id, item_num, main_data, 21, item_list, cost_list)
	local item_conf = Item_conf[item_id]
	local price = item_conf.PRICE * item_num
	core_user.get_item(191010001, price, main_data, 21)
	-- 检测成就
	core_task.check_chengjiu_total_gold(task_struct, main_data)
	core_task.check_chengjiu_max_gold(task_struct, main_data)
	
	local ret = {
		item = cost_list[1],
		get_gold = price,
		new_gold = main_data.gold,
	}
	
	return ret
end

--获取体力道具信息,返回是否成功,回复体力数量
local function get_php_item_info(item_id)
	local phpitems = { --体力恢复道具
		{191020214, 60}, --花雕，回复60体力
		{191020213, 120}, --女儿红，回复120体力
	}
	for k,v in ipairs (phpitems) do
		if item_id == v[1] then
			return true, v[2]
		end
	end
	return false
end

--使用物品
function logic_user.use_item(item_id, item_num, main_data, item_list, task_struct)
	local cost_list = {}
	assert(item_num > 0, "item_num must > 0")
	local rsync = {
		item_list = {},
	}
	core_user.expend_item(item_id, item_num, main_data, 21, item_list, rsync.item_list);
	local item_conf = Item_conf[item_id]

	local success = false
	local value = 0
	success, value = get_php_item_info(item_id)
	if success then
		value = value * item_num
		core_user.get_item(refid.tili, value * item_num, main_data, 26, nil, item_list, rsync)
		rsync.cur_tili = main_data.tili
	end

	return rsync
end

function logic_user.take_task(main_data, task_id)
	local task_system = main_data.task_list
	local task_list = rawget(task_system, "task_list")
	local finished_task_list = rawget(task_system, "finished_task_list")
	if not task_list then
		task_list = {}
		rawset(task_system, "task_list", task_list)
	end
	if not finished_task_list then
		finished_task_list = {}
		rawset(task_system, "finished_task_list", finished_task_list)
	end
	
	local task_conf = Task_conf[task_id]
	assert(task_conf, "task not find")
	
	local cur_task = nil
	for k,v in ipairs(task_list) do
		if v.id == task_id then
			assert(v.status == 0 or v.status == 1, "task has been taked")
			cur_task = v
			break
		end
	end
	local some_err = false
	local pre_task = task_conf.BEF_TASK
	if pre_task ~= 0 then some_err = true end
	if not cur_task then
		for k,v in ipairs(finished_task_list) do
			if v == task_id then
				error("task has been finished")
			end
			if pre_task ~= 0 then
				if v == pre_task then some_err = false end
			end
		end
		assert(not some_err)
		cur_task = {
			id = task_id,
			status = 0,
		}
		table.insert(task_list, cur_task)
	end
	local task_level = task_conf.TASK_LV
	local level = main_data.lead.level
	assert(level >= task_level, "level is less then TASK_LV")
	cur_task.status = 2
	return cur_task
end

function logic_user.get_task_reward(main_data, item_list, task_id)
	local task_system = main_data.task_list
	local task_list = task_system.task_list
	
	local task_conf = Task_conf[task_id]
	assert(task_conf, "task not find")
	
	local cur_task = nil
	local task_idx = 0
	for k,v in ipairs(task_list) do
		if v.id == task_id then
			assert(v.status == 2, "task not finished")
			cur_task = v
			task_idx = k
			break
		end
	end
	assert(cur_task, "task not find")
	
	local rewards = task_conf.REWARD
	local ret_item = {item_list = {}, gold = 0, money = 0}
	local k = 1
	while rewards[k] do
		core_user.get_item(rewards[k], rewards[k + 1], main_data, 22, nil, item_list, ret_item, nil)
		k = k + 2
	end
	ret_item.gold = main_data.gold
	ret_item.money = main_data.money
	
	cur_task.status = 3
	local back_task = clonetab(cur_task)
	local next_task = task_conf.NEXT_TASK
	local new_task = nil
	if next_task ~= 0 then
		local new_task_conf = Task_conf[next_task]
		assert(new_task_conf, "task not find")
		cur_task.id = next_task
		cur_task.status = 1
		core_task.check_task_by_task(main_data, cur_task, new_task_conf)
	end

	return back_task, cur_task, ret_item
end

function logic_user.get_chengjiu_reward(main_data, item_list, chengjiu_id)
	local chengjiu_system = main_data.chengjiu
	local chengjiu_list = chengjiu_system.chengjiu_list
	
	local chengjiu_conf = Achievement_conf[chengjiu_id]
	assert(chengjiu_conf, "chengjiu not find")
	
	local chengjiu_data = nil
	for k,v in ipairs(chengjiu_list) do
		if v.id == chengjiu_id then
			assert(v.status == 1, "chengjiu status != 1")
			v.status = 2
			chengjiu_data = v
			break
		end
	end
	assert(chengjiu_data, "chengjiu not find")
	
	local rewards = chengjiu_conf.Reward
	local ret_item = {item_list = {}, gold = 0, money = 0}
	local k = 1
	while rewards[k] do
		core_user.get_item(rewards[k], rewards[k + 1], main_data, 23, nil, item_list, ret_item, nil)
		k = k + 2
	end
	ret_item.gold = main_data.gold
	ret_item.money = main_data.money
	
	return chengjiu_data, ret_item
end

function logic_user.get_daily_reward(main_data, item_list, daily_id, task_struct)
	local t = main_data.daily.daily_list[1].flag
	local daily_system = main_data.daily
	local daily_list = daily_system.daily_list
	
	local daily_conf = Daily_conf[daily_id]
	assert(daily_conf, "daily not find")
	
	local daily_data = nil
	local new_daily = nil
	for k,v in ipairs(daily_list) do
		t = v.id
		if v.id == daily_id then
			assert(v.status == 1, "daily status != 1")
			v.status = 2
			daily_data = v
			break
		end
	end
	assert(daily_data, "daily not find")
	
	if daily_conf.Para_Type == 6 then
		local t = main_data.ext_data.yueka.left_idx
		local yueka = rawget(main_data.ext_data, "yueka")
		assert(yueka, "no yueka struct")
		daily_data.flag = t - 1
	elseif daily_conf.Para_Type == 7 then
		local find_next = false
		local conf = Daily_conf[daily_id + 1]
		if conf then
			for k,v in ipairs(daily_list) do
				if v.id == daily_id + 1 then
					v.status = 0
					new_daily = v
					find_next = true
					break
				end
			end
		end
		if find_next then
			daily_data.status = 3
			daily_data.flag = 1
		end
	end
	
	local rewards = daily_conf.Reward
	local ret_item = {item_list = {}, gold = 0, money = 0, exp = 0, level = nil, tili = 0, daily_list = {}}
	if new_daily then
		table.insert(ret_item.daily_list, new_daily)
	end
	
	local k = 1
	local gold_value = daily_conf.Coinbase + daily_conf.Coinlv * main_data.lead.level
	
	local levelup_struct = {
		ret = false,
		data = nil,
	}
	while rewards[k] do
		core_user.get_item(rewards[k], rewards[k + 1], main_data, 24, nil, item_list, ret_item, levelup_struct)
		k = k + 2
	end
	if gold_value > 0 then
		core_user.get_item(191010001, gold_value, main_data, 24, nil, nil, ret_item, nil)
	end
	ret_item.gold = main_data.gold
	ret_item.money = main_data.money
	ret_item.exp = main_data.lead.exp
	ret_item.tili = main_data.tili
	
	-- 检测成就
	core_task.check_chengjiu_levelup(task_struct, main_data)
	core_task.check_chengjiu_total_gold(task_struct, main_data)
	core_task.check_chengjiu_max_gold(task_struct, main_data)
	if levelup_struct.ret then
		core_task.reflesh_all_when_levelup(task_struct, main_data, levelup_struct)
		ret_item.level = levelup_struct.data
		local user_name = main_data.user_name
		assert(user_name, "user_name is nil")
		core_power.reflesh_knight_power(main_data, nil, 0, core_power.create_modify_power(rank.modify_power, user_name))
		group_cache.update_user_info(main_data)
	end
	
	return daily_data, ret_item
end


function logic_user.get_vip_reward(vip_idx, main_data, knight_list, item_list, task_struct, notify_struct)
	local t = main_data.ext_data.total_login
	local vip_reward_list = rawget(main_data.ext_data, "vip_reward")
	assert(vip_reward_list, "vip reward_list is nil")
	t = vip_reward_list[1]
	assert(rawlen(vip_reward_list) >= vip_idx, "vip idx < len")
	assert(vip_reward_list[vip_idx] == 0, "vip reward has been got")
	vip_reward_list[vip_idx] = 1
	
	local conf = VIP_conf[vip_idx]
	local reward_list = conf.REWARDLIST
	
	local ret_item = {item_list = {}, new_knight_list = {}, gold = 0}
	local k = 1
	while reward_list[k] do
		core_user.get_item(reward_list[k], reward_list[k + 1], main_data, 25, knight_list, item_list, ret_item, nil)
		k = k + 2
	end
	for k,v in ipairs(ret_item.new_knight_list) do
		if v.id == 10050012 then
			notify_struct.ret = true
			notify_struct.data = notify_sys.add_message(main_data.user_name, main_data.nickname, 3)
		end
	end
	ret_item.gold = main_data.gold
	-- 检测成就
	core_task.check_chengjiu_knight_star_num(task_struct, main_data, knight_list)
	core_task.check_chengjiu_knight_special(task_struct, main_data, knight_list)

	return ret_item
end

function logic_user.get_tili_reward(main_data, reward_id)
	local t = main_data.timestamp.get_tili
	assert(reward_id > t, "tili_reward_id has gotten")
	local conf_idx = 3107000 + reward_id
	local conf = Daily_conf[conf_idx]
	assert(conf, "tili_reward_conf not find")
	local begin_h = conf.Para[1]
	local end_h = conf.Para[2]
	local tm = os.date("*t")
	assert(tm.hour >= begin_h and tm.hour < end_h, "tili_reward_id is out of time")
	main_data.timestamp.get_tili = reward_id
	main_data.tili = main_data.tili + conf.Reward[2]
end

--侠义炼化
function logic_user.transform(main_data, item_list, transform_list)
	local lev = main_data.lead.level
	assert(lev >= Open_conf[18].OPEN_PARA)
	local temp_list = {}
	for k,v in ipairs(transform_list) do
		v.num = 0
		rawset(temp_list, v.id, v)
	end
	for k,v in ipairs(item_list) do
		local t = rawget(temp_list, v.id)
		if t then t.num = v.num end
	end
	local ghost = main_data.xyshop.ghost
	local new_ghost = 0
	local ret_item = {}
	for k,v in ipairs(transform_list) do
		assert(v.num > 0, "some item not find")
		local id = v.id - 180000000
		local conf = Convert_conf[id]
		new_ghost = new_ghost + conf.Chivalrous * v.num
		core_user.expend_item(v.id, v.num, main_data, 60, item_list, ret_item)
	end
	main_data.xyshop.ghost = ghost + new_ghost
	local ret_struct = {item_list = ret_item, ghost = main_data.xyshop.ghost}
	return ret_struct
end

function logic_user.reflesh_xyshop(main_data, item_list, force)
	local t = main_data.xyshop.next_reflesh_time
	local rsync = {item_list = {}, cur_money = main_data.money}
	local need_reflesh = false
	if force == 1 then
		need_reflesh = true
		main_data.xyshop.next_reflesh_time = os.time() + 7200
		local ret = core_user.expend_sxl(1, {main_data = main_data, item_list = item_list}, rsync.item_list, 61)
		if ret == -1 then
			core_money.use_money(20, main_data, 0, 61)
			rsync.cur_money = main_data.money
		end
	else
		local tm = os.time()
		if tm >= t then
			while t <= tm do
				t = t + 7200
			end
			main_data.xyshop.next_reflesh_time = t
			need_reflesh = true
		end
	end
	if need_reflesh then
		local xy_shop_list = {}
		local xy_pool = {}
		local xy_conf = Lottery_conf[100028]
		assert(xy_conf)
		core_drop.do_choujiang_from_1(xy_conf, xy_pool, true)
		for k,v in ipairs(xy_pool) do
			local i_conf = Xia_Shop_conf[v[1]]
			table.insert(xy_shop_list, {item = {id = v[1], num = v[2]}, cost = i_conf.PRICE * v[2], status = 0})
		end
		main_data.xyshop.shopping_list = xy_shop_list
	end
	return main_data.xyshop, rsync
end

function logic_user.xy_shopping(main_data, item_list, item_idx)
	local t = main_data.xyshop.next_reflesh_time
	local tm = os.time()
	assert(t > tm)
	t = main_data.xyshop.shopping_list[1].status
	local entry = rawget(main_data.xyshop.shopping_list, item_idx)
	assert(entry and entry.status == 0, "item_idx err")
	local ghost = main_data.xyshop.ghost
	if ghost == 0 then ghost = 5000 end
	assert(ghost >= entry.cost)
	main_data.xyshop.ghost = ghost - entry.cost
	local ret_struct = {
		item_list = {},
	}
	core_user.get_item(entry.item.id, entry.item.num, main_data, 62, nil, item_list, ret_struct)
	entry.status = 1
	ret_struct.xyshop = main_data.xyshop
	return ret_struct
end

function logic_user.wxjy(main_data, wxjy_idx)
	local lev = main_data.lead.level
	if wxjy_idx == 1 or wxjy_idx == 11 then
		--血
		assert(lev >= Open_conf[22].OPEN_PARA)
	elseif wxjy_idx == 2 or wxjy_idx == 12 then
		--攻
		assert(lev >= Open_conf[20].OPEN_PARA)
	elseif wxjy_idx == 3 or wxjy_idx == 13 then
		--防
		assert(lev >= Open_conf[21].OPEN_PARA)
	elseif wxjy_idx == 4 or wxjy_idx == 14 then
		--速
		assert(lev >= Open_conf[23].OPEN_PARA)
	elseif wxjy_idx == 5 or wxjy_idx == 15 then
		--命中
		assert(lev >= Open_conf[28].OPEN_PARA)
	elseif wxjy_idx == 6 or wxjy_idx == 16 then
		--闪避
		assert(lev >= Open_conf[29].OPEN_PARA)
	elseif wxjy_idx == 7 or wxjy_idx == 17 then
		--暴击
		assert(lev >= Open_conf[30].OPEN_PARA)
	elseif wxjy_idx == 8 or wxjy_idx == 18 then
		--技能暴击
		assert(lev >= Open_conf[31].OPEN_PARA)
	elseif wxjy_idx == 9 or wxjy_idx == 19 then
		--抗暴
		assert(lev >= Open_conf[32].OPEN_PARA)
	else
		error("wxjy_idx err")
	end
	
	local t = main_data.wxjy[1]
	t = main_data.wxjy[wxjy_idx]
	local conf = Extreme_conf[t]
	assert(conf.Price > 0)
	local ghost = main_data.xyshop.ghost
	assert(ghost >= conf.Price)
	main_data.xyshop.ghost = ghost - conf.Price
	main_data.wxjy[wxjy_idx] = t + 1
end

function logic_user.vip_shopping(main_data, item_list, item_idx, item_num)
	if item_num == 0 then item_num = 1 end
	assert(item_num > 0, "item num <= 0")
	local t = main_data.vip_lev
	local vip_goods = core_vip.vip_goods
	local cur_goods = vip_goods[item_idx]
	assert(cur_goods, "vip goods not find")
	assert(cur_goods.vip_level <= t, "vip level limit")
	local goods_entry = main_data.vip_shoplist.goods_list[item_idx]
	assert(goods_entry)
	if cur_goods.buy_limit[1] ~= -1 then
		assert(goods_entry.buy_num < cur_goods.buy_limit[t])
	end
	goods_entry.buy_num = goods_entry.buy_num + item_num
	
	local cost = cur_goods.goods.cost * item_num
	core_money.use_money(cost, main_data, 0, 71)
	local goods = cur_goods.goods.item
	local ret_struct = {
		item_list = {},
		cur_money = main_data.money
	}
	core_user.get_item(goods.id, goods.num * item_num, main_data, 63, nil, item_list, ret_struct)
	return ret_struct,goods_entry
end

function logic_user.vip_gift(main_data, item_list, item_idx)
	local t = main_data.vip_lev
	local vip_gift = core_vip.vip_gift
	local cur_item = vip_gift[item_idx]
	assert(cur_item, "vip goods not find")
	assert(cur_item.vip_level <= t, "vip level limit")
	local gift_entry = main_data.vip_gift.gift_list[item_idx]
	assert(gift_entry)
	assert(gift_entry.buy_num > 0)
	
	gift_entry.buy_num = gift_entry.buy_num - 1
	
	local cost = cur_item.price
	core_money.use_money(cost, main_data, 0, 71)
	local ret_struct = {
		item_list = {},
		cur_money = main_data.money,
		cur_gold = main_data.gold,
		cur_tili = main_data.tili,
	}
	for k,v in ipairs(gift_entry.item_list) do
		core_user.get_item(v.id, v.num, main_data, 64, nil, item_list, ret_struct)
	end
	ret_struct.cur_gold = main_data.gold
	return ret_struct,gift_entry
end

function logic_user.open_chest(main_data, item_list, chest_id, num, task_struct)
	assert(chest_id == 190100001 or chest_id == 190100002 or chest_id == 190100003)
	assert(num > 0)
	local ret_item_list = {}
	core_user.expend_item(chest_id, num, main_data, 500, item_list, ret_item_list)
	core_user.expend_item(chest_id + 10000, num, main_data, 500, item_list, ret_item_list)
	
	local rsync = {item_list = ret_item_list, cur_money = 0, cur_gold = 0}
	local conf = Box_conf[chest_id]
	local pool = conf.Box_Pool
	local t_list = {}
	for k = 1, num do
		core_drop.get_item_list_from_id(pool, t_list)
	end
	
	core_user.get_item_list({main_data = main_data, item_list = item_list},
		t_list, {rsync = rsync}, 500)
	
	rsync.cur_gold = main_data.gold
	rsync.cur_money = main_data.money
	
	-- 检测成就
	core_task.check_chengjiu_total_gold(task_struct, main_data)
	core_task.check_chengjiu_max_gold(task_struct, main_data)
	return rsync
end

function logic_user.do_cost_when_chat(main_data, item_list, chat_type)
	local r_item_list = {}
	if chat_type == 0 then
		if core_user.expend_item(191010022, 1, main_data, 501, item_list, r_item_list, true) == -1 then
			core_money.use_money(10, main_data, 0, 501)
		end
	end
	local rsync = {
		cur_money = main_data.money,
		item_list = r_item_list,
	}
	return rsync
end

function logic_user.get_qiyu(main_data, item_list, qiyu_guid)
	local qiyu_struct = core_user.get_qiyu(main_data)
	local qy_data = nil
	local qy_idx = 0
	for k,v in ipairs(qiyu_struct.qiyu_list) do
		if v.guid == qiyu_guid then
			qy_data = v
			qy_idx = k
			break
		end
	end
	assert(qy_idx ~= 0 and qy_data, "qiyu not find")
	assert(os.time() <= (qy_data.stamp + qy_data.duration), "qiyu outoftime")
	local tjhf = rawget(qy_data, "tjhf")
	local tfly = rawget(qy_data, "tfly")
	local yysr = rawget(qy_data, "yysr")
	local reward_list = {}
	local cost = 0
	if tjhf then
		table.insert(reward_list, {tjhf.item.id, tjhf.item.num})
	elseif tfly then
		cost = cost + tfly.cost
		table.insert(reward_list, {tfly.item.id, tfly.item.num})
	elseif yysr then
		cost = cost + yysr.cost
		table.insert(reward_list, {yysr.item.id, yysr.item.num})
	end
	
	if cost > 0 then
		core_money.use_money(cost, main_data, 0, 101)
	end
	local ret_struct = {
		item_list = {},
		cur_money = main_data.money,
	}
	
	core_user.get_item_list(
		{main_data = main_data, item_list = item_list}, 
		reward_list, {rsync = ret_struct}, 108)
	table.remove(qiyu_struct.qiyu_list, qy_idx)
	local t = main_data.ext_data.huodong.qiyu
	main_data.ext_data.huodong.qiyu = rawlen(qiyu_struct.qiyu_list)
	return ret_struct,qy_data, qiyu_struct
end

function logic_user.del_qiyu(main_data, qiyu_guid)
	local qiyu_struct = core_user.get_qiyu(main_data)
	local qy_data = nil
	local qy_idx = 0
	for k,v in ipairs(qiyu_struct.qiyu_list) do
		if v.guid == qiyu_guid then
			qy_data = v
			qy_idx = k
			break
		end
	end
	assert(qy_idx ~= 0 and qy_data, "qiyu not find")
	table.remove(qiyu_struct.qiyu_list, qy_idx)
	local t = main_data.ext_data.huodong.qiyu
	main_data.ext_data.huodong.qiyu = rawlen(qiyu_struct.qiyu_list)
	return qy_data, qiyu_struct
end

function logic_user.get_chongzhi_list(main_data)
	local list = global_huodong.get_czlist(main_data)
	local huodong = global_huodong.get_huodong(main_data, "czdb")
	local czdb = nil
	--是否存在充值活动
	if huodong then czdb = huodong.detail end
	return list, czdb
end

function logic_user.jiban(main_data, knight_list, tag_guid, src_guids)
	local t1 = src_guids[1]
	local src_num = rawlen(src_guids)
	
	local t = core_user.get_knight_by_guid(tag_guid, main_data, knight_list)
	assert(t[2])
	local tag_knight = t[2]
	assert(main_data.lead.level >= 30)
	local c_conf = Character_conf[tag_knight.id]
	local star = c_conf.STAR_LEVEL
	if star == 6 then assert(src_num <= 2)
	else assert(src_num == 1) end
	
	local ret_knight_list = {}
	table.insert(ret_knight_list, tag_knight)
	-- 解除原羁绊
	local t = tag_knight.data.level
	local jiban_list = rawget(tag_knight.data, "jiban_list")
	if jiban_list then
		for k,v in ipairs(jiban_list) do
			if v >= 0 then
				
				local tdata = core_user.get_knight_from_bag_by_guid(v, knight_list)
				assert(tdata[2])
				local t = tdata[2].data.level
				tdata[2].data.master = 0
				table.insert(ret_knight_list, tdata[2])
			end
		end
	end
	jiban_list = {}
	rawset(tag_knight.data, "jiban_list", jiban_list)
	
	
	local pve2 = main_data.PVE.pve2
	local s_pve2_zhanwei_list = pve2.zhenxing
	-- 设置新羁绊
	for k,v in ipairs(src_guids) do
		if v >= 0 then
			for k1,v1 in ipairs(s_pve2_zhanwei_list) do
				if v1.guid == v then
					v1.guid = -2
					local tdata = core_user.get_knight_from_bag_by_guid(v, knight_list)
					assert(tdata[2])
					tdata[2].data.lock = 0
					break
				end
			end
			assert(v ~= tag_guid)
			local tdata = core_user.get_knight_from_bag_by_guid(v, knight_list)
			assert(tdata[2])
			--assert(tdata[2].data.lock == 0, "on some zhenxing")
			assert(tdata[2].data.master == 0, "has master")
			local jiban = rawget(tdata[2].data, "jiban_list")
			local has_jiban = false
			if jiban then
				for k1,v1 in ipairs(jiban) do
					if v1 >= 0 then
						has_jiban = true
						break
					end
				end
			end
			assert(not has_jiban, "has jiban")
			tdata[2].data.master = tag_guid + 1
			table.insert(ret_knight_list, tdata[2])
		end
		table.insert(jiban_list, v)
	end
	core_power.reflesh_knight_power(main_data,knight_list, tag_knight.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
	return ret_knight_list, s_pve2_zhanwei_list
end

function logic_user.qianneng(main_data, knight_list, tag_guid)
	local t = core_user.get_knight_by_guid(tag_guid, main_data, knight_list)
	assert(t[2])
	local tag_knight = t[2]
	--临时
	local t = tag_knight.qianneng
	t = t + 1
	tag_knight.qianneng = t
	
	return tag_knight
end

function logic_user.sw_levelup( main_data, knight_list, item_list, req )
	local sevenweapon = core_user.check_sevenweapon_init( main_data, knight_list )
	--printtab(req)
	local slotidx = req.slotidx
	assert(slotidx > 0 and slotidx < 8)
	local itemid = 191010031
	local rsync = {item_list = {}}
	local onekey = false
	if req.onekey == 1 then
		onekey = true
	end
	local level = sevenweapon[slotidx].level
	assert(level and level > 0 )
	local conf = Seven_Weapon_conf[level]

	if not onekey then       
		assert(conf and conf.Need_Amount ~= 0)   
		core_user.expend_item(itemid, conf.Need_Amount, main_data, 904, item_list, rsync.item_list)
		level = level + 1
		sevenweapon[slotidx].level = level
	else
		local totalnum = 0
		for k,v in ipairs(item_list) do
			if v.id == itemid then
				totalnum = v.num
				break
			end
		end
		--print("totalnum:"..totalnum)
		while conf and totalnum >= conf.Need_Amount and conf.Need_Amount ~= 0 do
			core_user.expend_item(itemid, conf.Need_Amount, main_data, 904, item_list, rsync.item_list)
			level = level + 1
			sevenweapon[slotidx].level = level
			totalnum = totalnum - conf.Need_Amount
			--print("in totalnum:"..totalnum.. " "..conf.Need_Amount.. " tolv:"..level)
			conf = Seven_Weapon_conf[level]
		end
	end

	rsync.cur_money = main_data.money
	rsync.cur_gold = main_data.gold
	rsync.cur_tili = main_data.tili

	local resp = {
		result = "OK",
		slotidx = slotidx,
		rsync = rsync,
		sevenweapon = sevenweapon,
	}

	return resp
end

return logic_user