--[[
一、角色数据
    每个角色role都有以下数据:
    id
    posi
    type
    
    hp
    max_hp
    
    att
    def
    speed
    
    mingzhong
    huibi
    baoji
    xiaojian
    zhaojia
    
    relive
    attacket
    anti_love 缘必须隔一个回合再触发
    
    base_data 根据角色等级、武功等计算出来的基础数值,其实就是白字
        level
        star
        evolution
        
        waigong
        neigong
        qigong
        sudu
        
        hp
        att
        def
        speed
        
        mingzhong
        huibi
        baoji
        xiaojian
        zhaojia
    team_raise,巨著和侠侣的团队属性
    lover_data,侠侣对侠客的单独加成
    lover_skill_list,主角才有可能有的侠侣技能
    lover_skill_count,主角如果有侠侣技能就有这个数字。每场战斗最多放2个侠侣技能
    skill_data,技能数据
    skill 技能属性，详见fight_skill
    equip_list 装备信息,来自于userinfo
    gong_info = 武学信息,来自于用户数据
    gong_data = 武学实际加成
    yuan_data_list 一个侠客可能有多个缘属性
    {
        yuan_data 缘属性
            add_att
            add_def
            add_speed
            add_hp
            skill
    }
    yuan_skill
    final_data  --初始化后的最终值
    buff_list --每个人当前的buff值
]]
local Skill = require "fight_skill"

local setmetatable = setmetatable
local assert = assert
local error = error

local Character_conf = Character_conf
local Equipment_Upgrade_conf = Equipment_Upgrade_conf
local Equipment_Star_conf = Equipment_Star_conf
local Equipment_Set_conf = Equipment_Set_conf
local Nature_conf = Nature_conf

local function calc_attrib3(level)
    if level == 0 then return 0 end
    local t = 0
    local lv_limit = 0
    local index_list = Nature_conf.index
    for k,v in ipairs(index_list) do
        local conf = Nature_conf[v]
        local lv_t = conf.Nature_Lv
        local lv_top = 0
        if level <= lv_t then lv_top = level
        else lv_top = lv_t end
        t = t + (lv_top - lv_limit) * conf.Nature_Add
        if level <= lv_t then break
        else lv_limit = lv_top end
    end
    return t
end

local function calc_Dattrib3(level)
    if level == 0 then return 0 end
    local t = 0
    local factor = 1
    local lv_limit = 0
    local index_list = DNature_conf.index
    for k,v in ipairs(index_list) do
        local conf = DNature_conf[v]
        local lv_t = conf.DNature_Lv
        local lv_top = 0
        if level <= lv_t then lv_top = level
        else lv_top = lv_t end
        t = t + (lv_top - lv_limit) * conf.DNature_Add
        factor = conf.DNature_Factor
        if level <= lv_t then break
        else lv_limit = lv_top end
    end
    return t,factor
end

local Role = {}

Role.__index = Role

function Role:new()
    local self = {
        id = 0,
        posi = 0,
        type = nil,
        hp = 0,
        max_hp = 0,
        att = 0,
        def = 0,
        rdef = 0,
        df = 1,             --防御等级的修正系数
        speed = 0,
        mingzhong = 0,
        huibi = 0,
        baoji = 0,
        xiaojian = 0,
        zhaojia = 0,
        jibao = 0,
        relive = false,
        anti_love = 0,
        --attacked = false,
        base_data = {
            level = nil,
            star = 0,
            evolution = nil,
            hp = 0,
            att = 0,
            def = 0,
            speed = 0,
        },
        final_data = {  --初始化后的最终值
            att = 0,
            def = 0,
            hp = 0,
            speed = 0,
        },
        team_raise = nil,
        lover_data = nil,
        equip_list = nil,
        equip_data = nil,
        gong_info = nil,
        gong_data = nil,
        evolution_data = nil,
        wxjy_info = nil,
        wxjy_data = nil,
        group_wxjy_info = nil,
        group_wxjy_data = nil,
        skill = {},
        skill_data = {},
        yuan_data_list = nil,
        yuan_skill = nil,
        buff_list = nil,
        mj_list = nil,
        mj_data = nil,
        jiban_list = nil,
        group_wxjy_info = nil,
        group_wxjy_data = nil,
        qianneng = 0,
        bqp_info = nil,
        bqp_data = nil,
        sevenweapon = nil,
    }
    setmetatable(self, Role)
    return self
end

function Role:get_preview()
    local preview = {
        id = self.id,
        max_hp = self.max_hp,
        comming_hp = self.hp,
        end_hp = 0,
        posi = self.posi - 1,
        type = self.type,
        equip_list = self.equip_list
    }
    return preview
end

function Role:type_i()
    return 0  --0未知，1主将，2侠客
end

