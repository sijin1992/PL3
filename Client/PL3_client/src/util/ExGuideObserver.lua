print( "###LUA ExGuideObserver.lua" )
-- Coded by Wei Jingjun 20180612
local ExGuideObserver = class("ExGuideObserver")

ExGuideObserver.IS_DEBUG_LOG_LOCAL = false

function ExGuideObserver:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

------------------------------------------------

ExGuideObserver.exSchedulerHelper_single = require("util.ExSchedulerHelper")
ExGuideObserver.exSchedulerHelper = {}
ExGuideObserver.UPDATE_INTERVAL = 1 * 0.25 * 0.75
ExGuideObserver.UPDATE_INIT = 0
ExGuideObserver.UPDATE_MAX = 1
-- only need 1 time to fininsh

ExGuideObserver.logicHelper = require("util.ExGuideHelper")

------------------------------------------------








------------------------------------------------
function ExGuideObserver:OnSchedulerUpdate()
	local _self = ExGuideObserver
	if( _self.exSchedulerHelper.ScheduleState ~= _self.exSchedulerHelper.E_LOADING_STATE.RUNNING ) then
		--print( "###LUA NOT RUNNING !! ExGuideObserver State: " .. ( tostring(_self.exSchedulerHelper.ScheduleState) or " nil " ) )
		do return end
	end

	_self.logicHelper:OnUpdate()
end

function ExGuideObserver:OnSchedulerEnd()
	self:_print("@@@@ ExGuideObserver:OnSchedulerEnd")
end

function ExGuideObserver:InitScheduler()
	--print( "###LUA ExGuideObserver.lua InitScheduler" )
	self.exSchedulerHelper = self.exSchedulerHelper_single:new(self.exSchedulerHelper, self.UPDATE_INTERVAL, self.UPDATE_INIT, self.UPDATE_MAX )
	self.exSchedulerHelper:RegisterCallBack(self.OnSchedulerEnd)
	self.exSchedulerHelper:OnBegin(self.OnSchedulerUpdate)
end
------------------------------------------------

function ExGuideObserver:getInstance()
	--print( "###LUA ExGuideObserver.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExGuideObserver:onCreate()
	--print( "###LUA ExGuideObserver.lua onCreate" )
	if( self.exSchedulerHelper.count_current == nil ) then
		self:InitScheduler()
	end

	return self
end

print( "###LUA Return ExGuideObserver.lua" )
return ExGuideObserver