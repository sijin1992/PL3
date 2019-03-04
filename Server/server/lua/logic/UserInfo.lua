local UserInfo = {}

function UserInfo:add(user_name, nickname, icon_id)
	local cur_time = os.time()
	local user_info =
	{
		user_name = user_name,
		nickname = nickname,
		account = user_name,
		icon_id = icon_id,
		lineup = {0,0,0,0,0,0,0,0,0},
		aid_award_index = 0,
		strength = 0,
		strength_buy_times = 0,
		money = 0,
		vip_level = 0,
		exp = 0,
		level = 1,
		timestamp = {
			last_0am_day = 0,
			regist_time = cur_time,
			strength_timer = 0,
		},
		build_queue_list = {
			{
				duration_time = -1,
				open_time = -1,
				type = 0,
				index = 0,
			},
		},
		group_data = {
			groupid = "",
			job = 0,
			status = 0,
		},
		achievement_data = {
			sign_in_days = 1,
			recharge_money = 0,
		},
		trade_data = {
			last_product_time = cur_time,
			cur_num = 0,
		},
	}
	user_info.strength = Tools.getMaxStrength(user_info.level)

	local sync_user = SyncUserCache.createSyncUser(user_name)

	sync_user.res = Tools.clone(CONF.PARAM.get("start_res").PARAM)

	SyncUserCache.setSyncUser(sync_user)

	user_info.res = sync_user.res

	self.m_user_info = user_info
end

function UserInfo:getGroupMainFromGroupCache(  )
	local user_info = self:getUserInfo()
	if user_info.group_data == nil then
		return nil
	end
	local groupid = user_info.group_data.groupid
	if groupid == "" then
		return nil
	end
	return GroupCache.getGroupMain(groupid)
end


function UserInfo:addCoin(num)
	local user_info = self:getUserInfo()
	user_info.coin = user_info.coin + num
end

function UserInfo:addStrength(num)

	local user_info = self:getUserInfo()
	user_info.strength = user_info.strength + num
	return user_info.strength
end

function UserInfo:addStrengthByTime( num )

	local user_info = self:getUserInfo()

	local group_main = self:getGroupMainFromGroupCache()
	local group_tech_list = group_main and group_main.tech_list or nil

	local max = Tools.getMaxStrength(user_info.level, group_tech_list)

	if  user_info.strength < max then
		self:addStrength(num)
		if user_info.strength > max then
			user_info.strength = max
		end
	end
end

function UserInfo:removeStrength( num )
	local user_info = self:getUserInfo()
	user_info.strength = user_info.strength - num

	if user_info.strength < 0 then
		user_info.strength = 0
	end
	return  user_info.strength
end

function UserInfo:getStrength()

	local user_info = self:getUserInfo()

	local cur_time = os.time()

	if user_info.timestamp.strength_timer > 0 then

		local diff = cur_time - user_info.timestamp.strength_timer

		self:addStrengthByTime(math.floor(diff / 300))

		user_info.timestamp.strength_timer = cur_time - Tools.mod(diff, 300)
	else
		user_info.timestamp.strength_timer = cur_time
	end

	return user_info.strength
end


function UserInfo:resetLevel( num )
	
	local user_info = self:getUserInfo()
	CoreUser.setLevel(num, user_info)
	local conf = CONF.PLAYERLEVEL.check(user_info.level)
	user_info.exp = conf.EXP_ALL - 1
end

function UserInfo:addRes(index,num)

	local user_info = self:getUserInfo()

	CoreUser.addRes(index, num, user_info)
end

function UserInfo:addCredit(num)
	local user_info = self:getUserInfo()
	user_info.money = user_info.money + num
end

function UserInfo:removeGroupHelp( type, id )

	local user_info = self:getUserInfo()

	local group_main = self:getGroupMainFromGroupCache()
	if not group_main then
		return
	end
	if Tools.isEmpty(group_main.help_list) == true then
		return
	end
	for i,v in ipairs(group_main.help_list) do
		if v.user_name == user_info.user_name then
			if v.type == type and v.id[1] == id then
				table.remove(group_main.help_list, i)

				GroupCache.update(group_main, user_info.user_name)

				--todo
				break
			end
		end
	end

end


function UserInfo:getIdleBuildQueue( cd )
	local user_info = self:getUserInfo()
	for i,v in ipairs(user_info.build_queue_list) do
		local flag = false
		if v.open_time < 0 and v.type == 0 then
			return v
		elseif v.open_time > 0 then
			local remain = v.open_time + v.duration_time - os.time()
			if remain > cd then
				return v
			end
		end
	end
	return nil
end

