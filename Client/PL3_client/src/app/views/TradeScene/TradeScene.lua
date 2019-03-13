local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local TradeScene = class("TradeScene", cc.load("mvc").ViewBase)

TradeScene.RESOURCE_FILENAME = "TradeScene/TradeScene.csb"

TradeScene.RUN_TIMELINE = true

TradeScene.NEED_ADJUST_POSITION = true

TradeScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

function TradeScene:onCreate( data )
	self.data_ = data 
end


function TradeScene:onEnter()
  
	printInfo("TradeScene:onEnter()")

end

function TradeScene:onExit()
	
	printInfo("TradeScene:onExit()")
end

function TradeScene:resetRes( ... )
	local rn = self:getResourceNode()
	local res_node = rn:getChildByName("res_node")
	for i=1,4 do
		res_node:getChildByName("res_text_"..i):setString(formatRes(player:getResByIndex(i)))
	end
	res_node:getChildByName("res_text_5"):setString(tostring(player:getMoney()))--player:getMoney())
end

function TradeScene:resetUI( ... )
	local info = player:getBuildingInfo(CONF.EBuilding.kTrade)
	local conf = CONF.BUILDING_15.get(self.building_level)

	local rn = self:getResourceNode()
	local info_node = rn:getChildByName("info_node")
	info_node:getChildByName("next_level"):setString(CONF:getStringValue("BuildingName_15").." Lv."..self.building_level)
	info_node:getChildByName("army"):setString(CONF:getStringValue("total consume"))
	info_node:getChildByName("res"):setString(CONF:getStringValue("everyday output"))
	info_node:getChildByName("planet"):setString(CONF:getStringValue("reserve max"))

	if conf.SHOW_EXP then
		info_node:getChildByName("army_now"):setString(conf.SHOW_EXP)
	else
		info_node:getChildByName("army_now"):setString(CONF:getStringValue("MYZX max"))
	end


	info_node:getChildByName("res_now"):setString(conf.PRODUCTION_NUM)
	info_node:getChildByName("planet_now"):setString(conf.STORAGE)

	if self.building_level == 1 then
		rn:getChildByName("icon_left"):setVisible(false)
	else
		rn:getChildByName("icon_left"):setVisible(true)
	end

	if self.building_level == CONF.BUILDING_15.count() then
		rn:getChildByName("icon_right"):setVisible(false)
	else
		rn:getChildByName("icon_right"):setVisible(true)
	end

	-- local cur_num = math.floor(Tools.mod(player:getServerTime() - player:getTradeData().last_product_time, CONF.BUILDING_15.get(info.level).PRODUCTION_TIME))
	local cur_num = math.floor((player:getServerTime() - player:getTradeData().last_product_time)/CONF.BUILDING_15.get(info.level).PRODUCTION_TIME)*CONF.BUILDING_15.get(info.level).PRODUCTION_NUM
	if cur_num > CONF.BUILDING_15.get(info.level).STORAGE then
		cur_num = CONF.BUILDING_15.get(info.level).STORAGE 
	end

	if cur_num < 0 then
		cur_num = 0
	end

	rn:getChildByName("right_money_num"):setString(cur_num)
	local time = CONF.BUILDING_15.get(info.level).PRODUCTION_TIME - ((player:getServerTime() - player:getTradeData().last_product_time)%CONF.BUILDING_15.get(info.level).PRODUCTION_TIME)

	if player:getTradeData().last_product_time > player:getServerTime() then
		time = CONF.BUILDING_15.get(info.level).PRODUCTION_TIME
	end

	rn:getChildByName("time"):setString(formatTime(time))

	local percent = ((player:getServerTime() - player:getTradeData().last_product_time)%CONF.BUILDING_15.get(info.level).PRODUCTION_TIME)/CONF.BUILDING_15.get(info.level).PRODUCTION_TIME
	if percent > 1 then
		percent = 1
	end

	if percent < 0 then
		percent = 0
	end

	rn:getChildByName("time_tiao"):setContentSize(cc.size(rn:getChildByName("time_tiao"):getTag()*percent, rn:getChildByName("time_tiao"):getContentSize().height))

	if cur_num <= 0 then
		rn:getChildByName("btn"):setEnabled(false)

	else
		rn:getChildByName("btn"):setEnabled(true)

	end

	if cur_num == CONF.BUILDING_15.get(info.level).STORAGE then
		rn:getChildByName("right_time_ins"):setVisible(false)
		rn:getChildByName("time_back"):setVisible(false)
		rn:getChildByName("time_tiao"):setVisible(false)
		rn:getChildByName("time"):setVisible(false)

		rn:getChildByName("right_money_num"):setTextColor(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255))
		-- rn:getChildByName("right_money_num"):enableShadow(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255), cc.size(0.5,0.5))

		rn:getChildByName("right_money_text"):setVisible(true)
	else
		rn:getChildByName("right_time_ins"):setVisible(true)
		rn:getChildByName("time_back"):setVisible(true)
		rn:getChildByName("time_tiao"):setVisible(true)
		rn:getChildByName("time"):setVisible(true)

		rn:getChildByName("right_money_num"):setTextColor(cc.c4b(CONF.ETextColor.kGreen.r, CONF.ETextColor.kGreen.g, CONF.ETextColor.kGreen.b, 255))
		-- rn:getChildByName("right_money_num"):enableShadow(cc.c4b(CONF.ETextColor.kGreen.r, CONF.ETextColor.kGreen.g, CONF.ETextColor.kGreen.b, 255), cc.size(0.5,0.5))

		rn:getChildByName("right_money_text"):setVisible(false)

	end

	if info.level == CONF.BUILDING_15.count() then
		rn:getChildByName("level_ins_1"):setVisible(false)
		rn:getChildByName("level_ins_icon"):setVisible(false)
		rn:getChildByName("level_ins_3"):setVisible(false)
		rn:getChildByName("level_ins_2"):setVisible(false)

		rn:getChildByName("MAX"):setVisible(true)
	else
		rn:getChildByName("level_ins_1"):setVisible(true)
		rn:getChildByName("level_ins_icon"):setVisible(true)
		rn:getChildByName("level_ins_3"):setVisible(true)
		rn:getChildByName("level_ins_2"):setVisible(true)

		rn:getChildByName("MAX"):setVisible(false)

	end

