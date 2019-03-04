print( "###LUA ExMemoryTools.lua" )
-- Coded by Wei Jingjun 20180625
local ExMemoryTools = class("ExMemoryTools")

ExMemoryTools.IS_TEST_MEMORY_BUG = false

ExMemoryTools.IS_DEBUG_LOG_LOCAL = false

function ExMemoryTools:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

------------------------------------------------

ExMemoryTools.config = require("util.ExConfig"):getInstance()
ExMemoryTools.strategy = require("util.ExMemoryStrategy"):getInstance()
ExMemoryTools.directorHelper = require("util.ExDirectorHelper"):getInstance()

ExMemoryTools.lastReleaseMemoryTime = -1
ExMemoryTools.RELEASE_TIME_MIN = 3
------------------------------------------------



function ExMemoryTools:DebugCachedTexture(_comment)
	if( self.IS_DEBUG_LOG_LOCAL == true ) then
		self:_print(string.format(" **** ExMemoryTools DebugCachedTexture %s BEGIN >>>>>>>>>>>>>>>>>> " , tostring( _comment or " NIL" ) ) )
		self:_print(cc.Director:getInstance():getTextureCache():getCachedTextureInfo())
		self:_print(string.format(" **** ExMemoryTools DebugCachedTexture %s Description >>>>>>>>>>>>>>>>>> " , tostring( _comment or " NIL" ) ) )
		self:_print(cc.Director:getInstance():getTextureCache():getDescription())
		self:_print(string.format(" **** ExMemoryTools DebugCachedTexture %s END >>>>>>>>>>>>>>>>>> " , tostring( _comment or " NIL" ) ) )
	end
end

function ExMemoryTools:DebugViewCache(_v, _comment)
	if( self.IS_DEBUG_LOG_LOCAL == false ) then
		return
	end

	self:_print("***** ExMemoryTools:DebugViewCache : " .. tostring( _comment or " NIL _comment >>>>>>>>>>>" ))

	if( _v == nil ) then
		self:_print("***** ExMemoryTools:DebugViewCache : NIL")
		do return end
	end

	self:_print("***** ExMemoryTools:DebugViewCache : " .. tostring(_v or " NIL"))
	self:_print("*****  type: " .. tostring(type(_v) or " NIL"))
	local _t  = tostring(type(_v))
	if( _t == "table" ) then
		for a,b in pairs(_v) do
			self:_print("***** a: " .. tostring(a or " NIL"))
			self:_print("***** b: " .. tostring(b or " NIL"))

			if( a == "_view" ) then
				-- self:_print("***** b name: " .. tostring(b:getName() or " NIL"))
				-- self:_print("***** b ref count: " .. tostring(b:getReferenceCount()))
			end
		end

	elseif( _t == "userdata" ) then 
		self:_print("***** ExMemoryTools:DebugViewCache name: " .. tostring(_v:getName() or " NIL"))
		self:_print("***** ExMemoryTools:DebugViewCache ref count: " .. tostring(_v:getReferenceCount()))
	end


end

-----------------------------------------------------------


function ExMemoryTools:IsOpenGLView(_val)
	local director = cc.Director:getInstance()
	local view = director:getOpenGLView()
	return (view ~= nil)
end

function ExMemoryTools:ExRetain(_val)
	for _i = 1, 3 do
		_val:retain()
	end
end

function ExMemoryTools:PurgeCache(is_empty_scene, is_pause_director)

	local time_began = os.clock()
	self:_print(string.format("___ ExMemoryTools PurgeCache ! now: %s", tostring(time_began)))
	local time_min = (self.lastReleaseMemoryTime + self.RELEASE_TIME_MIN)
	if( time_began < time_min ) then
		self:_print(string.format("_____ DO NOT ExMemoryTools PurgeCache ! time_min: %s", tostring(time_min)))
		do return end
	end

	if( self.strategy:IsMemReleaseEnabled() == false ) then
		self:_print("**** ExMemoryTools PurgeCache : disabled, not now"  )
		do return end
	end

	if( is_pause_director == nil ) then
		is_pause_director = true
	end

	if ( is_pause_director ) then
		self.directorHelper:Pause()
	end

	local time_began = os.clock()
	require("util.ExPoolAnimWJJ"):getInstance():purge()
	require("util.ExPreclonePool"):getInstance():purge()
	self:_print("**** ExMemoryTools PurgeCache 112 "  )
	ccs.ActionTimelineCache:getInstance():purge()
	self:_print("**** ExMemoryTools PurgeCache 114 "  )
	cc.Director:getInstance():purgeCachedData()

	if( is_empty_scene == nil ) then
		is_empty_scene = false
	end
	self:_print("**** ExMemoryTools PurgeCache 120 is_empty_scene:  " .. tostring(is_empty_scene)  )
	if( is_empty_scene ) then
		if( self:IsOpenGLView() == false ) then
			_self:_print("____ NOT OnReleaseOnce getOpenGLView nil  now: " .. tostring(os.clock()))
			do return end
		end
		self:_print("**** ExMemoryTools PurgeCache 126 "  )
		-- cc.Director:getInstance():getTextureCache():waitForQuit()

		require("app.ExMemoryInterface"):getInstance():OnEnableAnimationReleaseAsync()
		require("app.ExMemoryInterface"):getInstance():OnEnableMemoryReleaseAsync()
		self:_print("**** ExMemoryTools PurgeCache 131 "  )
		-- cc.SpriteFrameCache:getInstance():removeSpriteFrames()
		-- cc.Director:getInstance():getTextureCache():removeAllTextures()

		-- self:DebugCachedTexture("*** TEST UpdateScene removeAllTextures")

		self:_print("**** ExMemoryTools PurgeCache 137 is_empty_scene END "  )
	end

	if ( is_pause_director ) then
		self.directorHelper:Resume()
	end

	self:_print("**** ExMemoryTools PurgeCache 142 ALL FINININSHED "  )

