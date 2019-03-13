-- Coded by Wei Jingjun 20180615
print( "###LUA ExAsyncLoadTimer.lua" )
local ExAsyncLoadTimer = class("ExAsyncLoadTimer")
ExAsyncLoadTimer.taskScheduler_single = require("util.ExSchedulerHelper")
ExAsyncLoadTimer.taskScheduler = {}
ExAsyncLoadTimer.fileUtil = require("util.ExFileUtil_Lua"):getInstance()
ExAsyncLoadTimer.pool_instance = {}

ExAsyncLoadTimer.config = require("util.ExConfig"):getInstance()

ExAsyncLoadTimer.preloadData = require("util.ExPreloadList")
------------------------------------------------


ExAsyncLoadTimer.UPDATE_INTERVAL = 0.001
ExAsyncLoadTimer.TIMER_CYCLE_MAX = 9999

ExAsyncLoadTimer.IS_DEBUG_LOG_VERBOSE = false

------------------------------------------------

ExAsyncLoadTimer.asyncLoadQueue = {}
ExAsyncLoadTimer.E_ASYNC_LOAD_STATE = {}
ExAsyncLoadTimer.E_ASYNC_LOAD_STATE.NONE = -1
ExAsyncLoadTimer.E_ASYNC_LOAD_STATE.WAITING = 0
ExAsyncLoadTimer.E_ASYNC_LOAD_STATE.LOADING = 1
ExAsyncLoadTimer.E_ASYNC_LOAD_STATE.FININSHED = 2

------------------------------------------------

ExAsyncLoadTimer.pauseEndTime = -1
ExAsyncLoadTimer.TIME_PAUSE = 1
ExAsyncLoadTimer.DELAY_MEMORY_RELEASE = 9
ExAsyncLoadTimer.lastSceneChangeEndTime = -1

------------------------------------------------

function ExAsyncLoadTimer:_print(_log)
	if( self.IS_DEBUG_LOG_VERBOSE ) then
		print(_log)
	end
end

function ExAsyncLoadTimer:IsPaused()
	if( cc.exports.G_IsCachePoolLocked ) then
		return true
	end

	-- self:_print(string.format("os.time() : %s   self.pauseEndTime : %s ", tostring(os.time()), tostring(self.pauseEndTime)))
	return (os.time() <= self.pauseEndTime)
end

function ExAsyncLoadTimer:Pause()
	self.pauseEndTime = os.time() + self.TIME_PAUSE
end

function ExAsyncLoadTimer:IsAsyncLoadTask(_path, _state)
	local task = self.asyncLoadQueue[_path]
	if( task == nil ) then
		local isNone = _state == self.E_ASYNC_LOAD_STATE.NONE
		self:_print( "###LUA IsAsyncLoadTask isNone " .. tostring(self.E_ASYNC_LOAD_STATE.NONE) .. " == " .. tostring(_state))
		do return isNone end
	end
	
	self:_print( "###LUA IsAsyncLoadTask task: " .. tostring(_path))
	self:_print( "###LUA IsAsyncLoadTask state: " .. tostring(task["state"]))
	local isState = task["state"] == _state
	do return isState end
end

function ExAsyncLoadTimer:AddAsyncLoadTask(_path, _isAsync, reload_callback)
	self:_print(" AddAsyncLoadTask BEGIN >>>>>>>>>>>>>>>>>>>>>>>>>>>> ")
	self:_print( "###LUA ExAsyncLoadTimer:AddAsyncLoadTask " .. tostring( _path or " NIL " ))

	if( cc.exports.G_IsCachePoolLocked ) then
		self:_print( "###LUA ExAsyncLoadTimer:AddAsyncLoadTask G_IsCachePoolLocked !!")
		return false
	end

	local isTaskNone = self:IsAsyncLoadTask(_path, self.E_ASYNC_LOAD_STATE.NONE)
	if( isTaskNone == false) then
		local isPrevTaskFininshed = self:IsAsyncLoadTask(_path, self.E_ASYNC_LOAD_STATE.FININSHED)
		if( isPrevTaskFininshed == false ) then
			self:_print( "###LUA ExAsyncLoadTimer:AddAsyncLoadTask FAIlED isPrevTaskFininshed false  ")
			do return false end
		end
	end
	local _data =  { 
		["path"] = _path
		,["isAsync"] = _isAsync
		,["reload_callback"] = reload_callback
		,["state"] = self.E_ASYNC_LOAD_STATE.WAITING
	 }

	self:_print(" _data : ")
	for _k, _v in pairs(_data) do
		self:_print(" _k:" .. tostring(_k))
		self:_print(" _v:" .. tostring(_v))
	end

	self.asyncLoadQueue[_path] = _data

	

	self:_print(" AddAsyncLoadTask END >>>>>>>>>>>>>>>>>>>>>>>>>>>> ")
