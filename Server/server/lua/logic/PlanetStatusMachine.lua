
local Status = {
	kMove = 1,
	kMoveBack = 2,
	kMoveEnd = 3,
	kCollect = 4,
	kFishing = 5,
	kGuarde = 6,
	kAccompany = 7,
	kEnlist = 8,
}

local ResMachine = {}

local RuinsMachine = {}

local FishingMachine = {}

local SpyMachine = {}

local GuardeMachine = {}

local BaseAttackMachine = {}

local AccompanyMachine = {}

local CityAttackMachine = {}

local BossAttackMachine = {}

local EnlistMachine = {}

local MonsterAttackMachine = {}

local WangZuoMachine = {}

local WangZuoTowerMachine = {}

local function isAllZero( hp_list )
	for i,value in ipairs(hp_list) do
		if value > 0 then
			return false
		end
	end
	return true
end

local function isArrived(now_time, army_line)
	if army_line.begin_time == nil or army_line.sub_time == nil or army_line.need_time == nil then
		Tools._print("isArrived error",army_line.begin_time,army_line.sub_time,army_line.need_time)
		return true 
	end
	return now_time - army_line.begin_time + army_line.sub_time >= army_line.need_time 
end

local function getDestroyPercent( value )
	return math.floor(value / CONF.PARAM.get("planet_destroy_value_limit").PARAM * 100)
end

local function checkDestroyStage(value)
	local percent = getDestroyPercent(value)

	if percent < CONF.PARAM.get("planet_destroy_param").PARAM[1] then
		return 1
	elseif percent < CONF.PARAM.get("planet_destroy_param").PARAM[2] then
		return 2
	else
		return 3
	end
	return 0
end

local function moveEnd(planet_user, planet_army, status )

	planet_army.status = status

	if Tools.isEmpty(planet_army.line) == false then
		PlanetCache.removeArmyLineInNode(planet_army.line)

		planet_army.line = nil
	end

	if status == Status.kMoveEnd then
		PlanetCache.broadcastUserUpdate(planet_user.user_name, planet_user.user_name)
	end
	
end

local function moveArmy(now_time, src, dest, planet_user, planet_army, status)

	local pos_list, node_list = PlanetCache.pathReach( src, dest )

	planet_army.begin_time = 0

	planet_army.status = status

	if Tools.isEmpty(planet_army.line) == false then
		moveEnd(planet_user, planet_army, status)
	end
	if planet_army.speed <= 0 then
		LOG_ERROR("move army speed <= 0 !!!!!!")
	end
	planet_army.line = {
		user_key = string.format("%s_%d", planet_user.user_name, planet_army.guid),
		node_id_list = node_list,
		move_list = pos_list,
		begin_time = now_time,
		need_time = PlanetCache.getMoveTime(pos_list, planet_army.speed * 0.001),
		sub_time = 0,
	}

	PlanetCache.addArmyLineToNode(planet_army.line)

	if status == Status.kMoveBack then

		if Tools.isEmpty(planet_army.army_key_list) == false then
			for i,army_key in ipairs(planet_army.army_key_list) do
				local army = PlanetCache.getArmy(army_key)
				local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])

				local dest_element = PlanetCache.getElement(user.base_global_key) 
	
				moveArmy(now_time, src, dest_element.pos_list[1], user, army, status)

				PlanetCache.saveUserData(user)
			end
		end
	end

	return node_list
end

--简化返回方法 必须要有 line
local function moveArmyBack(now_time, planet_army )

	planet_army.status = Status.kMoveBack

	local already = now_time - planet_army.line.begin_time + planet_army.line.sub_time
	if already > planet_army.line.need_time then
		already = planet_army.line.need_time
	end
	planet_army.line.begin_time = now_time - (planet_army.line.need_time - already)
	
	planet_army.line.sub_time = 0

	local pos_list = {}
	for i=#planet_army.line.move_list,1, -1 do
		table.insert(pos_list, planet_army.line.move_list[i])
	end
	
	planet_army.line.move_list = pos_list

	return Tools.clone(planet_army.line.node_id_list)
end

local function checkArmyAllDead(army)

	for i,v in ipairs(army.ship_list) do
		if Tools.checkShipDurable(v) == false then
			v.attr[CONF.EShipAttr.kHP] = 0
		end
	end

	for i,v in ipairs(army.ship_list) do
		if v.attr[CONF.EShipAttr.kHP] > 0 then
			
			return false
		end
	end
	return true
end

local function checkElement(element, type, global_pos)
	if element.type ~= type then
		return false
	end
	local flag = false
	for i,v in ipairs(element.pos_list) do
		if v.x == global_pos.x and v.y == global_pos.y then
			flag = true
			break
		end
	end
	return flag
end

local function addItemToList(item, item_list)

	for i,v in ipairs(item_list) do
		if v.id == item.id then
			v.num = item.num + v.num
			return
		end
	end
	table.insert(item_list, item)
end

local function getCollectSpeed( planet_user, element )

	local other_user_info = UserInfoCache.get(planet_user.user_name)

	local addition_speed = 0

	local collect_speed
	local res_conf 
	if element.type == 2 then

		res_conf = CONF.PLANET_RES.get(element.res_data.id)

		collect_speed = element.res_data.collect_speed

	elseif element.type == 6 then

		res_conf = CONF.PLANET_RES.get(element.city_res_data.id)

		local user = PlanetCache.getCityResUser(element, planet_user.user_name)
	
		collect_speed = user.collect_speed
	end

	if other_user_info.groupid ~= "" and other_user_info.groupid ~= nil then

		local group_main = GroupCache.getGroupMain(other_user_info.groupid)

		addition_speed = math.floor(Tools.getValueByTechnologyAddition(collect_speed, CONF.ETechTarget_1.kWorldRes, res_conf.TYPE, CONF.ETechTarget_3_Res.kCollect, nil, group_main.tech_list))
	end
	
	return collect_speed + addition_speed
end

local function collectFinish( now_time, planet_user, planet_army, element, flag )

	if flag == true then

		local allBearer = Tools.GetAllShipLoad(planet_army.ship_list)

		local begin_time
		if element.type == 2 then
			begin_time = element.res_data.begin_time
		elseif element.type == 6 then

			local user = PlanetCache.getCityResUser(element, planet_user.user_name)
			begin_time = user.begin_time
		end
		local get_storage = (now_time - begin_time) * getCollectSpeed( planet_user, element)

		local res_conf

		if element.type == 2 then

			res_conf = CONF.PLANET_RES.get(element.res_data.id)

			if get_storage >= allBearer then
				get_storage = allBearer
			elseif element.res_data.cur_storage < get_storage then
				get_storage = element.res_data.cur_storage
			end

			element.res_data.cur_storage = element.res_data.cur_storage - get_storage

			Tools._print("collectFinish",element.res_data.cur_storage,get_storage,allBearer)

		elseif element.type == 6 then

			res_conf = CONF.PLANET_RES.get(element.city_res_data.id)

			if get_storage >= allBearer then
				get_storage = allBearer
			elseif element.city_res_data.cur_storage < get_storage then
				get_storage = element.city_res_data.cur_storage
			end

			element.city_res_data.cur_storage = element.city_res_data.cur_storage - get_storage

			if element.city_res_data.cur_storage <= 0 then
				element.city_res_data.cur_storage = 0
				element.city_res_data.restore_start_time = now_time
			end
		end

		if Tools.isEmpty(planet_army.item_list) == true then
			planet_army.item_list = {}
		end

		local item = {
			id = res_conf.PRODUCTION_ID,
			num = get_storage,
			guid = 0,
		}

		addItemToList(item, planet_army.item_list)
		
	end

	local id 
	if element.type == 2 then
	
		element.res_data.user_name = nil
		element.res_data.begin_time = nil
		element.res_data.collect_speed = nil
		element.res_data.army_guid = nil

		id = element.res_data.id
	elseif element.type == 6 then

		PlanetCache.removeCityResUser(element, planet_user.user_name)

		id = element.city_res_data.id
	end

	local node_id = tonumber(Tools.split(element.global_key, "_")[1])
	PlanetCache.saveNodeDataByID(node_id)


	local report = {
		type = 1,
		result = true,
		item_list_list = {
			{item_list = planet_army.item_list},
		},
		id = id,
		pos_list = element.pos_list,
	}
	RedoList.addPlanetMail(planet_user.user_name, report)

	local mail_update = CoreMail.getMultiCast(planet_user.user_name)
      	local mail_update_buff = Tools.encode("Multicast", mail_update)
      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)
      	return node_id
end

local function resMoveBack(now_time, planet_user, planet_army, element, flag)

	collectFinish( now_time, planet_user, planet_army, element, flag )

      	local src_pos = element.pos_list[1]

	local dest_element = PlanetCache.getElement(planet_user.base_global_key) 
	local dest_pos = dest_element.pos_list[1]

	local node_list = moveArmy(now_time, src_pos, dest_pos, planet_user, planet_army, Status.kMoveBack)

      	return node_list
end


local function alreadyGuarde(user_name, guarde_list )

	if Tools.isEmpty(guarde_list) == false then
		for i,army_key in ipairs(guarde_list) do
			if Tools.split(army_key, "_")[1] == user_name then
				return true
			end
		end
	end
	return false
end

local function guarde(element, planet_user, planet_army )

	local guarde_list
	if element.type == 1 then
		guarde_list = element.base_data.guarde_list
	elseif element.type == 5 then
		guarde_list = element.city_data.guarde_list
	elseif element.type == 12 then
		guarde_list = element.wangzuo_data.guarde_list
	elseif element.type == 13 then
		guarde_list = element.tower_data.guarde_list
	end
	
	if Tools.isEmpty(guarde_list) == true then
		guarde_list = {}
	end
	table.insert(guarde_list, planet_army.army_key)

	if element.type == 1 then
		element.base_data.guarde_list = guarde_list
	elseif element.type == 5 then
		element.city_data.guarde_list = guarde_list
	elseif element.type == 12 then
		element.wangzuo_data.guarde_list = guarde_list
	elseif element.type == 13 then
		element.tower_data.guarde_list = guarde_list	
	end

	moveEnd(planet_user, planet_army, Status.kGuarde)
end



local function occupyCity(element, groupid, user_name, now_time)
	if element.type ~= 5 then
		return
	end
	element.city_data.occupy_begin_time = now_time

	element.city_data.user_name = user_name
	
	element.city_data.groupid = groupid

	local group_main = GroupCache.getGroupMain(groupid)

	local cityConf = CONF.PLANETCITY.get(element.city_data.id)
	if Tools.isEmpty(group_main.occupy_city_list) == true then
		group_main.occupy_city_list = {}
	end
	table.insert(group_main.occupy_city_list, element.global_key)

	if Tools.isEmpty(group_main.tech_list) == true then
		group_main.tech_list = {}
	end
	for i, id in ipairs(cityConf.BUFF) do
		local has = false
		for i,v in ipairs(group_main.tech_list) do
			if v.tech_id == id then
				has = true
				v.city_buff_count = v.city_buff_count + 1
			end
		end
		if has == false then
			local tech = {
				tech_id = id,
				status = 3,
				city_buff_count = 1,
			}
			table.insert(group_main.tech_list, tech)
		end
	end
	
	GroupCache.update(group_main, user_name, true)
end

local function calAttakBaseGetRes( base, attacker_user_name,  hurter_user_name, attack_ship)

	local attacker_other_user_info = UserInfoCache.get(attacker_user_name)
	local hurter_other_user_info = UserInfoCache.get(hurter_user_name)

	local attacker_sync_user = SyncUserCache.getSyncUser(attacker_user_name)
	local hurter_sync_user = SyncUserCache.getSyncUser(hurter_user_name)
	local get_res = {0,0,0,0}

	local percent = (100 - getDestroyPercent(base.base_data.destroy_value)) * 0.01
	local levelcha = CONF.PARAM.get("level_difference_value").PARAM
	local param1 = levelcha/(math.abs(attacker_other_user_info.level - hurter_other_user_info.level) + levelcha)
	local powercha = CONF.PARAM.get("ratio_difference_value").PARAM
	local param2 = powercha/(math.abs(attacker_other_user_info.power / hurter_other_user_info.power - 1) + powercha)
	--Tools._print("attack percent = ",percent,param1,param2,attacker_other_user_info.power,hurter_other_user_info.power,attacker_other_user_info.level,hurter_other_user_info.level)

	local building_10_conf = CONF.BUILDING_10.get(hurter_other_user_info.building_level_list[CONF.EBuilding.kWarehouse] or 1)
	local building_14_conf = CONF.BUILDING_14.get(attacker_other_user_info.building_level_list[CONF.EBuilding.kWarWorkshop] or 1)
	local allRes = 0
	for i=2,4 do
		get_res[i] = math.floor(hurter_sync_user.res[i] * percent * (CONF.PARAM.get("planet_rob_res").PARAM[i] * 0.01) * param1 * param2 + 1)
		--Tools._print("attack res = ",hurter_sync_user.res[i],(CONF.PARAM.get("planet_rob_res").PARAM[i] * 0.01),get_res[i])

		if hurter_sync_user.res[i] < building_10_conf.RESOURCE_PROTECT_LIMIT[i] then
			get_res[i] = 0
		elseif hurter_sync_user.res[i] - get_res[i] < building_10_conf.RESOURCE_PROTECT_LIMIT[i] then
			get_res[i] = hurter_sync_user.res[i] - building_10_conf.RESOURCE_PROTECT_LIMIT[i]
		end

		if get_res[i] > building_14_conf.CARRYING_RESOURCES[i] then
			get_res[i] = building_14_conf.CARRYING_RESOURCES[i]
		end
		allRes = allRes + get_res[i]
	end

	--算负重
	if attack_ship then
		local allLoad = Tools.GetAllShipLoad(attack_ship)
		local surplus = allRes - allLoad
		--Tools._print("calAttakBaseGetRes",get_res[2],get_res[3],get_res[4],allRes,allLoad,surplus)
		if surplus > 0 then
			local mean = math.ceil(surplus/3)
			-- 先平均减
			for i = 2 , 4 do
				if get_res[i] > mean then
					surplus = surplus - mean
					get_res[i] = get_res[i] - mean
				else
					surplus = surplus - get_res[i]
					get_res[i] = 0
				end
			end
			--平均减扣不够再按最大减
			if surplus > 0 then
				for i = 2 , 4 do
					if get_res[i] > surplus then
						get_res[i] = get_res[i] - surplus
						surplus = 0
					else
						surplus = surplus - get_res[i]
						get_res[i] = 0
					end
					if get_res[i] <= 0 then
						break
					end
				end
			end
		end
		--Tools.print_t(get_res)
	end

	return get_res
end

local function addUpdateNodeList( main_list, node_list )
	for i,node_id in ipairs(node_list) do
		local has = false
		for _,v in ipairs(main_list) do
			if v == node_id then
				has = true
				break
			end
		end
		if has == false then
			table.insert(main_list, node_id)
		end
	end
end

function ResMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time

	local src_element = PlanetCache.getElement(planet_user.base_global_key)
	local src = src_element.pos_list[1]

	local dest_element = PlanetCache.getElement(planet_army.element_global_key)
	local dest = dest_element.pos_list[1]

	if dest_element.type == 2 then
		if dest_element.res_data.user_name ~= nil and dest_element.res_data.user_name ~= "" then
			PlanetCache.closeShield(src_element)

			PlanetCache.userAddAttacker( dest_element.res_data.user_name, planet_army.army_key)
		end
	end

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)


end

function ResMachine.back( now_time, planet_user, planet_army )
	local node_list
	if planet_army.status == Status.kMove then

		local dest_element = PlanetCache.getElement(planet_army.element_global_key)
		if dest_element 
		and dest_element.type == 2
		and dest_element.res_data.user_name ~= nil 
		and dest_element.res_data.user_name ~= ""
		and dest_element.res_data.user_name ~= planet_user.user_name then
			PlanetCache.userRemoveAttacker( dest_element.res_data.user_name, planet_army.army_key)
		end

		node_list = moveArmyBack(now_time, planet_army)

	elseif planet_army.status == Status.kCollect then

		local element = PlanetCache.getElement(planet_army.element_global_key)

		node_list = resMoveBack( now_time, planet_user, planet_army, element, true )
	else
		return false
	end

	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
	return true
end

function ResMachine.moveBase( now_time, planet_user, planet_army)
	local node_id_list
	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		local dest_element = PlanetCache.getElement(planet_army.element_global_key)
		if dest_element
		and dest_element.type == 2
		and dest_element.res_data.user_name ~= nil 
		and dest_element.res_data.user_name ~= ""
		and dest_element.res_data.user_name ~= planet_user.user_name then

			PlanetCache.userRemoveAttacker( dest_element.res_data.user_name, planet_army.army_key)
		end

		node_id_list = planet_army.line.node_id_list
		moveEnd(planet_user, planet_army, Status.kMoveEnd)
		PlanetCache.saveUserData(planet_user)
	elseif planet_army.status == Status.kCollect then
		local element = PlanetCache.getElement(planet_army.element_global_key)
		local node_id = collectFinish( now_time, planet_user, planet_army, element, true )
		node_id_list = {node_id}
		moveEnd(planet_user, planet_army, Status.kMoveEnd)
		PlanetCache.saveUserData(planet_user)
	end
	return node_id_list
end

