-- Coded by Wei Jingjun 20180613
print( "###LUA ExViewHelper.lua" )
local ExViewHelper = class("ExViewHelper")

ExViewHelper.ExDictWJJ = require("util.ExDictWJJ"):getInstance():onCreate()

------------------------------------------------

function ExViewHelper:IsSpecial(_key)
	--print( "###LUA ExViewHelper.lua IsSpecial key: " .. tostring(_key) )

	if(tostring(_key) == "Common/UserInfo.csb") then
		do return true end
	end

	return false
end

function ExViewHelper:IsExistInHistory(_key)
	return self.ExDictWJJ:IsExist(_key)
end

function ExViewHelper:AddHistory(_key, _val)
	self.ExDictWJJ:Add(_key, _val)
	self.ExDictWJJ:DebugLog()
end

------------------------------------------------

function ExViewHelper:getInstance()
	--print( "###LUA ExViewHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExViewHelper:onCreate()
	--print( "###LUA ExViewHelper.lua onCreate" )

	self.ExDictWJJ:onCreate()

	return self.instance
end

print( "###LUA Return ExViewHelper.lua" )
return ExViewHelper