--[[
	self:DebugCachedTexture(string.format("*** ExMemoryTools PurgeCache BEGIN time: %s ************************", tostring(time_began) ) )
	-- for i = 1, 3000 do
	-- cc.Director:getInstance():getTextureCache():removeUnusedTextures()
	-- end

	cc.Director:getInstance():purgeCachedData()

	local time_end = os.clock()
	self:DebugCachedTexture(string.format("*** ExMemoryTools PurgeCache END time: %s ************************", tostring(time_end ) ) )
]]
	-- self:_print(string.format("*** used time: %s ************************", tostring(time_end - time_began ) ) )
end

function ExMemoryTools:IsNodeExistAtSceneOrParent(_node)
	local s = _node:getScene()
	local p = _node:getParent()

	local is_s = s ~= nil
	local is_p = p ~= nil

	if ( is_s ) then
		self:_print( "@@@ IsNodeExistAtSceneOrParent Scene: " .. tostring(s:getName()) )
		self:_print( "@@@ IsNodeExistAtSceneOrParent Scene Tag: " .. tostring(s:getTag()) )
	end

	if ( is_p ) then
		self:_print( "@@@ IsNodeExistAtSceneOrParent Parent: " .. tostring(p:getName()) )
	end


	self:_print( string.format("@@@ has scene : %s ,  has parent : %s" , tostring(is_s), tostring(is_p) ) )
	return is_s, is_p
end

function ExMemoryTools:ReleaseActionTimeline(_node, count, _is_release_child, _min, _is_stop_action, _is_release)
	if( _node == nil ) then
		self:_print( "______ ExMemoryTools ReleaseActionTimeline 184 err node == nil "  )
		do return end
	end

	if( count == nil ) then
		count = self.config.RES_REF_COUNT_NORMAL
	end

	if( _is_stop_action == nil ) then
		_is_stop_action = false
	end

	if( _is_release == nil ) then
		_is_release = true
	end

	if( _min == nil ) then
		_min = 1
	end

	local _ref_count = _node:getReferenceCount()

	if( _is_release ) then
		for i=1,count do
			local _ref_count = _node:getReferenceCount()
			self:_print( string.format("___ ReleaseActionTimeline ref count: %s", tostring(_ref_count) ) )
			if( _ref_count > _min ) then
				_node:release()
				self:_print( "___ ReleaseActionTimeline RELEASE! node ref count: " .. tostring(_node:getReferenceCount()) )
			end
		end
	end

	local _node_type = tostring(type(_node))
	self:_print( "***** _node_type: " .. tostring(_node_type) )

end