function ResMachine.doLogic(now_time, planet_user, planet_army)

	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then

			local element = PlanetCache.getElement(planet_army.element_global_key)

			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]
			local src_pos = planet_army.line.move_list[1]
			--元素消失 队伍返回
			if element == nil or (checkElement(element, 2, dest_pos) == false and checkElement(element, 6, dest_pos) == false) then
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			local isWin
			local event_list
			local attacker_hp_list
			local hurter_hp_list
			local video_key_list = {}

			local my_mail_user_list = {}
			local enemy_mail_user_list = {}

			local isFight = false

			local res_conf

			if element.type == 2 then

				res_conf = CONF.PLANET_RES.get(element.res_data.id)

				--如果有人
				if element.res_data.user_name ~= nil and element.res_data.user_name ~= "" then

					isFight = true

					local other_planet_user = PlanetCache.getUser( element.res_data.user_name )

					PlanetCache.userRemoveAttacker( other_planet_user.user_name, planet_army.army_key)

					--同一公会返回
					local other_user_info1 = UserInfoCache.get(planet_user.user_name)
					local other_user_info2 = UserInfoCache.get(other_planet_user.user_name)
					if other_user_info1.groupid ~= nil 
					and other_user_info2.groupid ~= nil
					and other_user_info1.groupid ~= ""
					and other_user_info2.groupid ~= ""
					and other_user_info1.groupid == other_user_info2.groupid then
						local node_list = moveArmyBack(now_time, planet_army)
						PlanetCache.saveUserData(planet_user)
						PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
						return
					end

					local other_planet_army
					for i,army in ipairs(other_planet_user.army_list) do
						if army.guid == element.res_data.army_guid then
							other_planet_army = army
							break
						end
					end

					for i,v in ipairs(planet_army.ship_list) do
						if Tools.checkShipDurable(v) == false then
							v.attr[CONF.EShipAttr.kHP] = 0
						end
					end

					for i,v in ipairs(other_planet_army.ship_list) do
						if Tools.checkShipDurable(v) == false then
							v.attr[CONF.EShipAttr.kHP] = 0
						end
					end
					

					isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(planet_army.ship_list, planet_army.lineup_hp, other_planet_army.ship_list, other_planet_army.lineup_hp)

					CoreUser.battleCount(planet_user.user_name, other_planet_user.user_name, isWin)

					local pre_my_ship_energy_level_list = {0,0,0,0,0,0,0,0,0,}
					local pre_enemy_ship_energy_level_list = {0,0,0,0,0,0,0,0,0,}

					for i,v in ipairs(planet_army.ship_list) do

						if v.energy_level then
							pre_my_ship_energy_level_list[v.position] = v.energy_level
						end
						
						Tools.shipSubDurable( v, 2, isWin and 1 or 0, planet_army.tech_durable_param )

						Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
					end

					for i,v in ipairs(other_planet_army.ship_list) do

						if v.energy_level then
							pre_enemy_ship_energy_level_list[v.position] = v.energy_level
						end

						Tools.shipSubDurable( v, 2, isWin and 0 or 1, other_planet_army.tech_durable_param )

						Tools.shipSubEnergy( v, 2, isWin and 0 or 1, true)
					end


					local resp = {
						result = 2,
						attack_list = planet_army.ship_list,
						hurter_list = other_planet_army.ship_list,
						event_list = event_list,
						attacker_hp_list = planet_army.lineup_hp,
						hurter_hp_list = other_planet_army.lineup_hp,
					}
					local video_key = VideoCache.addVideo(planet_user.user_name, resp)
					table.insert(video_key_list, video_key)
					--胜利 前者返航
					if isWin == true then
						--这里就不保存了 下面会保存other_planet_user
						resMoveBack(now_time, other_planet_user, other_planet_army, element, false )
					end

					if hurter_hp_list ~= nil then
						other_planet_army.lineup_hp = hurter_hp_list
					end
					if attacker_hp_list ~= nil then
						planet_army.lineup_hp = attacker_hp_list
					end

					PlanetCache.saveUserData(other_planet_user)

					local mail_user1 = PlanetCache.createMailUser(planet_user, planet_army)
					mail_user1.pre_ship_energy_level_list = pre_my_ship_energy_level_list
					table.insert(my_mail_user_list, mail_user1)
					local mail_user2 = PlanetCache.createMailUser(other_planet_user, other_planet_army)
					mail_user2.pre_ship_energy_level_list = pre_enemy_ship_energy_level_list
					table.insert(enemy_mail_user_list, mail_user2)

					local report1 = {
						type = 3,
						result = true,
						id = element.res_data.id,
						pos_list = element.pos_list,
						isWin = isWin,
						video_key_list = video_key_list,
						my_data_list = my_mail_user_list,
						enemy_data_list = enemy_mail_user_list,
					}
					RedoList.addPlanetMail(planet_user.user_name, report1)

					local report2 = {
						type = 2,
						result = true,
						id = element.res_data.id,
						pos_list = element.pos_list,
						isWin = (not isWin),
						video_key_list = video_key_list,
						my_data_list = enemy_mail_user_list,
						enemy_data_list = my_mail_user_list,
					}
					RedoList.addPlanetMail(other_planet_user.user_name, report2)

					local mail_update = CoreMail.getMultiCast({planet_user.user_name, other_planet_user.user_name})
		      		      	local mail_update_buff = Tools.encode("Multicast", mail_update)
		      		      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)

				elseif element.res_data.hasMonster == false then

					isFight = true


					local lineup_monster = res_conf.MONSTER_LIST

					local hurter_list = {}
					for k,ship_id in ipairs(lineup_monster) do
						if ship_id > 0 then
							local ship_info = Tools.createShipByConf(ship_id)
							ship_info.position = k
							ship_info.body_position = {k}
							table.insert(hurter_list, ship_info)
						end
					end

					for i,v in ipairs(planet_army.ship_list) do
						if Tools.checkShipDurable(v) == false then
							v.attr[CONF.EShipAttr.kHP] = 0
						end
					end

					isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(planet_army.ship_list, planet_army.lineup_hp, hurter_list, nil)

					local pre_my_ship_energy_level_list = {0,0,0,0,0,0,0,0,0,}
					for i,v in ipairs(planet_army.ship_list) do

						if v.energy_level then
							pre_my_ship_energy_level_list[v.position] = v.energy_level
						end
						
						Tools.shipSubDurable( v, 2, isWin and 1 or 0, planet_army.tech_durable_param )

						Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
					end

				
					local resp = {
						result = 2,
						attack_list = planet_army.ship_list,
						hurter_list = hurter_list,
						event_list = event_list,
						attacker_hp_list = planet_army.lineup_hp,
					}
					local video_key = VideoCache.addVideo(planet_user.user_name, resp)
					table.insert(video_key_list, video_key)
					if attacker_hp_list ~= nil then
						planet_army.lineup_hp = attacker_hp_list
					end
					if isWin then
	 					element.res_data.hasMonster = false
	 				end

	 				local mail_user = PlanetCache.createMailUser(planet_user, planet_army)
	 				mail_user.pre_ship_energy_level_list = pre_my_ship_energy_level_list
	 				table.insert(my_mail_user_list, mail_user)
					local report = {
						type = 3,
						result = true,
						id = element.res_data.id,
						pos_list = element.pos_list,
						isWin = isWin,
						video_key_list = video_key_list,
						my_data_list = my_mail_user_list,
					}
					RedoList.addPlanetMail(planet_user.user_name, report)

					local mail_update = CoreMail.getMultiCast(planet_user.user_name)
		      		      	local mail_update_buff = Tools.encode("Multicast", mail_update)
		      		      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)
				end

			elseif element.type == 6 then

				res_conf = CONF.PLANET_RES.get(element.city_res_data.id)

				local other_user_info = UserInfoCache.get(planet_user.user_name)

				if Tools.isEmpty( element.city_res_data.user_list) == false then

					local flag = true
			
					if #element.city_res_data.user_list >= res_conf.LOAD_NUM then
						flag = false

					end
					if flag == true then
						for i,user in ipairs(element.city_res_data.user_list) do
							if user.user_name == planet_user.user_name then
								flag = false

								break
							end
						end
					end
				end

				if flag == true then
					if other_user_info.groupid == nil or other_user_info.groupid ~= element.city_res_data.groupid then
						flag = false

					end
				end

				if flag == true then
					if element.city_res_data.cur_storage <= 0 then

						flag = false
					end
				end

				if flag == false then
					local node_list = moveArmyBack(now_time, planet_army)
					PlanetCache.saveUserData(planet_user)
					PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
					return
				end
			end

			if not isFight  or (isFight and isWin) then
				--开始采集
				moveEnd(planet_user, planet_army, Status.kCollect)

				if element.type == 2 then

					element.res_data.user_name = planet_user.user_name
					element.res_data.begin_time = now_time
					element.res_data.collect_speed = GolbalDefine.collect_speed
					element.res_data.army_guid = planet_army.guid
				elseif element.type == 6 then
					if Tools.isEmpty(element.city_res_data.user_list) then
						element.city_res_data.user_list = {}
					end

					local user = {
						user_name = planet_user.user_name,
						begin_time = now_time,
						collect_speed =  GolbalDefine.collect_speed + res_conf.COLLECT,
						army_guid = planet_army.guid,
					}
					table.insert(element.city_res_data.user_list, user)
				end

				local key_list = Tools.split(element.global_key, "_") 
				node_id = tonumber(key_list[1])
				PlanetCache.saveNodeDataByID(node_id)


				local level_list = CONF.PARAM.get("task_planet_level_interval_colloct").PARAM
				local level_list_count = #level_list
				if Tools.isEmpty(planet_user.colloct_level_times_list) then
					planet_user.colloct_level_times_list = {}
					for i=1,level_list_count do
						planet_user.colloct_level_times_list[i] = 0
					end
				end				
				for i=1,level_list_count do
					if res_conf.LEVEL <= level_list[i] then
						planet_user.colloct_level_times_list[i] = planet_user.colloct_level_times_list[i] + 1
						break
					end
				end

				if Tools.isEmpty(planet_user.colloct_level_times_list_day) then
					planet_user.colloct_level_times_list_day = {}
					for i=1,level_list_count do
						planet_user.colloct_level_times_list_day[i] = 0
					end
				end
				for i=1,level_list_count do
					if res_conf.LEVEL <= level_list[i] then
						planet_user.colloct_level_times_list_day[i] = planet_user.colloct_level_times_list_day[i] + 1
						break
					end
				end

				if Tools.isEmpty(planet_user.seven_days_data) then
					planet_user.seven_days_data = {}
				end
				if planet_user.seven_days_data.colloct_level_times_list_day==nil then
					planet_user.seven_days_data.colloct_level_times_list_day = 1
				else
					planet_user.seven_days_data.colloct_level_times_list_day = planet_user.seven_days_data.colloct_level_times_list_day + 1
				end


			else
				--失败 返回
			
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
			end

			PlanetCache.saveUserData(planet_user)

		end

	elseif  planet_army.status == Status.kCollect then
		
		local element = PlanetCache.getElement(planet_army.element_global_key)
	
		local backFlag = false
		local allBearer = Tools.GetAllShipLoad(planet_army.ship_list)
		if element.type == 2 then
			if element.res_data.user_name ~= planet_user.user_name then
				return
			end
			begin_time = element.res_data.begin_time

			local get_storage = (now_time - element.res_data.begin_time) * getCollectSpeed( planet_user, element)
			Tools._print("get_storage",element.res_data.cur_storage,get_storage,allBearer)
			if get_storage >= allBearer then
				backFlag = true
			end

			if element.res_data.cur_storage <= get_storage then

				backFlag = true
			end

		elseif element.type == 6 then

			local user = PlanetCache.getCityResUser(element, planet_user.user_name)
		
			if user == nil then
				return 
			end

			local get_storage = (now_time - user.begin_time) * getCollectSpeed( planet_user, element)
			if get_storage >= allBearer then
				backFlag = true
			end

			local res_conf = CONF.PLANET_RES.get(element.city_res_data.id)
		
			if element.city_res_data.cur_storage <= get_storage  then
				
				backFlag = true
			end

			if  res_conf.CARRY > 0 and get_storage > res_conf.CARRY then
				get_storage = res_conf.CARRY
				backFlag = true
			end
		end


		if backFlag then

			resMoveBack(now_time, planet_user, planet_army, element, true )
	
			PlanetCache.saveUserData(planet_user)

			if element.type == 2 and element.res_data.cur_storage <= 0 then
				Tools._print("remove res element", element.res_data.cur_storage)
				PlanetCache.removeElement(element.global_key)
			end
		end
		
	elseif  planet_army.status == Status.kMoveBack then

		if isArrived(now_time, planet_army.line) then

	      	moveEnd(planet_user, planet_army, Status.kMoveEnd)
      	
			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end

function RuinsMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time

	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	local src = src_element.pos_list[1]

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local dest = dest_element.pos_list[1]

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
end

function RuinsMachine.back( now_time, planet_user, planet_army )

	local node_list

	if planet_army.status == Status.kMove then

		node_list = moveArmyBack(now_time, planet_army)
	else
		return false
	end

	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
	return true
end

function RuinsMachine.moveBase(now_time, planet_user, planet_army )

	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		local node_id_list = planet_army.line.node_id_list

		moveEnd(planet_user, planet_army, Status.kMoveEnd)

		PlanetCache.saveUserData(planet_user)

		return node_id_list
	end

	return nil
end

function RuinsMachine.doLogic(now_time, planet_user, planet_army)

	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then

			local element = PlanetCache.getElement(planet_army.element_global_key)
			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]

			--元素消失 队伍返回
			if element == nil or checkElement(element, 3, dest_pos) == false then
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			local ruinsConf = CONF.PLANET_RUINS.get(element.ruins_data.id)

			local hasMonster = false
			
			if math.random(1,100) < ruinsConf.MONSTER_RATE then
				hasMonster = true
			end

			local isWin
			local video_key_list = {}
			local event_list
			local attacker_hp_list
			local hurter_hp_list

			local pre_my_ship_energy_level_list
				
			if hasMonster then

				local lineup_monster = ruinsConf.MONSTER_LIST
				local hurter_list = {}
				for k,ship_id in ipairs(lineup_monster) do
					if ship_id > 0 then
						local ship_info = Tools.createShipByConf(ship_id)
						ship_info.position = k
						ship_info.body_position = {k}
						table.insert(hurter_list, ship_info)
					end
				end

				for i,v in ipairs(planet_army.ship_list) do
					if Tools.checkShipDurable(v) == false then
						v.attr[CONF.EShipAttr.kHP] = 0
					end
				end

				isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(planet_army.ship_list, planet_army.lineup_hp, hurter_list, nil)
				
				pre_my_ship_energy_level_list = {0,0,0,0,0,0,0,0,0,}

				for i,v in ipairs(planet_army.ship_list) do

					if v.energy_level then
						pre_my_ship_energy_level_list[v.position] = v.energy_level
					end
					
					Tools.shipSubDurable( v, 2, isWin and 1 or 0, planet_army.tech_durable_param )

					Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
				end

				local resp = {
					result = 2,
					attack_list = planet_army.ship_list,
					hurter_list = hurter_list,
					event_list = event_list,
					attacker_hp_list = planet_army.lineup_hp,
				}
				local video_key = VideoCache.addVideo(planet_user.user_name, resp)
				table.insert(video_key_list, video_key)
				if attacker_hp_list ~= nil then
					planet_army.lineup_hp = attacker_hp_list
				end
			else
				isWin = true
			end
			
			if (hasMonster and isWin) or not hasMonster then

				local items = Tools.getRewards( ruinsConf.REWARD_ID )
				if Tools.isEmpty(planet_army.item_list) == true then
					planet_army.item_list = {}
				end
				for id,num in pairs(items) do
					local item = {
						id = id,
						num = num,
						guid = 0,
					}
					addItemToList(item, planet_army.item_list)
				end

				PlanetCache.removeElement(element.global_key)

				local level_list = CONF.PARAM.get("task_planet_level_interval_ruins").PARAM
				local level_list_count = #level_list
				if Tools.isEmpty(planet_user.ruins_level_times_list) then
					planet_user.ruins_level_times_list = {}
					for i=1,level_list_count do
						planet_user.ruins_level_times_list[i] = 0
					end
				end
				for i=1,level_list_count do
					if ruinsConf.LEVEL <= level_list[i] then
						planet_user.ruins_level_times_list[i] = planet_user.ruins_level_times_list[i] + 1
						break
					end
				end

				if Tools.isEmpty(planet_user.ruins_level_times_list_day) then
					planet_user.ruins_level_times_list_day = {}
					for i=1,level_list_count do
						planet_user.ruins_level_times_list_day[i] = 0
					end
				end
				for i=1,level_list_count do
					if ruinsConf.LEVEL <= level_list[i] then
						planet_user.ruins_level_times_list_day[i] = planet_user.ruins_level_times_list_day[i] + 1
						break
					end
				end

				if Tools.isEmpty(planet_user.seven_days_data) then
					planet_user.seven_days_data = {}
				end
				if planet_user.seven_days_data.ruins_level_times_list_day==nil then
					planet_user.seven_days_data.ruins_level_times_list_day = 1
				else
					planet_user.seven_days_data.ruins_level_times_list_day = planet_user.seven_days_data.ruins_level_times_list_day + 1
				end
				
			end

			local my_mail_user = PlanetCache.createMailUser(planet_user, planet_army)
			my_mail_user.pre_ship_energy_level_list = pre_my_ship_energy_level_list
			local my_mail_user_list = {my_mail_user}
			local report = {
				type = 5,
				result = true,
				item_list_list = {
					{item_list = planet_army.item_list},
				},
				id = element.ruins_data.id,
				pos_list = element.pos_list,
				isWin = isWin,
				video_key_list = video_key_list,
				my_data_list = my_mail_user_list,
			}
			RedoList.addPlanetMail(planet_user.user_name, report)

			local mail_update = CoreMail.getMultiCast(planet_user.user_name)
      		      	local mail_update_buff = Tools.encode("Multicast", mail_update)
      		      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)

			moveArmyBack(now_time, planet_army)

			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveBack then


		if isArrived(now_time, planet_army.line) then

			
			moveEnd(planet_user, planet_army, Status.kMoveEnd)
			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end


function FishingMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time


	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	local src = src_element.pos_list[1]

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local dest = dest_element.pos_list[1]

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
end

function FishingMachine.removeUser( planet_army )
	local element = PlanetCache.getElement(planet_army.element_global_key)
	element.ruins_data.user_name = nil
	element.ruins_data.begin_time = nil
	element.ruins_data.army_guid = nil
	element.ruins_data.need_time = nil

	local key_list = Tools.split(element.global_key, "_") 
	node_id = tonumber(key_list[1])
	PlanetCache.saveNodeDataByID(node_id)

	return node_id
end

function FishingMachine.back( now_time, planet_user, planet_army )

	local node_list

	if planet_army.status == Status.kMove then

		node_list = moveArmyBack(now_time, planet_army)

	elseif planet_army.status == Status.kFishing then

		FishingMachine.removeUser( planet_army )

		local element = PlanetCache.getElement(planet_army.element_global_key)
		local base = PlanetCache.getElement(planet_user.base_global_key)

		node_list = moveArmy(now_time, element.pos_list[1], base.pos_list[1], planet_user, planet_army, Status.kMoveBack)
	else
		return false
	end

	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
	return true
end

function FishingMachine.moveBase(now_time, planet_user, planet_army )
	local node_id_list
	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		node_id_list = planet_army.line.node_id_list

		moveEnd(planet_user, planet_army, Status.kMoveEnd)

		PlanetCache.saveUserData(planet_user)

	elseif planet_army.status == Status.kFishing then

		local node_id = FishingMachine.removeUser( planet_army )
		node_id_list = {node_id}

		moveEnd(planet_user, planet_army, Status.kMoveEnd)

		PlanetCache.saveUserData(planet_user)
	end

	return node_id_list
