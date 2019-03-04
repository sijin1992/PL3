--门派战
local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert
local core_fight = require "fight"
local kc = require "kyotocabinet"
local core_user = require "core_user_funcs"


--返回时间结构，例如通过t["month"]返回几月 [day min hour wday yday month year sec isdst]
local function get_time_table_from(time)
	local t = os.date("*t", time)
	return t
end

--制作定时秒数
local function make_time_flag(year, month, day, hour, min, sec)
	assert(year and month and day, "year month day need value!")
	local t = {
		year = year,
		month = month,
		day = day,
		hour = 0,
		min = 0,
		sec = 0,
	}
	if hour then
		t.hour = hour
		if min then
			t.min = min
			if sec then
				t.sec = sec
			end
		end
	end
	return os.time(t)
end

local function make_today_time_flag(hour, min, sec)
	local t = get_time_table_from(os.time())
	t.hour = 0
	t.min = 0
	t.sec = 0
	if hour then
		t.hour = hour
		if min then
			t.min = min
			if sec then
				t.sec = sec
			end
		end
	end
	return os.time(t)
end

local NIL = 0
local REG = 1
local MATR_REG = 2
local FIGHTING = 3
local FINISH = 4
local END = 5

local DB_S_NIL = 0      -- db文件不存在
local DB_S_ERR = 1      -- db文件错误
local DB_S_REGOK = 2    -- 报名阶段db文件正常
local DB_S_CLOSE = 3    -- db文件已关闭，等待计算
local DB_S_PKOK = 4     -- 战斗阶段，文件正常。此时db只读
local DB_S_RETRY = 5    -- 文件存在但是有问题，稍后重试

local flag_head = "had"
local flag_rcd = "rcd"
local flag_status = "sta"
local flag_robot = "rob"
local flag_play1 = "pl1"
local flag_play2 = "pl2"
local flag_prep = "prp" --战斗准备阶段
local flag_rcdidx = "rdx"

--玩法起始时间(s),尽量勿改,这样可以保证每个服务器同一届的数据文件名相同
local gstarttime = make_time_flag(2015, 5, 21)
--一轮战斗循环时间(s)
local ginterval = 3600*24
local gpercent = 5/6
local gvalidpercent = 5/8
local gmaster_reg_time = 600 	--会长布阵提交时间
local gt = os.time()
local gfight_time = 300 		--交战时间
local gchangeday = 7			--一届的轮循次数
local G_FIGHT_MAX_TIME = 128	--一次计算的公会交战次数 一次就是1场 2个公会，一次循环就是128场 256个公会
local G_MAX_ROBOT_NUM = 8 		--公会机器人的最大个数
local G_IS_VALID = true

-- for test 内网测试用
--[[
local test = false
if test then
	--玩法起始时间(s)
	gstarttime = make_time_flag(2015, 5, 27)
	--一轮战斗循环时间(s)
	ginterval = 600
	gpercent = 3/10
	gmaster_reg_time = 180
	gfight_time = 60
	gchangeday = 4
end

local test1 = false
if test1 then
	--一轮战斗循环时间(s)
	ginterval = 120
	gpercent = 1/4
	gmaster_reg_time = 30
	gfight_time = 30
end]]

--有效时间百分比
gvalidpercent = gpercent*3/4

family_name = {}
--[[for t in io.lines("../../../bin/logic/main_logic/fn.txt") do
    table.insert(family_name, t)
end--]]

male_name = {}
--[[for t in io.lines("../../../bin/logic/main_logic/mn.txt") do
    table.insert(male_name, t)
end--]]

female_name = {}
--[[for t in io.lines("../../../bin/logic/main_logic/fmn.txt") do
    table.insert(female_name, t)
end--]]

--gdiff为差几届
local gdiff = math.floor((gt - gstarttime)/(ginterval*gchangeday))
--glastUpdateTime 最近一届开始时间（周四0点）
local glastUpdateTime = gstarttime + gdiff*(ginterval*gchangeday)
--print("starttime", gstarttime, "diff", gdiff, "lastupdatetime", glastUpdateTime)

--这届开始时间点的dayid
local gts = math.floor((glastUpdateTime - gstarttime)/ginterval)

local gweek_data = { 
                dayid = gts,
                headinfo = {
                	opentime = gstarttime,
					lastupdatetime = glastUpdateTime,
					interval = ginterval,
					round = 1,
					attendnum = NIL,
            	},
            	prepstatus = 0,
                status = NIL,
                player = {}, -- 淘汰赛,包含了组合信息
				player1 = {}, --四强赛,包含了组合信息
				player2 = {}, --决赛，包含了组合信息
                rcd = {},
                rcd_idx = 0,
                db = kc.DB:new(),
                file = 'mpz' .. gts .. '.kch',
                db_status = DB_S_NIL
        }
--[[
    player{} 门派数组，里面是门派的{MPZNode data}详细见cmd_pvp.proto
    rcd{} 
                    -- rcd:录像列表索引 player:门派列表 status:当前状态
]]

--加载数据
local function load_db(startday, Week_Data, type)
	--print("startday:",startday," type:",type)
    Week_Data.file = 'mpz' .. startday .. '.kch'
    if not Week_Data.db:open(Week_Data.file, type) then
        LOG_ERROR(Week_Data.file.." open err")
        Week_Data.db_status = DB_S_ERR
    else
        local t = tonumber(Week_Data.db:get(flag_status))
        if type == kc.DB.OREADER and t ~= END and t~= FINISH then   -- 只读的kch，读到的状态只能是END or FINISH
            Week_Data.db_status = DB_S_RETRY
            Week_Data.db:close()
        else
            Week_Data.db:iterate(
                function(k1,v1)
                    local flag = string.sub(k1, 1, 3)
                    if flag == flag_status then
                        Week_Data.status = tonumber(v1)
                    elseif flag == flag_prep then
                    	Week_Data.prepstatus = tonumber(v1)
                    elseif flag == flag_rcdidx then
                    	Week_Data.rcd_idx = tonumber(v1)
                    elseif flag == flag_head then
                        local pb = require "protobuf"
                        local d = pb.decode("mpz_head_info", v1)
                        Week_Data.headinfo = d
						local headinfo = Week_Data.headinfo
						--LOG_INFO("mpz|head: lastUpdateTime:"..headinfo.lastupdatetime.." interval:"..headinfo.interval.." round:"..headinfo.round.." attendnum: "..headinfo.attendnum)
                    elseif flag == flag_rcd then
                        local rcd_idx = tonumber(string.sub(k1, 4))
                        --print("load_db|rcd:", rcd_idx)
                        local pb = require "protobuf"
                        --local d = pb.decode("MPZRcd", v1)
                        Week_Data.rcd[rcd_idx] = rcd_idx
					elseif flag == flag_play1 then
                        --print("load_db|player1:", k1)
                        local uid1 = string.sub(k1, 4)
                        local pb = require "protobuf"
                        local d = pb.decode("MPZNode", v1)
                        rawset(Week_Data.player1, uid1, d)
					elseif flag == flag_play2 then
                        --print("load_db|player2:", k1)
                        local uid2 = string.sub(k1, 4)
                        local pb = require "protobuf"
                        local d = pb.decode("MPZNode", v1)
                        rawset(Week_Data.player2, uid2, d)
                    else
                        --print("load_db|player:", k1)
                        local pb = require "protobuf"
                        local d = pb.decode("MPZNode", v1)
                        rawset(Week_Data.player, k1, d)
                    end
                end, false
            )
            Week_Data.db_status = DB_S_PKOK
        end
    end
end

--验证时间，看是否可初始化为正常赛程
local function  check_isvalid_time()
	local diff = math.floor((gt - glastUpdateTime)/ginterval)
	if diff == 0 and gt < glastUpdateTime + math.floor(ginterval*gvalidpercent) then
		LOG_INFO("mpz|G_IS_VALID = true")
		return true
	end
	LOG_INFO("mpz|G_IS_VALID = false")
	return false
end

--看数据文件是否存在
local F, err = io.open(gweek_data.file, "r+")
if F == nil then
	G_IS_VALID = check_isvalid_time()
end

--初始化执行一次
if G_IS_VALID then
	local ppday = gts - 3*gchangeday
	local ppfile = 'mpz' .. ppday .. '.kch'
	os.remove(ppfile)
	load_db(gts, gweek_data, kc.DB.OWRITER + kc.DB.OCREATE)
end

LOG_INFO("mpz|init:lastUpdateTime:"..gweek_data.headinfo.lastupdatetime.." interval:"..gweek_data.headinfo.interval.." round:"..gweek_data.headinfo.round.." attendnum: "..gweek_data.headinfo.attendnum)


local function comps( a, b )
	if a.score ~= b.score then
		return a.score > b.score
	else
		local power1 = 0
		local power2 = 0
		if rawget(a, "mpzreglist") then
			for k,v in ipairs(a.mpzreglist) do
				power1 = power1 + v.data1.power
			end
		end
		if rawget(b, "mpzreglist") then
			for k,v in ipairs(b.mpzreglist) do
				power2 = power2 + v.data1.power
			end
		end
		if power1 ~= power2 then 
			return power1 > power2
		else
			if string.sub(a.groupid, 1, 3) == flag_robot and string.sub(b.groupid, 1, 3) == flag_robot then
				local gpnum1 = tonumber(string.sub(a.groupid, 4))
				local gpnum2 = tonumber(string.sub(b.groupid, 4))
				return gpnum1 < gpnum2
			end

			if string.sub(a.groupid, 1, 3) == flag_robot then 
				return false
			elseif string.sub(b.groupid, 1, 3) == flag_robot then
				return true
			end

			local gpnum1 = tonumber(a.groupid)
			local gpnum2 = tonumber(b.groupid)
			return gpnum1 < gpnum2
		end
	end
end

local function get_sort_data_by_round(Week_Data, round)
	local player = Week_Data.player
	assert(player)
	local tmpgroups = {}
	if round == 1 then 
		local function comps2(a,b)
			return a.fightid < b.fightid
		end

		for k,v in pairs (player) do
			table.insert(tmpgroups, v)
			--print("mpz|1|get", v.groupid, v.fightid)
		end
		table.sort( tmpgroups, comps2 )
		return tmpgroups
	end
	if round < 2 then return end
	local player1 = Week_Data.player1
	local player2 = Week_Data.player2
	assert(player1)
	local wingroups = {}
	for k,v in pairs (player) do
		if v.failflag == 0 then
			table.insert(tmpgroups, v)
			--print("mpz|4|get wins", v.groupid, v.score)
		end
	end

	table.sort(tmpgroups, comps)

	for i = 1, 4 do
		table.insert(wingroups, player1[tmpgroups[i].groupid])
		--print("sort|", wingroups[i].groupid)
	end

	if round == 2 then return wingroups end
	local wingroups2 = {}
	for j = 1, 4, 2 do
		local tmpid1 = wingroups[j].groupid
		local tmpid2 = wingroups[j+1].groupid
		
		if player1 then		
			if player1[tmpid1].winflag > player1[tmpid2].winflag then
				table.insert(wingroups2, player2[tmpid1])			
			elseif player1[tmpid1].winflag < player1[tmpid2].winflag then
				table.insert(wingroups2, player2[tmpid2])
			end
		end
	end
	if round > 2 then return wingroups2 end
end

local function get_players_from_weekdata(Week_Data, round)
	if round == 1 then 
		return Week_Data.player 
	elseif round == 2 then
		return Week_Data.player1
	elseif round == 3 then
		return Week_Data.player2
	end

	return nil
end

local function found_user_config(group_node, username)
	if group_node and rawget(group_node, "mpzreglist") then
		for k, v in ipairs(group_node.mpzreglist) do 
			local user = v.data1.uid
			if user == username then
				return v
			end
		end
	end
	LOG_ERROR("found_user_config nil:"..group_node.groupid.."|".. username)
	return nil
end

