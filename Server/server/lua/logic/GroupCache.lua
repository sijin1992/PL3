local kc = require "kyotocabinet"
local db = kc.DB:new()-- + kc.DB.ONOLOCK

local guid_list = {}

local disband_list = {}

local group_list = {}

local sort_group_list = {}

local rank_update_time = 3600
local rank_timer = 3601

local cur_day_0 = get_dayid_from(os.time(), 0)

if not db:open("GroupMain.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
    error("GroupMain.kch open err")
else
	local num = 0
	db:iterate(

		function(k,v)

			local data = Tools.decode("GroupMainData", v)

			if string.sub(k,1,3) == "SID" then

				local sid = string.sub(k, 4)

				guid_list[sid] = 1
	
			elseif string.sub(k,1,3) == "DIS" then

                			local gid = string.sub(k, 4)
                			disband_list[gid] = 1

                		elseif k == "DAYID0" then
             	   		cur_day_0 = tonumber(v)
                		else
                			group_list[k] = Tools.decode("GroupMainData", v)

				num = num + 1
				sort_group_list[num] = group_list[k]

				group_list[k].rank = num

			end
		end, false
	)
end


local GroupCache = {}

function GroupCache.add(groupid, group_main)
	local isCheck = group_list[groupid] == nil
	if isCheck then

		local group_buff = Tools.encode("GroupMainData", group_main)
		isCheck = db:set(groupid, group_buff)

		group_list[groupid] = group_main
		sort_group_list[GroupCache.count() + 1] = group_list[groupid]

		guid_list[groupid] = 1
		db:set("SID"..groupid, 1)
	end
	
	return isCheck
end

function GroupCache.disband( groupid )
	local data = group_list[groupid]

	if data == nil then
		return false
	end

	table.remove(sort_group_list, group_list[groupid].rank)
	for i,v in ipairs(sort_group_list) do
		sort_group_list[i].rank = i
		local group_main_buff = Tools.encode("GroupMainData", sort_group_list[i])
		db:set(sort_group_list[i].groupid, group_main_buff)
	end

	group_list[groupid] = nil

	db:remove(groupid)

	disband_list[groupid] = 1
	db:set("DIS"..groupid, 1)
	return true
end

function GroupCache.isDisband( groupid )
	if disband_list[groupid] == nil then
		return false
	end
	return true
end

function GroupCache.hasNickName(nick_name)

	for k,group_main in pairs(group_list) do
		if group_main and group_main.nickname == nick_name then
			return true
		end
	end

	return false
end

function GroupCache.getGroupId(user_name)
	local svr_id = tonumber(string.sub(user_name, -5))
	local guid = 0
	for k,group_main in pairs(guid_list) do		
		local sid = tonumber(string.sub(k, -5))
		local gid = tonumber(string.sub(k, 4, string.len(k)-5))
		if sid and gid and sid == svr_id and gid > guid then
			guid = gid
		end
	end
	guid = guid + 1
	local groupid = string.format("%05d%d", guid, svr_id)
	return groupid
end

function GroupCache.getGroupMain(groupid)

	return group_list[groupid]
end

function GroupCache.getGroupMainByName( group_name )
	
	for id,v in pairs(group_list) do
		if v.nickname == group_name then
			return v
		end
	end
	return nil
end

function GroupCache.getGroupAllFightPower(groupid)
	local group_data = group_list[groupid]
	if group_data == nil then
		return 0
	end

	local power = 0
	for i,v in ipairs(group_data.user_list) do
		local other_user_info = UserInfoCache.get(v.user_name)
		if other_user_info then
			power = power + other_user_info.power
		end
	end

	return power
end

function GroupCache.getGroupByRank( rank )
	local group_data = sort_group_list[rank]

	if group_data then
		return group_data
	end
	return nil
end
function GroupCache.GetGroupLeader( group_main )
	if group_main == nil then
		return nil
	end
	for i,v in ipairs(group_main.user_list) do
		if v.job == GolbalDefine.enum_group_job.leader then
			return v
		end
	end
	return nil
end
function GroupCache.toOtherGroupInfo( group_main )
	if group_main == nil then
		return nil
	end

	local leader_name
	for i,v in ipairs(group_main.user_list) do
		if v.job == GolbalDefine.enum_group_job.leader then
			leader_name = v.nickname
		end
	end

	local other_group_info = {
		groupid = group_main.groupid,
		nickname = group_main.nickname,
		icon_id = group_main.icon_id,
		level = group_main.level,
		power = GroupCache.getGroupAllFightPower(group_main.groupid),
		leader_name = leader_name,
	}
	return other_group_info
end

function GroupCache.merge( group_main )
	local cache_group_main = GroupCache.getGroupMain(group_main.groupid)
	if not cache_group_main then
		LOG_ERROR(string.format("groupid %s not find in cache", group_main.groupid))
	end

	if group_main.rank ~= cache_group_main.rank then
		group_main.rank = cache_group_main.rank
	end
	
	group_main.help_list = cache_group_main.help_list

	group_main.worship_value = cache_group_main.worship_value
	group_main.today_worship_times = cache_group_main.today_worship_times

	group_main.tech_list = cache_group_main.tech_list
	group_main.occupy_city_list = cache_group_main.occupy_city_list
	group_main.enlist_list = cache_group_main.enlist_list
	group_main.attack_our_list = cache_group_main.attack_our_list
end

function GroupCache.update(group_main, user_name, need_cast)

	if GroupCache.isDisband( group_main.groupid ) == true then
		return false
	end
	
	local pre_group_main = GroupCache.getGroupMain(group_main.groupid)
	local pre_sort_group_main = sort_group_list[group_main.rank]

	if pre_group_main == nil or pre_sort_group_main == nil then
		LOG_ERROR("GroupCache.update error !!!!!!!!!!!!!!!!!!!!!!!")
		return false
	end

	local group_main_buff = Tools.encode("GroupMainData", group_main)
	db:set(group_main.groupid, group_main_buff)

	group_list[group_main.groupid] = group_main

	sort_group_list[group_main.rank] = group_main

	if user_name then
		for i,group_user in ipairs(group_main.user_list) do
			if group_user.user_name == user_name then
				group_user.last_act = os.time()
			end
		end
	end

	if need_cast == true then
		local recv_list = {}
		local user_list = group_main.user_list or {}
		for k,v in ipairs(user_list) do
			table.insert(recv_list, v.user_name)
		end

		local cmd = 0x16ff
		local group_update =
		{
			group_main = group_main,
			user_name = user_name,
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

	return true
end

function GroupCache.count()
	return rawlen(sort_group_list)
end

function GroupCache.search( groupid, group_name, page )

	if groupid and groupid ~= "" then

		local group_main = GroupCache.getGroupMain(groupid)
		if group_main then
			return {group_main}
		end
	elseif group_name and group_name ~= "" then

		local group_main = GroupCache.getGroupMainByName(group_name)
		if group_main then
			return {group_main}
		end

	elseif page > 0 then

		local list = {}
		for index = (page - 1) * GolbalDefine.group_num_in_page + 1, page * GolbalDefine.group_num_in_page do
			if sort_group_list[index] then

				table.insert(list, sort_group_list[index])
			else
				break
			end
		end

		return list
	end

	return nil
end

local function sort_func(a , b)

	local power_a = GroupCache.getGroupAllFightPower(a.groupid)
	local power_b = GroupCache.getGroupAllFightPower(b.groupid)

	if power_a > power_b then
		return true
	elseif power_a == power_b then
		if a.level > b.level then
			return true
		elseif a.level == b.level then
			return tonumber(a.groupid) > tonumber(b.groupid)
		end
		return false
	else
		return false
	end
end

local function sortRank()
	table.sort(sort_group_list, sort_func)

	for i,v in ipairs(sort_group_list) do
		v.rank = i
		local group_main_buff = Tools.encode("GroupMainData", v)
		db:set(v.groupid, group_main_buff)
	end
end

local function update_at_0am()

	for k,group_main in pairs(group_list) do
		if type(group_main) == "table" then
			group_main.worship_value = 0
			group_main.today_worship_times = 0
			local group_main_buff = Tools.encode("GroupMainData", group_main)
			db:set(group_main.groupid, group_main_buff)
		end
	end
end

function GroupCache.doTimer()

	local now_time = os.time()

	rank_timer = rank_timer + 10
	if rank_timer > rank_update_time then
		sortRank()
		rank_timer = 0
	end

	local new_day0 = get_dayid_from(now_time, 0)
	if new_day0 ~= cur_day_0 then
		update_at_0am()
		cur_day_0 = new_day0
		db:set("DAYID0", cur_day_0)
	end
end

return GroupCache
