local BuildTotalLayer = class("BuildTotalLayer" , cc.load("mvc").ViewBase)

BuildTotalLayer.RESOURCE_FILENAME = "CityScene/BuildTotalLayer.csb"

BuildTotalLayer.NEED_ADJUST_POSITION = true

BuildTotalLayer.RESOURCE_BINDING = {

}

local player = require("app.Player"):getInstance();

local animManager = require("app.AnimManager"):getInstance();

local app = require("app.MyApp"):getInstance();

local gl = require("util.GlobalLoading"):getInstance();

local Bit = require "Bit"

function BuildTotalLayer:onCreate( data)

	self:getResourceNode():setName("BuildTotalLayer");
	self.data_ = data;

	self.canClose = false
	local bg = self:getResourceNode():getChildByName("bg");
	bg:addClickEventListener(function ()
		self:onClickBg();
	end)

	local touch = self:getResourceNode():getChildByName("touch"):addClickEventListener(function ()
		self:onClickBg();
	end)

	animManager:runAnimOnceByCSB(bg, "CityScene/BuildTotalLayer.csb", "animation0");

	local close = self:getResourceNode():getChildByName("bg"):getChildByName("close");
	close:addClickEventListener(function ()
		self:onClickBg();
	end);

	self.list = self:getResourceNode():getChildByName("bg"):getChildByName("list");
	self.list:setScrollBarEnabled(false);
	self.listInfo = {};
	self.progressList = {}; --进度倒计时列表

	self.updateList ={};  --计时器列表
	self.recvlistenerList = {};  -- 回调接口列表
end

function BuildTotalLayer:onClickBg(sender , event)
	if self.canClose then
		self:removeFromParent();
	end
end

function BuildTotalLayer:onEnterTransitionFinish()
	self.canClose = true

	self:refreshAllQueue()

	self:eventListenerStart()
end

function BuildTotalLayer:eventListenerStart()
	if self.recvlistenerList[2] == nil then
		self.recvlistenerList[2] = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, function ()
			self:recv_OpenMoneyQueue()
		end)
		cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(self.recvlistenerList[2], FixedPriority.kNormal)
	end

	if self.recvlistenerList[4] == nil then
		self.recvlistenerList[4] = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, function ()
			self:recv_Blueprint();
		end)
		cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(self.recvlistenerList[4], FixedPriority.kNormal)
	end

	if self.recvlistenerList[5] == nil then
		self.recvlistenerList[5] = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, function ()
			self:recv_CreateEquip();
		end)
		cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(self.recvlistenerList[5], FixedPriority.kNormal)
	end

end

function BuildTotalLayer:refreshAllQueue()
	self.list:removeAllChildren()
	self:onExitTransitionStart()
	self:eventListenerStart()
	self.listInfo = {};

	self:addNodeByType("BuildQueue")
	self:addNodeByType("TechnologyQueue")
	self:addNodeByType("BlueprintQueue")
	self:addNodeByType("SmithingQueue")
	self:addNodeByType("RepairQueue")


	local function sort(a,b)
		if a.tag < b.tag then
			return true;
		else
			return false;
		end
	end
	table.sort(self.listInfo, sort);

	self:refreshQueueNodePos();


	-- WJJ 20180724
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Zonglan(self)
end

function BuildTotalLayer:addNodeByType(type)
	local queueNode = self:createBuildTypeNode(type);

	if queueNode == nil then
		print(type .. " have not open");
		return;
	end

	local node = {};
	queueNode:setName(type);
	self.list:addChild(queueNode);
	node.queueNode = queueNode;

	if type == "BuildQueue" then
		node.tag = 1
	elseif type == "TechnologyQueue" then
		node.tag = 2
	elseif type == "BlueprintQueue" then
		node.tag = 3
	elseif type == "SmithingQueue" then 
		node.tag = 4
	elseif type == "RepairQueue" then
		node.tag = 5
	end

	table.insert(self.listInfo, node);
end

