local logic_group = require "logic_group"

function get_group_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local req = pb.decode("PVE_REQ", req_buf)
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GetGroupResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save --[[+ datablock.save]], user_name
    elseif step == 2 then
        return datablock.group_main + datablock.try --[[+ datablock.save]], user_name
    else
        error("something error");
    end
end

function get_group_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    if not group_buf then
        local resp = {
            result = "OK",
        }
        local resp_buf = pb.encode("GetGroupResp", resp)
        return resp_buf,main_data_buf, group_buf
    end
    local group_data = pb.decode("GroupMainData", group_buf)
    if not group_data.groupid or group_data.groupid == "" then
        --这个公会已经解散了
        local tgid = ""
        local t = rawget(main_data, "group_data")
        if t then
            local groupid = t.groupid
            if groupid and groupid ~= "" then
                tgid = groupid
                group_cache.disband(groupid)
            end
            t.groupid = ""
            t.total_sw = 0
            t.anti_time = 0
            t.status = 0
            t.today_join_num = 0
        end
        LOG_INFO(string.format("%s|exitgroupid|%s|", main_data.user_name, tgid))
        local resp = {
            result = "OK",
            user_group_data = main_data.group_data,
        }
        local resp_buf = pb.encode("GetGroupResp", resp)
        main_data_buf = pb.encode("UserInfo", main_data)
        return resp_buf,main_data_buf, group_buf
    end
    local n_group_data = logic_group.get_group_data(group_data, main_data)

    local resp = {
        result = "OK",
        group_data = n_group_data,
        user_group_data = main_data.group_data,
    }
    local resp_buf = pb.encode("GetGroupResp", resp)
    main_data_buf = pb.encode("UserInfo", main_data)
    return resp_buf,main_data_buf, group_buf
end

function create_group_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local req = pb.decode("PVE_REQ", req_buf)
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GetGroupResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.create, user_name
    else
        error("something error");
    end
end

function create_group_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local req = pb.decode("CreateGroupReq", req_buf)
    
    local group_data = nil
    if group_buf then
        group_data = pb.decode("GroupMainData", group_buf)
        assert(group_data.groupid == "")
    else
        assert(group_buf == nil)
    end
    local ret, new_group, user_group_data = logic_group.create(main_data, req.nickname)
    local resp = nil
    if ret ~= 0 then
        resp = {
            result = "OK",
            code = 1,
            iscreate = 1,
        }
    else
        resp = {
            result = "OK",
            group_data = new_group,
            user_group_data = user_group_data,
            iscreate = 1,
            code = 0,
            money = main_data.money
        }
        main_data_buf = pb.encode("UserInfo", main_data)
        group_buf = pb.encode("GroupMainData", new_group)
    end
    
    local resp_buf = pb.encode("GetGroupResp", resp)
    return resp_buf,main_data_buf, group_buf
end

--门派捐献
function group_juan_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupJuanResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    else
        error("something error");
    end
end

function group_juan_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupJuanReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    
    local rsync,ghost,user_group_data,n_group_data, multicast = logic_group.juanxian(main_data, group_data, req)
    local resp = {
        result = "OK",
        group_data = n_group_data,
        rsync = rsync,
        ghost = ghost,
        user_group_data = user_group_data
    }
    group_buf = pb.encode("GroupMainData", n_group_data)
    main_data_buf = pb.encode("UserInfo", main_data)
    local resp_buf = pb.encode("GroupJuanResp", resp)
    local multi_buf = pb.encode("Multicast", multicast)
    return resp_buf,main_data_buf, group_buf, 0x2100, multi_buf
end

--门派升级
function group_levelup_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupLevelupResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    else
        error("something error");
    end
end

function group_levelup_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local n_group_data, old_level, multicast = logic_group.levelup(main_data, group_data)
    local resp = {
        result = "OK",
        group_data = n_group_data,
        old_lev = old_level
    }
    group_buf = pb.encode("GroupMainData", n_group_data)
    local multi_buf = pb.encode("Multicast", multicast)
    local resp_buf = pb.encode("GroupLevelupResp", resp)
    return resp_buf,main_data_buf, group_buf, 0x2100, multi_buf
