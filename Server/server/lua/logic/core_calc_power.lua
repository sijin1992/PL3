local core_user = require "core_user_funcs"

local function check_yuan(user_data, knight_list, new_zhenxing)
    local Relationship_conf = Relationship_conf
    local yuan_list = {
        {att = 1, def = 1, hp = 1},
        {att = 1, def = 1, hp = 1},
        {att = 1, def = 1, hp = 1},
        {att = 1, def = 1, hp = 1},
        {att = 1, def = 1, hp = 1},
        {att = 1, def = 1, hp = 1},
        {att = 1, def = 1, hp = 1},
    }
    if not knight_list then
        -- 主角能力变动，缘对其没有影响
        return yuan_list
    end
    local zhenxing = user_data.zhenxing.zhanwei_list

    if new_zhenxing then
        zhenxing = new_zhenxing
    end
    -- 处理缘
    local check_list = {}
    for k,v in ipairs(zhenxing) do
        if v.status == 2 then
            rawset(check_list, v.knight.id, k)
            --羁绊缘
            local t = v.knight.data.level
            local t_jiban = rawget(v.knight.data, "jiban_list")
            if t_jiban then
                for k1,v1 in ipairs(t_jiban) do
                    if v1 >= 0 then
                        local t = core_user.get_knight_from_bag_by_guid(v1, knight_list)
                        assert(t[2])
                        local knight = t[2]
                        local posi = k * 100 + k1
                        rawset(check_list, knight.id, posi)
                        rawset(yuan_list, posi, {att = 1, def = 1, hp = 1})
                    end
                end
            end
        end
    end
    local rela_conf_idx = Relationship_conf.index
    for k,v in ipairs(rela_conf_idx) do
        local conf = Relationship_conf[v]
        if conf.SKILL_ID == 0 then
            local tag_list = {}
            local hero_list = conf.HERO_ID_LIST
            local get_yuan = true
            -- 是否具备所有侠客
            for k1,v1 in ipairs(hero_list) do
                local posi = rawget(check_list, v1)
                if not posi then
                    get_yuan = false
                    break
                end
                rawset(tag_list, k1, posi)
            end
            if get_yuan then
                local att = conf.ATTACK_RAISE
                local def = conf.DEFENSE_RAISE
                local hp = conf.LIFE_RAISE
                for k1,v1 in ipairs(tag_list) do
                    yuan_list[v1].att = yuan_list[v1].att + att / 100
                    yuan_list[v1].def = yuan_list[v1].def + def / 100
                    yuan_list[v1].hp = yuan_list[v1].hp + hp / 100
                end
            end
        end
    end
    return yuan_list
end

local function get_team_raise(user_data)
    local team_raise = {att = 0, def = 0, hp = 0}
    local Lovers_conf = Lovers_conf
    local Book_conf = Book_conf
    --1，侠侣
    for _,v in ipairs(user_data.lover_list) do
        local conf = Lovers_conf[v.id]
        assert(conf, "lover conf not find")
        team_raise.att = team_raise.att + conf.TEAM_ATTACK_RAISE
        team_raise.def = team_raise.def + conf.TEAM_DEFENSE_RAISE
        team_raise.hp = team_raise.hp + conf.TEAM_LIFE_RAISE
    end
    --2，巨著
    for _,v in ipairs(user_data.book_list) do
        local book_id = 80000000 + v.id * 10000 + v.level
        local conf = Book_conf[book_id]
        assert(conf, "book conf not find")
        team_raise.att = team_raise.att + conf.TEAM_ATTACK_RAISE
        team_raise.def = team_raise.def + conf.TEAM_DEFENSE_RAISE
        team_raise.hp = team_raise.hp + conf.TEAM_LIFE_RAISE
    end
    --3，pvp称号
    local reputation = user_data.PVP.reputation
    for k,v in ipairs(PVP_Title_conf.index) do
        local conf = PVP_Title_conf[v]
        local min = conf.POPULARITY[1]
        local max = conf.POPULARITY[2]
        if reputation >= min then
            team_raise.att = team_raise.att + conf.TEAM_ATTACK_RAISE
            team_raise.def = team_raise.def + conf.TEAM_DEFENSE_RAISE
            team_raise.hp = team_raise.hp + conf.TEAM_LIFE_RAISE
            break
        end
    end
    --4，武学极意
    if user_data.wxjy then
        if user_data.wxjy[2] > 0 then
            local conf_a = Extreme_conf[user_data.wxjy[2]].ATTACK
            if conf_a > 0 then
                team_raise.att = team_raise.att + conf_a
            end
        end
        if user_data.wxjy[3] > 0 then
            local conf_d = Extreme_conf[user_data.wxjy[3]].DEFENSE
            if conf_d > 0 then
                team_raise.def = team_raise.def + conf_d
            end
        end
        if user_data.wxjy[1] > 0 then
            local conf_h = Extreme_conf[user_data.wxjy[1]].LIFE
            if conf_h > 0 then
                team_raise.hp = team_raise.hp + conf_h
            end
        end
    end
    --5，门派绝学
    local group = rawget(user_data, "group_data")
    if group then
        local t = group.groupid
        local wxjy = rawget(group, "wxjy")
        if wxjy then
            if wxjy[2] > 0 then
                local conf_a = Men_Extreme_conf[wxjy[2]].ATTACK
                if conf_a > 0 then
                    team_raise.att = team_raise.att + conf_a
                end
            end
            if wxjy[3] > 0 then
                local conf_d = Men_Extreme_conf[wxjy[3]].DEFENSE
                if conf_d > 0 then
                    team_raise.def = team_raise.def + conf_d
                end
            end
            if wxjy[1] > 0 then
                local conf_h = Men_Extreme_conf[wxjy[1]].LIFE
                if conf_h > 0 then
                    team_raise.hp = team_raise.hp + conf_h
                end
            end
        end
    end
    return team_raise
