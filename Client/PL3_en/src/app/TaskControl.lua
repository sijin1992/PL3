local player = require("app.Player"):getInstance()
local TaskManager = class("TaskManager")

function TaskManager:ctor()
	self.m_groupList = {}
	local id_list = CONF.TASK.getIDList()
	for i,v in ipairs(id_list) do
		local conf = CONF.TASK.get(v)
		if conf.TYPE == 3 then
			if conf.GROUP > 0 then
				self.m_groupList[conf.GROUP] = self.m_groupList[conf.GROUP] or {}
				table.insert(self.m_groupList[conf.GROUP],conf.ID)
			end
		end
	end
end

function TaskManager:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end
		
	return self.instance
end

function TaskManager:getTaskConf( group_id, id )
	return self.m_groupList[group_id][id]
end

function TaskManager:getAllAchievement(  )
	return self.m_groupList
end

function TaskManager:getGettedAchievement( )
	local getedList ={}
	for i,v in ipairs(player:getTaskList()) do
		local conf = CONF.TASK.get(v.task_id)
		if conf.TYPE == 3 then
		   	if conf.GROUP > 0 then
				getedList[conf.GROUP] = getedList[conf.GROUP] or {}
				table.insert(getedList[conf.GROUP],v)
		   	end
	   	end
	end

	if Tools.isEmpty(getedList) == false then 
		for k,group in pairs(getedList) do
			table.sort(group, function ( a,b )
				return a.task_id < b.task_id
			end)
		end
	end

	return getedList
end

function TaskManager:hasCanGetAchievement()

	local getedList = self:getGettedAchievement( )

	for k,group in pairs(self:getAllAchievement()) do
		
		if getedList[k] then
			local task_info =getedList[k][#getedList[k]]
			local finished = task_info.finished
			if finished == false then
				return true
			else
				local conf = CONF.TASK.get(task_info.task_id)
				if Tools.isEmpty(conf.NEXT_ID) == false then
					local nextConf = CONF.TASK.get(conf.NEXT_ID[1])
					if player:IsTaskOpen(nextConf) == true then
						if  player:IsTaskAchieved(nextConf) == true then
							return true
						end
					end
				end
			end
		else
			local conf = CONF.TASK.get(group[1])
			if player:IsTaskOpen(conf) == true then
				if  player:IsTaskAchieved(conf) == true then
					return true
				end
			end
		end
	end

	return false
end

function TaskManager:hasUnfinishDailyTask()
	for i,v in ipairs(player:getTaskList()) do
		local conf = CONF.TASK.get(v.task_id)
		if conf.TYPE == 1 then
			if v.finished == false then
				return true
			end
	   	end
	end
	return false
end

function TaskManager:hasCanGetDailyTask()
	for i,v in ipairs(player:getTaskList()) do
		local conf = CONF.TASK.get(v.task_id)
		if conf.TYPE == 1 then
			if player:IsTaskOpen(conf) == true then
				local finish = player:IsTaskAchieved(conf)
				if finish and v.finished == false then
					return true
				end	
			end
	   	end
	end
	return false
end

function TaskManager:hasCanGetMainTask()
	for i,v in ipairs(player:getTaskList()) do
		local conf = CONF.TASK.get(v.task_id)
		if conf.TYPE == 0 then
			if player:IsTaskOpen(conf) == true then
				local finish = player:IsTaskAchieved(conf)
				if finish and v.finished == false then
					return true
				end	
			end
	   	end
	end
	return false
end

function TaskManager:hasCanGetNormalTask()
	for i,v in ipairs(player:getTaskList()) do
		local conf = CONF.TASK.get(v.task_id)
		if conf.TYPE == 2 then
			if player:IsTaskOpen(conf) == true then
				local finish = player:IsTaskAchieved(conf)
				if finish and v.finished == false then
					return true
				end	
			end
	   	end
	end
	return false
end

return TaskManager