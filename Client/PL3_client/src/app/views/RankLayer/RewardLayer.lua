local RewardLayer = class("RewardLayer", cc.load("mvc").ViewBase)

RewardLayer.RESOURCE_FILENAME = "RankLayer/RewardLayer.csb"

RewardLayer.NEED_ADJUST_POSITION = true

RewardLayer.RESOURCE_BINDING = {
	["btnClose"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function RewardLayer:OnBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "btnClose" then 
			self:removeFromParent()
		end
	end
end

function RewardLayer:onEnterTransitionFinish()
	local rn = self:getResourceNode()
	rn:getChildByName("Text_17"):setString(CONF:getStringValue("rankingReward"))
	rn:getChildByName("btnClose"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	local list = rn:getChildByName("list")
	list:setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(list ,cc.size(0,2), cc.size(465,70))  
	self.rewardList ={}
	local rewardList = CONF.ARENA_REWARD.getIDList()
	for i,v in ipairs(rewardList) do
		local reward = CONF.ARENA_REWARD.get(v)
		if reward.TYPE == 2 then
			table.insert(self.rewardList ,reward)
		end
	end

	table.sort(self.rewardList ,function ( a ,b )
		return a.RANKING_UP < b.RANKING_UP
	end)

	local index = 1
	for k,v in pairs(self.rewardList) do
		local node = self:createItem(v)

		if index % 2 == 0 then
			node:getChildByName("background"):setOpacity(255*0.2)
		end
		index = index + 1

		self.svd_:addElement(node)

	end

	local function onTouchBegan(touch, event)
		print("reward began")
		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function RewardLayer:createItem( reward )
	local node = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/RewardItemNode.csb")
	local str = ""
	if reward.RANKING_UP == reward.RANKING_DOWN then
		if reward.RANKING_DOWN == 1 then 
			str = "1st"
		elseif reward.RANKING_DOWN == 2 then
			str = "2nd"
		elseif reward.RANKING_DOWN == 3 then 
			str = "3rd"
		end 
	else
		str = str .. reward.RANKING_UP .. "-"
		if reward.RANKING_DOWN > 0 then
			str = str .. reward.RANKING_DOWN
		end
	end
	node:getChildByName("text"):setString(str)

	--添加物品
	local pos = node:getChildByName("pos")
	for i=1,6 do
		local itemId = reward["ITEM_ID" .. i]
		if itemId == 0 then
			break 
		else 

			local itemNode = require("util.ItemNode"):create():init(itemId, reward["ITEM_NUM" .. i])

			itemNode:setScale(0.8)
			local posX = pos:getPositionX() + (i-1) * 90
			local posY = pos:getPositionY()
			node:addChild(itemNode)
			itemNode:setPosition(cc.p(posX ,posY))
		end 
	end

	return node
end

function RewardLayer:onExitTransitionStart()
end

return RewardLayer