end

local function get_knight_att(data, yuan_data, user_data)
    local conf = Character_conf[data.id]
    assert(conf ~= nil)
    local evolution = 1 + data.evolution / 10
    local qianneng = data.qianneng
    local hp = 0
    local att = 0
    local def = 0
    --白字，基础属性
    --白字，潜能
    if qianneng and qianneng > 0 then
    	if conf.NAME_ID == 0 then
    		hp = conf.LIFE + (conf.LIFE_GROWING + qianneng*10) * data.level
    		att = conf.ATTACK + (conf.ATTACK_GROWING + qianneng*4) * data.level
    		def = conf.DEFENSE + (conf.DEFENSE_GROWING + math.floor(qianneng*0.3)) * data.level
	    else
	    	if conf.AD_KIND == 0 then
	    		hp = conf.LIFE + (conf.LIFE_GROWING + qianneng*3) * data.level
	    		att = conf.ATTACK + (conf.ATTACK_GROWING + qianneng*3) * data.level
	    		def = conf.DEFENSE + (conf.DEFENSE_GROWING + math.floor(qianneng*0.3)) * data.level
	    	else	    	
	    		hp = conf.LIFE + (conf.LIFE_GROWING + qianneng*10) * data.level
	    		att = conf.ATTACK + (conf.ATTACK_GROWING + qianneng) * data.level
	    		def = conf.DEFENSE + (conf.DEFENSE_GROWING + qianneng) * data.level
	    	end
	    end
	    hp = math.floor(hp / 10)
	    att = math.floor(att / 10)
	    def = math.floor(def / 10)
    else
	    hp = math.floor((conf.LIFE + conf.LIFE_GROWING * data.level) / 10)
	    att = math.floor((conf.ATTACK + conf.ATTACK_GROWING * data.level) / 10)
	    def = math.floor((conf.DEFENSE + conf.DEFENSE_GROWING * data.level) / 10)
    end    
    --白字，吞进去的武学
    if data.gong_info then
        local gong = data.gong_info
        att = att + gong.add_atk
        def = def + gong.add_def
        hp = hp + gong.add_hp
    end
    local evo_att = 1
    local evo_def = 1
    local evo_hp = 1
    --白字，进阶后属性
    --if evolution ~= 1 then  -- 进阶加成
    --    att = att * evolution
    --    def = def * evolution
    --    hp = hp * evolution
    --end
    --绿字第一个，缘，是对白字算加成百分比
    att = math.floor(att * (yuan_data.att + data.evolution / 10))
    def = math.floor(def * (yuan_data.def + data.evolution / 10))
    hp = math.floor(hp * (yuan_data.hp + data.evolution / 10))
    --绿字，进阶加成
    local evo = data.evolution
    if evo > 0 then
        local jie_buff_list = HeroJie_conf[data.id].JieBuff_List
        for k = 1, evo do
            if jie_buff_list[k] and jie_buff_list[k] > 0 then
                local buff_id = jie_buff_list[k]
                local buff_conf = JieBuff_conf[buff_id]
                if buff_conf.Add_ATK > 0 then
                    att = att + buff_conf.Add_ATK
                end
                if buff_conf.Add_DEF > 0 then
                    def = def + buff_conf.Add_DEF
                end
                if buff_conf.Add_HP > 0 then
                    hp = hp + buff_conf.Add_HP
                end
            end
        end
    end
    --绿字，本级武学
    if data.gong_info then -- 武学
        local gong = data.gong_info
        for _,v in ipairs(gong.gong_list) do
            if v ~= 0 then
                local gong_conf = Gong_conf[v]
                assert(gong_conf, "gong conf not exist")
                att = att + gong_conf.Add_ATK
                def = def + gong_conf.Add_DEF
                hp = hp + gong_conf.Add_HP
            end
        end
    end
    --绿字，秘籍
    if data.mj_info then -- 武学
        for _,v in ipairs(data.mj_info) do
            local conf = Mi_conf[v.id + v.level]
            assert(conf, "miji conf not exist")
            att = att + conf.Add_ATK
            def = def + conf.Add_DEF
            hp = hp + conf.Add_HP
            
            local conf1 = Mi_Jie_conf[v.id + v.jinjie]
            assert(conf1, "miji jinjie conf not exist")
            att = att + conf1.Add_ATK
            def = def + conf1.Add_DEF
            hp = hp + conf1.Add_HP
        end
    end

    --绿字，兵器谱
    if data.bqp_data then -- 兵器谱
        local t = data.bqp_data.atk_list
        if rawget(data.bqp_data, "atk_list") then
            for _,v in ipairs(data.bqp_data.atk_list) do
                if v.id > 0 then
                    local conf = BQP_conf[v.id]
                    assert(conf, "bqp conf not exist")
                    att = att + conf.Add_ATK*v.level
                    def = def + conf.Add_DEF*v.level
                    hp = hp + conf.Add_HP*v.level
                end
            end
        end
        t = data.bqp_data.def_list
        if rawget(data.bqp_data, "def_list") then
            for _,v in ipairs(data.bqp_data.def_list) do
                if v.id > 0 then
                    local conf = BQP_conf[v.id]
                    assert(conf, "bqp conf not exist")
                    att = att + conf.Add_ATK*v.level
                    def = def + conf.Add_DEF*v.level
                    hp = hp + conf.Add_HP*v.level
                end
            end
        end

        if rawget(data.bqp_data, "personal") then
            if data.bqp_data.personal.id > 0 then
                local conf = BQP_conf[data.bqp_data.personal.id]
                assert(conf, "bqp conf not exist")
                att = att + conf.Add_ATK*data.bqp_data.personal.level
                def = def + conf.Add_DEF*data.bqp_data.personal.level
                hp = hp + conf.Add_HP*data.bqp_data.personal.level
            end
        end
    end
    --绿字，武器加成
    if data.equip_list then -- 计算武器加成
        local level_set = -1
        local star_set = -1
        local no_set = false
        for k,v in ipairs(data.equip_list) do
            local level = v.level
            local star = v.star
            if level > 0 then
                local idx = 130000000 + k * 10000 + level
                local data = Equipment_Upgrade_conf[idx]
                assert(data, string.format("Equipment_Upgrade idx = %d",idx))
                att = att + data.ATTACK_RAISE
                def = def + data.DEFENSE_RAISE
                hp = hp + data.LIFE_RAISE
                if star > 0 then
                    local idx = 140000000 + k * 10000 + star
                    local data = Equipment_Star_conf[idx]
                    assert(data)
                    att = att + data.ATTACK_RAISE
                    def = def + data.DEFENSE_RAISE
                    hp = hp + data.LIFE_RAISE
                end
            else
                no_set = true
                break
            end
            
            local ls = 0
            for k = 181000001, 181000099 do
                local conf = Equipment_Set_conf[k]
                if not conf then break end
                if level >= conf.GRADE then
                    ls = k - 181000000
                else break end
            end
            if level_set == -1 then level_set = ls
            elseif level_set > ls then level_set = ls end
            
            local s_idx = 140000000 + k * 10000 + star
            local conf = Equipment_Star_conf[s_idx]
            local ss = conf.UPGRADE_CLASS
            if star_set == -1 then star_set = ss
            elseif star_set > ss then star_set = ss end
        end
        -- 计算套装
        if (not no_set) and level_set > 0 then
            local idx = 181000000 + level_set
            local data = Equipment_Set_conf[idx]
            assert(data)
            att = att + data.ATTACK_RAISE
            def = def + data.DEFENSE_RAISE
            hp = hp + data.LIFE_RAISE
        end
        if (not no_set) and star_set > 0 then
            local idx = 182000000 + star_set
            local data = Equipment_Set_conf[idx]
            assert(data)
            att = att + data.ATTACK_RAISE
            def = def + data.DEFENSE_RAISE
            hp = hp + data.LIFE_RAISE
        end
    end
    --绿字，侠侣
    for _,v in ipairs(user_data.lover_list) do
        local conf = Lovers_conf[v.id]
        assert(conf, "lover conf not find")
        local hero_id = conf.HERO_ID
        if hero_id == data.id then
            -- 找到侠侣英雄
            att = att + conf.HERO_ATTACK_RAISE
            def = def + conf.HERO_DEFENSE_RAISE
            hp = hp + conf.HERO_LIFE_RAISE
        end
    end
    --绿字，主角的武学极意
    if data.equip_list then
        if user_data.wxjy[12] and user_data.wxjy[12] > 0 then
            local conf_a = Extreme_conf[user_data.wxjy[12]].C_ATTACK
            if conf_a > 0 then
                att = att + conf_a
            end
        end
        if user_data.wxjy[13] and user_data.wxjy[13] > 0 then
            local conf_d = Extreme_conf[user_data.wxjy[13]].C_DEFENSE
            if conf_d > 0 then
                def = def + conf_d
            end
        end
        if user_data.wxjy[11] and user_data.wxjy[11] > 0 then
            local conf_h = Extreme_conf[user_data.wxjy[11]].C_LIFE
            if conf_h > 0 then
                hp = hp + conf_h
            end
        end
        local group_data = rawget(user_data, "group_data")
        if group_data then
            local wxjy = group_data.wxjy
            if wxjy[12] and wxjy[12] > 0 then
                local conf_a = Men_Extreme_conf[wxjy[12]].C_ATTACK
                if conf_a > 0 then
                    att = att + conf_a
                end
            end
            if wxjy[13] and wxjy[13] > 0 then
                local conf_d = Men_Extreme_conf[wxjy[13]].C_DEFENSE
                if conf_d > 0 then
                    def = def + conf_d
                end
            end
            if wxjy[11] and wxjy[11] > 0 then
                local conf_h = Men_Extreme_conf[wxjy[11]].C_LIFE
                if conf_h > 0 then
                    hp = hp + conf_h
                end
            end
        end
    end
    return {att = att, def = def, hp = hp, skill_level = data.skill_level}
