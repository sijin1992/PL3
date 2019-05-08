local player = require("app.Player"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local ItemBagScene = class("ItemBagScene", cc.load("mvc").ViewBase)

local animManager = require("app.AnimManager"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local app = require("app.MyApp"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

ItemBagScene.RESOURCE_FILENAME = "ItemBag/ItemBagScene.csb"

ItemBagScene.NEED_ADJUST_POSITION = true

local schedulerEntry = nil

ItemBagScene.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

-- required int32 status_machine = 7;	//1:采集 2:废墟 3:打捞 4:侦查 5：驻扎 6:攻击基地 7:陪同 8:攻击据点 9:人工智能基地 10:征召
local Status_Machine = {
	kSpy = 4,
	kGuarde = 5,
	kAttackBase = 6,
	kAccompany = 7,
	kAttackCity = 8,
	kEnlist = 10,
}

function ItemBagScene:onCreate(data)
	self.data_ = data
end

function ItemBagScene:sortBagItem(bagkind)
	if bagkind == 1 then
		table.sort(self.items,function(a,b)
			local confA = CONF.ITEM.get(a.id)
			local confB = CONF.ITEM.get(b.id)
			if confA.TYPE == confB.TYPE then
				if confA.CAN_USE == confB.CAN_USE then
					if confA.QUALITY == confB.QUALITY then
						-- return confA.ID > confB.ID
						if confA.ID == confB.ID then
							return a.num > b.num
						else
							return confA.ID > confB.ID
						end
					else
						return confA.QUALITY > confB.QUALITY
					end
				else
					return confA.CAN_USE > confB.CAN_USE
				end
			else
				if confA.TYPE == 12 then
					return true
				end
				if confB.TYPE == 12 then
					return false
				end
				if confA.CAN_USE == confB.CAN_USE then
					if confA.TYPE == 13 then
						return true
					end
					if confB.TYPE == 13 then
						return false
					end
					if confA.QUALITY == confB.QUALITY then
						if confA.ID == confB.ID then
							return a.num > b.num
						else
							return confA.ID > confB.ID
						end
					else
						return confA.QUALITY > confB.QUALITY
					end
				else
					return confA.CAN_USE > confB.CAN_USE
				end
			end
		end)
	elseif bagkind == 2 then
		table.sort(self.equips,function(a,b)
			local confA = CONF.ITEM.get(a.id)
			local confB = CONF.ITEM.get(b.id)
			local equipA = CONF.EQUIP.get(a.id)
			local equipB = CONF.EQUIP.get(b.id)
			if equipA.LEVEL == equipB.LEVEL then
				if confA.QUALITY == confB.QUALITY then
					if confA.ID == confB.ID then
						return a.num > b.num
					else
						return confA.ID > confB.ID
					end
				else
					return confA.QUALITY > confB.QUALITY
				end
			else
				return equipA.LEVEL > equipB.LEVEL
			end
		end)
	elseif bagkind == 3 then
		table.sort(self.jewels,function(a,b)
			local confA = CONF.ITEM.get(a.id)
			local confB = CONF.ITEM.get(b.id)
			local jewelA = CONF.GEM.get(a.id)
			local jewelB = CONF.GEM.get(b.id)
			if jewelA.LEVEL == jewelB.LEVEL then
				if confA.QUALITY == confB.QUALITY then
					if confA.ID == confB.ID then
						return a.num > b.num
					else
						return confA.ID > confB.ID
					end
				else
					return confA.QUALITY > confB.QUALITY
				end
			else
				return jewelA.LEVEL > jewelB.LEVEL
			end
		end)
	elseif bagkind == 4 then
		table.sort(self.drawings,function(a,b)
			local confA = CONF.ITEM.get(a.id)
			local confB = CONF.ITEM.get(b.id)
			if confA.QUALITY == confB.QUALITY then
				if confA.ID == confB.ID then
					return a.num > b.num
				else
					return confA.ID > confB.ID
				end
			else
				return confA.QUALITY > confB.QUALITY
			end
		end)
	end
end

function ItemBagScene:OnBtnClick(event)
	if event.name == 'ended' then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			-- self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
			self:getApp():popView()
		end
	end
end

function ItemBagScene:setBarHighLight(bar, flag)
	if flag == true then
		bar:getChildByName("selected"):setVisible(true)
		bar:getChildByName("normal"):setVisible(false)
		bar:getChildByName("text"):setTextColor(cc.c4b(220, 246, 255,255))
		-- bar:getChildByName("text"):enableShadow(cc.c4b(220, 246, 255,255),cc.size(0.5,0.5))
	else
		bar:getChildByName("selected"):setVisible(false)
		bar:getChildByName("normal"):setVisible(true)
		bar:getChildByName("text"):setTextColor(cc.c4b(124, 127, 128,255))
		-- bar:getChildByName("text"):enableShadow(cc.c4b(124, 127, 128,255),cc.size(0.5,0.5))
	end
end

function ItemBagScene:retsetAllEquips()
	self.equips = {}
	for k,v in ipairs( player:getBagEquips()) do
		if v.ship_id == 0 then
			local main = v
			main.id = v.equip_id
			main.num = 1
			table.insert(self.equips,main)
		end
	end
	self:sortBagItem(2)
end

function ItemBagScene:retsetAllItems()
	self.items = {}
	self.jewels = {} 
	self.drawings = {} 
	local function splitItem(tab,itemId,itemNum,confNum)
		-- if itemNum > confNum then
		-- 	local t = {id = itemId ,num = confNum}
		-- 	table.insert(tab,t)
		-- 	splitItem(tab,itemId,itemNum-confNum,confNum)
		-- else
			local t = {id = itemId ,num = itemNum}
			table.insert(tab,t)
		-- end
	end
	local items = {}
	for k,v in ipairs(player:getBagItems()) do
		local conf = CONF.ITEM.get(v.id)
		if conf.BAG_TYPE and v.num ~= 0 then
			local main = {}
			main.id = v.id
			main.num = v.num
			table.insert(items,main)
		end
	end
	local gem = player:getAllUnGemList()
	for k,v in pairs(gem) do
		local conf = CONF.ITEM.get(v.id)
		if conf.SUPERPOSITION then
			splitItem(self.jewels,v.id,v.num,conf.SUPERPOSITION)
		end
	end
	for k,v in pairs(items) do
		local conf = CONF.ITEM.get(v.id)
		if conf.SUPERPOSITION then
			if conf.BAG_TYPE == 1 then
				splitItem(self.items,v.id,v.num,conf.SUPERPOSITION)
			elseif conf.BAG_TYPE == 4 then
				splitItem(self.drawings,v.id,v.num,conf.SUPERPOSITION)	
			end
		end
	end
	self:sortBagItem(1)
	self:sortBagItem(3)
	self:sortBagItem(4)
end

function ItemBagScene:onEnterTransitionFinish()
	self.btnSelected = self.btnSelected or 1
	self.itemSelected = self.itemSelected or 1
	local rn = self:getResourceNode()
	rn:getChildByName('Text_non'):setString(CONF:getStringValue('no_prop'))
	rn:getChildByName('Text_non'):setVisible(false)
	rn:getChildByName('bag_name'):setString(CONF:getStringValue('knapsack'))
	self.list = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(3,3), cc.size(90,90))
	self.list:getScrollView():setScrollBarEnabled(false)
	-- self:retsetAllEquips()
	-- self:retsetAllItems()
	self:updatePointV(0)
	self:resetList(self.btnSelected)
	self:setBarClick()

		self.time = 0
	self.canSend = true
	local function update( dt )		
		self.time = self.time + 1
		if self.time > 2 then
			self.time = 0
			self.canSend = true
		end

	end

	schedulerEntry = scheduler:scheduleScriptFunc(update, 1,false)

	local function recvMsg( )
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_ADD_STRENGTH_RESP") then
			playEffectSound("sound/system/use_item.mp3")
			local proto = Tools.decode("AddStrengthResp",strData)
			print("AddStrengthResp result...", proto.result)
			if proto.result == 'OK' then
				tips:tips(CONF:getStringValue("successful operation"))
				-- flurryLogEvent("potion_add_strength", {potion_id = tostring(item.id)}, 1, item.id)
				
				local node = rn:getChildByName('nodeDetail')
				if node then
					node:removeFromParent()
				end
				self:resetList(self.btnSelected)
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_PLANET_GET_RESP") then
			if not self.planetGet then return end
			playEffectSound("sound/system/use_item.mp3")
			local proto = Tools.decode("PlanetGetResp",strData)
			print("PlanetGetResp result...", proto.result)
			if proto.result == 0 then

				if proto.type == 1 then

					local flag = true
					for i,v in ipairs(proto.planet_user.army_list) do
						if v.status_machine ~= 5 then
							tips:tips(CONF:getStringValue("ship lock"))
							flag = false
							break
						else
							if v.element_global_key ~= proto.planet_user.base_global_key then
								tips:tips(CONF:getStringValue("ship lock"))
								flag = false
								break
							end
						end
					end

					if flag and not self.canSend then
						local strData = Tools.encode("PlanetMoveBaseReq", {
								type = 2,
							 })
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_MOVE_BASE_REQ"),strData) 
					end
				end
				local node = rn:getChildByName('nodeDetail')
				if node then
					node:removeFromParent()
				end
			end
			self.planetGet = false
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_MOVE_BASE_RESP") then
        	local proto = Tools.decode("PlanetMoveBaseResp",strData)

        	print('PlanetMoveBaseResp result',proto.result)

        	if proto.result == "OK" then

        		self.send_msg = false
			cc.exports.PlanetJumpTime = os.time()

        		-- cc.UserDefault:getInstance():setIntegerForKey("PlanetJumpTime", os.time())
        		-- if self.data_.from == "city" then
        		-- 	self:getApp():pushToRootView("PlanetScene/PlanetScene")
        		-- elseif self.data_.from == "planet" then
        		-- 	self:getApp():popView()
        		-- end

        		self:getApp():pushToRootView("PlanetScene/PlanetScene",{come_in_type = 1})

			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_OPEN_GIFT_RESP") then
			local proto = Tools.decode("OpenGiftResp",strData)
			print('OpenGiftResp result..',proto.result)
			if proto.result == 0 then
				local node = rn:getChildByName('nodeDetail')
				if node then
					node:removeFromParent()
				end
				local function func( ... )
					local guide 
					if guideManager:getSelfGuideID() ~= 0 then
						guide = guideManager:getSelfGuideID()
					else
						guide = player:getGuideStep()
					end

					if guide == guideManager:getTeshuGuideId(1) then
						guideManager:createGuideLayer(guide+1)
					end
				
				end
				local node = require("util.RewardNode"):createGettedNodeWithList(proto.get_item_list, func)
				tipsAction(node)
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				self:resetList(self.btnSelected)
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_SHIELD_BASE_RESP") then
			local proto = Tools.decode("PlanetShieldResp",strData)
			print('PlanetShieldResp result..',proto.result)
			if proto.result == 0 then
				tips:tips(CONF:getStringValue("use succeed"))
				local node = rn:getChildByName('nodeDetail')
				if node then
					node:removeFromParent()
				end
				self:resetList(self.btnSelected)
			else
				tips:tips(CONF:getStringValue("use defeated"))
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function ItemBagScene:updatePointV(selected)
	local rn = self:getResourceNode()
	local newItems = player:getItemUpdateTab()
	if selected == 0 then
		rn:getChildByName("leftBg"):getChildByName("mode_1"):getChildByName('point'):setVisible(next(newItems.item) and true or false )
		rn:getChildByName("leftBg"):getChildByName("mode_2"):getChildByName('point'):setVisible(next(newItems.equip) and true or false)
		rn:getChildByName("leftBg"):getChildByName("mode_3"):getChildByName('point'):setVisible(next(newItems.gem) and true or false)
		rn:getChildByName("leftBg"):getChildByName("mode_4"):getChildByName('point'):setVisible(next(newItems.drawing) and true or false)
	else
		local show = false
		if selected == 1 then
			show = next(newItems.item)
		elseif selected == 2 then
			show = next(newItems.equip)
		elseif selected == 3 then
			show = next(newItems.gem)
		elseif selected == 4 then
			show = next(newItems.drawing)
		end
		rn:getChildByName("leftBg"):getChildByName("mode_"..selected):getChildByName('point'):setVisible(show and true or false)
	end
end

function ItemBagScene:setBarClick()
	local rn = self:getResourceNode()
	local function changeMode(mode)
		local leftBar = rn:getChildByName("leftBg")
		local children = leftBar:getChildren()
		for i,v in ipairs(children) do
			local bar_name = v:getName()
			if bar_name == string.format("mode_%d", self.btnSelected) then
				self:setBarHighLight(v, true)
			else
				self:setBarHighLight(v, false)
			end
		end
		self:resetList(self.btnSelected)
	end
	local function clickBar(sender)
		if self.btnSelected == sender:getParent():getTag() then
			return
		end
		-- self:getResourceNode():getChildByName('itemDetail'):setVisible(false)
		playEffectSound("sound/system/tab.mp3")
		self.btnSelected = sender:getParent():getTag()
		changeMode()
	end
	for i=1,4 do
		local mode_node = rn:getChildByName("leftBg"):getChildByName("mode_"..i)
		if i == 1 then
			mode_node:getChildByName("selected"):setVisible(true)
		end
		local str = ''
		if i == 1 then
			str = 'prop'
		elseif i == 2 then
			str = 'equip'
		elseif i == 3 then
			str = 'gem'
		elseif i == 4 then
			str = 'drawing'
		end

		mode_node:getChildByName("text"):setString(CONF:getStringValue(str))

		mode_node:getChildByName("selected"):addClickEventListener(clickBar)
		mode_node:getChildByName("normal"):addClickEventListener(clickBar)
	end

	animManager:runAnimOnceByCSB(rn, "ItemBag/ItemBagScene.csb", "intro", function ( ... )

	end)
end

function ItemBagScene:setItemDetail(item)
	local rn = self:getResourceNode()
	local node_pos = rn:getChildByName('Node_pos')
	local node = require("app.ExResInterface"):getInstance():FastLoad("ItemBag/ItemDetailNode.csb")
	node:setPosition(0,0)
	rn:addChild(node)
	node:setName('nodeDetail')
	local conf = self:getItemConfDetail(item.id)
	local itemConf = CONF.ITEM.get(item.id)
	node:getChildByName("bg"):setTexture("RankLayer/ui/ui_avatar_"..itemConf.QUALITY..".png")
	local icon = itemConf.ICON_ID or itemConf.RES_ID
	node:getChildByName("icon"):loadTexture("ItemIcon/"..icon..".png")
	node:getChildByName('name'):setString(CONF:getStringValue(itemConf.NAME_ID))
	 if itemConf.QUALITY == 2 then
        node:getChildByName("name"):setTextColor(cc.c4b(33,255,70,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(33,255,70,255), cc.size(0.5,0.5))
    elseif itemConf.QUALITY == 3 then
        node:getChildByName("name"):setTextColor(cc.c4b(93,196,255,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(93,196,255,255), cc.size(0.5,0.5))
    elseif itemConf.QUALITY == 4 then
        node:getChildByName("name"):setTextColor(cc.c4b(236,79,255,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(236,79,255,255), cc.size(0.5,0.5))
    elseif itemConf.QUALITY == 5 then
        node:getChildByName("name"):setTextColor(cc.c4b(242,255,33,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(242,255,33,255), cc.size(0.5,0.5))
    end
	for i=1,3 do
		node:getChildByName('des_'..i):setVisible(false)
		node:getChildByName('des_text_'..i):setVisible(false)
	end
	if itemConf.BAG_TYPE == 1 or itemConf.BAG_TYPE == 4 then
		node:getChildByName('des_1'):setVisible(true)
		node:getChildByName('des_text_1'):setVisible(true)
		node:getChildByName('des_1'):setString(CONF:getStringValue('knapsack_have')..': ')
		node:getChildByName('des_text_1'):setString(item.num)
	else
		node:getChildByName('des_2'):setVisible(true)
		node:getChildByName('des_text_2'):setVisible(true)
		node:getChildByName('des_3'):setVisible(true)
		node:getChildByName('des_text_3'):setVisible(true)
		local str2 = ''
		local str22 = ''
		local str3 = ''
		local str33 = ''
		if itemConf.BAG_TYPE == 2 then
			str2 = CONF:getStringValue('break level')
			str22 = item.strength
			str3 = CONF:getStringValue('type')
			local equipConf = CONF.EQUIP.get(item.id)
			str33 = CONF:getStringValue('Equip_type_'..equipConf.TYPE)
		elseif itemConf.BAG_TYPE == 3 then
			str2 = CONF:getStringValue('level')
			str22 = conf.LEVEL
			str3 = CONF:getStringValue('have')
			str33 = item.num
		end
		node:getChildByName('des_2'):setString(str2..': ')
		node:getChildByName('des_text_2'):setString(str22)
		node:getChildByName('des_3'):setString(str3..': ')
		node:getChildByName('des_text_3'):setString(str33)
	end
	node:getChildByName('des_text_1'):setPosition(node:getChildByName('des_1'):getPositionX()+node:getChildByName('des_1'):getContentSize().width,node:getChildByName('des_1'):getPositionY())
	node:getChildByName('des_text_2'):setPosition(node:getChildByName('des_2'):getPositionX()+node:getChildByName('des_2'):getContentSize().width,node:getChildByName('des_2'):getPositionY())
	node:getChildByName('des_text_3'):setPosition(node:getChildByName('des_3'):getPositionX()+node:getChildByName('des_3'):getContentSize().width,node:getChildByName('des_3'):getPositionY())
	if itemConf.TYPE == 10 then
		local strTotal = CONF:getStringValue('wearing level')..': '..item.level..'\n'
		for i,v in pairs(item.attributes_base) do
			if v ~= 0 then
				strTotal = strTotal..CONF:getStringValue("Attr_"..i)..': '..math.floor(v + item.strength*v*CONF.PARAM.get("equip_strength").PARAM)..'\n'
			end
		end
		node:getChildByName('ins'):setString(strTotal)
	elseif itemConf.TYPE == 9 then 
		local strValue = conf.ATTR_VALUE
		for k,v in pairs(CONF.ShipPercentAttrs) do
			if conf.ATTR_KEY == v then
				strValue = strValue..'%'
			end
		end
		node:getChildByName('ins'):setString(CONF:getStringValue("Attr_"..conf.ATTR_KEY)..'+'..strValue)
	else
		local str = CONF:getStringValue(itemConf.MEMO_ID)
		str = string.gsub(str,"#",itemConf.VALUE)
		if itemConf.TYPE then
			if itemConf.TYPE == 16 then
				local strNum = CONF.AIRSHIP.get(itemConf.SHIPID).BLUEPRINT_NUM[1]
				local strName = CONF:getStringValue(CONF.AIRSHIP.get(itemConf.SHIPID).NAME_ID)
				str = string.gsub(string.gsub(CONF:getStringValue(itemConf.MEMO_ID),"%%d",strNum),"%%h",strName)
			elseif itemConf.TYPE == 12 then
				local reward_conf = CONF.REWARD.check(itemConf.KEY) and CONF.REWARD.check(itemConf.KEY)
	            if reward_conf then
	                for k,v in ipairs(reward_conf.ITEM) do
	                    local item = CONF.ITEM.get(v)
	                    if k ~= #reward_conf.ITEM then
	                        str = str..CONF:getStringValue(item.NAME_ID).."*"..reward_conf.COUNT[k]..", "
	                    else
	                        str = str..CONF:getStringValue(item.NAME_ID).."*"..reward_conf.COUNT[k]
	                    end
	                end
	            end
			end
		end
		node:getChildByName('ins'):setString(str)
	end
	for i=1,3 do
		node:getChildByName('Button_'..i):setVisible(false)
	end
	local btnStr1 = CONF:getStringValue('fuse')
	local btnStr2 = CONF:getStringValue('use')
	local btnStr3 = CONF:getStringValue('use')
	if itemConf.BAG_TYPE then
		if itemConf.CAN_USE == 1 then
			node:getChildByName('Button_3'):setVisible(itemConf.BAG_TYPE == 1)
		end
		node:getChildByName('Button_2'):setVisible(itemConf.BAG_TYPE ~= 1)
		node:getChildByName('Button_1'):setVisible(itemConf.BAG_TYPE ~= 1)
		if itemConf.BAG_TYPE == 2 then
			btnStr1 = CONF:getStringValue('resolve')
			btnStr2 = CONF:getStringValue('equip')
		elseif itemConf.BAG_TYPE == 3 then
			btnStr1 = CONF:getStringValue('fuse')
			btnStr2 = CONF:getStringValue('inlay')
		elseif itemConf.BAG_TYPE == 4 then
			btnStr1 = CONF:getStringValue('resolve')
			btnStr2 = CONF:getStringValue('use')
		end
	end
	node:getChildByName("Button_1"):getChildByName('Text'):setString(btnStr1)
	node:getChildByName("Button_2"):getChildByName('Text'):setString(btnStr2)
	node:getChildByName("Button_3"):getChildByName('Text'):setString(btnStr3)
	node:getChildByName("Button_3"):addClickEventListener(function ( sender )
		if itemConf.CAN_USE == 1 then -- 直接使用
			if itemConf.TYPE == 13 then -- 道具
				local param_strength = CONF.PARAM.get("strength_item_list").PARAM
				for k,v in ipairs(param_strength) do
					if itemConf.ID == v then
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ADD_STRENGTH_REQ"), Tools.encode("AddStrengthReq", 
							{
								type = 1,
								item = {key = item.id, value = 1},
							}
						))
						break
					end
				end
				local param_planet = CONF.PARAM.get("planet_rand_move_base_item").PARAM
				if itemConf.ID == param_planet then
					local function func( ... )

						if self.canSend then

							self.canSend = false
							self.planetGet = true
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"), Tools.encode("PlanetGetReq", 
									{
										type = 1,
									}
								))

							
						else
							tips:tips(CONF:getStringValue("too_fast"))
						end
					end

					local function createJumpTips( ... )
						local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/JumpTips.csb")
						node:getChildByName("back"):addClickEventListener(function ( ... )
							node:removeFromParent()
						end)

						node:getChildByName("text"):setString(CONF:getStringValue("random_jump_base"))
						node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))

						node:getChildByName("yes"):addClickEventListener(function ( ... )
							func()
							node:removeFromParent()
						end)

						tipsAction(node)
						self:addChild(node)

					end

					-- if cc.UserDefault:getInstance():getIntegerForKey("PlanetJumpTime") == 0  then
					if cc.exports.PlanetJumpTime == 0  then
						createJumpTips()
					else
						if player:getIsTodayOne() then
							createJumpTips()
						else
							func()
						end

					end
				end

				local param_energy = CONF.PARAM.get("planet_shield_base_item").PARAM
				for k,v in ipairs(param_energy) do
					if itemConf.ID == v then
						local canUse = true
						local planetUser = player:getPlayerPlanetUser()
						if Tools.isEmpty(planetUser.army_list) == false then
							for k,v in ipairs(planetUser.army_list) do
								for k,state in pairs(Status_Machine) do
									if state == 5 then
										if v.element_global_key ~= planetUser.base_global_key then
											canUse = false
										end
									elseif v.status_machine == state then
										canUse = false
									end
								end
							end
						end
						if canUse then
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_SHIELD_BASE_REQ"), Tools.encode("PlanetShieldReq", 
								{
									item_id = itemConf.ID,
								}
							))
						else
							tips:tips(CONF:getStringValue("use defeated"))
						end
						break
					end
				end

			elseif itemConf.TYPE == 12 then -- 礼包
				if itemConf.VALUE and player:getLevel() < itemConf.VALUE then
					tips:tips(CONF:getStringValue("level_not_enought"))
					return
				end
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_OPEN_GIFT_REQ"), Tools.encode("OpenGiftReq", 
					{
						item_id = itemConf.ID,
						num = 1,
					}
				))
			end
			
		else
			self:goScene(1,item)
		end
	end)
	node:getChildByName("Button_2"):addClickEventListener(function ( sender )
		self:goScene(2,item)
	end)
	node:getChildByName("Button_1"):addClickEventListener(function ( sender )
		self:goScene(3,item)
	end)

	node:getChildByName('back_0'):setSwallowTouches(true)
	node:getChildByName('back_0'):addClickEventListener(function()
		node:removeFromParent()
		end)
