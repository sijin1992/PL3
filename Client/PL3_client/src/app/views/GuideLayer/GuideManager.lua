
local app = require("app.MyApp"):getInstance()

local player = require("app.Player"):getInstance()

local GuideManager = class("GuideManager")

GuideManager.guide_type = false 
GuideManager.msg_type = false
GuideManager.show_guide = g_show_guide
GuideManager.guide_id = 0

GuideManager.first_guide_id = 0

GuideManager.teshu_guide_id = {29,44,47,36,52}

-- ADD WJJ 180620
GuideManager.observer = require("util.ExGuideObserver"):getInstance()
GuideManager.bugHelper = require("util.ExGuideTouchBug"):getInstance()

function GuideManager:ctor()
	local function recvMsg()
		--printInfo("GuideManager:recvMsg")

		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GUIDE_STEP_RESP") then

			local proto = Tools.decode("GuideStepResp",strData)
			if proto.result == 0 then

			end
		end
	
	end

	self.recvListener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

	eventDispatcher:addEventListenerWithFixedPriority(self.recvListener_, FixedPriority.kNormal)

end

function GuideManager:addGuideStep(id)
	print("GuideManager:addGuideStep", id)
	local strData = Tools.encode("GuideStepReq", {
        type = 1,
        step_index = 1,
        step_num = id,	
    })
    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GUIDE_STEP_REQ"),strData)
end

function GuideManager:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end  
		
	return self.instance  
end

function GuideManager:checkInterface( id )
	print(string.format( "@@@@ checkInterface: id : %s", tostring(id) ) )

	if self.show_guide == false then
		return
	end

	local guide 

	if self.guide_id ~= 0 then
		guide = self.guide_id
	else
		guide = player:getGuideStep()
	end

	if guide < self.first_guide_id then
		guide = self.first_guide_id
	end

	local _begin = ( guide or 0 )+1
	local _max = CONF.GUIDANCE.count()
	print(string.format( "@@@@ checkInterface: _begin : %s _max: %s ", tostring(_begin), tostring(_max) ) )

	for i=_begin,_max do
		local _interface = CONF.GUIDANCE.get(i).INTERFACE
		print(string.format( "@@@@ checkInterface: %s == %s ", tostring(_interface or " nil "), tostring(id or " nil") ) )
		if tonumber(_interface or -1) == tonumber(id or -1) then
			self:createGuideLayer(i)
			return
		end
	end

	-- local diff = (math.floor(guide/100)+1)*100 - guide - 1

	-- if guide%100 == 1 then
	-- 	guide = guide - 1 
	-- end
	-- if id == CONF.EInterface.kMain or id == CONF.EInterface.kLevel then
	-- 	for i=guide+1,guide+diff do
	-- 		if CONF.GUIDANCE.check(i) then
	-- 			if CONF.GUIDANCE.get(i).INTERFACE == id then
	-- 				self:createGuideLayer(i)
	-- 				return
	-- 			end
	-- 		else
	-- 			if math.floor(guide/100) < 6 then

	-- 				local index = (math.floor(guide/100)+1)*100+1

	-- 				for j=index,index+99 do
	-- 					if CONF.GUIDANCE.get(j).INTERFACE == id then

	-- 						-- if id == CONF.EInterface.kMain then

	-- 							-- self:addGuideStep(j)
	-- 						-- end
	-- 						self:createGuideLayer(j)
	-- 						return

	-- 					end
	-- 				end

	-- 			end
	-- 		end
	-- 	end
	-- else

	-- 	for i=guide+1,guide+diff do
	-- 		if CONF.GUIDANCE.check(i) then
	-- 			if CONF.GUIDANCE.get(i).INTERFACE == id then
	-- 				self:createGuideLayer(i)
	-- 				return
	-- 			end
	-- 		else
	-- 			return
	-- 		end
	-- 	end
	-- end
end

function GuideManager:getGuideID()

	local guide 

	if player:isInited() then
		if self.guide_id ~= 0 then
			guide = self.guide_id
		else
			guide = player:getGuideStep()
		end

		if guide < self.first_guide_id then
			guide = self.first_guide_id
		end
	else
		guide = g_Player_Guide
	end

	local id = math.floor(guide/100+1)*100+1

	if CONF.GUIDANCE.check(id) then
		return id 
	end

	return 0

end

function GuideManager:guideFinish()
	if player:isInited() then
		if not CONF.GUIDANCE.check(player:getGuideStep() + 1) then
			return true
		end
	end

	return false
end

function GuideManager:getNextGuideID()

	local guide 

	if player:isInited() then
		if self.guide_id ~= 0 then
			guide = self.guide_id
		else
			guide = player:getGuideStep()
		end

		if guide < self.first_guide_id then
			guide = self.first_guide_id
		end
	else
		guide = g_Player_Guide
	end

	local id = (guide+1)

	if CONF.GUIDANCE.check(id) then
		return id 
	end

	return 0 
end

