
local SuccessLayer = class("SuccessLayer", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

SuccessLayer.RESOURCE_FILENAME = "AdventureLayer/AdventureLayer.csb"

SuccessLayer.RUN_TIMELINE = true

SuccessLayer.NEED_ADJUST_POSITION = true

function SuccessLayer:onCreate( data )-- {info=,get=bool}
	self.data_ = data
end

function SuccessLayer:onEnter()
  
	printInfo("PlanetScene:onEnter()")

end

function SuccessLayer:onExit()
	
	printInfo("PlanetScene:onExit()")
end

function SuccessLayer:onEnterTransitionFinish()
	printInfo("SuccessLayer:onEnterTransitionFinish()")
	
	local rn = self:getResourceNode()
	rn:getChildByName("close"):setVisible(false)
	self:resetNode()
	
end

function SuccessLayer:resetNode() -- "left","right"
	if Tools.isEmpty(player:getNewHandGift()) then
		if schedulerEntry ~= nil then
		 	scheduler:unscheduleScriptEntry(schedulerEntry)
		 	schedulerEntry = nil
		end
		self:removeFromParent()
	end
	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_left"):setVisible(false)
	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_right"):setVisible(false)
	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("Text_des"):setVisible(false)
	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("Text_time"):setVisible(false)
	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("Image_2"):setVisible(false)
	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("num"):setVisible(false)
	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("zhe_4"):setVisible(false)
	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("bg2_2"):setVisible(false)
	local info = self.data_.info
	local newHand = CONF.NEWHANDGIFTBAG.get(info.id)
	local recharge_conf = CONF.RECHARGE.get(info.gift_id)
	local node = self:getResourceNode():getChildByName("FileNode_1")
	node:getChildByName("gift_bg"):setTexture("AdventureLayer/ui/"..newHand.RESOURCE_BG..".png")
	node:getChildByName("giftBagName"):setTexture("AdventureLayer/ui/"..newHand.NAME..".png")
	local pre = math.floor(recharge_conf["RECHARGE_"..server_platform]/newHand["PRICE_"..server_platform]*10)
	print("pre",pre)
	node:getChildByName("num"):setTexture("AdventureLayer/ui/num_"..pre..".png")


	local list = require("util.ScrollViewDelegate"):create(node:getChildByName("list"),cc.size(1,1), cc.size(221,54))
	list:getScrollView():setScrollBarEnabled(false)
	local items = {}
	for k,v in ipairs(newHand.REWARD) do
		local gift = CONF.REWARD.get(v)
		for i,id in ipairs(gift.ITEM) do
			table.insert(items,{id = id,num = gift.COUNT[i]})
		end
	end
	for k,v in ipairs(items) do
		local node_item = require("app.ExResInterface"):getInstance():FastLoad("AdventureLayer/ItemNode.csb")
		local cfg_item = CONF.ITEM.get(v.id)
		node_item:getChildByName("num"):setString("x"..v.num)
		node_item:getChildByName("name"):setString(CONF:getStringValue(cfg_item.NAME_ID))
		node_item:getChildByName("quality"):loadTexture("RankLayer/ui/ui_avatar_"..cfg_item.QUALITY..".png")
		node_item:getChildByName("icon"):setTexture("ItemIcon/"..cfg_item.ICON_ID..".png")
		list:addElement(node_item)
	end
	node:getChildByName("ok"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	node:getChildByName("ok"):getChildByName("text"):setVisible(true)
	node:getChildByName("ok"):addClickEventListener(function()
		self:removeFromParent()
		end)
	local img = node:getChildByName("ok"):getChildByName("normal"):getChildByName("Image_4")
	local old = node:getChildByName("ok"):getChildByName("normal"):getChildByName("old")
	local new = node:getChildByName("ok"):getChildByName("normal"):getChildByName("new")
	old:setString(CONF:getStringValue("coin_sign")..newHand["PRICE_"..server_platform])
	new:setString(CONF:getStringValue("coin_sign")..recharge_conf["RECHARGE_"..server_platform])
	old:setPositionX(img:getPositionX()-img:getContentSize().width/2)
	new:setPositionX(img:getPositionX()+img:getContentSize().width/2)
	node:getChildByName("ok"):getChildByName("normal"):setVisible(false)
end

function SuccessLayer:onExitTransitionStart()

	printInfo("SuccessLayer:onExitTransitionStart()")

end

return SuccessLayer