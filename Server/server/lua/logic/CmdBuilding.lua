function building_upgrade_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}

		return 1, Tools.encode("BuildingUpgradeResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function building_upgrade_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("BuildingUpgradeReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local tech_list = userInfo:getTechnologyList()

	local function buildingUpgrade(index)

		local building_info = userInfo:getBuildingInfo(req.index)
		if  not building_info then
			return 2
		end

		if building_info.upgrade_begin_time and building_info.upgrade_begin_time > 0 then
			return 3
		end

		local confList = CONF[string.format("BUILDING_%d",index)]
		if not confList then
			return 4
		end

		if building_info.level == nil then
			building_info.level = 1
		end

		local conf = confList.get(building_info.level)
		if not conf then
			return 5
		end

		if req.index == CONF.EBuilding.kMain then
			if user_info.level < conf.PLAYER_LEVEL then
				return 5
			end
		end

		if Tools.isEmpty(conf.BUILDING_TYPE) == false then
			for i,index in ipairs(conf.BUILDING_TYPE) do

				local building = userInfo:getBuildingInfo(index)
				if building.level < conf.BUILDING_LEVEL[i] then
					return 5
				end
			end
		end
		
		if Tools.isEmpty(conf.HOME_BUILDING_TYPE) == false then
			for i,index in ipairs(conf.HOME_BUILDING_TYPE) do
				if userInfo:getHomeBuildingLevel(index) < conf.HOME_BUILDING_LEVEL[i] then
					return 5
				end
			end
		end
		

		local group_main = userInfo:getGroupMainFromGroupCache()
		local group_tech_list = group_main and group_main.tech_list or nil
		local cd = conf.CD + Tools.getValueByTechnologyAddition( conf.CD, CONF.ETechTarget_1.kBuilding, index, CONF.ETechTarget_3_Building.kCD, tech_list,group_tech_list, PlanetCache.GetTitleTech(user_name) )
		if cd < 0 then
			cd = 0
		end
		local build_queue = userInfo:getIdleBuildQueue(cd)
		if build_queue == nil then
			return 6
		end

		local items = {}
		for i=1, #conf.ITEM_ID do
			--检查是否有技能减少消费
			items[conf.ITEM_ID[i]] = conf.ITEM_NUM[i] + Tools.getValueByTechnologyAddition(conf.ITEM_NUM[i], CONF.ETechTarget_1.kBuilding, index, CONF.ETechTarget_3_Building.kRes, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))
			if items[conf.ITEM_ID[i]] < 0 then
				items[conf.ITEM_ID[i]] = 0
			end
		end
		
		if not CoreItem.checkItems( items, item_list, user_info) then
			return 7
		end

		build_queue.type = 1
		build_queue.index = index

		CoreItem.expendItems( items, item_list, user_info)

		building_info.upgrade_begin_time = os.time()

		--LOG
		LOG_STAT( string.format( "%s|%s|%d|%d", "BUILD", user_info.user_name, req.index , building_info.level) )

		--等级去掉护盾
		local confP = CONF.PARAM.get("shield_break_building_level").PARAM
		if req.index == confP[1] then
			Tools._print("upgradeBuildingLevel",req.index,building_info.level)
			if building_info.level >= confP[2]-1 then
				local planet_user = PlanetCache.getUser(user_info.user_name)
				if planet_user then
					local base = PlanetCache.getElement(planet_user.base_global_key)
					if base	and base.base_data.shield_type and base.base_data.shield_type == 1 then
						Tools._print("upgradeBuildingLeve close")
						PlanetCache.closeShield(base)
						PlanetCache.saveUserData(planet_user)
					end
				end
			end
		end


		local user_sync = CoreItem.makeSync( items, item_list, user_info)
		user_sync.user_info.build_queue_list = user_info.build_queue_list
		return 0,  building_info, user_sync
	end

	local ret, building_info, user_sync = buildingUpgrade(req.index)
	local resp =
	{
		result = ret,
		user_sync = user_sync,
		info = building_info,
	}

	local resp_buff = Tools.encode("BuildingUpgradeResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end


function building_update_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("BuildingUpdateResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.save, user_name
	else
		error("something error");
	end
end


function building_update_do_logic(req_buff, user_name, user_info_buff, ship_list_buff)

	local req = Tools.decode("BuildingUpdateReq", req_buff)
	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()
	shipList:setUserInfo(user_info)

	local ret = 0

	local building_info = userInfo:getBuildingInfo(req.index)
	if not building_info then
		ret = 1
	end

	local other_user_info = UserInfoCache.get(user_info.user_name)
	if other_user_info then
		local power = shipList:getPowerFromAll()
		if power ~= other_user_info.power then
			other_user_info.power = power
		end
		UserInfoCache.set(user_info.user_name, other_user_info)
	end

	local user_sync = {
		user_info = {
			building_list = user_info.building_list,
			build_queue_list = user_info.build_queue_list,
			activity_list = user_info.activity_list,
		},
	}

	local resp =
	{
		result = ret,
		user_sync = user_sync,
		index = req.index,
	}

	local resp_buff = Tools.encode("BuildingUpdateResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff
end


function building_upgrade_speed_up_feature(step, req_buff, user_name)
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("BuildingUpgradeSpeedUpResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function building_upgrade_speed_up_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("BuildingUpgradeSpeedUpReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()


	local function doLogic( req  )
		local building_info = userInfo:getBuildingInfo(req.index)
		if not building_info then
			return 1
		end

		local cd = userInfo:getBuildingCDTime(req.index, building_info)

		local diff = cd + building_info.upgrade_begin_time - os.time()
		if diff <= 0 then
			return 2
		end

		local needMoney = Tools.getSpeedUpNeedMoney(diff)

		--VIP减少元宝
		local vip_conf  = CONF.VIP.get(user_info.vip_level)
		if vip_conf then
			if cd <= vip_conf.BUILDING_FREE then
				needMoney = 0
			end
		end

		local user_sync = {}
		if needMoney > 0 then
			if CoreItem.checkMoney(user_info, needMoney) == false then
				return 3
			end

			CoreItem.expendMoney(user_info, needMoney , CONF.EUseMoney.eBuilding_time)

			--LOG_STAT( string.format( "%s|%s|%d|%d", "LEVEL_UP", user_info.user_name, old_level, user_info.level ) )

			user_sync = CoreItem.syncMoney(user_info)
		end

		if userInfo:upgradeBuildingLevel(req.index,building_info) == false then
			return 4
		end
		
		if user_sync.user_info == nil then
			user_sync.user_info = {}
		end
		user_sync.user_info.build_queue_list = user_info.build_queue_list
		user_sync.user_info.level = user_info.level
		user_sync.user_info.exp = user_info.exp
		return 0,building_info,user_sync
	end


	local ret,building_info,user_sync = doLogic(req)

	local resp =
	{
		result = ret,
		user_sync = user_sync,
		info = building_info,
		index = req.index,
	}

	local resp_buff = Tools.encode("BuildingUpgradeSpeedUpResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end



function build_queue_add_feature(step, req_buff, user_name)
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("BuildQueueAddResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error");
	end
end

function build_queue_add_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("BuildQueueAddReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local function add()
		if req.num < 1 then
			return 1
		end
		
		local sub = CONF.PARAM.get("queue_buy_num").PARAM * req.num
		if CoreItem.checkMoney(user_info,sub) == false then
			return 2
		end
		
		local duration = CONF.PARAM.get("queue_buy_time").PARAM * 3600 * req.num
		--购买的时间不能超过一百天
		if duration > 8640000 then 
			duration = 8640000
		end

		if user_info.build_queue_list[2] ~= nil then

			user_info.build_queue_list[2].duration_time = user_info.build_queue_list[2].duration_time + duration
		else
			if #user_info.build_queue_list > 1 then
				return 3
			end
			local build_queue = {
				duration_time = duration,
				open_time = os.time(),
				type = 0,
				index = 0,
			}
			table.insert(user_info.build_queue_list, build_queue)
		end
		
		CoreItem.expendMoney(user_info, sub, CONF.EUseMoney.eBuild_queue_add)

		local user_sync = CoreItem.syncMoney(user_info)
		user_sync.user_info.build_queue_list = user_info.build_queue_list
	   
		return 0, user_sync
	end

	local ret,user_sync = add()

	local resp =
	{
		result        = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("BuildQueueAddResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end


function build_queue_remove_feature(step, req_buff, user_name)
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("BuildQueueRemoveResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error");
	end
end

function build_queue_remove_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("BuildQueueRemoveReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()


	local function remove(  )
		local build_queue = user_info.build_queue_list[req.index]
		if build_queue == nil then
			return 1
		end
		if build_queue.type ~= 0 and req.index ~= 1 then
			return 2
		end

		if os.time() - build_queue.open_time < build_queue.duration_time then
			return 3
		end

		if build_queue.open_time < 0 then
			return 4
		end

		table.remove(user_info.build_queue_list, req.index)
	end

	local ret = remove()
	local resp =
	{
		result = ret,
		user_sync = {
			user_info = {
				build_queue_list = user_info.build_queue_list,
			}
		}
	}

	local resp_buff = Tools.encode("BuildQueueRemoveResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end