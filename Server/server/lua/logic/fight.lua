local Knight = require "fight_knight"
local Leader = require "fight_leader"
local Monster = require "fight_monster"
local Skill = require "fight_skill"
local core_user = require "core_user_funcs"

local tinsert = table.insert
local tremove = table.remove
local tsort = table.sort
local sformat = string.format
local ipairs = ipairs
local rawset = rawset
local rawget = rawget
local assert = assert
local error = error
local setmetatable = setmetatable

local Stage_conf = Stage_conf
local Fortress_conf = Fortress_conf

--[[
    round_id : 当前回合，从1开始
    posi ： 当前攻击者站位
    act_status : 当前行动状态。0=回合开始，1=人物准备行动，2-人物行动结束
    event_id : 当前事件id
    winner : 胜利者
    start_talk: 开始和结束时的对话
    end_talk:
    Fight的子table有：
        role_list:用于计算的人物列表，包含初始人物和中途参战人物，且已经按照出手顺序排序
            ,因为是从下标1开始连续索引，所以其实是array，有性能优化，可以随机访问
        posi_list:始终是1-7，101-107，如果对应位置没有人则为nil，如果换了人，这里也要换人
            ,这个列表用来方便的索引被攻击者
        rcd:战斗实况记录器，最终被序列化为protobuf流
        yuan_skill_list:缘技能表。因为缘技能的数值是基于多个人的，所以用一个专门的地方统一处理
]]

local Fight = {}
Fight.__index = Fight

local EVENT_NOTHING = 0
local EVENT_NEXT = 1  -- 战斗没有结束，继续
local EVENT_STOP = 2  -- 战斗结束，终止循环
local EVENT_NEWROUND = 3 -- 有人加入或退出战斗，role_list改变，必须重新循环

function Fight:new()
    local self = {
        round_limit = 30,
        always_win = false,
        round_id = 0,
        posi = 0,
        act_status = 0,
        event_id = 0,
        winner = -1,
        role_list = {},
        posi_list = {},
        rcd = {
            preview = {
                winner = 0,
                role_list = {},

				stat_info = {
					total_damage = {},
				},
            },
            round_list = {},
        },
        yuan_skill_list = {},
        hurt = {0,0},
        start_talk = nil,
        end_talk = nil,
    }
    setmetatable(self, Fight)
    return self
end

function Fight:calc_team_raise(user_data, lover_skill_list)
    -- 计算团队加成
    local team_raise = {att = 0, def = 0, hp = 0, speed = 0,
        add_mingzhong = 0, add_huibi = 0,
        add_baoji = 0, add_xiaojian = 0, 
        add_zhaojia = 0, add_jibao = 0
    }
    --1，侠侣
    for _,v in ipairs(user_data.lover_list) do
        local conf = Lovers_conf[v.id]
        assert(conf, "lover conf not find")
        team_raise.att = team_raise.att + conf.TEAM_ATTACK_RAISE
        team_raise.def = team_raise.def + conf.TEAM_DEFENSE_RAISE
        team_raise.hp = team_raise.hp + conf.TEAM_LIFE_RAISE
        team_raise.speed = team_raise.speed + conf.TEAM_SPEED_RAISE
        if conf.SKILL_ID ~= 0 then
            local skill = Skill:new(conf.SKILL_ID, conf.LOVERS_LEVEL)--目前侠侣技能等级等于侠侣等级
            tinsert(lover_skill_list, skill)
        end
    end
    --2，巨著
    for _,v in ipairs(user_data.book_list) do
        local book_id = 80000000 + v.id * 10000 + v.level
        local conf = Book_conf[book_id]
        assert(conf, "book conf not find")
        team_raise.att = team_raise.att + conf.TEAM_ATTACK_RAISE
        team_raise.def = team_raise.def + conf.TEAM_DEFENSE_RAISE
        team_raise.hp = team_raise.hp + conf.TEAM_LIFE_RAISE
        team_raise.speed = team_raise.speed + conf.TEAM_SPEED_RAISE
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
            team_raise.speed = team_raise.speed + conf.TEAM_SPEED_RAISE
            break
        end
    end
    --4，武学极意
    -- 主角的武学极意加的都是一级属性
    local wxjy = user_data.wxjy
    if wxjy[2] > 0 then
        local conf_a = Extreme_conf[wxjy[2]].ATTACK
        if conf_a > 0 then
            team_raise.att = team_raise.att + conf_a
        end
    end
    if wxjy[3] > 0 then
        local conf_d = Extreme_conf[wxjy[3]].DEFENSE
        if conf_d > 0 then
            team_raise.def = team_raise.def + conf_d
        end
    end
    if wxjy[1] > 0 then
        local conf_h = Extreme_conf[wxjy[1]].LIFE
        if conf_h > 0 then
            team_raise.hp = team_raise.hp + conf_h
        end
    end
    if wxjy[4] > 0 then
        local conf_s = Extreme_conf[wxjy[4]].SPEED
        if conf_s > 0 then
            team_raise.speed = team_raise.speed + conf_s
        end
    end
    if wxjy[5] and wxjy[5] > 0 then
        local conf_h = Extreme_conf[wxjy[5]].HIT
        if conf_h > 0 then
            team_raise.add_mingzhong = team_raise.add_mingzhong + conf_h
        end
    end
    if wxjy[6] and wxjy[6] > 0 then
        local conf_d = Extreme_conf[wxjy[6]].DODGE
        if conf_d > 0 then
            team_raise.add_huibi = team_raise.add_huibi + conf_d
        end
    end
    if wxjy[7] and wxjy[7] > 0 then
        local conf_c = Extreme_conf[wxjy[7]].CRIT
        if conf_c > 0 then
            team_raise.add_baoji = team_raise.add_baoji + conf_c
        end
    end
    if wxjy[8] and wxjy[8] > 0 then
        local conf_s = Extreme_conf[wxjy[8]].SKILL_CRIT
        if conf_s > 0 then
            team_raise.add_jibao = team_raise.add_jibao + conf_s
        end
    end
    if wxjy[9] and wxjy[9] > 0 then
        local conf_ac = Extreme_conf[wxjy[9]].ANTICRIT
        if conf_ac > 0 then
            team_raise.add_xiaojian = team_raise.add_xiaojian + conf_ac
        end
    end
    -- 门派绝学
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
            if wxjy[4] > 0 then
                local conf_s = Men_Extreme_conf[wxjy[4]].SPEED
                if conf_s > 0 then
                    team_raise.speed = team_raise.speed + conf_s
                end
            end
            if wxjy[5] and wxjy[5] > 0 then
                local conf_h = Men_Extreme_conf[wxjy[5]].HIT
                if conf_h > 0 then
                    team_raise.add_mingzhong = team_raise.add_mingzhong + conf_h
                end
            end
            if wxjy[6] and wxjy[6] > 0 then
                local conf_d = Men_Extreme_conf[wxjy[6]].DODGE
                if conf_d > 0 then
                    team_raise.add_huibi = team_raise.add_huibi + conf_d
                end
            end
            if wxjy[7] and wxjy[7] > 0 then
                local conf_c = Men_Extreme_conf[wxjy[7]].CRIT
                if conf_c > 0 then
                    team_raise.add_baoji = team_raise.add_baoji + conf_c
                end
            end
            if wxjy[8] and wxjy[8] > 0 then
                local conf_s = Men_Extreme_conf[wxjy[8]].SKILL_CRIT
                if conf_s > 0 then
                    team_raise.add_jibao = team_raise.add_jibao + conf_s
                end
            end
            if wxjy[9] and wxjy[9] > 0 then
                local conf_ac = Men_Extreme_conf[wxjy[9]].ANTICRIT
                if conf_ac > 0 then
                    team_raise.add_xiaojian = team_raise.add_xiaojian + conf_ac
                end
            end
        end
    end
    return team_raise
