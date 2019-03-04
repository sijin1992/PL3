local core_user = require "core_user_funcs"
local logic_knight = require "logic_knight"

function levelup_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
		local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("KnightLevelUpResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function levelup_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_pack_buf)
    local pb = require "protobuf"
    local req = pb.decode("KnightLevelUpReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_pack_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    local tag_guid = req.tag_guid
    local tag = nil
    local t = nil
    local sync = nil
    t = core_user.get_knight_by_guid(tag_guid, main_data, knight_bag.knight_list)
    tag = t[2]
    assert(tag, "when levelup, tag guid not find")
    tag, sync = logic_knight.level_up(tag, req.src_list, item_package.item_list, main_data, user_name, knight_bag.knight_list)
	local resp = {
        result = "OK",
        knight = tag,
		rsync_item = sync,
		add_new_player = core_user.set_anp_knight_level(main_data)
    }
    if req.add_new_player > 0 then
        local t = main_data.ext_data.new_player
        main_data.ext_data.new_player = req.add_new_player;
    end
    local resp_buf = pb.encode("KnightLevelUpResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    item_pack_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, knight_bag_buf, item_pack_buf
end


function evolutionup_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
		local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("KnightEvolutionUpResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function evolutionup_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("KnightEvolutionUpReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    local tag_guid = req.tag_guid
    local tag = nil
	local t = nil
    t = core_user.get_knight_by_guid(tag_guid, main_data, knight_bag.knight_list)
    tag = t[2]
    assert(tag, "when evolutionup, tag guid not find")
	
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local rsync = logic_knight.evolution_up(tag, main_data, knight_bag.knight_list, item_package.item_list, user_name, task_struct)
	local resp = {
        result = "OK",
        knight = tag,
		rsync = rsync,
    }
    if req.add_new_player > 0 then
        local t = main_data.ext_data.new_player
        main_data.ext_data.new_player = req.add_new_player;
    end
	local resp_buf = pb.encode("KnightEvolutionUpResp", resp)
    local main_data_buf = pb.encode("UserInfo", main_data)
    local knight_bag_buf = pb.encode("KnightList", knight_bag)
    local item_bag_buf = pb.encode("ItemList", item_package)
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    return resp_buf, main_data_buf, knight_bag_buf, item_bag_buf, ext_cmd, ext_buf
end

function gong_equip_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GongEquipResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function gong_equip_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("GongEquipReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    local tag_guid = req.guid
    local tag = nil
    local t = nil
    t = core_user.get_knight_by_guid(tag_guid, main_data, knight_bag.knight_list)
    tag = t[2]
    assert(tag, "tag guid not find")
    
    local item, rsync, gongidxes = logic_knight.gong_equip(main_data, tag, req.gong_idx, req.onekey, item_package.item_list,knight_bag.knight_list)
    local resp = {
        result = "OK",
        knight = tag,
        item_id = item,
        gong_idx = req.gong_idx,
        add_new_player = core_user.set_anp_wx_equip(main_data, item),
        gong_idxes = gongidxes,
        rsync = rsync,
    }
    if req.add_new_player > 0 then
        local t = main_data.ext_data.new_player
        main_data.ext_data.new_player = req.add_new_player;
    end
    local resp_buf = pb.encode("GongEquipResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, knight_bag_buf, item_package_buf
end

function gong_merge_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GongMergeResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function gong_merge_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf)
    local pb = require "protobuf"
    local req = pb.decode("GongMergeReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    local tag_guid = req.guid
    local tag = nil
    local t = nil
    t = core_user.get_knight_by_guid(tag_guid, main_data, knight_bag.knight_list)
    tag = t[2]
    assert(tag, "tag guid not find")
    
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    logic_knight.gong_merge(tag, main_data, knight_bag.knight_list, task_struct)
    local resp = {
        result = "OK",
        knight = tag,
    }
    local resp_buf = pb.encode("GongMergeResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    return resp_buf, main_data_buf, knight_bag_buf, ext_cmd, ext_buf
end

function gong_mix_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GongMixResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function gong_mix_do_logic(req_buf, user_name, main_data_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("GongMixReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    
    local ret = logic_knight.gong_mix(req.tag_item, main_data, item_package.item_list)
    local resp = {
        result = "OK",
        rsync = ret,
    }
    local resp_buf = pb.encode("GongMixResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, item_package_buf
end

function enlist_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("KnightEnlistResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function enlist_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("KnightEnlistReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    local knight_id = req.knight_id
    local t = nil
    t = core_user.get_knight_by_id(knight_id, main_data, knight_bag.knight_list)
    assert(not t , knight_id.." tag knight not exist")

    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local notify_struct = {ret = false, data = nil}

    local rsync, sevenweapon = logic_knight.enlist(knight_id, main_data, knight_bag.knight_list, item_package.item_list,
        task_struct, notify_struct)
    local resp = {
        result = "OK",
        rsync = rsync,
        add_new_player = core_user.set_anp_enlist(main_data),
        sevenweapon = sevenweapon,
    }

    if req.add_new_player > 0 then
        local t = main_data.ext_data.new_player
        main_data.ext_data.new_player = req.add_new_player;
    end
    local resp_buf = pb.encode("KnightEnlistResp", resp)
    local main_data_buf = pb.encode("UserInfo", main_data)
    local knight_bag_buf = pb.encode("KnightList", knight_bag)
    local item_bag_buf = pb.encode("ItemList", item_package)
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
    return resp_buf, main_data_buf, knight_bag_buf, item_bag_buf, ext_cmd, ext_buf, ext_cmd2, ext_buf2
end

function mj_equip_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("EquipMiJiResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function mj_equip_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("EquipMiJiReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    
    local rsync = logic_knight.EquipMiJi(req.miji_id, req.guid, req.from, req.to,
        main_data, knight_bag.knight_list, item_package.item_list)
    
    local resp = {
        result = "OK",
        req = req,
        rsync = rsync,
    }
    local resp_buf = pb.encode("EquipMiJiResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, knight_bag_buf, item_package_buf
end

function mj_levelup_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("MiJiLevelupResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function mj_levelup_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("MiJiLevelupReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    
    local rsync = logic_knight.MiJiLevelup(req.miji_id, req.guid, req.from, req.item_list,
        main_data, knight_bag.knight_list, item_package.item_list)
    
    local resp = {
        result = "OK",
        req = req,
        rsync = rsync,
    }
    local resp_buf = pb.encode("MiJiLevelupResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, knight_bag_buf, item_package_buf
end

function mj_mix_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GongMixResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function mj_mix_do_logic(req_buf, user_name, main_data_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("GongMixReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    
    local ret = logic_knight.miji_mix(req.tag_item, main_data, item_package.item_list)
    local resp = {
        result = "OK",
        rsync = ret,
    }
    local resp_buf = pb.encode("GongMixResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, item_package_buf
end

function mj_jinjie_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("MiJiJinjieResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function mj_jinjie_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("MiJiJinjieReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    
    local rsync = logic_knight.MiJiJinjie(req.miji_id, req.guid, req.from, req.item_list,
        main_data, knight_bag.knight_list, item_package.item_list)
    
    local resp = {
        result = "OK",
        req = req,
        rsync = rsync,
    }
    local resp_buf = pb.encode("MiJiJinjieResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, knight_bag_buf, item_package_buf
end


function bqp_equip_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("EquipBQPResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function bqp_equip_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("EquipBQPReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    
    local drsync, rsync = logic_knight.EquipBQP(req, main_data, knight_bag.knight_list, item_package.item_list)
    
    local resp = {
        result = "OK",
        req = req,
        drsync = drsync,
        rsync = rsync,
    }
    resp.rsync.cur_gold = main_data.gold
    resp.rsync.cur_tili = main_data.tili
    resp.rsync.cur_money = main_data.money
    local resp_buf = pb.encode("EquipBQPResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    item_package_buf = pb.encode("ItemList", item_package)
    --assert(false)
    return resp_buf, main_data_buf, knight_bag_buf, item_package_buf
end

function bqp_levelup_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("BQPLevelupResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function bqp_levelup_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("BQPLevelupReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    
    local rsync, bqp_data, retitem = logic_knight.BQPLevelup(req, main_data, knight_bag.knight_list, item_package.item_list)
    
    local resp = {
        result = "OK",
        req = req,
        bqp_data = bqp_data,
        rsync = rsync,
        bqpitem = retitem,
    }
    
    resp.rsync.cur_gold = main_data.gold
    resp.rsync.cur_tili = main_data.tili
    resp.rsync.cur_money = main_data.money
    local resp_buf = pb.encode("BQPLevelupResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, knight_bag_buf, item_package_buf
end

function bqp_mix_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("BQPMixResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function bqp_mix_do_logic(req_buf, user_name, main_data_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("BQPMixReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    
    local ret = logic_knight.bqp_mix(req.mixnum, main_data, item_package.item_list)
    local resp = {
        result = "OK",
        rsync = ret,
    }
    resp.rsync.cur_gold = main_data.gold
    resp.rsync.cur_tili = main_data.tili
    resp.rsync.cur_money = main_data.money
    --printtab(resp, "resp:")
    local resp_buf = pb.encode("BQPMixResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, item_package_buf
end

function bqp_fenjie_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("BQPFenjieResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function bqp_fenjie_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf, item_package_buf)
    local pb = require "protobuf"
    local req = pb.decode("BQPFenjieReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    local item_package = pb.decode("ItemList", item_package_buf)
    if rawget(item_package, "item_list") == nil then item_package = {item_list = {}} end
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    
    local rsync = logic_knight.BQPFenjie(req.item_list, main_data, knight_bag.knight_list, item_package.item_list)
    
    local resp = {
        result = "OK",
        req = req,
        rsync = rsync,
    }
    resp.rsync.cur_gold = main_data.gold
    resp.rsync.cur_tili = main_data.tili
    resp.rsync.cur_money = main_data.money
    local resp_buf = pb.encode("BQPFenjieResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    knight_bag_buf = pb.encode("KnightList", knight_bag)
    item_package_buf = pb.encode("ItemList", item_package)
    return resp_buf, main_data_buf, knight_bag_buf, item_package_buf
end
