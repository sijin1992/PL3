print("~~~~ SystemGuideManager.lua line 1")
local animManager = require("app.AnimManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

-- Add wjj 20180806
-- if ( cc.exports.instance_systemGuideManager == nil ) then
	cc.exports.instance_systemGuideManager = systemGuideManager
-- end


local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local winSize = cc.Director:getInstance():getWinSize()

local scheduler = cc.Director:getInstance():getScheduler()

local SystemGuideLayer = class("SystemGuideLayer", cc.load("mvc").ViewBase)

SystemGuideLayer.RESOURCE_FILENAME = "GuideLayer/GuideLayer.csb"

SystemGuideLayer.NEED_ADJUST_POSITION = true

SystemGuideLayer.RESOURCE_BINDING = {
    --["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil
local schedulerEntryIndex = 0

function SystemGuideLayer:onCreate( data )
	print("~~~~ SystemGuideManager.lua line 33 onCreate")
	self.data_ = data
	cc.exports.instance_systemGuideManager = systemGuideManager
	cc.exports.instance_systemGuide_data = data
end

function SystemGuideLayer:onEnter()
    
    printInfo("SystemGuideLayer:onEnter()")




end

function SystemGuideLayer:onExit()
    
    printInfo("SystemGuideLayer:onExit()")
end

function SystemGuideLayer:resetStencil(id)

	local conf = CONF.SYSTEM_GUIDANCE.get(self.data_.id)

	local cur_size = self:getResourceNode():getContentSize()
	local cur_size_width = (winSize.width - cur_size.width)/2
	local cur_size_height = (winSize.height - cur_size.height)/2

	if conf.FRAME then
		self.stencil:setPosition(cc.p(conf.FRAME[1], conf.FRAME[2]))  		
	end

	if conf.SIZE then
		-- self.stencil:setContentSize(cc.size(conf.SIZE[1],conf.SIZE[2]))
		self.stencil:setScale(conf.SIZE[1]/self.stencil:getContentSize().width, conf.SIZE[2]/self.stencil:getContentSize().height)
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
	else
		self.stencil:setPosition(cc.p(self.stencil:getPositionX() + cur_size_width, self.stencil:getPositionY() + cur_size_height))
		self.arrow:setPosition(cc.p(self.arrow:getPositionX() + cur_size_width, self.arrow:getPositionY() + cur_size_height))
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
				print("resetStencil",col,g_city_scene_width,cur_size_width)
				if offsetX < g_city_scene_width - col then
					offsetX = g_city_scene_width - col
				elseif offsetX < 0 then
					offsetX = nil
				end
			end
		end		
	end
	print("resetStencil",offsetX)
	if offsetX then
		self.stencil:setPosition(cc.p(self.stencil:getPositionX() + offsetX, self.stencil:getPositionY()))
		self.arrow:setPosition(cc.p(self.arrow:getPositionX() + offsetX, self.arrow:getPositionY()))
	end
	print("setScreenPositionWin",self.stencil:getPositionX(),self.data_.id,cur_size_width,cur_size_height)
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

	print("SystemGuideLayer:resetStencil id=",self.data_.id)

	self.stencil:setPosition(cc.p(self.stencil:getPositionX() + (winSize.width - cur_size.width)/2 + offsetX, self.stencil:getPositionY() + (winSize.height - cur_size.height)/2))
	self.arrow:setPosition(cc.p(self.arrow:getPositionX() + (winSize.width - cur_size.width)/2 + offsetX, self.arrow:getPositionY() + (winSize.height - cur_size.height)/2))
]]
end

function SystemGuideLayer:resetInfo( ... )
	local conf = CONF.SYSTEM_GUIDANCE.get(self.data_.id)

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
		self.arrow:setVisible(false)

	else
		self.clip:setVisible(true)
		self.arrow:setVisible(true)

		if conf.STRING_KEY == nil then
			node:setVisible(false)
		end
	end
end

function SystemGuideLayer:onEnterTransitionFinish()
    printInfo("SystemGuideLayer:onEnterTransitionFinish()")

    systemGuideManager:setGuideType(true)
    systemGuideManager:setMsgType(false)


    print("aaa guide id",self.data_.id)
    local conf = CONF.SYSTEM_GUIDANCE.get(self.data_.id)

    local rn = self:getResourceNode()
    local node = rn:getChildByName("node")

    -- rn:getChildByName("btn_tiao"):addClickEventListener(function ( ... )
    -- 	print("dianji ")
    -- 	systemGuideManager:addGuideStep(self.data_.id)
    -- 	g_System_Guide_Id= 0
    -- 	self:getApp():removeViewByName("SystemGuideLayer/SystemGuideLayer")

    -- end)
    if conf.OPEN_GUIDANCE == 2 then
    	self:getApp():removeViewByName("SystemGuideLayer/SystemGuideLayer")
    	return
    end

    if conf.STRING_KEY then
	    local btn_close = ccui.Button:create("ChatLayer/cs.png", "ChatLayer/cs.png")
		btn_close:setPosition(cc.p(winSize.width - 270, 50))
		btn_close:setName("btn_close")
		btn_close:addClickEventListener(function ( ... )
			print("niasdnia")
			systemGuideManager:addGuideStep(self.data_.id)
	    	g_System_Guide_Id= 0
	    	self:getApp():removeViewByName("SystemGuideLayer/SystemGuideLayer")
		end)
		self:addChild(btn_close,100)

		local label = cc.Label:createWithTTF("跳过", "fonts/cuyabra.ttf", 24)
		label:setPosition(cc.p(30, 13.42))
		-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
		btn_close:addChild(label)

		local sptite = cc.Sprite:create("Common/ui2/guide_arrow.png")
		sptite:setPosition(cc.p(winSize.width - 300 + label:getContentSize().width + 10, 23))
		self:addChild(sptite)
	end

    if conf.DIALOGUE then
    	node:setPosition(cc.p(conf.DIALOGUE[1], conf.DIALOGUE[2]))
    end

    node:getChildByName("enemy_role"):setTexture("RoleImage/2.png")
    node:getChildByName("role"):setTexture("HeroImage/"..math.floor(player:getPlayerIcon()/100)..".png")

    if conf.LUCENCY ~= nil then
		rn:getChildByName("bg"):setOpacity(tonumber(conf.LUCENCY))
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

	if conf.TYPE == 1 then
		self.arrow = require("app.ExResInterface"):getInstance():FastLoad("GuideLayer/sfx/effect.csb")
		animManager:runAnimByCSB(self.arrow, "GuideLayer/sfx/effect.csb", "1")
	else
		self.arrow = require("app.ExResInterface"):getInstance():FastLoad("GuideLayer/sfx/Kuang/Kuang.csb")
		animManager:runAnimByCSB(self.arrow, "GuideLayer/sfx/Kuang/Kuang.csb", "1")
	end
	self:addChild(self.arrow, 2)

	if conf.SAVE then
		systemGuideManager:addGuideStep(conf.SAVE)
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
			systemGuideManager:addGuideLayer()
		end)))
	end

	self:resetStencil()

	self:resetInfo()

	if conf.INTERFACE == 1 then

		local function update(dt)

			if conf.BUILDING then
				if not systemGuideManager:getMsgType() then

					local event = cc.EventCustom:new("changeCityPos")
					event.pos = CONF.EMainBuildingPos[conf.BUILDING]
					event.num = conf.BUILDING
					if conf.BUILDING_OPERATION then
						event.type = conf.BUILDING_OPERATION
					end
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

					scheduler:unscheduleScriptEntry(schedulerEntry)
					if schedulerEntryIndex == 0 then
						schedulerEntry = scheduler:scheduleScriptFunc(update,0.5,false)
						schedulerEntryIndex = 1
					else
						schedulerEntryIndex = 0
					end


				end
			end

			if not systemGuideManager:getMsgType() then
				-- self:_print("## Lua RELOCATED CODE  GuideLayer local function update conf.MESSAGE: " .. tostring(conf.MESSAGE) )
				if not (conf.MESSAGE == nil) then
					self:_print("## Lua dispatch!! conf.MESSAGE: " .. tostring(conf.MESSAGE) )
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent(conf.MESSAGE)
				end
			end
		end
		schedulerEntry = scheduler:scheduleScriptFunc(update,0.1,false)

	end

	local listener = cc.EventListenerTouchOneByOne:create()

	local function onTouchBegan(touch, event)

		if conf.STRING_KEY and conf.TYPE == nil then
			return true
		else

			local ln = self.stencil:convertToNodeSpace(touch:getLocation())

			local s = self.stencil:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)

			if cc.rectContainsPoint(rect, ln) then

				listener:setSwallowTouches(false)
				return true
			end
		end

		return true
	end

	local function onTouchEnded( touch, event )
		print("aaaaaaaaaaaaaaaaa")
		if conf.INTERFACE == 1 then
			if conf.BUILDING then
				if not systemGuideManager:getMsgType() then
					listener:setSwallowTouches(true)
					return
				end
			end
		end
		
		---------------------------------------------
		-- ADD WJJ 20180806
		local g_id = self.data_.id
		local is_next = require("util.ExGuideBugHelper_SystemGuide"):getInstance():IsNextCursor(g_id)
		---------------------------------------------
		print("bbbbbbbbbbbbbbb",g_id,is_next)
		if conf.STRING_KEY and conf.TYPE == nil then
			-- ADD WJJ 20180806
			if( is_next ) then
				-- guideManager:addGuideLayer()
				systemGuideManager:doEvent(conf.EVENT, self.data_.id)
			end

		else

			local ln = self.stencil:convertToNodeSpace(touch:getLocation())

			local s = self.stencil:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)
			if cc.rectContainsPoint(rect, ln) then

				-- ADD WJJ 20180806
				if( is_next ) then
					systemGuideManager:doEvent(conf.EVENT, self.data_.id)
				end

			else
				listener:setSwallowTouches(true)
			end

			-- listener:setSwallowTouches(true)
		end

	end

	
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	cc.exports.g_activate_building = false 
end

function SystemGuideLayer:onExitTransitionStart()
    printInfo("SystemGuideLayer:onExitTransitionStart()")

    if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end
	schedulerEntryIndex = 0

    systemGuideManager:setGuideType(false)
end

return SystemGuideLayer