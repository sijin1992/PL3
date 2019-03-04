print( "###LUA ExMemoryInterface.lua" )
-- Coded by Wei Jingjun 20180625
local ExMemoryInterface = class("ExMemoryInterface")
ExMemoryInterface.app = require("app.MyApp"):getInstance()
ExMemoryInterface.memoryHelper = require("util.ExMemoryHelper"):getInstance()
ExMemoryInterface.loader = require("util.ExAsyncLoadTimer"):getInstance()



ExMemoryInterface.IS_DEBUG_LOG_LOCAL = false

function ExMemoryInterface:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end
------------------------------------------------

function ExMemoryInterface:getApp()
	return self.app
end


------------------------------------------------

function ExMemoryInterface:OnEnableAnimationReleaseAsync()
	self:_print("____  OnEnableMemoryReleaseAsync")
	local instance = cc.exports.memoryReleaseAsync
	if( instance ~= nil ) then
		instance.isAnimationFrameReleaseEnabled = true
	end
end

function ExMemoryInterface:OnDisableAnimationReleaseAsync()
	self:_print("____  OnDisableMemoryReleaseAsync")
	local instance = cc.exports.memoryReleaseAsync
	if( instance ~= nil ) then
		instance.isAnimationFrameReleaseEnabled = false
	else
		self:_print("____  instance nil")
	end
end

function ExMemoryInterface:OnEnableMemoryReleaseAsync()
	self:_print("____  OnEnableMemoryReleaseAsync")
	local instance = cc.exports.memoryReleaseAsync
	if( instance ~= nil ) then
		instance.isReleaseEnabled = true
	end
end

function ExMemoryInterface:OnDisableMemoryReleaseAsync()
	self:_print("____  OnDisableMemoryReleaseAsync")
	local instance = cc.exports.memoryReleaseAsync
	if( instance ~= nil ) then
		instance.isReleaseEnabled = false
	else
		self:_print("____  instance nil")
	end
end

function ExMemoryInterface:OnTransitionScene(is_empty_scene)
	self.loader:ResetLastSceneChangeEndTime()
	self.memoryHelper:ReleaseMemory(is_empty_scene)
end

------------------------------------------------

function ExMemoryInterface:getInstance()
	--print( "###LUA ExMemoryInterface.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExMemoryInterface:onCreate()
	--print( "###LUA ExMemoryInterface.lua onCreate" )

	return self
end

--print( "###LUA Return ExMemoryInterface.lua" )
return ExMemoryInterface