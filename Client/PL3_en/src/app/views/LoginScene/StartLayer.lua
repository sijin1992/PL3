local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local ud = cc.UserDefault:getInstance()

local tips = require("util.TipsMessage"):getInstance()

local StartLayer = class("StartLayer", cc.load("mvc").ViewBase)


StartLayer.RESOURCE_FILENAME = "LoginScene/StartLayer.csb"

StartLayer.NEED_ADJUST_POSITION = true

StartLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["start"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local password = "utugamepassword"

-- ADDED BY WJJ 20180612
StartLayer.IS_DEBUG_MEMORY = false
StartLayer.exResPreloader = require("app.ExResPreloader"):getInstance()
StartLayer.config = require("util.ExConfig"):getInstance()

StartLayer.player = require("app.Player"):getInstance()
StartLayer.netMsgLogin = require("app.ExNetMsgLogin"):getInstance()
StartLayer.lagHelper = require("util.ExLagHelper"):getInstance()
StartLayer.IS_SCENE_TRANSFER_EFFECT = false

-- ADDED BY WJJ 20180628
function StartLayer:FlurryLog_Login()
	--[[
	local _self = require("app.views.LoginScene.StartLayer")
	local now = os.time()
	local localTimeZone = os.difftime(now, os.time(os.date("!*t", now)))
	local date = os.date("*t", _self.player:getServerTime() - localTimeZone)--计算出服务端时区与客户端时区差值
	local date_str = string.format("year:%d/month:%d/day:%d/hour:%d/min:%d/sec:%d", date.year, date.month, date.day, date.hour, date.min, date.sec)

	flurryLogEvent("login", {time = date_str}, 2)
	]]
end

function StartLayer:OnStartGameButtonClicked()
	print( "@@@@@ OnStartGameButtonClicked" )

	self:FlurryLog_Login(_self)

	if( self.config.IS_OLD_LOGIN_MODE ) then
		if( self.IS_SCENE_TRANSFER_EFFECT ) then
			self.lagHelper:BeginTransferEffect("LoginScene")
		else
			self:getApp():pushToRootView("UpdateScene")
		end
	else
		--TODO connect server now!
		GameHandler.handler_c.connect()
	end
end

local function createGUID()
	local seed = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f',}
	local tb ={}
	for i=1,32 do
		table.insert(tb, seed[math.random(1,16)])
	end
	local sid = table.concat(tb)
	local timestr = string.format("%#x", os.time())
	return string.format('%s-%s-%s-%s-%s', string.sub(sid, 1, 8), string.sub(sid, 9, 16), string.sub(sid, 17, 24), string.sub(sid, 25, 32), string.sub(timestr, 3, 10))
end

local function registerGUID()

	local guid = createGUID()
	local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
	local url = string.format("%s?type=1&username=%s&password=%s&devicecode=devicecode&serverid=%s&lang=%d", g_login_server_url, uuid, password,server_id,server_platform)
	print("@@@StartLayer:OnStartGameButtonClicked()",url)
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xhr:open("GET", url)

	local function onReadyStateChanged()

		gl:releaseLoading()
		xhr:unregisterScriptHandler()

		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
	 
			print("Http Status Code:" .. xhr.statusText)

			local response = xhr.response
			local output = json.decode(response,1)
			if tonumber(output.result) > 0 then
				local ud = cc.UserDefault:getInstance()
				ud:setStringForKey("user_id", string.format("%d", output.result) )
				ud:flush()
		   
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventCustom:new("login_update_user_info"))
			elseif output.result == -2 then
				tips:tips(CONF:getStringValue("ID_exist"))
			else
				tips:tips(output.msg)
			end
		else
			print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
			return
		end
		
		-- ADD WJJ 180628
		self:OnStartGameButtonClicked()
		-- self:getApp():pushToRootView("UpdateScene")
	end

	xhr:registerScriptHandler(onReadyStateChanged)
	xhr:send()

	gl:retainLoading()
