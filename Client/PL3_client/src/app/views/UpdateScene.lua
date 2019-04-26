

local FileUtils = cc.FileUtils:getInstance()

local VisibleRect = cc.exports.VisibleRect

local UpdateScene = class("UpdateScene", cc.load("mvc").ViewBase)

-- Added by Wei Jingjun 2018612
UpdateScene.IS_DEBUG_LOG_VERBOSE = false

UpdateScene.RESOURCE_FILENAME = "UpdateScene/UpdateScene.csb"
UpdateScene.NEED_ADJUST_POSITION = true

local assetsManager = nil

local need_version


local storagePath = FileUtils:getWritablePath() .. "update_file/"
-- ADDED BY jinxin 20180620
local IS_SHOW_FAKEPROGRESS = true
local needEnter = false
local scheduler = cc.Director:getInstance():getScheduler()
UpdateScene.schedulerInfo = nil

-- ADDED BY WJJ 20180612
UpdateScene.IS_DEBUG_MEMORY = false
UpdateScene.exResPreloader = require("app.ExResPreloader"):getInstance()
UpdateScene.config = require("util.ExConfig"):getInstance()
UpdateScene.netMsgLogin = require("app.ExNetMsgLogin"):getInstance()
UpdateScene.lagHelper = require("util.ExLagHelper"):getInstance()
-- UpdateScene.netErrHelper = require("util.ExNetErrorHelper"):getInstance()


function UpdateScene:TestMemoryClear()
	local scene = display.getRunningScene()
	scene:removeAllChildren()
	-- self:clearViewCache()

	cc.Director:getInstance():getTextureCache():waitForQuit()

	require("app.ExMemoryInterface"):getInstance():OnEnableAnimationReleaseAsync()
	require("app.ExMemoryInterface"):getInstance():OnEnableMemoryReleaseAsync()
	require("util.ExMemoryHelper"):getInstance():ReleaseMemory()

	cc.SpriteFrameCache:getInstance():removeSpriteFrames()

	cc.Director:getInstance():getTextureCache():removeAllTextures()
	--require("util.ExMemoryHelper"):getInstance().memoryTools:DebugCachedTexture("*** TEST UpdateScene removeAllTextures")

	-- local _scene = cc.Scene:create()
	-- cc.Director:getInstance():replaceScene(_scene)

	-- cc.Director:getInstance():destroyTextureCache()
	require("util.GlobalLoading"):getInstance():retainLoading()
end

function UpdateScene:nextScene()

	if( self.config.IS_OLD_LOGIN_MODE ) then
		-- TODO WJJ : restart game when network error here,  
		-- time over , then retart game..

		-- self:TestMemoryClear()

		require("util.ExNetErrorHelper"):getInstance():OnConnectLoginServerBegin_CPP(display.getRunningScene())
		local result = GameHandler.handler_c.connect()
--		print(string.format("GameHandler.handler_c.connect result = %s", tostring(result)) )
	else
		self.netMsgLogin:OnLoginOK_NextScene()
	end
end

