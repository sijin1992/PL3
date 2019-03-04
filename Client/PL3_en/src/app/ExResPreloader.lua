print( "###LUA ExResPreloader.lua" )
-- Coded by Wei Jingjun 20180612
local ExResPreloader = class("ExResPreloader")

ExResPreloader.IS_DEBUG_LOG_VERBOSE_LOCAL = false

function ExResPreloader:_print(_log)
	if( self.IS_DEBUG_LOG_VERBOSE_LOCAL ) then
		print(_log)
	end
end

ExResPreloader.exPreloadList = require("util.ExPreloadList")
ExResPreloader.memoryTools = require("util.ExMemoryTools"):getInstance()
ExResPreloader.imageLoader = require("util.ExImageLoader"):getInstance()
ExResPreloader.config = require("util.ExConfig"):getInstance()



--------------------------------------------------------------------------------

ExResPreloader.ex_res_preload_count_max = 50
ExResPreloader.ex_res_preload_count_loaded = -1

-- do not too fast, or memory leak? WJJ 180709
-- ExResPreloader.UPDATE_INTERVAL = 0.033 * 3
ExResPreloader.UPDATE_INTERVAL = 0.013
ExResPreloader.PER_FRAME_FILES_LOAD_AMOUNT = 10
-- 0.033 71s on load time


--------------------------------------------------------------------------------

ExResPreloader.exSchedulerHelper_single = require("util.ExSchedulerHelper")
ExResPreloader.exSchedulerHelper = {}
ExResPreloader.exResCachePool = require("app.ExResCachePool"):getInstance()
ExResPreloader.exFileUtil_Lua = require("util.ExFileUtil_Lua"):getInstance()

-- ExResPreloader.scheduler = {}
-- ExResPreloader.schedulerEntry = -1
ExResPreloader.schedulerCallbackOnFininsh = {}

------------------------------------------------
function ExResPreloader:DebugMemory()
	self:_print( "###LUA ExResPreloader:DebugMemory BEGIN BEGIN BEGIN #######################" )
	self.exResCachePool:DebugMemory()
	self:_print( "###LUA DebugMemory:DebugLog END END END #######################" )
end

function ExResPreloader:DebugLog()
	self:_print( "###LUA ExResPreloader:DebugLog BEGIN BEGIN BEGIN #######################" )
	local ccTexCache = cc.Director:getInstance():getTextureCache()
	local des = ccTexCache:getDescription()
	self:_print( "###LUA des: " .. tostring(des) )
--[[
	self:_print( "###LUA SpriteFrameCache BEGIN BEGIN BEGIN #######################" )
	local ccSprCache = cc.SpriteFrameCache:getInstance()
	self:_print( "###LUA ccSprCache: " .. tostring(ccSprCache) )
	self:_print( "###LUA SpriteFrameCache END END END #######################" )

	self:_print( "###LUA AnimationCache BEGIN BEGIN BEGIN #######################" )
	local ccAniCache = cc.AnimationCache:getInstance()
	self:_print( "###LUA ccAniCache: " .. tostring(ccAniCache) )
	self:_print( "###LUA AnimationCache END END END #######################" )
--]]
	self:_print( "###LUA ExResPreloader:DebugLog END END END #######################" )
end


------------------------------------------------

function ExResPreloader:IsPlatformWindows()
	-- test
	-- return false
	return device.platform == "windows"
end

------------------------------------------------

function ExResPreloader:LoadAnim(animPath)
	self:_print( "###LUA ExResPreloader load animPath: " .. ( tostring(animPath) or " nil " ) )

	local isPathGood = self.exFileUtil_Lua:OnCheckAtPath_CSB(animPath)
	if( isPathGood == false ) then
		self:_print( "###LUA ExResPreloader.LoadAnim isPathGood BAD ")
		do return nil end
	end

	local _self = ExResPreloader
	local anim = _self.exResCachePool:OnLoadAtPath_CSB_Anim(animPath)
	return anim
end

