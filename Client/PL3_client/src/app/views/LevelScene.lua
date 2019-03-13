local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local talkManager = require("app.views.TalkLayer.TalkManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local LevelScene = class("LevelScene", cc.load("mvc").ViewBase)

LevelScene.RESOURCE_FILENAME = "LevelScene/LevelScene.csb"

LevelScene.RUN_TIMELINE = true

LevelScene.NEED_ADJUST_POSITION = true

LevelScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["left"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["right"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

local lt = nil

local time = 0.2

local labsStrPos = {Normal = {x = 11, y = 3},Select = {x = 16, y = 7}}

local cardMove = false

----------------------------------
-- WJJ 20180703

LevelScene.timeHelper = require("util.ExTimeHelper"):getInstance()


----------------------------------

function LevelScene:onCreate(data)
	self.data_ = data
end

function LevelScene:OnBtnClick(event)

	if event.name == "ended" and event.target:getName() == "close" then
		self:getApp():pushToRootView("ChapterScene", {})

		playEffectSound("sound/system/return.mp3")
	end

	if event.name == "ended" and event.target:getName() == "left" then

	    if self.selectIndex_ - 1 < 1 then
	        return
	    end
	    self.selectIndex_ = self.selectIndex_ - 1
	    cardMove = true
		self:runAction(cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(function ( ... )
			cardMove = false
		end)))

		playEffectSound("sound/system/move_map.mp3")

		if self.selectIndex_ == 1 then
			self:getResourceNode():getChildByName("left"):setVisible(false)
			self:getResourceNode():getChildByName("right"):setVisible(true)
		elseif self.selectIndex_ == table.getn(CONF.COPY.get(self.stage_).LEVEL_ID) then
			self:getResourceNode():getChildByName("left"):setVisible(true)
			self:getResourceNode():getChildByName("right"):setVisible(false)
		else
			self:getResourceNode():getChildByName("left"):setVisible(true)
			self:getResourceNode():getChildByName("right"):setVisible(true)
		end

		local children = self.panel_:getPanel():getChildren()

		for i,v in ipairs(children) do
			v:stopAllActions()

			if v:getTag() == self.selectIndex_ - 2  then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[1].x, self.iconInfo_[1].y)), cc.ScaleTo:create(time, self.iconInfo_[1].scale)))
				v:setLocalZOrder(8)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[1].shadow)
			elseif v:getTag() == self.selectIndex_ - 1 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[2].x, self.iconInfo_[2].y)), cc.ScaleTo:create(time, self.iconInfo_[2].scale)))
				v:setLocalZOrder(9)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[2].shadow)
			elseif v:getTag() == self.selectIndex_ then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[3].x, self.iconInfo_[3].y)), cc.ScaleTo:create(time, self.iconInfo_[3].scale)))
				v:setLocalZOrder(10)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[3].shadow)
			elseif v:getTag() == self.selectIndex_ + 1 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[4].x, self.iconInfo_[4].y)), cc.ScaleTo:create(time, self.iconInfo_[4].scale)))
				v:setLocalZOrder(9)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[4].shadow)
			elseif v:getTag() == self.selectIndex_ + 2 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[5].x, self.iconInfo_[5].y)), cc.ScaleTo:create(time, self.iconInfo_[5].scale)))
				v:setLocalZOrder(8)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[5].shadow)
			elseif v:getTag() < self.selectIndex_ - 2 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[1].x - v:getChildByName("icon"):getContentSize().width*v:getScale()*0.8*(self.selectIndex_-2-v:getTag()), self.iconInfo_[1].y)), cc.ScaleTo:create(time, self.iconInfo_[1].scale)))
				v:setLocalZOrder(7)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[1].shadow)
			elseif v:getTag() > self.selectIndex_ + 2 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[5].x + v:getChildByName("icon"):getContentSize().width*v:getScale()*0.8*(v:getTag()-self.selectIndex_-2), self.iconInfo_[5].y)), cc.ScaleTo:create(time, self.iconInfo_[5].scale)))
				v:setLocalZOrder(7)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[5].shadow)
			end

			if v:getTag() == self.selectIndex_ then
				animManager:runAnimByCSB(v:getChildByName("texiao"), "LevelScene/sfx/UI.csb",  "1")
				v:getChildByName("texiao"):setVisible(true)
				v:getChildByName("light"):setVisible(true)
				-- v:getChildByName("shadow"):setVisible(false)
			else
				v:getChildByName("texiao"):setVisible(false)
				v:getChildByName("light"):setVisible(false)
				-- v:getChildByName("shadow"):setVisible(true)
			end

		end

	end

	if event.name == "ended" and event.target:getName() == "right" then

	    if self.selectIndex_ + 1 > table.getn(self.panel_:getPanel():getChildren()) then
	        return
	    end
	    local indexx =  CONF.COPY.get(self.stage_).LEVEL_ID[self.selectIndex_ + 1]
	    if not indexx then
	    	return
	    end
	    local pre_copy = CONF.CHECKPOINT.get(indexx).PRE_COPYID
	    if pre_copy == 0 then
			self.selectIndex_ = self.selectIndex_ + 1
		else
			local star = player:getCopyStar(pre_copy)
			if star == 0 then
				tips:tips(CONF:getStringValue("finish pre copy"))
				return 
			else
				self.selectIndex_ = self.selectIndex_ + 1
			end
		end
	    cardMove = true
		self:runAction(cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(function ( ... )
			cardMove = false
		end)))

		playEffectSound("sound/system/move_map.mp3")

		if self.selectIndex_ == 1 then
			self:getResourceNode():getChildByName("left"):setVisible(false)
			self:getResourceNode():getChildByName("right"):setVisible(true)
		elseif self.selectIndex_ == table.getn(CONF.COPY.get(self.stage_).LEVEL_ID) then
			self:getResourceNode():getChildByName("left"):setVisible(true)
			self:getResourceNode():getChildByName("right"):setVisible(false)
		else
			self:getResourceNode():getChildByName("left"):setVisible(true)
			self:getResourceNode():getChildByName("right"):setVisible(true)
		end

		local children = self.panel_:getPanel():getChildren()

		for i,v in ipairs(children) do
			v:stopAllActions()

			if v:getTag() == self.selectIndex_ - 2  then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[1].x, self.iconInfo_[1].y)), cc.ScaleTo:create(time, self.iconInfo_[1].scale)))
				v:setLocalZOrder(8)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[1].shadow)
			elseif v:getTag() == self.selectIndex_ - 1 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[2].x, self.iconInfo_[2].y)), cc.ScaleTo:create(time, self.iconInfo_[2].scale)))
				v:setLocalZOrder(9)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[2].shadow)
			elseif v:getTag() == self.selectIndex_ then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[3].x, self.iconInfo_[3].y)), cc.ScaleTo:create(time, self.iconInfo_[3].scale)))
				v:setLocalZOrder(10)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[3].shadow)
			elseif v:getTag() == self.selectIndex_ + 1 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[4].x, self.iconInfo_[4].y)), cc.ScaleTo:create(time, self.iconInfo_[4].scale)))
				v:setLocalZOrder(9)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[4].shadow)
			elseif v:getTag() == self.selectIndex_ + 2 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[5].x, self.iconInfo_[5].y)), cc.ScaleTo:create(time, self.iconInfo_[5].scale)))
				v:setLocalZOrder(8)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[5].shadow)
			elseif v:getTag() < self.selectIndex_ - 2 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[1].x - v:getChildByName("icon"):getContentSize().width*v:getScale()*0.8*(self.selectIndex_-2-v:getTag()), self.iconInfo_[1].y)), cc.ScaleTo:create(time, self.iconInfo_[1].scale)))
				v:setLocalZOrder(7)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[1].shadow)
			elseif v:getTag() > self.selectIndex_ + 2 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[5].x + v:getChildByName("icon"):getContentSize().width*v:getScale()*0.8*(v:getTag()-self.selectIndex_-2), self.iconInfo_[5].y)), cc.ScaleTo:create(time, self.iconInfo_[5].scale)))
				v:setLocalZOrder(7)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[5].shadow)
			end

			if v:getTag() == self.selectIndex_ then
				animManager:runAnimByCSB(v:getChildByName("texiao"), "LevelScene/sfx/UI.csb",  "1")
				v:getChildByName("texiao"):setVisible(true)
				v:getChildByName("light"):setVisible(true)
				-- v:getChildByName("shadow"):setVisible(false)
			else
				v:getChildByName("texiao"):setVisible(false)
				v:getChildByName("light"):setVisible(false)
				-- v:getChildByName("shadow"):setVisible(true)
			end

		end
		
	end