end

------------------------------------------------------------------------

function ExAsyncLoadTimer:IsReloadDisabled(_path)

	-- local is_disabled = false
	local is_disabled = true

	if( cc.exports.G_IsCachePoolLocked ) then
		return true
	end

	local list = {
		[1] = self.preloadData.DELAY_RELOAD_LIST
		, [2] = self.preloadData.LIST_BATTLE
	}

	-- WJJ 20180702 do not reload main city assets. lag
	for _k2, _v2 in ipairs(list) do
	for _k, _v in pairs(_v2) do
		self:_print(string.format(" @@@ IsReloadDisabled %s == %s ", _path, _v))
		if( _path == _v ) then
			do return true end
		end
	end
	end

	if( self.config.IS_RELOAD_DISABLED_BY_LIST == false ) then
		do return false end
	end

	for _k, _v in pairs(self.preloadData.PRELOAD_LIST) do
		if( _path == _v ) then
			do return false end
		end
	end

	return is_disabled
end

function ExAsyncLoadTimer:IsFileLocked(_path)
	-- lock async loading file, do not load a file at once
	local _self = ExAsyncLoadTimer.instance
	return _self:getPool():IsFileLocked(_path, _self.config.ASYNC_LOAD_DEFAULT_TIME)
end

function ExAsyncLoadTimer:OnAsyncLoadBegin(_path)
	self:_print( "###LUA ExAsyncLoadTimer.OnAsyncLoadBegin ")

	-- lock async loading file, do not load a file at once
	if ( self:IsFileLocked(_path) ) then
		do return false end
	end

	local begin_time = os.clock()
	self:_print( "###LUA _path = " .. tostring(_path) )
	self:_print( "###LUA begin_time = " .. begin_time )
	self:getPool():AddPoolNote(_path, begin_time)
	return true
end

-- used by ExResPreloader:Reload
function ExAsyncLoadTimer:OnReload_CSB(_path, _isAsync, _isForceReload)
	self:_print( "###LUA ExAsyncLoadTimer.OnReload_CSB ")

	-- ADD WJJ 20180709
	if( cc.exports.G_IsCachePoolLocked or (self.config.isMainGameSceneEntered == false) ) then
		do return false end
	end

	if( _isForceReload == nil ) then
		_isForceReload = false
	end

	local is_disabled = self:IsReloadDisabled(_path)

	if( is_disabled and ( _isForceReload == false )) then
		self:_print( string.format("###LUA OnReload_CSB file IsReloadDisabled true : %s", _path))
		do return false end
	end

	local isNotLocked = self:OnAsyncLoadBegin(_path)
	if( isNotLocked == false ) then
		self:_print( "###LUA OnReload_CSB file locked !")
		do return false end
	end

	-- do async load here

	local reload_callback = function(_loadedNode) 
		if( _loadedNode == nil ) then
			self:_print( "###LUA ExAsyncLoadTimer.OnReload_CSB ASYNC NIL ")
			do return end
		end

		self:_print( "###LUA                                                         " )
		self:_print( "###LUA ExAsyncLoadTimer.OnReload_CSB ASYNC _loadedNode OK" )
		self:_print( "###LUA getName: " .. tostring(_loadedNode:getName()) )
		self:_print( "###LUA ref count: " .. tostring(_loadedNode:getReferenceCount()) )
		self:_print( "###LUA time now: " .. tostring(os.time()) )
		self:_print( "###LUA time now clock: " .. tostring(os.clock()) )
		self:_print( "###LUA time target fininsh: " .. tostring(os.time() + self.config.ASYNC_LOAD_DEFAULT_TIME) )
		self:_print( "###LUA                                                         " )
	end

	self:AddAsyncLoadTask(_path, _isAsync, reload_callback)

	-- local loadedNode = self.exFileUtil_Lua:OnLoadAtPath_CSB(_path, _isAsync, reload_callback)

	-- self:Replace_NodePool(_path, loadedNode)

	self:_print( "###LUA                                                   ")
	self:_print( "###LUA ExResCachePool.OnReload_CSB END")
	self:_print( "###LUA                                                   ")

	-- return loadedNode
