local ipairs = ipairs
--全部是为了levelup导入的
local core_task = require "core_task"
local rank = rank
local core_drop = require "core_drop"
--local pve2_levelup_cb = pve2_module.change_level

local core_user = {}


--秘籍相关
local function create_miji(item_id, main_data)
    local miji = {
        id = item_id,
        level = 1,
        exp = 0,
    }
    return miji
end

function core_user.find_miji_by_guid(id, guid, from_id, main_data, knight_list, item_list)
    if from_id == -1 then     -- 在背包里
        for k,v in ipairs(item_list) do
            if v.id == id and v.guid == guid then
                return v.mj_data, k
            end
        end
        return nil,nil
    else
        local t = core_user.get_knight_by_guid(from_id, main_data, knight_list)
        if not t then return nil,nil end
        local knight = t[2]
        assert(knight)
        t = knight.data.level
        if not rawget(knight.data, "miji_list") then return nil
        else
            for k,v in ipairs(knight.data.miji_list) do
                if v.guid == guid then
                    return v, knight
                end
            end
            return nil, nil
        end
    end
end

local function create_bqp(item_id, main_data)
    local bqp = {
        id = math.floor(item_id/1000)*1000,
        level = 1,
    }
    return bqp
end

function core_user.find_bqp_by_guid(id, guid, from_id, main_data, knight_list, item_list)
    if from_id == -2 then     -- 在背包里
        for k,v in ipairs(item_list) do
            --Tools._print("guid:"..v.guid .. " id:"..v.id)
            if v.id == id and v.guid == guid then
                return v.bqp_data, k, 0
            end
        end
        return nil,nil,0
    else
        local data = nil
        local ret_data = nil
        if from_id >= 0 then
            local t = core_user.get_knight_by_guid(from_id, main_data, knight_list)
            if not t then return nil, nil, nil end
            local knight = t[2]
            assert(knight)
            local t1 = knight.data.level
            data = knight.data
            t1 = data.bqp_data
            ret_data = knight
        elseif from_id == -1 then
            data = main_data.lead
            local t = data.bqp_data
            ret_data = main_data.lead
        end
        
        assert(data and ret_data)

        if not rawget(data, "bqp_data") then 
            return nil, nil, nil
        else
            local t = data.bqp_data.atk_list
            if rawget(data.bqp_data, "atk_list") then
                for k,v in ipairs(data.bqp_data.atk_list) do
                    if v.guid == guid and v.id == id then
                        return v, ret_data, 1
                    end
                end
            end
            
            local t = data.bqp_data.def_list
            if rawget(data.bqp_data, "def_list") then
                for k,v in ipairs(data.bqp_data.def_list) do
                    if v.guid == guid and v.id == id then
                        return v, ret_data, 2
                    end
                end
            end

            if rawget(data.bqp_data, "personal") then
                if data.bqp_data.personal.guid == guid and data.bqp_data.personal.id == id then
                    return data.bqp_data.personal, ret_data, 3
                end
            end

            return nil, nil, nil
        end
    end
end


function core_user.max_hp(level)
    if level == 1 then
        return 60
    else
        return 60 + level
    end
end

function core_user.check_and_init_knight_bag(knight_list)
    if(rawget(knight_list, "knight_list")) == nil then
        knight_list.knight_list = {}
    end
end

function core_user.check_and_init_item_package(item_list)
    if(rawget(item_list, "item_list")) == nil then
        item_list.item_list = {}
    end
end

function core_user.get_knight_totalnum ( main_data, knight_bag )
    local total_num = 0
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            total_num = total_num + 1
        end
    end
    if not knight_bag then knight_bag = {} end
    for k,v in ipairs(knight_bag) do
        total_num = total_num + 1
    end

    return total_num
end

function core_user.get_knight_by_guid(tag_guid, main_data, knight_bag)
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            if v.knight.guid == tag_guid then
                return {k, v.knight}
            end
        end
    end
    for k,v in ipairs(knight_bag) do
        if v.guid == tag_guid then
            return {k, v}
        end
    end
    return nil
end

function core_user.get_knight_by_id(knight_id, main_data, knight_bag)
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            if v.knight.id == knight_id then
                return {k, v.knight}
            end
        end
    end
    for k,v in ipairs(knight_bag) do
        if v.id == knight_id then
            return {k, v}
        end
    end
    return nil
end

function core_user.get_knight_from_bag_by_guid(tag_guid, knight_bag)
    for k,v in ipairs(knight_bag) do
        if v.guid == tag_guid then
            return {k, v}
        end
    end
    return nil