function BuildTotalLayer:refreshQueueNodePos()

	local contentHight = 0;
	for i=1,#self.listInfo do
		contentHight = contentHight+ self.listInfo[i].queueNode:getChildByName("bg"):getContentSize().height;
	end

	if #self.listInfo > 4 then
		self.list:setInnerContainerSize({width = 360, height = contentHight + #self.listInfo * 8})
	end
	--local contentHight = self.list:getInnerContainerSize().height;
	local totalHeight = self.list:getInnerContainerSize().height -10
	for i=1,#self.listInfo do
		local height = self.listInfo[i].queueNode:getChildByName("bg"):getContentSize().height;
		self.listInfo[i].queueNode:setPosition(0, totalHeight + (i-1)*(-8))

		totalHeight = totalHeight - height;
	end
end

-- type:队列的类型
function BuildTotalLayer:createBuildTypeNode(type) 
	local node = require("app.ExResInterface"):getInstance():FastLoad("CityScene/buildProcess.csb")
	node:setName(type.."Node");

	local root = nil;

	if type == "BuildQueue" then
		root = {};
		local root1 = require("app.ExResInterface"):getInstance():FastLoad("CityScene/buildNodeInfo.csb")
		local root2 = require("app.ExResInterface"):getInstance():FastLoad("CityScene/buildNodeInfo.csb")
		self:createBuildQueueNode(root1, 1); -- 免费
		self:createBuildQueueNode(root2, 2); -- 付费
		
		root[1] = root1;
		root[2] = root2;
		node:getChildByName("bg"):getChildByName("Image_3"):getChildByName("typeName"):setString(CONF:getStringValue(type));
	elseif type == "TechnologyQueue" then
		local param1, param2, param3 = isBuildingOpen(5, false);
		if param3 and param2 and param1 then  --判断是否开放科技队列
			root = require("app.ExResInterface"):getInstance():FastLoad("CityScene/buildNodeInfo.csb")
			self:createTechnologyNode(root)
		end
		node:getChildByName("bg"):getChildByName("Image_3"):getChildByName("typeName"):setString(CONF:getStringValue(type));
	elseif type == "BlueprintQueue" then
		local param1, param2, param3 = isBuildingOpen(3 ,false);
		if param3 and param2 and param1 then
			root = require("app.ExResInterface"):getInstance():FastLoad("CityScene/buildNodeInfo.csb")
			self:createBluprintNode(root)
			node:getChildByName("bg"):getChildByName("Image_3"):getChildByName("typeName"):setString(CONF:getStringValue(type));
		end
	elseif type == "SmithingQueue" then 
		local param1, param2, param3 = isBuildingOpen(16, false);
		if param3 and param2 and param1 then
			root = require("app.ExResInterface"):getInstance():FastLoad("CityScene/buildNodeInfo.csb")
			self:createSmithingNode(root)
			node:getChildByName("bg"):getChildByName("Image_3"):getChildByName("typeName"):setString(CONF:getStringValue(type));
		end
	elseif type == "RepairQueue" then 
		local param1, param2, param3 = isBuildingOpen(7, false);
		if param3 and param2 and param1 then
			root = require("app.ExResInterface"):getInstance():FastLoad("CityScene/buildNodeInfo.csb")	
			self:createRepairNode(root)
			node:getChildByName("bg"):getChildByName("Image_3"):getChildByName("typeName"):setString(CONF:getStringValue(type));
		end
	end

	if type == "BuildQueue" then
		node:getChildByName("bg"):setContentSize(371, 147)
		node:getChildByName("bg"):getChildByName("Image_3"):setPosition(123, 127);
		for i=1,#root do
			node:getChildByName("bg"):addChild(root[i]);
			root[i]:setPosition(0, 107-(50*(i-1)))
		end
	else
		if root ~= nil then 
			node:getChildByName("bg"):addChild(root);
			root:setPosition(0, 59)
		else
			return nil; -- 此类型队列尚未开放
		end
	end
	return node;
end

function BuildTotalLayer:showImage(rootWidget, isShow)
	rootWidget:getChildByName("processBg"):setVisible(isShow);
	rootWidget:getChildByName("buildName"):setVisible(isShow);

	if isShow then
		rootWidget:getChildByName("buildIcon"):loadTexture("CityScene/ui3/jianzhushengji.png");
	else
		rootWidget:getChildByName("buildIcon"):loadTexture("CityScene/ui3/jianzhushengji.png");
	end
	rootWidget:getChildByName("noBuilding"):setVisible(not isShow);
end

local function GetBuildFree(cd)
	return cd <= CONF.VIP.get(player:getVipLevel()).BUILDING_FREE
end
--rootWidget:队列节点  index:用于区分建筑队列（normal/money）  
function BuildTotalLayer:createBuildQueueNode(rootWidget, index)
	local isOpen = true
	if index == 2 then 
		isOpen = player:getMoneyBuildingQueueOpen();
	end
	self:showImage(rootWidget, isOpen);

	if not isOpen then  --付费队列未开放
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);

		rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(true)
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(true);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString(CONF.PARAM.get("queue_buy_num").PARAM)
		rootWidget:getChildByName("noBuilding"):setVisible(true);
		rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("BuildQueue_des 2"));
		rootWidget:getChildByName("beginBtn"):addClickEventListener(function ()
			self:onClickBuildQueueBtn("NotOpen");
		end)
		return;
	end

	local isWorking = player:getBuildQueueNow(index)
	if not isWorking then --没事干
		self:showImage(rootWidget, isWorking);
		rootWidget:getChildByName("noBuilding"):setVisible(true);
		rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("BuildQueue_des"))
		rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true)
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
		rootWidget:getChildByName("beginBtn"):addClickEventListener(function ()
			self:onClickBuildQueueBtn("NotWorking",nil, index);
		end)

		if index == 2 then 
			local leftTime = player:getBuildingQueueBuild(2).duration_time - (player:getServerTime() - player:getBuildingQueueBuild(2).open_time)
			rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("leisure in").. formatTime(leftTime));
			self.updateList[index] = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function ()
				if leftTime <= 0 then
					cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.updateList[index]);
					self.updateList[index] = nil;
					return;
				end
				leftTime = leftTime -1;
				rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("leisure in").. formatTime(leftTime));
			end, 1 , false)
		end
		return;
	end
	rootWidget:getChildByName("noBuilding"):setVisible(false)
	rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);
	rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
	rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
	rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true)
	rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))

	local info = player:getBuildingQueueBuild(index);
	local localTime = 0;
	local totalCD = 0
	self.progressList[index] = require("util.ScaleProgressDelegate"):create(rootWidget:getChildByName("processBg"):getChildByName("process"), 201)
	if info.type == 1 then

		local building_info = player:getBuildingInfo(info.index)

		local conf = CONF[string.format("BUILDING_%d",info.index)].get(building_info.level)

		rootWidget:getChildByName("buildName"):setString(CONF:getStringValue("BuildingName_"..info.index) .. "Lv:"..building_info.level + 1);

		totalCD = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
		localTime =  totalCD - (player:getServerTime() - building_info.upgrade_begin_time)
		rootWidget:getChildByName("processBg"):getChildByName("time"):setString(formatTime(localTime))

		local percent = 1-localTime/totalCD
		if percent < 0 then percent = 0 end
		if percent > 1 then percent = 1 end
		self.progressList[index]:setPercentage(math.floor(percent * 100));

		if GetBuildFree(localTime) then
			--[[rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false)
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false)
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false)
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true)
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("free"))]]
			rootWidget:getChildByName("beginBtn"):setVisible(false)

			rootWidget:getChildByName("freebut"):setVisible(true)
			rootWidget:getChildByName("freebut"):getChildByName("txt_begin"):setString(CONF:getStringValue("free"))
		else
			local ishelp = false
			if player:isGroup() then
				if player:getGroupHelp(CONF.EGroupHelpType.kBuilding, info.index) == nil then
					ishelp = true
				end
			end
			if ishelp then
				--[[rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("ask_help"))]]
				rootWidget:getChildByName("beginBtn"):setVisible(false)
				rootWidget:getChildByName("helpbut"):setVisible(true)
				rootWidget:getChildByName("helpbut"):getChildByName("txt_begin"):setString(CONF:getStringValue("ask_help"))
			else
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(false);
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);

				rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(true)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(true);
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString(player:getSpeedUpNeedMoney(localTime))
			end
		end

		--rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString("未算");
		rootWidget:getChildByName("beginBtn"):addClickEventListener(function ()
			self:onClickBuildQueueBtn("InWorking", 1, index);
		end)
		rootWidget:getChildByName("freebut"):addClickEventListener(function ()
			self:onClickBuildQueueBtn("InWorking", 1, index);
		end)
		rootWidget:getChildByName("helpbut"):addClickEventListener(function ()
			self:onClickBuildQueueBtn("InWorking", 1, index);
		end)

	elseif info.type == 2 then
		local landInfo = player:getLandType(info.index)

		local conf = CONF.RESOURCE.get(landInfo.resource_type)

		totalCD = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kHomeBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
		localTime = totalCD - (player:getServerTime() - landInfo.res_refresh_times)

		rootWidget:getChildByName("buildName"):setString(CONF:getStringValue("HomeBuildingName_"..math.floor(landInfo.resource_type/1000)).."Lv:"..landInfo.resource_level + 1);
		if localTime <= 0 then
			local strData = Tools.encode("GetHomeSatusReq", {
				home_type = 1,	
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)
		else
			rootWidget:getChildByName("processBg"):getChildByName("time"):setString(formatTime(localTime))
		end
		local percent = 1-localTime/totalCD
		if percent < 0 then percent = 0 end
		if percent > 1 then percent = 1 end
		self.progressList[index]:setPercentage(math.floor(percent * 100));

		local ishelp = false
		if player:isGroup() then
			if player:getGroupHelp(CONF.EGroupHelpType.kHome, info.index) == nil then
				ishelp = true
			end
		end
		if ishelp then
			--[[
			rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false)
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false)
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false)
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true)
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("ask_help"))]]

			rootWidget:getChildByName("beginBtn"):setVisible(false)
			rootWidget:getChildByName("helpbut"):setVisible(true)
			rootWidget:getChildByName("helpbut"):getChildByName("txt_begin"):setString(CONF:getStringValue("ask_help"))
		else
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(false);
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
			rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(true)
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(true);
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString(player:getSpeedUpNeedMoney(localTime))
		end

		--rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString("未算");
		rootWidget:getChildByName("beginBtn"):addClickEventListener(function ()
			self:onClickBuildQueueBtn("InWorking", 2, index	);
		end)
		rootWidget:getChildByName("helpbut"):addClickEventListener(function ()
			self:onClickBuildQueueBtn("InWorking", 2, index	);
		end)
	end

	self.updateList[index] = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function ()
		print("loop building",index)
		local building_info
		if info.type == 1 then
			building_info = player:getBuildingInfo(info.index)
		end
		if localTime <= 0 or (building_info and building_info.upgrade_begin_time == 0) then
			cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.updateList[index])
			self.updateList[index] = nil;
			print("close updateBuildQueue");
			self:refreshAllQueue();
			return;
		end
 
		localTime = localTime - 1;
		rootWidget:getChildByName("processBg"):getChildByName("time"):setString(formatTime(localTime))
		local percent = 1- localTime/totalCD;
		if percent < 0 then percent = 0 end
		if percent > 1 then percent = 1 end
		self.progressList[index]:setPercentage(math.floor(percent * 100));

		local bShow = true
		if info.type == 1 then
			if GetBuildFree(localTime) then
				--[[rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("free"))]]
				rootWidget:getChildByName("beginBtn"):setVisible(false)

				rootWidget:getChildByName("freebut"):setVisible(true)
				rootWidget:getChildByName("freebut"):getChildByName("txt_begin"):setString(CONF:getStringValue("free"))
				bShow = false
			end
		end

		if bShow then
			local ishelp = false
			if player:isGroup() then
				if info.type == 1 then
					if player:getGroupHelp(CONF.EGroupHelpType.kBuilding, info.index) == nil then
						ishelp = true
					end
				else
					if player:getGroupHelp(CONF.EGroupHelpType.kHome, info.index) == nil then
						ishelp = true
					end
				end
			end
			if ishelp then
				--[[rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("ask_help"))]]
				rootWidget:getChildByName("beginBtn"):setVisible(false)
				rootWidget:getChildByName("helpbut"):setVisible(true)
				rootWidget:getChildByName("helpbut"):getChildByName("txt_begin"):setString(CONF:getStringValue("ask_help"))
			else
				rootWidget:getChildByName("helpbut"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):setVisible(true)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(false);
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
				rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(true)
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(true);
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString(player:getSpeedUpNeedMoney(localTime))
			end
		end

	end, 1, false);

