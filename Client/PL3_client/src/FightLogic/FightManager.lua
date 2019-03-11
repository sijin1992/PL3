local FightShip = require("FightLogic.FightShip")
local FightEvent = require("FightLogic.FightEvent")

local player = require("app.Player"):getInstance()
-- group all = 0
-- group our = 1
-- group enemy = 2

-- local rowindex = 2
-- local colindex = 3

local rowMax = 3
local colMax = 3

local maxRound = 20

local FightManager = {}

FightManager.POS =
{
	{
		{1,1,1},{1,1,2},{1,1,3},
		{1,2,1},{1,2,2},{1,2,3},
		{1,3,1},{1,3,2},{1,3,3},
	},

	{
		{2,1,1},{2,1,2},{2,1,3},
		{2,2,1},{2,2,2},{2,2,3},
		{2,3,1},{2,3,2},{2,3,3},
	},
}



function FightManager:getShipByPos( pos )
	return self.group_[pos[1]][pos[2]][pos[3]]
end



function FightManager:resetAttackers(objects)
	self.attackers_ = objects
end

function FightManager:resetHurters(objects)
	self.hurters_ = objects
end

function FightManager:getAttackers()
	return self.attackers_
end

function FightManager:getHurters()
	return self.hurters_
end


function FightManager:getHasSpecialShips(group,key,num)
	local t = {}
	local count = 0
	num = num == 0 and 9 or num

	for col=1,colMax do
		for row=1,rowMax do

			if group[row][col] and group[row][col]:isCanHurt() and group[row][col]:hasSpecial(key) == true then
				
				table.insert(t, group[row][col])
				count  = count + 1
				if count >= num then
					return t
				end
			end
		end
	end

	if Tools.isEmpty(t) then
		return nil
	end
	return t
end

function FightManager:getHasSpecialShipsByGroupIndex(groupIndex, key,num )
	
	return self:getHasSpecialShips(self.group_[groupIndex], key, num)
end

function FightManager:getGroupId( group )
	if self.group_[1] == group then
		return 1
	end
	return 2
end

function FightManager:getShipsByOne(isSameGroup, pos, isTest) 

	local t = {} 

	local group = self.group_[isSameGroup and pos[1] or Tools.mod(pos[1] + 1, 2)]

	if isSameGroup == false then
		local psList = self:getHasSpecialShips(group,CONF.EShipSpecial.kProvocation,1)
		if psList ~= nil then
			table.insert(t, psList[1])
			return t
		end
	end

	for i=0, rowMax-1 do

		local curRow
		if pos[2] == rowMax then
			curRow = Tools.mod(pos[2] - i, rowMax)
		else
			curRow = Tools.mod(pos[2] + i, rowMax)
		end

		for j=1, colMax do
			
			local temp = group[curRow][j]
			if temp and temp:isCanHurt() then
				if isTest and isTest == true then
					table.insert(t, temp:getPos())
				else
					table.insert(t, temp)
				end
				return t
			end
		end
	end

	return nil
end

function FightManager:getShipsByRowCol( group, row, col, isTest) -- row col 0:all
	local t = {}

	local rowStart,rowEnd
	local colStart,colEnd

	if row == 0 then
		rowStart = 1
		rowEnd = rowMax
	else
		rowStart = row
		rowEnd = row
	end

	if col == 0 then
		colStart = 1
		colEnd = colMax
	else
		colStart = col
		colEnd = col
	end


	for i=rowStart,rowEnd do
		for j=colStart, colEnd do
			if isTest and isTest == true then
				table.insert(t, {self:getGroupId(group), i, j})
			else
				local temp = group[i][j]
				if temp and temp:isCanHurt() then
					table.insert(t, temp)
				end
			end
		end
	end

	return t
end

function FightManager:getShipsByCol(isSameGroup, pos, isBack, isTest) 


	local group = self.group_[isSameGroup and pos[1] or Tools.mod(pos[1] + 1, 2)]


	if isSameGroup == false then
		local psList = self:getHasSpecialShips(group,CONF.EShipSpecial.kProvocation,1)
		if psList then
			local pos = psList[1]:getPos()
			return self:getShipsByRowCol(group, 0, pos[3], isTest)
		end
	end


	local colStart, colEnd, flag
	if isBack == true then
		colStart = colMax
		colEnd = 1
		flag = -1
	else
		colStart = 1
		colEnd = colMax
		flag = 1
	end

	for col=colStart, colEnd, flag do

		for row=1,rowMax do
			local temp = group[row][col]
			if temp and temp:isCanHurt() then
				
				return self:getShipsByRowCol(group, 0, col, isTest)
			end
			
		end
	end

	return nil
