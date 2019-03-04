

function get_activity_list_feature( step, req_buff, user_name )

	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("GetActivityListResp", resp)

	elseif step == 1 then

		return datablock.main_data + datablock.save, user_name
	else
		error("something error")
	end
end

function get_activity_list_do_logic( req_buff, user_name, user_info_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local resp = {
		result = 0,
		id_list = GolbalActivity.getActivityList( os.time(), user_info ),
		user_sync = {
			user_info = {
				activity_list = user_info.activity_list,
			},
		},
	}

	user_info_buff = userInfo:getUserBuff()
	local resp_buff = Tools.encode("GetActivityListResp",resp)
	return resp_buff, user_info_buff
end



function activity_change_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityChangeResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_change_do_logic( req_buff, user_name, user_info_buff, item_list_buff)
	local req = Tools.decode("ActivityChangeReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local function doLogic(req )

		if GolbalActivity.isOpen( req.activity_id,  os.time(), user_info) == false then
			return 1
		end

		local function getChangeLimitPair( id, activity)
			if Tools.isEmpty(activity.change_data) == true then
				return nil
			end
			for i,v in ipairs(activity.change_data.limit_list) do
				if v.key == id then
					return v
				end
			end
			return nil
		end


		local changeConf = CONF.ACTIVITYCHANGE.get(req.activity_id)
		local has = false
		for i,v in ipairs(changeConf.GROUP) do
			if v == req.change_item_id then
				has = true
				break
			end
		end
		if has == false then
			return 2
		end

		local changeItemConf = CONF.CHANGEITEM.get(req.change_item_id)

		--检查兑换上限
		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if activity then
			local pair = getChangeLimitPair(req.change_item_id, activity)
			if pair then
				if pair.value >= changeItemConf.LIMIT then
					return 3
				end
			end
		end

		
		local removeItems = {}
		for i,v in ipairs(changeItemConf.COST_ITEM) do
			removeItems[v] = changeItemConf.COST_NUM[i]
		end
		if CoreItem.checkItems(removeItems, item_list, user_info) == false then
			return 4
		end

		
		local addItems = {}
		for i,v in ipairs(changeItemConf.GET_ITEM) do
			addItems[v] = changeItemConf.GET_NUM[i]
		end
		if CoreItem.addItems( addItems, item_list, user_info) == false then
			return 5
		end

		if CoreItem.expendItems( removeItems, item_list, user_info) == false then
			return 6
		end

		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
		end

		if Tools.isEmpty(activity.change_data) == true then
			activity.change_data = {
				limit_list = {
					{key = req.change_item_id, value = 1},
				}
			}
		else
			local has = false
			for i,v in ipairs(activity.change_data.limit_list) do
				if v.key == req.change_item_id then
					v.value = v.value + 1
					has = true
					break
				end
			end

			if has == false then
				table.insert(activity.change_data.limit_list, {key = req.change_item_id, value = 1})
			end
		end

		local user_sync = CoreItem.makeSync(addItems, item_list, user_info)

		CoreItem.makeSync(removeItems, item_list, user_info, user_sync)

		user_sync.activity_list = {activity}

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	local resp_buff = Tools.encode("ActivityChangeResp",resp)
	return resp_buff, user_info_buff, item_list_buff
end

function activity_sign_in_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivitySignInResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end
function activity_sign_in_do_logic( req_buff, user_name, user_info_buff, item_list_buff)
	local req = Tools.decode("ActivitySignInReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local function doLogic( req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id,  cur_time, user_info) == false then
			return 1
		end

		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
			activity.sign_in_data = {
				cur_day = 1,
				getted_today = false,
			}
		end

		if activity.sign_in_data.getted_today == true then
			return 2
		end

		local conf = CONF.ACTIVITYSIGNIN.get(activity.sign_in_data.cur_day)
		local items = {[conf.GET]= conf.GET_NUM}

		CoreItem.addItems(items, item_list, user_info)

		activity.sign_in_data.getted_today = true

		activity.sign_in_data.cur_day = activity.sign_in_data.cur_day + 1
		if activity.sign_in_data.cur_day > 7 then
			activity.sign_in_data.cur_day = 1
		end

		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		user_sync.activity_list = {activity}

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	local resp_buff = Tools.encode("ActivitySignInResp",resp)
	return resp_buff, user_info_buff, item_list_buff
end


function activity_seven_days_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivitySevenDaysResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.ship_list + datablock.save, user_name
	else
		error("something error")
	end
end
function activity_seven_days_do_logic( req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
	local req = Tools.decode("ActivitySevenDaysReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local shipList = require "ShipList"
	shipList:new(ship_list_buff , user_name)
	shipList:setUserInfo(user_info)
	local ship_list = shipList:getShipList()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local planet_user = PlanetCache.getUser(user_info.user_name)

	local function doLogic( req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end

		local conf = CONF.ACTIVITYSEVENDAYS.get(req.activity_id)
		local dayIndex = GolbalActivity.getDayIndex( req.activity_id, cur_time, user_info)
		Tools._print("ActivitySevenDaysReq   "..dayIndex.."  "..req.activity_id)
		if dayIndex <= 0 or dayIndex > 7 then
			return 2
		end


		local has = false
		for i=1,dayIndex do
			for _,v in ipairs(conf[string.format("DAY%d",i)]) do

				if v == req.task_id then
					has = true
					break
				end
			end
		end
		if has == false then
			return 3
		end

		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
		end

		if activity.seven_days_data ~= nil then
			if Tools.isEmpty(activity.seven_days_data.getted_reward_list) == false then
				for i,task_id in ipairs(activity.seven_days_data.getted_reward_list) do
					if task_id == req.task_id then
						return 4
					end
				end
			end
		end
		

		local taskConf = CONF.SEVENDAYSTASK.get(req.task_id)
		if Tools.calTask( taskConf, user_info, ship_list, planet_user, activity) == false then
			return 5
		end

		local items = {}
		for i,v in ipairs(taskConf.ITEM_ID) do
			items[v] = taskConf.ITEM_NUM[i]
		end
		if CoreItem.addItems(items, item_list, user_info) == false then
			return 6
		end
		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		local getted_list = activity.seven_days_data.getted_reward_list
		if Tools.isEmpty(getted_list) == true then
			getted_list = {req.task_id}
		else
			table.insert(getted_list, req.task_id)
		end
		activity.seven_days_data.getted_reward_list = getted_list

		user_sync.activity_list = {activity}

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}


	local resp_buff = Tools.encode("ActivitySevenDaysResp",resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end


function activity_first_recharge_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityFirstRechargeResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.ship_list + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_first_recharge_do_logic( req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local req = Tools.decode("ActivityFirstRechargeReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local shipList = require "ShipList"
	shipList:new(ship_list_buff , user_name)
	shipList:setUserInfo(user_info)
	local ship_list = shipList:getShipList()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic( req)
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end

		local achievement_data = userInfo:getAchievementData()

		if achievement_data.recharge_money == nil  or achievement_data.recharge_money <= 0 then
			return 3
		end
		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
			activity.first_recharge_data = {
				getted_reward = false,
			}
		end

		if activity.first_recharge_data.getted_reward == true then
			return 4
		end

		local conf = CONF.ACTIVITYFIRSTRECHARGE.get(req.activity_id)

		if achievement_data.recharge_money < conf.COST then
			return 5
		end

		local items = {}
		for i,v in ipairs(conf.ITEM) do
			items[v] = conf.NUM[i]
		end
		if CoreItem.addItems(items, item_list, user_info) == false then
			return 6
		end
		local user_sync = CoreItem.makeSync(items, item_list, user_info)
		
		local ship_info = shipList:shipCreate( conf.SHIP, user_sync)
		if ship_info == nil then
			return 7
		end

		user_sync.activity_list = {activity}

		activity.first_recharge_data.getted_reward = true

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ActivityFirstRechargeResp",resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end



function activity_recharge_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityRechargeResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.ship_list + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_recharge_do_logic( req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local req = Tools.decode("ActivityRechargeReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local shipList = require "ShipList"
	shipList:new(ship_list_buff , user_name)
	shipList:setUserInfo(user_info)
	local ship_list = shipList:getShipList()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end

		local activityConf = CONF.ACTIVITYRECHARGE.get(req.activity_id)
		local has = false
		for i,v in ipairs(activityConf.GROUP) do
			if v == req.id then
				has = true
				break
			end
		end
		if has == false then
			return 2
		end

		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
		end


		if Tools.isEmpty(activity.recharge_data) == true  then
			return 3
		end

		
		local conf = CONF.RECHARGEITEM.get(req.id)
		if activity.recharge_data.recharge_money < conf.COST then
			return 4
		end
		
		
		if Tools.isEmpty(activity.recharge_data.getted_id_list) == false then
			for i,v in ipairs(activity.recharge_data.getted_id_list) do
				if v == req.id then
					return 5
				end
			end
		end

		local user_sync
		if conf.SHIP ~= 0 then
			user_sync = {}
			local ship_info = shipList:shipCreate( conf.SHIP, user_sync)
			if ship_info == nil then
				return 6
			end
		end

		if Tools.isEmpty(conf.ITEM) == false then
			local items = {}
			for i,v in ipairs(conf.ITEM) do
				items[v] = conf.NUM[i]
			end
			if CoreItem.addItems(items, item_list, user_info) == false then
				return 7
			end
			user_sync = CoreItem.makeSync(items, item_list, user_info, user_sync)
		end

		if Tools.isEmpty(activity.recharge_data.getted_id_list) == true then
			activity.recharge_data.getted_id_list = {req.id}
		else
			table.insert(activity.recharge_data.getted_id_list, req.id)
		end

		user_sync.activity_list = {activity}

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ActivityRechargeResp",resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end


function activity_consume_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityConsumeResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.ship_list + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_consume_do_logic( req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local req = Tools.decode("ActivityConsumeReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local shipList = require "ShipList"
	shipList:new(ship_list_buff , user_name)
	shipList:setUserInfo(user_info)
	local ship_list = shipList:getShipList()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end

		local activityConf = CONF.ACTIVITYCONSUME.get(req.activity_id)
		local has = false
		for i,v in ipairs(activityConf.GROUP) do
			if v == req.id then
				has = true
				break
			end
		end
		if has == false then
			return 2
		end

		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
		end


		if Tools.isEmpty(activity.consume_data) == true  then
			return 3
		end

		local conf = CONF.CONSUMEITEM.get(req.id)
		if activity.consume_data.consume < conf.CONSUME then
			return 4
		end
		
		
		if Tools.isEmpty(activity.consume_data.getted_id_list) == false then
			for i,v in ipairs(activity.consume_data.getted_id_list) do
				if v == req.id then
					return 5
				end
			end
		end

		
		local items = {}
		for i,v in ipairs(conf.ITEM) do
			items[v] = conf.NUM[i]
		end
		if CoreItem.addItems(items, item_list, user_info) == false then
			return 6
		end
		local user_sync = CoreItem.makeSync(items, item_list, user_info)


		if Tools.isEmpty(activity.consume_data.getted_id_list) == true then
			activity.consume_data.getted_id_list = {req.id}
		else
			table.insert(activity.consume_data.getted_id_list, req.id)
		end

		user_sync.activity_list = {activity}

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ActivityConsumeResp",resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end


function activity_credit_return_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityCreditReturnResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_credit_return_do_logic( req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("ActivityRechargeReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end
		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
			activity.credit_retrun_data = {
				return_index = 0,
			}
		end

		if activity.credit_retrun_data.index + 1 ~= req.return_index then
			return 2
		end
		local activityConf = CONF.ACTIVITYCREDITRETURN.get(req.activity_id)
		if #activityConf.GROUP < req.return_index then
			return 3
		end
		local conf = CONF.CREDITRETURN.get(activityConf.GROUP[req.return_index])
		if CoreItem.checkMoney(user_info, conf.INPUT) == false then
			return 4
		end

		CoreItem.expendMoney(user_info, conf.INPUT, CONF.EUseMoney.eCredit_return, req.activity_id)

		local rand = math.random(conf.OUTPUT[1],  conf.OUTPUT[2])
		CoreItem.addMoney(user_info, rand)

		local user_sync = CoreItem.syncMoney(user_info)

		activity.credit_retrun_data.index = req.return_index

		user_sync.activity_list = {activity}
		return 0, user_sync, rand
	end



	local ret, user_sync, rand = doLogic()

	

	local resp = {
		result = ret,
		user_sync = user_sync,
		return_credit = rand,
	}

	local resp_buff = Tools.encode("ActivityCreditReturnResp",resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()

	if ret == 0 then
		--向世界频道推送
		local chat_cmd = 0x1521
		local chat_msg = {
			msg = {string.format(Lang.credit_return_msg, user_info.nickname, rand)},
			channel = 0,
			type = 1,
			sender = {
				nickname = Lang.world_chat_sender,
			},
		}
		local chat_msg_buff = Tools.encode("ChatMsg_t", chat_msg)
		return resp_buff, user_info_buff, item_list_buff, chat_cmd, chat_msg_buff
	end

	return resp_buff, user_info_buff, item_list_buff
end


function activity_online_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityOnlineResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_online_do_logic( req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("ActivityOnlineReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end
		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
		end

		local activityConf = CONF.ACTIVITYONLINE.get(req.activity_id)
		if #activityConf.GROUP < req.index then
			return 2
		end

		if Tools.isEmpty(activity.online_data) == false then
			if Tools.isEmpty(activity.online_data.get_indexs) == false then
				for i,v in ipairs(activity.online_data.get_indexs) do
					if v == req.index then
						return 3
					end
				end
			end
		end

		local conf = CONF.ONLINEGROUP.get(activityConf.GROUP[req.index])
		if conf.TYPE == 1 then
			if user_info.timestamp.today_online_time < conf.TIME then
				return 4
			end
		elseif conf.TYPE == 2 then
			local date = os.date("*t", cur_time)
			if date.hour < conf.TIME[1] or date.hour > conf.TIME[2] then
				return 5
			end
		else
			return 999
		end

		local addItems = {}
		for i,v in ipairs(conf.ITEM) do
			addItems[v] = conf.NUM[i]
		end
		if CoreItem.addItems( addItems, item_list, user_info) == false then
			return 5
		end

		if Tools.isEmpty(activity.online_data) == true then
			activity.online_data = {}
		end
		if Tools.isEmpty(activity.online_data.get_indexs) == false then
			table.insert(activity.online_data.get_indexs, req.index)
		else
			activity.online_data.get_indexs = { req.index}
		end

		local user_sync = CoreItem.makeSync(addItems, item_list, user_info)

		user_sync.activity_list = {activity}

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ActivityOnlineResp",resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end


function activity_power_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityPowerResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.ship_list + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_power_do_logic( req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local req = Tools.decode("ActivityPowerReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local shipList = require "ShipList"
	shipList:new(ship_list_buff , user_name)
	shipList:setUserInfo(user_info)

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end
		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
		end

		local activityConf = CONF.ACTIVITYPOWER.get(req.activity_id)
		if #activityConf.GROUP < req.index then
			return 2
		end

		if Tools.isEmpty(activity.power_data) == false then
			if Tools.isEmpty(activity.power_data.get_indexs) == false then
				for i,v in ipairs(activity.power_data.get_indexs) do
					if v == req.index then
						return 3
					end
				end
			end
		end

		local conf = CONF.POWERGROUP.get(activityConf.GROUP[req.index])

		local power = shipList:getPowerFromAll()
		if conf.POWER > power then
			return 4
		end
		
		local addItems = {}
		for i,v in ipairs(conf.ITEM) do
			addItems[v] = conf.NUM[i]
		end
		if CoreItem.addItems( addItems, item_list, user_info) == false then
			return 5
		end

		if Tools.isEmpty(activity.power_data) == true then
			activity.power_data = {}
		end
		if Tools.isEmpty(activity.power_data.get_indexs) == false then
			table.insert(activity.power_data.get_indexs, req.index)
		else
			activity.power_data.get_indexs = { req.index}
		end

		local user_sync = CoreItem.makeSync(addItems, item_list, user_info)

		user_sync.activity_list = {activity}

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ActivityPowerResp",resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end

function activity_growth_fund_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityGrowthFundResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_growth_fund_do_logic( req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("ActivityGrowthFundReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end
		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
			activity.growth_fund_data = {
				purchased = false,
			}
		end

		local activityConf = CONF.ACTIVITYFUND.get(req.activity_id)

		if req.type == 1 then
			if activity.growth_fund_data.purchased == true then
				return 2
			end
			if CoreItem.checkMoney(user_info, activityConf.PRICE) == false then
				return 3
			end
			activity.growth_fund_data.purchased = true
			CoreItem.expendMoney(user_info, activityConf.PRICE, CONF.EUseMoney.eGrowth_fund , req.activity_id)

			local user_sync = CoreItem.syncMoney(user_info)
			user_sync.activity_list = {activity}
			return 0, user_sync
		else
			
			if #activityConf.GROUP < req.index then
				return 10
			end

			if Tools.isEmpty(activity.growth_fund_data) == false then
				if Tools.isEmpty(activity.growth_fund_data.get_indexs) == false then
					for i,v in ipairs(activity.growth_fund_data.get_indexs) do
						if v == req.index then
							return 11
						end
					end
				end
			end

			local conf = CONF.FUNDGROUP.get(activityConf.GROUP[req.index])

			local mainBuilding = userInfo:getBuildingInfo(CONF.EBuilding.kMain)

			if mainBuilding.level < conf.LEVEL then
				return 12
			end
			
			local addItems = {}
			for i,v in ipairs(conf.ITEM) do
				addItems[v] = conf.NUM[i]
			end
			if CoreItem.addItems( addItems, item_list, user_info) == false then
				return 13
			end

			if Tools.isEmpty(activity.growth_fund_data.get_indexs) == false then
				table.insert(activity.growth_fund_data.get_indexs, req.index)
			else
				activity.growth_fund_data.get_indexs = { req.index}
			end

			local user_sync = CoreItem.makeSync(addItems, item_list, user_info)

			user_sync.activity_list = {activity}

			return 0, user_sync
		end	
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ActivityGrowthFundResp",resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end


function activity_invest_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityInvestResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_invest_do_logic( req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("ActivityInvestReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function randIndex( weight_list)
		local total_weight = 0
		for _,weight in ipairs(weight_list) do
			total_weight = total_weight + weight
		end

		if total_weight == 0 then
			return 0
		end

		local weight = math.random(total_weight)

		local num = 0
		for i, weight in ipairs(weight_list) do
			num = num + weight

			if weight < num then
				return i
			end
		end
		return 0
	end

	local function doLogic(req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end
		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
			activity.invest_data = {
				index = 0,
				start_time = 0,
			}
		end

		local activityConf = CONF.ACTIVITYINVEST.get(req.activity_id)

		local need = activity.invest_data.index + 1
		if #activityConf.GROUP < need then
			return 1
		end
		local conf = CONF.INVESTGROUP.get(activityConf.GROUP[need])

		if req.type == 1 then
			if activity.invest_data.start_time ~= 0 then
				return 2
			end
			
			if CoreItem.checkMoney(user_info, conf.INVEST) == false then
				return 3
			end

			CoreItem.expendMoney(user_info, conf.INVEST, CONF.EUseMoney.eInvest , req.activity_id)

			activity.invest_data.start_time = os.time()

			local user_sync = CoreItem.syncMoney(user_info)
			user_sync.activity_list = {activity}
			return 0, user_sync
		elseif req.type == 2 then
			
			if activity.invest_data.start_time == 0 then
				return 11
			end

			CoreItem.addMoney(user_info, math.floor(conf.INVEST*0.9))

			activity.invest_data.start_time = 0

			local user_sync = CoreItem.syncMoney(user_info)

			user_sync.activity_list = {activity}

			return 0, user_sync
		else
			if activity.invest_data.start_time == 0 then
				return 21
			end
			if os.time() - activity.invest_data.start_time < conf.TIME then
				return 22
			end

			local index = randIndex(conf.WEIGHT)
			local min = conf.EARNING[2*index - 1]
			local max = conf.EARNING[2*index]
			local earning = math.random(min, max)
			local ratio = 1 + earning * 0.01

			CoreItem.addMoney(user_info, math.floor(conf.INVEST*ratio))

			activity.invest_data.start_time = 0
			activity.invest_data.index = need

			local user_sync = CoreItem.syncMoney(user_info)

			user_sync.activity_list = {activity}

			return 0, user_sync, earning
		end	
	end

	local ret, user_sync, earning = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
		earning = earning,
	}

	local resp_buff = Tools.encode("ActivityInvestResp",resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end


function activity_change_ship_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityChangeShipResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.ship_list + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_change_ship_do_logic( req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local req = Tools.decode("ActivityChangeShipReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local shipList = require "ShipList"
	shipList:new(ship_list_buff , user_name)
	shipList:setUserInfo(user_info)

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end
		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
			activity.change_ship_data = {
				getted_reward = false,
			}
		end

		if activity.change_ship_data.getted_reward == true then
			return 4
		end

		local activityConf = CONF.ACTIVITYCHANGESHIP.get(req.activity_id)
		for _,id in ipairs(activityConf.CHANGE_LIST) do
			local info = shipList:getShipInfoByID(id)
			if info == nil then
				return 2
			end
		end

		local user_sync = {}
		local ship_info = shipList:shipCreate( activityConf.GET, user_sync)

		local ret = 0
		
		if ship_info == nil then
			ret = 3
		end
		
		activity.change_ship_data.getted_reward = true

		user_sync.activity_list = {activity}
		
		return ret, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ActivityChangeShipResp",resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end

function activity_month_sign_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityMonthSignResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_month_sign_do_logic( req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("ActivityMonthSignReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req )
		local cur_time = os.time()
		if GolbalActivity.isOpen( req.activity_id, cur_time, user_info) == false then
			return 1
		end
		local activityConf = CONF.ACTIVITYMONTHSIGN.get(req.activity_id)
		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
			activity.month_sign_data = {
				resign_times = 0, 
			}
			activity.month_sign_data.get_nums = {}
			for i=1,31 do
				activity.month_sign_data.get_nums[i] = 0
			end
			activity.month_sign_data.get_rewards = {}
			for i=1,10 do
				if activityConf["SIGN"..i] ~= nil then
					activity.month_sign_data.get_rewards[i] = false
				else
					break
				end
			end
		end

		if req.type == 1 then

			local date = os.date("*t")
			if req.index > date.day then
				return 1
			end
			
			if #activityConf.GROUP < req.index then
				return 2
			end
			if req.index < date.day then
				local vipConf = CONF.VIP.get(user_info.vip_level)
				if activity.month_sign_data.resign_times >= vipConf.RESIGN then
					return 3
				end
			end
			local conf = CONF.MONTHSIGNGROUP.get(activityConf.GROUP[req.index])
		

			if activity.month_sign_data.get_nums[req.index] > 1 then
				return 4
			elseif activity.month_sign_data.get_nums[req.index] == 1 then
				if user_info.vip_level < conf.VIP then
					return 5
				end
			end
		

			local addItems = {}

			addItems[conf.ITEM] = conf.NUM

			if CoreItem.addItems( addItems, item_list, user_info) == false then
				return 6
			end

			activity.month_sign_data.get_nums[req.index] = activity.month_sign_data.get_nums[req.index] + 1
				
			if req.index < date.day then
				activity.month_sign_data.resign_times = activity.month_sign_data.resign_times + 1
			end
			local user_sync = CoreItem.makeSync(addItems, item_list, user_info)
			user_sync.activity_list = {activity}
			return 0, user_sync
		else
			if activity.month_sign_data.get_rewards[req.index] == true then
				return 11
			end

			local count = 0
			for i,v in ipairs(activity.month_sign_data.get_nums) do
				if v > 0 then
					count = count + 1
				end
			end

			if count < activityConf["SIGN"..req.index] then
				return 12
			end

			local addItems = {}
			for i,v in ipairs(activityConf["ITEM"..req.index]) do
				addItems[v] = activityConf["NUM"..req.index][i]
			end

			if CoreItem.addItems( addItems, item_list, user_info) == false then
				return 13
			end

			activity.month_sign_data.get_rewards[req.index] = true

			local user_sync = CoreItem.makeSync(addItems, item_list, user_info)
			user_sync.activity_list = {activity}
			return 0, user_sync
		end
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("ActivityMonthSignResp",resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function activity_vip_pack_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityVIPPackResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_vip_pack_do_logic( req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("ActivityVIPPackReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req)
		if req.level > user_info.vip_level then --VIP等级不够
			return 1 
		end
		local vipConf = CONF.VIP.get(req.level)
		if not vipConf then
			return 1
		end

		local itemlist 
		local itemnumlist
		if req.type == 1 then
			if Tools.isEmpty(user_info.vip_award_list) then
				user_info.vip_award_list = {}
			else
				for i=1 ,#user_info.vip_award_list do
					if (user_info.vip_award_list[i] == req.level) then
						return 2
					end
				end
			end
			itemlist = vipConf.AWARD 
			itemnumlist = vipConf.AWARD_NUM
			table.insert(user_info.vip_award_list,req.level)
		else
			if Tools.isEmpty(user_info.vip_pack_list) then
				user_info.vip_pack_list = {}
			else
				for i=1 ,#user_info.vip_pack_list do
					if (user_info.vip_pack_list[i] == req.level) then
						return 2
					end
				end
			end

			if CoreItem.checkMoney(user_info, vipConf.PRICE) == false then
				return 3
			end
			CoreItem.expendMoney(user_info, vipConf.PRICE, CONF.EUseMoney.eVip_pack)
			itemlist = vipConf.PACKS 
			itemnumlist = vipConf.PACKS_NUM
			table.insert(user_info.vip_pack_list,req.level)
		end

		local items = {}
		for i,v in ipairs(itemlist) do
			items[v] = itemnumlist[i]
		end
		if CoreItem.addItems(items, item_list, user_info) == false then
			return 4
		end
		local user_sync = CoreItem.makeSync(items, item_list, user_info)
		user_sync.user_info.vip_award_list = user_info.vip_award_list
		user_sync.user_info.vip_pack_list = user_info.vip_pack_list
		user_sync.user_info.money = user_info.money
		
		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("ActivityVIPPackResp",resp)
	Tools._print("activity_vip_pack_do_logic end")
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function activity_every_day_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityEveryDayResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end
function activity_every_day_do_logic( req_buff, user_name, user_info_buff, item_list_buff)
	local req = Tools.decode("ActivityEveryDayReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()
	Tools._print("activity_every_day_do_logic")
	local function doLogic(req)
		local cur_time = os.time()
		local conf = CONF.RECHARGE_GIFT_BAG.get(req.id)
		if conf == nil then
			return 1
		end

		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity or not activity.every_day_get_day then
			return 1
		end

		Tools.print_t(activity)
		
		if activity.every_day_get_day.add_money < conf.COST then
			return 4
		end

		local playertime = activity.every_day_get_day.start_time

		if conf.DAY > 1 then
			if activity.every_day_get_day.get_day >= conf.DAY then
				return 2 --不到天数
			end
			local date = os.date("*t", cur_time)			
			local date2 = os.date("*t", playertime)
			local day = date.yday - date2.yday
			if day < 0 then
				day = day + 365 --应该算闰年的
			end
			day = day + 1
			if day < conf.DAY then
				return 3
			end
		else
			if activity.every_day_get_day.get_day > 0 then
				return 1
			end
		end

		activity.every_day_get_day.get_day = conf.DAY

		local items = {}
		for i,v in ipairs(conf.ITEM) do
			items[v] = conf.NUM[i]
		end
		if CoreItem.addItems(items, item_list, user_info) == false then
			return 4
		end

		local user_sync = CoreItem.makeSync(items, item_list, user_info)
		user_sync.activity_list = {activity}
		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("ActivityEveryDayResp",resp)
	Tools._print("activity_every_day_do_logic end")
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end
function activity_turntable_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityTurntableResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.ship_list + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end
function activity_turntable_do_logic( req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
	Tools._print("activity_turntable_do_logic 111")
	local req = Tools.decode("ActivityTurntableReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local shipList = require "ShipList"
	local ship_list = shipList:getShipList()
	shipList:setUserInfo(user_info)

	local function randIndex( weight_list)
		local total_weight = 0
		--if true then
		--	return 1
		--end
		for _,weight in ipairs(weight_list) do
			total_weight = total_weight + weight
		end

		if total_weight == 0 then
			return 0
		end

		local weight = math.random(total_weight)
		print("weight",weight,total_weight)

		local num = 0
		for i, weight2 in ipairs(weight_list) do
			num = num + weight2

			if weight <= num then
				print("weight for",weight2,total_weight)
				return i
			end
		end
		return 0
	end
	local function doLogic(req)
		local cur_time = os.time()
		if GolbalActivity.isOpen(req.activity_id, cur_time) == false then
			return 2
		end

		local conf 
		if req.id then
			conf = CONF.ACTIVITY_TURNTABLE.get(req.id)
		else
			conf = CONF.ACTIVITY_TURNTABLE.get(1)
		end
		if conf == nil then
			return 1
		end

		local activity = CoreUser.getActivity(req.activity_id, user_info)
		if not activity then
			activity = CoreUser.addActivity(req.activity_id, user_info)
			activity.turntable_data = 
			{
				add_money = 0,
				turntable_num = CONF.PARAM.get("turntable_add_num").PARAM[1],
			}
		end

		if activity.turntable_data.turntable_num < 1 then
			return 3
		end

		if CoreItem.checkMoney(user_info, conf.SINGLE) == false then
			return 4
		end

		local index = randIndex(conf.WEIGHT)
		print("activity_turntable_do_logic",index)
		if index == 0 then
			return 5
		end

		local user_sync = {
			item_list = {},
			user_info = {},
		}

		local addItems = {}
		addItems[conf.ITEM[index]] = conf.NUM[index]

		local removeItems = {}

		local get_item_list = {}

		for i,v in pairs(addItems) do
			local itemConf = CONF.ITEM.get(i)
			if itemConf.TYPE == CONF.EItemType.kShip then
				local shipConf = CONF.AIRSHIP.get(itemConf.KEY)
				if shipList:getShipInfoByID(shipConf.ID) ~= nil then
					if Tools.isEmpty(shipConf.BLUEPRINT) == false and Tools.isEmpty(shipConf.RETURN_BLUEPRINT_NUM) == false then
						for i,id in ipairs(shipConf.BLUEPRINT) do
							if shipConf.RETURN_BLUEPRINT_NUM[i] ~= nil then
								addItems[id] = shipConf.RETURN_BLUEPRINT_NUM[i]
							end
						end				
					end					
				else
					local ship_info = shipList:shipCreate( shipConf.ID, user_sync)
					if ship_info == nil then
						return 9
					end
				end
				table.insert(removeItems,i)
			end
		end

		if Tools.isEmpty(removeItems) == false then
			for _,v in ipairs(removeItems) do
				addItems[v] = nil
			end
		end

		if Tools.isEmpty(addItems) == false then
			for i,v in pairs(addItems) do
				local items = {
					key = i,
					value = v,
				}
				table.insert(get_item_list,items)
			end

			if CoreItem.addItems( addItems, item_list, user_info) == false then
				return 5
			end
		end

		CoreItem.expendMoney(user_info, conf.SINGLE, CONF.EUseMoney.eTurntable, req.activity_id)

		activity.turntable_data.turntable_num = activity.turntable_data.turntable_num - 1

		user_sync = CoreItem.makeSync(addItems, item_list, user_info , user_sync)
		CoreItem.syncMoney(user_info,user_sync)
		user_sync.activity_list = {activity}

		return 0 ,user_sync ,get_item_list ,index
	end
	local ret, user_sync, get_item_list, index = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
		index = index,
		get_item_list = get_item_list,
	}
	local resp_buff = Tools.encode("ActivityTurntableResp",resp)
	Tools._print("activity_every_day_do_logic end")
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()

	local ship_list = shipList:getShipList()
	Tools._print("ship_list count ",#ship_list,user_info.user_name)

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end
function activity_advanced_money_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityAdvancedMoneyResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end
function activity_advanced_money_do_logic( req_buff, user_name, user_info_buff, item_list_buff)
	local req = Tools.decode("ActivityAdvancedMoneyReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req)

		return -1
	end

	local ret, user_sync  = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("ActivityAdvancedMoneyResp",resp)
	Tools._print("activity_every_day_do_logic end")
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff

end

function activity_exchange_item_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("ActivityExchangeItemResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function activity_exchange_item_do_logic( req_buff, user_name, user_info_buff, item_list_buff)
	local req = Tools.decode("ActivityExchangeItemReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local function doLogic(req)
		local cur_time = os.time()
		if GolbalActivity.isOpen(20001, cur_time) == false then
			return 2
		end
		local conf = CONF.CHANGEITEM.get(req.id)
		if conf == nil then
			return 1
		end

		local activity = CoreUser.getActivity(20001, user_info)
		if not activity then
			activity = CoreUser.addActivity(20001, user_info)
			activity.change_item_data = {day_time = cur_time,item_list={}}
		end

		local info 
		if Tools.isEmpty(activity.change_item_data.item_list) == false then
			for _,v in ipairs(activity.change_item_data.item_list) do
				if v.key == req.id then
					info = v
				end
			end
		end

		if not info then
			info = {key = req.id ,value = 0}
			table.insert(activity.change_item_data.item_list,info)
		end

		if info.value >= conf.LIMIT then
			return 3
		end

		local removeItems = {}
		for i,v in ipairs(conf.COST_ITEM) do
			removeItems[v] = conf.COST_NUM[i]
		end

		if CoreItem.checkItems(removeItems, item_list, user_info) == false then
			return 4
		end

		if CoreItem.expendItems( removeItems, item_list, user_info) == false then
			return 6
		end
		
		local addItems = {}
		for i,v in ipairs(conf.GET_ITEM) do
			addItems[v] = conf.GET_NUM[i]
		end
		if CoreItem.addItems( addItems, item_list, user_info) == false then
			return 5
		end

		info.value = info.value + 1


		local user_sync = CoreItem.makeSync(addItems, item_list, user_info)

		CoreItem.makeSync(removeItems, item_list, user_info, user_sync)
		user_sync.activity_list = {activity}

		return 0, user_sync
	end

	local ret, user_sync  = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("ActivityExchangeItemResp",resp)
	Tools._print("activity_every_day_do_logic end")
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end