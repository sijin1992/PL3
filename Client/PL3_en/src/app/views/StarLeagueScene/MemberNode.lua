
local MemberNode = class("MemberNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local winSize = cc.Director:getInstance():getWinSize()

local gl = require("util.GlobalLoading"):getInstance()

MemberNode.RESOURCE_FILENAME = "StarLeagueScene/league_member.csb"

function MemberNode:onEnterTransitionFinish()

end

function MemberNode:init(scene,data)

	self.scene_ = scene
	self.group_list = data.group 
	self.info_list = data.user_info
	self.join_info_list = data.join_list

	self.select_index = 0

	local rn = self:getResourceNode()
	rn:getChildByName("text_0_0_0"):setString(CONF:getStringValue("post"))
	rn:getChildByName("text_0_0_0_1"):setString(CONF:getStringValue("name"))
	rn:getChildByName("text_0_0_0_0_0"):setString(CONF:getStringValue("level"))
	rn:getChildByName("text_0_0_0_0"):setString(CONF:getStringValue("combat"))
	rn:getChildByName("text_0_0_0_0_1"):setString(CONF:getStringValue("online_time"))

	rn:getChildByName("text_0"):setString(CONF:getStringValue("sumMember"))
	rn:getChildByName("apply"):getChildByName("text"):setString(CONF:getStringValue("applyers"))
	rn:getChildByName("list"):setScrollBarEnabled(false)
	-- rn:getChildByName("list"):setSwallowTouches(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(2,2), cc.size(924,82))

	rn:getChildByName("apply"):addClickEventListener(function ( ... )

		if self.scene_:getChildByName("click_node") then
			self.scene_:getChildByName("click_node"):removeFromParent()
		end

		self:createApply()
	end)

	rn:getChildByName("btn_chat"):addClickEventListener(function ( ... )
		local layer = self.scene_:getApp():createView("ChatLayer/ChatLayer", {name = "star"})
		self.scene_:addChild(layer)
	end)

	-- self:resetList()
	-- self:loadInfo()

	self:getMemberIsOnline()

	local strData = Tools.encode("GetMailListReq", {
		num = 0,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)

	gl:retainLoading()


	local function recvMsg()
		print("MemberNode:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_ALLOW_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupAllowResp",strData)
			if proto.result == "FAIL" then
				print("error :",proto.result)
			elseif proto.result == "OK" then

				tips:tips(CONF:getStringValue("successful operation"))

				self.group_list = proto.user_sync.group_main
                if self.scene_:getChildByName("message") then
				    self.scene_:getChildByName("message"):removeFromParent()
				    self:createApply()
                end
			elseif proto.result == "NO_USER" then
				tips:tips(CONF:getStringValue("InOtherGroup"))
			elseif proto.result == "NO_CONDITION" then
				tips:tips(CONF:getStringValue("no_condition"))
			elseif proto.result == "USER_COUNT_MAX" then
				tips:tips(CONF:getStringValue("group_count_max"))
			elseif proto.result == "NO_NUMS" then
				tips:tips(CONF:getStringValue("group_join_max"))
			elseif proto.result == "NO_TIME" then
				tips:tips(CONF:getStringValue("group_join_cd"))
			elseif proto.result == "STATUS_ERROR" then
				tips:tips(CONF:getStringValue("has_garup"))
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GetMailListResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				self.mail_name_list_ = {}

				for i,v in ipairs(proto.user_sync.mail_list) do
					if v.type == 9 then
						table.insert(self.mail_name_list_, v.from)
					end
				end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_APPLY_FRIEND_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("ApplyFriendResp",strData)
			if proto.result == "FAIL" then
				print("error :",proto.result)
			else

				if proto.result == "FRIEND" then
					tips:tips("appling friend now")
				elseif proto.result == "OTHER_BLACK" then
					tips:tips(CONF:getStringValue("you in this player blacklist"))
				else
					tips:tips(CONF:getStringValue("apply friend mail is send"))
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOB_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupJobResp",strData)
			if proto.result == "FAIL" then
				print("error :",proto.result)
			else

				if proto.result == "SAME_JOB" then
					tips:tips(CONF:getStringValue("AlreadyAppoint"))
				elseif proto.result == "FULL_MANAGER" then
					tips:tips(CONF:getStringValue("AppointFail"))
				elseif proto.result == "OK" then
					tips:tips(CONF:getStringValue("successful operation"))

				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_KICK_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupKickResp",strData)
			if proto.result == "FAIL" then
				print("error :",proto.result)
			elseif proto.result == "OK" then
				tips:tips(CONF:getStringValue("successful operation"))                
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TalkListResp",strData)

			if self.scene_:getChildByName("chat_layer") then
				return
			end

			if proto.result == 1 then
				local layer = self.scene_:getApp():createView("ChatLayer/ChatLayer", {name = "chat", user_name = self.chat_user})
				layer:setName("chat_layer")
				self.scene_:addChild(layer)
			elseif proto.result ~= 0 then
				print("error :",proto.result)
			else
				local layer = self.scene_:getApp():createView("ChatLayer/ChatLayer", {name = "chat", user_name = self.chat_user})
				layer:setName("chat_layer")
				self.scene_:addChild(layer)

			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_IS_ONLINE_RESP") then
			-- gl:releaseLoading()

			local proto = Tools.decode("IsOnlineResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else

				self.online_list = {}

				for i,v in ipairs(proto.user_name_list) do
					local tt = {name = v, online = proto.is_online_list[i]}
					table.insert(self.online_list, tt)
				end

				self:resetList()

			end

		end

	end
	
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function MemberNode:getMemberOnline( user_name )
	for i,v in ipairs(self.online_list) do
		if v.name == user_name then
			return v.online
		end
	end

	return nil
end

function MemberNode:getMemberIsOnline( ... )
	local user_name_list = {}
	for i,v in ipairs(self.group_list.user_list) do
		table.insert(user_name_list, v.user_name)
	end

	for i,v in ipairs(user_name_list) do
		print(i,v)
	end

	local strData = Tools.encode("IsOnlineReq", {
		user_name_list = user_name_list,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_IS_ONLINE_REQ"),strData)
end

function MemberNode:updateUI( group_list, info_list, join_list )
	self.group_list = group_list
	self.info_list = info_list
	self.join_info_list = join_list

	-- self:resetList()
	self:getMemberIsOnline()
	
end

function MemberNode:loadInfo( ... )
	local name = {}
	for i,v in ipairs(self.group_list.join_list) do
		table.insert(name, v.user_name)
	end

	if table.getn(name) == 0 then
		self.join_info_list = {}
		self:createApply()
	else
		local strData = Tools.encode("CmdGetOtherUserInfoListReq", {
			user_name_list = name,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_REQ"),strData)

		gl:retainLoading()
	end
end

function MemberNode:resetInfo( ... )
	local rn = self:getResourceNode()
	local conf = CONF.GROUP.get(self.group_list.level)

	local max_user = conf.MAX_USER + Tools.getValueByTechnologyAddition(conf.MAX_USER, CONF.ETechTarget_1.kGroup, 0, CONF.ETechTarget_3_Group.kMaxUser, player:getTechnolgList(), player:getPlayerGroupTech())

	rn:getChildByName("member_now"):setString(table.getn(self.info_list))
	rn:getChildByName("member_max"):setString("/"..max_user)
	rn:getChildByName("member_max"):setPositionX(rn:getChildByName("member_now"):getPositionX()+rn:getChildByName("member_now"):getContentSize().width)

	if #self.group_list.join_list ~= 0 then
		rn:getChildByName("green_icon"):setVisible(true)
	else
		rn:getChildByName("green_icon"):setVisible(false)
	end

	if self.scene_:getChildByName("message") then
		self.scene_:getChildByName("message"):removeFromParent()

		self:createApply()
	end

end

function MemberNode:resetList( ... )
	local rn = self:getResourceNode()

	self.svd_:clear()

	if table.getn(self.group_list.user_list) <= 6 then
		rn:getChildByName("list"):setBounceEnabled(false)
	else
		rn:getChildByName("list"):setBounceEnabled(true)
	end

	local member_list = {}

	for i,v in ipairs(self.group_list.user_list) do
		local other_info = {}
		for ii,vv in ipairs(self.info_list) do
			if vv.user_name == v.user_name then
				other_info = vv 
			end
		end

		local member = {}
		member.user_name = v.user_name
		member.nickname = v.nickname
		member.last_act = v.last_act
		member.job = v.job
		member.level = other_info.level
		member.power = other_info.power
		member.guid = v.guid
		member.icon_id = other_info.icon_id

		table.insert(member_list, member)

	end

	local function sort( a,b )

		if self:getMemberOnline(a.user_name) == true and self:getMemberOnline(b.user_name) == false then
			return true
		end

		if self:getMemberOnline(a.user_name) == false and self:getMemberOnline(b.user_name) == true then
			return false
		end

		if a.job ~= b.job then
			return a.job < b.job
		else
			if a.power ~= b.power then
				return a.power > b.power
			else
				if a.level ~= b.level then
					return a.level > b.level
				else
					if a.guid ~= b.guid then
						return a.guid < b.guid 
					end
				end
			end
		end
	end

	table.sort( member_list, sort )

	local callback = function (event)
		if event.name == "SCROLLING" then
			if self.scene_:getChildByName("click_node") then
				local preItem = self.svd_:getScrollView():getChildByName("item_"..self.scene_:getChildByName("click_node"):getTag())
				preItem:getChildByName("select_light"):setVisible(false)
				-- preItem:getChildByName("bg"):loadTexture("ChatLayer/ui/name_bottom.png")

				if preItem:getTag()%2 == 0 then
					preItem:getChildByName("bg"):setOpacity(255*0.7)
				end

				self.scene_:getChildByName("click_node"):removeFromParent()
			end
		end
	end

	rn:getChildByName("list"):onEvent(callback)

	local function createItem(info, index)

		local item = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_member_item.csb")

		if index%2 == 0 then
			item:getChildByName("bg"):setOpacity(255*0.7)
		end

		if info.job == 1 then
			item:getChildByName("icon"):setTexture("StarLeagueScene/ui/icon_king.png")
		elseif info.job == 2 then
			item:getChildByName("icon"):setTexture("StarLeagueScene/ui/icon_king2.png")
		end

		item:getChildByName("name"):setString(info.nickname)
		item:getChildByName("lv_num"):setString(info.level)
		item:getChildByName("power_num"):setString(info.power)

		local time = player:getServerTime() - info.last_act

		if time < 0 then
			time = 0 
		end

		local str = ""

		if time < 86400 then
			if time < 3600 then
				time = math.floor(time/60)
				str = CONF:getStringValue("minutes")
			else
				time = math.floor(time/3600)
				str = CONF:getStringValue("hours")
			end
		else
			time = math.floor(time/86400)

			if time > 7 then
				time = 7
			end

			str = CONF:getStringValue("days")
		end

		if self:getMemberOnline(info.user_name) then
			item:getChildByName("time"):setString(CONF:getStringValue("online"))

			item:getChildByName("time"):setTextColor(cc.c4b(255,255,255,255))
			-- item:getChildByName("time"):enableShadow(cc.c4b(255,255,255,255), cc.size(0.5,0.5))
		else
			item:getChildByName("time"):setString(CONF:getStringValue("not_online")..time..str)
		end
	
		--setpos
		-- item:getChildByName("lv"):setPositionX(item:getChildByName("name"):getPositionX() + item:getChildByName("name"):getContentSize().width + 30)
		-- item:getChildByName("lv_num"):setPositionX(item:getChildByName("lv"):getPositionX() + item:getChildByName("lv"):getContentSize().width)
		-- item:getChildByName("icon_power"):setPositionX(item:getChildByName("lv_num"):getPositionX() + item:getChildByName("lv_num"):getContentSize().width + 60)
		-- item:getChildByName("power_num"):setPositionX(item:getChildByName("icon_power"):getPositionX() + item:getChildByName("icon_power"):getContentSize().width/2 )

		return item
	end

	for i,v in ipairs(member_list) do
		local item = createItem(v, i)
		item:setTag(i)
		item:setName("item_"..i)

		local func = function ( sender )
			if self.scene_:getChildByName("click_node") then
				local preItem = self.svd_:getScrollView():getChildByName("item_"..self.scene_:getChildByName("click_node"):getTag())
				preItem:getChildByName("select_light"):setVisible(false)
				-- preItem:getChildByName("bg"):loadTexture("ChatLayer/ui/name_bottom.png")

				if preItem:getTag()%2 == 0 then
					preItem:getChildByName("bg"):setOpacity(255*0.7)
				end
				if self.scene_:getChildByName("click_node"):getTag() == item:getTag() then
					self.scene_:getChildByName("click_node"):removeFromParent()
					return
				else
					self.scene_:getChildByName("click_node"):removeFromParent()
				end
			end

			if v.user_name == player:getName() then
				return
			end

			item:getChildByName("select_light"):setVisible(true)
			-- item:getChildByName("bg"):loadTexture("NoStarLeagueLayer/ui/select_light.png")
			-- item:getChildByName("bg"):setOpacity(255)

			local click_node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/member_click.csb")
			click_node:getChildByName("see"):getChildByName("text"):setString(CONF:getStringValue("Check"))
			click_node:getChildByName("see"):addClickEventListener(function ( ... )

				local tt = {info = self:getChatNode(v.user_name)}

				local node = app:createView("ChatLayer/ChatNode2", {data = tt})
				node:setName("chatNode")
				node:setPosition(cc.p(self.scene_:getResourceNode():getChildByName("chat_node_pos"):getPosition()))
				self.scene_:addChild(node)

				self:unLightItem()
				-- click_node:removeFromParent()
			end)

			click_node:getChildByName("friend"):getChildByName("text"):setString(CONF:getStringValue("addFriend"))
			click_node:getChildByName("friend"):addClickEventListener(function ( ... )
				local flag = true

				for ii,vv in ipairs(self.mail_name_list_) do
					if vv == v.user_name then
						flag = false
					end
				end
					
				if player:isBlack(v.user_name) then
					tips:tips(CONF:getStringValue("this player in you blacklist"))
					return                           
				end
					
				if flag then

					local strData = Tools.encode("ApplyFriendReq", {
						recver = v.user_name,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_APPLY_FRIEND_REQ"),strData)

					gl:retainLoading()
				
				else
					tips:tips("this player is apply friend for you now")
				end

				self:unLightItem()
				-- click_node:removeFromParent()
			end)

			click_node:getChildByName("chat"):getChildByName("text"):setString(CONF:getStringValue("privateChat"))
			click_node:getChildByName("chat"):addClickEventListener(function ( ... )

				self.chat_user = v.user_name

				local strData = Tools.encode("TalkListReq", {
					type = 1,
					user_name = v.user_name,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_REQ"),strData)

				gl:retainLoading()

				self:unLightItem()
				-- click_node:removeFromParent()
			end)

			click_node:getChildByName("mail"):getChildByName("text"):setString(CONF:getStringValue("mail"))
			click_node:getChildByName("mail"):addClickEventListener(function ( ... )
				local sendLayer = require("app.views.MailScene.SendMail"):create()
				self:getParent():addChild(sendLayer)
				sendLayer:init(v.nickname,v.user_name)

				self:unLightItem()
				-- click_node:removeFromParent()
			end)

			click_node:getChildByName("chairman"):getChildByName("text"):setString(CONF:getStringValue("appoint"))
			click_node:getChildByName("chairman"):addClickEventListener(function ( ... )
				local strData = Tools.encode("GroupJobReq", {
					user_name = v.user_name,
					job = 2,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOB_REQ"),strData)

				gl:retainLoading()

				self:unLightItem()
				-- click_node:removeFromParent()
			end)

			click_node:getChildByName("avalon"):getChildByName("text"):setString(CONF:getStringValue("avalon"))
			click_node:getChildByName("avalon"):addClickEventListener(function ( ... )
				local strData = Tools.encode("GroupJobReq", {
					user_name = v.user_name,
					job = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOB_REQ"),strData)

				gl:retainLoading()

				self:unLightItem()
				-- click_node:removeFromParent()
			end)

			click_node:getChildByName("relieve"):getChildByName("text"):setString(CONF:getStringValue("relieve"))
			click_node:getChildByName("relieve"):addClickEventListener(function ( ... )
				local strData = Tools.encode("GroupJobReq", {
					user_name = v.user_name,
					job = 3,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOB_REQ"),strData)

				gl:retainLoading()

				self:unLightItem()
				-- click_node:removeFromParent()
			end)

			click_node:getChildByName("kick"):getChildByName("text"):setString(CONF:getStringValue("kick"))
			click_node:getChildByName("kick"):addClickEventListener(function ( ... )
				local strData = Tools.encode("GroupKickReq", {
					user_name = v.user_name,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_KICK_REQ"),strData)

				gl:retainLoading()

				self:unLightItem()
				-- click_node:removeFromParent()
			end)

			local num = 0
			if player:isFriend(v.user_name) or v.user_name == player:getName() then
				click_node:getChildByName("friend"):removeFromParent()

				click_node:getChildByName("chat"):setPositionY(click_node:getChildByName("chat"):getPositionY() + 40)
				click_node:getChildByName("mail"):setPositionY(click_node:getChildByName("mail"):getPositionY() + 40)
				click_node:getChildByName("chairman"):setPositionY(click_node:getChildByName("chairman"):getPositionY() + 40)
				click_node:getChildByName("avalon"):setPositionY(click_node:getChildByName("avalon"):getPositionY() + 40)
				click_node:getChildByName("kick"):setPositionY(click_node:getChildByName("kick"):getPositionY() + 40)
				click_node:getChildByName("relieve"):setPositionY(click_node:getChildByName("relieve"):getPositionY() + 40)

				num = num + 1
			end

			local job = player:getGroupData().job

			for k,v in ipairs(self.group_list.user_list) do
				if v.user_name == player:getName() then
					job = v.job
					break
				end
			end

			if job == 1 then
				if v.job == 2 then
					click_node:getChildByName("chairman"):removeFromParent()

					click_node:getChildByName("relieve"):setPositionY(click_node:getChildByName("relieve"):getPositionY() + 40)
					click_node:getChildByName("kick"):setPositionY(click_node:getChildByName("kick"):getPositionY() + 40)
					click_node:getChildByName("avalon"):setPositionY(click_node:getChildByName("avalon"):getPositionY() + 40)

					num = num + 1 
				elseif v.job == 3 then
					click_node:getChildByName("relieve"):removeFromParent()

					click_node:getChildByName("kick"):setPositionY(click_node:getChildByName("kick"):getPositionY() + 40)
					click_node:getChildByName("avalon"):setPositionY(click_node:getChildByName("avalon"):getPositionY() + 40)

					num = num + 1
				end
			end

			if job == 2 then

				click_node:getChildByName("avalon"):removeFromParent()
				click_node:getChildByName("chairman"):removeFromParent()
				click_node:getChildByName("relieve"):removeFromParent()
				if v.job == 3 then
					
					click_node:getChildByName("kick"):setPositionY(click_node:getChildByName("kick"):getPositionY() + 120)

					num = num + 3
				elseif v.job == 2 then

					click_node:getChildByName("kick"):removeFromParent()
					num = num + 4

				elseif v.job == 1 then

					click_node:getChildByName("kick"):removeFromParent()
					num = num + 4
				end
			end
					   
			if job == 3 then
				click_node:getChildByName("avalon"):removeFromParent()
				click_node:getChildByName("chairman"):removeFromParent()
				click_node:getChildByName("kick"):removeFromParent()
				click_node:getChildByName("relieve"):removeFromParent()

				num = num + 4
			end

			click_node:getChildByName("bg"):setContentSize(cc.size(click_node:getChildByName("bg"):getContentSize().width, click_node:getChildByName("bg"):getContentSize().height - num*40))

			click_node:setPosition(cc.p(item:getChildByName("node"):convertToWorldSpace(cc.p(0,0)).x - self:getPositionX(), item:getChildByName("node"):convertToWorldSpace(cc.p(0,0)).y - self:getPositionY()))

			if click_node:convertToWorldSpace(cc.p(0,0)).y < winSize.height/2 then
				click_node:setPositionY(click_node:getPositionY() + 150)
			end
			click_node:setName("click_node")
			click_node:setTag(item:getTag())

			self.scene_:addChild(click_node)

		end

		local callback = {node = item:getChildByName("bg"), func = func}


		self.svd_:addElement(item, {callback = callback})
	end

	self:resetInfo()
end

function MemberNode:getIsExit( ... )
	return false
end

function MemberNode:createApply( ... )
    local rn = self:getResourceNode()
	if self.scene_:getChildByName("message") then
		self.scene_:getChildByName("message"):removeFromParent()
	end
	local node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/MessageNode.csb")

	node:getChildByName("back"):setSwallowTouches(true)

	node:getChildByName("close"):addClickEventListener(function ( ... )
		node:removeFromParent()
	end) 

	local apply_node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_member_apply.csb")

	apply_node:getChildByName("text"):setString(CONF:getStringValue("ListIsEmpty"))
	apply_node:getChildByName("text_0"):setString(CONF:getStringValue("apply_list"))

	if #self.group_list.join_list == 0 then
		apply_node:getChildByName("text"):setVisible(true)
	else
		apply_node:getChildByName("text"):setVisible(false)
	end

	apply_node:getChildByName("list"):setScrollBarEnabled(false)
	self.apply_svd = require("util.ScrollViewDelegate"):create(apply_node:getChildByName("list"),cc.size(2,2), cc.size(661,82))

	local function createApplyItem( info )

		local other_info = {}
		for i,v in ipairs(self.join_info_list) do
			if v.user_name == info.user_name then
				other_info = v 
			end
		end

		local item = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_member_apply_item.csb")
		item:getChildByName("tongyi"):getChildByName("text"):setString(CONF:getStringValue("accept"))
		item:getChildByName("jujue"):getChildByName("text"):setString(CONF:getStringValue("refuse"))

		item:getChildByName("head"):setTexture("HeroImage/"..other_info.icon_id..".png")
		item:getChildByName("name"):setString(other_info.nickname)
		item:getChildByName("lv_num"):setString(other_info.level)
		item:getChildByName("fight_num"):setString(other_info.power)

		item:getChildByName("lv"):setPositionX(item:getChildByName("name"):getPositionX() + item:getChildByName("name"):getContentSize().width + 10)
		item:getChildByName("lv_num"):setPositionX(item:getChildByName("lv"):getPositionX() + item:getChildByName("lv"):getContentSize().width + 1)

		item:getChildByName("tongyi"):addClickEventListener(function ( ... )
			local job = player:getGroupData().job

			for k,v in ipairs(self.group_list.user_list) do
				if v.user_name == player:getName() then
					job = v.job
					break
				end
			end
			print("job", player:getGroupData().job)
			if job == 3 then
				tips:tips(CONF:getStringValue("Permission denied"))
				return
			end

			self.apply_index = item:getTag()

			local strData = Tools.encode("GroupAllowReq", {
				username = info.user_name,
				type = 0,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_ALLOW_REQ"),strData)

			gl:retainLoading()
            item:removeFromParent()
		end)

		item:getChildByName("jujue"):addClickEventListener(function ( ... )
			local job = player:getGroupData().job

			for k,v in ipairs(self.group_list.user_list) do
				if v.user_name == player:getName() then
					job = v.job
					break
				end
			end
			print("job", player:getGroupData().job)

			if job == 3 then
				tips:tips(CONF:getStringValue("Permission denied"))
				return
			end

			self.apply_index = item:getTag()

			local strData = Tools.encode("GroupAllowReq", {
				username = info.user_name,
				type = 1,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_ALLOW_REQ"),strData)

			gl:retainLoading()
            item:removeFromParent()
		end)

		return item
	end

	for i,v in ipairs(self.group_list.join_list) do
		local item = createApplyItem(v)
		item:setTag(i)
		item:setName("apply_item_"..i)

		self.apply_svd:addElement(item)
	end
    node:setPosition(cc.exports.VisibleRect:leftBottom())
	--local center = cc.exports.VisibleRect:center()
	--node:setPosition(cc.p(center.x - node:getChildByName("back"):getContentSize().width/2, center.y - node:getChildByName("back"):getContentSize().height/2))
	node:addChild(apply_node)
	node:setName("message")
    rn:addChild(node)
--	self.scene_:addChild(node)

end

function MemberNode:getChatNode( user_name )
	for i,v in ipairs(self.info_list) do
		if v.user_name == user_name then
			return v
		end
	end

	return nil
end

function MemberNode:unLightItem()
	local preItem = self.svd_:getScrollView():getChildByName("item_"..self.scene_:getChildByName("click_node"):getTag())
	preItem:getChildByName("select_light"):setVisible(false)
	-- preItem:getChildByName("bg"):loadTexture("ChatLayer/ui/name_bottom.png")

	if preItem:getTag()%2 == 0 then
		preItem:getChildByName("bg"):setOpacity(255*0.7)
	end

	self.scene_:getChildByName("click_node"):removeFromParent()
end

function MemberNode:onExitTransitionStart()
	printInfo("MemberNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end

return MemberNode