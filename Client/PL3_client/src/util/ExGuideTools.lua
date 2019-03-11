print( "###LUA ExGuideTools.lua" )
-- Coded by Wei Jingjun 20180629
local ExGuideTools = class("ExGuideTools")

ExGuideTools.IS_DEBUG_LOG_LOCAL = false

function ExGuideTools:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

------------------------------------------------

function ExGuideTools:IsNewPlayerGuideMode()
	local gid = self:GetGuideIdLocal() or -1


	local is_guide_ended = (gid < 0) or (gid > 99)

	return is_guide_ended == false
end

function ExGuideTools:GetGuideIdLocal()
	-- local id_current = self.guideManager.guide_id
	-- local id_current = tonumber( cc.UserDefault:getInstance():getStringForKey("global_guide_id_last") or -1 )
	local id_current = tonumber( cc.exports.global_guide_id_last or -1 )
	return id_current
end


------------------------------------------------

function ExGuideTools:getInstance()
	print( "###LUA ExGuideTools.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExGuideTools:onCreate()
	print( "###LUA ExMemoryHelper.lua onCreate" )

	return self
end

print( "###LUA Return ExGuideTools.lua" )
return ExGuideTools