local function send_reward(group_node, groupid, round, win)
	if string.sub(groupid,1,3) == flag_robot then return end
	local mail = {
		type = 10,
		from = lang_mpz.mpz_sender,
		subject = nil,        
    	message = nil,      
    	item_list = {},        
    	stamp = os.time(),
		guid = 0,
		expiry_stamp = 0,
	}

	local conf_reward = {}
	local confidx = 0
	if round == 1 then 
		if win == true then
			confidx = 5
			mail.subject = lang_mpz.mpz_fisrt_win_title
			mail.message = lang_mpz.mpz_fisrt_win_msg
			--print(lang_mpz.mpz_fisrt_title, lang_mpz.mpz_fisrt_win_msg)
		else
			confidx = 6
			mail.subject = lang_mpz.mpz_fisrt_fail_title
			mail.message = lang_mpz.mpz_fisrt_fail_msg
			--print(lang_mpz.mpz_fisrt_title, lang_mpz.mpz_fisrt_fail_msg)
		end
	elseif round == 2 then
		if win == true then
			confidx = 3
			mail.subject = lang_mpz.mpz_second_win_title
			mail.message = lang_mpz.mpz_second_win_msg
			--print(lang_mpz.mpz_second_win_title, lang_mpz.mpz_second_win_msg)
		else
			confidx = 4
			mail.subject = lang_mpz.mpz_second_fail_title
			mail.message = lang_mpz.mpz_second_fail_msg
			--print(lang_mpz.mpz_second_fail_title, lang_mpz.mpz_second_fail_msg)
		end
	elseif round == 3 then
		if win == true then
			confidx = 1
			mail.subject = lang_mpz.mpz_third_win_title
			mail.message = lang_mpz.mpz_third_win_msg
			--print(lang_mpz.mpz_third_win_title, lang_mpz.mpz_third_win_msg)
		else
			confidx = 2
			mail.subject = lang_mpz.mpz_third_fail_title
			mail.message = lang_mpz.mpz_third_fail_msg
			--print(lang_mpz.mpz_third_fail_title, lang_mpz.mpz_third_fail_msg)
		end
	else
		return
	end

	local item_list = {}
	conf_reward = Xue_Rank_conf[confidx]
	local item = {}
	for k,v in ipairs(conf_reward["Member_Re"]) do
		if k%2 == 1 then
			item.id = v
		else
			item.num = v
			--print("item:", item.id, item.num)
			table.insert(item_list, item)
			item = {}
		end
	end
	mail.item_list = item_list

	if rawget(group_node,"mpzreglist") then
    	for k,v in ipairs(group_node.mpzreglist) do
    		local uid = v.data1.uid
    		if string.sub(uid, 1, 3) ~= flag_robot then
    			LOG_INFO("mpz|send_mail "..confidx.." to: "..groupid..":".. uid)
    			redo_list.add_mail(uid, mail)
    		end
    	end
    end

    --添加库银、掌门和副掌门邮件
	local c_group = group_cache.get_group(groupid)
	if c_group ~= nil then
		local add_money = conf_reward["Men_Re"][2]
		group_cache.modify_money(groupid, add_money)
	    local mmail = {
	        type = 0,
	        from = lang_mpz.mpz_sender,
	        subject = lang_mpz.mpz_kuyin_title,
	        message = lang_mpz.mpz_kuyin_msg1..add_money..lang_mpz.mpz_kuyin_msg2,
	        stamp = os.time(),
	        expiry_stamp = os.time() + 604800,
	        guid = 0,
	    }

	    if rawget(c_group, "master") then
	    	LOG_INFO("mpz|send_mail "..confidx.." to master: "..groupid..":".. c_group.master.username)
	        redo_list.add_mail(c_group.master.username, mmail)
	    end
	    if rawget(c_group, "master2") then
	    	LOG_INFO("mpz|send_mail "..confidx.." to master2: "..groupid..":".. c_group.master2.username)
	        redo_list.add_mail(c_group.master2.username, mmail)
	    end
	end
end

local G_DO_SEND = false
local G_SEND_ROUND = 1

--重发邮件
if G_DO_SEND then
	LOG_INFO("mpz|GM|send reward")
	for k,v in pairs(gweek_data.player) do
		local group_node = v
		if group_node.winflag == G_SEND_ROUND then
			send_reward(group_node, group_node.groupid, G_SEND_ROUND, true)
		end
	end
end

local function send_reward_by_time(Week_Data, round)
	if round > 3 or round < 1 then 
		LOG_ERROR("mpz|round error! ".. round)
		return 
	end
	for i = 1, round do
		local player = get_players_from_weekdata(Week_Data, i)
		if not player then 
			LOG_ERROR("mpz|playerdata nil")
			return 
		end
		local fighternum = 0
		local groups_a = {}
		for k,v in pairs(player) do
			table.insert(groups_a, k)
			fighternum = fighternum + 1
		end
		LOG_INFO("mpz|send_reward_by_time! ".. i)
		for k = 1, fighternum do
			local gpid = groups_a[k]
	        local group_node = player[gpid]
	        local modified = false
	        --print("send_reward|", round, gpid, group_node.winflag)
	        --加randboxid是为了防止战斗错误可能引起的重复发邮件
	        if string.sub(gpid,1,3) ~= flag_robot and group_node.randboxid == 0 then		
				if group_node.winflag == i then
				    send_reward(group_node, gpid, i, true)
				    group_node.randboxid = (4-i)*2-1
				    --print("mpz|randboxid", group_node.randboxid)
				    modified = true	
				else
				    send_reward(group_node, gpid, i, false)
				    group_node.randboxid = (4-i)*2
				    --print("mpz|randboxid", group_node.randboxid)
				    modified = true
				end
			end

			if modified then
				local pb = require "protobuf"
				local t = pb.encode("MPZNode", group_node)
			    if i == 2 then
			    	Week_Data.db:set(flag_play1..gpid, t)
				elseif i == 3 then
					Week_Data.db:set(flag_play2..gpid, t)
				else
					Week_Data.db:set(gpid, t)
				end
			end
		end
	end
end

--状态的更新
local function update_state(Week_Data, percent, master_reg_time, fight_time)
	local nowtime = os.time()
	local starttime = Week_Data.headinfo.opentime
	local lastUpdateTime = Week_Data.headinfo.lastupdatetime
	local interval = Week_Data.headinfo.interval
	local round = Week_Data.headinfo.round

	if G_IS_VALID == false then
		Week_Data.status = END
		return
	end
	--当前进度
	local diff = math.floor((nowtime - lastUpdateTime)/interval)
	local regbegin = (round-1)*interval + lastUpdateTime
	local regend = (round-1)*interval + lastUpdateTime + percent*interval
	local tregbegin = diff*interval + lastUpdateTime
	local tregend = diff*interval + lastUpdateTime + percent*interval
	
	if nowtime >= regbegin and nowtime < regend then
		if Week_Data.status ~= END and Week_Data.status ~= REG then 
			Week_Data.status = REG
			Week_Data.db:set(flag_status, REG)
		end
	elseif nowtime >= regend and nowtime < regend + master_reg_time then
		if Week_Data.status ~= END and Week_Data.status ~= MATR_REG then 
			Week_Data.status = MATR_REG
			Week_Data.db:set(flag_status, MATR_REG)
		end
	elseif nowtime < tregbegin + master_reg_time + fight_time and nowtime >= tregend + master_reg_time then
		if Week_Data.status ~= END and Week_Data.status ~= FIGHTING then 
			Week_Data.status = FIGHTING
			Week_Data.db:set(flag_status, FIGHTING)
		end
	elseif nowtime >= tregend + master_reg_time + fight_time and nowtime < tregbegin + interval then
		if Week_Data.status ~= END and Week_Data.status ~= FINISH then 
			--切换状态时，发放奖励			
			if round > 3 then
				Week_Data.status = END
				Week_Data.db:set(flag_status, END)
			else
				Week_Data.status = FINISH
				Week_Data.db:set(flag_status, FINISH)
			end
			--print("send_reward_by_time!")
			send_reward_by_time(Week_Data, round - 1)
		end
		--send_reward_by_time(Week_Data, round - 1)
	elseif round < 4 and diff > round-1 then --出错不可用
		LOG_ERROR("mpz|status err! nowtime"..(nowtime-lastUpdateTime).. " fighttime"..(regend + master_reg_time - lastUpdateTime).." status "..Week_Data.status.." round".. round  )
	end
	--print("MPZ|status", Week_Data.status)
end

--返回下个状态的时间戳
local function get_next_status(Week_Data, percent, master_reg_time, fight_time, changeday)
	local nowtime = os.time()
	local lastUpdateTime = Week_Data.headinfo.lastupdatetime
	local interval = Week_Data.headinfo.interval
	local round = Week_Data.headinfo.round

	--更新status
	update_state(Week_Data, percent, master_reg_time, fight_time)
	local status = Week_Data.status

	--当前进度
	local diff = math.floor((nowtime - lastUpdateTime)/interval)

	if diff > round-1 then 
		return nowtime + fight_time
	else 
		if status == REG then
			local ret = lastUpdateTime+diff*interval + interval*percent
			--print("REG|nextstatus", ret-lastUpdateTime)
			return ret
		elseif status == MATR_REG then
			local ret = lastUpdateTime+diff*interval + interval*percent + master_reg_time
			--print("MATR_REG|nextstatus", ret-lastUpdateTime)
			return ret
		elseif status == FIGHTING then 
			local ret = lastUpdateTime+diff*interval + interval*percent + master_reg_time + fight_time
			--print("FIGHTING|nextstatus", ret-lastUpdateTime)
			return ret
		elseif status == FINISH then 

			local ret = lastUpdateTime + (diff+1)*interval
			if diff == round-1 then
				ret = lastUpdateTime + diff*interval
			end
			--print("FINISH|nextstatus", ret-lastUpdateTime)
			return ret
		elseif status == END then
			local ret = lastUpdateTime + changeday*interval
			--print("END|nextstatus", ret-lastUpdateTime)
			return ret
		else return -1 end
	end
end

--添加机器人公会
local function add_robotgroup(Week_Data, attendnum)
	local robot_num = 0
	if attendnum > G_MAX_ROBOT_NUM then
		robot_num = attendnum%2
	elseif attendnum == 0 then
		robot_num = G_MAX_ROBOT_NUM
	else
		robot_num = G_MAX_ROBOT_NUM - attendnum
	end

	if robot_num == 0 then return 1 end
	LOG_INFO("mpz|add_robot|robot_num: ".. robot_num)
    local player = Week_Data.player
    --print("add_robot", robot_num)
	for k = 1, robot_num do
		local robotid = flag_robot..k
		local robot_node = {
    		groupid = robotid,
			nickname = lang_mpz.robot_gnickname[(k-1)%8+1],
			fieldsinfo = {},		--6个战场信息，战斗前和战斗中信息
			fightid = Week_Data.headinfo.attendnum+k,	--战斗编号 唯一 fightid = 0 不可用
			signflag = 1,
			winflag = 0,			--胜利次数，根据这个判奖励
			failflag = 0,			--淘汰 = 1,未淘汰 = 0
			randboxid = 0,			--奖励 在淘汰时或得冠军时产生,没用，奖励不是宝箱
			fightendtime = 0,		--今天门派战结束时间，校验下今天还昨天的时间
			mpzreglist = {},
			score = 0,
			level = 1,
			enemyid = nil,
    	}


		for k1=1,6 do
			local fieldsinfo = {
				fieldno = k1,
				fighters = {},	--自己的成员
				enemys = {},	--对手，这里面没有奖励信息
				win = 0,		-- -1时，还在战斗中 0=输， 1=赢
				videonum = 0,	--录像总数
				fightinfo = {}, --不回fightbytes 另外拉取
				winnum = 0,
				failnum = 0,
			}

			if k1 == 1 then
		        local uid = flag_robot..(k*1000+k1*100+1)
		        
				local fighter_info = {
					uid = uid,
					rewardflag = 0,	--奖励标记位，领取后=1
					dead = 0,		--是否阵亡
				}

				fieldsinfo.fighters[1] = fighter_info			

				local  status = 3 --普通成员
				--if k1 == 1 and i == 1 then status = 1 end --会长
				--if k1 == 2 and i == 1 then status = 2 end --副会长
				local fn_len = rawlen(family_name)
			    local mn_len = rawlen(male_name)
			    local fmn_len = rawlen(female_name)
				local sex = math.random(2) - 1
		        local nickname = nil
		        if sex == 0 then
		            nickname = family_name[math.random(fn_len)]..male_name[math.random(mn_len)]
		        else
		            nickname = family_name[math.random(fn_len)]..female_name[math.random(fmn_len)]
		        end
				local robot_info = {
		            uid = uid,
		            power = math.random(6888,9999),
		            nick_name = nickname,
		            sex = sex,
		            level = 30,
		            star = 5,
		            vip = 0,
		            status = status,
		            robot = math.random(3000),
		        }

				local fighter_data = {
					data1 = robot_info,
				}
				--加到报名名单
				table.insert(robot_node.mpzreglist, fighter_data)
				LOG_INFO("mpz|add_robot|field: ".. fighter_data.data1.uid)
			end
			robot_node.fieldsinfo[k1] = fieldsinfo
		end
		--[[
		for i = 1,6 do
			for k,v in ipairs (robot_node.fieldsinfo[i].fighters) do
				print("print robot|", i, k, v.uid)
			end
		end]]

		player[robotid] = robot_node
		local pb = require "protobuf"
	    local t = pb.encode("MPZNode", robot_node)
	    --淘汰赛不必处理robotid
		Week_Data.db:set(robotid, t)
	end

	--门派数凑到偶数且大于等于8个
	Week_Data.headinfo.attendnum = Week_Data.headinfo.attendnum + robot_num
	--头信息改变写回
	local pb = require "protobuf"
	local headinfo = Week_Data.headinfo
	local h = pb.encode("mpz_head_info", headinfo)
	Week_Data.db:set(flag_head, h)

	return 1
