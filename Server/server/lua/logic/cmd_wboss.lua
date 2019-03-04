--local pb = pb
local logic_user = require "logic_user"
local rank = rank
local worldboss = require "worldboss"
function wboss_get_userinfo_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		--local req = pb.decode("WBossUserInfoGetReq", req_buf)
		local resp = {
			result = "FAIL"
		}
		return 1, pb.encode("WBossUserInfoGetResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.mail_list + datablock.save, user_name
	else
		error("something error");
	end
end

function wboss_get_userinfo_do_logic(req_buf, user_name, main_data_buf, mail_list_buf)
	local pb = require "protobuf"
	
	local main_data = pb.decode("UserInfo", main_data_buf)
	local mail_list = pb.decode("MailList", mail_list_buf)
	if not rawget(mail_list, "mail_list") then mail_list = {mail_list = {}} end
	--local req = pb.decode("WBossUserInfoGetReq", req_buf)
	
	local resp = {
		result = "OK",
		now_time = os.time(),	--当前服务器时间
		user_wboss = {}, --用户相关信息
		wboss_info = {}, --世界BOSS信息
		rank_list = {}	--排行 
	}
	
	local ret = worldboss.get_userinfo(main_data, mail_list.mail_list)
	resp.user_wboss = ret.user_wboss
	resp.wboss_info = ret.wboss_info
	resp.rank_list = ret.rank_list

	--printtab(resp, "wboss userinfo resp")
	local resp_buf = pb.encode("WBossUserInfoGetResp", resp)
	main_data_buf = pb.encode("UserInfo", main_data)
	mail_list_buf = pb.encode("MailList", mail_list)
	return resp_buf, main_data_buf, mail_list_buf
end


function wboss_get_rank_reward_list_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		--local req = pb.decode("WBossGetRankRewardListReq", req_buf)
		local resp = {
			result = "FAIL",
			reward_list = {}
		}
		return 0, pb.encode("WBossGetRankRewardListResp", resp)
	else
		error("something error");
	end
end

function wboss_get_rank_reward_list_do_logic(req_buf, user_name, main_data_buf)
	local pb = require "protobuf"
	--local req = pb.decode("WBossGetRankRewardListReq", req_buf)


	local resp = {
		result = "OK",
		reward_list = {
			items = {},
		}
	}
	resp.reward_list.items = worldboss.get_rank_reward_list()

	local resp_buf = pb.encode("WBossGetRankRewardListResp", resp)

	return resp_buf
end

function wboss_attack_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		--local req = pb.decode("WBossAttackReq", req_buf)
		local resp = {
			result = "FAIL"
		}
		return 1, pb.encode("WBossAttackResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
	else
		error("something error");
	end
end

function wboss_attack_do_logic(req_buf, user_name, main_data_buf, knight_buf, item_package_buf)
	local pb = require "protobuf"
	local req = pb.decode("WBossAttackReq", req_buf)
	local main_data = pb.decode("UserInfo", main_data_buf)
	local knight_bag = pb.decode("KnightList", knight_buf)
	if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
	local item_package = pb.decode("ItemList", item_package_buf)
	if not rawget(item_package, "item_list") then item_package = {item_list = {}} end
	local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
   
	local resp = worldboss.attack_boss(req.wboss_head, main_data, knight_bag.knight_list, item_package.item_list, task_struct)
	resp.result = "OK"

	local ext_cmd = nil
	local ext_buf = nil
	if task_struct.ret then
		ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
		ext_cmd = 0x1035
	end
	
	local resp_buf = pb.encode("WBossAttackResp", resp)
	main_data_buf = pb.encode("UserInfo", main_data)
	item_package_buf = pb.encode("ItemList", item_package)
	return resp_buf, main_data_buf, knight_buf, item_package_buf, ext_cmd, ext_buf
end

--获取排行榜
function wboss_rank_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		--local req = pb.decode("WBossRankReq", req_buf)
		local resp = {
			result = "FAIL"
		}
		return 1, pb.encode("WBossRankResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.save, user_name
	else
		error("something error");
	end
end

function wboss_rank_do_logic(req_buf, user_name, main_data_buf)
	local pb = require "protobuf"
	local req = pb.decode("WBossRankReq", req_buf)
	local main_data = pb.decode("UserInfo", main_data_buf)
	local resp = {
		result = "OK",
		rank_list = {}
	}
	
	resp.rank_list = worldboss.get_rank(main_data, req.wboss_head);

	local resp_buf = pb.encode("WBossRankResp", resp)
	main_data_buf = pb.encode("UserInfo", main_data)
	return resp_buf, main_data_buf
end
