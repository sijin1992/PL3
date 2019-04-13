
local AppBase = class("AppBase")

AppBase._viewCache = nil
AppBase._topViewIndex = 1

-- ADD BY WJJ 20180613
AppBase.IS_FORCE_RELEASE = true

AppBase.IS_DEBUG_LOG_APPBASE = false

AppBase.AppBase_FRAME_INTERVAL = 0.013

AppBase.scheduler_res = require("util.ExAsyncLoadTimer"):getInstance()

function AppBase:_print_appbase(_log)
	if( self.IS_DEBUG_LOG_APPBASE ) then
		print(_log)
	end
end

AppBase.memoryTools = require("util.ExMemoryTools"):getInstance()

--------------------------------------------------------

function AppBase:OnNewSceneInit(view)
	-- ADD WJJ 20180706
	view:setVisible(true)
end

--------------------------------------------------------

function AppBase:ctor(configs)

	self._viewCache = require("util.clist"):create()

	self.configs_ = {
		viewsRoot  = "app.views",
		modelsRoot = "app.models",
		defaultSceneName = "LaunchScene"--"UpdateScene",--"LoginScene/LoginScene",
	}

	for k, v in pairs(configs or {}) do
		self.configs_[k] = v
	end

	if type(self.configs_.viewsRoot) ~= "table" then
		self.configs_.viewsRoot = {self.configs_.viewsRoot}
	end
	if type(self.configs_.modelsRoot) ~= "table" then
		self.configs_.modelsRoot = {self.configs_.modelsRoot}
	end

	if DEBUG > 1 then
		dump(self.configs_, "AppBase configs")
	end

	if CC_SHOW_FPS then
		cc.Director:getInstance():setDisplayStats(true)
	end

	-- event
	self:onCreate()
end

function AppBase:run(initSceneName)
	initSceneName = initSceneName or self.configs_.defaultSceneName
	self:enterScene(initSceneName)
end
--[[
function AppBase:ReleaseCache()
	self:_print_appbase("***** AppBase:ReleaseCache()")
	self.memoryTools:PurgeCache()
	-- cc.Director:getInstance():purgeCachedData()
end
]]
function AppBase:enterScene(sceneName, transition, time, more)

	-- self:ReleaseCache()

	self:clearViewCache()


	local view = self:createView(sceneName)
	self._viewCache:pushBack({_name = sceneName, _data = nil, _view = view})

	-- ADD WJJ 20180706
	-- self:OnNewSceneInit(view)

	view:showWithScene(transition, time, more)
	return view
end


function AppBase:createView(name, data)

	--print(string.format("********* AppBase createView BEGIN : %s *******************", name))

	--self.memoryTools:DebugCachedTexture(" AppBase createView BEGIN time: " ..name.."********".. tostring(os.clock()))
	-- wjj 20180709
	require("util.ExAsyncLoadTimer"):getInstance():ResetLastSceneChangeEndTime()

	for _, root in ipairs(self.configs_.viewsRoot) do
		local packageName = string.format("%s.%s", root, name)

		self:_print_appbase("#### LUA DBG AppBase.lua 66 packageName :  " .. tostring(packageName))

		local status, view = xpcall(function()
				return require(packageName)
			end, function(msg)
			if not string.find(msg, string.format("'%s' not found:", packageName)) then
				-- self:_print_appbase("load view error: ", msg)
			end
		end)
		local t = type(view)
		if status and (t == "table" or t == "userdata") then


			local _v = view:create(self, name, data)

			--self.memoryTools:DebugCachedTexture(" AppBase createView END time: " ..name.."********".. tostring(os.clock()))
			self:_print_appbase(string.format("********* AppBase createView END: %s *******************", name))
			return _v
		end
	end
	error(string.format("AppBase:createView() - not found view \"%s\" in search paths \"%s\"",
		name, table.concat(self.configs_.viewsRoot, ",")), 0)
end

function AppBase:onCreate()
end

function AppBase:addView2Top(name, data)

	local view = self:createView(name, data)
	local scene = display.getRunningScene()

	self._topViewIndex = self._topViewIndex + 1

	-- ADD WJJ 20180706
	-- self:OnNewSceneInit(view)

	scene:addChild(view, self._topViewIndex)
	view:setTag(self._topViewIndex)

	return view
end

function AppBase:removeTopView()
	print("@@@@removeTopView")
	local scene = display.getRunningScene()

	scene:removeChildByTag(self._topViewIndex)
	self._topViewIndex = self._topViewIndex - 1
end

function AppBase:removeViewByName( name )
	print("@@@@removeViewByName")
	local scene = display.getRunningScene()

	for k,v in pairs(scene:getChildren()) do
		if v:getName() == name then
			v:removeFromParent()
			self._topViewIndex = self._topViewIndex - 1
			break
		end
	end

end

function AppBase:getTopViewData( )
	 local t = self._viewCache:back()
	 if t ~= nil then
		return t._data
	 end
end

function AppBase:getTopViewName( )
	 local t = self._viewCache:back()
	 if t ~= nil then
		return t._name
	 end
end

function AppBase:getTopView( )
	 local t = self._viewCache:back()
	 if t ~= nil then
		return t._view
	 end
end



