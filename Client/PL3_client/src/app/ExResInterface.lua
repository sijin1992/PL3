print( "###LUA ExResInterface.lua" )
-- Coded by Wei Jingjun 20180619
local ExResInterface = class("ExResInterface")
-- ExResInterface = require("app.ExResInterface")

ExResInterface.EX_OptimizedLoader = require("app.ExResPreloader"):getInstance()

-- XXX.ExResInterface = require("app.ExResInterface"):getInstance()

------------------------------------------------

function ExResInterface:FastLoad(file)
	--print("###LUA                                         ")
	--print("###LUA INTERFACE FastLoad: " .. tostring(file))
	-- local res = self.EX_OptimizedLoader:CacheLoad(file)
	local res = cc.CSLoader:createNode(file)
	return res
end

------------------------------------------------

function ExResInterface:getInstance()
	--print( "###LUA ExResInterface.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExResInterface:onCreate()
	--print( "###LUA ExResInterface.lua onCreate" )

	

	return self
end

--print( "###LUA Return ExResInterface.lua" )
return ExResInterface