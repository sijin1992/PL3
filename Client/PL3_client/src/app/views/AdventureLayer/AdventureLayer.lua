
local AdventureLayer = class("AdventureLayer", cc.load("mvc").ViewBase)
local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local app = require("app.MyApp"):getInstance()

local schedulerEntry = nil

local lt = nil

AdventureLayer.RESOURCE_FILENAME = "AdventureLayer/AdventureLayer.csb"

AdventureLayer.RUN_TIMELINE = true

AdventureLayer.NEED_ADJUST_POSITION = true

local cardMove = false

function AdventureLayer:onCreate( data )-- {id=,get=bool,new=bool}
	self.data_ = data
end

function AdventureLayer:onEnter()
  
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

	local rtTime = string.format("%s"..CONF:getStringValue("days").."%s:%s:%s", day ,hour, minute, second)
	return rtTime
end

function AdventureLayer:onExit()
	
	printInfo("PlanetScene:onExit()")
end

function AdventureLayer:onEnterTransitionFinish()
	cc.exports.new_hand_gift_bag_data = false
	lt = nil
	printInfo("AdventureLayer:onEnterTransitionFinish()")
	cardMove = false
	local rn = self:getResourceNode()
	-- rn:getChildByName("title"):setVisible(true)
	-- rn:getChildByName("title"):setString(CONF:getStringValue("fortuitous bag"))
	-- rn:getChildByName("num"):setVisible(true)
	local newHandGigt = player:getNewHandGift()
	-- for i=1,3 do
	-- 	rn:getChildByName("Panel"):getChildByName("img_"..i):setVisible(false)
	-- end
	-- self.panel_ = require("util.PanelDelegate"):create(rn:getChildByName("Panel"))
	-- self.panel_:getPanel():setSwallowTouches(false)
	if newHandGigt.new_hand_gift_bag_list == nil or Tools.isEmpty(newHandGigt.new_hand_gift_bag_list) then
		self:removeFromParent()
		return
	end
	-- rn:getChildByName("num"):setString(CONF:getStringValue("trigger time")..":"..newHandGigt.times.."/3")
	-- local function update()
	-- 	local newHandGigt2 = player:getNewHandGift()
	-- 	if newHandGigt2.new_hand_gift_bag_list == nil or Tools.isEmpty(newHandGigt2.new_hand_gift_bag_list)then
	-- 		self:removeFromParent()
	-- 		return
	-- 	end
	-- 	rn:getChildByName("num"):setString(CONF:getStringValue("trigger time")..":"..newHandGigt2.times.."/3")
	-- 	if newHandGigt2.times ~= newHandGigt.times then
	-- 		self:resetPanel()
	-- 	end
	-- 	if not(newHandGigt.new_hand_gift_bag_list) then
	-- 		newHandGigt.new_hand_gift_bag_list = {}
	-- 	end
	-- 	if not(newHandGigt2.new_hand_gift_bag_list) then
	-- 		newHandGigt2.new_hand_gift_bag_list = {}
	-- 	end
	-- 	if #newHandGigt.new_hand_gift_bag_list ~= #newHandGigt2.new_hand_gift_bag_list then
	-- 		self:resetPanel()
	-- 	end
	-- 	newHandGigt = newHandGigt2
	-- end
	-- update()
	-- self:openTouchEvent2()
	-- if schedulerEntry == nil then
	--  	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)
	-- end
	rn:getChildByName("FileNode_1"):getChildByName("btn_left"):addClickEventListener(function()
		self:resetNode("left")
		end)
	rn:getChildByName("FileNode_1"):getChildByName("btn_right"):addClickEventListener(function()
		self:resetNode("right")
		end)
	animManager:runAnimByCSB(rn:getChildByName("FileNode_1"):getChildByName("FileNode_2"), "AdventureLayer/sfx/baoshi/baoshi.csb", "1")
	self.selectNode = 1
	if self.data_ and self.data_.new then
		self.selectNode = #newHandGigt.new_hand_gift_bag_list
	end
	self:resetNode()
	rn:getChildByName("close"):addClickEventListener(function()
		self:removeFromParent()
		end)
	local function recvMsg( ) -- 模拟
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SDK_PAY_CALLBACK") then
			gl:releaseLoading()
			print("AdventureLayer strData",strData)
			local output = json.decode(strData,1)
			if output.result == 0 then
				local serNewHand = player:getSerNewHand()
				tips:tips(CONF:getStringValue("buy_success"))
				self:removeFromParent()
				local newHandId
				local gift_id
				for k,v in pairs(CONF.RECHARGE.getIDList()) do
					local conf = CONF.RECHARGE.get(v)
					if conf.PRODUCT_ID == output.productid then
						newHandId = conf.GIFT_ID
						gift_id = conf.ID
					end
				end
				if Tools.isEmpty(serNewHand) == false and newHandId then
					if Tools.isEmpty(serNewHand.new_hand_gift_bag_list) == false then
						for w,l in ipairs(serNewHand.new_hand_gift_bag_list) do
							if l.id == newHandId then
								table.remove(serNewHand.new_hand_gift_bag_list,w) 
							end
						end
					end
					player:setSerNewHand(serNewHand)
				end
				if newHandId and gift_id then
					local info = {}
					info.id = newHandId
					info.gift_id = gift_id
					app:addView2Top("AdventureLayer/SuccessLayer",{info = info,get = true})
				else
					tips:tips(CONF:getStringValue("buy_success"))
				end
			else
				tips:tips(CONF:getStringValue("buy_error"))
				self:removeFromParent()
			end
		end
	end

	local eventDispatcher = self:getEventDispatcher()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	-- eventDispatcher:addEventListenerWithFixedPriority(self.payListener_, FixedPriority.kNormal)

	-- 180724 wjj 
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Libao(self)

