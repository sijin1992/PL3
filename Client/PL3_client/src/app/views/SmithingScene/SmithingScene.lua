local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local SmithingScene = class("SmithingScene", cc.load("mvc").ViewBase)

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

SmithingScene.RESOURCE_FILENAME = "SmithingScene/SmithingScene.csb"

SmithingScene.NEED_ADJUST_POSITION = true

SmithingScene.mode = 1
SmithingScene.kind = 1

local resID = {3001,4001,5001,6001}

SmithingScene.schedulerSingles = {}
SmithingScene.schedulerInfo = nil

SmithingScene.forge_equip_List = {}

SmithingScene.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="onBtnClick"}}},
}

function SmithingScene:onCreate(data) -- {kind(1,2,3(锻造,分解,合成)) = ,mode(kind1页签) = ,mode2(kind2页签) = }
	self.data_ = data
end

function SmithingScene:onBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			self:getApp():popView()
		end
	end
end

function SmithingScene:setForgeEquipList()
	local forge_list = player:getForgeEquipList()
	self.forge_equip_List = {}
	local buildingLevel = player:getBuildingInfo(CONF.EBuilding.kForge).level
	for k,v in ipairs(CONF.BUILDING_16) do
		if v.ID <= buildingLevel then
			for k1,equipId in ipairs(v.DEBLOCKING_EQUIP) do
				local equip = CONF.EQUIP.get(equipId)
				if not self.forge_equip_List[equip.TYPE] then
					self.forge_equip_List[equip.TYPE] = {}
				end
				local tab = {}
				tab.id = equipId
				tab.item = {}
				local forge_equip = CONF.FORGEEQUIP.get(equipId)
				if Tools.isEmpty(forge_equip.ITEM_ID) == false then
					for n,item in ipairs(forge_equip.ITEM_ID) do
						local t = {}
						t.item = item
						t.num = forge_equip.ITEM_NUM[n]
						table.insert(tab.item,t)
					end
				end
				tab.res = {}
				if Tools.isEmpty(forge_equip.RES) == false then
					for n,num in ipairs(forge_equip.RES) do
						local t = {}
						t.item = resID[n]
						t.num = (num - v.RES[n]) > 0 and (num - v.RES[n]) or 0
						table.insert(tab.res,t)
					end
				end

				tab.equip = {}
				if Tools.isEmpty(forge_equip.EQUIP_ID) == false then
					for n,e in ipairs(forge_equip.EQUIP_ID) do
						local t = {}
						t.item = e
						t.num = forge_equip.EQUIP_NUM[n]
						table.insert(tab.equip,t)
					end
				end

				tab.forge_list = {}
				if Tools.isEmpty(forge_list) == false then
					for _,forge in ipairs(forge_list) do
						if forge.equip_id == equipId then
							tab.forge_list.guid = forge.guid
							tab.forge_list.start_time = forge.start_time
							break
						end
					end
				end
				table.insert(self.forge_equip_List[equip.TYPE],tab)
			end
		end
	end
	for i=1,4 do
		if self.forge_equip_List[i] then
			table.sort(self.forge_equip_List[i],function(a,b)
				local equipA = CONF.EQUIP.get(a.id)
				local equipB = CONF.EQUIP.get(b.id)
				if equipA.LEVEL ~= equipB.LEVEL then
					return equipA.LEVEL > equipB.LEVEL
				else
					return equipA.ID > equipB.ID
				end
				end)
		end
	end
end

function SmithingScene:setPointVisible()
	local rn = self:getResourceNode()
	if rn:getChildByName("forge_equip") then
		local btnAll = rn:getChildByName("forge_equip"):getChildByName("leftBg")
		local forge_list = player:getForgeEquipList()
		for i=1,4 do
			local mode = btnAll:getChildByName("mode_"..i)
			for k,v in ipairs(forge_list) do
				local cfg_equip = CONF.EQUIP.get(v.equip_id)
				if cfg_equip.TYPE == i then
					mode:getChildByName("point"):setVisible(true)
					mode:getChildByName("point"):setTexture("Common/ui/spherical_red.png")
					local total_time = CONF.FORGEEQUIP.get(v.equip_id).EQUIP_TIME
					local need_time = total_time - CONF.BUILDING_16.get(player:getBuildingInfo(CONF.EBuilding.kForge).level).EQUIP_FORGE_SPEED
					local time = v.start_time + need_time - player:getServerTime()
					if time <= 0 then
						mode:getChildByName("point"):setTexture("Common/ui/spherical_green.png")
					end
				end
			end
		end
	end
