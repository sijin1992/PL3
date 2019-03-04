-- Coded by Wei Jingjun 20180613
print( "###LUA ExDictWJJ.lua" )
local ExDictWJJ = class("ExDictWJJ")

ExDictWJJ.dict = {}

ExDictWJJ.IS_DEBUG_LOG_VERBOSE = false

------------------------------------------------

function ExDictWJJ:DebugLog()
	if(self.IS_DEBUG_LOG_VERBOSE == false) then
		do return end
	end
	print("###LUA ExDictWJJ DebugLog START ######### " )
	for __k,__v in pairs(self.dict) do
		print("###LUA ExDictWJJ [ " .. tostring(__k) .. " ] = " .. tostring(__v) )
	end
	print("###LUA ExDictWJJ DebugLog END ######### " )
end

function ExDictWJJ:IsExist(_key)
	for __k,__v in pairs(self.dict) do
		if(__k == _key) then
			do return true end
		end
	end

	return false
end

function ExDictWJJ:Add(_key, _val)
	if(self:IsExist(_key)) then
		if(self.IS_DEBUG_LOG_VERBOSE) then
			print("###LUA ExDictWJJ Add _key EXIST!! REPLACE " )
		end
	end

	if( _val == nil ) then
		--print("###LUA ExDictWJJ Add val = NIL!!! ")
		--print("###LUA ExDictWJJ Add _key : " .. tostring(_key) )
		do return end
	end

	self.dict[_key] = _val
	--print("###LUA ExDictWJJ Add _key : " .. tostring(_key) )
	--print("###LUA ExDictWJJ Add _val : " .. tostring(_val) )
end

function ExDictWJJ:Clear()
	self.dict = {}
end

------------------------------------------------

function ExDictWJJ:getInstance()
	--print( "###LUA ExDictWJJ.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExDictWJJ:onCreate()
	--print( "###LUA ExDictWJJ.lua onCreate" )

	self:Clear()

	return self.instance
end

--print( "###LUA Return ExDictWJJ.lua" )
return ExDictWJJ