function UserInfo:resetBuildQueue( type, index )
	local user_info = self:getUserInfo()
	for i,v in ipairs(user_info.build_queue_list) do

		if type == v.type and index == v.index then
			v.type = 0
			v.index = 0
			return true
		end
	end
	return false
end

function UserInfo:createBuildingInfo(index)

	local info = {
		level = 1,
	}
	return info
end

function UserInfo:upgradeBuildingLevel(index, info)

	if not info then
		return false
	end

	local confList = CONF[string.format("BUILDING_%d",index)]
	if not confList then
		return false
	end
	local nextConf = confList.check(info.level+1)
	if not nextConf then
		return false
	end

	info.level = info.level + 1
	info.upgrade_begin_time = 0
	info.helped = false


	self:resetBuildQueue(1, index)

	if index == 4 then
		local weapon_list = confList.get(info.level).WEAPON_LIST
		if weapon_list ~= nil and weapon_list ~= "" and Tools.isEmpty(weapon_list) == false then
			for k,v in ipairs(weapon_list) do
				self:addWeapon(v)
			end
		end
	end

	local user_info = self:getUserInfo()

		
	local other_user_info = UserInfoCache.get(user_info.user_name)
	if other_user_info then

		other_user_info.building_level_list[index] = info.level
		
		UserInfoCache.set(user_info.user_name, other_user_info)
	end


	self:removeGroupHelp(CONF.EGroupHelpType.kBuilding, index)

	--更新活动数据
	local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
	if activity_list then
		for i,v in ipairs(activity_list) do
			local count = v.seven_days_data.building_levelup_count or 0
			v.seven_days_data.building_levelup_count = count + 1
		end
	end

	--等级去掉护盾 --移到点击事件上
	--[[local confP = CONF.PARAM.get("shield_break_building_level").PARAM
	if index == confP[1] then
		Tools._print("upgradeBuildingLevel",index,info.level)
		if info.level >= confP[2] then
			local planet_user = PlanetCache.getUser(user_info.user_name)
			if planet_user then
				local base = PlanetCache.getElement(planet_user.base_global_key)
				if base	and base.base_data.shield_type and base.base_data.shield_type == 1 then
					Tools._print("upgradeBuildingLeve close")
					PlanetCache.closeShield(base)
				end
			end
		end
	end]]
	
	return true
end

function UserInfo:getBuildingCDTime( index, info, isOrg )
	local confList = CONF[string.format("BUILDING_%d",index)]
	if not confList then
		return 
	end
	local conf = confList.check(info.level)
	if not conf then
		return 
	end
	if isOrg == true then
		return conf.CD
	end
	--检查科技减少CD时间
	local user_info = self:getUserInfo()
	local group_main = self:getGroupMainFromGroupCache()	
	local cd = conf.CD + Tools.getValueByTechnologyAddition( conf.CD, CONF.ETechTarget_1.kBuilding, index, CONF.ETechTarget_3_Building.kCD, self:getTechnologyList(), group_main and group_main.tech_list or nil,PlanetCache.GetTitleTech(user_info.user_name))

	return cd
end

function UserInfo:getBuildingInfo(index)
	if index < 1 or index > CONF.EBuilding.count then
		return nil
	end
	local user_info = self:getUserInfo()
	local building_list = rawget(user_info, "building_list")
	if Tools.isEmpty(building_list) then
		building_list = {}
		rawset(user_info, "building_list", building_list)
	end
	if Tools.isEmpty(building_list[index]) then
		building_list[index] = self:createBuildingInfo(index)
		if index == 4 then
			local confList_t = CONF[string.format("BUILDING_%d",index)]
			local weapon_list = confList_t.get(1).WEAPON_LIST
	  		for k,v in ipairs(weapon_list) do
	  			self:addWeapon(v)
	  		end
		end
	end
	local function checkUpgraded( index, info )

		if info.upgrade_begin_time ~= nil and info.upgrade_begin_time > 0 then
			--检查科技减少CD时间
			local cd = self:getBuildingCDTime(index, info)
			if cd == nil then
				return
			end
			if os.time() >= info.upgrade_begin_time + cd then
				return self:upgradeBuildingLevel(index, info)
			end
		elseif info.upgrade_exp ~= nil and info.upgrade_exp > 0 then
		
			local confList = CONF[string.format("BUILDING_%d",index)]
			local flag = false
			local start = info.level
			for i=0,100 do
				local conf = confList.check(start + i)
				if not conf or not conf.EXP then
					break
				end
				if info.upgrade_exp >= conf.EXP then
					self:upgradeBuildingLevel(index, info)
					flag = true
				else
					break
				end
			end
			return flag
		end
		
		return false
	end
	local isUpgrade = checkUpgraded(index, building_list[index])
	return building_list[index], isUpgrade
