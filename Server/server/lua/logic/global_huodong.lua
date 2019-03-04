local mfloor = math.floor
local rawget = rawget
local rawset = rawset

--[[
	data = {
		type
		sub_id
		begin_time
		end_time
	}
]]

local function get_timestamp_from(t)
	if t < 2015000000 then
		return t
	end
	local y = math.floor(t / 1000000)
	local m = math.floor((t % 1000000) / 10000)
	local d = math.floor((t % 10000) / 100)
	local h = math.floor(t % 100)
	local dt = {year = y, month = m, day = d, hour = h}
	return os.time(dt)
end

local global_huodong = {}
local choujiang_huodong = {}
for k,v in ipairs(HotPoint_conf.index) do
	local conf = HotPoint_conf[v]
	local t = {
		start_stamp = get_timestamp_from(conf.Start_Time),
		end_stamp = get_timestamp_from(conf.End_Time),
		item = {item_id = conf.Show_Hero, item_num = 1},
		pool = conf.Hot_Pool
	}
	table.insert(choujiang_huodong, t)
end

local haoxia_huodong = {}
for k, v in ipairs(Haoxia_conf.index) do
	local conf = Haoxia_conf[v]	
	local t = {
		index = k,
		start_stamp = get_timestamp_from(conf.STARTTIME),
		end_stamp = get_timestamp_from(conf.ENDTIME),
		num_week = conf.SPE_REQUIRE,
		xia_week = conf.WEEKXIA,
		xia_spec = conf.SPE_POOL,
		xia_equl = conf.EQU_POOL,
		xia_1 = conf.SUNXIA,
		xia_2 = conf.MONXIA,
		xia_3 = conf.TUEXIA,
		xia_4 = conf.WEDXIA,
		xia_5 = conf.THUXIA,
		xia_6 = conf.FRIXIA,
		xia_7 = conf.SATXIA
	}
	table.insert(haoxia_huodong, t)
end

