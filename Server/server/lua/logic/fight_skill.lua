--[[
        技能
        id: 技能id
        conf：技能配置
        att_value{伤害值}
        att_value_list(伤害值列表)
        att_value_list_conf
        probably:触发概率
        type:技能类型
        damage:攻击百分比
        damage1:增加的伤害绝对值
        buff:buff(眩晕)概率
        f_att: 强制伤害
]]

local mfloor = math.floor
local mrandom = math.random
local ipairs = ipairs
local tinsert = table.insert
local sformat = string.format
local setmetatable = setmetatable
local assert = assert

local Skill_conf = Skill_conf

local att_seq = {   -- 每个站位的攻击顺序
    {1,4,2,5,3,6,7},
    {2,1,5,3,6,4,7},
    {3,2,6,7,1,5,4},
    {1,4,2,5,3,6,7},
    {1,2,5,4,3,6,7},
    {2,3,6,1,5,7,4},
    {3,7,2,6,1,5,4}
}

local trident = {   -- 打3排的情况下，攻击顺序
    {1,4,5},
    {2,5,6},
    {3,6,7},
    {4,1},
    {5,1,2},
    {6,2,3},
    {7,3}
}

local function get_tag(posi_list, posi, type)
    local self_group = 0
    local enemy_group = 100
    if posi > 100 then
        self_group = 100
        enemy_group = 0
    end
    local tags = {}
    local p = posi % 100
    local livenum = 0
    if type == 0 or type == 1 or type == 15 then   -- 普通攻击/单人攻击
        for k,v in ipairs(att_seq[p]) do
            if posi_list[enemy_group + v] and
                posi_list[enemy_group + v].hp > 0 then
                tinsert(tags, posi_list[enemy_group + v])
                break
            end
        end
    elseif type == 2 then           -- 全体攻击
        for k = 1,7 do
             if posi_list[enemy_group + k] and
                posi_list[enemy_group + k].hp > 0 then
                tinsert(tags, posi_list[enemy_group + k])
            end
        end
    elseif type == 3 then           -- 优先打前排
        local t = 0
        for i = 1,3 do
            if posi_list[enemy_group + i] and
                posi_list[enemy_group + i].hp > 0 then
                tinsert(tags, posi_list[enemy_group + i])
                t = t + 1
            end
        end
        if t == 0 then
            for i = 4,7 do
                if posi_list[enemy_group + i] and
                    posi_list[enemy_group + i].hp > 0 then
                    tinsert(tags, posi_list[enemy_group + i])
                end
            end
        end
    elseif type == 4 
        or type == 13 then           -- 打3排
                                    -- 先选中中心目标，再确定上下目标
        for k,v in ipairs(att_seq[p]) do
            if posi_list[enemy_group + v] and
                posi_list[enemy_group + v].hp > 0 then
                for k1,v1 in ipairs(trident[v]) do
                    if posi_list[enemy_group + v1] and
                        posi_list[enemy_group + v1].hp > 0 then
                        tinsert(tags, posi_list[enemy_group + v1])
                    end
                end
                break
            end
        end
    elseif type == 5 then           -- 单人治疗
        local tp = {1.1, nil}
        local t
        local percent = 0
        for i = 1,7 do
            if posi_list[self_group + i] and
                posi_list[self_group + i].hp > 0 then
                t = posi_list[self_group + i]
                percent = t.hp / t.max_hp
                if percent < tp[1] then
                    tp[1] = percent
                    tp[2] = posi_list[self_group + i]
                end
            end
        end
        tinsert(tags, tp[2])
    elseif type == 6 or type == 11 or type == 12 or type == 14 or type == 17 then           -- 己方全体治疗/加攻
        for k = 1,7 do
            if posi_list[self_group + k] and
                posi_list[self_group + k].hp > 0 then
                livenum = livenum + 1
                tinsert(tags, posi_list[self_group + k])
            end
        end
    elseif type == 7 then           -- 优先打后排
        local t = 0
        for i = 4,7 do
            if posi_list[enemy_group + i] and
                posi_list[enemy_group + i].hp > 0 then
                tinsert(tags, posi_list[enemy_group + i])
                t = t + 1
            end
        end
        if t == 0 then
            for i = 1,3 do
                if posi_list[enemy_group + i] and
                    posi_list[enemy_group + i].hp > 0 then
                    tinsert(tags, posi_list[enemy_group + i])
                end
            end
        end
    elseif type == 8 or type == 9 or type== 10 then --随机2,3,4个人
        local num = type - 6
        local t = {}
        for k = 1,7 do
            if posi_list[enemy_group + k] and
                posi_list[enemy_group + k].hp > 0 then
                tinsert(t, posi_list[enemy_group + k])
            end
        end
        local l = #t
        while l > 0 and num > 0 do
            local idx = mrandom(1,l)
            tinsert(tags, t[idx])
            table.remove(t, idx)
            l = l - 1
            num = num - 1
        end
    elseif type == 16 then --血量百分比最低
        local tmp = nil
        for k = 1,7 do
            if posi_list[self_group + k] and posi_list[self_group + k].hp > 0 then
                if not tmp then
                    tmp = posi_list[self_group + k]
                else
                    local percent = posi_list[self_group + k].hp/posi_list[self_group + k].max_hp
                    if percent < tmp.hp/tmp.max_hp then
                        tmp = posi_list[self_group + k]
                    end
                end
            end
        end
        if tmp then
            tinsert(tags, tmp)
        end
    end
    return tags,livenum
