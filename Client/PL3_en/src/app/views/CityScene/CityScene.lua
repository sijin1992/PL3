
local kMoveActionTag = 1000

local it = require("util.InertiaTouch"):create()

local Gmath = require("app.Gmath")

local VisibleRect = cc.exports.VisibleRect

local scheduler = cc.Director:getInstance():getScheduler()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local winSize = cc.Director:getInstance():getWinSize()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local player = require("app.Player"):getInstance()

local g_sendList = require("util.SendList"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local CityScene = class("CityScene", cc.load("mvc").ViewBase)

CityScene.RESOURCE_FILENAME = "CityScene/CityScene.csb"

CityScene.NEED_ADJUST_POSITION = true

CityScene.RUN_TIMELINE = true

CityScene.orgPos = 0

local schedulerEntry = nil

local schedulerQueue = nil

local schedulerFight = nil

local schedulerGroupHelper = nil

local moveOnBuilding = false

local moveRN = false

local first_come = true

----------------------------------------------------------------------
--ADD WJJ 180622
CityScene.bugHelper = require("util.ExGuideTouchBug"):getInstance()
CityScene.lagHelper = require("util.ExLagHelper"):getInstance()
CityScene.exConfig = require("util.ExConfig"):getInstance()
CityScene.IS_DELAY_ENTERING = true

CityScene.lastDragDelta = 0

-- CityScene.IS_SCENE_TRANSFER_EFFECT = true

----------------------------------------------------------------------

CityScene.zhuchengHelper = require("app.ExViewZhucheng"):getInstance()
-- CityScene.DRAG_GUANXING_RATE = 2
CityScene.DRAG_EASE_RATE = 2.5 * 0.55
CityScene.DRAG_GUANXING_RATE = 2 * 1
CityScene.DRAG_BACKGROUND_SPEED = -0.3
CityScene.DRAG_BACKGROUND_DISTANCE_RATE = -0.3
CityScene.DRAG_BACKGROUND_TIME_RATE = 1
-- CityScene.BACKGROUND_SKY_LEFT = 1400
-- CityScene.BACKGROUND_SKY_RIGHT = 2100
-- CityScene.BACKGROUND_SKY_LEFT = 1350
-- CityScene.BACKGROUND_SKY_RIGHT = 1570

CityScene.BACKGROUND_SKY_LEFT = 1350 - 500
CityScene.BACKGROUND_SKY_RIGHT = 1570 + 600

-- CityScene.BACKGROUND_LIU_GUANG_X = 100 - 35 -11.7 +2
CityScene.BACKGROUND_LIU_GUANG_X = 0
-- CityScene.BACKGROUND_LIU_GUANG_Y = 0 -11.7 -3
CityScene.BACKGROUND_LIU_GUANG_Y = 0



CityScene.isBackgroundQianjingStopped = false


CityScene.GUIDE_xiao_chui_zi_x_offset = -30
----------------------------------------------------------------------

CityScene.IS_DEBUG_LOG_VERBOSE_LOCAL = false

function CityScene:_print(_log)
	if( self.IS_DEBUG_LOG_VERBOSE_LOCAL ) then
		print(_log)
	end
end
----------------------------------------------------------------------

function CityScene:StopBackgroundMoving()
	local bg_mid, bg_far = self:GetBackgrounds()
	-- bg_far:stopActionByTag(kMoveActionTag)
	bg_far:stopAllActions()
end

function CityScene:OnFixBackground()
	local bg_mid, bg_far = self:GetBackgrounds()
	local far_x, far_y = bg_far:getPosition()
	if far_x < self.BACKGROUND_SKY_LEFT then
		far_x = self.BACKGROUND_SKY_LEFT
	elseif ( far_x > self.BACKGROUND_SKY_RIGHT ) then
		far_x = self.BACKGROUND_SKY_RIGHT
	end
	bg_far:setPositionX(far_x)
end

function CityScene:OnDragBackground_Guanxing(duration, distance)
	for k,v in pairs(distance) do
		print(string.format(" ~~~ onTouchEnded distance [%s] = %s", k, tostring(v) ))
	end

	local bg_move_distance = {}
	duration = duration * self.DRAG_BACKGROUND_TIME_RATE
	bg_move_distance["x"] =  self.DRAG_BACKGROUND_DISTANCE_RATE * distance["x"]
	bg_move_distance["y"] = distance["y"]
	local bg_far_move = cc.EaseOut:create(cc.MoveBy:create(duration, bg_move_distance), self.DRAG_EASE_RATE)
	-- local bg_far_move = cc.MoveBy:create(duration, bg_move_distance)
	bg_far_move:setTag(kMoveActionTag)
	local mid,far = self:GetBackgrounds()
	far:runAction(bg_far_move)
end

function CityScene:OnDragBackground()
	if ( self.isBackgroundQianjingStopped ) then
		return
	end

	local bg_mid, bg_far = self:GetBackgrounds()
	local far_x, far_y = bg_far:getPosition()

	-- print(string.format(" far_x: %s ", tostring( far_x ) ))

	local bg_far_delta = far_x + (self.lastDragDelta * self.DRAG_BACKGROUND_SPEED)

	-- print( string.format(" bg_far_delta: %s ", tostring( bg_far_delta ) ) )
--[[
	if bg_far_delta < winSize.width - cs.width then
		bg_far_delta = winSize.width - cs.width
	else
]]
	if bg_far_delta < self.BACKGROUND_SKY_LEFT then
		bg_far_delta = self.BACKGROUND_SKY_LEFT
	end

	bg_far:setPositionX(bg_far_delta)
end

function CityScene:GetBackgrounds()
	local node = self:getResourceNode()
	local background = node:getChildByName('background')
	local far = background:getChildByName('BG_L2_180725')
	local mid = background:getChildByName('BG_L1_180725')
	return mid, far
end

function CityScene:InitBackgrounds()
	local mid, far = self:GetBackgrounds()
	mid:setLocalZOrder(-1)
	far:setLocalZOrder(-2)
end

function CityScene:onCreate(data)

		if data then
			self.data_ = data
		end
		-- if ((data and data.sfx) or self.IS_DELAY_ENTERING ) then
		if ((data and data.sfx)  ) then
			if( data and data.sfx ) then
				data.sfx = false
			end
			local view = self:getApp():createView("CityScene/TransferScene",{from = "planet" ,state = "enter"})
			self:addChild(view,100)
		end


end

function CityScene:touchBuilding( num, tl )
	local resNode = self:getResourceNode()

	local building = resNode:getChildByName("building_"..num)

	if building == nil then
			
	else

		local s = building:getContentSize()
		local locationInNode = building:convertToNodeSpace(tl)
		local rect = cc.rect(0, 0, s.width, s.height)
		if cc.rectContainsPoint(rect, locationInNode) then

			if resNode:getChildByName("building_"..num):isVisible() == false then
				return
			end

			local x = building:getPositionX()
			local y = building:getPositionY()
			
			local scale = building:getContentSize().height/resNode:getChildByName("building_1"):getContentSize().height
			if building:getName() == "building_1_1" then
				x = resNode:getChildByName("building_1"):getPositionX()
				y = resNode:getChildByName("building_1"):getPositionY()
				scale = 1
			end
			-- BuildingName_10
			local name = building:getName()
			if  CONF.EParamOpenKey[num] ~= "" then
				local str = CONF.EParamOpenKey[num]
				local heroLevel = CONF.PARAM.get(str).PARAM[1]
				local centreLevel = CONF.PARAM.get(str).PARAM[2]
				if player:getLevel() < heroLevel or player:getBuildingInfo(1).level < centreLevel then
					local tipStr = CONF:getStringValue("BuildingName_"..num).."\n"
					if heroLevel ~= 0 then 
						tipStr = tipStr .. CONF:getStringValue("levelNum") .. tostring(heroLevel) .. CONF:getStringValue("open") .."\n"
					end
					if centreLevel ~= 0 then 
						tipStr = tipStr .. CONF:getStringValue("CentreLevel") .. CONF:getStringValue("achieve") .. tostring(centreLevel) .. CONF:getStringValue("open")
					end

					tips:tips(tipStr)
					return
				end       
			end 

			for k,i in ipairs(CONF.PARAM.get("building activate").PARAM) do
				if CONF.EFunctionOpenKey[i] ~= "" and i == num then
					if player:getSystemGuideStep(CONF.FUNCTION_OPEN.get(CONF.EFunctionOpenKey[i]).ID) == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() and player:getLevel() >= CONF.FUNCTION_OPEN.get(CONF.EFunctionOpenKey[i]).GRADE then
						if CONF.FUNCTION_OPEN.get(CONF.EFunctionOpenKey[i]).OPEN_GUIDANCE == 1 then
							return
						end
					end
				end
			end  

			if building:getName() == "building_15" then
				if player:getUserInfo().achievement_data.recharge_real_money < CONF.PARAM.get("trade money").PARAM then
					local ss = CONF:getStringValue("myzx_open")
					local strs = Split(ss,"#")
					tips:tips(strs[1]..CONF.PARAM.get("trade money").PARAM..strs[2])
					return
				end
			end

	-----------------------------------
		local gId = guideManager.guide_id
		local is_bug = self.bugHelper:OnGuideId_Building(gId)
		-- print("@@@ City onTouchEnded isBug: " .. tostring(is_bug))
		-- print("@@@ City onTouchEnded gId: " .. tostring(gId))
		if( is_bug ) then
			do return false end
		end
	-----------------------------------

			for j=1,CONF.EBuilding.count do
				local child = resNode:getChildByName(string.format("text_%d", j))
				if child ~= nil then
					self.zhuchengHelper.EffectManager:ScaleTo(child, 0.4, 0)
					-- child:runAction(cc.ScaleTo:create(0.4, 0))
				end
			end
			self.uiLayer_:switchBuildingBtn(true, building:getName(), cc.p(x + resNode:getPositionX() + (self:getResourceNode():getContentSize().width/2 - winSize.width/2), y), 1) 

	-----------------------------------


		if self.bugHelper then
			self.bugHelper:OnCitySceneTouchEnd()
		end

		-- ADD WJJ 20180806
		require("util.ExGuideBugHelper_SystemGuide"):getInstance():CheckSystemGuideNextCursor()

	-----------------------------------


			if guideManager:getGuideType() then
				guideManager:doEvent("building")
			end
			return 
		end

	end
end 

function CityScene:resetBuildQueue()

	if player:getNormalBuildingQueueNow() then

		local info = player:getBuildingQueueBuild(1)
		if info.type == 1 then

	-- 		self.uiLayer_:getResourceNode():getChildByName("queue"):setTag(1)
	-- 		self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("jianzhu"):setTag(info.index)
	-- 		self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("jianzhu"):setTexture("BuildingUpgradeScene/building/b"..info.index..".png")
	-- 		self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("mask"):setVisible(true)
	-- 		self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("jianzhu"):setVisible(true)

	-- 		local building_info = player:getBuildingInfo(info.index)

	-- 		local conf = CONF[string.format("BUILDING_%d",info.index)].get(building_info.level)
			  
	-- 		local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
	-- 		local time =  cd - (player:getServerTime() - building_info.upgrade_begin_time)
	-- 		self.uiLayer_:getResourceNode():getChildByName("queue_time"):setString(formatTime(time))
			

		elseif info.type == 2 then

			local landInfo = player:getLandType(info.index)

	-- 		self.uiLayer_:getResourceNode():getChildByName("queue"):setTag(2)
	-- 		self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("jianzhu"):setTag(info.index)
	-- 		local resource = math.floor(landInfo.resource_type/1000)*1000+1
	-- 		self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("jianzhu"):setTexture("BuildingUpgradeScene/building/"..resource..".png")
	-- 		self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("mask"):setVisible(true)
	-- 		self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("jianzhu"):setVisible(true)

			local conf = CONF.RESOURCE.get(landInfo.resource_type)

			local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kHomeBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
			local time = cd - (player:getServerTime() - landInfo.res_refresh_times)

			if time <= 0 then
				local strData = Tools.encode("GetHomeSatusReq", {
					home_type = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)
			else
	-- 			self.uiLayer_:getResourceNode():getChildByName("queue_time"):setString(formatTime(time))
			end

		end

	else
	-- 	self.uiLayer_:getResourceNode():getChildByName("queue_time"):setString(CONF:getStringValue("leisure"))
	-- 	self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("jianzhu"):setVisible(false)
	-- 	self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("mask"):setVisible(false)
	-- 	self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("point"):setVisible(true)
		
	end

	

	-- -----------

	if player:getMoneyBuildingQueueOpen() then

		local info = player:getBuildingQueueBuild(2)

		if player:getMoneyBuildingQueueNow() then
	-- 		self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("money"):setVisible(false)
	-- 		self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("money_num"):setVisible(false)
	-- 		self.uiLayer_:getResourceNode():getChildByName("money_queue_time"):setVisible(true)


			if info.type == 1 then

	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue"):setTag(1)
	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("jianzhu"):setTag(info.index)
	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("jianzhu"):setTexture("BuildingUpgradeScene/building/b"..info.index..".png")
	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("jianzhu"):setVisible(true)
	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("mask"):setVisible(true)

	-- 			local building_info = player:getBuildingInfo(info.index)

	-- 			local conf = CONF[string.format("BUILDING_%d",info.index)].get(building_info.level)
				  
	-- 			local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
	-- 			local time =  cd - (player:getServerTime() - building_info.upgrade_begin_time)
	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue_time"):setString(formatTime(time))
				

			elseif info.type == 2 then

				local landInfo = player:getLandType(info.index)

	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue"):setTag(2)
	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("jianzhu"):setTag(info.index)
	-- 			local resource = math.floor(landInfo.resource_type/1000)*1000+1
	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("jianzhu"):setTexture("BuildingUpgradeScene/building/"..resource..".png")
	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("jianzhu"):setVisible(true)
	-- 			self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("mask"):setVisible(true)

				local conf = CONF.RESOURCE.get(landInfo.resource_type)

				local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kHomeBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
				local time = cd - (player:getServerTime() - landInfo.res_refresh_times)

				if time <= 0 then
					local strData = Tools.encode("GetHomeSatusReq", {
						home_type = 1,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)
				else
	-- 				self.uiLayer_:getResourceNode():getChildByName("money_queue_time"):setString(formatTime(time))
				end

			end

		else
	-- 		self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("point"):setVisible(true)
	-- 		self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("jianzhu"):setVisible(false)
	-- 		self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("mask"):setVisible(false)
	-- 		local time = info.duration_time - (player:getServerTime() - info.open_time)
	-- 		self.uiLayer_:getResourceNode():getChildByName("money_queue_time"):setVisible(true)
	-- 		self.uiLayer_:getResourceNode():getChildByName("money_queue_time"):setString(formatTime(time))
	-- 		self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("money"):setVisible(false)
	-- 		self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("money_num"):setVisible(false)
			
		end
	else
	-- 	self.uiLayer_:getResourceNode():getChildByName("money_queue_time"):setVisible(false)
	-- 	self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("jianzhu"):setVisible(false)
	-- 	self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("money"):setVisible(true)
	-- 	self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("money_num"):setVisible(true)
	-- 	self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("mask"):setVisible(false)
	end

end

function CityScene:openCity( ... )
	-- Add by wjj 20180605
	-- print("###Lua CityScene:openCity")

	local rn = self:getResourceNode()
	local city = rn:getChildByName("background")
	for i=1,16 do
		rn:getChildByName("building_"..i):setVisible(false)
		rn:getChildByName("text_"..i):setVisible(false)
		city:getChildByName("city_"..i):setVisible(false)
		city:getChildByName("G"..i):setVisible(false)
	end

	local guide 
	if guideManager:getSelfGuideID() ~= 0 then
		guide = guideManager:getSelfGuideID()
	else
		guide = player:getGuideStep()
	end
	print("openCity guide",guide)
	local buildingTab = {}
	for i,v in ipairs(CONF.OPEN_ICON.getIDList()) do
		-- print("###Lua for CONF.OPEN_ICON.getIDList() ")
		-- print("###Lua for i: " .. tostring(i))
		-- print("###Lua for v: " .. tostring(v))
		local conf = CONF.OPEN_ICON.get(v)
		local show = false
		-- print("###Lua conf.CONDITION: " .. tostring(conf.CONDITION))
		if conf.CONDITION == 1 then
			if guide >= conf.COUNT then
				show = true
			end
		elseif conf.CONDITION == 2 then
			if player:getLevel() >= conf.COUNT then
				show = true
			end
		elseif conf.CONDITION == 4 then
			local id = math.floor( conf.COUNT/100)
			if player:getSystemGuideStep(id) == 0  then
				if math.floor(systemGuideManager:getSelfGuideID()/100) == math.floor(conf.COUNT/100) then
					if systemGuideManager:getSelfGuideID()>=conf.COUNT then
						show = true
					end
				end
			else
				show = true
			end
		elseif conf.CONDITION == 3 then
			if player:getBuildingInfo(1).level >= conf.COUNT then
				show = true
			end
		end
		-- print("###Lua show: " .. tostring(show))
		if show then
			for i2,v2 in ipairs(conf.BUILDING) do
				local ins = true
				for o,p in ipairs(buildingTab) do
					if v2 == p then
						ins = false
						break
					end
				end
				if ins then
					table.insert(buildingTab,v2)
				end
			end
			
		end
	end

	-- print("###Lua for buildingTab ")

	for i2,v2 in ipairs(buildingTab) do
	-- print("###Lua for buildingTab i2: " .. tostring(i2) )
	-- print("###Lua for buildingTab v2: " .. tostring(v2) )
		if v2 > 100 and v2 < 200 then
			rn:getChildByName("building_"..(v2-100)):setVisible(true)
			-- jian zhu biao ti  by wjj 20180727
			local building_label = rn:getChildByName("text_"..(v2-100))
			building_label:setVisible(true)
			city:getChildByName("city_"..(v2-100)):setVisible(true)
			city:getChildByName("G"..(v2-100)):setVisible(true)
			if city:getChildByName(string.format("city_%d", (v2-100))) then
				-- print("###Lua for city:getChildByName PARAM count: " .. tostring( #CONF.PARAM.get("building lock").PARAM ) )
				for k,i in ipairs(CONF.PARAM.get("building lock").PARAM) do
					-- print("###Lua for city:getChildByName PARAM k: " .. tostring(k) )
					-- print("###Lua for city:getChildByName PARAM i: " .. tostring(i) )
					if (v2-100) == i then
						local b1,b2,b3 = isBuildingOpen(i)
						if not b1 or not b2 or not b3 then
							-- print("###Lua animManager:runAnimByCSB getChildByName: " .. tostring(string.format("city_%d", (v2-100)) ))
							-- print("###Lua animManager:runAnimByCSB  " .. tostring(string.format("CityScene/sfx/city_%d.csb", (v2-100)) ))
							animManager:runAnimByCSB(city:getChildByName(string.format("city_%d", (v2-100))), string.format("CityScene/sfx/city_%d.csb", (v2-100)),  "grey")
							building_label:setVisible(false)
						end
						break
					end
				end
			end
		end
	end
end

function CityScene:openBtn( ... )
	local resNode = self:getResourceNode()
	local city = resNode:getChildByName("background")
	local func_key = CONF.EFunctionOpenKey
	for k,i in ipairs(CONF.PARAM.get("building activate").PARAM) do
		self:_print(string.format(" ~~~~ openBtn [%s] = %s ", tostring(k), tostring(i)))
		self:_print(string.format(" ~~~~ func_key[%s] = %s ", tostring(i), tostring(func_key[i])))
		if func_key[i] ~= "" then
			
			if city:getChildByName(string.format("city_%d", i)):getChildByName("icon_suo") then
				-- city:getChildByName(string.format("city_%d", i)):getChildByName("icon_suo"):setVisible(true)
			end

			local func_id = CONF.FUNCTION_OPEN.get(func_key[i]).ID
			local sys_guide_step = player:getSystemGuideStep(func_id)
			self:_print(string.format(" ~~~~ func_id = %s   sys_guide_step = %s ", tostring(func_id), tostring(sys_guide_step)))
			if tonumber(sys_guide_step) == 0 and tonumber(player:getGuideStep()) >= CONF.GUIDANCE.count() then
				local is_guide = CONF.FUNCTION_OPEN.get(func_key[i]).OPEN_GUIDANCE
				self:_print(string.format(" ~~~~ is_guide = %s ", tostring(is_guide)))
				if tonumber(is_guide) == 1 then
					local _name = string.format("city_%d", i)
					local _ani = string.format("CityScene/sfx/city_%d.csb", i)
					animManager:runAnimByCSB(city:getChildByName(_name), _ani,  "grey")
					local _grade = CONF.FUNCTION_OPEN.get(func_key[i]).GRADE
					self:_print(string.format(" ~~~~ _name = %s grey  _ani = %s _grade = %d", tostring(_name), tostring(_ani), _grade))
					if player:getLevel() >= tonumber(_grade) and resNode:getChildByName("btn_jihuo_"..i) then
						resNode:getChildByName("btn_jihuo_"..i):setVisible(true)
						resNode:getChildByName("btn_jihuo_"..i):getChildByName("jiantou"):setVisible(true)
						animManager:runAnimByCSB(resNode:getChildByName("btn_jihuo_"..i), "CityScene/BtnActivateNode.csb", "1")
						if city:getChildByName(string.format("city_%d", i)):getChildByName("icon_suo") then
							_name = string.format("city_%d", i)
							city:getChildByName(_name):getChildByName("icon_suo"):setVisible(false)
							self:_print(string.format(" ~~~~ _name = %s icon_suo hide ", tostring(_name)))
						end
					end
				end
			end

			resNode:getChildByName("btn_jihuo_"..i):getChildByName("btn"):addClickEventListener(function ( ... )
				if cc.exports.g_activate_building then
					return
				end
				resNode:getChildByName("building_"..i):setVisible(true)
				cc.exports.g_activate_building = true
				resNode:getChildByName('background'):getChildByName("city_"..i):setVisible(true)
				animManager:runAnimOnceByCSB(resNode:getChildByName('background'):getChildByName("city_"..i), "CityScene/sfx/city_"..i..".csb", "3", function ( ... )
					animManager:runAnimByCSB(resNode:getChildByName('background'):getChildByName("city_"..i), "CityScene/sfx/city_"..i..".csb", "1")
					if CONF.FUNCTION_OPEN.get(func_key[i]).OPEN_GUIDANCE == 1 then
						systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get(func_key[i]).INTERFACE)
					end
				end)
				resNode:getChildByName("btn_jihuo_"..i):setVisible(false)
			end)
		end
	end
end

function CityScene:OnDragScreenDoMove(winSize, cs)

	if( self.lastDragDelta ~= 0 ) then
		-- print(string.format("@@@ CityScene lastDragDelta: %s", tostring(self.lastDragDelta)))
		local node = self:getResourceNode()
		local currentPosX, currentPosY = node:getPosition()

		local delta = currentPosX + self.lastDragDelta

		self.isBackgroundQianjingStopped = false
		if delta < winSize.width - cs.width then
			delta = winSize.width - cs.width
			self.isBackgroundQianjingStopped = true
		elseif delta > 0 then
			delta = 0
			self.isBackgroundQianjingStopped = true
		end

		node:setPositionX(delta)

		----------------------------------------
		-- FEN CENG  by wjj
		if( self.isBackgroundQianjingStopped ) then
			self:StopBackgroundMoving()
		end

		self:OnDragBackground()
		----------------------------------------

		self.lastDragDelta = 0
	end

		self:OnFixBackground()
end

function CityScene:OnDragScreen(touch, winSize, cs)
	local diff = touch:getDelta()
	if math.abs(diff.x) < g_click_delta and math.abs(diff.y) < g_click_delta then
		
	else
		moveRN = true
		local zhuchengHelper = require("app.ExViewZhucheng"):getInstance()
		zhuchengHelper:OnDrag(true)
	end

	local node = self:getResourceNode()
	node:stopActionByTag(kMoveActionTag)

	self:StopBackgroundMoving()

	self.lastDragDelta = self.lastDragDelta + diff.x
	-- node:setPositionX(delta)
end

function CityScene:onEnterTransitionFinish()
	printInfo("CityScene:onEnterTransitionFinish()")

	--ADD BY WJJ 20180712
	cc.exports.G_Instance_CityScene = self
	cc.exports.lastEnterTime_CityScene = os.clock()
    --add by JinXin 20180713  只有第一次进入主城才会获取
    if cc.exports.FirstTouchlist == nil then
        cc.exports.FirstTouchlist = {1,3,4,5,7,10,11,12,13,14,16}
    end

	-- ADD WJJ 20180703
	-- self:KeepLoading()

	require("app.ExMemoryInterface"):getInstance():OnDisableMemoryReleaseAsync()

	if cc.exports.g_background_music_name ~= "sound/main.mp3" then
		playMusic("sound/main.mp3", true)
	end

	self:openCity()

	local function updateFight( ... )
		self:update()
	end

	scheduler:setTimeScale(1)

	if self.data_.function_id then
		systemGuideManager:createGuideLayer(self.data_.function_id)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end

	local resNode = self:getResourceNode()
	for k,v in ipairs(CONF.PARAM.get("building noob").PARAM) do
		if resNode:getChildByName("btn_jihuo_"..v) then
			resNode:getChildByName("btn_jihuo_"..v):getChildByName("btn"):addClickEventListener(function ( ... )
				if cc.exports.g_activate_building then
					return
				end
				resNode:getChildByName('background'):getChildByName("city_"..v):setVisible(true)
				animManager:runAnimOnceByCSB(resNode:getChildByName('background'):getChildByName("city_"..v), "CityScene/sfx/city_"..v..".csb", "3", function ( ... )
					animManager:runAnimByCSB(resNode:getChildByName('background'):getChildByName("city_"..v), "CityScene/sfx/city_"..v..".csb", "1")
				end)
				resNode:getChildByName("btn_jihuo_"..v):setVisible(false)
				guideManager:addGuideLayer()
			end)
		end
	end

	resNode:getChildByName("btn_xiufu"):addClickEventListener(function ( ... )
		if cc.exports.g_activate_building then
			return
		end
		resNode:getChildByName('background'):getChildByName("city_1"):setVisible(true)
		animManager:runAnimOnceByCSB(resNode:getChildByName('background'):getChildByName("city_1"), "CityScene/sfx/city_1.csb", "3", function ( ... )
			animManager:runAnimByCSB(resNode:getChildByName('background'):getChildByName("city_1"), "CityScene/sfx/city_1.csb", "1")
		end)
		resNode:getChildByName("btn_xiufu"):setVisible(false)
		guideManager:addGuideLayer()
	end)

	

	self.uiLayer_ = self:getApp():createView("CityScene/CityUILayer")
	self:addChild(self.uiLayer_)

	self.fight_delegate_ = require("util.FightRunDelegate"):create(self.uiLayer_:getResourceNode():getChildByName("info_node"):getChildByName("userInfoNode"):getResourceNode():getChildByName("fight_num"))

	self.uiLayer_:getResourceNode():getChildByName("info_node"):getChildByName("userInfoNode"):getResourceNode():getChildByName("fight_num"):setString(g_Player_Fight)
	if player:getPower() ~= g_Player_Fight then

			self.fight_delegate_:setUpNum(player:getPower())

			if schedulerFight == nil then
				schedulerFight = scheduler:scheduleScriptFunc(updateFight,0.01,false)
			end

			g_Player_Fight = player:getPower()

	end


	self.g_index = 0
	self.show_di_text = false

	self:openAmi()
	self:resetBuildQueue()
	
	local function toString( name )
		if name == 1 then 
			return 6 
		elseif name == 8 then 
			return 7
		elseif name == 3 then 
			return 3 
		elseif name == 6 then 
			return 4 
		elseif name == 5 then 
			return 5 
		elseif name == 2 then
			return 9
		else 
			return nil
		end
	end 
	-- local numList = {1,2,3,5,6,8,}
	-- for i,v in ipairs(numList) do
	-- 	if toString(v) then
	-- 		local child = resNode:getChildByName(string.format("text_%d", toString(v)))
	-- 		local str = "city_".. v .."_open"
	-- 		if player:getLevel() < CONF.PARAM.get(str).PARAM[1] or player:getBuildingInfo(1).level < CONF.PARAM.get(str).PARAM[2] then

	-- 			child:setVisible(false)
	-- 		end
	-- 	end
	-- end

	self:runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
		if player:isGroup() then
			local strData = Tools.encode("GetGroupReq", {
				-- groupid = player:getGroupData().groupid,
				groupid = "",
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_REQ"),strData)
		end
	end), cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )

		-- if player:getLevel() >= CONF.FUNCTION_OPEN.get("planet_open").GRADE then

			-- if first_come then
				local strData = Tools.encode("PlanetGetReq", {
					type = 1,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)

				-- first_come = false
			-- end
		-- end
		
	end), cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
		local strData = Tools.encode("GetChatLogReq", {

				chat_id = 0,
			})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)
		
	end), cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
		local strData = Tools.encode("SlaveSyncDataReq", {    
			type = 0,
			user_name_list = {player:getName()} ,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
		
	end)))
		

	--[[self.uiLayer_:getResourceNode():getChildByName("queue"):addClickEventListener(function( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
		if player:getNormalBuildingQueueNow() then

			for j=1,CONF.EBuilding.count do
				local child = self:getResourceNode():getChildByName(string.format("text_%d", j))
				if child ~= nil then
					child:runAction(cc.ScaleTo:create(0.1, 1))
				end
			end

			if self.uiLayer_:getIsBuildingOn() then
				self.uiLayer_:switchBuildingBtn(false, "")
			end

			local rn = self:getResourceNode()
			
			if self.uiLayer_:getResourceNode():getChildByName("queue"):getTag() == 1 then
				local build = rn:getChildByName("building_"..self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("jianzhu"):getTag())

				local x = winSize.width/2 - build:convertToWorldSpace(cc.p(0,0)).x - build:getContentSize().width/2

				-- local time = x/1000

				-- local ease = cc.EaseOut:create(cc.MoveBy:create(0.01,cc.p(x, 0)),2.5)
				local moveBy = cc.MoveBy:create(0.2, cc.p(x, 0))


				local function call( ... )
					for j=1,CONF.EBuilding.count do
						local child = rn:getChildByName(string.format("text_%d", j))
						if child ~= nil then
							child:runAction(cc.ScaleTo:create(0.4, 0))
						end
					end

					local x = build:getPositionX()
					local y = build:getPositionY()
					
					local scale = build:getContentSize().height/rn:getChildByName("building_1"):getContentSize().height

					self.uiLayer_:switchBuildingBtn(true, build:getName(), cc.p(x + rn:getPositionX(), y), 1)
				end

				rn:stopAllActions()
				rn:runAction(cc.Sequence:create(moveBy, cc.DelayTime:create(0.05), cc.CallFunc:create(call)))
			else
				self:getApp():pushView("HomeScene/HomeScene", {index = self.uiLayer_:getResourceNode():getChildByName("queue"):getChildByName("jianzhu"):getTag()})
			end
   		else
   			goScene(2, 11)
		end
	end)]]--

	--[[self.uiLayer_:getResourceNode():getChildByName("money_queue"):addClickEventListener(function( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
		if player:getMoneyBuildingQueueOpen() then
			if player:getMoneyBuildingQueueNow() then

				for j=1,CONF.EBuilding.count do
					local child = self:getResourceNode():getChildByName(string.format("text_%d", j))
					if child ~= nil then
						child:runAction(cc.ScaleTo:create(0.1, 1))
					end
				end

				if self.uiLayer_:getIsBuildingOn() then
					self.uiLayer_:switchBuildingBtn(false, "")
				end

				local rn = self:getResourceNode()
				
				if self.uiLayer_:getResourceNode():getChildByName("money_queue"):getTag() == 1 then
					local build = rn:getChildByName("building_"..self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("jianzhu"):getTag())

					local x = winSize.width/2 - build:convertToWorldSpace(cc.p(0,0)).x - build:getContentSize().width/2

					-- local time = x/1000

					-- local ease = cc.EaseOut:create(cc.MoveBy:create(0.01,cc.p(x, 0)),2.5)
					local moveBy = cc.MoveBy:create(0.2, cc.p(x, 0))


					local function call( ... )
						for j=1,CONF.EBuilding.count do
							local child = rn:getChildByName(string.format("text_%d", j))
							if child ~= nil then
								child:runAction(cc.ScaleTo:create(0.4, 0))
							end
						end

						local x = build:getPositionX()
						local y = build:getPositionY()
						
						local scale = build:getContentSize().height/rn:getChildByName("building_1"):getContentSize().height

						self.uiLayer_:switchBuildingBtn(true, build:getName(), cc.p(x + rn:getPositionX(), y), 1)
					end

					rn:stopAllActions()
					rn:runAction(cc.Sequence:create(moveBy, cc.DelayTime:create(0.05), cc.CallFunc:create(call)))
				else
					self:getApp():pushView("HomeScene/HomeScene", {index = self.uiLayer_:getResourceNode():getChildByName("money_queue"):getChildByName("jianzhu"):getTag()})
				end
	   		else
	   			goScene(2, 11)
			end
		else

			local function func( ... )
				if player:getMoneyBuildingQueueOpen() then

					if player:getMoneyBuildingQueueNow() then
						tips:tips(CONF:getStringValue("money build queue is upgrade now, can't buy"))
					else
						if player:getMoney() < CONF.PARAM.get("queue_buy_num").PARAM then
							-- tips:tips(CONF:getStringValue("no enought credit"))
							local function func()
								local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

								rechargeNode:init(self, {index = 1})
								self:addChild(rechargeNode)
							end

							local messageBox = require("util.MessageBox"):getInstance()
							messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)

						else
							local strData = Tools.encode("BuildQueueAddReq", {
								num = 1,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_ADD_REQ"),strData)

							gl:retainLoading()
						end
					end
				else
				
					if player:getMoney() < CONF.PARAM.get("queue_buy_num").PARAM then
						-- tips:tips(CONF:getStringValue("no enought credit"))
						local function func()
							local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

							rechargeNode:init(self, {index = 1})
							self:addChild(rechargeNode)
						end

						local messageBox = require("util.MessageBox"):getInstance()
						messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)

					else
						local strData = Tools.encode("BuildQueueAddReq", {
							num = 1,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_ADD_REQ"),strData)

						gl:retainLoading()
					end
				end
			end

			local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("open_queue").." "..formatTime2(CONF.PARAM.get("queue_buy_time").PARAM*3600), CONF.PARAM.get("queue_buy_num").PARAM, func)

			self:addChild(node)
			tipsAction(node)
			
		end
	end)]]--

	--set building level num
	local resNode = self:getResourceNode()
	resNode:getChildByName("btn_tarde"):getChildByName("text"):setString(CONF:getStringValue("Get"))
	resNode:getChildByName("btn_tarde"):addClickEventListener(function ( ... )
		if cc.exports.g_activate_building then
			return
		end
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRADE_GET_MONEY_REQ"),"0")
		gl:retainLoading()
	end)

	local function resetTrade( ... )
		if true then
			return
		end
		local info = player:getBuildingInfo(CONF.EBuilding.kTrade)
		local cur_num = math.floor((player:getServerTime() - player:getTradeData().last_product_time)/CONF.BUILDING_15.get(info.level).PRODUCTION_TIME)*CONF.BUILDING_15.get(info.level).PRODUCTION_NUM
		if cur_num > 0 then
			resNode:getChildByName("btn_tarde"):setVisible(true)
		else
			resNode:getChildByName("btn_tarde"):setVisible(false)
		end
		if player:getUserInfo().achievement_data.recharge_real_money < CONF.PARAM.get("trade money").PARAM then
			resNode:getChildByName("btn_tarde"):setVisible(false)
		end
	end
	resetTrade()

	for i=1,CONF.EBuilding.count do

		if resNode:getChildByName("text_"..i):getChildByName("num") then
			resNode:getChildByName("text_"..i):getChildByName("num"):setString("Lv."..player:getBuildingInfo(i).level)
		end
		resNode:getChildByName(string.format("text_%d", i)):getChildByName("text"):setString(CONF.STRING.get(string.format("BuildingName_%d", i)).VALUE)  

		if resNode:getChildByName("text_"..i):getChildByName("num") ~= nil then
			resNode:getChildByName("text_"..i):getChildByName("num"):setPositionX(resNode:getChildByName("text_"..i):getChildByName("text"):getPositionX()+resNode:getChildByName("text_"..i):getChildByName("text"):getContentSize().width+20)
		end
		
		resNode:getChildByName(string.format("text_%d", i)):setContentSize(resNode:getChildByName(string.format("text_%d", i)):getChildByName("text"):getContentSize().width+110, resNode:getChildByName(string.format("text_%d", i)):getContentSize().height)
	end

	----------------------------
	resNode:setPositionX(self.data_.pos)

	if self.data_.index then
		local build = resNode:getChildByName("building_"..self.data_.index)

		local x = winSize.width/2 - build:convertToWorldSpace(cc.p(0,0)).x - build:getContentSize().width/2

		-- local time = x/1000

		-- local ease = cc.EaseOut:create(cc.MoveBy:create(0.01,cc.p(x, 0)),2.5)
		local moveBy = cc.MoveBy:create(0.2, cc.p(x, 0))


		local function call( ... )
			for j=1,CONF.EBuilding.count do
				local child = resNode:getChildByName(string.format("text_%d", j))
				if child ~= nil then
					local zhuchengHelper = require("app.ExViewZhucheng"):getInstance()
					zhuchengHelper.EffectManager:ScaleTo(child, 0.4, 0)
					-- child:runAction(cc.ScaleTo:create(0.4, 0))
				end
			end

			local x = build:getPositionX()
			local y = build:getPositionY()
			
			local scale = build:getContentSize().height/resNode:getChildByName("building_1"):getContentSize().height

			self.uiLayer_:switchBuildingBtn(true, build:getName(), cc.p(x + resNode:getPositionX(), y), 1)
		end

		resNode:stopAllActions()
		resNode:runAction(cc.Sequence:create(moveBy, cc.DelayTime:create(0.05), cc.CallFunc:create(call)))
	end

	local cs = resNode:getChildByName("background"):getContentSize()


	local function onTouchBegan(touch, event)
		if cc.exports.g_activate_building then
			return false
		end

		-- ADD WJJ 20180710
		local zhuchengHelper = require("app.ExViewZhucheng"):getInstance()

		local location = touch:getLocation()
		
		local node = self:getResourceNode()
		node:stopActionByTag(kMoveActionTag)
		self:StopBackgroundMoving()

		it:setBegin(location,os.clock())

		moveRN = false
		zhuchengHelper:OnDrag(false)

		for i=1,CONF.EBuilding.count do
			local child = node:getChildByName(string.format("text_%d", i))
			if child ~= nil then
				zhuchengHelper.EffectManager:ScaleTo(child, 0.1, 1)
				-- child:runAction(cc.ScaleTo:create(0.1, 1))
			end
		end

		if self.uiLayer_:getIsBuildingOn() then
			self.uiLayer_:switchBuildingBtn(false, "")
		end

		local touch_zhong = false
		for i=1,CONF.EBuilding.count do
			local building = self:getResourceNode():getChildByName("building_"..i)
			local city = self:getResourceNode():getChildByName("background")

			local s = building:getContentSize()
			local locationInNode = building:convertToNodeSpace(touch:getLocation())
			local rect = cc.rect(0, 0, s.width, s.height)
			if cc.rectContainsPoint(rect, locationInNode) then


				if self:getResourceNode():getChildByName("building_"..i):isVisible() then
					self.g_index = i
					for k,ii in ipairs(CONF.PARAM.get("building activate").PARAM) do
						if self.g_index == ii and CONF.EFunctionOpenKey[ii] ~= "" then
							if player:getSystemGuideStep(CONF.FUNCTION_OPEN.get(CONF.EFunctionOpenKey[ii]).ID) == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() and player:getLevel() >= CONF.FUNCTION_OPEN.get(CONF.EFunctionOpenKey[ii]).GRADE then
								if CONF.FUNCTION_OPEN.get(CONF.EFunctionOpenKey[ii]).OPEN_GUIDANCE == 1 then
									return false
								end
							end
						end
					end  

					local _file = "CityScene/sfx/gaoliang/G"..i..".csb"
					animManager:runAnimByCSB(city:getChildByName("G"..i), _file, "1")
					-- print( "@@@ CityScene onTouchBegan anim : " .. tostring(_file) )

					touch_zhong = true
				end
			end
		end


		return true
	end

	local function onTouchMoved(touch, event)

		local gId = player:getGuideStep()


		-- if guideManager:getGuideType() then

		local can_move = true
		if gId < CONF.GUIDANCE.count() then
			can_move = false
		end
		if systemGuideManager:getGuideType()  then
			can_move = false
		end
		if not can_move  then

		else
			--ADD WJJ 180703
			self:OnDragScreen(touch, winSize, cs)
		end

		if self.g_index ~= 0 then
			local building = self:getResourceNode():getChildByName("building_"..self.g_index)
			local city = self:getResourceNode():getChildByName("background")

			local s = building:getContentSize()
			local locationInNode = building:convertToNodeSpace(touch:getLocation())
			local rect = cc.rect(0, 0, s.width, s.height)
			local _file = "CityScene/sfx/gaoliang/G"..self.g_index..".csb"
			local _is_rect = cc.rectContainsPoint(rect, locationInNode)
			if _is_rect then

				animManager:runAnimByCSB(city:getChildByName("G"..self.g_index), _file, "1")

			else
				animManager:runAnimByCSB(city:getChildByName("G"..self.g_index), _file, "0")

			end
			-- print( "@@@ CityScene onTouchMove anim : " .. tostring(_file) )
			-- print( "@@@ CityScene onTouchMove anim : " .. tostring(_is_rect) )
		end

	end

	local function onTouchEnded(touch, event)

		if( (self.touchBuilding == nil) or ( touch == nil ) ) then
			-- print("@@@ City self.touchBuilding or touch == nil ")
			do return false end
		end


		-- DO NOT check clicking building here

		local node = self:getResourceNode()

		local location = touch:getLocation()

		if moveRN then
		   local duration,distance = it:setEnd(location,os.clock())
		   if duration ~= nil then

				-- ADD WJJ 20180710
				duration = duration * self.DRAG_GUANXING_RATE

			   local moveBy = cc.EaseOut:create(cc.MoveBy:create(duration,distance),self.DRAG_EASE_RATE)
			-- local moveBy = cc.MoveBy:create(duration,distance)
			   moveBy:setTag(kMoveActionTag)
			   node:runAction(moveBy)
			if( self.isBackgroundQianjingStopped == false ) then
				self:OnDragBackground_Guanxing(duration, distance)
			end

			-- do not delay resume paused anim
			-- node:runAction(cc.Sequence:create(cc.DelayTime:create(duration), cc.CallFunc:create(function ( ... )
				self.zhuchengHelper:OnDrag(false)
			-- end)))
		else
			-- add wjj 20180727
			self.zhuchengHelper:OnDrag(false)

		   end
		


		else

			for i=1,CONF.EBuilding.count do
				local loc = touch:getLocation()
				if( loc ~= nil ) then
					local _self = cc.exports.G_Instance_CityScene
					if( _self ~= nil ) then

						_self:touchBuilding(i, loc)
					end
				end
	
			end

			-- self:touchBuilding("building_1_1", touch:getLocation())
		end

		if self.g_index ~= 0 then
			-- WJJ FIX BUG 20180712
			local _rn = cc.exports.g_zhucheng_res
			if(_rn ~= nil) then
				local city = _rn:getChildByName("background")
				local id = cc.exports.g_zhucheng_instance.g_index
				if( (id ~= nil) and (city ~= nil) ) then
					id = tostring(id)
					local _file = "CityScene/sfx/gaoliang/G".. id ..".csb"
					local _node = city:getChildByName("G".. id )
					if( _node ~= nil ) then
						animManager:runAnimByCSB(_node, _file, "0")
						
						-- print( "@@@ CityScene onTouchEnded anim : " .. tostring(_file) )
						self.g_index = 0
					end
				end
			end
		end

	end

	---------------------------------

	-- ADD WJJ 20180718
	cc.exports.g_zhucheng_instance = self
	cc.exports.g_zhucheng_res = self:getResourceNode()

	---------------------------------


	local eventDispatcher = self:getEventDispatcher()

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)

	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)


	local function adjustViewRange()

		local node = self:getResourceNode()
		local currentPosX, currentPosY = node:getPosition()
		local delta = currentPosX

		

		if delta < winSize.width - cs.width then
			delta = winSize.width - cs.width
			node:stopActionByTag(kMoveActionTag)
			node:setPositionX(delta)
			self:StopBackgroundMoving()
		elseif delta > 0 then
			delta = 0
			node:stopActionByTag(kMoveActionTag)
			node:setPositionX(delta)
			self:StopBackgroundMoving()
		end
	end

	local function update(dt)
		--ADD WJJ 20180703
		self:OnDragScreenDoMove(winSize, cs)
		adjustViewRange()

		if self.uiLayer_:getResourceNode():getChildByName("open_node"):getChildByName("node_open"):isVisible() == false and self.uiLayer_:getIsBuildingOn() == false then
			self.uiLayer_:getResourceNode():getChildByName("other_node"):setVisible(true)
		end

		-- if self.uiLayer_:getResourceNode():getChildByName("zhankai"):isVisible() then
		-- 	if self.uiLayer_:getResourceNode():getChildByName("next_di"):getTag() ~= 0 then
		-- 		if self.uiLayer_:getResourceNode():getChildByName("open_node"):getChildByName("node_open"):isVisible() == false then

		-- 			if self.uiLayer_:getResourceNode():getChildByName("next_btn"):getTag() == 160 then
		-- 				self.uiLayer_:getResourceNode():getChildByName("next_di"):setVisible(false)
		-- 			elseif self.uiLayer_:getResourceNode():getChildByName("next_btn"):getTag() == 159 then
		-- 				self.uiLayer_:getResourceNode():getChildByName("next_di"):setVisible(true)
		-- 			end
		-- 			self.uiLayer_:getResourceNode():getChildByName("next_btn"):setVisible(true)
		-- 		else
		-- 			self.uiLayer_:getResourceNode():getChildByName("next_di"):setVisible(false)
		-- 			self.uiLayer_:getResourceNode():getChildByName("next_btn"):setVisible(false)
		-- 		end
		-- 	end
		-- end

	end
	schedulerEntry = scheduler:scheduleScriptFunc(update,self.exConfig.DRAG_ZHUCHENG_FPS_INTERVAL,false)

	local function showLed( ... )
		local buildings = {1,3,4,5,7,10,11,12,13,14,16}
		for i,v in ipairs(buildings) do
			local info = player:getBuildingInfo(v)

			if info.upgrade_begin_time > 0 then
				self:getResourceNode():getChildByName("led_"..v):setVisible(true)

				local cd = CONF["BUILDING_"..v].get(info.level).CD + Tools.getValueByTechnologyAddition(CONF["BUILDING_"..v].get(info.level).CD, CONF.ETechTarget_1.kBuilding, v, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
				self:getResourceNode():getChildByName("led_"..v):getChildByName("text"):setString(formatTime(cd - (player:getServerTime() - info.upgrade_begin_time)))
			else
				self:getResourceNode():getChildByName("led_"..v):setVisible(false)
			end
		end
	end
	
	-- ADD WJJ 20180726
	local r_sfx = self:getResourceNode():getChildByName("background"):getChildByName("r_sfx")
	local r_sfx_x, r_sfx_y = r_sfx:getPosition()
	r_sfx:setPosition(r_sfx_x + self.BACKGROUND_LIU_GUANG_X, r_sfx_y + self.BACKGROUND_LIU_GUANG_Y)

	animManager:runAnimByCSB(r_sfx, "CityScene/sfx/city_17.csb", "1")
	animManager:runAnimByCSB(self:getResourceNode():getChildByName("background"):getChildByName("feijixunhuan"), "CityScene/sfx/feijixunhuan.csb", "1")
	showLed()
	local function runAnim(ui)
		animManager:runAnimByCSB(ui:getChildByName("yindao_1"), "GuideLayer/sfx/effect_0.csb", "1")
		animManager:runAnimByCSB(ui:getChildByName("yindao_2"), "GuideLayer/sfx/Kuang/Kuang.csb", "1")
	end
	local function setJiantouVisible(cfg,ui)
		ui:getChildByName("yindao_1"):setVisible(false)
		ui:getChildByName("yindao_2"):setVisible(false)
		if Tools.isEmpty(cfg.HINT) == false then
			if player:getLevel() >= cfg.GRADE then
				if player:getSystemGuideStep(cfg.ID)== 0 and g_System_Guide_Id == 0 then
					for k,v in ipairs(cfg.HINT) do
						if v == 1 then
							ui:getChildByName("yindao_1"):setVisible(true)
						elseif v == 2 then
							ui:getChildByName("yindao_2"):setVisible(true)
						end
					end
				else
					if g_System_Guide_Id ~= 0 then
						for k,v in ipairs(cfg.HINT) do
							if v == 1 then
								ui:getChildByName("yindao_1"):setVisible(true)
							elseif v == 2 then
								ui:getChildByName("yindao_2"):setVisible(true)
							end
						end
					end
				end
			end
		end
	end
	local function showJiantou()
		local rn = self:getResourceNode()
		
		local uiLayerRn = self.uiLayer_:getResourceNode()

		-- 殖民地
		local cfg_salve_open = CONF.FUNCTION_OPEN.get("slave_open")
		setJiantouVisible(cfg_salve_open,rn:getChildByName("home"))
		-- 预设队列
		local cfg_form_open = CONF.FUNCTION_OPEN.get("ysdl_open")
		setJiantouVisible(cfg_form_open,uiLayerRn:getChildByName("form"))
		-- 试炼
		--local cfg_trial_open = CONF.FUNCTION_OPEN.get("trial_open")
		--setJiantouVisible(cfg_trial_open,uiLayerRn:getChildByName("trial"))
		-- 竞技场
		--local cfg_arena_open = CONF.FUNCTION_OPEN.get("arena_open")
		--setJiantouVisible(cfg_arena_open,uiLayerRn:getChildByName("arena"))
		-- 星盟
		local cfg_league_open = CONF.FUNCTION_OPEN.get("league_open")
		setJiantouVisible(cfg_league_open,uiLayerRn:getChildByName("league"))
		-- 日常任务
		local cfg_dailyTask_open = CONF.FUNCTION_OPEN.get("task_open")
		setJiantouVisible(cfg_dailyTask_open,uiLayerRn:getChildByName("other_node"):getChildByName("daily_task"))
		-- 变强
		local cfg_strong_open = CONF.FUNCTION_OPEN.get("bq_open")
		setJiantouVisible(cfg_strong_open,uiLayerRn:getChildByName("other_node"):getChildByName("strong"))
		-- 活动
		local cfg_activity_open = CONF.FUNCTION_OPEN.get("hd_open")
		setJiantouVisible(cfg_activity_open,uiLayerRn:getChildByName("other_node"):getChildByName("huodong"))
		--好友
		local cfg_friend_open = CONF.FUNCTION_OPEN.get("friend_open")
		--if uiLayerRn:getChildByName("zhankai"):getTag() == 310 then
			setJiantouVisible(cfg_friend_open,uiLayerRn:getChildByName("friend"))
		--else
		--	uiLayerRn:getChildByName("friend"):getChildByName("yindao_1"):setVisible(false)
		--	uiLayerRn:("friend"):getChildByName("yindao_2"):setVisible(false)
		--end
	end
	local function runAnimCSB()
		local rn = self:getResourceNode()
		
		local uiLayerRn = self.uiLayer_:getResourceNode()

		-- 殖民地
		runAnim(rn:getChildByName("home"))
		-- 预设队列
		runAnim(uiLayerRn:getChildByName("form"))
		-- 试炼
		--runAnim(uiLayerRn:getChildByName("trial"))
		-- 竞技场
		--runAnim(uiLayerRn:getChildByName("arena"))
		-- 星盟
		runAnim(uiLayerRn:getChildByName("league"))
		-- 日常任务
		runAnim(uiLayerRn:getChildByName("other_node"):getChildByName("daily_task"))
		-- 变强
		runAnim(uiLayerRn:getChildByName("other_node"):getChildByName("strong"))
		-- 活动
		runAnim(uiLayerRn:getChildByName("other_node"):getChildByName("huodong"))
		--好友
		runAnim(uiLayerRn:getChildByName("friend"))
	end
	runAnimCSB()
	local function buildQueue(dt)
		self:resetBuildQueue()

		-- self.uiLayer_:task()

		showLed()
		resetTrade()
		showJiantou()
	end

	schedulerQueue = scheduler:scheduleScriptFunc(buildQueue,1,false)

	--
	local helperBtn = self:getResourceNode():getChildByName("building_btn_13")
	local playerName = player:getName()
	
	local function showHelperBtn()
		local btnShow = false
		if player:isGroup() then
			local group_data = player:getPlayerGroupMain()
			if group_data and Tools.isEmpty(group_data.help_list) == false then
				for k,data in ipairs(group_data.help_list) do
					if Tools.isEmpty(data.help_user_name_list) == false then
						local helpAlready = false
						for _,name in ipairs(data.help_user_name_list) do
							if name == playerName then
								helpAlready = true
							end
						end
						if not helpAlready then
							btnShow = true
						end
					else
						if data.user_name ~= playerName then
							btnShow = true
						end
					end
				end
			end
		end
		helperBtn:setVisible(btnShow)
		if player:getSystemGuideStep(CONF.FUNCTION_OPEN.get("wjj_open").ID) == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() and player:getLevel() >= CONF.FUNCTION_OPEN.get("wjj_open").GRADE then
			helperBtn:setVisible(false)
		end
		if player:getLevel() < CONF.FUNCTION_OPEN.get(13).GRADE then
			helperBtn:setVisible(false)
		end
	end
 	self:getResourceNode():getChildByName("building_btn_13"):addClickEventListener(function()
 		if cc.exports.g_activate_building then
			return
		end
 		local canHelpNameList = {}
 		if player:isGroup() then
			local group_data = player:getPlayerGroupMain()
			if group_data and Tools.isEmpty(group_data.help_list) == false then
				for k,data in ipairs(group_data.help_list) do
					if Tools.isEmpty(data.help_user_name_list) == false then
						local helpAlready = false
						for _,name in ipairs(data.help_user_name_list) do
							if name == playerName then
								helpAlready = true
							end
						end
						if not helpAlready then
							local helpinfo = {}
							helpinfo.user_name = data.user_name
							helpinfo.type = data.type
							helpinfo.id = data.id
							table.insert(canHelpNameList,helpinfo)
						end
					else
						if data.user_name ~= playerName then
							local helpinfo = {}
							helpinfo.user_name = data.user_name
							helpinfo.type = data.type
							helpinfo.id = data.id
							table.insert(canHelpNameList,helpinfo)
						end
					end
				end
			end
 		end
 		if Tools.isEmpty(canHelpNameList) == false then
 			local function send(index)
				local strData = Tools.encode("GroupHelpReq", {
					user_name = canHelpNameList[index].user_name,
					type = canHelpNameList[index].type,
					id = canHelpNameList[index].id,
				})

				g_sendList:addSend({define = "CMD_GROUP_HELP_REQ", strData = strData})
			end
			for k,v in ipairs(canHelpNameList) do
				send(k)
			end
 		end
 		end)
	broadcastRun()

	local function recvMsg()
		--print("CityScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_RESP") then

			local proto = Tools.decode("GetHomeSatusResp",strData)
			if proto.result == 0 then
				self:resetBuildQueue()
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_ADD_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("BuildQueueAddResp",strData)
			if proto.result == 0 then
				self:resetBuildQueue()
				-- self.uiLayer_:getResourceNode():getChildByName("Panel"):getChildByName("point_text"):setString(player:getMoney())
				tips:tips(CONF:getStringValue("open_queue_success"))
				local BuildTotalLayer = self:getResourceNode():getChildByName("BuildTotalLayer");
				if BuildTotalLayer ~= nil then
					BuildTotalLayer:refreshAllQueue();
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_RESP") then
			-- gl:releaseLoading()
			local proto = Tools.decode("GetGroupResp",strData)
			if proto.result ~= 0 then
				print("GetGroupResp error :",proto.result)
			else
				player:setPlayerGroupMain(proto.user_sync.group_main)
				showHelperBtn()
				if schedulerGroupHelper == nil then
					schedulerGroupHelper = scheduler:scheduleScriptFunc(showHelperBtn,5,false)
				end
			end

		-- elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_RESP") then

		-- 	local proto = Tools.decode("PlanetRideBackResp",strData)

		-- 	if proto.result ~= 0 then
		-- 		print("PlanetRideBackResp error :",proto.result)
		-- 	else
		-- 		print("proto.planet_res", proto.planet_res.ride_guid, proto.planet_res.cur_storage, proto.planet_res.collect_speed)
		-- 		table.insert( self.ride_info, proto.planet_res)

		-- 		if self.res_num == #self.ride_info then
		-- 			player:setRideResInfo(self.ride_info)
		-- 		end
		-- 	end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_CLIENT_GM_RESP") then

			local proto = Tools.decode("CmdClientGMResp",strData)
			print("CMD_CLIENT_GM_RESP result",proto.result)

			-- gl:releaseLoading()

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPDATE_RESP") then

			local proto = Tools.decode("BuildingUpdateResp",strData)
			print("CMD_BUILDING_UPDATE_RESP result",proto.result)

			if proto.result == 0 then

				if proto.index == CONF.EBuilding.kTrade then
					return
				end

				if player:getPower() ~= g_Player_Fight then

					self.fight_delegate_:setUpNum(player:getPower())
					
					if schedulerFight == nil then
						schedulerFight = scheduler:scheduleScriptFunc(updateFight,0.01,false)
					end
					g_Player_Fight = player:getPower()

				end
				self:openAmiByUpGrade(proto.index)
                local buildinginfo = player:getBuildingInfo(proto.index)
				if buildinginfo.upgrade_begin_time == 0 then
					self:getResourceNode():getChildByName("text_"..proto.index):getChildByName("num"):setString("Lv."..buildinginfo.level)
                    local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("BuildingName_"..proto.index).."Lv."..buildinginfo.level..CONF:getStringValue("UpgradeSucess"))
					node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(node)
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_RESP") then
			
			local proto = Tools.decode("GetChatLogResp",strData)
			print("city GetChatLogResp result",proto.result)

			-- gl:releaseLoading()

			if proto.result < 0 then
				print("error :",proto.result)
			else
				-- if not self.show_di_text then
					self.show_di_text = true

					local time = 0
					local str = ""
					local tt 

					for i,v in ipairs(proto.log_list) do
						if v.stamp > time then
							if v.user_name ~= "0" and not player:isBlack(v.user_name) then
								time = v.stamp

								-- local chat = handsomeSubString(v.chat, 8)
								-- local last = v.chat

								-- if v.group_name ~= "" then
								-- 	str = string.format("[%s]%s:%s", v.group_name, v.nickname, chat)
								-- else
								-- 	str = string.format("%s:%s", v.nickname, chat)
								-- end
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
					end
					
					if player:getLastChat() == nil then
						self.uiLayer_:getResourceNode():getChildByName("chat"):getChildByName("point"):setVisible(true)
					else
						if tt and player:getLastChat().user_name == tt.user_name and player:getLastChat().chat == tt.chat and player:getLastChat().time == tt.time then
							self.uiLayer_:getResourceNode():getChildByName("chat"):getChildByName("point"):setVisible(false)
						else
							self.uiLayer_:getResourceNode():getChildByName("chat"):getChildByName("point"):setVisible(true)
						end
					end

					self.uiLayer_:getResourceNode():getChildByName("di_text"):setString(str)

				-- end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then
			local proto = Tools.decode("PlanetGetResp",strData)
			print("PlanetGetResp result",proto.result, proto.type)

			gl:releaseLoading()
			if proto.result == 0 then
				if proto.type == 1 then

					player:setPlayerPlanetUser(proto.planet_user)
				end
        	end

        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_RESP") then

			local proto = Tools.decode("SlaveSyncDataResp",strData)
			--print("SlaveSyncDataResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else
				local rn = self:getResourceNode()
				local city = rn:getChildByName("background")

				if proto.slave_data_list[1].master == nil or proto.slave_data_list[1].master == "" then

					city:getChildByName("slave_text"):setString(CONF:getStringValue("colony"))
					
				else

					city:getChildByName("slave_text"):setString(proto.info_list[1].master_nickname..CONF:getStringValue("colony"))
					
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_RESP") then
			local proto = Tools.decode("GroupHelpResp",strData)
			print("CityScene GroupHelpResp ",proto.result)
			if proto.result ~= "OK" then
				if proto.result == "HELP_TIME_MAX" then
					tips:tips(CONF:getStringValue("help")..CONF:getStringValue("times_not_enought"))
				elseif proto.result == "NO_DATA" then
					tips:tips(CONF:getStringValue("ally")..CONF:getStringValue("building")..CONF:getStringValue("BuildingUpOk"))
				elseif proto.result == "NO_CD" then
					tips:tips(CONF:getStringValue("ally")..CONF:getStringValue("building")..CONF:getStringValue("BuildingUpOk"))
				else
					print("error :",proto.result)
				end
			else
				tips:tips(CONF:getStringValue("help win"))
				player:setPlayerGroupMain(proto.user_sync.group_main)
				showHelperBtn()
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRADE_GET_MONEY_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TradeGetMoneyResp",strData)
			print("CMD_TRADE_GET_MONEY_RESP result",proto.result)

			if proto.result == 0 then
				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				resetTrade()
			end
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

	self.friendListener_ = cc.EventListenerCustom:create("NewFriendUpdate", function ()
		self.uiLayer_:getResourceNode():getChildByName("friend"):getChildByName("red"):setVisible(true)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.friendListener_, FixedPriority.kNormal)

	self.strengthListener_ = cc.EventListenerCustom:create("StrengthUpdated", function ()
		self:resetStrength()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.strengthListener_, FixedPriority.kNormal)

	self.seeChatListener_ = cc.EventListenerCustom:create("seeChat", function ()
		self.uiLayer_:getResourceNode():getChildByName("chat"):getChildByName("point"):setVisible(false)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.seeChatListener_, FixedPriority.kNormal)

	self.frListener_ = cc.EventListenerCustom:create("firstRecharge", function ()
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self:getParent(), {index = 1})
		self:addChild(rechargeNode)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.frListener_, FixedPriority.kNormal)

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
		self.uiLayer_:getResourceNode():getChildByName("di_text"):setString(chat)
		if self.uiLayer_:getResourceNode():getChildByName("richText") then
			self.uiLayer_:getResourceNode():getChildByName("richText"):removeFromParent()
		end
		if player:getLastChat() and player:getLastChat().user_name == "0" then
			local label2 = createRichTextNeedChangeColor(string.format("%s:%s", event.chat.sender.nickname, chat))
			label2:setName("richText")
			label2:setPosition(cc.p(self.uiLayer_:getResourceNode():getChildByName("di_text"):getPosition()))
			label2:setAnchorPoint(cc.p(0,0.5))
			label2:ignoreContentAdaptWithSize(false)  
			label2:setContentSize(self.uiLayer_:getResourceNode():getChildByName("di_text"):getContentSize())
			self.uiLayer_:getResourceNode():addChild(label2)
			self.uiLayer_:getResourceNode():getChildByName("di_text"):setVisible(false)
		end
		if self:getChildByName("chatLayer") then
			self.uiLayer_:getResourceNode():getChildByName("chat"):getChildByName("point"):setVisible(false)
		else
			self.uiLayer_:getResourceNode():getChildByName("chat"):getChildByName("point"):setVisible(true)
		end

	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.worldListener_, FixedPriority.kNormal)

	self.posListener = cc.EventListenerCustom:create("changeCityPos", function (event)

		local building_name 
		local building
		local x
		local y 
		local building_num = event.num

		if event.num then
			building_name = "building_"..event.num
			building = resNode:getChildByName(building_name)
			x,y = building:getPosition()
		end

		local type = event.type
		--print("aaaaaaaaaaaaaa",event.pos,resNode:getPositionX(),(winSize.width-CC_DESIGN_RESOLUTION.width)/2)
		--resNode:runAction(cc.Sequence:create(cc.MoveBy:create(0.2, cc.p(event.pos - resNode:getPositionX(), 0)), cc.CallFunc:create(function ( )
		resNode:runAction(cc.Sequence:create(cc.MoveBy:create(0.2, cc.p((event.pos - resNode:getPositionX()) + (winSize.width-CC_DESIGN_RESOLUTION.width)/2 , 0)), cc.CallFunc:create(function ( )
			guideManager:setMsgType(true)
			systemGuideManager:setMsgType(true)

			print("resNode:runAction",resNode:getPositionX(),event.pos,(winSize.width-CC_DESIGN_RESOLUTION.width)/2 )

			if type ~= 2 and (building_num == 1 or building_num == 3 or building_num == 4 or building_num == 5 or building_num == 7 or  building_num == 12) then
				self.uiLayer_:switchBuildingBtn(true, building_name, cc.p(x + resNode:getPositionX(), y), 1) 
			end
		end)))

		
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.posListener, FixedPriority.kNormal)

	self.broadcastListener_ = cc.EventListenerCustom:create("broadcastRun", function ()
		broadcastRun()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.broadcastListener_, FixedPriority.kNormal)

	self.guideListener_ = cc.EventListenerCustom:create("GuideOver", function ()
		self:openCity()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.guideListener_, FixedPriority.kNormal)

	self.jihuo1Listener_ = cc.EventListenerCustom:create("jihuo_1", function ()
		resNode:getChildByName("btn_jihuo_3"):setVisible(true)
		resNode:getChildByName('background'):getChildByName("city_3"):setVisible(true)
		animManager:runAnimByCSB(resNode:getChildByName('background'):getChildByName("city_3"), "CityScene/sfx/city_3.csb", "grey")
		if resNode:getChildByName('background'):getChildByName("city_3"):getChildByName("icon_suo") then
			resNode:getChildByName('background'):getChildByName("city_3"):getChildByName("icon_suo"):setVisible(false)
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.jihuo1Listener_, FixedPriority.kNormal)

	self.jihuo2Listener_ = cc.EventListenerCustom:create("jihuo_2", function ()
		resNode:getChildByName('background'):getChildByName("city_12"):setVisible(true)
		resNode:getChildByName("btn_jihuo_12"):setVisible(true)
		animManager:runAnimByCSB(resNode:getChildByName('background'):getChildByName("city_12"), "CityScene/sfx/city_12.csb", "grey")
		if resNode:getChildByName('background'):getChildByName("city_12"):getChildByName("icon_suo") then
			resNode:getChildByName('background'):getChildByName("city_12"):getChildByName("icon_suo"):setVisible(false)
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.jihuo2Listener_, FixedPriority.kNormal)

	self.jihuo3Listener_ = cc.EventListenerCustom:create("jihuo_3", function ()
		resNode:getChildByName('background'):getChildByName("city_5"):setVisible(true)
		resNode:getChildByName("btn_jihuo_5"):setVisible(true)
		animManager:runAnimByCSB(resNode:getChildByName('background'):getChildByName("city_5"), "CityScene/sfx/city_5.csb", "grey")
		if resNode:getChildByName('background'):getChildByName("city_5"):getChildByName("icon_suo") then
			resNode:getChildByName('background'):getChildByName("city_5"):getChildByName("icon_suo"):setVisible(false)
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.jihuo3Listener_, FixedPriority.kNormal)

	self.jihuo4Listener_ = cc.EventListenerCustom:create("jihuo_4", function ()
		resNode:getChildByName('background'):getChildByName("city_9"):setVisible(true)
		resNode:getChildByName("btn_jihuo_9"):setVisible(true)
		animManager:runAnimByCSB(resNode:getChildByName('background'):getChildByName("city_9"), "CityScene/sfx/city_9.csb", "grey")
		if resNode:getChildByName('background'):getChildByName("city_9"):getChildByName("icon_suo") then
			resNode:getChildByName('background'):getChildByName("city_9"):getChildByName("icon_suo"):setVisible(false)
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.jihuo4Listener_, FixedPriority.kNormal)

	self.xiufuListener_ = cc.EventListenerCustom:create("main_xiufu", function ()
		local xiao_chui_zi = resNode:getChildByName("btn_xiufu")
		xiao_chui_zi:setVisible(true)
		-- FIX XIAO CHUI ZI POSITION
		-- wjj 20180802
		xiao_chui_zi:setPositionX(xiao_chui_zi:getPositionX() + self.GUIDE_xiao_chui_zi_x_offset  )

		resNode:getChildByName('background'):getChildByName("city_1"):setVisible(true)
		animManager:runAnimByCSB(resNode:getChildByName('background'):getChildByName("city_1"), "CityScene/sfx/city_1.csb", "grey")
		if resNode:getChildByName('background'):getChildByName("city_1"):getChildByName("icon_suo") then
			resNode:getChildByName('background'):getChildByName("city_1"):getChildByName("icon_suo"):setVisible(false)
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.xiufuListener_, FixedPriority.kNormal)

	self.levelupListener_ = cc.EventListenerCustom:create("playerLevelUp", function ()
		self:openCity()
		self:openAmiByLevelUp()
		self:openBtn()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.levelupListener_, FixedPriority.kNormal)

	self.jihuo11Listener_ = cc.EventListenerCustom:create("jihuo_11", function ()
		resNode:getChildByName("btn_jihuo_11"):setVisible(true)
		resNode:getChildByName('background'):getChildByName("city_11"):setVisible(true)
		animManager:runAnimByCSB(resNode:getChildByName('background'):getChildByName("city_11"), "CityScene/sfx/city_11.csb", "grey")
		if resNode:getChildByName('background'):getChildByName("city_11"):getChildByName("icon_suo") then
			resNode:getChildByName('background'):getChildByName("city_11"):getChildByName("icon_suo"):setVisible(false)
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.jihuo11Listener_, FixedPriority.kNormal)

	self.jihuo10Listener_ = cc.EventListenerCustom:create("jihuo_10", function ()
		resNode:getChildByName("btn_jihuo_10"):setVisible(true)
		resNode:getChildByName('background'):getChildByName("city_10"):setVisible(true)
		animManager:runAnimByCSB(resNode:getChildByName('background'):getChildByName("city_10"), "CityScene/sfx/city_10.csb", "grey")
		if resNode:getChildByName('background'):getChildByName("city_10"):getChildByName("icon_suo") then
			resNode:getChildByName('background'):getChildByName("city_10"):getChildByName("icon_suo"):setVisible(false)
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.jihuo10Listener_, FixedPriority.kNormal)


	-- Add wjj 20180605
	-- print("## Lua GuideLayer showGuideAnim2 ")
	self.showGuideAnim2Listener_ = cc.EventListenerCustom:create("showGuideAnim2", function ()
		-- print("## Lua GuideLayer showGuideAnim2 function createView ")
		local layer = self:getApp():createView("GuideLayer/GuideAnimLayer", {anim = "2"})
		self:addChild(layer)
		-- print("## Lua GuideLayer showGuideAnim2 function createView END")
	end)

	self.guide_showBuilding = cc.EventListenerCustom:create("guide_activate_building",function(event)
		if event.buildingNum and event.buildingNum >= 1 and event.buildingNum <= CONF.EBuilding.count then
			self:getResourceNode():getChildByName("building_"..event.buildingNum):setVisible(true)
			self:getResourceNode():getChildByName("text_"..event.buildingNum):setVisible(true)
		end
		end)
	eventDispatcher:addEventListenerWithFixedPriority(self.showGuideAnim2Listener_, FixedPriority.kNormal)
	eventDispatcher:addEventListenerWithFixedPriority(self.guide_showBuilding, FixedPriority.kNormal)
	-- self.showGuideAnim1Listener_ = cc.EventListenerCustom:create("showGuideAnim1", function ()
	-- 	print("shoudao showGuideAnim1")
	-- 	local layer = self:getApp():createView("GuideLayer/GuideAnimLayer", {anim = "1"})
	-- 	self:addChild(layer)
	-- end)
	-- eventDispatcher:addEventListenerWithFixedPriority(self.showGuideAnim1Listener_, FixedPriority.kNormal)
	if guideManager:getShowGuide() == false  then
		-- guideManager:addGuideStep(CONF.GUIDANCE.get(CONF.GUIDANCE.getIDList()[CONF.GUIDANCE.count()]).ID+1)
		 guideManager:addGuideStep(1000)
	end
	local guide 
	if guideManager:getSelfGuideID() ~= 0 then
		guide = guideManager:getSelfGuideID()
	else
		guide = player:getGuideStep()
	end
	if (guide <= 6) and g_show_guide then
		-- guideManager:createGuideLayer(3)
		local layer = self:getApp():createView("GuideLayer/GuideAnimLayer", {anim = "1"})
		self:addChild(layer)
	else
		guideManager:checkInterface(CONF.EInterface.kMain)
	end

	if g_show_system_guide == false then
		for  i=1,25 do
			local id = i*100+1
			local strData = Tools.encode("GuideStepReq", {
		        type = 1,
		        step_index = math.floor(id/100)+1,
		        step_num = id,
		    })
			g_sendList:addSend({define = "CMD_GUIDE_STEP_REQ", strData = strData})
		end
	end

	if self.data_.strong_index then
		self:getApp():addView2Top("StrongLayer/StrongLayer", {index = self.data_.strong_index})
	elseif self.data_.go == "ShipsForm" then
		self:getApp():getTopViewData().go = nil
		self:getApp():pushView("ShipsScene/ShipsDevelopScene",{type = player:getTypeToShipsScene(), go = "form"})

	end

	-- ADD WJJ 20180703
	-- self:KeepStopLoading()

	self:InitBackgrounds()
end
-- end of 437 onEnterTransitionFinish

function CityScene:resetStrength( )
	self.uiLayer_:setStrengthPercent()
end

function CityScene:update( dt )

	if self.fight_delegate_:getFlag() then
		self.fight_delegate_:update()
	else
		scheduler:unscheduleScriptEntry(schedulerFight)
		schedulerFight = nil
	end
end

function CityScene:resetRes()

	for i=1,4 do
		self.uiLayer_:getResourceNode():getChildByName("you"):getChildByName("res_text_"..i):setString(formatRes(player:getResByIndex(i)))
	end

	self.uiLayer_:getResourceNode():getChildByName("you"):getChildByName("money_num"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
end

function CityScene:openAmiByLevelUp()
	local rn = self:getResourceNode()
	local city = rn:getChildByName("background")
	local param_open_key = CONF.EParamOpenKey
	local diff = {}
	for k,v in ipairs(CONF.PARAM.get("building lock").PARAM) do
		local ins = true
		for k,i in ipairs(CONF.PARAM.get("building activate").PARAM) do
			if v == i then
				ins = false
			end
		end
		if ins then
			table.insert(diff,v)
		end
	end
	for k,i in ipairs(diff) do
		if city:getChildByName(string.format("city_%d", i)) ~= nil and param_open_key[i] ~= "" then
			if player:getLevel() < CONF.PARAM.get(param_open_key[i]).PARAM[1] or player:getBuildingInfo(1).level < CONF.PARAM.get(param_open_key[i]).PARAM[2] then
				animManager:runAnimByCSB(city:getChildByName(string.format("city_%d", i)), string.format("CityScene/sfx/city_%d.csb", i),  "grey")
			else
				animManager:runAnimByCSB(city:getChildByName(string.format("city_%d", i)), string.format("CityScene/sfx/city_%d.csb", i),  "1")
			end
		end
	end
end
function CityScene:openAmiByUpGrade(index)
	local rn = self:getResourceNode()
	local city = rn:getChildByName("background")
	for k,i in ipairs(CONF.PARAM.get("building level").PARAM) do
		if city:getChildByName(string.format("city_%d", i)) ~= nil then
			if player:getBuildingInfo(i) ~= nil then
				if index then
					if i == index then
						animManager:runAnimByCSB(city:getChildByName(string.format("city_%d", i)), string.format("CityScene/sfx/city_%d.csb", i),  "1")
					end
				else
					if player:getBuildingInfo(i).upgrade_begin_time > 0 then
						animManager:runAnimByCSB(city:getChildByName(string.format("city_%d", i)), string.format("CityScene/sfx/city_%d.csb", i),  "2")
					else
						animManager:runAnimByCSB(city:getChildByName(string.format("city_%d", i)), string.format("CityScene/sfx/city_%d.csb", i),  "1")
					end
				end
			end

		end
	end
end

function CityScene:openAmi()
	
	local rn = self:getResourceNode()
	local city = rn:getChildByName("background")

	for i=1,16 do
		if city:getChildByName("G"..i) then
			animManager:runAnimByCSB(city:getChildByName("G"..i), "CityScene/sfx/gaoliang/G"..i..".csb", "0")
		end
		if city:getChildByName(string.format("city_%d", i)) ~= nil then
			animManager:runAnimByCSB(city:getChildByName(string.format("city_%d", i)), string.format("CityScene/sfx/city_%d.csb", i),  "1")
		end

		if city:getChildByName(string.format("feiji_%d", i)) ~= nil then
			animManager:runAnimByCSB(city:getChildByName(string.format("feiji_%d", i)), string.format("CityScene/sfx/feiji_%d.csb", i),  "1")
		end

	end

	animManager:runAnimByCSB(city:getChildByName(string.format("feiji")), string.format("CityScene/sfx/feiji.csb"),  "1")
	animManager:runAnimByCSB(city:getChildByName(string.format("liuxing")), string.format("CityScene/sfx/liuxing.csb"),  "1")
	animManager:runAnimByCSB(city:getChildByName("shitou"), "CityScene/sfx/city_shitou.csb",  "1")
	animManager:runAnimByCSB(rn:getChildByName("feijida"), "CityScene/sfx/feijidadou.csb",  "1")
	self:openAmiByUpGrade()
	self:openAmiByLevelUp()
	self:openBtn()
end

function CityScene:onExitTransitionStart()
	printInfo("CityScene:onExitTransitionStart()")


	-- ADD WJJ 20180703
	self.exConfig.isMainGameSceneEntered = true
	-- ADD WJJ 20180709
	cc.exports.lastExitZhuchengTime = os.clock()

	scheduler:unscheduleScriptEntry(schedulerEntry)

	if schedulerQueue ~= nil then
		scheduler:unscheduleScriptEntry(schedulerQueue)
	end

	if schedulerFight ~= nil then
		scheduler:unscheduleScriptEntry(schedulerFight)
		schedulerFight = nil
	end

	if schedulerGroupHelper ~= nil then
		scheduler:unscheduleScriptEntry(schedulerGroupHelper)
		schedulerGroupHelper = nil
	end

	self.data_.pos = self:getResourceNode():getPositionX()
	g_city_scene_pos = self.data_.pos

	if self.data_.function_id then
		self.data_.function_id = nil
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.friendListener_)
	eventDispatcher:removeEventListener(self.strengthListener_)
	eventDispatcher:removeEventListener(self.frListener_)
	eventDispatcher:removeEventListener(self.posListener)
	eventDispatcher:removeEventListener(self.worldListener_)
	eventDispatcher:removeEventListener(self.broadcastListener_)
	eventDispatcher:removeEventListener(self.seeChatListener_)
	eventDispatcher:removeEventListener(self.guideListener_)
	eventDispatcher:removeEventListener(self.jihuo1Listener_)
	eventDispatcher:removeEventListener(self.jihuo2Listener_)
	eventDispatcher:removeEventListener(self.jihuo3Listener_)
	eventDispatcher:removeEventListener(self.jihuo4Listener_)
	eventDispatcher:removeEventListener(self.xiufuListener_)
	eventDispatcher:removeEventListener(self.showGuideAnim2Listener_)
	-- eventDispatcher:removeEventListener(self.showGuideAnim1Listener_)
	eventDispatcher:removeEventListener(self.levelupListener_)
	eventDispatcher:removeEventListener(self.guide_showBuilding)
	eventDispatcher:removeEventListener(self.jihuo11Listener_)
	eventDispatcher:removeEventListener(self.jihuo10Listener_)

	-- WJJ 20180712
	cc.exports.G_Instance_CityScene = nil

	---------------------------------

	-- ADD WJJ 20180718
	cc.exports.g_zhucheng_instance = nil
	cc.exports.g_zhucheng_res = nil

	---------------------------------
end

return CityScene