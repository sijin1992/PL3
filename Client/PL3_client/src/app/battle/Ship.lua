local animManager = require("app.AnimManager"):getInstance()

local ScaleProgressDelegate = require("util.ScaleProgressDelegate")

local scheduler = cc.Director:getInstance():getScheduler()

local player = require("app.Player"):getInstance()

local Ship = class("Ship")

local last_baozha_time_scale = 0.5

Ship.EAnimStatus = {
	kIdle = 1,
	kAttack = 2,
	kMove = 3,
}

Ship.ETypeStatus = {
	kGray = 0,
	kUseable = 1,
	kUsing = 2,
	kNormal = 3,
}
Ship.EDriverStatus = {
	kNoEnergy = 0,
	kActive = 1,
	kStop = 2,
	kWait = 3,
	kHasEnergyCD = 4,
	kNoEnergyCD = 5,
	kDead = 6,
}

Ship.bm = nil
Ship.renderer = nil
Ship.main = nil

Ship.group = nil
Ship.attr = nil
Ship.valueMax = nil

Ship.orgPos = nil

Ship.index = 0

Ship.cdWaitTime = 0
Ship.cdTimer = 0

Ship.shipSize = cc.size(150,124)

Ship.animStatus = kIdle


function Ship:getAttr(key)
	return self.attr[key]
end

function Ship:setAttr( key, value )
	self.attr[key] = value
end

function Ship:getRenderer()
	return self.renderer
end

function Ship:setHighLight(switch)
	if switch == true then
		self:getRenderer():setLocalZOrder(BattleZOrder.kSfxShip)
		self.ui:setLocalZOrder(BattleZOrder.kSfxShipUI)
	else
		self:getRenderer():setLocalZOrder(BattleZOrder.kShip)
		self.ui:setLocalZOrder(BattleZOrder.kShipUI)
	end
end

function Ship:getIndex()
	return self.index
end

function Ship:getPos( )
	return self.pos
end

function Ship:getSkillConfig(id)

	return CONF.WEAPON.get(id)
end

function Ship:onFrameEvent( str )
	if str == "icon_bg_in" then
		if self.driver then
			self.driver:setVisible(true)
			-- ADD WJJ 20180802
			require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Battle_ShowMyShip(self)
		end
	end
end

function Ship:showNumber( num, isBig, isMiss )

	local label = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/HurtValue.csb")

	local anim_name
	if isMiss == true then
		anim_name = "miss"
	elseif num > 0 then
		if isBig == true then
			anim_name = "big_add"
			label:getChildByName("crit_add_num"):setString("+"..num)
		else
			anim_name = "add"
			label:getChildByName("add_num"):setString("+"..num)
		end

	elseif num < 0 then
		if isBig == true then
			anim_name = "big_sub"
			label:getChildByName("crit_sub_num"):setString(tostring(num))
		else
			anim_name = "sub"
			label:getChildByName("sub_num"):setString(tostring(num))
		end
	end

	if anim_name then
		
		animManager:runAnimOnceByCSB(label, "BattleScene/HurtValue.csb", anim_name, function ()
			label:removeFromParent()
		end)
		self.bm:getUINode():addChild(label)

		local pos = cc.p(self.renderer:getPosition())
		label:setPosition( cc.p(pos.x,pos.y + self.shipSize.height*0.5) )
	end
end

function Ship:ctor( bm, airShip, group, list_index)


	local index = airShip.position

	self.bm = bm
	self.id = airShip.id
	

	local row = math.ceil(index/3)
	local col = math.mod(index,3) == 0 and 3 or math.mod(index,3)

	self.isBigSkilling = false
    

    	--logic index
	self.pos = {group, row, col}
	--
	self.conf_ = CONF.AIRSHIP.get(self.id)
	if self.conf_.SKILL > 0 then
		local cd = CONF.WEAPON.get(self.conf_.SKILL).CD
		self.cdWaitTime = cd
		self.cdTimer = cd
	end

	
	self.group = group

	self.index = index

	self.type = airShip.type

	self.attr = {}
	for i=1,CONF.EShipAttr.kCount do
		self.attr[i] = airShip.attr[i]
	end

	self.attr[CONF.EShipAttr.kMaxHP] = self.attr[CONF.EShipAttr.kHP]

	self.buffs = {}

	self.renderer = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", self.conf_.RES_ID))

 	self.bm:getBulletNode(self.group):addChild(self.renderer,BattleZOrder.kShip)


	self.ui = require("app.ExResInterface"):getInstance():FastLoad(string.format("BattleScene/ShipUI_%d.csb", group))
	self.bm:getBulletNode(group):addChild(self.ui, BattleZOrder.kShipUI)

	

    if self.group == 2 then
		if self.conf_.ICON and self.conf_.ICON == 1 then
	    	local typeNode = require("app.ExResInterface"):getInstance():FastLoad(string.format("BattleScene/ui/sfx/ship_type/ship_type_%d/ship_type_%d.csb", self.type,self.type))
			typeNode:setPosition(self.ui:getChildByName("type"):getPosition())
			self.ui:getChildByName("type"):removeFromParent()
			typeNode:setName("type")
			self.ui:addChild(typeNode)
		end
		self.curTypeStatus = Ship.ETypeStatus.kNormal
		self:setTypeStatus(self.curTypeStatus)

	elseif self.group == 1 then

