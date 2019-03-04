local UserGroup = {}

function UserGroup:addUser(group_main, user_info)
	local user =
	{
		guid = self:getGuid(group_main),
		user_name = user_info.user_name,
		nickname = user_info.nickname,
		job = GolbalDefine.enum_group_job.member,
		status = 1,

		last_act = os.time(),
		unlock_time = 0,
	}

	local other_user_info = UserInfoCache.get(user_info.user_name)
	if other_user_info then
		other_user_info.group_nickname = group_main.nickname
		other_user_info.groupid = group_main.groupid
		UserInfoCache.set(user_info.user_name, other_user_info)
	end
	return user
end

function UserGroup:resetGroupData( user_info )
	local group_data
	if Tools.isEmpty(user_info.group_data) == false then
		group_data = {
			groupid = "",
			job = 0,
			status = 0,
			anti_time = user_info.group_data.anti_time,
			today_join_num = user_info.group_data.today_join_num,
			contribute_end_cd = user_info.group_data.contribute_end_cd,
			contribute_locker = user_info.group_data.contribute_locker,
			today_worship_level = user_info.group_data.today_worship_level,
			getted_worship_reward = user_info.group_data.getted_worship_reward,
			pve_checkpoint_list = user_info.group_data.pve_checkpoint_list,
		}
	else
		group_data = {
			groupid = "",
			job = 0,
			status = 0,
		}
	end
	return group_data
end

function UserGroup:createGroup(nick_name, icon_id)
	local user_info = self:getUserInfo() or {}
    	local user_name = user_info.user_name

    	local has = GroupCache.hasNickName(nick_name)
    	if has == true then
    		return 1
    	end

    	if user_info then

    		if user_info.group_data == nil then

    			return 2

    		elseif user_info.group_data.groupid ~= "" then

    			return 2
    		end
    	end

	for i=1,CONF.DIRTYWORD.len do
		if string.find(nick_name, CONF.DIRTYWORD[i].KEY) ~= nil then
			return 3
		end
	end

	local groupid = GroupCache.getGroupId(user_name)

	local group_main = 
	{
		groupid = groupid,
		nickname = nick_name,
		status = 1,
		icon_id = icon_id,
		contribute = 0,
		exp = 0,
		level = 1,
		dayid = 0,
		guid = 1,
		broadcast = "",
		create_time = os.time(),
		join_condition = {
			needAllow = true,
		},
		rank = GroupCache.count() + 1,
	}
    	local group_user = self:addUser(group_main, user_info)

	group_user.job = GolbalDefine.enum_group_job.leader
	group_main.user_list = {group_user}
	self.m_group_main = group_main
	GroupCache.add(group_main.groupid, group_main)

	local group_data = self:resetGroupData(user_info)
	group_data.groupid = group_main.groupid
	group_data.job = group_user.job
	group_data.status = group_main.status
	group_data.icon_id = group_main.icon_id
	
	user_info.group_data = group_data

    	return 0
end

function UserGroup:getGroupBuff()

	return Tools.encode("GroupMainData", self.m_group_main)
end

function UserGroup:getGroupMain()
	return self.m_group_main
end

function UserGroup:getGroupUser(user_name)

	local group_main = self:getGroupMain()

	for k,v in ipairs(group_main.user_list) do
		if v.user_name == user_name then
			return v, k
		end
	end
	return nil
end

function UserGroup:getGroupJobCount( job )

	local group_main = self:getGroupMain()

	local count = 0
	for k,v in ipairs(group_main.user_list) do
		if v.job == job then
			count = count + 1
		end
	end
	return count
end

function UserGroup:getGuid(group_main)
	local guid = 0
	local user_list = group_main.user_list or {}
	for k,v in ipairs(user_list) do
		if v.guid > guid then
			guid = v.guid
		end
	end
	return guid + 1
end

function UserGroup:getItemList()
	return self.m_item_list
end