end

function AdventureLayer:resetNode(direction) -- "left","right"
	if Tools.isEmpty(player:getNewHandGift()) then
		if schedulerEntry ~= nil then
		 	scheduler:unscheduleScriptEntry(schedulerEntry)
		 	schedulerEntry = nil
		end
		self:removeFromParent()
	end
	if Tools.isEmpty(player:getNewHandGift().new_hand_gift_bag_list[self.selectNode]) then
		self.selectNode = 1
	end
	local canreturn = false
	if direction == "left" then
		if Tools.isEmpty(player:getNewHandGift().new_hand_gift_bag_list[self.selectNode - 1]) == false then
			self.selectNode = self.selectNode - 1
		else
			canreturn = true
		end
	elseif direction == "right" then
		if Tools.isEmpty(player:getNewHandGift().new_hand_gift_bag_list[self.selectNode + 1]) == false then
			self.selectNode = self.selectNode + 1
		else
			canreturn = true
		end
	end
	-- self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_left"):setBright(true)
	-- self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_right"):setBright(true)
	-- self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_left"):setTouchEnabled(true)
	-- self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_right"):setTouchEnabled(true)
	-- if Tools.isEmpty(player:getNewHandGift().new_hand_gift_bag_list[self.selectNode - 1]) then
	-- 	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_left"):setBright(false)
	-- 	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_left"):setTouchEnabled(false)
	-- end
	-- if Tools.isEmpty(player:getNewHandGift().new_hand_gift_bag_list[self.selectNode + 1]) then
	-- 	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_right"):setBright(false)
	-- 	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_right"):setTouchEnabled(false)
	-- end
	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_left"):setVisible(true)
	self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_right"):setVisible(true)
	if Tools.isEmpty(player:getNewHandGift().new_hand_gift_bag_list[self.selectNode - 1]) then
		self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_left"):setVisible(false)
	end
	if Tools.isEmpty(player:getNewHandGift().new_hand_gift_bag_list[self.selectNode + 1]) then
		self:getResourceNode():getChildByName("FileNode_1"):getChildByName("btn_right"):setVisible(false)
	end
	if canreturn then
		return
	end
	local info = player:getNewHandGift().new_hand_gift_bag_list[self.selectNode]
	local newHand = CONF.NEWHANDGIFTBAG.get(info.id)
	local recharge_conf = CONF.RECHARGE.get(info.gift_id)
	local node = self:getResourceNode():getChildByName("FileNode_1")
	node:getChildByName("gift_bg"):setTexture("AdventureLayer/ui/"..newHand.RESOURCE_BG..".png")
	node:getChildByName("giftBagName"):setTexture("AdventureLayer/ui/"..newHand.NAME..".png")
    node:getChildByName("Text_des"):setString(CONF:getStringValue("limitNum"))
