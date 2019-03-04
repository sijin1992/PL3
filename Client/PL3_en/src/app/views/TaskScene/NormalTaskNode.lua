local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()
local schedulerEntry = nil

local NormalTaskNode = class("NormalTaskNode",function()
	return require("app.ExResInterface"):getInstance():FastLoad("TaskScene/NormalTask.csb")
end)


function NormalTaskNode:ctor(scene)

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

local preBoundTaskIndex = 1
local function update( dt , frist)
	if Tools.isEmpty(NormalTaskNode.preBoundTask) == false then
		dump(NormalTaskNode.preBoundTask)
		local count = 1
		for i,v in ipairs(NormalTaskNode.preBoundTask) do
			if i >= preBoundTaskIndex  then
				local bountyTask = NormalTaskNode:createTask(v , false, index)
				if bountyTask then
					bountyTask:setTag(v)
					NormalTaskNode.svd_:addElement(bountyTask)
					NormalTaskNode.svd_:addListener(bountyTask:getChildByName("bg"), function ( sender )
						NormalTaskNode:changeState(sender:getParent():getTag())
					end)
				end				
				count = count + 1
				if count > (frist and 10 or 1) then
					preBoundTaskIndex = preBoundTaskIndex + (count - 1)
					return 
				end
			end		
		end
	end
	if schedulerEntry ~= nil then
		preBoundTaskIndex = #NormalTaskNode.preBoundTask
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil 
	end
end

function NormalTaskNode:createTask( id, isMain, index )
	if id == nil then
		return
	end
	local node = require("app.ExResInterface"):getInstance():FastLoad("TaskScene/TaskNode.csb")
	local conf = CONF.TASK.get(id)
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
	node:getChildByName("taskName"):setString(name_str)
	
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
	if conf.OPEN_LEVEL > player:getLevel() then
		isOpen = false 
	end
   
	if isAchieved == true and  isOpen == true then ----如果已经完成，则显示领取按钮

		animManager:runAnimOnceByCSB(node,"TaskScene/TaskNode.csb" ,"get")

		node:getChildByName("completeNum"):setString(tostring(completeNum))
		node:getChildByName("needNum"):setString(string.format("/%d",needNum))

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
			-- node:getChildByName("bg"):setOpacity(255*0.2)
		elseif index % 2 == 1 then 
			-- node:getChildByName("bg"):setOpacity(255*0.3)
		end
	end

	node:setTag(id)
	return node
end

function NormalTaskNode:selectNode(id, node, flag )

	if flag == true then
		node:getChildByName("selectedBg"):setVisible(true)

			showTaskNodeItem(id ,node, true)

	else
		node:getChildByName("selectedBg"):setVisible(false)

			showTaskNodeItem(id ,node, true)

	end
end

function NormalTaskNode:changeState( tag )
	local curTask = nil
	
	if self:getChildByName("list"):getChildByTag(tag) then
		curTask = self:getChildByName("list"):getChildByTag(tag)
	elseif self:getChildByTag(tag) then
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
		local preTask = self:getChildByName("list"):getChildByTag(self.selcetedTaskTag)

		if preTask == nil then
			preTask = self:getChildByTag(self.selcetedTaskTag)
		end
		if preTask then
			self:selectNode(self.selcetedTaskTag, preTask, false)
		end
	end

	self:selectNode(tag, curTask, true)

	self.selcetedTaskTag = tag 
end

