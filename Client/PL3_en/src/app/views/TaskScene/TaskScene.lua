
local app = require("app.MyApp"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local g_taskManager = require("app.TaskControl"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local player = require("app.Player"):getInstance()

local TaskScene = class("TaskScene", cc.load("mvc").ViewBase)

TaskScene.RESOURCE_FILENAME = "TaskScene/TaskLayer.csb"

TaskScene.NEED_ADJUST_POSITION = true

TaskScene.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function TaskScene:OnBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			-- self:getApp():pushToRootView("CityScene/CityScene", {pos = -350})
			-- app:removeTopView()
			if guideManager:getShowGuide() then
				if guideManager:getGuideType() then
					guideManager:doEvent("click")
				end
			end

			self:removeFromParent()
			
		end
	end
end

function TaskScene:onCreate(data) --1:main 2:daily
	self.introMode_ = data
	self.mode_ = 0
end

function TaskScene:setBarHighLight(bar, flag)
	if flag == true then
		bar:getChildByName("selected"):setVisible(true)
		bar:getChildByName("normal"):setVisible(false)
		bar:getChildByName("text_0"):setVisible(true)
		bar:getChildByName("text"):setVisible(false)
	else
		bar:getChildByName("selected"):setVisible(false)
		bar:getChildByName("normal"):setVisible(true)
		bar:getChildByName("text_0"):setVisible(false)
		bar:getChildByName("text"):setVisible(true)
	end
end

function TaskScene:changeMode(mode)
	if mode == self.mode_ then

		return
	end
	self.mode_ = mode

	local rn = self:getResourceNode()
	local second_node = rn:getChildByName("second_node")
	second_node:removeAllChildren()

	local node
	if mode == 1 then
		node = require("app.views.TaskScene.MainTaskNode"):create(self)
	elseif mode == 3 then
		node = require("app.views.TaskScene.DailyTaskNode"):create(self)
	elseif mode == 2 then
		node = require("app.views.TaskScene.NormalTaskNode"):create(self)
	end
	if not node then
		return 
	end
	if self.mode_ == 3 then
		guideManager:checkInterface(CONF.EInterface.kTask)

		if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kDayTask)== 0 and g_System_Guide_Id == 0 then
			systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("task_open").INTERFACE)
		else
			if g_System_Guide_Id ~= 0 then
				systemGuideManager:createGuideLayer(g_System_Guide_Id)
			end
		end
	end
	-- node:setScale(0.8)
	second_node:addChild(node)

	local leftBar = rn:getChildByName("leftBg")
	local children = leftBar:getChildren()
	for i,v in ipairs(children) do
		local bar_name = v:getName()
		if bar_name == string.format("mode_%d", mode) then
			self:setBarHighLight(v, true)
		else
			self:setBarHighLight(v, false)
		end
	end
end

