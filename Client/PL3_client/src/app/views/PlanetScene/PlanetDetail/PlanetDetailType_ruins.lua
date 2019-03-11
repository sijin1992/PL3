
local tips = require("util.TipsMessage"):getInstance()

local EDevelopStatus = require("app.views.ShipDevelopScene.DevelopStatus")

local gl = require("util.GlobalLoading"):getInstance()

local player = require("app.Player"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local path_reach = require('PathReach'):create()

local messageBox = require("util.MessageBox"):getInstance()

local planetManager = require('app.views.PlanetScene.Manager.PlanetManager'):getInstance()

local PlanetDetailType_ruins = class("PlanetDetailType_ruins", cc.load("mvc").ViewBase)

PlanetDetailType_ruins.RESOURCE_FILENAME = "PlanetScene/PlanetDetailLayer.csb"

PlanetDetailType_ruins.RUN_TIMELINE = true

PlanetDetailType_ruins.NEED_ADJUST_POSITION = true

PlanetDetailType_ruins.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local teamName = {
	[1] = 'Team a',
	[2] = 'Team b',
	[3] = 'Team c',
	[4] = 'Team d',
	[5] = 'Team e',
}

local scheduler = cc.Director:getInstance():getScheduler()
local schedulerSingle1 = nil
local schedulerSingle2 = nil
-- 1:base 2:res 3:ruins 4:boss 5:city
local infoType = {
	BASE = 1,
	RES = 2 ,
	RUINS = 3 ,
	BOSS = 4 ,
	CITY = 5,
}

local actionType = {
	COLLECT = 1, -- 采集
	ATTACK = 2, -- 攻击
	EXPLORE = 3, -- 探索
	RESIDENCE = 4,--驻扎
	SPY = 5,--侦查
}

function PlanetDetailType_ruins:OnBtnClick(event)
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
--data = {guid = }

function PlanetDetailType_ruins:onCreate(data)
	self._data = data
end

function PlanetDetailType_ruins:onEnter()
  
	printInfo("PlanetDetailType_ruins:onEnter()")

end

function PlanetDetailType_ruins:onExit()
	
	printInfo("PlanetDetailType_ruins:onExit()")
end

local function getTime(data)
	local speed
	local speeds = CONF.PARAM.get('planet_move_speed').PARAM
	-- if data.actionType == actionType.COLLECT then
	local speed = speeds[1]

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

function PlanetDetailType_ruins:onEnterTransitionFinish()
	printInfo("PlanetDetailType_ruins:onEnterTransitionFinish()")
	local rn = self:getResourceNode()
	local function onTouchBegan(touch, event)
		return true
	end

	local function onTouchEnded(touch, event)

	end
	self.show_di_text = false
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	local info = planetManager:getInfoByNodeGUID( self._data.node_id, self._data.guid )
	if info then
		local user_name = info.ruins_data.user_name
		if user_name and user_name ~= '' then
			local strData = Tools.encode("CmdGetOtherUserInfoReq", {
				user_name = user_name,
				})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_REQ"),strData)
		else
			self:showPlanetInfo(info)
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

        local msg = ""
		if self._data.node_name then
            msg = self._data.node_name
        else
			local info = planetManager:getInfoByNodeGUID( self._data.node_id, self._data.guid )
			if info then
				msg = planetManager:GetNodeName(info)
			end
		end

		if string.len(msg)>1 then
			msg = msg .. " "
		end
		msg = msg .. "X:"..posX.." Y:"..posY

        local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world",msg = msg})
		layer:setName("chatLayer")
		self:addChild(layer)		

		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
    end)

	if schedulerSingle1 ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerSingle1)
	 	schedulerSingle1 = nil
	end
	if schedulerSingle2 ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerSingle2)
	 	schedulerSingle2 = nil
	end
	local userInfo = {}
	local function recvMsg()
		-- print("PlanetDetailLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_RESP") then
			local proto = Tools.decode("CmdGetOtherUserInfoResp",strData)
			if proto.result == 0 then
				-- setInfoNode(info,proto.info)
				if self._data and self._data.node_id and self._data.guid then
					if info then
						self:showPlanetInfo(info,proto.info)
					end
				end
			end
		end
	end
	local userInfoNode = require("util.UserInfoNode"):create()
	userInfoNode:init(self)
	userInfoNode:setName("userInfoNode")
	if rn:getChildByName("info_node"):getChildByName('userInfoNode') == nil then
		rn:getChildByName("info_node"):addChild(userInfoNode)
	end
	-- rn:getChildByName('bottom_top3'):addClickEventListener(function() end)
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	self:updateChat()
	-- self:getFreshRES()
end

function PlanetDetailType_ruins:updateChat()
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