end

function LevelScene:openTouchEvent( ... )
	local function onTouchBegan(touch, event)

		local target = event:getCurrentTarget()
		
		local locationInNode = target:convertToNodeSpace(touch:getLocation())
		local s = target:getContentSize()
		local rect = cc.rect(0, 0, s.width, s.height)
		
		if cc.rectContainsPoint(rect, locationInNode) then

			return true
		end

		return false
	end

	local function onTouchMoved(touch, event)

		local diff = touch:getDelta()
		local children = self.panel_:getPanel():getChildren()

		local index = self.panel_:getHorizontalMidElementIndex()

		local midC = self.panel_:getPanel():getChildByTag(index)
		local disX = midC:convertToWorldSpace(cc.p(0,0)).x - cc.Director:getInstance():getWinSize().width/2
		
		for i,v in ipairs(children) do

			if v:getTag() == index - 2 or v:getTag() == index + 2 then
				v:setScale(self.iconInfo_[1].scale)
				v:setLocalZOrder(8)
			elseif v:getTag() == index - 1 or v:getTag() == index + 1 then
				v:setScale(self.iconInfo_[2].scale)
				v:setLocalZOrder(9)
			elseif v:getTag() == index then
				v:setScale(self.iconInfo_[3].scale)
				v:setLocalZOrder(10)
			else
				v:setScale(self.iconInfo_[5].scale)
				v:setLocalZOrder(7)	
			end


			v:setPositionX(v:getPositionX() + diff.x)
		end
	
	end

	local function onTouchEnded(touch, event)

		local children = self.panel_:getPanel():getChildren()

		local index = self.panel_:getHorizontalMidElementIndex()

		for i,v in ipairs(children) do

			if v:getTag() == index - 2  then
				v:setPositionX(self.iconInfo_[1].x)
				v:setScale(self.iconInfo_[1].scale)
				v:setLocalZOrder(8)
			elseif v:getTag() == index - 1 then
				v:setPositionX(self.iconInfo_[2].x)
				v:setScale(self.iconInfo_[2].scale)
				v:setLocalZOrder(9)
			elseif v:getTag() == index then
				v:setPositionX(self.iconInfo_[3].x)
				v:setScale(self.iconInfo_[3].scale)
				v:setLocalZOrder(10)
			elseif v:getTag() == index + 1 then
				v:setPositionX(self.iconInfo_[4].x)
				v:setScale(self.iconInfo_[4].scale)
				v:setLocalZOrder(9)
			elseif v:getTag() == index + 2 then
				v:setPositionX(self.iconInfo_[5].x)
				v:setScale(self.iconInfo_[5].scale)
				v:setLocalZOrder(8)
			elseif v:getTag() < index - 2 then
				v:setScale(self.iconInfo_[1].scale)
				v:setPositionX(self.iconInfo_[1].x - v:getChildByName("icon"):getContentSize().width*v:getScale()*0.8*(index-2-v:getTag()))
				v:setLocalZOrder(7)
			elseif v:getTag() > index + 2 then
				v:setScale(self.iconInfo_[5].scale)
				v:setPositionX(self.iconInfo_[5].x + v:getChildByName("icon"):getContentSize().width*v:getScale()*0.8*(v:getTag()-index-2))
				v:setLocalZOrder(7)
			end

		end
		
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.panel_:getPanel())

end

function LevelScene:openTouchEvent2()
	local function onTouchBegan(touch, event)

		local target = event:getCurrentTarget()
		lt = touch:getLocation()
		
		local locationInNode = target:convertToNodeSpace(touch:getLocation())
		local s = target:getContentSize()
		local rect = cc.rect(0, 0, s.width, s.height)

		if cardMove then
			return false
		end

		if guideManager:getGuideType() then
			return false
		end
		
		if cc.rectContainsPoint(rect, locationInNode) then

			return true
		end

		return false
	end


	local function onTouchEnded(touch, event)



		local location = touch:getLocation()
		local target = event:getCurrentTarget()

		if location.x - lt.x < 0 then
			if self.selectIndex_ + 1 > table.getn(self.panel_:getPanel():getChildren()) then
				return
			end

			local node
			for i,v in ipairs(target:getChildren()) do
				if v:getTag() == self.selectIndex_ + 1 then
					node = v
				end
			end
			local pre_copy = CONF.CHECKPOINT.get(node:getChildByName("icon"):getTag()).PRE_COPYID
			if pre_copy == 0 then
				self.selectIndex_ = self.selectIndex_ + 1
			else
				local star = player:getCopyStar(pre_copy)
				if star == 0 then
					return 
				else
					self.selectIndex_ = self.selectIndex_ + 1
				end
			end
		elseif location.x - lt.x > 0 then
			if self.selectIndex_ - 1 < 1 then
				return
			end
			self.selectIndex_ = self.selectIndex_ - 1
		end

		cardMove = true
		self:runAction(cc.Sequence:create(cc.DelayTime:create(time), cc.CallFunc:create(function ( ... )
			cardMove = false
		end)))

		playEffectSound("sound/system/move_map.mp3")

		if self.selectIndex_ == 1 then
			self:getResourceNode():getChildByName("left"):setVisible(false)
			self:getResourceNode():getChildByName("right"):setVisible(true)
		elseif self.selectIndex_ == table.getn(CONF.COPY.get(self.stage_).LEVEL_ID) then
			self:getResourceNode():getChildByName("left"):setVisible(true)
			self:getResourceNode():getChildByName("right"):setVisible(false)
		else
			self:getResourceNode():getChildByName("left"):setVisible(true)
			self:getResourceNode():getChildByName("right"):setVisible(true)
		end

		local children = self.panel_:getPanel():getChildren()

		for i,v in ipairs(children) do
			v:stopAllActions()

			if v:getTag() == self.selectIndex_ - 2  then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[1].x, self.iconInfo_[1].y)), cc.ScaleTo:create(time, self.iconInfo_[1].scale)))
				v:setLocalZOrder(8)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[1].shadow)
			elseif v:getTag() == self.selectIndex_ - 1 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[2].x, self.iconInfo_[2].y)), cc.ScaleTo:create(time, self.iconInfo_[2].scale)))
				v:setLocalZOrder(9)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[2].shadow)
			elseif v:getTag() == self.selectIndex_ then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[3].x, self.iconInfo_[3].y)), cc.ScaleTo:create(time, self.iconInfo_[3].scale)))
				v:setLocalZOrder(10)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[3].shadow)
			elseif v:getTag() == self.selectIndex_ + 1 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[4].x, self.iconInfo_[4].y)), cc.ScaleTo:create(time, self.iconInfo_[4].scale)))
				v:setLocalZOrder(9)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[4].shadow)
			elseif v:getTag() == self.selectIndex_ + 2 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[5].x, self.iconInfo_[5].y)), cc.ScaleTo:create(time, self.iconInfo_[5].scale)))
				v:setLocalZOrder(8)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[5].shadow)
			elseif v:getTag() < self.selectIndex_ - 2 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[1].x - v:getChildByName("icon"):getContentSize().width*v:getScale()*0.8*(self.selectIndex_-2-v:getTag()), self.iconInfo_[1].y)), cc.ScaleTo:create(time, self.iconInfo_[1].scale)))
				v:setLocalZOrder(7)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[1].shadow)
			elseif v:getTag() > self.selectIndex_ + 2 then
				v:runAction(cc.Spawn:create(cc.MoveTo:create(time, cc.p(self.iconInfo_[5].x + v:getChildByName("icon"):getContentSize().width*v:getScale()*0.8*(v:getTag()-self.selectIndex_-2), self.iconInfo_[5].y)), cc.ScaleTo:create(time, self.iconInfo_[5].scale)))
				v:setLocalZOrder(7)
				v:getChildByName("mask"):setOpacity(self.iconInfo_[5].shadow)
			end

			if v:getTag() == self.selectIndex_ then
				print("@@@@ GUIDE  LevelScene 303 ")
				animManager:runAnimByCSB(v:getChildByName("texiao"), "LevelScene/sfx/UI.csb",  "1")
				v:getChildByName("texiao"):setVisible(true)
				v:getChildByName("light"):setVisible(true)
				-- v:getChildByName("shadow"):setVisible(false)
			else
				v:getChildByName("texiao"):setVisible(false)
				v:getChildByName("light"):setVisible(false)
				-- v:getChildByName("shadow"):setVisible(true)
			end

		end
			
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.panel_:getPanel())
end

