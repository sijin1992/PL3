--[[
一、怪兽数据
]]

local Role = require "fight_role"
local Skill = require "fight_skill"

local setmetatable = setmetatable
local assert = assert

local Npc_conf = Npc_conf

local Monster = {}

setmetatable(Monster, Role)

Monster.__index = Monster

function Monster:new(monster_id, posi, difficulty, is_boss)
    local self = Role:new()
    self.id = monster_id
    self.posi = posi
    if is_boss then self.type = "BOSS"
    else self.type = "NORMAL" end
    if difficulty then self.difficulty = difficulty
    else self.difficulty = 1 end
    setmetatable(self, Monster)
    return self
end

function Monster:type_i()
    return 3  --0未知，1主将，2侠客，3怪
end

-- 查配置表获取属性
function Monster:get_monster_attrib()
    assert(Npc_conf[self.id] ~= nil, string.format("npc %d not find", self.id))
    local conf = Npc_conf[self.id]
    local base_data = self.base_data
    local difficulty = self.difficulty
    base_data.att = conf.ATTACK * difficulty
    base_data.def = conf.DEFENSE
    base_data.hp = conf.LIFE * difficulty
    if difficulty == 2 then difficulty = 1.2 end
    base_data.speed = conf.SPEED * difficulty
    
    self.mingzhong = conf.HIT
    self.huibi = conf.DODGE
    self.baoji = conf.CRIT
    self.xiaojian = conf.ANTICRIT
    self.zhaojia = conf.BLOCK
    self.jibao = conf.SKILL_CRIT
    self.skill = Skill:new(conf.SKILL_ID_LIST, conf.SKILL_LV)
end

return Monster