function ExResPreloader:Load(filePath, _isUseNow, is_retain)
	self:_print( "###LUA ExResPreloader load file: " .. ( tostring(filePath) or " nil " ) )

	local isPathGood = self.exFileUtil_Lua:OnCheckAtPath_CSB(filePath)
	if( isPathGood == false ) then
		self:_print( "###LUA ExResPreloader.Load isPathGood BAD ")
		do return nil end
	end

	local _self = ExResPreloader

	if( is_retain == nil ) then
		is_retain = true
	end

	local node = _self.exResCachePool:OnLoadAtPath_CSB(filePath, _isUseNow, is_retain)
	return node
end

------------------------------------------------
--[[
function ExResPreloader:IsAnimCloneNeeded(_path)
	
	local list = self.exPreloadList.ANIM_CLONE_LIST
	for k,v in pairs(list) do
		self:_print( "###LUA ExResPreloader.lua IsAnimCloneNeeded v: " .. tostring(v) )
		self:_print( "###LUA ExResPreloader.lua IsAnimCloneNeeded _path: " .. tostring(_path) )
		if( v == _path ) then
			self:_print( "###LUA ExResPreloader.lua IsAnimCloneNeeded true" )
			do return true end
		end
	end

	return false
end
]]
------------------------------------------------

function ExResPreloader:CacheLoadTimeline(_path, _isUseNow, _is_use_preclone)
	self:_print( "###LUA ExResPreloader.lua CacheLoadTimeline 145 "  .. ( tostring(_path) or " nil " )  )

	if( cc.exports.G_IsCachePoolLocked ) then
		return cc.CSLoader:createTimeline(_path)
	end

	if( _is_use_preclone == nil ) then
		_is_use_preclone = true
	end

	if ( _is_use_preclone ) then
		local precloner = require("util.ExPreclonePool"):getInstance()
		local obj_anim = precloner:TryLoadCache(_path)
		if ( obj_anim ~= nil ) then
			self:_print( "###LUA ExResPreloader.lua CacheLoadTimeline 137 use_preclone " )
			return obj_anim
		else
			self:_print( "###LUA use_preclone failed" )
		end
	end

	local val = self.exResCachePool:TryGet_Anim(_path)

	if( val == nil ) then
		self:_print( "###LUA ExResPreloader.lua CacheLoadTimeline 148 TryGet_Anim FAILED, try load and add to cache " )
		local val_2nd = self:LoadAnim(_path)
		if( val_2nd == nil ) then
			self:_print( "###LUA ExResPreloader.lua CacheLoadTimeline 151 FAILED FINALLY, try OLD load mode " )
			val_3nd = cc.CSLoader:createTimeline(_path)
			val = val_3nd
		else
			val = val_2nd
		end


		-- self:_print("### LUA new Anim : ref Count: " .. (tostring(val:getReferenceCount()) or " nil " )  )
		-- self:_print( "###LUA CacheLoadTimeline RETURN load new " )
		-- do return val end
		-- AWALYS CLONE , or bug

	else
		self:_print( "###LUA CacheLoadTimeline TryGet_Anim OK " )
	end
	
	if( val == nil ) then
		self:_print("### LUA Anim : NIL !!!" )
		do return nil end
	end
	
	self:_print("### LUA exsitAnim ref Count: " .. (tostring(val:getReferenceCount()) or " nil " ) )

	-- if( self:IsAnimCloneNeeded(_path) ) then

	local isClone = false

	if(  _isUseNow == nil ) then
		isClone = true
	else
		isClone = _isUseNow
	end

	local cloneAnim = val
	if(  isClone ) then
		cloneAnim = val:clone()
	end

	if( cloneAnim ~= nil ) then
		local ref_count = cloneAnim:getReferenceCount()
		self:_print("### LUA cloneAnim : ref Count: " .. (tostring(ref_count) or " nil " )  )
		-- if( ref_count  )

		self.exResCachePool.resCachePool_Anim:purgeOne(cloneAnim)

		local ref_count_purge = cloneAnim:getReferenceCount()
		self:_print("### LUA cloneAnim : ref Count purged: " .. (tostring(ref_count_purge) or " nil " )  )

		self:_print( "###LUA ExResPreloader.lua CacheLoadTimeline OPTIMIZED! CLONE from cache ! CLONE !" )
	else
		self:_print("### LUA cloneAnim : NIL !!!" )
	end

	return cloneAnim

	-- end
	-- AWALYS CLONE , or bug
	-- self:_print( "###LUA ExResPreloader.lua CacheLoadTimeline OPTIMIZED! load from cache  NOT CLONE" )
	-- return val
