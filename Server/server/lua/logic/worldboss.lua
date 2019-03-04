local core_fight = require "fight"
local Monster = require "fight_monster"
local core_user = require "core_user_funcs"
local core_mail = require "core_send_mail"
local pb = require "protobuf"

local tinsert = table.insert

local worldboss = {}

--世界BOSS等级限制
local wboss_level_limit = 25

--获取当前BOSS信息
local function get_cur_boss_info()
	local wboss_info = {
		head_info = {
			boss_season = 1,
			boss_id = 0,
			boss_generations = 1,
		},
		attr_info = {
			cur_hp = 1000000,
			max_hp = 3000000,
		},
		is_alive = 1,
		reward_calc_time = os.time() + 86400 - 4 *3600,
		attack_start_time = os.time() + 1 *3600,
		attack_end_time = os.time() + 4 *3600,
		next_boss_time = os.time() + 86400,
	}
	local wboss_info_buf = wboss_get_cur_boss()
	if wboss_info_buf then
		local ret = pb.decode("WorldBossInfo", wboss_info_buf)
		if ret then
			wboss_info = ret
		end
	end
	return wboss_info
end

--获取BOSS伤害排行
local function get_boss_rank(username, boss_head)
	--RankItemList
	local pb = require "protobuf" 
	local rank_list = {
		rankstart = 0,		--从哪里开始
		rankcount = 10,		--需要多少个
		taruser = username, --目标账号
		taruserrank = 0
	}

	local rank_list_buf = pb.encode("RankItemList", rank_list)
	local n_rank_list_buf = nil

	if boss_head then
	   --printtab(boss_head, "boss head")
		local boss_head_buf = pb.encode("WBossHeadInfo", boss_head)
		n_rank_list_buf = wboss_get_boss_rank(boss_head_buf, rank_list_buf)
	else
	   --print("no boss head")
	   n_rank_list_buf = wboss_get_cur_boss_rank(rank_list_buf)
	end

	if n_rank_list_buf then
		local ret = pb.decode("RankItemList", n_rank_list_buf)
		if ret then
			rank_list = ret
		end
	end
	--local wboss_rank_list_buf = wboss_mod.get_cur_rank_list(username)
	--pb.decode("RankItemList", rank_list)
	return rank_list
end

--获取当前BOSS伤害排行
local function get_cur_boss_rank(username)
	return get_boss_rank(username, nil)
end

--攻击BOSS伤害排行
local function attack_boss(attack_info)
	local attack_ret = {
		ret = 0,	--返回结果，<0表示出错，>=0表示剩余血量
		is_terminated = false
	}
	local attack_info_buf = pb.encode("WBossAttackInfo", attack_info)
	local ret, is_terminated = wboss_attack_boss(attack_info_buf)
	if not ret then
		return nil
	end
	attack_ret.ret = ret
	attack_ret.is_terminated = is_terminated
	return attack_ret
end

function worldboss.get_userinfo(main_data, mail_list)
	
	local ret = {
		user_wboss = {},	--玩家BOSS信息
		wboss_info = {},	--世界BOSS相关的信息
		rank_list = {},		--排行
	}
	--更新信息
	ret.user_wboss, ret.wboss_info = worldboss.update_user_info(main_data, mail_list)
	
	--返回成功
	if ret.user_wboss and ret.wboss_info then 
		ret.rank_list = worldboss.get_rank(main_data, ret.wboss_info.head_info)
	end

	return ret;
end

