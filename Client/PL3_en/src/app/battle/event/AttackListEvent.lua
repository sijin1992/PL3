
local AttackListEvent = class("AttackListEvent",require("app.battle.event.BattleEvent"))
local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()
local player = require("app.Player"):getInstance()

function AttackListEvent:ctor(data,bm)
	self.bm = bm



	local attackers = {}
	if data.attack_list ~= nil then
		for i, v in ipairs(data.attack_list) do
		
			local pos = (v.pos[2] - 1) * 3 + v.pos[3]

			local attacker = bm:getShip(v.pos[1], v.pos[2],v.pos[3])

			assert(attacker ~= nil,"error")

			table.insert(attackers, {obj = attacker, isBig = v.isBig})

		end
	end
	
	local pos,isBig

	if data.values[1] == 1 then

		self.bm:getAttackList():reset(attackers)

	elseif data.values[1] == 2 then

		for i,v in ipairs(attackers) do
			self.bm:getAttackList():remove(v)
		end

	elseif data.values[1] == 3 then

		pos, isBig = self.bm:getAttackList():next()

	elseif data.values[1] == 4 then

		self.bm:getAttackList():insert(attackers[1])
		pos = attackers[1].obj:getPos()
	end

	-- if pos then
	-- 	--todo:
	-- 	if player:getGuideStep() < 50 then 
	-- 		if pos[1] == 1 then
	-- 			local ppap = (pos[2] - 1) * 3 + pos[3]

	-- 			if ppap == 5 then
	-- 				print("hahahahha",guideManager:getSelfGuideID())
	-- 				if guideManager:getSelfGuideID() < 43 then
	-- 					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BattlePause")
	-- 					g_guiding_can_skill = true
	-- 					guideManager:createGuideLayer(43)
	-- 				end
	-- 			else
	-- 			end

	-- 		-- elseif pos[1] == 2 then

	-- 		-- 	if data.values[1] == 3 then

	-- 		-- 		if isBig and isBig == true then
	-- 		-- 			local ppap = (pos[2] - 1) * 3 + pos[3]
	-- 		-- 			if ppap == 6 then
	-- 		-- 				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BattlePause")
	-- 		-- 				guideManager:createGuideLayer(116)
	-- 		-- 			end
	-- 		-- 		end
	-- 		-- 	end
	-- 		end
	-- 	end
	-- end
end

function AttackListEvent:start()

	

end

function AttackListEvent:process(dt)
	
	return true
end

function AttackListEvent:finish()
	
end

return AttackListEvent