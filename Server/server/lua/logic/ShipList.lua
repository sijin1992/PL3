local ShipList = {}
local Bit = require "Bit"
function ShipList:createMonster( ship_id )
	
	return Tools.createShipByConf(ship_id)
end

function ShipList:add(ship_id)
	local conf = CONF.AIRSHIP.get(ship_id)
	if not conf then
		return nil
	end
	local ship_list = self:getShipList()
	local guid = Tools.getGuid(ship_list, "guid")

	--保证一个ID只能有一艘船
	Tools._print("ship_list count",#ship_list)
	for i,v in ipairs(ship_list) do
		if v.id == ship_id then
			Tools._print("have id",ship_id)
			return nil
		end
	end
	
	local ship_info =
	{
		guid = guid,
		status = 1,
		id = conf.ID,
		type = conf.TYPE,
		kind = conf.KIND,
		quality = conf.QUALITY,
		star = conf.STAR,
		level = conf.LEVEL,
		skill = conf.SKILL,
		weapon_list = {0,0,0,},
		load = conf.LOAD,
		position = 0,
		equip_list = {0,0,0,0},
		exp = 0,
		ship_break = 0,
		gem_list = {},
	}

	if Tools.isEmpty(conf.HOLE) == false then
		for i,v in ipairs(conf.HOLE) do
			table.insert(ship_info.gem_list, 0)
		end
	end

	ship_info.attr = {}
	table.insert(ship_info.attr, conf.ANGER)--1
	table.insert(ship_info.attr, conf.LIFE)--2
	table.insert(ship_info.attr, conf.ATTACK)--3
	table.insert(ship_info.attr, conf.DEFENCE)--4
	table.insert(ship_info.attr, conf.SPEED)--5
	table.insert(ship_info.attr, conf.PROBABILITY_HIT)--6
	table.insert(ship_info.attr, conf.PROBABILITY_DODGE)--7
	table.insert(ship_info.attr, conf.PROBABILITY_CRIT)--8
	table.insert(ship_info.attr, conf.PROBABILITY_ANTICRIT)--9
	table.insert(ship_info.attr, conf.ATTACK_ADDITION)--10
	table.insert(ship_info.attr, conf.HURT_DURATION_ADDITION)--11
	table.insert(ship_info.attr, conf.HURT_SUBTRATION)--12
	table.insert(ship_info.attr, conf.HURT_DURATION_SUBTRATION)--13
	table.insert(ship_info.attr, 0)--14
	table.insert(ship_info.attr, 0)--15
	table.insert(ship_info.attr, 0)--16
	table.insert(ship_info.attr, conf.ANGER_RECOVER)--17
	table.insert(ship_info.attr, 0)--18
	table.insert(ship_info.attr, conf.HURT_ADDITION)--19
	table.insert(ship_info.attr, conf.ENERGY_ATTACK)--20
	table.insert(ship_info.attr, conf.ENGER_ATTACK_ADDITION)--21
	table.insert(ship_info.attr, conf.PROBABILITY_CRIT_EFFECT)--22
	table.insert(ship_info.attr, conf.HURT_REBOUND)--23
	table.insert(ship_info.attr, conf.PENETRATE)--24
	table.insert(ship_info.attr, conf.VAMPIRE)--25
	table.insert(ship_info.attr, 0)--26
	table.insert(ship_info.attr, 0)--27
	table.insert(ship_info.attr, 0)--28
	table.insert(ship_info.attr, 0)--29
	table.insert(ship_info.attr, conf.FINAL_PROBABILITY_HIT)--30
	table.insert(ship_info.attr, conf.FINAL_PROBABILITY_DODGE)--31
	table.insert(ship_info.attr, conf.FINAL_PROBABILITY_CRIT)--32
	table.insert(ship_info.attr, conf.FINAL_PROBABILITY_ANTICRIT)--33
	table.insert(ship_info.attr, conf.HURT_REBOUND_SUBTRATION)--34
	table.insert(ship_info.attr, 0)--35
	table.insert(ship_info.attr, 0)--36

	table.insert(ship_list, ship_info)

	ship_info.durable = Tools.getShipMaxDurable(ship_info)

	return ship_info
end


function ShipList:changeLineup(user_info, lineup)

	local guids = {}


	local ship_list = self:getShipList()
	for k,v in ipairs(ship_list) do
		local ship_info = self:getShipInfo(v.guid)
		ship_info.position = 0
		if Bit:has(ship_info.status, CONF.EShipState.kLineup) == true then
			ship_info.status = Bit:remove(ship_info.status, CONF.EShipState.kLineup)
		end
		guids[v.guid] = ship_info
	end

	for position,guid in ipairs(lineup) do
		for _,v in pairs(ship_list) do
			local ship_info = self:getShipInfo(v.guid)
			if guid == ship_info.guid then
				if Bit:has(ship_info.status, CONF.EShipState.kFix) == true then
					return 2
				end
				ship_info.position = position
				ship_info.status = Bit:add(ship_info.status, CONF.EShipState.kLineup)
				guids[v.guid] = ship_info
				break
			end
		end
	end

	local changedShips = {}
	for k,v in pairs(guids) do
		table.insert(changedShips,v)
	end

	user_info.lineup = lineup

	local other_user_info = UserInfoCache.get(user_info.user_name)
	if other_user_info then
		local id_lineup, lv_lineup, break_lineup = self:getLineupInfo()
		other_user_info.id_lineup = id_lineup
		other_user_info.lv_lineup = lv_lineup
		other_user_info.break_lineup = break_lineup
		UserInfoCache.set(user_info.user_name, other_user_info)
	end


	return 0,changedShips
end

function ShipList:addShipExp( guid, exp, user_sync )


	local user_info = self:getUserInfo()

	local ship_info = self:getShipInfo(guid)
	local max_level = user_info.level--10 + ship_info.ship_break * 10

	local level = ship_info.level
	local old_level = level

	local isLevelUp = false
	ship_info.exp = ship_info.exp + exp

	for i=level,level + 200 do
		if i >= max_level then
			ship_info.level = max_level
			local conf = CONF.SHIPLEVEL.check(max_level)
			ship_info.exp = conf.EXP_ALL
			break
		end
		local conf = CONF.SHIPLEVEL.check(i)
		if not conf then
			return
		end
		if ship_info.exp <= conf.EXP_ALL then
			ship_info.level = i
			break
		end
		isLevelUp = true
	end

	if ship_info.level > max_level then
		local conf = CONF.SHIPLEVEL.get(max_level)
		ship_info.level = max_level
		ship_info.exp = conf.EXP_ALL
	end

	local levelDiff = ship_info.level - level

	if isLevelUp == true then
		Tools._print("test log stat")
		LOG_STAT( string.format( "%s|%s|%d|%d", "SHIP", user_info.user_name, ship_info.id, ship_info.level ) )

		local max_durable = Tools.getMaxDurable(ship_info.id, ship_info.level)
		local diff = max_durable - Tools.getMaxDurable(ship_info.id, old_level)
		ship_info.durable = ship_info.durable + diff
		if ship_info.durable > max_durable then
			ship_info.durable = max_durable
		end

		if user_info then
			local other_user_info = UserInfoCache.get(user_info.user_name)
			if other_user_info then
				if Bit:has(ship_info.status, CONF.EShipState.kLineup) == true then
					local id_lineup, lv_lineup = self:getLineupInfo()
					other_user_info.id_lineup = id_lineup
					other_user_info.lv_lineup = lv_lineup
				end
				other_user_info.power = self:getPowerFromAll()
				UserInfoCache.set(user_info.user_name, other_user_info)
			end
		end

		--更新每日数据
		local daily_data = rawget(user_info, "daily_data")
		if Tools.isEmpty(daily_data) then
			daily_data = {}
		end
		if daily_data.ship_levelup_count == nil then
			daily_data.ship_levelup_count = 0
		end
		daily_data.ship_levelup_count = daily_data.ship_levelup_count + levelDiff
		if user_sync then
			user_sync.user_info = user_sync.user_info or {}
			user_sync.user_info.daily_data = daily_data
		end
		


		--更新活动数据
		if user_sync then
			user_sync.activity_list = user_sync.activity_list or {}
		end
		local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
		if activity_list then
			for i,v in ipairs(activity_list) do
				local count = v.seven_days_data.ship_levelup_count or 0
				v.seven_days_data.ship_levelup_count = count + levelDiff
				table.insert(user_sync.activity_list, v)
			end
		end
	end
	

	return ship_info, levelDiff
end

function ShipList:addLineupExp(exp ,user_sync, lineup)

	local ship_list

	if lineup then
		ship_list = self:getShipByLineup(lineup)
	else
		ship_list = self:getLineup()
	end

	local user_info = self:getUserInfo()

	local isLevelUp = false
	for k,v in ipairs(ship_list) do

		local ship_info, levelDiff = self:addShipExp(v.guid, exp, user_sync)
		if levelDiff and levelDiff > 0 then
			isLevelUp = true
		end
		

		if user_sync then
			if not user_sync.ship_list or Tools.isEmpty(user_sync.ship_list) == true then
				user_sync.ship_list = {}
			end
			table.insert(user_sync.ship_list,ship_info)
		end
	end

	if isLevelUp == true and user_info then
		local other_user_info = UserInfoCache.get(user_info.user_name)
		if other_user_info then
			local id_lineup, lv_lineup = self:getLineupInfo()
			other_user_info.id_lineup = id_lineup
			other_user_info.lv_lineup = lv_lineup
			other_user_info.power = self:getPowerFromAll()
			UserInfoCache.set(user_info.user_name, other_user_info)
		end
	end

	return ship_list
end


function ShipList:subShipDurable(guid, type, result, tech_list, group_tech_list)

	local ship_info = self:getShipInfo(guid)
	if ship_info == nil then
		return nil
	end
	local tech_param = Tools.getValueByTechnologyAddition(1, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_UserInfo.kSubDurable, tech_list, group_tech_list)

	Tools.shipSubDurable( ship_info, type, result, tech_param )

	Tools.shipSubEnergy( ship_info, type, result)
	return ship_info
end

function ShipList:subLineupDurable(type, result, user_sync, lineup, tech_list, group_tech_list)--type:1.pve 2.pvp result: 1.win 0.lose

	local ship_list
	if lineup then
		ship_list = self:getShipByLineup(lineup)
	else
		ship_list = self:getLineup()
	end

	for k,v in ipairs(ship_list) do

		local ship_info = self:subShipDurable(v.guid, type, result, tech_list, group_tech_list)
	
		if user_sync then
			if not user_sync.ship_list or Tools.isEmpty(user_sync.ship_list) == true then
				user_sync.ship_list = {}
			end
			local has = false
			for _,ship_sync in ipairs(user_sync.ship_list) do
				if ship_sync.guid == v.guid then
					has = true
					break
				end
			end
			if has == false then
				table.insert(user_sync.ship_list,ship_info)
			end
		end
	end

	return ship_list
end

function ShipList:changeWeapon(ship_id, weapon_list)
	local ret = 0
	local ship_info = self:getShipInfo(ship_id)
	local user_info = self:getUserInfo()
	if ship_info then

		for i,guid in ipairs(weapon_list) do
			if guid ~= 0 then
				local flag = false
				for _,weapon_info in ipairs(user_info.weapon_list) do

					if weapon_info.guid == guid then
						flag = true
						break
					end
				end
				if flag == false then
					return 3
				end
			end
		end

		ship_info.weapon_list = weapon_list
	else
		ret = 2
	end
	return ret
end

function ShipList:equip(ship_guid, equip_index_list, equip_guid_list, user_sync)

	local user_info = self:getUserInfo()
	local ship_list = self:getShipList()

	local Equip = require "Equip"
	

	local ship_info = self:getShipInfo(ship_guid)
	if ship_info == nil  then
		return 1
	end

	if user_sync and user_sync.ship_list then
		table.insert(user_sync.ship_list,ship_info)
	end

	if Tools.isEmpty(ship_info.equip_list) then
		return 2
	end

	if Tools.isEmpty(equip_index_list) == true or Tools.isEmpty(equip_guid_list) == true then
		return 3
	end
	if #equip_index_list ~= #equip_guid_list then
		return 4
	end

	local function debus( list, index )

		local equip_info = Equip:getEquipInfo(list[index], user_info) 

		if not equip_info then
			return -1
		end

		equip_info.ship_id = 0
		list[index] = 0

		if user_sync and user_sync.equip_list then
			table.insert(user_sync.equip_list,equip_info)
		end

		return 0
	end

	for i=1,#equip_index_list do

		if equip_index_list[i] < 0 or equip_index_list[i] > rawlen(ship_info.equip_list) then
			return 5
		end

		local per_guid = ship_info.equip_list[equip_index_list[i]]

		if per_guid ~= 0  then
			if per_guid == equip_guid_list[i] then
				return 6
			end

			if debus( ship_info.equip_list, equip_index_list[i]) ~= 0 then
				return 7
			end
		end

		if equip_guid_list[i] > 0 then
			local equip_info = Equip:getEquipInfo(equip_guid_list[i], user_info) 
		
			if not equip_info then
				return 8
			end

			if equip_info.ship_id > 0 then
				return 9
			end

			if equip_info.type ~= equip_index_list[i] then
				return 10
			end
		 
			ship_info.equip_list[equip_index_list[i]] = equip_guid_list[i]
			equip_info.ship_id = ship_guid

			if user_sync and user_sync.equip_list then
				table.insert(user_sync.equip_list,equip_info)
			end
		end
	end

	
	return 0
end


function ShipList:getLineup()
	local ship_list = {}
	for k,v in ipairs(self:getShipList()) do
		local ship_info = Tools.clone(v)

		if Bit:has(ship_info.status, CONF.EShipState.kLineup) == true and ship_info.position and ship_info.position > 0 then
			
			--转换guid to weapon id
			if ship_info.weapon_list then
				local weapon_list = {}
				if ship_info.weapon_list ~= nil then

					for kk, guid in ipairs(ship_info.weapon_list) do
						if guid == 0 then
							table.insert(weapon_list, 0)
						else
							table.insert(weapon_list, self:getWeaponId(guid))
						end
					end

				else
					weapon_list = {0, 0, 0,}
				end
				ship_info.weapon_list = weapon_list
				table.insert(ship_list, ship_info)
			end
		end
	end
	return ship_list
end

function ShipList:getLineupInfo( lineup )

	local ship_list
	if lineup then
		ship_list = self:getShipByLineup(lineup)
	else
		ship_list = self:getLineup()
	end

	local id_lineup = {}
	local lv_lineup = {}
	local break_lineup = {}

	for i,v in ipairs(ship_list) do
		if v then
			id_lineup[i] = v.id
			lv_lineup[i] = v.level
			break_lineup[i] = v.ship_break == nil and 0 or v.ship_break
		else
			id_lineup[i] = 0
			lv_lineup[i] = 0
			break_lineup[i] = 0
		end
		
	end
	return id_lineup, lv_lineup, break_lineup
end


function ShipList:getPowerFromLineup( lineup )

	local user_info = self:getUserInfo()

	local ship_list

	if lineup then
		ship_list = self:getShipByLineup(lineup)
	else
		ship_list = self:getLineup()
	end

	local group_main
	local groupid = user_info.group_data.groupid
	if groupid ~= "" and groupid ~= nil then
		group_main = GroupCache.getGroupMain(groupid)
	end

	local cal_ship_list = {}
	for i,v in ipairs(ship_list) do
		cal_ship_list[i] = Tools.calShip( v, user_info, group_main, false)
	end
	
	local power = Tools.calAllFightPower(cal_ship_list, user_info)
	
	return power,ship_list
end

function ShipList:getPowerFromAll()

	local user_info = self:getUserInfo()

	local ship_list = self:getAllFightShip()

	local group_main
	local groupid = user_info.group_data.groupid
	if groupid ~= "" and groupid ~= nil then
		group_main = GroupCache.getGroupMain(groupid)
	end

	local cal_ship_list = {}
	for i,v in ipairs(ship_list) do
		cal_ship_list[i] = Tools.calShip( v, user_info, group_main, false)
	end
	
	local power = Tools.calAllFightPower(cal_ship_list, user_info)

	return power
end

function ShipList:createFightShip( ship )
	local cloneShip = Tools.clone(ship)

	--转换guid to weapon id
	local weapon_list = {}
	for kk, guid in ipairs(cloneShip.weapon_list) do
		table.insert(weapon_list, self:getWeaponId(guid))
	end
	cloneShip.weapon_list = weapon_list

	return cloneShip
end

function ShipList:getAllFightShip()
	local ship_list = {}
	for index,ship in ipairs(self:getShipList()) do
		local cloneShip = self:createFightShip(ship)
		table.insert(ship_list, cloneShip)
	end
	return ship_list
end

function ShipList:getShipByLineup( lineup)

	if lineup == nil then
		return self:getLineup()
	end

	local ship_list = {}

	for i,v in ipairs(lineup) do
		if v > 0 then
			for index,ship in ipairs(self:getShipList()) do
				if ship.guid == v then
					local cloneShip = self:createFightShip(ship)
					cloneShip.position = i
					table.insert(ship_list, cloneShip)
					break
				end
			end
		end
	end
	return ship_list
end

function ShipList:getShipBuff()
	local pb = require "protobuf"
	return  pb.encode("ShipList", self.m_ship_list)
end

function ShipList:getShipInfo(guid)
	local ship_list = self:getShipList()
	local ship_info
	for k,v in ipairs(ship_list) do
		if v.guid == guid then
			ship_info = v
			break
		end
	end
	return ship_info
end

function ShipList:getShipInfoByID(id)
	local ship_list = self:getShipList()
	local ship_info
	for k,v in ipairs(ship_list) do
		if v.id == id then
			ship_info = v
			break
		end
	end
	return ship_info
end

function ShipList:getItemList()
	return self.m_item_list
end

function ShipList:getShipList()
	local ship_list = rawget(self.m_ship_list, "ship_list")
	if Tools.isEmpty(ship_list) then
		ship_list = {}
		rawset(self.m_ship_list, "ship_list", ship_list)
	end
	return ship_list
end

function ShipList:getUserInfo()
	return self.m_user_info
end

function ShipList:getWeaponId(guid)
	local user_info = self:getUserInfo()

	return Tools.getWeaponId( guid, user_info)
end

function ShipList:new(ship_buff , user_name)
	local ship_list
	if ship_buff then
		local pb = require "protobuf"
	 	ship_list = pb.decode("ShipList", ship_buff)
	else
		ship_list = {}
	end

	if not rawget(ship_list, "ship_list") then
		ship_list.ship_list = {}
	end

	
	if user_name then
		Tools._print(user_name,"new m_ship_list count=",#rawget(ship_list, "ship_list"))
		LOG_INFO(user_name.." new m_ship_list count="..#rawget(ship_list, "ship_list"))
		local tmp_ship_list = self:getUserShipList(user_name)
		if tmp_ship_list ~= nil and #ship_list.ship_list < #tmp_ship_list.ship_list then
			Tools._print("ship ShipList:new no count",user_name,#tmp_ship_list.ship_list,#ship_list.ship_list)
			LOG_ERROR("ship ShipList:new no count "..user_name.."   "..#tmp_ship_list.ship_list.."   "..#ship_list.ship_list)
			Tools.print_stack("error","ship ShipList:new no count"..user_name)
			ship_list = tmp_ship_list
		else
			self:setUserShipList(user_name,ship_list)
		end
	end
	
   	self.m_ship_list = ship_list
end

function ShipList:setItemList(item_list)
	self.m_item_list = item_list
end

function ShipList:setUserInfo(user_info)
	self.m_user_info = user_info
end

function ShipList:shipCreate(ship_id, user_sync)
	local item_list = self:getItemList()
	local user_info = self:getUserInfo()

	local ship_info = self:add(ship_id)

	if user_sync then
		user_sync.ship_list = user_sync.ship_list or {}
		table.insert(user_sync.ship_list, ship_info)
	end
	if ship_info then
		LOG_STAT( string.format( "%s|%s|%d|%d", "SHIP", user_info.user_name, ship_info.id, ship_info.level ) )

		local other_user_info = UserInfoCache.get(user_info.user_name)
		if other_user_info then
			local power = self:getPowerFromAll()
			if power ~= other_user_info.power then
				other_user_info.power = power
				UserInfoCache.set(user_info.user_name, other_user_info)
			end
		end
	end

	return ship_info
end

function ShipList:shipRemove(ship_guid,ship_id)
	local item_list = self:getItemList()
	local user_info = self:getUserInfo()
	local ship_list = self:getShipList()

	for k,v in ipairs(ship_list) do
		if v.guid == ship_guid and v.position == 0 then
			table.remove(ship_list,k)
			return 0
		end
	end

	return 1
end

function ShipList:shipBreak(ship_guid, user_sync)

	local item_list = self:getItemList()
	local user_info = self:getUserInfo()
	local ship_list = self:getShipList()

	local ship_info = self:getShipInfo(ship_guid)
	if ship_info == nil  then
		return 1, 0
	end

	local ship_quality = ship_info.quality
	local ship_break_level = ship_info.ship_break
	local gold_level = ship_break_level + 1
	local conf = CONF.SHIP_BREAK.get(ship_quality)

	if gold_level > conf.NUM then
		return 2, 0
	end

	local need_ship_level = conf[string.format("NEED_LEVEL%d", gold_level)]
	if ship_info.level < need_ship_level then
		return 3, 0
	end


	--先检测物品
	local item_id_list = conf[string.format("ITEM_ID%d", gold_level)]
	local item_num_list = conf[string.format("ITEM_NUM%d", gold_level)]
	local items = {}
	for i,v in ipairs(item_id_list) do
		Tools.addNum(v, item_num_list[i], items)
	end

 	local shipConf = CONF.AIRSHIP.get(ship_info.id)
 	
 	if shipConf.BREAK_ISNEED_BLUEPRINT == 1 then
 		local drawingbreakConf = CONF.SHIP_BLUEPRINTBREAK.get(ship_info.quality)
 		local blueprint_id = shipConf.BLUEPRINT[1]
 		local blueprint_num = drawingbreakConf["ITEM_NUM"..gold_level]
 		Tools.addNum(blueprint_id, blueprint_num, items)
 	end

 	if CoreItem.checkItems(items, item_list, user_info) == false then
		return 4, 0
	end


 	--使用物品
 	CoreItem.expendItems(items, item_list, user_info)
 	
 	user_sync = CoreItem.makeSync( items, item_list, user_info)
 	ship_info.ship_break = gold_level

 	if Bit:has(ship_info.status, CONF.EShipState.kLineup) == true then
 		local other_user_info = UserInfoCache.get(user_info.user_name)
		if other_user_info then
			local id_lineup, lv_lineup, break_lineup = self:getLineupInfo()
			other_user_info.id_lineup = id_lineup
			other_user_info.lv_lineup = lv_lineup
			other_user_info.break_lineup = break_lineup
			other_user_info.power = self:getPowerFromAll()
			UserInfoCache.set(user_info.user_name, other_user_info)
		end
 	end

 	if Tools.isEmpty(user_sync.ship_list) then
 		user_sync.ship_list = {}
 	end
 	table.insert(user_sync.ship_list,ship_info)

 	--更新活动数据
	local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
	if activity_list then
		user_sync.activity_list = {}
		for i,v in ipairs(activity_list) do
			local count = v.seven_days_data.ship_break_count or 0
			v.seven_days_data.ship_break_count = count + 1
			table.insert(user_sync.activity_list, v)
		end
	end

	return 0, gold_level, user_sync
end

function ShipList:shipUserItemAddExp( ship_guid, item_id_list, item_num_list )
	local item_list = self:getItemList()
	local user_info = self:getUserInfo()
	local ship_list = self:getShipList()

	if Tools.isEmpty(item_id_list) == true or Tools.isEmpty(item_num_list) == true then
		return 1
	end

	if #item_id_list ~= #item_num_list then
		return 2
	end

	local ship_info = self:getShipInfo(ship_guid)
	if ship_info == nil then
		return 3
	end

	--先检测物品
	local ship_exp = 0

	local items = {}
	for i,v in ipairs(item_id_list) do
		local itemConf = CONF.ITEM.get(v)
		local useConf = CONF.ITEM.get(itemConf.KEY)
		if useConf.TYPE ~= CONF.EItemType.kShipExp then
			return 4
		end
		Tools.addNum(v, item_num_list[i], items)

		ship_exp = ship_exp + item_num_list[i] * itemConf.VALUE
	end
	if CoreItem.checkItems(items, item_list, user_info)  == false then
		return 5
	end

	--使用物品
 	CoreItem.expendItems(items, item_list, user_info)

 	local user_sync = CoreItem.makeSync( items, item_list, user_info)

 	local ship_info = self:addShipExp( ship_guid, ship_exp, user_sync )
 	
 	user_sync.ship_list = {ship_info}

	return 0, user_sync
end

local user_ship_list = {}--临时存放玩家飞船
function ShipList:getUserShipList(user_name)
	local ship_list = user_ship_list[tostring(user_name)]
	if ship_list then
		return Tools.clone(ship_list)
	end
	return nil
end
function ShipList:setUserShipList(user_name , ship_list)
	user_ship_list[tostring(user_name)] = Tools.clone(ship_list)
end

return ShipList
