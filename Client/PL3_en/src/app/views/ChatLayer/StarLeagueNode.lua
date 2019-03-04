
local StarLeagueNode = class("StarLeagueNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

StarLeagueNode.RESOURCE_FILENAME = "ChatLayer/world_list.csb"

function StarLeagueNode:onEnterTransitionFinish()

end

function StarLeagueNode:init(scene,data)

	self.scene_ = scene

	local rn = self:getResourceNode()

	rn:getChildByName("list"):setSwallowTouches(false)
	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(10,15), cc.size(850,66))

	local strData = Tools.encode("GetChatLogReq", {

		chat_id = player:getGroupData().groupid
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)

	gl:retainLoading()

	local function recvMsg()
		print("StarLeagueNode:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GetChatLogResp",strData)
			if proto.result < 0 then
				print("error :",proto.result)
			else

				self.list_ = proto.log_list

				self:resetList()

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("CmdGetOtherUserInfoResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
			else

				-- local node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/chatNode.csb")

				-- -- node:getChildByName("head"):setTexture("RoleIcon/"..proto.info.icon_id..".png")
				-- node:getChildByName("name"):setString(proto.info.nickname)
				-- node:getChildByName("lv_num"):setString(proto.info.level)
				-- node:getChildByName("lv_num_0"):setString(proto.info.level)
				-- node:getChildByName("fight_num_0"):setString(proto.info.power)
				-- node:getChildByName("close"):getChildByName("text"):setString(CONF:getStringValue("closed"))
				-- node:getChildByName("close"):addClickEventListener(function ( ... )
				--     node:removeFromParent()
				-- end)

				-- node:setName("chatNode")
				-- node:setPosition(cc.p(749,211))
				-- self.scene_:addChild(node)

				local node = app:createView("ChatLayer/ChatNode2", {data = proto})
				node:setName("chatNode")
				node:setPosition(cc.p(self.scene_:getResourceNode():getChildByName("chat_node_pos"):getPosition()))
				self.scene_:addChild(node)
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_INVITE_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("GroupInviteResp",strData)
			if proto.result == "OK" then
				tips:tips(CONF:getStringValue("successful operation"))
			elseif proto.result == "FAIL" then
				print("proto error")
			elseif proto.result == "MY_BLACK" then
				tips:tips(CONF:getStringValue("this player in you blacklist"))
			elseif proto.result == "OTHER_BLACK" then
				tips:tips(CONF:getStringValue("you in this player blacklist"))
			elseif proto.result == "SENDED" then
				tips:tips(CONF:getStringValue("sended"))
			elseif proto.result == "HAS_GROUP" then
				tips:tips(CONF:getStringValue("has_garup"))
			elseif proto.result == "NO_OPEN" then
				tips:tips(CONF:getStringValue("not_open"))
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("BlackListResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				
				tips:tips(CONF:getStringValue("add black ok"))

				player:addBlack(self.black_name)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TalkListResp",strData)

			if proto.result == 1 then
				self.scene_:resetNode("chat", {user_name = self.talk_name})
			elseif proto.result ~= 0 then
				print("error :",proto.result)
			else
				
				self.scene_:resetNode("chat", {user_name = self.talk_name})
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_APPLY_FRIEND_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("ApplyFriendResp",strData)

			if proto.result == "FAIL" then
				print("error :",proto.result)
			else

				if proto.result == "SENDED" then
					tips:tips(CONF:getStringValue("appling friend now"))

					-- self.svd_:getScrollView():getChildByName("item_"..self.add_index):getChildByName("botton"):setVisible(false)
				elseif proto.result == "OTHER_BLACK" then
					tips:tips(CONF:getStringValue("you in this player blacklist"))
				elseif proto.result == "MY_BLACK" then
					tips:tips(CONF:getStringValue("this player in you blacklist"))
				else
					tips:tips(CONF:getStringValue("apply friend mail is send"))
				end
			end
			
		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.leagueListener_ = cc.EventListenerCustom:create("leagueMsg", function (event)
		local table_ = {stamp = player:getServerTime(), chat = event.chat.msg, nickname = event.chat.sender.nickname, user_name = event.chat.sender.uid}

		table.insert(self.list_, table_)

		self:resetList()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.leagueListener_, FixedPriority.kNormal)


end

function StarLeagueNode:resetList()
	local rn = self:getResourceNode()

	if table.getn(self.list_) <= 5 then
		rn:getChildByName("list"):setBounceEnabled(false)
	else
		rn:getChildByName("list"):setBounceEnabled(true)
	end

	self.svd_:clear()

	local function createListItem( info )
		local item = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/world_list_item.csb")

		local string_1 = item:getChildByName("string_1")
		local string_2 = item:getChildByName("string_2")
		local string_3 = item:getChildByName("string_3")
		local string_4 = item:getChildByName("string_4")
		local btn = item:getChildByName("button")

		string_1:removeFromParent()
		string_2:removeFromParent()

		string_3:setString(info.nickname)
		string_4:setString(self.scene_:formatTime(info.stamp%86400))

		string_4:setFontSize(16)

		string_3:setPositionX(0)
		string_4:setPositionX(string_3:getContentSize().width + 2)

		local label = cc.Label:createWithTTF(info.chat, "fonts/cuyabra.ttf", 16)
		label:setAnchorPoint(cc.p(0,1))
		-- label:setContentSize(node:getChildByName("text"):getContentSize())
		label:setPosition(cc.p(0, -13))
		label:setLineBreakWithoutSpace(true)
		label:setMaxLineWidth(666)
		label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
		-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))

		if info.nickname == player:getNickName() then
			string_4:setPositionX(830 - string_4:getContentSize().width)
			string_3:setPositionX(string_4:getPositionX() - 2 - string_3:getContentSize().width)

			label:setAnchorPoint(cc.p(1,1))
			label:setPosition(cc.p(830, -13))
 
			label:setTextColor(cc.c4b(124, 208, 138, 255))
			-- label:enableShadow(cc.c4b(124, 208, 138, 255),cc.size(0.5,0.5))
		end

		item:addChild(label)

		btn:setPosition(cc.p(string_3:getPosition()))
		btn:setContentSize(cc.size(string_3:getContentSize().width, string_3:getContentSize().height + 3))

		btn:addClickEventListener(function ( ... )

			if rn:getChildByName("click_node") then
				if rn:getChildByName("click_node"):getTag() == node:getTag() then
					rn:getChildByName("click_node"):removeFromParent()
					return
				else
					rn:getChildByName("click_node"):removeFromParent()
				end
			end

			if player:getName() ~= info.user_name then
				local click_node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/click_notFriend.csb")

				click_node:getChildByName("see"):getChildByName("text"):setString(CONF:getStringValue("info"))
				click_node:getChildByName("see"):addClickEventListener(function ( ... )
					if self.scene_:getChildByName("chatNode") then
						self.scene_:getChildByName("chatNode"):removeFromParent()
					end

					local strData = Tools.encode("CmdGetOtherUserInfoReq", {
						user_name = info.user_name,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_REQ"),strData)

					gl:retainLoading()

					click_node:removeFromParent()
				end)

				click_node:getChildByName("friend"):getChildByName("text"):setString(CONF:getStringValue("addFriend"))
				click_node:getChildByName("friend"):addClickEventListener(function ( ... )
					local strData = Tools.encode("ApplyFriendReq", {
						recver = info.user_name,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_APPLY_FRIEND_REQ"),strData)

					gl:retainLoading()

					click_node:removeFromParent()
				end)

				click_node:getChildByName("chat"):getChildByName("text"):setString(CONF:getStringValue("privateChat"))
				click_node:getChildByName("chat"):addClickEventListener(function ( ... )
					self.talk_name = info.user_name

					local strData = Tools.encode("TalkListReq", {
						type = 1,
						user_name = info.user_name,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_REQ"),strData)

					gl:retainLoading()

					click_node:removeFromParent()
				end)

				click_node:getChildByName("mail"):getChildByName("text"):setString(CONF:getStringValue("mail"))
				click_node:getChildByName("mail"):addClickEventListener(function ( ... )

					local sendLayer = require("app.views.MailScene.SendMail"):create()
					self:getParent():addChild(sendLayer)
					sendLayer:init(info.nickname,info.user_name)

					click_node:removeFromParent()
				end)

				click_node:getChildByName("black"):getChildByName("text"):setString(CONF:getStringValue("black"))
				click_node:getChildByName("black"):addClickEventListener(function ( ... )

					if player:getFriendsNum(2) == CONF.PLAYERLEVEL.get(player:getLevel()).BLACK_NUM then
						tips:tips(CONF:getStringValue("blackListIsFull"))
						return
					end
					
					self.black_name = info.user_name

					local strData = Tools.encode("BlackListReq", {
						type = 1,
						user_name = info.user_name,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_REQ"),strData)

					gl:retainLoading()

					click_node:removeFromParent()
				end)

					click_node:getChildByName("group"):getChildByName("text"):setString(CONF:getStringValue("group_yaoqing"))
				click_node:getChildByName("group"):addClickEventListener(function ( ... )
					local strData = Tools.encode("GroupInviteReq", {
						recver = info.user_name,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_INVITE_REQ"),strData)

					gl:retainLoading()

					click_node:removeFromParent()
				end)

				if player:isFriend(info.user_name) then
					click_node:getChildByName("group"):setPosition(cc.p(click_node:getChildByName("black"):getPosition()))
					click_node:getChildByName("black"):setPosition(cc.p(click_node:getChildByName("mail"):getPosition()))
					click_node:getChildByName("mail"):setPosition(cc.p(click_node:getChildByName("chat"):getPosition()))
					click_node:getChildByName("chat"):setPosition(cc.p(click_node:getChildByName("friend"):getPosition()))

					click_node:getChildByName("friend"):removeFromParent()

					click_node:getChildByName("bg"):setContentSize(cc.size(click_node:getChildByName("bg"):getContentSize().width, click_node:getChildByName("bg"):getContentSize().height - 50))
				end

				if player:isGroup() then
					if player:getGroupData().job == 3 then

						click_node:getChildByName("group"):removeFromParent()
						click_node:getChildByName("bg"):setContentSize(cc.size(click_node:getChildByName("bg"):getContentSize().width, click_node:getChildByName("bg"):getContentSize().height - 50))
					end
				else
					click_node:getChildByName("group"):removeFromParent()
					click_node:getChildByName("bg"):setContentSize(cc.size(click_node:getChildByName("bg"):getContentSize().width, click_node:getChildByName("bg"):getContentSize().height - 50))

				end
				

				click_node:setPosition(cc.p(string_3:convertToWorldSpace(cc.p(0,0)).x + string_3:getContentSize().width/2 -self:getPositionX(), string_3:convertToWorldSpace(cc.p(0,0)).y - self:getPositionY()))
				click_node:setName("click_node")
				click_node:setTag(item:getTag())
				rn:addChild(click_node)
			end
		end)


		item:getChildByName("text"):removeFromParent()

		local size = string_3:getContentSize().height + label:getContentSize().height

		return item,size
	end

	for i,v in ipairs(self.list_) do

		local item,size = createListItem(v)

		item:setTag(i)
		item:setName("chat_item_"..i)

		self.svd_:addElement(item, {size = cc.size(584,size)})

	end

	self.svd_:getScrollView():getInnerContainer():setPositionY(0)
end

function StarLeagueNode:onExitTransitionStart()

	printInfo("StarLeagueNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.leagueListener_)

end

return StarLeagueNode