for k,v in ipairs(Activity_conf.index) do
	local conf = Activity_conf[v]
	local begin_time = conf.Activity_Start
	local end_time = 0
	local h_type = 0
	--[[
	start   end
	0       0       --1,永久
	0       n       --2，随开服
	1       n       --3,随特定时间点
	n       n       --4，正常活动
	2       n       --5,强制随角色创建
	]]
	if begin_time == 0 then -- 这个活动随开服时间走
		begin_time = svr_open_time
		if conf.LastTime ~= 0 then
			end_time = begin_time + conf.LastTime * 86400
			h_type = 2
		else
			end_time = 0
			h_type = 1
		end
	elseif begin_time == 1 then -- 这个活动随角色创建
		begin_time = 0
		end_time = conf.LastTime
		h_type = 3
	elseif begin_time == 2 then
		begin_time = 0
		end_time = conf.LastTime
		h_type = 5
	else
		begin_time = get_timestamp_from(begin_time)
		-- lasttime如果是是个小值，则是持续天数。如果是一个大值（大于10000）则是结束时间戳
		if conf.LastTime < 10000 then
			end_time = begin_time + conf.LastTime * 86400
		else
			end_time = get_timestamp_from(conf.LastTime)
		end
		h_type = 4
	end
	
	local need_add = true
	-- conf.Hide:为1代表这个活动和新服期冲突
	-- conf.Hide1:新服期。
	if conf.Hide ~= 0 then
		local s_limit = svr_open_time
		local e_limit = svr_open_time + 86400 * conf.Hide1
		if (begin_time >= s_limit and begin_time < e_limit)
			or (end_time > s_limit and end_time <= e_limit) then
			need_add = false
		end
	end
	
	if need_add then
		local type = mfloor(v / 10000)
		local subid = v % 10000
		local data = {
			type = type, sub_id = subid,
			begin_time = begin_time, end_time = end_time,
			group = conf.Group,show = conf.Show,
			act_id = v,
			h_type = h_type
		}
		if type == 42101 then
			local chongzhi = rawget(global_huodong, "chongzhi")
			if not chongzhi then
				chongzhi = {}
				rawset(global_huodong, "chongzhi", chongzhi)
			end
			
			local reward_list = {}
			for k,v in ipairs(Activity_Chong_conf.index) do
				local conf = Activity_Chong_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local item_list = {}
					local new_t = {
						reward = {item_list = item_list},
						act_id = data.act_id,
						show_hero = conf.Showhero,
						amount = conf.Limit,
					}
					
					table.insert(reward_list, new_t)
					local k = 1
					while conf.Reward[k] do
						local item = {id = conf.Reward[k], num = conf.Reward[k + 1]}
						table.insert(item_list, item)
						k = k + 2
					end
				end
			end
			data.reward_list = reward_list
			table.insert(chongzhi, data)
		elseif type == 43201 then
			local cangjian = rawget(global_huodong, "cangjian")
			if not cangjian then
				cangjian = {}
				rawset(global_huodong, "cangjian", cangjian)
			end
	
			--data.end_time = os.time() + 300
			table.insert(cangjian, data)
			--local data1 = {type = type, sub_id = subid + 1, begin_time = os.time() + 600, end_time = end_time}
			--table.insert(cangjian, data1)
		elseif type == 49401 then
			local qiandao = rawget(global_huodong, "qiandao")
			if not qiandao then
				qiandao = {}
				rawset(global_huodong, "qiandao", qiandao)
			end
			table.insert(qiandao, data)
		elseif type == 53001 then
			local day7 = rawget(global_huodong, "7day")
			if not day7 then
				day7 = {}
				rawset(global_huodong, "7day", day7)
			end
			local reward_list = {}
			for k,v in ipairs(LoginEvent_conf.index) do
				local conf = LoginEvent_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local conf_list = {}
					local t = {conf_list = conf_list}
					table.insert(reward_list, t)
					local k = 1
					while conf.REWARD[k] do
						local item = {id = conf.REWARD[k], num = conf.REWARD[k + 1]}
						table.insert(conf_list, item)
						k = k + 2
					end
				end
			end
			data.reward_list = reward_list
			table.insert(day7, data)
		elseif type == 55001 then
			local level_gift = rawget(global_huodong, "level")
			if not level_gift then
				level_gift = {}
				rawset(global_huodong, "level", level_gift)
			end
			local reward_list = {}
			for k,v in ipairs(LevelEvent_conf.index) do
				local conf = LevelEvent_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local conf_list = {}
					table.insert(reward_list, {level = conf.LEVEL, status = 0, conf_list = conf_list})
					local k = 1
					while conf.REWARD[k] do
						local item = {id = conf.REWARD[k], num = conf.REWARD[k + 1]}
						table.insert(conf_list, item)
						k = k + 2
					end
				end
			end
			data.reward_list = reward_list
			table.insert(level_gift, data)
		elseif type == 51001 then
			local new_task = rawget(global_huodong, "new_task")
			if not new_task then
				new_task = {}
				rawset(global_huodong, "new_task", new_task)
			end
			local reward_list = {}
			for k,v in ipairs(NewEvent_conf.index) do
				
				local conf = NewEvent_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local conf_list = {}
					local task_list = {}
					local event = {event_id = v, status = 0, task_list = task_list,
						conf_list = conf_list, targetdsr = conf.TARGETDSR}
					for k,v in ipairs(conf.TASKGROUP) do
						local nt_conf = NewTask_conf[v]
						table.insert(task_list, {id = v, flag = 0, status = 0,
							task_type = nt_conf.TASKTYPE, para = nt_conf.PARA, targetdsr = nt_conf.TARGETDSR})
					end
					table.insert(reward_list, event)
					local k = 1
					while conf.REWARD[k] do
						local item = {id = conf.REWARD[k], num = conf.REWARD[k + 1]}
						table.insert(conf_list, item)
						k = k + 2
					end
				end
			end
			data.reward_list = reward_list
			table.insert(new_task, data)
		elseif type == 99301 then
			local csd = rawget(global_huodong, "csd")
			if not csd then
				csd = {}
				rawset(global_huodong, "csd", csd)
			end
			table.insert(csd, data)
		elseif type == 56001 then   -- 单笔充值
			local dbcz = rawget(global_huodong, "dbcz")
			if not dbcz then
				dbcz = {}
				rawset(global_huodong, "dbcz", dbcz) 
			end
			local reward_list = {}
			local schannel = server_channel
			for k,v in ipairs(Once_Chong_conf.index) do
				local conf = Once_Chong_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					if conf.Android ~= 1 or (conf.Android == 1 and schannel > 1) then
						local item_list = {}
						local t = 1
						while conf.REWARD[t] do
							table.insert(item_list, {id = conf.REWARD[t], num = conf.REWARD[t + 1]})
							t = t + 2
						end
						table.insert(reward_list, {
							item_list = item_list,
							money = conf.MONEY,
							total_num = conf.CHANCE,
							num = 0,
							reward_num = 0,
						})
					end
				end
			end
			data.reward_list = reward_list
			table.insert(dbcz, data)
		elseif type == 57001 then       -- 单日累计充值
			local drljcz = rawget(global_huodong, "drljcz")
			if not drljcz then
				drljcz = {}
				rawset(global_huodong, "drljcz", drljcz) 
			end
			local reward_list = {}
			for k,v in ipairs(Con_Chong_conf.index) do
				local conf = Con_Chong_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local item_list = {}
					local t = 1
					while conf.REWARD[t] do
						table.insert(item_list, {id = conf.REWARD[t], num = conf.REWARD[t + 1]})
						t = t + 2
					end
					table.insert(reward_list, {
						item_list = item_list,
						status = 0,
						conf = conf.LIMIT,
					})
				end
			end
			data.reward_list = reward_list
			table.insert(drljcz, data)
		elseif type == 58001 then       -- 连续登录
			local lxdl = rawget(global_huodong, "lxdl")
			if not lxdl then
				lxdl = {}
				rawset(global_huodong, "lxdl", lxdl) 
			end
			local reward_list = {}
			local num = 1
			for k,v in ipairs(Activity_Login_conf.index) do
				local conf = Activity_Login_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local item_list = {}
					local t = 1
					while conf.REWARD[t] do
						table.insert(item_list, {id = conf.REWARD[t], num = conf.REWARD[t + 1]})
						t = t + 2
					end
					local status = 0
					if num == 1 then status = 1 end
					table.insert(reward_list, {
						item_list = item_list,
						status = status,
					})
					num = num + 1
				end
			end
			data.reward_list = reward_list
			table.insert(lxdl, data)
		elseif type == 59001 then       -- 消费返利
			local xffl = rawget(global_huodong, "xffl")
			if not xffl then
				xffl = {}
				rawset(global_huodong, "xffl", xffl) 
			end
			local reward_list = {}
			for k,v in ipairs(Activity_Xiao_conf.index) do
				local conf = Activity_Xiao_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local item_list = {}
					local t = 1
					while conf.REWARD[t] do
						table.insert(item_list, {id = conf.REWARD[t], num = conf.REWARD[t + 1]})
						t = t + 2
					end
					table.insert(reward_list, {
						item_list = item_list,
						status = 0,
						conf = conf.X_Gold,
					})
				end
			end
			data.reward_list = reward_list
			table.insert(xffl, data)
		elseif type == 60001 then       -- 累计充值
			local ljcz = rawget(global_huodong, "ljcz")
			if not ljcz then
				ljcz = {}
				rawset(global_huodong, "ljcz", ljcz) 
			end
			local reward_list = {}
			for k,v in ipairs(Con_Chong_conf.index) do
				local conf = Con_Chong_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local item_list = {}
					local t = 1
					while conf.REWARD[t] do
						table.insert(item_list, {id = conf.REWARD[t], num = conf.REWARD[t + 1]})
						t = t + 2
					end
					table.insert(reward_list, {
						item_list = item_list,
						status = 0,
						conf = conf.LIMIT,
					})
				end
			end
			data.reward_list = reward_list
			table.insert(ljcz, data)
		elseif type == 61001 then   -- 充值双倍活动
			local czdb = rawget(global_huodong, "czdb")
			if not czdb then
				czdb = {}
				rawset(global_huodong, "czdb", czdb)
			end
			local find = false
			local list = {}
			local detail = {
				reset_type = 0,
				reset_num = 0,
				begin_time = begin_time,
				end_time = end_time,
				list = list,
			}
			local reward_list = {}
			for k,v in ipairs(Activity_Recharge_conf.index) do
				if v == data.act_id then
					local conf = Activity_Recharge_conf[v]
					detail.reset_type = conf.Limit_Type
					detail.reset_num = conf.Limit_Time
					for k1,v1 in ipairs(conf.RechargeID) do
						local r_conf = Recharge_conf[v1]
						assert(r_conf)
						local info = {
							RechargeID = r_conf.RechargeID,
							PreRe = r_conf.PreRe,
							NextRe = r_conf.NextRe,
							Recharge_Title = r_conf.Recharge_Title,
							Recharge_Dsc = r_conf.Recharge_Dsc,
							Icon = r_conf.Icon,
							Title = r_conf.Title,
							Limit = r_conf.Limit,
							Scale = r_conf.Scale,
							Amount = r_conf.Amount,
							Product_Name = r_conf.Product_Name,
							Yue = r_conf.Yue,
						}
						table.insert(list, info)
						table.insert(reward_list, {recharge_id = r_conf.RechargeID,
							use_num = 0})
					end
					find = true
				end
			end
			assert(find)
			data.detail = detail
			data.reward_list = reward_list
			table.insert(czdb, data)
		elseif type == 62001 then   -- 充值红包
			local cz_rank = rawget(global_huodong, "cz_rank")
			if not cz_rank then
				cz_rank = {}
				rawset(global_huodong, "cz_rank", cz_rank)
			end
			table.insert(cz_rank, data)
		elseif type == 63001 then
			local level_gift = rawget(global_huodong, "new_level")
			if not level_gift then
				level_gift = {}
				rawset(global_huodong, "new_level", level_gift)
			end
			local reward_list = {}
			for k,v in ipairs(Activity_Level_conf.index) do
				local conf = Activity_Level_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local conf_list = {}
					table.insert(reward_list, {level = conf.LEVEL, status = 0, item_list = conf_list})
					local k = 1
					while conf.REWARD[k] do
						local item = {id = conf.REWARD[k], num = conf.REWARD[k + 1]}
						table.insert(conf_list, item)
						k = k + 2
					end
				end
				
			end
			data.reward_list = reward_list
			table.insert(level_gift, data)
		elseif type == 64001 then   -- 兑换活动
			local hd = rawget(global_huodong, "duihuan")
			if not hd then 
				hd = {}
				rawset(global_huodong, "duihuan", hd)
			end
			local reward_list = {}
			for k,v in ipairs(Activity_DuiShop_conf.index) do
				local conf = Activity_DuiShop_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local src_list = {}
					local tag_list = {}
					table.insert(reward_list, {src_list = src_list, tag_list = tag_list})
					local k = 1
					while conf.GOODS[k] do
						local item = {id = conf.GOODS[k], num = conf.GOODS[k + 1]}
						table.insert(tag_list, item)
						k = k + 2
					end
					k = 1
					while conf.PRIECE[k] do
						local item = {id = conf.PRIECE[k], num = conf.PRIECE[k + 1]}
						table.insert(src_list, item)
						k = k + 2
					end
				end
			end
			data.reward_list = reward_list
			local dp_conf = Activity_DuiPool_conf[data.act_id]
			data.pool6 = dp_conf.Stam_6
			data.pool8 = dp_conf.Stam_8
			data.pool10 = dp_conf.Stam_10
			data.pool12 = dp_conf.Stam_12
			data.item = dp_conf.Activity_item
			table.insert(hd, data)
		elseif type == 65001 then
			local tj = rawget(global_huodong, "tianji")
			if not tj then 
				tj = {}
				rawset(global_huodong, "tianji", tj)
			end
			local reward_list = {}
			--读配置表
			for k,v in ipairs(Activity_Tianji_Reward_conf.index) do
				local conf = Activity_Tianji_Reward_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local item_list = {}
					table.insert(reward_list, {item_list = item_list, status = conf.FREQUENCY})
					local k1 = 1
					while conf.REWARD[k1] do
						local item = {id = conf.REWARD[k1], num = conf.REWARD[k1 + 1]}
						table.insert(item_list, item)
						k1 = k1 + 2
					end
				end
			end

			data.reward_list = reward_list
			table.insert(tj, data)
		elseif type == 66001 then
			local ls = rawget(global_huodong, "limitshop")
			if not ls then 
				ls = {}
				rawset(global_huodong, "limitshop", ls)
			end

			local reward_list = {}

			--读配置表
			for k,v in ipairs(Activity_LShop_conf.index) do
				local conf = Activity_LShop_conf[v]
				if conf.Activity_ID == data.act_id then
					local item_list = {}
					table.insert(reward_list, {item_list = item_list, status = conf.Gift_Priece, limittime = conf.Gife_Limit, gift_name = conf.Gift_Name, iconid = conf.Gife_Icon})
					local k1 = 1
					while conf.Gift_Pool[k1] do
						local item = {id = conf.Gift_Pool[k1], num = conf.Gift_Pool[k1 + 1]}
						table.insert(item_list, item)
						k1 = k1 + 2
					end
				end
			end

			data.reward_list = reward_list 
			table.insert(ls, data)
		elseif type == 67001 then       -- 累计消费返利
			local ljxffl = rawget(global_huodong, "ljxffl")
			if not ljxffl then
				ljxffl = {}
				rawset(global_huodong, "ljxffl", ljxffl) 
			end
			local reward_list = {}
			for k,v in ipairs(Activity_Xiao_conf.index) do
				local conf = Activity_Xiao_conf[v]
				if conf.ACTIVITY_ID == data.act_id then
					local item_list = {}
					local t = 1
					while conf.REWARD[t] do
						table.insert(item_list, {id = conf.REWARD[t], num = conf.REWARD[t + 1]})
						t = t + 2
					end
					table.insert(reward_list, {
						item_list = item_list,
						status = 0,
						conf = conf.X_Gold,
					})
				end
			end
			data.reward_list = reward_list
			table.insert(ljxffl, data)
		elseif type == 68001 then       -- 抢豪侠活动
			local qhaoxia = rawget(global_huodong, "qhaoxia")
			if not qhaoxia then
				qhaoxia = {}
				rawset(global_huodong, "qhaoxia", qhaoxia) 
			end
			local found = false
			for k,v in ipairs(QiangHX_conf.index) do
				local conf = QiangHX_conf[v]
				if conf.Activity_ID == data.act_id then
					data.interval = conf.FP_CoolDown
					data.hotid = conf.Show_Hero
					found = true
					break
				end
			end

			--assert(found)

			local reward_list = {}
			for k,v in ipairs(QiangHX_Reward_conf.index) do
				local conf = QiangHX_Reward_conf[v]
				if conf.Activity_ID == data.act_id then
					local item_list = {}
					local t = 1
					while conf.Reward[t] do
						table.insert(item_list, {id = conf.Reward[t], num = conf.Reward[t + 1]})
						t = t + 2
					end
					table.insert(reward_list, {
						item_list = item_list,
						needpoint = conf.Score,
						getflag = 0,
					})
				end
			end

			local rank_reward = {}
			for k,v  in ipairs(QiangHX_PaiMing_Reward_conf.index) do
				local conf = QiangHX_PaiMing_Reward_conf[v]
				if conf.Activity_ID == data.act_id then
					local item_list = {}
					local t = 1
					while conf.Reward[t] do
						table.insert(item_list, {id = conf.Reward[t], num = conf.Reward[t + 1]})
						t = t + 2
					end
					table.insert(rank_reward, {item_list = item_list})
				end
			end
			data.rank_reward = rank_reward
			data.reward_list = reward_list
			table.insert(qhaoxia, data)
		end
	end
