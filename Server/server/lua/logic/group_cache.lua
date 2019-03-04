local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert

local group_list = {}
local group_list_sort = {}
local sid_group_guid = {}
local disband_list = {}
local cur_day_21 = get_dayid_from(os.time(), 21)
local cur_day_0 = get_dayid_from(os.time(), 0)
local cur_day_5 = get_dayid_from(os.time(), 5)

local last_gid = nil

local kc = require "kyotocabinet"
local db = kc.DB:new()


local function sort_group(a, b)
    if a.level == b.level then
        return a.create_time < b.create_time
    else
        return a.level > b.level
    end
end

local function remove_mem_from(user_list, username, flag)
--[[
    flag == 1 强行踢出公会(普通成员)
    flag == 2 重复会员(普通会员)
]]
    if user_list then
        if flag == 1 then
            for k,v in ipairs(user_list) do
                if v.username == username then
                    LOG_INFO("GROUP|GM|removemem|".. k.." ".. v.username)
                    table.remove(user_list, k)
                    break
                end     
            end
        elseif flag == 2 then
            local found = false
            for k,v in ipairs(user_list) do
                if found then
                    if v.username == username then
                        LOG_INFO("GROUP|GM|removemem|".. k.." ".. v.username)
                        table.remove(user_list, k)
                        break
                    end
                end
                if not found then 
                    if v.username == username then
                        found = true
                    end
                end
            end
        end
    end
end

