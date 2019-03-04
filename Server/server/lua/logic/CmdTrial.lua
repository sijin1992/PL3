local Bit = require "Bit"

function trial_get_reward_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("TrialGetRewardResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function trial_get_reward_do_logic( req_buff, user_name, user_info_buff, item_list_buff )
	local req = Tools.decode("TrialGetRewardReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()



	local confCopy = CONF.TRIAL_COPY.check(req.copy_id)

	local function getReward( )
		local star = 0

		for i,level_id in ipairs(confCopy.LEVEL_ID) do
			local level = userInfo:getTrialLevelByID(level_id)
			if not level then
				return 1
			end
			star = star + level.star
		end

		if star < confCopy.START_NUM then
			return 2
		end

		local copy = userInfo:getTrialCopyByID(req.copy_id)

		if copy.reward_flag > 0 then
			return 3
		end

		local user_sync = {
			user_info = {},
			item_list = {},
			ship_list = {},
			equip_list = {},
		}

		userInfo:getReward(confCopy.REWARD_ID, item_list ,user_sync)

		copy.reward_flag = 1
		
		return 0,user_sync
	end

	local ret,user_sync = getReward()

	local resp =
	{
		result = ret,
		user_sync = user_sync,
		copy_id = req.copy_id,
	}

	local resp_buff = Tools.encode("TrialGetRewardResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function trial_add_ticket_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("TrialAddTicketResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function trial_add_ticket_do_logic( req_buff, user_name, user_info_buff, item_list_buff )

	local req = Tools.decode("TrialAddTicketReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local trial_data = userInfo:getTrialData()

	local function doLogic( req )
		
		if req.num < 1 then
			return 1
		end

		local canChange = false
		for i,v in ipairs(CONF.PARAM.get("add_trial_times_id").PARAM) do
			if v == req.item_id then
				canChange = true
				break
			end
		end
		if canChange == false then
			return 2
		end
		local items = {[req.item_id] = req.num}

		if CoreItem.checkItems(items, item_list, user_info) == false then
			return 3
		end

		CoreItem.expendItems(items, item_list, user_info)

		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		trial_data.ticket_num = trial_data.ticket_num + req.num

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp =
	{
		result = ret,
		ticket_num = trial_data.ticket_num,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("TrialAddTicketResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end


function trial_get_times_feature(  step, req_buff, user_name  )
	if step == 0 then

		local resp =
		{
		    result = -1,
		}

		return 1, Tools.encode("TrialGetTimesResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error");
	end
end

function trial_get_times_do_logic( req_buff, user_name, user_info_buff )

	local req = Tools.decode("TrialGetTimesReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)


	local trial_data = userInfo:getTrialData()

	local resp =
	{
		result = 0,
		ticket_num = trial_data.ticket_num
	}


	local resp_buff = Tools.encode("TrialGetTimesResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end


function trial_area_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
		    result = -1,
		}
		return 1, Tools.encode("TrialAreaResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.save, user_name
	else
		error("something error");
	end
end


function trial_area_do_logic(req_buff, user_name, user_info_buff, ship_list_buff)


	local req = Tools.decode("TrialAreaReq", req_buff)
	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)

	local user_info = userInfo:getUserInfo()
	shipList:setUserInfo(user_info)


	local user_sync = {
		user_info = {},
	}

	local openArea = function ( req_area_id, req_lineup )

		local area_info = userInfo:getTrialArea(req.area_id)

		local trial_data = userInfo:getTrialData()

		local  areaConf = CONF.TRIAL_AREA.check(req_area_id)
		if not areaConf then
			return 1
		end

		if user_info.level < areaConf.ROLE_LEVEL then
			return 2
		end

		local power = shipList:getPowerFromAll()

		if power < areaConf.ROLE_COMBAT then
			return 3
		end
		
	   	if area_info == nil then 
	   		local data = {
				area_id = req_area_id,
				status = 0,
				ship_list = {},
			}
			area_info = data
	   		if Tools.isEmpty(trial_data.area_list) == true then
	   			trial_data.area_list = {area_info}
	   		else
	   			table.insert(trial_data.area_list, area_info)
	   		end
	   	end

	   	if area_info.status == 1 then
	   		return 5
	   	end

	   	local count = 0
	   	for i,v in ipairs(req_lineup) do
	   		if v > 0 then
	   			count = count + 1
	   		end
	   	end
	   	
	   	local building_14_conf = CONF.BUILDING_14.get(userInfo:getBuildingInfo(CONF.EBuilding.kWarWorkshop).level)
	   	if not req_lineup or Tools.isEmpty(req_lineup) or #req_lineup ~= 9 or count > building_14_conf.AIRSHIP_NUM then
	   		return 6
	   	end


	   	if trial_data.ticket_num < 1 then
	   		return 7
	   	end
	   	trial_data.ticket_num = trial_data.ticket_num - 1

	   	local group_main = userInfo:getGroupMainFromGroupCache()

	   	area_info.ship_list = {}
	   	for i,v in ipairs(req_lineup) do
	   		if v ~= 0 then
	   			local ship_info = shipList:getShipInfo(v)
	   			if not ship_info then
	   				return 8
	   			end
	   			local calShip = Tools.calShip(ship_info, user_info, group_main, true)
	   			if not calShip then
	   				return 9
	   			end
	   			if Bit:has(calShip.status, CONF.EShipState.kFix) == true then
	   				return 10
	   			end
	   			if Bit:has(calShip.status, CONF.EShipState.kOuting) == true then
	   				return 11
	   			end
	   			local ship = {
	   				hp = calShip.attr[CONF.EShipAttr.kHP],
	   				guid = v,
	   			}
	   			table.insert(area_info.ship_list, ship)
	   		else
			
	   		end
	   		
	   	end

	   	area_info.lineup = req_lineup
	   	area_info.status = 1

	   	--更新每日数据
		local daily_data = CoreUser.getDailyData(user_info)
		if not daily_data.trial_times then
			daily_data.trial_times = 1
		else
			daily_data.trial_times = daily_data.trial_times + 1
		end
		user_sync.user_info.daily_data = daily_data


	   	return 0
	end

	local function resetLineup( req_area_id, req_lineup )

		local area_info = userInfo:getTrialArea(req.area_id)

		if not area_info or area_info.status ~= 1 then
			return 11
		end

		if not req_lineup or Tools.isEmpty(req_lineup) == true or #req_lineup ~= 9 then
	   		return 12
	   	end

		for i,v in ipairs(req_lineup) do

			if v ~= 0 then
				local has = false
				for index,ship in ipairs(area_info.ship_list) do
					if ship.guid == v then
						has = true
						break
					end
				end

				if has == false then
					return 12
				end

			end
		end

		area_info.lineup = req_lineup
		return 0
	end

	local function closeArea( req_area_id )

		local area_info = userInfo:getTrialArea(req.area_id)

		if area_info.status == 0 then
			return 21
		end

		area_info.status = 0
		area_info.lineup = {}
		area_info.ship_list = {}

		return 0
	end

	local ret
	if req.type == 1 then
		ret = openArea(req.area_id, req.lineup)
	elseif req.type == 2 then
		ret  = resetLineup(req.area_id, req.lineup)
	elseif req.type == 3 then
		ret  = closeArea(req.area_id)
	else
		ret = 999
	end

	user_sync.user_info.trial_data = userInfo:getTrialData()
	local resp =
	{
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("TrialAreaResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff
end




function trial_get_building_info_feature(  step, req_buff, user_name  )
	if step == 0 then

		local resp =
		{
		    result = -1,
		}
		return 1, Tools.encode("TrialGetBuildingInfoResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error");
	end
end

function trial_get_building_info_do_logic( req_buff, user_name, user_info_buff )

	local req = Tools.decode("TrialGetBuildingInfoReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	
	local info = TrialCache.get(req.level_id)

	local resp =
	{
		result = 0,
		building_info = info
	}

	local resp_buff = Tools.encode("TrialGetBuildingInfoResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end


function trial_pve_start_feature( step, req_buff, user_name )
	if step == 0 then


		local req = Tools.decode("TrialPveStartReq", req_buff)
		local info = TrialCache.get(req.level_id)
		local num
		if info then
			if info.user_name == user_name then
				num = 1
			else
				num = 2
			end
		else
			num = 1
		end

		local resp =
		{
			result = -1,
		}
		return num, Tools.encode("TrialPveStartResp", resp)
	elseif step == 1 then	
		return datablock.user_info + datablock.ship_list + datablock.item_package + datablock.save, user_name
	elseif step == 2 then

		local req = Tools.decode("TrialPveStartReq", req_buff)

		local target = TrialCache.get(req.level_id).user_name	
		return datablock.main_data + datablock.ship_list + datablock.item_package + datablock.save, target
	else
		error("something error")
	end
end

function trial_pve_start_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff,user_info_buff2, ship_list_buff2, item_list_buff2)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"

	local user_info
	local ship_list 
	local item_list 

	local req = Tools.decode("TrialPveStartReq", req_buff)

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

	local ret = 0

	local cache_info = TrialCache.get(req.level_id)
	-- if cache_info then

	-- 	if cache_info.user_name == user_name then
	-- 		ret = 999
	-- 	end	
	-- end

	local attack_list = {}
	local hurter_list = {}


	local confLevel = CONF.TRIAL_LEVEL.check(req.level_id)
	--local confCopy = CONF.TRIAL_COPY.check(confLevel.T_COPY_ID)
	-- if not confCopy or  user_info.level < confCopy.LEVEL_LV then
	-- 	ret = 1
	-- end
	
	
	local function getFightMonsterInfo()

		local area_info = userInfo:getTrialArea(confLevel.AREA_ID)

		if not area_info.lineup then
			return 11
		end

		if area_info.status ~= 1 then
			return 12
		end

		attack_list = shipList:getShipByLineup(area_info.lineup)


		local group_main = userInfo:getGroupMainFromGroupCache()

		for i=1,#attack_list do
    
			attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true)
			attack_list[i].body_position = {attack_list[i].position}

		end

		local big_ship = 0
		for i,v in ipairs(confLevel.MONSTER_ID) do
			local bodyPositions = {}
			local ship_id = 0
			if v > 0 then
				ship_id = v
				table.insert(bodyPositions, i)
			elseif v < 0 and big_ship == 0 then
				ship_id = math.abs(v)
				for pos,id in ipairs(confLevel.MONSTER_ID) do
					if id == v then
						table.insert(bodyPositions, pos)
					end
				end
				big_ship = 1
			end

			if ship_id > 0 then
				local ship_info = shipList:createMonster(ship_id)
                			ship_info.position = i
                			ship_info.body_position = bodyPositions
                			table.insert(hurter_list, ship_info)
			end


		end


		return 0
	end

	local function getFightPlayerInfo()
		local area_info = userInfo:getTrialArea(confLevel.AREA_ID)

		if cache_info.user_name == user_info.user_name then
			return 20
		end

		if req.target_name ~= cache_info.user_name then
			return 21
		end
		
		if not area_info.lineup then
			return 22
		end

		if area_info.status ~= 1 then
			return 23
		end

		attack_list = shipList:getShipByLineup(area_info.lineup)

		for i,v in ipairs(attack_list) do
			if Tools.checkShipDurable(v) == false then
				return 24
			end
		end


		local group_main = userInfo:getGroupMainFromGroupCache()

		for i=1,#attack_list do
          
			attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true)

			attack_list[i].body_position = {attack_list[i].position}
		end

		resetBuff(2)

		group_main = userInfo:getGroupMainFromGroupCache()

		hurter_list = shipList:getShipByLineup(cache_info.lineup)
		for i=1,#hurter_list do
			hurter_list[i] = Tools.calShip(hurter_list[i], user_info, group_main, true)
			hurter_list[i].body_position = {hurter_list[i].position}
		end

		resetBuff(1)

		return 0
	end

	local hp_list = {}

	if ret  == 0 then
		if confLevel == nil then
			ret = 2
		else
			local area_info = userInfo:getTrialArea(confLevel.AREA_ID)
			
			if area_info == nil then
				ret = 3
			else
				for i,guid in ipairs(area_info.lineup) do
					if guid > 0 then
						for _,ship in ipairs(area_info.ship_list) do
							if ship.guid == guid then
								if ship.hp <= 0 then
									ret = 4
								end
								hp_list[i] = ship.hp
								break
							end
						end
					else
						hp_list[i] = 0
					end
				end
			end
		end
	end

	if req.type == 1 then
		if userInfo:getStrength() < confLevel.STRENGTH then
			ret = 1
		end
	end
	
	if ret == 0 then
		if cache_info then
			ret = getFightPlayerInfo()
		else
			ret = getFightMonsterInfo()
		end

		if req.type == 1 and ret == 0 then
			userInfo:removeStrength(confLevel.STRENGTH)
		end
	end

	local resp = {
		result = ret,
		attack_list = attack_list,
		hurter_list = hurter_list,
		level_id = req.level_id,
		hp_list = hp_list,
		user_sync= {
			user_info = {
				strength = userInfo:getStrength(),
			},
		},
		type = req.type,
	}

	local resp_buff = Tools.encode("TrialPveStartResp", resp)
	user_info_buff = userInfo:getUserBuff()
    	ship_list_buff = shipList:getShipBuff()
    	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff, user_info_buff2, ship_list_buff2, item_list_buff2
end

function trial_pve_end_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("TrialPveEndResp", resp)
	elseif step == 1 then		
		return datablock.main_data + datablock.ship_list + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function trial_pve_end_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
	
	local req = Tools.decode("TrialPveEndReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()
	local item_list = itemList:getItemList()

	shipList:setUserInfo(user_info)


	local confLevel = CONF.TRIAL_LEVEL.check(req.level_id)
	local area_info = userInfo:getTrialArea(confLevel.AREA_ID)

	local function isBuilding( level_id )
		
		local list = CONF.TRIAL_SCENE.getIDList()
		for i,key in ipairs(list) do
			local conf = CONF.TRIAL_SCENE.get(key)
			if conf.BUILDING_LEVEL_ID == level_id then
				return true
			end
		end
		return false
	end

	local save_lineup = Tools.clone(area_info.lineup)
	local save_id_lineup = {0,0,0,0,0,0,0,0,0,}
	for i,guid in ipairs(save_lineup) do
		if guid > 0 then
			local ship_info = shipList:getShipInfo(guid)
			save_id_lineup[i] = ship_info.id
		end
	end

	for i,guid in ipairs(area_info.lineup) do
		local hp = req.hp_list[i]
		if hp < 0 then
			hp = 0
		end
		for _,ship in ipairs(area_info.ship_list) do
			if ship.guid == guid then
				ship.hp = hp
				break
			end
		end

		--HP等于0时下阵
		if hp == 0 then
			area_info.lineup[i] = 0
		end
	end

	local user_sync = {
		user_info = {},
		item_list = {},
                    	ship_list = {},
	}

	local old_info = TrialCache.get(req.level_id)
	if old_info then
		--CoreUser.battleCount(user_info.user_name, old_info.user_name, req.result == 1)
	end

	local reward_flag
	local isFirstCross = false
	local oldBuildingUserName = nil
	local get_item_list
	if req.result == 1 then

		local getReward = false



		if isBuilding(req.level_id) == true then

			local oldInfo = TrialCache.get(req.level_id)
			if oldInfo then
				oldBuildingUserName = oldInfo.user_name
			end

			local info = {
				user_name = user_info.user_name,
				lineup = save_lineup,
				id_lineup = save_id_lineup,
			}
			TrialCache.set(req.level_id, info)
		else

			local level_info = userInfo:getTrialLevelByID(req.level_id) 
			if level_info == nil or level_info.star == nil or level_info.star <= 0 then
				getReward = true
				isFirstCross = true
			end

			if req.star <= confLevel.START_MAX then
				userInfo:setTrialLevel(req.level_id, req.star)
			end

			--更新活动数据
			local user_sync_activity_list = {}
			local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
			if activity_list then
				for i,v in ipairs(activity_list) do
					CoreUser.activityUpdateTrialLevel(req.level_id, req.star, v)
					table.insert(user_sync_activity_list, v)
				end
			end
		end


		--加奖励
		CoreUser.addExp(confLevel.EXP1, user_info)
		userInfo:addRes(1, confLevel.GOLD)

		userInfo:addBadge(confLevel.BADGE)

		user_sync.user_info.exp = user_info.exp
           	 	user_sync.user_info.level  = user_info.level
           	 	user_sync.user_info.res = user_info.res

		shipList:addLineupExp(confLevel.EXP2, user_sync, area_info.lineup)
		if getReward == true then
			user_sync, get_item_list = userInfo:getReward(confLevel.REWARD_ID, item_list ,user_sync)
			reward_flag = true
		else
			reward_flag = false
		end


	else
		local hasLive = false
		for i,ship in ipairs(area_info.ship_list) do
			if ship.hp > 0 then
				hasLive = true
				break
			end
		end
		if hasLive then

		else
			area_info.status = 0
			area_info.lineup = {}
			area_info.ship_list = {}
		end
	end
	user_sync.user_info.trial_data = userInfo:getTrialData()
	
	shipList:subLineupDurable(1, req.result, user_sync, area_info.lineup)

	local resp = {
		result = 0,
		level_id = req.level_id,
		user_sync = user_sync,
		reward_flag = reward_flag,
		get_item_list = get_item_list,
	}

	local resp_buff = Tools.encode("TrialPveEndResp", resp)
	user_info_buff = userInfo:getUserBuff()
    	ship_list_buff = shipList:getShipBuff()
    	item_list_buff = itemList:getItemBuff()

    	if req.result == 1 then

    		if isBuilding(req.level_id) == true then
    			--向世界频道推送取得试炼建筑
    			local msgStr
    			if oldBuildingUserName then
    				local other_user_info = UserInfoCache.get(oldBuildingUserName)
    				if other_user_info then
    					msgStr = string.format(Lang.trial_attack_building_win_msg, user_info.nickname, other_user_info.nickname)
    				end
    			else
    				msgStr = string.format(Lang.trial_get_building_win_msg, user_info.nickname)
    			end
    			
    			if msgStr then
				local chat_cmd = 0x1521
				local chat_msg = {
					msg = {msgStr},
					channel = 0,
					type = 2,
					sender = {
						nickname = Lang.world_chat_sender,
					},
				}
				local chat_msg_buff = Tools.encode("ChatMsg_t", chat_msg)
				return resp_buff, user_info_buff, ship_list_buff, item_list_buff, chat_cmd, chat_msg_buff
			end

    		else
    			--向世界频道推送通关
    			local isLastLevel = false
			local levelConf = CONF.TRIAL_LEVEL.get(req.level_id)
			local copyConf = CONF.TRIAL_COPY.get(levelConf.T_COPY_ID)

			if Tools.isEmpty(copyConf.LEVEL_ID) == true then
				if copyConf.LEVEL_ID[#copyConf.LEVEL_ID] == req.level_id then
					isLastLevel = true
				end
			end
			if isFirstCross == true and isLastLevel == true then
				local chat_cmd = 0x1521
				local chat_msg = {
					msg = {string.format(Lang.copy_msg, user_info.nickname, CONF.STRING.get(copyConf.T_COPY_NAME).VALUE)},
					channel = 0,
					type = 1,
					sender = {
						nickname = Lang.world_chat_sender,
					},
				}
				local chat_msg_buff = Tools.encode("ChatMsg_t", chat_msg)
				return resp_buff, user_info_buff, ship_list_buff, item_list_buff, chat_cmd, chat_msg_buff
		    	end
    		end
	end

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end