--	local pre = math.floor(recharge_conf["RECHARGE_"..server_platform]/newHand["PRICE_"..server_platform]*10)
--	if pre == 0 then pre = 1 end
--	node:getChildByName("num"):setTexture("AdventureLayer/ui/num_"..pre..".png")
    -- en
    local pre = tonumber(string.format("%.2f",recharge_conf["RECHARGE_"..server_platform]/newHand["PRICE_"..server_platform]))
    local off = (1 - pre)*100
    if off < 10 then
        node:getChildByName("num_0"):setVisible(false)
        node:getChildByName("num"):setTexture("AdventureLayer/ui/num_"..off..".png")
    else
        local One = math.floor(off / 10)
        local Ten = off % 10
        node:getChildByName("num"):setTexture("AdventureLayer/ui/num_"..One..".png")
        node:getChildByName("num_0"):setTexture("AdventureLayer/ui/num_"..Ten..".png")
    end


	local time = newHand.TIME - (player:getServerTime() - info.start_time)
	node:getChildByName("Text_time"):setString(formatTimeNow(time))
	if time < 0 then time = 0 end
	if time > newHand.TIME then time = newHand.TIME end
	local updateTime = function()
		local info = player:getNewHandGift().new_hand_gift_bag_list[self.selectNode]
		local newHand = CONF.NEWHANDGIFTBAG.get(info.id)
		local time = newHand.TIME - (player:getServerTime() - info.start_time)
		if time < 0 then time = 0 end
		if time > newHand.TIME then time = newHand.TIME end
		node:getChildByName("Text_time"):setString(formatTimeNow(time))
		node:getChildByName("Text_des"):setPositionX(node:getChildByName("Text_time"):getPositionX()-node:getChildByName("Text_time"):getContentSize().width)
		if time <= 0 then
			self:resetPanel()
		end
	end
	node:getChildByName("Text_des"):setPositionX(node:getChildByName("Text_time"):getPositionX()-node:getChildByName("Text_time"):getContentSize().width)
	if not schedulerEntry then
		schedulerEntry = scheduler:scheduleScriptFunc(updateTime,1,false)
	end
	if not self.list then
		self.list = require("util.ScrollViewDelegate"):create(node:getChildByName("list"),cc.size(1,1), cc.size(221,54))
	end
	self.list:clear()
	self.list:getScrollView():setScrollBarEnabled(false)
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
		self.list:addElement(node_item)
	end
	node:getChildByName("ok"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	node:getChildByName("ok"):getChildByName("text"):setVisible(false)
	node:getChildByName("ok"):addClickEventListener(function()
		print("device.platform  ",device.platform)
		if device.platform == "ios" or device.platform == "android" then
            if( require("util.ExSDK"):getInstance():IsQuickSDK() ) then
				require("util.ExSDK"):getInstance():wxPay(recharge_conf)
            end
			-- GameHandler.handler_c.payStart(recharge_conf.PRODUCT_ID)
			-- gl:retainLoading()
		end
		end)
	local img = node:getChildByName("ok"):getChildByName("normal"):getChildByName("Image_4")
	local old = node:getChildByName("ok"):getChildByName("normal"):getChildByName("old")
	local new = node:getChildByName("ok"):getChildByName("normal"):getChildByName("new")
	old:setString(CONF:getStringValue("coin_sign")..newHand["PRICE_"..server_platform])
	new:setString(CONF:getStringValue("coin_sign")..recharge_conf["RECHARGE_"..server_platform])
	old:setPositionX(img:getPositionX()-img:getContentSize().width/2)
	new:setPositionX(img:getPositionX()+img:getContentSize().width/2)
end

-- function AdventureLayer:resetPanel()
-- 	self.selectIndex_ = 2

-- 	local newHandGigt = player:getNewHandGift()

-- 	local rn = self:getResourceNode()

-- 	self.panel_:clear()
-- 	for i=1,3 do
-- 		rn:getChildByName("dian_"..i):setVisible(false)
-- 		if schedulerEntrys[i] then
-- 			scheduler:unscheduleScriptEntry(schedulerEntrys[i])
-- 		 	schedulerEntrys[i] = nil
-- 		end
-- 	end
-- 	if #newHandGigt.new_hand_gift_bag_list == 2 then
-- 		rn:getChildByName("dian_2"):setVisible(true)
-- 		rn:getChildByName("dian_1"):setVisible(true)
-- 	elseif #newHandGigt.new_hand_gift_bag_list == 3 then
-- 		for i=1,3 do
-- 			rn:getChildByName("dian_"..i):setVisible(true)
-- 		end
-- 	end
-- 	for i,v in ipairs(newHandGigt.new_hand_gift_bag_list) do
-- 		if i > 3 then break end 
-- 		local conf = CONF.NEWHANDGIFTBAG.get(v.id)
-- 		local node = require("app.views.AdventureLayer.GiftNode"):creatGiftNode(v,false)
-- 		local n = 1
-- 		if i == 1 then 
-- 			n = 2
-- 		elseif i == 2 then
-- 			n = 1
-- 		elseif i == 3 then
-- 			n = 3
-- 		end 
-- 		local time = conf.TIME - (player:getServerTime() - v.start_time)
-- 		if time < 0 then time = 0 end
-- 		if time > conf.TIME then time = conf.TIME end
-- 		local updateTime = function()
-- 			local time = conf.TIME - (player:getServerTime() - v.start_time)
-- 			if time < 0 then time = 0 end
-- 			if time > conf.TIME then time = conf.TIME end
-- 			-- node:getChildByName("Node_normal"):getChildByName("time"):setString(formatTimeNow(time))
-- 			if time <= 0 then
-- 				self:resetPanel()
-- 			end
-- 		end
-- 		if not schedulerEntrys[i] then
-- 			schedulerEntrys[i] = scheduler:scheduleScriptFunc(updateTime,1,false)
-- 		end
-- 		-- node:getChildByName("Node_normal"):getChildByName("time"):setString(formatTimeNow(time))
-- 		node:setTag(n)
-- 		if n == self.selectIndex_ then
-- 			node:getChildByName("ok"):setTouchEnabled(true)
-- 			node:getChildByName("list"):setTouchEnabled(true)
-- 		else
-- 			node:getChildByName("ok"):setTouchEnabled(false)
-- 			node:getChildByName("list"):setTouchEnabled(false)
-- 		end
-- 		if n == self.selectIndex_ then
-- 			node:setPosition(rn:getChildByName("Panel"):getChildByName("img_2"):getPosition())
-- 			node:setScale(1)
-- 			-- node:getChildByName("mask"):setOpacity(0)
-- 		elseif n == self.selectIndex_ + 1 then
-- 			node:setPosition(rn:getChildByName("Panel"):getChildByName("img_3"):getPosition())
-- 			node:setScale(0.9)
-- 			-- node:getChildByName("mask"):setOpacity(0.2*255)
-- 		elseif n == self.selectIndex_ - 1 then
-- 			node:setPosition(rn:getChildByName("Panel"):getChildByName("img_1"):getPosition())
-- 			node:setScale(0.9)
-- 			-- node:getChildByName("mask"):setOpacity(0.2*255)
-- 		end
		

-- 		if n == self.selectIndex_ then
-- 			node:setLocalZOrder(10)
-- 		elseif n == self.selectIndex_ + 1 or n == self.selectIndex_ - 1  then
-- 			node:setLocalZOrder(9)
-- 		end



-- 		--
-- 		local isTouchMe = false

-- 		local function onTouchBegan(touch, event)

-- 			if cardMove then
-- 				return false
-- 			end

-- 			local target = event:getCurrentTarget()
			
-- 			local locationInNode = target:convertToNodeSpace(touch:getLocation())
-- 			local s = target:getContentSize()
-- 			local rect = cc.rect(0, 0, s.width, s.height)
			
-- 			if cc.rectContainsPoint(rect, locationInNode) then
-- 				isTouchMe = true

-- 				if target:getParent():getLocalZOrder() == 10 then 
-- 					target:getParent():stopAllActions()
-- 					-- target:getParent():setScale(0.8)
-- 					target:getParent():runAction(cc.ScaleTo:create(0.1, 0.8))
-- 				end

-- 				return true
-- 			end

-- 			return false
-- 		end

-- 		local function onTouchMoved(touch, event)

-- 			local diff = touch:getDelta()
-- 			if math.abs(diff.x) < g_click_delta and math.abs(diff.y) < g_click_delta then
				
-- 			else
-- 				isTouchMe = false
-- 			end
			
-- 		end

-- 		local function onTouchEnded(touch, event)
-- 			local target = event:getCurrentTarget()

-- 			if isTouchMe == true then     
				
-- 				if target:getParent():getLocalZOrder() == 10 then 
-- 					target:getParent():runAction(cc.Sequence:create(cc.ScaleTo:create(0.1, 1)))
-- 					playEffectSound("sound/system/choose_map.mp3")
-- 				end
-- 			else
-- 				-- target:getParent():setScale(1)

-- 				if target:getParent():getLocalZOrder() == 10 then 
-- 					target:getParent():runAction(cc.ScaleTo:create(0.1, 1))
-- 				end

-- 			end
-- 		end


-- 		local listener = cc.EventListenerTouchOneByOne:create()
-- 		listener:setSwallowTouches(false)
-- 		listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
-- 		listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
-- 		listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
-- 		local eventDispatcher = self.panel_:getPanel():getEventDispatcher()
-- 		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node:getChildByName("gift_bg"))