end


-- 从用户数据填充p1列表
function Fight:get_player_data(user_data, knight_list, is_p2, p1_hook)
    local player_role_list = self.role_list
    local posi_list = self.posi_list
    local posi_offset = 0
    local lover_skill_list = {}
    local jiban_list = {}
    -- 计算团队加成
    local team_raise = self:calc_team_raise(user_data, lover_skill_list)
    
    if is_p2 then posi_offset = 100 end
    local zhanwei_list = user_data.zhenxing.zhanwei_list
    if p1_hook then
        zhanwei_list = clonetab(zhanwei_list)
        zhanwei_list = {
                {status = 3, t = 49990016},
                {status = 3, t = 49990017},
                {status = 3, t = 49990018},
                {status = 3, t = 49990019},
                {status = 1},
                {status = 3, t = 49990020},
                {status = 3, t = 49990021},
            }
    end
    for k,v in ipairs(zhanwei_list) do
        if v.status ~= 0 then
            local role = {}
            local sevenweapon = nil
            if rawget(user_data, "sevenweapon") and user_data.sevenweapon[k] then
                sevenweapon = {att = 0, def = 0, hp = 0}
                local level = user_data.sevenweapon[k].level
                if level > 0 then
                    local conf = Seven_Weapon_conf[level]
                    assert(conf)
                    sevenweapon.att = conf.Add_ATK
                    sevenweapon.def = conf.Add_DEF
                    sevenweapon.hp = conf.Add_HP
                end
            end
            if v.status == 1 then
                --这是主将
                role = Leader:new(user_data, k + posi_offset)
                role.knight = user_data.lead
                role.team_raise = team_raise
                if sevenweapon then
                    role.sevenweapon = sevenweapon
                end
                if #lover_skill_list then
                    role.lover_skill_list = lover_skill_list
                end
            elseif v.status == 2 then
                --这是侠客
                role = Knight:new(v.knight, k + posi_offset)
                role.knight = v.knight
                role.team_raise = team_raise
                if sevenweapon then
                    role.sevenweapon = sevenweapon
                end
                local t = v.knight.data.level
                local jiban_list = rawget(v.knight.data, "jiban_list")
                if jiban_list then
                    for k1,v1 in ipairs(jiban_list) do
                        if v1 >= 0 then
                            local t = core_user.get_knight_from_bag_by_guid(v1, knight_list)
                            assert(t[2])
                            local t_posi = 1000 + k * 100 + k1
                            if is_p2 then
                                t_posi = t_posi + 1000
                            end
                            local t_role = Knight:new(t[2], t_posi)
                            t_role.knight = t[2]
                            t_role.team_raise = team_raise
                            rawset(posi_list, t_posi, t_role)
                        end
                    end
                end
            elseif v.status == 3 then
                -- 刷出的npc不需要计算各种属性加成
                role = Monster:new(v.t, k)
            end
            tinsert(player_role_list, role)
            rawset(posi_list, k + posi_offset, role)
        end
    end
    self:check_yuan_lover(user_data, is_p2)
end

-- 获取review
function Fight:get_preview_role_list()
    local role_list = self.rcd.preview.role_list
    for k,v in ipairs(self.role_list) do
        tinsert(role_list, v:get_preview())
    end
end

-- 计算最终属性
function Fight:get_attrib()
    for k,v in ipairs(self.role_list) do
        local jiban_list = {}
        local posi = v.posi
        if (posi >= 1 and posi <= 7) or (posi >= 101 and posi <= 107) then
            for k1 = 1, 10 do
                local tt_posi = posi
                if tt_posi > 100 then tt_posi = tt_posi - 100 end
                local t_posi = 1000 + tt_posi * 100 + k1
                if posi > 100 then t_posi = t_posi + 1000 end
                local t_role = rawget(self.posi_list, t_posi)
                if t_role then
                    t_role:get_attrib()
                    table.insert(jiban_list, t_role)
                else
                    break
                end
            end
        end
        v:get_attrib(jiban_list) --查表获取一级属性并计算二级属性
    end
    -- 在这里统一处理缘技能
    for _,v in ipairs(self.yuan_skill_list) do
        v:get_conf(v.base_att)
    end
end

local function sort_by_speed(a, b)
    if a.speed == b.speed then
        return a.posi < b.posi
    else
        return a.speed > b.speed
    end
end

-- 每个回合初进行一次的刷新操作
function Fight:refresh_by_one_round()
    for k,v in ipairs(self.role_list) do
        v.relive = false    -- 复活标志。有这个标志的玩家本回合不能出手
    end
end

-- posi1的人强制杀死posi2的人
function Fight:force_kill(posi1, posi2)
    assert(self.posi_list[posi1])
    assert(self.posi_list[posi2])
    local tag = self.posi_list[posi2]
    local action = {
        attack = {
            posi = posi1 - 1,
            normal = {
                skill_id = 0,
                hurt_list = {
                    {
                        posi = posi2 - 1,
                        attack = {
                            tag.hp
                        },
                        attack_type = 3,    --强制杀死
                    }
                },
            },
        },
    }
    tag.hp = 0
    return action
end

--有人中途加入
function Fight:find_posi(group)
    local offset = 0
    if group == 2 then offset = 100
    else assert(group == 1) end
    local beginp = offset + 1
    local endp = offset + 7
    local posi_list = self.posi_list
    local firstk = 0
    for k = beginp,endp do
        local t = rawget(posi_list, k)
        if t == nil then return k
        elseif firstk == 0 and t:type_i() == 2 then
            firstk = k
        end
    end
    return firstk
