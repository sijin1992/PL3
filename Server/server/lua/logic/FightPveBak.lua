local FightPve = {}
FightPve.__index = FightPve

function FightPve:addBuff(attack_pos, defence_pos)
	local buff_list = {}

	local buff_conf = self:getBuffConf(attack_pos)
	if buff_conf then
		local target_list = self:getTargetList(attack_pos, defence_pos, buff_conf.TYPE)
		for k,v in ipairs(target_list) do
			local iPos = self:getPos(v)
			self.m_buff_list[iPos][buff_conf.ID] = {buff_conf.ROUND,0}
			if not buff_list[iPos] then
				buff_list[iPos]= {}
			end
			table.insert(buff_list[iPos], buff_conf.ID)
		end
	end

	buff_conf = self:getBuffConf(defence_pos)
	if buff_conf then
		local target_list = self:getTargetList(attack_pos, defence_pos, buff_conf.TYPE)
		for k,v in ipairs(target_list) do
			local iPos = self:getPos(v)
			self.m_buff_list[iPos][buff_conf.ID] = {buff_conf.ROUND,0}
			if not buff_list[iPos] then
				buff_list[iPos]= {}
			end
			table.insert(buff_list[iPos], buff_conf.ID)
		end
	end

	return buff_list
end

function FightPve:addEvent(event_info)
	table.insert(self.m_event_list, event_info)
end

function FightPve:checkBuff()
	local buff_list = self.m_buff_list
	for k,v in pairs(buff_list) do
		for kk,vv in ipairs(v) do
			if vv.COUNT > 0 then
				vv.COUNT = vv.COUNT - 1
			end
			if vv.ROUND > 0 then
				vv.ROUND = vv.ROUND - 1
			end
		end
	end
end

function FightPve:checkKey(conf, key)
	local is = false
	for k,v in ipairs(conf.KEY) do
		if v == key then
			is = true
		end
	end
	return is
end

function FightPve:changeSpeed(iPos, iRound, iSpeed)
	self.m_speed_list[iPos][2] = iRound
	self.m_speed_list[iPos][3] = iSpeed
end

function FightPve:compare(t1, t2)
	return t1[1] == t2[1] and t1[2] == t2[2] and t1[3] == t2[3]
end