end

local Skill = {}

Skill.__index = Skill

function Skill:new(skill_id, level)
    local self = {
        id = skill_id,
        level = level,
        conf = nil,
        att_value = 0,
        att_value_list = nil,
        att_value_list_conf = nil,
        probably = 0,
        type = 0,
        damage = 0,
        damage1 = 0,
        buff = 0,
        base_att = 0,       -- 记录基础att，方便在获取加攻buff后一起增加
        f_att = 0,
    }
    setmetatable(self, Skill)
    return self
end

function Skill:get_conf(base_att, newskill)
    local selfskill = nil
    if newskill then
        selfskill = newskill
    else
        selfskill = self
    end
    assert(selfskill)

    if selfskill.id == 0 then return end
    assert(Skill_conf[selfskill.id], sformat("skill conf %d not find", selfskill.id))
    selfskill.conf = Skill_conf[selfskill.id]
    local conf = selfskill.conf
    selfskill.probably = conf.TRIGGER_PROBABILITY
    selfskill.type = conf.SKILL_TYPE
    local skill_type = selfskill.type
    if skill_type == 15 then
        selfskill.buff = conf.SKILL_VALUE[1] * 10 + (selfskill.level - 1)
        if #conf.SKILL_VALUE > 1 then
            selfskill.att_value_list_conf = clonetab(conf.SKILL_VALUE)
            table.remove(selfskill.att_value_list_conf, 1)
        end
    else
        if conf.SKILL_VALUE[1] ~= 0 then
            selfskill.att_value_list_conf = conf.SKILL_VALUE
        end
    end
    
    if selfskill.type == 11 or selfskill.type == 12 or selfskill.type == 14 then
        selfskill.damage = conf.DAMAGE
    else
        selfskill.damage = conf.DAMAGE / 100
    end
    selfskill.damage1 = conf.DAMAGE_GROWING * selfskill.level
    
    
    local att_value_list = {}
    if not selfskill.att_value_list_conf then
        tinsert(att_value_list, 1)
    else
        for _, v in ipairs(selfskill.att_value_list_conf) do
            tinsert(att_value_list, v / 100)
        end
    end
    selfskill.att_value_list = att_value_list
    selfskill.base_att = base_att
    selfskill:fix_att(base_att, newskill)
    selfskill.f_att = conf.True_Dam
    if selfskill.f_att > 0 then
        selfskill.f_att = selfskill.f_att + conf.DAMAGE_GROWING * selfskill.level
    end
end

function Skill:fix_att(att_value, newskill)
    local selfskill = nil
    if newskill then
        selfskill = newskill
    else
        selfskill = self
    end
    assert(selfskill)
    if selfskill.type == 11 or selfskill.type == 12 or selfskill.type == 14 then
        selfskill.att_value = selfskill.damage + selfskill.damage1
    else
        selfskill.att_value = selfskill.damage * att_value + selfskill.damage1
    end