--获取排名奖励列表
function worldboss.get_rank_reward_list(boss_head)
	
	if not boss_head then
		--当前BOSS
		local wboss_info = get_cur_boss_info()
		boss_head = wboss_info.head_info
	end
	local tar_boss_index = boss_head.boss_generations

	local reward_table = {
	
	}
	
	for k,v in ipairs(GBoss_Rank_conf) do
		local reward_conf = v
		local boss_index = reward_conf.Boss_Index
		if boss_index == tar_boss_index then
			local reward = {
				boss_index = boss_index,
				rank = reward_conf.Rank,
				reward_item = reward_conf.Reward_Item,
				reward_yb = reward_conf.Reward_Gold,
			}
			tinsert(reward_table, reward)
		end
	end
	
	--printtab(reward_table, "reward_table")

	local reward_list = { 
		
	}

	local last_rank = 0
	for k,v in ipairs(reward_table) do
		local reward = v
		local rank_reward_item = {
				idx = k,
				from = last_rank + 1,
				to = reward.rank,
				item_list = {},
			}
		if reward.reward_item and #reward.reward_item >= 2 then
			for i = 1, #reward.reward_item, 2  do
				tinsert(rank_reward_item.item_list, {id = reward.reward_item[i], num = reward.reward_item[i+1]})
			end
		end

		tinsert(rank_reward_item.item_list, {id = refid["fake_yb"], num = reward.reward_yb})
		last_rank = reward.rank
		tinsert(reward_list, rank_reward_item)
	end
	--printtab(reward_list, "reward_list")
	return reward_list
end


--更新用户的世界BOSS信息,返回wboss用户的BOSS信息，boss_info当前BOSS的信息
function worldboss.update_user_info(main_data, mail_list)
	--世界BOSS等级限制
	if main_data.lead.level < wboss_level_limit then return end

	local t = main_data.wboss.need_update
	local wboss = {}
	if not rawget(main_data, "wboss") then
		--print("main_data.wboss not exists")
		--初始化
		main_data.wboss = 
		{
			cur_attack_times  = 0,		--当前挑战次数
			dmg_info = {
				boss_head = {},	--BOSS首要信息
				reward_calc_time = 0,
			},				--伤害信息
			terminate_boss_times = 0,	--终结BOSS次数
			need_update = 1				--是否需要更新
		}
		wboss = main_data.wboss
	else
		wboss = main_data.wboss
		--[[
		print("main_data.wboss exists", wboss)
		for v,k in pairs(wboss) do
			print(v, "->", k)
		end
		--]]
	end
	--[[
	if rawget(main_data, "wboss") then
		print("main_data.wboss exists2")
	else
		print("main_data.wboss not exists2")
	end
	--]]
	--赋值,最大挑战次数
	wboss.max_attack_times = 3

	--当前时间
	local now_time = os.time()
	--伤害信息
	local dmg_info = wboss.dmg_info
	--BOSS首要信息
	local boss_head = dmg_info.boss_head
	--当前BOSS信息
	local wboss_info = get_cur_boss_info()
	--当前BOSS的出生季
	local cur_boss_head = wboss_info.head_info
	--是否需要结算奖励
	local reward_time = dmg_info.reward_calc_time
	local season = boss_head.boss_season
	--print("username", main_data.user_name)
	--print("mail_list", mail_list)
	--printtab(wboss_info, "wboss_info")
	--printtab(dmg_info, "dmg_info")
	--获得结算奖励条件，存在奖励时间且奖励时间》0，且满足奖励时间，且伤害值大于0
	if season and reward_time and mail_list and dmg_info.cur_season_damage 
		and dmg_info.cur_season_damage > 0 and reward_time > 0 and reward_time < now_time then
		--结算奖励
		repeat --方便退出
		--先获取排名
		--totalranksize 
		local rank_list = get_boss_rank(main_data.user_name, boss_head)
		if not rawget(rank_list, "totalranksize") or rank_list.totalranksize == 0 then
			break
		end
		if not rawget(rank_list, "taruserrank") or rank_list.taruserrank == 0 then
			break
		end
		local rank = rank_list.taruserrank
		if rank < 0 then --调整排名
			rank = -rank + 1
		end

		--按排名获取奖励
		local item_list = {}
		local reward_list = worldboss.get_rank_reward_list(boss_head)
		local found_reward = false
		for k,v in ipairs(reward_list) do
			local rank_item = v
			if rank >= rank_item.from and rank <= rank_item.to then
				found_reward = true
				item_list = rank_item.item_list
				break
			end
		end
		--没有找到奖励项
		if not found_reward then
			break
		end
		--发送奖励邮件
		local text = nil
		if rank <= 500 then
			text = string.format(lang.wboss_rank_reward_mail_msg, rank)
		else
			text = lang.wboss_rank_reward_mail_msg_2
		end
		local mail = {
			type = 10,
			from = lang.jinjiuling,
			subject = lang.wboss_rank_reward_mail_subject,
			message = text,
			item_list = item_list,
			stamp = os.time(),
			guid = 0,
			expiry_stamp = 0,
		}
		--print("send wboss reward mail rank:", rank)
		
		core_mail.send_mail(main_data, mail_list, mail)
		
		until(true)
		dmg_info.reward_calc_time = 0
	end
	
	--更新
	if season == nil or season ~= cur_boss_head.boss_season then
		--更新下次结算时间
		dmg_info.reward_calc_time = wboss_info.reward_calc_time
		--排名重置
		dmg_info.cur_season_rank = 0
		--本集伤害重置
		dmg_info.cur_season_damage = 0
		--上次伤害重置
		dmg_info.last_attack_damage = 0
		--挑战次数重置
		wboss.cur_attack_times = 0
	end

	--更新BOSS首要信息
	clonetab_real(boss_head, cur_boss_head)
	return wboss, wboss_info
