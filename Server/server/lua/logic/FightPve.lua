local FightPve = {}

function FightPve:addAnger(pos, anger)
	local add = 0
	local idx = 0
	local anger_list = self.m_anger_list
	for i=1, 2 do
		if i == pos[1] then
			add = self:addValue(anger_list[i], anger, 0, 150)
			if add ~= 0 then
				idx = i
			end
			break
		end
	end
	if add ~= 0 then
		anger_list[idx] = anger_list[idx] + add
	end
	return add
end

function FightPve:addBuffer(attack_pos, defence_pos, attack_list, defence_list, skill)
	local weapon_info
	if skill and skill > 0 then
		weapon_info = self:getConfWeapon(skill)
	else
		weapon_info = self:getWeaponInfo(attack_pos)
	end
	if weapon_info then
		for i=1, 2 do
			local buff_id = weapon_info[self:concat("BUFF",i)]
			local buff_conf = self:getConfBuff(buff_id)
			if buff_conf then
				local buffer_id = buff_id * 10 + i
				local target_list = self:getTargetList(attack_pos, defence_pos, weapon_info[self:concat("TYPE",i)])
				for k, pos in ipairs(target_list) do
					local iPos = self:getPos(pos)
					--BuffEffect07,免疫Debuff
					local isNone = true
					for buffer_id, buff_info in pairs(self:getBuffList(pos)) do
						if buff_info.effect == 7 then
							isNone = false
							break
						end
					end
					if buff_conf.DEBUFF == 0 or buff_conf.DEBUFF > 0 and isNone then
						local buff_info = self.m_buffer_list[iPos][buffer_id]
						if buff_info then
							if buff_info.overlap > 0 then
								buff_info.count = buff_info.count + weapon_info[self:concat("COUNT",i)] or 0
								buff_info.round = buff_info.round + weapon_info[self:concat("ROUND",i)] or 0
							end
						else
							buff_info = {}
							buff_info.weapon_id = weapon_info["ID"]
							buff_info.count = weapon_info[self:concat("COUNT",i)] or 0
							buff_info.round = weapon_info[self:concat("ROUND",i)] or 0
							buff_info.value = weapon_info[self:concat("VALUE",i)] or {}
							buff_info.add = weapon_info[self:concat("ADD",i)] or {}
							buff_info.p = weapon_info[self:concat("P",i)] or {}
							buff_info.type = weapon_info[self:concat("TYPE",i)] or 0
							buff_info.state = weapon_info[self:concat("STATE",i)] or 0
							buff_info.buff_id = buff_id
							buff_info.key = buff_conf.KEY or {}
							buff_info.overlap = buff_conf.OVERLAP or 0
							buff_info.debuff = buff_conf.DEBUFF or 0
							buff_info.effect = buff_conf.EFFECT or 0
						end
						self.m_buffer_list[iPos][buffer_id] = buff_info
						--if pos[1] == attack_pos[1] then
						--	self:setHurterValue(attack_list, pos, 5, buff_id)
						--else
							self:setHurterValue(defence_list, pos, 5, buff_id)
						--end
					end
					--Tools.print_t(buff_info)
				end
			end
		end
	end
end

function FightPve:addEventAnger(pos, value)
	local hurter_list = {}
	self:setHurterValue(hurter_list, pos, 7, value)
	for k,v in ipairs(hurter_list) do
		local event_info = {}
		event_info.id = 2
		event_info.value = 0
		event_info.hurter_list = {{pos=v[1], values=v[2]}}
		table.insert(self.m_event_list, event_info)
	end
end

function FightPve:addEventAttack(attack_list, defence_list, weapon_id)
	local event_attack_list = {}
	local event_hurter_list = {}
	for k,v in ipairs(attack_list) do
		table.insert(event_attack_list, {pos=v[1], values=v[2], buffs=v[3]})
	end
	for k,v in ipairs(defence_list) do
		table.insert(event_hurter_list, {pos=v[1], values=v[2], buffs=v[3]})
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

function FightPve:addEventRemoveBuff(buff_list_event)
	local hurter_list = {}
	for k,v in ipairs(buff_list_event) do
		table.insert(hurter_list, {pos=v[1], buffs=v[3]})
	end
	local event_info = {id=3, value=0, hurter_list=hurter_list}
	table.insert(self.m_event_list, event_info)
end

function FightPve:addEventRound(round)
	local event_attack_list = {}
	local fight_list = self.m_fight_list
	for k,v in ipairs(fight_list) do
		local ship_info = self:getShipInfo(v)
		table.insert(event_attack_list, {pos=v, values={0,0,0,ship_info.speed}})
	end
	local event_info = {
		id = 4,
		value = round,
		attack_list = event_attack_list,
	}
	table.insert(self.m_event_list, event_info)
end

