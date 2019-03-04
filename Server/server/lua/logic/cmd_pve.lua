
-- local logic_user = require "logic_user"
-- local core_user = require "core_user_funcs"
-- local core_power = require "core_calc_power"
-- local rank = rank

-- local pve = require "pve"

-- local function is_robot(name)
-- 	if tonumber(name) then return nil end
-- 	local name1 = string.sub(name, 1,6)
-- 	local name2 = tonumber(string.sub(name, 7))
-- 	if name1 == "Robot_" and name2 then return name2
-- 	else return nil end
-- end
local Bit = require "Bit"

function pve_get_reward_feature(step, req_buf, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("PVEGetRewardResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.item_package + datablock.save,user_name
	else
		error("something error");
	end
end

function pve_get_reward_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

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

	local req = Tools.decode("PVEGetRewardReq", req_buff)

	local function doLogic( )
		local conf = CONF.COPY.check(req.copy_id)
		if conf == nil then
			return 1
		end

		if userInfo:getStageCopyStarNum(req.copy_id) < conf[string.format("SCORE%d",req.score_id)] then
			return 2
		end

		if userInfo:isGotStageCopyReward(req.copy_id,req.score_id) == true then
			return 3
		end


		local user_sync = userInfo:getReward(conf[string.format("REWARD_ID%d",req.score_id)], item_list)

		userInfo:setGotStageCopyReward(req.copy_id,req.score_id)

		user_sync.user_info.stage_data = userInfo:getStageData()

		return 0,user_sync
    	end

   
	local ret, user_sync = doLogic()

	resp ={
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("PVEGetRewardResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end

function fight_feature(step, req_buff, user_name)
	if step == 0 then
		local req = Tools.decode("PveReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("PveResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function fight_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

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


	local req = Tools.decode("PveReq", req_buff)
	

	local group_main = userInfo:getGroupMainFromGroupCache()

	local resp

	local function pveStart( req )

		shipList:changeLineup(user_info, user_info.lineup)

		local attack_list = shipList:getLineup()

		local attackCount = #attack_list
		if attackCount < 1 then
			return 1
		end

		for i=1,attackCount do

			attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true)

			attack_list[i].body_position = {attack_list[i].position}
		end

		local hurter_list = {}

		local checkpointConf = CONF.CHECKPOINT.get(req.checkpoint_id)

		local strength

		if req.type == 0 then

			local level = CONF.PARAM.get("ship_pve_durable_level").PARAM
			if level > user_info.level then
				for i,v in ipairs(attack_list) do
					if Tools.checkShipDurable(v) == false then
						return 2
					end

					--if Bit:has(v.status, CONF.EShipState.kFix) == true then
	   				--	return 3
	   				--end

	   				--if Bit:has(v.status, CONF.EShipState.kOuting) == true then
					--	return 4
					--end
				end
			end

			if user_info.strength - checkpointConf.STRENGTH < 0 then
				return 5
			end



			strength = userInfo:removeStrength(checkpointConf.STRENGTH)
		end


		local lineup_monster = checkpointConf.MONSTER_LIST
		local big_ship = 0

		for k,v in ipairs(lineup_monster) do
			local bodyPositions = {}
			local ship_id = 0
			if v > 0 then
				ship_id = v
				table.insert(bodyPositions, k)
			end
			if v < 0 and big_ship == 0 then
				ship_id = math.abs(v)
				for pos,id in ipairs(lineup_monster) do
					if id == v then
						table.insert(bodyPositions, pos)
					end
				end
				big_ship = 1
            			end

			if ship_id > 0 then

				local ship_info = shipList:createMonster(ship_id)
				ship_info.position = k
				ship_info.body_position = bodyPositions
				table.insert(hurter_list, ship_info)
			end
        		end

		resp =
		{
			result = 0,
			type = req.type,
			attack_list = attack_list,
			hurter_list = hurter_list,
			checkpoint_id = req.checkpoint_id,
			user_sync = {
				user_info = {
					strength = strength,
				},
			},
		}
		return 0
	end

	local function pveEnd(req)

		local exp1_bonus = 0
		local exp2_bonus = 0
		local gold_bonus = 0
		local science_bonus = 0
		local item_bonus = {}
		local user_sync = {
			user_info = {},
			item_list = {},
			ship_list = {},
			equip_list = {},
		} 
		local get_item_list

		local level_id = req.checkpoint_id
		local star = req.star
		local oldStar = userInfo:getLevelStar(level_id)

		local tech_list = userInfo:getTechnologyList()

		local group_tech_list = group_main and group_main.tech_list or nil

		if req.result == 1 then
			userInfo:setLevelStar(level_id, star)
			--LOG
			LOG_STAT( string.format( "%s|%s|%d|%d", "PVE", user_info.user_name, level_id, star ) )
			--更新活动数据
			local user_sync_activity_list = {}
			local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
			if activity_list then
				for i,v in ipairs(activity_list) do
					CoreUser.activityUpdateLevelInfo(level_id, star, v)
					table.insert(user_sync_activity_list, v)
				end
			end


			local cpConf = CONF.CHECKPOINT.get(level_id)

			--科技加成效果
			local group_tech_exp1 = 0
			local group_tech_exp2 = 0
			local group_tech_gold = 0

			

			exp1_bonus = CONF.CHECKPOINT.get(level_id).EXP1 + Tools.getValueByTechnologyAddition(cpConf.EXP1, CONF.ETechTarget_1.kReword, CONF.ETechTarget_2_Reword.kCopy, CONF.ETechTarget_3_Reword.kRole, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))

			exp2_bonus = CONF.CHECKPOINT.get(level_id).EXP2 + Tools.getValueByTechnologyAddition(cpConf.EXP2, CONF.ETechTarget_1.kReword, CONF.ETechTarget_2_Reword.kCopy, CONF.ETechTarget_3_Reword.kShip, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))

			gold_bonus = CONF.CHECKPOINT.get(level_id).GOLD + Tools.getValueByTechnologyAddition(cpConf.GOLD, CONF.ETechTarget_1.kReword, CONF.ETechTarget_2_Reword.kCopy, CONF.ETechTarget_3_Reword.kGold, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))


			science_bonus = CONF.CHECKPOINT.get(level_id).SCIENCE

			local slave_data = SlaveCache.get(user_info.user_name)
			if slave_data.master then
				exp1_bonus = exp1_bonus - SlaveCache.slaveSetRes(user_info.user_name, 0, exp1_bonus)
			end
			
			CoreUser.addExp(exp1_bonus, user_info)
			userInfo:addRes(1, gold_bonus)
			userInfo:addCredit(science_bonus)

			user_sync.user_info.stage_data = user_info.stage_data
			user_sync.user_info.exp    = user_info.exp
			user_sync.user_info.level  = user_info.level
			user_sync.user_info.money  = user_info.money
			user_sync.user_info.res = user_info.res
			user_sync.activity_list = user_sync_activity_list

			shipList:addLineupExp(exp2_bonus ,user_sync)


			if CONF.CHECKPOINT.get(level_id).REWARD_ID ~= nil  then
				user_sync, get_item_list = userInfo:getReward(CONF.CHECKPOINT.get(level_id).REWARD_ID, item_list, user_sync, CONF.ETechTarget_2_Reword.kCopy)
			end
			if GolbalActivity.isOpen( 21001, os.time()) then
				if CONF.GIFT_BAG.check(req.checkpoint_id) then
					local gift = CONF.GIFT_BAG.get(req.checkpoint_id)
					if gift then
						local items = {}
						for i,v in ipairs(gift.WEIGHT) do
							if math.random(1,100) < v then
								local item = {
									key = gift.ITEM[i],
									value = gift.NUM[i],
								}
								print("add gift item=",gift.ITEM[i])
								table.insert(get_item_list,item)	
								items[gift.ITEM[i]] = gift.NUM[i]
								break
							end
						end
						CoreItem.addItems(items, item_list, user_info)
						user_sync = CoreItem.makeSync(items, item_list, user_info, user_sync)
					end
				end
			end

		else
			local achievement_data = userInfo:getAchievementData()
			if (achievement_data.first_failed_battle == false or achievement_data.first_failed_battle == nil) and user_info.level > 3 then
				if (CoreUser.getNewHandGiftBag( user_info )) then
					achievement_data.first_failed_battle = true
				end
			end
		end

		--更新每日数据
		local daily_data = CoreUser.getDailyData(user_info)
		if not daily_data.checkpoint_fight then
			daily_data.checkpoint_fight = 1
		else
			daily_data.checkpoint_fight = daily_data.checkpoint_fight + 1
		end
		if req.result == 1 then
			if not daily_data.checkpoint_win then
				daily_data.checkpoint_win = 1
			else
				daily_data.checkpoint_win = daily_data.checkpoint_win + 1
			end
		end
		user_sync.user_info.daily_data = daily_data

		local level = CONF.PARAM.get("ship_pve_durable_level").PARAM
		if user_info.level > level then
			shipList:subLineupDurable(1, req.result, user_sync, nil, tech_list, group_tech_list)
		end   	 	

		resp =
		{
			result = 0,
			type = req.type,
			char_exp_bonus = exp1_bonus,  --//主角经验奖励
			ship_exp_bonus    = exp2_bonus,  --//飞船经验奖励
			level_gold_bonus  = gold_bonus,  --//副本金币奖励
			level_point_bonus = science_bonus,  --//副本信用点奖励
			checkpoint_id     = req.checkpoint_id,
			user_sync         = user_sync,
			get_item_list = get_item_list,
		} 

	            return 0, oldStar
	end
	
	
	local ret, oldStar
	if req.type == 0 or req.type == 2 then

		ret = pveStart(req)
	elseif req.type == 1 then
		ret, oldStar = pveEnd(req)
	else
		ret = 999
	end

	if ret ~= 0 then
		resp =
		{
			result = ret,
		}
	end

	local resp_buff = Tools.encode("PveResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()



	if ret == 0 and req.result == 1 and req.type == 1 then

		local isLastLevel = false
		local cpConf = CONF.CHECKPOINT.get(req.checkpoint_id)
		local copyConf = CONF.COPY.get(cpConf.AREA_ID)

		if Tools.isEmpty(copyConf.LEVEL_ID) == true then
			if copyConf.LEVEL_ID[#copyConf.LEVEL_ID] == req.checkpoint_id then
				isLastLevel = true
			end
		end

	    	if oldStar == 0 and isLastLevel == true then
	    		--向世界频道推送
			local chat_cmd = 0x1521
			local chat_msg = {
				msg = {string.format(Lang.copy_msg, user_info.nickname, CONF.STRING.get(copyConf.COPY_NAME).VALUE)},
				channel = 0,
				type = 2,
				sender = {
					nickname = Lang.world_chat_sender,
				},
			}
			local chat_msg_buff = Tools.encode("ChatMsg_t", chat_msg)
			return resp_buff, user_info_buff, ship_list_buff, item_list_buff, chat_cmd, chat_msg_buff
	    	end
	end

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end