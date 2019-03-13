print( "###LUA ExMemoryReleaseAsync.lua" )
-- Coded by Wei Jingjun 20180705
local ExMemoryReleaseAsync = class("ExMemoryReleaseAsync")

ExMemoryReleaseAsync.IS_DEBUG_LOG_LOCAL = false

function ExMemoryReleaseAsync:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

------------------------------------------------

ExMemoryReleaseAsync.strategy = require("util.ExMemoryStrategy"):getInstance()

ExMemoryReleaseAsync.exSchedulerHelper_single = require("util.ExSchedulerHelper")
ExMemoryReleaseAsync.exSchedulerHelper = {}
ExMemoryReleaseAsync.UPDATE_INTERVAL_ORIGIN = 0.013
ExMemoryReleaseAsync.TimesReleaseOnce = 20
ExMemoryReleaseAsync.UPDATE_INTERVAL = 0.5 --ExMemoryReleaseAsync.UPDATE_INTERVAL_ORIGIN
ExMemoryReleaseAsync.UPDATE_INIT = 0
ExMemoryReleaseAsync.UPDATE_MAX = 1
-- only need 1 time to fininsh



ExMemoryReleaseAsync.isReleaseEnabled = true
ExMemoryReleaseAsync.isAnimationFrameReleaseEnabled = false
------------------------------------------------

function ExMemoryReleaseAsync:ResetUpdateInterval()
	self.TimesReleaseOnce = 20
end

function ExMemoryReleaseAsync:SetUpdateFastOnTransfer()
	self.TimesReleaseOnce = 30
end



function ExMemoryReleaseAsync:OnReleaseOnce()
	local _self = ExMemoryReleaseAsync
	if( _self.strategy:IsAsyncMemReleaseEnabled() == false ) then
		return
	end

	local director = cc.Director:getInstance()
    if not director then
        return
    end
	local view = director:getOpenGLView()
	if( view == nil ) then
		_self:_print("____ NOT OnReleaseOnce getOpenGLView nil  now: " .. tostring(os.clock()))
		do return end
	end


	_self:_print("@@@ OnReleaseOnce now: " .. tostring(os.clock()))
	if( self.isAnimationFrameReleaseEnabled ) then
		cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
	end
    if director:getTextureCache() then
	    director:getTextureCache():removeUnusedTextures()
    end
end

------------------------------------------------
function ExMemoryReleaseAsync:OnSchedulerUpdate()
	local _self = cc.exports.memoryReleaseAsync
	if( _self.exSchedulerHelper.ScheduleState ~= _self.exSchedulerHelper.E_LOADING_STATE.RUNNING ) then
		print( "###LUA NOT RUNNING !! ExMemoryReleaseAsync State: " .. ( tostring(_self.exSchedulerHelper.ScheduleState) or " nil " ) )
		do return end
	end

	if( _self.strategy:IsAsyncMemReleaseEnabled() == false ) then
		return
	end

	for i = 1, _self.TimesReleaseOnce do
		if( _self.isReleaseEnabled ) then
			_self:_print("@@@ OnReleaseOnce i: " .. tostring(i))
			_self:OnReleaseOnce()
		end
	end
end

function ExMemoryReleaseAsync:OnSchedulerEnd()
	self:_print("@@@@ ExMemoryReleaseAsync:OnSchedulerEnd")
end

function ExMemoryReleaseAsync:InitScheduler()
	print( "###LUA ExMemoryReleaseAsync.lua InitScheduler" )
	self.exSchedulerHelper = self.exSchedulerHelper_single:new(self.exSchedulerHelper, self.UPDATE_INTERVAL, self.UPDATE_INIT, self.UPDATE_MAX )
	self.exSchedulerHelper:RegisterCallBack(self.OnSchedulerEnd)
	self.exSchedulerHelper:OnBegin(self.OnSchedulerUpdate)
end
------------------------------------------------

function ExMemoryReleaseAsync:getInstance()
	print( "###LUA ExMemoryReleaseAsync.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExMemoryReleaseAsync:onCreate()
	print( "###LUA ExMemoryReleaseAsync.lua onCreate" )
	if( self.exSchedulerHelper.count_current == nil ) then
		self:InitScheduler()
	end

	return self
end

print( "###LUA Return ExMemoryReleaseAsync.lua" )
return ExMemoryReleaseAsync