end

local function get_robot_data(robot_info)
    local d = clonetab(robot_list30[robot_info.data1.robot])
    d.lead.sex = robot_info.data1.sex
    d.lead.star = robot_info.data1.star
    d.lead.level = robot_info.data1.level
    d.lead.skill.id = 110650001
    d.lead.skill.level = 30
    d.zhenxing.zhanwei_list[1].knight.data.level = 30
    d.zhenxing.zhanwei_list[1].knight.data.skill.level = 30
    d.zhenxing.zhanwei_list[3].knight.data.level = 30
    d.zhenxing.zhanwei_list[3].knight.data.skill.level = 30
    d.zhenxing.zhanwei_list[4].knight.data.level = 30
    d.zhenxing.zhanwei_list[4].knight.data.skill.level = 30
    d.zhenxing.zhanwei_list[5].knight.data.level = 30
    d.zhenxing.zhanwei_list[5].knight.data.skill.level = 30
    d.zhenxing.zhanwei_list[6].knight.data.level = 30
    d.zhenxing.zhanwei_list[6].knight.data.skill.level = 30
    d.zhenxing.zhanwei_list[7].knight.data.level = 30
    d.zhenxing.zhanwei_list[7].knight.data.skill.level = 30
    return d, nil
end

local function get_main_data(user_info)
    local d = {
                lead = user_info.data2.lead,
                zhenxing = user_info.data2.zhenxing,
                PVP = {reputation = user_info.data2.reputation},
                book_list = user_info.data2.book_list,
                lover_list = user_info.data2.lover_list,
                wxjy = user_info.data2.wxjy,
                sevenweapon = user_info.data2.sevenweapon,
            }
            --printtab(user_info.data2, "wxjy|")
    return d, user_info.data2.knight_list
end

local function get_user_data(uid, user_info)
    local flag = string.sub(uid, 1, 3)
    if flag == flag_robot then
        return get_robot_data(user_info)
    else
        return get_main_data(user_info)
    end
end

local function check_field_finish(group_node1, group_node2)

	for i=1,6 do
		--print("check:group_node1", i, group_node1.fieldsinfo[i].win)
		if group_node1.fieldsinfo[i].win == 0 then
			return i
		end
		--print("check:group_node2", i, group_node2.fieldsinfo[i].win)
		if group_node2.fieldsinfo[i].win == 0 then
			return i
		end
	end

	return 0
end

local function do_field_fight(Week_Data, gpid1, gpid2, group_node1, group_node2, fieldno )
	local fieldsinfo1 = {}
	clonetab_real(fieldsinfo1, group_node1.fieldsinfo[fieldno])
	local fieldsinfo2 = {}
	clonetab_real(fieldsinfo2, group_node2.fieldsinfo[fieldno])
	local selfs = fieldsinfo1.fighters
	selfs = rawget(fieldsinfo1, "fighters")
	local enemys = fieldsinfo2.fighters
	enemys = rawget(fieldsinfo2, "fighters")
	local selfnum = 0
	local enemynum = 0
	if selfs then selfnum = #selfs end
	if enemys then enemynum = #enemys end

	local selfidx = 1
	local enemyidx = 1
	local videono = 0
	local rcd_temp = {}
	local rcd_idx = Week_Data.rcd_idx
	
	fieldsinfo1.videonum = 0
	fieldsinfo1.winnum = 0
	fieldsinfo1.failnum = 0
	fieldsinfo2.videonum = 0
	fieldsinfo2.winnum = 0
	fieldsinfo2.failnum = 0

	--print("dofieldfight:"..fieldno.." selfs:"..selfnum.." enemys:"..enemynum)
	if selfs then
		fieldsinfo2.enemys = {}
		for k,v in ipairs (selfs) do
			local user_info = found_user_config(group_node1, v.uid)
			fieldsinfo2.enemys[k] = user_info.data1
		end
	end

	if enemys then
		fieldsinfo1.enemys = {}
		for k,v in ipairs (enemys) do
			local user_info = found_user_config(group_node2, v.uid)
			fieldsinfo1.enemys[k] = user_info.data1
		end
	end
	
	--[[
	local notfinish = check_field_finish(group_node1, group_node2)
	--print("fieldsfight|check_field_finish|", notfinish)
	if notfinish > fieldno then
		print("notfinish > fieldno|", notfinish, fieldno)
		return
	end]]

	if selfnum == 0 and enemynum > 0 then	
		fieldsinfo1.win = -1
		fieldsinfo2.win = 1
		group_node1.fieldsinfo[fieldno] = fieldsinfo1
		group_node2.fieldsinfo[fieldno] = fieldsinfo2
		LOG_INFO("mpz|fieldno|"..fieldno.." selfnum 0 enemynum>0 win:"..gpid2.." fail:"..gpid1)
		return
	end

	if enemynum == 0 and selfnum > 0 then 	
		fieldsinfo1.win = 1
		fieldsinfo2.win = -1
		group_node1.fieldsinfo[fieldno] = fieldsinfo1
		group_node2.fieldsinfo[fieldno] = fieldsinfo2
		LOG_INFO("mpz|fieldno|"..fieldno.." selfnum>0 enemynum=0 win:"..gpid1.." fail:"..gpid2)
		return
	end

	--四强后会出现都没人
	if enemynum == 0 and selfnum == 0 then 
		-- 正常门派,不算分
		fieldsinfo1.win = -2
		fieldsinfo2.win = -2
		group_node1.fieldsinfo[fieldno] = fieldsinfo1
		group_node2.fieldsinfo[fieldno] = fieldsinfo2
		LOG_INFO("mpz|fieldno|"..fieldno.." both nofighter ".. gpid1.." vs "..gpid2)
		return
	end
	local win = 0
	local selfhpinfo = {}
	local enemyhpinfo = {}
	--大循环，车轮战斗T^T
	while selfnum >= selfidx and enemynum >= enemyidx do
		repeat
			--对战
			--print("pk**", pk1, pk2)
			local uid1 = selfs[selfidx].uid
			local uid2 = enemys[enemyidx].uid
			--print("mpz|"..selfidx.." vs "..enemyidx)
			--print("mpz|"..fieldno.."|"..gpid1.." vs " .. gpid2 .. "|doFight("..uid1.." vs "..uid2.. ")")
						
            local user_info1 = found_user_config(group_node1, uid1)
            local user_info2 = found_user_config(group_node2, uid2)
            if user_info1 == nil  then
            	LOG_ERROR(uid1.." not reg")
            	selfidx = selfidx + 1
            	break
            end
            if user_info2 == nil  then
            	LOG_ERROR(uid2.." not reg")
            	enemyidx = enemyidx + 1
            	break
            end
            local user_data1, knight_list1 = get_user_data(uid1, user_info1)
            local user_data2, knight_list2 = get_user_data(uid2, user_info2)
            -- 实际战斗并记下rcd
            local fight = core_fight:new()
            local rcd = fight.rcd
            local preview = rcd.preview

            fight:get_player_data(user_data1, knight_list1)
            fight:get_player_data(user_data2, knight_list2, true)
            fight:get_attrib()

            -- 更新hp
            if selfhpinfo then
            	for k,v in pairs (selfhpinfo) do
					for k1,v1 in ipairs(fight.role_list) do
						repeat
					        if v1.posi == k then
					        	v1.hp = v.end_hp
					        	if v1.hp < 0 then v1.hp = 0 end
					        	--print("mpz|flesh|selfid: ", v1.id, " type:", v1.type, " posi:", v1.posi, " fillhp:", v1.hp)
					        	break
					        end
				        until true
					end
				end
			end

			if enemyhpinfo then
            	for k,v in pairs (enemyhpinfo) do
					for k1,v1 in ipairs(fight.role_list) do
						repeat
					        if k == v1.posi then
					        	v1.hp = v.end_hp
					        	if v1.hp < 0 then v1.hp = 0 end
					        	--print("mpz|flesh|enemyid: ", v1.id, " type:", v1.type, " posi:", v1.posi, " fillhp:", v1.hp)
					        	break
					        end
				        until true
					end
				end
			end

            -- 这里必须先获取原始preview，排序之后顺序就乱了
            fight:get_preview_role_list()
            fight:play(rcd)

            videono = videono + 1
            rcd_idx = rcd_idx + 1
            win = fight.winner
            local MpzRcd = {
            	user1 = user_info1.data1,
				user2 = user_info2.data1,
				winner = nil,
				videoidx = rcd_idx, 		--录像池索引
				round = round,				--0-3 表第几轮 0=报名 1=完成淘汰赛 2=完成半决赛 3=出冠军，看结果
				fieldno = fieldno,			-- 战场编号	
				videono = videono,			--战场内第几场战斗
				fighttime = os.time(),
        	}

			if win == 1 then
                MpzRcd.winner = uid1
                --记录self血量
			    for k,v in ipairs(fight.role_list) do
			        local f = {id = -1, end_hp = -1}
			        local posi = v.posi
			        if posi < 100 then
			        	f.id = v.id
			        	if v.hp < 0 then 
			        		f.end_hp = 0 
			        	else
			            	f.end_hp = v.hp
			            end
			            selfhpinfo[posi] = f
			            --print("mpz|end|selfid: ", v.id, " type:" , v.type, " posi:", posi," fillhp:", selfhpinfo[posi].end_hp)
			        end
			    end

			    enemyhpinfo = {}
			    enemys[enemyidx].dead = 1
			    --selfs[selfidx].rewardflag = selfs[selfidx].rewardflag + 1
			    fieldsinfo1.winnum = fieldsinfo1.winnum + 1
			    fieldsinfo2.failnum = fieldsinfo2.failnum + 1
            else
                MpzRcd.winner = uid2
                --记录enemy血量
                for k,v in ipairs(fight.role_list) do
			        local f = {id = -1, end_hp = -1}
			        local posi = v.posi
			        if posi < 1000 and posi >= 100 then
			        	f.id = v.id
			        	if v.hp < 0 then 
			        		f.end_hp = 0 
			        	else
			            	f.end_hp = v.hp
			            end
			            enemyhpinfo[posi] = f
			            --print("mpz|end|enemyid: ", v.id , " posi:",posi," fillhp:",enemyhpinfo[posi].end_hp)
			        end
			    end
			    
			    selfhpinfo = {}
			    selfs[selfidx].dead = 1
			    --enemys[enemyidx].rewardflag = enemys[enemyidx].rewardflag + 1
			    fieldsinfo2.winnum = fieldsinfo2.winnum + 1
			    fieldsinfo1.failnum = fieldsinfo1.failnum + 1
            end

            --存在kc的数据
            table.insert(rcd_temp, {idx = rcd_idx, rcd = rcd})
        	--记录索引
            local rcd_t = rawget(Week_Data, "rcd")
            table.insert(rcd_t, rcd_idx)

            --战斗记录
            if not rawget(fieldsinfo1, "fightinfo") then fieldsinfo1.fightinfo = {} end
            if not rawget(fieldsinfo2, "fightinfo") then fieldsinfo2.fightinfo = {} end
            table.insert(fieldsinfo1.fightinfo, MpzRcd)
            table.insert(fieldsinfo2.fightinfo, MpzRcd)

			if win == 1 then
				enemyidx = enemyidx + 1 --下一个对手
			else
				selfidx = selfidx + 1 --下一个队友
			end
		until true 
	end

	--写回录像
	local pb = require "protobuf"
    for k,v in ipairs(rcd_temp) do
        local t = pb.encode("FightRcd", v.rcd)
        Week_Data.db:set(flag_rcd..v.idx, t)
    end
    Week_Data.rcd_idx = rcd_idx
    --print("rcd_idx",rcd_idx, Week_Data.rcd_idx)
    Week_Data.db:set(flag_rcdidx, rcd_idx)

    rcd_temp = {}

	fieldsinfo1.videonum = videono
	fieldsinfo2.videonum = videono

	--最后一场哪边赢就哪边胜
	if win == 1 then
		fieldsinfo1.win = 1
		fieldsinfo2.win = -1
		LOG_INFO("mpz|fieldno|".. fieldno.." failer|"..gpid2.."|winner|"..gpid1)
	else
		fieldsinfo1.win = -1
		fieldsinfo2.win = 1
		LOG_INFO("mpz|fieldno|".. fieldno.." failer|"..gpid1.."|winner|".. gpid2)
	end

	group_node1.fieldsinfo[fieldno] = fieldsinfo1
	group_node2.fieldsinfo[fieldno] = fieldsinfo2