end

local function add_gold(main_data, value)
    assert(type(value) == "number")
    local gold = main_data.gold
    gold = gold + value
    assert(gold >= 0)
    if gold > 999999999 then gold = 999999999 end
    if value > 0 then
        --local t = main_data.ext_data.total_gold
        --main_data.ext_data.total_gold = t + value
    end
    main_data.gold = gold
end

function core_user.add_money(main_data, num, item_id)
    assert(type(num) == "number")
    local value = 0
    local value1 = 0
    if item_id == 191010099 then
        value = num
    else
        value1 = num
    end
    local total = value1 + value
    local real_money = main_data.ext_data.real_money
    local cw_money = main_data.ext_data.cw_money
    local cw_cost = 0
    if value < 0 then   --花费了真元宝，这时要计算留存元宝和花费元宝
        cw_cost = math.floor(value * (cw_money / real_money))
        cw_money = cw_money + cw_cost
        main_data.ext_data.cw_money = cw_money
    end
    
    real_money = real_money + value
    local money = main_data.money
    money = money + total
    local money_1 = money - real_money
    assert(money >= 0)
    assert(money_1 >= 0)
    assert(real_money >= 0)
    if money > 999999999 then money = 999999999 end
    if real_money > 999999999 then real_money = 999999999 end
    main_data.money = money
    main_data.ext_data.real_money = real_money
end

local function levelup_tili(level)
    if level <= 3 then return 30
    elseif level <= 5 then return 35
    elseif level <= 10 then return 40
    elseif level <= 20 then return 50
    elseif level <= 30 then return 60
    elseif level <= 40 then return 70
    elseif level <= 50 then return 70
    elseif level <= 60 then return 100
    elseif level <= 70 then return 120
    elseif level <= 80 then return 140
    elseif level <= 85 then return 150
    else return 160 end
end

local function user_levelup(main_data, levelup_struct, old_level, new_level)
    assert(new_level > old_level, "new_level <= old level")
    local user_name = main_data.user_name
    if levelup_struct then
        levelup_struct.ret = true
    end
    local add_hp = 0
    local equip_list = {}
    
    local s_equip_list = main_data.lead.equip_list
    for k = old_level + 1, new_level do
        if k % 3 == 0 then -- 这里只须保证开启本级装备就行，之前未开启的装备会在登录时检测并开启
            local idx = math.floor(k / 3) + 1
            if idx <= 8 then
                local equip = s_equip_list[idx]
                if equip.level == 0 then
                    equip.level = 1
                    table.insert(equip_list, idx)
                end
            end
        end
        local a_hp = levelup_tili(k)
        add_hp = add_hp + a_hp
    end
    
    main_data.lead.level = new_level
    core_user.get_item(191040211, add_hp, main_data, 3)
    local new_hp = main_data.tili
    local data = nil
    if levelup_struct then
        data = {
            old_level = old_level,
            new_level = new_level,
            exp = main_data.lead.exp,
            new_hp = new_hp,
            open_equip = equip_list,
            add_tili = add_hp,
            add_new_player = 0,
        }
        levelup_struct.data = data
    end
    rank.modify_level(user_name, main_data.lead.level)
    if new_level >= 20 then
        pve2_levelup_cb(user_name, old_level, new_level)
    end
    core_task.check_newtask_by_event(main_data, 1)
    local t = core_user.set_anp_levelup(main_data, old_level, new_level)
    if data then data.add_new_player = t end
    --检测冲级活动状态
    local r,d = global_huodong.check_level(main_data)
    if d then
        t = main_data.ext_data.huodong.chongji
        t = 0
        for k, v in ipairs(d.entry_list) do
            if v.level <= new_level
                and v.status == 0 then
                t = t + 1
            end
        end
        main_data.ext_data.huodong.chongji = t
    end
    local t_item_list = {}
end

function core_user.add_exp(main_data, value, levelup_struct)
    assert(type(value) == "number")
    local exp = main_data.lead.exp
    local level = main_data.lead.level
    local old_level = level
    exp = exp + value
    local next_level_need = Player_Exp_conf[level].NEXT_LEVEL
    while next_level_need > 0 do
        if exp >= next_level_need then
            level = level + 1
            exp = exp - next_level_need
            next_level_need = Player_Exp_conf[level].NEXT_LEVEL
            if next_level_need == 0 then exp = 0 end
         else
            break
         end
    end
    main_data.lead.exp = exp
    if level > old_level then
        user_levelup(main_data, levelup_struct, old_level, level)
        LOG_STAT( string.format( "%s|%s|%d|%d", "LEVEL_UP", main_data.user_name, old_level, level ) )
    end