function FightPve:doFight()
	local attack_pos = self:getAttack()
	local attack_info = self:getShipInfo(attack_pos)
	local attack_buff
	local defence_buff
	local isWin
	local attack_list = {}
	local hurter_list = {}
	local weapon_id_attack = attack_info.weapon_list[self:m(self.m_round, 3)]
	if weapon_id_attack > 0 then
		local defence_pos = self:getDefence(attack_pos)
		if defence_pos then
			local defence_info = self:getShipInfo(defence_pos)
			local buff_list_init = self:addBuff(attack_pos, defence_pos)

			local attack_add = 0
			local defence_add = 0

			local buff_list_attack = self:getBuffList(attack_pos)
			for k,v in ipairs(buff_list_attack) do
				local conf = CONF.BUFF.get(v)
				if self:checkKey(conf, 2) then
					attack_add = attack_add + attack_info.attack_physical * self:getValue(conf, 2) + self:getAdd(conf, 2)
				end
			end

			local buff_list_defence = self:getBuffList(defence_pos)
			for k,v in ipairs(buff_list_defence) do
				local conf = CONF.BUFF.get(v)
				if self:checkKey(conf, 3) then
					defence_add = defence_add + defence_info.defence * self:getValue(conf, 3) + self:getAdd(conf, 3)
				end
			end


			if weapon_id_attack > 0 then
				local conf_weapon_attack = CONF.WEAPON.get(weapon_id_attack)
				if conf_weapon_attack.BUFF == 0 then
					local iCat = self:getCategory(conf_weapon_attack.ID)
					if conf_weapon_attack.TYPE == 1 and iCat == 1 or conf_weapon_attack.TYPE == 11 and iCat == 2 then
						attack_add = attack_add + attack_info.attack_physical * self:getValue(conf_weapon_attack, 2) + self:getAdd(conf_weapon_attack, 2)
						--print("attack_add", attack_add, self:getValue(conf_weapon_attack, 2), self:getAdd(conf_weapon_attack, 2))
					end
				end
			end

			local weapon_id_defence = defence_info.weapon_list[self:m(self.m_round, 3)]
			if weapon_id_defence > 0 then
				local conf_weapon_defence = CONF.WEAPON.get(weapon_id_defence)
				local iCat = self:getCategory(conf_weapon_defence.ID)
				if conf_weapon_defence.BUFF == 0 and conf_weapon_defence.TYPE == 1 and iCat == 2 then
					defence_add = defence_add + defence_info.defence * self:getValue(conf_weapon_defence, 3) + self:getAdd(conf_weapon_defence, 3)
					--print("defence_add", defence_add)
				end
			end

			local attack = defence_info.defence + defence_add - attack_info.attack_physical - attack_add

			local attack_values = {}
			local hurter_values = {}

			if buff_list_init[self:getPos(attack_pos)] then
				for k,v in ipairs(buff_list_init[self:getPos(attack_pos)]) do
					attack_values[5] = v
				end
			end

			if attack < 0 then
				hurter_values[1] = attack
			else
				hurter_values[1] = -1
			end
			if buff_list_init[self:getPos(defence_pos)] then
				for k,v in ipairs(buff_list_init[self:getPos(defence_pos)]) do
					hurter_values[5] = v
				end
			end
			defence_info.life = defence_info.life + hurter_values[1]
			if defence_info.life <= 0 then
				defence_info.life = 0
				for k,v in ipairs(self.m_fight_list) do
					if self:compare(defence_pos, v) then
						table.remove(self.m_fight_list, k)
						if k <= self.m_fight_index then
							self.m_fight_index = self.m_fight_index - 1
						end
						break
					end
				end
			end
			--attack_info.anger = attack_info.anger + 20
			defence_info.anger = defence_info.anger + 20
			if defence_info.anger > 100 then defence_info.anger = 100 end
			hurter_values[7] = 20
			local hurter_info = {}
			table.insert(hurter_info, defence_pos)
			table.insert(hurter_info, hurter_values)
			table.insert(hurter_list, hurter_info)
			--isWin = self:isWin()
		else
			--isWin = attack_pos[1]
		end
		--print("weapon_id_attack", weapon_id_attack)
		table.insert(attack_list, {attack_pos, attack_values})
		self:addEvent({2, attack_list, hurter_list, weapon_id_attack})
		isWin = self:isWin()

		if isWin == 0 then
			local attack_life_add = 0
			local attack_info = self:getShipInfo(attack_pos)
			local attack_buff_list = self:getBuffList(attack_pos)
			for k,v in ipairs(attack_buff_list) do
				local conf = CONF.BUFF.get(v)
				attack_life_add = attack_life_add + attack_info.life * self:getValue(conf, 2) + self:getAdd(conf, 2)
			end
			if attack_life_add ~= 0 then
				attack_info.life = attack_info.life + attack_life_add
				attack_info.anger = attack_info.anger + 20
				if attack_info.anger > 100 then attack_info.anger = 100 end
				if attack_info.life <= 0 then
					attack_info.life = 0
					for k,v in ipairs(self.m_fight_list) do
						if attack_pos[1] == v[1] and attack_pos[2] == v[2] and attack_pos[3] == v[3] then
							table.remove(self.m_fight_list, k)
							if k <= self.m_fight_index then
								self.m_fight_index = self.m_fight_index - 1
							end
							break
						end
					end
				end
				self:addEvent({2, nil, {{attack_pos, {attack_life_add,nil,nil,nil,nil,nil,20}}}})
			end
		end
		isWin = self:isWin()

		--[[if isWin == 0 then
			local defence_life_add = 0
			local defence_info = self:getShipInfo(defence_pos)
			local defence_buff_list = self:getBuffList(defence_pos, 1)
			for k,v in ipairs(defence_buff_list) do
				local conf = CONF.BUFF.get(v)
				defence_life_add = defence_life_add + defence_info.life * self:getValue(conf, 3) + self:getAdd(conf, 3)
			end
			if defence_life_add ~= 0 then
				defence_info.life = defence_info.life + defence_life_add
				if defence_info.life <= 0 then
					defence_info.life = 0
					for k,v in ipairs(self.m_fight_list) do
						if defence_pos[1] == v[1] and defence_pos[2] == v[2] and defence_pos[3] == v[3] then
							table.remove(self.m_fight_list, k)
							if k <= self.m_fight_index then
								self.m_fight_index = self.m_fight_index - 1
							end
							break
						end
					end
				end
				self:addEvent({2, {nil, defence_pos, {defence_life_add}}})
			end
		end
		isWin = self:isWin()--]]
	else
		isWin = self:isWin()
	end
	--print("iswin", isWin, "round", self.m_round)
	if isWin > 0 then
		self:addEvent({1, isWin})
	end
	if self.m_fight_index >= #self.m_fight_list then
		local event_buff = nil--self:removeBuff()
		if event_buff then
			self:addEvent({3, event_buff})
		end
	end
	self:setAttack(nil)
