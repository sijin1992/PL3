local logic_huodong = require "logic_huodong"
local cjsz_rank = cjsz_rank

function caishendao_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("CaishendaoResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function caishendao_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local cur_level = main_data.huodong.caishendao
    local get_money = logic_huodong.caishendao(main_data)
    local resp = {
        result = "OK",
        level = cur_level,
        next_level = main_data.huodong.caishendao,
        get_money = get_money,
        cur_money = main_data.money,
    }
    local resp_buf = pb.encode("CaishendaoResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function cangjian_getshoplist_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("CangjianGetShopListResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function cangjian_getshoplist_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("CangjianGetShopListReq", req_buf)
    local cangjian, rsync = logic_huodong.get_shoplist(req.force, main_data)
    local resp = {
        result = "OK",
        cangjian = cangjian,
        rsync = rsync,
    }
    local resp_buf = pb.encode("CangjianGetShopListResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function cangjian_shopping_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("CangjianShoppingResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function cangjian_shopping_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local req = pb.decode("CangjianShoppingReq", req_buf)
    local cangjian, rsync = logic_huodong.cangjian_shopping(req.item_id, main_data, item_list.item_list)
    local resp = {
        result = "OK",
        cangjian = cangjian,
        rsync = rsync,
    }
    local resp_buf = pb.encode("CangjianShoppingResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function cangjian_shengwang_shopping_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("CangjianShengwangShoppingResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function cangjian_shengwang_shopping_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local req = pb.decode("CangjianShengwangShoppingReq", req_buf)
    local rsync = logic_huodong.cangjian_shengwang_shopping(req.item_id,req.item_num, main_data, item_list.item_list)
    local resp = {
        result = "OK",
        item_id = req.item_id,
        rsync = rsync,
    }
    local resp_buf = pb.encode("CangjianShengwangShoppingResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function qiandao_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("QiandaoResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function qiandao_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local day_idx, rsync = logic_huodong.qiandao(main_data, item_list.item_list, task_struct)
    local resp = {
        result = "OK",
        idx = day_idx,
        rsync = rsync,
    }
    
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    local resp_buf = pb.encode("QiandaoResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf, ext_cmd, ext_buf
end

function czfl_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("ChongzhiRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function czfl_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    local req = pb.decode("ChongzhiRewardReq", req_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local rsync = logic_huodong.czfl(main_data, req.level, item_list.item_list)
    local resp = {
        result = "OK",
        level = req.level,
        rsync = rsync,
		
    }
    
    local resp_buf = pb.encode("ChongzhiRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function get_czfl_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("ChongzhiResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_czfl_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local r, chongzhi = global_huodong.check_chongzhi(main_data)
    local config = nil
    if chongzhi then
        local huodong = global_huodong.get_huodong(main_data,"chongzhi")
        config = huodong.reward_list
    end
    local huodong = global_huodong.get_huodong(main_data,"chongzhi")
    local resp = {
        result = "OK",
        chongzhi = chongzhi,
		config = config,
    }
    
    local resp_buf = pb.encode("ChongzhiResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function huodong_list_feature(step, req, user_name)
    local pb = require "protobuf"
    if step == 0 then
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("HuodongListResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function huodong_list_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local list = global_huodong.get_all_huodong(main_data)

    local resp = {
        result = "OK",
        huodong_list = {huodong_list = list}
    }
    local resp_buf = pb.encode("HuodongListResp", resp)
    return resp_buf, main_data_buf
end

function cjsz_top50_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("CjszTop50Resp", resp)
	elseif step == 1 then
        return datablock.main_data, user_name
    else
        error("something error");
    end
end

function cjsz_top50_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local resp = {
        result = "OK",
        rsync = {
            rank_list = cjsz_rank.get_top50(),
            total_sw = cjsz_rank.get_global_sw(),
            self_rank = cjsz_rank.get_self_rank(user_name),
        },
    }
	--添加奖励信息
	local main_data = pb.decode("UserInfo", main_data_buf)
	local cangjian_data = global_huodong.get_huodong(main_data,"cangjian")
	local rank_list = resp.rsync.rank_list
	for k1, v1 in ipairs(rank_list) do --每个排名清除奖励
		local t = v1.sex
		rawset(v1, "reward", nil)
		--v1.reward = nil
	end
	local thuodong = main_data.huodong
    local t = thuodong.cangjian.next_time
    local cangjian = rawget(thuodong, "cangjian")
    if cangjian and cangjian.sub_id == cangjian_data.sub_id then --在活动里
		local huodong_idx = 432010000 + cangjian.sub_id
		for k,v in ipairs(Cang_Rank_conf.index) do --每个配置
			local conf = Cang_Rank_conf[v]
			if conf.Activity_ID == huodong_idx then --正确的活动配置
				--按排名设置奖励
				for k1, v1 in ipairs(rank_list) do --每个排名设置
				    if k == 1 then
				        --print(k1, v1, v1.reward)
				    end
				    --local t = v1.reward.item_list
					local reward = rawget(v1, "reward")
					if reward == nil and conf.Rank >= k1 then --是否要设置
						v1.reward = { item_list = {}, }
						local rewardStr = conf.Reward
						if rewardStr and #rewardStr >= 2 then --存在奖励
							for i = 1, #rewardStr, 2  do
								table.insert(v1.reward.item_list, {id = rewardStr[i], num = rewardStr[i+1]})
							end
						end --存在奖励
						break --断开
					end --是否要设置
				end --每个排名设置
			end --正确的活动配置
		end --每个配置
	end --在活动里
    
    local resp_buf = pb.encode("CjszTop50Resp", resp)
    return resp_buf, main_data_buf
end

function cjsz_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("CangjianRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function cjsz_reward_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    local req = pb.decode("CangjianRewardReq", req_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local rsync = logic_huodong.cangjian_reward(main_data, item_list.item_list, req.reward_idx)
    local resp = {
        result = "OK",
        reward_idx = req.reward_idx,
        rsync = rsync,
        cangjian = main_data.huodong.cangjian
    }
    
    local resp_buf = pb.encode("CangjianRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function cjsz_exchange_list_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("CangjianGetExchangeListResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function cjsz_exchange_list_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local resp = {
        result = "OK",
        sw_exchange = {}, --新增兑换
    }
	local thuodong = main_data.huodong
	local cangjian_data = global_huodong.get_huodong(main_data,"cangjian")
    local t = thuodong.cangjian.next_time
    local cangjian = rawget(thuodong, "cangjian")
    if cangjian and cangjian.sub_id == cangjian_data.sub_id then --在活动里
		local huodong_idx = 432010000 + cangjian.sub_id
		for k,v in ipairs(Cang_Shop_conf.index) do
			local conf = Cang_Shop_conf[v]
			if conf.Activity_ID == huodong_idx then
				local exchange_item = {
					shopid = conf.CShop_ID,
					need_sw = conf.Devote,
					item = {
						id = conf.CShop_Item,
						num = 1,
					}
				}
				table.insert(resp.sw_exchange, exchange_item)
			end
		end
	end
	--printtab(resp.sw_exchange, "resp.sw_exchange")
    local resp_buf = pb.encode("CangjianGetExchangeListResp", resp)
    return resp_buf, main_data_buf
end

function cjsz_total_sw_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("CangjianTotalSWResp", resp)
	elseif step == 1 then
        return datablock.main_data, user_name
    else
        error("something error");
    end
end

function cjsz_total_sw_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", main_data_buf)
    local resp = nil
    local cangjian_data = global_huodong.get_huodong(main_data,"cangjian")
    if cangjian_data then
        resp = {
            result = "OK",
            total_sw = cjsz_rank.get_global_sw(),
			conf = {}, --新增，配置
        }
    else
        resp = {result = "FAIL"}
    end
	local thuodong = main_data.huodong
    local t = thuodong.cangjian.next_time
    local cangjian = rawget(thuodong, "cangjian")
    if cangjian and cangjian.sub_id == cangjian_data.sub_id then
		local huodong_idx = 432010000 + cangjian.sub_id
		for k,v in ipairs(Cang_Quan_conf.index) do
			local conf = Cang_Quan_conf[v]
			if conf.Activity_ID == huodong_idx then
				local new_t = {
					quan_id  = conf.Quan_ID,
					need_sw = conf.Devote,
					reward = {
						item_list = {},
					},
					reward_flag = cangjian.reward_list[conf.Quan_ID % 10000]
				}
			 
				local rewardStr = conf.Reward_List
				if rewardStr and #rewardStr >= 2 then
				for i = 1, #rewardStr, 2  do
					table.insert(new_t.reward.item_list, {id = rewardStr[i], num = rewardStr[i+1]})
				end
			end
				table.insert(resp.conf, new_t)
			end
		end
	end
    local resp_buf = pb.encode("CangjianTotalSWResp", resp)
    return resp_buf, main_data_buf
end

function day7_gift_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("Day7GiftResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function day7_gift_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    local req = pb.decode("Day7GiftReq", req_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local rsync = logic_huodong.day7_gift(main_data, req.day_id, item_list.item_list)
    local resp = {
        result = "OK",
        day_id = req.day_id,
        rsync = rsync,
        day7 = main_data.huodong.day7
    }
    
    local resp_buf = pb.encode("Day7GiftResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function level_gift_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("LevelGiftResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function level_gift_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    local req = pb.decode("LevelGiftReq", req_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local rsync = logic_huodong.level_gift(main_data, req.level_id, item_list.item_list)
    local resp = {
        result = "OK",
        level_id = req.level_id,
        rsync = rsync,
        level_gift = main_data.huodong.level_gift
    }
    
    local resp_buf = pb.encode("LevelGiftResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function get_newtask_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetNewTaskResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function get_newtask_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local t = main_data.huodong.new_task_list.regist_dayid
    local new_task_list = rawget(main_data.huodong, "new_task_list")
    assert(new_task_list)
    local resp = {
        result = "OK",
        new_task_list = new_task_list
    }
    local resp_buf = pb.encode("GetNewTaskResp", resp)
    return resp_buf, main_data_buf
end

function newtask_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("NewTaskRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function newtask_reward_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    local req = pb.decode("NewTaskRewardReq", req_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local rsync = logic_huodong.new_task_reward(main_data, req.day_id, item_list.item_list)
    local resp = {
        result = "OK",
        day_id = req.day_id,
        rsync = rsync,
        new_task_list = main_data.huodong.new_task_list
    }
    
    local resp_buf = pb.encode("NewTaskRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function cdkey_gift_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("CDKEY_Resp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function cdkey_gift_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    local req = pb.decode("CDKEY_Req", req_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local resp = {result = "OK"}
    local r = math.random(10)
    if r == 6 then
        resp.result = "FAIL"
    elseif r == 7 then
        resp.result = "USED"
    elseif r == 8 then
        resp.result = "CANT_USED"
    elseif r == 9 then
        resp.result = "UNKNOW"
    elseif r == 10 then
        resp.result = "SELF_USED"
    else
        local rsync = logic_huodong.cdkey_reward(main_data, item_list.item_list)
        resp.rsync = rsync
        resp.cdkey = req.cdkey
    end
    
    local resp_buf = pb.encode("CDKEY_Resp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function get_ljcz_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetLeijiChongzhiResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function get_ljcz_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("GetLeijiChongzhiReq", req_buf)
    local ret = nil
    if req.id == 57001 then
        ret = logic_huodong.get_meiri_leiji(main_data)
    else--60001
        ret = logic_huodong.get_jieduan_leiji(main_data)
    end
    local resp = {
        result = "OK",
        id = req.id,
        data = ret
    }    
    local resp_buf = pb.encode("GetLeijiChongzhiResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function get_dbcz_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetDanbiChongzhiResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function get_dbcz_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("GetDanbiChongzhiReq", req_buf)
    local ret = nil
    ret = logic_huodong.get_meiri_danbi(main_data)
    local resp = {
        result = "OK",
        id = req.id,
        data = ret
    }    
    local resp_buf = pb.encode("GetDanbiChongzhiResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function get_xffl_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetXiaofeiHuodongResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function get_xffl_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("GetXiaofeiHuodongReq", req_buf)
    local ret = nil
    ret = logic_huodong.get_meiri_xiaofei(main_data)
    local resp = {
        result = "OK",
        id = req.id,
        data = ret
    }    
    local resp_buf = pb.encode("GetXiaofeiHuodongResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function get_ljxffl_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetXiaofeiHuodongResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function get_ljxffl_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("GetXiaofeiHuodongReq", req_buf)
    local ret = nil
    ret = logic_huodong.get_leiji_xiaofei(main_data)
    local resp = {
        result = "OK",
        id = req.id,
        data = ret
    }    
    local resp_buf = pb.encode("GetXiaofeiHuodongResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function get_login_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetLoginHuodongResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function get_login_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("GetLoginHuodongReq", req_buf)
    local ret = nil
    ret = logic_huodong.get_login(main_data)
    local resp = {
        result = "OK",
        id = req.id,
        data = ret
    }    
    local resp_buf = pb.encode("GetLoginHuodongResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end



function ljcz_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("LeijiChongzhiRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function ljcz_reward_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("LeijiChongzhiRewardReq", req_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local ret = nil
    local rsync = nil
    if req.id == 57001 then
        ret, rsync = logic_huodong.meiri_leiji_reward(main_data, item_list.item_list, req.idx)
    else--60001
        ret, rsync = logic_huodong.jieduan_leiji_reward(main_data, item_list.item_list, req.idx)
    end
    local resp = {
        result = "OK",
        id = req.id,
        data = ret,
        rsync = rsync,
    }    
    
    local resp_buf = pb.encode("LeijiChongzhiRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function dbcz_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("DanbiChongzhiRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function dbcz_reward_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("DanbiChongzhiRewardReq", req_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local ret = nil
    local rsync = nil
    ret, rsync = logic_huodong.meiri_danbi_reward(main_data, item_list.item_list, req.idx)
    local resp = {
        result = "OK",
        id = req.id,
        data = ret,
        rsync = rsync,
    }    
    
    local resp_buf = pb.encode("DanbiChongzhiRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function xffl_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("XiaofeiHuodongRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function xffl_reward_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("XiaofeiHuodongRewardReq", req_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local ret = nil
    local rsync = nil
    ret, rsync = logic_huodong.meiri_xiaofei_reward(main_data, item_list.item_list, req.idx)
    local resp = {
        result = "OK",
        id = req.id,
        data = ret,
        rsync = rsync,
    }    
    
    local resp_buf = pb.encode("XiaofeiHuodongRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf,item_list_buf
end

function ljxffl_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("XiaofeiHuodongRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function ljxffl_reward_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("XiaofeiHuodongRewardReq", req_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local ret = nil
    local rsync = nil
    ret, rsync = logic_huodong.leiji_xiaofei_reward(main_data, item_list.item_list, req.idx)
    local resp = {
        result = "OK",
        id = req.id,
        data = ret,
        rsync = rsync,
    }    
    
    local resp_buf = pb.encode("XiaofeiHuodongRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf,item_list_buf
end

function lxdl_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("LoginHuodongRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function lxdl_reward_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("LoginHuodongRewardReq", req_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local ret = nil
    local rsync = nil
    ret, rsync = logic_huodong.lxdl_reward(main_data, item_list.item_list, req.idx)
    local resp = {
        result = "OK",
        id = req.id,
        data = ret,
        rsync = rsync,
    }    
    
    local resp_buf = pb.encode("LoginHuodongRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf,item_list_buf
end

function get_cz_rank_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 0, pb.encode("GetChongzhiHongbaoListResp", resp)
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function get_cz_rank_do_logic(req_buf, user_name)
    local pb = require "protobuf"
    local top10, self, self_rank = logic_huodong.get_cz_rank(user_name)
    local resp = {
        result = "OK",
        list = top10,
        self=self,
        self_rank = self_rank,
    }    
    
    local resp_buf = pb.encode("GetChongzhiHongbaoListResp", resp)
    return resp_buf
end

function new_level_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("NewLevelResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function new_level_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local ret = nil
    ret = logic_huodong.get_new_level(main_data)
    local resp = {
        result = "OK",
        level_gift = ret
    }    
    local resp_buf = pb.encode("NewLevelResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function new_level_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("NewLevelRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function new_level_reward_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("NewLevelRewardReq", req_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local ret = nil
    local rsync = nil
    ret, rsync = logic_huodong.new_level_reward(main_data, item_list.item_list, req.level_id)
    local resp = {
        result = "OK",
        level_id = req.level_id,
        level_gift = ret,
        rsync = rsync,
    }    
    
    local resp_buf = pb.encode("NewLevelRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function duihuan_info_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("DuihuanInfoResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function duihuan_info_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list, item = logic_huodong.get_duihuan(main_data)
    local resp = {
        result = "OK",
        list = item_list,
        item_id = item
    }    
    local resp_buf = pb.encode("DuihuanInfoResp", resp)
    return resp_buf, main_data_buf
end

function duihuan_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("DuihuanResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function duihuan_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("DuihuanReq", req_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local rsync = logic_huodong.duihuan(main_data, item_list.item_list, req.id, req.num)
    local resp = {
        result = "OK",
        req = req,
        rsync = rsync,
    }    
    
    local resp_buf = pb.encode("DuihuanResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function tianji_info_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("TianJiInfoResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function tianji_info_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local resp = logic_huodong.get_tianji(main_data)
        
    local resp_buf = pb.encode("TianJiInfoResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function tianji_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("TianJiResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function tianji_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("TianJiReq", req_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local rsync,rsyncdata = logic_huodong.open_tianji(main_data, item_list.item_list, req.isvip)
    local resp = {
        result = "OK",
        req = req,
        rsync = rsync,
        rsyncdata = rsyncdata
    }    
    
    local resp_buf = pb.encode("TianJiResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function tianji_reward_info_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("TianJiRewardInfoResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function tianji_reward_info_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local list = logic_huodong.tianji_reward_info(main_data)
    local resp = {
        result = "OK",
        list = list
    }
    local resp_buf = pb.encode("TianJiRewardInfoResp", resp)
    return resp_buf, main_data_buf
end

function tianji_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("TianJiRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function tianji_reward_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("TianJiRewardReq", req_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local rsync, rsyncdata = logic_huodong.tianji_reward(main_data, item_list.item_list, req.idx)
    local resp = {
        result = "OK",
        reqidx = req.idx,
        rsync = rsync,
        rsyncdata = rsyncdata
    }    
    
    local resp_buf = pb.encode("TianJiRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function limitshop_info_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("LimitShopInfoResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function limitshop_info_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local list = logic_huodong.limit_shop_info(main_data)
    local resp = {
        result = "OK",
        list = list
    }
    local resp_buf = pb.encode("LimitShopInfoResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end


function limitshopping_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("LimitShopResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function limitshopping_do_logic(req_buf, user_name, main_data_buf, item_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end 
    local req = pb.decode("LimitShopReq", req_buf)
    local rsync,buytime = logic_huodong.limit_shopping(main_data, item_list.item_list, req.idx)
    local resp = {
        result = "OK",
        reqidx = req.idx,
        rsync = rsync,
        buytime = buytime,
    }
    local resp_buf = pb.encode("LimitShopResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_buf
end


function qhaoxia_info_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("QHaoXiaGetResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function qhaoxia_info_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local resp = logic_huodong.get_qhaoxia(main_data)
        
    local resp_buf = pb.encode("QHaoXiaGetResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function qhaoxia_choujiang_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("QHaoXiaChouJiangResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function qhaoxia_choujiang_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("QHaoXiaChouJiangReq", req_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    if not rawget(knight_bag, "knight_list") then knight_bag = {knight_list = {}} end

    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local notify_struct = {ret = false, data = nil}
    local resp = logic_huodong.qhaoxia_choujiang(main_data, knight_bag.knight_list, item_list.item_list, req, task_struct, notify_struct) 
    
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
    
    local resp_buf = pb.encode("QHaoXiaChouJiangResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_list_buf = pb.encode("KnightList", knight_bag)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, knight_list_buf, item_list_buf, ext_cmd, ext_buf,ext_cmd2,ext_buf2
end

function qhaoxia_reward_info_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("QHaoXiaRewardInfoResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function qhaoxia_reward_info_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local list = logic_huodong.qhaoxia_reward_info(main_data)
    local resp = {
        result = "OK",
        list = list
    }
    local resp_buf = pb.encode("QHaoXiaRewardInfoResp", resp)
    return resp_buf, main_data_buf
end

function qhaoxia_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("QHaoXiaRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error")
        return nil,nil
    end
end

function qhaoxia_reward_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("QHaoXiaRewardReq", req_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local rsync, rsyncdata = logic_huodong.qhaoxia_reward(main_data, item_list.item_list, req.idx)
    local resp = {
        result = "OK",
        reqidx = req.idx,
        rsync = rsync,
        rsyncdata = rsyncdata
    }    
    
    local resp_buf = pb.encode("QHaoXiaRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end