-- 		self.panel_:addElement(node, nil)
-- 	end
-- end

-- function AdventureLayer:openTouchEvent2()
-- 	local rn = self:getResourceNode()
-- 	local function onTouchBegan(touch, event)

-- 		local target = event:getCurrentTarget()
-- 		lt = touch:getLocation()
		
-- 		local locationInNode = target:convertToNodeSpace(touch:getLocation())
-- 		local s = target:getContentSize()
-- 		local rect = cc.rect(0, 0, s.width, s.height)

-- 		if cardMove then
-- 			return false
-- 		end
		
-- 		if cc.rectContainsPoint(rect, locationInNode) then

-- 			return true
-- 		end

-- 		return false
-- 	end


-- 	local function onTouchEnded(touch, event)

-- 		local newHandGigt = player:getNewHandGift()
-- 		if not newHandGigt.new_hand_gift_bag_list then
-- 			newHandGigt.new_hand_gift_bag_list = {}
-- 		end
-- 		local location = touch:getLocation()
-- 		local target = event:getCurrentTarget()

-- 		if location.x - lt.x > 0 then
-- 			if self.selectIndex_ + 1 > #newHandGigt.new_hand_gift_bag_list then
-- 				return
-- 			end

-- 			self.selectIndex_ = self.selectIndex_ + 1
			
