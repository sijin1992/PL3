
local tips = require("util.TipsMessage"):getInstance()

local EDevelopStatus = require("app.views.ShipDevelopScene.DevelopStatus")

local gl = require("util.GlobalLoading"):getInstance()

local player = require("app.Player"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local path_reach = require('PathReach'):create()

local messageBox = require("util.MessageBox"):getInstance()

local planetManager = require('app.views.PlanetScene.Manager.PlanetManager'):getInstance()

local PlanetDetailType_cityRes = class("PlanetDetailType_cityRes", cc.load("mvc").ViewBase)

PlanetDetailType_cityRes.RESOURCE_FILENAME = "PlanetScene/PlanetDetailLayer.csb"

PlanetDetailType_cityRes.RUN_TIMELINE = true

PlanetDetailType_cityRes.NEED_ADJUST_POSITION = true

PlanetDetailType_cityRes.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local scheduler = cc.Director:getInstance():getScheduler()
local schedulerSingle1 = nil
local schedulerSingle2 = nil
local schedulerSingle3 = nil
-- 1:base 2:res 3:ruins 4:boss 5:city

function PlanetDetailType_cityRes:OnBtnClick(event)
	if event.name == 'ended' then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
			self:getApp():removeTopView()
		end
	end
end
--data = {guid = }

function PlanetDetailType_cityRes:onCreate(data)
	self._data = data
end

function PlanetDetailType_cityRes:onEnter()
  
	printInfo("PlanetDetailType_cityRes:onEnter()")

end

function PlanetDetailType_cityRes:onExit()
	
	printInfo("PlanetDetailType_cityRes:onExit()")
end

local function getTime(data)
	local speeds = CONF.PARAM.get('planet_move_speed').PARAM
	local addSpeed = CONF.PLANET_RES.get(data.city_res_data.id).COLLECT
	local speed = speeds[1] + addSpeed
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

function PlanetDetailType_cityRes:updateChat()
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

function PlanetDetailType_cityRes:setStrengthPercent( )

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

function PlanetDetailType_cityRes:getFreshRES()
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

function PlanetDetailType_cityRes:onEnterTransitionFinish()
	printInfo("PlanetDetailType_cityRes:onEnterTransitionFinish()")
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

	if schedulerSingle1 ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerSingle1)
	 	schedulerSingle1 = nil
	end
	if schedulerSingle2 ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerSingle2)
	 	schedulerSingle2 = nil
	end
	if schedulerSingle3 ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerSingle3)
	 	schedulerSingle3 = nil
	end
	local userInfoNode = require("util.UserInfoNode"):create()
	userInfoNode:init(self)
	userInfoNode:setName("userInfoNode")
	if rn:getChildByName("info_node"):getChildByName('userInfoNode') == nil then
		rn:getChildByName("info_node"):addChild(userInfoNode)
	end
	
	local function recvMsg()
		-- print("PlanetDetailLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_RESP") then
			local proto = Tools.decode("GetGroupResp",strData)
			print("GetGroupResp result "..proto.result)
			if proto.result == 0 then
				if self.ower_text then 
					self.ower_text:setString(proto.other_group_info.nickname)
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_RESP") then
			local proto = Tools.decode("CmdGetOtherUserInfoListResp",strData)
			print("PlanetDetailType_cityRes CmdGetOtherUserInfoListResp")
			print("result ",proto.result)
			if proto.result == 0 then
				if not self.svd then return end
				self.svd:clear()
				for k,v in ipairs(proto.info_list) do
					local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/nameNode.csb")
					node:getChildByName("name"):setString(v.nickname)
					node:getChildByName("level"):setString("Lv."..v.level)
					node:getChildByName("level"):setPositionX(node:getChildByName("name"):getPositionX()+node:getChildByName("name"):getContentSize().width+5)
					self.svd:addElement(node)
				end
			end
		end
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self:updateChat()
	-- self:getFreshRES()
	self:showPlanetInfo(info)
end

