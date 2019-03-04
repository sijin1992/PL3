
local FriendNode = class("FriendNode", cc.load("mvc").ViewBase)

local winSize = cc.Director:getInstance():getWinSize()

local app = require("app.MyApp"):getInstance()

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

FriendNode.RESOURCE_FILENAME = "FriendLayer/friend_list.csb"

local bAutoAllAddFriendTili = false

function FriendNode:onEnterTransitionFinish()

end

local function sort(a,b)
	if not a or not b then
		return false
	end
	local fa1 = player:GetFriendFamiliarity(a.user_name)
	local fa2 = player:GetFriendFamiliarity(b.user_name)
	if fa1 > fa2 then
		return true
	end
	if fa2 == fa1 then
		if a.power and b.power and a.power > b.power then
			return true
		end
	end
	return false
end

function FriendNode:init(scene,data)

	self.scene_ = scene

	self.select_index = 0

	local rn = self:getResourceNode()
	rn:getChildByName("Text_1"):setString(CONF:getStringValue("sumNum"))
	rn:getChildByName("text"):setString(CONF:getStringValue("no_friend"))

	rn:getChildByName("tili_add_but"):getChildByName("text"):setString("One key gift")
	rn:getChildByName("tili_read_but"):getChildByName("text"):setString(CONF:getStringValue("getAll"))

	rn:getChildByName("list"):setScrollBarEnabled(false)
	local tempItem = require("app.ExResInterface"):getInstance():FastLoad("FriendLayer/friend_list_item.csb")
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(0,0), tempItem:getChildByName("background"):getContentSize())

	-- if player:getFriendsNum(1) ~= 0 then
		
	-- end

	local strData = Tools.encode("GetFriendsInfoReq", {
		type = 1,
		index = 1,
		num = 999,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

	local function recvMsg()
		print("FriendNode:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_CHAT_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("ChatResp",strData)

			if proto.result == "FAIL" then
				print("error :",proto.result)
			elseif proto.result == "DIRTY" then
				tips:tips(CONF:getStringValue("dirty_message"))
			else
				print("chat ok")                
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_RESP") then

			local proto = Tools.decode("GetFriendsInfoResp",strData)
			print("GetFriendsInfoResp")
			print(proto.result)
			
			if proto.result == 2 then

				if rn:getChildByName("click_node") then
					rn:getChildByName("click_node"):removeFromParent()
				end

				self.friend_list_ = {}

				self:resetInfo()

				self:setList()

			elseif proto.result ~= 0 then
				print("error :",proto.result)

			else
				if rn:getChildByName("click_node") then
					rn:getChildByName("click_node"):removeFromParent()
				end

				self.friend_list_ = proto.list

				table.sort(self.friend_list_,sort)

				self:resetInfo()

				self:setList()
				
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("BlackListResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				
				tips:tips(CONF:getStringValue("add black ok"))
				player:addBlack(self.black_name)

				local strData = Tools.encode("GetFriendsInfoReq", {
					type = 1,
					index = 1,
					num = 999,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_REMOVE_FRIEND_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("RemoveFriendResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				player:removeFriend(self.remove_friend_name)

				-- local strData = Tools.encode("GetFriendsInfoReq", {
				--     type = 1,
				--     index = 1,
				--     num = 999,
				-- })
				-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TalkListResp",strData)

			if proto.result == 1 then
				self.scene_:chat(self.talk_name)
			elseif proto.result ~= 0 then
				print("error :",proto.result)
			else
				self.scene_:chat(self.talk_name)
				-- tips:tips("add chat list ok")

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("CmdGetOtherUserInfoResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
			else

				if rn:getChildByName("click_node") then
					rn:getChildByName("click_node"):removeFromParent()
				end

				local node = app:createView("ChatLayer/ChatNode2", {data = proto})
				node:setName("chatNode")
				node:setPosition(cc.p(self.scene_:getResourceNode():getChildByName("chat_node_pos"):getPosition()))
				self.scene_:addChild(node)
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_FRIEND_TILI_UPDATE") then
			print("CMD_FRIEND_TILI_UPDATE")
			self:setList()
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_FRIEND_ADD_TILI_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("FriendAddTiliResp",strData)
			print("FriendAddTiliResp",proto.result)
			if bAutoAllAddFriendTili then
				self:AutoAllAddFriendTili()
			end
			if not bAutoAllAddFriendTili then
				if proto.result == 0 then
					tips:tips(CONF:getStringValue("strength_give"))
				end
				self:setList()
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_FRIEND_READ_TILI_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("FriendReadTiliResp",strData)
			print("FriendAddTiliResp",proto.result)
			if proto.result == 0 then
				player:userSync(proto.user_sync)
				local str = CONF:getStringValue("strength_receive")
				str = string.gsub(str, "#",proto.all_tili)
				tips:tips(str)
				self:setList()
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.updateListener_ = cc.EventListenerCustom:create("BeFriendUpdate", function ()
		local strData = Tools.encode("GetFriendsInfoReq", {
			type = 1,
			index = 1,
			num = 999,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.updateListener_, FixedPriority.kNormal)


	rn:getChildByName("tili_add_but"):addClickEventListener(function()
		bAutoAllAddFriendTili = true
		self:AutoAllAddFriendTili()
	end)

	rn:getChildByName("tili_read_but"):addClickEventListener(function()
		local list = player:GetFriendReadTili()
		if list then
			local user_list = {}			
			for _, v in ipairs(list) do
				table.insert(user_list,v)
			end
			if #user_list > 0 then
				local strData = Tools.encode("FriendReadTiliReq", {   
					user_name = user_list
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_FRIEND_READ_TILI_REQ"),strData)
				gl:retainLoading()
			end
		end
	end)
end

local autoTmpAddFriendTili = {}
function FriendNode:AutoAllAddFriendTili()
	for i,v in ipairs(self.friend_list_) do
		if player:isFriendAddTili(v.user_name) == false and autoTmpAddFriendTili[v.user_name] == nil then
			local strData = Tools.encode("FriendAddTiliReq", {   
				user_name = v.user_name
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_FRIEND_ADD_TILI_REQ"),strData)
			autoTmpAddFriendTili[v.user_name] = 1
			gl:retainLoading()
			return
		end
	end
	bAutoAllAddFriendTili = false
	autoTmpAddFriendTili = {}
end


function FriendNode:setList( )

	local rn = self:getResourceNode()

	self.svd_:clear()

	if table.getn(self.friend_list_) > 0 then
		rn:getChildByName("text"):setVisible(false)       
	else
		rn:getChildByName("text"):setVisible(true)
		return
	end

	if table.getn(self.friend_list_) <= 4 then
		rn:getChildByName("list"):setBounceEnabled(false)
	else
		rn:getChildByName("list"):setBounceEnabled(true)
	end

	local callback = function (event)
		if event.name == "SCROLLING" then
			if rn:getChildByName("click_node") then
				rn:getChildByName("click_node"):removeFromParent()
			end

			if self.select_index ~= 0 then
				self:selectItem(self.svd_:getScrollView():getChildByName("node_"..self.select_index), false)
				self.select_index = 0
			end
		end
	end

	rn:getChildByName("list"):onEvent(callback)

	local function createClickNode(name, nickname)
		local node = require("app.ExResInterface"):getInstance():FastLoad("FriendLayer/friend_click.csb")
		node:getChildByName("see"):getChildByName("text"):setString(CONF:getStringValue("Check"))
		node:getChildByName("see"):addClickEventListener(function ( sender )
			if self.scene_:getChildByName("chatNode") then
				self.scene_:getChildByName("chatNode"):removeFromParent()
			end

			local strData = Tools.encode("CmdGetOtherUserInfoReq", {
				user_name = name,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_REQ"),strData)

			gl:retainLoading()

			-- node:removeFromParent()
		end)

		node:getChildByName("siliao"):getChildByName("text"):setString(CONF:getStringValue("privateChat"))
		node:getChildByName("siliao"):addClickEventListener(function ( sender )

			self.talk_name = name

			local strData = Tools.encode("TalkListReq", {
				type = 1,
				user_name = name,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TALK_LIST_REQ"),strData)

			gl:retainLoading()

			node:removeFromParent()
		end)

		node:getChildByName("black"):getChildByName("text"):setString(CONF:getStringValue("black"))
		node:getChildByName("black"):addClickEventListener(function ( sender )

			if player:getFriendsNum(2) == CONF.PLAYERLEVEL.get(player:getLevel()).BLACK_NUM then
				tips:tips(CONF:getStringValue("blackListIsFull"))
				return
			end

			self.black_name = name

			local strData = Tools.encode("BlackListReq", {
				type = 1,
				user_name = name,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_REQ"),strData)

			gl:retainLoading()

			node:removeFromParent()
		end)

		node:getChildByName("mail"):getChildByName("text"):setString(CONF:getStringValue("mail"))
		node:getChildByName("mail"):addClickEventListener(function ( sender )
			local sendLayer = require("app.views.MailScene.SendMail"):create()
			self:getParent():addChild(sendLayer)
			sendLayer:init(nickname,name)

			node:removeFromParent()
		end)

		node:getChildByName("delete"):getChildByName("text"):setString(CONF:getStringValue("relieve"))
		node:getChildByName("delete"):addClickEventListener(function ( sender )

			self.remove_friend_name = name

			local strData = Tools.encode("RemoveFriendReq", {
				user_name = name,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_REMOVE_FRIEND_REQ"),strData)

			gl:retainLoading()

			node:removeFromParent()
		end)

		return node

	end

	for i,v in ipairs(self.friend_list_) do
		local node = require("app.ExResInterface"):getInstance():FastLoad("FriendLayer/friend_list_item.csb")
		node:getChildByName("name"):setString(v.nickname)
		node:getChildByName("lv_num"):setString(v.level)
		node:getChildByName("fight_num"):setString(v.power)
		node:getChildByName("head"):setTexture("HeroImage/"..v.icon_id..".png")
		node:getChildByName("xingmeng"):setString(CONF:getStringValue("covenant")..":")
		node:getChildByName("xingmeng_name"):setString(v.group_nickname)

		if v.group_nickname == "" then
			node:getChildByName("xingmeng_name"):setString(CONF:getStringValue("leagueNmae"))
		end

		--node:getChildByName("lv"):setPositionX(node:getChildByName("name"):getPositionX() + node:getChildByName("name"):getContentSize().width*node:getChildByName("name"):getScale() + 20)
		--node:getChildByName("lv_num"):setPositionX(node:getChildByName("lv"):getPositionX() + node:getChildByName("lv"):getContentSize().width*node:getChildByName("lv"):getScale() + 10)
		node:getChildByName("fight_num"):setPositionX(node:getChildByName("fight"):getPositionX() + node:getChildByName("fight"):getContentSize().width/2*node:getChildByName("fight"):getScale() + 10)
		node:getChildByName("xingmeng_name"):setPositionX(node:getChildByName("xingmeng"):getPositionX() + node:getChildByName("xingmeng"):getContentSize().width*node:getChildByName("xingmeng"):getScale() + 5)

		node:setTag(i)
		node:setName("node_"..i)

		node:getChildByName("qingmi_test"):setString(tostring(player:GetFriendFamiliarity(v.user_name)))		

		local func = function( ... )
			if rn:getChildByName("click_node") then
				local tag = rn:getChildByName("click_node"):getTag()
				rn:getChildByName("click_node"):removeFromParent()
			end

			if self.select_index ~= 0 then 

				self:selectItem(self.svd_:getScrollView():getChildByName("node_"..self.select_index), false)

				if node:getTag() == self.select_index then
					self.select_index = 0
					return
				else 
					self:selectItem(node, true)

					self.select_index = node:getTag()
				end
			else
				self:selectItem(node, true)

				self.select_index = node:getTag()
			end

			local click_node = createClickNode(v.user_name, v.nickname)
			rn:addChild(click_node)
			click_node:setTag(i)
			click_node:setName("click_node")

			click_node:setPosition(cc.p(node:getChildByName("node"):convertToWorldSpace(cc.p(0,0)).x - self:convertToWorldSpace(cc.p(0,0)).x, node:getChildByName("node"):convertToWorldSpace(cc.p(0,0)).y - self:convertToWorldSpace(cc.p(0,0)).y))

			if click_node:convertToWorldSpace(cc.p(0,0)).y < winSize.height/2 then
				click_node:setPositionY(click_node:getPositionY() + 150)
			end
		end



		local callback = {node = node:getChildByName("background"), func = func}

		local nowtime = v.last_act
		if nowtime == nil then
			node:getChildByName("line_time"):setVisible(false)
		else
			local time = player:getServerTime() - nowtime
			if time < 400 then
				node:getChildByName("line_time"):setString(CONF:getStringValue("online"))
			else
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
				node:getChildByName("line_time"):setString(CONF:getStringValue("not_online")..time..str)
			end
		end

		if player:isFriendAddTili(v.user_name) then
			node:getChildByName("add_tili_but"):setEnabled(false)
		end
		node:getChildByName("add_tili_but"):addClickEventListener(function (sender)
			local strData = Tools.encode("FriendAddTiliReq", {   
				user_name = v.user_name
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_FRIEND_ADD_TILI_REQ"),strData)
			gl:retainLoading()
		end)

		if player:isFriendReadTili(v.user_name) == false then
			--node:getChildByName("read_tili_but"):setEnabled(false)
			node:getChildByName("read_tili_but"):setVisible(false)
		end
		node:getChildByName("read_tili_but"):addClickEventListener(function (sender)
			local strData = Tools.encode("FriendReadTiliReq", {   
				user_name = {v.user_name}
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_FRIEND_READ_TILI_REQ"),strData)
			gl:retainLoading()
		end)

		self.svd_:addElement(node, {callback = callback})
	end

end

function FriendNode:resetInfo( ... )
	local rn = self:getResourceNode()

	rn:getChildByName("friend_num"):setString(#self.friend_list_)
	rn:getChildByName("friend_max_num"):setString("/"..CONF.PLAYERLEVEL.get(player:getLevel()).FRIEND_NUM)
	rn:getChildByName("friend_max_num"):setPositionX(rn:getChildByName("friend_num"):getPositionX() + rn:getChildByName("friend_num"):getContentSize().width+1)
end

function FriendNode:selectItem(item, flag)
	item:getChildByName("selected"):setVisible(flag)

	--item:getChildByName("lv"):setPositionX(item:getChildByName("name"):getPositionX() + item:getChildByName("name"):getContentSize().width*item:getChildByName("name"):getScale() + 20)
	--item:getChildByName("lv_num"):setPositionX(item:getChildByName("lv"):getPositionX() + item:getChildByName("lv"):getContentSize().width*item:getChildByName("lv"):getScale() + 10)
	item:getChildByName("fight_num"):setPositionX(item:getChildByName("fight"):getPositionX() + item:getChildByName("fight"):getContentSize().width/2*item:getChildByName("fight"):getScale() + 10)
	item:getChildByName("xingmeng_name"):setPositionX(item:getChildByName("xingmeng"):getPositionX() + item:getChildByName("xingmeng"):getContentSize().width*item:getChildByName("xingmeng"):getScale() + 5)
end

function FriendNode:resetList()
	self:selectItem(self.svd_:getScrollView():getChildByName("node_"..self.select_index), false)
end

function FriendNode:onExitTransitionStart()
	printInfo("FriendNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.updateListener_)

end

return FriendNode