end

function BuildTotalLayer:onClickBuildQueueBtn(state, buildType, index)
	playEffectSound("sound/system/click.mp3")

	if state == "NotOpen" then
		local function func( ... )
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

		local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("open_queue").." "..formatTime2(CONF.PARAM.get("queue_buy_time").PARAM*3600), CONF.PARAM.get("queue_buy_num").PARAM, func)

		self:addChild(node)
		tipsAction(node)

	else

		if state == "NotWorking" then
			goScene(2, 11);
		elseif state == "InWorking" then
			local info = player:getBuildingQueueBuild(index);
			local localTime = 0;
			local totalCD = 0

			if info.type == 2 then
				if player:isGroup() then
					if player:getGroupHelp(CONF.EGroupHelpType.kHome, info.index) == nil then
						local landInfo = player:getLandType(info.index)

						local strData = Tools.encode("GroupRequestHelpReq", {
							type = CONF.EGroupHelpType.kHome,
							id = {landInfo.land_index, landInfo.resource_type},
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_REQUEST_HELP_REQ"),strData)

						return
					end
				end

				--转家园
				app:pushView("HomeScene/HomeScene", {index = 1});
			elseif info.type == 1 then
				local building_info = player:getBuildingInfo(info.index)
				local conf = CONF[string.format("BUILDING_%d",info.index)].get(building_info.level)

				totalCD = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
				localTime =  totalCD - (player:getServerTime() - building_info.upgrade_begin_time)
				print("BuildingUpgradeSpeedUpReq",index,localTime)

				if GetBuildFree(localTime) then
					local strData = Tools.encode("BuildingUpgradeSpeedUpReq", {
						index = info.index,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPGRADE_SPEED_UP_REQ"),strData)

					gl:retainLoading()
					return
				else
					if player:isGroup() then
						if player:getGroupHelp(CONF.EGroupHelpType.kBuilding, info.index) == nil then
							local strData = Tools.encode("GroupRequestHelpReq", {
								type = CONF.EGroupHelpType.kBuilding,
								id = {info.index},
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_REQUEST_HELP_REQ"),strData)
							return
						end
					end
				end

				app:pushView("BuildingUpgradeScene/BuildingUpgradeScene", {building_num = info.index})
				--goScene(2, minId);
			end
		end
		self:onClickBg();

	end
	
end

--科研队列
function BuildTotalLayer:createTechnologyNode(rootWidget)
	local isWorking = false;
	local haveCompleted = false;
	local techData = player:getTechnolgyData();

	local localTime = 0;
	local totalCD = 0;

	if techData.upgrade_busy == 0 then --没有研发
		isWorking = false;

		rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
		rootWidget:getChildByName("noBuilding"):setVisible(true);
		rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("TechnologyQueue_des"))
		self:showImage(rootWidget, isWorking);
	else

		local info = player:getTechnologyByID(techData.tech_id)
		assert(info, "error")
		local conf = CONF.TECHNOLOGY.get(techData.tech_id)

		localTime = info.begin_upgrade_time + conf.CD - player:getServerTime()

		if localTime <= 0 then  --已完成
			isWorking = false
			self:showImage(rootWidget, isWorking);
			rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true);
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
			rootWidget:getChildByName("processBg"):setVisible(false);
			rootWidget:getChildByName("noBuilding"):setVisible(true)
			rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("TechnologyQueue_des"))
		else
			isWorking = true;
			self:showImage(rootWidget, isWorking);

			if player:isGroup() and player:getGroupHelp(CONF.EGroupHelpType.kTechnology, techData.tech_id) == nil then
				rootWidget:getChildByName("beginBtn"):setVisible(false)
				rootWidget:getChildByName("helpbut"):setVisible(true)
				rootWidget:getChildByName("helpbut"):getChildByName("txt_begin"):setString(CONF:getStringValue("ask_help"))
			else
				rootWidget:getChildByName("beginBtn"):setVisible(true)
				rootWidget:getChildByName("helpbut"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true);
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
				rootWidget:getChildByName("buildName"):setString(CONF:getStringValue(conf.TECHNOLOGY_NAME).."Lv:" .. conf.TECHNOLOGY_LEVEL );--CONF:getStringValue
			end
		

			totalCD = conf.CD;
			local percent = 1- localTime/totalCD;
			if percent <= 0 then percent = 0 end
			if percent >= 1 then percent = 1 end

			rootWidget:getChildByName("processBg"):getChildByName("time"):setString(formatTime(localTime));

			self.progressList[3] = require("util.ScaleProgressDelegate"):create(rootWidget:getChildByName("processBg"):getChildByName("process"),201)
			self.progressList[3]:setPercentage(math.floor(percent * 100))

			self.updateList[3] = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function ()
				if localTime <= 0 then
					cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.updateList[3]);
					self.updateList[3] = nil;
					self:refreshAllQueue();
					return;
				end

				if player:isGroup() and player:getGroupHelp(CONF.EGroupHelpType.kTechnology, techData.tech_id) == nil then
					rootWidget:getChildByName("beginBtn"):setVisible(false)
					rootWidget:getChildByName("helpbut"):setVisible(true)
					rootWidget:getChildByName("helpbut"):getChildByName("txt_begin"):setString(CONF:getStringValue("ask_help"))
				else
					rootWidget:getChildByName("beginBtn"):setVisible(true)
					rootWidget:getChildByName("helpbut"):setVisible(false)
					rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);
					rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true);
					rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
					rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
					rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
					rootWidget:getChildByName("buildName"):setString(CONF:getStringValue(conf.TECHNOLOGY_NAME).."Lv:" .. conf.TECHNOLOGY_LEVEL );--CONF:getStringValue
				end

				localTime = localTime - 1;
				local percent = 1- localTime / totalCD;
				if percent <= 0 then percent = 0 end
				if percent > 1 then percent = 1 end
				rootWidget:getChildByName("processBg"):getChildByName("time"):setString(formatTime(localTime));
				self.progressList[3]:setPercentage(math.floor(percent * 100))
			end, 1, false);

		end
	end
	rootWidget:getChildByName("beginBtn"):addClickEventListener(function ()
		--app:pushView("TechnologyScene/TechnologyScene");
		--self:onClickBg();
		self:onClickTechnologyBtn(isWorking);
	end)
	rootWidget:getChildByName("helpbut"):addClickEventListener(function ()
		self:onClickTechnologyBtn(isWorking);
	end)
	
