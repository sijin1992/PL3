local EnergyEvent = class("EnergyEvent",require("app.battle.event.BattleEvent"))

function EnergyEvent:ctor(data, bm)

	self.bm = bm

	local attackers = data.attack_list
	self.attackers = {}

	printInfo("----attackers----")
	for i, v in ipairs(attackers) do
		
		local pos = (v.pos[2] - 1) * 3 + v.pos[3]

		local attack = bm:getShip(v.pos[1], v.pos[2],v.pos[3])

		assert(attack ~= nil,"error")

		table.insert(self.attackers,{obj = attack,attr = v.values, buffs = v.buffs, status = v.status})

		printInfo("  group: ", v.pos[1], "  pos: ", v.pos[2],v.pos[3])

	end
end



function EnergyEvent:start()
	for index,attacker in ipairs(self.attackers) do

		if attacker.attr ~= nil then
			for _,v in pairs(attacker.attr) do
				attacker.obj:getHurt(v.key,v.value, attacker.status)
			end
		end
	end
end

function EnergyEvent:process(dt)
	return true
end

function EnergyEvent:finish()
	
end

return EnergyEvent