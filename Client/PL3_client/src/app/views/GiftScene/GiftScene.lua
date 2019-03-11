
local GiftScene = class("GiftScene", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local app = require("app.MyApp"):getInstance()

local schedulerEntry = {}

GiftScene.RESOURCE_FILENAME = "GiftScene/GiftScene.csb"

GiftScene.RUN_TIMELINE = true

GiftScene.NEED_ADJUST_POSITION = true

function GiftScene:onCreate( data )
	self.data_ = data
end

function GiftScene:onEnter()
  
	printInfo("PlanetScene:onEnter()")

end

local function formatTimeNow(time)
	
	if time < 0 then
		time = 0
	end

	time = math.floor(time)
	local day = math.floor(time/(3600*24))
	local hour = math.fmod(math.floor(time/3600), 24);
	local minute = math.fmod(math.floor(time/60), 60)
	local second = math.fmod(time, 60)

	if hour<10 then
		hour = string.format("0%s",hour)
	end

	if minute<10 then
		minute = string.format("0%s",minute)
	end

	if second<10 then
		second = string.format("0%s",second)
	end
	local rtTime
	if day > 0 then
		rtTime = string.format("%s天 %s:%s:%s", day ,hour, minute, second)
	else
		rtTime = string.format("%s:%s:%s",hour, minute, second)
	end
	return rtTime
end

function GiftScene:onExit()
	
	printInfo("GiftScene:onExit()")
end

function GiftScene:onEnterTransitionFinish()
	printInfo("GiftScene:onEnterTransitionFinish()")
	local rn = self:getResourceNode()
	local giftData = player:getGiftData()
	rn:getChildByName("close"):addClickEventListener(function()
		self:getApp():popView()
	end)
	rn:getChildByName("giftname"):setString(CONF:getStringValue("libao"))
	rn:getChildByName("tishi_des"):setString(CONF:getStringValue("hint")..":")
	rn:getChildByName("tishi_text"):setString(CONF:getStringValue("xingmengfenxiangtishi"))
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(0,-6), cc.size(360,520))
	rn:getChildByName("list"):setScrollBarEnabled(false)
	if Tools.isEmpty(giftData) then
		rn:getChildByName("text_null"):setVisible(true)
	else
		rn:getChildByName("text_null"):setVisible(false)
		self:resetList()
	end
	local function recvMsg( ) -- 模拟
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SDK_PAY_CALLBACK") then
			gl:releaseLoading()
			local output = json.decode(strData,1)
			if output.result == 0 then
				local items = {}
				for k,v in pairs(output.item_list) do
					table.insert(items,{id = v.id,num = v.num})
				end
				local node = require("util.RewardNode"):createGettedNodeWithList(items)
				tipsAction(node)
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)
			else
				tips:tips(CONF:getStringValue("buy_error"))
			end
		end
	end

	local eventDispatcher = self:getEventDispatcher()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function GiftScene:resetList()
	local rn = self:getResourceNode()
	self.svd_:clear()
	local giftData = player:getGiftData()
	if Tools.isEmpty(giftData) == false then
		for k,v in ipairs(giftData) do
			local node = self:creatNode(v)
			self.svd_:addElement(node)
		end
	end
end

function GiftScene:creatNode(info)
	local node =  cc.CSLoader:createNode("GiftScene/GiftNode.csb")
	local newHand = CONF.NEWHANDGIFTBAG.get(info.id)
	local recharge_conf = CONF.RECHARGE.get(newHand.REWARD[1])
	local time = newHand.TIME - (player:getServerTime() - info.start_time)
	node:getChildByName("time_num"):setString(formatTimeNow(time))
	node:getChildByName("time_des"):setString(CONF:getStringValue("goumaidaojishi")..":")
	node:getChildByName("name_img"):setTexture("GiftScene/ui/"..newHand.NAME..".png")
	node:getChildByName("gift_img"):setTexture("GiftScene/ui/"..newHand.RESOURCE_BG..".png")
	if time < 0 then time = 0 end
	if time > newHand.TIME then time = newHand.TIME end
	local updateTime = function()
		local time = newHand.TIME - (player:getServerTime() - info.start_time)
		if time < 0 then time = 0 end
		if time > newHand.TIME then time = newHand.TIME end
		print("",type(node:getChildByName("time_num")))
		node:getChildByName("time_num"):setString(formatTimeNow(time))
		if time <= 0 then
			if schedulerEntry[info.id] then
				scheduler:unscheduleScriptEntry(schedulerEntry[info.id])
			 	schedulerEntry[info.id] = nil
			end
			self:resetList()
		end
	end
	if not schedulerEntry[info.id] then
		schedulerEntry[info.id] = scheduler:scheduleScriptFunc(updateTime,1,false)
	end
	local list = require("util.ScrollViewDelegate"):create(node:getChildByName("list"),cc.size(0,0), cc.size(310,90))
	node:getChildByName("list"):setScrollBarEnabled(false)
	local items = {}
	print("@@@@@@@@@@@@",recharge_conf.GIFT_ID,newHand.REWARD[1])
	local gift = CONF.REWARD.get(recharge_conf.GIFT_ID)
	if gift ~= nil then
		for i,id in ipairs(gift.ITEM) do
			table.insert(items,{id = id,num = gift.COUNT[i]})
		end

		for k,v in ipairs(items) do
			local node_item = cc.CSLoader:createNode("GiftScene/ItemNode.csb")
			local cfg_item = CONF.ITEM.get(v.id)
			node_item:getChildByName("num"):setString("x"..v.num)
			node_item:getChildByName("name"):setString(CONF:getStringValue(cfg_item.NAME_ID))
			node_item:getChildByName("item"):getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..cfg_item.QUALITY..".png")
			node_item:getChildByName("item"):getChildByName("icon"):loadTexture("ItemIcon/"..cfg_item.ICON_ID..".png")
			local namejb = node_item:getChildByName("name")
			local numjb = node_item:getChildByName("num")
			if namejb:getPositionX()+namejb:getContentSize().width > numjb:getPositionX() then
				numjb:setPositionX(namejb:getPositionX()+namejb:getContentSize().width+2)
			end
			local function func()
				addItemInfoTips( cfg_item )
			end
			local callback = {node = node_item:getChildByName("item"):getChildByName("background"), func = func}
			list:addElement(node_item,{callback = callback})
		end
	end
	node:getChildByName("ok"):getChildByName("text"):setString(CONF:getStringValue("coin_sign")..newHand["PRICE_"..server_platform])
	node:getChildByName("ok"):addClickEventListener(function()
		print("device.platform  ",device.platform)
		if device.platform == "ios" or device.platform == "android" then
            if( require("util.ExSDK"):getInstance():IsQuickSDK() ) then
				require("util.ExSDK"):getInstance():wxPay(recharge_conf)
			else
			    GameHandler.handler_c.payStart(recharge_conf.PRODUCT_ID)
			    gl:retainLoading()
            end
		end
		end)
	-- old:setString(CONF:getStringValue("coin_sign")..newHand["PRICE_"..server_platform])
	-- new:setString(CONF:getStringValue("coin_sign")..recharge_conf["RECHARGE_"..server_platform])
	return node
end


function GiftScene:onExitTransitionStart()
	printInfo("GiftScene:onExitTransitionStart()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	for k,v in pairs(schedulerEntry) do
		if schedulerEntry[k] then
			scheduler:unscheduleScriptEntry(schedulerEntry[k])
		 	schedulerEntry[k] = nil
		end
	end
end

return GiftScene