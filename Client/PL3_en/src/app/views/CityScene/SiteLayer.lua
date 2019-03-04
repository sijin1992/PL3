local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local SiteLayer = class("SiteLayer", cc.load("mvc").ViewBase)

SiteLayer.RESOURCE_FILENAME = "CityScene/SiteLayer.csb"

SiteLayer.RUN_TIMELINE = true

SiteLayer.NEED_ADJUST_POSITION = true

SiteLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	-- ["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function SiteLayer:onCreate(data)
	self.data_ = data

end

function SiteLayer:OnBtnClick(event)
	printInfo(event.name)
end

function SiteLayer:onEnter()
  
	printInfo("SiteLayer:onEnter()")
end

function SiteLayer:onExit()
	
	printInfo("SiteLayer:onExit()")
end

function SiteLayer:addKuaiListener( node,type )
	
	local rn = self:getResourceNode()

	local name = node:getName()

	local music_node = rn:getChildByName("music_node")
	local bg = music_node:getChildByName(name.."_bg")

	local x = bg:getPositionX()
	local kuai_width = node:getContentSize().width
	local bg_width = bg:getContentSize().width

	local min_x = x + kuai_width/2
	local max_x = x + bg_width - kuai_width/2

	print("min_x", min_x)
	print("max_x", max_x)

	local function setPos( posX )
		if posX < min_x then
			node:setPositionX(min_x)
			node:getChildByName("text"):setString("0%")
		elseif posX > max_x then
			node:setPositionX(max_x)
			node:getChildByName("text"):setString("100%")
		else
			node:setPositionX(posX)

			local num = math.floor((posX - min_x)/(max_x - min_x)*100)
			node:getChildByName("text"):setString(num.."%")
		end
		
	end

	local function setVolume( ... )
		local len = string.len(node:getChildByName("text"):getString())
		local num = tonumber(string.sub(node:getChildByName("text"):getString(), 1, len-1))

		if type == 1 then
			setMusicVolume(num)
		elseif type == 2 then
			setEffectVolume(num)
		end
	end

	local function bg_touch( sender, eventType )
		if eventType == ccui.TouchEventType.began then

			setPos(sender:getTouchBeganPosition().x)

			setVolume()

		elseif eventType == ccui.TouchEventType.moved then

			setPos(sender:getTouchMovePosition().x)

			setVolume()

		elseif eventType == ccui.TouchEventType.ended then

			local len = string.len(node:getChildByName("text"):getString())
			local num = tonumber(string.sub(node:getChildByName("text"):getString(), 1, len-1))

			if type == 1 then
				setMusicVolume(num)

				-- BUG WJJ 20180718
				cc.exports.musicVolume = tostring(num)

				--[[
				cc.UserDefault:getInstance():setStringForKey("musicVolume", tostring(num))
				cc.UserDefault:getInstance():flush()
				--]]

			elseif type == 2 then
				setEffectVolume(num)

				-- BUG WJJ 20180718
				cc.exports.effectVolume = tostring(num)

				--[[
				cc.UserDefault:getInstance():setStringForKey("effectVolume", tostring(num))
				cc.UserDefault:getInstance():flush()
				--]]
			end


		elseif eventType == ccui.TouchEventType.canceled then

			local len = string.len(node:getChildByName("text"):getString())
			
			local num =  string.sub(node:getChildByName("text"):getString(), 1, len-1) 
			num =  tonumber(num)

			if (type == 1) then
				setMusicVolume(num)

				-- BUG WJJ 20180718
				cc.exports.musicVolume = tostring(num)

				-- cc.UserDefault:getInstance():setStringForKey("musicVolume", tostring(num))
				-- cc.UserDefault:getInstance():flush()
				

			elseif (type == 2) then
				setEffectVolume(num)

				-- BUG WJJ 20180718
				cc.exports.effectVolume = tostring(num)


				-- cc.UserDefault:getInstance():setStringForKey("effectVolume", tostring(num))
				-- cc.UserDefault:getInstance():flush()
				
			end
			
		end
	end

	bg:addTouchEventListener(bg_touch)

end

function SiteLayer:setKuaiPos( node,type )
	local rn = self:getResourceNode()

	local name = node:getName()

	local music_node = rn:getChildByName("music_node")
	local bg = music_node:getChildByName(name.."_bg")

	local x = bg:getPositionX()
	local kuai_width = node:getContentSize().width
	local bg_width = bg:getContentSize().width

	local min_x = x + kuai_width/2
	local max_x = x + bg_width - kuai_width/2

	local volume = 0
	if type == 1 then
		-- BUG WJJ 20180718
		-- volume =  tonumber(cc.UserDefault:getInstance():getStringForKey("musicVolume"))
		volume =  tonumber(cc.exports.musicVolume) or 0
	elseif type == 2 then
		-- BUG WJJ 20180718
		-- volume = tonumber(cc.UserDefault:getInstance():getStringForKey("effectVolume"))
		volume = tonumber(cc.exports.effectVolume) or 0
	end

	local posX = min_x + volume/100*(max_x-min_x)

	node:setPositionX(posX)


	node:getChildByName("text"):setString(volume.."%")
end

function SiteLayer:changeUI( ... )
	local rn = self:getResourceNode()
	local ud = cc.UserDefault:getInstance()

	local visitor_node = rn:getChildByName("visitor_node")
	visitor_node:getChildByName("username"):setString(CONF:getStringValue("current_account")..":"..ud:getStringForKey("username"))
	visitor_node:getChildByName("ins"):setString(ud:getBoolForKey("isVisitor") and CONF:getStringValue("binding_memo1") or CONF:getStringValue("binding_memo2"))
	visitor_node:getChildByName("bind"):getChildByName("text"):setString(CONF:getStringValue("binding_account"))
	visitor_node:getChildByName("bind"):setEnabled(ud:getBoolForKey("isVisitor") and true or false)
end

function SiteLayer:onEnterTransitionFinish()

	printInfo("SiteLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()
	local ud = cc.UserDefault:getInstance()

	local visitor_node = rn:getChildByName("visitor_node")
	visitor_node:getChildByName("username"):setString(CONF:getStringValue("current_account")..":"..ud:getStringForKey("username"))
	visitor_node:getChildByName("ins"):setString(ud:getBoolForKey("isVisitor") and CONF:getStringValue("binding_memo1") or CONF:getStringValue("binding_memo2"))
	visitor_node:getChildByName("bind"):getChildByName("text"):setString(CONF:getStringValue("binding_account"))
	visitor_node:getChildByName("bind"):setEnabled(ud:getBoolForKey("isVisitor") and true or false)

	local function bind_visitor( ... )
		local bind_layer = self:getResourceNode():getChildByName("bind_layer")
		if bind_layer == nil then
			return
		end

		local username = bind_layer:getChildByName("editbox_1"):getString()
		local password = bind_layer:getChildByName("editbox_2"):getString()

		local ud = cc.UserDefault:getInstance()
		local user_id = ud:getStringForKey("user_id")
		local server_id = ud:getStringForKey("server_id")
		local url = string.format("%s?type=3&username=%s&password=%s&userid=%s&serverid=%s&lang=%d", g_login_server_url, username, password, user_id,server_id,server_platform)
		print("@@@SiteLayer:onEnterTransitionFinish",url)
		local xhr = cc.XMLHttpRequest:new()
		xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
		xhr:open("GET", url)		

		local function onReadyStateChanged()
			if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
		 
				print("Http Status Code:" .. xhr.statusText)

				local response = xhr.response
				print("response",response)
				local output = json.decode(response,1)
				print("output.result",output.result)
				if output.result == 0 then
					
					ud:setStringForKey("username", username)
					ud:setStringForKey("password", password)
					ud:setBoolForKey("isVisitor", false)
					-- ud:setStringForKey("user_id", string.format("%d", output.result) )
					ud:flush()
			   
				-- elseif output.result == -2 then
				-- 	Tips:tips(CONF:getStringValue("ID_exist"))
					tips:tips(CONF:getStringValue("binding_success"))
					bind_layer:removeFromParent()
					self:changeUI()
				else
					tips:tips(output.msg)
					-- tips:tips(CONF:getStringValue("binding_failed")..":"..output.msg)
				end
				
			else
				print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
			end
			gl:releaseLoading()
			xhr:unregisterScriptHandler()

		end

		xhr:registerScriptHandler(onReadyStateChanged)
		xhr:send()

		gl:retainLoading()
	end


	local function createBindLayer( ... )
		local bind_layer = require("app.ExResInterface"):getInstance():FastLoad("LoginScene/RegisterLayer.csb")
		animManager:runAnimOnceByCSB(bind_layer, "LoginScene/RegisterLayer.csb", "animation")

		bind_layer:getChildByName('layer_name'):setString(CONF:getStringValue("binding_account"))
		bind_layer:getChildByName("close"):addClickEventListener(function ( ... )
			
			animManager:runAnimOnceByCSB(bind_layer, "LoginScene/RegisterLayer.csb", "animation0", function ( ... )
				bind_layer:removeFromParent()
			end)
		end)
		bind_layer:getChildByName('confirm'):getChildByName("text"):setString(CONF:getStringValue("binding_account"))

		bind_layer:getChildByName("title_1"):setString(CONF:getStringValue("user_name")..":")
		bind_layer:getChildByName("title_2"):setString(CONF:getStringValue("password")..":")
		bind_layer:getChildByName("title_3"):setString(CONF:getStringValue("password_confirm")..":")

		for i=1,3 do
		    local textField = bind_layer:getChildByName("TextField_"..i)
		    --textField:setPlaceholder(CONF:getStringValue("6-20 Characters"))
		    textField:setName(string.format("editbox_%d", i))

			textField:addEventListener(function ( sender, eventType )
				
				if eventType == ccui.TextFiledEventType.attach_with_ime  then
					sender:setString("")
				end
			end)
		end

		bind_layer:getChildByName("confirm"):addClickEventListener(function ( ... )

			if bind_layer:getChildByName("editbox_1"):getString() == "" then
				tips:tips(CONF:getStringValue("username_empty"))
				return
			end

			if bind_layer:getChildByName("editbox_2"):getString() == "" or bind_layer:getChildByName("editbox_3"):getString() == "" then
				tips:tips(CONF:getStringValue("password_empty"))
				return
			end

			if bind_layer:getChildByName("editbox_2"):getString() ~= bind_layer:getChildByName("editbox_3"):getString() then
				tips:tips(CONF:getStringValue("password_diff"))
				return
			end
			
			for i=2,3 do

				if string.len(bind_layer:getChildByName("editbox_"..i):getString()) < 6 then
					tips:tips(CONF:getStringValue("password_short"))
					return

				end
			end


			messageBox:reset(CONF.STRING.get("binding_confirm").VALUE, bind_visitor)

			
		end)

		bind_layer:setName("bind_layer")
		self:getResourceNode():addChild(bind_layer)
	end

	rn:getChildByName("visitor_node"):getChildByName("bind"):addClickEventListener(function ( ... )
		local ud = cc.UserDefault:getInstance()
		if ud:getBoolForKey("isVisitor") then
			createBindLayer()
		else
			tips:tips("not visitor")
		end
	end)

	local kefu_node = rn:getChildByName("kefu_node")
	kefu_node:getChildByName("name"):setString(CONF:getStringValue("haomiao"))
	kefu_node:getChildByName("mail"):setString(CONF:getStringValue("contact"))
	kefu_node:getChildByName("mail_text"):setString(CONF:getStringValue("contact_way"))
	kefu_node:getChildByName("wang"):setString(CONF:getStringValue("website"))
	kefu_node:getChildByName("wang_text"):setString(CONF:getStringValue("website_site"))
	kefu_node:getChildByName("wang_text"):addClickEventListener(function ( ... )
		if device.platform == "ios" or device.platform == "android" then 
			GameHandler.handler_c.openUrl(CONF:getStringValue("website_site"))
		end
	end)

	rn:getChildByName("name"):setString(CONF:getStringValue("setting"))
	rn:getChildByName("music_text"):setString(CONF:getStringValue("music_site"))
	rn:getChildByName("code_text"):setString(CONF:getStringValue("redeem_code"))
	rn:getChildByName("zhuxiao"):getChildByName("text"):setString(CONF:getStringValue("login_off"))

	local music_node = rn:getChildByName("music_node")
	music_node:getChildByName("open_music"):setString(CONF:getStringValue("open_music"))
	music_node:getChildByName("open_effect"):setString(CONF:getStringValue("open_effect"))

	self:setKuaiPos(music_node:getChildByName("music_kuai"), 1)
	self:setKuaiPos(music_node:getChildByName("effect_kuai"), 2)

	self:addKuaiListener(music_node:getChildByName("music_kuai"), 1)
	self:addKuaiListener(music_node:getChildByName("effect_kuai"), 2)

	local code_node = rn:getChildByName("code_node")
	code_node:getChildByName("code"):setString(CONF:getStringValue("write_code"))

	--edit    
	local text = code_node:getChildByName("text")

	local fontColor = text:getTextColor()
	local fontName = text:getFontName()
	local fontSize = text:getFontSize()
	local maxLength = 20
 
	self.edit = ccui.EditBox:create(text:getContentSize(),"aa")
	code_node:addChild(self.edit)
	self.edit:setPosition(cc.p(text:getPosition()))
	self.edit:setPositionX(self.edit:getPositionX())
	self.edit:setPlaceHolder("")
	self.edit:setPlaceholderFont(fontName,fontSize)
	self.edit:setPlaceholderFontColor(fontColor)
	self.edit:setFont(fontName,fontSize)
	self.edit:setFontSize(fontSize)
	self.edit:setFontColor(fontColor)
	self.edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
	self.edit:setReturnType(1)
	self.edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	self.edit:setMaxLength(maxLength)
	self.edit:setName("edit")

	code_node:getChildByName("clear"):getChildByName("text"):setString(CONF:getStringValue("clear"))
	code_node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))

	code_node:getChildByName("clear"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		self.edit:setText("")
	end)

	code_node:getChildByName("yes"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
        local code = self.edit:getText()
		if code == "" then 
			tips:tips(CONF:getStringValue("code_empty"))
			return
		end
        SendCDKEY(code)
	end)

	rn:getChildByName("close"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/return.mp3")
		self:removeFromParent()
	end)

	rn:getChildByName("music"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/tab.mp3")
		music_node:setVisible(true)
		code_node:setVisible(false)
		kefu_node:setVisible(false)
		visitor_node:setVisible(false)

		rn:getChildByName("visitor"):setOpacity(0)
		rn:getChildByName("music"):setOpacity(255)
		rn:getChildByName("code"):setOpacity(0)
		rn:getChildByName("kefu"):setOpacity(0)

	end)

	rn:getChildByName("code"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/tab.mp3")
		music_node:setVisible(false)
		code_node:setVisible(true)
		kefu_node:setVisible(false)
		visitor_node:setVisible(false)

		rn:getChildByName("visitor"):setOpacity(0)
		rn:getChildByName("music"):setOpacity(0)
		rn:getChildByName("code"):setOpacity(255)
		rn:getChildByName("kefu"):setOpacity(0)

	end)

	rn:getChildByName("zhuxiao"):addClickEventListener(function ( sender )
		local function func( )
			playEffectSound("sound/system/click.mp3")

			player:initInfo()

			self:getApp():pushToRootView("LoginScene/LoginScene")
			--ADD WJJ 20180716
			if( require("util.ExSDK"):getInstance():IsQuickSDK() ) then
				GameHandler.handler_c.sdkLogout()
			end
		end

		messageBox:reset(CONF.STRING.get("login_off_tips").VALUE, func)
	end)

	rn:getChildByName("kefu_text"):setString(CONF:getStringValue("service"))
	rn:getChildByName("kefu"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/tab.mp3")

		music_node:setVisible(false)
		code_node:setVisible(false)
		kefu_node:setVisible(true)
		visitor_node:setVisible(false)

		rn:getChildByName("visitor"):setOpacity(0)
		rn:getChildByName("music"):setOpacity(0)
		rn:getChildByName("code"):setOpacity(0)
		rn:getChildByName("kefu"):setOpacity(255)

	end)


	rn:getChildByName("visitor_text"):setString(CONF:getStringValue("binding_account"))
	rn:getChildByName("visitor"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/tab.mp3")

		music_node:setVisible(false)
		code_node:setVisible(false)
		kefu_node:setVisible(false)
		visitor_node:setVisible(true)

		rn:getChildByName("visitor"):setOpacity(255)
		rn:getChildByName("music"):setOpacity(0)
		rn:getChildByName("code"):setOpacity(0)
		rn:getChildByName("kefu"):setOpacity(0)

	end)


	if DEBUG == 0 or device.platform ~= "windows" then
		rn:getChildByName("gm_input"):setVisible(false)
	end

	rn:getChildByName("gm_input"):onEvent(function (event)
			
		if event.name == "DETACH_WITH_IME" then
			local player = require("app.Player"):getInstance()
			if not player:isInited() then
				print("player :no data")
				return
			end
			
			local str = event.target:getString()

			if str == "" then
				return
			end
			local strData = Tools.encode("CmdClientGMReq", {
				cmd = str
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CLIENT_GM_REQ"),strData)

			gl:retainLoading()
			event.target:setString("")
		end
	end)

	local function recvMsg()
		print("LoginScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_CLIENT_GM_RESP") then

			local proto = Tools.decode("CmdClientGMResp",strData)
			print("CMD_CLIENT_GM_RESP result",proto.result)

			gl:releaseLoading()
		end
		
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function SiteLayer:onExitTransitionStart()

	printInfo("SiteLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return SiteLayer
