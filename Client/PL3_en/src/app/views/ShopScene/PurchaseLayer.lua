local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local PurchaseLayer = class("PurchaseLayer", cc.load("mvc").ViewBase)

PurchaseLayer.RESOURCE_FILENAME = "ShopScene/PurchaseNode.csb"

--PurchaseLayer.NEED_ADJUST_POSITION = true


function PurchaseLayer:onCreate(data)--{confList  , ID }
	print("id ========" ,data.ID)
	self.data_ = data
	local infoList = player:getUserInfo().shop_data.goods_list
	if #infoList > 0 then
		for k,v in pairs(infoList) do
			print(k,v)
			if v.id == data.ID then           
				self.info = v           
				break
			end
		end
	end
	for k,v in pairs(self.data_.confList) do
		if v.ID == data.ID then
			self.conf = v
			break
		end
	end
end

function PurchaseLayer:onEnterTransitionFinish()
	--noLimitNotic
	self:addTouch()
	local rn = self:getResourceNode()
	rn:getChildByName("background"):getChildByName("name"):setVisible(false)
	rn:getChildByName("background"):getChildByName("close"):setVisible(false)
	local itemConf = CONF.ITEM.get(self.conf.ITEM)
	local price = self.conf.COST
	local costNum = rn:getChildByName("costNum")
	rn:getChildByName("name"):setString(CONF:getStringValue(itemConf.NAME_ID))
	rn:getChildByName("icon"):loadTexture("ItemIcon/" .. itemConf.ICON_ID .. ".png")
	rn:getChildByName("icon"):addClickEventListener(function ( sender )
		addItemInfoTips(itemConf)
	end)

	if itemConf.TYPE == 10 then
		rn:getChildByName("level"):setVisible(true)
		rn:getChildByName("level_num"):setVisible(true)

		rn:getChildByName("level_num"):setString(CONF.EQUIP.get(itemConf.ID).LEVEL)
	elseif itemConf.TYPE == 9 then
		rn:getChildByName("level"):setVisible(true)
		rn:getChildByName("level_num"):setVisible(true)

		rn:getChildByName("level_num"):setString(CONF.GEM.get(itemConf.ID).LEVEL)
	end


	rn:getChildByName("iconBg"):setTexture("RankLayer/ui/ui_avatar_" .. itemConf.QUALITY .. ".png")
	rn:getChildByName("iconBg"):setVisible(true)
	if self.conf.COST_TYPE == 1 then
		rn:getChildByName("sprMoney"):removeFromParent()
		self.money = player:getResByIndex(1)
	elseif self.conf.COST_TYPE == 2 then
		rn:getChildByName("sprGold"):removeFromParent() 
		self.money = player:getMoney()
	elseif self.conf.COST_TYPE == 3 then
		rn:getChildByName("sprGold"):removeFromParent() 
		rn:getChildByName("sprMoney"):removeFromParent()
		rn:getChildByName("sprContribution"):setVisible(true)
		self.money = player:getGroupData().contribute
	end
	costNum:setString(price)
	if price > self.money then
		costNum:setTextColor(cc.c4b(255, 0, 0, 255))
		-- costNum:enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
	end

	rn:getChildByName("num"):setString(CONF:getStringValue("sumNum"))
	rn:getChildByName("cost"):setString(CONF:getStringValue("Cost"))
	rn:getChildByName("itemNum"):setString("x"..self.conf.ITEM_NUM)

	if self.conf.TIMES > 0 then -- 限购
		local buyTimes = 0
		if self.info == nil then
			buyTimes = 0
		elseif self.info.buy_times == nil then
			buyTimes = 0 
		else 
			buyTimes = self.info.buy_times
		end

		self.maxNum = self.conf.TIMES - buyTimes


	else 
		self.maxNum = 99
	end 

	
	rn:getChildByName("sum"):setString("/" .. self.maxNum)
	--self:addEditBox()

	local btnBuy = rn:getChildByName("btnBuy")
	btnBuy:getChildByName("text"):setString(CONF:getStringValue("Buy"))
	btnBuy:addClickEventListener(function (  )

		local scene = self:getParent()

		if self.money < tonumber(costNum:getString()) then
			if self.conf.COST_TYPE == 1 then
				tips:tips(CONF:getStringValue("notEnoughGold"))
			elseif self.conf.COST_TYPE == 2 then
				-- tips:tips(CONF:getStringValue("no enought credit"))
				local function func()

					local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

					rechargeNode:init(scene, {index = 1})
					scene:addChild(rechargeNode)


				end

				local messageBox = require("util.MessageBox"):getInstance()
				messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)

				self:removeFromParent()
			else
				tips:tips(CONF:getStringValue("contribution insufficient"))

			end
		else 
			if self.maxNum <= 0 then
				tips:tips(CONF:getStringValue("max_num_buy"))
				return
			end
			print("id = num=" ,self.conf.ID ,costNum:getString())
			-- 2018-11-28 yaorichang
			-- 判断资源上限
			local confitem = CONF.ITEM.get(self.conf.ITEM)
			if confitem and confitem.TYPE >= CONF.EItemType.kRes1 and confitem.TYPE <= CONF.EItemType.kRes4 then
				local count =  tonumber(rn:getChildByName("buyNum"):getString()) * self.conf.ITEM_NUM
				local buildconf = CONF.BUILDING_10.get(player:getBuildingInfo(CONF.EBuilding.kWarehouse).level)
				local index = confitem.TYPE - CONF.EItemType.kRes1 + 1
				if buildconf and player:getResByIndex(index) + count > buildconf.RESOURCE_UPPER_LIMIT[index] then
					tips:tips(CONF:getStringValue("achieve_upper_limit"))
					return
				end
			end
			-- end

			local strData = Tools.encode("ShopBuyReq", {    
				id = self.conf.ID,
				num= tonumber(rn:getChildByName("buyNum"):getString()) ,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHOP_BUY_REQ"),strData)
			gl:retainLoading()
		end     
	end)

	local btnCancel  = rn:getChildByName("btnCancel")
	btnCancel:getChildByName("text"):setString(CONF:getStringValue("cancel"))
	btnCancel:addClickEventListener(function (  )
		self:removeFromParent()
	end)

	--local editBox = rn:getChildByName("editBox")
	local placeHolder = rn:getChildByName("buyNum")

	rn:getChildByName("btnAdd"):addClickEventListener(function (  )
		local num = tonumber(placeHolder:getString()) + 1 
		if num > self.maxNum then
			return
		else
			--editBox:setText(num)
			print("print num", num)
			placeHolder:setString(string.format("%d", num))
			costNum:setString(string.format("%d", price * num))
			if price * num > self.money then
				costNum:setTextColor(cc.c4b(255, 0, 0, 255))
				-- costNum:enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
			else 
				costNum:setTextColor(cc.c4b(255, 255, 255, 255))
				-- costNum:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
			end
		end 
	end)

	rn:getChildByName("btnSub"):addClickEventListener(function (  )
		local num = tonumber(placeHolder:getString()) - 1 
		if num < 1 then
			return
		else
			--editBox:setText(num)
			print("print num", num)
			placeHolder:setString(string.format("%d", num))
			costNum:setString(string.format("%d", price * num))
			if price * num > self.money then
				costNum:setTextColor(cc.c4b(255, 0, 0, 255))
				-- costNum:enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
			else 
				costNum:setTextColor(cc.c4b(255, 255, 255, 255))
				-- costNum:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
			end
		end 
	end)

	--rn:getChildByName("btnMax"):getChildByName("text"):setString(CONF:getStringValue("maxNum"))
	rn:getChildByName("btnMax"):addClickEventListener(function (sender)
		local num = math.floor(self.money / price)
		local str
		if num < self.maxNum then 
			if num == 0 then
				str = 1
			else 
				str = num
			end
		else 
			str = self.maxNum
		end

		-- editBox:setText(string.format("%d", str))
		placeHolder:setString(string.format("%d", str))
		costNum:setString(string.format("%d", str * price))
		if str * price > self.money then
			costNum:setTextColor(cc.c4b(255, 0, 0, 255))
			-- costNum:enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
		else 
			costNum:setTextColor(cc.c4b(255, 255, 255, 255))
			-- costNum:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
		end
	end)

	local edit = cc.EditBox:create(rn:getChildByName("textBg"):getContentSize(),"aa")
	local z = math.min(rn:getChildByName("sum"):getLocalZOrder(),rn:getChildByName("buyNum"):getLocalZOrder())
	rn:addChild(edit)
	edit:setPosition(rn:getChildByName("textBg"):getPosition())
	local fontName =  rn:getChildByName("sum"):getFontName()
	local fontSize =  rn:getChildByName("sum"):getFontSize()
	edit:setPlaceholderFont(fontName,fontSize)
	edit:setFont(fontName,fontSize)
	edit:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)

	edit:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
	edit:setName("editbox")
	edit:registerScriptEditBoxHandler(function(eventname,sender)
		if eventname == "began" then  
	        sender:setText("")                                     
	    elseif eventname == "ended" then  
	    	local text = sender:getText()
	    	if text == "" then
	    		text = rn:getChildByName("buyNum"):getString()
	    	end
	    	if tonumber(text) > self.maxNum then
	    		text = self.maxNum
	    	end
	    	if tonumber(text) <= 0 then
		    	text = 1
	    	end
	        rn:getChildByName("buyNum"):setString(tonumber(text))
	        rn:getChildByName("costNum"):setString(string.format("%d",tonumber(text)*price))
	    elseif eventname == "return" then  
	    	local text = sender:getText()
	    	if text == "" then
	    		text = rn:getChildByName("buyNum"):getString()
	    	end
	    	if tonumber(text) > self.maxNum then
	    		text = self.maxNum
	    	end
	    	if tonumber(text) <= 0 then
		    	text = 1
	    	end
	        rn:getChildByName("buyNum"):setString(tonumber(text)) 
	        rn:getChildByName("costNum"):setString(string.format("%d",tonumber(text)*price))    
	    elseif eventname == "changed" then  
	        local text = sender:getText()
	    	if text == "" then
	    		text = rn:getChildByName("buyNum"):getString()
	    	end
	    	if tonumber(text) > self.maxNum then
	    		text = self.maxNum
	    	end
	    	if tonumber(text) <= 0 then
		    	text = 1
	    	end
	        rn:getChildByName("buyNum"):setString(tonumber(text)) 
	        rn:getChildByName("costNum"):setString(string.format("%d",tonumber(text)*price))   
	    end  
	end)
	edit:setMaxLength(4)

	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SHOP_BUY_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("ShopBuyResp",strData)
			if proto.result ~= 0 then
				print("proto error :",proto.result ,proto.req.id ,proto.req.num)
			else
				print("proto   ok          ",proto.result ,proto.req.id ,proto.req.num)
				tips:tips(CONF:getStringValue("buy_success"))
				if self.conf.TIMES > 0 then
					self:getParent():resetOneItem(proto.req.id)
					self.maxNum = self.maxNum - proto.req.num                   
				end

				flurryLogEvent("shop_buy", {item_id = tostring(proto.req.id), buy_num = tostring(proto.req.num)}, 2)

				if self.conf.COST_TYPE == 2 then

					local cost_num = self.conf.COST*proto.req.num

					flurryLogEvent("use_credit_in_shop", {item_info = "item_id:"..proto.req.id.."-item_num:"..proto.req.num, credit_info = "before_buy:"..(player:getMoney() + cost_num)..",after_buy:"..player:getMoney()}, 1, cost_num)
				elseif self.conf.COST_TYPE == 1 then
					local cost_num = self.conf.COST*proto.req.num

					flurryLogEvent("use_gold_in_shop", {item_info = "item_id:"..proto.req.id.."-item_num:"..proto.req.num, gold_info = "before_buy:"..(player:getResByIndex(1) + cost_num)..",after_buy:"..player:getResByIndex(1)}, 1, cost_num)
				end

				self:removeFromParent()
			end
		end
	end
	local eventDispatcher = self:getEventDispatcher()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	tipsAction(self)
end

function PurchaseLayer:addTouch(  )
	local function onTouchBegan(touch, event)
		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function PurchaseLayer:onExitTransitionStart()
	printInfo("PurchaseLayer:onExitTransitionStart()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return PurchaseLayer