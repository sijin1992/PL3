local g_player = require("app.Player"):getInstance()
local animManager = require("app.AnimManager"):getInstance()
local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()
local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
local TechnologyScene = class("TechnologyScene", cc.load("mvc").ViewBase)

TechnologyScene.RESOURCE_FILENAME = "TechnologyScene/TechnologyScene.csb"
TechnologyScene.NEED_ADJUST_POSITION = true
TechnologyScene.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil


local scheduler = cc.Director:getInstance():getScheduler()

function TechnologyScene:OnBtnClick(event)
	if event.name == "ended" then

		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
        			self:getApp():popView()
        			
    		end
	end
end

function TechnologyScene:onCreate()
	
	self.techGroupCount_ = 0
	local function countTech()
		local allList = CONF.TECHNOLOGY.getIDList()
		local groupMap = {} 
		for i,v in ipairs(allList) do
			if groupMap[v] == nil then
				groupMap[v] = 1
			end
		end


		for k,v in pairs(groupMap) do
			self.techGroupCount_ = self.techGroupCount_ + 1
		end
	end

	countTech()

	
end


function TechnologyScene:resetList(type)

	self.techDelegates_ = {}

	local function bindingNode(node)

		local delegate = require("app.views.TechnologyScene.TechnologyDelegate"):create(node)
        		delegate:updateInfo()
        		table.insert(self.techDelegates_, delegate)
	end

	local function initList(list)
		local children = list:getChildByName("node"):getChildren()
		for i,obj in ipairs(children) do

			if tolua.type(obj) ~= "ccui.ImageView" then

				bindingNode(obj)
			end
		end
	end



	local rn = self:getResourceNode()
	local list = rn:getChildByName("list")
	list:setScrollBarEnabled(false)
	local winSize = cc.Director:getInstance():getWinSize()
	local size = list:getContentSize()
	list:setContentSize(winSize.width - 20, size.height)


	local preNode = list:getChildByName("node")

	if preNode then
		if preNode:getTag() == type then
			return
		end

		preNode:removeFromParent()
	end

	
	local listName = string.format("TechnologyScene/list_%d.csb",type)
	local node = require("app.ExResInterface"):getInstance():FastLoad(listName)
	list:addChild(node)
	node:setName("node")
	node:setTag(type)

	animManager:runAnimOnceByCSB( node, listName, "1")

	list:setInnerContainerSize(node:getChildByName("background"):getContentSize())

	initList(list)
end

function TechnologyScene:resetRes( )
	local rn = self:getResourceNode()
	local topBar = rn:getChildByName("left_top_bar")
	for i=1, 4 do

		topBar:getChildByName(string.format("res_text_%d",i)):setString(formatRes(g_player:getResByIndex(i)))
	end

end

function TechnologyScene:resetMoney( )
	self:getResourceNode():getChildByName("left_top_bar"):getChildByName("res_text_5"):setString(g_player:getMoney())--formatRes(g_player:getMoney()))
end

function TechnologyScene:resetTech( )

	local rn = self:getResourceNode()
	local topBar = rn:getChildByName("top_bar")

	rn:getChildByName("left_top_bar"):getChildByName("cur_num"):setString(string.format("%d",g_player:getUsedTechnologyLevelCount()))

	rn:getChildByName("left_top_bar"):getChildByName("all_num"):setString(string.format("/%d",self.techGroupCount_))

	local fastDevelop = rn:getChildByName("buttom_bar"):getChildByName("fast_develop")
	fastDevelop:getChildByName("text"):setString(CONF:getStringValue("expedite"))

	local techData = g_player:getTechnolgyData()
	if techData and techData.upgrade_busy == 1 then
		rn:getChildByName("buttom_bar"):getChildByName("status"):setString(CONF.STRING.get("tech_cd_time").VALUE)
		rn:getChildByName("buttom_bar"):getChildByName("cd_time"):setVisible(true)

		fastDevelop:setVisible(true)

		fastDevelop:addClickEventListener(function ()
			
            			self:getApp():addView2Top("TechnologyScene/TechnologyDevelopLayer", {techID = techData.tech_id})
            			

		end)



	else
		rn:getChildByName("buttom_bar"):getChildByName("status"):setString(CONF.STRING.get("no_upgrade_tech").VALUE)
		rn:getChildByName("buttom_bar"):getChildByName("cd_time"):setVisible(false)
		fastDevelop:setVisible(false)
		fastDevelop:addClickEventListener(function ()
			-- body
		end)
	end
