
local animManager = require("app.AnimManager"):getInstance()

local Gmath = require("app.Gmath")

local MagicEvent = class("MagicEvent",require("app.battle.event.AttackEvent"))

MagicEvent.waitTimer = 0
MagicEvent.waitTime = 0.3

function MagicEvent:ctor(data, bm)
	self.__supers[#self.__supers]:ctor(data, bm)
end

function MagicEvent:start()
	
	self.__supers[#self.__supers]:start()


	assert(self.bullet ~= nil,"error")

	if self.resName == nil then
	
		for index,hurter in ipairs(self.hurters) do
			self:hurterGetHurt(index)
		end
		self.state = self.StateEnum.kMoveOtherSide
		return
	end

	self.bullet[1] = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", self.resName))
	assert(self.bullet[1] ~= nil,string.format("craete sprite failed : sfx/%s", self.resName))


	local conf = self.bm:getSkillConfig(self.skillID)


	self.bullet[1]:setPosition(self:getAttackPos())
	self.bm:getBulletNode(self.group):addChild(self.bullet[1], conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)

	local function attackAnimOK()
		--self.state = self.StateEnum.kMoveSpace
		self.bullet[1]:removeFromParent()
		self.bullet[1] = 0
	end
	printInfo("magic event attack res:",self.resName)

	local attack_str = "attack"
	if self.group == 2 then
		if animManager:isAnimExistsByCSB(string.format("sfx/%s", self.resName), "attack_2") then
			attack_str = "attack_2"
		end
	end

	local result = animManager:runAnimOnceByCSB(self.bullet[1], string.format("sfx/%s", self.resName), attack_str, attackAnimOK)
	if result == false then
		attackAnimOK()
	end
	--self.state = self.StateEnum.kMoveMySide

	if self.group == 2 then
		if attack_str == "attack_2" or self.buffIndex ~= nil then
			--self.bullet[1]:setScaleX(-1)
		else
			self.bullet[1]:setScale(-1)
		end
	end

	local bulletNode
	if Tools.isEmpty(self.attackers) == false and Tools.isEmpty(self.hurters) == false then
		bulletNode = self.bm:getBulletNode(self.group,self.attackers[1].obj.group == self.hurters[1].obj.group and true or false)
	end
	if bulletNode then
		
		for index,hurter in ipairs(self.hurters) do
		
			self.bullet[index+1] = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", self.resName))

			assert(self.bullet[index+1] ~= nil,"craete sprite failed")

			bulletNode:addChild(self.bullet[index+1], conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)
			self.bullet[index+1]:setPosition(cc.p(hurter.obj:getRenderer():getPosition()))

			printInfo("magic event hurt res:",self.resName)

			local hurt_str = "hurt"
			if self.group == 2 then
				if animManager:isAnimExistsByCSB(string.format("sfx/%s", self.resName), "hurt_2") then
					hurt_str = "hurt_2"
				end
			end

			if self.group == 2 then
				if hurt_str == "hurt_2" then
	
				else
					self.bullet[index+1]:setScale(-1)
				end
			end

			local function hurtAnimOK()

				self:hurterGetHurt(index)
				self.bullet[index+1]:removeFromParent()
				self.bullet[index+1] = 0
			end

			local function onFrameEvent(frame)
				if nil == frame then
					return
				end
				local str = frame:getEvent()
				if str == "hurt" then
					local node = frame:getNode()
					hurter.obj:hurt()
					self:hurterShowHP(index, node:getCustomProperty())
				end
			end

			
			local result = animManager:runAnimOnceByCSB(self.bullet[index+1], string.format("sfx/%s", self.resName), hurt_str, hurtAnimOK, onFrameEvent)
			if result == false then
				hurtAnimOK()
			end
		end
	end
	self.state = self.StateEnum.kMoveOtherSide
end


function MagicEvent:finish()
	if self.bullet ~= nil then
		for k,v in ipairs(self.bullet) do
			if v ~= nil and v ~= 0 then
				v:removeFromParent()
			end
		end
		self.__supers[#self.__supers]:finish()
	end
end


function MagicEvent:moveOnMySide(dt)

end

function MagicEvent:moveSpace(dt)

end

function MagicEvent:moveOnOtherSide(dt)

	local count = 0
	for index,obj in ipairs(self.bullet) do
		if type(obj) == "number" and obj == 0 then
			count = count + 1
		end
	end

	local shipAnimOK = false

	if Tools.isEmpty(self.attackers) == false then
		if self.attackers[1].obj:getAnimStatus() == self.attackers[1].obj.EAnimStatus.kIdle then
			shipAnimOK = true
		end
	else
		shipAnimOK = true
	end

	if count == #self.bullet and shipAnimOK then
		self:getHurt()
		self.state = self.StateEnum.kDisappear
	end
end

function MagicEvent:disappear(dt)

	self.waitTimer = self.waitTimer + dt

	if self.waitTimer > self.waitTime then
		return true
	end
	return false
end

return MagicEvent