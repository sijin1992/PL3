local kc = require "kyotocabinet"
local db = kc.DB:new()-- + kc.DB.ONOLOCK

local trial_building_list = {}

if not db:open("Trial.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
	error("Trial.kch open err")
else
	db:iterate(
		function(k,v)
			local data = Tools.decode("TrialBuilding", v)
			trial_building_list[k] = data
		end,
	false) 
end

local TrialCache = {}

function TrialCache.get(level_id)
	local string = string.format("%d",level_id)

	local data = trial_building_list[string]

	return data
end

function TrialCache.set(level_id, trial_main)

	local string = string.format("%d",level_id)

	trial_building_list[string] = trial_main


	local trial_buff = Tools.encode("TrialBuilding", trial_main)

	return db:set(level_id, trial_buff)
end


return TrialCache