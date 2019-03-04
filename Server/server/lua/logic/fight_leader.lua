--[[

]]

local Role = require "fight_role"

local setmetatable = setmetatable

local Leader = {}

setmetatable(Leader, Role)

Leader.__index = Leader

function Leader:new(main_data, posi)
    local self = Role:new()
    setmetatable(self, Leader)
    local base_data = self.base_data
    local lead_info = main_data.lead
    self.posi = posi
    base_data.level = lead_info.level - 1
    base_data.evolution = lead_info.evolution
    base_data.star = lead_info.star
    self.id = 10000000 + lead_info.star * 10000
    if lead_info.sex == 0 then
        self.type = "LEAD_M"
    else
        self.type = "LEAD_F"
    end
    self.equip_list = lead_info.equip_list
    self.skill_data = lead_info.skill
    self.wxjy_info = main_data.wxjy
    local group_data = rawget(main_data, "group_data")
    if group_data then
        self.group_wxjy_info = group_data.wxjy
    end
    self.qianneng = lead_info.qianneng
    self.bqp_info = rawget(lead_info, "bqp_data")
    return self
end

function Leader:type_i()
    return 1
end

return Leader