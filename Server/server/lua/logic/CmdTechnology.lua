function upgrade_technology_feature(step, req_buff, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local req = pb.decode("UpgradeTechReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 1, pb.encode("UpgradeTechResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error")
	end
end

function upgrade_technology_do_logic(req_buff, user_name, user_info_buff, item_list_buff)
	local pb = require "protobuf"
	local req = pb.decode("UpgradeTechReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local function technologyUpgrade(tech_id)
		local tech_data = userInfo:getTechnologyInfo()
		local tech_list = userInfo:getTechnologyList()

		if tech_data.upgrade_busy ~= 0 then
			return 1
		end

		local conf = CONF.TECHNOLOGY.get(tech_id)   
 
		--检查build
		local build_info = userInfo:getBuildingInfo(CONF.EBuilding.kTechnology)

		if build_info.level < conf.TECHNOLOGY_BUILDING_LEVEL then
			return 2
		end

		--检查前置科技
	   
		if Tools.isEmpty(conf.PRE_TECHNOLOGY) == false then
			local condition = true
			for i,v in ipairs(conf.PRE_TECHNOLOGY) do
				if v == 0 then
					break
				end

				local have_condition = false
				for k,m in ipairs(tech_list) do
					local v_z,v_x = math.modf(v/100);
					local t_z,t_x = math.modf(m.tech_id/100);
					if v_z ==  t_z and t_x >= v_x then
						have_condition = true
					end
				end

				if have_condition == false then
					condition = false
				end
			end
			if condition == false then
				return 3
			end
		end

		

		--检查资源  
		local items = {}
		for i=1, #conf.ITEM_ID do
			local itemNum = conf.ITEM_NUM[i]
			--检查是否有技能减少消费
			itemNum = itemNum + Tools.getValueByTechnologyAddition(itemNum, CONF.ETechTarget_1.kTechnology, 0, CONF.ETechTarget_3_Building.kRes, tech_list, nil, PlanetCache.GetTitleTech(user_name))
			items[conf.ITEM_ID[i]] = itemNum
		end

		if not CoreItem.checkItems( items, item_list, user_info) then
			return 4
		end

		CoreItem.expendItems( items, item_list, user_info)

		local tech_info =
		{
			tech_id = tech_id,
			begin_upgrade_time = os.time(),
		}
		table.insert(tech_list, tech_info)

		tech_data.upgrade_busy = 1
		tech_data.tech_id = tech_id

		local user_sync = CoreItem.makeSync( items, item_list, user_info)
		user_sync.user_info.tech_data = tech_data

		return 0, tech_info, user_sync
	end

	local ret, tech_info, user_sync =  technologyUpgrade(req.tech_id)

	local resp =
	{
		result             = ret,
		user_sync          = user_sync,
		tech_id            = req.tech_id,
		upgrade_begin_time = tech_info and tech_info.begin_upgrade_time or 0,
	}

	local resp_buff = pb.encode("UpgradeTechResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function get_technology_feature(step, req_buff, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local req = pb.decode("GetTechnologyReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 1, pb.encode("GetTechnologyResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error")
	end
end

function get_technology_do_logic(req_buff, user_name, user_info_buff)
	local pb = require "protobuf"
	local req = pb.decode("GetTechnologyReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local tech_data, hasUpgrade = userInfo:getTechnologyInfo()
	local resp =
	{
		result = 0,
		user_sync = {
			user_info = {
				tech_data = tech_data,
				activity_list = user_info.activity_list,
			},
		},
		hasUpgrade = hasUpgrade,
	}

	local resp_buff = pb.encode("GetTechnologyResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end


function speed_up_technology_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("SpeedUpTechnologyResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error")
	end
end

function speed_up_technology_do_logic(req_buff, user_name, user_info_buff, item_list_buff)
	local req = Tools.decode("SpeedUpTechnologyReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local function doLogic( )
		local tech_list = userInfo:getTechnologyList()  
		local tech_data = userInfo:getTechnologyInfo()


		if tech_data.upgrade_busy <= 0 then
			return 1
		end

		for i,v in ipairs(tech_list) do

			if v.tech_id == tech_data.tech_id and v.tech_id == req.tech_id then
				local conf = CONF.TECHNOLOGY.get(v.tech_id)

				--检查是否有技能减少CD
				local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kTechnology, 0, CONF.ETechTarget_3_Building.kCD, tech_list, nil, PlanetCache.GetTitleTech(user_name))

				local diff = cd + v.begin_upgrade_time - os.time()
				if diff <= 0 then
					return 2
				end

				local needMoney = Tools.getSpeedUpNeedMoney(diff)

				if CoreItem.checkMoney(user_info, needMoney) == false then
					return 3
				end

				CoreItem.expendMoney(user_info, needMoney, CONF.EUseMoney.eTechnology_speed)

				userInfo:upgradeTechnology(v)

				return 0
			end
		end

		return 10
	end

	local ret = doLogic()
	
	local resp =
	{
		result = ret,
		user_sync = { 
			user_info = {
				tech_data = userInfo:getTechnologyInfo(),
				money = user_info.money,
				activity_list = user_info.activity_list,
			},
	   	},  
	}

	local resp_buff = Tools.encode("SpeedUpTechnologyResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end