end

function SmithingScene:resetMode()
	local building_level = player:getBuildingInfo(CONF.EBuilding.kForge).level
	if Tools.isEmpty(self.forge_equip_List) == false then
		local canbreak = false
		for k,v in ipairs(self.forge_equip_List) do
			if Tools.isEmpty(v) == false then
				for _,info in ipairs(v) do
					if Tools.isEmpty(info.forge_list) == false then
						local cequip = CONF.EQUIP.get(info.id)
						local total_time = CONF.FORGEEQUIP.get(info.id).EQUIP_TIME
						local need_time = total_time - CONF.BUILDING_16.get(building_level).EQUIP_FORGE_SPEED
						local time = info.forge_list.start_time + need_time - player:getServerTime()
						if time <= 0 then
							canbreak = true
							self.mode = cequip.TYPE
							break
						else
							self.mode = cequip.TYPE
						end
					end
				end
			end
			if canbreak then
				break
			end
		end
	end
end

function SmithingScene:createForgeEquipNode()
	local svd_ = nil
	for k,v in pairs(self.schedulerSingles) do
		if v ~= nil then
			scheduler:unscheduleScriptEntry(v)
			v = nil
		end
	end
	self.schedulerSingles = {}
	self:setForgeEquipList()
	local node_forge = require("app.ExResInterface"):getInstance():FastLoad("SmithingScene/ForgeNode.csb")
	if svd_ then
		svd_:clear()
	else
		svd_ = require("util.ScrollViewDelegate"):create(node_forge:getChildByName("list") ,cc.size(0,5), cc.size(715 ,135)) 
		svd_:getScrollView():setScrollBarEnabled(false)
	end
	local function setBarHighLight(bar, flag)
		if flag == true then
			bar:getChildByName("selected"):setVisible(true)
			bar:getChildByName("normal"):setVisible(false)
		else
			bar:getChildByName("selected"):setVisible(false)
			bar:getChildByName("normal"):setVisible(true)
		end
	end

	local function changeMode()
		playEffectSound("sound/system/tab.mp3")		
		local children = node_forge:getChildByName("leftBg"):getChildren()
		local function func(v)
			local bar_name = v:getName()
			if bar_name == string.format("mode_%d", self.mode) then
				setBarHighLight(v, true)
			else
				setBarHighLight(v, false)
			end
		end
		for i,v in ipairs(children) do
			func(v)
		end
		for i=1,4 do
			local mode_node = node_forge:getChildByName("leftBg"):getChildByName("mode_"..i)
			mode_node:getChildByName("text"):setVisible(true)
			mode_node:getChildByName("text_0"):setVisible(false)
			if self.mode == i then
				mode_node:getChildByName("text"):setVisible(false)
				mode_node:getChildByName("text_0"):setVisible(true)
			end
		end
	end

	local function createEquipInfo(info) -- {id,forge_list}
		if Tools.isEmpty(info) then return end
		local node = require("app.ExResInterface"):getInstance():FastLoad("SmithingScene/EquipInfoNode.csb")
		local image = node:getChildByName("Image_18")
		local equip = CONF.EQUIP.get(info.id)
		local attr = equip.ATTR
		for k,v in ipairs(equip.KEY) do
			for _,pre in pairs(CONF.ShipPercentAttrs) do
				if v == pre then
					attr[k] = attr[v].."%"
					break
				end
			end
		end
		image:getChildByName("equip"):getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..equip.QUALITY..".png")
		image:getChildByName("equip"):getChildByName("icon"):setVisible(true)
		image:getChildByName("equip"):getChildByName("icon"):loadTexture("ItemIcon/"..equip.RES_ID..".png")
		image:getChildByName("equip"):getChildByName("shadow"):setVisible(false)
		image:getChildByName("equip"):getChildByName("num"):setVisible(false)
		image:getChildByName("equip"):getChildByName("level_num"):setVisible(true)
		image:getChildByName("equip"):getChildByName("level_num"):setString("Lv.".. equip.LEVEL)
		image:getChildByName("equip"):getChildByName("shadow_0"):setVisible(false)

		image:getChildByName("name"):setString(CONF:getStringValue(equip.NAME_ID))
		-- image:getChildByName("btn"):setVisible(false)
		image:getChildByName("creating"):setVisible(false)
		image:getChildByName("attr1"):setVisible(false)
		image:getChildByName("attr2"):setVisible(false)

		local building_level = player:getBuildingInfo(CONF.EBuilding.kForge).level
		local total_time = CONF.FORGEEQUIP.get(info.id).EQUIP_TIME
		local need_time = total_time - CONF.BUILDING_16.get(building_level).EQUIP_FORGE_SPEED

		local function update()
			-- image:getChildByName("btn"):setVisible(false)
			image:getChildByName("btn"):getChildByName("text"):setVisible(true)
			image:getChildByName("btn"):getChildByName("Sprite_item"):setVisible(false)
			image:getChildByName("btn"):getChildByName("text_0"):setVisible(false)
			image:getChildByName("creating"):setVisible(false)
			if Tools.isEmpty(info.forge_list) then
				image:getChildByName("btn"):setVisible(true)
				image:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("Check"))
				image:getChildByName("btn"):loadTextures("Common/newUI/button_blue.png","Common/newUI/button_blue_light.png")
			else
				local time = info.forge_list.start_time + need_time - player:getServerTime()
				if time <= 0 then
					image:getChildByName("btn"):setVisible(true)
					image:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("Get"))
					image:getChildByName("btn"):loadTextures("Common/newUI/button_yellow.png","Common/newUI/button_yellow_light.png")
					if self.schedulerSingles[info.id] then
						scheduler:unscheduleScriptEntry(self.schedulerSingles[info.id])
						self.schedulerSingles[info.id] = nil
					end
					if can_tip then
						local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("exploit complete"))
						node:setPosition(cc.exports.VisibleRect:center())
						self:addChild(node)
					end
				else
					image:getChildByName("creating"):setVisible(true)
					-- image:getChildByName("btn"):setVisible(false)
					image:getChildByName("creating"):setString(CONF:getStringValue("forging"))
					image:getChildByName("creating"):getChildByName("creating_0"):setString(formatTime(time))
					if self.schedulerSingles[info.id] == nil then
						self.schedulerSingles[info.id] = scheduler:scheduleScriptFunc(update,1,false)
					end
					image:getChildByName("btn"):getChildByName("Sprite_item"):setVisible(true)
					image:getChildByName("btn"):getChildByName("text_0"):setVisible(true)
					image:getChildByName("btn"):getChildByName("text"):setVisible(false)
					image:getChildByName("btn"):getChildByName("text_0"):setString(player:getSpeedUpNeedMoney(time))
				end
			end
		end
		update()
		image:getChildByName("btn"):addClickEventListener(function()
			if Tools.isEmpty(info.forge_list) then
				-- if Tools.isEmpty(info.item) == false then
				-- 	for k,v in ipairs(info.item) do
				-- 		local haveNum  = player:getItemNumByID( v.item )
				-- 		if haveNum < v.num then
				-- 			tips:tips(CONF:getStringValue("Material_not_enought"))
				-- 			return
				-- 		end
				-- 	end
				-- end
				-- if Tools.isEmpty(info.res) == false then
				-- 	for k,v in ipairs(info.res) do
				-- 		local haveNum  = player:getItemNumByID( v.item )
				-- 		if haveNum < v.num then
				-- 			tips:tips(CONF:getStringValue("res_not_enough"))
				-- 			return
				-- 		end
				-- 	end
				-- end
				-- local strData = Tools.encode("CreateEquipReq", {   
				-- 	type = 1,
				-- 	equip_id = info.id,
				-- })
				-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CREATE_EQUIP_REQ"),strData)
				local center = cc.exports.VisibleRect:center()
				local layer = self:getApp():createView("SmithingScene/ForgeEquipInfoLayer",info)
				layer:setName("Infolayer")
				tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
				self:addChild(layer)
			else
				if player:getNormalBuildingQueueNow() then
					local info = player:getBuildingQueueBuild(1)
					if info.index == 16 then
						tips:tips(CONF:getStringValue("building level"))
						return
					end
				end
				if player:getMoneyBuildingQueueOpen() then
					local info = player:getBuildingQueueBuild(2)
					if info.index == 16 then
						tips:tips(CONF:getStringValue("building level"))
						return
					end
				end
				local time = info.forge_list.start_time + need_time - player:getServerTime()
				if time <= 0 then
					local strData = Tools.encode("CreateEquipReq", {   
						type = 2,
						forge_guid = info.forge_list.guid,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CREATE_EQUIP_REQ"),strData)
				else
					if not self:getChildByName("makesureLayer") then
						local node = require("app.ExResInterface"):getInstance():FastLoad("CityScene/AddStrengthLayer_Tips.csb")
						node:setName("makesureLayer")
						node:getChildByName("Text_1_0_0_0"):setString(CONF:getStringValue("pay_forge"))
						node:getChildByName("strenth_count"):setVisible(false)
						node:setPosition(0,0)
						self:addChild(node)



						node:getChildByName("cancel"):addClickEventListener(function()
							node:removeFromParent()
							end)
						node:getChildByName("buy_SureBtn"):addClickEventListener(function()
							if player:getMoney() <= player:getSpeedUpNeedMoney(time) then
								tips:tips(CONF:getStringValue("no enought credit"))
								return
							end
							local strData = Tools.encode("CreateEquipReq", {   
									type = 2,
									forge_guid = info.forge_list.guid,
								})
								GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CREATE_EQUIP_REQ"),strData)
							end)


	--ADD WJJ 20180808
	require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Duanzao_PayCD(node)
					end
				end
			end
			end)
		local addHeight = 0
		for k,v in ipairs(equip.KEY) do
			if k%2 ~= 0 then
				local label = cc.Label:createWithTTF(CONF:getStringValue("Attr_"..v)..":"..attr[k], "fonts/cuyabra.ttf", 20)
				label:setAnchorPoint(cc.p(0,1))
				-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
				label:setName("label"..k)
				local mod = math.modf(k/2)
				label:setPosition(image:getChildByName("attr1"):getPositionX(),image:getChildByName("attr1"):getPositionY()-mod*(label:getContentSize().height) - 8)
				addHeight = label:getPositionY()-label:getContentSize().height
				image:addChild(label)
			else
				local label = cc.Label:createWithTTF(CONF:getStringValue("Attr_"..v)..":"..attr[k], "fonts/cuyabra.ttf", 20)
				label:setAnchorPoint(cc.p(0,1))
				-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
				label:setName("label"..k)
				local mod = math.modf((k-1)/2)
				label:setPosition(image:getChildByName("attr2"):getPositionX(),image:getChildByName("attr2"):getPositionY()-mod*(label:getContentSize().height) - 8)
				image:addChild(label)
			end
		end
		if addHeight < 0 then
			node:getChildByName("Image_18"):setContentSize(cc.size(node:getChildByName("Image_18"):getContentSize().width,node:getChildByName("Image_18"):getContentSize().height+math.abs(addHeight)))
			image:getChildByName("Image_20"):setContentSize(cc.size(image:getChildByName("Image_20"):getContentSize().width,node:getChildByName("Image_18"):getContentSize().height))
			for k,v in pairs(image:getChildren()) do
				v:setPositionY(v:getPositionY()+math.abs(addHeight)+5)
			end
		end
		-- image:getChildByName("btn"):setPositionY(node:getChildByName("Image_18"):getContentSize().height/2)
		-- image:getChildByName("creating"):setPosition(image:getChildByName("btn"):getPosition())
		return node
	end

	local function refreshListInfo()
		svd_:clear()
		if Tools.isEmpty(self.forge_equip_List[self.mode]) == false then
			for k,v in ipairs(self.forge_equip_List[self.mode]) do
				local node = createEquipInfo(v)
				local func = function ( ... )
					local center = cc.exports.VisibleRect:center()
					local layer = self:getApp():createView("SmithingScene/ForgeEquipInfoLayer",v)
					layer:setName("Infolayer")
					tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
					self:addChild(layer)
				end

				local callback = {node = node:getChildByName("Image_18"), func = func}
				svd_:addElement(node,{size = cc.size(715 ,node:getChildByName("Image_18"):getContentSize().height),callback = callback})
			end
		end
		svd_:resetAllElementPosition()
	end
	local function btnClick(i)
		for k,v in pairs(self.schedulerSingles) do
			if v ~= nil then
				scheduler:unscheduleScriptEntry(v)
				v = nil
			end
		end
		self.schedulerSingles = {}
		self.mode = i
		changeMode()
		refreshListInfo()
	end
	for i=1,4 do
		local mode_node = node_forge:getChildByName("leftBg"):getChildByName("mode_"..i)
		mode_node:getChildByName("text"):setString(CONF:getStringValue("Equip_type_"..i))
		mode_node:getChildByName("text_0"):setString(CONF:getStringValue("Equip_type_"..i))
		mode_node:getChildByName("selected"):addClickEventListener(function()
			if self.mode == i then return end
			btnClick(i)
			end)
		mode_node:getChildByName("normal"):addClickEventListener(function()
			if self.mode == i then return end
			btnClick(i)
			end)
	end
	changeMode()
	refreshListInfo()
	return node_forge
end

function SmithingScene:changeKind(kind)
	self.kind = kind or 1
	for k,v in pairs(self.schedulerSingles) do
		if v ~= nil then
			scheduler:unscheduleScriptEntry(v)
			v = nil
		end
	end
	self.schedulerSingles = {}
	local rn = self:getResourceNode()
	local node_pos = rn:getChildByName("Node_pos")
	for i=1,4 do
		rn:getChildByName("btn_all"):getChildByName("node_"..i):getChildByName("selected"):setVisible(false)
		rn:getChildByName("btn_all"):getChildByName("node_"..i):getChildByName("text_selected"):setVisible(false)
		rn:getChildByName("btn_all"):getChildByName("node_"..i):getChildByName("text"):setVisible(true)
	end
	rn:getChildByName("btn_all"):getChildByName("node_"..self.kind):getChildByName("selected"):setVisible(true)
	rn:getChildByName("btn_all"):getChildByName("node_"..self.kind):getChildByName("text_selected"):setVisible(true)
	if self.kind == 1 then
		if rn:getChildByName("forge_equip") then
			rn:getChildByName("forge_equip"):removeFromParent()
		end
		if rn:getChildByName("resolve_node") then
			rn:getChildByName("resolve_node"):removeFromParent()
		end
		if rn:getChildByName("Amalgamation_Node") then
			rn:getChildByName("Amalgamation_Node"):removeFromParent()
		end
        if rn:getChildByName("Handbook_Node") then
			rn:getChildByName("Handbook_Node"):removeFromParent()
		end
		self:setForgeEquipList()
		self:resetMode()
		local forge_equip = self:createForgeEquipNode()
		forge_equip:setName("forge_equip")
		forge_equip:setPosition(node_pos:getPosition())
		rn:addChild(forge_equip)
	elseif self.kind == 2 then
		if rn:getChildByName("forge_equip") then
			rn:getChildByName("forge_equip"):removeFromParent()
		end
		if rn:getChildByName("resolve_node") then
			rn:getChildByName("resolve_node"):removeFromParent()
		end
		if rn:getChildByName("Amalgamation_Node") then
			rn:getChildByName("Amalgamation_Node"):removeFromParent()
		end
        if rn:getChildByName("Handbook_Node") then
			rn:getChildByName("Handbook_Node"):removeFromParent()
		end
		local resolve_node = require("app.views.SmithingScene.ResolveNode"):createResolveNode(self.mode2)
		resolve_node:setName("resolve_node")
		resolve_node:setPosition(node_pos:getPosition())
		rn:addChild(resolve_node)
	elseif self.kind == 3 then
		if rn:getChildByName("forge_equip") then
			rn:getChildByName("forge_equip"):removeFromParent()
		end
		if rn:getChildByName("resolve_node") then
			rn:getChildByName("resolve_node"):removeFromParent()
		end
		if rn:getChildByName("Amalgamation_Node") then
			rn:getChildByName("Amalgamation_Node"):removeFromParent()
		end
        if rn:getChildByName("Handbook_Node") then
			rn:getChildByName("Handbook_Node"):removeFromParent()
		end
		local Amalgamation_Node = require("app.views.SmithingScene.AmalgamationNode"):createNode()
		Amalgamation_Node:setName("Amalgamation_Node")
		Amalgamation_Node:setPosition(node_pos:getPosition())
		rn:addChild(Amalgamation_Node)
    elseif self.kind == 4 then
		if rn:getChildByName("forge_equip") then
			rn:getChildByName("forge_equip"):removeFromParent()
		end
		if rn:getChildByName("resolve_node") then
			rn:getChildByName("resolve_node"):removeFromParent()
		end
		if rn:getChildByName("Amalgamation_Node") then
			rn:getChildByName("Amalgamation_Node"):removeFromParent()
		end
        if rn:getChildByName("Handbook_Node") then
			rn:getChildByName("Handbook_Node"):removeFromParent()
		end
		local Handbook_Node = require("app.views.SmithingScene.HandBookNode"):createNode()
		Handbook_Node:setName("Handbook_Node")
		Handbook_Node:setPosition(node_pos:getPosition())
		rn:addChild(Handbook_Node)
	end
end

function SmithingScene:onEnterTransitionFinish()

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kForge)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("dzgc_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end
	
	self.mode2 = 1
	if self.data_ and self.data_.kind then
		self.kind = self.data_.kind
		self.mode = self.data_.mode or 1
		self.mode2 = self.data_.mode2 or 1
	end
	for k,v in pairs(self.schedulerSingles) do
		if v ~= nil then
			scheduler:unscheduleScriptEntry(v)
			self.schedulerSingles[k] = nil
		end
	end
	self.schedulerSingles = {}
	self:changeKind(self.kind)
	local rn = self:getResourceNode()
	local node_pos = rn:getChildByName("Node_pos")
	rn:getChildByName("title"):setString(CONF:getStringValue("BuildingName_16"))
	-- rn:getChildByName("Image_22_0"):setPositionX(rn:getChildByName("title"):getPositionX()+rn:getChildByName("title"):getContentSize().width+5)
	local kind_text = {"forge_title","smelt","create","Illustrations"}
	for i=1,4 do
		local btnList = rn:getChildByName("btn_all")
		btnList:getChildByName("node_"..i):getChildByName("text_selected"):setString(CONF:getStringValue(kind_text[i]))
		btnList:getChildByName("node_"..i):getChildByName("text"):setString(CONF:getStringValue(kind_text[i]))
		btnList:getChildByName("node_"..i):getChildByName("btn"):addClickEventListener(function()
			if self.kind == i then return end
			self:changeKind(i)
			end)
	end
	if self.schedulerInfo == nil then
		local function update()
			self:setPointVisible()
		end
		self.schedulerInfo = scheduler:scheduleScriptFunc(update,1,false)
	end
	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_CREATE_EQUIP_RESP") then 
			local proto = Tools.decode("CreateEquipResp",strData)
			print("CreateEquipResp result  "..proto.result)
			if proto.result ~= 0 then
				return
			end 
			if self.kind == 1 then
				if rn:getChildByName("forge_equip") then
					rn:getChildByName("forge_equip"):removeFromParent()
				end
				local forge_equip = self:createForgeEquipNode()
				forge_equip:setName("forge_equip")
				forge_equip:setPosition(node_pos:getPosition())
				rn:addChild(forge_equip)
				if proto.get_equip_guid and proto.get_equip_guid ~= 0  then
					if not self:getChildByName("Infolayer") then
						local equip = player:getEquipByGUID( proto.get_equip_guid )
						if equip then
							local node = require("util.RewardNode"):createGettedNodeWithList({{id = equip.equip_id,num = 1}})
							tipsAction(node)
							node:setPosition(cc.exports.VisibleRect:center())
							self:addChild(node)
						end
					end
				end
				if self:getChildByName("makesureLayer") then
					self:getChildByName("makesureLayer"):removeFromParent()
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_RESOLVE_EQUIP_RESP") then
			local proto = Tools.decode("ResolveEquipResp",strData)
			gl:releaseLoading()
			if proto.result == 0 then
				if rn:getChildByName("resolve_node") then
					rn:getChildByName("resolve_node"):removeFromParent()
				end
				local resolve_node = require("app.views.SmithingScene.ResolveNode"):createResolveNode(1)
				resolve_node:setName("resolve_node")
				resolve_node:setPosition(node_pos:getPosition())
				rn:addChild(resolve_node)
				local node = require("util.RewardNode"):createNodeWithList(proto.get_item_list, 1)
				tipsAction(node)
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				local getTip = require("util.RewardNode"):createRewardListTip(proto.get_item_list, 1);
				getTip:setPosition(cc.exports.VisibleRect:top())
				self:addChild(getTip);
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_RESOLVE_BLUEPRINT_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("ResolveBlueprintResp",strData)

			if proto.result == 0 then
				if rn:getChildByName("resolve_node") then
					rn:getChildByName("resolve_node"):removeFromParent()
				end
				local resolve_node = require("app.views.SmithingScene.ResolveNode"):createResolveNode(2)
				resolve_node:setName("resolve_node")
				resolve_node:setPosition(node_pos:getPosition())
				rn:addChild(resolve_node)
				local node = require("util.RewardNode"):createNodeWithList(proto.get_item_list, 2)
				tipsAction(node)
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				local getTip = require("util.RewardNode"):createRewardListTip(proto.get_item_list, 2)
				getTip:setPosition(cc.exports.VisibleRect:top());
				self:addChild(getTip);

			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GEM_MIX_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("MixGemResp",strData)

			if proto.result == 0 then
				print("proto.mix_result",proto.mix_result)
				local node = require("util.RewardNode"):createNodeWithList(proto.remain_list, 1, nil, proto.mix_result)
				tipsAction(node)
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				local getTip = require("util.RewardNode"):createRewardListTip(proto.remain_list, 1, nil)
				getTip:setPosition(cc.exports.VisibleRect:top());
				self:addChild(getTip);

				if proto.mix_result == true then
					playEffectSound("sound/system/fuse_succeed.mp3")
				else
					playEffectSound("sound/system/fuse_failed.mp3")
				end
				if rn:getChildByName("Amalgamation_Node") then
					rn:getChildByName("Amalgamation_Node"):removeFromParent()
				end
				local Amalgamation_Node = require("app.views.SmithingScene.AmalgamationNode"):createNode()
				Amalgamation_Node:setName("Amalgamation_Node")
				Amalgamation_Node:setPosition(node_pos:getPosition())
				rn:addChild(Amalgamation_Node)

			end
		end
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local   eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	self:getFreshRES()
end


function SmithingScene:getFreshRES()
	local rn = self:getResourceNode()
	if rn:getChildByName('Node_money') ~= nil then
		for i=1, 4 do
			if rn:getChildByName('Node_money'):getChildByName(string.format("res_text_%d",i)) then
				rn:getChildByName('Node_money'):getChildByName(string.format("res_text_%d",i)):setString(formatRes(player:getResByIndex(i)))
			end
		end
		rn:getChildByName('Node_money'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
		rn:getChildByName('Node_money'):getChildByName('money_add'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

			rechargeNode:init(self:getParent(), {index = 1})
			self:addChild(rechargeNode)
		end)
		rn:getChildByName('Node_money'):getChildByName('touch1'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			local rechargeNode = require("app.views.CityScene.RechargeNode"):create()
			rechargeNode:init(self:getParent(), {index = 1})
			self:addChild(rechargeNode)
		end)
	end
	local eventDispatcher = self:getEventDispatcher()
	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		for i=1, 4 do
			if rn:getChildByName('Node_money'):getChildByName(string.format("res_text_%d",i)) then
				rn:getChildByName('Node_money'):getChildByName(string.format("res_text_%d",i)):setString(formatRes(player:getResByIndex(i)))
			end
		end
		rn:getChildByName('Node_money'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		rn:getChildByName('Node_money'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)
end

function SmithingScene:onExitTransitionStart()
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.resListener_)
	for k,v in pairs(self.schedulerSingles) do
		if v ~= nil then
			scheduler:unscheduleScriptEntry(v)
			self.schedulerSingles[k] = nil
		end
	end
	if self.schedulerInfo ~= nil then
		scheduler:unscheduleScriptEntry(self.schedulerInfo)
		self.schedulerInfo = nil
	end
	self.schedulerSingles = {}
end

return SmithingScene