package.path = "./?.lua;../?.lua"

require "json"

CONF = require "../configuration"
CONF:load "../config"

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
	{guid=1,id=10010001,position=1,speed=40,anger=10,skill=15020901,gift=14010001,life=100,attack_physical=20,defence=2,type=1,status=1,weapon_list={15010001,15010002,15010008},},
	{guid=2,id=10010002,position=2,speed=30,anger=10,skill=15010901,gift=14020002,life=100,attack_physical=20,defence=2,type=2,status=1,weapon_list={15010003,15010004},},
}
local defence_list = {
	{guid=1,id=10010001,position=1,speed=40,anger=10,skill=15040901,gift=14010001,life=100,attack_physical=20,defence=2,type=1,status=1,weapon_list={15010001,15010002},},
	{guid=2,id=10010002,position=2,speed=30,anger=10,skill=15010901,gift=14020002,life=100,attack_physical=20,defence=2,type=2,status=1,weapon_list={15010003,15010004},},
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

local event_list = {}
local fighting = require "FightPvp"
fighting:new()
fighting:init(attack_list, defence_list)
local isWin = 0
repeat
	fighting:doFight()	
	local event_info
	do event_info = fighting:getEvent()
		if event_info.id == 1 then
			isWin = event_info.value
			if isWin > 0 then
				break
			end
		end
	end
until isWin > 0
if isWin > 0 then
	event_list = fighting.m_event_list
end

print("finish", print_t(event_list))