function LevelScene:resetPanel(stage)
	self.selectIndex_ = self.data_.index

	local rn = self:getResourceNode()

	if self.selectIndex_ == 1 then
		rn:getChildByName("left"):setVisible(false)
		rn:getChildByName("right"):setVisible(true)
	elseif self.selectIndex_ == table.getn(CONF.COPY.get(self.stage_).LEVEL_ID) then
		rn:getChildByName("left"):setVisible(true)
		rn:getChildByName("right"):setVisible(false)
	else
		rn:getChildByName("left"):setVisible(true)
		rn:getChildByName("right"):setVisible(true)
	end

	for i,v in ipairs(self.svd_:getScrollView():getChildren()) do
		if v:getChildByName("icon"):getTag() == stage then
			v:getChildByName("icon"):setOpacity(255)
			v:getChildByName("text"):setTextColor(cc.c4b(255, 244, 198, 255))
			-- v:getChildByName("text"):enableShadow(cc.c4b(255, 244, 198, 255),cc.size(0.5,0.5))
			v:getChildByName("back"):setVisible(true)
			v:setLocalZOrder(9)

			-- rn:getChildByName("top_back_left"):setPositionX(v:getChildByName("back"):convertToWorldSpace(cc.p(0,0)).x)
			-- rn:getChildByName("top_back_right"):setPositionX(v:getChildByName("back"):convertToWorldSpace(cc.p(0,0)).x + v:getChildByName("back"):getContentSize().width)
		else
			v:getChildByName("icon"):setOpacity(0)
			v:getChildByName("text"):setTextColor(cc.c4b(255, 255, 255, 255))
			-- v:getChildByName("text"):enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
			v:getChildByName("back"):setVisible(false)
			v:setLocalZOrder(10)
		end
	end

	self.panel_:clear()
	local conf = CONF.COPY.get(stage)
	local show = false
	for i=1,3 do
		if conf["SCORE"..i] <= player:getStageStar(conf.ID) then
			if not player:getStageReward(conf.ID)[i] then
				show = true
			end
		end
	end
	self.svd_:getScrollView():getChildByTag(stage):getChildByName("point"):setVisible(show)
	----star

	local star = 0
	for i,v in ipairs(conf.LEVEL_ID) do
		local num = player:getCopyStar(v)
		star = star + num
	end

	rn:getChildByName("level_star"):setString(star)

	local p_conf = CONF.PLANET.get(self.data_.area)

	local star_now = 0
	for i,v in ipairs(CONF.AREA.get(conf.AREA).SIMPLE_COPY_ID) do
		for i2,v2 in ipairs(CONF.COPY.get(v).LEVEL_ID) do
			local num = player:getCopyStar(v2)
			star_now = star_now + num
		end
	end

	rn:getChildByName("star_now_num"):setString(star_now)
	rn:getChildByName("star_max_num"):setString("/"..p_conf.OPEN_VALUE)

	if star_now < p_conf.OPEN_VALUE then
		rn:getChildByName("star_now_num"):setTextColor(cc.c4b(255, 0, 0, 255))
		-- rn:getChildByName("star_now_num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
	else
		rn:getChildByName("star_now_num"):setTextColor(cc.c4b(33, 255, 70, 255))
		-- rn:getChildByName("star_now_num"):enableShadow(cc.c4b(33, 255, 70, 255),cc.size(0.5,0.5))
	end

	-- local sp = self:getResourceNode():getChildByName("star_progress")
	-- local star_progress = require("util.ScaleProgressDelegate"):create(sp, sp:getTag())
	-- star_progress:setPercentage(star_now/star_max*100)

	rn:getChildByName("star_progress"):setVisible(false)

	if rn:getChildByName("xq_progress") then
		rn:getChildByName("xq_progress"):removeFromParent()
	end

	--progress

	-- if p_conf.OPEN_TYPE == 1 then

	-- 	rn:getChildByName("tongguan"):setVisible(false)
	-- 	rn:getChildByName("ui_icon_start_48"):setVisible(true)
	-- 	rn:getChildByName("star_now_num"):setVisible(true)
	-- 	rn:getChildByName("star_max_num"):setVisible(true)

	-- 	-- if self.ani_ then
	-- 	-- 	local bs = cc.size(172, 61)
	-- 	-- 	local cap = cc.rect(0,0,20,20)
	-- 	-- 	local progress = require("util.ClippingScaleProgressDelegate"):create("LevelScene/ui/anniu_pstatus_progress.png", 173, {capinsets = cap, bg_size = bs, lightLength = 0, bg_texture = "LevelScene/ui/anniu_pstatus_progress.png"})

	-- 	-- 	rn:addChild(progress:getClippingNode())
	-- 	-- 	progress:getClippingNode():setPosition(cc.p(rn:getChildByName("star_progress"):getPosition()))

	-- 	-- 	local p = star_now/p_conf.OPEN_VALUE*100
	-- 	-- 	if p > 100 then
	-- 	-- 		p = 100
	-- 	-- 	end

	-- 	-- 	progress:setPercentage(p)
	-- 	-- 	progress:getClippingNode():setName("xq_progress")
	-- 	-- end
	-- elseif p_conf.OPEN_TYPE == 2 then

	-- 	rn:getChildByName("tongguan"):setString(CONF:getStringValue("need finish copy").." "..CONF:getStringValue(CONF.CHECKPOINT.get(p_conf.OPEN_VALUE).NAME_ID))

	-- 	rn:getChildByName("tongguan"):setVisible(true)
	-- 	rn:getChildByName("ui_icon_start_48"):setVisible(false)
	-- 	rn:getChildByName("star_now_num"):setVisible(false)
	-- 	rn:getChildByName("star_max_num"):setVisible(false)

	-- 	-- if self.ani_ then
	-- 	-- 	local bs = cc.size(172, 61)
	-- 	-- 	local cap = cc.rect(0,0,20,20)
	-- 	-- 	local progress = require("util.ClippingScaleProgressDelegate"):create("LevelScene/ui/anniu_pstatus_progress.png", 173, {capinsets = cap, bg_size = bs, lightLength = 0, bg_texture = "LevelScene/ui/anniu_pstatus_progress.png"})

	-- 	-- 	rn:addChild(progress:getClippingNode())
	-- 	-- 	progress:getClippingNode():setPosition(cc.p(rn:getChildByName("star_progress"):getPosition()))

	-- 	-- 	if player:getCopyFinish(p_conf.OPEN_VALUE) then
	-- 	-- 		progress:setPercentage(100)
	-- 	-- 	else
	-- 	-- 		progress:setPercentage(0)
	-- 	-- 	end
			
	-- 	-- 	progress:getClippingNode():setName("xq_progress")
	-- 	-- end
	-- elseif p_conf.OPEN_TYPE == 3 then
	-- 	rn:getChildByName("tongguan"):setVisible(false)
	-- 	rn:getChildByName("ui_icon_start_48"):setVisible(false)
	-- 	rn:getChildByName("star_now_num"):setVisible(false)
	-- 	rn:getChildByName("star_max_num"):setVisible(false)

	-- 	-- if self.ani_ then
	-- 	-- 	local bs = cc.size(172, 61)
	-- 	-- 	local cap = cc.rect(0,0,20,20)
	-- 	-- 	local progress = require("util.ClippingScaleProgressDelegate"):create("LevelScene/ui/anniu_pstatus_progress.png", 173, {capinsets = cap, bg_size = bs, lightLength = 0, bg_texture = "LevelScene/ui/anniu_pstatus_progress.png"})

	-- 	-- 	rn:addChild(progress:getClippingNode())
	-- 	-- 	progress:getClippingNode():setPosition(cc.p(rn:getChildByName("star_progress"):getPosition()))

	-- 	-- 	progress:setPercentage(100)
		  
	-- 	-- 	progress:getClippingNode():setName("xq_progress")
	-- 	-- end
	-- end

	-- if player:getLevel() < CONF.FUNCTION_OPEN.get("star_open").GRADE or self.data_.area == 1 then
	-- 	rn:getChildByName("tongguan"):setVisible(false)
	-- 	rn:getChildByName("ui_icon_start_48"):setVisible(false)
	-- 	rn:getChildByName("star_now_num"):setVisible(false)
	-- 	rn:getChildByName("star_max_num"):setVisible(false)
	-- end

	rn:getChildByName("Text_7"):setLocalZOrder(2)
	--鏄熸槦

	self.getReward = player:getStageReward(self.stage_)

	for i=1,3 do
		rn:getChildByName("text_"..i):setString(conf["SCORE"..i])
		rn:getChildByName("stage_"..i):setTag(i)
	end

	for i=1,3 do
		if tonumber(rn:getChildByName(string.format("text_%d", i)):getString()) > player:getStageStar(conf.ID) then
			
			animManager:runAnimByCSB(rn:getChildByName(string.format("star_%d", i)), "StageScene/sfx/UI_xingxing.csb",  "grey")
			rn:getChildByName("haveGet"..i):setVisible(false);
		else

			rn:getChildByName("haveGet"..i):setVisible(true);
			if self.getReward[i] == false then
				animManager:runAnimByCSB(rn:getChildByName(string.format("star_%d", i)), "StageScene/sfx/UI_xingxing.csb",  "run")
				rn:getChildByName("haveGet"..i):setString(CONF:getStringValue("unclaimed"))
			else
				animManager:runAnimByCSB(rn:getChildByName(string.format("star_%d", i)), "StageScene/sfx/UI_xingxing.csb",  "white")
				rn:getChildByName("haveGet"..i):setString(CONF:getStringValue("has_get"))
			end
		end

		rn:getChildByName(string.format("star_%d", i)):setScale(1.2)
   
	end

	--鑾峰彇鏉?
	-- self:getResourceNode():getChildByName("loadingBar"):setScale9Enabled(true)
	local lb = rn:getChildByName("loading_bar")
	local loadingBar = require("util.ScaleProgressDelegate"):create(lb, lb:getTag())

	local index = player:getStageStar(conf.ID) - tonumber(conf.SCORE1)
	if index <= 0 then
		loadingBar:setPercentage(0)
	else
		loadingBar:setPercentage((index/(conf.SCORE3-conf.SCORE1))*100)
	end

	if index >= 0 then
		local jindutiao = rn:getChildByName("jindutiao")
		jindutiao:setPositionX(rn:getChildByName("stage_1"):getPositionX() + (index/(conf.SCORE3-conf.SCORE1))*100*3.6-8)
		jindutiao:setVisible(true)
		jindutiao:setLocalZOrder(2)

		animManager:runAnimByCSB(jindutiao, "StageScene/sfx/UI_jindutiao.csb",  "1")

	else

		local jindutiao = rn:getChildByName("jindutiao")
		jindutiao:setVisible(false)

	end

	---

	for i,v in ipairs(conf.LEVEL_ID) do
		local copy_conf = CONF.CHECKPOINT.get(v)

		-- local num = copy_conf.RES_COPY%5
		-- if num == 0 then
		--     num = 5
		-- end

		local node = require("app.ExResInterface"):getInstance():FastLoad("LevelScene/copy_card.csb")
		node:getChildByName("icon"):loadTexture("LevelIcon/"..copy_conf.RES_COPY..".png")
		node:getChildByName("icon"):setTag(v)
		node:setTag(i)
		node:getChildByName("copy_name"):setString(CONF:getStringValue(copy_conf.NAME_ID))
		node:getChildByName("lv_num"):setString(copy_conf.LEVEL)
		node:getChildByName("solo"):setString(CONF:getStringValue("solo"))

		if player:getCopyStar(v) > 0 then
			node:getChildByName("finish"):setString(CONF:getStringValue("complete"))
		else
			node:getChildByName("finish"):setString(CONF:getStringValue("target"))
		end
		node:getChildByName("tili_num"):setString(copy_conf.STRENGTH)

		local isBoss = false
		for i2,v2 in ipairs(copy_conf.MONSTER_LIST) do
			if v2 < 0 then
				isBoss = true
				break
			end
		end

		if not isBoss then
			local _ico = node:getChildByName("boss_icon")
			if( _ico ~= nil ) then
				_ico:removeFromParent()
			end
			-- node:getChildByName("boss_bg"):removeFromParent()
		end

		if copy_conf.START_NUM == 3 then
			if node:getChildByName("star_4") then
				node:getChildByName("star_4"):removeFromParent()
			end
		end

		local star_num = player:getCopyStar(v)
		if star_num == 0 then
			for m=1,copy_conf.START_NUM do
				node:getChildByName("star_"..m):setTexture("LevelScene/ui/star_outline.png")
				node:getChildByName("star_"..m):setScale(1)
			end
		else
			for m=1,star_num do
                if node:getChildByName("star_"..m) then
				    node:getChildByName("star_"..m):setTexture("Common/ui/ui_star_light.png")
				    node:getChildByName("star_"..m):setScale(0.5)
                end
			end

			for n=star_num+1,copy_conf.START_NUM do
				node:getChildByName("star_"..n):setTexture("LevelScene/ui/star_outline.png")
				node:getChildByName("star_"..n):setScale(1)
			end
		end

		if i == self.selectIndex_ then
			print("@@@@ GUIDE  LevelScene 606 ")
			node:setPosition(cc.p(self.iconInfo_[3].x, self.iconInfo_[3].y))
			node:setScale(self.iconInfo_[3].scale)
			node:getChildByName("mask"):setOpacity(self.iconInfo_[3].shadow)
			
			animManager:runAnimByCSB(node:getChildByName("texiao"), "LevelScene/sfx/UI.csb",  "1")
		elseif i == self.selectIndex_ + 1 then
			node:setPosition(cc.p(self.iconInfo_[4].x, self.iconInfo_[4].y))
			node:setScale(self.iconInfo_[4].scale)
			node:getChildByName("mask"):setOpacity(self.iconInfo_[4].shadow)
		elseif i == self.selectIndex_ + 2 then
			node:setPosition(cc.p(self.iconInfo_[5].x, self.iconInfo_[5].y))
			node:setScale(self.iconInfo_[5].scale)
			node:getChildByName("mask"):setOpacity(self.iconInfo_[5].shadow)
		elseif i == self.selectIndex_ - 1 then
			node:setPosition(cc.p(self.iconInfo_[2].x, self.iconInfo_[2].y))
			node:setScale(self.iconInfo_[2].scale)
			node:getChildByName("mask"):setOpacity(self.iconInfo_[2].shadow)
		elseif i == self.selectIndex_ - 2 then
			node:setPosition(cc.p(self.iconInfo_[1].x, self.iconInfo_[1].y))
			node:setScale(self.iconInfo_[1].scale)
			node:getChildByName("mask"):setOpacity(self.iconInfo_[1].shadow)
		elseif i > self.selectIndex_ + 2 then
			node:setPosition(cc.p(self.iconInfo_[5].x + node:getChildByName("icon"):getContentSize().width*node:getScale()*0.8*(node:getTag()-self.selectIndex_-2), self.iconInfo_[5].y))
			node:setScale(self.iconInfo_[5].scale)
			node:getChildByName("mask"):setOpacity(self.iconInfo_[5].shadow)
		elseif i < self.selectIndex_ - 2 then
			node:setPosition(cc.p(self.iconInfo_[1].x - node:getChildByName("icon"):getContentSize().width*node:getScale()*0.8*(self.selectIndex_-2-node:getTag()), self.iconInfo_[1].y))
			node:setScale(self.iconInfo_[1].scale)
			node:getChildByName("mask"):setOpacity(self.iconInfo_[1].shadow)
		end
		

		if i == self.selectIndex_ then
			node:setLocalZOrder(10)
			node:getChildByName("light"):setVisible(true)
			-- node:getChildByName("shadow"):setVisible(false)
			node:getChildByName("texiao"):setVisible(true)
		elseif i == self.selectIndex_ + 1 or i == self.selectIndex_ - 1  then
			node:setLocalZOrder(9)
			node:getChildByName("light"):setVisible(false)
			-- node:getChildByName("shadow"):setVisible(true)
			node:getChildByName("texiao"):setVisible(false)
		elseif i == self.selectIndex_ + 2 or i == self.selectIndex_ - 2 then
			node:setLocalZOrder(8)
			node:getChildByName("light"):setVisible(false)
			-- node:getChildByName("shadow"):setVisible(true)
			node:getChildByName("texiao"):setVisible(false)
		else
			node:setLocalZOrder(7)
			node:getChildByName("light"):setVisible(false)
			-- node:getChildByName("shadow"):setVisible(true)
			node:getChildByName("texiao"):setVisible(false)
		end



		--
		local isTouchMe = false

		local function onTouchBegan(touch, event)

			if cardMove then
				return false
			end

			local target = event:getCurrentTarget()
			
			local locationInNode = target:convertToNodeSpace(touch:getLocation())
			local s = target:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)
			
			if cc.rectContainsPoint(rect, locationInNode) then
				isTouchMe = true

				if target:getParent():getLocalZOrder() == 10 then 
					target:getParent():stopAllActions()
					-- target:getParent():setScale(0.8)
					target:getParent():runAction(cc.ScaleTo:create(0.1, 0.8))
				end

				return true
			end

			return false
		end

		local function onTouchMoved(touch, event)

			local diff = touch:getDelta()
			if math.abs(diff.x) < g_click_delta and math.abs(diff.y) < g_click_delta then
				
			elseif player:getGuideStep() > CONF.GUIDANCE.count() then -- 修复进入副本的新手引导卡住的BUG
				isTouchMe = false
			end
			
		end

		local function onTouchEnded(touch, event)
			local target = event:getCurrentTarget()

			if isTouchMe == true then     
				
				if target:getParent():getLocalZOrder() == 10 then 
					target:getParent():runAction(cc.Sequence:create(cc.ScaleTo:create(0.1, 1)))
					target:runAction(cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function ( ... )
						-- self.data_.go = "copy"
						-- self:getApp():pushToRootView("CopyScene/CopyScene", {copy_id = target:getTag()})
						self:createTipsNode(target:getTag())
						if guideManager:getGuideType() then
							guideManager:doEvent("touch2")
						end
					end)))
					playEffectSound("sound/system/choose_map.mp3")
				end
			else
				-- target:getParent():setScale(1)

				if target:getParent():getLocalZOrder() == 10 then 
					target:getParent():runAction(cc.ScaleTo:create(0.1, 1))
				end

			end
		end


		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(false)
		listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
		listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
		listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
		local eventDispatcher = self.panel_:getPanel():getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node:getChildByName("icon"))


		self.panel_:addElement(node, nil)
	end

	self:resetTalk()