function PlanetDetailType_ruins:setStrengthPercent( )

	local rn = self:getResourceNode()

	local you = rn:getChildByName('AllMoneyAndEnergy')

	local strenthBar = you:getChildByName("progress")
	self.strengthDelegate_ = require("util.ScaleProgressDelegate"):create(strenthBar, 100)

	you:getChildByName("ev_num"):setString(player:getStrength().."/"..player:getMaxStrength())

	local p = player:getStrength()/player:getMaxStrength() * 100
	if p > 100 then
		p = 100
	end

	self.strengthDelegate_:setPercentage(p)
end

function PlanetDetailType_ruins:getFreshRES()
	local rn = self:getResourceNode()
	if rn:getChildByName('AllMoneyAndEnergy') ~= nil then
		for i=1, 4 do
			if rn:getChildByName('AllMoneyAndEnergy'):getChildByName(string.format("res_text_%d",i)) then
				rn:getChildByName('AllMoneyAndEnergy'):getChildByName(string.format("res_text_%d",i)):setString(formatRes(player:getResByIndex(i)))
			end
		end
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName('money_add'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

			rechargeNode:init(self:getParent(), {index = 1})
			self:addChild(rechargeNode)
		end)
		self:setStrengthPercent( )
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName('strength_add'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			self:getApp():addView2Top("CityScene/AddStrenthLayer")
		end)
	end
	local eventDispatcher = self:getEventDispatcher()
	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		for i=1, 4 do
			if rn:getChildByName('AllMoneyAndEnergy'):getChildByName(string.format("res_text_%d",i)) then
				rn:getChildByName('AllMoneyAndEnergy'):getChildByName(string.format("res_text_%d",i)):setString(formatRes(player:getResByIndex(i)))
			end
		end
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	self.strengthListener_ = cc.EventListenerCustom:create("StrengthUpdated", function ()
		self:setStrengthPercent( )
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)
end

