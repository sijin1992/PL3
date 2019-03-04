
local tips = require("util.TipsMessage"):getInstance()

local EDevelopStatus = require("app.views.ShipDevelopScene.DevelopStatus")

local gl = require("util.GlobalLoading"):getInstance()

local player = require("app.Player"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local path_reach = require('PathReach'):create()

local messageBox = require("util.MessageBox"):getInstance()

local planetManager = require('app.views.PlanetScene.Manager.PlanetManager'):getInstance()

local PlanetDetailType_boss = class("PlanetDetailType_boss", cc.load("mvc").ViewBase)

PlanetDetailType_boss.RESOURCE_FILENAME = "PlanetScene/PlanetDetailLayer.csb"

PlanetDetailType_boss.RUN_TIMELINE = true

PlanetDetailType_boss.NEED_ADJUST_POSITION = true

PlanetDetailType_boss.RESOURCE_BINDING = {
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
-- 1:base 2:res 3:ruins 4:boss 5:city
local infoType = {
	BASE = 1,
	RES = 2 ,
	RUINS = 3 ,
	BOSS = 4 ,
	CITY = 5,
}


function PlanetDetailType_boss:OnBtnClick(event)
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

function PlanetDetailType_boss:onCreate(data)
	self._data = data
end

function PlanetDetailType_boss:onEnter()
  
	printInfo("PlanetDetailType_boss:onEnter()")

end

function PlanetDetailType_boss:onExit()
	
	printInfo("PlanetDetailType_boss:onExit()")
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

function PlanetDetailType_boss:onEnterTransitionFinish()
	printInfo("PlanetDetailType_boss:onEnterTransitionFinish()")
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
	if schedulerSingle1 ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerSingle1)
	 	schedulerSingle1 = nil
	end
	local info = planetManager:getInfoByNodeGUID( self._data.node_id, self._data.guid )
	if info then
		self:showPlanetInfo(info)
	end
	local userInfoNode = require("util.UserInfoNode"):create()
	userInfoNode:init(self)
	userInfoNode:setName("userInfoNode")
	if rn:getChildByName("info_node"):getChildByName('userInfoNode') == nil then
		rn:getChildByName("info_node"):addChild(userInfoNode)
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
	-- rn:getChildByName('bottom_top3'):addClickEventListener(function() end)
	self:updateChat()
	-- self:getFreshRES()
end

function PlanetDetailType_boss:updateChat()
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

function PlanetDetailType_boss:setStrengthPercent( )

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

function PlanetDetailType_boss:getFreshRES()
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
function PlanetDetailType_boss:showPlanetInfo(data) -- 人工智能
	if data.type ~= infoType.BOSS then
		return 
	end
	if not data.boss_data or not next(data.boss_data) then
		return
	end
	self:setBossNode(data)
end

function PlanetDetailType_boss:setBossNode(data)
	local rn = self:getResourceNode()
	local cfg = CONF.PLANETBOSS.get(data.boss_data.id)
	local res_name = cfg.ICON..'.png'
	rn:getChildByName('planteName'):setString(CONF:getStringValue(cfg.NAME))
	if res_name then
		rn:getChildByName('Image_2'):setTexture(string.format("PlanetIcon2/"..res_name))
	end
	local node_detail = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/boss.csb")
	node_detail:setPosition(rn:getChildByName('Node_detail'):getPosition())
	node_detail:setName('node_detail')
	rn:addChild(node_detail)
	local resName = node_detail:getChildByName('resName') -- 物件名称
	local des_level = node_detail:getChildByName('des_level') -- 等级描述 
	local text_levelnum = node_detail:getChildByName('text_levelnum') -- 等级 
	local text_hp = node_detail:getChildByName('text_hp') --血量 
	local Image_jindu = node_detail:getChildByName('Image_jindu') --进度条 
	local jdt_bottom = node_detail:getChildByName('jdt_bottom') --进度条底 
	local text_jindu = node_detail:getChildByName('text_jindu') --进度条数字 
	local text_tili = node_detail:getChildByName('text_tili') --消耗体力：数字 
	local text_time = node_detail:getChildByName('text_time') -- 剩余时间
	local text_timenum = node_detail:getChildByName('text_timenum') --剩余时间值 
	local text_time1 = node_detail:getChildByName('text_time1') -- 移动时间
	local text_timenum1 = node_detail:getChildByName('text_timenum1') --移动时间值 
	local text_name = node_detail:getChildByName('text_name') --获得概率 
	local ship_list = node_detail:getChildByName('ship_list') -- list获得物品
	local text_lianxu = node_detail:getChildByName('text_lianxu') -- 连续攻击次数：值
	local text_jiacheng = node_detail:getChildByName('text_jiacheng') -- 伤害加成：值
	local text_jiachengTime = node_detail:getChildByName('text_jiachengTime') -- 加成剩余时间：值
	local text_des = node_detail:getChildByName('text_des') --boss战斗状态显示 
	local progress = require("util.ScaleProgressDelegate"):create(Image_jindu, 260)
	local boss_name = CONF:getStringValue(cfg.NAME)
	local list = require("util.ScrollViewDelegate"):create(ship_list,cc.size(0,10), cc.size(90,90))
	ship_list:setScrollBarEnabled(false)
	for i,id in ipairs(cfg.SHOWCASING) do
		local itemNode = require("util.ItemNode"):create():init(id)
		list:addElement(itemNode)
	end
	local item_count = ship_list:getChildrenCount()
	local size_width = ship_list:getContentSize().width
	local can_item_count = math.floor(size_width/90)
	if item_count <= can_item_count then
		ship_list:setTouchEnabled(false)
	end
	local update = function()
		local data = planetManager:getInfoByNodeGUID( self._data.node_id, self._data.guid )
		if not data then return end
		resName:setString(boss_name)
		des_level:setString(CONF:getStringValue('level_ji')..':  ')
		text_levelnum:setString(cfg.LV)
		text_hp:setString(CONF:getStringValue('Attr_2')..':  ')
		local totalHp = 0
		for i,ship_id in ipairs(cfg.MONSTER_LIST) do
			if ship_id ~= 0 then
				local cfg_ship = CONF.AIRSHIP.get(math.abs(ship_id))
				totalHp = totalHp + cfg_ship.LIFE
				break
			end
		end
		local bossHp = 0
		if Tools.isEmpty(data.boss_data.monster_hp_list) == false then
			for k,v in ipairs(data.boss_data.monster_hp_list) do
				bossHp = bossHp + v
			end
		else
			bossHp = totalHp
		end
		local p_value = math.ceil(bossHp/totalHp*1000)/10
		progress:setPercentage(p_value)
		text_jindu:setString(p_value..'%')
		if p_value <= 0 then
			if schedulerSingle1 ~= nil then
			 	scheduler:unscheduleScriptEntry(schedulerSingle1)
			 	schedulerSingle1 = nil
			 	self:getApp():removeTopView()
			 	return
			end
		end 
		text_tili:setString(CONF:getStringValue('use strength')..':  '..cfg.STRENGTH)
		text_time:setString(CONF:getStringValue('reside_time')..':  ')
		-- create_time
		-- user_info.start_time
		--getTime(data)
		local boss_time = cfg.REMOVE_TIME - player:getServerTime() + data.boss_data.create_time
		text_timenum:setString(formatTime(boss_time))
		if boss_time <= 0 then
			if schedulerSingle1 ~= nil then
			 	scheduler:unscheduleScriptEntry(schedulerSingle1)
			 	schedulerSingle1 = nil
			 	self:getApp():removeTopView()
			 	return
			end
		end
		text_time1:setString(CONF:getStringValue('yidong_time')..':  ')
		text_timenum1:setString(formatTime(getTime(data)))
		text_name:setString(CONF:getStringValue('gailv_huode'))
		text_lianxu:setString(CONF:getStringValue('base_damage'))

		local army_already = false
		if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
			if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
				for k,v in pairs(planetManager:getPlanetUser( ).army_list) do
					if v.element_global_key == data.global_key then
						army_already = true
						break
					end
				end
			end
		end
		local myArmy = {}
		if data.boss_data.user_info.user_name == player:getName() then
			myArmy = data.boss_data.user_info
		end
		text_des:setString(CONF:getStringValue('Being attacked'))
		if army_already then
			text_des:setVisible(true)
		else
			text_des:setVisible(false)
		end
		
		if Tools.isEmpty(myArmy) == false then
			text_jiacheng:setVisible(true)
			text_jiachengTime:setVisible(true)
			text_lianxu:setString(CONF:getStringValue('Continuous attack')..':  '.. myArmy.attack_count)
			local tech_id
			if #cfg.ATTACK_BUFF_LIST < myArmy.attack_count then
				tech_id = cfg.ATTACK_BUFF_LIST[#cfg.ATTACK_BUFF_LIST]
			else
				tech_id = cfg.ATTACK_BUFF_LIST[myArmy.attack_count]
			end
			local techAdd_num = 0
			if tech_id then
				local cfg_tech = CONF.TECHNOLOGY.get(tech_id)
				if cfg_tech.TECHNOLOGY_TARGET_1 == 3 and cfg_tech.TECHNOLOGY_TARGET_2 == 2 then
					local result = false
					for k,num in pairs(CONF.ShipPercentAttrs) do
						if cfg_tech.TECHNOLOGY_TARGET_3 == num then
							result = true
						end
					end
					techAdd_num = cfg_tech.TECHNOLOGY_ATTR_PERCENT and cfg_tech.TECHNOLOGY_ATTR_PERCENT or 0
					if result then
						techAdd_num = techAdd_num..'%'
					end
				end
			end
			text_jiacheng:setString(CONF:getStringValue('add damage')..':  '..techAdd_num)
			local addBuff_time = cfg.BUFF_TIME - player:getServerTime() + myArmy.start_time
			if addBuff_time <= 0 then
				-- if schedulerSingle1 ~= nil then
				--  	scheduler:unscheduleScriptEntry(schedulerSingle1)
				--  	schedulerSingle1 = nil
				--  	self:getApp():removeTopView()
				--  	return
				-- end
				text_lianxu:setString(CONF:getStringValue('base_damage'))
				text_jiacheng:setVisible(false)
				text_jiachengTime:setVisible(false)
			end
			local min = math.modf(addBuff_time/60)
			local sec = addBuff_time - min*60
			if min < 10 then min = '0'..min end
			if sec < 10 then sec = '0'..sec end
			text_jiachengTime:setString(CONF:getStringValue('damage_time')..':  '..min..':'..sec)
		else
			text_jiacheng:setVisible(false)
			text_jiachengTime:setVisible(false)
		end
		text_levelnum:setPosition(des_level:getPositionX()+des_level:getContentSize().width,des_level:getPositionY())
		Image_jindu:setPosition(text_hp:getPositionX()+text_hp:getContentSize().width,text_hp:getPositionY())
		jdt_bottom:setPosition(Image_jindu:getPosition())
		text_jindu:setPosition(jdt_bottom:getPositionX()+jdt_bottom:getContentSize().width/2,jdt_bottom:getPositionY())
		text_timenum:setPosition(text_time:getPositionX()+text_time:getContentSize().width,text_time:getPositionY())
		text_timenum1:setPosition(text_time1:getPositionX()+text_time1:getContentSize().width,text_time1:getPositionY())
	end
	update()
	if schedulerSingle1 == nil then
		schedulerSingle1 = scheduler:scheduleScriptFunc(update,1,false)
	end
end


function PlanetDetailType_boss:onExitTransitionStart()

	printInfo("PlanetDetailType_boss:onExitTransitionStart()")
	if schedulerSingle1 ~= nil then
		scheduler:unscheduleScriptEntry(schedulerSingle1)
	 	schedulerSingle1 = nil
	end
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.seeChatListener_)
	eventDispatcher:removeEventListener(self.chatRecvlistener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.worldListener_)
	eventDispatcher:removeEventListener(self.strengthListener_)
end

return PlanetDetailType_boss