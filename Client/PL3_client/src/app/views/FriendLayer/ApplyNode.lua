
local ApplyNode = class("ApplyNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

ApplyNode.RESOURCE_FILENAME = "FriendLayer/apply_list.csb"

function ApplyNode:onEnterTransitionFinish()

end

function ApplyNode:init(scene,data)

	self.scene_ = scene

	self.select_index = 0

	local rn = self:getResourceNode()
	
	rn:getChildByName("text"):setString(CONF:getStringValue("no_Apply"))
	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(2,10), cc.size(815,109))

	local strData = Tools.encode("GetMailListReq", {
		num = 0,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)

	gl:retainLoading()

	local function recvMsg()
		print("FriendNode:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GetMailListResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				self.mail_list_ = {}
				self.user_name_list_ = {}

				for i,v in ipairs(proto.user_sync.mail_list) do
					if v.type == 9 then
						table.insert(self.mail_list_, v)
						table.insert(self.user_name_list_, v.from)
					end
				end

				print(table.getn(self.mail_list_))

				if table.getn(self.mail_list_) ~= 0 then
					self:getUserInfo()
					self.scene_:getResourceNode():getChildByName("apply"):getChildByName("red"):setVisible(true)
				else
					self:resetList()
					self.scene_:getResourceNode():getChildByName("apply"):getChildByName("red"):setVisible(false)
				end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_ACCEPT_FRIEND_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("AcceptFriendResp",strData)
			if proto.result == "FAIL" then
				print("error :",proto.result)
			else
				if proto.result == "OTHER_BLACK" then
					tips:tips(CONF:getStringValue("you in this player blacklist"))
				elseif proto.result == "MY_FRIEND_FULL" then
					tips:tips(CONF:getStringValue("you friend is max num"))
				elseif proto.result == "OTHER_FRIEND_FULL" then
					tips:tips(CONF:getStringValue("this player friend num is max ,can't add"))
				elseif proto.result == "FIREND" then
					tips:tips(CONF:getStringValue("this player is you friend"))

					local strData = Tools.encode("DelMailReq", {
						guid_list = {self.mail_guid_},
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_DEL_MAIL_REQ"),strData)

					gl:retainLoading()
				else

					player:addFriend(self.add_friend_name)
					local strData = Tools.encode("GetMailListReq", {
						num = 9,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)

					gl:retainLoading()
				end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_DEL_MAIL_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("DelMailResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				local strData = Tools.encode("GetMailListReq", {
					num = 9,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)

				gl:retainLoading()

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("CmdGetOtherUserInfoResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
			else 

				table.insert(self.info_list_, proto.info)

				if table.getn(self.info_list_) == table.getn(self.mail_list_) then
					self:resetList()
				end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("CmdGetOtherUserInfoListResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
			else 

				self.info_list_ = {}

				for i,v in ipairs(proto.info_list) do
					table.insert(self.info_list_, v)
				end
				
				self:resetList()

			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	
end

function ApplyNode:getUserInfo()
	-- for i,v in ipairs(self.mail_list_) do
	--     local strData = Tools.encode("CmdGetOtherUserInfoReq", {
	--         user_name = v.from_user_name,
	--     })
	--     GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_REQ"),strData)

	--     gl:retainLoading()
	-- end

	-- local cmd,strData = GameHandler.handler_c.recvProtobuf()
	-- for i,v in ipairs(self.mail_list_) do
	--     local data = Tools.decode(v.message, strData)
	--     print(data.level)
	--     print(data.nickname)
	-- end

	local strData = Tools.encode("CmdGetOtherUserInfoListReq", {
		user_name_list = self.user_name_list_,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_REQ"),strData)

	gl:retainLoading()

end

function ApplyNode:resetList( ... )

	local rn = self:getResourceNode()

	self.svd_:clear()
	
	if table.getn(self.mail_list_) > 0 then
		rn:getChildByName("text"):setVisible(false)   
	else
		rn:getChildByName("text"):setVisible(true)
		return
	end

	if table.getn(self.mail_list_) <= 4 then
		rn:getChildByName("list"):setBounceEnabled(false)
	else
		rn:getChildByName("list"):setBounceEnabled(true)
	end

	local function createListItem(mail)
		local node = require("app.ExResInterface"):getInstance():FastLoad("FriendLayer/apply_list_item.csb")

		node:getChildByName("tongyi"):addClickEventListener(function ( ... )
 
			if player:isBlack(mail.from) then
				tips:tips(CONF:getStringValue("this player in you blacklist"))
			else

				if player:isFriend(mail.from) then
					tips:tips(CONF:getStringValue("this player is you friend"))
				else
					if player:getFriendsNum(1) >= CONF.PLAYERLEVEL.get(player:getLevel()).FRIEND_NUM then
						tips:tips(CONF:getStringValue("you friend is max num"))
					else
						self.add_friend_name = mail.from
						self.mail_guid_ = mail.guid
						local strData = Tools.encode("AcceptFriendReq", {
							sender = mail.from,
							mail_guid = mail.guid,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACCEPT_FRIEND_REQ"),strData)

						gl:retainLoading()
					end
				end
			end
		end)

		node:getChildByName("jujue"):addClickEventListener(function ( ... )
			local strData = Tools.encode("DelMailReq", {
				guid_list = {mail.guid},
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_DEL_MAIL_REQ"),strData)

			gl:retainLoading()
		end)


		return node
	end

	for i,v in ipairs(self.mail_list_) do
		local item = createListItem(v)
		item:getChildByName("name"):setString(self.info_list_[i].nickname)
		item:getChildByName("lv_num"):setString(self.info_list_[i].level)
		item:getChildByName("fight_num"):setString(self.info_list_[i].power)
		item:getChildByName("head"):setTexture("HeroImage/"..self.info_list_[i].icon_id..".png")
		item:getChildByName("xingmeng_name"):setString(self.info_list_[i].group_nickname)

		if self.info_list_[i].group_nickname == "" then
			item:getChildByName("xingmeng_name"):setString(CONF:getStringValue("leagueNmae"))
		end
		
		item:getChildByName("xingmeng"):setString(CONF:getStringValue("covenant")..":")
		item:getChildByName("tongyi"):getChildByName("text"):setString(CONF:getStringValue("accept"))
		item:getChildByName("jujue"):getChildByName("text"):setString(CONF:getStringValue("refuse"))

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

function ApplyNode:selectItem(item, flag)

	item:getChildByName("selected"):setVisible(flag)

	--item:getChildByName("lv"):setPositionX(item:getChildByName("name"):getPositionX() + item:getChildByName("name"):getContentSize().width*item:getChildByName("name"):getScale() + 20)
	--item:getChildByName("lv_num"):setPositionX(item:getChildByName("lv"):getPositionX() + item:getChildByName("lv"):getContentSize().width*item:getChildByName("lv"):getScale() + 10)
	item:getChildByName("fight_num"):setPositionX(item:getChildByName("fight"):getPositionX() + item:getChildByName("fight"):getContentSize().width/2*item:getChildByName("fight"):getScale() + 10)
	item:getChildByName("xingmeng_name"):setPositionX(item:getChildByName("xingmeng"):getPositionX() + item:getChildByName("xingmeng"):getContentSize().width*item:getChildByName("xingmeng"):getScale() + 5)
end

function ApplyNode:updateList()
	local strData = Tools.encode("GetMailListReq", {
		num = 0,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)

	gl:retainLoading()
end

function ApplyNode:onExitTransitionStart()
	printInfo("ApplyNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end

return ApplyNode