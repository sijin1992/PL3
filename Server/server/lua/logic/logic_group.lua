local core_user = require "core_user_funcs"
local core_money = require "core_money"
local core_fight = require "fight"
local Monster = require "fight_monster"
local core_drop = require "core_drop"
local core_send_mail = require "core_send_mail"

local tinsert = table.insert

local MIN_LEVEL = 30

local logic_group = {}

local function hurt_rank_sort(a, b)
    if a.value > b.value then return true
    else return false end
end

local function find_player_from_group(group_data, main_data)
    local group_user = nil
    local user_name = main_data.user_name
    local status = 0
    if group_data.master.username == user_name then
        group_user = group_data.master
        status = 1
    end
    if not group_user and rawget(group_data, "master2") and group_data.master2.username == user_name then
        group_user = group_data.master2
        status = 2
    end
    if not group_user and rawget(group_data, "user_list") then
        for k,v in ipairs(group_data.user_list) do
            if v.username == user_name then
                group_user = v
                status = 3
                break
            end
        end
    end
    return group_user, status
end

-- 封装代码，验证玩家是不是在这个帮派，以及确定角色等级
-- master=1：帮主|副帮主；2：帮主；3：副帮主；nil：不用判定
local function find_player_in_group(main_data, group_data, master, just_check)
    assert(group_data, "group_data is nil")
    local user_group_data = rawget(main_data, "group_data")
    assert(user_group_data and user_group_data.groupid == group_data.groupid, "groupid err")
    local group_user,status = find_player_from_group(group_data, main_data)
    if just_check then
        return user_group_data, group_user, status
    end
    assert(group_user, "user not in this group")
    --玩家的身份可能因活跃度等改变，所以要重新刷新
    local t = user_group_data.status
    user_group_data.status = status
    if master == 1 then
        assert(status == 1 or status == 2, "user is not master/master2")
    elseif master == 2 then
        assert(status == 1, "user is not master")
    elseif master == 3 then
        assert(status == 2, "user is not master2")
    end
    return user_group_data, group_user, status
end

local function find_player_in_group_by_guid(group_data, guid)
    local group_user = nil
    local status = 0
    if group_data.master.guid == guid then
        group_user = group_data.master
        status = 1
    end
    if not group_user and rawget(group_data, "master2") and group_data.master2.guid == guid then
        group_user = group_data.master2
        status = 2
    end
    if not group_user and rawget(group_data, "user_list") then
        for k,v in ipairs(group_data.user_list) do
            if v.guid == guid then
                group_user = v
                status = 3
                break
            end
        end
    end
    return group_user, status
end

local function fill_multicast(group_data)
    local recv_list = {}
    tinsert(recv_list, group_data.master.username)
    if rawget(group_data, "master2") then
        tinsert(recv_list, group_data.master2.username)
    end
    if rawget(group_data, "user_list") then
        for k,v in ipairs(group_data.user_list) do
            tinsert(recv_list, v.username)
        end
    end
    local cmd = 0x16ff
    local multicast = {
        recv_list = recv_list,
        cmd = cmd,
        group_data = {group_data = group_data, user_update_list = {}},
    }
    return multicast
end

local function reflesh_reward_list(group_data)
    -- 处理战利品
    local reward_list = rawget(group_data, "reward_list")
    if reward_list == nil then
        --print("reward list is nil when reflesh", group_data.groupid)
        return
    end
    local fortress_list = rawget(group_data, "fortress_list")
    if fortress_list == nil then
        return
    end
    
    local need_remove_list = {}
    --遍历所有战利品列表。如果num为0，没人申请，相关副本又关闭了，则可以删除
    for k,v in ipairs(reward_list) do
        local num = v.item_num
        if rawget(v, "ask_list") then
            local t = v.ask_list[1]
            if num == 0 and rawlen(v.ask_list) == 0 then
                local need_remove = true
                for k1,v1 in ipairs(v.fortress_id) do
                    for k2,v2 in ipairs(fortress_list) do
                        if v2.fortress_id == v1 then
                            if v2.finished == 0 then
                                need_remove = false
                                break
                            end
                        end
                    end
                    if not need_remove then
                        break
                    end
                end
                if need_remove then table.insert(need_remove_list, k) end
            end
        end
    end
    for k = rawlen(need_remove_list), 1, -1 do
        table.remove(reward_list, need_remove_list[k])
    end
end

function logic_group.create(main_data, nickname)
    local dirty = false
    assert(nickname ~= "")
    for _,dirty_word in ipairs(dirty_word) do
        if string.find(nickname, dirty_word) then
            return 1
        end
    end
    local check_nickname = true--group_cache.check_nickname(nickname)
    if not check_nickname then
        return 2
    end
    
    local user_group_data = rawget(main_data, "group_data")
    if user_group_data then
        --group_cache.check_disband(main_data)
        --assert(user_group_data.groupid == "")
    end
    --assert(main_data.lead.level >= MIN_LEVEL, "level < 30")
    --core_money.use_money(1000, main_data, 1, 604)
    
    local user_name = main_data.user_name
    local groupid = "1234580001"
    local new_group = {
        groupid = groupid,
        ver = 1,
        level = 1,        
        nickname = nickname,
        dayid = 0,
        master = {
            username = user_name,
            nickname = user_name,
            vip = 0,
            weiwang = 0,
            sex = 1,
            level = 0,
            --today_gongxian = {0,0,0},
            total_gongxian = 0,
            guid = 1,
            sw = 0,
            status = 1,
            star = 0,
            last_act = os.time(),
            last_gongxian = {1,1,0}--创建时把前两天贡献设为非0，这样计算活跃度方便
        },
        guid = 2,
        money = 0,
        broadcast = "",
        juexue = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
        create_time = os.time()
    }
    --group_cache.update_group(new_group, true)
    
    
    if not user_group_data then
        user_group_data = {groupid = groupid,
            status = 1,
            --wxjy = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
            --shopping_list = core_user.reflesh_shopping_list(100164),
            }
        rawset(main_data, "group_data", user_group_data)
    else
        local t = user_group_data.status
        user_group_data.groupid = groupid
        user_group_data.status = 1
        --user_group_data.allot_num = 0
        t = user_group_data.wxjy[1]
        if not rawget(user_group_data, "wxjy") then
            rawset(user_group_data, "wxjy", {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})
        end
        --user_group_data.shopping_list = core_user.reflesh_shopping_list(100164)
    end
    
    return 0, new_group, user_group_data
