-- Coded by Wei Jingjun 20180612
print( "###LUA ExResCachePool.lua" )
local ExResCachePool = class("ExResCachePool")

ExResCachePool.exFileUtil_Lua = require("util.ExFileUtil_Lua"):getInstance()

ExResCachePool.resCachePool = require("util.ExPoolWJJ"):getInstance()
ExResCachePool.resCachePool_Anim = require("util.ExPoolAnimWJJ"):getInstance()

ExResCachePool.asyncLoadTimer = require("util.ExAsyncLoadTimer"):getInstance()

ExResCachePool.IS_RETAIN = false

ExResCachePool.IS_DEBUG_LOG_LOCAL = false

function ExResCachePool:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

-----------------------------------------------------------------------------

function ExResCachePool:DebugMemoryAnim()
	for k,v in pairs(self.resCachePool_Anim.pool) do
		self:_print("###LUA resCachePool_Anim:DebugMemory: k = " .. tostring(k) )
		if ( v ~= nil ) then
			local count = v:getReferenceCount()
			self:_print("###LUA ExResCachePool:DebugMemory: ref count = " .. tostring(count) )
		else
			self:_print("###LUA ExResCachePool:DebugMemory: v =  nil "  )
		end

	end
end
function ExResCachePool:DebugMemoryNode()
	for k,v in pairs(self.resCachePool.pool) do
		self:_print("###LUA ExResCachePool:DebugMemory: k = " .. tostring(k) )
		if ( v ~= nil ) then
			local name = v:getName()
			local count = v:getReferenceCount()
			self:_print("###LUA ExResCachePool:DebugMemory: v name = " .. tostring(name) .. ", ref count = " .. tostring(count) )
		else
			self:_print("###LUA ExResCachePool:DebugMemory: v =  nil "  )
		end

	end
end

function ExResCachePool:DebugMemory()
	self:DebugMemoryNode()
	self:DebugMemoryAnim()
end

-----------------------------------------------------------------------------

function ExResCachePool:TryGet_Anim(_path)
	local val = self.resCachePool_Anim:GetValueAtKey(_path)
	return val
end

function ExResCachePool:TryGet(_path)
	local val = self.resCachePool:GetValueAtKey(_path)
	return val
end

function ExResCachePool:TryAddToPool_Anim(_path, _anim)
	local _self = ExResCachePool.instance
	_self:_print( "###LUA ExResCachePool.TryAddToPool_Anim "  )
	_self:_print( "###LUA  _path: " .. ( tostring(_path) or " nil " ) )



	local isAddOK = _self.resCachePool_Anim:TryAdd(_path, _anim)

	if( isAddOK and _self.IS_RETAIN  ) then
		self:_print("####  before referenceCount: " .. tostring(_anim:getReferenceCount()))
		_anim:retain()
		_anim:retain()
		_anim:retain()
		self:_print("####  after referenceCount: " .. tostring(_anim:getReferenceCount()))
	end
end

function ExResCachePool:TryAddToPool(_path, _node, _is_retain)
	local _self = ExResCachePool.instance
	_self:_print( "###LUA ExResCachePool.TryAddToPool "  )
	_self:_print( "###LUA  _node: " .. ( tostring(_node:getName()) or " nil " ) )
	_self:_print( "###LUA  _path: " .. ( tostring(_path) or " nil " ) )

	if( _is_retain == nil ) then
		_is_retain = true
	end

	local isAddOK = _self.resCachePool:TryAdd(_path, _node, _is_retain)

	if( isAddOK and _self.IS_RETAIN  ) then
		_self:_print("#### NODE : " .. tostring(_node:getName()))
		_self:_print("#### NODE before referenceCount: " .. tostring(_node:getReferenceCount()))
		_node:retain()
		_node:retain()
		_node:retain()
		_self:_print("#### NODE after referenceCount: " .. tostring(_node:getReferenceCount()))
	end
end

function ExResCachePool:Replace_NodePool(_path, _node)
	local _self = ExResCachePool.instance
	_self.resCachePool:TryDelete(_path)
	_self:TryAddToPool(_path, _node)
