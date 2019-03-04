local Tools = {}

function Tools.clone(t)
	local dst = {}
	for k,v in pairs(t) do
		if type(v) == "table" then
			dst[k] = Tools.clone(v)
		else
			dst[k] = v
		end
	end
	return dst
end

function Tools.decode(sType, buff)
	local pb = require "protobuf"
	return pb.decode(sType, buff)
end

function Tools.encode(sType, t)
	local pb = require "protobuf"
	return pb.encode(sType, t)
end

function Tools.enum_id(enum_type, enum_name)
	local pb = require "protobuf"
	return pb.enum_id(enum_type, enum_name)
end

function Tools.extract( proto )
	local pb = require "protobuf"
	pb.extract(proto)
end

function Tools.getGuid(list, id)
	id = id or "guid"
	local guid = 0
	if list ~= nil then
		for k,v in ipairs(list) do
			if guid < v[id] then
				guid = v[id]
			end
		end
	end
	return guid + 1
end

function Tools.getHex(sHex)
	local ss = {}
	local len = sHex and string.len(sHex) or 0
	for i = 1, len-1, 2 do
		local cc = string.sub(sHex, i, i+1)
		local n = tonumber(cc, 16)
		if n == 0 then
			ss[#ss+1] = '\00';
		else
			ss[#ss+1] = string.format("%c", n);
		end
	end
	return table.concat(ss)
end

function Tools.isEmpty(t)
	local isEmpty = t == nil or next(t) == nil
	if not isEmpty then
		local s = next(t)
		if string.len(s) > 0 and string.sub(s, 1, 1) == "_" then
			isEmpty = true
		end
	end
	return isEmpty
end

function Tools.newValues(value, size)
	local t = {}
	for i = 1, size do
		if type(value) == "table" then
			t[i] = Tools.clone(value)
		else
			t[i] = value
		end
	end
	return t
end

IS_PRINT_INFO = true
function Tools._print(...)
	if IS_PRINT_INFO then
		print(...)
	end
end
function Tools.print_t(...)
	if not IS_PRINT_INFO then
		return
	end
	for k,v in ipairs{...} do
		if type(v) == "table" then
			io.write(Tools.toString(v))
		else
			io.write(tostring(v))
		end
		io.write(" ")
	end
	io.write("\n")
end

function Tools.log_error_t( ... )
	for k,v in ipairs{...} do
		if type(v) == "table" then
			LOG_ERROR(Tools.toString(v))
		else
			LOG_ERROR(tostring(v))
		end
		LOG_ERROR("\n")
	end
	LOG_ERROR("\n\n\n\n\n")
end

local _trace = debug.traceback 
local _t_concat = table.concat 
local _log = print 
function Tools.print_stack(logtype, ...) 
    local out = {'[TRACE]'} 
    local n = select('#', ...) 
    for i=1, n, 1 do 
        local v = select(i,...) 
        out[#out+1] = tostring(v) 
    end 
    out[#out+1] = '\n' 
    out[#out+1] = _trace("", 2) 
    _log(_t_concat(out,' ')) 
    if logtype == "error" then
    	LOG_ERROR(_t_concat(out,' '))
    elseif logtype == "info" then
    	LOG_INFO(_t_concat(out,' '))
    end
end

function Tools.toHex(sData)
	local ss = {}
	local len = sData and string.len(sData) or 0
	for i = 1, len do
		ss[i] = string.format("%02x", string.byte(string.sub(sData, i, i)))
	end
	return table.concat(ss)
end

function Tools.toString(t, depth)
	depth = depth or 0
	local s
	local tt = {}
	if depth > 0 then
		s = string.rep("\t", depth)
	else
		s = ""
		tt[#tt+1] = ""
	end
	if type(t) == "table" then
		for k, v in pairs(t) do
			if type(v) == "table" and next(v) then
				tt[#tt+1] = string.format("%s%s->%s", s, k, tostring(v))
				if string.len(k) == 0 or string.len(k) > 0 and string.sub(k, 1, 1) ~= "_" then
					tt[#tt+1] = Tools.toString(v, depth+1)
				end
			else
				tt[#tt+1] = string.format("%s%s->%s", s, k, tostring(v))
			end
		end
	end
	return table.concat(tt, "\n")
end

function Tools.getWeaponId( guid, user_info)
	if Tools.isEmpty(user_info.weapon_list) == true then
		return 0
	end
	local weapon_id = 0
	for k,weapon_info in ipairs(user_info.weapon_list) do
		if weapon_info.guid == guid then
			weapon_id = weapon_info.weapon_id
			break
		end
	end
	return weapon_id
end

function Tools.getEnergyAddition( ship_id, energy_level, attr_type)
	if ship_id == nil then
		return 0
	end
	if energy_level == nil or energy_level < 1 then
		return 0
	end
	local conf = CONF.AIRSHIP.get(ship_id)
	if not conf then
		return 0
	end

	local org
	if attr_type == CONF.ShipGrowthAttrs.kHP then
		org = conf.LIFE
	elseif attr_type == CONF.ShipGrowthAttrs.kAttack then
		org = conf.ATTACK
	elseif attr_type == CONF.ShipGrowthAttrs.kDefence then
		org = conf.DEFENCE
	elseif attr_type == CONF.ShipGrowthAttrs.kSpeed then
		org = conf.SPEED
	elseif attr_type == CONF.ShipGrowthAttrs.kHit then
		org = conf.PROBABILITY_HIT
	elseif attr_type == CONF.ShipGrowthAttrs.kDodge then
		org = conf.PROBABILITY_DODGE
	elseif attr_type == CONF.ShipGrowthAttrs.kCrit then
		org = conf.PROBABILITY_CRIT
	elseif attr_type == CONF.ShipGrowthAttrs.kAnticrit then
		org = conf.PROBABILITY_ANTICRIT
	elseif attr_type == CONF.ShipGrowthAttrs.kEnergyAttack then
		org = conf.ENERGY_ATTACK
	elseif attr_type == 99 then
		org = conf.LOAD
	end

	return math.floor(org * CONF.PARAM.get("energy_attr_param").PARAM * energy_level)
end

function Tools.calShipFightPower(ship_info, weapon_id_list)

	local attr = ship_info.attr

	local value = attr[CONF.EShipAttr.kHP] * CONF.PARAM.get("fight_power_hp").PARAM
	+ attr[CONF.EShipAttr.kAttack] *  (1 + attr[CONF.EShipAttr.kHurtAddition]*0.01) * CONF.PARAM.get("fight_power_attack").PARAM
	+ attr[CONF.EShipAttr.kEnergyAttack]  *  (1 + attr[CONF.EShipAttr.kHurtAddition]*0.01) * CONF.PARAM.get("fight_power_energy_attack").PARAM
	+ attr[CONF.EShipAttr.kDefence] * (1 + attr[CONF.EShipAttr.kHurtSubtration]*0.01) * CONF.PARAM.get("fight_power_defence").PARAM
	+ attr[CONF.EShipAttr.kSpeed] * CONF.PARAM.get("fight_power_speed").PARAM
	+ attr[CONF.EShipAttr.kHit] * (1 + attr[CONF.EShipAttr.kFinalProbabilityHit]*0.01) * CONF.PARAM.get("fight_power_hit").PARAM
	+ attr[CONF.EShipAttr.kDodge] * (1 + attr[CONF.EShipAttr.kFinalProbabilityDodge]*0.01) * CONF.PARAM.get("fight_power_dodge").PARAM
	+ attr[CONF.EShipAttr.kCrit] * (1 + attr[CONF.EShipAttr.kFinalProbabilityCrit]*0.01) * CONF.PARAM.get("fight_power_crit").PARAM
	+ attr[CONF.EShipAttr.kAnticrit] * (1 + attr[CONF.EShipAttr.kFinalProbabilityAnticrit]*0.01) * CONF.PARAM.get("fight_power_anticrit").PARAM

	if Tools.isEmpty(weapon_id_list) == false then
		for i,v in ipairs(weapon_id_list) do
			if v ~= 0 then
				local conf = CONF.WEAPON.get(v)
				value = value + conf.FIGHT_POWER
			end
		end
	end

	return math.floor(value)
end

function Tools.calTechPower( user_info )
	local value = 0
	if Tools.isEmpty(user_info.tech_data) == true then
		return value
	end
	if Tools.isEmpty(user_info.tech_data.tech_info) == true then
		return value
	end
	for i,v in ipairs(user_info.tech_data.tech_info) do

		local conf = CONF.TECHNOLOGY.check(v.tech_id)
		if conf then
			value = value + conf.FIGHT_POWER
		end
	end
	return value
end

function Tools.calAllFightPower( ships, user_info ) --默认ship 里面的weapon list是 weapon_id_list
	local value = 0

	for i,ship_info in ipairs(ships) do
		value = value + Tools.calShipFightPower(ship_info, ship_info.weapon_list)
	end

	for i,v in ipairs(user_info.building_list) do

		if CONF[string.format("BUILDING_%d",i)] then
			local conf = CONF[string.format("BUILDING_%d",i)].check(v.level)
			if conf then
				value = value + conf.FIGHT_POWER
			end
		end
	end

	value = value + Tools.calTechPower( user_info )

	if Tools.isEmpty(user_info.home_info) == false then
		if Tools.isEmpty(user_info.home_info.land_info) == false then
			for i,v in ipairs(user_info.home_info.land_info) do
				local conf = CONF.RESOURCE.check(v.resource_type)
				if conf then
					value = value + conf.FIGHT_POWER
				end
			end
		end
	end
	return math.floor(value)
end

function Tools.calEquip( tempEquip )
	local equip = Tools.clone(tempEquip)

	for i,key in ipairs(equip.attributes_base) do

		equip.attributes_base[i] = math.floor(equip.attributes_base[i] + equip.strength * equip.attributes_base[i] * CONF.PARAM.get("equip_strength").PARAM)
	end
	
	return equip
end



function Tools.calShip( ship_info, user_info, group_main, isFight, addition_tech_list)

	local function calLevel( cal_ship )

		for i,key in pairs(CONF.ShipGrowthAttrs) do
			cal_ship.attr[key] = math.floor(cal_ship.attr[key] + (cal_ship.level - 1) * cal_ship.attr[key] * CONF.PARAM.get("ship_level").PARAM)
		end
		cal_ship.load = math.floor(cal_ship.load + (cal_ship.level - 1) * cal_ship.load * CONF.PARAM.get("ship_level").PARAM)
	end

	local function calEnergyAttr( cal_ship )
		if cal_ship.energy_level ~= nil then
			for i,key in pairs(CONF.ShipGrowthAttrs) do
				cal_ship.attr[key] = cal_ship.attr[key] + Tools.getEnergyAddition( cal_ship.id, cal_ship.energy_level, key)
			end
			cal_ship.load = cal_ship.load + Tools.getEnergyAddition( cal_ship.id, cal_ship.energy_level, 99)
		end		
	end

	local function calBreak( cal_ship )

		if cal_ship.ship_break and cal_ship.ship_break > 0 then
			for i,key in pairs(CONF.ShipGrowthAttrs) do

				cal_ship.attr[key] = math.floor(cal_ship.attr[key] * CONF.PARAM.get(string.format("ship_break_%d",cal_ship.ship_break)).PARAM)
			end
			cal_ship.load = math.floor(cal_ship.load * CONF.PARAM.get(string.format("ship_break_%d",cal_ship.ship_break)).PARAM)
		end
	end


	local function getEquipsByGuids( equip_guid_list, equip_list)

		if equip_list == nil then
			return nil
		end

		local guids = Tools.clone(equip_guid_list)

		local list = {}

		for i,v in ipairs(equip_list) do

			for j,w in ipairs(guids) do
				if v.guid == w then

					table.insert(list, v)
					table.remove(guids,j)
					break
				end
			end
		end

		if Tools.isEmpty(list) then
			return nil
		end

		return list
	end 


	local function calAttr(cal_ship, add_list)

		for key = 1, #add_list do
			cal_ship.attr[key] = math.floor(cal_ship.attr[key] + add_list[key])	
		end
	end

	local function calEquip( cal_ship )

		local equips = getEquipsByGuids(cal_ship.equip_list, user_info.equip_list)


		if not equips then
			return
		end
		for i,v in ipairs(equips) do

			local temp = Tools.calEquip(v)

			calAttr(cal_ship, temp.attributes_base)
		end
	end

	local function calArenaTitle(cal_ship)
		if user_info.arena_data == nil then
			return
		end
		local conf = CONF.ARENATITLE.check(user_info.arena_data.title_level)
		if not conf then
			return
		end
		for i,key in ipairs(conf.ATTR_KEY) do
			cal_ship.attr[key] = cal_ship.attr[key] + conf.ATTR_VALUE[i]
		end
	end

	local function calGem( cal_ship )
		if Tools.isEmpty(cal_ship.gem_list) == false then
			for i,gem_id in ipairs(cal_ship.gem_list) do
				if gem_id > 0 then
					local conf = CONF.GEM.get(gem_id)
					cal_ship.attr[conf.ATTR_KEY] = cal_ship.attr[conf.ATTR_KEY] + conf.ATTR_VALUE
				end
			end
		end
	end

	local function calTech( cal_ship, user_info, group_main, isFight, addition_tech_list)

		local additions = {}

		if Tools.isEmpty(addition_tech_list) == false then
			for i,tech_id in ipairs(addition_tech_list) do
				local conf = CONF.TECHNOLOGY.get(tech_id)

				if conf.TECHNOLOGY_TARGET_1 == CONF.ETechTarget_1.kShipAttr then

					local key = conf.TECHNOLOGY_TARGET_3

					if additions[key] then
						additions[key].per = additions[key].per + conf.TECHNOLOGY_ATTR_PERCENT
						additions[key].val = additions[key].val + conf.TECHNOLOGY_ATTR_VALUE
					else
						additions[key] = {
							val = conf.TECHNOLOGY_ATTR_VALUE,
							per = conf.TECHNOLOGY_ATTR_PERCENT,
						}
					end
				end
			end
			
		end

		if user_info.tech_data and Tools.isEmpty(user_info.tech_data.tech_info) == false then
			
			for i,m in ipairs(user_info.tech_data.tech_info) do

				if m.begin_upgrade_time == 0 then

					local conf = CONF.TECHNOLOGY.get(m.tech_id)

					if conf.TECHNOLOGY_TARGET_1 == CONF.ETechTarget_1.kShipAttr then

						local key = conf.TECHNOLOGY_TARGET_3

						if additions[key] then
							additions[key].per = additions[key].per + conf.TECHNOLOGY_ATTR_PERCENT
							additions[key].val = additions[key].val + conf.TECHNOLOGY_ATTR_VALUE
						else
							additions[key] = {
								val = conf.TECHNOLOGY_ATTR_VALUE,
								per = conf.TECHNOLOGY_ATTR_PERCENT,
							}
						end
					end
				end
			end
		end

		if group_main and Tools.isEmpty(group_main.tech_list) == false then
	
			for i,m in ipairs(group_main.tech_list) do

				if m.status == 3 then

					local conf = CONF.GROUP_TECH.get(m.tech_id)

					local flag = false

					if conf.TECHNOLOGY_TARGET_1 == CONF.ETechTarget_1.kShipAttr then
						flag = true
					end

					if isFight and isFight == true then
						if conf.TECHNOLOGY_TARGET_1 == CONF.ETechTarget_1.kFightShipAttr then
							flag = true
						end
					end

					if flag == true then

						local key = conf.TECHNOLOGY_TARGET_3

						if additions[key] then
							additions[key].per = additions[key].per + conf.TECHNOLOGY_ATTR_PERCENT
							additions[key].val = additions[key].val + conf.TECHNOLOGY_ATTR_VALUE
						else
							additions[key] = {
								val = conf.TECHNOLOGY_ATTR_VALUE,
								per = conf.TECHNOLOGY_ATTR_PERCENT,
							}
						end
					end
				end
			end
		
		end

	
		for key,v in pairs(additions) do
			if cal_ship.attr[key] ~= nil then
				cal_ship.attr[key] = cal_ship.attr[key] + cal_ship.attr[key] * v.per * 0.01 + v.val
			end
		end
	end

	local function calRateAttr( cal_ship )
		cal_ship.attr[CONF.EShipAttr.kHP] = cal_ship.attr[CONF.EShipAttr.kHP] + math.floor(cal_ship.attr[CONF.EShipAttr.kHP] * 0.01 * cal_ship.attr[CONF.EShipAttr.kLifeRate])
		cal_ship.attr[CONF.EShipAttr.kAttack] = cal_ship.attr[CONF.EShipAttr.kAttack] + math.floor(cal_ship.attr[CONF.EShipAttr.kAttack] * 0.01 * cal_ship.attr[CONF.EShipAttr.kAttackRate])
		cal_ship.attr[CONF.EShipAttr.kEnergyAttack] = cal_ship.attr[CONF.EShipAttr.kEnergyAttack] + math.floor(cal_ship.attr[CONF.EShipAttr.kEnergyAttack] * 0.01 * cal_ship.attr[CONF.EShipAttr.kEnergyAttackRate])
		cal_ship.attr[CONF.EShipAttr.kDefence] = cal_ship.attr[CONF.EShipAttr.kDefence] + math.floor(cal_ship.attr[CONF.EShipAttr.kDefence] * 0.01 * cal_ship.attr[CONF.EShipAttr.kDefenceRate])
	end

	if true then
		local conf = CONF.AIRSHIP.get(ship_info.id)
		if conf then
			ship_info.load = conf.LOAD
		end
	end

	local cal_ship = Tools.clone(ship_info)

	calLevel(cal_ship)

	calBreak(cal_ship)

	calTech(cal_ship, user_info, group_main, isFight, addition_tech_list)

	calEquip(cal_ship)

	calArenaTitle(cal_ship)

	calGem(cal_ship)

	calRateAttr(cal_ship)

	calEnergyAttr( cal_ship )

	return cal_ship
end

function Tools.GetAllShipLoad(ship_list)
	local num = 0
	if Tools.isEmpty(ship_list) then
		return num
	end
	for i,v in ipairs(ship_list) do		
		num = num + v.load
	end
	return num
end

function Tools.split(str, reps)  
	local resultStrsList = {}
	string.gsub(str, '[^' .. reps ..']+', function(w) table.insert(resultStrsList, w) end )
	return resultStrsList
end  

function Tools.mod(a, n)
	local m = a % n
	return m > 0 and m or n
end

function Tools.decode_event_list( list )

	local function decode_proto_table( pt )
		local t = {}
		local i = 0
		for k,v in pairs(pt) do

			i = i + 1
			t[i] = Tools.decode(v[1],v[2])
		end
		return t
	end

	local t = {}
	local i = 0
	for k,v in pairs(list) do

		i = i + 1
		t[i] = Tools.decode(v[1],v[2])

		t[i].attack_list = decode_proto_table(t[i].attack_list)
		t[i].hurter_list = decode_proto_table(t[i].hurter_list)
	end

	return t
end

function Tools.getValueByTechnologyAddition( value, tech_1, tech_2, tech_3, tech_list, group_tech_list ,other_tech_list)
	if tech_list == nil and group_tech_list == nil then
		return 0
	end
	local percent = 0
	local num = 0
	if tech_list then
		for k,m in ipairs(tech_list) do
			if m.begin_upgrade_time == 0 then
				local conf = CONF.TECHNOLOGY.check(m.tech_id)
				if conf then
					if conf.TECHNOLOGY_TARGET_1 == tech_1 
					and (conf.TECHNOLOGY_TARGET_2 == tech_2 or conf.TECHNOLOGY_TARGET_2 == 0)
					and conf.TECHNOLOGY_TARGET_3 == tech_3 then
						 percent = percent + conf.TECHNOLOGY_ATTR_PERCENT
						 num = num + conf.TECHNOLOGY_ATTR_VALUE
					end
				else
					LOG_ERROR("Tools.getValueByTechnologyAddition no tech_list ID",m.tech_id)
				end
			end
		end
	end

	if group_tech_list then
		for k,m in ipairs(group_tech_list) do
			if m.status == 3 then
				local conf = CONF.GROUP_TECH.check(m.tech_id)
				if conf then
					if conf.TECHNOLOGY_TARGET_1 == tech_1 
					and (conf.TECHNOLOGY_TARGET_2 == tech_2 or conf.TECHNOLOGY_TARGET_2 == 0)
					and conf.TECHNOLOGY_TARGET_3 == tech_3 then
						 percent = percent + conf.TECHNOLOGY_ATTR_PERCENT
						 num = num + conf.TECHNOLOGY_ATTR_VALUE
					end
				else
					LOG_ERROR("Tools.getValueByTechnologyAddition no group_tech_list ID",m.tech_id)
				end
			end
		end
	end

	if other_tech_list then
		for k,m in ipairs(other_tech_list) do
			local conf = CONF.GROUP_TECH.check(m)
			if conf then
				if conf.TECHNOLOGY_TARGET_1 == tech_1 
				and (conf.TECHNOLOGY_TARGET_2 == tech_2 or conf.TECHNOLOGY_TARGET_2 == 0)
				and conf.TECHNOLOGY_TARGET_3 == tech_3 then
					 percent = percent + conf.TECHNOLOGY_ATTR_PERCENT
					 num = num + conf.TECHNOLOGY_ATTR_VALUE
				end
			else
				LOG_ERROR("Tools.getValueByTechnologyAddition no other_tech_list ID",m)
			end
		end
	end

	local sign = 1
	if tech_1 == CONF.ETechTarget_1.kBuilding or tech_1 == CONF.ETechTarget_1.kTechnology then
		sign = -1
	end
	--Tools._print("percent",value,percent)
	return math.ceil( value * 0.01 * percent * sign + num * sign ) 
end

function Tools.getSpeedUpNeedMoney(second)
	
	return math.ceil(CONF.PARAM.get("kill_cd").PARAM * second + 1)
end

function Tools.getSpeedShipNeedMoney(second)
	
	return math.ceil(CONF.PARAM.get("ship_cd").PARAM * second + 1)
end

function Tools.getSpeedEnergyMoney(second)
	return math.ceil(CONF.PARAM.get("energy_cd").PARAM * second + 1)
end

function Tools.calArenaUpdateMoney(times)

	return  CONF.PARAM.get("arena_update_param_1").PARAM
end

function Tools.calAddArenaTimesNeedMoney( purchased_challenge_times )
	local value = purchased_challenge_times or 0
	return CONF.PARAM.get("arena_update_param_2").PARAM * (value + 1)
end

function Tools.calTask( taskConf, user_info, ship_list, planet_user, activity )
	if taskConf == nil then
		return false
	end

	if taskConf.TYPE == 4 then--活动数据
		if activity == nil then
			print("activity == nil")
			return false
		end
		local seven_days_data = activity.seven_days_data
		if Tools.isEmpty(seven_days_data) == true then
			print("seven_days_data is nil")
			return false,0,0
		end
		

		if taskConf.TARGET_1 == CONF.ETaskTarget_1.kCheckpoint then

			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Checkpoint.kPass then
				if Tools.isEmpty(seven_days_data.level_info) == false then

					for i,level_info in ipairs(seven_days_data.level_info) do
						local value = level_info.level_star
						if taskConf.VALUES[2] == 1 then
							if value > taskConf.VALUES[2] then
								value = taskConf.VALUES[2]
							end
						end
						if level_info.level_id == taskConf.VALUES[1] then

							return value >= taskConf.VALUES[2], value, taskConf.VALUES[2]
						end
					end
				end
				return false, 0, taskConf.VALUES[2]
			end
		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kWeapon then
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Weapon.kLevelUpCount then
				local count = seven_days_data.weapon_levelup_count or 0
				return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]
			end
		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kTechnology then
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Technology.kLevelUpCount then
				local count = seven_days_data.technology_levelup_count or 0
				return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]
			end

		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kBuilding then
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Building.kLevelUpCount then
				local count = seven_days_data.building_levelup_count or 0
				return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Building.kAllLevelUpCount then
				local count = seven_days_data.building_levelup_count or 0
				count = count + (seven_days_data.home_levelup_count or 0)
				return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]
			end
		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kHome then
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Building.kLevelUpCount then

				local count = seven_days_data.home_levelup_count or 0
				
				return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]
			end
		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kShip then

			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kLevelUpCount 
			or taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kEquipLevelUpCount
			or taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kBreakCount then

				local count
				if taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kLevelUpCount then
					count = seven_days_data.ship_levelup_count or 0
				elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kEquipLevelUpCount then
					count = seven_days_data.equip_strength_count or 0
				elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kBreakCount then
					count = seven_days_data.ship_break_count or 0
				end
				
				if not count then
					return false
				end
		
				return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]
			end
		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kArena then
			local count 
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Arena.kChallengeCount then
				count = seven_days_data.already_challenge_times or 0
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Arena.kWinCount then
				count = seven_days_data.win_challenge_times or 0
			end
			if not count then
				return false
			end

			return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]

		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kGroup then
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Group.kContributeCount then

				local count = seven_days_data.contribute_times or 0

				return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]
			end
		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kRecharge then
			local count
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Recharge.kRechargeCount then
				count = seven_days_data.recharge_money or 0
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Recharge.kConsumeCount then
				count = seven_days_data.consume_money or 0
			end
			if not count then
				return false
			end

			return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]

		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kSignIn then

			local count = seven_days_data.sign_in_days or 0

			return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]
		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kTrial then

			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Trial.kPass then
				if Tools.isEmpty(seven_days_data.trial_level_list) == false then

					for i,level_info in ipairs(seven_days_data.trial_level_list) do

						if level_info.level_id == taskConf.VALUES[1] then
							local value = level_info.star
							if taskConf.VALUES[2] == 1 then
								if value > taskConf.VALUES[2] then
									value = taskConf.VALUES[2]
								end
							end
							return value >= taskConf.VALUES[2], value, taskConf.VALUES[2]
						end
					end
				end
				return false, 0, taskConf.VALUES[2]
			end

		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kLottery then

			local count
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Lottery.kAllLotteryCount then

				count = seven_days_data.lottery_count or 0

			elseif  taskConf.TARGET_2 == CONF.ETaskTarget_2_Lottery.kMoneyLotteryCount then

				count = seven_days_data.money_lottery_count or 0
			end
			return count >= taskConf.VALUES[1], count, taskConf.VALUES[1]
		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kPlanet then

			if not planet_user or not planet_user.seven_days_data then
				return false, 0, taskConf.VALUES[1]
			end

			local count
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kAttackMonsterTimes then
				count = planet_user.seven_days_data.attack_monster_times or 0
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kBaseAttackTimes then
				count = planet_user.seven_days_data.base_attack_times or 0		
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kLevelCollectTimesDay then
				count = planet_user.seven_days_data.colloct_level_times_list_day or 0				
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kLevelRuinsTimesDay then
				count = planet_user.seven_days_data.ruins_level_times_list_day or 0
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kLevelFishingTimesDay then
				count = planet_user.seven_days_data.fishing_level_times_list_day or 0
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kBossTimesDay then
				count = planet_user.seven_days_data.boss_level_times_list_day or 0
			end
			
			if not count then
				return false, 0, taskConf.VALUES[1]
			end

			if count < taskConf.VALUES[1] then
				return false, count, taskConf.VALUES[1]
			else
				return true, count, taskConf.VALUES[1]
			end
		elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kBlueprint then


		end


		return false,0,0
	end


	if taskConf.TARGET_1 == CONF.ETaskTarget_1.kCheckpoint then

		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Checkpoint.kPass then

			if user_info.stage_data and user_info.stage_data.level_info then

				for i,level_info in ipairs(user_info.stage_data.level_info) do

					if level_info.level_id == taskConf.VALUES[1] then

						local value = level_info.level_star
						if taskConf.VALUES[2] == 1 then
							if value > taskConf.VALUES[2] then
								value = taskConf.VALUES[2]
							end
						end
						if  level_info.level_star >= taskConf.VALUES[2] then

							return true, value, taskConf.VALUES[2]
						else
							return false, value, taskConf.VALUES[2]
						end
					end
				end
			end
			return false,0,taskConf.VALUES[2]

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Checkpoint.kFight or taskConf.TARGET_2 == CONF.ETaskTarget_2_Checkpoint.kWin then

			if not user_info.daily_data then
				return false, 0, taskConf.VALUES[1]
			end

			local count
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Checkpoint.kFight then
				count = user_info.daily_data.checkpoint_fight or 0
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Checkpoint.kWin then
				count = user_info.daily_data.checkpoint_win or 0
			end
			
			if not count then
				return false, 0, taskConf.VALUES[1]
			end

			if count < taskConf.VALUES[1] then
				return false, count, taskConf.VALUES[1]
			else
				return true, count, taskConf.VALUES[1]
			end
		end

	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kBuilding then

		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Building.kLevelUpCount then

			if Tools.isEmpty(user_info.building_list) == true then
				return false, 0, taskConf.VALUES[1]
			end

			local count = 0
			for i,v in ipairs(user_info.building_list) do
				count = count + v.level - 1
			end

			if count < taskConf.VALUES[1] then
				return false, count, taskConf.VALUES[1]
			else
				return true, count, taskConf.VALUES[1]
			end

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Building.kLevelCount then

			if Tools.isEmpty(user_info.building_list) == true then
				return false, 0, taskConf.VALUES[2]
			end

			local count = 0
			for i,v in ipairs(user_info.building_list) do
				if v.level >= taskConf.VALUES[1] then
					count = count + 1
				end
			end

			if count < taskConf.VALUES[2] then
				return false, count, taskConf.VALUES[2]
			else
				return true, count, taskConf.VALUES[2]
			end

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Building.kLevelID then

			if Tools.isEmpty(user_info.building_list) == true then
				return false, 0, taskConf.VALUES[2]
			end

			local building_info = user_info.building_list[taskConf.VALUES[1]]
			if not building_info then
				return false
			end

			if building_info.level < taskConf.VALUES[2] then
				return false, building_info.level, taskConf.VALUES[2]
			else
				return true, building_info.level, taskConf.VALUES[2]
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Building.kActivation then
			--user_info.achievement_data.guide_list[taskConf.VALUES[1]]
			local icon_open = false
			for i,v in ipairs(CONF.OPEN_ICON.getIDList()) do
				local conf = CONF.OPEN_ICON.get(v)
				if conf.CONDITION == 4 then
					local id = math.floor( conf.COUNT/100)
					if user_info.achievement_data.guide_list[id] ~= nil then
						for k1,v1 in ipairs(conf.BUILDING) do
							if (v1-100) == taskConf.VALUES[1] then
								icon_open = true
								break
							end
						end
					end
				end
				if icon_open then
					break
				end
			end
			return icon_open , icon_open and 1 or 0 , taskConf.VALUES[2]
		end
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kHome then

		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Building.kLevelUpCount then

			if Tools.isEmpty(user_info.home_info) == true then
				return false, 0, taskConf.VALUES[1]
			end

			local count = 0
			if Tools.isEmpty(user_info.home_info.land_info) == false then
				for i,v in ipairs(user_info.home_info.land_info) do
					count = count + v.resource_level - 1
				end
			end

			if count < taskConf.VALUES[1] then
				return false, count, taskConf.VALUES[1]
			else
				return true, count, taskConf.VALUES[1]
			end

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Building.kLevelCount then

			if Tools.isEmpty(user_info.home_info) == true then
				return false, 0, taskConf.VALUES[2]
			end

			local count = 0
			if Tools.isEmpty(user_info.home_info.land_info) == false then
				for i,v in ipairs(user_info.home_info.land_info) do
					if v.resource_level >= taskConf.VALUES[1] then
						count = count + 1
					end
				end
			end
			if count < taskConf.VALUES[2] then
				return false, count, taskConf.VALUES[2]
			else
				return true, count, taskConf.VALUES[2]
			end

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Building.kLevelID then

			if Tools.isEmpty(user_info.home_info) == true then
				return false, 0, taskConf.VALUES[2]
			end

			local maxLevel = 0
			local flag = false
			if Tools.isEmpty(user_info.home_info.land_info) == false then

				for i,land_info in ipairs(user_info.home_info.land_info) do

					local resConf = CONF.RESOURCE.get(land_info.resource_type)

					if resConf.TYPE == taskConf.VALUES[1] then
						if land_info.resource_level > maxLevel then
							maxLevel = land_info.resource_level
						end
						if land_info.resource_level >= taskConf.VALUES[2] then
							flag = true
						end
					end 
				end
			end

			return flag, maxLevel, taskConf.VALUES[2]
		end

	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kUser then

		if taskConf.TARGET_2 == CONF.ETaskTarget_2_User.kLevel then

			return user_info.level >= taskConf.VALUES[1], user_info.level, taskConf.VALUES[1]

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_User.kBuyStrengthTimes then

			return user_info.strength_buy_times >= taskConf.VALUES[1], user_info.strength_buy_times, taskConf.VALUES[1]
		end

	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kShip then

		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kLevelUpCount 
		or taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kEquipLevelUpCount
		or taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kBreakCount then

			if not user_info.daily_data then
				return false, 0, taskConf.VALUES[1]
			end

			local count
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kLevelUpCount then
				count = user_info.daily_data.ship_levelup_count or 0
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kEquipLevelUpCount then
				count = user_info.daily_data.equip_strength_count or 0
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kBreakCount then
				count = user_info.daily_data.ship_break_count or 0
			end
			
			if not count then
				return false, 0, taskConf.VALUES[1]
			end

			if count < taskConf.VALUES[1] then
				return false, count, taskConf.VALUES[1]
			else
				return true, count, taskConf.VALUES[1]
			end

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kGetID then

			if not ship_list then
				return false
			end

			for i,v in ipairs(ship_list) do
				if v.id == taskConf.VALUES[1] then
					return true, 1, 1
				end
			end
			return false, 0, 1

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kQualityCount then

			if not ship_list then
				return false, 0, taskConf.VALUES[2]
			end

			local count = 0
			for i,v in ipairs(ship_list) do
				if v.quality == taskConf.VALUES[1] then
					count = count + 1
				end
			end

			if count < taskConf.VALUES[2] then
				return false, count, taskConf.VALUES[2]
			else
				return true, count, taskConf.VALUES[2]
			end

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kLevelCount then

			if not ship_list then
				return false, 0, taskConf.VALUES[2]
			end

			local count = 0
			for i,v in ipairs(ship_list) do
				if v.level >= taskConf.VALUES[1] then
					count = count + 1
				end
			end

			if count < taskConf.VALUES[2] then
				return false, count, taskConf.VALUES[2]
			else
				return true, count, taskConf.VALUES[2]
			end

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kPowerCount then

			if not ship_list then
				return false, 0, taskConf.VALUES[2]
			end

			local count = 0
			for i,v in ipairs(ship_list) do

				local ship_info = Tools.calShip(v, user_info)
				local weapon_id_list = {}
				for i,guid in ipairs(ship_info.weapon_list) do
					table.insert(weapon_id_list, Tools.getWeaponId( guid, user_info))
				end
				local power = Tools.calShipFightPower(ship_info, weapon_id_list)

				if power >= taskConf.VALUES[1] then
					count = count + 1
				end
			end

			if count < taskConf.VALUES[2] then
				return false, count, taskConf.VALUES[2]
			else
				return true, count, taskConf.VALUES[2]
			end

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Ship.kAllShipPower then

			if not ship_list then
				return false, 0, taskConf.VALUES[1]
			end

			local power = 0
			for i,v in ipairs(ship_list) do

				local ship_info = Tools.calShip(v, user_info)
				local weapon_id_list = {}
				for i,guid in ipairs(ship_info.weapon_list) do
					table.insert(weapon_id_list, Tools.getWeaponId( guid, user_info))
				end
				power = power + Tools.calShipFightPower(ship_info, weapon_id_list)
			end
			
			return power > taskConf.VALUES[1], power, taskConf.VALUES[1]
		end

	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kArena then

		if not user_info.arena_data then
			return false, 0, taskConf.VALUES[1]
		end

		local count 
		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Arena.kChallengeCount then
			count = user_info.arena_data.already_challenge_times or 0
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Arena.kWinCount then
			count = user_info.arena_data.win_challenge_times or 0
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Arena.kTitleLevel then
			count = user_info.arena_data.title_level or 0
		end

		if count < taskConf.VALUES[1] then
			return false, count, taskConf.VALUES[1]
		else
			return true, count, taskConf.VALUES[1]
		end
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kGroup then
		
		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Group.kContributeCount then
			if not user_info.achievement_data then
				return false, 0, taskConf.VALUES[1]
			end
			if user_info.achievement_data.contribute_times == nil then
				return false
			end

			return user_info.achievement_data.contribute_times >= taskConf.VALUES[1], user_info.achievement_data.contribute_times, taskConf.VALUES[1]

		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Group.kDailyContributeCount or taskConf.TARGET_2 == CONF.ETaskTarget_2_Group.kDailyBossTimes then
			if not user_info.daily_data then
				return false, 0, taskConf.VALUES[1]
			end

			local count
			if taskConf.TARGET_2 == CONF.ETaskTarget_2_Group.kDailyContributeCount then
				count = user_info.daily_data.contribute_times or 0
			elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Group.kDailyBossTimes then
				count = user_info.daily_data.group_boss_times or 0
			end
			
			if not count then
				return false, 0, taskConf.VALUES[1]
			end

			if count < taskConf.VALUES[1] then
				return false, count, taskConf.VALUES[1]
			else
				return true, count, taskConf.VALUES[1]
			end
		end
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kRecharge then
		if not user_info.achievement_data then
			return false, 0, taskConf.VALUES[1]
		end
		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Recharge.kRechargeCount then
			if user_info.achievement_data.recharge_money == nil then
				return false
			end
			return user_info.achievement_data.recharge_money >= taskConf.VALUES[1], user_info.achievement_data.recharge_money, taskConf.VALUES[1]
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Recharge.kConsumeCount then
			if user_info.achievement_data.consume_money == nil then
				return false
			end
			return user_info.achievement_data.consume_money >= taskConf.VALUES[1], user_info.achievement_data.consume_money, taskConf.VALUES[1]
		end
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kSignIn then
		if not user_info.achievement_data then
			return false, 0, taskConf.VALUES[1]
		end
		if user_info.achievement_data.sign_in_days == nil then
			return false, 0, taskConf.VALUES[1]
		end
		local value = user_info.achievement_data.sign_in_days
		if value > taskConf.VALUES[1] then
			value = taskConf.VALUES[1]
		end
		return user_info.achievement_data.sign_in_days >= taskConf.VALUES[1], value, taskConf.VALUES[1]
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kLottery then
		if not user_info.daily_data then
			return false, 0, taskConf.VALUES[1]
		end
		if user_info.daily_data.lottery_count == nil then
			return false, 0, taskConf.VALUES[1]
		end
		return user_info.daily_data.lottery_count >= taskConf.VALUES[1], user_info.daily_data.lottery_count, taskConf.VALUES[1]
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kHomeRes then
		if taskConf.TARGET_2 == CONF.ETaskTarget_2_HomeRes.kGetResTimes then
			if not user_info.daily_data then
				return false, 0, taskConf.VALUES[1]
			end

			local count = user_info.daily_data.get_home_res_times or 0
			
			if not count then
				return false, 0, taskConf.VALUES[1]
			end

			if count < taskConf.VALUES[1] then
				return false, count, taskConf.VALUES[1]
			else
				return true, count, taskConf.VALUES[1]
			end
		end
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kTrial then
		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Trial.kDailyTimes then
			if not user_info.daily_data then
				return false, 0, taskConf.VALUES[1]
			end

			local count = user_info.daily_data.trial_times or 0
			
			if not count then
				return false, 0, taskConf.VALUES[1]
			end

			if count < taskConf.VALUES[1] then
				return false, count, taskConf.VALUES[1]
			else
				return true, count, taskConf.VALUES[1]
			end
		end
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kTask then
		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Task.kFinishTimes then
			if not user_info.achievement_data then
				return false, 0, taskConf.VALUES[1]
			end
			if user_info.achievement_data.task_finish_times == nil then
				return false
			end

			return user_info.achievement_data.task_finish_times >= taskConf.VALUES[1], user_info.achievement_data.task_finish_times, taskConf.VALUES[1]
		end
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kSlave then
		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Slave.kSlaveTimes then
			if not user_info.achievement_data then
				return false, 0, taskConf.VALUES[1]
			end
			if user_info.achievement_data.slave_times == nil then
				return false
			end

			return user_info.achievement_data.slave_times >= taskConf.VALUES[1], user_info.achievement_data.slave_times, taskConf.VALUES[1]
		end
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kPlanet then

		if not planet_user then
			return false, 0, taskConf.VALUES[1]
		end

		local count
		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kLevelCollectTimes then
			if Tools.isEmpty(planet_user.colloct_level_times_list) == true then
				count = 0
			else
				if taskConf.VALUES[2] == 0 then
					count = 0
					for i=1,#planet_user.colloct_level_times_list do
						count = planet_user.colloct_level_times_list[i] + count
					end
				else
					count = planet_user.colloct_level_times_list[taskConf.VALUES[2]]
				end
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kCollectCount then
			if Tools.isEmpty(planet_user.colloct_count) == true then
				count = 0
			else
				if taskConf.VALUES[2] == 0 then
					count = 0
					for i=1,#planet_user.colloct_count do
						count = planet_user.colloct_count[i] + count
					end
				else
					count = planet_user.colloct_count[taskConf.VALUES[2]]
				end
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kLevelRuinsTimes then
			if Tools.isEmpty(planet_user.ruins_level_times_list) == true then
				count = 0
			else
				if taskConf.VALUES[2] == 0 then
					count = 0
					for i = 1 , #planet_user.ruins_level_times_list do
						count = count + planet_user.ruins_level_times_list[i]
					end
				else
					count = planet_user.ruins_level_times_list[taskConf.VALUES[2]]
				end
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kLevelFishingTimes then
			if Tools.isEmpty(planet_user.fishing_level_times_list) == true then
				count = 0
			else
				if taskConf.VALUES[2] == 0 then
					count = 0
					for i = 1 , #planet_user.fishing_level_times_list do
						count = count + planet_user.fishing_level_times_list[i]
					end
				else
					count = planet_user.fishing_level_times_list[taskConf.VALUES[2]]
				end
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kBossTimes then
			if Tools.isEmpty(planet_user.boss_level_times_list) == true then
				count = 0
			else
				if taskConf.VALUES[2] == 0 then
					count = 0
					for i = 1 , #planet_user.boss_level_times_list do
						count = count + planet_user.boss_level_times_list[i]
					end
				else
					count = planet_user.boss_level_times_list[taskConf.VALUES[2]]
				end
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kAttackCityWinTimes then
			
			count = planet_user.attack_city_win_times or 0
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kWinTims then
			count = planet_user.attack_win_times or 0
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kBaseDefenseWinTimes then
			count = planet_user.base_defense_win_times or 0
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kMoveBaseTimes then
			if Tools.isEmpty(planet_user.move_base_times_list) == true then
				count = 0
			else
				count = planet_user.move_base_times_list[taskConf.VALUES[2]]
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kAttackMonsterTimes then
			if Tools.isEmpty(planet_user.attack_monster_times) then
				count = 0
			else
				count = 0
				if taskConf.VALUES[2] <= 0 then
					for i = 1 , #planet_user.attack_monster_times do
						count = count + planet_user.attack_monster_times[i]
					end
				else
					for i = 2 , #taskConf.VALUES do
						count = count + planet_user.attack_monster_times[taskConf.VALUES[i]]
					end 
				end 
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kBaseAttackTimes then
			count = planet_user.base_attack_times or 0		
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kLevelCollectTimesDay then
			if Tools.isEmpty(planet_user.colloct_level_times_list_day) == true then
				count = 0
			else
				if taskConf.VALUES[2] == 0 then
					count = 0
					for i=1,#planet_user.colloct_level_times_list_day do
						count = planet_user.colloct_level_times_list_day[i] + count
					end
				else
					count = planet_user.colloct_level_times_list_day[taskConf.VALUES[2]]
				end
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kLevelRuinsTimesDay then
			if Tools.isEmpty(planet_user.ruins_level_times_list_day) == true then
				count = 0
			else
				if taskConf.VALUES[2] == 0 then
					count = 0
					for i = 1 , #planet_user.ruins_level_times_list_day do
						count = count + planet_user.ruins_level_times_list_day[i]
					end
				else
					count = planet_user.ruins_level_times_list_day[taskConf.VALUES[2]]
				end
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kLevelFishingTimesDay then
			if Tools.isEmpty(planet_user.fishing_level_times_list_day) == true then
				count = 0
			else
				if taskConf.VALUES[2] == 0 then
					count = 0
					for i = 1 , #planet_user.fishing_level_times_list_day do
						count = count + planet_user.fishing_level_times_list_day[i]
					end
				else
					count = planet_user.fishing_level_times_list_day[taskConf.VALUES[2]]
				end
			end
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Planet.kBossTimesDay then
			if Tools.isEmpty(planet_user.boss_level_times_list_day) == true then
				count = 0
			else
				if taskConf.VALUES[2] == 0 then
					count = 0
					for i = 1 , #planet_user.boss_level_times_list_day do
						count = count + planet_user.boss_level_times_list_day[i]
					end
				else
					count = planet_user.boss_level_times_list_day[taskConf.VALUES[2]]
				end
			end
		end
		
		if not count then
			return false, 0, taskConf.VALUES[1]
		end

		if count < taskConf.VALUES[1] then
			return false, count, taskConf.VALUES[1]
		else
			return true, count, taskConf.VALUES[1]
		end
	elseif taskConf.TARGET_1 == CONF.ETaskTarget_1.kBlueprint then
		local count = 0
		if taskConf.TARGET_2 == CONF.ETaskTarget_2_Blueprint.kBlueprintAll then
			if not user_info.achievement_data then
				return false, 0, taskConf.VALUES[2]
			end
			if user_info.achievement_data.blueprint_count == nil then
				return false, 0, taskConf.VALUES[2]
			end
			if taskConf.VALUES[1] == 0 then
				for _,v in ipairs(user_info.achievement_data.blueprint_count) do
					count = count + v.value
				end
			else
				for _,v in ipairs(user_info.achievement_data.blueprint_count) do
					if v.key == taskConf.VALUES[1] then
						count = v.value
						break
					end
				end
			end
			return count >= taskConf.VALUES[2] , count , taskConf.VALUES[2]
		elseif taskConf.TARGET_2 == CONF.ETaskTarget_2_Blueprint.kBlueprintTime then
			if not user_info.daily_data then
				return false, 0, taskConf.VALUES[2]
			end
			if user_info.daily_data.blueprint_count == nil then
				return false, 0, taskConf.VALUES[2]
			end
			if taskConf.VALUES[1] == 0 then
				for _,v in ipairs(user_info.daily_data.blueprint_count) do
					count = count + v.value
				end
			else
				for _,v in ipairs(user_info.daily_data.blueprint_count) do
					if v.key == taskConf.VALUES[1] then
						count = v.value
						break
					end
				end
			end
			return count >= taskConf.VALUES[2] , count , taskConf.VALUES[2]
		end
	end

	return false,0,0