end

function Fight:find_posi13(group, posi13)
    local offset = 0
    if group == 2 then offset = 100
    else assert(group == 1) end
    assert(posi13 == 1 or posi13 == 3)
    local posi = offset + posi13
    local posi_list = self.posi_list
    local t = rawget(posi_list, posi)
    if t == nil then return posi
    else
        if t:type_i() == 1 then
            return offset+2
        else
            return posi
        end
    end
end

function Fight:join(params, event_id)
    local e_data = {}
    local preview = self.rcd.preview.role_list
    local role_list = self.role_list
    local posi_list = self.posi_list
    local action = {
        event ={
            type = "APPEAR",
            data = e_data,
        }
    }
    
    for _,v in ipairs(params) do
        local role_id = v[1]
        local posi = v[2]
        local role = v[4]
        assert(posi_list[posi] == nil, sformat("posi %d has role",posi))
        if role == nil then
            role = Monster:new(role_id, posi,1, v[3])
            role:get_attrib()
        else
            role.posi = posi
        end
        local role_preview = role:get_preview()
        role_preview.posi = role_preview.posi + event_id * 1000
        tinsert(preview, role_preview)
        tinsert(role_list, role)
        rawset(posi_list, posi, role)
        tinsert(e_data, role_preview.posi)
    end
    tsort(role_list, sort_by_speed)
    return action
end

--叛逃
function Fight:defect(posi1, posi2)
    assert(self.posi_list[posi2] == nil and self.posi_list[posi1])
    local role = self.posi_list[posi1]
    rawset(self.posi_list, posi2, role)
    rawset(self.posi_list, posi1, nil)
    role.posi = posi2
    self.posi = posi2
    --Npc叛逃到己方后本来id需要更换为Character id，用来检测缘。
    --但是现在不考虑中途叛逃后的缘属性变化，缘技能特别处理(写死)，所以没必要修改
    --self.posi_list[posi2].info.id = Npc_conf[self.posi_list[posi2].info.id].IMAGE_ID
    local action = {
        event = {
            type = "DEFECT",
            data = {posi1 - 1, posi2 - 1},
        },
    }
    return action
end

--中途退场
function Fight:exit(posis)
    local e_data = {}
    local action = {
        event ={
            type = "DISAPPEAR",
            data = e_data,
        }
    }
    local ret = false
    local role_list = self.role_list
    local posi_list = self.posi_list
    for _,posi in ipairs(posis) do
        assert(self.posi_list[posi], sformat("posi %d not has role",posi))
        for k,v in ipairs(role_list) do
            if v.posi == posi then
                tremove(role_list, k)
                posi_list[posi] = nil
                tinsert(e_data, posi - 1)
                break
            end
        end
    end
    --self:check_yuan(0)
    return action
end

--复活
function Fight:relive(posi)
    local role = self.posi_list[posi]
    assert(role and role.hp == 0)
    role.hp = role.max_hp
    role.relive = true
    local action = {
        event = {
            type = "RELIVE",
            data = {posi - 1},
        },
    }
    return action
end

--剧情对话
function Fight:talk(talk_id)
    local action = {
        event = {
            type = "TALK",
            data = {talk_id},
        },
    }
    return action
end

--自动按照规则加入一个人
function Fight:auto_join(params, event_id, action_list)
    local posi_list = self.posi_list
    local lead_role = nil
    local exit_list = {}
    local temp_list = {}
    
    for k = 1, 7 do
        local role = posi_list[k]
        if role then
            tinsert(temp_list, {role, role.id, role:type_i(), k, 0})
        else
            tinsert(temp_list, {nil, 0, 0, 0, 0})
        end
    end
    for _,v in ipairs(params) do
        local nid = v[1]
        local nconf = Npc_conf[nid]
        local cid = nconf.IMAGE_ID
        local d_posi = v[2] --侠客出现的目标位置
        local t_posi = 0    --如果已有侠客，则是侠客目前位置
        for k1,v1 in ipairs(temp_list) do
            if v1[2] == cid then -- 找到相同侠客
                t_posi = k1 --获取这个侠客的位置
                break
            end
        end
        if t_posi ~= 0 then -- 没有侠客
            local d = temp_list[d_posi]
            local t = temp_list[t_posi]
            temp_list[d_posi] = t
            temp_list[t_posi] = d
        elseif temp_list[d_posi][3] == 1 then
            local t = temp_list[2]
            local d = temp_list[d_posi]
            temp_list[d_posi] = t
            temp_list[2] = d
            d[5] = 1000
        end
    end
    for k,v in ipairs(temp_list) do
        if v[3] == 1 then
            if v[4] ~= k then
                --主将受到影响，要替换
                local d = temp_list[2]
                local t = temp_list[k]
                temp_list[2] = t
                temp_list[k] = d
            end
            break
        end
    end
    for k,v in ipairs(params) do
        local t = v[2]
        if temp_list[t][1] then
            temp_list[t][5] = 100--要删掉
        end
    end
    local need_exit = {0,0,0,0,0,0,0}
    for k,v in ipairs(temp_list) do
        if v[5] == 100 then need_exit[k] = 1 end--这个位置被占用，肯定要移除
        if v[1] and v[4] ~= k then
            need_exit[k] = 1
            need_exit[v[4]] = 1
            if v[5] ~= 100 and v[2] < 19999999 then
                tinsert(params, {0, k, 0, v[1]})
            end
        end
    end
    for k,v in ipairs(need_exit) do
        if v == 1 and posi_list[k] then tinsert(exit_list, k) end
    end
    
    local event
    if rawlen(exit_list) > 0 then
        event = self:exit(exit_list)
        --event.event.more = 1
        tinsert(action_list, event)
    end
    --[[
    if lead_role then
        tinsert(params, {0,2,0,lead_role})
    end
    ]]
    event = self:join(params, event_id)
    tinsert(action_list, event)
end

function Fight:get_lead()
    for _,v in ipairs(self.role_list) do
        if v:type_i() == 1 then return v end
    end
    return nil
end

local function is_stage(stage_id, event_id)
    if stage_id < 60000000 then
        local env = (math.floor((stage_id - 50000000)/100)  + stage_id % 100) * 100
        if event_id < env + 100 and event_id >= env then return true
        else return false end
    else
        local env = (math.floor((stage_id - 400000000)/100)  + stage_id % 100) * 100 + 2000000
        if event_id < env + 100 and event_id >= env then return true
        else return false end
    end
end

