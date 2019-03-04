


local activity_list

local GolbalActivity = {}

function updateActivity()

	activity_list = {}

	local conf_id_list = CONF.ACTIVITY.getIDList()
	for _,id in ipairs(conf_id_list) do
		local conf = CONF.ACTIVITY.get(id)
		if conf.START_TIME > 10000 then

			activity_list[conf.ID] = {id = conf.ID, type = conf.TYPE, start_time = getTimeStampFrom(conf.START_TIME), end_time = getTimeStampFrom(conf.END_TIME)}
		else
			activity_list[conf.ID] = {id = conf.ID, type = conf.TYPE, start_time = conf.START_TIME, end_time = conf.END_TIME}
		end
	end
end

updateActivity()

function GolbalActivity.isOpen( id,  cur_time, user_info)

	local activity = activity_list[id]
	if activity == nil then
		return false
	end
	if activity.start_time == 0 then
		return true
	elseif activity.start_time == 1 and user_info then
		
		return cur_time >= user_info.timestamp.regist_time and cur_time < (user_info.timestamp.regist_time + activity.end_time * 86400)
	else
		return cur_time >= activity.start_time and cur_time < activity.end_time
	end
end

function GolbalActivity.getDayIndex( id, cur_time, user_info  ) --当前是活动的第几天
	local activity = activity_list[id]
	if activity == nil or activity.start_time == 0 then
		return 0
	end
	local start_time
	local end_time
	if activity.start_time == 1 then
		start_time = user_info.timestamp.regist_time
		end_time = user_info.timestamp.regist_time + activity.end_time * 86400
	else
		start_time = activity.start_time
		end_time = activity.end_time
	end

	if cur_time < start_time then
		return 0
	end
	local index = math.floor(cur_time / 86400) - math.floor(start_time / 86400)

	if index==7 then
		if cur_time < end_time then
			index = index-1
		end
	end
	return index + 1
end

function GolbalActivity.getActivityList( cur_time, user_info )

	local list = {}
	for id, activity in pairs(activity_list) do
		if GolbalActivity.isOpen(id, cur_time, user_info) == true then
			table.insert(list, id)
		end
	end

	return list
end

function GolbalActivity.createActivityInfo( id, user_info )
	local activity = activity_list[id]
	if activity == nil then
		return nil
	end
	
	local info = Tools.clone(activity)

	if info.start_time == 1 then
		info.start_time = user_info.timestamp.regist_time
		info.end_time = user_info.timestamp.regist_time + activity.end_time * 86400
	end
	return info
end

function GolbalActivity.updateActivityData(cur_time, user_info)

	CONF:load({"Activity"})

	if Tools.isEmpty(user_info.activity_list) == true then
		return 
	end

	for index = #user_info.activity_list, 1, -1 do
		local info = user_info.activity_list[index]
		local bDel = false
		if GolbalActivity.isOpen( info.id,  cur_time, user_info) == false then
			table.remove(user_info.activity_list, index)
			bDel = true
		end
		local activity = activity_list[info.id]
		if activity then
			if bDel == false and activity.TYPE == 17 and info.every_day_get_day then
				local playertime = info.every_day_get_day.start_time
				local wd = os.date("%W",cur_time)
				local wd2 = os.date("%W",playertime)
				if wd ~= wd2 then
					table.remove(user_info.activity_list, index)
					bDel = true
				end
			end

			if bDel == false and activity.TYPE == 20 and info.change_item_data then
				local d = 0
				local d2 = 0
				if info.change_item_data.day_time then
					d = os.date("%j",cur_time)
					d2 = os.date("%j",info.change_item_data.day_time)
				end
				if d ~= d2 then
					if Tools.isEmpty(info.change_item_data.item_list) then
						for i = #info.change_item_data.item_list, 1, -1 do
							local conf = CONF.CHANGEITEM.get(info.change_item_data.item_list[i].key)
							if conf and  conf.LIMIT_TYPE == 1 then
								table.remove(info.change_item_data.item_list, i)
							end
						end
					end
				end
			end
		end
	end
end

function GolbalActivity.AddActivityMoney(money, cur_time, user_info)
	local conf_id_list = CONF.ACTIVITY.getIDList()
	for _,id in ipairs(conf_id_list) do
		local conf = CONF.ACTIVITY.get(id)
		if conf.TYPE == 17 and GolbalActivity.isOpen( conf.ID,  cur_time, user_info) then
			local info = CoreUser.getActivity(conf.ID, user_info)
			if not info then
				info = CoreUser.addActivity(conf.ID, user_info)
				info.every_day_get_day={
					get_day = 0 ,
					start_time = cur_time ,
					add_money = 0 ,
				}
			end
			if info then
				info.every_day_get_day.add_money = info.every_day_get_day.add_money + money
			end
		end
		if conf.TYPE == 18 and GolbalActivity.isOpen( conf.ID,  cur_time, user_info) then
			local info = CoreUser.getActivity(conf.ID, user_info)
			if not info then
				info = CoreUser.addActivity(conf.ID, user_info)
				info.turntable_data = 
				{
					add_money = 0,
					turntable_num = CONF.PARAM.get("turntable_add_num").PARAM[1],
				}
			end
			local confT = CONF.ACTIVITY_TURNTABLE.get(1)
			if confT == nil then
				if info then
					info.turntable_data.add_money = info.turntable_data.add_money + money
				end
			else
				local nowmoney = math.floor(info.turntable_data.add_money%confT.COST_NUM)
				if info then
					info.turntable_data.add_money = info.turntable_data.add_money + money
				end
				nowmoney = nowmoney + money
				local count = math.floor(nowmoney/confT.COST_NUM)
				info.turntable_data.turntable_num = info.turntable_data.turntable_num + count
				Tools._print("AddActivityMoney TURNTABLE",nowmoney,money,info.turntable_data.turntable_num)
			end
		end
	end
end

function GolbalActivity.doTimer()
	updateActivity()
end

return GolbalActivity