end

local function do_fight(Week_Data)
	local round = Week_Data.headinfo.round
	--比完不用比了
	if round > 3 then return -1 end
	local player = get_players_from_weekdata(Week_Data, round)
	assert(player,"playerdata nil")
	local fighternum = 0
	local groups_a = {}
	for k,v in pairs(player) do
		--LOG_INFO("mpz|do_fight|player: "..k)
		table.insert(groups_a, v)
		fighternum = fighternum + 1
	end

 	groups_a = get_sort_data_by_round(Week_Data, round)
 	if round == 1 then
	 	for k,v in ipairs(groups_a) do
			LOG_INFO("mpz|do_fight|round:"..round.." gid:".. v.groupid.." fightid:".. v.fightid)
		end
	end

	LOG_INFO("mpz|do_fight|round:"..round.." fighternum:".. fighternum)

	local FIGHT_TIMES = 0 
	for k = 1, fighternum, 2 do
		--打到这么多场退出下回打
		if FIGHT_TIMES >= G_FIGHT_MAX_TIME then break end
		local gpid1 = groups_a[k].groupid
		assert(k+1 <= fighternum, "fighternum:"..fighternum)
		local gpid2 = groups_a[k+1].groupid
        local group_node1 = player[gpid1]
        local group_node2 = player[gpid2]
        local winner = nil
        local beginfieldno = 1     

        repeat
        	--检验战场完成状态
        	beginfieldno = check_field_finish(group_node1, group_node2)
        	--print("do_fight1|check_field_finish|", beginfieldno)
        	if beginfieldno == 0 then
        		break
        	end
        	
	        if round == 1 and string.sub(gpid1, 1, 3) == flag_robot and string.sub(gpid2, 1, 3) == flag_robot then
	            -- 这种机器人战斗没人看，可以跳过
	            group_node1.winflag = round
	            group_node1.failflag = 0
				group_node2.failflag = 1
				group_node1.enemyid = gpid2
				group_node2.enemyid = gpid1

				for i=1, 6 do
					group_node1.fieldsinfo[i].win = 1
					group_node2.fieldsinfo[i].win = -1
				end
				
				group_node1.score = 1
				group_node2.score = 0
				group_node1.winnum = 1
				group_node2.winnum = 0
				LOG_INFO("mpz|do_fight|round:"..round.." AllField Finished! robot1:"..gpid1.." vs robot2:"..gpid2)
	        else
	        	LOG_INFO("mpz|round:"..round.."|".. gpid1 .." vs "..gpid2)
	        	--6个战场战斗
	        	group_node1.enemyid = gpid2
				group_node2.enemyid = gpid1

				if group_node1.winflag == round or group_node2.winflag == round  then --胜利标记校验
					break
				end

	        	for i = 1, 6 do	
	        		do_field_fight(Week_Data, gpid1, gpid2, group_node1, group_node2, i)
	        		assert(group_node1.fieldsinfo[i].win ~= 0, "mpz|do_fight|round:"..round.." fieldsfight "..i.." not finish!" )
					assert(group_node2.fieldsinfo[i].win ~= 0, "mpz|do_fight|round:"..round.." fieldsfight "..i.." not finish!" )
	        	end

	        	local nowtime = os.time()
				group_node1.fightendtime = nowtime
				group_node2.fightendtime = nowtime

	    		local score1 = 0
				local score2 = 0
				if group_node1.fieldsinfo[1].win == 1 then
					score1 = score1 + 10 end
				if group_node1.fieldsinfo[2].win == 1 then
					score1 = score1 + 8 end
				if group_node1.fieldsinfo[3].win == 1 then
					score1 = score1 + 7 end
				if group_node1.fieldsinfo[4].win == 1 then
					score1 = score1 + 6 end
				if group_node1.fieldsinfo[5].win == 1 then
					score1 = score1 + 5 end
				if group_node1.fieldsinfo[6].win == 1 then
					score1 = score1 + 3
				end

				if group_node2.fieldsinfo[1].win == 1 then
					score2 = score2 + 10 end
				if group_node2.fieldsinfo[2].win == 1 then
					score2 = score2 + 8 end
				if group_node2.fieldsinfo[3].win == 1 then
					score2 = score2 + 7 end
				if group_node2.fieldsinfo[4].win == 1 then
					score2 = score2 + 6 end
				if group_node2.fieldsinfo[5].win == 1 then
					score2 = score2 + 5 end
				if group_node2.fieldsinfo[6].win == 1 then
					score2 = score2 + 3
				end
				group_node1.score = score1
				group_node2.score  = score2
				local win1 = 0
				local win2 = 0
				for i=1,6 do
					if group_node1.fieldsinfo[i] ~= nil then
						win1 = win1 + group_node1.fieldsinfo[i].winnum
					end
					if group_node2.fieldsinfo[i] ~= nil then
						win2 = win2 + group_node2.fieldsinfo[i].winnum
					end
				end

				group_node1.winnum = win1
				group_node2.winnum = win2
				--print("mpz|winnum:", win1, win2)
				local iswin = false

				if score1 > score2 then
					iswin = true
				elseif score2 == score1 then
					if group_node1.winnum > group_node2.winnum then 
						iswin = true
					elseif group_node1.winnum == group_node2.winnum then
						if string.sub(group_node1.groupid, 1, 3) == flag_robot and string.sub(group_node2.groupid, 1, 3) == flag_robot then
							local gpnum1 = tonumber(string.sub(group_node1.groupid, 4))
							local gpnum2 = tonumber(string.sub(group_node2.groupid, 4))
							if gpnum1 < gpnum2 then iswin = true end
						else
							if string.sub(group_node2.groupid, 1, 3) == flag_robot then
								iswin = true
							elseif string.sub(group_node1.groupid, 1, 3) ~= flag_robot and string.sub(group_node2.groupid, 1, 3) ~= flag_robot then
								local gpnum1 = tonumber(group_node1.groupid)
								local gpnum2 = tonumber(group_node2.groupid)
								if gpnum1 < gpnum2 then iswin = true end
							end
						end
					end
				end

				if iswin then
					group_node1.winflag = round
					group_node1.failflag = 0				
					group_node2.failflag = 1

					LOG_INFO("mpz|do_fight|round "..round.." AllField Finished! score1="..score1.." score2="..score2.." winner("..gpid1..")")
					--print("do_fight|round "..round.." AllField Finished! score1="..score1.." score2="..score2.." winner("..gpid1..")")
				else
					group_node2.winflag = round
					group_node2.failflag = 0
					group_node1.failflag = 1

					LOG_INFO("mpz|do_fight|round "..round.." AllField Finished! score1="..score1.." score2="..score2.." winner("..gpid2..")")
					--print("do_fight|round "..round.." AllField Finished! score1="..score1.." score2="..score2.." winner("..gpid2..")")
				end
	    	end

	    	--比完一对公会，写回
	    	local pb = require "protobuf"
	    	local t1 = pb.encode("MPZNode", group_node1)
	    	local t2 = pb.encode("MPZNode", group_node2)
		    if round == 2 then
		    	Week_Data.db:set(flag_play1..gpid1, t1)
		    	Week_Data.db:set(flag_play1..gpid2, t2)
			elseif round == 3 then
				Week_Data.db:set(flag_play2..gpid1, t1)
				Week_Data.db:set(flag_play2..gpid2, t2)
			else
				Week_Data.db:set(gpid1, t1)
				Week_Data.db:set(gpid2, t2)
			end
			
		    FIGHT_TIMES = FIGHT_TIMES + 1
	    until true
	end

	--校验完成
	for k = 1, fighternum, 2 do
		local gpid1 = groups_a[k].groupid
		assert(k+1 <= fighternum)
		local gpid2 = groups_a[k+1].groupid
        local group_node1 = player[gpid1]
        local group_node2 = player[gpid2]

		if group_node1.winflag ~= round and group_node2.winflag ~= round  then --胜利标记校验
			LOG_ERROR("mpz|do_fight|round:"..round.." winflag("..gpid1..":"..group_node1.winflag.."x"..gpid2..":"..group_node2.winflag..")|fight not finish!")
			return 1
		end
		
		local notfinish = check_field_finish(group_node1, group_node2)
    	if notfinish ~= 0 then
    		LOG_ERROR("mpz|round:"..round.." notfinish!".. notfinish)
    		return 1
		end
	end
    return 0
end

local function debug_week_data(Week_Data)
	local now_time = os.time()
	local lastUpdateTime = Week_Data.headinfo.lastupdatetime
	local interval = Week_Data.headinfo.interval
	local diff = math.floor((now_time - lastUpdateTime)/interval)
	local round = Week_Data.headinfo.round
	local attendnum = Week_Data.headinfo.attendnum
	print("mpz|debug|", now_time - lastUpdateTime, interval, round, attendnum, diff)

	local player = Week_Data.player
	local player1 = Week_Data.player1
	local player2 = Week_Data.player2
	
	if player then 	
		for k,v in pairs(player) do
			print("mpz|debug|groupid1:", k)
		end
	end
	if round > 1 and player1 then 	
		for k,v in pairs(player1) do
			print("mpz|debug|groupid2:", k)
		end
	end
	if round > 2 and player2 then 	
		for k,v in pairs(player2) do
			print("mpz|debug|groupid3:", k)
		end
	end
end

