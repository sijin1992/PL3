
local Ship = require("app.battle.Ship")
local Gmath = require("app.Gmath")
local player = require("app.Player"):getInstance()


local BattleManager = class("BattleManager")

local touch_debug = false

BattleManager.scene = nil

BattleManager.maxEnergy = 100

BattleManager.owner = {  --owner

	ship_pos = {},

	bullet_plane = nil,

	ship = nil,

	bullet_direct = cc.p(0.89,0.454),

	roleinfo = nil
}

BattleManager.enemy = {  --enemy

	ship_pos = {},

	bullet_plane = nil,

	ship = nil,

	bullet_direct = cc.p(-0.89,-0.454),

	roleinfo = nil
}

BattleManager.eventIndex = 0
BattleManager.curEvent = nil
BattleManager.eventList = nil

BattleManager.updateSwitch = true

BattleManager.isPve_ = true


function BattleManager:getGroupByNum(group)
	local key = (group == 1 and "owner") or "enemy"
	return self[key]
end


function BattleManager:getShip(group,row,col)
	local index = nil
	if col == nil then
		index = row
		return self:getGroupByNum(group).ship[index]
	end
	index = (row - 1) * 3 + col
	return self:getShipByIndex(group, index)
end

function BattleManager:getShipByIndex(group,index)

	return self:getGroupByNum(group).ship[index]
end



function BattleManager:getInfoByKey(group,key,flag)

	if group < 0 or group > 3 then
		return nil
	end

	if flag == true or flag == nil then

		return self:getGroupByNum(group)[key]
		
	else
		if group == 1 then
			return self.enemy[key]
		elseif group == 2 then
			return self.owner[key]
		end
	end
end


function BattleManager:getBattleScene()
	return self.scene
end

function BattleManager:getUINode()
	return self.scene:getResourceNode():getChildByName("ui_layer")
end

function BattleManager:getObjectNode()
	return self.scene:getResourceNode():getChildByName("object_layer")
end

function BattleManager:getBulletNode(group,flag)

	if group < 0 or group > 3 then
		return nil
	end

	local name = (group == 1 and "owner") or "enemy"

	local layer = self.scene:getResourceNode():getChildByName("bullet_layer")

	if flag == true or flag == nil then
		
		return layer:getChildByName(name)
	else
		if name == "owner" then
			return layer:getChildByName("enemy")
		elseif name == "enemy" then
			return layer:getChildByName("owner")
		end
	end
end

function BattleManager:getShipPos(groupNum, num, flag)

	return self:getInfoByKey(groupNum, "ship_pos", flag)[num]
end

function BattleManager:getSkillConfig(id)

	return CONF.WEAPON.get(id)
end

function BattleManager:createEvent(data)
	

	if data == nil then
		return nil
	end

	

	if data.id == 1 then

		data.event_type = "WinEvent"

	elseif data.id == 2 then

		if not data.attack_list or Tools.isEmpty(data.attack_list) then
			data.event_type = "BuffAttackEvent"
		else
			data.event_type = self:getSkillConfig(data.values[1]).LOGIC_ID
		end

	elseif data.id == 5 then

		data.event_type = self:getSkillConfig(data.values[1]).BUFF_LOGIC_ID[data.values[2]]

	elseif data.id == 3 then

		data.event_type = "ResetBuffEvent"

	elseif data.id == 4 then

		data.event_type = "RoundEvent"
	elseif data.id == 6 then

		data.event_type = "AttackListEvent"

	elseif data.id == 7 then

		data.event_type = "EnergyEvent"
	end


	s_event_step = s_event_step + 1

	local str = string.format("app.battle.event.%s",data.event_type)

	return require(str):create(data,self)
end

function BattleManager:loseNow( )
	if self.isPve_ == true then
		self.fightPveManager:loseNow()
	end
end