end

function core_user.create_knight(knight_id, main_data)
    local knight = {
        guid = main_data.next_knight_guid,
        id = knight_id,
        data = {
            level = 1,
            exp = 0,
            skill = {
                id = Character_conf[knight_id].SKILL_ID,
                level = 1,
            },
            gong = {
                type = Character_conf[knight_id].GongGroup_Type,
                gong_list = {0,0,0,0,0,0},
                level = 1,
                add_neigong = 0,
                add_waigong = 0,
                add_qinggong = 0,
                add_qigong = 0,
                add_atk = 0,
                add_def = 0,
                add_hp = 0,
                add_speed = 0,
                add_mingzhong = 0,
                add_huibi = 0,
                add_baoji = 0,
                add_xiaojian = 0,
                add_zhaojia = 0,
                add_jibao = 0,
            },
            evolution = 0,
            pve2_sub_hp = 0,
        }
    }
    main_data.next_knight_guid = main_data.next_knight_guid + 1
    return knight
end

function core_user.check_sevenweapon_init ( main_data, knight_bag )
    local num = core_user.get_knight_totalnum( main_data, knight_bag )
    local sevenweapon = main_data.sevenweapon
    sevenweapon = rawget(main_data, "sevenweapon")
    if not sevenweapon then 
        main_data.sevenweapon = {}
        for i = 1, 7 do
            table.insert(main_data.sevenweapon, {level = 0, redpoint = 0})
        end
    end
    sevenweapon = main_data.sevenweapon

    for i =1, 7 do
        local conf = SWeapon_Open_conf[i]
        assert(conf and sevenweapon[i])
        if i == 1 then 
            if conf.Need_Hero_Amount <= num and sevenweapon[2].level == 0 then
                sevenweapon[2].level = 1
            end
        elseif i == 2 then 
            if conf.Need_Hero_Amount <= num and sevenweapon[5].level == 0 then
                sevenweapon[5].level = 1
            end
        elseif i == 3 then 
            if conf.Need_Hero_Amount <= num and sevenweapon[6].level == 0 then
                sevenweapon[6].level = 1
            end
        elseif i == 4 then 
            if conf.Need_Hero_Amount <= num and sevenweapon[1].level == 0 then
                sevenweapon[1].level = 1
            end
        elseif i == 5 then 
            if conf.Need_Hero_Amount <= num and sevenweapon[4].level == 0 then
                sevenweapon[4].level = 1
            end
        elseif i == 6 then 
            if conf.Need_Hero_Amount <= num and sevenweapon[3].level == 0 then
                sevenweapon[3].level = 1
            end
        elseif i == 7 then 
            if conf.Need_Hero_Amount <= num and sevenweapon[7].level == 0 then
                sevenweapon[7].level = 1
            end
        end      
    end

    return sevenweapon
end

function core_user.get_new_knight(knight_id, main_data, knight_list, item_list)
    local old_knight = core_user.get_knight_by_id(knight_id, main_data, knight_list)
    local ret = {flag = 0, knight = nil, item = nil}
    local sevenweapon = nil
    if old_knight == nil then
        local knight = core_user.create_knight(knight_id,main_data)
        table.insert(knight_list,knight)
        ret.knight = knight
        sevenweapon = core_user.check_sevenweapon_init ( main_data, knight_list )
    else
        local knight_conf = Character_conf[knight_id]
        local num = knight_conf.REWARD_PIECE
        assert(num > 0)
        local t_item = {}
        ret.flag = 1
        core_user.get_item(knight_id + 180000000, num, main_data, 10, knight_list, item_list, {item_list = t_item}, nil)
        assert(rawlen(t_item) == 1)
        ret.item = t_item[1]
    end
    return ret, sevenweapon
end