end

function FishingMachine.doLogic(now_time, planet_user, planet_army)

	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then

			local element = PlanetCache.getElement(planet_army.element_global_key)
			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]

			--元素消失 或者 有人 队伍返回
			if element == nil or checkElement(element, 3, dest_pos) == false or (element.ruins_data.user_name ~= nil and element.ruins_data.user_name ~= "") then
			
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			local ruinsConf = CONF.PLANET_RUINS.get(element.ruins_data.id)

			--开始打捞
			planet_army.status = Status.kFishing

			moveEnd(planet_user, planet_army, Status.kFishing)

			PlanetCache.saveUserData(planet_user)

			element.ruins_data.user_name = planet_user.user_name
			element.ruins_data.begin_time = now_time
			element.ruins_data.army_guid = planet_army.guid
			element.ruins_data.need_time = ruinsConf.TIME

			local key_list = Tools.split(element.global_key, "_") 
			node_id = tonumber(key_list[1])
			PlanetCache.saveNodeDataByID(node_id)
		end

	elseif  planet_army.status == Status.kFishing then

		local element = PlanetCache.getElement(planet_army.element_global_key)
		if (now_time - element.ruins_data.begin_time) >= element.ruins_data.need_time then

			local ruinsConf = CONF.PLANET_RUINS.get(element.ruins_data.id)

			local item_list_list = {}

			local success = math.random(1, 100) < ruinsConf.RATE

			item_list_list[1] = {
				item_list = {}
			}
			if success then
				local items = Tools.getRewards( ruinsConf.REWARD_ID )
				if Tools.isEmpty(planet_army.item_list) == true then
					planet_army.item_list = {}
				end
				for id,num in pairs(items) do
					local item = {
						id = id,
						num = num,
						guid = 0,
					}
					addItemToList(item, planet_army.item_list)
				end

				item_list_list[1].item_list = Tools.clone(planet_army.item_list) 

				if GolbalActivity.isOpen( 16001, now_time) then
					if CONF.GIFT_BAG.check(element.ruins_data.id) then
						local gift = CONF.GIFT_BAG.get(element.ruins_data.id)
						if gift then
							for i,v in ipairs(gift.WEIGHT) do
								if true or math.random(1,100) < v then
									local item = {
										id = gift.ITEM[i],
										num = gift.NUM[i],
										guid = 0,
									}
									print("add gift item=",gift.ITEM[i])
									addItemToList(item, planet_army.item_list)
									table.insert(item_list_list[1].item_list, item)
									break
								end
							end
						end
					end
				end


				local level_list = CONF.PARAM.get("task_planet_level_interval_fishing").PARAM
				local level_list_count = #level_list
				if Tools.isEmpty(planet_user.fishing_level_times_list) then
					planet_user.fishing_level_times_list = {}
					for i=1,level_list_count do
						planet_user.fishing_level_times_list[i] = 0
					end
				end
				for i=1,level_list_count do
					if ruinsConf.LEVEL <= level_list[i] then
						planet_user.fishing_level_times_list[i] = planet_user.fishing_level_times_list[i] + 1
						break
					end
				end

				if Tools.isEmpty(planet_user.fishing_level_times_list_day) then
					planet_user.fishing_level_times_list_day = {}
					for i=1,level_list_count do
						planet_user.fishing_level_times_list_day[i] = 0
					end
				end
				for i=1,level_list_count do
					if ruinsConf.LEVEL <= level_list[i] then
						planet_user.fishing_level_times_list_day[i] = planet_user.fishing_level_times_list_day[i] + 1
						break
					end
				end

				if Tools.isEmpty(planet_user.seven_days_data) then
					planet_user.seven_days_data = {}
				end
				if planet_user.seven_days_data.fishing_level_times_list_day==nil then
					planet_user.seven_days_data.fishing_level_times_list_day = 1
				else
					planet_user.seven_days_data.fishing_level_times_list_day = planet_user.seven_days_data.fishing_level_times_list_day + 1
				end
				
			end

			if Tools.isEmpty(item_list_list[1]) then
				local item = {
					id = 0,
					num = 0,
					guid = 0,
				}
				item_list_list[1].item_list = {item}
			end

			local other_user_info = UserInfoCache.get(planet_user.user_name)
			
			if other_user_info.groupid ~= "" and other_user_info.groupid ~= nil then
				local group_main = GroupCache.getGroupMain(other_user_info.groupid)
				local groupConf = CONF.GROUP.get(group_main.level)
				local group_reward_list
				if success then
					group_reward_list = groupConf.SUP_PACK
				else
					group_reward_list = groupConf.CON_PACK
				end
				item_list_list[2] = {
					item_list = {}
				}
				for i,reward_id in ipairs(group_reward_list) do
					local items = Tools.getRewards( reward_id )
					if Tools.isEmpty(planet_army.item_list) == true then
						planet_army.item_list = {}
					end
					for id,num in pairs(items) do
						local item = {
							id = id,
							num = num,
							guid = 0,
						}
						addItemToList(item, planet_army.item_list)

						table.insert(item_list_list[2].item_list, item)
					end
				end

			end

			--Tools.print_t(item_list_list)

			local report = {
				type = 4,
				result = success,
				item_list_list = item_list_list,
				id = element.ruins_data.id,
				pos_list = element.pos_list,
			}

			RedoList.addPlanetMail(planet_user.user_name, report)

			local mail_update = CoreMail.getMultiCast(planet_user.user_name)
      		      	local mail_update_buff = Tools.encode("Multicast", mail_update)
      		      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)

      		      	local src_pos = element.pos_list[1]
      		      	local base = PlanetCache.getElement(planet_user.base_global_key)
      		      	local dest_pos = base.pos_list[1]

			PlanetCache.removeElement(element.global_key)

			moveArmy(now_time, src_pos, dest_pos, planet_user, planet_army, Status.kMoveBack)
	
			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveBack then

		if isArrived(now_time, planet_army.line) then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)
			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end

function SpyMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time


	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	local src = src_element.pos_list[1]

	PlanetCache.closeShield(src_element)

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local dest = dest_element.pos_list[1]

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)

	if dest_element.type == 1 then

		PlanetCache.userAddAttacker( dest_element.base_data.user_name, planet_army.army_key )

	elseif dest_element.type == 2 then

		if dest_element.res_data.user_name ~= nil and dest_element.res_data.user_name ~= "" then

			PlanetCache.userAddAttacker( dest_element.res_data.user_name, planet_army.army_key)
		end
	end
end

function SpyMachine.back( now_time, planet_user, planet_army )
	local node_list 
	if planet_army.status == Status.kMove then

		node_list = moveArmyBack(now_time, planet_army)

		local dest_element = PlanetCache.getElement(planet_army.element_global_key)
		if dest_element.type == 1 then

			PlanetCache.userRemoveAttacker( dest_element.base_data.user_name, planet_army.army_key )

		elseif dest_element.type == 2 then

			if dest_element.res_data.user_name ~= nil and dest_element.res_data.user_name ~= "" then
				PlanetCache.userRemoveAttacker( dest_element.res_data.user_name, planet_army.army_key)
			end
		end
	else
		return false
	end

	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)

	return true
end

function SpyMachine.moveBase(now_time, planet_user, planet_army )
	local node_id_list
	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		if planet_army.status == Status.kMove then
			local dest_element = PlanetCache.getElement(planet_army.element_global_key)
			if dest_element.type == 2 then
				if dest_element.res_data.user_name ~= nil 
				and dest_element.res_data.user_name ~= "" then

					PlanetCache.userRemoveAttacker( dest_element.res_data.user_name, planet_army.army_key)
				end
			elseif dest_element.type == 1 then

				PlanetCache.userRemoveAttacker( dest_element.base_data.user_name, planet_army.army_key )
			end
		end

		node_id_list = planet_army.line.node_id_list

		moveEnd(planet_user, planet_army, Status.kMoveEnd)

		PlanetCache.saveUserData(planet_user)
	end

	return node_id_list
end

function SpyMachine.doLogic(now_time, planet_user, planet_army)
	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then

			local element = PlanetCache.getElement(planet_army.element_global_key)

			local my_base = PlanetCache.getElement(planet_user.base_global_key)

			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]
			local src_pos = planet_army.line.move_list[1]

			local need_back = false

			--元素消失 队伍返回
			if element == nil then
				need_back = true
			elseif element.type == 1 then
				if checkElement(element, 1, dest_pos) == false then
					need_back = true
				else
					--同一公会返回
					local other_user_info1 = UserInfoCache.get(planet_user.user_name)
					local other_user_info2 = UserInfoCache.get(element.base_data.user_name)

					if other_user_info1.groupid ~= nil 
					and other_user_info1.groupid ~= ""
					and other_user_info1.groupid == other_user_info2.groupid then
						need_back = true
					end

					PlanetCache.userRemoveAttacker( element.base_data.user_name, planet_army.army_key )
				end


			elseif element.type == 2 then

				if element == nil or checkElement(element, 2, dest_pos) == false then
					need_back = true
				else
					local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
					if dest_element.res_data.user_name ~= nil 
					and dest_element.res_data.user_name ~= "" then

						PlanetCache.userRemoveAttacker( element.res_data.user_name, planet_army.army_key)
					end
				end
				
			elseif element.type == 5 then
				if checkElement(element, 5, dest_pos) == false then
					need_back = true
				else
					local other_user_info = UserInfoCache.get(planet_user.user_name)
					if other_user_info.groupid ~= "" 
					and other_user_info.groupid ~= nil 
					and element.city_data.groupid == other_user_info.groupid then
						need_back = true
					end
				end
			end

			if need_back then
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			--侦查报告
			local enemy_data_list = {}

			local item_list = {}

			local guarde_list

			local report_type
			local report_id
			local flag = true
			if element.type == 1 then
				local enemy_mail_user = PlanetCache.createMailUser(PlanetCache.getUser( element.base_data.user_name ))
				table.insert(enemy_data_list, 1, enemy_mail_user)


				local res_list = calAttakBaseGetRes(element, planet_user.user_name, element.base_data.user_name, planet_army.ship_list)
				for i=2,4 do
					if res_list[i] > 0 then
						local item = {
							id = refid.res[i],
							num = res_list[i],
							guid = 0,
						}
						table.insert(item_list, item)
					end
				end

				report_type = 6
				report_id = 0
				guarde_list = element.base_data.guarde_list
			elseif element.type == 5 then

				report_type = 15
				report_id = element.city_data.id

				flag = element.city_data.hasMonster
				guarde_list = element.city_data.guarde_list
			end

			if Tools.isEmpty(guarde_list) == false then

				for i,key in ipairs(guarde_list) do


					local key_list = Tools.split(key, "_")
					local guid = tonumber(key_list[2])
					local user = PlanetCache.getUser(key_list[1])
					local army = PlanetCache.getArmy(key)

					local mail_user = PlanetCache.createMailUser(user, army)

					table.insert(enemy_data_list, mail_user)
				end
			end

		
			local report = {
				type = report_type,
				result = flag,
				id = report_id,
				pos_list = element.pos_list,
				enemy_data_list = enemy_data_list,
				item_list_list = {
					{item_list = item_list},
				},
			}
			RedoList.addPlanetMail(planet_user.user_name, report)

			if element.type == 1 then
				--被侦查报告
				local enemy = PlanetCache.getUser(element.base_data.user_name)
				local enemy_mail_user = PlanetCache.createMailUser(planet_user)
				local report1 = {
					type = 7,
					result = true,
					id = 0,
					pos_list = my_base.pos_list,
					enemy_data_list = {enemy_mail_user},
				}
				RedoList.addPlanetMail(element.base_data.user_name, report1)
			end

			moveArmyBack(now_time, planet_army)
			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveBack then


		if isArrived(now_time, planet_army.line) then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)
			PlanetCache.saveUserData(planet_user)

		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end

function GuardeMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time

	if planet_army.element_global_key == planet_user.base_global_key then

		local base = PlanetCache.getElement(planet_army.element_global_key)
		guarde(base, planet_user, planet_army)
		local key_list = Tools.split(base.global_key, "_")
		local node_id = tonumber(key_list[1])
		PlanetCache.saveNodeDataByID(node_id)
	else

		local src_element = PlanetCache.getElement(planet_user.base_global_key) 
		local src = src_element.pos_list[1]

		PlanetCache.closeShield(src_element)

		local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
		local dest = dest_element.pos_list[1]

		local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

		PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
	end
end

function GuardeMachine.back(now_time, planet_user, planet_army)
	
	if planet_army.status == Status.kMove then

		local node_list = moveArmyBack(now_time, planet_army)

		PlanetCache.saveUserData(planet_user)

		PlanetCache.broadcastUpdate(planet_user.user_name, node_list)

	elseif planet_army.status == Status.kGuarde then

		local key = planet_army.army_key

		local element = PlanetCache.getElement(planet_army.element_global_key)

		if element.type == 1 then
			for i,v in ipairs(element.base_data.guarde_list) do
				if v == key then
					table.remove(element.base_data.guarde_list, i)
					break
				end
			end
		elseif element.type == 5 then
			for i,v in ipairs(element.city_data.guarde_list) do
				if v == key then
					table.remove(element.city_data.guarde_list, i)
					break
				end
			end
		elseif element.type == 12 then
			for i,v in ipairs(element.wangzuo_data.guarde_list) do
				if v == key then
					table.remove(element.wangzuo_data.guarde_list, i)
					break
				end
			end
		elseif element.type == 13 then
			for i,v in ipairs(element.tower_data.guarde_list) do
				if v == key then
					table.remove(element.tower_data.guarde_list, i)
					break
				end
			end
		end


		local key_list = Tools.split(element.global_key, "_")
		PlanetCache.saveNodeDataByID(tonumber(key_list[1]))
		

		local my_base = PlanetCache.getElement(planet_user.base_global_key)

		if planet_army.element_global_key == planet_user.base_global_key then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)
		else
			local node_list = moveArmy(now_time, element.pos_list[1], my_base.pos_list[1], planet_user, planet_army, Status.kMoveBack)

			PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
		end
		PlanetCache.saveUserData(planet_user)
	else
		return false
	end
	
	return true
end

function GuardeMachine.moveBase(now_time, planet_user, planet_army )
	local node_id_list
	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		node_id_list = planet_army.line.node_id_list

		moveEnd(planet_user, planet_army, Status.kMoveEnd)

		PlanetCache.saveUserData(planet_user)
	end

	return node_id_list
end

function GuardeMachine.doLogic(now_time, planet_user, planet_army)

	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then


			local element = PlanetCache.getElement(planet_army.element_global_key)

			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]
			local src_pos = planet_army.line.move_list[1]

			--元素消失 队伍返回
			local needBack = false
			if element == nil then
				needBack = true
			elseif element.type == 1 then

				local other_user_info = UserInfoCache.get(planet_user.user_name)
				local building_level = other_user_info.building_level_list[CONF.EBuilding.kDiplomacy]
				local guarde_max_num = CONF.BUILDING_13.get(building_level or 1).GUARDE_NUM

				if checkElement(element, 1, dest_pos) == false then
					needBack = true
				elseif alreadyGuarde(planet_user.user_name, element.base_data.guarde_list) then--已经有自己的队伍驻扎
					needBack = true
				elseif #element.base_data.guarde_list >= guarde_max_num then--驻扎达到上限
					needBack = true
				end
				
			elseif element.type == 5 then
				if checkElement(element, 5, dest_pos) == false then
					needBack = true
				elseif alreadyGuarde(planet_user.user_name, element.city_data.guarde_list) then--已经有自己的队伍驻扎
					needBack = true
				end
			elseif element.type == 12 then
				if checkElement(element, 12, dest_pos) == false then
					needBack = true
				--elseif alreadyGuarde(planet_user.user_name, element.wangzuo_data.guarde_list) then--已经有自己的队伍驻扎
					--needBack = true
				end
			elseif element.type == 13 then
				if checkElement(element, 13, dest_pos) == false then
					needBack = true
				--elseif alreadyGuarde(planet_user.user_name, element.tower_data.guarde_list) then--已经有自己的队伍驻扎
					--needBack = true
				end
			end
			
			if needBack == true then
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			if element.type == 1 then

				if planet_user.user_name ~= element.base_data.user_name then
					--非同一公会返回
					local other_user_info1 = UserInfoCache.get(planet_user.user_name)
					local other_user_info2 = UserInfoCache.get(element.base_data.user_name)
					if other_user_info1.groupid == nil 
					or other_user_info1.groupid == ""
					or other_user_info2.groupid == nil 
					or other_user_info2.groupid == ""
					or other_user_info1.groupid ~= other_user_info2.groupid then
						local node_list = moveArmyBack(now_time, planet_army)
						PlanetCache.saveUserData(planet_user)
						PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
						return
					end
				end
			elseif element.type == 5 then
				local other_user_info = UserInfoCache.get(planet_user.user_name)

				local cityConf = CONF.PLANETCITY.get(element.city_data.id)
				if other_user_info.groupid == nil 
				or other_user_info.groupid == "" 
				or other_user_info.groupid ~= element.city_data.groupid 
				or #element.city_data.guarde_list >= cityConf.TROOPS_LIMIT then
					local node_list = moveArmyBack(now_time, planet_army)
					PlanetCache.saveUserData(planet_user)
					PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
					return
				end
			elseif element.type == 12 then
				local other_user_info = UserInfoCache.get(planet_user.user_name)
				local cityConf = CONF.PLANETCITY.get(element.wangzuo_data.id)
				if 	#element.wangzuo_data.guarde_list >= cityConf.TROOPS_LIMIT then
					if (other_user_info.groupid ==nil or other_user_info.groupid == "" or other_user_info.groupid ~= element.wangzuo_data.groupid)
					and (other_user_info.user_name ~= element.wangzuo_data.user_name) then					
						local node_list = moveArmyBack(now_time, planet_army)
						PlanetCache.saveUserData(planet_user)
						PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
						return
					end
				end
			elseif element.type == 13 then
				local other_user_info = UserInfoCache.get(planet_user.user_name)
				local cityConf = CONF.PLANETTOWER.get(element.tower_data.id)
				if 	#element.tower_data.guarde_list >= cityConf.TROOPS_LIMIT then
					if (other_user_info.groupid ==nil or other_user_info.groupid == "" or other_user_info.groupid ~= element.tower_data.groupid)
					and (other_user_info.user_name ~= element.tower_data.user_name) then					
						local node_list = moveArmyBack(now_time, planet_army)
						PlanetCache.saveUserData(planet_user)
						PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
						return
					end
				end
			end

			guarde(element, planet_user, planet_army)

			local key_list = Tools.split(element.global_key, "_")
			local node_id = tonumber(key_list[1])
			PlanetCache.saveNodeDataByID(node_id)
			PlanetCache.saveUserData(planet_user)
		end

	elseif planet_army.status == Status.kGuarde then

	elseif  planet_army.status == Status.kMoveBack then

		if isArrived(now_time, planet_army.line) then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)
			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end


function BaseAttackMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time


	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	local src = src_element.pos_list[1]

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local dest = dest_element.pos_list[1]

	PlanetCache.closeShield(src_element)

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)

	local other_user_info = UserInfoCache.get(dest_element.base_data.user_name)
	PlanetCache.groupAddAttacker(other_user_info.groupid, planet_army.army_key)

	PlanetCache.userAddAttacker( other_user_info.user_name, planet_army.army_key )
end

function BaseAttackMachine.back(now_time, planet_user, planet_army)
	local node_list
	if planet_army.status == Status.kMove then

		node_list = moveArmyBack(now_time, planet_army)
	else
		return false
	end

	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local other_user_info = UserInfoCache.get(dest_element.base_data.user_name)

	PlanetCache.groupRemoveAttacker(other_user_info.groupid, planet_army.army_key)

	PlanetCache.userRemoveAttacker( other_user_info.user_name, planet_army.army_key )

	PlanetCache.removeEnlistInGroup( planet_army.army_key )
	return true
end

function BaseAttackMachine.moveBase(now_time, planet_user, planet_army )
	local node_id_list
	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		node_id_list = planet_army.line.node_id_list

		moveEnd(planet_user, planet_army, Status.kMoveEnd)

		PlanetCache.saveUserData(planet_user)

		local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
		local other_user_info = UserInfoCache.get(dest_element.base_data.user_name)

		PlanetCache.groupRemoveAttacker(other_user_info.groupid, planet_army.army_key)

		PlanetCache.userRemoveAttacker( other_user_info.user_name, planet_army.army_key )

		PlanetCache.removeEnlistInGroup( planet_army.army_key )


		if Tools.isEmpty(planet_army.army_key_list) == false then
			for i,army_key in ipairs(planet_army.army_key_list) do
				local army = PlanetCache.getArmy(army_key)
				local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])

				local src_element = PlanetCache.getElement(planet_user.base_global_key)
				local dest_element = PlanetCache.getElement(user.base_global_key) 

				local node_list = moveArmy(now_time, src_element.pos_list[1], dest_element.pos_list[1], user, army, Status.kMoveBack)

				PlanetCache.saveUserData(user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
			end
		end
	end

	return node_id_list
end

function BaseAttackMachine.doLogic(now_time, planet_user, planet_army)

	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then
			--Tools._print("BaseAttackMachine.doLogic 111111111111111")
			local element = PlanetCache.getElement(planet_army.element_global_key)
			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]
			local src_pos = planet_army.line.move_list[1]

			PlanetCache.removeEnlistInGroup( planet_army.army_key )

			--元素消失 队伍返回
			local backFlag = false
			if element == nil or checkElement(element, 1, dest_pos) == false then
				
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			local my_base = PlanetCache.getElement(planet_user.base_global_key)

			local attacker_other_user_info = UserInfoCache.get(planet_user.user_name)
			local hurter_user = PlanetCache.getUser( element.base_data.user_name )
			local hurter_other_user_info = UserInfoCache.get(hurter_user.user_name)

			PlanetCache.groupRemoveAttacker(hurter_other_user_info.groupid, planet_army.army_key)

			PlanetCache.userRemoveAttacker( hurter_other_user_info.user_name, planet_army.army_key)
			
			--同一公会返回
			if backFlag == false then
				if attacker_other_user_info.groupid ~= nil 
				and attacker_other_user_info.groupid ~= ""
				and attacker_other_user_info.groupid == hurter_other_user_info.groupid then

					backFlag = true
				end
			end

			--保护罩
			if backFlag == false then
				if element.base_data.shield_start_time ~= nil and element.base_data.shield_start_time > 0 then
					if now_time - element.base_data.shield_start_time < element.base_data.shield_time then

						local report1 = {
							type = 16,
							result = true,
							id = 0,
							pos_list = element.pos_list,
							isWin = false,
						}
						RedoList.addPlanetMail(planet_user.user_name, report1)

						if Tools.isEmpty(planet_army.army_key_list) == false then
							for i,v in ipairs(planet_army.army_key_list) do
								local user_name = Tools.split(v, "_")[1]
								RedoList.addPlanetMail(user_name, report1)
							end
						end

						backFlag = true
					end
				end
			end

			if backFlag == true then
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			local isWin
			local isKilledMonster = false
			local video_key_list = {}
			local item_list = {}

			local event_list
			local attacker_hp_list
			local hurter_hp_list
			
			
			local my_mail_user_list = {}
			local enemy_mail_user_list = {}

			local update_node_list = {}

			local building_12_conf = CONF.BUILDING_12.get(hurter_other_user_info.building_level_list[CONF.EBuilding.kDefend])
			local lineup_monster = building_12_conf.AIRSHIP

			local monster_list = {}
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

					local ship_info = Tools.createShipByConf(ship_id)
					ship_info.position = k
					ship_info.body_position = bodyPositions
					table.insert(monster_list, ship_info)
				end
			end

			local attack_army_key_list = {}
			table.insert(attack_army_key_list, planet_army.army_key)
			if Tools.isEmpty(planet_army.army_key_list) == false then
				for i,v in ipairs(planet_army.army_key_list) do
					table.insert(attack_army_key_list, v)
				end
			end

			local enemy_index = 1

			local pre_attacker_ship_energy_level_list_list = {}
			local pre_enemy_ship_energy_level_list_list = {}

			for i,army_key in ipairs(attack_army_key_list) do

				local key_list = Tools.split(army_key, "_")
				local attacker_user = PlanetCache.getUser(key_list[1])
				local attacker_army = PlanetCache.getArmy(army_key)

				if isKilledMonster == false then

					for i,v in ipairs(attacker_army.ship_list) do
						if Tools.checkShipDurable(v) == false then
							v.attr[CONF.EShipAttr.kHP] = 0
						end
					end

					isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(attacker_army.ship_list, attacker_army.lineup_hp, monster_list, nil)
					
					for i,v in ipairs(attacker_army.ship_list) do

						if v.energy_level then
							if pre_attacker_ship_energy_level_list_list[i] == nil then
								pre_attacker_ship_energy_level_list_list[i] = {0,0,0,0,0,0,0,0,0,}
							end
							pre_attacker_ship_energy_level_list_list[i][v.position] = math.max(v.energy_level, pre_attacker_ship_energy_level_list_list[i][v.position])
						end

						Tools.shipSubDurable( v, 2, isWin and 1 or 0, attacker_army.tech_durable_param)

						Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
					end

					local resp = {
						result = 2,
						attack_list = attacker_army.ship_list,
						hurter_list = monster_list,
						event_list = event_list,
						attacker_hp_list = attacker_army.lineup_hp,
					}
					local video_key = VideoCache.addVideo(attacker_user.user_name, resp)
					table.insert(video_key_list, video_key)
					if attacker_hp_list ~= nil then
						attacker_army.lineup_hp = attacker_hp_list
					end
				end


				if isWin == false then
				
				else

					isKilledMonster = true

					if Tools.isEmpty(element.base_data.guarde_list) then
						isWin = true
					else
						for i,enemy_army_key in ipairs(element.base_data.guarde_list) do
							if i >= enemy_index then

								local key_list = Tools.split(enemy_army_key, "_")
								local enemy_user 
								if element.base_data.user_name == key_list[1] then
									enemy_user = hurter_user
								else
									enemy_user = PlanetCache.getUser(key_list[1]  )
								end
								local enemy_army = PlanetCache.getArmy( enemy_army_key )
								if enemy_army.status == Status.kGuarde then

									for i,v in ipairs(attacker_army.ship_list) do
										if Tools.checkShipDurable(v) == false then
											v.attr[CONF.EShipAttr.kHP] = 0
										end
									end

									for i,v in ipairs(enemy_army.ship_list) do
										if Tools.checkShipDurable(v) == false then
											v.attr[CONF.EShipAttr.kHP] = 0
										end
									end

									isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(attacker_army.ship_list, attacker_army.lineup_hp, enemy_army.ship_list, enemy_army.lineup_hp)

									for i,v in ipairs(attacker_army.ship_list) do

										if v.energy_level then
											if pre_attacker_ship_energy_level_list_list[i] == nil then
												pre_attacker_ship_energy_level_list_list[i] = {0,0,0,0,0,0,0,0,0,}
											end
											pre_attacker_ship_energy_level_list_list[i][v.position] = math.max(v.energy_level, pre_attacker_ship_energy_level_list_list[i][v.position])
										end
								
										Tools.shipSubDurable( v, 2, isWin and 1 or 0, attacker_army.tech_durable_param )

										Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
									end

									for i,v in ipairs(enemy_army.ship_list) do

										if v.energy_level then
											if pre_enemy_ship_energy_level_list_list[i] == nil then
												pre_enemy_ship_energy_level_list_list[i] = {0,0,0,0,0,0,0,0,0,}
											end
											pre_enemy_ship_energy_level_list_list[i][v.position] = math.max(v.energy_level, pre_enemy_ship_energy_level_list_list[i][v.position])
										end

										Tools.shipSubDurable( v, 2, isWin and 0 or 1, enemy_army.tech_durable_param )

										Tools.shipSubEnergy( v, 2, isWin and 0 or 1, true)
									end
									
									local resp = {
										result = 2,
										attack_list = attacker_army.ship_list,
										hurter_list = enemy_army.ship_list,
										event_list = event_list,
										attacker_hp_list = attacker_army.lineup_hp,
										hurter_hp_list = enemy_army.lineup_hp,
									}

									local video_key = VideoCache.addVideo(attacker_user.user_name, resp)
									table.insert(video_key_list, video_key)

									if hurter_hp_list ~= nil then
										enemy_army.lineup_hp = hurter_hp_list
									end
									if attacker_hp_list ~= nil then
										attacker_army.lineup_hp = attacker_hp_list
									end

									if checkArmyAllDead(enemy_army) == true then

										PlanetStatusMachine[enemy_army.status_machine].back(now_time, enemy_user, enemy_army)
									end
									
									PlanetCache.saveUserData(enemy_user)
									PlanetCache.saveUserData(attacker_user)

									if isWin == false then
										break
									else
										enemy_index = enemy_index + 1
									end
								end


							end
						end
					end
				end

				if isWin == true then

					break

				end
			end

			CoreUser.battleCount(planet_user.user_name, hurter_user.user_name, isWin)

			for i,army_key in ipairs(attack_army_key_list) do

				local key_list = Tools.split(army_key, "_")
				local attacker_user = PlanetCache.getUser(key_list[1])
				local attacker_army = PlanetCache.getArmy(army_key)

				local my_mail_user = PlanetCache.createMailUser(attacker_user, attacker_army)
				my_mail_user.pre_ship_energy_level_list = pre_attacker_ship_energy_level_list_list[i]
				table.insert(my_mail_user_list, my_mail_user)
			end

			if Tools.isEmpty(element.base_data.guarde_list) == false then
				for i,army_key in ipairs(element.base_data.guarde_list) do
					local key_list = Tools.split(army_key, "_")
					local enemy_user 
					if element.base_data.user_name == key_list[1] then
						enemy_user = hurter_user
					else
						enemy_user = PlanetCache.getUser(key_list[1]  )
					end
					local enemy_army = PlanetCache.getArmy( army_key )
					local enemy_mail_user = PlanetCache.createMailUser(enemy_user, enemy_army)
					enemy_mail_user.pre_ship_energy_level_list = pre_enemy_ship_energy_level_list_list[i]
					table.insert(enemy_mail_user_list, enemy_mail_user)
				end
			end

			planet_user.base_attack_times = (planet_user.base_attack_times == nil and 0 or planet_user.base_attack_times) + 1

			if Tools.isEmpty(planet_user.seven_days_data) then
				planet_user.seven_days_data = {}
			end
			if planet_user.seven_days_data.base_attack_times==nil then
				planet_user.seven_days_data.base_attack_times = 1
			else
				planet_user.seven_days_data.base_attack_times = planet_user.seven_days_data.base_attack_times + 1
			end

			if isWin then

				planet_user.attack_win_times = (planet_user.attack_win_times == nil and 0 or planet_user.attack_win_times) + 1

				local stage = checkDestroyStage(element.base_data.destroy_value or 0)

				element.base_data.destroy_value = math.floor(math.min(element.base_data.destroy_value + CONF.PARAM.get("planet_destroy_stage").PARAM[stage], CONF.PARAM.get("planet_destroy_value_limit").PARAM))
				element.base_data.last_hurt_time = now_time

				local res_list = calAttakBaseGetRes(element, planet_user.user_name, hurter_user.user_name, planet_army.ship_list)

				local hurter_sync_user = SyncUserCache.getSyncUser(hurter_user.user_name)

				for i=2,4 do
		
					hurter_sync_user.res[i] = hurter_sync_user.res[i] - res_list[i]

					if Tools.isEmpty(planet_army.item_list) == true then
						planet_army.item_list = {}
					end
					if res_list[i] > 0 then
						local item = {
							id = refid.res[i],
							num = res_list[i],
							guid = 0,
						}

						addItemToList(item, planet_army.item_list)

						table.insert(item_list, item)
					end
				end

				SyncUserCache.setSyncUser(hurter_sync_user)
			else

				hurter_user.base_defense_win_times = (hurter_user.base_defense_win_times == nil and 0 or hurter_user.base_defense_win_times) + 1
				PlanetCache.saveUserData(hurter_user)
			end


			
			local enemy_mail_user = PlanetCache.createMailUser(hurter_user)
			table.insert(enemy_mail_user_list, 1, enemy_mail_user)
			

			local report1 = {
				type = 10,
				result = true,
				id = 0,
				pos_list = element.pos_list,
				isWin = isWin,
				video_key_list = video_key_list,
				my_data_list = my_mail_user_list,
				enemy_data_list = enemy_mail_user_list,
				item_list_list = {
					{item_list = item_list},
				},
			}
			RedoList.addPlanetMail(planet_user.user_name, report1)

			local report2 = {
				type = 11,
				result = true,
				item_list_list = {
					{item_list = item_list},
				},
				id = 0,
				pos_list = my_base.pos_list,
				isWin = (not isWin),
				video_key_list = video_key_list,
				my_data_list = enemy_mail_user_list,
				enemy_data_list = my_mail_user_list,
			}
			RedoList.addPlanetMail(hurter_user.user_name, report2)

			local mail_update = CoreMail.getMultiCast({planet_user.user_name, hurter_user.user_name})
			local mail_update_buff = Tools.encode("Multicast", mail_update)
			activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)

			addUpdateNodeList(update_node_list, moveArmyBack(now_time, planet_army))

			if Tools.isEmpty(planet_army.army_key_list) == false then
					
				for i,army_key in ipairs(planet_army.army_key_list) do

					local army = PlanetCache.getArmy(army_key)
					local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

					local base = PlanetCache.getElement(user.base_global_key)
					
					local node_list = moveArmy(now_time, element.pos_list[1], base.pos_list[1], user, army, Status.kMoveBack)

					addUpdateNodeList(update_node_list, node_list)

					PlanetCache.saveUserData(user)
				end

				planet_army.army_key_list = nil
			end

			PlanetCache.broadcastUpdate(planet_user.user_name, update_node_list)

			PlanetCache.saveUserData(planet_user)

		end

	elseif  planet_army.status == Status.kMoveBack then


		if isArrived(now_time, planet_army.line) then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)

			if Tools.isEmpty(planet_army.army_key_list) == false then

				for i,army_key in ipairs(planet_army.army_key_list) do
					local army = PlanetCache.getArmy(army_key)
					local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])
					PlanetStatusMachine[army.status_machine].back(now_time, user, army)

				end

				planet_army.army_key_list = nil
			end
			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end

end

function AccompanyMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time



	local other_army = PlanetCache.getArmy(planet_army.accompany_army_key)
	if Tools.isEmpty(other_army.req_army_key_list) == true then
		other_army.req_army_key_list = {}
	end
	table.insert(other_army.req_army_key_list, planet_army.army_key)

	local other_user = PlanetCache.getUser(Tools.split(planet_army.accompany_army_key, "_")[1])
	PlanetCache.saveUserData(other_user)

	planet_army.accompany_begin_time = other_army.begin_time

	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	local src = src_element.pos_list[1]

	PlanetCache.closeShield(src_element)

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local dest = dest_element.pos_list[1]

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
end

function AccompanyMachine.back(now_time, planet_user, planet_army)
	local node_list
Tools._print("ccccccccccccc1111")
	if planet_army.status == Status.kMove then

		node_list = moveArmyBack(now_time, planet_army)

		local other_army = PlanetCache.getArmy(planet_army.accompany_army_key)
		if other_army ~= nil then
			if Tools.isEmpty(other_army.req_army_key_list) == false then
				
				for i,v in ipairs(other_army.req_army_key_list) do
					if v == planet_army.army_key then
						table.remove(other_army.req_army_key_list, i)
						break
					end
				end
				local other_user = PlanetCache.getUser(Tools.split(planet_army.accompany_army_key, "_")[1])
				PlanetCache.saveUserData(other_user)
			end
		end


	elseif planet_army.status == Status.kAccompany then

		local other_army = PlanetCache.getArmy( planet_army.accompany_army_key )

		local other_user = PlanetCache.getUser(Tools.split(planet_army.accompany_army_key, "_")[1])
		local src_element = PlanetCache.getElement(other_user.base_global_key) 
		local src = src_element.pos_list[1]

		local dest_element = PlanetCache.getElement(planet_user.base_global_key) 
	
		node_list = moveArmy(now_time, src_element.pos_list[1], dest_element.pos_list[1], planet_user, planet_army, Status.kMoveBack)

		if other_army.status == Status.kEnlist then
	
			if Tools.isEmpty(other_army.army_key_list) == false then
				for i,v in ipairs(other_army.army_key_list) do
					if planet_army.army_key == v then

						table.remove(other_army.army_key_list, i)
						--通知公会所有人
						PlanetCache.broadcastUserUpdateToGroup(other_user.user_name)

						break
					end
				end
				PlanetCache.saveUserData(other_user)
			end
		end
		
	else
		return false
	end
	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