end

--门派绝学上限
function group_juexue_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupJuexueResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    else
        error("something error");
    end
end

function group_juexue_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupJuexueReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local n_group_data, old_level, multicast = logic_group.juexue(main_data, group_data, req.juexue_idx)
    local resp = {
        result = "OK",
        group_data = n_group_data,
        old_lev = old_level,
        req = req,
    }
    group_buf = pb.encode("GroupMainData", n_group_data)
    local multi_buf = pb.encode("Multicast", multicast)
    local resp_buf = pb.encode("GroupJuexueResp", resp)
    return resp_buf,main_data_buf, group_buf, 0x2100, multi_buf
end

--门派公告
function group_broadcast_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupBroadcastResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    else
        error("something error");
    end
end

function group_broadcast_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupBroadcastReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local dirty, n_group_data, multicast = logic_group.broadcast(main_data, group_data, req.broadcast)
    local resp = nil
    if dirty then
        resp = {result = "DIRTY"}
    else
        resp = {
            result = "OK",
            group_data = n_group_data,
        }
        group_buf = pb.encode("GroupMainData", n_group_data)
    end
    local multi_buf = pb.encode("Multicast", multicast)
    local resp_buf = pb.encode("GroupBroadcastResp", resp)
    return resp_buf,main_data_buf, group_buf, 0x2100, multi_buf
end

--wxjy
function group_wxjy_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupWXJYResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    elseif step == 2 then
        return datablock.group_main, user_name
    else
        error("something error");
    end
end

function group_wxjy_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupWXJYReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local user_group_data = logic_group.wxjy(main_data, group_data, req.wxjy_idx)
    local resp = {
        result = "OK",
        user_group_data = user_group_data,
        req = req
    }
    main_data_buf = pb.encode("UserInfo", main_data)
    local resp_buf = pb.encode("GroupWXJYResp", resp)
    return resp_buf,main_data_buf, group_buf
end

--门派PVE重置
function group_pve_reset_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupPVEResetResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    else
        error("something error");
    end
end

function group_pve_reset_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupPVEResetReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    
    if req.first == 0 then
        local resp = {
            result = "FAIL",
            group_data = group_data,
            req = req
        }
        local resp_buf = pb.encode("GroupPVEResetResp", resp)
        return resp_buf,main_data_buf, group_buf
    end
    
    local first_flag = false
    if req.first == 1 then first_flag = true end
    local n_group_data, multicast = logic_group.pve_reset(main_data, group_data, req.fortress_id, first_flag)
    local resp = {
        result = "OK",
        group_data = n_group_data,
        req = req
    }
    --main_data_buf = pb.encode("UserInfo", main_data)
    group_buf = pb.encode("GroupMainData", n_group_data)
    local resp_buf = pb.encode("GroupPVEResetResp", resp)
    local multi_buf = pb.encode("Multicast", multicast)
    return resp_buf,main_data_buf, group_buf, 0x2100, multi_buf
end

--门派PVE
function group_pve_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupPVEResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.save, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    else
        error("something error");
    end
end