end



function UserInfo:getWeaponList()
	local user_info = self:getUserInfo()
	local weapon_list = user_info.weapon_list
	if Tools.isEmpty(weapon_list) then
		weapon_list = {}
		user_info.weapon_list = weapon_list
	end
	return weapon_list
end

function UserInfo:checkWeaponId(kind_id)
	local user_info = self:getUserInfo()
	local weapon_list = user_info.weapon_list
	for i,v in ipairs(weapon_list) do
		local weapon_kind_id = CONF.WEAPON.get(v.weapon_id).KIND_ID
	 	if weapon_kind_id == kind_id then
	 		return 1
	 	end
	end 
	return 0
end

function UserInfo:addWeapon( weapon_id)
	local weapon_list = self:getWeaponList()
	local conf = CONF.WEAPON.get(weapon_id)

	if not conf then
		return nil
	end

	local check_result = self:checkWeaponId(conf.KIND_ID)
	if check_result == 1 then
			return nil
	end
            local weapon_info =
            {
                guid = Tools.getGuid(weapon_list, "guid"),
                weapon_id = conf.ID,
            }
            table.insert(weapon_list, weapon_info)
            return weapon_info
end

function UserInfo:upgradeWeapon( guid, weapon_id, item_list)

	local conf = CONF.WEAPON.check(weapon_id)
	if not conf then
		return 1
	end

	local nextConf = CONF.WEAPON.check(weapon_id+1)
	if not nextConf then
		return 2
	end

	local user_info   = self:getUserInfo()
	local weapon_list = self:getWeaponList()


	local weapon_info
	for i,v in ipairs(weapon_list) do
		if v.guid == guid and v.weapon_id == weapon_id then
			weapon_info = v
		end
	end

	if weapon_info == nil then
		return 3
	end



	local building_info = self:getBuildingInfo(CONF.EBuilding.kWeaponDevelop)

	if building_info.level < nextConf.BUILDING_LEVEL then
		return 4
	end

	local item_id  = CONF.WEAPON.get(weapon_id).MATERIAL_ID
	local item_num = CONF.WEAPON.get(weapon_id).MATERIAL_NUM
	local items = {}
	items[item_id] = item_num

	if CoreItem.checkItems(items, item_list, user_info) == false then
		return 5
	end

	CoreItem.expendItems(items, item_list, user_info)

	weapon_info.weapon_id = weapon_id + 1
	
	local user_sync = CoreItem.makeSync( items, item_list, user_info)
	user_sync.weapon_list = weapon_list

	--更新活动数据
	local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
	if activity_list then
		for i,v in ipairs(activity_list) do
			local count = v.seven_days_data.weapon_levelup_count or 0
			v.seven_days_data.weapon_levelup_count = count + 1
		end
	end
	user_sync.activity_list = activity_list

   	return 0 , weapon_id + 1, user_sync
end

function UserInfo:removeWeaponByID( weapon_id)
	local weapon_list = self:getWeaponList()

	for i=#weapon_list,1,-1 do
		if weapon_list[i].weapon_id == weapon_id then
			table.remove(weapon_list,i)
		end
	end
end


function UserInfo:getStageData()
	local user_info  = self:getUserInfo()
	local stage_data = rawget(user_info, "stage_data")
	if Tools.isEmpty(stage_data) then
		stage_data = {
			level_info = {},
			copy_data = {},
		}
		rawset(user_info, "stage_data", stage_data)
	end
	return stage_data
end

function UserInfo:getLevelList()
	local stage_data = self:getStageData()

	if not stage_data.level_info or Tools.isEmpty(stage_data.level_info) then

		stage_data.level_info = {}
	end
	return stage_data.level_info
end

function UserInfo:getLevelStar( level_id )

	for k,v in ipairs(self:getLevelList()) do
		if v.level_id == level_id then
			return v.level_star	
		end
	end
	return 0
end

function UserInfo:setLevelStar( level_id, level_star)
	local level_list = self:getLevelList()
	local flag = false
	for k,v in ipairs(level_list) do
		if v.level_id == level_id then
			if level_star > v.level_star then
				v.level_star = level_star
			end
			flag = true
			break
		end
	end

	if flag == false then
		local level_info =
		{
			level_id = level_id,
			level_star = level_star,
		}
		table.insert(level_list, level_info)
		return level_info
	end
end

