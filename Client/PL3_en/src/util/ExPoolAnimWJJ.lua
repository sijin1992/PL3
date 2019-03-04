-- Coded by Wei Jingjun 20180612
print( "###LUA ExPoolAnimWJJ.lua" )
local ExPoolAnimWJJ = class("ExPoolAnimWJJ")

ExPoolAnimWJJ.pool = {}
ExPoolAnimWJJ.IS_RETAIN = true
ExPoolAnimWJJ.IS_DEBUG_LOG_VERBOSE = false

ExPoolAnimWJJ.memoryTools = require("util.ExMemoryTools"):getInstance()

------------------------------------------------

function ExPoolAnimWJJ:_print(_log)
	if( self.IS_DEBUG_LOG_VERBOSE ) then
		print(_log)
	end
end

function ExPoolAnimWJJ:DebugLog(_pool)
	if( _pool == nil ) then
		_pool = self.pool
	end

	if( self.IS_DEBUG_LOG_VERBOSE == false ) then
		do return end
	end

	self:_print( "###LUA ExPoolAnimWJJ: DebugLog BEGIN ########################")

	for k,v in pairs(_pool) do
		self:_print( "###LUA ExPoolAnimWJJ: DebugLog [ " .. tostring(k) .. " ] = " )
		if( v == nil ) then
			self:_print( "###LUA ExPoolAnimWJJ: DebugLog nil v " )
			else
			self:_print( "###LUA ExPoolAnimWJJ: DebugLog " .. " REF_COUNT: " .. tostring(v:getReferenceCount())  )
		end
	end

	self:_print( "###LUA ExPoolAnimWJJ: DebugLog END ########################")
end

function ExPoolAnimWJJ:IsKeyGood(_key)
	if( (_key == nil) or (_key == "") ) then
		return false
	end
	return true
end

function ExPoolAnimWJJ:HasKey(_key, _pool)
	if( _pool == nil ) then
		_pool = self.pool
	end

	self:_print( "###LUA ExPoolAnimWJJ:HasKey : " .. ( tostring(_key) or " nil " ) )

	if( self:IsKeyGood(_key) == false ) then
		return false
	end

	if( _pool == nil ) then
		return false
	end

	for k,v in pairs(_pool) do
		if ( k == _key) then
			do return true end
		end
	end

	return false
end

function ExPoolAnimWJJ:GetValueAtKey(_key, _pool)
	if( _pool == nil ) then
		_pool = self.pool
	end

	self:_print( "###LUA ExPoolAnimWJJ:GetValueAtKey : " .. ( tostring(_key) or " nil " ) )

	if( self:IsKeyGood(_key) == false ) then
		return nil
	end

	if( self:HasKey(_key, _pool) == false ) then
		do return nil end
	end

	local val = _pool[_key]

	return val
end

function ExPoolAnimWJJ:TryLoadCache(path, _pool)
	if( _pool == nil ) then
		_pool = self.pool
	end

	self:_print( "###LUA ExPoolAnimWJJ.TryLoadCache " .. ( tostring(path) or " nil " ))
	local isHasKey = self:HasKey(path, _pool)
	if ( isHasKey ) then
		self:_print( "###LUA ExPoolAnimWJJ ALREADY EXSISTS")
		local existVal = self:GetValueAtKey(path, _pool)
		if ( existVal ~= nil ) then
			self:_print( "###LUA ExPoolAnimWJJ  existVal is OK, NOT NEED LOAD")
			return existVal
		end
	end
	return nil
end

function ExPoolAnimWJJ:TryAdd(_key, _val, _pool)
	if( _pool == nil ) then
		_pool = self.pool
	end

	self:_print( "###LUA ExPoolAnimWJJ.TryAdd "  )
	if( self:IsKeyGood(_key) == false ) then
		self:_print( "###LUA ExPoolAnimWJJ.TryAdd key bad "  )
		return false
	end

	if( _val == nil ) then
		self:_print( "###LUA ExPoolAnimWJJ.TryAdd _val bad "  )
		return false
	end

	-- prevent autorelease?
	-- _val:retain()

	if( self:HasKey(_key, _pool) ) then
		self:_print( "###LUA ExPoolAnimWJJ.TryAdd REPLACED " .. tostring(_key) )

		do return true end
		--[[
		local old = _pool[_key]
		-- _val:release()

		-- _pool[_key] = _val

		self:purgeOne(old)
		]]
	end

	self:_print( "###LUA ExPoolAnimWJJ.TryAdd NEW " .. tostring(_key) )

	_pool[_key] = _val

	if(self.IS_DEBUG_LOG_VERBOSE) then
		self:_print("#### LUA ExPoolAnimWJJ 96 _val:getReferenceCount() : " .. tostring(_val:getReferenceCount()))
	end

	if ( self.IS_RETAIN ) then
		self.memoryTools:ExRetain(_val)
	end

	self:DebugLog(_pool)

	return true
end

------------------------------------------------

function ExPoolAnimWJJ:purgeOne(v)
	self.memoryTools:ReleaseActionTimeline(v, 3, false, 1, true, true)
end

function ExPoolAnimWJJ:RemoveKey(_key, _pool)
	if( _pool == nil ) then
		_pool = self.pool
	end

	self:_print( "###LUA ExPoolAnimWJJ.RemoveKey: " .. tostring( _key or " NIL" ) )
	self:_print( "###LUA OLD length = " .. tostring( table.nums(_pool) ) )

	local v = _pool[_key]
	self:purgeOne(v)

	_pool[_key] = nil
	self:_print( "###LUA NEW length = " .. tostring( table.nums(_pool) ) )
end

function ExPoolAnimWJJ:purge(_pool)
	if( _pool == nil ) then
		_pool = self.pool
	end

	if(self.memoryTools.strategy:IsMemReleaseEnabled() == false) then
		do return end
	end

	-- all ref count = 1 , not need release???

	for k,v in pairs(_pool) do
		if( v == nil ) then

		else
			self:purgeOne(v)
		end
	end

	self:DebugLog(_pool)

	for k,v in pairs(_pool) do
		_pool[k] = nil
	end

	self:DebugLog(_pool)
end

------------------------------------------------

function ExPoolAnimWJJ:getInstance()
	self:_print( "###LUA ExPoolAnimWJJ.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExPoolAnimWJJ:Init()
	
end

function ExPoolAnimWJJ:onCreate()
	self:_print( "###LUA ExPoolAnimWJJ.lua onCreate" )

	-- self.pool = {}
	self:purge()

	return self
end

print( "###LUA Return ExPoolAnimWJJ.lua" )
return ExPoolAnimWJJ