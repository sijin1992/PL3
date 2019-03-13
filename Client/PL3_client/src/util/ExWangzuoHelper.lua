-- Coded by Wei Jingjun 20180810
print( "###LUA ExWangzuoHelper.lua" )
local ExWangzuoHelper = class("ExWangzuoHelper")



ExWangzuoHelper.IS_DEBUG_LOG_LOCAL = false

function ExWangzuoHelper:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end
------------------------------------------------

ExWangzuoHelper.DIAN_CI_TA_PARAMETERS_NEIWANG= {
	-- right
	["node1_4_4"] = {["rotation"] = 180,["scale"] = 1.15,["scale2"] = 1.08,["head_scaleY"] = 1},
	-- top
	["node1_-4_4"] = {["rotation"] = 90,["scale"] = 0.6,["scale2"] = 0.65,["head_scaleY"] = 0, ["offset_x"]=-8, ["offset_y"]=-47},
	-- left
	["node1_-4_-4"] = {["rotation"] = 0,["scale"] = 1.1,["scale2"] = 1.05,["head_scaleY"] = 1},
	-- bottom
	["node1_4_-4"] = {["rotation"] = -90,["scale"] = 0.65,["scale2"] = 0.7,["head_scaleY"] = 0}
}

--[[
ExWangzuoHelper.DIAN_CI_TA_PARAMETERS_NEIWANG= {
	-- right
	["node1_5_3"] = {["rotation"] = 180 + 10},
	-- top
	["node1_-3_3"] = {["rotation"] = 90, ["offset_x"]=-8, ["offset_y"]=-47},
	-- left
	["node1_-3_-5"] = {["rotation"] = -10},
	-- bottom
	["node1_5_-5"] = {["rotation"] = -90}
}
]]

ExWangzuoHelper.DIAN_CI_TA_PARAMETERS= {
	-- right
	-- ["node1_4_4"] = {["rotation"] = 180 + 10},
	["node1_4_4"] = {["rotation"] = 180,["scale"] = 1.15,["scale2"] = 1,["head_scaleY"] = 1},
	-- top
	["node1_-4_4"] = {["rotation"] = 90,["scale"] = 0.6,["scale2"] = 0.7,["head_scaleY"] = 0, ["offset_x"]=-8, ["offset_y"]=-47},
	-- left
	-- ["node1_-4_-4"] = {["rotation"] = -10},
	["node1_-4_-4"] = {["rotation"] = 0,["scale"] = 1.1,["scale2"] = 1,["head_scaleY"] = 1},
	-- bottom
	["node1_4_-4"] = {["rotation"] = -90,["scale"] = 0.65,["scale2"] = 0.7,["head_scaleY"] = 0}
}

---------------------------------------------------------------------------

ExWangzuoHelper.exSchedulerHelper_single = require("util.ExSchedulerHelper")
ExWangzuoHelper.exSchedulerHelper = {}
ExWangzuoHelper.UPDATE_INTERVAL = 10
ExWangzuoHelper.UPDATE_INIT = 0
ExWangzuoHelper.UPDATE_MAX = 1




