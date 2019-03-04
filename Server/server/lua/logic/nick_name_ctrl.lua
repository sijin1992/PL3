
local nick_name_list = {}    -- nick_name-->data

local kc = require "kyotocabinet"
local db = kc.DB:new()

if not db:open("nick_name_ctrl.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
	error("nick_name_ctrl.lua open err")
else
	db:iterate(
		function(k,v)

			local data = Tools.decode("nick_name_ctrl", v)

			nick_name_list[k] = data

			--print("nick_name_ctrl",k,data.user_name)
		end, false
	)
end

local function has_nick_name(nick_name)

	local data = nick_name_list[nick_name]

	if data ~= nil then 
		return true,data
	else 
		return false
	end
end

local function add_nick_name(nick_name, user_name)
	local data = {
		user_name = user_name,
		flag = 0,
	}
	nick_name_list[nick_name] = data

	local t = Tools.encode("nick_name_ctrl", data)
	db:set(nick_name, t)
end

local function check_add_nick_name(nick_name, user_name)
	if has_nick_name(nick_name) then 
		return false 
	end
	add_nick_name(nick_name, user_name)
	return true
end

local nick_name_ctrl = {
	check_add_nick_name = check_add_nick_name,
	has_nick_name = has_nick_name,
	add_nick_name = add_nick_name
}

return nick_name_ctrl