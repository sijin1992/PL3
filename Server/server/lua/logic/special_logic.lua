--[[
local core_drop = require "core_drop"
local core_send_mail = require "core_send_mail"
local core_task = require "core_task"
local pve = require "pve"
local worldboss = require "worldboss"
local rank = rank
local core_power = require "core_calc_power"

math.randomseed(os.time())

local DATA_VER_20150305 = 100
local DATA_VER_20150316 = 101
local DATA_VER_20150321 = 110
local DATA_VER_20150331 = 111--修正任务消失的问题
local DATA_VER_20150415 = 112--修正80级后经验表修改的问题
local DATA_VER_20150427 = 113
local DATA_VER_20150513 = 114--公会挑战从0点重置改成5点重置，所有人强制重置一次
local DATA_VER_20150523 = 115--充值返利活动因为bug，0点没有正确清除充值记录，补清
local DATA_VER_20150612 = 116
local DATA_VER_20150706 = 117
local DATA_VER_20150717 = 118--刷新侠客背包
local DATA_VER_20150803 = 119 --初始化宝藏守护阵容为一个主将
local DATA_VER_20150811 = 121
local DATA_VER_20150907 = 122
local DATA_VER_20150929 = 123
local DATA_VER_20150929_1 = 124
local DATA_VERSION = DATA_VER_20150929_1

local time_checking = require "time_checking"
local core_user = require "core_user_funcs"
local core_money = require "core_money"
local update_at_0am = time_checking.update_at_0am
local update_at_5am = time_checking.update_at_5am
local update_at_12am = time_checking.update_at_12am
local update_at_9pm = time_checking.update_at_9pm
local get_dayid_from = time_checking.get_dayid_from
local update_tili_per_6min = time_checking.update_tili_per_6min
local special_stage = time_checking.special_stage

local osdate = os.date
local ostime = os.time
--]]
local timeChecker = require "TimeChecker"
local osdate = os.date
local ostime = os.time

local function check_data_valid(main_data, item_list, mail_list)
	local valid = true
	for k,v in ipairs(item_list) do
		if v.num < 0 then
			valid = false
			break
		end
	end
	return valid
end

local function rebuild_data(main_data, item_list, mail_list)
	main_data.lead = {
		sex = main_data.lead.sex,
		star = 3,
		level = 1,
		exp = 0,
		equip_list = {
			{star = 0, level = 1},
			{star = 0, level = 0},
			{star = 0, level = 0},
			{star = 0, level = 0},
			{star = 0, level = 0},
			{star = 0, level = 0},
			{star = 0, level = 0},
			{star = 0, level = 0}
		},
		skill = {id = Character_conf[10020000].SKILL_ID,level = 1},
		evolution = 0,
		pve2_sub_hp = 0
	}
	main_data.zhenxing = {
		zhanwei_list = {
			{status = 0},
			{status = 1, power = 65},
			{status = 0},
			{status = 0},
			{status = 0},
			{status = 0},
			{status = 0},
		},
	}
end

local isblock = require "block"
local Bit = require "Bit"

function update_user(user_name, user_info_buff, ship_list_buff, item_list_buff, mail_list_buff)
	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"
	local mailList = require "MailList"

	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	itemList:new(item_list_buff)
	mailList:new(mail_list_buff)

	local user_info = userInfo:getUserInfo()

	local mail_list = mailList:getMailList()
	local item_list = itemList:getItemList()

	shipList:setUserInfo(user_info)

	--发现解散公会 重置group_data
	local group_data = rawget(user_info, "group_data")
	if group_data.groupid ~= "" then
		if GroupCache.isDisband(group_data.groupid) then
			local groupMain = require "UserGroup"
			group_data = groupMain:resetGroupData(user_info)
			rawset(user_info, "group_data", group_data)
		end
	end

	local time = ostime()

	for i=1,CONF.EBuilding.count do
		userInfo:getBuildingInfo(i)
	end

	if user_info.ship_energy_time_lock ~= nil and user_info.ship_energy_time_lock > 0 and user_info.ship_energy_end_time <= time then
		user_info.ship_energy_time_lock = -1
	end


	local redo = RedoList.get(user_info.user_name)
	if redo then
		--重发之前错误的充值等请求
		if redo.recharge_list then
			for k,v in ipairs(redo.recharge_list) do
				core_recharge(userInfo, itemList, v.money, v.item_id, v.fake)
			end
		end
		--获取邮件
		if redo.mail_list then
			for k,mail in ipairs(redo.mail_list) do
				
				CoreMail.recvMail(mail, mail_list)
			end
		end
		RedoList.clear(user_info.user_name)
	end

	local dayid = timeChecker.get_dayid_from(time)
	timeChecker.update_at_0am(userInfo, dayid)

	local other_user_info = UserInfoCache.get(user_info.user_name)
	local changeLevel = false
	for i=1,CONF.EBuilding.count do
		if other_user_info.building_level_list[i] == nil then
			other_user_info.building_level_list[i] = 1
			changeLevel = true
		end
	end
	if other_user_info.last_act == nil then
		other_user_info.last_act = time
	end
	Tools._print("loop user time", other_user_info.nickname, time - other_user_info.last_act)
	if changeLevel or time - other_user_info.last_act > 300 then
		UserInfoCache.set(user_info.user_name, other_user_info)
	end

	--删除无效的活动数据
	GolbalActivity.updateActivityData(time, user_info)

	mailList:limitMailCount(user_info, item_list)
	
	user_info_buff = userInfo:getUserBuff()

	ship_list_buff = shipList:getShipBuff()

	item_list_buff = itemList:getItemBuff()

	mail_list_buff = mailList:getMailBuff()

	local ret = 1	
	return ret, user_info_buff, ship_list_buff, item_list_buff, mail_list_buff
end

