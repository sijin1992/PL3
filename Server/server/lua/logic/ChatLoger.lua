
local MAX_TIME = 60000000
local MAX_COUNT = 50

local kc = require "kyotocabinet"
local db = kc.DB:new()

local list_map = {}

local function delLogWithTime(list, tm)
	while 1 do
		local need_break = true
		for k,v in ipairs(list) do
			if tm - v.stamp > MAX_TIME then
				need_break = false
				table.remove(list, k)
				break
			end
		end
		if need_break then break end
	end
end

local function delLogWithCount(list)
	local count = rawlen(list)
	while count > MAX_COUNT do
		table.remove(list, 1)
		count = count - 1
	end
end

if not db:open("chat_log.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
	LOG_ERROR("chat_log open err")
else
	local tm = os.time()
	db:iterate(
		function(k,v)
			local d = Tools.decode("ChatLogList", v)
			local t = rawget(d, "log_list")
			if t then
				delLogWithTime(t, tm)
				delLogWithCount(t)
				rawset(list_map, k, d)
			end
		end, false
	)
end

local ChatLoger = {}

function ChatLoger.pushLog(cid, msg, name, uid, group_name)
	if uid == nil then
		uid = 0
	end
	local c_list = rawget(list_map, cid)
	if not c_list then
		c_list = {
			log_list = {}
		}
		rawset(list_map, cid, c_list)
	elseif not rawget(c_list, "log_list") then
		rawset(c_list, "log_list", {})
	end
	local tm = os.time()
	table.insert(c_list.log_list, {stamp = tm, chat = msg, nickname = name, user_name = uid, group_name = group_name})
	delLogWithTime(c_list.log_list, tm)
	delLogWithCount(c_list.log_list)

	local d = Tools.encode("ChatLogList", c_list)

	db:set(cid, d)
end

function ChatLoger.getLogList(cid)

	local c_list = rawget(list_map, cid)
	if c_list and rawget(c_list, "log_list") then
		return c_list.log_list
	end
	return nil
end

return ChatLoger