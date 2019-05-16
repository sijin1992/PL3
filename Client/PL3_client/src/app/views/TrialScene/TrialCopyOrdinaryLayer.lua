local player = require("app.Player"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local TrialCopyOrdinaryLayer = class("TrialCopyOrdinaryLayer", cc.load("mvc").ViewBase)

TrialCopyOrdinaryLayer.RESOURCE_FILENAME = "CopyScene/CopyOrdinaryLayer.csb"

TrialCopyOrdinaryLayer.RUN_TIMELINE = true

TrialCopyOrdinaryLayer.NEED_ADJUST_POSITION = true

TrialCopyOrdinaryLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["form"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["fight"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}
	
local schedulerEntry = nil

function TrialCopyOrdinaryLayer:onCreate(data)
	self.data_ = data

end

function TrialCopyOrdinaryLayer:OnBtnClick(event)

	local conf = CONF.TRIAL_LEVEL.get(self.data_.level_id)

	if event.name == "ended" and event.target:getName() == "form" then    	
		playEffectSound("sound/system/click.mp3")
		if self.data_.name and self.data_.name ~= "" then
			self:getApp():addView2Top("NewFormLayer", {from = "trial_fight", id = self.data_.level_id, index = self.data_.index, target_name = self.data_.name, icon_id = self.data_.icon_id})
		else
		   self:getApp():addView2Top("NewFormLayer", {from = "trial_fight", id = self.data_.level_id, index = self.data_.index})
		end
	end

	if event.name == "ended" and event.target:getName() == "fight" then
		playEffectSound("sound/system/click.mp3")
		if player:getStrength() < CONF.TRIAL_LEVEL.get(self.data_.level_id).STRENGTH then
			-- tips:tips(CONF:getStringValue("strength_not_enought"))

			self:getApp():addView2Top("CityScene/AddStrenthLayer")
			return
		end 

		if player:isFighting(2, self.data_.index) ~= 0 then
			return
		end


		if self.data_.name then

			if self.data_.name == player:getName() then
				tips:tips(CONF:getStringValue("can't fight ziji"))
				return
			end
			
			local strData = Tools.encode("TrialPveStartReq", {
				level_id = self.data_.level_id,
				target_name = self.data_.name,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)
		else

			local strData = Tools.encode("TrialPveStartReq", {
				level_id = self.data_.level_id,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)
		end

		gl:retainLoading()

	end

	if event.name == "ended" and event.target:getName() == "close" then
		playEffectSound("sound/system/return.mp3")
		self:getApp():popView()
		-- self:getApp():pushToRootView("TrialScene/TrialStageScene", {})
	end

end

function TrialCopyOrdinaryLayer:onEnter()
  
	printInfo("CopyOrdinaryLayer:onEnter()")

end

function TrialCopyOrdinaryLayer:onExit()
	
	printInfo("CopyOrdinaryLayer:onExit()")
end

function TrialCopyOrdinaryLayer:createSelectShipNode( ship_info )
	local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/ship_select.csb")

	local conf = CONF.AIRSHIP.get(ship_info.id)

	node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
	node:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")

	node:getChildByName("progress_back"):removeFromParent()
	
	return node
end

function TrialCopyOrdinaryLayer:createSkillShow( skill, pos )
	local conf = CONF.CHECKPOINT.get(self.data_.copy_id)

	local skill_conf = CONF.WEAPON.get(skill)


	if skill_conf.TARGET_1 ~= 0 then
		if skill_conf.TARGET_1 == 4 then
			if skill_conf.TARGET_2 == 1 then

			end
		end

	end
end

function TrialCopyOrdinaryLayer:addFormListener(node)

	local function onTouchBegan(touch, event)
		
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

		self.isMoved = true

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
			tips:tips(string.format("%d, %d", ship_info.skill, index))
			self:createSkillShow(ship_info.skill, index)

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

function TrialCopyOrdinaryLayer:resetFormByIndex( index, guid )

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
--		for i=ship_info.ship_break+1,6 do
--			formship:getChildByName("star_"..i):removeFromParent()
--		end
        ShowShipStar(formship,ship_info.ship_break,"star_")
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

function TrialCopyOrdinaryLayer:getFormByIndex( index ,lineup)
	assert(index > 0 and index < 10,"error")

	return self.forms[index]
end

function TrialCopyOrdinaryLayer:switchFormByIndex( index1, index2, lineup)
	assert(index1 > 0 and index1 < 10,"error")
	assert(index2 > 0 and index2 < 10,"error")

	local temp = self.forms[index1]
	self.forms[index1] = self.forms[index2]
	self.forms[index2] = temp
end

function TrialCopyOrdinaryLayer:onEnterTransitionFinish()

	printInfo("CopyOrdinaryLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()

	self.faguang = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/faguang.csb")
	animManager:runAnimByCSB(self.faguang, "FormScene/sfx/faguang.csb", "1")
	rn:addChild(self.faguang)
	self.faguang:setPositionX(-10000)

	local forms_num = 0
	for i,v in ipairs(player:getTrialLineup(self.data_.index)) do
		if v ~= 0 then
			forms_num = forms_num + 1
		end
	end

	local ship_num = 0
	for i,v in ipairs(player:getTrialShipList(self.data_.index)) do
		if v.hp ~= 0 then
			ship_num = ship_num + 1
		end
	end

	if forms_num < ship_num then
		rn:getChildByName("form"):getChildByName("point"):setVisible(true)
	end

	rn:getChildByName("e_text"):setString(CONF:getStringValue("EnemyInfo"))
	rn:getChildByName("form"):getChildByName("text"):setString(CONF:getStringValue("form"))
	rn:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("Military"))
	rn:getChildByName("frist"):setString(CONF:getStringValue("front_row"))
	rn:getChildByName("second"):setString(CONF:getStringValue("middle_row"))
	rn:getChildByName("third"):setString(CONF:getStringValue("back_row"))

	local conf = CONF.TRIAL_LEVEL.get(self.data_.level_id)
	-- rn:getChildByName("level_fight"):setString(CONF:getStringValue("dungeonPower"))
	-- rn:getChildByName("drop"):getChildByName("text"):setString(CONF:getStringValue("dungeonDrop"))
	rn:getChildByName("enemy_team"):setString(CONF:getStringValue("enemyForm"))
	rn:getChildByName("enemy_team_0"):setString(CONF:getStringValue("my_forms"))

	-- rn:getChildByName("level_num"):setString(conf.LEVEL)

	-- if conf.Medt_LEVEL == "0" or conf.Medt_LEVEL == 0 then
	-- 	rn:getChildByName("level_name"):setString(CONF:getStringValue(CONF.TRIAL_SCENE.get(self.data_.level_id).BUILDING_NAME))
	-- else
	-- 	rn:getChildByName("level_name"):setString(CONF.STRING.get(conf.Medt_LEVEL).VALUE)
	-- end

	-- if conf.INTRODUCE_ID == "0" or conf.INTRODUCE_ID == 0 then
	-- 	rn:getChildByName("level_ins"):setString(CONF:getStringValue("null"))
	-- else
	-- 	rn:getChildByName("level_ins"):setString(CONF.STRING.get(conf.INTRODUCE_ID).VALUE)
	-- end

	local ships = {}
	for i,v in ipairs(player:getTrialLineup(self.data_.index)) do
		if v ~= 0 then
			local ship_info = player:calShip(v)
			table.insert(ships, ship_info)
		end
	end


	-- local power = Tools.calAllFightPower(ships, player:getUserInfo())

	-- rn:getChildByName("level_fight_mynum"):setString(power)

	-- if self.data_.name and self.data_.name ~= "" then
	-- 	 rn:getChildByName("level_fight_dnum"):setString("/"..self.data_.power)

	-- 	 if tonumber(player:getPower()) < self.data_.power then
	-- 		rn:getChildByName("level_fight_mynum"):setTextColor(cc.c4b(255,0,0,255))
	-- 		rn:getChildByName("level_fight_mynum"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
	-- 	end
	-- else
	-- 	rn:getChildByName("level_fight_dnum"):setString(string.format("/%d", conf.COMBAT))

	-- 	if tonumber(player:getPower()) < conf.COMBAT then
	-- 		rn:getChildByName("level_fight_mynum"):setTextColor(cc.c4b(255,0,0,255))
	-- 		rn:getChildByName("level_fight_mynum"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,0.5))
	-- 	end
	-- end

	-- rn:getChildByName("level_gold"):setString(CONF:getStringValue("copy gold"))
	-- rn:getChildByName("level_gold_num"):setString(conf.GOLD)
	-- rn:getChildByName("level_tp"):setString(CONF:getStringValue("copy money"))
	-- rn:getChildByName("level_tp_num"):setString(conf.BADGE)

	-- rn:getChildByName("info"):getChildByName("text"):setString(CONF:getStringValue("information"))
	-- rn:getChildByName("drop"):getChildByName("text"):setString(CONF:getStringValue("dungeonDrop"))

	rn:getChildByName("strength"):setString(CONF:getStringValue("use strength"))

	rn:getChildByName("strength_num"):setString(conf.STRENGTH)
	rn:getChildByName("strength_num_my"):setString("/"..player:getStrength())

	if tonumber(player:getStrength()) < conf.STRENGTH then
		rn:getChildByName("strength_num"):setTextColor(cc.c4b(255,0,0,255))
		-- rn:getChildByName("strength_num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,-0.5))
	end

	-- rn:getChildByName("level_gold"):setString(CONF:getStringValue("dungeonDrop"))
	-- rn:getChildByName("level_tp"):setString(CONF:getStringValue("dungeonDrop"))

	-- rn:getChildByName("item_1"):setVisible(false)

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

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("TrialPveStartResp",strData)

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
					name = self.data_.name 
					enemy_name = "HeroImage/"..self.data_.icon_id..".png"
				end

				self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kTrial,Tools.decode("TrialPveStartResp",strData),true,name,enemy_name})

			end
			
		end
	end
		
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	animManager:runAnimByCSB(rn:getChildByName("liuguang"), "Common/sfx/jiemianliuguang3.csb", "1")

	animManager:runAnimOnceByCSB(self:getResourceNode(),"CopyScene/CopyOrdinaryLayer.csb" ,"intro", function ( ... )

		if self.data_.name == "" or self.data_.name == nil then

			for i,v in ipairs(conf.MONSTER_ID) do
				if v > 0 then
					local ship = createEnemyShip(v)
					local shipPos = cc.p(rn:getChildByName(string.format("circle_%d", i)):getPosition())
					ship:setPosition(cc.p(shipPos.x, shipPos.y+10))
					rn:addChild(ship)

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
			for i,v in ipairs(conf.MONSTER_LIST) do
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
				rn:addChild(ship)
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
		else

			for i,v in ipairs(self.data_.id_lineup) do
				if v ~= 0 then
					local ship = createEnemyShip(v)
					local shipPos = cc.p(rn:getChildByName(string.format("circle_%d", i)):getPosition())
					ship:setPosition(shipPos.x, shipPos.y+10)
					self:getResourceNode():addChild(ship)

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

		-- rn:getChildByName("level_fight_dnum"):setPositionX(rn:getChildByName("level_fight_mynum"):getPositionX() + rn:getChildByName("level_fight_mynum"):getContentSize().width)
		rn:getChildByName("strength_num"):setPositionX(rn:getChildByName("strength"):getPositionX() + rn:getChildByName("strength"):getContentSize().width + 5)
		rn:getChildByName("strength_num_my"):setPositionX(rn:getChildByName("strength_num"):getPositionX() + rn:getChildByName("strength_num"):getContentSize().width)
		rn:getChildByName("strength_icon"):setPositionX(rn:getChildByName("strength_num_my"):getPositionX() + rn:getChildByName("strength_num_my"):getContentSize().width + 2)
	end)

end


function TrialCopyOrdinaryLayer:onExitTransitionStart()

	printInfo("CopyOrdinaryLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end

return TrialCopyOrdinaryLayer