end

function Skill:do_attack(role, posi_list, force_skill)
    if self.id == 0 or mrandom(1000) > self.probably then
        if not force_skill then
            return self:normal_hit(role, posi_list)
        else return nil, 0, 0 end
    else
        return self:skill_hit(role, posi_list)
    end
end

function Skill:normal_hit(role, posi_list)
    local hurt_list = {}
    local normal = {
        skill_id = 0,
        hurt_list = hurt_list,
    }
    local shurt = 0--本次伤害
    local rehurt = 0
    local tags = get_tag(posi_list, role.posi, 0)
    for k,v in ipairs(tags) do
        assert(v)
        local attack = {}
        local tag = v
        local hurt = {
            posi = tag.posi - 1,
            attack = attack,
            attack_type = 0,
        }
        tinsert(hurt_list, hurt)
        local att_value = mfloor((role.att - tag.def / tag.df) * (1 - tag.rdef/100))
        if att_value < 1 then att_value = 1 end
        -- 命中，招架， 暴击
        local mingzhong = role.mingzhong - tag.huibi
        local baoji = role.baoji - tag.xiaojian
        local zhaojia = tag.zhaojia
        if mrandom(1000) > mingzhong then
            -- 没命中，就啥事没有了
            tinsert(attack, 0)
            hurt.attack_type = 2
        else
            hurt.attack_type = 0
            if mrandom(1000) < baoji then
            -- 暴击
                att_value = 2 * att_value
                hurt.attack_type = 1
            end
            local cattack = 0
            if mrandom(1000) < zhaojia then
            -- 招架，产生反击
                att_value = 0
                local cbaoji = tag.baoji - role.xiaojian
                --cattack = mfloor(tag.att / (1 + (role.def*0.15 - 88) * 0.0075))
                cattack = mfloor((tag.att - role.def / role.df) * (1 - role.rdef/100))
                if cattack < 1 then cattack = 1 end
                if mrandom(1000) < cbaoji then
                    -- 反击是暴击
                    cattack = cattack * 2
                    hurt.counter_type = 1
                end
                hurt.counter_attack = cattack
            end
            tinsert(hurt.attack, att_value)
            
            shurt = shurt + tag:reduce_hp(att_value)
            if tag.hp == 0 and tag.yuan_skill then
                tag.yuan_skill.stop = true
            end
            if cattack > 0 then
                rehurt = rehurt + role:reduce_hp(cattack)
                if role.hp == 0 and role.yuan_skill then
                    role.yuan_skill.stop = true
                end
            end
        end
    end
    return normal, shurt, rehurt
end