--		self.ui:getChildByName("driver"):setTexture(string.format("RoleIcon/%d.png", self.conf_.DRIVER_ID))
        self.ui:getChildByName("driver"):setVisible(false)
        self.ui:getChildByName("type"):setVisible(true)
        self.ui:getChildByName("type"):setTexture(string.format("ShipType/%d.png", self.conf_.TYPE))

		local ui_node = self.bm:getUINode()
		local driver_pos = cc.p(ui_node:getChildByName("driver_"..list_index):getPosition())
		self.driver = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/Driver.csb")
		self.driver:setPosition(driver_pos)
		self.driver:setAnchorPoint(cc.p(0, 0))
		ui_node:addChild(self.driver)

		self.driver:setVisible(false)
		if self.type then
			self.driver:getChildByName("type"):setTexture(string.format("ShipType/%d.png", self.type))
		end
		if self.conf_.DRIVER_ID then
--			self.driver:getChildByName("icon"):loadTexture(string.format("RoleIcon/%d.png", self.conf_.DRIVER_ID))
            self.driver:getChildByName("icon"):setVisible(false)
            self.driver:getChildByName("icon2"):setVisible(true)
            self.driver:getChildByName("icon2"):loadTexture(string.format("ShipImage/%d.png", self.conf_.DRIVER_ID))
		end
		if self.conf_.QUALITY then
			self.driver:getChildByName("background"):setTexture(string.format("RankLayer/ui/ui_avatar_%d.png", self.conf_.QUALITY))
		end

		if airShip.ship_break ~= nil and airShip.ship_break > 0 then
			for i=1, airShip.ship_break do
                if self.driver:getChildByName("star_"..i) then
				    self.driver:getChildByName("star_"..i):setTexture("Common/ui/ui_star_light.png")
                end
			end
		end
		if self.conf_.SKILL ~= 0 then
			self.skillConf_ = CONF.WEAPON.get(self.conf_.SKILL)
			assert(self.skillConf_, "error")
			self.driver:getChildByName("no_energy_text"):setString(tostring(self.skillConf_.ENERGY))
			self.driver:getChildByName("has_energy_text"):setString(tostring(self.skillConf_.ENERGY))
			self.driver:getChildByName("stop_energy_text"):setString(tostring(self.skillConf_.ENERGY))
			self.curTypeStatus = Ship.EDriverStatus.kNoEnergy
			self:setDriverStatus(self.curTypeStatus)


			local function onTouchBegan(touch, event)
		
				local target = event:getCurrentTarget()

				local locationInNode = target:convertToNodeSpace(touch:getLocation())

				local s = target:getContentSize()

				local rect = cc.rect(0, 0, s.width, s.height)

				if cc.rectContainsPoint(rect, locationInNode) then

					if self.bm:isPve() == false then
						return
					end
					if self.curTypeStatus ~= Ship.EDriverStatus.kActive then
						return
					end

					if not player:isInited() then
						if g_Player_Guide < 200 then
							if g_guiding_can_skill == false then
								return
							end
						end
					end

					if self.group == 1 and self:isCDTime() == false and self.isBigSkilling == false and self.bm:getEnergy(self.group) >= self.skillConf_.ENERGY then
						local canFight = true
						for k,v in pairs(self.buffs) do
							local buffConf = CONF.BUFF.get(k)
							if buffConf.SPECIAL == CONF.EShipSpecial.kCannotAttack then
								canFight = false
								break
							end
						end
						
						if canFight == true then
					    		local value = self.bm.fightPveManager:doSkill(self.index)
					    		if value == 0 or value == nil then
								return
					    		end
					    		self.bm:setEnergy(self.group, value)
					    		self:setIsBigSkilling(true)
				    		end
				    	end
					return true
				end
				return false
			end

			local listener = cc.EventListenerTouchOneByOne:create()
			listener:setSwallowTouches(true)
			listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
			local eventDispatcher = self.bm:getBattleScene():getEventDispatcher()
			eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.driver:getChildByName("background"))
		end
	end

	local move = nil
	if group == 1 then
		move = cc.p(-400, -230)
	elseif group == 2 then
		move = cc.p(400, 230)
	end

   	local function getBodyPosition( positions )
	    	local count = #positions
	    	if count == 0 then
	    		return nil
	    	end
	    	if count == 1 then
	    		return bm:getShipPos(group,positions[1])
	    	else

	    		local p1 = bm:getShipPos(group,positions[1])
	    		local p2 = bm:getShipPos(group,positions[count])

	    		return cc.pMidpoint(p1,p2)
	    	end
    	end

	self.renderPos = getBodyPosition(airShip.body_position)

	self:setPosition(cc.pAdd(self.renderPos, move))

	local function moveOK(node)
		self:setPosition(self.renderPos)
		self:idle()

	end
	self:move()

	self.renderer:runAction(cc.Sequence:create(cc.DelayTime:create(1 + col*0.5),cc.MoveTo:create(0.5,self.renderPos),cc.CallFunc:create(moveOK)))
