local FightEvent = require("FightLogic.FightEvent")

local FightBuff = class("FightBuff")

local volatileKeys = {
[CONF.EShipAttr.kAnger] = true,
[CONF.EShipAttr.kHP] = true,
--[CONF.EShipAttr.kShield] = true,
}

function FightBuff:ctor(fm, ship, weaponConf, buffIndex, attitions)--attitions = {[key] = value} :比如buff减伤
	self.fm_ = fm 
	self.ship_ = ship
	self.weaponConf_ = weaponConf
	self.buffIndex_ = buffIndex
	self.buffConf_ = CONF.BUFF.get(weaponConf.BUFF_ID[buffIndex])

	self.round_ = self.weaponConf_.BUFF_ROUND[self.buffIndex_]

	self.did_ = false
	self.repeatSourceValue_ = 0

	self.attition_ = 0

	for k,v in pairs(attitions) do
		if k == self.buffConf_.DEST_KEY then
			self.attition_ = v
			break
		end
	end


	self.recordList_ = {}
	self.recordSpecialList_ = {}
end

function FightBuff:getID()
	return self.buffConf_.ID
end

function FightBuff:getRound()
	return self.round_
end

function FightBuff:isGoodBuff(  )
	if self.weaponConf_.BUFF_ATTR_PERCENT[self.buffIndex_] > 0 then
		return true
	elseif self.weaponConf_.BUFF_ATTR_VALUE[self.buffIndex_] > 0 then
		return true
	end

	if self.buffConf_.SPECIAL == CONF.EShipSpecial.kFightBack
	or self.buffConf_.SPECIAL == CONF.EShipSpecial.kCannotBeFightBack
	or self.buffConf_.SPECIAL == CONF.EShipSpecial.kImmuneDebuff 
	or self.buffConf_.SPECIAL == CONF.EShipSpecial.kGetAverageHurt then
		return true
	end
	return false
end

function FightBuff:isDebuff()
	if self.weaponConf_.BUFF_ATTR_PERCENT[self.buffIndex_] < 0 then
		return true
	elseif self.weaponConf_.BUFF_ATTR_VALUE[self.buffIndex_] < 0 then
		return true
	end

	if self.buffConf_.SPECIAL == CONF.EShipSpecial.kCannotAttack
	or self.buffConf_.SPECIAL == CONF.EShipSpecial.kCannotSkill
	or self.buffConf_.SPECIAL == CONF.EShipSpecial.kAttackCannotGetAnger then
		return true
	end
	return false
end

function FightBuff:doLogic(trigger)

	if self.buffConf_.REPEAT == 0 and self.did_ == true then
		return
	end

	local flag = false
	for i,v in ipairs(self.buffConf_.TRIGGER) do
		if v == trigger then
			flag = true
			break
		end
	end
	if flag == false then
		return
	end

	self:_doLogic()
end

function FightBuff:overlay(newBuff)

	if newBuff:getID() ~= self:getID() then
		return
	end

	local event = FightEvent:create(FightEvent.EventType.kAttack)
	self:_restore(event)
	if event:isHurterEmpty() == false then
		self.fm_:pushEvent(event:getEvent())
	end

	self.ship_ = newBuff.ship_
	self.weaponConf_ = newBuff.weaponConf_
	self.buffIndex_ = newBuff.buffIndex_
	self.buffConf_ = newBuff.buffConf_

	self.did_ = false
	self.repeatSourceValue_ = 0
	self.attition_ = newBuff.attition_

	self.round_ = newBuff:getRound()

	self:doLogic(CONF.EBuffTrigger.kCreate)
end

function FightBuff:_doLogic()

	if self.buffConf_.SOURCE_KEY ~= 0 then

		self:_transferLogic()
	else
		self:_normalLogic()
	end

	self.did_ = true
end


function FightBuff:_normalLogic()
	
	local destTargets = self.ship_:getTargetByConf(self.buffConf_.DEST_TARGET_1,self.buffConf_.DEST_TARGET_2,self.buffConf_.DEST_TARGET_3)

	if Tools.isEmpty(destTargets) then
		return
	end

	local buffEvent = FightEvent:create(FightEvent.EventType.kAttack)


	local key = self.buffConf_.DEST_KEY
	local needDetail = self.buffConf_.SHOW_DETAIL == 1

	local special = self.buffConf_.SPECIAL
	local value = 0

	for i,v in ipairs(destTargets) do
		if v:isDead() == false then

			if key ~= CONF.EShipAttr.kNil then
				value = math.floor( self.weaponConf_.BUFF_ATTR_PERCENT[self.buffIndex_] * 0.01 * v:getAttrByKey(key) + self.weaponConf_.BUFF_ATTR_VALUE[self.buffIndex_] )
		
				if (value > 0 and self.attition_ > 0) or (value < 0 and self.attition_ < 0) then
					value = math.floor(value + self.attition_ * 0.01 * value)
				end
			end

			v:watch(needDetail)
			if key ~= CONF.EShipAttr.kNil then

				value = v:setAttrByBuff(key,value)
				self:_record(v, key, value)
			end

			local event = v:getEvent()
			
			if event then
				buffEvent:addHurter(event)
			end

			if special and special ~= CONF.EShipSpecial.kNil then
				
				v:addSpecial(special)

				self:_recordSpecial(v, self.buffConf_.SPECIAL)


				if special == CONF.EShipSpecial.kImmuneDebuff then
					v:clearBuff(true)
				elseif special == CONF.EShipSpecial.kClearGoodBuff then
					v:clearBuff(false)
				end
			end
		end
	end

	if not buffEvent:isHurterEmpty() then
		self.fm_:pushEvent(buffEvent:getEvent())
	end
	
	if key == CONF.EShipAttr.kSpeed then
		self.fm_:resetFightOrder()
	end
