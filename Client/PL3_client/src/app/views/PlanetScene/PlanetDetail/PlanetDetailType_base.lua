
local tips = require("util.TipsMessage"):getInstance()

local EDevelopStatus = require("app.views.ShipDevelopScene.DevelopStatus")

local gl = require("util.GlobalLoading"):getInstance()

local player = require("app.Player"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local animManager = require("app.AnimManager"):getInstance()

local path_reach = require('PathReach'):create()

local messageBox = require("util.MessageBox"):getInstance()

local planetManager = require('app.views.PlanetScene.Manager.PlanetManager'):getInstance()

local PlanetDetailType_base = class("PlanetDetailType_base", cc.load("mvc").ViewBase)

PlanetDetailType_base.RESOURCE_FILENAME = "PlanetScene/PlanetDetailLayer.csb"

PlanetDetailType_base.RUN_TIMELINE = true

PlanetDetailType_base.NEED_ADJUST_POSITION = true

PlanetDetailType_base.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local teamName = {
	[1] = 'Team a',
	[2] = 'Team b',
	[3] = 'Team c',
	[4] = 'Team d',
	[5] = 'Team e',
}

local schedulerSingle1 = nil
local schedulerShield = nil
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

function PlanetDetailType_base:OnBtnClick(event)
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

function PlanetDetailType_base:onCreate(data)
	self._data = data
end

function PlanetDetailType_base:onEnter()
  
	printInfo("PlanetDetailType_base:onEnter()")

end

function PlanetDetailType_base:onExit()
	
	printInfo("PlanetDetailType_base:onExit()")
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

function PlanetDetailType_base:onEnterTransitionFinish()
	printInfo("PlanetDetailType_base:onEnterTransitionFinish()")
	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetShow5")
	
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
		local user_name = info.base_data.user_name
		if user_name and user_name ~= '' then
			local strData = Tools.encode("CmdGetOtherUserInfoReq", {
				user_name = user_name,
				})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_REQ"),strData)
		else
			self:showPlanetInfo(info)
		end
	end
	if schedulerSingle1 ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerSingle1)
	 	schedulerSingle1 = nil
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
						userInfo = proto.info
					end
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then

			local proto = Tools.decode("PlanetGetResp",strData)
			-- print("PlanetGetResp result",proto.result, proto.type)

			-- gl:releaseLoading()
			if proto.result ~= 0 then
				print("error :",proto.result, proto.type)
			else
				if proto.type == 5 then
					self.planetMailUser = proto.mail_user_list
					self:setBaseNode(info,userInfo,proto.mail_user_list)
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

function PlanetDetailType_base:updateChat()
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

function PlanetDetailType_base:setStrengthPercent( )

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

function PlanetDetailType_base:getFreshRES()
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
function PlanetDetailType_base:showPlanetInfo(data,other_user_info) -- 玩家基地
	if data.type ~= infoType.BASE then
		return 
	end
	if not data.base_data or not next(data.base_data) then
		return
	end
	local rn = self:getResourceNode()

	if Tools.isEmpty(data.base_data.guarde_list) == false then
		local strData = Tools.encode("PlanetGetReq", {
				army_key_list = data.base_data.guarde_list,
				type = 5,
			 })
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
	else
		self:setBaseNode(data,other_user_info)
	end
end