end

function Ship:getGroup()
	return self.group
end

function Ship:getID( )
	return self.id
end

function Ship:setIsBigSkilling( flag)
	self.isBigSkilling = flag
end

function Ship:setDriverStatus( status )
	print("setDriverStatus", status)
	if status == Ship.EDriverStatus.kNoEnergy then

		animManager:runAnimOnceByCSB(self.driver, "BattleScene/Driver.csb", "no_energy")

	elseif status == Ship.EDriverStatus.kActive then

		animManager:runAnimByCSB(self.driver, "BattleScene/Driver.csb", "active")

	elseif status == Ship.EDriverStatus.kStop then

		animManager:runAnimOnceByCSB(self.driver, "BattleScene/Driver.csb", "stop")

	elseif status == Ship.EDriverStatus.kWait then

		animManager:runAnimByCSB(self.driver, "BattleScene/Driver.csb", "wait")

	elseif status == Ship.EDriverStatus.kHasEnergyCD then

		animManager:runAnimOnceByCSB(self.driver, "BattleScene/Driver.csb", "has_energy_cd")

	elseif status == Ship.EDriverStatus.kNoEnergyCD then

		animManager:runAnimOnceByCSB(self.driver, "BattleScene/Driver.csb", "no_energy_cd")

	elseif status == Ship.EDriverStatus.kDead then

		animManager:runAnimOnceByCSB(self.driver, "BattleScene/Driver.csb", "dead")
        self.driver:getChildByName("cd_text"):setVisible(false)
        self.driver:getChildByName("dead_text"):setVisible(true)
		self.driver:getChildByName("dead_text"):setString(CONF:getStringValue("dead"))
	end
end

