
local Bit = require "Bit"

local function getShipByArmy(guid, army )
	if Tools.isEmpty(army.ship_list) == true then
		return nil
	end
	for i,v in ipairs(army.ship_list) do
		if v.guid == guid then
			return v
		end
	end
	return nil
end

function planet_get_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("PlanetGetResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function planet_get_do_logic(req_buff, user_name, user_info_buff)
	local req = Tools.decode("PlanetGetReq", req_buff)
	--Tools.print_t(req)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()

	local cur_time = os.time()
	local function installElement(element)
	
		if element == nil then
			return
		end
		if element.type == 1 then
			element.base_data.info = UserInfoCache.get(element.base_data.user_name)
		elseif element.type == 4 then
			element.boss_data.user_info = PlanetCache.getBossUser(user_info.user_name, element.global_key)
		elseif element.type == 5 then
			if element.city_data ~= nil and element.city_data.groupid ~= "" and element.city_data.groupid ~= nil then
				local group_main = GroupCache.getGroupMain(element.city_data.groupid)
				element.city_data.temp_info = GroupCache.toOtherGroupInfo(group_main)
			end
		elseif element.type == 6 then

			PlanetCache.checkCityRes( element, cur_time, user_info.user_name )
		elseif element.type == 12 then
			if element.wangzuo_data ~= nil then				
				if element.wangzuo_data.groupid ~= "" and element.wangzuo_data.groupid ~= nil then
					local group_main = GroupCache.getGroupMain(element.wangzuo_data.groupid)
					element.wangzuo_data.temp_info = GroupCache.toOtherGroupInfo(group_main)
					if element.wangzuo_data.temp_info ~= nil then
						local leader_user = GroupCache.GetGroupLeader(group_main)
						if leader_user ~= nil then
							local other_user_info = UserInfoCache.get(leader_user.user_name)
							if other_user_info ~= nil then
								element.wangzuo_data.user_info = other_user_info
							end
						end
					end
				else
					if element.wangzuo_data.user_name ~= nil then
						local other_user_info = UserInfoCache.get(element.wangzuo_data.user_name)
						if other_user_info ~= nil then
							element.wangzuo_data.user_info = other_user_info
						end
					end
				end
			end
		elseif element.type == 13 then
			if element.tower_data ~= nil then
				if element.tower_data.groupid ~= "" and element.tower_data.groupid ~= nil then
					local group_main = GroupCache.getGroupMain(element.tower_data.groupid)
					element.tower_data.temp_info = GroupCache.toOtherGroupInfo(group_main)
					if element.tower_data.temp_info ~= nil then
						local leader_user = GroupCache.GetGroupLeader(group_main)
						if leader_user ~= nil then
							local other_user_info = UserInfoCache.get(leader_user.user_name)
							if other_user_info ~= nil then
								element.tower_data.user_info = other_user_info
							end
						end
					end
				end
				if element.tower_data.user_name ~= nil then
					local other_user_info = UserInfoCache.get(element.tower_data.user_name)
					if other_user_info ~= nil then
						element.tower_data.user_info = other_user_info
					end
				end
			end
		end
	end

	local function syncUser(req)
		local planet_user = PlanetCache.getUser(user_info.user_name)
		if planet_user == nil then
			return 1
		end
		if Tools.isEmpty(planet_user.army_list) == false then
			for i,army in ipairs(planet_user.army_list) do
				--Tools._print("planet_get_do_logic",i,army.status_machine)
				PlanetStatusMachine[army.status_machine].doLogic(cur_time, planet_user, army)
				--Tools._print("planet_get_do_logic end")
			end
		end
		--Tools.print_t(planet_user)

		return 0, planet_user
	end

	local function syncNode( req )

		if Tools.isEmpty(req.node_id_list) == true then
			return 1
		end
 		local node_list = {}
		for i,id in ipairs(req.node_id_list) do
			local node_data = PlanetCache.getNodeByID(id)

			if node_data == nil then
				return 2
			end

			node_data = Tools.clone(node_data)
			if Tools.isEmpty(node_data.element_list) == false then
				for i,element in ipairs(node_data.element_list) do
					installElement(element)
				end
			end
			table.insert(node_list, node_data)
		end
		return 0, node_list
	end

	local function syncElement( list )

		if Tools.isEmpty(list) == true then
			return 1
		end

		local element_list = {}
		for i,key in ipairs(list) do
			local element = PlanetCache.getElement( key )
			if element ~= nil then
				element = Tools.clone(element)
				installElement(element)
				table.insert(element_list, element)
			end
		end
		
		return 0, element_list
	end

	local function syncArmyLine( req )
		if Tools.isEmpty(req.army_line_key_list) == true then
			return 1
		end

		local army_line_list = {}
		for i,army_key in ipairs(req.army_line_key_list) do
			local army = PlanetCache.getArmy( army_key )
			--print("syncArmyLine")
			--Tools.print_t(army)

			if army ~= nil and Tools.isEmpty(army.line) == false then
		
				local army_line = Tools.clone(army.line)
				army_line.status = army.status
				army_line.status_machine = army.status_machine
				table.insert(army_line_list, army_line)
			end
		end
		return 0, army_line_list
	end

	local function syncMailUser( req )
		if Tools.isEmpty(req.army_key_list) == true then
			return 1
		end
		local list = {}
		for i,army_key in ipairs(req.army_key_list) do
			local key_list = Tools.split(army_key, "_") 
			local planet_user = PlanetCache.getUser(key_list[1])
			local army = PlanetCache.getArmy(army_key)

			local mail_user = PlanetCache.createMailUser(planet_user, army)
			table.insert(list, mail_user)
		end
		return 0, list
	end

	local function syncArmy( req )

		if Tools.isEmpty(req.army_key_list) == true then
			return 1
		end
		local list = {}
		for i,army_key in ipairs(req.army_key_list) do

			local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
			local army = PlanetCache.getArmy(army_key)
			if army == nil then
				return 2
			end
			PlanetStatusMachine[army.status_machine].doLogic(cur_time, user, army)
			table.insert(list, army)
		end
		return 0, list
	end

	local function syncArmyInfo( req )
		if Tools.isEmpty(req.army_key_list) == true then
			return 1
		end
		local list = {}
		for i,army_key in ipairs(req.army_key_list) do
		
			local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
		
			local army = PlanetCache.getArmy(army_key)
			if army == nil then
				return 2
			end

			PlanetStatusMachine[army.status_machine].doLogic(cur_time, user, army)

			local my_base = PlanetCache.getElement( user.base_global_key )
			
			if my_base then
				my_base = Tools.clone(my_base)
				installElement(my_base)
			end
			

			local target_element = PlanetCache.getElement( army.element_global_key)
			if target_element then
				target_element = Tools.clone(target_element)
				installElement(target_element)
			end

			local info = {
				my_base = my_base,
				army = army,
				target_element = target_element,
			}

			table.insert(list, info)
		end
		return 0, list
	end

	--Tools._print("planet_get_do_logic  "..req.type)
	--if req.type == 2 then
	--	Tools.print_t(req)
	--end

	local ret
	local node_list
	local planet_user
	local element_list
	local army_line_list
	local mail_user_list
	local army_list
	local army_info_list
	if req.type == 1 then
		ret, planet_user = syncUser(req)
	elseif req.type == 2 then
		ret, node_list = syncNode(req)
	elseif req.type == 3 then
		ret, element_list = syncElement(req.element_global_key_list)
	elseif req.type == 4 then
		ret, army_line_list = syncArmyLine(req)
	elseif req.type == 5 then
		ret, mail_user_list = syncMailUser(req)
	elseif req.type == 6 then
		ret, army_list = syncArmy(req)
	elseif req.type == 7 then
		ret, army_info_list = syncArmyInfo(req)
	end
	--Tools._print("planet_get_do_logic end  ",req.type,ret)

	--if Tools.isEmpty(node_list) == false then
	--	for i,data in ipairs(node_list) do
	--		Tools._print("<<=="..data.id) 
	--	end
	--end
	--if (planet_user) then
	--	Tools.print_t(planet_user)
	--end
	--Tools._print("planet_get_do_logic22  "..req.type)

	local resp = {
		result = ret,
		type = req.type,
		node_list = node_list,
		planet_user = planet_user,
		element_list = element_list,
		planet_army_line_list = army_line_list,
		mail_user_list = mail_user_list,
		army_list = army_list,
		army_info_list = army_info_list,
	}
	local resp_buff = Tools.encode("PlanetGetResp", resp)
	user_info_buff = userInfo:getUserBuff()

	--Tools._print("planet_get_do_logic33  "..req.type)
	return resp_buff, user_info_buff
end


function planet_collect_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("PlanetCollectResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.save, user_name
	else
		error("something error");
	end
end

function planet_collect_do_logic( req_buff, user_name, user_info_buff, ship_list_buff)

	local req = Tools.decode("PlanetCollectReq", req_buff)

	local cur_time = os.time()

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()

	local shipList = require "ShipList"
	shipList:new(ship_list_buff , user_name)
	shipList:setUserInfo(user_info)

	local group_main = userInfo:getGroupMainFromGroupCache()

	local user_sync = {
		user_info = {},
		item_list = {},
		ship_list = {},
		equip_list = {},
	} 

	local planet_user = PlanetCache.getUser( user_info.user_name )

	local function doLogic( req )
		if req.res_global_key == nil then
			return "REQ_ERROR"
		end

		local element = PlanetCache.getElement( req.res_global_key )

		if element == nil or (element.type ~= 2 and element.type ~= 6) then
			return "ERROR_TYPE"
		end

		if Tools.isEmpty(req.lineup) == true then
			return "REQ_ERROR"
		end

		local tech_list = userInfo:getTechnologyList()
		local group_tech_list = group_main and group_main.tech_list or nil

		if Tools.isEmpty(planet_user.army_list) == false then
			local build_info = userInfo:getBuildingInfo(CONF.EBuilding.kMain)
			local buildConf = CONF.BUILDING_1.get(build_info.level)

			local max_army_num = math.floor(buildConf.ARMY_NUM + Tools.getValueByTechnologyAddition( buildConf.ARMY_NUM, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_Building.kArmyLimit, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name)))

			if #planet_user.army_list >= max_army_num then
				return "ARMY_NUM_MAX"
			end
		end

		if Tools.isEmpty(planet_user.army_list) == false then
			for i,v in ipairs(planet_user.army_list) do
				if v.element_global_key == req.res_global_key then
					return "MY_RES"
				end
				
			end
		end

		if element.type == 2 then
			if element.res_data.user_name == user_info.user_name then
				return "MY_RES"
			end
		elseif element.type == 6 then

			PlanetCache.checkCityRes( element, cur_time, user_info.user_name )

			if Tools.isEmpty(planet_user.army_list) == false then
				for i,v in ipairs(planet_user.army_list) do
					local element_temp = PlanetCache.getElement( v.element_global_key )
					if element_temp.type == 6 then
						return "ALREADY_COLLECT"
					end
				end
			end

			if Tools.isEmpty(planet_user.army_list) == false then
				for i,v in ipairs(planet_user.army_list) do
					if v.element_global_key == req.res_global_key then
						return "MY_RES"
					end
					local element_temp = PlanetCache.getElement( v.element_global_key )
					if element_temp.type == 6 then
						return "ALREADY_COLLECT"
					end
				end
			end

			if element.city_res_data.cur_storage <= 0 then
				return "NO_STORAGE"
			end

			if Tools.isEmpty( element.city_res_data.user_list) == false then
				local res_conf = CONF.PLANET_RES.get(element.city_res_data.id)
				if res_conf==nil or #element.city_res_data.user_list >= res_conf.LOAD_NUM then
					return "RES_MAX_LOAD"
				end

				for i,user in ipairs(element.city_res_data.user_list) do
					if user.user_name == user_info.user_name then
						return "MY_RES"
					end
				end
			end
			if user_info.group_data == nil or element.city_res_data.groupid == nil or element.city_res_data.groupid ~= user_info.group_data.groupid then

				return "ERROR_GROUP"
			end
		end
		
		local attack_list = shipList:getShipByLineup(req.lineup)
		local lineup_num = #attack_list
		if lineup_num < 1 or lineup_num > 9 then
			return "LINEUP_ERROR"
		end

		local building_14_conf = CONF.BUILDING_14.get(userInfo:getBuildingInfo(CONF.EBuilding.kWarWorkshop).level)
		local count = 0
		for i,v in ipairs(req.lineup) do
			if v > 0 then
				count = count + 1
			end
		end
		if building_14_conf == nil or count > building_14_conf.AIRSHIP_NUM or count <= 0 then
			return "LINEUP_ERROR"
		end

		for i,v in ipairs(attack_list) do
			if Tools.checkShipDurable(v) == false then
				return "NO_DURABLE"
			end
			if Bit:has(v.status, CONF.EShipState.kFix) == true then
				return "FIXING"
			elseif Bit:has(v.status, CONF.EShipState.kOuting) == true then
				return "OUTING"
			end
		end

		local lineup_hp = {0,0,0,0,0,0,0,0,0,}

		for i=1, lineup_num do
          			
			attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true)
			attack_list[i].body_position = {attack_list[i].position}

			lineup_hp[attack_list[i].position] = attack_list[i].attr[CONF.EShipAttr.kHP]
		end

		for i,v in ipairs(attack_list) do

			local ship = shipList:getShipInfo(v.guid)

			ship.status = Bit:add(ship.status, CONF.EShipState.kOuting)

			table.insert(user_sync.ship_list, ship)
		end

		local tech_param = Tools.getValueByTechnologyAddition(1, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_UserInfo.kSubDurable, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))

		local planet_army = {
			guid = 0,
			lineup = req.lineup,
			lineup_hp = lineup_hp,
			ship_list = attack_list,
			status = 0,
			status_machine = 1,
			begin_time = 0,
			element_global_key = req.res_global_key,
			tech_durable_param = tech_param,
		}
		local speed = Tools.getPlanetSpeed(planet_army.status_machine) * 1000
		speed = speed + Tools.getValueByTechnologyAddition( speed, CONF.ETechTarget_1.kPlanet, 0, CONF.ETechTarget_3_Planet.kSpeed, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))
		planet_army.speed = speed

		PlanetCache.userAddArmy(user_info.user_name, planet_army)

		return "OK"
	end

	local ret = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
		planet_user = planet_user,
	}

	local resp_buff = Tools.encode("PlanetCollectResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff
end

function planet_ride_back_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("PlanetRideBackResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function planet_ride_back_do_logic( req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local req = Tools.decode("PlanetRideBackReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()

	local shipList = require "ShipList"
	shipList:new(ship_list_buff , user_name)
	shipList:setUserInfo(user_info)

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local cur_time = os.time()

	local user_sync = {
		user_info = {},
		item_list = {},
		ship_list = {},
		equip_list = {},
	} 

	local planet_user = PlanetCache.getUser(user_info.user_name)

	local function doLogic( req )
		if Tools.isEmpty(planet_user.army_list) == true then
			return 1
		end

		for _,guid in ipairs(req.army_guid) do

			local planet_army
			local army_index
			for i,army in ipairs(planet_user.army_list) do
				if army.guid == guid then
					planet_army = army
					army_index = i
					break
				end
			end
			if planet_army ~= nil then
				if req.type == 1 then
					if planet_army.status ~= PlanetStatusMachine.Status.kMoveEnd then
						return 3
					end 

					if Tools.isEmpty(planet_army.item_list) == false then
						local items = {}
						for i,item in ipairs(planet_army.item_list) do

							items[item.id] = item.num

							if planet_army.status_machine == 1 then
								if Tools.isEmpty(planet_user.colloct_count) == true then
									planet_user.colloct_count = {}
									for i=1,#refid.res do
										planet_user.colloct_count[i] = 0 
									end
								end
								for i=1,#refid.res do
									if refid.res[i] == item.id then
										planet_user.colloct_count[i] = planet_user.colloct_count[i] + item.num
									end
								end
							end	
						end
						if CoreItem.addItems( items, item_list, user_info) == false then
							return 4
						end

						CoreItem.makeSync(items, item_list, user_info, user_sync)
					end

					if Tools.isEmpty(planet_army.lineup) == false then
						for i,guid in ipairs(planet_army.lineup) do

							if guid > 0 then
								local ship = shipList:getShipInfo(guid)
								if ship then
									ship.status = Bit:remove(ship.status, CONF.EShipState.kOuting)
									Tools._print("removekOuting removekOuting removekOuting removekOuting")
									local out_ship = getShipByArmy(guid, planet_army)

									ship.durable = out_ship.durable

									ship.energy_level = out_ship.energy_level
									ship.energy_exp = out_ship.energy_exp

									table.insert(user_sync.ship_list, ship)
								end
							end
						end
					end

					if planet_army.status_machine == 1 then
						local achievement_data = userInfo:getAchievementData()

						if (achievement_data.first_finish_collect == nil or achievement_data.first_finish_collect == false) and user_info.level > 3 then
							if (CoreUser.getNewHandGiftBag( user_info )) then
								achievement_data.first_finish_collect = true
							end
						end
					end

					table.remove(planet_user.army_list, army_index)

					PlanetCache.saveUserData( planet_user )

				elseif req.type == 2 then
					local planet_move_back_item = CONF.PARAM.get("planet_move_back_item").PARAM

					local move_flag = false
					if planet_army.status == PlanetStatusMachine.Status.kMove or planet_army.status == PlanetStatusMachine.Status.kMoveBack  then

						if planet_army.line == nil then
							return 11
						end

						if CoreItem.checkItem(planet_move_back_item, 1, item_list, user_info) == false then
							return 12
						end

						move_flag = true
					end
					if PlanetStatusMachine[planet_army.status_machine].back(os.time(), planet_user, planet_army) == false then
						return 13
					end
					if move_flag == true then
						local items = {[planet_move_back_item] = 1}
						CoreItem.expendItems( items, item_list, user_info)

						CoreItem.makeSync(items, item_list, user_info, user_sync)
					end

				end
			end

		end
		return 0
	end

	local ret = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
		planet_user = planet_user,
	}

	local resp_buff = Tools.encode("PlanetRideBackResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end

function planet_ruins_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("PlanetRuinsResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.save, user_name
	else
		error("something error");
	end
end

function planet_ruins_do_logic( req_buff, user_name, user_info_buff, ship_list_buff)

	local req = Tools.decode("PlanetRuinsReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()

	local shipList = require "ShipList"
	shipList:new(ship_list_buff , user_name)
	shipList:setUserInfo(user_info)

	local group_main = userInfo:getGroupMainFromGroupCache()

	local user_sync = {
		user_info = {},
		item_list = {},
		ship_list = {},
		equip_list = {},
	} 

	local planet_user = PlanetCache.getUser( user_info.user_name )

	local function doLogic( req )
	
		if req.element_global_key == nil then
			return "REQ_ERROR"
		end
	
		local element = PlanetCache.getElement( req.element_global_key )
		if element == nil or element.type ~= 3 then
			return "ERROR_TYPE"
		end

		local conf = CONF.PLANET_RUINS.get(element.ruins_data.id)
		
		if Tools.isEmpty(req.lineup) == true then
			return "REQ_ERROR"
		end

		if CoreItem.checkStrength(user_info, conf.STRENGTH) == false then
			return "NO_STRENGTH"
		end

		local tech_list = userInfo:getTechnologyList()
		local group_tech_list = group_main and group_main.tech_list or nil

		if Tools.isEmpty(planet_user.army_list) == false then
			local build_info = userInfo:getBuildingInfo(CONF.EBuilding.kMain)
			local buildConf = CONF.BUILDING_1.get(build_info.level)

			local max_army_num = math.floor(buildConf.ARMY_NUM + Tools.getValueByTechnologyAddition( buildConf.ARMY_NUM, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_Building.kArmyLimit, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name)))

			if #planet_user.army_list >= max_army_num then
				return "ARMY_NUM_MAX"
			end
		end
	
		local attack_list = shipList:getShipByLineup(req.lineup)
		local lineup_num = #attack_list
		if lineup_num < 1 then
			return "LINEUP_ERROR"
		end
		local building_14_conf = CONF.BUILDING_14.get(userInfo:getBuildingInfo(CONF.EBuilding.kWarWorkshop).level)
		local count = 0
		for i,v in ipairs(req.lineup) do
			if v > 0 then
				count = count + 1
			end
		end
		if count > building_14_conf.AIRSHIP_NUM or count <= 0 then
			return "LINEUP_ERROR"
		end
		for i,v in ipairs(attack_list) do
			if Tools.checkShipDurable(v) == false then
				return "NO_DURABLE"
			end
			if Bit:has(v.status, CONF.EShipState.kFix) == true then
				return "FIXING"
			elseif Bit:has(v.status, CONF.EShipState.kOuting) == true then

				return "OUTING"
			end
		end

		local lineup_hp = {0,0,0,0,0,0,0,0,0,}

		for i=1, lineup_num do
          			
			attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true)
			attack_list[i].body_position = {attack_list[i].position}

			lineup_hp[attack_list[i].position] = attack_list[i].attr[CONF.EShipAttr.kHP]
		end
		
		for i,v in ipairs(attack_list) do

			local ship = shipList:getShipInfo(v.guid)

			ship.status = Bit:add(ship.status, CONF.EShipState.kOuting)

			table.insert(user_sync.ship_list, ship)
		end
	
		local machine

		--Tools._print("sssssssssssssssssss "..conf.TYPE.."  "..element.ruins_data.id)
		
		if conf.TYPE == 1 then
			machine = 3
		else
			machine = 2
		end

		local tech_list = userInfo:getTechnologyList()
		local group_tech_list = group_main and group_main.tech_list or nil

		local tech_param = Tools.getValueByTechnologyAddition(1, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_UserInfo.kSubDurable, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))
	
		local planet_army = {
			guid = 0,
			lineup = req.lineup,
			lineup_hp = lineup_hp,
			ship_list = attack_list,
			status = 0,
			status_machine = machine,
			begin_time = 0,
			element_global_key = req.element_global_key,
			tech_durable_param = tech_param,
		}

		local speed = Tools.getPlanetSpeed(planet_army.status_machine) * 1000
		speed = speed + Tools.getValueByTechnologyAddition( speed, CONF.ETechTarget_1.kPlanet, 0, CONF.ETechTarget_3_Planet.kSpeed, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))
		planet_army.speed = speed

		PlanetCache.userAddArmy(user_info.user_name, planet_army)

		CoreItem.expendStrength(user_info, conf.STRENGTH) 
		CoreItem.syncStrength(user_info, user_sync)
	
		return "OK"
	end

	local ret = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
		planet_user = planet_user,
	}
	local resp_buff = Tools.encode("PlanetRuinsResp", resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()

	return resp_buff, user_info_buff, ship_list_buff
end



function planet_raid_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		local req = Tools.decode("PlanetRaidReq", req_buff)

		return 1, Tools.encode("PlanetRaidResp", resp)
	elseif step == 1 then
		
		return datablock.user_info + datablock.ship_list + datablock.save, user_name
	else
		error("something error");
	end
end

function planet_raid_do_logic( req_buff, user_name, user_info_buff, ship_list_buff)
	local req = Tools.decode("PlanetRaidReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)

	local user_info = userInfo:getUserInfo()
	local ship_list  = shipList:getShipList()
	shipList:setUserInfo(user_info)

	local group_main = userInfo:getGroupMainFromGroupCache()

	local now_time = os.time()

	local user_sync = {
		user_info = {},
		item_list = {},
		ship_list = {},
		equip_list = {},
	} 
	local planet_user = PlanetCache.getUser( user_info.user_name )

	local tech_list = userInfo:getTechnologyList()
	local group_tech_list = group_main and group_main.tech_list or nil

	local function doRaid( req )

		if req.element_global_key == nil then
			return "REQ_ERROR"
		end
	
		local element = PlanetCache.getElement( req.element_global_key )
		if element == nil or element.type == nil then
			return "ERROR_TYPE"
		end

		if req.type_list[1] == 1 or req.type_list[2] == 1 then
			if element.type ~= 1 then
				return "ERROR_TYPE"
			end

			if UserInfoCache.isSameGroup(user_info.user_name, element.base_data.user_name) then
				return "ERROR_GROUP"
			end

			if CoreItem.checkStrength(user_info, CONF.PARAM.get("attack_base_strength").PARAM) == false then
				return "NO_STRENGTH"
			end

			if element.base_data.shield_start_time ~= nil and element.base_data.shield_start_time > 0 then
				if now_time - element.base_data.shield_start_time < element.base_data.shield_time then

					return "SHIELD"
				end
			end
		end

		local addtion_tech_list

		if req.type_list[1] == 7 or req.type_list[2] == 7 then
			if element.type ~= 4 then
				return "ERROR_TYPE"
			end

			local conf = CONF.PLANETBOSS.get(element.boss_data.id)
			if CoreItem.checkStrength(user_info, conf.STRENGTH) == false then
				return "NO_STRENGTH"
			end

			local boss_user = PlanetCache.getBossUser(user_info.user_name, req.element_global_key)

			if boss_user ~= nil then
				if boss_user.start_time + conf.BUFF_TIME < os.time() then --BUFF时间到
					PlanetCache.removeBossUser(req.element_global_key )
				else
					addtion_tech_list = {boss_user.tech_id}
				end
			end
		end

		if req.type_list[1] == 6 or req.type_list[2] == 6 then
			if element.type ~= 5 then
				return "ERROR_TYPE"
			end
			if element.city_data.status ~= 2 then
				return "NOT_OPEN"
			end
			local conf = CONF.PLANETCITY.get(element.city_data.id)
			if CoreItem.checkStrength(user_info, conf.STRENGTH) == false then
				return "NO_STRENGTH"
			end

			if group_main == nil then
				return "NO_GROUP"
			end

			if element.city_data.groupid == group_main.groupid then
				return "ERROR_GROUP"
			end

			--local blast,index = PlanetCache.ClickCityGroup(element.city_data.id , group_main.groupid)
			--if blast == false then
			--	if index < 1 or index > 3 then
			--		index = 1
			--	end
			--	return "NO_LAST_CITY_"..index
			--end
		end

		if req.type_list[1] == 12 or req.type_list[2] == 12 then
			if element.type ~= 12 then
				return "ERROR_TYPE"
			end
			if element.wangzuo_data.status ~= 2 then
				return "NOT_OPEN"
			end
			local conf = CONF.PLANETCITY.get(element.wangzuo_data.id)
			if CoreItem.checkStrength(user_info, conf.STRENGTH) == false then
				return "NO_STRENGTH"
			end

			if group_main and element.wangzuo_data.groupid == group_main.groupid then
				return "ERROR_GROUP"
			end
		end

		if req.type_list[1] == 13 or req.type_list[2] == 13 then
			if element.type ~= 13 then
				return "ERROR_TYPE"
			end
			if element.tower_data.status ~= 2 then
				return "NOT_OPEN"
			end

			local conf = CONF.PLANETTOWER.get(element.tower_data.id)
			if CoreItem.checkStrength(user_info, conf.STRENGTH) == false then
				return "NO_STRENGTH"
			end

			if group_main and element.tower_data.groupid == group_main.groupid then
				return "ERROR_GROUP"
			end
		end

		if req.type_list[1] == 4 then
			--Tools.print_t(req)
			local other_user_info = UserInfoCache.get(user_info.user_name)
			if other_user_info.groupid == "" or other_user_info.groupid == nil then
				return "NO_GROUP"
			end
			if req.type_list[2] ~= 6 and req.type_list[2] ~= 1 and req.type_list[2] ~= 12 and req.type_list[2] ~= 13 then
				return "ERROR_TYPE"
			end

			if req.mass_level == nil or req.mass_level > #CONF.PARAM.get("mass_time").PARAM then
				return "ERROR_TYPE"
			end
		end

		if req.type_list[1] == 5 then
			if req.army_key == nil then
				return "REQ_ERROR"
			end

			local key_list = Tools.split(req.army_key, "_")
			if key_list[1] == user_info.user_name then
				return "REQ_ERROR"
			end

		
			local other_army = PlanetCache.getArmy(req.army_key)
			if other_army == nil or other_army.status ~= PlanetStatusMachine.Status.kEnlist then
				return "REQ_ERROR"
			end

			if Tools.isEmpty(other_army.army_key_list) == false then

				local other_other_user_info = UserInfoCache.get(key_list[1])
				local mainConf = CONF.BUILDING_1.get(other_other_user_info.building_level_list[CONF.EBuilding.kMain])

				if #other_army.army_key_list >= mainConf.MASS then
					return "ARMY_NUM_MAX"
				end
				for i,army_key in ipairs(other_army.army_key_list) do
					local name = Tools.split(army_key, "_")[1]
					if name == user_info.user_name then
						return "ALREADY_ACCOMPANY"
					end
				end
				for i,army_key in ipairs(other_army.req_army_key_list) do
					local name = Tools.split(army_key, "_")[1]
					if name == user_info.user_name then
						return "ALREADY_REQ_ACCOMPANY"
					end
				end
			end

			if UserInfoCache.isSameGroup(user_info.user_name, key_list[1]) == false then
				return "ERROR_GROUP"
			end
		end

		if req.type_list[1] == 11 or req.type_list[2] == 11 then
			if element.type ~= 11 then
				return "ERROR_TYPE"
			end

			if element.monster_data.isDead == 1 then
				return "REQ_ERROR"
			end
			local conf = CONF.PLANETCREEPS.get(element.monster_data.id)
			if conf==nil or CoreItem.checkStrength(user_info, conf.STRENGTH) == false then
				return "NO_STRENGTH"
			end
		end
		
		if Tools.isEmpty(req.lineup) == true then
			return "REQ_ERROR"
		end
		if Tools.isEmpty(planet_user.army_list) == false then

			local build_info = userInfo:getBuildingInfo(CONF.EBuilding.kMain)
			local buildConf = CONF.BUILDING_1.get(build_info.level)

			local max_army_num = math.floor(buildConf.ARMY_NUM + Tools.getValueByTechnologyAddition( buildConf.ARMY_NUM, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_Building.kArmyLimit, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name)))

			if #planet_user.army_list >= max_army_num then
				return "ARMY_NUM_MAX"
			end
		end
		
		local attack_list = shipList:getShipByLineup(req.lineup)
		local lineup_num = #attack_list
		if lineup_num < 1 then
			return "LINEUP_ERROR"
		end
		local building_14_conf = CONF.BUILDING_14.get(userInfo:getBuildingInfo(CONF.EBuilding.kWarWorkshop).level)
		local count = 0
		for i,v in ipairs(req.lineup) do
			if v > 0 then
				count = count + 1
			end
		end
		if count > building_14_conf.AIRSHIP_NUM or count <= 0 then
			return "LINEUP_ERROR"
		end
		for i,v in ipairs(attack_list) do
			if Tools.checkShipDurable(v) == false then
				return "NO_DURABLE"
			end
			if Bit:has(v.status, CONF.EShipState.kFix) == true then
				return "FIXING"
			elseif Bit:has(v.status, CONF.EShipState.kOuting) == true then

				return "OUTING"
			end
		end

		local lineup_hp = {0,0,0,0,0,0,0,0,0,}

		for i=1, lineup_num do
          			
			attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true, addtion_tech_list)
			attack_list[i].body_position = {attack_list[i].position}

			lineup_hp[attack_list[i].position] = attack_list[i].attr[CONF.EShipAttr.kHP]
		end

		for i,v in ipairs(attack_list) do

			local ship = shipList:getShipInfo(v.guid)

			ship.status = Bit:add(ship.status, CONF.EShipState.kOuting)

			table.insert(user_sync.ship_list, ship)
		end

		local tech_param = Tools.getValueByTechnologyAddition(1, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_UserInfo.kSubDurable, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))

		local machine = 0
		if req.type_list[1] == 1 then
			machine = 6
		elseif req.type_list[1] == 6 then
			machine = 8
		elseif req.type_list[1] == 7 then
			machine = 9
		elseif req.type_list[1] == 4 then
			machine = 10
		elseif req.type_list[1] == 5 then
			machine = 7
		elseif req.type_list[1] == 11 then
			machine = 11
		elseif req.type_list[1] == 12 then
			machine = 12
		elseif req.type_list[1] == 13 then
			machine = 13
		end
		local planet_army = {
			guid = 0,
			lineup = req.lineup,
			lineup_hp = lineup_hp,
			ship_list = attack_list,
			status = 0,
			status_machine = machine,
			begin_time = 0,
			element_global_key = req.element_global_key,
			tech_durable_param = tech_param,
		}

		if req.type_list[1] == 4 then

			if req.type_list[2] == 1 then
				planet_army.next_status_machine = 6
			elseif req.type_list[2] == 6 then
				planet_army.next_status_machine = 8
			elseif req.type_list[2] == 12 then
				planet_army.next_status_machine = 12
			elseif req.type_list[2] == 13 then
				planet_army.next_status_machine = 13
				Tools._print("req.type_list[1] == 4  req.type_list[2] == 13")
			end

			planet_army.mass_time = CONF.PARAM.get("mass_time").PARAM[req.mass_level] * 60

		elseif req.type_list[1] == 5 then

			planet_army.accompany_army_key = req.army_key

			--通知 集结的部队 有人加入
			local other_army = PlanetCache.getArmy(req.army_key)
			local user_list
			if Tools.isEmpty(other_army.army_key_list) == true then
				user_list = {}
			else
				user_list = Tools.clone(other_army.army_key_list)
			end
			table.insert(user_list, Tools.split(req.army_key, "_")[1])
			PlanetCache.broadcastUserUpdate(user_info.user_name, user_list)
		end

		if req.type_list[1] == 1 or req.type_list[2] == 1 then

			CoreItem.expendStrength(user_info, CONF.PARAM.get("attack_base_strength").PARAM) 
			CoreItem.syncStrength(user_info, user_sync)

		elseif req.type_list[1] == 6 or req.type_list[2] == 6 then

			local conf = CONF.PLANETCITY.get(element.city_data.id)
			CoreItem.expendStrength(user_info, conf.STRENGTH) 
			CoreItem.syncStrength(user_info, user_sync)

		elseif req.type_list[1] == 7 or req.type_list[2] == 7 then

			local conf = CONF.PLANETBOSS.get(element.boss_data.id)
			CoreItem.expendStrength(user_info, conf.STRENGTH) 
			CoreItem.syncStrength(user_info, user_sync)

		elseif req.type_list[1] == 11 or req.type_list[2] == 11 then

			local conf = CONF.PLANETCREEPS.get(element.monster_data.id)
			CoreItem.expendStrength(user_info, conf.STRENGTH) 
			CoreItem.syncStrength(user_info, user_sync)
		elseif req.type_list[1] == 12 or req.type_list[2] == 12 then

			local conf = CONF.PLANETCITY.get(element.wangzuo_data.id)
			CoreItem.expendStrength(user_info, conf.STRENGTH) 
			CoreItem.syncStrength(user_info, user_sync)
		elseif req.type_list[1] == 13 or req.type_list[2] == 13 then

			local conf = CONF.PLANETTOWER.get(element.tower_data.id)
			CoreItem.expendStrength(user_info, conf.STRENGTH) 
			CoreItem.syncStrength(user_info, user_sync)
		end

		local speed = Tools.getPlanetSpeed(planet_army.status_machine) * 1000
		speed = speed + Tools.getValueByTechnologyAddition( speed, CONF.ETechTarget_1.kPlanet, 0, CONF.ETechTarget_3_Planet.kSpeed, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))
		planet_army.speed = speed
		
		PlanetCache.userAddArmy(user_info.user_name, planet_army)

		if req.type_list[1] == 4 or req.type_list[1] == 1 or req.type_list[1] == 6 or req.type_list[1] == 12 or req.type_list[1] == 13 then
			PlanetCache.addEnlistToGroup( planet_army.army_key )
			Tools._print("req.type_list[1] == ",req.type_list[1],"  req.type_list[2] == ",req.type_list[2]," addEnlistToGroup")
		end
	
		return "OK"
	end

	local function doSpy( req )

		if req.element_global_key == nil then
			return "REQ_ERROR"
		end

		local element = PlanetCache.getElement( req.element_global_key )
		if element == nil or (element.type ~= 1 and element.type ~= 5) then
			return "ERROR_TYPE"
		end

		if element.type == 1 and UserInfoCache.isSameGroup(user_info.user_name, element.base_data.user_name) then
			return "ERROR_GROUP"
		elseif element.type == 5 and group_main ~= nil then

			if element.city_data.groupid == group_main.groupid then
				return "ERROR_GROUP"
			end
		elseif element.type == 12 and group_main ~= nil then
			if element.wangzuo_data.groupid == group_main.groupid then
				return "ERROR_GROUP"
			end
		elseif element.type == 13 and group_main ~= nil then
			if element.tower_data.groupid == group_main.groupid then
				return "ERROR_GROUP"
			end
		end

		if element.type == 1 and element.base_data.shield_start_time ~= nil and element.base_data.shield_start_time > 0 then
			if now_time - element.base_data.shield_start_time < element.base_data.shield_time then

				return "SHIELD"
			end
		end

		if Tools.isEmpty(planet_user.army_list) == false then
			local build_info = userInfo:getBuildingInfo(CONF.EBuilding.kMain)
			local buildConf = CONF.BUILDING_1.get(build_info.level)

			local max_army_num = math.floor(buildConf.ARMY_NUM + Tools.getValueByTechnologyAddition( buildConf.ARMY_NUM, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_Building.kArmyLimit, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name)))

			if #planet_user.army_list >= max_army_num then
				return "ARMY_NUM_MAX"
			end
		end

		local planet_army = {
			guid = 0,
			status = 0,
			status_machine = 4,
			begin_time = 0,
			element_global_key = req.element_global_key,
			tech_durable_param = 0,
		}

		local speed = Tools.getPlanetSpeed(planet_army.status_machine) * 1000
		speed = speed + Tools.getValueByTechnologyAddition( speed, CONF.ETechTarget_1.kPlanet, 0, CONF.ETechTarget_3_Planet.kSpeed, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))
		planet_army.speed = speed

		PlanetCache.userAddArmy(user_info.user_name, planet_army)
		return "OK"
	end

	local function doGuarde( req )
		local planet_user = PlanetCache.getUser( user_info.user_name )

		if req.element_global_key == nil  then
			return "REQ_ERROR"
		end

		local element = PlanetCache.getElement( req.element_global_key )
		if element == nil or (element.type ~= 1 and element.type ~= 5 and element.type ~= 12 and element.type ~= 13) then
			return "ERROR_TYPE"
		end

		if CoreItem.checkStrength(user_info, CONF.PARAM.get("guarde_strength").PARAM) == false then
			return "NO_STRENGTH"
		end

		if element.type == 1 then

			--非同一公会返回
			if UserInfoCache.isSameGroup(user_info.user_name, element.base_data.user_name) == false then
				return "ERROR_GROUP"
			end

			if Tools.isEmpty(element.base_data.guarde_list) == false then
				for i,army_key in ipairs(element.base_data.guarde_list) do
					if Tools.split(army_key, "_")[1] == planet_user.user_name then
						return "ALREADY_GUARDE"
					end
				end
			end	
		elseif element.type == 5 then

			local other_user_info = UserInfoCache.get(planet_user.user_name)

			local cityConf = CONF.PLANETCITY.get(element.city_data.id)
			if other_user_info.groupid == nil 
			or other_user_info.groupid == "" 
			or other_user_info.groupid ~= element.city_data.groupid 
			or #element.city_data.guarde_list >= cityConf.TROOPS_LIMIT then
				return "ERROR_GROUP"
			end

			if Tools.isEmpty(element.city_data.guarde_list) == false then
				for i,army_key in ipairs(element.city_data.guarde_list) do
					if Tools.split(army_key, "_")[1] == planet_user.user_name then
						return "ALREADY_GUARDE"
					end
				end
			end
		elseif element.type == 12 then

			local other_user_info = UserInfoCache.get(planet_user.user_name)
			local cityConf = CONF.PLANETCITY.get(element.wangzuo_data.id)
			if #element.wangzuo_data.guarde_list >= cityConf.TROOPS_LIMIT then
				return "ERROR_GROUP"
			end
			if (element.wangzuo_data.groupid == nil or element.wangzuo_data.groupid == "") then
				if other_user_info.user_name ~= element.wangzuo_data.user_name then
					return "ERROR_GROUP"
				end
			else
				if other_user_info.groupid == nil 
				or other_user_info.groupid == "" 
				or other_user_info.groupid ~= element.wangzuo_data.groupid then
					return "ERROR_GROUP"
				end
			end	

			--if Tools.isEmpty(element.wangzuo_data.guarde_list) == false then
			--	for i,army_key in ipairs(element.wangzuo_data.guarde_list) do
			--		if Tools.split(army_key, "_")[1] == planet_user.user_name then
			--			return "ALREADY_GUARDE"
			--		end
			--	end
			--end
		elseif element.type == 13 then

			local other_user_info = UserInfoCache.get(planet_user.user_name)

			local cityConf = CONF.PLANETTOWER.get(element.tower_data.id)
			if #element.wangzuo_data.guarde_list >= cityConf.TROOPS_LIMIT then
				return "ERROR_GROUP"
			end
			if (element.tower_data.groupid == nil or element.tower_data.groupid == "") then
				if other_user_info.user_name ~= element.tower_data.user_name then
					return "ERROR_GROUP"
				end
			else
				if other_user_info.groupid == nil 
				or other_user_info.groupid == "" 
				or other_user_info.groupid ~= element.tower_data.groupid then
					return "ERROR_GROUP"
				end
			end

			--if Tools.isEmpty(element.tower_data.guarde_list) == false then
			--	for i,army_key in ipairs(element.tower_data.guarde_list) do
			--		if Tools.split(army_key, "_")[1] == planet_user.user_name then
			--			return "ALREADY_GUARDE"
			--		end
			--	end
			--end
		end


		if Tools.isEmpty(planet_user.army_list) == false then
			local build_info = userInfo:getBuildingInfo(CONF.EBuilding.kMain)
			local buildConf = CONF.BUILDING_1.get(build_info.level)

			local max_army_num = math.floor(buildConf.ARMY_NUM + Tools.getValueByTechnologyAddition( buildConf.ARMY_NUM, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_Building.kArmyLimit, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name)))

			if #planet_user.army_list >= max_army_num then
				return "ARMY_NUM_MAX"
			end
		end

		local attack_list = shipList:getShipByLineup(req.lineup)
		local lineup_num = #attack_list
		if lineup_num < 1 then
			return "LINEUP_ERROR"
		end
		for i,v in ipairs(attack_list) do
			if Tools.checkShipDurable(v) == false then
				return "NO_DURABLE"
			end
			if Bit:has(v.status, CONF.EShipState.kFix) == true then
				return "FIXING"
			elseif Bit:has(v.status, CONF.EShipState.kOuting) == true then
				return "OUTING"
			end
		end

		local lineup_hp = {0,0,0,0,0,0,0,0,0,}

		for i=1, lineup_num do
          			
			attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true)
			attack_list[i].body_position = {attack_list[i].position}

			lineup_hp[attack_list[i].position] = attack_list[i].attr[CONF.EShipAttr.kHP]
		end

		for i,v in ipairs(attack_list) do

			local ship = shipList:getShipInfo(v.guid)

			ship.status = Bit:add(ship.status, CONF.EShipState.kOuting)

			table.insert(user_sync.ship_list, ship)
		end

		local tech_list = userInfo:getTechnologyList()
		local group_tech_list = group_main and group_main.tech_list or nil

		local tech_param = Tools.getValueByTechnologyAddition(1, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_UserInfo.kSubDurable, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))

		local planet_army = {
			guid = 0,
			lineup = req.lineup,
			lineup_hp = lineup_hp,
			ship_list = attack_list,
			status = 0,
			status_machine = 5,
			begin_time = 0,
			element_global_key = req.element_global_key,
			tech_durable_param = tech_param,
		}

		local speed = Tools.getPlanetSpeed(planet_army.status_machine) * 1000
		speed = speed + Tools.getValueByTechnologyAddition( speed, CONF.ETechTarget_1.kPlanet, 0, CONF.ETechTarget_3_Planet.kSpeed, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_name))
		planet_army.speed = speed

		PlanetCache.userAddArmy(user_info.user_name, planet_army)

		CoreItem.expendStrength(user_info, CONF.PARAM.get("guarde_strength").PARAM) 
		CoreItem.syncStrength(user_info, user_sync)

		return "OK"
	end

	local function doReturnGuarde(req)

		if req.army_key == nil then
			return "REQ_ERROR"
		end
		local key_list = Tools.split(req.army_key, "_")

		local other_planet_user = PlanetCache.getUser(key_list[1])
		local other_army = PlanetCache.getArmy(req.army_key)

		if other_army == nil or other_planet_user == nil then
			return "REQ_ERROR"
		end

		local element = PlanetCache.getElement(other_army.element_global_key)
		if element == nil then
			return "REQ_ERROR"
		end
		if element.type == 1 then
			if other_army.element_global_key ~= planet_user.base_global_key then
				return "NO_BASE_POWER"
			end
		elseif element.type == 5 then
			if Tools.isEmpty(user_info.group_data) == true then
				return "NO_GROUP"
			end
			if user_info.group_data.job >= 3 then
				return "NO_GROUP_POWER"
			end
		elseif element.type == 12 then
			--if Tools.isEmpty(user_info.group_data) == true then
			--	return "NO_GROUP"
			--end
			--if user_info.group_data.job >= 3 then
			--	return "NO_GROUP_POWER"
			--end
		elseif element.type == 13 then
			--if Tools.isEmpty(user_info.group_data) == true then
			--	return "NO_GROUP"
			--end
			--if user_info.group_data.job >= 3 then
			--	return "NO_GROUP_POWER"
			--end
		end

		if PlanetStatusMachine[other_army.status_machine].back(os.time(), other_planet_user, other_army) == false then
			return "ERROR_STATUS"
		end

		return "OK"
	end

	local function doReturnAccompany(req)
		if req.army_key == nil then
			return "REQ_ERROR"
		end
		local key_list = Tools.split(req.army_key, "_")

		local other_planet_user = PlanetCache.getUser(key_list[1])
		if other_planet_user == nil then
			return "REQ_ERROR"
		end
		local other_army = PlanetCache.getArmy(req.army_key)
		if other_army == nil then
			return "REQ_ERROR"
		end
		
		if PlanetStatusMachine[other_army.status_machine].back(os.time(), other_planet_user, other_army) == false then
			return "ERROR_STATUS"
		end

		return "OK"
	end


	--Tools._print("111111111111111111111")
	--Tools.print_t(req)

	local ret
	if Tools.isEmpty(req.type_list) == true then
		ret = "NO_TYPE"
	else
		if req.type_list[1] == 1 
		or req.type_list[1] == 6 
		or req.type_list[1] == 7 
		or req.type_list[1] == 4 
		or req.type_list[1] == 5 
		or req.type_list[1] == 11 
		or req.type_list[1] == 12
		or req.type_list[1] == 13 then
			ret = doRaid(req)
		elseif req.type_list[1] == 2 then
			ret = doSpy(req)
		elseif req.type_list[1] == 3 then
			ret = doGuarde(req)
		elseif req.type_list[1] == 5 then
			ret = doAccompany(req)
		elseif req.type_list[1] == 8 then
			ret = doReturnGuarde(req)
		elseif req.type_list[1] == 9 then
			ret = doReturnAccompany(req)
		end

	end

	
	local resp = {
		result = ret,
		user_sync = user_sync,
		planet_user = planet_user,
	}

	local resp_buff = Tools.encode("PlanetRaidResp", resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()

	return resp_buff, user_info_buff, ship_list_buff
end

function planet_speed_up_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("PlanetSpeedUpResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function planet_speed_up_do_logic( req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("PlanetSpeedUpReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local user_sync
	local army

	local cur_time = os.time()

	local function doLogic( req )
		local speed_item_list = CONF.PARAM.get("speed_item").PARAM
		if CoreItem.checkItem(speed_item_list[req.type], 1, item_list, user_info) == false then
			return 1
		end
		local key_list = Tools.split(req.army_key, "_") 
		local planet_user = PlanetCache.getUser(key_list[1])
		army = PlanetCache.getArmy(req.army_key)

		if army.status == PlanetStatusMachine.Status.kMove or army.status == PlanetStatusMachine.Status.kMoveBack then
			
			if army.line == nil then
				return 3
			end

			local items = {[speed_item_list[req.type]] = 1}

			local itemConf = CONF.ITEM.get(speed_item_list[req.type])
		
			if not CoreItem.checkItems( items, item_list, user_info) then
				
				if itemConf.BUY_TYPE == 2 then
					items = { [refid.res[1]] = itemConf.BUY_VALUE }
				else
					items = { [refid.money] = itemConf.BUY_VALUE }
				end

				if not CoreItem.checkItems( items, item_list, user_info) then
					return 4
				end
			end

			if itemConf.VALUE >= 0 then
				local remain = army.line.need_time - (cur_time - army.line.begin_time + army.line.sub_time)
				if remain > 0 then
					army.line.sub_time = math.floor(army.line.sub_time + remain * (itemConf.VALUE *0.01))
				
					PlanetCache.saveUserData( planet_user )

					local cur_time = os.time()
					PlanetStatusMachine[army.status_machine].doLogic(cur_time, planet_user, army)
				end
			else
				army.line.sub_time = math.floor(army.line.sub_time + (-itemConf.VALUE))
				PlanetCache.saveUserData( planet_user )

				local cur_time = os.time()
				PlanetStatusMachine[army.status_machine].doLogic(cur_time, planet_user, army)
			end
	
			CoreItem.expendItems(items, item_list, user_info)

			user_sync = CoreItem.makeSync(items, item_list, user_info)
		else
			return 2
		end

		return 0
	end

	local ret = doLogic(req)
	local resp = {
		result = ret,
		type = req.type,
		user_sync = user_sync,
		army = army,
	}

	local resp_buff = Tools.encode("PlanetSpeedUpResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, item_list_buff
end

function planet_shield_base_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("PlanetShieldResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function planet_shield_base_do_logic( req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("PlanetShieldReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local planet_user = PlanetCache.getUser(user_info.user_name)

	local function doLogic( req )
		local shield_base_item_list = CONF.PARAM.get("planet_shield_base_item").PARAM
		local index
		for i=1,#shield_base_item_list do
			if req.item_id == shield_base_item_list[i] then
				index = i
				break
			end
		end
		if index == nil then
			return 1
		end

		local use_item_list = {[req.item_id] = 1}
		if CoreItem.checkItems(use_item_list, item_list, user_info) == false then
			return 2
		end

		if Tools.isEmpty(planet_user.army_list) == false then
			for i,v in ipairs(planet_user.army_list) do
				if v.status_machine == 1 then
					local element = PlanetCache.getElement(v.element_global_key)
					if element.res_data.user_name ~= nil and element.res_data.user_name ~= "" then
						return 3
					end
				else
					return 3
				end
			end
		end

		local item_conf = CONF.ITEM.get(req.item_id)

		local base = PlanetCache.getElement(planet_user.base_global_key)

		if base.base_data.shield_start_time == nil or base.base_data.shield_start_time == 0 then
			base.base_data.shield_start_time = os.time()
			base.base_data.shield_time = 0
		end
		base.base_data.shield_type = nil
		base.base_data.shield_time = base.base_data.shield_time + item_conf.VALUE

		local node_id = tonumber(Tools.split(planet_user.base_global_key, "_")[1])

		PlanetCache.saveNodeDataByID(node_id)

		PlanetCache.broadcastUpdate(planet_user.user_name, node_id)

		CoreItem.expendItems(use_item_list, item_list, user_info)
		local user_sync = CoreItem.makeSync(use_item_list, item_list, user_info)

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("PlanetShieldResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, item_list_buff
end

function planet_move_base_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("PlanetMoveBaseResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function planet_move_base_do_logic( req_buff, user_name, user_info_buff, item_list_buff)
	local req = Tools.decode("PlanetMoveBaseReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local planet_user = PlanetCache.getUser(user_info.user_name)

	local user_sync

	local node_update_list = {}

	local function addToNodeList( id )
		for i,v in ipairs(node_update_list) do
			if v == id then
				return
			end
		end
		table.insert(node_update_list, id)
	end

	local function doLogic( req )
		local key_list = Tools.split(planet_user.base_global_key, "_")
		local base = PlanetCache.getElement(planet_user.base_global_key)
		local node_id
		local pos

		local cur_nation = CONF.PLANETWORLD.get(tonumber(Tools.split(planet_user.base_global_key, "_")[1])).NATION

		if req.type == 1 then
			local planet_move_base_item = CONF.PARAM.get("planet_move_base_item").PARAM
			if CoreItem.checkItem(planet_move_base_item, 1, item_list, user_info) == false then
				return "NO_ITEM"
			end
	
			if PlanetCache.hasElementInGlobal(req.pos.x, req.pos.y) then
				return "HAS_ELEMENT"
			end
	
			node_id = PlanetCache.getNodeIDByGlobalPos(req.pos)

			local node_conf = CONF.PLANETWORLD.get(node_id)



			if node_conf.TYPE == 1 then
				if node_conf.NATION ~= cur_nation then
					return "ERROR_NATION"
				end
			elseif node_conf.TYPE == 2 then

				local city = PlanetCache.getCity(node_id)
				if city == nil then
					return "ERROR_CITY"
				end
				local my_group_id = user_info.group_data and user_info.group_data.groupid or nil
				
				if city.city_data.groupid == nil or city.city_data.groupid == "" or city.city_data.groupid ~= my_group_id then
					return "ERROR_CITY"
				end

				if city.city_data.status == 2 then
					return "ERROR_CITY"
				end
			elseif node_conf.TYPE == 3 then

				return "ERROR_CITY"
			end
			
			
			local node = PlanetCache.getNodeByID(node_id)

			PlanetCache.moveElement( node, base, {req.pos})

			local items = {[planet_move_base_item] = 1}

			CoreItem.expendItems( items, item_list, user_info)

			user_sync = CoreItem.makeSync(items, item_list, user_info)
		else

			local planet_rand_move_base_item = CONF.PARAM.get("planet_rand_move_base_item").PARAM
			if CoreItem.checkItem(planet_rand_move_base_item, 1, item_list, user_info) == false then
				return "NO_ITEM"
			end

			if (Tools.isEmpty(planet_user.attack_me_list)==false) then
				--Tools._print("PlanetMoveBaseReq  "..user_info.user_name)
				return "ERROR_CITY"
			end

			local node_id_list = {}

			local id_list = CONF.PLANETWORLD.getIDList()
			for i,id in ipairs(id_list) do
				local nodeConf = CONF.PLANETWORLD.get(id)

				if nodeConf.TYPE == 1 and nodeConf.NATION == cur_nation then
					table.insert(node_id_list, nodeConf.ID)
				end
			end

			pos, node_id = PlanetCache.randEmptyPosByNodeList(node_id_list)

			if pos == nil then
				return "ERROR_POS"
			end

			local node = PlanetCache.getNodeByID(node_id)

			PlanetCache.moveElement( node, base, {pos})

			local items = {[planet_rand_move_base_item] = 1}

			CoreItem.expendItems( items, item_list, user_info)

			user_sync = CoreItem.makeSync(items, item_list, user_info)
		end

		if Tools.isEmpty(planet_user.move_base_times_list) == true then
			planet_user.move_base_times_list = {0,0}
		end

		planet_user.move_base_times_list[req.type] = planet_user.move_base_times_list[req.type] + 1

		planet_user.base_global_key = base.global_key

		if Tools.isEmpty(planet_user.army_list) == false then
			for _,army in ipairs(planet_user.army_list) do
				local node_id_list = PlanetStatusMachine[army.status_machine].moveBase(os.time(), planet_user, army)
				if Tools.isEmpty(node_id_list) == false then
					for i,v in ipairs(node_id_list) do
						addToNodeList(v)
					end
				end
			end
		end

		PlanetCache.saveUserData( planet_user )

		local pre_node_id = tonumber(key_list[1])

		addToNodeList(pre_node_id)
		addToNodeList(node_id)

		return "OK"
	end

	local ret = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
		planet_user = planet_user,
	}

	PlanetCache.broadcastUpdate(planet_user.user_name, node_update_list)

	local resp_buff = Tools.encode("PlanetMoveBaseResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, item_list_buff
end


function planet_mark_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("PlanetMarkResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error")
	end
end

function planet_mark_do_logic( req_buff, user_name, user_info_buff)

	local req = Tools.decode("PlanetMarkReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local planet_user = PlanetCache.getUser(user_info.user_name)

	local function doLogic( req )

		if req.type == 1 then
			if req.name == nil or req.pos == nil then
				return 1
			end

			if Tools.isEmpty(planet_user.mark_list) == true then
				planet_user.mark_list = {}
			end

			if #planet_user.mark_list >= GolbalDefine.planet_mark_max then
				return 2
			end

			local dirty = false
			for i=1,CONF.DIRTYWORD.len do
				if string.find(req.name, CONF.DIRTYWORD[i].KEY) ~= nil then
					dirty = true
					break
				end
			end
			if dirty then
				return 3
			end

			local mark = {
				name = req.name,
				pos = req.pos,
			}

			table.insert(planet_user.mark_list, mark)

			PlanetCache.saveUserData( planet_user )

		elseif req.type == 2 then

			if req.name == nil or req.pos == nil then
				return 1
			end

			if Tools.isEmpty(planet_user.mark_list) == true then
				return 2
			end
			for i,v in ipairs(planet_user.mark_list) do
				if v.name == req.name then
					table.remove(planet_user.mark_list, i)
					break
				end
			end
			PlanetCache.saveUserData( planet_user )
		end

		return 0
	end

	local ret = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
		mark_list = planet_user.mark_list,
	}

	local resp_buff = Tools.encode("PlanetMarkResp", resp)
	user_info_buff = userInfo:getUserBuff()

	return resp_buff, user_info_buff
end

function planet_tower_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("PlanetTowerResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error")
	end
end

function planet_tower_do_logic( req_buff, user_name, user_info_buff)
	local req = Tools.decode("PlanetTowerReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local planet_user = PlanetCache.getUser(user_info.user_name)
	local resp_element

	local function doLogic(req)
		if req.element_global_key == nil then
			return 1
		end
	
		local element = PlanetCache.getElement( req.element_global_key )
		if element == nil or element.type ~= 13 then
			return 2
		end

		if element.tower_data.user_name ~= user_info.user_name then
			return 3
		end

		if req.type == 1 then
			element.tower_data.is_attack = true
			element.tower_data.occupy_begin_time = os.time()
			element.tower_data.attack_hp = {}
		else
			element.tower_data.is_attack = false
			element.tower_data.attack_hp = {}
		end

		resp_element = Tools.clone(element)
		if resp_element.tower_data.groupid ~= "" and resp_element.tower_data.groupid ~= nil then
			local group_main = GroupCache.getGroupMain(resp_element.tower_data.groupid)
			resp_element.tower_data.temp_info = GroupCache.toOtherGroupInfo(group_main)
			if resp_element.tower_data.temp_info ~= nil then
				local leader_user = GroupCache.GetGroupLeader(group_main)
				if leader_user ~= nil then
					local other_user_info = UserInfoCache.get(leader_user.user_name)
					if other_user_info ~= nil then
						resp_element.tower_data.user_info = other_user_info
					end
				end
			end
		elseif resp_element.tower_data.user_name ~= nil then
			local other_user_info = UserInfoCache.get(resp_element.tower_data.user_name)
			if other_user_info ~= nil then
				resp_element.tower_data.user_info = other_user_info
			end	
		else
			return 4
		end

		local node_id = tonumber(Tools.split(element.global_key, "_")[1])
		PlanetCache.saveNodeDataByID(node_id)

		return 0
	end

	local ret = doLogic(req)
	local resp = {
		result = ret,
		element = resp_element,
	}

	local resp_buff = Tools.encode("PlanetTowerResp", resp)
	user_info_buff = userInfo:getUserBuff()

	return resp_buff, user_info_buff
end

function planet_wangzuo_title_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("PLanetWangZuoTitleResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error")
	end
end

function planet_wangzuo_title_logic( req_buff, user_name, user_info_buff)
	local req = Tools.decode("PlanetWangZuoTitleReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()
	local function GetUserList(title_list)
		if Tools.isEmpty(title_list) then
			return nil 
		end
		local userlist = {}
		for _ , title in ipairs(title_list) do
			local other = UserInfoCache.get(title.user_name)
			if other ~= nil then
				table.insert(userlist,other)
			end
		end
		return userlist
	end

	local function GetTitle(req)
		local wangzuo = PlanetCache.getWangzuo()
		if (wangzuo == nil) then
			return 1
		end
		local title_list = Tools.clone(PlanetCache.GetWangZuoTitle())
		--Tools.print_t(title_list)
		return 0 , title_list ,GetUserList(title_list)
	end

	local function SetTitle(req)
		local wangzuo = PlanetCache.getWangzuo()
		if (wangzuo == nil or wangzuo.wangzuo_data.status == 2) then
			return 1
		end
		if  wangzuo.wangzuo_data.groupid ~= nil and  wangzuo.wangzuo_data.groupid ~= "" then
			if user_info.group_data == nil then
				return 2
			end
			if user_info.group_data.groupid ~= wangzuo.wangzuo_data.groupid then
				return 3
			end
			if user_info.group_data.job ~= GolbalDefine.enum_group_job.leader then
				return 3
			end
		else
			if wangzuo.wangzuo_data.user_name ~= user_info.user_name then
				return 3
			end

		end
		local other_user = UserInfoCache.get(req.user_name) 
		if other_user == nil then
			return 4
		end
		--这里需要判断有没有req.title ,现在没表1111111111111111111
		if CONF.TITLE_BUFF.get(req.title) == nil then
			return 5
		end
		PlanetCache.SetWangZuoTitle(req.user_name,req.title)
		local title_list = Tools.clone(PlanetCache.GetWangZuoTitle())
		return 0 , title_list ,GetUserList(title_list)
	end

	local function RemoveTitle(req)
		local wangzuo = PlanetCache.getWangzuo()
		if (wangzuo == nil or wangzuo.wangzuo_data.status == 2) then
			return 1
		end
		if  wangzuo.wangzuo_data.groupid ~= nil and  wangzuo.wangzuo_data.groupid ~= "" then
			if user_info.group_data == nil then
				return 2
			end
			if user_info.group_data.groupid ~= wangzuo.wangzuo_data.groupid then
				return 3
			end

			if user_info.group_data.job ~= 1 then
				return 3
			end
		else
			if wangzuo.wangzuo_data.user_name ~= user_info.user_name then
				return 3
			end
		end
		if user_info.user_name == req.user_name then --不能任命自己
			return 4 
		end

		PlanetCache.RemoveTitle(req.user_name)

		local title_list = Tools.clone(PlanetCache.GetWangZuoTitle())
		return 0 , title_list ,GetUserList(title_list)
	end

	local function GetOccupyList()
		local list = PlanetCache.GetWangZuoOccupy()
		if Tools.isEmpty(list) then
			return 1
		end
		list = Tools.clone(list)		
		for _,info in ipairs(list) do
			info.info = UserInfoCache.get(info.user_name) 
		end
		--Tools.print_t(list)
		return 0, list
	end

	local ret = -1
	local title_list 
	local occupy_list
	local user_list
	if (req.type==1) then
		ret , title_list ,user_list = GetTitle(req)
	elseif (req.type==2) then
		ret , title_list ,user_list = SetTitle(req)
	elseif (req.type==3) then
		ret , title_list ,user_list = RemoveTitle(req)
	elseif (req.type==4) then
		ret , occupy_list = GetOccupyList()
	end
	local resp = {
		result = ret,
		type = req.type,
		title_list = {wangzuo_title_list = title_list},
		occupy_list = {occupy_list = occupy_list},
		user_list = user_list,
	}
	--Tools.print_t(resp)
	local resp_buff = Tools.encode("PLanetWangZuoTitleResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end