Tools._print("ccccccccccccccc22222")	
	return true
end

function AccompanyMachine.moveBase(now_time, planet_user, planet_army )

	local node_id_list

	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		node_id_list = planet_army.line.node_id_list

		if planet_army.status == Status.kMove then
			local other_army = PlanetCache.getArmy(planet_army.accompany_army_key)

			if Tools.isEmpty(other_army.req_army_key_list) == false then
				
				for i,v in ipairs(other_army.req_army_key_list) do
					if v == planet_army.army_key then
						table.remove(other_army.req_army_key_list, i)
						break
					end
				end
				local other_user = PlanetCache.getUser(Tools.split(planet_army.accompany_army_key, "_")[1])
				PlanetCache.saveUserData(other_user)
			end
		end

	elseif planet_army.status == Status.kAccompany then

		return false
	end

	moveEnd(planet_user, planet_army, Status.kMoveEnd)
	PlanetCache.saveUserData(planet_user)

	return node_id_list
end

function AccompanyMachine.doLogic(now_time, planet_user, planet_army)
	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then
Tools._print("bbbbbbbbbbbbbb1111")
			local key_list = Tools.split(planet_army.accompany_army_key, "_") 

			local element = PlanetCache.getElement(planet_army.element_global_key)
			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]
			local src_pos = planet_army.line.move_list[1]
			--元素消失 队伍返回
			if element == nil or checkElement(element, 1, dest_pos) == false then
				AccompanyMachine.back(now_time, planet_user, planet_army)
				return
			end
Tools._print("bbbbbbbbbbbbbb2222")
			--非同一公会返回
			local other_user_info1 = UserInfoCache.get(planet_user.user_name)
			local other_user_info2 = UserInfoCache.get(key_list[1])
			if other_user_info1.groupid ~= nil 
			and other_user_info1.groupid ~= ""
			and other_user_info2.groupid ~= nil 
			and other_user_info2.groupid ~= "" 
			and other_user_info1.groupid ~= other_user_info2.groupid then
				AccompanyMachine.back(now_time, planet_user, planet_army)
				return
			end
Tools._print("bbbbbbbbbbbbbb3333")
			--没有或已经出发
			local other_army = PlanetCache.getArmy( planet_army.accompany_army_key )
			if other_army == nil or other_army.status ~= Status.kEnlist or other_army.begin_time ~= planet_army.accompany_begin_time then
				AccompanyMachine.back(now_time, planet_user, planet_army)
				return
			end
Tools._print("bbbbbbbbbbbbbb4444")
			--到达加入上限
			local mainConf = CONF.BUILDING_1.get(other_user_info2.building_level_list[CONF.EBuilding.kMain])
			if Tools.isEmpty(other_army.army_key_list) == false then
				if #other_army.army_key_list >= mainConf.MASS then
					AccompanyMachine.back(now_time, planet_user, planet_army)
					return
				end
			end
Tools._print("bbbbbbbbbbbbbb5555")
			local my_army_key = planet_army.army_key
			--加入军队
			if Tools.isEmpty(other_army.army_key_list) == true then
				other_army.army_key_list = {} 
			end
			table.insert(other_army.army_key_list, my_army_key)

			--从请求列表中删除
			if Tools.isEmpty(other_army.req_army_key_list) == false then
				for i,v in ipairs(other_army.req_army_key_list) do
					if v == my_army_key then
						table.remove(other_army.req_army_key_list, i)
						break
					end
				end
			end
Tools._print("bbbbbbbbbbbbbb6666")
			local other_user = PlanetCache.getUser(key_list[1])
			PlanetCache.saveUserData(other_user)

			--通知公会所有人
			PlanetCache.broadcastUserUpdateToGroup(other_user.user_name)

			moveEnd(planet_user, planet_army, Status.kAccompany)
			PlanetCache.saveUserData(planet_user)
Tools._print("bbbbbbbbbbbbbb7777")			
		end

	elseif planet_army.status == Status.kAccompany then



	elseif planet_army.status == Status.kMoveBack then

		if isArrived(now_time, planet_army.line) then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)
			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end


function CityAttackMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time


	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	local src = src_element.pos_list[1]

	PlanetCache.closeShield(src_element)

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local dest = dest_element.pos_list[1]

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)

	PlanetCache.groupAddAttacker(dest_element.city_data.groupid, planet_army.army_key)

end

function CityAttackMachine.back(now_time, planet_user, planet_army)
	local node_list
	if planet_army.status == Status.kMove then

		node_list = moveArmyBack(now_time, planet_army)

		local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
		PlanetCache.groupRemoveAttacker(dest_element.city_data.groupid, planet_army.army_key)

		PlanetCache.removeEnlistInGroup( planet_army.army_key )
	elseif planet_army.status == Status.kGuarde then

		local element = PlanetCache.getElement(planet_army.element_global_key)
	
		for i,v in ipairs(element.city_data.guarde_list) do
			if v == planet_army.army_key then
				table.remove(element.city_data.guarde_list, i)
				break
			end
		end
	

		local key_list = Tools.split(element.global_key, "_")
		PlanetCache.saveNodeDataByID(tonumber(key_list[1]))
		

		local my_base = PlanetCache.getElement(planet_user.base_global_key)

		if planet_army.element_global_key == planet_user.base_global_key then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)
		else
			local node_list = moveArmy(now_time, element.pos_list[1], my_base.pos_list[1], planet_user, planet_army, Status.kMoveBack)

			PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
		end

		PlanetCache.saveUserData(planet_user)
	else
		return false
	end



	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
	return true
end

function CityAttackMachine.moveBase(now_time, planet_user, planet_army )

	local node_id_list
	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		node_id_list = planet_army.line.node_id_list

		local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
		PlanetCache.groupRemoveAttacker(dest_element.city_data.groupid, planet_army.army_key)

		PlanetCache.removeEnlistInGroup( planet_army.army_key )

	elseif planet_army.status == Status.kGuarde then

		return
	end

	moveEnd(planet_user, planet_army, Status.kMoveEnd)

	PlanetCache.saveUserData(planet_user)


	if Tools.isEmpty(planet_army.army_key_list) == false then
		for i,army_key in ipairs(planet_army.army_key_list) do
			local army = PlanetCache.getArmy(army_key)
			local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])

			local src_element = PlanetCache.getElement(planet_user.base_global_key)
			local dest_element = PlanetCache.getElement(user.base_global_key) 

			local node_list = moveArmy(now_time, src_element.pos_list[1], dest_element.pos_list[1], user, army, Status.kMoveBack)

			PlanetCache.saveUserData(user)
			PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
		end
	end

	return node_id_list
end

function CityAttackMachine.doLogic(now_time, planet_user, planet_army)
	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then
			
			local element = PlanetCache.getElement(planet_army.element_global_key)
			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]
			local src_pos = planet_army.line.move_list[1]

			local my_other_user_info = UserInfoCache.get(planet_user.user_name)

			PlanetCache.removeEnlistInGroup( planet_army.army_key )

			PlanetCache.groupRemoveAttacker(element.city_data.groupid, planet_army.army_key)

			--和平时期
			if element.city_data.status == 1 then

				local report1 = {
					type = 17,
					result = true,
					id = element.city_data.id,
					pos_list = element.pos_list,
					isWin = false,
				}
				RedoList.addPlanetMail(planet_user.user_name, report1)

				if Tools.isEmpty(planet_army.army_key_list) == false then
					for i,v in ipairs(planet_army.army_key_list) do
						local user_name = Tools.split(v, "_")[1]
						RedoList.addPlanetMail(user_name, report1)
					end
				end
			
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			--同一公会没必要打了
			if (my_other_user_info.groupid ~= "" and my_other_user_info.groupid ~= nil) and element.city_data.groupid == my_other_user_info.groupid then
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			local isWin
			local event_list
			local attacker_hp_list
			local hurter_hp_list
			local video_key_list = {}

			local my_mail_user_list = {}
			local enemy_mail_user_list = {}

			local attacker_recv_mail_user_list = {}
			local enemy_recv_mail_user_list = {}

			local update_node_list = {}

			local attacker_army_key_list = {planet_army.army_key}
			if Tools.isEmpty(planet_army.army_key_list) == false then
				for i,army_key in ipairs(planet_army.army_key_list) do
					table.insert(attacker_army_key_list, army_key)
				end
			end

			local pre_attacker_ship_energy_level_list_list = {}
			local pre_enemy_ship_energy_level_list_list = {}
			
			if element.city_data.hasMonster == true then

				local cityConf = CONF.PLANETCITY.get(element.city_data.id)

				local lineup_monster = cityConf.MONSTER_LIST

				local initMonster = false
				if Tools.isEmpty(element.city_data.monster_hp_list) == true then
					initMonster = true
					element.city_data.monster_hp_list = {0,0,0,0,0,0,0,0,0,}
				end

				local monster_list = {}
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

						local ship_info = Tools.createShipByConf(ship_id)
						ship_info.position = k
						ship_info.body_position = bodyPositions
						table.insert(monster_list, ship_info)

						if initMonster then
							element.city_data.monster_hp_list[k] = ship_info.attr[CONF.EShipAttr.kHP]
						end
					end
				end

				
		
				for i,army_key in ipairs(attacker_army_key_list) do
					local army
					local user
					if army_key == planet_army.army_key then
						army = planet_army
						user = planet_user
					else
						army = PlanetCache.getArmy(army_key)
						user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					end

					for i,v in ipairs(army.ship_list) do
						if Tools.checkShipDurable(v) == false then
							v.attr[CONF.EShipAttr.kHP] = 0
						end
					end

					isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(army.ship_list, army.lineup_hp, monster_list, element.city_data.monster_hp_list)

					for i,v in ipairs(army.ship_list) do

						if v.energy_level then
							if pre_attacker_ship_energy_level_list_list[i] == nil then
								pre_attacker_ship_energy_level_list_list[i] = {0,0,0,0,0,0,0,0,0,}
							end
							pre_attacker_ship_energy_level_list_list[i][v.position] = v.energy_level
						end
					
						Tools.shipSubDurable( v, 2, isWin and 1 or 0, army.tech_durable_param )

						Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
					end

					
					local resp = {
						result = 2,
						attack_list = army.ship_list,
						hurter_list = monster_list,
						event_list = event_list,
						attacker_hp_list = army.lineup_hp,
						hurter_hp_list = element.city_data.monster_hp_list,
					}
					local video_key = VideoCache.addVideo(user.user_name, resp)
					table.insert(video_key_list, video_key)
					if attacker_hp_list ~= nil then
						army.lineup_hp = attacker_hp_list
					end

					element.city_data.monster_hp_list = hurter_hp_list

					if isWin then
	 					element.city_data.hasMonster = false
	 					break
	 				end
	 			end

	 			local enemy_mail_user = PlanetCache.createMailUserByMonster( hurter_hp_list, monster_list)
	 			table.insert(enemy_mail_user_list, enemy_mail_user)

 				for i,army_key in ipairs(attacker_army_key_list) do

 					local army = PlanetCache.getArmy(army_key)
					local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					
 					local mail_user = PlanetCache.createMailUser(user, army)
 					mail_user.pre_ship_energy_level_list = pre_attacker_ship_energy_level_list_list[i]
 					table.insert(my_mail_user_list, mail_user)

 					table.insert(attacker_recv_mail_user_list, user.user_name)
 				end
 				
 				
				local report = {
					type = 12,
					result = true,
					id = element.city_data.id,
					pos_list = element.pos_list,
					isWin = isWin,
					video_key_list = video_key_list,
					my_data_list = my_mail_user_list,
					enemy_data_list = enemy_mail_user_list,
				}
				for i,user_name in ipairs(attacker_recv_mail_user_list) do
					RedoList.addPlanetMail(user_name, report)
				end
				
				local mail_update = CoreMail.getMultiCast(attacker_recv_mail_user_list)
	      		      	local mail_update_buff = Tools.encode("Multicast", mail_update)
	      		      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)

			elseif Tools.isEmpty(element.city_data.guarde_list) == false then

				local enemy_index = 1

				for i,army_key in ipairs(attacker_army_key_list) do

					local attacker_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					local attacker_army = PlanetCache.getArmy(army_key)

					for i,enemy_army_key in ipairs(element.city_data.guarde_list) do

						if i >= enemy_index then

							local enemy_user = PlanetCache.getUser(Tools.split(enemy_army_key, "_")[1])
							local enemy_army = PlanetCache.getArmy(enemy_army_key)

							if enemy_army and enemy_army.status == Status.kGuarde then

								for i,v in ipairs(attacker_army.ship_list) do
									if Tools.checkShipDurable(v) == false then
										v.attr[CONF.EShipAttr.kHP] = 0
									end
								end

								for i,v in ipairs(enemy_army.ship_list) do
									if Tools.checkShipDurable(v) == false then
										v.attr[CONF.EShipAttr.kHP] = 0
									end
								end

								isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(attacker_army.ship_list, attacker_army.lineup_hp, enemy_army.ship_list, enemy_army.lineup_hp)

								for i,v in ipairs(attacker_army.ship_list) do

									if v.energy_level then
										if pre_attacker_ship_energy_level_list_list[i] == nil then
											pre_attacker_ship_energy_level_list_list[i] = {0,0,0,0,0,0,0,0,0,}
										end
										pre_attacker_ship_energy_level_list_list[i][v.position] = math.max(pre_attacker_ship_energy_level_list_list[i][v.position], v.energy_level) 
									end
							
									Tools.shipSubDurable( v, 2, isWin and 1 or 0, attacker_army.tech_durable_param )

									Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
								end

								for i,v in ipairs(enemy_army.ship_list) do
									if v.energy_level then
										if pre_enemy_ship_energy_level_list_list[i] == nil then
											pre_enemy_ship_energy_level_list_list[i] = {0,0,0,0,0,0,0,0,0,}
										end
										pre_enemy_ship_energy_level_list_list[i][v.position] = math.max(pre_enemy_ship_energy_level_list_list[i][v.position], v.energy_level) 
									end

									Tools.shipSubDurable( v, 2, isWin and 0 or 1, enemy_army.tech_durable_param )

									Tools.shipSubEnergy( v, 2, isWin and 0 or 1, true)
								end
								
								local resp = {
									result = 2,
									attack_list = attacker_army.ship_list,
									hurter_list = enemy_army.ship_list,
									event_list = event_list,
									attacker_hp_list = attacker_army.lineup_hp,
									hurter_hp_list = enemy_army.lineup_hp,
								}

								local video_key = VideoCache.addVideo(attacker_user.user_name, resp)
								table.insert(video_key_list, video_key)

								if hurter_hp_list ~= nil then
									enemy_army.lineup_hp = hurter_hp_list
								end
								if attacker_hp_list ~= nil then
									attacker_army.lineup_hp = attacker_hp_list
								end
								
								
								if checkArmyAllDead(enemy_army) == true then

									PlanetStatusMachine[enemy_army.status_machine].back(now_time, enemy_user, enemy_army)
								end
								PlanetCache.saveUserData(enemy_user)
								PlanetCache.saveUserData(attacker_user)

								if isWin == false then
									break
								else
									enemy_index = enemy_index + 1
								end

								
							end


						end
					end
					
					if isWin == true then
						break
					end
				end


				for i,army_key in ipairs(attacker_army_key_list) do

					local attacker_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					local attacker_army = PlanetCache.getArmy(army_key)

					local my_mail_user = PlanetCache.createMailUser(attacker_user, attacker_army)
					my_mail_user.pre_ship_energy_level_list = pre_attacker_ship_energy_level_list_list[i]
					table.insert(my_mail_user_list, my_mail_user)

					table.insert(attacker_recv_mail_user_list, attacker_user.user_name)
				end

				for _,army_key in ipairs(element.city_data.guarde_list) do
				
					local enemy_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					local enemy_army = PlanetCache.getArmy( army_key )

					if enemy_army then
						local enemy_mail_user = PlanetCache.createMailUser(enemy_user, enemy_army)
						enemy_mail_user.pre_ship_energy_level_list = pre_enemy_ship_energy_level_list_list[i]
						table.insert(enemy_mail_user_list, enemy_mail_user)

						table.insert(enemy_recv_mail_user_list, enemy_user.user_name)
					end
				end
			
				local user_name_list = {}
				local report1 = {
					type = 12,
					result = true,
					id = element.city_data.id,
					pos_list = element.pos_list,
					isWin = isWin,
					video_key_list = video_key_list,
					my_data_list = my_mail_user_list,
					enemy_data_list = enemy_mail_user_list,
				}
				for i,user_name in ipairs(attacker_recv_mail_user_list) do
 					
					RedoList.addPlanetMail(user_name, report1)
					table.insert(user_name_list, user_name)
				end

				local report2 = {
					type = 13,
					result = true,
					id = element.city_data.id,
					pos_list = element.pos_list,
					isWin = (not isWin),
					video_key_list = video_key_list,
					my_data_list = enemy_mail_user_list,
					enemy_data_list = my_mail_user_list,
				}

				for _,user_name in ipairs(enemy_recv_mail_user_list) do
				
					RedoList.addPlanetMail(user_name, report2)
					table.insert(user_name_list, user_name)
				end

				local mail_update = CoreMail.getMultiCast(user_name_list)
				local mail_update_buff = Tools.encode("Multicast", mail_update)
				activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)

			else


				for i,army_key in ipairs(attacker_army_key_list) do

 					local army = PlanetCache.getArmy(army_key)
					local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					
					if army then
	 					local mail_user = PlanetCache.createMailUser(user, army)
	 					mail_user.pre_ship_energy_level_list = pre_attacker_ship_energy_level_list_list[i]
	 					table.insert(my_mail_user_list, mail_user)

	 					table.insert(attacker_recv_mail_user_list, user.user_name)
	 				end
 				end

				isWin = true

				local report = {
					type = 12,
					result = true,
					id = element.city_data.id,
					pos_list = element.pos_list,
					isWin = isWin,
					my_data_list = my_mail_user_list,
				}

				for i,user_name in ipairs(attacker_recv_mail_user_list) do
					RedoList.addPlanetMail(user_name, report)
				end
				
				local mail_update = CoreMail.getMultiCast(attacker_recv_mail_user_list)
	      		      	local mail_update_buff = Tools.encode("Multicast", mail_update)
	      		      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)
			end

			

			if isWin then
				
				if Tools.isEmpty(element.city_data.guarde_list) == false then --之前有的队伍全部返回

					for i,army_key in ipairs(element.city_data.guarde_list) do

						local army = PlanetCache.getArmy(army_key)
						local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

						if army then
							local base = PlanetCache.getElement(user.base_global_key)
							
							local node_list = moveArmy(now_time, element.pos_list[1], base.pos_list[1], user, army, Status.kMoveBack)

							addUpdateNodeList(update_node_list, node_list)

							PlanetCache.saveUserData(user)
						end
					end
					element.city_data.guarde_list = nil
				end
				PlanetCache.exitCity(element)

				if my_other_user_info.groupid ~= "" and my_other_user_info.groupid ~= nil then
					guarde(element, planet_user, planet_army)

					planet_user.attack_city_win_times = (planet_user.attack_city_win_times == nil and 0 or planet_user.attack_city_win_times) + 1
					planet_user.attack_win_times = (planet_user.attack_win_times == nil and 0 or planet_user.attack_win_times) + 1

					if Tools.isEmpty(planet_army.army_key_list) == false then
						for i,army_key in ipairs(planet_army.army_key_list) do

							local army = PlanetCache.getArmy(army_key)
							local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

							user.attack_city_win_times = (user.attack_city_win_times == nil and 0 or user.attack_city_win_times) + 1
							user.attack_win_times = (user.attack_win_times == nil and 0 or user.attack_win_times) + 1

							army.status_machine = 8
							army.element_global_key = element.global_key
							guarde(element, user, army)

							PlanetCache.saveUserData(user)
						end
					end

					planet_army.army_key_list = nil

					occupyCity(element, my_other_user_info.groupid, my_other_user_info.user_name, now_time)

					if PlanetCache.hasFirstRewardMark(element.global_key, element.city_data.groupid) == false then
						local cityConf = CONF.PLANETCITY.get(element.city_data.id)
						PlanetCache.sendGroupCityReward( element.city_data.groupid, cityConf.FIRST_AWARD, Lang.planet_city_first_reward_title, Lang.planet_city_first_reward_msg, element.global_key)
						PlanetCache.addFirstRewardMark(element.global_key, element.city_data.groupid)
					end

				else
					moveArmyBack(now_time, planet_army)
				end
				local key_list = Tools.split(element.global_key, "_") 
				local node_id = tonumber(key_list[1])
				PlanetCache.saveNodeDataByID(node_id)
				addUpdateNodeList(update_node_list, {node_id})
			else

				moveArmyBack(now_time, planet_army)

				if Tools.isEmpty(planet_army.army_key_list) == false then
					
					for i,army_key in ipairs(planet_army.army_key_list) do

						local army = PlanetCache.getArmy(army_key)
						local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

						local base = PlanetCache.getElement(user.base_global_key)
						
						local node_list = moveArmy(now_time, element.pos_list[1], base.pos_list[1], user, army, Status.kMoveBack)

						addUpdateNodeList(update_node_list, node_list)

						PlanetCache.saveUserData(user)
					end

					planet_army.army_key_list = nil
				end
			end

			PlanetCache.saveUserData(planet_user)


			if Tools.isEmpty(update_node_list) == false then
				PlanetCache.broadcastUpdate(planet_user.user_name, update_node_list)
			end
		end

	elseif planet_army.status == Status.kGuarde then
		--[[local element = PlanetCache.getElement(planet_army.element_global_key)
		if element.city_data.status == 2 then
			local cityConf = CONF.PLANETCITY.get(element.city_data.id)
			if now_time - element.city_data.occupy_begin_time >= cityConf.HOLD_TIME then

				element.city_data.status = 1

				local key_list = Tools.split(element.global_key, "_") 
				local node_id = tonumber(key_list[1])
				PlanetCache.saveNodeDataByID(node_id)

				PlanetCache.broadcastUpdate(planet_user.user_name, {node_id})
			end
		end]]

	elseif planet_army.status == Status.kMoveBack then

		if isArrived(now_time, planet_army.line) then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)

			if Tools.isEmpty(planet_army.army_key_list) == false then
				for i,army_key in ipairs(planet_army.army_key_list) do
					local army = PlanetCache.getArmy(army_key)
					local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])
					PlanetStatusMachine[army.status_machine].back(now_time, user, army)
				end
				planet_army.army_key_list = nil
			end

			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end

function BossAttackMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time

	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	local src = src_element.pos_list[1]

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local dest = dest_element.pos_list[1]

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
end

function BossAttackMachine.back(now_time, planet_user, planet_army)
	local node_list
	if planet_army.status == Status.kMove then

		node_list = moveArmyBack(now_time, planet_army)
	else
		return false
	end

	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
	return true
end

function BossAttackMachine.moveBase(now_time, planet_user, planet_army )

	local node_id_list
	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		node_id_list = planet_army.line.node_id_list

	elseif planet_army.status == Status.kGuarde then

		return
	end

	moveEnd(planet_user, planet_army, Status.kMoveEnd)

	PlanetCache.saveUserData(planet_user)

	return node_id_list
end

function BossAttackMachine.doLogic(now_time, planet_user, planet_army)
	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then
			local element = PlanetCache.getElement(planet_army.element_global_key)
			--元素消失 队伍返回
			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]
			if element == nil or checkElement(element, 4, dest_pos) == false then
			
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end
			--加BUFF
			local boss_user = PlanetCache.getBossUser(planet_user.user_name, element.global_key)
			local bossConf = CONF.PLANETBOSS.get(element.boss_data.id)
			if boss_user == nil or boss_user.boss_global_key ~= element.global_key then

				boss_user = {
					user_name = planet_user.user_name,
					tech_id = bossConf.ATTACK_BUFF_LIST[1],
					start_time = now_time,
					attack_count = 1,
					boss_global_key = element.global_key,
				}
			else
				boss_user.attack_count = boss_user.attack_count + 1
				local index = boss_user.attack_count
				local list_count = #bossConf.ATTACK_BUFF_LIST
				if index > list_count then
					index = list_count
				end
				boss_user.tech_id = bossConf.ATTACK_BUFF_LIST[index]
				boss_user.start_time = now_time
			end
			PlanetCache.resetBossUser(boss_user)

			local isWin
			local event_list
			local attacker_hp_list
			local hurter_hp_list
			local video_key_list = {}

			local lineup_monster = bossConf.MONSTER_LIST
			local initMonster = false
			if Tools.isEmpty(element.boss_data.monster_hp_list) == true then
				initMonster = true
				element.boss_data.monster_hp_list = {0,0,0,0,0,0,0,0,0,}
			end

			local monster_list = {}
			local big_ship = 0
			local monster_all_hp = 0
			local monster_sub_hp = 0
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

					local ship_info = Tools.createShipByConf(ship_id)
					ship_info.position = k
					ship_info.body_position = bodyPositions
					table.insert(monster_list, ship_info)

					if initMonster then
						element.boss_data.monster_hp_list[k] = ship_info.attr[CONF.EShipAttr.kHP]
					end
					monster_all_hp = monster_all_hp + ship_info.attr[CONF.EShipAttr.kHP]
				end
			end
	
			for i,v in ipairs(planet_army.ship_list) do
				if Tools.checkShipDurable(v) == false then
					v.attr[CONF.EShipAttr.kHP] = 0
				end
			end

			local pre_enemy_hp_list = Tools.clone(element.boss_data.monster_hp_list)

			isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(planet_army.ship_list, planet_army.lineup_hp, monster_list, element.boss_data.monster_hp_list)

			local pre_my_ship_energy_level_list = {0,0,0,0,0,0,0,0,0,}

			for i,v in ipairs(planet_army.ship_list) do

				if v.energy_level then
					pre_my_ship_energy_level_list[v.position] = v.energy_level
				end

				Tools.shipSubDurable( v, 2, isWin and 1 or 0, planet_army.tech_durable_param )

				Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
			end

			local resp = {
				result = 2,
				attack_list = planet_army.ship_list,
				hurter_list = monster_list,
				event_list = event_list,
				attacker_hp_list = planet_army.lineup_hp,
				hurter_hp_list = element.boss_data.monster_hp_list,
			}

			local video_key = VideoCache.addVideo(planet_user.user_name, resp)
			table.insert(video_key_list, video_key)
			if attacker_hp_list ~= nil then
				planet_army.lineup_hp = attacker_hp_list
			end

			if (Tools.isEmpty(element.boss_data.monster_hp_list)==false) then
				for i,v in ipairs(element.boss_data.monster_hp_list) do
					if v > 0 then
						monster_sub_hp = monster_sub_hp + (v - element.boss_data.monster_hp_list[i])
					end
				end
			end

			element.boss_data.monster_hp_list = hurter_hp_list
			local  monster_sub_hp_percent = monster_sub_hp / monster_all_hp * 100

			local level_list = CONF.PARAM.get("task_planet_level_interval_boss").PARAM
			local level_list_count = #level_list
			if Tools.isEmpty(planet_user.boss_level_times_list) then
				planet_user.boss_level_times_list = {}
				for i=1,level_list_count do
					planet_user.boss_level_times_list[i] = 0
				end
			end

			for i=1,level_list_count do
				if bossConf.LV <= level_list[i] then
					planet_user.boss_level_times_list[i] = planet_user.boss_level_times_list[i] + 1
					break
				end
			end
			if Tools.isEmpty(planet_user.boss_level_times_list_day) then
				planet_user.boss_level_times_list_day = {}
				for i=1,level_list_count do
					planet_user.boss_level_times_list_day[i] = 0
				end
			end

			for i=1,level_list_count do
				if bossConf.LV <= level_list[i] then
					planet_user.boss_level_times_list_day[i] = planet_user.boss_level_times_list_day[i] + 1
					break
				end
			end

			if Tools.isEmpty(planet_user.seven_days_data) then
				planet_user.seven_days_data = {}
			end
			if planet_user.seven_days_data.boss_level_times_list_day==nil then
				planet_user.seven_days_data.boss_level_times_list_day = 1
			else
				planet_user.seven_days_data.boss_level_times_list_day = planet_user.seven_days_data.boss_level_times_list_day + 1
			end


			if isWin then
				PlanetCache.removeBossElement(element.global_key)
      				
				local items = Tools.getRewards( bossConf.END_REWARD )
				if Tools.isEmpty(planet_army.item_list) == true then
					planet_army.item_list = {}
				end
				for id,num in pairs(items) do
					local item = {
						id = id,
						num = num,
						guid = 0,
					}
					addItemToList(item, planet_army.item_list)
				end

				--广播

				local other_user_info = UserInfoCache.get(planet_user.user_name)
				sendBroadcast(planet_user.user_name, Lang.world_chat_sender, string.format(Lang.planet_boss_board_msg, other_user_info.nickname, CONF.STRING.get(bossConf.NAME).VALUE))
			else
				local reward_index
				for i=1,#bossConf.HARM/2 do
					if monster_sub_hp_percent >= bossConf.HARM[i * 2 -1] and monster_sub_hp_percent < bossConf.HARM[i * 2] then
						reward_index = i
					end
				end

				if reward_index then
					local items = Tools.getRewards( bossConf.REWARD[reward_index] )
					if Tools.isEmpty(planet_army.item_list) == true then
						planet_army.item_list = {}
					end
					for id,num in pairs(items) do
						local item = {
							id = id,
							num = num,
							guid = 0,
						}
						addItemToList(item, planet_army.item_list)
					end
				end

				local node_id = tonumber(Tools.split(element.global_key, "_")[1])
				PlanetCache.saveNodeDataByID(node_id)
	      	end

 			local enemy_mail_user = PlanetCache.createMailUserByMonster( hurter_hp_list, monster_list)
 			enemy_mail_user_list = {enemy_mail_user}

			local mail_user = PlanetCache.createMailUser(planet_user, planet_army)
			mail_user.pre_ship_energy_level_list = pre_my_ship_energy_level_list
			my_mail_user_list = {mail_user}
				
			local report = {
				type = 14,
				result = true,
				id = element.boss_data.id,
				pos_list = element.pos_list,
				isWin = isWin,
				video_key_list = video_key_list,
				my_data_list = my_mail_user_list,
				enemy_data_list = enemy_mail_user_list,
				item_list_list = {
					{item_list = planet_army.item_list},
				},
				attack_count = boss_user.attack_count,
				pre_enemy_hp_list = pre_enemy_hp_list,
			}
			RedoList.addPlanetMail(planet_user.user_name, report)

			local mail_update = CoreMail.getMultiCast(planet_user.user_name)
  		      	local mail_update_buff = Tools.encode("Multicast", mail_update)
  		      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)


  		      	moveArmyBack(now_time, planet_army)

  		      	PlanetCache.saveUserData( planet_user )
			end

	elseif planet_army.status == Status.kMoveBack then

		if isArrived(now_time, planet_army.line) then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)

			if Tools.isEmpty(planet_army.army_key_list) == false then
				for i,army_key in ipairs(planet_army.army_key_list) do
					local army = PlanetCache.getArmy(army_key)
					local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])
					PlanetStatusMachine[army.status_machine].back(now_time, user, army)
				end
				planet_army.army_key_list = nil
			end

			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end

function EnlistMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time

	planet_army.status = Status.kEnlist

	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	PlanetCache.closeShield(src_element)

	local element = PlanetCache.getElement(planet_army.element_global_key)
	if element and element.type == 1 then
		PlanetCache.userAddAttacker( element.base_data.user_name, planet_army.army_key )
	end

	PlanetCache.broadcastUpdate(planet_user.user_name, tonumber(Tools.split(planet_user.base_global_key, "_")[1]))
end

function EnlistMachine.back(now_time, planet_user, planet_army)
	Tools._print("aaaaaaaaaaa111")
	if planet_army.status == Status.kEnlist then
		PlanetCache.removeEnlistInGroup( planet_army.army_key )
	end

	local element = PlanetCache.getElement(planet_army.element_global_key)
	if element and element.type == 1 then
		PlanetCache.userRemoveAttacker( element.base_data.user_name, planet_army.army_key)
	end

	if Tools.isEmpty(planet_army.army_key_list) == false then
		for i,army_key in ipairs(planet_army.army_key_list) do
			local army = PlanetCache.getArmy(army_key)
			local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])

			local src_element = PlanetCache.getElement(planet_user.base_global_key)
			local dest_element = PlanetCache.getElement(user.base_global_key) 

			local node_list = moveArmy(now_time, src_element.pos_list[1], dest_element.pos_list[1], user, army, Status.kMoveBack)

			PlanetCache.saveUserData(user)
			PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
		end
	end

	planet_army.status = Status.kMoveEnd
Tools._print("aaaaaaaaaaa222")
	return true
end

function EnlistMachine.moveBase(now_time, planet_user, planet_army )

	PlanetCache.removeEnlistInGroup( planet_army.army_key )

	local element = PlanetCache.getElement(planet_army.element_global_key)
	if element and element.type == 1 then
		PlanetCache.userRemoveAttacker( element.base_data.user_name, planet_army.army_key)
	end

	if Tools.isEmpty(planet_army.army_key_list) == false then
		for i,army_key in ipairs(planet_army.army_key_list) do
			local army = PlanetCache.getArmy(army_key)
			local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])

			local src_element = PlanetCache.getElement(planet_user.base_global_key)
			local dest_element = PlanetCache.getElement(user.base_global_key) 

			local node_list = moveArmy(now_time, src_element.pos_list[1], dest_element.pos_list[1], user, army, Status.kMoveBack)

			PlanetCache.saveUserData(user)
			PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
		end
	end

	moveEnd(planet_user, planet_army, Status.kMoveEnd)

	PlanetCache.saveUserData(planet_user)
end

function EnlistMachine.doLogic(now_time, planet_user, planet_army)
	if planet_army.status == Status.kEnlist then

		if now_time - planet_army.begin_time > planet_army.mass_time then

Tools._print("111111111111111111")
			local element = PlanetCache.getElement(planet_army.element_global_key)
			--元素消失 队伍返回
			if element == nil 
				or (checkElement(element, 1, element.pos_list[1]) == false 
				and checkElement(element, 5, element.pos_list[1]) == false
				and checkElement(element, 12, element.pos_list[1]) == false
				and checkElement(element, 13, element.pos_list[1]) == false) then
			
				PlanetStatusMachine[planet_army.status_machine].back(now_time, planet_user, planet_army)
				return
			end
Tools._print("222222222222222222")
			--无人加入 队伍返回
			if Tools.isEmpty(planet_army.army_key_list) == true then
				PlanetStatusMachine[planet_army.status_machine].back(now_time, planet_user, planet_army)
				return
			end
Tools._print("3333333333333333")
			local element = PlanetCache.getElement(planet_army.element_global_key)
			if element.type == 1 then
				PlanetCache.userRemoveAttacker( element.base_data.user_name, planet_army.army_key)
			end

			planet_army.status_machine = planet_army.next_status_machine
			planet_army.next_status_machine = nil

			PlanetStatusMachine[planet_army.status_machine].start(now_time, planet_user, planet_army)
			PlanetCache.saveUserData(planet_user)
Tools._print("4444444444444444")
		end

	elseif planet_army.status == Status.kMoveEnd then

	elseif planet_army.status == Status.kMoveBack then
	end

end


function MonsterAttackMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time

	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	local src = src_element.pos_list[1]

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local dest = dest_element.pos_list[1]

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
end

function MonsterAttackMachine.back( now_time, planet_user, planet_army )

	local node_list

	if planet_army.status == Status.kMove then

		node_list = moveArmyBack(now_time, planet_army)
	else
		return false
	end

	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
	return true
end

function MonsterAttackMachine.moveBase(now_time, planet_user, planet_army )

	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		local node_id_list = planet_army.line.node_id_list

		moveEnd(planet_user, planet_army, Status.kMoveEnd)

		PlanetCache.saveUserData(planet_user)

		return node_id_list
	end

	return nil
end