end

function global_huodong.get_huodong(main_data, name)
	local data_list = rawget(global_huodong, name)
	local data = nil
	if data_list then
		local t = os.time()
		for k,v in ipairs(data_list) do
			if v.h_type == 3 then
				local s = main_data.timestamp.huodong1_time
				local e = s + v.end_time * 86400
				if t >= s and t <= e then
					data = clonetab(v)
					data.begin_time = s
					data.end_time = e
					break
				end
			elseif v.h_type == 5 then
				local s = main_data.timestamp.regist_time
				local e = s + v.end_time * 86400
				if t >= s and t <= e then
					data = clonetab(v)
					data.begin_time = s
					data.end_time = e
					break
				end
			elseif v.h_type == 1 or t >= v.begin_time and t <= v.end_time then
				data = v
				break
			end
		end
	end
	return data
end

local cur_cjsz = -1
function global_huodong.check_czfl()
	local data = global_huodong.get_huodong(nil, "cangjian")
	if data then cur_cjsz = data.sub_id
	else cur_cjsz = 0 end
	
	if cur_cjsz ~= 0 then 
		cjsz_rank.cur_sub(cur_cjsz)
	end
end

local function get_one_huodong(huodong, main_data, huodong_list)
	local t = global_huodong.get_huodong(main_data, huodong)
	if t then
		table.insert(huodong_list, {id = t.act_id, start_time = t.begin_time, end_time = t.end_time,
		group = t.group, show = t.show})
	end
