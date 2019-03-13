local animManager = require("app.AnimManager"):getInstance()

local Gmath = require("app.Gmath")

local ColShootEvent = class("ColShootEvent",require("app.battle.event.AttackEvent"))

ColShootEvent.centerPos = nil
ColShootEvent.waitTimer = 0
ColShootEvent.waitTime = 0.5

function ColShootEvent:ctor(data,bm)
	
	self.__supers[#self.__supers]:ctor(data,bm)

	local hurter_1 = data.hurter_list[1] 
	self.centerPos = self.bm:getShipPos(self.group, hurter_1.pos[3] + 3, false)
end


function ColShootEvent:start()

	printInfo("ColShootEvent:start")
	self.__supers[#self.__supers]:start()

	local conf = self.bm:getSkillConfig(self.skillID)

	self.bullet[1] = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", self.resName))
	
	self.bullet[1]:setPosition(self:getAttackPos())

	self.bm:getBulletNode(self.group):addChild(self.bullet[1], conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)


	animManager:runAnimOnceByCSB(self.bullet[1], string.format("sfx/%s", self.resName), "attack", function ()
		--self.state = self.StateEnum.kMoveSpace
		self.bullet[1]:removeFromParent()
		self.bullet[1] = 0
	end)

	if self.group == 2 then
		self.bullet[1]:setScale(-1)
	end



	local bulletNode
	if Tools.isEmpty(self.attackers) == false and Tools.isEmpty(self.hurters) == false then
		bulletNode = self.bm:getBulletNode(self.group, self.attackers[1].obj.group == self.hurters[1].obj.group and true or false)
	end
	if bulletNode then

		self.bullet[2] = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", self.resName))

		self.bullet[2]:setPosition(self.centerPos)

		bulletNode:addChild(self.bullet[2], conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)

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

function ColShootEvent:finish()

	if self.bullet ~= nil then
		for k,v in ipairs(self.bullet) do
			if v ~= nil and v ~= 0 then
				v:removeFromParent()
			end
		end
		self.__supers[#self.__supers]:finish()
	end
end

function ColShootEvent:moveOnMySide()

end

function ColShootEvent:moveSpace(dt)

end

function ColShootEvent:moveOnOtherSide(dt)
	local count = 0
	for index,obj in ipairs(self.bullet) do
		if type(obj) == "number" and obj == 0 then
			count = count + 1
		end
	end

	if count == #self.bullet then
		self:getHurt()
		self.state = self.StateEnum.kDisappear
	end
end

function ColShootEvent:disappear(dt)
	self.waitTimer = self.waitTimer + dt

	if self.waitTimer > self.waitTime then
		return true
	end
	return false
end

return ColShootEvent