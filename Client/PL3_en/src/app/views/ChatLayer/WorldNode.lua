
local WorldNode = class("WorldNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

WorldNode.RESOURCE_FILENAME = "ChatLayer/world_list.csb"

function WorldNode:onEnterTransitionFinish()

end

function WorldNode:init(scene,data)

	self.scene_ = scene

	self.select_index = 0

	local rn = self:getResourceNode()

	rn:getChildByName("list"):setSwallowTouches(false)
	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(10,10), cc.size(850,66))

	local strData = Tools.encode("GetChatLogReq", {

			chat_id = 0
		})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)

	gl:retainLoading()

	local function recvMsg()
		print("WorldNode:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GetChatLogResp",strData)
			if proto.result < 0 then
				print("error :",proto.result)
			else

				self.list_ = proto.log_list

				self:resetList()

				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("seeChat")

				if #proto.log_list > 0 then
					local log = {}
					for i=#proto.log_list,1,-1 do
						if proto.log_list[i] then
							if proto.log_list[i].user_name ~= "0" then
								if not player:isBlack(proto.log_list[i].user_name) then
									log = proto.log_list[i]
									break
								end
							end	
						end
					end
					if Tools.isEmpty(log) == false then
						local tt = {user_name = log.user_name, chat = log.chat, time = log.stamp}
						player:setLastChat(tt)
					end
				end

			end
			
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("BlackListResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				
				tips:tips(CONF:getStringValue("add black ok"))

				player:addBlack(self.black_name)
				-- self:resetList()
				local strData = Tools.encode("GetChatLogReq", {

						chat_id = 0
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)
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

					self.svd_:getScrollView():getChildByName("item_"..self.add_index):getChildByName("botton"):setVisible(false)
				elseif proto.result == "OTHER_BLACK" then
					tips:tips(CONF:getStringValue("you in this player blacklist"))
				elseif proto.result == "MY_BLACK" then
					tips:tips(CONF:getStringValue("this player in you blacklist"))
				else
					tips:tips(CONF:getStringValue("apply friend mail is send"))
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("CmdGetOtherUserInfoResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
			else

				-- local node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/chatNode.csb")

				-- node:getChildByName("head"):setTexture("RoleIcon/"..proto.info.icon_id..".png")
				-- node:getChildByName("name"):setString(proto.info.nickname)
				-- node:getChildByName("lv_num"):setString(proto.info.level)
				-- node:getChildByName("lv_num_0"):setString(proto.info.level)
				-- node:getChildByName("fight_num"):setString(proto.info.power)
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

		end


	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.worldListener_ = cc.EventListenerCustom:create("worldMsg", function (event)
		playEffectSound("sound/system/message_update.mp3")
		local table_ = {stamp = player:getServerTime(), chat = event.chat.msg, nickname = event.chat.sender.nickname, user_name = event.chat.sender.uid, group_name = event.chat.sender.group_nickname}
		self:addNewItem(0, table_)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.worldListener_, FixedPriority.kNormal)

	self.broadcastListener_ = cc.EventListenerCustom:create("broadcastMsg", function (event)
		playEffectSound("sound/system/message_update.mp3")
		local table_ = {stamp = player:getServerTime(), chat = event.chat.msg, nickname = event.chat.sender.nickname, user_name = event.chat.sender.uid, group_name = event.chat.sender.group_nickname}
		self:addNewItem(1, table_)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.broadcastListener_, FixedPriority.kNormal)

	self.announcementListener_ = cc.EventListenerCustom:create("announcementMsg", function (event)
		playEffectSound("sound/system/message_update.mp3")
		local table_ = {stamp = player:getServerTime(), chat = event.chat.msg, nickname = event.chat.sender.nickname, user_name = event.chat.sender.uid, group_name = event.chat.sender.group_nickname}
		self:addNewItem(2, table_)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.announcementListener_, FixedPriority.kNormal)
	
end

function WorldNode:resetList( ... )

	local rn = self:getResourceNode()

	if table.getn(self.list_) <= 5 then
		rn:getChildByName("list"):setBounceEnabled(false)
	else
		rn:getChildByName("list"):setBounceEnabled(true)
	end

	self.svd_:clear()

	-- local callback = function (event)
	--     if event.name == "SCROLLING" then
	--         if rn:getChildByName("click_node") then
	--             rn:getChildByName("click_node"):removeFromParent()
	--         end
	--     end
	-- end

	-- rn:getChildByName("list"):onEvent(callback)

	local function createListItem(info)

		local node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/world_list_item.csb")

		local string_1 = node:getChildByName("string_1")
		local string_2 = node:getChildByName("string_2")
		local string_3 = node:getChildByName("string_3")
		local string_4 = node:getChildByName("string_4")
		local btn = node:getChildByName("button")
		string_1:setString("["..CONF:getStringValue("worldChat").."]")

		if info.group_name == nil then
			info.group_name = ""
		end

		if info.group_name ~= "" then
			string_2:setString("["..info.group_name.."]")
		else
			string_2:setString(info.group_name)
		end

		string_3:setString(info.nickname)
		-- string_1:setString(info.stamp) 
		string_4:setString(self.scene_:formatTime(info.stamp%86400))
		string_4:setFontSize(16)

		string_1:setPositionX(0)
		string_2:setPositionX(string_1:getContentSize().width + 2)
		string_3:setPositionX(string_2:getPositionX() + string_2:getContentSize().width + 2)
		string_4:setPositionX(string_3:getPositionX() + string_3:getContentSize().width + 2)

		local label = cc.Label:createWithTTF(info.chat, "fonts/cuyabra.ttf", 16)
		label:setAnchorPoint(cc.p(0,1))
		-- label:setContentSize(node:getChildByName("text"):getContentSize())
		label:setPosition(cc.p(0, -13))
		label:setLineBreakWithoutSpace(true)
		label:setMaxLineWidth(800)
		label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
		-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))

		if info.nickname == player:getNickName() then
			label:setTextColor(cc.c4b(124, 208, 138, 255))
			-- label:enableShadow(cc.c4b(124, 208, 138, 255),cc.size(0.5,0.5))
		end

		node:addChild(label)

		btn:setPosition(cc.p(string_2:getPosition()))
		if info.user_name and info.user_name == "0" then
			btn:setVisible(false)
			local label2 = createRichTextNeedChangeColor(info.chat)
			label2:setPosition(cc.p(label:getPosition()))
			label2:setAnchorPoint(cc.p(0,1))
			label2:ignoreContentAdaptWithSize(false)  
			label2:setContentSize(label:getContentSize())
			node:addChild(label2)
			label:setVisible(false)
		end
		btn:setContentSize(cc.size(string_2:getContentSize().width + string_3:getContentSize().width + 2, string_3:getContentSize().height + 3))
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

					-- if info.level < CONF.FUNCTION_OPEN.get(15).GRADE then
					-- 	tips:tips(CONF:getStringValue("not_open"))
					-- 	return
					-- end

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
				

				click_node:setPosition(cc.p(string_3:convertToWorldSpace(cc.p(0,0)).x + string_3:getContentSize().width/2 -self:getPositionX(), string_3:convertToWorldSpace(cc.p(0,0)).y - self:getPositionY()/2))

				if click_node:getPositionY() < 200 then
					click_node:setPositionY(click_node:getPositionY() + 100)
				end

				click_node:setName("click_node")
				click_node:setTag(node:getTag())
				rn:addChild(click_node)
			end
		end)

		if player:getName() == info.user_name then
			btn:removeFromParent()
		end

		node:getChildByName("text"):removeFromParent()

		local size = string_1:getContentSize().height + label:getContentSize().height

		return node,size

	end

	for i,v in ipairs(self.list_) do
		if not player:isBlack(v.user_name) then
			local item,size = createListItem(v)
			item:setTag(i)
			item:setName("chat_item_"..i)
			self.svd_:addElement(item, {size = cc.size(584,size)})
		end
	end

	self.svd_:getScrollView():getInnerContainer():setPositionY(0)
 
