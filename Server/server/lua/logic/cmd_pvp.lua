local logic_user = require "logic_user"
local pvp = require "pvp"

local core_time = require "time_checking"

local pvp_rcd = pvp_rcd
local rank = rank
--[[
local rank = require "rank_list"
rank.load()
]]

local function isRobot(name)
	if tonumber(name) then return nil end
	local name1 = string.sub(name, 1,5)
	local name2 = tonumber(string.sub(name, 6))
	if name1 == "Robot" then
		return name2
	else 
		return nil 
	end
end

function pvp_gettarget_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("GetRankingTagResp", resp)
	elseif step == 1 then
		return datablock.main_data, user_name
	else
		error("something error");
	end
end

function pvp_gettarget_do_logic(req_buf, user_name, main_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", main_buf)
	local resp = {
		result = "OK",
		list = nil,
	}
	resp.list = rank.get_target(user_name, main_data)
	
	local resp_buf = pb.encode("GetRankingTagResp", resp)
	return resp_buf, main_buf
end

function pvp_topn_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 0, pb.encode("GetRankingListResp", resp)
	else
		error("something error");
	end
end

function pvp_topn_do_logic(req_buf, user_name)
	local pb = require "protobuf"
	local resp = {
		result = "OK",
		list = nil,
	}
	resp.list = rank.get_top_n()
	
	local resp_buf = pb.encode("GetRankingListResp", resp)
	return resp_buf
end

function pvp_fight_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
			attack_list = {},
			hurter_list = {},
			event_list = {},
		}
		return 2, Tools.encode("PvpResp", resp)
	elseif step == 1 then		
		return datablock.main_data + datablock.ship_list + datablock.save, user_name
	elseif step == 2 then

		local req = Tools.decode("PvpReq", req_buff)
		local target = string.format("%s%d", req.target_name, req.target_sid)			
		return datablock.main_data + datablock.ship_list + datablock.save, target
	else
		error("something error");
	end
end

function pvp_fight_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, user_info_buff2, ship_list_buff2)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"

	local user_info
	local ship_list 

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

	local req = Tools.decode("PvpReq", req_buff)
	
	resetBuff(1)

	local attack_list = shipList:getLineup()
	local group_main = userInfo:getGroupMainFromGroupCache()
	for i=1,#attack_list do
		attack_list[i] = Tools.calShip(attack_list[i], user_info, group_main, true)
		attack_list[i].body_position = {attack_list[i].position}
	end

	
	resetBuff(2)

	local group_main = userInfo:getGroupMainFromGroupCache()

	local hurter_list = shipList:getShipByLineup()
	for i=1,#hurter_list do
		hurter_list[i] = Tools.calShip(hurter_list[i], user_info, group_main, true)
		hurter_list[i].body_position = {hurter_list[i].position}
	end

	resetBuff(1)



	local isWin, event_list = Tools.autoFight(attack_list, nil, hurter_list, nil)
	

	

	local resp =
	{
		result = 2,
		attack_list = attack_list,
		hurter_list = hurter_list,
		event_list = event_list,
	}
	-- Tools.print_t(resp)
	-- LOG_INFO(print_t(resp))
	local resp_buff = Tools.encode("PvpResp", resp)

	return resp_buff, user_info_buff, ship_list_buff, user_info_buff2, ship_list_buff2
end

