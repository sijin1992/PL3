local CoreUser = {}

function CoreUser.getDailyData(user_info)

	local daily_data = rawget(user_info, "daily_data")
	if Tools.isEmpty(daily_data) then
		daily_data =  {

		}
		rawset(user_info, "daily_data", daily_data)
	end
	return daily_data
end


function CoreUser.userSyncUpdate(user_name, user_sync)
	local cmd = 0x16fd

	local multi_cast = 
	{
		recv_list = {user_name},
		cmd = cmd,
		user_sync = user_sync,
	}
      	local multi_buff = Tools.encode("Multicast", multi_cast)
      	activeSendMessage(user_name, 0x2100, multi_buff)
end

function CoreUser.addRes(index, num, user_info)

	CoreItem.addRes(user_info, index, num)
end

function CoreUser.addExp(num, user_info)

	user_info.exp = user_info.exp + num

	for i=user_info.level,user_info.level + 200 do
		if i > CONF.PLAYERLEVEL.len then
			return
		end
		local conf = CONF.PLAYERLEVEL.get(i)
		if not conf then
			return
		end

		if user_info.exp > conf.EXP_ALL then

		else
			Tools._print("addlevel",i,user_info.exp,conf.EXP_ALL,conf.ID)
			CoreUser.setLevel(i, user_info)
			break
		end
	end
end

function CoreUser.setLevel( num, user_info )
	if num <= 0 or num > CONF.PLAYERLEVEL.len then
		return
	end

	local old = Tools.getMaxStrength(user_info.level)
	local new = Tools.getMaxStrength(num)
	user_info.strength = user_info.strength + (new - old)
	
	local old_level = user_info.level
	user_info.level = num

	local other_user_info = UserInfoCache.get(user_info.user_name)
	if other_user_info then
		other_user_info.level = user_info.level

		UserInfoCache.set(user_info.user_name, other_user_info)

		UserInfoCache.setLevelInterval( other_user_info, old_level )
	end

	if (old_level~=user_info.level) then
		CoreUser.getGiftBag(user_info)
		LOG_STAT( string.format( "%s|%s|%d|%d", "LEVEL_UP", user_info.user_name, old_level, user_info.level ) )
	end
end

function CoreUser.addMoney(num, user_info)
	assert(type(num) == "number")

	assert(num >= 0)

	if num > 999999999 then num = 999999999 end

	user_info.money = user_info.money + num
end

function CoreUser.getActivity( id, user_info )
	if Tools.isEmpty(user_info.activity_list) == true then
		return nil
	end
	for i,v in ipairs(user_info.activity_list) do
		if v.id == id then
			return v
		end
	end
	return nil
end

function CoreUser.addActivity( id, user_info )

	local activity = GolbalActivity.createActivityInfo(id, user_info)
	if Tools.isEmpty(user_info.activity_list) then
		user_info.activity_list = {activity}
	else
		table.insert(user_info.activity_list, activity)
	end
	return activity
end

function CoreUser.getActivityByType( type, user_info)
	if user_info == nil then
		return nil
	end

	local cur_time = os.time()

	local list = GolbalActivity.getActivityList( cur_time, user_info )

	if Tools.isEmpty(list) then
		return nil
	end
	local return_list = {}
	for i,id in ipairs(list) do
		local conf = CONF.ACTIVITY.get(id)
		if conf.TYPE == type then
			local activity = CoreUser.getActivity(id, user_info)
			if not activity then

				activity = CoreUser.addActivity(id, user_info)
			end
			

			if type == CONF.EActivityType.kSevenDays then
				if Tools.isEmpty(activity.seven_days_data) == true then 
					activity.seven_days_data = {}
				end
			end

			table.insert(return_list, activity)
		end
	end
	if Tools.isEmpty(return_list) == true then
		return nil
	end
	return return_list
end

function CoreUser.activityUpdateLevelInfo( level_id, level_star, activity )
	if activity == nil or activity.seven_days_data == nil then
		return
	end
	if Tools.isEmpty(activity.seven_days_data.level_info) == true then
		activity.seven_days_data.level_info = {
			{level_id = level_id, level_star = level_star},
		}
	else
		local info
		for i,v in ipairs(activity.seven_days_data.level_info) do
			if v.level_id == level_id then
				info = v
				break
			end
		end

		if info == nil then
			table.insert(activity.seven_days_data.level_info, {level_id = level_id, level_star = level_star})
		else
			if info.level_star < level_star then
				info.level_star = level_star
			end
		end
	end
end

function CoreUser.activityUpdateTrialLevel( level_id, star, activity )
	if activity == nil or activity.seven_days_data == nil then
		return
	end
	if Tools.isEmpty(activity.seven_days_data.trial_level_list) == true then
		activity.seven_days_data.trial_level_list = {
			{level_id = level_id, star = star},
		}
	else
		local info
		for i,v in ipairs(activity.seven_days_data.trial_level_list) do
			if v.level_id == level_id then
				info = v
				break
			end
		end

		if info == nil then
			table.insert(activity.seven_days_data.trial_level_list, {level_id = level_id, star = star})
		else
			if info.star < star then
				info.star = star
			end
		end
	end
