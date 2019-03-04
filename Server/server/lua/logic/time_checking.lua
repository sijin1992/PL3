local core_user = require "core_user_funcs"
local core_send_mail = require "core_send_mail"
local core_task = require "core_task"


local function get_dayid_from1(date, hour)
	local dayid = date.year * 1000 + date.yday
	if hour then
		if date.hour < hour then
			local t = os.time({year = date.year, month = date.month, day = date.day - 1})
			local t1 = os.date("*t", t)
			dayid = t1.year * 1000 + t1.yday
		end
	end
	return dayid
end

local function get_dayid_from(time, hour, minute)
	local t = time + 28800
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

local function special_stage(time)
	local t_tab = os.date("*t", time)
	local wday = t_tab.wday
	if wday == 1 then
		return 1,1,1
	elseif wday == 2 or wday == 5 then
		return 1,0,0
	elseif wday == 3 or wday == 6 then
		return 0,1,0
	else
		return 0,0,1
	end
end

local function update_at_0am_1(main_data, dayid)
	local last_0am_day1 = main_data.timestamp.last_0am_day1
	if last_0am_day1 == 0 then 
		last_0am_day1 = main_data.timestamp.last_0am_day 
	end
	local ret = false
	if last_0am_day1 ~= dayid then
		main_data.timestamp.last_0am_day1 = dayid
		--单日充值
		local s, t = global_huodong.check_drljcz(main_data)
		if t then
			for k,v in ipairs(t.reward_list) do
				local t1 = v.status
				v.status = 0
			end
			t.total_money = 0
		end
		--单笔充值
		local s, t = global_huodong.check_dbcz(main_data)
		if t then
			for k,v in ipairs(t.reward_list) do
				local t1 = v.num
				v.num = 0
			end
		end
		--消费
		local s, t = global_huodong.check_xffl(main_data)
		if t then
			for k,v in ipairs(t.reward_list) do
				local t1 = v.status
				v.status = 0
			end
			t.total_money = 0
		end
		
		-- 更新双倍充值
		local r, d = global_huodong.check_czdb(main_data)
		if r == 0 and d then
			local czhuodong = global_huodong.get_huodong(main_data, "czdb")
			if czhuodong.detail.reset_type == 1 then
				for k,v in ipairs(d.reward_list) do
					local t = v.use_num
					v.use_num = 0
				end
			end
		end
		
		local rt, st = global_huodong.check_tianji(main_data)
		if st then
			--print("----------------------------------init tianji!")
			if not rawget(main_data,"tianji") then
				main_data.tianji = {}
				main_data.tianji.totalnum = 0
				main_data.tianji.rewardsflag = {}       
			end
			main_data.tianji.bagnum = 0
			main_data.tianji.vipnum = 0
			global_huodong.reflesh_hongdian_flag(main_data, 65001, 5)
		else
			if rawget(main_data,"tianji") then
				LOG_INFO("TIANJI|CLEAR|".." totalnum:"..main_data.tianji.totalnum)
				main_data.tianji = {}
			end
		end

		if rawget(main_data, "mineinfo") then
			main_data.mineinfo.searchtimes = 0
		end

		if main_data.lead.level >= 40 then
			if rawget(main_data, "mineinfo") then
				main_data.mineinfo.getjingli = 0 
			end
		end

		if main_data.lead.level >= 35 then
			if rawget(main_data.PVE, "haoxiainfo") then
				main_data.PVE.haoxiainfo.fightnum = 0
				local vipnum = 0
				if main_data.vip_lev >= 5 then
					vipnum = 1
				end
				global_huodong.reflesh_hongdian_flag(main_data, 10001, 2+vipnum)
			end
		end

		ret = true
	end
	return ret
end

