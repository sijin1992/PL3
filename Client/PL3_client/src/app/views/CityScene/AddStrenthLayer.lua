local player = require("app.Player"):getInstance()
local tips = require("util.TipsMessage"):getInstance()
local AddStrengthLayer = class("AddStrengthLayer", cc.load("mvc").ViewBase)

AddStrengthLayer.RESOURCE_FILENAME = "CityScene/AddStrengthLayer.csb"
AddStrengthLayer.NEED_ADJUST_POSITION = true

-- AddStrengthLayer.RESOURCE_BINDING = {
--     ["close"] = {["varname"] = "", ["events"] = {{["event"] = "touch", ["method"] = "OnBtnClick"}}},
--     ["xydBtn"] = {["varname"] = "", ["events"] = {{["event"] = "touch", ["method"] = "OnBtnClick"}}},
-- }

AddStrengthLayer.btn = {
	close = 1,
	xydBtn = 2
}


function AddStrengthLayer:onEnterTransitionFinish()

	local rn = self:getResourceNode()
	rn:getChildByName("m_bottom2_17"):getChildByName("name"):setString(CONF:getStringValue("add_strength"))
	rn:getChildByName("m_bottom2_17"):getChildByName("close"):setVisible(false)
	rn:getChildByName("m_bottom2_17"):getChildByName("newbg2_2"):setVisible(false)
	
	rn:getChildByName("use"):getChildByName("text"):setString(CONF:getStringValue("use"))

	rn:getChildByName("xydBtn"):getChildByName("text"):setString(CONF:getStringValue("credit_buy"))

	rn:getChildByName("uibg"):setSwallowTouches(true)
	rn:getChildByName("uibg"):addClickEventListener(function ( sender )
		--playEffectSound("sound/system/return.mp3")
		self:getApp():removeTopView()
	end)

	rn:getChildByName("use"):addClickEventListener(function ( sender )

		if self.curItem_ == nil then
			return
		end
		local item_list = CONF.PARAM.get("strength_item_list").PARAM
		local curId = item_list[self.curItem_:getTag()]

		local itemNum = player:getItemNumByID(curId)

		if itemNum < 1 then 
			tips:tips(CONF:getStringValue("item not enought"))
			return
		end

		self.s_item_id = curId
		
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ADD_STRENGTH_REQ"), Tools.encode("AddStrengthReq", 
			{
				type = 1,
				item = {key = curId, value = 1},
			}
		))

		if itemNum ~= nil and itemNum >= 1 then 
			itemNum = itemNum - 1
			self.curItem_:getChildByName("have_num"):setString(tostring(itemNum))
		end
		if itemNum > 0 then 
			self.curItem_:getChildByName("have_num"):setTextColor(cc.c3b(33, 255, 70))
		else 
			self.curItem_:getChildByName("have_num"):setTextColor(cc.c3b(255, 145, 136))
		end
	end)


	self.xydBtn = rn:getChildByName("xydBtn")
	self.xydBtn:setTag(AddStrengthLayer.btn.xydBtn)
	self.xydBtn:addClickEventListener(function ( sender )
		if player:getUserInfo().strength_buy_times < CONF.VIP.get(player:getVipLevel()).STRENGTH_TIMES then
			local app = self:getApp()
			app:removeTopView()
			app:addView2Top("CityScene/AddStrenthTips")
		else
			tips:tips(CONF:getStringValue("max_num_buy"))
		end
	
	end )


	local item_list = CONF.PARAM.get("strength_item_list").PARAM

	for i, id in ipairs(item_list) do

		local conf = CONF.ITEM.get(id)
		local item_node = rn:getChildByName("strenth_item_" .. i)
		item_node:setTag(i)
		item_node:getChildByName("icon"):loadTexture("ItemIcon/" .. conf.ICON_ID .. ".png")
		item_node:getChildByName("name"):setString(CONF.STRING.get(conf.NAME_ID).VALUE)
		item_node:getChildByName("exp_num"):setString("+" .. conf.VALUE) 
		item_node:getChildByName("icon_di"):loadTexture("RankLayer/ui/ui_avatar_" .. 1 + i .. ".png")

		local num = player:getItemNumByID(id)
		if num == nil or num < 0 then 
			num = 0
		end
		item_node:getChildByName("have_num"):setString(tostring(num))
		if num > 0 then 
			item_node:getChildByName("have_num"):setTextColor(cc.c3b(33, 255, 70))
		else 
			item_node:getChildByName("have_num"):setTextColor(cc.c3b(255, 145, 136))
		end
		item_node:getChildByName("background"):addClickEventListener(function ( sender )
			if self.curItem_ ~= nil then
				self.curItem_:getChildByName("button"):setVisible(false)
			end
			self.curItem_ = sender:getParent()
			self.curItem_:getChildByName("button"):setVisible(true)
		end)
		if i == 1 then
			self.curItem_ = item_node
			self.curItem_:getChildByName("button"):setVisible(true)
		end
	end

	local function recvMsg( )
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_ADD_STRENGTH_RESP") then
			playEffectSound("sound/system/use_item.mp3")
			local proto = Tools.decode("AddStrengthResp",strData)
			print("AddStrengthResp result...", proto.result)

			if proto.result == 'OK' then
				tips:tips(CONF:getStringValue("successful operation"))

				flurryLogEvent("potion_add_strength", {potion_id = tostring(self.s_item_id)}, 1, self.s_item_id)
		
				local credit_num = CONF.ITEM.get(self.s_item_id).BUY_VALUE
				flurryLogEvent("use_credit_add_strength", {potion_id = tostring(self.s_item_id), credit_num = credit_num}, 1, credit_num)
                if device.platform == "ios" or device.platform == "android" then
                    TDGAItem:onUse(tostring(self.s_item_id), 1)
                end
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function AddStrengthLayer:onExitTransitionStart()
	printInfo("AddStrengthLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return AddStrengthLayer