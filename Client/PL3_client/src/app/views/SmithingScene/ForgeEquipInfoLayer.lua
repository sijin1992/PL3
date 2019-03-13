local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local app = require("app.MyApp"):getInstance()

local ForgeEquipInfoLayer = class("ForgeEquipInfoLayer", cc.load("mvc").ViewBase)

ForgeEquipInfoLayer.RESOURCE_FILENAME = "SmithingScene/ForgeEquipNode.csb"

ForgeEquipInfoLayer.NEED_ADJUST_POSITION = true

local scheduler = cc.Director:getInstance():getScheduler()

local resID = {3001,4001,5001,6001}

function ForgeEquipInfoLayer:onCreate(data) -- {id,item{},res{},equip{},forge_list{}}
	self.data_ = data
end

function ForgeEquipInfoLayer:setForgeEquipList()
	-- CONF.BUILDING_14.get(player:getBuildingInfo(14).level)
	local forge_list = player:getForgeEquipList()
	self.forge_equip_List = {}
	local buildingLevel = player:getBuildingInfo(16).level
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

function ForgeEquipInfoLayer:onEnterTransitionFinish()
	self:setForgeEquipList()
	local rn = self:getResourceNode()
	local cfg_equip = CONF.EQUIP.get(self.data_.id)
	rn:getChildByName("title"):setString(CONF:getStringValue("forge_title"))
	rn:getChildByName("name"):setString(CONF:getStringValue(cfg_equip.NAME_ID))
	rn:getChildByName("item_equip"):getChildByName("num"):setVisible(false)
    rn:getChildByName("item_equip"):getChildByName("num_0"):setVisible(false)
	rn:getChildByName("item_equip"):getChildByName("icon_bg"):setTexture("ShipsScene/ui/ui_avatar_"..cfg_equip.QUALITY..".png")
	rn:getChildByName("item_equip"):getChildByName("icon"):setTexture("ItemIcon/"..cfg_equip.RES_ID..".png")
    rn:getChildByName("item_equip"):getChildByName("clickimg"):addClickEventListener(function ()
        if not rn:getChildByName("info_node") then
            local info_node = require("util.ItemInfoNode"):createEquipNode(self.data_.id, 10)
		    info_node:setName("info_node")
		    rn:addChild(info_node)
        end
    end)
	local building_level = player:getBuildingInfo(16).level
	local total_time = CONF.FORGEEQUIP.get(self.data_.id).EQUIP_TIME
	local need_time = total_time - CONF.BUILDING_16.get(building_level).EQUIP_FORGE_SPEED
	local svd = require("util.ScrollViewDelegate"):create(rn:getChildByName("list") ,cc.size(0,0), cc.size(317 ,284))
	local function setInfo()
		cfg_equip = CONF.EQUIP.get(self.data_.id)
		rn:getChildByName("title"):setString(CONF:getStringValue("forge_title"))
		rn:getChildByName("name"):setString(CONF:getStringValue(cfg_equip.NAME_ID))
		rn:getChildByName("item_equip"):getChildByName("num"):setVisible(false)
        rn:getChildByName("item_equip"):getChildByName("num_0"):setVisible(false)
		rn:getChildByName("item_equip"):getChildByName("icon_bg"):setTexture("ShipsScene/ui/ui_avatar_"..cfg_equip.QUALITY..".png")
		rn:getChildByName("item_equip"):getChildByName("icon"):setTexture("ItemIcon/"..cfg_equip.RES_ID..".png")
		total_time = CONF.FORGEEQUIP.get(self.data_.id).EQUIP_TIME
		need_time = total_time - CONF.BUILDING_16.get(building_level).EQUIP_FORGE_SPEED
		for i=1,6 do
			rn:getChildByName("item_res"..i):setVisible(false)
		end
		if Tools.isEmpty(self.data_.item) == false then
			for i,v in ipairs(self.data_.item) do
				if rn:getChildByName("item_res"..i) then
					local cfg_item = CONF.ITEM.get(v.item)
					rn:getChildByName("item_res"..i):setVisible(true)
					rn:getChildByName("item_res"..i):getChildByName("icon"):setTexture("ItemIcon/"..cfg_item.ICON_ID..".png")
					rn:getChildByName("item_res"..i):getChildByName("icon_bg"):setTexture("ShipsScene/ui/ui_avatar_"..cfg_item.QUALITY..".png")
                    rn:getChildByName("item_res"..i):getChildByName("clickimg"):addClickEventListener(function ()
                        if not rn:getChildByName("info_node") then
                            local info_node = require("util.ItemInfoNode"):createItemInfoNode(v.item,cfg_item.TYPE)
		                    info_node:setName("info_node")
		                    rn:addChild(info_node)
                        end
                    end)
					local num1 = rn:getChildByName("item_res"..i):getChildByName("num_0")
					local num2 = rn:getChildByName("item_res"..i):getChildByName("num")
					rn:getChildByName("item_res"..i):getChildByName("name"):setString(CONF:getStringValue(cfg_item.NAME_ID))
					num1:setVisible(true)
					num1:setString(formatRes(player:getItemNumByID(v.item)))
					if player:getItemNumByID(v.item) >= v.num then
						num1:setTextColor(cc.c4b(51,231,51,255))
						-- num1:enableShadow(cc.c4b(51,231,51,255), cc.size(0.2,0.2))
					else
						num1:setTextColor(cc.c4b(233,50,59,255))
						-- num1:enableShadow(cc.c4b(233,50,59,255), cc.size(0.2,0.2))
					end
					num2:setString("/"..formatRes(v.num))
					num1:setPositionX(num2:getPositionX()-num2:getContentSize().width)
				end
			end
		end
		local k = 1
		if Tools.isEmpty(self.data_.res) == false then
			for i,v in ipairs(self.data_.res) do
				if rn:getChildByName("item_res"..(#self.data_.item+k)) and v.num > 0 then
					local res = rn:getChildByName("item_res"..(#self.data_.item+k))
					local cfg_item = CONF.ITEM.get(v.item)
					res:getChildByName("name"):setString(CONF:getStringValue(cfg_item.NAME_ID))
					res:setVisible(true)
					res:getChildByName("icon"):setTexture("ItemIcon/"..cfg_item.ICON_ID..".png")
					res:getChildByName("icon_bg"):setTexture("ShipsScene/ui/ui_avatar_"..cfg_item.QUALITY..".png")
                    res:getChildByName("clickimg"):addClickEventListener(function ()
                        if not rn:getChildByName("info_node") then
                            local info_node = require("util.ItemInfoNode"):createItemInfoNode(v.item,cfg_item.TYPE)
		                    info_node:setName("info_node")
		                    rn:addChild(info_node)
                        end
                    end)
					res:getChildByName("num"):setString(v.num)
					res:getChildByName("num_0"):setVisible(false)
					if player:getItemNumByID(v.item) >= v.num then
						res:getChildByName("num"):setTextColor(cc.c4b(51,231,51,255))
						-- res:getChildByName("num"):enableShadow(cc.c4b(51,231,51,255), cc.size(0.2,0.2))
					else
						res:getChildByName("num"):setTextColor(cc.c4b(233,50,59,255))
						-- res:getChildByName("num"):enableShadow(cc.c4b(233,50,59,255), cc.size(0.2,0.2))
					end
					k = k +1
				end
			end
		end
		local attr = cfg_equip.ATTR
		for k,v in ipairs(cfg_equip.KEY) do
			for _,pre in pairs(CONF.ShipPercentAttrs) do
				if v == pre then
					attr[k] = attr[v].."%"
					break
				end
			end
		end
		local function createAttr()
			local node = require("app.ExResInterface"):getInstance():FastLoad("SmithingScene/TextNode.csb")
			node:getChildByName("title"):setVisible(false)
			local label = cc.Label:createWithTTF(CONF:getStringValue("level_ji")..":"..cfg_equip.LEVEL, "fonts/cuyabra.ttf", 20)
			node:addChild(label)
			label:setName("label")
			label:setAnchorPoint(cc.p(0,1))
			-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
			label:setPosition(node:getChildByName("title"):getPosition())
			for k,v in ipairs(cfg_equip.KEY) do
				local label = node:getChildByName("label"..k)
				if not label then
					label = cc.Label:createWithTTF(CONF:getStringValue("Attr_"..v)..":"..attr[k], "fonts/cuyabra.ttf", 20)
					label:setName("label"..k)
					node:addChild(label)
				end
				label:setAnchorPoint(cc.p(0,1))
				-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
				
				label:setPosition(node:getChildByName("label"):getPositionX(),node:getChildByName("label"):getPositionY()-(k)*(label:getContentSize().height + 10))
			end
			return node
		end
		svd:clear() 
		rn:getChildByName("list"):setScrollBarEnabled(false)
		local node = createAttr()
		svd:addElement(node)

		local function needUpdate()
			rn:getChildByName("jindu_bg"):setVisible(false)
			rn:getChildByName("jindu"):setVisible(false)
			rn:getChildByName("develop"):getChildByName("text"):setVisible(true)
			rn:getChildByName("develop"):getChildByName("text_0"):setVisible(false)
			rn:getChildByName("develop"):getChildByName("Sprite_item"):setVisible(false)
			rn:getChildByName("time"):setString(CONF:getStringValue("forge time")..":"..formatTime(need_time))
			rn:getChildByName("time"):setVisible(true)
			if Tools.isEmpty(self.data_.forge_list) then
				rn:getChildByName("develop"):getChildByName("text"):setString(CONF:getStringValue("forge_title"))
			else
				local time = self.data_.forge_list.start_time + need_time - player:getServerTime()
				if time <= 0 then
					rn:getChildByName("develop"):getChildByName("text"):setString(CONF:getStringValue("Get"))
					rn:getChildByName("time"):setVisible(false)
					if self.schedulerInfo then
						scheduler:unscheduleScriptEntry(self.schedulerInfo)
						self.schedulerInfo = nil
					end
				else
					rn:getChildByName("jindu_bg"):setVisible(true)
					rn:getChildByName("jindu"):setVisible(true)
					rn:getChildByName("develop"):getChildByName("text"):setVisible(false)
					rn:getChildByName("develop"):getChildByName("text_0"):setVisible(true)
					rn:getChildByName("develop"):getChildByName("Sprite_item"):setVisible(true)
					rn:getChildByName("develop"):getChildByName("text_0"):setString(player:getSpeedUpNeedMoney(time))
					local progress = require("util.ScaleProgressDelegate"):create(rn:getChildByName("jindu"), 240)
					local p = (need_time-time) < 0 and 0 or (need_time-time)
					local pro = p/need_time
					progress:setPercentage(pro*100)
					rn:getChildByName("time"):setString(formatTime(time))
					if self.schedulerInfo == nil then
						self.schedulerInfo = scheduler:scheduleScriptFunc(needUpdate,1,false)
					end
				end
			end
		end
		needUpdate()
	end
	setInfo()
	rn:getChildByName("Button_1"):addClickEventListener(function()
		self:removeFromParent()
		end)

	local function getPreAndNextInfo()
		local pre = {}
		local nex = {}
		self:setForgeEquipList()
		if Tools.isEmpty(self.forge_equip_List) == false then
			for k,v in pairs(self.forge_equip_List) do
				if Tools.isEmpty(v) == false then
					for m,n in ipairs(v) do
						if self.data_.id == n.id then
							if Tools.isEmpty(v[m+1]) == false then
								nex = v[m+1]
							end
							if Tools.isEmpty(v[m-1]) == false then
								pre = v[m-1]
							end
						end
					end
				end
			end
		end
		return pre,nex
	end
	local function showBtn(nex,pre)
		rn:getChildByName("qiehuan_left"):setVisible(Tools.isEmpty(pre) == false)
		rn:getChildByName("qiehuan_right"):setVisible(Tools.isEmpty(nex) == false)
	end
	local pre,nex = getPreAndNextInfo()
	showBtn(nex,pre)

    local function showjumplayer(jumpTab)
        if Tools.isEmpty(jumpTab) == false and not self:getChildByName("JumpChoseLayer") then
			jumpTab.scene = "EquipInfoLayer"
			local center = cc.exports.VisibleRect:center()
			local layer = app:createView("ShipsScene/JumpChoseLayer",jumpTab)
			layer:setName("JumpChoseLayer")
			tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
			self:addChild(layer)
		end
    end
	rn:getChildByName("qiehuan_left"):addClickEventListener(function()
		if self.schedulerInfo then
			scheduler:unscheduleScriptEntry(self.schedulerInfo)
			self.schedulerInfo = nil
		end
		local pre,nex = getPreAndNextInfo()
		if Tools.isEmpty(pre) == false then
			self.data_ = pre
		end
		local pre,nex = getPreAndNextInfo()
		showBtn(nex,pre)
		setInfo()
		end)
	rn:getChildByName("qiehuan_right"):addClickEventListener(function()
		if self.schedulerInfo then
			scheduler:unscheduleScriptEntry(self.schedulerInfo)
			self.schedulerInfo = nil
		end
		local pre,nex = getPreAndNextInfo()
		if Tools.isEmpty(nex) == false then
			self.data_ = nex
		end
		local pre,nex = getPreAndNextInfo()
		showBtn(nex,pre)
		setInfo()
		end)
	rn:getChildByName("develop"):addClickEventListener(function()
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

		if Tools.isEmpty(player:getForgeEquipList()) == false then
			if #player:getForgeEquipList() >= CONF.BUILDING_16.get(player:getBuildingInfo(16).level).CASE then
				local have = false
				for k,v in ipairs(player:getForgeEquipList()) do
					if self.data_.id == v.equip_id then
						have = true
					end
				end
				if not have then
					tips:tips(CONF:getStringValue("forge queue"))
					return
				end
			end
		end

		if Tools.isEmpty(self.data_.forge_list) then
			if Tools.isEmpty(self.data_.item) == false then
				for k,v in ipairs(self.data_.item) do
					local haveNum  = player:getItemNumByID( v.item )
					if haveNum < v.num then
						tips:tips(CONF:getStringValue("Material_not_enought"))
                        local jumpTab = {}
                        local cfg_item = CONF.ITEM.get(v.item)
                        if cfg_item and cfg_item.JUMP then
						    table.insert(jumpTab,cfg_item.JUMP)
					    end
                        showjumplayer(jumpTab)
						return
					end
				end
			end
			if Tools.isEmpty(self.data_.res) == false then
				for k,v in ipairs(self.data_.res) do
					local haveNum  = player:getItemNumByID( v.item )
					if haveNum < v.num then
						tips:tips(CONF:getStringValue("res_not_enough"))
                        local jumpTab = {}
                        local cfg_item = CONF.ITEM.get(v.item)
                        if cfg_item and cfg_item.JUMP then
						    table.insert(jumpTab,cfg_item.JUMP)
					    end
                        showjumplayer(jumpTab)
						return
					end
				end
			end
			local strData = Tools.encode("CreateEquipReq", {   
				type = 1,
				equip_id = self.data_.id,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CREATE_EQUIP_REQ"),strData)
		else
			local time = self.data_.forge_list.start_time + need_time - player:getServerTime()
			if time > 0 then
				if not self:getParent():getChildByName("makesureLayer") then
					local node = require("app.ExResInterface"):getInstance():FastLoad("CityScene/AddStrengthLayer_Tips.csb")
					node:setName("makesureLayer")
					node:getChildByName("Text_1_0_0_0"):setString(CONF:getStringValue("pay_forge"))
					node:getChildByName("strenth_count"):setVisible(false)
					node:setPosition(0,0)


					self:getParent():addChild(node)
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
								forge_guid = self.data_.forge_list.guid,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CREATE_EQUIP_REQ"),strData)
						end)


	--ADD WJJ 20180808
	require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Duanzao_PayCD(node)
				end
			else
				local strData = Tools.encode("CreateEquipReq", {   
					type = 2,
					forge_guid = self.data_.forge_list.guid,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CREATE_EQUIP_REQ"),strData)
			end
			
		end
		end)
	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_CREATE_EQUIP_RESP") then 
			local proto = Tools.decode("CreateEquipResp",strData)
			print("ForgeEquipInfoLayer CreateEquipResp result  "..proto.result)
			if proto.result ~= 0 then
				return
			end 
			local forge_list = player:getForgeEquipList()
			local new_forge = {}
			local have = false
			if Tools.isEmpty(forge_list) == false then
				for _,forge in ipairs(forge_list) do
					if forge.equip_id == self.data_.id then
						have = true
						new_forge = forge
						break
					end
				end
			end
			self.data_.forge_list = {}
			if have then
				self.data_.forge_list.guid = new_forge.guid
				self.data_.forge_list.start_time = new_forge.start_time
			end
			if proto.get_equip_guid and proto.get_equip_guid ~= 0  then
				local equip = player:getEquipByGUID( proto.get_equip_guid )
				if equip then
					local node = require("util.RewardNode"):createGettedNodeWithList({{id = equip.equip_id,num = 1}})
					tipsAction(node)
					node:setPosition(cc.exports.VisibleRect:center())
					self:getParent():addChild(node)
				end
			end
			setInfo()
			if self:getParent():getChildByName("makesureLayer") then
				self:getParent():getChildByName("makesureLayer"):removeFromParent()
			end
		end
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local   eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function ForgeEquipInfoLayer:onExitTransitionStart()
	printInfo("ForgeEquipInfoLayer:onExitTransitionStart()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	if self.schedulerInfo then
		scheduler:unscheduleScriptEntry(self.schedulerInfo)
		self.schedulerInfo = nil
	end
end

return ForgeEquipInfoLayer