end

local function get_knight_power(user_data, knight_list, idx_list, new_zhenxing)
    local yuan_data = check_yuan(user_data, knight_list, new_zhenxing)
    local team_raise = get_team_raise(user_data)
    local power_list = {}
    local zhenxing = user_data.zhenxing.zhanwei_list
    if new_zhenxing then
        zhenxing = new_zhenxing
    end
    for k,v in ipairs(idx_list) do
        --print("get knight power", k)
        local type = zhenxing[v].status
        assert(type == 1 or type == 2)
        local data = {id = 0, level = 0, evolution = 0,equip_list = nil, skill_level = 0, gong_info = nil, mj_info = nil, qianneng = 0, bqp_data = nil}
        if type == 1 then
            local lead = user_data.lead
            data.id = 10000000 + lead.star * 10000
            data.level = lead.level - 1
            data.evolution = lead.evolution
            data.equip_list = lead.equip_list
            data.skill_level = lead.skill.level
            data.qianneng = user_data.lead.qianneng
            data.bqp_data = rawget(user_data.lead, "bqp_data")
        else
            local knight = zhenxing[v].knight
            data.id = knight.id
            data.level = knight.data.level - 1
            data.evolution = knight.data.evolution
            data.skill_level = knight.data.skill.level
            data.gong_info = knight.data.gong
            data.mj_info = rawget(knight.data, "miji_list")
            data.qianneng = knight.data.qianneng
            data.bqp_data = rawget(knight.data, "bqp_data")
        end
        local knight_value = get_knight_att(data, yuan_data[v], user_data)
        local att = knight_value.att + team_raise.att
        local def = knight_value.def + team_raise.def
        local hp = knight_value.hp + team_raise.hp
        --print("att, def, hp,", att, def, hp)
        --计算羁绊
        --printtab(yuan_data)
        if type == 2 then
            local t_jiban = rawget(zhenxing[v].knight.data, "jiban_list")
            if t_jiban then
                for k1,v1 in ipairs(t_jiban) do
                    if v1 >= 0 then
                        local t = core_user.get_knight_from_bag_by_guid(v1, knight_list)
                        assert(t[2])
                        local knight = t[2]
                        local tdata = {id = knight.id, level = knight.data.level - 1, evolution = knight.data.evolution,
                            equip_list = nil, skill_level = knight.data.skill.level, gong_info = knight.data.gong, mj_info = rawget(knight.data, "miji_list"), qianneng = knight.data.qianneng}
                        local t_posi = v * 100 + k1
                        --print("t_posi", t_posi)
                        local knight_value = get_knight_att(tdata, yuan_data[t_posi], user_data)
                        --print("t_posi end")
                        local t_att = knight_value.att + team_raise.att
                        local t_def = knight_value.def + team_raise.def
                        local t_hp = knight_value.hp + team_raise.hp
                        --print("knight id: t_att, t_def, t_hp,", knight.id, t_att, t_def, t_hp)
                        
                        att = att + math.floor(t_att * (20 + tdata.evolution * 5) / 100)
                        def = def + math.floor(t_def * (20 + tdata.evolution * 5) / 100)
                        hp = hp + math.floor(t_hp * (20 + tdata.evolution * 5) / 100)
                    end
                end
            end
        end
        
        local power = math.floor(att) + math.floor(def * 7 / 10) + math.floor(hp * 10 / 103)
        --local power = math.floor(att / 3) + math.floor(def * 0.7) + math.floor(hp / 9)
        
        power = power + 8 * (knight_value.skill_level - 1)
        table.insert(power_list, {idx = v, power = power, att = att, def = def, hp = hp})
        --print(k, power, att, def, hp)
    end
    --LOG_INFO(string.format("power:%d,hp:%d,att:%d,def:%d", power_list.power, power_list.hp, power_list.att, power_list.def))
    return power_list
