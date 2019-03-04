local CoreItem = {}

function CoreItem.addRes(user_info, index, value)

	local sync_user = SyncUserCache.getSyncUser(user_info.user_name)
	local add = CoreItem.addValue(sync_user.res[index], value)
	if add > 0 then

		sync_user.res[index] = sync_user.res[index] + add

		local conf = CONF.BUILDING_10.get(user_info.building_list[CONF.EBuilding.kWarehouse].level)
		if sync_user.res[index] > conf.RESOURCE_UPPER_LIMIT[index] then
			sync_user.res[index] = conf.RESOURCE_UPPER_LIMIT[index]
		end

		SyncUserCache.setSyncUser(sync_user)

		SyncUserCache.sync(user_info)

		--LOG
		if index == 1 then--暂时只记金币
			LOG_STAT( string.format( "%s|%s|%d|%d|%d", "RES", user_info.user_name, index , add , sync_user.res[index]) )
		end
	end
	return add
end

function CoreItem.addExp(user_info, value)
	local add = CoreItem.addValue(user_info.exp, value)
	if add > 0 then
		CoreUser.addExp(add, user_info)
	end
	return add
end


function CoreItem.addMoney(user_info, money)
	local add = CoreItem.addValue(user_info.money, money)
	if add > 0 then
		user_info.money = user_info.money + add
	end
	return add
end

function CoreItem.addStrength(user_info, value)
	local add = CoreItem.addValue(user_info.strength, value)
	if add > 0 then
		user_info.strength = user_info.strength + value
	end
	return add
end

function CoreItem.addHonour(user_info, value)

	if not user_info.arena_data then
		return nil
	end

	local add = CoreItem.addValue(user_info.arena_data.honour_point, value)
	if add > 0 then
		user_info.arena_data.honour_point = user_info.arena_data.honour_point + add
	end
	return add
end

function CoreItem.addBadge(user_info, value)

	if not user_info.trial_data then
		return nil
	end

	local add = CoreItem.addValue(user_info.trial_data.badge, value)
	if add > 0 then
		user_info.trial_data.badge = user_info.trial_data.badge + add
	end
	return add
end


function CoreItem.addEquip( user_info, equip_id, value )
	local equip = require "Equip"

	for i=1,value do
		equip:addEquip(equip_id, user_info)
	end
end

function CoreItem.addGem( user_info, gem_id, value )
	local equip = require "Equip"

	equip:addGem(gem_id, value, user_info)
end

function CoreItem.addItem(item_id, item_num, item_list, user_info)
	if item_num > 0 then

		CoreItem.addItemList(item_id, item_num, item_list, user_info)
	else
		if item_num < 0 then
			CoreItem.expendItemList(item_id, item_num, item_list, user_info)
		end
	end
end


