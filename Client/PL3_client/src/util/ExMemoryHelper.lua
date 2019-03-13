print( "###LUA ExMemoryHelper.lua" )
-- Coded by Wei Jingjun 20180625
local ExMemoryHelper = class("ExMemoryHelper")
ExMemoryHelper.app = require("app.MyApp"):getInstance()
ExMemoryHelper.ExResPreloader = require("app.ExResPreloader"):getInstance()
ExMemoryHelper.memoryTools = require("util.ExMemoryTools"):getInstance()
ExMemoryHelper.directorHelper = require("util.ExDirectorHelper"):getInstance()


ExMemoryHelper.lastReleaseMemoryTime = -1
ExMemoryHelper.RELEASE_TIME_MIN = 3

ExMemoryHelper.IS_DEBUG_LOG_LOCAL = false

function ExMemoryHelper:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end
------------------------------------------------

function ExMemoryHelper:getApp()
	return self.app
end


------------------------------------------------

function ExMemoryHelper:PurgeCache(is_empty_scene, is_director_pause)
	self.memoryTools:PurgeCache(is_empty_scene, is_director_pause)
end

function ExMemoryHelper:ReleaseMemory(is_empty_scene)
	local time_began = os.clock()
	self:_print(string.format("@@@@ ReleaseMemory ! now: %s", tostring(time_began)))
	local time_min = (self.lastReleaseMemoryTime + self.RELEASE_TIME_MIN)
	if( time_began < time_min ) then
		self:_print(string.format("_____ DO NOT ExMemoryHelper ReleaseMemory ! time_min: %s", tostring(time_min)))
		do return end
	end

	self.directorHelper:Pause()

	cc.exports.G_IsCachePoolLocked = true

	self.ExResPreloader:OnRelease()

	self:PurgeCache(is_empty_scene, false)

	local time_passed = os.clock() - time_began
	self:_print(string.format("@@@@ ReleaseMemory ! time_passed: %s", tostring(time_passed)))


	cc.exports.G_IsCachePoolLocked = false
	self.directorHelper:Resume()
end

------------------------------------------------

function ExMemoryHelper:getInstance()
	print( "###LUA ExMemoryHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExMemoryHelper:onCreate()
	print( "###LUA ExMemoryHelper.lua onCreate" )

	return self
end

print( "###LUA Return ExMemoryHelper.lua" )
return ExMemoryHelper