end

function Tools.getPlanetSpeed( machine )
	local speed
	if machine >= 1 and machine <= 3 then
		speed = CONF.PARAM.get("planet_move_speed").PARAM[1]
	elseif machine == 4 then
		speed = CONF.PARAM.get("planet_move_speed").PARAM[3]
	else
		speed = CONF.PARAM.get("planet_move_speed").PARAM[2]
	end
	
	return speed
end

function Tools.getMaxStrength( level, group_tech_list )

	local percent = 0
	local num = 0

	if group_tech_list then
		for k,m in ipairs(group_tech_list) do
			if m.status == 3 then
				local conf = CONF.GROUP_TECH.check(m.tech_id)
				if conf then
					if conf.TECHNOLOGY_TARGET_1 == CONF.ETechTarget_1.kUserInfo 
					and (conf.TECHNOLOGY_TARGET_2 == 0)
					and conf.TECHNOLOGY_TARGET_3 == CONF.ETechTarget_3_UserInfo.kStrength then


							 percent = percent + conf.TECHNOLOGY_ATTR_PERCENT
							 num = num + conf.TECHNOLOGY_ATTR_VALUE
					end
				else
					LOG_ERROR("Tools.getMaxStrength no group_tech_list ID",m.tech_id)
				end
			end
		end
	end
	local value = CONF.PLAYERLEVEL.get(level).STRENGTH
	return value + value * 0.01 * percent + num
