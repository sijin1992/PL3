local player = require("app.Player"):getInstance()
local tips = require("util.TipsMessage"):getInstance()
local scheduler = cc.Director:getInstance():getScheduler()
local messageBox = require("util.MessageBox"):getInstance()
local PlanetAddSpeedLayer = class("PlanetAddSpeedLayer", cc.load("mvc").ViewBase)

PlanetAddSpeedLayer.RESOURCE_FILENAME = "PlanetScene/otherNodeLayer/chuzheng_addSpeedLayer.csb"
PlanetAddSpeedLayer.NEED_ADJUST_POSITION = true

local schedulerEntry = nil

function PlanetAddSpeedLayer:onCreate( data )
	self.data_ = data
end

function PlanetAddSpeedLayer:resetList( ... )


	self.svd_:clear()

	local item = CONF.PARAM.get("speed_item").PARAM
	for k,v in ipairs(item) do
		local conf = CONF.ITEM.get(v)

		local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/otherNodeLayer/addSpeedNode.csb")
		node:getChildByName("Text_name"):setString(CONF:getStringValue(conf.NAME_ID))
		node:getChildByName("Text_num"):setString(CONF:getStringValue("have")..":")
		node:getChildByName("Text_num_"):setString(player:getItemNumByID(v))
		node:getChildByName("Text_num_"):setPositionX(node:getChildByName("Text_num"):getPositionX() + node:getChildByName("Text_num"):getContentSize().width)
		node:getChildByName("Text_des"):setString(CONF:getStringValue(conf.MEMO_ID))

		node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("use"))

		if player:getItemNumByID(v) <= 0 then
			node:getChildByName("btn"):setEnabled(false)
			-- node:getChildByName("btn"):getChildByName("text"):setVisible(false)
			-- node:getChildByName("btn"):getChildByName("icon"):setVisible(true)
			-- node:getChildByName("btn"):getChildByName("num"):setVisible(true)

			-- node:getChildByName("btn"):getChildByName("num"):setString(CONF.ITEM.get(v).BUY_VALUE)
		end

		node:getChildByName("btn"):addClickEventListener(function ( ... )
			playEffectSound("sound/system/click.mp3")

			if player:getItemNumByID(v) > 0 then

				local strData = Tools.encode("PlanetSpeedUpReq", {
					army_key = player:getName().."_"..self.data_.army_info.guid,
					type = k,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_SPEED_UP_REQ"),strData)

				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
				self:getApp():removeTopView()

			else
				local function func( ... )
					if player:getMoney() < CONF.ITEM.get(v).BUY_VALUE then
						local function func()
							local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

							rechargeNode:init(self, {index = 1})
							self:addChild(rechargeNode)
						end

						local messageBox = require("util.MessageBox"):getInstance()
						messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
						return
					end

					local strData = Tools.encode("PlanetSpeedUpReq", {
						army_key = player:getName().."_"..self.data_.army_info.guid,
						type = k,
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_SPEED_UP_REQ"),strData)

					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
					self:getApp():removeTopView()

				end

				local node = require("util.TipsNode"):createWithBuyNode("goumai?", CONF.ITEM.get(v).BUY_VALUE, func)

				self:addChild(node)
				tipsAction(node)

			end
		end)

		local item = require("util.ItemNode"):create():init(v)
		item:setPosition(node:getChildByName('Node_item'):getPosition())
		node:addChild(item)
		self.svd_:addElement(node)
	end
end

function PlanetAddSpeedLayer:onEnterTransitionFinish()
	printInfo("PlanetAddSpeedLayer:onEnterTransitionFinish()")

	-- local event = cc.EventCustom:new("seeShipUpdated")
	-- event.guid = self.data_.army_info.guid
	-- cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

	local rn = self:getResourceNode()
	rn:getChildByName('Image_4'):setSwallowTouches(true)
	rn:getChildByName('Button_2'):addClickEventListener(function()
		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
		self:getApp():removeTopView()
		end)

	local des_str = CONF:getStringValue("go")..":".." ("..self.data_.army_info.line.move_list[#self.data_.army_info.line.move_list].x..","..self.data_.army_info.line.move_list[#self.data_.army_info.line.move_list].y..")"
	-- if self.data_.res_info.type == 1 then
	-- 	des_str = des_str..self.data_.res_info.base_data.info.nickname.."jidi".." ("..self.data_.army_info.line.move_list[#self.data_.army_info.line.move_list].x..","..self.data_.army_info.line.move_list[#self.data_.army_info.line.move_list].y..")"
	-- elseif self.data_.res_info.type == 2 then
	-- 	local conf = CONF.PLANET_RES.get(self.data_.res_info.res_data.id)

	-- 	des_str = des_str..CONF:getStringValue(conf.NAME).." Lv."..conf.LEVEL.." ("..self.data_.army_info.line.move_list[#self.data_.army_info.line.move_list].x..","..self.data_.army_info.line.move_list[#self.data_.army_info.line.move_list].y..")"

	-- elseif self.data_.res_info.type == 3 then
	-- 	local conf = CONF.PLANET_RUINS.get(self.data_.res_info.ruins_data.id)

	-- 	des_str = des_str..CONF:getStringValue(conf.NAME).." Lv."..conf.LEVEL.." ("..self.data_.army_info.line.move_list[#self.data_.army_info.line.move_list].x..","..self.data_.army_info.line.move_list[#self.data_.army_info.line.move_list].y..")"
	-- elseif self.data_.res_info.type == 4 then

	-- elseif self.data_.res_info.type == 5 then

	-- end

	rn:getChildByName("Text_des"):setString(des_str)
    rn:getChildByName("Text_name"):setString(CONF:getStringValue("expedite"))
	rn:getChildByName("text_jindu"):setString(CONF:getStringValue("reside_time")..":"..formatTime(self.data_.army_info.line.need_time - (player:getServerTime() - self.data_.army_info.line.begin_time)))

	if (self.data_.army_info.line.need_time - self.data_.army_info.line.sub_time) - (player:getServerTime() - self.data_.army_info.line.begin_time) <= 0 then
		self:getApp():removeTopView()
	end

	local percent = ((self.data_.army_info.line.need_time - self.data_.army_info.line.sub_time) - (player:getServerTime() - self.data_.army_info.line.begin_time))/self.data_.army_info.line.need_time*100

	if percent < 0 then
		percent = 0
	end

	if percent > 100 then
		percent = 100
	end

	self.spd_ = require("util.ScaleProgressDelegate"):create(rn:getChildByName("Image_jindu"), rn:getChildByName("Image_jindu"):getTag())
	self.spd_:setPercentage( percent)

	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("item_list"),cc.size(3,10), cc.size(662,110))
	rn:getChildByName("item_list"):setScrollBarEnabled(false)
	self:resetList()	

	local function update( dt )		
		rn:getChildByName("text_jindu"):setString(CONF:getStringValue("reside_time")..":"..formatTime((self.data_.army_info.line.need_time - self.data_.army_info.line.sub_time) - (player:getServerTime() - self.data_.army_info.line.begin_time)))

		local percent = ((self.data_.army_info.line.need_time - self.data_.army_info.line.sub_time) - (player:getServerTime() - self.data_.army_info.line.begin_time))/self.data_.army_info.line.need_time*100
		if percent < 0 then
			percent = 0
		end

		if percent > 100 then
			percent = 100
		end

		self.spd_:setPercentage( percent)

		if (self.data_.army_info.line.need_time - self.data_.army_info.line.sub_time) - (player:getServerTime() - self.data_.army_info.line.begin_time) <= 0 then
			self:getApp():removeTopView()
		end

	end

	schedulerEntry = scheduler:scheduleScriptFunc(update, 1,false)

	local function recvMsg()
		--print("PlanetAddSpeedLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

        if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_SPEED_UP_RESP") then

			local proto = Tools.decode("PlanetSpeedUpResp",strData)
			print("PlanetSpeedUpResp", proto.result)

			if proto.result == 0 then

				self.data_.army_info = proto.army
				self:resetList()
				update()

				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updatePlanetUser")

			elseif proto.result == 1 then
				tips:tips(CONF:getStringValue("item not enought"))
        	end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function PlanetAddSpeedLayer:onExitTransitionStart()
	printInfo("PlanetAddSpeedLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil
	end
end

return PlanetAddSpeedLayer