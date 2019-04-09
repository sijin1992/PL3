local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local ShopLayer = class("ShopLayer", cc.load("mvc").ViewBase)

ShopLayer.RESOURCE_FILENAME = "ShopScene/ShopLayer.csb"

ShopLayer.NEED_ADJUST_POSITION = true

local schedulerEntry = nil
local schedulerEntry1 = nil

ShopLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

ShopLayer.lagHelper = require("util.ExLagHelper"):getInstance()
ShopLayer.IS_SCENE_TRANSFER_EFFECT = false

function ShopLayer:onCreate( data )
	if( self.IS_SCENE_TRANSFER_EFFECT == false ) then
		self.data_ = data
	else

	if data then
		self.data_ = data
	end
	if ((data and data.sfx) or true ) then
		if( data and data.sfx ) then
			data.sfx = false
		end
		local view = self:getApp():createView("CityScene/TransferScene",{from = "ShopScene/ShopLayer" ,state = "enter"})
		self:addChild(view)
	end
	end
end

function ShopLayer:OnBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			-- self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})

			-- EDIT BY WJJ 20180625
			 self:getApp():removeTopView()
--			if( self.IS_SCENE_TRANSFER_EFFECT ) then
--				self.lagHelper:BeginTransferEffect("city")
--			else
--				self:getApp():popView()
--			end
		end
	end
end

function ShopLayer:setBarHighLight(bar, flag)
	if flag == true then
		bar:getChildByName("selected"):setVisible(true)
		bar:getChildByName("normal"):setVisible(false)
	else
		bar:getChildByName("selected"):setVisible(false)
		bar:getChildByName("normal"):setVisible(true)
	end
end

function ShopLayer:changeMode(mode,ref)

	if mode == self.mode_ and not ref then

		return
	end
	self.mode_ = mode

	playEffectSound("sound/system/tab.mp3")		

	self.selectedNode = nil
	self:resetList1(mode)

	local rn = self:getResourceNode()
	local leftBar = rn:getChildByName("leftBg")
	local children = leftBar:getChildren()
	for i,v in ipairs(children) do
		local bar_name = v:getName()
		if bar_name == string.format("mode_%d", mode) then
			self:setBarHighLight(v, true)
		else
			self:setBarHighLight(v, false)
		end
	end
	for i=1,5 do
		local mode_node = self:getResourceNode():getChildByName("leftBg"):getChildByName("mode_"..i)
		mode_node:getChildByName("text"):setVisible(true)
		mode_node:getChildByName("text_0"):setVisible(false)
		if mode == i then
			mode_node:getChildByName("text"):setVisible(false)
			mode_node:getChildByName("text_0"):setVisible(true)
		end
	end
end

function ShopLayer:onEnterTransitionFinish()
	local rn = self:getResourceNode()
	self:resetInfoList()
	self:sendMsg()
	
	
	local function onTouchBegan(touch, event)
		return true
	end
	
	local eventDispatcher = self:getEventDispatcher()
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, rn:getChildByName("back"))
	
	--rn:getChildByName("shop"):setString(CONF:getStringValue("shop"))	delete by JinXin 20180620

	local function clickBar(sender)
		self:changeMode(sender:getParent():getTag())
	end
	for i=1,5 do
		local mode_node = rn:getChildByName("leftBg"):getChildByName("mode_"..i)
		if i == 1 then
			mode_node:getChildByName("selected"):setVisible(true)
		end

		mode_node:getChildByName("text"):setString(CONF:getStringValue("shop_mode_"..i))
		mode_node:getChildByName("text_0"):setString(CONF:getStringValue("shop_mode_"..i))

		mode_node:getChildByName("selected"):addClickEventListener(clickBar)
		mode_node:getChildByName("normal"):addClickEventListener(clickBar)
	end

	--set res
	for i=1,4 do
		local res = rn:getChildByName(string.format("res_%d", i))

		res:getChildByName("text"):setString(formatRes(player:getResByIndex(i)))
	end
	--set credit

	rn:getChildByName("res_5"):getChildByName("text"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))

	local function addMoney( sender)
		playEffectSound("sound/system/click.mp3")
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self, {index = 1})
		self:addChild(rechargeNode)
	end

	rn:getChildByName("res_5"):getChildByName("add"):addClickEventListener(addMoney)
	rn:getChildByName("res_5"):getChildByName("money_touch"):addClickEventListener(addMoney)

	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_CLIENT_GM_RESP") then

			local proto = Tools.decode("CmdClientGMResp",strData)
			print("CMD_CLIENT_GM_RESP result",proto.result)