function Role:get_base_attrib()
    local conf = Character_conf[self.id]
    assert(conf ~= nil)
    local base_data = self.base_data
    local qianneng = self.qianneng
    --白字，基本的二级属性
    if qianneng and qianneng > 0 then
    	if self:type_i() == 1 then	
	    	base_data.hp = conf.LIFE + (conf.LIFE_GROWING + qianneng*10) * base_data.level
		    base_data.att = conf.ATTACK + (conf.ATTACK_GROWING + qianneng*4) * base_data.level
		    base_data.def = conf.DEFENSE + (conf.DEFENSE_GROWING + math.floor(qianneng*0.3)) * base_data.level
		    base_data.speed = conf.SPEED + (conf.SPEED_GROWING + math.floor(qianneng*1.5)) * base_data.level
    	elseif self:type_i() == 2 then
    		if conf.AD_KIND == 0 then
    			base_data.hp = conf.LIFE + (conf.LIFE_GROWING + qianneng*3) * base_data.level
	    		base_data.att = conf.ATTACK + (conf.ATTACK_GROWING + qianneng*3) * base_data.level
	    		base_data.def = conf.DEFENSE + (conf.DEFENSE_GROWING + math.floor(qianneng*0.3)) * base_data.level
	    		base_data.speed = conf.SPEED + (conf.SPEED_GROWING + math.floor(qianneng*1.2)) * base_data.level
    		else
    			base_data.hp = conf.LIFE + (conf.LIFE_GROWING + qianneng*10) * base_data.level
	    		base_data.att = conf.ATTACK + (conf.ATTACK_GROWING + qianneng) * base_data.level
	    		base_data.def = conf.DEFENSE + (conf.DEFENSE_GROWING + qianneng) * base_data.level
	    		base_data.speed = conf.SPEED + (conf.SPEED_GROWING + qianneng) * base_data.level    			
    		end
    	else
	    	base_data.hp = conf.LIFE + conf.LIFE_GROWING * base_data.level
		    base_data.att = conf.ATTACK + conf.ATTACK_GROWING * base_data.level
		    base_data.def = conf.DEFENSE + conf.DEFENSE_GROWING * base_data.level
		    base_data.speed = conf.SPEED + conf.SPEED_GROWING * base_data.level
    	end    	
		base_data.hp = math.floor(base_data.hp / 10)
		base_data.att = math.floor(base_data.att / 10)
		base_data.def = math.floor(base_data.def / 10)
		base_data.speed = math.floor(base_data.speed / 10)
	else
	    base_data.hp = math.floor((conf.LIFE + conf.LIFE_GROWING * base_data.level) / 10)
	    base_data.att = math.floor((conf.ATTACK + conf.ATTACK_GROWING * base_data.level) / 10)
	    base_data.def = math.floor((conf.DEFENSE + conf.DEFENSE_GROWING * base_data.level) / 10)
	    base_data.speed = math.floor((conf.SPEED + conf.SPEED_GROWING * base_data.level) / 10)
	end
	--三级属性
	self.mingzhong = conf.HIT
    self.huibi = conf.DODGE
    self.baoji = conf.CRIT
    self.xiaojian = conf.ANTICRIT
    self.zhaojia = conf.BLOCK
    self.jibao = conf.SKILL_CRIT
    --白字，武学吸进去的二级属性
    if self.gong_info then  --吸进去的武学是计算进阶加成的
        base_data.att = base_data.att + self.gong_info.add_atk
        base_data.def = base_data.def + self.gong_info.add_def
        base_data.hp = base_data.hp + self.gong_info.add_hp
        base_data.speed = base_data.speed + self.gong_info.add_speed
    end

    --绿字，进阶加成
    local evo = base_data.evolution
    if evo > 0 then
        local jie_buff_list = HeroJie_conf[self.id].JieBuff_List
        for k = 1, evo do
            if jie_buff_list[k] and jie_buff_list[k] > 0 then
                local buff_id = jie_buff_list[k]
                local evolution_data = self.evolution_data
                if evolution_data == nil then
                    evolution_data = {
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
                    }
                    self.evolution_data = evolution_data
                end
                local buff_conf = JieBuff_conf[buff_id]
                if buff_conf.Add_ATK > 0 then
                    evolution_data.add_atk = evolution_data.add_atk + buff_conf.Add_ATK
                end
                if buff_conf.Add_DEF > 0 then
                    evolution_data.add_def = evolution_data.add_def + buff_conf.Add_DEF
                end
                if buff_conf.Add_HP > 0 then
                    evolution_data.add_hp = evolution_data.add_hp + buff_conf.Add_HP
                end
                if buff_conf.Add_SPEED > 0 then
                    evolution_data.add_speed = evolution_data.add_speed + buff_conf.Add_SPEED
                end
                
                if buff_conf.Add_HIT > 0 then
                    evolution_data.add_mingzhong = evolution_data.add_mingzhong + buff_conf.Add_HIT
                end
                if buff_conf.Add_DODGE > 0 then
                    evolution_data.add_huibi = evolution_data.add_huibi + buff_conf.Add_DODGE
                end
                if buff_conf.Add_CRIT > 0 then
                    evolution_data.add_baoji = evolution_data.add_baoji + buff_conf.Add_CRIT
                end
                if buff_conf.Add_ANTICRIT > 0 then
                    evolution_data.add_xiaojian = evolution_data.add_xiaojian + buff_conf.Add_ANTICRIT
                end
                if buff_conf.Add_BLOCK > 0 then
                    evolution_data.add_zhaojia = evolution_data.add_zhaojia + buff_conf.Add_BLOCK
                end
                if buff_conf.Add_SkillCrit > 0 then
                    evolution_data.add_jibao = evolution_data.add_jibao + buff_conf.Add_SkillCrit
                end
            end
        end
    end
    --武学本级属性是绿字
    --3级属性本来是百分比，但是配置表里是乘10，所以这里直接取，fight_skill里按照千分比处理
    if self.gong_info then
        local gong = self.gong_info
        local gong_data = {
            add_atk = 0,
            add_def = 0,
            add_hp = 0,
            add_speed = 0,
            add_mingzhong = gong.add_mingzhong,
            add_huibi = gong.add_huibi,
            add_baoji = gong.add_baoji,
            add_xiaojian = gong.add_xiaojian,
            add_zhaojia = gong.add_zhaojia,
            add_jibao = gong.add_jibao,
        }
        for _,v in ipairs(gong.gong_list) do
            if v ~= 0 then
                local gong_conf = Gong_conf[v]
                assert(gong_conf, "gong conf not exist")
                gong_data.add_atk = gong_data.add_atk + gong_conf.Add_ATK
                gong_data.add_def = gong_data.add_def + gong_conf.Add_DEF
                gong_data.add_hp = gong_data.add_hp + gong_conf.Add_HP
                gong_data.add_speed = gong_data.add_speed + gong_conf.Add_SPEED
                gong_data.add_mingzhong = gong_data.add_mingzhong + gong_conf.Add_HIT
                gong_data.add_huibi = gong_data.add_huibi + gong_conf.Add_DODGE
                gong_data.add_baoji = gong_data.add_baoji + gong_conf.Add_CRIT
                gong_data.add_xiaojian = gong_data.add_xiaojian + gong_conf.Add_ANTICRIT
                gong_data.add_zhaojia = gong_data.add_zhaojia + gong_conf.Add_BLOCK
                gong_data.add_jibao = gong_data.add_jibao + gong_conf.Add_SkillCrit
            end
        end
        self.gong_data = gong_data
    end
    --绿字，秘籍
    if self.mj_list then
        local mj_data = {
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
        }
        for k,v in ipairs(self.mj_list) do
            local conf = Mi_conf[v.id + v.level]
            assert(conf, "mj conf not exist")
            mj_data.add_atk = mj_data.add_atk + conf.Add_ATK
            mj_data.add_def = mj_data.add_def + conf.Add_DEF
            mj_data.add_hp = mj_data.add_hp + conf.Add_HP
            mj_data.add_speed = mj_data.add_speed + conf.Add_SPEED
            mj_data.add_mingzhong = mj_data.add_mingzhong + conf.Add_HIT
            mj_data.add_huibi = mj_data.add_huibi + conf.Add_DODGE
            mj_data.add_baoji = mj_data.add_baoji + conf.Add_CRIT
            mj_data.add_xiaojian = mj_data.add_xiaojian + conf.Add_ANTICRIT
            mj_data.add_zhaojia = mj_data.add_zhaojia + conf.Add_BLOCK
            mj_data.add_jibao = mj_data.add_jibao + conf.Add_SkillCrit
            
            local conf1 = Mi_Jie_conf[v.id + v.jinjie]
            assert(conf1, "mj jinjie conf not exist")
            mj_data.add_atk = mj_data.add_atk + conf1.Add_ATK
            mj_data.add_def = mj_data.add_def + conf1.Add_DEF
            mj_data.add_hp = mj_data.add_hp + conf1.Add_HP
            mj_data.add_speed = mj_data.add_speed + conf1.Add_SPEED
            mj_data.add_mingzhong = mj_data.add_mingzhong + conf1.Add_HIT
            mj_data.add_huibi = mj_data.add_huibi + conf1.Add_DODGE
            mj_data.add_baoji = mj_data.add_baoji + conf1.Add_CRIT
            mj_data.add_xiaojian = mj_data.add_xiaojian + conf1.Add_ANTICRIT
            mj_data.add_zhaojia = mj_data.add_zhaojia + conf1.Add_BLOCK
            mj_data.add_jibao = mj_data.add_jibao + conf1.Add_SkillCrit
        end
        self.mj_data = mj_data
    end

    if self.bqp_info then -- 兵器谱
        local bqp_data = {
            add_atk = 0,
            add_def = 0,
            add_hp = 0,
            add_mingzhong = 0,
            add_huibi = 0,
            add_baoji = 0,
            add_xiaojian = 0,
            add_jibao = 0,
        }
        local t = self.bqp_info.atk_list
        if rawget(self.bqp_info, "atk_list") then
            for _,v in ipairs(self.bqp_info.atk_list) do
                if v.id > 0 then
                    local conf = BQP_conf[v.id]
                    assert(conf, "bqp conf not exist")
                    bqp_data.add_atk = bqp_data.add_atk + conf.Add_ATK*v.level
                    bqp_data.add_def = bqp_data.add_def + conf.Add_DEF*v.level
                    bqp_data.add_hp = bqp_data.add_hp + conf.Add_HP*v.level
                    bqp_data.add_mingzhong = bqp_data.add_mingzhong + conf.Add_HIT*v.level
                    bqp_data.add_huibi = bqp_data.add_huibi + conf.Add_DODGE*v.level
                    bqp_data.add_baoji = bqp_data.add_baoji + conf.Add_CRIT*v.level
                    bqp_data.add_xiaojian = bqp_data.add_xiaojian + conf.Add_ANTICRIT*v.level
                    bqp_data.add_jibao = bqp_data.add_jibao + conf.Add_SkillCrit*v.level
                end
            end
        end
        t = self.bqp_info.def_list
        if rawget(self.bqp_info, "def_list") then
            for _,v in ipairs(self.bqp_info.def_list) do
                if v.id > 0 then
                    local conf = BQP_conf[v.id]
                    assert(conf, "bqp conf not exist")
                    bqp_data.add_atk = bqp_data.add_atk + conf.Add_ATK*v.level
                    bqp_data.add_def = bqp_data.add_def + conf.Add_DEF*v.level
                    bqp_data.add_hp = bqp_data.add_hp + conf.Add_HP*v.level
                    bqp_data.add_mingzhong = bqp_data.add_mingzhong + conf.Add_HIT*v.level
                    bqp_data.add_huibi = bqp_data.add_huibi + conf.Add_DODGE*v.level
                    bqp_data.add_baoji = bqp_data.add_baoji + conf.Add_CRIT*v.level
                    bqp_data.add_xiaojian = bqp_data.add_xiaojian + conf.Add_ANTICRIT*v.level
                    bqp_data.add_jibao = bqp_data.add_jibao + conf.Add_SkillCrit*v.level
                end
            end
        end

        if rawget(self.bqp_info, "personal") then
            if self.bqp_info.personal.id > 0 then
                local conf = BQP_conf[self.bqp_info.personal.id]
                assert(conf, "bqp conf not exist")
                bqp_data.add_atk = bqp_data.add_atk + conf.Add_ATK*self.bqp_info.personal.level
                bqp_data.add_def = bqp_data.add_def + conf.Add_DEF*self.bqp_info.personal.level
                bqp_data.add_hp = bqp_data.add_hp + conf.Add_HP*self.bqp_info.personal.level
                bqp_data.add_mingzhong = bqp_data.add_mingzhong + conf.Add_HIT*self.bqp_info.personal.level
                bqp_data.add_huibi = bqp_data.add_huibi + conf.Add_DODGE*self.bqp_info.personal.level
                bqp_data.add_baoji = bqp_data.add_baoji + conf.Add_CRIT*self.bqp_info.personal.level
                bqp_data.add_xiaojian = bqp_data.add_xiaojian + conf.Add_ANTICRIT*self.bqp_info.personal.level
                bqp_data.add_jibao = bqp_data.add_jibao + conf.Add_SkillCrit*self.bqp_info.personal.level
            end
        end
        self.bqp_data = bqp_data
        --printtab(bqp_data)
    end
    --绿字，武器加成
    if self.equip_list then -- 计算武器加成
        local equip_data = {add_att = 0, add_def = 0, add_hp = 0, add_speed = 0,
            add_mingzhong = 0, add_huibi = 0, add_baoji = 0, add_xiaojian = 0, add_zhaojia = 0, add_jibao = 0}
        self.equip_data = equip_data
        local level_set = -1
        local star_set = -1
        local no_set = false
        for k,v in ipairs(self.equip_list) do
            local level = v.level
            local star = v.star
            if level > 0 then
                local idx = 130000000 + k * 10000 + level
                local data = Equipment_Upgrade_conf[idx]
                assert(data, string.format("Equipment_Upgrade idx = %d",idx))
                equip_data.add_att = equip_data.add_att + data.ATTACK_RAISE
                equip_data.add_def = equip_data.add_def + data.DEFENSE_RAISE
                equip_data.add_hp = equip_data.add_hp + data.LIFE_RAISE
                equip_data.add_speed = equip_data.add_speed + data.SPEED_RAISE
                if star > 0 then
                    local idx = 140000000 + k * 10000 + star
                    local data = Equipment_Star_conf[idx]
                    assert(data)
                    equip_data.add_att = equip_data.add_att + data.ATTACK_RAISE
                    equip_data.add_def = equip_data.add_def + data.DEFENSE_RAISE
                    equip_data.add_hp = equip_data.add_hp + data.LIFE_RAISE
                    equip_data.add_speed = equip_data.add_speed + data.SPEED_RAISE
                    equip_data.add_mingzhong = equip_data.add_mingzhong + data.HIT
                    equip_data.add_huibi = equip_data.add_huibi + data.DODGE
                    equip_data.add_baoji = equip_data.add_baoji + data.CRIT
                    equip_data.add_xiaojian = equip_data.add_xiaojian + data.ANTICRIT
                    equip_data.add_zhaojia = equip_data.add_zhaojia + data.BLOCK
                    equip_data.add_jibao = equip_data.add_jibao + data.SKILL_CRIT
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
            equip_data.add_att = equip_data.add_att + data.ATTACK_RAISE
            equip_data.add_def = equip_data.add_def + data.DEFENSE_RAISE
            equip_data.add_hp = equip_data.add_hp + data.LIFE_RAISE
            equip_data.add_speed = equip_data.add_speed + data.SPEED_RAISE
        end
        if (not no_set) and star_set > 0 then
            local idx = 182000000 + star_set
            local data = Equipment_Set_conf[idx]
            assert(data)
            equip_data.add_att = equip_data.add_att + data.ATTACK_RAISE
            equip_data.add_def = equip_data.add_def + data.DEFENSE_RAISE
            equip_data.add_hp = equip_data.add_hp + data.LIFE_RAISE
            equip_data.add_speed = equip_data.add_speed + data.SPEED_RAISE
        end
    end

    if self.wxjy_info then
        local wxjy = self.wxjy_info
        local wxjy_data = {add_att = 0, add_def = 0, add_hp = 0, add_speed = 0,
            add_mingzhong = 0, add_huibi = 0, add_baoji = 0, add_xiaojian = 0, add_zhaojia = 0, add_jibao = 0}
        self.wxjy_data = wxjy_data
        
        if wxjy[12] and wxjy[12] > 0 then
            local conf_a = Extreme_conf[wxjy[12]].C_ATTACK
            if conf_a > 0 then
                wxjy_data.add_att = conf_a
            end
        end
        if wxjy[13] and wxjy[13] > 0 then
            local conf_d = Extreme_conf[wxjy[13]].C_DEFENSE
            if conf_d > 0 then
                wxjy_data.add_def = conf_d
            end
        end
        if wxjy[11] and wxjy[11] > 0 then
            local conf_h = Extreme_conf[wxjy[11]].C_LIFE
            if conf_h > 0 then
                wxjy_data.add_hp = conf_h
            end
        end
        if wxjy[14] and wxjy[14] > 0 then
            local conf_s = Extreme_conf[wxjy[14]].C_SPEED
            if conf_s > 0 then
                wxjy_data.add_speed = conf_s
            end
        end
        if wxjy[15] and wxjy[15] > 0 then
            local conf_h = Extreme_conf[wxjy[15]].C_HIT
            if conf_h > 0 then
                wxjy_data.add_mingzhong = conf_h
            end
        end
        if wxjy[16] and wxjy[16] > 0 then
            local conf_d = Extreme_conf[wxjy[16]].C_DODGE
            if conf_d > 0 then
                wxjy_data.add_huibi = conf_d
            end
        end
        if wxjy[17] and wxjy[17] > 0 then
            local conf_c = Extreme_conf[wxjy[17]].C_CRIT
            if conf_c > 0 then
                wxjy_data.add_baoji = conf_c
            end
        end
        if wxjy[18] and wxjy[18] > 0 then
            local conf_s = Extreme_conf[wxjy[18]].C_SKILL_CRIT
            if conf_s > 0 then
                wxjy_data.add_jibao = conf_s
            end
        end
        if wxjy[19] and wxjy[19] > 0 then
            local conf_ac = Extreme_conf[wxjy[19]].C_ANTICRIT
            if conf_ac > 0 then
                wxjy_data.add_xiaojian = conf_ac
            end
        end
    end
    
    if self.group_wxjy_info then
        local wxjy = self.group_wxjy_info
        local wxjy_data = {add_att = 0, add_def = 0, add_hp = 0, add_speed = 0,
            add_mingzhong = 0, add_huibi = 0, add_baoji = 0, add_xiaojian = 0, add_zhaojia = 0, add_jibao = 0}
        self.group_wxjy_data = wxjy_data
        
        if wxjy[12] and wxjy[12] > 0 then
            local conf_a = Men_Extreme_conf[wxjy[12]].C_ATTACK
            if conf_a > 0 then
                wxjy_data.add_att = conf_a
            end
        end
        if wxjy[13] and wxjy[13] > 0 then
            local conf_d = Men_Extreme_conf[wxjy[13]].C_DEFENSE
            if conf_d > 0 then
                wxjy_data.add_def = conf_d
            end
        end
        if wxjy[11] and wxjy[11] > 0 then
            local conf_h = Men_Extreme_conf[wxjy[11]].C_LIFE
            if conf_h > 0 then
                wxjy_data.add_hp = conf_h
            end
        end
        if wxjy[14] and wxjy[14] > 0 then
            local conf_s = Men_Extreme_conf[wxjy[14]].C_SPEED
            if conf_s > 0 then
                wxjy_data.add_speed = conf_s
            end
        end
        if wxjy[15] and wxjy[15] > 0 then
            local conf_h = Men_Extreme_conf[wxjy[15]].C_HIT
            if conf_h > 0 then
                wxjy_data.add_mingzhong = conf_h
            end
        end
        if wxjy[16] and wxjy[16] > 0 then
            local conf_d = Men_Extreme_conf[wxjy[16]].C_DODGE
            if conf_d > 0 then
                wxjy_data.add_huibi = conf_d
            end
        end
        if wxjy[17] and wxjy[17] > 0 then
            local conf_c = Men_Extreme_conf[wxjy[17]].C_CRIT
            if conf_c > 0 then
                wxjy_data.add_baoji = conf_c
            end
        end
        if wxjy[18] and wxjy[18] > 0 then
            local conf_s = Men_Extreme_conf[wxjy[18]].C_SKILL_CRIT
            if conf_s > 0 then
                wxjy_data.add_jibao = conf_s
            end
        end
        if wxjy[19] and wxjy[19] > 0 then
            local conf_ac = Men_Extreme_conf[wxjy[19]].C_ANTICRIT
            if conf_ac > 0 then
                wxjy_data.add_xiaojian = conf_ac
            end
        end
    end
    self.skill = Skill:new(self.skill_data.id, self.skill_data.level)
