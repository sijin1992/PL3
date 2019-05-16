local player = require("app.Player"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local Bit = require "Bit"

local RepairScene = class("RepairScene", cc.load("mvc").ViewBase)

RepairScene.RESOURCE_FILENAME = "RepairScene/RepairScene.csb"

RepairScene.RUN_TIMELINE = true

RepairScene.NEED_ADJUST_POSITION = true

RepairScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function RepairScene:onCreate(data)
	self.data_ = data

end

function RepairScene:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" and event.target:getName() == "close" then
		printInfo("close")
		playEffectSound("sound/system/return.mp3")
		self:getApp():popView()
		
	end

end

function RepairScene:onEnter()
  
	printInfo("RepairScene:onEnter()")

end

function RepairScene:onExit()
	
	printInfo("RepairScene:onExit()")
end

function RepairScene:createInfoNode( guid )

	local rn = self:getResourceNode()

	if rn:getChildByName("info_node") then
		rn:getChildByName("info_node"):removeFromParent()
	end

	-- self.svd_:getScrollView():getChildByTag(guid):getChildByName("bg"):getChildByName("selected_1"):loadTexture("Common/newUI/rw_tiao.png")
	self.svd_:getScrollView():getChildByTag(guid):getChildByName("bg"):getChildByName("selected_2"):setVisible(true)
	self.svd_:getScrollView():getChildByTag(guid):getChildByName("bg"):getChildByName("selected_1"):setVisible(false)
	self.svd_:getScrollView():getChildByTag(guid):getChildByName("bg"):getChildByName("Image_1"):setVisible(true)
	if self.svd_:getScrollView():getChildByTag(self.svd_:getScrollView():getTag()) then
		-- self.svd_:getScrollView():getChildByTag(self.svd_:getScrollView():getTag()):getChildByName("bg"):getChildByName("selected_1"):loadTexture("Common/newUI/rw_tiao.png")
		self.svd_:getScrollView():getChildByTag(self.svd_:getScrollView():getTag()):getChildByName("bg"):getChildByName("selected_2"):setVisible(false)
		self.svd_:getScrollView():getChildByTag(self.svd_:getScrollView():getTag()):getChildByName("bg"):getChildByName("selected_1"):setVisible(true)
		self.svd_:getScrollView():getChildByTag(self.svd_:getScrollView():getTag()):getChildByName("bg"):getChildByName("Image_1"):setVisible(false)
		-- self.svd_:getScrollView():getChildByTag(self.svd_:getScrollView():getTag()):setPositionX(self.svd_:getScrollView():getChildByTag(self.svd_:getScrollView():getTag()):getPositionX() + 13)
	end

	-- self.svd_:getScrollView():getChildByTag(guid):setPositionX(self.svd_:getScrollView():getChildByTag(guid):getPositionX() - 13)
	self.svd_:getScrollView():setTag(guid)

	local info = player:getShipByGUID(guid)
	local conf = CONF.AIRSHIP.get(info.id)

	local node = require("app.ExResInterface"):getInstance():FastLoad("RepairScene/repair_ship_info.csb")

	node:getChildByName("power"):setString(CONF:getStringValue("combat")..":")

	node:getChildByName("ship_type"):setTexture("ShipType/"..conf.TYPE..".png")
	node:getChildByName("ship_name"):setString(CONF:getStringValue(conf.NAME_ID))
	node:getChildByName("ship_image"):setTexture("ShipImage/"..conf.ICON_ID..".png")
	node:getChildByName("power_num"):setString(player:calShipFightPower(guid))

	node:getChildByName("power_num"):setPositionX(node:getChildByName("power"):getPositionX() + node:getChildByName("power"):getContentSize().width)
	-- node:getChildByName("durability_now"):setString(info.durable)
	-- node:getChildByName("durability_max"):setString("/"..Tools.getShipMaxDurable(info))
	node:getChildByName("unavailable"):getChildByName("text"):setString(CONF:getStringValue("unavailable"))

	-- node:getChildByName("durability_max"):setPositionX(node:getChildByName("durability_now"):getPositionX() + node:getChildByName("durability_now"):getContentSize().width)

	node:getChildByName("btn_sqr"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local ship_info_node = require("app.views.StarOccupationLayer.FormShipInfoNode"):create()
		ship_info_node:init(self, guid)
		ship_info_node:setLocalZOrder(20)
		node:addChild(ship_info_node)

		
	end)

	node:getChildByName("btn_sqr"):setPositionX(node:getChildByName("ship_name"):getPositionX() + node:getChildByName("ship_name"):getContentSize().width + 10)

	if info.durable < Tools.getShipMaxDurable(info)/10 then
		node:getChildByName("unavailable"):setVisible(true)
	end
	
	node:setName("info_node")
	node:setPosition(cc.p(rn:getChildByName("info_pos"):getPosition()))
	rn:addChild(node)

end

function RepairScene:createShipNode( guid )
	local info = player:getShipByGUID(guid)
	local conf = CONF.AIRSHIP.get(info.id)

	local node = require("app.ExResInterface"):getInstance():FastLoad("RepairScene/repair_ship.csb")
	local bg = node:getChildByName("bg")

	bg:getChildByName("image"):loadTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
	bg:getChildByName("icon"):setTexture("RoleIcon/"..conf.DRIVER_ID..".png")
    bg:getChildByName("icon"):setVisible(false)
    bg:getChildByName("icon2"):setVisible(true)
    bg:getChildByName("icon2"):setTexture("ShipImage/"..conf.DRIVER_ID..".png")
	bg:getChildByName("shipType"):setTexture("ShipType/"..conf.TYPE..".png")
	bg:getChildByName("levelNum"):setString(info.level)

--	for i=info.ship_break+1,6 do
--		bg:getChildByName("star_"..i):removeFromParent()
--	end

    ShowShipStar(bg,info.ship_break,"star_")

	local un_repairing_node = bg:getChildByName("UnrepairingNode")

	local bili = math.floor(info.durable/Tools.getShipMaxDurable(info)*100)
	-- un_repairing_node:getChildByName("durabilityNum"):setString(bili.."%")
	un_repairing_node:getChildByName("time"):setString(formatTime(Tools.getFixShipDurableTime( info, player:getUserInfo(), player:getTechnolgList(), player:getPlayerGroupTech())))
	un_repairing_node:getChildByName("btnRepair"):getChildByName("text"):setString(Tools.getFixShipDurableGold(info))

	un_repairing_node:getChildByName("durability_now"):setString(info.durable)
	un_repairing_node:getChildByName("durability_max"):setString("/"..Tools.getShipMaxDurable(info))
	un_repairing_node:getChildByName("durability_max"):setLocalZOrder(10)
	un_repairing_node:getChildByName("durability_now"):setLocalZOrder(10)

	un_repairing_node:getChildByName("btnRepair"):addClickEventListener(function ( ... )

		playEffectSound("sound/system/click.mp3")
		local info = player:getShipByGUID(guid)
		if player:getResByIndex(1) < Tools.getFixShipDurableGold(info) then
			local jumpTab = {}
            local cfg_item = CONF.ITEM.get(3001)
            if cfg_item and cfg_item.JUMP then
                table.insert(jumpTab,cfg_item.JUMP)
            end
            if Tools.isEmpty(jumpTab) == false and not self:getChildByName("JumpChoseLayer") then
            	jumpTab.scene = "RepairScene"
                local center = cc.exports.VisibleRect:center()
                local layer = self:getApp():createView("ShipsScene/JumpChoseLayer",jumpTab)
                tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
            	layer:setName("JumpChoseLayer")
                self:addChild(layer)
            end
			tips:tips(CONF:getStringValue("notEnoughGold"))
			return
		end

		self.pos_Y = self.svd_:getScrollView():getInnerContainer():getPositionY()

		self.index_ = guid
		self.type_ = 2
		local strData = Tools.encode("ShipFixReq", {
			type = 2,
			guids = {guid},
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_FIX_REQ"),strData)

		gl:retainLoading()  
	end)

	local bs = cc.size(320, 20)
	local progress = require("util.ClippingScaleProgressDelegate"):create("TaskScene/ui/active_progress.png", 320, {bg_size = bs, lightLength = 0})
	progress:getClippingNode():setPosition(cc.p(un_repairing_node:getChildByName("progressBg"):getPosition()))
	un_repairing_node:addChild(progress:getClippingNode())

	progress:setPercentage(info.durable/Tools.getShipMaxDurable(info)*100)

	local repair_node = bg:getChildByName("RepairingNode")
	repair_node:getChildByName("repairing"):setString(CONF:getStringValue("repair_now"))

	local totleTime = Tools.getFixShipDurableTime(info ,player:getUserInfo(), player:getTechnolgList(), player:getPlayerGroupTech()) 
	local needTime = totleTime - (player:getServerTime() - info.start_fix_time)

	repair_node:getChildByName("durabilityNum"):setString(formatTime(needTime))

	repair_node:getChildByName("btnRepair"):getChildByName("text"):setString(self:getSpeedUpNeedMoney(needTime))
	repair_node:getChildByName("btnCancel"):getChildByName("text"):setString(CONF:getStringValue("cancel"))
	repair_node:getChildByName("btnRepair"):getChildByName("free_text"):setString(CONF:getStringValue("free"))

	if self:getSpeedUpNeedMoney(needTime) == 0 then
		repair_node:getChildByName("btnRepair"):getChildByName("text"):setVisible(false)
		repair_node:getChildByName("btnRepair"):getChildByName("icon"):setVisible(false)
		repair_node:getChildByName("btnRepair"):getChildByName("free_text"):setVisible(true)
	end

	repair_node:getChildByName("btnRepair"):addClickEventListener(function ( ... )

		playEffectSound("sound/system/click.mp3")

		if player:getMoney() < tonumber(repair_node:getChildByName("btnRepair"):getChildByName("text"):getString()) then
			-- tips:tips(CONF:getStringValue("no enought credit"))
			local function func()
				local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

				rechargeNode:init(self, {index = 1})
				self:addChild(rechargeNode)
			end

			local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
			return
		end

		self.pos_Y = nil

		self.index_ = 0
		self.type_ = 4
		local strData = Tools.encode("ShipFixReq", {
			type = 4,
			guids = {guid},
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_FIX_REQ"),strData)

		gl:retainLoading()
	end)

	repair_node:getChildByName("btnCancel"):addClickEventListener(function ( ... )

		playEffectSound("sound/system/return.mp3")

		self.pos_Y = self.svd_:getScrollView():getInnerContainer():getPositionY()

		self.index_ = guid
		self.type_ = 3
		local strData = Tools.encode("ShipFixReq", {
			type = 3,
			guids = {guid},
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_FIX_REQ"),strData)

		gl:retainLoading()
	end)

	if Bit:has(info.status, 2) == false then
		un_repairing_node:setVisible(true)
		repair_node:setVisible(false)
	else
		un_repairing_node:setVisible(false)
		repair_node:setVisible(true)
	end

	return node

end

function RepairScene:addListener( node, func )
	local isTouchMe = false

	local function onTouchBegan(touch, event)

		self.resetMove = 0
		self.direction = 0

		local target = event:getCurrentTarget()
		
		local locationInNode = self.svd_:getScrollView():convertToNodeSpace(touch:getLocation())

		local sv_s = self.svd_:getScrollView():getContentSize()
		local sv_rect = cc.rect(0, 0, sv_s.width, sv_s.height)

		if cc.rectContainsPoint(sv_rect, locationInNode) then

			local ln = target:convertToNodeSpace(touch:getLocation())

			local s = target:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)
			
			if cc.rectContainsPoint(rect, ln) then
				isTouchMe = true
				return true
			end

		end

		return false
	end

	local function onTouchMoved(touch, event)

		local target = event:getCurrentTarget()

		local diff = touch:getDelta()

		if math.abs(diff.x) > g_click_delta or math.abs(diff.y) > g_click_delta then
			isTouchMe = false

			if self.resetMove == 0 then
				if math.abs(diff.x) > math.abs(diff.y) then
					self.direction = 1
				else
					self.direction = 2
				end

				self.resetMove = 1
			end

			if self.direction == 1 then
				self.svd_:getScrollView():setTouchEnabled(false)
			end

			if self.direction == 2 then
				return true
			end

			if target:getChildByName("RepairingNode"):isVisible() then
				if diff.x < 0 then
					if target:getPositionX() >= -91 then
						if target:getPositionX() + diff.x < -91 then
							target:setPositionX(-91)
						else
							target:setPositionX(target:getPositionX() + diff.x)
						end
					end
				end

				if diff.x > 0 then
					if target:getPositionX() <= 0 then
						if target:getPositionX() + diff.x > 0 then
							target:setPositionX(0)
						else
							target:setPositionX(target:getPositionX() + diff.x)
						end
					end
				end
			end
	
		end

	end

	local function onTouchEnded(touch, event)

		if self.direction == 2 then
			return true
		end

		self.svd_:getScrollView():setTouchEnabled(true)

		local target = event:getCurrentTarget()

		if isTouchMe == true then
				
			func(node)
		else
			if target:getPositionX() <= -91/2 then
				target:runAction(cc.MoveBy:create(0.1, cc.p(-91 - target:getPositionX(), 0)))
			else
				target:runAction(cc.MoveBy:create(0.1, cc.p(-target:getPositionX(), 0)))
			end
		end
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self.svd_:getScrollView():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

function RepairScene:resetList()

	local rn = self:getResourceNode()

	self.fix_ship = {}
	self.no_fix_ship = {}
	
	self.svd_:clear()

	local repair_ship_list = {}

	for i,v in ipairs(player:getShipList()) do

		if Bit:has(v.status, 4) then

		else
			if v.durable < Tools.getShipMaxDurable(v) then
				table.insert(repair_ship_list, v)

				print("reset", v.guid,Bit:has(v.status, 2))

				if Bit:has(v.status, 2) == true then
					table.insert(self.fix_ship, v.guid)
				else
					table.insert(self.no_fix_ship, v.guid)
				end
				
			end
		end
	end

	self:resetInfo(repair_ship_list)

	if #repair_ship_list == 0 then
		rn:getChildByName("noship"):setVisible(true)

		if rn:getChildByName("info_node") then
			rn:getChildByName("info_node"):removeFromParent()
		end

		return
	else
		rn:getChildByName("noship"):setVisible(false)
	end

	local function sort( a,b )

		if a.quality ~= b.quality then
			return a.quality > b.quality
		else
			local af = player:calShipFightPower(a.guid)
			local bf = player:calShipFightPower(b.guid)
			if af ~= bf then
				return af > bf
			else
				if a.level > b.level then
					return a.level > b.level
				else
					if a.id ~= b.id then
						return a.id > b.id 
					end
				end
			end
		end
	end

	table.sort( repair_ship_list, sort )

	if self.index_ == 0 then
		self.index_ = repair_ship_list[1].guid
	end
	

	for i,v in ipairs(repair_ship_list) do
		
		local node = self:createShipNode(v.guid)
		node:setTag(v.guid)
		node:getChildByName("bg"):setTag(i)
		node:setName("ship_"..v.guid)

		self:addListener(node:getChildByName("bg"), function ( ... )
			self:createInfoNode(node:getTag())
		end)

		self.svd_:addElement(node)

		if v.guid == self.index_ then
			self:createInfoNode(v.guid)
		end
		
	end

	if self.pos_Y then
		self.svd_:getScrollView():getInnerContainer():setPositionY(self.pos_Y)
	end

end

function RepairScene:resetInfo(list)
	
	local rn = self:getResourceNode()

	if #list == 0 then
--		rn:getChildByName("ship_num"):setVisible(false)
--		rn:getChildByName("ships"):setVisible(false)
--		rn:getChildByName("durability"):setVisible(false)
--		rn:getChildByName("progressBg"):setVisible(false)
--		rn:getChildByName("progress"):setVisible(false)
--		-- rn:getChildByName("persent"):setVisible(false)
--		rn:getChildByName("durability_now"):setVisible(false)
--		rn:getChildByName("durability_max"):setVisible(false)
		rn:getChildByName("btn_repair"):setVisible(false)
--		rn:getChildByName("time"):setVisible(false)

		rn:getChildByName("repairing"):setVisible(false)
		--rn:getChildByName("durability_num"):setVisible(false)
	else
		if #self.no_fix_ship == 0 then
--			rn:getChildByName("ship_num"):setVisible(false)
--			rn:getChildByName("ships"):setVisible(false)
--			rn:getChildByName("durability"):setVisible(false)
--			rn:getChildByName("progressBg"):setVisible(false)
--			rn:getChildByName("progress"):setVisible(false)
--			-- rn:getChildByName("persent"):setVisible(false)
--			rn:getChildByName("durability_now"):setVisible(false)
--			rn:getChildByName("durability_max"):setVisible(false)
--			rn:getChildByName("time"):setVisible(false)

			rn:getChildByName("repairing"):setVisible(true)
			--rn:getChildByName("durability_num"):setVisible(true)

			rn:getChildByName("btn_repair"):setVisible(true)
			rn:getChildByName("btn_repair"):getChildByName("text"):setVisible(false)
			rn:getChildByName("btn_repair"):getChildByName("text2"):setVisible(true)
			rn:getChildByName("btn_repair"):getChildByName("icon"):setVisible(true)
			rn:getChildByName("btn_repair"):getChildByName("free_text"):setVisible(false)

			rn:getChildByName("btn_repair"):getChildByName("text2"):setString(self:getAllFixMoney())

			if self:getAllFixMoney() == 0 then
				rn:getChildByName("btn_repair"):getChildByName("text2"):setVisible(false)
				rn:getChildByName("btn_repair"):getChildByName("text"):setVisible(false)
				rn:getChildByName("btn_repair"):getChildByName("icon"):setVisible(false)
				rn:getChildByName("btn_repair"):getChildByName("free_text"):setVisible(true)
			end

			--rn:getChildByName("durability_num"):setString(formatTime(self:getAllFixTime()))

		else

--			rn:getChildByName("ship_num"):setVisible(true)
--			rn:getChildByName("ships"):setVisible(true)
--			rn:getChildByName("durability"):setVisible(true)
--			rn:getChildByName("progressBg"):setVisible(true)
--			rn:getChildByName("progress"):setVisible(true)
--			-- rn:getChildByName("persent"):setVisible(true)
--			rn:getChildByName("durability_now"):setVisible(true)
--			rn:getChildByName("durability_max"):setVisible(true)
--			rn:getChildByName("time"):setVisible(true)

			rn:getChildByName("repairing"):setVisible(false)
			--rn:getChildByName("durability_num"):setVisible(false)

			rn:getChildByName("btn_repair"):setVisible(true)
			rn:getChildByName("btn_repair"):getChildByName("text"):setVisible(true)
			rn:getChildByName("btn_repair"):getChildByName("text2"):setVisible(false)
			rn:getChildByName("btn_repair"):getChildByName("icon"):setVisible(false)
			rn:getChildByName("btn_repair"):getChildByName("free_text"):setVisible(false)

--			self.progress:setPercentage(self:getAllDurablePercent())
--			-- rn:getChildByName("persent"):setString(self:getAllDurablePercent().."%")

--			local now,max = self:getAllDurableText() 
--			rn:getChildByName("durability_now"):setString(now)
--			rn:getChildByName("durability_max"):setString("/"..max)

--			rn:getChildByName("ship_num"):setString(#self.no_fix_ship.."/"..#list)
--			rn:getChildByName("time"):setString(formatTime(self:getAllNoFixTime()))

		end
	end
    rn:getChildByName("repairing"):setVisible(true);
    --rn:getChildByName("repairing"):setString(CONF.)
end

function RepairScene:getAllNoFixTime( ... )
	local time = 0
	for i,v in ipairs(self.no_fix_ship) do
		local info = player:getShipByGUID(v)
		local totleTime = Tools.getFixShipDurableTime(info ,player:getUserInfo(), player:getTechnolgList(), player:getPlayerGroupTech() ) 

		time = time + totleTime
	end

	return time
end

function RepairScene:getAllDurablePercent( ... )
	local now = 0
	local max = 0

	for i,v in ipairs(self.no_fix_ship) do
		local info = player:getShipByGUID(v)
		now = now + info.durable
		max = max + Tools.getShipMaxDurable(info)
	end

	return math.floor(now/max*100)
end

function RepairScene:getAllDurableText( ... )
	local now = 0
	local max = 0

	for i,v in ipairs(self.no_fix_ship) do
		local info = player:getShipByGUID(v)
		now = now + info.durable
		max = max + Tools.getShipMaxDurable(info)
	end

	return now,max
end

function RepairScene:getAllFixTime()

	local time = 0
	for i,v in ipairs(self.fix_ship) do
		local info = player:getShipByGUID(v)
		local totleTime = Tools.getFixShipDurableTime(info ,player:getUserInfo(), player:getTechnolgList(), player:getPlayerGroupTech() ) 
		local needTime = totleTime - (player:getServerTime() - info.start_fix_time)

		time = time + needTime
	end

	return time
end

function RepairScene:getAllFixMoney( ... )
	local time = 0
	for i,v in ipairs(self.fix_ship) do
		local info = player:getShipByGUID(v)
		local totleTime = Tools.getFixShipDurableTime(info ,player:getUserInfo() , player:getTechnolgList(), player:getPlayerGroupTech()) 
		local needTime = totleTime - (player:getServerTime() - info.start_fix_time)

		local money = self:getSpeedUpNeedMoney(needTime)
		time = time + money
	end

	return time
end

function RepairScene:onEnterTransitionFinish()

	printInfo("RepairScene:onEnterTransitionFinish()")

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kRepair)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("city_8_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end

	self.index_ = 0
	self.fix_ship = {}
	self.no_fix_ship = {}

	self.pos_Y = nil
	self.type_ = 0

	self.direction = 0
	self.resetMove = 0

	local rn = self:getResourceNode()

	rn:getChildByName("Text_1"):setString(CONF:getStringValue("ship_list"))
	rn:getChildByName("repair_name"):setString(CONF:getStringValue("BuildingName_7"))
	local contentX = rn:getChildByName("repair_name"):getContentSize().width;
	-- rn:getChildByName("repair_name"):getChildByName("Image_1"):setPositionX(contentX + 10);
	rn:getChildByName("btn_repair"):getChildByName("text"):setString(CONF:getStringValue("repairAll"))
	rn:getChildByName("btn_repair"):getChildByName("free_text"):setString(CONF:getStringValue("free"))

	rn:getChildByName("noship"):setString(CONF:getStringValue("no_need_fix_ship"))

	rn:getChildByName("repairing"):setString(CONF:getStringValue("repair text"))

	local bs = cc.size(667.00, 20)


	-- self.progress:setOpacity(0)
	-- setScreenPosition(self.progress:getClippingNode(), "bottom")

	rn:getChildByName("btn_repair"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")
		-- if #self.no_fix_ship == 0 then
		--     tips:tips(CONF:getStringValue("no_need_fix_ship"))
		--     return
		-- end

		if #self.no_fix_ship > 0 then

			local gold = 0
			for i,v in ipairs(self.no_fix_ship) do
				local ship_info = player:getShipByGUID(v)
				gold = gold + Tools.getFixShipDurableGold( ship_info )
			end

			if player:getResByIndex(1) < gold then
				local jumpTab = {}
	            local cfg_item = CONF.ITEM.get(3001)
	            if cfg_item and cfg_item.JUMP then
	                table.insert(jumpTab,cfg_item.JUMP)
	            end
	            if Tools.isEmpty(jumpTab) == false and not self:getChildByName("JumpChoseLayer") then
	            	jumpTab.scene = "RepairScene"
	                local center = cc.exports.VisibleRect:center()
	                local layer = self:getApp():createView("ShipsScene/JumpChoseLayer",jumpTab)
	                tipsAction(layer, cc.p(center.x + (rn:getContentSize().width/2 - center.x), center.y + (rn:getContentSize().height/2 - center.y)))
                	layer:setName("JumpChoseLayer")
	                self:addChild(layer)
	            end
				tips:tips(CONF:getStringValue("notEnoughGold"))
				return
			end

			self.type_ = 2
			local strData = Tools.encode("ShipFixReq", {
				type = 2,
				guids = self.no_fix_ship,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_FIX_REQ"),strData)

			gl:retainLoading() 
		else

			local gold = 0
			for i,v in ipairs(self.fix_ship) do
				local ship_info = player:getShipByGUID(v)
				gold = gold + self:getSpeedUpNeedMoney(Tools.getFixShipDurableTime( ship_info, player:getUserInfo(), player:getTechnolgList(), player:getPlayerGroupTech() ))
			end

			if player:getMoney() < gold then
				-- tips:tips(CONF:getStringValue("no enought credit"))
				local function func()
					local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

					rechargeNode:init(self, {index = 1})
					self:addChild(rechargeNode)
				end

				local messageBox = require("util.MessageBox"):getInstance()
				messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
				return
			end

			self.pos_Y = nil
			self.type_ = 4
			local strData = Tools.encode("ShipFixReq", {
				type = 4,
				guids = self.fix_ship,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_FIX_REQ"),strData)

			gl:retainLoading() 
		end
	end)

	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(0,10), cc.size(636,81))
	self.svd_:getScrollView():setScrollBarEnabled(false)

	local guids = {}

	for i,v in ipairs(player:getShipList()) do
		if v.durable < Tools.getShipMaxDurable(v) then
			table.insert(guids, v.guid)
		end
	end

	if #guids > 0 then
		local strData = Tools.encode("ShipFixReq", {
			type = 1,
			guids = guids,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_FIX_REQ"),strData)

		gl:retainLoading()  
	else
		self:resetList()
	end

	local function update( ... )
		for i,v in ipairs(self.fix_ship) do

			local info = player:getShipByGUID(v)
			local node = self.svd_:getScrollView():getChildByTag(v)
			local bg = node:getChildByName("bg")
			local repair_node = bg:getChildByName("RepairingNode")
			repair_node:getChildByName("repairing"):setString(CONF:getStringValue("repair_now"))

			local totleTime = Tools.getFixShipDurableTime(info ,player:getUserInfo(), player:getTechnolgList(), player:getPlayerGroupTech() ) 
			local needTime = totleTime - (player:getServerTime() - info.start_fix_time)

			if needTime <= 1 then
				
				print("jinlai")

				-- if rn:getChildByName("info_node") then
				--     rn:getChildByName("info_node"):removeFromParent()
				-- end

				self.type_ = 1
				self.index_ = 0
   
			end

			repair_node:getChildByName("durabilityNum"):setString(formatTime(needTime))

			repair_node:getChildByName("btnRepair"):getChildByName("text"):setString(self:getSpeedUpNeedMoney(needTime))

			if self:getSpeedUpNeedMoney(needTime) == 0 then
				repair_node:getChildByName("btnRepair"):getChildByName("text"):setVisible(false)
				repair_node:getChildByName("btnRepair"):getChildByName("icon"):setVisible(false)
				repair_node:getChildByName("btnRepair"):getChildByName("free_text"):setVisible(true)
			end
		end

		--rn:getChildByName("durability_num"):setString(formatTime(self:getAllFixTime()))
		rn:getChildByName("btn_repair"):getChildByName("text2"):setString(self:getAllFixMoney())

		if #self.no_fix_ship == 0 then
			if self:getAllFixMoney() == 0 then
				rn:getChildByName("btn_repair"):getChildByName("text2"):setVisible(false)
				rn:getChildByName("btn_repair"):getChildByName("text"):setVisible(false)
				rn:getChildByName("btn_repair"):getChildByName("icon"):setVisible(false)
				rn:getChildByName("btn_repair"):getChildByName("free_text"):setVisible(true)
			end
		end
	end
	
	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	local function recvMsg()
		print("RepairScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SHIP_FIX_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("ShipFixResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else

				if self.type_ == 1 or self.type_ == 4 then
					-- tips:tips(CONF:getStringValue("repairingOK"))

					local texiao_node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/qianghua.csb")
					texiao_node:getChildByName("text"):setString(CONF:getStringValue("repairingOK"))


					texiao_node:getChildByName("text"):runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
						texiao_node:getChildByName("text"):setVisible(true)
					end)))
					animManager:runAnimOnceByCSB(texiao_node:getChildByName("texiao"), "ShipsScene/sfx/qianghua.csb", "1", function ( ... )
						texiao_node:removeFromParent()
					end)
					texiao_node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(texiao_node)
				end

				self:resetList()
			end
		end
	end
	self:resetRes()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		self:resetRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		self:resetRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)
	animManager:runAnimOnceByCSB(self:getResourceNode(), "RepairScene/RepairScene.csb" ,"intro", function ( )
		
	end)

end

function RepairScene:resetRes()
	if self:getResourceNode():getChildByName('Gold_Diamond') == nil then
		local node = require("app.ExResInterface"):getInstance():FastLoad("MoneyNode/Gold_Diamond.csb")
		node:setName('Gold_Diamond')
		self:getResourceNode():addChild(node)
		node:setPosition(self:getResourceNode():getChildByName('Money_pos'):getPosition())
	end
	if self:getResourceNode():getChildByName('Gold_Diamond') ~= nil then
		for i=1, 4 do
			if self:getResourceNode():getChildByName('Gold_Diamond'):getChildByName(string.format("res_%d",i)) then
				self:getResourceNode():getChildByName('Gold_Diamond'):getChildByName(string.format("res_%d",i)):getChildByName('text'):setString(formatRes(player:getResByIndex(i)))
			end
		end
		self:getResourceNode():getChildByName('Gold_Diamond'):getChildByName("res_5"):getChildByName('text'):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
		self:getResourceNode():getChildByName('Gold_Diamond'):getChildByName("res_5"):getChildByName('add'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

			rechargeNode:init(self:getParent(), {index = 1})
			self:getParent():addChild(rechargeNode)
		end)
	end
end


function RepairScene:getSpeedUpNeedMoney( time )
	if time <= CONF.PARAM.get("free_fix_ship_time").PARAM then
		return 0
	else
		return player:getSpeedUpNeedMoney(time)
	end
end


function RepairScene:onExitTransitionStart()

	printInfo("RepairScene:onExitTransitionStart()")

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)

	if self.svd_ then
		self.svd_:clear()
	end
end

return RepairScene