end

function ItemBagScene:resetList(selected)
	if self.list then
		self.list:clear()
	end
	local rn = self:getResourceNode()
	local newItems = player:getItemUpdateTab()
	local listData = {}
	local newItemIDs = {}
	if selected == 2 then
		self:retsetAllEquips()
		listData = Tools.clone(self.equips)
		newItemIDs = newItems.equip
	else
		self:retsetAllItems()
		if selected == 1 then
			listData = Tools.clone(self.items)
			newItemIDs = newItems.item
		elseif selected == 3 then
			listData = Tools.clone(self.jewels)
			newItemIDs = newItems.gem
		elseif selected == 4 then
			listData = Tools.clone(self.drawings)
			newItemIDs = newItems.drawing
		end
	end
	if listData and next(listData) then
		rn:getChildByName('Text_non'):setVisible(false)
		for i,v in ipairs(listData) do
			local itemConf = CONF.ITEM.get(v.id)
			local item_node = require("app.ExResInterface"):getInstance():FastLoad("ItemBag/ItemNode.csb")
			item_node:getChildByName('Sprite_32'):setVisible(false)
			item_node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..itemConf.QUALITY..".png")
			local icon = itemConf.ICON_ID
			item_node:getChildByName("icon"):loadTexture("ItemIcon/"..icon..".png")
			item_node:getChildByName("level_num"):setVisible(false)
			item_node:getChildByName("level"):setVisible(false)
			item_node:getChildByName("num"):setString(formatRes(v.num))
			if itemConf.TYPE == 9 or itemConf.TYPE == 10 then
				item_node:getChildByName("level_num"):setVisible(true)
			end 
			for k,id in pairs(newItemIDs) do
				if selected == 2 then
					if k == v.guid and id == v.id then
						item_node:getChildByName('Sprite_32'):setVisible(true)
					end
				else
					if k == v.id then
						item_node:getChildByName('Sprite_32'):setVisible(true)
					end
				end
			end
			if itemConf.TYPE == 10 then
				local equipConf = CONF.EQUIP.get(v.id)
				item_node:getChildByName("num"):setString('Lv.'..equipConf.LEVEL)
				item_node:getChildByName("level_num"):setString('+'..v.strength)
				if v.strength == 0 then
					item_node:getChildByName("level_num"):setVisible(false)
				end
			end
			if itemConf.TYPE == 9 then
				item_node:getChildByName("level"):setVisible(true)
				local genConf = CONF.GEM.get(v.id)
				item_node:getChildByName("level_num"):setString(genConf.LEVEL)
			end
			item_node:setTag(v.id)
			local has_num = v.num 
			item_node:setTag(v.id)
			
			local func = function ( ... )
				self.itemSelected = i
				local children = rn:getChildByName("list"):getChildren()
				for k,v in pairs(children) do
					v:getChildByName("select_light"):setVisible(false)
				end
				item_node:getChildByName("select_light"):setVisible(true)
				self:setItemDetail(v)
				item_node:getChildByName('Sprite_32'):setVisible(false)
				for k,id in pairs(newItemIDs) do
					if selected == 2 then
						if k == v.guid and id == v.id then
							newItemIDs[k] = nil
						end
					else
						if k == v.id then
							newItemIDs[k] = nil
						end
					end
				end
				self:updatePointV(self.btnSelected)
			end

			local callback = {node = item_node:getChildByName("touch"), func = func}


			if v.num and v.num > 0 then
				self.list:addElement(item_node,{callback = callback})
			end
		end
	else
		rn:getChildByName('Text_non'):setVisible(true)
	end
	if listData and listData[1] then
		if rn:getChildByName('list'):getChildByTag(listData[1].id) ~= nil then
			-- rn:getChildByName('list'):getChildByTag(listData[1].id):getChildByName("select_light"):setVisible(true)
		end
		-- self.itemSelected = 1
		-- self:setItemDetail(listData[1])
	end
