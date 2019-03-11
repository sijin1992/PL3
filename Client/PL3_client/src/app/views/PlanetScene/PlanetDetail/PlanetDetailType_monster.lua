
local player = require("app.Player"):getInstance()

local planetManager = require('app.views.PlanetScene.Manager.PlanetManager'):getInstance()

local path_reach = require('PathReach'):create()

local PlanetDetailType_monster = class("PlanetDetailType_monster", cc.load("mvc").ViewBase)

PlanetDetailType_monster.RESOURCE_FILENAME = "PlanetScene/PlanetDetailLayer.csb"

PlanetDetailType_monster.NEED_ADJUST_POSITION = true
--关闭
PlanetDetailType_monster.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function PlanetDetailType_monster:OnBtnClick(event)
	if event.name == 'ended' then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			-- self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
			-- self:getApp():popView()
			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
			self:getApp():removeTopView()
		end
	end
end

function PlanetDetailType_monster:onCreate(data)
	self._data = data
end

function PlanetDetailType_monster:onEnter()

	printInfo("PlanetDetailType_monster:onEnter()")

end

function PlanetDetailType_monster:onEnterTransitionFinish()

	printInfo("PlanetDetailType_monster:onEnterTransitionFinish()")
    local rn = self:getResourceNode()
    --头像等级
    local userInfoNode = require("util.UserInfoNode"):create()
	userInfoNode:init(self)
	userInfoNode:setName("userInfoNode")
	if rn:getChildByName("info_node"):getChildByName('userInfoNode') == nil then
		rn:getChildByName("info_node"):addChild(userInfoNode)
	end
    --MonsterInfo
	local info = planetManager:getInfoByNodeGUID( self._data.node_id, self._data.guid )
    if info then
        self:showPlanetInfo(info)
    else
        print("monster's info is nil")
    end

    --聊天
    self:updateChat()
end