end



function FightManager:getShipsByRow(isSameGroup, pos, isTest) 

	local group = self.group_[isSameGroup and pos[1] or Tools.mod(pos[1] + 1, 2)]

	if isSameGroup == false then
		local psList = self:getHasSpecialShips(group,CONF.EShipSpecial.kProvocation,1)
		if psList then
			local pos = psList[1]:getPos()
			return self:getShipsByRowCol(group, pos[2], 0, isTest)
		end
	end

	for i=0, rowMax-1 do

		local curRow = Tools.mod(pos[2] + i, rowMax)

		for j=1, colMax do
			
			local temp = group[curRow][j]
			if temp and temp:isCanHurt() then
				
				return self:getShipsByRowCol(group, curRow, 0, isTest)
			end
		end
	end

	return nil
end

function FightManager:_getShipsByGroup( isSameGroup, pos ) -- nil == all

	if isSameGroup == nil then
		local all = {}
		local our = self:getShipsByRowCol(self.group_[pos[1]], 0, 0)
		local enemy = self:getShipsByRowCol(self.group_[Tools.mod(pos[1] + 1, 2)], 0, 0)

		for i,v in ipairs(our) do
			table.insert(all, v)
		end

		for i,v in ipairs(enemy) do
			table.insert(all, v)
		end
		return all
	end



	if isSameGroup == true then
		return self:getShipsByRowCol(self.group_[pos[1]], 0, 0)
	elseif isSameGroup == false then
		return self:getShipsByRowCol(self.group_[Tools.mod(pos[1] + 1, 2)], 0, 0)
	end
end

function FightManager:getShipsByRand(isSameGroup, pos, nums, isTest) -- nums(0:all)

	local t = {}
	local list = self:_getShipsByGroup(isSameGroup, pos)

	if nums == 0 then
		t = list
	else
		local count = #list

		local group = self.group_[isSameGroup and pos[1] or Tools.mod(pos[1] + 1, 2)]
		local psList = self:getHasSpecialShips(group,CONF.EShipSpecial.kProvocation,nums)
		
		if psList then
			local psCount = #psList
			for i=nums,1,-1 do
				if Tools.isEmpty(psList) then
					break
				end
				local index = math.random(psCount)
				table.insert(t, psList[index])
				table.remove(psList,index)
				psCount = psCount - 1
				nums = nums - 1
			end
		end

		for i=nums,1,-1 do

			if Tools.isEmpty(list) then
				break
			end
			local index = math.random(count)
			table.insert(t,list[index])
			table.remove(list,index)
			count = count - 1
		end
	end



	if isTest and isTest == true then
		local tempList = {}
		for i,v in ipairs(t) do
			table.insert(tempList, v:getPos())
		end
		t = tempList
	end
	
	return t
end

-- flag(max:true min:false)
function FightManager:getShipsByAttr(isSameGroup, pos, attrKey, flag, isTest)

	local t = {}

	local list = self:_getShipsByGroup(isSameGroup, pos)


	local bestValue,value,bestIndex

	for i,v in ipairs(list) do
		local value = v:getAttrByKey(attrKey)
		if bestValue == nil then
			bestValue = value
			bestIndex = i
		elseif flag==true and value > bestValue  then
			bestValue = value
			bestIndex = i
		elseif flag==false and value < bestValue  then
			bestValue = value
			bestIndex = i
		end
		
	end

	table.insert(t, list[bestIndex])
	if isTest and isTest == true then
		t = {t[1]:getPos()}
	end
	return t
end

function FightManager:isPve()
	return self.isPve_
end

function FightManager:setPve(ispve)
	self.isPve_ = ispve
end

function FightManager:getAnger(index)
	assert(index >0 and index < 3, "error")
	return self.anger_[index]
end

function FightManager:setAnger(index,value)
	local old = self.anger_[index]

	if value < 0 then
		value = 0
	elseif value > 100 then
		value = 100
	end

	self.anger_[index] = value
	return self.anger_[index] ~= old
end


function FightManager:getHitValue( groupIndex )
	return self.hitValue_[groupIndex]
end


function FightManager:addHitValue( groupIndex, value )
		
	if value < 0 then
		return
	end

	self.hitValue_[groupIndex] = self.hitValue_[groupIndex] + value
