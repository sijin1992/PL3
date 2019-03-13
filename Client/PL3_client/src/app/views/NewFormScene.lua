local animManager = require("app.AnimManager"):getInstance()

local g_player = require("app.Player"):getInstance()

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local Bit = require "Bit"

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local messageBox = require("util.MessageBox"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local NewFormScene = class("NewFormScene", cc.load("mvc").ViewBase)

NewFormScene.RESOURCE_FILENAME = "FormScene/NewFormScene.csb"

NewFormScene.NEED_ADJUST_POSITION = true

NewFormScene.RESOURCE_BINDING = {
	["save"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["fight"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local diff = 250

local piece_width = 530.5

local schedulerEntry = nil

function NewFormScene:OnBtnClick(event)

	printInfo(event.name)
	if event.name == "ended" then

		if event.target:getName() == "save" then
			playEffectSound("sound/system/click.mp3")

			if self.test_ship or self.guide_ship then
				return
			end

			local num = 0
			for i,v in ipairs(self.forms) do
				if v~=0 then
					num = num + 1 
				end
			end

			if num > CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM then 
				tips:tips(CONF:getStringValue("lineup max five ships"))
				return
			elseif num == 0 then
				tips:tips(CONF:getStringValue("lineup no ships on"))

				return
			end

			-- for i,v in ipairs(self.forms) do
			-- 	if v~=0 then
			-- 		local ship_info = player:getShipByGUID(v)
			-- 		if ship_info.durable < (Tools.getShipMaxDurable(ship_info)/10) then
			-- 			tips:tips(CONF:getStringValue("durable_not_enought"))
			-- 			return
			-- 		end
			-- 	end
			-- end

			if self.data_.from == "trial" then

				local strData = Tools.encode("TrialAreaReq", {
					type = 2,
					area_id = self.data_.index,
					lineup = self.forms
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

				gl:retainLoading()	

			else

				local strData = Tools.encode("ChangeLineupReq", {
						type = 1,
						lineup = self.forms
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)

				gl:retainLoading()

			end

		end

		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")

			if self.test_ship or self.guide_ship then
				return
			end

			for i=1,9 do
				self:resetFormByIndex(i, 0)
			end

			-- animManager:runAnimOnceByCSB(self:getResourceNode(), "FormScene/FormScene.csb", "outro", function ()
				self:getApp():popView()
			-- end)

			
		end

		if event.target:getName() == "fight" then
			playEffectSound("sound/system/click.mp3")
			if self.test_ship or self.guide_ship then
				return
			end

			local num = 0
			for i,v in ipairs(self.forms) do
				if v~=0 then
					num = num + 1 
				end
			end

			if num > CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM then 
				tips:tips(CONF:getStringValue("lineup max five ships"))
				return
			elseif num == 0 then
				tips:tips(CONF:getStringValue("lineup no ships on"))

				return
			end

			for i,v in ipairs(self.forms) do
				if v~=0 then
					local ship_info = player:getShipByGUID(v)
					if ship_info.durable < (Tools.getShipMaxDurable(ship_info)/10) then
						tips:tips(CONF:getStringValue("durable_not_enought"))
						return
					end

					if Bit:has(ship_info.status, 2) == true then
						tips:tips(CONF:getStringValue("has_fix_ship"))
						return
					end
				end
			end

			if self.data_.from == "trial_start" then	

				local function func( ... )
					local strData = Tools.encode("TrialAreaReq", {
						type = 1,
						area_id = self.data_.index,
						lineup = self.forms
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)
					
					gl:retainLoading()
				end

				messageBox:reset(CONF.STRING.get("start tips").VALUE, func)

			elseif self.data_.from == "trial_fight" then

				if player:getStrength() < CONF.TRIAL_LEVEL.get(self.data_.id).STRENGTH then
					-- tips:tips(CONF:getStringValue("strength_not_enought"))

					self:getApp():addView2Top("CityScene/AddStrenthLayer")
					return
				end 

				local strData = Tools.encode("TrialAreaReq", {
						type = 2,
						area_id = self.data_.index,
						lineup = self.forms
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

				gl:retainLoading()

			elseif self.data_.from == "slave" then

				local strData = Tools.encode("SlaveAttackReq", {
						type = self.data_.type,
						user_name = self.data_.user_name,
						lineup = self.forms
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_ATTACK_REQ"),strData)

				gl:retainLoading()
			else

				if player:getStrength() < CONF.CHECKPOINT.get(self.data_.id).STRENGTH then
					-- tips:tips(CONF:getStringValue("strength_not_enought"))

					self:getApp():addView2Top("CityScene/AddStrenthLayer")
					return
				end 

				local strData = Tools.encode("ChangeLineupReq", {
						type = 1,
						lineup = self.forms
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)

				gl:retainLoading()
				
			end

		end
	end

   
end

function NewFormScene:onCreate(data)
	self.data_ = data
end

function NewFormScene:onEnter()
	
	printInfo("NewFormScene:onEnter()")
end

function NewFormScene:onExit()
	
	printInfo("NewFormScene:onExit()")

end

function NewFormScene:resetList()
	
	self:addListItem(self.svd:getScrollView():getTag())

	self:resetShipNum()
end

function NewFormScene:resetShipNum( ... )

	local function check( guid )
		local flag = false
		for i,v in ipairs(self.forms) do
			if v == guid then
				flag = true
				break
			end
		end

		return flag
	end

	for i=1,4 do

		local ship_list
		if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
			ship_list = player:getTrialShipByType(self.data_.index, i)
		else
			ship_list = player:getShipsByType(i)
		end

		local num = 0
		for ii,vv in ipairs(ship_list) do
			if not check(vv.guid) then
				num = num + 1
			end
		end
		self:getResourceNode():getChildByName("piece_"..i):getChildByName("ship_num"):setString(num.."/"..#ship_list)
	end
end

function NewFormScene:addIconListener(node)
 

	local function onTouchBegan(touch, event)
		
		local target = event:getCurrentTarget()

		local ln = self.svd:getScrollView():convertToNodeSpace(touch:getLocation())

		local sv_s = self.svd:getScrollView():getContentSize()
		local sv_rect = cc.rect(0, 0, sv_s.width, sv_s.height)

		if cc.rectContainsPoint(sv_rect, ln) then
		
			local locationInNode = target:convertToNodeSpace(touch:getLocation())
			local s = target:getContentSize()

			local rect = cc.rect(0, 0, s.width, s.height)
			
			if cc.rectContainsPoint(rect, locationInNode) then

				print(string.format("sprite began... x = %f, y = %f", locationInNode.x, locationInNode.y))

				-- if self.test_ship then
					-- self.test_ship:removeFromParent()
					-- self.test_ship = nil

					-- guideManager:addGuideStep(907)

				-- 	self.test_ship:setOpacity(0)
				-- end


				local index = target:getTag()

				local guid = target:getParent():getTag()

				local ship = g_player:getShipByGUID(guid)
				self.long_ship = guid

				--self.shipsList_:resetElement(index, self:createNormal(index,ship))
				
				self.curSelectShip_ = self:createSelectShipNode(ship)

				local pos = cc.pAdd(touch:getLocation(),cc.p(-s.width*0.5,s.height*0.5))

				self.curSelectShip_:setPosition(pos)

				self.curSelectShip_:setVisible(false)

				self:addChild(self.curSelectShip_)

				-----
				self.isTouch = true
				

				return true
			end

		end

		return false
	end

	local function onTouchMoved(touch, event)

		local target = event:getCurrentTarget()
		local s = target:getContentSize()

		local pos = cc.pAdd(touch:getLocation(),cc.p(-s.width*0.5,s.height*0.5))

		self.curSelectShip_:setVisible(true)
		if self.curSelectShip_ then
			self.curSelectShip_:setPosition(pos)
		end

		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			self.isMoved = true
		end

		local in_form = false
		for i=1,9 do

			local form = self:getResourceNode():getChildByName(string.format("point_%d", i))
			local posInNode = form:convertToNodeSpace(touch:getLocation())
			local s = form:getContentSize()

			local rect = cc.rect(0, 0, s.width, s.height)

			if cc.rectContainsPoint(rect, posInNode) then
				-- if self.forms[i] == 0 then
					self.faguang:setPosition(cc.p(form:getPositionX() - 2, form:getPositionY() - 2))

					in_form = true
				-- end
			end
		end

		if not in_form then
			self.faguang:setPositionX(-10000)
		end

	end

	local function onTouchEnded(touch, event)
		print("onTouchEnded")

		self.faguang:setPositionX(-10000)

		local target = event:getCurrentTarget()

		local rn = self:getResourceNode()

		local index = target:getTag()
		local guid = target:getParent():getTag()
		local ship = g_player:getShipByGUID(guid)

		if self.curSelectShip_ then

			--self.shipsList_:resetElement(index, self:createNormal(index,ship))

			self.curSelectShip_:removeFromParent()
			
			self.curSelectShip_ = nil
		end

		self.isTouch = false


		if self.isMoved then
			self.isMoved = false

			for i=1,9 do

				local form = rn:getChildByName(string.format("point_%d", i))
				local posInNode = form:convertToNodeSpace(touch:getLocation())
				local s = form:getContentSize()

				local rect = cc.rect(0, 0, s.width, s.height)

				if cc.rectContainsPoint(rect, posInNode) then

					if self.data_.from == "trial" or self.data_.from == "trial_fight" then
						if player:getTrialShipHpByGUID(self.data_.index, guid) == 0 then
							tips:tips(CONF:getStringValue("ship hp zero"))
							return
						end
					end

					if self.test_ship then
						if i ~= 4 then
							self.test_ship:setOpacity(255)
							return
						else
							self:removeAction1()
							self:addAction2()
						end
					end

					if self.forms[i] == 0 then
						local num = 0
						for i,v in ipairs(self.forms) do
							if v~=0 then
								num = num + 1 
							end
						end

						local airship_num = CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM
						if num >= airship_num then

							if airship_num == 5 then
								tips:tips(CONF:getStringValue("lineup max five ships"))
								return
							else

								local add_level = 0

								for i,v in ipairs(CONF.BUILDING_14.getIDList()) do
									if CONF.BUILDING_14.get(v).AIRSHIP_NUM > airship_num then
										add_level = i
										break
									end
								end

								tips:tips(CONF:getStringValue("BuildingName_14")..add_level..CONF:getStringValue("level_2").. CONF:getStringValue("add_form_num"))
								return
							end
						else
							if ship.durable < Tools.getShipMaxDurable(ship)/10 then
								tips:tips(CONF:getStringValue("durable_not_enought"))
								return
							else
								if Bit:has(ship.status, 2) == true then
									tips:tips(CONF:getStringValue("repair_now"))
									return
								elseif  Bit:has(ship.status, 4) == true then
									if self.data_.from ~= "trial_fight"  and self.data_.from ~= "continue" and self.data_.from ~= "special" and self.data_.from ~= "trial" then
										tips:tips(CONF:getStringValue("chuzhen_tips"))
										return
									else
										tips:tips(CONF:getStringValue("up_form"))
										self:resetForms(i, guid)
									end
								else
									tips:tips(CONF:getStringValue("up_form"))
									self:resetForms(i, guid)
								end
							end
						end
					else
						if ship.durable < Tools.getShipMaxDurable(ship)/10 then
							tips:tips(CONF:getStringValue("durable_not_enought"))
							return
						else

							if Bit:has(ship.status, 2) == true then
								tips:tips(CONF:getStringValue("repair_now"))
								return
							elseif  Bit:has(ship.status, 4) == true then
								if self.data_.from ~= "trial_fight"  and self.data_.from ~= "continue" and self.data_.from ~= "special" and self.data_.from ~= "trial" then
									tips:tips(CONF:getStringValue("chuzhen_tips"))
									return
								else
									tips:tips(CONF:getStringValue("up_form"))
									self:resetForms(i, guid)
								end
							else
								tips:tips(CONF:getStringValue("up_form"))
								self:resetForms(i, guid)
							end
						end
					end

					self:resetFormByIndex(i, guid)

					self:resetList()
					self:resetNumInfo()
					break

				else
					if self.test_ship then
						self.test_ship:setOpacity(255)
					end

				end
			end
		else

			if self.test_ship then
				return
			end

			local node = require("app.views.StarOccupationLayer.FormShipInfoNode"):create()
			node:init(self, self.long_ship)
			node:setPosition(cc.p(rn:getChildByName("info_pos_1"):getPosition()))
			node:setLocalZOrder(20)
			rn:addChild(node)

			target:getParent():getChildByName("light"):setVisible(true)
			self.light_ = target:getParent():getChildByName("light")
			
		end
	   
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

function NewFormScene:addFormListener(node)


	local function onTouchBegan(touch, event)

		if self.test_ship then
			return false
		end
		
		local target = event:getCurrentTarget()
		
		local locationInNode = target:convertToNodeSpace(touch:getLocation())
		local s = target:getContentSize()

		local rect = cc.rect(0, 0, s.width, s.height)
		
		if cc.rectContainsPoint(rect, locationInNode) then

			local rn = self:getResourceNode()

			local index = target:getTag() - 100
			local formShip = rn:getChildByName(string.format("form_ship_%d", index))
			if formShip == nil then
				return false
			end

			if self.guide_ship then
				if index ~= 1 then
					return false
				else
					-- self.guide_ship:setOpacity(0)
				end
			end

			local guid = formShip:getTag()
			assert(guid>0,"error")
			self.long_ship = guid

			local ship = g_player:getShipByGUID(guid)
			self.curSelectShip_ = self:createSelectShipNode(ship)
			local pos = cc.pAdd(touch:getLocation(),cc.p(-s.width*0.5,s.height*0.5))
			self.curSelectShip_:setPosition(pos)
			self:addChild(self.curSelectShip_)
			self.curSelectShip_:setVisible(false)

			self.isTouch = true

			return true
		end

		return false
	end

	local function onTouchMoved(touch, event)

		local target = event:getCurrentTarget()
		local s = target:getContentSize()

		local pos = cc.pAdd(touch:getLocation(),cc.p(-s.width*0.5,s.height*0.5))

		if self.curSelectShip_ then
			self.curSelectShip_:setPosition(pos)
		end

		self.curSelectShip_:setVisible(true)

		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			self.isMoved = true
		end

		local in_form = false
		for i=1,9 do

			local form = self:getResourceNode():getChildByName(string.format("point_%d", i))
			local posInNode = form:convertToNodeSpace(touch:getLocation())
			local s = form:getContentSize()

			local rect = cc.rect(0, 0, s.width, s.height)

			if cc.rectContainsPoint(rect, posInNode) then
				-- if self.forms[i] == 0 then
					self.faguang:setPosition(cc.p(form:getPositionX() - 2, form:getPositionY() - 2))

					in_form = true
				-- end
			
			end
		end

		if not in_form then
			self.faguang:setPositionX(-10000)
		end

	end

	local function onTouchEnded(touch, event)

		self.faguang:setPositionX(-10000)

		local target = event:getCurrentTarget()

		if self.curSelectShip_ then

			self.curSelectShip_:removeFromParent()
			
			self.curSelectShip_ = nil
		end

		local rn = self:getResourceNode()

		local list = rn:getChildByName("touch")

		local locationInList = list:convertToNodeSpace(touch:getLocation())
		local s = list:getContentSize()
		local rect = cc.rect(0, 0, s.width, s.height)

		local index = target:getTag() - 100

		local formShip = rn:getChildByName(string.format("form_ship_%d", index))

		local guid = formShip:getTag()

		local ship_info = player:getShipByGUID(guid)

		if cc.rectContainsPoint(rect, locationInList) then

			if self.guide_ship then
				return
			end

			tips:tips(CONF:getStringValue("down_form"))

			if self.svd and self.svd:getScrollView():getTag() ~= ship_info.type then
				self:changeState(ship_info.type)
			end

			self:resetForms(index, 0)
			
			self:resetFormByIndex(index, 0)
			self:resetList()
			self:resetNumInfo()

		end

		self.isTouch = false
 
		if self.isMoved then
			self.isMoved = false

			for i=1,9 do
				if index ~= i then
					local form = rn:getChildByName(string.format("point_%d", i))
					local posInNode = form:convertToNodeSpace(touch:getLocation())
					local s = form:getContentSize()

					local rect = cc.rect(0, 0, s.width, s.height)

					if cc.rectContainsPoint(rect, posInNode) then     

						if self.guide_ship then
							if i ~= 5 then
								self.guide_ship:setOpacity(255)
								return
							else
								self:removeAction2()

								guideManager:doEvent("move")
								GameHandler.handler_c.adjustTrackEvent("598tzz")
								-- guideManager:addGuideStep(908)
							end  
						end

						tips:tips(CONF:getStringValue("switch_form"))

						self:switchFormByIndex(index, i)

						self:resetFormByIndex(i)
						self:resetFormByIndex(index)

						break

					else
						if self.guide_ship then
							self.guide_ship:setOpacity(255)
						end
					end
				end
			end
		else

			if self.guide_ship then
				return
			end

			local node = require("app.views.StarOccupationLayer.FormShipInfoNode"):create()
			node:init(self, self.long_ship)
			node:setPosition(cc.p(rn:getChildByName("info_pos_2"):getPosition()))
			node:setLocalZOrder(20)
			rn:addChild(node)

			self.choose_ = require("app.ExResInterface"):getInstance():FastLoad("FormScene/choose.csb")
			self.choose_:setPosition(cc.p(rn:getChildByName("point_"..index):getPosition()))
			rn:addChild(self.choose_)

		end

	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)

	
end

function NewFormScene:createNormalShipNode( ship_info, flag )
	local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/ship_normal.csb")

	if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
		ship_info = player:getShipByGUID(ship_info.guid)
	end

	local conf = CONF.AIRSHIP.get(ship_info.id)

	node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
	node:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")

	node:getChildByName("num"):setString(ship_info.level)
	node:getChildByName("type"):setTexture("ShipType/"..conf.TYPE..".png")

	node:getChildByName("icon"):setTag(ship_info.guid)
	-- node:getChildByName("background"):setTag(ship_info.)

	if flag then
		local grey = mc.EffectGreyScale:create()

		local greyImage = mc.EffectSprite:create("RoleIcon/"..conf.DRIVER_ID..".png")
		greyImage:setEffect(grey)
		greyImage:setPosition(cc.p(node:getChildByName("icon"):getPosition()))
		node:getChildByName("icon"):removeFromParent()
		node:addChild(greyImage)    
		greyImage:setName("icon")
		-- greyImage:setScale(60/greyImage:getContentSize().width)
	end

	local label
	if ship_info.durable < Tools.getShipMaxDurable(ship_info)/10 then
		label = cc.Label:createWithTTF(CONF:getStringValue("no durable"), "fonts/cuyabra.ttf", 16)
	else
		if  Bit:has(ship_info.status, 2) == true then
			if node:getChildByName("fix_label") then
				node:getChildByName("fix_label"):setString(CONF:getStringValue("repairingTime"))
			else
				label = cc.Label:createWithTTF(CONF:getStringValue("repairingTime"), "fonts/cuyabra.ttf", 16)
			end
		elseif  Bit:has(ship_info.status, 4) == true then
			if self.data_.from ~= "trial_fight"  and self.data_.from ~= "continue" and self.data_.from ~= "special" and self.data_.from ~= "trial" then
				label = cc.Label:createWithTTF(CONF:getStringValue("planeting"), "fonts/cuyabra.ttf", 16)
			end
		end
	end
	if label then
		label:setAnchorPoint(cc.p(0.5,0.5))
		label:setPosition(cc.p(node:getChildByName("icon"):getPosition()))
		label:setTextColor(cc.c4b(255,145,136,255))
		-- label:enableShadow(cc.c4b(255,145,136,255),cc.size(0.5,0.5))
		label:setLineBreakWithoutSpace(true)
		label:setMaxLineWidth(80)
		label:setName("fix_label")
		node:addChild(label)
	end
	node:getChildByName("type"):setLocalZOrder(2)

	for i=1,6 do
		node:getChildByName("star_"..i):setLocalZOrder(2)
	end

	for i=ship_info.ship_break+1,6 do
		if node:getChildByName("star_"..i) then
			node:getChildByName("star_"..i):removeFromParent()
		end
	end

	return node
end


function NewFormScene:createSelectShipNode( ship_info )
	local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/ship_select.csb")

	local conf = CONF.AIRSHIP.get(ship_info.id)

	node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
	node:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")

	if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
		local bs = cc.size(73.80, 6.4)
		local progress = require("util.ClippingScaleProgressDelegate"):create("CopyScene/ui/ui_progress_light2.png", 84, {bg_size = bs, lightLength = 4})

		node:addChild(progress:getClippingNode())
		progress:getClippingNode():setPosition(cc.p(node:getChildByName("progress_back"):getPosition()))

		local t_hp = player:getTrialShipHpByGUID(self.data_.index, ship_info.guid)
		local hp = player:calShip(ship_info.guid).attr[CONF.EShipAttr.kHP]
		progress:setPercentage(t_hp/hp*100)
	else
		node:getChildByName("progress_back"):removeFromParent()
	end

	return node
end

function NewFormScene:addListItem( tag )

	self.svd:clear()
	
	local ship_list 
	if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then

		ship_list = {}
		for i,v in ipairs(g_player:getTrialShipByType(self.data_.index, tag)) do
			if v ~= 0 then
				local info = g_player:getShipByGUID(v.guid)
				table.insert(ship_list, info)
			end
		end

	else
		ship_list = g_player:getShipsByType(tag)
	end

	local function sort( a,b )
		if a.quality ~= b.quality then
			return a.quality > b.quality
		else
			local af = g_player:calShipFightPower(a.guid)
			local bf = g_player:calShipFightPower(b.guid)
			if af ~= bf then
				return af > bf
			else
				if a.level > b.level then
					return a.level > b.level
				else
					if a.id ~= b.id then
						return a.id > b.id 
					end
				end
			end
		end
	end

	table.sort( ship_list, sort )

	for i,v in ipairs(ship_list) do
		local onLine = false
		for i2,v2 in ipairs(self.forms) do
			if v.guid == v2 then 
				onLine = true
			end
		end

		if not onLine then

			local flag = false

			if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
				local ship_list = player:getTrialShipList(self.data_.index)
				for ii,vv in ipairs(ship_list) do
					if vv.guid == v.guid then
						if vv.hp == 0 then
							flag = true
							break
						end
					end
				end
			end

			local ship = self:createNormalShipNode(v, flag)
			ship:setTag(v.guid)

			if self.data_.from ~= "continue" then
				self:addIconListener(ship:getChildByName("background"))
			end
			self.svd:addElement(ship)
		end
	end

	if #self.svd:getScrollView():getChildren() < 5 then
		self.svd:getScrollView():setTouchEnabled(false)
	else
		-- self.svd:getScrollView():setBounceEnabled(true)
		self.svd:getScrollView():setTouchEnabled(true)
	end

end

function NewFormScene:addList( tag )
	self.pieceType = tag
	local rn = self:getResourceNode()
	local piece = rn:getChildByName("piece_"..tag)
	piece:getChildByName("piece"):loadTexture("Common/newUI/bz_yq_light.png")
	local listPos = rn:getChildByName("Text_27")
	local posX = listPos:getPositionX() - 5
	local posY = listPos:getPositionY() - (tag - 1) * (piece:getChildByName("piece"):getContentSize().height + 5) - piece:getChildByName("piece"):getContentSize().height*2 
	local node = require("app.ExResInterface"):getInstance():FastLoad("WeaponDevelopScene/listNode.csb")
	node:getChildByName("list"):setContentSize(cc.size(piece_width, diff-15	))
	node:getChildByName("list"):setTag(tag)
	rn:addChild(node,6)
	node:setPosition(cc.p(posX ,posY))
	node:setName("sv")
	self.svd = require("util.ScrollViewDelegate"):create( node:getChildByName("list"),cc.size(20,10), cc.size(90 ,90))

	self:addListItem(tag)
	-- self:resetList()
	if tag < 4 then 
		for i=tag + 1 ,4 do
			local node = rn:getChildByName("piece_"..i)
			node:setPositionY(node:getPositionY() - diff)
		end     
	end
end

function NewFormScene:removeList( tag )
	local rn = self:getResourceNode()
	self.svd = nil
	local node = rn:getChildByName("piece_"..tag)
	node:getChildByName("piece"):loadTexture("Common/newUI/bz_yq.png")
	if rn:getChildByName("sv") then 
		rn:getChildByName("sv"):removeFromParent()
		if tag < 4 then 
			for i=tag + 1 ,4 do
				local node = rn:getChildByName("piece_"..i)
				node:setPositionY(node:getPositionY() + diff)
			end     
		end
	end 

	if self.prePieceTag ~= 0 then 
		rn:getChildByName("piece_"..self.prePieceTag):getChildByName("list_open"):setVisible(false)
	end
end

function NewFormScene:changeState( tag )

	for i=1,4 do
		self:getResourceNode():getChildByName("piece_"..i):getChildByName("list_open"):setVisible(tag == i)
	end

	if self.prePieceTag == -1 then 
		self.prePieceTag = tag 
		self:addList(tag)
	elseif self.prePieceTag == tag then
		self:removeList(tag)
		self.prePieceTag = -1
	else 
		self:removeList(self.prePieceTag)
		self.prePieceTag = tag
		self:addList(self.prePieceTag)
	end
end

function NewFormScene:AddPiece()
	-- local isTouchMe = false
	-- local function onTouchBegan(touch, event)
	-- 	local target = event:getCurrentTarget()
	-- 		local locationInNode = target:convertToNodeSpace(touch:getLocation())
	-- 		local s = target:getContentSize()
	-- 		local rect = cc.rect(0, 0, s.width, s.height)
	-- 		if cc.rectContainsPoint(rect, locationInNode) then
	-- 			isTouchMe = true
	-- 			return true
	-- 		end
	-- 	return false
	-- end

	-- local function onTouchMoved( touch ,event )

	-- 	local delta = touch:getDelta()

	-- 	if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
	-- 		isTouchMe = false
	-- 	end
	-- end

	-- local function onTouchEnded(touch, event)
	-- 	if isTouchMe == true then
	-- 		self:changeState(event:getCurrentTarget():getParent():getTag())
	-- 	end
	-- end

	-- local eventDispatcher = self:getEventDispatcher()
	-- local listener = cc.EventListenerTouchOneByOne:create()
	-- listener:setSwallowTouches(false)
	-- listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	-- listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	-- listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

	local function add(name ,index )
		local rn = self:getResourceNode()
		local piecePos = rn:getChildByName("Text_27")
		local node = require("app.ExResInterface"):getInstance():FastLoad("TaskScene/PieceNode.csb")
		local posX = piecePos:getPositionX() - 20
		local posY = piecePos:getPositionY() - index * (node:getChildByName("piece"):getContentSize().height) + 10
		node:getChildByName("piece"):setContentSize(cc.size(piece_width, node:getChildByName("piece"):getContentSize().height))

		local label = cc.Label:createWithTTF(#player:getShipsByType(index), "fonts/cuyabra.ttf", 20)
		label:setTextColor(cc.c4b(209,209,209,255))
		-- label:enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
		label:setPosition(cc.p(node:getChildByName("piece"):getPositionX() + node:getChildByName("piece"):getContentSize().width/2 + 10, node:getChildByName("piece"):getPositionY() - node:getChildByName("piece"):getContentSize().height/2))
		node:addChild(label)
		label:setName("ship_num")

		node:getChildByName("text"):setString(name)
		node:getChildByName("piece"):addClickEventListener(function ( sender)
			playEffectSound("sound/system/tab.mp3")
			if self.guide_ship or self.test_ship then
				return
			end

			self:changeState(node:getTag())
		end)
		-- eventDispatcher:addEventListenerWithSceneGraphPriority(listener:clone(), node:getChildByName("piece"))
		node:setName("piece_"..index)
		node:setTag(index)
		node:setPosition(cc.p(posX ,posY))
		rn:addChild(node ,5)
	end 

	add(CONF.STRING.get("attack").VALUE ,1)
	add(CONF.STRING.get("defense").VALUE ,2)
	add(CONF.STRING.get("treat").VALUE ,4)
	add(CONF.STRING.get("control").VALUE ,3)

	self:resetShipNum()

	if guideManager.guide_id == g_Guide_Form_Id and guideManager:getShowGuide() then
		-- print( "##LUA NewFormScene 1094 guideManager.guide_id = " .. tostring(g_Guide_Form_Id) .. " +1" )
		guideManager.guide_id = g_Guide_Form_Id+1

		self:changeState(1)

		self:addAction1()
	else
		self:changeState(1)
	end
end

function NewFormScene:onEnterTransitionFinish()
	printInfo("NewFormScene:onEnterTransitionFinish()")

	local rn = self:getResourceNode()

	self.fight_delegate_ = require("util.FightRunDelegate"):create(rn:getChildByName("power_num"))

	self.faguang = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/faguang.csb")
	animManager:runAnimByCSB(self.faguang, "FormScene/sfx/faguang.csb", "1")
	rn:addChild(self.faguang)
	self.faguang:setPositionX(-10000)

	--------
	self.isTouch = false
	self.isMoved = false
	--------
	
	rn:getChildByName("e_text"):setString(CONF:getStringValue("myTeam"))
	-- rn:getChildByName("e_text_m"):setString(CONF:getStringValue("myTeam"))
	rn:getChildByName("Text_27"):setString(CONF:getStringValue("shipDepot"))
	rn:getChildByName("form"):setString(CONF:getStringValue("form"))
	rn:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("Military"))
	rn:getChildByName("save"):getChildByName("text"):setString(CONF:getStringValue("Save"))
	rn:getChildByName("power"):setString(CONF:getStringValue("ship_power")..":")

	rn:getChildByName("form_max_num"):setString("/"..CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM)

	local save = rn:getChildByName("save")
	local fight = rn:getChildByName("fight")


	if self.data_.from == "copy" or self.data_.from == "trial_fight" then

		local conf 
		if self.data_.from == "copy" then
			conf = CONF.CHECKPOINT.get(self.data_.id)
		else 
			conf = CONF.TRIAL_LEVEL.get(self.data_.id)
		end

		if conf == nil then 

		else
			rn:getChildByName("strength"):setString(CONF:getStringValue("use strength"))
			rn:getChildByName("strength_num"):setString(conf.STRENGTH)
			rn:getChildByName("strength_num_my"):setString("/"..player:getStrength())
		
			if tonumber(player:getStrength()) < conf.STRENGTH then
				rn:getChildByName("strength_num"):setTextColor(cc.c4b(255,0,0,255))
				-- rn:getChildByName("strength_num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,-0.5))
			end
		end
	else
		rn:getChildByName("strength"):setVisible(false)
		rn:getChildByName("strength_num"):setVisible(false)
		rn:getChildByName("strength_num_my"):setVisible(false)
		rn:getChildByName("strength_icon"):setVisible(false)
	end

	for i=1,9 do
		if self.data_.from ~= "continue"  then
			rn:getChildByName("point_"..i):setTag(100+i)
			self:addFormListener(rn:getChildByName("point_"..i))
		end
	end

	local ship_list_ = nil
	if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
		ship_list_ = g_player:getTrialLineup(self.data_.index)
	elseif self.data_.from == "slave" then
		ship_list_ = {0,0,0,0,0,0,0,0,0}
	else
		ship_list_ = g_player:getForms()

	end

	self.forms = {}

	local num = 0 
	for i,v in ipairs(ship_list_) do
		if v ~= 0 then
			table.insert(self.forms, v)
		else
			table.insert(self.forms, 0)
		end
		
	end

	local power = 0
	local forms_num = 0
	for i,v in ipairs(self.forms) do
		if v ~= 0 then
			power = power + player:calShipFightPower(v)
			forms_num = forms_num + 1
		end
	end
	rn:getChildByName("power_num"):setString(power)
	

	rn:getChildByName("form_now_num"):setString(forms_num)

	self.prePieceTag = -1  

	local function onFrameEvent(frame)
		if nil == frame then
			return
		end
		local str = frame:getEvent()

		if str == "f" then
			rn:getChildByName("power_num"):setPositionX(rn:getChildByName("power"):getPositionX() + rn:getChildByName("power"):getContentSize().width)
			rn:getChildByName("power_num"):setOpacity(255)
			
		end
	end

	animManager:runAnimOnceByCSB(self:getResourceNode(), "FormScene/NewFormScene.csb", "intro", function ()

		rn:getChildByName("strength_num"):setPositionX(rn:getChildByName("strength"):getPositionX() + rn:getChildByName("strength"):getContentSize().width + 5)
		rn:getChildByName("strength_num_my"):setPositionX(rn:getChildByName("strength_num"):getPositionX() + rn:getChildByName("strength_num"):getContentSize().width)
		rn:getChildByName("strength_icon"):setPositionX(rn:getChildByName("strength_num_my"):getPositionX() + rn:getChildByName("strength_num_my"):getContentSize().width + 2)

		self:AddPiece()

		for i,v in ipairs(self.forms) do
			if v ~= 0 then
				self:resetFormByIndex(i, v)
			end
		end

		if self.data_.from == "ships" or self.data_.from == "trial" or self.data_.from == "copy" or self.data_.from == "special" then
			save:setVisible(true)
			fight:setVisible(false)
		elseif self.data_.from == "trial_start" or self.data_.from == "trial_fight" or self.data_.from == "slave" then
			save:setVisible(false)
			fight:setVisible(true)
		elseif self.data_.from == "continue" then
			save:setVisible(false)
			fight:setVisible(false)
		end
	end,onFrameEvent)
	

	local function recvMsg()
		print("NewFormScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("ChangeLineupResp",strData)

			if proto.result < 0 then
				print("error :",proto.result)
			else

				g_player:setForms(self.forms, {from = "copy"})

				local forms_num = 0
				local forms_str = ""
				for i,v in ipairs(self.forms) do
					if v ~= 0 then
						forms_num = forms_num + 1

						if forms_str ~= "" then
							forms_str = forms_str.."-"
						end

						forms_str = forms_str..player:getShipByGUID(v).id
					end
				end

				flurryLogEvent("lineup_ship_change", {ship_num = tostring(forms_num), ship_id = forms_str}, 2)

				-- if self.data_.from == "copy" then
				-- 	local strData = Tools.encode("PveReq", {
				-- 		checkpoint_id = self.data_.id,
				-- 		type = 0,
				-- 	})
				-- 	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

				-- else
					self:getApp():popView()
				-- end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PVE_RESP") then
			
			local proto = Tools.decode("PveResp",strData)

			if proto.result == 2 then
					tips:tips(CONF:getStringValue("durable_not_enought"))

			elseif proto.result ~= 0 then
				print("error :",proto.result)
			else
				local strength = proto.user_sync.user_info.strength
				if strength == 0 then
					player:setStrength(strength)
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
				end
				--存exp
				g_Player_OldExp.oldExp = 0
				g_Player_OldExp.oldExp = g_player:getNowExp()
				g_Player_OldExp.oldLevel = g_player:getLevel()

				--存stageInfo
				g_Views_config.copy_id = self.data_.id
				-- g_Views_config.slPosX = self.data_.slPosX

				local name = CONF:getStringValue(CONF.CHECKPOINT.get(self.data_.id).NAME_ID)
				local enemy_name = getEnemyIcon(CONF.CHECKPOINT.get(self.data_.id).MONSTER_LIST)
				self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kCheckPoint,Tools.decode("PveResp",strData),true,name,enemy_name})

			end
			
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TrialAreaResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				if self.data_.from == "trial_start" then
					self:getApp():pushToRootView("TrialScene/TrialStageScene", {scene = g_player:getTrialScene(self.data_.index)})

				elseif self.data_.from == "trial_fight" then
					if self.data_.target_name then

						if self.data_.target_name == player:getName() then
							tips:tips(CONF:getStringValue("can't fight ziji"))
							return
						end
			
						local strData = Tools.encode("TrialPveStartReq", {
							level_id = self.data_.id,
							target_name = self.data_.target_name,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)
					else

						local strData = Tools.encode("TrialPveStartReq", {
							level_id = self.data_.id,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)
					end
					
					gl:retainLoading()
				else
					self:getApp():popView()
				end
				
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("TrialPveStartResp",strData)

			if proto.result == 2 then
				tips:tips(CONF:getStringValue("durable_not_enought"))

			elseif proto.result ~= 0 then
				print("error :",proto.result)
			else
				local strength = proto.user_sync.user_info.strength
				if strength == 0 then
					g_player:setStrength(strength)
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
				end
				-- g_player:setForms(self.forms, {from = "trial", index = self.data_.index})

				--存exp
				-- g_Player_OldExp.oldExp = 0
				-- g_Player_OldExp.oldExp = player:getNowExp()
				-- g_Player_OldExp.oldLevel = player:getLevel()

				local hp = 0
				for i,v in ipairs(player:getTrialShipList(self.data_.index)) do
					hp = hp + v.hp
				end

				--存stageInfo
				g_Views_config.copy_id = self.data_.id
				g_Views_config.slPosX = self.data_.slPosX
				g_Views_config.hp = hp
				
				local name 
				local enemy_name

				if self.data_.name ~= "" and self.data_.name then
					name = self.data_.nickname
					enemy_name = "HeroImage/"..self.data_.icon_id..".png"
				else
					name = CONF.TRIAL_LEVEL.get(self.data_.id).Medt_LEVEL
					if name == 0 or name == "0" then
						name = CONF:getStringValue(CONF.TRIAL_SCENE.get(self.data_.id).BUILDING_NAME)
					else
						name = CONF:getStringValue(name)
					end

					enemy_name = getEnemyIcon(CONF.TRIAL_LEVEL.get(self.data_.id).MONSTER_ID)
				end
				
				self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kTrial,Tools.decode("TrialPveStartResp",strData),true, name,enemy_name})

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_ATTACK_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("SlaveAttackResp",strData)

			if proto.result == 2 then
				tips:tips(CONF:getStringValue("durable_not_enought"))

			elseif proto.result ~= "OK" then
				print("SlaveAttackResp error :",proto.result)
			else
				-- local strength = proto.user_sync.user_info.strength
				-- if strength == 0 then
				-- 	g_player:setStrength(strength)
				-- 	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
				-- end
				
				local name = self.data_.name
				local enemy_name = "HeroImage/"..self.data_.icon_id..".png"
				
				local battleType 
				if self.data_.layer == "enemy" then
					battleType = BattleType.kSlaveEnemy

					flurryLogEvent("touch_slave", {}, 2)
				elseif self.data_.layer == "save" then
					battleType = BattleType.kSaveFriend

					flurryLogEvent("save_slave_friend", {}, 2)
				elseif self.data_.layer == "slave" then
					battleType = BattleType.kSlave

					flurryLogEvent("touch_slave", {}, 2)
				end

				self:getApp():pushToRootView("BattleScene/BattleScene", {battleType,Tools.decode("SlaveAttackResp",strData),false, name,enemy_name})

			end

		end
		
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

end

function NewFormScene:update( dt )

	if self.fight_delegate_:getFlag() then
		self.fight_delegate_:update()
	else
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil
	end
end

function NewFormScene:resetNumInfo( ... )
	local rn = self:getResourceNode()

	local num = 0
	for i,v in ipairs(self.forms) do
		if v ~= 0 then
			num = num + 1
		end
	end

	rn:getChildByName("form_now_num"):setString(num)

	local power = 0
	for i,v in ipairs(self.forms) do
		if v ~= 0 then
			power = power + player:calShipFightPower(v)
		end
	end
	-- rn:getChildByName("power_num"):setString(power)

	self.fight_delegate_:setUpNum(power)

	local function update( ... )
		self:update()
	end

	if schedulerEntry == nil then
		schedulerEntry = scheduler:scheduleScriptFunc(update,0.01,false)
	end

end

function NewFormScene:resetFormByIndex( index, guid )

	local rn = self:getResourceNode()


	local function createFormShip( shipId )

		local shipConf = CONF.AIRSHIP.get(shipId)

		local formship = require("app.ExResInterface"):getInstance():FastLoad("FormScene/FormShip.csb")
		-- formship:getChildByName("ship"):removeFromParent()

		local res = string.format("sfx/%s", shipConf.RES_ID)		
		local ship = require("app.ExResInterface"):getInstance():FastLoad(res)
		ship:setName("ship")
		formship:getChildByName("ship"):addChild(ship)

		animManager:runAnimByCSB(ship, res, "move_1")

		local icon = formship:getChildByName("icon")
		icon:setTexture(string.format("RoleIcon/%d.png", shipConf.ICON_ID))
		icon:setLocalZOrder(1)
		
		local t = formship:getChildByName("type")
		t:setTexture(string.format("ShipType/%d.png", shipConf.TYPE))
		t:setLocalZOrder(1)

		local ship_info = player:getShipByID(shipId)
		for i=ship_info.ship_break+1,6 do
			formship:getChildByName("star_"..i):removeFromParent()
		end
		
		return formship
	end


	local point = self:getResourceNode():getChildByName(string.format("point_%d", index))
	-- point:setOpacity(255)

	local name = string.format("form_ship_%d", index)

	if rn:getChildByName(name) then
		rn:removeChildByName(name)
	end


	if guid == nil then
	  
		guid = self:getFormByIndex(index)
		
	end

	if guid ~= 0 and guid then
		local ship = g_player:getShipByGUID(guid)
		assert(ship ~= nil,"error")

		local fs = createFormShip(ship.id)
		fs:setTag(guid)
		local pos = cc.p(rn:getChildByName(string.format("point_%d", index)):getPosition())
		fs:setPosition(pos)
		fs:setName(name)
		rn:addChild(fs)

		point:setOpacity(255)
		if ship.quality == 2 then
			point:setColor(cc.c4b(152,255,23,255))
		elseif ship.quality == 3 then
			point:setColor(cc.c4b(68,211,255,255))
		elseif ship.quality == 4 then
			point:setColor(cc.c4b(236,89,236,255))
		elseif ship.quality == 5 then
			point:setColor(cc.c4b(255,242,68,255))
		elseif ship.quality == 1 then
			point:setColor(cc.c4b(255,255,255,255))

		end
	else
		point:setColor(cc.c4b(255,255,255,255))
		point:setOpacity(78.5)

	end

end

function NewFormScene:getFormByIndex( index ,lineup)
	assert(index > 0 and index < 10,"error")

	return self.forms[index]
end

function NewFormScene:switchFormByIndex( index1, index2, lineup)
	assert(index1 > 0 and index1 < 10,"error")
	assert(index2 > 0 and index2 < 10,"error")

	local temp = self.forms[index1]
	self.forms[index1] = self.forms[index2]
	self.forms[index2] = temp
end


function NewFormScene:resetForms( index, newShipGUID, lineup )

	print(index, newShipGUID)

	assert(index > 0 and index < 10,"error")
	assert(newShipGUID > -1,"error")


	local oldGUID = self.forms[index]

	local oldShip = nil

	if oldGUID ~= 0 and oldGUID then
		oldShip = g_player:getShipByGUID(oldGUID)
		assert(oldShip,"error")
	end

	if newShipGUID ~= 0 then

		local newShip = g_player:getShipByGUID(newShipGUID)
		assert(newShip,"error")

		-- newShip.position = index
		self.forms[index] = newShip.guid
	else
		self.forms[index] = 0
	end

	-- if oldShip then
	--     oldShip.position = 0
	-- end
end

function NewFormScene:onExitTransitionStart()
	printInfo("NewFormScene:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry) 
		schedulerEntry = nil
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end


function NewFormScene:addAction1( )

	if player:getShipByGUID(2) == nil then
		return
	end

	local ship = self:createSelectShipNode(player:getShipByGUID(2))
	ship:setPosition(cc.p(650,515))
	ship:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.MoveBy:create(1, cc.p(-200,-80)), cc.CallFunc:create(function ( ... )
		ship:setVisible(false)
	end), cc.DelayTime:create(0.3), cc.CallFunc:create(function ( ... )
		ship:setVisible(true)
		ship:setPosition(cc.p(650,515))
	end))))
	self:getResourceNode():addChild(ship, 99)

	self.test_ship = ship

	local choose_node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/jianto.csb")
	animManager:runAnimByCSB(choose_node, "FormScene/sfx/jianto.csb", "1")
	choose_node:setPosition(cc.p(self:getResourceNode():getChildByName(string.format("point_%d", 4)):getPosition()))
	self:getResourceNode():addChild(choose_node)

	self.choose_ = choose_node

end

function NewFormScene:removeAction1( ... )
	self.test_ship:removeFromParent()
	self.test_ship = nil

	self.choose_:removeFromParent()
	self.choose_ = nil

end

function NewFormScene:addAction2( )

	if player:getShipByGUID(2) == nil then
		return
	end

	local ship = self:createSelectShipNode(player:getShipByGUID(1))
	ship:setPosition(cc.p(370,521))
	ship:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.MoveBy:create(0.7, cc.p(-45,-120)), cc.CallFunc:create(function ( ... )
		ship:setVisible(false)
	end), cc.DelayTime:create(0.3), cc.CallFunc:create(function ( ... )
		ship:setVisible(true)
		ship:setPosition(cc.p(370,521))
	end))))
	self:getResourceNode():addChild(ship, 99)

	self.guide_ship = ship

	local choose_node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/jianto.csb")
	animManager:runAnimByCSB(choose_node, "FormScene/sfx/jianto.csb", "1")
	choose_node:setPosition(cc.p(self:getResourceNode():getChildByName(string.format("point_%d", 5)):getPosition()))
	self:getResourceNode():addChild(choose_node)

	self.choose_ = choose_node

end

function NewFormScene:removeAction2( ... )
	self.guide_ship:removeFromParent()
	self.guide_ship = nil

	self.choose_:removeFromParent()
	self.choose_ = nil

end

return NewFormScene