function UserGroup:getMultiCast(user_update_list)

	local user_info = self:getUserInfo()
	local group_main = self:getGroupMain()

	local recv_list = {}
	local user_list = group_main.user_list or {}
	for k,v in ipairs(user_list) do
		table.insert(recv_list, v.user_name)
	end
	local cmd = 0x16ff
	local group_update =
	{
		group_main = group_main,
		user_name = user_info and user_info.user_name or nil,
		user_update_list = user_update_list,
	}
	local multicast = 
	{
		recv_list = recv_list,
		cmd = cmd,
		group_update = group_update,
	}

	--Tools._print("UserGroup:getMultiCast")
	--Tools.print_t(multicast)
	return multicast
end

function UserGroup:getShipInfo(guid)
	local ship_list = self:getShipList()
	local ship_info
	for k,v in ipairs(ship_list) do
		if v.guid == guid then
			ship_info = v
		end
	end
	return ship_info
end

function UserGroup:getShipList()
	return self.m_ship_list
end

function UserGroup:getUserInfo()
	return self.m_user_info
end


function UserGroup:new(group_buff)
	local group_main
	if group_buff then
		group_main = Tools.decode("GroupMainData", group_buff)
	else
		group_main = {}
	end
	self.m_group_main = group_main
end

function UserGroup:setItemList(item_list)
	self.m_item_list = item_list
end

function UserGroup:setShipList(ship_list)
	self.m_ship_list = ship_list
end

function UserGroup:setUserInfo(user_info)
	self.m_user_info = user_info
end

function UserGroup:checkJoinCondition( group_main, user_info )



	if group_main.join_condition.needAllow == false then
		return true
	end

	if group_main.join_condition.level then
		if user_info.level < group_main.join_condition.level then
			return false
		end
	end

	local user_info_cache = UserInfoCache.get(user_info.user_name)
	if not user_info_cache then
		return false
	end
	if group_main.join_condition.power then
		if user_info_cache.power < group_main.join_condition.power then
			return false
		end
	end

	return true
end

function UserGroup:setJoinCondition( join_condition )

	local user_info = self:getUserInfo()

	local group_user = self:getGroupUser(user_info.user_name)

	local group_main = self:getGroupMain()

	GroupCache.merge(group_main)

	if group_user.job > GolbalDefine.enum_group_job.manager then
		return 1
	end

	group_main.join_condition = join_condition

	if group_main.join_condition.needAllow == false then
		group_main.join_list = nil
	end

	GroupCache.update(group_main, user_info)
	return 0
end

function UserGroup:groupJoin(user_info)
	local group_data = rawget(user_info,"group_data")



	if Tools.isEmpty(group_data) then
		group_data =
		{
			groupid = "",
			job = 0,
			status = 0,
		}
	end

	local group_main = self:getGroupMain()

	GroupCache.merge(group_main)

	if self:checkJoinCondition(group_main, user_info) == false then
		return "NO_CONDITION"
	end

	local join_list = rawget(group_main, "join_list") or {}
	group_data.status = 0
	group_data.anti_time = 0


	local has = false
	for k,v in ipairs(join_list) do
		if v.user_name == user_info.user_name then
			has = true
			break
		end
	end

	local ret
	if has == false and group_data.status == 0 then
		local today_join_num = group_data.today_join_num or 0
		local join_info =
		{
			user_name = user_info.user_name,
			nickname = user_info.nickname,
			join_time = os.time()
		}
		today_join_num = today_join_num + 1
		table.insert(join_list, join_info)
		group_data.today_join_num = today_join_num
		ret = "OK"
	else
		if group_data.status == 1 then
			ret = "STATUS_ERROR"
		else
			ret = "STATUS_ERROR"
		end
	end

	user_info.group_data = group_data
	rawset( group_main, "join_list", join_list)


	if ret == "OK" then
		GroupCache.update(group_main)
	end
	return ret
end

function UserGroup:groupUnjoin(user_info)

	local group_main = self:getGroupMain()
	GroupCache.merge(group_main)

	local join_list = group_main.join_list or {}

	local ret = "FAIL"

	for k,v in ipairs(join_list) do
		if v.user_name == user_info.user_name then
			table.remove(join_list, k)
			group_main.join_list = join_list

			GroupCache.update(group_main)
			ret = "OK"
		end
	end

	-- local user_list = group_main.user_list or {}
	-- for k,v in ipairs(user_list) do
	-- 	if v.user_name == user_info.user_name then
	-- 		table.remove(user_list, k)
	-- 		group_main.user_list = user_list

	-- 		GroupCache.update(group_main)
	-- 		ret = 0
	-- 	end
	-- end

	return ret