end


function TradeScene:onEnterTransitionFinish()
	printInfo("TradeScene:onEnterTransitionFinish()")

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kTrade)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("myzx_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end

	local info = player:getBuildingInfo(CONF.EBuilding.kTrade)
	self.building_level = info.level
	local conf =  CONF.BUILDING_15.get(info.level)

	local rn = self:getResourceNode()
	rn:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("Get"))
	rn:getChildByName("title"):setString(CONF:getStringValue("BuildingName_15"))
	rn:getChildByName("Image_22"):setPositionX(rn:getChildByName("title"):getPositionX()+rn:getChildByName("title"):getContentSize().width/2+5)
	rn:getChildByName("level_info"):setString(CONF:getStringValue("build level").." Lv."..info.level)
	local percent = 1
	if self.building_level == CONF.BUILDING_15.count() and conf.EXP == nil then
		rn:getChildByName("level_text"):setString(CONF:getStringValue("consume max"))
		rn:getChildByName("level_ins_2"):setString(CONF:getStringValue("consume max"))
	else
		percent = info.upgrade_exp/conf.EXP
		rn:getChildByName("level_text"):setString(info.upgrade_exp.."/"..conf.EXP)
		rn:getChildByName("level_ins_2"):setString(conf.EXP - info.upgrade_exp)
	end
	rn:getChildByName("level_ins_1"):setString(CONF:getStringValue("in consume"))
	rn:getChildByName("level_ins_3"):setString(CONF:getStringValue("may level"))

	rn:getChildByName("right_time_ins"):setString(CONF:getStringValue("The next output"))
	rn:getChildByName("right_money_text"):setString(CONF:getStringValue("trade max"))

	rn:getChildByName("level_ins_icon"):setPositionX(rn:getChildByName("level_ins_1"):getPositionX() + rn:getChildByName("level_ins_1"):getContentSize().width + 28)
	rn:getChildByName("level_ins_2"):setPositionX(rn:getChildByName("level_ins_icon"):getPositionX() + rn:getChildByName("level_ins_icon"):getContentSize().width/2 )
	rn:getChildByName("level_ins_3"):setPositionX(rn:getChildByName("level_ins_2"):getPositionX() + rn:getChildByName("level_ins_2"):getContentSize().width + 5)
	if percent > 1 then
		percent = 1
	end

	if percent < 0 then
		percent = 0
	end

	rn:getChildByName("level_tiao"):setContentSize(cc.size(rn:getChildByName("level_tiao"):getTag()*percent, rn:getChildByName("level_tiao"):getContentSize().height))

	rn:getChildByName("right_title"):setString(CONF:getStringValue("Trade output"))

	rn:getChildByName("close"):addClickEventListener(function ( ... )
		self:getApp():popView()
	end)

	local res_node = rn:getChildByName("res_node")
	res_node:getChildByName("money_add"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self:getParent(), {index = 1})
		self:getParent():addChild(rechargeNode)
	end)

	res_node:getChildByName("touch1"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self:getParent(), {index = 1})
		self:getParent():addChild(rechargeNode)
	end)

	rn:getChildByName("icon_left"):addClickEventListener(function ( ... )
		if self.building_level > 1 then
			self.building_level = self.building_level - 1
			self:resetUI()
		end
	end)

	rn:getChildByName("icon_right"):addClickEventListener(function ( ... )
		if self.building_level < CONF.BUILDING_15.count() then
			self.building_level = self.building_level + 1
			self:resetUI()
		end
	end)

	rn:getChildByName("btn"):addClickEventListener(function ( ... )
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRADE_GET_MONEY_REQ"),"0")
		gl:retainLoading()
	end)


	self:resetRes()
	self:resetUI()

	local strData = Tools.encode("BuildingUpdateReq", {
	   index = 15,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPDATE_REQ"),strData)
	-- gl:retainLoading()

	local function update(dt)
		self:resetUI()	
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)
	

	local function recvMsg()
		print("TradeScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_TRADE_GET_MONEY_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TradeGetMoneyResp",strData)
			print("CMD_TRADE_GET_MONEY_RESP result",proto.result)

			if proto.result == 0 then
				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				self:resetUI()
			end
		-- elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPDATE_RESP") then

		-- 	gl:releaseLoading()

		-- 	local proto = Tools.decode("BuildingUpdateResp",strData)
		-- 	print("CMD_BUILDING_UPDATE_RESP result",proto.result)

		-- 	if proto.result == 0 then

		-- 		print("trade BuildingUpdateResp", proto.index)
				

		-- 		if proto.index == 15 then
		-- 			self:resetUI()
		-- 		end

		-- 	end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		self:resetRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		self:resetRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)

end

function TradeScene:onExitTransitionStart()

	printInfo("TradeScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)


	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return TradeScene