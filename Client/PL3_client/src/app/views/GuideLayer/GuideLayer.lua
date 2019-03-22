
local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local winSize = cc.Director:getInstance():getWinSize()

local scheduler = cc.Director:getInstance():getScheduler()

local GuideLayer = class("GuideLayer", cc.load("mvc").ViewBase)

local ShipsDevelopScene = class("ShipsDevelopScene", cc.load("mvc").ViewBase)

GuideLayer.RESOURCE_FILENAME = "GuideLayer/GuideLayer.csb"

GuideLayer.NEED_ADJUST_POSITION = true

GuideLayer.RESOURCE_BINDING = {
    --["Button_1"]   = {["varname"] = "btn"},
}

GuideLayer.IS_DEBUG_LOG_1 = false
GuideLayer.IS_DEBUG_LOG_LOCAL = true

GuideLayer.TIME_CURSOR_DELAY = 0.3

local schedulerEntry = nil
local schedulerEntryIndex = 0

--ADD WJJ 20180620
GuideLayer.touchHelper = require("util.ExGuideTouchHelper"):getInstance()

function GuideLayer:_print(_log,...)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log,...)
	end
end

function GuideLayer:onCreate( data )
	self.data_ = data
end

function GuideLayer:onEnter()
    
    printInfo("GuideLayer:onEnter()")




end

function GuideLayer:onExit()
    
    printInfo("GuideLayer:onExit()")
end

function GuideLayer:resetStencil(id)

	local conf = CONF.GUIDANCE.get(self.data_.id)

	local cur_size = self:getResourceNode():getContentSize()
	local cur_size_width = (winSize.width - cur_size.width)/2
	local cur_size_height = (winSize.height - cur_size.height)/2

	if conf.FRAME then
		self.stencil:setPosition(cc.p(conf.FRAME[1], conf.FRAME[2]))  		
	end

	if conf.SIZE then
		-- self.stencil:setContentSize(cc.size(conf.SIZE[1],conf.SIZE[2]))
		-- added by wjj 20180606
		local stencil_width = ( self.touchHelper.GUIDE_CLICK_SIZE_MULTIPLY * conf.SIZE[1] ) /self.stencil:getContentSize().width
		local stencil_height = ( self.touchHelper.GUIDE_CLICK_SIZE_MULTIPLY * conf.SIZE[2] ) /self.stencil:getContentSize().height

		if ( conf.SIZE[1] > 5000  ) then
			stencil_width = ( conf.SIZE[1] ) /self.stencil:getContentSize().width
			stencil_height = ( conf.SIZE[2] ) /self.stencil:getContentSize().height
		end

		self.stencil:setScale( stencil_width,  stencil_height)
	end

	if conf.TYPE_ARROWS then
		self.arrow:setRotation(conf.TYPE_ARROWS)
	end

	if conf.TYPE_COORDINATE then
		self.arrow:setPosition(cc.p(conf.TYPE_COORDINATE[1], conf.TYPE_COORDINATE[2]))
	end

	if conf.TYPE_SIZE then
		self.arrow:getChildByName("Image_1"):setContentSize(cc.size(conf.TYPE_SIZE[1], conf.TYPE_SIZE[2]))
	end

	-- if conf.TYPE_SIZE then
	-- 	self.arrow:setPosition(cc.p(conf.TYPE_COORDINATE[1], conf.TYPE_COORDINATE[2]))
	-- end

	if conf.POSTYPE then
		setScreenPositionWin(self.stencil, conf.POSTYPE)
		setScreenPositionWin(self.arrow, conf.POSTYPE)

		self.stencil:setPosition(cc.p(self.stencil:getPositionX() , self.stencil:getPositionY()))
		self.arrow:setPosition(cc.p(self.arrow:getPositionX() , self.arrow:getPositionY()))
	else
		self.stencil:setPosition(cc.p(self.stencil:getPositionX() + cur_size_width , self.stencil:getPositionY() + cur_size_height))
		self.arrow:setPosition(cc.p(self.arrow:getPositionX() + cur_size_width , self.arrow:getPositionY() + cur_size_height))
	end

	local offsetX 
	if conf.BUILDING_2 then
		local pos = math.abs(CONF.EMainBuildingPos[conf.BUILDING_2])
		if pos < cur_size_width then
			offsetX = -((cur_size_width - pos) --[[ - (114 - pos)]])
		else
			local col = pos + winSize.width
			if col > g_city_scene_width then
				offsetX = col - g_city_scene_width - cur_size_width
			end
		end		
	end
	if offsetX then
		self.stencil:setPosition(cc.p(self.stencil:getPositionX() + offsetX, self.stencil:getPositionY()))
		self.arrow:setPosition(cc.p(self.arrow:getPositionX() + offsetX, self.arrow:getPositionY()))
	end
	print("setScreenPositionWin",self.stencil:getPositionX(),self.data_.id)
	

	--if conf.POSTYPE == "center" then
		--local scale = CC_DESIGN_RESOLUTION.width/winSize.width
		--self.stencil:setPosition(cc.p(self.stencil:getPositionX() + (winSize.width - CC_DESIGN_RESOLUTION.width)/2*scale, self.stencil:getPositionY() + (winSize.height - CC_DESIGN_RESOLUTION.height)/2*scale))
		--self.arrow:setPosition(cc.p(self.arrow:getPositionX() + (winSize.width - CC_DESIGN_RESOLUTION.width)/2*scale, self.arrow:getPositionY() + (winSize.height - CC_DESIGN_RESOLUTION.height)/2*scale))
	--end

	--[[
	local scale = winSize.width/winSize.height
	local offsetX = 0
	if  conf.OFFSET ~= nil then
		if scale > 2.3 then
			offsetX = conf.OFFSET[1] + 110 
		elseif scale > 2.2 then
			offsetX = conf.OFFSET[1] + 80 
		elseif scale > 2.1 then
			offsetX = conf.OFFSET[1] + 40 
		elseif scale > 1.9 then
			offsetX = conf.OFFSET[1]
		elseif scale > 1.7 then
			offsetX = conf.OFFSET[1] - 10
		elseif scale > 1.5 then
			offsetX = conf.OFFSET[1] - 50
		elseif scale > 1.4 then
			offsetX = conf.OFFSET[1] + 80
		else
			offsetX = conf.OFFSET[1] + 130
		end
	end

	self.stencil:setPosition(cc.p(self.stencil:getPositionX() + (winSize.width - cur_size.width)/2 + offsetX, self.stencil:getPositionY() + (winSize.height - cur_size.height)/2))
	self.arrow:setPosition(cc.p(self.arrow:getPositionX() + (winSize.width - cur_size.width)/2 + offsetX, self.arrow:getPositionY() + (winSize.height - cur_size.height)/2))
	]]