function MonsterAttackMachine.doLogic(now_time, planet_user, planet_army)

	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then
			--Tools._print("doLogic start")
			local element = PlanetCache.getElement(planet_army.element_global_key)
			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]

			--元素消失 队伍返回
			--Tools.print_t(element)
			--Tools.print_t(dest_pos)
			if element == nil or element.monster_data.isDead == 1 or checkElement(element, 11, dest_pos) == false then
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				Tools._print("MonsterAttackMachine doLogic checkElement false")
				return
			end

			local creepsConf = CONF.PLANETCREEPS.get(element.monster_data.id)


			local isWin
			local video_key_list = {}
			local event_list
			local attacker_hp_list
			local hurter_hp_list

			local pre_my_ship_energy_level_list				

			local lineup_monster = creepsConf.MONSTER_LIST
			local initMonster = false
			if Tools.isEmpty(element.monster_data.monster_hp_list) == true then
				initMonster = true
				element.monster_data.monster_hp_list = {0,0,0,0,0,0,0,0,0,}
			end

			local hurter_list = {}
			for k,ship_id in ipairs(lineup_monster) do
				if ship_id > 0 then
					local ship_info = Tools.createShipByConf(ship_id)
					ship_info.position = k
					ship_info.body_position = {k}
					table.insert(hurter_list, ship_info)

					if initMonster then
						element.monster_data.monster_hp_list[k] = ship_info.attr[CONF.EShipAttr.kHP]
					end
				end
			end

			for i,v in ipairs(planet_army.ship_list) do
				if Tools.checkShipDurable(v) == false then
					v.attr[CONF.EShipAttr.kHP] = 0
				end
			end
--Tools._print("doLogic start 1111111111111111")
			isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(planet_army.ship_list, planet_army.lineup_hp, hurter_list, element.monster_data.monster_hp_list)
		
			pre_my_ship_energy_level_list = {0,0,0,0,0,0,0,0,0,}

			element.monster_data.monster_hp_list = hurter_hp_list

			for i,v in ipairs(planet_army.ship_list) do

				if v.energy_level then
					pre_my_ship_energy_level_list[v.position] = v.energy_level
				end
				
				Tools.shipSubDurable( v, 2, isWin and 1 or 0, planet_army.tech_durable_param )

				Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
			end

			local resp = {
				result = 2,
				attack_list = planet_army.ship_list,
				hurter_list = hurter_list,
				event_list = event_list,
				attacker_hp_list = planet_army.lineup_hp,
			}
			local video_key = VideoCache.addVideo(planet_user.user_name, resp)
			table.insert(video_key_list, video_key)
			if attacker_hp_list ~= nil then
				planet_army.lineup_hp = attacker_hp_list
			end
				
			if isWin then

				local items = Tools.getRewards( creepsConf.REWARD_ID )
				if Tools.isEmpty(planet_army.item_list) == true then
					planet_army.item_list = {}
				end
				for id,num in pairs(items) do
					local item = {
						id = id,
						num = num,
						guid = 0,
					}
					addItemToList(item, planet_army.item_list)
				end

				element.monster_data.isDead = 1
				element.monster_data.dead_time = now_time
				element.monster_data.monster_hp_list = nil

				--Tools._print("1111111111111111111111")
				if  Tools.isEmpty(planet_user.attack_monster_times) then
					planet_user.attack_monster_times = {}
					local maxcount = CONF.PARAM.get("creeps_max_level").PARAM					
					for i = 1 , maxcount do
						planet_user.attack_monster_times[i] = 0
					end
				end
				--Tools.print_t(planet_user.attack_monster_times)
				planet_user.attack_monster_times[creepsConf.LEVEL] = planet_user.attack_monster_times[creepsConf.LEVEL] + 1

				if Tools.isEmpty(planet_user.seven_days_data) then
					planet_user.seven_days_data = {}
				end
				if planet_user.seven_days_data.attack_monster_times==nil then
					planet_user.seven_days_data.attack_monster_times = 1
				else
					planet_user.seven_days_data.attack_monster_times = planet_user.seven_days_data.attack_monster_times + 1
				end
				--Tools._print("222222222222222222222")

				--PlanetCache.removeElement(element.global_key)

				--local level_list = CONF.PARAM.get("task_planet_level_interval_ruins").PARAM
				--local level_list_count = #level_list
				--if Tools.isEmpty(planet_user.ruins_level_times_list) then
				--	planet_user.ruins_level_times_list = {}
				--	for i=1,level_list_count do
				--		planet_user.ruins_level_times_list[i] = 0
				--	end
				--end
				--for i=1,level_list_count do
				--	if creepsConf.LEVEL <= level_list[i] then
				--		planet_user.ruins_level_times_list[i] = planet_user.ruins_level_times_list[i] + 1
				--		Tools._print("add ruins", i, planet_user.ruins_level_times_list[i])
				--		break
				--	end
				--end
				
			end

			local my_mail_user = PlanetCache.createMailUser(planet_user, planet_army)
			my_mail_user.pre_ship_energy_level_list = pre_my_ship_energy_level_list
			local my_mail_user_list = {my_mail_user}
			local report = {
				type = 18,
				result = true,
				item_list_list = {
					{item_list = planet_army.item_list},
				},
				id = element.monster_data.id,
				pos_list = element.pos_list,
				isWin = isWin,
				video_key_list = video_key_list,
				my_data_list = my_mail_user_list,
			}
			RedoList.addPlanetMail(planet_user.user_name, report)

			local mail_update = CoreMail.getMultiCast(planet_user.user_name)
      		      	local mail_update_buff = Tools.encode("Multicast", mail_update)
      		      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)

			moveArmyBack(now_time, planet_army)

			PlanetCache.saveUserData(planet_user)

			--print("doLogic end")
		end

	elseif  planet_army.status == Status.kMoveBack then


		if isArrived(now_time, planet_army.line) then

			
			moveEnd(planet_user, planet_army, Status.kMoveEnd)
			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end


function WangZuoMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time


	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	local src = src_element.pos_list[1]

	PlanetCache.closeShield(src_element)

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local dest = dest_element.pos_list[1]

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)

	PlanetCache.groupAddAttacker(dest_element.wangzuo_data.groupid, planet_army.army_key)

end

function WangZuoMachine.back(now_time, planet_user, planet_army)
	local node_list
	if planet_army.status == Status.kMove then

		node_list = moveArmyBack(now_time, planet_army)

		local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
		PlanetCache.groupRemoveAttacker(dest_element.wangzuo_data.groupid, planet_army.army_key)

		PlanetCache.removeEnlistInGroup( planet_army.army_key )
	elseif planet_army.status == Status.kGuarde then

		local element = PlanetCache.getElement(planet_army.element_global_key)
	
		for i,v in ipairs(element.wangzuo_data.guarde_list) do
			if v == planet_army.army_key then
				table.remove(element.wangzuo_data.guarde_list, i)
				break
			end
		end
	

		local key_list = Tools.split(element.global_key, "_")
		PlanetCache.saveNodeDataByID(tonumber(key_list[1]))
		

		local my_base = PlanetCache.getElement(planet_user.base_global_key)

		if planet_army.element_global_key == planet_user.base_global_key then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)
		else
			local node_list = moveArmy(now_time, element.pos_list[1], my_base.pos_list[1], planet_user, planet_army, Status.kMoveBack)

			PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
		end

		PlanetCache.saveUserData(planet_user)
	else
		return false
	end



	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
	return true
end

function WangZuoMachine.moveBase(now_time, planet_user, planet_army )

	local node_id_list
	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		node_id_list = planet_army.line.node_id_list

		local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
		PlanetCache.groupRemoveAttacker(dest_element.wangzuo_data.groupid, planet_army.army_key)

		PlanetCache.removeEnlistInGroup( planet_army.army_key )

	elseif planet_army.status == Status.kGuarde then

		return
	end

	moveEnd(planet_user, planet_army, Status.kMoveEnd)

	PlanetCache.saveUserData(planet_user)


	if Tools.isEmpty(planet_army.army_key_list) == false then
		for i,army_key in ipairs(planet_army.army_key_list) do
			local army = PlanetCache.getArmy(army_key)
			local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])

			local src_element = PlanetCache.getElement(planet_user.base_global_key)
			local dest_element = PlanetCache.getElement(user.base_global_key) 

			local node_list = moveArmy(now_time, src_element.pos_list[1], dest_element.pos_list[1], user, army, Status.kMoveBack)

			PlanetCache.saveUserData(user)
			PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
		end
	end

	return node_id_list
end

function WangZuoMachine.doLogic(now_time, planet_user, planet_army)
	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then
		Tools._print("11111111111")	
			local element = PlanetCache.getElement(planet_army.element_global_key)
			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]
			local src_pos = planet_army.line.move_list[1]

			local my_other_user_info = UserInfoCache.get(planet_user.user_name)

			PlanetCache.removeEnlistInGroup( planet_army.army_key )

			PlanetCache.groupRemoveAttacker(element.wangzuo_data.groupid, planet_army.army_key)
Tools._print("22222222222222222")	
			--和平时期
			if element.wangzuo_data.status == 1 then

				local report1 = {
					type = 23,
					result = true,
					id = element.wangzuo_data.id,
					pos_list = element.pos_list,
					isWin = false,
				}
				RedoList.addPlanetMail(planet_user.user_name, report1)

				if Tools.isEmpty(planet_army.army_key_list) == false then
					for i,v in ipairs(planet_army.army_key_list) do
						local user_name = Tools.split(v, "_")[1]
						RedoList.addPlanetMail(user_name, report1)
					end
				end		
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			--同一公会没必要打了
			if (my_other_user_info.groupid ~= "" and my_other_user_info.groupid ~= nil) and element.wangzuo_data.groupid == my_other_user_info.groupid then
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end
Tools._print("4444444444444")	
			local isWin
			local event_list
			local attacker_hp_list
			local hurter_hp_list
			local video_key_list = {}

			local my_mail_user_list = {}
			local enemy_mail_user_list = {}

			local attacker_recv_mail_user_list = {}
			local enemy_recv_mail_user_list = {}

			local update_node_list = {}

			local attacker_army_key_list = {planet_army.army_key}
			if Tools.isEmpty(planet_army.army_key_list) == false then
				for i,army_key in ipairs(planet_army.army_key_list) do
					table.insert(attacker_army_key_list, army_key)
				end
			end

			local pre_attacker_ship_energy_level_list_list = {}
			local pre_enemy_ship_energy_level_list_list = {}
			
			if Tools.isEmpty(element.wangzuo_data.guarde_list) == false then

				local enemy_index = 1

				for i,army_key in ipairs(attacker_army_key_list) do

					local attacker_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					local attacker_army = PlanetCache.getArmy(army_key)

					for i,enemy_army_key in ipairs(element.wangzuo_data.guarde_list) do

						if i >= enemy_index then

							local enemy_user = PlanetCache.getUser(Tools.split(enemy_army_key, "_")[1])
							local enemy_army = PlanetCache.getArmy(enemy_army_key)

							if enemy_army.status == Status.kGuarde then

								for i,v in ipairs(attacker_army.ship_list) do
									if Tools.checkShipDurable(v) == false then
										v.attr[CONF.EShipAttr.kHP] = 0
									end
								end

								for i,v in ipairs(enemy_army.ship_list) do
									if Tools.checkShipDurable(v) == false then
										v.attr[CONF.EShipAttr.kHP] = 0
									end
								end

								isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(attacker_army.ship_list, attacker_army.lineup_hp, enemy_army.ship_list, enemy_army.lineup_hp)

								for i,v in ipairs(attacker_army.ship_list) do

									if v.energy_level then
										if pre_attacker_ship_energy_level_list_list[i] == nil then
											pre_attacker_ship_energy_level_list_list[i] = {0,0,0,0,0,0,0,0,0,}
										end
										pre_attacker_ship_energy_level_list_list[i][v.position] = math.max(pre_attacker_ship_energy_level_list_list[i][v.position], v.energy_level) 
									end
							
									Tools.shipSubDurable( v, 2, isWin and 1 or 0, attacker_army.tech_durable_param )

									Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
								end

								for i,v in ipairs(enemy_army.ship_list) do
									if v.energy_level then
										if pre_enemy_ship_energy_level_list_list[i] == nil then
											pre_enemy_ship_energy_level_list_list[i] = {0,0,0,0,0,0,0,0,0,}
										end
										pre_enemy_ship_energy_level_list_list[i][v.position] = math.max(pre_enemy_ship_energy_level_list_list[i][v.position], v.energy_level) 
									end

									Tools.shipSubDurable( v, 2, isWin and 0 or 1, enemy_army.tech_durable_param )

									Tools.shipSubEnergy( v, 2, isWin and 0 or 1, true)
								end
								
								local resp = {
									result = 2,
									attack_list = attacker_army.ship_list,
									hurter_list = enemy_army.ship_list,
									event_list = event_list,
									attacker_hp_list = attacker_army.lineup_hp,
									hurter_hp_list = enemy_army.lineup_hp,
								}

								local video_key = VideoCache.addVideo(attacker_user.user_name, resp)
								table.insert(video_key_list, video_key)

								if hurter_hp_list ~= nil then
									enemy_army.lineup_hp = hurter_hp_list
								end
								if attacker_hp_list ~= nil then
									attacker_army.lineup_hp = attacker_hp_list
								end
								
								
								if checkArmyAllDead(enemy_army) == true then

									PlanetStatusMachine[enemy_army.status_machine].back(now_time, enemy_user, enemy_army)
								end
								PlanetCache.saveUserData(enemy_user)
								PlanetCache.saveUserData(attacker_user)

								if isWin == false then
									break
								else
									enemy_index = enemy_index + 1
								end								

							end

						end
					end
					
					if isWin == true then
						break
					end
				end


				for i,army_key in ipairs(attacker_army_key_list) do

					local attacker_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					local attacker_army = PlanetCache.getArmy(army_key)

					local my_mail_user = PlanetCache.createMailUser(attacker_user, attacker_army)
					my_mail_user.pre_ship_energy_level_list = pre_attacker_ship_energy_level_list_list[i]
					table.insert(my_mail_user_list, my_mail_user)

					table.insert(attacker_recv_mail_user_list, attacker_user.user_name)
				end

				for _,army_key in ipairs(element.wangzuo_data.guarde_list) do
				
					local enemy_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					local enemy_army = PlanetCache.getArmy( army_key )

					local enemy_mail_user = PlanetCache.createMailUser(enemy_user, enemy_army)
					enemy_mail_user.pre_ship_energy_level_list = pre_enemy_ship_energy_level_list_list[i]
					table.insert(enemy_mail_user_list, enemy_mail_user)

					table.insert(enemy_recv_mail_user_list, enemy_user.user_name)
				end
			
				local user_name_list = {}
				local report1 = {
					type = 19,
					result = true,
					id = element.wangzuo_data.id,
					pos_list = element.pos_list,
					isWin = isWin,
					video_key_list = video_key_list,
					my_data_list = my_mail_user_list,
					enemy_data_list = enemy_mail_user_list,
				}
				for i,user_name in ipairs(attacker_recv_mail_user_list) do
 					
					RedoList.addPlanetMail(user_name, report1)
					table.insert(user_name_list, user_name)
				end

				local report2 = {
					type = 20,
					result = true,
					id = element.wangzuo_data.id,
					pos_list = element.pos_list,
					isWin = (not isWin),
					video_key_list = video_key_list,
					my_data_list = enemy_mail_user_list,
					enemy_data_list = my_mail_user_list,
				}

				for _,user_name in ipairs(enemy_recv_mail_user_list) do
				
					RedoList.addPlanetMail(user_name, report2)
					table.insert(user_name_list, user_name)
				end

				local mail_update = CoreMail.getMultiCast(user_name_list)
				local mail_update_buff = Tools.encode("Multicast", mail_update)
				activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)

			else
				
				isWin = true

				if element.wangzuo_data.user_name ~= nil then
					for i,army_key in ipairs(attacker_army_key_list) do

	 					local army = PlanetCache.getArmy(army_key)
						local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
						
	 					local mail_user = PlanetCache.createMailUser(user, army)
	 					mail_user.pre_ship_energy_level_list = pre_attacker_ship_energy_level_list_list[i]
	 					table.insert(my_mail_user_list, mail_user)

	 					table.insert(attacker_recv_mail_user_list, user.user_name)
	 				end

					local report = {
						type = 19,
						result = true,
						id = element.wangzuo_data.id,
						pos_list = element.pos_list,
						isWin = isWin,
						my_data_list = my_mail_user_list,
					}

					for i,user_name in ipairs(attacker_recv_mail_user_list) do
						RedoList.addPlanetMail(user_name, report)
					end
					
					local mail_update = CoreMail.getMultiCast(attacker_recv_mail_user_list)
      		      	local mail_update_buff = Tools.encode("Multicast", mail_update)
      		      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)
				end
			end

			

			if isWin then
				
				if Tools.isEmpty(element.wangzuo_data.guarde_list) == false then --之前有的队伍全部返回

					for i,army_key in ipairs(element.wangzuo_data.guarde_list) do

						local army = PlanetCache.getArmy(army_key)
						local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

						local base = PlanetCache.getElement(user.base_global_key)
						
						local node_list = moveArmy(now_time, element.pos_list[1], base.pos_list[1], user, army, Status.kMoveBack)

						addUpdateNodeList(update_node_list, node_list)

						PlanetCache.saveUserData(user)
					end
					element.wangzuo_data.guarde_list = nil
				end

				guarde(element, planet_user, planet_army)

				planet_user.attack_city_win_times = (planet_user.attack_city_win_times == nil and 0 or planet_user.attack_city_win_times) + 1
				planet_user.attack_win_times = (planet_user.attack_win_times == nil and 0 or planet_user.attack_win_times) + 1

				if Tools.isEmpty(planet_army.army_key_list) == false then
					for i,army_key in ipairs(planet_army.army_key_list) do

						local army = PlanetCache.getArmy(army_key)
						local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

						user.attack_city_win_times = (user.attack_city_win_times == nil and 0 or user.attack_city_win_times) + 1
						user.attack_win_times = (user.attack_win_times == nil and 0 or user.attack_win_times) + 1

						army.status_machine = 12
						army.element_global_key = element.global_key
						guarde(element, user, army)

						PlanetCache.saveUserData(user)
					end
				end

				planet_army.army_key_list = nil

				element.wangzuo_data.occupy_begin_time = now_time	
				element.wangzuo_data.user_name = planet_user.user_name
				element.wangzuo_data.groupid = my_other_user_info.groupid
				Tools._print("set wangzuo groupid",element.wangzuo_data.user_name,element.wangzuo_data.groupid)


				local key_list = Tools.split(element.global_key, "_") 
				local node_id = tonumber(key_list[1])
				PlanetCache.saveNodeDataByID(node_id)
				addUpdateNodeList(update_node_list, {node_id})
			else

				moveArmyBack(now_time, planet_army)

				if Tools.isEmpty(planet_army.army_key_list) == false then
					
					for i,army_key in ipairs(planet_army.army_key_list) do

						local army = PlanetCache.getArmy(army_key)
						local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

						local base = PlanetCache.getElement(user.base_global_key)
						
						local node_list = moveArmy(now_time, element.pos_list[1], base.pos_list[1], user, army, Status.kMoveBack)

						addUpdateNodeList(update_node_list, node_list)

						PlanetCache.saveUserData(user)
					end

					planet_army.army_key_list = nil
				end
			end

			PlanetCache.saveUserData(planet_user)


			if Tools.isEmpty(update_node_list) == false then
				PlanetCache.broadcastUpdate(planet_user.user_name, update_node_list)
			end
		end

	elseif planet_army.status == Status.kGuarde then
		local element = PlanetCache.getElement(planet_army.element_global_key)
		if element.wangzuo_data.status == 2 then
			local cityConf = CONF.PLANETCITY.get(element.wangzuo_data.id)
			if now_time - element.wangzuo_data.occupy_begin_time >= cityConf.HOLD_TIME then
				Tools._print("tttttttttttttttttttt game end")
				element.wangzuo_data.status = 1
				element.wangzuo_data.status_begin_time = now_time
				element.wangzuo_data.old_user_name = nil
				element.wangzuo_data.old_groupid = ""

				PlanetCache.WangZuoGuardeBack(now_time, element.wangzuo_data.guarde_list)
				PlanetCache.SetWangZuoOccupy(element.wangzuo_data)

				local key_list = Tools.split(element.global_key, "_") 
				local node_id = tonumber(key_list[1])
				PlanetCache.saveNodeDataByID(node_id)

				PlanetCache.broadcastUpdate(planet_user.user_name, {node_id})

				PlanetCache.SetTowerStatus(now_time, element,element.wangzuo_data.status)
			end
		end

	elseif planet_army.status == Status.kMoveBack then

		if isArrived(now_time, planet_army.line) then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)

			if Tools.isEmpty(planet_army.army_key_list) == false then
				for i,army_key in ipairs(planet_army.army_key_list) do
					local army = PlanetCache.getArmy(army_key)
					local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])
					PlanetStatusMachine[army.status_machine].back(now_time, user, army)
				end
				planet_army.army_key_list = nil
			end

			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end


