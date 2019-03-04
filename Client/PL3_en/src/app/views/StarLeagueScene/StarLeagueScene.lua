
local FileUtils = cc.FileUtils:getInstance()

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local StarLeagueScene = class("StarLeagueScene", cc.load("mvc").ViewBase)

StarLeagueScene.RESOURCE_FILENAME = "StarLeagueScene/StarLeagueScene.csb"

StarLeagueScene.RUN_TIMELINE = true

StarLeagueScene.NEED_ADJUST_POSITION = true

StarLeagueScene.RESOURCE_BINDING = {
}

function StarLeagueScene:onCreate(data)
	self.data_ = data
end

function StarLeagueScene:onEnter()
	
	printInfo("StarLeagueScene:onEnter()")
end

function StarLeagueScene:onExit()
	
	printInfo("StarLeagueScene:onExit()")

end

function StarLeagueScene:onEnterTransitionFinish()
	printInfo("StarLeagueScene:onEnterTransitionFinish()")

	broadcastRun()

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kStarLeague)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("league_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end


	local rn = self:getResourceNode()

	-- local strData = Tools.encode("GetGroupReq", {
	-- 	-- groupid = player:getGroupData().groupid,
	-- 	groupid = "",
	-- })
	-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_REQ"),strData)

	-- gl:retainLoading()

	if player:isGroup() then
		self.uiLayer_ = self:getApp():createView("StarLeagueScene/StarLeagueLayer", self.data_)
	else
		self.uiLayer_ = self:getApp():createView("StarLeagueScene/NoStarLeagueLayer",self.data_)
	end

	self:addChild(self.uiLayer_)


	local function recvMsg()
		print("ChatNode:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		-- if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_RESP") then
		-- 	-- gl:releaseLoading()

		--     local proto = Tools.decode("GetGroupResp",strData)
		--     print("GetGroupResp")
		--     print(proto.result)
			
		   --  if proto.result == 0 then
		   --  	if self.uiLayer_ == nil then
					

		   --  	end

		   --  end
		-- end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.broadcastListener_ = cc.EventListenerCustom:create("broadcastRun", function ()
		broadcastRun()
	end)

	self.chatListener_ = cc.EventListenerCustom:create("group_main_noGroupid", function (event)
		print("group_main_noGroupid gengxinxnxinxin")
		if event.group_main.groupid == "" or event.group_main == nil then
			return
		end
		self:getGroup()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.chatListener_, FixedPriority.kNormal)
	eventDispatcher:addEventListenerWithFixedPriority(self.broadcastListener_, FixedPriority.kNormal)
end

function StarLeagueScene:getGroup( ... )
	self.uiLayer_:removeFromParent()

	self.uiLayer_ = self:getApp():createView("StarLeagueScene/StarLeagueLayer",self.data_)
	self:addChild(self.uiLayer_)
end

function StarLeagueScene:getNoGroup( ... )
	self.uiLayer_:removeFromParent()

	self.uiLayer_ = self:getApp():createView("StarLeagueScene/NoStarLeagueLayer",self.data_)
	self:addChild(self.uiLayer_)
end

function StarLeagueScene:onExitTransitionStart()
	printInfo("StarLeagueScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.broadcastListener_)
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.chatListener_)
	
end

return StarLeagueScene