end

function GuideLayer:resetInfo( ... )
	print ( "## LUA  GuideLayer resetInfo" )
	local conf = CONF.GUIDANCE.get(self.data_.id)

	local rn = self:getResourceNode()
	local node = rn:getChildByName("node")

	if conf.STRING_KEY then
		node:getChildByName("text"):setString(CONF:getStringValue(conf.STRING_KEY))
	end

	if conf.PERSON == 2 then
		node:getChildByName("role"):setVisible(true)
		node:getChildByName("my_name_di"):setVisible(false)
		node:getChildByName("my_name"):setVisible(false)
		node:getChildByName("enemy_role"):setVisible(false)
		node:getChildByName("enemy_name_di"):setVisible(false)
		node:getChildByName("enemy_name"):setVisible(false)
	elseif conf.PERSON == 1 then
		node:getChildByName("role"):setVisible(false)
		node:getChildByName("my_name_di"):setVisible(false)
		node:getChildByName("my_name"):setVisible(false)
		node:getChildByName("enemy_role"):setVisible(true)
		node:getChildByName("enemy_name_di"):setVisible(false)
		node:getChildByName("enemy_name"):setVisible(false)
		-- node:getChildByName("enemy_role"):setTexture("RoleImage/"..conf.XTNPC..".png")
	else
		node:getChildByName("role"):setVisible(false)
		node:getChildByName("my_name_di"):setVisible(false)
		node:getChildByName("my_name"):setVisible(false)
		node:getChildByName("enemy_role"):setVisible(false)
		node:getChildByName("enemy_name_di"):setVisible(false)
		node:getChildByName("enemy_name"):setVisible(false)
	end

	if conf.STRING_KEY and conf.TYPE == nil then
		self.clip:setVisible(false)
		self:_print ( "## LUA GuideLayer hide cursor!~!" )
		self.arrow:setVisible(false)

	else
		self.clip:setVisible(true)
		self.arrow:setVisible(true)

		if conf.STRING_KEY == nil then
			node:setVisible(false)
		end
	end
