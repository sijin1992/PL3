
local BuffAttackEvent = class("BuffAttackEvent",require("app.battle.event.BattleEvent"))

BuffAttackEvent.hurters = nil

BuffAttackEvent.waitTime = 0.5
BuffAttackEvent.timer = 0

function BuffAttackEvent:ctor(data,bm)
	self.bm = bm

	self.hurters = {}

	for i, v in ipairs(data.hurter_list) do

		local pos = (v.pos[2] - 1) * 3 + v.pos[3]

		local hurter = bm:getShip(v.pos[1], pos)

		assert(hurter ~= nil,"error")

		table.insert(self.hurters,{obj = hurter,attr = v.values, buffs = v.buffs, status = v.status})
	end
end

function BuffAttackEvent:start()

	for index,obj in ipairs(self.hurters) do
		
		self:hurterGetHurt(index)
	end

end

function BuffAttackEvent:hurterGetHurt( index )


	local hurter = self.hurters[index]

	local list = hurter.attr
	if list ~= nil then
		for _,v in ipairs(hurter.attr) do
			hurter.obj:getHurt(v.key, v.value, hurter.status)
		end 
	end

	hurter.obj:setStatus(hurter.status)

end

function BuffAttackEvent:process(dt)

	self.timer = self.timer + dt

	if self.timer > self.waitTime then
		return true
	end
	return false
end

function BuffAttackEvent:finish()

end

return BuffAttackEvent