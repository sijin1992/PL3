
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local path_reach = require('PathReach'):create()

local planetMachine = require("app.views.PlanetScene.Manager.PlanetMachine"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local planetArmyManager = require("app.views.PlanetScene.Manager.PlanetArmyManager"):getInstance()

local WarScene = class("WarScene", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

WarScene.RESOURCE_FILENAME = "WarScene/WarScene.csb"

WarScene.RUN_TIMELINE = true

WarScene.NEED_ADJUST_POSITION = true

WarScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

local WarType = {
	ATK = 1,
	DEF = 2,
}


function WarScene:onCreate( data )
	self.data_ = data
end

function WarScene:onEnter()
  
	printInfo("WarScene:onEnter()")

end

function WarScene:onExit()
	
	printInfo("WarScene:onExit()")
end

function WarScene:resetList( info_list )
	-- message PlanetArmyInfo{
	-- 	repeated PlanetElement my_base = 1;
	-- 	repeated string army_key_list = 2;
	-- 	required PlanetElement target_element = 3;
	-- };

	if self.type == WarType.ATK then
		if #player:getPlayerGroupMain().enlist_list == 0 then
			self.army_info_list = nil
			return
		end

	elseif self.type == WarType.DEF then
		if #player:getPlayerGroupMain().attack_our_list == 0 then
			self.army_info_list = nil
			return
		end
	end

	local function addListener( node, func)

		local isTouchMe = false

		local function onTouchBegan(touch, event)

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
		local eventDispatcher = self.svd_:getScrollView():getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
	end


	self.svd_:clear()

	print("#info_list",#info_list)
	for i,v in ipairs(info_list) do
		local node = require("app.ExResInterface"):getInstance():FastLoad("WarScene/war_node.csb")

		node:getChildByName("atk_icon"):setTexture("HeroImage/"..v.my_base.base_data.info.icon_id..".png")

		if self.type == WarType.ATK then
			node:getChildByName("tiao"):loadTexture("WarScene/ui/qitachendi.png")
		elseif self.type == WarType.DEF then
			node:getChildByName("tiao"):loadTexture("WarScene/ui/direnchengdi.png")
		end

		local duiwu_str = ""
		if v.army.mass_time - (player:getServerTime() - v.army.begin_time) >= 0 and #v.army.army_key_list + #v.army.req_army_key_list > 0 then
			local duiwu_strs = Split(CONF:getStringValue("text_1"), "#")
			for i2,v2 in ipairs(duiwu_strs) do
				duiwu_str = duiwu_str..v2

				if i2 == 1 then
					duiwu_str = duiwu_str..v.my_base.base_data.info.nickname
				end
			end
		else
			duiwu_str = duiwu_str..v.my_base.base_data.info.nickname
		end
		node:getChildByName("atk_name"):setString(duiwu_str)
		node:getChildByName("atk_pos"):setString(CONF:getStringValue("coord")..":".."("..v.my_base.pos_list[1].x..","..v.my_base.pos_list[1].y..")")

		local num = 1
		if not Tools.isEmpty(v.army.army_key_list) then
			num = num + #v.army.army_key_list
		end
		if not Tools.isEmpty(v.army.req_army_key_list) then
			num = num + #v.army.req_army_key_list
		end
		node:getChildByName("atk_people"):setString(CONF:getStringValue("mass member")..":"..num.."/"..CONF.BUILDING_1.get(v.my_base.base_data.info.building_level_list[1]).MASS+1)


		if v.target_element then
			if v.target_element.type == 1 then
				node:getChildByName("def_icon"):loadTexture("HeroImage/"..v.target_element.base_data.info.icon_id..".png")

				if v.target_element.base_data.info.group_nickname ~= "" and v.target_element.base_data.info.group_nickname ~= nil then
					node:getChildByName("def_name"):setString("["..v.target_element.base_data.info.group_nickname.."]"..v.target_element.base_data.info.nickname)
				else
					node:getChildByName("def_name"):setString(v.target_element.base_data.info.nickname)
				end
			elseif v.target_element.type == 5 or v.target_element.type == 12 then
				local conf = CONF.PLANETCITY.get(v.target_element.city_data.id)
				node:getChildByName("def_icon"):loadTexture("PlanetIcon/"..conf.ICON..".png")
				node:getChildByName("def_name"):setString(CONF:getStringValue(conf.NAME))
			end
			node:getChildByName("def_pos"):setString(CONF:getStringValue("coord")..":".."("..v.target_element.pos_list[1].x..","..v.target_element.pos_list[1].y..")")
		else
			node:getChildByName("def_name"):setVisible(false)
			node:getChildByName("def_pos"):setVisible(false)
			node:getChildByName("def_back"):setVisible(false)
			node:getChildByName("def_icon"):setVisible(false)
			node:getChildByName("no_text"):setVisible(true)
		end
		node:getChildByName("to_jijie"):setString(CONF:getStringValue("click mass"))
		node:getChildByName("to_jijie"):addClickEventListener(function ( ... )
			-- self:getApp():addView2Top("WarScene/MassLayer", {my_base = v.my_base, army_info = v.army, element_info = v.target_element})
			self:getApp():pushView("WarScene/MassScene", {my_base = v.my_base, army_info = v.army, element_info = v.target_element})
		end)

		if v.army.status_machine ~= 10 then
			node:getChildByName("to_jijie"):setVisible(false)
		end

		local function clickAtkPos( ... )
			self:getApp():pushToRootView('PlanetScene/PlanetScene',{move_info = {pos = {x=v.my_base.pos_list[1].x,y=v.my_base.pos_list[1].y},node_id_list = {getNodeIDByGlobalPos(v.my_base.pos_list[1])}} })
		end

		local function clickDefPos( ... )
			self:getApp():pushToRootView('PlanetScene/PlanetScene',{move_info = {pos = {x=v.target_element.pos_list[1].x,y=v.target_element.pos_list[1].y},node_id_list = {getNodeIDByGlobalPos(v.target_element.pos_list[1])}} })
		end

		-- addListener(node:getChildByName("atk_click_pos"), clickAtkPos)
		-- addListener(node:getChildByName("def_click_pos"), clickDefPos)

		local callback = {{node = node:getChildByName("atk_click_pos"), func = clickAtkPos},{node = node:getChildByName("def_click_pos"), func = clickDefPos}}

		if v.army.mass_time - (player:getServerTime() - v.army.begin_time) >= 0 then
			local percent = ( v.army.mass_time - (player:getServerTime() - v.army.begin_time)) / v.army.mass_time
			if percent < 0 then
				percent = 0
			end
			if percent > 100 then
				percent = 100
			end
			node:getChildByName("jijie_tiao"):setContentSize(cc.size(node:getChildByName("jijie_tiao"):getTag()*percent, node:getChildByName("jijie_tiao"):getContentSize().height))
			node:getChildByName("jijie_text"):setString(CONF:getStringValue("mass count down")..":"..formatTime(v.army.mass_time - (player:getServerTime() - v.army.begin_time)))
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
				node:getChildByName("jijie_text"):setString(CONF:getStringValue("go mass")..":"..formatTime(v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))
			else
				node:getChildByName("jijie_text"):setString(CONF:getStringValue("go")..":"..formatTime(v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))
			end
		end

		if self.type == WarType.DEF then
			node:getChildByName("to_jijie"):setVisible(false)
			node:getChildByName("jijie_tiao"):setVisible(false)
			node:getChildByName("jijie_back"):setVisible(false)
			node:getChildByName("jijie_text"):setVisible(false)
		end

		node:setName("army_node_"..i)
		self.svd_:addElement(node, {callback = callback})
 
	end
end

function WarScene:changeType( type )

	self.type = type 

	local rn = self:getResourceNode()
	local group_main = player:getPlayerGroupMain()
	print('atk ',#group_main.enlist_list)
	for i,v in ipairs(group_main.enlist_list) do
		print(i,v)
	end

	print('def ',#group_main.attack_our_list)
	for i,v in ipairs(group_main.attack_our_list) do
		print(i,v)
	end

	if type == WarType.ATK then
		rn:getChildByName("atk_tiao"):loadTexture("MailLayer/ui/lv.png")
		rn:getChildByName("atk_tiao"):setRotation(0)

		rn:getChildByName("def_tiao"):loadTexture("WarScene/ui/gray_bg.png")
		rn:getChildByName("def_tiao"):setRotation(0)
		rn:getChildByName("no_text"):setString(CONF:getStringValue("no war"))

		if not Tools.isEmpty(group_main.enlist_list) then
			rn:getChildByName("no_text"):setVisible(false)

			print("changeType send")
			local strData = Tools.encode("PlanetGetReq", {
					army_key_list = group_main.enlist_list,
					type = 7,
				 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
			gl:retainLoading()
		else
			rn:getChildByName("no_text"):setVisible(true)
			self.svd_:clear()
			self.army_info_list = nil
		end

	elseif type == WarType.DEF then
		rn:getChildByName("def_tiao"):loadTexture("MailLayer/ui/hong.png")
		rn:getChildByName("def_tiao"):setRotation(0)

		rn:getChildByName("atk_tiao"):loadTexture("WarScene/ui/gray_bg.png")
		rn:getChildByName("atk_tiao"):setRotation(180)
		rn:getChildByName("no_text"):setString(CONF:getStringValue("no defense"))

		if not Tools.isEmpty(group_main.attack_our_list) then
			rn:getChildByName("no_text"):setVisible(false)
			print("changeType send")
			local strData = Tools.encode("PlanetGetReq", {
					army_key_list = group_main.attack_our_list,
					type = 7,
				 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
			gl:retainLoading()
		else
			rn:getChildByName("no_text"):setVisible(true)
			self.svd_:clear()
			self.army_info_list = nil
		end
	end
end

function WarScene:onEnterTransitionFinish()
	printInfo("WarScene:onEnterTransitionFinish()")

	self.type = WarType.ATK

	local rn = self:getResourceNode()

	local group_main = player:getPlayerGroupMain()
	local enlist_list = group_main.enlist_list
	print('atk ',#group_main.enlist_list)
	for i,v in ipairs(group_main.enlist_list) do
		print(i,v)
	end

	print('def ',#group_main.attack_our_list)
	for i,v in ipairs(group_main.attack_our_list) do
		print(i,v)
	end

	animManager:runAnimOnceByCSB(rn, "WarScene/WarScene.csb",  "intro")

	rn:getChildByName("atk_text"):setString(CONF:getStringValue("covenant war"))
	rn:getChildByName('atk_ren'):setString(CONF:getStringValue("sponsor"))
	rn:getChildByName("def_text"):setString(CONF:getStringValue("covenant defense"))
	rn:getChildByName("def_ren"):setString(CONF:getStringValue("target"))
	rn:getChildByName("title"):setString(CONF:getStringValue("covenant war"))
	rn:getChildByName("no_text"):setString(CONF:getStringValue("no war"))
	rn:getChildByName("close"):addClickEventListener(function ( ... )
		if self.data_.from and self.data_.from == 'PlanetUILayer' then
			self:getApp():pushToRootView("PlanetScene/PlanetScene")
		else
			self:getApp():popView()
		end
	end)
	rn:getChildByName("atk_info"):getChildByName("text"):setString(table.getn(enlist_list))
	rn:getChildByName("def_info"):getChildByName("text"):setString(table.getn(group_main.attack_our_list))

	rn:getChildByName("atk_tiao"):addClickEventListener(function ( ... )
		if self.type == WarType.ATK then
			return
		end

		self:changeType(WarType.ATK)
	end)

	rn:getChildByName("def_tiao"):addClickEventListener(function ( ... )
		if self.type == WarType.DEF then
			return
		end

		self:changeType(WarType.DEF)
	end)


	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName('list'),cc.size(5,10), cc.size(1000,163))

	print("#enlist_list",#enlist_list)
	if not Tools.isEmpty(enlist_list) then
		print("finish send")
		local strData = Tools.encode("PlanetGetReq", {
				army_key_list = enlist_list,
				type = 7,
			 })
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
		gl:retainLoading()
	else
		rn:getChildByName("no_text"):setVisible(true)
		-- rn:getChildByName("list"):setVisible(false)
	end

	local function updateData( group_main )

		print("updateData")
		rn:getChildByName("atk_info"):getChildByName("text"):setString(table.getn(group_main.enlist_list))
		rn:getChildByName("def_info"):getChildByName("text"):setString(table.getn(group_main.attack_our_list))

  		if self.type == WarType.ATK then

			rn:getChildByName("no_text"):setString(CONF:getStringValue("no war"))

			print("#updateData group_main.enlist_list",#group_main.enlist_list)
			if not Tools.isEmpty(group_main.enlist_list) then
				rn:getChildByName("no_text"):setVisible(false)

				self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
					print("update send")
					local strData = Tools.encode("PlanetGetReq", {
						army_key_list = group_main.enlist_list,
						type = 7,
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
					gl:retainLoading()
				end)))
				
			else
				rn:getChildByName("no_text"):setVisible(true)
				self.svd_:clear()
				self.army_info_list = nil
			end

		elseif self.type == WarType.DEF then

			rn:getChildByName("no_text"):setString(CONF:getStringValue("no defense"))

			if not Tools.isEmpty(group_main.attack_our_list) then
				rn:getChildByName("no_text"):setVisible(false)

				self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
					print("update send")
					local strData = Tools.encode("PlanetGetReq", {
						army_key_list = group_main.attack_our_list,
						type = 7,
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
					gl:retainLoading()
				end)))

			else
				rn:getChildByName("no_text"):setVisible(true)
				self.svd_:clear()
				self.army_info_list = nil
			end
		end
	end

	local function update(  )	
		if self.army_info_list then
			for i,v in ipairs(self.army_info_list) do

				local duiwu_str = ""
				if v.army.mass_time - (player:getServerTime() - v.army.begin_time) >= 0 and #v.army.army_key_list + #v.army.req_army_key_list > 0 then
					local duiwu_strs = Split(CONF:getStringValue("text_1"), "#")
					for i2,v2 in ipairs(duiwu_strs) do
						duiwu_str = duiwu_str..v2

						if i2 == 1 then
							duiwu_str = duiwu_str..v.my_base.base_data.info.nickname
						end
					end
				else
					duiwu_str = duiwu_str..v.my_base.base_data.info.nickname
				end
				self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("atk_name"):setString(duiwu_str)

				if v.army.mass_time - (player:getServerTime() - v.army.begin_time) >= 0 then
					local percent = ( v.army.mass_time - (player:getServerTime() - v.army.begin_time)) / v.army.mass_time
					if percent < 0 then
						percent = 0
					end
					if percent > 100 then
						percent = 100
					end
					self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_tiao"):setContentSize(cc.size(self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_tiao"):getTag()*percent, self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_tiao"):getContentSize().height))
					self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_text"):setString(CONF:getStringValue("mass count down")..":"..formatTime(v.army.mass_time - (player:getServerTime() - v.army.begin_time)))
				else
					if v.army.line.begin_time == nil or v.army.line.begin_time == 0 or v.army.line.need_time == 0 then
						updateData(player:getPlayerGroupMain())

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
								self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_text"):setString(CONF:getStringValue("go mass")..":"..formatTime(v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))
							else
								self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("jijie_text"):setString(CONF:getStringValue("go")..":"..formatTime(v.army.line.need_time - (player:getServerTime() - v.army.line.begin_time)))
							end
						else
							local strData = Tools.encode("GetGroupReq", {
								groupid = "",
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_REQ"),strData)

							gl:retainLoading()
							-- updateData(player:getPlayerGroupMain())
						end
					end
				end
				local num = 1
				if not Tools.isEmpty(v.army.army_key_list) then
					num = num + #v.army.army_key_list
				end
				if not Tools.isEmpty(v.army.req_army_key_list) then
					num = num + #v.army.req_army_key_list
				end
				self.svd_:getScrollView():getChildByName("army_node_"..i):getChildByName("atk_people"):setString(CONF:getStringValue("mass member")..":"..num.."/"..CONF.BUILDING_1.get(v.my_base.base_data.info.building_level_list[1]).MASS+1)

			end
		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	

	local function recvMsg()
		print("WarScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("PlanetGetResp",strData)
			print("WarScene PlanetGetResp result",proto.result, proto.type)

			-- gl:releaseLoading()
			if proto.type == 7 then

				if proto.result == 0 then
					self.army_info_list = proto.army_info_list
					self:resetList(proto.army_info_list)
					rn:getChildByName("no_text"):setVisible(false)
					
				elseif proto.result == 1 then
					self.svd_:clear()
					rn:getChildByName("no_text"):setVisible(true)
				-- elseif proto.result == 2 then
				-- 	self:getApp():popView()
	        	end
	        end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_RESP") then
			gl:releaseLoading()

		    local proto = Tools.decode("GetGroupResp",strData)
		    print("GetGroupResp",proto.result)
			
		    if proto.result == 0 then
		    	-- updateData(player:getPlayerGroupMain())

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

  		updateData(event.group_main)
  		print("#enlist_list", #event.group_main.enlist_list)
 		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.groupListener_, FixedPriority.kNormal)

end

function WarScene:onExitTransitionStart()

	printInfo("WarScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.groupListener_)

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return WarScene	