end

function ExResPreloader:Reload(_path, _isAsync)
	self:_print( "@@@@LUA ExResPreloader.lua Reload "  .. ( tostring(_path) or " nil " )  )

	if( cc.exports.G_IsCachePoolLocked == false ) then
		self.exResCachePool.asyncLoadTimer:OnReload_CSB(_path, _isAsync)
	end
end

function ExResPreloader:PauseReloader()
	self.exResCachePool.asyncLoadTimer:Pause()
end

function ExResPreloader:CacheLoad(_path, _isUseNow)
	self:_print( "###LUA ExResPreloader.lua CacheLoad 85 "  .. ( tostring(_path) or " nil " )  )

	-- do return cc.CSLoader:createNode(_path) end

	-- maybe file in async loading, do not use now
	if ( cc.exports.G_IsCachePoolLocked or self.exResCachePool.asyncLoadTimer:IsFileLocked(_path) ) then
		-- load file in safe mode
		self:_print( "###LUA OLD SAFE LOAD  " )
		local _safeVal = cc.CSLoader:createNode(_path)
		-- self.memoryTools:ResetReferenceCount(_safeVal)
		do return _safeVal end
	end

	local old_safe_loaded_res = {}
	local is_use_old_safe_loaded_res = false
	local val = self.exResCachePool:TryGet(_path)

	local isExsist =  false

	if( val == nil ) then
		self:_print( "###LUA ExResPreloader.lua CacheLoad 94 TryGet FAILED, try load and add to cache " )
		val = self:Load(_path, _isUseNow)
		if( val == nil ) then
			self:_print( "###LUA ExResPreloader.lua CacheLoad 97 FAILED FINALLY, try OLD load mode " )
			val = cc.CSLoader:createNode(_path)
		end
	else
		self.exResCachePool.resCachePool:TryDelete(_path)
		local ref_count = val:getReferenceCount()
		self:_print( string.format("@@@LUA CacheLoad ref_count: %s   RES_REF_COUNT_NORMAL: %s ", tostring(ref_count), tostring(self.config.RES_REF_COUNT_NORMAL) ) )

		local is_s, is_p = self.memoryTools:IsNodeExistAtSceneOrParent(val)
		isExsist =  is_s or is_p

		local is_not_use_cache = isExsist or (ref_count > self.config.RES_REF_COUNT_NORMAL )

		if( is_not_use_cache ) then
			self:_print( "###LUA cached res ref count ERROR, delete this, try OLD load mode again " )
			self.exResCachePool.resCachePool:TryDelete(_path)
			old_safe_loaded_res = cc.CSLoader:createNode(_path)
			val = old_safe_loaded_res
			is_use_old_safe_loaded_res = true
			
			if( old_safe_loaded_res ~= nil ) then
				local ref_count = old_safe_loaded_res:getReferenceCount()
				self:_print( "###LUA old_safe_loaded_res OK! ref count: " .. tostring(ref_count) )
			end
			
		else
			self:_print( "###LUA 175 use cache res!")
		end
	end

	local is_not_nil = (val ~= nil)
	if( is_use_old_safe_loaded_res ) then
		is_not_nil = old_safe_loaded_res ~= nil
	end

	local isReload = false
	if( is_not_nil ) then
		-- need clone!
		-- replace new loaded instance with old used instance
		-- true : async is laggy!



		if(  _isUseNow == nil ) then
			isReload = true
		else
			isReload = _isUseNow
		end
		self:_print( "@@@@LUA isReload: " .. tostring(isReload) )
		if(  isReload  ) then
			self:Reload( _path, true )
		end
	else
		self:_print( "###LUA ExResPreloader.lua CacheLoad FAILED!" )
		do return nil end
	end

	self:_print( string.format(  "@@@@LUA CacheLoad is_not_nil: %s   isReload: %s   _isUseNow: %s", tostring(is_not_nil), tostring(isReload), tostring(_isUseNow) ) )

	--[[
	local is_s, is_p = self.memoryTools:IsNodeExistAtSceneOrParent(val)
	local isExsist =  is_s or is_p
	]]

	local isBug = is_not_nil and (isReload == false) and _isUseNow

	if( isBug or isExsist or is_use_old_safe_loaded_res ) then
		self:_print( string.format("@@@@LUA CacheLoad isBug!! TryDelete: %s", tostring(_path) ) )
		self.exResCachePool.resCachePool:TryDelete(_path)
	end

	self:_print( "###LUA ExResPreloader.lua CacheLoad OPTIMIZED! load from cache END >>>>>>>>>>>>>>>>>>" )

	if( is_use_old_safe_loaded_res ) then
		-- self.memoryTools:ResetReferenceCount(old_safe_loaded_res)
		do return old_safe_loaded_res end
	end

	self.memoryTools:ResetReferenceCount(val)
	return val
