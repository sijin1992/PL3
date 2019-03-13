
local animManager = require("app.AnimManager"):getInstance()

local Gmath = require("app.Gmath")


local ShootEvent = class("ShootEvent",require("app.battle.event.AttackEvent"))

ShootEvent.hurterIndex = 0
ShootEvent.speed = 22
ShootEvent.resName = nil

function ShootEvent:ctor(data, bm)
	self.__supers[#self.__supers]:ctor(data, bm)
end

function ShootEvent:shoot()

	self.bullet[1]:setPosition(self:getAttackPos())

	animManager:runAnim(self.bullet[1], string.format("%s_move", self.resName))

	local dir = self.bm:getInfoByKey(self.group, "bullet_direct")

	local angle = math.deg(cc.pGetAngle(dir,cc.p(0,1)))
	self.bullet[1]:setRotation(angle)

	self.state = self.StateEnum.kMoveMySide

	local conf = self.bm:getSkillConfig(self.skillID)

	if self.bullet[1]:getParent() ~= self.bm:getBulletNode(self.group) then
		self.bullet[1]:retain()
		self.bullet[1]:removeFromParent()
		self.bm:getBulletNode(self.group):addChild(self.bullet[1], conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)
		self.bullet[1]:release()
	end
    

    --playEffectSound("sound/shoot.wav")
end

function ShootEvent:start()

	local function prepOK(sender,table)
		self:getHurt()

		self:shoot()
		self.hurterIndex = self.hurterIndex + 1


	end

	self.__supers[#self.__supers]:start()

	self.resName = self.bm:getSkillConfig(self.skillID).RES_ID

	self.bullet[1] = cc.Sprite:createWithSpriteFrameName(string.format("%s_prep_00.png", self.resName))
	assert(self.bullet[1] ~= nil,"craete sprite failed")

	self.bullet[1]:setPosition(self:getAttackPos())

	local conf = self.bm:getSkillConfig(self.skillID)
	self.bm:getBulletNode(self.group):addChild(self.bullet[1], conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)

	animManager:runAnimOnce(self.bullet[1], string.format("%s_prep", self.resName), cc.CallFunc:create(prepOK))
	
	self.state = self.StateEnum.kPrep

end

function ShootEvent:prep(dt)
	
end

function ShootEvent:getTargetPos()
	return cc.p(self.hurters[self.hurterIndex].obj:getRenderer():getPosition())
end

function ShootEvent:moveOnMySide(dt)

	local rect = self.bullet[1]:getBoundingBox()

	local conf = self.bm:getSkillConfig(self.skillID)

	if Gmath.isRectCrossPlane(rect, self.bm:getInfoByKey(self.group, "bullet_plane")) then
		self.state = self.StateEnum.kMoveSpace
		self.bullet[1]:retain()
		self.bullet[1]:removeFromParent()
		self.bm:getBulletNode(self.group,false):addChild(self.bullet[1], conf.BIG==1 and BattleZOrder.kSfxWeapon or BattleZOrder.kNormal)
		self.bullet[1]:release()
		animManager:runAnim(self.bullet[1], string.format("%s_move", self.resName))

		local pos = self:getTargetPos()
		local dir = self.bm:getInfoByKey(self.group, "bullet_direct", false)
		local plane = self.bm:getInfoByKey(self.group, "bullet_plane", false)


		local point = Gmath.isRayPlaneIntersection(Gmath.ray(pos,dir), plane)


		local size = self.bullet[1]:getContentSize()

		local addtion = cc.pMul( dir, cc.pGetLength(cc.p(size.width/2,size.height/2)))

		local org = cc.pAdd(point, addtion)
		self.bullet[1]:setPosition(org)
		return
	end

	local x,y = self.bullet[1]:getPosition()
	local pos = cc.p(x,y)
	local dir = self.bm:getInfoByKey(self.group, "bullet_direct")
	pos = cc.pAdd(pos, cc.pMul(dir,self.speed)) 
	self.bullet[1]:setPosition(pos)
end


function ShootEvent:moveOnOtherSide(dt)
	local bulletPos = cc.p(self.bullet[1]:getPosition())
	local bulletRect = self.bullet[1]:getBoundingBox()

	local pos = self:getTargetPos()


	if cc.rectContainsPoint(bulletRect,pos) then
		self.bullet[1]:stopAllActions()
		animManager:runAnimOnce(self.bullet[1], string.format("%s_disappear", self.resName))
		self.state = self.StateEnum.kDisappear
		return
	end

	
	local x,y = self.bullet[1]:getPosition()
	local pos = cc.p(x,y)
	local dir = self.bm:getInfoByKey(self.group, "bullet_direct", false)

	dir = cc.pRotate( dir,cc.pForAngle(math.rad(180)))

	pos = cc.pAdd(pos, cc.pMul(dir,self.speed)) 

	self.bullet[1]:setPosition(pos)
end

function ShootEvent:disappear(dt)

	if self.bullet[1]:getNumberOfRunningActions() ~= 0 then
		return false
	end

	local index = self.hurterIndex

	self:hurterGetHurt(index)

	if index < #self.hurters then
		self:shoot()
		self.hurterIndex = index + 1
		return false
	end
	self.state = self.StateEnum.kNone
	return true
end



function ShootEvent:finish()
	if self.bullet[1] ~= nil then
		self.bullet[1]:removeFromParent()
		self.bullet[1] = nil
	end

	self.__supers[#self.__supers]:finish()
end

return ShootEvent