-- 		elseif location.x - lt.x < 0 then
			
-- 			if self.selectIndex_ - 1 < 1 then
-- 				return
-- 			end
-- 			if #newHandGigt.new_hand_gift_bag_list <= 1 then
-- 				return
-- 			end
-- 			self.selectIndex_ = self.selectIndex_ - 1
-- 		end

-- 		cardMove = true
-- 		self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
-- 			cardMove = false
-- 		end)))

-- 		playEffectSound("sound/system/move_map.mp3")

-- 		local children = self.panel_:getPanel():getChildren()
-- 		for i=1,3 do
-- 			rn:getChildByName("dian_"..i):setTexture("AdventureLayer/ui/dian1.png")
-- 		end
-- 		for i,v in ipairs(children) do
-- 			v:stopAllActions()

-- 			if v:getTag() == self.selectIndex_ then
-- 				v:runAction(cc.Spawn:create(cc.MoveTo:create(0.2,cc.p(rn:getChildByName("Panel"):getChildByName("img_2"):getPositionX(),rn:getChildByName("Panel"):getChildByName("img_1"):getPositionY())), cc.ScaleTo:create(0.2, 1)))
-- 				v:setLocalZOrder(10)
-- 				v:getChildByName("mask"):setOpacity(0)
-- 				rn:getChildByName("dian_"..self.selectIndex_):setTexture("AdventureLayer/ui/dian2.png")
-- 				v:getChildByName("ok"):setTouchEnabled(true)
-- 				v:getChildByName("list"):setTouchEnabled(true)
-- 			elseif v:getTag() == self.selectIndex_ + 1 then
-- 				v:runAction(cc.Spawn:create(cc.MoveTo:create(0.2, cc.p(rn:getChildByName("Panel"):getChildByName("img_3"):getPositionX(),rn:getChildByName("Panel"):getChildByName("img_2"):getPositionY())), cc.ScaleTo:create(0.2, 0.9)))
-- 				v:setLocalZOrder(9)
-- 				v:getChildByName("mask"):setOpacity(0.2*255)
-- 				rn:getChildByName("dian_"..(self.selectIndex_+1)):setTexture("AdventureLayer/ui/dian1.png")
-- 				v:getChildByName("ok"):setTouchEnabled(false)
-- 				v:getChildByName("list"):setTouchEnabled(false)
-- 			elseif v:getTag() == self.selectIndex_  - 1 then
-- 				v:runAction(cc.Spawn:create(cc.MoveTo:create(0.2, cc.p(rn:getChildByName("Panel"):getChildByName("img_1"):getPositionX(),rn:getChildByName("Panel"):getChildByName("img_3"):getPositionY())), cc.ScaleTo:create(0.2, 0.9)))
-- 				v:setLocalZOrder(9)
-- 				v:getChildByName("mask"):setOpacity(0.2*255)
-- 				rn:getChildByName("dian_"..(self.selectIndex_-1)):setTexture("AdventureLayer/ui/dian1.png")
-- 				v:getChildByName("ok"):setTouchEnabled(false)
-- 				v:getChildByName("list"):setTouchEnabled(false)
-- 			end

-- 		end
-- 		rn:getChildByName("dian_2"):setPositionX(rn:getChildByName("dian_3"):getPositionX()+rn:getChildByName("dian_3"):getContentSize().width+4)	
-- 		rn:getChildByName("dian_1"):setPositionX(rn:getChildByName("dian_2"):getPositionX()+rn:getChildByName("dian_2"):getContentSize().width+4)	
-- 	end

-- 	local listener = cc.EventListenerTouchOneByOne:create()
-- 	listener:setSwallowTouches(true)
-- 	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
-- 	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
-- 	local eventDispatcher = self:getEventDispatcher()
-- 	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.panel_:getPanel())
-- end

function AdventureLayer:onExitTransitionStart()
	printInfo("AdventureLayer:onExitTransitionStart()")
	if schedulerEntry ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerEntry)
	 	schedulerEntry = nil
	end
	local eventDispatcher = self:getEventDispatcher()
	-- eventDispatcher:removeEventListener(self.payListener_)
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return AdventureLayer