end

function FightManager:getShipNum( groupIndex, countLive, needHpList )

	local ships = {}

	local function isExist(obj)
		for i,v in ipairs(ships) do
			if v == obj then
				return true
			end
		end
		return false
	end

	local hp_list = {0,0,0,0,0,0,0,0,0,}

	for row=1,rowMax do
		for col=1,colMax do
			if self.group_[groupIndex][row][col] then

				if countLive == true and self.group_[groupIndex][row][col]:isCanHurt() == false then

				else
					if isExist(self.group_[groupIndex][row][col]) == false then

						table.insert(ships, self.group_[groupIndex][row][col])

						if needHpList == true then
							local hp = self.group_[groupIndex][row][col]:getAttrByKey(CONF.EShipAttr.kHP)
							if hp < 0 then
								hp = 0
							end
							hp_list[(row-1)*3 + col] = hp
						end
					end

					
				end
			end
		end
	end

	if needHpList == true then
		return #ships, hp_list
	else
		return #ships
	end
end

function FightManager:getFightTime()
	return os.time() - self.fightStartTime_
end

function FightManager:init(attack_list, attack_hp_list, hurter_list, hurter_hp_list, isPve)

	-- ADD WJJ 20180803
	cc.exports.G_is_battle_over = false

	self.isPve_ = isPve

	self.fightList_ = nil

	self.curTime_ = 0

	self.round_ = 0

	self.eventList_ = {}

	self.anger_ = {0,0}

	self.hitValue_ = {0,0}

	self.fightStartTime_ = os.time()

	self.LoseSwitch = false

	local attack_group = {{},{},{}}

	for i,v in ipairs(attack_list) do
		local ship = FightShip:create(self,v,FightManager.POS[1][v.position])
		if attack_hp_list and attack_hp_list[i] then
			ship:setAttrByKey(CONF.EShipAttr.kHP, attack_hp_list[v.position])

		end

		for _,pos in ipairs(v.body_position) do

			local pos = FightManager.POS[1][pos]
			attack_group[pos[2]][pos[3]] = ship
		end
	end

	local hurter_group = {{},{},{}}

	for i,v in ipairs(hurter_list) do

		local ship = FightShip:create(self,v,FightManager.POS[2][v.position])

		if hurter_hp_list and hurter_hp_list[i] then
			ship:setAttrByKey(CONF.EShipAttr.kHP, hurter_hp_list[v.position])
		end

		for _,pos in ipairs(v.body_position) do

			local pos = FightManager.POS[2][pos]
			hurter_group[pos[2]][pos[3]] = ship
		end
	end

	self.group_ = {attack_group,hurter_group}

	math.randomseed(self.fightStartTime_)
end

function FightManager:destroy()
	self.group_ = nil
	self.eventList_ = nil
	self.round_ = nil
	self.fightList_ = nil
end

function FightManager:pushEvent( event )

	assert(event.id , "error")

	table.insert(self.eventList_, event)
end

function FightManager:popEvent()
	local event = self.eventList_[1]
	table.remove(self.eventList_, 1)
	return event
end

function FightManager:fightOrder()

	local function isExist(obj)
		for i,v in ipairs(self.fightList_) do
			if v.obj == obj then
				return true
			end
		end
		return false
	end

	self.fightList_ = {}

	for i=1,2 do
		for row=1,rowMax do
			for col=1,colMax do
				if self.group_[i][row][col] and self.group_[i][row][col]:isCanHurt() then
					if isExist(self.group_[i][row][col]) == false then

						table.insert(self.fightList_, {obj = self.group_[i][row][col], isBig = false})
					end
				end
			end
		end
	end

	self:resetFightOrder()
end

function FightManager:resetFightOrder()


	local function comps( a,b )
		if a.isBig == true and b.isBig == false then
			return true
		elseif a.isBig == false and b.isBig == true then
			return false
		else
			return a.obj:getAttrByKey(CONF.EShipAttr.kSpeed) > b.obj:getAttrByKey(CONF.EShipAttr.kSpeed)
		end
	end

	table.sort(self.fightList_, comps) 

	self:syncFightOrder()
end

function FightManager:syncFightOrder()

	local event = FightEvent:create(FightEvent.EventType.kFightList, {1})
	for i,v in ipairs(self.fightList_) do
		event:addAttacker({pos = v.obj:getPos(), isBig = v.isBig})
	end
	self:pushEvent(event:getEvent())
end

