if not json then
	require("json")
end

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local RegisterLayer = class("RegisterLayer", cc.load("mvc").ViewBase)

RegisterLayer.RESOURCE_FILENAME = "LoginScene/RegisterLayer.csb"

RegisterLayer.NEED_ADJUST_POSITION = true

RegisterLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["confirm"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}


function RegisterLayer:httpRegisterUser()

	local Tips = require("util.TipsMessage"):getInstance()

	local res = self:getResourceNode()
	
	local editbox_1 = res:getChildByName("editbox_1")
	local editbox_2 = res:getChildByName("editbox_2")
	local editbox_3 = res:getChildByName("editbox_3")

	if editbox_1:getString() == "" then
		Tips:tips(CONF.STRING.get("user_name_empty").VALUE)
		return
	end

	if editbox_2:getString() == "" then
		Tips:tips(CONF.STRING.get("password_empty").VALUE)
		return
	end

	if editbox_3:getString() == "" then
		Tips:tips(CONF.STRING.get("password_again").VALUE)
		return
	end

	if string.len(editbox_1:getString()) < 6 or string.len(editbox_1:getString()) > 20 then
		Tips:tips(CONF.STRING.get("id_lenght").VALUE)
		return
	end

	if string.len(editbox_2:getString()) < 6 or string.len(editbox_2:getString()) > 20 then
		Tips:tips(CONF.STRING.get("password_lenght").VALUE)
		return
	end

	if string.len(editbox_3:getString()) < 6 or string.len(editbox_3:getString()) > 20 then
		Tips:tips(CONF.STRING.get("password_lenght").VALUE)
		return
	end

	if editbox_2:getString() ~= editbox_3:getString() then
		Tips:tips(CONF.STRING.get("password_diff").VALUE)
		return
	end

	local function checkString( str )
		for i=1,string.len(str) do
		
			local curByte = string.byte(str, i)

			if (curByte >= 48 and curByte <= 57) or (curByte >= 65 and curByte <= 90) or (curByte >= 97 and curByte <= 122) then

			else
				return false
			end
			
		end

		return true
	end

	if not checkString(editbox_1:getString()) or not checkString(editbox_2:getString()) or not checkString(editbox_3:getString()) then
		tips:tips(CONF.STRING.get("CreateWarning").VALUE)
		return
	end
	local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
	local url = string.format("%s?type=1&username=%s&password=%s&devicecode=devicecode&serverid=%s&lang=%d", g_login_server_url, editbox_1:getString(), editbox_2:getString(),server_id,server_platform)
	print("@@@RegisterLayer:httpRegisterUser",url)
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xhr:open("GET", url)

	local function onReadyStateChanged()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
	 
			print("Http Status Code:" .. xhr.statusText)

			local response = xhr.response
			local output = json.decode(response,1)
			print("output.result",output.result)
			if tonumber(output.result) > 0 then
				local ud = cc.UserDefault:getInstance()
				ud:setStringForKey("username", editbox_1:getString())
				ud:setStringForKey("password", editbox_2:getString())
				ud:setStringForKey("user_id", string.format("%d", output.result) )
				ud:setBoolForKey("isVisitor",  false)
				ud:flush()
		   
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventCustom:new("login_update_user_info"))
			elseif output.result == -2 then
				Tips:tips(CONF:getStringValue("ID_exist"))
			else
				Tips:tips(output.msg)
			end
			
		else
			print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
		end
		gl:releaseLoading()
		xhr:unregisterScriptHandler()
		self:getApp():removeTopView()

		-- local app = require("app.MyApp"):getInstance()
		-- app:addView2Top("LoginScene/StartLayer", {ani = "stop"})

	end

	xhr:registerScriptHandler(onReadyStateChanged)
	xhr:send()

	gl:retainLoading()
end

function RegisterLayer:OnBtnClick(event)
	printInfo(event.name)

 
	if event.name == "ended" and event.target:getName() == "close" then
		animManager:runAnimOnceByCSB(self:getResourceNode(), "LoginScene/RegisterLayer.csb", "animation0", function ( ... )
			self:getApp():removeTopView()
		end)

		-- local app = require("app.MyApp"):getInstance()
		-- app:addView2Top("LoginScene/StartLayer", {ani = "stop"})
	end

	if event.name == "ended" and event.target:getName() == "confirm" then

		local rn = self:getResourceNode()

		if rn:getChildByName("editbox_1"):getString() == "" then
			tips:tips(CONF:getStringValue("username_empty"))
			return
		end

		if rn:getChildByName("editbox_2"):getString() == "" or rn:getChildByName("editbox_3"):getString() == "" then
			tips:tips(CONF:getStringValue("password_empty"))
			return
		end

		if rn:getChildByName("editbox_2"):getString() ~= rn:getChildByName("editbox_3"):getString() then
			tips:tips(CONF:getStringValue("password_diff"))
			return
		end
		
		for i=2,3 do

			if string.len(rn:getChildByName("editbox_"..i):getString()) < 6 then
				tips:tips(CONF:getStringValue("password_short"))
				return

			end
		end

		self:httpRegisterUser()
	end
