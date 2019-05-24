
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local planetMachine = require("app.views.PlanetScene.Manager.PlanetMachine"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local planetArmyManager = require("app.views.PlanetScene.Manager.PlanetArmyManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local winSize = cc.Director:getInstance():getWinSize()

local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local PlanetWarningInfoLayer = class("PlanetWarningInfoLayer", cc.load("mvc").ViewBase)

PlanetWarningInfoLayer.RESOURCE_FILENAME = "PlanetScene/PlanetWarningInfoLayer.csb"

PlanetWarningInfoLayer.RUN_TIMELINE = true

PlanetWarningInfoLayer.NEED_ADJUST_POSITION = true

PlanetWarningInfoLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

function PlanetWarningInfoLayer:onCreate( data )
	self.data_ = data
end

function PlanetWarningInfoLayer:onEnter()
  
	printInfo("PlanetWarningInfoLayer:onEnter()")

end

function PlanetWarningInfoLayer:onExit()
	
	printInfo("PlanetWarningInfoLayer:onExit()")
end

function PlanetWarningInfoLayer:resetRes( ... )
	local rn = self:getResourceNode()
	local res_node = rn:getChildByName("res_node")
	for i=1,4 do
		res_node:getChildByName("res_text_"..i):setString(formatRes(player:getResByIndex(i)))
	end
	res_node:getChildByName("res_text_5"):setString(player:getMoney())
end

function PlanetWarningInfoLayer:resetList( info_list )

	if info_list == nil then
		return
	end

	self.svd_:clear()
-- 	message PlanetArmyInfo{
-- 	required PlanetElement my_base = 1;
-- 	required PlanetArmy army = 2;
-- 	required PlanetElement target_element = 3;
-- };

	local function addListener( node, func)

		local isTouchMe = false

		local sv = self.svd_:getScrollView()

		local function onTouchBegan(touch, event)

			local target = event:getCurrentTarget()
			
			local locationInNode = sv:convertToNodeSpace(touch:getLocation())

			local sv_s = sv:getContentSize()
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

			local delta = touch:getDelta()
			if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
				isTouchMe = false
			end
		end

		local function onTouchEnded(touch, event)
			if isTouchMe == true then
					
				func(node)
			end
		end

		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(false)
		listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
		listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
		listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

		local eventDispatcher = sv:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
	end

	local function createListItem( info )
		local v = info
		local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/WarningInfoNode.csb")
		node:getChildByName("ship_num"):setString(CONF:getStringValue("dispatch ship")..":"..#v.army.ship_list)
		node:getChildByName("icon"):setTexture("HeroImage/"..v.my_base.base_data.info.icon_id..".png")
		node:getChildByName("name"):setString(v.my_base.base_data.info.nickname.."  Lv."..v.my_base.base_data.info.level)
	
		local ship_pos = cc.p(node:getChildByName("ship_pos"):getPosition())
		for i2,v2 in ipairs(v.army.ship_list) do
			local conf = CONF.AIRSHIP.get(v2.id)

			local ship_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/PlanetShip.csb")
			ship_node:getChildByName("lvNum"):setString(v2.level)
			ship_node:getChildByName("shipType"):setTexture("ShipType/"..v2.type..".png")

			if not self.see_ship_level then
				ship_node:getChildByName("lvNum"):setVisible(false)
			end

			ship_node:getChildByName("icon"):setTexture("RoleIcon/"..conf.ICON_ID..".png")
			ship_node:getChildByName("background"):loadTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")

			if self.see_ship_break then
--				if v2.ship_break and v2.ship_break > 0 then
--					for j=1,v2.ship_break do
--						ship_node:getChildByName("star_"..j):setVisible(true)
--					end
--				end
                player:ShowShipStar(ship_node,v2.ship_break,"star_")
			end

			-- ship_node:setPosition(cc.p(ship_pos.x + (i-1)*100, ship_pos.y))
			ship_node:setPosition(cc.p((i2-1)*100, 0))
			node:getChildByName("ship_pos"):addChild(ship_node)

			addListener(ship_node:getChildByName("background"), function ( ... )

				if not self.see_ship_info then
					return
				end

				local ship_info_node = require("util.ItemInfoNode"):createShipInfoNodeByInfo(v2)
				ship_info_node:setPosition(cc.p(cc.exports.VisibleRect:center().x - ship_info_node:getChildByName("landi"):getContentSize().width/2, cc.exports.VisibleRect:center().y + ship_info_node:getChildByName("landi"):getContentSize().height/2 + 20))
				-- ship_info_node:setPosition(cc.exports.VisibleRect:center())
				self:getResourceNode():addChild(ship_info_node)
			end)
		end

		return node
		
	end

	if self.see_ship_num then
		if self.data_.info.army.status_machine ~= 4 then
			local node = createListItem(self.data_.info)
			node:setName("army_node_1")
			node:getChildByName("army_num"):setString(CONF:getStringValue("queue").."1")
			self.svd_:addElement(node)
		end

		print("#info_list",#info_list)
		for i,v in ipairs(info_list) do
			local node = createListItem(v)
			node:setName("army_node_"..i+1)
			node:getChildByName("army_num"):setString(CONF:getStringValue("queue")..i+1)
			self.svd_:addElement(node)
		end
	else
		local rn = self:getResourceNode()
		rn:getChildByName("no_text"):setVisible(true)
	end
end

function PlanetWarningInfoLayer:resetBuildInfo()
	local info = player:getBuildingInfo(CONF.EBuilding.kSpy)
	local conf = CONF.BUILDING_11.get(info.level)
	local rn = self:getResourceNode()

	local team_str = ""
	if self.data_.info.army.mass_time - (player:getServerTime() - self.data_.info.army.begin_time) >= 0 then
		team_str = Split(CONF:getStringValue("text_1"), "#")[2]
	else
		if #self.data_.info.army.army_key_list + #self.data_.info.army.req_army_key_list > 0 then 
			team_str = Split(CONF:getStringValue("text_1"), "#")[2]
		end
	end


	for i,v in ipairs(conf.BE_ATTACK) do
		if v == 1 then



			if self.data_.info.my_base.base_data.info.group_nickname ~= nil and self.data_.info.my_base.base_data.info.group_nickname ~= "" then
				rn:getChildByName("people"):setString("["..CONF:getStringValue("unknown").."]"..self.data_.info.my_base.base_data.info.nickname..team_str)	
			else
				rn:getChildByName("people"):setString(self.data_.info.my_base.base_data.info.nickname..team_str)	
			end
		elseif v == 2 then
			local des_str = ("X:".. self.data_.info.my_base.pos_list[1].x .. ", Y:".. self.data_.info.my_base.pos_list[1].y)
			rn:getChildByName("pos"):setString(des_str)
		elseif v == 3 then
			if self.data_.info.army.mass_time - (player:getServerTime() - self.data_.info.army.begin_time) >= 0 then
				local percent = ( self.data_.info.army.mass_time - (player:getServerTime() - self.data_.info.army.begin_time)) / self.data_.info.army.mass_time
				if percent < 0 then
					local app = require("app.MyApp"):getInstance()
					self:getApp():removeTopView()
					app:addView2Top("PlanetScene/PlanetWarningLayer")
				else
					if percent > 100 then
						percent = 100
					end
					rn:getChildByName("jijie_tiao"):setContentSize(cc.size(rn:getChildByName("jijie_tiao"):getTag()*percent, rn:getChildByName("jijie_tiao"):getContentSize().height))
					rn:getChildByName("jijie_text"):setString(CONF:getStringValue("mass in")..":"..formatTime(self.data_.info.army.mass_time - (player:getServerTime() - self.data_.info.army.begin_time)))
				end
				
			else
				local percent = ( self.data_.info.army.line.need_time - (player:getServerTime() - self.data_.info.army.line.begin_time)) / self.data_.info.army.line.need_time
				if percent < 0 then
					local app = require("app.MyApp"):getInstance()
					self:getApp():removeTopView()
					app:addView2Top("PlanetScene/PlanetWarningLayer")
				else

					if percent > 100 then
						percent = 100
					end
					rn:getChildByName("jijie_tiao"):setContentSize(cc.size(rn:getChildByName("jijie_tiao"):getTag()*percent, rn:getChildByName("jijie_tiao"):getContentSize().height))
					if #self.data_.info.army.army_key_list + #self.data_.info.army.req_army_key_list > 0 then
						rn:getChildByName("jijie_text"):setString(CONF:getStringValue("approach in")..":"..formatTime(self.data_.info.army.line.need_time - (player:getServerTime() - self.data_.info.army.line.begin_time)))
					else
						rn:getChildByName("jijie_text"):setString(CONF:getStringValue("approach in")..":"..formatTime(self.data_.info.army.line.need_time - (player:getServerTime() - self.data_.info.army.line.begin_time)))
					end
				end
				
			end
		elseif v == 4 then
			if self.data_.info.my_base.base_data.info.group_nickname ~= nil and self.data_.info.my_base.base_data.info.group_nickname ~= "" then
				rn:getChildByName("people"):setString("["..self.data_.info.my_base.base_data.info.group_nickname.."]"..self.data_.info.my_base.base_data.info.nickname..team_str)	
			else
				rn:getChildByName("people"):setString(self.data_.info.my_base.base_data.info.nickname..team_str)	
			end
		elseif v == 5 then
			self.see_ship_num = true
		elseif v == 6 then
			self.see_ship_level = true
		elseif v == 7 then
			self.see_ship_break = true
		elseif v == 8 then
			self.see_ship_info = true
		elseif v == 9 then
			rn:getChildByName("btn"):setEnabled(true)
		end
	end
end

function PlanetWarningInfoLayer:onEnterTransitionFinish()
	printInfo("PlanetWarningInplafoLayer:onEnterTransitionFinish()")

	self:resetRes()

	local list = {}
	for i,v in ipairs(self.data_.info.army.army_key_list) do
		table.insert(list, v)
	end
	for i,v in ipairs(self.data_.info.army.req_army_key_list) do
		table.insert(list, v)
	end
	local strData = Tools.encode("PlanetGetReq", {
			army_key_list = list,
			type = 7,
		 })
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 

	local rn = self:getResourceNode()

	if self.data_.info.army.status_machine == 4 then --zhen
		rn:getChildByName("type_icon"):loadTexture("PlanetScene/ui/beigongji1.png")
		rn:getChildByName("type"):setString(CONF:getStringValue("scout assault"))
	elseif self.data_.info.army.status_machine == 10 then
		rn:getChildByName("type_icon"):loadTexture("PlanetScene/ui/beigongji2.png")
		rn:getChildByName("type"):setString(CONF:getStringValue("mass enemy in"))
	else
		if #self.data_.info.army.army_key_list + #self.data_.info.army.req_army_key_list > 0 then
			rn:getChildByName("type_icon"):loadTexture("PlanetScene/ui/beigongji2.png")
			rn:getChildByName("type"):setString(CONF:getStringValue("mass enemy assault"))
		else
			rn:getChildByName("type_icon"):loadTexture("PlanetScene/ui/beigongji3.png")
			rn:getChildByName("type"):setString(CONF:getStringValue("enemy assault"))
		end
	end

	rn:getChildByName("jijie_info"):setString(CONF:getStringValue("arrival time")..":")

	rn:getChildByName("jijie_tiao"):setPositionX(rn:getChildByName("jijie_info"):getPositionX() + rn:getChildByName("jijie_info"):getContentSize().width + 5)
	rn:getChildByName("jijie_back"):setPositionX(rn:getChildByName("jijie_info"):getPositionX() + rn:getChildByName("jijie_info"):getContentSize().width + 5)
	rn:getChildByName("jijie_text"):setPositionX(rn:getChildByName("jijie_info"):getPositionX() + rn:getChildByName("jijie_info"):getContentSize().width + 125)

	rn:getChildByName("close"):addClickEventListener(function ( ... )
		local app = require("app.MyApp"):getInstance()
		self:getApp():removeTopView()
		app:addView2Top("PlanetScene/PlanetWarningLayer")
	end)
	rn:getChildByName("title"):setString(CONF:getStringValue("enemy message"))

	-- if self.data_.info.target_element.type == 1 then
	-- 	rn:getChildByName("icon"):setTexture("PlanetIcon/"..CONF.BUILDING_1.get(self.data_.info.target_element.base_data.info.building_level_list[1]).IMAGE..".png")
	-- elseif self.data_.info.target_element.type == 5 then
	-- 	rn:getChildByName("icon"):setTexture("PlanetIcon/"..CONF.PLANETCITY.get(self.data_.info.target_element.city_data.id).ICON..".png")
	-- end

	-- local des_str = CONF:getStringValue("go")..":"	
	-- if self.data_.info.target_element.type == 1 then
	-- 	des_str = des_str..self.data_.info.target_element.base_data.info.nickname..CONF:getStringValue("city").." ("..self.data_.info.target_element.pos_list[1].x..","..self.data_.info.target_element.pos_list[1].y..")"
	-- elseif self.data_.info.target_element.type == 5 then
	-- 	local conf = CONF.PLANETCITY.get(self.data_.info.target_element.city_data.id)

	-- 	des_str = des_str..CONF:getStringValue(conf.NAME).." ("..self.data_.info.target_element.pos_list[1].x..","..self.data_.info.target_element.pos_list[1].y..")"
	-- elseif self.data_.info.target_element.type == 2 then
	-- 	local conf = CONF.PLANET_RES.get(self.data_.info.target_element.res_data.id)

	-- 	des_str = des_str..CONF:getStringValue(conf.NAME).." ("..self.data_.info.target_element.pos_list[1].x..","..self.data_.info.target_element.pos_list[1].y..")"
	-- end

	rn:getChildByName("head_icon"):loadTexture("HeroImage/"..self.data_.info.my_base.base_data.info.icon_id..".png")
	rn:getChildByName("suo_text"):setString(CONF:getStringValue("upgrade scout message"))
	rn:getChildByName("right_title"):setString(CONF:getStringValue("fleet message"))
	rn:getChildByName("btn"):setEnabled(false)
	rn:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("check dower"))

	if player:getBuildingInfo(CONF.EBuilding.kSpy).level == CONF.BUILDING_11.get(CONF.BUILDING_11.count()).ID then
		rn:getChildByName("suo_text"):setVisible(false)
		rn:getChildByName("icon_suo"):setVisible(false)
	end

	rn:getChildByName("pos"):setString(CONF:getStringValue("unknown"))
	rn:getChildByName("pos"):addClickEventListener(function ( ... )

		if rn:getChildByName("pos"):getString() == CONF:getStringValue("unknown") then
			return
		end

		local scene_name = app:getTopViewName()
		local pos = self.data_.info.my_base.pos_list[1]
		if scene_name == "PlanetScene/PlanetScene" then
			app:removeTopView()

			local event = cc.EventCustom:new("moveToUserRes")
			event.pos = pos
			event.node_id = getNodeIDByGlobalPos(pos)
			cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 
		else
			local move_info = {pos = self.data_.info.my_base.pos_list[1], node_id_list = {getNodeIDByGlobalPos(pos)}}
			app:removeTopView()
			app:pushToRootView("PlanetScene/PlanetScene", {move_info = move_info})


		end
	end)

	local num = 1 + #self.data_.info.army.army_key_list + #self.data_.info.army.req_army_key_list

	rn:getChildByName("people"):setString(CONF:getStringValue("attack people unknown"))	
	
	rn:getChildByName("jijie_text"):setString(CONF:getStringValue("arrival time unknown"))

	rn:getChildByName("no_text"):setString(CONF:getStringValue("no message"))
	if self.data_.info.army.status_machine == 4 then
		rn:getChildByName("no_text"):setVisible(true)	
	end

	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"), cc.size(0,5), cc.size(840,103))
	-- self:resetList()
	self:resetBuildInfo()
	local function update( ... )

		if rn:getChildByName("jijie_text"):getString() == CONF:getStringValue("arrival time unknown") then
			return
		end

		if self.data_.info.army.mass_time - (player:getServerTime() - self.data_.info.army.begin_time) >= 0 then
			local percent = ( self.data_.info.army.mass_time - (player:getServerTime() - self.data_.info.army.begin_time)) / self.data_.info.army.mass_time
			if percent < 0 then
				local app = require("app.MyApp"):getInstance()
				self:getApp():removeTopView()
				app:addView2Top("PlanetScene/PlanetWarningLayer")
			else
				if percent > 100 then
					percent = 100
				end
				rn:getChildByName("jijie_tiao"):setContentSize(cc.size(rn:getChildByName("jijie_tiao"):getTag()*percent, rn:getChildByName("jijie_tiao"):getContentSize().height))
				rn:getChildByName("jijie_text"):setString(CONF:getStringValue("mass in")..":"..formatTime(self.data_.info.army.mass_time - (player:getServerTime() - self.data_.info.army.begin_time)))
			end
			
		else
			local percent = ( self.data_.info.army.line.need_time - (player:getServerTime() - self.data_.info.army.line.begin_time)) / self.data_.info.army.line.need_time
			if percent < 0 then
				local app = require("app.MyApp"):getInstance()
				self:getApp():removeTopView()
				app:addView2Top("PlanetScene/PlanetWarningLayer")
			else

				if percent > 100 then
					percent = 100
				end
				rn:getChildByName("jijie_tiao"):setContentSize(cc.size(rn:getChildByName("jijie_tiao"):getTag()*percent, rn:getChildByName("jijie_tiao"):getContentSize().height))
				if #self.data_.info.army.army_key_list + #self.data_.info.army.req_army_key_list > 0 then
					rn:getChildByName("jijie_text"):setString(CONF:getStringValue("approach in")..":"..formatTime(self.data_.info.army.line.need_time - (player:getServerTime() - self.data_.info.army.line.begin_time)))
				else
					rn:getChildByName("jijie_text"):setString(CONF:getStringValue("approach in")..":"..formatTime(self.data_.info.army.line.need_time - (player:getServerTime() - self.data_.info.army.line.begin_time)))
				end
			end
			
		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update, 1, false)

	local function recvMsg()
		printInfo("PlanetWarningLayer:recvMsg")

		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then

			local proto = Tools.decode("PlanetGetResp",strData)
			printInfo("PlanetWarningInfoLayer PlanetGetResp result :"..proto.result)

			if proto.result < 0 then
				printInfo(" error :"..proto.result)
			else

				if proto.type == 7 then

					if proto.result == 0 then
						self.army_info_list = proto.army_info_list
						self:resetList(proto.army_info_list)
						
					elseif proto.result == 1 then
						self.svd_:clear()
						self.army_info_list = {}
						self:resetList({})
					-- elseif proto.result == 2 then
					-- 	self:getApp():popView()
		        	end
		        end

			end
		end
	
	end

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

end

function PlanetWarningInfoLayer:onExitTransitionStart()

	printInfo("PlanetWarningInfoLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)


end

return PlanetWarningInfoLayer