function pvp_video_feature(step, req_buff, user_name)
	if step == 0 then
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("PvpVideoResp", resp)
	elseif step == 1 then		
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function pvp_video_do_logic(req_buff, user_name, user_info_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()

	local req = Tools.decode("PvpVideoReq", req_buff)

	local resp =
	{
		result = 0,
	}

	local video_data = VideoCache.getVideo( req.video_key )
	if video_data == nil then
		resp.result = 1
	else
		resp.result = 0
		resp.data = video_data
	end

	local resp_buff = Tools.encode("PvpVideoResp", resp)
	return resp_buff, user_info_buff
end


function pvp_fight_feature1(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		local num = 2
		local req = pb.decode("PVPReq", req_buf)
		local target = req.target.entry.name
		if isRobot(target) then num = 1 end
		return num, pb.encode("PVPResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.mail_list + datablock.save,user_name
	elseif step == 2 then
		local pb = require "protobuf"
		local req = pb.decode("PVPReq", req_buf)
		local target = req.target.entry.name
		assert(not isRobot(target))
		return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.mail_list + datablock.save, target
	else
		error("something error");
	end
end

function pvp_fight_do_logic1(req_buf, user_name, main_buf1, knight_buf1, item_buf1, mail_buf1, main_buf2, knight_buf2, item_buf, mail_buf)
	local pb = require "protobuf"
	local req = pb.decode("PVPReq", req_buf)
	local target = req.target.entry.name
	local robot_idx = isRobot(target)
	local main_data1 = pb.decode("UserInfo", main_buf1)
	local mail_list1 = pb.decode("MailList", mail_buf1)
	local item_list1 = pb.decode("ItemList", item_buf1)
	local knight_bag1 = pb.decode("KnightList", knight_buf1)
	if rawget(knight_bag1, "knight_list") == nil then knight_bag1 = {knight_list = {}} end
	if rawget(item_list1, "item_list") == nil then item_list1 = {item_list = {}} end
	if not rawget(mail_list1, "mail_list") then mail_list1 = {mail_list = {}} end
	local main_data2 = nil
	local item_list = nil
	local mail_list = nil
	local knight_bag2 = nil
	if not robot_idx then
		main_data2 = pb.decode("UserInfo", main_buf2)
		item_list = pb.decode("ItemList", item_buf)
		mail_list = pb.decode("MailList", mail_buf)
		if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
		if not rawget(mail_list, "mail_list") then mail_list = {mail_list = {}} end
		knight_bag2 = pb.decode("KnightList", knight_buf2)
		if rawget(knight_bag2,"knight_list") == nil then knight_bag2 = {knight_list = {}} end
	else
		main_data2 = robot_list10[robot_idx]
		knight_bag2 = {knight_list = {}}
	end
	
	local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
	local notify_struct = {ret = false, data = nil}
	local rcd, new_target, new_self, rsync, winner, err_code, old_self =
		pvp.do_pvp(main_data1,knight_bag1.knight_list,mail_list1.mail_list,
			main_data2, knight_bag2.knight_list, user_name, req, task_struct, robot_idx, notify_struct)

	if not err_code then
		local ext_cmd = nil
		local ext_buf = nil
		if task_struct.ret then
			ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
			ext_cmd = 0x1035
		end
		
		local ext_cmd2 = nil
		local ext_buf2 = nil
		if notify_struct.ret then
			ext_buf2 = pb.encode("NotifyRefleshResp", {msg_list = notify_struct.data})
			ext_cmd2 = 0x1037
		end
		local resp = {
			result = "OK",
			new_target = new_target,
			fight_rcd = rcd,
			self = new_self,
			rsync = rsync,
			pvp = main_data1.PVP
		}
		if winner == 1 and not robot_idx then
			local time = os.time()
			local dayid = core_time.get_dayid_from(time, 21)
			core_time.update_at_9pm(main_data2, dayid, item_list.item_list, mail_list.mail_list, req.target.idx)
			if old_self.idx > 0 then
				core_time.update_at_9pm(main_data1, dayid, item_list1.item_list, mail_list1.mail_list, old_self.idx)
			end
		end
		local resp_buf = pb.encode("PVPResp", resp)
		main_buf1 = pb.encode("UserInfo", main_data1)
		item_buf1 = pb.encode("ItemList", item_list1)
		mail_buf1 = pb.encode("MailList", mail_list1)
		if not robot_idx then
			main_buf2 = pb.encode("UserInfo", main_data2)
			item_buf = pb.encode("ItemList", item_list)
			mail_buf = pb.encode("MailList", mail_list)
		end
		if not robot_idx then
			return resp_buf, main_buf1, knight_buf1, item_buf1, mail_buf1, main_buf2, knight_buf2, item_buf, mail_buf, ext_cmd, ext_buf,ext_cmd2,ext_buf2
		else
			return resp_buf, main_buf1, knight_buf1, item_buf1, mail_buf1, ext_cmd, ext_buf,ext_cmd2,ext_buf2
		end
	else
		local resp = {
			result = "OK",
			err_code = err_code
		}
		local resp_buf = pb.encode("PVPResp", resp)
		if not robot_idx then
			return resp_buf, main_buf1, knight_buf1, item_buf1, mail_buf1, main_buf2, knight_buf2, item_buf, mail_buf
		else
			return resp_buf, main_buf1, knight_buf1, item_buf1, mail_buf1
		end
	end
end

function pvp_get_self_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("GetRankingSelfResp", resp)
	elseif step == 1 then
		return datablock.main_data, user_name
	else
		error("something error");
	end
end

function pvp_get_self_do_logic(req_buf, user_name, main_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", main_buf)
	
	local pvp, rank = rank.get_self(user_name, main_data)
	local resp = {
		result = "OK",
		pvp_info = pvp,
		ranking_data = rank,
	}
	local resp_buf = pb.encode("GetRankingSelfResp", resp)
	return resp_buf, main_buf
end

function pvp_get_detail_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("GetDetailResp", resp)
	elseif step == 1 then
		local pb = require "protobuf"
		local req = pb.decode("GetDetailReq", req_buf)
		local target = req.name
		if isRobot(target) then target = user_name end
		return datablock.main_data, target
	else
		error("something error");
	end
end

function pvp_get_detail_do_logic(req_buf, user_name, main_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", main_buf)
	local req = pb.decode("GetDetailReq", req_buf)
	local target = req.name
	local robot_idx = isRobot(target)
	if robot_idx then
		local data = robot_list10[robot_idx]
		main_data.nickname = data.nickname
		main_data.lead = data.lead
		main_data.lead.exp = 0
		main_data.lead.level = 10
		main_data.lead.skill.level = 10
		main_data.lead.pve2_sub_hp = 0
		main_data.zhenxing = data.zhenxing
		local knight = main_data.zhenxing.zhanwei_list[5].knight.data
		knight.exp = 0
		knight.pve2_sub_hp = 0
		knight.gong.type = 0
		knight = main_data.zhenxing.zhanwei_list[6].knight.data
		knight.exp = 0
		knight.pve2_sub_hp = 0
		knight.gong.type = 0
		

		local t = main_data.PVP.reputation
		main_data.PVP.reputation = data.PVP.reputation
		main_data.PVP.total_count = 12
		main_data.PVP.total_win = 10
		main_data.lover_list = data.lover_list
		main_data.book_list = data.book_list
		main_data.power = data.power10
	end
	--去除敏感信息
	main_data.gold = 0
	main_data.money = 0
	local t = main_data.task_list.task_list
	main_data.task_list.task_list = nil
	t = main_data.chengjiu.chengjiu_list
	main_data.chengjiu.chengjiu_list = nil
	t = main_data.daily.daily_list
	main_data.daily.daily_list = nil
	t = main_data.ext_data.real_money
	main_data.ext_data.real_money = 0
	main_data.ext_data.total_money = 0
	t = main_data.PVE.fortress_list
	main_data.PVE.fortress_list = nil
	local resp = {
		result = "OK",
		name = req.name,
		detail = main_data,
	}
	local resp_buf = pb.encode("GetDetailResp", resp)
	return resp_buf, main_buf
end

function pvp_get_pvpinfo_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("GetPVPInfoResp", resp)
	elseif step == 1 then
		return datablock.main_data, user_name
	else
		error("something error");
	end
end

function pvp_get_pvpinfo_do_logic(req_buf, user_name, main_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", main_buf)
	local resp = {
		result = "OK",
		PVP = main_data.PVP,
	}
	local resp_buf = pb.encode("GetPVPInfoResp", resp)
	return resp_buf, main_buf
end

function pvp_get_rcd_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 0, pb.encode("GetPVPRcdResp", resp)
	else
		error("something error");
	end
end

function pvp_get_rcd_do_logic(req_buf, user_name)
	local pb = require "protobuf"
	local req = pb.decode("GetPVPRcdReq", req_buf)
	local rcd_idx = req.rcd_idx
	local rcd = pvp_rcd.get_rcd(rcd_idx)
	assert(rcd)
	local r_rcd = pb.decode("FightRcd", rcd)
	local resp = {
		result = "OK",
		rcd = r_rcd,
	}
	local resp_buf = pb.encode("GetPVPRcdResp", resp)
	return resp_buf
end

function pvp_reflesh_shop_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("PVPRefleshShopResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function pvp_reflesh_shop_do_logic(req_buf, user_name, user_data_buf, item_pack_buf)
	local pb = require "protobuf"
	local req = pb.decode("PVPRefleshShopReq", req_buf)
	local user_data = pb.decode("UserInfo", user_data_buf)
	local item_list = pb.decode("ItemList", item_pack_buf)
	if not rawget(item_list, "item_list") then item_list = {item_list = {}} end 
	local shop_list, rsync = pvp.reflesh_shop(user_data, item_list.item_list, req.free)
	local resp = {
		result = "OK",
		req = req,
		shopping_list = shop_list,
		rsync = rsync
	}
	user_data_buf = pb.encode("UserInfo", user_data)
	item_pack_buf = pb.encode("ItemList", item_list)
	local resp_buf = pb.encode("PVPRefleshShopResp", resp)
	return resp_buf, user_data_buf, item_pack_buf
end

function pvp_shopping_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("PVPShoppingResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function pvp_shopping_do_logic(req_buf, user_name, user_data_buf, item_pack_buf)
	local pb = require "protobuf"
	local req = pb.decode("PVPShoppingReq", req_buf)
	local user_data = pb.decode("UserInfo", user_data_buf)
	local item_list = pb.decode("ItemList", item_pack_buf)
	if not rawget(item_list, "item_list") then item_list = {item_list = {}} end 
	local ret = pvp.shopping(user_data, item_list.item_list, req.idx + 1)
	local resp = {
		result = "OK",
		req = req,
		rsync = ret
	}
	user_data_buf = pb.encode("UserInfo", user_data)
	item_pack_buf = pb.encode("ItemList", item_list)
	local resp_buf = pb.encode("PVPShoppingResp", resp)
	return resp_buf, user_data_buf, item_pack_buf
end

function pvp_money2chance_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("PVPMoney2ChanceResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function pvp_money2chance_do_logic(req_buf, user_name, user_data_buf)
	local pb = require "protobuf"
	local req = pb.decode("PVPMoney2ChanceReq", req_buf)
	local user_data = pb.decode("UserInfo", user_data_buf)
	local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
	local ret = pvp.money2chance(user_data, task_struct)
	local resp = {
		result = "OK",
		rsync = ret
	}
	local ext_cmd = nil
	local ext_buf = nil
	if task_struct.ret then
		ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
		ext_cmd = 0x1035
	end
	user_data_buf = pb.encode("UserInfo", user_data)
	local resp_buf = pb.encode("PVPMoney2ChanceResp", resp)
	return resp_buf, user_data_buf, ext_cmd, ext_buf
end

function wlzb_reg_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("WlzbRegResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.knight_bag + datablock.save, user_name
	else
		error("something error");
	end
end

function wlzb_reg_do_logic(req_buf, user_name, user_data_buf, knight_buf)
	local pb = require "protobuf"
	local req = pb.decode("WlzbRegReq", req_buf)
	local main_data = pb.decode("UserInfo", user_data_buf)
	local knight_bag = pb.decode("KnightList", knight_buf)
	if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
	local ret = 0
	if req.type == 0 then
		ret = wlzb.check_reg(user_name)
	else
		ret = wlzb.regist(main_data, knight_bag.knight_list)
	end
	local resp = {
		result = "OK",
		type = ret,
	}
	local resp_buf = pb.encode("WlzbRegResp", resp)
	user_data_buf = pb.encode("UserInfo", main_data)
	return resp_buf, user_data_buf, knight_buf
end

-- 拉取自己的战斗记录
function wlzb_rcd_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 0, pb.encode("WlzbGetRcdResp", resp)
	else
		error("something error");
	end
end

function wlzb_rcd_do_logic(req_buf, user_name)
	local pb = require "protobuf"
	local req = pb.decode("WlzbGetRcdReq", req_buf)
	local ret = wlzb.get_rcd(req.rcd_idx)
	local resp = {
		result = "OK",
		rcd_idx = req.rcd_idx,
		rcd = ret,
	}
	local resp_buf = pb.encode("WlzbGetRcdResp", resp)
	return resp_buf
end

-- 拉取战斗记录
function wlzb_get_fight_info_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("WlzbGetFightInfoResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function wlzb_get_fight_info_do_logic(req_buf, user_name, user_data_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", user_data_buf)
	local self_list, first8, round_num, wlzb_info = pvp.get_wlzb_fight(main_data)
	local last_reg = 0
	if self_list then last_reg = 1 end
	local status = 1
	local t = math.floor(((os.time() + 28800) % 86400) / 3600)
	if t < 8 then status = 0 end
	
	local resp = {
		result = "OK",
		self_list = self_list,
		first8_list = first8,
		round_num = round_num,
		wlzb_info = wlzb_info,
		status = status,
		last_reg = last_reg,
	}
	local resp_buf = pb.encode("WlzbGetFightInfoResp", resp)
	user_data_buf = pb.encode("UserInfo", main_data)
	return resp_buf, user_data_buf
end

-- 获取武林争霸奖励
function wlzb_reward_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("WlzbGetRewardResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function wlzb_reward_do_logic(req_buf, user_name, user_data_buf, item_buf)
	local pb = require "protobuf"
	local req = pb.decode("WlzbGetRewardReq", req_buf)
	local main_data = pb.decode("UserInfo", user_data_buf)
	local item_list = pb.decode("ItemList", item_buf)
	if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
	local ret, wlzb_info = pvp.get_wlzb_reward(main_data, item_list.item_list, req.reward_id)
	local resp = {
		result = "OK",
		reward_id = req.reward_id,
		rsync = ret,
		wlzb_info = wlzb_info,
	}
	local resp_buf = pb.encode("WlzbGetRewardResp", resp)
	user_data_buf = pb.encode("UserInfo", main_data)
	item_buf = pb.encode("ItemList", item_list)
	return resp_buf, user_data_buf, item_buf
end

-- 获取武林争霸奖励
function wlzb_reward_list_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 0, pb.encode("WlzbGetRewardListResp", resp)
	else
		error("something error");
	end
end

function wlzb_reward_list_do_logic(req_buf, user_name)
	local pb = require "protobuf"
	local reward_list = wlzb.get_reward_list()
	local resp = {
		result = "OK",
		item_list = reward_list,
	}
	local resp_buf = pb.encode("WlzbGetRewardListResp", resp)
	return resp_buf
end

--门派战
function mpz_master_reg_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 2, pb.encode("MPZRegResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function mpz_master_reg_do_logic(req_buf, user_name, user_data_buf, group_buf)
	local pb = require "protobuf"
	local req = pb.decode("MPZRegReq", req_buf)
	local main_data = pb.decode("UserInfo", user_data_buf)
	local group_data = pb.decode("GroupMainData", group_buf)
	
	local resp, group_r = mpz.master_regist(main_data, group_data, req)

	local resp_buf = pb.encode("MPZRegResp", resp)
	group_buf = pb.encode("GroupMainData", group_r)
	return resp_buf, user_data_buf, group_buf
end

function mpz_mem_reg_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 2, pb.encode("MPZRegMemResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.knight_bag + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.save, user_name
	else
		error("something error");
	end
end

function mpz_mem_reg_do_logic(req_buf, user_name, user_data_buf, knight_buf, group_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", user_data_buf)
	local knight_bag = pb.decode("KnightList", knight_buf)
	local group_data = pb.decode("GroupMainData", group_buf)
	if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
	
	local main_data_r, group_r = mpz.mem_regist(main_data, knight_bag.knight_list, group_data, user_name)

	local resp = {
		result = "OK",
	}
	local resp_buf = pb.encode("MPZRegMemResp", resp)
	user_data_buf = pb.encode("UserInfo", main_data_r)
	group_buf = pb.encode("GroupMainData", group_r)
	return resp_buf, user_data_buf, knight_buf, group_buf
end

-- 拉取自己的战斗记录
function mpz_get_rcd_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 0, pb.encode("MPZGetVideoResp", resp)
	else
		error("something error");
	end
end

function mpz_get_rcd_do_logic(req_buf, user_name)
	local pb = require "protobuf"
	local req = pb.decode("MPZGetVideoReq", req_buf)
	local ret = mpz.get_rcd(req)
	local resp = {
		result = "OK",
		fight_rcd = ret,
	}
	local resp_buf = pb.encode("MPZGetVideoResp", resp)
	return resp_buf
end

-- 拉取门派战信息
function mpz_get_info_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 2, pb.encode("MPZGetResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	elseif step == 2 then
		return datablock.group_main + datablock.try, user_name
	else
		error("something error");
	end
end

function mpz_get_info_do_logic(req_buf, user_name, user_data_buf, group_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", user_data_buf)
	local group_data = nil
	if group_buf then
		group_data = pb.decode("GroupMainData", group_buf)
	end
	local req = pb.decode("MPZGetReq", req_buf)

	local resp, group_r = mpz.get_mpz_info(main_data, group_data, req, user_name)    
	
	local resp_buf = pb.encode("MPZGetResp", resp)
	--user_data_buf = pb.encode("UserInfo", main_data)
	if group_buf and group_r ~= nil then
		group_buf = pb.encode("GroupMainData", group_r)
	end
	return resp_buf, user_data_buf, group_buf
end

function mine_get_info_feature( step, req_buf, user_name )
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("RobMineGetResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.knight_bag + datablock.save, user_name
	else
		error("something error");
	end
end

function mine_get_info_do_logic(req_buf, user_name, user_data_buf, knight_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", user_data_buf)
	local req = pb.decode("RobMineGetReq", req_buf)
	local knight_bag = pb.decode("KnightList", knight_buf)
	if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
	local resp = robmine.get_mine_info(main_data, knight_bag.knight_list, req.flag, user_name)    
	
	local resp_buf = pb.encode("RobMineGetResp", resp)
	user_data_buf = pb.encode("UserInfo", main_data)
	knight_buf = pb.encode("KnightList", knight_bag)
	return resp_buf, user_data_buf, knight_buf
end

--
function mine_search_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		local num = 2
		local req = pb.decode("RobMineSearchReq", req_buf)
		local target = req.uid
		if string.sub(target, 1, 6) == "Robot_" then target = "zhangyan" end
		if target == "zhangyan" then num = 1 end
		return num, pb.encode("RobMineSearchResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.knight_bag + datablock.save,user_name
	elseif step == 2 then
		local pb = require "protobuf"
		local req = pb.decode("RobMineSearchReq", req_buf)
		local target = req.uid
		if string.sub(target, 1, 6) == "Robot_" then target = "zhangyan" end
		assert( target ~= "zhangyan" )
		return datablock.main_data + datablock.save, target
	else
		error("something error");
	end
end

function mine_search_do_logic(req_buf, user_name, main_buf1, knight_buf1, main_buf2)
	local pb = require "protobuf"
	local req = pb.decode("RobMineSearchReq", req_buf)
	local enemyid = req.uid
	local main_data1 = pb.decode("UserInfo", main_buf1)
	local main_data2 = nil
	local knight_bag1 = pb.decode("KnightList", knight_buf1)
	if rawget(knight_bag1, "knight_list") == nil then knight_bag1 = {knight_list = {}} end
	if string.sub(enemyid, 1, 6) == "Robot_" then enemyid = "zhangyan" end
	
	if "zhangyan" ~= enemyid then
		main_data2 = pb.decode("UserInfo", main_buf2)
	end

	local enemyinfo, paygold, change_list = robmine.mine_research(main_data1, knight_bag1.knight_list, main_data2, enemyid)

	local resp = {
		result = "OK",
		enemyinfo = enemyinfo,
		rsyncgold = paygold,
		change_list = change_list,
	}

	local resp_buf = pb.encode("RobMineSearchResp", resp)
	main_buf1 = pb.encode("UserInfo", main_data1)
	knight_buf1 = pb.encode("KnightList", knight_bag1)
	if main_data2 then
		main_buf2 = pb.encode("UserInfo", main_data2)
		return resp_buf, main_buf1, knight_buf1, main_buf2
	else
		return resp_buf, main_buf1, knight_buf1
	end
end

function mine_get_enemylist_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		local num = 2
		local req = pb.decode("RobMineGetEnemyListReq", req_buf)
		local target = req.uid
		if isRobot(target) then num = 1 end
		return num, pb.encode("RobMineSearchResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save,user_name
	elseif step == 2 then
		local pb = require "protobuf"
		local req = pb.decode("RobMineGetEnemyListReq", req_buf)
		local target = req.uid
		assert(not isRobot(target))
		return datablock.main_data + datablock.knight_bag + datablock.save, target
	else
		error("something error");
	end
end

function mine_get_enemylist_do_logic(req_buf, user_name, main_buf1, main_buf2, knight_buf2)
	local pb = require "protobuf"
	local req = pb.decode("RobMineGetEnemyListReq", req_buf)
	local enemyid = req.uid
	local robot_idx = isRobot(enemyid)
	local main_data1 = pb.decode("UserInfo", main_buf1)
	local main_data2 = nil
	local knight_bag2 = {knight_list = {}}
	if not robot_idx then
		main_data2 = pb.decode("UserInfo", main_buf2)
		knight_bag2 = pb.decode("KnightList", knight_buf2)
		if rawget(knight_bag2, "knight_list") == nil then knight_bag2 = {knight_list = {}} end
	end

	local resp = robmine.get_enemylist(main_data1, main_data2, knight_bag2.knight_list, robot_idx)

	local resp_buf = pb.encode("RobMineGetEnemyListResp", resp)

	if not robot_idx then
		main_buf2 = pb.encode("UserInfo", main_data2)
		return resp_buf, main_buf1, main_buf2, knight_buf2
	else
		return resp_buf, main_buf1
	end
end

function mine_rob_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		local num = 2
		local req = pb.decode("RobMineReq", req_buf)
		local target = req.mineid
		if isRobot(target) then num = 1 end
		return num, pb.encode("RobMineResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save,user_name
	elseif step == 2 then
		local pb = require "protobuf"
		local req = pb.decode("RobMineReq", req_buf)
		local target = req.mineid
		assert(not isRobot(target))
		return datablock.main_data + datablock.knight_bag + datablock.save, target
	else
		error("something error");
	end
end

function mine_rob_do_logic(req_buf, user_name, main_buf1, knight_buf1, item_buf1, main_buf2, knight_buf2)
	local pb = require "protobuf"
	local req = pb.decode("RobMineReq", req_buf)
	local target = req.mineid
	local robot_idx = isRobot(target)
	local main_data1 = pb.decode("UserInfo", main_buf1)
	local item_list1 = pb.decode("ItemList", item_buf1)
	local knight_bag1 = pb.decode("KnightList", knight_buf1)
	if rawget(knight_bag1, "knight_list") == nil then knight_bag1 = {knight_list = {}} end
	if rawget(item_list1, "item_list") == nil then item_list1 = {item_list = {}} end
	local main_data2 = nil
	local knight_bag2 = nil
	if not robot_idx then
		main_data2 = pb.decode("UserInfo", main_buf2)
		knight_bag2 = pb.decode("KnightList", knight_buf2)
		if rawget(knight_bag2,"knight_list") == nil then knight_bag2 = {knight_list = {}} end
	else
		knight_bag2 = {knight_list = {}}
	end
	
	local resp =
		robmine.do_robfight(main_data1,knight_bag1.knight_list, item_list1.item_list, main_data2, knight_bag2.knight_list, user_name, req, robot_idx)

	local resp_buf = pb.encode("RobMineResp", resp)
	main_buf1 = pb.encode("UserInfo", main_data1)
	item_buf1 = pb.encode("ItemList", item_list1)
	knight_buf1 = pb.encode("KnightList", knight_bag1)

	if not robot_idx then
		main_buf2 = pb.encode("UserInfo", main_data2)
	end
	if not robot_idx then
		return resp_buf, main_buf1, knight_buf1, item_buf1, main_buf2, knight_buf2
	else
		return resp_buf, main_buf1, knight_buf1, item_buf1
	end
end

--
function mine_get_rcd_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 0, pb.encode("RobMineGetVideoResp", resp)
	else
		error("something error");
	end
end

function mine_get_rcd_do_logic(req_buf, user_name)
	local pb = require "protobuf"
	local req = pb.decode("RobMineGetVideoReq", req_buf)
	local ret = robmine.get_rcd(req)
	local resp = {
		result = "OK",
		fight_rcd = ret,
	}
	local resp_buf = pb.encode("RobMineGetVideoResp", resp)
	return resp_buf
end

--
function mine_get_jingli_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("RobMineGetJingLiResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function mine_get_jingli_do_logic(req_buf, user_name, user_data_buf)
	local pb = require "protobuf"
	local req = pb.decode("RobMineGetJingLiReq", req_buf)
	local main_data = pb.decode("UserInfo", user_data_buf)
	local ret, jinglirsync, defrcd, addjingli, defflag = robmine.get_jingli(main_data, req)
	local resp = {
		result = "OK",
		jinglirsync = jinglirsync,
		defrcd = defrcd,
		addjingli = addjingli,
		defhongdian = defflag,
	}

	if ret == 1 then
		resp.result = "FULL"
	end
	if ret == 2 then
		resp.result = "DAYFULL"
	end
	
	local resp_buf = pb.encode("RobMineGetJingLiResp", resp)
	user_data_buf = pb.encode("UserInfo", main_data)
	return resp_buf, user_data_buf
end

--
function mine_reward_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("RobMineRewardResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function mine_reward_do_logic(req_buf, user_name, user_data_buf, item_pack_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", user_data_buf)
	local req = pb.decode("RobMineGetReq", req_buf)
	local item_list = pb.decode("ItemList", item_pack_buf)
	if rawget(item_list, "item_list") == nil then item_list = {item_list = {}} end
	local rsync, mineinfo, addgold = robmine.get_reward(main_data, item_list.item_list)
	local resp = {
		result = "OK",
		rsync = rsync,
		mineinfo = mineinfo,
		addgold = addgold,
	}
	local resp_buf = pb.encode("RobMineRewardResp", resp)
	user_data_buf = pb.encode("UserInfo", main_data)
	item_pack_buf = pb.encode("ItemList", item_list)
	return resp_buf, user_data_buf, item_pack_buf
end

--
function mine_set_fightlist_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local resp = {
			result = "FAIL",
		}
		return 1, pb.encode("RobMineSetFightListResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.knight_bag + datablock.save, user_name
	else
		error("something error");
	end
end

function mine_set_fightlist_do_logic(req_buf, user_name, user_data_buf, knight_buf)
	local pb = require "protobuf"
	local req = pb.decode("RobMineSetFightListReq", req_buf)
	local main_data = pb.decode("UserInfo", user_data_buf)
	local knight_bag = pb.decode("KnightList", knight_buf)
	if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
	local resp = robmine.set_fightlist(main_data, knight_bag.knight_list, req, user_name)

	local resp_buf = pb.encode("RobMineSetFightListResp", resp)
	user_data_buf = pb.encode("UserInfo", main_data)
	knight_buf = pb.encode("KnightList", knight_bag)
	return resp_buf,user_data_buf, knight_buf
end