end

function global_huodong.get_all_huodong(main_data)
	local list = {}
	local huodong_list = {
		"chongzhi",
		"cangjian",
		"7day",
		"level",
		"new_task",
		"qiandao",
		"csd",
		"dbcz",
		"drljcz",
		"lxdl",
		"xffl",
		"ljcz",
		"cz_rank",
		"new_level",
		"duihuan",
		"tianji",
		"limitshop",
		"ljxffl",
		"qhaoxia",
	}
	for k,v in ipairs(huodong_list) do
		get_one_huodong(v, main_data, list)
	end
	-- 要排序
	local tlist = {}
	for k,v in ipairs(Activity_conf.index) do
		for k1,v1 in ipairs(list) do
			if v1.id == v then
				table.insert(tlist, v1)
				table.remove(list, k1)
				break
			end
		end
	end
	return tlist
end


function global_huodong.get_cur_cang_quan(data)
	if not data then return nil
	else
		local idx = 432010000 + data.sub_id
		local item_list = {}
		for k,v in ipairs(Cang_Quan_conf.index) do
			local conf = Cang_Quan_conf[v]
			if conf.Activity_ID == idx then
				table.insert(item_list, conf)
			end
		end
		return item_list
	end
end

function global_huodong.get_cur_cang_rank(data)
	if not data then return nil
	else
		local idx = 432010000 + data.sub_id
		local item_list = {}
		for k,v in ipairs(Cang_Rank_conf.index) do
			local conf = Cang_Rank_conf[v]
			if conf.Activity_ID == idx then
				table.insert(item_list, conf)
			end
		end
		return item_list
	end