function TaskScene:onEnterTransitionFinish()

	printInfo("TaskScene:onEnterTransitionFinish()")

	local rn = self:getResourceNode()

	-- ADD WJJ 20180723
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Renwu(self)

	animManager:runAnimOnceByCSB(rn,"TaskScene/TaskLayer.csb" ,"intro")

	self:changeMode(self.introMode_)

	local leftBar = rn:getChildByName("leftBg")
	local children = leftBar:getChildren()
	local function clickBar(sender)
		playEffectSound("sound/system/tab.mp3")
		self:changeMode(sender:getParent():getTag())
		
	end
	for i,v in ipairs(children) do
		v:getChildByName("selected"):addClickEventListener(clickBar)
		v:getChildByName("normal"):addClickEventListener(clickBar)
	end


	local taskText = rn:getChildByName("title")
	--taskText:setString(CONF:getStringValue("task"))	Delete by JinXin 20180620
	rn:getChildByName("leftBg"):getChildByName("mode_1"):getChildByName("text"):setString(CONF:getStringValue("Story_missions"))
	rn:getChildByName("leftBg"):getChildByName("mode_2"):getChildByName("text"):setString(CONF:getStringValue("normal_task"))
	rn:getChildByName("leftBg"):getChildByName("mode_3"):getChildByName("text"):setString(CONF:getStringValue("daily_task"))
	rn:getChildByName("leftBg"):getChildByName("mode_1"):getChildByName("text_0"):setString(CONF:getStringValue("Story_missions"))
	rn:getChildByName("leftBg"):getChildByName("mode_2"):getChildByName("text_0"):setString(CONF:getStringValue("normal_task"))
	rn:getChildByName("leftBg"):getChildByName("mode_3"):getChildByName("text_0"):setString(CONF:getStringValue("daily_task"))
	for i=1,3 do
		rn:getChildByName("leftBg"):getChildByName("mode_"..i):getChildByName("text_0"):setVisible(false)
		if i == self.mode_ then
			rn:getChildByName("leftBg"):getChildByName("mode_"..i):getChildByName("text_0"):setVisible(true)
		end
	end
	if player:getLevel() < CONF.FUNCTION_OPEN.get("task_open").GRADE then
		rn:getChildByName("leftBg"):getChildByName("mode_3"):setVisible(false)
    else
        local newX = rn:getChildByName("leftBg"):getChildByName("mode_1"):getPositionX()
        local newY = rn:getChildByName("leftBg"):getChildByName("mode_1"):getPositionY()
        rn:getChildByName("leftBg"):getChildByName("mode_1"):setPosition(rn:getChildByName("leftBg"):getChildByName("mode_2"):getPosition())
        rn:getChildByName("leftBg"):getChildByName("mode_2"):setPosition(rn:getChildByName("leftBg"):getChildByName("mode_3"):getPosition())
        rn:getChildByName("leftBg"):getChildByName("mode_3"):setPosition(newX,newY)
        rn:getChildByName("leftBg"):getChildByName("mode_3"):setVisible(true)
	end 

	local eventDispatcher = self:getEventDispatcher()
	rn:getChildByName("leftBg"):getChildByName("mode_1"):getChildByName("point"):setVisible(g_taskManager:hasCanGetMainTask())
	self.maintasklistener_ = cc.EventListenerCustom:create("TaskUpdate", function ( event )
		rn:getChildByName("leftBg"):getChildByName("mode_1"):getChildByName("point"):setVisible(g_taskManager:hasCanGetMainTask())
		rn:getChildByName("leftBg"):getChildByName("mode_2"):getChildByName("point"):setVisible(g_taskManager:hasCanGetNormalTask())
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.maintasklistener_, FixedPriority.kNormal)

	rn:getChildByName("leftBg"):getChildByName("mode_3"):getChildByName("point"):setVisible(g_taskManager:hasCanGetDailyTask())
	self.dailytasklistener_ = cc.EventListenerCustom:create("DailyTaskUpdate", function ( event )
		rn:getChildByName("leftBg"):getChildByName("mode_3"):getChildByName("point"):setVisible(g_taskManager:hasCanGetDailyTask())
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.dailytasklistener_, FixedPriority.kNormal)
	
	rn:getChildByName("leftBg"):getChildByName("mode_2"):getChildByName("point"):setVisible(g_taskManager:hasCanGetNormalTask())
	self.normaltasklistener_ = cc.EventListenerCustom:create("NormalTaskUpdate", function ( event )
		rn:getChildByName("leftBg"):getChildByName("mode_2"):getChildByName("point"):setVisible(g_taskManager:hasCanGetNormalTask())
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.normaltasklistener_, FixedPriority.kNormal)

	self.strengthlistener_ = cc.EventListenerCustom:create("StrengthUpdated", function ( event )
		local cur = self.mode_
		self.mode_ = 0
		self:changeMode(cur)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.strengthlistener_, FixedPriority.kNormal)
end

function TaskScene:onExitTransitionStart()
	printInfo("TaskScene:onExitTransitionStart()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.normaltasklistener_)
	eventDispatcher:removeEventListener(self.maintasklistener_)
	eventDispatcher:removeEventListener(self.dailytasklistener_)
	eventDispatcher:removeEventListener(self.strengthlistener_)
	
end

return TaskScene