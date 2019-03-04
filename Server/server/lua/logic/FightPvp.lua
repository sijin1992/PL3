local FightPvp = {}
FightPvp.__index = FightPvp

function FightPvp:addAnger(target_pos)
	--local weapon_info = self:
	--local anger
end

function FightPvp:addBuff(attack_pos, defence_pos)
	local buff_list = {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
	local buff_conf = self:getConfBuff(attack_pos)
	if buff_conf then
		local target_list = self:getTargetList(attack_pos, defence_pos, buff_conf.TYPE)
		for k,v in ipairs(target_list) do
			local iPos = self:getPos(v)
			self.m_buff_list[iPos][buff_conf.ID] = {buff_conf.ROUND,buff_conf.COUNT}
			table.insert(buff_list[iPos], buff_conf.ID)
		end
	end
	return buff_list
end

function FightPvp:addEventAttack(attack_list, defence_list, weapon_id)
	local event_attack_list = {}
	local event_hurter_list = {}
	for k,v in ipairs(attack_list) do
		table.insert(event_attack_list, {pos=v[1], values=v[2]})
	end
	for k,v in ipairs(defence_list) do
		table.insert(event_hurter_list, {pos=v[1], values=v[2]})
	end
	local event_info = {}
	event_info.id = 2
	event_info.value = weapon_id
	if not self:isEmpty(event_attack_list) then
		event_info.attack_list = event_attack_list
	end
	if not self:isEmpty(event_hurter_list) then
		event_info.hurter_list = event_hurter_list
	end
	table.insert(self.m_event_list, event_info)
end

function FightPvp:addEventRemoveBuff(buff_list_event)
	local hurter_list = {}
	for k,v in ipairs(buff_list_event) do
		table.insert(hurter_list, {pos=v[1], values=v[2]})
	end
	table.insert(self.m_event_list, {id=3, value=0, hurter_list=hurter_list})
end

function FightPvp:addEventRound(round)
	table.insert(self.m_event_list, {id=4, value=round})
end

function FightPvp:addEventWin(isWin)
	table.insert(self.m_event_list, {id=1, value=isWin})
end

function FightPvp:checkKey(conf, key)
	local is = false
	for k,v in ipairs(conf.KEY) do
		if v == key then
			is = true
			break
		end
	end
	return is
end

function FightPvp:compare(t1, t2)
	return t1[1] == t2[1] and t1[2] == t2[2] and t1[3] == t2[3]
end

function FightPvp:doFight()
	local attack_pos = self:getAttack()
	local attack_info = self:getShipInfo(attack_pos)
	local attack_gift = self:getConfGift(attack_info.gift)
	local isWin = 0
	local attack_list = {}
	local defence_list = {}
	local weapon_info = self:getWeaponConf(attack_pos)
	local defence_pos = self:getDefence(attack_pos)
	if weapon_info and defence_pos then
		local buff_list_add = self:addBuff(attack_pos, defence_pos)
		for k,v in ipairs(buff_list_add) do
			for kk,vv in ipairs(v) do
				local pos = self:getPos(k)
				if pos[1] == attack_pos[1] then
					self:setHurterValue(attack_list, pos, 5, vv)
				else
					self:setHurterValue(defence_list, pos, 5, vv)
				end
				break
			end
		end
		local defence_info = self:getShipInfo(defence_pos)
		local defence_gift = self:getConfGift(defence_info.gift)
		local vals = {self:getValuesAttack(attack_pos), self:getValuesDefence(defence_pos)}
		local hurt = attack_info.attack_physical + vals[1][2] - defence_info.defence - vals[2][3]
		--天赋技能2,免疫第一回合攻击伤害
		if defence_gift and defence_gift.EFFECT == 2 and defence_gift.ROUND >= self.m_round then
			hurt = 0
		end

		if hurt < 0 then
			hurt = 1
		end
		if hurt > defence_info.life then
			hurt = defence_info.life
		end
		local defence_anger = 20
		if defence_anger  > 100 - defence_info.anger then
			defence_anger = 100 - defence_info.anger
		end

		local attack_event
		for k,v in ipairs(attack_list) do
			if self:compare(v[1], attack_pos) then
				attack_event = v
				break
			end
		end
		if not attack_event then
			attack_event = {attack_pos, {}}
			table.insert(attack_list, attack_event)
		end

		defence_info.life = defence_info.life - hurt
		defence_info.anger = defence_info.anger + defence_anger
		self:setHurterValue(defence_list, defence_pos, 1, -hurt)
		self:setHurterValue(defence_list, defence_pos, 7, defence_anger)

		if defence_info.life == 0 then
			--天赋5,亡语
			if defence_gift and defence_gift.EFFECT == 5 then
				local target_list = self:getTargetList(defence_info, nil, defence_gift.TYPE)
				local target_pos = target_list[1]
				if target_pos then
					local life_add = 0
					local target_info = self:getShipInfo(target_pos)
					if self:checkKey(defence_gift, 1) then
						life_add = target_info.life * self:getValue(defence_gift, 1) + self:getAdd(defence_gift, 1)
					end
					if life_add > 0 then
						self:setHurterValue(defence_list, target_pos, 1, life_add)
						target_info.life = target_info.life + life_add
					end
				end
			end

			self:removeShip()
		end

		--天赋3,激怒受击,自身受击,自己增加攻击力
		if defence_gift and defence_gift.EFFECT == 3 then
			local attack_add = 0
			if self:checkKey(defence_gift, 2) then
				attack_add = defence_info.attack_physical * self:getValue(defence_gift, 2) + self:getAdd(defence_gift, 2)
			end
			if attack_add > 0 then
				defence_event[2][2] = attack_add
				defence_info.attack_physical = defence_info.attack_physical + attack_add
			end
		end

		--天赋4,激怒受击,己方受击,自己增加攻击力
		for k,v in ipairs(self:getFightList(defence_pos[1])) do
			local attack_add = 0
			local t = self:getShipInfo(v)
			local conf_gift = self:getConfGift(t.gift)
			if conf_gift and conf_gift.EFFECT == 4 then
				if self:checkKey(conf_gift, 2) then
					attack_add = t.attack_physical * self:getValue(conf_gift, 2) + self:getAdd(conf_gift, 2)
				end
			end
			if attack_add > 0 then
				self:setHurterValue(defence_list, v, 2, attack_add)
				t.attack_physical = t.attack_physical + attack_add
				break
			end
		end

		--天赋技能8,己方随机增加生命
		if attack_gift and attack_gift.EFFECT == 8 then
			local life_add = 0
			if self:checkKey(attack_gift, 1) then
				life_add = attack_info.life * self:getValue(attack_gift, 1) + self:getAdd(attack_gift, 1)
			end
			if life_add > 0 then
				local target_list = self:getTargetList(attack_pos, nil, 2)
				local target_pos = target_list[1]
				if target_pos then
					self:setHurterValue(defence_list, target_pos, 1, life_add)
					local target_info = self:getShipInfo(target_pos)
					target_info.life = target_info.life + life_add
				end
			end
		end

		self:addEventAttack(attack_list, defence_list, weapon_info.ID)
		isWin = self:isWin()
	end

	--print("iswin", isWin, "round", self.m_round)
	self:onFightEnd()
	self:onRoundEnd()
	return isWin
end

function FightPvp:doSkill(iPos)
	local attack_pos = self:getPos(iPos)
	local attack_info = self:getShipInfo(attack_pos)
	local attack_list = {}
	local hurter_list = {}

	local conf = CONF.WEAPON.get(attack_info.skill)
	--天赋技能1,必杀技所需怒气可定义
	local anger_max = conf.ANGER_MAX
	if attack_info.anger < anger_max or attack_info.skill == 0 then
		--return
	end
	local defence_pos = self:getDefence(attack_pos)
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
		print("SkillAttack", print_t(self.m_event_list))
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
			print("SkillDefence", print_t(self.m_event_list))
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
		print("SkillRecover", print_t(self.m_event_list))
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
		print("SkillControl", print_t(self.m_event_list))
	end
	--天赋技能7,己方使用大技能,自己增加攻击力
	for k,v in ipairs(self:getFightList(attack_pos[1])) do
		local attack_add = 0
		local t = self:getShipInfo(v)
		local conf_gift = self:getConfGift(t.gift)
		if conf_gift and conf_gift.EFFECT == 7 then
			if self:checkKey(conf_gift, 2) then
				attack_add = t.attack_physical * self:getValue(conf_gift, 2) + self:getAdd(conf_gift, 2)
			end
		end
		if attack_add > 0 then
			self:setHurterValue(hurter_list, v, 2, attack_add)
			t.attack_physical = t.attack_physical + attack_add
			break
		end
	end

	self:addEventAttack(attack_list, hurter_list, conf.ID)
	return self:isWin()
end

function FightPvp:getAdd(conf, key)
	local add = 0
	for k,v in ipairs(conf.KEY) do
		if v == key then
			add = conf.ADD[k]
			break
		end
	end
	return add
end

function FightPvp:getAttack()
	local attack
	if self.m_attack then
		attack = self.m_attack
		self.m_attack = nil
	else
		self.m_fight_index = self.m_fight_index < #self.m_fight_list and (self.m_fight_index + 1) or 1
		if self.m_fight_index == 1 then
			self:sort()
			self.m_round = self.m_round + 1
			if self:isWin() == 0 then
				self:addEventRound(self.m_round)
			end
		end
		attack = self.m_fight_list[self.m_fight_index]
	end
	return attack
end

function FightPvp:getBuffList(pos, buff_category)
	local buff_list = {}
	for k,v in pairs(self.m_buff_list[self:getPos(pos)]) do
		--if self:getCategory(k) == buff_category then
			table.insert(buff_list, k)
		--end
	end
	return buff_list
end

function FightPvp:getCategory(id)
	return tonumber(string.sub(tostring(id), 3, 4))
end

function FightPvp:getConfBuff(pos)
	local buff_conf
	local ship_info = self:getShipInfo(pos)
	local weapon_id = ship_info.weapon_list[self:m(self.m_round, 3)]
	if weapon_id and weapon_id > 0 then
		local buff_id = CONF.WEAPON.get(weapon_id).BUFF
		if buff_id > 0 then
			buff_conf = CONF.BUFF.get(buff_id)
			if buff_conf.STATUS == 0 then
				buff_conf = nil
			end
		end
	end
	return buff_conf
end

function FightPvp:getConfGift(gift_id)
	local gift_conf
	if gift_id > 0 then
		gift_conf = CONF.GIFT.get(gift_id)
		if gift_conf.STATUS == 0 then
			gift_conf = nil
		end
	end
	return gift_conf
end

function FightPvp:getDefence(attack_pos)
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

function FightPvp:getEvent()
	local event_info
	if #self.m_event_list > self.m_event_index then
		self.m_event_index = self.m_event_index + 1
		event_info = self.m_event_list[self.m_event_index]
	end
	return event_info
end

function FightPvp:getFightList(i)
	local t = {}
	if i > 0 then
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == i then
				table.insert(t, v)
			end
		end
	else
		for k,v in ipairs(self.m_fight_list) do
			table.insert(t, v)
		end
	end
	return t
end

function FightPvp:getFightRandom(pos)
	local fight_list = {}
	for k,v in ipairs(self.m_fight_list) do
		if not self:compare(v, pos) and v[1] == pos[1] then
			table.insert(fight_list, v)
		end
	end
	return #fight_list > 0 and fight_list[math.random(#fight_list)] or pos
end

function FightPvp:getPos(pos)
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

function FightPvp:getShipInfo(t)
	return self:isEmpty(t) and nil or self.m_box[t[1]][t[2]][t[3]]
end

function FightPvp:getTargetList(attack_pos, defence_pos, weapon_type)
	local target_list = {}
	if weapon_type == 1 then
		table.insert(target_list, attack_pos)
	elseif weapon_type == 2 then
		table.insert(target_list, self:getFightRandom(attack_pos))
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
		table.insert(target_list, self:getFightRandom(defence_pos))
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

function FightPvp:getTargetValues(target_pos, conf)
	local target_info = self:getShipInfo(target_pos)
	local values = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	if conf then
		for k,v in ipairs(conf.KEY) do
			local val = 0
			if v == 1 then
				val = target_info.life
			elseif v == 2 then
				val = target_info.attack_physical
			elseif v == 3 then
				 val = target_info.defence
			elseif v == 4 then
				val = target_info.speed
			elseif v == 7 then
				val = target_info.anger
			end
			if val > 0 then
				local add = val * conf.VALUE[k] + conf.ADD[k]
				if add > 0 then
					values[v] = math.ceil(val * conf.VALUE[k] + conf.ADD[k])
				else
					values[v] = math.floor(val * conf.VALUE[k] + conf.ADD[k])
				end
			end
		end
	end
	return values
end

function FightPvp:getValue(conf, key)
	local val = 0
	for k,v in ipairs(conf.KEY) do
		if v == key then
			val = conf.VALUE[k]
			break
		end
	end
	return val
end

function FightPvp:getValuesAttack(attack_pos)
	local attack_info = self:getShipInfo(attack_pos)
	local weapon_conf = self:getWeaponConf(attack_pos)
	local attack_values = self:getTargetValues(attack_pos, weapon_conf)
	for k,v in pairs(self.m_buff_list[self:getPos(attack_pos)]) do
		local conf_buff = CONF.BUFF.get(k)
		if conf_buff.EFFECT == 1 then
			local values = self:getTargetValues(attack_pos, conf_buff)
			for kk,vv in ipairs(values) do
				attack_values[kk] = attack_values[kk] + vv
			end
		end
	end
	--天赋技能9,祝福,加攻击
	local attack_add = 0
	local speed_add = 0
	for k,v in ipairs(self:getFightList(attack_pos[1])) do
		if attack_info.gift > 0 then
			local conf_gift = CONF.GIFT.get(attack_info.gift)
			if conf_gift.EFFECT == 9 then
				if self:checkKey(conf_gift, 2) then
					attack_add = attack_add + attack_info.attack_physical * self:getValue(conf_gift, 2) + self:getAdd(conf_gift, 2)
				end
			end
			if conf_gift.EFFECT == 10 then
				if self:checkKey(conf_gift, 4) then
					speed_add = speed_add + attack_info.speed * self:getValue(conf_gift, 4) + self:getAdd(conf_gift, 4)
				end
			end
		end
	end
	if attack_add > 0 then
		attack_values[2] = attack_values[2] + attack_add
	end

	if speed_add > 4 then
		attack_values[4] = attack_values[4] + speed_add
	end
	return attack_values
end

function FightPvp:getValuesDefence(defence_pos)
	local defence_info = self:getShipInfo(defence_pos)
	local defence_values = self:getTargetValues(defence_pos, nil)
	for k,v in pairs(self.m_buff_list[self:getPos(defence_pos)]) do
		local conf_buff = CONF.BUFF.get(k)
		if conf_buff.EFFECT == 1 then
			local values = self:getTargetValues(defence_pos, conf_buff)
			for kk,vv in ipairs(values) do
				defence_values[kk] = defence_values[kk] + vv
			end
		end
	end
	return defence_values
end

function FightPvp:getWeaponConf(attack_pos)
	local ship_info = self:getShipInfo(attack_pos)
	local weapon_id = ship_info.weapon_list[self:m(self.m_round, #ship_info.weapon_list)]
	return weapon_id > 0 and CONF.WEAPON.get(weapon_id) or nil
end

function FightPvp:init(ship_list, npc_list)
	local box = self.m_box
	for k,v in ipairs(ship_list) do
		local pos = self:getPos(v.position)
		box[1][pos[2]][pos[3]] = v
	end

	for k,v in ipairs(npc_list) do
		local pos = self:getPos(v.position+9)
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
	--self:sort()
	--print(print_t(self.m_fight_list))
end

function FightPvp:isEmpty(t)
	return t == nil or next(t) == nil
end

function FightPvp:isWin()
	local life = {0,0}
	for k,v in ipairs(self.m_fight_list) do
		life[v[1]] = life[v[1]] + self:getShipInfo(v).life
	end
	local isWin
	if life[2] == 0 then
		isWin = 1
	else
		if life[1] == 0 then
			isWin = 2
		else
			if self.m_round > 5 then
				isWin = 2
			else
				isWin = 0
			end
		end
	end
	if isWin > 0 then
		self:addEventWin(isWin)
	end
	return isWin
end

function FightPvp:m(a, n)
	local m = a % n
	return m > 0 and m or n
end

function FightPvp:new()
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
	self.m_attack = nil
	self.m_defence = nil

	self.m_event_index = 0
	self.m_event_list =  {}
	self.m_buff_list =   {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
	self.m_weapon_list = {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
	self.m_power_list  = {{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{},{}}
end

function FightPvp:onFightBegin()
	self:sort()
end

function FightPvp:onFightEnd()
	--中毒
	for k,v in ipairs(self.m_buff_list) do
		for kk,vv in pairs(v) do
			local buff_conf = CONF.BUFF.get(kk)
			if buff_conf.EFFECT == 2 then
				local pos = self:getPos(k)
				local values = self:getTargetValues(pos, buff_conf)
				local vals = self:setTargetValues(pos, values)
				self:addEventAttack({}, {{pos, vals},}, kk)
			end
		end
	end
	self:removeBuff(2)
end

function FightPvp:onRoundEnd()
	if self.m_fight_index < #self.m_fight_list then
		return
	end
	--灼烧
	for k,v in ipairs(self.m_buff_list) do
		for kk,vv in pairs(v) do
			local buff_conf = CONF.BUFF.get(kk)
			if buff_conf.EFFECT == 1 then
				local pos = self:getPos(k)
				local values = self:getTargetValues(pos, buff_conf)
				local vals = self:setTargetValues(pos, values)
				self:addEventAttack({}, {{pos, vals},}, kk)
			end
		end
	end
	self:removeBuff(1)
end

function FightPvp:removeBuff(iEffect)
	local buff_list_event = {}
	for k,v in ipairs(self.m_buff_list) do
		for kk,vv in pairs(v) do
			if iEffect == 2 then
				if vv[2] > 0 then
					vv[2] = vv[2] - 1
					if vv[2] == 0 then
						self:setHurterValue(buff_list_event, self:getPos(k), 5, -kk)
						v[kk] = nil
					end
				end
			else
				if vv[1] > 0 then
					vv[1] = vv[1] - 1
					if vv[1] == 0 then
						self:setHurterValue(buff_list_event, self:getPos(k), 5, -kk)
						v[kk] = nil
					end
				end
			end
		end
	end
	if not self:isEmpty(buff_list_event) then
		self:addEventRemoveBuff(buff_list_event)
	end
	return buff_list_event
end

function FightPvp:removeShip()
	local fight_list = self.m_fight_list
	for i = #fight_list, 1, -1 do
		local ship_info = self:getShipInfo(fight_list[i])
		if ship_info.life == 0 then
			self.m_buff_list[self:getPos(fight_list[i])] = {}
			if i <= self.m_fight_index then
				self.m_fight_index = self.m_fight_index - 1
			end
			table.remove(fight_list, i)
		end
	end
end

function FightPvp:setAttack(pos)
	self.m_attack = pos
end

function FightPvp:setDefence(pos)
	--if not pos then
end

function FightPvp:setHurterValue(hurter_list, pos, key, value)
	local none = true
	for k,v in ipairs(hurter_list) do
		if self:compare(v[1], pos) then
			v[2][key] = v[2][key] and v[2][key] + value or value
			none = false
			break
		end
	end
	if none then
		local t = {0,0,0,0,0,0,0,0,0}
		t[key] = value
		table.insert(hurter_list, {pos,t})
	end
end

function FightPvp:setTargetValues(target_pos, values)
	local target_info = self:getShipInfo(target_pos)
	local vals = {0,0,0,0,0,0,0,0,0,}
	for k,v in pairs(values) do
		if v ~= 0 then
			local add = 0
			if k == 1 then
				if target_info.life < -v then
					add = -target_info.life
				else
					add = v
				end
				vals[k] = add
				target_info.life = target_info.life + add
				if target_info.life == 0 then
					self:removeShip()
				end
			elseif k == 2 then
				if target_info.attack_physical < -v then
					add = -target_info.attack_physical
				else
					add = v
				end
				vals[k] = add
				target_info.attack_physical = target_info.attack_physical + add
			elseif k == 3 then
				if target_info.defence < -v then
					add = -target_info.defence
				else
					add = v
				end
				vals[k] = add
				target_info.defence = target_info.defence + add
			elseif k == 4 then
				if target_info.speed < -v then
					add = -target_info.speed
				else
					add = v
				end
				vals[k] = add
				target_info.speed = target_info.speed + add
			elseif k == 7 then
				if target_info.anger < -v then
					add = -target_info.anger
				else
					if target_info.anger > 100 - v then
						add = 100 - target_info.anger
					else
						add = v
					end
				end
				vals[k] = add
				target_info.anger = target_info.anger + add
			end
		end
	end
	return vals
end

--攻击顺序,1,Speed Desc,2,Pos,Asc,3,Attack,Asc
function FightPvp:sort()
	local f = function (a, b)
		local aPos = self:getPos(a)
		local bPos = self:getPos(b)
		local ship_info_a = self:getShipInfo(a)
		local ship_info_b = self:getShipInfo(b)
		local aSpeed = ship_info_a.speed
		local bSpeed = ship_info_b.speed
		aPos = aPos > 9 and aPos - 9 or aPos
		bPos = bPos > 9 and bPos - 9 or bPos
		local isCheck
		if aSpeed == bSpeed then
			if aPos == bPos then
				isCheck = a[1] < b[1]
			else
				isCheck = aPos < bPos
			end
		else
			isCheck = aSpeed > bSpeed
		end
		return isCheck
	end
	table.sort(self.m_fight_list, f)
end

return FightPvp