end

function WorldNode:addNewItem( type, info ) -- 0世界  1广播  2系统

	if player:isBlack(info.user_name) then
		return
	end

	-- if type ~= 0 then
	-- 	return
	-- end

	local rn = self:getResourceNode()

	local node = require("app.ExResInterface"):getInstance():FastLoad("ChatLayer/world_list_item.csb")

	local string_1 = node:getChildByName("string_1")
	local string_2 = node:getChildByName("string_2")
	local string_3 = node:getChildByName("string_3")
	local string_4 = node:getChildByName("string_4")
	local btn = node:getChildByName("button")

	if type == 0 then
		string_1:setString("["..CONF:getStringValue("worldChat").."]")
	elseif type == 1 then
		string_1:setString(string.format("[%s]",CONF:getStringValue("broadcast")))
	elseif type == 2 then
		string_1:setString("["..CONF:getStringValue("system").."]")
	end

	if info.group_name == nil then
		info.group_name = ""
	end

	if info.group_name ~= "" then
		string_2:setString("["..info.group_name.."]")
	else
		string_2:setString(info.group_name)
	end
	string_3:setString(info.nickname)
	-- string_1:setString(info.stamp) 
	string_4:setString(self.scene_:formatTime(info.stamp%86400))
	string_4:setFontSize(16)

	string_1:setPositionX(0)
	string_2:setPositionX(string_1:getContentSize().width + 2)
	string_3:setPositionX(string_2:getPositionX() + string_2:getContentSize().width + 2)
	string_4:setPositionX(string_3:getPositionX() + string_3:getContentSize().width + 2)

	if type == 1 then
		string_1:setTextColor(cc.c4b(232,243,77,255))
		-- string_1:enableShadow(cc.c4b(232, 243, 77, 255),cc.size(0.5,0.5))
	elseif type == 2 then
		string_1:setTextColor(cc.c4b(255,145,136,255))
		-- string_1:enableShadow(cc.c4b(255, 145, 136, 255),cc.size(0.5,0.5))
		string_2:setString(info.stamp)
		string_3:removeFromParent()
		string_4:removeFromParent()
	end

	local function removeJing( str )
		local strs = {}

		while true do
			if not string.find(str,"#") then
			
				table.insert(strs,str)
				break
			end

			local pos1 = string.find(str,"#")

			local sr = string.sub(str, 1, pos1-1)

			if sr ~= "" then
				table.insert(strs, sr)
			end

			local ssr = string.sub(str,pos1,pos1+8)
			--table.insert(strs, ssr)

			str = string.sub(str, pos1+9)
		end

		local chat = ""
		for i,v in ipairs(strs) do
			chat = chat..v
		end

		return chat
	end

	local label = cc.Label:createWithTTF(removeJing(info.chat), "fonts/cuyabra.ttf", 16)
	label:setAnchorPoint(cc.p(0,1))
	-- label:setContentSize(node:getChildByName("text"):getContentSize())
	label:setPosition(cc.p(0, -13))
	label:setLineBreakWithoutSpace(true)
	label:setMaxLineWidth(800)
	label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
	if type == 0 then
		-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
	elseif type == 1 then
		label:setTextColor(cc.c4b(232,243,77,255))
		-- label:enableShadow(cc.c4b(232, 243, 77, 255),cc.size(0.5,0.5))
	elseif type == 2 then
		label:setTextColor(cc.c4b(255,145,136,255))
		-- label:enableShadow(cc.c4b(255, 145, 136, 255),cc.size(0.5,0.5))
	end

	if info.nickname == player:getNickName() then
		label:setTextColor(cc.c4b(124, 208, 138, 255))
		-- label:enableShadow(cc.c4b(124, 208, 138, 255),cc.size(0.5,0.5))
	end
	node:addChild(label)

	if type ~= 2 then
		btn:setPosition(cc.p(string_2:getPosition()))
		btn:setContentSize(cc.size(string_2:getContentSize().width + string_3:getContentSize().width + 2, string_3:getContentSize().height + 3))
		btn:addClickEventListener(function ( ... )
			if rn:getChildByName("click_node") then
				rn:getChildByName("click_node"):removeFromParent()
			end

			if player:getNickName() ~= info.nickname then
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

				
				if click_node:getPositionY() < 200 then
					click_node:setPositionY(click_node:getPositionY() + 100)
				end
				
				click_node:setName("click_node")
				rn:addChild(click_node)
			end
		end)
	end

	node:getChildByName("text"):removeFromParent()

	local size = string_1:getContentSize().height + label:getContentSize().height

	table.insert(self.list_, info)

	node:setTag(table.getn(self.list_))
	node:setName("chat_item_"..table.getn(self.list_))

	self.svd_:addElement(node, {size = cc.size(568,size)})

	self.svd_:getScrollView():getInnerContainer():setPositionY(0)

	if table.getn(self.list_) <= 5 then
		rn:getChildByName("list"):setBounceEnabled(false)
	else
		rn:getChildByName("list"):setBounceEnabled(true)
	end

end

function WorldNode:onExitTransitionStart()
	printInfo("WorldNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.worldListener_)
	eventDispatcher:removeEventListener(self.broadcastListener_)
	eventDispatcher:removeEventListener(self.announcementListener_)

end

return WorldNode