end

------------------------------------------------

function ExResPreloader:InitScheduler()
	self.ex_res_preload_count_loaded = 1
	-- self.ex_res_preload_count_max = table.getn(self.exPreloadList)

	-- do not load much images on mobile phone! 1.5G memory need
	-- if(  device.platform == "windows" ) then
	if(  self:IsPlatformWindows() ) then
		self.ex_res_preload_count_max = tonumber(self.exPreloadList.PRELOAD_AMOUNT_MAX)
	else
		self.ex_res_preload_count_max = tonumber(self.exPreloadList.PRELOAD_AMOUNT_MAX_ANDROID)
	end


	self:_print(" self.exPreloadListMax: " .. tostring(self.ex_res_preload_count_max))
	self.exSchedulerHelper = self.exSchedulerHelper_single:new(self.exSchedulerHelper, ExResPreloader.UPDATE_INTERVAL, self.ex_res_preload_count_loaded, self.ex_res_preload_count_max )
	-- self.exSchedulerHelper:onCreate(ExResPreloader.UPDATE_INTERVAL, self.ex_res_preload_count_loaded, self.ex_res_preload_count_max )
end

------------------------------------------------

function ExResPreloader:OnLoadEnd()
	-- ExResPreloader.LoadingState = ExResPreloader.E_LOADING_STATE.FINISHED

	-- self:ReleaseScheduler()
	-- self:schedulerCallbackOnFininsh()

	-- wjj 20180710 preclone zhucheng texiao

	local precloner = require("util.ExPreclonePool"):getInstance()
	local list = require("util.ExPreloadList").PRECLONE_LIST_ZHUCHENG
	precloner:OnPreclone(nil, list, 0)


	self:DebugLog()
	self:_print( "###LUA FINISHED ExResPreloader.OnLoadEnd " )
end

