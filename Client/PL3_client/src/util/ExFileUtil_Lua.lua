-- Coded by Wei Jingjun 20180612
print( "###LUA ExFileUtil_Lua.lua" )
local ExFileUtil_Lua = class("ExFileUtil_Lua")

ExFileUtil_Lua.IS_RETAIN = false

ExFileUtil_Lua.IS_ASYNC = false

ExFileUtil_Lua.IS_DEBUG_LOG_LOCAL = false

function ExFileUtil_Lua:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

function ExFileUtil_Lua:GetDataFromFile(path)


end

function ExFileUtil_Lua:OnCheckAtPath_CSB(path)
	self:_print( "###LUA ExFileUtil_Lua.OnCheckAtPath_CSB path: " .. ( tostring(path) or " nil " ) )
	local isExist = true
	local _util = cc.FileUtils:getInstance();
	local fullPath = _util:fullPathForFilename(path)
	
	if( (fullPath == nil) or (fullPath == "") ) then
		do return false end
	end

	self:_print( "###LUA ExFileUtil_Lua.OnCheckAtPath_CSB fullPath: " .. ( tostring(fullPath) or " nil " ) )
	isExist = assert(_util:isFileExist(fullPath), "###LUA assert isFileExist " .. ( tostring(fullPath) or " nil " ))
	return isExist
end

function ExFileUtil_Lua:OnLoadAtPath_CSB_Anim(path)
	self:_print( "###LUA ExFileUtil_Lua.OnLoadAtPath_CSB_Anim: " .. ( tostring(path) or " nil " ) )

	if( self:OnCheckAtPath_CSB(path) == false ) then
		self:_print( " #### LUA OnCheckAtPath_CSB false  : " .. tostring(path) )
		do return nil end
	end

	local actionTimeLine = cc.CSLoader:createTimeline(path) --assert(cc.CSLoader:createTimeline(path), " #### LUA ASSERT CSLoader:createTimeline : " .. tostring(path) )

	if( actionTimeLine ~= nil ) then
		self:_print("#### actionTimeLine refCount : " .. tostring(actionTimeLine:getReferenceCount()))

		if( self.IS_RETAIN ) then
			actionTimeLine:retain()
			actionTimeLine:retain()
			actionTimeLine:retain()

			self:_print("#### actionTimeLine refCount RETAIN!! : " .. tostring(actionTimeLine:getReferenceCount()))
		end

	else
		self:_print("#### actionTimeLine NIL!! ")
	end

	return actionTimeLine
end

function ExFileUtil_Lua:OnLoadAtPath_CSB(path, _isAsync, _callback)
	self:_print( "###LUA ExFileUtil_Lua.OnLoadAtPath_CSB: " .. ( tostring(path) or " nil " ) )

	local csload_callback = function(arg1)
		self:_print("#### csload_callback os.clock: " .. tostring(os.clock()))
		self:_print("#### csload_callback path : " .. tostring(path))
		
		self:_print("#### csload_callback NODE : " .. tostring(arg1:getName()))
		if( self.IS_RETAIN ) then
			self:_print("#### NODE : " .. tostring(arg1:getName()))
			self:_print("#### NODE before referenceCount: " .. tostring(arg1:getReferenceCount()))
			arg1:retain()
			arg1:retain()
			arg1:retain()
			self:_print("#### NODE after referenceCount: " .. tostring(arg1:getReferenceCount()))
		end

	end

	if( self:OnCheckAtPath_CSB(path) == false ) then
		self:_print( " #### LUA OnCheckAtPath_CSB false  : " .. tostring(path) )
		do return nil end
	end

	local __async = self.IS_ASYNC
	if( _isAsync ~= nil ) then
		__async = _isAsync
	end

	if( __async ) then

		local __cb = csload_callback

		if( _callback ~= nil ) then
			__cb = _callback
		end

		local node = assert(cc.CSLoader:createNode(path, __cb), " #### LUA ASSERT CSLoader:createNode ASYNC : " .. tostring(path) .. "\n time: " .. tostring(os.time())  )

		self:_print("#### ExFileUtil_Lua OnLoadAtPath_CSB node ASYNC BEGIN : " .. tostring(node:getName()))

		return node

	end

		local node = assert(cc.CSLoader:createNode(path), " #### LUA ASSERT CSLoader:createNode OLD SYNC MODE: " .. tostring(path) )

		self:_print("#### createNode OLD SYNC MODE !! node : " .. tostring(node:getName()))

		return node

end


------------------------------------------------

function ExFileUtil_Lua:getInstance()
	self:_print( "###LUA ExFileUtil_Lua.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExFileUtil_Lua:Init()
	
end

function ExFileUtil_Lua:onCreate()
	self:_print( "###LUA ExFileUtil_Lua.lua onCreate" )

	self.resCachPool = {}

	return self
end

print( "###LUA Return ExFileUtil_Lua.lua" )
return ExFileUtil_Lua