function Ship:checkDriverStatus()

	if self.curTypeStatus == Ship.EDriverStatus.kDead then
		return
	end

	local canFight = true
	for k,v in pairs(self.buffs) do
		local buffConf = CONF.BUFF.get(k)
		if buffConf.SPECIAL == CONF.EShipSpecial.kCannotAttack then
			canFight = false
			break
		end
	end

	if canFight == false then

		if self.curTypeStatus ~= Ship.EDriverStatus.kStop then
			self.isBigSkilling = false
			self.curTypeStatus = Ship.EDriverStatus.kStop
			self:setDriverStatus(self.curTypeStatus)
		end

	elseif self.isBigSkilling == true then

		if self.curTypeStatus ~= Ship.EDriverStatus.kWait then
			self.curTypeStatus = Ship.EDriverStatus.kWait
			self:setDriverStatus(self.curTypeStatus)
		end
	elseif self:isCDTime() == true and self.skillConf_ ~= nil and self.bm:getEnergy(self.group) >= self.skillConf_.ENERGY then

		if self.curTypeStatus ~= Ship.EDriverStatus.kHasEnergyCD then
			self.curTypeStatus = Ship.EDriverStatus.kHasEnergyCD
			self:setDriverStatus(self.curTypeStatus)
		end

	elseif self:isCDTime() == true and self.skillConf_ ~= nil and self.bm:getEnergy(self.group) < self.skillConf_.ENERGY then

		if self.curTypeStatus ~= Ship.EDriverStatus.kNoEnergyCD then
			self.curTypeStatus = Ship.EDriverStatus.kNoEnergyCD
			self:setDriverStatus(self.curTypeStatus)
		end

	elseif self:isCDTime() == false and self.skillConf_ ~= nil and self.bm:getEnergy(self.group) >= self.skillConf_.ENERGY then

		local status
	
		if player:isInited() == false and g_guide_hero_active > 0 then
			if g_guide_hero_active == self:getIndex() then
				status = Ship.EDriverStatus.kActive
			else
				status = Ship.EDriverStatus.kNoEnergy
			end
		else
			status = Ship.EDriverStatus.kActive

			-- ADD WJJ 20180718 BUG
			local _bts = self.bm:getBattleScene()
			if( (_bts ~= nil) and ( _bts.getBattleType ~= nil ) and ( _bts:getBattleType() ~= nil )  ) then
				if self.bm:isPve() 
				and _bts:getBattleType() == BattleType.kCheckPoint 
				and _bts:getData().checkpoint_id == 1000001 then
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("SkillActive")
				end
			end
		end


		if self.curTypeStatus ~= status then
			self.curTypeStatus = status
			self:setDriverStatus(self.curTypeStatus)
		end
	else
		if self.curTypeStatus ~= Ship.EDriverStatus.kNoEnergy then

			self.curTypeStatus = Ship.EDriverStatus.kNoEnergy
			self:setDriverStatus(self.curTypeStatus)
		end
	end
end

function Ship:setTypeStatus( status )
	 if self.group == 2 then
		if self.conf_.ICON and self.conf_.ICON == 2 then
			return
		end
	end
	animManager:runAnimByCSB(self.ui:getChildByName("type"), string.format("BattleScene/ui/sfx/ship_type/ship_type_%d/ship_type_%d.csb", self.type,self.type), string.format("%d",status))
end

function Ship:checkTypeStatus()

	if self.group == 2 then

		return
	end

	local canFight = true
	for k,v in pairs(self.buffs) do
		local buffConf = CONF.BUFF.get(k)
		if buffConf.SPECIAL == CONF.EShipSpecial.kCannotAttack then
			canFight = false
			break
		end
	end

	if canFight == false then

		self.curTypeStatus = Ship.ETypeStatus.kGray
		self:setTypeStatus(self.curTypeStatus)
		self.isBigSkilling = false

	elseif self.isBigSkilling == true then

		if self.curTypeStatus ~= Ship.ETypeStatus.kUsing then

			self.curTypeStatus = Ship.ETypeStatus.kUsing
			self:setTypeStatus(self.curTypeStatus)
		end
		
	elseif self:isCDTime() == false and self.bm:getEnergy(self.group) >= self.skillConf_.ENERGY then

		if self.curTypeStatus ~= Ship.ETypeStatus.kUseable then

			self.curTypeStatus = Ship.ETypeStatus.kUseable
			self:setTypeStatus(self.curTypeStatus)
		end 
	else

		if self.curTypeStatus ~= Ship.ETypeStatus.kGray then

			self.curTypeStatus = Ship.ETypeStatus.kGray
			self:setTypeStatus(self.curTypeStatus)
			
		end
	end
end



function Ship:startCD()
	self:setIsBigSkilling(false)
    	self.cdTimer = 0
end

function Ship:setPosition( p )
	
	self.renderer:setPosition(p)

	self.orgPos = p
	
	self.ui:setPosition(p)
end

function Ship:move()
	if self.renderer == nil then
		return
	end
	self.renderer:stopAllActions()

	animManager:runAnimByCSB(self.renderer, string.format("sfx/%s", self.conf_.RES_ID), string.format("move_%d", self.group))
	self.animStatus = Ship.EAnimStatus.kMove
end

