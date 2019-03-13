
local VisibleRect = cc.exports.VisibleRect

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local player = require("app.Player"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local HomeScene = class("HomeScene", cc.load("mvc").ViewBase)

HomeScene.RESOURCE_FILENAME = "HomeScene/Scene.csb"

HomeScene.RESOURE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

HomeScene.NEED_ADJUST_POSITION = true

HomeScene.RUN_TIMELINE = true

local schedulerEntry = nil

local touchMove = false

local updateTime = 20

local timeUpPos = 30


local landZOrder = 15
local infoZOrder = 16

function HomeScene:onCreate(data)

	if data then
		self.data_ = data
	end
	if data and data.sfx then
		data.sfx = false
		self:getApp():addView2Top("CityScene/TransferScene",{from = "home" ,state = "enter"})
	end
end

function HomeScene:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" and event.target:getName() == "close" then
		playEffectSound("sound/system/return.mp3")
		-- self:getApp():popView()
		-- self:getApp():pushToRootView("CityScene/CityScene", {pos = -350})
	end
end

function HomeScene:onEnter()
	
	printInfo("HomeScene:onEnter()")
end

function HomeScene:onExit()
	
	printInfo("HomeScene:onExit()")
end

function HomeScene:resetBuildQueue()

	local rn = self:getResourceNode()

	local queue = rn:getChildByName("Panel_3"):getChildByName("queue")
	if player:getNormalBuildingQueueNow() then

		local info = player:getBuildingQueueBuild(1)
		queue:getChildByName("point"):setVisible(false)
		if info.type == 1 then

			queue:setTag(1)
			queue:getChildByName("jianzhu"):setTag(info.index)
			queue:getChildByName("jianzhu"):loadTexture(CONF.EBuildingICON[info.index])
			queue:getChildByName("mask"):setVisible(true)
			queue:getChildByName("jianzhu"):setVisible(true)

			local building_info = player:getBuildingInfo(info.index)

			local conf = CONF[string.format("BUILDING_%d",info.index)].get(building_info.level)
			  
			local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
			local time =  cd - (player:getServerTime() - building_info.upgrade_begin_time)
			rn:getChildByName("Panel_3"):getChildByName("queue_time"):setString(formatTime(time))
			

		elseif info.type == 2 then
			local landInfo = player:getLandType(info.index)

			queue:setTag(2)
			queue:getChildByName("jianzhu"):setTag(info.index)

			local resource = math.floor(landInfo.resource_type/1000)*1000+1
			queue:getChildByName("jianzhu"):loadTexture("HomeIcon/"..resource..".png")
			queue:getChildByName("jianzhu"):setVisible(true)
			queue:getChildByName("mask"):setVisible(true)

			local conf = CONF.RESOURCE.get(landInfo.resource_type)

			local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kHomeBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
			local time = cd - (player:getServerTime() - landInfo.res_refresh_times)

			rn:getChildByName("Panel_3"):getChildByName("queue_time"):setString(formatTime(time))

			if time <= 0 then

				local texiao_node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/qianghua.csb")

				texiao_node:getChildByName("text"):setString(CONF:getStringValue(conf.NAME).."Lv."..(landInfo.resource_level + 1)..CONF:getStringValue("UpgradeSucess"))

				texiao_node:getChildByName("text"):runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
					texiao_node:getChildByName("text"):setVisible(true)
				end)))
				animManager:runAnimOnceByCSB(texiao_node:getChildByName("texiao"), "ShipsScene/sfx/qianghua.csb", "1", function ( ... )
					texiao_node:removeFromParent()
				end)
				texiao_node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(texiao_node)

				-- tips:tips(CONF:getStringValue("UpgradeSucess"))

				local strData = Tools.encode("GetHomeSatusReq", {
					home_type = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)
			end
			
		end

	else
		rn:getChildByName("Panel_3"):getChildByName("queue_time"):setString(CONF:getStringValue("leisure"))
		queue:getChildByName("jianzhu"):setVisible(false)
		queue:getChildByName("mask"):setVisible(false)
		queue:getChildByName("point"):setVisible(true)
	end

	-----------
	local money_queue = rn:getChildByName("Panel_3"):getChildByName("money_queue")
	if player:getMoneyBuildingQueueOpen() then

		local info = player:getBuildingQueueBuild(2)

		if player:getMoneyBuildingQueueNow() then

			money_queue:getChildByName("point"):setVisible(false)
			money_queue:getChildByName("money"):setVisible(false)
			money_queue:getChildByName("money_num"):setVisible(false)
			rn:getChildByName("Panel_3"):getChildByName("money_queue_time"):setVisible(true)

			if info.type == 1 then

				money_queue:setTag(1)
				money_queue:getChildByName("jianzhu"):setTag(info.index)
				money_queue:getChildByName("jianzhu"):loadTexture(CONF.EBuildingICON[info.index])
				rn:getChildByName("Panel_3"):getChildByName("money_queue_time"):setVisible(true)
				money_queue:getChildByName("mask"):setVisible(true)

				money_queue:getChildByName("jianzhu"):setVisible(true)

				local building_info = player:getBuildingInfo(info.index)

				local conf = CONF[string.format("BUILDING_%d",info.index)].get(building_info.level)
				  
				local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
				local time =  conf.CD - (player:getServerTime() - building_info.upgrade_begin_time)
				rn:getChildByName("Panel_3"):getChildByName("money_queue_time"):setString(formatTime(time))
				

			elseif info.type == 2 then

				local landInfo = player:getLandType(info.index)

				money_queue:setTag(2)
				money_queue:getChildByName("jianzhu"):setTag(info.index)
				local resource = math.floor(landInfo.resource_type/1000)*1000+1
				money_queue:getChildByName("jianzhu"):loadTexture("HomeIcon/"..resource..".png")
				rn:getChildByName("Panel_3"):getChildByName("money_queue_time"):setVisible(true)
				money_queue:getChildByName("jianzhu"):setVisible(true)
				money_queue:getChildByName("mask"):setVisible(true)        

				local conf = CONF.RESOURCE.get(landInfo.resource_type)

				local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kHomeBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
				local time = cd - (player:getServerTime() - landInfo.res_refresh_times)

				rn:getChildByName("Panel_3"):getChildByName("money_queue_time"):setString(formatTime(time))

				if time <= 0 then

					local texiao_node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/qianghua.csb")

					texiao_node:getChildByName("text"):setString(CONF:getStringValue(conf.NAME).."Lv."..(landInfo.resource_level + 1)..CONF:getStringValue("UpgradeSucess"))

					texiao_node:getChildByName("text"):runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
						texiao_node:getChildByName("text"):setVisible(true)
					end)))
					animManager:runAnimOnceByCSB(texiao_node:getChildByName("texiao"), "ShipsScene/sfx/qianghua.csb", "1", function ( ... )
						texiao_node:removeFromParent()
					end)
					texiao_node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(texiao_node)
					
					-- tips:tips(CONF:getStringValue("UpgradeSucess"))

					local strData = Tools.encode("GetHomeSatusReq", {
						home_type = 1,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)
				end

			end

		else
			rn:getChildByName("Panel_3"):getChildByName("money_queue_time"):setVisible(true)
			money_queue:getChildByName("jianzhu"):setVisible(false)
			money_queue:getChildByName("money"):setVisible(false)
			money_queue:getChildByName("money_num"):setVisible(false)
			money_queue:getChildByName("mask"):setVisible(false)
			money_queue:getChildByName("point"):setVisible(true)

			local time = info.duration_time - (player:getServerTime() - info.open_time)
			rn:getChildByName("Panel_3"):getChildByName("money_queue_time"):setString(formatTime(time))
		end
	else
		rn:getChildByName("Panel_3"):getChildByName("money_queue_time"):setVisible(false)
		money_queue:getChildByName("jianzhu"):setVisible(false)
		money_queue:getChildByName("money"):setVisible(true)
		money_queue:getChildByName("money_num"):setVisible(true)
		money_queue:getChildByName("mask"):setVisible(false)
		money_queue:getChildByName("point"):setVisible(false)
	end
	rn:getChildByName("Panel_3"):getChildByName("money_queue_time"):setVisible(false)
end


function HomeScene:onEnterTransitionFinish()
	printInfo("HomeScene:onEnterTransitionFinish()")
	-- self:getResourceNode():getChildByName("Panel_2"):getChildByName("Text_4"):setString(CONF:getStringValue("totolInfo"))

	broadcastRun()

	guideManager:checkInterface(CONF.EInterface.kHome)
	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kSlave)== 0 and g_System_Guide_Id == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() then
		-- print( "##LUA 260 HomeScene.lua createGuideLayer : " .. tostring(CONF.FUNCTION_OPEN.get("slave_open").INTERFACE) )
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("slave_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			-- print( "##LUA 263 HomeScene.lua createGuideLayer : " .. tostring(g_System_Guide_Id) )
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end

	local strData = Tools.encode("SlaveSyncDataReq", {    
		type = 0,
		user_name_list = {player:getName()} ,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_REQ"),strData)
	gl:retainLoading()

	self.landNode_ = nil
	self.infoNode_ = nil
	self.buildingNodes = {}
	self.landBuild = {}
	self.landInfo = {}
	self.updateTime = 0

	--xuanzhong
	--self.chooseNode = cc.Sprite:create("CityScene/ui2/ui_icon_function.png")
	self.chooseNode = cc.Sprite:create()
	self:getResourceNode():addChild(self.chooseNode)
	self.chooseNode:setVisible(false)

	-- self.uiLayer_ = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeLayer.csb")
	-- self:getResourceNode():addChild(self.uiLayer_)
	self.uiLayer_ = self:getResourceNode():getChildByName("Panel_2")

	self:getResourceNode():getChildByName("Panel_3"):setLocalZOrder(10)

	local function addMoney( sender, eventType )
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self, {index = 1})
		self:addChild(rechargeNode)
	end

	self.uiLayer_:getChildByName("res_5"):getChildByName("add"):addClickEventListener(addMoney)
	self.uiLayer_:getChildByName("res_5"):getChildByName("money_touch"):addClickEventListener(addMoney)

	local rn = self:getResourceNode()

	rn:getChildByName("btn_slave"):addClickEventListener(function ( ... )

		if player:getLevel() < CONF.FUNCTION_OPEN.get("slave_open").GRADE then
			tips:tips(CONF:getStringValue("level_slave"))
			return
		end

		self:getApp():pushToRootView("SlaveScene/SlaveScene")
	end)

	rn:getChildByName("QianJing"):setLocalZOrder(9)

	for i=1,12 do

		if i <= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).RESOURCE_NUM then
			local newNode = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/NEWjianzhu.csb")
			newNode:setPosition(cc.p(rn:getChildByName("land_"..i):getPositionX(), rn:getChildByName("land_"..i):getPositionY()))
			newNode:setName("newNode_"..i)
			rn:addChild(newNode)

			animManager:runAnimByCSB(newNode, "HomeScene/NEWjianzhu.csb",  "1")
		else
			local newNode = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/suo.csb")
			newNode:setPosition(cc.p(rn:getChildByName("land_"..i):getPositionX(), rn:getChildByName("land_"..i):getPositionY()))
			newNode:setName("newNode_"..i)
			rn:addChild(newNode)

			animManager:runAnimByCSB(newNode, "HomeScene/suo.csb",  "2")
		end
	end

	rn:getChildByName("Panel_1"):getChildByName("alloy"):setString(CONF:getStringValue("HomeBuildingName_1"))
	rn:getChildByName("Panel_1"):getChildByName("crystal"):setString(CONF:getStringValue("HomeBuildingName_2"))
	rn:getChildByName("Panel_1"):getChildByName("energy"):setString(CONF:getStringValue("HomeBuildingName_3"))

	local queue = rn:getChildByName("Panel_3"):getChildByName("queue")
	queue:addClickEventListener(function( ... )
		playEffectSound("sound/system/click.mp3")
		if player:getNormalBuildingQueueNow() then

			local rn = self:getResourceNode()
			
			if queue:getTag() == 1 then
				self:getApp():pushToRootView("CityScene/CityScene", {pos = -1350, index = queue:getChildByName("jianzhu"):getTag()})
			else
				self:clickLand(queue:getChildByName("jianzhu"):getTag())
			end
		else
   			goScene(2, 11)
   
		end
	end)

	local money_queue = rn:getChildByName("Panel_3"):getChildByName("money_queue")
	money_queue:getChildByName("money_num"):setString(CONF.PARAM.get("queue_buy_num").PARAM)
	money_queue:addClickEventListener(function( ... )
		playEffectSound("sound/system/click.mp3")
		if player:getMoneyBuildingQueueOpen() then
			if player:getMoneyBuildingQueueNow() then
				
				if money_queue:getTag() == 1 then
					self:getApp():pushToRootView("CityScene/CityScene", {pos = -1350, index = money_queue:getChildByName("jianzhu"):getTag()})
				else
					self:clickLand(money_queue:getChildByName("jianzhu"):getTag())
				end
			else
   				goScene(2, 11)
	   
			end
		else   

			local function func( ... )
				if player:getMoneyBuildingQueueOpen() then

					if player:getMoneyBuildingQueueNow() then
						-- tips:tips(CONF:getStringValue("money build queue is upgrade now, can't buy"))
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
		
	end)


	self.uiLayer_:getChildByName("close"):setLocalZOrder(99)

	local strData = Tools.encode("GetHomeSatusReq", {
			home_type = 1,
		})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)


	local eventDispatcher = self:getEventDispatcher()

	self.uiLayer_:getChildByName("close"):addClickEventListener(function (sender )
		playEffectSound("sound/system/return.mp3")
		-- self:getApp():popView()
		-- self:getApp():pushToRootView("CityScene/CityScene", {pos = -350})
		self:getApp():addView2Top("CityScene/TransferScene",{from = "city2" ,state = "start"})
		
	end)

	--播放特效

	local children = rn:getChildren()

	for i,v in ipairs(children) do

		local name = v:getName()
		local filePath = string.format("HomeScene/%s.csb", name)

		local file = cc.FileUtils:getInstance():isFileExist(filePath)
		if file then
			animManager:runAnimByCSB(v, filePath,  "1")
		end

		-- local filePath_X = string.format("ChapterScene/Chanjing/%d/%s_X.csb", i, name)
		-- local file_X = cc.FileUtils:getInstance():isFileExist(filePath_X)
		-- if file_X then
		--     animManager:runAnimOnceByCSB(vv, filePath_X,  "1", function()
		--         animManager:runAnimByCSB(vv, filePath_X,  "2")
		--     end)
		-- end
			
	end

	--播放进入界面动画
	animManager:runAnimOnceByCSB(rn, "HomeScene/Scene.csb",  "intro", function ( ... )
		 animManager:runAnimByCSB(rn:getChildByName("qiu"), "HomeScene/qiu.csb", "1")
	end)

	if self.data_.index then
		self:clickLand(self.data_.index)
	end

	--touch

	for i=1,12 do
		rn:getChildByName("land_"..i):addClickEventListener(function ( sender)
			playEffectSound("sound/system/click.mp3")

			if player:getBuildingInfo(1).level >= self:toBuildingLevel(i) then
				self:clickLand(i)
			else

				tips:tips(CONF:getStringValue("BuildingName_1")..self:toBuildingLevel(i)..CONF:getStringValue("level_ji")..CONF:getStringValue("open"))
			end
			
		end)
	end

	local function onTouchBegan(touch, event)

		touchMove = false

		return true
	end

	local function onTouchMoved(touch, event)

		local diff = touch:getDelta()
		if math.abs(diff.x) < g_click_delta and math.abs(diff.y) < g_click_delta then
			
		else
			touchMove = true
		end

	end

	local function onTouchEnded(touch, event)

		local resNode = self:getResourceNode()

		local location = touch:getLocation()

		if touchMove == false then

			for i,v in ipairs(self.landBuild) do
				local locationInNode = v:convertToNodeSpace(touch:getLocation())
				local s = v:getContentSize()
				local rect = cc.rect(0, 0, s.width, s.height)
				if cc.rectContainsPoint(rect, locationInNode) then

					self:clickLand(v:getTag())
					return 
				end
			end

			if self.landNode_ ~= nil then
				self.landNode_:removeFromParent()
				self.landNode_ = nil
			end
			
			if self.infoNode_ then
				self.infoNode_:removeFromParent()
				self.infoNode_ = nil
			end

			self.chooseNode:setVisible(false)
			
		else


		end

	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)

	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)


	local function recvMsg()

		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_UPGRADE_RESOURCE_RESP") then

			gl:releaseLoading()

			if self.landNode_ ~= nil then
				self.landNode_:removeFromParent()
				self.landNode_ = nil
			end

			self.chooseNode:setVisible(false)

			local proto = Tools.decode("UpgradeResLandResp",strData)
			if proto.result == 0 then
				
				-- local resNode = self:getResourceNode()
				-- local build = cc.Sprite:create(string.format("HomeIcon/%d001.png", proto.resource_type))
				-- local land = resNode:getChildByName(string.format("land_%d", proto.land_index))
				-- land:addChild(build)
				-- build:setPosition(cc.p(land:getContentSize().width, 20))

				if player:getLandType(self.chooseNode:getTag()) == nil then
					local texiao_node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/qianghua.csb")

					texiao_node:getChildByName("text"):setString(CONF:getStringValue("switch_form"))

					texiao_node:getChildByName("text"):runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
						texiao_node:getChildByName("text"):setVisible(true)
					end)))
					animManager:runAnimOnceByCSB(texiao_node:getChildByName("texiao"), "ShipsScene/sfx/qianghua.csb", "1", function ( ... )
						texiao_node:removeFromParent()
					end)
					texiao_node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(texiao_node)

				end

				local strData = Tools.encode("GetHomeSatusReq", {
					home_type = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_RESP") then

			local proto = Tools.decode("GetHomeSatusResp",strData)
			if proto.result == 0 then

				self.landInfo = player:getLandInfo()

				if player:isGroup() then
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_LIST_REQ"),"0") 
				end

				-- for i,v in ipairs(self.landBuild) do
				--     v:removeFromParent()
				-- end

				-- self.landBuild = {}

				-- for k,v in pairs(self.buildingNodes) do
				--     v.buingingNode:removeFromParent()
				-- end

				-- self.buildingNodes = {}

				for i=1,5 do
					local res = self.uiLayer_:getChildByName("res_"..i)
					if i < 5 then
						res:getChildByName("text"):setString(formatRes(player:getResByIndex(i)))
					else
						res:getChildByName("text"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
					end
				end

				-- local proto = Tools.decode("GetHomeSatusResp",strData)

				-- if self.landNode_ ~= nil then
				--     self.landNode_:setLocalZOrder(100)
				-- end

				-- for i=1,player:getMaxLandNum() do

				--     local landType = player:getLandType(i)

				--     if landType ~= nil then

				--         if landType.resource_type ~= 0 then

				--             if landType.resource_status == 2 then

				--                 local buildType = math.floor(landType.resource_type/1000)
				--                 local build = cc.Sprite:create(string.format("HomeIcon/%d001.png", buildType))
				--                 build:setPosition(cc.p(rn:getChildByName(string.format("land_%d", i)):getPositionX(), rn:getChildByName(string.format("land_%d", i)):getPositionY()+20))
				--                 rn:addChild(build)

				--                 self.landBuild[#self.landBuild+1] = build

				--                 if landType.resource_num == CONF.RESOURCE.get(landType.resource_type).STORAGE then
					
				--                     local node = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeNode.csb")
				--                     rn:addChild(node)
				--                     node:setPosition(cc.p(rn:getChildByName(string.format("land_%d", i)):getPositionX(), rn:getChildByName(string.format("land_%d", i)):getPositionY()+timeUpPos))
												  
				--                     self.landBuild[#self.landBuild+1] = node
				--                 elseif landType.resource_num >= CONF.RESOURCE.get(landType.resource_type).STORAGE*0.6 then
				--                     local node = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeNode.csb")
				--                     node:getChildByName("max"):getChildByName("icon"):setTexture("CityScene/ui2/ui_icon_002.png")
				--                     node:getChildByName("max"):getChildByName("icon"):setScale(2)
				--                     rn:addChild(node)
				--                     node:setPosition(cc.p(rn:getChildByName(string.format("land_%d", i)):getPositionX(), rn:getChildByName(string.format("land_%d", i)):getPositionY()+timeUpPos))

				--                     self.landBuild[#self.landBuild+1] = node

				--                 end


				--             elseif landType.resource_status == 1 then

				--                 local buingingNode = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeBuildingNode.csb")
				--                 buingingNode:getChildByName("times"):setString(formatTime(CONF.RESOURCE.get(landType.resource_type).CD - (player:getServerTime() - landType.res_refresh_times)))

				--                 buingingNode:setPosition(cc.p(rn:getChildByName(string.format("land_%d", i)):getPositionX(), rn:getChildByName(string.format("land_%d", i)):getPositionY()+timeUpPos))
				--                 rn:addChild(buingingNode)

				--                 local table = {index = i, buingingNode = buingingNode}
				--                 self.buildingNodes[#self.buildingNodes+1] = table

				--             else            

				--             end
				
				--         end

				--     end

				-- end

				self:updateUI()
				self:resetBuildQueue()
			end
			
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_REMOVE_RESOURCE_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("RemoveResLandResp",strData)

			self.landNode_:removeFromParent()
			self.landNode_ = nil

			self.chooseNode:setVisible(false)

			if proto.result == 0 then

				tips:tips(CONF:getStringValue("dismantle_success"))


				local strData = Tools.encode("GetHomeSatusReq", {
					home_type = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_RESOURCE_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("GetResourceResp",strData)
			if proto.result == 0 then

				--增加资源
				if proto.result == 0 then

					-- local strData = Tools.encode("GetHomeSatusReq", {
					--     home_type = 1,
					-- })
					-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)

					-- if self.buingingNodes then
					--     for i,v in pairs(self.buingingNodes) do
					--         print(v.index)
					--         if proto.land_index == v.index then
					--             v.buingingNode:setVisible(false)
					--         end
					--     end
					-- end

					player:resetResourceNum(proto.land_index)
					self:updateUI()

					local ttfConfig = {}
					ttfConfig.fontFilePath = s_default_font
					ttfConfig.fontSize = 20

					local str = string.format("+%d", proto.resource_num)
					local label = cc.Label:createWithTTF(ttfConfig,str,cc.VERTICAL_TEXT_ALIGNMENT_CENTER,400)
					label:setTextColor(cc.c4b(255,255,255,255))
					self:getResourceNode():addChild(label)
					label:setPosition(cc.p(rn:getChildByName(string.format("land_%d", proto.land_index)):getPositionX(), rn:getChildByName(string.format("land_%d", proto.land_index)):getPositionY()+10))
					label:setLocalZOrder(99)

					local moveTo
					local moveTo2
					local worldPos
					if math.floor(proto.resource_type/1000) == 1 then
						moveTo = cc.MoveTo:create(1, self.uiLayer_:getChildByName("res_2"):getChildByName("text"):convertToWorldSpace(cc.p(0, 0)))
						moveTo2 = cc.MoveTo:create(1, self.uiLayer_:getChildByName("res_2"):getChildByName("icon"):convertToWorldSpace(cc.p(0, 0)))
					elseif math.floor(proto.resource_type/1000) == 2 then
						moveTo = cc.MoveTo:create(1, self.uiLayer_:getChildByName("res_3"):getChildByName("text"):convertToWorldSpace(cc.p(0, 0)))
						moveTo2 = cc.MoveTo:create(1, self.uiLayer_:getChildByName("res_3"):getChildByName("icon"):convertToWorldSpace(cc.p(0, 0)))
					elseif math.floor(proto.resource_type/1000) == 3 then
						moveTo = cc.MoveTo:create(1, self.uiLayer_:getChildByName("res_4"):getChildByName("text"):convertToWorldSpace(cc.p(0, 0)))
						moveTo2 = cc.MoveTo:create(1, self.uiLayer_:getChildByName("res_4"):getChildByName("icon"):convertToWorldSpace(cc.p(0, 0)))
					end

					label:runAction(cc.Sequence:create(cc.MoveBy:create(0.2, cc.p(0,20)), moveTo, cc.CallFunc:create(function ( ... )
						-- player:setResByIndex(math.floor(proto.resource_type/1000)+1, proto.resource_num)

						local strData = Tools.encode("GetHomeSatusReq", {
							home_type = 1,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)

						label:removeFromParent()

					end)))

					local icon = cc.Sprite:create("Common/ui/ui_icon_00"..math.floor(proto.resource_type/1000)..".png")
					icon:setScale(0.5)
					icon:setPosition(label:getPositionX() - label:getContentSize().width/2 - 20, label:getPositionY())
					icon:runAction(cc.Sequence:create(cc.MoveBy:create(0.2, cc.p(0,20)), moveTo2, cc.CallFunc:create(function ( ... )
						icon:removeFromParent()
					end)))
					self:getResourceNode():addChild(icon)

					
				end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_CANCEL_BUILD_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("CancelResBuildingResp",strData)

			if proto.result == 0 then

				tips:tips(CONF:getStringValue("successful operation"))

				self.landNode_:removeFromParent()
				self.landNode_ = nil

				local strData = Tools.encode("GetHomeSatusReq", {
					home_type = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SPEED_UP_BUILD_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("SpeedUpBuildResp",strData)

			if proto.result == 0 then

				if proto.user_sync.user_info.money == nil then
					player:setMoney(0)
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("MoneyUpdated")
				end

				local texiao_node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/qianghua.csb")
                local landInfo = player:getLandType(proto.land_index)
                local conf = CONF.RESOURCE.get(landInfo.resource_type)
				texiao_node:getChildByName("text"):setString(CONF:getStringValue(conf.NAME).."Lv."..(landInfo.resource_level + 1)..CONF:getStringValue("UpgradeSucess"))

				texiao_node:getChildByName("text"):runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
					texiao_node:getChildByName("text"):setVisible(true)
				end)))
				animManager:runAnimOnceByCSB(texiao_node:getChildByName("texiao"), "ShipsScene/sfx/qianghua.csb", "1", function ( ... )
					texiao_node:removeFromParent()
				end)
				texiao_node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(texiao_node)

				if self.landNode_ then
					self.landNode_:removeFromParent()
					self.landNode_ = nil
				end

				local strData = Tools.encode("GetHomeSatusReq", {
					home_type = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_ADD_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("BuildQueueAddResp",strData)
			if proto.result == 0 then
				self:resetBuildQueue()
				tips:tips(CONF:getStringValue("open_queue_success"))
				-- self.uiLayer_:getResourceNode():getChildByName("Panel"):getChildByName("point_text"):setString(player:getMoney())
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_LIST_RESP") then
			local proto = Tools.decode("GroupHelpListResp",strData)

			if proto.result ~= "OK" then
				-- print("error :",proto.result)
			else
				
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_REQUEST_HELP_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("GroupRequestHelpResp",strData)

			if proto.result == "HELPED" then
				tips:tips(CONF:getStringValue("requested_help"))
			elseif proto.result == "REQUESTED" then
				tips:tips(CONF:getStringValue("requested_group_help"))
			elseif proto.result == "NO_CD" then
				tips:tips(CONF:getStringValue("help_full"))
			elseif proto.result ~= "OK" then
				print("GroupRequestHelpResp error :",proto.result)
			else
				tips:tips(CONF:getStringValue("request_help_succeed"))

				self.infoNode_:getChildByName("help"):setVisible(false)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_SYNC_DATA_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SlaveSyncDataResp",strData)
			--print("SlaveSyncDataResp",proto.result)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else

				if proto.slave_data_list[1].master == nil or proto.slave_data_list[1].master == "" then

					rn:getChildByName("slave_text"):setString(CONF:getStringValue("colony"))
					
				else

					rn:getChildByName("slave_text"):setString(proto.info_list[1].master_nickname..CONF:getStringValue("colony"))
					
				end
			end

		end

	end
		
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		self:resetRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)

	self.broadcastListener_ = cc.EventListenerCustom:create("broadcastRun", function ()
		broadcastRun()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.broadcastListener_, FixedPriority.kNormal)


	local function update(dt)
		self:updateUI()
		self:resetBuildQueue()

		self.updateTime = self.updateTime + 1
		if self.updateTime >= updateTime then

			self.updateTime = 0 

			local strData = Tools.encode("GetHomeSatusReq", {
				home_type = 1,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)

		end

	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Jiayuan(self)
end

function HomeScene:toBuildingLevel( land_num )
	for i,v in ipairs(CONF.BUILDING_1.getIDList()) do
		local conf = CONF.BUILDING_1.get(v)
		if conf.RESOURCE_NUM >= land_num then
			return i 
		end
	end


	return 0
end

function HomeScene:resetRes( ... )
	for i=1,5 do
		local res = self.uiLayer_:getChildByName("res_"..i)
		if i < 5 then
			res:getChildByName("text"):setString(formatRes(player:getResByIndex(i)))
		else
			res:getChildByName("text"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
		end
	end
end

function HomeScene:clickLand(index)

	local rn = self:getResourceNode()

	if rn:getChildByName(string.format("land_%d", index)) == nil then
		return
	end

	local landType = player:getLandType(index)

	if self.landNode_ ~= nil then
		self.landNode_:removeFromParent()
		self.landNode_ = nil
	end

	if self.infoNode_ then
		self.infoNode_:removeFromParent()
		self.infoNode_ = nil
	end

	if self.chooseNode then

		self.chooseNode:setTag(index)
		self.chooseNode:setPosition(cc.p(rn:getChildByName(string.format("land_%d", index)):getPositionX(), rn:getChildByName(string.format("land_%d", index)):getPositionY()+5))
		self.chooseNode:setVisible(true)
	end

	if landType == nil then

		self.landNode_ = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeBuildInfo.csb")
		-- self.landNode_:setPosition(cc.p(rn:getChildByName(string.format("midpos")):getPosition()))
		self.landNode_:setPosition(cc.p(self.chooseNode:getPosition()))

		self.landNode_:getChildByName("smelting_plant"):getChildByName("text"):setString(CONF:getStringValue("HomeBuildingName_1"))
		self.landNode_:getChildByName("ore_collecting"):getChildByName("text"):setString(CONF:getStringValue("HomeBuildingName_2"))
		self.landNode_:getChildByName("energy_station"):getChildByName("text"):setString(CONF:getStringValue("HomeBuildingName_3"))

		self.landNode_:getChildByName("mid"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/click.mp3")
			self.landNode_:removeFromParent()
			self.landNode_ = nil
		end)

		self.landNode_:getChildByName("smelting_plant"):addClickEventListener(function ( )
			playEffectSound("sound/system/click.mp3")
			local strData = Tools.encode("UpgradeResLandReq", {
				land_index = index,
				resource_type = 1001,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPGRADE_RESOURCE_REQ"),strData)

			gl:retainLoading()
		end)

		self.landNode_:getChildByName("ore_collecting"):addClickEventListener(function ( )
			playEffectSound("sound/system/click.mp3")
			local strData = Tools.encode("UpgradeResLandReq", {
				land_index = index,
				resource_type = 2001,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPGRADE_RESOURCE_REQ"),strData)

			gl:retainLoading()
		end)

		local conf = CONF.BUILDING_1.get(player:getBuildingInfo(CONF.EBuilding.kMain).level)
		if #conf.RESOURCE_TYPE == 3 then
			self.landNode_:getChildByName("energy_station"):addClickEventListener(function ( )
				playEffectSound("sound/system/click.mp3")
				local strData = Tools.encode("UpgradeResLandReq", {
					land_index = index,
					resource_type = 3001,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPGRADE_RESOURCE_REQ"),strData)

				gl:retainLoading()
			end)
		else
			self.landNode_:getChildByName("energy_station"):getChildByName("locked"):setVisible(true)
			-- self.landNode_:getChildByName("energy_station"):setTouchEnabled(false)
			self.landNode_:getChildByName("energy_station"):addClickEventListener(function ( )
				playEffectSound("sound/system/click.mp3")
				tips:tips(CONF:getStringValue("need")..CONF:getStringValue("CentreLevel")..10)
			end)
		end

		rn:addChild(self.landNode_,landZOrder)

	else
	
		if landType.resource_type == 0 or landType.resource_type == nil then
			self.landNode_ = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeBuildInfo.csb")
			-- self.landNode_:setPosition(cc.p(rn:getChildByName(string.format("midpos")):getPosition()))
			self.landNode_:setPosition(cc.p(self.chooseNode:getPosition()))
			-- self.landNode_:setPosition(cc.exports.VisibleRect:center())

			local conf = CONF.BUILDING_1.get(player:getBuildingInfo(CONF.EBuilding.kMain).level)
			self.landNode_:getChildByName("smelting_plant"):getChildByName("text"):setString(CONF:getStringValue("HomeBuildingName_1"))
			self.landNode_:getChildByName("ore_collecting"):getChildByName("text"):setString(CONF:getStringValue("HomeBuildingName_2"))
			self.landNode_:getChildByName("energy_station"):getChildByName("text"):setString(CONF:getStringValue("HomeBuildingName_3"))

			self.landNode_:getChildByName("mid"):addClickEventListener(function ( ... )
				self.landNode_:removeFromParent()
				self.landNode_ = nil
			end)
	
			self.landNode_:getChildByName("smelting_plant"):addClickEventListener(function ( )
				playEffectSound("sound/system/click.mp3")
				local strData = Tools.encode("UpgradeResLandReq", {
					land_index = index,
					resource_type = 1001,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPGRADE_RESOURCE_REQ"),strData)

				gl:retainLoading()
			end)
	
			self.landNode_:getChildByName("ore_collecting"):addClickEventListener(function ( )
				playEffectSound("sound/system/click.mp3")
				local strData = Tools.encode("UpgradeResLandReq", {
					land_index = index,
					resource_type = 2001,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPGRADE_RESOURCE_REQ"),strData)

				gl:retainLoading()
			end)
	
			if #conf.RESOURCE_TYPE == 3 then
				self.landNode_:getChildByName("energy_station"):addClickEventListener(function ( )
					playEffectSound("sound/system/click.mp3")
					local strData = Tools.encode("UpgradeResLandReq", {
						land_index = index,
						resource_type = 3001,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPGRADE_RESOURCE_REQ"),strData)

					gl:retainLoading()
				end)


			else
				self.landNode_:getChildByName("energy_station"):getChildByName("locked"):setVisible(true)
				self.landNode_:getChildByName("energy_station"):setTouchEnabled(false)
			end
	
			rn:addChild(self.landNode_,landZOrder)
	
		else
	
			local status = landType.resource_status
			if status == 2 then
				if landType.resource_num > 1 then

					self.chooseNode:setVisible(false)
					--增加资源
					local strData = Tools.encode("GetResourceReq", {
						land_index = index,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_RESOURCE_REQ"),strData)
	
					gl:retainLoading()
				else
	
					self.landNode_ = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeBuild.csb")
					self.landNode_:getChildByName("info"):getChildByName("text"):setString(CONF:getStringValue("information"))
					self.landNode_:getChildByName("dismantle"):getChildByName("text"):setString(CONF:getStringValue("dismantle"))
					self.landNode_:getChildByName("upgrade"):getChildByName("text"):setString(CONF:getStringValue("upgrade"))
					
					local is_max = false
					if landType.resource_level == 45 then
						is_max = true
					end

					if is_max then
						self.landNode_:getChildByName("upgrade"):setVisible(false)
					end

					-- self.landNode_:setPosition(cc.p(rn:getChildByName(string.format("midpos")):getPosition()))
					self.landNode_:setPosition(cc.p(self.chooseNode:getPosition()))

					-- self.landNode_:setPosition(cc.exports.VisibleRect:center())
					rn:addChild(self.landNode_,landZOrder)

					self.landNode_:getChildByName("mid"):addClickEventListener(function ( ... )
						playEffectSound("sound/system/click.mp3")
						if self.infoNode_ then
							self.infoNode_:removeFromParent()
							self.infoNode_ = nil
						end

						self.landNode_:removeFromParent()
						self.landNode_ = nil
					end)

					self.landNode_:getChildByName("info"):addClickEventListener(function ( ... )
						playEffectSound("sound/system/click.mp3")

						if self.infoNode_ then
							self.infoNode_:removeFromParent()
							self.infoNode_ = nil
						else

							self.infoNode_ = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeBuildingInfo.csb")
							self.infoNode_:getChildByName("Text_10_1"):setString(CONF:getStringValue("Storage"))
							self.infoNode_:getChildByName("Text_10"):setString(CONF:getStringValue("Yields") .. CONF:getStringValue("hours"))
							self.infoNode_:getChildByName("Lv"):setString(CONF:getStringValue("level"))
	
							local buildType = math.floor(landType.resource_type/1000)
							if buildType == 1 then
								self.infoNode_:getChildByName("build_name"):setString(CONF:getStringValue("HomeBuildingName_"..buildType))
							elseif buildType == 2 then
								self.infoNode_:getChildByName("build_name"):setString(CONF:getStringValue("HomeBuildingName_"..buildType))
							elseif buildType == 3 then
								self.infoNode_:getChildByName("build_name"):setString(CONF:getStringValue("HomeBuildingName_"..buildType))
							end
		
							self.infoNode_:getChildByName("build_icon"):setTexture("HomeIcon/"..buildType.."001.png")
		
							if not is_max then
								local add = 1+(CONF.VIP.get(player:getVipLevel()).EXTRA_HOME_RESOURCE/100)
								self.infoNode_:getChildByName("old_level"):setString(landType.resource_level)
								self.infoNode_:getChildByName("new_level"):setString(landType.resource_level+1)
								self.infoNode_:getChildByName("yield"):setString(CONF.RESOURCE.get(landType.resource_type).PRODUCTION_NUM*add)
								self.infoNode_:getChildByName("yield_upnum"):setString(CONF.RESOURCE.get(landType.resource_type+1).PRODUCTION_NUM*add-CONF.RESOURCE.get(landType.resource_type).PRODUCTION_NUM*add)
								self.infoNode_:getChildByName("storage"):setString(CONF.RESOURCE.get(landType.resource_type).STORAGE)
								self.infoNode_:getChildByName("storage_upnum"):setString(CONF.RESOURCE.get(landType.resource_type+1).STORAGE-CONF.RESOURCE.get(landType.resource_type).STORAGE)
						        --Changed By JinXin 20180625
								self.infoNode_:setPosition(cc.p((winSize.width + (rn:getContentSize().width - winSize.width))/2, (winSize.height + (rn:getContentSize().height - winSize.height))/2))
								rn:addChild(self.infoNode_, infoZOrder)
		
								self.infoNode_:getChildByName("Image_3"):setVisible(false)
								self.infoNode_:getChildByName("new_level"):setVisible(false)
								self.infoNode_:getChildByName("Text_10_0_0_0"):setVisible(false)
								self.infoNode_:getChildByName("yield_upnum"):setVisible(false)
								self.infoNode_:getChildByName("Text_10_0_0_0_0"):setVisible(false)
								self.infoNode_:getChildByName("storage_upnum"):setVisible(false)
							else
								self.infoNode_:getChildByName("old_level"):setString(landType.resource_level)
								local add = 1+(CONF.VIP.get(player:getVipLevel()).EXTRA_HOME_RESOURCE/100)
								self.infoNode_:getChildByName("yield"):setString(CONF.RESOURCE.get(landType.resource_type).PRODUCTION_NUM*add)
								self.infoNode_:getChildByName("storage"):setString(CONF.RESOURCE.get(landType.resource_type).STORAGE)
						
								self.infoNode_:setPosition(cc.p((winSize.width + (rn:getContentSize().width - winSize.width))/2, (winSize.height + (rn:getContentSize().height - winSize.height))/2))
								rn:addChild(self.infoNode_, infoZOrder)
		
								self.infoNode_:getChildByName("Image_3"):setVisible(false)
								self.infoNode_:getChildByName("new_level"):setVisible(false)
								self.infoNode_:getChildByName("Text_10_0_0_0"):setVisible(false)
								self.infoNode_:getChildByName("yield_upnum"):setVisible(false)
								self.infoNode_:getChildByName("Text_10_0_0_0_0"):setVisible(false)
								self.infoNode_:getChildByName("storage_upnum"):setVisible(false)
								self.infoNode_:getChildByName("new_level"):setVisible(false)
								self.infoNode_:getChildByName("yield_upnum"):setVisible(false)
								self.infoNode_:getChildByName("storage_upnum"):setVisible(false)
								self.infoNode_:getChildByName("Image_3"):setVisible(false)
							end
						end

					end)
	
					self.landNode_:getChildByName("upgrade"):addClickEventListener(function ( )
						playEffectSound("sound/system/click.mp3")
						if self.infoNode_ then
							self.infoNode_:removeFromParent()
							self.infoNode_ = nil
						end

						self.landNode_:removeFromParent()
						self.landNode_ = nil
	
						self.landNode_ = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeBuildUpInfo.csb")
						self.landNode_:getChildByName("Storage"):setString(CONF:getStringValue("Storage"))
						self.landNode_:getChildByName("yh"):setString(CONF:getStringValue("Yields") .."/".. CONF:getStringValue("hours"))
						self.landNode_:getChildByName("conditions"):setString(CONF:getStringValue("Conditions"))
						self.landNode_:getChildByName("upgrade"):getChildByName("text"):setString(CONF:getStringValue("upgrade"))
						self.landNode_:getChildByName("cost"):setString(CONF:getStringValue("Cost"))
						self.landNode_:getChildByName("lv"):setString(CONF:getStringValue("level"))

						self.landNode_:getChildByName("conditions_text"):setString(CONF:getStringValue("BuildingName_1").." Lv.")
						self.landNode_:getChildByName("conditions_num"):setPositionX(self.landNode_:getChildByName("conditions_text"):getPositionX() + self.landNode_:getChildByName("conditions_text"):getContentSize().width + 2)
	
						local buildType = math.floor(landType.resource_type/1000)
						if buildType == 1 then
							self.landNode_:getChildByName("build_name"):setString(CONF:getStringValue("HomeBuildingName_"..buildType))
						elseif buildType == 2 then
							self.landNode_:getChildByName("build_name"):setString(CONF:getStringValue("HomeBuildingName_"..buildType))
						elseif buildType == 3 then
							self.landNode_:getChildByName("build_name"):setString(CONF:getStringValue("HomeBuildingName_"..buildType))
						end
	
						self.landNode_:getChildByName("build_icon"):setTexture("HomeIcon/"..buildType.."001.png")
	
						self.landNode_:getChildByName("old_level"):setString(landType.resource_level)
						self.landNode_:getChildByName("new_level"):setString(landType.resource_level+1)
						local add = 1+(CONF.VIP.get(player:getVipLevel()).EXTRA_HOME_RESOURCE/100)
						local yield_upnum = CONF.RESOURCE.get(landType.resource_type+1).PRODUCTION_NUM*add-CONF.RESOURCE.get(landType.resource_type).PRODUCTION_NUM*add
						self.landNode_:getChildByName("yield"):setString(CONF.RESOURCE.get(landType.resource_type).PRODUCTION_NUM*add.."+"..yield_upnum)
						-- self.landNode_:getChildByName("yield_upnum"):setString()
						local storage_upnum = CONF.RESOURCE.get(landType.resource_type+1).STORAGE-CONF.RESOURCE.get(landType.resource_type).STORAGE
						self.landNode_:getChildByName("storage"):setString(CONF.RESOURCE.get(landType.resource_type).STORAGE.."+"..storage_upnum)
						-- self.landNode_:getChildByName("storage_upnum"):setString()

						-- textSetPos(self.landNode_:getChildByName("yh"),self.landNode_:getChildByName("yield"), 15, 1)
						-- textSetPos(self.landNode_:getChildByName("Storage"),self.landNode_:getChildByName("storage"), 15, 1)
						textSetPos(self.landNode_:getChildByName("conditions_text"),self.landNode_:getChildByName("conditions_num"), 0, 1)
						-- self.landNode_:setPosition(cc.p(rn:getChildByName(string.format("midpos")):getPosition()))
						-- self.landNode_:setPosition(cc.p(winSize.width/2 + (rn:getContentSize().width - winSize.width)/2, rn:getContentSize().height/2 + (rn:getContentSize().height - winSize.height)/2))
--						local center = cc.exports.VisibleRect:center()
--	                    self.landNode_:setPosition(cc.p(center.x - self.landNode_:getChildByName("back"):getContentSize().width/2, center.y - self.landNode_:getChildByName("back"):getContentSize().height/2))
--                        self.landNode_:setPosition(cc.exports.VisibleRect:center())
--                        require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQuanmianping_HomeBuildUpInfo(self.landNode_)
						rn:addChild(self.landNode_, landZOrder)
                        self.landNode_:setPosition(rn:getChildByName("midpos"):getPosition())
	
						local conf = CONF.RESOURCE.get(player:getLandType(index).resource_type)                 
						local canUpgrade = true
						local item_pos = cc.p(self.landNode_:getChildByName("item_pos"):getPosition())
						for i,v in ipairs(conf.ITEM_ID) do
							local haveNum = player:getItemNumByID(v)
							local needNum = conf.ITEM_NUM[i]
	
							local item_node = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/item_need.csb")
							item_node:getChildByName("item_num"):setString(needNum)
							item_node:getChildByName("item_icon"):setTexture(string.format("ItemIcon/%d.png", CONF.ITEM.get(v).ICON_ID))
	

							item_node:setPosition(cc.p(item_pos.x+(120*(i-1)), item_pos.y))
							self.landNode_:addChild(item_node)
							if haveNum < needNum then
								canUpgrade = false
							end
						end
	
						self.landNode_:getChildByName("time"):setString(formatTime(conf.CD))
		
						self.landNode_:getChildByName("conditions_num"):setString(conf.MAIN_BUILDING_LEVEL)
						if player:getBuildingInfo(CONF.EBuilding.kMain).level < conf.MAIN_BUILDING_LEVEL then
							self.landNode_:getChildByName("conditions_text"):setTextColor(cc.c4b(255, 0, 0, 255))
							-- self.landNode_:getChildByName("conditions_text"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
							self.landNode_:getChildByName("conditions_num"):setTextColor(cc.c4b(255, 0, 0, 255))
							-- self.landNode_:getChildByName("conditions_num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
	
							canUpgrade = false
						end

						self.landNode_:getChildByName("upgrade"):addClickEventListener(function( ... )
							playEffectSound("sound/system/click.mp3")

							if canUpgrade then
								local nh = true
								if player:getNormalBuildingQueueNow() then
									if not player:getMoneyBuildingQueueOpen() then
										-- tips:tips(CONF:getStringValue("has build upgrade now"))
										local time = conf.CD/3600

										local num = math.ceil(time/CONF.PARAM.get("queue_buy_time").PARAM)

										local function func( ... )
											playEffectSound("sound/system/click.mp3")
											if player:getMoney() < CONF.PARAM.get("queue_buy_num").PARAM*num then
												-- tips:tips(CONF:getStringValue("no enought credit"))

												local function func()
													local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

													rechargeNode:init(self, {index = 1})
													self:addChild(rechargeNode)
												end

												local messageBox = require("util.MessageBox"):getInstance()
												messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
												return
											end

											local strData = Tools.encode("BuildQueueAddReq", {
												num = num,
											})
											GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_ADD_REQ"),strData)

											gl:retainLoading()

											-- node:removeFromParent()
										end

										local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("open_queue").." "..formatTime2(CONF.PARAM.get("queue_buy_time").PARAM*3600*num), CONF.PARAM.get("queue_buy_num").PARAM*num, func)

										self:addChild(node)
										tipsAction(node)
									end
								else
									nh = false

									local strData = Tools.encode("UpgradeResLandReq", {
										land_index = index,
										resource_type = landType.resource_type,
									})
									GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPGRADE_RESOURCE_REQ"),strData)

									gl:retainLoading() 
								end

								if nh then
									if player:getMoneyBuildingQueueOpen() then
										if player:getMoneyBuildingQueueNow() then
											tips:tips(CONF:getStringValue("has build upgrade now"))
										else
											local conf = CONF.RESOURCE.get(player:getLandType(index).resource_type)
											local info = player:getBuildingQueueBuild(2)

											local time = info.duration_time - (player:getServerTime() - info.open_time)

											if time < conf.CD then
												local p_time = (conf.CD - time)/3600

												local num = math.ceil(p_time/CONF.PARAM.get("queue_buy_time").PARAM)

												local function func( ... )
													if player:getMoney() < CONF.PARAM.get("queue_buy_num").PARAM*num then
														-- tips:tips(CONF:getStringValue("no enought credit"))

														local function func()
															local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

															rechargeNode:init(self, {index = 1})
															self:addChild(rechargeNode)
														end

														local messageBox = require("util.MessageBox"):getInstance()
														messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
														return
													end

													local strData = Tools.encode("BuildQueueAddReq", {
														num = num,
													})
													GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_ADD_REQ"),strData)

													gl:retainLoading()

													-- node:removeFromParent()
												end

												local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("open_queue").." "..formatTime2(CONF.PARAM.get("queue_buy_time").PARAM*3600*num), CONF.PARAM.get("queue_buy_num").PARAM*num, func)

												self:addChild(node)
												tipsAction(node)
											else
												local strData = Tools.encode("UpgradeResLandReq", {
													land_index = index,
													resource_type = landType.resource_type,
												})
												GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPGRADE_RESOURCE_REQ"),strData)

												gl:retainLoading() 
											end
										end
									end

								end
								
							else
								local jumpTab = {}
								for k,v in ipairs(conf.ITEM_ID) do
									if player:getItemNumByID(v) < conf.ITEM_NUM[k] then
										local cfg_item = CONF.ITEM.get(v)
										if cfg_item and cfg_item.JUMP then
											table.insert(jumpTab,cfg_item.JUMP)
										end
									end
								end
								if Tools.isEmpty(jumpTab) == false and not self:getChildByName("JumpChoseLayer") then
									jumpTab.scene = "HomeScene"
									local center = cc.exports.VisibleRect:center()
									local layer = self:getApp():createView("ShipsScene/JumpChoseLayer",jumpTab)
									layer:setName("JumpChoseLayer")
									tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
									self:addChild(layer)
								end
								tips:tips(CONF:getStringValue("Material_not_enought"))
							end                            

						end)
	
						
					end)
	
					self.landNode_:getChildByName("dismantle"):addClickEventListener(function ( ... )
						playEffectSound("sound/system/click.mp3")
						if self.infoNode_ then
							self.infoNode_:removeFromParent()
							self.infoNode_ = nil
						end

						self.landNode_:removeFromParent()
						self.landNode_ = nil
	
						self.landNode_ = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeDismantle.csb")
	
						self.landNode_:getChildByName("time_num"):setString(formatTime(0))
						self.landNode_:getChildByName("cancel"):getChildByName("text"):setString(CONF:getStringValue("cancel"))
						self.landNode_:getChildByName("dismantle"):getChildByName("text"):setString(CONF:getStringValue("dismantle"))
						self.landNode_:getChildByName("warning"):setString(CONF:getStringValue("home dismanle info"))

						self.landNode_:getChildByName("cancel"):addClickEventListener(function ( ... )
							playEffectSound("sound/system/click.mp3")
							self.landNode_:removeFromParent()
							self.landNode_ = nil
						end)
	
						self.landNode_:getChildByName("dismantle"):addClickEventListener(function ( ... )
							playEffectSound("sound/system/click.mp3")
							local strData = Tools.encode("RemoveResLandReq", {
								land_index = index,
						
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_REMOVE_RESOURCE_REQ"),strData)

							gl:retainLoading()
	
						end)
		
						-- self.landNode_:setPosition(cc.p(self.chooseNode:getPosition()))
						-- if self.landNode_:getPositionX() + self.landNode_:getChildByName("Panel"):getContentSize().width/2 > rn:getContentSize().width then
						-- 	self.landNode_:setPositionX(rn:getContentSize().width - self.landNode_:getChildByName("Panel"):getContentSize().width/2 + (rn:getContentSize().width - winSize.width)/2)
						-- end
						-- self.landNode_:setPosition(cc.p(rn:getChildByName(string.format("midpos")):getPosition()))
--						self.landNode_:setPosition(cc.exports.VisibleRect:center())
						rn:addChild(self.landNode_,landZOrder)
                        self.landNode_:setPosition(rn:getChildByName("midpos"):getPosition())
	
					end)
				end
	
			elseif status == 1 then
	
				self.landNode_ = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeBuilding.csb")
				self.landNode_:getChildByName("finish"):getChildByName("text"):setString(CONF:getStringValue("expedite"))
				self.landNode_:getChildByName("info"):getChildByName("text"):setString(CONF:getStringValue("information"))
				self.landNode_:getChildByName("cancel"):getChildByName("text"):setString(CONF:getStringValue("cancel"))

				self.landNode_:getChildByName("mid"):addClickEventListener(function ( ... )
					playEffectSound("sound/system/click.mp3")
					if self.infoNode_ then
						self.infoNode_:removeFromParent()
						self.infoNode_ = nil
					end

					self.landNode_:removeFromParent()
					self.landNode_ = nil
				end)

				self.landNode_:getChildByName("info"):addClickEventListener(function ( ... )
					playEffectSound("sound/system/click.mp3")
					local add = 1+(CONF.VIP.get(player:getVipLevel()).EXTRA_HOME_RESOURCE/100)
					if self.infoNode_ then
						self.infoNode_:removeFromParent()
						self.infoNode_ = nil
					else

						self.infoNode_ = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeBuildingInfo.csb")
						self.infoNode_:getChildByName("Lv"):setString(CONF:getStringValue("level"))
						self.infoNode_:getChildByName("Text_10_1"):setString(CONF:getStringValue("Storage"))
						self.infoNode_:getChildByName("Text_10"):setString(CONF:getStringValue("Yields") .. CONF:getStringValue("hours"))
	
						local buildType = math.floor(landType.resource_type/1000)
						if buildType == 1 then
							self.infoNode_:getChildByName("build_name"):setString(CONF:getStringValue("HomeBuildingName_"..buildType))
						elseif buildType == 2 then
							self.infoNode_:getChildByName("build_name"):setString(CONF:getStringValue("HomeBuildingName_"..buildType))
						elseif buildType == 3 then
							self.infoNode_:getChildByName("build_name"):setString(CONF:getStringValue("HomeBuildingName_"..buildType))
						end
	
						self.infoNode_:getChildByName("build_icon"):setTexture("HomeIcon/"..buildType.."001.png")
	
						self.infoNode_:getChildByName("old_level"):setString(landType.resource_level)
						self.infoNode_:getChildByName("new_level"):setString(landType.resource_level+1)
						self.infoNode_:getChildByName("yield"):setString(CONF.RESOURCE.get(landType.resource_type).PRODUCTION_NUM*add)
						self.infoNode_:getChildByName("yield_upnum"):setString(CONF.RESOURCE.get(landType.resource_type+1).PRODUCTION_NUM*add-CONF.RESOURCE.get(landType.resource_type).PRODUCTION_NUM*add)
						self.infoNode_:getChildByName("storage"):setString(CONF.RESOURCE.get(landType.resource_type).STORAGE)
						self.infoNode_:getChildByName("storage_upnum"):setString(CONF.RESOURCE.get(landType.resource_type+1).STORAGE-CONF.RESOURCE.get(landType.resource_type).STORAGE)

						self.infoNode_:getChildByName("help"):getChildByName("text"):setString(CONF:getStringValue("ask_help"))

						print("CONF.EGroupHelpType.kHome", CONF.EGroupHelpType.kHome)
						if player:isGroup() then
							if player:getGroupHelp(CONF.EGroupHelpType.kHome, landType.land_index) == nil then
								self.infoNode_:getChildByName("help"):setVisible(true)
								self.infoNode_:getChildByName("help"):addClickEventListener(function ( ... )
									playEffectSound("sound/system/click.mp3")
									local strData = Tools.encode("GroupRequestHelpReq", {
										type = CONF.EGroupHelpType.kHome,
										id = {landType.land_index, landType.resource_type},
									})
									GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_REQUEST_HELP_REQ"),strData)

									gl:retainLoading()
								end)
							end
						end
				
						self.infoNode_:setPosition(cc.p((winSize.width + (rn:getContentSize().width - winSize.width))/2, (winSize.height + (rn:getContentSize().height - winSize.height))/2))
						-- self.landNode_:setPosition(cc.exports.VisibleRect:center())
						rn:addChild(self.infoNode_,infoZOrder)
					end     
	
				end)
				self.landNode_:getChildByName("cancel"):addClickEventListener(function ( ... )
					playEffectSound("sound/system/click.mp3")
					if self.infoNode_ then
						self.infoNode_:removeFromParent()
						self.infoNode_ = nil
					end
	
					self.landNode_:removeFromParent()
					self.landNode_ = nil
	
					self.landNode_ = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeWarning.csb")

					self.landNode_:getChildByName("cancel"):getChildByName("text"):setString(CONF:getStringValue("cancel"))
					self.landNode_:getChildByName("queding"):getChildByName("text"):setString(CONF:getStringValue("yes"))
					self.landNode_:getChildByName("warning"):setString(CONF:getStringValue("cancel upgrade"))
	
					self.landNode_:getChildByName("cancel"):addClickEventListener(function ( ... )
						playEffectSound("sound/system/click.mp3")
						self.landNode_:removeFromParent()
						self.landNode_ = nil
					end)
	
					self.landNode_:getChildByName("queding"):addClickEventListener(function ( ... )
						-- self.landNode_:removeFromParent()
						-- self.landNode_ = nil
						playEffectSound("sound/system/click.mp3")
						local strData = Tools.encode("CancelResBuildingReq", {
							land_index = index,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CANCEL_BUILD_REQ"),strData)

						gl:retainLoading()
					end)

					-- self.landNode_:setPosition(cc.p(self.chooseNode:getPosition()))
					-- if self.landNode_:getPositionX() + self.landNode_:getChildByName("Panel"):getContentSize().width/2 > rn:getContentSize().width then
					-- 	self.landNode_:setPositionX(rn:getContentSize().width - self.landNode_:getChildByName("Panel"):getContentSize().width/2 + (rn:getContentSize().width - winSize.width)/2)
					-- end
					self.landNode_:setPosition(cc.exports.VisibleRect:center())
					rn:addChild(self.landNode_,landZOrder)
                    self.landNode_:setPosition(cc.p(rn:getChildByName(string.format("midpos")):getPosition()))
					
				end)
				self.landNode_:getChildByName("finish"):addClickEventListener(function ( ... )
					playEffectSound("sound/system/click.mp3")
					if player:getMoney() < tonumber(self.landNode_:getChildByName("finish"):getChildByName("credcit_num"):getString()) then
						-- tips:tips(CONF:getStringValue("no enought credit"))
						local function func()
							local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

							rechargeNode:init(self, {index = 1})
							self:addChild(rechargeNode)
						end

						local messageBox = require("util.MessageBox"):getInstance()
						messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
						return 
					end

					if self.infoNode_ then
						self.infoNode_:removeFromParent()
						self.infoNode_ = nil
					end

					self.landNode_:removeFromParent()
					self.landNode_ = nil

					local strData = Tools.encode("SpeedUpBuildReq", {
						land_index = index,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SPEED_UP_BUILD_REQ"),strData)

					gl:retainLoading()
					
				end)

				self.time_num = CONF.RESOURCE.get(player:getLandType(index).resource_type).CD - (player:getServerTime() - player:getLandType(index).res_refresh_times)

				self.landNode_:getChildByName("finish"):getChildByName("credcit_num"):setString(player:getSpeedUpNeedMoney(self.time_num))
		
				self.landNode_:setPosition(cc.p(self.chooseNode:getPosition()))
				-- self.landNode_:setPosition(cc.exports.VisibleRect:center())
				-- self.landNode_:setPosition(cc.p(rn:getChildByName(string.format("midpos")):getPosition()))
				rn:addChild(self.landNode_,landZOrder)
	
			end
	
		end
	end
end

function HomeScene:updateUI()

	local rn = self:getResourceNode()

	--setinfo
	local add = 1+(CONF.VIP.get(player:getVipLevel()).EXTRA_HOME_RESOURCE/100)

	local build_info = player:getBuildingInfo(CONF.EBuilding.kMain)
	add = add + CONF.BUILDING_1.get(build_info.level).HOME_PRODUCTION


	local panel = rn:getChildByName("Panel_1")
	panel:setSwallowTouches(false)

	local info = {{num = 0, pro = 0},{num = 0, pro = 0},{num = 0, pro = 0}}

	for i,v in ipairs(self.landInfo) do
		local conf = CONF.RESOURCE.get(v.resource_type)
		if conf.TYPE == 1 then
			info[1].num = info[1].num + 1

			info[1].pro = info[1].pro + conf.PRODUCTION_NUM*add + Tools.getValueByTechnologyAddition(CONF.RESOURCE.get(v.resource_type).PRODUCTION_NUM*add, CONF.ETechTarget_1.kHomeRes, conf.TYPE, CONF.ETechTarget_3_Res.kProduction, player:getTechnolgList(), player:getPlayerGroupTech())
		elseif conf.TYPE == 2 then
			info[2].num = info[2].num + 1
			info[2].pro = info[2].pro + conf.PRODUCTION_NUM*add + Tools.getValueByTechnologyAddition(CONF.RESOURCE.get(v.resource_type).PRODUCTION_NUM*add, CONF.ETechTarget_1.kHomeRes, conf.TYPE, CONF.ETechTarget_3_Res.kProduction, player:getTechnolgList(), player:getPlayerGroupTech())
		elseif conf.TYPE == 3 then
			info[3].num = info[3].num + 1
			info[3].pro = info[3].pro + conf.PRODUCTION_NUM*add + Tools.getValueByTechnologyAddition(CONF.RESOURCE.get(v.resource_type).PRODUCTION_NUM*add, CONF.ETechTarget_1.kHomeRes, conf.TYPE, CONF.ETechTarget_3_Res.kProduction, player:getTechnolgList(), player:getPlayerGroupTech())
		end
	end

	panel:getChildByName("alloy_num"):setString(info[1].num)
	panel:getChildByName("alloy_production_num"):setString(math.floor(info[1].pro))
	panel:getChildByName("alloy_production_hour"):setPositionX(panel:getChildByName("alloy_production_num"):getPositionX() + panel:getChildByName("alloy_production_num"):getContentSize().width + 2)

	panel:getChildByName("crystal_num"):setString(info[2].num)
	panel:getChildByName("crystal_production_num"):setString(math.floor(info[2].pro))
	panel:getChildByName("crystal_production_hour"):setPositionX(panel:getChildByName("crystal_production_num"):getPositionX() + panel:getChildByName("crystal_production_num"):getContentSize().width + 2)

	panel:getChildByName("energy_num"):setString(info[3].num)
	panel:getChildByName("energy_production_num"):setString(math.floor(info[3].pro))
	panel:getChildByName("energy_production_hour"):setPositionX(panel:getChildByName("energy_production_num"):getPositionX() + panel:getChildByName("energy_production_num"):getContentSize().width + 2)


	local panel_3 = rn:getChildByName("Panel_3")
	panel_3:getChildByName("all_num_text1"):setString(info[1].num + info[2].num + info[3].num)
	panel_3:getChildByName("all_num_text2"):setString(CONF.BUILDING_1.get(player:getBuildingInfo(1).level).RESOURCE_NUM)

	--setbuild

	if self.landNode_ then
		self.landNode_:setLocalZOrder(100)
	end

	if self.infoNode_ then
		self.infoNode_:setLocalZOrder(99)
	end

	for k,v in pairs(self.landBuild) do
		v:removeFromParent()
	end

	self.landBuild = {}

	for k,v in pairs(self.buildingNodes) do
			v.buingingNode:removeFromParent()
	end

	self.buildingNodes = {}


	for i=1,CONF.BUILDING_1.get(player:getBuildingInfo(CONF.EBuilding.kMain).level).RESOURCE_NUM do
		
		local v = player:getLandType(i)
		if v ~= nil then
			rn:getChildByName("newNode_"..i):setVisible(true)

			if v.resource_type ~= 0 then

				local buildType = math.floor(v.resource_type/1000)
		
				local buildArea = 1
				if v.land_index >=1 and v.land_index <= 4 then
					buildArea = 1
				elseif v.land_index >=5 and v.land_index <= 8 then
					buildArea = 2
				elseif v.land_index >=9 and v.land_index <= 12 then
					buildArea = 3
				end
				local build = cc.Sprite:create(string.format("HomeIcon/%d001_%d.png", buildType, buildArea))
				-- local build = cc.Sprite:create(string.format("HomeIcon/%d001.png", buildType))
				build:setPosition(cc.p(rn:getChildByName(string.format("land_%d", v.land_index)):getPositionX(), rn:getChildByName(string.format("land_%d", v.land_index)):getPositionY()+10))
				rn:addChild(build)
				build:setTag(v.land_index)
	
				table.insert(self.landBuild, build)

				local ttfConfig = {}
				ttfConfig.fontFilePath = s_default_font
				ttfConfig.fontSize = 17

				local sprite

				if buildType == 1 then
					sprite = cc.Sprite:create("Common/newUI/y_lv.png")
				elseif buildType == 2 then
					sprite = cc.Sprite:create("Common/newUI/g_lv.png")
				elseif buildType == 3 then
					sprite = cc.Sprite:create("Common/newUI/b_lv.png")
				end

				rn:addChild(sprite)
				sprite:setPosition(cc.p(build:getPositionX()-5, build:getPositionY()-20))

				table.insert(self.landBuild, sprite)

				local label = cc.Label:createWithTTF(ttfConfig,v.resource_level,cc.VERTICAL_TEXT_ALIGNMENT_CENTER,400)

				rn:addChild(label)
				label:setPosition(cc.p(build:getPositionX()-6, build:getPositionY()-20))

				table.insert(self.landBuild, label)

				-- local label = cc.Label:createWithTTF(ttfConfig,"",cc.VERTICAL_TEXT_ALIGNMENT_CENTER,400)
				-- if buildType == 1 then
				-- 	label:setTextColor(cc.c4b(2, 170, 240, 255))
				-- 	label:enableShadow(cc.c4b(2, 170, 240, 255),cc.size(0.5,0.5))
				-- 	label:setString(string.format("%s lv.%d", CONF:getStringValue("HomeBuildingName_1"), v.resource_level))
				-- elseif buildType == 2 then
				-- 	label:setTextColor(cc.c4b(240, 147, 16, 255))
				-- 	label:enableShadow(cc.c4b(240, 147, 16, 255),cc.size(0.5,0.5))
				-- 	label:setString(string.format("%s lv.%d", CONF:getStringValue("HomeBuildingName_2"), v.resource_level))
				-- elseif buildType == 3 then
				-- 	label:setTextColor(cc.c4b(6, 217, 64, 255))
				-- 	label:enableShadow(cc.c4b(6, 217, 64, 255),cc.size(0.5,0.5))
				-- 	label:setString(string.format("%s lv.%d", CONF:getStringValue("HomeBuildingName_3"), v.resource_level))
				-- end

				-- rn:addChild(label)
				-- label:setPosition(cc.p(build:getPositionX(), build:getPositionY()-20))

				-- table.insert(self.landBuild, label)

				if v.resource_status == 2 then
		
					-- local resourceNum = math.floor((player:getServerTime() - v.res_refresh_times)/3600*CONF.RESOURCE.get(v.resource_type).PRODUCTION_NUM)
					-- printInfo("resourceNum  "..resourceNum)
					-- if resourceNum >= CONF.RESOURCE.get(v.resource_type).STORAGE then
					--     resourceNum = CONF.RESOURCE.get(v.resource_type).STORAGE
					-- end
					-- v.resource_num = resourceNum 
		
					if v.resource_num == CONF.RESOURCE.get(v.resource_type).STORAGE then
					
						local node = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeNode.csb")
						
						node:getChildByName("Panel_1"):getChildByName("icon"):setTexture("Common/ui/ui_icon_00"..buildType..".png")
						node:setPosition(cc.p(rn:getChildByName(string.format("land_%d", v.land_index)):getPositionX(), rn:getChildByName(string.format("land_%d", v.land_index)):getPositionY()+30))

						node:getChildByName("Panel_1"):setTag(v.land_index)
						node:getChildByName("Panel_1"):addClickEventListener(function ( sender )
							playEffectSound("sound/system/click.mp3")
							self:clickLand(node:getChildByName("Panel_1"):getTag())
						end)

						rn:addChild(node,2)
												  
						table.insert(self.buildingNodes, {index = v.land_index, buingingNode = node})
					elseif v.resource_num >= CONF.RESOURCE.get(v.resource_type).STORAGE*0.6 then

						local node = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeNode.csb")
						node:getChildByName("Panel_1"):getChildByName("icon"):setTexture("Common/ui/ui_icon_00"..buildType..".png")
						
						node:setPosition(cc.p(rn:getChildByName(string.format("land_%d", v.land_index)):getPositionX(), rn:getChildByName(string.format("land_%d", v.land_index)):getPositionY()+30))

						node:getChildByName("Panel_1"):setTag(v.land_index)
						node:getChildByName("Panel_1"):addClickEventListener(function ( sender )
							playEffectSound("sound/system/click.mp3")
							self:clickLand(node:getChildByName("Panel_1"):getTag())
						end)

						rn:addChild(node,2)
		
						table.insert(self.buildingNodes, {index = v.land_index, buingingNode = node})
					else
		
					end
		
				elseif v.resource_status == 1 then
		
					if CONF.RESOURCE.get(v.resource_type).CD - (player:getServerTime() - v.res_refresh_times) <= 0 then

						if self.landNode_ then
							self.landNode_:removeFromParent()
							self.landNode_ = nil
						end

						if self.infoNode_ then
							self.infoNode_:removeFromParent()
							self.infoNode_ = nil
						end

						-- self.chooseNode:setVisible(false)
		
						local strData = Tools.encode("GetHomeSatusReq", {
							home_type = 1,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)
		
					else
		
						local buingingNode = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/HomeBuildingNode.csb")
						buingingNode:getChildByName("times"):setString(formatTime(CONF.RESOURCE.get(v.resource_type).CD - (player:getServerTime() - v.res_refresh_times)))
		
						self.time_num = CONF.RESOURCE.get(v.resource_type).CD - (player:getServerTime() - v.res_refresh_times)

						buingingNode:setPosition(cc.p(rn:getChildByName(string.format("land_%d", v.land_index)):getPositionX(), rn:getChildByName(string.format("land_%d", v.land_index)):getPositionY()+timeUpPos))

						buingingNode:getChildByName("Panel"):addClickEventListener(function ( sender )
							playEffectSound("sound/system/click.mp3")
							self:clickLand(v.land_index)
						end)

						rn:addChild(buingingNode, 3)
		
						-- local table = {index = v.land_index, buingingNode = buingingNode}
						table.insert(self.buildingNodes, {index = v.land_index, buingingNode = buingingNode})
		
					end
		
				end

			end
		else
			-- local newNode = require("app.ExResInterface"):getInstance():FastLoad("HomeScene/NEWjianzhu.csb")
			-- newNode:setPosition(cc.p(rn:getChildByName("land_"..i):getPositionX(), rn:getChildByName("land_"..i):getPositionY()))
			-- rn:addChild(newNode)

			-- animManager:runAnimByCSB(newNode, "HomeScene/NEWjianzhu.csb",  "1")

			-- table.insert(self.landBuild, newNode)

			rn:getChildByName("newNode_"..i):setVisible(true)

		end
	end
	
end

function HomeScene:onExitTransitionStart()
	printInfo("HomeScene:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry) 
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.broadcastListener_)

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return HomeScene