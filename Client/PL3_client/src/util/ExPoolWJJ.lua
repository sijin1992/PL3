-- Coded by Wei Jingjun 20180612
print( "###LUA ExPoolWJJ.lua" )
local ExPoolWJJ = class("ExPoolWJJ")

ExPoolWJJ.config = require("util.ExConfig"):getInstance()
ExPoolWJJ.memoryTools = require("util.ExMemoryTools"):getInstance()
ExPoolWJJ.preloadList = require("util.ExPreloadList")

ExPoolWJJ.pool = {}
ExPoolWJJ.pool_note = {}

ExPoolWJJ.IS_RETAIN = true
ExPoolWJJ.IS_DEBUG_LOG_VERBOSE = false	
ExPoolWJJ.IS_DEBUG_LOG_MEOMORY = false

------------------------------------------------

ExPoolWJJ.IS_DEBUG_LOG_VERBOSE_LOCAL = false

function ExPoolWJJ:_print(_log)
	if( self.IS_DEBUG_LOG_VERBOSE_LOCAL ) then
		print(_log)
	end
end

function ExPoolWJJ:DebugLog()
	local _self = ExPoolWJJ.instance
	if( _self.IS_DEBUG_LOG_VERBOSE == false ) then
		do return end
	end

	self:_print( "###LUA ExPoolWJJ: DebugLog BEGIN ########################")

	for k,v in pairs(_self.pool) do
		self:_print( "###LUA ExPoolWJJ: DebugLog [ " .. tostring(k) .. " ] = " )
		if( v == nil ) then
			self:_print( "###LUA ExPoolWJJ: DebugLog nil v " )
			else
			self:_print( "###LUA ExPoolWJJ: DebugLog v:getName " .. tostring(v:getName())  .. " REF_COUNT: " .. tostring(v:getReferenceCount())  )
		end
	end

	self:_print( "###LUA ExPoolWJJ: DebugLog END ########################")
end

function ExPoolWJJ:IsKeyGood(_key)
	if( (_key == nil) or (_key == "") ) then
		return false
	end
	return true
end

function ExPoolWJJ:HasKey(_key)
	self:_print( "###LUA ExPoolWJJ:HasKey : " .. ( tostring(_key) or " nil " ) )

	if( self:IsKeyGood(_key) == false ) then
		return false
	end

	if( self.pool == nil ) then
		return false
	end

	for k,v in pairs(self.pool) do
		if ( k == _key) then
			do return true end
		end
	end

	return false
end

function ExPoolWJJ:GetValueAtKey(_key)
	self:_print( "###LUA ExPoolWJJ:GetValueAtKey : " .. ( tostring(_key) or " nil " ) )

	if( self:IsKeyGood(_key) == false ) then
		return nil
	end

	if( self:HasKey(_key) == false ) then
		do return nil end
	end

	local val = self.pool[_key]

	return val
end

function ExPoolWJJ:TryLoadCache(path)
	self:_print( "###LUA ExPoolWJJ.TryLoadCache " .. ( tostring(path) or " nil " ))

	local isHasKey = self:HasKey(path)
	if ( isHasKey ) then
		self:_print( "###LUA ExResCachePool.OnLoadAtPath_CSB ALREADY EXSISTS")
		local existNode = self:GetValueAtKey(path)
		if ( existNode ~= nil ) then
			self:_print( "###LUA ExResCachePool.TryLoadCache existNode is OK, NOT NEED LOAD")
			return existNode
		end
	end

	return nil
end