end


function RegisterLayer:onEnterTransitionFinish()
	printInfo("RegisterLayer:onEnterTransitionFinish()")

	local res = self:getResourceNode()
	animManager:runAnimOnceByCSB(res, "LoginScene/RegisterLayer.csb", "animation")
--    animManager:runAnimByCSB(res:getChildByName("number"),"LoginScene/sfx/number/suzibofang.csb","1")
--    animManager:runAnimByCSB(res:getChildByName("squres"),"LoginScene/sfx/squres/squres.csb","1")
	res:getChildByName("layer_name"):setString(CONF:getStringValue("create_account"))
	res:getChildByName("confirm"):getChildByName("text"):setString(CONF:getStringValue("register"))

	res:getChildByName("title_1"):setString(CONF:getStringValue("user_name")..":")
	res:getChildByName("title_2"):setString(CONF:getStringValue("password")..":")
	res:getChildByName("title_3"):setString(CONF:getStringValue("password_confirm")..":")
	
	local placeHolder = res:getChildByName("input_text_1")
	local inputText = res:getChildByName("input_text_1")
	local placeHolderColor = placeHolder:getTextColor()
	local fontColor = inputText:getTextColor()
	local fontName = inputText:getFontName()
	local fontSize = inputText:getFontSize()

	local function selectEditBox( tag, flag )
		if flag == true then
			for i=1,3 do
				print("i, tag", i, tag, i == tag)
				res:getChildByName(string.format("editbox_%d", i)):setEnabled(i == tag)
			end
		else
			for i=1,3 do
				res:getChildByName(string.format("editbox_%d", i)):setEnabled(true)
			end
		end
	end

	local function editBoxTextEventHandle(strEventName,pSender)
		local edit = pSender
		local strFmt 
		if strEventName == "began" then
			strFmt = string.format("editBox %p DidBegin !", edit)
			print(strFmt)
			selectEditBox(edit:getTag(), true)

		elseif strEventName == "ended" then
			strFmt = string.format("editBox %p DidEnd !", edit)
			print(strFmt)
		elseif strEventName == "return" then
			strFmt = string.format("editBox %p was returned !",edit)
			print(strFmt)
			selectEditBox(edit:getTag(), false)
		elseif strEventName == "changed" then
			strFmt = string.format("editBox %p TextChanged, text: %s ", edit, edit:getText())
			print(strFmt)
		else
			print(strEventName, edit:getName())
		end
	end

	-- for i=1,3 do

	-- 	local back = res:getChildByName(string.format("input_text_%d", i))

	-- 	local edit = cc.EditBox:create(back:getContentSize(),"aa")
	-- 	res:addChild(edit)
	-- 	edit:setPosition(cc.p(back:getPosition()))
	-- 	edit:setPlaceHolder(CONF:getStringValue(placeHolder:getString()))
		
	-- 	if i == 1 then
	-- 		edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
	-- 	else
	-- 		edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
	-- 	end

	-- 	edit:setPlaceholderFont(fontName,fontSize)
	-- 	edit:setPlaceholderFontColor(fontColor)
	-- 	edit:setFont(fontName,fontSize)
	-- 	edit:setFontColor(fontColor)
	-- 	edit:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
	-- 	edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	-- 	edit:setName(string.format("editbox_%d", i))
	-- 	edit:setTag(i)
	-- 	edit:registerScriptEditBoxHandler(editBoxTextEventHandle)

	-- 	edit:setMaxLength(20)

	-- 	back:removeFromParent()
	-- end

	for i=1,3 do
	    local textField = res:getChildByName("TextField_"..i)
	    -- textField:setPlaceHolder(CONF:getStringValue("6-20 Characters"))

	    textField:setName(string.format("editbox_%d", i))

		textField:addEventListener(function ( sender, eventType )
			
			if eventType == ccui.TextFiledEventType.attach_with_ime  then
				sender:setString("")
			end
		end)
	end

	-- placeHolder:removeFromParent()
	-- inputText:removeFromParent()
end

function RegisterLayer:onExitTransitionStart()
	printInfo("RegisterLayer:onExitTransitionStart()")
end

return RegisterLayer