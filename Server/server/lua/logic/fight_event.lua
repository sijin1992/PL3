local evnet_list = {
    {
        id = 50010001,
        {}
    }
}

local Knight = require "fight_knight"
local Leader = require "fight_leader"
local Monster = require "fight_monster"
local Skill = require "fight_skill"
local time_checking = require "time_checking"

local update_tili_per_6min = time_checking.update_tili_per_6min

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

local logic_knight = require "logic_knight"
local logic_user = require "logic_user"

local Fight = {}
Fight.__index = Fight

local EVENT_NOTHING = 0
local EVENT_NEXT = 1  -- 战斗没有结束，继续
local EVENT_STOP = 2  -- 战斗结束，终止循环
local EVENT_NEWROUND = 3 -- 有人加入或退出战斗，role_list改变，必须重新循环

function Fight:new()
    local self = {
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
            },
            round_list = {},
        },
        yuan_skill_list = {},
        start_talk = nil,
        end_talk = nil,
    }
    setmetatable(self, Fight)
    return self
end

function Fight:calc_team_raise(user_data, lover_skill_list)
    -- 计算团队加成
    local team_raise = {att = 0, def = 0, hp = 0, speed = 0}
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
    return team_raise
end


-- 从用户数据填充p1列表
function Fight:get_player_data(user_data, is_p2, p1_hook)
    local player_role_list = self.role_list
    local posi_list = self.posi_list
    local posi_offset = 0
    local lover_skill_list = {}
    -- 计算团队加成
    local team_raise = self:calc_team_raise(user_data, lover_skill_list)
    
    if is_p2 then posi_offset = 100 end
    local zhanwei_list = user_data.zhenxing.zhanwei_list
    if p1_hook then
        zhanwei_list = clonetab(zhanwei_list)
        p1_hook(zhanwei_list)
    end
    for k,v in ipairs(zhanwei_list) do
        if v.status ~= 0 then
            local role = {}
            if v.status == 1 then
                --这是主将
                role = Leader:new(user_data, k + posi_offset)
                role.knight = user_data.lead
                role.team_raise = team_raise
                if #lover_skill_list then
                    role.lover_skill_list = lover_skill_list
                end
            elseif v.status == 2 then
                --这是侠客
                role = Knight:new(v.knight, k + posi_offset)
                role.knight = v.knight
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
        v:get_attrib() --查表获取一级属性并计算二级属性
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
        assert(posi_list[posi] == nil, sformat("posi %d has role",posi))
        local role = Monster:new(role_id, posi,1, v[3])
        role:get_attrib()
        local role_preview = role:get_preview()
        role_preview.posi = role_preview.posi + event_id * 10000
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
    --self:check_yuan(0)
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