end

function logic_group.get_group_data(group_data, main_data)
    if group_data.groupid == "" then
        return nil
    end
    group_cache.merge_cache_to(group_data)
    reflesh_reward_list(group_data)
    local t, gu = find_player_in_group(main_data, group_data, 0, true)
    if not gu then
        local user_group_data = rawget(main_data, "group_data")
        if user_group_data then user_group_data.groupid = "" end
        return nil
    end
    group_cache.update_group(group_data)
    return group_data
end

function logic_group.juanxian(main_data, group_data, req)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data)
    
    local multicast = fill_multicast(group_data)
    
    local type = req.type
    local value = req.value
    local num = req.num
    if num == 0 then num = 1 end
    assert(type > 0 and type < 4 and value > 0 and value < 4, "req err")
    local cost_list = {
        {100000, 1000000, 5000000},
        {100, 1000, 5000},
        {100, 1000, 5000}
    }
    local get_list = {10, 100, 500}
    local cost = cost_list[type][value] * num
    local get = get_list[value] * num
    
    local ret_item = {}
    if type == 1 then
        core_user.expend_item(191010001, cost, main_data, 601, nil, ret_item)
    elseif type == 2 then
        core_user.expend_item(191010057, cost, main_data, 601, nil, ret_item)
    else
        core_money.use_money(cost, main_data, 1, 601)
    end
    local rsync = {item_list = ret_item, cur_gold = main_data.gold, cur_money = main_data.money,
        cur_tili = main_data.tili}
    
    local t = group_user.sw + get
    group_user.sw = t
    
    t = group_user.today_gongxian[1]
    if rawget(group_user, "today_gongxian") == nil then
        rawset(group_user, "today_gongxian", {0,0,0})
    end
    t = group_user.today_gongxian[type] + get
    assert(t <= 10000, "too much gongxian today")
    group_user.today_gongxian[type] = t
    t = group_user.total_gongxian + get
    group_user.total_gongxian = t
    
    t = user_group_data.total_sw + get
    user_group_data.total_sw = t
    core_user.get_item(191010027, get, main_data, 603, nil, nil, rsync)
    --t = user_group_data.sw + get
    --user_group_data.sw = t
    
    t = group_data.money + get
    group_data.money = t
    
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
        
    group_cache.update_group(group_data)
    return rsync, main_data.xyshop.ghost, user_group_data, group_data, multicast
end

function logic_group.levelup(main_data, group_data)    
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data, 1)
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
    
    local cur_level = group_data.level
    local conf = Men_Exp_conf[cur_level]
    assert(conf, "conf not find")
    assert(conf.COST > 0, "max level")
    assert(group_data.money >= conf.COST, "money not enough")
    group_data.money = group_data.money - conf.COST
    group_data.level = cur_level + 1
    group_cache.update_group(group_data)
    return group_data, cur_level, multicast
end

function logic_group.juexue(main_data, group_data,juexue_idx)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data, 1)
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
    
    assert((juexue_idx >= 1 and juexue_idx <= 9) or (juexue_idx >= 11 and juexue_idx <= 19), "juexue_idx err")
    local juexue_lev = group_data.juexue[juexue_idx]
    
    local cur_level = group_data.level
    local conf = Men_Exp_conf[cur_level]
    assert(conf, "conf not find")
    assert(juexue_lev < conf.JUEXUE_LEVEL, "juexue is top")
    local juexue_conf = Men_Extreme_conf[juexue_lev]
    assert(juexue_conf, "juexue conf not find")
    local cost = juexue_conf.COST
    assert(cost > 0, "max level")
    assert(group_data.money >= cost, "money not enough")
    group_data.money = group_data.money - cost
    group_data.juexue[juexue_idx] = juexue_lev + 1
    group_cache.update_group(group_data)
    return group_data, juexue_lev, multicast
end

function logic_group.broadcast(main_data, group_data, broadcast)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data, 1)
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
    
    local dirty = false
    for _,dirty_word in ipairs(dirty_word) do
        if string.find(broadcast, dirty_word) then
            dirty = true
            break
        end
    end
    if not dirty then
        group_data.broadcast = broadcast
    end
    
    return dirty, group_data, multicast
end

function logic_group.wxjy(main_data, group_data,wxjy_idx)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data)
    
    assert((wxjy_idx >= 1 and wxjy_idx <= 9) or (wxjy_idx >= 11 and wxjy_idx <= 19), "wxjy_idx err")
    local cur_wxjy = user_group_data.wxjy[wxjy_idx]
    local cur_top = group_data.juexue[wxjy_idx]
    assert(cur_wxjy < cur_top)
    -- 这个配置比较特殊，每一栏陪的是，升到这一级，需要多少材料
    local tag_level = cur_wxjy + 1
    
    local wxjy_conf = Men_Extreme_conf[tag_level]
    assert(wxjy_conf, "wxjy conf not find")
    local cost = wxjy_conf.Price
    core_user.expend_item(191010027, cost, main_data, 605)
    --assert(user_group_data.sw >= cost, "sw not enough")
    --user_group_data.sw = user_group_data.sw - cost
    user_group_data.wxjy[wxjy_idx] = tag_level
        
    return user_group_data