function update_when_login(user_name, user_data_buf, knight_buf, item_buf, mail_buf, rank_idx)
	local pb = require "protobuf"
	local user_info = pb.decode("UserInfo", user_data_buf)
	local knight_list = pb.decode("KnightList", knight_buf)
	local item_list = pb.decode("ItemList", item_buf)
	local mail_list = pb.decode("MailList", mail_buf)


	if rawget(knight_list, "knight_list") == nil then
		knight_list = {knight_list = {}}
	end
	if(rawget(item_list, "item_list")) == nil then
		item_list.item_list = {}
	end
	if(rawget(mail_list, "mail_list")) == nil then
		mail_list.mail_list = {}
	end

	local ret = false
	local time = ostime()
	if not rawget(user_info, "user_name") or user_name ~= user_info.user_name then
		user_info.user_name = user_name
		ret = true
	end

	if isblock then
		if isblock(user_name) then
			error(user_name.." block")
		end
	end
	rawset(user_info, "blocked", nil)

	local last_0am_day1 = user_info.timestamp.last_0am_day1
	if last_0am_day1 == 0 then 
		user_info.timestamp.last_0am_day1 = user_info.timestamp.last_0am_day 
	end

	--合服相关逻辑
	local hfflag = user_info.ext_data.hf
	if last_hf and last_hf ~= hfflag then
		-- 合服了，要清除gmail和pvp rcd
		user_info.ext_data.hf = last_hf
		user_info.ext_data.gmail = 0
		local t = user_info.PVP.reputation
		user_info.PVP.pvp_rcd_list = {}
		user_info.wboss = nil
		user_info.PVP.today_count = 0
		user_info.PVP.today_reset_count = 0
		t = user_info.huodong.cangjian.last_sub
		rawset(user_info.huodong, "cangjian", nil)
		t = user_info.PVE.pve2.reset_num
		user_info.PVE.pve2.reset_num = 0

		local t = user_info.huodong.caishendao
		user_info.huodong.caishendao = 1
		user_info.huodong.chongzhi = nil
		LOG_INFO(string.format("user:%s hf:%d from:%d", user_name, last_hf, hfflag))
	end
	--检查数据版本
	local group = rawget(user_info, "group_data")
	if group then
		local t = group.groupid
		if not group_cache.get_group(t) then
			group.groupid = ""
		end
	end
	--print("user_info.data_version", user_info.data_version)
	if user_info.data_version < DATA_VERSION then
		local main_data = user_info --alias user_info
		if user_info.data_version < DATA_VER_20150321 then
			local t = user_info.huodong.caishendao
			rawset(user_info.huodong, "day7", nil)
			rawset(user_info.huodong, "level_gift", nil)
			t = user_info.timestamp.huodong1_time
			user_info.timestamp.huodong1_time = os.time()
			--这一版新增了一些24-28关卡
			local t = user_info.PVE.fortress_list[1].id
			t = user_info.PVE.jingying[1].id
			local lent = rawlen(user_info.PVE.fortress_list)
			if lent == 23 and user_info.PVE.fortress_list[23].stage_list[10].difficulty_list[1].pass_num > 0 then
			   -- 玩家已通关，这一版要加新章节
			   local new_fortress,jingying_fortress = pve.create_new_fortress(24)
				if new_fortress then
					table.insert(user_info.PVE.fortress_list, new_fortress)
					table.insert(user_info.PVE.jingying, jingying_fortress)
				end
			end
			--藏剑山庄数据
			local cangjian_data = global_huodong.get_huodong(user_info,"cangjian")
			if cangjian_data then
				local begin_t = cangjian_data.begin_time
				local end_t = cangjian_data.end_time
				local now_t = os.time()
				local thuodong = main_data.huodong
				local next_time = thuodong.cangjian.next_time
				local cangjian = rawget(thuodong, "cangjian")
				--在活动里面，且没到自动刷新时间之前，刷新一下
				--print("cangjian", cangjian, "next_time", next_time, now_t)
				if cangjian and cangjian.sub_id == cangjian_data.sub_id and next_time > now_t then
					huodong.cangjian_refresh(cangjian)
					LOG_INFO(string.format("user:%s cangjian data refreshed, data-version:%d", user_name, user_info.data_version))
				end
			end
			--补偿邮件
			local bc_list = {}
			local t_list = {
				{70010001, 190050018,20},
				{70020002, 190050018,20},
				{70030003, 190050034,20},
				{70040004, 190050034,20},
				{70050005, 190050034,40},
				{70060006, 190050005,20},
				{70070007, 190050005,20},
				{70080008, 190050005,40},
				{70090009, 190050003,15},
				{70100010, 190050003,15},
				{70110011, 190050003,15},
				{70120012, 190050041,5},
				{70130013, 190050041,5},
				{70140014, 190050041,5},
				{70150015, 190040019,15},
				{70160016, 190040019,15},
				{70170017, 190040019,15},
				{70180018, 190040010,15},
				{70190019, 190040010,15},
				{70200020, 190040010,15},
				{70210021, 190040037,15},
				{70220022, 190040037,15},
				{70230023, 190040037,15},
			}
			for k,v in ipairs(user_info.PVE.jingying) do
				for k1,v1 in ipairs(t_list) do
					if v1[1] == v.id then
						if v.reward == 1 then
							local find = false
							for k2,v2 in ipairs(bc_list) do
								if v2.id == v1[2] then
									v2.num = v2.num + v1[3]
									find = true
									break
								end
							end
							if not find then
								table.insert(bc_list, {id = v1[2], num = v1[3]})
							end
						break
						end
					end
				end
			end
			if rawlen(bc_list) > 0 then
				local t_mail = {
					type = 10,
					from = lang.gl_yunying,
					subject = lang.bc20150321_sub,
					message = lang.bc20150321_mail,
					item_list = bc_list,
					stamp = 0,
					guid = 0,
					expiry_stamp = 0
				}
			core_send_mail.send_mail(user_info, mail_list.mail_list, t_mail)
			end
		end
		if user_info.data_version == DATA_VER_20150321 then
			local t = user_info.task_list.task_list[1]
			local find1 = false
			local find2 = false
			local task_list = rawget(user_info.task_list, "task_list")
			if task_list then
				for k,v in ipairs(task_list) do
					if v.id >= 292001 and v.id < 293000 then find1 = true end
					if v.id >= 293001 then find2 = true end
				end
			else
				task_list = {}
				rawset(user_info.task_list, "task_list", task_list)
			end
			if user_info.lead.level < 10 then find2 = true end
			if not find1 then
				local new_status = 1
				t = user_info.PVE.fortress_list[1].id
				local lent = rawlen(user_info.PVE.fortress_list)
				if lent >= 24 and user_info.PVE.fortress_list[24].stage_list[1].difficulty_list[1].pass_num > 0 then
				   -- 玩家已通关，这一版要加新章节
				   new_status = 2
				end
				table.insert(task_list, {id = 292098, status = new_status})
			end
			if not find2 then
				local new_status = 1
				t = user_info.PVE.jingying[1].id
				local lent = rawlen(user_info.PVE.jingying)
				if lent >= 24 and user_info.PVE.jingying[24].stage_list[1].pass_num > 0 then
				   -- 玩家已通关，这一版要加新章节
				   new_status = 2
				end
				table.insert(task_list, {id = 293067, status = new_status})
			end


		end
		if user_info.data_version < DATA_VER_20150415 then
			local tab = {
				100,0,0,1300,4500,
				9100,15100,22500,31300,41500,
				53100,66100,80500,96300,113500,
				132100,152100,173500,196300,220500
			}
			if user_info.lead.level >= 80 then
				local idx = user_info.lead.level - 79
				if idx <= 20 then
					user_info.lead.exp = user_info.lead.exp + tab[idx]
				end
			end
		end
		if user_info.data_version < DATA_VER_20150427 then
			--这一版新增了一些24-28关卡
			local t = user_info.PVE.fortress_list[1].id
			t = user_info.PVE.jingying[1].id
			local lent = rawlen(user_info.PVE.fortress_list)
			if lent == 28 and user_info.PVE.fortress_list[28].stage_list[10].difficulty_list[1].pass_num > 0 then
			   -- 玩家已通关，这一版要加新章节
			   local new_fortress,jingying_fortress = pve.create_new_fortress(29)
				if new_fortress then
					table.insert(user_info.PVE.fortress_list, new_fortress)
					table.insert(user_info.PVE.jingying, jingying_fortress)
				end
			end
			--补偿邮件
			local bc_list = {}
			local t_list = {
				{70270027, 190050011,5},
				{70280028, 190050011,5},
			}
			for k,v in ipairs(user_info.PVE.jingying) do
				for k1,v1 in ipairs(t_list) do
					if v1[1] == v.id then
						if v.reward == 1 then
							local find = false
							for k2,v2 in ipairs(bc_list) do
								if v2.id == v1[2] then
									v2.num = v2.num + v1[3]
									find = true
									break
								end
							end
							if not find then
								table.insert(bc_list, {id = v1[2], num = v1[3]})
							end
						break
						end
					end
				end
			end
			if rawlen(bc_list) > 0 then
				local t_mail = {
					type = 10,
					from = lang.gl_yunying,
					subject = lang.bc20150321_sub,
					message = lang.bc20150321_mail,
					item_list = bc_list,
					stamp = 0,
					guid = 0,
					expiry_stamp = 0
				}
			core_send_mail.send_mail(user_info, mail_list.mail_list, t_mail)
			end
		end
		if user_info.data_version < DATA_VER_20150513 then
			local group = rawget(user_info, "group_data")
			if group then
				local t = group.groupid
				group.today_join_num = 0
				group.allot_num = 0
				local fortress = rawget(group, "fortress_list")
				if fortress then
					for k,v in ipairs(fortress) do
						t = v.reset
						v.reset = 0
						v.pass_num = 0
					end
				end
			end
		end
		if user_info.data_version < DATA_VER_20150523 then
			local dayid = get_dayid_from(os.time())
			if dayid == 16578 then
				local r, d = global_huodong.check_czdb(user_info)
				if r == 0 and d then
					local czhuodong = global_huodong.get_huodong(user_info, "czdb")
					if czhuodong.detail.reset_type == 1 then
						for k,v in ipairs(d.reward_list) do
							local t = v.use_num
							v.use_num = 0
						end
					end
				end
			end
		end
		if user_info.data_version < DATA_VER_20150612 then
			local t_cj_list = rawget(user_info, "chengjiu")
			if t_cj_list then
				for k,v in ipairs(t_cj_list.chengjiu_list) do
					if v.id == 300206008 then
						table.remove(t_cj_list.chengjiu_list, k)
						break
					end
				end
			end
			local group_data = rawget(main_data, "group_data")
			if group_data then
				local groupid = group_data.groupid
				if groupid ~= "" then
					local t = group_cache.get_group(groupid)
					if not t then
						group_data.groupid = ""
						group_data.total_sw = 0
						group_data.anti_time = 0
						group_data.status = 0
						--group_data.allot_num = 0
						group_data.today_join_num = 0
						--公会解散如果清挑战次数，玩家可以刷，所以也不请
						--rawset(group_data, "fortress_list", nil)
					end
				end
			end
		end
		if user_info.data_version < DATA_VER_20150706
			or ( server_platform == 1 and user_info.data_version < DATA_VER_20150907 ) --台湾版
		then
			--这一版新增了34-48关卡
			local t = user_info.PVE.fortress_list[1].id
			t = user_info.PVE.jingying[1].id
			local lent = rawlen(user_info.PVE.fortress_list)
			if lent == 33 and user_info.PVE.fortress_list[33].stage_list[10].difficulty_list[1].pass_num > 0 then
			   -- 玩家已通关，这一版要加新章节
			   local new_fortress,jingying_fortress = pve.create_new_fortress(34)
				if new_fortress then
					table.insert(user_info.PVE.fortress_list, new_fortress)
					table.insert(user_info.PVE.jingying, jingying_fortress)
				end
			end
		end
		if user_info.data_version < DATA_VER_20150717 then
			-- 侠客数据修正。新增了侠客的lock项，这里统一刷新一下
			local zhanwei_list = main_data.zhenxing.zhanwei_list
			for k,v in ipairs(zhanwei_list) do
				if v.status == 2 then
					v.knight.data.lock = 1
				end
			end
			local zhenxing = main_data.PVE.pve2.zhenxing
			if zhenxing then
				for k,v in ipairs(zhenxing) do
					if v.guid >= 0 then
						local t = core_user.get_knight_by_guid(v.guid, main_data, knight_list.knight_list)
						assert(t and t[2], "pve2_set_zhenxing|some guid not find")
						t[2].data.lock = t[2].data.lock + 1
					end
				end
			end
		end
		--宝藏开采队列初始化
		if user_info.data_version < DATA_VER_20150811 then
			if rawget(user_info, "mineinfo") then
				local found = false
				for k,v in ipairs(user_info.mineinfo.def_knight_list) do
					if v.status == 2 then
						v.status = 0
						v.knight = nil
					end
					if v.status == 1 then
						found = true
					end
				end

				if not found and rawget(user_info.mineinfo, "def_knight_list") then
					--print("init main")
					user_info.mineinfo.def_knight_list[1].status = 1
				end
			end
		end

		if server_platform == 1 and user_info.data_version < DATA_VER_20150929 then
			for k,v in ipairs(item_list.item_list) do
				if v.id == 191010031 then
					LOG_INFO("GM|RM191010031*"..v.num)
					table.remove(item_list.item_list, k)
				end
			end
		end

		if server_platform == 1 and user_info.data_version < DATA_VER_20150929_1 then
			for k,v in ipairs(item_list.item_list) do
				if v.id == 191010032 then
					LOG_INFO("GM|RM191010032*"..v.num)
					table.remove(item_list.item_list, k)
				end
			end
		end

		--修改数据版本号
		LOG_INFO(string.format("user:%s data-version update to:%d from:%d", user_name, DATA_VERSION, user_info.data_version))
		user_info.data_version = DATA_VERSION
	end

	--每次登陆做一次lock修正
	local t = {}
	for k,v in ipairs(knight_list.knight_list) do
		if v.data.lock ~= 0 then
			--print(1, v.guid, v.data.lock)
			table.insert(t, v.guid)
		end
	end
	robmine.check_knight_lock( user_info, knight_list.knight_list, t )

	--数据错误修正
	--修正错误主角星级
	if user_info.lead.star < 3 then
		LOG_INFO(string.format("%s|star:%d", user_name, user_info.lead.star))
		user_info.lead.star = 3
	end

	--检查各种版本容错
	--1,有没有新增的每日活跃
	local t = {}
	local level = user_info.lead.level
	for k, v in ipairs(Daily_conf.index) do
		local conf = Daily_conf[v]
		if level >= conf.Daily_Lv then
			rawset(t, v, 0)
		end
	end
	local t1 = user_info.daily.daily_list[1].id
	local t_daily_list = user_info.daily.daily_list
	t1 = rawlen(t_daily_list)
	--删掉不存在的活跃
	for k = t1, 1, -1 do
		local id = t_daily_list[k].id
		local t_entry = rawget(t, id)
		if not t_entry then
			table.remove(t_daily_list, k)
			ret = true
		else
			rawset(t, id, 1)
		end
	end
	--添加新增的活跃
	for k,v in pairs(t) do
		if v == 0 then
			local data = {id = k, status = 0, flag = 0, tag = 0}
			local conf = Daily_conf[k]
			local t = conf.Para_Type
			if t == 7 then
				data.tag = 1
				data.status = 3
			else
				data.tag = conf.Para[1]
			end
			table.insert(t_daily_list, data)
			ret = true
		end
	end
	--去除无效成就，添加新成就
	if not rawget(user_info, "chengjiu") then
		rawset(user_info, "chengjiu", {chengjiu_list = {}})
	end
	t = user_info.chengjiu.chengjiu_list[1]
	local t_chengjiu_list = rawget(user_info.chengjiu, "chengjiu_list")
	if not t_chengjiu_list then
		t_chengjiu_list = {}
		rawset(user_info.chengjiu, "chengjiu_list", t_chengjiu_list)
	end
	local t1 = {}
	local need_add = {}
	for k,v in ipairs(t_chengjiu_list) do
		t1[v.id] = k
		rawset(v,"t",-1)
	end
	for k,v in ipairs(Achievement_conf.index) do
		local e = t1[v]
		if not e then table.insert(need_add, v)
		else rawset(t_chengjiu_list[e],"t", nil) end
	end
	t1 = rawlen(t_chengjiu_list)
	for k = t1, 1, -1 do
		if rawget(t_chengjiu_list[k], "t") then
			table.remove(t_chengjiu_list, k)
			ret = true
		end
	end
	for k,v in ipairs(need_add) do
		local data = {id = v, status = 0, flag = 0, tag = 0}
		local conf = Achievement_conf[v]
		local t = conf.Para_Type
		if t == 1 or (t >= 13 and t <= 23) then
			data.tag = conf.Para[1]
		elseif t == 6 or t == 8 or t == 9 or t == 12 then
			data.tag = conf.Para[2]
		elseif t == 2 or t == 3 or t == 4 or t == 5 or t == 7 or t == 10 or t == 11 then
			data.tag = 1
		end
		table.insert(t_chengjiu_list, data)
		ret = true
	end

	--2,检查各种活动
	local r,d = global_huodong.check_new_task(user_info)
	if r ~= 0 then ret = true end
	r,d = global_huodong.check_day7(user_info)
	if r ~= 0 then ret = true end
	r,d = global_huodong.check_level(user_info)
	if r ~= 0 then ret = true end

	--3,检测pve特殊关卡
	t = user_info.ext_data.switch[1]
	t = rawget(user_info.ext_data, "switch")
	if not t then
		rawset(user_info.ext_data, "switch", {0,0,0})
	elseif rawlen(t) < 3 then
		rawset(user_info.ext_data, "switch", {0,0,0})
	end
	t = user_info.PVE.watch_show
	t = rawget(user_info.PVE, "special_stage")
	if not t then
		local t = {}
		for k = 1,3 do
			local t1 = {pass_num = 0, today_pass_num = 0, today_reset_num = 0, id = k}
			table.insert(t, t1)
		end
		rawset(user_info.PVE, "special_stage", t)
	end
	--4,其他
	if not rawget(user_info, "wxjy") then
		rawset(user_info, "wxjy", {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})
		ret = true
	else
		t = user_info.wxjy[1]
		for k = rawlen(user_info.wxjy) + 1, 20 do
			table.insert(user_info.wxjy, 0)
		end
		ret = true
	end
	--5，如果有新的任务，接下去
	t = user_info.task_list.task_list.id
	for k,v in ipairs(user_info.task_list.task_list) do
		if v.status == 3 then
			local tconf = Task_conf[v.id]
			if tconf.NEXT_TASK ~= 0 then
				local nt_conf = Task_conf[tconf.NEXT_TASK]
				v.id = tconf.NEXT_TASK
				v.status = 1
				core_task.check_task_by_task(user_info, v, nt_conf)
			end
		end
	end
	--6，如果没有xy商店，补上
	t = user_info.xyshop.ghost
	if not rawget(user_info, "xyshop") then
		local xy_shop_list = {}
		local xy_shop = {ghost = 0, shopping_list = xy_shop_list, next_reflesh_time = os.time() + 7200}
		local xy_pool = {}
		local xy_conf = Lottery_conf[100028]
		assert(xy_conf)
		core_drop.do_choujiang_from_1(xy_conf, xy_pool, true)
		for k,v in ipairs(xy_pool) do
			local i_conf = Xia_Shop_conf[v[1]]
			table.insert(xy_shop_list, {item = {id = v[1], num = v[2]}, cost = i_conf.PRICE * v[2], status = 0})
		end
		rawset(user_info, "xyshop", xy_shop)
		ret = true
	end
	--7，maxpower
	t = user_info.ext_data.max_power.max_power
	local max_power = rawget(user_info.ext_data, "max_power")
	if not max_power then
		local zhanwei = {}
		local total_power = 0
		for k,v in ipairs(user_info.zhenxing.zhanwei_list) do
			if v.status == 0 then
				table.insert(zhanwei, -2)
			elseif v.status == 1 then
				table.insert(zhanwei, -1)
				total_power = total_power + v.power
			else
				table.insert(zhanwei, v.knight.guid)
				total_power = total_power + v.power
			end
		end
		max_power = {max_power = total_power, zhanwei = zhanwei}
		rawset(user_info.ext_data, "max_power", max_power)
	end

	if magic_switch then
		t = user_info.huodong.new_task_list.open_day
		local t_list = rawget(user_info.huodong, "new_task_list")
		if t_list then
			t = t + 1
			if t >= 7 then t = 7 end
			t_list.open_day = t
		end
		t = user_info.huodong.day7.day_id
		local day7 = rawget(user_info.huodong, "day7")
		if day7 then
			t = t + 1
			if t >= 7 then t = 7 end
			day7.day_id = t
		end
		ret = true
	end

	local v = user_info.data_version

	if core_vip.reflesh_vip_goods_list(user_info) then
		ret = true
	end
	if core_vip.reflesh_vip_gift_list(user_info) then
		ret = true
	end

	local dayid = get_dayid_from(time)
	local ret1 = update_at_0am(user_info, dayid, mail_list.mail_list)
	ret = ret or ret1
	ret1 = update_tili_per_6min(user_info, 1, mail_list.mail_list, item_list)
	ret = ret or ret1
	dayid = get_dayid_from(time, 5)
	ret1 = update_at_5am(user_info, dayid, mail_list.mail_list)
	ret = ret or ret1

	--更新PVE信息
	--更新武林之巅信息
	pve.update_trial_info(user_info)

	--更新世界BOSS信息
	worldboss.update_user_info(user_info, mail_list.mail_list)

	dayid = get_dayid_from(time, 12)
	ret1 = update_at_12am(user_info, dayid, mail_list.mail_list)
	ret = ret or ret1

	dayid = get_dayid_from(time, 21)
	local ret1 = update_at_9pm(user_info, dayid, item_list.item_list, mail_list.mail_list, rank_idx)
	ret = ret or ret1

	core_send_mail.limit_mail_count(user_info, item_list.item_list, mail_list.mail_list)
	local mail_num = core_user.unread_mail_num(mail_list.mail_list)

	local t = user_info.ext_data.yueka.left_idx
	t = rawget(user_info.ext_data, "yueka")
	if not t then
		for k,v in ipairs(user_info.daily.daily_list) do
			if v.id == 3106001 then
				v.status = 0
			end
		end
	end

	t = user_info.daily.daily_list[1].id
	core_task.check_daily_tili(nil, user_info)

	--
	local qiandao_data = global_huodong.get_huodong(user_info,"qiandao")
	local t = user_info.huodong.qiandao.sub_id
	local t = rawget(user_info.huodong, "qiandao")

	--重发之前错误的充值等请求
	local redo = redo_list.get_redo_list(user_info.user_name)
	if redo then
		if redo.recharge_list then
			for k,v in ipairs(redo.recharge_list) do
				core_recharge(user_info, item_list, v.money, v.item_id, v.fake, v.selfdef, v.gamemoney, v.basemoney, v.monthcard)
				LOG_STAT( string.format( "%s|%s|%d|%s|%d|%s|%d", "CAST_OD", user_info.user_name, 2, v.od , v.money, v.item_id,user_info.money) )
			end
		end
		if redo.remail_list then
			for k,v in ipairs(redo.remail_list) do
				core_send_mail.send_mail(user_info, mail_list.mail_list, v)
			end
		end
		redo_list.clear_redo_list(user_info.user_name)
	end
	--[[
	-- 3.26更新后，有一部分老玩家意外开启新手豪礼，在这里强制检测一下这些任务，帮助他们完成
	core_task.check_newtask_by_event(user_info, 1)
	core_task.check_newtask_by_event(user_info, 3)
	for k,v in ipairs(user_info.PVE.jingying) do
		local rtn = false
		for k1,v1 in ipairs(v.stage_list) do
			local t = v1.id
			if t == 400020008 and v1.pass_num > 0 then
				core_task.check_newtask_by_event(user_info, 5, 400020008)
			elseif t == 400050010 and v1.pass_num > 0 then
				core_task.check_newtask_by_event(user_info, 5, 400050010)
			elseif t == 400080010 and v1.pass_num > 0 then
				core_task.check_newtask_by_event(user_info, 5, 400080010)
				rtn = true
			end
		end
		if rtn then
			break
		end
	end
	]]
	--部分玩家会意外出现3个任务，需要去掉一个
	local task_num = 0
	local max_idx = 0
	local cur_id = 0
	for k,v in ipairs(user_info.task_list.task_list) do
		if v.id >= 293000 then
			task_num = task_num + 1
			if cur_id == 0 or cur_id < v.id then
				cur_id = v.id
				max_idx = k
			end
		end
	end
	if task_num > 1 then
		table.remove(user_info.task_list.task_list, max_idx)
		LOG_INFO(string.format("%s|task_remove|%d", user_name, cur_id))
	end

	--初始化宝藏红点，默认flag = 1
	if user_info.lead.level >= 40 then
		if not rawget(user_info.ext_data.huodong,"hongdian_list") then
			user_info.ext_data.huodong.hongdian_list = {}
		end
		local found = false
		for k,v in ipairs(user_info.ext_data.huodong.hongdian_list) do
			if v.act_id == 10000 then
				found = true
				--print("baozang flag|" ..user_info.user_name .." ".. v.flag)
				break
			end
		end
		if not found then
			LOG_INFO(user_info.user_name.." init baozang!")
			t = {act_id = 10000, flag = 1}
			table.insert(user_info.ext_data.huodong.hongdian_list, t)
		end
	end

	--初始化豪侠列传
	if user_info.lead.level >= 35 then
		if not rawget(user_info.PVE, "haoxiainfo") then
			rawset(user_info.PVE, "haoxiainfo", {fightnum = 0,max_stage = 57770001})
		end
		if not rawget(user_info.ext_data.huodong,"hongdian_list") then
			user_info.ext_data.huodong.hongdian_list = {}
		end
		local found = false
		for k,v in ipairs(user_info.ext_data.huodong.hongdian_list) do
			if v.act_id == 10001 then
				found = true
				--print("baozang flag|" ..user_info.user_name .." ".. v.flag)
				break
			end
		end
		if not found then
			LOG_INFO(user_info.user_name.." init baozang!")
			t = {act_id = 10001, flag = 2}
			table.insert(user_info.ext_data.huodong.hongdian_list, t)
		end
	end

	core_task.check_newtask_by_event(user_info, 6)
	core_task.check_newtask_by_event(user_info, 7)
	core_task.check_newtask_by_event(user_info, 8)
	ret = true
	core_power.reflesh_team_power(user_info, knight_list.knight_list, core_power.create_modify_power(rank.modify_power, user_info.user_name))

	user_data_buf = pb.encode("UserInfo", user_info)
	item_buf = pb.encode("ItemList", item_list)
	mail_buf = pb.encode("MailList", mail_list)
	knight_buf = pb.encode("KnightList", knight_list)
	return ret, user_data_buf, knight_buf, item_buf, mail_buf, mail_num
