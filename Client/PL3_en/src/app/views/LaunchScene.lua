print("###LUA DBG launchScene.lua  line 1")
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()
print("###LUA DBG launchScene.lua  line 5")
local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local LaunchScene = class("LaunchScene", cc.load("mvc").ViewBase)

LaunchScene.RESOURCE_FILENAME = "LaunchScene/LaunchScene.csb"

LaunchScene.RUN_TIMELINE = true

LaunchScene.NEED_ADJUST_POSITION = true

LaunchScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

-- ADD BY WJJ 20180619
LaunchScene.exResPreloader = require("app.ExResPreloader"):getInstance()
LaunchScene.exConfig = require("util.ExConfig"):getInstance()

function LaunchScene:onEnter()
  
	printInfo("LaunchScene:onEnter()")
	-- WJJ: DO CREATE PRELOADER ON START LAYER!
	self.exResPreloader:onCreate()
	self.exConfig:onCreate()
end

function LaunchScene:onExit()
	
	printInfo("LaunchScene:onExit()")
end


function LaunchScene:onEnterTransitionFinish()
	printInfo("LaunchScene:onEnterTransitionFinish()")

	local rn = self:getResourceNode()

	local icon = rn:getChildByName("icon")

	local function func()

		local FileUtils = cc.FileUtils:getInstance()
		local UserDefault = cc.UserDefault:getInstance()

		local client_version = UserDefault:getStringForKey("client_version")

		if client_version ~= "" then
			local client_version_list = Tools.split(client_version, ".")
			if tonumber(client_version_list[2]) < g_big_version then

				local storagePath = FileUtils:getWritablePath() .. "update_file/"
				if FileUtils:isDirectoryExist(storagePath) == true then
					FileUtils:removeDirectory(storagePath)
				end
				client_version = ""
			end
		end

		if client_version == "" then
			client_version = "1."..g_big_version.."."..g_org_res_version
			UserDefault:setStringForKey("client_version", client_version)
			UserDefault:flush()
		end

		

		local function checkZipConf(zipPath)
			--开发测试的时候直接用 src/conf/
			-- if DEBUG >= 2 then
			-- 	return
			-- end

			-- local outPath = FileUtils:getWritablePath() .. "update_file/"
			-- cc.FileUtils:getInstance():addSearchPath(outPath)

			-- local unziped = cc.UserDefault:getInstance():getBoolForKey("upziped_conf")
			-- if unziped == true then
			-- 	return
			-- end

			-- local ok = GameHandler.handler_c.unzip(zipPath, outPath)
			-- assert(ok,"unzip conf error")
			-- cc.UserDefault:getInstance():setBoolForKey("upziped_conf", true)
			-- cc.UserDefault:getInstance():flush()
		end

		checkZipConf("conf.zip")
		CONF:load(true)
		self:getApp():pushToRootView("LoginScene/LoginScene")
	end

	icon:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), cc.FadeOut:create(1), cc.CallFunc:create(func)))
	if server_platform == 1 then
		rn:getChildByName('Text_2'):setVisible(false)
	end

	-- ADD WJJ 20180723
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Logo(self)
end

function LaunchScene:onExitTransitionStart()

	printInfo("LaunchScene:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return LaunchScene