end



function logic_group.pve_reset(main_data, group_data, fortress_id, first_flag)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data, 1)
    local fortress_conf = Men_Fortress_conf[fortress_id]
    assert(fortress_conf, "fortress_id err, not find conf")
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
    
    local fortress_list = rawget(group_data, "fortress_list")
    if fortress_list == nil then
        fortress_list = {}
        rawset(group_data, "fortress_list", fortress_list)
    end
    local fortress_data = nil
    if first_flag then
        --首次开启，那么以前不应该有，而且是接着已开的最后一章
        local last_stage = 0
        for k,v in ipairs(fortress_list) do
            last_stage = v.fortress_id
            -- 既然是开新章，以前的肯定都通关过了吧
            assert(v.pass_num > 0, "pass front fortress first")
            if v.fortress_id == fortress_id then
                error("fortress exist")
            end
        end
        assert(last_stage == fortress_conf.FRONT_FORTRESS_ID)
        --构建stage_list
        local stage_list = {}
        for k,v in ipairs(fortress_conf.STAGE_LIST) do
            local s_conf = Men_Stage_conf[v]
            assert(s_conf, "Men_Stage_conf not find")
            local max_hp = 0
            for k1,v1 in ipairs(s_conf.NPC_LIST) do
                if v1 ~= 0 then
                    local n_conf = Npc_conf[v1]
                    assert(n_conf, "npc "..v1.." not find")
                    max_hp = max_hp + n_conf.LIFE
                end
            end
            local s = {
                stage_id = s_conf.ID,
                sub_hp = {0,0,0,0,0,0,0},
                max_hp = max_hp
            }
            table.insert(stage_list, s)
        end
        fortress_data = {
            fortress_id = fortress_id,
            stage_list = stage_list,
        }
        table.insert(fortress_list, fortress_data)
    else
        --看看库银够不够，不够就不用往下走了
        assert(group_data.money >= fortress_conf.CHONGZHI)
        group_data.money = group_data.money - fortress_conf.CHONGZHI
        
        -- 重置已有副本
        for k,v in ipairs(fortress_list) do
            if v.fortress_id == fortress_id then
                fortress_data = v
                break
            end
        end
        -- 肯定应该在已有列表中
        assert(fortress_data, "fortress_data not find")
        -- 应该是已通关状态
        assert(fortress_data.finished ~= 0)
        rawset(fortress_data, "rank_list", nil)
    end
    --重置章节数据
    fortress_data.fast_time = os.time() + fortress_conf.FAST_REWARD_LIMIT * 86400
    fortress_data.finished = 0
    for k,v in ipairs(fortress_data.stage_list) do
        local t = v.sub_hp[1]
        v.finished = 0
        v.sub_hp = {0,0,0,0,0,0,0}
    end
    -- 处理战利品
    local reward_list = rawget(group_data, "reward_list")
    if reward_list == nil then
        reward_list = {}
        rawset(group_data, "reward_list", reward_list)
    end
    for k,v in ipairs(fortress_conf.PHASE_REWARD_LIST) do
        local find = false
        for k1,v1 in ipairs(reward_list) do
            if v1.item_id == v then
                find = true
                local find_f = false
                for k2,v2 in ipairs(v1.fortress_id) do
                    if v2 == fortress_id then
                        find_f = true
                        break
                    end
                end
                if not find_f then table.insert(v1.fortress_id, fortress_id) end
                break
            end
        end
        if not find then
            local reward = {
                item_id = v,
                item_num = 0,
                fortress_id = {fortress_id}
            }
            table.insert(reward_list, reward)
        end
    end
    --printtab(reward_list)
    group_cache.update_group(group_data)
    return group_data, multicast
end