end

function FightBuff:_transferLogic()

	local sourceTargets = self.ship_:getTargetByConf(self.buffConf_.SOURCE_TARGET_1,self.buffConf_.SOURCE_TARGET_2,self.buffConf_.SOURCE_TARGET_3)

	local sourceKey = self.buffConf_.SOURCE_KEY
	local value = 0
	--printInfo("_transferLogic", self:getID())
	if self.buffConf_.REPEAT == true and self.did_ == true then
		value = self.repeatSourceValue_
	else
		for i,v in ipairs(sourceTargets) do
			
			if v:isDead() == false then
				local temp = v:getAttrByKey(sourceKey)
		
				temp = (self.weaponConf_.BUFF_ATTR_PERCENT[self.buffIndex_]) * 0.01 * temp + self.weaponConf_.BUFF_ATTR_VALUE[self.buffIndex_]
				temp = math.floor( temp )
				
				if volatileKeys[sourceKey] == true then
					--print("test", value, sourceKey, temp, v:getPos()[1], v:getPos()[2], v:getPos()[3])
					value = value + v:setAttrByBuff(sourceKey, temp)
				else
					value = value + temp
				end
			end
		end
		self.repeatSourceValue_ = value
	end

	local destTargets = self.ship_:getTargetByConf(self.buffConf_.DEST_TARGET_1,self.buffConf_.DEST_TARGET_2,self.buffConf_.DEST_TARGET_3)


	if Tools.isEmpty(destTargets) then
		return
	end

	local buffEvent = FightEvent:create(FightEvent.EventType.kAttack)


	local needDetail = self.buffConf_.SHOW_DETAIL == 1

	local destKey = self.buffConf_.DEST_KEY

	local special = self.buffConf_.SPECIAL

	for i,v in ipairs(destTargets) do

		if v:isDead() == false then
			v:watch(needDetail)
			if destKey ~= CONF.EShipAttr.kNil then

				local temp = v:setAttrByBuff(destKey, value)
				self:_record(v, destKey, temp)
			end

			local event = v:getEvent()
			if event then
				buffEvent:addHurter(event)
			end

			if special and special ~= CONF.EShipSpecial.kNil then

				v:addSpecial(special)
				self:_recordSpecial(v, self.buffConf_.SPECIAL)


				if special == CONF.EShipSpecial.kImmuneDebuff then
					v:clearBuff(true)
				elseif special == CONF.EShipSpecial.kClearGoodBuff then
					v:clearBuff(false)
				end
			end
		end
	end

	if not buffEvent:isHurterEmpty() then
		self.fm_:pushEvent(buffEvent:getEvent())
	end
	

	if destKey == CONF.EShipAttr.kSpeed then
		self.fm_:resetFightOrder()
	end
end

function FightBuff:_record( ship, key, value )

	if volatileKeys[key] == true then
		return
	end
	if key and value then
		printInfo(string.format("_record :----- key: %d, value: %d", key, value))

		table.insert(self.recordList_, {obj = ship,key = key, value = value})
	end
end

function FightBuff:_recordSpecial( ship, key )

	table.insert(self.recordSpecialList_, {obj = ship,key = key})

end


function FightBuff:_restore(buffEvent)

	printInfo(string.format("_restore ID", self.buffConf_.ID))
	for i,v in ipairs(self.recordList_) do
		if v.obj:isDead() == false then
			printInfo(string.format("_restore :----- key:%d value: %d",v.key, -v.value))
			v.obj:watch()
			v.obj:setAttrByBuff(v.key,-v.value)

			local event = v.obj:getEvent()
			if Tools.isEmpty(event) == false then
				buffEvent:addHurter(event)
			end
		else
			printInfo("_restore v.obj:isDead()!!!!!!!!!!!!!!!")
		end
	end

	self.recordList_ = {}

	for i,v in ipairs(self.recordSpecialList_) do
		v.obj:removeSpecial(v.key)
	end
	self.recordSpecialList_ = {}

	local removeEvent = {
		pos = self.ship_:getPos(), 
		buffs = {-self:getID(),}
	}
	buffEvent:addHurter(removeEvent)
end

function FightBuff:calRound(round, buffEvent)
	round = round or 0
	self.round_ = self.round_ - round
	if self.round_ <= 0 then
		self:_restore(buffEvent)
	end

	return self.round_
end

function FightBuff:remove( buffEvent )

	self:_restore(buffEvent)
end

return FightBuff