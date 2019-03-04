local ChatLoger = require "ChatLoger"
local timeChecker = require "TimeChecker"
local Bit = require "Bit"

function update_timestamp_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("UpdateTimeStampResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.mail_list + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end


function update_timestamp_do_logic(req_buff, user_name, user_info_buff, item_list_buff, mail_list_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	local mailList = require "MailList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	mailList:new(mail_list_buff)

	local time = os.time()
	
	local dayid = timeChecker.get_dayid_from(time)
	local user_sync = {

	}

	timeChecker.update_at_0am(userInfo, dayid, user_sync)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	local mail_list = mailList:getMailList()

	timeChecker.update_time_stamp(user_info, item_list, mail_list, user_sync)

	if Tools.isEmpty(user_info.blocked) == false then
		if Tools.isEmpty(user_sync.user_info) == false then
			user_sync.user_info.blocked = user_info.blocked
		else
			user_sync.user_info = {
				blocked = user_info.blocked,
			}
		end
	end

	if user_info.timestamp.today_online_time == nil then
		user_info.timestamp.today_online_time = 60
	else
		user_info.timestamp.today_online_time = user_info.timestamp.today_online_time + 60
	end
	if Tools.isEmpty(user_sync.user_info) == false then
		user_sync.user_info.timestamp = user_info.timestamp
	else
		user_sync.user_info = {
			timestamp = user_info.timestamp,
		}
	end

	if  Bit:has(user_info.state, 1) == true then
		if time - user_info.timestamp.regist_time > CONF.PARAM.get("green_hand_time").PARAM then
			local tech_list = userInfo:getTechnologyList()
			for i=#tech_list, 1, -1 do

				for _,tech_id in ipairs(CONF.PARAM.get("green_hand_buff").PARAM) do
					if tech_id == tech_list[i].tech_id then
						table.remove(tech_list, i)
						break
					end
				end
			end
			user_info.state = Bit:remove(user_info.state, 1)
			if Tools.isEmpty(user_sync.user_info) == false then
				user_sync.user_info.state = user_info.state
			else
				user_sync.user_info = {
					state = user_info.state,
				}
			end
		end
	end
	

	local resp = {
		result = 0,
		user_sync = user_sync,
	}

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	mail_list_buff = mailList:getMailBuff()
	local resp_buff = Tools.encode("UpdateTimeStampResp",resp)
	return resp_buff, user_info_buff, item_list_buff, mail_list_buff
end

function update_res_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("UpdateResResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end

function update_res_do_logic(req_buff, user_name, user_info_buff)

	local userInfo = require "UserInfo"

	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()


	local resp = {
		result = 0,
		user_sync = {
			user_info = {
				money = user_info.money,
				achievement_data = user_info.achievement_data,
			}
		},
		credit = user_info.money,
	}

	user_info_buff = userInfo:getUserBuff()

	local resp_buff = Tools.encode("UpdateResResp",resp)
	return resp_buff, user_info_buff
end


function chat_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		local chatreq = Tools.decode("ChatReq", req)
		if chatreq.channel == 1 then
			return 2, Tools.encode("ChatResp", resp)
		elseif chatreq.channel == 2 then
			return 2, Tools.encode("ChatResp", resp)
		else
			return 1, Tools.encode("ChatResp", resp)
		end
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	elseif step == 2 then

		local chatreq = Tools.decode("ChatReq", req)
		if chatreq.channel == 1 then
			local recv_uid = chatreq.recver.uid
			assert(recv_uid and recv_uid ~= "")
			return datablock.main_data + datablock.save, recv_uid
		else
			return datablock.group_main + datablock.save, user_name
		end
	else
		error("something error");
	end
end

function chat_do_logic(req_buff, user_name, main_data_buff, item_list_buff, main_data_buff2)

	local req = Tools.decode("ChatReq", req_buff)

	--屏蔽字检测
	local dirty = false
	
	for i=1,CONF.DIRTYWORD.len do
		if string.find(req.msg, CONF.DIRTYWORD[i].KEY) ~= nil then
			dirty = true
			break
		end
	end

	if dirty then
		local resp = {
			result = "DIRTY",
		}
		local resp_buff = Tools.encode("ChatResp", resp)
		if req.channel == 1 or req.channel == 2 then
			return resp_buff, main_data_buff, item_list_buff, main_data_buff2
		else
			return resp_buff, main_data_buff, item_list_buff
		end
	end

	local main_data = Tools.decode("UserInfo", main_data_buff)
	local item_list = Tools.decode("ItemList", item_list_buff)

	local user_sync
	--收费消息检测
	if req.channel ~= 1 and req.type == 1 and main_data then

		local need = 100
		if CoreItem.checkMoney(main_data, need) == false then
			local resp = {
				result = "NOMONEY",
			}
			local resp_buff = Tools.encode("ChatResp", resp)
			return resp_buff, main_data_buff, item_list_buff
		end
		CoreItem.expendMoney(main_data, need, CONF.EUseMoney.eChat)

		user_sync = CoreItem.syncMoney(main_data)
	end

	--添加recver
	local recver = nil
	local recvs = {}

	local cid

	local main_data2

	if req.channel == 1 then

		main_data2 = Tools.decode("UserInfo", main_data_buff2)

		if main_data2.user_name == user_name then
			local resp = {
				result = "SELF",
			}
			local resp_buff = Tools.encode("ChatResp", resp)
			return resp_buff, main_data_buff, item_list_buff, main_data_buff2
		end


		--黑名单检测
		local has, index = CoreUser.checkFriendsData(main_data.user_name, "black_list", main_data2)
		if has ==true then
			local resp = {
				result = "BLACK",
			}
			local resp_buff = Tools.encode("ChatResp", resp)
			return resp_buff, main_data_buff, item_list_buff, main_data_buff2
		end

		--私聊队列检测
		if CoreUser.checkFriendsData(main_data.user_name, "talk_list", main_data2) == false then


			CoreUser.addFriendsData(main_data.user_name, "talk_list", main_data2)

			if #main_data2.friends_data.talk_list > GolbalDefine.talk_max then
				CoreUser.removeFriendsDataByIndex(1, "talk_list", main_data2)
			end

		end

		local cache_group_main 
		if main_data2.group_data and main_data2.group_data.groupid ~= "" then
			cache_group_main = GroupCache.getGroupMain(main_data2.group_data.groupid)
		end

		recver = {
			uid = main_data2.user_name,
			nickname = main_data2.nickname,
			vip = main_data2.vip_level,
			level = main_data2.level,
			group_nickname = cache_group_main and cache_group_main.nickname or nil
		}


		if tonumber(user_name) < tonumber(main_data2.user_name) then
			cid = user_name..main_data2.user_name
		else
			cid = main_data2.user_name..user_name
		end
	elseif req.channel == 2 then

		main_data2 = Tools.decode("GroupMainData", main_data_buff2)

		if main_data2.user_list then
			for k,v in ipairs(main_data2.user_list) do
				table.insert(recvs, v.user_name)
			end
		end

		GroupCache.update(main_data2, user_name)

		cid = main_data.group_data.groupid
	elseif req.channel == 0 then
		cid = "0"
		if Tools.isEmpty(req.minor) == false then
			for i,v in ipairs(req.minor) do
				cid = cid .. "_" .. v
			end
		end
	end


	if not cid then

		local resp = {
			result = "FAIL",
		}
		local resp_buff = Tools.encode("ChatResp", resp)
		return resp_buff, main_data_buff, item_list_buff, main_data_buff2
	end


	local cache_group_main 
	if main_data.group_data and main_data.group_data.groupid ~= "" then
		cache_group_main = GroupCache.getGroupMain(main_data.group_data.groupid)
	end
	local group_nickname = cache_group_main and cache_group_main.nickname or nil

	ChatLoger.pushLog(cid, req.msg, main_data.nickname, main_data.user_name, group_nickname)

	--创建 chat message
	local chat_cmd = 0x1521
	local chat_msg = {
		msg = {req.msg},
		channel = req.channel,
		sender = {
			uid = main_data.user_name,
			nickname = main_data.nickname,
			vip = main_data.vip_level,
			level = main_data.level,
			group_nickname = group_nickname,
		},
		recver = recver,
		recvs = recvs,
		type = req.type,
		minor = req.minor,
	}
	

	local chat_msg_buff = Tools.encode("ChatMsg_t", chat_msg)

	local resp = {
		result = "OK",
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("ChatResp", resp)

	main_data_buff = Tools.encode("UserInfo", main_data)
	item_list_buff = Tools.encode("ItemList", item_list)


	if req.channel == 1 or req.channel == 2 then

		if req.channel == 1 then
			main_data_buff2 = Tools.encode("UserInfo", main_data2)
		elseif req.channel == 2 then
			main_data_buff2 = Tools.encode("GroupMainData", main_data2)
		end

		return resp_buff, main_data_buff, item_list_buff, main_data_buff2, chat_cmd, chat_msg_buff
	else
		return resp_buff, main_data_buff, item_list_buff, chat_cmd, chat_msg_buff
	end
end

function get_chat_log_feature(step, req_buff, user_name)
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("GetChatLogResp", resp)
	elseif step == 1 then
		return datablock.main_data , user_name
	else
		error("something error")
	end
end

function get_chat_log_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("GetChatLogReq", req_buff)

	local function doLogic(  )
		local chat_id = req.chat_id
		if Tools.isEmpty(req.minor) == false then
			for i,v in ipairs(req.minor) do
				chat_id = chat_id .. "_" .. v
			end
		end

		local log_list = ChatLoger.getLogList(chat_id)
		if log_list == nil then
			return 1
		end
		return 0,log_list
	end

	local ret, log_list = doLogic()

	local resp = {
		result = ret,
		log_list = log_list,
	}

	local resp_buff = Tools.encode("GetChatLogResp", resp)
	return resp_buff, user_info_buff
end


function is_online_feature(  step, req_buff, user_name  )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("IsOnlineResp", resp)
	elseif step == 1 then
		return datablock.main_data, user_name
	else
		error("something error");
	end
end

function is_online_do_logic( req_buff, user_name, user_info_buff )

	local req = Tools.decode("IsOnlineReq", req_buff)

	local function doLogic( )
		if Tools.isEmpty(req.user_name_list) then
			return 1
		end

		local flag_list = {}
		for i,uid in ipairs(req.user_name_list) do

			local flag = isOnline(uid)
			if flag == nil then
				return 2
			end
			flag_list[i] = flag
		end

		return 0, flag_list
	end

	local ret,flag_list = doLogic()

	local resp = {
		result = ret,
		user_name_list = req.user_name_list,
		is_online_list = flag_list,
	}
	local resp_buff = Tools.encode("IsOnlineResp", resp)
	return resp_buff, user_info_buff
end

function get_other_user_info_list_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("CmdGetOtherUserInfoListResp", resp)
	elseif step == 1 then
		return datablock.main_data, user_name
	else
		error("something error");
	end
end

function get_other_user_info_list_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("CmdGetOtherUserInfoListReq", req_buff)

	local function doLogic( )
		if Tools.isEmpty(req.user_name_list) then
			return 1
		end

		local info_list = {}

		for i,uid in ipairs(req.user_name_list) do

			local info = UserInfoCache.get(uid)
			if not info then
				return 2
			end
			table.insert(info_list, info)
		end

		return 0, info_list
	end

	local ret,info_list = doLogic()

	local resp = {
		result = ret,
		info_list = info_list,
	}
	local resp_buff = Tools.encode("CmdGetOtherUserInfoListResp", resp)
	return resp_buff,user_info_buff
end

function get_other_user_info_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		local req = Tools.decode("CmdGetOtherUserInfoReq", req_buff)
		local num = 2
		if string.sub(req.user_name, 1, 5) == "robot" then
			num = 1
		end
		return num, Tools.encode("CmdGetOtherUserInfoResp", resp)
	elseif step == 1 then
		return datablock.main_data, user_name
	elseif step == 2 then
		local req = Tools.decode("CmdGetOtherUserInfoReq", req_buff)
		return datablock.main_data + datablock.ship_list, req.user_name
	else
		error("something error");
	end
end

function get_other_user_info_do_logic(req_buff, user_name, user_info_buff, user_info_buff2, ship_list_buff2)

	local req = Tools.decode("CmdGetOtherUserInfoReq", req_buff)

	local function doLogic(  )
		if string.sub(req.user_name, 1, 5) == "robot" then

			local id = tonumber(string.match(req.user_name,"(%d+)")) 

			local conf = CONF.ROBOT.get(id)

			local lv_lineup = {}

			for i,v in ipairs(conf.MONSTER_LIST) do

				if v == 0 then
					lv_lineup[i] = 0
				else
					lv_lineup[i] = CONF.AIRSHIP.get(v).LEVEL
				end
			end

			info = {
				user_name = req.user_name,
				nickname = req.user_name,
				power = conf.POWER,
				id_lineup = conf.MONSTER_LIST,
				level = conf.LEVEL,
				lv_lineup = lv_lineup,
				icon_id = conf.ICON_ID,
			}
			return 0, info
		else

			local userInfo = require "UserInfo"
			local shipList = require "ShipList"
			userInfo:new(user_info_buff2)
			shipList:new(ship_list_buff2)
			shipList:setUserInfo(userInfo:getUserInfo())


			local other_user_info = UserInfoCache.get(req.user_name)
			if not other_user_info then
				return 1
			end

			if Tools.isEmpty(req.lineup) == false then
				local ship_list = shipList:getShipByLineup(req.lineup)
				local power = shipList:getPowerFromAll()

				other_user_info.power = power
				other_user_info.id_lineup = {0,0,0,0,0,0,0,0,0,}
				other_user_info.lv_lineup = {0,0,0,0,0,0,0,0,0,}

				for i,v in ipairs(ship_list) do
					other_user_info.id_lineup[v.position] = v.id
					other_user_info.lv_lineup[v.position] = v.level
				end
			end

			return 0, other_user_info
		end
	end

	local ret, info = doLogic(req)

	local resp = {
		result = ret,
		info = info,
	}

	local resp_buff = Tools.encode("CmdGetOtherUserInfoResp", resp)

	return resp_buff, user_info_buff, user_info_buff2, ship_list_buff2
end

function apply_friend_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = "FAIL",
		}
		return 2, Tools.encode("ApplyFriendResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("ApplyFriendReq", req_buff)
		return datablock.main_data + datablock.mail_list + datablock.save, req.recver
	else
		error("something error");
	end
end

function apply_friend_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, user_info_buff2, mail_list_buff2)

	local req = Tools.decode("ApplyFriendReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local mailList2 = require "MailList"
	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	mailList2:new(mail_list_buff2)



	local user_info = userInfo:getUserInfo()
	local mail_list2 = mailList2:getMailList()
	shipList:setUserInfo(user_info)

	local user_info2 = Tools.decode("UserInfo", user_info_buff2)

	local function doLogic( )


		if CoreUser.checkFriendsData( req.recver, "friends_list", user_info) == true then
			return "FRIEND"
		end


		--查看是否在对方黑名单
		if CoreUser.checkFriendsData( user_name, "black_list", user_info2) == true then
			return "OTHER_BLACK"
		end

		--查看是否在自己黑名单
		if CoreUser.checkFriendsData( user_info2.user_name, "black_list", user_info) == true then
			return "MY_BLACK"
		end

		if #user_info.friends_data.friends_list > GolbalDefine.friends_max then
			return "FIREND_FULL"
		end

		local power = shipList:getPowerFromAll()

		if CoreMail.recvMakeFriendMail(user_info, power,mail_list2) == false then
			return "SENDED"
		end

		local new_friend_update = {
			sender = user_info.user_name
		}

		local multicast =
		{
			recv_list = {req.recver},
			cmd = 0x1424,
			msg_buff = Tools.encode("NewFriendUpdate",new_friend_update)
		}

		--更新每日数据
		-- local daily_data = CoreUser.getDailyData(user_info)
		-- if not daily_data.apply_friend then
		-- 	daily_data.apply_friend = 1
		-- else
		-- 	daily_data.apply_friend = daily_data.apply_friend + 1
		-- end

		return "OK", multicast
	end

	local ret, multicast = doLogic()

	local resp = {
		result = ret,
		-- user_sync = {
		-- 	user_info = {
		-- 		daily_data = user_info.daily_data,
		-- 	}
		-- }
	}
	user_info_buff = userInfo:getUserBuff()
	mail_list_buff2 = mailList2:getMailBuff() 
	local resp_buff = Tools.encode("ApplyFriendResp",resp)
	if multicast then
		return resp_buff, user_info_buff, ship_list_buff, user_info_buff2, mail_list_buff2, 0x2100, Tools.encode("Multicast", multicast)
	else
		return resp_buff, user_info_buff, ship_list_buff, user_info_buff2, mail_list_buff2
	end
end

function accept_friend_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = "FAIL",
		}
		return 2, Tools.encode("AcceptFriendResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.mail_list + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("AcceptFriendReq", req_buff)
		return datablock.main_data + datablock.save, req.sender
	else
		error("something error");
	end
end

function accept_friend_do_logic( req_buff, user_name, user_info_buff, mail_list_buff, user_info_buff2 )

	local req = Tools.decode("AcceptFriendReq", req_buff)


	local user_info = Tools.decode("UserInfo", user_info_buff)
	local user_info2 = Tools.decode("UserInfo", user_info_buff2)

	local mailList = require "MailList"
	mailList:new(mail_list_buff)


	local function doLogic( )

		local mail_list = mailList:getMailList()


		if CoreUser.checkFriendsData(req.sender, "friends_list", user_info) == true then
			return "FRIEND"
		end


		local mail, mailIndex = mailList:getMailByGUID(req.mail_guid)
		if mail == nil then
			return "NO_MAIL"
		end

		if mail.from ~= req.sender then
			return "SELF"
		end

		if CoreUser.checkFriendsData(user_info.user_name, "friends_list", user_info2) == true then
			return "FRIEND"
		end

		--查看是否在对方黑名单
		if CoreUser.checkFriendsData( user_name, "black_list", user_info2) == true then
			return "OTHER_BLACK"
		end

		--查看是否在自己黑名单
		if CoreUser.checkFriendsData( user_info2.user_name, "black_list", user_info) == true then
			return "MY_BLACK"
		end

		if #user_info.friends_data.friends_list > GolbalDefine.friends_max then
			return "MY_FRIEND_FULL"
		end

		if #user_info2.friends_data.friends_list > GolbalDefine.friends_max then
			return "OTHER_FRIEND_FULL"
		end


		CoreUser.addFriendsData(req.sender, "friends_list", user_info)
		table.remove(mail_list, mailIndex)


		CoreUser.addFriendsData(user_info.user_name, "friends_list", user_info2)

		local multicast =
		{
			recv_list = {req.sender, user_info.user_name,},
			cmd = 0x1425,
			msg_buff = Tools.encode("BeFriendUpdate",{result = 0})
		}
		return "OK",multicast
	end

	local ret, multicast = doLogic()
	local resp = {
		result = ret,
	}

	mail_list_buff = mailList:getMailBuff()

	user_info_buff = Tools.encode("UserInfo",user_info)
	
	user_info_buff2 = Tools.encode("UserInfo",user_info2)

	local resp_buff = Tools.encode("AcceptFriendResp",resp)
	if multicast == nil then
		return resp_buff, user_info_buff, mail_list_buff, user_info_buff2
	else
		return resp_buff, user_info_buff, mail_list_buff, user_info_buff2, 0x2100, Tools.encode("Multicast", multicast)
	end
end


function get_friends_info_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("GetFriendsInfoResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function get_friends_info_do_logic( req_buff, user_name, user_info_buff)

	local req = Tools.decode("GetFriendsInfoReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local friends_data = userInfo:getFriendsData()

	local  function doLogic( )

		local info_list = {}

		if req.type == 0 then

			if req.nickname == nil then
				return 11
			end

			local flag, data = nick_name_ctrl.has_nick_name(req.nickname)
			if flag == false then
				return 12
			end

			local info = UserInfoCache.get(data.user_name)
			if not info then
				return 13
			end
			info_list[1] = info

		elseif req.type == 1 or req.type == 2 or req.type == 3 then

			if req.index == nil or req.index < 1 or req.num == nil or req.num < 1 then
				return 1
			end 


			local list
			if req.type == 1 then

				list = friends_data.friends_list
				

			elseif req.type == 2 then

				list = friends_data.black_list

			elseif req.type == 3 then

				list = friends_data.talk_list
				
			else
				return 100
			end


			local count = #list 
			if req.index > count then
				return 2
			end

			for i=req.index,req.num do
				local name = list[i]
				if name then
					local info = UserInfoCache.get(name)
					if info then
						info_list[i - req.index + 1] = info
					else
						return 3
					end
				else
					break
				end
			end
		elseif req.type == 4 then
			
			local function isFriend(user_name)
				for i,v in ipairs(friends_data.friends_list) do
					if v == user_name then
						return true
					end
				end
				return false
			end 

			info_list = UserInfoCache.getRandUser(user_info.user_name, math.min(req.num, 5))
			for i=#info_list,1, -1 do
				if isFriend(info_list[i].user_name) == true then
					table.remove(info_list, i)
				end
			end
		end

		return 0, info_list
	end

	local ret,info_list = doLogic()

	local resp = {
		result = ret,
		type = req.type,
		list = info_list,
	}

	user_info_buff = userInfo:getUserBuff()
	local resp_buff = Tools.encode("GetFriendsInfoResp",resp)
	return resp_buff, user_info_buff
end


function remove_friend_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 2, Tools.encode("RemoveFriendResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then

		local req = Tools.decode("RemoveFriendReq", req_buff)
		return datablock.main_data + datablock.save, req.user_name
	else
		error("something error");
	end
end

function remove_friend_do_logic( req_buff, user_name, user_info_buff, user_info_buff2)

	local req = Tools.decode("RemoveFriendReq", req_buff)

	local user_info = Tools.decode("UserInfo", user_info_buff)
	local user_info2 = Tools.decode("UserInfo", user_info_buff2)

	local  function doLogic( )
		--remove my friend
		local hasFriend, friendIndex = CoreUser.checkFriendsData(req.user_name, "friends_list", user_info)
		if hasFriend == false then
			return 1
		end

		CoreUser.removeFriendsDataByIndex(friendIndex, "friends_list", user_info)
		CoreUser.removeFriendFamiliarity(user_info,req.user_name)

		--remove other friend
		hasFriend, friendIndex = CoreUser.checkFriendsData(user_info.user_name, "friends_list", user_info2)
		if hasFriend == false then
			return 2
		end
		CoreUser.removeFriendsDataByIndex(friendIndex, "friends_list", user_info2)
		CoreUser.removeFriendFamiliarity(user_info2,user_info.user_name)

		local multicast =
		{
			recv_list = {user_info.user_name, user_info2.user_name,},
			cmd = 0x1425,
			msg_buff = Tools.encode("BeFriendUpdate",{result = 0})
		}
		return 0, multicast
	end

	local ret, multicast = doLogic()

	local resp = {
		result = ret,
	}
	local resp_buff = Tools.encode("RemoveFriendResp",resp)
	user_info_buff = Tools.encode("UserInfo", user_info)
	user_info_buff2 = Tools.encode("UserInfo", user_info2)
	if ret == 0 then
		local multicast_buff = Tools.encode("Multicast", multicast)
		return resp_buff, user_info_buff, user_info_buff2, 0x2100, multicast_buff
	end
	return resp_buff, user_info_buff, user_info_buff2
end
function friend_add_tili_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		return 2, Tools.encode("FriendAddTiliResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("FriendAddTiliReq", req_buff)
		return datablock.main_data + datablock.save, req.user_name
	else
		error("something error");
	end
end

function friend_add_tili_do_logic(req_buff, user_name, user_info_buff, user_info_buff2)
	local req = Tools.decode("FriendAddTiliReq", req_buff)
	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	local user_info = Tools.decode("UserInfo", user_info_buff)
	local user_info2 = Tools.decode("UserInfo", user_info_buff2)

	Tools._print("friend_add_tili_do_logic", req.user_name)

	local function sendToUser2()
		local user_sync2 = 
		{
			user_info = 
			{
				friends_data = user_info2.friends_data,
			},
		}
		CoreUser.userSyncUpdate(user_info2.user_name,user_sync2)

		local add_tili_update = 
		{
			result = 0,
			info = info,
		}
		local multicast_update =
		{
			recv_list = {user_info2.user_name},
			cmd = 0x1436,
			msg_buff = nickname
		}
      	local multi_buff = Tools.encode("Multicast", multicast_update)
      	activeSendMessage(user_name, 0x2100, multi_buff)
	end

	local function doLogic()
		if CoreUser.checkFriendsData( req.user_name, "friends_list", user_info) == false then --不在好友列表
			return 1
		end
		--查看是否在对方黑名单
		if CoreUser.checkFriendsData( user_name, "black_list", user_info2) == true then
			return 2
		end
		--查看是否在自己黑名单
		if CoreUser.checkFriendsData( req.user_name, "black_list", user_info) == true then
			return 3
		end

		if CoreUser.AddFriendTili(user_info , user_info2) ==false then
			return 4
		end

		local user_sync = 
		{
			user_info = 
			{
				friends_data = user_info.friends_data,
			},
		}
		sendToUser2()
		return 0, user_sync
	end

	local ret, user_sync = doLogic()
	local resp = {
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("FriendAddTiliResp",resp)
	user_info_buff = Tools.encode("UserInfo", user_info)
	user_info_buff2 = Tools.encode("UserInfo", user_info2)
	return resp_buff, user_info_buff, user_info_buff2
end

function friend_read_tili_feature( step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("FriendReadTiliResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end
function friend_read_tili_do_logic(req_buff, user_name, user_info_buff)
	local req = Tools.decode("FriendReadTiliReq", req_buff)
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local function doLogic()
		local user_sync
		local alltili = 0
		local ret = 0
		for _ , v in ipairs(req.user_name) do
			if CoreUser.checkFriendsData( v, "friends_list", user_info) then --不在好友列表
				local b = CoreUser.ReadFriendTili(user_info, v)
				if b then
					local tili = CONF.PARAM.get("friends get_energy").PARAM
					alltili = alltili + tili
					userInfo:addStrength(tili)
					user_sync = CoreItem.syncStrength(user_info,user_sync)
				end
			end
		end
		if user_sync then
			user_sync.user_info.friends_data = user_info.friends_data
			Tools._print("friend_read_tili_do_logic")
			Tools.print_t(user_sync.user_info.friends_data)
		else
			ret = 1
		end
		return ret , alltili, user_sync
	end

	local ret, alltili, user_sync = doLogic()
	local resp = {
		result = ret,
		all_tili = alltili,
		user_sync = user_sync,
	}
	Tools.print_t(resp)
	local resp_buff = Tools.encode("FriendReadTiliResp", resp)

	user_info_buff = userInfo:getUserBuff()

	return resp_buff, user_info_buff
end

function black_list_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		local req = Tools.decode("BlackListReq", req_buff)

		return req.type == 1 and 2 or 1, Tools.encode("BlackListResp", resp)
	elseif step == 1 then

		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("BlackListReq", req_buff)

		return datablock.main_data + datablock.save, req.user_name
	else
		error("something error");
	end
end

function black_list_do_logic( req_buff, user_name, user_info_buff, user_info_buff2)

	local req = Tools.decode("BlackListReq", req_buff)

	local user_info = Tools.decode("UserInfo",user_info_buff)

	local user_info2

	
	local  function doLogic( )
		
		local info_list = {}

		if req.type == 1 then

			if CoreUser.checkFriendsData(req.user_name, "black_list", user_info) == true then
				return 1
			end

			local hasFriend, friendIndex = CoreUser.checkFriendsData(req.user_name, "friends_list", user_info)
			if hasFriend == true then
				CoreUser.removeFriendsDataByIndex(friendIndex, "friends_list", user_info)
				CoreUser.removeFriendFamiliarity(user_info, req.user_name)
			end

			CoreUser.addFriendsData(req.user_name, "black_list", user_info)

	
			user_info2 = Tools.decode("UserInfo",user_info_buff2)
			hasFriend, friendIndex = CoreUser.checkFriendsData(user_info.user_name, "friends_list", user_info2)
			if hasFriend == true then
				CoreUser.removeFriendsDataByIndex(friendIndex, "friends_list", user_info2)
				CoreUser.removeFriendFamiliarity(user_info2, user_info.user_name)
			end


		elseif req.type == 2 then

			local has, index = CoreUser.checkFriendsData(req.user_name, "black_list", user_info)
			if has == false then
				return 11
			end

			CoreUser.removeFriendsDataByIndex(index, "black_list", user_info)
		else
			return 100
		end

		return 0
	end

	local ret = doLogic()

	local resp = {
		result = ret,
	}

	local resp_buff = Tools.encode("BlackListResp",resp)

	user_info_buff = Tools.encode("UserInfo",user_info)
	
	if req.type == 1 then 
		user_info_buff2 = Tools.encode("UserInfo",user_info2)
		return resp_buff, user_info_buff, user_info_buff2
	else
		return resp_buff, user_info_buff
	end
	
end


function talk_list_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = -1,
		}
		local req = Tools.decode("TalkListReq", req_buff)

		return req.type == 1 and 2 or 1, Tools.encode("TalkListResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("TalkListReq", req_buff)
		return datablock.main_data, req.user_name
	else
		error("something error");
	end
end

function talk_list_do_logic( req_buff, user_name, user_info_buff, user_info_buff2)

	local req = Tools.decode("TalkListReq", req_buff)

	local user_info = Tools.decode("UserInfo", user_info_buff)
	
	local  function doLogic()

		if req.type == 1 then

			if CoreUser.checkFriendsData(req.user_name, "talk_list", user_info) == true then
				return 1
			end

			CoreUser.addFriendsData(req.user_name, "talk_list", user_info)

			if #user_info.friends_data.talk_list > GolbalDefine.talk_max then
				CoreUser.removeFriendsDataByIndex(1, "talk_list", user_info)
			end

		elseif req.type == 2 then
			local has,index = CoreUser.checkFriendsData(req.user_name, "talk_list", user_info)
			if has == false then
				return 11
			end
			CoreUser.removeFriendsDataByIndex(index, "talk_list", user_info)
		else
			return 100
		end
		return 0
	end

	local ret = doLogic()

	local resp = {
		result = ret,
	}

	local resp_buff = Tools.encode("TalkListResp",resp)

	user_info_buff = Tools.encode("UserInfo", user_info)
	
	return resp_buff, user_info_buff, user_info_buff2
end


function task_list_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("TaskListResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end


function task_list_do_logic(req_buff, user_name, user_info_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()

	local resp = {
		result = 0,
		task_list = user_info.task_list,
	}

	local resp_buff = Tools.encode("TaskListResp", resp)

	user_info_buff = Tools.encode("UserInfo", user_info)

	return resp_buff, user_info_buff
end

function task_reward_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("TaskRewardResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.item_package + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end

function task_reward_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)

	local req = Tools.decode("TaskRewardReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()
	local item_list = itemList:getItemList()

	shipList:setUserInfo(user_info)

	local planet_user = PlanetCache.getUser(user_info.user_name)

	local function doLogic( task_id )

		if task_id < 0 then --获取每日活跃奖励

			local want_get_level = -task_id
			if want_get_level > 4 then
				return 21
			end

			local daily_data = CoreUser.getDailyData(user_info)
			if daily_data.active == nil then
				daily_data.active = 0
			end

			local dailyConf
			local daily_list = CONF.DAILYTASK.getIDList()
			for i,v in ipairs(daily_list) do
				local conf = CONF.DAILYTASK.get(v)
				if user_info.level >= conf.START_LEVEL and user_info.level <= conf.END_LEVEL then
					dailyConf = conf
					break
				end
			end
			if dailyConf == nil then
				dailyConf = CONF.DAILYTASK.get(daily_list[#daily_list])
			end

			if dailyConf["ACTIVE_POINT"..want_get_level] == nil then
				return 22
			end
			if daily_data.active < dailyConf["ACTIVE_POINT"..want_get_level] then
				return 23
			end
			if Tools.isEmpty(daily_data.get_active_level) == true then
				daily_data.get_active_level = {false,false,false,false,}
			end
			if daily_data.get_active_level[want_get_level] == true then
				return 24
			end
			local user_sync = userInfo:getReward(dailyConf["REWARD"..want_get_level], item_list)

			daily_data.get_active_level[want_get_level] = true

			user_sync.user_info = user_sync.user_info or {}
			user_sync.user_info.daily_data = daily_data

			return 0, user_sync
		end

		local taskConf = CONF.TASK.get(task_id)

		local user_sync

		if taskConf.TYPE == 3 or taskConf.TYPE == 1 then
			local task_info,task_index = userInfo:getTaskInfo(req.task_id)
			if task_info and task_info.finished == true then
				return 11
			end
			if Tools.calTask(taskConf, user_info, ship_list, planet_user) == false then
				return 12
			end

			if user_info.level < taskConf.OPEN_LEVEL then
				return 13
			end

			local items = {}

			for i,v in ipairs(taskConf.ITEM_ID) do
				items[v] = taskConf.ITEM_NUM[i]
			end

			CoreItem.addItems(items, item_list, user_info)

			user_sync = CoreItem.makeSync(items, item_list, user_info)

			if task_info == nil then
				userInfo:addTaskInfo(task_id, true)
			else
				task_info.finished = true
			end
			user_sync.task_list = {}
			table.insert(user_sync.task_list, {task_id = task_id, finished = true})

			if taskConf.TYPE == 1 then
				local daily_data = CoreUser.getDailyData(user_info)
				if daily_data.active == nil then
					daily_data.active = 0
				end
				daily_data.active = daily_data.active + taskConf.ACTIVE_POINT
				local max_active = CONF.PARAM.get("max_active").PARAM
				if daily_data.active > max_active then
					daily_data.active = max_active
				end

				user_sync.user_info = user_sync.user_info or {}
				user_sync.user_info.daily_data = user_info.daily_data
			end
		else

			local task_info,task_index = userInfo:getTaskInfo(req.task_id)
			if task_info == nil then
				return 1
			end 

			if Tools.calTask(taskConf, user_info, ship_list, planet_user) == false then
				return 2
			end

			if user_info.level < taskConf.OPEN_LEVEL then
				return 3
			end

			local items = {}

			for i,v in ipairs(taskConf.ITEM_ID) do
				items[v] = taskConf.ITEM_NUM[i]
			end

			CoreItem.addItems(items, item_list, user_info)


			userInfo:removeTaskInfo(task_index)

			user_sync = CoreItem.makeSync(items, item_list, user_info)

			user_sync.task_list = {{task_id = -task_id},}

			if type(taskConf.NEXT_ID) == "table" then
				for i,v in ipairs(taskConf.NEXT_ID) do

					userInfo:addTaskInfo(v)

					table.insert(user_sync.task_list, {task_id = v})
				end
			end

			local achievement_data = userInfo:getAchievementData()
			if achievement_data.task_finish_times == nil then
				achievement_data.task_finish_times = 0
			end
			achievement_data.task_finish_times = achievement_data.task_finish_times + 1
			user_sync.user_info.achievement_data = achievement_data
		end
		return 0, user_sync
	end

	local ret, user_sync = doLogic(req.task_id)


	local resp = {
		result = ret,
		user_sync = user_sync,
		task_id = req.task_id,
		other = req.other,
	}

	local resp_buff = Tools.encode("TaskRewardResp", resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end


function get_strength_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("GetStrengthResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end


function get_strength_do_logic(req_buff, user_name, user_info_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local resp = {
		result = 0,
		user_sync = {
			user_info = {
				strength = userInfo:getStrength(),
			},
		},
	}

	local resp_buff = Tools.encode("GetStrengthResp", resp)

	user_info_buff = userInfo:getUserBuff()

	return resp_buff, user_info_buff
end

function add_strength_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("AddStrengthResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end


function add_strength_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("AddStrengthReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local function useItem( req )
		if req.item == nil then
			return "REQ_DATA_ERROR"
		end
		local itemConf = CONF.ITEM.get(req.item.key)

		if itemConf.TYPE ~= CONF.EItemType.kNormal then
			return "ITEM_KEY_ERROR"
		end
		local keyConf = CONF.ITEM.get(itemConf.KEY)
		if keyConf.TYPE ~= CONF.EItemType.kStrength then
			return "ITEM_KEY_ERROR"
		end

		local items = {[req.item.key] = req.item.value}

		if CoreItem.checkItems(items, item_list, user_info) == false then
			return "NO_ITEM"
		end

		local getItems = {[itemConf.KEY] = itemConf.VALUE * items[req.item.key]}
		CoreItem.addItems(getItems, item_list, user_info)
		local user_sync = CoreItem.makeSync(getItems, item_list, user_info)

		CoreItem.expendItems(items, item_list, user_info)
		CoreItem.makeSync(items, item_list,user_info , user_sync)

		return "OK", user_sync
	end
	local function useMoney( req )
		local next_times = user_info.strength_buy_times + 1
		local conf = CONF.STRENGTH.check(next_times)
		local vipConf = CONF.VIP.get(user_info.vip_level)
		if not conf or user_info.strength_buy_times >= vipConf.STRENGTH_TIMES then
			return "MAX_TIMES"
		end
		if CoreItem.checkMoney(user_info, conf.COST) == false then
			return "NO_MONEY"
		end
		CoreItem.expendMoney(user_info, conf.COST, CONF.EUseMoney.eAdd_strength)

		CoreItem.addStrength(user_info, conf.VALUE)

		user_info.strength_buy_times = next_times

		local user_sync = CoreItem.syncMoney(user_info)
		CoreItem.syncStrength(user_info, user_sync)
		user_sync.user_info.strength_buy_times = next_times

		return "OK", user_sync
	end

	local ret
	local user_sync
	if req.type == 1 then
		ret, user_sync = useItem(req)
	elseif req.type == 2 then
		ret, user_sync = useMoney(req)
	end

	local resp = {
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("AddStrengthResp", resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, item_list_buff
end


function rank_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("RankResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list, user_name
	else
		LOG_ERR("something error");
		return
	end
end

function rank_do_logic(req_buff, user_name, user_info_buff, ship_list_buff)

	local req = Tools.decode("RankReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()

	shipList:setUserInfo(user_info)

	local rank_num = 10

	local resp = {

		user_rank = {},
		group_rank = {},
	}

	local function doLogic( req  )

		if req.start_rank <= 0 then
			return 1
		end

		if req.rank_type == "PLAYER_LEVEL" then

			if req.start_rank > 0 then
				for index = req.start_rank,rank_num do
					local info = UserInfoCache.getRankLevelInfo(index)
					if info then
						table.insert(resp.user_rank, info)
					end
				end
			end

			if req.need_my == true then
				local my_info = UserInfoCache.get(user_info.user_name)
				if my_info then
					resp.my_user_rank = my_info
				end
			end

		elseif req.rank_type == "PLAYER_POWER" then

			local other_user_info = UserInfoCache.get(user_info.user_name)
			if other_user_info then
				local power = shipList:getPowerFromAll()
				if power ~= other_user_info.power then
					other_user_info.power = power
					UserInfoCache.set(user_info.user_name, other_user_info)
				end
			end

			if req.start_rank > 0 then
				for index = req.start_rank,rank_num do
					local info = UserInfoCache.getRankPowerInfo(index)
					if info then
						table.insert(resp.user_rank, info)
					end
				end
			end

			if req.need_my == true then
				local my_info = UserInfoCache.get(user_info.user_name)
				if my_info then
					resp.my_user_rank = my_info
				end
			end


		elseif req.rank_type == "MAIN_CITY_LEVEL" then

			if req.start_rank > 0 then
				for index = req.start_rank,rank_num do
					local info = UserInfoCache.getRankMainCityLevelInfo(index)
					if info then
						table.insert(resp.user_rank, info)
					end
				end
			end

			if req.need_my == true then
				local my_info = UserInfoCache.get(user_info.user_name)
				if my_info then
					resp.my_user_rank = my_info
				end
			end

		elseif req.rank_type == "GROUP_POWER" then

			if req.start_rank > 0 then
				for index = req.start_rank,rank_num do
					local group_main = GroupCache.getGroupByRank(index)
					local info = GroupCache.toOtherGroupInfo(group_main)
					if info then
						resp.group_rank[index] = info
					end
				end
			end
			if req.need_my == true then
				if user_info.group_data.groupid ~= "" then
					local group_main = GroupCache.getGroupMain(user_info.group_data.groupid)
					local my_group_info = GroupCache.toOtherGroupInfo(group_main)
					if my_group_info then
						resp.my_group_rank = my_group_info
					end
				end
				
			end

		elseif req.rank_type == "ARENA" then

			if req.start_rank > 0 then
				for index = req.start_rank,rank_num do
					local arena_info_data = ArenaCache.getByRank(index)
					local info = UserInfoCache.get(arena_info_data.user_name)
					if info then
						resp.user_rank[index] = info
					end
				end
			end
			if req.need_my == true then
				local my_info = UserInfoCache.get(user_info.user_name)
				if my_info then
					resp.my_user_rank = my_info
				end
			end

		elseif req.rank_type == "TRIAL" then

			if req.start_rank > 0 then
				for index = req.start_rank,rank_num do
					local info = UserInfoCache.getRankTrialLevelInfo(index)
					if info and (info.max_trial_level ~= nil and info.max_trial_level > 0) then
						table.insert(resp.user_rank, info)
					end
				end
			end
			if req.need_my == true then
				local my_info = UserInfoCache.get(user_info.user_name)
				if my_info and (my_info.max_trial_level ~= nil and my_info.max_trial_level > 0) then
					resp.my_user_rank = my_info
				end
			end
		end

		return 0
	end


	resp.result = doLogic(req)

	local resp_buff = Tools.encode("RankResp", resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff
end

function regist_init_ship_feature( step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("RegistInitShipResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end

function regist_init_ship_do_logic(req_buff, user_name, user_info_buff, ship_list_buff)

	local req = Tools.decode("RegistInitShipReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()

	shipList:setUserInfo(user_info)

	local function doLogic( req )

		if user_info.init_ship_index ~= nil and user_info.init_ship_index > 0 then
			return 1
		end
		local ship_id_list = CONF.PARAM.get(string.format("start_ships_%d", req.init_index)).PARAM
		local lineup = {0,0,0,0,0,0,0,0,0}
		local user_sync = {
			user_info = {},
			ship_list = {},
		}
		for i,v in ipairs(ship_id_list) do

			local ship_info = shipList:add(v)
			if ship_info == nil then
				return 2
			end
			if i < #lineup then
				lineup[i] = ship_info.guid
				table.insert(user_sync.ship_list, ship_info)
			end
		end
		shipList:changeLineup(user_info, lineup)

		user_sync.user_info.lineup = user_info.lineup

		user_info.init_ship_index = req.init_index

		user_sync.user_info.init_ship_index = req.init_index

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("RegistInitShipResp", resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()

	return resp_buff, user_info_buff, ship_list_buff
end

function shop_time_item_list_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("ShopTimeItemListResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end

function shop_time_item_list_do_logic(req_buff, user_name, user_info_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)


	local user_info = userInfo:getUserInfo()

	local cur_time = os.time()
	local ret = 0
	local time_item_list = {}
	local id_list = CONF.SHOP.getIDList()
	for i,id in ipairs(id_list) do
		local conf = CONF.SHOP.get(id)
		if conf.START_TIME > 0 then
			local start_time = getTimeStampFrom(conf.START_TIME)
			local end_time = getTimeStampFrom(conf.END_TIME)

			if cur_time >= start_time and cur_time < end_time then
				table.insert(time_item_list, {id = id, end_time = end_time})
			end
		end
		
	end

	if Tools.isEmpty(time_item_list) == true then
		ret = 1
	end

	local resp = {
		result = ret,
		list = time_item_list,
	}

	local resp_buff = Tools.encode("ShopTimeItemListResp", resp)

	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end

function shop_buy_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("ShopBuyResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end

function shop_buy_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("ShopBuyReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local function doLogic( req )

		if req.num <= 0 or req.id <= 0 then
			return 1
		end

		if req.num > 999 then
			return 2
		end

		local cur_time = os.time()

		local goodsConf = CONF.SHOP.get(req.id)
		if goodsConf.START_TIME > 0 then
			local start_time = getTimeStampFrom(goodsConf.START_TIME)
			local end_time = getTimeStampFrom(goodsConf.END_TIME)

			if cur_time >= start_time and cur_time < end_time then
				return 2
			end
		elseif goodsConf.START_TIME == -2 then
			if user_info.timestamp.regist_time + goodsConf.END_TIME < cur_time then
				return 2
			end
		end


		local needNum = goodsConf.COST * req.num
		if goodsConf.COST_TYPE == 2 then
			if CoreItem.checkMoney(user_info, needNum) == false then
				return 3
			end
		elseif goodsConf.COST_TYPE == 1 then
			if CoreItem.checkRes(user_info, 1, needNum) == false then
				return 4
			end
		elseif goodsConf.COST_TYPE == 3 then
			if Tools.isEmpty(user_info.group_data) == true then
				return 5
			end
			if user_info.group_data.contribute < needNum then
				return 5
			end
		end

		if userInfo:addShopTimes(req.id, req.num) == false then
			return 6
		end

		local items = {}
		items[goodsConf.ITEM] = req.num * goodsConf.ITEM_NUM
		CoreItem.addItems(items, item_list, user_info)
		LOG_STAT( string.format( "%s|%s|%d|%d|%d", "BUY_ITEM", user_info.user_name, req.id, req.num, needNum ) )

		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		if goodsConf.COST_TYPE == 2 then
			CoreItem.expendMoney(user_info, needNum, CONF.EUseMoney.eBuy_shop)
		elseif goodsConf.COST_TYPE == 1 then
			CoreItem.expendRes(user_info, 1, needNum)
			CoreItem.syncRes(user_info, user_sync)
		elseif goodsConf.COST_TYPE == 3 then
			if Tools.isEmpty(user_info.group_data) == false then
				user_info.group_data.contribute = user_info.group_data.contribute - needNum
				user_sync.user_info.group_data = user_info.group_data
			end
		end

		user_sync.user_info.shop_data = userInfo:getShopData()

		CoreItem.syncMoney(user_info, user_sync)

		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)


	local resp = {
		result = ret,
		user_sync = user_sync,
		req = req,
	}

	local resp_buff = Tools.encode("ShopBuyResp", resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function ship_lottery_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("ShipLotteryResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.item_package + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end

function ship_lottery_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
	local req = Tools.decode("ShipLotteryReq", req_buff)

	local cur_time = os.time()
	math.randomseed(tostring(cur_time):reverse():sub(1, 6)) 

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()
	local item_list = itemList:getItemList()
	local achievement_data = userInfo:getAchievementData()

	shipList:setUserInfo(user_info)


	local function rand(weights)

		if Tools.isEmpty(weights) == true then

			return 0
		end

		local total_weight = 0
		for _,v in ipairs(weights) do
			total_weight = total_weight + v
		end

		if total_weight == 0 then

			return 0
		end

		local weight = math.random(total_weight)

		local num = 0
		for index,value  in ipairs(weights) do
			num = num + value

			if weight <= num then
	
				return index
			end
		end

		return 0
	end

	local function addItem( id, num, items )
		if (id == nil or id <= 0) or (num == nil or num <= 0) then
			return false
		end
		if items[id] == nil then
			items[id] = num
		else
			items[id] = items[id] + num
		end
		return true
	end
	local conf = CONF.SHIP_LOTTERY.get(req.id)	

	local function lottery( req )
		local count
		if req.type == 1 then
			count = 1
		elseif  req.type == 2 then
			count = 10
		end
		local daily_data = CoreUser.getDailyData(user_info)
		-- if server_platform == 0 then --如果是中文审核版 限制抽奖次数
		-- 	if daily_data.lottery_count == nil then
		-- 		daily_data.lottery_count = 0
		-- 	end
		-- 	if daily_data.lottery_count + count >= 30 then
		-- 		return 111
		-- 	end
		-- end	

		local user_sync = {
			item_list = {},
			user_info = {},
			equip_list = {},
			gem_list = {},
		}

		local info = userInfo:getShipLotteryInfo(req.id)

		local needNum = (req.type == 1 and conf.SINGLE) or conf.MULTI
		if conf.GACHA_TYPE == 1 then

			if req.type == 1 and info.cd_start_time == 0 and info.free_times > 0 then

			else
				if CoreItem.checkRes(user_info, 1, needNum) == false then
					return 1
				end
			end
			
		elseif conf.GACHA_TYPE == 2 then
			if info.free_times <= 0 or req.type == 2 then
				if CoreItem.checkMoney(user_info, needNum) == false then
					return 2
				end
			end
		else
			return 3
		end

		local items = {}
		local item_index = 0

		local item_vec = {}		
		if req.type == 1 then
	
			local id,num

			info.single_times = info.single_times + 1
			local list
			if info.single_times == conf.HEAP + 1 then
				item_index = rand(conf.HEAP_WEIGHT)
				id = conf.HEAP_ITEM[item_index]
				num = conf.HEAP_NUM[item_index]
				
				info.single_times = 0
			else
				item_index = rand(conf.ITEM_WEIGHT)
				id = conf.ITEM[item_index]
				num = conf.ITEM_NUM[item_index]
			end
			
			if not addItem( id, num, items ) then
				return 4
			end

			table.insert(item_vec, {
				id = id,
				num = num,
				guid = 0,
			})

		elseif  req.type == 2 then

			for i=1,9 do
				item_index = rand(conf.ITEM_WEIGHT)
				if not addItem( conf.ITEM[item_index], conf.ITEM_NUM[item_index], items) then
					return 6
				end
				table.insert(item_vec, {
					id = conf.ITEM[item_index],
					num = conf.ITEM_NUM[item_index],
					guid = 0,
				})
			end

			item_index = rand(conf.MIN_WEIGHT)
			local itemid = 0
			local itemnum = 0
			if conf.GACHA_TYPE == 1 then
				if achievement_data.first_lottery_res then
					itemid = conf.MIN_ITEM[item_index]
					itemnum = conf.MIN_NUM[item_index]
				else
					itemid = conf.FIRST_ITEM[item_index]
					itemnum = conf.FIRST_NUM[item_index]
					achievement_data.first_lottery_res = true
				end
			elseif conf.GACHA_TYPE == 2 then
				if achievement_data.first_lottery_money then
					itemid = conf.MIN_ITEM[item_index]
					itemnum = conf.MIN_NUM[item_index]
				else
					itemid = conf.FIRST_ITEM[item_index]
					itemnum = conf.FIRST_NUM[item_index]
					achievement_data.first_lottery_money = true
				end
			end

			if not addItem( itemid, itemnum, items) then
				return 7
			end
			table.insert(item_vec, {
				id = itemid,
				num = itemnum,
				guid = 0,
			})

		else
			return 8
		end
		for k,v in pairs(items) do
			local itemConf = CONF.ITEM.get(k)
			if itemConf.TYPE == CONF.EItemType.kShip then

				local shipConf = CONF.AIRSHIP.get(itemConf.KEY)

				if shipList:getShipInfoByID(shipConf.ID) ~= nil then
					if Tools.isEmpty(shipConf.BLUEPRINT) == false and Tools.isEmpty(shipConf.RETURN_BLUEPRINT_NUM) == false then
						for i,id in ipairs(shipConf.BLUEPRINT) do
							if shipConf.RETURN_BLUEPRINT_NUM[i] ~= nil then
								addItem(id, shipConf.RETURN_BLUEPRINT_NUM[i], items)
								table.insert(item_vec, {
									id = id,
									num = shipConf.RETURN_BLUEPRINT_NUM[i],
									guid = 0,
								})
							end
						end
						for i=#item_vec,1, -1 do
							if item_vec[i].id == k then
								table.remove(item_vec, i)
								break
							end
						end					
					end
				else
					local ship_info = shipList:shipCreate( shipConf.ID, user_sync)
					if ship_info == nil then
						return 9
					end
				end

				items[k] = nil
			elseif itemConf.TYPE == CONF.EItemType.kShipBulepoint and itemConf.QUALITY >= CONF.PARAM.get("broadcast_port").PARAM then
				--发送广播

				sendBroadcast(user_info.user_name, Lang.world_chat_sender, string.format(Lang.lottery_board_msg, user_info.nickname, CONF.STRING.get(itemConf.NAME_ID).VALUE, v))
			end
		end
		CoreItem.addItems(items, item_list, user_info)
		CoreItem.makeSync(items, item_list, user_info, user_sync)
		local useFreeTime = false
		--免费单抽
		if info.free_times > 0 and info.cd_start_time == 0 and req.type == 1 then

			info.free_times = info.free_times - 1
			if info.free_times < 0 then
				info.free_times = 0
			end

			if conf.SINGLE_CD > 0 then

				info.cd_start_time = cur_time

			elseif  conf.RESET > 0 then

				if info.free_times < conf.FREE_TIMES then
					info.add_free_start_time = cur_time
				end
			end
		--花费单抽或10连
		else

			if conf.GACHA_TYPE == 1 then

				CoreItem.expendRes(user_info, 1, needNum)
				CoreItem.syncRes(user_info, user_sync)
				
			elseif conf.GACHA_TYPE == 2 then

				CoreItem.expendMoney(user_info, needNum, CONF.EUseMoney.eLottery)
				CoreItem.syncMoney(user_info, user_sync)
			end

		end

		user_sync.user_info.ship_lottery_data = user_info.ship_lottery_data

		
		if  req.id == 2 then
			if achievement_data.lottery_count == nil then
				achievement_data.lottery_count = count
			else
				achievement_data.lottery_count = achievement_data.lottery_count + count
			end
		end
		user_sync.user_info.achievement_data = achievement_data

		--更新每日数据
		if  req.id == 2 then
			if not daily_data.lottery_count then
				daily_data.lottery_count = count
			else
				daily_data.lottery_count = daily_data.lottery_count + count
			end
		end
		user_sync.user_info.daily_data = user_info.daily_data

		--更新活动数据
		user_sync.activity_list = user_sync.activity_list or {}
		local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
		if activity_list then
			for i,v in ipairs(activity_list) do
				if  req.id == 2 then
					local count = v.seven_days_data.lottery_count or 0
					v.seven_days_data.lottery_count = count + 1
				end

				if conf.GACHA_TYPE == 2 then
					local moneyCount = v.seven_days_data.money_lottery_count or 0
					v.seven_days_data.money_lottery_count = moneyCount + 1
				end
				table.insert(user_sync.activity_list, v)
			end
		end
		return 0, user_sync, item_vec
	end

	local function update( req )

		local info = userInfo:getShipLotteryInfo(req.id)

		if info.add_free_start_time > 0 then

			if cur_time < (info.add_free_start_time + conf.RESET) then
				return 11
			end
			info.free_times = info.free_times + 1
			if info.free_times > conf.FREE_TIMES then
				info.free_times = conf.FREE_TIMES
			end
			info.add_free_start_time = 0

		elseif info.cd_start_time > 0 and conf.SINGLE_CD > 0 then

			if cur_time < (info.cd_start_time + conf.SINGLE_CD) then
				return 12
			end
			info.cd_start_time = 0
		end

		local user_sync = {
			user_info = {
				ship_lottery_data = user_info.ship_lottery_data
			},
		}

		return 0, user_sync
	end

	local ret, user_sync, item_vec
	if req.type == 0 then
		ret, user_sync = update(req)
	else
		ret, user_sync, item_vec = lottery(req)
	end


	local resp = {
		result = ret,
		user_sync = user_sync,
		item_list = item_vec,
	}

	local resp_buff = Tools.encode("ShipLotteryResp", resp)

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end

function guide_step_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("GuideStepResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end

function guide_step_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("GuideStepReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local function doConfig(conf, user_sync)
		if conf == nil then
			return user_sync
		end
		if conf.EXP and conf.EXP > 0 then
	
			CoreUser.addExp(conf.EXP, user_info)
			user_sync.user_info.exp = user_info.exp
			user_sync.user_info.level = user_info.level
		end

		if conf.ITEM then
			local items = {}
			for i,v in ipairs(conf.ITEM) do
				items[v] = conf.ITEM_NUM[i]
			end
			
			if CoreItem.addItems( items, item_list, user_info) == false then
				return user_sync
			end
			user_sync = CoreItem.makeSync(items, item_list, user_info, user_sync)

		end
		return user_sync
	end

	local function doLogic( req )

		local user_sync = {
			item_list = {},
			user_info = {},
			equip_list = {},
			gem_list = {},
		}

		if req.type == 1 then

			if req.step_index < 0 or req.step_index > 40 then
				return 1
			end

			local guide_list = user_info.achievement_data.guide_list
			if Tools.isEmpty(guide_list) == true then
				for i=1,40 do
					guide_list[i] = 0
				end
			elseif #guide_list < 40 then
				for i=#guide_list+1 , 40 do
					guide_list[i] = 0
				end
			end
			local flag = false
			local tmpsave = guide_list[req.step_index]
			if req.step_index == 1 then
				if req.step_num < tmpsave then
					Tools._print("GuideStepReq step", req.step_num, tmpsave)
					return 1
				end
			end
			if tmpsave < req.step_num then
				flag = true
			end
			guide_list[req.step_index] = req.step_num
			--print("record", req.step_index, req.step_num, user_name)

			user_info.achievement_data.guide_list = guide_list

			
			local conf_list
			if req.step_index == 1 then
				conf_list = CONF.GUIDANCE
			else
				conf_list = CONF.SYSTEM_GUIDANCE
			end

			local conf = conf_list.check(req.step_num)

			if req.step_index == 1 then
				if flag then
					if req.step_num >= conf_list.count() then
						for i = tmpsave , req.step_num do
							conf = conf_list.check(i)
							if conf and conf.SAVE and tmpsave < conf.SAVE then
								tmpsave = conf.SAVE
								user_sync = doConfig(conf, user_sync)
							end
						end
						Tools._print("GuideStepReq end",req.step_num,tmpsave,user_sync.user_info.exp)
					else
						user_sync = doConfig(conf, user_sync)
					end
					if tmpsave ~= req.step_num then
						LOG_STAT( string.format( "%s|%s|%d", "GUIDE", user_info.user_name,req.step_num ) )
					end
				end			
			else
				if flag then
					user_sync = doConfig(conf, user_sync)	
				end
			end
				
				
				--[[if conf then
					if conf.EXP and conf.EXP > 0 then
	
						CoreUser.addExp(conf.EXP, user_info)
						user_sync.user_info.exp = user_info.exp
						user_sync.user_info.level = user_info.level
					end

					if conf.ITEM then
						local items = {}
						for i,v in ipairs(conf.ITEM) do
							items[v] = conf.ITEM_NUM[i]
						end
						
						if CoreItem.addItems( items, item_list, user_info) == false then
							return 3
						end
						CoreItem.makeSync(items, item_list, user_info, user_sync)

					end
				end]]
			--end
		elseif req.type == 2 then

			local data = Tools.clone(user_info.achievement_data)
			data.talk_key = req.talk_key
			user_info.achievement_data = data
		end
		user_sync.user_info.achievement_data = user_info.achievement_data
		return 0, user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("GuideStepResp", resp)

	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff
end


function aid_award_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("AidAwardResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end

function aid_award_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("AidAwardReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local function doLogic( req )
		local cur_time = os.time()
		
		if req.type == 1 then
			if user_info.timestamp.regist_aid_award_time ~= nil then
				return 1
			end
			user_info.timestamp.regist_aid_award_time = cur_time
			local user_sync = {
				user_info = {
					timestamp = user_info.timestamp,
				}
			}
			return 0, user_sync
		else
			if user_info.timestamp.regist_aid_award_time == nil or user_info.timestamp.regist_aid_award_time == 0 then
				return 11
			end
			local need = user_info.aid_award_index + 1

			local conf = CONF.AIDAWARD.get(need)
			if cur_time - user_info.timestamp.regist_aid_award_time < conf.TIME then
				return 12
			end

			local addItems = {}
			for i,v in ipairs(conf.ITEM) do
				addItems[v] = conf.NUM[i]
			end
			if CoreItem.addItems( addItems, item_list, user_info) == false then
				return 13
			end

			user_info.aid_award_index = need

			local user_sync = CoreItem.makeSync(addItems, item_list, user_info)
			user_sync.user_info.aid_award_index = need
			return 0, user_sync
		end
	end

	local ret, user_sync = doLogic(req)


	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("AidAwardResp", resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff
end

function open_gift_feature(step, req, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("OpenGiftResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		LOG_ERR("something error");
		return
	end
end

function open_gift_do_logic(req_buff, user_name, user_info_buff, item_list_buff)

	local req = Tools.decode("OpenGiftReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local function doLogic( req )

		local use_items = {}
		use_items[req.item_id] = req.num
		

		if CoreItem.checkItems(use_items, item_list, user_info) == false then
			return 1
		end

		local item_conf = CONF.ITEM.get(req.item_id)
		if item_conf.TYPE ~= CONF.EItemType.kGiftBag then
			return 2
		end

		if item_conf.VALUE > 0 and user_info.level < item_conf.VALUE then
			return 3
		end
		
		local items = Tools.getRewards(item_conf.KEY)

		local get_item_list = {}
		for k,v in pairs(items) do
			table.insert(get_item_list, {id = k, num = items[k], guid = 0,})
		end

		CoreItem.addItems(items, item_list, user_info)

		local user_sync = CoreItem.makeSync(items, item_list, user_info)


		CoreItem.expendItems(use_items, item_list, user_info)

		user_sync = CoreItem.makeSync(use_items, item_list, user_info, user_sync)

		return 0, user_sync, get_item_list
	end

	local ret, user_sync, get_item_list = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
		get_item_list = get_item_list,
	}

	local resp_buff = Tools.encode("OpenGiftResp", resp)

	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()

	return resp_buff, user_info_buff, item_list_buff
end