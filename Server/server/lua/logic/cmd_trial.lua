--local pb = pb
local logic_user = require "logic_user"
local core_user = require "core_user_funcs"
local core_power = require "core_calc_power"
local rank = rank

local pve = require "pve"

function trial_info_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local req = pb.decode("PVETrialInfoGetReq", req_buf)
        local resp = {
            result = "FAIL",
            is_reset = req.is_reset
        }
        return 1, pb.encode("PVETrialInfoGetResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        error("something error");
    end
end

function trial_info_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("PVETrialInfoGetReq", req_buf)
	local resp = {
        result = "OK",
        is_reset = req.is_reset,
		trial_info = {}
    }
    if req.is_reset == 0 --获取信息
	then
		--update 5 am;
		resp.trial_info = pve.update_trial_info(main_data);
    else --重置挑战
		resp.trial_info = pve.reset_trial_info(main_data)
	end
	
    local resp_buf = pb.encode("PVETrialInfoGetResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function trial_start_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local req = pb.decode("PVETrialStartReq", req_buf)
        local resp = {
            result = "FAIL",
            is_sweep = req.is_sweep
        }
        return 1, pb.encode("PVETrialStartResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        error("something error");
    end
end

function trial_start_do_logic(req_buf, user_name, main_data_buf, knight_buf, item_list_buf)
    local pb = require "protobuf"
    
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local knight_bag = pb.decode("KnightList", knight_buf)
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    
    local req = pb.decode("PVETrialStartReq", req_buf)

	--获取玩家的trial信息
	local t = main_data.PVE.watch_show--强制解开proto
    local trial_info = rawget(main_data.PVE, "trial_info")
    --if main_data.PVE.trial_info
    if not trial_info then
        trial_info = 
        {
            cur_reset_times = 0,
            state = "UnStart",
            cur_layer = 0,
            history_max_layer = 0,
            need_update = 1
        }
        rawset(main_data.PVE, "trial_info", trial_info)
    end
	
	local trial_state = trial_info.state
	local cur_layer = trial_info.cur_layer
	local history_max_layer = trial_info.history_max_layer

	local resp = {
        result = "OK"
    }

	local tar_layer = req.tar_layer
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    
	--//当状态为"UnStart", 如果history_max_layer >0 则扫荡，否则挑战第一层
	--//当状态为"Beated",挑战cur_layer+1
	--//当状态为"Failed",挑战cur_layer+1，且更新复活信息
	if trial_state == "Failed" then --需要复活
		--验证请求
		--assert(req.is_revive ~= 0, "req.is_revive:"..req.is_revive.."==0")
		--复活
		resp.cost_yb = pve.do_trial_revive(main_data, trial_info, task_struct)
	end

	if req.is_sweep ~= 0 then --扫荡
		--未开始挑战
		--assert(trial_state == "UnStart", "trial_state:"..trial_state.." not UnStart")
		assert(history_max_layer > 0, history_max_layer .. "history_max_layer check failed")
		resp.reward_sync = pve.do_trial_sweep(main_data, trial_info, item_list.item_list, task_struct)
	else --挑战
		--检查层数是否对
		--assert(tar_layer == cur_layer + 1, "tar_layer check failed")
		tar_layer = cur_layer + 1
		resp.fight_rcd, resp.reward_sync = pve.do_trial_fight(tar_layer, main_data, knight_bag.knight_list, trial_info, item_list.item_list, task_struct)
		
	end

	resp.is_sweep = req.is_sweep
	resp.is_revive = req.is_revive
	resp.trial_info = trial_info

    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end

    local resp_buf = pb.encode("PVETrialStartResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
	
    return resp_buf, main_data_buf, knight_buf, item_list_buf, ext_cmd, ext_buf
end