end

function UserGroup:groupAllow(type, user_info2, isInvite) -- type 0:allow 1:notallow


	local group_main = self:getGroupMain()

	GroupCache.merge(group_main)

	local join_list = group_main.join_list or {}
	local user_list = group_main.user_list or {}


	for k,v in ipairs(user_list) do
		if v.user_name == user_info2.user_name then
			return "SAME_USER"
		end
	end

	for k,v in ipairs(join_list) do
		if v.user_name == user_info2.user_name then
	
			table.remove(join_list, k)
			group_main.join_list = join_list
			break
		end
	end

	local my_user_info = self:getUserInfo()

	if type == 1 then
		GroupCache.update(group_main, my_user_info and my_user_info or nil)
		return "OK"
	end

	if user_info2.group_data then
		if user_info2.group_data.status ~= 0 then

			for k,v in ipairs(join_list) do
				if v.user_name == user_info2.user_name then
					table.remove(join_list, k)
					group_main.join_list = join_list
					GroupCache.update(group_main, my_user_info and my_user_info or nil)
					break
				end
			end
			return "STATUS_ERROR"
		end
	end


	if my_user_info then
		local my_group_user = self:getGroupUser(my_user_info.user_name)
		if my_group_user == nil then
			return "NO_USER"
		end
		if my_group_user.job > GolbalDefine.enum_group_job.manager then
			return "NO_POWER"
		end
	end

	local groupConf = CONF.GROUP.get(group_main.level)

	local max = groupConf.MAX_USER + Tools.getValueByTechnologyAddition(groupConf.MAX_USER, CONF.ETechTarget_1.kGroup, 0, CONF.ETechTarget_3_Group.kMaxUser, nil, group_main.tech_list)
	if #user_list >= max then
		return "USER_COUNT_MAX"
	end

	if isInvite == true then
		
	else
		if self:checkJoinCondition(group_main, user_info2) == false then
			return "NO_CONDITION"
		end
	end

	local group_user = self:addUser(group_main, user_info2)

	table.insert(user_list, group_user)


	user_info2.group_data.groupid = group_main.groupid

	user_info2.group_data.job = group_user.job

	user_info2.group_data.status = 1

	group_main.user_list = user_list

	GroupCache.update(group_main, my_user_info and my_user_info.user_name or nil)

	return "OK"
end

function UserGroup:groupDisband( )

	local group_main = self:getGroupMain()
	GroupCache.merge(group_main)

	local user_info = self:getUserInfo()
	local group_user = self:getGroupUser(user_info.user_name)

	if group_user.job ~= GolbalDefine.enum_group_job.leader then
		return "NOPOWER"
	end
	

	if group_main.unlock_time ~= nil and os.time() < group_main.unlock_time then
		return "LOCKED"
	end 

	if GroupCache.disband(group_main.groupid) == false then
		return "ERROR"
	end

	local mail = {
		type = 0,
		from = Lang.group_mail_sender,
		subject = Lang.group_disband_title,
		message = Lang.group_disband_msg,
		stamp = os.time(),
		expiry_stamp = os.time() + 604800,
		guid = 0,
	}

	local update_list = {}

	for i,v in ipairs(group_main.user_list) do

		if user_info.user_name ~= v.user_name then

			local user_update = {
				user_name = v.user_name,
				user_sync = {
					user_info = {
						group_data = {
							groupid = "",
							job = 0,
							status = 0,
						}
					}
				}
			}
			table.insert(update_list, user_update)
		end


		local other_user_info = UserInfoCache.get(v.user_name)
		if other_user_info then
			other_user_info.group_nickname = nil
			other_user_info.groupid = nil
			UserInfoCache.set(v.user_name, other_user_info)
		end


		RedoList.addMail(v.user_name, mail)

		PlanetCache.checkHasGroupArmy( v.user_name )
	end

	PlanetCache.groupExitCityRes(group_main.groupid)

	if Tools.isEmpty(group_main.occupy_city_list) == false then
		local element_list = {}
		for i,global_key in ipairs(group_main.occupy_city_list) do
			local element = PlanetCache.getElement(global_key)
			table.insert(element_list ,element )
		end
		local node_list = {}
		for i,v in ipairs(element_list) do
			local node_id = PlanetCache.exitCity(v, group_main)
			table.insert(node_list, node_id)
		end
		PlanetCache.broadcastUpdate(user_info.user_name, node_list)
	end

	local multi_cast = self:getMultiCast(update_list)

	user_info.group_data = self:resetGroupData(user_info)
	
	group_main.status = 0

	return "OK",multi_cast
