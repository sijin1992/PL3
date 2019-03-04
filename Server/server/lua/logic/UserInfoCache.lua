local kc = require "kyotocabinet"
local db = kc.DB:new()-- + kc.DB.ONOLOCK

local user_info_list = {}

local user_name_cache = {}
local user_name_cache_count = 0
local function addUserNameCache(user_name)
	table.insert(user_name_cache, user_name)
	user_name_cache_count = user_name_cache_count + 1
end

local rank_max_count = 100

local level_rank_list = {}

local power_rank_list = {}

local main_city_rank_list = {}

local max_trial_rank_list = {}

local level_interval = 10
local level_interval_list = {}
local level_interval_min_level = CONF.PARAM.get("slave_room_open").PARAM[1]

local function initLevelInterval( index )

	level_interval_list[index] = {}
	level_interval_list[index].__num = 0
	if level_interval_list.__min == nil or index < level_interval_list.__min then
		level_interval_list.__min = index
	end
	if level_interval_list.__max == nil or index > level_interval_list.__max then
		level_interval_list.__max = index
	end
end

local function setLevelInterval( other_user_info, old_level )
	local old_index
	if old_level ~= nil then
		old_index = math.floor(old_level / level_interval)
	end
	local index = math.floor(other_user_info.level / level_interval)

	if level_interval_list[index] == nil then
		initLevelInterval(index)
	end

	if old_index ~= nil then
		if level_interval_list[old_index] == nil then
			initLevelInterval(old_index)
		end
		
		if old_index ~= index then
			if level_interval_list[old_index][other_user_info.user_name] ~= nil then
				level_interval_list[old_index][other_user_info.user_name] = nil 
				level_interval_list[old_index].__num = level_interval_list[old_index].__num - 1
			end
		end
	end

	if level_interval_list[index][other_user_info.user_name] == nil then
		level_interval_list[index][other_user_info.user_name] = other_user_info.level
		level_interval_list[index].__num = level_interval_list[index].__num + 1
	end
end