function FightPve:addEventWin(isWin)
	table.insert(self.m_event_list, {id=1, value=isWin})
end

function FightPve:addValue(value, add, min, max)
	min = min or 0
	max = max or 99999999
	local val
	if add > 0 then
		if value + add > max then
			val = max - value
		else
			val = add
		end
	else
		if value + add < min then
			val = min - value
		else
			val = add
		end
	end
	return val
end

function FightPve:checkKey(conf, key)
	local is = false
	for k,v in ipairs(conf.KEY) do
		if v == key then
			is = true
			break
		end
	end
	return is
end

function FightPve:checkP(value)
	local min = 1
	local max = 100
	local len = math.floor(value * 100)
	if len > max then
		len = max
	end
	local t = {}
	for i=min, len do
		t[i] = 1
	end
	for i=len+1, max do
		t[i] = 0
	end
	local val = math.random(min, max)
	return t[val] > 0
end

function FightPve:clone(t)
	local dst = {}
	for k,v in pairs(t) do
		if type(v) == "table" then
			dst[k] = clone(v)
		else
			dst[k] = v
		end
	end
	return dst
end

function FightPve:compare(t1, t2)
	return t1[1] == t2[1] and t1[2] == t2[2] and t1[3] == t2[3]
end

function FightPve:concat(...)
	local t = {}
	for k,v in ipairs{...} do
		t[#t+1] = v
	end
	return table.concat(t)
end

function FightPve:doFight()
	local attack_pos = self:getAttack()
	local attack_info = self:getShipInfo(attack_pos)
	local attack_gift = self:getConfGift(attack_info.gift)
	local isWin = 0
	local attack_list = {}
	local defence_list = {}
	local weapon_info = self:getWeaponInfo(attack_pos)
	local defence_pos = self:getDefence(attack_pos)
	--BuffEffect12
	local isActive_attack = true
	for buffer_id_attack, buff_info_attack in pairs(self:getBuffList(attack_pos)) do
		if buff_info_attack.effect == 12 then
			isActive_attack = false
			break
		end
	end
	if defence_pos and isActive_attack then
		self:addBuffer(attack_pos, defence_pos, attack_list, defence_list)
		local defence_info = self:getShipInfo(defence_pos)
		local defence_gift = self:getConfGift(defence_info.gift)
		local hurt = self:getHurt(attack_pos, defence_pos, self:getValuesAttack(attack_pos), self:getValuesDefence(defence_pos))
		--天赋技能2,免疫第一回合攻击伤害
		if defence_gift and defence_gift.EFFECT == 2 and defence_gift.ROUND >= self.m_round then
			hurt = 0
		end

		self:setHurt(defence_pos, hurt)
		self:setHurterValue(attack_list, attack_pos, 0, 0)
		self:setHurterValue(defence_list, defence_pos, 1, -hurt)

		self:setHurterValue(attack_list, attack_pos, 7, self:addAnger(attack_pos, 20))
		self:setHurterValue(defence_list, defence_pos, 7, self:addAnger(defence_pos, 20))

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
			--BuffEffect09,复活
			for k,v in pairs(self:getBuffList(defence_pos)) do
				local buffer_id = k
				local buff_info = v
				if buff_info.effect == 9 then
					local vals = self:getTargetValues(defence_pos, self:getBufferIndex(buffer_id), nil)
					self:setTargetValues(attack_pos, vals)
					self:setHurterValues(attack_list, defence_pos, {})
					self:setHurterValues(defence_list, attack_pos, vals)
					self:addEventAttack(attack_list, defence_list, buff_info.weapon_id)
					break
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

		self:addEventAttack(attack_list, defence_list, weapon_info and weapon_info.ID or 0)

		for buffer_id, buff_info in pairs(self:getBuffList(attack_pos)) do
			--BuffEffect03吸血吸能
			if buff_info.effect == 3 then
				if buff_info.state == 11 and defence_info.life > 0 then
					local vals = self:getTargetValues(defence_pos, self:getBufferIndex(buffer_id), nil)
					attack_list = {}
					defence_list = {}
					self:setTargetValues(defence_pos, vals)
					self:setHurterValues(defence_list, defence_pos, vals)
					for i = 1, #vals do vals[i] = -vals[i] end
					self:setTargetValues(attack_pos, vals)
					self:setHurterValues(attack_list, attack_pos, vals)
					self:addEventAttack(attack_list, defence_list, v)
				end
			--BuffEffect08
			elseif buff_info.effect == 8 then
				local vals = self:getTargetValues(attack_pos, self:getBufferIndex(buffer_id), nil)
				attack_list = {}
				defence_list = {}
				self:setTargetValues(attack_pos, vals)
				self:setHurterValues(attack_list, attack_pos, {})
				self:setHurterValues(defence_list, attack_pos, vals)
				self:addEventAttack(attack_list, defence_list, buff_info.weapon_id)
			--BuffEffect24,扣对方能量条
			elseif buff_info.effect == 24 then
				local anger_defence = self:getAnger(defence_pos)
				local anger_defence_value = anger_defence * self:getBuffValue(buff_info, 7) + self:getBuffAdd(buff_info, 7)
				anger_defence = self:addAnger(defence_pos, anger_defence_value)
				if anger_defence < 0 then
					attack_list = {}
					defence_list = {}
					self:setHurterValue(defence_list, defence_pos, 7, anger_defence)
					self:addEventAttack(attack_list, defence_list, buff_info.weapon_id)
				end
			end
		end

		--BuffEffect04反击
		for buffer_id_defence, buff_info_defence in pairs(self:getBuffList(defence_pos)) do
			if buff_info_defence.effect == 4 and defence_info.life > 0 then
				--BuffEffect05,确认对方没有反击buff
				local isNone = true
				for buffer_id_attack, buff_info_attack in pairs(self:getBuffList(attack_pos)) do
					if buff_info_attack.effect == 5 then
						isNone = false
						break
					end
				end
				if isNone then
					local hurt = self:getHurt(defence_pos, attack_pos, self:getTargetValues(defence_pos, self:getBufferIndex(buffer_id_defence), nil), self:getTargetValues(attack_pos, self:getBufferIndex(buffer_id_attack), nil))
					self:setHurt(attack_pos, hurt)
					attack_list = {}
					defence_list = {}
					self:setHurterValue(attack_list, defence_pos, 0, 0)
					self:setHurterValue(defence_list, attack_pos, 1, -hurt)
					self:addEventAttack(attack_list, defence_list, v)
				end
			end
		end

		isWin = self:isWin()
		if isWin == 0 and attack_pos[1] == 2 then
			self:doSkill(self:getPos(attack_pos))
		end
	end

	--print("iswin", isWin, "round", self.m_round)
	self:onFightEnd()
	self:onRoundEnd()
	return isWin
end

function FightPve:doSkill(iPos)
	local attack_pos = self:getPos(iPos)
	local attack_info = self:getShipInfo(attack_pos)
	local attack_list = {}
	local hurter_list = {}

	if attack_info.skill == 0 then
		print(iPos, "skill 0")
		return
	end

	local conf = self:getConfWeapon(attack_info.skill)
	--天赋技能1,必杀技所需怒气可定义
	local anger_max = conf.ANGER_MAX
	local anger_attack = self:getAnger(attack_pos)
	if anger_attack < anger_max or attack_info.skill == 0 or iPos < 10 and os.time() - self.m_skill_time < 3 then
		if anger_attack < anger_max then
			print(iPos, "skill anger not enough")
		elseif attack_info.skill == 0 then
			print(iPos, "no skill")
		elseif iPos < 10 and os.time() - self.m_skill_time < 3 then
			print(iPos, "skill time not enough")
		end
		return
	end
	local defence_pos = self:getDefence(attack_pos)
	if defence_pos then
		self:addBuffer(attack_pos, defence_pos, attack_list, hurter_list, attack_info.skill)
		local iCategory = self:getCategory(attack_info.skill)
		if iCategory == 5 or iCategory == 1 or iCategory == 7 or iCategory == 3 then
			--print(iPos, attack_info.skill, iCategory)
			local attack_add = attack_info.attack_physical * self:getValue(conf, 2) + self:getAdd(conf, 2)
			self:setHurterValue(attack_list, attack_pos, 2, attack_add)
			self:setHurterValue(attack_list, attack_pos, 7, self:addAnger(attack_pos, -attack_info.anger))
			local target_list = self:getTargetList(attack_pos, defence_pos, conf.TYPE)
			for k,v in ipairs(target_list) do
				local defence_info = self:getShipInfo(v)
				local life_add = defence_info.defence - attack_info.attack_physical - attack_add
				local anger_add = 20
				if life_add >= 0 then
					life_add = -1
				end
				defence_info.life = defence_info.life + life_add
				self:setHurterValue(hurter_list, v, 1, life_add)
				self:setHurterValue(hurter_list, v, 7, self:addAnger(v, anger_add))
			end
			self:removeShip()
			--Tools.print_t("SkillAttack", self.m_event_list)
		elseif iCategory == 66 or iCategory == 22 then
			if conf.TYPE == 1 and conf.BUFF > 0 then
				local buff_conf = self:getConfBuff(conf.BUFF)
				self:setHurterValue(attack_list, attack_pos, 7, self:addAnger(attack_pos, -attack_info.anger))
				local target_list = self:getTargetList(attack_pos, defence_pos, buff_conf.TYPE)
				for k,v in ipairs(target_list) do
					local target_info = self:getShipInfo(v)
					if self:checkKey(buff_conf, 3) then
						--self.m_buffer_list[self:getPos(v)][buff_conf.ID] = {buff_conf.ROUND,0}
						--local hurter_values = {}
						--hurter_values[3] = target_info.defence * self:getValue(conf, 3) + self:getAdd(conf, 3)
						--hurter_values[5] = buff_conf.ID
						--table.insert(hurter_list, {v, hurter_values})
						self:setHurterValue(hurter_list, v, 3, target_info.defence * self:getValue(conf, 3) + self:getAdd(conf, 3))
						self:setHurterValue(hurter_list, v, 5, buff_conf.ID)
					end
				end
				--Tools.print_t("SkillDefence", self.m_event_list)
			end
		elseif iCategory == 8 or iCategory == 4 or iCategory == 6 or iCategory == 2 then
			self:setHurterValue(attack_list, attack_pos, 7, self:addAnger(attack_pos, -attack_info.anger))
			local target_list = self:getTargetList(attack_pos, defence_pos, conf.TYPE)
			for _,target_pos in ipairs(target_list) do
				local target_info = self:getShipInfo(target_pos)
				for i,key in ipairs(conf.KEY) do
					local value = conf.VALUE[i]
					local add = conf.ADD[i]
					local val = 0
					if key == 1 then
						val = target_info.life + target_info.life * value + add
						if val ~= 0 then
							target_info.life = target_info.life + val
							self:setHurterValue(hurter_list, target_pos, 1, val)
						end
					elseif key == 2 then
						val = target_info.attack_physical + target_info.attack_physical * value + add
						if val ~= 0 then
							target_info.attack_physical = target_info.attack_physical + val
							self:setHurterValue(hurter_list, target_pos, 2, val)
						end
					elseif key == 3 then
						val = target_info.defence + target_info.defence * value + add
						if val ~= 0 then
							target_info.defence = target_info.defence + val
							self:setHurterValue(hurter_list, target_pos, 3, val)
						end
					elseif key == 4 then
						val = target_info.speed + target_info.speed * value + add
						if val ~= 0 then
							target_info.speed = target_info.speed + val
							self:setHurterValue(hurter_list, target_pos, 4, val)
						end
					elseif key == 6 then
						val = target_info.probability_dodge + target_info.probability_dodge * value + add
						if val ~= 0 then
							target_info.probability_dodge = target_info.probability_dodge + val
							self:setHurterValue(hurter_list, target_pos, 6, val)
						end
					elseif key == 7 then
						val = target_info.anger + target_info.anger * value + add
						if val ~= 0 then
							target_info.anger = target_info.anger + val
							self:setHurterValue(hurter_list, target_pos, 7, val)
						end
					elseif key == 8 then
						val = target_info.probability_crit + target_info.probability_crit * value + add
						if val ~= 0 then
							target_info.probability_crit = target_info.probability_crit + val
							self:setHurterValue(hurter_list, target_pos, 8, val)
						end
					elseif key == 10 then
						val = target_info.attack_energy + target_info.attack_energy * value + add
						if val ~= 0 then
							target_info.attack_energy = target_info.attack_energy + val
							self:setHurterValue(hurter_list, target_pos, 10, val)
						end
					elseif key == 11 then
						val = target_info.probability_hit + target_info.probability_hit * value + add
						if val ~= 0 then
							target_info.probability_hit = target_info.probability_hit + val
							self:setHurterValue(hurter_list, target_pos, 11, val)
						end
					elseif key == 12 then
						val = target_info.probability_anticrit + target_info.probability_hit * value + add
						if val ~= 0 then
							target_info.probability_anticrit = target_info.probability_anticrit + val
							self:setHurterValue(hurter_list, target_pos, 12, val)
						end
					end
				end
			end
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
		if iPos < 10 then
			self.m_skill_time = os.time()
		end
		self:addEventAttack(attack_list, hurter_list, conf.ID)
	end
	return self:isWin()
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

function FightPve:getAnger(pos)
	return self.m_anger_list[pos[1]]
end

function FightPve:getAttack()
	local attack
	if self.m_attack then
		attack = self.m_attack
		self.m_attack = nil
	else
		self.m_fight_index = self.m_fight_index < #self.m_fight_list and (self.m_fight_index + 1) or 1
		self:sort()
		if self.m_fight_index == 1 then
			self.m_round = self.m_round + 1
			if self:isWin() == 0 then
				self:addEventRound(self.m_round)
			end
		end
		attack = self.m_fight_list[self.m_fight_index]
	end
	return attack
end

function FightPve:getBuffAdd(buff_info, key)
	local val = 0
	for k,v in ipairs(buff_info.key) do
		if v == key then
			val = buff_info.add[k] or 0
			break
		end
	end
	return val
end

function FightPve:getBuffId(buff_id)
	return math.floor(buff_id / 10)
end

function FightPve:getBufferIndex(buffer_id)
	return buffer_id % 10
end

function FightPve:getBuffKey(buff_info, idx)
	return buff_info.key[idx] or 0
end

function FightPve:getBuffList(pos)
	return self.m_buffer_list[self:getPos(pos)]
end

function FightPve:getBuffValue(buff_info, key)
	local val = 0
	for k,v in ipairs(buff_info.key) do
		if v == key then
			val = buff_info.value[k] or 0
			break
		end
	end
	return val
end

function FightPve:getCategory(id)
	return self:m(tonumber(string.sub(tostring(id), 3, 4)), 4)
end

function FightPve:getConfBuff(buff_id)
	local buff_conf
	buff_id = tonumber(buff_id)
	if buff_id and buff_id > 0 then
		buff_conf = CONF.BUFF.get(buff_id)
		if buff_conf.STATUS == 0 then
			buff_conf = nil
		end
	end
	return buff_conf
end

function FightPve:getConfGift(gift_id)
	local gift_conf
	if gift_id > 0 then
		gift_conf = CONF.GIFT.get(gift_id)
		if gift_conf.STATUS == 0 then
			gift_conf = nil
		end
	end
	return gift_conf
end

function FightPve:getConfWeapon(weapon_id)
	local weapon_conf
	if weapon_id > 0 then
		weapon_conf = CONF.WEAPON.get(weapon_id)
		if weapon_conf.STATUS == 0 then
			weapon_conf = nil
		end
	end
	return weapon_conf
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
	local event_info
	if #self.m_event_list > self.m_event_index then
		self.m_event_index = self.m_event_index + 1
		event_info = self.m_event_list[self.m_event_index]
	end
	return event_info
end

function FightPve:getFightList(i)
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

function FightPve:getFightRandom(pos)
	local fight_list = {}
	for k,v in ipairs(self.m_fight_list) do
		if not self:compare(v, pos) and v[1] == pos[1] then
			table.insert(fight_list, v)
		end
	end
	return #fight_list > 0 and fight_list[math.random(#fight_list)] or pos
end

function FightPve:getHurt(attack_pos, defence_pos, attack_values, defence_values)
	local attack_info = self:getShipInfo(attack_pos)
	local defence_info = self:getShipInfo(defence_pos)
	local hurt = 0
	if attack_info.life > 0 and defence_info.life > 0 then

		for buffer_id_attack, buff_info_attack in pairs(self:getBuffList(attack_pos)) do
			--BuffEffect10,对方冻结,伤害加倍,BuffEffect10
			if buff_info_attack.effect == 10 then
				for buffer_id_defence, buff_info_defence in pairs(self:getBuffList(defence_pos)) do
					--BuffEffect12,
					if buff_info_defence.effect == 12 then
						attack_values[2] = attack_values[2] + attack_info.attack_physical * self:getBuffValue(buff_info_attack, 2) + self:getBuffAdd(buff_info_attack, 2)
						break
					end
				end
			--BuffEffect25,
			elseif buff_info_attack.effect == 25 then
				for buffer_id_defence, buff_info_defence in pairs(self:getBuffList(defence_pos)) do
					if buff_info_defence.debuff == 1 then
						attack_values[2] = attack_values[2] + attack_info.attack_physical * self:getBuffValue(buff_info_attack, 2) + self:getBuffAdd(buff_info_attack, 2)
						break
					end
				end
			--BuffEffect27,对方灼烧,伤害加倍,
			elseif buff_info_attack.effect == 27 then
				for buffer_id_defence, buff_info_defence in pairs(self:getBuffList(defence_pos)) do
					--BuffEffect12,
					if buff_info_defence.effect == 10 then
						attack_values[2] = attack_values[2] + attack_info.attack_physical * self:getBuffValue(buff_info_attack, 2) + self:getBuffAdd(buff_info_attack, 2)
						break
					end
				end
			end
		end

		hurt = attack_info.attack_physical + attack_values[2] - defence_info.defence - defence_values[3]
		if hurt < 0 then
			hurt = 1
		end
		if hurt > defence_info.life then
			hurt = defence_info.life
		end




		--BuffEffect06,受击不死
		if hurt == defence_info.life then
			local buffer_list = self:getBuffList(defence_pos)
			for buffer_id, buff_info in pairs(buffer_list) do
				if buff_info.effect == 6 then
					hurt = defence_info.life - 1
					break
				end
			end
		end
	end
	return hurt
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
	local fight_list = self.m_fight_list
	--自己
	if weapon_type == 1 then
		table.insert(target_list, attack_pos)
	--我方随机
	elseif weapon_type == 2 then
		table.insert(target_list, self:getFightRandom(attack_pos))
	--我方全体
	elseif weapon_type == 3 then
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == attack_pos[1] then
				table.insert(target_list, v)
			end
		end
	--我方血最少
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
	--我方防最高
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
	--我方攻最高
	elseif weapon_type == 7 then
		local t = attack_pos
		for k,v in fight_list do
			if v[1] == t[1] then
				if self:getShipInfo(v).attack_physical > self:getShipInfo(t).attack_physical then
					t = v
				end
			end
		end
		table.insert(target_list, t)
	--我方横排
	elseif weapon_type == 8 then
		local t = attack_pos
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == t[1] and v[2] == t[2] then
				table.insert(target_list, v)
			end
		end
		table.insert(target_list, t)
	--我方竖排
	elseif weapon_type == 9 then
		local t = attack_pos
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == t[1] and v[3] == t[3] then
				table.insert(target_list, v)
			end
		end
		table.insert(target_list, t)
	--对方单体
	elseif weapon_type == 11 then
		table.insert(target_list, defence_pos)
	--对方随机
	elseif weapon_type == 12 then
		table.insert(target_list, self:getFightRandom(defence_pos))
	--对方全体
	elseif weapon_type == 13 then
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == defence_pos[1] then
				table.insert(target_list, v)
			end
		end
	--对方血血少
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
	--对方防最少
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
	--对方攻最高
	elseif weapon_type == 17 then
		local t = defence_pos
		for k,v in fight_list do
			if v[1] == t[1] then
				if self:getShipInfo(v).attack_physical > self:getShipInfo(t).attack_physical then
					t = v
				end
			end
		end
		table.insert(target_list, t)
	--对方横排
	elseif weapon_type == 18 then
		local t = defence_pos
		for k,v in ipairs(self.m_fight_list) do
			if v[1] == t[1] and v[2] == t[2] then
				table.insert(target_list, v)
			end
		end
	--对方竖排
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

function FightPve:getTargetValues(target_pos, buffer_index, values)
	local target_info = self:getShipInfo(target_pos)
	local weapon_info = self:getWeaponInfo(target_pos)
	local conf_buff
	local vals
	if self:isEmpty(values) then
		vals = self:newValues(0, 12)
	else
		vals = values
	end
	local keys
	if buffer_index > 0 then
		local buff_id = tonumber(weapon_info[self:concat("BUFF",buffer_index)])
		if buff_id then
			conf_buff = self:getConfBuff(buff_id)
			keys = conf_buff.KEY
		else
			keys = {}
		end
	else
		keys = weapon_info.KEY
	end
	local sPostfix = buffer_index > 0 and tostring(buffer_index) or ""
	if weapon_info then
		for k,v in ipairs(keys) do
			local val = 0
			if v == 1 then
				val = target_info.life
			elseif v == 2 then
				val = target_info.attack_physical
			elseif v == 3 then
				 val = target_info.defence
			elseif v == 4 then
				val = target_info.speed
			elseif v == 6 then
				val = target_info.probability_dodge
			elseif v == 7 then
				val = target_info.anger
			elseif v == 8 then
				val = target_info.probability_crit
			elseif v == 10 then
				val = target_info.attack_energy
			elseif v == 11 then
				val = target_info.probability_hit
			elseif v == 12 then
				val = target_info.probability_anticrit
			end
			if val > 0 then
				local add = val * (weapon_info[self:concat("VALUE",sPostfix)][k] or 0) + (weapon_info[self:concat("ADD",sPostfix)][k] or 0)
				if add > 0 then
					vals[v] = math.ceil(val * (weapon_info[self:concat("VALUE",sPostfix)][k] or 0) + (weapon_info[self:concat("ADD",sPostfix)][k] or 0))
				else
					vals[v] = math.floor(val * (weapon_info[self:concat("VALUE",sPostfix)][k] or 0) + (weapon_info[self:concat("ADD",sPostfix)][k] or 0))
				end
			end
		end
	end
	return vals
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

function FightPve:getValuesAttack(attack_pos)
	local attack_info = self:getShipInfo(attack_pos)
	local attack_values = self:getTargetValues(attack_pos, 0, nil)
	local buffer_id_list_remove = {}
	for buffer_id, buff_info in pairs(self:getBuffList(attack_pos)) do
		if buff_info.effect == 0 then
			attack_values = self:getTargetValues(attack_pos, self:getBufferIndex(buffer_id), attack_values)
		--BuffEffect22
		elseif buff_info.effect == 22 then
			attack_values = self:getTargetValues(attack_pos, self:getBufferIndex(buffer_id), attack_values)
			for buffer_id_attack, buff_info_attack in pairs(self:getBuffList(attack_pos)) do
				if buff_info_attack.debuff == 0 then
					table.insert(buffer_id_list_remove, buffer_id_attack)
					break
				end
			end
		end
	end
	--天赋技能9,祝福,加攻击
	local attack_add = 0
	local speed_add = 0
	for k,v in ipairs(self:getFightList(attack_pos[1])) do
		if attack_info.gift > 0 then
			local conf_gift = self:getConfGift(attack_info.gift)
			if conf_gift then
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
	end
	if attack_add > 0 then
		attack_values[2] = attack_values[2] + attack_add
	end

	if speed_add > 0 then
		attack_values[4] = attack_values[4] + speed_add
	end
	for k,v in ipairs(buffer_id_list_remove) do
		self:removeBuffer(attack_pos, v)
	end
	return attack_values
end

function FightPve:getValuesDefence(defence_pos)
	local defence_info = self:getShipInfo(defence_pos)
	local defence_values = self:getTargetValues(defence_pos, 0, nil)
	for buffer_id, buff_info in pairs(self:getBuffList(defence_pos)) do
		if buff_info.effect == 0 then
			defence_values = self:getTargetValues(defence_pos, self:getBufferIndex(buffer_id), defence_values)
		end
	end
	return defence_values
end

function FightPve:getWeaponInfo(pos)
	local ship_info = self:getShipInfo(pos)
	local weapon_id = ship_info.weapon_list[self:m(self.m_round, #ship_info.weapon_list)]
	return self:getConfWeapon(weapon_id)
end

function FightPve:init(attack_list, hurter_list)
	local box = self.m_box
	for k,v in ipairs(attack_list) do
		local pos = self:getPos(v.position)
		box[1][pos[2]][pos[3]] = v
	end

	for k,v in ipairs(hurter_list) do
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

function FightPve:isEmpty(t)
	return t == nil or next(t) == nil
end

function FightPve:isWin()
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
	self.m_attack = nil
	self.m_defence = nil

	self.m_event_index = 0
	self.m_event_list =  {}
	self.m_buffer_list =   self:newValues({}, 18)
	self.m_weapon_list = self:newValues({}, 18)
	self.m_power_list  = self:newValues({}, 18)
	self.m_anger_list = self:newValues(0, 2)
	self.m_skill_time = 0
	math.randomseed(os.time())
end

function FightPve:newValues(value, size)
	local t = {}
	for i = 1, size do
		if type(value) == "table" then
			t[i] = self:clone(value)
		else
			t[i] = value
		end
	end
	return t

end

function FightPve:onFightBegin()
	self:sort()
end

function FightPve:onFightEnd()
	--BuffEffect01,中毒
	for k,v in ipairs(self.m_buffer_list) do
		for buffer_id, buff_info in pairs(v) do
			if buff_info.effect == 1 then
				local pos = self:getPos(k)
				local values = self:getTargetValues(pos, self:getBufferIndex(buffer_id), nil)
				local vals = self:setTargetValues(pos, values)
				self:addEventAttack({}, {{pos, vals},}, buffer_id)
			end
		end
	end
	self:removeBuff(1)
end

function FightPve:onRoundEnd()
	if self.m_fight_index < #self.m_fight_list then
		return
	end
	--BuffEffect02,灼烧
	for k,v in ipairs(self.m_buffer_list) do
		for buffer_id, buff_info in pairs(v) do
			if buff_info.effect == 2 then
				local pos = self:getPos(k)
				local values = self:getTargetValues(pos, self:getBufferIndex(buffer_id), nil)
				local vals = self:setTargetValues(pos, values)
				self:addEventAttack({}, {{pos, vals},}, buffer_id)
			end
		end
	end
	self:removeBuff(2)
end

function FightPve:removeBuff(iEffect)
	local buff_list_event = {}
	for iPos, buffer_list in ipairs(self.m_buffer_list) do
		for buffer_id, buff_info in pairs(buffer_list) do
			if iEffect == 1 then
				assert(buff_info.count, string.format("weapon_id,%d", buff_info.weapon_id))
				if buff_info.count > 0 then
					buff_info.count = buff_info.count - 1
					if buff_info.count <= 0 then
						self:setHurterValue(buff_list_event, self:getPos(iPos), 5, -self:getBuffId(buffer_id))
						buffer_list[buffer_id] = nil
					end
				end
			else
				if buff_info.round > 0 then
					buff_info.round = buff_info.round - 1
					if buff_info.round <= 0 then
						self:setHurterValue(buff_list_event, self:getPos(iPos), 5, -self:getBuffId(buffer_id))
						buffer_list[buffer_id] = nil
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

function FightPve:removeBuffer(pos, buffer_id)
	local buff_info = self.m_buffer_list[self:getPos(pos)]
	if buff_info[buffer_id] then
		local buff_list_event = {}
		self:setHurterValue(buff_list_event, self:getPos(pos), 5, -self:getBuffId(buffer_id))
		self:addEventRemoveBuff(buff_list_event)
		buff_info[buffer_id] = nil
	end
end

function FightPve:removeShip()
	local fight_list = self.m_fight_list
	for i = #fight_list, 1, -1 do
		local ship_info = self:getShipInfo(fight_list[i])
		if ship_info.life <= 0 then
			ship_info.life = 0
			self.m_buffer_list[self:getPos(fight_list[i])] = {}
			if i <= self.m_fight_index then
				self.m_fight_index = self.m_fight_index - 1
			end
			table.remove(fight_list, i)
		end
	end
end

function FightPve:setAttack(pos)
	self.m_attack = pos
end

function FightPve:setAnger(attack_pos, defence_pos)
	self:addAnger(attack_pos, 20)
	self:addAnger(defence_pos, 20)
end

function FightPve:setDefence(pos)
	--if not pos then
end

function FightPve:setHurt(target_pos, hurt)
	local target_info = self:getShipInfo(target_pos)
	if target_info.life > 0 and hurt > 0 then
		target_info.life = target_info.life - hurt
		if target_info.life < 0 then
			target_info.life = 0
		end
		if target_info.life == 0 then
			self:removeShip()
		end
	end
end

function FightPve:setHurterValue(hurter_list, pos, key, value)
	local none = true
	for k,v in ipairs(hurter_list) do
		if self:compare(v[1], pos) and key > 0 then
			if key == 5 then
				local none_buff = true
				for _,buff_id in ipairs(v[3]) do
					if buff_id == value then
						none_buff = false
						break
					end
				end
				if none_buff then
					table.insert(v[3], value)
				end
			else
				v[2][key] = v[2][key] and v[2][key] + value or value
			end
			none = false
			break
		end
	end
	if none then
		local values
		local buffs = {}
		if key > 0 then
			values = self:newValues(0, 12)
			if key == 5 then
				table.insert(buffs, value)
			else
				values[key] = value
			end
		else
			values = {}
		end
		table.insert(hurter_list, {pos,values,buffs})
	end
end

function FightPve:setHurterValues(hurter_list, pos, values)
	local none = true
	for k,v in ipairs(hurter_list) do
		if self:compare(v[1], pos) then
			for kk,vv in ipairs(values) do
				if v[2][kk] then
					v[2][kk] = v[2][kk] + vv
				else
					v[2][kk] = v
				end
			end
			none = false
			break
		end
	end
	if none then
		table.insert(hurter_list, {pos,values})
	end
end

function FightPve:setTargetValues(target_pos, values)
	local target_info = self:getShipInfo(target_pos)
	local vals = self:newValues(0, 12)
	for k,v in pairs(values) do
		local add = 0
		if k == 1 then
			add = target_info.life < -v and -target_info.life or v
			target_info.life = target_info.life + add
			if target_info.life == 0 then
				self:removeShip()
			end
		elseif k == 2 then
			add = target_info.attack_physical < -v and -target_info.attack_physical or v
			target_info.attack_physical = target_info.attack_physical + add
		elseif k == 3 then
			add = target_info.defence < -v and -target_info.defence or v
			target_info.defence = target_info.defence + add
		elseif k == 4 then
			add = target_info.speed < -v and -target_info.speed or v
			target_info.speed = target_info.speed + add
		elseif k == 6 then
			add = target_info.probability_dodge < -v and -target_info.probability_dodge or v
			target_info.probability_dodge = target_info.probability_dodge + add
		elseif k == 7 then
			add = target_info.anger < -v and -target_info.anger or v
			add = target_info.anger > 100 - add and 100 - target_info.anger or add
			target_info.anger = target_info.anger + add
		elseif k == 8 then
			add = target_info.anger < -v and -target_info.anger or v
		elseif k == 10 then
			add = target_info.attack_energy < -v and -target_info.attack_energy or v
			target_info.attack_energy = target_info.attack_energy + add
		elseif k == 11 then
			add = target_info.probability_hit < -v and -target_info.probability_hit or v
			target_info.probability_hit = target_info.probability_hit + add
		elseif k == 12 then
			add = target_info.probability_anticrit < -v and -target_info.probability_anticrit or v
			target_info.probability_anticrit = target_info.probability_anticrit + add
		end
		vals[k] = add
	end
	return vals
end

--攻击顺序,1,Speed Desc,2,Pos,Asc,3,Attack,Asc
function FightPve:sort()
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

	local fight_index = self.m_fight_index
	local fight_list = {}
	for i=#self.m_fight_list, fight_index, -1 do
		table.insert(fight_list, self.m_fight_list[i])
		table.remove(self.m_fight_list, i)
	end
	table.sort(fight_list, f)
	for k,v in ipairs(fight_list) do
		table.insert(self.m_fight_list, v)
	end
end

return FightPve