end

function LevelScene:onEnter()
  
	printInfo("LevelScene:onEnter()")

end

function LevelScene:onExit()
	
	printInfo("LevelScene:onExit()")
end

function LevelScene:resetTalk( sender )
	
	-- if guideManager:getGuideType() then
	-- 	return
	-- end

	talkManager:addTalkLayer(2, self.stage_)

end

function LevelScene:createFightAllNode( ... )

	local conf = CONF.AREA.get(self.data_.tongguan.index)
	local next_conf = nil

	if self.data_.tongguan.index < 5 then
		next_conf = CONF.AREA.get(self.data_.tongguan.index+1)
	end

	local node = require("app.ExResInterface"):getInstance():FastLoad("LevelScene/fight_all.csb")


	node:getChildByName("tongguan_text"):setString(CONF:getStringValue("tongguan"))

	node:getChildByName("next_qu"):setString(CONF:getStringValue("next_qu"))

	node:getChildByName("qu_name"):setString(CONF:getStringValue(conf.NAME_ID))

	node:getChildByName("tong_all"):setString(CONF:getStringValue("tong_all"))

	if next_conf then
		node:getChildByName("next_qu_name"):setString(CONF:getStringValue(next_conf.NAME_ID))
		node:getChildByName("qu_ins"):setString(CONF:getStringValue(next_conf.INTRODUCE_ID))

		node:getChildByName("sc_btkuang_3"):setPositionX(node:getChildByName("next_qu_name"):getPositionX()+node:getChildByName("next_qu_name"):getContentSize().width + 10)
		node:getChildByName("card"):setTexture("LevelIcon/"..CONF.CHECKPOINT.get(CONF.COPY.get(next_conf.SIMPLE_COPY_ID[1]).LEVEL_ID[1]).RES_COPY..".png")
	else
		node:getChildByName("next_qu_name"):setVisible(false)
		node:getChildByName("qu_ins"):setVisible(false)
		node:getChildByName("sc_btkuang_3"):setVisible(false)
		node:getChildByName("card"):setVisible(false)
		node:getChildByName("sc_btkuang_3_0"):setVisible(false)
		node:getChildByName("next_qu"):setVisible(false)
		node:getChildByName("sc_gk_bottom_7"):setVisible(false)

		node:getChildByName("tong_all"):setVisible(true)
	end

	node:getChildByName("go"):getChildByName("text"):setString(CONF:getStringValue("go"))
	node:getChildByName("go"):addClickEventListener(function ( ... )
		self:getApp():pushToRootView("ChapterScene", {})
	end)

	node:getChildByName("back"):setSwallowTouches(true)
	node:getChildByName("back"):addClickEventListener(function ( ... )
		node:removeFromParent()
	end)

	node:getChildByName("bg"):setSwallowTouches(true)
	node:getChildByName("bg"):addClickEventListener(function ( ... )
		-- body
	end)

	tipsAction(node, nil, function ( ... )
		node:getChildByName("back"):setTag(1)
	end)

	node:setPosition(cc.exports.VisibleRect:center())

	self:addChild(node)