end

function get_sevenweapon_power(user_data, knight_list)
    local att = 0
    local def = 0
    local hp = 0
    local sevenweapon = core_user.check_sevenweapon_init(user_data, knight_list)
    for i = 1, 7 do
        assert(sevenweapon[i])
        local level = sevenweapon[i].level
        if level and level > 0 then
            local conf = Seven_Weapon_conf[level]
            assert(conf)
            att = att + conf.Add_ATK
            def = def + conf.Add_DEF
            hp = hp + conf.Add_HP
        end
    end
    local power = math.floor(att) + math.floor(def * 7 / 10) + math.floor(hp * 10 / 103)
    return power
end

local core_calc_power = {}

function core_calc_power.get_team_info(user_data, knight_list)
    local idx_list = {}
    local total_power = 0
    for k,v in ipairs(user_data.zhenxing.zhanwei_list) do
        v.power = nil
        if v.status ~= 0 then table.insert(idx_list, k) end
    end
    local info_list = get_knight_power(user_data, knight_list, idx_list)
    return info_list
end

function core_calc_power.reflesh_team_power(user_data, knight_list, modify_power_func)
    -- 刷新战斗力
    local idx_list = {}
    local total_power = 0
    local zhanwei = {}
    for k,v in ipairs(user_data.zhenxing.zhanwei_list) do
        v.power = nil
        if v.status ~= 0 then table.insert(idx_list, k) end
        if v.status == 0 then
            table.insert(zhanwei, -2)
        elseif v.status == 1 then
            table.insert(zhanwei, -1)
        else
            table.insert(zhanwei, v.knight.guid)
        end
    end
    local power_list = get_knight_power(user_data, knight_list, idx_list)
    for k,v in ipairs(power_list) do
        user_data.zhenxing.zhanwei_list[v.idx].power = v.power
        total_power = total_power + v.power
    end
 
    local t = get_sevenweapon_power(user_data, knight_list)
    total_power = t + total_power

    --print("total_power = ", total_power)
    user_data.power = total_power
    modify_power_func(total_power)
    --LOG_EXT(string.format("POWER CHANGE T:%s|%d)",
            --user_data.user_name, total_power))
    
    local t = user_data.ext_data.max_power.max_power
    local max_power = rawget(user_data.ext_data, "max_power")
    if not max_power or total_power > t then
        if not max_power then
            max_power = {max_power = total_power, zhanwei = zhanwei}
            rawset(user_data.ext_data, "max_power", max_power)
        else
            max_power.max_power = total_power
            max_power.zhanwei = zhanwei
        end
    end