end

function UserGroup:groupExit( user_info )
	
	local group_main = self:getGroupMain()
	GroupCache.merge(group_main)

	local group_user, index = self:getGroupUser(user_info.user_name)
	if not group_user then
		return 1
	end

	if group_user.job == GolbalDefine.enum_group_job.leader then
		return 2
	end 

	user_info.group_data = self:resetGroupData(user_info)
	user_info.group_data.anti_time = os.time() + 86400--一天内不能去新公会


	if Tools.isEmpty(group_main.help_list) == false then
		for i=#group_main.help_list,1, -1 do
			if user_info.user_name == group_main.help_list[i].user_name then
				table.remove(group_main.help_list, i)
			end
		end
	end

	local user_update = {
		user_name = user_info.user_name,
		user_sync = {
			user_info = {
				group_data = user_info.group_data,
			}
		}
	}

	local multi_cast = self:getMultiCast({user_update})

	table.remove(group_main.user_list, index)

	PlanetCache.groupClearByUserName(group_main, user_info.user_name)

	PlanetCache.checkHasGroupArmy( user_info.user_name )

	GroupCache.update(group_main)

	local other_user_info = UserInfoCache.get(user_info.user_name)
	if other_user_info then
		other_user_info.group_nickname = nil
		other_user_info.groupid = nil
		UserInfoCache.set(user_info.user_name, other_user_info)
	end

	return 0, multi_cast
end


function UserGroup:groupKick(kick_user_info, kick_mail_list)

	local user_info = self:getUserInfo()

	local group_user = self:getGroupUser(user_info.user_name)
	local kick_group_user,kick_index = self:getGroupUser(kick_user_info.user_name)

	if group_user == nil or kick_group_user == nil then
		return "NOUSER"
	end

	if group_user.job >= kick_group_user.job and group_user.job > GolbalDefine.enum_group_job.manager then
		return "NOPOWER"
	end

	local group_main = self:getGroupMain()
	GroupCache.merge(group_main)

	if kick_group_user.unlock_time and os.time() < kick_group_user.unlock_time then
		return "LOCKED"
	end

	kick_user_info.group_data = self:resetGroupData(kick_user_info)

	local other_user_info = UserInfoCache.get(kick_user_info.user_name)
	if other_user_info then
		other_user_info.group_nickname = nil
		other_user_info.groupid = nil
		UserInfoCache.set(kick_user_info.user_name, other_user_info)
	end

	local user_update = {
		user_name = kick_user_info.user_name,
		user_sync = {
			user_info = {
				group_data = kick_user_info.group_data,
			}
		}
	}
	local multi_cast = self:getMultiCast({user_update})

	table.remove(group_main.user_list, kick_index)

	if Tools.isEmpty(group_main.help_list) == false then
		for i=#group_main.help_list,1, -1 do
			if kick_user_info.user_name == group_main.help_list[i].user_name then
				table.remove(group_main.help_list, i)
			end
		end
	end
    
	local mail = {
		type = 0,
		from = Lang.group_mail_sender,
		subject = Lang.group_kick_title,
		message = Lang.group_kick_msg,
		stamp = os.time(),
		expiry_stamp = os.time() + 604800,
		guid = 0,
	}

    	CoreMail.recvMail(mail, kick_mail_list)

	--TODO:
	-- 退出公会的话，清掉这个人在公会中的所有痕迹
	PlanetCache.checkHasGroupArmy( kick_user_info.user_name )

    	PlanetCache.groupClearByUserName(group_main, kick_user_info.user_name)

    	GroupCache.update(group_main,user_info.user_name)

    	return "OK", multi_cast