end

function LevelScene:createTipsNode( copy_id )
	print( "@@@ LevelScene createTipsNode" )
	local conf = CONF.CHECKPOINT.get(copy_id)

	local node = require("app.ExResInterface"):getInstance():FastLoad("LevelScene/copy_ins.csb")

	node:getChildByName("close"):addClickEventListener(function ( ... )
		node:removeFromParent()
	end)
    node:getChildByName("my_fight"):setString(CONF:getStringValue("my_forms_2"))
    node:getChildByName("enemy_fight"):setString(CONF:getStringValue("FightRange_1_4"))
	node:getChildByName("level_num"):setString(conf.LEVEL)
	node:getChildByName("level_name"):setString(CONF.STRING.get(conf.NAME_ID).VALUE)
	node:getChildByName("level_ins"):setString(CONF.STRING.get(conf.INTRODUCE_ID).VALUE)
--	node:getChildByName("level_fight"):setString(CONF.STRING.get("dungeonPower").VALUE)

    local power = GetCurrentShipsPower()
	node:getChildByName("level_fight_mynum"):setString(power)
--	node:getChildByName("level_fight_dnum"):setString(string.format("/%d", conf.COMBAT))
    node:getChildByName("level_fight_dnum"):setString(conf.COMBAT)
--	node:getChildByName("level_fight_dnum"):setPositionX(node:getChildByName("level_fight_mynum"):getPositionX() + node:getChildByName("level_fight_mynum"):getContentSize().width)
	if power < conf.COMBAT then
		node:getChildByName("level_fight_mynum"):setTextColor(cc.c4b(255,0,0,255))
		-- node:getChildByName("level_fight_mynum"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,-0.5))
	else
        node:getChildByName("level_fight_mynum"):setTextColor(cc.c4b(0,255,0,255))
    end

	node:getChildByName("level_gold"):setString(CONF:getStringValue("copy gold"))