function Fight:check_event(action_list)
    local ret = EVENT_NOTHING
    local event_id = self.event_id
    if event_id == 0 then return ret end
    
    if event_id < 10200 and event_id >= 10100 then
        if self.act_status == 0 and self.round_id == 1 then
            local role = rawget(self.posi_list, 2)
            assert(role)
            role.def = 5000
            role.skill.probably = 1000
            role = rawget(self.posi_list, 102)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 1)
            assert(role)
            role.skill.probably = 1000
            local lover_skill = Skill:new(110360001, 1)
            lover_skill:get_conf(role.att)
            lover_skill.probably = 1000
            local lover_skill_list = {lover_skill}
            role.lover_skill_list = lover_skill_list
            role.lover_skill_count = 2
            ret = EVENT_NEXT
        elseif event_id == 10101 and self.winner == 1 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40010003, 101},{40010004, 103},
            {40010005, 104},{40010005, 105},{40010005, 106},{40010005, 107}}, event_id)
            tinsert(action_list, event)
            event = self:talk(172920772)
            tinsert(action_list, event)
            local role = rawget(self.posi_list, 101)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 103)
            assert(role)
            local yuan_skill = Skill:new(110700001, 1)
            yuan_skill:get_conf(role.att)
            yuan_skill.probably = 1000
            role.yuan_skill = yuan_skill
            self.winner = 0
            ret = EVENT_NEWROUND
        elseif event_id == 10102 and rawget(self.posi_list, 1).hp == 0 then
            local event = self:exit({1})
            tinsert(action_list, event)
            event = self:join({{40010007, 1},{40010006, 3}}, event_id)
            tinsert(action_list, event)
            event = self:talk(172930773)
            tinsert(action_list, event)
            local role = rawget(self.posi_list, 1)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 3)
            assert(role)
            local yuan_skill = Skill:new(110680001, 1)
            yuan_skill:get_conf(role.att)
            yuan_skill.probably = 1000
            role.yuan_skill = yuan_skill
            ret = EVENT_NEWROUND
        end
    elseif event_id < 10300 and event_id >= 10200 then
        if self.act_status == 0 and self.round_id == 1 then
            local role = rawget(self.posi_list, 2)
            assert(role)
            role.def = 5000
            role = rawget(self.posi_list, 101)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 103)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 1)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 3)
            assert(role)
            role.skill.probably = 1000
            ret = EVENT_NEXT
        elseif event_id == 10201 and self.posi == 1 and self.act_status == 2 then
            local role = rawget(self.posi_list, 1)
            assert(role)
            local yuan_skill = Skill:new(110680001, 1)
            yuan_skill:get_conf(role.att)
            yuan_skill.probably = 1000
            role.yuan_skill = yuan_skill
            ret = EVENT_NEXT
        end
    elseif event_id < 10400 and event_id >= 10300 then
        if event_id == 10300 and self.act_status == 0 then
            local event = nil
            local posi = 1
            local t = rawget(self.posi_list, posi)
            if t then
                event = self:exit({posi})
                tinsert(action_list, event)
            end
            event = self:join({{40010010, posi}}, event_id)
            tinsert(action_list, event)
            local role = rawget(self.posi_list, 2)
            assert(role)
            role.def = 5000
            role = rawget(self.posi_list, 1)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 106)
            assert(role)
            role.skill.probably = 1000
            ret = EVENT_NEWROUND
        end
    elseif event_id < 10500 and event_id >= 10400 then
        if self.act_status == 0 and self.round_id == 2 then
            local event = nil
            local posi = 1
            local t = rawget(self.posi_list, posi)
            if t then
                event = self:exit({posi})
                tinsert(action_list, event)
            end
            event = self:join({{40010013, posi}}, event_id)
            tinsert(action_list, event)
            event = self:talk(173000795)
            tinsert(action_list, event)
            local role = rawget(self.posi_list, 1)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 102)
            assert(role)
            role.skill.probably = 1000
            ret = EVENT_NEXT
        end
    elseif event_id < 10600 and event_id >= 10500 then
        if event_id == 10500 and self.act_status == 0 then
            local posi = 1
            local role = rawget(self.posi_list, posi)
            role.skill.probably = 1000
            ret = EVENT_NEXT
        elseif event_id == 10501 then
            local role = rawget(self.posi_list, 102)
            if role.hp == 0 then
                local event = nil
                event = self:exit({102})
                tinsert(action_list, event)
                event = self:join({{40010026, 102}}, event_id)
                tinsert(action_list, event)
                event = self:join({{40010003, 3}}, event_id)
                tinsert(action_list, event)
                event = self:talk(173020802)
                tinsert(action_list, event)
                role = rawget(self.posi_list, 2)
                role.def = 5000
                role = rawget(self.posi_list, 3)
                role.skill.probably = 1000
                role = rawget(self.posi_list, 102)
                role.skill.probably = 1000
                self.winner = 0
                ret = EVENT_NEWROUND
            end
        end
    elseif event_id < 10700 and event_id >= 10600 then
        if event_id == 10600 and self.act_status == 0 then
            local posi = 1
            local role = rawget(self.posi_list, posi)
            role.skill.probably = 1000
            ret = EVENT_NEXT
        elseif event_id == 10601 and self.act_status == 0 and self.round_id == 2 then
            local event = nil
            local posi = {}
            local need_exit = false
            local t = rawget(self.posi_list, 3)
            if t then
                need_exit = true
                table.insert(posi, 3)
            end
            t = rawget(self.posi_list, 4)
            if t then
                need_exit = true
                table.insert(posi, 4)
            end
            if need_exit then
                event = self:exit(posi)
                tinsert(action_list, event)
            end
            event = self:join({{40010002, 3}, {40010001, 4}}, event_id)
            tinsert(action_list, event)
            event = self:talk(173730989)
            tinsert(action_list, event)
            local yuan_skill = Skill:new(110320001, 1)
            yuan_skill:get_conf(3500)
            yuan_skill.probably = 1000
            local role = rawget(self.posi_list, 4)
            assert(role)
            role.yuan_skill = yuan_skill
            role = rawget(self.posi_list, 3)
            assert(role)
            role.yuan_skill = yuan_skill
            ret = EVENT_NEWROUND
        end
    elseif event_id < 10800 and event_id >= 10700 then
        if event_id == 10700 and self.act_status == 0 then
            local posi = 1
            local role = rawget(self.posi_list, posi)
            role.skill.probably = 1000
            ret = EVENT_NEXT
        elseif event_id == 10701 then
            local role = rawget(self.posi_list, 102)
            if role.hp == 0 then
                local event = nil
                event = self:exit({102})
                tinsert(action_list, event)
                event = self:join({{40010021, 102}}, event_id)
                tinsert(action_list, event)
                event = self:join({{40010020, 3}}, event_id)
                tinsert(action_list, event)
                event = self:talk(173070818)
                tinsert(action_list, event)
                role = rawget(self.posi_list, 2)
                role.def = 5000
                role = rawget(self.posi_list, 3)
                role.skill.probably = 1000
                role = rawget(self.posi_list, 102)
                role.skill.probably = 1000
                self.winner = 0
                ret = EVENT_NEWROUND
            end
        end
    elseif event_id < 10900 and event_id >= 10800 then
        if event_id == 10800 and self.act_status == 0 then
            local posi = 3
            local role = rawget(self.posi_list, posi)
            role.skill.probably = 1000
            posi = 1
            local role = rawget(self.posi_list, posi)
            role.skill.probably = 1000
            ret = EVENT_NEXT
        elseif self.winner == 1 and event_id == 10801 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40010024, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(173100828)
            tinsert(action_list, event)
            self.winner = 0
            ret = EVENT_NEWROUND
        end
    elseif event_id < 20200 and event_id >= 20100 then
        if event_id == 20100 then
            local role = rawget(self.posi_list, 102)
            if role.hp == 0 then
                local event = nil
                event = self:exit({102})
                tinsert(action_list, event)
                event = self:join({{40020006, 102}}, event_id)
                tinsert(action_list, event)
                role = rawget(self.posi_list, 3)
                if role then
                    event = self:exit({3})
                    tinsert(action_list, event)
                end
                event = self:join({{40020005, 3}}, event_id)
                tinsert(action_list, event)
                event = self:talk(173130838)
                tinsert(action_list, event)
                role = rawget(self.posi_list, 3)
                role.skill.probably = 1000
                role = rawget(self.posi_list, 102)
                role.skill.probably = 1000
                role = rawget(self.posi_list, 2)
                role.def = 5000
                self.winner = 0
                ret = EVENT_NEWROUND
            end
        end
    elseif event_id < 20300 and event_id >= 20200 then
        if event_id == 20200 and self.act_status == 0 then
            local posi = 1
            local role = rawget(self.posi_list, posi)
            role.skill.probably = 1000
            ret = EVENT_NEXT
        end
    elseif event_id < 20400 and event_id >= 20300 then
        if event_id == 20300 and self.act_status == 0 then
            local posi = 3
            local role = rawget(self.posi_list, posi)
            role.skill.probably = 1000
            role.speed = 9999
            tsort(self.role_list, sort_by_speed)
            ret = EVENT_NEWROUND
        end
    elseif event_id < 20500 and event_id >= 20400 then
        if event_id == 20400 then
            local role = rawget(self.posi_list, 102)
            if role.hp == 0 then
                local event = nil
                event = self:exit({102})
                tinsert(action_list, event)
                event = self:join({{40020011, 102}}, event_id)
                tinsert(action_list, event)
                event = self:talk(173200862)
                tinsert(action_list, event)
                self.winner = 0
                ret = EVENT_NEWROUND
            end
        end
    elseif event_id < 20600 and event_id >= 20500 then
        if event_id == 20500 and self.act_status == 0 then
            local event = nil
            local posi = 3
            local t = rawget(self.posi_list, posi)
            if t then
                event = self:exit({posi})
                tinsert(action_list, event)
            end
            event = self:join({{40020012, posi}}, event_id)
            tinsert(action_list, event)
            local role = rawget(self.posi_list, 3)
            assert(role)
            role.skill.probably = 1000
            ret = EVENT_NEWROUND
        end
    elseif event_id < 20700 and event_id >= 20600 then
        if event_id == 20600 and self.act_status == 0 then
            local role = rawget(self.posi_list, 3)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 103)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 1)
            assert(role)
            role.skill.probably = 1000
            role.speed = 98
            role = rawget(self.posi_list, 2)
            assert(role)
            role.def = 5000
            tsort(self.role_list, sort_by_speed)
            ret = EVENT_NEWROUND
        elseif self.round_id == 2 and self.act_status == 0 then
            local role = rawget(self.posi_list, 1)
            assert(role)
            role.skill.probably = 0
            ret = EVENT_NEWROUND
        end
    elseif event_id < 20900 and event_id >= 20800 then
        if self.act_status == 0 and self.round_id == 1 then
            local role = rawget(self.posi_list, 102)
            assert(role)
            role.skill.probably = 1000
            role = rawget(self.posi_list, 2)
            assert(role)
            role.def = 5000
            role = rawget(self.posi_list, 1)
            assert(role)
            role.skill.probably = 1000
            ret = EVENT_NEXT
        elseif self.act_status == 0 and self.round_id == 2 then
            local event = nil
            event = self:join({{40020018, 3}, {40020019, 4}}, event_id)
            tinsert(action_list, event)
            event = self:talk(173280881)
            tinsert(action_list, event)
            local role = rawget(self.posi_list,3)
            role.skill.probably = 1000
            role = rawget(self.posi_list,4)
            role.skill.probably = 1000
            ret = EVENT_NEWROUND
        elseif self.act_status == 0 and self.round_id == 3 then
            local event = nil
            local role = rawget(self.posi_list,4)
            role.speed = 1
            event = self:join({{40020020, 5}, {40020021, 6}}, event_id)
            tinsert(action_list, event)
            event = self:talk(173290883)
            tinsert(action_list, event)
            role = rawget(self.posi_list,3)
            local yuan_skill = Skill:new(110730001, 1)
            yuan_skill:get_conf(600)
            yuan_skill.probably = 1000
            role.yuan_skill = yuan_skill
            
            yuan_skill = Skill:new(110310001, 1)
            yuan_skill:get_conf(6000)
            yuan_skill.probably = 1000
            role = rawget(self.posi_list,5)
            role.yuan_skill = yuan_skill
            role = rawget(self.posi_list,6)
            role.yuan_skill = yuan_skill
            ret = EVENT_NEWROUND
        end
    elseif event_id < 30200 and event_id >= 30100 then
        if event_id == 30100 and self.act_status == 0 then
            local event = nil
            local posi = 3
            local t = rawget(self.posi_list, posi)
            if t then
                event = self:exit({posi})
                tinsert(action_list, event)
            end
            event = self:join({{40030001, posi}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NEWROUND
        end
    elseif event_id < 40300 and event_id >= 40200 then
        if self.posi_list[102].hp == 0 and event_id == 40200 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40040006, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(171270343)
            tinsert(action_list, event)
            self.winner = 0
            ret = EVENT_NEWROUND
        end
    elseif event_id < 40400 and event_id >= 40300 then
        if event_id == 40300 and self.act_status == 0 then
            local event = nil
            local posi = 4
            local t = rawget(self.posi_list, posi)
            if t then
                event = self:exit({posi})
                tinsert(action_list, event)
            end
            event = self:join({{40040007, posi}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NEWROUND
        end
    elseif event_id < 41100 and event_id >= 41000 then
        if self.winner == 1 and event_id == 41000 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40040016, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(171430388)
            tinsert(action_list, event)
            self.winner = 0
            ret = EVENT_NEWROUND
        end
    elseif event_id == 50400 or event_id == 50500 or event_id == 50700 or
        event_id == 50800 or event_id == 51000 then
        local event = nil
        local posi = 1
        local t = rawget(self.posi_list, posi)
        if t then
            event = self:exit({posi})
            tinsert(action_list, event)
        end
        local knight = 40050001
        if event_id == 50500 then knight = 40050015
        elseif event_id == 50800 then knight = 40050018 end
        event = self:join({{knight, posi}}, event_id)
        tinsert(action_list, event)
        ret = EVENT_NEWROUND
    elseif event_id == 60200 or event_id == 60400 or event_id == 60500 then
        local event = nil
        local posi = 1
        local knight = 40060001
        if event_id == 60400 then knight = 40060007 end
        local t = rawget(self.posi_list, posi)
        if t then
            event = self:exit({posi})
            tinsert(action_list, event)
        end
        event = self:join({{knight, posi}}, event_id)
        tinsert(action_list, event)
        ret = EVENT_NEWROUND
    elseif event_id == 60300 then
        local event = nil
        local posi = {}
        local need_exit = false
        local t = rawget(self.posi_list, 1)
        if t then
            need_exit = true
            table.insert(posi, 1)
        end
        t = rawget(self.posi_list, 3)
        if t then
            need_exit = true
            table.insert(posi, 3)
        end
        if need_exit then
            event = self:exit(posi)
            tinsert(action_list, event)
        end
        event = self:join({{40060001, 1}, {40060007, 3}}, event_id)
        tinsert(action_list, event)
        ret = EVENT_NEWROUND
    elseif event_id < 60700 and event_id >= 60600 then
        if self.winner == 1 and event_id == 60600 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40060010, 101, 1}, {40060010, 103, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(171680460)
            tinsert(action_list, event)
            self.winner = 0
            ret = EVENT_NEWROUND
        elseif self.winner == 1 and event_id == 60601 then
            local event = self:exit({101, 103})
            tinsert(action_list, event)
            event = self:join({{40060010, 101, 1}, {40060010, 102, 1}, {40060010, 103, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(171690461)
            tinsert(action_list, event)
            self.winner = 0
            ret = EVENT_NEWROUND
        end
    elseif event_id == 60700 or event_id == 60800 or event_id == 60900 then
        local event = nil
        local knight = 40060001
        if event_id == 60700 then knight = 40060012 end
        local t = rawget(self.posi_list, 1)
        if t then
            event = self:exit({1})
            tinsert(action_list, event)
        end
        event = self:join({{knight, 1}}, event_id)
        tinsert(action_list, event)
        ret = EVENT_NEWROUND
    elseif event_id == 70200 or event_id == 70300 or event_id == 70400 then
        local event = nil
        local knight = 40070001
        if event_id == 70400 then knight = 40070007 end
        local t = rawget(self.posi_list, 1)
        if t then
            event = self:exit({1})
            tinsert(action_list, event)
        end
        event = self:join({{knight, 1}}, event_id)
        tinsert(action_list, event)
        ret = EVENT_NEWROUND
    elseif event_id < 80800 and event_id >= 80700 then
        if event_id == 80700 then
            local event = nil
            local t = rawget(self.posi_list, 1)
            if t then
                event = self:exit({1})
                tinsert(action_list, event)
            end
            event = self:join({{40080008, 1}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NEWROUND
        elseif event_id == 80701 and self.act_status == 2 and self.posi_list[1].hp == 0 then
            local event = self:talk(171940512)
            tinsert(action_list, event)
            ret = EVENT_NEXT
        end
    elseif event_id < 90400 and event_id >= 90300 then
        if self.winner == 1 and event_id == 90300 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40090005, 102, 1}}, event_id)
            tinsert(action_list, event)
            ret = EVENT_NOTHING
        end
    elseif event_id == 100200 then
        local event = nil
        local t = rawget(self.posi_list, 3)
        if t then
            event = self:exit({3})
            tinsert(action_list, event)
        end
        event = self:join({{40100003, 3}}, event_id)
        tinsert(action_list, event)
        ret = EVENT_NEWROUND
    elseif event_id < 130400 and event_id >= 130300 then
        if self.winner == 1 and event_id == 130300 then
            local event = self:exit({102})
            tinsert(action_list, event)
            event = self:join({{40130004, 102, 1}}, event_id)
            tinsert(action_list, event)
            event = self:talk(172490647)
            tinsert(action_list, event)
            self.winner = 0
            ret = EVENT_NEWROUND
        end
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
            role:do_attack(attack, self.posi_list)
        end
        self.act_status = 2
        local wret = self:check_win()
        -- 检测特殊事件
        ret = self:check_event(action_list)
        if ret ~= EVENT_NOTHING then
            self.winner = -1
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
    self:check_event(action_list)
    if self.round_id == 1 and self.start_talk then
        local event = self:talk(self.start_talk)
        tinsert(action_list, event)
    end
    local ret
    while 1 do
        for k,v in ipairs(self.role_list) do
            ret = self:attack(v, action_list)
            if ret == EVENT_STOP then
                if self.winner == 1 and self.end_talk then
                    local event = self:talk(self.end_talk)
                    tinsert(action_list, event)
                end
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
        --if self.round_id > 30 then break end
    end
    preview.winner = self.winner
    local role_list = {}
    for k,v in ipairs(self.role_list) do
        local t = v:get_preview()
        t.end_hp = v.hp
        tinsert(role_list, t)
    end
    preview.role_list_end = role_list
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
    local check_list = {}
    for k = 1,7 do
        local p = rawget(self.posi_list,group_start+ k)
        if p then rawset(check_list, p.id, group_start + k) end
    end
    
    local rela_conf_idx = Relationship_conf.index
    for k,v in ipairs(rela_conf_idx) do
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
                yuan_skill = Skill:new(cur_rela.SKILL_ID, 0)
                yuan_skill.base_att = 0
            else
                yuan_data = {
                    add_hp = 1 + cur_rela.LIFE_RAISE / 100,
                    add_speed = 1 + cur_rela.SPEED_RAISE / 100,
                    add_att = 1 + cur_rela.ATTACK_RAISE / 100,
                    add_def = 1 + cur_rela.DEFENSE_RAISE / 100,
                }
            end
            local evolution = 1000
            for k1,v1 in ipairs(tag_list) do
                local role = self.posi_list[v1]
                assert(role)
                if yuan_data then
                    role.yuan_data = yuan_data
                else
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