end

function UserGroup:broadcast(blurb, broadcast)

	local user_info = self:getUserInfo()

	local group_user = self:getGroupUser(user_info.user_name)
	if group_user == nil then
		return "NO_USER"
	end

	if group_user.job > GolbalDefine.enum_group_job.manager then
		return "NOPOWER"
	end

	for i=1,CONF.DIRTYWORD.len do
		if string.find(broadcast, CONF.DIRTYWORD[i].KEY) then
			return "DIRTY"
		end
		if string.find(blurb, CONF.DIRTYWORD[i].KEY) then
			return "DIRTY"
		end
	end

	local group_main = self:getGroupMain()
	GroupCache.merge(group_main)

	local changed = false
	if broadcast ~= nil then
		group_main.broadcast = broadcast
		changed = true
	end

	if blurb ~= nil then
		group_main.blurb = blurb
		changed = true
	end

	if changed == true then
		GroupCache.update(group_main, user_info.user_name)
	end
	

	return "OK"
end


function UserGroup:groupJob( job, recv_user_info )

	local give_user_info = self:getUserInfo()
	local group_giver = self:getGroupUser(give_user_info.user_name)

	local group_receiver = self:getGroupUser(recv_user_info.user_name)

	if group_giver == nil or group_receiver == nil then
		return "NOUSER"
	end

	if group_giver.job >= group_receiver.job and group_giver.job > GolbalDefine.enum_group_job.manager then
		return "NOPOWER"
	end

	if group_receiver.job == job then
		return "SAME_JOB"
	end


	if job == GolbalDefine.enum_group_job.leader then
		if group_giver.job ~= GolbalDefine.enum_group_job.leader then
			return "NOPOWER"
		end

		group_receiver.job = job
		group_giver.job = GolbalDefine.enum_group_job.member


		--因为第一次设置会没有用 所有用下面的方法替代
		-- recv_user_info.group_data.job = job 
		-- give_user_info.group_data.job = GolbalDefine.enum_group_job.member

		local recv_user_data = Tools.clone(recv_user_info.group_data)
		recv_user_data.job = job
		recv_user_info.group_data = recv_user_data

		local giver_user_data = Tools.clone(give_user_info.group_data)
		giver_user_data.job = GolbalDefine.enum_group_job.member
		give_user_info.group_data = giver_user_data
		

	elseif job == GolbalDefine.enum_group_job.manager then

		if group_giver.job ~= GolbalDefine.enum_group_job.leader then
			return "NOPOWER"
		end

		if group_receiver.job <= GolbalDefine.enum_group_job.manager then
			return "ERROR_JOB"
		end

		local count = self:getGroupJobCount( GolbalDefine.enum_group_job.manager )

		local groupConf = CONF.GROUP.get(self:getGroupMain().level)
		
		if count >= groupConf.MANAGER then
			return "FULL_MANAGER"
		end

		group_receiver.job = job
		recv_user_info.group_data.job = job 


	elseif job == GolbalDefine.enum_group_job.member then

		if group_giver.job ~= GolbalDefine.enum_group_job.leader then
			return "NOPOWER"
		end

		if group_receiver.job >= GolbalDefine.enum_group_job.member then
			return "ERROR_JOB"
		end

		group_receiver.job = job
		recv_user_info.group_data.job = job

	else
		return "ERROR_JOB"
	end 


	local group_main = self:getGroupMain()
	GroupCache.merge(group_main)
	GroupCache.update(group_main, give_user_info.user_name)


	local update_user_list = {
		{
			user_name = give_user_info.user_name,
			user_sync = {
				user_info = {
					group_data = give_user_info.group_data,
				}
			}
		},
		{
			user_name = recv_user_info.user_name,
			user_sync = {
				user_info = {
					group_data = recv_user_info.group_data,
				}
			}
		},
	}

	local multi_cast = self:getMultiCast(update_user_list)

	return "OK",multi_cast
end