function Fight:is_round(id)
    if self.act_status == 0 and self.round_id == id then return true
    else return false end
end

local event_yuan_list = {
    {50340004,{{105,106,110740001}}},
    {50340010,{{106,107,110740001}}},
    {50350005,{{102,105,110700001}}},
    {50350007,{{105,106,110340001}}},
    {50350010,{{105,106,110340001}}},
    {50360010,{{105,106,110720001}}},
    {50370007,{{102,106,110700001}}},
    {50370010,{{103,105,110700001}}},
    {50380004,{{102,103,110730001}}},
    {50380010,{{105,106,110690001}}},
    {50390010,{{104,107,110340001}}},
    {50400010,{{103,105,110320001}}},
    {50410003,{{105,106,110720001}}},
    {50410006,{{106,107,110690001}}},
    {50410010,{{105,107,110720001}}},
    {50420003,{{102,105,110700001}}},
    {50420006,{{104,107,110740001}}},
    {50420010,{{103,105,110700001}}},
    {50430003,{{106,107,110690001}}},
    {50430006,{{106,107,110720001}}},
    {50440006,{{102,103,110730001}}},
    {50440010,{{105,106,110690001}}},
    {50450004,{{103,105,110700001}}},
    {50450010,{{105,106,110340001}}},
    {50460004,{{102,105,110670001}}},
    {50460007,{{105,106,110690001}}},
    {50460010,{{103,106,110670001}}},
    {50470006,{{105,106,110740001}}},
    {50470010,{{102,105,110700001}}},
    {50480002,{{102,105,110320001}}},
    {50480004,{{103,106,110680001}}},
    {50480006,{{102,106,110320001}}},
    {50480010,{{101,104,110680001},{102,107,110670001},{103,106,110320001}}},
    
    {400340004,{{105,106,110740001}}},
    {400340010,{{106,107,110740001}}},
    {400350005,{{102,105,110700001}}},
    {400350007,{{105,106,110340001}}},
    {400350010,{{105,106,110340001}}},
    {400360010,{{105,106,110720001}}},
    {400370007,{{102,106,110700001}}},
    {400370010,{{103,105,110700001}}},
    {400380004,{{102,103,110730001}}},
    {400380010,{{105,106,110690001}}},
    {400390010,{{104,107,110340001}}},
    {400400010,{{103,105,110320001}}},
    {400410003,{{105,106,110720001}}},
    {400410006,{{106,107,110690001}}},
    {400410010,{{105,107,110720001}}},
    {400420003,{{102,105,110700001}}},
    {400420006,{{104,107,110740001}}},
    {400420010,{{103,105,110700001}}},
    {400430003,{{106,107,110690001}}},
    {400430006,{{106,107,110720001}}},
    {400440006,{{102,103,110730001}}},
    {400440010,{{105,106,110690001}}},
    {400450004,{{103,105,110700001}}},
    {400450010,{{105,106,110340001}}},
    {400460004,{{102,105,110670001}}},
    {400460007,{{105,106,110690001}}},
    {400460010,{{103,106,110670001}}},
    {400470006,{{105,106,110740001}}},
    {400470010,{{102,105,110700001}}},
    {400480002,{{102,105,110320001}}},
    {400480004,{{103,106,110680001}}},
    {400480006,{{102,106,110320001}}},
    {400480010,{{101,104,110680001},{102,107,110670001},{103,106,110320001}}},
}
local function check_event_yuan(event_id, fight)
    local ret = EVENT_NOTHING
    for k,v in ipairs(event_yuan_list) do
        if is_stage(v[1], event_id) then
            if fight:is_round(1) then
                for k1,v1 in ipairs(v[2]) do
                    local r1 = fight.posi_list[v1[1]]
                    local r2 = fight.posi_list[v1[2]]
                    local att = r1.att + r2.att
                    local yuan_skill = Skill:new(v1[3], 1)
                    yuan_skill:get_conf(att)
                    r1.yuan_skill = yuan_skill
                    r2.yuan_skill = yuan_skill
                end
                ret = EVENT_NEWROUND
            end
            break
        end
    end
    return ret
end




