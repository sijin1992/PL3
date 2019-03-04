local core_fight = require "fight"
local Monster = require "fight_monster"

local Trial_conf = Tower_conf

local time_checking = require "time_checking"
local update_tili_per_6min = time_checking.update_tili_per_6min

local core_user = require "core_user_funcs"
local core_drop = require "core_drop"
local core_task = require "core_task"
local core_money = require "core_money"
local core_power = require "core_calc_power"

local tinsert = table.insert

local PVE = {}

local function create_new_fortress(new_fortress_id)
	local fortress_data = Fortress_conf[Fortress_conf.index[new_fortress_id]]
	if not fortress_data then return nil end
	local phase_reward = {}
	if fortress_data.PHASE_REWARD_1_OPEN > 0 then tinsert(phase_reward, 0) end
	if fortress_data.PHASE_REWARD_2_OPEN > 0 then tinsert(phase_reward, 0) end
	if fortress_data.PHASE_REWARD_3_OPEN > 0 then tinsert(phase_reward, 0) end
	local stage_list = {}
	for k,v in ipairs(fortress_data.STAGE_LIST) do
		local stage_data = Stage_conf[v]
		assert(stage_data)
		local difficulty_list = {}
		for k1 = 1, stage_data.DIFFICULTY_QUANTITY do
			tinsert(difficulty_list, {pass_num = 0, today_pass_num = 0})
		end
		local stage = {
			difficulty_list = difficulty_list
		}
		tinsert(stage_list, stage)
	end
	local fortress = {
		id = new_fortress_id,
		stage_list = stage_list,
		phase_reward = phase_reward,
		star = 0,
	}
	local jinfrotress_data = Jing_Fortress_conf[Jing_Fortress_conf.index[new_fortress_id]]
	local jingying_stage = {}
	for k,v in ipairs(jinfrotress_data.STAGE_LIST) do
		tinsert(jingying_stage, {id = v, pass_num = 0, today_pass_num = 0})
	end
	local jingying_fortress = {
		id = jinfrotress_data.ID,
		stage_list = jingying_stage
	}
	return fortress, jingying_fortress
end

function PVE.create_new_fortress(new_fortress_id)
	return create_new_fortress(new_fortress_id)
end

local function get_environment_data(pve_data, fight_core)
	local stage_conf = pve_data.stage_conf
	local difficulty = pve_data.difficulty
	-- 有ghost，表示原始关卡配置只在第一次打时有用
	local pass_num = pve_data.stage_data.pass_num
	local use_ghost = true
	if magic_switch then
		use_ghost = false
	end
	if stage_conf.GHOST and stage_conf.GHOST ~= 0 then
		if use_ghost and pass_num > 0 then
			local stage_id = stage_conf.GHOST
			stage_conf = Stage_conf[stage_id]
			assert(stage_conf ~= nil, "stage "..stage_id.." not find")
			pve_data.stage_conf = stage_conf
			pve_data.stage_id = stage_id
		end
	end
	local is_boss = false
	local difficult = 1
	if difficulty == 2 then difficult = 2 end
	local role_list = fight_core.role_list
	local posi_list = fight_core.posi_list
	for k,v in ipairs(stage_conf.NPC_LIST) do
		if v ~= 0 then
			is_boss = false
			for k1,v1 in ipairs(stage_conf.BOSS_ID) do
				if k == v1 then
					is_boss = true
					break
				end
			end
			local monster = Monster:new(v, k + 100, difficult, is_boss)
			tinsert(role_list, monster)
			rawset(posi_list, k + 100, monster)
		end
	end
	local stage_id = pve_data.stage_id
	if --pass_num == 0 and
		((stage_id == 50010003 or stage_id == 50010005 or stage_id == 50010008)
		or (stage_id == 50020002)
		or (stage_id == 50170002 or stage_id == 50170004 or stage_id == 50170006 or stage_id == 50170010)
		or (stage_id == 50180001 or stage_id == 50180010)
		or (stage_id == 50190001 or stage_id == 50190010)
		or (stage_id == 50030001 or stage_id == 50030010)
		or (stage_id == 50040002 or stage_id == 50040010) 
		or (stage_id == 50200001 or stage_id == 50200010)
		or (stage_id == 50050001)
		or (stage_id == 50060001 or stage_id == 50060006 or stage_id == 50060010)
		or stage_id == 50070001
		or (stage_id == 50080002 or stage_id == 50080007)
		or (stage_id == 50090003 or stage_id == 50090006 or stage_id == 50090010)
		or (stage_id == 50100002 or stage_id == 50100010)
		or (stage_id == 50110003 or stage_id == 50110010)
		or (stage_id == 50120004 or stage_id == 50120010)
		or (stage_id == 50130003 or stage_id == 50130010)
		or (stage_id == 50140005 or stage_id == 50140010)
		or (stage_id == 50150001 or stage_id == 50150002 or stage_id == 50150004 or stage_id == 50150010)
		or (stage_id == 50160001 or stage_id == 50160007 or stage_id == 50160010)
		or (stage_id == 50210003 or stage_id == 50210010)
		or (stage_id == 50220001 or stage_id == 50220010)
		or (stage_id == 50230001 or stage_id == 50230007 or stage_id == 50230010)
		or (stage_id == 50240001 or stage_id == 50240010)
		or (stage_id == 50250001 or stage_id == 50250010)
		or (stage_id == 50260001 or stage_id == 50260010)
		or (stage_id == 50270010)
		or (stage_id == 50280001 or stage_id == 50280007 or stage_id == 50280010)
		or (stage_id == 50320002 or stage_id == 50320006 or stage_id == 50320010)
		or (stage_id == 50330008 or stage_id == 50330010)
		or (stage_id == 50340004 or stage_id == 50340010)
		or (stage_id == 50350005 or stage_id == 50350007 or stage_id == 50350010)
		or (stage_id == 50360010)
		or (stage_id == 50370007 or stage_id == 50370010)
		or (stage_id == 50380004 or stage_id == 50380010)
		or (stage_id == 50390010)
		or (stage_id == 50400010)
		or (stage_id == 50410003 or stage_id == 50410006 or stage_id == 50410010)
		or (stage_id == 50420003 or stage_id == 50420006 or stage_id == 50420010)
		or (stage_id == 50430003 or stage_id == 50430006)
		or (stage_id == 50440006 or stage_id == 50440010)
		or (stage_id == 50450004 or stage_id == 50450010)
		or (stage_id == 50460004 or stage_id == 50460007 or stage_id == 50460010)
		or (stage_id == 50470006 or stage_id == 50470010)
		or (stage_id == 50480002 or stage_id == 50480004 or stage_id == 50480006 or stage_id == 50480010)
		)
		then
		pve_data.do_event = true
		fight_core.event_id = (math.floor((stage_id - 50000000)/100) + stage_id % 100) * 100
	elseif ((stage_id == 400340004 or stage_id == 400340010)
		or (stage_id == 400350005 or stage_id == 400350007 or stage_id == 400350010)
		or (stage_id == 400360010)
		or (stage_id == 400370007 or stage_id == 400370010)
		or (stage_id == 400380004 or stage_id == 400380010)
		or (stage_id == 400390010)
		or (stage_id == 400400010)
		or (stage_id == 400410003 or stage_id == 400410006 or stage_id == 400410010)
		or (stage_id == 400420003 or stage_id == 400420006 or stage_id == 400420010)
		or (stage_id == 400430003 or stage_id == 400430006)
		or (stage_id == 400440006 or stage_id == 400440010)
		or (stage_id == 400450004 or stage_id == 400450010)
		or (stage_id == 400460004 or stage_id == 400460007 or stage_id == 400460010)
		or (stage_id == 400470006 or stage_id == 400470010)
		or (stage_id == 400480002 or stage_id == 400480004 or stage_id == 400480006 or stage_id == 400480010)
		)
		then
		pve_data.do_event = true
		fight_core.event_id = (math.floor((stage_id - 400000000)/100) + stage_id % 100) * 100 + 2000000
	else
		pve_data.do_event = false
		fight_core.event_id = 0
	end
		
	if (not use_ghost) or pass_num == 0 then
		if stage_conf.OPENING_TALK ~= 0 then fight_core.start_talk = stage_conf.OPENING_TALK end
		if stage_conf.ENDING_TALK ~= 0 then fight_core.end_talk = stage_conf.ENDING_TALK end
	end
end

