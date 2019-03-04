
local FightBuff = require("FightLogic.FightBuff")
local FightEvent = require("FightLogic.FightEvent")

local FightShip = class("FightShip")


function FightShip:ctor(fm, data, pos )

	self.fm_ = fm

	self.data_ = data

	self.status_ = CONF.EShipStatus.kNil

	self.special_ = {}

	self.data_.attr[CONF.EShipAttr.kMaxHP] = self.data_.attr[CONF.EShipAttr.kHP]
	self.data_.attr[CONF.EShipAttr.kFightValue] = 0

	self.buffs_ = {}

	self.mainPos_ = pos

	self.lastSkillTime_ = 0
end
function FightShip:getID()
	return self.data_.id
end

function FightShip:getQuality()
	return self.data_.quality
end

function FightShip:getLevel()
	return self.data_.level
end

function FightShip:getPos()
	return self.mainPos_
end

function FightShip:getAttrByKey( key )
	if key == CONF.EShipAttr.kAnger then
		return self.fm_:getAnger(self:getPos()[1])
	end

	return self.data_.attr[key]
end


function FightShip:setAttrByKey( key, value )

	local flag = true
	if key == CONF.EShipAttr.kAnger then
		
		flag = self.fm_:setAnger(self:getPos()[1],value)
	else
		self.data_.attr[key] = value
	end

	if key == CONF.EShipAttr.kHP then

		if self.data_.attr[key] > self.data_.attr[CONF.EShipAttr.kMaxHP] then

			if self.record_ and self.record_.overValues[key] then
				self.record_.overValues[key] = self.data_.attr[key] - self.data_.attr[CONF.EShipAttr.kMaxHP]
			end
			self.data_.attr[key] = self.data_.attr[CONF.EShipAttr.kMaxHP]

		elseif self.data_.attr[key] < 0 then
			if self.record_ and self.record_.overValues[key] then
				self.record_.overValues[key] = self.data_.attr[key]
			end
			self.data_.attr[key] = 0
		end
	end

	if self.record_ and self.record_.watchKeys and type(self.record_.watchKeys[key]) == "boolean" then
		self.record_.watchKeys[key] = true
	end
	return flag
end

function FightShip:isCanHurt()
	if self.status_ == CONF.EShipStatus.kDead then
		return false
	end
	return true
end

function FightShip:isCanFight()
	return self:getAttrByKey(CONF.EShipAttr.kSpeed) > 0 and self:hasSpecial(CONF.EShipSpecial.kCannotAttack) == false
end

function FightShip:hasSpecial(key)
	if self.special_[key] ~= nil and self.special_[key] > 0 then
		return true
	end
	return false
end

function FightShip:addSpecial( key )

	if self:hasSpecial(key) == true then

		self.special_[key] = self.special_[key] + 1
	else
		self.special_[key] = 1
	end
end

function FightShip:removeSpecial( key )
	
	assert(self.special_[key],string.format("error key", key) )

	self.special_[key] = self.special_[key] - 1
	if self.special_[key] <= 0 then
		self.special_[key] = nil
	end
end

function FightShip:getTargetByConf(key1, key2, key3, isTest)
	if key1 == CONF.EShipTarget_1.kSelf then

		if isTest and isTest == true then
			return {self:getPos()}
		end
		return {self}

	elseif key1 == CONF.EShipTarget_1.kAttacker then
		if isTest and isTest == true then
			return nil
		end
		return self.fm_:getAttackers()

	elseif key1 == CONF.EShipTarget_1.kHurter  then
		if isTest and isTest == true then
			return nil
		end
		return self.fm_:getHurters()
	end

	local isSameGroup
	if key1 == CONF.EShipTarget_1.kOur then
		isSameGroup = true
	elseif key1 == CONF.EShipTarget_1.kEnemy then
		isSameGroup = false
	end

	
	if key2 == CONF.EShipTarget_2.kOne then
		
		return self.fm_:getShipsByOne(isSameGroup, self:getPos(), isTest)

	elseif key2 == CONF.EShipTarget_2.kFrontCol then

		return self.fm_:getShipsByCol(isSameGroup, self:getPos(), false, isTest)

	elseif key2 == CONF.EShipTarget_2.kBackCol then

		return self.fm_:getShipsByCol(isSameGroup, self:getPos(), true, isTest)

	elseif key2 == CONF.EShipTarget_2.kRow then

		return self.fm_:getShipsByRow(isSameGroup, self:getPos(), isTest)

	elseif key2 == CONF.EShipTarget_2.kRand then

		return self.fm_:getShipsByRand(isSameGroup, self:getPos(), key3, isTest)

	elseif key2 == CONF.EShipTarget_2.kValueMax then

		return self.fm_:getShipsByAttr(isSameGroup, self:getPos(), key3, true, isTest)

	elseif key2 == CONF.EShipTarget_2.kValueMin then

		return self.fm_:getShipsByAttr(isSameGroup, self:getPos(), key3, false, isTest)

	elseif key2 == CONF.EShipTarget_2.kAll then

		return self.fm_:getShipsByRand(isSameGroup, self:getPos(), 0, isTest)
	end
	return nil