function logic_group.pve(main_data,knight_list, group_data, stage_id, fortress_id)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data)
    local group_info = group_cache.get_group(group_data.groupid)
    assert(group_info, "group_info not exist")
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
    
    local fortress_list = rawget(group_data, "fortress_list")
    assert(fortress_list, "no fortress_list")
    
    --获取group的fortress 和 stage 的结构
    local fortress_data = nil
    local stage_data = nil
    for k,v in ipairs(fortress_list) do
        if v.fortress_id == fortress_id then
            for k1,v1 in ipairs(v.stage_list) do
                if v1.stage_id == stage_id then
                    stage_data = v1
                    break
                end
            end
            fortress_data = v
            break
        end
    end
    assert(fortress_data,"fortress_data not find")
    assert(stage_data, "stage_data not find")
    assert(fortress_data.finished == 0, "fortress passed")
    assert(stage_data.finished == 0, "stage passed")
    
    --获取配置
    local fortress_conf = Men_Fortress_conf[fortress_id]
    local stage_conf = Men_Stage_conf[stage_id]
    assert(fortress_conf and stage_conf, "config not find")
    
    --查询玩家自己的fortress结构，看看有没有这个fortress
    local user_fortress_data = nil
    local last_fortress = 650000000
    local t = user_group_data.fortress_list[1]
    local user_fortress_list = rawget(user_group_data, "fortress_list")
    if not user_fortress_list then
        user_fortress_list = {}
        rawset(user_group_data, "fortress_list", user_fortress_list)
    end
    for k,v in ipairs(user_fortress_list) do
        last_fortress = v.id
        if last_fortress == fortress_id then
            -- 找到了，不容易啊
            user_fortress_data = v
            break
        end
    end
    if last_fortress ~= fortress_id then
        assert(not user_fortress_data,"why has user_fortress_data")
        assert(last_fortress < fortress_id)
        assert((fortress_id - last_fortress)%10001 == 0)
        for k = last_fortress + 10001, fortress_id, 10001 do
            local t_fortress = {id = k, pass_num = 0, total_pass_num = 0}
            table.insert(user_fortress_list, t_fortress)
            if k == fortress_id then user_fortress_data = t_fortress end
        end
    end
    assert(user_fortress_data, "not find user_fortress_data")
    assert(user_fortress_data.pass_num < 2)
    
    local fight = core_fight:new()
    local rcd = fight.rcd
    local preview = rcd.preview
    preview.winner = 0
    local role_list = fight.role_list
    local posi_list = fight.posi_list
    for k,v in ipairs(stage_conf.NPC_LIST) do
        if v ~= 0 then
            local is_boss = false
            for k1,v1 in ipairs(stage_conf.BOSS_ID) do
                if k == v1 then
                    is_boss = true
                    break
                end
            end
            local monster = Monster:new(v, k + 100, 1, is_boss)
            monster.sub_hp = stage_data.sub_hp[k]
            tinsert(role_list, monster)
            rawset(posi_list, k + 100, monster)
        end
    end
    fight:get_player_data(main_data, knight_list)
    fight:get_attrib()
    for k = 1, 7 do
        local role = posi_list[k]
        if role then
            role.hp = role.hp-- * 10
            role.att = role.att-- * 10
            role.speed = role.speed-- * 10
        end
    end
    -- 更新hp
    for k = 101, 107 do
        local role = posi_list[k]
        if role then
            assert(role.sub_hp)
            local now_hp = role.hp
            if role.sub_hp > 0 then
                now_hp = now_hp - role.sub_hp
            elseif role.sub_hp < 0 then
                now_hp = 0
            end
            if now_hp < 0 then now_hp = 0 end
            role.hp = now_hp
        end
    end
    
    -- 这里必须先获取原始preview，排序之后顺序就乱了
    fight:get_preview_role_list()
    fight:play(rcd)
    local winner = fight.winner
    --user_fortress_data.pass_num = user_fortress_data.pass_num + 1
    --user_fortress_data.total_pass_num = user_fortress_data.total_pass_num + 1
    
    --更新伤害排行榜
    local hurt = fight.hurt[1]
    local rank_list = rawget(fortress_data, "rank_list")
    if not rank_list then
        rank_list = {}
        rawset(fortress_data, "rank_list", rank_list)
    end
    local find_rank = false
    for k,v in ipairs(rank_list) do
        if v.guid == group_user.guid then
            find_rank = true
            v.value = v.value + hurt
            break
        end
    end
    if not find_rank then
        tinsert(rank_list, {guid = group_user.guid, value = hurt})
    end
    table.sort(rank_list, hurt_rank_sort)
    
    --计算奖励获得
    local reward_conf = nil
    for k,v in ipairs(Men_Damage_Reward_conf.index) do
        if hurt >= v then
            reward_conf = Men_Damage_Reward_conf[v]
        else
            break
        end
    end
    assert(reward_conf, "reward_conf not find")
    local rsync = {item_list = {}, cur_money = main_data.money, cur_gold = main_data.gold, cur_tili = main_data.tili}
    if reward_conf.METAL > 0 then
        core_user.get_item(191010025, reward_conf.METAL, main_data, 601, nil, nil, rsync)
    end
    core_user.get_item(191010001, reward_conf.MONEY, main_data, 601, nil, nil, rsync)
    rsync.cur_gold = main_data.gold
    
    local pass = true
    for k = 101, 107 do
        local role = posi_list[k]
        if role then
            local sub_hp = 0
            if role.hp <= 0 then sub_hp = -role.max_hp
            else sub_hp = role.max_hp - role.hp end
            stage_data.sub_hp[k - 100] = sub_hp
            if sub_hp > 0 then pass = false end
        end
    end
    local fortress_pass = true
    if pass then
        stage_data.finished = 1
        for k,v in ipairs(fortress_data.stage_list) do
            if v.finished == 0 then
                fortress_pass = false
                break
            end
        end
        if fortress_pass then
            fortress_data.finished = 1
            fortress_data.pass_num = fortress_data.pass_num + 1
            
            --:快速通关判定
            local fortress_name = lang[fortress_id]
            if os.time() <= fortress_data.fast_time then
                local text = string.format(lang.group_fast_msg, fortress_name)
                local mail = {
                    type = 10,
                    from = lang.group_mail_sender,
                    subject = lang.group_fast_title,
                    message = text,
                    stamp = os.time(),
                    expiry_stamp = os.time() + 604800,
                    guid = 0,
                    item_list = {{id = fortress_conf.FAST_REWARD[1], num = fortress_conf.FAST_REWARD[2]}}
                }
                if rawget(group_data, "master") then
                    redo_list.add_mail(group_data.master.username, mail)
                end
                if rawget(group_data, "master2") then
                    redo_list.add_mail(group_data.master2.username, mail)
                end
                if rawget(group_data, "user_list") then
                    for k,v in ipairs(group_data.user_list) do
                        redo_list.add_mail(v.username, mail)
                    end
                end
            end
            --伤害排行
            
            for k,v in ipairs(rank_list) do
                local num = fortress_conf.RANK_REWARD_LIST[k]
                if num == nil then break end
                local user = find_player_in_group_by_guid(group_data, v.guid)
                local text = string.format(lang.group_rank_list_msg, fortress_name, v.value, k)
                if user then
                    local mail = {
                        type = 10,
                        from = lang.group_mail_sender,
                        subject = lang.group_rank_list_title,
                        message = text,
                        stamp = os.time(),
                        expiry_stamp = os.time() + 604800,
                        guid = 0,
                        item_list = {{id = 191010025, num = num}}
                    }
                    
                    redo_list.add_mail(user.username, mail)
                end
            end
            
        end
        -- 获取战利品
        local reward_list = rawget(group_data, "reward_list")
        if not reward_list then
            reward_list = {}
            rawset(group_data, "reward_list", reward_list)
        end
        local t_list = {}
        core_drop.get_item_list_from_id(stage_conf.STAGE_REWARD, t_list)
        for _,v in ipairs(t_list) do
            local find = false
            for k1,v1 in ipairs(reward_list) do
                local t = v1.item_id
                if v1.item_id == v[1] then
                    v1.item_num = v1.item_num + v[2]
                    find = true
                    break
                end
            end
        end
        --printtab(t_list, "t_list:")
        group_cache.update_group(group_data)
    end
    return rcd, group_data, user_group_data, hurt, rsync, multicast