--指定一个关卡，获取关卡的奖励列表并插入总奖励列表中
--返回本次获得的物品列表
local function get_pve_reward_list(stage_id, reward_list)
	local t_list = {};
	local stage_conf = nil
	if stage_id >= 50000000 and stage_id <= 59999999 then
		stage_conf = Stage_conf[stage_id]
	else
		stage_conf = Jing_Stage_conf[stage_id]
	end
	--固定掉落
	local reward = stage_conf.EASY_REWARD_FIXED
	local k = 1
	while reward[k] do
		table.insert(t_list, {reward[k], reward[k + 1]})
		k = k + 2
	end
	
	--浮动掉落
	if stage_conf.BELONGS_FORTRESS ~= 0 then
		--普通本，精英本有浮动掉落，爬塔没有
		reward = stage_conf.EASY_REWARD_FLOAT
		k = 1
		local need_min = true
		while reward[k] do
			local t = math.random(100)
			if t <= reward[k + 1] then
				core_drop.get_item_list_from_id(reward[k], t_list)
				need_min = false
			end
			k = k + 2
		end
		if need_min then
			for k1,v1 in ipairs(stage_conf.Min_Drop) do
				if v1 ~= 0 then
					core_drop.get_item_list_from_id(v1, t_list)
				end
			end
		end
	end
	for k,v in ipairs(t_list) do
		local find = false
		for k1,v1 in ipairs(reward_list) do
			if v1[1] == v[1] then
				v1[2] = v1[2] + v[2]
				find = true
				break
			end
		end
		if not find then
			table.insert(reward_list, v)
		end
	end
	return t_list
end

local function get_pve_reward(pve_data, rsync, user_info, item_list, levelup_struct, where)
	local reward_list = {}
	get_pve_reward_list(pve_data.stage_id, reward_list)
	local user_struct = {main_data = user_info, item_list = item_list}
	local ret_list = {rsync = rsync, levelup_struct = levelup_struct}
	local inwhere = 101
	if where then inwhere = where end
	if pve_data.cost_hp then
		-- pve推本和扫荡，在活动期间，要产出特殊道具
		local hd = global_huodong.check_duihuan(user_info)
		if hd then
			local pool = hd.pool6
			if pve_data.cost_hp == 8 then
				pool = hd.pool8
			elseif pve_data.cost_hp == 10 then
				pool = hd.pool10
			elseif pve_data.cost_hp == 12 then
				pool = hd.pool12
			end
			local t_list = {}
			core_drop.get_item_list_from_id(pool, t_list)
			if t_list[1] then
				if rawlen(reward_list) >= 6 then
					reward_list[6] = t_list[1]
				else
					table.insert(reward_list, t_list[1])
				end
			end
		end
	end
	core_user.get_item_list(user_struct, reward_list, ret_list, inwhere)
end

