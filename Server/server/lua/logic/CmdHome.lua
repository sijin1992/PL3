

function get_home_feature(step, req_buff, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local req = pb.decode("GetHomeSatusReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 1, pb.encode("GetHomeSatusResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error");
	end
end

function get_home_do_logic(req_buff, user_name, user_info_buff)
	local pb = require "protobuf"
	local req = pb.decode("GetHomeSatusReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local ret, home_info = userInfo:getHomeData()
	local resp =
	{
		result = ret,
		--home_info = home_info,
		user_sync = { 
			user_info = {
				home_info = home_info,
				build_queue_list = user_info.build_queue_list,
				activity_list = user_info.activity_list,
			},
		},
	}

	local resp_buff = pb.encode("GetHomeSatusResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end

function get_resource_feature(step, req_buff, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local req = pb.decode("GetResourceReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 1, pb.encode("GetResourceResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function get_resource_do_logic(req_buff, user_name, user_info_buff, item_list_buff)
	local pb = require "protobuf"
	local req = pb.decode("GetResourceReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	local ret, resource_type, resource_num, user_sync = userInfo:getHomeResource(req.land_index,item_list)

	local resp =
	{
		result = ret,
		user_sync = user_sync,
		land_index = req.land_index,
		resource_type = resource_type,
		resource_num  = resource_num,
	}

	local resp_buff = pb.encode("GetResourceResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function upgrade_resource_feature(step, req_buff, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local req = pb.decode("UpgradeResLandReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 1, pb.encode("UpgradeResLandResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function upgrade_resource_do_logic(req_buff, user_name, user_info_buff, item_list_buff)
	local pb = require "protobuf"
	local req = pb.decode("UpgradeResLandReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()


	local ret = 1
	

	local function upgradeResource(index)

		local have_land_num = 0
		local home_info = userInfo:getHomeInfo()
		local land_list = userInfo:getHomeLandList()
		local typeID = req.resource_type

		local conf = CONF.RESOURCE.get(typeID)
		local tech_list = userInfo:getTechnologyList()
		local group_main = userInfo:getGroupMainFromGroupCache()
		local group_tech_list = group_main and group_main.tech_list or nil
		for i,v in ipairs(land_list) do

			have_land_num = have_land_num + 1

			if v.land_index == index then

				local items = {}
				for i=1, #conf.ITEM_ID do
					items[conf.ITEM_ID[i]] = conf.ITEM_NUM[i] + Tools.getValueByTechnologyAddition(conf.ITEM_NUM[i], CONF.ETechTarget_1.kHomeBuilding, v.resource_type, CONF.ETechTarget_3_Building.kRes, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))
				end

				if not CoreItem.checkItems( items, item_list, user_info) then
					return 1
				end

				local conf = CONF.RESOURCE.get(v.resource_type)
				local build_queue = userInfo:getIdleBuildQueue(conf.CD)
				if build_queue == nil then
					return 2
				end

				build_queue.type = 2
				build_queue.index = v.land_index

				CoreItem.expendItems( items, item_list, user_info)
				v.resource_status = 1
				v.res_refresh_times = os.time()

				local user_sync = CoreItem.makeSync( items, item_list, user_info)
				user_sync.user_info.build_queue_list = user_info.build_queue_list
				user_sync.user_info.home_info = user_info.home_info
				return 0,v,user_sync
			end
		end


		if have_land_num >= home_info.max_land_num then
			return 2
		end
		local land_info = {
			land_index        = index,  
			resource_type     = typeID,
			resource_level    = 1,
			resource_status   = 2,
			res_refresh_times = os.time(),
			resource_num      = 0,
		}
		table.insert(land_list, land_info)
		return 0,land_info
	end

	
	local ret,land_info,user_sync = upgradeResource(req.land_index)

	local resp =
	{
		result        = ret,
		user_sync     = user_sync,
		land_index    = req.land_index,
		resource_type = land_info and land_info.resource_type or nil,
		building_time = land_info and land_info.res_refresh_times or nil,
	}

	local resp_buff = pb.encode("UpgradeResLandResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function remove_resource_feature(step, req_buff, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local req = pb.decode("RemoveResLandReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 1, pb.encode("RemoveResLandResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error");
	end
end

function remove_resource_do_logic(req_buff, user_name, user_info_buff)
	local pb = require "protobuf"
	local req = pb.decode("RemoveResLandReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local resp =
	{
		result = 1,
		building_time = 0,
	}

	local home_info = userInfo:getHomeInfo()
	local land_list = userInfo:getHomeLandList()
	local ret = 1
	local land_info
	for k,v in ipairs(land_list) do

		if v.land_index == req.land_index then

			v.resource_status = 3
			v.res_refresh_times = os.time()
			resp.building_time = v.res_refresh_times
			resp.result = 0
			v.resource_num = 0
			v.helped = false
			
			break
		end
	end

	local resp_buff = pb.encode("RemoveResLandResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end

function cancel_build_feature(step, req_buff, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local req = pb.decode("CancelResBuildingReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 1, pb.encode("CancelResBuildingResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function cancel_build_do_logic(req_buff, user_name, user_info_buff, item_list_buff)
	local pb = require "protobuf"
	local req = pb.decode("CancelResBuildingReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local home_info = userInfo:getHomeInfo()

	local user_sync
	local ret = 1

	for k,v in ipairs(home_info.land_info) do

		if v.land_index == req.land_index then

			if v.resource_status == 1 or v.resource_status == 3 then

				if v.resource_status == 1 then

					local conf = CONF.RESOURCE.get(v.resource_type)

					local items = {}
					for i=1, #conf.ITEM_ID do
						items[conf.ITEM_ID[i]] = conf.ITEM_NUM[i] * 60 / 100
					end

					CoreItem.addItems(items, item_list, user_info)
					user_sync = CoreItem.makeSync(items,item_list,user_info)

					--删除帮助信息
					userInfo:removeGroupHelp( CONF.EGroupHelpType.kHome, req.land_index)
				end

				userInfo:resetBuildQueue(2,v.land_index)

				v.resource_status = 2
				v.res_refresh_times = 0
				v.res_refresh_times = os.time()

				ret = 0
				user_sync = user_sync and user_sync or {}
				user_sync.user_info = user_sync.user_info and user_sync.user_info or {}
				user_sync.user_info.build_queue_list = user_info.build_queue_list
				user_sync.user_info.home_info = user_info.home_info
				break
			end
		end
	end


	local resp =
	{
		result        = ret,
		user_sync     = user_sync,
	}

	local resp_buff = pb.encode("CancelResBuildingResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function speed_up_build_feature(step, req_buff, user_name)
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("SpeedUpBuildResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function speed_up_build_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("SpeedUpBuildReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local user_sync

	local function doLogic(  )
		local home_info = userInfo:getHomeInfo()
		local land_list = userInfo:getHomeLandList()
		for k,v in ipairs(land_list) do

			if v.land_index == req.land_index then
				if v.resource_status == 1 then

					local conf = CONF.RESOURCE.get(v.resource_type)
					if not conf then
						return 1
					end
					local curTime = os.time()
					local diff = conf.CD + v.res_refresh_times - curTime
					if diff <= 0 then
						return 2
					end

					local needMoney = Tools.getSpeedUpNeedMoney(diff)
					if CoreItem.checkMoney(user_info, needMoney) == false then
						return 3
					end

					CoreItem.expendMoney(user_info, needMoney, CONF.EUseMoney.eHome_building_time)

					userInfo:upgradeHomeBuilding(v,curTime)

					user_sync = CoreItem.syncMoney(user_info)
					return  0
				end
			end
		end

		return 10
	end

	local ret = doLogic()

	local resp =
	{
		result        = ret,
		land_index    = req.land_index,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("SpeedUpBuildResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function trade_get_money_feature(step, req_buff, user_name)
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("TradeGetMoneyResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error");
	end
end

function trade_get_money_do_logic(req_buff, user_name, user_info_buff)

	
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local user_sync

	local function doLogic(  )

		local achievement_data = userInfo:getAchievementData()
		if achievement_data.recharge_real_money ==nil or achievement_data.recharge_real_money <= 0 then
			return 1
		end
		
		local building_info = userInfo:getBuildingInfo(CONF.EBuilding.kTrade)
		local conf = CONF.BUILDING_15.get(building_info.level)

		local cur_time = os.time()
		local times =  math.floor((cur_time - user_info.trade_data.last_product_time) / conf.PRODUCTION_TIME)

		if times <= 0 then
			return 2
		end

		local num = conf.PRODUCTION_NUM * times
		
		if num > conf.STORAGE then
			num = conf.STORAGE
			user_info.trade_data.last_product_time = cur_time
		else
			local new_last_time = user_info.trade_data.last_product_time + conf.PRODUCTION_TIME * times
			if user_info.trade_data.last_product_time > cur_time then
				return 3
			end
			user_info.trade_data.last_product_time = new_last_time
		end
		CoreItem.addMoney(user_info, num)
		user_sync = CoreItem.syncMoney(user_info, user_sync)


		user_sync.user_info.trade_data = user_info.trade_data
		return 0
	end

	local ret = doLogic()

	local resp = {
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("TradeGetMoneyResp", resp)

	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end