function UserInfo:isGotStageCopyReward( copy_id, score_id )
	local stage_data = self:getStageData()

	if not stage_data.copy_data or Tools.isEmpty(stage_data.copy_data) then
		return false
	end

	for i,v in ipairs(stage_data.copy_data) do
		if v.copy_id == copy_id then
			if not v.got_reward or Tools.isEmpty(v.got_reward) then
				return false
			end
			return v.got_reward[score_id]
		end
	end

	return false
end

function UserInfo:setGotStageCopyReward( copy_id, score_id )
	local stage_data = self:getStageData()

	if not stage_data.copy_data or Tools.isEmpty(stage_data.copy_data) then

		stage_data.copy_data = {}
	end

	local flag = false
	for i,v in ipairs(stage_data.copy_data) do
		if v.copy_id == copy_id then
			v.got_reward[score_id] = true
			flag = true
			break
		end
	end

	if flag == false then
		local copy = {
			copy_id = copy_id,
			got_reward = {false,false,false},
		}
		copy.got_reward[score_id] = true
		table.insert(stage_data.copy_data, copy)
	end
end

function UserInfo:getStageCopyStarNum( copy_id )

	local conf = CONF.COPY.get(copy_id)
	local count = 0
	for i,v in ipairs(conf.LEVEL_ID) do
		count = count + self:getLevelStar(v)
	end
	return count
end

function UserInfo:getHomeInfo()
	local user_info  = self:getUserInfo()
	local home_info = rawget(user_info, "home_info")
	if Tools.isEmpty(home_info) then
		home_info = {
			land_info = {},
			max_land_num = 0,
		}
		rawset(user_info, "home_info", home_info)
	end
	return home_info
end

function UserInfo:getHomeLandList()
	local home_info = self:getHomeInfo()
	local land_list = home_info.land_info
	if Tools.isEmpty(land_list) then
		land_info = {}
		home_info.land_info = land_info
		return home_info.land_info
	end
	return land_list
end

function UserInfo:_calHomeRes(land_info)

	local user_info = self:getUserInfo()


	local add = 1+(CONF.VIP.get(user_info.vip_level).EXTRA_HOME_RESOURCE/100)

	local build_info = self:getBuildingInfo(CONF.EBuilding.kMain)
	add = add + CONF.BUILDING_1.get(build_info.level).HOME_PRODUCTION


	local conf = CONF.RESOURCE.get(land_info.resource_type)

	
	local group_main = self:getGroupMainFromGroupCache()
	local tech_list = self:getTechnologyList()
	local group_tech_list = group_main and group_main.tech_list or nil
	local productionAddition = Tools.getValueByTechnologyAddition(conf.PRODUCTION_NUM*add, CONF.ETechTarget_1.kHomeRes, conf.TYPE, CONF.ETechTarget_3_Res.kProduction, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_info.user_name))

	local storageAddition = Tools.getValueByTechnologyAddition(conf.STORAGE, CONF.ETechTarget_1.kHomeRes, conf.TYPE, CONF.ETechTarget_3_Res.kStorage, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_info.user_name))

	local result  = (conf.PRODUCTION_NUM *add + productionAddition) * ( (os.time() - land_info.res_refresh_times) / 3600 )
	--print("_calHomeRes",user_info.user_name, (conf.PRODUCTION_NUM *add + productionAddition), (os.time() - land_info.res_refresh_times))

	local res_capacity = conf.STORAGE + storageAddition
	if result > res_capacity then
		result = res_capacity
	end
	return math.floor(result)
end

function UserInfo:upgradeHomeBuilding( info, time )
	if info == nil then
		return
	end
	local user_info = self:getUserInfo()

	info.resource_type = info.resource_type + 1
	info.resource_level = info.resource_level + 1

	info.resource_status = 2
	info.res_refresh_times = time
	info.resource_num = 0
	info.helped = false

	self:resetBuildQueue(2, info.land_index)

	self:removeGroupHelp(CONF.EGroupHelpType.kHome, info.land_index)

	--更新活动数据
	local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
	if activity_list then
		for i,v in ipairs(activity_list) do
			local count = v.seven_days_data.home_levelup_count or 0
			v.seven_days_data.home_levelup_count = count + 1
		end
	end
end

function UserInfo:getHomeBuildingCDTime( type, isOrg)
	local user_info = self:getUserInfo()
	local conf = CONF.RESOURCE.get(type)

	local group_main = self:getGroupMainFromGroupCache()

	if isOrg == true then
		return conf.CD
	end

	local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kHomeBuilding, type, CONF.ETechTarget_3_Building.kCD, self:getTechnologyList(), group_main and group_main.tech_list or nil, PlanetCache.GetTitleTech(user_info.user_name))
	return cd
end