function NormalTaskNode:resetList()

	local function getNoTaskString( ... )

		local level = 0
		local task_id = 0 
		for i,v in ipairs(CONF.TASK.getIDList()) do
			local conf = CONF.TASK.get(v)
			if conf.TYPE == 2 then 
				if conf.OPEN_LEVEL > player:getLevel() then
					if level == 0 then
						level = conf.OPEN_LEVEL
						task_id = conf.ID
					else
						if level > conf.OPEN_LEVEL then
							level = conf.OPEN_LEVEL
							task_id = conf.ID
						end
					end
				end
		   	end
		end

		local finish = true
		for i,v in ipairs(CONF.TASK.getIDList()) do
			local conf = CONF.TASK.get(v)
			if conf.NEXT_ID then
				for i2,v2 in ipairs(conf.NEXT_ID) do
					if v2 == task_id then
						finish = player:IsTaskGetedReward(conf)
						break
					end
				end
			end
		end

		local str = ""
		if level == 0 then
			str = CONF:getStringValue("all task finish")		
		else

			if finish then
				str = CONF:getStringValue("hero")..CONF:getStringValue("level")..level..CONF:getStringValue("Can pick up")
			else
				str = CONF:getStringValue("finish task")	
			end
		end

		return str
	end


	self:getChildByName("after"):setVisible(false)
	if Tools.isEmpty(self.task_list) then
		self:getChildByName("after"):setVisible(true)
		self:getChildByName("after"):setString(getNoTaskString()) 
		return       
	end
	--分组
	local groupList ={}
	for i,v in ipairs(self.task_list) do
		local conf = CONF.TASK.get(v.task_id)
		if conf.TYPE == 2 then 
			table.insert(groupList , conf.ID)
	   	end
	end
	-----------------
	if Tools.isEmpty(groupList) then
		self:getChildByName("after"):setVisible(true)
		self:getChildByName("after"):setString(getNoTaskString())
	end
	NormalTaskNode.svd_:clear()
	if self:getChildByName("mainTask") then
		self:getChildByName("mainTask"):removeFromParent()
	end
	self.selcetedTaskTag = -1

	NormalTaskNode.preBoundTask = groupList

	local function sort(a, b)
		local confA = CONF.TASK.get(a)
		local confB = CONF.TASK.get(b)
		local isAchievedA = player:IsTaskAchieved(confA)
		local isAchievedB = player:IsTaskAchieved(confB)
		if isAchievedA == false and isAchievedB == true then
			return false
		elseif isAchievedA == true and isAchievedB == false then
			return true
		else
			local isOpenA = player:IsTaskOpen(confA)
			local isOpenB = player:IsTaskOpen(confB)
			if isOpenA == false and isOpenB == true then
				return false
			elseif isOpenA == true and isOpenB == false then
				return true
			else
				return a < b
			end
		end
	end
	table.sort( NormalTaskNode.preBoundTask, sort)
	preBoundTaskIndex = 1
	if schedulerEntry == nil  then
		schedulerEntry = scheduler:scheduleScriptFunc(update,0.25,false)
	end
	update(0 , true)

end


function NormalTaskNode:init()
	printInfo("NormalTaskNode:init()")
	local title1 = self:getChildByName("title1")
	title1:getChildByName("BT"):setString(CONF:getStringValue("bountyTask"))

	local list = self:getChildByName("list")
	list:setScrollBarEnabled(false)
	--list:setOpacity(0)
	NormalTaskNode.svd_ = require("util.ScrollViewDelegate"):create(list,cc.size(5,2), cc.size(957,90))

	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_LIST_REQ"),0)
	gl:retainLoading()

	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_LIST_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("TaskListResp",strData)
			if proto.result ~= 0 then
				print("get task error :",proto.result)
				return
			end
	
			self.task_list = proto.task_list
			player:setTaskList(proto.task_list)
			self:resetList()
	
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_REWARD_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("TaskRewardResp",strData)
			if proto.result ~= 0 then
				print("get task error :",proto.result)
			else
				if proto.task_id > 0 then
					flurryLogEvent("task", {task_id = tostring(proto.task_id)}, 2)
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

				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("NormalTaskUpdate")

				local taskConf = CONF.TASK.get(proto.task_id)
				local items = {}
				for i,v in ipairs(taskConf.ITEM_ID) do
					table.insert(items, {id = v, num = taskConf.ITEM_NUM[i]})
				end
				if self.scene_ then
					local node = require("util.RewardNode"):createGettedNodeWithList(items, nil, self.scene_)
					tipsAction(node)
					node:setPosition(cc.exports.VisibleRect:center())
					self.scene_:addChild(node)

					--local getTip = require("util.RewardNode"):createRewardTipFromList(items);
					--getTip:setPosition(cc.exports.VisibleRect:top())
					--self.scene_:addChild(getTip);
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

function NormalTaskNode:destroy()
	printInfo("NormalTaskNode:destroy()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.upgradeOverListener_)
	NormalTaskNode.svd_:clear()
	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil 
	end
end

return NormalTaskNode