function Ship:idle()

	if self.renderer == nil then
		return
	end

	self.renderer:stopAllActions()

	animManager:runAnimByCSB(self.renderer, string.format("sfx/%s", self.conf_.RES_ID), string.format("idle_%d", self.group))

	local n = self.bm:getInfoByKey(self.group,"bullet_direct")


	local min = cc.pAdd(self.orgPos,cc.pMul(n,-math.random() * 5))
	local max = cc.pAdd(self.orgPos,cc.pMul(n,math.random() * 5))
	
	local idle = cc.Sequence:create(cc.MoveTo:create(1, min),cc.MoveTo:create(1, max))
	self.renderer:runAction(cc.RepeatForever:create(idle))

	self.animStatus = Ship.EAnimStatus.kIdle
end

function Ship:attack(buff_index)

	if self.renderer == nil then
		return
	end

	local function attackOk()
		self:idle()
	end

	local res_name
	if buff_index == nil then
		res_name = string.format("attack_%d", self.group)
	else
		res_name = string.format("buff_%d", self.group)
	end

	local has = animManager:runAnimOnceByCSB(self.renderer, string.format("sfx/%s", self.conf_.RES_ID), res_name, attackOk)
	
	self.animStatus = Ship.EAnimStatus.kAttack

	if has == false then
		self:idle()
	end
end

function Ship:getAnimStatus( )
	return self.animStatus
end

function Ship:setStatus( status)
	if status == nil then
		return
	end

	local Bit = require "Bit"

	if Bit:has(status, CONF.EShipStatus.kDead) == true then

		self:disapper()

	elseif Bit:has(status, CONF.EShipStatus.kMiss) == true then

		self:showNumber(nil, nil, true)
	end
end

function Ship:hurt()
	if self.conf_.KIND ~= 4 then--BOSS没有受击动画
		self.renderer:stopAllActions()
		local n = self.bm:getInfoByKey((self.group == 1 and 2) or 1,"bullet_direct")
		local dir = cc.pAdd(self.orgPos,cc.pMul(n, 10))
		local function actionOk( )
			self:idle()
		end
		
		local hurt_action = cc.Sequence:create(
			cc.MoveTo:create(0.1, dir), 
			cc.MoveTo:create(0.05, cc.pAdd(dir, cc.p(0, 4))), 
			cc.MoveTo:create(0.05, cc.pAdd(dir, cc.p(0, -9))),
			cc.CallFunc:create(actionOk)
		)

		self.renderer:runAction(hurt_action)
	end
end

function Ship:setDead(  )
	if self.baozha then
		self.baozha:setVisible(false)
	end
	

	self.bm:getBattleScene():setPosition(0,0)
end

function Ship:disapper()

	for k,v in pairs(self.buffs) do
    		if v.renderer then
    			v.renderer:stopAllActions()
    			v.renderer:removeFromParent()
    		end
		self.buffs[k] = nil
	end

	self.renderer:stopAllActions()

	local pos = cc.p(self.renderer:getPosition())
	local zorder = self.renderer:getLocalZOrder()
	self.renderer:setVisible(false)

	local function actionOk()
		self:setDead()
		
		if scheduler:getTimeScale() == last_baozha_time_scale then
			scheduler:setTimeScale(1)
		end
	end

	if self.group == 1 and self.curTypeStatus ~= Ship.EDriverStatus.kDead then
		self.curTypeStatus = Ship.EDriverStatus.kDead
		self:setDriverStatus(self.curTypeStatus)
	end

	self.baozha = require("app.ExResInterface"):getInstance():FastLoad("sfx/fightSfx/baozha/baozha.csb")

	self.bm:getBulletNode(self.group):addChild(self.baozha,zorder)

	self.baozha:setPosition(pos)


    	animManager:runAnimOnceByCSB(self.baozha, "sfx/fightSfx/baozha/baozha.csb", "run", actionOk)

	playEffectSound("sound/effect/baozha.mp3")
	
	if self.bm:isLastShip(self.group) == true then
		scheduler:setTimeScale(last_baozha_time_scale)
	else
		self.bm:getBattleScene():runAction(mc.Shake:create(0.3,5))
	end

	self.ui:setVisible(false)
end

function Ship:updateUIHp()
	local percent = self.attr[CONF.EShipAttr.kHP] / self.attr[CONF.EShipAttr.kMaxHP] * 100

	if percent > 0 and percent < 10 then
		percent = 10
	end

	local loadingbar = self.ui:getChildByName("loadingbar")
	local delegate = ScaleProgressDelegate:create(loadingbar, loadingbar:getTag())
	delegate:setPercentage( percent)
