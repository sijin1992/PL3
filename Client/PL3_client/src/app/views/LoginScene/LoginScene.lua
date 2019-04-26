
local tips = require("util.TipsMessage"):getInstance()
local messageBox = require("util.MessageBox"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local app = require("app.MyApp"):getInstance()

local LoginScene = class("LoginScene", cc.load("mvc").ViewBase)

LoginScene.RESOURCE_FILENAME = "LoginScene/LoginScene.csb"

LoginScene.RUN_TIMELINE = true

LoginScene.NEED_ADJUST_POSITION = true

LoginScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	
	["start_pve"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["start_pvp"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local notice_can_close = true

----------------------------------------

LoginScene.config = require("util.ExConfig"):getInstance()
LoginScene.netGateway = require("app.ExNetMsgGateway"):getInstance()


LoginScene.gatewayConnectListener_ = {}
LoginScene.gateway_xhr = {}




----------------------------------------

function LoginScene:OnBtnClick(event)
	printInfo(event.name)

end

function LoginScene:onCreate( data )
	self.data_ = data

	-- ADD WJJ 20180703
	self.config.isMainGameSceneEntered = false

end

function LoginScene:onEnter()
	
	printInfo("LoginScene:onEnter()")
    if device.platform == "ios" or device.platform == "android" then
        buglySetTag(2)
    end
end

function LoginScene:onExit()
	
	printInfo("LoginScene:onExit()")
end

function LoginScene:changeLayer( layer_name )

	-- self:getApp():removeTopView()

	if layer_name == "start" then
		app:addView2Top("LoginScene/StartLayer", {ani = "intro"})
	elseif layer_name == "gate" then
		app:addView2Top("LoginScene/GateLayer")
	elseif layer_name == "register" then
		app:addView2Top("LoginScene/RegisterLayer")
	elseif layer_name == "server" then
		app:addView2Top("LoginScene/ServerSelectLayer")
	elseif layer_name == "login" then
		app:addView2Top("LoginScene/LoginLayer")
	end

end

function LoginScene:initScene(  )
	print(" LoginScene:initScene 67 ")

	playMusic("sound/login.mp3", true)

	local rn = self:getResourceNode()

	rn:getChildByName("start_pve"):setVisible(false)
	rn:getChildByName("start_pvp"):setVisible(false)

	local client_version = cc.UserDefault:getInstance():getStringForKey("client_version")
	rn:getChildByName("text"):setString(CONF:getStringValue("version")..":"..client_version)
	print(" LoginScene:initScene 78 ")
	animManager:runAnimOnceByCSB(rn:getChildByName("light"), "LoginScene/sfx/light/light.csb", "1", function ()

		rn:getChildByName("light"):setVisible(false)
		rn:getChildByName("light_2"):setVisible(true)

		animManager:runAnimByCSB(rn:getChildByName("light_2"), "LoginScene/sfx/light/light.csb", "2")
	end)

	self:changeLayer("start")

	
	print(" LoginScene:initScene 90 ")
	local function updateUserInfo(event)
		--self:changeLayer("start")
	end

	print(" LoginScene:initScene 95 ")
	self.updateUserInfolistener_ = cc.EventListenerCustom:create("login_update_user_info", updateUserInfo)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.updateUserInfolistener_, FixedPriority.kNormal)


end

function LoginScene:createNotice( str, flag )

	if self.notice_ == nil then
		return
	end

	if self.can_create_notice == false then
		return
	end


	str = string.gsub(str, "<br/>", "\n")

	local notice_node = require("app.ExResInterface"):getInstance():FastLoad("LoginScene/NotiveNode.csb")
	notice_node:getChildByName("title"):setString(CONF:getStringValue("notice"))
	notice_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	animManager:runAnimOnceByCSB(notice_node, "LoginScene/NotiveNode.csb", "animation", function ( ... )
		self.can_create_notice = true
	end)

	local text_list = notice_node:getChildByName("list")
	text_list:setScrollBarEnabled(false)
	local listSize = text_list:getContentSize()
	local label = cc.Label:createWithTTF(str, s_default_font, 20 )--cc.size(listSize.width, 0))
	label:setLineBreakWithoutSpace(true)
	label:setMaxLineWidth(624)

	local inner_height
	if label:getContentSize().height > listSize.height then
		inner_height = label:getContentSize().height
		label:setPosition(0, inner_height)
	else
		inner_height = listSize.height
		label:setPosition(0, inner_height - (inner_height-label:getContentSize().height)*0.5)
		text_list:setTouchEnabled(false)
	end
	label:setAnchorPoint(cc.p(0, 1))
	-- label:enableShadow(cc.c4b(255,255,255,255), cc.size(0.5,0.5))
	label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
	text_list:setInnerContainerSize(cc.size(listSize.width, inner_height))

	text_list:addChild(label)

	print("#### notice_node ref init : " .. tostring(notice_node:getReferenceCount() ))
	notice_node:getChildByName("button"):addClickEventListener(function ( ... )
			-- DEBUG WJJ
			print("#### notice_node ref before run anim : " .. tostring(notice_node:getReferenceCount() ))
			local act = animManager:runAnimOnceByCSB(notice_node, "LoginScene/NotiveNode.csb", "animation0", function ( ... )
				notice_node:removeFromParent()
				print("#### notice_node ref after removeFromParent : " .. tostring(notice_node:getReferenceCount() ))
			end)
			

	print("#### notice_node ref after addClickEventListener : " .. tostring(notice_node:getReferenceCount() ))
		
		if flag == false or flag == nil then
			if cc.UserDefault:getInstance():getStringForKey("username") ~= "" and cc.UserDefault:getInstance():getStringForKey("username") ~= nil then
				
			else
				if( require("util.ExSDK"):getInstance():IsQuickSDK() ) then
					GameHandler.handler_c.sdkLogin()
				else
					self:getApp():addView2Top("LoginScene/LoginLayer")
				end
			end
		end
		
	end)

	self.can_create_notice = false
	-- tipsAction(notice_node, nil, function ( ... )
	-- 	self.can_create_notice = true
	-- end)

	notice_node:setPosition(cc.exports.VisibleRect:center())
	display:getRunningScene():addChild(notice_node,900)
	
	print("#### notice_node ref after getRunningScene addChild : " .. tostring(notice_node:getReferenceCount() ))
end

function LoginScene:getServers( )

	if self.data_ then
		return self.data_.server
	end
end


function LoginScene:SendHttp(xhr)
	if( xhr == nil ) then
		print("@@@@  LoginScene Retry xhr nil")
	else
		xhr:send()
	end
end

function LoginScene:StopHttp(xhr)
	gl:releaseLoading()
	local _xhr = self.gateway_xhr
	_xhr:unregisterScriptHandler()
end

function LoginScene:Retry(xhr)
	-- local _self = require("app.views.LoginScene/LoginScene"):getResourceNode()
	-- local _self = LoginScene:getResourceNode()
	local _self = self.netGateway.instance_LoginScene
	-- local _self = require("app.views.LoginScene/LoginScene")
	-- local _self = LoginScene
	-- _self.last_retry_xhr = xhr

	_self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(function ( ... )
			if( xhr == nil ) then
				print("@@@@  LoginScene Retry xhr nil")
			end
			-- local _self = self.netGateway.instance_LoginScene
			-- xhr = _self.last_retry_xhr
			xhr = _self.gateway_xhr
			_self:SendHttp(xhr)

	end)))