end

function FightPve:doSkill(iPos)
	local attack_pos = self:getPos(iPos)
	local attack_info = self:getShipInfo(attack_pos)
	if attack_info.anger < 100 or attack_info.skill == 0 then
		--return
	end
	local attack_list = {}
	local hurter_list = {}

	local defence_pos = self:getDefence(attack_pos)
	local conf = CONF.WEAPON.get(attack_info.skill)
	local iCategory = self:getCategory(attack_info.skill)
	if iCategory == 1 then
		local attack_add = attack_info.attack_physical * self:getValue(conf, 2) + self:getAdd(conf, 2)
		local attack_values = {}
		attack_values[2] = attack_add
		attack_values[7] = -attack_info.anger
		attack_info.anger = 0
		table.insert(attack_list, {attack_pos, attack_values})
		local target_list = self:getTargetList(attack_pos, defence_pos, conf.TYPE)
		for k,v in ipairs(target_list) do
			local defence_info = self:getShipInfo(v)
			local life_add = defence_info.defence - attack_info.attack_physical - attack_add
			local anger_add = 20
			if life_add >= 0 then
				life_add = -1
			end
			defence_info.life = defence_info.life + life_add
			defence_info.anger = defence_info.anger + anger_add
			if defence_info.anger > 100 then defence_info.anger = 100 end
			local hurter_values = {}
			hurter_values[1] = life_add
			hurter_values[7] = anger_add
			table.insert(hurter_list, {defence_pos, hurter_values})
		end
		self:removeShip()
		local isWin = self:isWin()
		if isWin > 0 then
			self:addEvent({1, isWin})
		end
		self:addEvent({2, attack_list, hurter_list, conf.ID})
		--print("SkillAttack", print_t(self.m_event_list))
	elseif iCategory == 2 then
		if conf.TYPE == 1 and conf.BUFF > 0 then
			local buff_conf = CONF.BUFF.get(conf.BUFF)
			local attack_values = {}
			attack_values[7] = -attack_info.anger
			attack_info.anger = 0
			table.insert(attack_list, {attack_pos, attack_values})
			local target_list = self:getTargetList(attack_pos, defence_pos, buff_conf.TYPE)
			for k,v in ipairs(target_list) do
				local target_info = self:getShipInfo(v)
				if self:checkKey(buff_conf, 3) then
					self.m_buff_list[self:getPos(v)][buff_conf.ID] = {buff_conf.ROUND,0}
					local hurter_values = {}
					hurter_values[3] = target_info.defence * self:getValue(conf, 3) + self:getAdd(conf, 3)
					hurter_values[5] = buff_conf.ID
					table.insert(hurter_list, {v, hurter_values})
				end
			end
			self:addEvent({2, attack_list, hurter_list, conf.ID})
			--print("SkillDefence", print_t(self.m_event_list))
		end
	elseif iCategory == 3 then
		local attack_values = {}
		attack_values[7] = -attack_info.anger
		attack_info.anger = 0
		table.insert(attack_list, {attack_pos, attack_values})
		local target_list = self:getTargetList(attack_pos, defence_pos, conf.TYPE)
		for k,v in ipairs(target_list) do
			local target_info = self:getShipInfo(v)
			if self:checkKey(conf, 1) then
				local life_add = target_info.life * self:getValue(conf, 1) + self:getAdd(conf, 1)
				local attack_values = {}
				attack_values[1] = life_add
				table.insert(attack_list, {v, attack_values})
			end
		end
		self:addEvent({2, attack_list, hurter_list, conf.ID})
		--print("SkillRecover", print_t(self.m_event_list))
	elseif iCategory == 4 then
		local attack_values = {}
		attack_values[7] = -attack_info.anger
		attack_info.anger = 0
		table.insert(attack_list, {attack_pos, attack_values})
		local target_list = self:getTargetList(attack_pos, defence_pos, conf.TYPE)
		for k,v in ipairs(target_list) do
			local hurter_values = {}
			local target_info = self:getShipInfo(v)
			local anger_add = 0
			if self:checkKey(conf, 7) then
				anger_add = target_info.anger * self:getValue(conf, 7) + self:getAdd(conf, 7)
				target_info.anger = target_info.anger + anger_add
			end

			local life_add = target_info.defence - attack_info.attack_physical
			if life_add >= 0 then
				life_add = -1
			end
			target_info.life = target_info.life + life_add
			target_info.anger = target_info.anger + anger_add
			local hurter_values = {}
			hurter_values[1] = life_add
			hurter_values[7] = anger_add
			table.insert(hurter_list, {v, hurter_values})
		end
		self:removeShip()
		local isWin = self:isWin()
		if isWin > 0 then
			self:addEvent({1, isWin})
		end
		self:addEvent({2, attack_list, hurter_list, conf.ID})
		--print("SkillControl", print_t(self.m_event_list))
	end