function WangZuoTowerMachine.start(now_time, planet_user, planet_army)

	planet_army.begin_time = now_time


	local src_element = PlanetCache.getElement(planet_user.base_global_key) 
	local src = src_element.pos_list[1]

	PlanetCache.closeShield(src_element)

	local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
	local dest = dest_element.pos_list[1]

	local node_list = moveArmy(now_time, src, dest, planet_user, planet_army, Status.kMove)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)

	PlanetCache.groupAddAttacker(dest_element.tower_data.groupid, planet_army.army_key)

end

function WangZuoTowerMachine.back(now_time, planet_user, planet_army)
	local node_list
	if planet_army.status == Status.kMove then

		node_list = moveArmyBack(now_time, planet_army)

		local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
		PlanetCache.groupRemoveAttacker(dest_element.tower_data.groupid, planet_army.army_key)

		PlanetCache.removeEnlistInGroup( planet_army.army_key )
	elseif planet_army.status == Status.kGuarde then

		local element = PlanetCache.getElement(planet_army.element_global_key)
	
		for i,v in ipairs(element.tower_data.guarde_list) do
			if v == planet_army.army_key then
				table.remove(element.tower_data.guarde_list, i)
				break
			end
		end
	

		local key_list = Tools.split(element.global_key, "_")
		PlanetCache.saveNodeDataByID(tonumber(key_list[1]))
		

		local my_base = PlanetCache.getElement(planet_user.base_global_key)
		Tools._print("WangZuoTowerMachine.back",planet_army.element_global_key,planet_user.base_global_key)
		if planet_army.element_global_key == planet_user.base_global_key then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)
		else
			local node_list = moveArmy(now_time, element.pos_list[1], my_base.pos_list[1], planet_user, planet_army, Status.kMoveBack)

			PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
		end

		PlanetCache.saveUserData(planet_user)
	else
		return false
	end



	PlanetCache.saveUserData(planet_user)

	PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
	return true
end

function WangZuoTowerMachine.moveBase(now_time, planet_user, planet_army )

	local node_id_list
	if planet_army.status == Status.kMove or planet_army.status == Status.kMoveBack  then

		node_id_list = planet_army.line.node_id_list

		local dest_element = PlanetCache.getElement(planet_army.element_global_key) 
		PlanetCache.groupRemoveAttacker(dest_element.tower_data.groupid, planet_army.army_key)

		PlanetCache.removeEnlistInGroup( planet_army.army_key )

	elseif planet_army.status == Status.kGuarde then

		return
	end

	moveEnd(planet_user, planet_army, Status.kMoveEnd)

	PlanetCache.saveUserData(planet_user)


	if Tools.isEmpty(planet_army.army_key_list) == false then
		for i,army_key in ipairs(planet_army.army_key_list) do
			local army = PlanetCache.getArmy(army_key)
			local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])

			local src_element = PlanetCache.getElement(planet_user.base_global_key)
			local dest_element = PlanetCache.getElement(user.base_global_key) 

			local node_list = moveArmy(now_time, src_element.pos_list[1], dest_element.pos_list[1], user, army, Status.kMoveBack)

			PlanetCache.saveUserData(user)
			PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
		end
	end

	return node_id_list
end

function WangZuoTowerMachine.doLogic(now_time, planet_user, planet_army)
	if planet_army.status == Status.kMove then

		if isArrived(now_time, planet_army.line) then
			
			local element = PlanetCache.getElement(planet_army.element_global_key)
			local dest_pos = planet_army.line.move_list[#planet_army.line.move_list]
			local src_pos = planet_army.line.move_list[1]

			local my_other_user_info = UserInfoCache.get(planet_user.user_name)

			PlanetCache.removeEnlistInGroup( planet_army.army_key )

			PlanetCache.groupRemoveAttacker(element.tower_data.groupid, planet_army.army_key)

			--和平时期
			if element.tower_data.status == 1 then

				local report1 = {
					type = 24,
					result = true,
					id = element.tower_data.id,
					pos_list = element.pos_list,
					isWin = false,
				}
				RedoList.addPlanetMail(planet_user.user_name, report1)

				if Tools.isEmpty(planet_army.army_key_list) == false then
					for i,v in ipairs(planet_army.army_key_list) do
						local user_name = Tools.split(v, "_")[1]
						RedoList.addPlanetMail(user_name, report1)
					end
				end
			
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			--同一公会没必要打了
			if (my_other_user_info.groupid ~= "" and my_other_user_info.groupid ~= nil) and element.tower_data.groupid == my_other_user_info.groupid then
				local node_list = moveArmyBack(now_time, planet_army)
				PlanetCache.saveUserData(planet_user)
				PlanetCache.broadcastUpdate(planet_user.user_name, node_list)
				return
			end

			local isWin
			local event_list
			local attacker_hp_list
			local hurter_hp_list
			local video_key_list = {}

			local my_mail_user_list = {}
			local enemy_mail_user_list = {}

			local attacker_recv_mail_user_list = {}
			local enemy_recv_mail_user_list = {}

			local update_node_list = {}

			local attacker_army_key_list = {planet_army.army_key}
			if Tools.isEmpty(planet_army.army_key_list) == false then
				for i,army_key in ipairs(planet_army.army_key_list) do
					table.insert(attacker_army_key_list, army_key)
				end
			end

			local pre_attacker_ship_energy_level_list_list = {}
			local pre_enemy_ship_energy_level_list_list = {}

			if Tools.isEmpty(element.tower_data.guarde_list) == false then

				local enemy_index = 1

				for i,army_key in ipairs(attacker_army_key_list) do

					local attacker_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					local attacker_army = PlanetCache.getArmy(army_key)

					for i,enemy_army_key in ipairs(element.tower_data.guarde_list) do

						if i >= enemy_index then

							local enemy_user = PlanetCache.getUser(Tools.split(enemy_army_key, "_")[1])
							local enemy_army = PlanetCache.getArmy(enemy_army_key)

							if enemy_army.status == Status.kGuarde then

								for i,v in ipairs(attacker_army.ship_list) do
									if Tools.checkShipDurable(v) == false then
										v.attr[CONF.EShipAttr.kHP] = 0
									end
								end

								for i,v in ipairs(enemy_army.ship_list) do
									if Tools.checkShipDurable(v) == false then
										v.attr[CONF.EShipAttr.kHP] = 0
									end
								end

								isWin, event_list, attacker_hp_list, hurter_hp_list = Tools.autoFight(attacker_army.ship_list, attacker_army.lineup_hp, enemy_army.ship_list, enemy_army.lineup_hp)

								for i,v in ipairs(attacker_army.ship_list) do

									if v.energy_level then
										if pre_attacker_ship_energy_level_list_list[i] == nil then
											pre_attacker_ship_energy_level_list_list[i] = {0,0,0,0,0,0,0,0,0,}
										end
										pre_attacker_ship_energy_level_list_list[i][v.position] = math.max(pre_attacker_ship_energy_level_list_list[i][v.position], v.energy_level) 
									end
							
									Tools.shipSubDurable( v, 2, isWin and 1 or 0, attacker_army.tech_durable_param )

									Tools.shipSubEnergy( v, 2, isWin and 1 or 0, true)
								end

								for i,v in ipairs(enemy_army.ship_list) do
									if v.energy_level then
										if pre_enemy_ship_energy_level_list_list[i] == nil then
											pre_enemy_ship_energy_level_list_list[i] = {0,0,0,0,0,0,0,0,0,}
										end
										pre_enemy_ship_energy_level_list_list[i][v.position] = math.max(pre_enemy_ship_energy_level_list_list[i][v.position], v.energy_level) 
									end

									Tools.shipSubDurable( v, 2, isWin and 0 or 1, enemy_army.tech_durable_param )

									Tools.shipSubEnergy( v, 2, isWin and 0 or 1, true)
								end
								
								local resp = {
									result = 2,
									attack_list = attacker_army.ship_list,
									hurter_list = enemy_army.ship_list,
									event_list = event_list,
									attacker_hp_list = attacker_army.lineup_hp,
									hurter_hp_list = enemy_army.lineup_hp,
								}

								local video_key = VideoCache.addVideo(attacker_user.user_name, resp)
								table.insert(video_key_list, video_key)

								if hurter_hp_list ~= nil then
									enemy_army.lineup_hp = hurter_hp_list
								end
								if attacker_hp_list ~= nil then
									attacker_army.lineup_hp = attacker_hp_list
								end
								
								
								if checkArmyAllDead(enemy_army) == true then

									PlanetStatusMachine[enemy_army.status_machine].back(now_time, enemy_user, enemy_army)
								end
								PlanetCache.saveUserData(enemy_user)
								PlanetCache.saveUserData(attacker_user)

								if isWin == false then
									break
								else
									enemy_index = enemy_index + 1
								end

								
							end


						end
					end
					
					if isWin == true then
						break
					end
				end


				for i,army_key in ipairs(attacker_army_key_list) do

					local attacker_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					local attacker_army = PlanetCache.getArmy(army_key)

					local my_mail_user = PlanetCache.createMailUser(attacker_user, attacker_army)
					my_mail_user.pre_ship_energy_level_list = pre_attacker_ship_energy_level_list_list[i]
					table.insert(my_mail_user_list, my_mail_user)

					table.insert(attacker_recv_mail_user_list, attacker_user.user_name)
				end

				for _,army_key in ipairs(element.tower_data.guarde_list) do
				
					local enemy_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					local enemy_army = PlanetCache.getArmy( army_key )

					local enemy_mail_user = PlanetCache.createMailUser(enemy_user, enemy_army)
					enemy_mail_user.pre_ship_energy_level_list = pre_enemy_ship_energy_level_list_list[i]
					table.insert(enemy_mail_user_list, enemy_mail_user)

					table.insert(enemy_recv_mail_user_list, enemy_user.user_name)
				end
			
				local user_name_list = {}
				local report1 = {
					type = 21,
					result = true,
					id = element.tower_data.id,
					pos_list = element.pos_list,
					isWin = isWin,
					video_key_list = video_key_list,
					my_data_list = my_mail_user_list,
					enemy_data_list = enemy_mail_user_list,
				}
				for i,user_name in ipairs(attacker_recv_mail_user_list) do
 					
					RedoList.addPlanetMail(user_name, report1)
					table.insert(user_name_list, user_name)
				end

				local report2 = {
					type = 22,
					result = true,
					id = element.tower_data.id,
					pos_list = element.pos_list,
					isWin = (not isWin),
					video_key_list = video_key_list,
					my_data_list = enemy_mail_user_list,
					enemy_data_list = my_mail_user_list,
				}

				for _,user_name in ipairs(enemy_recv_mail_user_list) do
				
					RedoList.addPlanetMail(user_name, report2)
					table.insert(user_name_list, user_name)
				end

				local mail_update = CoreMail.getMultiCast(user_name_list)
				local mail_update_buff = Tools.encode("Multicast", mail_update)
				activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)

			else

				isWin = true
				if element.tower_data.user_name ~= nil then
					for i,army_key in ipairs(attacker_army_key_list) do

	 					local army = PlanetCache.getArmy(army_key)
						local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
						
	 					local mail_user = PlanetCache.createMailUser(user, army)
	 					mail_user.pre_ship_energy_level_list = pre_attacker_ship_energy_level_list_list[i]
	 					table.insert(my_mail_user_list, mail_user)

	 					table.insert(attacker_recv_mail_user_list, user.user_name)
	 				end

					local report = {
						type = 21,
						result = true,
						id = element.tower_data.id,
						pos_list = element.pos_list,
						isWin = isWin,
						my_data_list = my_mail_user_list,
					}

					for i,user_name in ipairs(attacker_recv_mail_user_list) do
						RedoList.addPlanetMail(user_name, report)
					end
					
					local mail_update = CoreMail.getMultiCast(attacker_recv_mail_user_list)
      		      	local mail_update_buff = Tools.encode("Multicast", mail_update)
      		      	activeSendMessage(planet_user.user_name, 0x2100, mail_update_buff)
				end
			end

			

			if isWin then
				
				if Tools.isEmpty(element.tower_data.guarde_list) == false then --之前有的队伍全部返回

					for i,army_key in ipairs(element.tower_data.guarde_list) do

						local army = PlanetCache.getArmy(army_key)
						local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

						local base = PlanetCache.getElement(user.base_global_key)
						
						local node_list = moveArmy(now_time, element.pos_list[1], base.pos_list[1], user, army, Status.kMoveBack)

						addUpdateNodeList(update_node_list, node_list)

						PlanetCache.saveUserData(user)
					end
					element.tower_data.guarde_list = nil
				end

				guarde(element, planet_user, planet_army)

				planet_user.attack_city_win_times = (planet_user.attack_city_win_times == nil and 0 or planet_user.attack_city_win_times) + 1
				planet_user.attack_win_times = (planet_user.attack_win_times == nil and 0 or planet_user.attack_win_times) + 1

				if Tools.isEmpty(planet_army.army_key_list) == false then
					for i,army_key in ipairs(planet_army.army_key_list) do

						local army = PlanetCache.getArmy(army_key)
						local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

						user.attack_city_win_times = (user.attack_city_win_times == nil and 0 or user.attack_city_win_times) + 1
						user.attack_win_times = (user.attack_win_times == nil and 0 or user.attack_win_times) + 1

						army.status_machine = 13
						army.element_global_key = element.global_key
						guarde(element, user, army)

						PlanetCache.saveUserData(user)
					end
				end

				planet_army.army_key_list = nil

				element.tower_data.occupy_begin_time = now_time	
				element.tower_data.groupid = my_other_user_info.groupid
				element.tower_data.user_name = planet_user.user_name
				element.tower_data.is_attack = false


				local key_list = Tools.split(element.global_key, "_") 
				local node_id = tonumber(key_list[1])
				PlanetCache.saveNodeDataByID(node_id)
				addUpdateNodeList(update_node_list, {node_id})
			else

				moveArmyBack(now_time, planet_army)

				if Tools.isEmpty(planet_army.army_key_list) == false then
					
					for i,army_key in ipairs(planet_army.army_key_list) do

						local army = PlanetCache.getArmy(army_key)
						local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

						local base = PlanetCache.getElement(user.base_global_key)
						
						local node_list = moveArmy(now_time, element.pos_list[1], base.pos_list[1], user, army, Status.kMoveBack)

						addUpdateNodeList(update_node_list, node_list)

						PlanetCache.saveUserData(user)
					end

					planet_army.army_key_list = nil
				end
			end

			PlanetCache.saveUserData(planet_user)


			if Tools.isEmpty(update_node_list) == false then
				PlanetCache.broadcastUpdate(planet_user.user_name, update_node_list)
			end
		end

	elseif planet_army.status == Status.kGuarde then
		--local element = PlanetCache.getElement(planet_army.element_global_key)
		--if element.tower_data.status == 2 then
		--	local cityConf = CONF.PLANETCITY.get(element.tower_data.id)
		--	if now_time - element.tower_data.occupy_begin_time >= cityConf.HOLD_TIME then
		--
		--		element.tower_data.status = 1
		--
		--		local key_list = Tools.split(element.global_key, "_") 
		--		local node_id = tonumber(key_list[1])
		--		PlanetCache.saveNodeDataByID(node_id)
		--
		--		PlanetCache.broadcastUpdate(planet_user.user_name, {node_id})
		--	end
		--end

	elseif planet_army.status == Status.kMoveBack then

		if isArrived(now_time, planet_army.line) then

			moveEnd(planet_user, planet_army, Status.kMoveEnd)

			if Tools.isEmpty(planet_army.army_key_list) == false then
				for i,army_key in ipairs(planet_army.army_key_list) do
					local army = PlanetCache.getArmy(army_key)
					local user = PlanetCache.getUser(Tools.split(army_key,"_")[1])
					PlanetStatusMachine[army.status_machine].back(now_time, user, army)
				end
				planet_army.army_key_list = nil
			end

			PlanetCache.saveUserData(planet_user)
		end

	elseif  planet_army.status == Status.kMoveEnd then

	end
end

local PlanetStatusMachine = {

	[1] = ResMachine,
	[2] = RuinsMachine,
	[3] = FishingMachine,
	[4] = SpyMachine,
	[5] = GuardeMachine,
	[6] = BaseAttackMachine,
	[7] = AccompanyMachine,
	[8] = CityAttackMachine,
	[9] = BossAttackMachine,
	[10] = EnlistMachine,
	[11] = MonsterAttackMachine,
	[12] = WangZuoMachine,
	[13] = WangZuoTowerMachine,
	Status = Status,
}

return PlanetStatusMachine