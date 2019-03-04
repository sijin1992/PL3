local core_user = require "core_user_funcs"
local core_task = require "core_task"

function get_mail_list_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GetKnightBagResp", resp)
    elseif step == 1 then
        return datablock.mail_list, user_name
    else
        error("something error");
    end
end

function get_mail_list_do_logic(req, user_name, mail_list_buf)
    local pb = require "protobuf"
    local mail_list = pb.decode("MailList", mail_list_buf)
    if rawget(mail_list, "mail_list") == nil then mail_list = {mail_list = {}} end
    
    --[[if user_name == "lm01100002" then
        wlzb.do_test()
    end
    ]]
    
    --TODO: 真元宝需要替换成假元宝
    for k,v in ipairs(mail_list.mail_list) do
        if v.type == 10 then
            local t = rawget(v, "item_list")
            if t then
                for k1,v1 in ipairs(t) do
                    if v1.id == 191010099 then v1.id = 191010003 end
                end
            end
        end
    end
    local resp = {
        result = "OK",
        mail_list = mail_list,
    }
    local resp_buf = pb.encode("GetMailListResp", resp)
    return resp_buf, mail_list_buf
end

function read_mail_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = { result = "FAIL" }
        return 1, pb.encode("ReadMailResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.mail_list + datablock.save, user_name
    else
        error("something error");
    end
end

function read_mail_do_logic(req_buf, user_name, user_info_buf, item_bag_buf, mail_list_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", user_info_buf)
    local item_bag = pb.decode("ItemList", item_bag_buf)
    local mail_list = pb.decode("MailList", mail_list_buf)
    if rawget(item_bag, "item_list") == nil then item_bag = {item_list = {}} end
    if rawget(mail_list, "mail_list") == nil then mail_list = {mail_list = {}} end
    local req = pb.decode("ReadMailReq", req_buf)
    local guid = req.guid
    local mail = nil
    local mail_idx = 0
    local resp = {
        result = "OK",
        req = req,
        rsync = nil, 
    }
    for k,v in ipairs(mail_list.mail_list) do
        if v.guid == guid then
            mail = v
            mail_idx = k
            break
        end
    end
    assert(mail, "mail not find")
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    if mail.type == 10 then
        local item_list = mail.item_list
        local rsync = {
            gold = main_data.gold,
            item_list = {},
        }
        for _,v in ipairs(item_list) do
			core_user.get_item(v.id, v.num, main_data, 301, nil, item_bag.item_list, rsync, nil)
        end
        core_task.check_chengjiu_title(task_struct, main_data)
        core_task.check_chengjiu_shengwang(task_struct, main_data)
        core_task.check_chengjiu_total_gold(task_struct, main_data)
        core_task.check_chengjiu_max_gold(task_struct, main_data)
        core_task.check_newtask_by_event(main_data, 7)
        
        rsync.gold = main_data.gold
        resp.rsync = rsync
        table.remove(mail_list.mail_list, mail_idx)
        --TODO:真元宝要改成假元宝
        for k1,v1 in ipairs(rsync.item_list) do
            if v1.item_id == 191010099 then v1.item_id = 191010003 end
        end
    else
        mail.type = 1
    end

    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    user_info_buf = pb.encode("UserInfo", main_data)
    item_bag_buf = pb.encode("ItemList", item_bag)
    mail_list_buf = pb.encode("MailList", mail_list)
    local resp_buf = pb.encode("ReadMailResp", resp)
    return resp_buf, user_info_buf, item_bag_buf, mail_list_buf, ext_cmd, ext_buf
end

function del_mail_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = { result = "FAIL" }
        return 1, pb.encode("ReadMailResp", resp)
    elseif step == 1 then
        return datablock.mail_list + datablock.save, user_name
    else
        error("something error");
    end
end

function del_mail_do_logic(req_buf, user_name, mail_list_buf)
    local pb = require "protobuf"
    local mail_list = pb.decode("MailList", mail_list_buf)
    if rawget(mail_list, "mail_list") == nil then mail_list = {mail_list = {}} end
    
    local req = pb.decode("DelMailReq", req_buf)
    local guid = req.guid
    local need_del = {}
    for k,v in ipairs(mail_list.mail_list) do
        if guid <= 0 or v.guid == guid then
            if v.type == 0 or v.type == 1 then
                table.insert(need_del, k)
            end
            if v.guid == guid then
                break
            end
        end
    end
    local need_del_num = rawlen(need_del)
    assert(need_del_num > 0, "mail not find")
    for k = rawlen(need_del), 1, -1 do
        table.remove(mail_list.mail_list, need_del[k])
    end
    
    local resp = {
        result = "OK",
        mail_list = mail_list
    }
    mail_list_buf = pb.encode("MailList", mail_list)
    local resp_buf = pb.encode("DelMailResp", resp)
    return resp_buf, mail_list_buf
end