end

-------------------------------------------------

function LoginScene:OnGatewayFailed()
	print("@@@@ OnGatewayFailed")
	local xhr = self.gateway_xhr
	local response = self.config:GetFakeJson_Gateway()
	self.netGateway:OnGatewayResponse(response, xhr)
end
-------------------------------------------------


function LoginScene:SendHttpStep1_GetServerInfo()
	local client_version = cc.UserDefault:getInstance():getStringForKey("client_version")
	local url = string.format("%s?platform=%d&uid=%d&ver=%s&os=%s", g_server_centre_url, g_platform, 1, client_version, device.platform)
	local xhr = cc.XMLHttpRequest:new()
	
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xhr:open("GET", url)

	print( string.format("@@@ url: %s ", url) )

	local function onReadyStateChanged()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
	 
			-- for _i3, _v3 in pairs( xhr ) do
				print(string.format("@@@@ LoginScene.lua 201 xhr : %s", tostring(xhr) ) ) 
			-- end

			-- ADD WJJ 180627

			print("Http Status Code: " .. xhr.statusText)

			local response = xhr.response

			if( self.config.IS_USE_FAKE_JSON_HTTP ) then
				response = self.config:GetFakeJson_Gateway()
			end

			-- ADD WJJ 20180703
			self.netGateway:OnGatewayResponse(response, xhr, self)
		else
			print("server xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
			gl:releaseLoading()
			local function func()
				gl:retainLoading()
				self:Retry(xhr)
				--self:SendHttpStep2_GetNotice()
			end
			local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(CONF.STRING.get("want_reconnect").VALUE, func)			
		end
	end

	-- ADD WJJ 20180703

	local err_helper = require("util.ExNetErrorHelper"):getInstance()
	--[[
	local event_name = err_helper.EVENT_GATEWAY_CONNECT_FAILED
	print("@@@ event_name : " .. tostring(event_name))
	self.gatewayConnectListener_ = cc.EventListenerCustom:create(event_name, function ()
		print("@@@@ EVENT_GATEWAY_CONNECT_FAILED")
		self:OnGatewayFailed()
	end)
	--]]

	self.netGateway.instance_LoginScene = self

	xhr:registerScriptHandler(onReadyStateChanged)



	xhr:send()
	gl:retainLoading()

	self.gateway_xhr = xhr
	err_helper.gateway_xhr = xhr
end

function LoginScene:SendHttpStep2_GetNotice()
	local client_version = cc.UserDefault:getInstance():getStringForKey("client_version")
	local url = string.format("%s?platform=%d", g_server_centre_url, g_platform)
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xhr:open("GET", url)
	local function getNotice()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
	 
			print("Http Status Code:" .. xhr.statusText)

			local response = xhr.response

			self.notice_ = response
		else
			print("notice xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
		end
		gl:releaseLoading()
		xhr:unregisterScriptHandler()

		if self.notice_ ~= nil  then
			self:createNotice(self.notice_)
		end

	end

	xhr:registerScriptHandler(getNotice)
	xhr:send()
	gl:retainLoading()
end

function LoginScene:onEnterTransitionFinish()
	printInfo("LoginScene:onEnterTransitionFinish()")

	--ADD WJJ 180629
	require("util.ExNetErrorHelper"):getInstance():OnConnectGatewayBegin()
	self.serverDataRetryCount = 0

	playMusic("sound/login.mp3", true)


	self.can_create_notice = true

	if self.data_ then
		if self.data_.player_type == "blocked" then
			tips:tips(CONF:getStringValue("user_blocked"))
		end
	end
	
	local rn = self:getResourceNode()
	local client_version = cc.UserDefault:getInstance():getStringForKey("client_version")
	rn:getChildByName("text"):setString(CONF:getStringValue("version")..":"..client_version)

	
	self:SendHttpStep1_GetServerInfo()
	self:SendHttpStep2_GetNotice()

	self.layer_ = nil

	self.noticeListener_ = cc.EventListenerCustom:create("loginNotice", function ()
		self:createNotice(self.notice_, true)
	end)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.noticeListener_, FixedPriority.kNormal)
end

function LoginScene:onExitTransitionStart()
	printInfo("LoginScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.noticeListener_)
	-- eventDispatcher:removeEventListener(self.gatewayConnectListener_)


end


return LoginScene	