end

function Tools.shipSubEnergy( ship_info, type, result, isFight)
	if ship_info.energy_exp == nil or ship_info.energy_exp <= 0 then
		return
	end

	local pre_level
	if isFight == true then
		pre_level = ship_info.energy_level
	end

	if result == 2 then
		result = 0
	end
	local param = CONF.PARAM.get(string.format("energy_loss_param_%d_%d", type, result)).PARAM

	local max = CONF.PARAM.get(string.format("energy_loss_max_%d_%d", type, result)).PARAM

	local sub = math.min(math.floor(ship_info.energy_exp * param), max)

	CoreShip.setExp(-sub, ship_info)

	if isFight == true and pre_level ~= ship_info.energy_level then
		for i,key in pairs(CONF.ShipGrowthAttrs) do
			local diff = Tools.getEnergyAddition( ship_info.id, ship_info.energy_level, key) - Tools.getEnergyAddition( ship_info.id, pre_level, key)
			ship_info.attr[key] = ship_info.attr[key] + diff
		end
	end
end

function Tools.getMaxDurable( ship_id, level )
	local conf = CONF.AIRSHIP.get(ship_id)
	local max_durable = conf.DURABLE + conf.DURABLE * CONF.PARAM.get("ship_level").PARAM * (level - 1)--*耐久度加成
	return math.floor(max_durable)
