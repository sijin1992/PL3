
local animManager = require("app.AnimManager"):getInstance()

local Gmath = require("app.Gmath")

local BigMagicEvent = class("BigMagicEvent",require("app.battle.event.MagicEvent"))


function BigMagicEvent:start()
	
	local MagicEvent = self.__supers[#self.__supers]
	MagicEvent.__supers[#self.__supers]:start()
	
	self.bullet = {}

	assert(self.bullet ~= nil,"error")

	local conf = self.bm:getSkillConfig(self.skillID)

	self.bullet[1] = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", self.resName))
	assert(self.bullet[1] ~= nil,"craete sprite failed")

	self.bullet[1]:setPosition(self:getAttackPos())
	self.bm:getBulletNode(self.group):addChild(self.bullet[1], conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)

	local attack_str = "attack"
	if self.group == 2 and self.buffIndex == nil then
		if animManager:isAnimExistsByCSB(string.format("sfx/%s", self.resName), "attack_2") then
			attack_str = "attack_2"
		end
	end

	animManager:runAnimOnceByCSB(self.bullet[1], string.format("sfx/%s", self.resName), attack_str, function ()
		--self.state = self.StateEnum.kMoveSpace
		self.bullet[1]:removeFromParent()
		self.bullet[1] = 0
	end)
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
		bulletNode = self.bm:getBulletNode(self.group, self.attackers[1].obj.group == self.hurters[1].obj.group and true or false)
	end
	if bulletNode then

		self.bullet[2] = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", self.resName))

		assert(self.bullet[2] ~= nil,"craete sprite failed")

		bulletNode:addChild(self.bullet[2], conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)
		local cneterPos = self.bm:getShipPos(self.group, 5, false)

		self.bullet[2]:setPosition(cneterPos)


		animManager:runAnimOnceByCSB(self.bullet[2], string.format("sfx/%s", self.resName), "hurt1", function ()
			
			self.bullet[2]:removeFromParent()
			self.bullet[2] = 0
		end)

		if self.group == 2 then
			
			self.bullet[2]:setScale(-1)
		end

		

		for index,hurter in ipairs(self.hurters) do

			self.bullet[index+2] = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", self.resName))

			assert(self.bullet[index+2] ~= nil,"craete sprite failed")

			bulletNode:addChild(self.bullet[index+2], conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)

			self.bullet[index+2]:setPosition(cc.p(hurter.obj:getRenderer():getPosition()))


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

			local function hurtAnimOK()

				self:hurterGetHurt(index)
				self.bullet[index+2]:removeFromParent()
				self.bullet[index+2] = 0
			end

			local result = animManager:runAnimOnceByCSB(self.bullet[index+2], string.format("sfx/%s", self.resName), "hurt2", hurtAnimOK, onFrameEvent)
			if result == false then
				hurtAnimOK()
			end
			if self.group == 2 then
				self.bullet[index+2]:setScale(-1)
			end
		end
		
	end

	self.state = self.StateEnum.kMoveOtherSide

end

return BigMagicEvent