end

------------------------------------------------

function ExAsyncLoadTimer:OnTaskStateChange(_file, _nextState)
	self:_print("#LUA                                          ")
	self:_print("#LUA ExAsyncLoadTimer OnTaskStateChange >>>>> ")
	self:_print("#LUA _file: " ..tostring(_file) )
	self:_print("#LUA _nextState: " ..tostring(_nextState) )

	local _self = ExAsyncLoadTimer.instance

	local _data = _self.asyncLoadQueue[_file]

	if( _data == nil ) then
		self:_print("###LUA EXCEPTION: _data NIL")
		do return end
	end

	self:_print("###LUA _data old state: " .. tostring(_data["state"]))
	_data["state"] = _nextState
	_self.asyncLoadQueue[_file] = _data

	self:_print("#LUA                                          ")
end

-----------------------------------------------------------------------------

function ExAsyncLoadTimer:OnTask_LOADING(_data)
	self:_print("#LUA                                          ")
	self:_print("#LUA ExAsyncLoadTimer OnTask_LOADING >>>>> ")

	if(  _data == nil ) then
		self:_print("###LUA EXCEPTION: _data NIL")
		do return end
	end
	local _self = ExAsyncLoadTimer.instance
	local _file = _data["path"]

	if(  _file == nil ) then
		self:_print("###LUA EXCEPTION: _file NIL")
		do return end
	end

	if ( _self:IsFileLocked(_file) ) then
		do return false end
	end

	_self:OnTaskStateChange(_file, _self.E_ASYNC_LOAD_STATE.FININSHED)
	self:_print("#LUA AsyncLoad FININSHED !! _file: " .. tostring(_file))


	self:_print("#LUA                                          ")
	return false
end

function ExAsyncLoadTimer:OnTask_WAITING(_data)
	self:_print("#LUA ExAsyncLoadTimer OnTask_WAITING >>>>> time: " .. tostring(os.time()))
	self:_print("#LUA found task in waiting ")
	local _self = ExAsyncLoadTimer.instance

	local _file = _data["path"]
	if ( _self:getPool():IsFileDelay(_file) ) then
		do return true end
	end


	local loadedNode = _self.fileUtil:OnLoadAtPath_CSB( _file, _data["isAsync"], _data["reload_callback"] )

	_self:OnTaskStateChange(_file, _self.E_ASYNC_LOAD_STATE.LOADING)
	self:_print("#### LUA  ExAsyncLoadTimer:OnTask_WAITING before Replace_NodePool " .. tostring(_file))
	_self.pool_instance:Replace_NodePool(_file, loadedNode)
	self:_print("#### LUA  ExAsyncLoadTimer:OnTask_WAITING AFTER Replace_NodePool")

	return true
end

function ExAsyncLoadTimer:OnTaskData(_data)
	local _self = ExAsyncLoadTimer.instance
	local _isSkip = false

	if( _data["state"] == _self.E_ASYNC_LOAD_STATE.WAITING ) then
		_isSkip = _self:OnTask_WAITING(_data)
	elseif( _data["state"] == _self.E_ASYNC_LOAD_STATE.LOADING ) then
		_isSkip = _self:OnTask_LOADING(_data)
	end

	do return _isSkip end
end