end
function Tools.getShipMaxDurable( ship_info )
	return Tools.getMaxDurable( ship_info.id, ship_info.level )
end

function Tools.getSubDurableByParam( ship_info, type, result, tech_param)--type:1.pve 2.pvp result: 1.win 0.lose

	if result == 2 then
		result = 0
	end

	local param = CONF.PARAM.get(string.format("sub_durable_%d_%d", type, result)).PARAM

	return math.ceil(param * ship_info.level) * (1 - tech_param)
end

function Tools.shipSubDurable( ship_info, type, result, tech_param )

	if result == 2 then
		result = 0
	end

	local sub = Tools.getSubDurableByParam( ship_info, type, result, tech_param)
	ship_info.durable = ship_info.durable - sub
	if ship_info.durable < 0 then
		ship_info.durable = 0
	end
end

function Tools.getFixShipDurableGold( ship_info )
	local conf = CONF.AIRSHIP.get(ship_info.id)
	local max_durable = Tools.getShipMaxDurable(ship_info)
	return math.ceil((max_durable - ship_info.durable) * CONF.PARAM.get("fix_ship_gold").PARAM) 
end

function Tools.getFixShipDurableTime( ship_info, user_info, tech_list, group_tech_list)

	local building_info = user_info.building_list[CONF.EBuilding.kGarage]
	assert(building_info ~= nil, "error")
	
	local base_speed = CONF[string.format("BUILDING_%d",CONF.EBuilding.kGarage)].get(building_info.level).REPAIR_SPEED

	local fixSpeed = base_speed + Tools.getValueByTechnologyAddition(base_speed, CONF.ETechTarget_1.kUserInfo, 0, CONF.ETechTarget_3_UserInfo.kFixSpeed, tech_list, group_tech_list)

	assert(base_speed > 0, "error: repair_speed <= 0")

	local conf = CONF.AIRSHIP.get(ship_info.id)
	local max_durable = Tools.getShipMaxDurable(ship_info)

	return math.ceil((max_durable - ship_info.durable) / fixSpeed + 1)