local function update_at_0am(main_data, dayid, mail_list)
	local last_0am_day = main_data.timestamp.last_0am_day
	local ret = update_at_0am_1(main_data, dayid)
	if last_0am_day ~= dayid then
		main_data.timestamp.last_0am_day = dayid
		--登录
		local s, t = global_huodong.check_login(main_data)
		if t and s ~= 2 then
			local hd = global_huodong.get_huodong(main_data, "lxdl")
			local btime = 0
			if hd then btime = hd.begin_time end
			--开始第一天，不需要刷新。其实一天是86400秒，但只要规避掉活动开始的前6分钟即可，所以随便填了个80000秒
			if (os.time() - btime) > 80000 then
				for k,v in ipairs(t.reward_list) do
					if v.status == 0 then
						--开最近的一个
						v.status = 1
						break
					end
				end
			end
		end
		
		-- 刷新登录次数
		t = main_data.ext_data.total_login
		main_data.ext_data.total_login = t + 1
		core_task.check_chengjiu_total_login(nil, main_data)
		
		-- 更新7日奖励
		local r, d = global_huodong.check_day7(main_data)
		if r == 0 and d then
			if d.day_id < 7 then d.day_id = d.day_id + 1 end
		end
		
		r,d = global_huodong.check_new_task(main_data)
		if r == 0 and d then
			t = d.event_list[1].event_id
			t = rawlen(d.event_list)
			if d.open_day < t then d.open_day = d.open_day + 1 end
		end
		--更新冲级礼包
		--if not global_huodong.get_huodong(main_data,"level") then
		  --  rawset(main_data.huodong, "level_gift", nil)
		--end
		
		core_send_mail.send_haojiao_mail(main_data, mail_list)
		
		core_send_mail.send_huodong_mail_daily(main_data, mail_list, dayid)
		
		ret = true
	end
	return ret
end

--为了解决重复包含问题，就复制了一份这个代码。以后要好好规划包含层级
local function reflesh_m2g(num, money, level, vip_rate, vip_crit)
	local base = 20300 + level * 75 + (num - 1) * 1000
	local min = base - 500
	local max = base + 499
	local real = math.random(min,max)
	real = math.floor(real * vip_rate / 100)
	
	local crit_base = {200, 40, 30, 10, 10}
	for k,v in ipairs(crit_base) do
		crit_base[k] = math.floor(v * vip_crit / 100)
	end
	local t = math.random(1000)
	local baoji = 1
	for k,v in ipairs(crit_base) do
		if t <= v then
			if k == 1 then baoji = 2
			elseif k == 2 then baoji = 3
			elseif k == 3 then baoji = 5
			elseif k == 4 then baoji = 8
			else baoji = 10 end
			break
		else
			t = t - v
		end
	end
	
	local ret = {
		money = money,
		gold = real,
		baoji = baoji,
		num = num
	}
	return ret
end

