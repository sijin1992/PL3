-- Coded by Wei Jingjun 20180710
print( "###LUA ExPreclonePool.lua" )
local ExPreclonePool = class("ExPreclonePool")
ExPreclonePool.pool = {}
ExPreclonePool.config = require("util.ExConfig"):getInstance()
ExPreclonePool.base = require("util.ExPoolAnimWJJ"):getInstance()

ExPreclonePool.IS_DEBUG_LOG_VERBOSE = false
function ExPreclonePool:_print(_log)
	if( self.IS_DEBUG_LOG_VERBOSE ) then
		print(_log)
	end
end

------------------------------------------------
function ExPreclonePool:purge()
	self:_print( "\n***** ExPreclonePool purge  !  \n\n " )
	self.base:purge(self.pool)
end

function ExPreclonePool:RemoveKey(_key)
	self.base:RemoveKey(_key, self.pool)
end

function ExPreclonePool:TryLoadCache(path)
	self:_print( "\n***** ExPreclonePool TryLoadCache >>>>>>>>>>>>>>>>>>>>>> \n\n " )
	local obj_anim = self.base:TryLoadCache(path, self.pool)

	if (obj_anim ~= nil) then
		self:_print( string.format("\n***** ExPreclonePool TryLoadCache OK ! name: %s \n\n ", tostring(path)) )
		-- obj_anim:retain()
		self:_print( "***** OLD length = " .. tostring( table.nums(self.pool) ) )
		self:RemoveKey(path)
		self:_print( "***** NEW length = " .. tostring( table.nums(self.pool) ) )
		-- self.base:purgeOne(obj_anim)
		-- obj_anim:retain()
		self:_print( string.format("\n***** obj_anim ref count : %s \n\n ", tostring(obj_anim:getReferenceCount())) )
	end
	
	return obj_anim
end

function ExPreclonePool:OnPreclone(_view, _list, _i_began)

	local i = _i_began or 0
	for _k, _v in pairs(_list) do

		if( cc.exports.G_IsCachePoolLocked ) then
			return
		end

		local now = os.clock()
		self:_print( string.format("\n***** ExPreclonePool OnPreclone ! name: %s now: %s \n\n ", tostring(_v), tostring(now)) )
		if( _view ~= nil ) then
			local delay = self.config.DELAY_TO_PRELOAD + i * self.config.INTERVAL_PER_PRELOAD
			_view:runAction(cc.Sequence:create(cc.DelayTime:create(delay), cc.CallFunc:create(function ( ... )

				if( cc.exports.G_IsCachePoolLocked ) then
					return
				end

				local loader = require("app.ExResPreloader"):getInstance()
				local now = os.clock()
				local _self = require("util.ExPreclonePool"):getInstance()
				_self:_print( string.format("\n***** ExPreclonePool OnPreclone DELAYED name: %s now: %s \n\n ", tostring(_v), tostring(now)) )
				local obj_anim = loader:CacheLoadTimeline(_v, true, false)
				if ( (_self.pool == nil) or (obj_anim == nil) ) then
					_self:_print( string.format("\n***** _self.pool or obj_anim nil at: %s \n\n ", tostring(i)) )
				else
					_self.base:TryAdd(_v, obj_anim, _self.pool ) 
				end
			end)))
		else
			local loader = require("app.ExResPreloader"):getInstance()
			local obj_anim = loader:CacheLoadTimeline(_v, true, false)
			if ( (self.pool ~= nil) and (obj_anim ~= nil) ) then
				self.base:TryAdd(_v, obj_anim, self.pool ) 
			else
				self:_print( string.format("\n***** NO VIEW MODE : _self.pool or obj_anim nil at: %s \n\n ", tostring(i)) )
			end
		end
		i = i + 1
	end
end



------------------------------------------------

function ExPreclonePool:getInstance()
	print( "###LUA ExPreclonePool.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExPreclonePool:onCreate()
	print( "###LUA ExPreclonePool.lua onCreate" )

	self.base:purge(self.pool)

	return self.instance
end

print( "###LUA Return ExPreclonePool.lua" )
return ExPreclonePool