end

local function pre_attack_boss(wboss_data, main_data, fight_core)

	local stage_id = wboss_data.stage_id
	local stage_conf = Stage_conf[stage_id]
	assert(stage_conf, "stage conf not find stage_id:" .. stage_id)
 
	local boss_generations = wboss_data.boss_generations
	local boss_conf = GBoss_conf[boss_generations]
	wboss_data.boss_conf = boss_conf

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

--攻击BOSS
function worldboss.attack_boss(boss_head, main_data, knight_list, item_list, task_struct)

	--世界BOSS等级限制
	assert(main_data.lead.level >= wboss_level_limit, 
		"main_data.lead.level:" .. main_data.lead.level .. " < wboss_level_limit:" ..wboss_level_limit)

	local ret = {
		attack_result = 0,		--挑战结果
		user_wboss = {},	--玩家BOSS信息
		attr_info = {}, 	--BOSS属性信息
		fight_rcd = {
			preview = {
				winner = 0
			}
		},		--战斗录像
		attack_damage = 0,	--本次进攻伤害
		is_terminated = 0,	--是否被你终结
		rsync = {
			item_list = {}, --物品列表 
		},	        --待同步的数据，奖励与消耗，包含终结奖励，显示请读term_info中的信息
		term_info = {}		--BOSS终结信息，如果BOSS的话
	}


	--更新信息,忽略邮件
	local user_wboss, wboss_info = worldboss.update_user_info(main_data)

	--限制挑战次数
	----[[
	assert(user_wboss.cur_attack_times < user_wboss.max_attack_times, 
		string.format("user_wboss.cur_attack_times:%d >= user_wboss.max_attack_times:%d", 
		user_wboss.cur_attack_times, user_wboss.max_attack_times))
	----]]
	--世界BOSS信息
	assert(wboss_info.head_info.boss_season == boss_head.boss_season, 
		string.format("wboss_info.head_info.boss_season:%d ~= boss_head.boss_season:%d",
		wboss_info.head_info.boss_season, boss_head.boss_season))

	if (not wboss_info.is_alive) or wboss_info.is_alive == 0 then
		ret.attack_result = -2
		return ret
	end

	local wboss_data = {
		boss_generations = wboss_info.head_info.boss_generations,
		stage_id = wboss_info.head_info.boss_id,
		boss_conf = {},
		stage_conf = {},
	}

	--之前处理
	local fight = core_fight:new()
	local rcd = fight.rcd
	local preview = rcd.preview
	preview.winner = 0

	pre_attack_boss(wboss_data, main_data, fight)

	local stage_conf = wboss_data.stage_conf
   
	fight:get_player_data(main_data, knight_list, false)
	--end
	fight:get_attrib()
	--设置血量
	--解到包cur_hp
	local t = wboss_info.attr_info.cur_hp
	local attr_info = wboss_info.attr_info
	for k,v in ipairs(fight.role_list) do
		if v.posi > 100 and v.type == "BOSS" then
			v.hp = attr_info.cur_hp
			v.max_hp = attr_info.max_hp
			break
		end
	end
		
	-- 这里必须先获取原始preview，排序之后顺序就乱了
	fight:get_preview_role_list()
	fight:play(rcd)
	

	--对BOSS进行伤害计算
	
	--实际伤害
	local attack_damage = rcd.preview.stat_info.total_damage[1]
	
	local username = main_data.user_name
	local dmg_info = user_wboss.dmg_info
	--总伤害
	local total_damage = dmg_info.cur_season_damage + attack_damage
	local attack_info = {
		user_name = username,				--用户名，用户ID
		nick_name = main_data.nickname,		--昵称
		level = main_data.lead.level,		--等级
		viplv = main_data.vip_lev,			--VIP等级
		power = main_data.ext_data.max_power.max_power,	--战斗力

		damage = attack_damage,						--造成伤害
		total_damage = total_damage,	--总伤害
		time = os.time()							--挑战时间
	}
	local attack_ret = attack_boss(attack_info)
	assert(attack_ret, "attack_boss failed")
	if attack_ret.ret < 0 then --出错
		ret.attack_result = attack_ret.ret
		return ret
	end
	dmg_info.last_attack_damage = attack_damage
	dmg_info.cur_season_damage = total_damage

	--返回结果
	ret.fight_rcd = rcd
	ret.attack_damage = attack_damage
	--增加攻打次数
	user_wboss.cur_attack_times = user_wboss.cur_attack_times + 1

	--同步BOSS血量
	
	attr_info.cur_hp = attack_ret.ret
	ret.attr_info = attr_info
	--被终结了 发放奖励
	if attack_ret.is_terminated then

		--胜利
		preview.winner = 1
		user_wboss.terminate_boss_times = user_wboss.terminate_boss_times + 1
		local kill_reward_arr = wboss_data.boss_conf.Kill_Reward
		local reward_list = get_reward_item_list(kill_reward_arr)
		local mail_item_list = {}
		local mail = {
			type = 10,
			lev_limit = wboss_level_limit, --等级限制25级
			from = lang.jinjiuling,
			subject = lang.wboss_rank_reward_mail_subject_2,
			message = lang.wboss_rank_reward_mail_msg_3,
			item_list = reward_list,
			stamp = os.time(),
			guid = 0,
			expiry_stamp = os.time() + 86400 * 7,
		}
		--添加全服邮件
		svr_info.add_gmail(mail)
		--[[
		local where = 123
		core_user.get_reward_list(main_data, item_list, reward_list, ret.rsync, where)
		--]]
		ret.is_terminated = 1
		ret.term_info.user_name = username
		ret.term_info.nick_name = main_data.nickname
		ret.term_info.item_list = ret.rsync.item_list
		--LOG_STAT( string.format( "%s|%s|%d", "PASS_WL", username, tar_layer ) )
	end

	ret.user_wboss = user_wboss

	--local boss_head_buf = pb.decode("WBossHeadInfo", boss_head)
	--local is_effect, is_terminate = wboss_mod.attack_boss(username, boss_head, attack_damage)
	ret.rank_list, ret.last_rank = worldboss.get_rank(main_data, boss_head)
	return ret