end

function Tools.checkShipDurable( ship_info )

	local conf = CONF.AIRSHIP.get(ship_info.id)
	local max_durable = Tools.getShipMaxDurable(ship_info)
	local Bit = require "Bit"
	if Bit:has(ship_info.status, CONF.EShipState.kFix) == true then
		return false
	end
	return ship_info.durable >= (max_durable * CONF.PARAM.get("ship_durable_min_percent").PARAM * 0.01)
end

function Tools.getGemRate( maxLevelRate, maxLevel, curLevel )
	return math.max(maxLevelRate/math.pow(4,(maxLevel-curLevel)), 0)
end

function Tools.getGemListRate( gem_list )
	local max_level = 0 
	local maxLevelRate = 0
	for i,v in ipairs(gem_list) do
		if v%10 > max_level then
			max_level = v%10
			maxLevelRate = CONF.GEM.get(v).RATE 

		elseif v%10 == max_level then
			if CONF.GEM.get(v).RATE > maxLevelRate then
				maxLevelRate = CONF.GEM.get(v).RATE 
			end
		end
	end

	local rate = 0
	for i,v in ipairs(gem_list) do
		rate = rate + Tools.getGemRate(maxLevelRate, max_level, v%10)
	end

	return rate
end

function Tools.addNum( key, num, list )
	if list[key] == nil then
		list[key] = num
	else
		list[key] = list[key] + num
	end