function FightManager:removeFightOrder(pShip)

	for i,v in ipairs(self.fightList_) do
		if v.obj == pShip then
			table.remove(self.fightList_, i)


			local event = FightEvent:create(FightEvent.EventType.kFightList, {2})

			event:addAttacker({pos = v.obj:getPos()})
	
			self:pushEvent(event:getEvent())

			break
		end
	end
end

function FightManager:isGroupDead( index )
	for row=1,rowMax do
		for col=1,colMax do
			if self.group_[index][row][col] and self.group_[index][row][col]:isCanHurt() then
				return false
			end
		end
	end

	return true
end

function FightManager:isFightGetResult()

	local function countEndData(isWin)

		local myShipLiveNum, myHpList = self:getShipNum(1, true, true)
		local enemyShipLiveNum, enemyHpList = self:getShipNum(2, true, true)

		local resultData = {}
		resultData[1] = isWin
		resultData[2] = self:getFightTime()
		resultData[3] = self:getHitValue(1)
		resultData[4] = self:getHitValue(2)
		resultData[5] = myShipLiveNum
		resultData[6] = self:getShipNum(1,false)
		resultData[7] = enemyShipLiveNum
		resultData[8] = self:getShipNum(2,false)
		resultData[9] = self.round_
		return resultData, myHpList, enemyHpList
	end

	if self.LoseSwitch == true then
		printInfo("self.LoseSwitch == true")
		self.LoseSwitch = false
		local values, myHpList, enemyHpList = countEndData(2)
		self:pushEvent(FightEvent:create(FightEvent.EventType.kWin,values, nil, nil, myHpList, enemyHpList):getEvent())
		return true
	end

	for i=1,2 do
		if self:isGroupDead(i) then
			printInfo("group is dead", i)

			-- ADD WJJ 20180803
			cc.exports.G_is_battle_over = true

			local values, myHpList, enemyHpList = countEndData(i == 2 and 1 or 2)
			self:pushEvent(FightEvent:create(FightEvent.EventType.kWin, values, nil, nil, myHpList, enemyHpList):getEvent())
			return true
		end
	end

	if self.round_ > maxRound then
		printInfo("max round!")
		local values, myHpList, enemyHpList = countEndData(2)
		self:pushEvent(FightEvent:create(FightEvent.EventType.kWin,values, nil, nil, myHpList, enemyHpList):getEvent())
		return true
	end
	

	return false
end

function FightManager:checkDoSkill(  )
	local group_small_hp = {false,false}

	for i=1,2 do
		for row=1,rowMax do
			for col=1,colMax do
				if self.group_[i][row][col] and self.group_[i][row][col]:isCanHurt() then
					
					if self.group_[i][row][col]:isSmallHP() == true then
						group_small_hp[i] = true
					end
				end
			end
		end
	end

	local function sort( a, b )
		local group_a = a:getPos()[1]
		local group_b = b:getPos()[1]
		if group_a == group_b then
			if group_small_hp[group_a] == true then
				local a_flag = a:isCureSkill()
				local b_flag = b:isCureSkill()
				if b_flag == true and a_flag == false then
					return false
				elseif b_flag == false and a_flag == true then
					return true
				end
			end
		end
		if b:getAttrByKey(CONF.EShipAttr.kSpeed) > a:getAttrByKey(CONF.EShipAttr.kSpeed) then
			return false
		elseif b:getAttrByKey(CONF.EShipAttr.kSpeed) < a:getAttrByKey(CONF.EShipAttr.kSpeed) then
			return true
		end
		if b:getQuality() > a:getQuality() then
			return false
		elseif b:getQuality() < a:getQuality() then
			return true
		end
		if b:getLevel() > a:getLevel() then
			return false
		elseif b:getLevel() < a:getLevel() then
			return true
		end
		if b:getID() > a:getID() then
			return false
		else
			return true
		end
	end

	local cur = {}
	for i=1,2 do
		for row=1,rowMax do
			for col=1,colMax do
				if self.group_[i][row][col] and self.group_[i][row][col]:isCanHurt() then
					if self.group_[i][row][col]:checkDoSkill() == true then
						if cur[i] == nil then
							cur[i] = {row, col}
						elseif sort(self.group_[i][cur[i][1]][cur[i][2]], self.group_[i][row][col]) == false then
							cur[i][1] = row
							cur[i][2] = col
						end
					end
				end
			end
		end
	end

	local pos
	if cur[1] ~= nil and cur[2] ~= nil then
		if sort(self.group_[1][cur[1][1]][cur[1][2]], self.group_[2][cur[2][1]][cur[2][2]]) then
			pos = {1, cur[1][1], cur[1][2]}
		else
			pos = {2, cur[2][1], cur[2][2]}
		end
	elseif cur[1] ~= nil then
		pos = {1, cur[1][1], cur[1][2]}
	elseif cur[2] ~= nil then
		pos = {2, cur[2][1], cur[2][2]}
	end

	if pos == nil then
		return false
	end
	local ship = self.group_[pos[1]][pos[2]][pos[3]]
	if (pos[1] == 2) or (self:isPve() == false) then
		local has = false
		for i,v in ipairs(self.fightList_) do
			if v.obj == ship and v.isBig == true then
				has = true
				break
			end
		end
		if has == false then
			table.insert(self.fightList_, {obj = ship, isBig = true})
		end
		self:resetFightOrder()
		ship:doSkillSubEnergy()
	end
	--ship:doSkill()
	return true
