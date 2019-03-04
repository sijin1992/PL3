local Bit = require "Bit"
local ChatLoger = require "ChatLoger"
function get_group_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 2, Tools.encode("GetGroupResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("GetGroupReq", req_buff)
		if req.groupid == "" then
			return datablock.group_main + datablock.try, user_name
		else
			return datablock.group_main + datablock.groupid, req.groupid
		end
	else
		error("something error");
	end
end

function get_group_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	local req = Tools.decode("GetGroupReq", req_buff)


	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local groupMain = require "UserGroup"
	groupMain:new(group_main_buff)
	local group_main = groupMain:getGroupMain()
	groupMain:setUserInfo(user_info)

	local resp

	if req.groupid == "" then

		if not group_main_buff then
			local resp =
			{
				result = 1,
			}
			local resp_buff = Tools.encode("GetGroupResp", resp)
			return resp_buff, user_info_buff
		end

		GroupCache.merge(group_main)
		GroupCache.update(group_main, user_info.user_name)

		resp =
		{
			result = 0,
			user_sync = {
				user_info = {
					group_data = user_info.group_data,
				},
				group_main = group_main,
			},
		}
	else
		local group_main = GroupCache.getGroupMain(req.groupid)
		
		if group_main == nil then
			local resp =
			{
				result = 2,
			}
			local resp_buff = Tools.encode("GetGroupResp", resp)
			return resp_buff, user_info_buff
		end
		local other_group_info = GroupCache.toOtherGroupInfo(group_main)
		resp =
		{
			result = 0,
			other_group_info = other_group_info,
		}
	end


	local resp_buff = Tools.encode("GetGroupResp", resp)
	user_info_buff = userInfo:getUserBuff()
	return resp_buff, user_info_buff, group_main_buff
end

--查询
function group_search_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 0, Tools.encode("GroupSearchResp", resp)
	else
		error("something error");
	end
end

function group_search_do_logic(req_buff, user_name)
	local req = Tools.decode("GroupSearchReq", req_buff)



	local group_list = GroupCache.search(req.groupid, req.group_name, req.page)

	local total_page
	if not req.groupid or req.groupid == "" or not req.group_name or req.group_name == "" then
		total_page = math.ceil(GroupCache.count() / GolbalDefine.group_num_in_page)
	else
		total_page = #group_list
	end

	local resp = {
		result = 0,
		group_list = group_list,
		total_page = total_page
	}
	local resp_buff = Tools.encode("GroupSearchResp", resp)
	return resp_buff
end


function create_group_feature(step, req_buff, user_name)
	if step == 0 then
		local req = Tools.decode("CreateGroupReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 2, Tools.encode("GetGroupResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.create, user_name
	else
		error("something error");
	end
end

function create_group_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	 local req = Tools.decode("CreateGroupReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()

	local groupMain = require "UserGroup"
	groupMain:new()
	groupMain:setUserInfo(user_info)

	local ret = groupMain:createGroup(req.nickname, req.icon_id)

	local group_main
	local group_data
	if ret == 0 then
		group_data = user_info.group_data

		group_main = groupMain:getGroupMain()

		user_info_buff = userInfo:getUserBuff()

		group_main_buff = groupMain:getGroupBuff()
	end

	local resp =
	{
		result = ret,
		user_sync = {
			user_info = {
				group_data = group_data,
			},
			group_main = group_main,
		},
	}


	local resp_buff = Tools.encode("CreateGroupResp", resp)

	return resp_buff, user_info_buff, group_main_buff
end

function group_join_condition_feature(step, req_buff, user_name )
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 2, Tools.encode("GroupJoinConditionResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error")
	end
end

function group_join_condition_do_logic( req_buff, user_name, user_info_buff, group_main_buff )
	local req = Tools.decode("GroupJoinConditionReq", req_buff)

	local userInfo = require "UserInfo"
	local groupMain = require "UserGroup"

	userInfo:new(user_info_buff)
	groupMain:new(group_main_buff)

	local user_info = userInfo:getUserInfo()
	local group_main = groupMain:getGroupMain()

	groupMain:setUserInfo(user_info)

	local condition = {
		needAllow = req.needAllow,
		level = req.level,
		power = req.power,
	}
	local ret = groupMain:setJoinCondition(condition)

	local resp =
	{
		result = ret,
		user_sync = {
			group_main = group_main,
		},
		
	}
	local resp_buff = Tools.encode("GroupJoinConditionResp", resp)
	user_info_buff = userInfo:getUserBuff()
	group_main_buff = groupMain:getGroupBuff()

	if ret == 0 then
		local multi_cast = groupMain:getMultiCast()
		local multi_buff = Tools.encode("Multicast", multi_cast)

		return resp_buff, user_info_buff, group_main_buff, 0x2100, multi_buff
	end

	return resp_buff, user_info_buff, group_main_buff
end

--申请
function group_join_req_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = "FAIL",
		}
		return 2, Tools.encode("GroupJoinResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("GroupJoinReq", req_buff)
		return datablock.group_main + datablock.save + datablock.groupid, req.groupid
	else
		error("something error")
	end
end

function group_join_req_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	local req = Tools.decode("GroupJoinReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local groupMain = require "UserGroup"
	groupMain:new(group_main_buff)
	local group_main = groupMain:getGroupMain()

	local function doLogic(  )
		if group_main_buff == nil then
			return "DATA_ERROR"
		end

		groupMain:setUserInfo(nil)
		if req.type == 1 or req.type == 3 then
	
			if user_info.group_data then
				local group_data = user_info.group_data
				if group_data.groupid ~= "" then
					if GroupCache.isDisband(group_data.groupid) then
						group_data = groupMain:resetGroupData(user_info)
						rawset(user_info, "group_data", group_data)
					end
				end
		
				if user_info.group_data.groupid ~= "" or user_info.group_data.status ~= 0 then
					return "HAS_GROUP"
				end
				-- if user_info.group_data.today_join_num ~= nil and user_info.group_data.today_join_num >= GolbalDefine.group_join_max_today then
				-- 	return "NO_NUMS"
				-- end
				-- if user_info.group_data.anti_time ~= nil and user_info.group_data.anti_time > os.time() then
				-- 	return "NO_TIME"
				-- end
	
			end

			if req.type == 3 then
				return groupMain:groupAllow(0,user_info, true)
			end

			if group_main.join_condition.needAllow == true then

				return groupMain:groupJoin(user_info)
			else

				return groupMain:groupAllow(0,user_info)
			end


		elseif req.type == 2 then

			return groupMain:groupUnjoin(user_info)

		end
		return "ERROR_TYPE"
	end

	local ret = doLogic()

	local resp =
	{
		result = ret,
		user_sync = {
			user_info = {
				group_data = user_info.group_data,
			},
			group_main = group_main,
		},
	}

	user_info_buff = userInfo:getUserBuff()

	group_main_buff = groupMain:getGroupBuff()

	local resp_buff = Tools.encode("GroupJoinResp", resp)

	if ret == "OK" then

		local user_update = {
			user_name = user_info.user_name,
			user_sync = {
				user_info = {
					group_data = user_info.group_data,
				}
			}
		}

		local multi_cast = groupMain:getMultiCast({user_update})

		local multi_buff = Tools.encode("Multicast", multi_cast)
	
		return resp_buff, user_info_buff, group_main_buff, 0x2100, multi_buff
	end

	return resp_buff, user_info_buff, group_main_buff
end

--批准
function group_allow_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = "FAIL",
		}
		return 3, Tools.encode("GroupAllowResp", resp)
	elseif step == 1 then
		return datablock.user_info, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	elseif step == 3 then
		local req = Tools.decode("GroupAllowReq", req_buff)
		return datablock.user_info + datablock.mail_list + datablock.save, req.username
	else
		error("something error");
	end
end

function group_allow_do_logic(req_buff, user_name, user_info_buff, group_main_buff, user_info_buff2, mail_list_buff2)

	local req = Tools.decode("GroupAllowReq", req_buff)


	local groupMain = require "UserGroup"
	groupMain:new(group_main_buff)
	local group_main = groupMain:getGroupMain()

	local user_info = Tools.decode("UserInfo",user_info_buff)
	local user_info2 = Tools.decode("UserInfo",user_info_buff2)

	local mailList2 = require "MailList"
	mailList2:new(mail_list_buff2)
	local mail_list2 = mailList2:getMailList()

	groupMain:setUserInfo(user_info)

	local ret
	if user_info.group_data and user_info.group_data.job < GolbalDefine.enum_group_job.member then
		ret = groupMain:groupAllow(req.type,user_info2)
	else
		ret = "DATA_ERROR"
	end

	
	local resp =
	{
		result = ret,
		user_sync = {
			group_main = group_main,
		},
	}

	local resp_buff = Tools.encode("GroupAllowResp", resp)
	user_info_buff = Tools.encode("UserInfo", user_info)
	group_main_buff = groupMain:getGroupBuff()
	user_info_buff2 = Tools.encode("UserInfo", user_info2)

	mail_list_buff2 = mailList2:getMailBuff() 

	if ret == "OK" then

		local user_update = {
			user_name = user_info2.user_name,
			user_sync = {
				user_info = {
					group_data = user_info2.group_data,
				}
			}
		}
		local multi_cast = groupMain:getMultiCast({user_update})
		local multi_buff = Tools.encode("Multicast", multi_cast)
		return resp_buff, user_info_buff, group_main_buff, user_info_buff2, mail_list_buff2, 0x2100, multi_buff
	end

	return resp_buff, user_info_buff, group_main_buff, user_info_buff2, mail_list_buff2
end

--退出公会
function group_exit_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 2, Tools.encode("GroupExitGroupResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_exit_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	local userInfo = require "UserInfo"
	local groupMain = require "UserGroup"

	userInfo:new(user_info_buff)
	groupMain:new(group_main_buff)

	local user_info = userInfo:getUserInfo()
	local group_main = groupMain:getGroupMain()

	groupMain:setUserInfo(user_info)

	local ret,multi_cast = groupMain:groupExit( user_info)

	local resp = {
		result = ret,
		user_sync = {
			user_info = {
				group_data = user_info.group_data,
			},
		},
	}
	local resp_buff= Tools.encode("GroupExitGroupResp", resp)

	user_info_buff = userInfo:getUserBuff()
	group_main_buff = groupMain:getGroupBuff()

	if ret == 0 then
		if multi_cast then

			local multi_buff = Tools.encode("Multicast", multi_cast)
			return resp_buff, user_info_buff, group_main_buff, 0x2100, multi_buff
		end
	end

	return resp_buff, user_info_buff, group_main_buff
end


--踢出公会
function group_kick_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 3, Tools.encode("GroupKickResp", resp)
	elseif step == 1 then
		return datablock.main_data, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	elseif step == 3 then

		local req = Tools.decode("GroupKickReq", req_buff)
		return datablock.main_data + datablock.mail_list + datablock.save, req.user_name
	else
		error("something error");
	end
end

function group_kick_do_logic(req_buff, user_name, user_info_buff, group_main_buff, user_info_buff2, mail_buff2)

	local req = Tools.decode("GroupKickReq", req_buff)
	local user_info = Tools.decode("UserInfo", user_info_buff)

	local user_info2 = Tools.decode("UserInfo", user_info_buff2)
	local mail_list2 = Tools.decode("MailList", mail_buff2)


	local groupMain = require "UserGroup"
	groupMain:new(group_main_buff)

	local group_main = groupMain:getGroupMain()
	groupMain:setUserInfo(user_info)


	if not rawget(mail_list2, "mail_list") then mail_list2 = {mail_list = {}} end

	local ret,multi_cast = groupMain:groupKick(user_info2, mail_list2.mail_list)

	local resp = {
		result = ret,
		req = req,
		user_sync = {
			group_main = group_main,
		},
	}
	local resp_buff = Tools.encode("GroupKickResp", resp)

	group_main_buff = groupMain:getGroupBuff()

	user_info_buff = Tools.encode("UserInfo", user_info)
	user_info_buff2 = Tools.encode("UserInfo", user_info2)

	mail_buff2 = Tools.encode("MailList", mail_list2)

	if ret == "OK" then
		if multi_cast then
			local mail_update = CoreMail.getMultiCast(user_info2.user_name)
			local mail_update_buff = Tools.encode("Multicast", mail_update)

			local multi_buff = Tools.encode("Multicast", multi_cast)
			return resp_buff, user_info_buff, group_main_buff, user_info_buff2, mail_buff2, 0x2100, multi_buff, 0x2100, mail_update_buff
		end
	end

	return resp_buff, user_info_buff, group_main_buff, user_info_buff2, mail_buff2
end


--指定职位
function group_job_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 3, Tools.encode("GroupJobResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	elseif step == 3 then

		local req = Tools.decode("GroupJobReq", req_buff)
		return datablock.main_data + datablock.save, req.user_name
	else
		error("something error");
	end
end

function group_job_do_logic(req_buff, user_name, user_info_buff, group_main_buff, user_info_buff2)

	local pb = require "protobuf"

	local req = pb.decode("GroupJobReq", req_buff)

	local user_info = pb.decode("UserInfo", user_info_buff)
	SyncUserCache.sync(user_info)
	local user_info2 = pb.decode("UserInfo", user_info_buff2)
	SyncUserCache.sync(user_info2)
	
	local groupMain = require "UserGroup"
	groupMain:new(group_main_buff)

	local group_main = groupMain:getGroupMain()
	groupMain:setUserInfo(user_info)

	local ret, multi_cast = groupMain:groupJob( req.job, user_info2 )
	local job = user_info2.group_data.job
	local resp = {
		result = ret,
		user_sync = {
			group_main = group_main,
		},
	}
	
	user_info_buff = pb.encode("UserInfo", user_info)
	user_info_buff2 = pb.encode("UserInfo", user_info2)
	--BUG：任命理事的时候会无法设置成2 所以用这个方法解决
	user_info2.group_data.job = job
	user_info_buff2 = pb.encode("UserInfo", user_info2)
	--


	local resp_buff = pb.encode("GroupJobResp", resp)
	group_main_buff = groupMain:getGroupBuff()

	if ret == "OK" then
		if multi_cast then
			local multi_buff = pb.encode("Multicast", multi_cast)
			return resp_buff, user_info_buff, group_main_buff, user_info_buff2, 0x2100, multi_buff
		end
	end

	return resp_buff, user_info_buff, group_main_buff, user_info_buff2
end

--解散星盟
function group_disband_feature(step, req_buff, user_name)
	if step == 0 then

		local resp = {
			result = "FAIL",
		}
		return 2, Tools.encode("GroupDisbandResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_disband_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	local userInfo = require "UserInfo"
	local groupMain = require "UserGroup"

	userInfo:new(user_info_buff)
	groupMain:new(group_main_buff)

	local user_info = userInfo:getUserInfo()
	local group_main = groupMain:getGroupMain()

	groupMain:setUserInfo(user_info)

	local ret,multi_cast = groupMain:groupDisband()

	local resp = {
		result = ret,
		user_sync = {
			user_info = {
				group_data = user_info.group_data,
			},
			group_main = group_main,
		},
	}

	local resp_buff = Tools.encode("GroupDisbandResp", resp)

	group_main_buff = groupMain:getGroupBuff()

	user_info_buff = Tools.encode("UserInfo", user_info)

	if ret == "OK" then

		local multi_buff = Tools.encode("Multicast", multi_cast)
		return resp_buff, user_info_buff, group_main_buff, 0x2100, multi_buff
	end

	return resp_buff, user_info_buff, group_main_buff
end


--门派公告
function group_broadcast_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 2, Tools.encode("GroupBroadcastResp", resp)
	elseif step == 1 then
		return datablock.main_data, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_broadcast_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	local req = Tools.decode("GroupBroadcastReq", req_buff)

	local userInfo = require "UserInfo"
	local groupMain = require "UserGroup"

	userInfo:new(user_info_buff)
	groupMain:new(group_main_buff)

	local user_info = userInfo:getUserInfo()
	local group_main = groupMain:getGroupMain()

	groupMain:setUserInfo(user_info)

	local ret = groupMain:broadcast(req.blurb, req.broadcast)

	local resp = {
		result = ret,
		user_sync = {
			group_main = group_main,
		},
	}

	local resp_buff = Tools.encode("GroupBroadcastResp", resp)

	user_info_buff = userInfo:getUserBuff()
	group_main_buff = groupMain:getGroupBuff()

	if ret == "OK" then
		local multi_cast = groupMain:getMultiCast()
		local multi_buff = Tools.encode("Multicast", multi_cast)
		return resp_buff, user_info_buff, group_main_buff, user_info_buff2, mail_buff2, 0x2100, multi_buff
	end

	return resp_buff, user_info_buff, group_main_buff
end

--贡献
function group_contribute_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 2, Tools.encode("GroupContributeResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.item_list + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_contribute_do_logic(req_buff, user_name, user_info_buff, item_list_buff, group_main_buff)

	local req = Tools.decode("GroupContributeReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	local groupMain = require "UserGroup"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	groupMain:new(group_main_buff)
	local user_info = userInfo:getUserInfo()
	local group_main = groupMain:getGroupMain()
	local item_list = itemList:getItemList()
	groupMain:setUserInfo(user_info)
	groupMain:setItemList(item_list)

	local ret, user_sync = groupMain:groupContribute(req.type, req.tech_id)

	user_sync = user_sync or {}
	user_sync.user_info = user_sync.user_info or {}

	local achievement_data = userInfo:getAchievementData()
	if req.type > 0 and ret == 0 then
		 if achievement_data.contribute_times == nil then
			achievement_data.contribute_times = 1
		else
			achievement_data.contribute_times = achievement_data.contribute_times + 1
		end

		--更新每日数据
		local daily_data = CoreUser.getDailyData(user_info)
		if not daily_data.contribute_times then
			daily_data.contribute_times = 1
		else
			daily_data.contribute_times = daily_data.contribute_times + 1
		end
		user_sync.user_info.daily_data = daily_data
		--更新活动数据
		local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
		if activity_list then
			user_sync.activity_list = {}
			for i,v in ipairs(activity_list) do
				local count = v.seven_days_data.contribute_times or 0
				v.seven_days_data.contribute_times = count + 1
				table.insert(user_sync.activity_list, v)
			end
		end
	end

	user_sync.user_info.group_data = user_info.group_data
	user_sync.user_info.achievement_data = user_info.achievement_data
	user_sync.group_main = group_main

	local resp =
	{
		result = ret,
		user_sync = user_sync,
	}



	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	group_main_buff = groupMain:getGroupBuff()

	local resp_buff = Tools.encode("GroupContributeResp", resp)

	if ret == 0 then
		local multi_cast = groupMain:getMultiCast()
		local multi_buff = Tools.encode("Multicast", multi_cast)

		return resp_buff, user_info_buff, item_list_buff, group_main_buff, 0x2100, multi_buff
	end

	return resp_buff, user_info_buff, item_list_buff, group_main_buff
end

--重置贡献锁
function group_contribute_cd_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("GroupContributeCDResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	else
		error("something error");
	end
end

function group_contribute_cd_do_logic( req_buff, user_name, user_info_buff )
	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local function doLogic(  )
		if user_info.group_data.groupid == "" then
			return 1
		end

		if user_info.group_data.contribute_locker == false then
			return 2
		end

		local time = user_info.group_data.contribute_end_cd - os.time()

		local need = Tools.getSpeedUpNeedMoney(time)

		if CoreItem.checkMoney(user_info, need) == false then
			return 3
		end
		CoreItem.expendMoney(user_info, need , CONF.EUseMoney.eGroup_contribute_cd)

		user_info.group_data.contribute_end_cd = 0
		user_info.group_data.contribute_locker = false

		local user_sync = {
			user_info = {
				group_data = user_info.group_data,
				money = user_info.money,
			}
		}

		return 0, user_sync
	end

	local ret, user_sync = doLogic()

	local resp =
	{
		result = ret,
		user_sync = user_sync,
	}
	local resp_buff = Tools.encode("GroupContributeCDResp", resp)
	user_info_buff = userInfo:getUserBuff()

	return resp_buff, user_info_buff
end

--科技升级
function group_tech_levelup_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 2, Tools.encode("GroupTechLevelupResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_tech_levelup_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	local req = Tools.decode("GroupTechLevelupReq", req_buff)

	local userInfo = require "UserInfo"

	local groupMain = require "UserGroup"
	userInfo:new(user_info_buff)
	groupMain:new(group_main_buff)

	local user_info = userInfo:getUserInfo()

	groupMain:setUserInfo(user_info)

	local ret = groupMain:groupTechLevelup(req.tech_id)

	local resp =
	{
		result = ret,
		user_sync = {
			group_main = groupMain:getGroupMain(),
		},
	}

	user_info_buff = userInfo:getUserBuff()

	group_main_buff = groupMain:getGroupBuff()

	local resp_buff = Tools.encode("GroupTechLevelupResp", resp)

	if ret == 0 then
		local multi_cast = groupMain:getMultiCast()
		local multi_buff = Tools.encode("Multicast", multi_cast)

		return resp_buff, user_info_buff, group_main_buff, 0x2100, multi_buff
	end

	return resp_buff, user_info_buff, group_main_buff
end

--获取科技信息
function group_get_tech_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 2, Tools.encode("GroupGetTechResp", resp)
	elseif step == 1 then
		return datablock.user_info + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_get_tech_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	local req = Tools.decode("GroupGetTechReq", req_buff)

	local userInfo = require "UserInfo"

	local groupMain = require "UserGroup"
	userInfo:new(user_info_buff)
	groupMain:new(group_main_buff)

	local user_info = userInfo:getUserInfo()
	local group_main = groupMain:getGroupMain()

	groupMain:setUserInfo(user_info)


	local group_tech = groupMain:getTechnology(req.tech_id)

	-- if group_tech then
	--     group_tech.begin_upgrade_time = 0
	--     groupMain:removeTechnology(req.tech_id - 1)
	-- end

	GroupCache.update(group_main, user_name)

	local ret = 0
	if group_tech == nil then
		ret = 1
	end 

	local resp =
	{
		result = ret,
		user_sync = {
			group_main = (ret == 0 and group_main or nil),
		},
		group_tech = group_tech,
	}

	user_info_buff = userInfo:getUserBuff()

	group_main_buff = groupMain:getGroupBuff()

	local resp_buff = Tools.encode("GroupGetTechResp", resp)

	if ret == 0 then
		local multi_cast = groupMain:getMultiCast()
		local multi_buff = Tools.encode("Multicast", multi_cast)

		return resp_buff, user_info_buff, group_main_buff, 0x2100, multi_buff
	end

	return resp_buff, user_info_buff, group_main_buff
end


--公会升级
function group_levelup_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 2, Tools.encode("GroupLevelupResp", resp)
	elseif step == 1 then
		return datablock.main_data, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_levelup_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	local userInfo = require "UserInfo"

	local groupMain = require "UserGroup"
	userInfo:new(user_info_buff)
	groupMain:new(group_main_buff)

	local user_info = userInfo:getUserInfo()
	local group_main = groupMain:getGroupMain()

	groupMain:setUserInfo(user_info)

	local ret = groupMain:groupLevelup()

	local resp =
	{
		result = ret,
		user_sync = {
			group_main = (ret == 0 and group_main or nil),
		},
	}

	if group_main.level >= CONF.PARAM.get("broadcast_league_lv").PARAM then

		for i,v in ipairs(group_main.user_list) do
			if v.job == 1 then
				--发送广播
				local msg = string.format(Lang.group_level_board_msg, v.nickname, group_main.nickname, group_main.level)
				sendBroadcast(user_info.user_name, Lang.world_chat_sender, msg)
				--保存记录
				ChatLoger.pushLog(0, msg, Lang.world_chat_sender)
				break
			end
		end
		
	end


	user_info_buff = userInfo:getUserBuff()
	group_main_buff = groupMain:getGroupBuff()

	local resp_buff = Tools.encode("GroupLevelupResp", resp)

	if ret == 0 then
		local multi_cast = groupMain:getMultiCast()
		local multi_buff = Tools.encode("Multicast", multi_cast)

		return resp_buff, user_info_buff, group_main_buff, 0x2100, multi_buff
	end

	return resp_buff, user_info_buff, group_main_buff
end

--公会PVE
function group_pve_get_info_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("GroupPVEGetInfoResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.save, user_name
	else
		error("something error");
	end
end

function group_pve_get_info_do_logic(req_buff, user_name, user_info_buff, ship_list_buff)

	local req = Tools.decode("GroupPVEGetInfoReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()

	shipList:setUserInfo(user_info)

	local function doLogic( req )

		if Tools.isEmpty(user_info.group_data) == true then
			return "NO_GROUP"
		end
		if user_info.group_data.groupid == nil or user_info.group_data.groupid == "" then
			return "NO_GROUP"
		end


		local group_boss_info
		if Tools.isEmpty(user_info.group_data.pve_checkpoint_list) == false then
			for i,v in ipairs(user_info.group_data.pve_checkpoint_list) do
				if v.group_boss_id == req.group_boss_id then
					group_boss_info = v
				end
			end
		end

		--添加数据
		if not group_boss_info then

			local bossConf = CONF.GROUP_BOSS.get(req.group_boss_id)
			local checkpointConf = CONF.GROUP_CHECKPOINT.get(bossConf.GROUP_CHECKPOINT_ID)


			local hurter_hp_list = {0,0,0,0,0,0,0,0,0}
			local lineup_monster = checkpointConf.MONSTER_LIST
			local big_ship = 0
			for k,v in ipairs(lineup_monster) do

				local ship_id = 0
				if v > 0 then
					ship_id = v
				end
				if v < 0 and big_ship == 0 then
					ship_id = math.abs(v)
					big_ship = 1
	            			end

				if ship_id > 0 then
					local ship_info = shipList:createMonster(ship_id)
					hurter_hp_list[k] = ship_info.attr[CONF.EShipAttr.kHP]
				end
	        		end

		
			local reward_list = {}
			for i,v in ipairs(bossConf.DAMAGE) do
				table.insert(reward_list, false)
			end
			group_boss_info = {
				group_boss_id = req.group_boss_id,
				hurter_hp_list = hurter_hp_list,
				damage = 0,
				challenge_times = bossConf.TIME_1,
				buy_challenge_times = 0,
				get_reward_list = reward_list,
			}

			if Tools.isEmpty(user_info.group_data.pve_checkpoint_list) == false then
				table.insert(user_info.group_data.pve_checkpoint_list, group_boss_info)
			else
				user_info.group_data.pve_checkpoint_list = {group_boss_info}
			end
		end

		local user_sync = {
			user_info = {
				group_data = user_info.group_data
			}
		}

		return "OK", group_boss_info, user_sync
	end


	local ret, group_boss_info, user_sync = doLogic(req)
	local resp =
	{
		result = ret,
		user_sync = user_sync,
		info = group_boss_info,
	}

	local resp_buff = Tools.encode("GroupPVEGetInfoResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	return resp_buff, user_info_buff, ship_list_buff
end


function group_pve_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 2, Tools.encode("GroupPVEResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_pve_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, group_main_buff)

	local req = Tools.decode("GroupPVEReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local groupMain = require "UserGroup"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	groupMain:new(group_main_buff)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()
	local group_main = groupMain:getGroupMain()

	shipList:setUserInfo(user_info)
	groupMain:setUserInfo(user_info)
	
	local attack_list = {}
	local hurter_list = {}

	local function doLogic( req )

		if Tools.isEmpty(user_info.group_data) == true then
			return "NO_GROUP"
		end
		if user_info.group_data.groupid == nil or user_info.group_data.groupid == "" then
			return "NO_GROUP"
		end


		GroupCache.merge(group_main)

		local bossConf = CONF.GROUP_BOSS.get(req.group_boss_id)
		if bossConf.LEVEL > group_main.level then
			return "GROUP_LEVEL"
		end
		local cur_time = os.time()

		local date = os.date("*t", cur_time)
		if date.wday ~= bossConf.OPEN then
			return "WDAY"
		end

		local start_time = os.time({year = date.year, month = date.month, day = date.day, hour = bossConf.START_TIME})
		local end_time = start_time + bossConf.END_TIME

		if cur_time < start_time or cur_time > end_time then
			return "TIME_OUT"
		end

		local group_boss_info
		--是否存在数据
		if Tools.isEmpty(user_info.group_data.pve_checkpoint_list) == false then
			for i,v in ipairs(user_info.group_data.pve_checkpoint_list) do
				if v.group_boss_id == req.group_boss_id then
					group_boss_info = v
				end
			end
		end
		if not group_boss_info then
			return "NO_DATA"
		end

		--检查次数
		if group_boss_info then
			if group_boss_info.challenge_times < 1 then
				return "CHALLENGE_TIMES"
			end
			local alive = false
			for i,v in ipairs(group_boss_info.hurter_hp_list) do
				if v > 0 then
					alive = true
					break
				end
			end
			if alive == false then
				return "DEAD"
			end
		end

		--检查体力
		local checkpointConf = CONF.GROUP_CHECKPOINT.get(bossConf.GROUP_CHECKPOINT_ID)
		if user_info.strength - checkpointConf.STRENGTH < 0 then
			return "NO_STRENGTH"
		end


		--添加攻击队列
		attack_list = shipList:getShipByLineup()
		for i,v in ipairs(attack_list) do
			if Tools.checkShipDurable(v) == false then
				return "NO_DURABEL"
			end
			if Bit:has(v.status, CONF.EShipState.kFix) == true then
				return "SHIP_FIXING"
			end
			if Bit:has(v.status, CONF.EShipState.kOuting) == true then
				return "SHIP_OUTING"
			end
		end
		for i=1,#attack_list do
          			
			attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true)
			attack_list[i].body_position = {attack_list[i].position}
		end


		

		--添加防守方队列
		local lineup_monster = checkpointConf.MONSTER_LIST
		local big_ship = 0

		for k,v in ipairs(lineup_monster) do
			local bodyPositions = {}
			local ship_id = 0
			if v > 0 then
				ship_id = v
				table.insert(bodyPositions, k)
			end
			if v < 0 and big_ship == 0 then
				ship_id = math.abs(v)
				for pos,id in ipairs(lineup_monster) do
					if id == v then
						table.insert(bodyPositions, pos)
					end
				end
				big_ship = 1
            			end

			if ship_id > 0 then
				local ship_info = shipList:createMonster(ship_id)
				ship_info.position = k
				ship_info.body_position = bodyPositions
				table.insert(hurter_list, ship_info)
			end
        		end

		--扣除体力
            		local strength = userInfo:removeStrength(checkpointConf.STRENGTH)

            		--扣除次数
            		if group_boss_info.challenge_times > 0 then
            			group_boss_info.challenge_times = group_boss_info.challenge_times - 1
            		end

		local user_sync = {
			user_info = {
				strength = strength,
				group_data = user_info.group_data,
			},
		}

		return "OK", group_boss_info.hurter_hp_list, user_sync
	end

	local ret, hurter_hp_list, user_sync = doLogic(req)
	local resp =
	{
		result = ret,
		user_sync = user_sync,
		attack_list = attack_list,
		hurter_list = hurter_list,
		hurter_hp_list = hurter_hp_list,
		group_boss_id = req.group_boss_id,
	}

	local resp_buff = Tools.encode("GroupPVEResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	group_main_buff = groupMain:getGroupBuff()
	return resp_buff, user_info_buff, ship_list_buff, group_main_buff
end



function group_pve_ok_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 2, Tools.encode("GroupPVEOKResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_pve_ok_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, group_main_buff)

	local req = Tools.decode("GroupPVEOKReq", req_buff)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local groupMain = require "UserGroup"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	groupMain:new(group_main_buff)

	local user_info = userInfo:getUserInfo()
	local ship_list = shipList:getShipList()
	local group_main = groupMain:getGroupMain()

	shipList:setUserInfo(user_info)
	groupMain:setUserInfo(user_info)
	
	local function doLogic( req )
		local bossConf = CONF.GROUP_BOSS.get(req.group_boss_id)

		if Tools.isEmpty(user_info.group_data) == true then
			return "NO_GROUP"
		end
		if user_info.group_data.groupid == nil or user_info.group_data.groupid == "" then
			return "NO_GROUP"
		end

		if req.result <0 and req.result > 2 then
			return "ERROR_RESULT"
		end
		
		--是否存在数据
		if Tools.isEmpty(user_info.group_data.pve_checkpoint_list) == true then
			return "NO_DATA"
		end
		local group_boss_info
		for i,v in ipairs(user_info.group_data.pve_checkpoint_list) do
			if v.group_boss_id == req.group_boss_id then
				group_boss_info = v
			end
		end
		if group_boss_info == nil then
			return "NO_DATA"
		end

		--检查 req hurter_hp_list
		local count = #req.hurter_hp_list
		if count ~= 9 then
			return "HP_LIST_ERROR0"
		end
		if req.result == 1 then
			for i=1,count do
				if req.hurter_hp_list[i] > 0 then
					return "HP_LIST_ERROR1"
				end
			end
		end

		local damage = 0
		for i,v in ipairs(group_boss_info.hurter_hp_list) do
			if req.hurter_hp_list[i] > v then
				req.hurter_hp_list[i] = v
			end
			damage = damage + (v - req.hurter_hp_list[i])

			group_boss_info.hurter_hp_list[i] = req.hurter_hp_list[i]
		end
		group_boss_info.damage = group_boss_info.damage + damage

		local user_sync = {
			user_info = {
				group_data = user_info.group_data,
			},
		}
		shipList:subLineupDurable(1, req.result, user_sync)

		--更新每日数据
		local daily_data = CoreUser.getDailyData(user_info)
		if not daily_data.group_boss_times then
			daily_data.group_boss_times = 1
		else
			daily_data.group_boss_times = daily_data.group_boss_times + 1
		end
		user_sync.user_info.daily_data = daily_data

		return "OK", user_sync
	end

	local ret, user_sync = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
	}

	local resp_buff = Tools.encode("GroupPVEOKResp", resp)
	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	group_main_buff = groupMain:getGroupBuff()
	return resp_buff, user_info_buff, ship_list_buff, group_main_buff
end


function group_pve_add_times_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 1, Tools.encode("GroupPVEAddTimsResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function group_pve_add_times_do_logic(req_buff, user_name, user_info_buff)

	local req = Tools.decode("GroupPVEAddTimsReq", req_buff)

	local userInfo = require "UserInfo"

	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()

	local function doLogic( req )
		
		if Tools.isEmpty(user_info.group_data) == true then
			return "NO_GROUP"
		end
		if user_info.group_data.groupid == nil or user_info.group_data.groupid == "" then
			return "NO_GROUP"
		end

		local group_boss_info
		--是否存在数据
		if Tools.isEmpty(user_info.group_data.pve_checkpoint_list) == false then
			for i,v in ipairs(user_info.group_data.pve_checkpoint_list) do
				if v.group_boss_id == req.group_boss_id then
					group_boss_info = v
				end
			end
		end
		if not group_boss_info then
			return "NO_DATA"
		end

		local bossConf = CONF.GROUP_BOSS.get(req.group_boss_id)
		if req.times <= 0 then
			return "ERROR_TIMES"
		end

		local addedTimes = group_boss_info.buy_challenge_times + req.times

		if addedTimes > bossConf.TIME_2 then
			return "MAX_TIMES"
		end

		local needMoney = 0
		local priceCount = #bossConf.PRICE
		for i = group_boss_info.buy_challenge_times + 1, addedTimes do
			if bossConf.PRICE[i] then
				needMoney = needMoney + bossConf.PRICE[i]
			else
				needMoney = needMoney + bossConf.PRICE[priceCount]
			end
		end

		if CoreItem.checkMoney(user_info, needMoney) == false then

			return "NO_MONEY"
		end

		CoreItem.expendMoney(user_info, needMoney, CONF.EUseMoney.eGroup_pve)

		group_boss_info.buy_challenge_times = addedTimes

		group_boss_info.challenge_times = group_boss_info.challenge_times + req.times

		local user_sync = {
			user_info = {
				money = user_info.money,
				group_data = user_info.group_data,
			}
		}
		return "OK", user_sync
	end

	local ret, user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
		req = req,
	}

	local resp_buff = Tools.encode("GroupPVEAddTimsResp", resp)
	user_info_buff = userInfo:getUserBuff()

	return resp_buff, user_info_buff
end

function group_pve_reward_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 2, Tools.encode("GroupPVERewardResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_list + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end


function group_pve_reward_do_logic(req_buff, user_name, user_info_buff, item_list_buff, group_main_buff)

	local req = Tools.decode("GroupPVERewardReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"

	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local groupMain = require "UserGroup"
	groupMain:new(group_main_buff)
	local group_main = groupMain:getGroupMain()

	groupMain:setUserInfo(user_info)

	GroupCache.merge(group_main)

	local function doLogic( req )

		if Tools.isEmpty(user_info.group_data) == true then
			return "NO_GROUP"
		end
		if user_info.group_data.groupid == nil or user_info.group_data.groupid == "" then
			return "NO_GROUP"
		end

		local group_boss_info
		--是否存在数据
		if Tools.isEmpty(user_info.group_data.pve_checkpoint_list) == false then
			for i,v in ipairs(user_info.group_data.pve_checkpoint_list) do
				if v.group_boss_id == req.group_boss_id then
					group_boss_info = v
				end
			end
		end
		if not group_boss_info then
			return "NO_DATA"
		end
		local bossConf = CONF.GROUP_BOSS.get(req.group_boss_id)
		if bossConf.DAMAGE[req.reward_index] == nil then
			return "NO_INDEX"
		end

		if group_boss_info.damage < bossConf.DAMAGE[req.reward_index] then
			return "SMALL_DAMAGE"
		end

		local item_id = bossConf[string.format("DAMAGE_REWARD_%d",req.reward_index)]
		local item_num = bossConf[string.format("DAMAGE_REWARD_NUM_%d",req.reward_index)]
		if item_id == "" or item_id == nil or item_num == "" or item_num == nil then
			return "NO_INDEX_DATA"
		end

		local rewardCount = #group_boss_info.get_reward_list
		if rewardCount < req.reward_index then
			for i=rewardCount,req.reward_index do
				table.insert(group_boss_info.get_reward_list, false)
			end
		end
		if group_boss_info.get_reward_list[req.reward_index] == true then
			return "GETTED"
		end
		group_boss_info.get_reward_list[req.reward_index] = true

		local items = {}
		for i,v in ipairs(item_id) do
			items[v] = item_num[i] + math.floor(Tools.getValueByTechnologyAddition(item_num[i], CONF.ETechTarget_1.kGroup, 0, CONF.ETechTarget_3_Group.kBossReward, nil, group_main.tech_list), PlanetCache.GetTitleTech(user_name))
		end

		CoreItem.addItems(items, item_list, user_info)

		local user_sync = CoreItem.makeSync(items, item_list, user_info)

		user_sync.user_info.group_data = user_info.group_data

		return "OK", user_sync
	end

	local ret,user_sync = doLogic(req)

	local resp = {
		result = ret,
		user_sync = user_sync,
		req = req,
	}

	local resp_buff = Tools.encode("GroupPVERewardResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	group_main_buff = groupMain:getGroupBuff()
	return resp_buff, user_info_buff, item_list_buff, group_main_buff
end

function group_request_help_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 2, Tools.encode("GroupRequestHelpResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_request_help_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	local req = Tools.decode("GroupRequestHelpReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local groupMain = require "UserGroup"
	groupMain:new(group_main_buff)
	local group_main = groupMain:getGroupMain()
	groupMain:setUserInfo(user_info)

	local function doLogic( req )

		GroupCache.merge(group_main)

		if req.id[1] == nil or req.id[1] <= 0 then
			return "REQ_DATA_ERROR"
		end

		if req.type == CONF.EGroupHelpType.kBuilding then

			local building_info = userInfo:getBuildingInfo(req.id[1])
			if not building_info then
				return "NO_DATA"
			end

			if building_info.upgrade_begin_time <= 0 then
				return "NO_CD"
			end
			if building_info.helped == true then
				return "HELPED"
			end
		elseif req.type == CONF.EGroupHelpType.kTechnology then
	
			local tech_data = userInfo:getTechnologyInfo()
			if not tech_data then
				return "NO_DATA"
			end
			if tech_data.upgrade_busy <= 0 or tech_data.tech_id ~= req.id[1] then
				return "NO_CD"
			end
			local tech_info = userInfo:getTechnologyInfoByID(req.id[1])
			if tech_info.helped == true then
				return "HELPED"
			end
		elseif req.type == CONF.EGroupHelpType.kHome then
			if req.id[2] == nil or req.id[2] <= 0 then
				return "REQ_DATA_ERROR"
			end
			local land_info = userInfo:getHomeLandList()
			local info
			for i,v in ipairs(land_info) do
				if v.land_index == req.id[1] then
					info = v
					break
				end
			end
			if info then
				if info.resource_status ~= 1 or info.res_refresh_times <= 0 then
					return "NO_CD"
				end
				if info.helped == true then
					return "HELPED"
				end
			end
		end

		if Tools.isEmpty(group_main.help_list) == false then
			local has = false
			for i,v in ipairs(group_main.help_list) do
				if user_info.user_name == v.user_name then
					if req.type == v.type and req.id[1] == v.id[1] then
						has = true
					end
				end
			end
			if has == true then
				return "REQUESTED"
			end
		end

		local groupConf = CONF.GROUP.get(group_main.level)
		local building_13_info = CoreUser.getBuildingInfo( CONF.EBuilding.kDiplomacy, user_info )
		local building_addition = 0
		if building_13_info then
			building_addition = CONF.BUILDING_13.get(building_13_info.level).HELP_TIMES
		end

		local max_help_times = groupConf.HELP_TIME + building_addition + Tools.getValueByTechnologyAddition(groupConf.HELP_TIME, CONF.ETechTarget_1.kGroup, 0, CONF.ETechTarget_3_Group.kBeHelpTimes, nil, group_main.tech_list, PlanetCache.GetTitleTech(user_name))
		max_help_times = math.floor(max_help_times)

		local info = {
			user_name = user_info.user_name,
			type = req.type,
			id = req.id,
			max_help_times = max_help_times,
		}

		if Tools.isEmpty(group_main.help_list) == false then
			table.insert(group_main.help_list, info)
		else
			group_main.help_list = {info}
		end


		if req.id[1] == nil or req.id[1] <= 0 then
			return "REQ_DATA_ERROR"
		end

		if req.type == CONF.EGroupHelpType.kBuilding then

			local building_info = userInfo:getBuildingInfo(req.id[1])
			building_info.helped = true

		elseif req.type == CONF.EGroupHelpType.kTechnology then
	
			local tech_info = userInfo:getTechnologyInfoByID(req.id[1])
			tech_info.helped = true
		elseif req.type == CONF.EGroupHelpType.kHome then

			local land_info = userInfo:getHomeLandList()
			local info
			for i,v in ipairs(land_info) do
				if v.land_index == req.id[1] then
					info = v
					break
				end
			end
			if info then
				info.helped = true
			end
		end

		GroupCache.update(group_main, user_info.user_name)

		return "OK"
	end

	local function autohelp(req)

		local user_sync2 
		local time = os.time()
		local helpConf = CONF.GROUP_HELP.get(req.type)
		local auto_time = CONF.PARAM.get("auto_help_time").PARAM
		if req.type == CONF.EGroupHelpType.kBuilding then
			local building_info = userInfo:getBuildingInfo(req.id[1])
			if not building_info then
				return
			end
			if building_info.upgrade_begin_time <= 0 then
				table.remove(group_main.help_list, help_info_index)
				return
			end
			
			if building_info.upgrade_begin_time - time > auto_time then
				return
			end

			local cd = userInfo:getBuildingCDTime( req.id[1], building_info, true )

			local sub_value = helpConf.CD_SEC + cd * 0.01 * helpConf.CD_PER

			building_info.upgrade_begin_time = building_info.upgrade_begin_time - sub_value

			user_sync2 = {
				user_info = {
					building_list = user_info.building_list,
					group_data = user_info.group_data,
				}
			}

		elseif req.type == CONF.EGroupHelpType.kTechnology then
			local tech_data = userInfo:getTechnologyInfo()
			if not tech_data then
				return
			end
			local tech_info = userInfo:getTechnologyInfoByID(req.id[1])
			if not tech_info then
				return
			end
			if tech_data.upgrade_busy <= 0 or tech_info.tech_id ~= req.id[1] then
				table.remove(group_main.help_list, help_info_index)
				return
			end

			if tech_info.begin_upgrade_time - time > auto_time then
				return
			end

			local cd = userInfo:getTechnologyCDTime(req.id[1], true)

			local sub_value = helpConf.CD_SEC + cd * 0.01 * helpConf.CD_PER

			tech_info.begin_upgrade_time = tech_info.begin_upgrade_time - sub_value

			user_sync2 = {
				user_info = {
					tech_data = user_info.tech_data,
					group_data = user_info.group_data,
				}
			}
		elseif req.type == CONF.EGroupHelpType.kHome then

			if req.id[2] == nil or req.id[2] <= 0 then
				return
			end

			local land_info = userInfo:getHomeLandList()
			local info
			for i,v in ipairs(land_info) do
				if v.land_index == req.id[1] then
					info = v
					break
				end
			end
			if info.resource_status ~= 1 or info.res_refresh_times <= 0 then
				table.remove(group_main.help_list, help_info_index)
				return 
			end
			if info.res_refresh_times - time > auto_time then
				return
			end

			local cd = userInfo:getHomeBuildingCDTime(info.resource_type, true)

			local sub_value = helpConf.CD_SEC + cd * 0.01 * helpConf.CD_PER

			info.res_refresh_times =  info.res_refresh_times - sub_value

			user_sync2 = {
				user_info = {
					home_info = user_info.home_info,
					group_data = user_info.group_data,
				}
			}

		end

		if user_info.group_data.help_times ~= nil then
			user_info.group_data.help_times = 1
		else
			user_info.group_data.help_times = user_info.group_data.help_times + 1
		end
		
		--更新每日数据
		local daily_data = CoreUser.getDailyData(user_info)
		if not daily_data.help_times then
			daily_data.help_times = 1
		else
			daily_data.help_times = daily_data.help_times + 1
		end


		local user_update = {
			user_name = user_info.user_name,
			user_sync = user_sync2
		}
		local multi_cast = groupMain:getMultiCast({user_update})

		local multi_buff = Tools.encode("Multicast", multi_cast)

		activeSendMessage(user_info.user_name, 0x2100, multi_buff)
	end
	
	local ret = doLogic(req)
	local resp = {
		result = ret,
		help_list = group_main.help_list,
	}

	if ret == "OK" then
		autohelp(req)
	end

	local resp_buff = Tools.encode("GroupRequestHelpResp", resp)
	user_info_buff = userInfo:getUserBuff()
	group_main_buff = groupMain:getGroupBuff()


	if ret == "OK" then
	
		local multi_cast = groupMain:getMultiCast()

		local multi_buff = Tools.encode("Multicast", multi_cast)

		return resp_buff, user_info_buff, group_main_buff, 0x2100, multi_buff
	end

	return resp_buff, user_info_buff, group_main_buff
end

function group_help_list_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 2, Tools.encode("GroupHelpListResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_help_list_do_logic(req_buff, user_name, user_info_buff, group_main_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local groupMain = require "UserGroup"
	groupMain:new(group_main_buff)
	local group_main = groupMain:getGroupMain()
	groupMain:setUserInfo(user_info)

	GroupCache.merge(group_main)

	GroupCache.update(group_main, user_info.user_name)


	local resp = {
		result = "OK",
		help_list = group_main.help_list,
	}

	local resp_buff = Tools.encode("GroupHelpListResp", resp)
	user_info_buff = userInfo:getUserBuff()
	group_main_buff = groupMain:getGroupBuff()
	return resp_buff, user_info_buff, group_main_buff
end

function group_help_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 3, Tools.encode("GroupHelpResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("GroupHelpReq", req_buff)
		return datablock.main_data + datablock.save, req.user_name
	elseif step == 3 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_help_do_logic(req_buff, user_name, user_info_buff, user_info_buff2, group_main_buff)

	local req = Tools.decode("GroupHelpReq", req_buff)

	local userInfo2 = require "UserInfo"
	userInfo2:new(user_info_buff2)
	local user_info2 = userInfo2:getUserInfo()

	local user_info = Tools.decode("UserInfo", user_info_buff)

	local groupMain = require "UserGroup"
	groupMain:new(group_main_buff)
	local group_main = groupMain:getGroupMain()
	groupMain:setUserInfo(user_info)

	local user_sync2

	local function doLogic( req )

		GroupCache.merge(group_main)

		if req.id[1] == nil or req.id[1] <= 0 then
			return "REQ_DATA_ERROR"
		end


		local building_info = CoreUser.getBuildingInfo( CONF.EBuilding.kDiplomacy, user_info )
		
		if user_info.group_data.help_times == nil then
			user_info.group_data.help_times = 0
		else
			user_info.group_data.help_times = user_info.group_data.help_times + 1
		end

		local help_info
		local help_info_index
		if Tools.isEmpty(group_main.help_list) == false then

			for i,v in ipairs(group_main.help_list) do
				if v.user_name == req.user_name then
					if v.type == req.type and v.id[1] == req.id[1] then
						help_info = v
						help_info_index = i
						break
					end
				end
			end
		end
		if help_info == nil then
			return "NO_DATA"
		end

		if Tools.isEmpty(help_info.help_user_name_list) == false then
			for i,v in ipairs(help_info.help_user_name_list) do
				if v == user_info.user_name then
					return "REQ_DATA_ERROR"
				end
			end
			if #help_info.help_user_name_list >= help_info.max_help_times then
				return "HELP_TIME_MAX"
			end
		end
		

		local helpConf = CONF.GROUP_HELP.get(req.type)
		local building_sub_conf = 0

		if building_info then
			building_sub_conf = CONF.BUILDING_13.get(building_info.level).HELP_SUB_TIME
		end

		if req.type == CONF.EGroupHelpType.kBuilding then

			local building_info = userInfo2:getBuildingInfo(req.id[1])
			if not building_info then
				return "NO_INFO_DATA"
			end
			if building_info.upgrade_begin_time <= 0 then
				table.remove(group_main.help_list, help_info_index)
				return "NO_CD"
			end
			local cd = userInfo2:getBuildingCDTime( req.id[1], building_info, true )

			local sub_value = helpConf.CD_SEC + cd * 0.01 * helpConf.CD_PER + building_sub_conf

			building_info.upgrade_begin_time = building_info.upgrade_begin_time - sub_value

			user_sync2 = {
				user_info = {
					building_list = user_info2.building_list,
					group_data = user_info2.group_data,
				}
			}

		elseif req.type == CONF.EGroupHelpType.kTechnology then
			local tech_data = userInfo2:getTechnologyInfo()
			if not tech_data then
				return "NO_INFO_DATA"
			end
			local tech_info = userInfo2:getTechnologyInfoByID(req.id[1])
			if not tech_info then
				return "NO_INFO_DATA"
			end
			if tech_data.upgrade_busy <= 0 or tech_info.tech_id ~= req.id[1] then
				table.remove(group_main.help_list, help_info_index)
				return "NO_CD"
			end

			local cd = userInfo2:getTechnologyCDTime(req.id[1], true)

			local sub_value = helpConf.CD_SEC + cd * 0.01 * helpConf.CD_PER + building_sub_conf

			tech_info.begin_upgrade_time = tech_info.begin_upgrade_time - sub_value

			user_sync2 = {
				user_info = {
					tech_data = user_info2.tech_data,
					group_data = user_info2.group_data,
				}
			}


		elseif req.type == CONF.EGroupHelpType.kHome then

			if req.id[2] == nil or req.id[2] <= 0 then
				return "REQ_DATA_ERROR"
			end

			local land_info = userInfo2:getHomeLandList()
			local info
			for i,v in ipairs(land_info) do
				if v.land_index == req.id[1] then
					info = v
					break
				end
			end
			if info.resource_status ~= 1 or info.res_refresh_times <= 0 then
				table.remove(group_main.help_list, help_info_index)
				return "NO_CD"
			end
			local cd = userInfo2:getHomeBuildingCDTime(info.resource_type, true)

			local sub_value = helpConf.CD_SEC + cd * 0.01 * helpConf.CD_PER + building_sub_conf

			info.res_refresh_times =  info.res_refresh_times - sub_value

			user_sync2 = {
				user_info = {
					home_info = user_info2.home_info,
					group_data = user_info2.group_data,
				}
			}
		end

		if user_info.group_data.help_times ~= nil then
			user_info.group_data.help_times = 1
		else
			user_info.group_data.help_times = user_info.group_data.help_times + 1
		end

		--更新每日数据
		local daily_data = CoreUser.getDailyData(user_info)
		if not daily_data.help_times then
			daily_data.help_times = 1
		else
			daily_data.help_times = daily_data.help_times + 1
		end

		--添加帮助user_name
		if Tools.isEmpty(help_info.help_user_name_list) == false then
			table.insert(help_info.help_user_name_list, user_info.user_name)
		else
			help_info.help_user_name_list = {user_info.user_name}
		end

		--删除帮助次数满的信息
		if #help_info.help_user_name_list >= helpConf.TIME then
			table.remove(group_main.help_list, help_info_index)
		end

		GroupCache.update(group_main, user_info.user_name)

		local user_sync = {
			user_info = {
				group_data = user_info.group_data,
				daily_data = daily_data,
			}
		}

		return "OK", user_sync
	end


	local ret, user_sync = doLogic(req)
	local resp = {
		result = ret,
		user_sync = user_sync,
		help_list = group_main.help_list,
	}

	local resp_buff = Tools.encode("GroupHelpResp", resp)
	user_info_buff = Tools.encode("UserInfo", user_info)
	user_info_buff2 = userInfo2:getUserBuff()
	group_main_buff = groupMain:getGroupBuff()

	if ret == "OK" then
		local user_update = {
			user_name = user_info2.user_name,
			user_sync = user_sync2
		}
		local multi_cast = groupMain:getMultiCast({user_update})

		local multi_buff = Tools.encode("Multicast", multi_cast)

		return resp_buff, user_info_buff, user_info_buff2, group_main_buff, 0x2100, multi_buff
	end

	
	return resp_buff, user_info_buff, user_info_buff2, group_main_buff
end


function group_invite_feature( step, req_buff, user_name )
	if step == 0 then

		local resp =
		{
			result = "FAIL",
		}
		return 2, Tools.encode("GroupInviteResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("GroupInviteReq", req_buff)
		return datablock.main_data + datablock.mail_list + datablock.save, req.recver
	else
		error("something error");
	end
end

function group_invite_do_logic(req_buff, user_name, user_info_buff, user_info_buff2, mail_list_buff2)

	local req = Tools.decode("GroupInviteReq", req_buff)

	local userInfo = require "UserInfo"
	local mailList2 = require "MailList"
	userInfo:new(user_info_buff)
	mailList2:new(mail_list_buff2)

	local user_info = userInfo:getUserInfo()
	local mail_list2 = mailList2:getMailList()

	local user_info2 = Tools.decode("UserInfo", user_info_buff2)

	local function doLogic()

		if user_info.group_data and user_info.group_data.job >= GolbalDefine.enum_group_job.member then
			return "NO_POWER"
		end

		if user_info2.level < CONF.FUNCTION_OPEN.get("league_open").GRADE then
			return "NO_OPEN"
		end

		--查看是否在对方黑名单
		if CoreUser.checkFriendsData( user_name, "black_list", user_info2) == true then
			return "OTHER_BLACK"
		end

		--查看是否在自己黑名单
		if CoreUser.checkFriendsData( user_info2.user_name, "black_list", user_info) == true then
			return "MY_BLACK"
		end

		--查看是否有公会
		if Tools.isEmpty(user_info2.group_data) == false and user_info2.group_data.groupid ~= ""  then
			return "HAS_GROUP"
		end

		if CoreMail.recvGroupInviteMail(user_info, mail_list2) == false then
			return "SENDED"
		end

		local new_group_update = {
			sender = user_info.user_name
		}

		local multicast =
		{
			recv_list = {req.recver},
			cmd = 0x16fe,
			msg_buff = Tools.encode("NewGroupUpdate",new_group_update)
		}
		return "OK", multicast
	end

	local ret, multicast = doLogic()	

	local resp = {
		result = ret,
	}
	user_info_buff = userInfo:getUserBuff()
	mail_list_buff2 = mailList2:getMailBuff() 
	local resp_buff = Tools.encode("GroupInviteResp",resp)
	if multicast then
		return resp_buff, user_info_buff, user_info_buff2, mail_list_buff2, 0x2100, Tools.encode("Multicast", multicast)
	else
		return resp_buff, user_info_buff, user_info_buff2, mail_list_buff2
	end
end


function group_worship_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = "FAIL",
		}
		return 2, Tools.encode("GroupWorshipResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_list + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function group_worship_do_logic(req_buff, user_name, user_info_buff, item_list_buff, group_main_buff)

	local req = Tools.decode("GroupWorshipReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local groupMain = require "UserGroup"
	groupMain:new(group_main_buff)
	local group_main = groupMain:getGroupMain()
	groupMain:setUserInfo(user_info)
	groupMain:setItemList(item_list)

	local ret
	local user_sync
	if req.type == 1 then
		ret, user_sync = groupMain:groupWorship(req.level)
	elseif req.type == 2 then
		local function getReward( level )

			if user_info.group_data == nil or user_info.group_data.groupid == "" then
				return "NO_GROUP"
			end

			-- if user_info.group_data.today_worship_level == nil or user_info.group_data.today_worship_level == 0 then
			-- 	return "NO_WORSHIP"
			-- end

			if Tools.isEmpty(user_info.group_data.getted_worship_reward) == false then
				if user_info.group_data.getted_worship_reward[level] == true then
					return "GETTED"
				end
			end

			local conf = CONF.WORSHIPREWARD.get(1)
			if group_main.worship_value < conf["ACTIVE_POINT"..level] then
				return "LOW_POINT"
			end

			local user_sync = userInfo:getReward(conf["REWARD"..level], item_list)
	
			if Tools.isEmpty(user_info.group_data.getted_worship_reward) == true then
				user_info.group_data.getted_worship_reward = {false, false, false}
			end
			user_info.group_data.getted_worship_reward[level] = true
			user_sync.user_info = user_sync.user_info or {}
			user_sync.user_info.group_data = user_info.group_data

			return "OK", user_sync
		end
		ret, user_sync = getReward(req.level)
	end

	local resp = {
		result = ret,
		user_sync = user_sync, 
		req = req,
	}

	local resp_buff = Tools.encode("GroupWorshipResp", resp)
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	group_main_buff = groupMain:getGroupBuff()

	if req.type == 1 and ret == "OK" then
		local multi_cast = groupMain:getMultiCast()
		local multi_buff = Tools.encode("Multicast", multi_cast)
		return resp_buff, user_info_buff, item_list_buff, group_main_buff, 0x2100, multi_buff
	end
	return resp_buff, user_info_buff, item_list_buff, group_main_buff
end