if not db:open("UserInfo.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
	error("UserInfo.kch open err")
else
	db:iterate(
		function(k,v)
			local data = Tools.decode("OtherUserInfo", v)
			user_info_list[k] = data

			addUserNameCache(k)

			if data.level_rank > 0 then
				level_rank_list[data.level_rank] = data
			end
			if data.power_rank > 0 then
				power_rank_list[data.power_rank] = data
			end

			if data.main_city_level_rank > 0 then
				main_city_rank_list[data.main_city_level_rank] = data
			end
			
			if data.max_trial_level_rank > 0 then
				max_trial_rank_list[data.max_trial_level_rank] = data
			end

			setLevelInterval( data )
		end,
	false)
end

local function checkRankCount(list, rank_key)
	local count = #list
	if count > rank_max_count then
		for index=count, rank_max_count, -1 do
			if list[index] then
				list[index][rank_key] = 0
				db:set(list[index].user_name, Tools.encode("OtherUserInfo", list[index]))
				table.remove(list, index)
			end
		end
	end
end

local function sort_level_func(a , b)
	if a and not b then
		return true
	end
	if b and not a then
		return false
	end

	if a.level > b.level then
		return true
	elseif a.level == b.level then

		return a.power > b.power
	else
		return false
	end
end

local function sortLevel(  )

	table.sort(level_rank_list, sort_level_func)

	for i,v in ipairs(level_rank_list) do
		v.level_rank = i
		db:set(v.user_name, Tools.encode("OtherUserInfo", v))
	end

	checkRankCount(level_rank_list, "level_rank")
end

local function sort_power_func(a , b)
	if a and not b then
		return true
	end
	if b and not a then
		return false
	end
	if a.power > b.power then
		return true
	elseif a.power == b.power then

		return a.level > b.level
	else
		return false
	end
end

local function sortPower(  )

	table.sort(power_rank_list, sort_power_func)

	for i,v in ipairs(power_rank_list) do
		v.power_rank = i
		db:set(v.user_name, Tools.encode("OtherUserInfo", v))
	end

	checkRankCount(power_rank_list, "power_rank")
end

local function sort_main_city_level_func(a , b)
	if a and not b then
		return true
	end
	if b and not a then
		return false
	end

	if a.building_level_list[CONF.EBuilding.kMain] > b.building_level_list[CONF.EBuilding.kMain] then
		return true
	elseif a.building_level_list[CONF.EBuilding.kMain] == b.building_level_list[CONF.EBuilding.kMain] then
		return a.level > b.level
	else
		return false
	end
end

local function sortMainCityLevel( )

	table.sort(main_city_rank_list, sort_main_city_level_func)

	for i,v in ipairs(main_city_rank_list) do
		v.main_city_level_rank = i
		db:set(v.user_name, Tools.encode("OtherUserInfo", v))
	end

	checkRankCount(main_city_rank_list, "main_city_level_rank")
end

local function sort_max_trial_level_func( a, b )


	if (a.max_trial_level == nil or a.max_trial_level == 0) and (b.max_trial_level == nil or b.max_trial_level == 0) then
		return tonumber(a.user_name) > tonumber(b.user_name)
	end

	if (a.max_trial_level == nil or a.max_trial_level == 0) and (b.max_trial_level~= nil and b.max_trial_level > 0) then
		return false
	end

	if (b.max_trial_level == nil or b.max_trial_level == 0) and (a.max_trial_level~= nil and a.max_trial_level > 0) then
		return true
	end

	if a.max_trial_star > b.max_trial_star then

		return true

	elseif a.max_trial_star == b.max_trial_star then

	 	if a.max_trial_level > b.max_trial_level then
			return true
		elseif a.max_trial_level == b.max_trial_level then

			return a.level > b.level
		else
			return false
		end
	 else
		return false
	end
end

local function sortMaxTrialLevel(  )

	table.sort(max_trial_rank_list, sort_max_trial_level_func)

	for i,v in ipairs(max_trial_rank_list) do
		v.max_trial_level_rank = i
		db:set(v.user_name, Tools.encode("OtherUserInfo", v))
	end

	checkRankCount(max_trial_rank_list, "max_trial_level_rank")
end

local function checkAddMaxTrialList( info )
	if info.max_trial_level == nil or info.max_trial_level == 0 then
		return false
	end
	return true
end

local UserInfoCache = {}



function UserInfoCache.getRandUser( my_user_name, num )
	if num <= 0 then
		return nil
	end

	local list = {}

	local function add( user_name )
		if user_name and user_name ~= my_user_name then
			local info = UserInfoCache.get(user_name)
			if info then
				for i,v in ipairs(list) do
					if v.user_name == info.user_name then
						return false
					end
				end
				table.insert(list, info)
				return true
			end
		end
		return false
	end

	
	local indexs = {}
	local section = math.floor(user_name_cache_count / num)
	if user_name_cache_count <= num or section < 2 then
		for i=1,num do
			add(user_name_cache[i])
		end
	else
		for i=1,num do
			local s = 1 + section*(i-1)
			local e = section*i
			local index = math.random(s, e)
			add(user_name_cache[index])
		end
	end
	return list
end

function UserInfoCache.get(user_name)
	if user_name == nil then
		return nil
	end
	if string.sub(user_name,1,5) == "robot" then

		local id = tonumber(string.match(user_name,"(%d+)")) 

		local conf -- = CONF.ROBOT.get(id)
		if id < 1000 then
			conf = CONF.ROBOT.get(id)
		else
			conf = CONF.COMPUTERUSER.get(user_name)
		end

		local lv_lineup = {}

		for i,v in ipairs(conf.MONSTER_LIST) do

			if v == 0 then
				lv_lineup[i] = 0
			else
				lv_lineup[i] = CONF.AIRSHIP.get(v).LEVEL
			end
		end

		local other_user_info = {
			user_name = user_name,
			nickname = conf.NICKNAME,
			power = conf.POWER,
			id_lineup = conf.MONSTER_LIST,
			level = conf.LEVEL,
			lv_lineup = lv_lineup,
			building_level_list = {},
			icon_id = conf.ICON_ID,
		}

		for i=1,CONF.EBuilding.count do
			other_user_info.building_level_list[i] = 1
		end
		return other_user_info
	end


	local data = user_info_list[user_name]
	if data == nil then
		return nil
	end
	return Tools.clone(data)
end

function UserInfoCache.getRankLevelInfo( rank )
	local info = level_rank_list[rank]
	if info then
		return Tools.clone(info)
	end
	return nil
end

function UserInfoCache.getRankPowerInfo( rank )
	local info = power_rank_list[rank]
	if info then
		return Tools.clone(info)
	end
	return nil
end

function UserInfoCache.getRankMainCityLevelInfo( rank )
	local info = main_city_rank_list[rank]
	if info then
		return Tools.clone(info)
	end
	return nil
end

function UserInfoCache.getRankTrialLevelInfo( rank )
	local info = max_trial_rank_list[rank]
	if info then
		return Tools.clone(info)
	end
	return nil
end


function UserInfoCache.isSameGroup(my_user_name, other_user_name)
	if my_user_name == other_user_name then
		return true
	end
	local other_user_info1 = UserInfoCache.get(my_user_name)
	local other_user_info2 = UserInfoCache.get(other_user_name)

	if other_user_info1.groupid == nil or other_user_info1.groupid == "" then
		return false
	end
	return other_user_info1.groupid == other_user_info2.groupid 
end

function UserInfoCache.set(user_name, otherUserInfo)

	local rank = {
		"level_rank",
		"power_rank",
		"main_city_level_rank",
		"max_trial_level_rank",
	}

	local values = {
		{"level"},
		{"power"},
		{"building_level_list"},
		{"max_trial_level", "max_trial_star"},
	}

	local rank_func = {
		sortLevel,
		sortPower,
		sortMainCityLevel,
		sortMaxTrialLevel,
	}

	local check_func = {
		nil,
		nil,
		nil,
		checkAddMaxTrialList,
	}

	local rank_list = {
		level_rank_list,
		power_rank_list,
		main_city_rank_list,
		max_trial_rank_list,
	}
	if user_info_list[user_name] == nil then
		addUserNameCache(user_name)
	end
	otherUserInfo.last_act = os.time()
	Tools._print("otherUserInfo save time",otherUserInfo.nickname,otherUserInfo.last_act)
	user_info_list[user_name] = otherUserInfo

	for i=1, #rank do

		local rank_num = otherUserInfo[rank[i]]

		if rank_num and rank_num > 0 then

			local changed = false
			for _,str in ipairs(values[i]) do
				if type(otherUserInfo[str]) == "table" then
					if otherUserInfo[str][1] ~= rank_list[i][rank_num][str][1] then
						changed = true
					end
				elseif otherUserInfo[str] ~= rank_list[i][rank_num][str] then
					changed = true
				end
			end
	
			if rank_list[i][rank_num].user_name == otherUserInfo.user_name then

				rank_list[i][rank_num] = otherUserInfo
			end
			if changed == true then
				rank_func[i]()
			end

		else
	
			if check_func[i] == nil or check_func[i](otherUserInfo) == true then
				otherUserInfo[rank[i]] = 0
				table.insert(rank_list[i], otherUserInfo)
				rank_func[i]()
			end
		end
	end

	local user_info_buff = Tools.encode("OtherUserInfo", otherUserInfo)

	return db:set(user_name, user_info_buff)
end

function UserInfoCache.setLevelInterval( other_user_info, old_level )
	if other_user_info.level < level_interval_min_level then
		return
	end
	setLevelInterval( other_user_info, old_level )
end


function UserInfoCache.getRandUserByLevelInterval( my_user_name, num )

	local info = UserInfoCache.get(my_user_name)

	local cur_inedx = math.floor(info.level / level_interval)

	local function addList( index, pos, list )
		if list[index] == nil then
			list[index] = {}
		end
		list[index][pos] = true
	end

	local function getByIndex(index, num, list, depth, param)

		if num == 0 then
			return
		end

		if Tools.isEmpty(level_interval_list) == true then
			return
		end

		if level_interval_list.__max < index or level_interval_list.__min > index then
			return
		end

		if level_interval_list[index] == nil or level_interval_list[index].__num == 0 then

		else
			local section = math.floor(level_interval_list[index].__num / num)
			local need_num = num
			if  section < 2 then
				if (level_interval_list[index].__num / num) > 1 then
		
					local remove_num = level_interval_list[index].__num - num
					section = math.floor(level_interval_list[index].__num / remove_num)
					local remove_list = {}
					for i=1,remove_num do
						local s = 1 + section*(i-1)
						local e = section*i
						local pos = math.random(s, e)
						table.insert(remove_list, pos)
					end
					
					local pos = 0
					for k,v in pairs(level_interval_list[index]) do
						pos = pos + 1
						local need = true
						for _,v2 in ipairs(remove_list) do
							if v2 == pos then
								need = false
								break
							end
						end
						if need == true then
							addList( index, pos, list )
						
							num = num - 1
						end
					end

				else
					for i=1,level_interval_list[index].__num do

						addList( index, i, list )
				
						num = num - 1
					end
				end
			else
				for i=1,need_num do
					local s = 1 + section*(i-1)
					local e = section*i
					local pos = math.random(s, e)
					addList( index, pos, list )
		
					num = num - 1
				end
			end
		end


	
		if num > 0 then
			if param == nil then
				getByIndex(index+1, num, list, depth+1, 1)
				getByIndex(index-1, num, list, depth+1, -1)
			else
				getByIndex(index + param, num, list, depth+1, param)
			end
		end

	end 


	local function getFromLevelInterval(index, pos_list, output_user_name_list )
		local pos = 0

		for k,v in pairs(level_interval_list[index]) do

			if k ~= "__num" then
				pos = pos + 1
				if pos_list[pos] == true then

					table.insert(output_user_name_list, k)
				end
			end
		end
	end

	local list = {}

	getByIndex(cur_inedx, num, list, 0)

	local user_name_list = {}
	for index,v in pairs(list) do
		getFromLevelInterval(index, v, user_name_list)
	end

	return user_name_list
end

function UserInfoCache.AddComputerUser()
	local count = CONF.COMPUTERUSER.len
	local userInfo = require "UserInfo"
	for i=1, count do
		local num = CONF.COMPUTERUSER.index[i]
		local conf = CONF.COMPUTERUSER[num]
		userInfo:new()

		userInfo:add(conf.ID, conf.NICKNAME, conf.ICONID)

		local sync_user = SyncUserCache.getSyncUser(conf.ID)
		sync_user.res = Tools.clone(conf.RES)
		SyncUserCache.setSyncUser(sync_user)

		local planet_user = PlanetCache.getUser(conf.USERNAME)
		--暂时先没舰队后面添舰队

	end
end


return UserInfoCache