function ExAsyncLoadTimer:OnCheckTask()
	local _self = ExAsyncLoadTimer.instance
	local _isSkip = false
	-- self:_print("#LUA  OnCheckTask BEGIN                                         ")

	local is_paused = self:IsPaused()
	if( is_paused ) then
		_isSkip = true
		self:_print("@@@LUA  OnCheckTask PAUSED!! RETURN ")
		do return _isSkip end
	end

	for _file, _data in pairs(_self.asyncLoadQueue) do
		_isSkip = _self:OnTaskData(_data)
		if( _isSkip ) then
			self:_print("###LUA  OnCheckTask skip! at " .. tostring(_file) )
			self:_print("###LUA  state now: " .. tostring(_data["state"]) )
			self:_print("###LUA  time now: " .. tostring(os.time()) )
			do return _isSkip end
		end
	end
	-- self:_print("#LUA  OnCheckTask END                                          ")
	do return _isSkip end
end


function ExAsyncLoadTimer:ResetLastSceneChangeEndTime()
	self.lastSceneChangeEndTime = -1
end

function ExAsyncLoadTimer:OnCheckMemoryRelease()

	-- self:_print( string.format("_____ cc.exports.G_IsCachePoolLocked: %s  lastSceneChangeEndTime : %s   self.config.isMainGameSceneEntered : %s ", tostring(cc.exports.G_IsCachePoolLocked), tostring(self.lastSceneChangeEndTime), tostring(self.config.isMainGameSceneEntered) ) )

	-- do not release too early!
	if( cc.exports.G_IsCachePoolLocked or (self.config.isMainGameSceneEntered == false) ) then
		do return end
	end

	if( self.lastSceneChangeEndTime < 0 ) then
		do return end
	end
	local diff = os.time() - self.lastSceneChangeEndTime
	self:_print( "***** diff: " .. tostring(diff) )
	if( diff < self.DELAY_MEMORY_RELEASE  ) then
		do return end
	end

	self:ResetLastSceneChangeEndTime()

	self:_print( "\n***** LUA PurgeCache !  ExAsyncLoadTimer OnCheckMemoryRelease\n\n" )

	require("util.GlobalLoading"):getInstance():retainLoading()

	local memoryTools = require("util.ExMemoryTools"):getInstance()
	memoryTools:PurgeCache()

	require("util.GlobalLoading"):getInstance():releaseLoading()
end

function ExAsyncLoadTimer:IsInDisabledList(_name)
	-- do not preload too early
	if(  cc.exports.G_IsCachePoolLocked or (self.config.isMainGameSceneEntered == false) ) then
		do return true end
	end

	-- WJJ 20180702 do not reload main city assets. lag
	for _k, _v in pairs(self.preloadData.IN_GAME_DISABLE_PRELOAD_LIST) do
		self:_print(string.format(" @@@ IsInDisabledList %s == %s ", _name, _v))
		if( _name == _v ) then
			do return true end
		end
	end
	return false
end

function ExAsyncLoadTimer:OnPreload(_name, _view)
	local _isAsync = true
	local is_not = self:IsInDisabledList(_name) == true

	if( is_not ) then
		self:_print( string.format("\n***** OnPreload DO NOT OnPreload ! _name: %s \n\n ", tostring(_name)) )
		do return false end
	end

	local i = 0
	for _k, _v in pairs(self.preloadData.DELAY_RELOAD_LIST) do
		local now = os.clock()
		self:_print( string.format("\n***** ExAsyncLoadTimer OnPreload ! name: %s now: %s \n\n ", tostring(_v), tostring(now)) )
		if( _view ~= nil ) then
			local delay = self.config.DELAY_TO_PRELOAD + i * self.config.INTERVAL_PER_PRELOAD
			_view:runAction(cc.Sequence:create(cc.DelayTime:create(delay), cc.CallFunc:create(function ( ... )
				local now = os.clock()
				local _self = require("util.ExAsyncLoadTimer"):getInstance()
				_self:_print( string.format("\n***** ExAsyncLoadTimer OnPreload DELAYED name: %s now: %s \n\n ", tostring(_v), tostring(now)) )
				_self:OnReload_CSB(_v, _isAsync , true)
			end)))
		else
			self:OnReload_CSB(_v, _isAsync , true)
		end
		i = i + 1
	end

	local precloner = require("util.ExPreclonePool"):getInstance()
	local list = self.preloadData.PRECLONE_LIST_ZHUCHENG
	precloner:OnPreclone(_view, list, i)

