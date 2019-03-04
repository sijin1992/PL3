print( "###LUA ExSchedulerHelper.lua" )

local ExSchedulerHelper = class("ExSchedulerHelper")

ExSchedulerHelper.scheduler = {}
ExSchedulerHelper.schedulerEntry = -1
ExSchedulerHelper.UPDATE_INTERVAL = 0.15

ExSchedulerHelper.count_max = -1
ExSchedulerHelper.count_current = -1

ExSchedulerHelper.E_LOADING_STATE = {}
ExSchedulerHelper.E_LOADING_STATE.NONE = 0
ExSchedulerHelper.E_LOADING_STATE.RUNNING = 1
ExSchedulerHelper.E_LOADING_STATE.FINISHED = 2
ExSchedulerHelper.ScheduleState = ExSchedulerHelper.E_LOADING_STATE.NONE

ExSchedulerHelper.schedulerCallbackOnFininsh = {}

ExSchedulerHelper.IS_DEBUG_LOG_LOCAL = false

function ExSchedulerHelper:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

function ExSchedulerHelper:RegisterCallBack(callback)

	if(  callback == nil ) then
		self:_print( "###LUA ExSchedulerHelper:RegisterCallBack NILL!!!" )
	end

	 self.schedulerCallbackOnFininsh = callback
end


function ExSchedulerHelper:onCreate(_interval, _current, _max )
	self:_print( "###LUA ExSchedulerHelper.lua onCreate" )
	
	self.UPDATE_INTERVAL = _interval
	self.count_current = _current
	self.count_max = _max
	return self
end

function ExSchedulerHelper:new(o, _interval, _current, _max)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
	o:onCreate(_interval, _current, _max)
    return o
end

-- DO NOT SINGLE INSTANCE, we need clone 
--[[
function ExSchedulerHelper:getInstance()
	self:_print( "###LUA ExSchedulerHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end
]]

function ExSchedulerHelper:StopScheduler()
	self:_print( "###LUA ExSchedulerHelper.lua StopScheduler " )
	local _scheduler = self:GetScheduler()

	self:_print( "###LUA ExSchedulerHelper.lua schedulerEntry =  " .. ( tostring(self.schedulerEntry) or " nil" ) )
	_scheduler:unscheduleScriptEntry(self.schedulerEntry)
end

function ExSchedulerHelper:OnEnd()
	self.ScheduleState = self.E_LOADING_STATE.FINISHED
	self:schedulerCallbackOnFininsh()
	self:StopScheduler()
end

function ExSchedulerHelper:OnFinishCheck()
	if( self.count_current > self.count_max ) then
		self:OnEnd()
	end
end

function ExSchedulerHelper:OnUpdateCount()
	if( self.ScheduleState ~= self.E_LOADING_STATE.RUNNING ) then
		self:_print( "###LUA NOT RUNNING !! ExSchedulerHelper.ScheduleState: " .. ( tostring(self.ScheduleState) or " nil " ) )
		do return end
	end

	self:_print( "###LUA ExSchedulerHelper.lua OnUpdateCount time: " .. ( tostring(os.clock()) or "error os.clock" ) )
	self:_print( "###LUA ExSchedulerHelper.lua OnUpdateCount current: " .. ( tostring(self.count_current) or " nil" ) )
	self:_print( "###LUA ExSchedulerHelper.lua OnUpdateCount max: " .. ( tostring(self.count_max) or " nil" ) )

	self.count_current = self.count_current + 1

	self:OnFinishCheck()

end

function ExSchedulerHelper:GetScheduler()
	self.scheduler = cc.Director:getInstance():getScheduler()
	return self.scheduler
end

function ExSchedulerHelper:InitScheduler()
	self:GetScheduler()
end

function ExSchedulerHelper:OnBegin(_action)
	self:GetScheduler()
	self.ScheduleState = self.E_LOADING_STATE.RUNNING
	if schedulerEntry == nil or schedulerEntry <= 0 then
		self.schedulerEntry = self.scheduler:scheduleScriptFunc(_action, self.UPDATE_INTERVAL , false)
		self:_print( "###LUA ExSchedulerHelper.lua schedulerEntry : " .. ( tostring(self.schedulerEntry) or " nil" ) )
	else
		print("@@@@@@@@@@@@@@@@@no schedulerEntry",schedulerEntry)
	end
end

print( "###LUA Return ExSchedulerHelper.lua" )
return ExSchedulerHelper