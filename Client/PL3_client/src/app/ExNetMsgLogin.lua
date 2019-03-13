print( "###LUA ExNetMsgLogin.lua" )
-- Coded by Wei Jingjun 20180628
local ExNetMsgLogin = class("ExNetMsgLogin")
-- ExNetMsgLogin = require("app.ExNetMsgLogin")

ExNetMsgLogin.old_config = require("config")
ExNetMsgLogin.config = require("util.ExConfig"):getInstance()
ExNetMsgLogin.lagHelper = require("util.ExLagHelper"):getInstance()
ExNetMsgLogin.app = require("app.MyApp"):getInstance()
-- ExNetMsgLogin.netErrHelper = require("util.ExNetErrorHelper"):getInstance()



------------------------------------------------
ExNetMsgLogin.IS_SCENE_TRANSFER_EFFECT = false

ExNetMsgLogin.recvlistener_ = {}

ExNetMsgLogin.lastReceivedProto = {}
------------------------------------------------


function ExNetMsgLogin:GetEventDispatcher()
	local _self = cc.Director:getInstance()
	local eventDispatcher = _self:getEventDispatcher()
	return eventDispatcher
end

function ExNetMsgLogin:OnDestroy()
	local eventDispatcher = self:GetEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end


function ExNetMsgLogin:getApp()
	return self.app
end

function ExNetMsgLogin:OnLoginOK_NextScene()
	local player = require("app.Player"):getInstance()
	if player:getShipListSize() == 0 then
		self:getApp():pushToRootView("RegisterScene/RegisterShipScene")
	else
		if player:getGuideStep() == 63 then
			self:getApp():pushToRootView("HomeScene/HomeScene",{})
		else

			--[[
			if (self.IS_DEBUG_MEMORY) then
				self.exResPreloader:DebugMemory()
			end
			]]

			print("go CityScene")
			-- ADD WJJ 180702
			if( self.IS_SCENE_TRANSFER_EFFECT ) then
				self.lagHelper:BeginTransferEffect("UpdateScene")
			else
				self:getApp():pushToRootView("CityScene/CityScene", {pos = -1350})
			end
		end

		if( require("util.ExSDK"):getInstance():IsQuickSDK() ) then
			-- Added by Wei Jingjun 20180601 for Dangle SDK bug
			Call_C_setQuickUserInfo()
		end

	end

	-- local gf = require("GlobalFunc")
	-- if( gf ~= nil ) then
		-- gf:playMusic("sound/main.mp3", true)
	-- end

	playMusic("sound/main.mp3", true)
end

function ExNetMsgLogin:OnLoginOK(proto)
	print("@@@@@ OnLoginOK  ")

	--GameHandler.handler_c.adjustTrackEvent("login")

	local tips = require("util.TipsMessage"):getInstance()
	local player = require("app.Player"):getInstance()
	local gl = require("util.GlobalLoading"):getInstance()

	tips:tips(CONF:getStringValue("loginOK"))

	player:initInfo(proto)

	g_Player_Level = proto.user_info.level
	g_Player_Fight = player:getPower()

	local items = {}
	for i=1,CONF.RECHARGE.len do
		
		local rechargeConf = CONF.RECHARGE.get(CONF.RECHARGE.index[i])
		table.insert(items, rechargeConf.PRODUCT_ID)
		table.insert(items, rechargeConf["RECHARGE_"..server_platform])
	end
	GameHandler.handler_c.reqPaymentItemInfo(items)

	local version = cc.UserDefault:getInstance():getStringForKey("server_version")
	local user_id = cc.UserDefault:getInstance():getStringForKey("user_id")
	GameHandler.handler_c.onLoginEvent(version, user_id)

	if( self.config.IS_OLD_LOGIN_MODE ) then
		self:OnLoginOK_NextScene()
	else
		print("@@@@@ OnLoginOK proto received!")

		-- TODO
	end
end

function ExNetMsgLogin:OnLoginNODATA()
	local player = require("app.Player"):getInstance()
	player:initInfo(nil)
	-- player:registerRequst()
	local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()
	if guideManager:getShowGuide() then

		self:getApp():pushToRootView("CGScene")
	else
		self:getApp():pushToRootView("RegisterScene/RegisterPlayerScene")
	end

	return
end

function ExNetMsgLogin:NetMessageReceiverInit()

		local player = require("app.Player"):getInstance()

		local tips = require("util.TipsMessage"):getInstance()

		local gl = require("util.GlobalLoading"):getInstance()



	local function recvMsg()
		print("ExNetMsgLogin:recvMsg")

		local player = require("app.Player"):getInstance()
		local tips = require("util.TipsMessage"):getInstance()
		local gl = require("util.GlobalLoading"):getInstance()

		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_LOGIN_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("LoginResp",strData)
			self.lastReceivedProto = proto
			print("CMD_LOGIN_RESP ",proto.result)

			if cc.exports.musicVolume == "" then
				cc.exports.musicVolume = "100"
			end

			if cc.exports.effectVolume == "" then
				cc.exports.effectVolume = "100"
			end

			--[[
			if cc.UserDefault:getInstance():getStringForKey("musicVolume") == "" then
				cc.UserDefault:getInstance():setStringForKey("musicVolume", "100")
			end

			if cc.UserDefault:getInstance():getStringForKey("effectVolume") == "" then
				cc.UserDefault:getInstance():setStringForKey("effectVolume", "100")
			end


			cc.UserDefault:getInstance():flush()
			-- ]]

			--ADD WJJ 20180703
			-- self.netErrHelper:OnLoginConnectResponsed()
			require("util.ExNetErrorHelper"):getInstance():OnLoginConnectResponsed()

			if proto.result == "NODATA" then
				if( self.config.IS_OLD_LOGIN_MODE ) then
					self:OnLoginNODATA()
				else
					-- TODO
					self:OnLoginNODATA()
				end
			end

			if proto.result == "BLOCKED" then
				-- tips:tips(CONF:getStringValue("user_blocked"))
				self:getApp():pushToRootView("LoginScene/LoginScene", {player_type = "blocked"})
				return
			end
			
			if proto.result == "OK" then--进入主城
				self:OnLoginOK(proto)
			end
		end
	end

	local DEFINE_NET_ON_RECEVIE = "ClientConnect::onReceviePacket"
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:GetEventDispatcher()
	-- self.old_config.FixedPriority.kNormal  = 2
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, 2)

end

------------------------------------------------

function ExNetMsgLogin:getInstance()
	print( "###LUA ExNetMsgLogin.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExNetMsgLogin:onCreate()
	print( "###LUA ExNetMsgLogin.lua onCreate" )

	

	return self
end

print( "###LUA Return ExNetMsgLogin.lua" )
return ExNetMsgLogin