function ExMemoryTools:ReferenceCountToRelease(_node, count, _is_release_child, _min, _is_stop_action, _is_release)
	if( count == nil ) then
		count = self.config.RES_REF_COUNT_NORMAL
	end

	if( _is_stop_action == nil ) then
		_is_stop_action = true
	end

	if( _is_release == nil ) then
		_is_release = true
	end

	if( _min == nil ) then
		_min = 1
	end

	local _ref_count = _node:getReferenceCount()
	if( (_ref_count == 2) and (self.IS_TEST_MEMORY_BUG) ) then
		self:_print( string.format("\n\n@@@ ref > 1 ? node <%s> ref count: %s \n\n", _node:getName(), tostring(_ref_count) ) )
	end

	if( (_ref_count == 3) and (self.IS_TEST_MEMORY_BUG) ) then
		self:_print( string.format("\n\n@@@ ref > 2 ? node <%s> ref count: %s \n\n", _node:getName(), tostring(_ref_count) ) )
	end

	if( _is_release ) then
		for i=1,count do
			local _ref_count = _node:getReferenceCount()
			self:_print( string.format("@@@ node <%s> ref count: %s", _node:getName(), tostring(_ref_count) ) )
			if( _ref_count > _min ) then
				_node:release()
				self:_print( "@@@ RELEASE! node ref count: " .. tostring(_node:getReferenceCount()) )
			end
		end
	end

	local _node_type = tostring(type(_node))
	self:_print( "***** _node_type: " .. tostring(_node_type) )

	local _act_num = _node:getNumberOfRunningActions()
	self:_print( "***** NumberOfRunningActions: " .. tostring(_act_num) )
	if( _is_stop_action and (_act_num > 0 ) ) then
		self:_print( "***** stopAllAction ")
 
		_node:stopAllActions()
		_node:cleanup()
	end

	if( _is_release_child == nil ) then
		_is_release_child = false
	end

	if( _is_release_child ) then
		local child_count = _node:getChildrenCount()
		self:_print( string.format("***** node< %s > ", _node:getName() )  ) 
		self:_print( "***** _is_release_child ChildrenCount: " .. tostring(child_count) )
		if( child_count <= 0 ) then
			do return end
		end
		local child_array = _node:getChildren()
		for _k,_v in ipairs(child_array) do
			self:_print( string.format("***** node< %s > :  [%s] = %s", _node:getName() , _k, tostring(_v:getName() )  ) )
			self:ReferenceCountToRelease(_v, count, true, _min, _is_stop_action, _is_release)
		end
	end
end

function ExMemoryTools:ReleaseAllChildren(_scene, _release_times , _is_release_child , _min, _is_not_scene, _is_stop_action, _is_release )

	if( _is_not_scene == nil ) then
		_is_not_scene = false
	end

	if( _is_not_scene == false ) then
		self:_print( "***** _scene ReleaseAllChildren! \ndescription: " .. tostring(_scene:getDescription()) )
		self:_print( "***** _scene NumberOfRunningActions: " .. tostring(_scene:getNumberOfRunningActions()) )
		self:_print( "***** _scene ChildrenCount: " .. tostring(_scene:getChildrenCount()) )
	end

	if( _is_release_child == nil ) then
		_is_release_child = false
	end

	if( _min == nil ) then
		_min = 1
	end

	if( _release_times == nil ) then
		_release_times = self.config.RES_REF_COUNT_NORMAL
	end

	self:ReferenceCountToRelease(_scene, _release_times, _is_release_child, _min, _is_stop_action, _is_release)

	-- pause
	-- _scene:unscheduleAllCallbacks()
	-- _scene:unscheduleAllSelectors()
	-- _scene:removeAllComponents()
end

function ExMemoryTools:ResetReferenceCount(_node)
	local name = _node:getName()
	self:_print( "@@@ LUA ExMemoryTools.lua ResetReferenceCount node name: " .. tostring(name) )
	local count = _node:getReferenceCount()
	self:_print( "@@@  node ref count: " .. tostring(count) )

	local has_scene, has_parent = self:IsNodeExistAtSceneOrParent(_node)

	if( (has_scene ) or ( has_parent  ) ) then
		self:_print( "@@@ DO NOT RELEASE! has_scene has_parent" )
		do return false end
	end

	--[[
	local ref_normal = self.config.RES_REF_COUNT_NORMAL
	local ref_now = _node:getReferenceCount()
	if( ref_now > ref_normal ) then
		self:_print( string.format("@@@ DO NOT RELEASE! node: %s ref count: %s", name, tostring(ref_now) ) )
		do return false end
	end
	]]


	self:ReferenceCountToRelease(_node, count, false, 1, true, true)

end

function ExMemoryTools:OnSceneChanged(_scene)
	self:_print(" **** ExMemoryTools OnSceneChanged " .. (tostring(_scene) or "nil") )

	self:DebugViewCache(_scene, " OnSceneChanged")

	self:DebugCachedTexture()

	-- self:ReleaseAllChildren(_scene)
	self:ReleaseAllChildren(_scene, self.config.RES_REF_COUNT_NORMAL, true, 1,false,  true, false)
end

------------------------------------------------

function ExMemoryTools:getInstance()
	print( "###LUA ExMemoryTools.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExMemoryTools:onCreate()
	print( "###LUA ExMemoryHelper.lua onCreate" )

	return self
end

print( "###LUA Return ExMemoryTools.lua" )
return ExMemoryTools