function AppBase:pushView(name, data)
	self:_print_appbase(string.format("********* AppBase pushView BEGIN : %s *******************", name))
	--cc.Director:getInstance():purgeCachedData()

	local scene = display.getRunningScene()
	
	local t = self._viewCache:back()
	if t ~= nil then

		t._view:removeSelf()
		t._view = nil
	end
	
	-- ADD WJJ 180705
	local memoryInterface = require("app.ExMemoryInterface"):getInstance()
	memoryInterface:OnEnableAnimationReleaseAsync()
	memoryInterface:OnEnableMemoryReleaseAsync()

	local view = self:createView(name, data)
	self._viewCache:pushBack({_name = name, _data = data, _view = view})

	self:OnNewSceneInit(view)
	-- view:setVisible(true)
	view:setName(name)
	scene:addChild(view)

	if( self.IS_FORCE_RELEASE ) then

		self.scheduler_res:OnSceneChangeEnd(scene, name, view)
	end

	self:_print_appbase(string.format("********* AppBase createView END: %s *******************", name))
	return view
end

function AppBase:popView()
	local t = self._viewCache:back()
	if t == nil then
		-- self:_print_appbase("t == nil")
		return
	end

	t._view:removeSelf()
	self._viewCache:popBack()

	t = self._viewCache:back()
	if t ~= nil then
		local view = self:createView(t._name, t._data)
		t._view = view
		
		local scene = display.getRunningScene()
		self:OnNewSceneInit(view)
		-- view:setVisible(true)
		scene:addChild(view)
	end
end

-- Never used ...  wjj 20180709
function AppBase:popToRootView()
	local t = self._viewCache:back()
	if t == nil and self._viewCache:front() == self._viewCache:back() then
		return
	end

	t._view:removeSelf()
	while self._viewCache:back() ~= nil and self._viewCache:front() ~= self._viewCache:back() do
		self._viewCache:popBack()
	end

	t = self._viewCache:back()
	if t ~= nil then
		local view = self:createView(t._name, t._data)
		t._view = view
		
		local scene = display.getRunningScene()

		self:OnNewSceneInit(view)
		-- view:setVisible(true)


		scene:addChild(view)
	end
end

function AppBase:pushToRootView(name, data)

	-- Added by Wei Jingjun 20180605
	-- self:_print_appbase("### Lua AppBase:pushToRootView : " .. tostring(name) .. tostring(data))

	local scene = display.getRunningScene()

	if( self.IS_FORCE_RELEASE ) then
		require("util.ExMemoryTools"):getInstance():OnSceneChanged(scene)
	end

	scene:removeAllChildren()

	self:clearViewCache()

	if( self.IS_FORCE_RELEASE ) then
		-- ADD WJJ 180705
		local memoryInterface = require("app.ExMemoryInterface"):getInstance()
		memoryInterface:OnEnableAnimationReleaseAsync()
		memoryInterface:OnEnableMemoryReleaseAsync()
		-- self.memoryTools:DebugCachedTexture(" AppBase createView BEGIN time: " .. tostring(os.clock()))
		if ( cc.exports.isTotalReleaseMemoryOnce  ) then
			cc.exports.isTotalReleaseMemoryOnce = false
			local memoryInterface = require("app.ExMemoryInterface"):getInstance()
			memoryInterface:OnTransitionScene(true)
			print( string.format( " @@@@ Appbase after remove all children, memory released! now: %s ", tostring(os.clock()))  )
		end

		cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
		cc.Director:getInstance():getTextureCache():removeUnusedTextures()

	end
	--display.removeUnusedSpriteFrames()


	-- self:_print_appbase("### Lua AppBase:pushToRootView : createView")
	local view = self:createView(name,data)

	-- self.scheduler_res:OnSceneChangeEnd(scene, name)
	-- self.memoryTools:DebugCachedTexture(" AppBase createView END time: " .. tostring(os.clock()))

	require("util.ExMemoryTools"):getInstance():DebugViewCache(view, " before add scene")

	self._viewCache:pushBack({_name = name, _data = data, _view = view})

	-- ADD WJJ 20180706
	-- show next frame, or lag
	self:OnNewSceneInit(view)
	-- view:setVisible(true)


	view:setName(name)
	scene:addChild(view)

	-- if( self.IS_FORCE_RELEASE ) then
		self.scheduler_res:OnSceneChangeEnd(scene, name , view)
	-- end

	require("util.ExMemoryTools"):getInstance():DebugViewCache(view, " after add scene")
	-- self:_print_appbase("### Lua AppBase:pushToRootView : end")
	return view
end

function AppBase:DebugViewCache(_v)
	if( _v == nil ) then
		self:_print_appbase("***** AppBase:DebugViewCache : NIL")
		do return end
	end

	self:_print_appbase("***** AppBase:DebugViewCache : " .. tostring(_v or " NIL"))
	self:_print_appbase("***** AppBase:DebugViewCache name: " .. tostring(_v:getName() or " NIL"))
	self:_print_appbase("***** AppBase:DebugViewCache ref count: " .. tostring(_v:getReferenceCount()))
end

function AppBase:clearViewCache()
	print("@@@clearViewCache")
	local is_back = true
	while is_back do
		local _v = self._viewCache:back()
		is_back = _v ~= nil
		if( is_back ) then
			require("util.ExMemoryTools"):getInstance():DebugViewCache(_v, " popBack")
				self._viewCache:popBack()
		end
	end
end

return AppBase
