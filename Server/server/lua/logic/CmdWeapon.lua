local Bit = require "Bit"
function change_lineup_feature(step, req_buff, user_name)
	if step == 0 then

		local req = Tools.decode("ChangeLineupReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ChangeLineupResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.save, user_name
	else
		error("something error");
	end
end

function change_lineup_do_logic(req_buff, user_name, user_info_buff, ship_list_buff)

	local req = Tools.decode("ChangeLineupReq", req_buff)
	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()

	shipList:setUserInfo(user_info)

	local building_14_conf = CONF.BUILDING_14.get(userInfo:getBuildingInfo(CONF.EBuilding.kWarWorkshop).level)

	local result = -1
	local user_sync = {}
	if req.type == 1 then

		local count = 0
		for i,v in ipairs(req.lineup) do
			if v > 0 then
				count = count + 1
			end
		end

		
		if count > building_14_conf.AIRSHIP_NUM or count <= 0 then
			result = 1
		else
			result, user_sync.ship_list = shipList:changeLineup(user_info, req.lineup)
		end

	elseif req.type == 2 then

		local count = 0
		for i,v in ipairs(req.lineup) do
			if v > 0 then
				count = count + 1
			end
		end
		local teamNum = CONF.PLAYERLEVEL.get(user_info.level).DEFAULT_TEAM

		if count > building_14_conf.AIRSHIP_NUM or count <= 0 then
			result = 1
		elseif req.index > teamNum then
			result = 1
		else
			if Tools.isEmpty(user_info.preset_lineup_list) == true then

				user_info.preset_lineup_list = {}
			end

			for i=1,req.index do

				if Tools.isEmpty(user_info.preset_lineup_list[i]) == true then
					user_info.preset_lineup_list[i] = {ship_guid_list = {0,0,0,0,0,0,0,0,0,}}
				end
			end
			user_info.preset_lineup_list[req.index] = {
				ship_guid_list = req.lineup
			}

			if req.line_name then
				user_info.preset_lineup_list[req.index].line_name = req.line_name
			end

			user_sync.user_info = {
				preset_lineup_list = user_info.preset_lineup_list,
			}

			result = 0
		end
	elseif req.type == 3 then
		local teamNum = CONF.PLAYERLEVEL.get(user_info.level).DEFAULT_TEAM
		if req.index > teamNum or not req.line_name then
			result = 1
		else
			for i=1,req.index do
				if Tools.isEmpty(user_info.preset_lineup_list[i]) == true then
					user_info.preset_lineup_list[i] = {ship_guid_list = {0,0,0,0,0,0,0,0,0,}}
				end
			end
			
			user_info.preset_lineup_list[req.index] = 
			{
				ship_guid_list = user_info.preset_lineup_list[req.index].ship_guid_list,
				line_name = req.line_name,
			}

			user_sync.user_info = {
				preset_lineup_list = user_info.preset_lineup_list,
			}

			result = 0
		end
		
	end

	local other_user_info = UserInfoCache.get(user_info.user_name)
	if other_user_info then
		local power = shipList:getPowerFromAll()
		if power ~= other_user_info.power then
			other_user_info.power = power
			UserInfoCache.set(user_info.user_name, other_user_info)
		end
	end

	local resp = { 
		result = result,
		user_sync = user_sync,
		lineup = user_info.lineup,
		type = req.type,
	}

	local resp_buff = Tools.encode("ChangeLineupResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff
end

function change_weapon_feature(step, req_buff, user_name)
	if step == 0 then
        		local req = Tools.decode("ChangeWeaponReq", req_buff)
		local resp =
		{
			result = -1,
		}
        		return 1, Tools.encode("ChangeWeaponResp", resp)
    	elseif step == 1 then
       		return datablock.user_info + datablock.ship_list + datablock.save, user_name
    	else
        		error("something error");
    	end
end

function change_weapon_do_logic(req_buff, user_name, user_info_buff, ship_list_buff)

	local req = Tools.decode("ChangeWeaponReq", req_buff)
	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()

	shipList:setUserInfo(user_info)

	local ret = shipList:changeWeapon(req.ship_id , req.weapon_list)

	local user_sync = {}

	if ret == 0 then
		ship_info = shipList:getShipInfo(req.ship_id)
		ship_guid = ship_info.guid
		weapon_list = ship_info.weapon_list
		user_sync.ship_list = {ship_info}
		--user_sync.weapon_list = user_info.weapon_list
	end

	local other_user_info = UserInfoCache.get(user_info.user_name)
	if other_user_info then
		local power = shipList:getPowerFromAll()
		if power ~= other_user_info.power then
			other_user_info.power = power
			UserInfoCache.set(user_info.user_name, other_user_info)
		end
	end

	local resp =
	{
		result = ret,
		ship_id = ship_guid,
		weapon_list = weapon_list,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ChangeWeaponResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff
end

function weapon_upgrade_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("WeaponUpgradeResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function weapon_upgrade_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("WeaponUpgradeReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local ret
	local new_weapon_id
	local user_sync

	if req.type == 0 then
		if req.guid and  req.weapon_id then
			ret, new_weapon_id, user_sync = userInfo:upgradeWeapon(req.guid , req.weapon_id , item_list)
		end 
	elseif req.type == 1 then
		user_sync = {
			user_info = {
				weapon_list = userInfo:getWeaponList()
			}
		}
	end

	local resp =
	{
		result = ret,
		guid   = req.guid,
		type = req.type,
		weapon_id = new_weapon_id,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("WeaponUpgradeResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function get_ship_list_feature(step, req_buff, user_name)
	if step == 0 then

	        local req = Tools.decode("GetShipListReq", req_buff)
	        local resp =
	        {
	        	result = -1,
	        }
	        return 1, Tools.encode("GetShipListResp", resp)
    	elseif step == 1 then
        		return datablock.user_info + datablock.ship_list + datablock.save, user_name
    	else
       		error("something error");
    	end
end

function get_ship_list_do_logic(req_buff, user_name, user_info_buff, ship_list_buff)
	local pb = require "protobuf"
	local req = pb.decode("GetShipListReq", req_buff)
    	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()

	local resp =
	{
		result = 0,
	}

	local ship_id = req.ship_id
	if ship_id > 0 then
		resp.ship_info = shipList:getShipInfo(ship_id)
	else
		resp.ship_list = ship_list
	end

	local resp_buff = pb.encode("GetShipListResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff
end

function ship_develope_feature(step, req_buff, user_name)
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ShipDevelopeResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function ship_develope_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
	local req = Tools.decode("ShipDevelopeReq", req_buff)

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

	local function create( req )

		local conf = CONF.AIRSHIP.get(req.ship_id)

		if Tools.isEmpty(conf.BLUEPRINT) == true then
			return 1
		end


		local items = {}
		for i,v in ipairs(conf.BLUEPRINT) do
			items[v] = conf.BLUEPRINT_NUM[i]
		end

		if CoreItem.checkItems(items, item_list, user_info) == false then
			return 2
		end

		CoreItem.expendItems(items, item_list, user_info)

		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		local ship_info = shipList:shipCreate( req.ship_id, user_sync)
		if ship_info == nil then
			return 3
		end


		local achievement_data = userInfo:getAchievementData()
		if (achievement_data.first_develop_ship == nil or achievement_data.first_develop_ship == false) and user_info.level > 3 then
			if (CoreUser.getNewHandGiftBag( user_info )) then
				achievement_data.first_develop_ship = true
			end
		end

		for i,id in ipairs(CONF.PARAM.get("broadcast_get_ship").PARAM) do
			if req.ship_id == id then
				--发送广播
				sendBroadcast(user_info.user_name, Lang.world_chat_sender, string.format(Lang.get_ship_board_msg, user_info.nickname, CONF.STRING.get(conf.NAME_ID).VALUE))
				break
			end
		end


		return 0, user_sync, ship_info.id, ship_info.guid
	end

	local ret, user_sync, ship_id, ship_guid = create(req)

	local resp =
	{
		result = ret,
		user_sync = user_sync,
		ship_guid = ship_guid,
		ship_id = ship_id,
	}

	local resp_buff = Tools.encode("ShipDevelopeResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end

function blueprint_develope_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("BlueprintDevelopeResp", resp)
	elseif step == 1 then
	    	return datablock.user_info + datablock.item_list + datablock.save, user_name
	else
	    	error("something error");
	end
end

function blueprint_develope_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("BlueprintDevelopeReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local user_sync

	local blueprint_conf = CONF.BLUEPRINT.get(req.blueprint_id)

	local building_info = userInfo:getBuildingInfo(CONF.EBuilding.kShipDevelop)

	local cur_time = os.time()

	local crit

	local function checkCondition( blueprint_id )

		for i=1,building_info.level do
			local conf = CONF.BUILDING_3.get(i)
			if Tools.isEmpty(conf.BLUEPRINT_LIST) == false then
				for i,id in ipairs(conf.BLUEPRINT_LIST) do
					if id == blueprint_id then
						return true
					end
				end
			end
		end
		return false
	end

	local function develope( )

		if checkCondition(req.blueprint_id) ~= true then
			return 1
		end

		if blueprint_conf == nil then
			return 2
		end

		if blueprint_conf.MATERIAL_ID == nil or blueprint_conf.MATERIAL_ID == "" then
			return 3
		end

		if Tools.isEmpty(user_info.blueprint_list) == true then
			user_info.blueprint_list = {}
		end
		local building_conf = CONF.BUILDING_3.get(building_info.level)
		local vipConf = CONF.VIP.get(user_info.vip_level)
		if #user_info.blueprint_list >= (building_conf.QUEUE + vipConf.ADD_RAD_QUEUE) then
			return 4
		end
		for i,v in ipairs(user_info.blueprint_list) do
			if v.blueprint_id == req.blueprint_id then
				return 5
			end
		end

		local items = {}
		for i,v in ipairs(blueprint_conf.MATERIAL_ID) do
			items[v] = blueprint_conf.MATERIAL_NUM[i]
		end

		if CoreItem.checkItems(items, item_list, user_info) == false then
			return 6
		end

		
		local info = {
			blueprint_id = req.blueprint_id,
			start_time = cur_time,
		}
		table.insert(user_info.blueprint_list, info)

		CoreItem.expendItems(items, item_list, user_info)

		user_sync = CoreItem.makeSync(items, item_list, user_info)

		user_sync.user_info.blueprint_list = user_info.blueprint_list

		return 0
	end

	local function finish( )

		if blueprint_conf == nil then
			return 11
		end

		local index
		for i,v in ipairs(user_info.blueprint_list) do
			if v.blueprint_id == req.blueprint_id then
				index = i
				break
			end
		end
		if index == nil then
			return 12
		end

		if user_info.blueprint_list[index].start_time + blueprint_conf.TIME > cur_time then
			
			return 13
		end

		local items = {}
		local addition = 0

		local achievement_data = userInfo:getAchievementData()
		if achievement_data.first_develop_blueprint == nil or achievement_data.first_develop_blueprint == false then
			crit = true
			achievement_data.first_develop_blueprint = true
		else
			local vipConf = CONF.VIP.get(user_info.vip_level)
			local nowcrit = blueprint_conf.CRIT 
			if vipConf then
				nowcrit = nowcrit + vipConf.EXTRA_BLUEPRINT_CRIT 
			end
			crit = math.random(1, 100) < nowcrit
		end
		
		if crit then
			addition = blueprint_conf.CRIT_NUM
		end
		items[req.blueprint_id] = 1 + addition

		if CoreItem.addItems( items, item_list, user_info) == false then
			return 14
		end

		local daily_data = CoreUser.getDailyData(user_info)
		local da_count = daily_data.blueprint_count
		if da_count == nil then
			da_count = {}
		end
		local bHave = false
		if Tools.isEmpty(da_count) == false then
			for _,v in ipairs(da_count) do
				if v.key == req.blueprint_id then
					bHave = true
					v.value = v.value + items[req.blueprint_id]
				end
			end
		end
		if not bHave then
			local point = 
			{
				key=req.blueprint_id,
				value=items[req.blueprint_id],
			}
			table.insert(da_count,point)
		end
		user_info.daily_data.blueprint_count = da_count
		
		bHave = false
		local ac_count = achievement_data.blueprint_count
		if ac_count == nil then
			ac_count = {}
		end
		if Tools.isEmpty(ac_count) == false then
			for _,v in ipairs(ac_count) do
				if v.key == req.blueprint_id then
					bHave = true
					v.value = v.value + items[req.blueprint_id]
				end
			end
		end
		if not bHave then
			local point = 
			{
				key=req.blueprint_id,
				value=items[req.blueprint_id],
			}		
			table.insert(ac_count,point)
		end
		user_info.achievement_data.blueprint_count = ac_count

		user_sync = CoreItem.makeSync(items, item_list, user_info)
		user_sync.user_info.blueprint_list = user_info.blueprint_list
		user_sync.user_info.daily_data = user_info.daily_data
		user_sync.user_info.achievement_data =  user_info.achievement_data

		table.remove(user_info.blueprint_list, index)

		return 0 , 1 + addition
	end

	local function doTimer()
		if blueprint_conf == nil then
			return 11
		end
		local index
		for i,v in ipairs(user_info.blueprint_list) do
			if v.blueprint_id == req.blueprint_id then
				index = i
				break
			end
		end
		if index == nil then
			return 12
		end

		local diff = blueprint_conf.TIME + user_info.blueprint_list[index].start_time -cur_time 
		if diff <= 0 then
			return 13
		end
		local needMoney = Tools.getSpeedShipNeedMoney(diff)
		if needMoney <= 0 then
			return 14
		end
		if CoreItem.checkMoney(user_info, needMoney) == false then
			return 15
		end

		CoreItem.expendMoney(user_info, needMoney, CONF.EUseMoney.eBlueprint_speed)
		user_sync = CoreItem.syncMoney(user_info)
		user_info.blueprint_list[index].start_time = user_info.blueprint_list[index].start_time - blueprint_conf.TIME - 300
		user_sync.user_info.blueprint_list = user_info.blueprint_list

		return 0
	end

	local function clearship()
		if blueprint_conf == nil then
			return 2
		end

		if blueprint_conf.MATERIAL_ID == nil or blueprint_conf.MATERIAL_ID == "" then
			return 3
		end

		local index
		for i,v in ipairs(user_info.blueprint_list) do
			if v.blueprint_id == req.blueprint_id then
				index = i
				break
			end
		end
		if index == nil then
			return 12
		end

		
		
		local items = {}
		for i,v in ipairs(blueprint_conf.MATERIAL_ID) do
			items[v] = blueprint_conf.MATERIAL_NUM[i]
		end

		CoreItem.addItems(items, item_list, user_info)
		user_sync = CoreItem.makeSync(items, item_list, user_info)
		table.remove(user_info.blueprint_list,index)
		user_sync.user_info.blueprint_list = user_info.blueprint_list

		return 0
	end

	local ret
	local num
	if req.type == 1 then
		ret = develope()
	elseif req.type == 2 then
		ret,num = finish()
	elseif req.type == 3 then
		ret = doTimer()
	elseif req.type == 4 then
		ret = clearship()
	end

	local resp =
	{
		result = ret,
		user_sync = user_sync,
		blueprint_id = req.blueprint_id,
		type = req.type,
		crit = crit,
		num = num,
	}

	local resp_buff = Tools.encode("BlueprintDevelopeResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, item_list_buff
end

function ship_break_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ShipBreakResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.item_list + datablock.save, user_name
	else
		error("something error")
	end
end

function ship_break_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
	local req = Tools.decode("ShipBreakReq", req_buff)
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

	local user_sync = {
		user_info  = {},
		item_list  = {},
		ship_list = {},
	}

	local ret, ship_break, user_sync = shipList:shipBreak(req.ship_guid, user_sync)

	if ret == 0 then
		local daily_data = CoreUser.getDailyData(user_info)
		if not daily_data.ship_break_count then
			daily_data.ship_break_count = 1
		else
			daily_data.ship_break_count = daily_data.ship_break_count + 1
		end
		user_sync.user_info.daily_data = daily_data

		if ship_break >= CONF.PARAM.get("broadcast_breakthrough").PARAM then
			--发送广播
			local ship = shipList:getShipInfo(req.ship_guid)
			sendBroadcast(user_info.user_name, Lang.world_chat_sender, string.format(Lang.ship_break_board_msg, user_info.nickname, CONF.STRING.get(CONF.AIRSHIP.get(ship.id).NAME_ID).VALUE, ship_break))
		end
	end



	local resp =
	{
		result = ret,
		user_sync = user_sync,
		ship_guid = req.ship_guid,
		ship_break = ship_break,
	}

	local resp_buff = Tools.encode("ShipBreakResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end


function ship_add_exp_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ShipAddExpResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function ship_add_exp_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
	local req = Tools.decode("ShipAddExpReq", req_buff)
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

	local ret, user_sync = shipList:shipUserItemAddExp(req.ship_guid, req.item_id_list, req.item_num_list)

	local resp =
	{
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ShipAddExpResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end


function resolve_equip_feature(step, req_buff, user_name)
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

function resolve_equip_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
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
	shipList:setUserInfo(user_info)
	shipList:setItemList(item_list)

	local user_sync = {
		user_info  = {},
		item_list  = {},
		equip_list = {},
	}       
	local ret = shipList:resolveEquip(req.equip_index, req.equip_guid, user_sync)

	local resp =
	{
		result      = ret,
		user_sync   = user_sync,
		equip_index = req.equip_index,
		equip_guid  = req.equip_guid,
	}

	local resp_buff = Tools.encode("ResolveEquipResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end


function ship_fix_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ShipFixResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.save, user_name
	else
		error("something error");
	end
end

function ship_fix_do_logic(req_buff, user_name, user_info_buff, ship_list_buff)
	local req = Tools.decode("ShipFixReq", req_buff)
	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()

	shipList:setUserInfo(user_info)

	local curTime = os.time()

	local user_sync = {ship_list = {}}

	local group_main = userInfo:getGroupMainFromGroupCache()

	local tech_list = userInfo:getTechnologyList()

	local group_tech_list = group_main and group_main.tech_list or nil

	local function checkShips(req, user_sync)
		if Tools.isEmpty(req.guids) == true then
			return 1
		end
		
		for _,guid in ipairs(req.guids) do
			local ship_info = shipList:getShipInfo(guid)
	
			if Bit:has(ship_info.status, CONF.EShipState.kFix) == true then
				local fix_time = Tools.getFixShipDurableTime( ship_info, user_info, tech_list, group_tech_list)

				if curTime >= ship_info.start_fix_time + fix_time then
					ship_info.status = Bit:remove(ship_info.status, CONF.EShipState.kFix)
					ship_info.start_fix_time = nil
					ship_info.durable = Tools.getShipMaxDurable(ship_info)
					table.insert(user_sync.ship_list, ship_info)
				end
			end
		end
		return 0
	end


	local function fixShips(req, user_sync)
		local needGold = 0
		local ships = {}
		for i,guid in ipairs(req.guids) do
			local ship_info = shipList:getShipInfo(guid)
			if ship_info == nil then
				return 11
			end

			if Bit:has(ship_info.status, CONF.EShipState.kOuting) == true or Bit:has(ship_info.status, CONF.EShipState.kFix) == true then
				return 11
			end

			if Bit:has(ship_info.status, CONF.EShipState.kFix) == false then
				needGold = needGold + Tools.getFixShipDurableGold( ship_info )
				table.insert(ships, ship_info)
			end
		end

		if CoreItem.checkRes(user_info, 1, needGold) == false then
			return 12
		end

		for i,ship_info in ipairs(ships) do
			-- if Bit:has(ship_info.status, CONF.EShipState.kLineup) == false then
			-- 	for index=1,#user_info.lineup do
			-- 		if user_info.lineup[index] == ship_info.guid then
			-- 			user_info.lineup[index] = 0
			-- 		end
			-- 	end
			-- end
			ship_info.status = Bit:add(ship_info.status, CONF.EShipState.kFix)
			ship_info.start_fix_time = curTime

			-- if Tools.isEmpty(user_info.trial_data.area_list) == false then
			-- 	for _,area in ipairs(user_info.trial_data.area_list) do
			-- 		for i,v in ipairs(area.lineup) do
			-- 			if v == ship_info.guid then
			-- 				area.lineup[i] = 0
			-- 				break
			-- 			end
			-- 		end
			-- 	end
			-- end
		end

		CoreItem.expendRes(user_info, 1, needGold)

		user_sync.ship_list = ships
		user_sync.user_info = {
			res = user_info.res,
			--lineup = user_info.lineup,
			trial_data = user_info.trial_data,
		}
		CoreItem.syncRes(user_info, user_sync)
		return 0
	end

	local function cancelFixShip( req, user_sync )

		for i,guid in ipairs(req.guids) do
			local ship_info = shipList:getShipInfo(guid)
			if ship_info == nil then
				return 111
			end
			if Bit:has(ship_info.status, CONF.EShipState.kFix) == true then
				ship_info.status = Bit:remove(ship_info.status, CONF.EShipState.kFix)
				ship_info.start_fix_time = nil

				table.insert(user_sync.ship_list, ship_info)
			end
		end
		return 0
	end

	local function speedUpFixShip( req, user_sync )
		if Tools.isEmpty(req.guids) == true then
			return 1111
		end
		local ships = {}
		local needMoney = 0
		for _,guid in ipairs(req.guids) do
			local ship_info = shipList:getShipInfo(guid)
			if Bit:has(ship_info.status, CONF.EShipState.kFix) == true then
				local fix_time = Tools.getFixShipDurableTime( ship_info, user_info, tech_list, group_tech_list)
				local need_time = ship_info.start_fix_time + fix_time - curTime
				if need_time > 0  then
					if need_time > CONF.PARAM.get("free_fix_ship_time").PARAM then
						needMoney = needMoney + Tools.getSpeedUpNeedMoney(need_time)
					end
					table.insert(ships, ship_info)
				end
			end
		end

		-- if needMoney == 0 then
		-- 	return 1112
		-- end

		if CoreItem.checkMoney(user_info, needMoney) == false then
			return 1113
		end

		CoreItem.expendMoney(user_info, needMoney, CONF.EUseMoney.eShip_fix)

		for i,ship_info in ipairs(ships) do
			ship_info.status = Bit:remove(ship_info.status, CONF.EShipState.kFix)
			ship_info.start_fix_time = nil
			ship_info.durable = Tools.getShipMaxDurable(ship_info)
		end
		user_sync.ship_list = ships
		user_sync.user_info = {
			money = user_info.money,
		}

		return 0
	end

	local ret
	if req.type == 1 then
		ret = checkShips(req, user_sync)
	elseif req.type == 2 then
		ret = fixShips(req, user_sync)
	elseif req.type == 3 then
		ret = cancelFixShip(req, user_sync)
	elseif req.type == 4 then
		ret = speedUpFixShip(req, user_sync)
	else
		ret = -11
	end

	local resp =
	{
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ShipFixResp", resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff
end

function ship_add_energy_exp_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ShipAddEnergyExpResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function ship_add_energy_exp_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local req = Tools.decode("ShipAddEnergyExpReq", req_buff)

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

	local function doLogic( )

		local ret_min_list = CONF.PARAM.get("energy_res_min").PARAM

		local ret_param_list = CONF.PARAM.get("energy_res_param").PARAM

		local exp = 0

		local items = {}

		local ship_info = shipList:getShipInfo(req.ship_guid)

		if Bit:has(ship_info.status, CONF.EShipState.kOuting) == true then
			return 1
		end
		local now_time = os.time()
		if user_info.ship_energy_time_lock ~= nil and user_info.ship_energy_time_lock > 0 and user_info.ship_energy_end_time >= now_time then
			return 5
		end
		user_info.ship_energy_time_lock = -1
		local isEnough = false
		for i=2,4 do

			if req.res_list[i] > ret_min_list[i] then
				isEnough = true
			end
		end
		if isEnough == false then
			return 2
		end

		for i=1,4 do
			if req.res_list[i] == nil then
				return 1
			end
			
			exp = exp + ret_param_list[i] * req.res_list[i]

			items[refid.res[i]] = req.res_list[i]
		end

		if CoreItem.checkItems(items, item_list, user_info) == false then
			return 3
		end

		local conf = CONF.ENERGYLEVEL.check(ship_info.energy_level + 1)
		if conf == nil then
			return 6
		end

		if conf.ENERGY_EXP_ALL ~= ship_info.energy_exp + exp then
			return 7
		end

		local addtime = exp * CONF.PARAM.get("energy_add_exp_time").PARAM
		if user_info.ship_energy_end_time < now_time then
			user_info.ship_energy_end_time = now_time
		end
		user_info.ship_energy_end_time = user_info.ship_energy_end_time + addtime
		if user_info.ship_energy_end_time - now_time > CONF.PARAM.get("energy_lock_time").PARAM then
			user_info.ship_energy_time_lock = 1
		end

		CoreShip.setExp(exp, ship_info)

		CoreItem.expendItems(items, item_list, user_info)

		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		user_sync.ship_list = {ship_info}

		user_sync.user_info.ship_energy_end_time = user_info.ship_energy_end_time
		user_sync.user_info.ship_energy_time_lock = user_info.ship_energy_time_lock

		return 0, user_sync
	end

	local ret, user_sync = doLogic()

	local resp =
	{
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ShipAddExpResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end


function ship_lock_energy_time_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ShipLockEnergyTimeResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error");
	end
end

function ship_lock_energy_time_do_logic(req_buff, user_name, user_info_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local function doLogic(  )	

		if user_info.ship_energy_time_lock == nil or user_info.ship_energy_time_lock < 1 then
			return 2
		end

		local time = user_info.ship_energy_end_time - os.time()
		if time <= 0 then
			return 2
		end

		local need = Tools.getSpeedEnergyMoney(time)

		if CoreItem.checkMoney(user_info, need) == false then
			return 3
		end
		CoreItem.expendMoney(user_info, need , CONF.EUseMoney.eGroup_contribute_cd)

		user_info.ship_energy_end_time = 1
		user_info.ship_energy_time_lock = -1

		local user_sync = {
			user_info = {
				money = user_info.money,
				ship_energy_end_time = user_info.ship_energy_end_time,
				ship_energy_time_lock = user_info.ship_energy_time_lock,
			},
		}

		return 0, user_sync
	end

	local ret, user_sync = doLogic()

	local resp =
	{
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("ShipLockEnergyTimeResp", resp)
	user_info_buff = userInfo:getUserBuff()

	return resp_buff, user_info_buff
end