end

function TechnologyScene:onEnterTransitionFinish()
	printInfo("TechnologyScene:onEnterTransitionFinish()")

	guideManager:checkInterface(CONF.EInterface.kTechnology)
	if CONF.FUNCTION_OPEN.get("city_5_open").OPEN_GUIDANCE == 1 then
		if g_player:getSystemGuideStep(CONF.ESystemGuideInterFace.kTechnology)== 0 and g_System_Guide_Id == 0 then
			systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("city_5_open").INTERFACE)
		else
			if g_System_Guide_Id ~= 0 then
				systemGuideManager:createGuideLayer(g_System_Guide_Id)
			end
		end
	end

	local eventDispatcher = self:getEventDispatcher()
	local rn = self:getResourceNode()
	rn:getChildByName("buttom_bar"):getChildByName("type_2"):getChildByName("text"):setString(CONF:getStringValue("Building"))
	rn:getChildByName("buttom_bar"):getChildByName("type_3"):getChildByName("text"):setString(CONF:getStringValue("Assisted"))
	rn:getChildByName("buttom_bar"):getChildByName("type_1"):getChildByName("text"):setString(CONF:getStringValue("Military"))
	rn:getChildByName("left_top_bar"):getChildByName("research_qty"):setString(CONF:getStringValue("ResearchQty"))

	if guideManager:getGuideType() then
   		rn:getChildByName("list"):setTouchEnabled(false)
    end

	local function update(dt)

		if Tools.isEmpty(self.techDelegates_) == false then
			for i,v in ipairs(self.techDelegates_) do
				v:update(dt)
			end
		end

		local techData = g_player:getTechnolgyData()

		if rn:getChildByName("buttom_bar"):getChildByName("cd_time"):isVisible() ==  true and techData.upgrade_busy == 1 then
			
			local info = g_player:getTechnologyByID(techData.tech_id)
			assert(info,"error")
	
			local conf = CONF.TECHNOLOGY.get(techData.tech_id)

			local time = info.begin_upgrade_time + conf.CD - g_player:getServerTime()
			rn:getChildByName("buttom_bar"):getChildByName("cd_time"):setString(formatTime(time))
		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)
	

	self:resetRes()
	self:resetTech()
	self:resetMoney()
	rn:getChildByName("left_top_bar"):getChildByName("money_add"):addClickEventListener(function ( sender )
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self:getParent(), {index = 1})
		self:getParent():addChild(rechargeNode)
	end)

	self:resetList(3)

	self.td_ = require("util.LabsDelegate"):create(function (target)
		playEffectSound("sound/system/tab.mp3")
		local type = tonumber(string.match(target:getName(),"(%d+)")) 

		self:resetList(type)

		

	end, "Common/newUI/yq_click02.png", "Common/newUI/yq_click02_bottom.png", eventDispatcher, 
	{rn:getChildByName("buttom_bar"):getChildByName("type_1")}, 
	{rn:getChildByName("buttom_bar"):getChildByName("type_2")}, 
	{rn:getChildByName("buttom_bar"):getChildByName("type_3")})

	self.td_ :setTextColor(cc.c4b(255,244,198,255), cc.c4b(209,209,209,255))

	local eventDispatcher = self:getEventDispatcher()
	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		self:resetRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)


	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		self:resetMoney()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)
	

	self.techListener_ = cc.EventListenerCustom:create("TechUpdated", function ()

		if Tools.isEmpty(self.techDelegates_) == false then
			for i,v in ipairs(self.techDelegates_) do
				v:updateInfo()
			end
		end
		self:resetTech()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.techListener_, FixedPriority.kNormal)

	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_TECHNOLOGY_RESP") then

        			local proto = Tools.decode("GetTechnologyResp",strData)
        			if proto.result == 0 then

        				if proto.hasUpgrade == true then
        					local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("UpgradeSucess"))
					node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(node)
				end
        			end
        		end
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	animManager:runAnimOnceByCSB( self, self.RESOURCE_FILENAME, "intro")
end

function TechnologyScene:onExitTransitionStart()
	printInfo("TechnologyScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.techListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)

	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
  		scheduler:unscheduleScriptEntry(schedulerEntry)
  	end
end

return TechnologyScene