function ExResPreloader:OnUpdateLoadOnce()
	local _self = ExResPreloader
	local i = _self.exSchedulerHelper.count_current
	_self:_print( "###LUA ExResPreloader OnSchedulerUpdate: " .. ( tostring(i) or " nil " ) )

	------------------------------------------------------------------------v

	-- png, zhucheng images
	local image_max = _self.exPreloadList.IMAGE_LIST_ZHUCHENG_MAX
	local node_max = _self.exPreloadList.PRELOAD_LIST_MAX
	local image_list = _self.exPreloadList.IMAGE_LIST_ZHUCHENG

	if( self:IsPlatformWindows() == false ) then
		image_max = _self.exPreloadList.IMAGE_LIST_BIG_ONLY_MAX
		image_list = _self.exPreloadList.IMAGE_LIST_BIG_ONLY
	end


	if ( i <= image_max ) then

		-- no tostring i here
		local filePath = image_list[i]
		-- TODO
		local began_time = os.clock()
		_self:_print( "~~~~ imageLoader Load BEGIN: " ..  tostring(filePath) .. " now: " .. tostring(began_time)  )
		_self.imageLoader:Load(filePath, false, true)

	-- csb file , createNode
	elseif ( i <= (image_max + node_max) ) then
		local i_node = i - image_max

		local filePath = _self.exPreloadList.PRELOAD_LIST[tostring(i_node)]
		-- try do not retain ... or memory leak
		local node = _self:Load(filePath, false, true)
		if( node == nil ) then
			_self:_print( "###LUA ExResPreloader Load: nil at " .. ( tostring(i) or " nil " ) )
		else
			_self:_print( "###LUA ExResPreloader Load: " ..  tostring(node:getName()) .. " refCount: " .. tostring(node:getReferenceCount())  )
		end
	else
	-- csb file, actionTimeLine
		local i_anim = i - (node_max + image_max)
		_self:_print( "###LUA ExResPreloader PRELOAD ANIM : " .. tostring(i_anim) )
		local animPath = _self.exPreloadList.PRELOAD_ANIM_LIST[tostring(i_anim)]
		local anim = _self:LoadAnim(animPath)
		if( anim == nil ) then
			_self:_print( "###LUA ExResPreloader Load anim: nil at " .. ( tostring(i_anim) or " nil " ) )
		else
			_self:_print( "###LUA ExResPreloader Load anim refCount: " ..  tostring(anim:getReferenceCount()) )
		end
	end

	------------------------------------------------------------------------v

	-- local node = _self.exResCachePool:OnLoadAtPath_CSB(filePath)
	-- _self.exResCachePool:TryAddToPool(filePath, node)

	_self.exSchedulerHelper:OnUpdateCount()

	if( _self.exSchedulerHelper.ScheduleState == _self.exSchedulerHelper.E_LOADING_STATE.FINISHED ) then
		_self:OnLoadEnd()
		return true
	end
	return false
end

function ExResPreloader:OnSchedulerUpdate()
	local _self = ExResPreloader
	if( _self.exSchedulerHelper.ScheduleState ~= _self.exSchedulerHelper.E_LOADING_STATE.RUNNING ) then
		_self:_print( "###LUA NOT RUNNING !! ExResPreloader.LoadingState: " .. ( tostring(_self.exSchedulerHelper.ScheduleState) or " nil " ) )
		do return end
	end

	for _i = 1, _self.PER_FRAME_FILES_LOAD_AMOUNT do
		local is_end = _self:OnUpdateLoadOnce()
		if( is_end ) then
			return
		end
	end

	-- _self:OnLoadingFinishCheck()
end

function ExResPreloader:OnLoadBegin(_callbackOnLoadFininsh)
	self:_print( "###LUA ExResPreloader.lua OnLoadBegin" )

	self:DebugLog()

	require("app.ExMemoryInterface"):getInstance():OnDisableMemoryReleaseAsync()

	self:InitScheduler()
	self.exSchedulerHelper:OnBegin(self.OnSchedulerUpdate)
	-- self.exResCachePool:onCreate()

	self:RegisterCallBack(_callbackOnLoadFininsh)

	-- ExResPreloader.schedulerEntry = self.scheduler:scheduleScriptFunc(self.OnSchedulerUpdate, self.UPDATE_INTERVAL , false)
end

function ExResPreloader:RegisterCallBack(callback)

	self.exSchedulerHelper:RegisterCallBack(callback)

end

------------------------------------------------

function ExResPreloader:OnRelease()
	self.exResCachePool:OnRelease()
end

------------------------------------------------

function ExResPreloader:getInstance()
	self:_print( "###LUA ExResPreloader.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExResPreloader:onCreate()
	self:_print( "###LUA ExResPreloader.lua onCreate" )


	self.exResCachePool:onCreate()

	return self
end

ExResPreloader:_print( "###LUA Return ExResPreloader.lua" )
return ExResPreloader