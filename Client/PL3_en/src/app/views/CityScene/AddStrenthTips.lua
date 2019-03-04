local player = require("app.Player"):getInstance()
local tips = require("util.TipsMessage"):getInstance()
local AddStrenthTips = class("AddStrenthTips", cc.load("mvc").ViewBase)

AddStrenthTips.RESOURCE_FILENAME = "CityScene/AddStrengthLayer_Tips.csb"

AddStrenthTips.NEED_ADJUST_POSITION = true

AddStrenthTips.RESOURCE_BINDING = {
	["cancel"] = { ["varname"] = "", ["events"] = {{["event"] = "touch", ["method"] = "OnBtnClick"}}},
	["buy_SureBtn"] = { ["varname"] = "", ["events"] = {{["event"] = "touch", ["method"] = "OnBtnClick"}}},
}

function AddStrenthTips:setGameData( )
	-- add strenth data 
	 local strenth_Data = Tools.encode("AddStrengthReq", {
				type = 2,
			})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ADD_STRENGTH_REQ"),strenth_Data)
end

function AddStrenthTips:OnBtnClick( event )
	if event.name == "ended" and event.target:getName() == "cancel" then 
		if self ~= nil then 
			if self.uiBg ~= nil then 
				self.uiBg:removeFromParent()
				self.uiBg = nil
			end
			self:removeFromParent()
		end
	elseif event.name == "ended" and event.target:getName() == "buy_SureBtn" then 
		local buyCounts = player:getUserInfo().strength_buy_times + 1
		if buyCounts >= 20 then 
			buyCounts = 20
		end
		-- no money
		local buyCost = CONF.STRENGTH.get(buyCounts).COST
		if player:getMoney() < buyCost then
			local function func()
				self:removeFromParent()
				local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

				rechargeNode:init(display:getRunningScene(), {index = 1})
				display:getRunningScene():addChild(rechargeNode)
			end

			local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
			return
		end

		-- max times 
		if player:getUserInfo().strength_buy_times >= CONF.VIP.get(player:getVipLevel()).STRENGTH_TIMES then 
			tips:tips(CONF:getStringValue("max_num_buy"))
			return
		end
		self:setGameData()
	end
end

function AddStrenthTips:createRichText( ... )

	local rn = self:getResourceNode()
	if rn:getChildByName("richText") then
		rn:getChildByName("richText"):removeFromParent()
	end
	
	if player:getUserInfo().strength_buy_times < CONF.VIP.get(player:getVipLevel()).STRENGTH_TIMES then
		rn:getChildByName("Text_1"):setVisible(false)
		local buyCounts = player:getUserInfo().strength_buy_times + 1
		if buyCounts >= 20 then 
			buyCounts = 20
		end

		local string1 = "#FFFFFF02"..CONF:getStringValue("but_tili_1")
		local string2 = "#21FF4602"..CONF.STRENGTH.get(buyCounts).COST
		local string3 = "#FFF47902"..CONF:getStringValue("IN_7001")
		local string4 = "#FFFFFF02"..CONF:getStringValue("Buy")
		local string5 = "#21FF4602"..CONF.STRENGTH.get(buyCounts).VALUE
		local string6 = "#FDCD6F02"..CONF:getStringValue("IN_8001")
		local string7 = "#FFFFFF02".."?"
        local string8 = "      "

        local str = string1..string8..string2..string4..string5..string6..string7
--		local str = string1..string2..string3..string4..string5..string6..string7
		local richText = createRichTextNeedChangeColor(str,22)
		richText:setContentSize(cc.size(rn:getChildByName("Text_1"):getContentSize().width, rn:getChildByName("Text_1"):getContentSize().height))
		richText:ignoreContentAdaptWithSize(false)
		richText:setAnchorPoint(cc.p(0,1))
		richText:setName("richText")
		richText:setPosition(cc.p(rn:getChildByName("Text_1"):getPosition()))
		rn:addChild(richText)
		self.buyCount:setString(tostring(player:getUserInfo().strength_buy_times) .. "/" .. CONF.VIP.get(player:getVipLevel()).STRENGTH_TIMES)
		self.use_credit = CONF.STRENGTH.get(buyCounts).VALUE
	else
		self.buyCount:setVisible(false)
		rn:getChildByName("Text_1_0_0_0"):setVisible(false)
		rn:getChildByName("Text_1"):setVisible(true)
		rn:getChildByName("Text_1"):setString("increase_purchases")
	end
	

end

function AddStrenthTips:onEnterTransitionFinish( )

	local rn = self:getResourceNode()

	rn:getChildByName("uibg"):addClickEventListener(function ( sender )
		self:removeFromParent()
	end)

	rn:getChildByName("Text_1_0_0_0"):setString(CONF:getStringValue("but_tili_2"))

	rn:getChildByName("buy_SureBtn"):getChildByName("strenth_text_text_0_0"):setString(CONF:getStringValue("yes"))
	rn:getChildByName("cancel"):getChildByName("strenth_text_text_0"):setString(CONF:getStringValue("cancel"))

	rn:getChildByName("strenth_count"):setPositionX(rn:getChildByName("Text_1_0_0_0"):getPositionX() + rn:getChildByName("Text_1_0_0_0"):getContentSize().width)

	local buyCounts = player:getUserInfo().strength_buy_times + 1
	if buyCounts >= 20 then 
		buyCounts = 20
	end

	self.buyCount = rn:getChildByName("strenth_count")
    rn:getChildByName("zuan"):setVisible(true)
	self:createRichText()


	local function recvMsg( )
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_ADD_STRENGTH_RESP") then 
			local proto = Tools.decode("AddStrengthResp",strData)
			print("===========xinyongdian...", proto.result)
			if proto.result == "OK" then
				-- self:setBuyInfo()
				flurryLogEvent("credit_buy_strength", {cost = tostring(self.use_credit), count = self.buyCount}, 1, self.use_credit)

				self:createRichText()

				tips:tips(CONF:getStringValue("buy_success"))

			end
			
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end


function AddStrenthTips:onExitTransitionStart()
	printInfo("AddStrenthTips:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end

return AddStrenthTips