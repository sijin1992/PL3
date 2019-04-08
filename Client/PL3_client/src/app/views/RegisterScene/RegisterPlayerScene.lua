
local FileUtils = cc.FileUtils:getInstance()

local VisibleRect = cc.exports.VisibleRect

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local RegisterPlayerScene = class("RegisterPlayerScene", cc.load("mvc").ViewBase)

RegisterPlayerScene.RESOURCE_FILENAME = "RegisterScene/RegisterPlayerScene.csb"

RegisterPlayerScene.RUN_TIMELINE = true

RegisterPlayerScene.NEED_ADJUST_POSITION = true

RegisterPlayerScene.RESOURCE_BINDING = {
}

function RegisterPlayerScene:onCreate()

end

function RegisterPlayerScene:onEnter()
	
	printInfo("RegisterPlayerScene:onEnter()")
end

function RegisterPlayerScene:onExit()
	
	printInfo("RegisterPlayerScene:onExit()")

end

function RegisterPlayerScene:clickHead( tag )

	self.lead = tag

	local rn = self:getResourceNode()
	local leftPanel = rn:getChildByName("leftPanel")

	for i=1,#self.headIcon do
		local driverNode = leftPanel:getChildByName("driverNode_"..i)
		if self.headIcon[i] == tag then

			driverNode:getChildByName("background"):loadTexture("Common/newUI/cj_button_light.png")

			local conf = CONF.ROLE_CREATION.get(i)
			rn:getChildByName("name"):setString(CONF:getStringValue(conf.NAME_ID))
			rn:getChildByName("roleImage"):setTexture("HeroImage/"..conf.RES_ID..".png")
			rn:getChildByName("ins"):setString(CONF:getStringValue(conf.MEMO_ID))

		else
			driverNode:getChildByName("background"):loadTexture("Common/newUI/cj_button.png")
		end
	end
end

function RegisterPlayerScene:createDriverNode( id)
	local driverNode = require("app.ExResInterface"):getInstance():FastLoad("RegisterScene/DriverNode.csb")

	local icon = driverNode:getChildByName("icon")
	local bg = driverNode:getChildByName("background")

	local sprite = cc.Sprite:create("HeroImage/"..id..".png")
	sprite:setScale(1)
	local sp = cc.Sprite:create("StarOccupationLayer/ui/mask_black.png")
	sp:setScale(1.50)

	local clippingNode = cc.ClippingNode:create()
	clippingNode:setStencil(sp)
	clippingNode:setInverted(false)
	clippingNode:setAlphaThreshold(0.5)
	clippingNode:addChild(sprite)

	driverNode:addChild(clippingNode)
	clippingNode:setPosition(cc.p(icon:getPositionX(),icon:getPositionY()-3))

	icon:removeFromParent()

	driverNode:setTag(id)

	bg:addClickEventListener(function ( ... )
		self:clickHead(id)
	end)

	return driverNode
end

