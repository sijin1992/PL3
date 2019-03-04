__G__TRACKBACK__ = function(msg)
    local msg = debug.traceback(msg, 3)
    LOG_ERROR(msg)
    return msg
end

local function LoadProtoBuf()
	---- 注册所有的protobuf
	local pb = require "protobuf"
	local proto_path = "../../../bin/logic/main_logic/lua/protobuf/"
	--local proto_path = "./lua/protobuf/"
	print ("regist proto begin.")
	pb.register_file(proto_path.."cmd_define.pb")
	pb.register_file(proto_path.."config.pb")
	pb.register_file(proto_path.."AirShip.pb")
	pb.register_file(proto_path.."Item.pb")
	pb.register_file(proto_path.."Stage.pb")
	pb.register_file(proto_path.."OtherInfo.pb")
	pb.register_file(proto_path.."PveInfo.pb")
	pb.register_file(proto_path.."PvpInfo.pb")
	pb.register_file(proto_path.."Planet.pb")
	pb.register_file(proto_path.."Mail.pb")
	pb.register_file(proto_path.."FlagShip.pb")
	pb.register_file(proto_path.."Weapon.pb")
	pb.register_file(proto_path.."Equip.pb")
	pb.register_file(proto_path.."Group.pb")
	pb.register_file(proto_path.."Home.pb")
	pb.register_file(proto_path.."Building.pb")
	pb.register_file(proto_path.."Trial.pb")
	pb.register_file(proto_path.."Activity.pb")
	pb.register_file(proto_path.."UserInfo.pb")
	pb.register_file(proto_path.."Slave.pb")
	pb.register_file(proto_path.."UserSync.pb")
	pb.register_file(proto_path.."CmdLogin.pb")
	pb.register_file(proto_path.."CmdWeapon.pb")
	pb.register_file(proto_path.."CmdPve.pb")
	pb.register_file(proto_path.."CmdPvp.pb")
	pb.register_file(proto_path.."CmdUser.pb")
	pb.register_file(proto_path.."CmdSync.pb")
	pb.register_file(proto_path.."CmdEquip.pb")
	pb.register_file(proto_path.."CmdGroup.pb")
	pb.register_file(proto_path.."CmdHome.pb")
	pb.register_file(proto_path.."CmdBuilding.pb")
	pb.register_file(proto_path.."CmdTrial.pb")
	pb.register_file(proto_path.."CmdArena.pb")
	pb.register_file(proto_path.."gm_cmd.pb")
	pb.register_file(proto_path.."inner_cmd.pb")
	pb.register_file(proto_path.."CmdMail.pb")
	pb.register_file(proto_path.."CmdPlanet.pb")
	pb.register_file(proto_path.."CmdSlave.pb")
	pb.register_file(proto_path.."CmdActivity.pb")
	
	print ("regist proto complete.")
end

util = require "util.c"
require "svr_conf"--服务器特定的信息
require "star_main_define"
if server_platform == 1 then
    require "Lang_en"
else
    require "Lang_cn"
end

--加载log模块
require "log_module"

---- 加载所有配置文件
--require "all_config"

LoadProtoBuf()
CONF = require "configuration"
CONF:load "../../../bin/logic/main_logic/lua/config"
Tools = require "Tools"
CONF:debug()
CoreItem = require "CoreItem"
CoreMail = require "CoreMail"
CoreUser = require "CoreUser"
CoreShip= require "CoreShip"

math.randomseed(os.time())

---- 常用模块
function clonetab(src)
	local dest = {}
	for k,v in pairs(src) do
		if type(v) == "table" then
			dest[k] = clonetab(v)
		else
			dest[k] = v
		end
	end
	return dest
end

function clonetab_real(to, src)
	for k,v in pairs(src) do
		if type(v) == "table" then
			local t = {}
			clonetab_real(t, v)
			to[k] = t
		else
			to[k] = v
		end
	end
end

function printspace(len)
	if not len or len == 0 then
		return
	end
	io.write(string.rep("\t", len))
end

