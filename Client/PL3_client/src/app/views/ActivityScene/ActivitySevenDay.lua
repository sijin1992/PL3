-- 开服7天活动
local player = require("app.Player"):getInstance()
local ActivitySevenDay = class("ActivitySevenDay", function()
	return cc.Layer:create()
end)

function ActivitySevenDay:ctor( btnTag )
	local function onNodeEvent( event )
		if event == "enter" then 
			self.eventBtnId = btnTag
			self.sevendaysData = CONF.ACTIVITYSEVENDAYS
			self.sevenTaskData = CONF.SEVENDAYSTASK
			self.item = {}
			self.itemTab = {}
			self.getItemIdTab = {}
			self.getItemNumTab = {}
			self.itemInfo = {}
			self.uiroot = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/right_rewardPanel.csb")
			self:addChild(self.uiroot)
			self:getUiInfo(self.eventBtnId, self.uiroot)
			local function recvMsg()
				local cmd,strData = GameHandler.handler_c.recvProtobuf()
				if cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_SEVEN_DAYS_RESP") then 
					local proto = Tools.decode("ActivitySevenDaysResp", strData)
					if proto.result ~= 0 then 
						print("=====ActivitySevenDay==err:", proto.result)
					else 
						self:updateAll()
					end
				end
			end

			self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
			local eventDispatcher = self:getEventDispatcher()
			eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
		elseif event == "exit" then 
			local eventDispatcher = self:getEventDispatcher()
			eventDispatcher:removeEventListener(self.recvlistener_)
		end
	end

	self:registerScriptHandler(onNodeEvent)
end

function ActivitySevenDay:updateAll()
	local tab = {}
	local posTab = {}
	for i = 1, table.nums(self.item) do

		local isCompelete, compeleteNum, needNum = player:IsTaskAchieved(self.sevenTaskData.get(i))
		print("isCompelete==", isCompelete, compeleteNum, needNum)
		if compeleteNum > needNum then 
			compeleteNum = needNum
		end

		self.item[i].proNeedNum:setString(compeleteNum)
		self.item[i].proMaxNum:setString("/".. needNum)

		if isCompelete == false then 
			self.item[i].receiveBtn:setBright(false)
			self.item[i].receiveBtnTTF:setString(CONF:getStringValue("Get"))
			self.item[i].receiveBtn:setTouchEnabled(false)
		else 
			self.item[i].receiveBtn:setBright(true)
			self.item[i].receiveBtnTTF:setString(CONF:getStringValue("Get"))
			self.item[i].receiveBtn:setTouchEnabled(true)
		end
	end
	
	self:getUiInfo(self.eventBtnId, self.uiroot )
end

function ActivitySevenDay:getUiInfo( eventBtnId, res )
	self.sevenDays_Scroll = res:getChildByName("ScrollView_1")
	self.sevenDays_Scroll:removeAllChildren()
	local eid = 4001
	if eventBtnId == 1 then 
		self.itemTab = self.sevendaysData.get(eid).DAY1
	elseif eventBtnId == 2 then 
		self.itemTab = self.sevendaysData.get(eid).DAY2
	elseif eventBtnId == 3 then
		self.itemTab = self.sevendaysData.get(eid).DAY3
	elseif eventBtnId == 4 then 
		self.itemTab = self.sevendaysData.get(eid).DAY4
	elseif eventBtnId == 5 then 
		self.itemTab = self.sevendaysData.get(eid).DAY5
	elseif eventBtnId == 6 then 
		self.itemTab = self.sevendaysData.get(eid).DAY6
	elseif eventBtnId == 7 then     
		self.itemTab = self.sevendaysData.get(eid).DAY7
	end
	local tab = {}

	local sh = table.nums(self.itemTab) * 115
	local scrollW, scrollH = self.sevenDays_Scroll:getContentSize().width, self.sevenDays_Scroll:getContentSize().height
	if sh < scrollH then
		sh = scrollH
	end
	self.sevenDays_Scroll:setInnerContainerSize(cc.size(self.sevenDays_Scroll:getInnerContainerSize().width, sh))

	local index = 0
	
	local posTab = {}
	local receiveTab = {}
	if player:getActivity(4001) ~= nil then 
		receiveTab = player:getActivity(4001).seven_days_data.getted_today_list
	end
	for i = 1, table.nums(self.itemTab) do
		tab = self:createCell(i)
		self.sevenDays_Scroll:addChild(tab.cell)
		self.item[i] = tab
		self.item[i].isGetEvent = false

		local isCompelete, compeleteNum, needNum = player:IsTaskAchieved(self.sevenTaskData.get(i))

		local get = 1
		for k,v in pairs(receiveTab) do
			if i == v then 
				get = 2
			end
		end

		local can = 1
		if compeleteNum >= needNum then 
			can = 2 
		end
		local it = {cell = tab.cell, index = i, get = get, can = can}

		table.insert(posTab, it)
	end 

	local function sort( a, b )
		if a.get ~= b.get then
			return a.get < b.get
		else
			if a.can ~= b.can then
				return a.can > b.can
			else
				return a.index < b.index
			end
		end
	end

	table.sort(posTab, sort)

	for k,v in pairs(posTab) do
		print("=====index===", k, v.index, v.get, v.can)

		local x = 780 * 0.5
		local y = sh - (10 * v.index + 100*0.5*(2*v.index-1))

		posTab[v.index].cell:setPosition(cc.p(x, y))
	end

	-- set cell Position

	-- for i = 1, table.nums(posTab) do
	--     local x = 780 * 0.5
	--     local y = sh - (10 * i + 100*0.5*(2*i-1))
	--     print("x=============", x, y)

	--     posTab[i].cell:setPosition(cc.p(x, y))

	-- end

	-- set info
	self:setCellInfoData()