end

function CoreUser.checkFriendsData( user_name, list_name, user_info )

	if Tools.isEmpty(user_info.friends_data) == true or Tools.isEmpty(user_info.friends_data[list_name]) == true then
		return false
	end

	for i,v in ipairs(user_info.friends_data[list_name]) do
		if v == user_name then
			return true,i
		end
	end
	return false
end

function CoreUser.addFriendsData( user_name, list_name, user_info )
	if user_info.friends_data == nil then
		user_info.friends_data = {}
	end
	if user_info.friends_data[list_name] == nil or Tools.isEmpty(user_info.friends_data[list_name]) then
		user_info.friends_data[list_name] = {}
	end

	table.insert(user_info.friends_data[list_name], user_name)

end

function CoreUser.removeFriendsDataByIndex( index, list_name, user_info )
	if user_info.friends_data == nil then
		return
	end
	if user_info.friends_data[list_name] == nil or Tools.isEmpty(user_info.friends_data[list_name]) then
		return
	end
	table.remove(user_info.friends_data[list_name], index)
end

function CoreUser.removeFriendFamiliarity(user_info, user_name)
	if user_info.friends_data == nil then
		return
	end
	for i, v in ipairs(user_info.friends_data.friends_familiarity) do
		if v.user_name == user_name then
			table.remove(user_info.friends_data.friends_familiarity, i)
			break
		end
	end
end

function CoreUser.AddFriendTili(user_info, user_info2)
	if user_info == nil or user_info2 == nil then
		return false
	end
	if user_info.friends_data == nil or user_info2.friends_data == nil then
		return false
	end
	local add_tili = user_info.friends_data.add_tili
	if add_tili == nil then
		add_tili = {}
	end
	local read_tili = user_info2.friends_data.read_tili
	if read_tili == nil then
		read_tili = {}
	end

	local bHave = false
	if #add_tili == 0 then
		--bHave = true
	else
		for _ , v in ipairs(add_tili) do
			if v == user_info2.user_name then
				print("have frient tili name",v)
				bHave = true
				break
			end
		end
	end
	if bHave then
		return false
	end

	table.insert(add_tili, user_info2.user_name)
	if not user_info.friends_data.add_tili_count then
		user_info.friends_data.add_tili_count = 0
	else
		user_info.friends_data.add_tili_count = user_info.friends_data.add_tili_count + 1
	end

	bHave = false
	if #read_tili > 0 then
		for _, v in ipairs(read_tili) do
			if v == user_info.user_name then
				bHave = true
				break
			end
		end
	end
	if not bHave then
		local b = false
		local fam_list = user_info.friends_data.friends_familiarity
		local fa = CONF.PARAM.get("friends get_energy").PARAM
		for _ , v in ipairs(fam_list) do
			if v.user_name == tostring(user_info2.user_name) then
				v.familiarity = v.familiarity + fa
				b = true
			end
		end
		if b == false then
			table.insert(fam_list,{user_name = tostring(user_info2.user_name),familiarity = fa,})
		end
		user_info.friends_data.friends_familiarity = fam_list

		table.insert(read_tili, user_info.user_name)
	end

	user_info.friends_data.add_tili = add_tili
	user_info2.friends_data.read_tili = read_tili
	return true
end

function CoreUser.ReadFriendTili(user_info,user_name)
	if user_info.friends_data == nil then
		return false
	end
	if user_info.friends_data.read_tili == nil or Tools.isEmpty(user_info.friends_data.read_tili) then
		return false
	end

	if user_info.friends_data.read_tili_count >= CONF.VIP.get(user_info.vip_level).FRIEND_STRENGTH then
		return false
	end

	local have = false
	for i, v in ipairs(user_info.friends_data.read_tili) do
		if v == user_name then
			have = true
			table.remove(user_info.friends_data.read_tili,i)
			user_info.friends_data.read_tili_count = user_info.friends_data.read_tili_count + 1
			break
		end
	end
	return have
end

function CoreUser.battleCount( attacker_name, defencer_name, isWin )

	if string.sub(defencer_name,1,5) ~= "robot" then
		local defence_other_user_info = UserInfoCache.get(defencer_name)
		if defence_other_user_info then
			if defence_other_user_info.defence_count == nil then
				defence_other_user_info.defence_count = 1
			else
				defence_other_user_info.defence_count = defence_other_user_info.defence_count + 1
			end
			UserInfoCache.set(defence_other_user_info.user_name, defence_other_user_info)
		end

	end

	local attack_other_user_info = UserInfoCache.get(attacker_name)
	if attack_other_user_info then
		if attack_other_user_info.attack_count == nil then
			attack_other_user_info.attack_count = 1
		else
			attack_other_user_info.attack_count = attack_other_user_info.attack_count + 1
		end

		if isWin == true then
			if attack_other_user_info.win_count == nil then
				attack_other_user_info.win_count = 1
			else
				attack_other_user_info.win_count = attack_other_user_info.win_count + 1
			end
		end
		UserInfoCache.set(attack_other_user_info.user_name, attack_other_user_info)
	end
