local player = require("app.Player"):getInstance()
local animManager = require("app.AnimManager"):getInstance()

local FriendLayer = class("FriendLayer", cc.load("mvc").ViewBase)

FriendLayer.RESOURCE_FILENAME = "FriendLayer/FriendLayer.csb"
FriendLayer.NEED_ADJUST_POSITION = true
FriendLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function FriendLayer:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" then

		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			self:removeFromParent()

		end
	end

end


function FriendLayer:onCreate(data)
	self.data_ = data
end


function FriendLayer:resetNode(typename,data,frist)

	print(self.typename_, typename)
	if self.typename_ == typename then
		return
	end

	local rn = self:getResourceNode()

	local perNode = rn:getChildByName("node")
	if perNode == nil then
		return
	end
	local nodePos = cc.p(perNode:getPosition())
	perNode:removeFromParent()

	local node = nil
	if typename == "friend" then
		if frist and player:getFriendsNum(1) == 0 then
			node = require("app.views.FriendLayer.AddFriendNode"):create()
			typename = "add"
		else
			node = require("app.views.FriendLayer.FriendNode"):create()
		end
	elseif typename == "add" then
		node = require("app.views.FriendLayer.AddFriendNode"):create()
	elseif typename == "black" then
		node = require("app.views.FriendLayer.BlackNode"):create()
	elseif typename == "apply" then
		node = require("app.views.FriendLayer.ApplyNode"):create()
	elseif typename == "enemy" then
		node = require("app.views.FriendLayer.EnemyNode"):create()
	end

	for i,v in ipairs(self.typeList) do
		local target = rn:getChildByName(v)
		if v == typename then
			target:getChildByName("text"):setVisible(false)
			target:getChildByName("selected_text"):setVisible(true)
			target:getChildByName("selected"):setVisible(true)
		else
			target:getChildByName("text"):setVisible(true)
			target:getChildByName("selected_text"):setVisible(false)
			target:getChildByName("selected"):setVisible(false)
		end
	end

	self.typename_ = typename
	rn:addChild(node)	
	node:setName("node")
	node:setPosition(nodePos)

	node:init(self,data)
end

function FriendLayer:onEnterTransitionFinish()

	printInfo("FriendLayer:onEnterTransitionFinish()")

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kFriend)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("friend_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end

	local eventDispatcher = self:getEventDispatcher()

	self.typeList = {"friend", "add", "black", "apply"}

	self.typename_ = ""

	local rn = self:getResourceNode()
	rn:getChildByName("friend"):getChildByName("text"):setString(CONF:getStringValue("friend"))
	rn:getChildByName("add"):getChildByName("text"):setString(CONF:getStringValue("add"))
	rn:getChildByName("apply"):getChildByName("text"):setString(CONF:getStringValue("apply"))
	rn:getChildByName("black"):getChildByName("text"):setString(CONF:getStringValue("black"))
	rn:getChildByName("friend"):getChildByName("selected_text"):setString(CONF:getStringValue("friend"))
	rn:getChildByName("add"):getChildByName("selected_text"):setString(CONF:getStringValue("add"))
	rn:getChildByName("apply"):getChildByName("selected_text"):setString(CONF:getStringValue("apply"))
	rn:getChildByName("black"):getChildByName("selected_text"):setString(CONF:getStringValue("black"))
	--rn:getChildByName("enemy"):getChildByName("text"):setString(CONF:getStringValue("enemy"))
	--rn:getChildByName("title"):setString(CONF:getStringValue("friend"))

	local hasApply = false
    if player.mail_list_ then
	    for i,v in ipairs(player.mail_list_) do
		    if v.type == 9 then
			    hasApply = true
			    break
		    end
	    end
    end

	if hasApply then
		rn:getChildByName("apply"):getChildByName("red"):setVisible(true)
	else
		rn:getChildByName("apply"):getChildByName("red"):setVisible(false)
	end

	self:resetNode("friend", {index = 0}, true)

	for i,v in ipairs(self.typeList) do
		local target = rn:getChildByName(v)

		target:addClickEventListener(function ( sender )
			playEffectSound("sound/system/tab.mp3")
			self:resetNode(v, {index = 0})
		end)
	end

	rn:getChildByName("gray"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		if self.typename_ == "friend" then
			if rn:getChildByName("node"):getResourceNode():getChildByName("click_node") then
				rn:getChildByName("node"):getResourceNode():getChildByName("click_node"):removeFromParent()

				rn:getChildByName("node"):resetList()
			end
		end
	end)


	self.friendListener_ = cc.EventListenerCustom:create("NewFriendUpdate", function ()
		rn:getChildByName("apply"):getChildByName("red"):setVisible(true)

		if self.typename_ == "apply" then
			rn:getChildByName("node"):updateList()
		end

	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.friendListener_, FixedPriority.kNormal)

end

function FriendLayer:chat(name)
	local layer = self:getApp():createView("ChatLayer/ChatLayer",{name = "chat", user_name = name})
	self:getParent():addChild(layer)
	-- layer:resetNode("chat")

	self:removeFromParent()


end


function FriendLayer:onExitTransitionStart()
	printInfo("FriendLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.friendListener_)

	-- self:getParent():getMailList()
end


return FriendLayer