end

function FightShip:addBuff( buff )
	if self.buffs_ == nil then
		return
	end
	table.insert(self.buffs_, buff)
end

function FightShip:clearBuff( isDeff )

	if self.buffs_ == nil then
		return
	end
	local event = FightEvent:create(FightEvent.EventType.kBuff)

	for i=#self.buffs_,1, -1 do
		local flag = false
		if isDeff == true then
			flag = self.buffs_[i]:isDebuff()
		else
			flag = self.buffs_[i]:isGoodBuff()
		end
		if flag then
			self.buffs_[i]:remove(event)
			table.remove(self.buffs_, i)
		end
	end

	if event:isHurterEmpty() == false then
		self.fm_:pushEvent(event:getEvent())
	end
end

function FightShip:createBuff(weaponConf, buff_index)

	--printInfo("createBuff",weaponConf.ID,weaponConf.BUFF_ID[1])
	local buffEvent = FightEvent:create(FightEvent.EventType.kCreateBuff, {weaponConf.ID, buff_index}, { {pos = self:getPos()}, })

	--这里先放进队列 然后设置参数 是为了让buff动画先放 效果在后
	if buffEvent then
	
		self.fm_:pushEvent(buffEvent:getEvent())
	end

	
	local targets = self:getTargetByConf(weaponConf.BUFF_TARGET_1[buff_index], weaponConf.BUFF_TARGET_2[buff_index], weaponConf.BUFF_TARGET_3[buff_index])
	local hit = weaponConf.BUFF_CONDITION_PERCENT[buff_index] * 0.01
	local flag 
	for i,v in ipairs(targets) do
		flag = hit >= math.random()

		local buff = FightBuff:create(self.fm_, v, weaponConf, buff_index, {[CONF.EShipAttr.kHP] = -self:getAttrByKey(CONF.EShipAttr.kAttackDurationAddition)})

		if flag then

			if buff:isDebuff() == true and v:hasSpecial(CONF.EShipSpecial.kImmuneDebuff) == true then
	
				if buffEvent then
					buffEvent:addHurter({pos = v:getPos(),})
				end
			else
				local hasBuff = v:getBuffByID(buff:getID())
				if hasBuff then
	
					hasBuff:overlay(buff)
				else
					
					buff:doLogic(CONF.EBuffTrigger.kCreate)
					v:addBuff(buff)
				end

				if buffEvent then
					buffEvent:addHurter({pos = v:getPos(), buffs = {weaponConf.BUFF_ID[buff_index]}})
				end

			end
			

		else

			if buffEvent then
				buffEvent:addHurter({pos = v:getPos(),})
			end
		end


	end


	
end



function FightShip:calCreateBuff(weaponConf, condition)

	if not Tools.isEmpty(weaponConf.BUFF_ID) and weaponConf.BUFF_ID[1] ~= 0 then

		for i,v in ipairs(weaponConf.BUFF_ID) do

			if weaponConf.BUFF_CONDITION_TYPE[i] == condition then

				self:createBuff(weaponConf, i)
			end
		end
	end
end

function FightShip:calRemoveBuff(round)
	if self.buffs_ == nil then
		return
	end

	local event = FightEvent:create(FightEvent.EventType.kBuff)

	local i, max = 1, #self.buffs_
	while i <= max do
		if self.buffs_[i]:calRound(round, event) <= 0 then
			table.remove(self.buffs_, i)
			i = i - 1
			max = max - 1
		end
		i = i + 1
	end

	if event:isHurterEmpty() == false then
		self.fm_:pushEvent(event:getEvent())
	end
end

