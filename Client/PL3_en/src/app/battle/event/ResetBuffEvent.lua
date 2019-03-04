
local ResetBuffEvent = class("ResetBuffEvent",require("app.battle.event.BattleEvent"))

ResetBuffEvent.hurters = nil

function ResetBuffEvent:ctor(data,bm)

	self.bm = bm

	if data.values then
		self.weaponID = data.values[1]
	end
	

	self.hurters = {}

	for i, v in ipairs(data.hurter_list) do

		local pos = (v.pos[2] - 1) * 3 + v.pos[3]
		local hurter = bm:getShip(v.pos[1], pos)

		assert(hurter ~= nil,"error")

		table.insert(self.hurters,{obj = hurter,buffs = v.buffs, attr = v.values, status = v.status})
	end
	
end

function ResetBuffEvent:hurterResetAttr( index )


	local hurter = self.hurters[index]

	local list = hurter.attr
	if list ~= nil then
		for _,v in ipairs(hurter.attr) do
			hurter.obj:getHurt(v.key, v.value, hurter.status, true)
		end 
	end
end

function ResetBuffEvent:start()


	for index,hurter in ipairs(self.hurters) do
		
		self:hurterResetAttr(index)

		for i,v in ipairs(hurter.buffs) do
			if v > 0 then
				hurter.obj:addBuff(v,self.weaponID)
			elseif v < 0 then
				hurter.obj:removeBuff(v)
			end
		end 
	end

end

function ResetBuffEvent:process(dt)

	return true
end

function ResetBuffEvent:finish()

end

return ResetBuffEvent