function BattleManager:showResult()
	if self.isPve_ == false then
		for i,v in ipairs(self.eventDataList) do
			if v.id == 1 then
				if self.eventIndex ~= (i - 1) then
					self.eventIndex = i - 1
				end
				break
			end
		end
	end
end

function BattleManager:pushEventData()

	local function getEventData()
		local event = self.fightPveManager:getEvent()
		if event ~= nil then
			
			return event
		end

		while event == nil do

			self.fightPveManager:doLogic()

			event = self.fightPveManager:getEvent()

			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BattleDoLogic")
		end
		assert(event,"error")

		return event
	end

	local eventData = getEventData()

	table.insert(self.eventDataList, eventData)
end

function BattleManager:onFrameEvent( str )
	if str == "icon_bg_in" then

		for k,v in pairs(self.owner.ship) do
			if v ~= nil then
				v:onFrameEvent(str)
			end
		end

		-- ADD WJJ 20180802
		require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Battle_ShowEnemyShip(self.enemy.ship)
	end
end

function BattleManager:ctor(scene,list_my,list_enemy, event_list, switchGroup)

	--get plane:
	--local plane = Gmath.getPlane({cc.p(344,564),cc.p(672,130)})
	--printInfo("plane:",plane.n.x,plane.n.y,plane.l)
	--plane = Gmath.getPlane({cc.p(725,141),cc.p(410,554)})
	--printInfo("plane:",plane.n.x,plane.n.y,plane.l)

	--get direct
	-- local function getDirect(org,dist)
	-- 	local dir = cc.pSub(dist,org)
	-- 	return cc.pNormalize(dir)
	-- end
	-- local dir = getDirect(cc.p(717,169),cc.p(613,222))
	-- printInfo("ray :",dir.x,dir.y)
	self.eventDataList = {}
	if event_list ~= nil then

		self.eventDataList = Tools.decode_event_list(event_list)
		self.isPve_ = false
	else
		
		self.isPve_ = true
	end

	if switchGroup == true then
		local list = list_my
		list_my = list_enemy
		list_enemy = list

		for _,event in ipairs(self.eventDataList) do
			if Tools.isEmpty(event.attack_list) == false then
				for i=1,#event.attack_list do

					event.attack_list[i].pos[1] = Tools.mod(event.attack_list[i].pos[1] + 1, 2) 
				end
			end
			if Tools.isEmpty(event.hurter_list) == false then
				for i=1,#event.hurter_list do
					
					event.hurter_list[i].pos[1] = Tools.mod(event.hurter_list[i].pos[1] + 1, 2)
				end
			end

			if event.id == 1 then

				if event.values[1] == 1 then
					event.values[1] = 2 
				else 
					event.values[1] = 1
				end

				local temp
				temp = event.values[3]
				event.values[3] = event.values[4]
				event.values[4] = temp
				
				temp = event.values[5]
				event.values[5] = event.values[7]
				event.values[7] = temp

				temp = event.values[6]
				event.values[6] = event.values[8]
				event.values[8] = temp
			end
		end
	end

	self.eventIndex = 1
	self.updateSwitch = true

	self.scene = scene
	self.owner.ship = {}
	self.enemy.ship = {}
	

	self.myDoBigSkillShipList = {}

	self.owner.roleinfo = {energy = 0,hp = 0,maxhp = 0,}
	self.enemy.roleinfo = clone(self.owner.roleinfo)	

	local battleType = self:getBattleScene():getBattleType()

	local center = cc.exports.VisibleRect:center()


	local ownerFightPower = 0
	for i, v in ipairs(list_my) do

		local obj = Ship:create(self,v,1,i)

		-- ADD WJJ 20180802
		require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Battle_DelayShowShip(obj)

		self.owner.ship[v.position] = obj

		self.owner.roleinfo.maxhp = self.owner.roleinfo.maxhp + obj:getAttr(CONF.EShipAttr.kHP)

		ownerFightPower = ownerFightPower + Tools.calShipFightPower(v, v.weapon_list)
	end
	self.ownerFightPower = ownerFightPower
	

	if battleType == BattleType.kTrial then
		local hp = 0
		local hp_list = self:getBattleScene():getData().hp_list
		for index=1,9 do
			local ship = self.owner.ship[index]
			if ship then
				self.owner.ship[index]:setAttr(CONF.EShipAttr.kHP, hp_list[index])
				self.owner.ship[index]:updateUIHp()
				if hp_list[index] <= 0 then
					ship:setDead()
				end

				hp = hp + hp_list[index]
			end
		end

		self.owner.roleinfo.hp = hp


	else

		self.owner.roleinfo.hp = self.owner.roleinfo.maxhp
	end

	self:getBattleScene():setHpPercentage(1, self.owner.roleinfo.maxhp, self.owner.roleinfo.hp, true)

	


	local enemyFightPower = 0
	for i, v in ipairs(list_enemy) do

		local obj = Ship:create(self,v,2,i)

		-- ADD WJJ 20180802
		require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Battle_DelayShowShip(obj)

		self.enemy.ship[v.position] = obj

		self.enemy.roleinfo.maxhp = self.enemy.roleinfo.maxhp + obj:getAttr(CONF.EShipAttr.kHP)

		enemyFightPower = enemyFightPower + Tools.calShipFightPower(v, v.weapon_list)
	end
	self.enemyFightPower = enemyFightPower

	if battleType == BattleType.kGroupBoss then
		local hp = 0
		local hp_list = self:getBattleScene():getData().hurter_hp_list
		for index=1,9 do
			local ship = self.enemy.ship[index]
			if ship then
				self.enemy.ship[index]:setAttr(CONF.EShipAttr.kHP, hp_list[index])
				self.enemy.ship[index]:updateUIHp()
				if hp_list[index] <= 0 then
					ship:setDead()
				end

				hp = hp + hp_list[index]
			end
		end

		self.enemy.roleinfo.hp = hp
	else

		self.enemy.roleinfo.hp = self.enemy.roleinfo.maxhp
	end


	self:getBattleScene():setHpPercentage(2, self.enemy.roleinfo.maxhp, self.enemy.roleinfo.hp, true)

	self:setEnergy(1,0)

	if self.isPve_ == true then
		self.fightPveManager = require("FightLogic.FightControler")
		local hp_list = nil
		local hurter_hp_list = nil
		if battleType == BattleType.kTrial then
			hp_list = self:getBattleScene():getData().hp_list
		elseif battleType == BattleType.kGroupBoss then
			hurter_hp_list = self:getBattleScene():getData().hurter_hp_list
		end
		local pve = true
		if cc.UserDefault:getInstance():getBoolForKey(player:getName().."_isPve") == true then
			pve = false
		end
		self.fightPveManager:init(list_my, hp_list, list_enemy, hurter_hp_list, pve)
		self:pushEventData()
	end

	self.attackList_ = require("app.battle.AttackList"):create(self, cc.p(self.scene:getResourceNode():getChildByName("attack_list_pos"):getPosition()) )
	
	self:getUINode():addChild(self.attackList_)


	-- require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Battle_DelayShowShip(self.attackList_)

	

	return ownerFightPower, enemyFightPower
