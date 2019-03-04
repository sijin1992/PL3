local ChatLoger = require "ChatLoger"
local Bit = require "Bit"

function slave_sync_data_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("SlaveSyncDataResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function slave_sync_data_do_logic(req_buff, user_name, user_info_buff)
	local req = Tools.decode("SlaveSyncDataReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()
	local user_sync = {}
	local slave_data_list = {}
	local info_list = {}
	
	local function doLogic()
		
		if Tools.isEmpty(req.user_name_list) then
			local data = SlaveCache.get(user_name)

			user_sync.slave_data = data

		else
			for i,v in ipairs(req.user_name_list) do
				local data = SlaveCache.get(v)
				local info = SlaveCache.createBriefInfo(v)
				if info then
					table.insert(slave_data_list, data)
					table.insert(info_list, info)
				end
			end
		end


		return "OK"
	end

	local ret = doLogic()
	local resp = {
		result = ret,
		user_sync = user_sync,
		slave_data_list = slave_data_list,
		info_list = info_list,
	}

	local resp_buff = Tools.encode("SlaveSyncDataResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end



	
function slave_get_res_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 2, Tools.encode("SlaveGetResResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("SlaveGetResReq", req_buff)

		if req.slave_name == "" or req.slave_name == nil then
			LOG_ERROR(string.format("slave_get_res_feature slave_name == ", req.slave_name))
		end
		return datablock.user_info + datablock.save, req.slave_name
	else
		error("something error");
	end
end

function slave_get_res_do_logic(req_buff, user_name, user_info_buff, user_info_buff2)
	local req = Tools.decode("SlaveGetResReq", req_buff)

	local userInfo2 = require "UserInfo"
	userInfo2:new(user_info_buff2)
	local user_info2 = userInfo2:getUserInfo()

	local user_info = Tools.decode("UserInfo", user_info_buff)

	local res = {0,0,0,0,}
	local exp = 0
	local function doLogic()
		local data = SlaveCache.get(user_name)

		if SlaveCache.isMySlave(user_name, req.slave_name ) == false then
			return "NOT_MY_SLAVE"
		end

		if req.type > 1 then
			if os.time() < data.get_res_start_time +  CONF.PARAM.get("slave_get_res_cd").PARAM then
				return "CD_TIME"
			end
		end
		local isJustCal = req.type == 1

		exp = SlaveCache.masterGetRes(isJustCal, req.slave_name, 0)

		for i=2,4 do
			local cal_new_value = userInfo2:calGetHomeResource(i)
			res[i] = SlaveCache.masterGetRes(isJustCal, req.slave_name, i, cal_new_value)
		end

		data = SlaveCache.get(user_name)

		if not isJustCal then
			if exp > 0 then
				CoreUser.addExp(exp, user_info)
			end
			for i,v in ipairs(res) do
				if v > 0 then
					CoreUser.addRes(i, v, user_info)
				end
			end
		end
		return "OK"
	end

	local ret = doLogic()
	local resp = {
		result = ret,
		user_sync = user_sync,
		res = res,
		exp = exp,
	}

	local resp_buff = Tools.encode("SlaveGetResResp", resp)
	user_info_buff = Tools.encode("UserInfo", user_info)
	user_info_buff2 = userInfo2:getUserBuff()
	return resp_buff, user_info_buff, user_info_buff2
end


	
function slave_free_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("SlaveFreeResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function slave_free_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("SlaveFreeReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()

	local function doLogic()

		if SlaveCache.isMySlave(user_name, req.slave_name) == false then
			return "NOT_MY_SLAVE"
		end

		local ret = SlaveCache.freeSlave(req.slave_name)
		if ret == false then
			return "FREE_SLAVE_ERROR"
		else
			SlaveCache.recordNote(req.slave_name, "BE_FREE", {
				[CONF.ESlaveNoteKey.kMaster] = user_info.nickname,
			})
		end

		
		return "OK"
	end

	local ret = doLogic()

	local resp = {
		result = ret,
		user_sync = {
			slave_data = SlaveCache.get(user_name)
		}
	}

	local resp_buff = Tools.encode("SlaveFreeResp", resp)
	user_info_buff = userInfo:getUserBuff()

	local multicast =
	{
		recv_list = {req.slave_name},
		cmd = 0x172F,
		msg_buff = "0",
	}
	return resp_buff, user_info_buff, 0x2100, Tools.encode("Multicast", multicast)
end

function slave_show_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("SlaveShowResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error")
	end
end

function slave_show_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("SlaveShowReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	local get_item_list = {}
	local function doLogic()

		if req.type == 1 then

			if SlaveCache.isMySlave(user_name, req.slave_name) == false then
				return "NOT_MY_SLAVE"
			end

			local money = CONF.PARAM.get("slave_show_money").PARAM
			if CoreItem.checkMoney(user_info, money) == false then
				return "NO_MONEY"
			end

			local slave_data = SlaveCache.get(req.slave_name)
			if slave_data.state == 2 then
				return "STATE_ERROR"
			end

			slave_data.state = 2
			slave_data.show_watch_num = 0
			slave_data.show_start_time = os.time()
			slave_data.watch_list = nil
			SlaveCache.set(slave_data)

			CoreItem.expendMoney(user_info, money , CONF.EUseMoney.eSlave)

			local slave_other_user_info = UserInfoCache.get(slave_data.user_name)

			SlaveCache.recordNote(user_name, "SHOW", {
				[CONF.ESlaveNoteKey.kSlave] = slave_other_user_info.nickname,
			})

			SlaveCache.recordNote(req.slave_name, "BE_SHOW", {
				[CONF.ESlaveNoteKey.kMaster] = user_info.nickname,
			})

			local msg = string.format(Lang.slave_show_msg, user_info.nickname, slave_other_user_info.nickname)

	
			ChatLoger.pushLog("0_3",  msg, slave_other_user_info.nickname, slave_other_user_info.user_name, slave_other_user_info.group_nickname)

			--创建 chat message
			local chat_msg = {
				msg = {msg},
				channel = 0,
				sender = {
					uid = slave_other_user_info.user_name,
					nickname = slave_other_user_info.nickname,
					vip = 0,
					level = slave_other_user_info.level,
					group_nickname = slave_other_user_info.group_nickname,
				},
				recver = nil,
				recvs = nil,
				type = 0,
				minor = {3},
			}

			return "OK",  CoreItem.syncMoney(user_info), chat_msg

		elseif req.type == 2 then

			local slave_data = SlaveCache.get(req.slave_name)
			local master_name = slave_data.master
			if master_name == nil or master_name == "" then
				return "NO_MASTER"
			end
			if slave_data.state ~= 2 then
				return "STATE_ERROR"
			end
			if Tools.isEmpty(slave_data.watch_list) == false then
				for i,v in ipairs(slave_data.watch_list) do
					if v == user_name then
						return "WATCHED"
					end
				end
			end

			if slave_data.show_watch_num >= CONF.PARAM.get("slave_watch_num").PARAM then
				return "WATCH_NUM_MAX"
			end
			if Tools.isEmpty(slave_data.watch_list) == true then
				slave_data.watch_list = {user_name,}
			else
				table.insert(slave_data.watch_list, user_name)
			end
			slave_data.show_watch_num = slave_data.show_watch_num + 1
			SlaveCache.set(slave_data)

			local slave_other_user_info = UserInfoCache.get(slave_data.user_name)
			SlaveCache.recordNote(slave_data.master, "WATCH", {
		
				[CONF.ESlaveNoteKey.kWatcher] = user_info.nickname,
			})

			SlaveCache.recordNote(slave_data.user_name, "WATCH", {
	
				[CONF.ESlaveNoteKey.kWatcher] = user_info.nickname,
			})
			
			local id, num = SlaveCache.getReward(3)
			local items = {[id] = num}
			table.insert(get_item_list, {key = id, value = num})
			CoreItem.addItems(items, item_list, user_info)
	
			local user_sync = CoreItem.makeSync(items, item_list, user_info)
		
			return "OK", user_sync
		end
		return "TYPE_ERROR"
	end

	local ret, user_sync, chat_msg = doLogic()
	
	local resp = {
		result = ret,
		user_sync = user_sync,
		get_item_list = get_item_list,
	}

	local resp_buff = Tools.encode("SlaveShowResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()

	local multicast =
	{
		recv_list = {req.slave_name},
		cmd = 0x172F,
		msg_buff = "0",
	}

	if chat_msg then
		local chat_cmd = 0x1521
		return resp_buff, user_info_buff, item_list_buff, 0x2100, Tools.encode("Multicast", multicast), chat_cmd, Tools.encode("ChatMsg_t", chat_msg)
	end
	return resp_buff, user_info_buff, item_list_buff, 0x2100, Tools.encode("Multicast", multicast)
end

function slave_work_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("SlaveWorkResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function slave_work_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("SlaveWorkReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	local get_item_list = {}
	local function doLogic()

		if SlaveCache.isMySlave(user_name, req.slave_name) == false then
			return "NOT_MY_SLAVE"
		end

		local cur_time = os.time()

		local slave_data = SlaveCache.get(req.slave_name)

		if slave_data.work_cd_start_time > 0 and cur_time < slave_data.work_cd_start_time + CONF.PARAM.get("slave_work_cd").PARAM then
			return "CD_TIME"
		end

		local id, num = SlaveCache.getReward(2)
		local items = {[id] = num}
		table.insert(get_item_list, {key = id, value = num})
		CoreItem.addItems(items, item_list, user_info)

		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		slave_data.work_cd_start_time = os.time()
		SlaveCache.set(slave_data)

		local slave_other_user_info = UserInfoCache.get(req.slave_name)

		local note_info = SlaveCache.recordNote(user_name, (num > 0 and "WORK_ADD") or "WORK_SUB", {
			[CONF.ESlaveNoteKey.kSlave] = slave_other_user_info.nickname,
			[CONF.ESlaveNoteKey.kItem] = tostring(id),
			[CONF.ESlaveNoteKey.kNum] = tostring(num),
		})
		user_sync.slave_data = SlaveCache.get(user_name)
		return "OK", user_sync, note_info
	end

	local ret, user_sync, note_info = doLogic()

	local resp = {
		result = ret,
		user_sync = user_sync,
		get_item_list = get_item_list,
		note_info = note_info,
	}

	local resp_buff = Tools.encode("SlaveWorkResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, item_list_buff
end

function slave_fawn_on_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("SlaveFawnOnResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function slave_fawn_on_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("SlaveFawnOnReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	local get_item_list = {}
	local function doLogic()

		local slave_data = SlaveCache.get(user_name)
		local master_name = slave_data.master
		if master_name == nil or master_name == "" then
			return "NO_MASTER"
		end

		local cur_time = os.time()

		if slave_data.fawn_on_cd_start_time > 0 and cur_time < slave_data.fawn_on_cd_start_time + CONF.PARAM.get("slave_fawn_on_cd").PARAM then
			return "CD_TIME"
		end

		local id, num = SlaveCache.getReward(2)

		local items = {[id] = num}
		table.insert(get_item_list, {key = id, value = num})
		CoreItem.addItems(items, item_list, user_info)
	
		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		slave_data.fawn_on_cd_start_time = cur_time
		SlaveCache.set(slave_data)

		local master_other_user_info = UserInfoCache.get(master_name)

		local note_info = SlaveCache.recordNote(user_name, (num > 0 and "FAWN_ON_ADD") or "FAWN_ON_SUB", {
			[CONF.ESlaveNoteKey.kMaster] = master_other_user_info.nickname,
			[CONF.ESlaveNoteKey.kItem] = tostring(id),
			[CONF.ESlaveNoteKey.kNum] = tostring(num),
		})
		user_sync.slave_data = SlaveCache.get(user_name)
		return "OK", user_sync, note_info
	end

	local ret, user_sync, note_info = doLogic()

	local resp = {
		result = ret,
		user_sync = user_sync,
		get_item_list = get_item_list,
		note_info = note_info,
	}

	local resp_buff = Tools.encode("SlaveFawnOnResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, item_list_buff
end

function slave_help_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("SlaveHelpResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function slave_help_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("SlaveHelpReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local function doLogic()

		local slave_data = SlaveCache.get(user_name)
		local master_name = slave_data.master
		if master_name == nil or master_name == "" then
			return "NO_MASTER"
		end

		local cur_time = os.time()

		if slave_data.help_cd_start_time > 0 and cur_time < slave_data.help_cd_start_time + CONF.PARAM.get("slave_help_cd").PARAM then
			return "CD_TIME"
		end

		if Tools.isEmpty(user_info.friends_data) == true or Tools.isEmpty(user_info.friends_data.friends_list) == true then
			return "SEND_LIST_EMPTY"
		end
		
		local recv_list = {}
		for i,friend_name in ipairs(user_info.friends_data.friends_list) do
			local sended = SlaveCache.sendHelp(friend_name, user_name)
			if sended == true then
				table.insert(recv_list, friend_name)
			end
		end

		local multicast
		if Tools.isEmpty(recv_list) == false then
			multicast = {
				recv_list = recv_list,
				cmd = 0x172F,
			}
		end

		slave_data.help_cd_start_time = cur_time
		SlaveCache.set(slave_data)

		local user_sync = {
			slave_data = SlaveCache.get(user_name),
		}

		return "OK", user_sync, multicast
	end

	local ret, user_sync = doLogic()

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("SlaveHelpResp", resp)
	user_info_buff = userInfo:getUserBuff()

	if multicast then
		return resp_buff, user_info_buff, 0x2100, Tools.encode("Multicast", multicast)
	else
		return resp_buff, user_info_buff
	end
end

function slave_add_times_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("SlaveAddTimesResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function slave_add_times_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("SlaveAddTimesReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local function doLogic()
		local user_sync

		local my_data = SlaveCache.get(user_name)
		if req.type == 1 then
			local need_money = CONF.PARAM.get("enslave_coupon").PARAM * (1 + my_data.buy_get_slaves_times)
			if CoreItem.checkMoney(user_info, need_money) == false then
				return "NO_MONEY"
			end
			my_data.buy_get_slaves_times = my_data.buy_get_slaves_times + 1
			my_data.get_slaves_times = my_data.get_slaves_times + 1
			CoreItem.expendMoney(user_info, need_money, CONF.EUseMoney.eSlave)
		else
			local need_money = CONF.PARAM.get("save_coupon").PARAM * (1 + my_data.buy_get_save_times)
			if CoreItem.checkMoney(user_info, need_money) == false then
				return "NO_MONEY"
			end
			my_data.buy_get_save_times = my_data.buy_get_save_times + 1
			my_data.get_save_times = my_data.get_save_times + 1
			CoreItem.expendMoney(user_info, need_money, CONF.EUseMoney.eSlave)
		end
		SlaveCache.set(my_data)
		user_sync = CoreItem.syncMoney(user_info)
		user_sync.slave_data = my_data

		return "OK", user_sync
	end

	local ret, user_sync = doLogic()

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("SlaveAddTimesResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end

function slave_search_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("SlaveSearchResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function slave_search_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("SlaveSearchReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local function doLogic()

		local slave_data = SlaveCache.get(user_name)

		local master_name = slave_data.master

		local need_num = 6

		local user_name_list

		if req.type == 1 then
	
			if master_name ~= nil and master_name ~= "" then
				return "HAS_MASTER"
			end

			user_name_list = UserInfoCache.getRandUserByLevelInterval(user_name, 11)
			if Tools.isEmpty(user_name_list) == true then
				return "EMPTY"
			end

			for index=#user_name_list,1, -1 do

				if user_name == user_name_list[index] then

					table.remove(user_name_list, index)

				elseif Tools.isEmpty(slave_data.slave_list) == false then
					for i,v in ipairs(slave_data.slave_list) do
						if user_name_list[index]== v then
							table.remove(user_name_list, index)
						end
					end
				end
			end

		elseif req.type == 2 then

			if master_name ~= nil and master_name ~= "" then
				return "HAS_MASTER"
			end

			if Tools.isEmpty(slave_data.enemy_list) == true then
				return "EMPTY"
			end

			user_name_list = {}
			local section = math.floor(#slave_data.enemy_list / need_num)
			if  section < 2 then
				for i=1,need_num do
					table.insert(user_name_list, slave_data.enemy_list[i])
				end
			else
				for i=1,need_num do
					local s = 1 + section*(i-1)
					local e = section*i
					local index = math.random(s, e)
					table.insert(user_name_list, slave_data.enemy_list[index])
				end
			end

		elseif req.type == 3 then
			if Tools.isEmpty(slave_data.help_list) == true then
				return "EMPTY"
			end
			for i=#slave_data.help_list,1, -1 do
				local data = SlaveCache.get(slave_data.help_list[i])
				if data.master == "" or data.master == nil then
					table.remove(slave_data.help_list, i)
				end
			end

			user_name_list = {}
			local section = math.floor(#slave_data.help_list / need_num)
			if  section < 2 then
				for i=1,need_num do
					table.insert(user_name_list, slave_data.help_list[i])
				end
			else
				for i=1,need_num do
					local s = 1 + section*(i-1)
					local e = section*i
					local index = math.random(s, e)
					table.insert(user_name_list, slave_data.help_list[index])
				end
			end
		else
			return "ERROR_TYPE"
		end

		if Tools.isEmpty(user_name_list) == true then
			return "EMPTY"
		end

		local info_list = {}
		for i=1,need_num do
			if user_name_list[i] ~= nil then
				local data = SlaveCache.get(user_name_list[i])
				table.insert(info_list, SlaveCache.createBriefInfo( user_name_list[i] ))
			end
		end

		return "OK", info_list
	end

	local ret, info_list = doLogic()

	local resp = {
		result = ret,
		info_list = info_list,
	}

	local resp_buff = Tools.encode("SlaveSearchResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end

function slave_attack_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		local req = Tools.decode("SlaveAttackReq", req_buff)
		local slave_data = SlaveCache.get(req.user_name)
		local num = 2
		if req.type == 2 then
			if slave_data.master == nil or slave_data.master == "" then
				num = 1
			end
		end
		return num, Tools.encode("SlaveAttackResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.ship_list + datablock.item_package + datablock.save, user_name
	elseif step == 2 then

		local req = Tools.decode("SlaveAttackReq", req_buff)
		local target_name
		local slave_data = SlaveCache.get(req.user_name)
		if req.type == 2 then
			target_name = slave_data.master
			if target_name == nil then
				LOG_ERROR("slave_attack_feature target no master")
			end
		else
			if slave_data.master and slave_data.master ~= "" then
				target_name = slave_data.master
			else
				target_name = req.user_name
			end
		end
		if target_name == "" or target_name == nil then
			LOG_ERROR("slave_attack_feature target_name == nil")
		end
		return datablock.user_info + datablock.ship_list, target_name
	else
		error("something error");
	end
end

function slave_attack_do_logic( req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff, user_info_buff2, ship_list_buff2)

	local req = Tools.decode("SlaveAttackReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	local user_info
	local ship_list 

	local user_info2 = Tools.decode("UserInfo", user_info_buff2)

	local function resetBuff( index )
		if index == 1 then
			userInfo:new(user_info_buff)
			shipList:new(ship_list_buff , user_name)
		else
			userInfo:new(user_info_buff2)
			shipList:new(ship_list_buff2)
		end
		user_info = userInfo:getUserInfo()
		ship_list = shipList:getShipList()
		shipList:setUserInfo(user_info)
	end

	resetBuff(1)

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local item_list = itemList:getItemList()

	local attack_list = {}
	local hurter_list = {}

	local event_list
	local isWin
	local isCatch = false
	local out_recv_list = {}
	local get_item_list = {}
	local user_sync = {}
	local function doLogic()
		if user_info_buff2 == nil then
			return "NO_EMEMY"
		end

		if user_info2.user_name == user_name then
			return "ATTACK_SELF"
		end

		if req.type > 2 or req.type < 1 then
			return "ERROR_TYPE"
		end

		local my_data = SlaveCache.get(user_name)

		local cur_time = os.time()

		if req.type == 1 then
			if my_data.master ~= nil and my_data.master ~= "" then
				return "HAS_MASTER"
			end
			if req.user_name == user_name then
				return "ATTACK_SELF"
			end
			if my_data.get_slaves_times <= 0 then
				return "NO_TIMES"
			end
			if Tools.isEmpty(my_data.slave_list) == false then
				if #my_data.slave_list > 5 then
					return "MAX_SLAVE"
				end
				for i,v in ipairs(my_data.slave_list) do
					if v == req.user_name then
						return "HAS_SLAVE"
					end
				end
			end

			local slave_data = SlaveCache.get(req.user_name)
			if slave_data.state == 2 then
				return "SHOWING"
			end
		else
			local slave_data = SlaveCache.get(req.user_name)
			if slave_data.state == 2 then
				return "SHOWING"
			end
			if slave_data.master == nil or slave_data.master == "" then
				return "NO_MASTER"
			end
			if req.user_name == user_name then
				if cur_time < my_data.revolt_cd_start_time + CONF.PARAM.get("slave_revolt_cd").PARAM then
					return "CD_TIME"
				end
			else
				if my_data.get_save_times <= 0 then
					return "NO_TIMES"
				end
			end
		end

		local lineup_num = 0
		for i,v in ipairs(req.lineup) do
			if v > 0 then
				lineup_num = lineup_num + 1
			end
		end
		if lineup_num < 1 then
			return "NO_SHIPS"
		end

		attack_list = shipList:getShipByLineup(req.lineup)

		for i,v in ipairs(attack_list) do
			if Tools.checkShipDurable(v) == false then
				return "NO_DURABLE"
			end
			
			if Bit:has(v.status, CONF.EShipState.kFix) == true then
				return "FIXING"
			end

			if Bit:has(v.status, CONF.EShipState.kOuting) == true then
				return "OUTING"
			end
		end

		local group_main = userInfo:getGroupMainFromGroupCache()
		for i=1,#attack_list do
          			
			attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true)
			attack_list[i].body_position = {attack_list[i].position}
		end

		resetBuff(2)


		local group_main = userInfo:getGroupMainFromGroupCache()
		hurter_list = shipList:getShipByLineup()
		for i=1,#hurter_list do
			hurter_list[i] = Tools.calShip(hurter_list[i], user_info, group_main, true)
			hurter_list[i].body_position = {hurter_list[i].position}
		end

		resetBuff(1)


		isWin, event_list = Tools.autoFight(attack_list, nil, hurter_list, nil)

		--CoreUser.battleCount(user_info.user_name, req.user_name, isWin)
		
		if req.type == 1 then --抓奴隶
	
			if isWin then
				local slave_data = SlaveCache.get(req.user_name)
				local p = 10 / (math.abs(user_info.level - user_info2.level) + 10) * 100

				if p > math.random(1,100) then
					isCatch = true
				end
	
				if user_info2.user_name ~= req.user_name then --抢夺奴隶
					if slave_data.master ~= user_info2.user_name then

						return "NOT_SLAVE_MASTER"
					end
					
				else--正常抓为奴隶
					if slave_data.master ~= nil and slave_data.master ~= "" then
						return "HAS_MASTER"
					end
				end

				if isCatch == true then
		
					local has = SlaveCache.catchSlave(user_name, req.user_name, out_recv_list)
					if has ~= true then
						return "CATCH_ERROR"
					end
					local slave_other_user_info = UserInfoCache.get(req.user_name)
	
					SlaveCache.recordNote(user_name, "ROB_SUCCESS", {
						[CONF.ESlaveNoteKey.kCatchSlave] = slave_other_user_info.nickname,
					})

					SlaveCache.removeEnemy(user_name, req.user_name)
					if user_info2.user_name ~= req.user_name then

						SlaveCache.addEnemy(user_info2.user_name, user_name)
						SlaveCache.addEnemy(user_info2.user_name, req.user_name)
					
						SlaveCache.recordNote(user_info2.user_name, "BE_ROB_SUCCESS", {
							[CONF.ESlaveNoteKey.kSlave] = slave_other_user_info.nickname,
							[CONF.ESlaveNoteKey.kAttacker] = user_info.nickname,
						})
					end
	
					SlaveCache.recordNote(req.user_name, "BE_CATCH", {
						[CONF.ESlaveNoteKey.kAttacker] = user_info.nickname,
					})
				
					local achievement_data = userInfo:getAchievementData()
					if achievement_data.slave_times == nil then
						achievement_data.slave_times = 0
					end
					achievement_data.slave_times = achievement_data.slave_times + 1
					user_sync.user_info = user_sync.user_info or {}
					user_sync.user_info.achievement_data = achievement_data
				end
			end

			my_data = SlaveCache.get(user_name)
			my_data.get_slaves_times = my_data.get_slaves_times - 1
			SlaveCache.set(my_data)
			
		else --救奴隶

			if isWin then
				SlaveCache.freeSlave(req.user_name, out_recv_list)
			end

			if req.user_name == user_name then --自救

				my_data.revolt_cd_start_time = cur_time

				if isWin then
					SlaveCache.recordNote(user_info2.user_name, "SAVE_SELF_SUCCESS", {
						[CONF.ESlaveNoteKey.kSlave] = user_info.nickname,
					})
				end
			else --救别人
				my_data.get_save_times = my_data.get_save_times - 1
				SlaveCache.set(my_data)
				if isWin then

					local item_id, num = SlaveCache.getReward(4)
					table.insert(get_item_list, {key = item_id, value = num})

					local items = {[item_id] = num}
					CoreItem.addItems(items, item_list, user_info)

					user_sync = CoreItem.makeSync(items, item_list, user_info)

					local slave_other_user_info = UserInfoCache.get(req.user_name)
					local master_other_user_info = UserInfoCache.get(user_info2.user_name)
					SlaveCache.recordNote(user_name, "SAVE_SUCCESS" , {
						[CONF.ESlaveNoteKey.kSlave] = slave_other_user_info.nickname,
						[CONF.ESlaveNoteKey.kMaster] = master_other_user_info.nickname,
						[CONF.ESlaveNoteKey.kItem] = tostring(item_id),
						[CONF.ESlaveNoteKey.kNum] =  tostring(num),
					})
					SlaveCache.recordNote(user_info2.user_name, "BE_SAVE_SUCCESS", {
						[CONF.ESlaveNoteKey.kAttacker] = user_info.nickname,
						[CONF.ESlaveNoteKey.kSlave] = slave_other_user_info.nickname,
					})
					SlaveCache.recordNote(req.user_name, "SLAVE_BE_SAVE_SUCCESS", {
						[CONF.ESlaveNoteKey.kAttacker] = user_info.nickname,
						[CONF.ESlaveNoteKey.kMaster] = master_other_user_info.nickname,
					})
				end
			end
		end

		user_sync.slave_data = SlaveCache.get(user_name)

		local tech_list = userInfo:getTechnologyList()
		local group_tech_list = group_main and group_main.tech_list or nil
		shipList:subLineupDurable(2, isWin and 1 or 0 , user_sync, nil, tech_list, group_tech_list)
		-- print("user_sync:      ==============")
		-- Tools.print_t(user_sync.slave_data)


		shipList:changeLineup(user_info, req.lineup)

		return "OK"
	end

	local ret = doLogic()

	local resp = {
		result = ret,
		user_sync = user_sync,
		attack_list = attack_list,
		hurter_list = hurter_list,
		event_list = event_list,
		isWin = isWin,
		isCatch = isCatch,
		get_item_list = get_item_list,
		req = req,
	}

	local resp_buff = Tools.encode("SlaveAttackResp", resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()

	if Tools.isEmpty(out_recv_list) == false then

		local list = {}
		for k,v in pairs(out_recv_list) do
			table.insert(list, k)
		end
		local multicast = {
			recv_list = list,
			cmd = 0x172F,
			msg_buff = "0",
		}
		local multicast_buff = Tools.encode("Multicast", multicast)
		return resp_buff, user_info_buff, ship_list_buff, item_list_buff, user_info_buff2, ship_list_buff2, 0x2100, multicast_buff
	else
		return resp_buff, user_info_buff, ship_list_buff, item_list_buff, user_info_buff2, ship_list_buff2
	end
end