end

function Tools.createShipByConf( ship_id )
	local conf = CONF.AIRSHIP.get(ship_id)
	if not conf then
		return nil
	end

	local ship_info =
	{
		id = conf.ID,
		status = 0,
		type = conf.TYPE,
		kind = conf.KIND,
		quality = conf.QUALITY,
		star = conf.STAR,
		level = conf.LEVEL,
		skill = conf.SKILL,
		weapon_list = Tools.clone(conf.WEAPON_LIST),
		load = 0,
		durable = 0,
	}

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

	return ship_info
end

function Tools.autoFight(attack_list, attack_hp_list, hurter_list, hurter_hp_list,attack_buff_list,hurter_buff_list)
	local event_list = {}
	local step = 0

	local pvpControler = require("FightLogic.FightControler")
	pvpControler:init(Tools.clone(attack_list), attack_hp_list, Tools.clone(hurter_list), hurter_hp_list, false)
	local ackbuflist 
	local hurbuflist 
	if attack_buff_list ~= nil or hurter_buff_list ~= nil then
		if attack_buff_list ~= nil then
			if type(attack_buff_list) ~= "table" then
				ackbuflist = {attack_buff_list}
			else
				ackbuflist = attack_buff_list
			end
		end
		if hurter_buff_list ~= nil then
			if type(hurter_buff_list) ~= "table" then
				hurbuflist = {hurter_buff_list}
			else
				hurbuflist = hurter_buff_list
			end
		end
		FightControler:addStartBuff(ackbuflist,hurbuflist)
	end

	local function getEventData()

		local event = pvpControler:getEvent()
		if event ~= nil then

			return event
		end

		while event == nil do
			pvpControler:doLogic()
			event = pvpControler:getEvent()
		end
		assert(event,"pvpControler:doLogic error")
		return event
	end
	
	local isWin = -100
	local attack_hp_list
	local hurter_hp_list

	repeat
		step = step + 1
		local event = getEventData()
		table.insert(event_list, event)

		if event and event.id == 1 then
			isWin = event.values[1]
			attack_hp_list = event.attack_hp_list
			hurter_hp_list = event.hurter_hp_list
		end
	until isWin ~= -100 or step > 500

	if step > 500 then
		return false, event_list
	end

	if isWin == 1 then
		return true,  event_list, attack_hp_list, hurter_hp_list
	end
	return false, event_list, attack_hp_list, hurter_hp_list
