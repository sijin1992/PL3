
local app = require("app.MyApp"):getInstance()

local player = require("app.Player"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()
local SystemGuideManager = class("SystemGuideManager")

SystemGuideManager.guide_type = false 
SystemGuideManager.msg_type = false
SystemGuideManager.show_guide = g_show_system_guide
SystemGuideManager.guide_id = 0

function SystemGuideManager:ctor()
	local function recvMsg()
		--printInfo("Player:recvMsg")

		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GUIDE_STEP_RESP") then

			local proto = Tools.decode("GuideStepResp",strData)
			print("GuideStepResp", proto.result)
			if proto.result == 0 then

			end
		end
	
	end

	self.recvListener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

	eventDispatcher:addEventListenerWithFixedPriority(self.recvListener_, FixedPriority.kNormal)

end

function SystemGuideManager:addGuideStep(id)
	print("SystemGuideManager:addGuideStep", id)
	local strData = Tools.encode("GuideStepReq", {
        type = 1,
        step_index = math.floor(id/100)+1,
        step_num = id,
    })
    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GUIDE_STEP_REQ"),strData)
end

function SystemGuideManager:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end  
		
	return self.instance  
end

function SystemGuideManager:addGuideLayer()

	local id = 0

	if CONF.SYSTEM_GUIDANCE.check(self.guide_id+1) then
		id = self.guide_id+1
	end

	if id == 0 then
		app:removeViewByName("SystemGuideLayer/SystemGuideLayer")
		return
	end

	self:createGuideLayer(id)
end

function SystemGuideManager:createGuideLayer( id )
	print("##lua 74 SystemGuideManager:createGuideLayer id: " .. tostring(id) )
	if self.show_guide == false then
		print("##lua 74 SystemGuideManager:createGuideLayer show_guide",self.show_guide)
		return
	end


	local guide 
	if guideManager:getSelfGuideID() ~= 0 then
		guide = guideManager:getSelfGuideID()
	else
		guide = player:getGuideStep()
	end

	if guide < CONF.GUIDANCE.count() then
		print("##lua 74 SystemGuideManager:createGuideLayer guide count",guide,CONF.GUIDANCE.count())
		return
	end

	if CONF.FUNCTION_OPEN.get( math.floor(id/100)).GRADE > player:getLevel() then
		print("##lua 74 SystemGuideManager:createGuideLayer guide getLevel",CONF.FUNCTION_OPEN.get( math.floor(id/100)).GRADE)
		return
	end

	if CONF.FUNCTION_OPEN.get(math.floor(id/100)).OPEN_GUIDANCE == 2 then
		print("##lua 74 SystemGuideManager:createGuideLayer OPEN_GUIDANCE",CONF.FUNCTION_OPEN.get(math.floor(id/100)).OPEN_GUIDANCE)
		return
	end

	self.guide_id = id

	print("SystemGuideLayer id ",id)
	if self.guide_type then
		app:removeViewByName("SystemGuideLayer/SystemGuideLayer")
	end

	app:addView2Top("SystemGuideLayer/SystemGuideLayer", {id = id})
end

function SystemGuideManager:doEvent( cmd, id )
	
	if cmd == "touch" then
		print("SystemGuideManager:doEvent touch")
		if CONF.SYSTEM_GUIDANCE.check(id+1) then
			self:createGuideLayer(id+1)
		else
			app:removeViewByName("SystemGuideLayer/SystemGuideLayer")
		end
	elseif cmd == "click" then
		print("SystemGuideManager:doEvent click")
		g_System_Guide_Id = id + 1

		-- if CONF.SYSTEM_GUIDANCE.check(id+1) then
			-- self:createGuideLayer(id+1)
		-- else
			app:removeViewByName("SystemGuideLayer/SystemGuideLayer")
		-- end
	elseif cmd == "trial_click" then

		g_System_Guide_Id = 0
		g_System_Guide_Id_T = id + 1

		-- if CONF.SYSTEM_GUIDANCE.check(id+1) then
			-- self:createGuideLayer(id+1)
		-- else
			app:removeViewByName("SystemGuideLayer/SystemGuideLayer")
		-- end
	end

	if not CONF.SYSTEM_GUIDANCE.check(id+1) then
		g_System_Guide_Id = 0
		g_System_Guide_Id_T = 0
	end

end


function SystemGuideManager:setGuideType( flag )
	self.guide_type = flag
end

function SystemGuideManager:getGuideType()
	return self.guide_type
end

function SystemGuideManager:getMsgType()
	return self.msg_type
end

function SystemGuideManager:setMsgType( flag )
	self.msg_type = flag
end

function SystemGuideManager:setShowGuide( flag )
	self.show_guide = flag
end

function SystemGuideManager:getShowGuide()
	return self.show_guide
end

function SystemGuideManager:getSelfGuideID( ... )
	return self.guide_id
end

return SystemGuideManager