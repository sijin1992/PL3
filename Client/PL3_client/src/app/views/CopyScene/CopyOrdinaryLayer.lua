local player = require("app.Player"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local CopyOrdinaryLayer = class("CopyOrdinaryLayer", cc.load("mvc").ViewBase)

CopyOrdinaryLayer.RESOURCE_FILENAME = "CopyScene/CopyOrdinaryLayer.csb"

CopyOrdinaryLayer.RUN_TIMELINE = true

CopyOrdinaryLayer.NEED_ADJUST_POSITION = true

CopyOrdinaryLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["form"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["fight"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function CopyOrdinaryLayer:onCreate(data)
	self.data_ = data

end

function CopyOrdinaryLayer:OnBtnClick(event)
	printInfo(event.name)
	
	if event.name == "ended" and event.target:getName() == "form" then 
		playEffectSound("sound/system/click.mp3")
		if guideManager:getGuideType() then
			-- guideManager:addGuideStep(907)
			self:getApp():removeTopView()
		end

		self:getApp():pushView("NewFormScene", {from = "copy", id = self.data_.copy_id, stageInfo = self.data_})
	end

	if event.name == "ended" and event.target:getName() == "fight" then
		playEffectSound("sound/system/click.mp3")
		if player:getStrength() < tonumber(self:getResourceNode():getChildByName("strength_num"):getString()) then
			-- tips:tips(CONF:getStringValue("strength_not_enought"))

			self:getApp():addView2Top("CityScene/AddStrenthLayer")
			return
		end

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

			local strData = Tools.encode("ChangeLineupReq", {
					type = 1,
					lineup = self.forms
				})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)

			gl:retainLoading()
		else

			local strData = Tools.encode("PveReq", {
				checkpoint_id = self.data_.copy_id,
				type = 0,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

			gl:retainLoading()
		end

	end

	if event.name == "ended" and event.target:getName() == "close" then
		playEffectSound("sound/system/return.mp3")

		self:getApp():pushToRootView("LevelScene", {area = math.floor(self.data_.copy_id/1000000), stage = math.floor(self.data_.copy_id/100), index = self.data_.copy_id%100})

	end

end

function CopyOrdinaryLayer:onEnter()
  
	printInfo("CopyOrdinaryLayer:onEnter()")

end

function CopyOrdinaryLayer:onExit()
	
	printInfo("CopyOrdinaryLayer:onExit()")
end

function CopyOrdinaryLayer:createSelectShipNode( ship_info )
	local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/ship_select.csb")

	local conf = CONF.AIRSHIP.get(ship_info.id)

	node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
	node:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")

	node:getChildByName("progress_back"):removeFromParent()
	
	return node
end

function CopyOrdinaryLayer:createSkillShow( skill, pos )
	local conf = CONF.CHECKPOINT.get(self.data_.copy_id)

	local skill_conf = CONF.WEAPON.get(skill)


	if skill_conf.TARGET_1 ~= 0 then
		if skill_conf.TARGET_1 == 4 then
			if skill_conf.TARGET_2 == 1 then

			end
		end

	end
end

function CopyOrdinaryLayer:addFormListener(node)

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

function CopyOrdinaryLayer:resetFormByIndex( index, guid )

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

function CopyOrdinaryLayer:getFormByIndex( index ,lineup)
	assert(index > 0 and index < 10,"error")

	return self.forms[index]
end

function CopyOrdinaryLayer:switchFormByIndex( index1, index2, lineup)
	assert(index1 > 0 and index1 < 10,"error")
	assert(index2 > 0 and index2 < 10,"error")

	local temp = self.forms[index1]
	self.forms[index1] = self.forms[index2]
	self.forms[index2] = temp
end

function CopyOrdinaryLayer:onEnterTransitionFinish()

	printInfo("CopyOrdinaryLayer:onEnterTransitionFinish()")

	-- self:getApp():addView2Top("TalkLayer/TalkLayer", {talk_id = CONF.CHECKPOINT.get(self.data_.copy_id).TALK_ID})

	local rn = self:getResourceNode()

	self.faguang = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/faguang.csb")
	animManager:runAnimByCSB(self.faguang, "FormScene/sfx/faguang.csb", "1")
	rn:addChild(self.faguang)
	self.faguang:setPositionX(-10000)

	local ship_list_ =  player:getForms()

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

	local conf = CONF.CHECKPOINT.get(tonumber(string.format("%d", self.data_.copy_id)))

	rn:getChildByName("e_text"):setString(CONF:getStringValue("EnemyInfo"))
	rn:getChildByName("form"):getChildByName("text"):setString(CONF:getStringValue("form"))
	rn:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("Military"))
	rn:getChildByName("frist"):setString(CONF:getStringValue("front_row"))
	rn:getChildByName("second"):setString(CONF:getStringValue("middle_row"))
	rn:getChildByName("third"):setString(CONF:getStringValue("back_row"))
	rn:getChildByName("enemy_team_0"):setString(CONF:getStringValue("my_forms"))

	rn:getChildByName("enemy_team"):setString(CONF:getStringValue("enemyForm"))

	rn:getChildByName("my_fight"):setString(player:getLineupPower())
	rn:getChildByName("di_fight"):setString(conf.COMBAT)


	rn:getChildByName("strength"):setString(CONF:getStringValue("use strength"))
	rn:getChildByName("strength_num"):setString(conf.STRENGTH)
	rn:getChildByName("strength_num_my"):setString("/"..player:getStrength())

	if tonumber(player:getStrength()) < conf.STRENGTH then
		rn:getChildByName("strength_num"):setTextColor(cc.c4b(255,0,0,255))
		-- rn:getChildByName("strength_num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,-0.5))
	end
	

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
				if proto.type == 0 then
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
					print("enemy_name", enemy_name)
					self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kCheckPoint,Tools.decode("PveResp",strData),true, name, enemy_name})
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("ChangeLineupResp",strData)

			if proto.result < 0 then
				print("error :",proto.result)
			else

				player:setForms(self.forms, {from = "copy"})

				local strData = Tools.encode("PveReq", {
					checkpoint_id = self.data_.copy_id,
					type = 0,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

				gl:retainLoading()

			end
			
		end
	end
		
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	--播放进入动画

	animManager:runAnimByCSB(rn:getChildByName("liuguang"), "Common/sfx/jiemianliuguang3.csb", "1")

	animManager:runAnimOnceByCSB(self:getResourceNode(),"CopyScene/CopyOrdinaryLayer.csb" ,"intro", function ( )

		for i,v in ipairs(conf.MONSTER_LIST) do
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

		rn:getChildByName("strength_num"):setPositionX(rn:getChildByName("strength"):getPositionX() + rn:getChildByName("strength"):getContentSize().width + 5)
		rn:getChildByName("strength_num_my"):setPositionX(rn:getChildByName("strength_num"):getPositionX() + rn:getChildByName("strength_num"):getContentSize().width)
		rn:getChildByName("strength_icon"):setPositionX(rn:getChildByName("strength_num_my"):getPositionX() + rn:getChildByName("strength_num_my"):getContentSize().width + 2)
	end)
end


function CopyOrdinaryLayer:onExitTransitionStart()

	printInfo("CopyOrdinaryLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end

return CopyOrdinaryLayer