function CoreItem.addItemList(item_id, item_num, item_list, user_info)
	local conf = CONF.ITEM.check(item_id)
	if not conf then

		return
	end

	if conf.TYPE >= CONF.EItemType.kRes1 and conf.TYPE <= CONF.EItemType.kRes4 then
		if user_info then
			CoreItem.addRes(user_info, conf.TYPE - CONF.EItemType.kRes1 + 1,item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kMoney then
		if user_info then
			CoreItem.addMoney(user_info, item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kStrength then
		if user_info then
			CoreItem.addStrength(user_info, item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kExp then

		if user_info then
			CoreItem.addExp(user_info, item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kHonour then

		if user_info then
			CoreItem.addHonour(user_info, item_num)
		end

	elseif conf.TYPE == CONF.EItemType.kBadge then

		if user_info then
			CoreItem.addBadge(user_info, item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kEquip then

		if user_info then
			CoreItem.addEquip(user_info, item_id,item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kGem then
		if user_info then
			CoreItem.addGem(user_info, item_id,item_num)
		end
	else
		local item_info
		if Tools.isEmpty(item_list) == false then
			for k,v in ipairs(item_list) do
				if v.id == item_id then
					item_info = v
					break
				end
			end
		end
		
		if not item_info then
			local guid = 0
			if Tools.isEmpty(item_list) == false then
				for k,v in ipairs(item_list) do
					if guid < v.guid then
						guid = v.guid
					end
				end
			end
			item_info =
			{
			    	guid = guid + 1,
			    	id = item_id,
			    	num = 0,
			}
		
			table.insert(item_list, item_info)
		end
		local add = CoreItem.addValue(item_info.num, item_num)
		if add > 0 then
			item_info.num = item_info.num + add
		end
	end
end

function CoreItem.addItems(items, item_list, user_info)

	for item_id, item_num in pairs(items) do
		CoreItem.addItem(item_id, item_num, item_list, user_info)
	end
end


function CoreItem.addValue(value, add, min, max)
	min = min or 0
	max = max or 9999999999
	local val
	if add > 0 then
		if value + add > max then
			val = max - value
		else
			val = add
		end
	else
		if value + add < min then
			val = min - value
		else
			val = add
		end
	end
	return val
end

function CoreItem.checkRes(user_info, index, value)
	local sync_user = SyncUserCache.getSyncUser(user_info.user_name)
	if index < 1 or index > #sync_user.res then
		return false
	end
	local expend = value > 0 and value or -value
	return sync_user.res[index] >= expend
end

function CoreItem.checkMoney(user_info, money)
	local expend = money > 0 and money or -money
	return user_info.money >= expend
end

function CoreItem.checkStrength(user_info, value)
	local expend = value > 0 and value or -value
	return user_info.strength >= expend
end

function CoreItem.checkHonour(user_info, value )
	if not Tools.isEmpty(user_info.arena_data) then
		return false
	end
	local expend = value > 0 and value or -value
	return user_info.arena_data.honour_point >= expend
end

function CoreItem.checkGem(user_info, gem_id, num)
	
	if Tools.isEmpty(user_info.gem_list) == true then
		LOG_ERROR("checkGem Tools.isEmpty(user_info.gem_list)")
		return false
	end
	local info
	for k,v in ipairs(user_info.gem_list) do
		if v.id == gem_id then
			info = v
			break
		end
	end
	if not info then
		return false
	end
	local expend = (num > 0 and num) or -num
	return info.num >= expend
end

function CoreItem.checkItem(item_id, item_num, item_list, user_info)
	local isCheck = false

	local conf = CONF.ITEM.get(item_id)
	if not conf then
		return isCheck
	end

	if conf.TYPE >= CONF.EItemType.kRes1 and conf.TYPE <= CONF.EItemType.kRes4 then
		if user_info then
			isCheck = CoreItem.checkRes(user_info,  conf.TYPE - CONF.EItemType.kRes1 + 1, item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kMoney then
		if user_info then
			isCheck = CoreItem.checkMoney(user_info, item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kStrength then
		if user_info then
			isCheck = CoreItem.checkStrength(user_info, item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kGem then
		if user_info then
			isCheck = CoreItem.checkGem(user_info, item_id, item_num)
		end
	else
		if Tools.isEmpty(item_list) == true then
			LOG_ERROR("checkItem Tools.isEmpty(item_list)")
			return isCheck
		end
		local item_info
		for k,v in ipairs(item_list) do
			if v.id == item_id then
				item_info = v
				break
			end
		end
		if item_info then
			local expend = item_num > 0 and item_num or -item_num
			isCheck = item_info.num >= expend
		end
	end
	return isCheck
end

function CoreItem.checkItems(items, item_list, user_info)
	local isCheck = true
	for item_id, item_num in pairs(items) do
		isCheck = CoreItem.checkItem(item_id, item_num, item_list, user_info)
		if not isCheck then
			break
		end
	end
	return isCheck
end



function CoreItem.expendRes(user_info, index, value)

	local sync_user = SyncUserCache.getSyncUser(user_info.user_name)

	local expend
	if value > 0 then
		expend = CoreItem.addValue(sync_user.res[index], -value)
	else
		expend = CoreItem.addValue(sync_user.res[index], value)
	end
	if expend < 0 then
		sync_user.res[index] = sync_user.res[index] + expend
		SyncUserCache.setSyncUser(sync_user)
		SyncUserCache.sync(user_info)

		if index == 1 then--暂时只记金币
			LOG_STAT( string.format( "%s|%s|%d|%d|%d", "RES", user_info.user_name, index , expend , sync_user.res[index]) )
		end

	end
	return expend
end


function CoreItem.expendMoney(user_info, money, where, activity_id) -- activity_id：某些活动不计算在活动消费内 需要函数内部需要判断
	local expend
	if money > 0 then
		expend = CoreItem.addValue(user_info.money, -money)
	else
		expend = CoreItem.addValue(user_info.money, money)
	end
	if expend < 0 then
		user_info.money = user_info.money + expend

		--消耗渠道，消耗数量，真元宝数，财务确认金额，留存充值元宝，剩余总真元宝，剩余总元宝，账号，IP，MMC
		if not where then
			where = CONF.EUseMoney.eFree
		end
		LOG_STAT(string.format("%s|%s|%d|%d|%d|%d|%d|%d|%d|%s|%s|%s","CAST_YB",user_info.user_name, where ,expend ,user_info.money, user_info.money, user_info.money, user_info.money, user_info.money, user_info.nickname, "null", "null"))

		if user_info.achievement_data == nil then
			user_info.achievement_data = {}
		end

		--更新建筑经验
		local building_info = user_info.building_list[CONF.EBuilding.kTrade]
		if building_info.upgrade_exp == nil or  building_info.upgrade_exp < 0 then
			building_info.upgrade_exp = 0
		end
		building_info.upgrade_exp = building_info.upgrade_exp - expend

		--更新终身消费
		local count = user_info.achievement_data.consume_money or 0
		count = count - expend
		user_info.achievement_data.consume_money = count

		--更新活动消费
		local function isWithout(id, list )
			if list == nil or list == "" or id == nil then
				return false
			end
			for i,v in ipairs(list) do
				if v == id then
					return true
				end
			end
			return false
		end
		local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kConsume, user_info)
		if activity_list then
			for i,v in ipairs(activity_list) do
				local conf = CONF.ACTIVITYCONSUME.get(v.id)
				if isWithout(activity_id, conf.WITHOUT) == false then
					if Tools.isEmpty(v.consume_data) == true then
						v.consume_data = {consume = -expend}
					else
						v.consume_data.consume = v.consume_data.consume - expend
					end
				end
			end
		end
		
		activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
		if activity_list then
			for i,v in ipairs(activity_list) do
				local count = v.seven_days_data.consume_money or 0
				v.seven_days_data.consume_money = count - expend
			end
		end
	end
	return expend
end


function CoreItem.expendStrength( user_info, value )
	local expend
	if value > 0 then
		expend = CoreItem.addValue(user_info.strength, -value)
	else
		expend = CoreItem.addValue(user_info.strength, value)
	end
	if expend < 0 then
		user_info.strength = user_info.strength + expend
	end
	return expend
end

function CoreItem.expendHonour(user_info, value)
	if not Tools.isEmpty(user_info.arena_data) then
		return 0
	end
	local expend
	if value > 0 then
		expend = CoreItem.addValue(user_info.arena_data.honour_point, -value)
	else
		expend = CoreItem.addValue(user_info.arena_data.honour_point, value)
	end
	if expend < 0 then
		user_info.arena_data.honour_point = user_info.arena_data.honour_point + expend
	end
	return expend
end

function CoreItem.checkBadge(user_info, value)
	if not Tools.isEmpty(user_info.trial_data) then
		return 0
	end
	local expend
	if value > 0 then
		expend = CoreItem.addValue(user_info.trial_data.badge, -value)
	else
		expend = CoreItem.addValue(user_info.trial_data.badge, value)
	end
	if expend < 0 then
		user_info.trial_data.badge = user_info.trial_data.badge + expend
	end
	return expend
end

function CoreItem.expendGem(user_info, gem_id, num)
	if Tools.isEmpty(user_info.gem_list) == true then
		return false
	end
	local info
	for k,v in ipairs(user_info.gem_list) do
		if v.id == item_id then
			info = v
			break
		end
	end
	if not info then
		return false
	end
	local expend
	if num > 0 then
		expend = CoreItem.addValue(info.num, -num)
	else
		expend = CoreItem.addValue(info.num, num)
	end
	if expend < 0 then
		info.num = info.num + expend
	end
	return true
end

function CoreItem.expendItemList(item_id, item_num, item_list, user_info)

	local conf = CONF.ITEM.get(item_id)
	if not conf then
		return
	end

	if conf.TYPE >= CONF.EItemType.kRes1 and conf.TYPE <= CONF.EItemType.kRes4 then
		if user_info then
			CoreItem.expendRes(user_info, conf.TYPE - CONF.EItemType.kRes1 + 1,item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kMoney then
		if user_info then
			CoreItem.expendMoney(user_info, item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kStrength then
		if user_info then
			CoreItem.expendStrength(user_info, item_num)
		end
	elseif conf.TYPE == CONF.EItemType.kGem then
		if user_info then
			CoreItem.expendGem(user_info, item_id, item_num)
		end
	else
		local item_info
		if Tools.isEmpty(item_list) == false then
			for k,v in ipairs(item_list) do
				if v.id == item_id then
					item_info = v
					break
				end
			end
		end
		
		if item_info then
			local expend
			if item_num > 0 then
				expend = CoreItem.addValue(item_info.num, -item_num)
			else
				expend = CoreItem.addValue(item_info.num, item_num)
			end
			if expend < 0 then
				item_info.num = item_info.num + expend
			end
		end
	end
end

function CoreItem.expendItems(items, item_list, user_info)
	for item_id, item_num in pairs(items) do
		CoreItem.expendItemList(item_id, item_num, item_list, user_info)
	end
end



function CoreItem.getAward(items, pool)
	local item_list = {}
	for i=1, #items, 2 do
		local item_info = {}
		item_info.item_id = items[i]
		item_info.item_num = items[i+1]
		table.insert(item_list, item_info)
	end
	local idx = 1
	local t = {}
	for k,v in ipairs(pool) do
		if k > #item_list then
			break
		end
		for i=1, v do
			t[idx] = item_list[k].item_id
			idx = idx + 1
		end
	end
	local item_id = t[math.random(1, #t)]
	local item_info =
	{
		item_id = item_id,
		item_num = 1,
	}
	for k,v in ipairs(item_list) do
		if v.item_id == item_id then
			item_info.item_num = v.item_num
			break
		end
	end
	return item_info
end

function CoreItem.getGuid(item_list)
	local guid = 0
	for k,v in ipairs(item_list) do
		if guid < v.guid then
			guid = v.guid
		end
	end
	return guid + 1
end

function CoreItem.getItem(item_id, item_list )
	for i,v in ipairs(item_list) do
		if v.id == item_id then
			return v
		end
	end
	return nil
end

function CoreItem.syncRes(user_info, user_sync)
	user_sync = user_sync or {
		user_info = {},
	}

	user_sync.user_info.res = Tools.clone(user_info.res)
	return user_sync
end

function CoreItem.syncMoney(user_info, user_sync)
	user_sync = user_sync or {
		user_info = {},
	}

	user_sync.user_info.money = user_info.money
	user_sync.user_info.achievement_data = user_info.achievement_data
	user_sync.user_info.building_list = user_info.building_list
	return user_sync
end

function CoreItem.syncStrength(user_info, user_sync)
	user_sync = user_sync or {
		user_info = {},
	}

	user_sync.user_info.strength = user_info.strength
	return user_sync
end

function CoreItem.syncExp(user_info, user_sync)
	user_sync = user_sync or {
		user_info = {},
	}

	user_sync.user_info.exp = user_info.exp
	user_sync.user_info.level = user_info.level
	return user_sync
end

function CoreItem.syncHonour(user_info, user_sync)
	user_sync = user_sync or {
		user_info = {},
	}

	if not user_info.arena_data then
		return user_sync
	end
	user_sync.user_info.arena_data = user_info.arena_data
	return user_sync
end

function CoreItem.syncBadge(user_info, user_sync)
	user_sync = user_sync or {
		user_info = {},
	}

	if not user_info.trial_data then
		return user_sync
	end
	user_sync.user_info.trial_data = user_info.trial_data
	return user_sync
end

function CoreItem.syncEquip(items, user_info, user_sync )
	user_sync = user_sync or {
		equip_list = {},
	}
	local equip = require "Equip"

	for id,num in pairs(items) do
		local list = equip:getEquipByID(id, user_info)
		if list then

			local count = #list
			if count < num then
				break
			end
			for i=count,count - num + 1, -1 do
				table.insert(user_sync.equip_list, list[i])
			end
		end
	end
end

function CoreItem.syncGem(items, user_info, user_sync )
	user_sync = user_sync or {
		gem_list = {},
	}
	local equip = require "Equip"

	for id,num in pairs(items) do
		local info = equip:getGemInfo(id, user_info)
		if info == nil then
			info = {
				id = -id,
				num = 0,
			}
		end
		table.insert(user_sync.gem_list, info)
	end
end

function CoreItem.makeSync(items, item_list, user_info, user_sync)
	user_sync = user_sync or {
		item_list = {},
		user_info = {},
		equip_list = {},
		gem_list = {},
	}

	local needSyncRes = false
	local needSyncMoney = false
	local needSyncHonour = false
	local needSyncBadge = false
	local needSyncExp = false
	local needSyncStrength = false
	local needSyncEquip = {}
	local needSyncGem = {}

	for item_id, item_num in pairs(items) do

		local conf = CONF.ITEM.check(item_id)
		if conf then
	
			if conf.TYPE >= CONF.EItemType.kRes1 and conf.TYPE <= CONF.EItemType.kRes4 then
				needSyncRes = true
			elseif conf.TYPE == CONF.EItemType.kMoney then
				needSyncMoney = true
			elseif conf.TYPE == CONF.EItemType.kStrength then
				needSyncStrength = true
			elseif conf.TYPE == CONF.EItemType.kExp then
				needSyncExp = true
			elseif conf.TYPE == CONF.EItemType.kHonour then
				needSyncHonour = true
			elseif conf.TYPE == CONF.EItemType.kBadge then
				needSyncBadge = true
			elseif conf.TYPE == CONF.EItemType.kEquip then
				if needSyncEquip[item_id] then
					needSyncEquip[item_id] = needSyncEquip[item_id] + item_num
				else
					needSyncEquip[item_id] = item_num
				end
			elseif conf.TYPE == CONF.EItemType.kGem then

				if needSyncGem[item_id] then
					needSyncGem[item_id] = needSyncGem[item_id] + item_num
				else
					needSyncGem[item_id] = item_num
				end
			else
				local has = false
				if Tools.isEmpty(user_sync.item_list) == false then
					for k,v in pairs(user_sync.item_list) do
						if item_id == v.id then
							has = true
							break
						end
					end
				end

				if has == false then
					local item_info = CoreItem.getItem( item_id, item_list)

					if item_info then
						if Tools.isEmpty(user_sync.item_list) == true then
							user_sync.item_list = {item_info}
						else
							table.insert(user_sync.item_list, item_info)
						end
						
					end
				end
			end
		end
	end


	if user_info then
		if needSyncRes then
			CoreItem.syncRes(user_info, user_sync)
		end

		if needSyncMoney then
			CoreItem.syncMoney(user_info, user_sync)
		end

		if needSyncBadge then
			CoreItem.syncBadge(user_info, user_sync)
		end

		if needSyncStrength then
			CoreItem.syncStrength(user_info, user_sync)
		end

		if needSyncExp then
			CoreItem.syncExp(user_info, user_sync)
		end

		if needSyncHonour then
			CoreItem.syncHonour(user_info, user_sync)
		end


		if Tools.isEmpty(needSyncEquip) == false then

			CoreItem.syncEquip(needSyncEquip, user_info, user_sync)
		end

		if Tools.isEmpty(needSyncGem) == false then

			CoreItem.syncGem(needSyncGem, user_info, user_sync)
		end
	end

	return user_sync
end

return CoreItem