local function update_at_5am(user_info, dayid, mail_list)
	local last_5am_day = user_info.timestamp.last_5am_day
	local ret = false
	if(last_5am_day ~= dayid) then
		--因为体力不再是5点重置了，所以这一段全部注释掉
		--local max_hp = core_user.max_hp(user_info.lead.level)
		--if max_hp > user_info.tili then
		--    local add_tili = max_hp - user_info.tili
		--    core_user.get_item(191040211, add_tili, user_info, 1)
		--end
		--user_info.timestamp.last_reflesh_tili = os.time()
		
		local t = user_info.PVP.today_count
		-- 重置每日挑战购买次数
		user_info.PVP.today_count = 0
		user_info.PVP.today_reset_count = 0
		user_info.timestamp.get_tili = 0
		user_info.timestamp.last_5am_day = dayid
		
		user_info.timestamp.money2hp = 0
		
		-- 刷新点石成金
		local vip_rate = core_vip.money2gold_rate(user_info)
		local vip_crit = core_vip.money2gold_crit(user_info)
		local m2g = reflesh_m2g(1, 50, user_info.lead.level, vip_rate, vip_crit)
		local t = user_info.money2gold.m2g_num
		user_info.money2gold.m2g_num = 0
		user_info.money2gold.last_money = m2g.money
		user_info.money2gold.last_gold = m2g.gold
		user_info.money2gold.last_baoji = m2g.baoji
		user_info.money2gold.last_num = m2g.num
		
		-- 金币抽奖
		t = user_info.choujiang.today_gold_num
		user_info.choujiang.today_gold_num = 0
		user_info.choujiang.next_gold_time = 0
		
		-- pve2重置次数
		t = user_info.PVE.pve2.reset_num
		user_info.PVE.pve2.reset_num = 0
		
		-- pve武林之巅重置
		t = user_info.PVE.trial_info.need_update
		t = rawget(user_info.PVE, "trial_info")
		if t then
			local t1 = t.need_update
			t.need_update = 1
		end
		
		t = user_info.ext_data.yueka.left_idx
		local yueka = rawget(user_info.ext_data, "yueka")
		local has_yueka = false
		if yueka then
			if dayid >= yueka.last_day then rawset(user_info.ext_data, "yueka", nil)
			else
				yueka.left_idx = yueka.last_day - dayid
				has_yueka = true
			end
		end
		
		-- 每日任务重置
		t = user_info.daily.daily_list[1].id
		for k,v in ipairs(user_info.daily.daily_list) do
			if v.id == 3106001 then
				if has_yueka then v.status = 1
				else v.status = 0 end
			elseif v.id == 3111001 then
				if user_info.ext_data.zsyk == 1 then v.status = 1
				else v.status = 0 end
			elseif v.id == 3107001 then
				v.status = 1
				v.flag = 0
			elseif v.id > 3107001 and v.id < 3107099 then
				v.status = 3
				v.flag = 0
			else
				t = v.status
				v.status = 0
				v.flag = 0
			end
		end

		-- 重置pve各个副本
		t = user_info.PVE.fortress_list[1].id
		for k,v in ipairs(user_info.PVE.fortress_list) do
			for k1,v1 in ipairs(v.stage_list) do
				for k2,v2 in ipairs(v1.difficulty_list) do
					t = v2.today_pass_num
					v2.today_pass_num = 0
				end
			end
		end
		
		t = user_info.PVE.jingying[1].id
		for k,v in ipairs(user_info.PVE.jingying) do
			for k1,v1 in ipairs(v.stage_list) do
				t = v1.today_pass_num
				v1.today_pass_num = 0
				v1.today_reset_num = 0
			end
		end
		
		-- 重置pve特殊关卡
		for k,v in ipairs(user_info.PVE.special_stage) do
			t = v.today_pass_num
			v.today_pass_num = 0
			v.today_reset_num = 0
		end
		local sw1,sw2,sw3 = special_stage(os.time())
		t = user_info.ext_data.switch[1]
		user_info.ext_data.switch[1] = sw1
		user_info.ext_data.switch[2] = sw2
		user_info.ext_data.switch[3] = sw3
		
		-- 签到活动
		local qiandao_data = global_huodong.get_huodong(user_info,"qiandao")
		t = user_info.huodong.qiandao.sub_id
		local qiandao = rawget(user_info.huodong, "qiandao")
		if qiandao == nil then
			rawset(user_info.huodong, "qiandao", {sub_id = qiandao_data.sub_id, day_idx = 1, status = 0})
		elseif qiandao_data.sub_id ~= qiandao.sub_id then
			qiandao.sub_id = qiandao_data.sub_id
			qiandao.day_idx = 1
			qiandao.status = 0
		elseif qiandao.status ~= 0 then
			qiandao.day_idx = qiandao.day_idx + 1
			qiandao.status = 0
		end
		t = user_info.ext_data.huodong.qiandao
		user_info.ext_data.huodong.qiandao = 1
		
		local vip_goods_list = rawget(user_info, "vip_shoplist")
		if vip_goods_list then
			for k,v in ipairs(vip_goods_list.goods_list) do
				t = v.buy_num
				v.buy_num = 0
			end
		end
		
		-- 奇遇重置
		local qiyu = core_user.get_qiyu(user_info)
		t = qiyu.today_tjhf
		qiyu.today_tjhf = 0
		
		-- 公会重置
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

		ret = true
	end
	return ret
end

local function update_at_12am(user_info, dayid, mail_list)
	local last_12am_day = user_info.timestamp.last_12am_day
	local ret = false
	if last_12am_day ~= dayid then
		if ext_mail then
			core_send_mail.send_ext_mail(user_info, mail_list)
		end
		user_info.timestamp.last_12am_day = dayid
		ret = true
	end
	return ret
end

