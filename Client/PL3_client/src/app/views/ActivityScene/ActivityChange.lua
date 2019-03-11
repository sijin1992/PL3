-- 兑换活动
local tips = require("util.TipsMessage"):getInstance()
local player = require("app.Player"):getInstance()
local ActivityChange = class("ActivityChange", function()
	return cc.Layer:create()
end)


-- 活动id 1011
function ActivityChange:ctor( changeId )
	self.eid = changeId
	self.receive = {}
	self.icontab = {}
	self.changeitemNum = {}
	self.receiveTab = {}
	self.changeitem = {}
	self.reveiveitemNum = {}
	self.changCountNum = {}
	self.reveiveitem = {}
	self.item = {}
	self.itemBtn = {}
	self.selectBtn = 1
	self.itemNode = {}
	self.countNumTab = {}
	local function onNodeEvent( event )
		if event == "enter" then 
			self.uiroot = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/right_rewardPanel.csb")
			self:addChild(self.uiroot)
			self:setGameGata(self.eid, self.uiroot)

			local function recvMsg( )
				local cmd,strData = GameHandler.handler_c.recvProtobuf()
				if cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_CHANGE_RESP") then 
					local proto = Tools.decode("ActivityChangeResp", strData)
					if proto.result ~= 0 then 
						print("ActivityChange=====err:", proto.result)
					else 
						self:updateData()
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

	-- local uiroot = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/Change.csb")
	-- self:addChild(uiroot)
	-- self:setGameGata(self.eid, uiroot)
end

function ActivityChange:updateData()
	local rnum = 0
	for i = 1, table.nums(CONF.ACTIVITYCHANGE.get(self.eid).GROUP) do
		for k,v in pairs(CONF.CHANGEITEM.getIDList()) do
			if k == i then 
				self.changeitem = CONF.CHANGEITEM.get(i).COST_ITEM
				self.changeitemNum = CONF.CHANGEITEM.get(i).COST_NUM
			end
		end

		self.item[i].node:getChildByTag(66):getChildByName("itemBg_1"):getChildByName("Text_1")
		for z = 1,#self.changeitem do
			self.item[i].node:getChildByTag(66):getChildByName("itemBg_1"):getChildByName("Text_1"):setString(player:getItemNumByID(self.changeitem[z]))
		end
	end

	if player:getActivity(self.eid) ~= nil then 
		for k,v in pairs(player:getActivity(self.eid).change_data.limit_list) do
			if self.selectBtn == v.key then 
				rnum = v.value
			end
		end
	end

	print("self.item[i].changNum====", self.eid, rnum, CONF.CHANGEITEM.get(self.selectBtn).LIMIT)
	self.item[self.selectBtn].changNum:setString(rnum)
	if rnum < CONF.CHANGEITEM.get(self.selectBtn).LIMIT then 
		self.item[self.selectBtn].changNum:setTextColor(cc.c3b(0, 255, 0))
	else 
		self.item[self.selectBtn].changNum:setTextColor(cc.c3b(255, 125, 0))
	end

	local function judge( )
		if rnum < CONF.CHANGEITEM.get(self.selectBtn).LIMIT then 
			return true
		else 
		   return false
		end
	end

	if judge() then 
		self.item[self.selectBtn].btn:getChildByName("Text_11_0_0_0"):setString(CONF:getStringValue("DUIHUAN"))
		self.item[self.selectBtn].btn:setBright(true)
		self.item[self.selectBtn].btn:setTouchEnabled(true)
	else 
		self.item[self.selectBtn].btn:getChildByName("Text_11_0_0_0"):setString(CONF:getStringValue("YIDUIHUAN"))
		self.item[self.selectBtn].btn:setBright(false)
		self.item[self.selectBtn].btn:setTouchEnabled(false)
	end

	self:setNodePos()
end

