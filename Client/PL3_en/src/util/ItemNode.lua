local ItemNode = class("ItemNode")

function ItemNode:ctor()

	
end

function ItemNode:init(item_id, item_num, strength, notShowInfo)

	local conf = CONF.ITEM.get(item_id)

	local item_node

	if conf.TYPE == 9 then
		item_node = require("app.ExResInterface"):getInstance():FastLoad("Common/GemNode.csb")
	else
		item_node = require("app.ExResInterface"):getInstance():FastLoad("Common/ItemNode.csb")
	end

	if item_node:getChildByName("level_num") then
		item_node:getChildByName("level_num"):setString(CONF.GEM.get(item_id).LEVEL)
	end

	item_node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")

	item_node:getChildByName("icon"):loadTexture("ItemIcon/"..conf.ICON_ID..".png")


	if item_num then
		item_node:getChildByName("num"):setString(item_num)
		item_node:getChildByName("num"):setVisible(true)

		-- if conf.TYPE ~= 9 then
			item_node:getChildByName("num_m"):setString(item_num)
			item_node:getChildByName("num_m"):setVisible(true)
		-- end


		item_node:getChildByName("shadow"):setVisible(true)
		
	end

	if conf.TYPE == 10 then
		local e_conf = CONF.EQUIP.get(item_id)

		item_node:getChildByName("num"):setString("Lv."..e_conf.LEVEL)
		item_node:getChildByName("num"):setVisible(true)

		-- if conf.TYPE ~= 9 then
			item_node:getChildByName("num_m"):setString("Lv."..e_conf.LEVEL)
			item_node:getChildByName("num_m"):setVisible(true)
		-- end


		item_node:getChildByName("shadow"):setVisible(true)

		if strength and strength > 0 then
			item_node:getChildByName("strength"):setString("+"..strength)
			item_node:getChildByName("strength"):setVisible(true)
		end

	end

	self.node_ = item_node

	if not notShowInfo or notShowInfo == false then
		self:addListener(function (  )

			addItemInfoTips(conf,strength)
		end)
	end

	return self.node_
end

function ItemNode:addListener( func )

	local isTouchMe = false

	local function callBack( sender, eventType )

		if eventType == ccui.TouchEventType.began  then

			isTouchMe = true

		end
		if eventType == ccui.TouchEventType.moved  then
			local delta = cc.pSub(sender:getTouchMovePosition(), sender:getTouchBeganPosition()) 
			delta.x =  math.abs(delta.x)
			delta.y =  math.abs(delta.y)
			if delta.x > g_click_delta or delta.y > g_click_delta then
				isTouchMe = false
			end

		end
		if eventType == ccui.TouchEventType.ended then 
			if isTouchMe == true then
				func(sender)
			end
		end
	end


	self.node_:getChildByName("icon"):addTouchEventListener(callBack)
	self.node_:getChildByName("icon"):setSwallowTouches(true)
end

return ItemNode