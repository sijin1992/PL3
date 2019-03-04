-- Coded by Wei Jingjun 20180613
print( "###LUA ExMemoryStrategy.lua" )
local ExMemoryStrategy = class("ExMemoryStrategy")

ExMemoryStrategy.IS_DEBUG_LOG_VERBOSE_LOCAL = false

function ExMemoryStrategy:_print(_log)
	if( self.IS_DEBUG_LOG_VERBOSE_LOCAL ) then
		print(_log)
	end
end

ExMemoryStrategy.config = require("util.ExConfig"):getInstance()
ExMemoryStrategy.guideTools =  require("util.ExGuideTools"):getInstance()


------------------------------------------------

function ExMemoryStrategy:IsAsyncMemReleaseEnabled()
	self:_print("@@@@ IsAsyncMemReleaseEnabled")
    if cc.exports.updateHot then
        do return false end
    end
	-- always release images before update scene, even in tutorial scene... or memory very big..
	local _self = cc.exports.memoryReleaseAsync
	do return _self.isReleaseEnabled end
	-- do return self:IsMemReleaseEnabled() end
end

function ExMemoryStrategy:IsMemReleaseEnabled()
	self:_print("@@@@ IsMemReleaseEnabled")
    if cc.exports.updateHot then
        do return false end
    end
	-- ADD WJJ 20180704
	if( (g_is_release_memory_enabled == false) and ( device.platform == "windows" ) ) then
		self:_print(" *** DO NOT RELEASE MEM ON windows ")
		do return false end
	end


	-- ADD WJJ 20180703
	if( self.config.isMainGameSceneEntered == false ) then
		do return false end
	end

	local is_guide_now = self.guideTools:IsNewPlayerGuideMode()
	local is_release = is_guide_now == false

	do return is_release end
end
------------------------------------------------

function ExMemoryStrategy:getInstance()
	print( "###LUA ExMemoryStrategy.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExMemoryStrategy:onCreate()
	print( "###LUA ExMemoryStrategy.lua onCreate" )

	self.ExDictWJJ:onCreate()

	return self.instance
end

print( "###LUA Return ExMemoryStrategy.lua" )
return ExMemoryStrategy