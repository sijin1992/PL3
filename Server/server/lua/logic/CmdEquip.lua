
function equip_enchase_feature(step, req_buff, user_name)
	if step == 0 then

		local resp = {
			result = -1,
		}
		return 1, Tools.encode("EquipEnchaseResp", resp)
    	elseif step == 1 then
        		return datablock.main_data + datablock.ship_list + datablock.item_list + datablock.save, user_name
    	else
        		error("something error");
   	 end
end

function equip_enchase_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	itemList:new(item_list_buff)


	local req = Tools.decode("EquipEnchaseReq", req_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	
	local resp = {
		result = result,
	}

	local resp_buff = Tools.encode("EquipEnchaseResp", resp)
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end

function equip_levelup_feature(step, req_buff, user_name)
	if step == 0 then

		local resp =
		{
		    result = -1,
		}
        		return 1, Tools.encode("EquipLevelUpResp", resp)
    	elseif step == 1 then
        		return datablock.main_data + datablock.ship_list + datablock.item_list + datablock.save, user_name
    	else
        		error("something error");
    	end
end

function equip_levelup_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	itemList:new(item_list_buff)

	local req = Tools.decode("EquipLevelUpReq", req_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local equip = require "Equip"

	local result, equip_info, item_syncs = equip:levelUp(req.id, req.add_value, user_info)
	local resp =
	{
		result = result,
		equip = equip_info,
		syncs = item_syncs,
	}
    
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()

	local resp_buff = Tools.encode("EquipLevelUpResp", resp)
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end


function ship_equip_feature(step, req_buff, user_name)
	if step == 0 then        
		local req = Tools.decode("ShipEquipReq", req_buff)
		local resp =
		{
		    result = -1,
		}
		return 1, Tools.encode("ShipEquipResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function ship_equip_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	itemList:new(item_list_buff)
	
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	
	shipList:setUserInfo(user_info)
	shipList:setItemList(item_list)
	
	local req = Tools.decode("ShipEquipReq", req_buff)

	local user_sync = {
		ship_list = {},
		equip_list = {},
	}

	local result = shipList:equip(req.ship_guid, req.equip_index_list, req.equip_guid_list, user_sync)

	if result == 0 then
		local other_user_info = UserInfoCache.get(user_info.user_name)
		if other_user_info then

			local power = shipList:getPowerFromAll()
			if power ~= other_user_info.power then
				other_user_info.power = power
				UserInfoCache.set(user_info.user_name, other_user_info)
			end
		end
	end

	local resp =
    	{
        		result = result,
        		ship_guid = req.ship_guid,
        		equip_index_list = req.equip_index_list,
        		equip_guid_list = req.equip_guid_list,
        		user_sync = user_sync,
    	}

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()	

	local resp_buff = Tools.encode("ShipEquipResp", resp)

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end

function equip_strength_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
		    result = -1,
		}
		return 1, Tools.encode("StrengthEquipResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function equip_strength_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
	local req = Tools.decode("StrengthEquipReq", req_buff)
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
	shipList:setItemList(item_list)

	
	local function doLogic(equip_guid, count)

		if count == nil then 
			count = 1
		end

		local Equip = require "Equip"

		local equip_info = Equip:getEquipInfo(equip_guid, user_info) 

		if not equip_info then
			return 1
		end

		local equipConf = CONF.EQUIP.get(equip_info.equip_id)
		local nextLevel = equip_info.strength + count
		if nextLevel > equipConf.MAX_STRENGTH then
			return 2
		end
		local items = {}

		for i=1, count do
			local nextStrengthConf = CONF.EQUIP_STRENGTH.get(equip_info.strength + i)
			for i,v in ipairs(nextStrengthConf.ITEM_ID) do
				local num = nextStrengthConf.ITEM_NUM[i] * CONF.PARAM.get(string.format("equip_strength_%d",equip_info.quality)).PARAM
				num = math.floor(num)
	
				if items[v] == nil then
					items[v] = num
				else
					items[v] = items[v] + num
				end
			end
		end

		if CoreItem.checkItems(items, item_list, user_info) == false then
	   		return 3
	   	end
		CoreItem.expendItems(items, item_list, user_info)

		equip_info.strength = nextLevel

		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		user_sync.equip_list = {}

		table.insert(user_sync.equip_list, equip_info)


		--更新活动数据
		local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
		if activity_list then
			user_sync.activity_list = {}
			for i,v in ipairs(activity_list) do
				local num = v.seven_days_data.equip_strength_count or 0
				v.seven_days_data.equip_strength_count = num + count
				table.insert(user_sync.activity_list, v)
			end
		end


		--更新每日数据
		local daily_data = CoreUser.getDailyData(user_info)
		if not daily_data.equip_strength_count then
			daily_data.equip_strength_count = count
		else
			daily_data.equip_strength_count = daily_data.equip_strength_count + count
		end

		user_sync.user_info = user_sync.user_info or {}
		user_sync.user_info.daily_data = daily_data


		return 0, user_sync
	end
	
	local ret,user_sync = doLogic(req.equip_guid, req.count)

	local resp =
	{
		result = ret,
		user_sync   = user_sync,
		equip_guid = req.equip_guid,
	}

	local resp_buff = Tools.encode("StrengthEquipResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end

function equip_resolve_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ResolveEquipResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function equip_resolve_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local req = Tools.decode("ResolveEquipReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()
	local item_list = itemList:getItemList()

	local Equip = require "Equip"

	local function doLogic( req )

		local items = {}
		if #req.equip_guid_list > 8 then
			return 1
		end

		local sync_equip_list = {}

		for i,guid in ipairs(req.equip_guid_list) do
			local equip_info = Equip:getEquipInfo(guid, user_info) 

			if not equip_info then
				return 2
			end
			if equip_info.status > 0 then
				return 3
			end
			

			local conf = CONF.EQUIP.get(equip_info.equip_id)
			
			for i,key in ipairs(conf.RESOLVE_ID) do
				Tools.addNum(key, conf.RESOLVE_NUM[i], items)
			end

			if equip_info.strength > 0 then
				local strengthConf = CONF.EQUIP_STRENGTH.get(equip_info.strength)
				for i,item_id in ipairs(strengthConf.RETURN_ITEM_ID) do
					if strengthConf.RETURN_ITEM_ID[i] > 0 then
						Tools.addNum(item_id, strengthConf.RETURN_ITEM_NUM[i] * CONF.PARAM.get(string.format("equip_strength_%d",equip_info.quality)).PARAM, items)
					end
				end
			end
			
		end

		for i,guid in ipairs(req.equip_guid_list) do
			local equip_info = Equip:getEquipInfo(guid, user_info) 
			if not Equip:removeEquip(guid, user_info) then
				return 4
			end
			equip_info.guid = -equip_info.guid
			table.insert(sync_equip_list, equip_info)
		end

		CoreItem.addItems(items, item_list, user_info)


		local get_item_list = {}
		for key,num in pairs(items) do
			local info = {
				id = key, 
				num = num,
				guid = 0,
			}
			table.insert(get_item_list, info)
		end

		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		user_sync.equip_list = sync_equip_list
		return 0, user_sync, get_item_list
	end

	local ret,user_sync, get_item_list = doLogic(req)

	local resp ={
		result = ret,
		user_sync = user_sync,
		get_item_list = get_item_list,
	}

	local resp_buff = Tools.encode("ResolveEquipResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end


function equip_create_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("CreateEquipResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function equip_create_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("CreateEquipReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local Equip = require "Equip"

	local user_sync

	local building_16_info = userInfo:getBuildingInfo(CONF.EBuilding.kForge)
	local building_16_conf = CONF.BUILDING_16.get(building_16_info.level)

	local cur_time = os.time()

	local get_equip_guid

	local function checkForgeable( equip_id )
		for i=1,building_16_info.level do
			local conf = CONF.BUILDING_16.get(i)
			if Tools.isEmpty(conf.DEBLOCKING_EQUIP) == false then
				for i,v in ipairs(conf.DEBLOCKING_EQUIP) do
					if v == equip_id then
						return true
					end
				end
			end
		end
		return false
	end

	local function startForge( req )

		
		if not checkForgeable(req.equip_id) then
			return 1
		end

		local conf = CONF.FORGEEQUIP.get(req.equip_id)
		local items = {}
		if Tools.isEmpty(conf.ITEM_ID) == false then

			for i,v in ipairs(conf.ITEM_ID) do
				items[v] = conf.ITEM_NUM[i]
			end
		end

		if Tools.isEmpty(conf.RES) == false then

			for i,v in ipairs(conf.RES) do
				local num = conf.RES[i] - building_16_conf.RES[i]
				if num > 0 then
					items[refid.res[i]] = num
				end
			end
		end

		if CoreItem.checkItems(items, item_list, user_info) == false then
			return 2
		end

		if Tools.isEmpty(user_info.forge_equip_list) then
			user_info.forge_equip_list = {}
		end 

		local forge_equip ={
			guid = Tools.getGuid(user_info.forge_equip_list),
			equip_id = req.equip_id,
			start_time = cur_time,
		}

		table.insert(user_info.forge_equip_list, forge_equip)

		CoreItem.expendItems(items, item_list, user_info)
		
		user_sync = CoreItem.makeSync(items, item_list, user_info)

		user_sync.forge_equip_list = {forge_equip}
		return 0
	end

	local function forgeComplete( req )
		local forge_equip
		if Tools.isEmpty(user_info.forge_equip_list) then
			return 11
		end 
		local index
		for i,v in ipairs(user_info.forge_equip_list) do
			if v.guid == req.forge_guid then
				forge_equip = v
				index = i
				break
			end
		end
		if forge_equip == nil then
			return 12 
		end

		local conf = CONF.FORGEEQUIP.get(forge_equip.equip_id)
		local forge_time = math.max( conf.EQUIP_TIME - building_16_conf.EQUIP_FORGE_SPEED, 0)

		user_sync = {
			user_info = {},
			equip_list = {},
			forge_equip_list = {},
		}

		if cur_time < (forge_equip.start_time + forge_time) then

			local need_money = Tools.getSpeedUpNeedMoney(forge_equip.start_time + forge_time - cur_time)

			if not CoreItem.checkMoney(user_info, need_money) then
				return 13
			end
			CoreItem.expendMoney(user_info, need_money)
			CoreItem.syncMoney(user_info, user_sync)
		end

		local equip_info = Equip:addEquip(forge_equip.equip_id, user_info)

		table.insert(user_sync.equip_list, equip_info)
		get_equip_guid = equip_info.guid

		forge_equip.guid = -forge_equip.guid 
		table.insert(user_sync.forge_equip_list, forge_equip)
		table.remove(user_info.forge_equip_list, index)

		return 0
	end

	local ret
	if req.type == 1 then
		ret = startForge(req)
	elseif req.type == 2 then
		ret = forgeComplete(req)
	end

	local resp ={
		result = ret,
		user_sync = user_sync,
		get_equip_guid = get_equip_guid,
	}

	local resp_buff = Tools.encode("CreateEquipResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function resolve_blueprint_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ResolveBlueprintResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function resolve_blueprint_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("ResolveBlueprintReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local function doLogic(req )
		local itemCount = 0
		local removeItems = {}
		for i,v in ipairs(req.item_list) do
			removeItems[v.key] = v.value
			itemCount = itemCount + v.value
		end
		if itemCount < 1 or itemCount > 8 then
			return 1
		end

		if CoreItem.checkItems(removeItems, item_list, user_info) == false then
			return 2
		end

		math.randomseed(tostring(os.time()):reverse():sub(1, 6)) 

		local addItems = {}
		for id,num in pairs(removeItems) do
			local conf = CONF.SHIP_BLUEPRINT.get(id)
			for i=1,num do
				Tools.addNum(conf.RESOLVE_ID, math.random(conf.INTERVAL_NUM[1], conf.INTERVAL_NUM[2]), addItems)
				
				if Tools.isEmpty(conf.RESOLVE_RATE) == false then
					local temp = math.random(1,100)
		
					local min = 1
					local index = 0
					for i,rate in ipairs(conf.RESOLVE_RATE) do
						max = min + rate

						if temp >= min and temp < max then
							index = i
							break
						end
						min = max
					end
		
					if index ~= 0 then
						Tools.addNum(conf.ITEM_ID[index], conf.ITEM_NUM[index], addItems)
					end
				end
			end
		end

		CoreItem.expendItems(removeItems, item_list, user_info)

		CoreItem.addItems(addItems, item_list, user_info)

		local user_sync = CoreItem.makeSync(removeItems, item_list, user_info)

		CoreItem.makeSync(addItems, item_list, user_info, user_sync)

		local get_item_list = {}
		for k,v in pairs(addItems) do
			table.insert(get_item_list, {key = k, value = v})
		end

		return 0, get_item_list, user_sync
	end

	local ret,get_item_list, user_sync = doLogic(req)

	local resp ={
		result = ret,
		user_sync = user_sync,
		get_item_list = get_item_list,
	}

	local resp_buff = Tools.encode("ResolveBlueprintResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function gem_equip_feature(step, req_buff, user_name)

	if step == 0 then        
		local req = Tools.decode("GemEquipReq", req_buff)
		local resp =
		{
		    result = -1,
		}
		return 1, Tools.encode("GemEquipResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.save, user_name
	else
		error("something error");
	end
end

function gem_equip_do_logic(req_buff, user_name, user_info_buff, ship_list_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)

	local user_info = userInfo:getUserInfo()

	shipList:setUserInfo(user_info)

	local Equip = require "Equip"
	
	local req = Tools.decode("GemEquipReq", req_buff)

	local user_sync = {
		ship_list = {},
		gem_list = {},
	}

	local function equip( req )

		local ship_info = shipList:getShipInfo(req.ship_guid)
		if not ship_info then
			return 1
		end

		local shipConf = CONF.AIRSHIP.get(ship_info.id)
		if req.index < 1 or req.index > #shipConf.HOLEOPEN_LEVEL then
			return 2
		end
		if ship_info.level < shipConf.HOLEOPEN_LEVEL[req.index] then
			return 3
		end

		local gem_info = Equip:getGemInfo(req.gem_id, user_info)
		if not gem_info then
			return 4
		end
		if gem_info.num < 1 then
			return 5
		end

		local gemConf = CONF.GEM.get(gem_info.id)
		if gemConf.TYPE ~= shipConf.HOLE[req.index] and shipConf.HOLE[req.index] ~= CONF.EGemType.kTypeAll then
			return 6
		end 

		if ship_info.gem_list[req.index] > 0 then
			local old_gem_id = ship_info.gem_list[req.index]
			Equip:addGem(old_gem_id, 1, user_info, user_sync.gem_list)
		end

		ship_info.gem_list[req.index] = gem_info.id
		Equip:removeGem(gem_info.id, 1, user_info, user_sync.gem_list)

		table.insert(user_sync.ship_list, ship_info)
		return 0
	end

	local function unequip( req )
		local ship_info = shipList:getShipInfo(req.ship_guid)
		if not ship_info then
			return 11
		end

		local shipConf = CONF.AIRSHIP.get(ship_info.id)
		if req.index < 1 or req.index > #shipConf.HOLEOPEN_LEVEL then
			return 12
		end

		if ship_info.gem_list[req.index] == 0 then
			return 13
		end

		local old_gem_id = ship_info.gem_list[req.index]
		
		Equip:addGem(old_gem_id, 1, user_info, user_sync.gem_list)

		ship_info.gem_list[req.index] = 0

		table.insert(user_sync.ship_list, ship_info)
		return 0
	end

	local ret
	if req.type == 1 then
		ret = equip(req)
	elseif req.type == 2 then
		ret = unequip(req)
	else
		ret = 999
	end

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()

	local resp_buff = Tools.encode("GemEquipResp", resp)

	return resp_buff, user_info_buff, ship_list_buff
end

function mix_gem_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("MixGemResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function mix_gem_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("MixGemReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)

	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local Equip = require "Equip"

	local gem_sync_list = {}

	local function doLogic( req )

		local gem_count = 0
		for i,v in ipairs(req.gem_list) do
			if v.num < 1 then
				return 1
			end
			gem_count = gem_count + v.num
		end
		if gem_count < 2 or gem_count > 4 then
			return 2
		end

		local rate = 0
		local temp_type = 0
		local temp_attr = 0
		local isSameType = true
		local temp_level = 0
		local isSameLevel = true
		local max_level = 0
		local gem_info_list = {}
		local gem_conf_list = {}

		for i,info in ipairs(req.gem_list) do

			local gem_info = Equip:getGemInfo(info.id, user_info)
			if gem_info == nil then
				return 3
			end
			if gem_info.num < info.num then
				return 3
			end
			gem_info_list[i] = gem_info

			local conf = CONF.GEM.get(gem_info.id)
			gem_conf_list[i] = conf

			if isSameType == true then
				if i == 1 then
					temp_type = conf.TYPE
					temp_attr = conf.ATTR_KEY
				else
					if temp_type ~= conf.TYPE or temp_attr ~= conf.ATTR_KEY then
						isSameType = false
					end
				end
			end

			if isSameLevel == true then
				if i == 1 then
					temp_level = conf.LEVEL
				else
					if temp_level ~= conf.LEVEL then
						isSameLevel = false
					end
				end
			end

			if conf.LEVEL > max_level then
				max_level = conf.LEVEL
			end
		end

		local max_level_list = {}
		for i,conf in ipairs(gem_conf_list) do
			if conf.LEVEL == max_level then
				table.insert(max_level_list, req.gem_list[i])
			end
		end

		local remain_list = {}

		local vecGemList = {}
		for i,v in ipairs(req.gem_list) do
			for i=1,v.num do
				table.insert(vecGemList, v.id)
			end
		end
		local rate = Tools.getGemListRate(vecGemList)
		local mix_result = rate >= math.random(0,100)
	
		if isSameType == true then
			if mix_result == true then
				--销毁全部 创建+1LEVEL 宝石
				local newGemID = max_level_list[1].id + 1
				if CONF.GEM.check(newGemID) == nil then
					return 4
				end

				for i,info in ipairs(req.gem_list) do

					Equip:removeGem(info.id, info.num, user_info, gem_sync_list)
				end

				Equip:addGem(newGemID, 1, user_info, gem_sync_list)
				table.insert(remain_list, {id = newGemID, num = 1})
			
			else

				if isSameLevel == true then
		
					--销毁一个 创建所销毁的宝石 -1LEVEL
					local removeIndex = math.random(1, #req.gem_list)
					if gem_conf_list[removeIndex].LEVEL > 1 then
						local newGemID = gem_info_list[removeIndex].id - 1
						Equip:addGem(newGemID, 1, user_info, gem_sync_list)

						table.insert(remain_list, {id = newGemID, num = 1})
					end

					Equip:removeGem(gem_info_list[removeIndex].id, 1, user_info, gem_sync_list)

					for i,v in ipairs(req.gem_list) do
						if removeIndex ~= i then
							table.insert(remain_list, {id = v.id, num = v.num})
						else
							if v.num - 1 > 0 then
								table.insert(remain_list, {id = v.id, num = v.num - 1})
							end
						end
					end
				
				else
					--重新按概率生成，生成1个与放置最高级宝石同等级的宝石或者生成一个与放置宝石中（最高等级-1）的宝石
					local maxIndex = math.random(1, #max_level_list)
					local newGemID = 0
					if rate >= math.random(0,100) then
						newGemID = max_level_list[maxIndex].id
					else
						newGemID = max_level_list[maxIndex].id - 1
					end
					for i,info in ipairs(req.gem_list) do
						Equip:removeGem(info.id, info.num, user_info, gem_sync_list)
					end
					Equip:addGem(newGemID, 1, user_info, gem_sync_list)
					table.insert(remain_list, {id = newGemID, num = 1})
				end
			end
		else
			if mix_result == true then

				--销毁全部 创建+1LEVEL 随机TYPE宝石
				for i,info in ipairs(req.gem_list) do
					Equip:removeGem(info.id, info.num, user_info, gem_sync_list)
				end

				local randType = math.random(1, CONF.EGemType.kTypeAll - 1)
				local id_list = CONF.GEM.get(string.format("TYPE%d", randType))[string.format("LEVEL%d", max_level)]

				if Tools.isEmpty(id_list) == true then
					return 5
				end
				local newGemID = id_list[math.random(1, #id_list)] + 1
				if CONF.GEM.check(newGemID) == nil then
					return 6
				end

				
				Equip:addGem(newGemID, 1, user_info, gem_sync_list)

				table.insert(remain_list, {id = newGemID, num = 1})
		
			else
	
				if isSameLevel == true then
					--销毁一个  创建所销毁的宝石 -1LEVEL 
					local removeIndex = math.random(1, #req.gem_list)
					if gem_conf_list[removeIndex].LEVEL > 1 then
						local newGemID = req.gem_list[removeIndex].id - 1
						Equip:addGem(newGemID, 1, user_info, gem_sync_list)

						table.insert(remain_list, {id = newGemID, num = 1})
					end
					Equip:removeGem(req.gem_list[removeIndex].id, 1, user_info, gem_sync_list)

					for i,v in ipairs(req.gem_list) do
						if removeIndex ~= i then
							table.insert(remain_list, {id = v.id, num = v.num})
						else
							if v.num - 1 > 0 then
								table.insert(remain_list, {id = v.id, num = v.num - 1})
							end
						end
					end
				else
					--重新按概率生成，生成1个与放置最高级宝石同等级的随机类型宝石或者生成一个与放置宝石中（最高等级-1）的相同类型宝石
					local maxIndex = math.random(1, #max_level_list)
					local newGemID = 0
					if rate >= math.random(0,100) then
						local conf = CONF.GEM.get(max_level_list[maxIndex].id)

						local randType = math.random(1, CONF.EGemType.kTypeAll - 1)
						local id_list = CONF.GEM.get(string.format("TYPE%d", randType))[string.format("LEVEL%d", conf.LEVEL)]
						if Tools.isEmpty(id_list) == true then
							return 7
						end
						newGemID = id_list[math.random(1, #id_list)]
					else
						newGemID = max_level_list[maxIndex].id - 1
					end
					for i,info in ipairs(req.gem_list) do
						Equip:removeGem(info.id, info.num, user_info, gem_sync_list)
					end
					Equip:addGem(newGemID, 1, user_info, gem_sync_list)
					table.insert(remain_list, {id = newGemID, num = 1})
				end
			end
		end
		return 0, mix_result, remain_list
	end

	local ret
	local mix_result
	local all_remain_list = {}

	if req.count == nil or req.count < 1 then
		req.count = 1
	end

	if req.count > 999 then
		req.count = 999
	end

	local function addGem( info )
		for i,v in ipairs(all_remain_list) do
			if v.id == info.id then
				v.num = v.num + info.num
				return
			end
		end
		table.insert(all_remain_list, info)
	end

	local successed = false
	for i=1,req.count do
		ret, mix_result, remain_list = doLogic(req)
		if mix_result == true then
			successed = true

			--广播
			for i,v in ipairs(remain_list) do
				local gem_conf = CONF.GEM.get(v.id)
				if gem_conf.LEVEL >= CONF.PARAM.get("broadcast_gem").PARAM then
					sendBroadcast(user_info.user_name, Lang.world_chat_sender, string.format(Lang.gem_mix_board_msg, user_info.nickname, gem_conf.LEVEL, CONF.STRING.get(gem_conf.NAME_ID).VALUE))
				end
			end
		end
		if ret ~= 0 then
			gem_sync_list = nil
			break
		end
		if Tools.isEmpty(remain_list) == false then
			for i,info in ipairs(remain_list) do
				addGem(info)
			end
		end
	end
	
	local resp ={
		result = ret,
		user_sync = {
			gem_list = gem_sync_list,
		},
		mix_result = mix_result,
		remain_list = all_remain_list,
	}
	local resp_buff = Tools.encode("MixGemResp", resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end