end

function FightPve:getAdd(conf, key)
	local add = 0
	for k,v in ipairs(conf.KEY) do
		if v == key then
			add = conf.ADD[k]
			break
		end
	end
	return add
end

function FightPve:getAttack()
	local attack
	if self.m_attack then
		attack = self.m_attack
		self.m_attack = nil
	else
		self.m_fight_index = self.m_fight_index < #self.m_fight_list and (self.m_fight_index + 1) or 1
		if self.m_fight_index == 1 then
			--print("Round Beg,"..self.m_round, "m_fight_index,"..self.m_fight_index, "fight_length,"..#self.m_fight_list)
			self.m_round = self.m_round + 1
			if self:isWin() == 0 then
				self:addEvent({4, self.m_round})
			end
		end
		attack = self.m_fight_list[self.m_fight_index]
	end
	return attack
end

function FightPve:getBuffConf(pos)
	local buff_conf
	local ship_info = self:getShipInfo(pos)
	local weapon_id = ship_info.weapon_list[self:m(self.m_round, 3)]
	if weapon_id and weapon_id > 0 then
		local buff_id = CONF.WEAPON.get(weapon_id).BUFF
		if buff_id > 0 then
			buff_conf = CONF.BUFF.get(buff_id)
		end
	end
	return buff_conf
end

function FightPve:getBuffList(pos, buff_category)
	local buff_list = {}
	for k,v in pairs(self.m_buff_list[self:getPos(pos)]) do
		--if self:getCategory(k) == buff_category then
			table.insert(buff_list, k)
		--end
	end
	return buff_list
end

function FightPve:getCategory(id)
	return tonumber(string.sub(tostring(id), 3, 4))
end

function FightPve:getDefence(attack_pos)
	local defence
	if self.m_defence then
		defence = self.m_defence
	else
		local attack = attack_pos
		local defence_i = self:m(attack[1]+1, 2)
		for j=1, 3 do
			for k=1, 3 do
				local defence_j = self.m_attack_rule[attack[2]][j]
				local defence_info = self:getShipInfo({defence_i, defence_j, k})
				if defence_info and defence_info.life > 0 then
					defence = {defence_i, defence_j, k}
					break
				end
			end
			if defence then
				break
			end
		end
	end
	return defence
end

function FightPve:getEvent()
	local event_info = nil
	if #self.m_event_list > 0 then
		event_info = self.m_event_list[1]
		table.remove(self.m_event_list, 1)
	end
	return event_info
end

function FightPve:getPos(pos)
	local isNumber = type(pos) == "number" or false
	local result
	if isNumber then
		result = self.m_pos[pos]
	else
		for k,v in ipairs(self.m_pos) do
			if self:compare(pos, v) then
				result = k
				break
			end
		end
	end
	return result
end

function FightPve:getShipInfo(t)
	return self:isEmpty(t) and nil or self.m_box[t[1]][t[2]][t[3]]
end

function FightPve:getTargetList(attack_pos, defence_pos, weapon_type)
	local target_list = {}
	if weapon_type == 1 then
		table.insert(target_list, attack_pos)
	elseif weapon_type == 2 then
		table.insert(target_list, attack_pos)
	elseif weapon_type == 3 then
		for k,v in self.m_fight_list do
			if v[1] == attack_pos[1] then
				table.insert(target_list, v)
			end
		end
	elseif weapon_type == 4 then
		local t = attack_pos
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == t[1] then
				if self:getShipInfo(v).life < self:getShipInfo(t).life then
					t = v
				end
			end
		end
		table.insert(target_list, t)
	elseif weapon_type == 5 then
		local t = attack_pos
		for k,v in self.m_fight_list do
			if v[1] == t[1] then
				if self:getShipInfo(v).defence > self:getShipInfo(t).defence then
					t = v
				end
			end
		end
		table.insert(target_list, t)
	elseif weapon_type == 8 then
		local t = attack_pos
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == t[1] and v[2] == t[2] then
				table.insert(target_list, v)
			end
		end
		table.insert(target_list, t)
	elseif weapon_type == 9 then
		local t = attack_pos
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == t[1] and v[3] == t[3] then
				table.insert(target_list, v)
			end
		end
		table.insert(target_list, t)
	elseif weapon_type == 11 then
		table.insert(target_list, defence_pos)
	elseif weapon_type == 12 then
		table.insert(target_list, defence_pos)
	elseif weapon_type == 13 then
		for k,v in self.m_fight_list do
			if v[1] == defence_pos[1] then
				table.insert(defence_pos, v)
			end
		end
	elseif weapon_type == 14 then
		local t = defence_pos
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == t[1] then
				if self:getShipInfo(v).life < self:getShipInfo(t).life then
					t = v
				end
			end
		end
		table.insert(target_list, t)
	elseif weapon_type == 16 then
		local t = defence_pos
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == t[1] then
				if self:getShipInfo(v).defence < self:getShipInfo(t).defence then
					t = v
				end
			end
		end
		table.insert(target_list, t)
	elseif weapon_type == 18 then
		local t = defence_pos
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == t[1] and v[2] == t[2] then
				table.insert(target_list, v)
			end
		end
	elseif weapon_type == 19 then
		local t = attack_pos
		for k,v in ipairs(self.m_fight_list) do
			if v[1] ~= t[1] and v[3] == t[3] then
				table.insert(target_list, v)
			end
		end
	end
	return target_list
end

function FightPve:getValue(conf, key)
	local val = 0
	for k,v in ipairs(conf.KEY) do
		if v == key then
			val = conf.VALUE[k]
			break
		end
	end
	return val
end

function FightPve:init(ship_list, npc_list)
	local box = self.m_box
	for k,v in ipairs(ship_list) do
		local pos = self:getPos(v.position)
		self.m_speed_list[v.position] = {v.speed,0,0}
		box[1][pos[2]][pos[3]] = v
	end

	for k,v in ipairs(npc_list) do
		local pos = self:getPos(v.position+9)
		self.m_speed_list[v.position+9] = {v.speed,0,0}
		box[2][pos[2]][pos[3]] = v
	end

	for i=1, 2 do
		for j=1, 3 do
			for k=1, 3 do
				if box[i][j][k] then
					table.insert(self.m_fight_list, {i,j,k})
				end
			end
		end
	end
	--print(print_t(self.m_fight_list))
	self:sortBySpeed()
	--print(print_t(self.m_fight_list))
end

function FightPve:isEmpty(t)
	return t and next(t)
end

function FightPve:isWin()
	local life = {0,0}
	for k,v in ipairs(self.m_fight_list) do
		life[v[1]] = life[v[1]] + self:getShipInfo(v).life
	end
	local isWin
	if math.floor(life[2]) == 0 then
		isWin = 1
	else
		if math.floor(life[1]) == 0 then
			isWin = 2
		else
			if self.m_round > 5 then
				isWin = 2
			else
				isWin = 0
			end
		end
	end
	return isWin
end

function FightPve:m(a, n)
	local m = a % n
	return m > 0 and m or n
end

function FightPve:new()
	self.m_box =
	{
		{
			{nil,nil,nil},
			{nil,nil,nil},
			{nil,nil,nil},
		},
		{
			{nil,nil,nil},
			{nil,nil,nil},
			{nil,nil,nil},
		}
	}
	self.m_pos =
	{
		{1,1,1},{1,1,2},{1,1,3},
		{1,2,1},{1,2,2},{1,2,3},
		{1,3,1},{1,3,2},{1,3,3},
		{2,1,1},{2,1,2},{2,1,3},
		{2,2,1},{2,2,2},{2,2,3},
		{2,3,1},{2,3,2},{2,3,3},
	}
	self.m_attack_rule =
	{
		{1,2,3},
		{2,1,3},
		{3,2,1},
	}

	self.m_round = 0
	self.m_fight_index = 0
	self.m_fight_list = {}
	self.m_speed_list = {}
	self.m_attack = nil
	self.m_defence = nil

	self.m_event_list =  {}
	self.m_buff_list =   {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
	self.m_weapon_list = {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
	self.m_power_list  = {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
end

function FightPve:removeBuff()
	local event_list
	for k,v in pairs(self.m_buff_list) do
		for kk,vv in pairs(v) do
			if vv[1] > 0 then
				vv[1] = vv[1] - 1
			end
			if vv[1] == 0 then
				if self:getShipInfo(self:getPos(k)).life > 0 then
					local t = {}
					t[5] = -kk
					event_list = {{self:getPos(k), t}}
					--print(self.m_round, print_t(event_list))
				end
				v[kk] = nil
			end
		end
	end
	return event_list
end

function FightPve:removeShip()
	local fight_list = self.m_fight_list
	for i = #fight_list, 1, -1 do
		local ship_info = self:getShipInfo(fight_list[i])
		if ship_info.life == 0 then
			table.remove(fight_list, i)
			if i <= self.m_fight_index then
				self.m_fight_index = self.m_fight_index - 1
			end
		end
	end
end

function FightPve:setAttack(pos)
	self.m_attack = pos
end

function FightPve:setDefence(pos)
	--if not pos then

end

function FightPve:sortBySpeed()
	local f = function (a, b)
		local aPos = self:getPos(a)
		local bPos = self:getPos(b)
		local aSpeed = self.m_speed_list[aPos][1]
		local bSpeed = self.m_speed_list[bPos][1]
		if self.m_speed_list[aPos][2] > 0 then
			aSpeed = aSpeed + self.m_speed_list[aPos][3]
		end
		if self.m_speed_list[bPos][2] > 0 then
			bSpeed = bSpeed + self.m_speed_list[bPos][3]
		end
		local isCheck
		if aSpeed == bSpeed then
			if (aPos > 9 and aPos-9 or aPos) == (bPos > 9 and bPos-9 or bPos) then
				isCheck = a[1] < b[1]
			else
				isCheck = (aPos > 9 and aPos-9 or aPos) < (bPos > 9 and bPos-9 or bPos)
			end
		else
			isCheck = aSpeed > bSpeed
		end
		return isCheck
	end
	table.sort(self.m_fight_list, f)
	for k,v in pairs(self.m_speed_list) do
		if v[2] > 0 then
			v[2] = v[2] - 1
			if v[2] == 0 and v[3] > 0 then
				v[3] = 0
			end
		end
	end
end

return FightPve
