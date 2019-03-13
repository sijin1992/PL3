local MailLayer = class("OpenMail")

local gl = require("util.GlobalLoading"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()

function MailLayer:init(mail_info, scene)
	if mail_info == nil then
		return
	end
	self.mail = mail_info
	local mail_node = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/OpenMail.csb")
	local rn = mail_node:getChildByName('Node_info')
	setScreenPosition(mail_node:getChildByName('close'), "righttop")
	setScreenPosition(mail_node:getChildByName('Image_9'), "righttop")
	setScreenPosition(rn, "lefttop")

	mail_node:getChildByName('close'):addClickEventListener(function(event)
		mail_node:removeFromParent()
		end)
	rn:getChildByName("btnRemove"):addClickEventListener(function()
		local strData = Tools.encode("DelMailReq", {
			guid_list = {self.mail.guid},
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_DEL_MAIL_REQ"),strData)
		gl:retainLoading()
		end)
	rn:getChildByName('btnGet'):addClickEventListener(function(event)
		if self.mail.type == 10 then 

			local strData = Tools.encode("ReadMailReq", {
				guid = self.mail.guid,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_READ_MAIL_REQ"),strData)                
			gl:retainLoading()               
		elseif self.mail.type == 2 or self.mail.type == 3 then
			local sendLayer = require("app.views.MailScene.SendMail"):create()
            local center = cc.exports.VisibleRect:center()
	        sendLayer:setPosition(cc.p(center.x + (rn:getParent():getContentSize().width/2 - center.x), center.y + (rn:getParent():getContentSize().height/2 - center.y)))
			rn:getParent():addChild(sendLayer)
			sendLayer:init(self.mail.from,self.mail.from_user_name)

		elseif self.mail.type == 8 then
			local strData = Tools.encode("GroupJoinReq", {
				groupid = self.mail.message,
				type = 3,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOIN_REQ"),strData)
			gl:retainLoading()
		else
			self:removeFromParent() 
		end
		end)

	if self.mail.type == 0 or self.mail.type == 1 then 
		rn:getChildByName("sender"):setString(CONF:getStringValue("systemMail"))
		rn:getChildByName("btnGet"):setVisible(false)
	elseif self.mail.type == 2 or self.mail.type == 3 or self.mail.type == 8 then 
		rn:getChildByName("sender"):setString(string.format("%s",self.mail.from))
		rn:getChildByName("btnGet"):setVisible(true)
		if self.mail.type == 8 then
			rn:getChildByName("btnGet"):getChildByName("text"):setString(CONF:getStringValue("agree"))
			rn:getChildByName("btnRemove"):setVisible(true)
			rn:getChildByName("btnRemove"):getChildByName("text"):setString(CONF:getStringValue("delete"))
		else
			rn:getChildByName("btnGet"):getChildByName("text"):setString(CONF:getStringValue("response"))
		end
	elseif self.mail.type == 4 or self.mail.type == 5 then 
		rn:getChildByName("sender"):setString(string.format("%s", CONF:getStringValue("planetOccupation")))
		rn:getChildByName("btnGet"):setVisible(true)
		rn:getChildByName("btnGet"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	elseif self.mail.type == 10 then 
		rn:getChildByName("sender"):setString(CONF:getStringValue("systemMail"))
		rn:getChildByName("btnGet"):setVisible(true)
		rn:getChildByName("btnGet"):getChildByName("text"):setString(CONF:getStringValue("Get"))
	end
	local itemsNode = rn:getChildByName("itemsNode")
	for i,v in ipairs(self.mail.item_list) do
		local item = require("util.ItemNode"):create():init(v.id, v.num)
		itemsNode:addChild(item)

		item:setPosition(item:getChildByName("background"):getContentSize().width * (i-1) + 10, 0)
	end
	local title = rn:getChildByName("title")
	local titleText = rn:getChildByName("titleText")
	local content = rn:getChildByName("content")
	local contentText = rn:getChildByName("contentText")

	title:setString(CONF:getStringValue("title") .. ":")
	content:setString(CONF:getStringValue("content") .. ":")
	
	local titleRichText = createRichTextNeedChangeColor(self.mail.subject)
	titleRichText:setPosition(titleText:getPosition())
	titleRichText:setAnchorPoint(titleText:getAnchorPoint())
	rn:addChild(titleRichText)

	titleText:removeFromParent()

	local contentStr
	if self.mail.type == 8 then
		contentStr = self.mail.subject
	else
		contentStr = self.mail.message
	end


	local label = createRichTextNeedChangeColor(contentStr)
	label:setPosition(cc.p(contentText:getPosition()))
	label:setAnchorPoint(cc.p(0 , 1))
	label:ignoreContentAdaptWithSize(false)  
	label:setContentSize(contentText:getContentSize())
	rn:addChild(label)

	contentText:removeFromParent()
	-- local list = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(5,5), titleRichText:getContentSize())
	-- local list1 = require("util.ScrollViewDelegate"):create(rn:getChildByName("list1"),cc.size(5,5), label:getContentSize())
	-- list:addElement(titleRichText)
	-- list1:addElement(label)
	-- rn:getChildByName('list'):setScrollBarEnabled(false)
	-- rn:getChildByName('list1'):setScrollBarEnabled(false)
	-- if titleRichText:getContentSize().width <= rn:getChildByName('list'):getContentSize().width then
	-- 	rn:getChildByName('list'):setTouchEnabled(false)
	-- end
	-- if label:getContentSize().height <= rn:getChildByName('list1'):getContentSize().height then
	-- 	rn:getChildByName('list1'):setTouchEnabled(false)
	-- end
	-- contentText:removeFromParent()
    require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_MailGET(rn)
	return mail_node
end

return MailLayer