end

--获取排行
function worldboss.get_rank(main_data, boss_head)
	local rank_list = {}
	--local wboss_rank_list_buf = wboss_mod.get_cur_rank_list(username)
	--pb.encode("RankItemList", rank_list)
	rank_list = get_cur_boss_rank(main_data.user_name)
	assert(rank_list, "get_cur_boss_rank failed")
	--local t = rank_list.totalranksize
	if not rawget(rank_list, "totalranksize") or rank_list.totalranksize == 0 then
		return rank_list
	end
	if not rawget(rank_list, "taruserrank") or rank_list.taruserrank == 0 then
		return rank_list
	end
	local last_rank = 0
	if rank_list.taruserrank then
		local user_wboss = main_data.wboss
		local dmg_info = user_wboss.dmg_info
		last_rank = dmg_info.cur_season_rank
		local head_info = dmg_info.boss_head

		if head_info.boss_season == boss_head.boss_season and rank_list.taruserrank ~= 0 then
			dmg_info.cur_season_rank = rank_list.taruserrank
		end

		--[[
		print(string.format("head_info.boss_season:%d, boss_head.boss_season:%d, taruserrank:%d",
				head_info.boss_season, boss_head.boss_season, rank_list.taruserrank))
		--]]
	end
	--print(last_rank)
	return rank_list, last_rank

end

return worldboss