local function pre_normal_pve(pve_data, main_data)
	local stage_id = pve_data.stage_id
	local stage_conf = Stage_conf[stage_id]
	assert(stage_conf, "stage conf not find")
	pve_data.stage_conf = stage_conf
	local fortress_id = stage_conf.BELONGS_FORTRESS
	local fortress_conf = Fortress_conf[fortress_id]
	assert(fortress_conf, "fortress conf not exist")
	assert(fortress_conf.ENTER_LEVEL <= main_data.lead.level, "cur level can't play this fortress")
	
	local fortress = fortress_id % 10000
	local stage_idx = stage_id % 10000
	local pve = main_data.PVE
	local fortress_list = pve.fortress_list
	assert(fortress <= #fortress_list, "fortress:" ..fortress .. " not inited")
	-- 已有章节
	local cur_fortress = fortress_list[fortress]
	local cur_stage_list = cur_fortress.stage_list
	local cur_stage = cur_stage_list[stage_idx]
	if stage_idx > 1 then
		-- 打后面的关前，必须先打前面的简单关卡
		assert(cur_stage_list[stage_idx - 1].difficulty_list[1].pass_num > 0)
	end
	--[[ 没有多个难度了
	if difficulty > 1 then
		-- 打后面的难度前，必须先打上一难度
		assert(cur_stage.difficulty_list[difficulty - 1].pass_num > 0)
	end]]
	pve_data.stage_data = cur_stage.difficulty_list[1]
	pve_data.fortress_data = cur_fortress
	pve_data.cost_hp = stage_conf.STAMINA
end

--武林之巅之前的处理
local function pre_pve_trial(trial_data, main_data, fight_core)
	local trial_info = main_data.PVE.trial_info;
	local layer = trial_data.tar_layer;
	local trial_conf = Trial_conf[layer]
	assert(trial_conf, "trialconf not find layer:" .. layer)
	local stage_id = trial_conf.Stage
	local stage_conf = Stage_conf[stage_id]
	assert(stage_conf, "stage conf not find layer:" .. stage_id)

	assert(layer == trial_info.cur_layer + 1)
	-- 已有章节
	local userLevel = main_data.lead.level
	assert(userLevel >= trial_conf.Open_Level, "cur level:"..userLevel.." can't play this layer, need:"..trial_conf.Open_Level)

	trial_data.trial_conf = trial_conf;
	trial_data.stage_id = stage_id;
	trial_data.stage_conf = stage_conf;

	-- 初始化NPC
	local role_list = fight_core.role_list
	local posi_list = fight_core.posi_list
	for k,v in ipairs(stage_conf.NPC_LIST) do
		if v ~= 0 then
			is_boss = false
			for k1,v1 in ipairs(stage_conf.BOSS_ID) do
				if k == v1 then
					is_boss = true
					break
				end
			end
			local monster = Monster:new(v, k + 100, difficult, is_boss)
			tinsert(role_list, monster)
			rawset(posi_list, k + 100, monster)
		end
	end

end

local function pre_jingying_pve(pve_data, main_data)
	local stage_id = pve_data.stage_id
	local stage_conf = Jing_Stage_conf[stage_id]
	assert(stage_conf, "stage conf not find")
	pve_data.stage_conf = stage_conf
	local fortress_id = stage_conf.BELONGS_FORTRESS
	local fortress_conf = Jing_Fortress_conf[fortress_id]
	assert(fortress_conf, "fortress conf not exist")
	assert(fortress_conf.ENTER_LEVEL <= main_data.lead.level, "cur level can't play this fortress")
	
	local fortress_idx = fortress_id % 10000
	local stage_idx = stage_id % 10000
	local pve = main_data.PVE
	local fortress_list = pve.jingying
	local normal_fortress_list = pve.fortress_list
	assert(fortress_idx <= #fortress_list)
	local fortress_data = fortress_list[fortress_idx]
	local cur_stage_data = fortress_data.stage_list[stage_idx]
	if cur_stage_data.pass_num == 0 then
		-- 必须通关普通本
		local t = normal_fortress_list[fortress_idx].stage_list
		assert(t[#t].difficulty_list[1].pass_num > 0)
		if stage_idx > 1 then
			assert(fortress_data.stage_list[stage_idx - 1].pass_num > 0)
		else
			if fortress_idx > 1 then
				-- 上一章节必须通关
				local t = fortress_list[fortress_idx - 1].stage_list
				assert(t[#t].pass_num > 0)
			end
		end
	else
		assert(cur_stage_data.today_pass_num < 3)
	end
	pve_data.jingying_fortress_data = fortress_data
	pve_data.stage_data = fortress_list[fortress_idx].stage_list[stage_idx]
	pve_data.cost_hp = stage_conf.STAMINA
end

function PVE.do_pve(stage, difficulty, user_data, knight_list, item_list, task_struct)
	--for log
	local old_level = user_data.lead.level
	
	local pve_data = {
		stage_id = stage,           -- 关卡id
		difficulty = difficulty,    -- 难度
		stage_conf = nil,           -- 关卡配置
		stage_data = nil,           -- 玩家的关卡数据，方便事后修改
		fortress_data = nil,        -- 玩家章节数据，方便事后修改，比如通关后增加星数等
		jingying_fortress_data = nil,
		do_event = true,            -- 是否执行特殊事件
	}
	local pve = user_data.PVE
	if difficulty == 1 then
		--先获取关卡配置，用户关卡信息能，存到pve_data中
		pre_normal_pve(pve_data, user_data)
	elseif difficulty == 2 then
		local lev = user_data.lead.level
		assert(lev >= Open_conf[9].OPEN_PARA)
		pre_jingying_pve(pve_data, user_data)
	else error("difficulty != 1 or 2")
	end
	local stage_conf = pve_data.stage_conf

	update_tili_per_6min(user_data)
	local max = core_user.max_hp(user_data.lead.level)
	local tili = user_data.tili
	-- 如果之前体力是满的，则体力刷新起始时间点要更新，不然消费体力后，第一次使用的时间将不会是6分钟
	if tili >= max then user_data.timestamp.last_reflesh_tili = os.time() end
	assert(stage_conf.STAMINA > 0)
	assert(tili >= stage_conf.STAMINA) -- 体力判断必须在获取pve信息之后
	local fight = core_fight:new()
	local rcd = fight.rcd
	local preview = rcd.preview
	preview.winner = 0
	get_environment_data(pve_data, fight)
	stage_conf = pve_data.stage_conf
--if stage == 50010003 then
--        local hook = true
--        fight:get_player_data(user_data, false, hook)
--    else
	fight:get_player_data(user_data, knight_list)
--end
	fight:get_attrib()

	-- 这里必须先获取原始preview，排序之后顺序就乱了
	fight:get_preview_role_list()
	fight:play(rcd)
	local winner = fight.winner
	-- 打完扣体力
	local stage_data = pve_data.stage_data
	local fortress_data = nil
	if difficulty == 1 then fortress_data = pve_data.fortress_data
	else fortress_data = pve_data.jingying_fortress_data end
	local task_check_ret = nil
	local cost_hp = 0
	if winner == 1 then
		-- 胜利的话要更新通关信息
		cost_hp = stage_conf.STAMINA
		stage_data.pass_num = stage_data.pass_num + 1
		stage_data.today_pass_num = stage_data.today_pass_num + 1
		if stage_data.pass_num == 1 and difficulty == 1 then
			 --普通本通关任务
			task_check_ret = core_task.check_task_by_event(user_data, 1, {id = stage})
			if task_check_ret then
				task_struct.ret = true
				task_struct.data.task = 1
				task_struct.data.task_list = task_check_ret
			end
			fortress_data.star = fortress_data.star + 1
		elseif stage_data.pass_num == 1 and difficulty == 2 then
			-- 精英本通关任务
			task_check_ret = core_task.check_task_by_event(user_data, 2, {id = stage})
			if task_check_ret then
				task_struct.ret = true
				task_struct.data.task = 1
				task_struct.data.task_list = task_check_ret
			end
			core_task.check_newtask_by_event(user_data, 5, stage)
		end
	end
	--刷新成就。这个成就和胜利与否无关
	if difficulty == 1 then
		core_task.check_chengjiu_total_pve(task_struct, user_data)
	else
		core_task.check_chengjiu_total_jingying(task_struct, user_data)
	end
	--扣体力
	if cost_hp > 0 then
		core_user.expend_hp(cost_hp, user_data, 5)
		local total_cost_hp = user_data.ext_data.total_hp
		user_data.ext_data.total_hp = total_cost_hp + cost_hp
	end
	-- 获取奖励
	local rsync = {
		tili = user_data.tili,
		gold = user_data.gold,
		exp = user_data.lead.exp,
		fortress_list = {},
		item_list = {},
		new_knight_list = {},
		last_reflesh_tili = user_data.timestamp.last_reflesh_tili,
		chengjiu_list = nil,
		jingying_list = {},
	}
	local levelup_struct = {
		ret = false,
		data = nil,
	}
	if winner == 1 then
		local stage_idx = stage % 10000
		if difficulty == 1 then
			tinsert(rsync.fortress_list, fortress_data)
			if stage_idx == #fortress_data.stage_list
				and stage_data.pass_num == 1 then
				local new_fortress,jingying_fortress = create_new_fortress(#pve.fortress_list + 1)
				if new_fortress then
					tinsert(pve.fortress_list, new_fortress)
					tinsert(pve.jingying, jingying_fortress)
				end
				tinsert(rsync.fortress_list, new_fortress)
				tinsert(rsync.jingying_list, jingying_fortress)
			end
		else
			tinsert(rsync.jingying_list, fortress_data)
		end
		get_pve_reward(pve_data, rsync, user_data, item_list, levelup_struct)
		
		local hero_exp = stage_conf.HERO_EXP
		if hero_exp > 0 then
			for k,v in ipairs(user_data.zhenxing.zhanwei_list) do
				if v.status == 2 then
					core_user.add_knight_exp(v.knight, hero_exp, user_data, knight_list)
					local user_name = user_data.user_name
					assert(user_name, "user_name is nil")
					core_power.reflesh_knight_power(user_data, knight_list, v.knight.id, core_power.create_modify_power(rank.modify_power, user_name))
				end
			end
		end
		if levelup_struct.data then
			core_task.reflesh_all_when_levelup(task_struct, user_data, levelup_struct)
			local user_name = user_data.user_name
			assert(user_name, "user_name is nil")
			core_power.reflesh_knight_power(user_data, nil, 0, core_power.create_modify_power(rank.modify_power, user_name))
			group_cache.update_user_info(user_data)
		end
		--刷新成就
		core_task.check_chengjiu_total_gold(task_struct, user_data)
		core_task.check_chengjiu_levelup(task_struct, user_data)
		core_task.check_chengjiu_total_hp(task_struct, user_data)
		core_task.check_chengjiu_max_gold(task_struct, user_data)
		
		core_task.check_daily_pve(task_struct, user_data)
		
		rsync.gold = user_data.gold
		rsync.exp = user_data.lead.exp
		rsync.zhenxing = user_data.zhenxing
		if stage_data.pass_num == 1 then
			core_task.check_chengjiu_stage(task_struct, user_data, stage)
			-- 首次通关记录一下进度
			LOG_STAT( string.format( "%s|%s|%d", "PASS_GQ", user_data.user_name, stage ) )
		end
	else
		--LOG_STAT( string.format( "%s|%s|%d", "UNPASS_GQ", user_data.user_name, stage ) )
	end
	rsync.tili = user_data.tili
	return rcd, rsync, levelup_struct
end

local qy_probability = {
	{60, 20, 20, 4, 5},       --0
	{50, 20, 30, 5, 5},       --1
	{50, 20, 30, 5, 5},       --2
	{40, 30, 30, 5, 5},       --3
	{40, 30, 30, 5, 5},       --4
	{30, 30, 40, 5, 6},       --5
	{30, 30, 40, 5, 6},       --6
	{30, 30, 40, 5, 6},       --7
	{10, 40, 50, 6, 6},       --8
	{10, 40, 50, 6, 6},       --9
	{10, 40, 50, 6, 6},       --10
}


local function do_qiyu(main_data, qiyu_struct)
	local vip = main_data.vip_lev + 1
	local conf = qy_probability[vip]
	local qiyu_conf = Qiyu_conf[vip - 1]
	local t = math.random(100)
	local qy = nil
	if t > 15 then
		return qy   --单次扫荡遇到奇遇的概率是15%
	end
	
	local qiyu_guid = qiyu_struct.guid
	local qiyu_list = qiyu_struct.qiyu_list
	qiyu_struct.guid = qiyu_guid + 1
	t = math.random(100)
	local tjhf = nil
	local tfly = nil
	local yysr = nil
	local ptjhf = conf[1]
	local ptfly = conf[2]
	local pyysr = conf[3]
	if qiyu_struct.today_tjhf >= 7 then
		ptfly = ptfly + ptjhf / 2
		pyysr = pyysr + ptjhf / 2
		ptjhf = 0
	end
	ptfly = ptjhf + ptfly
	pyysr = ptfly + pyysr
	
	if t <= ptjhf then
		-- 天降鸿福
		local drop_id = qiyu_conf.Tianjiang
		local item_list = {}
		core_drop.get_item_list_from_id(drop_id, item_list)
		local item_id = item_list[1][1]
		local item_num = item_list[1][2]
		tjhf = {
			item = {id = item_list[1][1], num = item_list[1][2]},
		}
		qiyu_struct.today_tjhf = qiyu_struct.today_tjhf + 1
	elseif t <= ptfly then
		-- 天付良缘
		local drop_id = qiyu_conf.Tianfu
		local item_list = {}
		core_drop.get_item_list_from_id(drop_id, item_list)
		local item_id = item_list[1][1]
		local item_num = item_list[1][2]
		local cost = Qiyu_Shop_conf[item_id].Price * item_num
		tfly = {
			item = {id = item_id, num = item_num},
			cost = cost,
		}
	else
		-- 云游商人
		local drop_id = qiyu_conf.Yunyou
		local item_list = {}
		core_drop.get_item_list_from_id(drop_id, item_list)
		local item_id = item_list[1][1]
		local item_num = item_list[1][2]
		local cost = Qiyu_Shop_conf[item_id].Price * item_num
		yysr = {
			item = {id = item_id, num = item_num},
			cost = cost,
		}
	end
	qy = {
		tjhf = tjhf,
		tfly = tfly,
		yysr = yysr,
		guid = qiyu_guid,
		stamp = os.time(),
		duration = 3600,
	}
	table.insert(qiyu_list, qy)
	local t = main_data.ext_data.huodong.qiyu
	main_data.ext_data.huodong.qiyu = rawlen(qiyu_list)
	return qy
end

function PVE.clear(stage, difficulty, num, user_data, item_list, task_struct)
	local lev = user_data.lead.level
	assert(lev >= Open_conf[11].OPEN_PARA)
	local stage_conf = nil
	local stage_data = nil
	if difficulty == 1 then
		assert(num == 1 or num == 10, "num err")
		local enable10 = core_vip.pve_clear10(user_data)
		if enable10 == 0 then assert(num == 1) end
		stage_conf = Stage_conf[stage]
		assert(stage_conf, "stage conf not find")
		local ghost = stage_conf.GHOST
		if ghost ~= 0 then
			stage_conf = Stage_conf[ghost]
			assert(stage_conf, "stage conf not find")
		end
		local fortress = stage_conf.BELONGS_FORTRESS % 10000
		local stage_idx = stage % 10000
		local pve = user_data.PVE
		local fortress_list = pve.fortress_list
		assert(fortress <= #fortress_list, "fortress id err")
		local cur_fortress = fortress_list[fortress]
		local cur_stage_list = cur_fortress.stage_list
		local cur_stage = cur_stage_list[stage_idx].difficulty_list[difficulty]
		local t = cur_stage.pass_num
		assert(cur_stage.pass_num > 0, "unpass stage")
		cur_stage.pass_num = cur_stage.pass_num + num
		cur_stage.today_pass_num = cur_stage.today_pass_num + num
		stage_data = cur_stage
	elseif difficulty == 2 then
		stage_conf = Jing_Stage_conf[stage]
		assert(stage_conf, "stage conf not find")
		local fortress = stage_conf.BELONGS_FORTRESS % 10000
		local stage_idx = stage % 10000
		local pve = user_data.PVE
		local fortress_list = pve.jingying
		assert(fortress <= #fortress_list, "fortress id err")
		local cur_fortress = fortress_list[fortress]
		local cur_stage_list = cur_fortress.stage_list
		local cur_stage = cur_stage_list[stage_idx]
		local t = cur_stage.pass_num
		assert(cur_stage.pass_num > 0, "unpass stage")
		local total_num = cur_stage.today_pass_num + num
		if num == 1 then assert(total_num <= 3)
		else assert(num > 1 and total_num == 3) end
		cur_stage.pass_num = cur_stage.pass_num + num
		cur_stage.today_pass_num = cur_stage.today_pass_num + num
		stage_data = cur_stage
	end
	
	update_tili_per_6min(user_data)
	local max = core_user.max_hp(user_data.lead.level)
	local tili = user_data.tili
	-- 如果之前体力是满的，则体力刷新起始时间点要更新，不然消费体力后，第一次使用的时间将不会是6分钟
	if tili >= max then user_data.timestamp.last_reflesh_tili = os.time() end
	local cost_hp = stage_conf.STAMINA
	assert(tili >= cost_hp) -- 体力判断必须在获取pve信息之后
	if num > 0 then assert(tili >= (cost_hp * num))
	else num = math.floor(tili / cost_hp) end
	
	-- 打完扣体力
	cost_hp = stage_conf.STAMINA * num
	core_user.expend_item(191040211, cost_hp, user_data, 6)
	local total_cost_hp = user_data.ext_data.total_hp
	user_data.ext_data.total_hp = total_cost_hp + cost_hp
	
	local get_list = {}
	local pve_data = {
		difficulty = difficulty,
		stage_data = {pass_num = 2},
		stage_conf = stage_conf,
		stage_id = stage_conf.ID,
		cost_hp = stage_conf.STAMINA
	}
	-- 获取奖励
	local is_levelup = false
	local total_levelup_struct = {
		ret = false,
		data = {
			old_level = user_data.lead.level,
			new_level = user_data.lead.level,
		}
	}
	for k = 1, num do
		local levelup_struct = {
			ret = false,
			data = nil,
		}
		local ret = {item_list = {}}
		get_pve_reward(pve_data, ret, user_data, item_list, levelup_struct)
		local levelup_data = nil
		if levelup_struct.ret then
			is_levelup = true
			total_levelup_struct.ret = true
			total_levelup_struct.data.new_level = user_data.lead.level
			local user_name = user_data.user_name
			assert(user_name, "user_name is nil")
			core_power.reflesh_knight_power(user_data, nil, 0, core_power.create_modify_power(rank.modify_power, user_name))
			group_cache.update_user_info(user_data)
		end
		table.insert(get_list, {item_list = ret.item_list, levelup = levelup_struct.data})
	end
	
	local ext_item_list = {}
	local a = {item_list = ext_item_list}
	local stage_conf = pve_data.stage_conf
	local ext_item_id = stage_conf.ADDITIONAL_REWARD[1]
	if ext_item_id ~= 0 then
		local ext_item_num = stage_conf.ADDITIONAL_REWARD[2] * num
		core_user.get_item(ext_item_id, ext_item_num, user_data, 102, nil, item_list, a, nil)
	end
	
	--检测成就
	core_task.check_chengjiu_total_hp(task_struct, user_data)
	core_task.check_chengjiu_total_gold(task_struct, user_data)
	core_task.check_chengjiu_max_gold(task_struct, user_data)
	core_task.check_chengjiu_total_clear(task_struct, user_data, num)
	core_task.check_chengjiu_levelup(task_struct, user_data)
	
	core_task.check_daily_pve(task_struct, user_data, num)
	if is_levelup then
		core_task.reflesh_all_when_levelup(task_struct, user_data, total_levelup_struct)
	end

	local rsync = {
		tili = user_data.tili,
		gold = user_data.gold,
		last_reflesh_tili = user_data.timestamp.last_reflesh_tili,
		exp = user_data.lead.exp,
	}
	local qy_num = 0
	local qiyu_struct = core_user.get_qiyu(user_data)
	local cur_num = core_user.check_qiyu(qiyu_struct.qiyu_list)
	for k = 1, num do
		if cur_num >= 10 then break end
		if do_qiyu(user_data, qiyu_struct) then
			qy_num = qy_num + 1
			cur_num = cur_num + 1
		end
	end
	return get_list, rsync, ext_item_list, num, is_levelup, qy_num
end


function PVE.pve2_reset_core(main_data, knight_list, user_name)
	local pve2 = main_data.PVE.pve2
	local min_level = 20
	local zhanwei = main_data.zhenxing.zhanwei_list
	local pve2_zhanwei = pve2.zhenxing
	local lead = main_data.lead
	for k = 1,7 do
		local t = zhanwei[k].status
		t = pve2_zhanwei[k].guid
		if zhanwei[k].status == 0 then
			pve2_zhanwei[k].guid = -2
		elseif zhanwei[k].status == 1 then
			pve2_zhanwei[k].guid = -1
			lead.pve2_sub_hp = 0
		else
			local knight = zhanwei[k].knight
			assert(knight)
			local data = knight.data
			t = data.pve2_sub_hp
			data.pve2_sub_hp = 0
			if data.level >= min_level then
				pve2_zhanwei[k].guid = knight.guid
			else
				pve2_zhanwei[k].guid = -2
			end
		end
	end
	for k,v in ipairs(knight_list) do
		local data = v.data
		local t = data.pve2_sub_hp
		data.pve2_sub_hp = 0
	end
	local level = main_data.lead.level
	local enemys, dispute_lev = pve2_module.get_tags(level, user_name)
	local enemy_list = {}
	for k,v in ipairs(enemys) do
		local t = {
			username = v,
			type = 0,
		}
		table.insert(enemy_list, t)
	end
	pve2.enemy_list = enemy_list
	pve2.cur_idx = 1
	pve2.dispute_lev = dispute_lev
	rawset(pve2, "optional_buff_list", nil)
	rawset(pve2, "pve2_buff_list", nil)
end

function PVE.pve2_reset(main_data, knight_list, user_name)
	local pve2 = main_data.PVE.pve2
	local min_level = Open_conf[3].OPEN_PARA
	local cur_level = main_data.lead.level
	assert(cur_level >= min_level)
	
	local cur_reset_num = pve2.reset_num
	--local enemy_list = rawget(pve2, "enemy_list")
	--if enemy_list and rawlen(enemy_list) > 0 then
		local max_count = core_vip.pve2_reset(main_data)
		assert(cur_reset_num < max_count)
		pve2.reset_num = cur_reset_num + 1
		--if cur_reset_num > 0 then
		--    pve2.anti_pve2gold = 1
		--else
			pve2.anti_pve2gold = 0
		--end
	--end
	
	PVE.pve2_reset_core(main_data, knight_list, user_name)
	--lock修正
	local t = {}
	for k,v in ipairs(knight_list) do
		if v.data.lock ~= 0 then 
			--print(1, v.guid, v.data.lock)
			table.insert(t, v.guid)
		end
	end
	change_list = robmine.check_knight_lock( main_data, knight_list, t )
	return change_list
end

function PVE.pve2_set_zhenxing(main_data, knight_list, new_zhenxing)
	local min_level = 20
	local change_list = {}
	assert(rawlen(new_zhenxing) == 7, "pve2_set_zhenxing|zhenxing len is not 7")
	local effect_guid = 0
	for _,v in ipairs(new_zhenxing) do
		if v >= -1 then
			effect_guid = effect_guid + 1
			local num = 0
			for _,v1 in ipairs(new_zhenxing) do
				if v == v1 then num = num + 1 end
			end
			assert(num == 1, "pve2_set_zhenxing|guid repeat")
		end
	end
	-- 有效guid必须至少有一个
	assert(effect_guid > 0, "pve2_set_zhenxing|effect guid is 0")
	
	local zhenxing = main_data.PVE.pve2.zhenxing
	--先更新原阵型
	for k,v in ipairs(zhenxing) do
		if v.guid >= 0 then
			local t = core_user.get_knight_by_guid(v.guid, main_data, knight_list)
			assert(t and t[2], "pve2_set_zhenxing|some guid not find")
			t[2].data.lock = t[2].data.lock - 1
			table.insert(change_list, t[2])
		end
	end
	
	for k,v in ipairs(new_zhenxing) do
		if v >= 0 then
			local t = core_user.get_knight_by_guid(v, main_data, knight_list)
			assert(t and t[2], "pve2_set_zhenxing|some guid not find")
			assert(t[2].data.level >= min_level)
			assert(t[2].data.master == 0, "this knight has master")
			assert(t[2].data.pve2_sub_hp ~= -1, "some knight hp is 0")
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
		elseif v == -1 then
			assert(main_data.lead.pve2_sub_hp ~= -1, "lead hp is 0")
		end
		local t = zhenxing[k].guid
		zhenxing[k].guid = v
	end
	return zhenxing, change_list
end

function PVE.pve2_get_enemy(main_data1, main_data2, req, isrobot, knight_list2)
	local pve2 = main_data1.PVE.pve2
	local enemy_list = pve2.enemy_list
	local reqidx = req.index
	local reqname = req.user_name
	local cur_idx = math.floor((reqidx - 1)/ 2) + 1
	local min_knight_level = 20
	
	assert(pve2.cur_idx >= 1 and pve2.cur_idx <= 30, "cur_idx is wrong")
	assert(pve2.cur_idx == reqidx, "idx err")
	local cur_enemy = enemy_list[cur_idx]
	assert(cur_enemy.username == reqname, "enemy name is wrong")
	assert(rawget(cur_enemy, "detail") == nil, "detail info is exist")
	
	assert(cur_idx >= 1 and cur_idx <= 15, "cur_idx err")
	local dispute_conf = Dispute_conf[cur_idx]
	assert(dispute_conf)
	local diff = dispute_conf.DIFF_FACTOR / 100
	
	cur_enemy.nickname = main_data2.nickname
	local zhanwei = {}
	if not isrobot then
		for k,v in ipairs(main_data2.zhenxing.zhanwei_list) do
			if v.status == 2 then
				table.insert(knight_list2, v.knight)
			end
		end
		local t = main_data2.ext_data.max_power.max_power
		local t1 = rawget(main_data2.ext_data, "max_power")
		assert(t1, "has no max_power")
		local zw_list = t1.zhanwei
		t = zw_list[1]
		for k,v in ipairs(zw_list) do
			if v == -2 then
				main_data2.zhenxing.zhanwei_list[k] = {status = 0, power = 0}
			elseif v == -1 then
				main_data2.zhenxing.zhanwei_list[k] = {status = 1, power = 0}
			else
				local t = core_user.get_knight_from_bag_by_guid(v, knight_list2)
				assert(t, main_data2.user_name.." knight not find")
				local tk = t[2]
				if tk.data.level >= min_knight_level then
					main_data2.zhenxing.zhanwei_list[k] = {status = 2, knight = tk, power = 0, jiban_list = {}}
					local t = tk.data.level
					local jiban_list = rawget(tk.data, "jiban_list")
					if jiban_list then
						for k1,v1 in ipairs(jiban_list) do
							if v1 >= 0 then
								local t = core_user.get_knight_from_bag_by_guid(v1, knight_list2)
								assert(t, main_data2.user_name.." knight not find")
								local tk1 = t[2]
								if tk1.data.level >= min_knight_level then
									table.insert(main_data2.zhenxing.zhanwei_list[k].jiban_list, tk1)
								else
									jiban_list[k1] = -1
								end
							end
						end
					end
				else
					main_data2.zhenxing.zhanwei_list[k] = {status = 0, power = 0}
				end
			end
		end
	else
		local dispute_level = pve2.dispute_lev
		local robot_knight_level = 0
		main_data2 = clonetab(main_data2)
		local conf = Dispute_Lay_conf[dispute_level]
		local t = cur_idx
		if t <= conf.LAY_1[3] then
			robot_knight_level = conf.LAY_1[1]
		else
			t = t - conf.LAY_1[3]
		end
		if robot_knight_level == 0 and t <= conf.LAY_2[3] then
			robot_knight_level = conf.LAY_2[1]
		else
			t = t - conf.LAY_2[3]
		end
		if robot_knight_level == 0 and t <= conf.LAY_3[3] then
			robot_knight_level = conf.LAY_3[1]
		else
			t = t - conf.LAY_3[3]
		end
		if robot_knight_level == 0 then
			robot_knight_level = conf.LAY_4[1]
		end
		for k,v in ipairs(main_data2.zhenxing.zhanwei_list) do
			if dispute_level < 23 and (k == 3 or k == 7) then
				main_data2.zhenxing.zhanwei_list[k] = {status = 0, power = 0}
			elseif dispute_level < 30 and k == 3 then
				main_data2.zhenxing.zhanwei_list[k] = {status = 0, power = 0}
			else
				if k == 2 then
					main_data2.lead.level = robot_knight_level
					main_data2.lead.skill.level = robot_knight_level
				else
					v.knight.data.level = robot_knight_level
					v.knight.data.skill.level = robot_knight_level
				end
			end
		end
	end
	local zhanwei1 = main_data2.zhenxing.zhanwei_list
	for k,v in ipairs(zhanwei1) do
		local t = nil
		if v.status == 0 then
			t = {
				status = 0
			}
		elseif v.status == 1 then
			t = {
				status = 1,
				lead = main_data2.lead,
				max_hp = 0,
			}
			local tt = t.lead
			local ttt = tt.exp
			tt.exp = 0
			tt.pve2_sub_hp = 0
		else
			local tt = v.knight.data.level

			t = {
				status = 2,
				knight = v.knight,
				max_hp = 0,
				jiban_list = v.jiban_list
			}
			local tt = t.knight.data
			tt.exp = 0
			tt.gong.type = 0
			tt.pve2_sub_hp = 0
		end
		table.insert(zhanwei, t)
	end
	local ext_info = core_power.get_team_info(main_data2, knight_list2)
	for k,v in ipairs(ext_info) do
		local t = zhanwei[v.idx]
		assert(t.lead or t.knight)
		t.max_hp = math.floor(v.hp * diff)
	end
	local detail = {
		zhanwei_list = zhanwei,
		lover_list = main_data2.lover_list,
		book_list = main_data2.book_list,
		win = 0,
		reputation = main_data2.PVP.reputation,
		wxjy = main_data2.wxjy,
		sevenweapon = sevenweapon
	}
	cur_enemy.detail = detail
	return cur_enemy
end

function PVE.pve2_do_fight(user_data, knight_list, task_struct)
	local pve2 = user_data.PVE.pve2
	local cur_idx = math.floor((pve2.cur_idx - 1) / 2) + 1
	assert(cur_idx >= 1 and cur_idx <= 15, "cur_idx err")
	assert(not rawget(pve2, "optional_buff_list"), "not select buff list")
	local dispute_conf = Dispute_conf[cur_idx]
	assert(dispute_conf)
	local diff = dispute_conf.DIFF_FACTOR / 100
	
	local cur_enemy = pve2.enemy_list[cur_idx]
	local t = cur_enemy.type
	local enemy_detail = rawget(cur_enemy, "detail")
	assert(enemy_detail, "no detail info")
	assert(enemy_detail.win == 0, "you have win this enemy")
	-- 处理自己的userinfo
	local self_zhanwei_list = {}
	local s_pve2_zhanwei_list = pve2.zhenxing
	
	local kn = 0
	for k,v in ipairs(s_pve2_zhanwei_list) do
		local t = nil
		if v.guid == -2 then
			t = {
				status = 0,
			}
		elseif v.guid == -1 then
			if user_data.lead.pve2_sub_hp == -1 then
				t = {
					status = 0,
				}
			else
				t = {
					status = 1
				}
				kn = kn + 1
			end
		else
			local t1 = core_user.get_knight_by_guid(v.guid, user_data, knight_list)
			assert(t1 and t1[2], "some knight not find")
			if t1[2].data.pve2_sub_hp == -1 or t1[2].data.master ~= 0 then
				t = {
					status = 0,
				}
			else
				t = {
					status = 2,
					knight = t1[2]
				}
				kn = kn + 1
			end
		end
		table.insert(self_zhanwei_list, t)
	end
	assert(kn > 0, "all kinght are die")
	local self_info = {
		book_list = user_data.book_list,
		lover_list = user_data.lover_list,
		lead = user_data.lead,
		zhenxing = {
			zhanwei_list = self_zhanwei_list
		},
		PVP = {
			reputation = user_data.PVP.reputation
		},
		wxjy = user_data.wxjy,
		sevenweapon = user_data.sevenweapon,
	}
	-- 处理敌人的userinfo
	local enemy_zhanwei_list = {}
	local e_pve2_zhanwei_list = enemy_detail.zhanwei_list
	local e_lead = nil
	local e_knight_list = {}
	for k,v in ipairs(e_pve2_zhanwei_list) do
		local t = nil
		if v.status == 0 then
			t = {
				status = 0,
			}
		elseif v.status == 1 then
			if v.lead.pve2_sub_hp == -1 then
				t = {
					status = 0,
				}
			else
				t = {
					status = 1
				}
				e_lead = v.lead
			end
		else
			if v.knight.data.pve2_sub_hp == -1 then
				t = {
					status = 0
				}
			else
				t = {
					status = 2,
					knight = v.knight
				}
				for k1,v1 in ipairs(v.jiban_list) do
					table.insert(e_knight_list, v1)
				end
			end
		end
		table.insert(enemy_zhanwei_list, t)
	end
	local enemy_info = {
		book_list = enemy_detail.book_list,
		lover_list = enemy_detail.lover_list,
		lead = e_lead,
		zhenxing = {
			zhanwei_list = enemy_zhanwei_list
		},
		PVP = {
			reputation = enemy_detail.reputation
		},
		wxjy = enemy_detail.wxjy,
	}
	local fight = core_fight:new()
	local rcd = fight.rcd
	local preview = rcd.preview
	fight:get_player_data(self_info, knight_list)
	fight:get_player_data(enemy_info, e_knight_list, true)
	-- 处理buff
	local buff_list = rawget(pve2, "pve2_buff_list")
	local buff_handle = nil
	if buff_list then
		local buff = {1,1,1,0,0,0,0}
		for k,v in ipairs(buff_list) do
			local conf = Disputebuff_conf[v]
			assert(conf)
			local type = conf.BUFF_TYPE
			local value = conf.BUFF_EFF
			if type >= 1 and type <= 3 then
				buff[type] = buff[type] + value / 100
			elseif type >= 4 and type <= 7 then
				buff[type] = buff[type] + value
			end
		end
		buff_handle = function(role)
			for k,v in ipairs(buff) do
				if k == 1 then
					local t = role.att
					role.att = math.floor(role.att * v)
					--print("att buf", t, role.att)
				elseif k == 2 then
					local t = role.hp
					role.hp = math.floor(role.hp * v)
					--print("hp buf", t, role.hp)
				elseif k == 3 then
					local t = role.speed
					role.speed = math.floor(role.speed * v)
					--print("speed buf", t, role.speed)
				elseif k == 4 then
					local t = role.baoji
					role.baoji = role.baoji + v
					--print("baoji buf", t, role.baoji)
				elseif k == 5 then
					local t = role.xiaojian
					role.xiaojian = role.xiaojian + v
					--print("xiaojian buf", t, role.xiaojian)
				elseif k == 6 then
					local t = role.huibi
					role.huibi = role.huibi + v
					--print("huibi buf", t, role.huibi)
				elseif k == 7 then
					local t = role.zhaojia
					role.zhaojia = role.zhaojia + v
					--print("zhaojia buf", t, role.zhaojia)
				end
			end
		end
	end
	for k = 1,7 do
		local role = rawget(fight.posi_list, k)
		if role then role.buff_handle = buff_handle end
	end
	fight:get_attrib()
	-- 处理难度
	for k = 101, 107 do
		local role = rawget(fight.posi_list, k)
		if role then
			role.max_hp = math.floor(role.max_hp * diff)
			role.hp = role.max_hp
			role.att = math.floor(role.att * diff)
			role.def = math.floor(role.def * diff)
			role.speed = math.floor(role.speed * diff)
		end
	end
	
	
	-- 更新hp
	for k,v in ipairs(fight.role_list) do
		local knight = v.knight
		assert(knight)
		local sub_hp = 0
		if v:type_i() == 1 then
			sub_hp = knight.pve2_sub_hp
		elseif v:type_i() == 2 then
			sub_hp = knight.data.pve2_sub_hp
		end
		local now_hp = v.hp - sub_hp
		if sub_hp == -1 then now_hp = 0 end
		assert(now_hp >= 0)
		v.hp = now_hp
	end
	-- 这里必须先获取原始preview，排序之后顺序就乱了
	fight:get_preview_role_list()    
	fight:play(rcd)
	
	local winner = fight.winner
	local hp_list = {-2, -2, -2, -2, -2, -2, -2}
	-- 处理剩余血量
	for k,v in ipairs(fight.role_list) do
		local knight = v.knight
		assert(knight)
		local posi = v.posi
		if posi < 1000 then--援护侠客的站位是1*01；1*02,2*01等
			local sub_hp = 0
			if v.hp == 0 then
				sub_hp = -1
				--主将死了，援护侠客也就死了
				local t_p = 1
				local t_p_idx = posi
				if posi >= 100 then
					t_p = 2
					t_p_idx = posi - 100
				end
				for k1 = 1,2 do
					local jb_posi = t_p * 1000 + t_p_idx * 100 + k1
					local jb_knight = fight.posi_list[jb_posi]
					if jb_knight then
						jb_knight.knight.data.pve2_sub_hp = -1
					end
				end
			else
				sub_hp = v.max_hp - v.hp
				if (winner == 1 and posi < 100) or (winner == 0 and posi > 100) then
					sub_hp = sub_hp - math.floor(v.max_hp * 0.2)
					if sub_hp < 0 then sub_hp = 0 end
				end
			end
			
			if v:type_i() == 1 then
			--    if sub_hp == -1 then sub_hp = v.max_hp - 1 end
				v.knight.pve2_sub_hp = sub_hp
			elseif v:type_i() == 2 then
				v.knight.data.pve2_sub_hp = sub_hp
			end
			if posi < 100 and sub_hp == -1 then
				s_pve2_zhanwei_list[v.posi].guid = -2
			end
			if posi < 100 then
				hp_list[posi] = sub_hp
			end
		end
	end
	--print("idx:"..pve2.cur_idx)
	
	local optional_buff_list = {}
	if winner == 1 then
		--通关清除pve2阵容
		if pve2.cur_idx == 29 then
			--print("init pve2")
			local foundmain = false
			for k,v in ipairs(s_pve2_zhanwei_list) do
				if v.guid > -1 then
					v.guid = -2
				end
				if v.guid == -1 then
					foundmain = true
				end
			end

			if not foundmain then
				s_pve2_zhanwei_list[1].guid = -1
			end
		end
		pve2.cur_idx = pve2.cur_idx + 1
		enemy_detail.win = 1
		local buff_pool = dispute_conf.BUFFPOOL
		if buff_pool[1] ~= 0 then
			local len = rawlen(buff_pool)
			local t = clonetab(buff_pool)
			local l = 0
			while l < 3 do
				local tt = math.random(len)
				table.insert(optional_buff_list, t[tt])
				table.remove(t, tt)
				len = len - 1
				if len == 0 then break end
			end
			pve2.optional_buff_list = optional_buff_list
		end
		core_task.check_daily_fengzheng(task_struct, user_data)
	else
	end

	--lock修正
	local t = {}
	for k,v in ipairs(knight_list) do
		if v.data.lock ~= 0 then 
			--print(1, v.guid, v.data.lock)
			table.insert(t, v.guid)
		end
	end
	change_list = robmine.check_knight_lock( user_data, knight_list, t )
	
	return rcd, optional_buff_list, hp_list, e_pve2_zhanwei_list, change_list
end

function PVE.pve2_get_reward(user_data, item_list, task_struct)
	local pve2 = user_data.PVE.pve2
	local cur_idx = math.floor((pve2.cur_idx - 1)/2) + 1
	local enemy = pve2.enemy_list[cur_idx]
	local t = enemy.type
	local detail = rawget(enemy, "detail")
	assert(detail, "has no detail yet")
	assert(detail.win == 1, "unwin yet")
	local conf = Dispute_conf[cur_idx]
	assert(conf, "conf not find")
	local get_list = {}
	
	local dispute_level = pve2.dispute_lev
	local conf_l = Dispute_Lay_conf[dispute_level]
	local retitem = conf_l.Nor_Box
	if cur_idx == 3 or cur_idx == 6 or cur_idx == 9 or cur_idx == 12 then
		retitem = conf_l.Ell_Box
	elseif cur_idx == 15 then
		retitem = conf_l.End_Box
	end
	core_drop.get_item_list_from_id(retitem, get_list)
	
	local level = user_data.lead.level
	local gold_rate = core_vip.pve2_gold_rate(user_data) / 100
	local gold_num = math.floor((conf.BASECOIN + level * conf.LVCOIN) * gold_rate)
	table.insert(get_list, {191010001, gold_num})
	local medal = conf.RE_MEDAL
	if medal > 0 and pve2.anti_pve2gold ~= 1 then
		table.insert(get_list, {191040212, medal})
	end
	
	local ret = {
		gold = 0,
		pve2_gold = 0,
		item_list = {},
	}
	core_user.get_item_list({main_data = user_data, item_list = item_list}, 
		get_list, {rsync = ret}, 103)
		
	-- 检测成就
	core_task.check_chengjiu_total_gold(task_struct, user_data)
	core_task.check_chengjiu_max_gold(task_struct, user_data)
	ret.gold = user_data.gold
	ret.pve2_gold = user_data.PVE.pve2.pve2_gold
	
	pve2.cur_idx = pve2.cur_idx + 1
	return ret
end

function PVE.pve2_select_buff(user_data, idx)
	local pve2 = user_data.PVE.pve2
	local t = pve2.cur_idx
	local optional_buff_list = rawget(pve2, "optional_buff_list")
	assert(optional_buff_list, "optional buff list not exist")
	local len = rawlen(optional_buff_list)
	assert(idx <= len and idx > 0, "idx err")
	local buff_list = rawget(pve2, "pve2_buff_list")
	if not buff_list then
		buff_list = {}
		rawset(pve2, "pve2_buff_list", buff_list)
	end
	local buff = optional_buff_list[idx]
	table.insert(buff_list, buff)
	rawset(pve2, "optional_buff_list", nil)
	return buff_list
end

function PVE.pve2_reflesh_shop(main_data, item_list, free)
	local rsync = {item_list = {}, cur_money = main_data.money}
	if free ~= 1 then
		local ret = core_user.expend_sxl(1, {main_data = main_data, item_list = item_list}, rsync.item_list, 105)
		if ret == -1 then
			core_money.use_money(20, main_data, 0, 105)
			rsync.cur_money = main_data.money
		end
	end
	local shop_list = nil
	local pve2_info = main_data.PVE.pve2
	local t = pve2_info.pve2_gold
	shop_list = rawget(pve2_info, "shopping_list")
	if free ~= 1 then
		shop_list = core_user.reflesh_shopping_list(100025)
		pve2_info.shopping_list = shop_list
	end

	return shop_list, rsync
end

function PVE.pve2_shopping(user_info, item_list, idx)
	local pve2 = user_info.PVE.pve2
	local gold = pve2.pve2_gold
	local shopping_list = pve2.shopping_list
	local item = rawget(shopping_list, idx)
	assert(item, "item not exist")
	assert(item.num > 0, "item num is 0")
	local cost = item.price * item.num
	
	core_user.expend_item(191040212, cost, user_info, 104)

	local ret_struct = {
		item_list = {},
		cost = cost,
		token = pve2.pve2_gold
	}
	local item_id = item.id
	core_user.get_item(item_id, item.num, user_info, 104, nil, item_list, ret_struct, nil)
	item.num = 0
	return ret_struct
end

function PVE.jingying_reset(stage_id, main_data)
	local t = main_data.PVE.last_update_time
	local jingying = main_data.PVE.jingying
	t = jingying[1].id
	
	local stage_conf = Jing_Stage_conf[stage_id]
	assert(stage_conf, "stage conf not find")
	local fortress_id = stage_conf.BELONGS_FORTRESS
	local fortress_idx = fortress_id % 10000
	local stage_idx = stage_id % 10000
  
	assert(rawlen(jingying) >= fortress_idx, "fortress id not find")
	local fortress = jingying[fortress_idx]
	t = fortress.id
	t = fortress.stage_list[1].id
	assert(rawlen(fortress.stage_list) >= stage_idx, "stage id not find")
	local stage = fortress.stage_list[stage_idx]
	assert(stage.today_pass_num == 3, "today_pass_num not equal 3")
	local max_num = core_vip.jingying_reset(main_data)
	local today_reset_num = stage.today_reset_num
	if today_reset_num == nil then today_reset_num = 0 end
	assert(today_reset_num < max_num, "reset num is max")
	today_reset_num = today_reset_num + 1
	local cost_money = 25
	if today_reset_num > 8 then cost_money = 50 end
	core_money.use_money(cost_money, main_data, 0, 106)
	stage.today_reset_num = today_reset_num
	stage.today_pass_num = 0
	return stage
end

--获取复活所需元宝
local function get_revive_cost(times)
	return times * 10;
end

--更新武林之巅信息
--resp.trial_info = pve.update_trial_info(main_data)
function PVE.update_trial_info(main_data)
	local t = main_data.PVE.trial_info.cur_layer
	local trial_info
	--if main_data.PVE.trial_info
	if not rawget(main_data.PVE, "trial_info") then
		--print("main_data.PVE.trial_info not exists")
		--初始化
		main_data.PVE.trial_info = 
		{
			cur_reset_times = 0,
			state = "UnStart",
			cur_layer = 0,
			history_max_layer = 0,
			need_update = 1
		}
		trial_info = main_data.PVE.trial_info
	else
		trial_info = main_data.PVE.trial_info
		--[[
		print("main_data.PVE.trial_info exists", trial_info)
		for v,k in pairs(trial_info) do
			print(v, "->", k)
		end
		--]]
	end
	--[[
	if rawget(main_data.PVE, "trial_info") then
		print("main_data.PVE.trial_info exists2")
	else
		print("main_data.PVE.trial_info not exists2")
	end
	--]]
	--赋值,最多1次
	trial_info.max_reset_times = 1
	--更新
	if trial_info.need_update ~= 0 then
		trial_info.need_update = 0
		trial_info.cur_reset_times = 0
	end

	return trial_info
end

--重置武林之巅挑战
--resp.trial_info = pve.reset_trial_info(main_data)
function PVE.reset_trial_info(main_data)
	local trial_info = main_data.PVE.trial_info
	assert( trial_info, "trial_info not inited" )
	local cur_reset_times = trial_info.cur_reset_times
	local max_reset_times =  trial_info.max_reset_times
	assert( cur_reset_times < max_reset_times, "cur_reset_times:"..cur_reset_times .."<".."max_reset_times:" .. max_reset_times)
	
	--重置挑战状态
	trial_info.cur_reset_times = cur_reset_times + 1
	trial_info.state = "UnStart"
	trial_info.cur_layer = 0
	trial_info.cur_revive_times = 0
	trial_info.cur_revive_cost = get_revive_cost(1)
	--最多10次
	trial_info.max_revive_times = 10

	return trial_info;
end

--武林之巅战胜至层
function PVE.do_trial_beat(user_data, trial_info, tar_layer)

	--更新当前层数和历史层数,状态
	if tar_layer > trial_info.history_max_layer then 
		trial_info.history_max_layer = tar_layer 
	end
	trial_info.cur_layer = tar_layer
	trial_info.state = "Beated"

	local max_layer = 150
	assert( trial_info.cur_layer <= max_layer, "tar_layer: "..tar_layer.." reach max:"..max_layer )

	if trial_info.history_max_layer > max_layer then
		trial_info.history_max_layer = max_layer
	end
end

--扫荡武林之巅
--resp.reward_sync = pve.do_trial_sweep(main_data, trial_info, item_list.item_list, task_struct)
function PVE.do_trial_sweep(user_data, trial_info, item_list, task_struct)
	
	local cur_layer = trial_info.cur_layer
	local history_max_layer = trial_info.history_max_layer
	assert( trial_info.state ~= "Failed", "trial state is failed need revive." )
	
	assert( history_max_layer > 0, history_max_layer .. "history_max_layer <= 0" )
	local stage_id, trial_conf
	local reward_list = {}
	local reward_sync = {
		item_list = {}
	}
	if cur_layer == history_max_layer then 
		reward_sync.syncgold = user_data.gold
		return reward_sync
	end

	local trial_conf
	for cur_layer = cur_layer + 1, history_max_layer do
		trial_conf = Trial_conf[cur_layer]
		assert(trial_conf, "trial_conf not found cur_layer:".. cur_layer)
		stage_id = trial_conf.Stage
		get_pve_reward_list(stage_id, reward_list)
	end
	
	--把奖励添加到用户数据中
	local user_struct = {main_data = user_data, item_list = item_list}
	local ret_list = {rsync = reward_sync, levelup_struct = nil}
	core_user.get_item_list(user_struct, reward_list, ret_list, 123)
	
	--更新层数至历史最高层
	PVE.do_trial_beat(user_data, trial_info, history_max_layer)
	
	--更新成就
	core_task.check_chengjiu_total_gold(task_struct, user_data)
	core_task.check_chengjiu_max_gold(task_struct, user_data)

	reward_sync.syncgold = user_data.gold
	
	return reward_sync
end

--武林之巅复活
--resp.cost_yb = pve.do_trial_reveive(main_data, trial_info, task_struct)
function PVE.do_trial_revive(user_data, trial_info, task_struct)
	
	--[[
	local cur_revive_times = trial_info.cur_revive_times;
	local max_revive_times =  trial_info.max_revive_times;
	assert( cur_revive_times < max_revive_times, cur_revive_times .."<".. max_revive_times)
	--复活次数加1
	cur_revive_times = cur_revive_times + 1;
	--消耗元宝
	local cost_yb = trial_info.cur_revive_cost
	core_money.use_money(cost_yb, user_data, 0, 121)
	--更新复活次数和消耗
	trial_info.cur_revive_times = cur_revive_times
	trial_info.cur_revive_cost = get_revive_cost(cur_revive_times+1)
	--改变状态
	trial_info.state = "Beated"
	return cost_yb
	--]]
	local cur_revive_times = trial_info.cur_revive_times;
	cur_revive_times = cur_revive_times + 1;
	trial_info.cur_revive_times = cur_revive_times
	--改变状态
	trial_info.state = "Beated"
	return 0
end

--resp.fight_rcd, resp.reward_sync = pve.do_trial_fight(tar_layer, main_data, trial_info, item_list.item_list, task_struct)
function PVE.do_trial_fight(tar_layer, user_data, knight_list, trial_info, bag_item_list, task_struct)
	--for log
	
	local trial_data = {
		tar_layer = tar_layer;
		trial_conf = nil,
		stage_id = 0,
		stage_conf = nil,
	}

	--之前处理
	local fight = core_fight:new()
	local rcd = fight.rcd
	local preview = rcd.preview
	preview.winner = 0

	pre_pve_trial(trial_data, user_data, fight)

	local stage_conf = trial_data.stage_conf
	--if pve_data.do_event then
	--    fight:get_player_data(user_data, false, p1_hook_creator(pve_data.stage_id))
	--else
	fight:get_player_data(user_data, knight_list, false)
	--end
	fight:get_attrib()
	-- 这里必须先获取原始preview，排序之后顺序就乱了
	fight:get_preview_role_list()
	fight:play(rcd)
	local winner = fight.winner

	-- 返回奖励
	local reward_sync = {
		item_list = {}
	}

	--胜利
	if winner == 1 then

		get_pve_reward(trial_data, reward_sync, user_data, bag_item_list, nil, 122)

		core_task.check_chengjiu_total_gold(task_struct, user_data)
		core_task.check_chengjiu_max_gold(task_struct, user_data)

		PVE.do_trial_beat(user_data, trial_info, tar_layer)
		LOG_STAT( string.format( "%s|%s|%d", "PASS_WL", user_data.user_name, tar_layer ) )
	else
		--更新状态为失败
		trial_info.state = "Failed"
		--LOG_STAT( string.format( "%s|%s|%d", "UNPASS_WL", user_data.user_name, layer ) )
	end

	reward_sync.syncgold = user_data.gold
	
	return rcd, reward_sync
end

local function pre_special_stage(pve_data, main_data)
	local stage_id = pve_data.stage_id
	local idx = stage_id % 10000
	assert(main_data.ext_data.switch[idx] == 1, "stage cannot play today")
	local type = math.floor(stage_id / 10000) % 1000
	assert(type == 888, "stage_id err")
	local stage_conf = Stage_conf[stage_id]
	assert(stage_conf, "stage conf not find")
	pve_data.stage_conf = stage_conf
	
	local pve = main_data.PVE
	local cur_stage_data = pve.special_stage[idx]
	assert(cur_stage_data)
	assert(cur_stage_data.today_pass_num < 2)
	local level = main_data.lead.level
	local level_limit = 0
	if idx == 1 then
		level_limit = Open_conf[25].OPEN_PARA
	elseif idx == 2 then
		level_limit = Open_conf[26].OPEN_PARA
	else
		level_limit = Open_conf[27].OPEN_PARA
	end
	assert(level >= level_limit)
	pve_data.stage_data = cur_stage_data
end

function PVE.special_stage(stage_id, main_data, knight_list, item_list)
	local pve_data = {
		stage_id = stage_id,           -- 关卡id
		difficulty = 1,    -- 难度
		stage_conf = nil,           -- 关卡配置
		stage_data = nil,           -- 玩家的关卡数据，方便事后修改
	}
	local pve = main_data.PVE
	pre_special_stage(pve_data, main_data)
	
	local fight = core_fight:new()
	local rcd = fight.rcd
	local preview = rcd.preview
	preview.winner = 0
	get_environment_data(pve_data, fight)
	--特殊设置
	fight.always_win = true
	fight.round_limit = 3
	fight:get_player_data(main_data, knight_list, false)
	fight:get_attrib()
	-- 这里必须先获取原始preview，排序之后顺序就乱了
	fight:get_preview_role_list()
	fight:play(rcd)
	local winner = fight.winner
	
	local hurt = fight.hurt[1]
	local reward_conf = nil
	for k,v in ipairs(PVE_Damage_Reward_conf.index) do
		if hurt >= v then reward_conf = PVE_Damage_Reward_conf[v]
		else break end
	end
	local gold = 0
	local iron = 0
	local dan = 0
	if stage_id == 58880001 then -- 打钱
		gold = hurt + reward_conf.MONEY
	elseif stage_id == 58880002 then
		iron = reward_conf.IRON
	else
		dan = reward_conf.DAN
	end
	local stage_data = pve_data.stage_data
	stage_data.pass_num = stage_data.pass_num + 1
	stage_data.today_pass_num = stage_data.today_pass_num + 1
	
	-- 获取奖励
	local rsync = {
		cur_gold = main_data.gold,
		item_list = {},
	}

	if gold > 0 then
		core_user.add_gold(gold, {main_data = main_data}, rsync, 105)
		rsync.cur_gold = main_data.gold
	end
	if iron > 0 then
		core_user.add_xuantie(iron, {main_data = main_data, item_list = item_list}, rsync, 106)
	end
	if dan > 0 then
		core_user.add_renshen(dan, {main_data = main_data, item_list = item_list}, rsync, 107)
	end

	return rcd, rsync, hurt, stage_data
end


local function pre_haoxia_pve(pve_data, main_data)
	local stage_id = pve_data.stage_id
	local idx = stage_id % 10000
	local max_fight_num = 2
	if main_data.vip_lev >= 5 then
		max_fight_num = 3
	end
	local t = main_data.PVE.haoxiainfo 
	if not rawget(main_data.PVE, "haoxiainfo") then
		rawset(main_data.PVE, "haoxiainfo", {fightnum = 0, max_stage = 57770001})
	end
	local type = math.floor(stage_id / 10000) % 1000
	assert(type == 777, "stage_id err")
	--print(stage_id.." "..main_data.PVE.haoxiainfo.max_stage)
	assert(stage_id <= main_data.PVE.haoxiainfo.max_stage, stage_id.." "..main_data.PVE.haoxiainfo.max_stage)
	assert(max_fight_num > main_data.PVE.haoxiainfo.fightnum)
	local stage_conf = Stage_conf[stage_id]
	assert(stage_conf, "stage conf not find")
	pve_data.stage_conf = stage_conf
	
	local pve = main_data.PVE
	local level = main_data.lead.level
	assert(level >= 35)
	pve_data.stage_data = {
		pass_num = 0,
		today_pass_num = 0,
		today_reset_num = 0,
		id = 0,
	}

	return max_fight_num
end

function PVE.haoxia_pve(stage_id, main_data, knight_list, item_list)
	local pve_data = {
		stage_id = stage_id,           -- 关卡id
		difficulty = 1,    -- 难度
		stage_conf = nil,           -- 关卡配置
		stage_data = nil,           -- 玩家的关卡数据，方便事后修改
	}
	local max_fight_num = pre_haoxia_pve(pve_data, main_data)
	
	local fight = core_fight:new()
	local rcd = fight.rcd
	local preview = rcd.preview
	preview.winner = 0
	get_environment_data(pve_data, fight)
	
	fight:get_player_data(main_data, knight_list, false)
	fight:get_attrib()
	-- 这里必须先获取原始preview，排序之后顺序就乱了
	fight:get_preview_role_list()
	fight:play(rcd)
	local winner = fight.winner
	local haoxiainfo = main_data.PVE.haoxiainfo
	local reward_conf = nil
	
	-- 获取奖励
	local rsync = {
		cur_gold = main_data.gold,
		item_list = {},
	}

	haoxiainfo.fightnum = haoxiainfo.fightnum + 1
	if winner == 1 then
		if haoxiainfo.max_stage == stage_id then
			haoxiainfo.max_stage = stage_id + 1
		end
		local conf = Hero_Story_Reward_conf[stage_id]
		assert(conf)
		--开池子
		local poolid = conf.Reward_Pool
		--print("poolid|", poolid)

		local list = {}
		core_drop.get_item_list_from_id(poolid, list, false)
		
		for k,v in ipairs(list) do
			--print("open|", v[1], v[2])
			core_user.get_item(v[1], v[2], main_data, 906, nil, item_list, rsync)
		end
	end  

	local found = false
	local flag = max_fight_num - haoxiainfo.fightnum
	local t = main_data.ext_data.huodong.hongdian_list
	if rawget(main_data.ext_data.huodong,"hongdian_list") then
		for k,v in ipairs(main_data.ext_data.huodong.hongdian_list) do
			if v.act_id == 10001 then
				found = true
				--print("set|" ..main_data.user_name .." hongdian ".. flag)
				v.flag = flag
				break
			end
		end
	end

	if not found then
		t = {act_id = 10001, flag = flag}
		--print("cre|" ..main_data.user_name .." hongdian ".. flag)
		if not rawget(main_data.ext_data.huodong,"hongdian_list") then 
			main_data.ext_data.huodong.hongdian_list = {} 
		end
		table.insert(main_data.ext_data.huodong.hongdian_list, t)
	end
	rsync.cur_gold = main_data.gold
	rsync.cur_money = main_data.money
	rsync.cur_tili = main_data.tili

	return rcd, rsync, haoxiainfo, max_fight_num
end

return PVE