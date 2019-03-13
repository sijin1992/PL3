
local GiftNode = class("GiftNode")

local gl = require("util.GlobalLoading"):getInstance()

local player = require("app.Player"):getInstance()

function GiftNode:creatGiftNode(info,get) -- get:bool
	local newHand = CONF.NEWHANDGIFTBAG.get(info.id)
	local node = require("app.ExResInterface"):getInstance():FastLoad("AdventureLayer/AdventureNode.csb")
	node:getChildByName("gift_bg"):setTexture("AdventureLayer/ui/"..newHand.RESOURCE_BG..".png")
	-- node:getChildByName("Node_get"):getChildByName("name"):setString(CONF:getStringValue(newHand.NAME))
	-- node:getChildByName("Node_get"):getChildByName("title"):setString(CONF:getStringValue("get_reward"))
	-- node:getChildByName("Node_normal"):getChildByName("name"):setString(CONF:getStringValue(newHand.NAME))
    node:getChildByName("Text_des"):setString(CONF:getStringValue("limitNum"))
	local recharge_conf = CONF.RECHARGE.get(info.gift_id)
	local pre = math.floor(recharge_conf["RECHARGE_"..server_platform]/newHand["PRICE_"..server_platform]*100)
	-- node:getChildByName("Node_normal"):getChildByName("kou"):setString(pre.."%")
	-- node:getChildByName("Node_normal"):getChildByName("time"):setString("")
	-- node:getChildByName("ins"):setString(CONF:getStringValue(newHand.DESCRIBE))
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
		node_item:getChildByName("num"):setString(v.num)
		node_item:getChildByName("name"):setString(CONF:getStringValue(cfg_item.NAME_ID))
		node_item:getChildByName("quality"):loadTexture("RankLayer/ui/ui_avatar_"..cfg_item.QUALITY..".png")
		node_item:getChildByName("icon"):setTexture("ItemIcon/"..cfg_item.ICON_ID..".png")
		list:addElement(node_item)
	end
	node:getChildByName("ok"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	node:getChildByName("ok"):addClickEventListener(function()
		if get then
			node:getParent():removeFromParent()
		else
			print("device.platform  ",device.platform)
			if device.platform == "ios" or device.platform == "android" then
				if(device.platform == "android" and require("util.ExSDK"):getInstance():IsQuickSDK() ) then
					require("util.ExSDK"):getInstance():SDK_REQ_QuickPay(recharge_conf)
				else
					GameHandler.handler_c.payStart(recharge_conf.PRODUCT_ID)
					-- gl:retainLoading()
				end
			end
		end
		end)
	local img = node:getChildByName("ok"):getChildByName("normal"):getChildByName("Image_4")
	local old = node:getChildByName("ok"):getChildByName("normal"):getChildByName("old")
	local new = node:getChildByName("ok"):getChildByName("normal"):getChildByName("new")
	old:setString(CONF:getStringValue("coin_sign")..newHand["PRICE_"..server_platform])
	new:setString(CONF:getStringValue("coin_sign")..recharge_conf["RECHARGE_"..server_platform])
	old:setPositionX(img:getPositionX()-img:getContentSize().width/2)
	new:setPositionX(img:getPositionX()+img:getContentSize().width/2)

	-- node:getChildByName("Node_get"):setVisible(get)
	-- node:getChildByName("Node_normal"):setVisible(not get)
	node:getChildByName("ok"):getChildByName("normal"):setVisible(not get)
	node:getChildByName("ok"):getChildByName("text"):setVisible(get)
	-- node:getChildByName("mask"):setVisible(not get)
	return node
end

return GiftNode