function UserInfo:getHomeData()
	local land_list = self:getHomeLandList()
	local build_info = self:getBuildingInfo(CONF.EBuilding.kMain)
	local resource_num = CONF.BUILDING_1.get(build_info.level).RESOURCE_NUM
	local ret = 2
	local home_info = self:getHomeInfo()	

	if resource_num > 0 then 

		home_info.max_land_num = resource_num		
		ret = 0
		for k,v in ipairs(land_list) do
			if v.resource_status == 1 then
				-- building
	        			local cd = self:getHomeBuildingCDTime(v.resource_type)
				local time = v.res_refresh_times + cd
				if os.time() >= time then
				
					self:upgradeHomeBuilding(v, time)
				end
			elseif v.resource_status == 2 then
				--produce
				v.resource_num = self:_calHomeRes(v)
				
			elseif v.resource_status == 3 then
				--remove
				local conf = CONF.RESOURCE.get(v.resource_type)
				if os.time() >= v.res_refresh_times then
					table.remove(land_list,k)
				end
			else

			end
		end		
	end

	return ret, home_info
end

function UserInfo:getHomeBuildingLevel( type )
	local ret, home_data = UserInfo:getHomeData()
	if ret == 0 and Tools.isEmpty(home_data.land_info) == false  then

		local max_level = 0

		for i,v in ipairs(home_data.land_info) do
			local conf = CONF.RESOURCE.get(v.resource_type)
			if conf.TYPE == type and v.resource_level > max_level then
				max_level = v.resource_level
			end
		end
		return max_level
		
	end
	return 0
end

function UserInfo:calGetHomeResource( type )
	local user_info = self:getUserInfo()
	local land_list = self:getHomeLandList()

	local resource_num = 0
	for _,v in ipairs(land_list) do
		local conf = CONF.RESOURCE.get(v.resource_type)
		if (conf.TYPE +1) == type then
			resource_num = resource_num + self:_calHomeRes(v)
		end
	end
	return resource_num
end

function UserInfo:getHomeResource( index, item_list)
	local user_info = self:getUserInfo()
	local land_list = self:getHomeLandList()
	local ret = 1
	local resource_type, resource_num

	local daily_data

	for k,v in ipairs(land_list) do
		if v.land_index == index then
			
			local item_num = self:_calHomeRes(v)

			local conf = CONF.RESOURCE.get(v.resource_type)

			local item_id  = conf.PRODUCTION_ID
		
			item_num = item_num - SlaveCache.slaveSetRes(user_info.user_name, conf.TYPE + 1, item_num)

			--local vipConf = CONF.VIP.get(user_info.vip_level)
			--if vipConf and vipConf.EXTRA_HOME_RESOURCE>0 then
			--	item_num = item_num + (item_num*vipConf.EXTRA_HOME_RESOURCE)/100
			--end
		
			if item_num < 0 then
				item_num = 0
			end

			CoreItem.addItemList(item_id, item_num, item_list, user_info)

			v.res_refresh_times = os.time()
			v.resource_num = 0
			resource_type = v.resource_type
			resource_num  = item_num
			ret = 0

			--更新每日数据
			daily_data = CoreUser.getDailyData(user_info)
			if not daily_data.get_home_res_times then
				daily_data.get_home_res_times = 1
			else
				daily_data.get_home_res_times = daily_data.get_home_res_times + 1
			end
			
			break
		end
	end
	local user_sync = CoreItem.syncRes(user_info)
	if user_sync and daily_data then
		user_sync.user_info.daily_data = daily_data
	end
	return ret, resource_type, resource_num, user_sync
end


function UserInfo:getTechnologyData()
	local user_info  = self:getUserInfo()
	local tech_data = rawget(user_info, "tech_data")
	if Tools.isEmpty(tech_data) then
		tech_data =  {
			upgrade_busy = 0,
			tech_id      = 0,
			tech_info    = {},
		}
		rawset(user_info, "tech_data", tech_data)
	end
	return tech_data
end

function UserInfo:getTechnologyList()

	return self:getTechnologyData().tech_info
end

function UserInfo:getTechnologyInfoByID( tech_id )
	local tech_list = self:getTechnologyList()
	for k,m in ipairs(tech_list) do
		if m.tech_id == tech_id then
			return m
		end
	end
	return nil
end

function UserInfo:removeTechnologyByID(tech_id)
	local tech_list = self:getTechnologyList()
	for k,m in ipairs(tech_list) do
		if m.tech_id == tech_id then
			table.remove(tech_list,k)
			return true
		end
	end
	return false
end