-- eventid
function ActivityChange:setGameGata( changeId, uiroot )
	self.srollPanel = uiroot:getChildByName("ScrollView_1")
	self.srollPanel:removeAllChildren()

	local function itemBtn_callBack( sender, eventType )
		if eventType == ccui.TouchEventType.ended then 
			local tag = sender:getTag()
			print("receive =======tag===", tag, changeId)
			self.eid = changeId
			self.selectBtn = tag
			local receiveData = Tools.encode("ActivityChangeReq", {
				activity_id = changeId,
				change_item_id = tag,
			})

			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_CHANGE_REQ"), receiveData)
		end
	end

	local itemTab = {}
	local cn = 0
	local item_list = CONF.ACTIVITYCHANGE.get(changeId).GROUP
	-- self.srollPanel:setInnerContainerSize(cc.size(790, math.max(table.nums(item_list) * 105 + 10, 360)))
	local sh = table.nums(item_list) * 115
	local scrollW, scrollH = self.srollPanel:getContentSize().width, self.srollPanel:getContentSize().height
	if sh < scrollH then
		sh = scrollH
	end
	self.srollPanel:setInnerContainerSize(cc.size(self.srollPanel:getInnerContainerSize().width, sh))
	local tab = {}
	local posTab = {}
	for i=1, table.nums(item_list) do
		self.item[i] = {}
		self.item[i].node = self:createItemNode(i, changeId)
		if player:getActivity(changeId) ~= nil then 
			for k,v in pairs(player:getActivity(changeId).change_data.limit_list) do
				if i == v.key then 
					table.insert(self.countNumTab, v.key, v.value)
				end
			end
		end

		if self.countNumTab[i] ~= nil then 
			cn = self.countNumTab[i]
		else 
			cn = 0
		end

		self.item[i].btn = self.item[i].node:getChildByName("Button_1")
		self.item[i].changNum = self.item[i].node:getChildByName("Text_11_0")
		self.item[i].changNum:setString(cn)
		if cn < CONF.CHANGEITEM.get(i).LIMIT then 
			self.item[i].changNum:setTextColor(cc.c3b(0, 255, 0))
		else 
			self.item[i].changNum:setTextColor(cc.c3b(255, 125, 0))
		end
		self.item[i].needNum = self.item[i].node:getChildByName("Text_11_0_0")
		self.item[i].needNum:setString("/" .. CONF.CHANGEITEM.get(i).LIMIT)
		self.item[i].btn:setTag(CONF.CHANGEITEM.get(i).ID)
		self.item[i].btn:addTouchEventListener(itemBtn_callBack)
		self.srollPanel:addChild(self.item[i].node, 99, 99)

		-- 
		-- local can = 1
		-- if cn >= CONF.CHANGEITEM.get(i).LIMIT then 
		--     can = 2
		-- end
		-- local it = {node = self.item[i].node, index = i, can = can}

		-- table.insert(posTab, it)
	end

	-- local function sort( a, b )
	--     if a.can ~= b.can then
	--         return a.can < b.can
	--     else
	--         return a.index < b.index
	--     end
	-- end

	-- table.sort(posTab, sort)

	-- for k,v in pairs(posTab) do
	--     print("posTab=====change==", k, v.index, v.can)

	--     local x = 780 * 0.5
	--     local y = sh - (10 * v.index + 100*0.5*(2*v.index-1))
	--     posTab[v.index].node:setPosition(cc.p(x, y))
	--     -- posTab[v.index].node:setPosition(cc.p(self.itemBgPosx, self.itemBgPosy - (v.index - 1) * 105 + self.srollPanel:getInnerContainerSize().height * 0.5 - 50))
	-- end
	self:setNodePos()
end

function ActivityChange:setNodePos( )
	local item_list = CONF.ACTIVITYCHANGE.get(self.eid).GROUP
	local sh = table.nums(item_list) * 115
	local posTab = {}
	local cn = 0
	for k,v in pairs(item_list) do
		if player:getActivity(self.eid) ~= nil then 
			for k_,v_ in pairs(player:getActivity(self.eid).change_data.limit_list) do
				if k == v_.key then 
					table.insert(self.countNumTab, v_.key, v_.value)
				end
			end
		end
		if self.countNumTab[k] ~= nil then 
			cn = self.countNumTab[k]
		else 
			cn = 0
		end

		local can = 1
		if cn >= CONF.CHANGEITEM.get(k).LIMIT then 
			can = 2
		end
		local it = {node = self.item[k].node, index = k, can = can}
		table.insert(posTab, it)
	end

	local function sort( a, b )
		if a.can ~= b.can then
			return a.can < b.can
		else
			return a.index < b.index
		end
	end

	table.sort(posTab, sort)

	for k,v in pairs(posTab) do
		print("posTab=====change==", k, v.index, v.can)

		local x = 780 * 0.5
		local y = sh - (10 * v.index + 100*0.5*(2*v.index-1))
		posTab[v.index].node:setPosition(cc.p(x, y))
		-- posTab[v.index].node:setPosition(cc.p(self.itemBgPosx, self.itemBgPosy - (v.index - 1) * 105 + self.srollPanel:getInnerContainerSize().height * 0.5 - 50))
	end
