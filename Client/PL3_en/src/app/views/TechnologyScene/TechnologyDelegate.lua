local g_player = require("app.Player"):getInstance()
local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local TechnologyDelegate = class("TechnologyDelegate")

function TechnologyDelegate:ctor(owner)
	self.owner_ = owner


end

function TechnologyDelegate:getOwner(  )
	return self.owner_
end

function TechnologyDelegate:update( dt )
	local node = self:getOwner()
	local progress = node:getChildByName("progress")
	if progress and self.nextInfo_ and self.nextInfo_.begin_upgrade_time and self.nextInfo_.begin_upgrade_time > 0 then

		local now_time = g_player:getServerTime()

		local temp_id = tonumber(node:getName())
		local conf = CONF.TECHNOLOGY.get(self.nextInfo_.tech_id)
		local time = now_time - self.nextInfo_.begin_upgrade_time
		progress:setPercentage( time / conf.CD * 100 )

		local cd = conf.CD + g_player:getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kTechnology, 0, CONF.ETechTarget_3_Building.kCD)
		local diff = cd + self.nextInfo_.begin_upgrade_time - now_time
		local timeLabel = node:getChildByName("time")
		if timeLabel:isVisible() == true then
			timeLabel:setString(formatTime(diff))
		end
	end
end

function TechnologyDelegate:updateInfo(  )
	local node = self:getOwner()

	local temp_id = tonumber(node:getName())

	self.info_ = g_player:getUsedTechnologyByTemp(temp_id)
	
	self.techID_= self.info_ and self.info_.tech_id or temp_id

	local tempConf = CONF.TECHNOLOGY.check(self.techID_)
	if not tempConf then
		tempConf = CONF.TECHNOLOGY.get(self.techID_+1)
	end

	local nextConf = CONF.TECHNOLOGY.check(self.techID_+1)

	local function gray()
		if  nextConf and Tools.isEmpty(nextConf.PRE_TECHNOLOGY) == false then
			for i,v in ipairs(nextConf.PRE_TECHNOLOGY) do
				if v > 0 then
					local curTech= g_player:getUsedTechnologyByTemp(math.floor(v / 100) * 100)
					if curTech == nil then

						return false
					end
				end
			end
		end
		return true
	end


	local isTouchMe = false
	local function onTouchBegan(touch, event)
		
		local target = event:getCurrentTarget()
		
		local locationInNode = target:convertToNodeSpace(touch:getLocation())
		local s = target:getContentSize()
		local rect = cc.rect(0, 0, s.width, s.height)

		if cc.rectContainsPoint(rect, locationInNode) then
			isTouchMe = true
			return true
		end

		return false
	end

	local function onTouchMoved(touch, event)
		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			isTouchMe = false
		end
	end

	local function onTouchEnded(touch, event)
		if isTouchMe == true then
			
			local conf = CONF.TECHNOLOGY.check(self.techID_)
			local app = require("app.MyApp"):getInstance()
			if conf and conf.TECHNOLOGY_MAX_LEVEL == conf.TECHNOLOGY_LEVEL then
				app:addView2Top("TechnologyScene/TechnologyMaxLayer", {techID = self.techID_})
			else
				local temp_id = tonumber(node:getName())
				--print("touch:",temp_id)
				local data = {techID = self.techID_+1}

				local is_guide = false
				if guideManager:getGuideType() then
					is_guide = true
					app:removeTopView()
				end

				app:addView2Top("TechnologyScene/TechnologyDevelopLayer", data)

				if is_guide then
					guideManager:createGuideLayer(100)
				end

				if g_System_Guide_Id ~= 0 then
					systemGuideManager:createGuideLayer(g_System_Guide_Id)
				end

			end
		end
	end

	local eventDispatcher = node:getEventDispatcher()

	if self.frameListener_ == nil then
		self.frameListener_ = cc.EventListenerTouchOneByOne:create()
		self.frameListener_:setSwallowTouches(false)
		self.frameListener_:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
		self.frameListener_:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
		self.frameListener_:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
		eventDispatcher:addEventListenerWithSceneGraphPriority(self.frameListener_, node:getChildByName("frame"))
	end

	self.isCanDevelop_ = gray()

	local icon = node:getChildByName("icon")
	local pos = cc.p(icon:getPosition())
	icon:removeFromParent()

	if self.isCanDevelop_  == false then

		local gray = mc.EffectGreyScale:create()
		icon = mc.EffectSprite:create(string.format("TechnologyIcon/%d.png",tempConf.RES_ID))
		icon:setEffect(gray)

	else
		icon = cc.Sprite:create(string.format("TechnologyIcon/%d.png",tempConf.RES_ID))
	end

	icon:setName("icon")
	icon:setPosition(pos)
	node:addChild(icon)
	icon:setLocalZOrder(1)

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node:getChildByName("icon"))

	
	node:getChildByName("name"):setString(CONF.STRING.get(tempConf.TECHNOLOGY_NAME).VALUE)


	if node:getChildByName("progress") then
		node:getChildByName("progress"):removeFromParent()
	end

	if nextConf then
		self.nextInfo_ = g_player:getTechnologyByID(nextConf.ID)
	else
		self.nextInfo_ = nil
	end

	local tab = node:getChildByName("tab")
	local tabPos = cc.p(tab:getPosition())
	tab:removeFromParent()

	local time = node:getChildByName("time")
	local addition = node:getChildByName("addition")
	
	if self.nextInfo_ and self.nextInfo_.begin_upgrade_time and self.nextInfo_.begin_upgrade_time > 0 then

		tab = require("app.ExResInterface"):getInstance():FastLoad("TechnologyScene/UpgradeTab.csb")
		

		local progress = cc.ProgressTimer:create(cc.Sprite:create("TechnologyScene/progress.png"))
		progress:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
		progress:setPosition(icon:getPosition())
		progress:setName("progress")
		node:addChild(progress)

		local curLv = self.info_ and tempConf.TECHNOLOGY_LEVEL or 0

		tab:getChildByName("lv_cur"):setString(string.format("%d",curLv))
		tab:getChildByName("lv_next"):setString(string.format("%d",curLv + 1))

		time:setVisible(true)
		addition:setVisible(false)

		tab:getChildByName("state"):setString(CONF:getStringValue("upgrading"))

	else

		tab = require("app.ExResInterface"):getInstance():FastLoad("TechnologyScene/NormalTab.csb")

		local lv_cur = self.info_ and tempConf.TECHNOLOGY_LEVEL or 0

		tab:getChildByName("lv_cur"):setString(string.format("LV.%d",lv_cur))
		tab:getChildByName("lv_max"):setString(string.format("/%d",tempConf.TECHNOLOGY_MAX_LEVEL))

		if lv_cur == tempConf.TECHNOLOGY_MAX_LEVEL then
			tab:getChildByName("max"):setVisible(true)
			tab:getChildByName("item_icon"):setVisible(false)
			tab:getChildByName("item_num"):setVisible(false)
			
		else
			local itemConf  = CONF.ITEM.get(nextConf.ITEM_ID[1])
			if itemConf then
				tab:getChildByName("item_icon"):setTexture(string.format("ItemIcon/%d.png",itemConf.ICON_ID))
			end

			tab:getChildByName("item_num"):setString(formatRes(nextConf.ITEM_NUM[1]))
			tab:getChildByName("max"):setVisible(false)
		end

		time:setVisible(false)
		addition:setVisible(true)
	end

	tab:setPosition(tabPos)
	node:addChild(tab)
	tab:setName("tab")
end

return TechnologyDelegate