function PlanetDetailType_cityRes:showPlanetInfo(data)-- 资源
	self.ower_text = nil
	if Tools.isEmpty(data.city_res_data) then return end
	local rn = self:getResourceNode()
	if rn:getChildByName('node_detail') == nil then
		local node_detail = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/city_res.csb")
		node_detail:setPosition(rn:getChildByName('Node_detail'):getPosition())
		node_detail:setName('node_detail')
		rn:addChild(node_detail)
	end
	local cfg_res = CONF.PLANET_RES.get(data.city_res_data.id)
	local res_id = cfg_res.RES_ID
	local res_name = res_id..'.png'
	local node_detail = rn:getChildByName('node_detail')
	if not self.svd then
		self.svd = require("util.ScrollViewDelegate"):create(node_detail:getChildByName("list"),cc.size(0,2), cc.size(460,40))
		node_detail:getChildByName("list"):setScrollBarEnabled(false)
	else
		self.svd:clear()
	end
	rn:getChildByName('planteName'):setString(CONF:getStringValue(cfg_res.MEMO_ID))
	if res_name then
		rn:getChildByName('Image_2'):setTexture(string.format("PlanetIcon2/"..res_name))
	end
	local sizeY = rn:getChildByName('Image_2'):getPositionY()-rn:getChildByName('Image_2'):getContentSize().height/2-rn:getChildByName('planteName'):getContentSize().height/2
	local progress = require("util.ScaleProgressDelegate"):create(node_detail:getChildByName('Image_jindu'), 460)
	node_detail:getChildByName("name_str"):setString(CONF:getStringValue(cfg_res.NAME))
	node_detail:getChildByName("level_str"):setString(CONF:getStringValue("level")..": ")
	node_detail:getChildByName("level_text"):setString("Lv."..cfg_res.LEVEL)
	node_detail:getChildByName("num_str"):setString(CONF:getStringValue("total_resources")..": ")
	node_detail:getChildByName("num_text"):setString(data.city_res_data.cur_storage.."/"..cfg_res.STORAGE)
	node_detail:getChildByName("ower_str"):setString(CONF:getStringValue("occupation")..": ")
	node_detail:getChildByName("ower_text"):setString("—")
	self.ower_text = node_detail:getChildByName("ower_text")
	node_detail:getChildByName("text_str"):setString(CONF:getStringValue("yidong_time")..": ")
	local str_time = getTime(data) and formatTime(getTime(data)) or "—"
	node_detail:getChildByName("time_text"):setString(str_time)
	node_detail:getChildByName("text_jindu"):setString("")
	node_detail:getChildByName("pnum_str"):setString(CONF:getStringValue("collect_limit")..": ")
	node_detail:getChildByName("pnum_text"):setString("") 
	node_detail:getChildByName("list"):setVisible(false)
	node_detail:getChildByName("Image_85"):setVisible(false)
	node_detail:getChildByName("Image_jindu"):setVisible(false)
	node_detail:getChildByName("jdt_bottom"):setVisible(false)
	node_detail:getChildByName("text_jindu"):setVisible(false)
	node_detail:getChildByName("pnum_str"):setVisible(false)
	node_detail:getChildByName("pnum_text"):setVisible(false)
	node_detail:getChildByName("Button_1"):getChildByName("text"):setString(CONF:getStringValue("expedite"))
	node_detail:getChildByName("Button_1"):setVisible(false)
	local isMyGroup = false
	if  data.city_res_data.groupid and data.city_res_data.groupid ~= "" then
		node_detail:getChildByName("ower_text"):setString("—")
		if data.city_res_data.groupid == player:getGroupData().groupid then
			isMyGroup = true
		else
			local strData = Tools.encode("GetGroupReq", {
				-- groupid = player:getGroupData().groupid,
				groupid = data.city_res_data.groupid,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_REQ"),strData)
		end
	end
	if isMyGroup then
		node_detail:getChildByName("ower_text"):setString(player:getGroupName())
		node_detail:getChildByName("ower_text"):setTextColor(cc.c4b(CONF.ETextColor.kGreen.r, CONF.ETextColor.kGreen.g, CONF.ETextColor.kGreen.b, 255))
		-- node_detail:getChildByName("ower_text"):enableShadow(cc.c4b(CONF.ETextColor.kGreen.r, CONF.ETextColor.kGreen.g, CONF.ETextColor.kGreen.b, 255), cc.size(0.5,0.5))
		node_detail:getChildByName("list"):setVisible(true)
		node_detail:getChildByName("Image_85"):setVisible(true)
		node_detail:getChildByName("pnum_str"):setVisible(true)
		node_detail:getChildByName("pnum_text"):setVisible(true)
		node_detail:getChildByName("pnum_text"):setString("0/"..tostring(cfg_res.LOAD_NUM))
		local userNames = {}
		if data.city_res_data.restore_start_time == 0 then
			local coloct = data.city_res_data.cur_storage
			if Tools.isEmpty(data.city_res_data.user_list) == false then
				for k,v in ipairs(data.city_res_data.user_list) do

					local collect_speed = v.collect_speed
					local res_conf = CONF.PLANET_RES.get(v.id)
					if res_conf then
						collect_speed =  player:getValueByTechnologyAdditionGroup(collect_speed, CONF.ETechTarget_1.kWorldRes, res_conf.TYPE, CONF.ETechTarget_3_Res.kCollect)
					end


					local co = (player:getServerTime() - v.begin_time) * collect_speed
					if co < 0 then co = 0 end
					coloct = coloct - co
				end
			end
			node_detail:getChildByName("num_text"):setString(coloct.."/"..cfg_res.STORAGE)
			local myCollect = false
			if Tools.isEmpty(data.city_res_data.user_list) == false then
				node_detail:getChildByName("pnum_text"):setString(#data.city_res_data.user_list.."/"..cfg_res.LOAD_NUM)
				for k,v in ipairs(data.city_res_data.user_list) do
					if v.user_name == player:getName() then
						myCollect = true
						node_detail:getChildByName("text_str"):setString(CONF:getStringValue("collect_time")..": ")
						node_detail:getChildByName("Image_jindu"):setVisible(true)
						node_detail:getChildByName("jdt_bottom"):setVisible(true)
						node_detail:getChildByName("text_jindu"):setVisible(true)

						local collect_speed = v.collect_speed
						local res_conf = CONF.PLANET_RES.get(v.id)
						if res_conf then
							collect_speed =  player:getValueByTechnologyAdditionGroup(collect_speed, CONF.ETechTarget_1.kWorldRes, res_conf.TYPE, CONF.ETechTarget_3_Res.kCollect)
						end

						local time = data.city_res_data.cur_storage/collect_speed
						local function update()
							local data = planetManager:getInfoByNodeGUID( self._data.node_id, self._data.guid )
							local collectRes = (player:getServerTime() - v.begin_time) * collect_speed
							if collectRes < 0 then collectRes = 0 end
							local carry = cfg_res.CARRY == 0 and 1 or cfg_res.CARRY
							if collectRes > carry then collectRes = carry end
							local time = (carry - collectRes) / collect_speed
							if time < 0 then time = 0 end
							node_detail:getChildByName("time_text"):setString(formatTime(math.floor(time)))
							local p = collectRes/carry*100
							if p > 100 then p = 100 end
							progress:setPercentage(p)
							node_detail:getChildByName("text_jindu"):setString(collectRes.."/"..carry)
							if time <= 0 or data.city_res_data.restore_start_time ~= 0 then
								if schedulerSingle1 ~= nil then
									scheduler:unscheduleScriptEntry(schedulerSingle1)
								 	schedulerSingle1 = nil
								end
							end
						end
						update()
						if schedulerSingle1 == nil and time > 0 then
							schedulerSingle1 = scheduler:scheduleScriptFunc(update,1,false)
						end
					end
					table.insert(userNames,v.user_name)
				end
				if Tools.isEmpty(userNames) == false then
					local strData = Tools.encode("CmdGetOtherUserInfoListReq", {
						user_name_list = userNames,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_REQ"),strData)
				end
			end
			if not myCollect then
				-- node_detail:getChildByName("pnum_str"):setPositionY(node_detail:getChildByName("pnum_str"):getPositionY()+20)
				-- node_detail:getChildByName("pnum_text"):setPositionY(node_detail:getChildByName("pnum_text"):getPositionY()+20)
				-- node_detail:getChildByName("list"):setPositionY(node_detail:getChildByName("list"):getPositionY()+20)
				-- node_detail:getChildByName("Image_85"):setPositionY(node_detail:getChildByName("Image_85"):getPositionY()+20)
			end
			local function updateTeam()
				local team = {}
				local data = planetManager:getInfoByNodeGUID( self._data.node_id, self._data.guid )
				if data.city_res_data.restore_start_time ~= 0 then
					if schedulerSingle3 ~= nil then
						scheduler:unscheduleScriptEntry(schedulerSingle3)
					 	schedulerSingle3 = nil
					end
					return
				end
				if Tools.isEmpty(data.city_res_data.user_list) == false then
					for k,v in ipairs(data.city_res_data.user_list) do
						table.insert(team,v.user_name)
					end
				end
				local same = true
				for k,v in ipairs(team) do
					if not userNames[k] then
						same = false
						break
					end
					if v ~= userNames[k] then
						same = false
						break
					end
				end
				local coloct = data.city_res_data.cur_storage
				if Tools.isEmpty(data.city_res_data.user_list) == false then
					for k,v in ipairs(data.city_res_data.user_list) do

						local collect_speed = v.collect_speed
						local res_conf = CONF.PLANET_RES.get(v.id)
						if res_conf then
							collect_speed =  player:getValueByTechnologyAdditionGroup(collect_speed, CONF.ETechTarget_1.kWorldRes, res_conf.TYPE, CONF.ETechTarget_3_Res.kCollect)
						end

						local co = (player:getServerTime() - v.begin_time) * collect_speed
						if co < 0 then co = 0 end
						coloct = coloct - co
					end
				end
				node_detail:getChildByName("num_text"):setString(coloct.."/"..cfg_res.STORAGE)
				if #team ~= #userNames or not same then
					self:showPlanetInfo(data)
					userNames = team
				end
			end
			if schedulerSingle3 == nil  then
				schedulerSingle3 = scheduler:scheduleScriptFunc(updateTeam,1,false)
			end
		else
			node_detail:getChildByName("list"):setVisible(false)
			node_detail:getChildByName("Image_85"):setVisible(false)
			node_detail:getChildByName("Image_jindu"):setVisible(false)
			node_detail:getChildByName("jdt_bottom"):setVisible(false)
			node_detail:getChildByName("text_jindu"):setVisible(false)
			node_detail:getChildByName("pnum_str"):setVisible(false)
			node_detail:getChildByName("pnum_text"):setVisible(false)
			node_detail:getChildByName("text_str"):setString(CONF:getStringValue("repair_time")..": ")
			local time = player:getServerTime() - data.city_res_data.restore_start_time
			node_detail:getChildByName('time_text'):setString(formatTime(CONF.PLANETCITYRES.get(data.city_res_data.id).TIME - time))
			node_detail:getChildByName("Button_1"):setVisible(false)
			node_detail:getChildByName("Button_1"):addClickEventListener(function()
				local time =  player:getServerTime() - data.city_res_data.restore_start_time
				if player:getMoney() <= player:getSpeedUpNeedMoney(time) then
					tips:tips(CONF:getStringValue("no enought credit"))
					return
				end

				end)

			if CONF.PLANETCITYRES.get(data.city_res_data.id).TIME - time > 0 then
				local func = function()
					local time =  player:getServerTime() - data.city_res_data.restore_start_time
					node_detail:getChildByName('time_text'):setString(formatTime(CONF.PLANETCITYRES.get(data.city_res_data.id).TIME- time) )
					if time <= 0 or data.city_res_data.restore_start_time == 0 then
						if schedulerSingle2 ~= nil then
							scheduler:unscheduleScriptEntry(schedulerSingle2)
						 	schedulerSingle2 = nil
						end
					end
				end
				if schedulerSingle2 == nil then
					schedulerSingle2 = scheduler:scheduleScriptFunc(func,1,false)
				end
			end
		end
	else
		node_detail:getChildByName("num_text"):setString(cfg_res.STORAGE)
		if  data.city_res_data.groupid and data.city_res_data.groupid ~= "" then
			node_detail:getChildByName("ower_text"):setTextColor(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255))
			-- node_detail:getChildByName("ower_text"):enableShadow(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255), cc.size(0.5,0.5))
		end
	end
	node_detail:getChildByName('level_text'):setPositionX(node_detail:getChildByName('level_str'):getPositionX()+node_detail:getChildByName('level_str'):getContentSize().width)
	node_detail:getChildByName('num_text'):setPositionX(node_detail:getChildByName('num_str'):getPositionX()+node_detail:getChildByName('num_str'):getContentSize().width)
	node_detail:getChildByName('ower_text'):setPositionX(node_detail:getChildByName('ower_str'):getPositionX()+node_detail:getChildByName('ower_str'):getContentSize().width)
	node_detail:getChildByName('time_text'):setPositionX(node_detail:getChildByName('text_str'):getPositionX()+node_detail:getChildByName('text_str'):getContentSize().width)
	node_detail:getChildByName('pnum_text'):setPositionX(node_detail:getChildByName('pnum_str'):getPositionX()+node_detail:getChildByName('pnum_str'):getContentSize().width)
end

function PlanetDetailType_cityRes:onExitTransitionStart()

	printInfo("PlanetDetailType_cityRes:onExitTransitionStart()")
	if schedulerSingle1 ~= nil then
		scheduler:unscheduleScriptEntry(schedulerSingle1)
	 	schedulerSingle1 = nil
	end
	if schedulerSingle2 ~= nil then
		scheduler:unscheduleScriptEntry(schedulerSingle2)
	 	schedulerSingle2 = nil
	end
	if schedulerSingle3 ~= nil then
		scheduler:unscheduleScriptEntry(schedulerSingle3)
	 	schedulerSingle3 = nil
	end
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.seeChatListener_)
	eventDispatcher:removeEventListener(self.chatRecvlistener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.worldListener_)
	eventDispatcher:removeEventListener(self.strengthListener_)
	eventDispatcher:removeEventListener(self.recvlistener_)

	if self.svd then
		self.svd:clear()
	end
end

return PlanetDetailType_cityRes