end

function Role:get_attrib(jiban_list)
    if self:type_i() == 1 or self:type_i() == 2 then
        self:get_base_attrib()
    elseif self:type_i() == 3 then
        self:get_monster_attrib()
    else
        error("role type err")
    end
    self:fill_attrib()
    if jiban_list then
        self.jiban_list = jiban_list
        for k,v in ipairs(jiban_list) do
            local t = 20 + v.base_data.evolution * 5
            self.max_hp = self.max_hp + math.floor(v.max_hp * t / 100)
            self.hp = self.max_hp
            self.att = self.att + math.floor(v.att * t / 100)
            self.def = self.def + math.floor(v.def * t / 100)
            self.speed = self.speed + math.floor(v.speed * t / 100)
            --print(string.format("(%d:%d %d %d %d)-->%d[%d]", v.id,v.max_hp,v.att,v.def,v.speed, self.id,self.posi))
        end
    end
    
    local skill = self.skill
    skill:get_conf(self.att)
    if self.yuan_skill then
        self.yuan_skill.base_att = self.yuan_skill.base_att + self.att
    end
    if self.lover_skill_list then
        for k,v in ipairs(self.lover_skill_list) do
            v:get_conf(0)--因为一般技能是att*damage/100，而侠侣技能是damage，所以att直接设为100
        end
        self.lover_skill_count = 2
    end
    --print("posi:", self.posi, self.att, self.def, self.hp)
    --[[
    if self.qianneng > 0 then
    	LOG_INFO(string.format("Id:%d,qianneng:%d,hp:%d,att:%d,def:%d,speed:%d", self.id, self.qianneng, self.base_data.hp, self.base_data.att, self.base_data.def, self.base_data.speed))
    	LOG_INFO(string.format("id:%d,qianneng:%d,hp:%d,att:%d,def:%d,speed:%d", self.id, self.qianneng, self.hp, self.att, self.def, self.speed))
	end
	--]]
