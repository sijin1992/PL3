
local ResolveNode = class("ResolveNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local infoKind = {
	EQUIP = 1,
	DRAWING = 2,
}

ResolveNode.on_items = {0,0,0,0,0,0,0,0}

local diffX = 80

ResolveNode.itemAllNode = {}

function ResolveNode:addListener( node, fun1, fun2)

	local function beginhandle()
		if self.isTouch then
			self.count = self.count + 1
			if self.count >= 2 then
				self.longPress = true
				self.count = 0
				if fun2 then
					fun2()
				end
			end
		end
	end

	local function onTouchBegan(touch, event)

		local target = event:getCurrentTarget()
		
		local locationInNode = self.svd2_:getScrollView():convertToNodeSpace(touch:getLocation())

		local sv_s = self.svd2_:getScrollView():getContentSize()
		local sv_rect = cc.rect(0, 0, sv_s.width, sv_s.height)

		if cc.rectContainsPoint(sv_rect, locationInNode) then

			local ln = target:convertToNodeSpace(touch:getLocation())

			local s = target:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)
			
			if cc.rectContainsPoint(rect, ln) then

				self.isTouch = true
				self.beginHandle = scheduler:scheduleScriptFunc(beginhandle,0.3,false)   
				return true
			end

		end

		return false
	end

	local function onTouchMoved(touch, event)

		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			self.isMoved = true
		end
	end

	local function onTouchEnded(touch, event)
		scheduler:unscheduleScriptEntry(self.beginHandle)
		self.isTouch = false

		if self.isMoved then
			self.isMoved = false
			return false
		end

		if self.longPress then
			self.longPress = false
			self.count = 0
			return false
			-- fun2()
		end
		
		self.longPress = false
		self.count = 0
		if fun1 then
			fun1()
		end

	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self.svd2_:getScrollView():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