function UserGroup:removeTechnology( tech_id )
	local group_main = self:getGroupMain()
	for i,v in ipairs(group_main.tech_list) do
		if tech_id == v.tech_id then
			table.remove(group_main.tech_list, i)
			return true
		end
	end
	return false
end

function UserGroup:getTechnology( tech_id )
	local group_main = self:getGroupMain()

	local tech_list = group_main.tech_list

	local remove_list = {}
	local return_data

	local tech_temp,tech_level = math.modf(tech_id/100)

	for i,v in ipairs(tech_list) do

		local temp,level = math.modf(v.tech_id/100)
		if tech_temp == temp then
			if level == tech_level then

				if v.status == 2 then
					local techConf = CONF.GROUP_TECH.get(tech_id)
					if os.time() - v.begin_upgrade_time >= techConf.CD then
						v.begin_upgrade_time = 0
						table.insert(remove_list, tech_id - 1)
						v.status = 3
					end
				end

				return_data = v
				break

			elseif level > tech_level then

				return nil
			end
		end
	end

	for i,remove_id in ipairs(remove_list) do
		local removed = self:removeTechnology(remove_id)
	end

	if return_data then
		return return_data
	end

	----------------新科技-------------------

	local function isTechOpen( tech_temp )

		for i=1,group_main.level do

			local groupConf = CONF.GROUP.get(i)
			for i,v in ipairs(groupConf.OPEN_TECH_ID) do
				local temp = math.modf(v/100)
				if temp == tech_temp then

					return true
				end
			end
		end

		return false
	end

	if isTechOpen(tech_temp) == false then
		return nil
	end


	if Tools.isEmpty(group_main.tech_list) == true then
		group_main.tech_list = {}
	end

	local group_tech = {
		tech_id = tech_id,
		exp = 0,
		status = 1,
	}

	table.insert(group_main.tech_list, group_tech)
	return group_tech
end

function UserGroup:getUserTechContributeData( tech_id )
	local user_info = self:getUserInfo()
	for i,v in ipairs(user_info.group_data.tech_contribute_list) do
		if v.tech_id == tech_id then
			return v
		end
	end
	return nil
end