function FightShip:checkBuffs(trigger)
	if self.buffs_ == nil then
		return
	end
	for i,v in ipairs(self.buffs_) do
		v:doLogic(trigger)
	end
end


function FightShip:hasBuff( id )
	if self.buffs_ == nil then
		return false
	end
	for i,v in ipairs(self.buffs_) do
		if v:getID() == id then
			return true
		end
	end

	return false
end

function FightShip:getBuffByID( id )
	if self.buffs_ == nil then
		return nil
	end
	for i,v in ipairs(self.buffs_) do
		if v:getID() == id then
			return v
		end
	end

	return nil
end

function FightShip:getWeaponConfByIndex( index )

	local id = self.data_.weapon_list[index]
	if id == 0 then
		local shipConf = CONF.AIRSHIP.get(self.data_.id)
		id = shipConf.WEAPON_LIST[index]
	end

	return CONF.WEAPON.get(id)
end

function FightShip:getWeaponConfBySkill()

	local id = CONF.AIRSHIP.get(self.data_.id).SKILL
	if id == 0 then
		return nil
	end

	return CONF.WEAPON.get(id)
end

function FightShip:isCureSkill(  )
	local conf = self:getWeaponConfBySkill()

	if conf.SIGN == 2 then
		return true
	end

	if Tools.isEmpty(conf.BUFF_ID) == false then
		for i,v in ipairs(conf.BUFF_ID) do
			if v > 0 then
				local buffConf = CONF.BUFF.get(v)
				if buffConf.CURE == 1 then
					return true
				end
			end
		end
	end
	return false
end

function FightShip:getWeaponConfByDefault(index)
	local conf = CONF.AIRSHIP.get(self.data_.id)
	local weaponID = 0
	if conf.KIND == 1 then
		weaponID = conf.WEAPON_LIST[index]
	else
		--怪物挑选一个普通攻击
		for i,v in ipairs(conf.WEAPON_LIST) do
			if v <= 2020 and v > 2000 then
				weaponID = v
				break
			end
		end
		if weaponID == 0 then
			weaponID = conf.WEAPON_LIST[index]
		end
	end
	return CONF.WEAPON.get(weaponID)
end

function FightShip:_doWeapon(weaponConf, curRound, isFightBack, hurters)

	self.fm_:resetAttackers({self})

	if hurters ~= nil and Tools.isEmpty(hurters) == false then
		self.hurters_ = hurters
	end

	if weaponConf and weaponConf.TARGET_1 ~= 0 and hurters == nil then
		self.hurters_ = self:getTargetByConf(weaponConf.TARGET_1, weaponConf.TARGET_2, weaponConf.TARGET_3)
	end
	
	
	self.fm_:resetHurters(self.hurters_)

	if curRound and curRound > 0 then
		self:checkBuffs(CONF.EBuffTrigger.kRoundStart)
	end

	if weaponConf then
		self:calCreateBuff(weaponConf, CONF.EBuffCondition.kNow)

		if self:isDead() == false then

			self:checkBuffs(CONF.EBuffTrigger.kAttack)
			self:attack( weaponConf, isFightBack )
			
			self:checkBuffs(CONF.EBuffTrigger.kAttacked)
		end

		
	end

	if curRound and curRound > 0 then
		self:checkBuffs(CONF.EBuffTrigger.kRoundEnd)
	end
	if self.hurters_ then
		for i,v in ipairs(self.hurters_) do
			v:setAttrByKey(CONF.EShipAttr.kHurtValue, 0)
		end
	end
	
	self:setAttrByKey(CONF.EShipAttr.kAttackValue, 0)

	self.hurters_ = nil
	self.fm_:resetHurters(nil)
	self.fm_:resetAttackers(nil)

	self.fm_:addTime(5)
end


function FightShip:doSkill()

	if self.fm_:isGroupDead(self:getPos()[1] == 1 and 2 or 1) == true then
		print("error doSkill 1")
		return
	end

	if self.data_.attr[CONF.EShipAttr.kHP] <= 0 or self.status_ == CONF.EShipStatus.kDead then
		print("error doSkill 2")
		return
	end

	
	local weaponConf = self:getWeaponConfBySkill()
	if not weaponConf then
		print("error doSkill 3")
		return
	end

	-- if self:getAttrByKey(CONF.EShipAttr.kAnger) < weaponConf.ENERGY then
	-- 	return
	-- end

	if self:isCanFight() == false then
		print("error doSkill 4")
		return
	end
	
	self:_doWeapon(weaponConf)

	self:calRemoveBuff(0)

	self.lastSkillTime_ = self.fm_:getTime()
