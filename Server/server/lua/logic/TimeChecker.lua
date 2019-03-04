

local function get_dayid_from(time, hour, minute)
	local t = time --+ 28800 --+8时区
	local d = math.floor(t / 86400)
	local h = math.floor((t % 86400) / 3600)
	local m = nil
	if minute then
		m = math.floor((t % 3600) / 60)
	end
	
	local dayid = d
	if hour then
		if h < hour then
			dayid = d - 1
		elseif minute and h == hour then
			if m < minute then dayid = d - 1 end
		end
	end
	return dayid
end

local function update_at_0am(userInfo, dayid, user_sync)
	local user_info = userInfo:getUserInfo()
	if user_info.timestamp.last_0am_day == dayid then
		return false
	end
	user_info.timestamp.last_0am_day = dayid

	user_info.timestamp.today_online_time = 0

	user_sync = user_sync or {}
	user_sync.user_info = user_sync.user_info or {}

	user_sync.user_info.timestamp = user_info.timestamp

	--重置体力值
	userInfo:addStrengthByTime(999999)
	user_sync.user_info.strength = user_info.strength
	--重置每日体力购买次数
	user_info.strength_buy_times = 0
	user_sync.user_info.strength_buy_times = user_info.strength_buy_times
		
	--重置试炼信息次数
	local trial_data = userInfo:getTrialData()
	if user_info.trial_data then

		if user_info.trial_data.ticket_num < GolbalDefine.trial_init_ticket_num then

			user_info.trial_data.ticket_num = GolbalDefine.trial_init_ticket_num
		end
	end
	user_sync.user_info.trial_data = user_info.trial_data

	--重置竞技场次数
	local arena_data = userInfo:getArenaData()
	if user_info.arena_data then
		if user_info.arena_data.challenge_times < GolbalDefine.arena_init_challenge_times then

			user_info.arena_data.challenge_times = GolbalDefine.arena_init_challenge_times
		end
		user_info.arena_data.purchased_challenge_times = 0

		user_info.arena_data.daily_reward = 0
		user_info.arena_data.already_challenge_times = 0
		user_info.arena_data.win_challenge_times = 0

	end
	user_sync.user_info.arena_data = user_info.arena_data

	--重置每日数据
	user_info.daily_data = {ship_levelup_count = 0}
	user_sync.user_info.daily_data = user_info.daily_data

	local planet_user = PlanetCache.getUser(user_info.user_name)
	if planet_user then
		planet_user.attack_monster_times = nil
		planet_user.base_attack_times = nil
		planet_user.colloct_level_times_list_day = nil
		planet_user.ruins_level_times_list_day = nil
		planet_user.fishing_level_times_list_day = nil
		planet_user.boss_level_times_list_day = nil
		PlanetCache.saveUserData(planet_user)
	end

	--重置奴隶数据

	local slave_data = SlaveCache.get(user_info.user_name)

	local default_slave_enslave_num = CONF.PARAM.get("slave_enslave_num").PARAM

	if slave_data.get_slaves_times < default_slave_enslave_num then
		slave_data.get_slaves_times = default_slave_enslave_num
	end
	slave_data.buy_get_slaves_times = 0

	local default_slave_save_num = CONF.PARAM.get("slave_save_num").PARAM

	if slave_data.get_save_times < default_slave_save_num then
		slave_data.get_save_times = default_slave_save_num
	end

	slave_data.buy_get_save_times = 0
	SlaveCache.set(slave_data)


	--重置每日任务
	userInfo:resetDailyTask()
	user_sync.user_info.task_list = user_info.task_list

	--重置每日商城数据
	userInfo:resetShopData()
	user_sync.user_info.shop_data = user_info.shop_data

	--重置每日抽奖数据
	userInfo:resetShipLotteryData()
	user_sync.user_info.ship_lottery_data = user_info.ship_lottery_data

	--重置部分活动数据
	userInfo:resetActivityData()
	user_sync.user_info.activity_list = user_info.activity_list

	--登陆天数增加
	local achievement_data = userInfo:getAchievementData()
	if achievement_data.sign_in_days == nil then
		achievement_data.sign_in_days = 1
	else
		achievement_data.sign_in_days = achievement_data.sign_in_days + 1
	end
	user_sync.user_info.achievement_data = user_info.achievement_data

	--更新活动数据
	user_sync.activity_list = user_sync.activity_list or {}
	local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
	if activity_list then
		for i,v in ipairs(activity_list) do
			local count = v.seven_days_data.sign_in_days or 0
			v.seven_days_data.sign_in_days = count + 1
			table.insert(user_sync.activity_list, v)
		end
	end


	
	if Tools.isEmpty(user_info.group_data) == false then
		--重置公会PVE数据
		if user_info.group_data ~= nil or user_info.group_data ~= "" then
			user_info.group_data.pve_checkpoint_list = nil
		end
		--重置帮助次数
		user_info.group_data.help_times = 0
		user_info.group_data.today_worship_level = 0
		user_info.group_data.getted_worship_reward = nil
		user_sync.user_info.group_data = user_info.group_data
	end

	--领取每日卡奖励

	if user_info.timestamp.card_end_time ~= 0 and user_info.timestamp.card_end_time ~= nil then
		if user_info.timestamp.card_end_time < os.time() then
			user_info.timestamp.card_end_time = 0
		else
			local curConf
			local id_list = CONF.RECHARGE.getIDList()
			for _,id in ipairs(id_list) do
				local conf = CONF.RECHARGE.get(id)
				if string.sub(conf.PRODUCT_ID,1,4) == "card" then
					curConf = conf
					break
				end
			end
			if curConf then
				user_info.money = user_info.money + curConf["PRESENT_"..server_platform]
			end
		end
		
	end

	--重置好友体力
	if user_info.friends_data then
		local friends = {
			friends_list = user_info.friends_data.friends_list,
			black_list = user_info.friends_data.black_list,
			talk_list = user_info.friends_data.talk_list,
			friends_familiarity = user_info.friends_data.friends_familiarity,
		}
		user_info.friends_data = friends
		user_sync.user_info.friends_data = friends
	end

	userInfo:setUserInfo(user_info)

	return true
end

local function update_time_stamp(user_info, item_list, mail_list, user_sync)
	--处理全服邮件
	local gmail_list = svr_info.get_gmail_list()
	local t = user_info.timestamp.gmail or 0
	local max_gmail = 0
	for k,v in ipairs(gmail_list) do
		if t < v.tid then
			if max_gmail < v.tid then 
				max_gmail = v.tid
			end
			if (v.reg_time and v.reg_time ~= 0 and user_info.timestamp.regist_time > v.reg_time) 
			or (v.vip_limit and v.vip_limit ~= 0 and user_info.vip_level < v.vip_limit) 
			or (v.lev_limit and v.lev_limit ~= 0 and user_info.level < v.lev_limit) then

			else
				CoreMail.recvMail(v, mail_list)
			end
		end
	end
	if t < max_gmail then
		user_info.timestamp.gmail = max_gmail
	end
end


local timechecker = {
	get_dayid_from = get_dayid_from,
	update_at_0am = update_at_0am,
	update_time_stamp = update_time_stamp,
}

return timechecker