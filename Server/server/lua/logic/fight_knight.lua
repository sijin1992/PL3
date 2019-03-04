--[[
一、侠客数据
]]

local Role = require "fight_role"

local setmetatable = setmetatable

local Knight = {}

setmetatable(Knight, Role)

Knight.__index = Knight

function Knight:new(knight, posi)
    local self = Role:new()
    setmetatable(self, Knight)
    self.id = knight.id
    self.type = "KNIGHT"
    self.posi = posi
    self.base_data.level = knight.data.level - 1
    self.base_data.evolution = knight.data.evolution
    self.skill_data = knight.data.skill
    self.gong_info = knight.data.gong
    self.mj_list = rawget(knight.data, "miji_list")
    self.qianneng = knight.data.qianneng
    self.bqp_info = rawget(knight.data, "bqp_data")
    return self
end

function Knight:type_i()
    return 2
end

return Knight