end

function FightShip:isSmallHP( )
	return (self:getAttrByKey(CONF.EShipAttr.kHP) / self:getAttrByKey(CONF.EShipAttr.kMaxHP)) <= 0.3
end

function FightShip:checkDoSkill(  )
	local flag = (self.fm_:isPve() == true and self:getPos()[1] == 2) or self.fm_:isPve() == false
	if self:isCanFight() == true then
		if flag then
			local skillConf = self:getWeaponConfBySkill()
			if skillConf then
				if self:getAttrByKey(CONF.EShipAttr.kAnger) >= skillConf.ENERGY then
					if flag then
						if self.lastSkillTime_ == 0 then
							return true
						else
							return self.fm_:getTime() >= self.lastSkillTime_ + skillConf.CD
						end
					end
					return true
				end
			end
		end
	end
	return false
end

function FightShip:fight(curRound)

	local function getWeaponIndex(curRound)
		local weapon_list = self.data_.weapon_list
		return  Tools.mod(curRound, #weapon_list)
	end
	local index = getWeaponIndex(curRound)
	local weaponConf = self:getWeaponConfByIndex(index)

	if self:isDead() == false then
		if self:isCanFight() == true then
	
			if self:hasSpecial(CONF.EShipSpecial.kCannotSkill) == true then
				
				weaponConf = self:getWeaponConfByDefault(index)
				printInfo("CannotSkill", weaponConf.ID)
			end
			self:_doWeapon(weaponConf, curRound)
		else
			printInfo("can not fight ")
			self:_doWeapon(nil, curRound)
		end
	end

    	self:calRemoveBuff(1)
end

function FightShip:doSkillSubEnergy()
	local weaponConf = self:getWeaponConfBySkill()
	if not weaponConf then
	
		return 0
	end

	if self:getAttrByKey(CONF.EShipAttr.kAnger) < weaponConf.ENERGY then
		return 0
	end



	if weaponConf.BIG == 1 then


		local oldAnger = self:getAttrByKey(CONF.EShipAttr.kAnger)
		self:setAttrByKey(CONF.EShipAttr.kAnger, oldAnger - weaponConf.ENERGY )

		if self.fm_:isPve() == true and self:getPos()[1] == 1 then
			--已在客户端扣除ENERGY
		else
			local attackEvent = FightEvent:create(FightEvent.EventType.kEnergy)
			local attakerEvent = {pos = self:getPos()}
			attackEvent:addAttacker(attakerEvent)
			attakerEvent.values = {{key = CONF.EShipAttr.kAnger,value = self:getAttrByKey(CONF.EShipAttr.kAnger) - oldAnger},}
			self.fm_:pushEvent(attackEvent:getEvent())
		end

	end

	return -weaponConf.ENERGY
end

function FightShip:attack( weaponConf, isFightBack )

	assert(weaponConf,"error")
	local hurtValue = 0
	local ret = 0
	local hited
	local flag = false
	local needFightBack = false


	local attackEvent 
	if not self.hurters_ or weaponConf.SIGN == 0 then --只放BUFF的技能使用EnergyEvent
		attackEvent = FightEvent:create(FightEvent.EventType.kEnergy)
	else
		attackEvent = FightEvent:create(FightEvent.EventType.kAttack, {weaponConf.ID})
	end

	local attakerEvent = {pos = self:getPos()}
	attackEvent:addAttacker(attakerEvent)
	--攻击怒气计算
	if weaponConf.BIG == 1 then
		if self:getAttrByKey(CONF.EShipAttr.kAnger) >= weaponConf.ENERGY then

			-- local oldAnger = self:getAttrByKey(CONF.EShipAttr.kAnger)
			-- self:setAttrByKey(CONF.EShipAttr.kAnger, oldAnger - weaponConf.ENERGY )

			-- if self.fm_:isPve() == true and self:getPos()[1] == 1 then
			-- 	--已在客户端扣除ENERGY
			-- else
			-- 	attakerEvent.values = {{key = CONF.EShipAttr.kAnger,value = self:getAttrByKey(CONF.EShipAttr.kAnger) - oldAnger},}
			-- end
		end

	else

		if self:hasSpecial(CONF.EShipSpecial.kAttackCannotGetAnger) == true then
		
			
		else
			local add = self:getAttrByKey(CONF.EShipAttr.kAngerRestore) * CONF.PARAM.get("attack_anger").PARAM
			add = math.ceil(add)
			local oldAnger = self:getAttrByKey(CONF.EShipAttr.kAnger)
			if self:setAttrByKey(CONF.EShipAttr.kAnger, oldAnger + add) then
				attakerEvent.values = {{key = CONF.EShipAttr.kAnger, value = self:getAttrByKey(CONF.EShipAttr.kAnger) - oldAnger},}
			end
		end


	end


	if not self.hurters_ or weaponConf.SIGN == 0 then
		self:setAttrByKey(CONF.EShipAttr.kAttackValue, 0)
		self.fm_:pushEvent(attackEvent:getEvent())
		return
	end

	local fightBackList = {}
	local averageHurtList = {}
	local averageHurtEvent

	local isKilled = false
	local hurted_list = {}
	for i,v in ipairs(self.hurters_) do
		--伤害计算
		ret,hited,needFightBack,averageHurtEvent = v:hurt(attackEvent, self, weaponConf, isFightBack)

		if hited == true then
			flag = true
		end
		if needFightBack == true then
			table.insert(fightBackList, v)
		end
		if averageHurtEvent then
			table.insert(averageHurtList, averageHurtEvent)
		end

		local temp = 0
		if ret < 0 then
			temp = -ret
		end
		v:setAttrByKey(CONF.EShipAttr.kHurtValue, temp)
		hurtValue = hurtValue + temp

		if not v:isCanHurt() then
			isKilled = true
		else
			if ret < 0 then
				table.insert(hurted_list, v)
			end
		end
	end

	self:setAttrByKey(CONF.EShipAttr.kAttackValue, hurtValue)


	self.fm_:pushEvent(attackEvent:getEvent())

	for i,v in ipairs(hurted_list) do
		v:checkBuffs(CONF.EBuffTrigger.kHurt)	
	end

	if isKilled == true then
		for i = 1, #self.data_.weapon_list do
			self:calCreateBuff(self:getWeaponConfByIndex(i), CONF.EBuffCondition.kKilled)
		end
		self:checkBuffs(CONF.EBuffTrigger.kKilled)
	end

	for i,v in ipairs(averageHurtList) do
		self.fm_:pushEvent(v:getEvent())
	end

	if flag == true then
		self:calCreateBuff(weaponConf, CONF.EBuffCondition.kHited)
	end

	for i,v in ipairs(fightBackList) do

		local weaponConf = v:getWeaponConfByDefault(1)
			
		if weaponConf ~= nil then
			v:_doWeapon(weaponConf, 0, true, {self})
			v:calRemoveBuff(0)
		end
	end
end

function FightShip:dead( )

	self.status_ = CONF.EShipStatus.kDead
	self.data_.attr[CONF.EShipAttr.kHP] = 0

	self.buffs_ = nil

	self.fm_:removeFightOrder(self)
end

function FightShip:isDead( )
	return self.status_ == CONF.EShipStatus.kDead
end

function FightShip:averageHurt(hurtValue)

	local ships = self.fm_:getHasSpecialShipsByGroupIndex( self:getPos()[1], CONF.EShipSpecial.kGetAverageHurt, 0)

	local averageHurtValue = math.floor(hurtValue / #ships)

	local event = FightEvent:create(FightEvent.EventType.kAttack)

	for i,v in ipairs(ships) do

		if v ~= self then

			v:setAttrByKey(CONF.EShipAttr.kHP, self:getAttrByKey(CONF.EShipAttr.kHP) + averageHurtValue)

			
			local status = CONF.EShipStatus.kNil
			if v:getAttrByKey(CONF.EShipAttr.kHP) <= 0 then
				v:dead()
				status = CONF.EShipStatus.kDead
			end

			event:addHurter({pos = v:getPos(), status = status, values = {{key = CONF.EShipAttr.kHP, value = averageHurtValue}},})
		end
	end

	if event:isHurterEmpty() then
		event = nil
	end
	return averageHurtValue,event
end

function FightShip:calAttackValue(weaponConf)

	local sign = weaponConf.SIGN
	if weaponConf.SIGN == 1 then
		sign = -1
	elseif weaponConf.SIGN == 0 then
		return 0
	end
	
	
	return value1 * sign, value2 * sign
end

function FightShip:hurt(attackEvent, attacker, weaponConf, isFightBack )

	local ret = 0
	local hited = false
	local fightBack = false
	local averageHurtEvent
	local status = CONF.EShipStatus.kNil

	local sign = weaponConf.SIGN

	if weaponConf.SIGN ~= 1 then

		self:watch()
		local ret = attacker:getAttrByKey(CONF.EShipAttr.kEnergyAttack) * 0.01 * (attacker:getAttrByKey(CONF.EShipAttr.kEnergyAttackAddition) + 100)
		ret = ret * (weaponConf.ENERGY_ATTR_PERCENT * 0.01) + weaponConf.ENERGY_ATTR_VALUE
		ret = ret + ret * (self:getAttrByKey(kBeCureAddition) * 0.01)
		ret = math.floor(ret)

		self:setAttrByKey(CONF.EShipAttr.kHP, self:getAttrByKey(CONF.EShipAttr.kHP) + ret)

		hited = true

	else
		self:watch()

		local attackerHit = attacker:getAttrByKey(CONF.EShipAttr.kHit)
		local hit = attackerHit / (attackerHit + self:getAttrByKey(CONF.EShipAttr.kDodge) * CONF.PARAM.get("hit").PARAM) * 100 + attacker:getAttrByKey(CONF.EShipAttr.kFinalProbabilityHit) - self:getAttrByKey(CONF.EShipAttr.kFinalProbabilityDodge)
		hit = math.floor(hit)
		
		local flag = (hit > 0) and (hit >= math.random(1,100)) or false

		if flag == false then
			attackEvent:addHurter({pos = self:getPos(), status = CONF.EShipStatus.kMiss})
			return 0
		end
		hited = true

		local value1 = attacker:getAttrByKey(CONF.EShipAttr.kAttack) * 0.01 * (attacker:getAttrByKey(CONF.EShipAttr.kAttackAddition) + 100) 

		local value2 = attacker:getAttrByKey(CONF.EShipAttr.kEnergyAttack) * 0.01 * (attacker:getAttrByKey(CONF.EShipAttr.kEnergyAttackAddition) + 100)
		
		local defence = (self:getAttrByKey(CONF.EShipAttr.kDefence) > 0) and self:getAttrByKey(CONF.EShipAttr.kDefence) or 0
		defence = defence + defence * (self:getAttrByKey(CONF.EShipAttr.kDefeceAddition) * 0.01)
		value1 = value1 * value1 / (value1 + defence) * weaponConf.ATTR_PERCENT*0.01 + weaponConf.ATTR_VALUE
		value2 = value2 * value2 / (value2 + defence) * weaponConf.ENERGY_ATTR_PERCENT*0.01 + weaponConf.ENERGY_ATTR_VALUE

		local attackerValue = (value1 + value2)
		ret = attackerValue +  (attackerValue * 0.01 * (attacker:getAttrByKey(CONF.EShipAttr.kHurtAddition) -  self:getAttrByKey(CONF.EShipAttr.kHurtSubtration)))
		if ret < 1 then
			ret = 1
		end
		
		local attackerCrit = attacker:getAttrByKey(CONF.EShipAttr.kCrit)
		local crit = attackerCrit / ( attackerCrit + self:getAttrByKey(CONF.EShipAttr.kAnticrit)*CONF.PARAM.get("crit").PARAM) * 100 + attacker:getAttrByKey(CONF.EShipAttr.kFinalProbabilityCrit) - self:getAttrByKey(CONF.EShipAttr.kFinalProbabilityAnticrit)
		flag = (attackerCrit > 0) and crit >= math.random(1,100) or false
		if flag == true then
			ret =  ret * 0.01 * attacker:getAttrByKey(CONF.EShipAttr.kCritEffect)
			status = CONF.EShipStatus.kCrit
		end
		if ret < 1 then
			ret = 1
		end
		ret = -math.floor(ret)

		self:setAttrByKey(CONF.EShipAttr.kShield, self:getAttrByKey(CONF.EShipAttr.kShield) + ret)

		if self:getAttrByKey(CONF.EShipAttr.kShield) < 0 then

			ret = self:getAttrByKey(CONF.EShipAttr.kShield)

			self:setAttrByKey(CONF.EShipAttr.kShield, 0)

			--平分伤害
			if self:hasSpecial(CONF.EShipSpecial.kGetAverageHurt) == true then
				ret,averageHurtEvent = self:averageHurt(ret)
			end

			self:setAttrByKey(CONF.EShipAttr.kHP, self:getAttrByKey(CONF.EShipAttr.kHP) + ret)


			self.fm_:addHitValue(self:getPos()[1] == 1 and 2 or 1, -ret)


			if self:getAttrByKey(CONF.EShipAttr.kHP) <= 0 then
				self:dead()
			end
		else
			ret = 0

		end

		if  self:isCanHurt() == true
		and (isFightBack == nil or isFightBack == false)
		and attacker:hasSpecial(CONF.EShipSpecial.kCannotBeFightBack) == false
		and self:hasSpecial(CONF.EShipSpecial.kFightBack) == true
		and self ~= attacker then
			fightBack = true
		end
	end

	local event = self:getEvent(status)
	if weaponConf.SIGN == 1 then --伤血技能才会加怒气
		if self:hasSpecial(CONF.EShipSpecial.kAttackCannotGetAnger) == true then--无法积攒怒气

		else
			local add = self:getAttrByKey(CONF.EShipAttr.kAngerRestore) * CONF.PARAM.get("defend_anger").PARAM
			add = math.ceil(add)
			local oldAnger = self:getAttrByKey(CONF.EShipAttr.kAnger)
			if self:setAttrByKey(CONF.EShipAttr.kAnger, oldAnger + add) then
				table.insert(event.values, {key = CONF.EShipAttr.kAnger, value = self:getAttrByKey(CONF.EShipAttr.kAnger) - oldAnger})
			end
		end
	end
	attackEvent:addHurter(event)

	return ret,hited,fightBack,averageHurtEvent
end

function FightShip:setAttrByBuff( key, value)

	if not self:isCanHurt() and key ~= CONF.EShipAttr.kAnger then
		return
	end
	local oldAttr = self:getAttrByKey(key)
	if oldAttr == nil then
		oldAttr = 0
	end
	self:setAttrByKey(key, oldAttr + value)

	if key == CONF.EShipAttr.kHP then
		local value = self:getAttrByKey(key)
		if  value <= 0 then
			self:dead()
		end
	elseif key == CONF.EShipAttr.kShield then

		if self:getAttrByKey(key) < 0 then
			self:setAttrByKey(key, 0)
		end
	end
	return value
end


function FightShip:watch(needDetail)

	self.record_ = {}

	if needDetail == true then
		self.record_.watchKeys = {}
		for i=1,CONF.EShipAttr.kCount do
			self.record_.watchKeys[i] = false
		end
	else
		self.record_.watchKeys = {[CONF.EShipAttr.kHP] = false,[CONF.EShipAttr.kAnger] = false, [CONF.EShipAttr.kShield] = false, }
	end
	

	self.record_.overValues = {[CONF.EShipAttr.kHP] = 0,}

	self.record_.recordAttr = {}
	for key,flag in pairs(self.record_.watchKeys) do
		if key == CONF.EShipAttr.kAnger then
			self.record_.recordAttr[key] = self.fm_:getAnger(self:getPos()[1])
		else
			self.record_.recordAttr[key] = self:getAttrByKey(key)
		end
	end

	
end

function FightShip:getEvent(status)

	if self.record_.watchKeys == nil then
		return nil
	end

	local attr = {}

	if self.record_ then
		for k,v in pairs(self.record_.watchKeys) do
			if v == true then
				local value = self:getAttrByKey(k) - self.record_.recordAttr[k]
				if self.record_.overValues[k] then
					value = value + self.record_.overValues[k]
				end
				table.insert(attr, {key = k, value = value})
			end
		end

		self.record_.watchKeys = nil
		self.record_.recordAttr = nil
		self.record_ = nil
	end
	

	if Tools.isEmpty(attr) then
		return  nil
	end

	if status == nil then
		status = CONF.EShipStatus.kNil
	end
	if self.data_.attr[CONF.EShipAttr.kHP] <= 0 or self.status_ == CONF.EShipStatus.kDead then
		local Bit = require "Bit"
		if Bit:has(status, CONF.EShipStatus.kDead) == false then
			status = Bit:add(status, CONF.EShipStatus.kDead)
		end
	end

	return {pos = self:getPos(), values = attr, status = status}
end

return FightShip