function printtab(src, name, depth)
	if not depth then 
		depth = 0
		print("\n")
	end
	if name then 
		print(name, src, "--begin.\n")
	end
	if type(src) ~= "table" then
		return
	end
	for k,v in pairs(src) do
		printspace(depth)
		print(k,"->", v)
		if type(v) == "table" then
			printtab(v,nil,depth+1)
		end
	end
	if name then 
		print(name, src, "--end.\n")
	end
end

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
			tt[#tt+1] = string.format("%s%s->%s", s, k, tostring(v))
			if type(v) == "table" then
				tt[#tt+1] = print_t(v, depth+1)
			end
		end	
	end
	return table.concat(tt, "\n")
end

function printInfo( str )
	--print(str)
end

function string.split(str, delimiter)
	if str == nil or str == '' or delimiter == nil then
		return nil
	end
	local result = {}
	for match in (str..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
	return result
end

--固定格式 2015-05-06 11:10:10
function string.time(str)
	local tab = { year=1970, month=1, day=1, hour=0, min=0, sec=0, isdst=false }
	repeat
		if str == nil or str == '' then
			break
		end
		local parts = string.split(str, ' ')
		--printtab(parts, 'parts')
		if parts == nil or parts[1] == nil then
			break
		end
		--year month day
		pdate = string.split(parts[1], '-')
		--printtab(pdate, 'pdate')
		if pdate == nil or #pdate < 3 then
			break
		end
		tab.year = pdate[1]
		tab.month = pdate[2]
		tab.day = pdate[3]
		--hour min sec
		ptime = string.split(parts[2], ':')
		--printtab(ptime, 'ptime')
		if ptime == nil or #ptime < 1 then
			break
		end
		tab.hour = ptime[1]
		if #ptime >= 2 then tab.min = ptime[2] end
		if #ptime >= 3 then tab.sec = ptime[3] end
	until true;
	--printtab(tab, 'TimeTab')
	local time = os.time(tab)
	--print('RetTime:', time)
	return time
end

local setmetatableindex_
setmetatableindex_ = function(t, index)
	if type(t) == "userdata" then
		assert(false, "class setmetatableindex_ can't userdata")
	else
		local mt = getmetatable(t)
		if not mt then mt = {} end
		if not mt.__index then
			mt.__index = index
			setmetatable(t, mt)
		elseif mt.__index ~= index then
			setmetatableindex_(mt, index)
		end
	end
end
setmetatableindex = setmetatableindex_

function class(classname, ...)
	local cls = {__cname = classname}

	local supers = {...}
	for _, super in ipairs(supers) do
		local superType = type(super)
		assert(superType == "nil" or superType == "table" or superType == "function",
		string.format("class() - create class \"%s\" with invalid super class type \"%s\"",
		classname, superType))

		if superType == "function" then
			assert(cls.__create == nil,
			string.format("class() - create class \"%s\" with more than one creating function",
			classname));
			-- if super is function, set it to __create
			cls.__create = super
		elseif superType == "table" then
			if super[".isclass"] then
				-- super is native class
				assert(cls.__create == nil,
				string.format("class() - create class \"%s\" with more than one creating function or native class",
				classname));
				cls.__create = function() return super:create() end
			else
				-- super is pure lua class
				cls.__supers = cls.__supers or {}
				cls.__supers[#cls.__supers + 1] = super
				if not cls.super then
					-- set first super pure lua class as class.super
					cls.super = super
				end
			end
		else
			error(string.format("class() - create class \"%s\" with invalid super type",
			classname), 0)
		end
	end

	cls.__index = cls
	if not cls.__supers or #cls.__supers == 1 then
		setmetatable(cls, {__index = cls.super})
	else
		setmetatable(cls, {__index = function(_, key)
			local supers = cls.__supers
			for i = 1, #supers do
				local super = supers[i]
				if super[key] then return super[key] end
			end
		end})
	end

	if not cls.ctor then
		-- add default constructor
		cls.ctor = function() end
	end
	cls.new = function(...)
	local instance
	if cls.__create then
		instance = cls.__create(...)
	else
		instance = {}
	end
	setmetatableindex(instance, cls)
	instance.class = cls
		instance:ctor(...)
		return instance
	end
	cls.create = function(_, ...)
		return cls.new(...)
	end

	return cls
end

function get_reward_list(reward_arr)
	local ret_reward_list = {};
	local k = 1
	while reward_arr[k] do
		table.insert(ret_reward_list, {tonumber(reward_arr[k]), tonumber(reward_arr[k + 1])})
		k = k + 2
	end
	return ret_reward_list
end

function get_reward_item_list(reward_arr)
	local ret_reward_list = {};
	local k = 1
	while reward_arr[k] do
		table.insert(ret_reward_list, {id=tonumber(reward_arr[k]), num=tonumber(reward_arr[k + 1])})
		k = k + 2
	end
	return ret_reward_list
end


function getTimeStampFrom(t)
	if t < 2017000000 then
		return t
	end
	local y = math.floor(t / 1000000)
	local m = math.floor((t % 1000000) / 10000)
	local d = math.floor((t % 10000) / 100)
	local h = math.floor(t % 100)
	local dt = {year = y, month = m, day = d, hour = h}
	return os.time(dt)
end

function get_dayid_from(time, hour, minute)
	local t = time --+ 28800 --+8时区
	local d = math.floor(t / 86400)
	local h = math.floor((t % 86400) / 3600)
	local m = nil
	if minute then
		m = math.floor((t % 3600) / 60)
	end
	
	local dayid = d
	if hour then
		if h < hour then
			dayid = d - 1
		elseif minute and h == hour then
			if m < minute then dayid = d - 1 end
		end
	end
	return dayid
end

function get_dayid_from_str(timestr, hour)
	local time = string.time(timestr)
	--print('time:', time)
	return get_dayid_from(time, hour)
end

function get_dayid(timestr)
	return get_dayid_from_str(timestr)
end

function xxx_feature(cmd, ...)
	local _module = reg[cmd]
	return _module[1](...)
end

function xxx_do_logic(cmd, ...)
	local _module = reg[cmd]
	return _module[2](...)
end

SyncUserCache = require "SyncUserCache"
GroupCache = require "GroupCache"
TrialCache = require "TrialCache"
ArenaCache = require "ArenaCache"
UserInfoCache = require "UserInfoCache"

VideoCache = require "VideoCache"
PlanetStatusMachine = require "PlanetStatusMachine"
PlanetCache = require "PlanetCache"

SlaveCache = require "SlaveCache"

nick_name_ctrl = require "nick_name_ctrl"

RedoList = require "RedoList"

GolbalActivity = require "GolbalActivity"

-- if server_platform == 1 then
--     robot_list30 = require "robot_tw"
-- else
--     robot_list30 = require "robot"
-- end

--pve2_module = require "pve2_power"


--notify_sys = require "notify"
svr_info = require "svr_info"



function get_rank_by_name(name)
	return rank.get_idx_by_name(name)
end

require "cmd_pve"
require "cmd_pvp"
require "CmdBase"
require "gm"
require "CmdWeapon"
require "CmdEquip"
require "CmdGroup"
require "CmdHome"
require "CmdBuilding"
require "CmdTechnology"
require "CmdTrial"
require "CmdArena"
require "CmdMail"
require "CmdPlanet"
require "CmdActivity"
require "CmdSlave"
require "reg_cmd"
require "special_logic"
require "special_api"

--下面这个文件不一定存在
local t = loadfile ("svr_data.lua")
if t then
	t()
end

function sendBroadcast(user_name, sender_name, board_chat_msg, type)
	if type == nil then
		type = 1
	end
	--向世界频道推送
	local chat_msg = {
		msg = {board_chat_msg},
		channel = 0,
		type = type,
		sender = {
			nickname = sender,
		},
	}
	local chat_msg_buff = Tools.encode("ChatMsg_t", chat_msg)
	activeSendMessage(user_name, 0x1521, chat_msg_buff)
end