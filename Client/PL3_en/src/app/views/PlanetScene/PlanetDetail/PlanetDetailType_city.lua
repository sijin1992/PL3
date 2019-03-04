
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local path_reach = require('PathReach'):create()

local planetMachine = require("app.views.PlanetScene.Manager.PlanetMachine"):getInstance()

local g_sendList = require("util.SendList"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local planetArmyManager = require("app.views.PlanetScene.Manager.PlanetArmyManager"):getInstance()

local PlanetDetailType_city = class("PlanetDetailType_city", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

PlanetDetailType_city.RESOURCE_FILENAME = "PlanetScene/PlanetDetailLayer.csb"

PlanetDetailType_city.RUN_TIMELINE = true

PlanetDetailType_city.NEED_ADJUST_POSITION = true

PlanetDetailType_city.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil


function PlanetDetailType_city:onCreate( data )
	self.data_ = data
end

function PlanetDetailType_city:onEnter()
  
	printInfo("PlanetScene:onEnter()")

end

function PlanetDetailType_city:onExit()
	
	printInfo("PlanetScene:onExit()")
end

local function getTime(data)
	local speeds = CONF.PARAM.get('planet_move_speed').PARAM
	local speed = speeds[2]

	if not planetManager:getUserBaseElementInfo( ) or not planetManager:getUserBaseElementInfo( ).global_key then
		return
	end
	local src_node_id = tonumber(Tools.split(planetManager:getUserBaseElementInfo( ).global_key,"_")[1])
	local dest_node_id = tonumber(Tools.split(data.global_key, "_")[1])
	local node_list = {}
	if src_node_id ~= dest_node_id then
		node_list = path_reach:getFindPathList(src_node_id, dest_node_id)
	end
	if node_list == nil then
	  	return nil
	end
	local dest_pos = data.pos_list[1]
	local src_pos = planetManager:getUserBaseElementInfo( ).pos_list[1]
	local nodeW = g_Planet_Grid_Info.row
	local nodeH = g_Planet_Grid_Info.col
	local function getRectInGlobal(row, col)

		local min = {x = row * nodeW - nodeW/2, y = col * nodeH - nodeH/2}
		local max = {x = row * nodeW + nodeW/2 - 1, y = col * nodeH + nodeH/2 - 1}

		return min, max
	end

	local function getGlobalPosByNode( node_id, diffX, diffY )

		local conf = CONF.PLANETWORLD.get(node_id)
		local min, max = getRectInGlobal(conf.ROW, conf.COL)

		return {x = min.x + diffX, y = min.y + diffY}
	end
	-- if #node_list < 3 then
	--   	return {src_pos, dest_pos}, {src_node_id, dest_node_id}
	-- end

	local pos_list = {src_pos}

	for i=2,#node_list-1 do
	 	local conf = CONF.PLANETWORLD.get(node_list[i])
		if conf.TYPE > 2 then
		  	local pos = getGlobalPosByNode(node_list[i], nodeW/2, nodeH/2)
		    table.insert(pos_list, pos)
		end
	end
	table.insert(pos_list, dest_pos)
	return Tools.getPlanetMoveTime( pos_list, speed )
end

function PlanetDetailType_city:resetList( mail_user_info )
	
	self.svd_:clear()

	local english = {"a", "b", "c", "d", "e"}

	local function createInfoNode( ship_info )

		print("createInfoNodeeeeeeeeee")

		local rn = self:getResourceNode()
		local ship_info_node = require("util.ItemInfoNode"):createShipInfoNodeByInfo(ship_info)
		ship_info_node:setPosition(cc.p(rn:getChildByName("uibg"):getPositionX() - ship_info_node:getChildByName("landi"):getContentSize().width/2, rn:getChildByName("uibg"):getPositionY() + ship_info_node:getChildByName("landi"):getContentSize().height/4))
		rn:addChild(ship_info_node)
	end

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


	for i,v in ipairs(mail_user_info) do
		local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/teamNode.csb")
		node:getChildByName("Text_1"):setString(CONF:getStringValue("Team "..english[i])..":"..v.info.nickname)

		for j=#v.ship_list+1,5 do
			node:getChildByName('FileNode_'..j):setVisible(false)
			node:getChildByName('text_jindu'..j):setVisible(false)
			node:getChildByName('Image_jindu'..j):setVisible(false)
			node:getChildByName('jdt_bottom'..j):setVisible(false)
		end

		for j=1,#v.ship_list do
			node:getChildByName('FileNode_'..j):getChildByName("icon"):loadTexture("RoleIcon/"..v.ship_list[j].id..".png")
			node:getChildByName('FileNode_'..j):getChildByName("background"):loadTexture("RankLayer/ui/ui_avatar_"..v.ship_list[j].quality..".png")
			node:getChildByName("text_jindu"..j):setString(v.ship_hp_list[v.ship_list[j].position].."/"..v.ship_list[j].attr[CONF.EShipAttr.kHP])
			node:getChildByName("Image_jindu"..j):setContentSize(cc.size(node:getChildByName("Image_jindu"..j):getTag()*(v.ship_hp_list[v.ship_list[j].position]/v.ship_list[j].attr[CONF.EShipAttr.kHP]), node:getChildByName("Image_jindu"..j):getContentSize().height))
			addListener(node:getChildByName('FileNode_'..j):getChildByName("icon"), function ( ... )
				local rn = self:getResourceNode()
				local ship_info_node = require("util.ItemInfoNode"):createShipInfoNodeByInfo(v.ship_list[j])
				ship_info_node:setPosition(cc.p(rn:getChildByName("uibg"):getPositionX() - ship_info_node:getChildByName("landi"):getContentSize().width/2, rn:getChildByName("uibg"):getPositionY() + ship_info_node:getChildByName("landi"):getContentSize().height/2))
				rn:addChild(ship_info_node)
			end)
		end

		self.svd_:addElement(node)
	end

end

function PlanetDetailType_city:onEnterTransitionFinish()
	printInfo("PlanetDetailType_city:onEnterTransitionFinish()")


	local info = self.data_.info
	local conf = CONF.PLANETCITY.get(info.city_data.id)

	local rn = self:getResourceNode()
	rn:getChildByName("Image_2"):setTexture("PlanetIcon2/"..conf.ICON..".png")

	rn:getChildByName("close"):addClickEventListener(function ( ... )
		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
		self:getApp():removeTopView()
	end)

	rn:getChildByName("btn_show"):setVisible(true)
	rn:getChildByName("btn_show"):getChildByName("text"):setString(CONF:getStringValue("occupy award"))
	rn:getChildByName("btn_show"):addClickEventListener(function()
		local layer = self:getApp():createView("PlanetScene/PlanetDetail/PlanetDetailType_cityReward",info.city_data.id)
		self:addChild(layer)
		end)

	local userInfoNode = require("util.UserInfoNode"):create()
	userInfoNode:init(self)
	userInfoNode:setName("userInfoNode")
	if rn:getChildByName("info_node"):getChildByName('userInfoNode') == nil then
		rn:getChildByName("info_node"):addChild(userInfoNode)
	end

	local detail_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/city.csb")
	detail_node:getChildByName("city_name"):setString(CONF:getStringValue(CONF.PLANETCITY.get(info.city_data.id).NAME))
	detail_node:getChildByName("zhan"):setString(CONF:getStringValue("zhanlingzhe")..":")
	detail_node:getChildByName("move"):setString(CONF:getStringValue("yidong_time")..":")
	detail_node:getChildByName("buff"):setString(CONF:getStringValue("judian").." buff"..":")
	detail_node:getChildByName("army"):setString(CONF:getStringValue("station_centre")..":")

	detail_node:getChildByName("zhan_name"):setPositionX(detail_node:getChildByName("zhan"):getPositionX() + detail_node:getChildByName("zhan"):getContentSize().width)
	detail_node:getChildByName("move_time"):setPositionX(detail_node:getChildByName("move"):getPositionX() + detail_node:getChildByName("move"):getContentSize().width)
	detail_node:getChildByName("army_ins"):setPositionX(detail_node:getChildByName("army"):getPositionX() + detail_node:getChildByName("army"):getContentSize().width)


	if info.city_data.groupid == "" or info.city_data.groupid == nil then
		detail_node:getChildByName("zhan_name"):setString(CONF:getStringValue("trial_building_no_player"))
	else
		-- if planetManager:getGroupInfoByGroupId(info.city_data.groupid) then
		-- 	local group_info = planetManager:getGroupInfoByGroupId(info.city_data.groupid)

		-- 	detail_node:getChildByName("zhan_name"):setString(group_info.nickname)
		-- end
		detail_node:getChildByName("zhan_name"):setString(info.city_data.temp_info.nickname)
	end
	detail_node:getChildByName("move_time"):setString(formatTime(getTime(info)))


	local bbb = {conf.BUFF[1],conf.BUFF[1],conf.BUFF[1]}
	local buff_ins_pos = cc.p(detail_node:getChildByName("buff_ins"):getPosition())
	for i,v in ipairs(conf.BUFF) do

		local tech_conf = CONF.GROUP_TECH.get(v)

		local str = CONF:getStringValue(tech_conf.MEMO)
		if tech_conf.TECHNOLOGY_ATTR_PERCENT ~= 0 then
			str = str..tech_conf.TECHNOLOGY_ATTR_PERCENT.."%" 
		end

		if tech_conf.TECHNOLOGY_ATTR_VALUE ~= 0 then
			str = str..tech_conf.TECHNOLOGY_ATTR_VALUE
		end

		if i == 1 then
			detail_node:getChildByName("buff_ins"):setString(str)
		else
			local label = cc.Label:createWithTTF(str, "fonts/cuyabra.ttf", detail_node:getChildByName("buff_ins"):getFontSize())
			label:setAnchorPoint(cc.p(0,1))
			label:setPosition(cc.p(buff_ins_pos.x, buff_ins_pos.y - (i-1)*27 + 14))
			label:setTextColor(cc.c4b(33,255,70,255))
			-- label:enableShadow(cc.c4b(33,255,70,255), cc.size(0.5,0.5))
			detail_node:addChild(label)

		end
	end

	local down_list = {"army", "army_ins", "ship_list", "wen", "btn"}
	for i,v in ipairs(down_list) do
		detail_node:getChildByName(v):setPositionY(detail_node:getChildByName(v):getPositionY() - (#conf.BUFF - 1)*30)
	end

	detail_node:getChildByName("ship_list"):setScrollBarEnabled(false)
	detail_node:setName("detail_node")
	rn:getChildByName("Node_detail"):addChild(detail_node)
	self.svd_ = require("util.ScrollViewDelegate"):create(detail_node:getChildByName('ship_list'),cc.size(5,10), cc.size(550,140))

	if player:isGroup() then
		if player:getGroupData().groupid == info.city_data.groupid then
			detail_node:getChildByName("wen"):setVisible(false)
			detail_node:getChildByName("army_ins"):setString(#info.city_data.guarde_list.."/"..conf.TROOPS_LIMIT)

			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetShow5")
			local strData = Tools.encode("PlanetGetReq", {
					army_key_list = info.city_data.guarde_list,
					type = 5,
				 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
		end
	end


	local function onTouchBegan(touch, event)
		return true
	end

	local function onTouchEnded(touch, event)

	end
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	local function recvMsg()
		print("PlanetDetailType_city:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then

			local proto = Tools.decode("PlanetGetResp",strData)
			print("PlanetGetResp result",proto.result, proto.type)

			-- gl:releaseLoading()
			if proto.result == 0 then
				if proto.type == 5 then
					self:resetList(proto.mail_user_list)
				end
        	end
			
		end
	end
    local posX,posY
	posX = info.pos_list[1].x
	posY = info.pos_list[1].y
    rn:getChildByName("collect"):setVisible(true)
    rn:getChildByName("collect"):addClickEventListener(function ()

		local er_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/add_marker.csb")
		er_node:getChildByName("pos"):setString('('..posX..','..posY..')')
		er_node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("yes"))
		er_node:getChildByName("title"):setString(CONF:getStringValue("add_marker"))

		local msg = self.data_.node_name

		if string.len(msg) == 0 then
			msg = "X:"..posX.." Y:"..posY
		end

		er_node:getChildByName("text_field"):setString(msg)

		er_node:getChildByName("close"):addClickEventListener(function ( ... )
			er_node:removeFromParent()
		end)

		er_node:getChildByName("btn"):addClickEventListener(function ( ... )

			if er_node:getChildByName("text_field"):getString() == "" then
				tips:tips(CONF:getStringValue("point name"))
			else

				for i=1,CONF.DIRTYWORD.len do
				  if string.find(er_node:getChildByName("text_field"):getString(), CONF.DIRTYWORD[i].KEY) then
				  	tips:tips(CONF:getStringValue("dirty_message"))
				  	return
				  end
				end

				local str = shuaiSubString(er_node:getChildByName("text_field"):getString())
				for i=1,CONF.DIRTYWORD.len do
				  if string.find(str, CONF.DIRTYWORD[i].KEY) then
				  	tips:tips(CONF:getStringValue("dirty_message"))
				  	return
				  end
				end

				local strData = Tools.encode("PlanetMarkReq", {
					type = 1,
					name = er_node:getChildByName("text_field"):getString(),
					pos = {x = posX, y = posY},
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_MARK_REQ"),strData)

				er_node:removeFromParent()
			end
		end)
		self:addChild(er_node)
    end)

    rn:getChildByName("send"):setVisible(true)
    rn:getChildByName("send"):addClickEventListener(function ()
        playEffectSound("sound/system/click.mp3")

		local msg = self.data_.node_name
		if string.len(msg)>1 then
			msg = msg .. " "
		end
		msg = msg .. "X:"..posX.." Y:"..posY

        local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world",msg = msg})
		layer:setName("chatLayer")
		self:addChild(layer)		

		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
    end)
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	self:updateChat()
end

function PlanetDetailType_city:updateChat()
	local rn = self:getResourceNode()
	rn:getChildByName("chat"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		layer:setName("chatLayer")
		self:addChild(layer)

		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
	end)
	rn:getChildByName('chat_img'):addClickEventListener(function()
		playEffectSound("sound/system/click.mp3")
		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		layer:setName("chatLayer")
		self:addChild(layer)

		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
		end)
	local strData = Tools.encode("GetChatLogReq", {
			chat_id = 0,
		})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)
	local function recvMsg( )
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_RESP") then

			local proto = Tools.decode("GetChatLogResp",strData)
			print("city GetChatLogResp result",proto.result)

			-- gl:releaseLoading()

			if proto.result < 0 then
				print("error :",proto.result)
			else
				
				if not self.show_di_text then
					self.show_di_text = true

					local time = 0
					local str = ""
					local tt 

					for i,v in ipairs(proto.log_list) do
						if v.stamp > time and v.user_name ~= "0" and not player:isBlack(v.user_name) then
							time = v.stamp

							local strc = ""
							if v.group_name ~= "" then
								strc = string.format("[%s]%s:", v.group_name, v.nickname)
							else
								strc = string.format("%s:", v.nickname)
							end
							str = handsomeSubString(strc..v.chat, CONF.PARAM.get("chat number").PARAM)

							tt = {user_name = v.user_name, chat = v.chat, time = v.stamp}

						end
					end

					if player:getLastChat() == nil then
						rn:getChildByName("chat"):getChildByName("point"):setVisible(true)
					else
						if player:getLastChat().user_name == tt.user_name and player:getLastChat().chat == tt.chat and player:getLastChat().time == tt.time then
							rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
						else
							rn:getChildByName("chat"):getChildByName("point"):setVisible(true)
						end
					end

					rn:getChildByName("di_text"):setString(str)

				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ADD_STRENGTH_RESP") then
			local proto = Tools.decode("AddStrengthResp",strData)
			if proto.result == 'OK' then
				self:setStrengthPercent( )
			end
		end
	end
	self.chatRecvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.chatRecvlistener_, FixedPriority.kNormal)

	self.seeChatListener_ = cc.EventListenerCustom:create("seeChat", function ()
		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.seeChatListener_, FixedPriority.kNormal)

	self.worldListener_ = cc.EventListenerCustom:create("worldMsg", function (event)
		playEffectSound("sound/system/message_update.mp3")
		local table_ = {stamp = player:getServerTime(), chat = event.chat.msg, nickname = event.chat.sender.nickname, user_name = event.chat.sender.uid, group_name = event.chat.sender.group_nickname}
		
		local strc = ""
		if event.chat.sender.group_nickname ~= "" then
			strc = string.format("[%s]%s:", event.chat.sender.group_nickname, event.chat.sender.nickname)
		else
			strc = string.format("%s:", event.chat.sender.nickname)
		end
		local chat = handsomeSubString(strc..event.chat.msg, CONF.PARAM.get("chat number").PARAM)
		rn:getChildByName("di_text"):setString(chat)

		if self:getChildByName("chatLayer") then
			rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
		else
			rn:getChildByName("chat"):getChildByName("point"):setVisible(true)
		end

	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.worldListener_, FixedPriority.kNormal)
end

function PlanetDetailType_city:onExitTransitionStart()

	printInfo("PlanetDetailType_city:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.chatRecvlistener_)
	eventDispatcher:removeEventListener(self.seeChatListener_)
	eventDispatcher:removeEventListener(self.worldListener_)
	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return PlanetDetailType_city