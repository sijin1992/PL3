local animManager = require("app.AnimManager"):getInstance()

local AttackList = class("AttackList", function ()
	return cc.Node:create()
end)

local beginPos = cc.p(980,668)
local diffX = 60


function AttackList:_create( ship, isBig)

	local group = ship:getGroup()

	local model = CONF.AIRSHIP.get(ship:getID())

	local sprite = require("app.ExResInterface"):getInstance():FastLoad(string.format("sfx/%s", model.RES_ID))


	sprite:setScale(0.6)

	if isBig ~= nil and isBig == true then

		local skillIcon = cc.Sprite:create(string.format("BattleScene/ui/skill_%d.png",group))
		sprite:addChild(skillIcon)
		skillIcon:setPosition(30, 10)
		skillIcon:setScale(4)
	end


	local arrow = cc.Sprite:create(string.format("BattleScene/ui/arrow_%d.png", group))
	sprite:addChild(arrow)
	arrow:setPosition(15, 50)
	arrow:setScale(4)
	return sprite
end

function AttackList:ctor(bm, pos)
	self._shipList = {}
	self._bm = bm
	beginPos = pos
end
		   
function AttackList:reset( list )

	--printInfo("do reset")

	local index = 1
	while self._shipList[index] do
		
		if self._shipList[index].renderer:getParent() ~= nil then
			self._shipList[index].renderer:removeFromParent()
		end
		self._shipList[index].renderer:release()
		table.remove(self._shipList,index)
	end



	for i,v in ipairs(list) do

		local sprite = self:_create(v.obj, v.isBig)

		table.insert(self._shipList,{renderer = sprite,isBig = v.isBig,ship = v.obj})
		sprite:retain()
	end

	for i=1,5 do

		if self._shipList[i] ~= nil then

			self._shipList[i].renderer:setPosition(beginPos.x - diffX*(i-1), beginPos.y)
			self:addChild(self._shipList[i].renderer)

		end
		
	end
end


function AttackList:insert( ship )

	local function stop( index )
		for i = index, #self._shipList do
			self._shipList[i].renderer:stopAllActions()
		end
	end

	local index = 1

	stop(index)

	--printInfo("AttackList insert",index)

	local sprite = self:_create( ship.obj, true)
	table.insert(self._shipList, index, {renderer = sprite,isBig = true,ship = ship.obj})
	sprite:retain()

	sprite:setPosition(beginPos.x - diffX*index, beginPos.y - diffX)
	self:addChild(sprite)

	for i= index, 6 do

		if nil ~= self._shipList[i] and self._shipList[i].renderer:getParent() ~= nil then

			self._shipList[i].renderer:runAction(cc.MoveTo:create(0.5,cc.p(beginPos.x - diffX*(i-1), beginPos.y)))
		
		end
		
	end
end

function AttackList:remove( ship )
	--printInfo("do remove ", ship:getIndex(), ship:getGroup())

	for i,v in ipairs(self._shipList) do
		if v.ship == ship.obj then
			if v.renderer:getParent() ~= nil then
				v.renderer:removeFromParent()
			end
			v.renderer:release()
			table.remove(self._shipList,i)
			--printInfo("remove ok",i)
			break
		end
	end
end

function AttackList:next( )
	--printInfo("do next")
	if Tools.isEmpty(self._shipList) == true then
		--printInfo("list isEmpty")
		return
	end
	if self._shipList[1] == nil then
		--printInfo("big error")
		table.remove(self._shipList,1)
		self:next()
		return
	end

	assert(self._shipList[1].renderer ~= nil,"error")

	self._shipList[1].renderer:removeFromParent()
	self._shipList[1].renderer:release()
	
	local prePos = Tools.clone(self._shipList[1].ship:getPos())
	local preIsBig = self._shipList[1].isBig
	table.remove(self._shipList,1)

	for i=1,5 do

		if nil ~= self._shipList[i] then

			if i == 5 then

				self._shipList[i].renderer:setPosition(beginPos.x - diffX*i, beginPos.y)
				if self._shipList[i].renderer:getParent() == nil then
					self:addChild(self._shipList[i].renderer)
				end
			end

			if self._shipList[i].renderer ~= nil then
				self._shipList[i].renderer:runAction(cc.MoveTo:create(0.5,cc.p(beginPos.x - diffX*(i-1), beginPos.y)))
			end
		end
	end

	return prePos, preIsBig
end

return AttackList