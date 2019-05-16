
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local path_reach = require('PathReach'):create()

local planetMachine = require("app.views.PlanetScene.Manager.PlanetMachine"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local planetArmyManager = require("app.views.PlanetScene.Manager.PlanetArmyManager"):getInstance()

local MassLayer = class("MassLayer", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

MassLayer.RESOURCE_FILENAME = "WarScene/MassLayer.csb"

MassLayer.RUN_TIMELINE = true

MassLayer.NEED_ADJUST_POSITION = true

MassLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

function MassLayer:onCreate( data )
	self.data_ = data
end

function MassLayer:onEnter()
  
	printInfo("MassLayer:onEnter()")

end

function MassLayer:onExit()
	
	printInfo("MassLayer:onExit()")
end

function MassLayer:resetList( info_list )
	-- message PlanetArmyInfo{
	-- 	repeated PlanetElement my_base = 1;
	-- 	repeated string army_key_list = 2;
	-- 	required PlanetElement target_element = 3;
	-- };
	self.svd_:clear()
	print("resetList", #info_list)

	for i,v in ipairs(info_list) do
		local node = require("app.ExResInterface"):getInstance():FastLoad("WarScene/mass_node.csb")
		node:getChildByName("army_num"):setString(i)
		node:getChildByName("ship_num"):setString("feichhuan"..":"..#v.army.ship_list)
		node:getChildByName("icon"):setTexture("HeroImage/"..v.my_base.base_data.info.icon_id..".png")
		node:getChildByName("name"):setString(v.my_base.base_data.info.nickname)
		node:getChildByName("type"):setVisible(false)

		local ship_pos = cc.p(node:getChildByName("ship_pos"):getPosition())
		for i2,v2 in ipairs(v.army.ship_list) do
			local conf = CONF.AIRSHIP.get(v2.id)

			local ship_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/PlanetShip.csb")
			ship_node:getChildByName("lvNum"):setString(v2.level)
			ship_node:getChildByName("shipType"):setTexture("ShipType/"..v2.type..".png")
			ship_node:getChildByName("RoleIcon/"..conf.ICON_ID..".png")
			ship_node:getChildByName("background"):loadTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")

--			if v2.ship_break and v2.ship_break > 0 then
--				for j=1,6 do
--					ship_node:getChildByName("star_"..j):setVisible(true)
--				end
--			end
            ShowShipStar(ship_node,v2.ship_break,"star_")

			-- ship_node:setPosition(cc.p(ship_pos.x + (i-1)*100, ship_pos.y))
			ship_node:setPosition(cc.p((i2-1)*100, 0))
			node:getChildByName("ship_pos"):addChild(ship_node)
		end

		if v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time) > 0 then
		-- if v.army.status == 1 then
			node:getChildByName("ship_pos"):setVisible(false)
			node:getChildByName("open"):setRotation(-90)
			node:getChildByName("jijie_back"):setVisible(true)
			node:getChildByName("jijie_tiao"):setVisible(true)
			node:getChildByName("jijie_text"):setVisible(true)
			node:getChildByName("btn_speedup"):setVisible(true)

			local percent = v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time) / v.army.line.need_time
			if percent < 0 then
				percent = 0
			end
			node:getChildByName("jijie_tiao"):setContentSize(cc.size(node:getChildByName("jijie_tiao"):getTag()*percent, node:getChildByName("jijie_tiao"):getContentSize().height))
			node:getChildByName("jijie_text"):setString(formatTime( v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))
		end

		node:getChildByName("btn_back"):addClickEventListener(function ( ... )
			local strData = Tools.encode("PlanetRaidReq", {
				type_list = {9},
				element_global_key = self.data_.my_base.global_key,
				army_key = v.army.guid,
			 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
		end)

		node:setName("army_node")
		self.svd_:addElement(node)

	end

	local function func( ... )
		print("peitong",self.data_.my_base.global_key,self.data_.my_base.base_data.info.user_name.."_"..self.data_.army_info.guid)
		self:getApp():addView2Top("NewFormLayer",{from="bigMapAccompany",element_global_key=self.data_.my_base.global_key,type=5,army_key = self.data_.my_base.base_data.info.user_name.."_"..self.data_.army_info.guid})
	end

	local mass_num = CONF.BUILDING_1.get(self.data_.my_base.base_data.info.building_level_list[1]).MASS
	print(mass_num,#info_list)
	local num = mass_num-#info_list
	for i=1,num do
		local node = require("app.ExResInterface"):getInstance():FastLoad("WarScene/mass_no_node.csb")
		node:getChildByName("army_num"):setString(#info_list+i)

		local callback = {node = node:getChildByName("tiao"), func = func}
		self.svd_:addElement(node, {callback = callback})
	end
end

function MassLayer:resetData()

end

function MassLayer:onEnterTransitionFinish()
	printInfo("MassLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()

	animManager:runAnimOnceByCSB(rn, "WarScene/MassLayer.csb",  "intro")

	rn:getChildByName("title"):setString("mass")
	rn:getChildByName("close"):addClickEventListener(function ( ... )
		self:getApp():removeTopView()
	end)

	if self.data_.element_info.type == 1 then
		rn:getChildByName("icon"):setTexture("PlanetIcon/"..CONF.BUILDING_1.get(self.data_.element_info.base_data.info.building_level_list[1]).IMAGE..".png")
	elseif self.data_.element_info.type == 5 then
		rn:getChildByName("icon"):setTexture("PlanetIcon/"..CONF.PLANETCITY.get(self.data_.element_info.city_data.id).ICON..".png")
	end

	local des_str = CONF:getStringValue("go")..":"	
	if self.data_.element_info.type == 1 then
		des_str = des_str..self.data_.element_info.base_data.info.nickname.."jidi".." ("..self.data_.element_info.pos_list[1].x..","..self.data_.element_info.pos_list[1].y..")"
	elseif self.data_.element_info.type == 4 then
		local conf = CONF.PLANETCITY.get(self.data_.element_info.city_data.id)

		des_str = des_str..CONF:getStringValue(conf.NAME).." ("..self.data_.element_info.pos_list[1].x..","..self.data_.element_info.pos_list[1].y..")"
	end

	rn:getChildByName("pos"):setString(des_str)

	rn:getChildByName("people"):setString(#self.data_.army_info.."/"..CONF.BUILDING_1.get(self.data_.my_base.base_data.info.building_level_list[1]).MASS)
	local percent = ( self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time)) / self.data_.army_info.mass_time
	if percent < 0 then
			percent = 0
		end
	rn:getChildByName("jijie_tiao"):setContentSize(cc.size(rn:getChildByName("jijie_tiao"):getTag()*percent, rn:getChildByName("jijie_tiao"):getContentSize().height))
	rn:getChildByName("jijie_text"):setString(formatTime(self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time)))

	rn:getChildByName("btn"):getChildByName("text"):setString("jiesan")

	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName('list'),cc.size(5,10), cc.size(1000,163))

	local send_list = {}

	if Tools.isEmpty(self.data_.army_info.army_key_list) then
		self:resetList({{my_base = self.data_.my_base, target_element = self.data_.element_info, army = self.data_.army_info}})
	else
		local user_name = self.data_.my_base.base_data.info.user_name
		table.insert(send_list, user_name.."_"..self.data_.army_info.guid)

		for i,v in ipairs(self.data_.army_info.army_key_list) do
			table.insert(send_list, v)
		end
	end

	if not Tools.isEmpty(send_list) then
		local strData = Tools.encode("PlanetGetReq", {
				army_key_list = send_list,
				type = 7,
			 })
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
		gl:retainLoading()
	end

	if self.data_.my_base.base_data.info.user_name ~= player:getName() then
		rn:getChildByName("btn"):setVisible(false)
	end

	local function update(  )	
		local percent = ( self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time)) / self.data_.army_info.mass_time
		if percent < 0 then
			percent = 0
		end
		rn:getChildByName("jijie_tiao"):setContentSize(cc.size(rn:getChildByName("jijie_tiao"):getTag()*percent, rn:getChildByName("jijie_tiao"):getContentSize().height))
		rn:getChildByName("jijie_text"):setString(formatTime(self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time)))

		if self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time) < 0 then
			self:getApp():removeTopView()
		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	local function recvMsg()
		print("MassLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then
			local proto = Tools.decode("PlanetGetResp",strData)
			print("PlanetGetResp result",proto.result, proto.type)

			gl:releaseLoading()
			if proto.result == 0 then
				if proto.type == 7 then
					-- self.army_info_list = proto.army_info_list
					self:resetList(proto.army_info_list)
				end
        	end
			
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

end

function MassLayer:onExitTransitionStart()

	printInfo("MassLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return MassLayer	