local function do_select(Week_Data, round)
	local now_time = os.time() 
	local lastUpdateTime = Week_Data.headinfo.lastupdatetime
	local interval = Week_Data.headinfo.interval
	local diff = math.floor((now_time - lastUpdateTime)/interval)

	--选出4强
	if round == 1 then 
		local player = Week_Data.player
		local wingroups = {}
		for k,v in pairs (player) do
			if v.failflag == 0 then
				table.insert(wingroups, v)
				--print("mpz|4|get wins", v.groupid, v.score)
			end
		end

		table.sort(wingroups, comps)
		--[[
		for k,v in ipairs(wingroups) do
			print("mpz|sort:", v.groupid, "score", v.score, "lv", v.level)
		end]]
		local i = 1
		for k,v in ipairs(wingroups) do
			if i > 4 then break end
			--清除一些数据
			local group_node = clonetab(v)
			local groupid = group_node.groupid
			local is_robot = (string.sub(groupid, 1, 3) == flag_robot)
			group_node.randboxid = 0
			group_node.fightendtime = 0					--门派战结束时间
			LOG_INFO("mpz|do select 4:".. groupid.. " score:"..group_node.score)
			group_node.score = 0 	
			group_node.winnum = 0					--积分
			for k1 = 1,6 do
				local fieldsinfo = {}
				clonetab_real(fieldsinfo, group_node.fieldsinfo[k1])
				assert(fieldsinfo)
				fieldsinfo.enemys = {}
				fieldsinfo.win = 0
				fieldsinfo.videonum = 0
				fieldsinfo.fightinfo = {}
				fieldsinfo.winnum = 0
				fieldsinfo.failnum = 0
				if rawget(fieldsinfo, "fighters") then
					for k2,v2 in ipairs (fieldsinfo.fighters) do
						v2.rewardflag = 0
						v2.dead = 0
					end
				end
				group_node.fieldsinfo[k1] = fieldsinfo
			end
			if not is_robot then
				group_node.signflag = 0							--会长提交标记
				group_node.mpzreglist = {}						--门派战报名名单
				for k1 = 1,6 do
					group_node.fieldsinfo[k1].fighters = {}		--自己的成员
					group_node.fieldsinfo[k1].enemys = {}		--敌方的成员
				end
			end

			local player1 = Week_Data.player1
			player1[groupid] = group_node

			--写回
			local pb = require "protobuf"
	    	local t = pb.encode("MPZNode", group_node)
		    Week_Data.db:set(flag_play1..groupid, t)
		    i = i + 1
		end
	elseif round == 2 then	--选出决赛名单
		local player2 = Week_Data.player2
		local player1 = Week_Data.player1
		for k,v in pairs (player1) do
			if v.winflag == round then
				
				local group_node = clonetab(v)
				local is_robot = (string.sub(k, 1, 3) == flag_robot)

				--初始化一些数据
				group_node.randboxid = 0
				group_node.fightendtime = 0			--今天门派战结束时间，校验下今天还昨天的时间
				LOG_INFO("mpz|do select 4->2:".. k.." score:"..group_node.score)
				group_node.score = 0 				--积分
				group_node.winnum = 0
				for k1 = 1,6 do
					local fieldsinfo = {}
					clonetab_real(fieldsinfo, group_node.fieldsinfo[k1])
					assert(fieldsinfo)
					fieldsinfo.enemys = {}
					fieldsinfo.win = 0
					fieldsinfo.videonum = 0
					fieldsinfo.fightinfo = {}
					fieldsinfo.winnum = 0
					fieldsinfo.failnum = 0
					if rawget(fieldsinfo, "fighters") then
						for k2,v2 in ipairs (fieldsinfo.fighters) do
							v2.rewardflag = 0
							v2.dead = 0
						end
					end
					group_node.fieldsinfo[k1] = fieldsinfo
				end
				if not is_robot then
					group_node.signflag = 0							--会长提交标记
					group_node.mpzreglist = {}						--门派战报名名单
					for k1 = 1,6 do
						group_node.fieldsinfo[k1].fighters = {}		--自己的成员
						group_node.fieldsinfo[k1].enemys = {}		--敌方的成员
					end
					
				end

				player2[k] = group_node

				--写回
				local pb = require "protobuf"
		    	local t1 = pb.encode("MPZNode", group_node)
			    Week_Data.db:set(flag_play2..k, t1)
			end
		end
	end

	-- 全部完成，等自然切换status
	Week_Data.headinfo.round = Week_Data.headinfo.round + 1 

	--头信息改变写回
	local pb = require "protobuf"
	local headinfo = Week_Data.headinfo
	local h = pb.encode("mpz_head_info", headinfo)
	Week_Data.db:set(flag_head, h)

end

--要先填充过机器人FIGHTING阶段调用
local function pre_fill_fieldinfo(Week_Data)
	local round = Week_Data.headinfo.round
	--比完不用比了
	if round > 3 then return -1 end
	LOG_INFO("mpz|pre_fill_fieldinfo|round"..round)
	local player = get_players_from_weekdata(Week_Data, round)
	assert(player,"playerdata nil")
	local fighternum = 0
	local groups_a = {}
	for k,v in pairs(player) do
		--LOG_INFO("pre_fill_fieldinfo|player: "..k)
		table.insert(groups_a, v)
		fighternum = fighternum + 1
	end

	LOG_INFO("mpz|pre_fill_fieldinfo|fighternum:".. fighternum)

	--全员预填充战场
	for k = 1, fighternum do
		local gpid = groups_a[k].groupid
		local group_node = player[gpid]
		repeat
			if group_node.signflag > 0 then break end --应该有战场信息

			--对会长没提交的公会自动随机填充战场
	        if group_node.signflag == 0 and rawget(group_node,"mpzreglist") then
	        	local uids = {}
	        	local num = 0
	        	for k,v in ipairs(group_node.mpzreglist) do
	        		uids[k] = v.data1.uid
	        		num = num + 1
	        		--print("prefill", v.data1.uid)
	        	end

	        	--打乱顺序
	        	for k,v in ipairs(uids) do
	        		local tmp = uids[k]
	        		local rn = math.random(num)
	        		uids[k] = uids[rn]
	        		uids[rn] = tmp
	        	end

	        	for i = 1, num do
	        		if num > 18 then break end
	        		local fino = math.floor((i-1)/6)+1
	        		local fdno = i - (fino-1)*6
	        		local user_info = found_user_config(group_node, uids[i])
	        		if user_info == nil then return -1 end
	        		local fighter_info = {
						uid = user_info.data1.uid,
						rewardflag = 0,	--奖励标记位，领取后=1
						dead = 0,		--是否阵亡
					}
					if not rawget(group_node.fieldsinfo[fdno], "fighters") then group_node.fieldsinfo[fdno].fighters = {} end
					group_node.fieldsinfo[fdno].fighters[fino] = fighter_info
					LOG_INFO("mpz|pre_fill_fieldinfo|"..gpid.." fieldno("..fdno.."x"..fino..")|add "..user_info.data1.uid)
				end
	        	
				group_node.signflag = 1
				local pb = require "protobuf"
		    	local t = pb.encode("MPZNode", group_node)
			    if round == 2 then
			    	Week_Data.db:set(flag_play1..gpid, t)
				elseif round == 3 then
					Week_Data.db:set(flag_play2..gpid, t)
				else
					Week_Data.db:set(gpid, t)
				end
	        end
        until true
	end

	groups_a = get_sort_data_by_round(Week_Data, round)
	if round == 1 then
	 	for k,v in ipairs(groups_a) do
			LOG_INFO("mpz|pre|round:"..round.." gid:".. v.groupid.." fightid:".. v.fightid)
		end
	end

	--预填充对手
	for k = 1, fighternum, 2 do
		local gpid1 = groups_a[k].groupid
		if k+1 > fighternum then break end
		local gpid2 = groups_a[k+1].groupid
		local group_node1 = player[gpid1]
		local group_node2 = player[gpid2]

		for i = 1,6 do		
			if rawget(group_node2, "fieldsinfo") and rawget(group_node2.fieldsinfo[i],"fighters") then 
				group_node1.fieldsinfo[i].enemys = {}
				for k,v in ipairs (group_node2.fieldsinfo[i].fighters) do
					local user_info = found_user_config(group_node2, v.uid)
					if user_info then
						group_node1.fieldsinfo[i].enemys[k] = user_info.data1
					end
				end
			end

			if rawget(group_node1,"fieldsinfo") and rawget(group_node1.fieldsinfo[i], "fighters") then 
				group_node2.fieldsinfo[i].enemys = {}
				for k,v in ipairs (group_node1.fieldsinfo[i].fighters) do
					local user_info = found_user_config(group_node1, v.uid)
					if user_info then
						group_node2.fieldsinfo[i].enemys[k] = user_info.data1
					end
				end
			end
		end
		group_node1.enemyid = group_node2.groupid
		group_node2.enemyid = group_node1.groupid

		--写回
    	local pb = require "protobuf"
    	local t1 = pb.encode("MPZNode", group_node1)
    	local t2 = pb.encode("MPZNode", group_node2)
	    if round == 2 then
	    	Week_Data.db:set(flag_play1..gpid1, t1)
	    	Week_Data.db:set(flag_play1..gpid2, t2)
		elseif round == 3 then
			Week_Data.db:set(flag_play2..gpid1, t1)
			Week_Data.db:set(flag_play2..gpid2, t2)
		else
			Week_Data.db:set(gpid1, t1)
			Week_Data.db:set(gpid2, t2)
		end
	end    
	Week_Data.prepstatus = 1
	Week_Data.db:set(flag_prep, Week_Data.prepstatus)
    return 0
end