function Fight:check_event(action_list)
    local ret = EVENT_NOTHING
    local event_id = self.event_id
    if event_id == 0 then return ret end
    --[[第一关的特殊表演
    if is_stage(50010003, event_id) then
        if self:is_round(1) then
            local role = self:get_lead()
            assert(role)
            role.def = 2000
            role.att = 5500
            role.hp = 30000
            role.max_hp = 30000
            role.speed = 98
            role.skill.probably = 1000
            local role_list = self.rcd.preview.role_list
            for k,v in ipairs(role_list) do
                if v.posi == 4 then
                    v.max_hp = 30000
                    v.comming_hp = 30000
                end
            end
            local role1 = rawget(self.posi_list, 1)
            local role2 = rawget(self.posi_list, 2)
            local role3 = rawget(self.posi_list, 3)
            local role4 = rawget(self.posi_list, 4)
            local role6 = rawget(self.posi_list, 6)
            local role7 = rawget(self.posi_list, 7)
            local role101 = rawget(self.posi_list, 101)
            local role102 = rawget(self.posi_list, 102)
            local role103 = rawget(self.posi_list, 103)
            local role104 = rawget(self.posi_list, 104)
            local role105 = rawget(self.posi_list, 105)
            local role106 = rawget(self.posi_list, 106)
            local role107 = rawget(self.posi_list, 107)
            
            local att = role6.att + role2.att
            local yuan_skill = Skill:new(110680001, 1)
            yuan_skill:get_conf(att)
            yuan_skill.probably = 1000
            role6.yuan_skill = yuan_skill
            
            local att = role105.att + role106.att
            local yuan_skill = Skill:new(110740001, 1)
            yuan_skill:get_conf(att)
            yuan_skill.probably = 1000
            role106.yuan_skill = yuan_skill
            
            role107.skill.probably = 1000
            
            local att = role7.att + role3.att
            local yuan_skill = Skill:new(110670001, 1)
            yuan_skill:get_conf(att)
            yuan_skill.probably = 1000
            role7.yuan_skill = yuan_skill
            
            local lover_skill = Skill:new(110750001, 1)
            lover_skill:get_conf(role7.att)
            lover_skill.probably = 1000
            local lover_skill_list = {lover_skill}
            role7.lover_skill_list = lover_skill_list
            role7.lover_skill_count = 2
            
            local att = role102.att + role103.att
            local yuan_skill = Skill:new(110730001, 1)
            yuan_skill:get_conf(att)
            yuan_skill.probably = 1000
            role102.yuan_skill = yuan_skill
            
            local att = role1.att + role4.att
            local yuan_skill = Skill:new(110310001, 1)
            yuan_skill:get_conf(att)
            yuan_skill.probably = 1000
            role1.yuan_skill = yuan_skill
            
            local lover_skill = Skill:new(110360001, 1)
            lover_skill:get_conf(3000)
            lover_skill.probably = 1000
            lover_skill.att_value = 3000
            local lover_skill_list = {lover_skill}
            role104.lover_skill_list = lover_skill_list
            role104.lover_skill_count = 2
            
            local att = role101.att + role104.att
            local yuan_skill = Skill:new(110320001, 1)
            yuan_skill:get_conf(att)
            yuan_skill.probably = 1000
            role104.yuan_skill = yuan_skill
            
            tsort(self.role_list, sort_by_speed)
            ret = EVENT_NEWROUND
        elseif event_id == 10301 and self.posi == 107 and self.act_status == 2 then
            local event = self:talk(174591186)
            tinsert(action_list, event)
            ret = EVENT_NEXT
        elseif event_id == 10302 and self.posi == 1 and self.act_status == 2 then
            local event = self:talk(174601187)
            tinsert(action_list, event)
            ret = EVENT_NEXT
        elseif event_id == 10303 and self.posi == 104 and self.act_status == 2 then
            self.winner = 1
            ret = EVENT_STOP
        end
        ]]
    
    if is_stage(50010003, event_id) then
        if self:is_round(2) then
            if rawget(self.posi_list, 5) then
                local event = self:exit{5}
                tinsert(action_list, event)
            end
            local event = self:defect(2,5)
            tinsert(action_list, event)
            event = self:join({{40010004, 2}}, event_id)
            tinsert(action_list, event)
            event = self:talk(174541171)
            tinsert(action_list, event)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50010005, event_id) then
        if self.winner == 1 and event_id == 10500 then
            local event = self:exit{102}
            tinsert(action_list, event)
            event = self:join({{40010006, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(174621189)
            tinsert(action_list, event)
            self.winner = 0
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50010008, event_id) then
        if self:is_round(1) then
            local event = self:talk(174691204)
            tinsert(action_list, event)
            event = self:exit{102}
            tinsert(action_list, event)
            event = self:join({{40010009, 102, 1}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50020002, event_id) then
        if self:is_round(1) and self.act_status == 0 then
            for k = 1,7 do
                local role = self.posi_list[k]
                if role then role.skill.probably = 0 end
            end
            for k = 101,107 do
                local role = self.posi_list[k]
                if role then role.skill.probably = 0 end
            end
            ret = EVENT_NEWROUND
        elseif self.round_id == 1 and self.posi == 102 and self.act_status == 2 then
            local role = self.posi_list[102]
            if role then
                role.skill.probably = 1000
                role.skill.att_value = 200
                ret = EVENT_NEXT
            end
        elseif self.round_id == 2 and self.posi == 102 and self.act_status == 2 then
            local role = self.posi_list[102]
            if role then
                role.skill.probably = 0
                ret = EVENT_NEXT
            end
        elseif event_id == 20203 then
            local role = self.posi_list[2]
            if role and role.hp == 0 then
                local event = self:talk(174851237)
                tinsert(action_list, event)
                ret = EVENT_NEXT
            else
                ret = EVENT_NOTHING
            end
        end
    elseif is_stage(50170002, event_id) then
        if self:is_round(1) then
            self:auto_join({{40170002, 3}, {40170004, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50170004, event_id) then
        if self:is_round(1) then
            local role = self.posi_list[102]
            role.skill.probably = 1000
            ret = EVENT_NEXT
        elseif self:is_round(3) then
            self:auto_join({{40170019, 1}}, event_id, action_list)
            self.winner = 1
            ret = EVENT_STOP
        end
    elseif is_stage(50170006, event_id) then
        if self:is_round(1) then
            local role = self.posi_list[102]
            role.skill.probably = 1000
            ret = EVENT_NEXT
        elseif self.winner == 0 and event_id == 170601 then
            self:auto_join({{40170017, 1}}, event_id, action_list)
            local role = self.posi_list[102]
            role.skill.probably = 0
            role = self.posi_list[1]
            role.skill.probably = 1000
            local event = self:talk(174991259)
            tinsert(action_list, event)
            self.round_limit = self.round_id + 2
            self.always_win = true
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50170010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40170004, 1}, {40170007, 3}, {40170015, 4}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50180001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40180001, 1}, {40180002, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50180010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40180001, 1}, {40180002, 3}, {40180010, 4}}, event_id, action_list)
            local role1 = self.posi_list[1]
            local role3 = self.posi_list[3]
            local yuan_skill = Skill:new(110730001, 1)
            yuan_skill:get_conf(role1.att + role3.att)
            role1.yuan_skill = yuan_skill
            role3.yuan_skill = yuan_skill
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50190001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40190001, 1}, {40190002, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50190010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40190001, 1}, {40190002, 3}}, event_id, action_list)
            local role = self.posi_list[102]
            role.skill.probably = 1000
            ret = EVENT_NEWROUND
        elseif event_id == 191001 and self.posi_list[1].hp == 0 then
            local event = nil
            local need_exit = {}
            for k=1,7 do
                if self.posi_list[k] then table.insert(need_exit,k) end
            end
            event = self:exit(need_exit)
            tinsert(action_list,event)
            event = self:join({{40190015, 2}}, event_id)
            tinsert(action_list, event)
            event = self:talk(175011263)
            tinsert(action_list, event)
            local role = self.posi_list[2]
            role.skill.probably = 1000
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50030001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40030002, 4}, {40030001, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50030010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40030001, 3}, {40030002, 4}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50040002, event_id) then
        if self:is_round(1) then
            self:auto_join({{40040001, 3}, {40040002, 4}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif event_id == 40201 then
            local role = rawget(self.posi_list, 102)
            if role.hp == 0 then
                local event = self:exit({102})
                tinsert(action_list, event)
                event = self:join({{40040006, 102, 1}}, event_id)
                tinsert(action_list, event)
                event = self:talk(171270343)
                tinsert(action_list, event)
                ret = EVENT_NEXT
            end
        end
    elseif is_stage(50040010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40040001, 3}, {40040002, 4}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 41001 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40040016, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(171430388)
            tinsert(action_list, event)
            self.winner = 0
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50200001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40200001, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50200010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40200011, 1}, {40200001, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50050001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40050001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50060001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40060001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50060006, event_id) then
        if self.winner == 1 and event_id == 60600 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40060010, 101, 1},{40060010, 103, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(171680460)
            tinsert(action_list, event)
            self.winner = -1
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 60601 then
            local event = self:exit({101, 103})
            tinsert(action_list, event)
            event = self:join({{40060010, 101, 1},{40060010, 102, 1},{40060010, 103, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(171690461)
            tinsert(action_list, event)
            self.winner = -1
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50060010, event_id) then
        if self:is_round(1) then
            local exit_list = {}
            local lead_posi = 0
            for k = 1, 7 do
                local role = self.posi_list[k]
                if role and role:type_i() == 2 then
                    tinsert(exit_list, k)
                elseif role and role:type_i() == 1 then
                    lead_posi = k
                end
            end
            if rawlen(exit_list) > 0 then
                local event = self:exit(exit_list)
                tinsert(action_list, event)
            end
            assert(lead_posi >= 1 and lead_posi <= 7)
            if lead_posi ~= 2 then
                local event = self:defect(lead_posi, 2)
                tinsert(action_list, event)
            end
            ret = EVENT_NEXT
        
        end
    elseif is_stage(50070001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40070001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50080002, event_id) then
        if self:is_round(1) then
            self:auto_join({{40080003, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50080007, event_id) then
        if self:is_round(1) then
            self:auto_join({{40080008, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif event_id == 80701 and self.posi_list[1].hp == 0 then
            local event = self:talk(171940512)
            tinsert(action_list, event)
            ret = EVENT_NEXT
        end
    elseif is_stage(50090003, event_id) then
        if self.winner == 1 and event_id == 90300 then
            local event = self:join({{40090005, 102, 1}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NOTHING
        end
    elseif is_stage(50090006, event_id) then
        if self:is_round(1) then
            self:auto_join({{40090005, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50090010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40090013, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50100002, event_id) then
        if self:is_round(1) then
            self:auto_join({{40100001, 1}, {40100003, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50100010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40100003, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50110003, event_id) then
        if self:is_round(1) then
            self:auto_join({{40110003, 1}, {40110004, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50110010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40110003, 1}, {40110004, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50120004, event_id) then
        if self:is_round(1) then
            self:auto_join({{40120002, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50120010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40120002, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50130003, event_id) then
        if self:is_round(1) then
            self:auto_join({{40130001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 130301 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40130004, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(172490647)
            tinsert(action_list, event)
            self.winner = -1
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50130010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40130001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50140005, event_id) then
        if self:is_round(1) then
            self:auto_join({{40140004, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif event_id == 140501 and self.posi_list[101].hp == 0
            and self.posi_list[102].hp == 0
            and self.posi_list[103].hp == 0 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40140006, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(172670695)
            tinsert(action_list, event)
            self.winner = -1
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50140010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40140004, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif event_id == 141001 and self.posi_list[101].hp == 0
            and self.posi_list[102].hp == 0
            and self.posi_list[103].hp == 0 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40140010, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(172730712)
            tinsert(action_list, event)
            self.winner = -1
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50150001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40150001, 1}, {40150002, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50150002, event_id) then
        if self:is_round(1) then
            self:auto_join({{40150001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 150201 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40150005, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(172780728)
            tinsert(action_list, event)
            self.winner = -1
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50150004, event_id) then
        if self:is_round(1) then
            self:auto_join({{40150001, 1}, {40150006, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50150010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40150001, 1}, {40150012, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif event_id == 151001 and self.posi_list[3].hp == 0 then
            local event = self:exit({3})
            tinsert(action_list, event)
            event = self:join({{40150006, 3}}, event_id)
            tinsert(action_list, event)
            event = self:talk(172860754)
            tinsert(action_list, event)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50160001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40160001, 1}, {40160002, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50160007, event_id) then
        if self:is_round(1) then
            self:auto_join({{40160009, 1}}, event_id, action_list)
            local role = self.posi_list[1]
            role.skill.probably = 1000
            role = self.posi_list[102]
            role.skill.probably = 1000
            role.skill.lock = 1     -- 下一次必打此人
            ret = EVENT_NEWROUND
        elseif event_id == 160701 and self.posi_list[1].hp == 0 then
            local event = self:talk(173991040)
            tinsert(action_list, event)
            event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40160003, 101},{40160003, 102},{40160003, 103},
                {40160003, 104},{40160003, 105},{40160003, 106},{40160003, 107}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50160010, event_id) then
        if self:is_round(2) then
            local event = self:exit({101})
            tinsert(action_list, event)
            event = self:join({{40160007, 101, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(174021048)
            tinsert(action_list, event)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50210003, event_id) then
        if self:is_round(1) then
            self:auto_join({{40210004, 1}, {40210005, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50210010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40210004, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50220001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40220001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50220010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40220001, 1}, {40220009, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 221001 then
            local event = self:exit({3, 102})
            tinsert(action_list, event)
            event = self:join({{40220010, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(174381130)
            tinsert(action_list, event)
            self.winner = -1
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50230001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40230001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50230007, event_id) then
        if self:is_round(1) then
            self:auto_join({{40230001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif self:is_round(2) then
            local event = self:talk(174451147)
            tinsert(action_list, event)
            event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40230009, 101, 1},
                {40230010, 102, 1}, {40230011, 103, 1}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50230010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40230001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif event_id == 231001 and self.posi_list[102].hp == 0 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40230013, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(174471151)
            tinsert(action_list, event)
            self.winner = -1
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50240001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40240001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50240010, event_id) then
        if self.winner == 1 and event_id == 241000 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40240001, 102}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NOTHING
        end
    elseif is_stage(50250001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40250001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50250010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40250001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 251001 then
            local event = self:exit({105})
            tinsert(action_list, event)
            event = self:join({{40250010, 105}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NOTHING
        end
    elseif is_stage(50260001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40260001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50260010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40260001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 261001 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40260012, 102}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NOTHING
        end
    elseif is_stage(50270010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40270001, 1}, {40270010, 3}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50280001, event_id) then
        if self:is_round(1) then
            self:auto_join({{40280001, 1}}, event_id, action_list)
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50280007, event_id) then
        if self:is_round(1) then
            self:auto_join({{40280010, 1}}, event_id, action_list)
            local role = self.posi_list[102]
            role.skill.probably = 1000
            ret = EVENT_NEWROUND
        elseif self:is_round(2) then
            local role = self.posi_list[102]
            role.skill.probably = 200
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 280702 then
            local event = self:exit({101})
            tinsert(action_list, event)
            event = self:join({{40280011, 101}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NOTHING
        end
    elseif is_stage(50280010, event_id) then
        if self:is_round(1) then
            self:auto_join({{40280001, 1}, {40280014, 3}}, event_id, action_list)
            local role1 = self.posi_list[1]
            local role3 = self.posi_list[3]
            
            local att = role1.att + role3.att
            local yuan_skill = Skill:new(110310001, 1)
            yuan_skill:get_conf(att)
            role1.yuan_skill = yuan_skill
            role3.yuan_skill = yuan_skill
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 281001 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40280013, 102}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NOTHING
        end
    elseif is_stage(50320002, event_id) then
        if self:is_round(1) then
            local role105 = self.posi_list[105]
            local role106 = self.posi_list[106]
            local att = role105.att + role106.att
            local yuan_skill = Skill:new(110700001, 1)
            yuan_skill:get_conf(att)
            role105.yuan_skill = yuan_skill
            role106.yuan_skill = yuan_skill
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50320006, event_id) then
        if self:is_round(1) then
            local role101 = self.posi_list[101]
            local role103 = self.posi_list[103]
            local att = role101.att + role103.att
            local yuan_skill = Skill:new(110730001, 1)
            yuan_skill:get_conf(att)
            role101.yuan_skill = yuan_skill
            role103.yuan_skill = yuan_skill
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50320010, event_id) then
        if self:is_round(1) then
            local role105 = self.posi_list[105]
            local role106 = self.posi_list[106]
            local att = role105.att + role106.att
            local yuan_skill = Skill:new(110670001, 1)
            yuan_skill:get_conf(att)
            role105.yuan_skill = yuan_skill
            role106.yuan_skill = yuan_skill
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 321001 then
            local event = self:exit({106})
            tinsert(action_list, event)
            event = self:join({{40320014, 106, 1}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NOTHING
        end
    elseif is_stage(50330008, event_id) then
        if self:is_round(1) then
            local role105 = self.posi_list[105]
            local role106 = self.posi_list[106]
            local att = role105.att + role106.att
            local yuan_skill = Skill:new(110310001, 1)
            yuan_skill:get_conf(att)
            role105.yuan_skill = yuan_skill
            role106.yuan_skill = yuan_skill
            ret = EVENT_NEWROUND
        end
    elseif is_stage(50330010, event_id) then
        if self:is_round(1) then
            local role102 = self.posi_list[102]
            local role105 = self.posi_list[105]
            local att = role102.att + role105.att
            local yuan_skill = Skill:new(110680001, 1)
            yuan_skill:get_conf(att)
            role102.yuan_skill = yuan_skill
            role105.yuan_skill = yuan_skill
            ret = EVENT_NEWROUND
        end
    else
        ret = check_event_yuan(event_id, self)
    end
    if ret ~= EVENT_NOTHING then
        self.event_id = event_id + 1
    end
    return ret
end

-- 每次攻击信息
function Fight:attack(role, action_list)
    if role.hp > 0 and role.relive == false then
        self.posi = role.posi
        self.act_status = 1
        local ret = self:check_event(action_list)
        if ret == EVENT_NEWROUND then
            return EVENT_NEWROUND
        elseif ret == EVENT_STOP then
            return EVENT_STOP
        elseif ret == EVENT_NOTHING then
            local attack = {
                posi = role.posi - 1,
            }
            local action = {
                attack = attack,
            }
            tinsert(action_list, action)
            local hurt, rehurt = role:do_attack(attack, self.posi_list)
            if self.posi < 100 then
                self.hurt[1] = self.hurt[1] + hurt
                self.hurt[2] = self.hurt[2] + rehurt
            else
                self.hurt[2] = self.hurt[2] + hurt
                self.hurt[1] = self.hurt[1] + rehurt
            end
        end
        self.act_status = 2
        local wret = self:check_win()
        -- 检测特殊事件
        ret = self:check_event(action_list)
        if ret ~= EVENT_NOTHING then
            --self.winner = -1
            return ret
        else
            if wret ~= 2 then return EVENT_STOP
            else return ret end
        end
    end
    return EVENT_NEXT
end

-- 每回合信息
function Fight:round(round_list)
    self:refresh_by_one_round()
    self.round_id = self.round_id + 1
    self.posi = 0
    self.act_status = 0
    local action_list = {}
    local new_round = {     -- 新一回合
        action_list = action_list
    }
    tinsert(round_list, new_round)
    local ret = self:check_event(action_list)
    if ret == EVENT_STOP then
        return EVENT_STOP
    end
    if self.round_id == 1 and self.start_talk then
        local event = self:talk(self.start_talk)
        tinsert(action_list, event)
    end
    while 1 do
        for k,v in ipairs(self.role_list) do
            ret = self:attack(v, action_list)
            if ret == EVENT_STOP then
                break
            elseif ret == EVENT_NEWROUND then  -- 如果有人加入或退出，本回合作废
                break
            end
        end
        if ret == EVENT_NEXT or ret == EVENT_NOTHING or ret == EVENT_NEWROUND or ret == EVENT_STOP then
            break
        end
    end
    return ret
end

-- 开始战斗
function Fight:play(rcd)
    -- 先按照speed排序
    tsort(self.role_list, sort_by_speed)
    self.round_id = 0
    local round_list = rcd.round_list
    local preview = rcd.preview
    while 1 do
        local ret = self:round(round_list)
        if ret == EVENT_STOP then
            break
        end
        if self.round_id >= self.round_limit then
            if self.always_win then
                self.winner = 1
            else
                self.winner = 0
            end
            break
        end
    end
    if self.winner == 1 and self.end_talk then
        local event = self:talk(self.end_talk)
        local round_len = rawlen(round_list)
        assert(round_len > 0)
        local last_round = round_list[round_len]
        tinsert(last_round.action_list, event)
    end
    preview.winner = self.winner
    local role_list = {}
    for k,v in ipairs(self.role_list) do
        local t = v:get_preview()
        t.end_hp = v.hp
        tinsert(role_list, t)
    end
    preview.role_list_end = role_list
    preview.stat_info.total_damage = self.hurt
end

-- 检测是否有人获胜
function Fight:check_win()
    local p1 = 0
    local p2 = 0
    for k,v in ipairs(self.role_list) do
        if v.posi < 100 then
            p1 = p1 + v.hp
        elseif v.posi < 10000 then
            p2 = p2 + v.hp
        end
    end
    if p1 == 0 then
        self.winner = 0
        return 0
    elseif p2 == 0 then
        self.winner = 1
        return 1
    else
        return 2
    end
end


-- 检测缘
function Fight:check_yuan_lover(user_data, is_p2)
    local group_start = 0
    if is_p2 then group_start = 100 end
    -- 先处理侠侣：
    for _,v in ipairs(user_data.lover_list) do
        local conf = Lovers_conf[v.id]
        assert(conf, "lover conf not find")
        local hero_id = conf.HERO_ID
        for k = 1,7 do
            local p = rawget(self.posi_list,group_start+ k)
            if p and p.id == hero_id then
                -- 找到侠侣英雄
                local lover_data = {
                    add_hp = conf.HERO_LIFE_RAISE,
                    add_speed = conf.HERO_SPEED_RAISE,
                    add_att = conf.HERO_ATTACK_RAISE,
                    add_def = conf.HERO_DEFENSE_RAISE,
                }
                p.lover_data = lover_data
                if conf.SKILL_ID ~= 0 then
                    local lover_skill = Skill:new(conf.SKILL_ID, hero_id % 10)
                    lover_skill.base_att = 0
                end
                break
            end
        end
    end
    
    -- 处理缘
    local check_list = {}       -- 这是所有上阵侠客列表
    for k = 1,7 do
        local p = rawget(self.posi_list,group_start+ k)
        if p then rawset(check_list, p.id, group_start + k) end
        for k1 = 1,10 do
            local t_posi = 1000 + k * 100 + k1
            if is_p2 then t_posi = t_posi + 1000 end
            local t_p = rawget(self.posi_list, t_posi)
            if t_p then rawset(check_list, t_p.id, t_posi) end
        end
    end
    
    local rela_conf_idx = Relationship_conf.index
    for k,v in ipairs(rela_conf_idx) do
    --遍历所有缘
        local tag_list = {}
        local cur_rela = Relationship_conf[v]
        local hero_list = cur_rela.HERO_ID_LIST
        local get_yuan = true
        -- 是否具备所有侠客
        for k1,v1 in ipairs(hero_list) do
            rawset(tag_list, k1, rawget(check_list, v1))
            if not rawget(check_list, v1) then
                get_yuan = false
                break
            end
        end
        if get_yuan then
            local yuan_skill = nil
            local yuan_data = nil
            if cur_rela.SKILL_ID ~= 0 then
                local add_yuan_skill = true
                for k1,v1 in ipairs(tag_list) do
                    if v1 > 107 then
                        add_yuan_skill = false
                        break
                    end
                end
                if add_yuan_skill then
                    yuan_skill = Skill:new(cur_rela.SKILL_ID, 0)
                    yuan_skill.base_att = 0
                end
            else
                yuan_data = {
                    add_hp = cur_rela.LIFE_RAISE / 100,
                    add_speed = cur_rela.SPEED_RAISE / 100,
                    add_att = cur_rela.ATTACK_RAISE / 100,
                    add_def = cur_rela.DEFENSE_RAISE / 100,
                }
            end
            local evolution = 1000
            for k1,v1 in ipairs(tag_list) do
                local role = self.posi_list[v1]
                assert(role)
                if yuan_data then
                    local yuan_data_list = role.yuan_data_list
                    if not yuan_data_list then
                        yuan_data_list = {}
                        role.yuan_data_list = yuan_data_list
                    end
                    table.insert(yuan_data_list, yuan_data)
                elseif yuan_skill then
                    role.yuan_skill = yuan_skill
                    if evolution > role.base_data.evolution then
                        evolution = role.base_data.evolution
                    end
                end
                
            end
            if yuan_skill then
                yuan_skill.level = evolution + 1
                tinsert(self.yuan_skill_list, yuan_skill)
            end
        end
    end
end



local function debug(a)
    for k,v in pairs(a) do
        print(k,v)
        if type(v) == "table" then
            debug(v)
        end
    end
end

function Fight:pve_sim(user_data, stage, difficulty, num, resp)
    self.stage_id = stage
    self.difficulty = difficulty
    assert(difficulty >= 1 and difficulty <= 3)
    local win = 0
    for k = 1,num do
        self.round_id = 0
        self.posi = 0
        self.act_status = 0
        self.event_id = 0
        self.winner = -1
        self.role_list = {}
        self.posi_list = {}
        self.stage_info = {pass_num = 1}
        self.stage_data = Stage_conf[stage]
        self.rcd = {
            preview = {winner = 0, role_list = {}},
            round_list = {}
        }
        self.yuan_skill_list = {}
        local rcd = self.rcd
        self:get_environment_data(stage, difficulty)
        assert(difficulty <= self.stage_data.DIFFICULTY_QUANTITY) -- 有些关卡没有高级难度
        self:get_player_data(user_data)
        self:get_attrib()
        -- 获取一个table，内部已经按照出手顺序排序了
        tsort(self.role_list, sort_by_speed)
        self:play(rcd)
        if self.winner == 1 then
            win = win + 1
        end
    end
    resp.win = win
end


function Fight:pvp(user_data, user_data1, tag_idx, tag_name, self_name, rank)
    local tag_entry = rawget(rank.rank_list_id,tag_idx)
    local tag_entry1 = rawget(rank.rank_list_name, tag_name)
    -- 必须保证对手排名没变更
    assert(tag_entry1.idx == tag_idx)
    assert(tag_entry.name == tag_name)
    local rcd = self.rcd
    local preview = rcd.preview
    preview.winner = 0
    self:get_player_data(user_data)
    self:get_player_data(user_data1, true)
    self:get_attrib()
    -- 这里必须先获取原始preview，排序之后顺序就乱了
    self:get_preview_role_list()
    
    -- 获取一个table，内部已经按照出手顺序排序了
    tsort(self.role_list, sort_by_speed)
    
    
    self:play(rcd)
    -- 获取奖励
    
    --debug(rcd.round_list)
    return rcd
end








function Fight:get_sim_data(user_data, is_p2)
    local player_role_list = self.role_list
    local posi_list = self.posi_list
    local posi_offset = 0
    local lover_skill_list = {}
    -- 计算团队加成
    local team_raise = self:calc_team_raise(user_data)
    
    if is_p2 then posi_offset = 100 end
    local zhanwei_list = user_data.zhenxing.zhanwei_list
    for k,v in ipairs(zhanwei_list) do
        if v.status ~= 0 then
            local role = {}
            if v.status == 1 then
                --这是主将
                role = Leader:new(user_data, k + posi_offset)
                role.team_raise = team_raise
                if #lover_skill_list then
                    role.lover_skill_list = lover_skill_list
                end
            elseif v.status == 2 then
                --这是侠客
                role = Knight:new(v.knight, k + posi_offset)
                role.team_raise = team_raise
            elseif v.status == 3 then
                -- 刷出的npc不需要计算各种属性加成
                role = Monster:new(v.t, k)
            end
            tinsert(player_role_list, role)
            rawset(posi_list, k + posi_offset, role)
        end
    end
    self:check_yuan_lover(user_data, is_p2)
end





return Fight

