
local kc = require "kyotocabinet"
local db = kc.DB:new()-- + kc.DB.ONOLOCK

local data_list = {}

local SlaveCache = {}

if not db:open("Slave.kch", kc.DB.OWRITER + kc.DB.OCREATE) then

	error("Slave.kch open err")
else

	db:iterate(
		function(k,v)
			local data = Tools.decode("SlaveData", v)

			data_list[data.user_name] = data
		end,
	false)
end

local function _freeSlave(slave_data, master_data)

	local has = false
	if Tools.isEmpty(master_data.slave_list) == true then

		return false
	end
	for i,v in ipairs(master_data.slave_list) do
		if v == slave_data.user_name then
			table.remove(master_data.slave_list, i)
			has = true
			break
		end
	end

	slave_data.master = nil

	if has == false then
		return false
	end
	SlaveCache.set( master_data )

	SlaveCache.resetData(slave_data)
	
	SlaveCache.set( slave_data )

	return true
end

function SlaveCache.createBriefInfo( user_name )

	local data = SlaveCache.get(user_name)

	local other_user_info = UserInfoCache.get(user_name)
	if other_user_info then
		local master_nickname
		if data.master ~= nil and data.master ~= "" then
			master_nickname = UserInfoCache.get(data.master).nickname
		end
		local info = {
			user_name = user_name,
			nickname = other_user_info.nickname,
			icon_id = other_user_info.icon_id,
			level = other_user_info.level,
			power = other_user_info.power,
			slave_count = (data.slave_list == nil and 0) or #data.slave_list,
			state = data.state,
			group_nickname = other_user_info.group_nickname,
			master = data.master,
			master_nickname = master_nickname,
		}
		return info
	end
	return nil
end

function SlaveCache.resetData( data )

	data.state = 1
	data.work_cd_start_time = 0
	data.fawn_on_cd_start_time = 0
	data.help_cd_start_time = 0
	data.revolt_cd_start_time = 0
	data.slaved_start_time = 0
	data.show_start_time = 0
	data.watch_list = nil
	show_watch_num = 0
	data.exp_pool = 0
	data.res_pool = {0,0,0,0,}
	data.res_sub_cache = {0,0,0,0,}
	data.master = nil
	data.slave_list = nil
	data.get_res_start_time = 0

	return data
end


function SlaveCache.get(user_name)

	local data = data_list[user_name]
	if data == nil then
		data = {
			user_name = user_name,
			state = 1,
			work_cd_start_time = 0,
			fawn_on_cd_start_time = 0,
			help_cd_start_time = 0,
			revolt_cd_start_time = 0,
			slaved_start_time = 0,
			show_start_time = 0,
			show_watch_num = 0,
			get_res_start_time = 0,
			get_slaves_times = CONF.PARAM.get("slave_enslave_num").PARAM,
			buy_get_slaves_times = 0,
			get_save_times = CONF.PARAM.get("slave_save_num").PARAM,
			buy_get_save_times = 0,
			exp_pool = 0,
			res_pool = {0,0,0,0,},
			res_sub_cache = {0,0,0,0,},
			slave_list = nil,
			enemy_list = nil,
			help_list = nil,
			watch_list = nil,
			note = nil,
		}
		SlaveCache.set(data)
	end

	local cur_time = os.time()

	if data.master ~= nil and data.master ~= "" then
		
		local change = false
		if data.work_cd_start_time > 0 and cur_time > data.work_cd_start_time + CONF.PARAM.get("slave_work_cd").PARAM then
			data.work_cd_start_time = 0
			change = true
		end

		if data.fawn_on_cd_start_time > 0 and cur_time > data.fawn_on_cd_start_time + CONF.PARAM.get("slave_fawn_on_cd").PARAM then
			data.fawn_on_cd_start_time = 0
			change = true
		end

		if data.help_cd_start_time > 0 and cur_time > data.help_cd_start_time + CONF.PARAM.get("slave_help_cd").PARAM then
			data.help_cd_start_time = 0
			change = true
		end

		if data.revolt_cd_start_time > 0 and cur_time > data.revolt_cd_start_time + CONF.PARAM.get("slave_revolt_cd").PARAM then
			data.revolt_cd_start_time = 0
			change = true
		end

		if data.get_res_start_time > 0 and cur_time > data.get_res_start_time + CONF.PARAM.get("slave_get_res_cd").PARAM then
			data.get_res_start_time = 0
			change = true
		end

		if data.state == 2 and cur_time > data.show_start_time + CONF.PARAM.get("slave_show_time").PARAM then
			data.state = 1
			data.show_start_time = 0
			data.show_watch_num = 0
			data.watch_list = nil
			change = true
		end

		if change == true then
			SlaveCache.set(data)
		end
		
		if cur_time > data.slaved_start_time + CONF.PARAM.get("slave_free_time").PARAM then
			data = data_list[user_name]
			_freeSlave(data, data_list[data.master])
		end

	elseif Tools.isEmpty(data.slave_list) == false then

		for i,v in ipairs(data.slave_list) do
			
			local slave_data = data_list[v]
			if slave_data.master ~= nil and slave_data.master ~= "" then

				SlaveCache.get(v, user_name)
			end
		end
	end

	return data