local function check_time()     -- 这里都是自然切换的时间 
	local Week_Data = gweek_data
    local now_time = os.time()
	local starttime = Week_Data.headinfo.opentime
	local lastUpdateTime = Week_Data.headinfo.lastupdatetime
	local interval = Week_Data.headinfo.interval
	if now_time < starttime then return end
	local new_mpz_time = lastUpdateTime + gchangeday*interval
	local new_start_day = math.floor((new_mpz_time - starttime)/interval)
	
	if now_time < svr_open_time then
		return 
	end

	--换届
	get_next_status(Week_Data, gpercent, gmaster_reg_time, gfight_time, gchangeday)
	if new_mpz_time <= now_time then 
		--关闭上届db			
		Week_Data.db:set(flag_status, END)
		Week_Data.db_status = DB_S_CLOSE
		Week_Data.db:close()
		--初始化新一届的db
		local t = {
				dayid = new_start_day,
				headinfo = {
					opentime = starttime,
					lastupdatetime = new_mpz_time,
					interval = interval,
					round = 1,
					attendnum = NIL,
				},
				prepstatus = 0,
                status = NIL,
                player = {}, -- 淘汰赛,包含了组合信息
				player1 = {}, --四强赛,包含了组合信息
				player2 = {}, --决赛,包含了组合信息
				rcd = {},
				rcd_idx = 0,
				db = kc.DB:new(),
				file = 'mpz' .. new_start_day .. '.kch',
				db_status = DB_S_NIL
		}

		clonetab_real(Week_Data, t)

		--load db
		load_db(new_start_day, Week_Data, kc.DB.OWRITER + kc.DB.OCREATE)
		Week_Data.status = REG
		Week_Data.db:set(flag_status, REG)
		LOG_INFO("mpz|change mpz: interval:"..interval.." lastupdatetime:".. lastUpdateTime.." newday:".. new_start_day)
		

		--删除上上届数据文件
		--LOG_INFO("mpz|del prepre mpzdata!")
		local ppday = new_start_day-3*gchangeday
		local ppfile = 'mpz' .. ppday .. '.kch'
		local ret, retcode = os.remove(ppfile)
		if ret == nil then LOG_ERROR(retcode) end
		G_IS_VALID = true
    end

    --战斗触发 
    --更新变量数据
	lastUpdateTime = Week_Data.headinfo.lastupdatetime
	--当前进度
	local diff = math.floor((now_time - lastUpdateTime)/interval)
	local round = Week_Data.headinfo.round
    local fightTime = lastUpdateTime + (round-1)*interval + math.floor(interval*gpercent) + gmaster_reg_time	
	local attendnum = Week_Data.headinfo.attendnum

	--无效赛程
    if G_IS_VALID == false then
    	Week_Data.headinfo.round = 4
    	Week_Data.status = END
    	local nextstatus = glastUpdateTime+ginterval*gchangeday
    	--LOG_INFO("mpz|inv|status:"..Week_Data.status.." preps:"..Week_Data.prepstatus.." nextstatus:"..(nextstatus-glastUpdateTime) .. " nowtime ".. (now_time-glastUpdateTime) .. " diff"..diff.." round"..round)
    	return 
    end 

	--这届结束，下场在下一届的时间
	if round > 3 then 
		fightTime = lastUpdateTime+interval*gchangeday+math.floor(interval*gpercent) + gmaster_reg_time
		diff = -1
	end

	--在淘汰赛成员报名结束时就开始添加机器人
	if now_time >= fightTime-gmaster_reg_time or diff > 0 then
		if round == 1 then 
    		--创建足量的机器人
    		if add_robotgroup(Week_Data, attendnum) ~= 1 then return end
		end	
	end

	--更新初始化战斗准备状态
	if status == REG or status == MATR_REG and Week_Data.prepstatus == 1 then
		Week_Data.prepstatus = 0
		Week_Data.db:set(flag_prep, Week_Data.prepstatus)
	end

	--print("mpz|status:"..Week_Data.status.." preps:"..Week_Data.prepstatus.. " nowtime ".. (now_time-lastUpdateTime) .. " fighttime"..(fightTime-lastUpdateTime).. " diff"..diff.." round"..round)
	if Week_Data.status ~= REG and Week_Data.status ~= END then
		LOG_INFO("mpz|status:"..Week_Data.status.." preps:"..Week_Data.prepstatus.." nowtime ".. (now_time-lastUpdateTime) .. " fighttime"..(fightTime-lastUpdateTime).. " diff"..diff.." round"..round)
    end

    if now_time >= fightTime or diff > round-1 then
		if round < 4 then
			--战斗
			LOG_INFO("mpz|nowtime:"..(now_time-lastUpdateTime).." interval:"..interval.." round:"..round.." attendnum: "..attendnum.." diff:"..diff)
			LOG_INFO("mpz|doFight!")
			--print("doFight")
			-- 全部完成
			if Week_Data.status ~= FINISH and Week_Data.status ~= END then
			    Week_Data.status = FIGHTING
			    Week_Data.db:set(flag_status, FIGHTING)
			end
			if Week_Data.prepstatus ~= 1 then
				--print("pre_fill_fieldinfo")
				if pre_fill_fieldinfo(Week_Data) ~= 0 then return end
			end
			local ret = do_fight(Week_Data)
			if ret == 1 then 
				LOG_INFO("mpz|doFight OK but not finish!")
				return --这里就返回了，下面不会执行
			elseif ret == 0 then
				LOG_INFO("mpz|doFight All Done!")
				--print("doFight All Done")
				do_select(Week_Data, round)
				if diff > round - 1 or status == FINISH then
					send_reward_by_time(Week_Data, round)
				end
				return
			end

			LOG_ERROR("mpz|doFight Err!")
			
		else --结束了，不打了
			return
		end
	end
end

local function find_player_from_group(group_data, user_name)
    local group_user = nil
    local status = 0
    if group_data.master.username == user_name then
        group_user = group_data.master
        status = 1
    end
    if not group_user and rawget(group_data, "master2") and group_data.master2.username == user_name then
        group_user = group_data.master2
        status = 2
    end
    if not group_user and rawget(group_data, "user_list") then
        for k,v in ipairs(group_data.user_list) do
            if v.username == user_name then
                group_user = v
                status = 3
                break
            end
        end
    end
    return group_user, status
end

--会长提交报名
local function master_regist(main_data, group_data, req)
	assert(group_data, "group_data is nil")
	group_cache.merge_cache_to(group_data)
    local user_group_data = rawget(main_data, "group_data")
    assert(user_group_data and user_group_data.groupid == group_data.groupid, "groupid err")
    local group_user,status = find_player_from_group(group_data, main_data.user_name)
    assert(group_user, "user not in this group")
	assert(status ~= 3, "not master or master2") --会长或副会长才能提交
	local Week_Data = gweek_data
    local nowtime = os.time()
	local starttime = Week_Data.headinfo.opentime
	local lastUpdateTime = Week_Data.headinfo.lastupdatetime
	local interval = Week_Data.headinfo.interval
	local round = Week_Data.headinfo.round
	local attendnum = Week_Data.headinfo.attendnum
	assert(round < 4, "mpz|all pk is finish can't reg")
	assert(G_IS_VALID, "mpz|invlid can't reg")
	--当前进度
	local diff = math.floor((nowtime - lastUpdateTime)/interval)
	local regEndTime = lastUpdateTime + (round-1)*interval + math.floor(interval*gpercent)
	--print("masterreg|regendtime:" , gmaster_reg_time)
	update_state(Week_Data, gpercent, gmaster_reg_time, gfight_time)
    assert(Week_Data.db_status == DB_S_PKOK)  --kch必须是打开状态
    assert(Week_Data.status == MATR_REG, "mpz|not in master regtime")

    assert(nowtime > regEndTime and nowtime < regEndTime + gmaster_reg_time, "mpz|out reg time!")

    local groupid = group_data.groupid

    local player = get_players_from_weekdata(Week_Data, round)
	local group_node = nil
	assert(player, "mpz|playerdata nil")
	if round == 1 then --淘汰赛，没有成员报名就没有门派信息
		assert(rawget(player, groupid), "mpz|not register")
	elseif round > 1 then --四强后，player数据系统产生
		assert(rawget(player, groupid), "mpz|out or not attend!")
	end

	group_node = player[groupid]
	assert(group_node, "mpz|group_node nil!")

	local members = {}
	local memidx = 0
	--验证req各数组长度，拉出所有人到一个数组
	for k,v in ipairs(req.fieldinfo) do
		local fightersize = 0
		if v.fighter then
			for k1,v1 in ipairs(v.fighter) do
				--print("fieldno", k, "|",k1, v1)
				fightersize = fightersize + 1
			end
		end
		assert(fightersize <= 3, "mpz|fieldno(" .. k .. ") signreq fighter(" .. fightersize .. ") > 3!")

		for k1,v1 in ipairs(v.fighter) do
			--if k1 > v.fighternum then break end
			--验证是否在签到名单
			local tmpname = v1
			local config = found_user_config(group_node, tmpname)
			assert(config,  "mpz|"..tmpname .. "(".. k.."x"..k1..") do not in signlist")
			members[memidx] = tmpname
			memidx = memidx + 1
		end
	end

	--验证是否有同名参赛者
	for i=0, memidx-2 do
		local tmp = members[i]
		for j=i+1, memidx-1 do
			assert(tmp ~= members[j], "mpz|signreq fieldinfo member["..i.."] ["..j.."] is same member("..tmp..")!")
		end
	end 
	local resp = {
        result = "OK",
        fieldsinfo = {},
        mpzreglist = {},
    }

    local reged = false
	if group_node.signflag == 1 then
		LOG_ERROR( "mpz|"..groupid.." has signed!")
		resp.result = "SIGNED"
		reged = true
	end

	if not reged then
		local valid = false
		local fieldno = 0
		local fieldsinfo = {}
		for k, v in ipairs(group_node.fieldsinfo) do
			fieldsinfo[k] = v
		end
		for k,v in ipairs(req.fieldinfo) do
			fieldsinfo[k].fighters = {}
			for k1,v1 in ipairs(v.fighter) do
				--if k1 > v.fighternum then break end
				assert(fieldsinfo[k])
				local tmpname = v1
				local config = found_user_config(group_node, tmpname)
				assert(config,  "mpz|"..tmpname .. "(".. k.."x"..k1..") do not in signlist") --前面验证过，一般不会报错

				--上传配置
				local fighter_info = {
					uid = config.data1.uid,
					rewardflag = 0,	--奖励标记位，领取后=1
					dead = 0,		--是否阵亡
				}
				table.insert(fieldsinfo[k].fighters, fighter_info)
				LOG_INFO("mpz|fieldno("..k..")|"..k1.."|add "..tmpname)
				--print("mpz|fieldno("..k..")|"..k1.."|add "..tmpname)
			end
		end

		for k,v in ipairs (fieldsinfo) do
			if v.fieldno == group_node.fieldsinfo[k].fieldno then
				group_node.fieldsinfo[k] = v
				for k1,v1 in ipairs (v.fighters) do
					--print("mpz|test1", k, k1, v1.uid)
				end
			end
		end
		--[[
		if test1 then 
			for k1=1,6 do
				for i = 1,3 do
					repeat
						if k1 == 1 and i == 1 then break end
				        local uid = flag_robot..(k1*100+i)..groupid
				        
						local fighter_info = {
							uid = uid,
							rewardflag = 0,	--奖励标记位，领取后=1
							dead = 0,		--是否阵亡
						}
						--print("add ", uid, k1, i)
						if not rawget(group_node.fieldsinfo[k1],"fighters") then group_node.fieldsinfo[k1].fighters = {} end
						group_node.fieldsinfo[k1].fighters[i] = fighter_info

						local status = 3 --普通成员
						local fn_len = rawlen(family_name)
					    local mn_len = rawlen(male_name)
					    local fmn_len = rawlen(female_name)
						local sex = math.random(2) - 1
				        local nickname = nil
				        if sex == 0 then
				            nickname = family_name[math.random(fn_len)]..male_name[math.random(mn_len)]
				        else
				            nickname = family_name[math.random(fn_len)]..female_name[math.random(fmn_len)]
				        end
						local robot_info = {
				            uid = uid,
				            power = 2999,
				            nick_name = nickname,
				            sex = sex,
				            level = 60,
				            star = 5,
				            vip = 0,
				            status = status,
				            robot = math.random(3000),
				        }

						local fighter_data = {
							data1 = robot_info,
						}

						--加到报名名单
						table.insert(group_node.mpzreglist, fighter_data)
						LOG_INFO("mpz|reg|add_robot|field: ".. fighter_data.data1.uid)
						break
					until true
				end
			end
		end]]

		--签到标记设置
		group_node.signflag = 1

		if round == 1 then 
    		--创建足量的机器人
    		if add_robotgroup(Week_Data, attendnum) ~= 1 then LOG_ERROR("mpz|add_robot err") end	
		end

		--预填充对手信息
		local fighternum = 0
		local groups_a = {}
		for k,v in pairs(player) do
			table.insert(groups_a, v)
			fighternum = fighternum + 1
		end

	 	groups_a = get_sort_data_by_round(Week_Data, round)

		for k = 1, fighternum, 2 do
			local gpid1 = groups_a[k].groupid
			if k+1 > fighternum then break end
			local gpid2 = groups_a[k+1].groupid
			local group_node1 = player[gpid1]
			local group_node2 = player[gpid2]

			if gpid1 == groupid then
				for i = 1,6 do
					
					if rawget(group_node2,"fieldsinfo") and rawget(group_node2.fieldsinfo[i], "fighters") then 
						group_node.fieldsinfo[i].enemys = {}
						for k,v in ipairs (group_node2.fieldsinfo[i].fighters) do
							local user_info = found_user_config(group_node2, v.uid)
							group_node.fieldsinfo[i].enemys[k] = user_info.data1
						end
					end
				end
				group_node.enemyid = group_node2.groupid
				break
			end

			if gpid2 == groupid then
				for i = 1,6 do
					if rawget(group_node1,"fieldsinfo") and rawget(group_node1.fieldsinfo[i], "fighters") then 
						group_node.fieldsinfo[i].enemys = {}
						for k,v in ipairs (group_node1.fieldsinfo[i].fighters) do
							local user_info = found_user_config(group_node1, v.uid)
							group_node.fieldsinfo[i].enemys[k] = user_info.data1
						end
					end
				end
				group_node.enemyid = group_node1.groupid
				break
			end
		end

		local pb = require "protobuf"
	    local t = pb.encode("MPZNode", group_node)
	    if round == 2 then
	    	Week_Data.db:set(flag_play1..groupid, t)
		elseif round == 3 then 
			Week_Data.db:set(flag_play2..groupid, t)
		else
			Week_Data.db:set(groupid, t)
		end

		LOG_INFO("mpz|masterreg|"..groupid)
	end

	resp.fieldsinfo.signflag = 1
	local t = {}
    if rawget(group_node,"fieldsinfo") then
    	for i = 1,6 do
    		t[i] = group_node.fieldsinfo[i]
    	end
    end

    resp.fieldsinfo.fieldsinfo = t
    local self = {
		groupid = groupid, 
		groupname = group_node.nickname,
		level = group_node.level,
		score = group_node.score,
	}

	resp.fieldsinfo.headinfo = {}
	table.insert(resp.fieldsinfo.headinfo, self)
	if rawget(group_node,"enemyid") then
		local enemy = {
			groupid = group_node.enemyid, 
			groupname = player[group_node.enemyid].nickname,
			level = player[group_node.enemyid].level,
			score = player[group_node.enemyid].score,
		}
		table.insert(resp.fieldsinfo.headinfo, enemy)
	end

	if rawget(group_node, "mpzreglist") then
		for k,v in ipairs (group_node.mpzreglist) do
			table.insert(resp.mpzreglist, v.data1)
		end
	end

	local group_info = group_cache.update_group(group_data)
	return resp, group_data