end

function logic_group.reset_self_pve(main_data, fortress_id, group_data)
    local user_group_data = rawget(main_data, "group_data")
    assert(user_group_data, "not in group err")
    
    local user_fortress_data = nil
    local t = user_group_data.fortress_list[1]
    local user_fortress_list = rawget(user_group_data, "fortress_list")
    assert(user_fortress_list, "fortress_list not find")
    for k,v in ipairs(user_fortress_list) do
        if v.id == fortress_id then
            -- 找到了，不容易啊
            user_fortress_data = v
            break
        end
    end
    assert(user_fortress_data, "fortress_data not find")
    
    local cost = 300
    local today_reset = user_fortress_data.reset
    local men_conf = Men_Exp_conf[group_data.level]
    assert(men_conf)
    assert(today_reset < men_conf.CHONGZHI)
    
    if today_reset == 0 then cost = 100
    elseif today_reset == 1 then cost = 200 end
    
    local ret_item = {}
    core_money.use_money(cost, main_data, 1, 602)
    user_fortress_data.reset = today_reset + 1
    user_fortress_data.pass_num = 0
    user_fortress_data.total_reset_num = user_fortress_data.total_reset_num + 1
    
    local rsync = {item_list = ret_item, cur_gold = main_data.gold, cur_money = main_data.money,
        cur_tili = main_data.tili}
    return user_group_data, rsync
end

function logic_group.ask_reward(main_data, group_data, item_id)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data)
    local user_group_data = rawget(main_data, "group_data")
    assert(user_group_data, "not in group err")
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
    
    local reward_list = rawget(group_data, "reward_list")
    assert(reward_list, "reward_list not find")
    local tag_item_data = nil
    local old_item_data = nil
    local old_idx = 0
    for k,v in ipairs(reward_list) do
        if v.item_id == item_id then
            tag_item_data = v
        end
        if rawget(v, "ask_list") then
            for k1,v1 in ipairs(v.ask_list) do
                if v1.guid == group_user.guid then
                    old_item_data = v
                    table.remove(v.ask_list, k1)
                    break
                end
            end
        end
    end
    --已经申请过这个东西了
    assert(tag_item_data ~= old_item_data, "same item")
    assert(tag_item_data, "not find the item")
    local ask_list = rawget(tag_item_data, "ask_list")
    if not ask_list then
        ask_list = {}
        rawset(tag_item_data, "ask_list", ask_list)
    end
    tinsert(ask_list, {guid = group_user.guid, username = group_user.username})
    group_cache.update_group(group_data)
    return group_data, multicast
end

function logic_group.allot_reward(main_data, group_data, item_id, guid)
    group_cache.merge_cache_to(group_data)
    --assert(group_data.allot_num == 0)
    --group_data.allot_num = group_data.allot_num + 1
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data, 2)
    local user_group_data = rawget(main_data, "group_data")
    assert(user_group_data, "not in group err")
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
    
    local t = user_group_data.allot_num
    assert(t == 0, "allot num is not 0")
    --user_group_data.allot_num = t + 1
    
    -- 找到受益者
    local winner = find_player_in_group_by_guid(group_data, guid)
    assert(winner)

    local reward_list = rawget(group_data, "reward_list")
    assert(reward_list, "reward_list not find")
    local tag_item_data = nil
    for k,v in ipairs(reward_list) do
        if v.item_id == item_id then
            tag_item_data = v
        end
    end
    assert(tag_item_data, "not find the item")
    assert(tag_item_data.item_num > 0)
    --[[没有受害者了
    -- 找受害者
    local loser = nil
    local t = tag_item_data.ask_list[1]
    local ask_list = rawget(tag_item_data, "ask_list")
    if ask_list and rawlen(ask_list) >= tag_item_data.item_num then
        local loser_guid = ask_list[tag_item_data.item_num]
        loser = find_player_in_group_by_guid(group_data, loser_guid)
    end
    ]]
    tag_item_data.item_num = tag_item_data.item_num - 1
    
    --邮件1：通知邮件
    local text = string.format(lang.group_allot_msg, Item_conf[tag_item_data.item_id].CN_NAME,
        winner.nickname)
    
    local mail = {
        type = 0,
        from = lang.group_mail_sender,
        subject = lang.group_allot_title,
        message = text,
        stamp = os.time(),
        expiry_stamp = os.time() + 604800,
        guid = 0,
    }
    if rawget(group_data, "master") then
        if group_data.master.username ~= winner.username then
            redo_list.add_mail(group_data.master.username, mail)
        end
    end
    if rawget(group_data, "master2") then
        if group_data.master2.username ~= winner.username then
            redo_list.add_mail(group_data.master2.username, mail)
        end
    end
    if rawget(group_data, "user_list") then
        for k,v in ipairs(group_data.user_list) do
            if v.username ~= winner.username then
                redo_list.add_mail(v.username, mail)
            end
        end
    end
    
    --邮件2，附件
    text = string.format(lang.group_allot2_msg, Item_conf[tag_item_data.item_id].CN_NAME)
    local mail2 = {
        type = 10,
        from = lang.group_mail_sender,
        subject = lang.group_allot2_title,
        message = text,
        stamp = os.time(),
        expiry_stamp = os.time() + 604800,
        guid = 0,
        item_list = {{id = tag_item_data.item_id, num = 1}}
    }
    redo_list.add_mail(winner.username, mail2)
    
    LOG_INFO(string.format("group_allot %s, %s --> %d", group_data.groupid, winner.username, tag_item_data.item_id))
    group_cache.update_group(group_data)
    return group_data, user_group_data, multicast