end

function SlaveCache.set( data )
	if Tools.isEmpty(data) == true or data.user_name == "" or data.user_name == nil then
		return false
	end
	data_list[data.user_name] = data

	local buff = Tools.encode("SlaveData", data)

	-- print("set:", data.user_name)
	-- print("{")
	-- print("	slave_list:")
	-- Tools.print_t(data.slave_list)
	-- print("	master:",data.master)
	-- print("}")
	return db:set(data.user_name, buff)
end

function SlaveCache.isMySlave(user_name, slave_name )
	local data = SlaveCache.get(user_name)
	if Tools.isEmpty(data.slave_list) == true then
		return false
	end
	for i,v in ipairs(data.slave_list) do
		if slave_name == v then
			return true, i
		end
	end
	return false
end

function SlaveCache.slaveSetRes(slave_name, type, value)	--0:经验 1.金币 2.金属 3.晶体 4.气体
	local data = SlaveCache.get(slave_name)
	if data.master == nil or data.master == "" then
		return 0
	end

	local master_other_info = UserInfoCache.get(data.master) 
	if master_other_info == nil then
		return 0
	end

	local slave_other_info = UserInfoCache.get(slave_name) 
	if slave_other_info == nil then
		return 0
	end

	local sub_value = 0
	if type ~= 0 then
		sub_value = data.res_sub_cache[type]
	end
	 
	
	value = value - sub_value
	if value < 0 then
		value = 0

		data.res_sub_cache[type] = data.res_sub_cache[type] - value
	else
		data.res_sub_cache[type] = 0
	end

	local get_num = Tools.calSlaveGetRes(type, value, master_other_info.level, slave_other_info.level)

	if get_num > value or get_num <= 0 then
		SlaveCache.set( data )
		return 0
	end
	local levelConf = CONF.PLAYERLEVEL.get(master_other_info.level)
	local limit = (type == 0 and levelConf.SLAVE_EXP) or levelConf["SLAVE_RESOURCE_"..type]
	local pool = (type == 0 and data.exp_pool ) or data.res_pool[type]
	
	if get_num > (limit - pool) then
		get_num = limit - pool
	end
	
	if type == 0 then
		data.exp_pool = data.exp_pool + get_num
	else
		data.res_pool[type] = data.res_pool[type] + get_num
	end

	SlaveCache.set( data )

	return get_num
end

function SlaveCache.masterGetRes( isJustCal, slave_name, type, slave_new_value)

	local data = SlaveCache.get(slave_name)
	if data.master == nil  or data.master == "" then
		return 0
	end

	local master_other_info = UserInfoCache.get(data.master) 
	if master_other_info == nil then
		return 0
	end

	local slave_other_info = UserInfoCache.get(slave_name) 
	if slave_other_info == nil then
		return 0
	end

	local value
	if type == 0 then
		value = data.exp_pool
	else
		value = data.res_pool[type]
	end

	local addtion_value = 0
	if slave_new_value then
		addtion_value = Tools.calSlaveGetRes(type, slave_new_value, master_other_info.level, slave_other_info.level)
		value = value + addtion_value
	end
	
	if value < 0 then
		value = 0
	end

	local levelConf = CONF.PLAYERLEVEL.get(master_other_info.level)
	local limit = (type == 0 and levelConf.SLAVE_EXP) or levelConf["SLAVE_RESOURCE_"..type]
	local pool = (type == 0 and data.exp_pool ) or data.res_pool[type]

	local slave_out_value = 0
	if value > limit then

		slave_out_value  = math.min(value - limit, addtion_value)
		value = limit
	end

	
	if isJustCal == true then
		return value
	else
		if type > 0 then
			data.res_sub_cache[type] = addtion_value - slave_out_value
		end

		local ret = value
		if type == 0 then
			data.exp_pool = 0
		else
			data.res_pool[type] = 0
		end
		data.get_res_start_time = os.time()

		SlaveCache.set( data )
		return ret
	end