end

function ItemBagScene:getItemConfDetail(id)
	local itemConf = CONF.ITEM.get(id)
	if itemConf.TYPE == 9 then
		return CONF.GEM.get(id)
	elseif itemConf.TYPE == 10 then
		return CONF.EQUIP.get(id)
	end
	return itemConf
end

function ItemBagScene:goScene(btnTag,item)
	local function go(sceneTag)
		if sceneTag == 16 or sceneTag == 18 or sceneTag == 21 or sceneTag == 22 then -- (舰队机库 16.装备 18.宝石 21.合成 22.突破)
			local param = CONF.PARAM.get("city_3_open").PARAM
			if player:getLevel() >=param[1] and player:getBuildingInfo(1).level >= param[2] then
				print(" go ShipsDevelopScene at 835 ItemBagScene ")
				app:pushView("ShipsScene/ShipsDevelopScene",{type = 5})
			else
				tips:tips(CONF:getStringValue("function_not_open"))
			end
		elseif sceneTag == 17 then -- (17.熔炉装备 19.宝石 20.图纸)
			if player:getSystemGuideStep(CONF.FUNCTION_OPEN.get("dzgc_open").ID) == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() then
				tips:tips(CONF:getStringValue("resolve open"))
				return
			end
			local param =  CONF.PARAM.get("city_16_open").PARAM
			if player:getLevel() >=param[1] and player:getBuildingInfo(1).level >= param[2] then
				app:pushView("SmithingScene/SmithingScene",{kind = 2,mode = 1})
			else
				tips:tips(CONF:getStringValue("function_not_open"))
			end
		elseif sceneTag == 19 then -- 熔炉 宝石
			if player:getSystemGuideStep(CONF.FUNCTION_OPEN.get("dzgc_open").ID) == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() then
				tips:tips(CONF:getStringValue("smelt open"))
				return
			end
			local param =  CONF.PARAM.get("city_16_open").PARAM
			if player:getLevel() >=param[1] and player:getBuildingInfo(1).level >= param[2] then
				app:pushView("SmithingScene/SmithingScene",{kind = 3})
			else
				tips:tips(CONF:getStringValue("function_not_open"))
			end
		elseif sceneTag == 20 then -- 熔炉 飞船
			if player:getSystemGuideStep(CONF.FUNCTION_OPEN.get("dzgc_open").ID) == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() then
				tips:tips(CONF:getStringValue("smelt open"))
				return
			end
			local param =  CONF.PARAM.get("city_16_open").PARAM
			if player:getLevel() >=param[1] and player:getBuildingInfo(1).level >= param[2] then
				app:pushView("SmithingScene/SmithingScene",{kind = 2,mode = 2})
			else
				tips:tips(CONF:getStringValue("function_not_open"))
			end
		end
	end
	local itemConf = CONF.ITEM.get(item.id)
	local sceneTag
	local shipList = player:getShipList()
	if btnTag == 1 or btnTag == 3 then
		sceneTag = itemConf.BUTTON
	elseif btnTag == 2 then
		sceneTag = itemConf.BUTTON2 and itemConf.BUTTON2[1]
	end
	if sceneTag then
		if itemConf.BAG_TYPE == 4 then
			if btnTag == 2 then 
				local shipList = player:getShipList()
				local shipIDs = {}
				for k,v in pairs(shipList) do
					table.insert(shipIDs,v.id)
				end
				local resultOne = true
				for k,v in ipairs(shipIDs) do
					local confShip = CONF.AIRSHIP.get(v)
					if confShip.BLUEPRINT and confShip.BLUEPRINT[1] then
						if confShip.BLUEPRINT[1] == item.id then
							resultOne = false
						end
					end
				end
				if resultOne then
					go(sceneTag)
				else
					go(itemConf.BUTTON2[2])
				end
			else
				go(sceneTag)
			end
		else
			go(sceneTag)
		end
	end
end

function ItemBagScene:onExitTransitionStart()
	printInfo("ItemBagScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil
	end
end

return ItemBagScene