function RegisterPlayerScene:onEnterTransitionFinish()
	printInfo("RegisterPlayerScene:onEnterTransitionFinish()")

    if device.platform == "ios" or device.platform == "android" then
        TDGAMission:onBegin("RegisterPlayer")
    end

	playMusic("sound/main.mp3", true)

	self.headIcon = {}

	for i=1,5 do
		local num = CONF.ROLE_CREATION.get(i).ICON_ID
		table.insert(self.headIcon, num)
	end

	local rn = self:getResourceNode()

	animManager:runAnimOnceByCSB(rn, "RegisterScene/RegisterPlayerScene.csb", "intro", function ( ... )
		guideManager:createGuideLayer(1)
	end)


	rn:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("recruiting team"))
	-- rn:getChildByName("text"):setString(CONF:getStringValue("write_player_name"))

	local leftPanel = rn:getChildByName("leftPanel")

	for i,v in ipairs(self.headIcon) do

		local node = self:createDriverNode(v)
		node:setName("driverNode_"..i)
		node:setPosition(leftPanel:getChildByName("player"..i):getPosition())
		leftPanel:addChild(node)

		leftPanel:getChildByName("player"..i):setVisible(false)
	end

	self:clickHead(self.headIcon[1])

	rn:getChildByName("swallow"):setSwallowTouches(true)
	rn:getChildByName("swallow"):addClickEventListener(function ( ... )
		-- body
	end)
	rn:getChildByName("swallow"):setLocalZOrder(2)

	self.num1 = 0
	self.num2 = 0
	for i,v in ipairs(CONF.NAME.getIDList()) do
		local conf = CONF.NAME.get(v)
		if conf.SURNAME ~= nil then
			self.num1 = self.num1 + 1
		end

		if conf.NAME ~= nil then
			self.num2 = self.num2 + 1
		end

	end



	--edit    
	local text = rn:getChildByName("text")

	local fontColor = text:getTextColor()
	local fontName = text:getFontName()
	local fontSize = text:getFontSize()
	local maxLength = CONF.PARAM.get("name_digit").PARAM
 
	self.edit = ccui.EditBox:create(text:getContentSize(),"aa")
	self.edit:setContentSize(cc.size(self.edit:getContentSize().width,self.edit:getContentSize().height))
	rn:addChild(self.edit)
	self.edit:setPosition(cc.p(text:getPosition()))
	self.edit:setPositionX(self.edit:getPositionX())