end

--玩家报名
local function mem_regist(main_data, knight_list, group_data, user_name)
	assert(group_data, "group_data is nil")
	group_cache.merge_cache_to(group_data)
    local user_group_data = rawget(main_data, "group_data")
    assert(user_group_data and user_group_data.groupid == group_data.groupid, "groupid err")
    local group_user,status = find_player_from_group(group_data, user_name)
    assert(group_user, "user not in this group")

    local Week_Data = gweek_data
    local groupid = group_data.groupid
    local nowtime = os.time()
	local starttime = Week_Data.headinfo.opentime
	local lastUpdateTime = Week_Data.headinfo.lastupdatetime
	local interval = Week_Data.headinfo.interval
	local round = Week_Data.headinfo.round
	local attendnum = Week_Data.headinfo.attendnum
	assert(round < 4, "mpz|all pk is finish can't reg")
	assert(G_IS_VALID, "mpz|invlid can't reg")
	--当前进度
	local diff = math.floor((nowtime - lastUpdateTime)/interval)
	local regEndTime = lastUpdateTime + (round-1)*interval + math.floor(interval*gpercent)
	--print("memreg|regendtime: ", (regEndTime-lastUpdateTime))
	--print("memreg|lastUpdateTime:"..lastUpdateTime.." interval:"..interval.." round:"..round.." attendnum: "..attendnum.." diff:"..diff)
	assert( nowtime < regEndTime,"mpz|memreg|out reg time!") 
	update_state(Week_Data, gpercent, gmaster_reg_time, gfight_time)
    assert(Week_Data.db_status == DB_S_PKOK)  --kch必须是打开状态
    assert(Week_Data.status == REG, "mpz|memreg|not reg time")
	local player = get_players_from_weekdata(Week_Data, round)
	assert(player, "mpz|memreg|playerdata nil")

	local group_node = nil
	local new_data = false
    --确认门派是否可报名
	if round > 1 then
		assert(player[groupid], "mpz|memreg|group not attend")
	elseif round == 1 then
		if not rawget(player, groupid) then
			local g = {
				groupid = groupid,
				nickname = group_data.nickname,
				fieldsinfo = {},		--6个战场信息，战斗前和战斗中信息
				fightid = attendnum+1,	--战斗编号 唯一 fightid = 0 不可用
				signflag = 0,			--签到标记
				winflag = 0,			--胜利次数，根据这个判奖励
				failflag = 0,			--淘汰 = 1,未淘汰 = 0
				randboxid = 0,			--奖励 在淘汰时或得冠军时产生,没用，奖励不是宝箱
				fightendtime = 0,		--今天门派战结束时间，校验下今天还昨天的时间
				mpzreglist = {},
				score = 0,
				level = group_data.level,
				enemyid = nil,
				winnum = 0,
			}
			--初始化6个战场
			for i = 1, 6 do
				local fieldsinfo = {
						fieldno = i,
						fighters = {},	--自己的成员
						enemys = {},	--对手，这里面没有奖励信息
						win = 0,		-- -1时，还在战斗中 0=输， 1=赢
						videonum = 0,	--录像总数
						fightinfo = {}, --不回fightbytes 另外拉取
						winnum = 0,
						failnum = 0,
				}
				g.fieldsinfo[i] = fieldsinfo
			end
			rawset(player, groupid, g)
			new_data = true
		end
	end

	--公会参赛开始4天内不能解散
	if new_data then
		local unlocktime = lastUpdateTime + interval*3
		--print ("grouplocktime:", unlocktime- nowtime, group_data.unlocktime-nowtime)
		if not rawget(group_data, "unlocktime") or group_data.unlocktime < unlocktime then
			group_data.unlocktime = unlocktime
		end
	end

	--会员今天内不能退出公会
	local unlocktime = lastUpdateTime + round*interval
	--print ("locktime:", unlocktime, group_user.unlocktime-nowtime)
	if not rawget(group_user, "unlocktime") or group_user.unlocktime < unlocktime then
		group_user.unlocktime = unlocktime
	end

	group_node = player[groupid]
	assert(group_node)

	if rawget(group_node, "mpzreglist") then
		--是否报过名
		for k,v in ipairs(group_node.mpzreglist ) do
			local tmpname = v.data1.uid
			--print("tmpname:", tmpname, "user_name", user_name)
			assert(tmpname ~= user_name, "mpz|memreg|"..user_name.." has reg")
		end
	end


	local t_knight_list = {}
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            local t = v.knight.data.level
            local jiban_list = rawget(v.knight.data, "jiban_list")
            if jiban_list then
                for k1,v1 in ipairs(jiban_list) do
                    if v1 >= 0 then
                        local t = core_user.get_knight_from_bag_by_guid(v1, knight_list)
                        assert(t, "mpz|knight not find")
                        local tk1 = t[2]
                        table.insert(t_knight_list, tk1)
                    end
                end
            end
        end
    end

	local player_data = 
    {
    	data1 = {
			uid = user_name,
			power = main_data.power,
			nick_name = main_data.nickname,
	        sex = main_data.lead.sex,
	        level = main_data.lead.level,
	        star = main_data.lead.star,
	        vip = main_data.vip_lev,
			status = status,
		},
		data2 = {
	        lead = main_data.lead,
	        zhenxing = main_data.zhenxing,
	        lover_list = main_data.lover_list,
	        book_list = main_data.book_list,
	        reputation = main_data.PVP.reputation,
	        wxjy = main_data.wxjy,
	        knight_list = t_knight_list,
	        sevenweapon = main_data.sevenweapon,
	    }
    }

    if not rawget(group_node, "mpzreglist") then
    	rawset(group_node, "mpzreglist", {})
  	end
    
    table.insert(group_node.mpzreglist, player_data)

    --更新公会等级
    group_node.level = group_data.level

    local function comps1(a,b)
    	if a.data1.power ~= b.data1.power then
    		return a.data1.power > b.data1.power
    	else
    		return a.data1.level > b.data1.level
    	end
    end

    --降序排序
    table.sort(group_node.mpzreglist, comps1)
    --[[
    for k,v in ipairs (group_node.mpzreglist) do
    	print("memreg|name", v.data1.uid, "power", v.data1.power, "level", v.data1.level)
    end]]

    LOG_INFO("mpz|memreg|"..main_data.user_name)
 
    if new_data then
		Week_Data.headinfo.attendnum = attendnum+1
		local pb = require "protobuf"
	    local h = pb.encode("mpz_head_info", Week_Data.headinfo)
	    Week_Data.db:set(flag_head, h) 
	end

    local pb = require "protobuf"
    local t = pb.encode("MPZNode", group_node)
    if round == 2 then
    	Week_Data.db:set(flag_play1..groupid, t)
	elseif round == 3 then 
		Week_Data.db:set(flag_play2..groupid, t)
	else
		Week_Data.db:set(groupid, t)
	end

	--奖励
	local item_list = {}
	local conf_reward = Xue_Rank_conf[7]
	local item = {}
	for k,v in ipairs(conf_reward["Member_Re"]) do
		if k%2 == 1 then
			item.id = v
		else
			item.num = v
			table.insert(item_list, item)
			item = {}
		end
	end

	local mail = {
		type = 10,
		from = lang_mpz.mpz_sender,
		subject = lang_mpz.mpz_reg_title,        
    	message = lang_mpz.mpz_reg_msg,      
    	item_list = item_list,        
    	stamp = os.time(),
		guid = 0,
		expiry_stamp = 0,
	}
	LOG_INFO("mpz|reg|add_mail|"..user_name)
	redo_list.add_mail(user_name, mail)

    local group_info = group_cache.update_group(group_data)
    return main_data, group_data
end

