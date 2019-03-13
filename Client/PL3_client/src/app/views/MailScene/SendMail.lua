local SendMail = class("SendMail", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

SendMail.RESOURCE_FILENAME = "MailLayer/SendMail.csb"

SendMail.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function SendMail:OnBtnClick(event)
	if event.name == "ended" then

		if event.target:getName() == "close" then

			self:removeFromParent()           
		end
	end

end

function SendMail:onEnterTransitionFinish()

	local eventDispatcher = self:getEventDispatcher()

	local function recvMsg()
		printInfo("ChatLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SEND_MAIL_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("SendMailResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				printInfo("send sucess")
				Tips:tips(CONF:getStringValue("Responsed_Successfully")) 
				self:removeFromParent()
				--rn:getChildByName("send_text"):setText("")                
			end
		end
	   
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function SendMail:addTitleEdit( name ,nameBg )
	local rn = self:getResourceNode()
	local placeHolder = rn:getChildByName(name)
	local placeHolderColor = placeHolder:getTextColor()
	local fontColor = placeHolder:getTextColor()
	local fontName = placeHolder:getFontName()
	local fontSize = placeHolder:getFontSize()
	local maxLength = placeHolder:getMaxLength()

	local back = rn:getChildByName(nameBg)
	
    --Changed By JinXin 20180625
	local editTitle = ccui.EditBox:create(back:boundingBox(), "aa")
	rn:addChild(editTitle)
	editTitle:setPosition(cc.p(back:getPosition()))
	editTitle:setAnchorPoint(cc.p(back:getAnchorPoint()))
	editTitle:setPlaceHolder(CONF:getStringValue("InputTitle"))
	editTitle:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
	editTitle:setPlaceholderFont(fontName,fontSize)
	editTitle:setPlaceholderFontColor(fontColor)
	editTitle:setFont(fontName,fontSize)
	editTitle:setFontColor(cc.c4b(255, 255, 255, 255))
	editTitle:setReturnType(1)
	editTitle:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	editTitle:setMaxLength(maxLength)
	editTitle:setName(name)

	placeHolder:removeFromParent()
end

function SendMail:addContentEdit(name, nameBg)
	local rn = self:getResourceNode()
	local placeHolder = rn:getChildByName(name)
	local placeHolderColor = placeHolder:getTextColor()
	local fontColor = placeHolder:getTextColor()
	local fontName = placeHolder:getFontName()
	local fontSize = placeHolder:getFontSize()
	local maxLength = placeHolder:getMaxLength()

	local back = rn:getChildByName(nameBg)
		
	local contentEdit = ccui.EditBox:create(back:getContentSize(), "aa")
	rn:addChild(contentEdit)
	contentEdit:setPosition(cc.p(back:getPosition()))
	contentEdit:setAnchorPoint(cc.p(back:getAnchorPoint()))
	contentEdit:setPlaceHolder(CONF:getStringValue("InputContent"))
	contentEdit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
	contentEdit:setPlaceholderFont(fontName,fontSize)
	contentEdit:setFontSize(0)
	contentEdit:setPlaceholderFontColor(fontColor)
	contentEdit:setFont(fontName,fontSize)
	contentEdit:setFontColor(fontColor)
	contentEdit:setReturnType(1)
	contentEdit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	contentEdit:setMaxLength(maxLength)
	contentEdit:setName("content")
	  
	placeHolder:removeFromParent()


	local contentLabel = cc.Label:createWithTTF("", "fonts/cuyabra.ttf", 20)
	contentLabel:setPosition(cc.p(back:getPosition()))
	contentLabel:setAnchorPoint(cc.p(back:getAnchorPoint()))
	contentLabel:setLineBreakWithoutSpace(true)
	contentLabel:setMaxLineWidth(530)
	contentLabel:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
	contentLabel:setName("contentLabel")
	-- contentLabel:enableShadow(cc.c4b(0, 0, 0, 255),cc.size(0.5,0.5))
	contentLabel:setTextColor(cc.c4b(255, 255, 255, 255))
	rn:addChild(contentLabel)

	local handler = function(event)  
		if event == "began" then   
			contentEdit:setFontColor(cc.c4b(0,0,0,0))
		end  
		  
		if event == "changed" then  
			local str =  contentEdit:getText()  
			contentLabel:setString(str)  
		end  
		  
		if event == "return" then  
		   local str =  contentEdit:getText()   
		   contentLabel:setString(str)  
		end  
	end  
		
	contentEdit:registerScriptEditBoxHandler(handler)  
end

function SendMail:init(name,id)
	self.receiver = name
	self.receiverId = id
	local rn = self:getResourceNode()
	rn:getChildByName("title1"):setString(CONF:getStringValue("title"))
	rn:getChildByName("content1"):setString(CONF:getStringValue("content"))
	rn:getChildByName("btnSend"):getChildByName("text"):setString(CONF:getStringValue("send"))

	rn:getChildByName("name"):setString(name)
	rn:getChildByName("warning"):setVisible(false)

	self:addTitleEdit("title", "titleBg")
	self:addContentEdit("content", "contentBg")
	
	rn:getChildByName("btnSend"):addClickEventListener(function (...)
		local title = rn:getChildByName("title"):getText()        
		local content = rn:getChildByName("content"):getText()

		if title == "" or content == "" then
			Tips:tips(CONF:getStringValue("ContentIsEmpty"))
		else
			for i=1,CONF.DIRTYWORD.len do
			  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
			  if string.find(title, CONF.DIRTYWORD[i].KEY) or string.find(content, CONF.DIRTYWORD[i].KEY) then
			  	Tips:tips(CONF:getStringValue("dirty_message"))
			  	return
			  end
			end

			local str = shuaiSubString(title)
			for i=1,CONF.DIRTYWORD.len do
			  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
			  if string.find(str, CONF.DIRTYWORD[i].KEY) then
			  	tips:tips(CONF:getStringValue("dirty_message"))
			  	return
			  end
			end

			local str = shuaiSubString(content)
			for i=1,CONF.DIRTYWORD.len do
			  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
			  if string.find(str, CONF.DIRTYWORD[i].KEY) then
			  	tips:tips(CONF:getStringValue("dirty_message"))
			  	return
			  end
			end

			local strData = Tools.encode("SendMailReq", {
				user_name = self.receiverId ,
				subject = title,
				message = content,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SEND_MAIL_REQ"),strData)
			gl:retainLoading()  
		end
	end)


	local function onTouchBegan( event, touch )
		return true
	end
	local eventDispatcher = self:getEventDispatcher()
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, rn)
end



function SendMail:onExitTransitionStart()
	printInfo("SendMail:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	local edit =self:getResourceNode():getChildByName("content")
	edit:unregisterScriptEditBoxHandler()

end

return SendMail