end

function create_user(user_name, nickname, icon_id)
	print("create_user",user_name,nickname)

	if UserInfoCache.get(user_name) ~= nil then
		assert(false,"already has other_user_info", user_name)
	end

	if nick_name_ctrl.has_nick_name(nickname) == true then
		assert(false,"already has nickname  "..nickname)
	end

	for i=1,CONF.DIRTYWORD.len do
		assert(not string.find(nickname, CONF.DIRTYWORD[i].KEY), "dirty word  "..nickname)
	end
	
	local x,y = string.find(nickname,"%s+")
	assert(not (x==1 and string.len(nickname) == y) , "name has space  "..nickname)

	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"
	local mailList = require "MailList"

	userInfo:new()
	shipList:new()
	itemList:new()
	mailList:new()

	userInfo:add(user_name, nickname, icon_id)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()


	shipList:setUserInfo(user_info)

	for i=1,CONF.EBuilding.count do
		userInfo:getBuildingInfo(i)
	end

	userInfo:addCredit(CONF.PARAM.get("start_credit").PARAM)
	
	local items = {}
	for i,v in ipairs(CONF.PARAM.get("start_item_id").PARAM) do
		items[v] = CONF.PARAM.get("start_item_num").PARAM[i]
	end
	CoreItem.addItems(items, item_list, user_info)

	userInfo:addTaskInfo(1001)

	userInfo:resetDailyTask()

	--添加新手BUFF
	user_info.state = 0
	user_info.state = Bit:add(user_info.state, 1)
	local tech_list = userInfo:getTechnologyList()
	for i,tech_id in ipairs(CONF.PARAM.get("green_hand_buff").PARAM) do
		local tech_info =
		{
			tech_id = tech_id,
			begin_upgrade_time = 0,
		}
		table.insert(tech_list, tech_info)
	end

	--不给之前的邮件
	if true then
		local gmail_list = svr_info.get_gmail_list()
		if #gmail_list > 0 then
			user_info.timestamp.gmail = gmail_list[#gmail_list].tid
		end
	end

	local time = ostime()
	local dayid = timeChecker.get_dayid_from(time)
	timeChecker.update_at_0am(userInfo, dayid)

	local other_user_info = {
		user_name = user_info.user_name,
		nickname = user_info.nickname,
		power = shipList:getPowerFromAll(),
		level = user_info.level,
		icon_id = user_info.icon_id,
		building_level_list = {},
	}
	for i=1,CONF.EBuilding.count do
		other_user_info.building_level_list[i] = 1
	end

	UserInfoCache.set(user_info.user_name, other_user_info)

	nick_name_ctrl.add_nick_name(nickname, user_name)

	svr_info.new_reg()

	local user_buff = userInfo:getUserBuff()

	local ship_buff = shipList:getShipBuff()

	local item_buff = itemList:getItemBuff()

	local mail_buff = mailList:getMailBuff()

	return user_buff, ship_buff, item_buff, mail_buff
end

function create_new_user(nickname, sex, user_name, account, mcc, ip, real_money, money)
	local gm_flag = false
	if string.sub(user_name,1,2) == "gm" then
		gm_flag = true
	end
	if g_force_gm then
		gm_flag = true
	end
	local time = ostime()
	local pb = require "protobuf"
	if not gm_flag then
		for _,dirty_word in ipairs(dirty_word) do
			assert(not string.find(nickname, dirty_word))
		end
	end

	local sw1,sw2,sw3 = special_stage(time)
	local special_stage = {}
	for k = 1,3 do
		local t1 = {pass_num = 0, today_pass_num = 0, today_reset_num = 0, id = k}
		table.insert(special_stage, t1)
	end

	assert(nick_name_ctrl.has_nick_name(nickname))

	local fortress_list = {}
	local jing_fortress_list = {}
	for k = 1,rawlen(Fortress_conf.index) do
		if not gm_flag and k > 1 then
			break
		end
		local stage_list = {}
		local jingying_stage = {}
		local cur_fortress_conf = Fortress_conf[Fortress_conf.index[k]]
		local cur_jingying_fortress_conf = Jing_Fortress_conf[Jing_Fortress_conf.index[k]]
		local cur_fortress =
		{
			id = k,
			stage_list = stage_list,
			phase_reward = {0},
			star = 0
		}
		local cur_jingying_fortress = {id = cur_jingying_fortress_conf.ID, stage_list = jingying_stage}
		for k,v in ipairs(cur_fortress_conf.STAGE_LIST) do
			local s = Stage_conf[v]
			local d = {}
			local t = {difficulty_list = d}
			for k1 = 1,s.DIFFICULTY_QUANTITY do
				if gm_flag then
					table.insert(d,{pass_num = 1, today_pass_num = 0})
				else
					table.insert(d,{pass_num = 0, today_pass_num = 0})
				end
			end
			table.insert(stage_list, t)
			if gm_flag then
				cur_fortress.star = k
			end
		end
		for k,v in ipairs(cur_jingying_fortress_conf.STAGE_LIST) do
			if gm_flag then
				table.insert(jingying_stage, {pass_num = 1, today_pass_num = 0, id = v})
			else
				table.insert(jingying_stage, {pass_num = 0, today_pass_num = 0, id = v})
			end
		end



		table.insert(fortress_list, cur_fortress)
		table.insert(jing_fortress_list, cur_jingying_fortress)
	end

	-- 初始化成就列表
	local chengjiu_list = {}
	local chengjiu = {chengjiu_list = chengjiu_list}
	for k,v in ipairs(Achievement_conf.index) do
		local data = {id = v, status = 0, flag = 0, tag = 0}
		local conf = Achievement_conf[v]
		local t = conf.Para_Type
		if t == 1 or (t >= 13 and t <= 23) then
			data.tag = conf.Para[1]
		elseif t == 6 or t == 8 or t == 9 or t == 12 then
			data.tag = conf.Para[2]
		elseif t == 2 or t == 3 or t == 4 or t == 5 or t == 7 or t == 10 or t == 11 then
			data.tag = 1
		end
		table.insert(chengjiu_list, data)
	end
	-- 初始化每日活跃列表
	local daily_list = {}
	local daily = {daily_list = daily_list}
	for k,v in ipairs(Daily_conf.index) do
		local conf = Daily_conf[v]
		if conf.Daily_Lv == 1 then
			local data = {id = v, status = 0, flag = 0, tag = 0}
			--if v == 3106001 then data.status = 0 end
			local t = conf.Para_Type
			if t == 7 then
				data.tag = 1
				if v == 3107001 then data.status = 0
				else data.status = 3
				end
			else
				data.tag = conf.Para[1]
			end
			table.insert(daily_list, data)
		end
	end

	-- 初始化pvp shoppinglist
	local shop_list = {}
	local pool_list = {}
	local conf = Lottery_conf[100014]
	assert(conf)
	core_drop.do_choujiang_from_1(conf, pool_list)
	for k,v in ipairs(pool_list) do
		local id = v[1]
		local num = v[2]
		local conf_item = PVP_Shop_conf[id]
		assert(conf_item)
		local price = conf_item.PRICE
		local entry = {
			id = id,
			num = num,
			price = price
		}
		table.insert(shop_list, entry)
	end

	-- 初始化pve2 shoppinglist
	local shop_list1 = {}
	local pool_list1 = {}
	local conf1 = Lottery_conf[100025]
	assert(conf1)
	core_drop.do_choujiang_from_1(conf1, pool_list1)
	for k,v in ipairs(pool_list1) do
		local id = v[1]
		local num = v[2]
		local conf_item = PVE2_Shop_conf[id]
		assert(conf_item)
		local price = conf_item.PRICE
		local entry = {
			id = id,
			num = num,
			price = price
		}
		table.insert(shop_list1, entry)
	end

	--初始化侠义客栈商品列表
	local xy_shop_list = {}
	local xy_shop = {ghost = 0, shopping_list = xy_shop_list, next_reflesh_time = time + 7200}
	local xy_pool = {}
	local xy_conf = Lottery_conf[100028]
	assert(xy_conf)
	core_drop.do_choujiang_from_1(xy_conf, xy_pool, true)
	for k,v in ipairs(xy_pool) do
		local i_conf = Xia_Shop_conf[v[1]]
		table.insert(xy_shop_list, {item = {id = v[1], num = v[2]}, cost = i_conf.PRICE * v[2], status = 0})
	end

	-- 初始化点石成金
	local m2g = core_money.reflesh_m2g(1, Gold_Money_conf[1].YUANBAO, 1, 100, 100)

	local user_info = {
		nickname = nickname,
		tili = 60,
		gold = init_gold,
		money = init_money,
		vip_lev = init_vip,
		next_knight_guid = 0,
		next_mail_guid = 0,
		user_name = user_name,
		account = account,
		ip = ip,
		mcc = mcc,
		data_version = DATA_VERSION
	}
	--if last_hf then user_info.ext_data.hf = last_hf end
	local knight_list = {knight_list = {}}
	local item_list = {item_list = {}}
	local mail_list = {mail_list = {}}
	--初始化各种活动
	--[[global_huodong.check_new_task(user_info)
	global_huodong.check_day7(user_info)
	global_huodong.check_level(user_info)
	global_huodong.check_drljcz(user_info)
	global_huodong.check_ljcz(user_info)
	global_huodong.check_dbcz(user_info)
	global_huodong.check_xffl(user_info)
	global_huodong.check_login(user_info)
	global_huodong.check_tianji(user_info)
	global_huodong.check_ljxffl(user_info)
	global_huodong.check_qhaoxia(user_info)--]]

	--处理全服公告
	--[[local gmail_list = svr_info.get_gmail_list()
	local t = user_info.ext_data.gmail
	local max_gmail = 0
	for k,v in ipairs(gmail_list) do
		if t < v.tid then
			if max_gmail < v.tid then max_gmail = v.tid end
			if (v.reg_time and v.reg_time ~= 0 and user_info.timestamp.regist_time > v.reg_time)
				or (v.vip_limit and v.vip_limit ~= 0 and user_info.vip_lev < v.vip_limit)
				or (v.lev_limit and v.lev_limit ~= 0 and user_info.lead.level < v.lev_limit) then
			else
				core_send_mail.send_mail(user_info, mail_list.mail_list, v)
			end
		end
	end
	user_info.ext_data.gmail = max_gmail

	core_vip.reflesh_vip_goods_list(user_info)
	core_vip.reflesh_vip_gift_list(user_info)

	core_task.check_daily_tili(nil, user_info)--]]
	if gm_flag then
		user_info.gold = 10000000
		user_info.money = 1000000
		user_info.ext_data.real_money = 1000000
		user_info.lead.star = 6
		user_info.lead.level = 99
		for k,v in ipairs(user_info.lead.equip_list) do
			v.star = 5
			v.level = 99
		end
		user_info.lover_list = {{id = 30040001, skill = {id = 110360001, level = 1}},
					{id = 30100001, skill = {id = 110750001, level = 1}},
					{id = 30050001, skill = {id = 110370001, level = 1}}}
		user_info.lead.skill.id = Character_conf[10060000].SKILL_ID

		local e_item_list = {}
		for k,v in ipairs(Item_conf.index) do
			local conf = Item_conf[v]
			if conf.KIND == 3 or conf.KIND == 1 or conf.KIND == 2 or conf.KIND == 5 or conf.KIND == 7 or conf.KIND == 9 then
				table.insert(e_item_list, {id = conf.ID, num = 10000})
			end
		end

		local mail = {type = 10,
					from = lang.gm_sender,
					subject = lang.gm_subject,
					message = "",
					item_list = e_item_list,
					stamp = 0,
					guid = 0,
					expiry_stamp = 0,}
		core_send_mail.send_mail(user_info, mail_list.mail_list, mail)

		user_info.task_list.task_list[1].status = 2
		table.insert(user_info.task_list.task_list, {id = 293001, status = 2})
	end

	--这里处理封测充值双倍返还
	--[[core_user.get_item(191010003, money * 2, user_info, 410)
	core_user.get_item(191010099, real_money * 2, user_info, 410)
	user_info.ext_data.total_money = real_money
	user_info.vip_score = real_money
	local total_money = real_money
	local cur_vip = 0
	local dest_vip = cur_vip
	for k = cur_vip + 1, VIP_conf.len - 1 do
		local conf = VIP_conf[k]
		local value = conf.RECHARGE
		if total_money >= value then dest_vip = k
		else break end
	end
	user_info.vip_lev = dest_vip
	local vip_reward = {}
	for k = 1, dest_vip do
		table.insert(vip_reward, 0)
	end
	user_info.ext_data.vip_reward = vip_reward--]]

	--这里处置充值返利
	--[[local r, chongzhi = global_huodong.check_chongzhi(user_info)
	if chongzhi then
		chongzhi.total_money = real_money
	end
	core_send_mail.send_huodong_mail_daily(user_info, mail_list.mail_list, get_dayid_from(time))
	core_send_mail.limit_mail_count(user_info, item_list.item_list, mail_list.mail_list)--]]
	local user_data_buf = pb.encode("UserInfo", user_info)
	local knight_buf = pb.encode("KnightList", knight_list)
	local item_buf = pb.encode("ItemList", item_list)
	local mail_buf = pb.encode("MailList", mail_list)

	nick_name_ctrl.add_nick_name(nickname, user_name)
	svr_info.new_reg()
	return user_data_buf, knight_buf, item_buf, mail_buf
end

 --定时轮询 10秒1次
function time_reflesh()
	--服务器活动表热更新
	--GolbalActivity.doTimer()

	--global_huodong.check_czfl()
	svr_info.check_gmail()
	--wlzb.check_time()
	--group_cache.do_timer()
	--cz_rank.do_timer()
	--mpz.check_time()
	--tianji_msg.do_timer()
	--robmine.check_time()
	--qhaoxia_rank.do_timer()
	ArenaCache.doTimer()
	PlanetCache.doTimer()
	GroupCache.doTimer()
	VideoCache.doTimer()
end

function add_undo_recharge(uid, money, item_id, fake, selfdef, gamemoney, basemoney, monthcard, od)
	print("add_undo_recharge---------------------", uid, money, item_id, fake, selfdef, gamemoney, basemoney, monthcard)
	RedoList.addRecharge(uid, money, item_id, fake, od)
	LOG_STAT( string.format( "%s|%s|%d|%s|%d|%s|%d", "CAST_OD", user_info.user_name, 1, od , money, item_id, 0) )
end

function add_undo_mail(uid, mail_buf)
	RedoList.addMailBuff(uid, mail_buf)
end

function get_reg_num()
	if not max_reg then max_reg = 20000 end
	return svr_info.get_reg(),max_reg
end

