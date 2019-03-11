local animManager = require("app.AnimManager"):getInstance()

local AttackEvent = class("AttackEvent",require("app.battle.event.BattleEvent"))

AttackEvent.group = 0
AttackEvent.attackers = nil
AttackEvent.hurters = nil
AttackEvent.bullet = nil
AttackEvent.speed = 1

AttackEvent.skillID = 0

AttackEvent.StateEnum = {
	kNone = 0,
	kPrep = 1,
	kMoveMySide = 2,
	kMoveSpace = 3,
	kMoveOtherSide = 4,
	kDisappear = 5,
}
AttackEvent.state = 0

AttackEvent.timer = 0
AttackEvent.spaceTime = 0.15

AttackEvent.resName = nil

function AttackEvent:ctor(data, bm)

	self.state = self.StateEnum.kNone
	self.bm = bm

	local attackers = data.attack_list
	self.attackers = {}

	self.group = attackers[1].pos[1]

	self.skillID = data.values[1]

	self.buffIndex = data.values[2]

	local conf = self.bm:getSkillConfig(self.skillID)
	if self.buffIndex then

		if Tools.isEmpty(conf.BUFF_RES_ID) == true then
			self.resName = nil
		else
			self.resName = conf.BUFF_RES_ID[self.buffIndex]
		end
	else
		self.resName = conf.RES_ID
	end
	


	printInfo("----attackers----")
	for i, v in ipairs(attackers) do
		
		local pos = (v.pos[2] - 1) * 3 + v.pos[3]

		local attack = bm:getShip(v.pos[1], v.pos[2],v.pos[3])

		assert(attack ~= nil,"error")

		table.insert(self.attackers,{obj = attack,attr = v.values, buffs = v.buffs, status = v.status})

		printInfo("  group: ", v.pos[1], "  pos: ", v.pos[2],v.pos[3])

	end
	
	
	self.hurters = {}
	if data.hurter_list then
		
		printInfo("----hurters----")
		for i, v in ipairs(data.hurter_list) do

			local pos = (v.pos[2] - 1) * 3 + v.pos[3]

			local hurter = bm:getShip(v.pos[1], pos)

			assert(hurter ~= nil,"error")

			table.insert(self.hurters,{obj = hurter,attr = v.values, buffs = v.buffs, status = v.status})

			
			printInfo("  group: ", v.pos[1],"  pos: ", v.pos[2],v.pos[3])
		end
	end
end

function AttackEvent:getAttackPos( )
	if self.attackers[1] == nil then
		return
	end

	local shipPos = cc.p(self.attackers[1].obj:getRenderer():getPosition())

	local group = self.attackers[1].obj:getGroup()

	local skillNode = self.attackers[1].obj:getRenderer():getChildByName(string.format("skill_position_%d", group) )
	if skillNode == nil then
		return shipPos
	end

	return cc.pAdd(shipPos,  cc.p(skillNode:getPosition()))
end

function AttackEvent:highLightShipSfx(switch)
	local list = {}

	for i, v in ipairs(self.attackers) do
		table.insert(list,v.obj)
	end

	for i,v in ipairs(self.hurters) do
		table.insert(list,v.obj)
	end

	self.bm:getBattleScene():highLightShipSfx(switch,list)
end

function AttackEvent:start()
	
	self.bullet = {}
	local conf = self.bm:getSkillConfig(self.skillID)

	if conf.BIG == 1 then

		--self.bm:getAttackList():insert(self.attackers[1].obj)
		if self.resName ~= nil and self.resName ~= "" then
			self:highLightShipSfx(true)

			for i,v in ipairs(self.attackers) do
				v.obj:attack(self.buffIndex)
			end
		end
	end

	if self.buffIndex then
		--BUFF情况
		if conf.RES_ID == nil and Tools.isEmpty(conf.BUFF_RES_ID) == false and self.buffIndex == 1 then
			if conf.MUSIC and conf.MUSIC ~= "" then
				playEffectSound( "sound/effect/"..conf.MUSIC )
			end
		end
	else
		--attack情况
		if conf.RES_ID then
			if conf.MUSIC and conf.MUSIC ~= "" then
				playEffectSound( "sound/effect/"..conf.MUSIC )
			end
		end
	end
end