function ResolveNode:createResolveNode(mode)
	self.mode = mode or 1
	self.svd2_ = nil
	self.count = 0
	self.on_items = {0,0,0,0,0,0,0,0}
	self.itemAllNode = {}
	local selectedT = 1
	local node_forge = require("app.ExResInterface"):getInstance():FastLoad("SmithingScene/ResolveNode.csb")
	node_forge:getChildByName("break"):setString(CONF:getStringValue("decomposition_results"))
	node_forge:getChildByName("btn1"):getChildByName("text"):setString(CONF:getStringValue("smelt"))
	node_forge:getChildByName("btn2"):getChildByName("text"):setString(CONF:getStringValue("smart_choice"))
	node_forge:getChildByName("btn3"):getChildByName("text"):setString(CONF:getStringValue("a_key_to_cancel"))

	local function setBarHighLight(bar, flag)
		if flag == true then
			bar:getChildByName("selected"):setVisible(true)
			bar:getChildByName("normal"):setVisible(false)
		else
			bar:getChildByName("selected"):setVisible(false)
			bar:getChildByName("normal"):setVisible(true)
		end
	end
	local function setSelectedRefresh()
		for k,v in ipairs(self.itemAllNode) do
			if v then
				v:removeFromParent()
				v = nil
			end
		end
		for i=1,8 do
			node_forge:getChildByName("item"..i):getChildByName("FileNode_1"):setVisible(false)
			node_forge:getChildByName("item"..i):getChildByName("add"):setVisible(true)
			node_forge:getChildByName("item"..i):getChildByName("Image_48"):setOpacity(100)
		end
		for k,v in ipairs(self.on_items) do
			if v ~= 0 then
				node_forge:getChildByName("item"..k):getChildByName("FileNode_1"):setVisible(true)
				node_forge:getChildByName("item"..k):getChildByName("add"):setVisible(false)
				local item = node_forge:getChildByName("item"..k):getChildByName("FileNode_1")
				item:getChildByName("icon"):setVisible(true)
				node_forge:getChildByName("item"..k):getChildByName("Image_48"):setOpacity(0)
				if self.mode == infoKind.EQUIP then
					local equip = player:getEquipByGUID( v )
					if equip then
						local cfg_equip = CONF.EQUIP.get(equip.equip_id)
						item:getChildByName("num"):setString("Lv."..cfg_equip.LEVEL)
						item:getChildByName("level_num"):setString("+"..equip.strength)
						if equip.strength == 0 then
							item:getChildByName("level_num"):setVisible(false)
						end
						item:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..cfg_equip.QUALITY..".png")
						item:getChildByName("icon"):loadTexture("ItemIcon/"..cfg_equip.RES_ID..".png")
					end
				elseif self.mode == infoKind.DRAWING then
					local cfg_drawing = CONF.ITEM.get(v)
					local drawing =  player:getItemByID( v )
					item:getChildByName("num"):setString("1")
					item:getChildByName("level_num"):setString(cfg_drawing.LEVEL)
					item:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..cfg_drawing.QUALITY..".png")
					item:getChildByName("icon"):loadTexture("ItemIcon/"..cfg_drawing.ICON_ID..".png")
				end
			end
		end
		local items = {}
		local pair_list = {}
		local other_list = {}
		for k,v in ipairs(self.on_items) do
			if self.mode == infoKind.EQUIP then
				if v ~= 0 and player:getEquipByGUID(v) then
					local equip = player:getEquipByGUID( v )
					local ec = CONF.EQUIP.get(equip.equip_id)
					for i2,v2 in ipairs(ec.RESOLVE_ID) do
						local has = false
						local get_index = 0
						for i3,v3 in ipairs(items) do
							if v3.id == v2 then
								has = true
								get_index = i3
								break
							end
						end

						if has then
							items[get_index].num = items[get_index].num + ec.RESOLVE_NUM[i2]
						else
							local tt = {id = v2, num = ec.RESOLVE_NUM[i2]}

							table.insert(items, tt)
						end
					end

					if equip.strength > 0 then
						local sc = CONF.EQUIP_STRENGTH.get(equip.strength)
						for i2,v2 in ipairs(sc.RETURN_ITEM_ID) do

							-- if v2 ~= 3001 then
								local has = false
								local get_index = 0
								for i3,v3 in ipairs(items) do
									if v3.id == v2 then
										has = true
										get_index = i3
										break
									end
								end

								if has then
									items[get_index].num = items[get_index].num + sc.RETURN_ITEM_NUM[i2]*CONF.PARAM.get("equip_strength_"..equip.quality).PARAM
								else
									local tt = {id = v2, num = sc.RETURN_ITEM_NUM[i2]*CONF.PARAM.get("equip_strength_"..equip.quality).PARAM}

									table.insert(items, tt)
								end
							-- end
						end
					end
				end
			elseif self.mode == infoKind.DRAWING then
				if v ~= 0 then

					local conf = CONF.SHIP_BLUEPRINT.get(v)

					local has = false
					local get_index = 0
					for i2,v2 in ipairs(pair_list) do
						if v2.id == conf.RESOLVE_ID then 
							has = true
							get_index = i2 
							break
						end
					end

					if has then
						pair_list[get_index].min_num = pair_list[get_index].min_num + conf.INTERVAL_NUM[1]
						pair_list[get_index].max_num = pair_list[get_index].max_num + conf.INTERVAL_NUM[2]
					else
						local tt = {id = conf.RESOLVE_ID, min_num = conf.INTERVAL_NUM[1], max_num = conf.INTERVAL_NUM[2]}
						table.insert(pair_list, tt)
					end

					for i2,v2 in ipairs(conf.ITEM_ID) do
						local has = false
						for i3,v3 in ipairs(other_list) do
							if v3 == v2 then
								has = true
								break
							end
						end

						if not has then
							table.insert(other_list, v2)
						end
					end
				end
			end
		end
		self.itemAllNode = {}
		local x,y = node_forge:getChildByName("item_pos"):getPosition()
		for i,v in ipairs(items) do
			if v.id ~= 0 then
				local itemNode = require("util.ItemNode"):create():init(v.id, v.num)
				itemNode:setPosition(cc.p(x + (i-1)*100, y))
				node_forge:addChild(itemNode,88)
				table.insert(self.itemAllNode,itemNode)
			end
		end
		local item_num = 1
		for i,v in ipairs(pair_list) do
			local item_node = require("util.ItemNode"):create():init(v.id)
			item_node:getChildByName("text"):setString(v.min_num.."-"..v.max_num)
			item_node:getChildByName("text"):setVisible(true)
			item_node:setPosition(cc.p(x+(i-1)*diffX, y))
			node_forge:addChild(item_node,88)
			item_num = item_num + 1
			table.insert(self.itemAllNode, item_node)
		end
		for i,v in ipairs(other_list) do
			local item_node = require("util.ItemNode"):create():init(v)
			item_node:getChildByName("text"):setString("?")
			item_node:getChildByName("text"):setVisible(true)
			item_node:setPosition(cc.p(x+(item_num-1)*diffX, y))
			node_forge:addChild(item_node,88)
			item_num = item_num + 1
			table.insert(self.itemAllNode, item_node)
		end
		local disabled = false
		for k,v in ipairs(self.on_items) do
			if v ~= 0 then
				disabled = true
				break
			end
		end
		node_forge:getChildByName("btn3"):setEnabled(disabled)
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
		for i=1,2 do
			local mode_node = node_forge:getChildByName("leftBg"):getChildByName("mode_"..i)
			mode_node:getChildByName("text"):setVisible(true)
			mode_node:getChildByName("text_0"):setVisible(false)
			if self.mode == i then
				mode_node:getChildByName("text"):setVisible(false)
				mode_node:getChildByName("text_0"):setVisible(true)
			end
		end
		node_forge:getChildByName("btn2"):setVisible(self.mode == infoKind.EQUIP)
		self.on_items = {0,0,0,0,0,0,0,0}
		setSelectedRefresh()
	end

	local function btnClick(i)
		self.mode = i or 1
		changeMode()
		-- refreshListInfo()
	end

	local title = {"equip","drawing"}
	for i=1,2 do
		local mode_node = node_forge:getChildByName("leftBg"):getChildByName("mode_"..i)
		mode_node:getChildByName("text"):setString(CONF:getStringValue(title[i]))
		mode_node:getChildByName("text_0"):setString(CONF:getStringValue(title[i]))
		mode_node:getChildByName("selected"):addClickEventListener(function()
			if self.mode == i then return end
			btnClick(i)
			end)
		mode_node:getChildByName("normal"):addClickEventListener(function()
			if self.mode == i then return end
			btnClick(i)
			end)
	end
	btnClick(self.mode)
	setSelectedRefresh()
	local function setAddInfoList(kind,tag)
		local node_info = node_forge:getChildByName("AddInfoNode")
		self.svd2_ = require("util.ScrollViewDelegate"):create(node_info:getChildByName("list") ,cc.size(0,0), cc.size(80 ,80)) 
		self.svd2_:getScrollView():setScrollBarEnabled(false)
		self.svd2_:clear()
		selectedT = 1
		node_info:getChildByName("Image_44"):addClickEventListener(function()
			node_info:removeFromParent()
			end)
		node_info:getChildByName("Button_1"):addClickEventListener(function()
			node_info:removeFromParent()
			end)
		local function func(t)
			selectedT = t or 1
			for i=1,4 do
				node_info:getChildByName("title"..i):loadTexture("SmithingScene/ui/title_bg2.png")
				node_info:getChildByName("title"..i):setVisible(true)
			end
			if kind == infoKind.DRAWING then
				for i=2,4 do
					node_info:getChildByName("title"..i):setVisible(false)
				end
			end
			node_info:getChildByName("title"..selectedT):loadTexture("SmithingScene/ui/title_bg1.png")
		end
		local function refreshListInfo(kind)
			self.svd2_:clear()
			if kind == infoKind.EQUIP then
				local equips = player:getAllUnequipListWithType(selectedT)
				for i=1,4 do
					node_info:getChildByName("title"..i):getChildByName("text"):setString(CONF:getStringValue("Equip_type_"..i))
				end
				if Tools.isEmpty(equips) == false and #equips > 0 then
					table.sort(equips,function(a,b)
						if a.level == b.level then
							if a.quality == b.quality then
								if a.equip_id == b.equip_id then
									return a.guid > b.guid
								else
									return a.equip_id > b.equip_id
								end
							else
								return a.quality > b.quality
							end
						else
							return a.level > b.level
						end
						end)
					for k,v in ipairs(equips) do
						local can = true
						for _,id in ipairs(self.on_items) do
							if v.guid == id then
								can = false
								break
							end
						end
						if can then
							local conf = CONF.EQUIP.get(v.equip_id)
							local item_node = require("app.ExResInterface"):getInstance():FastLoad("ForgeScene/EquipNode.csb")
							item_node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
							item_node:getChildByName("icon"):loadTexture("ItemIcon/"..conf.RES_ID..".png")

							item_node:getChildByName("num"):setString("Lv."..conf.LEVEL)

							if v.strength > 0 then
								item_node:getChildByName("level_num"):setString("+"..v.strength)
								item_node:getChildByName("level_num"):setVisible(true)
							end

							local function fun1(  )
								local num = 0
								for i,v in ipairs(self.on_items) do
									if v == 0 then
										num = i
										break
									end
								end

								if num == 0 then
									tips:tips(CONF:getStringValue("forge_full"))
									return
								end
								if self.on_items[tag] == 0 then
									self.on_items[tag] = v.guid
								else
									for k,va in ipairs(self.on_items) do
										if va == 0 then
											self.on_items[k] = v.guid
											break
										end
									end
								end
								setSelectedRefresh()
								refreshListInfo(kind)
							end

							local function fun2( ... )
								if node_forge:getChildByName("info_node") then
									node_forge:getChildByName("info_node"):removeFromParent()
								end

								local info_node = require("util.ItemInfoNode"):createEquipNode(conf.ID, 10, v.strength)
								info_node:setPosition(node_forge:getChildByName("info_pos"):getPosition())
								info_node:setName("info_node")
								node_forge:addChild(info_node, SceneZOrder.kItemInfo)
							end

							self:addListener(item_node:getChildByName("background"), fun1, fun2)
							self.svd2_:addElement(item_node)
						end
					end
				end
			elseif kind == infoKind.DRAWING then
				selectedT = 1
				for i=1,4 do
					node_info:getChildByName("title"..i):getChildByName("text"):setString(CONF:getStringValue("drawing"))
				end
				local drawings = player:getAllDrawing()
				if Tools.isEmpty(drawings) == false and #drawings > 0 then
					for i,v in ipairs(drawings) do
						local conf = CONF.ITEM.get(v.id)

						local item_node = require("app.ExResInterface"):getInstance():FastLoad("ForgeScene/DrawingNode.csb")
						item_node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
						item_node:getChildByName("icon"):loadTexture("ItemIcon/"..conf.ICON_ID..".png")

						local has_num = v.num

						for i2,v2 in ipairs(self.on_items) do
							if v.id == v2 then
								has_num = has_num - 1
							end
						end

						if has_num > 0 then
							item_node:getChildByName("num"):setString(has_num)

							local function fun1(  )
								local num = 0
								for i,v in ipairs(self.on_items) do
									if v == 0 then
										num = i
										break
									end
								end

								if num == 0 then
									tips:tips(CONF:getStringValue("forge_full"))
									return
								end
								if self.on_items[tag] == 0 then
									self.on_items[tag] = v.id
								else
									for k,va in ipairs(self.on_items) do
										if va == 0 then
											self.on_items[k] = v.id
											break
										end
									end
								end
								setSelectedRefresh()
								refreshListInfo(kind)
							end

							local function fun2( ... )
								if node_forge:getChildByName("info_node") then
									node_forge:getChildByName("info_node"):removeFromParent()
								end

								local info_node = require("util.ItemInfoNode"):createItemInfoNode(conf.ID, 11)
								info_node:setPosition(node_forge:getChildByName("info_pos"):getPosition())
								info_node:setName("info_node")
								node_forge:addChild(info_node, SceneZOrder.kItemInfo)
							end

							self:addListener(item_node:getChildByName("background"), fun1, fun2)
							self.svd2_:addElement(item_node)
						end
					end
				end
			end
		end
		refreshListInfo(self.mode)
		for i=1,4 do
			node_info:getChildByName("title"..i):addClickEventListener(function()
				func(i)
				refreshListInfo(self.mode)
				end)
		end
		func()
	end
	for i=1,8 do
		local item = node_forge:getChildByName("item"..i)
		item:getChildByName("Image_48"):addClickEventListener(function()
			if self.on_items[i] == 0 then
				if node_forge:getChildByName("AddInfoNode") then
					node_forge:getChildByName("AddInfoNode"):removeFromParent()
				end
				local node = require("app.ExResInterface"):getInstance():FastLoad("SmithingScene/AddInfoNode.csb")
				node:setPosition(node_forge:getChildByName("info_pos"):getPosition())
				node:setName("AddInfoNode")
				node_forge:addChild(node,89)
				setAddInfoList(self.mode,i)
			else
				self.on_items[i] = 0
				setSelectedRefresh()
			end
			end)
	end
	node_forge:getChildByName("btn1"):addClickEventListener(function()
		if self.mode == infoKind.EQUIP then
			local equip_list = {}
			for i,v in ipairs(self.on_items) do
				if v ~= 0 then
					table.insert(equip_list, v)
				end
			end

			if #equip_list == 0 then
				tips:tips(CONF:getStringValue("forge_one"))
				return
			end
			local strData = Tools.encode("ResolveEquipReq", {
					equip_guid_list = equip_list,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_RESOLVE_EQUIP_REQ"),strData)
			setSelectedRefresh()
			gl:retainLoading()
		elseif self.mode == infoKind.DRAWING then
			local pair_list = {}
			for i,v in ipairs(self.on_items) do
				if v ~= 0 then
					local has = false
					local get_index = 0
					for i2,v2 in ipairs(pair_list) do
						if v2.key == v then
							has = true
							get_index = i2
							break
						end
					end

					if has then
						pair_list[get_index].value = pair_list[get_index].value + 1
					else
						local tt = {key = v, value = 1}
						table.insert(pair_list, tt)
					end
				end
			end

			if #pair_list == 0 then
				tips:tips(CONF:getStringValue("forge_one"))
				return
			end
			local strData = Tools.encode("ResolveBlueprintReq", {
					item_list = pair_list,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_RESOLVE_BLUEPRINT_REQ"),strData)
			gl:retainLoading()
		end
		end)
	node_forge:getChildByName("btn2"):addClickEventListener(function()
		if self.mode == infoKind.EQUIP then
			local on_num = 0
			for i,v in ipairs(self.on_items) do
				if v ~= 0 then
					on_num = on_num + 1
				end
			end

			if on_num == 8 then
				tips:tips(CONF:getStringValue("forge_full"))
				return
			end

			-- local equip_list = player:getAllUnequipListWithType(selectedT)
			local equip_list = player:getAllUnequipList()
			if equip_list == nil or #equip_list == 0 then
				tips:tips(CONF:getStringValue("ListIsEmpty"))
				return
			end

			local list = {}
			for i,v in ipairs(equip_list) do
				local has = false
				for i2,v2 in ipairs(self.on_items) do
					if v.guid == v2 then
						has = true
						break
					end
				end

				if not has then
					table.insert(list, v)
				end
			end

			local function sort( a,b )
				if a.type == b.type then
					if a.quality ~= b.quality then
						return a.quality < b.quality
					else
						if a.equip_id ~= b.equip_id then
							return a.equip_id < b.equip_id

						else
							return a.guid < b.guid
						end
					end
				else
					return a.type < b.type
				end
			end

			table.sort(list, sort)

			if #list == 0 then
				tips:tips(CONF:getStringValue("ListIsEmpty"))
				return
			end

			local num = 1
			for i,v in ipairs(self.on_items) do
				if v == 0 then
					
					if num <= #list then
						self.on_items[i] = list[num].guid
						num = num + 1
					end

				end
			end
		end
		setSelectedRefresh()
		end)
	node_forge:getChildByName("btn3"):addClickEventListener(function()
		self.on_items = {0,0,0,0,0,0,0,0}
		setSelectedRefresh()
		end)
	return node_forge
end

return ResolveNode