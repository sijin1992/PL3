local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()

local MainTaskNode = class("MainTaskNode",function()
	return require("app.ExResInterface"):getInstance():FastLoad("TaskScene/MainTask.csb")
end)


function MainTaskNode:ctor(scene)

	self.scene_ = scene

	local function onNodeEvent(event)
		if event == "enter" then
			self:init()
		elseif event == "exit" then
			self:destroy()
		end
	end

	self:registerScriptHandler(onNodeEvent)
end



function MainTaskNode:createTask( id, isMain, index )
   	-- print("#LUA MainTaskNode.lua 34 : id = " .. tostring(id) .. " isMain = " .. tostring(isMain) .. " / index = " .. tostring(index) )

	if id == nil then
		return
	end
	local node = require("app.ExResInterface"):getInstance():FastLoad("TaskScene/TaskNode.csb")
	local conf = CONF.TASK.get(id)
	print(conf.NAME,conf.MEMO,CONF.STRING[conf.NAME] ,CONF.STRING[conf.MEMO])
	local name_str = CONF.STRING.get(conf.NAME).VALUE
	local memo_str = CONF.STRING.get(conf.MEMO).VALUE
	if conf.SHOW and conf.SHOW == 1 then
		local value = conf.VALUES
		if value[1] then
			local vv = value[1]
			if conf.TARGET_1 == 2 and conf.TARGET_2 == 3 then
				vv = CONF:getStringValue("BuildingName_"..value[1])
			elseif conf.TARGET_1 == 3 and conf.TARGET_2 == 3 then
				vv = CONF:getStringValue("HomeBuildingName_"..value[1])
			elseif conf.TARGET_1 == 6 and conf.TARGET_2 == 3 then
				vv = CONF:getStringValue("ARENA_TITLE_"..value[1])
			elseif conf.TARGET_1 == 1 and conf.TARGET_2 == 1 then
				vv = CONF:getStringValue("Level_N"..value[1])
			end
			name_str = string.gsub(name_str,"#",vv)
			memo_str = string.gsub(memo_str,"#",vv)
		end
		if value[2] then
			name_str = string.gsub(name_str,"*",value[2])
			memo_str = string.gsub(memo_str,"*",value[2])
		end
		if value[3] then
			name_str = string.gsub(name_str,"&",value[3])
			memo_str = string.gsub(memo_str,"&",value[3])
		end
	end
	node:getChildByName("icon"):setTexture("TaskScene/ui/" .. conf.ICON .. ".png")
	--node:getChildByName("introduction"):setString(memo_str)
	node:getChildByName("taskName"):setString(name_str)
	--node:getChildByName("introduction"):setVisible(false);
	
	node:getChildByName("open"):setString(CONF.STRING.get("open").VALUE)
	--判断任务是否开放
	local isAchieved = false
	local completeNum 
	local needNum
	isAchieved , completeNum, needNum = player:IsTaskAchieved(conf)
	if completeNum == nil then 
		completeNum = 0
	end
	if needNum == nil then 
		completeNum = 1
	end

	local  isOpen = true
	if isMain == true and conf.OPEN_LEVEL > player:getLevel() then
		isOpen = false 
	end

   	-- print("#LUA MainTaskNode.lua 88 : isAchieved = " .. tostring(isAchieved) .. " isOpen = " .. tostring(isOpen) )
	if isAchieved == true and  isOpen == true then ----如果已经完成，则显示领取按钮

		animManager:runAnimOnceByCSB(node,"TaskScene/TaskNode.csb" ,"get")

		node:getChildByName("completeNum"):setString(tostring(completeNum))
		node:getChildByName("needNum"):setString(string.format("/%d",needNum))

		-- print("#LUA MainTaskNode.lua 95 : btnGet = " .. tostring(CONF:getStringValue("Get")) )

		node:getChildByName("btnGet"):getChildByName("btnText"):setString(CONF:getStringValue("Get"))
		node:getChildByName("btnGet"):addClickEventListener(function (sender)
			playEffectSound("sound/system/click.mp3")
            cc.exports.clickTaskReward = true
			-- if guideManager:getGuideType() then
			-- 	guideManager:addGuideStep(804)
				
			-- 	guideManager:createGuideLayer(804)
			-- end

			local function func( ... )
				local strData = Tools.encode("TaskRewardReq", {
					task_id = id,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_REWARD_REQ"),strData)
				gl:retainLoading()
			end

			if checkRewardBeMax(CONF.TASK.get(id).ITEM_ID, CONF.TASK.get(id).ITEM_NUM) then
				func()
			else
				local messageBox = require("util.MessageBox"):getInstance()

				messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
			end
		end)

		--showTaskNodeItem(id , node, true)
		
		-- ADD BY WJJ 20180608
		local timeNow = os.time()
		-- print("#LUA MainTaskNode.lua 130 : global_taskscene_ok_time = " .. tostring(timeNow) )
		-- cc.UserDefault:getInstance():setStringForKey("global_taskscene_ok_time", tostring(timeNow))
		-- cc.UserDefault:getInstance():flush()
		cc.exports.global_taskscene_ok_time = tostring(timeNow)

	elseif isOpen== true then --如果任务开放，则显示进度

		animManager:runAnimOnceByCSB(node,"TaskScene/TaskNode.csb" ,"open")

		node:getChildByName("completeNum"):setString(tostring(completeNum))
		node:getChildByName("needNum"):setString(string.format("/%d",needNum))
		
		node:getChildByName("btnGo"):getChildByName("btnText"):setString(CONF:getStringValue("go"))
		node:getChildByName("btnGo"):addClickEventListener(function (sender)
			playEffectSound("sound/system/click.mp3")
			local conf = CONF.TASK.get(sender:getParent():getTag())
			goScene(conf.TURN_TYPE, conf.TURN_ID)
		end)
	else --如果任务未开放，则显示开放条件  
		animManager:runAnimOnceByCSB(node,"TaskScene/TaskNode.csb" ,"unopen")

		if conf.OPEN_LEVEL > player:getLevel() then 
			node:getChildByName("openCondition"):setString("LV " .. conf.OPEN_LEVEL)         
		end
		--showTaskNodeItem(id , node, true)
	end
showTaskNodeItem(id , node, true)
	if index then
		if index % 2 == 0 then
			node:getChildByName("bg"):setOpacity(255*0.2)
		elseif index % 2 == 1 then 
			node:getChildByName("bg"):setOpacity(255*0.3)
		end
	end

	node:setTag(id)
	return node
end

function MainTaskNode:selectNode(id, node, flag )
	if flag == true then
		node:getChildByName("selectedBg"):setVisible(true)


			showTaskNodeItem(id ,node, true)
	else
		node:getChildByName("selectedBg"):setVisible(false)

			showTaskNodeItem(id ,node, true)
	end
end

function MainTaskNode:changeState( tag )
	local curTask = nil
	
	if self:getChildByTag(tag) then
		curTask = self:getChildByTag(tag)
	else
		printInfo("error :node is nil")
		return
	end

	if self.selcetedTaskTag == tag then
		self:selectNode(tag, curTask, false )
		self.selcetedTaskTag = -1 
		return
	end

	if self.selcetedTaskTag ~= -1 then
		local preTask = self:getChildByTag(self.selcetedTaskTag)
		if preTask then
			self:selectNode(self.selcetedTaskTag, preTask, false)
		end
	end

	self:selectNode(tag, curTask, true)

	self.selcetedTaskTag = tag 
end

function MainTaskNode:resetList()
	self:getChildByName("after"):setVisible(false)
	if Tools.isEmpty(self.task_list) then 
		self:getChildByName("after"):setVisible(true)
		self:getChildByName("after"):setString(CONF:getStringValue("coming soon"))
		return       
	end
	--分组
	local mainTaskId
	local groupList ={}
	for i,v in ipairs(self.task_list) do
		local conf = CONF.TASK.get(v.task_id)
		groupList[conf.GROUP] = groupList[conf.GROUP] or {}

		if conf.TYPE == 0 then
			table.insert(groupList[conf.GROUP] , conf)
		end
	end

	local function sort(a, b)

		local isOpenA = player:IsTaskOpen(a)
		local isOpenB = player:IsTaskOpen(b)
		if isOpenA == false and isOpenB == true then
			return false
		elseif isOpenA == true and isOpenB == false then
			return true
		else
			local isAchievedA = player:IsTaskAchieved(a)
			local isAchievedB = player:IsTaskAchieved(b)
			if isAchievedA == false and isAchievedB == true then
				return false
			elseif isAchievedA == true and isAchievedB == false then
				return true
			else
				if a.TYPE < b.TYPE then
					return true
				elseif a.TYPE > b.TYPE then
					return false
				else
					return a.ID < b.ID
				end
			end
		end
	end

	local tasks = {}
	for k,v in pairs(groupList) do
		table.sort(groupList[k], sort)
		table.insert(tasks , groupList[k][1])
	end
	table.sort( tasks, sort)
	mainTaskId = tasks[1] and tasks[1].ID
	-----------------
	if not mainTaskId then
		self:getChildByName("after"):setVisible(true)
		self:getChildByName("after"):setString(CONF:getStringValue("coming soon"))
	end
	if self:getChildByName("mainTask") then
		self:getChildByName("mainTask"):removeFromParent()
	end
	self.selcetedTaskTag = -1

	local mainTask = self:createTask(mainTaskId, true)
	if mainTask then
		mainTask:setName("mainTask")
		mainTask:getChildByName("bg"):setTouchEnabled(true)
		mainTask:getChildByName("bg"):addClickEventListener(function ( sender )
			self:changeState(sender:getParent():getTag())
		end)
		self:addChild(mainTask)
		mainTask:setPosition(cc.p(self:getChildByName("main_task_pos"):getPosition()))
	end
end


function MainTaskNode:init()
	printInfo("MainTaskNode:init()")
	local title1 = self:getChildByName("title1")
	title1:getChildByName("MT"):setString(CONF:getStringValue("mainTask"))
	-- print("### LUA MainTaskNode title1:getChildByName(MT):setString = " .. tostring(CONF:getStringValue("mainTask")))

	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_LIST_REQ"),0)
	gl:retainLoading()

	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_LIST_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("TaskListResp",strData)
			if proto.result ~= 0 then
				-- print("get task error :",proto.result)
				return
			end
	
			self.task_list = proto.task_list
			player:setTaskList(proto.task_list)
			self:resetList()
	
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_REWARD_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("TaskRewardResp",strData)
			if proto.result ~= 0 then
				-- print("get task error :",proto.result)
			else
				if proto.task_id > 0 then
					flurryLogEvent("task", {task_id = tostring(proto.task_id)}, 2)
					local gold_num = 0
					local credit_num = 0
					for i,v in ipairs(CONF.TASK.get(proto.task_id).ITEM_ID) do
						if v == 3001 then
							gold_num = CONF.TASK.get(proto.task_id).ITEM_NUM[i]
							
						elseif v == 7001 then
							credit_num = CONF.TASK.get(proto.task_id).ITEM_NUM[i]
						end
					end
					flurryLogEvent("get_gold_by_task", {task_id = tostring(proto.task_id), gold_num = gold_num}, 1, gold_num)

					if credit_num > 0 then
						flurryLogEvent("get_credit_by_task", {task_id = tostring(proto.task_id), credit_num = credit_num}, 1, credit_num)
					end
				end

				if guideManager:getShowGuide() then
					if guideManager:getGuideType() then
						guideManager:doEvent("recv")
					end
				end

				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)  

				playEffectSound("sound/system/reward.mp3")
				self.task_list = player:getTaskList()
				self:resetList()
				-- Tips:tips(CONF:getStringValue("getSucess"))

				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("TaskUpdate")

				local taskConf = CONF.TASK.get(proto.task_id)
				local items = {}
				for i,v in ipairs(taskConf.ITEM_ID) do
					table.insert(items, {id = v, num = taskConf.ITEM_NUM[i]})
				end
				if self.scene_ then
					local node = require("util.RewardNode"):createGettedNodeWithList(items, nil , self.scene_)
					tipsAction(node)
					node:setPosition(cc.exports.VisibleRect:center())
					self.scene_:addChild(node)

					--local getTip = require("util.RewardNode"):createRewardTipFromList(items)
					--local pos = cc.exports.VisibleRect:top();
					--getTip:setPosition(cc.exports.VisibleRect:top());
					--self.scene_:addChild(getTip)
				end
			end
		end

	end
	local eventDispatcher = self:getEventDispatcher()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.upgradeOverListener_ = cc.EventListenerCustom:create("upgradeOver", function ()
		if g_Player_Level ~= player:getLevel() then
            if cc.exports.clickTaskReward ~= nil and cc.exports.clickTaskReward then 
                cc.exports.levelup_param = {player:getLevel(),g_Player_Level}
            else
			    createLevelUpNode(player:getLevel(), g_Player_Level)
            end
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.upgradeOverListener_, FixedPriority.kNormal)
end

function MainTaskNode:destroy()
	printInfo("MainTaskNode:destroy()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.upgradeOverListener_)
end

return MainTaskNode