local logic_user = require "logic_user"
local core_user = require "core_user_funcs"
local core_power = require "core_calc_power"
local chat_log = require "chat_log"

function get_knight_bag_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
		local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetKnightBagResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_knight_bag_do_logic(req, user_name, main_data, knight_bag_buf)
    local pb = require "protobuf"
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
	local resp = {
        result = "OK",
		knight_bag = knight_bag.knight_list,
    }
    local resp_buf = pb.encode("GetKnightBagResp", resp)
    return resp_buf, main_data, knight_bag_buf
end

function get_item_package_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetKnightBagResp", resp)
    elseif step == 1 then
        return datablock.item_package, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_item_package_do_logic(req, user_name, item_package_buf)
    local pb = require "protobuf"
    local item_package = pb.decode("ItemList", item_package_buf)
    if(rawget(item_package, "item_list")) == nil then
        item_package.item_list = {}
    end
    
    local resp = {
        result = "OK",
        item_package = item_package,
    }
    local resp_buf = pb.encode("GetItemPackageResp", resp)
    --local item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, item_package_buf
end

function set_zhenxing_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("SetZhenxingResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function set_zhenxing_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf)
    local pb = require "protobuf"
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("SetZhenxingReq", req_buf)
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    local change_list = logic_user.set_zhenxing(main_data, knight_bag.knight_list, req.zhenxing, user_name)
    
    local resp = {
        result = "OK",
        zhenxing = main_data.zhenxing,
        add_new_player = core_user.set_anp_buzhen(main_data),
        change_list = change_list
    }
    if req.add_new_player > 0 then
        local t = main_data.ext_data.new_player
        main_data.ext_data.new_player = req.add_new_player;
    end
    local resp_buf = pb.encode("SetZhenxingResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    return resp_buf, main_data_buf, knight_bag_buf
end

function lead_starup_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("LeadStarUpResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function lead_starup_do_logic(req_buf, user_name, main_data_buf, bag_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_package = pb.decode("ItemList", bag_list_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    local rsync = logic_user.lead_starup(main_data, item_package.item_list, user_name)
    local resp = {
        result = "OK",
        lead = main_data.lead,
        rsync = rsync,
        add_new_player = core_user.set_anp_lead_star(main_data)
    }
    local resp_buf = pb.encode("LeadStarUpResp", resp)
    local main_data_buf = pb.encode("UserInfo", main_data)
    local item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, item_package_buf
end

function open_book_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("OpenBookResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function open_book_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf)
    local pb = require "protobuf"
    local req = pb.decode("OpenBookReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local book_info = logic_user.open_book(req.book_id, main_data, user_name, task_struct, knight_bag.knight_list)
    local resp = {
        result = "OK",
        book = book_info,
        add_new_player = core_user.set_anp_open_book(main_data)
    }
    if req.add_new_player > 0 then
        local t = main_data.ext_data.new_player
        main_data.ext_data.new_player = req.add_new_player;
    end
    local resp_buf = pb.encode("OpenBookResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    return resp_buf, main_data_buf, knight_bag_buf, ext_cmd, ext_buf
end

function book_levelup_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("BookLevelUpResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function book_levelup_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("BookLevelUpReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_pack = pb.decode("ItemList", item_package_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    if rawget(item_pack, "item_list") == nil then item_pack = {item_list = {}} end
    local book_info = nil
    local rsync = nil
    book_info, rsync = logic_user.book_levelup(req.book_id, main_data, item_pack.item_list, req.item_list, user_name, knight_bag.knight_list )
    local resp = {
        result = "OK",
        book = book_info,
        rsync_item = rsync.item_list,
        add_new_player = core_user.set_anp_booklevelup(main_data)
    }
    local resp_buf = pb.encode("BookLevelUpResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_package_buf = pb.encode("ItemList", item_pack)
    return resp_buf, main_data_buf, knight_bag_buf,item_package_buf
end

function open_lover_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("OpenLoverResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function open_lover_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_pack_buf)
    local pb = require "protobuf"
    local req = pb.decode("OpenLoverReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_pack = pb.decode("ItemList", item_pack_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    if rawget(item_pack, "item_list") == nil then item_pack = {item_list = {}} end
    local lover_info, rsync_item = logic_user.open_lover(req.lover_id, main_data, item_pack.item_list, user_name, knight_bag.knight_list)
    local resp = {
        result = "OK",
        lover = lover_info,
        rsync_item = rsync_item,
    }
    local resp_buf = pb.encode("OpenLoverResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_pack_buf = pb.encode("ItemList", item_pack)
    return resp_buf, main_data_buf, knight_bag_buf, item_pack_buf
end

function lover_levelup_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("LoverLevelUpResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function lover_levelup_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("LoverLevelUpReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_pack = pb.decode("ItemList", item_package_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    if rawget(item_pack, "item_list") == nil then item_pack = {item_list = {}} end
    local lover_info = nil
    local rsync = nil
    lover_info, rsync = logic_user.lover_levelup(req.lover_id, main_data, item_pack.item_list, user_name, knight_bag.knight_list)
    local resp = {
        result = "OK",
        lover = lover_info,
        rsync_item = rsync,
    }
    local resp_buf = pb.encode("LoverLevelUpResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_package_buf = pb.encode("ItemList", item_pack)
    return resp_buf, main_data_buf, knight_bag_buf,item_package_buf
end

function update_timestamp_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("UpdateTimeStampResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.mail_list + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function update_timestamp_do_logic(req_buf, user_name, main_data_buf, item_buf, mail_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    local mail_list = pb.decode("MailList", mail_buf)
    if rawget(item_list, "item_list") == nil then item_list = {item_list = {}} end
    if rawget(mail_list, "mail_list") == nil then mail_list = {mail_list = {}} end
    local lover_info = nil
    local rsync = nil
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local unread_mail = logic_user.update_timestamp(main_data, item_list.item_list, mail_list.mail_list, user_name, task_struct)
    --充值，cdkey，微信，红包
    --0，默认，1，强制关，2，强制开
    local top_act_flag_list = {0,0,0,2}
    if server_platform == 1 or server_platform == 2 then
        top_act_flag_list = {0,0,0,0}
    end
    
    local resp = {
        result = "OK",
        tili = main_data.tili,
        last_reflesh_tili = main_data.timestamp.last_reflesh_tili,
        unread_mail_num = unread_mail,
        top_act_flag_list = top_act_flag_list
    }
    
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    local ext_cmd2 = nil
    local ext_buf2 = nil
    local notify = notify_sys.get_message(main_data.user_name)
    if notify then
        ext_buf2 = pb.encode("NotifyRefleshResp", {msg_list = notify})
        ext_cmd2 = 0x1037
    end
    
    local resp_buf = pb.encode("UpdateTimeStampResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_buf = pb.encode("ItemList", item_list)
    mail_buf = pb.encode("MailList", mail_list)
    return resp_buf, main_data_buf, item_buf, mail_buf, ext_cmd, ext_buf,ext_cmd2,ext_buf2
end

function money2gold_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("Money2GoldResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function money2gold_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local ret = logic_user.money2gold(main_data, task_struct)
    
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    
    local resp = {
        result = "OK",
        rsync = ret,
    }
    local resp_buf = pb.encode("Money2GoldResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf, ext_cmd, ext_buf
end

function money2hp_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("Money2HPResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function money2hp_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local ret = logic_user.money2hp(main_data, task_struct)
    local resp = {
        result = "OK",
        rsync = ret,
    }
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    local resp_buf = pb.encode("Money2HPResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf, ext_cmd, ext_buf
end

function choujiang_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("ChouJiangResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function choujiang_do_logic(req_buf, user_name, main_data_buf, knight_list_buf, item_list_buf)
    local pb = require "protobuf"
    local req = pb.decode("ChouJiangReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_list = pb.decode("KnightList", knight_list_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if not rawget(knight_list, "knight_list") then knight_list = {knight_list = {}} end
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local notify_struct = {ret = false, data = nil}
    local ret, sevenweapon = logic_user.choujiang(req.type, req.is_free, main_data, knight_list.knight_list, item_list.item_list,
        task_struct, notify_struct)
    
    local add_new_player = 0
    local next5star = 2 - (main_data.choujiang.total_money10_num - 1) % 2
        
    if req.type == 1 then
        add_new_player = core_user.set_anp_choujiang_g(main_data)
    end
    local resp = {
        result = "OK",
        req = req,
        rsync = ret,
        add_new_player = add_new_player,
        next5star = next5star,
        sevenweapon = sevenweapon,
    }
    if req.add_new_player > 0 then
        local t = main_data.ext_data.new_player
        main_data.ext_data.new_player = req.add_new_player;
    end
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
    
    local resp_buf = pb.encode("ChouJiangResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_list_buf = pb.encode("KnightList", knight_list)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, knight_list_buf, item_list_buf, ext_cmd, ext_buf,ext_cmd2,ext_buf2
end

function sell_item_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("SellItemResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function sell_item_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local req = pb.decode("SellItemReq", req_buf)
	assert(req.item.item_num > 0, "item_num:"..req.item.item_num.." <= 0")

    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if rawget(item_list, "item_list") == nil then item_list = {item_list = {}} end
    
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local ret = logic_user.sell_item(req.item.item_id, req.item.item_num, main_data, item_list.item_list, task_struct)
    local resp = {
        result = "OK",
        rsync = ret,
    }
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    local resp_buf = pb.encode("SellItemResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf, ext_cmd, ext_buf
end

function use_item_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("UseItemResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function use_item_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local req = pb.decode("UseItemReq", req_buf)
	local item_num = req.item.num
	local item_id = req.item.id
	assert(item_num > 0, "item_num:"..item_num.." <= 0")

    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if rawget(item_list, "item_list") == nil then item_list = {item_list = {}} end
    
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local ret = logic_user.use_item(item_id, item_num, main_data, item_list.item_list, task_struct)
    local resp = {
        result = "OK",
        rsync = ret,
    }
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    local resp_buf = pb.encode("UseItemResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf, ext_cmd, ext_buf
end



function get_chengjiu_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetChengjiuRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_chengjiu_reward_do_logic(req_buf, user_name, main_data_buf, item_buf)
    local pb = require "protobuf"
    local req = pb.decode("GetChengjiuRewardReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    
    local chengjiu, rsync = logic_user.get_chengjiu_reward(main_data, item_list.item_list, req.chengjiu_id)
    local resp = {
        result = "OK",
        cur_chengjiu = chengjiu,
        rsync = rsync
    }
    local resp_buf = pb.encode("GetChengjiuRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_buf
end

function get_daily_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetDailyRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_daily_reward_do_logic(req_buf, user_name, main_data_buf, item_buf)
    local pb = require "protobuf"
    local req = pb.decode("GetDailyRewardReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local daily, rsync = logic_user.get_daily_reward(main_data, item_list.item_list, req.daily_id, task_struct)
    local resp = {
        result = "OK",
        cur_daily = daily,
        rsync = rsync
    }
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    local resp_buf = pb.encode("GetDailyRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_buf, ext_cmd, ext_buf
end

function get_task_list_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetTaskListResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_task_list_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local req = pb.decode("GetTaskListReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    
    local task = nil
    local chengjiu = nil
    local daily = nil
    if req.task == 1 then task = main_data.task_list end
    if req.chengjiu == 1 then chengjiu = main_data.chengjiu end
    if req.daily == 1 then daily = main_data.daily end
    local resp = {
        result = "OK",
        req = req,
        task_list = task,
        chengjiu_list = chengjiu,
        daily_list = daily,
    }

    local resp_buf = pb.encode("GetTaskListResp", resp)
    
    --main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function get_vip_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("VIPRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_vip_reward_do_logic(req_buf, user_name, main_data_buf, knight_buf, item_buf)
    local pb = require "protobuf"
    local req = pb.decode("VIPRewardReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local knight_list = pb.decode("KnightList", knight_buf)
    if not rawget(knight_list, "knight_list") then knight_list = {knight_list = {}} end
    
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local notify_struct = {ret = false, data = nil}
    local rsync = logic_user.get_vip_reward(req.vip_idx, main_data, knight_list.knight_list, item_list.item_list,
        task_struct, notify_struct)
    local resp = {
        result = "OK",
        rsync = rsync,
        vip_idx = req.vip_idx,
    }
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
    local resp_buf = pb.encode("VIPRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_buf = pb.encode("KnightList", knight_list)
    item_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, knight_buf, item_buf, ext_cmd, ext_buf,ext_cmd2,ext_buf2
end

function test_add_money_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            sid = "err",
            orderno = "err",
            amount = 0,
            cur_money = 0,
            cur_vip = 0,
            total_money = 0,
        }
        return 1, pb.encode("AddMoneyCallBack", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

--DEBUG_CZ = 1
function test_add_money_do_logic(req_buf, user_name, main_data_buf)
    assert(DEBUG_CZ)
    local pb = require "protobuf"
    local req = pb.decode("TestHttpAddMondyReq", req_buf)
    local money = req.money
    local yueka_flag = 0
    local conf_id
    local new_id
    local bag_list_buf = pb.encode("ItemList", {item_list = {}})
    main_data_buf, bag_list_buf, yueka_flag, conf_id, new_id = platform_add_money(main_data_buf, bag_list_buf, money, req.extinfo)
    local main_data = pb.decode("UserInfo", main_data_buf)
    
    local resp = {
        sid = req.sid,
        orderno = req.orderno,
        amount = money,
        cur_money = main_data.money,
        cur_vip = main_data.vip_lev,
        total_money = main_data.ext_data.total_money,
        item_id = conf_id,
        buqian = 0,
        new_item_id = new_id
    }
    
    local ext_cmd = nil
    local ext_buf = nil
    
    if yueka_flag == 1 then
        resp.yueka = main_data.ext_data.yueka
        ext_cmd = 0x1035
        local d = nil
        for k,v in ipairs(main_data.daily.daily_list) do
            if v.id == 3106001 then
                d = v
                break
            end
        end
        local r = {
            huoyue = 1,
            daily_list = {d};
        }
        ext_buf = pb.encode("TaskRefleshResp", r)
    elseif yueka_flag == 2 then
        ext_cmd = 0x1035
        local d = nil
        for k,v in ipairs(main_data.daily.daily_list) do
            if v.id == 3111001 then
                d = v
                break
            end
        end
        local r = {
            huoyue = 1,
            daily_list = {d};
        }
        ext_buf = pb.encode("TaskRefleshResp", r)
        resp.zsyk = 1
    end
    local t = main_data.huodong.qiandao.status
    if t == 2 then resp.buqian = 1 end

    local resp_buf = pb.encode("AddMoneyCallBack", resp)
    return resp_buf, main_data_buf, ext_cmd, ext_buf
end

function client_code_set_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("ClientCodeSetResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function client_code_set_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local req = pb.decode("ClientCodeSetReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    assert(req.code_id == 1)
    
    core_user.set_anp_touchclose(main_data, req.code_value)
    local resp = {
        result = "OK",
        req = req,
    }

    local resp_buf = pb.encode("ClientCodeSetResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function get_extdata_at5am_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetExtDataAt5amResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_extdata_at5am_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    
    local resp = {
        result = "OK",
        rsync = {
            ext_data = main_data.ext_data
        }
    }
    local resp_buf = pb.encode("GetExtDataAt5amResp", resp)
    return resp_buf, main_data_buf
end

function get_tili_reward_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetTiliRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_tili_reward_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("GetTiliRewardReq", req_buf)
    logic_user.get_tili_reward(main_data, req.reward_id)
    local resp = {
        result = "OK",
        rsync = {
            tili = main_data.tili,
            get_tili = main_data.timestamp.get_tili
        }
    }
    local resp_buf = pb.encode("GetTiliRewardResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function xy_transform_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("TransformResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function xy_transform_do_logic(req_buf, user_name, main_data_buf, item_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end 
    local req = pb.decode("TransformReq", req_buf)
    local ret = logic_user.transform(main_data, item_list.item_list, req.item_list)
    local resp = {
        result = "OK",
        rsync = ret
    }
    local resp_buf = pb.encode("TransformResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_buf
end

function reflesh_xyshop_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("XYRefleshResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function reflesh_xyshop_do_logic(req_buf, user_name, main_data_buf, item_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local req = pb.decode("XYRefleshReq", req_buf)
    local xy_shop,rsync = logic_user.reflesh_xyshop(main_data, item_list.item_list, req.use_money)
    local resp = {
        result = "OK",
        xyshop = xy_shop,
        rsync = rsync
    }
    local resp_buf = pb.encode("XYRefleshResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_buf
end

function xyshopping_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("XYShoppingResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function xyshopping_do_logic(req_buf, user_name, main_data_buf, item_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end 
    local req = pb.decode("XYShoppingReq", req_buf)
    local ret = logic_user.xy_shopping(main_data, item_list.item_list, req.item_idx)
    local resp = {
        result = "OK",
        item_idx = req.item_idx,
        rsync = ret
    }
    local resp_buf = pb.encode("XYShoppingResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_buf
end

function wxjy_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("WXJYResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function wxjy_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("WXJYReq", req_buf)
    logic_user.wxjy(main_data, req.WXJY_idx)
    local resp = {
        result = "OK",
        rsync = {
            ghost = main_data.xyshop.ghost,
            wxjy = main_data.wxjy,
        }
    }
    local resp_buf = pb.encode("WXJYResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function get_huodong_flag_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetHuodongFlagResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_huodong_flag_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    --奇遇
    local qiyu_struct = core_user.get_qiyu(main_data)
    core_user.check_qiyu(qiyu_struct.qiyu_list)
    main_data.ext_data.huodong.qiyu = rawlen(qiyu_struct.qiyu_list)
    
    local resp = {
        result = "OK",
        huodong = main_data.ext_data.huodong,
    }
    local resp_buf = pb.encode("GetHuodongFlagResp", resp)
    return resp_buf, main_data_buf
end

function vipshopping_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("VIPShoppingResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function vipshopping_do_logic(req_buf, user_name, main_data_buf, item_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end 
    local req = pb.decode("VIPShoppingReq", req_buf)
    local ret,goods_entry = logic_user.vip_shopping(main_data, item_list.item_list, req.item_idx, req.item_num)
    local resp = {
        result = "OK",
        item_idx = req.item_idx,
        rsync = ret,
        vip_goods = goods_entry
    }
    local resp_buf = pb.encode("VIPShoppingResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_buf
end

function vipgift_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("VIPGiftResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function vipgift_do_logic(req_buf, user_name, main_data_buf, item_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end 
    local req = pb.decode("VIPGiftReq", req_buf)
    local ret,gift_entry = logic_user.vip_gift(main_data, item_list.item_list, req.item_idx)
    
    local resp = {
        result = "OK",
        item_idx = req.item_idx,
        rsync = ret,
        entry = gift_entry
    }
    
    local resp_buf = pb.encode("VIPGiftResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_buf
end

function choujiang_huodong_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("ChoujiangHuodongResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        error("something error");
    end
end
local choujiang = require "choujiang"
function choujiang_huodong_do_logic(req_buf, user_name,main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local num = main_data.choujiang.total_money10_num
    local next5star = 1
    if num > 0 then
        next5star = 2 - (num - 1) % 2
    end
    local start_stamp = 0
    local end_stamp = 0
    local item_list = {}
    local t = global_huodong.get_choujiang()
    if t then
        start_stamp = t.start_stamp
        end_stamp = t.end_stamp
        table.insert(item_list, t.item)
    end
    local item_list_day, item_list_week = choujiang.getHaoxiaItems(main_data)
    local resp = {
        result = "OK",
        start_stamp = start_stamp,
        end_stamp = end_stamp,
        item_list = item_list,
        next5star = next5star,
        item_list_day = item_list_day,
        item_list_week = item_list_week,
    }
    local resp_buf = pb.encode("ChoujiangHuodongResp", resp)
    return resp_buf,main_data_buf
end

function open_chest_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("OpenChestResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function open_chest_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local req = pb.decode("OpenChestReq", req_buf)
    assert(req.item.item_num > 0, "item_num:"..req.item.item_num.." <= 0")

    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if rawget(item_list, "item_list") == nil then item_list = {item_list = {}} end
    
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local ret = logic_user.open_chest(main_data, item_list.item_list, req.item.item_id, req.item.item_num, task_struct)
    local resp = {
        result = "OK",
        rsync = ret,
    }
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    local resp_buf = pb.encode("OpenChestResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf, ext_cmd, ext_buf
end

function chat_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        local chatreq = pb.decode("ChatReq", req)
        if chatreq.channel == 1 then
            return 2, pb.encode("ChatResp", resp)
        elseif chatreq.channel == 2 then
            return 2, pb.encode("ChatResp", resp)
        else
            return 1, pb.encode("ChatResp", resp)
        end
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    elseif step == 2 then
        local pb = require "protobuf"
        local chatreq = pb.decode("ChatReq", req)
        if chatreq.channel == 1 then
            local recv_uid = chatreq.recver.uid
            assert(recv_uid and recv_uid ~= "")
            return datablock.main_data, recv_uid
        else
            return datablock.group_main, user_name
        end
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function chat_do_logic(req_buf, user_name, main_data_buf, item_list_buf, main_data_buf2)
    local pb = require "protobuf"
    local req = pb.decode("ChatReq", req_buf)
    local dirty = false
    for _,dirty_word in ipairs(dirty_word) do
        if string.find(req.msg, dirty_word) then
            dirty = true
            break
        end
    end
    if dirty then
        local resp = {
            result = "DIRTY",
            }
        local resp_buf = pb.encode("ChatResp", resp)
        if req.channel == 1 then
            return resp_buf, main_data_buf, item_list_buf, main_data_buf2
        else
            return resp_buf, main_data_buf, item_list_buf
        end
    end
    
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if rawget(item_list, "item_list") == nil then item_list = {item_list = {}} end
    
    local recver = nil
    local rsync = nil
    local recvs = {}
    if req.channel == 1 then
        local main_data2 = pb.decode("UserInfo", main_data_buf2)
        recver = {
            uid = main_data2.user_name,
            nickname = main_data2.nickname,
            vip = main_data2.vip_lev,
            sex = main_data2.lead.sex,
            level = main_data2.lead.level,
            star = main_data2.lead.star
        }
    elseif req.channel == 2 then
        local group_data = pb.decode("GroupMainData", main_data_buf2)
        local master = rawget(group_data, "master")
        if master then table.insert(recvs, master.username) end
        local master2 = rawget(group_data, "master2")
        if master2 then table.insert(recvs, master2.username) end
        local user_list = rawget(group_data, "user_list")
        if user_list then
            for k,v in ipairs(user_list) do
                table.insert(recvs, v.username)
            end
        end
    end
    
    local rsync = logic_user.do_cost_when_chat(main_data, item_list.item_list, req.channel)
    local resp = {
        result = "OK",
        rsync = rsync,
    }
    
    local send_msg = {req.msg}
    --[[ 原来客户端有个bug，服务器帮忙分割msg字符串，现在应该用不到了
    local send_msg = {}
    local chat_msg = req.msg
    local _, charnum = string.gsub(chat_msg, "[^\128-\193]", "")
    local ttt = {}
    for uchar in string.gmatch(chat_msg, "[%z\1-\127\194-\244][\128-\191]*") do
        table.insert(ttt, uchar)
    end
    
    local t_len = 0
    local t_str = ""
    local max_len = 12
    for k,v in ipairs(ttt) do
        t_str = t_str .. v
        t_len = t_len + 1
        if t_len == max_len then
            table.insert(send_msg, t_str)
            t_str = ""
            t_len = 0
        end
    end
    if t_len ~= 0 then
        table.insert(send_msg, t_str)
    end
    ]]
    --[[print(string.len(chat_msg), charnum)
    for k,v in ipairs(ttt) do
        print(k,v)
    end
    ]]
    local sender_uid = main_data.user_name
    local sender_nickname = main_data.nickname
    if string.sub(sender_uid, 1, 5) == "broad" then
        sender_uid = ""
        sender_nickname = lang.system_broadcast
    end
    local chat_cmd = 0x1521
    local chat_msg = {
        msg = send_msg,
        channel = req.channel,
        sender = {
            uid = sender_uid,
            nickname = sender_nickname,
            vip = main_data.vip_lev,
            sex = main_data.lead.sex,
            level = main_data.lead.level,
            star = main_data.lead.star
        },
        recver = recver,
        recvs = recvs
    }
    local chat_msg_buf = pb.encode("ChatMsg_t", chat_msg)
    local resp_buf = pb.encode("ChatResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    if req.channel == 0 then
        chat_msg.msg = req.msg
        chat_log.push_log(0, chat_msg)
    elseif req.channel == 2 then
        chat_msg.msg = req.msg
        chat_log.push_log(main_data.group_data.groupid, chat_msg)
    end
    --[[
    local req = pb.decode("OpenChestReq", req_buf)
    assert(req.item.item_num > 0, "item_num:"..req.item.item_num.." <= 0")

    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if rawget(item_list, "item_list") == nil then item_list = {item_list = {}} end
    
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local ret = logic_user.open_chest(main_data, item_list.item_list, req.item.item_id, req.item.item_num, task_struct)
    local resp = {
        result = "OK",
        rsync = ret,
    }
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    local resp_buf = pb.encode("OpenChestResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    ]]
    
    if req.channel == 1 or req.channel == 2 then
        return resp_buf, main_data_buf, item_list_buf, main_data_buf2, chat_cmd, chat_msg_buf
    else
        return resp_buf, main_data_buf, item_list_buf, chat_cmd, chat_msg_buf
    end
end

function server_broadcast_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        local broadcast = pb.decode("ServerBroadcastReq", req)
		return 0, pb.encode("ServerBroadcastResp", resp)
    else
        LOG_ERR("something error");
        return nil,nil
    end
end


function server_broadcast_do_logic(req_buf, user_name)
    local pb = require "protobuf"
    local req = pb.decode("ServerBroadcastReq", req_buf)
	local send_msg = {req.message}
    local chat_cmd = 0x1521
    local chat_msg = {
        msg = send_msg,
        channel = 0,
        sender = {
            uid = "",
            nickname = lang.system_broadcast,
        },
    }
	local resp = {
            result = "OK",
			fd = req.fd,
			session = req.session
        }
    local chat_msg_buf = pb.encode("ChatMsg_t", chat_msg)
    local resp_buf = pb.encode("ServerBroadcastResp", resp)
  
    return resp_buf, chat_cmd, chat_msg_buf
end


function reflesh_qy_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("RefleshQiYuResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function reflesh_qy_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    
    local qiyu = core_user.get_qiyu(main_data)
    core_user.check_qiyu(qiyu.qiyu_list)
    local t = main_data.ext_data.huodong.qiyu
    main_data.ext_data.huodong.qiyu = rawlen(qiyu.qiyu_list)
    local resp = {
        result = "OK",
        qiyu = qiyu,
    }
    local resp_buf = pb.encode("RefleshQiYuResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end

function get_qy_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetQiYuResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function get_qy_do_logic(req_buf, user_name, main_data_buf, item_list_buf)
    local pb = require "protobuf"
    local req = pb.decode("GetQiYuReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_list_buf)
    if rawget(item_list, "item_list") == nil then item_list = {item_list = {}} end
    
    local rsync, qiyu_data, qiyu_list = logic_user.get_qiyu(main_data, item_list.item_list, req.guid)
    core_user.check_qiyu(qiyu_list.qiyu_list)
    local resp = {
        result = "OK",
        qiyu = qiyu_data,
        qiyu_list = qiyu_list,
        rsync = rsync,
    }
    local resp_buf = pb.encode("GetQiYuResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf
end

function del_qy_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("DelQiYuResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function del_qy_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local req = pb.decode("DelQiYuReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    
    local qiyu_data, qiyu_list = logic_user.del_qiyu(main_data, req.guid)
    core_user.check_qiyu(qiyu_list.qiyu_list)
    local resp = {
        result = "OK",
        qiyu = qiyu_data,
        qiyu_list = qiyu_list,
    }
    local resp_buf = pb.encode("DelQiYuResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf
end


function Get_TOPAct_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 0, pb.encode("GetTOPActResp", resp)
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function Get_TOPAct_do_logic(req_buf, user_name)
    local pb = require "protobuf"
    
    local resp = {
        result = "OK",
        flag_list = {0,0,0,0},
    }
    local resp_buf = pb.encode("GetTOPActResp", resp)
    return resp_buf
end

function set_jiban_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("JibanResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function set_jiban_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf)
    local pb = require "protobuf"
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("JibanReq", req_buf)
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    local knight_list, pve2_zhanwei = logic_user.jiban(main_data, knight_bag.knight_list, req.guid, req.jiban_list)
    
    local resp = {
        result = "OK",
        req = req,
        knight_list = knight_list,
        zhenxing = pve2_zhanwei
    }
    
    local resp_buf = pb.encode("JibanResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    return resp_buf, main_data_buf, knight_bag_buf
end

function set_qianneng_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("QiannengResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function set_qianneng_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_pack_buf)
    local pb = require "protobuf"
    local req = pb.decode("QiannengReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_pack_buf)
    if not rawget(knight_bag, "knight_list") then knight_bag = {knight_list = {}} end
    if not rawget(item_package, "item_list") then item_package = {item_list = {}} end

    local isLead = req.knight_guid < 0
    local knight = nil
    local qianneng = 0
    if isLead then
    	qianneng = main_data.lead.qianneng
    else
    	local t = core_user.get_knight_by_guid(req.knight_guid, main_data, knight_bag.knight_list)
    	if t and next(t,1) then
    		knight = t[2]
    		qianneng = knight.data.qianneng
    	end
    end

    local isVip = VIP_conf[main_data.vip_lev]["Qian"] > 0
    local levelup = Open_conf[38]["OPEN_PARA"]
    --主角等级大于50,自动升级需Vip
    local isCheck = main_data.lead.level >= levelup
    if isCheck then
		isCheck = req.level > 1 and isVip or req.level == 1
    end

    local item_id = 191010024
    local item_num = 0
    for i = 1, req.level do
    	if qianneng > 1000 then
    		break
    	end
    	qianneng = qianneng + 1
    	local idx = Qian_conf["index"][math.floor((qianneng - 1) / 10) + 1]
    	item_num = item_num + Qian_conf[idx]["Need_Amount"]
    end

    --LOG_INFO(string.format("Qianneng:%d,ItemNum:%d,levelup:%d,isVip:%s", qianneng, item_num, levelup, isVip))
    local rsync = {item_list = {}}
    if isCheck and item_num > 0 then
    	core_user.expend_item(item_id, item_num, main_data, 22, item_package.item_list, rsync.item_list, true)
		if next(rsync.item_list) then
			if isLead then
				main_data.lead.qianneng = qianneng
			else
				if knight then
					knight.data.qianneng = qianneng
				end
			end
		end
	end

	rsync.cur_gold = main_data.gold
	rsync.cur_money = main_data.money
	rsync.cur_tili = main_data.tili

    local resp = {
        result = "OK",
        knight = knight,
        rsync = rsync,
        lead = main_data.lead,
    }
	local knight_id = isLead and 0 or knight.id
	core_power.reflesh_knight_power(main_data, knight_bag.knight_list, knight_id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
    local resp_buf = pb.encode("QiannengResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    item_pack_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, knight_bag_buf, item_pack_buf
end

function chat_log_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("ChatLogResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function chat_log_do_logic(req_buf, user_name, main_data_buf)
    local pb = require "protobuf"
    local req = pb.decode("ChatLogReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    
    local chat_log_list = nil
    if req.type == 1 then
        chat_log_list = chat_log.get_log_list(main_data.group_data.groupid)
    else
        chat_log_list = chat_log.get_log_list(0)
    end
    local resp = {
        result = "OK",
        type = req.type,
        chat_list = chat_log_list,
    }
    local resp_buf = pb.encode("ChatLogResp", resp)
    return resp_buf, main_data_buf
end

function seven_weapon_level_up_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("SevenWeaponLevelUpResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function seven_weapon_level_up_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_pack_buf)
    local pb = require "protobuf"
    local req = pb.decode("SevenWeapenLevelUpReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_pack_buf)
    if not rawget(knight_bag, "knight_list") then knight_bag = {knight_list = {}} end
    if not rawget(item_package, "item_list") then item_package = {item_list = {}} end
    local resp = logic_user.sw_levelup(main_data, knight_bag.knight_list, item_package.item_list, req)
    
    local resp_buf = pb.encode("SevenWeaponLevelUpResp", resp)
    local main_data_buf = pb.encode("UserInfo", main_data)
    local item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, knight_bag_buf, item_pack_buf
end

function seven_weapon_set_redpoint_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("SevenWeaponSetRedpointResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function seven_weapon_set_redpoint_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    if not rawget(knight_bag, "knight_list") then knight_bag = {knight_list = {}} end
    local sevenweapon = core_user.check_sevenweapon_init( main_data, knight_bag.knight_list )
    for k,v in ipairs(sevenweapon) do
        if v.level > 0 then
            v.redpoint = 1  
        end
    end
    local resp = {
        result = "OK",
        sevenweapon = sevenweapon,
    }
    
    local resp_buf = pb.encode("SevenWeaponSetRedpointResp", resp)
    local main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf, main_data_buf, knight_bag_buf
end