--			gl:releaseLoading()
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SHOP_TIME_ITEM_LIST_RESP") then

--			gl:releaseLoading()

			local proto = Tools.decode("ShopTimeItemListResp",strData)
			print("ShopTimeItemListResp, proto result",proto.result)

			if proto.result == 1 then
				self.timeLimitList = proto.list
				self:setConfList()

				if self.data_ then
					self:changeMode(self.data_.type)
				else
					self:changeMode(1)
				end
			elseif proto.result ~= 0 then 
				print("proto.result error" ,proto.result)
			else
				self.timeLimitList = proto.list
				self:setConfList()
				if self.data_ then
					self:changeMode(self.data_.type)
				else
					self:changeMode(1)
				end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SHOP_BUY_RESP") then
			local proto = Tools.decode("ShopBuyResp",strData)
			if proto.result == 0 then
				local user_info = player:getUserInfo()
				user_info.money = proto.user_sync.user_info.money
				-- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("MoneyUpdated")
				self:updateRes()
			else
				tips:tips(CONF:getStringValue("buy_error"))
			end
		end
	end
	local eventDispatcher = self:getEventDispatcher()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		self:updateRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)
	
	animManager:runAnimOnceByCSB(rn, "ShopScene/ShopLayer.csb", "intro")

end

function ShopLayer:sendMsg(  )
	self.updateNumList = {}
	self.updateNodeList = {}
	self.timeLimitList = {}

	print("CMD_SHOP_TIME_ITEM_LIST_REQ")
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHOP_TIME_ITEM_LIST_REQ"),"1")

--	gl:retainLoading()
end