end


function ActivityChange:createItemNode(id, eventid)
	-- self.item[id] = {}
	local btnTab = {}
	local node = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/ChangItemNode.csb")
	node:getChildByName("FileNode_2"):setVisible(false)
	btnTab[id] = {} 
	btnTab[id].btn = node:getChildByName("Button_1")
	-- get item num
	for k,v in pairs(CONF.CHANGEITEM.getIDList()) do
		if k == id then 
			self.changeitem = CONF.CHANGEITEM.get(id).COST_ITEM
			self.changeitemNum = CONF.CHANGEITEM.get(id).COST_NUM
			self.reveiveitem = CONF.CHANGEITEM.get(id).GET_ITEM
			self.reveiveitemNum = CONF.CHANGEITEM.get(id).GET_NUM
		end
	end

	for i = 1,#self.changeitem do
		self.icontab[i] = {}
		self.icontab[i].icon = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/itemInfo.csb")
		self.icontab[i].iconBg = self.icontab[i].icon:getChildByName("itemBg_1"):getChildByName("Image_3")
		self.icontab[i].iconBg:loadTexture("res/ItemIcon/" .. CONF.ITEM.get(self.changeitem[i]).ICON_ID .. ".png")
		self.icontab[i].iconNumText = self.icontab[i].icon:getChildByName("itemBg_1"):getChildByName("Text_1")
		self.icontab[i].iconNumText:setString(player:getItemNumByID(self.changeitem[i]))
		if player:getItemNumByID(self.changeitem[i]) >= self.changeitemNum[i] then 
			self.icontab[i].iconNumText:setTextColor(cc.c3b(0, 255, 0))
		else 
			self.icontab[i].iconNumText:setTextColor(cc.c3b(255, 127, 0))
		end
		self.icontab[i].iconNumText2  = self.icontab[i].icon:getChildByName("itemBg_1"):getChildByName("Text_1_0")
		self.icontab[i].iconNumText2:setAnchorPoint(cc.p(0, 0.5))
		self.icontab[i].iconNumText2:setString("/" .. self.changeitemNum[i])
		self.icontab[i].iconNumText2:setPosition(cc.p(self.icontab[i].iconNumText:getPositionX() + self.icontab[i].iconNumText:getContentSize().width * 0.5,self.icontab[i].iconNumText:getPositionY()))
		self.icontab[i].icon:setPosition(cc.p(node:getChildByName("FileNode_2"):getPositionX() + (i - 1) * 81, node:getChildByName("FileNode_2"):getPositionY()))
		node:addChild(self.icontab[i].icon, 6, 66)
	end

	self.equalSp = cc.Scale9Sprite:create("res/StarLeagueScene/ui/icon_reduce.png")
	self.equalSp:setPreferredSize(cc.size(35, 20))
	self.equalSp:setCapInsets(cc.rect(5, 5, 1, 1))
	self.equalSp:setPosition(cc.p(self.icontab[#self.changeitem].icon:getPositionX() + 110, self.icontab[#self.changeitem].icon:getPositionY() + 30))
	node:addChild(self.equalSp)
	self.equalSp2 = cc.Scale9Sprite:create("res/StarLeagueScene/ui/icon_reduce.png")
	self.equalSp2:setPreferredSize(cc.size(35, 20))
	self.equalSp2:setCapInsets(cc.rect(5, 5, 1, 1))
	self.equalSp2:setPosition(cc.p(self.equalSp:getPositionX(), self.equalSp:getPositionY() - self.equalSp:getContentSize().height))
	node:addChild(self.equalSp2)

	for i=1,#self.reveiveitem do
		self.receiveTab[i] = {}
		self.receiveTab[i].icon = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/itemInfo.csb")
		self.receiveTab[i].iconBg = self.receiveTab[i].icon:getChildByName("itemBg_1"):getChildByName("Image_3")
		self.receiveTab[i].iconBg:loadTexture("res/ItemIcon/" .. CONF.ITEM.get(self.reveiveitem[i]).ICON_ID .. ".png")
		self.receiveTab[i].iconNumText = self.receiveTab[i].icon:getChildByName("itemBg_1"):getChildByName("Text_1")
		self.receiveTab[i].iconNumText:setVisible(false)
		self.receiveTab[i].iconNumText2  = self.receiveTab[i].icon:getChildByName("itemBg_1"):getChildByName("Text_1_0")
		self.receiveTab[i].iconNumText2:setString(self.reveiveitemNum[i])
		self.receiveTab[i].iconNumText2:setPosition(cc.p(self.receiveTab[i].iconBg:getContentSize().width * 0.5, self.receiveTab[i].iconNumText:getPositionY()))
		self.receiveTab[i].icon:setPosition(cc.p(self.equalSp:getPositionX() + (self.equalSp:getContentSize().width) * i, self.icontab[#self.changeitem].icon:getPositionY()))
		node:addChild(self.receiveTab[i].icon)
	end

	local nn = 0
	if player:getActivity(eventid) ~= nil then 
		for k,v in pairs(player:getActivity(eventid).change_data.limit_list) do
			if id== v.key then 
				nn = v.value
			end
		end
	end

	local function judge( )
		if nn < CONF.CHANGEITEM.get(id).LIMIT then 
			return true
		else 
		   return false
		end
	end

	if judge() then 
		
		
		btnTab[id].btn:getChildByName("Text_11_0_0_0"):setString(CONF:getStringValue('DUIHUAN'))
		btnTab[id].btn:setBright(true)
		btnTab[id].btn:setTouchEnabled(true)
	else 
		btnTab[id].btn:getChildByName("Text_11_0_0_0"):setString(CONF:getStringValue('YIDUIHUAN'))
		btnTab[id].btn:setBright(false)
		btnTab[id].btn:setTouchEnabled(false)
	end


	return node
end

-- 添加 控件到滑动层
-- scroll 要设置的scorllview
-- cells 添加的item数组
-- colNum 放多少个item
-- gap 间距
function ActivityChange:setScrollView( scroll, cells, colNum, gap , scroll_type)
	-- scroll:removeAllChildren()
	scroll_type = scroll_type or 0
	gap = gap or 10
	colNum = colNum or 1
	local moreGap = 60
	local scrollSize = scroll:getContentSize()
	scroll:setInnerContainerSize(scrollSize)
	local cellH = cells[1]:getContentSize().height
	local cellW = cells[1]:getContentSize().width
	local cellHeight = cellH + gap
	local cellWidth = cellW + gap
	local cellsHeight = cellHeight * math.ceil(#cells/colNum) + moreGap
	local cellsWidth = cellWidth * colNum  + moreGap + 10
	local scrollWidth = scrollSize.width
	local scrollHeight = scrollSize.height
	if scrollHeight < cellsHeight then
		scrollHeight = cellsHeight
		scroll:setInnerContainerSize(cc.size(scrollWidth, scrollHeight))
	end

	local subPosX = scrollWidth / (colNum*2) -- 每格长度
	
	for i, cell in pairs(cells) do
		cell:setAnchorPoint(cc.p(0.5, 0.5))
		local row = math.ceil(i/colNum) -- 行数
		local col = i % colNum          -- 列数
		if col == 0 then
			col = colNum
		end
		local posX = subPosX * (col*2 -1) 
		local posY = scrollHeight - (cellHeight * (row-1)) - cellHeight/2  
		cell:setPosition(posX, posY)
	end

	if scroll_type == 1 then 
		if scrollWidth < cellsWidth then
			scrollWidth = cellsWidth
			scroll:setInnerContainerSize(cc.size(scrollWidth, scrollHeight))
		end

		-- local subPosX = scrollWidth / (colNum*2) -- 每格长度
		
		for i, cell in pairs(cells) do
			cell:setAnchorPoint(cc.p(0.5, 0.5))
			local col = i % colNum          -- 列数
			if col == 0 then
				col = colNum
			end
			-- local posX = subPosX * (col*2 -1) 
			local posX = cellWidth * col - cellW * 0.5 
			local posY = scrollHeight - cellH * 0.5
			cell:setPosition(posX, posY)
		end
	end
end
 
return ActivityChange