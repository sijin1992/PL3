
local AddFriendNode = class("AddFriendNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

AddFriendNode.RESOURCE_FILENAME = "FriendLayer/find_list.csb"


function AddFriendNode:onEnterTransitionFinish()

end

function AddFriendNode:init(scene,data)

	self.scene_ = scene

	self.select_index = 0

    self.user_name_list_ = {}

	local rn = self:getResourceNode()
	rn:getChildByName("text"):setString(CONF:getStringValue("NotExist"))

	rn:getChildByName("find"):getChildByName("text"):setString(CONF:getStringValue("search"))

	rn:getChildByName("back"):getChildByName("text"):setString(CONF:getStringValue("back"))
	rn:getChildByName("back"):addClickEventListener(function ( ... )
		rn:getChildByName("back"):setVisible(false)
		-- self.find_list_ = {}
		-- self:resetFind()
		rn:getChildByName("shuaxin"):setVisible(true)

		local strData = Tools.encode("GetFriendsInfoReq", {
			type = 4,
			index = 1,
			num = 5,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)
	end)


	rn:getChildByName("shuaxin"):getChildByName("text"):setString(CONF:getStringValue("shuaxin"))
	rn:getChildByName("shuaxin"):addClickEventListener(function ( ... )
		local strData = Tools.encode("GetFriendsInfoReq", {
			type = 4,
			index = 1,
			num = 5,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)
	end)
	

	local placeHolder = rn:getChildByName("find_text")
	-- local inputText = rn:getChildByName("input_text")
	local placeHolderColor = placeHolder:getTextColor()
	local fontColor = placeHolder:getTextColor()	
	local fontName = placeHolder:getFontName()
	local fontSize = placeHolder:getFontSize()

	local back = rn:getChildByName(string.format("text_back"))

	local edit = ccui.EditBox:create(back:getContentSize(),"Common/ui/chat_bottom.png")
	rn:addChild(edit)
	edit:setPosition(cc.p(back:getPosition()))
	edit:setPlaceHolder(CONF:getStringValue("InputPlayerName"))
	edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
	edit:setPlaceholderFont(fontName,fontSize)
	edit:setPlaceholderFontColor(fontColor)
	edit:setFont(fontName,fontSize)
	edit:setFontColor(fontColor)
	edit:setReturnType(1)
	edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
	edit:setName("find_text")

	back:removeFromParent()
	
	placeHolder:removeFromParent()

	rn:getChildByName("list"):setScrollBarEnabled(false)

	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(2,10), cc.size(815,109))

	rn:getChildByName("find"):addClickEventListener(function ( sender )
		print(rn:getChildByName("find_text"):getText())

		if rn:getChildByName("find_text"):getText() == "" then
			tips:tips(CONF:getStringValue("ContentIsEmpty"))
			return
		end

		if rn:getChildByName("find_text"):getText() == player:getNickName() then
			tips:tips(CONF:getStringValue("Can't search my"))
		else
			local strData = Tools.encode("GetFriendsInfoReq", {
				type = 0,
				nickname = rn:getChildByName("find_text"):getText(),
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

			rn:getChildByName("back"):setVisible(true)
			rn:getChildByName("shuaxin"):setVisible(false)
		end
	end)

	local strData = Tools.encode("GetMailListReq", {
		num = 0,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)

	gl:retainLoading()

	local strData = Tools.encode("GetFriendsInfoReq", {
		type = 4,
		index = 1,
		num = 5,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

	-- gl:retainLoading()

	local function recvMsg()
		print("AddFriendNode:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GetMailListResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				for i,v in ipairs(proto.user_sync.mail_list) do
					if v.type == 9 then
						table.insert(self.user_name_list_, v.from)
					end
				end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_APPLY_FRIEND_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("ApplyFriendResp",strData)
			if proto.result == "FAIL" then
				print("error :",proto.result)
			else

				if proto.result == "SENDED" then
					tips:tips(CONF:getStringValue("appling friend now"))

					self.svd_:getScrollView():getChildByName("item_"..self.add_index):getChildByName("botton"):setEnabled(false)
				elseif proto.result == "OTHER_BLACK" then
					tips:tips(CONF:getStringValue("this player in you blacklist"))
				else
					tips:tips(CONF:getStringValue("apply friend mail is send"))

					self.svd_:getScrollView():getChildByName("item_"..self.add_index):getChildByName("botton"):setEnabled(false)
				end
				-- local strData = Tools.encode("GetFriendsInfoReq", {
				--     type = 3,
				--     nickname = rn:getChildByName("find_text"):getText(),
				-- })
				-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

				-- gl:retainLoading()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_RESP") then

			local proto = Tools.decode("GetFriendsInfoResp",strData)
			if proto.result == 2 then
				self.find_list_ = proto.list

				self:resetFind()

			elseif proto.result < 0 then
				print("error :",proto.result)
			elseif proto.result == 12 then
				tips:tips(CONF:getStringValue("NotExist"))

			else
				self.find_list_ = proto.list

				self:resetFind()

			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

end

function AddFriendNode:resetFind(text)
	local rn = self:getResourceNode()

	rn:getChildByName("text"):setVisible(false)

	self.svd_:clear()

	if table.getn(self.find_list_) == 0 then
		rn:getChildByName("text"):setVisible(true)
		return
	else
		rn:getChildByName("text"):setVisible(false)
	end

	if table.getn(self.find_list_) <= 4 then
		rn:getChildByName("list"):setBounceEnabled(false)
	else
		rn:getChildByName("list"):setBounceEnabled(true)
	end

	local function createListItem(name)
		local item = require("app.ExResInterface"):getInstance():FastLoad("FriendLayer/find_list_item.csb")
		item:getChildByName("xingmeng"):setString(CONF:getStringValue("covenant")..":")
		item:getChildByName("botton"):getChildByName("text"):setString(CONF:getStringValue("add"))

		if player:isFriend(name) then
			item:getChildByName("botton"):setVisible(false)

		else

			item:getChildByName("botton"):addClickEventListener(function( ... )
				local flag = true
				for i,v in ipairs(self.user_name_list_) do
					if v == name then
						flag = false
					end
				end

				self.add_index = item:getTag()

				if name == player:getName() then
					tips:tips(CONF:getStringValue("Can'tAddYourself"))
					return
				end

				if player:isBlack(name) then
					tips:tips(CONF:getStringValue("this player in you blacklist"))
					return                           
				end
					
				if flag then

					local strData = Tools.encode("ApplyFriendReq", {
						recver = name,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_APPLY_FRIEND_REQ"),strData)

					gl:retainLoading()
				
				else
					tips:tips(CONF:getStringValue("AlreadyApply"))
				end
			end)    
		end

		return item
	end
	
	for i,v in ipairs(self.find_list_) do
		local item = createListItem(v.user_name)

		item:getChildByName("name"):setString(v.nickname)
		item:getChildByName("lv_num"):setString(v.level)
		item:getChildByName("fight_num"):setString(v.power)

		item:getChildByName("head"):setTexture("HeroImage/"..v.icon_id..".png")
		item:getChildByName("xingmeng_name"):setString(v.group_nickname)

		if v.group_nickname == "" then
			item:getChildByName("xingmeng_name"):setString(CONF:getStringValue("leagueNmae"))
		end

		--item:getChildByName("lv"):setPositionX(item:getChildByName("name"):getPositionX() + item:getChildByName("name"):getContentSize().width*item:getChildByName("name"):getScale() + 20)
		--item:getChildByName("lv_num"):setPositionX(item:getChildByName("lv"):getPositionX() + item:getChildByName("lv"):getContentSize().width*item:getChildByName("lv"):getScale() + 10)
		item:getChildByName("fight_num"):setPositionX(item:getChildByName("fight"):getPositionX() + item:getChildByName("fight"):getContentSize().width/2*item:getChildByName("fight"):getScale() + 10)
		item:getChildByName("xingmeng_name"):setPositionX(item:getChildByName("xingmeng"):getPositionX() + item:getChildByName("xingmeng"):getContentSize().width*item:getChildByName("xingmeng"):getScale() + 5)

		item:setTag(i)
		item:setName("item_"..i)

		local func = function( ... )
			if self.select_index ~= 0 then 

				self:selectItem(self.svd_:getScrollView():getChildByName("item_"..self.select_index), false)

				if item:getTag() == self.select_index then
					self.select_index = 0
					return
				else 
					self:selectItem(item, true)

					self.select_index = item:getTag()
				end
			else
				self:selectItem(item, true)

				self.select_index = item:getTag()
			end
		end

		local callback = {node = item:getChildByName("background"), func = func}

		self.svd_:addElement(item, {callback = callback})
	end

end

function AddFriendNode:selectItem(item, flag)

	if item == nil then
		return
	end

	item:getChildByName("selected"):setVisible(flag)

	--item:getChildByName("lv"):setPositionX(item:getChildByName("name"):getPositionX() + item:getChildByName("name"):getContentSize().width*item:getChildByName("name"):getScale() + 20)
	--item:getChildByName("lv_num"):setPositionX(item:getChildByName("lv"):getPositionX() + item:getChildByName("lv"):getContentSize().width*item:getChildByName("lv"):getScale() + 10)
	item:getChildByName("fight_num"):setPositionX(item:getChildByName("fight"):getPositionX() + item:getChildByName("fight"):getContentSize().width/2*item:getChildByName("fight"):getScale() + 10)
	item:getChildByName("xingmeng_name"):setPositionX(item:getChildByName("xingmeng"):getPositionX() + item:getChildByName("xingmeng"):getContentSize().width*item:getChildByName("xingmeng"):getScale() + 5)
end

function AddFriendNode:onExitTransitionStart()
	printInfo("AddFriendNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end

return AddFriendNode