end

function StartLayer:OnBtnClick(event)

	printInfo(event.name)

	local app = require("app.MyApp"):getInstance()
	local rn = self:getResourceNode()

	if event.name == "ended" and event.target:getName() == "start" then
		playEffectSound("sound/system/click.mp3")

		if rn:getChildByName("protocol_check_box"):getTag() == ccui.CheckBoxEventType.unselected then
			tips:tips(CONF:getStringValue("agree_protocol_first"))
			return
		end

		if ud:getIntegerForKey("server_id") == 0 then
--			self:getApp():removeTopView()
       	 		app:addView2Top("LoginScene/ServerSelectLayer")
       	 		return
		end

		local quName = cc.UserDefault:getInstance():getStringForKey("server_id")
		local server_list = display.getRunningScene():getChildByName("LoginScene/LoginScene"):getServers()

		local index = 0
		local st = 0
		for i,v in ipairs(server_list) do
			if tonumber(v.id) == tonumber(quName) then
				quName = v.nm
				st = v.st
				break
			end
		end
		if st == 2 then
			tips:tips(CONF:getStringValue("server_maintenance"))
			return
		end

		local user_str = ud:getStringForKey("user_id")

		if user_str == nil or user_str == "" then
			-- ADD WJJ 20180716
			if( require("util.ExSDK"):getInstance():IsQuickSDK() ) then
				GameHandler.handler_c.sdkLogin()
				return 
            else
                tips:tips(CONF:getStringValue("username_empty"))
                return
			end

			local uuid = GameHandler.handler_c.getUUID()
			local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
			local url = string.format("%s?type=0&username=%s&password=%s&serverid=%s&lang=%d", g_login_server_url, uuid, password, server_id,server_platform)
			print("@@@StartLayer:OnBtnClick",url)
			local xhr = cc.XMLHttpRequest:new()
			xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
			xhr:open("GET", url)

			local function onReadyStateChanged()
		
				if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			 
					print("Http Status Code:" .. xhr.statusText)

					local response = xhr.response
					local output = json.decode(response,1)

					-- ADD WJJ 20180612
					print( "##LUA StartLayer 123 output.result = " .. (tostring(output.result) or " nil") )

					if tonumber(output.result) > 0 then
						local ud = cc.UserDefault:getInstance()
						ud:setStringForKey("user_id", string.format("%d", output.result))
						ud:flush()

						cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventCustom:new("login_update_user_info"))
					else
						registerGUID()
					end
					
				else
					print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
				end

				gl:releaseLoading()
				xhr:unregisterScriptHandler()


				--ADD WJJ 180628
				self:OnStartGameButtonClicked()

				--[[
				local now = os.time()
				local localTimeZone = os.difftime(now, os.time(os.date("!*t", now)))
				local date = os.date("*t", self:getServerTime() - localTimeZone)--计算出服务端时区与客户端时区差值
				local date_str = string.format("year:%d/month:%d/day:%d/hour:%d/min:%d/sec:%d", date.year, date.month, date.day, date.hour, date.min, date.sec)

				flurryLogEvent("login", {time = date_str}, 2)
				]]
	
				-- self:getApp():pushToRootView("UpdateScene")
			end

			xhr:registerScriptHandler(onReadyStateChanged)
			xhr:send()
			gl:retainLoading()


			return
		end

		--ADD WJJ 180628
		self:OnStartGameButtonClicked()
		-- self:getApp():pushToRootView("UpdateScene")
	end

end

function StartLayer:onCreate( data )
	self.data_ = data

	-- ADD WJJ 20180703
	self.config.isMainGameSceneEntered = false

end

function StartLayer:onEnter()
	
	printInfo("StartLayer:onEnter()")

end

function StartLayer:onExit()
	if (self.IS_DEBUG_MEMORY) then
		self.exResPreloader:DebugMemory()
	end



	printInfo("StartLayer:onExit()")
