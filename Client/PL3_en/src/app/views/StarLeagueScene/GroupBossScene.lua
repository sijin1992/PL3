
local FileUtils = cc.FileUtils:getInstance()

local animManager = require("app.AnimManager"):getInstance()
local tips = require("util.TipsMessage"):getInstance()
local player = require("app.Player"):getInstance()
local gl = require("util.GlobalLoading"):getInstance()
local messageBox = require("util.MessageBox"):getInstance()
local Bit = require "Bit"

local VisibleRect = cc.exports.VisibleRect

local GroupBossScene = class("GroupBossScene", cc.load("mvc").ViewBase)

GroupBossScene.RESOURCE_FILENAME = "GroupBossScene/GroupBossScene.csb"
GroupBossScene.NEED_ADJUST_POSITION = true
GroupBossScene.RESOURCE_BINDING = {

	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

local weaponSize = cc.size(57.8,57.8)
local noSize = cc.size(27,27)

local aSize = cc.size(58,58)
local bSize = cc.size(70.00,70.00)

function GroupBossScene:OnBtnClick(event)

	print(event.name)
	if event.name == "ended" and event.target:getName() == "close" then
		self:getApp():pushToRootView("StarLeagueScene/StarLeagueScene")
	end


end

function GroupBossScene:onCreate(data)
	if data then
		self.data_ = data
	end
end


function GroupBossScene:onEnter()
	
	printInfo("GroupBossScene:onEnter()")
end

function GroupBossScene:onExit()
	
	printInfo("GroupBossScene:onExit()")

end

function GroupBossScene:createInfoNode( index )
	
	if self.index_ == index then
		return
	end

	local function toWeek( num )
		if num == 1 then
			return "Sunday"
		elseif num == 2 then
			return "Monday"
		elseif num == 3 then
			return "Tuesday"
		elseif num == 4 then
			return "Wednesday"
		elseif num == 5 then
			return "Thursday"
		elseif num == 6 then
			return "Friday"
		elseif num == 7 then
			return "Saturday"
		end

		return nil
	end

	self.index_ = index 
	for i,v in ipairs(self.svd_:getScrollView():getChildren()) do
		v:getChildByName("text"):setPositionX(v:getChildByName("Image_12_0_0"):getPositionX())
		if v:getTag() == index then
			v:getChildByName("background"):setOpacity(255)
			v:getChildByName("text"):setTextColor(cc.c4b(205, 235, 247,255))
			v:getChildByName("text"):setPositionX(v:getChildByName("Image_12_0_0"):getPositionX()+18)
		else
			v:getChildByName("text"):setTextColor(cc.c4b(209, 209, 209,255))
			v:getChildByName("text"):setPositionX(v:getChildByName("Image_12_0_0"):getPositionX())
			v:getChildByName("background"):setOpacity(255*0)
		end
	end

	local rn = self:getResourceNode()

	if rn:getChildByName("node"):getChildByName("info_node") then
		rn:getChildByName("node"):getChildByName("info_node"):removeFromParent()
	end

	local conf = CONF.GROUP_BOSS.get(index)
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("GroupBossScene/BossInfoNode.csb")

	info_node:getChildByName("boss_name"):setString(CONF:getStringValue(conf.NAME))
	info_node:getChildByName("boss_ins"):setString(CONF:getStringValue(conf.MEMO))
	info_node:getChildByName("ship"):setTexture("ShipImage/"..conf.IMAGE..".png")
	info_node:getChildByName("role"):setTexture("RoleImage/"..conf.IMAGE..".png")

	local can_fight = info_node:getChildByName("can_fight")
	can_fight:getChildByName("boss_fight"):setString(CONF:getStringValue("group_boss_fight_num")..":")
	can_fight:getChildByName("boss_power"):setString(CONF:getStringValue("group_boss_fight")..":")
	can_fight:getChildByName("boss_time"):setString(CONF:getStringValue("open_time")..":")
	can_fight:getChildByName("btn_reward"):getChildByName("text"):setString(CONF:getStringValue("reward"))
	can_fight:getChildByName("challenge"):getChildByName("text"):setString(CONF:getStringValue("challenge"))

	local begin_time = conf.START_TIME*3600
	local end_time = begin_time + conf.END_TIME

	local time_str = string.format("%s-%s", formatTime(begin_time), formatTime(end_time))
	can_fight:getChildByName("boss_time_num"):setString(time_str)

	can_fight:getChildByName("boss_time_num"):setPositionX(can_fight:getChildByName("boss_time"):getPositionX() + can_fight:getChildByName("boss_time"):getContentSize().width + 5)

	can_fight:getChildByName("form"):getChildByName("text"):setString(CONF:getStringValue("form"))
	can_fight:getChildByName("form"):addClickEventListener(function ( ... )
		self:getApp():addView2Top("NewFormLayer",{from = "ships"})
	end)

	local not_fight = info_node:getChildByName("can't_fight")
	not_fight:getChildByName("open"):setString(CONF:getStringValue("open_time")..":")
	not_fight:getChildByName("open_time"):setString(CONF:getStringValue(toWeek(conf.OPEN)).."  "..time_str)
	not_fight:getChildByName("group_level"):setString(CONF:getStringValue("group_level_not_enough").."Lv."..conf.LEVEL)

	local dayStr = conf.OPEN--toWeek(conf.OPEN)
	local day = player:getServerDate().wday

	if day == dayStr and self.data_.group_list.level >= conf.LEVEL then
		can_fight:setVisible(true)
		not_fight:setVisible(false)

		local strData = Tools.encode("GroupPVEGetInfoReq", {
			group_boss_id = conf.ID,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_GET_INFO_REQ"),strData)

		gl:retainLoading()
	else
		can_fight:setVisible(false)
		not_fight:setVisible(true)

		info_node:getChildByName("boss_ins"):setPositionY(info_node:getChildByName("boss_ins"):getPositionY() + 40)

		if self.data_.group_list.level >= conf.LEVEL then
			not_fight:getChildByName("flag_w_0"):setVisible(false)
			not_fight:getChildByName("group_level"):setVisible(false)
		end
	end

	info_node:setName("info_node")
	rn:getChildByName("node"):addChild(info_node)
end

function GroupBossScene:resetInfo(info)

	local rn = self:getResourceNode()

	local info_node = rn:getChildByName("node"):getChildByName("info_node")

	-- message GroupPVECheckpoint{
	--     required int32 group_boss_id = 1;
	--     repeated int32 hurter_hp_list = 2;
	--     required int32 damage = 3;
	--     required int32 challenge_times = 4;
	--     required int32 buy_challenge_times = 5;
	--     repeated bool get_reward_list = 6;
	-- }

	local conf = CONF.GROUP_CHECKPOINT.get(CONF.GROUP_BOSS.get(info.group_boss_id).GROUP_CHECKPOINT_ID)
	local monsters = {}
	for i,v in ipairs(conf.MONSTER_LIST) do
		if v ~= 0 then
			local has = false
			for i2,v2 in ipairs(monsters) do
				if v2 == v then
					has = true
					break
				end
			end

			if not has then
				table.insert(monsters, v)
			end
		end
	end

	for i,v in ipairs(monsters) do
		if v < 0 then
			self.boss_id = v 
			break
		end
	end

	self.group_boss_id = info.group_boss_id

	local hp_now = 0
	for i,v in ipairs(info.hurter_hp_list) do
		hp_now = hp_now + v
	end

	local hp_max = 0
	for i,v in ipairs(monsters) do
		hp_max = hp_max + CONF.AIRSHIP.get(math.abs(v)).LIFE
	end

	print("hp", hp_now,hp_max)

	if hp_now == 0 then
		info_node:getChildByName("can_fight"):getChildByName("challenge"):setEnabled(false)
		info_node:getChildByName("can_fight"):getChildByName("challenge"):getChildByName("text"):setTextColor(cc.c4b(209,209,209,255))
		-- info_node:getChildByName("can_fight"):getChildByName("challenge"):getChildByName("text"):enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
	end

	info_node:getChildByName("can_fight"):getChildByName("boss_hp"):setString(math.floor(hp_now/hp_max*100).."%")

	local progress = require("util.ScaleProgressDelegate"):create(info_node:getChildByName("can_fight"):getChildByName("progress"),245)
	local p = hp_now/hp_max
	if p < 0 then p=0 end
	if p > 100 then p = 100 end
	progress:setPercentage(p*100)

	info_node:getChildByName("can_fight"):getChildByName("boss_fight_num"):setPositionX(info_node:getChildByName("can_fight"):getChildByName("boss_fight"):getPositionX() + info_node:getChildByName("can_fight"):getChildByName("boss_fight"):getContentSize().width + 5)
	info_node:getChildByName("can_fight"):getChildByName("boss_power_num"):setPositionX(info_node:getChildByName("can_fight"):getChildByName("boss_power"):getPositionX() + info_node:getChildByName("can_fight"):getChildByName("boss_power"):getContentSize().width + 5)
	info_node:getChildByName("can't_fight"):getChildByName("open_time"):setPositionX(info_node:getChildByName("can't_fight"):getChildByName("open"):getPositionX() + info_node:getChildByName("can't_fight"):getChildByName("open"):getContentSize().width + 5)

	info_node:getChildByName("can_fight"):getChildByName("boss_fight_num"):setString(info.challenge_times)
	info_node:getChildByName("can_fight"):getChildByName("boss_power_num"):setString(info.damage)

	info_node:getChildByName("can_fight"):getChildByName("btn_reward"):addClickEventListener(function ( ... )
		self:createRewardNode(info)
	end)

	info_node:getChildByName("can_fight"):getChildByName("challenge"):addClickEventListener(function ( ... )
		if info.challenge_times == 0 then
			tips:tips(CONF:getStringValue("noTimeToChallenge"))
			return
		end

		if player:isFighting(1) ~= 0 then
			return
		end

		for i,v in ipairs(player:getForms()) do
			if v ~= 0 then
				local calship = player:calShip(v)
				if calship and Bit:has(calship.status, 4) then
					tips:tips(CONF:getStringValue("chuzhen_tips"))
					return
				end
			end
		end	

		local strData = Tools.encode("GroupPVEReq", {
			group_boss_id = info.group_boss_id,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_REQ"),strData)

		gl:retainLoading()
	end)

	info_node:getChildByName("can_fight"):getChildByName("add_fight"):addClickEventListener(function ( ... )

		local gb_conf = CONF.GROUP_BOSS.get(info.group_boss_id)

		local now_time = player:getServerTime()%86400
		local start_time = gb_conf.START_TIME*3600
		local end_time = start_time + gb_conf.END_TIME

		if now_time < start_time or now_time > end_time then
			tips:tips(CONF:getStringValue("group_boss_timeout"))
			return
		end

		if info.buy_challenge_times == CONF.GROUP_BOSS.get(info.group_boss_id).TIME_2 then
			tips:tips(CONF:getStringValue("buy_group_boss_times_full"))
			return
		end

		local function func( ... )
			if player:getMoney() < CONF.GROUP_BOSS.get(info.group_boss_id).PRICE[info.buy_challenge_times+1] then
				-- tips:tips("no enought credit")
				local function func()
					local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

					rechargeNode:init(self, {index = 1})
					self:addChild(rechargeNode)
				end

				local messageBox = require("util.MessageBox"):getInstance()
				messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
				return
			end

			local strData = Tools.encode("GroupPVEAddTimsReq", {
				group_boss_id = info.group_boss_id,
				times = 1,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_ADD_TIMES_REQ"),strData)

			gl:retainLoading()
		end

		local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("buy_group_boss_times"), CONF.GROUP_BOSS.get(info.group_boss_id).PRICE[info.buy_challenge_times+1], func)

		tipsAction(node)
		self:addChild(node)

	end)

	local can_get_reward = {}
	for i,v in ipairs(CONF.GROUP_BOSS.get(info.group_boss_id).DAMAGE) do
		if info.damage >= v then
			table.insert(can_get_reward, true)
		else
			table.insert(can_get_reward, false)
		end
	end

	local show_green = false
	for i=1,#info.get_reward_list do
		if info.get_reward_list[i] == false and can_get_reward[i] == true then
			show_green = true
			break
		end
	end

	if show_green then
		info_node:getChildByName("can_fight"):getChildByName("btn_reward"):getChildByName("green"):setVisible(true)
	else
		info_node:getChildByName("can_fight"):getChildByName("btn_reward"):getChildByName("green"):setVisible(false)
	end

end

function GroupBossScene:createRewardNode( info )

	local conf = CONF.GROUP_BOSS.get(info.group_boss_id)
	
	local reward_node = require("app.ExResInterface"):getInstance():FastLoad("GroupBossScene/BossRewardNode.csb")
	reward_node:getChildByName("damage"):setString(CONF:getStringValue("group_boss_fight"))
	reward_node:getChildByName("damage_num"):setString(info.damage)

	reward_node:getChildByName("damage_num"):setPositionX(reward_node:getChildByName("damage"):getPositionX() + reward_node:getChildByName("damage"):getContentSize().width + 5)

	self.reward_svd = require("util.ScrollViewDelegate"):create(reward_node:getChildByName("list"),cc.size(0,0), cc.size(749,82))
	reward_node:getChildByName("list"):setScrollBarEnabled(false)

	self:createRewardItem(info)

	reward_node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	reward_node:getChildByName("yes"):addClickEventListener(function ( ... )

		reward_node:removeFromParent()
	end)

	reward_node:getChildByName("swallow"):setSwallowTouches(true)
	reward_node:getChildByName("swallow"):addClickEventListener(function ( ... )

		reward_node:removeFromParent()
	end)

	reward_node:setName("reward_node")
	tipsAction(reward_node)
	self:addChild(reward_node)

end

function GroupBossScene:createRewardItem( info )

	local conf = CONF.GROUP_BOSS.get(info.group_boss_id)

	local items = {}

	self.reward_svd:clear()

	for i,v in ipairs(conf.DAMAGE) do
		local item = require("app.ExResInterface"):getInstance():FastLoad("GroupBossScene/reward_item.csb")

		item:setTag(i)

		if i%2 == 0 then
			item:getChildByName("background"):setOpacity(255*0.20)
		else
			item:getChildByName("background"):setOpacity(255*0.39)
		end

		item:getChildByName("damage"):setString(CONF:getStringValue("damage")..":")
		item:getChildByName("damage_num"):setString(v)

		item:getChildByName("damage_num"):setPositionX(item:getChildByName("damage"):getPositionX() + item:getChildByName("damage"):getContentSize().width + 5)

		item:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("Get"))

		local x,y = item:getChildByName("item_pos"):getPosition()
		for i2,v2 in ipairs(conf["DAMAGE_REWARD_"..i]) do

			local ii = require("util.ItemNode"):create():init(v2, conf["DAMAGE_REWARD_NUM_"..i][i2])

			ii:setPosition(cc.p(x+(i2-1)*90, y))
			item:addChild(ii)
		end

		if info.damage < v then
			item:getChildByName("button"):setEnabled(false)
			item:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209,209,209,255))
			-- item:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
		else
			if info.get_reward_list[i] then
				item:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
				item:getChildByName("button"):setEnabled(false)
				item:getChildByName("button"):getChildByName("text"):setTextColor(cc.c4b(209,209,209,255))
				-- item:getChildByName("button"):getChildByName("text"):enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
			else
				item:getChildByName("button"):addClickEventListener(function ( ... )

					self.btn_ = item:getChildByName("button")

					local strData = Tools.encode("GroupPVERewardReq", {
						group_boss_id = info.group_boss_id,
						reward_index = i,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_GET_REWARD_REQ"),strData)

					gl:retainLoading()
				end)
			end
		end

		local can = 1
		if info.damage >= v then
			can = 2
		end

		local get = 1
		if info.get_reward_list[i] then
			get = 2
		end

		local tt = {item = item, index = i, get = get, can = can}
		table.insert(items, tt)
	end

	local function sort( a,b )
		if a.get ~= b.get then
			return a.get < b.get
		else
			if a.can ~= b.can then
				return a.can > b.can
			else
				return a.index < b.index
			end
		end
	end

	table.sort(items, sort)

	for i,v in ipairs(items) do
		self.reward_svd:addElement(v.item)
	end
end

function GroupBossScene:onEnterTransitionFinish()
	printInfo("GroupBossScene:onEnterTransitionFinish()")

	local rn = self:getResourceNode()
	rn:getChildByName("name"):setString(CONF:getStringValue("leagueBoss"))
	
	-- self.progress:setPercentage(100)

	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(4,2), cc.size(299.00,69))
	rn:getChildByName("list"):setScrollBarEnabled(false)

	self.index_ = 0

	local conf = CONF.GROUP_BOSS.get(self.data_.group_list.level)

	local days = player:getGroupBossDays()
	for i,v in ipairs(days) do
		local cf = CONF.GROUP_BOSS.get(v.index)

		local node = require("app.ExResInterface"):getInstance():FastLoad("GroupBossScene/LabsNode.csb")
		node:getChildByName("text"):setString(CONF:getStringValue(cf.NAME))
		node:setTag(v.index)	

		local function func()
			self:createInfoNode(node:getTag())
		end

		local callback = {node = node:getChildByName("background"), func = func}

		self.svd_:addElement(node, {callback = callback})
	end

	self:createInfoNode(days[1].index)

	local function recvMsg()
		print("ShipsScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_GET_INFO_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("GroupPVEGetInfoResp",strData)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else 
				self:resetInfo(proto.info)

				if self:getChildByName("reward_node") then
					self:createRewardItem(proto.info)
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_GET_REWARD_RESP") then
			
			gl:releaseLoading()
			
			local proto = Tools.decode("GroupPVERewardResp",strData)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else 
				-- self.btn_:getChildByName("text"):setString(CONF:getStringValue("has_get"))
				-- self.btn_:getChildByName("text"):setTextColor(cc.c4b(209,209,209,255))
				-- self.btn_:getChildByName("text"):enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
				-- self.btn_:setEnabled(false)

				-- for i,v in ipairs(self.items) do
				--     if proto.req.reward_index == v.index then
				--         v.get = 2

				--         local btn = v.item:getChildByName("button")
				--         btn:getChildByName("text"):setString(CONF:getStringValue("has_get"))
				--         btn:getChildByName("text"):setTextColor(cc.c4b(209,209,209,255))
				--         btn:getChildByName("text"):enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
				--         btn:setEnabled(false)

				--         break
				--     end
				-- end

				-- local function sort( a,b )
				--     if a.get ~= b.get then
				--         return a.get < b.get
				--     else
				--         if a.can ~= b.can then
				--             return a.can < b.can
				--         else
				--             return a.index < b.index
				--         end
				--     end
				-- end

				-- table.sort(self.items, sort)       
				
				-- self.reward_svd:clear()

				-- for i,v in ipairs(self.items) do
				--     self.reward_svd:addElement(v.item:clone())
				-- end         
				playEffectSound("sound/system/reward.mp3")
				local strData = Tools.encode("GroupPVEGetInfoReq", {
					group_boss_id = proto.req.group_boss_id,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_GET_INFO_REQ"),strData)

				gl:retainLoading()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("GroupPVEResp",strData)

			if proto.result == "TIME_OUT" then
				tips:tips(CONF:getStringValue("group_boss_timeout"))
			elseif proto.result ~= "OK" then
				print("error :",proto.result)
			else 
				local strength = proto.user_sync.user_info.strength
				if strength == 0 then
					player:setStrength(strength)
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
				end
				local name = CONF:getStringValue(CONF.GROUP_BOSS.get(math.abs(self.group_boss_id)).NAME)
				local enemy_name = "RoleIcon/"..CONF.AIRSHIP.get(math.abs(self.boss_id)).ICON_ID..".png"

				self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kGroupBoss,Tools.decode("GroupPVEResp",strData),true, name, enemy_name})
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_ADD_TIMES_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("GroupPVEAddTimsResp",strData)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else 
				local strData = Tools.encode("GroupPVEGetInfoReq", {
					group_boss_id = proto.req.group_boss_id,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_GET_INFO_REQ"),strData)

				gl:retainLoading()
			
			end

		end
	end
		
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

end

function GroupBossScene:onExitTransitionStart()
	printInfo("GroupBossScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end
end

return GroupBossScene