
local kc = require "kyotocabinet"
local db = kc.DB:new()-- + kc.DB.ONOLOCK

local cur_3_day = get_dayid_from(os.time() + 86400 * 3, 0) * 86400

local ArenaCache = {}

ArenaCache.min = 50

local RecordMax = 10

local rank_list = {}

local info_list = {}

local record_list = {}

local totleEntry = 0

local last_reflesh = os.time()


local function createRobotData(robot_id)

	local conf = CONF.ROBOT.get(robot_id)

	local data = {
		rank = 0,
		nickname = conf.NICKNAME,
		power = conf.POWER,
		user_name = string.format("robot%d",conf.ID),
		score = conf.ARENA_SCORE,
		icon_id = conf.ICON_ID,
		level = conf.LEVEL,
		ship_id_list = conf.MONSTER_LIST,
	}
	local level_list = {}
	for i,v in ipairs(conf.MONSTER_LIST) do
		local level = 0
		if v > 0 then
			level = CONF.AIRSHIP.get(v).LEVEL
		end
		level_list[i] = level
	end
	data.ship_level_list = level_list
	return data
end

local function sort_func(a , b)

	if a.score > b.score then
		return true
	elseif a.score == b.score then

		return a.power > b.power
	else
		return false
	end
end

local function sort(  )

	table.sort(rank_list, sort_func)

	for i,v in ipairs(rank_list) do
		v.rank = i
	end

	--Tools.print_t(rank_list)
end

if not db:open("Arena.kch", kc.DB.OWRITER + kc.DB.OCREATE) then

	error("Arena.kch open err")
else

	db:iterate(
		function(k,v)

			if k == "DAYID3" then

				 cur_3_day = tonumber(v)

			elseif string.sub(k,1,6) == "RECORD" then

				local data = Tools.decode("ArenaRecordDataList", v)
				record_list[data.user_name] = data

			else
				local data = Tools.decode("ArenaInfoData", v)
				-- print("key",k)
				-- Tools.print_t(data)

				info_list[k] = data

				totleEntry = totleEntry + 1

				rank_list[totleEntry] = data
			end

			
		end,


	false)

	local robot_id = 0
	if totleEntry < ArenaCache.min then

		local start = totleEntry + 1

		for i=start,ArenaCache.min do
			
			totleEntry = totleEntry + 1

			robot_id = robot_id +1

			local robot = createRobotData(robot_id)
			
			rank_list[totleEntry] = robot
			info_list[robot.user_name] = robot 
		end
	end

	sort()
end

local function createRecordList( user_name )
	record_list[user_name] = {
		user_name = user_name,
	}
end

function ArenaCache.setCurrentEnemy( user_name, enemy_user_name )
	if Tools.isEmpty(record_list[user_name]) == true then
		createRecordList(user_name)
	end

	record_list[user_name].current_enemy_user_name = enemy_user_name

	local info_buff = Tools.encode("ArenaRecordDataList", record_list[user_name])

	return db:set("RECORD"..user_name, info_buff)
end

function ArenaCache.getCurrentEnemy( user_name)
	if Tools.isEmpty(record_list[user_name]) == true then
		return nil
	end
	return record_list[user_name].current_enemy_user_name
end

function ArenaCache.addRecord(user_name, info)

	if user_name == nil or string.sub(user_name,1,5) == "robot" then
		return
	end

	if Tools.isEmpty(record_list[user_name]) == true then
		createRecordList(user_name)
	end

	if record_list[user_name].current_enemy_user_name == nil or record_list[user_name].current_enemy_user_name == "" then
		return
	end

	info.enemy_user_name = record_list[user_name].current_enemy_user_name
	record_list[user_name].current_enemy_user_name = nil

	if Tools.isEmpty(record_list[user_name].record_info_list) == true then
		record_list[user_name].record_info_list = {}
	end

	if #record_list[user_name].record_info_list >= RecordMax then
		table.remove(record_list[user_name].record_info_list, 1)
	end

	table.insert(record_list[user_name].record_info_list, info)

	local info_buff = Tools.encode("ArenaRecordDataList", record_list[user_name])

	return db:set("RECORD"..user_name, info_buff)
end

function ArenaCache.getRecord(user_name)

	if record_list[user_name] == nil then
		return nil
	end

	local list = Tools.clone(record_list[user_name])

	for i,v in ipairs(list.record_info_list) do
		list.record_info_list[i].other_user_info = UserInfoCache.get(v.enemy_user_name)
	end
	return list
end


function ArenaCache.getByRank( rank )
	return rank_list[rank]
end

