local kc = require "kyotocabinet"
local db = kc.DB:new()-- + kc.DB.ONOLOCK

local SyncUserCache = {}

local user_list = {}

if not db:open("SyncUser.kch", kc.DB.OWRITER + kc.DB.OCREATE) then

	error("SyncUser.kch open err")
else

	db:iterate(
		function(k,v)
			local user = Tools.decode("SyncUser", v)
			user_list[k] = user
		end,
	false)

end

function SyncUserCache.createSyncUser( user_name )
	local user = {
		user_name = user_name,
		res = {0,0,0,0,}
	}
	return user
end

function SyncUserCache.getSyncUser( user_name )
	local user = user_list[user_name]
	return user
end

function SyncUserCache.setSyncUser( data )

	user_list[data.user_name] = data

	db:set(data.user_name, Tools.encode("SyncUser", data))
end

function SyncUserCache.sync( user_info )

	user_info.res = user_list[user_info.user_name].res
end

function SyncUserCache.getMultiCast( recver )
	local list
	if type(recver) == "table" then
		list = recver
	else
		list = {recver}
	end

	local multi_cast =
	{
		recv_list = list,
		cmd = 0x1034,
		msg_buff = "0",
	}
	return multi_cast
end

return SyncUserCache