if not db:open("group.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
    error("group.kch open err")
else
    db:iterate(
        function(k,v)
            if string.sub(k,1,3) == "SID" then
                local sid = string.sub(k, 4)
                sid_group_guid[sid] = tonumber(v)
            elseif k == "DAYID21" then
                cur_day_21 = tonumber(v)
            elseif k == "DAYID0" then
                cur_day_0 = tonumber(v)
            elseif k == "DAYID5" then
                cur_day_5 = tonumber(v)
            elseif string.sub(k,1,3) == "DIS" then
                local gid = string.sub(k, 4)
                disband_list[gid] = 1
            else
                local pb = require "protobuf"
                local d = pb.decode("GroupInfo", v)
                group_list[k] = d
                tinsert(group_list_sort, d)
            end
        end, false
    )
    
    table.sort(group_list_sort, sort_group)
end

local group_cache = {}

function group_cache.get_groupid(uid)
    local sid = string.sub(uid, -5)
    local guid = 1
    if sid_group_guid[sid] then guid = sid_group_guid[sid] end
    sid_group_guid[sid] = guid + 1
    db:set("SID"..sid, sid_group_guid[sid])
    return guid..sid
end

function group_cache.check_nickname(str)
    for k,v in ipairs(group_list_sort) do
        if v.nickname == str then
            return false
        end
    end
    return true
end

function group_cache.get_group(groupid)
    return group_list[groupid]
end

function group_cache.update_user_info(main_data)
    local group_data = rawget(main_data, "group_data")
    if not group_data then return end
    local groupid = group_data.groupid
    if groupid == "" then return end
    local group_info = group_list[groupid]
    if not group_info then
        LOG_ERROR(string.format("uid: %s, groupid: %s, group cache not find", main_data.user_name, groupid))
        return
    end
    local c_data = nil
    local t = rawget(group_info, "master")
    if t and t.username == main_data.user_name then c_data = t end
    if not c_data then
        t = rawget(group_info, "master2")
        if t and t.username == main_data.user_name then c_data = t end
    end
    if not c_data then
        t = rawget(group_info, "user_list")
        if t then
            for k,v in ipairs(t) do
                if v.username == main_data.user_name then
                    c_data = v
                    break
                end
            end
        end
    end
    if not c_data then
        LOG_ERROR(string.format("uid: %s, groupid: %s, not exist when update", main_data.user_name, groupid))
        return
    end
    c_data.level = main_data.lead.level
    c_data.vip = main_data.vip_lev
    c_data.star = main_data.lead.star
    c_data.last_act = os.time()
    group_data.status = c_data.status
    local pb = require "protobuf"
    local group_str = pb.encode("GroupInfo", group_info)
    db:set(groupid, group_str)
end

function group_cache.check_disband(main_data)
    local group_data = rawget(main_data, "group_data")
    if not group_data then return end
    local groupid = group_data.groupid
    if groupid == "" then return end
    local t = disband_list[groupid]
    if t then
        group_data.groupid = ""
        group_data.total_sw = 0
        group_data.anti_time = 0
        group_data.status = 0
        --group_data.allot_num = 0
        group_data.today_join_num = 0
        --公会解散如果清挑战次数，玩家可以刷，所以也不请
        --rawset(group_data, "fortress_list", nil)
        LOG_INFO(string.format("check_disband|%s|%s|", main_data.user_name, groupid))
    end
end

function group_cache.merge_cache_to(group_data)
    local group_info = group_list[group_data.groupid]
    if not group_info then
        LOG_ERROR(string.format("groupid %s not find in cache", group_data.groupid))
        return
    end
    
    local t = group_data.groupid
    t = group_info.groupid
    
    local join_list = rawget(group_info, "join_list")
    rawset(group_data, "join_list", join_list)
    
    local reward_list = rawget(group_info, "reward_list")
    rawset(group_data, "reward_list", reward_list)
    
    --local master = rawget(group_data, "master")
    --local c_master = rawget(group_info, "master")
    rawset(group_data, "master", rawget(group_info, "master"))
    --[[
    assert(master and c_master and master.username == c_master.username)
    master.level = c_master.level
    master.vip = c_master.vip
    master.star = c_master.star
    master.last_act = c_master.last_act
    rawset(master, "today_gongxian", rawget(c_master, "today_gongxian"))
    rawset(master, "last_gongxian", rawget(c_master, "last_gongxian"))
    ]]
    rawset(group_data, "master2", rawget(group_info, "master2"))
    
    --[[
    local master2 = rawget(group_data, "master2")
    local c_master2 = rawget(group_info, "master2")
    if master2 then
        assert(c_master2 and master2.username == c_master2.username)
        master2.level = c_master2.level
        master2.vip = c_master2.vip
        master2.star = c_master2.star
        master2.last_act = c_master2.last_act
        rawset(master2, "today_gongxian", rawget(c_master2, "today_gongxian"))
        rawset(master2, "last_gongxian", rawget(c_master2, "last_gongxian"))
    end
    ]]
    rawset(group_data, "user_list", rawget(group_info, "user_list"))
    --[[
    local user_list = rawget(group_data, "user_list")
    local c_user_list = rawget(group_info, "user_list")
    if user_list then
        assert(c_user_list)
        for k,v in ipairs(user_list) do
            local c_v = rawget(c_user_list, k)
            assert(c_v and v.username == c_v.username)
            v.level = c_v.level
            v.vip = c_v.vip
            v.star = c_v.star
            v.last_act = c_v.last_act
            rawset(v, "today_gongxian", rawget(c_v, "today_gongxian"))
            rawset(v, "last_gongxian", rawget(c_v, "last_gongxian"))
        end
    end
    ]]
    if group_info.money and group_info.money > 0 then
        rawset(group_data, "money", rawget(group_info, "money"))
    end
    rawset(group_data, "allot_num", rawget(group_info, "allot_num"))
end

function group_cache.update_group(group_data, new_flag)
    local groupid = group_data.groupid
    local c_group = group_list[groupid]
    
    local member = 0
    if rawget(group_data, "master") then member = member + 1 end
    if rawget(group_data, "master2") then member = member + 1 end
    local user_list = rawget(group_data, "user_list")
    if user_list then
        local t = user_list[1]
        member = member + rawlen(user_list)
    end
    
    if c_group == nil then
        --新建工会
        c_group = {
            groupid = group_data.groupid,
            level = group_data.level,
            nickname = group_data.nickname,
            flag = 0,
            member = member,
            create_time = group_data.create_time,
            master = group_data.master,
            master2 = rawget(group_data, "master2"),
            money = rawget(group_data, "money"),
            user_list = rawget(group_data, "user_list"),
            reward_list = rawget(group_data, "reward_list"),
            allot_num = rawget(group_data, "allot_num"),
            join_list = rawget(group_data, "join_list")
        }
        group_list[groupid] = c_group
        tinsert(group_list_sort, c_group)

    else
        --更新工会
        local t = c_group.level
        c_group.level = group_data.level
        --[[
        local join_list = nil
        if group_data.join_list then
            local t = group_data.join_list[1]
            join_list = rawget(group_data, "join_list")
        end
        ]]
        c_group.nickname = group_data.nickname
        c_group.join_list = rawget(group_data, "join_list")
        c_group.member = member
        c_group.create_time = group_data.create_time
        c_group.master = group_data.master
        c_group.master2 = rawget(group_data, "master2")
        c_group.user_list = rawget(group_data, "user_list")
        c_group.reward_list = rawget(group_data, "reward_list")
        c_group.money = rawget(group_data, "money")
        c_group.allot_num = rawget(group_data, "allot_num")
    end
    local pb = require "protobuf"
    local group_str = pb.encode("GroupInfo", c_group)
    db:set(groupid, group_str)
    if new_flag then last_gid = groupid end
    if groupid then
        local slen = string.len(groupid)
        if slen > 5 then
            local sid = string.sub(groupid, -5)
            local cur_num = tonumber(string.sub(groupid, 1, slen - 5))
            if (not sid_group_guid[sid]) or cur_num >= sid_group_guid[sid] then
                sid_group_guid[sid] = cur_num + 1
                db:set("SID"..sid, sid_group_guid[sid])
            end
        end
    end
    return c_group
end

function group_cache.rollback()
    if last_gid then
        db:remove(last_gid)
        for k,v in ipairs(group_list_sort) do
            if v.groupid == last_gid then
                table.remove(group_list_sort, k)
                break
            end
        end
        group_list[last_gid] = nil
    end
end

function group_cache.search_group(groupid, page)
    if groupid and groupid ~= "" then
        if group_list[groupid] then
            return true, {group_list[groupid]}
        else return true, nil end
    elseif page > 0 then
        local t_list = {}
        for k = (page - 1) * 5 + 1, page * 5 do
            if group_list_sort[k] then
                local t = group_list_sort[k]
                tinsert(t_list, t)
            else
                break
            end
        end
        return true, t_list
    else
        return false
    end
end

function group_cache.group_count()
    return rawlen(group_list_sort)
end

function group_cache.join_req(main_data, group_data)
    local group_info = group_list[group_data.groupid]
    assert(group_info)
    local t = group_info.groupid
    local t_list = rawget(group_info, "join_list")
    if t_list then
        local num = 0
        for k,v in ipairs(t_list) do
            assert(v.username ~= main_data.user_name, "has req join")
            num = num + 1
        end
        if num >= 20 then
            table.remove(t_list, 1)
        end
    else
        t_list = {}
        rawset(group_info, "join_list", t_list)
    end
    tinsert(t_list, {username = main_data.user_name,
        nickname = main_data.nickname,
        vip = main_data.vip_lev, sex = main_data.lead.sex, level = main_data.lead.level,
        star = main_data.lead.star})
    local pb = require "protobuf"
    local group_str = pb.encode("GroupInfo", group_info)
    db:set(group_data.groupid, group_str)
    return group_info
end

function group_cache.modify_money(groupid, modify_money)
    local c_group = group_cache.get_group(groupid)
    if c_group ~= nil then
        local money = rawget(c_group, "money")
        if money == nil then
            money = 0
        end
        money = money + modify_money
        rawset(c_group, "money", money)
        local pb = require "protobuf"
        local group_str = pb.encode("GroupInfo", c_group)
        db:set(groupid, group_str)
    end
end

function group_cache.disband(groupid)
    for k,v in ipairs(group_list_sort) do
        if v.groupid == groupid then
            table.remove(group_list_sort, k)
            break
        end
    end
    group_list[groupid] = nil
    db:remove(groupid)
    disband_list[groupid] = 1
    db:set("DIS"..groupid, 1)
    LOG_INFO(string.format("disband|%s", groupid))
end

local function auto_allot_reward()
    for k,v in ipairs(group_list_sort) do
        local t = v.level
        local reward_list = rawget(v,"reward_list")
        if reward_list then       
            for k1,v1 in ipairs(reward_list) do
                local num = v1.item_num
                local ask_list = rawget(v1, "ask_list")
                if ask_list then
                    t = ask_list[1]
                    local item_name = Item_conf[v1.item_id].CN_NAME
                    local text = string.format(lang.group_auto_allot_msg, item_name)
                    while num > 0 do
                        if rawlen(ask_list) > 0 then
                            local username = ask_list[1].username
                            if username ~= "" then
                               local mail = {
                                    type = 10,
                                    from = lang.group_mail_sender,
                                    subject = lang.group_auto_allot_title,
                                    message = text,
                                    stamp = os.time(),
                                    expiry_stamp = os.time() + 604800,
                                    guid = 0,
                                    item_list = {{id = v1.item_id, num = 1}}
                                }
                                redo_list.add_mail(username, mail)
                            end
                            table.remove(ask_list, 1)
                            num = num - 1
                            LOG_INFO(string.format("group_auto_allot|%s|%s --> %d", v.groupid, username, v1.item_id))
                        else break
                        end
                    end
                    v1.item_num = num
                end
            end
        end
        --全部处理完，更新kch
        local pb = require "protobuf"
        local group_str = pb.encode("GroupInfo", v)
        db:set(v.groupid, group_str)
    end
end

local function reset_allot_num()
    for k,v in ipairs(group_list_sort) do
        local t = v.level
        v.allot_num = 0
        --全部处理完，更新kch
        local pb = require "protobuf"
        local group_str = pb.encode("GroupInfo", v)
        db:set(v.groupid, group_str)
    end
end

local function auto_reset_gongxian()
    for k,v in ipairs(group_list_sort) do
        local m = rawget(v, "master")
        if m then
            local t = m.guid
            local total = m.today_gongxian[1] + m.today_gongxian[2] + m.today_gongxian[3]
            t = m.last_gongxian[1]
            table.insert(m.last_gongxian, total)
            table.remove(m.last_gongxian, 1)
            m.today_gongxian = {0,0,0}
        end
        local m2 = rawget(v, "master2")
        if m2 then
            local t = m2.guid
            local total = m2.today_gongxian[1] + m2.today_gongxian[2] + m2.today_gongxian[3]
            t = m2.last_gongxian[1]
            table.insert(m2.last_gongxian, total)
            table.remove(m2.last_gongxian, 1)
            m2.today_gongxian = {0,0,0}
        end
        local u_l = rawget(v, "user_list")
        if u_l then
            for k1,v1 in ipairs(u_l) do
                local t = v1.guid
                local total = v1.today_gongxian[1] + v1.today_gongxian[2] + v1.today_gongxian[3]
                t = v1.last_gongxian[1]
                table.insert(v1.last_gongxian, total)
                table.remove(v1.last_gongxian, 1)
                v1.today_gongxian = {0,0,0}    
            end
        end
        --处理超过72小时没有上线的帮主
        if os.time() - m.last_act > 259200 then
            local new_m = nil
            if m2 and m2.last_gongxian[1] + m.last_gongxian[2] + m.last_gongxian[3] > 0 then
                -- 优先传给副帮主
                new_m = m2
                new_m.status = 1
                rawset(v, "master2", nil)
            elseif u_l then
                local max_gx = 0
                local max_idx = 0
                for k1,v1 in ipairs(u_l) do
                    local t = v1.last_gongxian[1] + v1.last_gongxian[2] + v1.last_gongxian[3]
                    if t > 0 and t > max_gx then
                        max_gx = t
                        max_idx = k1
                        new_m = v1
                    end
                end
                if new_m then
                    new_m.status = 1
                    table.remove(u_l, max_idx)
                end
            end
            if new_m then   --找到新帮主
                local text = string.format(lang.group_master_msg2, new_m.nickname)
                local mail = {
                    type = 0,
                    from = lang.group_mail_sender,
                    subject = lang.group_master_title,
                    message = text,
                    stamp = os.time(),
                    expiry_stamp = os.time() + 604800,
                    guid = 0,
                }
                if new_m then
                    redo_list.add_mail(new_m.username, mail)
                end
                if rawget(v, "master2") then
                    redo_list.add_mail(m2.username, mail)
                end
                redo_list.add_mail(m.username, mail)
                if u_l then
                    for k1,v1 in ipairs(u_l) do
                        redo_list.add_mail(v1.username, mail)
                    end
                end
                m.status = 3
                if not u_l then
                    u_l = {}
                    rawset(v, "user_list", u_l)
                end
                table.insert(u_l, m)
                rawset(v, "master", new_m)
                LOG_INFO(string.format("change_master_auto|%s|%s --> %s", v.groupid, m.username, new_m.username))
            end
        end
        --全部处理完，更新kch
        local pb = require "protobuf"
        local group_str = pb.encode("GroupInfo", v)
        db:set(v.groupid, group_str)
    end
end

local last_reflesh = os.time()

function group_cache.do_timer()
    local now_time = os.time()
    local new_day21 = get_dayid_from(now_time, 21)
    if new_day21 ~= cur_day_21 then
        auto_allot_reward()
        cur_day_21 = new_day21
        db:set("DAYID21", cur_day_21)
        LOG_INFO("auto_allot_reward, dayid = "..cur_day_21)
    end
    local new_day0 = get_dayid_from(now_time, 0)
    if new_day0 ~= cur_day_0 then
        auto_reset_gongxian()
        cur_day_0 = new_day0
        db:set("DAYID0", cur_day_0)
        LOG_INFO("auto_reset_gongxian, dayid = "..cur_day_0)
    end
    local new_day5 = get_dayid_from(now_time, 5)
    if new_day5 ~= cur_day_5 then
        reset_allot_num()
        cur_day_5 = new_day5
        db:set("DAYID5", cur_day_5)
        LOG_INFO("auto_reset_allotnum, dayid = "..cur_day_5)
    end
    if (now_time - last_reflesh) >= 1800 then
        table.sort(group_list_sort, sort_group)
        last_reflesh = now_time
        LOG_INFO("reflesh group_list_sort")
    end
end

function gc_rollback()
    group_cache.rollback()
end

return group_cache