function PlanetDetailType_base:setBaseNode(data,otherUserInfo,shipListInfo)
	local rn = self:getResourceNode()
	if rn:getChildByName('node_detail') == nil then
		local node_detail = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/base.csb")
		node_detail:setPosition(rn:getChildByName('Node_detail'):getPosition())
		node_detail:setName('node_detail')
		rn:addChild(node_detail)
	end
	local node_detail = rn:getChildByName('node_detail')
	rn:getChildByName('planteName'):setString(otherUserInfo.nickname)
    rn:getChildByName('plantepos'):setPosition(rn:getChildByName('planteName'):getPositionX(),rn:getChildByName('planteName'):getPositionY() + 20)
    rn:getChildByName('plantepos'):setVisible(true)
    rn:getChildByName('plantepos'):setString("(".."X:"..data.pos_list[1].x..",".."Y:"..data.pos_list[1].y..")")
	-- rn:getChildByName('Image_2'):setTexture(string.format("PlanetScene/ui/user_star.png"))
	local icon = CONF.BUILDING_1.get(otherUserInfo.building_level_list[1]).IMAGE
	rn:getChildByName('Image_2'):setTexture("PlanetIcon2/"..icon..".png")

	rn:getChildByName("shield"):setVisible(false)
	rn:getChildByName("shield_text"):setVisible(false)
	local function changeShieldInfo( ... )
		if data.base_data.info.user_name == player:getName() then
			if data.base_data.shield_start_time > 0 then
				if player:getServerTime() - data.base_data.shield_start_time <= data.base_data.shield_time then
					rn:getChildByName("shield"):setVisible(true)
					animManager:runAnimByCSB(rn:getChildByName("shield"), "PlanetScene/sfx/kongjianzhan/shield.csb", "1")

					rn:getChildByName("shield_text"):setVisible(true)
					rn:getChildByName("shield_text"):setString(formatTime(data.base_data.shield_time - (player:getServerTime() - data.base_data.shield_start_time)))
				else
					rn:getChildByName("shield"):setVisible(false)
					rn:getChildByName("shield_text"):setVisible(false)
				end
			else
				rn:getChildByName("shield"):setVisible(false)
				rn:getChildByName("shield_text"):setVisible(false)
			end
		end
	end

	changeShieldInfo()
	local function updateShield( ... )
		changeShieldInfo()
	end

	schedulerShield = scheduler:scheduleScriptFunc(updateShield, 1, false)

	local sizeY = rn:getChildByName('Image_2'):getPositionY()-rn:getChildByName('Image_2'):getContentSize().height/2-rn:getChildByName('planteName'):getContentSize().height/2
	-- rn:getChildByName('planteName'):setPosition(rn:getChildByName('Image_2'):getPositionX(),sizeY)
	node_detail:getChildByName('Image_jiantou'):setVisible(false)
	node_detail:getChildByName('Button1'):setVisible(false)
	node_detail:getChildByName('des_level'):setString(CONF:getStringValue('level')..':')
	node_detail:getChildByName('resName'):setString(otherUserInfo.nickname) -- 我的行星
	node_detail:getChildByName('resLevel'):setString('Lv.'..otherUserInfo.level) -- 我的等级
	node_detail:getChildByName('des1'):setString(CONF:getStringValue('combat')..':') -- 战力
	if data.base_data.user_name == player:getName() then
		node_detail:getChildByName('text1'):setString(player:getPower())
	else
		node_detail:getChildByName('text1'):setString(otherUserInfo.power)
	end
	node_detail:getChildByName('des2'):setString(CONF:getStringValue('covenant')..':') -- 星盟
	local nickname = CONF:getStringValue('wu_text')
	if otherUserInfo.group_nickname and otherUserInfo.group_nickname ~= '' then
		nickname = otherUserInfo.group_nickname
	end
	node_detail:getChildByName('text2'):setString(nickname)
	local nodeId = tonumber(Tools.split(data.global_key,"_")[1])
	node_detail:getChildByName('des3'):setString(CONF:getStringValue('xingxi')..':') -- 星系
	node_detail:getChildByName('text3'):setString( CONF:getStringValue(CONF.PLANETWORLD.get(nodeId).NAME))
	node_detail:getChildByName('des4'):setString(CONF:getStringValue('cuihuidu')..':') --摧毁度
	local max_destroy = CONF.PARAM.get('planet_destroy_value_limit').PARAM
	local p = data.base_data.destroy_value/max_destroy*100
	if p < 0 then p = 0 end
	if p > 100 then p = 100 end
	local progress = require("util.ScaleProgressDelegate"):create(node_detail:getChildByName('Image_jindu'), 400)
	progress:setPercentage(p)
	node_detail:getChildByName('text_jindu'):setString(p..'%')
	node_detail:getChildByName('des5'):setString(CONF:getStringValue('zhuzha')..':') -- 驻扎队伍

	local maxArmy_num = CONF.BUILDING_1.get(otherUserInfo.building_level_list[1]).ARMY_NUM

	local function setJinDun(see)
		node_detail:getChildByName("jdt_bottom02_53"):setVisible(see)
		node_detail:getChildByName("Image_jindu"):setVisible(see)
		node_detail:getChildByName("text_jindu"):setVisible(see)
		node_detail:getChildByName("des4"):setVisible(see)
	end

	-- node_detail:getChildByName('text5'):setString('1'..'/'..maxArmy_num)
	node_detail:getChildByName('des5'):setVisible(true)
	node_detail:getChildByName('text5'):setVisible(true)
	if player:checkPlayerIsInGroup(data.base_data.user_name) then
		node_detail:getChildByName('resName'):setTextColor(cc.c4b(17,167,17,255))
		-- node_detail:getChildByName('resName'):enableShadow(cc.c4b(17,167,17,255), cc.size(0.5,0.5))
		-- rn:getChildByName('Image_2'):getChildByName('planteName'):setTextColor(cc.c4b(17,167,17,255))
		-- rn:getChildByName('Image_2'):getChildByName('planteName'):enableShadow(cc.c4b(17,167,17,255), cc.size(0.5,0.5))
	else
		node_detail:getChildByName('des5'):setVisible(false)
		node_detail:getChildByName('text5'):setVisible(false)
		node_detail:getChildByName('resName'):setTextColor(cc.c4b(211,44,44,255))
		-- node_detail:getChildByName('resName'):enableShadow(cc.c4b(211,44,44,255), cc.size(0.5,0.5))
		-- rn:getChildByName('Image_2'):getChildByName('planteName'):setTextColor(cc.c4b(211,44,44,255))
		-- rn:getChildByName('Image_2'):getChildByName('planteName'):enableShadow(cc.c4b(211,44,44,255), cc.size(0.5,0.5))
	end
	if data.base_data.user_name == player:getName() then
		node_detail:getChildByName('resName'):setString(CONF:getStringValue('My_station')) -- 我的行星
		node_detail:getChildByName('resName'):setTextColor(cc.c4b(255,255,255,255))
		-- node_detail:getChildByName('resName'):enableShadow(cc.c4b(255,255,255,255), cc.size(0.5,0.5))
		-- rn:getChildByName('Image_2'):getChildByName('planteName'):setTextColor(cc.c4b(255,255,255,255))
		-- rn:getChildByName('Image_2'):getChildByName('planteName'):enableShadow(cc.c4b(255,255,255,255), cc.size(0.5,0.5))
	end
	node_detail:getChildByName('text1'):setPosition(node_detail:getChildByName('des1'):getPositionX()+node_detail:getChildByName('des1'):getContentSize().width,node_detail:getChildByName('des1'):getPositionY())
	node_detail:getChildByName('text2'):setPosition(node_detail:getChildByName('des2'):getPositionX()+node_detail:getChildByName('des2'):getContentSize().width,node_detail:getChildByName('des2'):getPositionY())
	node_detail:getChildByName('text3'):setPosition(node_detail:getChildByName('des3'):getPositionX()+node_detail:getChildByName('des3'):getContentSize().width,node_detail:getChildByName('des3'):getPositionY())
	node_detail:getChildByName('Image_jindu'):setPosition(node_detail:getChildByName('des4'):getPositionX()+node_detail:getChildByName('des4'):getContentSize().width,node_detail:getChildByName('des4'):getPositionY())
	node_detail:getChildByName('text5'):setPosition(node_detail:getChildByName('des5'):getPositionX()+node_detail:getChildByName('des5'):getContentSize().width,node_detail:getChildByName('des5'):getPositionY())
	node_detail:getChildByName('jdt_bottom02_53'):setPosition(node_detail:getChildByName('Image_jindu'):getPosition())
	node_detail:getChildByName('resLevel'):setPosition(node_detail:getChildByName('des_level'):getPositionX()+node_detail:getChildByName('des_level'):getContentSize().width,node_detail:getChildByName('des_level'):getPositionY())
	local armyNum = shipListInfo and #shipListInfo or 0
	local cixu
	if shipListInfo then
		for k,v in ipairs(shipListInfo) do
			if v.info.user_name == otherUserInfo.user_name then
				armyNum = armyNum - 1
				cixu = k
			end
		end
	end
	node_detail:getChildByName('ship_list'):setScrollBarEnabled(false)
	node_detail:getChildByName('text5'):setString(armyNum..'/'..maxArmy_num)
	if shipListInfo and (data.base_data.user_name == player:getName() or (player:getGroupName( ) ==  otherUserInfo.group_nickname and player:getGroupName( ) ~= "") ) then
		if armyNum >= 2 then
			node_detail:getChildByName('Image_jiantou'):setVisible(true)
		end
		node_detail:getChildByName('des5'):setVisible(true)
		node_detail:getChildByName('text5'):setVisible(true)
		local list = require("util.ScrollViewDelegate"):create(node_detail:getChildByName('ship_list'),cc.size(0,10), cc.size(550,130))
		local teamNum = 1
		for k,v in ipairs(shipListInfo) do
			local shipInfo = {}
			if v.info.user_name ~= otherUserInfo.user_name then
				for i,p in ipairs(v.ship_list) do
					local can = false
					if not cixu then
						can = true
					else
						if k ~= cixu then
							can = true
						end
					end
					if can and p.id ~= 0 then
						-- local durable = Tools.getShipMaxDurable( ship )
						local maxHp = p.attr[CONF.EShipAttr.kHP]
						local t = {p.id,v.ship_hp_list[p.position],maxHp}
						shipInfo[#shipInfo+1] = t
					end
				end
			end
			if Tools.isEmpty(shipInfo) == false then
				local item_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/teamNode.csb")
				for i=1,5 do
					item_node:getChildByName('FileNode_'..i):setVisible(false)
					item_node:getChildByName('text_jindu'..i):setVisible(false)
					item_node:getChildByName('Image_jindu'..i):setVisible(false)
					item_node:getChildByName('jdt_bottom'..i):setVisible(false)
					if i<= #shipInfo then
						item_node:getChildByName('FileNode_'..i):setVisible(true)
						item_node:getChildByName('text_jindu'..i):setVisible(true)
						item_node:getChildByName('Image_jindu'..i):setVisible(true)
						item_node:getChildByName('jdt_bottom'..i):setVisible(true)
					end
				end
				item_node:getChildByName('Text_1'):setString(CONF:getStringValue(teamName[teamNum])..':  '..v.info.nickname)
				teamNum = teamNum + 1
				for i,p in ipairs(shipInfo) do
					if item_node:getChildByName('FileNode_'..i) then
						local cfg_ship = CONF.AIRSHIP.get(tonumber(p[1]))
						local progress = require("util.ScaleProgressDelegate"):create(item_node:getChildByName('Image_jindu'..i), 90)
						local pro = math.ceil(p[2]/p[3]*1000)/10
						progress:setPercentage(pro)
						local p2 = math.ceil(p[2]/p[3]*1000)/10
						item_node:getChildByName('text_jindu'..i):setString(p2..'%')
						item_node:getChildByName('FileNode_'..i):getChildByName('icon'):loadTexture('ShipImage/'..cfg_ship.ICON_ID..'.png')
						-- if cfg_ship.QUALITY == EDevelopStatus.kHas then
							item_node:getChildByName('FileNode_'..i):getChildByName('background'):loadTexture("RankLayer/ui/ui_avatar_" .. cfg_ship.QUALITY .. ".png")
						-- else
							-- item_node:getChildByName('FileNode_'..i):getChildByName('background'):loadTexture("RankLayer/ui/ui_avatar2_" .. cfg_ship.QUALITY .. ".png")
						-- end
					end
				end
				list:addElement(item_node)
			end
		end
	end
	local function onScrollViewEvent(sender, evenType)
		if shipListInfo and armyNum >= 2 then
	        if evenType == ccui.ScrollviewEventType.bounceTop then       
		        node_detail:getChildByName('Image_jiantou'):setVisible(true)
	        elseif evenType == ccui.ScrollviewEventType.bounceBottom then
	        	node_detail:getChildByName('Image_jiantou'):setVisible(false)
	        end
	    end
    end
	node_detail:getChildByName('ship_list'):addEventListener(onScrollViewEvent)
	setJinDun(node_detail:getChildByName('des5'):isVisible())
	if (data.base_data.user_name ~= player:getName() and (player:getGroupName( ) ==  otherUserInfo.group_nickname and player:getGroupName( ) ~= "") ) then
		setJinDun(false)
	end

	-- ADD WJJ 20180727
	require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQuanMianPing_Yuzhou_Xinxi(self)

end


function PlanetDetailType_base:onExitTransitionStart()

	printInfo("PlanetDetailType_base:onExitTransitionStart()")
	if schedulerSingle1 ~= nil then
		scheduler:unscheduleScriptEntry(schedulerSingle1)
	 	schedulerSingle1 = nil
	end

	if schedulerShield ~= nil then
		scheduler:unscheduleScriptEntry(schedulerShield)
	 	schedulerShield = nil
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

return PlanetDetailType_base