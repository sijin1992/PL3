local AmalgamationNode = class("AmalgamationNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local app = require("app.MyApp"):getInstance()

local infoKind = {
	EQUIP = 1,
	DRAWING = 2,
}

local diffX = 80

function AmalgamationNode:addListener( node, fun1, fun2)

	local function beginhandle()
		if self.isTouch then
			self.count = self.count and (self.count + 1) or 1
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

function AmalgamationNode:createNode()
	self.result_items = {}
	self.on_items = {0,0,0,0}
	local node = require("app.ExResInterface"):getInstance():FastLoad("SmithingScene/AmalgamationNode.csb")
	node:getChildByName("leftBg"):getChildByName("mode_1"):getChildByName("text"):setString(CONF:getStringValue("shop_mode_4"))
	node:getChildByName("leftBg"):getChildByName("mode_1"):getChildByName("text_0"):setString(CONF:getStringValue("shop_mode_4"))
	node:getChildByName("break"):setString(CONF:getStringValue("fusion_results"))
	node:getChildByName("btn1"):getChildByName("text"):setString(CONF:getStringValue("fuse"))
	node:getChildByName("btn2"):getChildByName("text"):setString(CONF:getStringValue("fast_compose"))
	node:getChildByName("btn3"):getChildByName("text"):setString(CONF:getStringValue("a_key_to_cancel"))

	local function createGemNode2( id, icon )
		local conf = CONF.GEM.get(id)

		local gemNode = require("app.ExResInterface"):getInstance():FastLoad("SmithingScene/GemNodeText.csb")--("ForgeScene/GemNode.csb")
		gemNode:getChildByName("level_num"):setString(conf.LEVEL)
		gemNode:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
		if icon then
			gemNode:getChildByName("icon"):loadTexture(icon)
		else
			gemNode:getChildByName("icon"):loadTexture("ItemIcon/"..conf.RES_ID..".png")

			gemNode:getChildByName("touch"):addClickEventListener(function ( ... )
				local info_node = require("util.ItemInfoNode"):createEquipNode(id, 9)
				info_node:setPosition(node:getChildByName("info_pos"):getPosition())
				node:addChild(info_node)
			end)
		end

		gemNode:getChildByName("shadow"):removeFromParent()
		gemNode:getChildByName("num"):removeFromParent()
		gemNode:getChildByName("pag"):setString("0%")

		return gemNode
	end

	local function resetRate( num )
	    if num*10%10 >= 5 then
	        num = math.ceil(num)
	    else
	        num = math.floor(num)
	    end
		--node:getChildByName("cg_text"):setString(tostring(num).."%")
		node:getChildByName("cg_text"):setVisible(false)--暂时不要
		node:getChildByName("sb_text"):setVisible(false)--暂时不要
		if num == 0 then
			--node:getChildByName("sb_text"):setString(tostring(0).."%")
			--node:getChildByName("cg_text"):setVisible(false)
			--node:getChildByName("sb_text"):setVisible(false)
			node:getChildByName("cg_bg"):setVisible(false)
			node:getChildByName("sb_bg"):setVisible(false)
		else
			--node:getChildByName("sb_text"):setString(tostring(100 - num).."%")
			--node:getChildByName("cg_text"):setVisible(true)
			--node:getChildByName("sb_text"):setVisible(true)
			node:getChildByName("cg_bg"):setVisible(true)
			node:getChildByName("sb_bg"):setVisible(true)
		end
	end
	local function setSelectedRefresh()
		for i,v in ipairs(self.result_items) do
			if v then
				v:removeFromParent()
				v = nil
			end
		end

		self.result_items = {}
		for i=1,4 do
			node:getChildByName("item"..i):getChildByName("FileNode_1"):setVisible(false)
			node:getChildByName("item"..i):getChildByName("add"):setVisible(true)
			node:getChildByName("item"..i):getChildByName("Image_48"):setOpacity(100)
		end
		for k,v in ipairs(self.on_items) do
			if v ~= 0 then
				node:getChildByName("item"..k):getChildByName("FileNode_1"):setVisible(true)
				node:getChildByName("item"..k):getChildByName("add"):setVisible(false)
				local item = node:getChildByName("item"..k):getChildByName("FileNode_1")
				item:getChildByName("icon"):setVisible(true)
				node:getChildByName("item"..k):getChildByName("Image_48"):setOpacity(0)

				local cfg_gem = CONF.GEM.get(v)
				item:getChildByName("num"):setString("1")
				item:getChildByName("level_num"):setString(cfg_gem.LEVEL)
				item:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..cfg_gem.QUALITY..".png")
				item:getChildByName("icon"):loadTexture("ItemIcon/"..cfg_gem.RES_ID..".png")
				item:getChildByName("level_num"):setVisible(true)
				item:getChildByName("level"):setVisible(true)
			end
		end
		local gem_list = {}
		local disabled = false
		for i,v in ipairs(self.on_items) do
			if v ~= 0 then
				disabled = true
				local has = false
				local get_index = 0
				for i2,v2 in ipairs(gem_list) do
					if v2.id == v then 
						has = true
						get_index = i2 
						break
					end
				end

				if has then
					gem_list[get_index].num = gem_list[get_index].num + 1
				else
					local tt = {id = v, num = 1}
					table.insert(gem_list, tt)
				end
			end
		end
		node:getChildByName("btn3"):setEnabled(disabled)
		if #gem_list == 0 then
			resetRate(0)
			return
		end
		if #gem_list == 1 then
			if gem_list[1].num <= 1 then
				resetRate(0)
				return
			end
		end

		local rate = player:getGemListRate(gem_list)
        if rate*10%10 >= 5 then
            rate = math.ceil(rate)
        else
            rate = math.floor(rate)
        end

		resetRate(rate)

		local type_list = {}
		local attr_list = {}
		local level_list = {}
		for i,v in ipairs(gem_list) do
			local isSameType = false
			local isSameAttr = false
			local isSameLevel = false

			local conf = CONF.GEM.get(v.id)

			for i2,v2 in ipairs(type_list) do
				if v2 == conf.TYPE then 
					isSameType = true
					break
				end
			end

			for i2,v2 in ipairs(attr_list) do
				if v2 == conf.ATTR_KEY then 
					isSameAttr = true
					break
				end
			end

			for i2,v2 in ipairs(level_list) do
				if v2 == conf.LEVEL then
					isSameLevel = true
					break
				end
			end

			if not isSameType then
				table.insert(type_list, conf.TYPE)                
			end

			if not isSameAttr then
				table.insert(attr_list, conf.ATTR_KEY)
			end

			if not isSameLevel then
				table.insert(level_list, conf.LEVEL)
			end
		end

		if #type_list == 1 then  --相同

			if #level_list == 1 then

				if #attr_list == 1 then

					local max_level = gem_list[1].id%10
					local max_id = gem_list[1].id
				

					local cg_node = createGemNode2(max_id + 1)
					cg_node:setPosition(cc.p(node:getChildByName("cg_pos"):getPosition()))
					cg_node:getChildByName("pag"):setString(rate.."%")
					node:addChild(cg_node)

					table.insert(self.result_items, cg_node)

					local x,y = node:getChildByName("sb_pos"):getPosition()

					if rate ~= 100 then
						local nodelist = {}
						for i=1,gem_list[1].num do
							if i == gem_list[1].num then

								if max_level ~= 1 then
									local sb_node = createGemNode2(max_id-1)
									sb_node:setPosition(cc.p(x + (i - 1)*diffX, y))
									node:addChild(sb_node)

									table.insert(self.result_items, sb_node)
									table.insert(nodelist, sb_node)
								end
							else
								local sb_node = createGemNode2(max_id)
								sb_node:setPosition(cc.p(x + (i - 1)*diffX, y))
								node:addChild(sb_node)

								table.insert(self.result_items, sb_node)
								table.insert(nodelist, sb_node)
							end
						end
						if #nodelist > 0 then
							local rate2 = (100 - rate) / #nodelist
						 	if rate2*10%10 >= 5 then
						        rate2 = math.ceil(rate2)
						    else
						        rate2 = math.floor(rate2)
						    end
							for _,v in ipairs(nodelist) do
								v:getChildByName("pag"):setString(rate2.."%")
								v:getChildByName("pag"):setTextColor(cc.c4b(255,145,136,255))
							end
						end
					end

				else
					local max_level = gem_list[1].id%10

					local cg_node = createGemNode2(gem_list[1].id + 1, "ForgeScene/ui/gem_black_"..CONF.GEM.get(gem_list[1].id).TYPE..".png")
					cg_node:setPosition(cc.p(node:getChildByName("cg_pos"):getPosition()))
					cg_node:getChildByName("pag"):setString(rate.."%")

					local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
					sprite:setPosition(cc.p(cg_node:getChildByName("icon"):getPosition()))
					sprite:setScale(0.7)
					cg_node:addChild(sprite)

					node:addChild(cg_node)

					table.insert(self.result_items, cg_node)

					local x,y = node:getChildByName("sb_pos"):getPosition()

					local gem_num = 0
					for i,v in ipairs(gem_list) do
						gem_num = gem_num + v.num
					end

					if rate ~= 100 then
						local nodelist = {}
						for i=1,gem_num do
							if i == gem_num then

								if max_level ~= 1 then
									local sb_node = createGemNode2(gem_list[1].id-1, "ForgeScene/ui/gem_black_"..CONF.GEM.get(gem_list[1].id).TYPE..".png")
									sb_node:setPosition(cc.p(x + (i - 1)*diffX, y))
									node:addChild(sb_node)

									local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
									sprite:setPosition(cc.p(cg_node:getChildByName("icon"):getPosition()))
									sprite:setScale(0.7)
									sb_node:addChild(sprite)

									table.insert(self.result_items, sb_node)
									table.insert(nodelist, sb_node)
								end
							else
								local sb_node = createGemNode2(gem_list[1].id, "ForgeScene/ui/gem_black_"..CONF.GEM.get(gem_list[1].id).TYPE..".png")
								sb_node:setPosition(cc.p(x + (i - 1)*diffX, y))
								node:addChild(sb_node)

								local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
								sprite:setPosition(cc.p(cg_node:getChildByName("icon"):getPosition()))
								sprite:setScale(0.7)
								sb_node:addChild(sprite)

								table.insert(self.result_items, sb_node)
								table.insert(nodelist, sb_node)
							end
						end
						if #nodelist > 0 then
							local rate2 = (100 - rate) / #nodelist
						 	if rate2*10%10 >= 5 then
						        rate2 = math.ceil(rate2)
						    else
						        rate2 = math.floor(rate2)
						    end
							for _,v in ipairs(nodelist) do
								v:getChildByName("pag"):setString(rate2.."%")
								v:getChildByName("pag"):setTextColor(cc.c4b(255,145,136,255))
							end
						end
					end

				end
			else

				if #attr_list == 1 then
					local max_level = 0
					local max_id = 0

					for i,v in ipairs(gem_list) do
						if v.id%10 > max_level then
							max_level = v.id%10
							max_id = v.id
						elseif v.id%10 == max_level then
							if CONF.GEM.get(v.id).RATE > CONF.GEM.get(max_id).RATE then
								max_id = v.id 
							end
						end

					end

					local cg_node = createGemNode2(max_id + 1)
					cg_node:setPosition(cc.p(node:getChildByName("cg_pos"):getPosition()))
					cg_node:getChildByName("pag"):setString(rate.."%")
					node:addChild(cg_node)

					table.insert(self.result_items, cg_node)

					local x,y = node:getChildByName("sb_pos"):getPosition()

					if rate ~= 100 then
						local rate_num = 100 - rate
						local rate_num2 =  math.floor(rate * rate_num / 100 + 0.5)
	                    rate_num =  math.floor(rate_num * rate_num / 100 + 0.5)
	                    

						local sb_node = createGemNode2(max_id)
						sb_node:setPosition(cc.p(x, y))
						sb_node:getChildByName("pag"):setTextColor(cc.c4b(255,145,136,255))
						sb_node:getChildByName("pag"):setString(rate_num.."%")
						node:addChild(sb_node)

						table.insert(self.result_items, sb_node)

						local sb_node2 = createGemNode2(max_id-1)
						--sb_node2:setPosition(cc.p(x + diffX*3, y))
						sb_node2:setPosition(cc.p(x + diffX, y))
						sb_node2:getChildByName("pag"):setTextColor(cc.c4b(255,145,136,255))
						sb_node2:getChildByName("pag"):setString(rate_num2.."%")
						node:addChild(sb_node2)

						table.insert(self.result_items, sb_node2)

						--[[local orNode = require("app.ExResInterface"):getInstance():FastLoad("ForgeScene/OrNode.csb")

	                    local rate_num 
	                    if rate*10%10 >= 5 then
	                        rate_num = math.ceil(rate)
	                    else
	                        rate_num = math.floor(rate)
	                    end

						orNode:getChildByName("text_1"):setString(rate_num.."%")
						orNode:getChildByName("text_2"):setString((100 - rate_num).."%")
						orNode:setPosition(cc.p(x + diffX*1.5, y))
						node:addChild(orNode)

						table.insert(self.result_items, orNode)]]
						
					end


				else

					local max_level = 0
					local max_id = 0

					for i,v in ipairs(gem_list) do
						if v.id%10 > max_level then
							max_level = v.id%10
							max_id = v.id
						elseif v.id%10 == max_level then
							if CONF.GEM.get(v.id).RATE > CONF.GEM.get(max_id).RATE then
								max_id = v.id 
							end
						end

					end

					local cg_node = createGemNode2(max_id + 1, "ForgeScene/ui/gem_black_"..CONF.GEM.get(max_id).TYPE..".png")
					cg_node:setPosition(cc.p(node:getChildByName("cg_pos"):getPosition()))
					cg_node:getChildByName("pag"):setString(rate.."%")

					local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
					sprite:setPosition(cc.p(cg_node:getChildByName("icon"):getPosition()))
					sprite:setScale(0.7)
					cg_node:addChild(sprite)

					node:addChild(cg_node)

					table.insert(self.result_items, cg_node)

					local x,y = node:getChildByName("sb_pos"):getPosition()

					if rate ~= 100 then
						local rate_num = 100 - rate						
						local rate_num2 = math.floor(rate * rate_num / 100 + 0.5)
	                    rate_num =  math.floor(rate_num * rate_num / 100 + 0.5)
	                    

						local sb_node = createGemNode2(max_id, "ForgeScene/ui/gem_black_"..CONF.GEM.get(max_id).TYPE..".png")
						sb_node:setPosition(cc.p(x, y))
						sb_node:getChildByName("pag"):setTextColor(cc.c4b(255,145,136,255))
						sb_node:getChildByName("pag"):setString(rate_num.."%")

						node:addChild(sb_node)

						local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
						sprite:setPosition(cc.p(cg_node:getChildByName("icon"):getPosition()))
						sprite:setScale(0.7)
						sb_node:addChild(sprite)

						table.insert(self.result_items, sb_node)

						local sb_node = createGemNode2(max_id-1, "ForgeScene/ui/gem_black_"..CONF.GEM.get(max_id-1).TYPE..".png")
						--sb_node:setPosition(cc.p(x + diffX*3, y))
						sb_node:setPosition(cc.p(x + diffX, y))
						sb_node:getChildByName("pag"):setTextColor(cc.c4b(255,145,136,255))
						sb_node:getChildByName("pag"):setString(rate_num2.."%")

						node:addChild(sb_node)

						local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
						sprite:setPosition(cc.p(cg_node:getChildByName("icon"):getPosition()))
						sprite:setScale(0.7)
						sb_node:addChild(sprite)

						table.insert(self.result_items, sb_node)

						--[[local orNode = require("app.ExResInterface"):getInstance():FastLoad("ForgeScene/OrNode.csb")

	                    local rate_num 
	                    if rate*10%10 >= 5 then
	                        rate_num = math.ceil(rate)
	                    else
	                        rate_num = math.floor(rate)
	                    end

						orNode:getChildByName("text_1"):setString(rate_num.."%")
						orNode:getChildByName("text_2"):setString((100 - rate_num).."%")
						orNode:setPosition(cc.p(x + diffX*1.5, y))
						node:addChild(orNode)

						table.insert(self.result_items, orNode)]]
					end

				end

			end
		else  -- 不同
			if #level_list == 1 then

				local max_level = 0
				local max_id = 0
				local has_same = false

				for i,v in ipairs(gem_list) do
					if v.id%10 > max_level then
						max_level = v.id%10
						max_id = v.id
					elseif v.id%10 == max_level then

						if CONF.GEM.get(v.id).TYPE ~= CONF.GEM.get(max_id).TYPE then
							has_same = true
						end

						if CONF.GEM.get(v.id).RATE > CONF.GEM.get(max_id).RATE then
							max_id = v.id    
						end
					end

				end

				local cg_node = createGemNode2(max_id + 1, "ForgeScene/ui/gem_black_"..CONF.GEM.get(max_id).TYPE..".png")
				cg_node:setPosition(cc.p(node:getChildByName("cg_pos"):getPosition()))
				cg_node:getChildByName("pag"):setString(rate.."%")


				local label = cc.Label:createWithTTF(CONF:getStringValue("random_gem"), "fonts/cuyabra.ttf", 16)
				label:setPosition(cc.p(cg_node:getChildByName("icon"):getPosition()))
				cg_node:addChild(label)

			
				local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
				sprite:setPosition(cc.p(cg_node:getChildByName("icon"):getPosition()))
				sprite:setScale(0.7)
				cg_node:addChild(sprite)

				cg_node:getChildByName("icon"):removeFromParent()
				

				node:addChild(cg_node)

				table.insert(self.result_items, cg_node)

				local x,y = node:getChildByName("sb_pos"):getPosition()

				local gem_num = 0
				for i,v in ipairs(gem_list) do
					gem_num = gem_num + v.num
				end

				if rate ~= 100 then
					local nodelist = {}
					for i=1,gem_num do
						if i == gem_num then

							if max_level ~= 1 then
								local sb_node = createGemNode2(max_id-1, "LotteryScene/ui/icon_wh.png")
								sb_node:setPosition(cc.p(x + (i - 1)*diffX, y))
								node:addChild(sb_node)

								local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
								sprite:setPosition(cc.p(sb_node:getChildByName("icon"):getPosition()))
								sprite:setScale(0.7)
								sb_node:addChild(sprite)

								local label = cc.Label:createWithTTF(CONF:getStringValue("random_gem"), "fonts/cuyabra.ttf", 16)
								label:setPosition(cc.p(sb_node:getChildByName("icon"):getPosition()))
								sb_node:addChild(label)

								sb_node:getChildByName("icon"):removeFromParent()

								table.insert(self.result_items, sb_node)
								table.insert(nodelist, sb_node)
							end
						else
							local sb_node = createGemNode2(max_id, "LotteryScene/ui/icon_wh.png")
							sb_node:setPosition(cc.p(x + (i - 1)*diffX, y))
							node:addChild(sb_node)

							local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
							sprite:setPosition(cc.p(sb_node:getChildByName("icon"):getPosition()))
							sprite:setScale(0.7)
							sb_node:addChild(sprite)

							local label = cc.Label:createWithTTF(CONF:getStringValue("random_gem"), "fonts/cuyabra.ttf", 16)
							label:setPosition(cc.p(sb_node:getChildByName("icon"):getPosition()))
							sb_node:addChild(label)

							sb_node:getChildByName("icon"):removeFromParent()

							table.insert(self.result_items, sb_node)
							table.insert(nodelist, sb_node)
						end
					end
					if #nodelist > 0 then
						local rate2 = (100 - rate) / #nodelist
					 	if rate2*10%10 >= 5 then
					        rate2 = math.ceil(rate2)
					    else
					        rate2 = math.floor(rate2)
					    end
						for _,v in ipairs(nodelist) do
							v:getChildByName("pag"):setString(rate2.."%")
							v:getChildByName("pag"):setTextColor(cc.c4b(255,145,136,255))
						end
					end
				end
			else
				local max_level = 0
				local max_id = 0
				local has_same = false

				for i,v in ipairs(gem_list) do
					if v.id%10 > max_level then
						max_level = v.id%10
						max_id = v.id
					elseif v.id%10 == max_level then

						if CONF.GEM.get(v.id).TYPE ~= CONF.GEM.get(max_id).TYPE then
							has_same = true
						end

						if CONF.GEM.get(v.id).RATE > CONF.GEM.get(max_id).RATE then
							max_id = v.id 
						end
					end

				end

				local cg_node = createGemNode2(max_id + 1, "ForgeScene/ui/gem_black_"..CONF.GEM.get(max_id).TYPE..".png")
				cg_node:setPosition(cc.p(node:getChildByName("cg_pos"):getPosition()))
				cg_node:getChildByName("pag"):setString(rate.."%")

				-- if has_same then

					local label = cc.Label:createWithTTF(CONF:getStringValue("random_gem"), "fonts/cuyabra.ttf", 16)
					label:setPosition(cc.p(cg_node:getChildByName("icon"):getPosition()))
					cg_node:addChild(label)

				
					local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
					sprite:setPosition(cc.p(cg_node:getChildByName("icon"):getPosition()))
					sprite:setScale(0.7)
					cg_node:addChild(sprite)

					cg_node:getChildByName("icon"):removeFromParent()
				-- end

				node:addChild(cg_node)

				table.insert(self.result_items, cg_node)

				local x,y = node:getChildByName("sb_pos"):getPosition()

				local gem_num = 0
				for i,v in ipairs(gem_list) do
					gem_num = gem_num + v.num
				end

				if rate ~= 100 then
					local rate_num = 100 - rate
					local rate_num2 =  math.floor(rate * rate_num / 100 + 0.5)
                    rate_num =  math.floor(rate_num * rate_num / 100 + 0.5)                    

					local sb_node = createGemNode2(max_id, "LotteryScene/ui/icon_wh.png")
					sb_node:setPosition(cc.p(x , y))
					sb_node:getChildByName("pag"):setTextColor(cc.c4b(255,145,136,255))
					sb_node:getChildByName("pag"):setString(rate_num.."%")
					node:addChild(sb_node)

					local sprite = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
					sprite:setPosition(cc.p(sb_node:getChildByName("icon"):getPosition()))
					sprite:setScale(0.7)
					sb_node:addChild(sprite)

					local label = cc.Label:createWithTTF(CONF:getStringValue("random_gem"), "fonts/cuyabra.ttf", 16)
					label:setPosition(cc.p(sb_node:getChildByName("icon"):getPosition()))
					sb_node:addChild(label)

					sb_node:getChildByName("icon"):removeFromParent()

					table.insert(self.result_items, sb_node)

					local sb_node2 = createGemNode2(max_id-1, "ForgeScene/ui/gem_black_"..CONF.GEM.get(max_id).TYPE..".png")
					--sb_node2:setPosition(cc.p(x + diffX*3, y))
					sb_node2:setPosition(cc.p(x + diffX, y))
					sb_node2:getChildByName("pag"):setTextColor(cc.c4b(255,145,136,255))
					sb_node2:getChildByName("pag"):setString(rate_num2.."%")
					node:addChild(sb_node2)

					if has_same then
						local sprite2 = cc.Sprite:create("LotteryScene/ui/icon_wh.png")
						sprite2:setPosition(cc.p(sb_node2:getChildByName("icon"):getPosition()))
						sprite2:setScale(0.7)
						sb_node2:addChild(sprite2)

						local label2 = cc.Label:createWithTTF(CONF:getStringValue("random_gem"), "fonts/cuyabra.ttf", 16)
						label2:setPosition(cc.p(sb_node2:getChildByName("icon"):getPosition()))
						sb_node2:addChild(label2)

						sb_node2:getChildByName("icon"):removeFromParent()
					end

					table.insert(self.result_items, sb_node2)

					--[[local orNode = require("app.ExResInterface"):getInstance():FastLoad("ForgeScene/OrNode.csb")

                    local rate_num 
                    if rate*10%10 >= 5 then
                        rate_num = math.ceil(rate)
                    else
                        rate_num = math.floor(rate)
                    end

					orNode:getChildByName("text_1"):setString(rate_num.."%")
					orNode:getChildByName("text_2"):setString((100 - rate_num).."%")
					orNode:setPosition(cc.p(x + diffX*1.5, y))
					node:addChild(orNode)

					table.insert(self.result_items, orNode)]]
				end

			end
		end
	end
	local function setAddInfoList(tag)
		local node_info = node:getChildByName("AddInfoNode")
		self.svd2_ = require("util.ScrollViewDelegate"):create(node_info:getChildByName("list") ,cc.size(0,0), cc.size(80 ,80)) 
		self.svd2_:getScrollView():setScrollBarEnabled(true)
		self.svd2_:getScrollView():setScrollBarWidth(15)
		self.svd2_:getScrollView():setScrollBarColor(cc.c4b(51,231,231,255))
		self.svd2_:clear()
		node_info:getChildByName("title1"):getChildByName("text"):setString(CONF:getStringValue("shop_mode_4"))
		node_info:getChildByName("Image_44"):addClickEventListener(function()
			node_info:removeFromParent()
			end)
		node_info:getChildByName("Button_1"):addClickEventListener(function()
			node_info:removeFromParent()
			end)
		for i=1,4 do
			node_info:getChildByName("title"..i):loadTexture("SmithingScene/ui/title_bg2.png")
			node_info:getChildByName("title"..i):setVisible(false)
		end
		node_info:getChildByName("title1"):setVisible(true)
		node_info:getChildByName("title1"):loadTexture("SmithingScene/ui/title_bg1.png")

		local function refreshListInfo()
			self.svd2_:clear()
			local list = player:getAllUnGemList()
			local function sort( a,b )
				local confA = CONF.GEM.get(a.id)
				local confB = CONF.GEM.get(b.id)

				if confA.LEVEL ~= confB.LEVEL then

					return confA.LEVEL > confB.LEVEL

				else
					if a.id ~= b.id then
						return a.id > b.id 
					end
				end
			end

			table.sort( list, sort )
			if list then
				for i,v in ipairs(list) do
					local conf = CONF.GEM.get(v.id)

					local item_node = require("app.ExResInterface"):getInstance():FastLoad("ForgeScene/GemNode.csb")
					item_node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
					item_node:getChildByName("icon"):loadTexture("ItemIcon/"..conf.RES_ID..".png")
					item_node:getChildByName("level_num"):setString(conf.LEVEL)

					local has_num = v.num 
					for ii,vv in ipairs(self.on_items) do
						if vv == v.id then
							has_num = has_num - 1
						end
					end

					item_node:getChildByName("num"):setString(has_num)

					if has_num > 0 then

						local function fun1(  )

							local num = 0
							for i,v in ipairs(self.on_items) do
								if i <= 4 then
									if v == 0 then
										num = i
										break
									end
								end
							end

							if num == 0 then
								tips:tips(CONF:getStringValue("forge_full"))
								return
							end

							local check = CONF.GEM.check(v.id+1)
							if check then
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

								has_num = has_num - 1
								print("@@@@@@@@@@@@@",has_num)
								if has_num > 0 then
									print("@@@@@@@@@@@@@ has_num",has_num)
									item_node:getChildByName("num"):setString(has_num)
								else
									print("@@@@@@@@@@@@@ refreshListInfo")
									refreshListInfo()
								end

							else
								tips:tips(CONF:getStringValue("max_gem"))
							end
						end

						local function fun2( ... )
							if node:getChildByName("info_node") then
								node:getChildByName("info_node"):removeFromParent()
							end

							local info_node = require("util.ItemInfoNode"):createEquipNode(conf.ID, 9)
							info_node:setPosition(node:getChildByName("info_pos"):getPosition())
							info_node:setName("info_node")
							node:addChild(info_node, SceneZOrder.kItemInfo)
						end

						self:addListener(item_node:getChildByName("background"), fun1, fun2)
						self.svd2_:addElement(item_node)
					end
				end
			end
		end
		refreshListInfo()
	end
	for i=1,4 do
		local item = node:getChildByName("item"..i)
		item:getChildByName("Image_48"):addClickEventListener(function()
			if self.on_items[i] == 0 then
				if node:getChildByName("AddInfoNode") then
					node:getChildByName("AddInfoNode"):removeFromParent()
				end
				local info_node = require("app.ExResInterface"):getInstance():FastLoad("SmithingScene/AddInfoNode.csb")
				info_node:setPosition(node:getChildByName("info_pos"):getPosition())
				info_node:setName("AddInfoNode")
				node:addChild(info_node,89)
				setAddInfoList(i)
			else
				self.on_items[i] = 0
				setSelectedRefresh()
			end
			end)
	end
	node:getChildByName("btn1"):addClickEventListener(function()
		local gem_list = {}
		for i,v in ipairs(self.on_items) do
			if v ~= 0 then
				local has = false
				local get_index = 0
				for i2,v2 in ipairs(gem_list) do
					if v2.id == v then
						has = true
						get_index = i2
						break
					end
				end

				if has then
					gem_list[get_index].num = gem_list[get_index].num + 1
				else
					local tt = {id = v, num = 1}
					table.insert(gem_list, tt)
				end
			end
		end

		local num = 0
		for i,v in ipairs(gem_list) do
			num = num + v.num
		end

		if #gem_list == 0 then
			tips:tips(CONF:getStringValue("forge_gem_num"))
			return
		elseif num < 2 then
			tips:tips(CONF:getStringValue("forge_gem_num"))
			return
		end
		local strData = Tools.encode("MixGemReq", {
				gem_list = gem_list,
				count = 1,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GEM_MIX_REQ"),strData)

			gl:retainLoading()
		end)
	node:getChildByName("btn2"):addClickEventListener(function()
		local gem_list = {}
		for i,v in ipairs(self.on_items) do
			if v ~= 0 then
				local has = false
				local get_index = 0
				for i2,v2 in ipairs(gem_list) do
					if v2.id == v then
						has = true
						get_index = i2
						break
					end
				end

				if has then
					gem_list[get_index].num = gem_list[get_index].num + 1
				else
					local tt = {id = v, num = 1}
					table.insert(gem_list, tt)
				end
			end
		end

		local num = 0
		for i,v in ipairs(gem_list) do
			num = num + v.num
		end

		if #gem_list == 0 then
			tips:tips(CONF:getStringValue("forge_gem_num"))
			return
		elseif num < 2 then
			tips:tips(CONF:getStringValue("forge_gem_num"))
			return
		end
		app:addView2Top("PlanetScene/PlanetSpyMakeSureLayer",{from='ForgeScene',items=self.on_items})
		end)
	node:getChildByName("btn3"):addClickEventListener(function()
		self.on_items = {0,0,0,0}
		setSelectedRefresh()
		end)
	setSelectedRefresh()
	return node
end

return AmalgamationNode