end 

function BattleManager:getAttackList()
	return self.attackList_
end

function BattleManager:update(dt)
-- print("uuuuuuuuuuuu", self.updateSwitch)
	if self.updateSwitch == false then
		return
	end

	if self.curEvent == nil then

		self.curEvent = self:createEvent(self.eventDataList[self.eventIndex]) 
		if self.curEvent == nil then

			return
		else
			self.curEvent:start()
			self.curEvent:check()
		end

	else

		local flag = self.curEvent:process(dt)

		if flag == true then

			self.curEvent:finish()

			--touch control switch
			if self.isPve_ == true then
				if touch_debug == false then
					self:pushEventData()
				end
			end
			--

			self.eventIndex = self.eventIndex + 1
			self.curEvent = nil
		end
	end


	for k,v in pairs(self:getInfoByKey(1,"ship")) do
		v:update(dt)
	end

	for k,v in pairs(self:getInfoByKey(2,"ship")) do
		v:update(dt)
	end
end

function BattleManager:getUpdateSwitch()
	return self.updateSwitch
end

function BattleManager:resume()



	self.updateSwitch = true

	for k,v in pairs(self:getInfoByKey(1,"ship")) do
		v:resume()
	end

	for k,v in pairs(self:getInfoByKey(2,"ship")) do
		v:resume()
	end
	if self.curEvent then
		self.curEvent:resume()
	end