--	node:getChildByName("level_gold_num"):setString(conf.GOLD)
	node:getChildByName("level_tp"):setString(CONF:getStringValue("copy money"))
--	node:getChildByName("level_tp_num"):setString(conf.SCIENCE)

	node:getChildByName("info_text"):setString(CONF:getStringValue("information"))
	node:getChildByName("drop_text"):setString(CONF:getStringValue("dungeonDrop"))

	node:getChildByName("info"):setPositionX(node:getChildByName("info_text"):getPositionX() + node:getChildByName("info_text"):getContentSize().width + 3)
	node:getChildByName("drop"):setPositionX(node:getChildByName("drop_text"):getPositionX() + node:getChildByName("drop_text"):getContentSize().width + 3)

    local itemlist = {}
    for k,v in ipairs(conf.ITEMS_LIST) do
        table.insert(itemlist,v)
    end
    if tonumber(conf.GOLD) > 0 then
        table.insert(itemlist,1,3001)
    end
    if tonumber(conf.SCIENCE) > 0 then
        table.insert(itemlist,1,7001)
    end

	for i,v in ipairs(itemlist) do
        local itemNode
		local x,y = node:getChildByName("item_1"):getPosition()
        if tonumber(v) == 3001 then
            itemNode = require("util.ItemNode"):create():init(v,tonumber(conf.GOLD))
        elseif tonumber(v) == 7001 then
            itemNode = require("util.ItemNode"):create():init(v,tonumber(conf.SCIENCE))
        else
		    itemNode = require("util.ItemNode"):create():init(v)
        end

		node:addChild(itemNode)
		itemNode:setScale(0.8)
		itemNode:setPosition(cc.p(x+90*(i-1), y))
		itemNode:setName(string.format("item_%d", i))

	end

	node:getChildByName("item_1"):removeFromParent()

    node:getChildByName("power"):setString(CONF:getStringValue("use strength"))
    node:getChildByName("needpower"):setString(conf.STRENGTH)
    node:getChildByName("mypower"):setString("/"..player:getStrength())
    if tonumber(player:getStrength()) < tonumber(conf.STRENGTH) then
        node:getChildByName("needpower"):setTextColor(cc.c4b(255,0,0,255))
    else
        node:getChildByName("needpower"):setTextColor(cc.c4b(0,255,0,255))
    end
	node:getChildByName("jinru"):getChildByName("text"):setString(CONF:getStringValue("entrance"))
	node:getChildByName("jinru"):addClickEventListener(function ( ... )
		print(" COPY_INS CLICK  jin ru 883 levelsceen.lua")
		if player:getStrength() < tonumber(conf.STRENGTH) then
			self:getApp():addView2Top("CityScene/AddStrenthLayer")
			return
		end
		self.data_.go = "copy"
		self:getApp():pushToRootView("FightFormScene/FightFormScene", {copy_id = copy_id, from = "copy"})
	end)
    node:setName("copyinsnode")
	self:addChild(node)

	tipsAction(node)
	node:getChildByName("level"):setPositionX(node:getChildByName("level_name"):getPositionX()+node:getChildByName("level_name"):getContentSize().width+10)
	node:getChildByName("level_num"):setPositionX(node:getChildByName("level"):getPositionX()+node:getChildByName("level"):getContentSize().width)
	-- ADD WJJ 20180703
	self.timeHelper:SetGlobalVal_TimeNowOf("global_time_last_tanchu_fuben_jinru_ui") 
end

