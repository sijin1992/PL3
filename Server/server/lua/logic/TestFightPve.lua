dofile("lua/logic/Global.lua")

function print_t(t, depth)
	depth = depth or 0
	local s
	local tt = {}
	if depth > 0 then
		s = string.rep("\t", depth)
	else
		s = ""
		tt[#tt+1] = ""
	end
	if type(t) == "table" then
		for k, v in pairs(t) do
			if type(v) == "table" then
				if v and next(v) then
					tt[#tt+1] = string.format("%s%s->%s", s, k, tostring(v))
					tt[#tt+1] = print_t(v, depth+1)
				end
			else
				tt[#tt+1] = string.format("%s%s->%s", s, k, tostring(v))
			end
		end
	end
	return table.concat(tt, "\n")
end

local attack_list = {
	{guid=1,position=2,id=10010001,life=100,attack_physical=20,defence=2,speed=40,probability_dodge=10,anger=10,probability_crit=10,attack_energy=10,probability_hit=10,probability_anticrit=10,type=1,status=1,skill=15080901,gift=14010001,weapon_list={15010001,15010002,15010008},},
	{guid=2,position=1,id=10010002,life=100,attack_physical=20,defence=2,speed=30,probability_dodge=10,anger=10,probability_crit=10,attack_energy=10,probability_hit=10,probability_anticrit=10,type=2,status=1,skill=15050901,gift=14020002,weapon_list={15010003,15010004},},
}
local hurter_list = {
	{guid=0,position=1,id=10990001,life=100,attack_physical=10,defence=1,speed=20,probability_dodge=10,anger=10,probability_crit=10,attack_energy=10,probability_hit=10,probability_anticrit=10,type=1,status=0,skill=15010914,gift=0,weapon_list={15010001,15010002},},
	{guid=0,position=2,id=10990002,life=100,attack_physical=10,defence=1,speed=10,probability_dodge=10,anger=10,probability_crit=10,attack_energy=10,probability_hit=10,probability_anticrit=10,type=2,status=0,skill=15010908,gift=0,weapon_list={15010003,15010004},},
}

local function getWinner(event_list)
	local winner = 0
	for k,v in ipairs(event_list) do
		if v[1] == 1 then
			winner = v[2]
		end
		if winner > 0 then
			break
		end
	end
	return winner
end

local function getLife(fighting)
	for i=1,2 do
		for j=1,3 do
			for k=1,3 do
				if fighting.m_box[i][j][k] and fighting.m_box[i][j][k].life > 0 then
					print(fighting:getPos({i,j,k}), fighting.m_box[i][j][k].life)
				end
			end
		end
	end
end

local fighting = require "FightPve"
fighting:new()
fighting:init(attack_list, hurter_list)

--print("BeforeSkill", print_t(fighting.m_box))
--
--print("AfterSkill", print_t(fighting.m_box))
local step = 0
local step_event = 0
local isWin = 0
repeat
	step = step + 1	
	fighting:doFight()
	local event_list = {}
	local event_info
	repeat
		event_info = fighting:getEvent()
		if event_info then
			if event_info.id == 1 then
				isWin = event_info.value
			end
			step_event = step_event + 1
			table.insert(event_list, event_info)
		end
	until not event_info or isWin > 0
	if step == 1 or step == 2 or step == 3 then
		--print("step,"..step, "round,"..fighting.m_round, "fight_index,"..fighting.m_fight_index, "isWin,"..isWin.."\n")
		print("step,"..step, "step_event,"..step_event, "round,"..fighting.m_round, "fight_index,"..fighting.m_fight_index, "isWin,"..isWin, "event_list,"..print_t(event_list).."\n")
		--getLife(fighting)
	end
	--[[
	if step == 1 then
		getLife(fighting)		
		fighting:doSkill(2)
		print("fighting:m_buff_list", print_t(fighting.m_buff_list))
		repeat
			event_info = fighting:getEvent()
			if event_info then
				if event_info.id == 1 then
					isWin = event_info.value
				end
				print("skill", print_t(event_info))
				getLife(fighting)
			end
		until not event_info
		print("fighting:m_buff_list", print_t(fighting.m_buff_list))
	end		
	--]]
until isWin > 0
--print("Winner", isWin, "Step", step, "step_event", step_event)
