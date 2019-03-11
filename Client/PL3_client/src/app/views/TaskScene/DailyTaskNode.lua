
local animManager = require("app.AnimManager"):getInstance()

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()

local DailyTaskNode = class("DailyTaskNode",function()
	return require("app.ExResInterface"):getInstance():FastLoad("TaskScene/DailyTask.csb")
end)

function DailyTaskNode:ctor(scene)
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


function DailyTaskNode:createTask( id, index )
	local node = require("app.ExResInterface"):getInstance():FastLoad("TaskScene/TaskNode.csb")
	local conf = CONF.TASK.get(id)

	node:getChildByName("icon"):setTexture("TaskScene/ui/" .. conf.ICON .. ".png")
	local name_str = CONF.STRING.get(conf.NAME).VALUE

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
		end
		if value[2] then
			name_str = string.gsub(name_str,"*",value[2])
		end
		if value[3] then
			name_str = string.gsub(name_str,"&",value[3])
		end
	end
	node:getChildByName("taskName"):setString(name_str)

	node:getChildByName("active"):setString(CONF.STRING.get("active_num").VALUE)
	node:getChildByName("activeNum"):setString(string.format("+%d", conf.ACTIVE_POINT))

	node:getChildByName("geted"):setString(CONF.STRING.get("has_get").VALUE)
	node:getChildByName("open"):setString(CONF.STRING.get("open").VALUE)
	
	--判断任务是否开放
	local isAchieved = false
	local completeNum 
	local needNum
	local getedReward = player:IsTaskGetedReward(conf)
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
   	
   	if getedReward == true then----如果已经领取

   		animManager:runAnimOnceByCSB(node,"TaskScene/TaskNode.csb" ,"daily_geted")


	elseif isAchieved == true and  isOpen == true then ----如果已经完成，则显示领取按钮

		animManager:runAnimOnceByCSB(node,"TaskScene/TaskNode.csb" ,"daily_get")

		node:getChildByName("completeNum"):setString(tostring(completeNum))
		node:getChildByName("needNum"):setString(string.format("/%d",needNum))

		node:getChildByName("btnGet"):getChildByName("btnText"):setString(CONF:getStringValue("Get"))
		node:getChildByName("btnGet"):addClickEventListener(function (sender)
			playEffectSound("sound/system/click.mp3")
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
	elseif isOpen== true then --如果任务开放，则显示进度

		animManager:runAnimOnceByCSB(node,"TaskScene/TaskNode.csb" ,"daily_open")

		node:getChildByName("completeNum"):setString(tostring(completeNum))
		node:getChildByName("needNum"):setString(string.format("/%d",needNum))
		
		node:getChildByName("btnGo"):getChildByName("btnText"):setString(CONF:getStringValue("go"))
		node:getChildByName("btnGo"):addClickEventListener(function (sender)
			playEffectSound("sound/system/click.mp3")
			local conf = CONF.TASK.get(sender:getParent():getTag())
			goScene(conf.TURN_TYPE, conf.TURN_ID)
		end)

	else --如果任务未开放，则显示开放条件  
		animManager:runAnimOnceByCSB(node,"TaskScene/TaskNode.csb" ,"daily_unopen")

		if conf.OPEN_LEVEL > player:getLevel() then 
			node:getChildByName("openCondition"):setString("LV " .. conf.OPEN_LEVEL)         
		end
	end

	-- if index then
	-- 	if index % 2 == 0 then
	-- 		node:getChildByName("bg"):setOpacity(255*0.2)
	-- 	elseif index % 2 == 1 then 
	-- 		node:getChildByName("bg"):setOpacity(255*0.3)
	-- 	end
	-- end

	showTaskNodeItem(id ,node, true)

	node:setTag(id)
	return node
end

function DailyTaskNode:resetList()
	if Tools.isEmpty(self.task_list) then 
		return       
	end
	--分组
	local groupList ={}
	local mainTaskId
	for i,v in ipairs(self.task_list) do
		local conf = CONF.TASK.get(v.task_id)
		if conf.TYPE == 1 then
			groupList[conf.GROUP] = groupList[conf.GROUP] or {}
			table.insert(groupList[conf.GROUP] , conf.ID)
	   	end
	end
	-----------------
	self.svd_:clear()

	self.dailyTask = {}
	for k,v in pairs(groupList) do
		table.sort(groupList[k], sort)
		table.insert(self.dailyTask , groupList[k][1])
	end

	local function sort(a, b)
		local confA = CONF.TASK.get(a)
		local confB = CONF.TASK.get(b)
		
		local getedRewardA = player:IsTaskGetedReward(confA)
		local getedRewardB = player:IsTaskGetedReward(confB)
	
		if getedRewardA == true and getedRewardB == false then
			return false
		elseif getedRewardA == false and getedRewardB == true then
			return true
		else
			local isAchievedA = player:IsTaskAchieved(confA)
			local isAchievedB = player:IsTaskAchieved(confB)
			if isAchievedA == false and isAchievedB == true then
				return false
			elseif isAchievedA == true and isAchievedB == false then
				return true
			else
				local isOpenA = player:IsTaskOpen(CONF.TASK.get(a))
				local isOpenB = player:IsTaskOpen(CONF.TASK.get(b))
				if isOpenA == false and isOpenB == true then
					return false
				elseif isOpenA == true and isOpenB == false then
					return true
				else
					return a < b
				end
			end
		end
	end
	table.sort( self.dailyTask, sort)

	local index = 1
	for i,v in ipairs(self.dailyTask) do
		local task = self:createTask(v, index)
		if task then
			task:setTag(v)
			self.svd_:addElement(task)
		end
		index = index + 1
	end
end

function DailyTaskNode:resetActive( )

	local cur_active = player:getDailyActive()
	self:getChildByName("cur_active_num"):setString(tostring(cur_active))
--	self:getChildByName("cur_active_num"):setPositionX(self:getChildByName("cur_active"):getPositionX() + self:getChildByName("cur_active"):getContentSize().width)

	local level = player:getLevel()

	local dailyConf
	local daily_list = CONF.DAILYTASK.getIDList()
	for i,v in ipairs(daily_list) do
		local conf = CONF.DAILYTASK.get(v)
		if level >= conf.START_LEVEL and level <= conf.END_LEVEL then
			dailyConf = conf
			break
		end
	end
	if not dailyConf then
		dailyConf =  CONF.DAILYTASK.get(daily_list[#daily_list])
	end

	local max_active = CONF.PARAM.get("max_active").PARAM
	self:getChildByName("active_progress"):setPercent(cur_active / max_active * 100)
	local active_length = self:getChildByName("active_progress_buttom"):getContentSize().width
	for i=1,4 do
		local active_icon = self:getChildByName("actives"):getChildByName("active_"..i)
		local need = dailyConf["ACTIVE_POINT"..i]
 
		active_icon:setPositionX(need / max_active * active_length)
		active_icon:getChildByName("num"):setString(tostring(need))

		active_icon:getChildByName("btn"):loadTextures("TaskScene/ui/active_"..i..".png", "TaskScene/ui/active_select_"..i..".png", "TaskScene/ui/active_gray_"..i..".png")
		active_icon:getChildByName("get"):setTexture("TaskScene/ui/active_gray_"..i..".png")
		active_icon:getChildByName("btn"):setTag(i)
		
		if cur_active < need then --不能领

			animManager:runAnimOnceByCSB(active_icon,"TaskScene/ActiveIcon.csb" ,"unopen")

		elseif cur_active >= need and player:isGetDailyActiveReward(i) == false then --可以领取

			animManager:runAnimByCSB(active_icon, "TaskScene/ActiveIcon.csb" , "get")

		else--已经领取
			animManager:runAnimOnceByCSB(active_icon, "TaskScene/ActiveIcon.csb" , "getted")
		end
	end
end

function DailyTaskNode:clickActive(index)
	local cur_active = player:getDailyActive()
	local level = player:getLevel()

	local dailyConf
	local daily_id_list = CONF.DAILYTASK.getIDList()
	for i,id in ipairs(daily_id_list) do
		local conf = CONF.DAILYTASK.get(id)
		if level >= conf.START_LEVEL and level <= conf.END_LEVEL then
			dailyConf = conf
			break
		end
	end
	if not dailyConf then
		dailyConf = CONF.DAILYTASK.get(daily_id_list[#daily_id_list])
	end

	local need = dailyConf["ACTIVE_POINT"..index]
	
	local canGet = false

	local function func( )
		if canGet == true then
			local function func( ... )
				local strData = Tools.encode("TaskRewardReq", {
					task_id = -index,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_REWARD_REQ"),strData)
				gl:retainLoading()
			end

			print("iiiiiii",-index)
			local rw_conf = CONF.REWARD.get(dailyConf["REWARD"..index])
			if checkRewardBeMax(rw_conf.ITEM, rw_conf.COUNT) then
				func()
			else
				local messageBox = require("util.MessageBox"):getInstance()

				messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
			end
		end
	end

	local node = require("util.RewardNode"):createNode(dailyConf["REWARD"..index], func)

	--local getTip = require("util.RewardNode"):createRewardTip(dailyConf["REWARD"..index], func)

	if cur_active < need then --不能领

		node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))

	elseif cur_active >= need and player:isGetDailyActiveReward(index) == true then --已经领取

		node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
	else
		node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("Get"))
		canGet = true
	end

	tipsAction(node)
	node:setPosition(cc.exports.VisibleRect:center())
	node:setName("reward_node")
	self.scene_:addChild(node)

end

function DailyTaskNode:init()

	self:getChildByName("cur_active"):setString(CONF:getStringValue("cur_active"))
	self:getChildByName("cur_active_0"):setString(CONF:getStringValue("task_list"))
	
	self:resetActive()
	for i=1,4 do
		local active_icon = self:getChildByName("actives"):getChildByName("active_"..i)
		active_icon:getChildByName("btn"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/click.mp3")
			self:clickActive(sender:getTag())
		end)
	end

	local list = self:getChildByName("list")
	list:setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(list,cc.size(5,2), cc.size(957,96))

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

				playEffectSound("sound/system/reward.mp3")
				self.task_list = player:getTaskList()
				self:resetActive()
				self:resetList()
				--Tips:tips(CONF:getStringValue("getSucess"))
				
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("DailyTaskUpdate")

				local items = {}
				if proto.task_id < 0 then
					local want_get_level = -proto.task_id
					local dailyConf
					local daily_list = CONF.DAILYTASK.getIDList()
					for i,v in ipairs(daily_list) do
						local conf = CONF.DAILYTASK.get(v)
						if player:getLevel() >= conf.START_LEVEL and player:getLevel() <= conf.END_LEVEL then
							dailyConf = conf
							break
						end
					end
					if dailyConf == nil then
						dailyConf = CONF.DAILYTASK.get(daily_list[#daily_list])
					end
					local rewardConf = CONF.REWARD.get(dailyConf["REWARD"..want_get_level])
					for i,v in ipairs(rewardConf.ITEM) do
						table.insert(items, {id = v, num = rewardConf.COUNT[i]})
					end
				else
					local taskConf = CONF.TASK.get(proto.task_id)

					for i,v in ipairs(taskConf.ITEM_ID) do
						table.insert(items, {id = v, num = taskConf.ITEM_NUM[i]})
					end
				end

				if self.scene_ then
					local node = require("util.RewardNode"):createGettedNodeWithList(items, nil, self.scene_);
					tipsAction(node)
					node:setPosition(cc.exports.VisibleRect:center())
					self.scene_:addChild(node)

					--local getTip = require("util.RewardNode"):createRewardTipFromList(items)
					--getTip:setPosition(cc.exports.VisibleRect:top())
					--self.scene_:addChild(getTip)
				end
			end
		end

	end
	local eventDispatcher = self:getEventDispatcher()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function DailyTaskNode:destroy()
	printInfo("DailyTaskNode:destroy()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	self.svd_:clear()
end

return DailyTaskNode