end

function global_huodong.get_choujiang()
	local t = os.time()
	local ret = nil
	for k,v in ipairs(choujiang_huodong) do
		if t >= v.start_stamp and t <= v.end_stamp then
			ret = v
			break
		end
	end
	return ret
end

function global_huodong.get_haoxia()
	local t = os.time()
	local ret = nil
	for k, v in ipairs(haoxia_huodong) do
		if t >= v.start_stamp and t < v.end_stamp then
			ret = v
			break
		end
	end
	return ret
end

--新加的5个活动适用
--这里只校验当下的有效性
--ret=0 这个date有效
--ret=1 这个date要清掉，失效了且没有新的数据
--ret=2 返回了一个新的date。可能是原来没有date，现在有，也可能是原来的失效了，现在有
--ret=3 活动本身没变，但是配置表变了
local function check_huodong_data(huodong_name, data, main_data)
	local huodong = global_huodong.get_huodong(main_data, huodong_name)
	if (not huodong) and data then
		return 1,nil
	elseif (data and huodong and  (huodong.sub_id%1000) ~= (data.sub_id%1000))--新活动
		or ((not data) and huodong)--创建活动
		then
		local reward_list = clonetab(huodong.reward_list)
		local tdata = {
			sub_id = huodong.sub_id,
			reward_list = reward_list,
		}
		return 2,tdata
	elseif  (data and huodong and  (huodong.sub_id) ~= (data.sub_id)) then
		data.sub_id = huodong.sub_id
		return 3,huodong.reward_list
	else
		return 0, data
	end
end

function global_huodong.check_drljcz(main_data)
	local t = main_data.huodong.meiri_leiji
	if t then t = t.sub_id end
	local data = rawget(main_data.huodong, "meiri_leiji")
	local ret, rdata = check_huodong_data("drljcz", data, main_data)
	if ret == 2 then
		rdata.total_money = 0
	end
	if ret == 3 then
		for k,v in ipairs(data.reward_list) do
			local t = v.item_list[1]
			v.item_list = rdata[k].item_list
		end
		rdata = data
	elseif ret ~= 0 then
		rawset(main_data.huodong, "meiri_leiji", rdata)
	end
	return ret, rdata
end

function global_huodong.check_ljcz(main_data)
	local t = main_data.huodong.jieduan_leiji
	if t then t = t.sub_id end
	local data = rawget(main_data.huodong, "jieduan_leiji")
	local ret, rdata = check_huodong_data("ljcz", data, main_data)
	if ret == 2 then
		rdata.total_money = 0
	end
	if ret == 3 then
		for k,v in ipairs(data.reward_list) do
			local t = v.item_list[1]
			v.item_list = rdata[k].item_list
		end
		rdata = data
	elseif ret ~= 0 then
		rawset(main_data.huodong, "jieduan_leiji", rdata)
	end
	return ret, rdata
end