function ExPoolWJJ:TryAdd(_key, _val, _is_retain)
	self:_print( "###LUA ExPoolWJJ.TryAdd "  )
	local _self = ExPoolWJJ.instance

	if( _self:IsKeyGood(_key) == false ) then
		_self:_print( "###LUA ExPoolWJJ.TryAdd key bad "  )
		return false
	end

	if( _val == nil ) then
		_self:_print( "###LUA ExPoolWJJ.TryAdd _val bad "  )
		return false
	end

	if( _self:HasKey(_key) ) then
		_self:_print( "###LUA ExPoolWJJ.TryAdd REPLACED " .. tostring(_key) )
		_self:RemoveKey(_key)
		_self.pool[_key] = _val
		do return true end
	end

	_self:_print( "###LUA ExPoolWJJ.TryAdd NEW " .. tostring(_key) )
	--[[
	local kvpair = {}
	kvpair[_key] = _val
	table.insert(_self.pool, kvpair)
	--]]

	_self.pool[_key] = _val

	if(_self.IS_DEBUG_LOG_MEOMORY) then
		_self:_print("#### LUA ExPoolWJJ 96 _val:getName() : " .. tostring(_val:getName()))
		_self:_print("#### LUA ExPoolWJJ 96 _val:getReferenceCount() : " .. tostring(_val:getReferenceCount()))
	end

	if( _is_retain ) then
	if ( _self.IS_RETAIN ) then
			_self.memoryTools:ExRetain(_val)
	end

	else
		_self:_print("#### LUA ExPoolWJJ 144 no retain! refcount: " .. tostring(_val:getReferenceCount()))
	end

	if(_self.IS_DEBUG_LOG_MEOMORY) then
		_self:_print("#### LUA ExPoolWJJ retain _val:getReferenceCount() : " .. tostring(_val:getReferenceCount()))
	end

	_self:DebugLog()

	return true
end

function ExPoolWJJ:RemoveKey(_key)
	self:_print( "###LUA ExPoolWJJ.RemoveKey: " .. tostring( _key or " NIL" ) )
	self:_print( "###LUA OLD length = " .. tostring( table.nums(self.pool) ) )

	local v = self.pool[_key]
	self.memoryTools:ResetReferenceCount(v)

	self.pool[_key] = nil
	self:_print( "###LUA NEW length = " .. tostring( table.nums(self.pool) ) )
end

function ExPoolWJJ:ResetPoolWithoutKey(_key)
	self:_print( "###LUA ExPoolWJJ.ResetPoolWithoutKey: " .. tostring( _key or " NIL" ) )

	local newPool = {}

	local _val = self.pool[_key]
	self:_print( "###LUA _val name = " .. tostring( _val:getName() ) )

	local _n = 0
	for _k,_v in pairs(self.pool) do
		self:_print( "###LUA finding... _n = " .. tostring( _n ) )
		self:_print( "###LUA finding... key:  " .. tostring( _k ) )

		if(_k == _key) then
			self:_print( "###LUA found, _n = " .. tostring( _n ) )
		else
			newPool[_k] = _v
		end
		_n = _n + 1
	end


	self:_print( "###LUA n = " .. tostring( _n ) )
	self:_print( "###LUA newPool length = " .. tostring( table.nums(newPool) ) )

	--[[
	for i = 1, table.nums(self.pool) do
		local last = table.nums(self.pool)
		self:_print( "###LUA remove last = " .. tostring( last ) )
		self.pool = table.remove(self.pool)
	end


	self:_print( "###LUA CLEARED OLD POOL! length = " .. tostring( table.nums(self.pool) ) )
	]]

	for _k2,_v2 in pairs(newPool) do
		self:TryAdd(_k2,_v2)
	end
	self:_print( "###LUA REBUILD OLD POOL! length = " .. tostring( table.nums(self.pool) ) )
	-- return newPool
end

function ExPoolWJJ:TryDelete(_key)
	self:_print( "###LUA ExPoolWJJ.TryDelete: " .. tostring( _key or " NIL" ) )
	local _self = ExPoolWJJ.instance
	local _val = _self.pool[_key]
	if( _val == nil ) then
		self:_print( "###LUA ExPoolWJJ.TryDelete: NIL, not need delete" )
		do return false end
	end
	
	--[[
	self:_print( "###LUA ref count = " .. tostring(  _val:getReferenceCount()  ) )
	_val:retain()
	_val:retain()
	_val:retain()
	]]

	--[[
	if( _pos == false ) then
		self:_print( "###LUA ExPoolWJJ.TryDelete not exsist " )
		do return end
	end
	]]

--[[
	local _pos = self:IndexOf(_key)

	if( _pos < 1 ) then
		self:_print( "###LUA ExPoolWJJ.TryDelete _pos ERROR "  )
		do return false end
	end
]]

	-- self:_print( "###LUA ExPoolWJJ.TryDelete at _pos : " .. tostring(_pos) )

	self:RemoveKey(_key)
	-- self:ResetPoolWithoutKey(_key)

	return true
end

------------------------------------------------

function ExPoolWJJ:GetPoolNote(_key, _note)
	return self.pool_note[_key]
end

function ExPoolWJJ:AddPoolNote(_key, _note)
	self.pool_note[_key] = _note
end