function UserInfo:getTechnologyCDTime( tech_id, isOrg)
	local user_info  = self:getUserInfo()
	local conf = CONF.TECHNOLOGY.get(tech_id)

	local group_main = self:getGroupMainFromGroupCache()
	if isOrg == true then
		return conf.CD
	end

	local cd = conf.CD + Tools.getValueByTechnologyAddition( conf.CD, CONF.ETechTarget_1.kTechnology, 0, CONF.ETechTarget_3_Building.kCD, self:getTechnologyList(), group_main and group_main.tech_list or nil , PlanetCache.GetTitleTech(user_info.user_name))
	return cd
end

function UserInfo:upgradeTechnology( info )

	local tech_data = self:getTechnologyData()

	info.begin_upgrade_time = 0
	tech_data.upgrade_busy = 0
	tech_data.tech_id = 0

	self:removeGroupHelp(CONF.EGroupHelpType.kTechnology, info.tech_id)

	self:removeTechnologyByID(info.tech_id - 1)

	--更新活动数据
	local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
	if activity_list then
		for i,v in ipairs(activity_list) do
			local count = v.seven_days_data.technology_levelup_count or 0
			v.seven_days_data.technology_levelup_count = count + 1
		end
	end
end

function UserInfo:getTechnologyInfo()
	local user_info   = self:getUserInfo()
	local tech_list = self:getTechnologyList()	
	local tech_data = self:getTechnologyData()

	local hasUpgrade = false

	if tech_data.upgrade_busy > 0 then
		for i,v in ipairs(tech_list) do
			if v.tech_id == tech_data.tech_id then
			
	        			local cd = self:getTechnologyCDTime(v.tech_id)

				if os.time() >= v.begin_upgrade_time + cd then
					self:upgradeTechnology(v)
					hasUpgrade = true
				end
				break
			end
		end
	end

	return tech_data, hasUpgrade
end

function UserInfo:getAchievementData( )

	local user_info  = self:getUserInfo()
	local achievement_data = rawget(user_info, "achievement_data")
	if Tools.isEmpty(achievement_data) then
		achievement_data =  {

		}
		rawset(user_info, "achievement_data", achievement_data)
	end
	return achievement_data
end


function UserInfo:getTrialData()

	local user_info  = self:getUserInfo()
	local trial_data = rawget(user_info, "trial_data")
	if Tools.isEmpty(trial_data) then

		local data  =  {
			ticket_num = GolbalDefine.trial_init_ticket_num,
			badge = 0,
		}
		trial_data = data
		rawset(user_info, "trial_data", data)
	end
	return trial_data
end

function UserInfo:getTrialArea( area_id )

	local trial_data = self:getTrialData()

	if Tools.isEmpty(trial_data.area_list) == false then
		for index,area in ipairs(trial_data.area_list) do
			if area.area_id == area_id then
				return area
			end
		end
	end
	return nil
end

function UserInfo:addBadge( value )
	if value <= 0 then
		return
	end

	local trial_data = self:getTrialData()
	trial_data.badge = trial_data.badge + value

end


function UserInfo:getTrialLevelByID( level_id )

	local trial_data = self:getTrialData()

	if not trial_data.level_list or Tools.isEmpty(trial_data.level_list) == true then
		return nil
	end

	for i,v in ipairs(trial_data.level_list) do
		if level_id == v.level_id then
			return v
		end
	end
	return nil
end

function UserInfo:setTrialLevel( level_id, star )

	local user_info = self:getUserInfo()

	local trial_data = self:getTrialData()

	if not trial_data.level_list or Tools.isEmpty(trial_data.level_list) == true then
		trial_data.level_list = {}
	end

	local level = self:getTrialLevelByID(level_id)
	local addStar = 0
	if level then
		if star > level.star then
			level.star = star
			addStar = star - level.star
		end
	else

		level = {
			level_id = level_id,
			star = star,
		}
		addStar = star
		table.insert(trial_data.level_list, level)
	end

	local other_user_info = UserInfoCache.get(user_info.user_name)
	if other_user_info then
		if other_user_info.max_trial_level == nil or level_id > other_user_info.max_trial_level then
			other_user_info.max_trial_level = level_id
		end
		if other_user_info.max_trial_star == nil then
			other_user_info.max_trial_star = addStar 
		elseif addStar > 0 then
			other_user_info.max_trial_star = other_user_info.max_trial_star + addStar
		end
		UserInfoCache.set(user_info.user_name, other_user_info)
	end
end


function UserInfo:getTrialCopyByID( copy_id )

	local trial_data = self:getTrialData()

	if not trial_data.copy_list or Tools.isEmpty(trial_data.copy_list) == true then
		trial_data.copy_list = {}
	end

	local copy
	for i,v in ipairs(trial_data.copy_list) do
		if copy_id == v.copy_id then
			copy = v 
		end
	end

	if not copy then
		copy = {
			copy_id = copy_id,
			reward_flag = 0,
		}
		table.insert(trial_data.copy_list, copy)
	end

	return copy
