
local app = require("app.MyApp"):getInstance()

local player = require("app.Player"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local g_sendList = require("util.SendList"):getInstance()

local PlanetMachine = class("PlanetMachine")

local Status = {
 	kMove = 1,
 	kMoveBack = 2,
 	kMoveEnd = 3,
 	kCollect = 4,
 	kFishing = 5,
 	kGuarde = 6,
}

local Element_type = {
	kBase = 1,
	kRes = 2,
	kRuins = 3,
	kBoss = 4,
	kCity = 5,
}

local res_machine = {}
local ruins_machine = {}
local raid_machine = {}
local spy_machine = {}
local stationed_machine = {}
local attack_base_machine = {}
local escort_machine = {}
local user_army_machine = {}

PlanetMachine.machine_list = {
	[1] = res_machine,
	[2] = ruins_machine,
	[3] = raid_machine,
	[4] = spy_machine,
	[5] = stationed_machine,
	[6] = attack_base_machine,
	[7] = escort_machine,
	[8] = user_army_machine,
}

PlanetMachine.scene = nil

function PlanetMachine:ctor()
	
end
	
function res_machine.check( ... )

	local info_list = planetManager:getInfoList()

	for i,v in ipairs(info_list) do
		for i2,v2 in ipairs(v.info) do
			if v2.type == Element_type.kRes then
				if v2.res_data.user_name ~= "" then

					local collect_speed = v2.res_data.collect_speed
					local res_conf = CONF.PLANET_RES.get(v2.res_data.id)
					if res_conf then
						collect_speed =  player:getValueByTechnologyAdditionGroup(collect_speed, CONF.ETechTarget_1.kWorldRes, res_conf.TYPE, CONF.ETechTarget_3_Res.kCollect)
					end

					local need_time = v2.res_data.cur_storage/collect_speed

					-- print("res time", player:getServerTime(), v2.res_data.begin_time, need_time)

					if player:getServerTime() > v2.res_data.begin_time + need_time then

						local event = cc.EventCustom:new("nodeUpdated")
						event.node_id_list = {tonumber(Split(v2.global_key, "_")[1])}
						cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
					end
				end
			end
		end
	end
end

function ruins_machine.check( ... )

	local info_list = planetManager:getInfoList()
	
	for i,v in ipairs(info_list) do
		for i2,v2 in ipairs(v.info) do
			if v2.type == Element_type.kRuins then
				if v2.ruins_data.user_name ~= "" then

					-- print("ruins time", player:getServerTime(), v2.ruins_data.begin_time, v2.ruins_data.need_time)
					if player:getServerTime() > v2.ruins_data.begin_time + v2.ruins_data.need_time then

						local event = cc.EventCustom:new("nodeUpdated")
						event.node_id_list = {tonumber(Split(v2.global_key, "_")[1])}
						cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
					end
				end
			end
		end
	end

end

function user_army_machine.check( ... )

	local planet_user = planetManager:getPlanetUser()

	if planet_user.army_list then
		for i,v in ipairs(planet_user.army_list) do

			-- print("army_list status", v.guid,v.status)
			-- print("line node_id_list",#v.line.node_id_list)

			-- for i,v in ipairs(v.line.node_id_list) do
			-- 	print("line node",i,v)
			-- end

			if v.status == Status.kMoveEnd then

				-- local strData = Tools.encode("PlanetRideBackReq", {
				-- 	army_guid = v.guid,
				-- 	type = 1,
				--  })
				-- g_sendList:addSend({define = "CMD_PLANET_RIDE_BACK_REQ", strData = strData, key = "army_ride_back_"..v.guid})

				-- local event = cc.EventCustom:new("nodeUpdated")
				-- event.node_id_list = {tonumber(Tools.split(v.element_global_key, "_")[1])}
				-- cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

			end
		end
	end
end

function PlanetMachine:check( ... )
	
	self.machine_list[1].check()
	self.machine_list[2].check()
	-- self.machine_list[8].check()

end


function PlanetMachine:update()
	self:check()

end

function PlanetMachine:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end
		
	return self.instance
end



return PlanetMachine