function global_huodong.check_dbcz(main_data)
	local t = main_data.huodong.meiri_danbi
	if t then t = t.sub_id end
	local data = rawget(main_data.huodong, "meiri_danbi")
	local ret, rdata = check_huodong_data("dbcz", data, main_data)
	if ret == 3 then
		for k,v in ipairs(data.reward_list) do
			local t = v.item_list[1]
			v.item_list = rdata[k].item_list
		end
		rdata = data
	elseif ret ~= 0 then
		rawset(main_data.huodong, "meiri_danbi", rdata)
	end
	return ret, rdata
end

function global_huodong.check_xffl(main_data)
	local t = main_data.huodong.meiri_xiaofei
	if t then t = t.sub_id end
	local data = rawget(main_data.huodong, "meiri_xiaofei")
	local ret, rdata = check_huodong_data("xffl", data, main_data)
	if ret == 2 then
		rdata.total_money = 0
	end
	if ret == 3 then
		for k,v in ipairs(data.reward_list) do
			local t = v.item_list[1]
			v.item_list = rdata[k].item_list
		end
		rdata = data
	elseif ret ~= 0 then
		rawset(main_data.huodong, "meiri_xiaofei", rdata)
	end
	return ret, rdata
end

function global_huodong.check_ljxffl(main_data)
	local t = main_data.huodong.leiji_xiaofei
	if t then t = t.sub_id end
	local data = rawget(main_data.huodong, "leiji_xiaofei")
	local ret, rdata = check_huodong_data("ljxffl", data, main_data)
	if ret == 2 then
		rdata.total_money = 0
	end
	if ret == 3 then
		for k,v in ipairs(data.reward_list) do
			local t = v.item_list[1]
			v.item_list = rdata[k].item_list
		end
		rdata = data
	elseif ret ~= 0 then
		rawset(main_data.huodong, "leiji_xiaofei", rdata)
	end
	return ret, rdata
end

function global_huodong.check_login(main_data)
	local t = main_data.huodong.login
	if t then t = t.sub_id end
	local data = rawget(main_data.huodong, "login")
	local ret, rdata = check_huodong_data("lxdl", data, main_data)
	if ret == 3 then
		for k,v in ipairs(data.reward_list) do
			local t = v.item_list[1]
			v.item_list = rdata[k].item_list
		end
		rdata = data
	elseif ret ~= 0 then
		rawset(main_data.huodong, "login", rdata)
	end
	return ret, rdata
end

function global_huodong.check_new_level(main_data)
	local t = main_data.huodong.new_level
	if t then t = t.sub_id end
	local data = rawget(main_data.huodong, "new_level")
	local ret, rdata = check_huodong_data("new_level", data, main_data)
	if ret == 3 then
		for k,v in ipairs(data.reward_list) do
			local t = v.item_list[1]
			v.item_list = rdata[k].item_list
		end
		rdata = data
	elseif ret ~= 0 then
		rawset(main_data.huodong, "new_level", rdata)
	end
	return ret, rdata
end

function global_huodong.check_duihuan(main_data)
	local huodong = global_huodong.get_huodong(main_data, "duihuan")
	return huodong
end

-- 充值翻倍
function global_huodong.check_czdb(main_data)
	local t = main_data.huodong.czdb
	if t then t = t.sub_id end
	local data = rawget(main_data.huodong, "czdb")
	local ret, rdata = check_huodong_data("czdb", data, main_data)
	if ret ~= 0 then
		rawset(main_data.huodong, "czdb", rdata)
	end
	return ret, rdata
end
--这里处理充值翻倍相关的检测
--如果存在extinfo，则是获取这一档的充值充值id，否则是获取全部的充值id
function global_huodong.get_czlist(main_data, czreqidx)
	local huodong = global_huodong.get_huodong(main_data, "czdb")
	local czdb = nil
	local czdb_data = nil
	--是否存在充值活动
	if huodong then czdb = huodong.detail end
	if czdb then
		-- 这里获取充值活动数据
		local t = main_data.huodong.czdb
		if t then t = t.sub_id end
		czdb_data = rawget(main_data.huodong, "czdb")
		if czdb_data and czdb_data.sub_id ~= huodong.sub_id then czdb_data = nil end
	end
	
	local list = {}
	local pid = main_data.platform
	local t = main_data.ext_data.real_money
	-- 获取充值数据
	local chongzhi_list = rawget(main_data.ext_data, "chongzhi_list")
	local list_len = 0
	if chongzhi_list then
		t = chongzhi_list[1]
		list_len = rawlen(chongzhi_list)
	end

	for k,v in ipairs(Recharge_conf.index) do
		local conf = Recharge_conf[v]
		if pid ~= 173 or conf.Android == 0 then
			--这里要判断实际的充值档数
			local czidx = math.floor((v - 60000000) / 10000)
			if czreqidx == nil or czreqidx == 0 or czreqidx == czidx then
				--这一档没有充过，显示首充
				if czidx > list_len or chongzhi_list[czidx] == 0 then
					if v % 10000 == 1 then
						table.insert(list, v)
					end
				else
					-- 如果这一档在活动中，则只加活动档
					local done = false
					if czdb then
						for k1,v1 in ipairs(czdb.list) do
							if math.floor((v1.RechargeID - 60000000) / 10000) == czidx then
								done = true
								if v == v1.RechargeID then
									local cur_num = 0
									if czdb_data  then cur_num = czdb_data.reward_list[k1].use_num end
									if cur_num < czdb.reset_num then
										table.insert(list, v)
									else
										table.insert(list, chongzhi_list[czidx])
										-- 如果当前活动次数已用完，则显示普通充值档
									end
								end
							end
						end
					end
					-- 不在活动中，则返回当前可充档
					if not done then
						if v == chongzhi_list[czidx] then
							table.insert(list, v)
						end
					end
				end
			end
		end
	end
	return list