local function update_at_9pm(user_info, dayid, item_list, mail_list, rank_idx)
	local last_active_day = user_info.timestamp.last_9pm_day
	local ret = false
	local begin_day = last_active_day
	
	if begin_day < dayid then
		if rank_idx <= 10000 then
			local t_date = os.date("*t")
			t_date.hour = 21
			t_date.min = 0
			t_date.sec = 0
			local t_time = os.time(t_date)
			local daylist = {}
			local t_dayid = get_dayid_from(t_time, 21)
			if t_dayid == dayid then table.insert(daylist, t_time) end
			while true do
				t_time = t_time - 86400
				t_dayid = get_dayid_from(t_time, 21)
				if t_dayid == begin_day then break
				else table.insert(daylist, t_time) end
			end
			core_send_mail.send_pvp_reward_mail(rank_idx, daylist, user_info, item_list, mail_list)
			LOG_INFO(string.format("9pm|%s|%d", user_info.user_name, rank_idx))
		end
		
		-- 刷新纷争商店
		local shop_list = core_user.reflesh_shopping_list(100025)
		local t = user_info.PVE.pve2.pve2_gold
		user_info.PVE.pve2.shopping_list = shop_list
		
		local shop_list1 = core_user.reflesh_shopping_list(100014)
		local t = user_info.PVP.reputation
		user_info.PVP.shopping_list = shop_list1
		
		local group_data = rawget(user_info, "group_data")
		if group_data then
			local t = group_data.groupid
			if t ~= "" then
				local shop_list1 = core_user.reflesh_shopping_list(100164)
				rawset(group_data, "shopping_list", shop_list1)
			end
		end
		
		user_info.timestamp.last_9pm_day = dayid
		ret = true
	end

	
	return ret
end