function ExPoolWJJ:IsFileDelay(_path, _delay_time)

	local _self = ExPoolWJJ.instance


	local is_delay_enabled = false
	for _k, _v in pairs(self.preloadList.DELAY_RELOAD_LIST) do
		if( is_delay_enabled == false ) then
			is_delay_enabled = _v == _path
			-- _self:_print(string.format(" _v: %s  \n _path : %s",_v,_path))
		end
	end

	if( is_delay_enabled == false ) then
		do return false end
	end

	_self:_print(string.format("@@@@ IsFileDelay %s",_path))

	if( _delay_time == nil ) then
		_delay_time = _self.config.DELAY_RELOAD_TIME
	end

	local now = os.time()
	local _beganTime = _self:GetPoolNote(_path)
	if( _beganTime ~= nil ) then
		local targetDelayTime = tonumber(_beganTime) + _delay_time
		local isDelay = now < targetDelayTime
		_self:_print( "###LUA now : " .. tostring(now) )
		_self:_print( "###LUA _beganTime : " .. tostring(_beganTime) )
		_self:_print( "###LUA targetDelayTime : " .. tostring(targetDelayTime) )
		if ( isDelay == true ) then
			_self:_print( "###LUA isDelayed : " .. tostring(isDelay) )
			do return true end
		end
	else
		_self:_print( "@@@LUA _beganTime : NIL" )
	end

	_self:_print( "###LUA IsFileDelay false " .. tostring(now) )
	return false
end

function ExPoolWJJ:IsFileLocked(_path, _lock_time, _is_force_clear)
	-- lock async loading file, do not load a file at once
	local _self = ExPoolWJJ.instance
	_self:_print( string.format("~~~~~ IsFileLocked : _path: %s  _lock_time: %s" , tostring(_path), tostring(_lock_time) ) )
	_self:_print( string.format("~~~~~ cc.exports.G_IsCachePoolLocked : %s  " , tostring(cc.exports.G_IsCachePoolLocked) ) )

	if( _is_force_clear == nil ) then
		_is_force_clear = false
	end

	if( _is_force_clear ) then
		_self:_print( string.format("~~~~~ _is_force_clear : %s  " , tostring(_is_force_clear) ) )
		return false
	end

	if( cc.exports.G_IsCachePoolLocked ) then
		return true
	end



	if( _lock_time == nil ) then
		_lock_time = _self.config.ASYNC_LOAD_DEFAULT_TIME
	end

	local now = os.clock()
	local _beganTime = _self:GetPoolNote(_path)
	if( _beganTime ~= nil ) then
		local targetFininshTime = tonumber(_beganTime) + _lock_time
		local isFinished = now >= targetFininshTime
		_self:_print( "###LUA isFinished : " .. tostring(isFinished) )
		_self:_print( "###LUA now : " .. tostring(now) )
		_self:_print( "###LUA targetFininshTime : " .. tostring(targetFininshTime) )
		if ( isFinished == false ) then
			do return true end
		end
	end

	_self:_print( "###LUA IsFileLocked false " .. tostring(now) )
	return false
end

------------------------------------------------


function ExPoolWJJ:OnRelease()
	self:_print("@@@ ExPoolWJJ OnRelease")

	local strategy = require("util.ExMemoryStrategy"):getInstance()
	if( strategy:IsMemReleaseEnabled() == false  ) then
		self:_print("**** ExPoolWJJ OnRelease : disabled, not now"  )
		do return end
	end

	local deleted_list = {}
	for k,v in pairs(self.pool) do
		local is_locked = self:IsFileLocked(k, self.config.ASYNC_LOAD_DEFAULT_TIME, true)
		if ( is_locked == false) then
			table.insert(deleted_list, k)
			self.memoryTools:ResetReferenceCount(v)
		else
			self:_print("@@@ ExPoolWJJ OnRelease is_locked ! " .. tostring(k))
		end
	end

	self:DebugLog()

	for k,v in ipairs(deleted_list) do
		self.pool[v] = nil
	end

	self:DebugLog()
end



function ExPoolWJJ:getInstance()
	self:_print( "###LUA ExPoolWJJ.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end



function ExPoolWJJ:onCreate()
	self:_print( "###LUA ExPoolWJJ.lua onCreate" )

	self.pool = {}
	self.pool_note = {}
	return self
end

print( "###LUA Return ExPoolWJJ.lua" )
return ExPoolWJJ	