function UpdateScene:getAssetsManager(init)

	local function onError(errorCode)

		local rn = self:getResourceNode()

		local status = rn:getChildByName("status")
		local text = rn:getChildByName("prgress_text")
		status:setVisible(true)
		if errorCode == cc.ASSETSMANAGER_NO_NEW_VERSION then

			status:setString(CONF:getStringValue("no_update"))
			printInfo("no new version")
	
			self:startPreload()

		elseif errorCode == cc.ASSETSMANAGER_NETWORK then
			
			status:setString(CONF:getStringValue("network_error"))
			text:setString("")
			printInfo("network error")
	
			if self:getAssetsManager():checkUpdate() then
				self:getAssetsManager():update()
			end

		else
			status:setString(CONF:getStringValue("network_error") .. " : " .. errorCode)
			text:setString("")
			printInfo("other error: errorCode ", errorCode)

			if self:getAssetsManager():checkUpdate() then
				self:getAssetsManager():update()
			end
		end
	end

	local function onProgress( percent )

		local rn = self:getResourceNode()

		local status = rn:getChildByName("status")

		local text = rn:getChildByName("prgress_text")

		if percent >= 10000 then

			percent = percent - 10000
			text:setString(string.format("%d%%",percent))
			self.progress_:setPercentage(percent)

		elseif percent == 100 then

			status:setString(CONF:getStringValue("Unpack"))
			text:setString(CONF:getStringValue("Waiting"))
		else
			status:setVisible(true)
			status:setString(CONF:getStringValue("updating") .. "->" .. "1.".. g_big_version .. "." .. need_version)

			text:setVisible(true)
			text:setString(string.format("%d%%",percent))

			local maxX = self.progress_:getMaxLength()
			self.progress_:setPercentage(percent)
		end
	end

	local function onSuccess()

		local rn = self:getResourceNode()
		local text = rn:getChildByName("prgress_text")
		text:setString("100%")
		self.progress_:setPercentage(100)

		local status = rn:getChildByName("status")
		status:setVisible(true)
		status:setString(CONF:getStringValue("update_ok"))

		cc.UserDefault:getInstance():setStringForKey("client_version", self:getAssetsManager():getVersion())
		cc.UserDefault:getInstance():flush()

		if self:checkUpdate() then
			if self:getAssetsManager(true):checkUpdate() then
				self:getAssetsManager():update()
			end
		else
			self:startPreload()
		end
	end

	if init == true and assetsManager then
		assetsManager:release()
		assetsManager = nil
	end

	if nil == assetsManager then

		local rn = self:getResourceNode()
		self:resetUI()
		local status = rn:getChildByName("status")
		status:setVisible(false)

	
		local client_version = cc.UserDefault:getInstance():getStringForKey("client_version")
		local client_version_list = Tools.split(client_version, ".")

		

		need_version = tonumber(client_version_list[3]) + 1
		
		local packageUrl = g_update_server_url..g_big_version.."/"..need_version.."/cocos2dx-update-temp-package.zip"

		local versionFileUrl = g_update_server_url..g_big_version.."/"..need_version.."/version.txt"
	
		if FileUtils:isDirectoryExist(storagePath) == false then
			FileUtils:createDirectory(storagePath)
		end

		assetsManager = cc.AssetsManager:new(packageUrl,versionFileUrl,storagePath)
		assetsManager:retain()
		assetsManager:setDelegate(onError, cc.ASSETSMANAGER_PROTOCOL_ERROR )
		assetsManager:setDelegate(onProgress, cc.ASSETSMANAGER_PROTOCOL_PROGRESS)
		assetsManager:setDelegate(onSuccess, cc.ASSETSMANAGER_PROTOCOL_SUCCESS )
		assetsManager:setConnectionTimeout(10)

		print("assetsManager:getVersion():", assetsManager:getVersion())
		--assetsManager:deleteVersion()
	end

	return assetsManager
end


function UpdateScene:checkUpdate()

	local server_version = cc.UserDefault:getInstance():getStringForKey("server_version")
	local server_version_list = Tools.split(server_version, ".")

	if tonumber(server_version_list[2]) > g_big_version then
		local function func()
			if device.platform == "ios" then
				GameHandler.handler_c.openUrl(g_apple_store_url)
			elseif device.platform == "android" then
				GameHandler.handler_c.openUrl(g_google_store_url)
			end
		end

		local messageBox = require("util.MessageBox"):getInstance()
		messageBox:reset(CONF.STRING.get("versions").VALUE, func, nil, true)

		return false
	end

	local client_version = cc.UserDefault:getInstance():getStringForKey("client_version")
	local client_version_list = Tools.split(client_version, ".")


	if tonumber(client_version_list[3]) >= tonumber(server_version_list[3]) then

		return false
	end

    cc.exports.updateHot = true

	return true
end

local preload_count = 0
local preloaded_count = 0

-- Added by Wei Jingjun 2018612
local ex_res_preload_count = 999

