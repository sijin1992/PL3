
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local player = require("app.Player"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local planetArmyManager = require("app.views.PlanetScene.Manager.PlanetArmyManager"):getInstance()

local g_sendList = require("util.SendList"):getInstance()

local PlanetArmyLayer = class("PlanetArmyLayer", cc.load("mvc").ViewBase)

PlanetArmyLayer.RESOURCE_FILENAME = "PlanetScene/PlanetArmyLayer.csb"

PlanetArmyLayer.RUN_TIMELINE = true

PlanetArmyLayer.NEED_ADJUST_POSITION = true

PlanetArmyLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil


function PlanetArmyLayer:onEnter()
  
	printInfo("PlanetArmyLayer:onEnter()")

end

function PlanetArmyLayer:onExit()
	
	printInfo("PlanetArmyLayer:onExit()")
end

function PlanetArmyLayer:getArmyList( ... )
	return self._pam:getArmyList()
end

function PlanetArmyLayer:onEnterTransitionFinish()
	printInfo("PlanetArmyLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()
	self._pam = planetArmyManager:create(self)
	self._pam:clearArmyList()
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPDATE_TIMESTAMP_REQ"),"0")

	local function update( dt )		
		self._pam:update(dt)
	end

	-- schedulerEntry = scheduler:scheduleScriptFunc(update,0.1,false)
	self:scheduleUpdateWithPriorityLua(update, 1)

	local function recvMsg()
		--print("PlanetDiamondLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then

			local proto = Tools.decode("PlanetGetResp",strData)

			-- gl:releaseLoading()

			if proto.result ~= 0 then
			
			else
				if proto.type == 4 then
					print("shuliang planet_army_line_list",#proto.planet_army_line_list)

					self._pam:setIsSend(false)
					self._pam:setArmyList(proto.planet_army_line_list)

				elseif proto.type == 3 then
					self._pam:setIsSend(false)
				elseif proto.type == 2 then
					local list = {}
					for i,v in ipairs(proto.node_list) do
						print("node army_line_key_list", v.id, #v.army_line_key_list)
						for i2,v2 in ipairs(v.army_line_key_list) do
							if Tools.isEmpty(list) then
								table.insert(list,v2)
							else

								local has = false
								for i3,v3 in ipairs(list) do
									if v3 == v2 then
										has = true
										break
									end
								end

								if not has then
									table.insert(list,v2)
								end

							end
						end

					end

					print("type 2 to 4 list num", #list)

					if not Tools.isEmpty(list) then

						local strData = Tools.encode("PlanetGetReq", {
							army_line_key_list = list,
							type = 4,
						 })
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
						-- g_sendList:addSend({define = "CMD_PLANET_GET_REQ", strData = strData})
					else
						self._pam:setArmyList({})
					end
				end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_UPDATE_TIMESTAMP_RESP") then

			local proto = Tools.decode("UpdateTimeStampResp",strData)

			if proto.result == 0 then
				self._pam:setTime(player:getServerTime())
        	end
		
		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)



end

function PlanetArmyLayer:onExitTransitionStart()

	printInfo("PlanetArmyLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.armyListener_)
	eventDispatcher:removeEventListener(self.baseListener_)

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	self._pam:clearArmyList()

end

return PlanetArmyLayer