function ShopLayer:updateRes(  )
	local rn = self:getResourceNode()
	for i=1,4 do
		local res = rn:getChildByName(string.format("res_%d", i))

		res:getChildByName("text"):setString(formatRes(player:getResByIndex(i)))
		print("res =========" ,i ,player:getResByIndex(i))
	end

	rn:getChildByName("res_5"):getChildByName("text"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	print("credit ========" ,player:getMoney())

	if rn:getChildByName('selectNode5') then
		rn:getChildByName('selectNode5'):getChildByName("Text_1_0"):setString(player:getGroupData().contribute)
	end
end

function ShopLayer:createPoints( pages )
	self.prePage = 0
	local rn = self:getResourceNode()
	local pointNode = rn:getChildByName("pointNode")
	pointNode:removeAllChildren()

	for i=1,pages do
		local point =  cc.Sprite:create("ShipsScene/ui2/flag_w.png")
		point:setPositionX( (i - 1) * 20)
		point:setPositionY(5)
		point:setOpacity(255 * 0.5)
		point:setTag(i-1)
		pointNode:addChild(point)
	end

	if pointNode:getChildByTag(0) ~= nil then
		pointNode:getChildByTag(0):setOpacity(255)
	end
end

function ShopLayer:updatePoints( page )
	if not page or page < 0 then return end
	local pointNode = self:getResourceNode():getChildByName("pointNode")
	if pointNode ~= nil and pointNode:getChildByTag(page) ~= nil then
		pointNode:getChildByTag(page):setOpacity(255)
		if self.prePage ~= page then
			pointNode:getChildByTag(self.prePage):setOpacity(255 * 0.5)
			self.prePage = page
		end 
	end
	
end

function ShopLayer:setConfList(  )
	self.goodsConfList = {}
	local idList = CONF.SHOP.getIDList()
	for k,v in pairs(idList) do
		local goodsConf = CONF.SHOP.get(v)
		if goodsConf.START_TIME <= 0 then
			table.insert( self.goodsConfList, goodsConf )
		end
	end
	for k,v in pairs(self.timeLimitList) do
		local goodsConf = CONF.SHOP.get(v.id)
		table.insert( self.goodsConfList, goodsConf )
	end
	local function sort( a ,b )
		if a.ORDER > b.ORDER then
			return false 
		elseif a.ORDER == b.ORDER then
			return a.ID < b.ID
		else 
			return true
		end
	end 
	table.sort(self.goodsConfList ,sort)
	local have = false
	for i=#self.goodsConfList,1,-1 do
		if self.goodsConfList[i].START_TIME == -2 then
			local birthT = player:getRegistTime()
			if player:getServerTime() - birthT >= self.goodsConfList[i].END_TIME then
				table.remove(self.goodsConfList,i)
			else
				have = true
			end
		end
	end
	local function check()
		for i=#self.goodsConfList,1,-1 do
			if self.goodsConfList[i].START_TIME == -2 then
				local birthT = player:getRegistTime()
				if player:getServerTime() - birthT >= self.goodsConfList[i].END_TIME then
					self:setConfList()
					self:changeMode(self.mode_,true)
				end
			end
		end
	end
	check()
	if have then
		if schedulerEntry1 == nil then
			schedulerEntry1 = scheduler:scheduleScriptFunc(check,1,false)
		end
	else
		if schedulerEntry1 then 
			scheduler:unscheduleScriptEntry(schedulerEntry1)
			schedulerEntry1 = nil
		end
	end

	if schedulerEntry == nil and #self.timeLimitList > 0 then
		schedulerEntry = scheduler:scheduleScriptFunc(handler(self, self.updateTime), 1,false) 
	end
end

function ShopLayer:updateTime(  )
	local Time = player:getServerTime()
	for k,v in pairs(self.updateNodeList) do
		local timeNum = self.updateNumList[k]
		if Time > timeNum then -- 过期删除
			self:sendMsg()
			scheduler:unscheduleScriptEntry(schedulerEntry)
			schedulerEntry = nil
			break
		else
			v:getChildByName("time"):setString(formatTime(timeNum - Time))
		end
	end
end

function ShopLayer:resetInfoList(  )
	self.itemInfoList = {}
	self.itemInfoList = player:getUserInfo().shop_data.goods_list
end

function ShopLayer:addClickFunc(item_node,id)
	local func = function ( ... )
		playEffectSound("sound/system/click.mp3")
		if self.selectedNode then
			self.selectedNode:getChildByName('selectedBg'):setVisible(false)
		end
		item_node:getChildByName('selectedBg'):setVisible(true)
		self.selectedNode = item_node
		if self.selectedNode:getChildByName("limit") == nil then
			tips:tips(CONF:getStringValue("max_num_buy"))
			return
		end
		if self:getChildByName("PurchaseLayer") then
			self:getChildByName("PurchaseLayer"):removeFromParent()
		end
		local layer = self:getApp():createView("ShopScene/PurchaseLayer", {confList = self.goodsConfList , ID = id})
		layer:setName("PurchaseLayer")
		self:addChild(layer)
	end

	local callback = {node = item_node:getChildByName("selectedBg"), func = func}
	return callback
end

function ShopLayer:resetList1(itemType) --1热销2资源3装备4宝石5星盟
	local rn = self:getResourceNode()
	for i=1,5 do
		if rn:getChildByName('selectNode'..i) then
			rn:getChildByName('selectNode'..i):removeFromParent()
			self.pageView = nil
		end
	end
	if self.pageView then
		self.pageView:removeAllChildren()
	end
	if itemType == 2 or itemType == 4 then
		self.pageView = rn:getChildByName("pageView")
		self:resetList(itemType)
	end
	local idList = {}
	self.updateNodeList = {}
	self.updateNumList = {}
	
	if self.goodsConfList == nil then
		return
	end

	for k,v in pairs(self.goodsConfList) do
		if v.TYPE == itemType then 
			table.insert(idList ,v)
		end
	end
	if self.pageView then
		self.pageView:setVisible(true)
	end
	if itemType == 1 then
		local pointNode = rn:getChildByName("pointNode")
		pointNode:removeAllChildren()
		if self.pageView then
			self.pageView:setVisible(false)
		end
		local node = require("app.ExResInterface"):getInstance():FastLoad("ShopScene/mode_1Node.csb")
		node:setName('selectNode'..itemType)
		node:setPosition(rn:getChildByName('Node'):getPosition())
		rn:addChild(node)
		local list1 = node:getChildByName('list')
		local list2 = node:getChildByName('list_0')
		node:getChildByName('Text_62'):setString(CONF:getStringValue('best shop'))
		local img = node:getChildByName('Image_62')
		local new_ids = {}
		local hot_ids = {}
		for k,v in ipairs(idList) do
			if v.SCRIPT == 1 then
				table.insert(hot_ids,v)
			elseif v.SCRIPT == 2 then
				table.insert(new_ids,v)
			end
		end
		self.list_view1 = require("util.ScrollViewDelegate"):create(list1,cc.size(0,242), cc.size(170,242))
		self.list_view2 = require("util.ScrollViewDelegate"):create(list2,cc.size(0,0), cc.size(190,90))	--change by JinXin 20180620
		self.list_view1:clear()
		self.list_view2:clear()
		list1:setScrollBarEnabled(false)
		list2:setScrollBarEnabled(false)
		for k,v in ipairs(new_ids) do
			local item_node = self:createItemNode(v)
			self.list_view1:addElement(item_node,{callback = self:addClickFunc(item_node,v.ID)})
		end
		for k,v in ipairs(hot_ids) do
			local item_node = self:createItemNode(v,true)
			self.list_view2:addElement(item_node,{callback = self:addClickFunc(item_node,v.ID)})
		end
	elseif itemType == 3 then
		local node = require("app.ExResInterface"):getInstance():FastLoad("ShopScene/mode_3Node.csb")
		node:setName('selectNode'..itemType)
		node:setPosition(rn:getChildByName('Node'):getPosition())
		rn:addChild(node)
		-- local list = require("util.ScrollViewDelegate"):create(node:getChildByName('list'),cc.size(0,242), cc.size(210,550))
		-- node:getChildByName('list'):setScrollBarEnabled(false)
		-- for i,v in ipairs(idList) do
		-- 	local item_node = self:createItemNode(v)
		-- 	list:addElement(item_node,{callback = self:addClickFunc(item_node,v.ID)})
		-- end
		self.pageView = node:getChildByName('pageView')
		self:resetList(itemType)
	elseif itemType == 5 then
		local node = require("app.ExResInterface"):getInstance():FastLoad("ShopScene/mode_5Node.csb")
		node:setName('selectNode'..itemType)
		node:setPosition(rn:getChildByName('Node'):getPosition())
		node:getChildByName("Text_1_0"):setString(player:getGroupData().contribute)
		rn:addChild(node)

		self.pageView = node:getChildByName('pageView')
		self:resetList(itemType)
	end
	if self.pageView then
		self.pageView:onEvent(function(event)
			if event.name == "TURNING" and self.pageView then
				if self.prePage == self.pageView:getCurrentPageIndex() then 
					return 
				else 
					if self.pageView then            
						self:updatePoints(self.pageView:getCurrentPageIndex())
					end
				end
			end
		end)
	end
end

function ShopLayer:resetList( itemType ) --1热销2资源3装备4宝石
	if not self.pageView then return end
	local idList = {}
	self.updateNodeList = {}
	self.updateNumList = {}
	local rn = self:getResourceNode()
	self.pageView:removeAllChildren()
	if self.goodsConfList == nil then
		return
	end

	for k,v in pairs(self.goodsConfList) do
		if v.TYPE == itemType then 
			table.insert(idList ,v)
		end
	end

	local page = 0
	if #idList % 8 == 0 then
		page = #idList / 8
	else 
		page = math.ceil(#idList / 8)
	end

	local selectedPag = 0
	local function onTouchBegan(touch, event)
		local target = event:getCurrentTarget()
		local locationInNode = self.pageView:convertToNodeSpace(touch:getLocation())
		local page_s = self.pageView:getContentSize()
		local page_rect = cc.rect(0, 0, page_s.width, page_s.height)
		if cc.rectContainsPoint(page_rect, locationInNode) then 

			local ln = target:convertToNodeSpace(touch:getLocation())
			local s = target:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)
			if cc.rectContainsPoint(rect, ln) then               
				self.isTouch = true
				selectedPag = self.pageView:getCurrentPageIndex()
				return true
			end
			return false
		end
		return false
	end

	local function onTouchMoved( touch ,event )

		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			self.isTouch = false
		end     
	end

	local function onTouchEnded(touch, event)
		if self.isTouch  then
			playEffectSound("sound/system/click.mp3")
			local target = event:getCurrentTarget()
			if self.selectedNode then
				self.selectedNode:getChildByName("selectedBg"):setVisible(false)
			end
			target:getParent():getChildByName("selectedBg"):setVisible(true)
			self.selectedNode = target:getParent()

			if target:getParent():getChildByName("limit") == nil then
				tips:tips(CONF:getStringValue("max_num_buy"))
				return 
			end
			if self:getChildByName("PurchaseLayer") then
				self:getChildByName("PurchaseLayer"):removeFromParent()
			end
			local layer = self:getApp():createView("ShopScene/PurchaseLayer", {confList = self.goodsConfList , ID = target:getParent():getTag()})
			layer:setName("PurchaseLayer")
			self:addChild(layer)
		end
	end

	local eventDispatcher = self:getEventDispatcher()
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

	local num = 1
	for i=1,page do
		local layout = ccui.Layout:create()
		local nums = 8
		if itemType == 3 then
			nums = 6
		end
		for i=1,nums do
			if idList[num] then
				local itemNode = self:createItemNode(idList[num])
				itemNode:setScale(0.9)
				local posX ,posY
				if i%2 == 1 then --上面
					posX =  math.floor(i/2) * 160 
					posY = 450
				elseif i%2 == 0 then --下面
					posX = math.floor((i-1)/2) * 160
					posY = 450 - 230
				end 
				layout:addChild(itemNode)
				itemNode:setPosition(cc.p(posX ,posY))
				eventDispatcher:addEventListenerWithSceneGraphPriority(listener:clone(), itemNode:getChildByName("bg"))
			else

				break
			end       
			num = num + 1
		end

		self.pageView:addPage(layout)
	end

	self.pageView:scrollToPage(1)  
	self:createPoints(page)
end

function ShopLayer:resetOneItem( ID )
	self:resetInfoList()
	local info 
	local conf
	for k,v in pairs(self.itemInfoList) do
		if v.id == ID then           
			info = v           
			break
		end
	end

	for k,v in pairs(self.goodsConfList) do
		if v.ID == ID then
			conf = v
			break
		end
	end

	if conf.TIMES < 0 then --不限�?
		return
	end

	local buy_times = info.buy_times
	if buy_times == conf.TIMES then --买完�?
		self.selectedNode:getChildByName("totalNum"):removeFromParent()
		self.selectedNode:getChildByName("buyNum"):removeFromParent()
		self.selectedNode:getChildByName("limit"):removeFromParent()
		local overText = self.selectedNode:getChildByName("over")
		overText:setString(CONF:getStringValue("saleOver"))
		overText:setVisible(true)
	else 
		self.selectedNode:getChildByName("buyNum"):setString(buy_times)
	end
end

function ShopLayer:createItemNode( goodsConf,small )
	local itemNode = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_shop_item.csb")
	if small and small == true then
		itemNode = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_shop_item_0.csb")
	end
	local itemConf = CONF.ITEM.get(goodsConf.ITEM)
	if goodsConf.COST_TYPE == 1 then
		itemNode:getChildByName("sprMoney"):removeFromParent()
	elseif goodsConf.COST_TYPE == 2 then
		itemNode:getChildByName("sprGold"):removeFromParent()
	elseif goodsConf.COST_TYPE == 3 then
		itemNode:getChildByName("sprGold"):removeFromParent()
		itemNode:getChildByName("sprMoney"):removeFromParent()
		itemNode:getChildByName("sprContribution"):setVisible(true)
	end

	local iconName = "ShopScene/ui/"
	if goodsConf.SCRIPT == 1 then
	-- Change By JinXin 20180620
        if small and small == true then
            iconName = iconName .. "icon_hot3.png"
        else
            iconName = iconName .. "icon_hot.png"
        end
	elseif goodsConf.SCRIPT == 2 then
		iconName = iconName .. "icon_new.png"
	elseif goodsConf.SCRIPT == 3 then
		iconName = iconName .. "icon_time.png"
	end
	if goodsConf.SCRIPT == 0 then
		itemNode:getChildByName("hot"):removeFromParent()
	else 
		itemNode:getChildByName("hot"):setTexture(iconName)
	end 

	local limitText =  itemNode:getChildByName("limit")
	local totalNum = itemNode:getChildByName("totalNum")
	local buyNum = itemNode:getChildByName("buyNum")
	if goodsConf.TIMES < 0 then 
		limitText:setVisible(false)
		totalNum:removeFromParent()
		buyNum:removeFromParent()
	else 
		local buyTimes = 0
		for k,v in pairs(self.itemInfoList) do
			if v.id == goodsConf.ID then   
		   
				if v.buy_times == nil then
					buyTimes = 0 
				else 
					buyTimes = v.buy_times
				end           
				break
			end
		end
		if buyTimes == goodsConf.TIMES then --买完�?
			totalNum:removeFromParent()
			buyNum:removeFromParent()
			limitText:removeFromParent()
			local overText = itemNode:getChildByName("over")
			overText:setString(CONF:getStringValue("saleOver"))
			overText:setVisible(true)
		else 
			buyNum:setString(buyTimes)
			limitText:setString(CONF:getStringValue("limitNum"))
			totalNum:setString("/" .. goodsConf.TIMES)
		end         
	end

	itemNode:getChildByName("moneyNum"):setString(goodsConf.COST)
	itemNode:getChildByName("itemIcon"):loadTexture("ItemIcon/" .. itemConf.ICON_ID .. ".png")
	itemNode:getChildByName("itemName"):setString(CONF:getStringValue(itemConf.NAME_ID))
	--Change By JinXin 20180620
    itemNode:getChildByName("itemNum"):setString("x" .. goodsConf.ITEM_NUM)
    if small and small == true then
        itemNode:getChildByName("itemNum"):setString(CONF:getStringValue("sumNum").."x" .. goodsConf.ITEM_NUM)
    end
	itemNode:setTag(goodsConf.ID)

	local isLimit = false
	local endTime = 0
	for k,v in pairs(self.timeLimitList) do
		if v.id == goodsConf.ID then
			isLimit = true
			endTime = v.end_time
			break
		end
	end

	if isLimit then
		itemNode:getChildByName("time"):setVisible(true)
		itemNode:getChildByName("time"):setString(formatTime(endTime - player:getServerTime()))
		table.insert(self.updateNodeList ,itemNode)
		table.insert(self.updateNumList ,endTime)
	end

	return itemNode
end

function ShopLayer:onExitTransitionStart()
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	if schedulerEntry then 
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil
	end
	if schedulerEntry1 then 
		scheduler:unscheduleScriptEntry(schedulerEntry1)
		schedulerEntry1 = nil
	end
--	if self.list_view1 ~= nil then
--		self.list_view1:clear()
--	end
--	if self.list_view2 ~= nil then
--		self.list_view2:clear()
--	end
end


return ShopLayer