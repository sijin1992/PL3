
local BlackNode = class("BlackNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

BlackNode.RESOURCE_FILENAME = "FriendLayer/black_list.csb"

function BlackNode:onEnterTransitionFinish()

end

function BlackNode:init(scene,data)

	self.scene_ = scene

	self.select_index = 0

	local rn = self:getResourceNode()
	rn:getChildByName("text"):setString(CONF:getStringValue("no_black_friend"))
	rn:getChildByName("Text_1"):setString(CONF:getStringValue("sumNum"))
	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(0,0), cc.size(815,109))

	-- if player:getFriendsNum(2) ~= 0 then
		
	-- end

	local strData = Tools.encode("GetFriendsInfoReq", {
		type = 2,
		index = 1,
		num = 999,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

	
	local function recvMsg()

		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_RESP") then

			local proto = Tools.decode("GetFriendsInfoResp",strData)
			
			if proto.result == 2 then
				self.black_list_ = {}

				self:resetInfo()

				self:resetList()

			elseif proto.result < 0 then
				print("error :",proto.result)
			else
				self.black_list_ = proto.list

				self:resetInfo()

				self:resetList()
				
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("BlackListResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				player:removeBlack(self.black_name)

				local strData = Tools.encode("GetFriendsInfoReq", {
					type = 2,
					index = 1,
					num = 5,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function BlackNode:resetList()
	local rn = self:getResourceNode()

	self.svd_:clear()

	if table.getn(self.black_list_) > 0 then
		rn:getChildByName("text"):setVisible(false)           
	else
		rn:getChildByName("text"):setVisible(true)
		return
	end

	if table.getn(self.black_list_) <= 4 then
		rn:getChildByName("list"):setBounceEnabled(false)
	else
		rn:getChildByName("list"):setBounceEnabled(true)
	end

	local function createListItem(name)
		local node = require("app.ExResInterface"):getInstance():FastLoad("FriendLayer/black_list_item.csb")

		node:getChildByName("botton"):addClickEventListener(function(sender )

			self.black_name = name

			local strData = Tools.encode("BlackListReq", {
				type = 2,
				user_name = name,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BLACK_LIST_REQ"),strData)

			gl:retainLoading()
		end)

		return node
	end

	for i,v in ipairs(self.black_list_) do
		local item = createListItem(v.user_name)

		item:getChildByName("name"):setString(v.nickname)
		item:getChildByName("lv_num"):setString(v.level)
		item:getChildByName("fight_num"):setString(v.power)
		item:getChildByName("head"):setTexture("HeroImage/"..v.icon_id..".png")
		item:getChildByName("xingmeng_name"):setString(v.group_nickname)

		if v.group_nickname == "" then
			item:getChildByName("xingmeng_name"):setString(CONF:getStringValue("leagueNmae"))
		end
		item:getChildByName("xingmeng"):setString(CONF:getStringValue("covenant")..":")
		item:getChildByName("botton"):getChildByName("text"):setString(CONF:getStringValue("relieve"))

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

function BlackNode:resetInfo()
	local rn = self:getResourceNode()
	
	rn:getChildByName("friend_num"):setString(#self.black_list_)
	rn:getChildByName("friend_max_num"):setString("/"..CONF.PLAYERLEVEL.get(player:getLevel()).BLACK_NUM)
	rn:getChildByName("friend_max_num"):setPositionX(rn:getChildByName("friend_num"):getPositionX() + rn:getChildByName("friend_num"):getContentSize().width+1)
end

function BlackNode:selectItem(item, flag)

	item:getChildByName("selected"):setVisible(flag)

	--item:getChildByName("lv"):setPositionX(item:getChildByName("name"):getPositionX() + item:getChildByName("name"):getContentSize().width*item:getChildByName("name"):getScale() + 20)
	--item:getChildByName("lv_num"):setPositionX(item:getChildByName("lv"):getPositionX() + item:getChildByName("lv"):getContentSize().width*item:getChildByName("lv"):getScale() + 10)
	item:getChildByName("fight_num"):setPositionX(item:getChildByName("fight"):getPositionX() + item:getChildByName("fight"):getContentSize().width/2*item:getChildByName("fight"):getScale() + 10)
	item:getChildByName("xingmeng_name"):setPositionX(item:getChildByName("xingmeng"):getPositionX() + item:getChildByName("xingmeng"):getContentSize().width*item:getChildByName("xingmeng"):getScale() + 5)
end

function BlackNode:onExitTransitionStart()
	printInfo("BlackNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end

return BlackNode