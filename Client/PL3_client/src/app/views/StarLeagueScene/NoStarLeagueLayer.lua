local player = require("app.Player"):getInstance()
local animManager = require("app.AnimManager"):getInstance()
local tips = require("util.TipsMessage"):getInstance()
local gl = require("util.GlobalLoading"):getInstance()
local scheduler = cc.Director:getInstance():getScheduler()
local winSize = cc.Director:getInstance():getWinSize()
local NoStarLeagueLayer = class("NoStarLeagueLayer", cc.load("mvc").ViewBase)

NoStarLeagueLayer.RESOURCE_FILENAME = "StarLeagueScene/NoStarLeagueLayer.csb"
NoStarLeagueLayer.NEED_ADJUST_POSITION = true
NoStarLeagueLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function NoStarLeagueLayer:OnBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			if self.data_ and self.data_.from and self.data_.from == 'PlanetUILayer' then
				self:getApp():pushToRootView("PlanetScene/PlanetScene")
			else
				self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
			end
		 end
	end
end

function NoStarLeagueLayer:createItem( info, index )
	local node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/LeagueNode.csb")

	if index%2 == 0 then
		node:getChildByName("bg"):setOpacity(255*0.7)
	end

	node:getChildByName("apply"):getChildByName("text"):setString(CONF:getStringValue("apply"))
	node:getChildByName("undo_apply"):getChildByName("text"):setString(CONF:getStringValue("backout"))

	node:getChildByName("select_light"):setVisible(false)
	node:getChildByName("icon"):setTexture("StarLeagueScene/ui/icon_star_0"..info.icon_id..".png")

	node:getChildByName("name"):setString(info.name)
	node:getChildByName("chairman"):setString(info.chairman)
	node:getChildByName("level"):setString(info.level)
	node:getChildByName("power"):setString(info.power)
	node:getChildByName("people_now"):setString(info.people)
	node:getChildByName("people_max"):setString("/"..CONF.GROUP.get(info.level).MAX_USER)

	local intro = node:getChildByName("intro")
	local levelLimit = CONF:getStringValue("levelLimit") .. ":" .. info.join_condition.level
	local powerLimit = CONF:getStringValue("powerLimit")..":" .. info.join_condition.power
	node:getChildByName("intro_text"):setString(info.blurb.. "  " .. levelLimit .. " " .. powerLimit)
	node:getChildByName("intro_text"):setPositionX(intro:getPositionX() + intro:getContentSize().width + 2)
	if not info.join_condition.needAllow then
		node:getChildByName("apply"):getChildByName("text"):setString(CONF:getStringValue("join"))
	end

	if info.people == CONF.GROUP.get(info.level).MAX_USER then
		node:getChildByName("apply"):setEnabled(false)
		node:getChildByName("apply"):getChildByName("text"):setString(CONF:getStringValue("can't join"))
	end

	node:getChildByName("apply"):addClickEventListener(function ( sender )

		playEffectSound("sound/system/click.mp3")

		-- if player:getLevel() < info.join_condition.level then
		-- 	tips:tips(CONF:getStringValue("level_not_enought"))
		-- 	return
		-- end

		-- if player:getPower() < info.join_condition.power then
		-- 	tips:tips(CONF:getStringValue("power_not_enough"))
		-- 	return
		-- end

		print(player:getGroupData().today_join_num)

		self.join_index = index 
		self.isJoin_ = true
		local strData = Tools.encode("GroupJoinReq", {
			groupid = info.groupid,
			type = 1,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOIN_REQ"),strData)

		gl:retainLoading()
		if not info.join_condition.needAllow then
			tips:tips(CONF:getStringValue("joinSucess"))
		else
			tips:tips(CONF:getStringValue("applySucess"))
		end

	end)

	node:getChildByName("undo_apply"):addClickEventListener(function ( sender )

		playEffectSound("sound/system/click.mp3")
		self.join_index = index 
		self.isJoin_ = true
		local strData = Tools.encode("GroupJoinReq", {
			groupid = info.groupid,
			type = 2,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOIN_REQ"),strData)
		tips:tips(CONF:getStringValue("backoutSucess"))
		gl:retainLoading()
	end)

	if info.isApply then
		node:getChildByName("undo_apply"):setVisible(true)
		node:getChildByName("apply"):setVisible(false)
	else
		node:getChildByName("undo_apply"):setVisible(false)
		node:getChildByName("apply"):setVisible(true)
	end

	return node
end


function NoStarLeagueLayer:onCreate(data)
	self.data_ = data
end

function NoStarLeagueLayer:init( scene )
	self.scene_ = scene
end

function NoStarLeagueLayer:onEnterTransitionFinish()

	self.isJoin_ = false

	printInfo("NoStarLeagueLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()
	rn:getChildByName("back"):getChildByName("text"):setString(CONF:getStringValue("back"))
	rn:getChildByName("establish"):getChildByName("text"):setString(CONF:getStringValue("establish"))
	rn:getChildByName("Text_1_0_0_0_0_0"):setString(CONF:getStringValue("sumMember"))
	rn:getChildByName("Text_1_0_0_0_0"):setString(CONF:getStringValue("sumPower"))
	rn:getChildByName("Text_1_0_0_0"):setString(CONF:getStringValue("leagueLever"))
	rn:getChildByName("Text_1_0_0"):setString(CONF:getStringValue("leader"))
	rn:getChildByName("Text_1_0"):setString(CONF:getStringValue("leagueName"))
	rn:getChildByName("Text_1"):setString(CONF:getStringValue("covenant"))
	rn:getChildByName("text"):setString(CONF:getStringValue("group_list_null"))

	self.select_index = 0
	self.search_ = "page"
	self.loading = false
	self.page_ = 1

	rn:getChildByName("list"):setScrollBarEnabled(false)

	local callback = function (event)
		if event.name == "SCROLL_TO_BOTTOM" then
			if self.loading == false then
				self.page_ = self.page_ + 1
				self.search_ = "add"

				local strData = Tools.encode("GroupSearchReq", {
					page = self.page_
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_SEARCH_REQ"),strData)

				gl:retainLoading()

				rn:getChildByName("list"):setTouchEnabled(false)
				self.loading = true
			end
		end
	end

	rn:getChildByName("list"):onEvent(callback)

	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(2,2), cc.size(993,82))

	animManager:runAnimOnceByCSB(rn, "StarLeagueScene/NoStarLeagueLayer.csb", "intro", function ()

		local placeHolder = rn:getChildByName("find_text")
		local placeHolderColor = placeHolder:getTextColor()
		local fontColor = placeHolder:getTextColor()
		local fontName = placeHolder:getFontName()
		local fontSize = placeHolder:getFontSize()

		local back = rn:getChildByName(string.format("text_back"))
	   
		local edit = ccui.EditBox:create(back:getContentSize(),"aa")
		rn:addChild(edit)
		edit:setPosition(cc.p(back:getPosition()))
		--edit:setPlaceHolder(placeHolder:getPlaceHolder())
		edit:setPlaceHolder(CONF:getStringValue("inputStatLeagueName"))
		edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
		edit:setPlaceholderFont(fontName,fontSize)
		edit:setPlaceholderFontColor(fontColor)
		edit:setFont(fontName,fontSize)
		edit:setFontColor(cc.c4b(215,235,253,255))
		edit:setReturnType(1)
		edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		edit:setName("find_text")

		-- back:removeFromParent()
		
		placeHolder:removeFromParent()

		local strData = Tools.encode("GroupSearchReq", {
			page = self.page_
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_SEARCH_REQ"),strData)

		gl:retainLoading()
   	end)   

	------
	rn:getChildByName("find"):addClickEventListener(function ( sender )

		playEffectSound("sound/system/click.mp3")
		if rn:getChildByName("find_text"):getText() == "" then
			tips:tips(CONF:getStringValue("ContentIsEmpty"))
		else
			rn:getChildByName("establish"):setVisible(false)
			rn:getChildByName("back"):setVisible(true)

			self.search_ = "group_name"
			local strData = Tools.encode("GroupSearchReq", {
				group_name = rn:getChildByName("find_text"):getText()
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_SEARCH_REQ"),strData)

			gl:retainLoading()

			rn:getChildByName("find_text"):setText("")

		end
	end)

	rn:getChildByName("back"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		rn:getChildByName("establish"):setVisible(true)
		rn:getChildByName("back"):setVisible(false)

		rn:getChildByName("find_text"):setText("")

		self.page_ = 1
		self.search_ = "page"
		local strData = Tools.encode("GroupSearchReq", {
			page = self.page_
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_SEARCH_REQ"),strData)

		gl:retainLoading()
	end)

	---
	rn:getChildByName("back"):setVisible(false)

	rn:getChildByName("establish"):addClickEventListener(function ( sender)
		playEffectSound("sound/system/click.mp3")
		self:createMessage(2)
	end)

	local function update( dt )
		if not self.isJoin_ and player:isGroup() then
			self:getParent():getGroup()
		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	local function recvMsg()
		print("NoStarLeagueLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_CREATE_GROUP_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("CreateGroupResp",strData)

			if proto.result < 0 then
				print("error :",proto.result)
			else
				if proto.result == 0 then
					tips:tips(CONF:getStringValue("createSucess"))
					self:getParent():getGroup()
				elseif proto.result == 1 then
					tips:tips(CONF:getStringValue("LeagueNameExist"))
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_SEARCH_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupSearchResp",strData)
			printInfo("GroupSearchResp")
			print(proto.result)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				if self.search_ == "page" or self.search_ == "group_name"  then

					self.select_index = 0

					if self.search_ == "group_name" and #proto.group_list == 0 then
						tips:tips(CONF:getStringValue("no_search_group"))
						return
					end

					self.user_name_list = {}
					self.user_power_list = {}

					for i,v in ipairs(proto.group_list) do
						local name = {}
						for ii,vv in ipairs(v.user_list) do
							table.insert(name, vv.user_name)
						end

						table.insert(self.user_name_list, name)
					end

					self.group_list_ = proto.group_list

					if table.getn(self.user_name_list) ~= 0 then

						for i,v in ipairs(self.user_name_list) do

							local strData = Tools.encode("CmdGetOtherUserInfoListReq", {
								user_name_list = v,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_REQ"),strData)

							-- gl:retainLoading()
							
						end

					else

						self:resetList()
					end

				elseif self.search_ == "groupid" then

					self.one_group_list = proto.group_list[1]

					local name_list = {}

					for ii,vv in ipairs(proto.group_list[1].user_list) do
						table.insert(name_list, vv.user_name)
					end
					
					local strData = Tools.encode("CmdGetOtherUserInfoListReq", {
						user_name_list = name_list,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_REQ"),strData)

					-- gl:retainLoading()

					-- self:resetItemInfo(proto.group_list[1])
				elseif self.search_ == "add" then
					self.add_name_list = {}
					self.add_power_list = {}
					self.add_list = {}

					-- self.user_name_list = {}
					-- self.user_power_list = {}

					if #proto.group_list < 6 then
						self.page_ = self.page_ -1 
					end

					for i,v in ipairs(proto.group_list) do

						local has = false
						for i2,v2 in ipairs(self.group_list_) do
							if v2.nickname == v.nickname then
								has = true
								break
							end
						end

						if not has then
							table.insert(self.group_list_, v)
							table.insert(self.add_list, v)
						end
						
					end


					for i,v in ipairs(self.add_list) do
						local name = {}
						for ii,vv in ipairs(v.user_list) do
							table.insert(name, vv.user_name)
						end

						table.insert(self.add_name_list, name)
					end

					if #self.add_name_list ~= 0 then

						for i,v in ipairs(self.add_name_list) do

							local strData = Tools.encode("CmdGetOtherUserInfoListReq", {
								user_name_list = v,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_REQ"),strData)

							-- gl:retainLoading()
							
						end
					else
						self.loading = false
						rn:getChildByName("list"):setTouchEnabled(true)
						tips:tips(CONF:getStringValue("NoNewGroup"))
					end
					

				end
				
				-- self:resetList()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_RESP") then
			-- gl:releaseLoading()

			local proto = Tools.decode("CmdGetOtherUserInfoListResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				if self.user_power_list == nil then
					return
				end

				local power = 0
				for i,v in ipairs(proto.info_list) do
					power = power +	v.power
				end

				table.insert(self.user_power_list, power)

				if self.search_ == "page" or self.search_ == "group_name" then 
					if table.getn(self.group_list_) == table.getn(self.user_name_list) then
						self:resetList()

						self.loading = false

					end
				elseif self.search_ == "groupid" then
					print("jin zheli")
					self:resetItemInfo(self.one_group_list, power)
					
				elseif self.search_ == "add" then
					if #self.group_list_ == #self.user_power_list then
						self:resetList()

						self.loading = false
						rn:getChildByName("list"):setTouchEnabled(true)
					end

				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOIN_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupJoinResp",strData)
			
			if proto.result == "OK" then
				if not proto.user_sync.group_main.join_condition.needAllow then
					player:setGroupData( proto.user_sync.group_main)
					self:getParent():getGroup()
				else
					self.group_list_[self.join_index] = proto.user_sync.group_main

					self:resetList()
				end

				-- self.svd_:getScrollView():getChildByName("item_"..self.join_index):getChildByName("apply"):setVisible(false)
				-- self.svd_:getScrollView():getChildByName("item_"..self.join_index):getChildByName("undo_apply"):setVisible(true)
			elseif proto.result == "NO_CONDITION" then
				tips:tips(CONF:getStringValue("no_condition"))
			elseif proto.result == "USER_COUNT_MAX" then
				tips:tips(CONF:getStringValue("group_count_max"))
			elseif proto.result == "NO_NUMS" then
				tips:tips(CONF:getStringValue("group_join_max"))
			elseif proto.result == "NO_TIME" then
				tips:tips(CONF:getStringValue("group_join_cd"))
			else
				print("GroupJoinResp error :",proto.result)
			end

			self.isJoin_ = false
		end

	end
	
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function NoStarLeagueLayer:addElement(  )

	for i,v in ipairs(self.add_list) do
		local chairman_ = ""
		for ii,vv in ipairs(v.user_list) do
			if vv.job == 1 then
				chairman_ = vv.nickname
				break
			end
		end

		local flag = false
		for ii,vv in ipairs(v.join_list) do
			if vv.user_name == player:getName() then
				flag = true
				break
			end
		end

		local info = {name = v.nickname, chairman = chairman_, icon_id = v.icon_id, level = v.level, power = self.add_power_list[i], people = table.getn(v.user_list), groupid = v.groupid, isApply = flag, join_condition = v.join_condition, blurb = v.blurb, rank = v.rank}

		local item = self:createItem(info, i+table.getn(self.group_list_))
		item:setTag(i+table.getn(self.group_list_))
		item:setName("item_"..i+table.getn(self.group_list_))

		local func = function ( ... )
			if self.select_index ~= 0 then 

				self:selectItem(self.svd_:getScrollView():getChildByName("item_"..self.select_index), false)

				if item:getTag() == self.select_index then
					self.select_index = 0
					return
				else 
					-- self:selectItem(item, true)

					self.select_index = item:getTag()
				end
			else
				-- self:selectItem(item, true)

				self.select_index = item:getTag()
			end

			self.search_ = "groupid"

			local strData = Tools.encode("GroupSearchReq", {
				groupid = v.groupid
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_SEARCH_REQ"),strData)

			gl:retainLoading()
		end

		local callback = {node = item:getChildByName("bg"), func = func}

		table.insert(self.group_list_, v)
		self.svd_:addElement(item, {callback = callback})
	end

	self.svd_:getScrollView():getInnerContainer():setPositionY(-75*#self.add_list)
end

function NoStarLeagueLayer:resetItemInfo( group_info, power )
	local chairman_ = ""
	for ii,vv in ipairs(group_info.user_list) do
		if vv.job == 1 then
			chairman_ = vv.nickname
			break
		end
	end

	local flag = false
	for ii,vv in ipairs(group_info.join_list) do
		if vv.user_name == player:getName() then
			flag = true
			break
		end
	end

	local info = {name = group_info.nickname, chairman = chairman_, icon_id = group_info.icon_id, level = group_info.level, power = self.user_power_list[i], people = table.getn(group_info.user_list), groupid = group_info.groupid, isApply = flag, join_condition = group_info.join_condition, blurb = group_info.blurb, rank = group_info.rank}

	local node = self.svd_:getScrollView():getChildByName("item_"..self.select_index)
	if node then
		node:getChildByName("icon"):setTexture("StarLeagueScene/ui/icon_star_0"..info.icon_id..".png")

		node:getChildByName("name"):setString(info.name)
		node:getChildByName("chairman"):setString(info.chairman)
		node:getChildByName("level"):setString(info.level)
		node:getChildByName("power"):setString(power)
		node:getChildByName("people_now"):setString(info.people)
		node:getChildByName("people_max"):setString("/"..CONF.GROUP.get(info.level).MAX_USER)
		local intro = node:getChildByName("intro")
		local levelLimit = CONF:getStringValue("levelLimit") .. ":" .. info.join_condition.level
		local powerLimit = CONF:getStringValue("powerLimit")..":" .. info.join_condition.power
		node:getChildByName("intro_text"):setString(info.blurb.. "  " .. levelLimit .. " " .. powerLimit)
		node:getChildByName("intro_text"):setPositionX(intro:getPositionX() + intro:getContentSize().width + 2)
		if not info.join_condition.needAllow then
			node:getChildByName("apply"):getChildByName("text"):setString(CONF:getStringValue("join"))
		else
			node:getChildByName("apply"):getChildByName("text"):setString(CONF:getStringValue("apply"))
		end

		if info.people == CONF.GROUP.get(info.level).MAX_USER then
			node:getChildByName("apply"):setEnabled(false)
			node:getChildByName("apply"):getChildByName("text"):setString(CONF:getStringValue("can't join"))
		end

		if info.isApply then
			node:getChildByName("undo_apply"):setVisible(true)
			node:getChildByName("apply"):setVisible(false)
		else
			node:getChildByName("undo_apply"):setVisible(false)
			node:getChildByName("apply"):setVisible(true)
		end

		self:selectItem(node, true)
	end
end

function NoStarLeagueLayer:resetList()

	local rn = self:getResourceNode()

	self.svd_:clear()

	local function sort( a,b )
		return a.rank < b.rank
	end

	table.sort(self.group_list_, sort)

	if table.getn(self.group_list_) > 0 then
		rn:getChildByName("text"):setVisible(false)
	else
		rn:getChildByName("text"):setVisible(true)
		return
	end

	if table.getn(self.group_list_) <= 6 then
		rn:getChildByName("list"):setBounceEnabled(false)
	else
		rn:getChildByName("list"):setBounceEnabled(true)
	end
	
	for i,v in ipairs(self.group_list_) do
		local chairman_ = ""
		for ii,vv in ipairs(v.user_list) do
			if vv.job == 1 then
				chairman_ = vv.nickname
				break
			end
		end

		local flag = false
		for ii,vv in ipairs(v.join_list) do
			if vv.user_name == player:getName() then
				flag = true
				break
			end
		end

		local info = {name = v.nickname, chairman = chairman_, icon_id = v.icon_id, level = v.level, power = self.user_power_list[i], people = table.getn(v.user_list), groupid = v.groupid, isApply = flag, join_condition = v.join_condition, blurb = v.blurb, rank = v.rank}

		local item = self:createItem(info, i)
		item:setTag(i)
		item:setName("item_"..i)

		local func = function ( ... )
			if self.loading then
				return
			end

			if self.select_index ~= 0 then 

				self:selectItem(self.svd_:getScrollView():getChildByName("item_"..self.select_index), false)

				if item:getTag() == self.select_index then
					self.select_index = 0
					return
				else 
					-- self:selectItem(item, true)

					self.select_index = item:getTag()
				end
			else
				-- self:selectItem(item, true)

				self.select_index = item:getTag()
			end

			self.search_ = "groupid"

			local strData = Tools.encode("GroupSearchReq", {
				groupid = v.groupid
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_SEARCH_REQ"),strData)

			gl:retainLoading()
		end

		local callback = {node = item:getChildByName("bg"), func = func}

		self.svd_:addElement(item, {callback = callback})
	end

	if self.search_ == "add" then
		self.svd_:getScrollView():getInnerContainer():setPositionY(-75*#self.add_list)
	end

end

function NoStarLeagueLayer:selectItem( item, flag )
	if flag then
		item:getChildByName("select_light"):setVisible(true)
		-- item:getChildByName("bg"):loadTexture("NoStarLeagueLayer/ui/select_light.png")
		item:getChildByName("bg"):setOpacity(255)

		item:getChildByName("name"):setVisible(true)
		item:getChildByName("chairman"):setVisible(false)
		item:getChildByName("level"):setVisible(false)
		item:getChildByName("lv"):setVisible(false)
		item:getChildByName("power"):setVisible(false)
		item:getChildByName("people_now"):setVisible(false)	
		item:getChildByName("people_max"):setVisible(false)

		item:getChildByName("intro"):setVisible(true)
		item:getChildByName("intro"):setString(CONF:getStringValue("leagueDemand"))
		item:getChildByName("intro_text"):setVisible(true)

		item:getChildByName("intro_text"):setPositionX(item:getChildByName("intro"):getPositionX() + item:getChildByName("intro"):getContentSize().width + 2)

	else
		item:getChildByName("select_light"):setVisible(false)
		-- item:getChildByName("bg"):loadTexture("ChatLayer/ui/name_bottom.png")

		if item:getTag()%2 == 0 then
			item:getChildByName("bg"):setOpacity(255*0.7)
		end

		item:getChildByName("name"):setVisible(true)
		item:getChildByName("chairman"):setVisible(true)
		item:getChildByName("level"):setVisible(true)
		item:getChildByName("lv"):setVisible(true)
		item:getChildByName("power"):setVisible(true)
		item:getChildByName("people_now"):setVisible(true)	
		item:getChildByName("people_max"):setVisible(true)

		item:getChildByName("intro"):setVisible(false)
		item:getChildByName("intro_text"):setVisible(false)

	end
end

function NoStarLeagueLayer:createMessage( type ) -- 1 申请失败 2 创建公会
	local node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/MessageNode.csb")

	node:getChildByName("back"):setSwallowTouches(true)

	node:getChildByName("close"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/return.mp3")
		node:removeFromParent()
	end)

	if type == 2 then
		local el = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/establish_league.csb")
		el:getChildByName("Text_1"):setString(CONF:getStringValue("establishLeague"))
		el:getChildByName("Text_1_0"):setString(CONF:getStringValue("leagueName"))
		el:getChildByName("Text_1_0_0"):setString(CONF:getStringValue("leagueIcon"))
		el:getChildByName("ok"):getChildByName("text"):setString(CONF:getStringValue("establish"))

		local placeHolder = el:getChildByName("find_text")
		local placeHolderColor = placeHolder:getTextColor()
		local fontColor = placeHolder:getTextColor()
		local fontName = placeHolder:getFontName()
		local fontSize = placeHolder:getFontSize()
		local maxLength = CONF.PARAM.get("alliance_digit").PARAM

		local back = el:getChildByName(string.format("text_back"))
	   
		local edit = ccui.EditBox:create(back:getContentSize(),"Common/ui/chat_bottom.png")
		edit:setAnchorPoint(cc.p(0,0.5)) 
		el:addChild(edit)
		edit:setPosition(cc.p(back:getPosition()))
		edit:setPlaceHolder(CONF:getStringValue("inputStatLeagueName"))
		edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
		edit:setPlaceholderFont(fontName,fontSize)
		edit:setPlaceholderFontColor(fontColor)
		edit:setFont(fontName,fontSize)
		edit:setFontColor(fontColor)
		edit:setReturnType(1)
		edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		edit:setMaxLength(maxLength)
		edit:setName("find_text")

		back:removeFromParent()
		
		placeHolder:removeFromParent()

		for i=1,8 do
			el:getChildByName("node_"..i):setTag(i)
			el:getChildByName("node_"..i):setLocalZOrder(10)
		end

		for i=1,8 do
			el:getChildByName("node_"..i):getChildByName("bg"):addClickEventListener(function ( sender )
				playEffectSound("sound/system/click.mp3")
				if el:getChildByName("node_"..i):getChildByName("bg"):getTag() == 0 then
					return
				end

				for j=1,8 do
					if el:getChildByName("node_"..j):getChildByName("bg"):getTag() == 0 then
						el:getChildByName("node_"..j):getChildByName("light"):setVisible(false)
						el:getChildByName("node_"..j):getChildByName("light2"):setVisible(false)
						el:getChildByName("node_"..j):getChildByName("light3"):setVisible(false)

						el:getChildByName("node_"..j):getChildByName("bg"):setTag(j)

						el:getChildByName("node_"..j):setLocalZOrder(10)
					end
				end

				el:getChildByName("node_"..i):getChildByName("light"):setVisible(true)
				el:getChildByName("node_"..i):getChildByName("light2"):setVisible(true)
				el:getChildByName("node_"..i):getChildByName("light3"):setVisible(true)

				el:getChildByName("node_"..i):getChildByName("bg"):setTag(0)

				el:getChildByName("node_"..i):setLocalZOrder(11)

			end)
		end

		el:getChildByName("ok"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/click.mp3")
			if edit:getText() == "" then
				tips:tips(CONF:getStringValue("NameCan'tNull"))
			else
				for i=1,CONF.DIRTYWORD.len do
				  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
				  if string.find(edit:getText(), CONF.DIRTYWORD[i].KEY) then
				  	tips:tips(CONF:getStringValue("dirty_message"))
				  	return
				  end
				end

				local str = shuaiSubString(edit:getText())
				for i=1,CONF.DIRTYWORD.len do
				  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
				  if string.find(str, CONF.DIRTYWORD[i].KEY) then
				  	tips:tips(CONF:getStringValue("dirty_message"))
				  	return
				  end
				end
				
				local index 
				for i=1,8 do
					if el:getChildByName("node_"..i):getChildByName("bg"):getTag() == 0 then 
						index = i
						break
					end
				end

				local strData = Tools.encode("CreateGroupReq", {
					nickname = edit:getText(),
					icon_id = index,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CREATE_GROUP_REQ"),strData)

				gl:retainLoading()
			end	
		end)

		node:addChild(el)
	end

	local center = cc.exports.VisibleRect:center()
	node:setPosition(cc.p(center.x - node:getChildByName("back"):getContentSize().width/2, center.y - node:getChildByName("back"):getContentSize().height/2))
	node:setName("message")
	self:getResourceNode():addChild(node)

	--ADD WJJ 20180808
	require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Xingmeng_Chuangjian(node)
end

function NoStarLeagueLayer:onExitTransitionStart()
	printInfo("NoStarLeagueLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end
end


return NoStarLeagueLayer