end

function logic_group.search_group(groupid, page)
    local ret, t = group_cache.search_group(groupid, page)
    if ret then
        if not groupid or groupid == "" then
            if t then
                return true, t, math.floor((group_cache.group_count() + 4) / 5)
            else
                return true, t, 0
            end
        else
            if t then
                return true, t, 1
            else
                return true, t, 0
            end
        end
    else return false
    end
end

--请求加入门派
function logic_group.join_req(main_data, group_data)
    assert(main_data.lead.level >= MIN_LEVEL, "level < 30")
    assert(group_data, "group_data is nil")
    group_cache.merge_cache_to(group_data)
    local user_group_data = rawget(main_data, "group_data")
    if user_group_data then
        group_cache.check_disband(main_data)
        assert(user_group_data.groupid == "")
        assert(user_group_data.today_join_num <= 3)
        assert(user_group_data.anti_time == 0 or user_group_data.anti_time < os.time())
    end
    
    local t_list = rawget(group_data, "join_list")
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
        rawset(group_data, "join_list", t_list)
    end
    tinsert(t_list, {username = main_data.user_name,
        nickname = main_data.nickname,
        vip = main_data.vip_lev, sex = main_data.lead.sex, level = main_data.lead.level,
        star = main_data.lead.star})
    
    if not user_group_data then
        user_group_data =  {groupid = "",
            status = 0,
            wxjy = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
            today_join_num = 0}
        rawset(main_data, "group_data", user_group_data)
    end
    user_group_data.today_join_num = user_group_data.today_join_num + 1
    local group_info = group_cache.update_group(group_data)--group_cache.join_req(main_data, group_data)
    return user_group_data, group_data, group_info
end

--批准加入门派
function logic_group.allow_join(main_data, group_data, main_data2, type, mail_list2)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data, 1)
    local join_list = rawget(group_data, "join_list")
    assert(join_list, "join_list not find")
    local join_idx = 0
    for k,v in ipairs(join_list) do
        if v.username == main_data2.user_name then
            join_idx = k
            break
        end
    end
    assert(join_idx ~= 0, "no join req")
    table.remove(join_list, join_idx)
    local code = 0
    local user_group_data2 = nil
    if type == 0 then
        user_group_data2 = rawget(main_data2, "group_data")
        assert(user_group_data2, "user_group_data2 not find")
        if(user_group_data2.groupid ~= "") then
            local group_info = group_cache.update_group(group_data)
            return group_data, group_info, 1
        end
        user_group_data2.groupid = group_data.groupid
        user_group_data2.total_sw = 0
        user_group_data2.status = 3
        --user_group_data2.allot_num = 0
        user_group_data2.shopping_list = core_user.reflesh_shopping_list(100164)
        
        local group_user2 = {
                username = main_data2.user_name,
                nickname = main_data2.nickname,
                weiwang = 0,
                vip = main_data2.vip_lev,
                sex = main_data2.lead.sex,
                level = main_data2.lead.level,
                today_gongxian = {0,0,0},
                total_gongxian = 0,
                sw = 0,
                guid = group_data.guid,
                status = 3,
                star = main_data2.lead.star,
                last_act = os.time(),
                last_gongxian = {1,1,0}
            }
        group_data.guid = group_data.guid + 1
        local user_list = rawget(group_data, "user_list")
        if not user_list then
            user_list = {}
            rawset(group_data, "user_list", user_list)
        end
        local num = 1
        if rawget(group_data, "master2") then num = num + 1 end
        num = num + rawlen(user_list)
        if num >= 20 then
            LOG_ERROR("group member is max")
            code = 2
            local group_info = group_cache.update_group(group_data)
            return group_data, group_info, code, nil
        end
        tinsert(user_list, group_user2)
        local text = string.format(lang.group_join_msg, group_data.nickname)
        local mail = {
            type = 0,
            from = lang.group_mail_sender,
            subject = lang.group_join_title,
            message = text,
            stamp = os.time(),
            expiry_stamp = os.time() + 604800,
            guid = 0,
        }
        core_send_mail.send_mail(main_data2, mail_list2, mail)
    end
    local group_info = group_cache.update_group(group_data)
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
    if type == 0 then
        tinsert(multicast.group_data.user_update_list,
            {user_group_data = user_group_data2, user_name = main_data2.user_name})
    end
    return group_data, group_info, code, multicast
end

