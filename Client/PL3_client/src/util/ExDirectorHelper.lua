-- Coded by Wei Jingjun 20180709
print( "###LUA ExDirectorHelper.lua" )
local ExDirectorHelper = class("ExDirectorHelper")

------------------------------------------------

function ExDirectorHelper:Pause()
	local is_paused = cc.Director:getInstance():isPaused()
	if( is_paused == false ) then
		cc.Director:getInstance():pause()
	end
end

function ExDirectorHelper:Resume()
	local is_paused = cc.Director:getInstance():isPaused()
	if( is_paused  ) then
		cc.Director:getInstance():resume()
	end
end

------------------------------------------------

function ExDirectorHelper:getInstance()
	--print( "###LUA ExDirectorHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExDirectorHelper:onCreate()
	--print( "###LUA ExDirectorHelper.lua onCreate" )


	return self.instance
end

--print( "###LUA Return ExDirectorHelper.lua" )
return ExDirectorHelper