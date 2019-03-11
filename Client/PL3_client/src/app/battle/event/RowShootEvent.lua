
local animManager = require("app.AnimManager"):getInstance()

local Gmath = require("app.Gmath")


local RowShootEvent = class("RowShootEvent",require("app.battle.event.AttackEvent"))

RowShootEvent.waitTimer = 0
RowShootEvent.waitTime = 0.5

function RowShootEvent:ctor(data,bm)
	
	self.__supers[#self.__supers]:ctor(data,bm)

end


function RowShootEvent:start()

	self.__supers[#self.__supers]:start()

	local conf = self.bm:getSkillConfig(self.skillID)

	self.bullet[1] = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", self.resName))
	
	self.bullet[1]:setPosition(self:getAttackPos())

	self.bm:getBulletNode(self.group):addChild(self.bullet[1],  conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)

	local function animOk()
		--self.state = self.StateEnum.kMoveSpace
		self.bullet[1]:removeFromParent()
		self.bullet[1] = 0
	end

	animManager:runAnimOnceByCSB(self.bullet[1], string.format("sfx/%s", self.resName), "attack", animOk)

	if self.group == 2 then
		self.bullet[1]:setScale(-1)
	end


	if Tools.isEmpty(self.hurters) == false then
		self.bullet[2] = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", self.resName))

		local index = self.hurters[1].obj.index
		if index < 4 then
			index = 1
		elseif index < 7 then
			index = 4
		else
			index = 7
		end

		self.bullet[2]:setPosition(self.bm:getShipPos(self.group, index, false))

		self.bm:getBulletNode(self.group,false):addChild(self.bullet[2],  conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)

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

			self.bm:getBulletNode(self.group,false):addChild(self.bullet[index+2],  conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)

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


function RowShootEvent:finish()

	if self.bullet ~= nil then
		for k,v in ipairs(self.bullet) do
			if v ~= nil and v ~= 0 then
				v:removeFromParent()
			end
		end
		self.__supers[#self.__supers]:finish()
	end
end



function RowShootEvent:moveOnMySide()



end

function RowShootEvent:moveSpace(dt)

end

function RowShootEvent:moveOnOtherSide(dt)


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

function RowShootEvent:disappear(dt)

	self.waitTimer = self.waitTimer + dt

	if self.waitTimer > self.waitTime then
		return true
	end
	return false
end



return RowShootEvent