end

function Role:fill_attrib()
    local base_data = self.base_data
    local final_data= self.final_data
    final_data.att = base_data.att
    final_data.def = base_data.def
    final_data.hp = base_data.hp
    final_data.speed = base_data.speed
    if self:type_i() == 1 or self:type_i() == 2 then
        --LOG_DEBUG(string.format("id = %d", self.id))
        --LOG_DEBUG(string.format("----base: att = %d, def = %d, hp = %d, speed = %d", base_data.att, base_data.def, base_data.hp, base_data.speed))
        --白字，进阶后
        local e_add_hp = 1
        local e_add_speed = 1
        local e_add_att = 1
        local e_add_def = 1
        if base_data.evolution > 0 then
            e_add_hp = 1 + base_data.evolution / 10
            e_add_speed = e_add_hp
            e_add_att = e_add_hp
            e_add_def = e_add_hp
        end
        
        local yuan_data_list = self.yuan_data_list
        if yuan_data_list then
            for k,v in ipairs(yuan_data_list) do
                e_add_hp = e_add_hp + v.add_hp
                e_add_speed = e_add_speed + v.add_speed
                e_add_att = e_add_att + v.add_att
                e_add_def = e_add_def + v.add_def
            end
            --LOG_DEBUG(string.format("----yuan: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed))
        end
        final_data.att = math.floor(final_data.att * (e_add_att))
        final_data.def = math.floor(final_data.def * (e_add_def))
        final_data.hp = math.floor(final_data.hp * (e_add_hp))
        final_data.speed = math.floor(final_data.speed * (e_add_speed))
        
        -- 武学
        local gong_data = self.gong_data
        if gong_data then
            --LOG_DEBUG(string.format("----befor gong: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed))
            final_data.att = final_data.att + gong_data.add_atk
            final_data.def = final_data.def + gong_data.add_def
            final_data.hp = final_data.hp + gong_data.add_hp
            final_data.speed = final_data.speed + gong_data.add_speed
            --LOG_DEBUG(string.format("----gong: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed))
            self.mingzhong = self.mingzhong + gong_data.add_mingzhong
            self.huibi = self.huibi + gong_data.add_huibi
            self.baoji = self.baoji + gong_data.add_baoji
            self.xiaojian = self.xiaojian + gong_data.add_xiaojian
            self.zhaojia = self.zhaojia + gong_data.add_zhaojia
            self.jibao = self.jibao + gong_data.add_jibao
        end
        -- 秘籍
        local mj_data = self.mj_data
        if mj_data then
            --LOG_DEBUG(string.format("----befor gong: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed))
            final_data.att = final_data.att + mj_data.add_atk
            final_data.def = final_data.def + mj_data.add_def
            final_data.hp = final_data.hp + mj_data.add_hp
            final_data.speed = final_data.speed + mj_data.add_speed
            --LOG_DEBUG(string.format("----gong: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed))
            self.mingzhong = self.mingzhong + mj_data.add_mingzhong
            self.huibi = self.huibi + mj_data.add_huibi
            self.baoji = self.baoji + mj_data.add_baoji
            self.xiaojian = self.xiaojian + mj_data.add_xiaojian
            self.zhaojia = self.zhaojia + mj_data.add_zhaojia
            self.jibao = self.jibao + mj_data.add_jibao
        end
        -- 装备
        local equip_data = self.equip_data
        if equip_data then
            final_data.att = final_data.att + equip_data.add_att
            final_data.def = final_data.def + equip_data.add_def
            final_data.hp = final_data.hp + equip_data.add_hp
            final_data.speed = final_data.speed + equip_data.add_speed
            --LOG_DEBUG(string.format("----equip: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed)) 
            self.mingzhong = self.mingzhong + equip_data.add_mingzhong
            self.huibi = self.huibi + equip_data.add_huibi
            self.baoji = self.baoji + equip_data.add_baoji
            self.xiaojian = self.xiaojian + equip_data.add_xiaojian
            self.zhaojia = self.zhaojia + equip_data.add_zhaojia
            self.jibao = self.jibao + equip_data.add_jibao       
        end
        -- 单独侠侣加成
        local lover_data = self.lover_data
        if lover_data then
            final_data.att = final_data.att + lover_data.add_att
            final_data.def = final_data.def + lover_data.add_def
            final_data.hp = final_data.hp + lover_data.add_hp
            final_data.speed = final_data.speed + lover_data.add_speed
            --LOG_DEBUG(string.format("----lover: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed))        
        end
        -- 侠侣，巨著等的团队加成
        local team_data = self.team_raise
        if team_data then
            final_data.att = final_data.att + team_data.att
            final_data.def = final_data.def + team_data.def
            final_data.hp = final_data.hp + team_data.hp
            final_data.speed = final_data.speed + team_data.speed
            self.mingzhong = self.mingzhong + team_data.add_mingzhong
            self.huibi = self.huibi + team_data.add_huibi
            self.baoji = self.baoji + team_data.add_baoji
            self.xiaojian = self.xiaojian + team_data.add_xiaojian
            self.zhaojia = self.zhaojia + team_data.add_zhaojia
            self.jibao = self.jibao + team_data.add_jibao  
            --LOG_DEBUG(string.format("----team: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed))        
        end

        -- 进阶额外加成
        local evo_data = self.evolution_data
        if evo_data then
            final_data.att = final_data.att + evo_data.add_atk
            final_data.def = final_data.def + evo_data.add_def
            final_data.hp = final_data.hp + evo_data.add_hp
            final_data.speed = final_data.speed + evo_data.add_speed
            --LOG_DEBUG(string.format("----evo: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed)) 
            self.mingzhong = self.mingzhong + evo_data.add_mingzhong
            self.huibi = self.huibi + evo_data.add_huibi
            self.baoji = self.baoji + evo_data.add_baoji
            self.xiaojian = self.xiaojian + evo_data.add_xiaojian
            self.zhaojia = self.zhaojia + evo_data.add_zhaojia
            self.jibao = self.jibao + evo_data.add_jibao       
        end
        
        -- wxjy加成
        local wxjy_data = self.wxjy_data
        if wxjy_data then
            final_data.att = final_data.att + wxjy_data.add_att
            final_data.def = final_data.def + wxjy_data.add_def
            final_data.hp = final_data.hp + wxjy_data.add_hp
            final_data.speed = final_data.speed + wxjy_data.add_speed
            --LOG_DEBUG(string.format("----evo: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed)) 
            self.mingzhong = self.mingzhong + wxjy_data.add_mingzhong
            self.huibi = self.huibi + wxjy_data.add_huibi
            self.baoji = self.baoji + wxjy_data.add_baoji
            self.xiaojian = self.xiaojian + wxjy_data.add_xiaojian
            self.zhaojia = self.zhaojia + wxjy_data.add_zhaojia
            self.jibao = self.jibao + wxjy_data.add_jibao       
        end
        wxjy_data = self.group_wxjy_data
        if wxjy_data then
            final_data.att = final_data.att + wxjy_data.add_att
            final_data.def = final_data.def + wxjy_data.add_def
            final_data.hp = final_data.hp + wxjy_data.add_hp
            final_data.speed = final_data.speed + wxjy_data.add_speed
            --LOG_DEBUG(string.format("----evo: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed)) 
            self.mingzhong = self.mingzhong + wxjy_data.add_mingzhong
            self.huibi = self.huibi + wxjy_data.add_huibi
            self.baoji = self.baoji + wxjy_data.add_baoji
            self.xiaojian = self.xiaojian + wxjy_data.add_xiaojian
            self.zhaojia = self.zhaojia + wxjy_data.add_zhaojia
            self.jibao = self.jibao + wxjy_data.add_jibao       
        end

        local bqp_data = self.bqp_data
        if bqp_data then
            final_data.att = final_data.att + bqp_data.add_atk
            final_data.def = final_data.def + bqp_data.add_def
            final_data.hp = final_data.hp + bqp_data.add_hp
            --LOG_DEBUG(string.format("----bqp: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed))
            self.mingzhong = self.mingzhong + bqp_data.add_mingzhong
            self.huibi = self.huibi + bqp_data.add_huibi
            self.baoji = self.baoji + bqp_data.add_baoji
            self.xiaojian = self.xiaojian + bqp_data.add_xiaojian
            self.jibao = self.jibao + bqp_data.add_jibao
        end

        -- 七种武器站位加成
        local sevenweapon = self.sevenweapon
        if sevenweapon then
            final_data.att = final_data.att + sevenweapon.att
            final_data.def = final_data.def + sevenweapon.def
            final_data.hp = final_data.hp + sevenweapon.hp
            --print("7w:"..sevenweapon.att.." "..sevenweapon.def.." "..sevenweapon.hp)
            --LOG_DEBUG(string.format("----7w: att = %d, def = %d, hp = %d, speed = %d", final_data.att, final_data.def, final_data.hp, final_data.speed))        
        end
        
        self.mingzhong = 1000 + calc_attrib3(self.mingzhong) * 10
        self.huibi = calc_attrib3(self.huibi) * 10
        self.baoji = calc_attrib3(self.baoji) * 10
        self.xiaojian = calc_attrib3(math.floor(self.xiaojian * 0.2)) * 10
        self.zhaojia = calc_attrib3(self.zhaojia) * 10
        self.jibao = calc_attrib3(self.jibao) * 10
        --LOG_DEBUG(string.format("----final: att = %d, def = %d, hp = %d", final_data.att, final_data.def, final_data.hp))
    else
        --LOG_DEBUG(string.format("id = %d", self.id))
        --LOG_DEBUG(string.format("----npc: att = %d, def = %d, hp = %d, speed = %d", base_data.att, base_data.def, base_data.hp, base_data.speed))
    end
    
    self.att = math.floor(final_data.att)
    self.def = math.floor(final_data.def)
    self.hp = math.floor(final_data.hp)
    self.speed = math.floor(final_data.speed)
    self.rdef, self.df = calc_Dattrib3(self.def)
    if self.buff_handle then self.buff_handle(self) end
    self.max_hp = self.hp
end

function Role:do_attack(attack, posi_list)
    -- 先处理侠侣技能，主角阶段，不占用出手次数
    -- 然后处理缘技能。缘技能如果成功发动，则不会再发动普通技能
    -- 最后处理普通技能
    local hurt = 0
    local rehurt = 0
    local buff_list = rawget(self, "buff_list")
    local buff3 = false
    if buff_list then
        local num = #buff_list
        for k = num,1,-1 do
            local buff = rawget(buff_list, k)
            if buff.type == 3 then
                buff3 = true
            elseif buff.type == 1 then
                if buff.count == 1 then
                    self.def = self.def - buff.value
                    self:reflesh_def(self.def)
                    table.remove(buff_list, k)
                else
                    buff.count = buff.count - 1
                end
            end
        end
    end
    
    if not buff3 then -- 没有眩晕才攻击
        local data = nil
        local lover_skill_list = rawget(self, "lover_skill_list")
        if self.anti_love > 0 then self.anti_love = 0
        elseif lover_skill_list then
            local lover_skill_count = self.lover_skill_count
            if self.lover_skill_count > 0 then
                for k,v in ipairs(lover_skill_list) do
                    data = v:do_attack(self, posi_list, true)
                    if data then
                        self.anti_love = 1
                        table.remove(lover_skill_list, k)
                        self.lover_skill_count = lover_skill_count - 1
                        if(lover_skill_count == 1) then rawset(self, "lover_skill_list", nil) end
                        break
                    end
                end
            end
        end
        if data then
            attack.combination = data
        end
        data = nil
        local data2 = nil
        local hurt2 = 0
        local rehurt2 = 0
        if self.yuan_skill and (not self.yuan_skill.stop) then
            data, hurt, rehurt, data2, hurt2, rehurt2 = self.yuan_skill:do_attack(self, posi_list, true)
        end
        if data then
            attack.yuan = data
        else
            attack.normal, hurt, rehurt, data2, hurt2, rehurt2 = self.skill:do_attack(self, posi_list)
        end

        if data2 then
            attack.ext_skill = data2
            hurt = hurt + hurt2
            rehurt = rehurt + rehurt2
            --printtab(data2, "proto:")
        end
    end
    local buff_list = rawget(self, "buff_list")
    if not buff_list then return hurt, rehurt end
    local num = #buff_list
    for k = num,1,-1 do
        local buff = rawget(buff_list, k)
        if buff.type ~= 1 then
            if buff.count == 1 then
                if buff.type == 2 then
                    self.att = self.att - buff.value
                    local tag_skill = self.skill
                    if tag_skill then tag_skill:fix_att(self.att) end
                    if self.yuan_skill then
                        self.yuan_skill.base_att = self.yuan_skill.base_att - buff.value
                        self.yuan_skill:fix_att(self.yuan_skill.base_att)
                    end
                end
                table.remove(buff_list, k)
            else
                buff.count = buff.count - 1
            end
        end
    end
    num = #buff_list
    if num == 0 then
        rawset(self, "buff_list", nil)
    end
    return hurt, rehurt
end

function Role:reduce_hp(value)
    local hurt = value
    local t = self.hp
    if self.hp < value then
        hurt = self.hp
        self.hp = 0
    else
        self.hp = self.hp - value
    end
    return hurt
end

function Role:add_hp(value)
    self.hp = self.hp + value
    if self.hp > self.max_hp then self.hp = self.max_hp end
end

function Role:reflesh_def(value)
    --local rdef = self.rdef
    --local df = self.df
    self.rdef,self.df = calc_Dattrib3(value)  
end

return Role