end

function BuildTotalLayer:onClickTechnologyBtn(state)
	local techData = player:getTechnolgyData()
	if state then
		if player:isGroup() and player:getGroupHelp(CONF.EGroupHelpType.kTechnology, techData.tech_id) == nil then
			local strData = Tools.encode("GroupRequestHelpReq", {
				type =  CONF.EGroupHelpType.kTechnology,
				id = {techData.tech_id},
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_REQUEST_HELP_REQ"), strData)

		else
			app:pushView("TechnologyScene/TechnologyScene");
			self:onClickBg();
		end
	else
		app:pushView("TechnologyScene/TechnologyScene");
		self:onClickBg();
	end
end

--图纸研发队列
function BuildTotalLayer:createBluprintNode(rootWidget)
	local blueprintData = self:getBlueprintList();
	local isWorking = false;
	local runningData = nil
	print("createBluprintNode blueprintData count",#blueprintData)
	for k, value in ipairs(blueprintData) do
		if value.isOpen == 1 and value.startTime ~= 0 then
			isWorking = true;
			runningData = value;
			break
		end
	end

	self:showImage(rootWidget ,isWorking)
	rootWidget:getChildByName("beginBtn"):addClickEventListener(function ()
		--app:pushView("BlueprintScene/BlueprintScene");
		--self:onClickBg();
		self:onClickBlueprintBtn(isWorking,runningData);
	end)
	rootWidget:getChildByName("freebut"):addClickEventListener(function ()
		self:onClickBlueprintBtn(isWorking,runningData);
	end)


	print("isWorking" , isWorking);
	if not isWorking then --没有图纸研发
		self:showImage(rootWidget, isWorking);
		rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("BlueprintQueue_des"));
		rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
		return;
	end

	local localTime = 0;
	local totalCD = 0;

	if runningData ~= nil then

		self:showImage(rootWidget, isWorking);

		totalCD = CONF.BLUEPRINT.get(runningData.id).TIME
		localTime =  totalCD + runningData.startTime - player:getServerTime()

		--[[rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);]]
		rootWidget:getChildByName("buildName"):setString(CONF:getStringValue("IN_"..runningData.id));

		rootWidget:getChildByName("noBuilding"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);

		rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(true)
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(true);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString(Tools.getSpeedShipNeedMoney(localTime))

		if localTime > 0 then
			self.progressList[4] = require("util.ScaleProgressDelegate"):create(rootWidget:getChildByName("processBg"):getChildByName("process"), 201);
			local percent = 1- localTime/totalCD;
			if percent <= 0 then percent = 0 end
			if percent >= 1 then percent = 1 end
			self.progressList[4]:setPercentage(math.floor(percent * 100));
			rootWidget:getChildByName("processBg"):getChildByName("time"):setString(formatTime(localTime));

			self.updateList[4] = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function ()
				if localTime <= 0 then 
					cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.updateList[4]);
					self.updateList[4] = nil;
					--self:refreshAllQueue();
					rootWidget:getChildByName("buildName"):setVisible(false)
					rootWidget:getChildByName("noBuilding"):setVisible(true)
					rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("IN_"..runningData.id)..CONF:getStringValue("accomplish"));

					rootWidget:getChildByName("beginBtn"):setVisible(false)
					rootWidget:getChildByName("freebut"):setVisible(true)
					rootWidget:getChildByName("freebut"):getChildByName("txt_begin"):setString(CONF:getStringValue("Get"))

					rootWidget:getChildByName("processBg"):setVisible(false);
					return;
				end
				localTime = localTime - 1;
				local percent = 1 - localTime / totalCD;
				if percent >= 1 then percent = 1 end
				if percent <= 0 then percent = 0 end
				self.progressList[4]:setPercentage(math.floor(percent*100));
				rootWidget:getChildByName("processBg"):getChildByName("time"):setString(formatTime(localTime));
				rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString(Tools.getSpeedShipNeedMoney(localTime))
			end, 1 ,false)
		else
			--self:showImage(rootWidget, not isWorking);
			rootWidget:getChildByName("buildName"):setVisible(false)
			rootWidget:getChildByName("noBuilding"):setVisible(true)
			rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("IN_"..runningData.id)..CONF:getStringValue("accomplish"));
			
			--[[rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true);
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
			rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);]]
			rootWidget:getChildByName("beginBtn"):setVisible(false)
			rootWidget:getChildByName("freebut"):setVisible(true)
			rootWidget:getChildByName("freebut"):getChildByName("txt_begin"):setString(CONF:getStringValue("Get"))

			rootWidget:getChildByName("processBg"):setVisible(false);
			
		end
	end