end

function core_calc_power.get_team_power(user_data, knight_list, new_zhenxing)
    -- 刷新战斗力
    local idx_list = {}
    local total_power = 0
    local zhanwei = {}
    assert(new_zhenxing)
    for k,v in ipairs(new_zhenxing) do
        v.power = nil
        if v.status ~= 0 then table.insert(idx_list, k) end
        if v.status == 0 then
            table.insert(zhanwei, -2)
        elseif v.status == 1 then
            table.insert(zhanwei, -1)
        else
            table.insert(zhanwei, v.knight.guid)
        end
    end
    local power_list = get_knight_power(user_data, knight_list, idx_list, new_zhenxing)
    for k,v in ipairs(power_list) do
        new_zhenxing[v.idx].power = v.power
        total_power = total_power + v.power
    end

    local t = get_sevenweapon_power(user_data, knight_list)
    total_power = t + total_power

    return total_power
end

function core_calc_power.reflesh_knight_power(user_data, knight_list, knight_id, modify_power_func)
    -- knight_id = 0 主角，否则为侠客id
    local idx = 0
    local total_power = 0
    local new_zhanwei = {}
    for k,v in ipairs(user_data.zhenxing.zhanwei_list) do
        if knight_id == 0 then
            if v.status == 1 then
                idx = k
            else
                total_power = total_power + v.power
            end
        else
            if v.status == 2 and v.knight.id == knight_id then
                idx = k
            else
                local find_jb = false
                local t = v.knight.data.level
                local jb_list = rawget(v.knight.data, "jiban_list")
                if jb_list then
                    for k1,v1 in ipairs(jb_list) do
                        if v1 >= 0 then
                            local t = core_user.get_knight_from_bag_by_guid(v1, knight_list)
                            if t[2] then
                                if t[2].id == knight_id then
                                    find_jb = true
                                    break
                                end
                            end
                        end
                    end
                end
                if find_jb then
                    idx = k
                else
                    total_power = total_power + v.power
                end
            end
        end
    end
    --主角必须在场，所以必须是一个有效idx
    if knight_id == 0 then assert(idx > 0 and idx <= 7) end
    if idx == 0 then return end
    
    assert(idx > 0 and idx <= 7)
    --print("*********idx",idx)
    local power_list = get_knight_power(user_data, knight_list, {idx})
    for k,v in ipairs(power_list) do
        user_data.zhenxing.zhanwei_list[idx].power = v.power
        total_power = total_power + v.power
    end

    local t = get_sevenweapon_power(user_data, knight_list)
    total_power = t + total_power

    user_data.power = total_power
    modify_power_func(total_power)
    --LOG_EXT(string.format("POWER CHANGE K:%s|%d)",
        --user_data.user_name, total_power))

    local t = user_data.ext_data.max_power.max_power
    local max_power = rawget(user_data.ext_data, "max_power")
    if not max_power then
        local zhanwei = {}
        for k,v in ipairs(user_data.zhenxing.zhanwei_list) do
            if v.status == 0 then
                table.insert(zhanwei, -2)
            elseif v.status == 1 then
                table.insert(zhanwei, -1)
            else
                table.insert(zhanwei, v.knight.guid)
            end
        end
        max_power = {max_power = total_power, zhanwei = zhanwei}
        rawset(user_data.ext_data, "max_power", max_power)
    elseif t < total_power then
        max_power.max_power = total_power
    end
end

function core_calc_power.create_modify_power(f,username)
    return function(power)
        f(username, power)
    end
end

return core_calc_power