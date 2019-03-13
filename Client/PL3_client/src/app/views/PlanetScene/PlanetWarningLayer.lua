
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local planetMachine = require("app.views.PlanetScene.Manager.PlanetMachine"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local planetArmyManager = require("app.views.PlanetScene.Manager.PlanetArmyManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local PlanetWarningLayer = class("PlanetWarningLayer", cc.load("mvc").ViewBase)

PlanetWarningLayer.RESOURCE_FILENAME = "PlanetScene/PlanetWarningLayer.csb"

PlanetWarningLayer.RUN_TIMELINE = true

PlanetWarningLayer.NEED_ADJUST_POSITION = true

PlanetWarningLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

function PlanetWarningLayer:onCreate( data )
	self.data_ = data
end

function PlanetWarningLayer:onEnter()
  
	printInfo("PlanetWarningLayer:onEnter()")

end

function PlanetWarningLayer:onExit()
	
	printInfo("PlanetWarningLayer:onExit()")
end

function PlanetWarningLayer:resetList( info_list )

	if info_list == nil then
		return
	end

	self.svd_:clear()
-- 	message PlanetArmyInfo{
-- 	required PlanetElement my_base = 1;
-- 	required PlanetArmy army = 2;
-- 	required PlanetElement target_element = 3;
-- };


	print("#info_list",#info_list)

	local function sort( a,b )

		if a.army.mass_time > 0 and b.army.mass_time > 0 then
			return (a.army.mass_time - (player:getServerTime() - a.army.begin_time)) >= (b.army.mass_time - (player:getServerTime() - b.army.begin_time))
		else
			if a.army.mass_time == 0 and b.army.mass_time > 0 then
				return true
			elseif a.army.mass_time > 0 and b.army.mass_time == 0 then
				return false
			else
				return ( a.army.line.need_time - (player:getServerTime() - a.army.line.begin_time)) >= ( b.army.line.need_time - (player:getServerTime() - b.army.line.begin_time))
			end

		end


	end

	table.sort(info_list, sort)

	for i,v in ipairs(info_list) do
		local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/WarningNode.csb")

		-- if v.my_base.base_data.info.group_nickname ~= nil and v.my_base.base_data.info.group_nickname ~= "" then
		-- 	node:getChildByName("name"):setString("["..v.my_base.base_data.info.group_nickname.."]"..v.my_base.base_data.info.nickname)
		-- else
		-- 	node:getChildByName("name"):setString(v.my_base.base_data.info.nickname)
		-- end

		if i%2 == 1 then
			node:getChildByName("bg"):setVisible(false)
		end

		if v.army.status_machine == 4 then --zhen
			node:getChildByName("icon"):setTexture("PlanetScene/ui/beigongji1.png")
			node:getChildByName("name"):setString(CONF:getStringValue("scout assault"))
		elseif v.army.status_machine == 10 then
			node:getChildByName("icon"):setTexture("PlanetScene/ui/beigongji2.png")
			node:getChildByName("name"):setString(CONF:getStringValue("mass enemy in"))
		else
			if #v.army.army_key_list + #v.army.req_army_key_list > 0 then
				node:getChildByName("icon"):setTexture("PlanetScene/ui/beigongji2.png")
				node:getChildByName("name"):setString(CONF:getStringValue("mass enemy assault"))
			else
				node:getChildByName("icon"):setTexture("PlanetScene/ui/beigongji3.png")
				node:getChildByName("name"):setString(CONF:getStringValue("enemy assault"))
			end
		end

		if self.can_see_time then
			if v.army.mass_time - (player:getServerTime() - v.army.begin_time) >= 0 then
				local percent = ( v.army.mass_time - (player:getServerTime() - v.army.begin_time)) / v.army.mass_time
				if percent < 0 then
					percent = 0
				end
				if percent > 100 then
					percent = 100
				end
				node:getChildByName("jijie_tiao"):setContentSize(cc.size(node:getChildByName("jijie_tiao"):getTag()*percent, node:getChildByName("jijie_tiao"):getContentSize().height))
				node:getChildByName("jijie_text"):setString(CONF:getStringValue("mass in")..":"..formatTime(v.army.mass_time - (player:getServerTime() - v.army.begin_time)))
			else
				local percent = ( v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)) / v.army.line.need_time
				if percent < 0 then
					percent = 0
				end

				if percent > 100 then
					percent = 100
				end
				-- node:getChildByName("to_jijie"):setVisible(false)
				node:getChildByName("jijie_tiao"):setContentSize(cc.size(node:getChildByName("jijie_tiao"):getTag()*percent, node:getChildByName("jijie_tiao"):getContentSize().height))

				if #v.army.army_key_list + #v.army.req_army_key_list > 0 then
					node:getChildByName("jijie_text"):setString(CONF:getStringValue("approach in")..":"..formatTime(v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))
				else
					node:getChildByName("jijie_text"):setString(CONF:getStringValue("approach in")..":"..formatTime(v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))
				end
			end
		else
			node:getChildByName("jijie_text"):setString(CONF:getStringValue("arrival time unknown"))
		end

		node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("Check"))
		node:getChildByName("btn"):addClickEventListener(function ( ... )
			local app = require("app.MyApp"):getInstance()
			self:getApp():removeTopView()
			app:addView2Top("PlanetScene/PlanetWarningInfoLayer", {info = v})
		end)

		node:setName("army_node_"..i)
		self.svd_:addElement(node)

	end
end

function PlanetWarningLayer:resetBuildInfo()
	local info = player:getBuildingInfo(CONF.EBuilding.kSpy)
	local conf = CONF.BUILDING_11.get(info.level)
	local rn = self:getResourceNode()

	for i,v in ipairs(conf.BE_ATTACK) do

		if v == 3 then
			self.can_see_time = true
		end

	end
end

function PlanetWarningLayer:sendMessage( ... )
	local rn = self:getResourceNode()
	local scene_name = app:getTopViewName()

	if scene_name == "PlanetScene/PlanetScene" then
		if #planetManager:getPlanetUser().attack_me_list == 0 then
			rn:getChildByName("no_text"):setVisible(true)
		else
			rn:getChildByName("no_text"):setVisible(false)
			local strData = Tools.encode("PlanetGetReq", {
					army_key_list = planetManager:getPlanetUser().attack_me_list,
					type = 7,
				 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 

		end
	else
		if #player:getPlayerPlanetUser().attack_me_list == 0 then
			rn:getChildByName("no_text"):setVisible(true)
		else
			rn:getChildByName("no_text"):setVisible(false)
			local strData = Tools.encode("PlanetGetReq", {
					army_key_list = player:getPlayerPlanetUser().attack_me_list,
					type = 7,
				 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 

		end
	end
end

function PlanetWarningLayer:onEnterTransitionFinish()
	printInfo("PlanetWarningLayer:onEnterTransitionFinish()")

	self:resetBuildInfo()

	local rn = self:getResourceNode()
	rn:getChildByName("close"):addClickEventListener(function ( ... )
		self:getApp():removeTopView()
	end)

	rn:getChildByName("no_text"):setString(CONF:getStringValue("no enemy message"))
	rn:getChildByName("title"):setString(CONF:getStringValue("BuildingName_"..CONF.EBuilding.kSpy).." Lv."..player:getBuildingInfo(CONF.EBuilding.kSpy).level)

	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"), cc.size(5,5), cc.size(485,98))

	self:sendMessage()

	local function update( ... )

		if not self.can_see_time then
			return
		end

		if self.army_info_list then
			local scene_name = app:getTopViewName()
			if scene_name == "PlanetScene/PlanetScene" then
				if #planetManager:getPlanetUser().attack_me_list == #self.army_info_list then
				else
					if #planetManager:getPlanetUser().attack_me_list == 0 then
						rn:getChildByName("no_text"):setVisible(true)
						self.svd_:clear()
						self.army_info_list = nil
					else
						rn:getChildByName("no_text"):setVisible(false)
						local strData = Tools.encode("PlanetGetReq", {
								army_key_list = planetManager:getPlanetUser().attack_me_list,
								type = 7,
							 })
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 

					end

				end
			else

				if #player:getPlayerPlanetUser().attack_me_list == #self.army_info_list then
				else
					if #player:getPlayerPlanetUser().attack_me_list == 0 then
						rn:getChildByName("no_text"):setVisible(true)
						self.svd_:clear()
						self.army_info_list = nil
					else
						rn:getChildByName("no_text"):setVisible(false)
						local strData = Tools.encode("PlanetGetReq", {
								army_key_list = player:getPlayerPlanetUser().attack_me_list,
								type = 7,
							 })
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 

					end

				end
			end

		end


		if self.army_info_list then
			for i,v in ipairs(self.army_info_list) do
				if v.army.mass_time - (player:getServerTime() - v.army.begin_time) >= 0 then
					local percent = ( v.army.mass_time - (player:getServerTime() - v.army.begin_time)) / v.army.mass_time
					if percent < 0 then
						percent = 0
					end
					if percent > 100 then
						percent = 100
					end
					self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_tiao"):setContentSize(cc.size(self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_tiao"):getTag()*percent, self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_tiao"):getContentSize().height))
					self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_text"):setString(CONF:getStringValue("mass in")..":"..formatTime(v.army.mass_time - (player:getServerTime() - v.army.begin_time)))
				else
					if v.army.line.begin_time == nil or v.army.line.begin_time == 0 or v.army.line.need_time == 0 then
						-- updateData(player:getPlayerGroupMain())

						-- gl:retainLoading()
					else
						if v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time) >= 0 then
							local percent = ( v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)) / v.army.line.need_time
							if percent < 0 then
								percent = 0
							end 

							if percent > 100 then
								percent = 100
							end
							-- self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("to_jijie"):setVisible(false)
							self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_tiao"):setContentSize(cc.size(self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_tiao"):getTag()*percent, self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_tiao"):getContentSize().height))
							if #v.army.army_key_list + #v.army.req_army_key_list > 0 then
								self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_text"):setString(CONF:getStringValue("approach in")..":"..formatTime(v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))
							else
								self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_text"):setString(CONF:getStringValue("approach in")..":"..formatTime(v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))
							end
						else

							local list
							if planetManager:getPlanetUser() then
								list = planetManager:getPlanetUser().attack_me_list
							else
								list = player:getPlayerPlanetUser().attack_me_list
							end
							local strData = Tools.encode("PlanetGetReq", {
									army_key_list = list,
									type = 7,
								 })
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
						end
					end
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
			printInfo("PlanetWarningLayer PlanetGetResp result :"..proto.result)

			if proto.result ~= 0 then
				printInfo(" error :"..proto.result)
			else

				if proto.type == 7 then

					if proto.result == 0 then
						self.army_info_list = proto.army_info_list
						self:resetList(proto.army_info_list)
						
					elseif proto.result == 1 then
						self.svd_:clear()
						self.army_info_list = nil
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

	self.planetUserUpdateListener_ = cc.EventListenerCustom:create("planetUserUpdate", function (event)
		self:sendMessage()

		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.planetUserUpdateListener_, FixedPriority.kNormal)

end

function PlanetWarningLayer:onExitTransitionStart()

	printInfo("PlanetWarningLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.planetUserUpdateListener_)

end

return PlanetWarningLayer