local kc = require "kyotocabinet"
local db = kc.DB:new()-- + kc.DB.ONOLOCK

local VideoCache = {}

local data_list = {} --key:user_name value:data_list

local last_update = os.time()

if not db:open("Video.kch", kc.DB.OWRITER + kc.DB.OCREATE) then

	error("Video.kch open error")
else
	db:iterate(
		function(k,v)
			local key_list = Tools.split(k, "_")
		
			if Tools.isEmpty(data_list[key_list[1]]) == true then
				data_list[key_list[1]] = {}
			end

			table.insert(data_list[key_list[1]], Tools.decode("VideoData", v))
		end,
	false)
end

function VideoCache.addVideo( user_name, resp )

	local cur_time = os.time()

	if Tools.isEmpty(data_list[user_name]) == true then
		data_list[user_name] = {}
	end

	local guid = Tools.getGuid(data_list[user_name])

	if guid == nil then
		return nil
	end

	local data = {
		guid = guid,
		stamp = cur_time,
		expiry_stamp = cur_time + 604800,
		resp = resp,
	}

	table.insert(data_list[user_name], data)
	local key = user_name .. "_" .. guid
	db:set(key, Tools.encode("VideoData", data))

	return key
end

function VideoCache.getVideo( key )

	local key_list = Tools.split(key, "_")

	local guid = tonumber(key_list[2])

	if Tools.isEmpty(data_list[key_list[1]]) == true then
		return nil
	end

	for i,v in ipairs(data_list[key_list[1]]) do
		if v.guid == guid then
			return v
		end
	end

	return nil
end

function VideoCache.doTimer()

	local cur_time = os.time()

	if cur_time - last_update > 86400 then
		for user_name,list in pairs(data_list) do
			for i=#list, 1, -1 do
				if cur_time > list[i].expiry_stamp then
					db:remove(user_name .. "_" .. list[i].guid)
					table.remove(list, i)
				end
			end
		end
		last_update = cur_time
	end
end

return VideoCache