function UpdateScene:startPreload( )
	-- Added by Wei Jingjun 2018612
	if( self.IS_DEBUG_LOG_VERBOSE ) then
		print("###LUA UpdateScene:startPreload 191 ")
	end

	local rn = self:getResourceNode()
	local status = rn:getChildByName("status")
    local text = rn:getChildByName("prgress_text")  --Added by JinXin 20180620
	status:setString(CONF:getStringValue("preloading"))

	self:resetUI()

	cc.FileUtils:getInstance():purgeCachedEntries()
	cc.FileUtils:getInstance():addSearchPath(storagePath.."src/", true)
	cc.FileUtils:getInstance():addSearchPath(storagePath.."res/", true)

	if package.loaded and package.loaded["conf/String"] then
		package.loaded["conf/String"] = nil
	end
	package.loaded = nil

	require "config"
	require "cocos.init"
	require "VisibleRect"

	require("app.MyApp"):getInstance():onCreate()
	-- Added by Wei Jingjun 2018612
	if( self.IS_DEBUG_LOG_VERBOSE ) then
		print("###LUA UpdateScene:startPreload 223 ExResPreloader onCreate ")
	end

	if( self.IS_DEBUG_LOG_VERBOSE ) then
		print("###LUA UpdateScene:startPreload 227 ExResPreloader = " .. (tostring(self.exResPreloader) or "nil" ))
	end

	local function registerAllConf()
		local time = os.time()
		CONF:load(false)
		if DEBUG >= 2 then
			CONF:debug()
		end
		time = os.time() - time
		print("registerAllConf all time", time)
	end

	registerAllConf()
	----------------------------------------------------------------------------------------------------v
	-- wjj 20180716 no use code
	--[[ 
	local needLoadImage = {
		-- "ChapterScene/guankada/guank/1.png",
		-- "ChapterScene/guankada/guank/3.png",
		-- "ChapterScene/guankada/guank/4.png",
		-- "ChapterScene/guankada/guank/6.png",
		-- "ChapterScene/guankada/guank/7.png",
		-- "LevelScene/sfx/1.png",
	}
	preload_count = #needLoadImage

	

	if( self.IS_DEBUG_LOG_VERBOSE ) then
		print("###LUA UpdateScene:startPreload 230 preload_count: " .. tostring(preload_count) )
		print("###LUA UpdateScene:startPreload 230 ex_res_preload_count: " .. tostring(ex_res_preload_count) )
	end

	local function imageLoaded(texture)

		texture:retain()

		preloaded_count = preloaded_count + 1
		
		local percent = preloaded_count  / preload_count * 100
		if percent > 100 then
			percent = 100
		end
		local maxX = self.progress_:getMaxLength()
		
		self.progress_:setPercentage(percent)

		if preloaded_count >= preload_count then
			self:nextScene()
		end
	end

	if  ( (preload_count == 0) and ( ex_res_preload_count == 0 )  ) then
		self:nextScene()
		return
	end

	if  ( (preload_count > 0)  ) then
		for i,v in ipairs(needLoadImage) do
			cc.Director:getInstance():getTextureCache():addImageAsync(v, imageLoaded)
		end
	end

	--]]
	----------------------------------------------------------------------------------------------------v

    --Added by JinXin 20180620
    if IS_SHOW_FAKEPROGRESS then
        self:fakeProgress(self.config.TOTAL_LOADING_TIME2)
    end

	if( self.exResPreloader ~= nil ) then
		print(string.format("@@@ OnLoadBegin delayed now: %s", os.clock()))
		self:runAction(cc.Sequence:create(cc.DelayTime:create(self.config.DELAY_TIME_UPDATESCENE_PRELOAD), cc.CallFunc:create(function ( ... )
			print(string.format("@@@ OnLoadBegin started now: %s", os.clock()))
			self.exResPreloader:OnLoadBegin(function(_selfLoader) 
				print("###LUA UpdateScene ExResPreloader callback 297 ")
				self.needEnter = true
                cc.exports.updateHot = false
                if( g_is_release_memory_enabled or (device.platform ~= "windows") ) then
		            if( cc.exports.memoryReleaseAsync == nil ) then
			            cc.exports.memoryReleaseAsync = require("util.ExMemoryReleaseAsync"):getInstance()
			            cc.exports.memoryReleaseAsync:onCreate()
		            end
	            end
	            print("__cname",self.__cname)
                if self.__cname == "UpdateScene" then
				    self:nextScene()
                end

			end)
		end)))
	end

	if( self.IS_DEBUG_LOG_VERBOSE ) then
		print("###LUA UpdateScene:startPreload 282 ENDED IMAGE PRELOAD " )
	end
end