function logic_group.exit(main_data, group_data)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data)
    assert(status ~= 1, "master can not exit")
    
    local ret = 0

    if status == 2 then 
        if group_data.master2 and group_data.master2.unlocktime ~= nil then
            if os.time() < group_data.master2.unlocktime then
                LOG_ERROR("user in locktime, can't exit! "..(group_data.master2.unlocktime - os.time()))
                ret = -2
                --[[
                local group_info = group_cache.update_group(group_data)
                local multicast = fill_multicast(group_data)
                multicast.group_data.user_name = main_data.user_name
                tinsert(multicast.group_data.user_update_list,
                    {user_group_data = user_group_data, user_name = main_data.user_name})
                ]]
                return ret, group_data, nil, user_group_data
            end
        end
        rawset(group_data, "master2", nil)
    else
        local user_list = rawget(group_data, "user_list")
        assert(user_list)
        for k,v in ipairs(user_list) do
            if v.username == main_data.user_name then
                if v.unlocktime ~= nil then
                    if os.time() < v.unlocktime then
                        LOG_ERROR("user in locktime, can't exit! ".. (v.unlocktime - os.time()))
                        ret = -2
                        --[[
                        local group_info = group_cache.update_group(group_data)
                        local multicast = fill_multicast(group_data)
                        multicast.group_data.user_name = main_data.user_name
                        tinsert(multicast.group_data.user_update_list,
                            {user_group_data = user_group_data, user_name = main_data.user_name})
                        ]]
                        return ret, group_data, nil,user_group_data
                    end
                end
                table.remove(user_list, k)
                break
            end
        end
    end


    user_group_data.groupid = ""
    user_group_data.total_sw = 0
    user_group_data.status = 0
    --user_group_data.allot_num = 0
    user_group_data.today_join_num = 0
    user_group_data.anti_time = os.time() + 43200
    --被踢出和主动退出门派，不重置挑战次数
    --rawset(user_group_data, "fortress_list", nil)

    
    -- 退出公会的话，清掉这个人在公会中的所有痕迹
    local reward_list = rawget(group_data, "reward_list")
    if reward_list then
        for k,v in ipairs(reward_list) do
            local t = v.item_id
            t = rawget(v, "ask_list")
            if t then
                for k1,v1 in ipairs(t) do
                    if v1.guid == group_user.guid then
                        table.remove(t, k1)
                        break
                    end
                end
            end
        end
    end
    local fortress_list = rawget(group_data, "fortress_list")
    if fortress_list then
        for k,v in ipairs(fortress_list) do
            local t = v.fortress_id
            t = rawget(v, "rank_list")
            if t then
                for k1, v1 in ipairs(t) do
                    if v1.guid == group_user.guid then
                        table.remove(t, k1)
                        break
                    end
                end
            end
        end
    end
    
    local group_info = group_cache.update_group(group_data)
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
    
    return ret, group_data, group_info,user_group_data, multicast
end

function logic_group.kick(main_data, group_data, main_data2, mail_list2)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data,1)
    local user_group_data2, group_user2, status2 = find_player_in_group(main_data2, group_data)
    assert(status < status2, "power err")
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data2, user_name = main_data2.user_name})
    
    if status2 == 2 then 
        if group_data.master2 and group_data.master2.unlocktime ~= nil then
            if os.time() < group_data.master2.unlocktime then
                LOG_ERROR("user in locktime, can't kick! "..(group_data.master2.unlocktime - os.time()) )
                local ret = -2
                --local group_info = group_cache.update_group(group_data)
                return ret, group_data
            end
        end
        rawset(group_data, "master2", nil)
    else
        local user_list = rawget(group_data, "user_list")
        assert(user_list)
        for k,v in ipairs(user_list) do
            if v.username == main_data2.user_name then
                if v.unlocktime then
                    if os.time() < v.unlocktime then
                        LOG_ERROR("user in locktime, can't kick! ".. (v.unlocktime - os.time()))
                        local ret = -2
                        --local group_info = group_cache.update_group(group_data)
                        return ret, group_data
                    end
                end
                table.remove(user_list, k)
                break
            end
        end
    end

    user_group_data2.groupid = ""
    user_group_data2.total_sw = 0
    user_group_data2.status = 0
    --user_group_data2.allot_num = 0
    user_group_data2.anti_time = 0
    user_group_data2.today_join_num = 0
    --被踢出和主动退出门派，不重置挑战次数
    --rawset(user_group_data2, "fortress_list", nil)
    
    local mail = {
        type = 0,
        from = lang.group_mail_sender,
        subject = lang.group_kick_title,
        message = lang.group_kick_msg,
        stamp = os.time(),
        expiry_stamp = os.time() + 604800,
        guid = 0,
    }
    core_send_mail.send_mail(main_data2, mail_list2, mail)
    
    -- 退出公会的话，清掉这个人在公会中的所有痕迹
    local reward_list = rawget(group_data, "reward_list")
    if reward_list then
        for k,v in ipairs(reward_list) do
            local t = v.item_id
            t = rawget(v, "ask_list")
            if t then
                for k1,v1 in ipairs(t) do
                    if v1.guid == group_user2.guid then
                        table.remove(t, k1)
                        break
                    end
                end
            end
        end
    end
    local fortress_list = rawget(group_data, "fortress_list")
    if fortress_list then
        for k,v in ipairs(fortress_list) do
            local t = v.fortress_id
            t = rawget(v, "rank_list")
            if t then
                for k1, v1 in ipairs(t) do
                    if v1.guid == group_user2.guid then
                        table.remove(t, k1)
                        break
                    end
                end
            end
        end
    end
    
    local group_info = group_cache.update_group(group_data)
    
    return ret, group_data, group_info, multicast
end