end

function UserInfo:getArenaData()

	local user_info  = self:getUserInfo()
	local arena_data = rawget(user_info, "arena_data")
	if Tools.isEmpty(arena_data) then
		arena_data =  {
			challenge_times = GolbalDefine.arena_init_challenge_times,
			honour_point = 0,
			purchased_challenge_times = 0,
			daily_reward = 0,
			last_failed_time = 0,
			target_rank = 0,
			already_challenge_times = 0,
			win_challenge_times = 0,
			title_level = 0,
		}
		rawset(user_info, "arena_data", arena_data)
	end
	return arena_data
end

function UserInfo:addArenaChallenged(user_name)

	local arena_data = self:getArenaData()

	if not arena_data.challenged_list or Tools.isEmpty(arena_data.challenged_list) == true then
		arena_data.challenged_list = {}
	end
	table.insert(arena_data.challenged_list, user_name)
end

function UserInfo:isArenaChallenged( user_name )

	local arena_data = self:getArenaData()

	if not arena_data.challenged_list or Tools.isEmpty(arena_data.challenged_list) == true then
		return false
	end

	for i,string in ipairs(arena_data.challenged_list) do
		if user_name == string then
			return true
		end
	end
	return false
end

function UserInfo:clearArenaChallenged()

	local arena_data = self:getArenaData()

	arena_data.challenged_list = nil
end



function UserInfo:getReward( reward_id, item_list, user_sync, reward_addtion_type)
	if reward_id == 0 then
		return user_sync
	end

	local user_info = self:getUserInfo()

	local items = Tools.getRewards( reward_id )
	
	local group_main = self:getGroupMainFromGroupCache()
	local group_tech_list = group_main and group_main.tech_list or nil
	local tech_list = self:getTechnologyList()

	local get_item_list = {}
	for k,v in pairs(items) do
		if reward_addtion_type ~= nil then
			items[k] = items[k] + Tools.getValueByTechnologyAddition( items[k], CONF.ETechTarget_1.kRewordItem, reward_addtion_type, k, tech_list, group_tech_list, PlanetCache.GetTitleTech(user_info.user_name))
		end

		table.insert(get_item_list, {key = k, value = items[k]})
	end

	CoreItem.addItems(items, item_list, user_info)

	user_sync = CoreItem.makeSync(items, item_list, user_info, user_sync)

	return user_sync, get_item_list
end

function UserInfo:getFriendsData()
	local user_info  = self:getUserInfo()
	local friends_data = rawget(user_info, "friends_data")
	if Tools.isEmpty(friends_data) then
		friends_data = {
			friends_list = {},
			black_list = {},
			talk_list = {},
		}
		rawset(user_info, "friends_data", friends_data)
	end
	return friends_data
end

function UserInfo:getTaskInfo( task_id )
	local user_info = self:getUserInfo()

	local task_list = rawget(user_info, "task_list")

	if Tools.isEmpty(task_list) == false then
		for i,v in ipairs(task_list) do
			if v.task_id == task_id then
				return v, i
			end
		end
	end
	return nil
end

function UserInfo:addTaskInfo( task_id, flag )

	local user_info = self:getUserInfo()

	local task_list = rawget(user_info, "task_list")

	task_list = task_list or {}

	for i,v in ipairs(task_list) do
		if v.task_id == task_id then
			return false
		end
	end

	flag = flag or false

	table.insert(task_list, {
		task_id = task_id,
		finished = flag or false,
	})

	rawset(user_info, "task_list", task_list)

	return true
end

function UserInfo:removeTaskInfo( index )

	local user_info = self:getUserInfo()

	local task_list = rawget(user_info, "task_list")

	if Tools.isEmpty(task_list) then
		return false
	end

	if index < 0 or index > #task_list then
		return false
	end

	table.remove( task_list, index)

	return true
end

function UserInfo:resetDailyTask( )

	local user_info = self:getUserInfo()
	local task_list = rawget(user_info, "task_list")

	--删除日常任务
	if task_list ~= nil then
		for i=#task_list, 1, -1 do
			local task_id = task_list[i].task_id

			local conf = CONF.TASK.get(task_id)

			if conf.TYPE == 1 then
				table.remove(task_list, i)
			end
		end
	end

	--添加日常任务
	local id_list = CONF.DAILYTASK.getIDList()

	for i=1,#id_list do
		local dailyConf =  CONF.DAILYTASK.get(id_list[i])

		if dailyConf.START_LEVEL <= user_info.level and dailyConf.END_LEVEL >= user_info.level then

			for _,id in ipairs(dailyConf.TASKS) do
				self:addTaskInfo(id)
			end
			break
		end
	end