end

function FightManager:doLogic()

	if self:isFightGetResult() then
		return
	end

	if Tools.isEmpty(self.fightList_) then

		self.round_ = self.round_ + 1
		
		self:pushEvent(FightEvent:create(FightEvent.EventType.kRound,{self.round_}):getEvent())

		self:fightOrder()
		return
	end

	while (self:checkDoSkill()) do
		if self:isFightGetResult() then
			return
		end
	end


	if not Tools.isEmpty(self.fightList_) then

		local attacker = self.fightList_[1].obj
		local isBig = self.fightList_[1].isBig
		if isBig == true then
			if attacker and attacker:isDead() == false then
				local pos = attacker:getPos()
				attacker:doSkill()
			end
		else
			attacker:fight( self.round_ )
		end

		table.remove(self.fightList_, 1)

		local event = FightEvent:create(FightEvent.EventType.kFightList, {3})
		self:pushEvent(event:getEvent())
	end

end

function FightManager:printFightList(num)
	print("print fight list :", num)
	for i,v in ipairs(self.fightList_) do
		local pos = v.obj:getPos()
		print("fight list ", i, pos[1], pos[2], pos[3], v.isBig)
	end
end

function FightManager:doSkill( shipPos )

	local ship = self:getShipByPos(FightManager.POS[1][shipPos])
	if ship and ship:isDead() == false then
		table.insert(self.fightList_, {obj = ship, isBig = true})
		self:resetFightOrder()
		return ship:doSkillSubEnergy()
	end
	return 0
end

function FightManager:addTime( delta )
	self.curTime_ = self.curTime_ + delta
end

function FightManager:getTime( )
	return self.curTime_
end

local function posNum2Table(group_id, num )
	local row = math.ceil(num/3)
	local col = math.mod(num,3) == 0 and 3 or math.mod(num,3)

	return {group_id, row, col}
end

local function posTable2Num( table )
	
	return table[1], (table[2] - 1) * colMax + table[3]
end

function FightManager:getSkillTargetTest(position)
	local pos = FightManager.POS[1][position]
	local fightShip = self.group_[1][pos[2]][pos[3]]
	local weaponConf = fightShip:getWeaponConfBySkill()
	if fightShip == nil then
		print("no fightShip",position, pos[2], pos[3] )
		return nil 
	end
	local targets_list
	
	if weaponConf.TARGET_1 == 0 then
		if Tools.isEmpty(weaponConf.BUFF_TARGET_1) == true then
			return nil
		end
		local buff_target_index = 0
		local buff_target = 0
		for index,target in ipairs(weaponConf.BUFF_TARGET_1) do
			if target > buff_target then
				buff_target_index = index
			end
		end
		if buff_target_index == 0 then
			return nil
		end
		targets_list = fightShip:getTargetByConf(weaponConf.BUFF_TARGET_1[buff_target_index], weaponConf.BUFF_TARGET_2[buff_target_index], weaponConf.BUFF_TARGET_3[buff_target_index], true)
		
	else
		targets_list = fightShip:getTargetByConf(weaponConf.TARGET_1, weaponConf.TARGET_2, weaponConf.TARGET_3, true)
	end
	if Tools.isEmpty(targets_list) == true then
		return nil
	end
	local group = {{}, {}}
	for i,v in ipairs(targets_list) do
		local group_id, index = posTable2Num(v)
		table.insert(group[group_id], index)
	end

	return group
end

return FightManager