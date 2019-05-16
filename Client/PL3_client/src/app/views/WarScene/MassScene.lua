
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local path_reach = require('PathReach'):create()

local planetMachine = require("app.views.PlanetScene.Manager.PlanetMachine"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local planetArmyManager = require("app.views.PlanetScene.Manager.PlanetArmyManager"):getInstance()

local MassScene = class("MassScene", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

MassScene.RESOURCE_FILENAME = "WarScene/MassScene.csb"

MassScene.RUN_TIMELINE = true

MassScene.NEED_ADJUST_POSITION = true

MassScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

function MassScene:onCreate( data )
	self.data_ = data
end

function MassScene:onEnter()
  
	printInfo("MassScene:onEnter()")

end

function MassScene:onExit()
	
	printInfo("MassScene:onExit()")
end

function MassScene:resetList( info_list )
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
		node:getChildByName("ship_num"):setString(CONF:getStringValue("dispatch ship")..":"..#v.army.ship_list)
		node:getChildByName("icon"):setTexture("HeroImage/"..v.my_base.base_data.info.icon_id..".png")
		node:getChildByName("name"):setString(v.my_base.base_data.info.nickname)
		
		if v.my_base.base_data.info.user_name ~= Split(self.leader_army_key,"_")[1] then
			node:getChildByName("tiao"):loadTexture("WarScene/ui/qitachendi.png")
		end

		local ship_pos = cc.p(node:getChildByName("ship_pos"):getPosition())
		for i2,v2 in ipairs(v.army.ship_list) do
			local conf = CONF.AIRSHIP.get(v2.id)

			local ship_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/PlanetShip.csb")
			ship_node:getChildByName("lvNum"):setString(v2.level)
			ship_node:getChildByName("shipType"):setTexture("ShipType/"..v2.type..".png")
            ship_node:getChildByName("icon"):setVisible(false)
            ship_node:getChildByName("icon2"):setVisible(true)
			ship_node:getChildByName("icon"):setTexture("RoleIcon/"..conf.ICON_ID..".png")
            ship_node:getChildByName("icon2"):setTexture("ShipImage/"..conf.ICON_ID..".png")
			ship_node:getChildByName("background"):loadTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")

--			if v2.ship_break and v2.ship_break > 0 then
--				for j=1,v2.ship_break do
--					ship_node:getChildByName("star_"..j):setVisible(true)
--				end
--			end
            ShowShipStar(ship_node,v2.ship_break,"star_")

			-- ship_node:setPosition(cc.p(ship_pos.x + (i-1)*100, ship_pos.y))
			ship_node:setPosition(cc.p((i2-1)*100, 0))
			node:getChildByName("ship_pos"):addChild(ship_node)
		end

		if v.army.army_key ~= self.leader_army_key then
			if v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time) > 0 then
			-- if v.army.status == 1 then
				node:getChildByName("ship_pos"):setVisible(false)
				node:getChildByName("open"):setRotation(-90)
				node:getChildByName("jijie_back"):setVisible(true)
				node:getChildByName("jijie_tiao"):setVisible(true)
				node:getChildByName("jijie_text"):setVisible(true)
				node:getChildByName("btn_speedup"):setVisible(true)
				node:getChildByName("btn_fanhui"):setVisible(true)

				node:getChildByName("btn_speedup"):addClickEventListener(function ( ... )
					self:getApp():addView2Top("PlanetScene/PlanetAddSpeedLayer",{army_info = v.army})
				end)

				local percent = (v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time))  / v.army.line.need_time
				if percent < 0 then
					percent = 0
				end
				if percent > 100 then
					percent = 100
				end

				node:getChildByName("jijie_tiao"):setContentSize(cc.size(node:getChildByName("jijie_tiao"):getTag()*percent, node:getChildByName("jijie_tiao"):getContentSize().height))
				node:getChildByName("jijie_text"):setString(formatTime( v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))

				node:getChildByName("btn_back"):setVisible(false)
			end
		end

		node:getChildByName("btn_back"):setVisible(false)
		if v.my_base.base_data.info.user_name == Split(self.leader_army_key,"_")[1] then
			node:getChildByName("type"):setString(CONF:getStringValue("sponsor"))
		else
			if v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time) > 0 then
				node:getChildByName("type"):setString(CONF:getStringValue("approach in"))
			else
				node:getChildByName("type"):setString(CONF:getStringValue("mass in"))
			end
		end

		node:getChildByName("btn_back"):getChildByName("text"):setString(CONF:getStringValue("huicheng"))
		node:getChildByName("btn_back"):addClickEventListener(function ( ... )

			if self.data_.my_base.base_data.info.user_name == Split(self.leader_army_key,"_")[1] then
				local strData = Tools.encode("PlanetRaidReq", {
					type_list = {9},
					element_global_key = self.data_.my_base.global_key,
					army_key =  v.army.army_key,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
				gl:retainLoading()
			else

				local function func( ... )
					if player:getItemNumByID(17003) <= 0 then
						tips:tips(CONF:getStringValue("item not enought"))
						return
					end

					self.ride_back_type = 2
					local strData = Tools.encode("PlanetRideBackReq", {
						army_guid = {v.army.guid},
						type = 2,
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData) 
					gl:retainLoading()
				end

				local node = require("util.TipsNode"):createWithUseNode(CONF:getStringValue("ship_base"), 17003, 1, func)
				self:addChild(node)
				tipsAction(node)

			end
		end)

		node:getChildByName("btn_fanhui"):addClickEventListener(function ( ... )

			if v.my_base.base_data.info.user_name == Split(self.leader_army_key,"_")[1] then
				local strData = Tools.encode("PlanetRaidReq", {
					type_list = {9},
					element_global_key = self.data_.my_base.global_key,
					army_key = v.army.army_key,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
				gl:retainLoading()
			else
				if player:getItemNumByID(17003) > 0 then
					self.ride_back_type = 2
					local strData = Tools.encode("PlanetRideBackReq", {
						army_guid = {v.army.guid},
						type = 2,
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData) 
					gl:retainLoading()
				else
					tips:tips(CONF:getStringValue("item not enought"))
				end			
			end
		end)

		node:setName("army_node_"..i)
		self.svd_:addElement(node)

	end

	local function func( ... )

		if self.army_info_list then
			for i,v in ipairs(self.army_info_list) do
				if v.my_base.base_data.info.user_name == player:getName() then
					tips:tips(CONF:getStringValue("Has participated mass"))
					return
				end
			end
		end

		if self.data_.element_info.base_data.info.building_level_list[1] == 0 then
			self.data_.element_info.base_data.info.building_level_list[1] = 1 
		end

		if #self.army_info_list >= CONF.BUILDING_1.get(self.data_.element_info.base_data.info.building_level_list[1]).MASS+1 then
			tips:tips(CONF:getStringValue("mass upper"))
		else
			if self:getLeaderArmyType() == 8 then
				self:getApp():addView2Top("NewFormLayer",{from="bigMapMass",element_global_key=self.data_.my_base.global_key,type=5,army_key = self.data_.my_base.base_data.info.user_name.."_"..self.data_.army_info.guid})
			else
				tips:tips(CONF:getStringValue("mass end"))
			end
		end

		-- self:getApp():addView2Top("NewFormLayer",{from="bigMapMass",element_global_key=self.data_.my_base.global_key,type=5,army_key = self.data_.my_base.base_data.info.user_name.."_"..self.data_.army_info.guid})
	end

	local mass_num = CONF.BUILDING_1.get(self.data_.my_base.base_data.info.building_level_list[1]).MASS+1
	local num = mass_num-#info_list
	for i=1,num do
		local node = require("app.ExResInterface"):getInstance():FastLoad("WarScene/mass_no_node.csb")
		node:getChildByName("army_num"):setString(#info_list+i)
		node:getChildByName("text"):setString(CONF:getStringValue("dispatch fleet"))
		node:getChildByName("tiao"):loadTexture("WarScene/ui/qitachendi.png")

		local callback = {node = node:getChildByName("tiao"), func = func}
		self.svd_:addElement(node, {callback = callback})
	end
end

function MassScene:resetData( leader_info )

	local send_list = {}
	if Tools.isEmpty(leader_info.army.army_key_list) and Tools.isEmpty(leader_info.army.req_army_key_list) then
		self:resetList({leader_info})
		self.army_info_list = leader_info
	else
		local user_name = leader_info.my_base.base_data.info.user_name
		table.insert(send_list, user_name.."_"..leader_info.army.guid)

		for i,v in ipairs(leader_info.army.army_key_list) do
			print("leader_info.army_info.army_key_list",i,v)
			table.insert(send_list, v)
		end

		for i,v in ipairs(leader_info.army.req_army_key_list) do
			print("leader_info.army_info.req_army_key_list",i,v)
			table.insert(send_list, v)
		end
	end

	if not Tools.isEmpty(send_list) then
		self.isUpdate = false
		local strData = Tools.encode("PlanetGetReq", {
				army_key_list = send_list,
				type = 7,
			 })
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
		-- gl:retainLoading()
	end
end

function MassScene:getLeaderArmyType( ... )
	return self.data_.army_info.status
end

function MassScene:onEnterTransitionFinish()
	printInfo("MassScene:onEnterTransitionFinish()")

	self.ride_back_type = 0
	self.can_send = true
	self.time = 0

	local rn = self:getResourceNode()

	animManager:runAnimOnceByCSB(rn, "WarScene/MassScene.csb",  "intro")

	rn:getChildByName("title"):setString(CONF:getStringValue("mass"))
	rn:getChildByName("close"):addClickEventListener(function ( ... )
		self:getApp():popView()
	end)

	rn:getChildByName("btn_speedup"):addClickEventListener(function ( ... )
		self:getApp():addView2Top("PlanetScene/PlanetAddSpeedLayer",{army_info = self.data_.army_info})
	end)

	if self.data_.element_info.type == 1 then
		rn:getChildByName("icon"):setTexture("PlanetIcon/"..CONF.BUILDING_1.get(self.data_.element_info.base_data.info.building_level_list[1]).IMAGE..".png")
	elseif self.data_.element_info.type == 5 then
		rn:getChildByName("icon"):setTexture("PlanetIcon/"..CONF.PLANETCITY.get(self.data_.element_info.city_data.id).ICON..".png")
	end

	local des_str = CONF:getStringValue("go")..":"	
	if self.data_.element_info.type == 1 then
		des_str = des_str..self.data_.element_info.base_data.info.nickname..CONF:getStringValue("city").." ("..self.data_.element_info.pos_list[1].x..","..self.data_.element_info.pos_list[1].y..")"
	elseif self.data_.element_info.type == 5 then
		local conf = CONF.PLANETCITY.get(self.data_.element_info.city_data.id)

		des_str = des_str..CONF:getStringValue(conf.NAME).." ("..self.data_.element_info.pos_list[1].x..","..self.data_.element_info.pos_list[1].y..")"
	end

	rn:getChildByName("pos"):setString(des_str)

	local num = 1 + #self.data_.army_info.army_key_list + #self.data_.army_info.req_army_key_list
	rn:getChildByName("people"):setString(CONF:getStringValue("mass member")..":"..num.."/"..CONF.BUILDING_1.get(self.data_.my_base.base_data.info.building_level_list[1]).MASS+1)

	if self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time) >= 0 then
		local percent = ( self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time)) / self.data_.army_info.mass_time
		if percent < 0 then
			percent = 0
		end
		if percent > 100 then
			percent = 100
		end
		rn:getChildByName("jijie_tiao"):setContentSize(cc.size(rn:getChildByName("jijie_tiao"):getTag()*percent, rn:getChildByName("jijie_tiao"):getContentSize().height))
		rn:getChildByName("jijie_text"):setString(CONF:getStringValue("mass count down")..":"..formatTime(self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time)))
	else
		local percent = ( self.data_.army_info.line.need_time - (player:getServerTime() - self.data_.army_info.line.begin_time)) / self.data_.army_info.line.need_time
		if percent < 0 then
			percent = 0
		end
		if percent > 100 then
			percent = 100
		end
		rn:getChildByName("jijie_tiao"):setContentSize(cc.size(rn:getChildByName("jijie_tiao"):getTag()*percent, rn:getChildByName("jijie_tiao"):getContentSize().height))
		rn:getChildByName("jijie_text"):setString(CONF:getStringValue("go mass")..":"..formatTime(self.data_.army_info.line.need_time - (player:getServerTime() - self.data_.army_info.line.begin_time)))
	end

	rn:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("dissolve mass"))

	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName('list'),cc.size(5,10), cc.size(1000,163))


	self.leader_army_key = self.data_.my_base.base_data.info.user_name.."_"..self.data_.army_info.guid
	self.isUpdate = false
	local send_list = {}

	if Tools.isEmpty(self.data_.army_info.army_key_list) and Tools.isEmpty(self.data_.army_info.req_army_key_list) then
		self:resetList({{my_base = self.data_.my_base, target_element = self.data_.element_info, army = self.data_.army_info}})
		self.army_info_list = {{my_base = self.data_.my_base, target_element = self.data_.element_info, army = self.data_.army_info}}
	else
		local user_name = self.data_.my_base.base_data.info.user_name
		table.insert(send_list, user_name.."_"..self.data_.army_info.guid)

		for i,v in ipairs(self.data_.army_info.army_key_list) do
			print("self.data_.army_info.army_key_list",i,v)
			table.insert(send_list, v)
		end

		for i,v in ipairs(self.data_.army_info.req_army_key_list) do
			print("self.data_.army_info.req_army_key_list",i,v)
			table.insert(send_list, v)
		end
	end

	if not Tools.isEmpty(send_list) then
		for i,v in ipairs(send_list) do
			print("send_list",i,v)
		end

		local strData = Tools.encode("PlanetGetReq", {
				army_key_list = send_list,
				type = 7,
			 })
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
		-- gl:retainLoading()
	end

	for i,v in ipairs(self.data_.army_info.army_key_list) do
		if Split(v, "_")[1] == player:getName() then
			rn:getChildByName("btn"):setVisible(false)
			break
		end
	end

	for i,v in ipairs(self.data_.army_info.req_army_key_list) do
		if Split(v, "_")[1] == player:getName() then
			rn:getChildByName("btn"):setVisible(false)
			break
		end
	end

	if self.data_.my_base.base_data.info.user_name ~= player:getName() then
		-- rn:getChildByName("btn"):setVisible(false)

		if self.army_info_list then
			local has = false
			for i,v in ipairs(self.army_info_list) do
				if v.my_base.base_data.info.user_name == player:getName() then
					has = true
					break
				end
			end

			if  player:getName() ~= Split(self.leader_army_key, "_")[1] then

				if has then
					rn:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("already mass"))
				else
					rn:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("participate mass"))
				end
			end
		end

		rn:getChildByName("btn"):addClickEventListener(function ( ... )

			if self.army_info_list == nil then
				return
			end

				if rn:getChildByName("btn"):getChildByName("text"):getString() == CONF:getStringValue("already mass") then
					tips:tips(CONF:getStringValue("already mass"))
				else
					if self.data_.my_base.base_data.info.building_level_list[1] == 0 then
						self.data_.my_base.base_data.info.building_level_list[1] = 1 
					end
					print(self.data_.my_base.base_data.info.building_level_list[1])

					if #self.army_info_list >= CONF.BUILDING_1.get(self.data_.my_base.base_data.info.building_level_list[1]).MASS+1 then
						tips:tips(CONF:getStringValue("mass upper"))
					else
						-- print("self:getLeaderArmyType()",self:getLeaderArmyType())

						if self:getLeaderArmyType() == 8 then
							self:getApp():addView2Top("NewFormLayer",{from="bigMapMass",element_global_key=self.data_.my_base.global_key,type=5,army_key = self.data_.my_base.base_data.info.user_name.."_"..self.data_.army_info.guid})
						else
							tips:tips(CONF:getStringValue("mass end"))
						end
					end
				end
			end)
	else
		rn:getChildByName("btn"):addClickEventListener(function ( ... )
            local function click()
                self.ride_back_type = 2
			    local strData = Tools.encode("PlanetRideBackReq", {
				    army_guid = {self.data_.army_info.guid},
				    type = 2,
			     })
			    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData) 
			    gl:retainLoading()
            end

            local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(CONF:getStringValue("isjiesan_mass"), click)
		end)
	end

	local function update(  )	

		self.time = self.time + 1
		if self.time > 3 then
			self.can_send = true
			self.time = 0
		end

		for i,v in ipairs(self.data_.army_info.army_key_list) do
			if Split(v, "_")[1] == player:getName() then
				rn:getChildByName("btn"):setVisible(false)
				break
			end
		end

		for i,v in ipairs(self.data_.army_info.req_army_key_list) do
			if Split(v, "_")[1] == player:getName() then
				rn:getChildByName("btn"):setVisible(false)
				break
			end
		end

		if self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time) >= 0 then
			rn:getChildByName("btn_speedup"):setVisible(false)

			local percent = ( self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time)) / self.data_.army_info.mass_time
			if percent < 0 then
				percent = 0
			end
			if percent > 100 then
				percent = 100
			end
			rn:getChildByName("jijie_tiao"):setContentSize(cc.size(rn:getChildByName("jijie_tiao"):getTag()*percent, rn:getChildByName("jijie_tiao"):getContentSize().height))
			rn:getChildByName("jijie_text"):setString(CONF:getStringValue("mass count down")..":"..formatTime(self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time)))
		else
			print("shijian",self.data_.army_info.line.need_time,self.data_.army_info.line.begin_time)
			if self.data_.army_info.line.need_time == 0 or self.data_.army_info.line.begin_time == 0 then
				self.isUpdate = true

				local army_key_list = {}
				for i,v in ipairs(self.army_info_list) do
					table.insert(army_key_list, v.army.army_key)
				end

				local strData = Tools.encode("PlanetGetReq", {
					army_key_list = {self.leader_army_key},
					type = 7,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
			else

				if self.data_.army_info.line.need_time - (player:getServerTime() - self.data_.army_info.line.begin_time) > 0 then
					rn:getChildByName("btn_speedup"):setVisible(true)

					local percent = ( self.data_.army_info.line.need_time - (player:getServerTime() - self.data_.army_info.line.begin_time)) / self.data_.army_info.line.need_time
					if percent < 0 then
						percent = 0
					end
					if percent > 100 then
						percent = 100		
					end
					rn:getChildByName("jijie_tiao"):setContentSize(cc.size(rn:getChildByName("jijie_tiao"):getTag()*percent, rn:getChildByName("jijie_tiao"):getContentSize().height))
					rn:getChildByName("jijie_text"):setString(CONF:getStringValue("go mass")..":"..formatTime(self.data_.army_info.line.need_time - (player:getServerTime() - self.data_.army_info.line.begin_time)))
				else
					self:getApp():popView()
				end
			end
		end

		if self.data_.army_info.mass_time - (player:getServerTime() - self.data_.army_info.begin_time) < 0 then
			-- self:getApp():popView()
			self.isUpdate = true

			local army_key_list = {}
			for i,v in ipairs(self.army_info_list) do
				table.insert(army_key_list, v.army.army_key)
			end

			local strData = Tools.encode("PlanetGetReq", {
				army_key_list = {self.leader_army_key},
				type = 7,
			 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
		end

		-- print("self:getLeaderArmyType()",self:getLeaderArmyType())
		-- if self:getLeaderArmyType() ~= 8 then
		-- 	self:getApp():popView()
		-- end

		if self.army_info_list then
			local num = 1 + #self.data_.army_info.army_key_list + #self.data_.army_info.req_army_key_list
			rn:getChildByName("people"):setString(CONF:getStringValue("mass member")..":"..num.."/"..CONF.BUILDING_1.get(self.data_.my_base.base_data.info.building_level_list[1]).MASS+1)
		end

		if self.army_info_list then
			for i,v in ipairs(self.army_info_list) do

				if  player:getName() ~= Split(self.leader_army_key, "_")[1] then
					if v.my_base.base_data.info.user_name == player:getName() then
						rn:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("already mass"))
					else
						rn:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("participate mass"))
					end
				end

				if v.army.status == 1 then
					if v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time) > 0 then
						local node = self.svd_:getScrollView():getChildByName("army_node_"..i)
						local percent = (v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)) / v.army.line.need_time
						if percent < 0 then
							percent = 0
						end

						if percent > 100 then
							percent = 100
						end
						node:getChildByName("jijie_tiao"):setContentSize(cc.size(node:getChildByName("jijie_tiao"):getTag()*percent, node:getChildByName("jijie_tiao"):getContentSize().height))
						node:getChildByName("jijie_text"):setString(formatTime( v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))
					else
						if self.can_send then
							self.isUpdate = true
							local strData = Tools.encode("PlanetGetReq", {
								army_key_list = {self.leader_army_key},
								type = 7,
							 })
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
							-- gl:retainLoading()

							self.can_send =false
						end
					end
				end

				if v.my_base.base_data.info.user_name == player:getName() then
					if v.army.status == 3 then
						self.ride_back_type = 1
						local strData = Tools.encode("PlanetRideBackReq", {
							army_guid = {self.data_.army_info.guid},
							type = 1,
						 })
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData) 
						gl:retainLoading()
					end
				end
			end
		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	local function recvMsg()
		print("MassScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then
			local proto = Tools.decode("PlanetGetResp",strData)
			print("PlanetGetResp result",proto.result, proto.type)

			print("isUpdate",self.isUpdate)
			-- gl:releaseLoading()
			if proto.type == 7 then

				if proto.result == 0 then

					if not self.isUpdate then
						self:resetList(proto.army_info_list)
						self.army_info_list = proto.army_info_list

					else

						self:resetData(proto.army_info_list[1])
						self.data_.army_info = proto.army_info_list[1].army
						self.data_.my_base = proto.army_info_list[1].my_base
						self.data_.element_info = proto.army_info_list[1].target_element
					end		

				else
					self:getApp():popView()

	        	end

	        end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("PlanetRaidResp",strData)
			print('PlanetRaidResp..',proto.result)
			if proto.result == 'OK' then
				self.isUpdate = true

				local strData = Tools.encode("PlanetGetReq", {
					army_key_list = {self.leader_army_key},
					type = 7,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
				-- gl:retainLoading()

				-- self::pushToRootView("PlanetScene/PlanetScene")
				
			end

		 elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("PlanetRideBackResp",strData)
			print('PlanetRideBackResp..',proto.result)
			if proto.result == 0 then

				if self.ride_back_type == 1 then
					self:getApp():popView()
				elseif self.ride_back_type == 2 then
					local strData = Tools.encode("PlanetGetReq", {
						army_key_list = {self.leader_army_key},
						type = 7,
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
					-- gl:retainLoading()
				end
				
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_USER_UPDATE") then
			print("gengxinxxxxxxxxxxxxx")

			self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
				self.isUpdate = true

				local strData = Tools.encode("PlanetGetReq", {
					army_key_list = {self.leader_army_key},
					type = 7,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
			end)))

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_SPEED_UP_RESP") then

			local proto = Tools.decode("PlanetSpeedUpResp",strData)
			print("PlanetSpeedUpResp", proto.result)

			if proto.result == 0 then

				for i,v in ipairs(self.army_info_list) do
					if v.army.army_key == proto.army.army_key then
						v.army = proto.army 
						break
					end
				end

				if proto.army.army_key == self.leader_army_key then
					self.data_.army_info = proto.army 
				end

			elseif proto.result == 1 then
				tips:tips(CONF:getStringValue("item not enought"))
        	end
			
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.groupListener_ = cc.EventListenerCustom:create("group_main", function (event)

		print("group_maingroup_maingroup_main")

		if event.group_main.groupid == "" or event.group_main == nil then
  			return
  		end

  		self.isUpdate = true
  		local strData = Tools.encode("PlanetGetReq", {
			army_key_list = {self.leader_army_key},
			type = 7,
		 })
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
 		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.groupListener_, FixedPriority.kNormal)

end

function MassScene:onExitTransitionStart()

	printInfo("MassScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return MassScene	