local function update_tili_per_6min(main_data, type, mail_list, bag_list)
	local ret = false
	local nowtime = os.time()
	local lasttime = main_data.timestamp.last_reflesh_tili
	if lasttime == 0 then lasttime = nowtime end
	local difftime = nowtime - lasttime
	--assert(difftime >= 0)
	if difftime <= 0 then
		difftime = 0
		main_data.timestamp.last_reflesh_tili = nowtime
	end
	local diff6min = math.floor(difftime / 360)
	if diff6min > 0 then
		ret = true
		main_data.timestamp.last_reflesh_tili = diff6min * 360 + lasttime
		local max_hp = core_user.max_hp(main_data.lead.level)
		local nowhp = main_data.tili
		if nowhp < max_hp then
			local newhp = nowhp + diff6min
			if newhp > max_hp then diff6min = max_hp - nowhp end
			core_user.get_item(191040211, diff6min, main_data, 2)
		end
	end
	
	if type == 1 then
		--重发之前错误的充值等请求
		local redo = redo_list.get_redo_list(main_data.user_name)
		if redo then
			if redo.recharge_list then
				for k,v in ipairs(redo.recharge_list) do
					local real_bag_list={item_list={}}
					if bag_list then
						real_bag_list = bag_list
					end
					core_recharge(main_data, real_bag_list, v.money, v.item_id, v.fake, v.selfdef, v.gamemoney, v.basemoney, v.monthcard)
				end
			end
			if redo.remail_list then
				for k,v in ipairs(redo.remail_list) do
					core_send_mail.send_mail(main_data, mail_list, v)
				end
			end
			redo_list.clear_redo_list(main_data.user_name)
		end
		
		
		--处理全服公告
		local gmail_list = svr_info.get_gmail_list()
		local t = main_data.ext_data.gmail
		local max_gmail = 0
		for k,v in ipairs(gmail_list) do
			if t < v.tid then
				if max_gmail < v.tid then max_gmail = v.tid end
				if (v.reg_time and v.reg_time ~= 0 and main_data.timestamp.regist_time > v.reg_time) 
					or (v.vip_limit and v.vip_limit ~= 0 and main_data.vip_lev < v.vip_limit) 
					or (v.lev_limit and v.lev_limit ~= 0 and main_data.lead.level < v.lev_limit) then
				else
					core_send_mail.send_mail(main_data, mail_list, v)
				end
			end
		end
		if t < max_gmail then
			main_data.ext_data.gmail = max_gmail
		end
		
		--定期检查各种活动
		--单日充值
		local s, t = global_huodong.check_drljcz(main_data)
		if s ~= 0 then ret = true end
		if t then
			local tt = 0
			for k,v in ipairs(t.reward_list) do
				if v.status == 0 and t.total_money >= v.conf then tt = tt + 1 end
			end
			main_data.ext_data.huodong.drljcz = tt
			global_huodong.reflesh_hongdian_flag(main_data, 57001, tt)
		else
			main_data.ext_data.huodong.drljcz = 0
			global_huodong.reflesh_hongdian_flag(main_data, 57001, 0)
		end
		--阶段充值
		local s, t = global_huodong.check_ljcz(main_data)
		if s ~= 0 then ret = true end
		if t then
			local tt = 0
			for k,v in ipairs(t.reward_list) do
				if v.status == 0 and t.total_money >= v.conf then tt = tt + 1 end
			end
			main_data.ext_data.huodong.ljcz = tt
			global_huodong.reflesh_hongdian_flag(main_data, 60001, tt)
		else
			main_data.ext_data.huodong.ljcz = 0
			global_huodong.reflesh_hongdian_flag(main_data, 60001, 0)
		end
		--单笔充值
		local s, t = global_huodong.check_dbcz(main_data)
		if s ~= 0 then ret = true end
		if t then
			local tt = 0
			for k,v in ipairs(t.reward_list) do
				tt = tt + v.reward_num
			end
			main_data.ext_data.huodong.dbcz = tt
			global_huodong.reflesh_hongdian_flag(main_data, 56001, tt)
		else
			main_data.ext_data.huodong.dbcz = 0
			global_huodong.reflesh_hongdian_flag(main_data, 56001, 0)
		end
		--消费
		local s, t = global_huodong.check_xffl(main_data)
		if s ~= 0 then ret = true end
		if t then
			local tt = 0
			for k,v in ipairs(t.reward_list) do
				if v.status == 0 and t.total_money >= v.conf then tt = tt + 1 end
			end
			main_data.ext_data.huodong.xffl = tt
			global_huodong.reflesh_hongdian_flag(main_data, 59001, tt)
		else
			main_data.ext_data.huodong.xffl = 0
			global_huodong.reflesh_hongdian_flag(main_data, 59001, 0)
		end
		
		local s, t = global_huodong.check_ljxffl(main_data)
		if s ~= 0 then ret = true end
		if t then
			local tt = 0
			for k,v in ipairs(t.reward_list) do
				if v.status == 0 and t.total_money >= v.conf then tt = tt + 1 end
			end
			global_huodong.reflesh_hongdian_flag(main_data, 67001, tt)
		else
			global_huodong.reflesh_hongdian_flag(main_data, 67001, 0)
		end
		--登录
		local s, t = global_huodong.check_login(main_data)
		if s ~= 0 then ret = true end
		if t then
			local tt = 0
			for k,v in ipairs(t.reward_list) do
				if v.status == 1 then tt = tt + 1 end
			end
			main_data.ext_data.huodong.lxdl = tt
			global_huodong.reflesh_hongdian_flag(main_data, 58001, tt)
		else
			main_data.ext_data.huodong.lxdl = 0
			global_huodong.reflesh_hongdian_flag(main_data, 58001, 0)
		end
		
		--新服登录
		local s, t = global_huodong.check_day7(main_data)
		if s ~= 0 then ret = true end
		if t then
			local tt = 0
			for k = 1, t.day_id do
				if t.gift_list[k] == 0 then tt = tt + 1 end
			end
			main_data.ext_data.huodong.denglu = tt
			global_huodong.reflesh_hongdian_flag(main_data, 53001, tt)
		else
			main_data.ext_data.huodong.denglu = 0
			global_huodong.reflesh_hongdian_flag(main_data, 53001, 0)
		end
		
		--新等级礼包
		local s, t = global_huodong.check_new_level(main_data)
		if s ~= 0 then ret = true end
		if t then
			local cur_level = main_data.lead.level
			local tt = 0
			for k,v in ipairs(t.reward_list) do
				if v.status == 0 and cur_level >= v.level then tt = tt + 1 end
			end
			global_huodong.reflesh_hongdian_flag(main_data, 63001, tt)
		else
			global_huodong.reflesh_hongdian_flag(main_data, 63001, 0)
		end
		
		--定期检查藏剑山庄--藏剑山庄过期要发邮件？
		local t = main_data.huodong.cangjian.last_sub
		local cangjian = rawget(main_data.huodong, "cangjian")
		local cangjian_huodong = global_huodong.get_huodong(main_data,"cangjian")
		if cangjian and t ~= 0 and ((not cangjian_huodong) or cangjian_huodong.sub_id ~= t) then
			local rank_idx = -1
			rank_idx = cjsz_rank.get_last_rank(main_data.user_name, t)
			if rank_idx ~= -1 then
				core_send_mail.send_cjsz_mail(main_data, rank_idx, mail_list, {sub_id = t})
			end
			cangjian.last_sub = 0
			ret = true
		end
		
		local t = main_data.ext_data.huodong.caishen
		--刷新财神到的红点
		local csd = global_huodong.get_huodong(main_data,"csd")
		if csd then
			local csd_level = main_data.huodong.caishendao
			if csd_level > 0 then
				local t = 0
				for k = csd_level, 100 do
					local conf = Activity_Cai_conf[k]
					if not conf then break end
					if conf.Grade <= main_data.money then t = t + 1
					else break end
				end
				main_data.ext_data.huodong.caishen = t
			else
				main_data.ext_data.huodong.caishen = 0
			end
		else
			main_data.ext_data.huodong.caishen = 0
		end
		
		--检测冲级活动状态
		local r,d = global_huodong.check_level(main_data)
		local lev = main_data.lead.level
		if d then
			t = main_data.ext_data.huodong.chongji
			t = 0
			for k, v in ipairs(d.entry_list) do
				if v.level <= lev
					and v.status == 0 then
					t = t + 1
				end
			end
			main_data.ext_data.huodong.chongji = t
		else
			main_data.ext_data.huodong.chongji = 0
		end
		--刷新藏剑山庄红点
		local cangjian_data = global_huodong.get_huodong(main_data,"cangjian")
		if cangjian_data then
			local totalsw = cjsz_rank.get_global_sw()
			local cang_quan = global_huodong.get_cur_cang_quan(cangjian_data)
			assert(cang_quan)
			local t = main_data.huodong.cangjian.next_time
			local cangjian = rawget(main_data.huodong, "cangjian")
			t = 0
			if cangjian then
				-- 已经有藏剑山庄了
				for k,v in ipairs(cang_quan) do
					if v.Devote <= totalsw
						and cangjian.reward_list[k] == 0 then
						t = t + 1
					end
				end
			else
				for k,v in ipairs(cang_quan) do
					if v.Devote <= totalsw then
						t = t + 1
					end
				end
			end
			main_data.ext_data.huodong.cjsz = t
		else
			main_data.ext_data.huodong.cjsz = 0
		end
		--刷新新手豪礼红点
		local t = main_data.huodong.new_task_list.event_list[1]
		local new_task_list = rawget(main_data.huodong, "new_task_list")
		if new_task_list then
			local t = 0
			for k,v in ipairs(new_task_list.event_list) do
				if k > main_data.huodong.new_task_list.open_day then break end
				local finished = true
				for k1,v1 in ipairs(v.task_list) do
					if v1.status == 0 then
						finished = false
						break
					end
				end
				if finished and v.status == 0 then
					t = t + 1
				end
			end
			main_data.ext_data.huodong.xinshou = t
		else
			main_data.ext_data.huodong.xinshou = 0
		end
		--奇遇
		local qiyu_struct = core_user.get_qiyu(main_data)
		core_user.check_qiyu(qiyu_struct.qiyu_list)
		main_data.ext_data.huodong.qiyu = rawlen(qiyu_struct.qiyu_list)
		
		--充值返利红点
		local s, t = global_huodong.check_chongzhi(main_data)
		if s ~= 0 then ret = true end
		if t then
			local huodong = global_huodong.get_huodong(main_data,"chongzhi")
			local tt = 0
			for k,v in ipairs(huodong.reward_list) do
				if t.total_money >= v.amount and t.reward_level[k] == 0 then tt = tt + 1 end
			end
			main_data.ext_data.huodong.czfl = tt
			global_huodong.reflesh_hongdian_flag(main_data, 42101, tt)
		else
			main_data.ext_data.huodong.czfl = 0
			global_huodong.reflesh_hongdian_flag(main_data, 42101, 0)
		end
		
		local need_del = {}
		for k,v in ipairs(mail_list) do
			if v.expiry_stamp ~= 0 and v.expiry_stamp < nowtime then
				table.insert(need_del, k)
			end
		end
		for k = rawlen(need_del), 1, -1 do
			table.remove(mail_list, need_del[k])
		end
		
		robmine.check_hongdian(main_data)
	end
	group_cache.update_user_info(main_data)
	group_cache.check_disband(main_data)
	ret = true
	return ret
end

local time_checking = {
	get_dayid_from = get_dayid_from,
	update_at_0am = update_at_0am,
	update_at_0am_1 = update_at_0am_1,
	update_at_5am = update_at_5am,
	update_at_12am = update_at_12am,
	update_at_9pm = update_at_9pm,
	update_tili_per_6min = update_tili_per_6min,
	special_stage = special_stage,
}

return time_checking