
local fightManager = require("FightLogic.FightManager")

local FightControler = {}

function FightControler:init(attack_list, attack_hp_list, hurter_list, hurter_hp_list, isPve)
	
	fightManager:init(attack_list, attack_hp_list, hurter_list, hurter_hp_list, isPve)
end

function FightControler:destroy()
	fightManager:destroy()
end

function FightControler:getEvent()
	
	return fightManager:popEvent()
end

function FightControler:doLogic()
	fightManager:doLogic()
end

function FightControler:doSkill(shipPos)
	return fightManager:doSkill(shipPos)
end

function FightControler:loseNow( )
	fightManager.LoseSwitch = true
end

function FightControler:getSkillTargetTest(index)
	return fightManager:getSkillTargetTest(index)
end

function FightControler:isPve()
	return fightManager:isPve()
end
function FightControler:setPve(ispve)
	fightManager:setPve(ispve)
end

return FightControler