function core_user.get_item(item_id, item_num, main_data, where, knight_list, item_list, ret_struct, levelup_struct)
    assert(item_num >= 0, "item_num:"..item_num.." < 0")
    if item_id == 191010001 then
        add_gold(main_data, item_num)
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d", "GET_GD", main_data.user_name, where, item_num, main_data.gold ) )
    elseif item_id == 191010002 then
        core_user.add_exp(main_data, item_num, levelup_struct)
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
    elseif item_id == 191010003 or item_id == 191010099 then
        --加元宝。第二行的两个id是特殊处理的，表示需要考虑充值返利等特殊活动
        --local t = main_data.ext_data.cw_money
        core_user.add_money(main_data, item_num, item_id)
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = 191010003, item_num = item_num})
        end
        --刷新财神到的红点
        local csd_level = main_data.huodong.caishendao
        local t = 0
        if csd_level > 0 then
            for k = csd_level, 100 do
                local conf = Activity_Cai_conf[k]
                if not conf then break end
                if conf.Grade <= main_data.money then t = t + 1
                else break end
            end
            local t1 = main_data.ext_data.huodong.caishen
            main_data.ext_data.huodong.caishen = t
        end
         
        if where ~= 50 then -- 充值的时候涉及财务留存元宝的计算，所以另行记录
            if item_id == 191010003 then--假元宝
                LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d|%d|%d|%d|%s|%s|%s", "GET_YB", main_data.user_name,
                    where, item_num, 0, 0, main_data.ext_data.cw_money, main_data.ext_data.real_money, main_data.money,
                    main_data.account, main_data.ip, main_data.mcc) )
            else
                LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d|%d|%d|%d|%s|%s|%s", "GET_YB", main_data.user_name,
                    where, item_num, item_num, 0, main_data.ext_data.cw_money, main_data.ext_data.real_money, main_data.money,
                    main_data.account, main_data.ip, main_data.mcc) )
            end
        end
    elseif item_id == 191040210 then
        local t = main_data.PVP.reputation
        t = t + item_num
        if t < 0 then t = 0
        elseif t > 99999999 then t = 99999999 end
        main_data.PVP.reputation = t
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
        if rank then
            rank.modify_reputation(main_data.user_name, main_data.PVP.reputation)
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "GET_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id == 191040211 then
        --体力
        local t = main_data.tili
        t = t + item_num
        if t < 0 then t = 0
        elseif t > 99999999 then t = 99999999 end
        main_data.tili = t
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d", "GET_PHP", main_data.user_name, where, item_num, t ) )
    elseif item_id == 191040212 then
        local t = main_data.PVE.pve2.pve2_gold
        t = t + item_num
        if t < 0 then t = 0
        elseif t > 99999999 then t = 99999999 end
        main_data.PVE.pve2.pve2_gold = t
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "GET_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id == 191010056 then
        local t = main_data.PVP.pvp_gold
        t = t + item_num
        if t < 0 then t = 0
        elseif t > 99999999 then t = 99999999 end
        main_data.PVP.pvp_gold = t
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "GET_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id == 191010025 then
        local t = main_data.group_data.paizi
        t = t + item_num
        if t < 0 then t = 0
        elseif t > 99999999 then t = 99999999 end
        main_data.group_data.paizi = t
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "GET_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id == 191010027 then
        local t = main_data.group_data.sw
        t = t + item_num
        if t < 0 then t = 0
        elseif t > 99999999 then t = 99999999 end
        main_data.group_data.sw = t
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "GET_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id == 191010057 then
        -- 武魂
        local t = main_data.xyshop.ghost
        t = t + item_num
        main_data.xyshop.ghost = t
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "GET_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id > 10000000 and item_id < 20000000 then
        --TODO:有个玩家有两个石观音
        if string.sub(main_data.user_name, 1, 7) == "7555779" then
            local num = 0
            local posi = 0
            local idx = 0
            for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
                if v.status == 2 then
                    if v.knight.id == 10050036 then
                        posi = 1
                        idx = k
                        num = num + 1
                    end
                end
            end
            for k,v in ipairs(knight_list) do
                if v.id == 10050036 then
                    posi = 2
                    idx = k
                    num = num + 1
                end
            end
            if num >= 2 then
                if posi == 1 then
                    main_data.zhenxing.zhanwei_list[idx]={status = 0}
                elseif posi == 2 then
                    table.remove(knight_list, idx)
                end
            end
        end
        
        local ret, sevenweapon = core_user.get_new_knight(item_id, main_data, knight_list, item_list)
        if ret.knight then
            LOG_STAT( string.format( "%s|%s|%d|%d|%d", "GET_CARD", main_data.user_name, where, item_id, 1 ) )
        end
        if ret_struct then
            if ret.knight then
                table.insert(ret_struct.new_knight_list, ret.knight)
            end
        end
        return ret, sevenweapon
    elseif item_id >= 194800000 and item_id <= 194809999 then
        for k = 1, item_num do
            local mj = create_miji(item_id, main_data)
            local item = {id = item_id, num = 1, mj_data = mj, guid = main_data.next_item_guid}
            table.insert(item_list, item)
            mj.guid = item.guid
            main_data.next_item_guid = main_data.next_item_guid + 1
            if ret_struct then
                table.insert(ret_struct.item_list, {item_id = item_id, item_num = 1, mj_data = mj, guid = item.guid})
            end
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "GET_ITEM", main_data.user_name, where, item_id, item_num, 1 ) )
    elseif item_id >= 194810000 and item_id <= 194899999 then
        for k = 1, item_num do
            local bqp = create_bqp(item_id, main_data)
            local item = {id = item_id, num = 1, bqp_data = bqp, guid = main_data.next_item_guid}
            table.insert(item_list, item)
            bqp.guid = item.guid
            main_data.next_item_guid = main_data.next_item_guid + 1
            if ret_struct then
                table.insert(ret_struct.item_list, {item_id = item_id, item_num = 1, bqp_data = bqp, guid = item.guid})
            end
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "GET_ITEM", main_data.user_name, where, item_id, item_num, 1 ) )
    elseif item_id == 191020199 or item_id == 192020200 or item_id == 193020201 or item_id == 194020202 then
        -- 得到银票
        local gold_num = Item_conf[item_id].PRICE * item_num
        core_user.get_item(191010001, gold_num, main_data, where)
        
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num, guid = 0})
        end
    elseif item_id == 191010023 then
        --更新累计充值金额&vip
        local total_money = main_data.ext_data.total_money
        local total_first = 1
        if total_money > 0 then total_first = 0 end
        total_money = total_money + item_num
        main_data.ext_data.total_money = total_money
        main_data.vip_score = total_money
        --更新vip
        local cur_vip = main_data.vip_lev
        local dest_vip = cur_vip
        for k = cur_vip + 1, VIP_conf.len - 1 do
            local conf = VIP_conf[k]
            local value = conf.RECHARGE
            if total_money >= value then dest_vip = k
            else break end
        end
        if dest_vip > cur_vip then
            local vip_reward = rawget(main_data.ext_data, "vip_reward")
            if not vip_reward then
                vip_reward = {}
                main_data.ext_data.vip_reward = vip_reward
            end
            local vip_reward_len = rawlen(vip_reward)
            for k = vip_reward_len + 1, dest_vip do
                table.insert(vip_reward, 0)
            end
            main_data.vip_lev = dest_vip
            local cur_qiandao = main_data.huodong.qiandao.day_idx
            local cur_qiandao_sub_id = main_data.huodong.qiandao.sub_id
            local qiandao_status = main_data.huodong.qiandao.status
            if qiandao_status == 1 then
                local qian_id = 480000000 + cur_qiandao_sub_id * 1000 + cur_qiandao
                local qian_conf = Activity_Qian_conf[qian_id]
                assert(qian_conf, "qian conf not find")
                local double_vip = tonumber(qian_conf.VIP_LV)
                if double_vip > 0 and cur_vip < double_vip and dest_vip >= double_vip then
                    main_data.huodong.qiandao.status = 2
                    main_data.ext_data.huodong.qiandao = 1
                end
            end
        end
    elseif item_id == 199990001 then        -- 控制命令1，清除公会
        local group_data = rawget(main_data, "group_data")
        if not group_data then return end
        local groupid = group_data.groupid
        group_data.groupid = ""
        group_data.total_sw = 0
        group_data.anti_time = 0
        group_data.status = 0
        --group_data.allot_num = 0
        group_data.today_join_num = 0
        --公会解散如果清挑战次数，玩家可以刷，所以也不请
        --rawset(group_data, "fortress_list", nil)
        LOG_INFO(string.format("exit_group_by_gm|%s|%s|", main_data.user_name, groupid))
    elseif item_id > 190000000 and item_id < 200000000 then
        local item = nil
        local left_num = 0
        for k,v in ipairs(item_list) do
            if v.id == item_id then
                v.num = v.num + item_num
                left_num = v.num
                item = v
                break
            end
        end
        if not item then
            item = {id = item_id, num = item_num,guid = main_data.next_item_guid}
            table.insert(item_list, item)
            left_num = item_num
            main_data.next_item_guid = main_data.next_item_guid + 1
        end
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num, guid = item.guid})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "GET_ITEM", main_data.user_name, where, item_id, item_num, left_num ) )
    end