end

function global_huodong.check_tianji(main_data)
	local t = main_data.huodong.tianji
	if t then t = t.sub_id end
	local data = rawget(main_data.huodong, "tianji")
	local ret, rdata = check_huodong_data("tianji", data, main_data)
	if ret == 3 then
		for k,v in ipairs(data.reward_list) do
			--local t = v.item_list[1]
			v.item_list = rdata[k].item_list
		end
		rdata = data
	elseif ret ~= 0 then
		rawset(main_data.huodong, "tianji", rdata)
		if not rawget(main_data, "tianji")then main_data.tianji = {} end
		main_data.tianji.totalnum = 0
		main_data.tianji.rewardsflag = {}
	end
	return ret, rdata
end

function global_huodong.check_limitshop(main_data)
	local t = main_data.huodong.limitshop
	if t then t = t.sub_id end
	local huodong = global_huodong.get_huodong(main_data,"limitshop")
	local data = rawget(main_data.huodong, "limitshop")
	local ret = 0
	
	if data and huodong then
		LOG_INFO("data:"..data.sub_id .. " huodong:"..huodong.sub_id)
	end
	if (not huodong) and data then
		ret = 1
		data = nil
	elseif (data and huodong and  huodong.sub_id ~= data.sub_id)--新活动
		or ((not data) and huodong)--创建活动
		then
		if data and huodong then
			LOG_INFO("data:"..data.sub_id .. " huodong:"..huodong.sub_id)
		end
		local reward_list = clonetab(huodong.reward_list)
		local tdata = {
			reward_list = reward_list,
			sub_id = huodong.sub_id
		}

		rawset(main_data,"limitshop", {}) 

		for k,v in ipairs(reward_list) do
			table.insert(main_data.limitshop, 0)
		end

		ret = 3
		data = tdata
	else
	end
	if ret ~= 0 then
		rawset(main_data.huodong, "limitshop", data)
	end
	return ret, data
end

--ret=0 这个date有效
--ret=1 这个date要清掉，失效了且没有新的数据
--ret=2 返回了一个新的date。可能是原来没有date，现在有，也可能是原来的失效了，现在有
function global_huodong.check_day7(main_data)
	local huodong = global_huodong.get_huodong(main_data,"7day")
	local t = main_data.huodong.day7
	if t then t = t.day_id end
	local data = rawget(main_data.huodong, "day7")
	local ret = 0
	if (not huodong) and data then
		ret = 1
		data = nil
	elseif (data and huodong and data.ver == 0) then
		local t_conf_list = {}
		for k,v in ipairs(LoginEvent_conf.index) do
			local conf = LoginEvent_conf[v]
			if conf.ACTIVITY_ID == huodong.act_id then
				local conf_list = {}
				local t = {conf_list = conf_list}
				table.insert(t_conf_list, t)
				local k = 1
				while conf.REWARD[k] do
					local item = {id = conf.REWARD[k], num = conf.REWARD[k + 1]}
					table.insert(conf_list, item)
					k = k + 2
				end
			end
		end
		data.ver = huodong.sub_id
		data.conf_list = t_conf_list
		ret = 3
	elseif (data and huodong and  huodong.sub_id ~= data.ver)--新活动
		or ((not data) and huodong)--创建活动
		then
		local reward_list = clonetab(huodong.reward_list)
		local tdata = {
			day_id = 1,
			gift_list = {0,0,0,0,0,0,0},
			conf_list = reward_list,
			ver = huodong.sub_id
		}
		ret = 2
		data = tdata
	else
	end
	if ret ~= 0 then
		rawset(main_data.huodong, "day7", data)
	end
	return ret, data
end

function global_huodong.check_level(main_data)
	local huodong = global_huodong.get_huodong(main_data,"level")
	local t = main_data.huodong.level_gift
	if t then t = t.ver end
	local data = rawget(main_data.huodong, "level_gift")
	local ret = 0
	if (not huodong) and data then
		ret = 1
		data = nil
	elseif (data and huodong and data.ver == 0) then
		for k,v in ipairs(data.entry_list) do
			local conf = LevelEvent_conf[560010000 + k]
			if conf.ACTIVITY_ID == huodong.act_id then
				local conf_list = {}
				v.conf_list = conf_list
				local k = 1
				while conf.REWARD[k] do
					local item = {id = conf.REWARD[k], num = conf.REWARD[k + 1]}
					table.insert(conf_list, item)
					k = k + 2
				end
			end
		end
		data.ver = huodong.sub_id
		ret = 3
	elseif (data and huodong and  huodong.sub_id ~= data.ver)--新活动
		or ((not data) and huodong)--创建活动
		then
		local reward_list = clonetab(huodong.reward_list)
		local tdata = {
			entry_list = reward_list,
			ver = huodong.sub_id
		}
		ret = 2
		data = tdata
	else
	end
	if ret ~= 0 then
		rawset(main_data.huodong, "level_gift", data)
	end
	return ret, data