--	self.edit:setPlaceHolder(CONF:getStringValue("write_player_name"))
--	self.edit:setPlaceholderFont(fontName,fontSize)
--	self.edit:setPlaceholderFontColor(fontColor)
	self.edit:setFont(fontName,fontSize)
	self.edit:setFontSize(fontSize)
	self.edit:setFontColor(fontColor)
	self.edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
	self.edit:setReturnType(1)
	self.edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	self.edit:setMaxLength(maxLength)
	self.edit:setName("edit")

	self.edit:setOpacity(0)
	self.edit:setPositionY(self.edit:getPositionY() - 6)
	self.edit:runAction(cc.Spawn:create(cc.FadeIn:create(0.33), cc.MoveBy:create(0.33, cc.p(0,20))))

	-- local handler = function(event)  
	--     if event == "began" then  
	--         self.edit:setText( text:getString())  
	--     end  
		  
	--     if event == "changed" then  
	--         local str =  self.edit:getText()  
	--         text:setString(str)  
	--     end  
		  
	--     if event == "return" then  
	--        local str =  self.edit:getText()  
	--        self.edit:setText("")  
	--        text:setString(str)  
	--     end  
	-- end  
		
	-- self.edit:registerScriptEditBoxHandler(handler) 

	text:setVisible(false)



	rn:getChildByName("btn"):addClickEventListener(function ( ... )
		local user_str = cc.UserDefault:getInstance():getStringForKey("user_id")
		if user_str == nil or user_str == "" then
			tips:tips(CONF:getStringValue("user_name_null"))
			return
		end

		local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
		if server_id == nil or server_id == "" then
			tips:tips("please select server first")
			return
		end

		if self.edit:getText() == "" then
			tips:tips(CONF:getStringValue("player_name_null"))
			return
		end

		for i=1,CONF.DIRTYWORD.len do
		  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
		  if string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY) then
		  	tips:tips(CONF:getStringValue("dirty_message"))
		  	return
		  end
		end

		local str = shuaiSubString(self.edit:getText())
		for i=1,CONF.DIRTYWORD.len do
		  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
		  if string.find(str, CONF.DIRTYWORD[i].KEY) then
		  	tips:tips(CONF:getStringValue("dirty_message"))
		  	return
		  end
		end

		-- self.type = "reg"
		local strData = Tools.encode("RegistReq", {
			roleName = self.edit:getText(),
			lead = self.lead,
			server = server_id,
			platform = 13,
			device_type = "device_type",
			resolution = "resolution",
			os_type = "os_type",
			ISP = "ISP",
			net = "net",
			MCC = "MCC",
			account = user_str,
		})

		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_REGIST_REQ"),strData)
		
		gl:retainLoading()
	end)

	 math.randomseed(os.time())


	local function random( ... )
		local index = 0 
		for i=1,3 do
			index = math.random(10)
		end

		local num = 0
		local name_str = ""
		if index >= 1 and index <= 3 then
			for i=1,3 do
				num = math.random(self.num1)
			end
			
			name_str = CONF.NAME.get(num).SURNAME

		elseif index >= 4 and index <= 6 then
			for i=1,3 do
				num = math.random(self.num2)
			end
			
			name_str = CONF.NAME.get(num).NAME

		else

			for i=1,3 do
				num = math.random(self.num1)
			end

			name_str = name_str..CONF.NAME.get(num).SURNAME

			name_str = name_str.."."

			for i=1,3 do
				num = math.random(self.num2)
			end
			
			name_str = name_str..CONF.NAME.get(num).NAME

		end

		self.edit:setText(name_str)
	end
	rn:getChildByName("random"):addClickEventListener(function ( ... )
		random()
	end)

	random()

	local function recvMsg()
		--print("CityScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_LOGIN_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("LoginResp",strData)
			printInfo("LoginResp")
			printInfo(proto.result)

			if proto.result == "OK" then

				-- if self.type == "reg" then
				--     self.type = "log"
				--     GameHandler.handler_c.connect()
				-- else
                player:initInfo(proto)

                g_Player_Level = proto.user_info.level
				g_Player_Fight = player:getPower()
				-- end

				local user_id = cc.UserDefault:getInstance():getStringForKey("user_id")
				local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
                local username = self.edit:getText()
--				local url = string.format(g_create_player_url, user_id, server_id, self.edit:getText())
--				local xhr = cc.XMLHttpRequest:new()
--				xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
--				xhr:open("GET", url)
                -- post
                local data = "userid="..user_id.."&".."svrid="..server_id.."&".."rolename="..username
                local url = g_create_player_url
				local xhr = cc.XMLHttpRequest:new()
				xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
				xhr:open("POST", url)
				local function func()
					if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
				 
						print("Http Status Code:" .. xhr.statusText)

						local response = xhr.response
						local output = json.decode(response,1)
						if output.result == 0 then
							print("create ok")
							if( require("util.ExSDK"):getInstance():IsQuickSDK() ) then
								print("#### RegisterPlayerScene.lua create ok")
								-- Added by Wei Jingjun 20180601 for Dangle SDK bug
								Call_C_setQuickUserInfo()
							end
                            if device.platform == "ios" or device.platform == "android" then
                                TDGAMission:onCompleted("RegisterPlayer")
                                TDGAAccount:setAccountName(username)
                                TDGAAccount:setLevel(0)
                            end

						else
							print("create error:",output.result)
						end

					else
						print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
					end
					gl:releaseLoading()
					xhr:unregisterScriptHandler()

					local version = cc.UserDefault:getInstance():getStringForKey("server_version")
					local user_id = cc.UserDefault:getInstance():getStringForKey("user_id")
					GameHandler.handler_c.onLoginEvent(version, user_id)

					self:getApp():pushView("RegisterScene/RegisterShipScene")

				end

				xhr:registerScriptHandler(func)
--				xhr:send()
                xhr:send(data)
				gl:retainLoading()


			elseif proto.result == "NICKNAME_EXIST" then
				tips:tips(CONF:getStringValue("player_name_again"))
			elseif proto.result == "NICKNAME_ERR" then
				tips:tips(CONF:getStringValue("player_name_error"))
			elseif proto.result == "DIRTY" then
   				tips:tips(CONF:getStringValue("dirty_message"))
			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

end

function RegisterPlayerScene:onExitTransitionStart()
	printInfo("RegisterPlayerScene:onExitTransitionStart()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	-- self.edit:unregisterScriptEditBoxHandler()
	
end

return RegisterPlayerScene