end

function ExAsyncLoadTimer:OnSetTime(_name)
	-- WJJ 20180702 do not reload main city assets. lag
	local is_not_release = self:IsInDisabledList(_name) == true

	if( is_not_release ) then
		self:_print( string.format("\n***** ExAsyncLoadTimer OnSceneChangeEnd DO NOT RELEASE ! _name: %s \n\n ", tostring(_name)) )
		self:ResetLastSceneChangeEndTime()
		do return false end
	end

	local now = os.time()
	self:_print( string.format("\n***** ExAsyncLoadTimer OnSceneChangeEnd ! now: %s \n\n ", tostring(now)) )
	self.lastSceneChangeEndTime = now
end

function ExAsyncLoadTimer:OnSceneChangeEnd(_scene, _name, _view)
	self:OnSetTime(_name)
	-- memory leak? wjj 20180709

	if( cc.exports.lastExitZhuchengTime ~= nil ) then
		local limit_time = (os.clock() - self.config.MIN_TIME_LIMIT_PRELOAD)

		self:_print( string.format("_____ limit_time: %s  lastExitZhuchengTime : ", tostring(limit_time), tostring(cc.exports.lastExitZhuchengTime) ) )

		if( cc.exports.lastExitZhuchengTime > limit_time ) then
			self:_print(string.format("~~~ cc.exports.lastExitZhuchengTime: %s ", tostring(cc.exports.lastExitZhuchengTime), tostring(limit_time) ) )
			self:OnPreload(_name, _view)
		end
	end
end

function ExAsyncLoadTimer:OnSchedulerUpdate()
	local _self = ExAsyncLoadTimer.instance
	if( _self.taskScheduler.ScheduleState ~= _self.taskScheduler.E_LOADING_STATE.RUNNING ) then
		self:_print( "###LUA    asyncLoadTimer NOT RUNNING !!  LoadingState: " .. ( tostring(_self.taskScheduler.ScheduleState) or " nil " ) )
		do return end
	end


	local _isSkip = _self:OnCheckTask()

	_self:OnCheckMemoryRelease()

			--[[
			_self:_print("###LUA                                              ")
			_self:_print("###LUA ExAsyncLoadTimer OnSchedulerUpdate END at " .. tostring(os.time()))
			_self:_print("###LUA                                              ")
			--]]
end

function ExAsyncLoadTimer:InitScheduler()
	self.taskScheduler = self.taskScheduler_single:new(self.taskScheduler, self.UPDATE_INTERVAL, 1, self.TIMER_CYCLE_MAX )
	-- MUST USE SCHEDULER, or not async

	-- callback on cycle count max
	self.taskScheduler:RegisterCallBack(function(_selfLoader)
			self:_print("###LUA                                              ")
			self:_print("###LUA AsyncLoad END at " .. tostring(os.time()))
			self:_print("###LUA                                              ")
		end)

	self.taskScheduler:OnBegin(self.OnSchedulerUpdate)

end

function ExAsyncLoadTimer:getPool()
	--[[
	if(self.pool_instance ~= nil) then
		self:_print( "###LUA getPool ok!" )
		do return self.pool_instance.resCachePool end
	end
	]]

	local _pool = require("app.ExResCachePool"):getInstance().resCachePool
	self:_print( "###LUA getPool require!" )
	return _pool
end

-----------------------------------------------------------------------------


function ExAsyncLoadTimer:getInstance()
	self:_print( "###LUA ExAsyncLoadTimer.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExAsyncLoadTimer:onCreate( _pool )
	self:_print( "###LUA ExAsyncLoadTimer.lua onCreate" )

	if( _pool == nil ) then
		self:_print( "###LUA _pool NIL!" )
		do return nil end
	end

	self.pool_instance = _pool
	self:_print( "###LUA pool_instance OK!" )

	self:InitScheduler()

	return self
end

ExAsyncLoadTimer:_print( "###LUA Return ExAsyncLoadTimer.lua" )
return ExAsyncLoadTimer