end

function UserInfo:getShopData( )

	local user_info  = self:getUserInfo()
	local shop_data = rawget(user_info, "shop_data")
	if Tools.isEmpty(shop_data) then
		shop_data = {
			goods_list = {},
		}
		rawset(user_info, "shop_data", shop_data)
	end
	return shop_data
end

function UserInfo:addShopTimes(id, num )

	if num < 0 then
		return false
	end

	local shop_data = self:getShopData()

	local goodsConf = CONF.SHOP.get(id)

	if Tools.isEmpty(shop_data.goods_list) == true then

		if goodsConf.TIMES > 0 and num > goodsConf.TIMES then
			return false
		end
		local goods = {
			id = id,
			buy_times = num,
		}
		shop_data.goods_list = {goods}
		return true
	else

		for i,goods in ipairs(shop_data.goods_list) do
			if goods.id == id then
				if goodsConf.TIMES > 0 and goods.buy_times + num > goodsConf.TIMES then
					return false
				end
				goods.buy_times = goods.buy_times + num
				return true
			end
		end

		if goodsConf.TIMES > 0 and num > goodsConf.TIMES then
			return false
		end
		table.insert(shop_data.goods_list, {
			id = id,
			buy_times = num,
		})
		return true
	end

	return false
end

function UserInfo:resetShopData( )
	local shop_data = self:getShopData()
	if Tools.isEmpty(shop_data.goods_list) == true then
		return
	end
	shop_data.goods_list = nil
end

function UserInfo:getShipLotteryData( )
	local user_info  = self:getUserInfo()
	local ship_lottery_data = rawget(user_info, "ship_lottery_data")
	if Tools.isEmpty(ship_lottery_data) then
		ship_lottery_data = {
			info_list = {}
		}
		rawset(user_info, "ship_lottery_data", ship_lottery_data)
	end
	return ship_lottery_data
end


function UserInfo:getShipLotteryInfo( id )
	local data = self:getShipLotteryData()

	for i,v in ipairs(data.info_list) do
		if v.id == id then
			return v
		end
	end

	local conf = CONF.SHIP_LOTTERY.get(id)
	local info = {
		id = id,
		free_times = conf.FREE_TIMES,
		add_free_start_time = 0,
		cd_start_time = 0,
		single_times = 0,
	}

	if Tools.isEmpty(data.info_list) == true then
		data.info_list = {info}
	else
		table.insert(data.info_list, info)
	end
	return info
end

function UserInfo:resetShipLotteryData( )
	local data = self:getShipLotteryData( )
	for i,v in ipairs(data.info_list) do
		local conf = CONF.SHIP_LOTTERY.get(v.id)
		if conf.RESET == 0 then
			v.free_times = conf.FREE_TIMES
		end
	end
end


function UserInfo:resetActivityData()
 	local user_info = self:getUserInfo()
 	if Tools.isEmpty(user_info.activity_list) then
		return nil
	end
	for i,activity in ipairs(user_info.activity_list) do

		--兑换活动清空每日数据
		if activity.type == CONF.EActivityType.kChange then
			if Tools.isEmpty(activity.change_data.limit_list) == false then
				for i=#activity.change_data.limit_list, 1, -1 do

					local conf = CONF.CHANGEITEM.get(activity.change_data.limit_list[i].key)
					if conf.LIMIT_TYPE == 1 then
						table.remove(activity.change_data.limit_list, i)
					end
				end
			end
		elseif activity.type == CONF.EActivityType.kSignIn then
			if activity.sign_in_data.getted_today == true then
				activity.sign_in_data.getted_today = false
			end
		elseif activity.type == CONF.EActivityType.kOnline then
			if Tools.isEmpty(activity.online_data.get_indexs) == false then
				activity.online_data.get_indexs = {0,}
			end
		end


	end
 end 

function UserInfo:getUserBuff()
	local pb = require "protobuf"
	return pb.encode("UserInfo", self.m_user_info)
end

function UserInfo:getUserInfo()
	return self.m_user_info
end

function UserInfo:setUserInfo(user_info)
	self.m_user_info = user_info
end

function UserInfo:new(user_buff)
	local user_info
	if user_buff then
		local pb = require "protobuf"
		user_info = pb.decode("UserInfo", user_buff)
		SyncUserCache.sync( user_info )
	else
		user_info = {}
	end
	self.m_user_info = user_info
end

return UserInfo