function group_pve_do_logic(req_buf, user_name, main_data_buf, knight_list_buf, group_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupPVEReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local knight_list = pb.decode("KnightList", knight_list_buf)
    if(rawget(knight_list, "knight_list")) == nil then
        knight_list.knight_list = {}
    end
    
    local rcd, n_group_data, user_group_data, hurt, rsync, multicast = 
        logic_group.pve(main_data, knight_list.knight_list, group_data, req.stage_id, req.fortress_id)
    local resp = {
        result = "OK",
        group_data = n_group_data,
        user_group_data = user_group_data,
        damage = hurt,
        rsync = rsync,
        fight_rcd = rcd,
        req = req
    }
    main_data_buf = pb.encode("UserInfo", main_data)
    group_buf = pb.encode("GroupMainData", n_group_data)
    local resp_buf = pb.encode("GroupPVEResp", resp)
    local multi_buf = pb.encode("Multicast", multicast)
    return resp_buf,main_data_buf,knight_list_buf, group_buf, 0x2100, multi_buf
end

--门派PVE重置
function group_reset_self_pve_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupResetSelfPVEResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    elseif step == 2 then
        return datablock.group_main, user_name
    else
        error("something error");
    end
end

function group_reset_self_pve_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupResetSelfPVEReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local  user_group_data, rsync = 
        logic_group.reset_self_pve(main_data, req.fortress_id, group_data)
    local resp = {
        result = "OK",
        group_data = user_group_data,
        rsync = rsync,
        req = req
    }
    main_data_buf = pb.encode("UserInfo", main_data)
    local resp_buf = pb.encode("GroupResetSelfPVEResp", resp)
    return resp_buf,main_data_buf, group_buf
end

--战利品申请
function group_ask_reward_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupAskRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    else
        error("something error");
    end
end

function group_ask_reward_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupAskRewardReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local n_group_data, multicast = 
        logic_group.ask_reward(main_data, group_data, req.item_id)
    local resp = {
        result = "OK",
        group_data = n_group_data,
        req = req
    }
    --main_data_buf = pb.encode("UserInfo", main_data)
    group_buf = pb.encode("GroupMainData", n_group_data)
    local resp_buf = pb.encode("GroupAskRewardResp", resp)
    local multi_buf = pb.encode("Multicast", multicast)
    return resp_buf,main_data_buf, group_buf, 0x2100, multi_buf
end

--战利品分配
function group_allot_reward_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupAllotRewardResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    else
        error("something error");
    end
end

function group_allot_reward_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupAllotRewardReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local n_group_data, user_group_data, multicast = 
        logic_group.allot_reward(main_data, group_data, req.item_id, req.guid)
    local resp = {
        result = "OK",
        group_data = n_group_data,
        req = req,
        user_group_data = user_group_data
    }
    main_data_buf = pb.encode("UserInfo", main_data)
    group_buf = pb.encode("GroupMainData", n_group_data)
    local resp_buf = pb.encode("GroupAllotRewardResp", resp)
    local multi_buf = pb.encode("Multicast", multicast)
    return resp_buf,main_data_buf, group_buf, 0x2100, multi_buf
end

--查询帮会
function group_search_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 0, pb.encode("GroupSearchResp", resp)
    else
        error("something error");
    end
end

function group_search_do_logic(req_buf, user_name)
    local pb = require "protobuf"
    local req = pb.decode("GroupSearchReq", req_buf)
    local ret, group_list, total_page = 
        logic_group.search_group(req.groupid, req.page)
    assert(ret)
    local resp = {
        result = "OK",
        group_list = group_list,
        req = req,
        total_page = total_page
    }
    local resp_buf = pb.encode("GroupSearchResp", resp)
    return resp_buf
end

--申请加入
function group_join_req_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupJoinResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    elseif step == 2 then
        
        local pb = require "protobuf"
        local req = pb.decode("GroupJoinReq", req_buf)
        return datablock.group_main + datablock.save + datablock.groupid, req.groupid
    else
        error("something error");
    end
end

function group_join_req_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupJoinReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local user_group_data, n_group_data, group_info = 
        logic_group.join_req(main_data, group_data)
    local resp = {
        result = "OK",
        user_group_data = user_group_data,
        req = req,
        group_info = group_info
    }
    main_data_buf = pb.encode("UserInfo", main_data)
    group_buf = pb.encode("GroupMainData", n_group_data)
    local resp_buf = pb.encode("GroupJoinResp", resp)
    return resp_buf, main_data_buf, group_buf
end

--批准加入
function group_allow_join_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 3, pb.encode("GroupAllowJoinResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    elseif step == 3 then
        local pb = require "protobuf"
        local req = pb.decode("GroupAllowJoinReq", req_buf)
        return datablock.main_data + datablock.mail_list + datablock.save, req.username
    else
        error("something error");
    end
end

function group_allow_join_do_logic(req_buf, user_name, main_data_buf, group_buf, main_data_buf2, mail_buf2)
    local pb = require "protobuf"
    local req = pb.decode("GroupAllowJoinReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local main_data2 = pb.decode("UserInfo", main_data_buf2)
    local mail_list2 = pb.decode("MailList", mail_buf2)
    if not rawget(mail_list2, "mail_list") then mail_list2 = {mail_list = {}} end
    local n_group_data, group_info, code, multicast = 
        logic_group.allow_join(main_data, group_data, main_data2, req.type, mail_list2.mail_list)
    if code == 0 then
        local resp = {
            result = "OK",
            group_data = n_group_data,
            req = req,
            group_info = group_info,
            code = code
        }
        --main_data_buf = pb.encode("UserInfo", main_data)
        group_buf = pb.encode("GroupMainData", n_group_data)
        main_data_buf2 = pb.encode("UserInfo", main_data2)
        mail_buf2 = pb.encode("MailList", mail_list2)
        local resp_buf = pb.encode("GroupAllowJoinResp", resp)
        local multi_buf = pb.encode("Multicast", multicast)
        return resp_buf, main_data_buf, group_buf, main_data_buf2, mail_buf2, 0x2100, multi_buf
    else
        local resp = {
            result = "OK",
            req = req,
            code = code,
            group_data = n_group_data,
            group_info = group_info,
        }
        --main_data_buf = pb.encode("UserInfo", main_data)
        local resp_buf = pb.encode("GroupAllowJoinResp", resp)
        return resp_buf, main_data_buf, group_buf, main_data_buf2, mail_buf2
    end
end

--退出公会
function group_exit_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupExitGroupResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    else
        error("something error");
    end
end

function group_exit_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local ret, n_group_data, group_info, user_group_data, multicast = 
        logic_group.exit(main_data, group_data)
    local resp = {
        result = "OK",
        user_group_data = user_group_data,
    }
    if ret == -2 then
        resp.result = "LOCKED"
        resp.user_group_data = nil 
        local resp_buf = pb.encode("GroupExitGroupResp", resp)
        return resp_buf, main_data_buf, group_buf
    end

    main_data_buf = pb.encode("UserInfo", main_data)
    group_buf = pb.encode("GroupMainData", n_group_data)
    local resp_buf = pb.encode("GroupExitGroupResp", resp)
    local multi_buf = pb.encode("Multicast", multicast)
    return resp_buf, main_data_buf, group_buf, 0x2100, multi_buf
end

--踢出公会
function group_kick_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 3, pb.encode("GroupKickResp", resp)
    elseif step == 1 then
        return datablock.main_data, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    elseif step == 3 then
        local pb = require "protobuf"
        local req = pb.decode("GroupKickReq", req_buf)
        return datablock.main_data + datablock.mail_list + datablock.save, req.username
    else
        error("something error");
    end
end

function group_kick_do_logic(req_buf, user_name, main_data_buf, group_buf, main_data_buf2, mail_buf2)
    local pb = require "protobuf"
    local req = pb.decode("GroupKickReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local main_data2 = pb.decode("UserInfo", main_data_buf2)
    local mail_list2 = pb.decode("MailList", mail_buf2)
    if not rawget(mail_list2, "mail_list") then mail_list2 = {mail_list = {}} end
    
    local ret, n_group_data, group_info, multicast = 
        logic_group.kick(main_data, group_data, main_data2, mail_list2.mail_list)
    local resp = {
        result = "OK",
        group_data = n_group_data,
        req = req,
    }

    if ret == -2 then
        resp.result = "LOCKED"
        resp.group_data = nil 
        local resp_buf = pb.encode("GroupKickResp", resp)
        return resp_buf, main_data_buf, group_buf, main_data_buf2, mail_buf2
    end
    --main_data_buf = pb.encode("UserInfo", main_data)
    group_buf = pb.encode("GroupMainData", n_group_data)
    main_data_buf2 = pb.encode("UserInfo", main_data2)
    mail_buf2 = pb.encode("MailList", mail_list2)
    local resp_buf = pb.encode("GroupKickResp", resp)
    local multi_buf = pb.encode("Multicast", multicast)
    return resp_buf, main_data_buf, group_buf, main_data_buf2, mail_buf2, 0x2100, multi_buf
end

--指定帮主副帮主
function group_master_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 3, pb.encode("GroupMasterResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    elseif step == 3 then
        local pb = require "protobuf"
        local req = pb.decode("GroupMasterReq", req_buf)
        return datablock.main_data + datablock.save, req.username
    else
        error("something error");
    end
end

function group_master_do_logic(req_buf, user_name, main_data_buf, group_buf, main_data_buf2)
    local pb = require "protobuf"
    local req = pb.decode("GroupMasterReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local main_data2 = pb.decode("UserInfo", main_data_buf2)
    local n_group_data, group_info, user_group_data, multicast = 
        logic_group.master(main_data, group_data, main_data2, req.type)
    local resp = {
        result = "OK",
        group_data = n_group_data,
        req = req,
        user_group_data = user_group_data,
    }
    main_data_buf = pb.encode("UserInfo", main_data)
    group_buf = pb.encode("GroupMainData", n_group_data)
    main_data_buf2 = pb.encode("UserInfo", main_data2)
    local resp_buf = pb.encode("GroupMasterResp", resp)
    local multi_buf = pb.encode("Multicast", multicast)
    return resp_buf, main_data_buf, group_buf, main_data_buf2, 0x2100, multi_buf
end

--解散帮会
function group_disband_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 2, pb.encode("GroupDisbandResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.save, user_name
    elseif step == 2 then
        return datablock.group_main + datablock.save, user_name
    else
        error("something error");
    end
end

function group_disband_do_logic(req_buf, user_name, main_data_buf, group_buf)
    local pb = require "protobuf"
    local main_data = pb.decode("UserInfo", main_data_buf)
    local group_data = pb.decode("GroupMainData", group_buf)
    local ret, n_group_data, user_group_data, multicast = 
        logic_group.disband(main_data, group_data)
    local resp = {
        result = "OK",
        user_group_data = user_group_data,
    }

    if ret == -2 then
        resp.result = "LOCKED"
        resp.user_group_data = nil 
        local resp_buf = pb.encode("GroupDisbandResp", resp)
        return resp_buf, main_data_buf, group_buf
    end
    
    main_data_buf = pb.encode("UserInfo", main_data)
    group_buf = pb.encode("GroupMainData", n_group_data)
    local resp_buf = pb.encode("GroupDisbandResp", resp)
    local multi_buf = pb.encode("Multicast", multicast)
    return resp_buf, main_data_buf, group_buf, 0x2100, multi_buf
end

function group_reflesh_shop_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GroupRefleshShopResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        error("something error");
    end
end

function group_reflesh_shop_do_logic(req_buf, user_name, user_data_buf, item_pack_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupRefleshShopReq", req_buf)
    local user_data = pb.decode("UserInfo", user_data_buf)
    local item_list = pb.decode("ItemList", item_pack_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
    local shop_list,rsync = logic_group.reflesh_shop(user_data, item_list.item_list, req.free)
    local resp = {
        result = "OK",
        req = req,
        shopping_list = shop_list,
        rsync = rsync
    }
    user_data_buf = pb.encode("UserInfo", user_data)
    item_pack_buf = pb.encode("ItemList", item_list)
    local resp_buf = pb.encode("GroupRefleshShopResp", resp)
    return resp_buf, user_data_buf, item_pack_buf
end

function group_shopping_feature(step, req_buf, user_name)
    if step == 0 then
        local pb = require "protobuf"
        local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("GroupShoppingResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.item_package + datablock.save, user_name
    else
        error("something error");
    end
end

function group_shopping_do_logic(req_buf, user_name, user_data_buf, item_pack_buf)
    local pb = require "protobuf"
    local req = pb.decode("GroupShoppingReq", req_buf)
    local user_data = pb.decode("UserInfo", user_data_buf)
    local item_list = pb.decode("ItemList", item_pack_buf)
    if not rawget(item_list, "item_list") then item_list = {item_list = {}} end 
    local ret = logic_group.shopping(user_data, item_list.item_list, req.idx + 1)
    local resp = {
        result = "OK",
        req = req,
        rsync = ret
    }
    user_data_buf = pb.encode("UserInfo", user_data)
    item_pack_buf = pb.encode("ItemList", item_list)
    local resp_buf = pb.encode("GroupShoppingResp", resp)
    return resp_buf, user_data_buf, item_pack_buf
end