function ExWangzuoHelper:DebugTowerData(tower_data, info, node_1)
      		-- local tower_data = info.tower_data
		self:_print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
		self:_print("node_1: ")
		self:_print(string.format("node_1: %s", tostring(node_1:getName())) )
		self:_print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
		self:_print("info: ")
		for k,v in pairs(info) do
			self:_print(string.format("k: %s", tostring(k)) )
			self:_print(string.format("v: %s", tostring(v)) )
		end

		self:_print("tower_data: ")
		for k2,v2 in pairs(tower_data) do
			self:_print(string.format("k2: %s", tostring(k2)) )
			self:_print(string.format("v2: %s", tostring(v2)) )
		end

		self:_print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")

	self:Debug_Diancita(tower_data.occupy_begin_time, tower_data.is_attack)
		-- require("util.ExWangzuoHelper"):getInstance():Debug_Diancita(tower_data.occupy_begin_time, tower_data.is_attack)

		self:_print("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
end

---------------------------------------------------------------------------
function ExWangzuoHelper:UpdateDiancita_Data(tower_data, info, node_1)
	local node_name = _node:getName()
	
	local data = {
		["node_object"] = node_1
	}
	
end

---------------------------------------------------------------------------

function ExWangzuoHelper:SetDiancita_Jiguang(_node, _anim,i)
	self:_print("~~~ _node:getName() : ")
	self:_print(_node:getName())
	local node_name = _node:getName()

	local is_neiwang = require("util.ExConfig"):getInstance():IsNeiwang()

	local param = self.DIAN_CI_TA_PARAMETERS[node_name]

	if( is_neiwang ) then
		param = self.DIAN_CI_TA_PARAMETERS_NEIWANG[node_name]
	end

	if (param == nil) then
		return
	end

	local anim_node = _node:getChildByName(_anim..i)
    if i == 4 then
        local Node_4 = anim_node:getChildByName("Node_4")
	    if (param["scale"] ~= nil) then
		    Node_4:setScaleX(param["scale"])
	    end
    elseif i == 2 then
        local sp2_node = anim_node:getChildByName("Sprite_2")
        if (param["scale2"] ~= nil) then
            sp2_node:setScaleX(param["scale2"])
        end
    end

	if (param["offset_x"] ~= nil) then
		-- anim_node:setPositionX(anim_node:getPositionX() + param["offset_x"])
	end

	if (param["offset_y"] ~= nil) then
		-- anim_node:setPositionY(anim_node:getPositionY() + param["offset_y"])
	end

    anim_node:setRotation(param["rotation"])

end

function ExWangzuoHelper:Debug_Diancita(occupy_begin_time, is_attack, run2)
	self:_print("~~~ tower.tower_data.occupy_begin_time: " .. tostring(occupy_begin_time))
	self:_print("~~~ now: " .. tostring(os.time()))
	self:_print("~~~ tower_data.is_attack: " .. tostring(is_attack))
	-- _print("~~~ run2: " .. tostring(run2))
	self:_print("~~~ Diancita_IsTimeShoot: " .. tostring(self:Diancita_IsTimeShoot(occupy_begin_time, is_attack)))

end

function ExWangzuoHelper:Diancita_IsTimeShoot(occupy_begin_time, is_attack)
	if( is_attack == false ) then
		return false
	end

	local tower_attack_time = CONF.PARAM.get("tower_attack_time").PARAM
	local now = os.time()
	local passed = now - occupy_begin_time
	
	-- test
	-- passed = tower_attack_time

	if( passed > 0 ) then
		local mod = math.floor(passed % tower_attack_time)
		self:_print("~~~ passed: " .. tostring(passed))
		self:_print("~~~ tower_attack_time: " .. tostring(tower_attack_time))
		self:_print("~~~ mod: " .. tostring(mod))
		if( mod == 0 ) then
			do return true end
		end
	end

	return false
end

------------------------------------------------

function ExWangzuoHelper:OnSchedulerUpdate()
	local _self = ExWangzuoHelper
	if( _self.exSchedulerHelper.ScheduleState ~= _self.exSchedulerHelper.E_LOADING_STATE.RUNNING ) then
		self:_print( "###LUA NOT RUNNING !! ExWangzuoHelper State: " .. ( tostring(_self.exSchedulerHelper.ScheduleState) or " nil " ) )
		do return end
	end

	-- ADD WJJ 20180813
	if( cc.exports.G_INSTANCE_PlanetDiamondLayer ~= nil ) then
		cc.exports.G_INSTANCE_PlanetDiamondLayer:OnSchedulerUpdate()
	end

	_self:_print( "###LUA ExWangzuoHelper OnSchedulerUpdate RUNNING !!")
end

function ExWangzuoHelper:OnSchedulerEnd()
	self:_print("@@@@ ExWangzuoHelper:OnSchedulerEnd")
end

function ExWangzuoHelper:InitScheduler()
	self:_print( "###LUA ExWangzuoHelper.lua InitScheduler" )
	self.exSchedulerHelper = self.exSchedulerHelper_single:new(self.exSchedulerHelper, self.UPDATE_INTERVAL, self.UPDATE_INIT, self.UPDATE_MAX )
	self.exSchedulerHelper:RegisterCallBack(self.OnSchedulerEnd)
	self.exSchedulerHelper:OnBegin(self.OnSchedulerUpdate)
end

------------------------------------------------

function ExWangzuoHelper:getInstance()
	self:_print( "###LUA ExWangzuoHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExWangzuoHelper:onCreate()
	self:_print( "###LUA ExWangzuoHelper.lua onCreate" )


	return self.instance
end


if( ExWangzuoHelper.exSchedulerHelper.count_current == nil ) then
	ExWangzuoHelper:InitScheduler()
end

ExWangzuoHelper:_print( "###LUA Return ExWangzuoHelper.lua" )
return ExWangzuoHelper