--指定帮主副帮主
function logic_group.master(main_data, group_data, main_data2, type)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data,2)
    local user_group_data2, group_user2, status2 = find_player_in_group(main_data2, group_data)
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data, user_name = main_data.user_name})
    tinsert(multicast.group_data.user_update_list,
        {user_group_data = user_group_data2, user_name = main_data2.user_name})
    
    if type == 1 then
        -- 任命副帮主
        assert(status2 == 3)
        local user_list = rawget(group_data, "user_list")
        assert(user_list)
        for k,v in ipairs(user_list) do
            if v.username == main_data2.user_name then
                table.remove(user_list, k)
                break
            end
        end
        
        assert(not rawget(group_data, "master2"), "master2 exist")
        group_data.master2 = group_user2
        group_user2.status = 2
        user_group_data2.status = 2
        for k,v in ipairs(user_list) do
            if v.username == group_user2.username then
                table.remove(user_list, k)
                break
            end
        end
    elseif type == 2 then
        --退位
        group_data.master = group_user2
        group_user2.status = 1
        user_group_data2.status = 1
        local user_list = rawget(group_data, "user_list")
        if not user_list then
            user_list = {}
            rawset(group_data, "user_list", user_list)
        end
        group_user.status = 3
        user_group_data.status = 3
        tinsert(user_list, group_user)
        if status2 == 3 then
            for k,v in ipairs(user_list) do
                if v.username == main_data2.user_name then
                    table.remove(user_list, k)
                    break
                end
            end
        elseif status2 == 2 then
            rawset(group_data, "master2", nil)
        else
            error("status must be 2 or 3")
        end
    else--副帮主将为弟子
        assert(status2 == 2)
        group_data.master2 = nil
        group_user2.status = 3
        user_group_data2.status = 3
        local user_list = rawget(group_data, "user_list")
        if not user_list then
            user_list = {}
            rawset(group_data, "user_list", user_list)
        end
        tinsert(user_list, group_user2)
    end
    
    if type == 2 then
        local text = string.format(lang.group_master_msg, group_user.nickname, group_user2.nickname)
        local mail = {
            type = 0,
            from = lang.group_mail_sender,
            subject = lang.group_master_title,
            message = text,
            stamp = os.time(),
            expiry_stamp = os.time() + 604800,
            guid = 0,
        }
        if rawget(group_data, "master") then
            redo_list.add_mail(group_data.master.username, mail)
        end
        if rawget(group_data, "master2") then
            redo_list.add_mail(group_data.master2.username, mail)
        end
        if rawget(group_data, "user_list") then
            for k,v in ipairs(group_data.user_list) do
                redo_list.add_mail(v.username, mail)
            end
        end
    end
    local group_info = group_cache.update_group(group_data)
    
    return group_data, group_info, user_group_data, multicast
end

function logic_group.disband(main_data, group_data)
    group_cache.merge_cache_to(group_data)
    local user_group_data, group_user, status = find_player_in_group(main_data, group_data,2)
    local groupid = group_data.groupid
    
    if group_data.unlocktime ~= nil then
        if os.time() < group_data.unlocktime then
            LOG_ERROR("group in locktime, can't disband! ".. (group_data.unlocktime - os.time()) )
            return -2, group_data, user_group_data
        end
    end
    
    local multicast = fill_multicast(group_data)
    multicast.group_data.user_name = main_data.user_name
    
    user_group_data.groupid = ""
    user_group_data.total_sw = 0
    user_group_data.status = 0
    --user_group_data.allot_num = 0
    user_group_data.today_join_num = 0
    user_group_data.anti_time = 0
    --公会解散如果清挑战次数，玩家可以刷，所以也不请
    --rawset(user_group_data, "fortress_list", nil)
    
    local mail = {
        type = 0,
        from = lang.group_mail_sender,
        subject = lang.group_disband_title,
        message = lang.group_disband_msg,
        stamp = os.time(),
        expiry_stamp = os.time() + 604800,
        guid = 0,
    }
    if rawget(group_data, "master") then
        redo_list.add_mail(group_data.master.username, mail)
    end
    if rawget(group_data, "master2") then
        redo_list.add_mail(group_data.master2.username, mail)
    end
    if rawget(group_data, "user_list") then
        for k,v in ipairs(group_data.user_list) do
            redo_list.add_mail(v.username, mail)
        end
    end
    
    group_data.groupid = ""
    group_data.disband = 1
    group_cache.disband(groupid)
    return 0, group_data, user_group_data, multicast
end

function logic_group.reflesh_shop(main_data, item_list, free)
    local user_group_data = rawget(main_data, "group_data")
    assert(user_group_data and user_group_data.groupid ~= "", "groupid err")
    
    local rsync = {item_list = {}, cur_money = main_data.money}
    if free ~= 1 then
        local ret = core_user.expend_sxl(1, {main_data = main_data, item_list = item_list}, rsync.item_list, 603)
        if ret == -1 then
            core_money.use_money(20, main_data, 0, 603)
            rsync.cur_money = main_data.money
        end
    end
    local shop_list = nil
    shop_list = rawget(user_group_data, "shopping_list")
    if free ~= 1 then
        shop_list = core_user.reflesh_shopping_list(100164)
        user_group_data.shopping_list = shop_list
    end

    return shop_list, rsync
end

function logic_group.shopping(main_data, item_list, idx)
    local user_group_data = rawget(main_data, "group_data")
    assert(user_group_data and user_group_data.groupid ~= "", "groupid err")
    
    local gold = user_group_data.paizi
    local shopping_list = user_group_data.shopping_list
    local item = rawget(shopping_list, idx)
    assert(item, "item not exist")
    assert(item.num > 0, "item num is 0")
    local cost = item.price * item.num
    assert(gold >= cost, "pvp_gold not enough")
    user_group_data.paizi = gold - cost

    local ret_struct = {
        item_list = {},
        cost = cost,
        paizi = user_group_data.paizi
    }
    local item_id = item.id
    core_user.get_item(item_id, item.num, main_data, 602, nil, item_list, ret_struct, nil)
    item.num = 0
    return ret_struct
end

return logic_group