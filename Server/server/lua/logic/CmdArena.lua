

function arena_info_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ArenaInfoResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.save, user_name
	else
		error("something error");
	end
end

function arena_info_do_logic( req_buff, user_name, user_info_buff, ship_list_buff )

	local req = Tools.decode("ArenaInfoReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)

	local user_info = userInfo:getUserInfo()
	shipList:setUserInfo(user_info)

	local my_info = ArenaCache.getByUserName(user_info.user_name)
	if my_info then
		my_info.power = shipList:getPowerFromLineup()
		my_info.level = user_info.level
		ArenaCache.set(my_info)
	end

	local my_rank = my_info and my_info.rank or 0

	local arena_data = userInfo:getArenaData()

	local function resetChallengeList( rank, flag )
		local info = ArenaCache.getByMyRank(rank)

		if flag == true then

			for i,v in ipairs(info) do
				arena_data.challenge_list[i].rank = v.rank
			end
		else

			if not arena_data.challenge_list or Tools.isEmpty(arena_data.challenge_list) == true then
				arena_data.challenge_list = {}
			end

			for i,v in ipairs(info) do
				arena_data.challenge_list[i] = {
					rank = v.rank,
					isChallenged = false,
				}
			end
		end

		return info
	end

	local function isAllChallenged( )
		for i,v in ipairs(arena_data.challenge_list) do
			if v.isChallenged == false then
				return false
			end
		end
		return true
	end

	local function getTheirInfo( rank )
		--获取
		if req.type == 1 then 

			if not arena_data.challenge_list or Tools.isEmpty(arena_data.challenge_list) == true or isAllChallenged() == true then

				return 0,resetChallengeList(rank)
			end

			local ranks = {}
			for i,v in ipairs(arena_data.challenge_list) do
				if v.rank == rank then
					return 0,resetChallengeList(rank,true)
				end
				ranks[i] = v.rank
			end

			return 0,ArenaCache.getByRanks(ranks)

		--重置
		elseif req.type == 2 then 

			if CoreItem.checkMoney(user_info,10) == false then
				return 2
			end
			CoreItem.expendMoney(user_info,10, CONF.EUseMoney.eArena_reset)

			local info = resetChallengeList(rank)

			return 0,info
		else
			return 1
		end

	end

	
	local resp
	if req.type == 3 then
		local result = 0
		local record_list = ArenaCache.getRecord(user_info.user_name)
		if record_list == nil then
			result = 11
		end
		resp = {
			result = result,
			record_list = record_list,
		}

	else
		local ret,their_info = getTheirInfo(my_rank)

		resp =
		{
			result = ret,
			user_sync = {
				user_info = {
					arena_data = arena_data,
					money = user_info.money,
				},
			},
			my_info = my_info,
			their_info = their_info,
			cur_3_day = ArenaCache.getCur3Day(),
			last_reflesh = ArenaCache.getReflesh(),
		}
	end

	local resp_buff = Tools.encode("ArenaInfoResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff
end

function arena_add_times_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ArenaAddTimesResp", resp)
	elseif step == 1 then
		return datablock.user_info+ datablock.save, user_name
	else
		error("something error");
	end
end

function arena_add_times_do_logic(  req_buff, user_name, user_info_buff )
	local req = Tools.decode("ArenaAddTimesReq", req_buff)
	local userInfo = require "UserInfo"

	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()

	local arena_data = userInfo:getArenaData()

	local function addTimes( )

		if req.type == 1 then
			local need = Tools.calAddArenaTimesNeedMoney(user_info.arena_data.purchased_challenge_times)
			if CoreItem.checkMoney(user_info, need) == false then
				return 1
			end

			arena_data.challenge_times = arena_data.challenge_times + req.times

			CoreItem.expendMoney(user_info, need, CONF.EUseMoney.eArena_add_times)

			arena_data.purchased_challenge_times = arena_data.purchased_challenge_times + req.times

		elseif req.type == 2 then
			local time = 120 - (os.time() - arena_data.last_failed_time)
			if time > 120 then
				return 11
			end

			local need = Tools.getSpeedUpNeedMoney(time)

			if CoreItem.checkMoney(user_info, need) == false then
				return 1
			end
			arena_data.last_failed_time = 0
			CoreItem.expendMoney(user_info, need, CONF.EUseMoney.eArena_add_times)
		end
		
		
		return 0
	end

	local ret = addTimes()

	
	local resp =
	{
		result = ret,
		user_sync = {
			user_info = {
				arena_data = arena_data,
				money = user_info.money,
			}
		}
	}

	local resp_buff = Tools.encode("ArenaAddTimesResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end

function arena_get_daily_reward_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ArenaGetDailyRewardResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end

end

function arena_get_daily_reward_do_logic( req_buff, user_name, user_info_buff, item_list_buff )

	local req = Tools.decode("ArenaGetDailyRewardReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local arena_data = userInfo:getArenaData()

	local db_data = ArenaCache.getByUserName(user_info.user_name)


	local function doLogic(  )

		if arena_data.daily_reward ~= 1 then
			return 1
		end

		local items = {}
		for i,id in ipairs(CONF.ARENA_REWARD.getIDList()) do
			local conf = CONF.ARENA_REWARD.get(id)
			
			if conf.TYPE == 1 and ArenaCache.interval(db_data.rank, conf.RANKING_DOWN, conf.RANKING_UP) == true then
				
				for i=1,6 do
					if conf[string.format("ITEM_ID%d",i)] == 0 then
						break
					end
					items[conf[string.format("ITEM_ID%d",i)]] = conf[string.format("ITEM_NUM%d",i)]
				end
				break
			end
		end

		CoreItem.addItems(items, item_list, user_info)
		local user_sync = CoreItem.makeSync(items, item_list, user_info)
		arena_data.daily_reward = 2

		if Tools.isEmpty(user_sync.user_info) == false then
			user_sync.user_info = {
				arena_data = arena_data
			}
		else
			user_sync.user_info.arena_data = arena_data
		end

		return 0,user_sync
	end

	local ret,user_sync = doLogic()

	local resp =
	{
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("ArenaAddTimesResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function arena_challenge_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		local req = Tools.decode("ArenaChallengeReq", req_buff)

		local num
		if req.type == 0 or req.type == 2 then
			local target_name = ArenaCache.getByRanks({req.rank})[1].user_name
			num = string.sub(target_name,1,5) == "robot" and 1 or 2
		else
			num = 1
		end
		return num, Tools.encode("ArenaChallengeResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.item_package +datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("ArenaChallengeReq", req_buff)
		local target_name = ArenaCache.getByRanks({req.rank})[1].user_name
		return datablock.user_info + datablock.ship_list + datablock.item_package +datablock.save, target_name
	else
		error("something error");
	end
end

function arena_challenge_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff,user_info_buff2, ship_list_buff2, item_list_buff2)
	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"

	local user_info
	local ship_list 
	local item_list 

	local cur_time = os.time()

	local function resetBuff( index )
		if index == 1 then
			userInfo:new(user_info_buff)
			shipList:new(ship_list_buff , user_name)
			itemList:new(item_list_buff)

		else
			userInfo:new(user_info_buff2)
			shipList:new(ship_list_buff2)
			itemList:new(item_list_buff2)
		end

		user_info = userInfo:getUserInfo()
		ship_list = shipList:getShipList()
		item_list = itemList:getItemList()
		shipList:setUserInfo(user_info)
	end

	resetBuff(1)

	local attack_list = {}
	local hurter_list = {}

	local req = Tools.decode("ArenaChallengeReq", req_buff)

	local user_sync = {}

	local function getFightPlayerInfo( )

		local target_name = ArenaCache.getByRanks({req.rank})[1].user_name

		 ArenaCache.setCurrentEnemy( user_info.user_name, target_name )

		if string.sub(target_name,1,5) == "robot" then

			local id = tonumber(string.match(target_name,"(%d+)")) 

			local lineup_monster = CONF.ROBOT.get(id).MONSTER_LIST

			for k,v in ipairs(lineup_monster) do
				local ship_id = v
				if ship_id > 0 then
					local ship_info = shipList:createMonster(ship_id)
					ship_info.position = k
					ship_info.body_position = {k}
					table.insert(hurter_list, ship_info)
				end

			end

		else

			if user_info_buff2 == nil then
				return 999
			end
			resetBuff(2)

			local data_2 = ArenaCache.getByUserName(user_info.user_name)

			local group_main = userInfo:getGroupMainFromGroupCache()

			hurter_list = shipList:getShipByLineup(data_2.ship_guid_list)
			for i=1,#hurter_list do
				hurter_list[i] = Tools.calShip(hurter_list[i], user_info, group_main, true)
				hurter_list[i].body_position = {hurter_list[i].position}
			end

			resetBuff(1)

		end



		local arena_data = userInfo:getArenaData()

		local data = ArenaCache.getByUserName(user_info.user_name)

		if data ~= nil and req.rank == data.rank then
			return 1
		end

		attack_list = shipList:getLineup()

		if req.type == 0 then

			if arena_data.challenge_times < 1 then
				return 2
			end

			if os.time() - arena_data.last_failed_time < 120 then
				return 3
			end

			for i,v in ipairs(attack_list) do
				if Tools.checkShipDurable(v) == false then
					return 4
				end
			end
			arena_data.last_failed_time = 0

			arena_data.challenge_times = arena_data.challenge_times - 1

			arena_data.target_rank = req.rank
		end
		

		local group_main = userInfo:getGroupMainFromGroupCache()
		local guid_list = {0,0,0,0,0,0,0,0,0,}
		local id_list = {0,0,0,0,0,0,0,0,0,}
		local level_list = {0,0,0,0,0,0,0,0,0,}

		for i=1,#attack_list do

			attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true)
			local pos = attack_list[i].position
			attack_list[i].body_position = {pos}

			guid_list[pos] = attack_list[i].guid
			id_list[pos] = attack_list[i].id
			level_list[pos] = attack_list[i].level
		end

		if req.type == 0 then
			--创建竞技场数据
			local data = ArenaCache.getByUserName(user_info.user_name)
			if not data then
				data = {
					rank = 0,
					user_name = user_info.user_name,
					nickname = user_info.nickname,
					score = 0,
					icon_id = user_info.icon_id,
				}
			end
			data.power = shipList:getPowerFromLineup()
			data.level = user_info.level
			data.ship_guid_list = guid_list
			data.ship_id_list = id_list
			data.ship_level_list = level_list
			ArenaCache.set(data)
		end
		return 0
	end

	local getScore
	local add_point

	local board_chat_msg

	local function getFightEndInfo( result )

		local arena_data = userInfo:getArenaData()

		local db_data1 = ArenaCache.getByUserName(user_info.user_name)

		local db_data2 = ArenaCache.getByRanks({arena_data.target_rank})[1]

		if not db_data1 or Tools.isEmpty(db_data1) == true then
			return 11
		end

		if not db_data2 or Tools.isEmpty(db_data2) == true then
			return 12
		end

		if arena_data.target_rank <= 0 then
			return 13
		end

		local score = math.floor(32 *(1 - 1/(1+math.pow(10,((db_data2.score - db_data1.score)/400)+5))))

		local point
		if db_data1.score > 3500 then
			point = math.floor(2894/(1+259 * math.pow(2.71828 ,(-0.0025*db_data1.score)))*0.1 ) 
		else
			point = math.floor((0.206*db_data1.score + 99) * 0.1)
		end

		
		if result == 0 then
			getScore = math.floor(score/5 + 1)
			db_data1.score = db_data1.score + getScore
			add_point = math.floor(point/5 + 2)
			arena_data.honour_point = arena_data.honour_point + add_point
			arena_data.last_failed_time = os.time()

			local achievement_data = userInfo:getAchievementData()
			if (achievement_data.first_failed_battle == false or achievement_data.first_failed_battle == nil) and user_info.level > 3 then
				if (CoreUser.getNewHandGiftBag( user_info )) then
					achievement_data.first_failed_battle = true
				end
			end
		else
			getScore = score
			db_data1.score = db_data1.score + getScore
			add_point = point
			arena_data.honour_point  = arena_data.honour_point + add_point

			for i,v in ipairs(arena_data.challenge_list) do
				if v.rank == arena_data.target_rank then
					v.isChallenged = true	
					break
				end
			end

			if arena_data.daily_reward == 0 then
				local checkOK = true
				for i,v in ipairs(arena_data.challenge_list) do
					if v.isChallenged == false then
						checkOK = false
						break
					end
				end
				if checkOK == true then
					board_chat_msg = string.format(Lang.arena_daily_reword_msg, user_info.nickname)
					arena_data.daily_reward = 1
				end
			end

			arena_data.win_challenge_times = arena_data.win_challenge_times + 1
		end

		arena_data.already_challenge_times = arena_data.already_challenge_times + 1

		local record_info1 ={
			time = cur_time,
			add_score = getScore,
			add_point = add_point,
			result = result,
		}
		ArenaCache.addRecord(user_info.user_name, record_info1)
		local record_info2 ={
			time = cur_time,
			add_score = getScore,
			add_point = add_point,
			result = (result == 0 and 1) or 0,
		}
		ArenaCache.addRecord(ArenaCache.getCurrentEnemy(user_info.user_name), record_info2)

		--更新活动数据
		local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
		if activity_list then
			user_sync.activity_list = {}
			for i,v in ipairs(activity_list) do
				local count = v.seven_days_data.already_challenge_times or 0
				v.seven_days_data.already_challenge_times = count + 1
				if result ~= 0 then
					local win_count = v.seven_days_data.win_challenge_times or 0
					v.seven_days_data.win_challenge_times = win_count + 1
				end
				table.insert(user_sync.activity_list, v)
			end
		end

		ArenaCache.set(db_data1)

		arena_data.target_rank = 0

		--shipList:subLineupDurable(2, result, user_sync)

		return 0
	end

	local ret

	if req.type == 0 or req.type == 2 then
		ret = getFightPlayerInfo()
	else
		ret = getFightEndInfo( req.result )
	end


	if Tools.isEmpty(user_sync.user_info) == true then
		user_sync.user_info = {
			arena_data = userInfo:getArenaData()
		}
	else
		user_sync.user_info.arena_data = userInfo:getArenaData()
	end
	
	local resp = {
		result = ret,
		user_sync = user_sync,
		attack_list = attack_list,
		hurter_list = hurter_list,
		get_score = getScore,
		add_point = add_point,
		type = req.type,
	}

	local resp_buff = Tools.encode("ArenaChallengeResp", resp)
	user_info_buff = userInfo:getUserBuff()
    	ship_list_buff = shipList:getShipBuff()
    	item_list_buff = itemList:getItemBuff()

    	if req.type == 1 and board_chat_msg then
    		--向世界频道推送
		local chat_cmd = 0x1521
		local chat_msg = {
			msg = {board_chat_msg},
			channel = 0,
			type = 2,
			sender = {
				nickname = Lang.arena_reword_sender,
			},
		}
		local chat_msg_buff = Tools.encode("ChatMsg_t", chat_msg)
    		return resp_buff, user_info_buff, ship_list_buff, item_list_buff, chat_cmd, chat_msg_buff
    	end
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff, user_info_buff2, ship_list_buff2, item_list_buff2
end

function arena_title_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ArenaTitleResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error");
	end
end

function arena_title_do_logic( req_buff, user_name, user_info_buff )

	local req = Tools.decode("ArenaTitleReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local arena_data = userInfo:getArenaData()


	local function doLogic(  )

		local next_conf = CONF.ARENATITLE.check(arena_data.title_level+1)
		if next_conf == nil then
			return 1
		end
		if arena_data.honour_point < next_conf.NEED_HONOUR then
			return 2
		end
		arena_data.title_level = arena_data.title_level + 1
		local user_sync = {
			user_info = {
				arena_data = arena_data,
			}
		}
		--发送广播
		local m = CONF.PARAM.get("broadcast_arena").PARAM
		if arena_data.title_level > 1 and Tools.mod(arena_data.title_level, m) == 10 then

			sendBroadcast(user_info.user_name, Lang.world_chat_sender, string.format(Lang.title_board_msg, user_info.nickname, arena_data.title_level))
		end
		return 0,user_sync
	end

	local ret,user_sync = doLogic()

	local resp =
	{
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("ArenaTitleResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end