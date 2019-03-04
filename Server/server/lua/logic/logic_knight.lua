local Hero_Exp_conf = Hero_Exp_conf
local Character_conf = Character_conf
local Hero_Expend_conf = Hero_Expend_conf
local Gong_conf = Gong_conf
local GongGroup_conf = GongGroup_conf
local MixGong_conf = MixGong_conf

local core_user = require "core_user_funcs"
local core_power = require "core_calc_power"
local core_task = require "core_task"
local core_drop = require "core_drop"
local rank = rank

local LogicKnight = {}

function LogicKnight.level_up(tag, src_list, item_list, main_data, username, knight_list)
    local total_exp = 0
    -- 侠客等级最多比玩家高5级
    local lead_level = main_data.lead.level
    local max_level = lead_level + 5
    -- 获取目标卡当前信息
    local c_conf = Character_conf[tag.id]
    local star = c_conf.STAR_LEVEL
    local data = core_user.init_knight_and_get_data(tag)
    local level = data.level
    local old_level = level
    local exp = data.exp
    local exp_idx = 100000000 + star * 10000 + level
    assert(Hero_Exp_conf[exp_idx])
    local next_level_need = Hero_Exp_conf[exp_idx].NEXT_LEVEL
    assert(next_level_need > 0, "knight level is max") -- 到顶级，不能再升级了
    if level == max_level then assert(exp < next_level_need, "knight level is max, exp err") end
    
    assert(#src_list == 1)
    local items = src_list[1]
    local base_exp = 60
    if items.id == 192010009 then base_exp = 600
    elseif items.id == 193010010 then base_exp = 6000
    elseif items.id ~= 191010008 then error("knight levelup, src id err") end
    
    local max_num = items.num
    assert(max_num >= 0, "knight levelup, src num < 0")
    local real_num = 0
    local max = false
    for k = 1,max_num do
        exp = exp + base_exp
        real_num = real_num + 1
        while next_level_need > 0 do
            if exp > next_level_need then
                if level == max_level then
                    -- 已经达到升级上限
                    exp = next_level_need - 1
                    max = true
                    break
                else
                    level = level + 1
                    exp = exp - next_level_need
                    exp_idx = exp_idx + 1
                    next_level_need = Hero_Exp_conf[exp_idx].NEXT_LEVEL
                    if next_level_need == 0 then
                        -- 已经到最高等级
                        exp = 0
                        max = true
                    end
                end
             else
                break
             end
        end
        if max then break end
    end
    
    local ret_struct = {}
    core_user.expend_item(items.id, real_num, main_data, 40, item_list, ret_struct)

    data.level = level
    data.exp = exp
    
    -- 刷新战斗力
    if old_level < level then
        core_power.reflesh_knight_power(main_data,knight_list, tag.id, core_power.create_modify_power(rank.modify_power, username))
        --LOG_EXT(string.format("KNIGHT L:%s|%d  %d--->%d)",
            --main_data.user_name, tag.id, old_level, level))
    end
    
    return tag, ret_struct
end

function LogicKnight.evolution_up(tag, main_data, knight_list, item_list, username, task_struct)
    local data = core_user.init_knight_and_get_data(tag)
    local cur_evo = data.evolution
    local c_conf = Character_conf[tag.id]
    local star = c_conf.STAR_LEVEL
    local conf_idx = 220000000 + star * 10000 + cur_evo
    local conf_data = Hero_Expend_conf[conf_idx]
    assert(conf_data)
    local numclip = conf_data.NEXT_LEVEL
    local clip_id = tag.id + 180000000
    local money = conf_data.NEXT_MONEY
    local renshen = conf_data.GINSENG
    local num = numclip + money + renshen
    assert(num > 0)--如果所有消耗都为0，就说明不能进阶了
    local ret = {item_list = {}, gold = 0}
    if money > 0 then
        core_user.expend_gold(money, {main_data = main_data}, ret.item_list, 41)
    end
    if numclip > 0 then
        core_user.expend_suipian(clip_id, numclip, {main_data = main_data, item_list = item_list}, ret.item_list, 41)
    end
    if renshen > 0 then
        core_user.expend_renshen(renshen, {main_data = main_data, item_list = item_list}, ret.item_list, 41)
    end
    data.evolution = cur_evo + 1
    ret.gold = main_data.gold
    
    -- 刷新战斗力
    core_power.reflesh_knight_power(main_data, knight_list, tag.id, core_power.create_modify_power(rank.modify_power, username))
    -- 刷新成就
    core_task.check_chengjiu_knight_evo_num(task_struct, main_data, knight_list)
    -- 开服任务
    core_task.check_newtask_by_event(main_data, 9, knight_list)
    --LOG_EXT(string.format("KNIGHT E:%s|%d  %d--->%d)",
            --username, tag.id, cur_evo, cur_evo + 1))
    return ret
end

local function get_gong_cost_conf(itemid)
    --local len = MixGong_conf.len
    for k,v in pairs(MixGong_conf.index) do
        if v == itemid then
            return MixGong_conf[v]
        end
    end
    return nil
end

local function check_item_enough(itemid, num, main_data, item_list)
    --print("id:"..itemid.. " need:"..num)
    if itemid == 191010001 then
        if num <= main_data.gold then return true end
    else
        for k,v in ipairs(item_list) do
            if v.id == itemid then
                print("id:"..v.id.. " num:"..v.num.. " need:"..num)
                if v.num >= num then return true end
                break
            end
        end
    end
    return false
end

--递归检查物品合成消耗
local function CheckGongsCost(main_data, item_list, items, costitem, need_money)
    
    for k,v in ipairs(items) do
        --print("id:"..v.id.." num:"..v.num)
        local costnum = 0
        for k1,v1 in ipairs(costitem) do
            if v1.id == v.id then
                costnum = v1.num 
            end
        end
        --加上已消耗的同个物品数
        local totalnum = v.num + costnum
        if not check_item_enough(v.id, totalnum, main_data, item_list) then --验证数量是否足够
            local tmp = get_gong_cost_conf(v.id)
            if not tmp then--不可合成，结束操作
                return false
            else--可合成
                local hasnum = 0
                for k1,v1 in ipairs(item_list) do --包裹里是否有成品，有全部扣掉，然后去合成
                    if v1.id == v.id then
                        hasnum = v1.num - costnum --去掉已消耗的物品数量
                        if hasnum > 0 then
                            print("add1 cost|id:".. v1.id.. " num:"..v1.num)
                            local found = false
                            for k2,v2 in ipairs(costitem) do
                                if v2.id == v.id then
                                    found = true
                                    v2.num = v2.num + hasnum
                                    break
                                end
                            end

                            if not found then
                                table.insert(costitem, {id = v1.id, num = hasnum})
                            end
                        end
                        break
                    end
                end
                --需要合成的数量
                local mixnum = v.num - hasnum
                need_money = need_money + tmp.Mix_Money*mixnum

                if not check_item_enough(191010001, need_money, main_data, item_list) then--合成钱不够
                    need_money = need_money - tmp.Mix_Money*mixnum
                    return false
                end
                local t = 1
                local l = {}
                while tmp.MixGong_List[t] do
                    print("CheckGongsCost|id:"..tmp.MixGong_List[t].. " num:"..mixnum*tmp.MixGong_List[t + 1])
                    table.insert(l, {id = tmp.MixGong_List[t], num = mixnum*tmp.MixGong_List[t + 1]})
                    t = t + 2
                end

                if not CheckGongsCost(main_data, item_list, l, costitem, need_money) then
                    return false
                end
            end
        else--加入预扣除物品
            print("add2 cost|id:".. v.id.. " num:"..v.num)
            
            local found = false
            for k1,v1 in ipairs(costitem) do
                if v1.id == v.id then
                    found = true
                    v1.num = v1.num + v.num 
                    break
                end
            end

            if not found then
                table.insert(costitem, {id = v.id, num = v.num})
            end
        end
    end

    return true
end

--一键校验，合成，扣除物品，就是这么叼
local function do_one_key_equip_gong(main_data, item_list, need_item, rsync)
    --检查物品
    if check_item_enough(need_item, 1, main_data, item_list) then
        print("has item")
        local found = false
        for k,v in ipairs(rsync.item_list) do
            if v.item_id == need_item then
                found = true
                v.item_num = v.item_num - 1
            end
        end

        if not found then
            table.insert(rsync.item_list, {item_id = need_item, item_num = -1})
        end

        local t = {}
        core_user.expend_item(need_item, 1, main_data, 42, item_list, t)

    else--查合成表
        print("mix item")
        local conf = get_gong_cost_conf(need_item)
        local costitem = {}
        local items = {}
        local t = 1
        local need_money = conf.Mix_Money

        --检查钱
        if not check_item_enough(191010001, need_money, main_data, item_list) then
            LOG_ERROR("money not enough" )
            return false
        end

        while conf.MixGong_List[t] do
            print("mix: need id:"..conf.MixGong_List[t].." num:"..conf.MixGong_List[t+1])
            table.insert(items, {id = conf.MixGong_List[t], num = conf.MixGong_List[t + 1]})
            t = t + 2
        end
        local done = true
        done = CheckGongsCost(main_data, item_list, items, costitem, need_money)

        --有物品不足
        if not done then
            LOG_ERROR("some item not enough")
            return false
        end

        --printtab(costitem, "costitem:")

        core_user.expend_gold(need_money, {main_data = main_data}, nil, 901)
        for k,v in ipairs(costitem) do
            core_user.expend_item(v.id, v.num, main_data, 901, item_list, rsync.item_list)
        end
    end
    return true
end

function LogicKnight.gong_equip(main_data, tag, idx, onekey, item_list, knight_list)
    local data = core_user.init_knight_and_get_data(tag)
    local lev = data.level
    assert(lev >= Open_conf[5].OPEN_PARA)
    local gong = data.gong
    local gong_type = gong.type
    local gong_level = gong.level
    if idx > 0 then
        assert(gong.gong_list[idx] == 0, "already equip")
        local tag_gong_group_idx = 330000000 + gong_type * 10000 + gong_level
        local gong_group_conf = GongGroup_conf[tag_gong_group_idx]
        assert(gong_group_conf, "GongGroup conf not exist")
        local tag_gong = 0
        if idx == 1 then tag_gong = gong_group_conf.Gong_1
        elseif idx == 2 then tag_gong = gong_group_conf.Gong_2
        elseif idx == 3 then tag_gong = gong_group_conf.Gong_3
        elseif idx == 4 then tag_gong = gong_group_conf.Gong_4
        elseif idx == 5 then tag_gong = gong_group_conf.Gong_5
        elseif idx == 6 then tag_gong = gong_group_conf.Gong_6
        else error("idx error") end
        local gong_conf = Gong_conf[tag_gong]
        assert(gong_conf, "gong conf not exist")
        assert(gong_conf.Gong_Need <= data.level , "level not enough")

        local need_item = gong_conf.Gong_Item
        local rsync = {item_list = {}}

        if onekey == 1 then
            assert(do_one_key_equip_gong(main_data, item_list, need_item, rsync), "do_one_key_equip_gong error!")
        else
            local t = {}
            core_user.expend_item(need_item, 1, main_data, 42, item_list, t)
        end

        gong.gong_list[idx] = tag_gong

        -- 刷新战斗力
        core_power.reflesh_knight_power(main_data, knight_list, tag.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
        
        rsync.cur_gold = main_data.gold
        rsync.cur_money = main_data.money
        rsync.cur_tili = main_data.tili
        local gongidxes = {}
        table.insert(gongidxes, idx)

        return need_item, rsync, gongidxes
    elseif idx == -1 then --一键装备
        local rsync = {item_list = {}}
        local gongidxes = {}
        for i = 1, 6 do
            repeat
                if gong.gong_list[i] ~= 0 then break end
                local tag_gong_group_idx = 330000000 + gong_type * 10000 + gong_level
                local gong_group_conf = GongGroup_conf[tag_gong_group_idx]
                assert(gong_group_conf, "GongGroup conf not exist")
                local tag_gong = 0
                if i == 1 then tag_gong = gong_group_conf.Gong_1
                elseif i == 2 then tag_gong = gong_group_conf.Gong_2
                elseif i == 3 then tag_gong = gong_group_conf.Gong_3
                elseif i == 4 then tag_gong = gong_group_conf.Gong_4
                elseif i == 5 then tag_gong = gong_group_conf.Gong_5
                elseif i == 6 then tag_gong = gong_group_conf.Gong_6
                else error("idx error") end
                local gong_conf = Gong_conf[tag_gong]
                assert(gong_conf, "gong conf not exist")
                if gong_conf.Gong_Need > data.level then
                    break
                end
                local need_item = gong_conf.Gong_Item

                --一键校验，合成，扣除物品，就是这么叼
                if not do_one_key_equip_gong(main_data, item_list, need_item, rsync) then break end

                print("idx equip:"..i)
                gong.gong_list[i] = tag_gong
                table.insert(gongidxes, i)
            until true 
        end

        rsync.cur_gold = main_data.gold
        rsync.cur_money = main_data.money
        rsync.cur_tili = main_data.tili

        -- 刷新战斗力
        core_power.reflesh_knight_power(main_data, knight_list, tag.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
        return nil, rsync, gongidxes
    else
        error("idx error") 
    end   
end

function LogicKnight.gong_merge(tag, main_data, knight_list, task_struct)
    local data = core_user.init_knight_and_get_data(tag)
    local gong = data.gong
    local gong_type = gong.type
    local gong_level = gong.level
    local tag_gong_group_idx = 330000000 + gong_type * 10000 + gong_level
    local gong_group_conf = GongGroup_conf[tag_gong_group_idx]
    assert(gong_group_conf, "GongGroup conf not exist")
    assert(gong_group_conf.Next_Group ~= 0, "max gong level")
    for _,v in ipairs(gong.gong_list) do
        assert(v ~= 0, "some gong not equip")
        local gong_conf = Gong_conf[v]
        assert(gong_conf, "gong conf not exist")
        gong.add_atk = gong.add_atk + gong_conf.Add_ATK
        gong.add_def = gong.add_def + gong_conf.Add_DEF
        gong.add_hp = gong.add_hp + gong_conf.Add_HP
        gong.add_speed = gong.add_speed + gong_conf.Add_SPEED
        gong.add_mingzhong = gong.add_mingzhong + gong_conf.Add_HIT
        gong.add_huibi = gong.add_huibi + gong_conf.Add_DODGE
        gong.add_baoji = gong.add_baoji + gong_conf.Add_CRIT
        gong.add_xiaojian = gong.add_xiaojian + gong_conf.Add_ANTICRIT
        gong.add_zhaojia = gong.add_zhaojia + gong_conf.Add_BLOCK
        gong.add_jibao = gong.add_jibao + gong_conf.Add_SkillCrit
    end
    gong.gong_list = {0,0,0,0,0,0}
    gong.level = gong_level + 1
    -- 检测成就
    core_task.check_chengjiu_knight_gonglv_num(task_struct, main_data, knight_list)
    -- 检测开服任务
    core_task.check_newtask_by_event(main_data, 4, knight_list)
    --LOG_EXT(string.format("GONG L:%s|%d  %d--->%d)",
            --main_data.user_name, tag.id, gong_level, gong_level + 1))
end

function LogicKnight.gong_mix(tar_item, user_info, item_list)
    local mix_conf = MixGong_conf[tar_item]
    assert(mix_conf, "mix conf not find")
    local titem_list = {}
    local ret = {
        item_list = titem_list,
        gold = 0
    }
    local k = 1
    while mix_conf.MixGong_List[k] do
        core_user.expend_item(mix_conf.MixGong_List[k], mix_conf.MixGong_List[k + 1], user_info, 11, item_list, titem_list)
        k = k + 2
    end
    core_user.expend_item(191010001, mix_conf.Mix_Money, user_info, 11, nil, titem_list)
    core_user.get_item(tar_item, 1, user_info, 11, nil, item_list, ret, nil)
    ret.gold = user_info.gold
    return ret
end

function LogicKnight.enlist(knight_id, main_data, knight_list, item_list, task_struct, notify_struct)
    local knight_conf = Character_conf[knight_id]
    assert(knight_conf, "knight conf not find")
    local star = knight_conf.STAR_LEVEL
    local num = knight_conf.PIECE
    local gold_num = knight_conf.RECRUIT_PRICE
    local item_id = knight_id + 180000000
    local titem_list = {}
    local tknight_list = {}
    local ret = {
        item_list = titem_list,
        knight = nil,
        cur_gold = 0
    }
    local tret = {
        new_knight_list = tknight_list
    }
    if gold_num > 0 then
        core_user.expend_item(191010001, gold_num, main_data, 12, nil, titem_list)
    end
    core_user.expend_item(item_id, num, main_data, 12, item_list, titem_list)
    core_user.get_item(knight_id, 1, main_data, 12, knight_list, nil, tret, nil)
    assert(#tknight_list == 1, "unknow err")
    ret.knight = tknight_list[1]
    -- 检测成就
    core_task.check_chengjiu_knight_star_num(task_struct, main_data, knight_list)
    core_task.check_chengjiu_knight_special(task_struct, main_data, knight_list)
    
    if star == 5 then
        notify_struct.ret = true
        notify_struct.data = notify_sys.add_message(main_data.user_name, main_data.nickname, 2, knight_id)
    elseif star == 6 then
        notify_struct.ret = true
        notify_struct.data = notify_sys.add_message(main_data.user_name, main_data.nickname, 5, knight_id)
    end

    local sevenweapon = core_user.check_sevenweapon_init(main_data, knight_list)

    ret.cur_gold = main_data.gold
    return ret,sevenweapon
end

function LogicKnight.EquipMiJi(miji_id, miji_guid, from_guid, to_guid, main_data, knight_list, item_list)
    assert(from_guid >= -1 and to_guid >= -1 and from_guid ~= to_guid)
    local from_knight = nil
    local to_knight = nil
    local miji_data = nil
    local item_idx = -1
    local another_miji = nil    -- 目标侠客身上已经有这个秘籍，要卸载下来
    local t = nil
    miji_data, t = core_user.find_miji_by_guid(miji_id, miji_guid, from_guid, main_data, knight_list, item_list)
    assert(miji_data, "miji not find")
    if from_guid == -1 then--从背包装到侠客身上
        item_idx = t
    else
        from_knight = t
    end
    if to_guid ~= -1 then
        -- 是要装备
        local t = core_user.get_knight_by_guid(to_guid, main_data, knight_list)
        assert("to_guid not find")
        to_knight = t[2]
        assert(to_knight)
    end
    --数据准备完毕
    local r_item_list = {}
    local rsync = {
        from = from_knight,
        to = to_knight,
        item_list = r_item_list
    }
    if to_guid ~= -1 then
        -- 是要装备
        -- 先看看等级限制
        t = to_knight.data.level
        local mi_conf = Mi_conf[miji_data.id + miji_data.level]
        assert(t >= mi_conf.Mi_Need)
        -- 看看他有没有装过这本秘籍
        if not rawget(to_knight.data, "miji_list") then
            rawset(to_knight.data, "miji_list", {})
        else
            for k,v in ipairs(to_knight.data.miji_list) do
                if v.id == miji_id then
                    another_miji = v
                    table.remove(to_knight.data.miji_list, k)
                    break
                end
            end
        end
        if not another_miji then
            --没装过这个秘籍，那么要验证一下这本秘籍是不是可以装
            local mitype = Character_conf[to_knight.id].Mi_Type
            assert(mitype > 0)
            local conf = MiGroup_conf[mitype]
            assert(conf)
            assert(conf.Mi_1 == miji_id or conf.Mi_2 == miji_id or conf.Mi_3 == miji_id
                or conf.Mi_4 == miji_id or conf.Mi_5 == miji_id)
        end
        if from_knight then
            -- 是从别人那里装
            -- 先把原来的卸掉
            for k,v in ipairs(from_knight.data.miji_list) do
                if v.id == miji_id then
                    table.remove(from_knight.data.miji_list, k)
                    break
                end
            end
            -- 放到新的人身上
            table.insert(to_knight.data.miji_list, miji_data)
            -- 如果目标侠客有一本相同秘籍，就放入背包
            if another_miji then
                table.insert(item_list, {id = another_miji.id, num = 1, guid = another_miji.guid, mj_data = another_miji})
                table.insert(r_item_list, {item_id = another_miji.id, item_num = 1, guid = another_miji.guid,mj_data = another_miji})
            end
        else
            -- 如果目标侠客有一本相同秘籍，就放入背包
            if another_miji then
                table.insert(item_list, {id = another_miji.id, num = 1, guid = another_miji.guid, mj_data = another_miji})
                table.insert(r_item_list, {item_id = another_miji.id, item_num = 1, guid = another_miji.guid,mj_data = another_miji})
            end
            -- 从背包装备
            table.insert(to_knight.data.miji_list, miji_data)
            table.remove(item_list, item_idx)
            table.insert(r_item_list, {item_id = miji_data.id, item_num = -1, guid = miji_data.guid, mj_data = miji_data})
        end
    else
        --是要卸载
        -- 先把原来的卸掉
        for k,v in ipairs(from_knight.data.miji_list) do
            if v.id == miji_id then
                table.remove(from_knight.data.miji_list, k)
                break
            end
        end
        table.insert(item_list, {id = miji_data.id, num = 1, mj_data = miji_data, guid = miji_data.guid})
        table.insert(r_item_list, {item_id = miji_data.id, item_num = 1, mj_data = miji_data, guid = miji_data.guid})
    end
    -- 刷新战斗力
    if from_knight then
        core_power.reflesh_knight_power(main_data, knight_list, from_knight.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
    end
    if to_knight then
        core_power.reflesh_knight_power(main_data, knight_list, to_knight.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
    end
    return rsync
end

function LogicKnight.MiJiLevelup(miji_id, miji_guid, from_guid, src_list, main_data, knight_list, item_list)
    local miji_data, t = core_user.find_miji_by_guid(miji_id, miji_guid, from_guid, main_data, knight_list, item_list)
    assert(miji_id)
    local r_item_list = {}
    local total_exp = 0
    for k,v in ipairs(src_list) do
        local m, idx = core_user.find_miji_by_guid(v.id, v.mj_data.guid, -1, main_data, nil, item_list)
        assert(m)
        table.remove(item_list, idx)
        table.insert(r_item_list, {item_id = v.id, item_num = -1, mj_data = m, guid = m.guid})
        local mi_idx = m.id + m.level
        total_exp = total_exp + Mi_conf[mi_idx].Mi_Exp + m.exp
    end
    local new_exp = miji_data.exp + total_exp
    local new_level = miji_data.level
    local mi_idx = miji_data.id + new_level
    local mi_conf = Mi_conf[mi_idx]
    local need_exp = mi_conf.Need_Exp
    --print(need_exp, mi_idx)
    assert(need_exp > 0)
    while need_exp > 0 do
        if new_exp >= need_exp then
            new_exp = new_exp - need_exp
            new_level = new_level + 1
            mi_idx = mi_idx + 1
            mi_conf = Mi_conf[mi_idx]
            need_exp = mi_conf.Need_Exp
        else
            break
        end
    end
    if from_guid >= 0 then
        assert(t.data.level >= mi_conf.Mi_Need)
    end
    if need_exp == 0 then new_exp = 0 end
    miji_data.level = new_level
    miji_data.exp = new_exp
    local rsync = {
        mj_data = miji_data,
        item_list = r_item_list
    }
    if from_guid ~= -1 then
        core_power.reflesh_knight_power(main_data, knight_list, t.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
    end
    
    for k,v in ipairs(src_list) do
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "CAST_ITEM", main_data.user_name, 80, v.id, 1, 0 ) )
    end
    
    return rsync
end

function LogicKnight.miji_mix(tar_item, main_data, item_list)
    local mix_conf = MixMi_conf[tar_item]
    assert(mix_conf, "mix conf not find")
    local titem_list = {}
    local ret = {
        item_list = titem_list,
        gold = 0
    }
    local k = 1
    while mix_conf.MixMi_List[k] do
        core_user.expend_item(mix_conf.MixMi_List[k], mix_conf.MixMi_List[k + 1], main_data, 13, item_list, titem_list)
        k = k + 2
    end
    if mix_conf.Mix_Money then
        core_user.expend_item(191010001, mix_conf.Mix_Money, main_data, 13, nil, titem_list)
    end
    core_user.get_item(tar_item, 1, main_data, 13, nil, item_list, ret)
    ret.gold = main_data.gold
    return ret
end

function LogicKnight.MiJiJinjie(miji_id, miji_guid, from_guid, src_list, main_data, knight_list, item_list)
    local miji_data, t = core_user.find_miji_by_guid(miji_id, miji_guid, from_guid, main_data, knight_list, item_list)
    assert(miji_id)
    local jinjie_conf = Mi_Jie_conf[miji_data.id + miji_data.jinjie]
    assert(jinjie_conf, "config not find")
    local costid = jinjie_conf.Expend_ID[1]
    local costnum = jinjie_conf.Expend_ID[2]
    assert(costid > 0)
    local r_item_list = {}
    local usenum = 0
    for k,v in ipairs(src_list) do
        assert(v.id == costid)
        usenum = usenum + 1
        assert(usenum <= costnum, costnum, string.format("%d, %d, %d, %d", miji_id,miji_guid, usenum, costnum))
        local m, idx = core_user.find_miji_by_guid(v.id, v.mj_data.guid, -1, main_data, nil, item_list)
        assert(m, string.format("find miji %d, %d", v.id, v.mj_data.guid))
        table.remove(item_list, idx)
        table.insert(r_item_list, {item_id = v.id, item_num = -1, mj_data = m, guid = m.guid})
    end
    assert(usenum == costnum, string.format("%d, %d, %d, %d", miji_id,miji_guid, usenum, costnum))
    miji_data.jinjie = miji_data.jinjie + 1
    
    if from_guid ~= -1 then
        core_power.reflesh_knight_power(main_data, knight_list, t.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
    end
    
    local rsync = {
        mj_data = miji_data,
        item_list = r_item_list
    }
    
    for k,v in ipairs(src_list) do
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "CAST_ITEM", main_data.user_name, 81, v.id, 1, 0 ) )
    end
    return rsync
end

--初始化兵器谱数据
local function init_knight_bqp_data( guid, main_data, knight_list )
    local bqp_data = nil
    local atklen = 0
    local deflen = 0
    local perlen = 0
    if guid == -1 then 
        local t = main_data.lead.bqp_data
        if t then
            t = main_data.lead.bqp_data.atk_list
            t = main_data.lead.bqp_data.def_list
        end
        if not rawget(main_data.lead, "bqp_data") then main_data.lead.bqp_data = {} end
        bqp_data = main_data.lead.bqp_data
        atklen = 4
        deflen = 4
    elseif guid >=0 then
        local t = core_user.get_knight_by_guid(guid, main_data, knight_list)
        assert(t and t[2])
        local tmp = t[2].data.bqp_data
        if tmp then
            tmp = t[2].data.bqp_data.atk_list
            tmp = t[2].data.bqp_data.def_list
        end
        if not rawget(t[2].data, "bqp_data") then t[2].data.bqp_data = {} end
        bqp_data = t[2].data.bqp_data
        local star = Character_conf[t[2].id].STAR_LEVEL
        atklen = 3
        deflen = 3
        if star == 6 then 
            perlen = 1
        end
    end

    if bqp_data then
        if not rawget(bqp_data, "atk_list") then rawset(bqp_data, "atk_list", {}) end
        local len = #bqp_data.atk_list
        for i = len + 1,  atklen do
            print(guid.." init atk:"..len .." "..i)
            table.insert(bqp_data.atk_list, {id = 0})
        end

        if not rawget(bqp_data, "def_list") then rawset(bqp_data, "def_list", {}) end
        len = #bqp_data.def_list
        for i = len + 1,  deflen do
            print(guid.." init def:"..len .." "..i)
            table.insert(bqp_data.def_list, {id = 0})
        end

        if perlen > 0 then       
            if not rawget(bqp_data, "personal") then 
                print(guid.." init per")
                rawset(bqp_data, "personal", {id = 0}) 
            end
        end
    end

    return bqp_data
end

local function get_bqp_list_by_type( bqp_data, type)
    assert(bqp_data)
    if type == 1 then
        local t = bqp_data.atk_list
        if not rawget(bqp_data, "atk_list") then rawset(bqp_data, "atk_list", {}) end
        return bqp_data.atk_list
    elseif type == 2 then
        local t = bqp_data.def_list
        if not rawget(bqp_data, "def_list") then rawset(bqp_data, "def_list", {}) end
        return bqp_data.def_list
    elseif type == 3 then
        if not rawget(bqp_data, "personal") then rawset(bqp_data, "personal", {}) end
        return bqp_data.personal
    end
    return nil
end

function check_bqp_equip_legal( id, knight_id, reqtype )
    assert(BQP_conf[id])
    if reqtype == 3 then
        if knight_id < 0 then return false end
        if BQP_conf[id].P_Character_ID ~= knight_id and BQP_conf[id].P_Character_ID > 0 then
            return false
        end

        if math.floor(BQP_conf[id].BQP_TYPE /10) == 1 then
            return false
        end
    elseif reqtype == 1 or reqtype == 2 then

        local type1 = math.floor(BQP_conf[id].BQP_TYPE /10)
        local type2 = BQP_conf[id].BQP_TYPE%10
        --print(type1, type2, reqtype, knight_id)
        if reqtype ~= type2 then return false end
        if type1 == 2 and knight_id ~= -1 then return false end
    else
        return false
    end
    return true
end

function LogicKnight.EquipBQP(req, main_data, knight_list, item_list)
    local from_guid = req.from
    local to_guid = req.to
    local from_idx = req.from_idx
    local to_idx = req.to_idx
    local type = req.type
    local bqp_guid = req.guid
    local bqp_id = req.bqp_id
    assert(type <= 3 and type >= 1)
    assert(from_guid >= -2 and to_guid >= -2)
    local from_knight = nil
    local to_knight = nil
    local bqp_data = nil
    local item_idx = -1
    local another_bqp = nil    -- 目标侠客身上已经有这个兵器谱，要卸载下来
    local t = nil
    local type2 = nil
    if to_guid > -2 then
        --装备时初始化
        init_knight_bqp_data(to_guid, main_data, knight_list)
        --printtab(main_data.lead.bqp_data, "lead1:")
    end
    --printtab(req)
    --print("reqtype:"..type.. " bqp_id:"..bqp_id.." bqp_guid:"..bqp_guid)
    bqp_data, t, type2 = core_user.find_bqp_by_guid(bqp_id, bqp_guid, from_guid, main_data, knight_list, item_list)
    assert(bqp_data, bqp_id.." "..bqp_guid.. " bqp not find")
    local bd = clonetab(bqp_data)
    --装备的移动
    if from_guid == to_guid then
        assert(from_guid ~= -2)
        assert(from_idx ~= to_idx)
        assert(type ~= 3)
        local drsync = {}
        local r_item_list = {}
        local rsync = {item_list = r_item_list}
        local data = t
        if from_guid > -1 then
            data = t.data
            drsync.from = t
            drsync.to = t
        elseif from_guid == -1 then
            drsync.lfrom = t
            drsync.lto = t
        end

        local list1 = get_bqp_list_by_type(data.bqp_data, type)
        --清空原来的槽
        list1[from_idx] = {}
        local another_bqp = nil
        --卸下要装备的槽
        if list1[to_idx].id ~= 0 then
            another_bqp = clonetab(list1[to_idx])
        end
        --装备
        list1[to_idx] = bd
        
        if another_bqp then
            table.insert(item_list, {id = another_bqp.id, num = 1, guid = another_bqp.guid, bqp_data = another_bqp})
            table.insert(r_item_list, {item_id = another_bqp.id, item_num = 1, guid = another_bqp.guid,bqp_data = another_bqp})
        end

        if to_guid > -1 then
            core_power.reflesh_knight_power(main_data, knight_list, t.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
        end

        return drsync, rsync  
    end


    if from_guid == -2 then--从背包装到侠客身上
        item_idx = t
    else
        from_knight = t
    end

    if to_guid ~= -2 then
        if to_guid >= 0 then
            -- 是要装备
            local t1 = core_user.get_knight_by_guid(to_guid, main_data, knight_list)
            assert(t1, "to_guid not find")
            to_knight = t1[2]
            assert(to_knight)
        elseif to_guid == -1 then
            to_knight = main_data.lead
        end
    end
   
    --数据准备完毕
    local r_item_list = {}
    local rsync = {item_list = r_item_list}
    local drsync = {}
    if from_guid >= 0 then
        drsync.from = from_knight
    elseif from_guid == -1 then
        drsync.lfrom = from_knight
    end
    if to_guid == -1 then
        drsync.lto = to_knight
    elseif to_guid > -1 then
        drsync.to = to_knight
    end
    
    if to_guid ~= -2 then
        local data = to_knight
        if to_guid > -1 then data = to_knight.data end
        -- 是要装备
        -- 先看看等级限制
        assert(data.level >= 50, "level not enough")
        --验证一下这本兵器谱是不是可以装
        local knight_id = rawget(to_knight, "id")
        if not knight_id then knight_id = -1 end
        assert(check_bqp_equip_legal(bqp_id, knight_id, type), "type:"..type.. " bqp_id:"..bqp_id.. "to_knight_id:"..knight_id)     
        
        -- 看看他要装的位置是否有兵器谱
        local list1 = get_bqp_list_by_type(data.bqp_data, type)
        
        if type < 3 then
            if list1[to_idx].id ~= 0 then
                local v = list1[to_idx]
                another_bqp = clonetab(v)
                list1[to_idx] = {id = 0}
            end
        elseif type == 3 then
            if list1.id ~= 0 then
                another_bqp = clonetab(list1)
                data.bqp_data.personal = {id = 0}
            end
        end

        -- 如果目标侠客有兵器谱，就放入背包
        if another_bqp then
            table.insert(item_list, {id = another_bqp.id, num = 1, guid = another_bqp.guid, bqp_data = another_bqp})
            table.insert(r_item_list, {item_id = another_bqp.id, item_num = 1, guid = another_bqp.guid,bqp_data = another_bqp})
        end

        if from_knight then
            assert(type == type2, type.." " .. type2)
            -- 是从别人那里装
            -- 先把原来的卸掉
            local data2 = from_knight
            if from_guid > -1 then data2 = from_knight.data end
            local list2 = get_bqp_list_by_type(data2.bqp_data, type2)
            if type2 < 3 then
                if list2[from_idx].id == bqp_id then
                    list2[from_idx] = {id = 0}
                end
            else
                error("type = 3 can't equip from one to another!")
            end

            -- 放到新的人身上
            list1[to_idx] = bd
        else            
            -- 从背包装备
            if type == 3 then
                --print("equip personal!")
                data.bqp_data.personal = bd
            else
                list1[to_idx] = bd
            end
            table.remove(item_list, item_idx)
            table.insert(r_item_list, {item_id = bd.id, item_num = -1, guid = bd.guid, bqp_data = bd})
        end

    else
        --是要卸载
        -- 先把原来的卸掉
        local data2 = from_knight
        if from_guid > -1 then data2 = from_knight.data end
        local list2 = get_bqp_list_by_type(data2.bqp_data, type2)
        if type2 < 3 then
            if list2[from_idx].id == bqp_id then
                list2[from_idx] = {id = 0}
            end
        elseif type2 == 3 then
            if list2.id == bqp_id then
                data2.bqp_data.personal = {id = 0}
            end
        end
        table.insert(item_list, {id = bd.id, num = 1, bqp_data = bd, guid = bd.guid})
        table.insert(r_item_list, {item_id = bd.id, item_num = 1,bqp_data = bd, guid = bd.guid})
    end
    -- 刷新战斗力
    if from_knight and from_guid > -1 then
        core_power.reflesh_knight_power(main_data, knight_list, from_knight.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
    end
    if to_knight and to_guid > -1 then
        core_power.reflesh_knight_power(main_data, knight_list, to_knight.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
    end

    return drsync, rsync
end

function LogicKnight.BQPLevelup(req, main_data, knight_list, item_list)
    local bqp_guid = req.bqp_guid
    local bqp_id = req.bqp_id
    local onekey = req.onekey
    local from_guid = req.from_id
    local costid = 191010033
    local totalnum = 0
    local bqp_data, t = core_user.find_bqp_by_guid(bqp_id, bqp_guid, from_guid, main_data, knight_list, item_list)
    assert(bqp_data)
    for k,v in ipairs(item_list) do
        if v.id == costid then
            totalnum = v.num
            break
        end
    end
    local rsync = {item_list = {}}
    local conf = BQP_conf[bqp_data.id]
    assert(conf)
    local type = conf.BQP_TYPE
    local bqp_idx = bqp_data.level
    
    --专属兵器谱，索引偏移
    if type ~= 11 and type ~= 12 then
        bqp_idx = bqp_idx + 100
    end

    conf = BQP_Project_conf[bqp_idx]
    assert(conf)

    if onekey ~= 1 then 
        assert(conf.Need_Amount > 0, "level full")
        core_user.expend_item(costid, conf.Need_Amount, main_data, 903, item_list, rsync.item_list)
        bqp_data.level = bqp_data.level + 1
    else--一键升到最高
        while totalnum >= conf.Need_Amount do
            if conf.Need_Amount == 0 then break end
            core_user.expend_item(costid, conf.Need_Amount, main_data, 903, item_list, rsync.item_list)
            totalnum = totalnum - conf.Need_Amount
            bqp_data.level = bqp_data.level + 1
            bqp_idx = bqp_idx + 1
            conf = BQP_Project_conf[bqp_idx]
        end
    end

    if from_guid > -1 then
        core_power.reflesh_knight_power(main_data, knight_list, t.id, core_power.create_modify_power(rank.modify_power, main_data.user_name))
    end
    local retitem = nil
    if from_guid == -2 then
        retitem = {id = bqp_data.id, num = 1, guid = bqp_data.guid, bqp_data = bqp_data}
    else
        if from_guid == -1 then
            t = t.bqp_data
        else 
            t = t.data.bqp_data
        end
    end 
    return rsync, t, retitem
end

function LogicKnight.bqp_mix(num, main_data, item_list)
    local itemid = 191010032
    local poolid = 100277
    local rsync = {item_list = {}}

    --验证包裹里兵器谱数量
    local bqp_num = 0
    for k,v in ipairs(item_list) do
        if v.id >= 194810000 and v.id <= 194899999 then
            bqp_num = bqp_num + 1
            assert(bqp_num + num <= 200)
        end
    end

    --先扣材料
    core_user.expend_item(itemid, 80*num, main_data, 901, item_list, rsync.item_list)
    for i = 1, num do
        local list = {}
        core_drop.get_item_list_from_id(poolid, list, false)
        
        for k,v in ipairs(list) do
            --print("open|", v[1], v[2])
            core_user.get_item(v[1], v[2], main_data, 901, nil, item_list, rsync)
        end
    end

    --printtab(rsync)

    return rsync
end

function LogicKnight.BQPFenjie(fenjie_list, main_data, knight_list, item_list)
    --先检查物品
    --printtab(fenjie_list)
    for k,v in ipairs(fenjie_list) do
        local t = v.bqp_data
        assert(rawget(v, "bqp_data"))
        local bqp_data, t = core_user.find_bqp_by_guid(v.bqp_data.id, v.bqp_data.guid, -2, main_data, knight_list, item_list)
        assert(bqp_data, v.bqp_data.id.." "..v.bqp_data.guid.." not in baglist!")
        v.item_id = v.bqp_data.id
        v.item_num = -1
        v.guid = v.bqp_data.guid
        v.bqp_data.level = bqp_data.level
    end
    local rsync = {item_list = clonetab(fenjie_list)}
    local additemid = 191010033
    local len = #fenjie_list
    for k,v in ipairs(fenjie_list) do
        --printtab(v, "k:"..k)
        local bqp_data, t = core_user.find_bqp_by_guid(v.bqp_data.id, v.bqp_data.guid, -2, main_data, knight_list, item_list)
        assert(bqp_data, v.bqp_data.id.." "..v.bqp_data.guid.." not in baglist!")

        local conf = BQP_conf[bqp_data.id]
        assert(conf)
        local type = conf.BQP_TYPE
        local bqp_idx = bqp_data.level
        
        --专属兵器谱，索引偏移
        if type ~= 11 and type ~= 12 then
            bqp_idx = bqp_idx + 100
        end
        conf = BQP_Project_conf[bqp_idx]
        assert(conf)

        --增加分解材料
        core_user.get_item(additemid, conf.Output_Amount, main_data, 902, knight_list, item_list, rsync)
        
        --删除物品
        table.remove(item_list, t)
        LOG_STAT( string.format( "%s|%s|%d|%d|%d|%d", "CAST_ITEM", main_data.user_name, 902, v.bqp_data.id, v.bqp_data.guid, 0) )
    end

    return rsync
end

return LogicKnight