end

function StartLayer:changeServer( ... )
	local rn = self:getResourceNode()

	local quName = cc.UserDefault:getInstance():getStringForKey("server_id")

	local server_list = display.getRunningScene():getChildByName("LoginScene/LoginScene"):getServers()

	local index = 0
	local st = 0
	local rc = 0
	for i,v in ipairs(server_list) do
		if tonumber(v.id) == tonumber(quName) then
			quName = v.nm
			st = v.st
			rc = v.rc + 1
			break
		end
	end

	if st == 0 then
		rn:getChildByName("state_1"):setTexture("LoginScene/ui/logo_unimpedede.png")
		rn:getChildByName("state_2"):setTexture("LoginScene/ui/botton_unimpedede.png")
	elseif st == 1 then
		rn:getChildByName("state_1"):setTexture("LoginScene/ui/logo_full.png")
		rn:getChildByName("state_2"):setTexture("LoginScene/ui/botton_full.png")

	elseif st == 2 then
		rn:getChildByName("state_1"):setTexture("LoginScene/ui/logo_maintain.png")
		rn:getChildByName("state_2"):setTexture("LoginScene/ui/botton_maintain .png")

	end

	rn:getChildByName('title_node'):getChildByName('tiaoti_node'):getChildByName('biaoti_en'):setVisible(server_platform==0)
	rn:getChildByName('title_node'):getChildByName('tiaoti_node'):getChildByName('biaoti_cn'):setVisible(server_platform==1)

	if quName ~= nil and quName ~= "" then
		rn:getChildByName("qu_name"):setString(quName)
	else
		rn:getChildByName("qu_name"):setString(CONF:getStringValue("please_select_server"))
	end

	rn:getChildByName("qu"):setString("["..rc..CONF:getStringValue("qu_text").."]")
end

