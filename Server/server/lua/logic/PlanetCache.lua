local timeChecker = require "TimeChecker"

local kc = require "kyotocabinet"
local db = kc.DB:new()-- + kc.DB.ONOLOCK

local PlanetCache = {}



local conf_node_list = {} --以ROW COL 为索引的NODE CONF 副本

local node_id_list = {}	--以ID为索引的NODE LIST

local node_pos_list = {}		--以ROW COL 为索引的NODE LIST 副本

local global_pos_list = {}	--以X Y 为索引的ELEMENT LIST

local planet_user_list = {}	--以 user_name为索引的 PLANET_USER LIST

local planet_city_list = {}	--据点LIST副本

local planet_wangzuo_list = {} --王座LIST副本

local planet_wangzuo_tower_list = {} --王座电磁塔LIST副本

local planet_boss_list = {} 	--BOSS LIST副本

local planet_city_res_list = {}	--据点矿LIST副本

local planet_boss_user_list = {}	--以 global_key 为索引的 BOSS 玩家信息 LIST

local planet_city_reward_list = {} --以 city global_key为索引的 GROUPID LIST

local planet_city_reward_user_list = {} --以 city global_key为索引的 USER LIST

local planet_monster_list = {} --野怪的LIST副本

local last_city_daily_reward_dayid = 0

local last_city_open_fight_time = 0

local last_wangzuo_daily_reward_dayid = 0 --王座奖励时间

local last_wangzuo_open_fight_time = 0 --王座战斗时间

local last_wangzuo_create_time = 0 --王座创建时间

local wangzuo_title_list = {} --称号列表

local wangzuo_occupy_player_list = {} --铁王座名人堂

local path_reach = require("PathReach"):create()

local last_boss_reflesh = os.time() - 8600
local boss_reset_time = 8600

local last_res_reflesh = os.time() - 7200
local res_reset_time = 7200

local monster_reset_time = 10800
local last_monster_reflesh = os.time() - monster_reset_time

local monster_revive_time = 300 --野怪复活时间

local first_loop_time = true


local nodeW = 16
local nodeH = 16
local destroy_resub_time = 1800
local destroy_sub_time = 300
local fix_value = CONF.PARAM.get("planet_fix").PARAM

local function saveNodeData( node )

	node_id_list[node.id] = node

	local conf = CONF.PLANETWORLD.get(node.id)

	if Tools.isEmpty(node_pos_list[conf.ROW]) == true then
		node_pos_list[conf.ROW] = {}
	end
	node_id_list[node.id] = node
	node_pos_list[conf.ROW][conf.COL] = node

	db:set("NODE"..node.id, Tools.encode("PlanetNode", node))
end


local function saveUserData( planet_user )
	--Tools._print("saveUserData", planet_user.user_name)
	--Tools.print_t(planet_user)

	planet_user_list[planet_user.user_name] = planet_user

	db:set("USER"..planet_user.user_name, Tools.encode("PlanetUser", planet_user))
end

local function saveWangZuoTitle()
	local title = {}
	title.wangzuo_title_list = wangzuo_title_list 
	db:set("TITLE",Tools.encode("PlanetWangZuoTitleList",title))
end

local function saveWangZuoOccupy()
	local title = {}
	title.occupy_list = wangzuo_occupy_player_list 
	db:set("WANGZUO_OCCUPY",Tools.encode("PlanetWangZuoOccupyList",title))
end

local function createRes( id, x, y)
	local conf = CONF.PLANET_RES.get(id)
	local element = {
		guid = 0,
		global_key = "",
		pos_list = {
			{
				x=x, 
				y=y,
			},
		},
		type = 2,
		res_data = {
			id = id,
			 cur_storage = conf.STORAGE,
			 hasMonster = true,
		},
	}
	return element
end

local function createRuins( id, x, y)
	local element = {
		guid = 0,
		global_key = "",
		pos_list = {
			{
				x = x,
				y = y,
			},	
		},
		type = 3,
		ruins_data = {
			id = id,
		},
	}
	return element
end

local function createCity( id, pos_list, cur_time)
	local element = {
		guid = 0,
		global_key = "",
		pos_list = pos_list,
		type = 5,
		city_data = {
			id = id,
			hasMonster = true,
			status = 2,
			status_begin_time = cur_time,
			occupy_begin_time = 0,
			groupid = "",
		},
	}
	return element
end
local function createWangzuo(id, pos_list, cur_time)
	local element = {
		guid = 0,
		global_key = "",
		pos_list = pos_list,
		type = 12,
		wangzuo_data = {
			id = id,
			status = 1,
			status_begin_time = cur_time,
			occupy_begin_time = 0,
			create_time = cur_time,
			groupid = "",
		},
	}
	return element
end

local function createWangzuoTower(id, x, y)
	local element = {
		guid = 0,
		global_key = "",
		pos_list = {
			{
				x = x,
				y = y,
			},
		},
		type = 13,
		tower_data = {
			id = id,
			status = 1,
			is_attack = false ,
			groupid = "",
		},
	}
	return element
end

local function createBase( user_name, x, y)
	local element = {
		guid = 0,
		global_key = "",
		pos_list = {
			{
				x = x,
				y = y,
			},
		},
		type = 1,
		base_data = {
			user_name = user_name,
			destroy_value = 0,
		},
	}
	return element
end

local function createBoss( id, create_time, x, y)
	local element = {
		guid = 0,
		global_key = "",
		pos_list = {
			{
				x = x,
				y = y,
			},
		},
		type = 4,
		boss_data = {
			id = id,
			create_time = create_time,
		},
	}
	return element
end


local function createCityRes( id, x, y)
	local conf = CONF.PLANET_RES.get(id)
	local element = {
		guid = 0,
		global_key = "",
		pos_list = {
			{
				x = x,
				y = y,
			},
		},
		type = 6,
		city_res_data = {
			id = id,
			cur_storage = conf.STORAGE,
			restore_start_time = 0,
		},
	}
	return element
end

local function createMonster( id, create_time, x, y)
	local element = {
		guid = 0,
		global_key = "",
		pos_list = {
			{
				x = x,
				y = y,
			},
		},
		type = 11,
		monster_data = {
			isDead = 0,
			id = id,
			create_time = create_time,
		},
	}
	return element
end

local function getRectInGlobal(row, col)

	local min = {	
		x = row * nodeW - nodeW / 2,
		y = col * nodeH - nodeH / 2,
	}
	local max = {	
		x = row * nodeW + nodeW / 2 - 1, 
		y = col * nodeH + nodeH / 2 - 1,
	}

	return min, max
end

local function getNodeIDByGlobalPos( pos )
	local row = ((pos.x > 0 and pos.x + 1) or pos.x)  / (nodeW/2)

	if (row > 0 and math.abs(row) < 1) or (row < 0 and math.abs(row) <= 1) then
		row = 0
	else
		if row > 0 then
			row = math.ceil((row - 1)/2)
		else
			row = math.floor((row + 1)/2)
		end
	end

	local col = ((pos.y > 0 and pos.y + 1) or pos.y) / (nodeH/2)


	if (col > 0 and math.abs(col) < 1) or (col < 0 and math.abs(col) <= 1) then
		col = 0
	else
		if col > 0 then
			col = math.ceil((col - 1)/2)
		else
			col = math.floor((col + 1)/2)
		end
	end

	if  conf_node_list[row] == nil or conf_node_list[row][col] == nil then
		return
	end
	return conf_node_list[row][col].ID
end

function PlanetCache.getNodeIDByGlobalPos( pos )

	return getNodeIDByGlobalPos(pos)
end

local function getGlobalPosByNode( node_id, diffX, diffY )

	local conf = CONF.PLANETWORLD.get(node_id)

	local min, max = getRectInGlobal(conf.ROW, conf.COL)

	return {x = min.x + diffX, y = min.y + diffY}
end

function PlanetCache.pathReach(src_pos, dest_pos)

	local src_node_id = getNodeIDByGlobalPos(src_pos)
	local dest_node_id = getNodeIDByGlobalPos(dest_pos)

	if src_node_id == dest_node_id then
	
		return {src_pos, dest_pos}, {src_node_id}
	end
	
	local node_list = path_reach:getFindPathList(src_node_id, dest_node_id)
	if node_list == nil then
		return nil
	end
	local node_count = #node_list

	if node_count < 3 then

		return {src_pos, dest_pos}, {src_node_id, dest_node_id}
	end

	local pos_list = {src_pos}

	for i=2,node_count-1 do
		local conf = CONF.PLANETWORLD.get(node_list[i])
		if conf.TYPE > 2 then
			local pos = getGlobalPosByNode(node_list[i], nodeW/2, nodeH/2)
			table.insert(pos_list, pos)
		end
	end

	table.insert(pos_list, dest_pos)

	return pos_list, node_list
end


function PlanetCache.hasElementInGlobal( x, y )
	if Tools.isEmpty(global_pos_list[x]) == true then
		return false
	end
	local ret = Tools.isEmpty(global_pos_list[x][y]) == false

	return ret
end

local function randEmptyPos(min, max)

	local x
	local y

	local flag = false
	for i=1,3 do
		x = math.random(min.x, max.x)
		y = math.random(min.y, max.y)
		if PlanetCache.hasElementInGlobal(x,y) == false then
			flag = true
		end

		if flag then
			break
		end
	end

	if flag == false then
		for j=min.y,max.y do
			for i=min.x,max.x do
				if PlanetCache.hasElementInGlobal(i,j) == false then
					return {x = i, y = j}
				end
			end
		end
		return nil
	end
	return {x = x, y = y}
end
 
