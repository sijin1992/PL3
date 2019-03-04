-- Coded by Wei Jingjun 20180716
print( "###LUA ExImageLoader.lua" )
local ExImageLoader = class("ExImageLoader")

ExImageLoader.IS_DEBUG_LOG_VERBOSE_LOCAL = false

function ExImageLoader:_print(_log)
	if( self.IS_DEBUG_LOG_VERBOSE_LOCAL ) then
		print(_log)
	end
end
------------------------------------------------
ExImageLoader.director = cc.Director:getInstance()
ExImageLoader.textureCache = ExImageLoader.director:getTextureCache()
------------------------------------------------

function ExImageLoader:Load(filePath, _isUseNow, is_retain, callback)
    	if not callback then
		callback = function()
			self:_print( "~~~~ imageLoader Load END: " ..  tostring(filePath) .. " now: " .. tostring(os.clock())  )
		end
	end

	self.textureCache:addImageAsync(filePath, callback)
end

------------------------------------------------

function ExImageLoader:getInstance()
	print( "###LUA ExImageLoader.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExImageLoader:onCreate()
	print( "###LUA ExImageLoader.lua onCreate" )


	return self.instance
end

print( "###LUA Return ExImageLoader.lua" )
return ExImageLoader