end

function Ship:showHPHurt(value, status)
	local isBig = false
	if status then
		local Bit = require "Bit"
		if Bit:has(status, CONF.EShipStatus.kCrit) == true then
			isBig = true
		end
	end

	if math.abs(value) > 10 then

		value = value + math.random(-5, 5)
	end

	self:showNumber(value, isBig)
end

function Ship:getHurt(key, value, status, noShow)

	local function setHp(value, noShow)
		if self.attr[CONF.EShipAttr.kHP] <= 0 then
			printInfo("error !!!!!!!!!!!!!!!!!!", self.attr[CONF.EShipAttr.kHP] <= 0)
		end

		local oldHp = self.attr[CONF.EShipAttr.kHP]

		self.attr[CONF.EShipAttr.kHP] = self.attr[CONF.EShipAttr.kHP] + value

		if self.attr[CONF.EShipAttr.kHP] < 0 then

			self.attr[CONF.EShipAttr.kHP] = 0

		elseif self.attr[CONF.EShipAttr.kHP] > self.attr[CONF.EShipAttr.kMaxHP] then

			self.attr[CONF.EShipAttr.kHP] = self.attr[CONF.EShipAttr.kMaxHP]
		end

		local changeHP = self.attr[CONF.EShipAttr.kHP] - oldHp

		self:updateUIHp()

		local pos = cc.p(self.renderer:getPosition())

		printInfo("setHp",value, changeHP, self:getIndex())

		if noShow == nil or noShow == false then
			self:showHPHurt(value, status)
		end

		self.bm:setHP(self.group, changeHP)
	end


	local function setEnergy(value, noShow)
		if value == 0 then
			return
		end
		if value > 0 then
			self.bm:setEnergy(self.group, value, cc.p(self.renderer:getPosition()))
		else
			self.bm:setEnergy(self.group, value)
		end
		
	end

	local function setShield( value, noShow )

		local oldShield = self.attr[CONF.EShipAttr.kShield]
		self.attr[CONF.EShipAttr.kShield] = self.attr[CONF.EShipAttr.kShield] + value
		if self.attr[CONF.EShipAttr.kShield] < 0 then
			self.attr[CONF.EShipAttr.kShield] = 0
		end

		if oldShield > 0 and self.attr[CONF.EShipAttr.kShield] <= 0 then -- 护盾失效

			for k,v in pairs(self.buffs) do
				local buffConf = CONF.BUFF.get(k)
				if buffConf and buffConf.DEST_KEY == CONF.EShipAttr.kShield then
					if self.buffs[k].renderer then
						self.buffs[k].renderer:setVisible(false)
					end
				end
			end
		elseif oldShield <= 0 and  self.attr[CONF.EShipAttr.kShield] > 0 then
			for k,v in pairs(self.buffs) do
				local buffConf = CONF.BUFF.get(k)
				if buffConf and buffConf.DEST_KEY == CONF.EShipAttr.kShield then
					if self.buffs[k].renderer then
						self.buffs[k].renderer:setVisible(true)
					end
				end
			end
		end

		if noShow == false or noShow == nil then

			if value ~= 0 then
				self:showAttrLabel( key, value)
			end
		end
	end

	
	if key == CONF.EShipAttr.kHP then
		setHp(value, noShow)
	elseif key == CONF.EShipAttr.kAnger then
		setEnergy(value, noShow)
	elseif key == CONF.EShipAttr.kShield then
		setShield(value, noShow)
	else
		self:showAttrLabel(key, value)
	end
end

function Ship:changedEnergy( )

	if self.group == 1 then
		-- local energyNeed = self.ui:getChildByName("angry")
		-- if self.bm:getEnergy(self.group) >= self.skillConf_.ENERGY then
			
		-- 	energyNeed:setTextColor(cc.c4b(255,0,0,255))
		-- 	energyNeed:enableOutline(cc.c4b(217,0,0,255))
		-- else
		-- 	energyNeed:setTextColor(cc.c4b(18,252,255,255))
		-- 	energyNeed:enableOutline(cc.c4b(18,252,255,255))
		-- end
	end

end

function Ship:reset(key,value)

	if value == 0 then
		return
	end

	