function AttackEvent:check()
	if self.bm:getSkillConfig(self.skillID).BIG == 1 then
		local conf = self.bm:getSkillConfig(self.skillID)

		if self.buffIndex then
			--放BUFF情况
			if self.buffIndex == 1 and Tools.isEmpty(conf.BUFF_RES_ID) == false and conf.BUFF_CONDITION_TYPE[1] == 1 then
				self.bm:getBattleScene():showSkillNameSfx(conf)
			end
		else
			--attack情况
			if Tools.isEmpty(conf.BUFF_RES_ID) == true or conf.BUFF_CONDITION_TYPE[1] ~= 1 then
				self.bm:getBattleScene():showSkillNameSfx(conf)
			end
		end

		
		--self.bm:getBattleScene():showHeroImage(1)
	end
end

function AttackEvent:getHurt()

	for index,attacker in ipairs(self.attackers) do

		if attacker.attr ~= nil then
			for _,v in pairs(attacker.attr) do
				attacker.obj:getHurt(v.key,v.value, attacker.status)
			end
		end

		if attacker.buffs ~= nil then
			for i,v in ipairs(attacker.buffs) do
				if v > 0 then
					attack.obj:addBuff(v,self.skillID)
				end
			end
		end

		attacker.obj:setStatus(attacker.status)
	end
end

function AttackEvent:hurterShowHP( index, part )
	local hurter =  self.hurters[index]

	local list = hurter.attr
	if list ~= nil then
		for _,v in ipairs(list) do
			if v.key == CONF.EShipAttr.kHP then
				if part and part ~= "" then
					hurter.obj:showHPHurt(math.ceil(v.value/tonumber(part)), hurter.status)
				else
					hurter.obj:showHPHurt(v.value, hurter.status)
				end

			end
		end 
	end

	self.showHPList_ = self.showHPList_ or {}
	self.showHPList_[index] = true
end

function AttackEvent:hurterGetHurt( index )
	printInfo("hurterGetHurt", index)
	local hurter =  self.hurters[index]

	local list = hurter.attr
	if list ~= nil then
		for _,v in ipairs(list) do
			local noShow = false
			if self.showHPList_ and self.showHPList_[index] == true then
				noShow = true
			end
			hurter.obj:getHurt(v.key,v.value,hurter.status, noShow)
		end 
	end
	
	list = hurter.buffs
	if list ~= nil then
		for i,v in ipairs(list) do
			if v > 0 then
				hurter.obj:addBuff(v,self.skillID)
			end
		end
	end
	hurter.obj:setStatus(hurter.status)
end


function AttackEvent:finish()

	self.bullet = nil
	
	local conf = self.bm:getSkillConfig(self.skillID)
	if conf.BIG == 1 then
		if self.resName ~= nil and self.resName ~= "" then
			self:highLightShipSfx(false)
		end
		if self.group == 1 then
			for i,v in ipairs(self.attackers) do

				v.obj:startCD()
			end
		end
		
	end
end

function AttackEvent:prep(dt)
	self.state = self.StateEnum.kMoveMySide
end

function AttackEvent:moveOnMySide(dt)
	self.state = self.StateEnum.kMoveSpace
end

function AttackEvent:moveSpace(dt)
	self.timer = self.timer + dt
	if self.timer > self.spaceTime then
		self.timer = 0
		self.state = self.StateEnum.kMoveOtherSide
	end
end

function AttackEvent:moveOnOtherSide(dt)
	self.state = self.StateEnum.kDisappear
end

function AttackEvent:disappear(dt)
	return true
end

function AttackEvent:process(dt)
	
	if self.state == self.StateEnum.kPrep then

		self:prep(dt)

	elseif self.state == self.StateEnum.kMoveMySide then

		self:moveOnMySide(dt)

	elseif self.state == self.StateEnum.kMoveSpace then

		self:moveSpace(dt)

	elseif self.state == self.StateEnum.kMoveOtherSide then

		self:moveOnOtherSide(dt)

	elseif self.state == self.StateEnum.kDisappear then
		
		return self:disappear(dt)
	else
		printInfoError("AttackEvent state error! : %d",self.state)
	end

	return false
end


function AttackEvent:resume()

	if self.bullet ~= nil then
		for i,v in ipairs(self.bullet) do
			if type(v) ~= "number" then
				v:resume()
			end
		end
	end
	
end

function AttackEvent:pause()

	if self.bullet ~= nil then
		for i,v in ipairs(self.bullet) do
			if type(v) ~= "number" then
				v:pause()
			end
		end
	end

	
end

return AttackEvent