--Added by JinXin 20180620
function UpdateScene:fakeProgress(totaltime)
    local rn = self:getResourceNode()
	local status = rn:getChildByName("status")
    local text = rn:getChildByName("prgress_text")
    local time = 0
    local percent = 0

    local function timer()
        if time < totaltime/0.033 then
            time = time + 1
            percent = time / (totaltime/0.033) *100
            if percent > 100 or self.needEnter then
                percent = 100
            end
            status:setString(CONF:getStringValue("preloading"))
            text:setString(string.format("%d%%",percent))
            self.progress_:setPercentage(percent)
        end
    end
    if self.schedulerInfo == nil then
        self.schedulerInfo = scheduler:scheduleScriptFunc(timer,0.033,false)
    end
end

UpdateScene.IS_SCENE_TRANSFER_EFFECT = false
function UpdateScene:onCreate(data)
	if( self.IS_SCENE_TRANSFER_EFFECT == false ) then
		-- self.data_ = data
	else
		if data then
			self.data_ = data
		end
		if ((data and data.sfx) or true ) then
			if( data and data.sfx ) then
				data.sfx = false
			end
			local view = self:getApp():createView("CityScene/TransferScene",{from = "LoginScene" ,state = "enter"})
			self:addChild(view)
		end
	end
end

function UpdateScene:onEnter()
	
	printInfo("UpdateScene:onEnter()")
    if device.platform == "ios" or device.platform == "android" then
        buglySetTag(4)
    end
	-- DEBUG WJJ
--	if( g_is_release_memory_enabled or (device.platform ~= "windows") ) then
--		if( cc.exports.memoryReleaseAsync == nil ) then
--			cc.exports.memoryReleaseAsync = require("util.ExMemoryReleaseAsync"):getInstance()
--			cc.exports.memoryReleaseAsync:onCreate()
--		end
--	end
end

function UpdateScene:onExit()
	if self.schedulerInfo ~= nil then
	    scheduler:unscheduleScriptEntry(self.schedulerInfo)
	    self.schedulerInfo = nil
	end
	printInfo("UpdateScene:onExit()")

end

function UpdateScene:resetUI( )
	local rn = self:getResourceNode()

	local text = rn:getChildByName("prgress_text")
	text:setString(string.format("%d%%",0))
	text:setVisible(false)

	local uiProgress = rn:getChildByName("progress")
	self.progress_ = require("util.ScaleProgressDelegate"):create(uiProgress, uiProgress:getTag())
	self.progress_:setPercentage(0)
end

function UpdateScene:onEnterTransitionFinish()
	printInfo("UpdateScene:onEnterTransitionFinish()")


	if self:checkUpdate() then
		if self:getAssetsManager(true):checkUpdate() then
			self:getAssetsManager():update()
		end
	else
		self:startPreload()
	end

	if( self.config.IS_OLD_LOGIN_MODE ) then
		self.netMsgLogin:NetMessageReceiverInit()
	else
		-- TODO
		
	end




	local animManager = require("app.AnimManager"):getInstance()
	local rn = self:getResourceNode()

	animManager:runAnimByCSB(rn:getChildByName("light"), "LoginScene/sfx/light/light.csb", "2")

	animManager:runAnimByCSB(rn, UpdateScene.RESOURCE_FILENAME,  "loop")
	local sp_path = 'LoginScene/ui/biaoti_en.png'
	if server_platform==0 then
--		sp_path = 'LoginScene/ui/biaoti_cn.png'
	end
	rn:getChildByName('Node_32'):getChildByName('Node_1'):getChildByName('biaoti'):setTexture(sp_path)

	local status = rn:getChildByName("status")
	status:setVisible(true)
	status:setString(CONF:getStringValue("updating"))
	local text = rn:getChildByName("prgress_text")
	text:setVisible(true)
	text:setString("...")
end

function UpdateScene:onExitTransitionStart()
	printInfo("UpdateScene:onExitTransitionStart()")


	if (self.IS_DEBUG_MEMORY) then
		self.exResPreloader:DebugMemory()
	end

	if nil ~= assetsManager then
		assetsManager:release()
		assetsManager = nil
	end


	if( self.config.IS_OLD_LOGIN_MODE ) then
		self.netMsgLogin:OnDestroy()
	else

	end

	--[[
	local eventDispatcher = self:getEventDispatcher()

	eventDispatcher:removeEventListener(self.recvlistener_)
	]]


	if (self.IS_DEBUG_MEMORY) then
		self.exResPreloader:DebugMemory()
	end

end

return UpdateScene