end

function global_huodong.check_new_task(main_data)
	local huodong = global_huodong.get_huodong(main_data,"new_task")
	local t = main_data.huodong.new_task_list
	if t then t = t.open_day end
	local data = rawget(main_data.huodong, "new_task_list")
	local ret = 0
	if (not huodong) and data then
		ret = 1
		data = nil
	elseif (data and huodong and data.ver == 0) then
		data.ver = huodong.sub_id
		for k,v in ipairs(data.event_list) do
			local conf_list = {}
			v.conf_list = conf_list
			local event_conf = NewEvent_conf[v.event_id]
			if event_conf.ACTIVITY_ID == huodong.act_id then
				local k = 1
				while event_conf.REWARD[k] do
					local item = {id = event_conf.REWARD[k], num = event_conf.REWARD[k + 1]}
					table.insert(conf_list, item)
					k = k + 2
				end
			end
		end
		ret = 3
	elseif (data and huodong and  huodong.sub_id ~= data.ver)--新活动
		or ((not data) and huodong)--创建活动
		then
		local reward_list = clonetab(huodong.reward_list)
		local tdata = {
			event_list = reward_list,
			ver = huodong.sub_id,
			open_day = 1,
			regist_dayid = get_dayid_from(os.time()),
		}
		ret = 2
		data = tdata
	else
	end
	if ret ~= 0 then
		rawset(main_data.huodong, "new_task_list", data)
	end
	return ret, data
end

function global_huodong.reflesh_hongdian_flag(main_data, type, flag)
	local idx = type
	local t = main_data.ext_data.huodong.dump
	t = rawget(main_data.ext_data.huodong, "hongdian_list")
	if not t then
		t = {}
		rawset(main_data.ext_data.huodong, "hongdian_list", t)
	end
	local find = false
	for k,v in ipairs(t) do
		if v.act_id == idx then
			find = true
			v.flag = flag
			break
		end
	end
	if not find then
		table.insert(t, {act_id = idx, flag = flag})
	end
end

function global_huodong.reflesh_hongdian_flag(main_data, type, flag)
	local idx = type
	local t = main_data.ext_data.huodong.dump
	t = rawget(main_data.ext_data.huodong, "hongdian_list")
	if not t then
		t = {}
		rawset(main_data.ext_data.huodong, "hongdian_list", t)
	end
	local find = false
	for k,v in ipairs(t) do
		if v.act_id == idx then
			find = true
			v.flag = flag
			break
		end
	end
	if not find then
		table.insert(t, {act_id = idx, flag = flag})
	end
end

function global_huodong.get_hongdian_flag(main_data, type, flag)
	local idx = type
	local t = rawget(main_data.ext_data.huodong, "hongdian_list")
	if not t then
		flag = 0 
		return
	end
	local find = false
	for k,v in ipairs(t) do
		if v.act_id == idx then
			find = true
			flag = v.flag
			break
		end
	end
	if not find then
		flag = 0
	end
end

function global_huodong.check_chongzhi(main_data)
	local huodong = global_huodong.get_huodong(main_data,"chongzhi")
	local t = main_data.huodong.chongzhi
	if t then t = t.sub_id end
	local data = rawget(main_data.huodong, "chongzhi")
	local ret = 0
	if (not huodong) and data then
		ret = 1
		data = nil
	elseif (data and huodong and  huodong.sub_id ~= data.sub_id)--新活动
		or ((not data) and huodong)--创建活动
		then
		local reward_level = {}
		for k,v in ipairs(huodong.reward_list) do
			table.insert(reward_level, 0)
		end
		local tdata = {
			sub_id = huodong.sub_id,
			total_money = 0,
			reward_level = reward_level,
		}
		ret = 2
		data = tdata
	else
	end
	if ret ~= 0 then
		rawset(main_data.huodong, "chongzhi", data)
	end
	return ret, data
end

function global_huodong.check_qhaoxia(main_data)
	local t = main_data.huodong.qhaoxia
	if t then t = t.sub_id end
	local huodong = global_huodong.get_huodong(main_data,"qhaoxia")
	local data = rawget(main_data.huodong, "qhaoxia")
	local ret = 0
	
	if (not huodong) and data then
		ret = 1
		data = nil
	elseif (data and huodong and  huodong.sub_id ~= data.sub_id)--新活动
		or ((not data) and huodong)--创建活动
		then
		
		local reward_list = clonetab(huodong.reward_list)
		local tdata = {
			reward_list = reward_list,
			sub_id = huodong.sub_id,
			haoxiainfo = {},
			rank_reward = huodong.rank_reward,
		}

		tdata.haoxiainfo.hotid = huodong.hotid
		tdata.haoxiainfo.next_chou_time = os.time()
		tdata.haoxiainfo.interval = huodong.interval
		tdata.haoxiainfo.point = 0
		tdata.haoxiainfo.tencount = 0

		ret = 2
		data = tdata
	else
	end
	if ret ~= 0 then
		rawset(main_data.huodong, "qhaoxia", data)
	end
	return ret, data
end


return global_huodong