local function get_mpz_info(main_data, group_data, req, user_name)
	local Week_Data = gweek_data
	local now_time = os.time()
	local ret = 0
	local flag = req.flag
	local pre = req.pre
	local fieldno = req.fieldno
	local round = Week_Data.headinfo.round
	local groupid = nil
	local diff = math.floor((now_time - Week_Data.headinfo.lastupdatetime)/Week_Data.headinfo.interval)
	local respround = diff + 1
	if round <= diff then
    	respround = round
    end

	local nextstatus = get_next_status(Week_Data, gpercent, gmaster_reg_time, gfight_time, gchangeday)
	local status = Week_Data.status
	local resp = {
            result = "OK",        
            fieldinfo = nil,
            statusinfo = {					--服务器状态信息
            	round = respround, 			--round>1自动回复四强信息
				status = status, 			--服务器状态 1=reg 2=masterreg 3=fighting 4=finish 5=end 0 = 不可用
				nextstatus = nextstatus, 	--下个状态的时间戳
				regflag = 0,				--是否报名(1/2)
				configflag = 0,				--1=有人参赛，0=无人参赛(1/2)
				failflag = 0,				--淘汰 = 1,未淘汰 = 0(4/5)
				fourinfo = nil,				--结构4->2 
            },
            mpzreglist = nil,
			flag = flag,
            alldata = nil,
        }

    --关闭重置
    if flag == 999 then flag = 0 end
    --无效赛程
    if flag ~= 999 and G_IS_VALID == false then
		resp.statusinfo.status = END
		resp.statusinfo.round = 4
		resp.result = "INVALID"
    	resp.statusinfo.nextstatus = glastUpdateTime + ginterval*gchangeday + 15 --客户端延时15s 让服务器完成换届
		--LOG_INFO("mpz|get|inv|nowtime:".. (now_time-glastUpdateTime).."s nextstatus:"..(nextstatus-glastUpdateTime)..  "s diff:"..diff.." round:"..round)       	
    	return resp, nil
    end

    if status == FIGHTING then
    	if Week_Data.prepstatus ~= 1 then
			--LOG_INFO("pre_fill_fieldinfo")
			pre_fill_fieldinfo(Week_Data)
		end
	end

	if (status == REG or status == MATR_REG) and Week_Data.prepstatus == 1 then
		Week_Data.prepstatus = 0
		Week_Data.db:set(flag_prep, Week_Data.prepstatus)
	end
	--get_sort_data_by_round(Week_Data, 1)
    assert(fieldno >= 0 and fieldno < 7, "req.fieldno ".. fieldno .." err!")
    --print("mpz|get|"..user_name.." flag:"..flag)
    --print("mpz|get|nowtime:".. (now_time-Week_Data.headinfo.lastupdatetime).." status:"..status.." nextstatus:"..(nextstatus-Week_Data.headinfo.lastupdatetime).." preps:"..Week_Data.prepstatus..  " diff"..diff.." round"..round)
    --debug_week_data(Week_Data)
    --print("get: interval:"..Week_Data.headinfo.interval.. " round:"..round.." attendnum: "..Week_Data.headinfo.attendnum)
	--LOG_INFO("mpz|get: interval:"..Week_Data.headinfo.interval.." nowtime"..(os.time()-Week_Data.headinfo.lastupdatetime).." round:"..round.." attendnum: "..Week_Data.headinfo.attendnum)
	--四强信息
	if round > 1 and pre ~= 1 then 
		local fourinfo = {}
		local player = Week_Data.player
		local player1 = Week_Data.player1
		local player2 = Week_Data.player2
		assert(player and player1)

		local wingroups = get_sort_data_by_round(Week_Data, 2)

		for j = 1, 4, 2 do
			local tmpid1 = wingroups[j].groupid
			local tmpid2 = wingroups[j+1].groupid

			local combo = {
				groupid1 = tmpid1,
				groupid2 = tmpid2,
				winner = nil,
				round = 2,
				nickname1 = player[tmpid1].nickname,
				nickname2 = player[tmpid2].nickname,
				level1 = player[tmpid1].level,
				level2 = player[tmpid2].level,
			}

			if player1 and round > 2 then		
				if player1[tmpid1].winflag > player1[tmpid2].winflag then
					combo.winner = tmpid1
					combo.score1 = player1[tmpid1].score
					combo.score2 = player1[tmpid2].score
					combo.winnum1 = player1[tmpid1].winnum
					combo.winnum2 = player1[tmpid2].winnum
				elseif player1[tmpid1].winflag < player1[tmpid2].winflag then
					combo.winner = tmpid2
					combo.score1 = player1[tmpid1].score
					combo.score2 = player1[tmpid2].score
					combo.winnum1 = player1[tmpid1].winnum
					combo.winnum2 = player1[tmpid2].winnum
				end
				--print("winner|", 3, combo.winner)
			end
			table.insert(fourinfo, combo)
		end

		if round > 2 then
			local tmpid1 = nil
			local tmpid2 = nil
		
			if fourinfo[1].winner then
				tmpid1 = fourinfo[1].winner
			end
			if fourinfo[2].winner then
				tmpid2 = fourinfo[2].winner
			end
			--print("3|", tmpid1, tmpid2)
			local combo = {
				groupid1 = tmpid1,
				groupid2 = tmpid2,
				winner = nil,
				round = 3,
				nickname1 = player1[tmpid1].nickname,
				nickname2 = player1[tmpid2].nickname,
				level1 = player1[tmpid1].level,
				level2 = player1[tmpid2].level,
			}

			if player2 and round == 4 then
				if player2 and player2[tmpid1].winflag > player2[tmpid2].winflag then
					combo.winner = tmpid1
					combo.score1 = player2[tmpid1].score
					combo.score2 = player2[tmpid2].score
					combo.winnum1 = player2[tmpid1].winnum
					combo.winnum2 = player2[tmpid2].winnum
				elseif player2[tmpid1].winflag < player2[tmpid2].winflag then
					combo.winner = tmpid2
					combo.score1 = player2[tmpid1].score
					combo.score2 = player2[tmpid2].score
					combo.winnum1 = player2[tmpid1].winnum
					combo.winnum2 = player2[tmpid2].winnum
				end
				--print("4|winner", combo.winner)
			end
			table.insert(fourinfo, combo)
		end

		--战斗中，屏蔽四强结果
		if status == FIGHTING then
			if round == 2 and diff == 0 then 
				fourinfo = nil
			elseif round == 3 and diff == 1 then
				fourinfo[1].winner = nil
				fourinfo[1].score1 = 0
				fourinfo[1].score2 = 0
				fourinfo[1].winnum1 = 0
				fourinfo[1].winnum2 = 0
				fourinfo[2].winner = nil
				fourinfo[2].score1 = 0
				fourinfo[2].score2 = 0
				fourinfo[2].winnum1 = 0
				fourinfo[2].winnum2 = 0
				fourinfo[3] = nil
			elseif round == 4 and diff == 2 then
				fourinfo[3].winner = nil
				fourinfo[3].score1 = 0
				fourinfo[3].score2 = 0
				fourinfo[3].winnum1 = 0
				fourinfo[3].winnum2 = 0
			end
		end

		resp.statusinfo.fourinfo = fourinfo
	end

	if flag >= 0 and flag ~= 956 and flag ~= 999 then
		assert(group_data, "group_data is nil")
		group_cache.merge_cache_to(group_data)
	    local user_group_data = rawget(main_data, "group_data")
	    assert(user_group_data and user_group_data.groupid == group_data.groupid, "groupid err")
	    local group_user, mstatus = find_player_from_group(group_data, user_name)
	    assert(group_user, "user not in this group")
	    local tround = diff + 1
	    if round <= diff then
	    	tround = round
	    end

	    if pre == 1 then 
	    	tround = tround - 1 
	    end

	    assert(tround>0, "mpz|no pre data")
		groupid = group_data.groupid
		if tround > 3 then tround = 3 end
		local player = get_players_from_weekdata(Week_Data, tround)
		assert(player)
		--print("tround", tround)
		group_node = player[groupid]
		if group_node == nil then
			if pre == 1 then
				assert(false, "mpz|no attend preround")
			else
				resp.result = "NOATTEND"
			end
		else
			local has_reg = false
			if rawget(group_node, "mpzreglist") then
				for k,v in ipairs (group_node.mpzreglist) do
					has_reg = true
					if v.data1.uid == user_name then
						resp.statusinfo.regflag = 1
						break
					end
				end
			end

			if has_reg or (round > 1 and status ~= REG) then
				resp.statusinfo.configflag = 1
			end
			--报名名单
			--assert(mstatus ~= 3, "not master!")
			if rawget(group_node, "mpzreglist") then
				resp.mpzreglist = {}
				for k,v in ipairs (group_node.mpzreglist) do
					table.insert(resp.mpzreglist, v.data1)
				end
			end

			resp.statusinfo.failflag = 0

			if status == FIGHTING or status == FINISH or status == END then
				if not rawget(group_node, "failflag") or group_node.failflag == 0 then
					resp.statusinfo.failflag = -1
				else
					resp.statusinfo.failflag = 1
				end
			end

			--LOG_INFO("mpz|get|failflag:"..resp.statusinfo.failflag)

			if pre == 1 then --前一天的战场信息
				local self = {
					groupid = groupid, 
					groupname = group_node.nickname,
					level = group_node.level,
					score = group_node.score,
				}
				resp.fieldinfo = {} 
				resp.fieldinfo.headinfo = {}
				table.insert(resp.fieldinfo.headinfo, self)
				--战场信息	
				resp.fieldinfo.signflag = group_node.signflag	
				if rawget(group_node, "fieldsinfo") then
					local t = {}
					if fieldno == 0 then
						for k = 1,6 do
							table.insert(t, group_node.fieldsinfo[k])
						end
					elseif fieldno > 0 and fieldno < 7 then
						table.insert(t, group_node.fieldsinfo[fieldno])
					end
					resp.fieldinfo.fieldsinfo = t
					
					if rawget(group_node, "enemyid") then
						local enemy = {
							groupid = group_node.enemyid, 
							groupname = player[group_node.enemyid].nickname,
							level = player[group_node.enemyid].level,
							score = player[group_node.enemyid].score,
						}
						table.insert(resp.fieldinfo.headinfo, enemy)
					end	
				end
			elseif flag == 1 then --当天的战场信息
				local self = {
					groupid = groupid, 
					groupname = group_node.nickname,
					level = group_node.level,
					score = group_node.score,
				}

				resp.fieldinfo = {}
				resp.fieldinfo.headinfo = {}
				table.insert(resp.fieldinfo.headinfo, self)
				resp.fieldinfo.signflag = group_node.signflag
				if status ~= REG then --报名时间不可用
				 	if rawget(group_node, "fieldsinfo") then
						local t = {}
						if fieldno == 0 then
							for k = 1,6 do
								table.insert(t, group_node.fieldsinfo[k])
							end
						elseif fieldno > 0 and fieldno < 7 then
							table.insert(t, group_node.fieldsinfo[fieldno])
						end

						resp.fieldinfo.fieldsinfo = t
					end
					if rawget(group_node, "enemyid") and player[group_node.enemyid] then
						local enemy = {
							groupid = group_node.enemyid, 
							groupname = player[group_node.enemyid].nickname,
							level = player[group_node.enemyid].level,
							score = player[group_node.enemyid].score,
						}
						table.insert(resp.fieldinfo.headinfo, enemy)
					end
				end
			end
		end
		local group_info = group_cache.update_group(group_data)
		return resp, group_data

	elseif flag == 956 then
		local alldata = {
			lastupdatetime = Week_Data.headinfo.lastupdatetime,	--上次更新时间，即本届开始时间(每周四0点)
			interval = Week_Data.headinfo.interval, 			--每轮战斗间隔
			round = round,										--第几轮，0=报名 1=完成淘汰赛 2=完成半决赛 3=出冠军，看结果
			attendnum = Week_Data.headinfo.attendnum,			--参赛者门派个数
			attendances = {}
		}

		groupid = req.groupname
		--拉取所有该工会相关信息
		local player = get_players_from_weekdata(Week_Data, pre)
		assert (player, "player"..pre.." is nil") 
		local group_node = player[groupid]
		if group_node then
			table.insert(alldata.attendances, group_node)
		end
		clonetab_real(resp.alldata, alldata)
        if resp.alldata then
            for k,v in ipairs(resp.alldata.attendances) do
                for k1,v1 in ipairs(v.mpzreglist) do
                    v1.data2 = {}
                end
            end
        end
		return resp, nil
	elseif flag == 999 then
		--关闭上届db	
		if 	G_IS_VALID then
			Week_Data.db:set(flag_status, END)
			Week_Data.db_status = DB_S_CLOSE
			Week_Data.db:close()
		end
		--删除上上届数据文件
		local new_start_day = 0
		for i = 0,3 do
			local ppfile = 'mpz'..(new_start_day + i*gchangeday)..'.kch'
			os.remove(ppfile)
		end
		local nowtime = os.time()
		
		--初始化新一届的db
		local t = {
				dayid = new_start_day,
				headinfo = {
					opentime = nowtime,
					lastupdatetime = nowtime,
					interval = ginterval,
					round = 1,
					attendnum = NIL,
				},
				prepstatus = 0,
                status = NIL,
                player = {}, -- 淘汰赛,包含了组合信息
				player1 = {}, --四强赛,包含了组合信息
				player2 = {}, --决赛,包含了组合信息
				rcd = {},
				rcd_idx = 0,
				db = kc.DB:new(),
				file = 'mpz' .. new_start_day .. '.kch',
				db_status = DB_S_NIL
		}

		clonetab_real(Week_Data, t)

		--load db
		load_db(new_start_day, Week_Data, kc.DB.OWRITER + kc.DB.OCREATE)
		Week_Data.status = REG
		Week_Data.db:set(flag_status, REG)
		G_IS_VALID = true
		return resp, nil
    end	
    assert(false, "flag error!")
	return resp, nil
end

--获取战斗rcd
local function get_rcd(req)
    --print("videoidx",req.videoidx)
    local rcd_idx = req.videoidx
    local rcd_list = gweek_data.rcd
    local rcd = rcd_list[rcd_idx]
    --print("rcd",rcd)
    assert(rcd and rcd ~= 0)
    local rcd_buf = gweek_data.db:get(flag_rcd..rcd)
    local pb = require "protobuf"
    rcd = pb.decode("FightRcd", rcd_buf)
    return rcd
end

local mpz = {
	found_user_config = found_user_config,
    get_players_from_weekdata = get_players_from_weekdata,
    master_regist = master_regist,
    mem_regist = mem_regist,
    get_mpz_info = get_mpz_info,
    get_rcd = get_rcd,
    check_time = check_time,
    get_status = get_status,
}

return mpz