function LevelScene:onEnterTransitionFinish()
	printInfo("LevelScene:onEnterTransitionFinish()")

	scheduler:setTimeScale(1)

	if self.data_.function_id then
		systemGuideManager:createGuideLayer(self.data_.function_id)
	end

	local rn = self:getResourceNode()

	local daily_task = rn:getChildByName("daily_task")
	local function touchTask(sender, eventType )
		if eventType == ccui.TouchEventType.began then 
			sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			sender:setOpacity(255*0.7)

			self.data_.go = "copy"
			-- self:getApp():addView2Top("TaskScene/TaskScene", 2)
			local layer = self:getApp():createView("TaskScene/TaskScene",2)
			self:addChild(layer)
		elseif eventType == ccui.TouchEventType.canceled then 
			sender:setOpacity(255*0.7)
		end
	end
	daily_task:getChildByName("bg"):addTouchEventListener(touchTask)
	daily_task:getChildByName("text"):setString(CONF:getStringValue("daily_task"))
	if player:getLevel() < CONF.FUNCTION_OPEN.get("task_open").GRADE then
		daily_task:setVisible(false)
	else
		if require("app.TaskControl"):getInstance():hasUnfinishDailyTask() == true then
			daily_task:getChildByName("point"):setVisible(true)
		end
	end

	cardMove = false
	self.stage_ = self.data_.stage

	guideManager:checkInterface(CONF.EInterface.kLevel)

	self:resetTalk()

	self.ani_ = false


	animManager:runAnimOnceByCSB(rn, "LevelScene/LevelScene.csb", "intro", function ( ... )

		self:resetPanel(self.stage_)
		self.ani_ = true

		if self.data_.tongguan then
			self:createFightAllNode()
		end
		
	end)

	rn:getChildByName("Text_7"):setString(CONF:getStringValue("planetOccupation"))

	local conf = CONF.AREA.get(self.data_.area)

	rn:getChildByName("area_name"):setString(CONF:getStringValue(conf.NAME_ID))

	local bg = rn:getChildByName("bg")
	-- local bg_index = self.data_.area%4

	-- if bg_index == 0 then
	--     bg_index = 4
	-- end

	local _file_bg = "LevelScene/G"..self.data_.area.."mo.jpg"
	-- local _file_bg = "LevelScene/G"..self.data_.area.."mo.pkm"
	print( string.format("@@@@ _file_bg : %s", _file_bg) )
	bg:setTexture(_file_bg)
	-- local blur = mc.EffectBlur:create()
	-- blur:setBlurRadius(10)
	-- blur:setBlurSampleNum(5)

	-- local blur_ = mc.EffectSprite:create("LevelScene/G"..self.data_.area..".jpg")
	-- blur_:setEffect(blur)
	-- blur_:setPosition(cc.p(bg:getContentSize().width/2, bg:getContentSize().height/2))
	-- bg:addChild(blur_)
	-- blur_:setName("bg_blur")

	-- bg:removeFromParent()

	--
	self.iconInfo_ = {}
	for i=1,5 do
		local table_ = {}
		table_.x = rn:getChildByName("Panel"):getChildByName("sprite_"..i):getPositionX()
		table_.y = rn:getChildByName("Panel"):getChildByName("sprite_"..i):getPositionY()
		table_.scale = rn:getChildByName("Panel"):getChildByName("sprite_"..i):getScale()

		if i == 2 or i == 4 then
			table_.shadow = 0.2*255
		elseif i == 3 then
			table_.shadow = 0
		else
			table_.shadow = 0.3*255
		end

		table.insert(self.iconInfo_, table_)

		rn:getChildByName("Panel"):getChildByName("sprite_"..i):removeFromParent()
	end

	--setSv
	
	local function createLabsNode(stage)
		local conf = CONF.COPY.get(stage)

		local node = require("app.ExResInterface"):getInstance():FastLoad("LevelScene/LabsNode.csb")

		node:getChildByName("text"):setString(CONF:getStringValue(conf.COPY_NAME))

		if stage == self.stage_ then
			node:getChildByName("icon"):setOpacity(255)
			node:getChildByName("text"):setTextColor(cc.c4b(0, 255, 0, 255))
			-- node:getChildByName("text"):enableShadow(cc.c4b(0, 255, 0, 255),cc.size(0.5,0.5))
			node:getChildByName("back"):setVisible(true)
			node:setLocalZOrder(9)

			-- local left = rn:getChildByName("top_back_left")
			-- local right = rn:getChildByName("top_back_right")

			-- left:setPositionX(node:getChildByName("back"):convertToWorldSpace(cc.p(0,0)).x)
			-- right:setPositionX(node:getChildByName("back"):convertToWorldSpace(cc.p(0,0)).x + node:getChildByName("back"):getContentSize().width)
		end

		-- node:getChildByName("Panel"):addClickEventListener(function ( ... )
		--     resetPanel(node:getChildByName("Panel"):getTag())
		-- end)
		node:setLocalZOrder(10)
		node:getChildByName("icon"):setTag(stage)
		node:setName(string.format("%d", stage))

		return node
	end

	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(0,0), cc.size(180,73))
	self.svd_:getScrollView():setScrollBarEnabled(false)

	for i,v in ipairs(conf.SIMPLE_COPY_ID) do
		local node = createLabsNode(v)
		local conf = CONF.COPY.get(node:getChildByName("icon"):getTag())
		
		for i=1,3 do
			if conf["SCORE"..i] <= player:getStageStar(conf.ID) then
				if not player:getStageReward(conf.ID)[i] then
					node:getChildByName("point"):setVisible(true)
				end
			end
		end
		local func = function ( sender )

			print(self.stage_, node:getChildByName("icon"):getTag())
			if self.stage_ == node:getChildByName("icon"):getTag() then
				return
			end

			if self:getChildByName("reward_node") then
				self:getChildByName("reward_node"):removeFromParent()
			end

			local conf = CONF.COPY.get(node:getChildByName("icon"):getTag())
			
			if conf.PRE_COPY == 0 then
				self.data_.index = 1
				self.stage_ = node:getChildByName("icon"):getTag()
				self:resetPanel(node:getChildByName("icon"):getTag())
			else

				local pre_conf = CONF.COPY.get(conf.PRE_COPY)
				local copy_id = pre_conf.LEVEL_ID[table.getn(pre_conf.LEVEL_ID)]
				local num = player:getCopyStar(copy_id)
				if num == 0 then
					tips:tips(CONF:getStringValue("finish pre copy"))
					return
				else
					self.data_.index = 1
					self.stage_ = node:getChildByName("icon"):getTag()
					self:resetPanel(node:getChildByName("icon"):getTag())
				end
			end

			playEffectSound("sound/system/tab.mp3")
		end

		local callback = {node = node:getChildByName("icon"), func = func}
		node:setTag(v)
		self.svd_:addElement(node, {callback = callback})

	end

	--setPanel
	self.panel_ = require("util.PanelDelegate"):create(rn:getChildByName("Panel"))
	self.panel_:getPanel():setSwallowTouches(false)

	self:resetPanel(self.stage_)

	----
	--鏄熺悆鍗犻

	-- if #player:getPlanetData().ride_list < CONF.BUILDING_1.get(player:getBuildingInfo(1).level).COLLECT_NUM then
	-- 	rn:getChildByName("star_point"):setVisible(true)
	-- end

	-- if player:getLevel() < CONF.FUNCTION_OPEN.get("star_open").GRADE or self.data_.area == 1 then
		rn:getChildByName("star_point"):setVisible(false)
		rn:getChildByName("btn_xingqiu"):setVisible(false)
		rn:getChildByName("Text_7"):setVisible(false)
	-- end

	-- rn:getChildByName("star_point"):setLocalZOrder(10)

	rn:getChildByName("btn_xingqiu"):addClickEventListener(function ( ... )

		local planet_conf = CONF.PLANET.get(conf.PLANET_ID)

		if planet_conf.OPEN_TYPE == 1 then
			if tonumber(rn:getChildByName("star_now_num"):getString()) < planet_conf.OPEN_VALUE then
				tips:tips(CONF:getStringValue("no enough star"))
				return	
			end
		elseif planet_conf.OPEN_TYPE == 2 then
			if player:getCopyStar(planet_conf.OPEN_VALUE) == 0 then
				tips:tips(CONF:getStringValue("no finish copy").." "..CONF:getStringValue(CONF.CHECKPOINT.get(planet_conf.OPEN_VALUE).NAME_ID))
				return
			end
		end

		self.data_.go = "planet"
		local layer = self:getApp():createView("StarOccupationLayer/StarOccupationLayer", {area = conf.PLANET_ID})
		layer:setLocalZOrder(100)

		self:addChild(layer)

		playEffectSound("sound/system/click.mp3")

	end)

	-------
	rn:getChildByName("mode_1"):getChildByName("panel"):getChildByName("text"):setString(CONF:getStringValue("extension"))
	rn:getChildByName("mode_2"):getChildByName("panel"):getChildByName("text"):setString(CONF:getStringValue("plotline"))

	rn:getChildByName("mode_2"):getChildByName("panel"):getChildByName("text"):setTextColor(cc.c4b(69,69,69,255))
	-- rn:getChildByName("mode_2"):getChildByName("panel"):getChildByName("text"):enableShadow(cc.c4b(69,69,69,255), cc.size(0.5,-0.5))

	self.selectMode_ = 2
	self.default_color = rn:getChildByName("mode_2"):getChildByName("panel"):getBackGroundColor()
	self.mode_pos = {}
	for i=1,2 do
		rn:getChildByName("mode_"..i):getChildByName("panel"):setTag(i)
		local table_ = {x = rn:getChildByName("mode_"..i):getPositionX(), y = rn:getChildByName("mode_"..i):getPositionY()}  
		table.insert(self.mode_pos, table_)  

		rn:getChildByName("mode_"..i):getChildByName("panel"):addClickEventListener(function ( ... )
			-- self:modeAction(rn:getChildByName("mode_"..i):getChildByName("panel"):getTag())
		end)
	end

	rn:getChildByName("mode_2"):getChildByName("panel"):getChildByName("icon"):loadTexture("Common/ui/botton_write.png")
	if player:getFinishCopy(self.stage_) == false then
		rn:getChildByName("mode_1"):getChildByName("panel"):getChildByName("icon"):loadTexture("Common/ui/botton_gray.png")
	end

	self:openTouchEvent2()

	--
	if self.data_.go then
		if self.data_.go == "planet" then
			self:createPlanet(self.data_.area)
		end
	end

	for j=1,#self.getReward do
		--rn:getChildByName("haveGet"..j):setTextColor({r=255,g=255,b=255,a=255});
		rn:getChildByName("haveGet"..j):setString(CONF:getStringValue("unclaimed"))
		if self.getReward[j] then
			--rn:getChildByName("haveGet"..j):setTextColor({r=129,g=129,b=129,a=255});
			rn:getChildByName("haveGet"..j):setString(CONF:getStringValue("has_get"))
		end
	end

	--
	local isTouchMe = false

	local function onTouchBegan(touch, event)

		isTouchMe = true

		return true
	end

	local function onTouchMoved(touch, event)

		local diff = touch:getDelta()
		if math.abs(diff.x) < g_click_delta and math.abs(diff.y) < g_click_delta then
			
		else
			isTouchMe = false
		end
	end
	
	local function onTouchEnded(touch, event)
		if isTouchMe == true then
			playEffectSound("sound/system/click.mp3")
			for i=1,3 do
				local node = self:getResourceNode():getChildByName(string.format("stage_%d", i))

				if node == nil then
			
				else
					local s = node:getContentSize()
					local locationInNode = node:convertToNodeSpace(touch:getLocation())
					local rect = cc.rect(0, 0, s.width, s.height)
					if cc.rectContainsPoint(rect, locationInNode) then

						if self:getChildByName("reward_node") then
							-- self:getChildByName("reward_node"):removeFromParent()
							return
						end

						if tonumber(self:getResourceNode():getChildByName("level_star"):getString()) < CONF.COPY.get(self.stage_)["SCORE"..i] then

							if guideManager:getGuideType() then
								return
							end

							local node = require("util.RewardNode"):createNode(CONF.COPY.get(self.stage_)["REWARD_ID"..i])
							tipsAction(node)
							node:setPosition(cc.exports.VisibleRect:center())
							node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))
							node:setName("reward_node")
							self:addChild(node)
							

							--local getTip = require("util.RewardNode"):createRewardTip(CONF.COPY.get(self.stage_)["REWARD_ID"..i])
							--getTip:setPosition(cc.exports.VisibleRect:top());
							--self:addChild(getTip);
						else
							local rn = self:getResourceNode();
							if self.getReward[i] then
								printInfo("reward got")
								return
							else

								local function func( ... )
									playEffectSound("sound/system/click.mp3")
									local conf = CONF.COPY.get(self.stage_)
									local reward_id = conf["REWARD_ID"..i]
									local score_id = conf["SCORE"..i]

									local strData = Tools.encode("PVEGetRewardReq", {
										copy_id = self.stage_,
										score_id = i,
									})
									GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_GET_REWARD_REQ"),strData)

									gl:retainLoading()

								end

								local node = require("util.RewardNode"):createNode(CONF.COPY.get(self.stage_)["REWARD_ID"..i], func)

								if CONF.COPY.get(self.stage_)["REWARD_ID"..i] == 1101011 or CONF.COPY.get(self.stage_)["REWARD_ID"..i] == 1101012 then
									
									self:getApp():removeTopView()

									node:getChildByName("bg"):addClickEventListener(function ( ... )
										
									end)

									node:getChildByName("yes"):addClickEventListener(function ( ... )
										if guideManager:getGuideType() then
											guideManager:doEvent("touch2")
										end
										func()
									end)
								end

								tipsAction(node)
								node:setPosition(cc.exports.VisibleRect:center())
								node:setName("reward_node")
								self:addChild(node)
								guideManager:checkInterface(CONF.EInterface.kLevel)
								--local getTip = require("util.RewardNode"):createRewardTip(CONF.COPY.get(self.stage_)["REWARD_ID"..i])
								--getTip:setPosition(cc.exports.VisibleRect:top());
								--self:addChild(getTip);
							end
						end
					end

				end
			end
			
		end
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	--
	
	local function recvMsg()
		print("LevelScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PVE_GET_REWARD_RESP") then
			
			gl:releaseLoading()

			local proto = Tools.decode("PVEGetRewardResp",strData)
			print(proto.result)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				playEffectSound("sound/system/reward.mp3")
				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				self:resetPanel(self.stage_)
				if self.stage_ == 10101 then

					--if self.getReward[3] ~= true then

						if self:getChildByName("reward_node") then
							self:getChildByName("reward_node"):removeFromParent()
						end

						-- guideManager:doEvent("recv")

						-- if self.getReward[1] and self.getReward[2] then
												
						-- 	-- guideManager:addGuideStep(510)
						-- 	-- guideManager:createGuideLayer(601)
						-- 	guideManager:doEvent("recv")
						-- elseif self.getReward[1] then
						-- 	-- guideManager:addGuideStep(509)
						-- 	-- guideManager:createGuideLayer(509)
						-- 	guideManager:doEvent("recv")
						-- else
						-- 	guideManager:doEvent("recv")
						-- 	-- guideManager:createGuideLayer(508)
						-- end 
					--end
				end
				local guide 
				if guideManager:getSelfGuideID() ~= 0 then
					guide = guideManager:getSelfGuideID()
				else
					guide = player:getGuideStep()
				end
				print("aaaaaaaaaaaa",guide,guideManager:getGuideType())
				if guideManager:getGuideType() then
					guideManager:addGuideLayer()
				end
			end
		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.talkListener_ = cc.EventListenerCustom:create("talk_over", function ()
		self:resetTalk()                                                                                                                                                                                                                                                 
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.talkListener_, FixedPriority.kNormal)

    self.strengthListener_ = cc.EventListenerCustom:create("StrengthUpdated", function ()
        if self:getChildByName("copyinsnode") then
            local node = self:getChildByName("copyinsnode")
            node:getChildByName("mypower"):setString("/"..player:getStrength())
            if tonumber(player:getStrength()) < tonumber(node:getChildByName("needpower"):getString()) then
			    node:getChildByName("needpower"):setTextColor(cc.c4b(255,0,0,255))
		    else
			    node:getChildByName("needpower"):setTextColor(cc.c4b(0,255,0,255))
		    end
        end
	end)
    eventDispatcher:addEventListenerWithFixedPriority(self.strengthListener_, FixedPriority.kNormal)
    -- nextlevel
    if self.data_ and self.data_["isnext"] then
        self:createTipsNode(self.data_.nextlevel)
    end