function GuideManager:addGuideLayer()

	local id = self:getNextGuideID()

	if id == 0 then
		-- id = self:getGuideID()
		return
	end

	-- player:setGuideStep(id)

	
	self:createGuideLayer(id)
end

function GuideManager:OnGuideIdChanged( id )
	self.guide_id = id
	-- cc.UserDefault:getInstance():setStringForKey("global_guide_id_last", tostring(id))
	-- cc.UserDefault:getInstance():flush()
	cc.exports.global_guide_id_last = tostring(id)
end

function GuideManager:createGuideLayer( id )
	print("###LUA createGuideLayer begin >>>>>>>>>>>>>>>>>>>")
	print("###LUA id : " .. tostring(id),player:getGuideStep())
	if self.show_guide == false then
		return
	end

------------------------------------------------

	-- ADD WJJ 20180806
	if g_skip_new_player_guide then
		if( (id >= 5) and (id < CONF.GUIDANCE.count())) then
			id = CONF.GUIDANCE.count()
			local conf = CONF.GUIDANCE.get(id)
			self:addGuideStep(conf.SAVE)
			if self.guide_type then
				app:removeTopView()
			end
			self:setGuideType(false)
			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("GuideOver")
			
			--cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("playerLevelUp")
			return
		end		
	end

-- ADD WJJ 180622
	local is_bug = self.bugHelper:OnGuideId(id-1)

	if( is_bug ) then
		print("###LUA GuideManager:createGuideLayer BUG!! DISABLED this time! ")
		id = id - 1
		-- do return false end
	end

	-- skip 101, bug.
	--[[if( (id >= 101) and (id < 103)  ) then
		id = 103
	end

	-- SKIP jiayuan
	if( (id >= 65) and (id < 80)  ) then
		-- id = 76
		id = 80 -- skip unlock cang ku
	end

	-- skip unlock paotai
	-- if( id == 23  ) then
		-- id = 75
	-- end

	-- skip unlock zhen cha ta
	if( (id >= 39) and (id < 42)  ) then
		id = 42
	end

	-- skip unlock cang ku
	if( id == 76  ) then
		-- id = 75
	end]]

	-- ADD WJJ 20180629
	-- if( (id >= 34) and (id < 38 ) ) then
	-- 	id = 38
	-- end

------------------------------------------------

	self:OnGuideIdChanged( id )


	if player:isInited() then
		-- player:setGuideStep(id)
	else
		g_Player_Guide = id
	end

	self.observer:onCreate()

	if self.guide_type then
		app:removeTopView()
	end

    if device.platform == "ios" or device.platform == "android" then
        if id == CONF.GUIDANCE.count() then
            TDGAMission:onCompleted("GreenHand")
            TDGAAccount:setLevel(player:getLevel())
        end
    end

	app:addView2Top("GuideLayer/GuideLayer", {id = id})
	print("###LUA createGuideLayer END >>>>>>>>>>>>>>>>>>>")
end

function GuideManager:doEvent( cmd )
	
	local conf = CONF.GUIDANCE.check(self.guide_id)
	if conf == nil then
		return
	end

	if conf.EVENT == cmd then
		flurryLogEvent("guide", {guide_id = tostring(self.guide_id), type = "end.."..player:getServerDateString()}, 2)


		-- self:addGuideStep(self.guide_id)

		-- local index = 0
		-- for i,v in ipairs(CONF.GUIDANCE.getIDList()) do
		-- 	if self.guide_id == v then
		-- 		index = i
		-- 		break
		-- 	end
		-- end

		-- if index ~= #CONF.GUIDANCE.getIDList() then

		-- 	local guide_num = CONF.GUIDANCE.getIDList()[index + 1]

			-- if CONF.GUIDANCE.check(guide_num) then
			-- 	self:createGuideLayer(guide_num)
			-- end
		-- end
		if self.guide_type then
			app:removeTopView()
		end
		local guideID = self.guide_id+1
		if conf.EVENT == "specialEvent" then
			guideID = self.guide_id+2
		end
		if CONF.GUIDANCE.check(guideID) then
			self:createGuideLayer(guideID)
		else

			app:removeTopView()
			
		end

	end

end


function GuideManager:setGuideType( flag )
	self.guide_type = flag
end

function GuideManager:getGuideType()
	return self.guide_type
end

function GuideManager:getMsgType()
	return self.msg_type
end

function GuideManager:setMsgType( flag )
	self.msg_type = flag
end

function GuideManager:setShowGuide( flag )
	self.show_guide = flag
end

function GuideManager:getShowGuide()
	return self.show_guide
end

function GuideManager:getSelfGuideID( ... )
	return self.guide_id
end

function GuideManager:getTeshuGuideId( num )
	print( string.format( " @@@ getTeshuGuideId : %s ", tostring(num) ) )
	local _id = CONF.PARAM.get("guidance id").PARAM[num]
	print( string.format( " @@@ PARAM id : %s ", tostring(_id) ) )
	return CONF.PARAM.get("guidance id").PARAM[num]
end

return GuideManager