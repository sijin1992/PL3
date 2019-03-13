local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local LoginLayer = class("LoginLayer", cc.load("mvc").ViewBase)

LoginLayer.RESOURCE_FILENAME = "LoginScene/LoginLayer.csb"

LoginLayer.NEED_ADJUST_POSITION = true

LoginLayer.RESOURCE_BINDING = {
	["login"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local password = "password"

function LoginLayer:httpLoginUser()

	local res = self:getResourceNode()
	
	local editbox_1 = res:getChildByName("editbox_1")
	local editbox_2 = res:getChildByName("editbox_2")

	if editbox_1:getString() == "" then
		tips:tips(CONF.STRING.get("user_name_empty").VALUE)
		return
	end

	if editbox_2:getString() == "" then
		tips:tips(CONF.STRING.get("password_empty").VALUE)
		return
	end
	local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
	local url = string.format("%s?type=0&username=%s&password=%s&serverid=%s&lang=%d", g_login_server_url,editbox_1:getString(), editbox_2:getString(),server_id,server_platform)
	print("@@@LoginLayer:httpLoginUser",url)

	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xhr:open("GET", url)

	local function onReadyStateChanged()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
	 
			print("Http Status Code:" .. xhr.statusText)

			local response = xhr.response

			print("response",response)
			local output = json.decode(response,1)
			print(Tools.print_t(output))

			local result = tonumber(output.result )
			if result > 0 then
				local ud = cc.UserDefault:getInstance()
				ud:setStringForKey("username", editbox_1:getString())
				ud:setStringForKey("password", editbox_2:getString())
				ud:setStringForKey("user_id", string.format("%d", result))

				ud:setBoolForKey("isVisitor",  output.type == "0" and true or false)
				ud:flush()
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventCustom:new("login_update_user_info"))
			elseif result == -1 then
				tips:tips(CONF:getStringValue("ID_mistake"))
			else
				tips:tips(output.msg)
			end
			
		else
			print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
		end
		gl:releaseLoading()
		xhr:unregisterScriptHandler()

		if self:getApp() then
			self:getApp():removeTopView()
		end
		-- local app = require("app.MyApp"):getInstance()
		-- app:addView2Top("LoginScene/StartLayer", {ani = "stop"})
	end

	xhr:registerScriptHandler(onReadyStateChanged)
	xhr:send()
	gl:retainLoading()
end

function LoginLayer:OnBtnClick(event)

	if event.name == "ended" and event.target:getName() == "close" then
		animManager:runAnimOnceByCSB(self:getResourceNode(), "LoginScene/LoginLayer.csb", "animation0", function ( ... )
			self:getApp():removeTopView()
		end)
		

		-- local app = require("app.MyApp"):getInstance()
		-- app:addView2Top("LoginScene/StartLayer", {ani = "stop"})
	end

	if event.name == "ended" and event.target:getName() == "login" then

		local rn = self:getResourceNode()

		if rn:getChildByName("editbox_1"):getString() == "" then
			tips:tips(CONF:getStringValue("username_empty"))
			return
		end

		if rn:getChildByName("editbox_2"):getString() == "" then
			tips:tips(CONF:getStringValue("password_empty"))
			return
		end

		self:httpLoginUser()  
	end

end


function LoginLayer:onEnterTransitionFinish()
	printInfo("LoginLayer:onEnterTransitionFinish()")

	local res = self:getResourceNode()
	animManager:runAnimOnceByCSB(res, "LoginScene/LoginLayer.csb", "animation")
    animManager:runAnimByCSB(res:getChildByName("number"),"LoginScene/sfx/number/suzibofang.csb","1")
    animManager:runAnimByCSB(res:getChildByName("squres"),"LoginScene/sfx/squres/squres.csb","1")

	res:getChildByName("register"):getChildByName("text"):setString(CONF:getStringValue("create_account"))
	res:getChildByName("register"):addClickEventListener(function ( ... )
		self:getApp():removeTopView()

		local app = require("app.MyApp"):getInstance()
		app:addView2Top("LoginScene/RegisterLayer")
	end)
		
	res:getChildByName("layer_name"):setString(CONF:getStringValue("change user"))
	res:getChildByName("login"):getChildByName("text"):setString(CONF:getStringValue("login"))

	res:getChildByName("title_1"):setString(CONF:getStringValue("user_name")..":")
	res:getChildByName("title_2"):setString(CONF:getStringValue("password")..":")

	local function visitors_login( ... )

		local url = string.format("%s?type=2&devicecode=devicecode", g_login_server_url)

		local xhr = cc.XMLHttpRequest:new()
		xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
		xhr:open("GET", url)

		local function onReadyStateChanged()
			if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
		 
				print("Http Status Code:" .. xhr.statusText)

				local response = xhr.response
				local output = json.decode(response,1)
				print("output.result",output.result)
				if output.result > 0 then
					local ud = cc.UserDefault:getInstance()
					ud:setStringForKey("username", output.username)
					ud:setStringForKey("password", output.password)
					ud:setStringForKey("user_id", string.format("%d", output.result) )
					ud:setBoolForKey("isVisitor",  true)
					ud:flush()
			   
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventCustom:new("login_update_user_info"))
				-- elseif output.result == -2 then
				-- 	Tips:tips(CONF:getStringValue("ID_exist"))
				else
					tips:tips(output.msg)
				end
				
			else
				print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
			end
			gl:releaseLoading()
			xhr:unregisterScriptHandler()
			self:getApp():removeTopView()

		end

		xhr:registerScriptHandler(onReadyStateChanged)
		xhr:send()

		gl:retainLoading()
	end

	res:getChildByName("Text_tourist_login"):setString(CONF:getStringValue("visitors enter"))
	res:getChildByName("Text_tourist_login"):addClickEventListener(visitors_login)

	res:getChildByName("Text_password_retrieval"):setString(CONF:getStringValue("retrieve password"))
	res:getChildByName("Text_password_retrieval"):addClickEventListener(function ( ... )
		tips:tips(CONF:getStringValue("coming soon"))
	end)

    res:getChildByName("Text_tourist_register"):setString(CONF:getStringValue("create_account"))
    res:getChildByName("Text_tourist_register"):addClickEventListener(function ( ... )
		self:getApp():removeTopView()

		local app = require("app.MyApp"):getInstance()
		app:addView2Top("LoginScene/RegisterLayer")
	end)

	if cc.UserDefault:getInstance():getStringForKey("username") ~= "" and cc.UserDefault:getInstance():getStringForKey("username") ~= nil then
		res:getChildByName("TextField_1"):setString(cc.UserDefault:getInstance():getStringForKey("username"))
	end

	if cc.UserDefault:getInstance():getStringForKey("password") ~= "" and cc.UserDefault:getInstance():getStringForKey("password") ~= nil then
		res:getChildByName("TextField_2"):setString(cc.UserDefault:getInstance():getStringForKey("password"))
	end
	
	local placeHolder = res:getChildByName("input_text_1")
	local inputText = res:getChildByName("input_text_1")
	local placeHolderColor = placeHolder:getTextColor()
	local fontColor = inputText:getTextColor()
	local fontName = inputText:getFontName()
	local fontSize = inputText:getFontSize()

	-- for i=1,2 do

	-- 	local back = res:getChildByName(string.format("input_text_%d", i))
		

	-- 	local edit = ccui.EditBox:create(back:getContentSize(),"aa")
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
	-- 	edit:setReturnType(1)
	-- 	edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	-- 	edit:setName(string.format("editbox_%d", i))

	-- 	edit:setMaxLength(20)

	-- 	back:removeFromParent()
	-- end

	for i=1,2 do
	    local textField = res:getChildByName("TextField_"..i)
	    --textField:setPlaceholder(CONF:getStringValue("6-20 Characters"))

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

function LoginLayer:onExitTransitionStart()
	printInfo("LoginLayer:onExitTransitionStart()")

end

return LoginLayer