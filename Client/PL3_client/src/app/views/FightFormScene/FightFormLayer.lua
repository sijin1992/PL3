local player = require("app.Player"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local gl = require("util.GlobalLoading"):getInstance()

local Bit = require "Bit"

local tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local FightFormLayer = class("FightFormLayer", cc.load("mvc").ViewBase)

FightFormLayer.RESOURCE_FILENAME = "CopyScene/CopyOrdinaryLayer.csb"

FightFormLayer.RUN_TIMELINE = true

FightFormLayer.NEED_ADJUST_POSITION = true

local fightClick = false

FightFormLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["form"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["fight"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function FightFormLayer:onCreate(data)
	self.data_ = data

end

function FightFormLayer:OnBtnClick(event)
	printInfo(event.name)
	
	if event.name == "ended" and event.target:getName() == "form" then 
		playEffectSound("sound/system/click.mp3")
		if Tools.isEmpty(self.texiao_list) == false then
			for i,v in ipairs(self.texiao_list) do
					v:removeFromParent()
				end

			self.texiao_list = {}
		end
		if guideManager:getGuideType() then

			-- guideManager:addGuideStep(907)
			self:getApp():removeViewByName("GuideLayer/GuideLayer")
		end

		if self.data_.from == "copy" then
			self:getApp():addView2Top("NewFormLayer", {from = self.data_.from, id = self.data_.copy_id, stageInfo = self.data_})
		elseif self.data_.from == "trial" then
			self:getApp():addView2Top("NewFormLayer", {from = self.data_.from, id = self.data_.copy_id, stageInfo = self.data_, index = self.data_.index})
		elseif self.data_.from == "arena" then
			local layer = self:getApp():createView("NewFormLayer", {from = "special"})
			self:addChild(layer)
			layer:setName("NewFormLayer")
		end
	end

	if event.name == "ended" and event.target:getName() == "fight" then
		playEffectSound("sound/system/click.mp3")
		if player:getStrength() < tonumber(self:getResourceNode():getChildByName("strength_num"):getString()) then
			-- tips:tips(CONF:getStringValue("strength_not_enought"))

			self:getApp():addView2Top("CityScene/AddStrenthLayer")
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

		if self.data_.from == "copy" then

			if player:isFighting(1) ~= 0 then
				return
			end		
			local change = false
			for i,v in ipairs(player:getForms()) do
				if v ~= self.forms[i] then
					change = true
					break
				end
			end

			if change then
				fightClick = true
				local strData = Tools.encode("ChangeLineupReq", {
						type = 1,
						lineup = self.forms
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)

				gl:retainLoading()
			else
				for i,v in ipairs(player:getForms()) do
					if v ~= 0 then
						local calship = player:calShip(v)
						if calship and Bit:has(calship.status, 4) then
							tips:tips(CONF:getStringValue("chuzhen_tips"))
							return
						end
					end
				end	
				local strData = Tools.encode("PveReq", {
					checkpoint_id = self.data_.copy_id,
					type = 0,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

				gl:retainLoading()
			end
		elseif self.data_.from == "trial" then
			if player:isFighting(2, self.data_.index) ~= 0 then
				return
			end

			local change = false
			-- 原来的
			-- for i,v in ipairs(player:getForms()) do
			-- 	if v ~= self.forms[i] then
			-- 		change = true
			-- 		break
			-- 	end
			-- end
			--现在
			for i,v in ipairs( player:getTrialLineup(self.data_.index)) do
				if v ~= self.forms[i] then
					change = true
					break
				end
			end
			if change then

				local strData = Tools.encode("TrialAreaReq", {
					type = 2,
					area_id = self.data_.index,
					lineup = self.forms
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

				gl:retainLoading()	
			end

			if self.data_.name then

				if self.data_.name == player:getName() then
					tips:tips(CONF:getStringValue("can't fight ziji"))
					return
				end
				
				local strData = Tools.encode("TrialPveStartReq", {
					type = 1,
					level_id = self.data_.level_id,
					target_name = self.data_.name,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)

				gl:retainLoading()

			else

				local strData = Tools.encode("TrialPveStartReq", {
					type = 1,
					level_id = self.data_.level_id,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)

				gl:retainLoading()

			end

		elseif self.data_.from == "arena" then


			local change = false
			for i,v in ipairs(player:getForms()) do
				if v ~= self.forms[i] then
					change = true
					break
				end
			end

			if change then

				local strData = Tools.encode("ChangeLineupReq", {
						type = 1,
						lineup = self.forms
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)

				gl:retainLoading()
			else

				self.challenge_name = self.data_.info.nickname
				self.challenge_power = self.data_.info.power

				self.challenge_icon = "HeroImage/"..self.data_.info.icon_id..".png"

				local strData = Tools.encode("ArenaChallengeReq", {
					type = 0,
					rank = self.data_.info.rank,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_CHALLENGE_REQ"),strData)

				gl:retainLoading()
			end
		end

	end

	if event.name == "ended" and event.target:getName() == "close" then
		playEffectSound("sound/system/return.mp3")

		if self.data_.from == "copy" then
			self:getApp():pushToRootView("LevelScene", {area = math.floor(self.data_.copy_id/1000000), stage = math.floor(self.data_.copy_id/100), index = self.data_.copy_id%100})
		else
			self:getApp():popView()
		end

	end

end

function FightFormLayer:onEnter()
  
	printInfo("FightFormLayer:onEnter()")

end

function FightFormLayer:onExit()
	
	printInfo("FightFormLayer:onExit()")
end

function FightFormLayer:createSelectShipNode( ship_info )
	local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/ship_select.csb")

	local conf = CONF.AIRSHIP.get(ship_info.id)

	node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
	node:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")
    node:getChildByName("icon"):setVisible(false)
    node:getChildByName("icon2"):setVisible(true)
    node:getChildByName("icon2"):setTexture("ShipImage/"..conf.DRIVER_ID..".png")
	node:getChildByName("progress_back"):removeFromParent()
	node:getChildByName("type"):setVisible(true)
	node:getChildByName("type"):setTexture("ShipQuality/quality_"..conf.QUALITY..".png")

	return node
end

function FightFormLayer:createTexiaoNode( pos )
	local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/guangbiao/guangbiao.csb")
	node:setPosition(cc.p(pos.x, pos.y + 5))
	self:getResourceNode():addChild(node)

	animManager:runAnimByCSB(node, "FormScene/sfx/guangbiao/guangbiao.csb", "1")

	table.insert(self.texiao_list, node)
end

function FightFormLayer:createSkillShow( pos )

	local ships_info = {}

	for i,v in ipairs(self.forms) do
		if v ~= 0 then

			local calship = player:calShip(v)
			calship.position = i
			calship.body_position = {i}

			table.insert(ships_info, calship)
		end
	end

	local fightManager = require("FightLogic.FightControler")
	fightManager:init(ships_info, nil, self.hurter_list, nil, true)

	local rn = self:getResourceNode()

	local choose_node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/jianto.csb")
	animManager:runAnimByCSB(choose_node, "FormScene/sfx/jianto.csb", "1")
	choose_node:setPosition(cc.p(rn:getChildByName(string.format("circle_%d_0", pos)):getPosition()))
	rn:addChild(choose_node)

	table.insert(self.texiao_list, choose_node)

	print("pospospos", pos)
	local fight_pos = fightManager:getSkillTargetTest(pos)

	if not Tools.isEmpty(fight_pos) then
		for i=1,2 do
			for i2,v2 in ipairs(fight_pos[i]) do
				print(i ,i2,v2)

				local node_pos 
				if i == 1 then
					node_pos = cc.p(rn:getChildByName(string.format("circle_%d_0", v2)):getPosition())
				elseif i == 2 then
					node_pos = cc.p(rn:getChildByName(string.format("circle_%d", v2)):getPosition())
				end

				self:createTexiaoNode(node_pos)
			end
		end
	end
end

function FightFormLayer:addFormListener(node)

	local function onTouchBegan(touch, event)
		
		local target = event:getCurrentTarget()
		
		local locationInNode = target:convertToNodeSpace(touch:getLocation())
		local s = target:getContentSize()

		local rect = cc.rect(0, 0, s.width, s.height)
		
		if cc.rectContainsPoint(rect, locationInNode) then

			for i,v in ipairs(self.texiao_list) do
				v:removeFromParent()
			end

			self.texiao_list = {}

			local rn = self:getResourceNode()

			local index = target:getTag() - 100
			local formShip = rn:getChildByName(string.format("form_ship_%d", index))
			if formShip == nil then
				return false
			end

			for i,v in ipairs(self.texiao_list) do
				v:removeFromParent()
			end
			self.texiao_list = {}

			local guid = formShip:getTag()
			assert(guid>0,"error")
			self.long_ship = guid

			local ship = player:getShipByGUID(guid)
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

			local form = self:getResourceNode():getChildByName(string.format("circle_%d_0", i))
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

		local index = target:getTag() - 100

		local formShip = rn:getChildByName(string.format("form_ship_%d", index))

		local guid = formShip:getTag()

		local ship_info = player:getShipByGUID(guid)

		self.isTouch = false
 
		if self.isMoved then
			self.isMoved = false

			for i=1,9 do
				if index ~= i then
					local form = rn:getChildByName(string.format("circle_%d_0", i))
					local posInNode = form:convertToNodeSpace(touch:getLocation())
					local s = form:getContentSize()

					local rect = cc.rect(0, 0, s.width, s.height)

					if cc.rectContainsPoint(rect, posInNode) then       

						tips:tips(CONF:getStringValue("switch_form"))

						self:switchFormByIndex(index, i)

						self:resetFormByIndex(i)
						self:resetFormByIndex(index)

						break
					end
				end
			end
		else
			--技能
			-- tips:tips(string.format("%d, %d", ship_info.skill, index))
			self:createSkillShow(index)

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

function FightFormLayer:resetFormByIndex( index, guid )

	local rn = self:getResourceNode()


	local function createFormShip( shipId )

		local shipConf = CONF.AIRSHIP.get(shipId)

		local formship = require("app.ExResInterface"):getInstance():FastLoad("FormScene/FormShip.csb")
		-- formship:getChildByName("ship"):removeFromParent()

		local res = string.format("sfx/%s", shipConf.RES_ID)

		print("ship res", res)
		
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


	local point = self:getResourceNode():getChildByName(string.format("circle_%d_0", index))
	-- point:setOpacity(255)

	local name = string.format("form_ship_%d", index)

	if rn:getChildByName(name) then
		rn:removeChildByName(name)
	end


	if guid == nil then
	  
		guid = self:getFormByIndex(index)
		
	end

	if guid ~= 0 and guid then
		local ship = player:getShipByGUID(guid)
		assert(ship ~= nil,"error")

		local fs = createFormShip(ship.id)
		fs:setTag(guid)
		local pos = cc.p(rn:getChildByName(string.format("circle_%d_0", index)):getPosition())
		fs:setPosition(pos)
		fs:setName(name)
		rn:addChild(fs, 5)

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

		if self.data_.from == "trial" then
			if player:getTrialShipHpByGUID(self.data_.index,guid) <= 0 then
				point:setColor(cc.c4b(255,0,0,255))
			end
		end
	else
		point:setColor(cc.c4b(255,255,255,255))
		point:setOpacity(78.5)

	end
	local forms_num = 0
	for i,v in ipairs(player:getForms()) do
		if v ~= 0 then
			forms_num = forms_num + 1
		end
	end

	if forms_num < CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM then
		rn:getChildByName("form"):getChildByName("point"):setVisible(true)
    else
        rn:getChildByName("form"):getChildByName("point"):setVisible(false)
	end

end

function FightFormLayer:getFormByIndex( index ,lineup)
	assert(index > 0 and index < 10,"error")

	return self.forms[index]
end

function FightFormLayer:switchFormByIndex( index1, index2, lineup)
	assert(index1 > 0 and index1 < 10,"error")
	assert(index2 > 0 and index2 < 10,"error")

	local temp = self.forms[index1]
	self.forms[index1] = self.forms[index2]
	self.forms[index2] = temp
end

function FightFormLayer:onEnterTransitionFinish()

	printInfo("FightFormLayer:onEnterTransitionFinish()")

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	-- self:getApp():addView2Top("TalkLayer/TalkLayer", {talk_id = CONF.CHECKPOINT.get(self.data_.copy_id).TALK_ID})
	if g_System_Guide_Id ~= 0 then
		systemGuideManager:createGuideLayer(g_System_Guide_Id)
	end

	self.attack_list = nil
	self.hurter_list = nil

	self.texiao_list = {}
	if self.data_.from == "copy" then
		local strData = Tools.encode("PveReq", {
			checkpoint_id = self.data_.copy_id,
			type = 2,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)
		if not self.data_.noRetain then
			gl:retainLoading()
		end
	elseif self.data_.from == "trial" then
		local need_fightForce = CONF.TRIAL_AREA.get(self.data_.index).ROLE_COMBAT
		local my_fightForce = player:getLineupPower()
		if self.data_.name and self.data_.name ~= "" then

			local strData = Tools.encode("TrialPveStartReq", {
				type = 2,
				level_id = self.data_.level_id,	
				target_name = self.data_.name,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)

			gl:retainLoading()

		else
			local strData = Tools.encode("TrialPveStartReq", {
				type = 2,
				level_id = self.data_.level_id,	
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)

			gl:retainLoading()
		end
		
	elseif self.data_.from == "arena" then
		local strData = Tools.encode("ArenaChallengeReq", {
			type = 2,
			rank = self.data_.info.rank,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_CHALLENGE_REQ"),strData)

		gl:retainLoading()

	end


	local rn = self:getResourceNode()

	self.faguang = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/faguang.csb")
	animManager:runAnimByCSB(self.faguang, "FormScene/sfx/faguang.csb", "1")
	rn:addChild(self.faguang)
	self.faguang:setPositionX(-10000)
	local ship_list_
	local conf = nil
	local function setInfo()
		if not self.data_ then
			return
		end
		if self.data_.from == "copy" or self.data_.from == "arena" then
			ship_list_ =  player:getForms()
		elseif self.data_.from == "trial" then
			ship_list_ = player:getTrialLineup(self.data_.index)
		end
		self.forms = {}

		for i,v in ipairs(ship_list_) do
			if v ~= 0 then
				table.insert(self.forms, v)
			else
				table.insert(self.forms, 0)
			end
			
		end

		local forms_num = 0
		for i,v in ipairs(player:getForms()) do
			if v ~= 0 then
				forms_num = forms_num + 1
			end
		end

		if forms_num < CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM then
			rn:getChildByName("form"):getChildByName("point"):setVisible(true)
		end

		if self.data_.from == "copy" then
			conf = CONF.CHECKPOINT.get(tonumber(string.format("%d", self.data_.copy_id)))
		elseif self.data_.from == "trial" then
			conf = CONF.TRIAL_LEVEL.get(self.data_.level_id)
		end

		rn:getChildByName("e_text"):setString(CONF:getStringValue("EnemyInfo"))
		rn:getChildByName("form"):getChildByName("text"):setString(CONF:getStringValue("form"))
		rn:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("enter combat"))
		rn:getChildByName("frist"):setString(CONF:getStringValue("front_row"))
		rn:getChildByName("second"):setString(CONF:getStringValue("middle_row"))
		rn:getChildByName("third"):setString(CONF:getStringValue("back_row"))
		rn:getChildByName("enemy_team_0"):setString(CONF:getStringValue("my_forms"))

		rn:getChildByName("enemy_team"):setString(CONF:getStringValue("enemyForm"))

		if self.data_.from == "copy" or self.data_.from == "arena" then
			rn:getChildByName("my_fight"):setString(player:getLineupPower())
		elseif self.data_.from == "trial" then

			local power = 0
			for i,v in ipairs(self.forms) do
				if v ~= 0 then
					power = power + player:calShipFightPower(v)
				end
			end

			rn:getChildByName("my_fight"):setString(power)
		end

		if conf then
			rn:getChildByName("di_fight"):setString(conf.COMBAT)

			if self.data_.power then
				rn:getChildByName("di_fight"):setString(self.data_.power)
			end
		else
			rn:getChildByName("di_fight"):setString(self.data_.info.power)
		end



		rn:getChildByName("strength"):setString(CONF:getStringValue("use strength")..":")

		if conf then
			rn:getChildByName("strength_num"):setString(conf.STRENGTH)

			rn:getChildByName("strength_num_my"):setString("/"..player:getStrength())

			if tonumber(player:getStrength()) < conf.STRENGTH then
				rn:getChildByName("strength_num"):setTextColor(cc.c4b(255,0,0,255))
				-- rn:getChildByName("strength_num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,-0.5))
			end
		end

		if self.data_.from == "trial" or self.data_.from == "arena" then
			rn:getChildByName("strength"):setVisible(false)
			rn:getChildByName("strength_num"):setVisible(false)
			rn:getChildByName("strength_icon"):setVisible(false)
			rn:getChildByName("strength_num_my"):setVisible(false)
		end
	end
	setInfo()
	--ship
	local function createEnemyShip( shipId )

		local shipConf = CONF.AIRSHIP.get(shipId)

		local enemyShip = require("app.ExResInterface"):getInstance():FastLoad("CopyScene/EnemyShip.csb")
		enemyShip:getChildByName("ship"):removeFromParent()

		local res = string.format("sfx/%s", shipConf.RES_ID)

		local ship = require("app.ExResInterface"):getInstance():FastLoad(res)
		ship:setName("ship")
		enemyShip:addChild(ship)

		animManager:runAnimByCSB(ship, res, "idle_2")

		local t = enemyShip:getChildByName("type")
		t:setTexture(string.format("ShipType/%d.png", shipConf.TYPE))
		t:setLocalZOrder(1)


		return enemyShip
	end

	local function recvMsg()
		print("CopyOrdinaryLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PVE_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("PveResp",strData)

			if proto.result == 2 then

				tips:tips(CONF:getStringValue("durable_not_enought"))

			elseif proto.result ~= 0 then
				
				print("error :",proto.result)
			else 
				
				if self.hurter_list then
					local strength = proto.user_sync.user_info.strength
					if strength == 0 then
						player:setStrength(strength)
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
					end
					--存exp
					g_Player_OldExp.oldExp = 0
					g_Player_OldExp.oldExp = player:getNowExp()
					g_Player_OldExp.oldLevel = player:getLevel()

					--存stageInfo
					g_Views_config.copy_id = self.data_.copy_id
					-- g_Views_config.slPosX = self.data_.slPossX

					local name = CONF:getStringValue(CONF.CHECKPOINT.get(self.data_.copy_id).NAME_ID)
					local enemy_name = getEnemyIcon(CONF.CHECKPOINT.get(self.data_.copy_id).MONSTER_LIST)

					flurryLogEvent("copy_use_strength",{copy_id = tostring(self.data_.copy_id),use_strength = tostring(conf.STRENGTH) }, 1, conf.STRENGTH)
					self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kCheckPoint,Tools.decode("PveResp",strData),true, name, enemy_name})
				else

					self.hurter_list = proto.hurter_list
				end
			
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_RESP") then
			if not self:getChildByName("NewFormLayer") then
				gl:releaseLoading()
				local proto = Tools.decode("ChangeLineupResp",strData)

				if proto.result < 0 then
					print("error :",proto.result)
				else
					if proto.type == 1 then
						player:setForms(self.forms, {from = "copy"})
					end

					if self.data_.from == "copy" then
						if fightClick then
							fightClick = false
							local strData = Tools.encode("PveReq", {
								checkpoint_id = self.data_.copy_id,
								type = 0,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

							gl:retainLoading()
						end
					elseif self.data_.from == "arena" then
						self.challenge_name = self.data_.info.nickname
						self.challenge_power = self.data_.info.power

						self.challenge_icon = "HeroImage/"..self.data_.info.icon_id..".png"

						local strData = Tools.encode("ArenaChallengeReq", {
							type = 0,
							rank = self.data_.info.rank,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_CHALLENGE_REQ"),strData)

						gl:retainLoading()
					end

				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("TrialPveStartResp",strData)
			print("TrialPveStartResp")
			print(proto.result)
			if proto.result == 2 then
				tips:tips(CONF:getStringValue("durable_not_enought"))
			elseif proto.result == 4 then
				tips:tips(CONF:getStringValue("ship hp zero"))
			elseif proto.result ~= 0 then
				print("error :",proto.result)
			else
				
				if self.hurter_list then
					local strength = proto.user_sync.user_info.strength
					if strength == 0 then
						player:setStrength(strength)
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
					end

					--存exp
					-- g_Player_OldExp.oldExp = 0
					-- g_Player_OldExp.oldExp = player:getNowExp()
					-- g_Player_OldExp.oldLevel = player:getLevel()

					local hp = 0
					for i,v in ipairs(player:getTrialShipList(self.data_.index)) do
						hp = hp + v.hp
					end

					--存stageInfo
					print("level",self.data_.level_id)
					g_Views_config.copy_id = self.data_.level_id
					g_Views_config.slPosX = self.data_.slPosX
					g_Views_config.hp = hp

					local name
					local enemy_name = getEnemyIcon(CONF.TRIAL_LEVEL.get(self.data_.level_id).MONSTER_ID)
					if CONF.TRIAL_LEVEL.get(self.data_.level_id).Medt_LEVEL == 0 or CONF.TRIAL_LEVEL.get(self.data_.level_id).Medt_LEVEL == "0" then
						name = CONF:getStringValue(CONF.TRIAL_SCENE.get(self.data_.level_id).BUILDING_NAME)
					else
						name = CONF:getStringValue(CONF.TRIAL_LEVEL.get(self.data_.level_id).Medt_LEVEL)
					end

					if self.data_.name and self.data_.name ~= "" then
						name = self.data_.nickname 
						enemy_name = "HeroImage/"..self.data_.icon_id..".png"
					end

					self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kTrial,Tools.decode("TrialPveStartResp",strData),true,name,enemy_name})
				else
					self.hurter_list = proto.hurter_list
				end

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TrialAreaResp",strData)
			if proto.result ~= 0 then
				print("proto error", proto.result)
			else
				-- if self.data_.name then

				-- 	if self.data_.name == player:getName() then
				-- 		tips:tips(CONF:getStringValue("can't fight ziji"))
				-- 		return
				-- 	end
					
				-- 	local strData = Tools.encode("TrialPveStartReq", {
				-- 		level_id = self.data_.level_id,
				-- 		target_name = self.data_.name,
				-- 	})
				-- 	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)

				-- 	gl:retainLoading()

				-- else

				-- 	local strData = Tools.encode("TrialPveStartReq", {
				-- 		level_id = self.data_.level_id,
				-- 	})
				-- 	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)

				-- 	gl:retainLoading()

				-- end
				setInfo()
				for i=1,9 do
					self:resetFormByIndex(i, 0)
				end
				for i,v in ipairs(self.forms) do
					if v ~= 0 then
						self:resetFormByIndex(i, v)
					end
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_CHALLENGE_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("ArenaChallengeResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
			else 
				if self.hurter_list then
					self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kArena,Tools.decode("ArenaChallengeResp",strData),true, self.challenge_name, self.challenge_icon, self.challenge_power})
				else
					self.hurter_list = proto.hurter_list
				end
			end
			
		end
	end
		
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.strengthListener_ = cc.EventListenerCustom:create("StrengthUpdated", function ()
		print("StrengthUpdated", player:getStrength())
		rn:getChildByName("strength_num_my"):setString("/"..player:getStrength())

		if tonumber(player:getStrength()) < tonumber(rn:getChildByName("strength_num"):getString()) then
			rn:getChildByName("strength_num"):setTextColor(cc.c4b(255,0,0,255))
			-- rn:getChildByName("strength_num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
		else
			rn:getChildByName("strength_num"):setTextColor(cc.c4b(33,255,70,255))
			-- rn:getChildByName("strength_num"):enableShadow(cc.c4b(33, 255, 70, 255),cc.size(0.5,0.5))
		end

	rn:getChildByName("strength_num_my"):setPositionX(rn:getChildByName("strength_num"):getPositionX() + rn:getChildByName("strength_num"):getContentSize().width)
	rn:getChildByName("strength_icon"):setPositionX(rn:getChildByName("strength_num_my"):getPositionX() + rn:getChildByName("strength_num_my"):getContentSize().width + 2)

	end)
	self.formChangeListener_ = cc.EventListenerCustom:create("formChange", function ()
		setInfo()
		if self.forms then
			for i,v in ipairs(self.forms) do
				self:resetFormByIndex(i, 0)
				if v ~= 0 then
					self:resetFormByIndex(i, v)
				end
			end
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.strengthListener_, FixedPriority.kNormal)
	eventDispatcher:addEventListenerWithFixedPriority(self.formChangeListener_, FixedPriority.kNormal)
	rn:getChildByName("strength_num"):setPositionX(rn:getChildByName("strength"):getPositionX() + rn:getChildByName("strength"):getContentSize().width + 5)
	rn:getChildByName("strength_num_my"):setPositionX(rn:getChildByName("strength_num"):getPositionX() + rn:getChildByName("strength_num"):getContentSize().width)
	rn:getChildByName("strength_icon"):setPositionX(rn:getChildByName("strength_num_my"):getPositionX() + rn:getChildByName("strength_num_my"):getContentSize().width + 2)
	
	--播放进入动画

	animManager:runAnimByCSB(rn:getChildByName("liuguang"), "Common/sfx/jiemianliuguang3.csb", "1")
    animManager:runAnimByCSB(rn:getChildByName("fightsfx"), "CopyScene/sfx/fightsfx/zhandouguangxiao.csb", "1")
	local function onFrameEvent(frame)
		if nil == frame then
			return
		end
		local str = frame:getEvent()

		if str == "1" then

			local nn = frame:getNode()

			rn:getChildByName("strength_num"):setPositionX(rn:getChildByName("strength"):getPositionX() + rn:getChildByName("strength"):getContentSize().width + 5)
			rn:getChildByName("strength_num_my"):setPositionX(rn:getChildByName("strength_num"):getPositionX() + rn:getChildByName("strength_num"):getContentSize().width)
			rn:getChildByName("strength_icon"):setPositionX(rn:getChildByName("strength_num_my"):getPositionX() + rn:getChildByName("strength_num_my"):getContentSize().width + 2)

			rn:getChildByName("strength_num"):setOpacity(255)
			rn:getChildByName("strength_num_my"):setOpacity(255)
			rn:getChildByName("strength_icon"):setOpacity(255)
		end
	end

	animManager:runAnimOnceByCSB(self:getResourceNode(),"CopyScene/CopyOrdinaryLayer.csb" ,"intro", function ( )

		if conf then

			local monster_list 
			if self.data_.from == "copy" then
				monster_list = conf.MONSTER_LIST 
			elseif self.data_.from == "trial" then

				if self.data_.name and self.data_.name ~= "" then
					monster_list = self.data_.id_lineup
				else
					monster_list = conf.MONSTER_ID
				end
			end

			for i,v in ipairs(monster_list) do
				if v > 0 then
					local ship = createEnemyShip(v)
					local shipPos = cc.p(rn:getChildByName(string.format("circle_%d", i)):getPosition())
					ship:setPosition(cc.p(shipPos.x, shipPos.y+10))
					rn:addChild(ship,5)

					local conf = CONF.AIRSHIP.get(v)
					if conf.QUALITY == 2 then
						rn:getChildByName(string.format("circle_%d", i)):setColor(cc.c4b(152,255,23,255))
					elseif conf.QUALITY == 3 then
						rn:getChildByName(string.format("circle_%d", i)):setColor(cc.c4b(68,211,255,255))
					elseif conf.QUALITY == 4 then
						rn:getChildByName(string.format("circle_%d", i)):setColor(cc.c4b(236,89,236,255))
					elseif conf.QUALITY == 5 then
						rn:getChildByName(string.format("circle_%d", i)):setColor(cc.c4b(255,242,68,255))

					end
					rn:getChildByName(string.format("circle_%d", i)):setOpacity(255)

				else
					rn:getChildByName(string.format("circle_%d", i)):setOpacity(78.5)
				end
			end

			local boss_pos = {}
			local boss_id = 0
			for i,v in ipairs(monster_list) do
				if v < 0 then
					boss_id = v
					table.insert(boss_pos, i)
				end
			end

			if boss_id ~= 0 then

				local min_pos = 0
				local max_pos = 0
				for i,v in ipairs(boss_pos) do
					if min_pos == 0 then
						min_pos = v
						max_pos = v
					end

					if v < min_pos then
						min_pos = v
					elseif v > min_pos and v < max_pos then

					elseif v > max_pos then
						max_pos = v
					end

					if CONF.AIRSHIP.get(math.abs(boss_id)).QUALITY == 2 then
						rn:getChildByName(string.format("circle_%d", v)):setColor(cc.c4b(152,255,23,255))
					elseif CONF.AIRSHIP.get(math.abs(boss_id)).QUALITY == 3 then
						rn:getChildByName(string.format("circle_%d", v)):setColor(cc.c4b(68,211,255,255))
					elseif CONF.AIRSHIP.get(math.abs(boss_id)).QUALITY == 4 then
						rn:getChildByName(string.format("circle_%d", v)):setColor(cc.c4b(236,89,236,255))
					elseif CONF.AIRSHIP.get(math.abs(boss_id)).QUALITY == 5 then
						rn:getChildByName(string.format("circle_%d", v)):setColor(cc.c4b(255,242,68,255))

					end
					rn:getChildByName(string.format("circle_%d", v)):setOpacity(255)

				end

				local pos1 = cc.p(rn:getChildByName("circle_"..min_pos):getPosition())
				local pos2 = cc.p(rn:getChildByName("circle_"..max_pos):getPosition())

				local pos_p = cc.pMidpoint(pos1,pos2)
				local ship = createEnemyShip(math.abs(boss_id))
				local shipPos = cc.p(pos_p)
				ship:setPosition(cc.p(shipPos.x, shipPos.y+10))
				rn:addChild(ship,5)
			end

		else
			for i,v in ipairs(self.data_.info.ship_id_list) do
				if v > 0 then
					local ship = createEnemyShip(v)
					local shipPos = cc.p(rn:getChildByName(string.format("circle_%d", i)):getPosition())
					ship:setPosition(cc.p(shipPos.x, shipPos.y+10))
					rn:addChild(ship,5)

					local conf = CONF.AIRSHIP.get(v)
					if conf.QUALITY == 2 then
						rn:getChildByName(string.format("circle_%d", i)):setColor(cc.c4b(152,255,23,255))
					elseif conf.QUALITY == 3 then
						rn:getChildByName(string.format("circle_%d", i)):setColor(cc.c4b(68,211,255,255))
					elseif conf.QUALITY == 4 then
						rn:getChildByName(string.format("circle_%d", i)):setColor(cc.c4b(236,89,236,255))
					elseif conf.QUALITY == 5 then
						rn:getChildByName(string.format("circle_%d", i)):setColor(cc.c4b(255,242,68,255))

					end
					rn:getChildByName(string.format("circle_%d", i)):setOpacity(255)

				else
					rn:getChildByName(string.format("circle_%d", i)):setOpacity(78.5)
				end
			end

		end

		for i,v in ipairs(self.forms) do
			if v ~= 0 then
				self:resetFormByIndex(i, v)
			end
		end

		for i=1,9 do
			rn:getChildByName("circle_"..i.."_0"):setTag(100+i)
			self:addFormListener(rn:getChildByName("circle_"..i.."_0"))
		end
		rn:getChildByName("strength_num"):setPositionX(rn:getChildByName("strength"):getPositionX() + rn:getChildByName("strength"):getContentSize().width + 5)
		rn:getChildByName("strength_num_my"):setPositionX(rn:getChildByName("strength_num"):getPositionX() + rn:getChildByName("strength_num"):getContentSize().width)
		rn:getChildByName("strength_icon"):setPositionX(rn:getChildByName("strength_num_my"):getPositionX() + rn:getChildByName("strength_num_my"):getContentSize().width + 2)
	
		
	end, onFrameEvent)

	-----------------------------
	-- WJJ 20180711 
	local precloner = require("util.ExPreclonePool"):getInstance()
	local list = require("util.ExPreloadList").LIST_BATTLE
	precloner:OnPreclone(self:getResourceNode(), list, 0)
	-----------------------------
end


function FightFormLayer:onExitTransitionStart()

	printInfo("FightFormLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.strengthListener_)

end

return FightFormLayer