end

function BuildTotalLayer:getBlueprintList()
	local building3_level = player:getBuildingInfo(CONF.EBuilding.kShipDevelop).level
	local produce_list = player:getBlueprint_list()
	local blueprint_list = {}
	for k,v in ipairs(CONF.BUILDING_3) do
		if v.BLUEPRINT_LIST then
			for i,pieceID in ipairs(v.BLUEPRINT_LIST) do
				local conf = CONF.BLUEPRINT.get(pieceID)
				local list = {}
				list.isOpen = 0
				list.id = pieceID
				list.openLevel = k
				list.startTime = 0
				list.shipId = conf.AIRSHIP
				list.type = conf.TYPE
				if building3_level >= k then
					list.isOpen = 1
					for ii,blist in ipairs(produce_list) do
						if pieceID == blist.blueprint_id then
							list.startTime = blist.start_time
							break
						end
					end
					table.insert(blueprint_list,list)
				else
					table.insert(blueprint_list,list) 
				end
			end
		end
	end

	return blueprint_list;
end

function BuildTotalLayer:onClickBlueprintBtn(state,runningData)
	print("onClickBlueprintBtn",state)
	if not state  then
		app:pushView("BlueprintScene/BlueprintScene")
		self:onClickBg()
	else
		if runningData then
			local totalCD = CONF.BLUEPRINT.get(runningData.id).TIME
			local localTime =  totalCD + runningData.startTime - player:getServerTime()
			if localTime > 0 then
				app:pushView("BlueprintScene/BlueprintScene")
				self:onClickBg()
			else
				print("onClickBlueprintBtn id",state,runningData.id)
				local strData = Tools.encode("BlueprintDevelopeReq", {   
					type = 2,
					blueprint_id = runningData.id,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BLUEPRINT_DEVELOPE_REQ"),strData)
				gl:retainLoading()
			end		
		else
			app:pushView("BlueprintScene/BlueprintScene")
			self:onClickBg()
		end
	end
end

--锻造队列
function BuildTotalLayer:createSmithingNode(rootWidget)
	local isWorking = false;
	local state = "NotWorking";

	local localTime =0;
	local totalCD = 0;
	local forge_list = player:getForgeEquipList()
	local runningData = nil
	for i=1,4 do
		for k,v in ipairs(forge_list) do
			local cfg_equip = CONF.EQUIP.get(v.equip_id)
			if cfg_equip.TYPE == i then
				print("v.equip_id ", v.equip_id)
				runningData = cfg_equip;
				isWorking = true;
				state = "InWorking";
				totalCD = CONF.FORGEEQUIP.get(v.equip_id).EQUIP_TIME
				local need_time = totalCD - CONF.BUILDING_16.get(player:getBuildingInfo(CONF.EBuilding.kForge).level).EQUIP_FORGE_SPEED
				localTime = v.start_time + need_time - player:getServerTime()
				if localTime <= 0 then
					isWorking = false;
					state = "Completed";
				end
			end
		end
	end
	self:showImage(rootWidget, isWorking);

	if state == "InWorking" then
		rootWidget:getChildByName("noBuilding"):setVisible(false);
		--[[rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true)
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);]]
		--rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString("未算");
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);

		rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(true)
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(true);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString(player:getSpeedUpNeedMoney(localTime))

		rootWidget:getChildByName("buildName"):setString(CONF:getStringValue(runningData.NAME_ID).."Lv."..runningData.LEVEL);

		self.progressList[5] = require("util.ScaleProgressDelegate"):create(rootWidget:getChildByName("processBg"):getChildByName("process"), 201);
		local percent = 1- localTime / totalCD;
		if percent <= 0 then percent = 0 end
		if percent > 1 then percent = 1 end
		self.progressList[5]:setPercentage(math.floor(percent * 100));
		rootWidget:getChildByName("processBg"):getChildByName("time"):setString(formatTime(localTime));

		self.updateList[5] = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function ()
			if localTime <= 0 then
				cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.updateList[5]);
				self.updateList[5] = nil;
				--self:refreshAllQueue();
				rootWidget:getChildByName("buildName"):setVisible(false)
				rootWidget:getChildByName("beginBtn"):setVisible(false)
				rootWidget:getChildByName("freebut"):setVisible(true)
				rootWidget:getChildByName("freebut"):getChildByName("txt_begin"):setString(CONF:getStringValue("Get"))
                rootWidget:getChildByName("noBuilding"):ignoreContentAdaptWithSize(false)
                rootWidget:getChildByName("noBuilding"):setSize(220,60)
				rootWidget:getChildByName("noBuilding"):setVisible(true);
				rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue(runningData.NAME_ID).."Lv."..runningData.LEVEL..CONF:getStringValue("accomplish"));

				rootWidget:getChildByName("processBg"):setVisible(false);
				return;
			end

			localTime = localTime - 1;
			rootWidget:getChildByName("processBg"):getChildByName("time"):setString(formatTime(localTime));
			local percent = 1- localTime / totalCD;
			if percent < 0 then percent = 0 end
			if percent > 1 then percent = 1 end
			self.progressList[5]:setPercentage(math.floor(percent * 100));
			rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setString(player:getSpeedUpNeedMoney(localTime))
		end, 1, false);

	elseif state == "NotWorking" then
		rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
		rootWidget:getChildByName("noBuilding"):setVisible(true);
		rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("SmithingQueue_des"));
	elseif state == "Completed" then 
		--[[rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true);
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);]]

		rootWidget:getChildByName("beginBtn"):setVisible(false)
		rootWidget:getChildByName("freebut"):setVisible(true)
		rootWidget:getChildByName("freebut"):getChildByName("txt_begin"):setString(CONF:getStringValue("Get"))
        rootWidget:getChildByName("noBuilding"):ignoreContentAdaptWithSize(false)
        rootWidget:getChildByName("noBuilding"):setSize(220,60)
		rootWidget:getChildByName("noBuilding"):setVisible(true)
		rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue(runningData.NAME_ID).."Lv."..runningData.LEVEL..CONF:getStringValue("accomplish"));
	end

	rootWidget:getChildByName("beginBtn"):addClickEventListener(function ()
		--app:pushView("SmithingScene/SmithingScene");
		--self:onClickBg();
		self:onClickSmithingBtn(state);
	end)
	rootWidget:getChildByName("freebut"):addClickEventListener(function ()
		--app:pushView("SmithingScene/SmithingScene");
		--self:onClickBg();
		self:onClickSmithingBtn(state);
	end)