function PlanetDetailType_monster:showPlanetInfo(data)
    local rn = self:getResourceNode()
    --Left
    if rn:getChildByName('node_detail') == nil then
			local node_detail = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/ruins_little.csb")
			node_detail:setPosition(rn:getChildByName('Node_detail'):getPosition())
			node_detail:setName('node_detail')
			rn:addChild(node_detail)
	end

	local node_detail = rn:getChildByName('node_detail')
        node_detail:getChildByName('resName'):setString(CONF:getStringValue(CONF.PLANETCREEPS.get(data.monster_data.id).NAME)) -- 野怪名字
	node_detail:getChildByName('des_level'):setString(CONF:getStringValue('level_ji')..':') -- 等级
    node_detail:getChildByName('resLevel'):setString(CONF.PLANETCREEPS.get(data.monster_data.id).LEVEL)
    node_detail:getChildByName('resLevel'):setPosition(node_detail:getChildByName('des_level'):getPositionX()+node_detail:getChildByName('des_level'):getContentSize().width+5,node_detail:getChildByName('resLevel'):getPositionY())
	node_detail:getChildByName('des_num'):setString(CONF:getStringValue('use strength')..':') -- 消耗体力
    node_detail:getChildByName('text_num'):setString(CONF.PLANETCREEPS.get(data.monster_data.id).STRENGTH)
    node_detail:getChildByName('text_num'):setPosition(node_detail:getChildByName('des_num'):getPositionX()+node_detail:getChildByName('des_num'):getContentSize().width+5,node_detail:getChildByName('text_num'):getPositionY())
    local movetime = self:getTime(data) -- 移动时间
    node_detail:getChildByName('des_name'):setVisible(movetime ~= nil)
	node_detail:getChildByName('text_name'):setVisible(movetime ~= nil)
	if movetime then
        node_detail:getChildByName('des_name'):setString(CONF:getStringValue('yidong_time')..':')
		node_detail:getChildByName('text_name'):setString(formatTime(movetime))
        node_detail:getChildByName('text_name'):setPosition(node_detail:getChildByName('des_name'):getPositionX()+node_detail:getChildByName('des_name'):getContentSize().width+5,node_detail:getChildByName('text_name'):getPositionY())
	end
    node_detail:getChildByName('des_name1'):setString(CONF:getStringValue('recommend')..CONF:getStringValue('combat')..':') -- 推荐战力
    node_detail:getChildByName('text_name1'):setString(CONF.PLANETCREEPS.get(data.monster_data.id).RECOMMENDED)
    node_detail:getChildByName('text_name1'):setPosition(node_detail:getChildByName('des_name1'):getPositionX()+node_detail:getChildByName('des_name1'):getContentSize().width+5,node_detail:getChildByName('text_name1'):getPositionY())

    node_detail:getChildByName('des_name2'):setVisible(false)
    node_detail:getChildByName('text_name2'):setVisible(false)
	node_detail:getChildByName('Image_jindu'):setVisible(false)
	node_detail:getChildByName('jdt_bottom02_53'):setVisible(false)
	node_detail:getChildByName('text_jindu'):setVisible(false)
    node_detail:getChildByName('des_time2'):setVisible(false)

	node_detail:getChildByName('des_time'):setString(CONF:getStringValue('gailv_huode')..':') -- 概率获得
	local list = require("util.ScrollViewDelegate"):create(node_detail:getChildByName("ship_list"),cc.size(7,3), cc.size(90,90))
    node_detail:getChildByName("ship_list"):setScrollBarEnabled(false)
	local groupID = CONF.PLANETCREEPS.get(data.monster_data.id).REWARD_ID
	local itemIDs = CONF.REWARD.get(groupID).ITEM
	local itemNums = CONF.REWARD.get(groupID).COUNT
	for i=1,#itemIDs do
		if itemNums[i] then
			local itemNode = require("util.ItemNode"):create():init(itemIDs[i], itemNums[i])
			list:addElement(itemNode)
		end
	end
	local item_count = node_detail:getChildByName("ship_list"):getChildrenCount()
	local size_width = node_detail:getChildByName("ship_list"):getContentSize().width
	local can_item_count = math.floor(size_width/90)
	if item_count <= can_item_count then
		node_detail:getChildByName("ship_list"):setTouchEnabled(false)
	end

    --Right
    rn:getChildByName('Image_2'):setTexture(string.format("PlanetIcon2/%d.png", CONF.PLANETCREEPS.get(data.monster_data.id).RES_ID))
    rn:getChildByName('planteName'):setString(CONF:getStringValue(CONF.PLANETCREEPS.get(data.monster_data.id).MEMO_ID)) -- 野怪说明

    local posX,posY
	posX = data.pos_list[1].x
	posY = data.pos_list[1].y
    rn:getChildByName("collect"):setVisible(true)
    rn:getChildByName("collect"):addClickEventListener(function ()

		local er_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/add_marker.csb")
		er_node:getChildByName("pos"):setString('('..posX..','..posY..')')
		er_node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("yes"))
		er_node:getChildByName("title"):setString(CONF:getStringValue("add_marker"))

		local msg = self._data.node_name

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

		local msg = self._data.node_name
		if string.len(msg)>1 then
			msg = msg .. " "
		end
		msg = msg .. "X:"..posX.." Y:"..posY

        local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world",msg = msg})
		layer:setName("chatLayer")
		self:addChild(layer)		

		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
    end)
end

function PlanetDetailType_monster:getTime(data)
	local speed
	local speeds = CONF.PARAM.get('planet_move_speed').PARAM
	-- if data.actionType == actionType.COLLECT then
	local speed = speeds[1]
	if not planetManager:getUserBaseElementInfo() or not planetManager:getUserBaseElementInfo().global_key then
		return
	end
	local src_node_id = tonumber(Tools.split(planetManager:getUserBaseElementInfo().global_key,"_")[1])
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

function PlanetDetailType_monster:updateChat()
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

function PlanetDetailType_monster:onExitTransitionStart()

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.chatRecvlistener_)
    eventDispatcher:removeEventListener(self.seeChatListener_)
    eventDispatcher:removeEventListener(self.worldListener_)

end

function PlanetDetailType_monster:onExit()
	
	printInfo("PlanetDetailType_monster:onExit()")
end


return PlanetDetailType_monster