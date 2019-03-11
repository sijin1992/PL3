
local animManager = require("app.AnimManager"):getInstance()

local Gmath = require("app.Gmath")

local MultiShootEvent = class("MultiShootEvent",require("app.battle.event.AttackEvent"))

MultiShootEvent.speed = 44


function MultiShootEvent:ctor(data, bm)
	self.__supers[#self.__supers]:ctor(data, bm)
end

function MultiShootEvent:start()


	local function prepOK(sender,table)
		
		self:getHurt()

		local dir = self.bm:getInfoByKey(self.group, "bullet_direct")

		local angle = math.deg(cc.pGetAngle(dir,cc.p(0,1)))
		self.bullet[1]:setRotation(angle)

		self.state = self.StateEnum.kMoveMySide

		animManager:runAnim(self.bullet[1], string.format("%s_move", self.resName))
	end

	self.__supers[#self.__supers]:start()

	local conf = self.bm:getSkillConfig(self.skillID)

	self.bullet[1] = cc.Sprite:createWithSpriteFrameName(string.format("%s_prep_00.png", self.resName))
	assert(self.bullet[1] ~= nil,"craete sprite failed")
	--animManager:runAnim(self.bullet[1], string.format("%s_move", self.resName))
	animManager:runAnimOnce(self.bullet[1], string.format("%s_prep", self.resName), cc.CallFunc:create(prepOK))

	self.bullet[1]:setPosition(self:getAttackPos())

	if self.group == 1 then
		self.bullet[1]:setFlippedX(true)
		self.bullet[1]:setFlippedY(true)
	end

	self.bm:getBulletNode(self.group):addChild(self.bullet[1],  conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)

	self.state = self.StateEnum.kPrep
end


function MultiShootEvent:finish()

	for k,v in ipairs(self.bullet) do
		if v ~= nil and v ~= 0 then
			v:removeFromParent()
		end
	end
	
	self.__supers[#self.__supers]:finish()
end

function MultiShootEvent:prep(dt)
	
end

function MultiShootEvent:getTargetPos(index)
	return cc.p(self.hurters[index].obj:getRenderer():getPosition())
end

function MultiShootEvent:moveOnMySide(dt)
	local rect = self.bullet[1]:getBoundingBox()

	if Gmath.isRectCrossPlane(rect, self.bm:getInfoByKey(self.group, "bullet_plane")) then


		self.bullet[1]:removeFromParent()

		local dir = self.bm:getInfoByKey(self.group, "bullet_direct", false)
		local plane = self.bm:getInfoByKey(self.group, "bullet_plane", false)

		local subdir = cc.pRotate( dir,cc.pForAngle(math.rad(180)))
		local angle = math.deg(cc.pGetAngle(subdir,cc.p(0,1)))

		if (Tools.isEmpty(self.hurters) == false) then
			for index,obj in ipairs(self.hurters) do
				self.bullet[index] = cc.Sprite:createWithSpriteFrameName(string.format("%s_move_00.png", self.resName))
				assert(self.bullet[index] ~= nil,"craete sprite failed")
				animManager:runAnim(self.bullet[index], string.format("%s_move", self.resName))

				self.bm:getBulletNode(self.group,false):addChild(self.bullet[index],  conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)

				local pos = self:getTargetPos(index)
				
				local point = Gmath.isRayPlaneIntersection(Gmath.ray(pos,dir), plane)

				local size = self.bullet[index]:getContentSize()
				local addtion = cc.pMul( dir, cc.pGetLength(cc.p(size.width/2,size.height/2)))
				local org = cc.pAdd(point, addtion)
				self.bullet[index]:setPosition(org)

					self.bullet[index]:setRotation(angle)
			end
		end


		self.state = self.StateEnum.kMoveSpace
		return
	end

	local pos = cc.p(self.bullet[1]:getPosition())
	local dir = self.bm:getInfoByKey(self.group, "bullet_direct")
	pos = cc.pAdd(pos, cc.pMul(dir,self.speed)) 
	self.bullet[1]:setPosition(pos)
end

function MultiShootEvent:moveOnOtherSide(dt)

	local function disappearOK(sender,table)

		local index = table[1]

		self:hurterGetHurt(index)
		
		sender:removeFromParent()
	end

	local count = 0

	for index,obj in ipairs(self.bullet) do

		while true do

					if 0 == self.bullet[index] then 
						count = count + 1
						print("count :",count)
						break 
					end

					local bulletPos = cc.p(self.bullet[index]:getPosition())
			local bulletRect = self.bullet[index]:getBoundingBox()

			local pos = self:getTargetPos(index)

			if cc.rectContainsPoint(bulletRect,pos) then

				self.bullet[index]:stopAllActions()

				self.bullet[index]:setPosition(pos)

				animManager:runAnimOnce(self.bullet[index], string.format("%s_disappear", self.resName), cc.CallFunc:create(disappearOK,{index}))
				self.bullet[index] = 0
				break
			end

			local pos = cc.p(self.bullet[index]:getPosition())
			local dir = self.bm:getInfoByKey(self.group, "bullet_direct", false)

			dir = cc.pRotate( dir,cc.pForAngle(math.rad(180)))
			pos = cc.pAdd(pos, cc.pMul(dir,self.speed)) 
			self.bullet[index]:setPosition(pos)
					break
			end
	end

	if count == #self.bullet then
		self.state = self.StateEnum.kDisappear
	end
end

function MultiShootEvent:disappear(dt)
	self.state = self.StateEnum.kNone
	return true
end

return MultiShootEvent