end


function Ship:addBuff( buffId, weaponId )

	if buffId <= 0 then
		return
	end
	printInfo("add buffId : ", buffId, "weapon id",weaponId)

	local conf = CONF.BUFF.get(buffId)
	local weaponConf = CONF.WEAPON.get(weaponId)


	local function createAnim( res )
		if res == nil then
			return nil
		end

		assert(res ~= nil,"error")

		local node = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", res))

		node:setPosition(0,0)
		self.renderer:addChild(node)

		local animName = "run"
		if self.group == 2 then
			if animManager:isAnimExistsByCSB(string.format("sfx/%s", res), "run_2") then
				animName = "run_2"
			else
				node:setScaleX(-1)
			end
		end

		if conf.LOGIC_ID == "RepeatBuff" then
			animManager:runAnimByCSB(node, string.format("sfx/%s", res), animName)
		else
			animManager:runAnimOnceByCSB(node, string.format("sfx/%s", res), animName)
		end

		return node
	end

	local function addIcon( buffID, buffConf, flag )

		self.iconList_ = self.iconList_ or {}

		
		local icon = cc.Sprite:create(string.format("BuffIcon/%d.png", buffConf.ICON_ID))
		if not icon then
			return
		end

		table.insert(self.iconList_, {id = buffID, icon = icon})
		icon:retain()
		if buffConf.ICON_DEBUFF == 0 then
			icon:setColor((flag == true and cc.GREEN) or cc.RED)
		else
			icon:setColor((flag == true and cc.RED) or cc.GREEN)
		end
		icon:setScale(0.5)


		local count = #self.iconList_
		if count > 3 then
			return
		end
		self.ui:addChild(icon)
		icon:setPosition(self.ui:getChildByName( string.format("icon_%d",count) ):getPosition() )
	end

	local function getBuffIndexByWeaponConf( weaponConf )
		
		for i,v in ipairs(weaponConf.BUFF_ID) do
			if v == buffId then
				return i
			end
		end
		return nil
	end

	local buffIndexInWeaponConf = getBuffIndexByWeaponConf(weaponConf)
	assert(buffIndexInWeaponConf, "error")

	--add buff attr label

	if conf.SHOW_DETAIL ~= 1 and conf.DEST_KEY ~= CONF.EShipAttr.kHP then-- and (conf.DEST_KEY ~= CONF.EShipAttr.kAnger )
		local keyStr = CONF.STRING.get(conf.MEMO_ID).VALUE
		
		local value = weaponConf.BUFF_ATTR_PERCENT[buffIndexInWeaponConf]
		local isPercent = true
		if value == 0 then
			value = weaponConf.BUFF_ATTR_VALUE[buffIndexInWeaponConf]
			isPercent = false
		end

		self:showAttrLabel(conf.DEST_KEY, value, isPercent, conf.STR_DEBUFF == 1, keyStr)
	end
	
	if self.buffs[buffId] ~= nil then

		self.buffs[buffId].count = self.buffs[buffId].count + 1
		self.buffs[buffId].renderer:setVisible(true)
		return
	end


	local node
	if type(conf.RES_ID) ~= "string" and Tools.isEmpty(conf.RES_ID) == false then

		local index = 1
		if weaponConf.BUFF_ATTR_PERCENT[buffIndexInWeaponConf] < 0 or weaponConf.BUFF_ATTR_VALUE[buffIndexInWeaponConf] < 0 then
			index = 2
		end

		if conf.RES_ID[2] == nil then
			node = createAnim(conf.RES_ID[1])
		else
			node = createAnim(conf.RES_ID[index])
		end

		if conf.ICON_ID and conf.ICON_ID ~= 0 then
			addIcon(buffId, conf, index == 1)
		end
	end

	self.buffs[buffId] = {renderer = node,count = 1}
end

