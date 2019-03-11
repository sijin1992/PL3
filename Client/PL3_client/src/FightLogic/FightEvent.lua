
local FightEvent = class("FightEvent")

FightEvent.EventType = {
	kWin = 1,
	kAttack = 2,
	kBuff = 3,
	kRound = 4,
	kCreateBuff = 5,
	kFightList = 6,
	kEnergy = 7,
}


local function mergeValue(table1, table2)
	for i,v in ipairs(table2) do
		table.insert(table1, v)
	end
	return table1
end

local function mergeBuff(table1, table2)
	for i,v in ipairs(table2) do
		local has = false
		for i1,v1 in ipairs(table1) do
			if v1 == v then
				has = true
				break
			end
		end
		if has == false then
			table.insert(table1, v)
		end
	end
	return table1
end

function FightEvent:ctor(id, values, attack_list, hurter_list, attack_hp_list, hurter_hp_list)
 	self.event_ = {

 		id = id,
 		values = values,
 		attack_list = attack_list,
 		hurter_list = hurter_list,
 		attack_hp_list = attack_hp_list,
 		hurter_hp_list = hurter_hp_list,
 	}
end 

function FightEvent:getEvent(  )
	
	return self.event_
end

function FightEvent:addAttacker( element )

	self.event_.attack_list = self.event_.attack_list or {}
	
	table.insert(self.event_.attack_list, element)
end

function FightEvent:addHurter( element )

	self.event_.hurter_list = self.event_.hurter_list or {}

	local flag = false
	for i,v in ipairs(self.event_.hurter_list) do
		if v.pos == element.pos then

			if v.buffs == nil then
				if element.buffs then
					v.buffs = element.buffs
				end
			else
				if element.buffs then
	
					mergeBuff(v.buffs, element.buffs)
				end
			end

			if v.values == nil then
				if element.values then
					v.values = element.values
				end
			else
				if element.values then

					mergeValue(v.values, element.values)
				end
			end
			
			return
		end
	end

	table.insert(self.event_.hurter_list, element)
end

function FightEvent:isAttackerEmpty()
	return Tools.isEmpty(self.event_.attack_list)
end

function FightEvent:isHurterEmpty()
	return Tools.isEmpty(self.event_.hurter_list)
end

return FightEvent