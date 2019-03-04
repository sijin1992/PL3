-- local kc = require "kyotocabinet"
-- local pb = require "protobuf"
-- local path_nick = "/usr/local/services/star_server/svr80001/logic/main_logic"
-- local path_proto = "/usr/local/services/star_server/bin/logic/main_logic/lua/protobuf"
-- local nick_list = {}
-- local db = kc.DB:new()

-- local function print_t(t, depth)
-- 	depth = depth or 0
-- 	local s
-- 	local tt = {}
-- 	if depth > 0 then
-- 		s = string.rep("\t", depth)
-- 	else
-- 		s = ""
-- 		tt[#tt+1] = ""
-- 	end
-- 	if type(t) == "table" then
-- 		for k, v in pairs(t) do
-- 			tt[#tt+1] = string.format("%s%s->%s", s, k, tostring(v))
-- 			if type(v) == "table" then
-- 				tt[#tt+1] = print_t(v, depth+1)
-- 			end
-- 		end	
-- 	end
-- 	return table.concat(tt, "\n")
-- end

-- local function init()
-- 	pb.register_file(string.format("%s/nick_name.pb", path_proto))
-- end

-- local function load()
-- 	nick_list = {}	
-- 	if db:open(string.format("%s/nick_name_ctrl.kch", path_nick), kc.DB.OWRITER) then
-- 		db:iterate(
-- 	        function(k,v)            
-- 	            local d = pb.decode("nick_name", v)
-- 	            nick_list[k] = v
-- 	        end, false)
-- 	else
-- 		error("nick_name.lua open err")
-- 	end 
-- 	db:close()
-- end

-- local function remove(key)
-- 	local isSucc = false
-- 	if db:open(string.format("%s/nick_name_ctrl.kch", path_nick), kc.DB.OWRITER) then
-- 		isSucc = db:remove(key)
-- 		db:close()
-- 	end
-- 	return isSucc
-- end

-- init()
-- load()

-- for k, v in pairs(nick_list) do
-- 	print(k)
-- end

-- --local t = {1,4}
-- --local set = {}
-- --for k, l in ipairs(t) do
	
-- -- 	set[l] = true
-- --end

-- --print((set.__metatable));


-- --print(table.maxn(nick_list))