function PlanetDetailType_ruins:showPlanetInfo(data,other_user_info) -- -- 废墟、行星带
	local rn = self:getResourceNode()
	-- local res_id = CONF.PLANET_RUINS.get(data.ruins_data.id).RES_ID)
	-- local res_name
	-- if res_id == 11001 then
	-- 	res_name = ''
	-- elseif res_id == 11002 then
	-- 	res_name = ''
	-- end
	if data.type == infoType.RUINS and data.ruins_data and next(data.ruins_data) then
		rn:getChildByName('Image_2'):setTexture(string.format("PlanetIcon2/%d.png", CONF.PLANET_RUINS.get(data.ruins_data.id).RES_ID))
		if CONF.PLANET_RUINS.get(data.ruins_data.id).TYPE == 2 then -- 行星带
			if rn:getChildByName('node_detail') == nil then
				local node_detail = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/ruins_more.csb")
				node_detail:setPosition(rn:getChildByName('Node_detail'):getPosition())
				node_detail:setName('node_detail')
				rn:addChild(node_detail)
			end
			local node_detail = rn:getChildByName('node_detail')
			node_detail:getChildByName('resName'):setString(CONF:getStringValue(CONF.PLANET_RUINS.get(data.ruins_data.id).NAME))
			node_detail:getChildByName('resLevel'):setString(CONF.PLANET_RUINS.get(data.ruins_data.id).LEVEL)
			rn:getChildByName('planteName'):setString(CONF:getStringValue(CONF.PLANET_RUINS.get(data.ruins_data.id).MEMO_ID))
			-- rn:getChildByName('Image_2'):getChildByName('planteName'):setTextColor(cc.c4b(211,44,44,255))
	  --       rn:getChildByName('Image_2'):getChildByName('planteName'):enableShadow(cc.c4b(211,44,44,255), cc.size(0.5,0.5))
	        node_detail:getChildByName('des_level'):setString(CONF:getStringValue('level_ji')..':')
	        node_detail:getChildByName('des_num'):setString(CONF:getStringValue('use strength')..':')
	        node_detail:getChildByName('text_num'):setString(CONF.PLANET_RUINS.get(data.ruins_data.id).STRENGTH)
			node_detail:getChildByName('des_name'):setString(CONF:getStringValue('yidong_time')..':') -- 移动时间
			if getTime(data) then
				node_detail:getChildByName('text_name'):setString(formatTime(getTime(data)))
			else
				node_detail:getChildByName('text_name'):setVisible(false)
				node_detail:getChildByName('des_time'):setVisible(false)
			end
			node_detail:getChildByName('des_time'):setString(CONF:getStringValue('gailv_huode')..':') -- 概率获得
			node_detail:getChildByName('text_num'):setPosition(node_detail:getChildByName('des_num'):getPositionX()+node_detail:getChildByName('des_num'):getContentSize().width+5,node_detail:getChildByName('des_num'):getPositionY())
			node_detail:getChildByName('text_name'):setPosition(node_detail:getChildByName('des_name'):getPositionX()+node_detail:getChildByName('des_name'):getContentSize().width+5,node_detail:getChildByName('des_name'):getPositionY())
			node_detail:getChildByName('resLevel'):setPosition(node_detail:getChildByName('des_level'):getPositionX()+node_detail:getChildByName('des_level'):getContentSize().width+5,node_detail:getChildByName('des_level'):getPositionY())
			local list = require("util.ScrollViewDelegate"):create(node_detail:getChildByName("ship_list"),cc.size(7,3), cc.size(90,90))
			node_detail:getChildByName("ship_list"):setScrollBarEnabled(false)
			local groupID = CONF.PLANET_RUINS.get(data.ruins_data.id).REWARD_ID
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
		elseif CONF.PLANET_RUINS.get(data.ruins_data.id).TYPE == 1 then -- 残骸
			if rn:getChildByName('node_detail') == nil then
				local node_detail = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/ruins_little.csb")
				node_detail:setPosition(rn:getChildByName('Node_detail'):getPosition())
				node_detail:setName('node_detail')
				rn:addChild(node_detail)
			end
			rn:getChildByName('planteName'):setString(CONF:getStringValue(CONF.PLANET_RUINS.get(data.ruins_data.id).MEMO_ID))
			local node_detail = rn:getChildByName('node_detail')
			node_detail:getChildByName('des_level'):setString(CONF:getStringValue('level_ji')..':')
			node_detail:getChildByName('resName'):setString(CONF:getStringValue(CONF.PLANET_RUINS.get(data.ruins_data.id).NAME))
			node_detail:getChildByName('resLevel'):setString(CONF.PLANET_RUINS.get(data.ruins_data.id).LEVEL)
			node_detail:getChildByName('des_num'):setString(CONF:getStringValue('zhanlingzhe')..':') -- 占领者
			node_detail:getChildByName('text_num'):setString(CONF:getStringValue('wu_text'))
			node_detail:getChildByName('des_name'):setString(CONF:getStringValue('use strength')..':') -- 消耗体力
			node_detail:getChildByName('text_name'):setString(CONF.PLANET_RUINS.get(data.ruins_data.id).STRENGTH)
			node_detail:getChildByName('des_name1'):setString(CONF:getStringValue('dalao_time')..':') -- 打捞时间
			node_detail:getChildByName('text_name1'):setString(formatTime(CONF.PLANET_RUINS.get(data.ruins_data.id).TIME))
			node_detail:getChildByName('des_name2'):setString(CONF:getStringValue('yidong_time')..':') -- 移动时间
			if getTime(data) then
				node_detail:getChildByName('text_name2'):setString(formatTime(getTime(data)))
			end
			node_detail:getChildByName('text_name2'):setVisible(getTime(data) ~= nil)
			node_detail:getChildByName('des_name2'):setVisible(getTime(data) ~= nil)
			node_detail:getChildByName('des_time'):setString(CONF:getStringValue('gailv_huode')..':') --概率获得
			node_detail:getChildByName('des_time2'):setString(CONF:getStringValue('shengyu_time')..':') -- 剩余打捞时间
			node_detail:getChildByName('des_time2'):setVisible(false)
			node_detail:getChildByName('Image_jindu'):setVisible(false)
			node_detail:getChildByName('jdt_bottom02_53'):setVisible(false)
			node_detail:getChildByName('text_jindu'):setVisible(false)
			local list = require("util.ScrollViewDelegate"):create(node_detail:getChildByName("ship_list"),cc.size(7,3), cc.size(90,90))
			node_detail:getChildByName("ship_list"):setScrollBarEnabled(false)
			local groupID = CONF.PLANET_RUINS.get(data.ruins_data.id).REWARD_ID
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
			-- 
			if other_user_info and next(other_user_info) then
				local strName = ''
				if other_user_info.group_nickname and other_user_info.group_nickname ~= '' then
					strName = '【'..other_user_info.group_nickname..'】'..other_user_info.nickname
				else
					strName = other_user_info.nickname
				end
				node_detail:getChildByName('text_num'):setString(strName)
				if other_user_info.user_name == player:getName() then
					node_detail:getChildByName('des_time2'):setVisible(true)
					node_detail:getChildByName("text_num"):setTextColor(cc.c4b(17,167,17,255))
			        -- node_detail:getChildByName("text_num"):enableShadow(cc.c4b(17,167,17,255), cc.size(0.5,0.5))
			        -- rn:getChildByName('Image_2'):getChildByName('planteName'):setTextColor(cc.c4b(17,167,17,255))
			        -- rn:getChildByName('Image_2'):getChildByName('planteName'):enableShadow(cc.c4b(17,167,17,255), cc.size(0.5,0.5))
			        local time = data.ruins_data.need_time - player:getServerTime() + data.ruins_data.begin_time
					node_detail:getChildByName('Image_jindu'):setVisible(true)
					local strengthDelegate_ = require("util.ScaleProgressDelegate"):create(node_detail:getChildByName('Image_jindu'), 400)
					node_detail:getChildByName('jdt_bottom02_53'):setVisible(true)
					node_detail:getChildByName('text_jindu'):setVisible(true)
					local function updatePercentage()
						local time = data.ruins_data.need_time - player:getServerTime() + data.ruins_data.begin_time
				 		local p = time/data.ruins_data.need_time * 100
				 		if p > 100 then p = 100 end
				 		if p < 0 then p = 0 end
						node_detail:getChildByName('text_jindu'):setString(formatTime(time))
						strengthDelegate_:setPercentage(p)
				 		if p <= 0 or time <= 0 then
				 			if schedulerSingle2 ~= nil then
				 				scheduler:unscheduleScriptEntry(schedulerSingle2)
							 	schedulerSingle2 = nil
							 	self:getApp():removeTopView()
				 			end
				 		end
					end
					updatePercentage()
					if schedulerSingle2 == nil and time > 0 then
						schedulerSingle2 = scheduler:scheduleScriptFunc(updatePercentage,1,false)
					end
				else
					if player:getGroupName( ) ==  other_user_info.group_nickname then
						node_detail:getChildByName("text_num"):setTextColor(cc.c4b(17,167,17,255))
				        -- node_detail:getChildByName("text_num"):enableShadow(cc.c4b(17,167,17,255), cc.size(0.5,0.5))
				        -- rn:getChildByName('Image_2'):getChildByName('planteName'):setTextColor(cc.c4b(17,167,17,255))
				        -- rn:getChildByName('Image_2'):getChildByName('planteName'):enableShadow(cc.c4b(17,167,17,255), cc.size(0.5,0.5))
					else
						node_detail:getChildByName("text_num"):setTextColor(cc.c4b(211,44,44,255))
				        -- node_detail:getChildByName("text_num"):enableShadow(cc.c4b(211,44,44,255), cc.size(0.5,0.5))
				        -- rn:getChildByName('Image_2'):getChildByName('planteName'):setTextColor(cc.c4b(211,44,44,255))
				        -- rn:getChildByName('Image_2'):getChildByName('planteName'):enableShadow(cc.c4b(211,44,44,255), cc.size(0.5,0.5))
					end
				end
			else
				node_detail:getChildByName('text_num'):setString(CONF:getStringValue('trial_building_no_player'))
			end
			node_detail:getChildByName('text_num'):setPosition(node_detail:getChildByName('des_num'):getPositionX()+node_detail:getChildByName('des_num'):getContentSize().width,node_detail:getChildByName('des_num'):getPositionY())
			node_detail:getChildByName('text_name'):setPosition(node_detail:getChildByName('des_name'):getPositionX()+node_detail:getChildByName('des_name'):getContentSize().width,node_detail:getChildByName('des_name'):getPositionY())
			node_detail:getChildByName('text_name1'):setPosition(node_detail:getChildByName('des_name1'):getPositionX()+node_detail:getChildByName('des_name1'):getContentSize().width,node_detail:getChildByName('des_name1'):getPositionY())
			node_detail:getChildByName('text_name2'):setPosition(node_detail:getChildByName('des_name2'):getPositionX()+node_detail:getChildByName('des_name2'):getContentSize().width,node_detail:getChildByName('des_name2'):getPositionY())
		end
		local sizeY = rn:getChildByName('Image_2'):getPositionY()-rn:getChildByName('Image_2'):getContentSize().height/2-rn:getChildByName('planteName'):getContentSize().height/2
		-- rn:getChildByName('planteName'):setPosition(rn:getChildByName('Image_2'):getPositionX(),sizeY)
	end
end

function PlanetDetailType_ruins:onExitTransitionStart()

	printInfo("PlanetDetailType_ruins:onExitTransitionStart()")
	if schedulerSingle1 ~= nil then
		scheduler:unscheduleScriptEntry(schedulerSingle1)
	 	schedulerSingle1 = nil
	end
	if schedulerSingle2 ~= nil then
		scheduler:unscheduleScriptEntry(schedulerSingle2)
	 	schedulerSingle2 = nil
	end
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.seeChatListener_)
	eventDispatcher:removeEventListener(self.chatRecvlistener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.worldListener_)
	eventDispatcher:removeEventListener(self.strengthListener_)
end

return PlanetDetailType_ruins