end

function core_user.expend_item(item_id, item_num, main_data, where, item_list, ret_struct, need_result)
	assert(item_num >= 0, "item_num:"..item_num.." < 0")
	if item_num == 0 then return end --=0直接返回
    if item_id == 191010001 then
        add_gold(main_data, -item_num)
        if ret_struct then
            table.insert(ret_struct, {item_id = item_id, item_num = -item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d", "CAST_GD", main_data.user_name, where, item_num, main_data.gold ) )
    elseif item_id == 191010003 or item_id == 191010099 then
        --花费元宝
        core_user.add_money(main_data, -item_num, item_id)
        if ret_struct then
            table.insert(ret_struct, {item_id = item_id, item_num = -item_num})
        end
    elseif item_id == 191040211 then
        --体力
        local t = main_data.tili
        t = t - item_num
        if t < 0 then t = 0
        elseif t > 99999999 then t = 99999999 end
        main_data.tili = t
        if ret_struct then
            table.insert(ret_struct, {item_id = item_id, item_num = -item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d|%d", "CAST_PHP", main_data.user_name, where, item_num, main_data.lead.level, main_data.lead.level, t ) )
    elseif item_id == 191040212 then
        local t = main_data.PVE.pve2.pve2_gold
        t = t - item_num
        assert(t >= 0, "pve2 gold not enough")
        main_data.PVE.pve2.pve2_gold = t
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "CAST_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id == 191010056 then
        local t = main_data.PVP.pvp_gold
        t = t - item_num
        assert(t >= 0, "pvp gold not enough")
        main_data.PVP.pvp_gold = t
        if ret_struct then
            table.insert(ret_struct.item_list, {item_id = item_id, item_num = item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "CAST_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id == 191010057 then
        -- 武魂
        local t = main_data.xyshop.ghost
        t = t - item_num
        assert(t >= 0)
        main_data.xyshop.ghost = t
        if ret_struct then
            table.insert(ret_struct, {item_id = item_id, item_num = -item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "CAST_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id == 191010025 then
        local t = main_data.group_data.paizi
        t = t - item_num
        assert(t >= 0)
        main_data.group_data.paizi = t
        if ret_struct then
            table.insert(ret_struct, {item_id = item_id, item_num = -item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "CAST_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id == 191010027 then
        local t = main_data.group_data.sw
        t = t - item_num
        assert(t >= 0)
        main_data.group_data.sw = t
        if ret_struct then
            table.insert(ret_struct, {item_id = item_id, item_num = -item_num})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "CAST_ITEM", main_data.user_name, where, item_id, item_num, t ) )
    elseif item_id > 190000000 and item_id < 200000000 then
        local item = false
        local t = 0
        for k,v in ipairs(item_list) do
            if v.id == item_id then
                if not need_result then
                    -- 这里如果不满足条件，就直接退出整个lua逻辑了。有的时候需要更精细的控制
                    assert(v.num >= item_num)
                elseif v.num < item_num then
                    return -1
                end
                v.num = v.num - item_num
                t = v.num
                item = v
                if v.num == 0 then table.remove(item_list, k) end
                break
            end
        end
        if not need_result then
            assert(item, string.format("%d not find", item_id))
        elseif not item then
            return -1
        end
        if ret_struct then
            table.insert(ret_struct, {item_id = item_id, item_num = -item_num, guid = item.guid})
        end
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "CAST_ITEM", main_data.user_name, where, item_id, item_num, t) )
    else
        error("expend_item, err item_id")
    end
end

function core_user.init_knight_and_get_data(knight)
    local data = nil
    if knight.data and knight.data.level ~= 0 then
        data = knight.data
    else
        data = {
            level = 1,
            exp = 0,
            skill = {
                id = Character_conf[knight.id].SKILL_ID,
                level = 1,
            },
            gong = {
                type = Character_conf[knight.id].GongGroup_Type,
                gong_list = {0,0,0,0,0,0},
                level = 1,
                add_neigong = 0,
                add_waigong = 0,
                add_qinggong = 0,
                add_qigong = 0,
                add_atk = 0,
                add_def = 0,
                add_hp = 0,
                add_speed = 0,
                add_mingzhong = 0,
                add_huibi = 0,
                add_baoji = 0,
                add_xiaojian = 0,
                add_zhaojia = 0,
            },
            evolution = 0,
        }
        knight.data = data
    end
    return data
end

function core_user.init_knight(knight)
    core_user.init_knight_and_get_data(knight)
end

function core_user.unread_mail_num(mail_list)
    local n = 0
    for _,v in ipairs(mail_list) do
        if v.type ~= 1 then n = n + 1 end
    end
    return n
end



function core_user.add_knight_exp(knight, value, main_data, knight_list)
    -- 侠客等级最多比玩家高5级
    local max_level = main_data.lead.level + 5
    
    -- 获取目标卡当前信息
    local c_conf = Character_conf[knight.id]
    local star = c_conf.STAR_LEVEL
    local data = core_user.init_knight_and_get_data(knight)
    local level = data.level
    local old_level = level
    local exp = data.exp
    local exp_idx = 100000000 + star * 10000 + level
    local conf = Hero_Exp_conf[exp_idx]
    assert(conf)
    local next_level_need = conf.NEXT_LEVEL
    if next_level_need == 0 then    -- 到顶级，不能再升级了
        return -1
    end
    if level == max_level and exp >= (next_level_need - 1) then -- 到最大等级上限ww
        return -1
    end
    
    exp = exp + value
    local levelup = false
    while next_level_need > 0 do
        if exp > next_level_need then
            if level >= max_level then
                -- 已经达到升级上限
                exp = next_level_need - 1
                break
            else
                level = level + 1
                levelup = true
                exp = exp - next_level_need
                exp_idx = exp_idx + 1
                next_level_need = Hero_Exp_conf[exp_idx].NEXT_LEVEL
                if next_level_need == 0 then
                    -- 已经到最高等级
                    exp = 0
                    break
                end
            end
        else
            break
        end
    end
    data.level = level
    data.exp = exp
    if levelup then
        return 1
    else return 0 end
end

function core_user.reflesh_shopping_list(idx)
    local shop_list = {}
    local pool_list = {}
    local conf = Lottery_conf[idx]
    assert(conf)
    core_drop.do_choujiang_from_1(conf, pool_list)
    for k,v in ipairs(pool_list) do
        local id = v[1]
        local num = v[2]
        local conf_item = nil
        if idx == 100014 then
            conf_item = PVP_Shop_conf[id]
        elseif idx == 100025 then
            conf_item = PVE2_Shop_conf[id]
        elseif idx == 100164 then
            conf_item = Men_Shop_conf[id]
        end
        assert(conf_item)
        local price = conf_item.PRICE
        local entry = {
            id = id,
            num = num,
            price = price
        }
        table.insert(shop_list, entry)
    end
    return shop_list
end

function core_user.add_gold(num, data, ret, where)
    core_user.get_item(191010001, num, data.main_data, where, nil, nil, ret)
end
function core_user.add_xuantie(num, data, ret, where)
    core_user.get_item(193010004, num, data.main_data, where, nil, data.item_list, ret)
end
function core_user.add_renshen(num, data, ret, where)--就是进阶丹
    core_user.get_item(193010005, num, data.main_data, where, nil, data.item_list, ret)
end

function core_user.expend_hp(cost, main_data, where)
    core_user.expend_item(191040211, cost, main_data, 5)
end

function core_user.expend_renshen(cost, data, ret, where)
    core_user.expend_item(193010005, cost, data.main_data,where, data.item_list, ret)
end
function core_user.expend_gold(cost, data, ret, where)
    core_user.expend_item(191010001,cost,data.main_data,where,nil,ret)
end
function core_user.expend_suipian(id, cost, data, ret, where)
    core_user.expend_item(id,cost,data.main_data,where,data.item_list,ret)
end

function core_user.expend_sxl(cost, data, ret, where)
    return core_user.expend_item(191010212, cost, data.main_data, where, data.item_list, ret, true)
end
--[[
user_struct{
    main_data -- 玩家基础数据
    item_list -- 玩家背包数据，如果获取物品，就需要这个结构
    knihgt_list -- 玩家侠客列表。如果有获取侠客就需要这个结构，否则不需要
}
ret_list
{
    rsync{
        item_list={}--必须有。所有获得的物品，道具，都会在这里记录。这个结构可以直接发给客户端用于结算显示
        new_knight_list={} -- 如果获得侠客，就必须有这个结构
    }
    levelup_struct{--如果有获得经验，就可能升级，就必须有这个结构。只需要创建空表{ret= false， data= nil}即可
        ret = false/true
        data = nil/{
                        old_level
                        new_level
                        exp
                        new_hp
                        open_equip
                        add_tili
                        reflesh_task_list
                        reflesh_daily_list
                    }
    }
}
]]

function core_user.get_item_list(user_struct, reward_list, ret_list, where)
    local rsync = ret_list.rsync
    local levelup_struct = ret_list.levelup_struct
    local main_data = user_struct.main_data
    local item_list = user_struct.item_list
    local knight_list = user_struct.knight_list
    for _,v in ipairs(reward_list) do
        core_user.get_item(v[1], v[2], main_data, where, knight_list, item_list,
            rsync, levelup_struct)
    end
end

function core_user.get_reward_list(main_data, bag_list, reward_list, rsync, where)
    local user_struct = {main_data = main_data, item_list = bag_list}
    local ret_list = {rsync = rsync, levelup_struct = levelup_struct}
	core_user.get_item_list(user_struct, reward_list, ret_list, where)
end

local function set_add_new_player(main_data, idx)
    local t = main_data.ext_data.add_new_player[0]
    local anp = rawget(main_data.ext_data, "add_new_player")
    if not anp then
        anp = {}
        rawset(main_data.ext_data, "add_new_player", anp)
    end
    t = rawlen(anp)
    if t < idx then
        for k = t + 1, idx do
            table.insert(anp, 0)
        end
    end
    if anp[idx] == 0 then
        anp[idx] = 1
        local t = main_data.ext_data.new_player
        t = t + 1
        main_data.ext_data.new_player = t
        LOG_STAT( string.format( "GUIDE|%s|%d", main_data.user_name, t ) )
        return idx
    else
        return 0
    end
end

function core_user.set_anp_on_equiplevel(main_data)
    return set_add_new_player(main_data, 1)
end

function core_user.set_anp_on_equipstar(main_data)
    return set_add_new_player(main_data, 2)
end

function core_user.set_anp_knight_level(main_data)
    return set_add_new_player(main_data, 3)
end

function core_user.set_anp_lead_star(main_data)
    return set_add_new_player(main_data, 4)
end

function core_user.set_anp_wx_equip(main_data, wx_id)
    for k,v in ipairs(Guide_conf.index) do
        local conf = Guide_conf[v]
        if conf.Type == 5 and wx_id == conf.Para then
            return set_add_new_player(main_data, v)
        elseif conf.Type > 5 then break
        end
    end
    return 0
end

function core_user.set_anp_enlist(main_data)
    return set_add_new_player(main_data, 7)
end

function core_user.set_anp_pve_reward(main_data, fortress_id)
    for k,v in ipairs(Guide_conf.index) do
       local conf = Guide_conf[v]
        if conf.Type == 7 and fortress_id == conf.Para then
            return set_add_new_player(main_data, v)
        elseif conf.Type > 7 then break
        end 
    end
end
function core_user.set_anp_skill_level(main_data)
    return set_add_new_player(main_data, 10)
end
function core_user.set_anp_buzhen(main_data)
    return set_add_new_player(main_data, 11)
end
function core_user.set_anp_open_book(main_data)
    return set_add_new_player(main_data, 12)
end
function core_user.set_anp_choujiang_g(main_data)
    return set_add_new_player(main_data, 13)
end
function core_user.set_anp_pve(main_data, stage_id)
    for k,v in ipairs(Guide_conf.index) do
       local conf = Guide_conf[v]
        if (conf.Type == 12 or conf.Type == 17) and stage_id == conf.Para then
            return set_add_new_player(main_data, v)
        end 
    end
end
function core_user.set_anp_touchclose(main_data, idx)
    return set_add_new_player(main_data, idx)
end
function core_user.set_anp_levelup(main_data, old_level, new_level)
    local ret = 0
    for k,v in ipairs(Guide_conf.index) do
       local conf = Guide_conf[v]
        if conf.Type == 15 and old_level < conf.Para and new_level >= conf.Para then
            local r = set_add_new_player(main_data, v)
            if r ~= 0 then ret = r end
        end 
    end
    return ret
end
function core_user.set_anp_booklevelup(main_data)
    return set_add_new_player(main_data, 59)
end

function core_user.get_qiyu(main_data)
    local qiyu_struct = rawget(main_data, "qiyu")
    local qiyu_list = nil
    if not qiyu_struct then
        qiyu_list = {}
        qiyu_struct = {
            qiyu_list = qiyu_list,
            guid = 0,
            today_tjhf = 0
        }
        rawset(main_data, "qiyu", qiyu_struct)
    else
        local t = qiyu_struct.guid
        if not rawget(qiyu_struct, "qiyu_list") then
            qiyu_list = {}
            rawset(qiyu_struct, "qiyu_list", qiyu_list)
        end
    end
    return qiyu_struct
end

function core_user.check_qiyu(qiyu_list)
    local redo = true
    local t = os.time()
    while redo do
        redo = false
        for k,v in ipairs(qiyu_list) do
            if t > (v.stamp + v.duration) then
                redo = true
                table.remove(qiyu_list, k)
                break
            end
        end
    end
    return rawlen(qiyu_list)
end

return core_user