function Skill:skill_hit(role, posi_list, follow_skill_id, prehurt, base_att2, level2)
    local shurt = 0
    local rehurt = 0
    local hurt_list = {}
    
    local selfskill = nil
    
    if follow_skill_id then
        selfskill = Skill:new(follow_skill_id, level2)
        --读后续技能配置
        Skill:get_conf(base_att2, selfskill)
        --printtab(selfskill, "skill_hit ext:")
    else
        selfskill = self
    end

    assert(selfskill)
    
    local skill_info ={
        skill_id = selfskill.id,
        hurt_list = hurt_list,
    }
    
    local att_value = selfskill.att_value
    local att_value_list = selfskill.att_value_list
    local skill_type = selfskill.type
    local tags, livenum = get_tag(posi_list, role.posi, skill_type)
    
    if selfskill.lock then --强制攻击某人
        local find = false
        for k,v in ipairs(tags) do
            if v.posi == selfskill.lock then
                find = true
            end
        end
        if not find then
            tags[1] = posi_list[selfskill.lock]
        end
        selfskill.lock = nil
    end
    for k,v in ipairs(tags) do
        assert(v)
        local tag = v
        local attack = {}
        local hurt = {
            posi = tag.posi - 1,
            attack = attack,
            attack_type = 0,
        }
        tinsert(hurt_list, hurt)
        local att_v = 0
        local tag_def = tag.def
        local tag_att = tag.att
        local att_v = 0
        if skill_type == 5 or skill_type == 6 or skill_type == 11 or skill_type == 12 or skill_type == 14 or skill_type == 16 then
            att_v = att_value 
        else
            if selfskill.f_att ~= 0 then -- 强制伤害
                att_v = selfskill.f_att
                local baoji = role.jibao - tag.xiaojian
                if mrandom(1000) < baoji then
                    -- 暴击
                    hurt.attack_type = 1
                end
            elseif not selfskill.force_att then
                --print(att_value, tag_def, tag.rdef)
                att_v = mfloor((att_value - tag_def / tag.df) * (1 - tag.rdef/100))
                local baoji = role.jibao - tag.xiaojian
                if mrandom(1000) < baoji then
                    -- 暴击
                    att_v = 2 * att_v
                    hurt.attack_type = 1
                end
            else
                att_v = selfskill.force_att
            end
            
        end
        local att_v_r = 0
        local buff_type = 0
        if skill_type == 12 or skill_type == 14 then -- 加buff的
            if skill_type == 12 then buff_type = 1
            else buff_type = 2 end
            hurt.buff = buff_type
        elseif skill_type ~= 16 and skill_type ~= 17 then
            for k,v in ipairs(att_value_list) do
                local val = mfloor(v * att_v)
                if val < 1 then val = 1 end
                tinsert(attack, val)
                att_v_r = att_v_r + val
                if skill_type == 15 and buff_type == 0 then -- 增加眩晕效果
                    local t = math.random(1000)
                    if t <= selfskill.buff then
                        buff_type = 3
                    end
                end
            end
        end
        if buff_type ~= 0 then
            local buff_count = 2
            --if buff_type == 1 then buff_count = 3 end
            local buff = {
                count = buff_count,
                type = buff_type,--1=防御，2=攻击
                value = att_value,
            }
            local buff_list = rawget(tag, "buff_list")
            if not buff_list then
                buff_list = {}
                rawset(tag,"buff_list", buff_list)
            end
            tinsert(buff_list, buff)
            if buff_type == 1 then
                tag.def = tag_def + att_value
                tag:reflesh_def(tag.def)
            elseif buff_type == 2 then
                tag.att = tag_att + att_value
                local tag_skill = tag.skill
                if tag_skill then tag_skill:fix_att(tag.att) end
                if tag.yuan_skill then
                    tag.yuan_skill.base_att = tag.yuan_skill.base_att + att_value
                    tag.yuan_skill:fix_att(tag.yuan_skill.base_att)
                end
            end
        elseif skill_type == 5 or skill_type == 6 or skill_type == 11 then
            tag:add_hp(att_v_r)
        elseif skill_type == 16 then --单体回复伤害百分比
            local percent = selfskill.damage + selfskill.damage1
            print("type16:", percent, prehurt, math.floor(percent*prehurt))
            --tag:add_hp(math.floor(percent*prehurt))     
            tinsert(attack, math.floor(percent*prehurt))
        elseif skill_type == 17 and livenum > 0 then --群体回复伤害百分比
            local percent = selfskill.damage + selfskill.damage1
            local addhp = math.floor(percent*prehurt/livenum)
            --print("type17:", prehurt, livenum, addhp)
            tag:add_hp(addhp)
            tinsert(attack, addhp)
        else
            shurt = shurt + tag:reduce_hp(att_v_r)
            if tag.hp == 0 and tag.yuan_skill then
                tag.yuan_skill.stop = true
            end
        end
    end
    selfskill.force_att = nil
    local skill_info2 = nil
    local shurt2 = 0
    local rehurt2 = 0
    --后续技能,只能接一个,接多个最好改成数组
    if not follow_skill_id and selfskill.conf.FOLLOW_SKILL and selfskill.conf.FOLLOW_SKILL > 0 then
        skill_info2, shurt2, rehurt2 = Skill:skill_hit(role, posi_list, selfskill.conf.FOLLOW_SKILL, shurt, self.base_att, self.level)
    end
    return skill_info, shurt, rehurt, skill_info2, shurt2, rehurt2
end

return Skill