end

function LevelScene:modeAction( index )

	local rn = self:getResourceNode()

	if rn:getChildByName("mode_"..index):getChildByName("panel"):getChildByName("text"):getString() == CONF:getStringValue("extension") then
		if player:getFinishCopy(self.stage_) == false then
			return
		end
	end

	if index == 2 then
		return
	end
	
	
	local perNode
	local node 

	for i=1,2 do
		if rn:getChildByName("mode_"..i):getChildByName("panel"):getTag() == self.selectMode_ then
			perNode = rn:getChildByName("mode_"..i)
		end

		if rn:getChildByName("mode_"..i):getChildByName("panel"):getTag() == index then
			node = rn:getChildByName("mode_"..i)
		end
	end

	perNode:stopAllActions()
	perNode:runAction(cc.Spawn:create(cc.MoveTo:create(0.2, cc.p(self.mode_pos[index].x, self.mode_pos[index].y)), cc.CallFunc:create(function ( ... )
		perNode:getChildByName("panel"):setTag(index)
		perNode:getChildByName("panel"):getChildByName("icon"):setTexture("Common/ui/botton_dark.png")
	end)))

	node:stopAllActions()
	node:runAction(cc.Spawn:create(cc.MoveTo:create(0.2, cc.p(self.mode_pos[self.selectMode_].x, self.mode_pos[self.selectMode_].y)), cc.CallFunc:create(function ( ... )
		node:getChildByName("panel"):setTag(self.selectMode_)
		perNode:getChildByName("panel"):getChildByName("icon"):setTexture("Common/ui/botton_write.png")
	end)))


end

function LevelScene:createPlanet( area_id )

	local layer = self:getApp():createView("StarOccupationLayer/StarOccupationLayer", {area = area_id, tips = self.data_.tips})
	layer:setLocalZOrder(100)

	self:addChild(layer)
end

function LevelScene:onExitTransitionStart()

	printInfo("LevelScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.talkListener_)
    eventDispatcher:removeEventListener(self.strengthListener_)

	if self.data_.function_id then
		self.data_.function_id = nil
	end

	if self.data_.tips then
		self.data_.tips = nil
	end

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end
end

return LevelScene