end

function BattleManager:pause()

	
	self.updateSwitch = false

	for k,v in pairs(self:getInfoByKey(1,"ship")) do
		v:pause()
	end

	for k,v in pairs(self:getInfoByKey(2,"ship")) do
		v:pause()
	end

	if self.curEvent then
		self.curEvent:pause()
	end
end

function BattleManager:getEnergy(group)
	local target = nil
	if group < 0 or group > 3 then
		return
	end

	if group == 1 then
		target = self.owner.roleinfo
	else 
		target = self.enemy.roleinfo
	end

	return target.energy
end

function BattleManager:setEnergy(group, value, orgPos)

	local target = nil
	if group < 0 or group > 3 then
		return
	end

	if group == 1 then
		target = self.owner.roleinfo
	else 
		target = self.enemy.roleinfo
	end
	target.energy = target.energy + value

	if group == 1 then

		self:getBattleScene():setEnergyPercentage(self.maxEnergy, target.energy, orgPos)

		-- for i,v in pairs(self:getInfoByKey(1,"ship")) do
		-- 	v:changedEnergy()
		-- end
	end	
end

function BattleManager:setHP( group, value )
	local target = nil
	if group < 0 or group > 3 then
		return
	end

	if group == 1 then
		target = self.owner.roleinfo
	else 
		target = self.enemy.roleinfo
	end

	target.hp = target.hp + value

	if target.hp < 0 then
		target.hp = 0
	end

	self:getBattleScene():setHpPercentage(group, target.maxhp, target.hp)
end

function BattleManager:isPve(  )
	return self.isPve_
end
function BattleManager:isFightPve()
	return self.fightPveManager:isPve()
end
function BattleManager:setPve(ispve)
	cc.UserDefault:getInstance():setBoolForKey(player:getName().."_isPve",ispve)
	cc.UserDefault:getInstance():flush()
	self.fightPveManager:setPve(not ispve)
end

function BattleManager:onTouchBegan(touch, event)

	local target = event:getCurrentTarget()

	-- if self.isPve_ == true then
	-- 	for k,v in pairs(self.owner.ship) do

	-- 		local locationInNode = v:getRenderer():convertToNodeSpace(touch:getLocation())
	-- 		local s = cc.size(102,64)

	-- 		local rect = cc.rect(-s.width*0.5, -s.height*0.5, s.width + 20, s.height + 20)

	-- 		if cc.rectContainsPoint(rect, locationInNode) then
	-- 			v:onTouchBegan(touch, event)
	-- 			return true
	-- 		end
	-- 	end
	-- end

	--touch control switch
	-- if self.isPve_ == true then
	-- 	if touch_debug == true then
	-- 		self:pushEventData()
	-- 	end
	-- end
	--

	return false
end

function BattleManager:isLastShip( group )
	local ships
	if group == 1 then
		ships = self.owner.ship
	else
		ships = self.enemy.ship
	end
	local count = 0
	for k,v in pairs(ships) do
		if v:getRenderer():isVisible() == true then
			count = count + 1
		end
	end
	if count == 0 then
		return true
	end
	return false
end

return BattleManager