end


function GuideLayer:OnTouchRect( touch, is_skip_touch)

	if( is_skip_touch == nil ) then
		is_skip_touch = false
	end

	local is_rect = false

	if( (touch == nil) and (is_skip_touch == false) ) then
		do return false end
	end

	if( is_skip_touch ) then
		do return true end
	else
		local ln = self.stencil:convertToNodeSpace(touch:getLocation())

		local s = self.stencil:getContentSize()
		local rect = cc.rect(0, 0, s.width, s.height)

		is_rect = cc.rectContainsPoint(rect, ln)
	end

	return is_rect
end

-- ADD BY WJJ 20180620
print( "###LUA Return GuideLayer.lua 165" )
function GuideLayer:OnTouchEndNoBug( conf, listener, touch, is_skip_touch, g_id)

		if conf.EVENT == "animation" then
			listener:setSwallowTouches(true)
			return
		end
		-- if conf.MESSAGE == "showGuideAnim1" then
		-- 	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("showGuideAnim1")
		-- 	self:getApp():removeTopView()
		-- 	return
		-- end


		if conf.INTERFACE == 1 then
			if conf.BUILDING then
				if not guideManager:getMsgType() then
					listener:setSwallowTouches(true)
					return
				end
			end
		end

		local _self = GuideLayer
		local _guild_id = -1
		if( _self.data_ == nil ) then
			_self:_print("@@@@@ OnTouchEndNoBug _self.data_ nil!!! ")
			_guild_id = g_id
		else
			_guild_id = _self.data_.id
		end

		

		if conf.STRING_KEY then
			-- guideManager:addGuideLayer()
			flurryLogEvent("guide", {guide_id = tostring(_guild_id), type = "end.."..player:getServerDateString()}, 2)

			if CONF.GUIDANCE.check(_guild_id+1) then
				if _guild_id + 1 == guideManager:getTeshuGuideId(3) or _guild_id + 1 == guideManager:getTeshuGuideId(5) then
					if _guild_id + 1 == guideManager:getTeshuGuideId(3) then
						self:removeFromParent()
					end
					local event = cc.EventCustom:new("special_guide")
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
					return
				end
				if conf.INTERFACE == CONF.GUIDANCE.get(_guild_id+1).INTERFACE and player:isInited() then
					guideManager:addGuideLayer()
				else
					if conf.INTERFACE == 3 and CONF.GUIDANCE.get(_guild_id+1).INTERFACE == 1 then
						self:getApp():pushToRootView("CityScene/CityScene", {pos = -1350})
					elseif _guild_id == 110 then
						self:getApp():pushToRootView("CityScene/CityScene", {pos = -1350})
					elseif conf.INTERFACE == 21 or conf.INTERFACE == 25 then
						if conf.INTERFACE == CONF.GUIDANCE.get(_guild_id+1).INTERFACE then
							guideManager:addGuideLayer()
						else
							self:getApp():removeTopView()
						end
					else
						g_Player_Guide = _guild_id

						-- guideManager:createGuideLayer(_guild_id+1)
						self:getApp():removeTopView()
						
					end
				end
			else

				g_Player_Guide = _guild_id

				-- self:getApp():removeTopView()

				-- if CONF.GUIDANCE.get((math.floor(_guild_id/100)+1)*100+1).INTERFACE == 1 then
				-- 	self:getApp():pushToRootView("CityScene/CityScene", {pos = -350})
				-- else
					self:getApp():removeTopView()
				-- end

			end
		else
		-- 188 if

			local is_rect = self:OnTouchRect(touch, is_skip_touch)

			if is_rect then

				if not player:isInited() then
					if g_Player_Guide < 200 then
						-- cc.UserDefault:getInstance():setIntegerForKey("guideStep", 108)
						-- cc.UserDefault:getInstance():flush()
						self:getApp():removeTopView()
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("guideAction")
						
					end
				else
					if conf.EVENT == "touch" or conf.EVENT == "specialEvent" then
						print("OnTouchEndNoBug conf.EVENT", conf.EVENT)
						flurryLogEvent("guide", {guide_id = tostring(_guild_id), type = "end.."..player:getServerDateString()}, 2)

						if CONF.GUIDANCE.check(_guild_id+1) then
							if CONF.GUIDANCE.get(_guild_id+1).INTERFACE == CONF.GUIDANCE.get(_guild_id).INTERFACE then
								guideManager:createGuideLayer(_guild_id+1)
							else
								self:getApp():removeTopView()
							end
						else
							self:getApp():removeTopView()
						end
					elseif conf.EVENT == "battle" then
						self:getApp():removeTopView()
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("guideAction")
						
					end
				end

			else
				listener:setSwallowTouches(true)
			end

			-- listener:setSwallowTouches(true)
		end
		-- 188 if
	--  end 
	-- onTouchEnded 