end

function BuildTotalLayer:onClickSmithingBtn(state)
	if state == "NotWorking" then
		app:pushView("SmithingScene/SmithingScene");
		self:onClickBg();
	else
		local localTime =0;
		local totalCD = 0;
		local forge_list = player:getForgeEquipList()
		local guid = 0
		for i=1,4 do
			for k,v in ipairs(forge_list) do
				local cfg_equip = CONF.EQUIP.get(v.equip_id)
				if cfg_equip.TYPE == i then
					print("v.equip_id ", v.equip_id)
					guid = v.guid
					totalCD = CONF.FORGEEQUIP.get(v.equip_id).EQUIP_TIME
					local need_time = totalCD - CONF.BUILDING_16.get(player:getBuildingInfo(CONF.EBuilding.kForge).level).EQUIP_FORGE_SPEED
					localTime = v.start_time + need_time - player:getServerTime()
				end
			end
		end
		if localTime <= 0 then
			local strData = Tools.encode("CreateEquipReq", {   
				type = 2,
				forge_guid = guid
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CREATE_EQUIP_REQ"),strData)

		else
			app:pushView("SmithingScene/SmithingScene");
			self:onClickBg();
		end
	end
end

--修理队列
function BuildTotalLayer:createRepairNode(rootWidget)
	local isBusy = false;  --只判断是否有需要

	local repair_ship_list = {}

	for i,v in ipairs(player:getShipList()) do

		if Bit:has(v.status, 4) then

		else
			if v.durable < Tools.getShipMaxDurable(v) then		
				if Bit:has(v.status, 2) == true then
					table.insert(repair_ship_list, v.guid)
				end	
			end
		end
	end

	isBusy = not( #repair_ship_list == 0 );

	self:showImage(rootWidget, false);
	rootWidget:getChildByName("beginBtn"):getChildByName("credit"):setVisible(false)
	rootWidget:getChildByName("beginBtn"):getChildByName("txt_over"):setVisible(false);
	rootWidget:getChildByName("beginBtn"):getChildByName("txt_speedUp"):setVisible(false);
	rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true);
	rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"))
	if isBusy then
		rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("RepairQueue_des"));
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setVisible(true)
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"));
	else
		rootWidget:getChildByName("noBuilding"):setString(CONF:getStringValue("RepairQueue_des 2"));
		rootWidget:getChildByName("beginBtn"):getChildByName("txt_begin"):setString(CONF:getStringValue("go"));
	end
	rootWidget:getChildByName("beginBtn"):addClickEventListener(function ()
		app:pushView("RepairScene/RepairScene");
		self:onClickBg();
	end)
end

function BuildTotalLayer:recv_CreateEquip()
	
	local cmd, strData = GameHandler.handler_c.recvProtobuf();

	if cmd == Tools.enum_id("CMD_DEFINE", "CMD_CREATE_EQUIP_RESP") then
		print("recv_CreateEquip");
		local proto = Tools.decode("CreateEquipResp", strData);
		print("ForgeEquipInfoLayer CreateEquipResp result  "..proto.result)
		if proto.result ~= 0 then
			return;
		end

		if proto.get_equip_guid and proto.get_equip_guid ~= 0  then
			local equip = player:getEquipByGUID( proto.get_equip_guid )
			if equip then
				local node = require("util.RewardNode"):createGettedNodeWithList({{id = equip.equip_id,num = 1}})
				tipsAction(node)
				node:setPosition(cc.exports.VisibleRect:center())
				self:getResourceNode():getParent():addChild(node)

				self:refreshAllQueue()
			end
		end
	end
end

function BuildTotalLayer:recv_OpenMoneyQueue()
	local cmd,strData = GameHandler.handler_c.recvProtobuf()
	if cmd == Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_ADD_RESP") then
		gl:releaseLoading()

		local proto = Tools.decode("BuildQueueAddResp",strData)
		if proto.result == 0 then
			self:refreshAllQueue();
		end
	elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_BUILDING_UPGRADE_SPEED_UP_RESP") then
		gl:releaseLoading()
		local proto = Tools.decode("BuildingUpgradeSpeedUpResp",strData)

		if proto.result ~= 0 then
			print("error :",proto.result)      
		else 
			if proto.user_sync.user_info.money == nil then
				player:setMoney(0)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("MoneyUpdated")
			end
			player:setBuildingInfo(proto.index, proto.info)

		end
	end
end

function BuildTotalLayer:recv_Blueprint()
	local cmd,strData = GameHandler.handler_c.recvProtobuf()
	if cmd == Tools.enum_id("CMD_DEFINE", "CMD_BLUEPRINT_DEVELOPE_RESP") then
		gl:releaseLoading()
		local proto = Tools.decode("BlueprintDevelopeResp",strData)
		if proto.result ~= 0 then

		else
			if Tools.isEmpty(proto.user_sync.user_info.blueprint_list) then 
				player:setBlueprint_list(nil)
			end
			if proto.type == 2 then
				local items = {}
				for i=1,proto.num do
					local t = {}
					t.id = proto.blueprint_id
					t.num = 1
					table.insert(items,t)
				end
				local node = require("util.RewardNode"):createGettedNodeWithList(items, func,nil,proto.crit)
				tipsAction(node)
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				self:refreshAllQueue()
			end
		end
	end
end

function BuildTotalLayer:onExitTransitionStart()
	print("onExitTransitionStart remove")
	for k,v in pairs(self.updateList) do
		if v~= nil then 
			cc.Director:getInstance():getScheduler():unscheduleScriptEntry(v)
			v= nil;
		end
	end

	for k,v in pairs(self.recvlistenerList) do
		if v ~= nil then
			cc.Director:getInstance():getEventDispatcher():removeEventListener(v);
			v =nil;
		end
	end
	self.recvlistenerList = {}
end

return BuildTotalLayer