function StartLayer:onEnterTransitionFinish()
	printInfo("StartLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()
	rn:getChildByName("Text_1"):setString(CONF:getStringValue("change")) 

	local userName = cc.UserDefault:getInstance():getStringForKey("username")
	if userName ~= nil and userName ~= "" then
		rn:getChildByName("user_name"):setString(CONF:getStringValue("user_name")..":"..userName)
	else
		local uuid = GameHandler.handler_c.getUUID()
		if string.len(uuid) > 8 then
			uuid = string.sub(uuid, 1, 8) .. "..."
		end
		rn:getChildByName("user_name"):setString(CONF:getStringValue("user_name")..":" .. CONF:getStringValue("visitor") .. "_" .. uuid)
	end

	local quName = cc.UserDefault:getInstance():getStringForKey("server_id")

	local server_list = display.getRunningScene():getChildByName("LoginScene/LoginScene"):getServers()

	local index = 0
	local st = 0
	local rc = 0
	for i,v in ipairs(server_list) do
		if tonumber(v.id) == tonumber(quName) then
			quName = v.nm
			st = v.st
			rc = v.rc + 1
			break
		end
	end

	if st == 0 then
		rn:getChildByName("state_1"):setTexture("LoginScene/ui/logo_unimpedede.png")
		rn:getChildByName("state_2"):setTexture("LoginScene/ui/botton_unimpedede.png")
	elseif st == 1 then
		rn:getChildByName("state_1"):setTexture("LoginScene/ui/logo_full.png")
		rn:getChildByName("state_2"):setTexture("LoginScene/ui/botton_full.png")

	elseif st == 2 then
		rn:getChildByName("state_1"):setTexture("LoginScene/ui/logo_maintain.png")
		rn:getChildByName("state_2"):setTexture("LoginScene/ui/botton_maintain .png")

	end

	rn:getChildByName('title_node'):getChildByName('tiaoti_node'):getChildByName('biaoti_en'):setVisible(server_platform==0)
	rn:getChildByName('title_node'):getChildByName('tiaoti_node'):getChildByName('biaoti_cn'):setVisible(server_platform==1)

	if quName ~= nil and quName ~= "" then
		rn:getChildByName("qu_name"):setString(quName)
	else
		rn:getChildByName("qu_name"):setString(CONF:getStringValue("please_select_server"))
	end

	rn:getChildByName("qu"):setString("["..rc..CONF:getStringValue("qu_text").."]")
	-- rn:getChildByName("qu_name"):setString(CONF:getStringValue("qu_name"))

	rn:getChildByName("qu_name"):setOpacity(0)
	-- rn:getChildByName("qu_name"):setPositionX(rn:getChildByName("qu"):getPositionX() + rn:getChildByName("qu"):getContentSize().width+ 200)

	rn:getChildByName("start"):getChildByName("text"):setString(CONF:getStringValue("start game"))

	local protocol_1 = rn:getChildByName("protocol_1")
	local protocol_2 = rn:getChildByName("protocol_2")

	protocol_1:setString(CONF:getStringValue("agree_protocol"))
	protocol_2:setString(CONF:getStringValue("user_protocol"))
	protocol_2:addClickEventListener(function ( sender )

	
		GameHandler.handler_c.openUrl(g_xy_url.."?type="..server_platform)
	
	end)

	protocol_2:setPositionX(protocol_1:getPositionX() + protocol_1:getContentSize().width)

	rn:getChildByName("protocol_check_box"):setTag(ccui.CheckBoxEventType.selected):setSelected(true)
	rn:getChildByName("protocol_check_box"):addEventListener(function ( sender, eventtype )
		sender:setTag(eventtype)
	end)

	local app = require("app.MyApp"):getInstance()

	rn:getChildByName("gate_1"):addClickEventListener(function (sender)
			-- self:getApp():removeTopView()
			-- app:addView2Top("LoginScene/GateLayer")

		if( require("util.ExSDK"):getInstance():IsQuickSDK() ) then
			GameHandler.handler_c.sdkLogin()
		else
			app:addView2Top("LoginScene/LoginLayer")
		end
	end)

	rn:getChildByName("gate_2"):addClickEventListener(function (sender)
			-- self:getApp():removeTopView()
			app:addView2Top("LoginScene/ServerSelectLayer")

	end)

	rn:getChildByName("notive"):addClickEventListener(function ( ... )
		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("loginNotice")
	end)

	local function onFrameEvent(frame)

		if nil == frame then
			return
		end
		local str = frame:getEvent()

		if str == "1" then

			local node = frame:getNode()

			local o_node = self:getResourceNode():getChildByName(node:getName().."_name")
			o_node:setPositionX(node:getPositionX() + node:getContentSize().width)
			o_node:setOpacity(255)
		end
	end

	local function actionOver( ... )
		animManager:runAnimByCSB(rn, "LoginScene/StartLayer.csb", "1")

		-- display.getRunningScene():getChildByName("LoginScene/LoginScene"):createNotice()

	end

	animManager:runAnimOnceByCSB(rn, "LoginScene/StartLayer.csb", self.data_.ani, actionOver, onFrameEvent)
	if server_platform == 1 then
		rn:getChildByName('Text_2'):setVisible(false)
	end

	self.CSListener_ = cc.EventListenerCustom:create("changeServer", function ()
		self:changeServer()
	end)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.CSListener_, FixedPriority.kNormal)

	--ADD WJJ 180628
	if( self.config.IS_OLD_LOGIN_MODE == false ) then
		self.netMsgLogin:NetMessageReceiverInit()
	end

	-- ADD WJJ 20180723
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_LoginMainScene(self)

end
-- end of transition fininsh

function StartLayer:onExitTransitionStart()
	printInfo("StartLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.CSListener_)

	--ADD WJJ 180628
	if ( self.config.IS_OLD_LOGIN_MODE == false ) then
		self.netMsgLogin:OnDestroy()
	end
end

return StartLayer