end

function Tools.calSlaveGetRes(type, value, master_level, slave_level)	--0:经验 1.金币 2.金属 3.晶体 4.气体
	local param
	if type == 0 then
		param = CONF.PARAM.get("slave_get_exp").PARAM
	else
		param = CONF.PARAM.get("slave_get_res_" .. type).PARAM
	end
	local parcent = 10
	if master_level ~= slave_level then
		parcent = param / (master_level - slave_level) * 10 + 10
	end
	if parcent <= 0 then
		return 0
	elseif parcent > 100 then
		return value
	end
	return  math.floor(value * 0.01 * parcent)
end


function Tools.getLength(pt)
	return math.sqrt( pt.x * pt.x + pt.y * pt.y )
end

function Tools.getPlanetMoveTime( pos_list, speed )
	local count = #pos_list
	if count < 2 then
		return nil
	end
	local length = 0
	for i=2,count do
		local diff = {
			x = pos_list[i].x - pos_list[i-1].x, 
			y = pos_list[i].y - pos_list[i-1].y,
		}
		length = length + Tools.getLength(diff)
	end
	Tools._print("getPlanetMoveTime",math.ceil(length / speed),length,speed)
	return math.ceil(length / speed)
end

function Tools.getRewards( reward_id )--return {[key]=value}
	local conf = CONF.REWARD.get(reward_id)
	if conf == nil then
		print("CONF.REWARD.get() err", reward_id)
		LOG_ERROR("CONF.REWARD.get() err"..reward_id)
	end

	local items = {}

	if conf.TYPE == 0 then

		for i,v in ipairs(conf.ITEM) do
			if v > 0 and conf.COUNT[i] > 0 then
				items[conf.ITEM[i]] = conf.COUNT[i]
			end
		end

	elseif conf.TYPE == 99 then

		math.randomseed(tostring(os.time()):reverse():sub(1, 6)) 

		for i,v in ipairs(conf.WEIGHT) do
			local weight = v
			if math.random(100) <= weight then
				
				if conf.ITEM[i] > 0 and conf.COUNT[i] > 0 then
					items[conf.ITEM[i]] = conf.COUNT[i]
				end
			end
		end
	else
		math.randomseed(tostring(os.time()):reverse():sub(1, 6)) 

		local total_num = conf.TYPE

		

		local function randIndex( list, conf )
			local total_weight = 0
			for _,index in ipairs(list) do
				total_weight = total_weight + conf.WEIGHT[index]
			end

			if total_weight == 0 then
				return 0
			end

			local weight = math.random(total_weight)

			local num = 0
			for i, index in ipairs(list) do
				num = num + conf.WEIGHT[index]

				if weight < num then
					local ret = index
					table.remove(list, i)
	
					return ret
				end
			end
			return 0
		end

		local index_list = {}
		for i,v in ipairs(conf.WEIGHT) do
			local weight = v
			if type(weight) ~="string" and weight > 0 then
				table.insert(index_list,i)
			end
		end

		for i=1,total_num do
			local index = randIndex(index_list, conf)
			if index > 0 then
				if conf.ITEM[index] > 0 and conf.COUNT[index]> 0 then
					items[conf.ITEM[index]] = conf[conf.COUNT[index]]
				end
			end
		end
	end
	return items
end


return Tools