function Ship:showAttrLabel( key, value, isPercent, isDebuff, keyStr)

	if self.renderer:isVisible() == false then
		return
	end

	if isDebuff == true then

		value = -value
	end

	if keyStr == nil then
		keyStr = CONF.STRING.get( string.format("Attr_%d", key) ).VALUE
	end


	local node = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/AttrLabel.csb")
	local animName

	if key == 0 then
		if isDebuff == true then
			animName = "add"
		else
			animName = "sub"
		end
		node:getChildByName(animName):setString(string.format("%s", keyStr))
	else

		local sign = ""
		local strValue
		if isPercent == true then

			if value > 0 then
				sign = "+"
			end
			
			strValue = string.format("%d%%", value)
		else
			if value > 0 then
				sign = "+"
			end
			local isPercentValue = false
			for k,num in pairs(CONF.ShipPercentAttrs) do
				if num == key then
					isPercentValue = true
					break
				end
			end
			if isPercentValue == true then
				strValue = string.format("%d%%", value)
			else
				strValue = string.format("%d", value)
			end
		end
		
		if isDebuff == true then
			if sign == "+" then
				animName = "sub"
			else
				animName = "add"
			end
		else
			if sign == "+" then
				animName = "add"
			else
				animName = "sub"
			end
		end
		node:getChildByName(animName):setString(string.format("%s%s%s", keyStr,sign,strValue))
	end

	animManager:runAnimOnceByCSB(node, "BattleScene/AttrLabel.csb", animName, function ()
		node:removeFromParent()
	end)
	node:setPosition(self.renderer:getPosition())
	self.bm:getUINode():addChild(node)
	--self.renderer:addChild(node)
end

function Ship:removeBuff( buffId )

	local function removeAnim( buffId )
		
		if self.buffs[buffId].renderer then
			self.buffs[buffId].renderer:removeFromParent()

			self.buffs[buffId].renderer = nil
		end
	end

	local function removeIcon( buffId )
		local flag = false
		if self.iconList_ == nil then
			return
		end
		for i,v in ipairs(self.iconList_) do
			if v.id == buffId then
				if i < 4 then
					flag = true
					v.icon:removeFromParent()
				end
				v.icon:release()
				table.remove(self.iconList_,i)
				break
			end
		end

		if flag then
			for i,v in ipairs(self.iconList_) do
				if i > 3 then
					break
				end
				if not v.icon:getParent() then

					self.ui:addChild(v.icon)
				end
				v.icon:setPosition(self.ui:getChildByName( string.format("icon_%d",i) ):getPosition() )
			end
		end
		

	end


	printInfo("removeBuff buffId : ",buffId)
	if buffId > 0 then
		return
	end
	buffId = -buffId

	if self.buffs[buffId] ~= nil then

		self.buffs[buffId].count = self.buffs[buffId].count - 1

		if self.buffs[buffId].count < 1 then
			removeAnim(buffId)
			removeIcon(buffId)

			self.buffs[buffId].count = nil
			self.buffs[buffId] = nil
		end
	else
		printInfo("warning: buffid already remove", buffId)
	end
end

function Ship:isCDTime( )
	--printInfo("isCDTime", self.cdTimer, self.cdWaitTime)
	return self.cdTimer < self.cdWaitTime
end

function Ship:update(dt)

	if self.bm.updateSwitch == false then
		return
	end

	if self.curTypeStatus == Ship.EDriverStatus.kDead then
		return
	end



	if self:isCDTime() == true then

		self.cdTimer = self.cdTimer + dt

		-- ADD WJJ 20180803
		-- shan tui bug fix
		if (self.driver and (cc.exports.G_is_battle_over ~= true)) then

			-- bug fix wjj 20180718
			local _cd_bar_node = self.driver:getChildByName("cd_bar")
			if( _cd_bar_node ~= nil )then
				_cd_bar_node:setPercent( 100 - self.cdTimer / self.cdWaitTime * 100 )
				if self.cdTimer >= self.cdWaitTime then
					_cd_bar_node:setPercent(0)
				end
			end

			local time = math.max(self.cdWaitTime - self.cdTimer, 0)
            self.driver:getChildByName("cd_text"):setVisible(true)
            self.driver:getChildByName("dead_text"):setVisible(false)
			self.driver:getChildByName("cd_text"):setString(tostring(math.floor(time)).."s")
		end
	end

	
	if self.group == 1 then
		self:checkDriverStatus()
	end
end

function Ship:resume()

	self:getRenderer():resume()

	for k,v in pairs(self.buffs) do
		if v.renderer ~= nil and type(v.renderer) ~= "number" then
			v.renderer:resume()
		end
	end
end

function Ship:pause()

	self:getRenderer():pause()
	
	for k,v in pairs(self.buffs) do
		if v.renderer ~= nil and type(v.renderer) ~= "number" then
			v.renderer:pause()
		end
	end
end


return Ship