end

------------------------------------------------------------------------

function ExResCachePool:OnAnimLoaded(_path, _anim)
	if( (_path == nil) or (_path == "") ) then
		self:_print( "###LUA ExResCachePool.OnAnimLoaded _path BAD ")
		do return end
	end

	
	local isPathGood = self.exFileUtil_Lua:OnCheckAtPath_CSB(_path)
	if( isPathGood == false ) then
		self:_print( "###LUA ExResCachePool.OnAnimLoaded isPathGood BAD ")
		do return end
	end
	

	if( _anim == nil ) then
		self:_print( "###LUA ExResCachePool.OnAnimLoaded _anim BAD ")
		do return end
	end

	self:_print( "###LUA ExResCachePool.OnAnimLoaded _path: " .. ( tostring(_path) or " nil " ) )

	self:TryAddToPool_Anim(_path, _anim)
end

function ExResCachePool:OnNodeLoaded(_path, _node, _is_retain)

	if( (_path == nil) or (_path == "") ) then
		self:_print( "###LUA ExResCachePool.OnNodeLoaded _path BAD ")
		do return end
	end

	
	local isPathGood = self.exFileUtil_Lua:OnCheckAtPath_CSB(_path)
	if( isPathGood == false ) then
		self:_print( "###LUA ExResCachePool.OnNodeLoaded isPathGood BAD ")
		do return end
	end
	

	if( _node == nil ) then
		self:_print( "###LUA ExResCachePool.OnNodeLoaded _node BAD ")
		do return end
	end

	self:_print( "###LUA ExResCachePool.OnNodeLoaded _node: " .. ( tostring(_node:getName()) or " nil " ) )
	self:_print( "###LUA ExResCachePool.OnNodeLoaded _path: " .. ( tostring(_path) or " nil " ) )

	if( _is_retain == nil ) then
		_is_retain = true
	end

	self:TryAddToPool(_path, _node, _is_retain)

end

function ExResCachePool:OnLoadAtPath_CSB_Anim(path)
	self:_print( "###LUA ExResCachePool.OnLoadAtPath_CSB_Anim ")

	local exsitAnim = self.resCachePool_Anim:TryLoadCache(path)
	if( exsitAnim ~= nil ) then
		self:_print( "###LUA OnLoadAtPath_CSB_Anim TryLoadCache exsitAnim OK")
		do return exsitAnim end
	end

	local loadedAnim = self.exFileUtil_Lua:OnLoadAtPath_CSB_Anim(path)
	self:OnAnimLoaded(path, loadedAnim)
	return loadedAnim
end

function ExResCachePool:OnLoadAtPath_CSB(path, _isUseNow, _is_retain)
	self:_print( "###LUA ExResCachePool.OnLoadAtPath_CSB ")
	local exsit = self.resCachePool:TryLoadCache(path)
	if( exsit ~= nil ) then
		return exsit
	end
	-- try async, or ref count bug! 20180709 wjj
	local loadedNode = self.exFileUtil_Lua:OnLoadAtPath_CSB(path, true)

	local isAdd = false

	if(  _isUseNow == nil ) then
		isAdd = false
	else
		isAdd = _isUseNow == false
	end

	if(  isAdd  ) then
		if( _is_retain == nil ) then
			_is_retain = true
		end
		self:OnNodeLoaded(path, loadedNode, _is_retain)
	else
		self:_print("###LUA _isUseNow true, do not add to pool!")
	end

	self:_print( "###LUA isAdd " .. tostring(isAdd))

	return loadedNode
end



------------------------------------------------

function ExResCachePool:OnRelease()
	self.resCachePool:OnRelease()
end

------------------------------------------------

function ExResCachePool:getInstance()
--	self:_print( "###LUA ExResCachePool.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExResCachePool:onCreate()
	self:_print( "###LUA ExResCachePool.lua onCreate" )

	self.resCachePool:onCreate()
	self.asyncLoadTimer:onCreate(self.instance)

	return self
end

print( "###LUA Return ExResCachePool.lua" )
return ExResCachePool