end


function SlaveCache.addEnemy( slave_name, enemy_name )

	local slave_data = SlaveCache.get(slave_name)

	if Tools.isEmpty(slave_data.enemy_list) == false then
		for i,v in ipairs(slave_data.enemy_list) do
			if v == enemy_name then
				return false
			end
		end

		table.insert(slave_data.enemy_list, enemy_name)
	else

		slave_data.enemy_list = {enemy_name}
	end

	SlaveCache.set(slave_data)

	return true
end

function SlaveCache.removeEnemy( slave_name, enemy_name )

	local slave_data = SlaveCache.get(slave_name)
	if Tools.isEmpty(slave_data.enemy_list) == false then
		for i,v in ipairs(slave_data.enemy_list) do
			if v == enemy_name then
				table.remove(slave_data.enemy_list, i)
				SlaveCache.set(slave_data)
				return true
			end
		end
	end
	return false
end



function SlaveCache.freeSlave(slave_name, out_update_list)

	local slave_data = SlaveCache.get(slave_name)

	if slave_data.master == nil or slave_data.master == "" then

		return false
	end

	local master_data = SlaveCache.get(slave_data.master)

	local result = _freeSlave(slave_data, master_data)

	if result == true and out_update_list ~= nil then
		out_update_list[slave_name] = true
		out_update_list[master_data.user_name] = true
	end
	return result
end

function SlaveCache.catchSlave(master_name, slave_name, out_update_list)

	local slave_data = SlaveCache.get(slave_name)
	local master_data = SlaveCache.get(master_name)

	if slave_data.state == 2 then
		return false
	end
	
	if master_data.master ~= nil and master_data.master ~= "" then
		return false
	end

	if slave_name == master_name then
		return false
	end

	if Tools.isEmpty(master_data.slave_list) == false then
		for i,v in ipairs(master_data.slave_list) do
			if v == slave_name then
				return false
			end
		end
	end

	if slave_data.master and slave_data.master ~= "" then
		SlaveCache.freeSlave(slave_name, out_update_list)
	end

	if Tools.isEmpty(slave_data.slave_list) == false then
		for i,v in ipairs(slave_data.slave_list) do
			SlaveCache.freeSlave(v, out_update_list)
		end
	end

	if Tools.isEmpty(master_data.slave_list) == true then
		master_data.slave_list = {slave_name,}
	else
		table.insert(master_data.slave_list, slave_name)
	end
	SlaveCache.set(master_data)

	SlaveCache.resetData(slave_data)
	slave_data.master = master_name
	slave_data.slaved_start_time = os.time()
	SlaveCache.set(slave_data)

	if out_update_list ~= nil then
		out_update_list[master_name] = true
		out_update_list[slave_name] = true
	end

	return true
end

function SlaveCache.getReward(type) --1.讨好 2.工作 3.围观 4.救人
	local confReward = CONF.SLAVE_AWARD.get(type)

	local limit = 0
	for i=1,4 do
		if confReward["ITEM_ID"..i] == nil then
			break
		end
		limit  = i
	end

	local index = math.random(1, limit)
	local num = math.random(confReward["QUANTITY"..index][1], confReward["QUANTITY"..index][2])

	return confReward["ITEM_ID"..index], num
end

function SlaveCache.recordNote(user_name, type, param_list)

	local data = SlaveCache.get(user_name)
	local has_param = false
	for i=CONF.ESlaveNoteKey.kMax,1, -1 do
		if param_list[i] == nil then
			if has_param == true then
				param_list[i] = "nil"
			end
		else
			has_param = true
		end
	end

	local temp = {
		type = type,
		param_list = param_list,
		text_index = math.random(1, CONF.SLAVE_NOTE.get(CONF.ESlaveNoteType[type]).TEXT_COUNT),
	}

	if Tools.isEmpty(data.note) == false then
		if #data.note >= 30 then
			table.remove(data.note, 1)
		end
		table.insert(data.note, temp)
	else
		data.note = {temp}
	end

	SlaveCache.set(data)

	return temp
end

function SlaveCache.sendHelp(helper, need_helper)
	local data = SlaveCache.get(helper)

	if Tools.isEmpty(data.help_list) == false then
		
		for i,v in ipairs(data.help_list) do
			if v == need_helper then
				return false
			end
		end

		if #data.help_list >= 12 then
			table.remove(data.help_list, 1)
		end

		table.insert(data.help_list, need_helper)
	else
		data.help_list = {need_helper}
	end
	
	SlaveCache.set(data)
	return true
end

return SlaveCache