function ArenaCache.getByRanks(ranks)
	local list = {}
	for i,rank in ipairs(ranks) do
		table.insert(list, rank_list[rank])
	end
	return list
end

function ArenaCache.getByMyRank( rank )

	local function getCount( list )
		local count = 0
		for i,v in pairs(list) do
			count = count + 1
		end

		return count
	end

	if rank == 0 then
		rank = totleEntry
	end
	
	local high = 5
	local rankNum = 20
	local low

	local list = {}

	local highList = {}
	for i=rankNum, 1, -1 do
		local index =  rank - i
		if index > 0 then
			table.insert(highList, index)
		else
			break
		end
	end

	for i=1,high do
		local count = #highList
		if count < 1 then
			break
		end
		local index = math.random(1, count )
		local temp = highList[index]

		list[temp] = true
		table.remove(highList, index)
	end

	low = high - getCount(list)

	if low > 0  then
		local lowList = {}
		for i=1,rankNum do
			if (rank + i) >= totleEntry then
				break
			end
			table.insert(lowList, rank + i)
		end

		if Tools.isEmpty(lowList) == false then
			for i=1,low do
				local index = math.random(1, #lowList )
				local temp = lowList[index]

				list[temp] = true
				table.remove(lowList, index)
			end
		end
	end

	local return_list = {}
	local count = 0
	for k,v in pairs(list) do
		table.insert(return_list, rank_list[k])
		count = count  +1
	end
	return return_list
end

function ArenaCache.getByUserName(user_name)

	return info_list[user_name]
end


function ArenaCache.set( data )

	-- print("ArenaCache.set")
	-- Tools.print_t(data)

	if info_list[data.user_name] then
		--print("has")
	else
		totleEntry = totleEntry + 1
		rank_list[totleEntry] = data
		data.rank = totleEntry
		data.score = GolbalDefine.arena_init_score
	end

	info_list[data.user_name] = data

	local info_buff = Tools.encode("ArenaInfoData", data)

	return db:set(data.user_name, info_buff)
end

function ArenaCache.remove( user_name )
	if info_list[user_name] == nil then
		return 
	end
	if info_list[user_name].rank > 0 then
		table.remove(rank_list,  info_list[user_name].rank)
		sort()
	end

	totleEntry = totleEntry - 1
	info_list[user_name] = nil
	db:remove(user_name)
end

function ArenaCache.interval( rank, down, up )
	local flag1 = false
	if down == 0 then
		flag1 = true
	else
		if rank <= down then
			flag1 = true
		end
	end

	local flag2 = false
	if up == 0 then
		flag2 = true

	else
		if rank >= up then
			flag2 = true
		end
	end
	return flag1 and flag2
end

local function getReward(rank, user_name, cur_time)

	if string.sub(user_name,1,5) == "robot" then
		return
	end

	local item_list = {}
	for _,id in ipairs(CONF.ARENA_REWARD.getIDList()) do
		local conf = CONF.ARENA_REWARD.get(id)

		if conf.TYPE == 2 and ArenaCache.interval(rank, conf.RANKING_DOWN, conf.RANKING_UP) == true then

			for i=1,6 do
				local item_id = conf[string.format("ITEM_ID%d",i)]
				if item_id > 0 then
					table.insert(item_list, {
						id = item_id, 
						num = conf[string.format("ITEM_NUM%d",i)],
						guid = 0,
					})
				end
			end

			local mail = {
				type = 10,
				from = Lang.arena_reword_sender,
				subject = Lang.arena_reword_title,
				message = string.format(Lang.arena_reword_msg, rank),
				item_list = item_list,
				stamp = cur_time,
				guid = 0,
				expiry_stamp = 0,
			}

			RedoList.addMail(user_name, mail)
			break
		end
	end
end

local function reset_rank_score()

	Tools._print("reset_rank_score")

	local info_buff
	for k,v in pairs(info_list) do
		v.score = 0

		info_buff = Tools.encode("ArenaInfoData", v)
		db:set(v.user_name, info_buff)
	end	
end

function ArenaCache.getCur3Day()
	return cur_3_day
end

function ArenaCache.getReflesh()
	return last_reflesh
end

function ArenaCache.doTimer( )
	local now_time = os.time()

	if now_time > cur_3_day then
	--if (now_time - last_reflesh) >= 10 then
		sort()
		for i,v in ipairs(rank_list) do
			getReward(i, v.user_name, now_time)
		end

		reset_rank_score()
		cur_3_day = cur_3_day + 86400 * 3
		db:set("DAYID3", cur_3_day)
	end

	if (now_time - last_reflesh) >= 1800 then
		sort()
		last_reflesh = now_time
	end
end

return ArenaCache