end
--ADD WJJ 20180703
function GuideLayer:DelayAddCuror(arrow_z_order)
	self.arrow:retain()
	self.arrow:setVisible(false)
	self:runAction(cc.Sequence:create(cc.DelayTime:create(self.TIME_CURSOR_DELAY), cc.CallFunc:create(function ( ... )
		self:addChild(self.arrow, arrow_z_order)
		self.arrow:release()
	end)))
end

function GuideLayer:DelayShowCuror()
	self.arrow:setVisible(false)
	self:runAction(cc.Sequence:create(cc.DelayTime:create(self.TIME_CURSOR_DELAY), cc.CallFunc:create(function ( ... )
		animManager:runAnimByCSB(self.arrow, "GuideLayer/sfx/effect.csb", "1")
		self.arrow:setVisible(true)

		print(string.format(" arrow z order : %s", tostring(self.arrow:getGlobalZOrder()) ))
	end)))
end

function GuideLayer:onEnterTransitionFinish()
    printInfo("GuideLayer:onEnterTransitionFinish()")

    guideManager:setGuideType(true)
    guideManager:setMsgType(false)
    self:_print("ccc guide id ", self.data_.id)

    flurryLogEvent("guide", {guide_id = tostring(self.data_.id), type = "start"}, 2)

    local conf = CONF.GUIDANCE.get(self.data_.id)
    local rn = self:getResourceNode()
    local node = rn:getChildByName("node")
	
	-- Add wjj 20180605
	if( self.IS_DEBUG_LOG_1 ) then
		self:_print("## Lua GuideLayer conf: " .. tostring(conf) )
	end

    if conf.PERSON_COORDINATE then
    	node:setPosition(cc.p(conf.PERSON_COORDINATE[1], conf.PERSON_COORDINATE[2]))
    end

    if conf.PERSON_SIZE then
    	node:getChildByName("di"):setContentSize(cc.size(conf.PERSON_SIZE[1], conf.PERSON_SIZE[2]))
    end

    if conf.PERSON_TEXT_SIZE then
    	node:getChildByName("text"):setContentSize(cc.size(conf.PERSON_TEXT_SIZE[1], conf.PERSON_TEXT_SIZE[2]))
    end

    node:getChildByName("enemy_role"):setTexture("RoleImage/2.png")
   	if player:isInited() then
	    node:getChildByName("role"):setTexture("HeroImage/"..math.floor(player:getPlayerIcon()/100)..".png")
	end

    if conf.LUCENCY ~= nil then
		rn:getChildByName("bg"):setOpacity(tonumber(conf.LUCENCY))
	end

	-- Add wjj 20180605
	self:_print("## Lua GuideLayer conf.MESSAGE: " .. tostring(conf.MESSAGE) )

	if conf.MESSAGE then
		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent(conf.MESSAGE)
	end

    self.clip = cc.ClippingNode:create()  
	self.clip:setInverted(true)  
	self.clip:setAlphaThreshold(0.0)  
	self:addChild(self.clip)  
	  
	local op = 155
	if conf.LUCENCY ~= nil then
		op = tonumber(conf.LUCENCY)
	end

	local back = cc.LayerColor:create(cc.c4b(0, 0, 0, op))  
	back:setContentSize(cc.size(1136,768))
	self.clip:addChild(back)  

	self.stencil = cc.Sprite:create("ShipsScene/ui_bar_yellow_full.png")
	self.stencil:setAnchorPoint(cc.p(0.5,0.5))
	self.clip:setStencil(self.stencil) 
	local arrow_z_order = 2
	if conf.TYPE == 1 then
		self:_print("GuideLayer show arrow and circle!  " )
		self.arrow = require("app.ExResInterface"):getInstance():FastLoad("GuideLayer/sfx/effect.csb")
		-- local cursor = animManager:runAnimByCSB(self.arrow, "GuideLayer/sfx/effect.csb", "1")
		-- ADD WJJ 20180703
		-- delay show cursor
		self:DelayShowCuror()
	else
		self.arrow = require("app.ExResInterface"):getInstance():FastLoad("GuideLayer/sfx/Kuang/Kuang.csb")
		animManager:runAnimByCSB(self.arrow, "GuideLayer/sfx/Kuang/Kuang.csb", "1")

		-- ADD WJJ 20180801
		arrow_z_order = -10
	end

	
	-- self:addChild(self.arrow, 2)
	--ADD WJJ 20180703
	self:DelayAddCuror(arrow_z_order)
	
	self:resetStencil()

	self:resetInfo()

	-- Add wjj 20180605
	self:_print("## Lua GuideLayer resetStencil ")


	if conf.SAVE then
		guideManager:addGuideStep(conf.SAVE)
	end

	if conf.RED then
		rn:getChildByName("red"):setVisible(true)
		rn:getChildByName("red"):getChildByName("Sprite_1"):setScale(winSize.width/rn:getChildByName("red"):getChildByName("Sprite_1"):getContentSize().width, winSize.height/rn:getChildByName("red"):getChildByName("Sprite_1"):getContentSize().height)
		animManager:runAnimByCSB(rn:getChildByName("red"), "PlanetScene/sfx/shanping/shanping.csb", "1")
	end

	if conf.SPECIAL_EFFECTS then
		local node = require("app.ExResInterface"):getInstance():FastLoad(tostring(conf.SPECIAL_EFFECTS))
		animManager:runAnimOnceByCSB(node, tostring(conf.SPECIAL_EFFECTS), "1", function ( ... )
			if CONF.GUIDANCE.check(self.data_.id+1) then
				guideManager:createGuideLayer(self.data_.id+1)
			else
				if CONF.GUIDANCE.check((math.floor(self.data_.id/100)+1)*100+1) then
					if CONF.GUIDANCE.get((math.floor(self.data_.id/100)+1)*100+1).INTERFACE == conf.INTERFACE then
						guideManager:createGuideLayer((math.floor(self.data_.id/100)+1)*100+1)
					else
						self:getApp():removeTopView()
					end
				else
					self:getApp():removeTopView()
				end
			end
		end)
		rn:addChild(node)
	end

	if conf.PECTURE then
		rn:getChildByName("sp"):setVisible(true)
		rn:getChildByName("sp"):setTexture(conf.PECTURE)
	end
    -- 新手引导跳过
    local LastId = CONF.GUIDANCE.count()
    rn:getChildByName("btn_tiao"):addClickEventListener(function()

        local function func()
            local conf = CONF.GUIDANCE.get(LastId)
--		    guideManager:addGuideStep(conf.SAVE)
            guideManager:addGuideStep(self.data_.id)
            guideManager:createGuideLayer(LastId)
            app:pushToRootView("CityScene/CityScene", {pos = -1350})
	    end
        local str1 = CONF.STRING.get("whether_skip_guide").VALUE
        local str2 = CONF.STRING.get("skip_notes").VALUE
        local str = str1.."\n"..str2
	    local messageBox = require("util.MessageBox"):getInstance()
	    messageBox:reset(str, func)
    end)
    if self.data_.id >= 3 and self.data_.id < LastId then
        rn:getChildByName("btn_tiao"):setVisible(true)
    end

	if conf.GUIDANCE then
		if conf.GUIDANCE == 1 then
			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("moveToJinRes")
		elseif conf.GUIDANCE == 2 then
			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("moveToJinCity")
		end

	end

	if conf.STOP_TIEM then
		self:runAction(cc.Sequence:create(cc.DelayTime:create(conf.STOP_TIEM), cc.CallFunc:create(function ( ... )
			guideManager:addGuideLayer()
		end)))
	end

	if conf.INTERFACE == 1 then

		local function update(dt)
			-- Add wjj 20180605
			-- self:_print("## Lua GuideLayer local function update  " )
			if conf.BUILDING then
				-- Add wjj 20180605
				-- self:_print("## Lua GuideLayer local function update conf.BUILDING " .. tostring(conf.BUILDING) )
				-- Add wjj 20180605
				self:_print("## Lua GuideLayer local function update guideManager:getMsgType() " .. tostring(guideManager:getMsgType()) )
				if not guideManager:getMsgType() then
					-- Add wjj 20180605
					self:_print("## Lua GuideLayer local function update conf.BUILDING_OPERATION " .. tostring(conf.BUILDING_OPERATION) )
					local event = cc.EventCustom:new("changeCityPos")

					-- Add wjj 20180605
					self:_print("## Lua GuideLayer local function update event " .. tostring(event) )

					event.pos = CONF.EMainBuildingPos[conf.BUILDING]
					event.num = conf.BUILDING

					if conf.BUILDING_OPERATION then
						event.type = conf.BUILDING_OPERATION
					end

					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

					-- Add wjj 20180605
					self:_print("## Lua GuideLayer local function update conf.MESSAGE: " .. tostring(conf.MESSAGE) )
					-- if conf.MESSAGE then
					-- 	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent(conf.MESSAGE)
					-- end

					scheduler:unscheduleScriptEntry(schedulerEntry)
					if schedulerEntryIndex == 0 then
						schedulerEntryIndex = 1
						schedulerEntry = scheduler:scheduleScriptFunc(update,0.5,false)
					else
						schedulerEntryIndex = 0
					end

				end
			end
			-- 454 if end

			-- Add wjj 20180605
			if not guideManager:getMsgType() then
				-- self:_print("## Lua RELOCATED CODE  GuideLayer local function update conf.MESSAGE: " .. tostring(conf.MESSAGE) )
				if not (conf.MESSAGE == nil) then
					self:_print("## Lua dispatch!! conf.MESSAGE: " .. tostring(conf.MESSAGE) )
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent(conf.MESSAGE)
				end
			end

		end
		-- 454 update end
		schedulerEntry = scheduler:scheduleScriptFunc(update,0.01,false)
		self:_print("## Lua END      GuideLayer conf.INTERFACE == 1 " )
	end
	-- 449 if end

	-- Add wjj 20180605
	self:_print("## Lua GuideLayer EventListenerTouchOneByOne ")

	local listener = cc.EventListenerTouchOneByOne:create()

	local function onTouchBegan(touch, event)
		-- ADDED BY WJJ 20180606
		self:_print("GuideLayer onTouchBegan  ")
		self.touchHelper:SetTouchBeganTimeNow()

		if conf.STRING_KEY then
			return true
		else

			local ln = self.stencil:convertToNodeSpace(touch:getLocation())

			local s = self.stencil:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)

			if cc.rectContainsPoint(rect, ln) then

				listener:setSwallowTouches(false)
				self:_print("GuideLayer onTouchBegan setSwallowTouches ")
				return true
			end
		end

		return true
	end

	

	local function onTouchEnded( touch, event )
		
		-- ADDED BY WJJ 20180606
		local g_id = self.data_.id
		self:_print("GuideLayer onTouchEnded : self.data_.id: " .. tostring(g_id) )

		local isNoBug = require("app.views.GuideLayer.GuideLayer").touchHelper:OnFixBugGuide(g_id)
		if( isNoBug == false ) then
			self:_print("@@@@ GUIDE BUG!!!! THIS CLICK NOT WORK!")
			do return false end
		end

		if( IS_GUIDE_CLICK_TIME_LIMITED == true ) then
			self:_print("GuideLayer lastTouchBeganTime : " .. tostring(guideClickTimer.lastTouchBeganTime) )
			if( self.touchHelper:IsGuideClickTimeOK() == false ) then
				do return  end
			end
		end

		self:OnTouchEndNoBug( conf, listener, touch , false, g_id)
	end


	-- Add wjj 20180605
	self:_print("## Lua GuideLayer listener:setSwallowTouches ")


	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self) 

	if conf.EVENT == "visible" then
		local event = cc.EventCustom:new("guide_activate_building")
		event.buildingNum = conf.BUILDING
		cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
	end


	-- Add wjj 20180605
	self:_print("## Lua GuideLayer end function GuideLayer:onEnterTransitionFinish ")

end

function GuideLayer:onExitTransitionStart()
    printInfo("GuideLayer:onExitTransitionStart()")

    if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end
	schedulerEntryIndex = 0

	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("GuideOver")

    guideManager:setGuideType(false)

end
print( "###LUA Return GuideLayer.lua end" )
return GuideLayer