local function randEmptyPosByNodeList( node_id_list )
	if #node_id_list <1 then
		return nil,nil
	end
	local index = math.random(1, #node_id_list)
	local conf = CONF.PLANETWORLD.get(node_id_list[index])
	local min, max = getRectInGlobal(conf.ROW, conf.COL)
	local pos = randEmptyPos(min, max)

	if pos == nil then
		for i,id in ipairs(node_id_list) do

			conf = CONF.PLANETWORLD.get(id)
			min, max = getRectInGlobal(conf.ROW, conf.COL)
			pos = randEmptyPos(min, max)
			if pos ~= nil then
				return pos, id
			end
		end
	else
		return pos, node_id_list[index]
	end
end

function PlanetCache.randEmptyPosByNodeList( node_id_list )
	return randEmptyPosByNodeList(node_id_list)
end



local function addElement(node, element)

	if Tools.isEmpty(node.element_list) == true then
		node.element_list = {}
	end
	if element.guid <= 0 then
	
		local guid = Tools.getGuid(node.element_list)

		element.guid = guid

		element.global_key = string.format("%d_%d", node.id, guid)

		table.insert(node.element_list, element)
	end 

	for i,v in ipairs(element.pos_list) do
		
		if Tools.isEmpty(global_pos_list[v.x]) == true then
			global_pos_list[v.x] = {}
		end
		if PlanetCache.hasElementInGlobal(v.x, v.y) == false then
		
			global_pos_list[v.x][v.y] = element
		end
	end
end

function PlanetCache.moveElement( node, element, pos_list)

	local old_key_list = Tools.split(element.global_key, "_")
	
	if Tools.isEmpty(node.element_list) == true then
		node.element_list = {}
	end

	local old_node = PlanetCache.getNodeByID(tonumber(old_key_list[1]))

	for i,v in ipairs(old_node.element_list) do
		if v.guid == element.guid then
			table.remove(old_node.element_list, i)
			break
		end
	end

	if old_node.id ~= node.id then
		saveNodeData(old_node)
	end

	local guid = Tools.getGuid(node.element_list)
	element.guid = guid
	element.global_key = string.format("%d_%d", node.id, guid)

	table.insert(node.element_list, element)

	if element.type == 1 then
		if Tools.isEmpty(element.base_data.guarde_list) == false then
			for i,army_key in ipairs(element.base_data.guarde_list) do

				local army = PlanetCache.getArmy(army_key)
				army.element_global_key = element.global_key

				local user_name = Tools.split(army_key, "_")[1]
				saveUserData(PlanetCache.getUser(user_name))
			end
		end

		local other_user_info = UserInfoCache.get(element.base_data.user_name)
		PlanetCache.groupRemoveAttackerByElement( other_user_info.groupid, element.global_key)
		PlanetCache.userRemoveAttackerByElement( element.base_data.user_name, element.global_key)
	end

	for i,v in ipairs(element.pos_list) do
		global_pos_list[v.x][v.y] = nil
	end

	element.pos_list = pos_list

	for i,v in ipairs(element.pos_list) do
		
		if Tools.isEmpty(global_pos_list[v.x]) == true then
			global_pos_list[v.x] = {}
		end
		if PlanetCache.hasElementInGlobal(v.x, v.y) == false then
		
			global_pos_list[v.x][v.y] = element
		end
	end

	saveNodeData(node)

	return element
end

local function resetRes(node, num, rand_list)

	if Tools.isEmpty(node.element_list) == false then
		for i=#node.element_list, 1, -1 do
			if node.element_list[i].type == 2  then
				if (node.element_list[i].res_data.user_name ~= nil and node.element_list[i].res_data.user_name ~= "") or node.element_list[i].res_data.hasMonster == true then
	
					num = num - 1
				else
					for i,v in ipairs(node.element_list[i].pos_list) do
						global_pos_list[v.x][v.y] = nil
					end
					table.remove(node.element_list, i)
				end
			end
		end
	end

	if num <= 0 then
		return
	end

	local conf = CONF.PLANETWORLD.get(node.id)

	local min, max = getRectInGlobal(conf.ROW, conf.COL)

	local count = #rand_list

	for i=1,num do
		local pos = randEmptyPos(min, max)

		if pos ~= nil then
			local index = math.random(1, count)
			local element = createRes(rand_list[index], pos.x, pos.y)
			addElement(node, element)
		end
	end
end

local function resetRuins(node, num, rand_list)
	if Tools.isEmpty(node.element_list) == false then
		for i=#node.element_list, 1, -1 do
			if node.element_list[i].type == 3  then

				num = num - 1
			end
		end
	end

	if num <= 0 then
		return
	end

	local conf = CONF.PLANETWORLD.get(node.id)

	local min, max = getRectInGlobal(conf.ROW, conf.COL)

	local count = #rand_list

	for i=1,num do
		local pos = randEmptyPos(min, max)
		if pos ~= nil then
			local index = math.random(1, count)
			local element = createRuins(rand_list[index], pos.x, pos.y)
			addElement(node, element)
		end
	end
end

local function resetBoss( node, rand_list, now_time)
	local conf = CONF.PLANETWORLD.get(node.id)

	local min, max = getRectInGlobal(conf.ROW, conf.COL)

	local count = #rand_list

	local pos = randEmptyPos(min, max)

	if pos ~= nil then
		local index = math.random(1, count)
		Tools._print("create boss ", pos.x, pos.y)
		local element = createBoss(rand_list[index], now_time, pos.x, pos.y)
		addElement(node, element)

		table.insert(planet_boss_list, element)
	end
end

local function resetCity(node, cur_time)


	local conf = CONF.PLANETWORLD.get(node.id)

	local min, max = getRectInGlobal(conf.ROW, conf.COL)

	

	local center ={ x = min.x + math.floor((max.x - min.x)/2), y = min.y + math.floor((max.y - min.y)/2)}
	
	local center_1 = Tools.clone(center)
	local center_2 = Tools.clone(center)
	local center_3 = Tools.clone(center)
	if center.x>0 then
		center_1.x = center_1.x + 1
		center_3.x = center_3.x + 1
	else
		center_1.x = center_1.x - 1
		center_3.x = center_3.x - 1
	end

	if center.y>0 then
		center_2.y = center_1.y + 1
		center_3.y = center_3.y + 1
	else
		center_2.y = center_1.y - 1
		center_3.y = center_3.y - 1
	end

	local pos_list = {center, center_1, center_2, center_3}

	local element = createCity(node.id, pos_list, cur_time)
	addElement(node, element)

	for i=1,CONF.PLANETCITYRES.len do

		local conf = CONF.PLANETCITYRES[CONF.PLANETCITYRES.index[i]]
		if node.id == conf.NODE_ID then
			local res = createCityRes(conf.ID, conf.POS[1], conf.POS[2])
			addElement(node, res)

			table.insert(planet_city_res_list, res)
		end
	end

	
	
	table.insert(planet_city_list, element)
end

local function resetWangzuo(node, cur_time)
	local pos_list ={
		{x = 0 , y = 0},
		{x = 1 , y = 0},
		{x = -1 , y = 0},
		{x = 0 , y = 1},
		{x = 0 , y = -1},
		{x = 1 , y = 1},
		{x = -1 , y = 1},
		{x = 1 , y = -1},
		{x = -1 , y = -1},
	}


	local element = createWangzuo(node.id, pos_list, cur_time)

	Tools._print("resetWangzuo")
	Tools.print_t(element)
	Tools._print("resetWangzuo end")

	addElement(node, element)	

	for i=1,CONF.PLANETTOWER.len do
		local conf = CONF.PLANETTOWER[CONF.PLANETTOWER.index[i]]
		local node = PlanetCache.getNodeByID(conf.NODE_ID)
		if node ~= nil then
			local tower = createWangzuoTower(conf.ID, conf.POS[1], conf.POS[2])
			addElement(node, tower)
			Tools._print("createWangzuoTower")
			table.insert(planet_wangzuo_tower_list, tower)
		end
	end
	
	table.insert(planet_wangzuo_list, element)
end


local function resetMonster( node, rand_list, now_time )
	local conf = CONF.PLANETWORLD.get(node.id)

	local min, max = getRectInGlobal(conf.ROW, conf.COL)

	local count = #rand_list

	local pos = randEmptyPos(min, max)

	if pos ~= nil then
		local index = math.random(1, count)
		--Tools._print("create monster ",rand_list[index],pos.x,pos.y)
		local element = createMonster(rand_list[index], now_time, pos.x, pos.y)
		addElement(node, element)

		table.insert(planet_monster_list, element)
	end
end

function PlanetCache.getNodeByID( id )
	
	return node_id_list[id]
end

function PlanetCache.getNodeElementCount(id , type)
	local node = PlanetCache.getNodeByID( id )
	if not node then
		return -1
	end
	local num = 0
	for i,v in ipairs(node.element_list) do
		if type then
			if v.type == type then
				num = num + 1
			end
		else
			num = num + 1
		end
	end
	return num 
end

if not db:open("Planet.kch", kc.DB.OWRITER + kc.DB.OCREATE) then

	error("Planet.kch open err")
else

	local id_list = CONF.PLANETWORLD.getIDList()
	for i,id in ipairs(id_list) do
		local nodeConf = CONF.PLANETWORLD.get(id)
		if conf_node_list[nodeConf.ROW] == nil then
			conf_node_list[nodeConf.ROW] = {}
		end

		conf_node_list[nodeConf.ROW][nodeConf.COL] = nodeConf
	end

	db:iterate(
		function(k,v)
			if string.sub(k,1,4) == "NODE" then

				local planet_node = Tools.decode("PlanetNode", v)

				local conf = CONF.PLANETWORLD.get(planet_node.id)

				if Tools.isEmpty(node_pos_list[conf.ROW]) == true then
					node_pos_list[conf.ROW] = {}
				end
				node_id_list[planet_node.id] = planet_node
				node_pos_list[conf.ROW][conf.COL] = planet_node

				for i,element in ipairs(planet_node.element_list) do
					addElement(planet_node, element)
					if element.type == 5 then
						table.insert(planet_city_list, element)
					elseif element.type == 4 then
						table.insert(planet_boss_list, element)
					elseif element.type == 6 then
						table.insert(planet_city_res_list, element)
					elseif element.type == 11 then
						table.insert(planet_monster_list, element)
					elseif element.type == 12 then
						table.insert(planet_wangzuo_list, element)
						Tools._print("db ",element.wangzuo_data.status)
					elseif element.type == 13 then
						table.insert(planet_wangzuo_tower_list, element)
					end
				end
			elseif string.sub(k, 1, 4) == "USER" then

				local planet_user = Tools.decode("PlanetUser", v)
				planet_user_list[planet_user.user_name] = planet_user

				for i,army in ipairs(planet_user.army_list) do
					if army.line ~= nil then
						PlanetCache.addArmyLineToNode(army.line)
					end
				end
			elseif string.sub(k, 1 , 10) == "CITYREWARD" then
				local global_key = string.sub(k, 10 , #k)
				if Tools.isEmpty(planet_city_reward_list[global_key]) == true then
					planet_city_reward_list[global_key] = {}
				end

				planet_city_reward_list[global_key][v] = true
			elseif string.sub(k,1 , 14) == "CITYUSERREWARD" then
				local global_key = string.sub(k, 14 , #k)
				if Tools.isEmpty(planet_city_reward_user_list[global_key]) == true then
					planet_city_reward_user_list[global_key] = {}
				end
				planet_city_reward_user_list[global_key][v] = true
			elseif string.sub(k, 1 , 16) == "CITY_DAILY_DAYID" then
		
				last_city_daily_reward_dayid = tonumber(v)
			elseif string.sub(k, 1 , 19) == "WANGZUO_DAILY_DAYID" then
		
				last_wangzuo_daily_reward_dayid = tonumber(v)
			elseif string.sub(k, 1 , 5) == "TITLE" then
				wangzuo_title_list = Tools.decode("PlanetWangZuoTitleList", v).wangzuo_title_list
			elseif string.sub(k, 1 , 14) == "WANGZUO_OCCUPY"  then
				wangzuo_occupy_player_list = Tools.decode("PlanetWangZuoOccupyList", v).occupy_list 
			end
		end,
	false)


	if Tools.isEmpty(node_id_list) == true or #node_id_list < CONF.PLANETWORLD.count() then
		local cur_time = os.time()
		for i,id in ipairs(id_list) do
		
			if PlanetCache.getNodeByID(id) == nil then
				local nodeConf = CONF.PLANETWORLD.get(id)

				local node = {
					id = id,
					element_list = {},
				}

				if nodeConf.TYPE == 2 then
					resetCity(node, cur_time)
				end
				if nodeConf.TYPE == 3 then
					resetWangzuo(node, cur_time)
				end

				local nodeLevelConf = CONF.PLANETNODELEVEL.get(nodeConf.LV)
				if id > 1 then

					resetRes(node, nodeLevelConf.RES_MAX_NUM, nodeLevelConf.RES_ID_LIST)
					
					resetRuins(node, nodeLevelConf.RUINS_MAX_NUM, nodeLevelConf.RUINS_ID_LIST)
				end

				saveNodeData(node)
				Tools._print("add node",node.id)
			end
		end
	end

	if last_city_daily_reward_dayid == 0 then
		last_city_daily_reward_dayid = timeChecker.get_dayid_from(os.time())
		db:set("CITY_DAILY_DAYID", tostring(last_city_daily_reward_dayid))
	end
	if last_wangzuo_daily_reward_dayid == 0 then
		last_wangzuo_daily_reward_dayid = timeChecker.get_dayid_from(os.time())
		db:set("WANGZUO_DAILY_DAYID", tostring(last_wangzuo_daily_reward_dayid))
	end
end

function PlanetCache.closeShield( base )

	base.base_data.shield_start_time = nil
	base.base_data.shield_time = nil
	base.base_data.shield_type = nil
end

function PlanetCache.getUser( user_name )

	if user_name == nil then
		LOG_ERROR("PlanetCache.getUser error")
	end

	local planet_user = planet_user_list[user_name]
	if planet_user == nil then
 
		local node_id_list = {}

		local id_list = CONF.PLANETWORLD.getIDList()
		for i,id in ipairs(id_list) do
			local nodeConf = CONF.PLANETWORLD.get(id)
			if nodeConf.TYPE == 1 and (nodeConf.LV == 1) then
				local num = PlanetCache.getNodeElementCount(id , 1)
				Tools._print("getUser nodeid=",id,"num=",num,nodeConf.PLAYER)
				if num>=0 and num < nodeConf.PLAYER then
					table.insert(node_id_list, nodeConf.ID)
				end
			end
		end
		Tools._print("getUser node_id_list num=",#node_id_list)

		local pos, node_id = randEmptyPosByNodeList(node_id_list)

		if pos == nil then
			return nil
		end
		local planet_node = PlanetCache.getNodeByID(node_id)

		local element = createBase(user_name, pos.x, pos.y)

		print("createBase ok",pos.x,pos.y,type(element))

		element.base_data.shield_start_time = os.time()
		element.base_data.shield_type = 1

		local green_hand_item = CONF.PARAM.get("planet_shield_base_green_hand_item").PARAM
		element.base_data.shield_time = CONF.ITEM.get(green_hand_item).VALUE

		addElement(planet_node, element)

		saveNodeData(planet_node)

		local node_conf = CONF.PLANETWORLD.get(node_id)

		planet_user = {
			user_name = user_name,
			base_global_key = element.global_key,
			nation = node_conf.NATION,
		}
		saveUserData(planet_user)
	end
	return planet_user
end

function PlanetCache.getArmy( army_key )

	local key_list = Tools.split(army_key, "_")
	local guid = tonumber(key_list[2])
	local user = PlanetCache.getUser(key_list[1])
	if Tools.isEmpty(user.army_list) == true then
		return nil
	end
	for i,v in ipairs(user.army_list) do
		if v.guid == guid then
			return v
		end
	end
	return nil
end

function PlanetCache.userAddArmy(user_name, planet_army )
	--Tools._print("userAddArmy", user_name, planet_army.status_machine)
	local planet_user = PlanetCache.getUser( user_name )

	if Tools.isEmpty(planet_user.army_list) == true then

		planet_user.army_list = {}
	end
	planet_army.guid = Tools.getGuid(planet_user.army_list)

	planet_army.army_key = user_name .. "_" .. planet_army.guid

	PlanetStatusMachine[planet_army.status_machine].start(os.time(), planet_user, planet_army)

	--Tools._print("userAddArmy "..user_name.."  "..planet_army.status_machine)

	table.insert(planet_user.army_list, planet_army)

	saveUserData(planet_user)
end

function PlanetCache.addArmyLineToNode( army_line )
	if Tools.isEmpty(army_line.node_id_list) == true then
		return false
	end
	for i,id in ipairs(army_line.node_id_list) do

		local node = PlanetCache.getNodeByID(id)

		if Tools.isEmpty(node.army_line_key_list) == true then
			node.army_line_key_list = {}
		end

		table.insert(node.army_line_key_list, army_line.user_key)

		saveNodeData(node)
	end
	return true
end

function PlanetCache.removeArmyLineInNode( army_line )
	
	if Tools.isEmpty(army_line.node_id_list) == true then
		return false
	end
	for i,id in ipairs(army_line.node_id_list) do

		local node = PlanetCache.getNodeByID(id)

		for i,key in ipairs(node.army_line_key_list) do
			if key == army_line.user_key then
				table.remove(node.army_line_key_list, i)
				break
			end
		end
		saveNodeData(node)
	end
	return true
end

function PlanetCache.getMoveTime( pos_list, speed )
	return Tools.getPlanetMoveTime( pos_list, speed )
end

function PlanetCache.getElement( element_global_key )
	if element_global_key == nil then
	
		return nil
	end
	local key_list = Tools.split(element_global_key, "_")
	node_id = tonumber(key_list[1])
	guid =  tonumber(key_list[2])

	local node = node_id_list[node_id]
	if node == nil then
		return nil
	end
	if Tools.isEmpty(node.element_list) == true then
		return nil
	end
	for i,v in ipairs(node.element_list) do
		if v.guid == guid then
			return v
		end
	end
	return nil
end

function PlanetCache.removeElement(element_global_key)

	local key_list = Tools.split(element_global_key, "_")
	node_id = tonumber(key_list[1])
	guid = tonumber(key_list[2])

	local node = PlanetCache.getNodeByID(node_id)

	local index
	local element
	for i,v in ipairs(node.element_list) do
		if v.guid == guid then
			index = i
			element = v
			break
		end
	end

	if element.type == 2 and element.res_data.user_name ~= "" and  element.res_data.user_name ~= nil then
		PlanetCache.userRemoveAttackerByElement( element.res_data.user_name, element_global_key)
	end

	for i,v in ipairs(element.pos_list) do

		global_pos_list[v.x][v.y] = nil
	end

	table.remove(node.element_list, index)
	saveNodeData(node)
end

function PlanetCache.createMailUser( planet_user, planet_army )
	local base = PlanetCache.getElement(planet_user.base_global_key)


	local ship_hp_list
	local ship_info_list
	if planet_army then

		ship_hp_list = planet_army.lineup_hp
		ship_info_list = planet_army.ship_list
	end

	local user = {
		info = UserInfoCache.get(planet_user.user_name),
		pos_list = base.pos_list,
		ship_hp_list = ship_hp_list,
		ship_list = ship_info_list,
	}
	return user
end

function PlanetCache.createMailUserByMonster( ship_hp_list, ship_info_list)
	local guid = 0
	for i,ship_info in ipairs(ship_info_list) do
		if ship_info.guid == nil then
			guid = guid + 1
			ship_info.guid = guid
		end
	end
	local user = {
		ship_hp_list = ship_hp_list,
		ship_list = ship_info_list,
	}
	return user
end

function PlanetCache.saveUserData( user_data )
	saveUserData(user_data)
end

function PlanetCache.saveNodeDataByID( node_id )
	local node_data = PlanetCache.getNodeByID(node_id)
	saveNodeData(node_data)
end

function PlanetCache.broadcastUserUpdate(user_name, recver) --通知recver 自己 planet user 更新
	local list
	if type(recver) == "table" then
		list = recver
	else
		list = {recver}
	end

	local multi_cast =
	{
		recv_list = list,
		cmd = 0x1036,
		msg_buff = "0",
	}
	
	local multi_cast_buff = Tools.encode("Multicast", multi_cast)
	activeSendMessage(user_name, 0x2100, multi_cast_buff)
end

function PlanetCache.broadcastUserUpdateToGroup(user_name)	--通知公会所有人 user_name 的 planet user 更新

	local other_user_info = UserInfoCache.get(user_name)
	if other_user_info.groupid == "" or other_user_info.groupid == nil then
		return
	end

	local group_main = GroupCache.getGroupMain(other_user_info.groupid)
	local recv_list = {}
	local user_list = group_main.user_list or {}
	for k,v in ipairs(user_list) do
		table.insert(recv_list, v.user_name)
	end



	local cmd = 0x16ff
	local group_update =
	{
		user_name = user_name,
		user_update_list = {
			{
				user_name = user_name,
				planet_user = PlanetCache.getUser(user_name),
			},
		},
	}
	local multi_cast = 
	{
		recv_list = recv_list,
		cmd = cmd,
		group_update = group_update,
	}
      	local multi_buff = Tools.encode("Multicast", multi_cast)
      	activeSendMessage(user_name, 0x2100, multi_buff)
end

function PlanetCache.broadcastUpdate(user_name, node_list )

	local chat_msg = {
		msg = {"update node"},
		channel = 0,
		sender = {
			uid = user_name,
		},
		type = 0,
		minor = {4},
	}

	if type(node_list) == "number" then
		node_list = {node_list,}
	end

	if Tools.isEmpty(node_list) == false then
		for i,node_id in ipairs(node_list) do
			chat_msg.minor[i + 1] = node_id
		end
	end


	local chat_msg_buff = Tools.encode("ChatMsg_t", chat_msg)
	activeSendMessage(user_name, 0x1521, chat_msg_buff)
end

function PlanetCache.checkHasGroupArmy( user_name )

	local cur_time = os.time()

	local planet_user = PlanetCache.getUser(user_name)

	if Tools.isEmpty(planet_user.army_list) == false then
		for i,army in ipairs(planet_user.army_list) do
			local back_flag = false
			if (army.status_machine == 5 and army.element_global_key ~= planet_user.base_global_key)
			or army.status_machine == 10
			or army.status_machine == 8 then

				back_flag = true

			elseif army.status_machine == 1 then
				local element = PlanetCache.getElement(army.element_global_key)
				if element.type == 6 then
					back_flag = true
				end
			end

			if back_flag == true then

				PlanetStatusMachine[army.status_machine].back(cur_time, planet_user, army)
			end
		end
	end


	local base = PlanetCache.getElement(planet_user.base_global_key)
	if Tools.isEmpty(base.base_data.guarde_list) == false then
		for i=#base.base_data.guarde_list,1, -1 do
			local army_key = base.base_data.guarde_list[i]
			local army = PlanetCache.getArmy(army_key)
			local user = PlanetCache.getUser(Tools.split(army_key, "_")[1])

			if Tools.split(army.army_key, "_")[1] ~= user_name then
			
				PlanetStatusMachine[army.status_machine].back(cur_time, user, army)
			end
		end
	end

	local other_user_info = UserInfoCache.get(user_name)

	PlanetCache.groupRemoveAttackerByHurter(other_user_info.groupid, user_name)

	return true
end

function PlanetCache.groupExitCityRes(groupid)
	
	for i,element in ipairs(planet_city_res_list) do
		if element.city_res_data.groupid ~= nil and element.city_res_data.groupid ~= "" then

			if element.city_res_data.groupid == groupid then

				element.city_res_data.user_list = nil
				element.city_res_data.groupid = nil

				local node_id = tonumber(Tools.split(element.global_key, "_")[1]) 
				PlanetCache.saveNodeDataByID(node_id)
			end
		end
	end
end

function PlanetCache.exitCity(element, group_main)
	if element.type ~= 5 then

		return
	end
	
	if element.city_data.groupid == nil or element.city_data.groupid == "" then

		return
	end


	if group_main == nil then
		group_main = GroupCache.getGroupMain(element.city_data.groupid)
	end

	local cityConf = CONF.PLANETCITY.get(element.city_data.id)
	for i,global_key in ipairs(group_main.occupy_city_list) do
		if global_key == element.global_key then
			table.remove(group_main.occupy_city_list, i)
			break
		end
	end

	for i, id in ipairs(cityConf.BUFF) do
	
		for i,v in ipairs(group_main.tech_list) do
			if v.tech_id == id then
				
				v.city_buff_count = v.city_buff_count - 1
				if v.city_buff_count <= 0 then
					table.remove(group_main.tech_list, i)
					break
				end
			end
		end
	end
	
	GroupCache.update(group_main)

	element.city_data.groupid = ""

	element.city_data.user_name = nil

	local node_id = tonumber(Tools.split(element.global_key, "_")[1]) 
	PlanetCache.saveNodeDataByID(node_id)

	return node_id
end

function PlanetCache.addEnemyToGroup( army_key, groupid )
	-- body
end

function PlanetCache.removeEnemyInGroup( army_key, groupid )
	-- body
end

function PlanetCache.addEnlistToGroup( army_key )

	local key_list = Tools.split(army_key,"_")
	local other_user_info = UserInfoCache.get(key_list[1])
	local group_main = GroupCache.getGroupMain(other_user_info.groupid)
	if group_main == nil then
		return
	end
	if Tools.isEmpty(group_main.enlist_list) == true then
		group_main.enlist_list = {}
	end
	
	table.insert(group_main.enlist_list, army_key)

	GroupCache.update(group_main, key_list[1], true)
end

function PlanetCache.removeEnlistInGroup( army_key )
	

	local key_list = Tools.split(army_key,"_")
	local other_user_info = UserInfoCache.get(key_list[1])


	local group_main = GroupCache.getGroupMain(other_user_info.groupid)
	if group_main == nil then
		return
	end

	for i,v in ipairs(group_main.enlist_list) do
		if v == army_key then
			table.remove(group_main.enlist_list, i)
			GroupCache.update(group_main, key_list[1], true)
			return
		end
	end
end

function PlanetCache.groupClearByUserName(group_main, user_name)

	for i=#group_main.attack_our_list,1, -1 do

		local army = PlanetCache.getArmy(group_main.attack_our_list[i])
		if army ~= nil then
			local element = PlanetCache.getElement(army.element_global_key)
			if element == nil then
				table.remove(group_main.attack_our_list, i)
			elseif element.type == 1 and element.base_data.user_name == user_name then
				table.remove(group_main.attack_our_list, i)
			end
		else
			table.remove(group_main.attack_our_list, i)
		end
	end

	for i=#group_main.enlist_list,1, -1 do
		local key_list = Tools.split(group_main.enlist_list[i], "_")
		if  key_list[1] == user_name then
			table.remove(group_main.enlist_list, i)
		end
	end
end

function PlanetCache.groupAddAttacker(groupid, army_key)

	if groupid == "" or groupid == nil then
		return
	end
	local group_main = GroupCache.getGroupMain(groupid)
	if Tools.isEmpty(group_main.attack_our_list) == true then
		group_main.attack_our_list = {}
	end
	table.insert(group_main.attack_our_list, army_key)

	GroupCache.update(group_main, Tools.split(army_key, "_")[1], true)
end

function PlanetCache.groupRemoveAttacker(groupid, army_key)

	if groupid == "" or groupid == nil then
		return
	end
	local group_main = GroupCache.getGroupMain(groupid)
	if Tools.isEmpty(group_main.attack_our_list) == true then
		return
	end
	for i=#group_main.attack_our_list,1, -1 do
		if group_main.attack_our_list[i] == army_key then
			table.remove(group_main.attack_our_list, i)
			break
		end
	end
	GroupCache.update(group_main, Tools.split(army_key, "_")[1], true)
end

function PlanetCache.groupRemoveAttackerByElement( groupid, element_global_key)

	if groupid == "" or groupid == nil then
		return
	end
	local group_main = GroupCache.getGroupMain(groupid)

	local user_name

	for i=#group_main.attack_our_list, 1, -1 do

		local army = PlanetCache.getArmy(group_main.attack_our_list[i])
		if army ~= nil then
			local element = PlanetCache.getElement(army.element_global_key)
			if element == nil then
				table.remove(group_main.attack_our_list, i)
			elseif element.type == 1 and element.global_key == element_global_key then
				table.remove(group_main.attack_our_list, i)
				user_name = element.base_data.user_name
			end
		else
			table.remove(group_main.attack_our_list, i)
		end
	end

	GroupCache.update(group_main, user_name, true)
end

function PlanetCache.userAddAttacker( user_name, army_key )
	local planet_user = PlanetCache.getUser(user_name)

	if Tools.isEmpty(planet_user.attack_me_list) == true then
		planet_user.attack_me_list = {}
	end
	table.insert(planet_user.attack_me_list, army_key)

	PlanetCache.broadcastUserUpdate(user_name, {user_name})

	saveUserData( planet_user )
end

function PlanetCache.userRemoveAttacker( user_name, army_key )

	local planet_user = PlanetCache.getUser(user_name)

	if Tools.isEmpty(planet_user.attack_me_list) == true then
		return
	end

	for i,v in ipairs(planet_user.attack_me_list) do
		if v == army_key then
			table.remove(planet_user.attack_me_list, i)
			break
		end
	end

	PlanetCache.broadcastUserUpdate(user_name, {user_name})

	saveUserData( planet_user )
end

function PlanetCache.userRemoveAttackerByElement( user_name, element_global_key)
	local planet_user = PlanetCache.getUser(user_name)

	if Tools.isEmpty(planet_user.attack_me_list) == true then
		return
	end
	local removed = false
	for i=#planet_user.attack_me_list,1, -1 do
		local army = PlanetCache.getArmy(planet_user.attack_me_list[i])
		if army == nil or army.element_global_key == element_global_key then
			table.remove(planet_user.attack_me_list, i)
			removed = true
		end
	end

	planet_user.attack_me_list = nil

	if removed then
		PlanetCache.broadcastUserUpdate(user_name, {user_name})
	end
end

function PlanetCache.groupRemoveAttackerByHurter(groupid, hurter_user_name)

	if groupid == "" or groupid == nil then
		return
	end
	local group_main = GroupCache.getGroupMain(groupid)
	if Tools.isEmpty(group_main.attack_our_list) == true then
		return
	end
	local hurter_user = PlanetCache.getUser(hurter_user_name)
	for i=#group_main.attack_our_list,1, -1 do
		local army = PlanetCache.getArmy(group_main.attack_our_list[i])
		if army.element_global_key == hurter_user.base_global_key then
			table.remove(group_main.attack_our_list, i)
		end
	end
	GroupCache.update(group_main, hurter_user_name, true)
end

function PlanetCache.getBossUser( user_name, global_key)
	if Tools.isEmpty(planet_boss_user_list[user_name]) == true then
		return nil
	end

	if planet_boss_user_list[user_name].boss_global_key ~= global_key then
		return nil
	end
	return planet_boss_user_list[user_name]
end

function PlanetCache.resetBossUser( info )
	

	planet_boss_user_list[info.user_name] = info
	planet_boss_user_list[info.boss_global_key] = info
end

function PlanetCache.removeBossUser(global_key)

	local info = planet_boss_user_list[global_key]
	if info == nil then
		return
	end
	planet_boss_user_list[info.user_name] = nil
	planet_boss_user_list[global_key] = nil
end

function PlanetCache.GetWangZuoTitle()
	return wangzuo_title_list
end

function PlanetCache.IsHaveTitle(user_name)
	for _,title in ipairs(wangzuo_title_list) do
		if (title.user_name == user_name) then
			return true , title.title
		end
	end
	return false
end

function PlanetCache.RemoveTitle(user_name)
	if user_name == nil then
		wangzuo_title_list = {}
		saveWangZuoTitle()
	else
		if Tools.isEmpty(wangzuo_title_list) == true then
			return true
		end
		for i,title in ipairs(wangzuo_title_list) do
			if (title.user_name == user_name) then
				table.remove(wangzuo_title_list,i)
				saveWangZuoTitle()
				return true
			end
		end
	end
	return false
end

function PlanetCache.SetWangZuoTitle(user_name , title)
	PlanetCache.RemoveTitle(user_name)
	local info = {}
	info.user_name = user_name
	info.title = title
	table.insert(wangzuo_title_list, info)
	saveWangZuoTitle()
end

function PlanetCache.GetTitleTech(user_name)
	local req , title = PlanetCache.IsHaveTitle(user_name)
	if not req then
		return nil
	end

	local conf_title = CONF.TITLE_BUFF.get(title)
	if conf_title == nil then
		return nil
	end

	return conf_title.BUFF
end

function PlanetCache.SetWangZuoOccupy(wangzuo_data)
	if wangzuo_data == nil then
		return 
	end
	local user_name 
	if wangzuo_data.groupid == nil or wangzuo_data.groupid == "" then
		user_name = wangzuo_data.user_name
	else
		local group_user = GroupCache.GetGroupLeader(GroupCache.getGroupMain(wangzuo_data.groupid))
		if group_user ~= nil then
			user_name = group_user.user_name
		end
	end
	if user_name == nil or user_name == "" then
		return 
	end

	local userOccupy = {}
	userOccupy.user_name = user_name
	userOccupy.create_time = os.time() 
	table.insert(wangzuo_occupy_player_list,userOccupy)
	Tools._print("SetWangZuoOccupy",user_name)
	Tools.print_t(wangzuo_occupy_player_list)
	saveWangZuoOccupy()
end

function PlanetCache.GetWangZuoOccupy()
	return wangzuo_occupy_player_list 
end


local function reflushBoss( now_time )
	local node_level_list = {}

	for id,v in pairs(node_id_list) do
		if id > 1 then
			local node_conf = CONF.PLANETWORLD.get(id)
			if node_level_list[node_conf.LV] == nil then
				node_level_list[node_conf.LV] = {}
			end
			table.insert(node_level_list[node_conf.LV], v)
		end
	end



	for i=1, CONF.PLANETNODELEVEL.len do
		local num = CONF.PLANETNODELEVEL.index[i]
		local conf = CONF.PLANETNODELEVEL[num]
		local level = conf.ID

		if Tools.isEmpty(node_level_list[level]) == false and conf.ALL_RAND_BOSS_NUM>0 then
			local count = #node_level_list[level]
			for j=1, conf.ALL_RAND_BOSS_NUM do
				local index = math.random(1, count)
				resetBoss(node_level_list[level][index], conf.ALL_RAND_BOSS_ID_LIST, now_time)
			end
		end
	end
end

function PlanetCache.removeBossElement(global_key)

	PlanetCache.removeBossUser(global_key)

	PlanetCache.removeElement(global_key)

	for i,v in ipairs(planet_boss_list) do
		if v.global_key == global_key then
			table.remove(planet_boss_list, i)
			break
		end
	end

end
local function updateBoss( now_time, node_update_list )

	if Tools.isEmpty(planet_boss_list) == true then
		return
	end
	local node_update_list = {}
	for i=#planet_boss_list,1, -1 do

		local conf = CONF.PLANETBOSS.get(planet_boss_list[i].boss_data.id)
		if now_time > planet_boss_list[i].boss_data.create_time + conf.REMOVE_TIME then

			table.insert(node_update_list, tonumber(Tools.split(planet_boss_list[i].global_key, "_")[1]))
			
			PlanetCache.removeBossUser(planet_boss_list[i].global_key)

			PlanetCache.removeElement(planet_boss_list[i].global_key)

			table.remove(planet_boss_list, i)
		end
	end
	if Tools.isEmpty(node_update_list) == false then
		PlanetCache.broadcastUpdate("", node_update_list)
	end
end

local function reflushMonster( now_time )
	local node_level_list = {}

	for id,v in pairs(node_id_list) do
		if id > 1 then
			local node_conf = CONF.PLANETWORLD.get(id)
			if node_level_list[node_conf.LV] == nil then
				node_level_list[node_conf.LV] = {}
			end
			table.insert(node_level_list[node_conf.LV], v)
		end
	end


	for i=1, CONF.PLANETNODELEVEL.len do
		local num = CONF.PLANETNODELEVEL.index[i]
		local conf = CONF.PLANETNODELEVEL[num]
		local level = conf.ID
		local len = math.random(conf.CREEPS_MIN_NUM,conf.CREEPS_MAX_NUM)

		if Tools.isEmpty(node_level_list[level]) == false then
			local count = #node_level_list[level]
			for j=1, len do
				local index = math.random(1, count)
				
				resetMonster(node_level_list[level][index], conf.CREEPS_LIST, now_time)
			end
		end
	end
end

function PlanetCache.removeMonsterElement(global_key)

	PlanetCache.removeElement(global_key)

	for i,v in ipairs(planet_boss_list) do
		if v.global_key == global_key then
			table.remove(planet_monster_list, i)
			break
		end
	end

end
local function updateMonster( now_time, node_update_list )

	if Tools.isEmpty(planet_monster_list) == true then
		return
	end
	--local node_update_list = {}
	for i=#planet_monster_list,1, -1 do

		if  planet_monster_list[i].monster_data.isDaad==1 and now_time > planet_monster_list[i].monster_data.dead_time + monster_revive_time then
			planet_monster_list[i].monster_data.isDead = 0 --复活HP在死时已经重置，所以不用再重置了
		end

		--local conf = CONF.PLANETCREEPS.get(planet_monster_list[i].monster_data.id)
		--if now_time > planet_monster_list[i].monster_data.create_time + conf.REMOVE_TIME then

		--	table.insert(node_update_list, tonumber(Tools.split(planet_monster_list[i].global_key, "_")[1]))

		--	PlanetCache.removeElement(planet_monster_list[i].global_key)

		--	table.remove(planet_monster_list, i)
		--end
	end
	--if Tools.isEmpty(node_update_list) == false then
	--	PlanetCache.broadcastUpdate("", node_update_list)
	--end
end
local function ClearMonster()
	if Tools.isEmpty(planet_monster_list) == true then
		return
	end
	local node_update_list = {}
	for i=#planet_monster_list,1, -1 do

		table.insert(node_update_list, tonumber(Tools.split(planet_monster_list[i].global_key, "_")[1]))

		PlanetCache.removeElement(planet_monster_list[i].global_key)
		table.remove(planet_monster_list, i)
	end

	if Tools.isEmpty(node_update_list) == false then
		PlanetCache.broadcastUpdate("", node_update_list)
	end
end

function PlanetCache.ClearMonster()
	--Tools._print("PlanetCache.ClearMonster",#planet_monster_list)
	ClearMonster()	
end
function PlanetCache.reflushMonster()
	ClearMonster()
	--Tools._print("PlanetCache.reflushMonster")
	last_monster_reflesh = os.time()
	reflushMonster()
end

function PlanetCache.hasFirstRewardMark( global_key, groupid)
	if Tools.isEmpty(planet_city_reward_list[global_key]) == true then
		return false
	end
	return planet_city_reward_list[global_key][groupid]
end

function PlanetCache.addFirstRewardMark( global_key, groupid)

	if Tools.isEmpty(planet_city_reward_list[global_key]) == true then
		planet_city_reward_list[global_key] = {}
	end

	if planet_city_reward_list[global_key][groupid] == true then
		return
	end

	planet_city_reward_list[global_key][groupid] = true

	db:set("CITYREWARD"..global_key, groupid)
end

function PlanetCache.sendGroupCityReward( groupid, reward_id, title, msg, global_key)
	local group_main = GroupCache.getGroupMain(groupid)
	Tools._print("sendGroupCityReward",groupid,type(group_main),reward_id,type(reward_id))
	if type(reward_id) ~= "number" or group_main == nil then
		return
	end

	local items = Tools.getRewards( reward_id )
	local item_list = {}
	for id,num in pairs(items) do
		local item = {
			id = id,
			num = num,
			guid = 0,
		}
		table.insert(item_list, item)
	end
	local mail = {
		type = 10,
		from = Lang.planet_mail_sender,
		subject = tostring(title),
		message = tostring(msg),
		stamp = os.time(),
		expiry_stamp = os.time() + 604800,
		guid = 0,
		item_list = item_list,
	}

	for i,user in ipairs(group_main.user_list) do
		--Tools._print("addMail",user.user_name,type(title))
		local bSend = true
		if global_key then
			if planet_city_reward_user_list[user.user_name] == nil then
				planet_city_reward_user_list[user.user_name] = true
				db:set("CITYUSERREWARD"..global_key, user.user_name)
			else
				bSend = false
			end
		end
		if bSend then
			RedoList.addMail(user.user_name, mail)
		end
	end
end

local function sendUserCityReward(user_name, reward_id, title, msg )
	local items = Tools.getRewards( reward_id )
	local item_list = {}
	for id,num in pairs(items) do
		local item = {
			id = id,
			num = num,
			guid = 0,
		}
		table.insert(item_list, item)
	end
	local mail = {
		type = 10,
		from = Lang.planet_mail_sender,
		subject = tostring(title),
		message = tostring(msg),
		stamp = os.time(),
		expiry_stamp = os.time() + 604800,
		guid = 0,
		item_list = item_list,
	}

	RedoList.addMail(user_name, mail)
end

function PlanetCache.getCity(node_id)

	for i,city in ipairs(planet_city_list) do
		if city.city_data.id == node_id then
			return city
		end
	end
	return nil
end

function PlanetCache.getCityResByNodeID(id)
	for i,v in ipairs(planet_city_res_list) do
		local conf = CONF.PLANETCITYRES.get(v.city_res_data.id)
		if conf.NODE_ID == id then
			return v
		end
	end
	return nil
end
function PlanetCache.getCityResUser( element, user_name )
	if element.type ~= 6 then
		return nil
	end
	if Tools.isEmpty(element.city_res_data.user_list) then
		return nil
	end

	for i,user in ipairs(element.city_res_data.user_list) do
		if user.user_name == user_name then
			return user
		end
	end
	return nil
end

function PlanetCache.removeCityResUser( element, user_name )
	if element.type ~= 6 then
		return
	end
	if Tools.isEmpty(element.city_res_data.user_list) then
		return
	end

	for i,user in ipairs(element.city_res_data.user_list) do
		if user.user_name == user_name then
			table.remove(element.city_res_data.user_list, i)
			break
		end
	end
end

function PlanetCache.checkCityRes( element, now_time, user_name )
	if element.type ~= 6 then
		return
	end
	if element.city_res_data.cur_storage > 0 then
		return 
	end
	local city_res_conf = CONF.PLANETCITYRES.get(element.city_res_data.id)
	local res_conf = CONF.PLANET_RES.get(element.city_res_data.id)

	if now_time >= element.city_res_data.restore_start_time + city_res_conf.TIME then

		element.city_res_data.cur_storage = res_conf.STORAGE
		element.city_res_data.restore_start_time = 0

		local node_id = tonumber(Tools.split(element.global_key, "_")[1])
		local node = PlanetCache.getNodeByID(node_id)
		saveNodeData(node)

		PlanetCache.broadcastUpdate(user_name, node_id)
	end
end

function PlanetCache.ClickCityGroup(id, groupid)
	if Tools.isEmpty(planet_city_list) == true then
		return true
	end

	local conf = CONF.PLANETCITY.get(id)
	if conf.LV == nil then
		return true
	end
	local smallcity = {}
	for _, v in ipairs(planet_city_list) do
		--if v.city_data.id < id then
		local conf2 = CONF.PLANETCITY.get(v.city_data.id)
		if conf2.LV ~= nil and conf2.LV < conf.LV then
			--if v.city_data.groupid ~= groupid then
			--	return false, i
			--end
			table.insert(smallcity , {conf2.LV , v})
		end
	end
	if Tools.isEmpty(smallcity) == true then
		return true
	end
	if #smallcity >= 2 then
		table.sort(smallcity ,function(a,b)
					return a[1] < b[1]
					end)
	end
	Tools._print("ClickCityGroup")
	Tools.print_t(smallcity)

	for i ,v in ipairs(smallcity) do
		if v[2].city_data.groupid ~= groupid then
			return false, i
		end
	end

	return true
end

function PlanetCache.gmupdateCity(status)


end

local function updateCity( now_time )

	if Tools.isEmpty(planet_city_list) == true then
		return
	end

	local date = os.date("*t", now_time)

	local firstID = CONF.PLANETCITY["index"][1]

	for i=1,#CONF.PLANETCITY[firstID].TIME do
		if date.hour == CONF.PLANETCITY[firstID].TIME[i] and date.min == 0 then
			if now_time - last_city_open_fight_time > 60 then 
				last_city_open_fight_time = now_time

				for i,city in ipairs(planet_city_list) do
					local cityConf = CONF.PLANETCITY.get(city.city_data.id)

					local city_res = PlanetCache.getCityResByNodeID(city.city_data.id)				
					if city_res and city.city_data.groupid ~= city_res.city_res_data.groupid then						
						Tools._print("reset city res... node:", city_res.city_res_data.id, city.city_data.groupid)
						if Tools.isEmpty(city_res.city_res_data.user_list) == false then
							for i,user in ipairs(city_res.city_res_data.user_list) do
								
								local army = PlanetCache.getArmy(user.user_name .. "_" .. user.army_guid)
								local user = PlanetCache.getUser(user.user_name)

								PlanetStatusMachine[army.status_machine].back(now_time, user, army)
							end
						end
						city_res.city_res_data.groupid = city.city_data.groupid
					end

					if city.city_data.user_name ~= nil then
						--Tools._print("sendGroup_daily_CityReward...  ", city.city_data.id)
						--PlanetCache.sendGroupCityReward( city.city_data.groupid, cityConf.EVERYDAY_AWARD, Lang.planet_city_daily_reward_title, Lang.planet_city_daily_reward_msg)

						sendUserCityReward(city.city_data.user_name, cityConf.PLAYER_AWARD, Lang.planet_city_daily_reward_title, Lang.planet_city_daily_reward_msg)
					end

				end
			end
		end
	end

	for i,city in ipairs(planet_city_list) do
		if city.city_data.status == 1 then
			city.city_data.status = 2
		end

		local cityConf = CONF.PLANETCITY.get(city.city_data.id)		
		if city.city_data.groupid ~= nil and now_time - city.city_data.occupy_begin_time >= cityConf.HOLD_TIME then
			city.city_data.occupy_begin_time = now_time
			
			--Tools._print("sendGroup_daily_CityReward...  ", city.city_data.id,city.city_data.groupid,type(city.city_data.groupid))
			PlanetCache.sendGroupCityReward( city.city_data.groupid, cityConf.EVERYTIME_AWARD, Lang.planet_city_time_reward_title, Lang.planet_city_tiem_reward_msg)

		end
	end

--[[	for i=1,#CONF.PLANETCITY[firstID].TIME/2 do
		if date.wday == CONF.PLANETCITY[firstID].TIME[i*2-1] and date.hour == CONF.PLANETCITY[firstID].TIME[i*2] and date.min == 0 then --注释这里可以直接进入战争状态
			if now_time - last_city_open_fight_time > 60 then --前后间隔起码大于一分钟吧
				
				for i,city in ipairs(planet_city_list) do
					if city.city_data.status == 1 then
						city.city_data.status = 2
						city.city_data.status_begin_time = now_time

						local node = PlanetCache.getNodeByID(tonumber(Tools.split(city.global_key, "_")[1]))
						saveNodeData(node)

						Tools._print("open city status", city.city_data.id, city.city_data.status)
					end
				end

				last_city_open_fight_time = now_time
			end
		end
	end

	local day_id = timeChecker.get_dayid_from(now_time)
	local need_send_city_daily_reward = false
	if last_city_daily_reward_dayid ~= day_id then
		need_send_city_daily_reward = true
		last_city_daily_reward_dayid = day_id
		db:set("CITY_DAILY_DAYID", tostring(day_id))
	end	


	for i,city in ipairs(planet_city_list) do

		local cityConf = CONF.PLANETCITY.get(city.city_data.id)

		if city.city_data.status == 2 and now_time - city.city_data.status_begin_time >= cityConf.DURATION then

			city.city_data.status = 1
			city.city_data.status_begin_time = now_time

			if city.city_data.groupid ~= nil and city.city_data.groupid ~= "" then

				if PlanetCache.hasFirstRewardMark(city.global_key, city.city_data.groupid) == false then
					Tools._print("sendGroup_first_CityReward...")
					PlanetCache.sendGroupCityReward( city.city_data.groupid, cityConf.FIRST_AWARD, Lang.planet_city_first_reward_title, Lang.planet_city_first_reward_msg)
					PlanetCache.addFirstRewardMark(city.global_key, city.city_data.groupid)
				end

				local city_res = PlanetCache.getCityResByNodeID(city.city_data.id)
				
				if city_res and city.city_data.groupid ~= city_res.city_res_data.groupid then
					
					Tools._print("reset city res... node:", city_res.city_res_data.id, city.city_data.groupid)
					if Tools.isEmpty(city_res.city_res_data.user_list) == false then
						for i,user in ipairs(city_res.city_res_data.user_list) do
							
							local army = PlanetCache.getArmy(user.user_name .. "_" .. user.army_guid)
							local user = PlanetCache.getUser(user.user_name)

							PlanetStatusMachine[army.status_machine].back(now_time, user, army)
						end
					end
					city_res.city_res_data.groupid = city.city_data.groupid
				end
			end

			local node = PlanetCache.getNodeByID(tonumber(Tools.split(city.global_key, "_")[1]))
			saveNodeData(node)
		end

		if need_send_city_daily_reward and city.city_data.status == 1 and city.city_data.groupid ~= nil then
			Tools._print("sendGroup_daily_CityReward...  ", city.city_data.id)
			PlanetCache.sendGroupCityReward( city.city_data.groupid, cityConf.EVERYDAY_AWARD, Lang.planet_city_daily_reward_title, Lang.planet_city_daily_reward_msg)

			--if city.city_data.user_name ~= nil then
			--	sendUserCityReward(city.city_data.user_name, cityConf.PLAYER_AWARD, Lang.planet_city_daily_reward_title, Lang.planet_city_daily_reward_msg)
			--end
		end
	end]]
end

function PlanetCache.getWangzuo()
	if Tools.isEmpty(planet_wangzuo_list) == false then
		return planet_wangzuo_list[1]
	end
	return nil
end

function PlanetCache.gmupdateWangZuo(status)
	Tools._print("gmStartWangzuo", status)
	if Tools.isEmpty(planet_wangzuo_list) == true then
		return
	end
	if status == nil or status ~= 2then
		status = 1
	end
	local now_time = os.time()

	local day_id = timeChecker.get_dayid_from(now_time)
	local need_send_wangzuo_daily_reward = false
	if last_wangzuo_daily_reward_dayid ~= day_id then
		need_send_wangzuo_daily_reward = true
		last_wangzuo_daily_reward_dayid = day_id
		db:set("WANGZUO_DAILY_DAYID", tostring(day_id))
	end	

	for i,wangzuo in ipairs(planet_wangzuo_list) do
		wangzuo.wangzuo_data.status = status
		wangzuo.wangzuo_data.status_begin_time = now_time
		local cityConf = CONF.PLANETCITY.get(wangzuo.wangzuo_data.id)
		if (status == 1) then	

			PlanetCache.WangZuoGuardeBack(now_time, wangzuo.wangzuo_data.guarde_list)
			wangzuo.wangzuo_data.user_name = wangzuo.wangzuo_data.old_user_name
			wangzuo.wangzuo_data.old_user_name = nil
			wangzuo.wangzuo_data.groupid = wangzuo.wangzuo_data.old_groupid
			wangzuo.wangzuo_data.old_groupid = ""
			wangzuo.wangzuo_data.guarde_list = {}

			
			PlanetCache.SetWangZuoOccupy(wangzuo.wangzuo_data)

			if wangzuo.wangzuo_data.groupid ~= nil and wangzuo.wangzuo_data.groupid ~= "" then
				if hasFirstRewardMark(wangzuo.global_key, wangzuo.wangzuo_data.groupid) == false then
					PlanetCache.sendGroupCityReward( wangzuo.wangzuo_data.groupid, cityConf.FIRST_AWARD, Lang.planet_wangzuo_first_reward_title, Lang.planet_wangzuo_first_reward_msg)
					PlanetCache.addFirstRewardMark(wangzuo.global_key, wangzuo.wangzuo_data.groupid)
				end

			end
			PlanetCache.SetTowerStatus(now_time, wangzuo,1)
		else
			PlanetCache.WangZuoGuardeBack(now_time, wangzuo.wangzuo_data.guarde_list)

			wangzuo.wangzuo_data.occupy_begin_time = now_time
			wangzuo.wangzuo_data.old_groupid = wangzuo.wangzuo_data.groupid
			wangzuo.wangzuo_data.old_user_name = wangzuo.wangzuo_data.user_name
			wangzuo.wangzuo_data.user_name = nil 
			wangzuo.wangzuo_data.groupid = ""
			wangzuo.wangzuo_data.guarde_list = {}

			wangzuo_title_list = {}
			saveWangZuoTitle()

			Tools._print("open wangzuo status", wangzuo.wangzuo_data.id, wangzuo.wangzuo_data.status)
			PlanetCache.SetTowerStatus(now_time, wangzuo,2)

			last_wangzuo_open_fight_time = now_time
		end

		local node = PlanetCache.getNodeByID(tonumber(Tools.split(wangzuo.global_key, "_")[1]))
		saveNodeData(node)
		Tools._print("wangzuo.global_key",wangzuo.global_key)

		if wangzuo.wangzuo_data.status == 1 and wangzuo.wangzuo_data.groupid ~= nil then
			Tools._print("gm sendGroup_daily_wangzuoReward...  ", wangzuo.wangzuo_data.id," group=",wangzuo.wangzuo_data.groupid)
			PlanetCache.sendGroupCityReward( wangzuo.wangzuo_data.groupid, cityConf.EVERYDAY_AWARD, Lang.planet_wangzuo_daily_reward_title, Lang.planet_wangzuo_daily_reward_msg)
		end
		Tools._print("updateWangzuo status ",wangzuo.wangzuo_data.status,wangzuo.wangzuo_data.status_begin_time)
	end
	Tools._print("gmStartWangzuo ok", status)
end


local function updateTower(now_time)
	if Tools.isEmpty(planet_wangzuo_tower_list) or Tools.isEmpty(planet_wangzuo_list) then
		return
	end
	local wangzuo = planet_wangzuo_list[1]
	if wangzuo == nil then
		return
	end
	local tower_attack_time = CONF.PARAM.get("tower_attack_time").PARAM
	local tower_attack_hp_rate = CONF.PARAM.get("tower_attack_hp_rate").PARAM
	for i,tower in  ipairs(planet_wangzuo_tower_list) do
		if tower.tower_data.status == 2 and 
			((tower.tower_data.groupid ~= nil and tower.tower_data.groupid ~= "" and tower.tower_data.groupid ~= wangzuo.wangzuo_data.groupid)
			or ((tower.tower_data.groupid == nil or tower.tower_data.groupid == "") and tower.tower_data.user_name ~=  wangzuo.wangzuo_data.user_name))then
			if tower.tower_data.is_attack == true and  now_time - tower.tower_data.occupy_begin_time >= tower_attack_time then
				tower.tower_data.occupy_begin_time = now_time
				tower.tower_data.attack_hp = {}
				for i,army_key in ipairs(wangzuo.wangzuo_data.guarde_list) do
					local enemy_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
					local enemy_army = PlanetCache.getArmy(army_key)
					local attack_hp = {
						army_key = army_key ,
						ship_hp_list = {0,0,0,0,0,0,0,0,0,},
					}
					for i,v in ipairs(enemy_army.ship_list) do
						if enemy_army.lineup_hp[v.position] > 0 then
							local hp = v.attr[CONF.EShipAttr.kHP]*tower_attack_hp_rate
							if hp < 1 then
								hp = 1
							end							
							enemy_army.lineup_hp[v.position] = enemy_army.lineup_hp[v.position] - hp
							if (enemy_army.lineup_hp[v.position] <= 0) then
								enemy_army.lineup_hp[v.position] = 0
								Tools.shipSubDurable( v, 3, 0, enemy_army.tech_durable_param )
							end
							attack_hp.ship_hp_list[v.position] = hp
						end
					end
					table.insert(tower.tower_data.attack_hp, attack_hp)
					PlanetCache.saveUserData(enemy_user)
					Tools.print_t(enemy_army)

				end

				local node = PlanetCache.getNodeByID(tonumber(Tools.split(tower.global_key, "_")[1]))
				saveNodeData(node)
			end
		end
	end
	local node = PlanetCache.getNodeByID(tonumber(Tools.split(wangzuo.global_key, "_")[1]))
	saveNodeData(node)
end

--王座遣返驻扎舰队
function PlanetCache.WangZuoGuardeBack(now_time, guarde_list)

	if Tools.isEmpty(guarde_list) == false then
		for _, army_key in ipairs(guarde_list) do
			local planet_user = PlanetCache.getUser(Tools.split(army_key, "_")[1])
			Tools._print("WangZuoGuardeBack planet_user",army_key)
			Tools.print_t(planet_user)
			for _,army in ipairs(planet_user.army_list) do
				Tools._print("WangZuoGuardeBack",army.status_machine)
				
				Tools.print_t(army)
				PlanetStatusMachine[army.status_machine].back(now_time, planet_user, army)

				if Tools.isEmpty(army.army_key_list) == false then
					for i,army_key_tmp in ipairs(army.army_key_list) do
						local army_tmp = PlanetCache.getArmy(army_key_tmp)
						local user_tmp = PlanetCache.getUser(Tools.split(army_key_tmp,"_")[1])
						PlanetStatusMachine[army.status_machine].back(now_time, user_tmp, army_tmp)
					end
					planet_army.army_key_list = nil
				end
			end
		end
	end
end
local function updateWangzuo( now_time )

	if Tools.isEmpty(planet_wangzuo_list) == true then
		return
	end
	local first_start_time = CONF.PARAM.get("throne_first_open").PARAM
	local date = os.date("*t", now_time)
	local firstID = CONF.PLANETCITY["index"][CONF.PLANETCITY.count()]
	for i=1,#CONF.PLANETCITY[firstID].TIME/2 do
		if date.wday == CONF.PLANETCITY[firstID].TIME[i*2-1] and date.hour == CONF.PLANETCITY[firstID].TIME[i*2] and date.min == 0 then --注释这里可以直接进入战争状态
			Tools._print("updateWangzuo time ",date.wday,date.hour,"start")
			if now_time - last_wangzuo_open_fight_time > 60 then --前后间隔起码大于一分钟吧
				for i,wangzuo in ipairs(planet_wangzuo_list) do
					if (--[[true or]] now_time - wangzuo.wangzuo_data.create_time > first_start_time) then
						if wangzuo.wangzuo_data.status == 1 then
							wangzuo.wangzuo_data.status = 2
							Tools._print("updateWangzuo status ",wangzuo.wangzuo_data.status)

							PlanetCache.WangZuoGuardeBack(now_time, wangzuo.wangzuo_data.guarde_list)

							wangzuo.wangzuo_data.occupy_begin_time = now_time
							wangzuo.wangzuo_data.old_groupid = wangzuo.wangzuo_data.groupid
							wangzuo.wangzuo_data.old_user_name = wangzuo.wangzuo_data.user_name
							wangzuo.wangzuo_data.user_name = nil 
							wangzuo.wangzuo_data.groupid = ""
							wangzuo.wangzuo_data.guarde_list = {}
							wangzuo.wangzuo_data.status_begin_time = now_time

							wangzuo_title_list = {}
							saveWangZuoTitle()

							Tools._print("open wangzuo status", wangzuo.wangzuo_data.id, wangzuo.wangzuo_data.status)
							PlanetCache.SetTowerStatus(now_time, wangzuo,2)

							local node = PlanetCache.getNodeByID(tonumber(Tools.split(wangzuo.global_key, "_")[1]))
							saveNodeData(node)
						end
					end
				end

				last_wangzuo_open_fight_time = now_time
			end
		end
	end

	local day_id = timeChecker.get_dayid_from(now_time)
	local need_send_wangzuo_daily_reward = false
	if last_wangzuo_daily_reward_dayid ~= day_id then
		need_send_wangzuo_daily_reward = true
		last_wangzuo_daily_reward_dayid = day_id
		db:set("WANGZUO_DAILY_DAYID", tostring(day_id))
	end	

	for i,wangzuo in ipairs(planet_wangzuo_list) do

		local cityConf = CONF.PLANETCITY.get(wangzuo.wangzuo_data.id)

		if wangzuo.wangzuo_data.status == 2 and now_time - wangzuo.wangzuo_data.status_begin_time >= cityConf.DURATION then

			wangzuo.wangzuo_data.status = 1
			wangzuo.wangzuo_data.status_begin_time = now_time		

			PlanetCache.WangZuoGuardeBack(now_time, wangzuo.wangzuo_data.guarde_list)

			wangzuo.wangzuo_data.user_name = wangzuo.wangzuo_data.old_user_name
			wangzuo.wangzuo_data.old_user_name = nil
			wangzuo.wangzuo_data.groupid = wangzuo.wangzuo_data.old_groupid
			wangzuo.wangzuo_data.old_groupid = ""
			wangzuo.wangzuo_data.guarde_list = {}
			
			PlanetCache.SetWangZuoOccupy(wangzuo.wangzuo_data)

			if wangzuo.wangzuo_data.groupid ~= nil and wangzuo.wangzuo_data.groupid ~= "" then
				if hasFirstRewardMark(wangzuo.global_key, wangzuo.wangzuo_data.groupid) == false then
					PlanetCache.sendGroupCityReward( wangzuo.wangzuo_data.groupid, cityConf.FIRST_AWARD, Lang.planet_wangzuo_first_reward_title, Lang.planet_wangzuo_first_reward_msg)
					PlanetCache.addFirstRewardMark(wangzuo.global_key, wangzuo.wangzuo_data.groupid)
				end				
			end
			PlanetCache.SetTowerStatus(now_time, wangzuo,wangzuo.wangzuo_data.status)
			local node = PlanetCache.getNodeByID(tonumber(Tools.split(wangzuo.global_key, "_")[1]))
			saveNodeData(node)
		end

		--if need_send_wangzuo_daily_reward and wangzuo.wangzuo_data.status == 1 and wangzuo.wangzuo_data.groupid ~= nil then
		--	print("sendGroup_daily_wangzuoReward...  ", wangzuo.wangzuo_data.id)
		--	PlanetCache.sendGroupCityReward( wangzuo.wangzuo_data.groupid, cityConf.EVERYDAY_AWARD, Lang.planet_wangzuo_daily_reward_title, Lang.planet_wangzuo_daily_reward_msg)
		--end
	end

	updateTower(now_time)

end

function PlanetCache.SetTowerStatus(now_time,wangguo,status)
	if wangguo == nil or Tools.isEmpty(planet_wangzuo_tower_list) then
		return
	end
	Tools._print("planet_wangzuo_tower_list",#planet_wangzuo_tower_list)
	Tools.print_t(planet_wangzuo_tower_list)
	for i,tower in ipairs(planet_wangzuo_tower_list) do
		tower.tower_data.status = status
		tower.tower_data.is_attack = false
		tower.tower_data.occupy_begin_time = 0
		if status == 1 then
			PlanetCache.WangZuoGuardeBack(now_time,tower.tower_data.guarde_list)
			tower.tower_data.groupid = wangguo.wangzuo_data.groupid
			tower.tower_data.user_name = wangguo.wangzuo_data.user_name
			tower.tower_data.guarde_list = {}
			tower.tower_data.attack_hp = {}
		else
			PlanetCache.WangZuoGuardeBack(now_time,tower.tower_data.guarde_list)

			tower.tower_data.groupid = "" 
			tower.tower_data.user_name = nil
			tower.tower_data.guarde_list = {}
			tower.tower_data.attack_hp = {}
		end
	end
end

local function updateRes(now_time)

	local node_update_list = {}
	for id,node in pairs(node_id_list) do
		if id > 1 then
			local nodeConf = CONF.PLANETWORLD.get(id)

			local nodeLevelConf = CONF.PLANETNODELEVEL.get(nodeConf.LV)

			resetRes(node, nodeLevelConf.RES_MAX_NUM, nodeLevelConf.RES_ID_LIST)
		
			resetRuins(node, nodeLevelConf.RUINS_MAX_NUM, nodeLevelConf.RUINS_ID_LIST)

			saveNodeData(node)

			table.insert(node_update_list, id)
		end
	end
	PlanetCache.broadcastUpdate("", node_update_list)
end

local wangzuo_tiem_t = 0
function PlanetCache.doTimer( )
	local now_time = os.time()

	if Tools.isEmpty(planet_user_list) == false then
		for user_name,user in pairs(planet_user_list) do

			local base = PlanetCache.getElement(user.base_global_key)
			if base then
				if base.base_data.destroy_value > 0 then
					if (now_time - base.base_data.last_hurt_time > destroy_resub_time) then
						if base.base_data.last_sub_destroy_value_time == nil or (now_time - base.base_data.last_sub_destroy_value_time > destroy_sub_time) then
							base.base_data.destroy_value = math.max(base.base_data.destroy_value - fix_value, 0)
							base.base_data.last_sub_destroy_value_time = now_time
						end
					end
				end

				if base.base_data.shield_start_time ~= nil and base.base_data.shield_start_time > 0 then
					if first_loop_time then
						base.base_data.shield_time = base.base_data.shield_time + CONF.PARAM.get("shield_maintenance_compensate").PARAM 
					end

					if now_time - base.base_data.shield_start_time >= base.base_data.shield_time then
						base.base_data.shield_start_time = nil
						base.base_data.shield_time = nil
						base.base_data.shield_type = nil
					end
				end

				if Tools.isEmpty(user.army_list) == false then
					for _,army in ipairs(user.army_list) do
						PlanetStatusMachine[army.status_machine].doLogic(now_time, user, army)
					end
				end
			end
		end
	end

	updateCity(now_time)
	updateWangzuo(now_time)

	if (now_time - last_boss_reflesh) >= boss_reset_time then
		Tools._print("reflesh boss")
		reflushBoss(now_time)
		last_boss_reflesh = now_time
	end
	updateBoss(now_time)

	if (now_time - last_monster_reflesh >= monster_reset_time) then
		Tools._print("reflesh monster")
		ClearMonster()
		reflushMonster(now_time)
		last_monster_reflesh = now_time
	end
	updateMonster(now_time)

	if (now_time - last_res_reflesh) >= res_reset_time then
		Tools._print("reflesh res")
		updateRes(now_time)
		last_res_reflesh = now_time
	end

	first_loop_time = false

	--因为是新加,所以王座可能没初始化过,所以另外初始化,以后可以删除
	if Tools.isEmpty(planet_wangzuo_list) or Tools.isEmpty(planet_wangzuo_tower_list) then
		wangzuo_tiem_t = 1
		local cur_time = os.time()
		if Tools.isEmpty(planet_wangzuo_list) == false then
			PlanetCache.removeElement(planet_wangzuo_list[1].global_key)
			planet_wangzuo_list = {}
		end
		if Tools.isEmpty(planet_wangzuo_tower_list) == false then
			for _,tower in  ipairs(planet_wangzuo_tower_list) do
				PlanetCache.removeElement(tower.global_key)
			end
			planet_wangzuo_tower_list = {}
		end
		local node = PlanetCache.getNodeByID(1)
		if node~=nil then
			Tools._print("resetWangzuo start")
			resetWangzuo(node, cur_time)
			Tools._print("resetWangzuo111 ok")
			saveNodeData(node)
			Tools._print("resetWangzuo222 ok")
		end
		
	end

end

return PlanetCache