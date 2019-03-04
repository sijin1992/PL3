local logic_equip = require "logic_equip"
local core_user = require "core_user_funcs"

function equiplevelup_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
		local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("EquipLevelUpResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function equiplevelup_do_logic(req_buf, user_name, main_data_buf, item_buf)
    local pb = require "protobuf"
    local req = pb.decode("EquipLevelUpReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if rawget(item_list, "item_list") == nil then item_list = {item_list = {}} end
    local equip = main_data.lead.equip_list[req.id]
    assert(equip)
    
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local rsync = logic_equip.level_up(equip, req.id, req.add_value, main_data, user_name, item_list.item_list, task_struct)
    local resp = {
        result = "OK",
        equip = equip,
        id = req.id,
		rsync = rsync,
		add_new_player = core_user.set_anp_on_equiplevel(main_data),
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
    local resp_buf = pb.encode("EquipLevelUpResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    item_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_buf, ext_cmd, ext_buf
end

function equipstarup_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("EquipStarUpResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function equipstarup_do_logic(req_buf, user_name, main_data_buf, item_buf)
    local pb = require "protobuf"
    local req = pb.decode("EquipStarUpReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local item_list = pb.decode("ItemList", item_buf)
    if rawget(item_list, "item_list") == nil then item_list = {item_list = {}} end
    local equip = main_data.lead.equip_list[req.id]
    assert(equip)

    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    local rsync = logic_equip.star_up(equip, req.id, main_data, item_list.item_list, user_name, task_struct)
    
    local resp = {
        result = "OK",
        equip = equip,
        id = req.id,
        rsync = rsync,
        add_new_player = core_user.set_anp_on_equipstar(main_data),
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
    local resp_buf = pb.encode("EquipStarUpResp", resp)
    local main_data_buf = pb.encode("UserInfo", main_data)
    local item_list_buf = pb.encode("ItemList", item_list)
    return resp_buf, main_data_buf, item_list_buf, ext_cmd, ext_buf
end

function ship_remove_feature(step, req_buff, user_name)
    if step == 0 then
        local resp =
        {
            result = -1,
        }
        return 1, Tools.encode("ShipRemoveResp", resp)
    elseif step == 1 then
        return datablock.user_info + datablock.ship_list + datablock.item_list + datablock.save, user_name
    else
        error("something error");
    end
end

function ship_remove_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
    local req = Tools.decode("ShipRemoveReq", req_buff)
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
    shipList:setItemList(item_list)
    local ret
    local item_syncs = {}
    local user_sync = {}
    local ship_info
    if req.type > 0 then        
        ret = shipList:shipRemove(req.ship_guid)
    else
        ret = 0
    end
    --print("shipremove", ret)
    local resp =
    {
        result = ret,
        --user_sync = user_sync,
    }

    local resp_buff = Tools.encode("ShipRemoveResp", resp)
    user_info_buff = userInfo:getUserBuff()
    ship_list_buff = shipList:getShipBuff()
    item_list_buff = itemList:getItemBuff()
    return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end