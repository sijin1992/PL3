local g_player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local MailScene = class("MailScene", cc.load("mvc").ViewBase)

MailScene.RESOURCE_FILENAME = "MailLayer/MailLayer.csb"

MailScene.NEED_ADJUST_POSITION = true

MailScene.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["btnGetAll"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["btnDelAll"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function MailScene:onCreate(data)
	self._data = data
end

function MailScene:OnBtnClick(event)
	printInfo(event.name)
	if event.name == "ended" then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			-- self:getApp():pushToRootView("CityScene/CityScene", {pos = -350})

			if self.can_close then
				self:getApp():popView()
			end

			
		elseif event.target:getName() == "btnGetAll" then
			if Tools.isEmpty(self.mail_list_) == false then
				playEffectSound("sound/system/click.mp3")
				--self:getAll()
				self:getAllMail()
			end
		elseif event.target:getName() == "btnDelAll" then
			if Tools.isEmpty(self.mail_list_) == false then
				playEffectSound("sound/system/click.mp3")
				self:delAll()
				
			end
		end
	end
end

function MailScene:getAll()
	if Tools.isEmpty(self.mail_list_) then
		return false
	end
	if self.readAll == false then
		self.readNum = 0
	end
	self.readAll = true
	local isReaded = false
	for i,v in ipairs(self.mail_list_) do
		if v.type == 10 and self.selectType == "system" then
			isReaded = true
			local strData = Tools.encode("ReadMailReq", {
				guid = v.guid,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_READ_MAIL_REQ"),strData)                
			gl:retainLoading()

			if not self.readNum then
				self.readNum = 0
			end
			self.readNum = self.readNum + 1
			break
		end                       
	end
	if isReaded == false or self.readNum > 5 then
		self.readAll = false
	end
	return true
end

function MailScene:getAllMail()
	if Tools.isEmpty(self.mail_list_) then
		return false
	end
	local guid = {}
	for i,v in ipairs(self.mail_list_) do
		if v.type == 10 and self.selectType == "system" then
			table.insert(guid, v.guid)
		end
	end
	local strData = Tools.encode("ReadMailListReq", {
		guid = guid,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_READ_MAIL_LIST_REQ"),strData)                
	gl:retainLoading()
end

function MailScene:delAll(  )
	if Tools.isEmpty(self.mail_list_) then
		return
	end

	local id_list = {}

	for i,v in ipairs(self.mail_list_) do
		if v.type == 1 and self.selectType == "system" then          
			table.insert(id_list, v.guid) 
			local node = self:getResourceNode():getChildByName("list"):getChildByTag(v.guid)
			if node then
				self.svd_:removeElement(node)
			else
				print("remove error:",v.guid)
			end
		elseif v.type == 3 and self.selectType == "player" then 
			table.insert(id_list, v.guid) 
			local node = self:getResourceNode():getChildByName("list"):getChildByTag(v.guid)
			if node then
				self.svd_:removeElement(node)
			else
				print("remove error:",v.guid)
			end
		elseif v.type == 5 and v.planet_report.type == 1 and self.selectType == "planet"  then 
			table.insert(id_list, v.guid) 
			local node = self:getResourceNode():getChildByName("list"):getChildByTag(v.guid)
			if node then
				self.svd_:removeElement(node)
			else
				print("remove error:",v.guid)
			end
		elseif  v.type == 5 and v.planet_report.type == 4 and self.selectType == "planet2" then
			table.insert(id_list, v.guid) 
			local node = self:getResourceNode():getChildByName("list"):getChildByTag(v.guid)
			if node then
				self.svd_:removeElement(node)
			else
				print("remove error:",v.guid)
			end
		elseif  v.type == 5 and v.planet_report.type == 18 and self.selectType == "planet4" then
			table.insert(id_list, v.guid) 
			local node = self:getResourceNode():getChildByName("list"):getChildByTag(v.guid)
			if node then
				self.svd_:removeElement(node)
			else
				print("remove error:",v.guid)
			end
		elseif v.type == 5 and (v.planet_report.type ~= 1 and v.planet_report.type ~= 4 and v.planet_report.type ~= 18 ) and self.selectType == "planet3" then
			table.insert(id_list, v.guid) 
			local node = self:getResourceNode():getChildByName("list"):getChildByTag(v.guid)
			if node then
				self.svd_:removeElement(node)
			else
				print("remove error:",v.guid)
			end

		end
	end
  
	if Tools.isEmpty(id_list) == false then
		self:delMail(id_list)  
	else
		return
	end
	self.preTag = 0
end

function MailScene:createPlayerMailNode( mail )
	local node = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/player_mail_item.csb")
	local background = node:getChildByName("background")
	--background:getChildByName("star"):setVisible(false)
	background:getChildByName("notice"):setVisible(false)
	background:getChildByName("Text_6"):setString(CONF:getStringValue("sender"))
	local time_num = background:getChildByName("time_num")
	local time = background:getChildByName("time")
	local days = math.floor((g_player:getServerTime() - mail.stamp)/3600/24)

	if days <= 0 then
		time:setVisible(false)
		time_num:setVisible(false)
		background:getChildByName("today"):setVisible(true)
		background:getChildByName("today"):setString(CONF:getStringValue("today"))
	elseif days > 0 then
		time:setVisible(true)
		time:setString(CONF:getStringValue("daysAgo"))
		time_num:setVisible(true)
		background:getChildByName("today"):setVisible(false)
		time_num:setString(string.format("%d", days))
		time_num:setPositionX(time:getPositionX() - time:getContentSize().width - 5)
	end
	background:getChildByName("btnDel"):getChildByName("text"):setString(CONF:getStringValue("delete"))
	background:getChildByName("btnDel"):addClickEventListener(function (...)
		local node = self:getResourceNode():getChildByName("list"):getChildByTag(mail.guid)
		self.svd_:removeElement(node)
		self.preTag = 0
		local id_list = {mail.guid}
		self:delMail(id_list)
	end)

	if mail.type == 2 then
		background:getChildByName("mailClose"):setVisible(true)
		background:getChildByName("mailOpen"):setVisible(false)
		background:getChildByName("notice"):setVisible(true)
	elseif mail.type == 3 then
		background:getChildByName("mailClose"):setVisible(false)
		background:getChildByName("mailOpen"):setVisible(true)
		background:getChildByName("notice"):setVisible(false)
	elseif mail.type == 8 then
		background:getChildByName("mailClose"):setVisible(true)
		background:getChildByName("mailOpen"):setVisible(false)
		background:getChildByName("notice"):setVisible(true)
	end

	local rich_str = mail.subject == nil and "" or mail.subject

	local richText = createRichTextNeedChangeColor(rich_str)
	richText:setAnchorPoint(cc.p(background:getChildByName("title"):getAnchorPoint()))
	richText:setPosition(cc.p(background:getChildByName("title"):getPosition()))
	background:addChild(richText)

	background:getChildByName("title"):setVisible(false)
	background:getChildByName("senderName"):setString(mail.from)
	return node
end

function MailScene:createPlanetMailNode( mail )
	local node = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/system_mail_item.csb")
	local background = node:getChildByName("background")
	--background:getChildByName("star"):setVisible(false)
	background:getChildByName("notice"):setVisible(false)
	local time_num = background:getChildByName("time_num")
	local time = node:getChildByName("background"):getChildByName("time")
	local days = math.floor((g_player:getServerTime() - mail.stamp)/3600/24)
	-- if days < 0 then 
	-- 	print("time is error",days)
	-- 	return
	if days <= 0 then
		time:setVisible(false)
		time_num:setVisible(false)
		background:getChildByName("today"):setVisible(true)
		background:getChildByName("today"):setString(CONF:getStringValue("today"))
	elseif days > 0 then
		time:setVisible(true)
		time:setString(CONF:getStringValue("daysAgo"))
		time_num:setVisible(true)
		background:getChildByName("today"):setVisible(false)
		time_num:setString(string.format("%d", days))
		time_num:setPositionX(time:getPositionX() - time:getContentSize().width)
	end

	local function delete(  )
		local node = self:getResourceNode():getChildByName("list"):getChildByTag(mail.guid)
		self.svd_:removeElement(node)
		self.preTag = 0
		local id_list = {mail.guid}
		self:delMail(id_list)
	end

	background:getChildByName("btnDel"):getChildByName("text"):setString(CONF:getStringValue("delete"))
	background:getChildByName("btnDel"):addClickEventListener(function (sender)
		if mail.type ~= 10 then 
			delete()
		else 
			local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(CONF:getStringValue("makesureDel") ,delete)
		end
	end)
	if mail.type == 4 then
		background:getChildByName("mailClose"):setVisible(true)
		background:getChildByName("mailOpen"):setVisible(false)
		background:getChildByName("notice"):setVisible(true)
		--background:getChildByName("star"):setVisible(false)
	elseif mail.type == 5 then
		background:getChildByName("mailClose"):setVisible(false)
		background:getChildByName("mailOpen"):setVisible(true)
		background:getChildByName("notice"):setVisible(false)
		--background:getChildByName("star"):setVisible(false)
	end
	local rec_type = mail.planet_report.type
	local rich_str = ''
	if rec_type == 1 then
		rich_str = CONF:getStringValue('gather_report')
	elseif rec_type == 4 then
		rich_str = CONF:getStringValue('salve_report')
	elseif rec_type == 6 or rec_type == 15 then
		rich_str = CONF:getStringValue('scout_report')
	elseif rec_type == 5 then
		rich_str = CONF:getStringValue('destroy_report')
	elseif rec_type == 7 then
		rich_str = CONF:getStringValue('by_scout_report')
	elseif rec_type == 3 or rec_type == 8 or rec_type == 10 or rec_type == 12 or rec_type == 19 or rec_type == 21 then
		rich_str = CONF:getStringValue('attack_report')
	elseif rec_type == 2 or rec_type == 9 or rec_type == 11 or rec_type == 13 or rec_type == 20 or rec_type == 22 then
		rich_str = CONF:getStringValue('by_attack_report')
	elseif rec_type == 14 then
		rich_str = CONF:getStringValue('attack_report')
	elseif rec_type == 18 then
		rich_str = CONF:getStringValue('BATTLEFIELD REPORT TITLE')
	end
	local richText = createRichTextNeedChangeColor(rich_str)
	richText:setAnchorPoint(cc.p(background:getChildByName("title"):getAnchorPoint()))
	richText:setPosition(cc.p(background:getChildByName("title"):getPosition()))
	background:addChild(richText)

	background:getChildByName("title"):setVisible(false)
	return node
end

function MailScene:createSystemMailNode( mail )
	local node = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/system_mail_item.csb")
	local background = node:getChildByName("background")
	--background:getChildByName("star"):setVisible(false)
	background:getChildByName("notice"):setVisible(false)
	local time_num = background:getChildByName("time_num")
	local time = node:getChildByName("background"):getChildByName("time")
	local days = math.floor((g_player:getServerTime() - mail.stamp)/3600/24)
	-- if days < 0 then 
	-- 	print("time is error",days)
	-- 	return
	if days <= 0 then
		time:setVisible(false)
		time_num:setVisible(false)
		background:getChildByName("today"):setVisible(true)
		background:getChildByName("today"):setString(CONF:getStringValue("today"))
	elseif days > 0 then
		time:setVisible(true)
		time:setString(CONF:getStringValue("daysAgo"))
		time_num:setVisible(true)
		background:getChildByName("today"):setVisible(false)
		time_num:setString(string.format("%d", days))
		time_num:setPositionX(time:getPositionX() - time:getContentSize().width)
	end

   	local function delete(  )
		local node = self:getResourceNode():getChildByName("list"):getChildByTag(mail.guid)
		self.svd_:removeElement(node)
		self.preTag = 0
		local id_list = {mail.guid}
		self:delMail(id_list)
	end

	background:getChildByName("btnDel"):getChildByName("text"):setString(CONF:getStringValue("delete"))
	background:getChildByName("btnDel"):addClickEventListener(function (sender)
		if mail.type ~= 10 then 
			delete()
		else 
			local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(CONF:getStringValue("makesureDel") ,delete)
		end
	end)

	if mail.type == 0 then
		background:getChildByName("mailClose"):setVisible(true)
		background:getChildByName("mailOpen"):setVisible(false)
		background:getChildByName("notice"):setVisible(true)
		--background:getChildByName("star"):setVisible(false)
	elseif mail.type == 1 then
		background:getChildByName("mailClose"):setVisible(false)
		background:getChildByName("mailOpen"):setVisible(true)
		background:getChildByName("notice"):setVisible(false)
		--background:getChildByName("star"):setVisible(false)
	end
	if mail.type == 10 then
		--background:getChildByName("star"):setVisible(true)
		background:getChildByName("mailClose"):setVisible(true)
		background:getChildByName("notice"):setVisible(true)
		background:getChildByName("mailOpen"):setVisible(false)
	end

	local rich_str = mail.subject == nil and "" or mail.subject

	local richText = createRichTextNeedChangeColor(rich_str)
	richText:setAnchorPoint(cc.p(background:getChildByName("title"):getAnchorPoint()))
	richText:setPosition(cc.p(background:getChildByName("title"):getPosition()))
	background:addChild(richText)

	background:getChildByName("title"):setVisible(false)
	return node
end

function MailScene:resetList( typeName )
	local rn = self:getResourceNode()
	local leftPanel = rn:getChildByName("leftBg")
	local btnGetAll = rn:getChildByName("btnGetAll")
	local btnDelAll = rn:getChildByName("btnDelAll")

	self.svd_:clear()
	self.selcetedMail = 0 

	if Tools.isEmpty(self.mail_list_) then        
		leftPanel:getChildByName("planetNotice"):setVisible(false)
		leftPanel:getChildByName("planetNotice2"):setVisible(false)
		leftPanel:getChildByName("planetNotice3"):setVisible(false)
		leftPanel:getChildByName("planetNotice4"):setVisible(false)
		leftPanel:getChildByName("playerNotice"):setVisible(false)
		leftPanel:getChildByName("systemNotice"):setVisible(false)
		rn:getChildByName("textMailNum"):setString("0")
		rn:getChildByName("noMail"):setString(CONF:getStringValue("ListIsEmpty"))

		btnGetAll:setTouchEnabled(false)
		btnGetAll:setBright(false)
		btnGetAll:setEnabled(false)
		btnDelAll:setTouchEnabled(false)
		btnDelAll:setBright(false)
		btnDelAll:setEnabled(false)
		return       
	end

	--邮件排序 (未读在前，新收在前)
	local function isReaded( mail_info )
		if mail_info.type == 0 
		or mail_info.type == 2 
		or mail_info.type == 10 
		or mail_info.type == 8 
		or mail_info.type == 4 then
			return false
		end
		return true
	end

	local function sort( a,b )
		--未读的邮件 排在前面

		local flag_a = isReaded(a)
		local flag_b = isReaded(b)
		if flag_a == true and flag_b == false then
			return false
		elseif flag_a == false and flag_b == true then
			return true
		elseif flag_a == flag_b then --最新收到的邮件排在前面
			if a.stamp ~= b.stamp then
				if (a.stamp < b.stamp) then
					return false
				else
					return true
				end
			else
				return a.guid > b.guid
			end
		end
	end
	table.sort(self.mail_list_ , sort)

	local positionStartX = 0
	local offsetMax = 150
	local isTouch = false
	self.isMove = false
	self.preTag = 0
	local function onTouchBegan(touch, event)
		local target = event:getCurrentTarget()        
		self.resetMove = 1  
		self.moveDirection = 0
		rn:getChildByName("list"):setBounceEnabled(true)

		local sv_=rn:getChildByName("list")
		local locationInNode = sv_:convertToNodeSpace(touch:getLocation())
		local sv_s = sv_:getContentSize()
		local sv_rect = cc.rect(0, 0, sv_s.width, sv_s.height)
		if cc.rectContainsPoint(sv_rect, locationInNode) then          
			local ln = target:convertToNodeSpace(touch:getLocation())
			local s = target:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)
			if cc.rectContainsPoint(rect, ln) then
				self.beginLocation = target:convertToNodeSpace(touch:getLocation())
				isTouch = true
				if self.preTag == 0 then 
					self.preTag = target:getParent():getTag()
				end
				return true
			end
		end
		return false
	end

	local function onTouchMoved(touch, event)
		--在水平（1） 和 竖直（2）方向 移动互斥
		--touch结束前，只在最开始判断一次，touchBegan 里重置判断条件；


		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			isTouch = false
			if self.moveDirection == 2 then
				return true
			end
			local target = event:getCurrentTarget()
			local ln = target:convertToNodeSpace(touch:getLocation())
			local offsetX = ln.x - self.beginLocation.x
			local offsetY = ln.y - self.beginLocation.y
			if self.resetMove == 1 then
				if math.abs(offsetX) > math.abs(offsetY) then
					 self.moveDirection = 1
					 rn:getChildByName("list"):setBounceEnabled(false)
					 if self.isMove and self.preTag ~= 0 then 
						rn:getChildByName("list"):getChildByTag(self.preTag):getChildByName("background"):setPositionX(positionStartX)
						self.preTag = target:getParent():getTag()
						self.isMove = false
					end
				else 
					 self.moveDirection = 2
				end
				self.resetMove = 0
			end
		   
			if self.moveDirection == 2 then
				return true
			end
			local posX = target:getPositionX() + offsetX
			if positionStartX - posX < 0 then 
				target:setPositionX(positionStartX)
			elseif positionStartX - posX > offsetMax then
				target:setPositionX(positionStartX - offsetMax)           
			else 
				target:setPositionX(posX)
			end
		end
		
		return true
	end

	local function onTouchEnded(touch, event)
		local target = event:getCurrentTarget()
		local offsetX = positionStartX - target:getPositionX() 
		if self.moveDirection == 2 and self.isMove then
			rn:getChildByName("list"):getChildByTag(self.preTag):getChildByName("background"):setPositionX(positionStartX)
			self.isMove = false
		elseif self.moveDirection == 1 then
			if offsetX >= offsetMax/2 and offsetX <= offsetMax then
				target:setPositionX(positionStartX - offsetMax)
				self.isMove = true 
				self.preTag = target:getParent():getTag()
			elseif offsetX < offsetMax/2 and offsetX > 0 then
				target:setPositionX(positionStartX)
				self.isMove = false 
			end
		end
		if isTouch then
			if self.isMove then 
				rn:getChildByName("list"):getChildByTag(self.preTag):getChildByName("background"):setPositionX(positionStartX)
				self.isMove = false 
			end
			self:readMail(target:getParent():getTag()) 
		end
	end

	

	local eventDispatcher = self:getEventDispatcher()
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

	local mailNum = 0
	local playerMailClose = 0
	local systemMailClose = 0
	local planetMailClose = 0
	local planetMailClose2 = 0
	local planetMailClose3 = 0
	local planetMailClose4 = 0
	local enclosure = 0 --附件
	for i,v in ipairs(self.mail_list_) do

		if v.type == 2 or v.type == 8 then 
			playerMailClose = playerMailClose + 1
		elseif v.type == 0 then 
			systemMailClose = systemMailClose +1
		elseif v.type == 4 then 
			if v.planet_report.type == 1 then
				planetMailClose = planetMailClose + 1
			elseif v.planet_report.type == 4 then
				planetMailClose2 = planetMailClose2 + 1
			elseif v.planet_report.type == 18 then
				planetMailClose4 = planetMailClose4 + 1
			else
				planetMailClose3 = planetMailClose3 + 1
			end
		elseif v.type == 10 then 
			enclosure = enclosure +1
			--附件邮件 也是系统邮件
			systemMailClose = systemMailClose +1
		end

		if typeName == "system"  and (v.type == 0 or v.type == 1 or v.type == 10) then 
			mailNum = mailNum + 1
			local mailNode = self:createSystemMailNode(v)   
			mailNode:setTag(v.guid)
			self.svd_:addElement(mailNode)
			eventDispatcher:addEventListenerWithSceneGraphPriority(listener:clone(), mailNode:getChildByName("background"))
		elseif typeName == "player" and (v.type == 2 or v.type == 3 or v.type == 8) then
			mailNum = mailNum + 1
			local mailNode = self:createPlayerMailNode(v)   
			if mailNode then
				mailNode:setTag(v.guid)
				self.svd_:addElement(mailNode)
				eventDispatcher:addEventListenerWithSceneGraphPriority(listener:clone(), mailNode:getChildByName("background"))
			end
		elseif typeName == "planet" and (v.type == 4 or v.type == 5) and v.planet_report.type == 1 then
			mailNum = mailNum + 1
			local mailNode = self:createPlanetMailNode(v)   

			mailNode:setTag(v.guid)
			self.svd_:addElement(mailNode)
			eventDispatcher:addEventListenerWithSceneGraphPriority(listener:clone(), mailNode:getChildByName("background"))
		elseif typeName == "planet2" and (v.type == 4 or v.type == 5) and (v.planet_report.type == 4) then
			mailNum = mailNum + 1
			local mailNode = self:createPlanetMailNode(v)   

			mailNode:setTag(v.guid)
			self.svd_:addElement(mailNode)
			eventDispatcher:addEventListenerWithSceneGraphPriority(listener:clone(), mailNode:getChildByName("background"))
		elseif typeName == "planet4" and (v.type == 4 or v.type == 5) and (v.planet_report.type == 18) then
			mailNum = mailNum + 1
			local mailNode = self:createPlanetMailNode(v)   

			mailNode:setTag(v.guid)
			self.svd_:addElement(mailNode)
			eventDispatcher:addEventListenerWithSceneGraphPriority(listener:clone(), mailNode:getChildByName("background"))
		elseif typeName == "planet3" and (v.type == 4 or v.type == 5) and v.planet_report.type ~= 1 and v.planet_report.type ~= 4 and v.planet_report.type ~= 18 then
			mailNum = mailNum + 1
			local mailNode = self:createPlanetMailNode(v)   

			mailNode:setTag(v.guid)
			self.svd_:addElement(mailNode)
			eventDispatcher:addEventListenerWithSceneGraphPriority(listener:clone(), mailNode:getChildByName("background"))

		end
	end

	--新邮件提示
	local function setNotice(num ,name )
		local notice = leftPanel:getChildByName(name)
		if num == 0 then
			notice:setVisible(false)
		else 
			notice:setVisible(true)
		end
	end
	setNotice(systemMailClose ,"systemNotice")
	setNotice(playerMailClose ,"playerNotice")
	setNotice(planetMailClose ,"planetNotice")
	setNotice(planetMailClose2 ,"planetNotice2")
	setNotice(planetMailClose3 ,"planetNotice3")
	setNotice(planetMailClose4 ,"planetNotice4")

	if enclosure ~= 0 and typeName == "system" then    
		btnGetAll:setTouchEnabled(true)
		btnGetAll:setBright(true)
		btnGetAll:setEnabled(true)
	else 
		rn:getChildByName("btnGetAll"):setTouchEnabled(false)
		rn:getChildByName("btnGetAll"):setBright(false)
		rn:getChildByName("btnGetAll"):setEnabled(false)
	end

	if mailNum ==0 then
		self:getResourceNode():getChildByName("noMail"):setString(CONF:getStringValue("ListIsEmpty"))
		self:getResourceNode():getChildByName("textMailNum"):setString("0")
		btnDelAll:setTouchEnabled(false)
		btnDelAll:setBright(false)
		btnDelAll:setEnabled(false)
	else 
		self:getResourceNode():getChildByName("noMail"):setString("")
		self:getResourceNode():getChildByName("textMailNum"):setString(string.format("%s",mailNum))
		btnDelAll:setTouchEnabled(true)
		btnDelAll:setBright(true)
		btnDelAll:setEnabled(true)
	end

end

function MailScene:delMail( id_list, noLoading )

	for i,v in ipairs(id_list) do
		local mail = self:getMail(v)

		local str_1 = mail.subject.."-"..mail.guid.."-"..mail.from.."-(item:"
		for i,v in ipairs(mail.item_list) do
			str_1 = str_1.."id:"..mail.id.."num:"..mail.num.." "
		end

		str_1 = str_1..")"

		local str_2 = "delete_time:"..getNowDateString()
		flurryLogEvent("delete_system_mail", {info1 = str1, info2 = str_2})
	end

	local strData = Tools.encode("DelMailReq", {
		guid_list = id_list,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_DEL_MAIL_REQ"),strData)
	if noLoading == true then
		
	else
		gl:retainLoading()
	end
end

function MailScene:getMail( guid )

	if Tools.isEmpty(self.mail_list_) == true then
		return nil
	end
	for i,v in ipairs(self.mail_list_) do
		if v.guid == guid then 
			return v
		end
	end
	return nil
end

function MailScene:readMail( id )
	self.getItemMail = nil 
	local mailType = -1
	local mail  = {}
	for i,v in ipairs(self.mail_list_) do
		if v.guid == id then 
			mailType = v.type
			mail = v
			break
		end
	end

	local rn = self:getResourceNode()
	if mailType == 1 or mailType == 3 or mailType == 10 or mailType == 8 then 
		local mailLayer = require("app.views.MailScene.OpenMail"):init(self:getMail(id))
		mailLayer:setName('MailDetailNode')
		rn:addChild(mailLayer)
		if mailType == 10 then 
			self.getItemMail = mailLayer
		end
	elseif mailType == 0 or mailType == 2 or mailType == 4  then 
		local strData = Tools.encode("ReadMailReq", {
			guid = id,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_READ_MAIL_REQ"),strData)
		gl:retainLoading()

		local node = rn:getChildByName("list"):getChildByTag(id)
		if node then 
			node:getChildByName("background"):getChildByName("mailClose"):setVisible(false)
			node:getChildByName("background"):getChildByName("mailOpen"):setVisible(true)
			node:getChildByName("background"):getChildByName("notice"):setVisible(false)
			--node:getChildByName("background"):getChildByName("star"):setVisible(false)
		end
	elseif mailType == 5 then
		if rn:getChildByName('MailDetailNode') then
			rn:getChildByName('MailDetailNode'):removeFromParent()
		end
		if mail.planet_report.type == 1 then
			local node = require("app.views.MailScene.MailDetail.MailDetailType_res"):initMailDetail(self:getMail(id),self._data)
			node:setName('MailDetailNode')
			rn:addChild(node)
		elseif mail.planet_report.type == 4 then
			local node = require("app.views.MailScene.MailDetail.MailDetailType_ruins"):initMailDetail(self:getMail(id),self._data)
			node:setName('MailDetailNode')
			rn:addChild(node)
		elseif mail.planet_report.type ~= 1 and mail.planet_report.type ~= 4 then
			local node
			if mail.planet_report.type == 10 or mail.planet_report.type == 2 or mail.planet_report.type == 3 or mail.planet_report.type == 8 or mail.planet_report.type == 9 or mail.planet_report.type == 11 then 
				node = require("app.views.MailScene.MailDetail.MailDetailAttackType_others"):initMailDetail(self:getMail(id),self._data)
			elseif mail.planet_report.type == 7 then
				node = require("app.views.MailScene.MailDetail.MailDetailType_spy"):initMailDetail(self:getMail(id),self._data)
			elseif mail.planet_report.type == 5 then
				node = require("app.views.MailScene.MailDetail.MailDetailAttackType_ruins"):initMailDetail(self:getMail(id),self._data)
			elseif mail.planet_report.type == 6 then
				node = require("app.views.MailScene.MailDetail.MailDetailAttackType_spy"):initMailDetail(self:getMail(id),self._data)
			elseif mail.planet_report.type == 12 or mail.planet_report.type == 13 or mail.planet_report.type == 19 or mail.planet_report.type == 20 or mail.planet_report.type == 21 or mail.planet_report.type == 22 then
				node = require("app.views.MailScene.MailDetail.MailDetailAttackType_city"):initMailDetail(self:getMail(id),self._data)
			elseif mail.planet_report.type == 15 then
				node = require("app.views.MailScene.MailDetail.MailDetailAttackType_citySpy"):initMailDetail(self:getMail(id),self._data)
			elseif mail.planet_report.type == 14 then
				if mail.planet_report.result then
					node = require("app.views.MailScene.MailDetail.MailDetailAttackType_boss"):initMailDetail(self:getMail(id),self._data)
				else
					node = require("app.views.MailScene.MailDetail.MailDetailAttackType_bossFail"):initMailDetail(self:getMail(id),self._data)
				end
			elseif mail.planet_report.type == 16 or mail.planet_report.type == 17 then
				node = require("app.views.MailScene.MailDetail.MailDetailAttackType_fail"):initMailDetail(self:getMail(id),self._data)
			elseif mail.planet_report.type == 18 then
				node = require("app.views.MailScene.MailDetail.MailDetailAttackType_field"):initMailDetail(mail,self._data)
			end
			if node then
				node:setName('MailDetailNode')
				node:setPositionX(19)
				rn:addChild(node)
			end
		end
	end       
end

function MailScene:setData(  )
	self.labels = {"system" ,"player" ,"planet","planet2","planet3","planet4"}
	local rn = self:getResourceNode()
	local leftPanel = rn:getChildByName("leftBg")

	rn:getChildByName("mailPanel"):setString(CONF:getStringValue("mail"))
	rn:getChildByName("mailNum"):setString(CONF:getStringValue("mailNum"))
	rn:getChildByName("btnDelAll"):getChildByName("text"):setString(CONF:getStringValue("delAll"))
	rn:getChildByName("btnGetAll"):getChildByName("text"):setString(CONF:getStringValue("getAll"))
	leftPanel:getChildByName("system_text"):setString(CONF:getStringValue("systemMail"))
	leftPanel:getChildByName("player_text"):setString(CONF:getStringValue("playerMail")) 
	leftPanel:getChildByName("planet_text"):setString(CONF:getStringValue("Resource information"))
	leftPanel:getChildByName("planet2_text"):setString(CONF:getStringValue("Salvage information"))
	leftPanel:getChildByName("planet3_text"):setString(CONF:getStringValue("Attack information"))
	leftPanel:getChildByName("planet4_text"):setString(CONF:getStringValue("CREEPS BATTLEFIELD REPORT"))

	local lineTop = rn:getChildByName("lineTop")
	local lineBottom = rn:getChildByName("lineBottom")
	local list = rn:getChildByName("list")
	local btn = rn:getChildByName("btnDelAll")
	lineBottom:setPositionY(btn:getPositionY() + 25)
	local  height  = lineTop:getPositionY() - lineBottom:getPositionY() - 25
	list:setContentSize(cc.size(list:getContentSize().width ,height))
	list:setPositionY(lineTop:getPositionY() - 15)
	local mailNum = rn:getChildByName("mailNum")
	local textMailNum = rn:getChildByName("textMailNum")
	textMailNum:setPositionX(mailNum:getContentSize().width + mailNum:getPositionX() + 7)
	rn:getChildByName("sumMail"):setPositionX(textMailNum:getContentSize().width + textMailNum:getPositionX() )

	self.mail_list_ = {}
	self.readAll = false 
end

function MailScene:onEnterTransitionFinish()
	self.can_close = false

	local rn = self:getResourceNode()
	self:setData()

	local eventDispatcher = self:getEventDispatcher()
	local strData = Tools.encode("GetMailListReq", {
		num = 0,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)
	gl:retainLoading()

	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(0,10), cc.size(814,100))

	self:addTouch()
	self.selectType = self.labels[1]
	if self._data and self._data.type == 'video' then
		local ctype = true
		if self._data.id then
			local mailInfo = self:getMail(self._data.id)
			if mailInfo then
				if mailInfo.type == 18 then
					ctype = false
				end
			end
		end
		if ctype then
			self.selectType = self.labels[5]
		else
			self.selectType = self.labels[6]
		end
	end
	self:changeType()

	local function recvMsg()
		print("MailScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		-- 获得邮件列表
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_RESP") then
			gl:releaseLoading()          
			local proto = Tools.decode("GetMailListResp",strData)
		   	self.can_close = true
			if proto.result ~= 0 then
				printInfo("proto error")  
			else  
				self.mail_list_ = proto.user_sync.mail_list
				-- g_player.mail_list_ = proto.user_sync.mail_list
				self:resetList(self.selectType)
				if g_MailGuid_VideoPosition ~= '' then
					local guid = tonumber(Tools.split(g_MailGuid_VideoPosition,'_')[1])
					for k,v in ipairs(self.mail_list_) do
						if v.guid == guid then
							if self._data and self._data.type == 'video' then
								self:readMail( guid )
							end
							break
						end
					end
				end

				for i,v in ipairs(proto.user_sync.mail_list) do
					if v.type == 0 or v.type == 1 or v.type == 10 then
						local str_1 = v.subject.."-"..v.guid.."-"..v.from.."-(item:"
						for i,v in ipairs(v.item_list) do
							str_1 = str_1.."id:"..v.id.."num:"..v.num.." "
						end

						str_1 = str_1..")"

						local str_2 = "get_time:"..getNowDateString(v.stamp)

						flurryLogEvent("get_system_mail", {info1 = str1, info2 = str_2})
					end
				end
			end
		--有新邮件 更新列表
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_MAIL_LIST_UPDATE") then

			local strData = Tools.encode("GetMailListReq", {
				num = 0,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)
			gl:retainLoading()
		--获取邮件内容 读邮件
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_READ_MAIL_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("ReadMailResp",strData)
		   
			if proto.result ~= 0 then
				print("proto error",proto.result)  
			else  
				-- g_player.mail_list_ = proto.user_sync.mail_list
				self.mail_list_ = proto.user_sync.mail_list
				self:resetList(self.selectType)

				if self.readAll then
					if self:getAll() == false then
						--self:resetList(self.selectType)	
					end
				elseif self.getItemMail then --如果已经打开附件邮件，点击领取后，关闭邮件
					--self:resetList(self.selectType)
					self.getItemMail:removeFromParent()
					self.getItemMail = nil
				else
					--self:resetList(self.selectType)
					local mail = self:getMail( proto.req.guid )
					if mail and mail.type == 5 then
						if rn:getChildByName('MailDetailNode') then
							rn:getChildByName('MailDetailNode'):removeFromParent()
						end
						if mail.planet_report.type == 1 then
							local str_1 = mail.subject.."-"..mail.guid.."-"..mail.from.."-(item:"
							for i,v in ipairs(mail.item_list) do
								str_1 = str_1.."id:"..v.id.."num:"..v.num.." "
							end

							str_1 = str_1..")"

							local str_2 = "read_time:"..getNowDateString()
							flurryLogEvent("read_system_mail", {info1 = str1, info2 = str_2})

							local node = require("app.views.MailScene.MailDetail.MailDetailType_res"):initMailDetail(mail,self._data)
							node:setName('MailDetailNode')
							rn:addChild(node)
						elseif mail.planet_report.type == 4 then
							local node = require("app.views.MailScene.MailDetail.MailDetailType_ruins"):initMailDetail(mail,self._data)
							node:setName('MailDetailNode')
							rn:addChild(node)
						elseif mail.planet_report.type ~= 1 and mail.planet_report.type ~= 4 then
							local node
							if mail.planet_report.type == 10 or mail.planet_report.type == 2 or mail.planet_report.type == 3 or mail.planet_report.type == 8 or mail.planet_report.type == 9 or mail.planet_report.type == 11 then 
								node = require("app.views.MailScene.MailDetail.MailDetailAttackType_others"):initMailDetail(mail,self._data)
							elseif mail.planet_report.type == 7 then
								node = require("app.views.MailScene.MailDetail.MailDetailType_spy"):initMailDetail(mail,self._data)
							elseif mail.planet_report.type == 5 then
								node = require("app.views.MailScene.MailDetail.MailDetailAttackType_ruins"):initMailDetail(mail,self._data)
							elseif mail.planet_report.type == 6 then
								node = require("app.views.MailScene.MailDetail.MailDetailAttackType_spy"):initMailDetail(mail,self._data)
							elseif mail.planet_report.type == 12 or mail.planet_report.type == 13 or mail.planet_report.type == 19 or mail.planet_report.type == 20 or mail.planet_report.type == 21 or mail.planet_report.type == 22 then
								node = require("app.views.MailScene.MailDetail.MailDetailAttackType_city"):initMailDetail(mail,self._data)
							elseif mail.planet_report.type == 15 then
								node = require("app.views.MailScene.MailDetail.MailDetailAttackType_citySpy"):initMailDetail(mail,self._data)
							elseif mail.planet_report.type == 14 then
								if mail.planet_report.result then
									node = require("app.views.MailScene.MailDetail.MailDetailAttackType_boss"):initMailDetail(mail,self._data)
								else
									node = require("app.views.MailScene.MailDetail.MailDetailAttackType_bossFail"):initMailDetail(mail,self._data)
								end
							elseif mail.planet_report.type == 16 or mail.planet_report.type == 17 then
								node = require("app.views.MailScene.MailDetail.MailDetailAttackType_fail"):initMailDetail(mail,self._data)
							elseif mail.planet_report.type == 18 then
								node = require("app.views.MailScene.MailDetail.MailDetailAttackType_field"):initMailDetail(mail,self._data)	
							end
							if node then
								node:setName('MailDetailNode')
								node:setPositionX(19)
								rn:addChild(node)
							end
						end
					else
						local mailLayer = require("app.views.MailScene.OpenMail"):init(mail)
						if mailLayer then
							mailLayer:setName('MailDetailNode')
							rn:addChild(mailLayer)
						end
					end
				end
				

				if  Tools.isEmpty(proto.get_item_list) == false then
					local items = {}
					for i,v in ipairs(proto.get_item_list) do
						table.insert(items, {id = v.key, num = v.value})
					end
					local node = require("util.RewardNode"):createGettedNodeWithList(items)
					tipsAction(node)
					node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(node)
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_READ_MAIL_LIST_RESP") then
			print("11111111111111111111111111")
			gl:releaseLoading()
			
			local proto = Tools.decode("ReadMailListResp",strData)
		   print("222222222222222222222222222")
			if proto.result ~= 0 then
				print("proto error",proto.result)  
			else  
				self.mail_list_ = proto.user_sync.mail_list
				self:resetList(self.selectType)				
				print("33333333333333333333333")
				if  Tools.isEmpty(proto.get_item_list) == false then
					print("44444444444444444444444")
					local items = {}
					for i,v in ipairs(proto.get_item_list) do
						table.insert(items, {id = v.key, num = v.value})
					end
					print("5555555555555555555555")
					local node = require("util.RewardNode"):createGettedNodeWithList(items)
					tipsAction(node)
					node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(node)
					print("666666666666666666666666")
				end
			end

		--删除邮件
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_DEL_MAIL_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("DelMailResp",strData)          
			if proto.result ~= 0 then
				print("error",proto.result)
				printInfo("proto error")  
			else
				-- Tips:tips(CONF:getStringValue("Deleted_Successfully"))  
				-- g_player.mail_list_ = proto.user_sync.mail_list
				self.mail_list_ = proto.user_sync.mail_list
				self:resetList(self.selectType)
			end

		-- 邮件战斗回放
		elseif cmd == Tools.enum_id('CMD_DEFINE','CMD_PVP_VIDEO_RESP') then
			local proto = Tools.decode("PvpVideoResp",strData)
			if proto.result == 0 then
				if Tools.isEmpty(proto.data) then return end
				local guid = tonumber(Tools.split(g_MailGuid_VideoPosition,'_')[1])
				local mail = self:getMail(guid )
				if Tools.isEmpty(proto.data.resp) == false and Tools.isEmpty(proto.data.resp.hurter_list) == false and Tools.isEmpty(proto.data.resp.attack_list) == false then
					local enemyName
					local enemyIconPath
					local myName
					local myIconPath
					local switchGroup1 = false
					if Tools.isEmpty(mail) == false and Tools.isEmpty(mail.planet_report) == false then
						local exchange = false
						if mail.planet_report.type == 2 or mail.planet_report.type == 7 or  mail.planet_report.type == 9 or  mail.planet_report.type == 11 or  mail.planet_report.type == 13 then
							exchange = true
							switchGroup1 = true
						end
						if mail.planet_report.type == 14 then
							local cfg_boss = CONF.PLANETBOSS.get(mail.planet_report.id)
							enemyName = CONF:getStringValue(cfg_boss.NAME)
							enemyIconPath = getEnemyIcon(cfg_boss.MONSTER_LIST)
						elseif mail.planet_report.type == 12 or mail.planet_report.type == 8 then
							local cfg_city = CONF.PLANETCITY.get(mail.planet_report.id)
							enemyIconPath = getEnemyIcon(cfg_city.MONSTER_LIST)
							enemyName = CONF:getStringValue(cfg_city.NAME)
						elseif mail.planet_report.type == 5 then
							local cfg_ruins = CONF.PLANET_RUINS.get(mail.planet_report.id)
							enemyIconPath = getEnemyIcon(cfg_ruins.MONSTER_LIST)
							enemyName = CONF:getStringValue(cfg_ruins.NAME)
						elseif mail.planet_report.type == 18 then
							local cfg_field = CONF.PLANETCREEPS.get(mail.planet_report.id)
							enemyIconPath = getEnemyIcon(cfg_field.MONSTER_LIST)
							enemyName = CONF:getStringValue(cfg_field.NAME)
						end
						if Tools.isEmpty(mail.planet_report.enemy_data_list) == false then
							if Tools.isEmpty(mail.planet_report.enemy_data_list[1].info) == false then
								enemyName = mail.planet_report.enemy_data_list[1].info.nickname
								enemyIconPath = "HeroImage/"..mail.planet_report.enemy_data_list[1].info.icon_id..".png"
							end
						end
						if Tools.isEmpty(mail.planet_report.my_data_list) == false and Tools.isEmpty(mail.planet_report.my_data_list[1].info) == false then
							myName = mail.planet_report.my_data_list[1].info.nickname
							myIconPath = "HeroImage/"..mail.planet_report.my_data_list[1].info.icon_id..".png"
						end
					end
					self:getApp():pushToRootView("BattleScene/BattleScene", { 
						from = self._data.from, 
						switchGroup = switchGroup1,
						BattleType.kMailVideo, 
						Tools.decode("PvpVideoResp",strData).data.resp, 
						false,
						enemyName,
						enemyIconPath,
						nil,
						myName,
						myIconPath,
					})
				end
			end
		
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOIN_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupJoinResp",strData)
			if proto.result == "OK" then
				self:delMail({self.preTag},true)
				self:getApp():pushView("StarLeagueScene/StarLeagueScene")
			elseif proto.result == "NO_CONDITION" then
				Tips:tips(CONF:getStringValue("no_condition"))
			elseif proto.result == "USER_COUNT_MAX" then
				Tips:tips(CONF:getStringValue("group_count_max"))
			elseif proto.result == "NO_NUMS" then
				Tips:tips(CONF:getStringValue("group_join_max"))
			elseif proto.result == "NO_TIME" then
				Tips:tips(CONF:getStringValue("group_join_cd"))
			else
				Tips:tips(CONF:getStringValue("group_join_disband"))
				self:delMail({self.preTag},true)
				if rn:getChildByName('MailDetailNode') then
					rn:getChildByName('MailDetailNode'):removeFromParent()
				end
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local   eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	--animManager:runAnimOnceByCSB(rn,"MailLayer/MailLayer.csb" ,"intro")

    require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Mail(self)
end

function MailScene:changeType()
	local textTab =  {"system_text","player_text","planet_text","planet2_text","planet3_text","planet4_text"}
	local rn = self:getResourceNode()
	local leftPanel = rn:getChildByName("leftBg")
	local node = leftPanel:getChildByName(self.selectType)
	-- node:getChildByName("normal"):setVisible(true)
	-- node:getChildByName("seleted"):setVisible(true)
	-- node:setOpacity(255)
	for i=1 ,#textTab do
		leftPanel:getChildByName(textTab[i]):setTextColor(cc.c4b(209, 209, 209,255))
		-- leftPanel:getChildByName(textTab[i]):setPositionX(leftPanel:getChildByName("Image_12_0_0"):getPositionX())
	end
	-- leftPanel:getChildByName(self.selectType.."_text"):setPositionX(leftPanel:getChildByName("Image_12_0_0"):getPositionX()+20)
	leftPanel:getChildByName(self.selectType.."_text"):setTextColor(cc.c4b(205, 235, 247,255))
	leftPanel:getChildByName(self.selectType):getChildByName("selected"):setVisible(true)
	
	self:resetList(self.selectType) 
end

function MailScene:addTouch(  )
	local leftPanel = self:getResourceNode():getChildByName("leftBg")
	local textTab =  {"system_text","player_text","planet_text","planet2_text","planet3_text","planet4_text"}
	for i=1 ,#textTab do
		leftPanel:getChildByName(textTab[i]):setTextColor(cc.c4b(209, 209, 209,255))
		-- leftPanel:getChildByName(textTab[i]):setPositionX(leftPanel:getChildByName("Image_12_0_0"):getPositionX())
	end
	for i,v in ipairs(self.labels) do
		local node = leftPanel:getChildByName(v)
		node:getChildByName("bkg"):addClickEventListener(function (sender)
			playEffectSound("sound/system/tab.mp3")
			if self:getResourceNode():getChildByName('MailDetailNode') then
				self:getResourceNode():getChildByName('MailDetailNode'):removeFromParent()
			end
			if self.selectType == nil then 
				self.selectType = node:getName() 
				leftPanel:getChildByName(self.selectType.."_text"):setTextColor(cc.c4b(205, 235, 247,255))
				-- leftPanel:getChildByName(self.selectType.."_text"):setPositionX(leftPanel:getChildByName("Image_12_0_0"):getPositionX()+20)
				leftPanel:getChildByName(self.selectType):getChildByName("selected"):setVisible(true)
				self:resetList(self.selectType)    
			elseif  self.selectType == node:getName() then
				return
			else
				local preNode = leftPanel:getChildByName(self.selectType)
				-- leftPanel:getChildByName(self.selectType.."_text"):setPositionX(leftPanel:getChildByName("Image_12_0_0"):getPositionX())
				leftPanel:getChildByName(self.selectType):getChildByName("selected"):setVisible(false)

				self.selectType = node:getName()
				leftPanel:getChildByName(self.selectType.."_text"):setTextColor(cc.c4b(205, 235, 247,255))
				-- leftPanel:getChildByName(self.selectType.."_text"):setPositionX(leftPanel:getChildByName("Image_12_0_0"):getPositionX()+20)
				leftPanel:getChildByName(self.selectType):getChildByName("selected"):setVisible(true)
				self:resetList(self.selectType)
			end
			
		end)
	end
end

function MailScene:onExitTransitionStart()
	printInfo("MailScene:onExitTransitionStart()")
	
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return MailScene