end

function ActivitySevenDay:setCellInfoData()

	local function receiveBtn_callBack(sender, eventType)
		if eventType == ccui.TouchEventType.ended then 
			print("=======eventTag===", sender:getTag())
			local tag = sender:getTag()
			local sevenData = Tools.encode("ActivitySevenDaysReq", {
				activity_id = 4001,
				task_id = tag,
			})

			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_SEVEN_DAYS_REQ"), sevenData)
			-- self:updateAll()
		end
	end

	for i = 1, table.nums(self.item) do
		for k,v in pairs(self.sevenTaskData.getIDList()) do
			if k == i then 
				self.getItemIdTab = self.sevenTaskData.get(i).ITEM_ID
				self.getItemNumTab = self.sevenTaskData.get(i).ITEM_NUM
			end
		end

		self.item[i].receiveBtn:setTag(self.sevenTaskData.get(i).ID)
		self.item[i].receiveBtn:addTouchEventListener(receiveBtn_callBack)
		for n = 1,table.nums(self.getItemIdTab) do
			self.item[i].cell:getChildByTag(66):getChildByName("itemBg_1"):getChildByName("Image_3"):loadTexture("res/ItemIcon/" .. CONF.ITEM.get(self.getItemIdTab[n]).ICON_ID .. ".png")
			self.item[i].cell:getChildByTag(66):getChildByName("itemBg_1"):getChildByName("Text_3"):setString(self.getItemNumTab[n])
		end

		self.item[i].desText:setString(CONF.STRING.get(self.sevenTaskData.get(i).MEMO).VALUE)
		self.item[i].needNum:setVisible(false)
		self.item[i].des2Text:setVisible(false)

		local isCompelete, compeleteNum, needNum = player:IsTaskAchieved(self.sevenTaskData.get(i))
		if compeleteNum > needNum then 
			compeleteNum = needNum
		end
		self.item[i].proNeedNum:setString(compeleteNum)
		self.item[i].proMaxNum:setString("/".. needNum)

		 if isCompelete == false then 
			self.item[i].receiveBtn:setBright(false)
			self.item[i].receiveBtnTTF:setString(CONF:getStringValue("Get"))
			self.item[i].receiveBtn:setTouchEnabled(false)
		else 
			self.item[i].receiveBtn:setBright(true)
			self.item[i].receiveBtnTTF:setString(CONF:getStringValue("Get"))
			self.item[i].receiveBtn:setTouchEnabled(true)
		end

		if player:getActivity(4001) ~= nil then 
			for k, v in pairs(player:getActivity(4001).seven_days_data.getted_today_list) do
				-- 领取过
				if v == i then
					self.item[i].receiveBtn:setBright(false)
					self.item[i].receiveBtnTTF:setString(CONF:getStringValue("has_get"))
					self.item[i].receiveBtn:setTouchEnabled(false)
				end
			end
		end
	end
end

function ActivitySevenDay:createCell( idx )
	local tab = {}
	tab.cell = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/SevenItemNode.csb")
	tab.receiveBtn = tab.cell:getChildByName("Button_1")
	tab.receiveBtnTTF = tab.receiveBtn:getChildByName("Text_11_0_0_0")
	tab.desText = tab.cell:getChildByName("des1")
	tab.needNum = tab.cell:getChildByName("num")
	tab.des2Text = tab.cell:getChildByName("des2")
	tab.proNeedNum = tab.cell:getChildByName("num_0")
	tab.proMaxNum = tab.cell:getChildByName("des2_0")
	tab.proMaxNum:setPosition(cc.p(tab.proNeedNum:getPositionX() + tab.proNeedNum:getContentSize().width * 0.4, tab.proNeedNum:getPositionY()))
	-- 
	for k,v in pairs(self.sevenTaskData.getIDList()) do
		if k == idx then 
			self.getItemIdTab = self.sevenTaskData.get(idx).ITEM_ID
			self.getItemNumTab = self.sevenTaskData.get(idx).ITEM_NUM
		end
	end

	local ix, iy
	for i = 1, #self.getItemIdTab do
		self.itemInfo[i] = {}
		self.itemInfo[i].item = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/sevenItemInfo.csb")
		self.itemInfo[i].itemIcon = self.itemInfo[i].item:getChildByName("itemBg_1"):getChildByName("Image_3")
		self.itemInfo[i].itemNum = self.itemInfo[i].item:getChildByName("itemBg_1"):getChildByName("Text_3")
		tab.cell:addChild(self.itemInfo[i].item, 66, 66)

		-- tab.initem = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/sevenItemInfo.csb")
		-- tab.itemIcon = tab.initem:getChildByName("itemBg_1"):getChildByName("Image_3")
		-- tab.itemNum = tab.initem:getChildByName("itemBg_1"):getChildByName("Text_3")
		-- tab.cell:addChild(tab.initem)

		ix = -(780 * 0.5 + 30) + 82 * (2 * i - 1)
		iy = -10
		self.itemInfo[i].item:setPosition(cc.p(ix, iy))
	end

	return tab
end

return ActivitySevenDay