function UserGroup:groupContribute(type, tech_id)

	local user_info = self:getUserInfo()
	local item_list = self:getItemList()
	local group_main = self:getGroupMain()
	GroupCache.merge(group_main)

	local group_user = self:getGroupUser(user_info.user_name)

	local group_data = user_info.group_data


	local group_tech = self:getTechnology(tech_id)
	--检查科技
	if group_tech == nil then
		return 1
	end

	local tech_contribute_data = self:getUserTechContributeData(tech_id)

	local user_sync

	local techConf = CONF.GROUP_TECH.get(tech_id)

	if type > 0 then

		local now_time = os.time()
		if group_data.contribute_end_cd < now_time then
			group_data.contribute_locker = false
		end
		if group_data.contribute_locker == true then
			return 2
		end

		--检查捐献
		if tech_contribute_data == nil then
			return 3
		end
		
		local index = tech_contribute_data.item_index_list[type]

		--检查INDEX
		if index == nil or index < 1 or index > #techConf.ITEM then
			return 4
		end

		--检查CONF
		if not techConf.ITEM[index] or not techConf.NUM[index] then
			return 5
		end

		--检查是否是完成的科技
		if group_tech.status == 3 then
			return 6
		end
		
		--检查资源
		local items = {}
		items[techConf.ITEM[index]] = techConf.NUM[index]
		if not CoreItem.checkItems( items, item_list, user_info) then
            			return 7
        		end

        		CoreItem.expendItems( items, item_list, user_info)

        		user_sync = CoreItem.makeSync( items, item_list, user_info)

        		--增加EXP
        		group_tech.exp = group_tech.exp + (techConf.GOT_EXP * type)
        		if group_tech.exp > techConf.EXP then
        			group_tech.exp = techConf.EXP 
        		end

        		--增加贡献值
   
        		group_data.contribute = group_data.contribute + techConf.GOT_CONTRIBUTE * type

        		group_main.contribute = group_main.contribute + techConf.GOT_CONTRIBUTE * type

        		--重置暴击INDEX
        		if type == 2 then
        			tech_contribute_data.item_index_list[type] = nil
        		end

        		group_data.contribute_end_cd = group_data.contribute_end_cd or now_time
		if group_data.contribute_end_cd < now_time then
			group_data.contribute_end_cd = now_time
		end

		group_data.contribute_end_cd = group_data.contribute_end_cd + CONF.PARAM.get("donate_cd").PARAM

		if (group_data.contribute_end_cd - now_time) > CONF.PARAM.get("donate_cd_limit").PARAM then
			group_data.contribute_locker = true
		end

	end

	--randrom new item
	if not tech_contribute_data then
		tech_contribute_data = {
			tech_id = tech_id,
		}

		local group_data = rawget(user_info, "group_data")

		local tech_contribute_list = group_data.tech_contribute_list or {}

		table.insert(tech_contribute_list, tech_contribute_data)

		group_data.tech_contribute_list = tech_contribute_list

	end


	tech_contribute_data.item_index_list = tech_contribute_data.item_index_list or {}

	--普通捐献刷新
	if type == 1 or tech_contribute_data.item_index_list[1] == nil then
		tech_contribute_data.item_index_list[1] = math.random(#techConf.ITEM)
	end

	--暴击刷新
	if type == 1 and tech_contribute_data.item_index_list[2] == nil then
		if math.random(100) > 50 then
			tech_contribute_data.item_index_list[2] = math.random(#techConf.ITEM)
		end
	end

	GroupCache.update(group_main, user_info.user_name)

	return 0, user_sync
end

function UserGroup:groupTechLevelup( tech_id )

	local group_main = self:getGroupMain()
	GroupCache.merge(group_main)

	local user_info = self:getUserInfo()

	local group_tech = self:getTechnology(tech_id)

	local group_user = self:getGroupUser(user_info.user_name)
	if group_user.job > GolbalDefine.enum_group_job.manager then
		return 1
	end

	if group_tech == nil or group_tech.exp == nil then 
		return 2
	end

	local techConf = CONF.GROUP_TECH.get(tech_id)
	if group_tech.exp < techConf.EXP then
		return 3
	end

	for i,v in ipairs(group_main.tech_list) do
		if v.status == 2 then
			return 4
		end
	end

	local tech_type,level = math.modf(group_tech.tech_id/100)
	if level > 1 then
		local pre_tech = self:getTechnology(group_tech.tech_id - 1)
		if pre_tech and pre_tech.status == 3 then

		else
			return 5
		end
	end
	
	
	group_tech.exp = nil

	group_tech.begin_upgrade_time = os.time()

	group_tech.status = 2

	GroupCache.update(group_main, user_info.user_name)

	return 0
end


function UserGroup:groupLevelup( )

	local user_info = self:getUserInfo()
	local group_user = self:getGroupUser(user_info.user_name)
	if group_user.job > GolbalDefine.enum_group_job.manager then
		return 1
	end

	local group_main = self:getGroupMain()
	local nextConf = CONF.GROUP.check(group_main.level + 1)
	if not nextConf then
		return 2
	end

	if group_main.contribute < nextConf.CONTRIBUTE then
		return 3
	end

	local userCount = #group_main.user_list
	if userCount < nextConf.LEVELUP_MEMBER_NUM then
		return 4
	end

	local techCount = 0
	for i,v in ipairs(group_main.tech_list) do
		if v.begin_upgrade_time and v.begin_upgrade_time == 0 then
			local _,level = math.modf(v.tech_id/100)
			techCount = techCount + math.floor(level*100)
		end
	end

	if techCount < nextConf.LEVELUP_TECH_NUM then
		return 5
	end

	group_main.contribute = group_main.contribute - nextConf.CONTRIBUTE
	group_main.level = group_main.level + 1

	return 0
end

function UserGroup:addHonour(honour)
	local user_info = self:getUserInfo()
	local group_main = self:getGroupMain()
	local group_user = self:getGroupUser(user_info.user_name)
	local ret = 0

	if honour < 0 then

		if group_user.honour < -honour then
			ret = group_user.honour + honour
		end
	end
	if ret == 0 then
		group_user.honour = group_user.honour + honour
		ret = group_user.honour
	end
	return ret
end

function UserGroup:getConfTask()
	local list = {}
	for k,v in pairs(CONF.GROUP_TASK) do
		if type(k) == "number" then
			local item =
			{
				id = v.ID,
				type = v.TYPE,
				status = 0,
			}
			local rewards = v.REWARD
			local reward_list = {}
			for i = 1, #rewards, 2 do
				local item_sync = {}
				item_sync.item_id = rewards[i]
				item_sync.item_num = rewards[i+1]
				table.insert(reward_list, item_sync)
			end
			item.reward_list = reward_list
			table.insert(list, item)
		end
	end
	return list
end


function UserGroup:groupShopRefresh()
	local user_info = self:getUserInfo()
	local group_data = user_info.group_data
	local shopping_list = group_data.shopping_list or {}
	for i=#shopping_list, 1, -1 do
		table.remove(shopping_list, i)
	end
	for k,v in ipairs(self:getShoppingList()) do
		table.insert(shopping_list, v)
	end
	group_data.shopping_list = shopping_list
end


function UserGroup:groupShopping(idx)
	local item_list = {}
	local user_info = self:getUserInfo()
	local group_data = user_info.group_data
	local shopping_list = group_data.shopping_list or {}
	for k,v in ipairs(shopping_list) do
		if k == idx then
			local item_sync =
			{
				item_id = v.item_id,
				item_num = 1,
			}
			v.item_num = v.item_num - 1
			table.insert(item_list, item_sync)
			break
		end
	end
	group_data.shopping_list = shopping_list
	return item_list
end

function UserGroup:groupTask(type, taskid)
	local user_info = self:getUserInfo()
	local group_main = self:getGroupMain()
	local group_user = self:getGroupUser(user_info.user_name)
	assert(group_user)

	if type == 0 then
		local task_list = Tools.isEmpty(group_user.task_list) and self:getConfTask() or group_user.task_list
		group_user.task_list = task_list
	else
		local task_list = group_user.task_list or {}
		for k,v in ipairs(task_list) do
			if v.id == taskid then
				v.status = 1
				break
			end
		end
	end
	return 0
end

function UserGroup:groupWorship(level)

	local user_info = self:getUserInfo()
	local item_list = self:getItemList()
	local group_main = self:getGroupMain()
	GroupCache.merge(group_main)

	local group_user = self:getGroupUser(user_info.user_name)

	local group_data = user_info.group_data

	if group_data == nil or group_data.groupid == "" then
		return "NO_GROUP"
	end
	if group_data.today_worship_level ~= nil then
		if group_data.today_worship_level > 0 then
			return "ALREADY"
		end
	end
	local conf = CONF.WORSHIP.get(level)
	if conf == nil then
		return "NO_CONF"
	end
	local items = {[conf.TYPE] = conf.NUM}
	if CoreItem.checkItems(items, item_list, user_info) == false then
		return "NO_RES"
	end

	CoreItem.expendItems(items, item_list, user_info)

	if group_data.contribute == nil then
		group_data.contribute = conf.CONTRIBUTION
	else
		group_data.contribute = conf.CONTRIBUTION + group_data.contribute
	end

	if group_main.contribute == nil then
		group_main.contribute = conf.CONTRIBUTION
	else
		group_main.contribute = conf.CONTRIBUTION + group_main.contribute
	end

	local rewardConf = CONF.WORSHIPREWARD.get(1)
	
	if group_main.worship_value == nil then
		group_main.worship_value = conf.SCHEDULE
	else
		group_main.worship_value = conf.SCHEDULE + group_main.worship_value
		if group_main.worship_value > rewardConf.MAX then
			group_main.worship_value = rewardConf.MAX
		end
	end

	group_data.today_worship_level = level
	if group_main.today_worship_times == nil then
		group_main.today_worship_times = 1
	else
		group_main.today_worship_times = group_main.today_worship_times + 1
	end

	local user_sync = CoreItem.makeSync(items, item_list, user_info)
	user_sync.group_main = group_main
	user_sync.user_info = user_sync.user_info or {}
	user_sync.user_info.group_data = group_data

	GroupCache.update(group_main, user_info.user_name)

	return "OK", user_sync
end

return UserGroup