end

function CoreUser.getBuildingInfo( index, user_info )
	if index < 1 or index > CONF.EBuilding.count then
		return nil
	end

	if Tools.isEmpty(user_info.building_list) then
		return nil
	end
 
	return user_info.building_list[index]
end

function CoreUser.getNewHandGiftBag( user_info )
	local count = 0
	local list_conf = {}
	for i=1,CONF.NEWHANDGIFTBAG.len do

		local conf = CONF.NEWHANDGIFTBAG[CONF.NEWHANDGIFTBAG.index[i]]
		if (conf.TYPE == 0 and user_info.level >= conf.MIN_LEVEL and user_info.level <= conf.MAX_LEVEL2) then
			--Tools._print("getNewHandGiftBag  "..tostring(user_info.level).."  "..tostring(conf.MIN_LEVEL).."  "..tostring(conf.MAX_LEVEL2).."  "..conf.ID)
			count = count + conf.RATE
			table.insert(list_conf,conf)
		end
	end
	if(#list_conf<1) then
		return false 
	end
	local rand = math.random(1, count)
	local num = 0
	local selected_conf
	for i=1,#list_conf do
		local conf = list_conf[i]
		num = num + conf.RATE
		if rand <= num then
			selected_conf = conf
			break
		end
	end

	if selected_conf == nil then
		return false
	end
	if not Tools.isEmpty(user_info.new_hand_gift_bag_data) and not Tools.isEmpty(user_info.new_hand_gift_bag_data.new_hand_gift_bag_list) then
		for i=1,#user_info.new_hand_gift_bag_data.new_hand_gift_bag_list do
			if user_info.new_hand_gift_bag_data.new_hand_gift_bag_list[i].id==selected_conf.ID then
				return false 
			end
		end
	end
	count = 0
	for i=1,#selected_conf.GIFTBAG_RATE do
		count = count + selected_conf.GIFTBAG_RATE[i]
	end

	rand = math.random(1, count)
	num = 0

	for i=1,#selected_conf.GIFTBAG_RATE do
		num = num + selected_conf.GIFTBAG_RATE[i]
		if rand <= num then
			local gift_bag = {
				id = selected_conf.ID,
				gift_id = selected_conf.GIFTBAG[i],
				start_time = os.time(),
			}
			if Tools.isEmpty(user_info.new_hand_gift_bag_data) then
				user_info.new_hand_gift_bag_data = {
					times = 0,
				}
			end

			if Tools.isEmpty(user_info.new_hand_gift_bag_data.new_hand_gift_bag_list) then
				user_info.new_hand_gift_bag_data.new_hand_gift_bag_list = {}
			end

			user_info.new_hand_gift_bag_data.times = user_info.new_hand_gift_bag_data.times + 1
			table.insert(user_info.new_hand_gift_bag_data.new_hand_gift_bag_list, gift_bag)

			CoreUser.userSyncUpdate(user_info.user_name, {
				user_info = {
					new_hand_gift_bag_data = user_info.new_hand_gift_bag_data,
				},
			})
			break
		end
	end
	return true
end

function CoreUser.getGiftBag( user_info )
	if (Tools.isEmpty(user_info.gift_bag_list)) then
		Tools._print("CoreUser.getGiftBag nil gift_bag_list")
	else
		Tools._print("CoreUser.getGiftBag have gift_bag_list")
		Tools.print_t(user_info.gift_bag_list)
	end

	local list_conf = {}
	for i=1,CONF.NEWHANDGIFTBAG.len do

		local conf = CONF.NEWHANDGIFTBAG[CONF.NEWHANDGIFTBAG.index[i]]
		if (conf.TYPE == 1 and user_info.level >= conf.MIN_LEVEL and user_info.level <= conf.MAX_LEVEL2) then
			local bHave = false
			if not Tools.isEmpty(user_info.gift_bag_list) then
				for j=1,#user_info.gift_bag_list do
					if user_info.gift_bag_list[j].id==conf.ID then
						bHave = true
						break
					end
				end
			end
			if (bHave == false) then
				table.insert(list_conf,conf)
			end
		end
	end

	if(#list_conf<1) then
		return false 
	end


	for i=1,#list_conf do

		local gift_bag = {
			id = list_conf[i].ID,
			count = 0,
			start_time = os.time(),
		}

		if Tools.isEmpty(user_info.gift_bag_list) then
			user_info.gift_bag_list = {
			}
		end

		table.insert(user_info.gift_bag_list, gift_bag)
		--print("CoreUser.getGiftBag add" ,#user_info.gift_bag_list,type(user_info),type(user_info.gift_bag_list))
	end

	--Tools.print_t(user_info)

	CoreUser.userSyncUpdate(user_info.user_name, {
		user_info = {
			gift_bag_list = user_info.gift_bag_list,
		},
	})	
	print("CoreUser.getGiftBag 33333333333333")

end

return CoreUser