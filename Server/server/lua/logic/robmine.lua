--门派战
local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert
local core_fight = require "fight"
local kc = require "kyotocabinet"
local core_user = require "core_user_funcs"
local core_money = require "core_money"
local core_power = require "core_calc_power"


local G_FINISH_TIMES = 10
local G_PROTECT_TIME = 3600
local G_PER_HOUR_TIME = 3600
local G_MAX_PRODUCE_TIME = G_FINISH_TIMES*G_PER_HOUR_TIME
local G_RCD_REMOVE_TIME = 3600*24*7
local G_MAX_JINGLI = 99
local flag_rcd = "rcd"
local flag_rcdidx = "rdx"
local flag_robot = "Robot_"

local gmine_data = { 
               	totalnum = 0,
                mines = {}, -- 所有矿洞
                rcd = {},
                rcd_idx = 0,
                db = kc.DB:new(),
                file = 'robmine.kch',
        }
--[[
    mines{} 矿洞数组，里面是玩家的{Mine_Info_Kch data}详细见robmine.proto
    rcd{} 录像列表索引 
]]


--加载数据
local function load_db(Mine_Data, type)
    if not Mine_Data.db:open(Mine_Data.file, type) then
        LOG_ERROR(Mine_Data.file.." open err")
    else  
        Mine_Data.db:iterate(
            function(k1,v1)
                local flag = string.sub(k1, 1, 3)
                if flag == flag_rcdidx then
                	Mine_Data.rcd_idx = tonumber(v1)
                elseif flag == flag_rcd then
                    local rcd_idx = tonumber(string.sub(k1, 4))
                    local pb = require "protobuf"
                    local d = pb.decode("MineFightRcd", v1)
                    --print("load_db|rcd:", rcd_idx, os.time() - d.timestamp)
                    Mine_Data.rcd[rcd_idx] = {idx = rcd_idx, timestamp = d.timestamp}
				else
                    --print("load_db|mines:", k1)
                    local pb = require "protobuf"
                    local d = pb.decode("MineSingleInfo", v1)
                    rawset(Mine_Data.mines, k1, d)
                    Mine_Data.totalnum = Mine_Data.totalnum + 1
                end
            end, false
        )
    end
end

--load_db(gmine_data, kc.DB.OWRITER + kc.DB.OCREATE)
--print("ROBMINE|init totalnum:".. gmine_data.totalnum.. " rcdidx:"..gmine_data.rcd_idx)
--LOG_INFO("ROBMINE|init totalnum:".. gmine_data.totalnum.. " rcdidx:"..gmine_data.rcd_idx)

local function comps1(a,b)
	return a.begintime < b.begintime
end

local function comps2(a,b)
	return a.user.level < b.user.level
end

local function update_jingli_per_20min(mineinfo)
    local ret = false
    local nowtime = os.time()
    if not mineinfo then return ret end
    if not mineinfo.jinglitimestamp then mineinfo.jinglitimestamp = nowtime end
    local lasttime = mineinfo.jinglitimestamp
    if lasttime == 0 then lasttime = nowtime end
    local difftime = nowtime - lasttime
    if difftime <= 0 then
        difftime = 0
        mineinfo.jinglitimestamp = nowtime
    end
    local diff20min = math.floor(difftime / 1200)
    if diff20min > 0 then
        ret = true
        
        mineinfo.jinglitimestamp = diff20min * 1200 + lasttime
        local max_hp = 30
        local nowhp = mineinfo.jingli
        if nowhp < max_hp then
            local newhp = nowhp + diff20min
            if newhp > max_hp then diff20min = max_hp - nowhp end
            LOG_INFO("ROBMINE|nowjingli: "..nowhp.. " + add:".. diff20min)
            mineinfo.jingli = nowhp + diff20min
        elseif nowhp > 99 then mineinfo.jingli = 99 end
    end

    return true
end

local function get_can_rob_minelist(Mine_Data)
	local nowtime = os.time()
	local list = {}
	if Mine_Data.mines then
		for k,v in pairs(Mine_Data.mines) do
			if nowtime < v.begintime + G_MAX_PRODUCE_TIME*9/10 and nowtime > v.lockendtime then
				table.insert(list, v)
				--print("canrob|", k)
			end
		end
	end
	table.sort(list, comps2)
	return list
end


local function get_minelist_by_level(Mine_Data, Level, uid)
	local t = get_can_rob_minelist(Mine_Data)
	local list = {}
	if t then
		for k,v in ipairs(t) do
			if math.abs(v.user.level - Level) <= 5 then
				if v.user.uid ~= uid then --过滤自己
					table.insert(list, v)
				end
			end
		end
	end

	return list
end

local function check_begintime(begintime)
	local nowtime = os.time()
	local status = 0
	if begintime == 0 then return -1 end
	if begintime < 0 then return begintime end
	if begintime > 0 then
		if begintime + G_MAX_PRODUCE_TIME > nowtime then 
			return begintime 
		else
			return -2
		end
	end
end

local function check_knight_lock( main_data, knight_list, old_list )
	local t = {}
	local change_list = {}
	for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
		if v.status == 2 then
			table.insert(t, {guid = v.knight.guid, lock = 1})
		end
	end

	local tmp = main_data.PVE.pve2.zhenxing
	if rawget(main_data.PVE.pve2, "zhenxing") then
		for k,v in ipairs(main_data.PVE.pve2.zhenxing) do
			if v.guid >= 0 then
				--print("pve2:",v)
				local found = false
				for k1,v1 in ipairs(t) do
					if v1.guid == v.guid then
						found = true
						v1.lock = v1.lock + 1
						break
					end
				end

				if not found then
					table.insert(t, {guid = v.guid, lock = 1})
				end
			end
		end
	end
	tmp = main_data.mineinfo
	if rawget(main_data, "mineinfo") then
		local tmp = main_data.mineinfo.def_knight_list
		if rawget(main_data.mineinfo, "def_knight_list") then
			for k,v in ipairs(main_data.mineinfo.def_knight_list) do
				if v.status == 2 then
					local found = false
					--print("def_knight_list:",v.knight.guid)
					for k1,v1 in ipairs(t) do
						if v1.guid == v.knight.guid then
							found = true
							v1.lock = v1.lock + 1
							break
						end
					end

					if not found then
						table.insert(t, {guid = v.knight.guid, lock = 1})
					end
				end
			end
		end
		tmp = main_data.mineinfo.atkdata
		if tmp then
			tmp = main_data.mineinfo.atkdata.last_atk_list
		end
		if rawget(main_data.mineinfo, "atkdata") and rawget(main_data.mineinfo.atkdata, "last_atk_list") then
			for k,v in ipairs(main_data.mineinfo.atkdata.last_atk_list) do
				if v >= 0 then
					--print("last_atk_list:",v)
					local found = false
					for k1,v1 in ipairs(t) do
						if v1.guid == v then
							found = true
							v1.lock = v1.lock + 1
							break
						end
					end

					if not found then
						table.insert(t, {guid = v, lock = 1})
					end
				end
			end
		end
	end

	for k, v in ipairs(t) do
		--LOG_INFO("lock|".. v.guid.." ".. v.lock)
		local k1 = core_user.get_knight_by_guid(v.guid, main_data, knight_list)
        assert(k1 and k1[2])
        local jiban = rawget(k1[2].data, "jiban_list")
        
        if k1[2].data.lock ~= v.lock then
        	LOG_INFO(main_data.user_name.." change|".. v.guid.." ".. k1[2].data.lock.." ".. v.lock)
        	k1[2].data.lock = v.lock
        	table.insert(change_list, k1[2])
        end
        core_user.init_knight(k1[2])
    end

    if old_list then
	    for k,v in ipairs(old_list) do
	    	if v >= 0 then
	    		--print("old ".. v)
	    		local found = false
		    	for k1,v1 in ipairs(t) do
		    		if v1.guid == v then
		    			found = true
		    			break
		    		end
		    	end

		    	if not found then
	    			local k2 = core_user.get_knight_by_guid(v, main_data, knight_list)
			        assert(k2 and k2[2])
			        local jiban = rawget(k2[2].data, "jiban_list")
			        if k2[2].data.lock ~= 0 then
			        	LOG_INFO(main_data.user_name.." change2|".. v.." ".. k2[2].data.lock.."->0 ")
			        	k2[2].data.lock = 0
			        end
			        
			        table.insert(change_list, k2[2])
			        core_user.init_knight(k2[2])
				end
			end
		end
	end

    return change_list
end

local function remove_no_result_defrcd(defrcd)
	local t = {}
	for k,v in ipairs(defrcd) do
		if v.win ~= 0 then
			table.insert(t, v)
		end
	end
	return t
end


local function get_produce_from_conf(power)
	local confsize = Baozang_conf.len
	local idx = Baozang_conf.index[confsize]
	local conf = Baozang_conf[idx] --如果下面循环没找到配置就以最后一个作为配置
	for i = 1, confsize do
		local x = Baozang_conf.index[i]
		local t = Baozang_conf[x]
		if power >= t.START and power <= t.END then
			conf = t
			break
		end
	end

	confsize = Bao_Yin_conf.len
	idx = Bao_Yin_conf.index[confsize]
	local conf1 = Bao_Yin_conf[idx]
	for i = 1, confsize do
		local x = Bao_Yin_conf.index[i]
		local t = Bao_Yin_conf[x]
		if power >= t.START and power <= t.END then
			conf1 = t
			break
		end
	end

	local produce = {
		power = power,
		gold = conf1.BASE + math.floor((power-conf1.START)*conf1.XISHU/100),
		jinjiedan = conf.DAN,
		xuantie = conf.IRON,
	}
	
	return produce
end

local function update_produce(begintime, produce, nowpower, uid, retrob)

	local Mine_Data = gmine_data
	local nowtime = os.time()
	if begintime == -1 then --没采矿
		produce = {}
		return 
	end
	if begintime == -2 then
		begintime = nowtime - G_MAX_PRODUCE_TIME - 10
	end

	local hours = math.floor((nowtime - begintime)/G_PER_HOUR_TIME)
	if not produce then
		produce = {}
	end
	local producesize = #produce

	if hours > G_FINISH_TIMES then
		hours = G_FINISH_TIMES
	end

	--print("ROBMINE|update_produce|"..begintime.." nowpower:".. nowpower.." uid:".. uid)

	for i = 1, hours do
		if i > producesize then --记录为生成说明还没被抢过，完整记录
			local p = get_produce_from_conf(nowpower)
			p.hour = i
			--print("ROBMINE|PRODUCESFULL|uid:".. uid.. " power:"..p.power.. " hour:" .. i.. " gold:"..p.gold)
			table.insert(produce, p)
		end
	end

	if hours+1 <= G_FINISH_TIMES and #produce < hours+1 then
		local p = get_produce_from_conf(nowpower)
		p.hour = hours+1
		--print("ROBMINE|THISHOUR|uid:"..uid.. " power:"..p.power .." hour:" .. hours+1 .." gold:".. p.gold)
		table.insert(produce, p)
	end

	--同步
	local gmineinfo = Mine_Data.mines[uid]
	if gmineinfo then
		gmineinfo.produce = produce
		local pb = require "protobuf"
		local t = pb.encode("MineSingleInfo", gmineinfo)

		Mine_Data.db:set(uid, t)
	end

	local nowproduce = {
		gold = 0,
		jinjiedan = 0,
		xuantie = 0,
	}
	local nextproduce = get_produce_from_conf(nowpower)
		
	if nowtime > begintime + G_MAX_PRODUCE_TIME then
		for k,v in ipairs(produce) do
			nowproduce.gold = nowproduce.gold + v.gold
			if v.robed ~= 1 then
				nowproduce.jinjiedan = nowproduce.jinjiedan + v.jinjiedan
				nowproduce.xuantie = nowproduce.xuantie + v.xuantie
			end
		end
	else
		for k,v in ipairs(produce) do
			if k < #produce then
				nowproduce.gold = nowproduce.gold + v.gold
				if v.robed ~= 1 then
					nowproduce.jinjiedan = nowproduce.jinjiedan + v.jinjiedan
					nowproduce.xuantie = nowproduce.xuantie + v.xuantie
				end
			end
		end
	end
	if retrob then 
		local robproduce = clonetab(produce[#produce-1])
		robproduce.gold = math.floor(robproduce.gold*3/5)
		return robproduce
	end
	return nowproduce, nextproduce
end

local function remove_db_rcd(Mine_Data, rcdidx )
	local rcd_list = Mine_Data.rcd
    local rcd = rcd_list[rcdidx]
    if rcd and rcd.idx and rcd.idx ~= 0 then 
    	local ret = gmine_data.db:remove(flag_rcd..rcd.idx)
    	if ret then
    		Mine_Data.rcd[rcdidx] = nil
    		LOG_INFO("ROBMINE|remove db rcd:".. rcdidx.. " success!" )
		else
			LOG_INFO("ROBMINE|remove db rcd:".. rcdidx.. " fail!" )
		end
    	return ret
    end

    return false
end

local function remove_rcd_by_time(nowtime, defrcd)
	if defrcd then
		--删除过期录像
		local newrcd = {}
		local rmlist = {}
		for k,v in ipairs(defrcd) do
			if v.lastfighttime + G_RCD_REMOVE_TIME > nowtime then
				table.insert(newrcd, v)
			end
		end

		return newrcd
	end

	return defrcd
end

local function remove_rcd_by_size(defrcd)
	if defrcd then
		--删除超过长度的录像
		local newrcd = {}
		local rmlist = {}
		for k,v in ipairs(defrcd) do
			if k <= 30 then
				table.insert(newrcd, v)
			end
		end

		return newrcd
	end

	return defrcd
end

local function get_mineinfo(main_data)
	local nowtime = os.time()
	local mineinfo = main_data.mineinfo
	if not rawget(main_data, "mineinfo") then
		LOG_INFO("init mineinfo")
		main_data.mineinfo = {
			jingli = 28,
			def_knight_list = main_data.zhenxing.zhanwei_list,
			defdata = {},
			atkdata = {},
			protectendtime = 0,
			begintime = -1,
			defrcd = {},
			produce = {},
			nowpower = 0,
			searchtimes = 0,
			jinglitimestamp = nowtime,
			maxrcdno = 0,
			getjingli = 0,
		}
	end

	mineinfo = main_data.mineinfo

	update_jingli_per_20min(mineinfo)

	local t = mineinfo.defrcd
	t = rawget(mineinfo, "defrcd")
	if not t then
		mineinfo.defrcd = {}
	end

	t = mineinfo.defrcd.rcd

	mineinfo.defrcd = remove_rcd_by_time(nowtime, mineinfo.defrcd)
	for k,v in ipairs(mineinfo.defrcd) do	
		if mineinfo.protectendtime <= nowtime then
			if v.win == 0 then
				v.win = 1
			end
		end
	end

	t = mineinfo.def_knight_list
	t = rawget(mineinfo, "def_knight_list")
	if not t then
		mineinfo.def_knight_list = {}
	end

	if #mineinfo.def_knight_list == 0 then
		mineinfo.def_knight_list = main_data.zhenxing.zhanwei_list		
	elseif #mineinfo.def_knight_list < 7 then
		for i = #mineinfo.def_knight_list+1, 7 do
			mineinfo.def_knight_list[i].status = 0
		end
	end

	t = mineinfo.defdata
	t = rawget(mineinfo, "defdata")
	if not t then
		mineinfo.defdata = {}
	end

	t = mineinfo.atkdata
	t = rawget(mineinfo, "atkdata")
	if not t then
		mineinfo.atkdata = {}
	end

	local tmp = mineinfo.atkdata.last_atk_list

	if not rawget(mineinfo.atkdata, "last_atk_list") or #mineinfo.atkdata.last_atk_list ~= 7 then
		LOG_INFO(main_data.user_name.. " last_atk_list init!")
		mineinfo.atkdata.last_atk_list = {}
		
		for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
			if v.status == 2 then
				table.insert(mineinfo.atkdata.last_atk_list, -2)
			elseif v.status == 1 then
				table.insert(mineinfo.atkdata.last_atk_list, -1)
			elseif v.status == 0 then
				table.insert(mineinfo.atkdata.last_atk_list, -2)
			end
		end	
	end

	local t = mineinfo.produce
	t = rawget(mineinfo, "produce")
	if not t then
		mineinfo.produce = {}
	end

	mineinfo.begintime = check_begintime(mineinfo.begintime)

	return main_data.mineinfo
end

local function update_def_power( main_data, knight_list, deflist, type )
    local new_zhanwei = {}
    local ret_zhanwei = {}
    local zhenxing = {}

    assert( deflist and #deflist == 7, "deflist size error")

    --不同的type deflist和new_zhanwei的结构是不一样的
    if type == 1 then
    	for k,v in ipairs(deflist) do
	        if v.status == 1 then
	        	table.insert(ret_zhanwei, -1)
	        	--print("zhenxing4: -1")
	        elseif v.status == 2 then
	        	table.insert(ret_zhanwei, v.knight.guid)
	            --print("zhenxing4: "..v.knight.guid)
	        elseif v.status == 0 then
	        	table.insert(ret_zhanwei, -2)
	            --print("zhenxing4: -2")
	        end
	    end

	    zhenxing = ret_zhanwei
	    --print("")
    else--改阵容
    	zhenxing = deflist
    end
    local has_lead = false
    local tmp = {}
    for k,v in ipairs(zhenxing) do
        if v  == -1 then
            assert(not has_lead)
            has_lead = true
            tmp[k] = {}
            tmp[k].status = 1
            --print("zhenxing1: -1")
        elseif v == -2 then
        	tmp[k] = {}
            tmp[k].status = 0
            --print("zhenxing1: -2")
        else
        	assert(main_data.zhenxing.zhanwei_list)
            local t = core_user.get_knight_by_guid(v, main_data, knight_list)
            assert(t and t[2])
            local jiban = rawget(t[2].data, "jiban_list")

            assert(not t[2].data.master or t[2].data.master == 0, "this knight has master")
            --assert(t[2].data.level >= 30, t[2].guid .. " level < 30")
            tmp[k] = {}
            tmp[k].status = 2
            tmp[k].knight = t[2]
            --print("zhenxing1: "..v)
            core_user.init_knight(t[2])
        end
    end
    --print("")
    new_zhanwei = tmp

    if type ~= 1 then
    	ret_zhanwei = tmp
    end

    nowpower = core_power.get_team_power(main_data, knight_list, new_zhanwei)
    --print( "innner nowpower:", nowpower)

    return nowpower, ret_zhanwei
end

local function get_produce_to_bag( main_data, item_list, gold, jinjiedan, xuantie, type)
	--添加物品
	local rsync = {item_list = {}}
	local jinjiedanid = 191010024
	core_user.get_item(jinjiedanid, jinjiedan, main_data, type, nil, item_list, rsync)
	core_user.add_xuantie(xuantie, {main_data = main_data, item_list = item_list}, rsync, type)
	core_user.add_gold(gold, {main_data = main_data, item_list = item_list}, rsync, type)

   	rsync.cur_gold = main_data.gold
    rsync.cur_money = main_data.money
    rsync.cur_tili = main_data.tili

   	return rsync, main_data, item_list
end

local function check_hongdian( main_data )
	if main_data.lead.level < 40 then return 0 end
	--local mineinfo = get_mineinfo(main_data)
	local mineinfo = rawget(main_data, "mineinfo")
	local flag = 0
	local defflag = 0 
	if not mineinfo then --未初始化数据，直接默认有红点
		flag = 1
	else
		if mineinfo.begintime < 0 then
			flag = 1
		end
		if rawget(mineinfo, "defrcd") then
			for k,v in ipairs(mineinfo.defrcd) do
				if v.jinglireward == 1 and v.win ~= 0 then
					defflag = defflag + 1
				end
			end
		end
		flag = flag + defflag
	end
	
	local found = false
	local t = main_data.ext_data.huodong.hongdian_list
	if rawget(main_data.ext_data.huodong,"hongdian_list") then
		for k,v in ipairs(main_data.ext_data.huodong.hongdian_list) do
			if v.act_id == 10000 then
				found = true
				--print("set|" ..main_data.user_name .." hongdian ".. flag)
				v.flag = flag
				break
			end
		end
	end

	if not found then
		t = {act_id = 10000, flag = flag}
		--print("cre|" ..main_data.user_name .." hongdian ".. flag)
		if not rawget(main_data.ext_data.huodong,"hongdian_list") then 
			main_data.ext_data.huodong.hongdian_list = {} 
		end
		table.insert(main_data.ext_data.huodong.hongdian_list, t)
	end
	
	return defflag
end

--调用前刷新战斗力
local function mine_rsync_data(Mine_Data, mineinfo, user_name, main_data)
	local nowtime = os.time()
	if mineinfo then
		if mineinfo.begintime > 0 then
			local gmineinfo = Mine_Data.mines[user_name]
			local modified = false

			--同步数据
			if gmineinfo then
				if gmineinfo.inithpflag == 1 then
					mineinfo.defdata.hpdata = {}
					LOG_INFO("init enemyhp! "..main_data.user_name)
					mineinfo.maxrcdno = mineinfo.maxrcdno + 1
					gmineinfo.inithpflag = 0
					modified = true
				end

				if gmineinfo.lockendtime > mineinfo.protectendtime then
					mineinfo.protectendtime = gmineinfo.lockendtime
					mineinfo.defdata.robuid = gmineinfo.rober
				end

				if gmineinfo.user.level ~= main_data.lead.level then
					gmineinfo.user.level = main_data.lead.level
					modified = true
				end

				if gmineinfo.nowpower ~= mineinfo.nowpower then
					gmineinfo.nowpower = mineinfo.nowpower
					modified = true
				end
		
				update_produce(mineinfo.begintime, mineinfo.produce, mineinfo.nowpower, user_name)

			else
				local g = {
					user = {
						uid = user_name,
						nick_name = main_data.nickname,
				        sex = main_data.lead.sex,
				        level = main_data.lead.level,
				        star = main_data.lead.star,
				        vip = main_data.vip_lev,
					},
					lockendtime = mineinfo.protectendtime,	--保护结束时间
					produce = {},						
					begintime = mineinfo.begintime,
					rober = nil,
					nowpower = mineinfo.nowpower,
					inithpflag = 0,
				}
		
				update_produce(mineinfo.begintime, mineinfo.produce, mineinfo.nowpower, user_name)

				if rawget(mineinfo, "defdata") and rawget(mineinfo.defdata, "robuid") then
					g.rober = mineinfo.defdata.robuid
				end

				Mine_Data.totalnum = Mine_Data.totalnum + 1
				LOG_INFO("rsync|totalnum:".. Mine_Data.totalnum)
				rawset(Mine_Data.mines, user_name, g)
				gmineinfo = clonetab(g)
				modified = true
			end

			if modified then
				local pb = require "protobuf"
				local t = pb.encode("MineSingleInfo", gmineinfo)

				Mine_Data.db:set(user_name, t)
			end
		end
	end
end

local function mine_research(main_data1, knight_list1, main_data2, enemyid)
	local Mine_Data = gmine_data
	local nowtime = os.time()
	local user_name = main_data1.user_name

	local level = main_data1.lead.level
	assert(level >= 40)

	local mineinfo = get_mineinfo(main_data1)
	local jinglirsync = {
		jingli = mineinfo.jingli,
		jinglitimestamp = mineinfo.jinglitimestamp + 1200,
	}

	mineinfo.searchtimes = mineinfo.searchtimes + 1
	local searchtimes = mineinfo.searchtimes
	if searchtimes > #Baozang_Search_conf then searchtimes = #Baozang_Search_conf end
	local conf = Baozang_Search_conf[searchtimes]
	local expendGold = conf.COST

	core_user.expend_gold(expendGold, {main_data = main_data1}, nil, 801)
	--print("search|", enemyid)
	if enemyid == "zhangyan" then 
		if nowtime < mineinfo.atkdata.robendtime then
			local flag = string.sub(mineinfo.atkdata.robmineid, 1, 6)
			assert( flag == flag_robot)
		end
	end
	if enemyid ~= "zhangyan" and nowtime < mineinfo.atkdata.robendtime then
		assert(mineinfo.atkdata.robmineid == enemyid)
		assert(main_data2)
		assert(enemyid == main_data2.user_name)
		local enemyinfo = rawget(main_data2, "mineinfo")
		assert(enemyinfo)
		enemyinfo = get_mineinfo(main_data2)
		genemydata = Mine_Data.mines[enemyid]
		if genemydata and nowtime < genemydata.lockendtime then
			if genemydata.rober == user_name then
				genemydata.rober = nil
				genemydata.lockendtime = nowtime - 1
				enemyinfo.protectendtime = nowtime - 1 
			end
		end
		
		for k,v in ipairs(enemyinfo.defrcd) do
			if v.robuid == user_name and nowtime - v.lastfighttime < G_PER_HOUR_TIME then
				v.win = 1
				enemyinfo.maxrcdno = enemyinfo.maxrcdno + 1
			end
		end

		enemyinfo.defdata = {}
	end

	local last_atk_list = {}
	for k,v in ipairs(main_data1.zhenxing.zhanwei_list) do
		if v.status == 2 then
			if v.knight.data.level >= 30 then
				table.insert(last_atk_list, v.knight.guid)
			else
				table.insert(last_atk_list, -2)
			end
		elseif v.status == 1 then
			table.insert(last_atk_list, -1)
		elseif v.status == 0 then
			table.insert(last_atk_list, -2)
		end
	end

	local list = get_minelist_by_level(Mine_Data, level, user_name)

	if not list or #list < 1 then
		--返回机器人
		local ridx = math.random(3000)
		local confsize = Bao_Robot_conf.len
		local idx = Bao_Robot_conf.index[confsize]
		local conf = Bao_Robot_conf[idx] --如果下面循环没找到配置就以最后一个作为配置
		for i = 1, confsize do
			local x = Bao_Robot_conf.index[i]
			local t = Bao_Robot_conf[x]
			if level >= t.START_LV and level <= t.END_LV then
				conf = t
				break
			end
		end

		local robproduce = get_produce_from_conf(conf.FIGHT)
		robproduce.gold = math.floor(robproduce.gold*3/5)
		local g = {
			enemy = {
				uid = flag_robot..ridx,
				nick_name = robot_list30[ridx].nick_name,
		        sex = robot_list30[ridx].sex,
		        level = conf.ROBOT_LV,
		        star = 5,
		        vip = 0,
		        robot = ridx,
			},
			lockendtime = nowtime + G_PER_HOUR_TIME,	--保护结束时间
			robproduce = robproduce,
			searchtimes = mineinfo.searchtimes,
			jinglirsync = jinglirsync,
		}
		--print(g.enemy.uid)
		mineinfo.atkdata.robmineid = g.enemy.uid
		mineinfo.atkdata.robendtime = nowtime + G_PER_HOUR_TIME
		mineinfo.atkdata.deadlist = {}
		mineinfo.atkdata.robot = g.enemy
		mineinfo.atkdata.robotdefinfo = {}
		mineinfo.atkdata.robproduce = g.robproduce
		mineinfo.atkdata.robotdefinfo.robuid = user_name
		mineinfo.atkdata.last_atk_list = last_atk_list
		local change_list = check_knight_lock( main_data1, knight_list1)
		return g, main_data1.gold, change_list
	else
		
		local ridx = math.random(#list)
		local enemydata = list[ridx]
		local enemyid2 = enemydata.user.uid
		assert(enemydata)
		
		--刷新产量
		local robproduce = update_produce(enemydata.begintime, enemydata.produce, enemydata.nowpower, enemyid2, 1)
		local g = {
			enemy = enemydata.user,
			lockendtime = nowtime + G_PER_HOUR_TIME,	--保护结束时间
			robproduce = robproduce,
			searchtimes = mineinfo.searchtimes,
			jinglirsync = jinglirsync,
		}

		mineinfo.atkdata = {
			robmineid = enemyid2,
			robendtime = nowtime + G_PER_HOUR_TIME,
			deadlist = {},
			last_atk_list = last_atk_list,
		}

		enemydata.inithpflag = 1

		enemydata.rober = user_name
		enemydata.lockendtime = nowtime + G_PER_HOUR_TIME
		
		Mine_Data.mines[enemyid2] = enemydata
		mineinfo.atkdata.robendtime = nowtime + G_PER_HOUR_TIME
		local pb = require "protobuf"
		local t = pb.encode("MineSingleInfo", enemydata)
	
		Mine_Data.db:set(enemyid2, t)
		local change_list = check_knight_lock( main_data1, knight_list1)
		return g, main_data1.gold, change_list
	end
end

local function get_robot_data(robot_info )
    local d = clonetab(robot_list30[robot_info.robot])
    d.lead.sex = robot_info.sex
    d.lead.star = robot_info.star
    d.lead.level = robot_info.level
    d.lead.skill.id = 110650001
    d.lead.skill.level = robot_info.level
    --d.zhenxing.zhanwei_list[4].status = 0
    --d.zhenxing.zhanwei_list[5].status = 0
    --d.zhenxing.zhanwei_list[6].status = 0
    --d.zhenxing.zhanwei_list[7].status = 0
    d.zhenxing.zhanwei_list[1].knight.data.level = robot_info.level
    d.zhenxing.zhanwei_list[1].knight.data.skill.level = robot_info.level
    d.zhenxing.zhanwei_list[3].knight.data.level = robot_info.level
    d.zhenxing.zhanwei_list[3].knight.data.skill.level = robot_info.level
    d.zhenxing.zhanwei_list[4].knight.data.level = robot_info.level
    d.zhenxing.zhanwei_list[4].knight.data.skill.level = robot_info.level
    d.zhenxing.zhanwei_list[5].knight.data.level = robot_info.level
    d.zhenxing.zhanwei_list[5].knight.data.skill.level = robot_info.level
    d.zhenxing.zhanwei_list[6].knight.data.level = robot_info.level
    d.zhenxing.zhanwei_list[6].knight.data.skill.level = robot_info.level
    d.zhenxing.zhanwei_list[7].knight.data.level = robot_info.level
    d.zhenxing.zhanwei_list[7].knight.data.skill.level = robot_info.level
    return d
end

local function create_main_data(main_data, knight_list, new_zhanwei)
	local has_lead = false
    local tmp = {}
    local t_knight_list = {}
    for k,v in ipairs(new_zhanwei) do
        if v  == -1 then
            assert(not has_lead)
            has_lead = true
            tmp[k] = {}
            tmp[k].status = 1
            --print("zhenxing1: -1")
        elseif v == -2 then
        	tmp[k] = {}
            tmp[k].status = 0
            --print("zhenxing1: -2")
        else
        	assert(main_data.zhenxing.zhanwei_list)
            local t = core_user.get_knight_by_guid(v, main_data, knight_list)
            assert(t and t[2])
            local jiban_list = rawget(t[2].data, "jiban_list")
            if jiban_list then
                for k1,v1 in ipairs(jiban_list) do
                    if v1 >= 0 then
                        local t1 = core_user.get_knight_from_bag_by_guid(v1, knight_list)
                        assert(t1, "knight not find")
                        local tk1 = t1[2]
                        LOG_INFO("addknightbag:".. tk1.id .." ".. tk1.guid)
                        table.insert(t_knight_list, tk1)
                    end
                end
            end
            assert(not t[2].data.master or t[2].data.master == 0, "this knight has master")
            --assert(t[2].data.level >= 30, t[2].guid .. " level < 30")
            tmp[k] = {}
            tmp[k].status = 2
            tmp[k].knight = t[2]
            --print("zhenxing1: "..v)
            core_user.init_knight(t[2])
        end
    end
    
	local d = {
            lead = main_data.lead,
            zhenxing = {zhanwei_list = tmp},
            PVP = {reputation = main_data.PVP.reputation},
            book_list = main_data.book_list,
            lover_list = main_data.lover_list,
            wxjy = main_data.wxjy,
            sevenweapon = main_data.sevenweapon,
        }
    return d
end

local function zhanwei_to_enemylist( zhanwei, user )
	local g = {}
	assert(zhanwei)
	for k,v in ipairs(zhanwei) do
		if v.status == 0 then
			local t = {id = -2, guid = -2,}
			--print("enemylist:"..-2)
			table.insert(g, t)
		elseif v.status == 1 then
			assert(user)
			local t = {id = -1, level = user.level, sex = user.sex, star = user.star, guid = -1,}
			--print("enemylist:"..-1)
			table.insert(g, t)
		elseif v.status == 2 then
			local t = {
				id = v.knight.id,
				level = v.knight.data.level,
				guid = v.knight.guid,
			}
			--print("enemylist:"..v.knight.guid)
			table.insert(g, t)
		end
	end
	return g
end

local function do_fight( resp, main_data1, main_data2, knight_list1, item_list1, knight_list2, deflist, robot )
	local Mine_Data = gmine_data
	local nowtime = os.time()
	--这new数据战斗完就没用了
	local mineinfo = main_data1.mineinfo
	local new_main_data1 = create_main_data(main_data1, knight_list1, mineinfo.atkdata.last_atk_list)
	local new_main_data2 = nil
	local robot_info = rawget(mineinfo.atkdata, "robot")
	local hpdata = {}

	if not robot then
		new_main_data2 = create_main_data(main_data2, knight_list2, deflist)
		if not rawget(main_data2.mineinfo.defdata, "hpdata") then main_data2.mineinfo.defdata.hpdata = {} end
		hpdata = main_data2.mineinfo.defdata.hpdata
	else	
		assert(robot_info)
		new_main_data2 = get_robot_data(robot_info)
		local t = mineinfo.atkdata.robotdefinfo
		if not rawget(mineinfo.atkdata, "robotdefinfo") then mineinfo.atkdata.robotdefinfo = {} end
		t = mineinfo.atkdata.robotdefinfo.hpdata
		if not rawget(mineinfo.atkdata.robotdefinfo, "hpdata") then mineinfo.atkdata.robotdefinfo.hpdata = {} end
		hpdata = mineinfo.atkdata.robotdefinfo.hpdata
	end

    -- 实际战斗并记下rcd
    local fight = core_fight:new()
    local rcd = fight.rcd
    local preview = rcd.preview

    fight:get_player_data(new_main_data1, knight_list1)
    fight:get_player_data(new_main_data2, knight_list2, true)
    fight:get_attrib()

    -- 更新hp
    if rawget(mineinfo.atkdata, "deadlist") then
    	for k,v in ipairs(fight.role_list) do
    		if v.posi < 100 then
    			LOG_INFO("fillfull|self "..v.id)
        		for k1,v1 in pairs (mineinfo.atkdata.deadlist) do
        			if v1 == v.id then
        				LOG_INFO("fill0|self "..v.id)
        				v.hp = 0
        				break
        			end
				end
			end
		end
	end

	for k,v in ipairs(hpdata) do
    	--print("hpdata1:", v.knightid, v.knighthp)
    end
	if hpdata then
		for k,v in ipairs(fight.role_list) do
			if v.posi >= 100 and v.posi < 1000 then
				local found = false
        		for k1,v1 in pairs (hpdata) do
			        if v1.knightid == v.id then
			        	found = true
			        	v.hp = v1.knighthp
			        	LOG_INFO("fillhp|enemy id:"..v.id.." hp:"..v.hp)
			        	if v.hp < 0 then v.hp = 0 end
			        	break
			        end
				end
				if not found then
					LOG_INFO("fillfull|enemy id:"..v.id)
				end
			end
		end
	end

    -- 这里必须先获取原始preview，排序之后顺序就乱了
    fight:get_preview_role_list()
    fight:play(rcd)

    resp.fight_rcd = rcd

    local rcd_idx = Mine_Data.rcd_idx + 1
    local win = fight.winner

	local winner = main_data1.user_name
	if win == 0 then 
		if not robot then 
			winner = main_data2.user_name 
		else 
			winner = mineinfo.atkdata.robmineid end
	end

	local MineRcd = {
		user1 = {
			uid = main_data1.user_name,
			nick_name = main_data1.nickname,
	        sex = main_data1.lead.sex,
	        level = main_data1.lead.level,
	        star = main_data1.lead.star,
	        vip = main_data1.vip_lev,
		},
		winner = winner,
		videoidx = rcd_idx,
		fighttime = nowtime,
	}	
	if robot then
		MineRcd.user2 = clonetab(robot_info)
	else
		MineRcd.user2 = {
			uid = main_data2.user_name,
			nick_name = main_data2.nickname,
	        sex = main_data2.lead.sex,
	        level = main_data2.lead.level,
	        star = main_data2.lead.star,
	        vip = main_data2.vip_lev,
		}
	end

	--产生防守记录
	if not robot then
		local enemyinfo = main_data2.mineinfo
		local rcdno = enemyinfo.maxrcdno
		if not rcdno or rcdno <= 0 then 
			rcdno = 1 
			enemyinfo.maxrcdno = 1 
		end		
		local found = false
		for k,v in ipairs(enemyinfo.defrcd) do
			if v.rcdno == rcdno then
				found = true
				if not rawget(v, "rcd") then v.rcd = {} end
				table.insert(v.rcd, MineRcd)
				v.lastfighttime = nowtime
				v.win = 0-win
			end
		end
		if not found then
			local t = {
				robuid = main_data1.user_name,
				nick_name = main_data1.nickname,
				rcd = {},
				win = 0-win,
				lastfighttime = nowtime,
				jinglireward = 1,
				rcdno = rcdno,
			}

			table.insert(t.rcd, MineRcd)
			table.insert(enemyinfo.defrcd, t)
			--enemyinfo.maxrcdno = enemyinfo.maxrcdno + 1
		end

		enemyinfo.defrcd = remove_rcd_by_size(enemyinfo.defrcd)
	end
	--local tmp = mineinfo.atkdata.last_atk_list
	if win == 1 then 
		local robproduce = {
			gold = 0,
			jinjiedan = 0,
			xuantie = 0,
		}
		
		if not robot then
			local enemyinfo = main_data2.mineinfo
			local enemydata = Mine_Data.mines[main_data2.user_name]
			assert(enemydata)

			enemyinfo.defdata = {}

			assert(#enemyinfo.produce - 1 > 0)
				
			robproduce = update_produce(enemyinfo.begintime, enemyinfo.produce, enemyinfo.nowpower, main_data2.user_name, 1)
			local leftproduce = enemyinfo.produce[#enemyinfo.produce-1]
			robproduce.jinjiedan = leftproduce.jinjiedan
			robproduce.xuantie = leftproduce.xuantie


			resp.rsync = get_produce_to_bag( main_data1, item_list1, robproduce.gold, robproduce.jinjiedan, robproduce.xuantie, 802)
			LOG_INFO("ROBMINE|ROBREWARD|".. main_data1.user_name.. " gold:"..robproduce.gold.. " jinjiedan:".. robproduce.jinjiedan.. " xuantie:"..robproduce.xuantie)
			resp.addgold = robproduce.gold
			leftproduce.gold =  leftproduce.gold - robproduce.gold
			leftproduce.robed = 1

			enemydata.produce = enemyinfo.produce
			enemydata.rober = nil
			
		else


			if rawget(mineinfo.atkdata, "robproduce") then
				robproduce = mineinfo.atkdata.robproduce
			end
			resp.rsync = get_produce_to_bag( main_data1, item_list1, robproduce.gold, robproduce.jinjiedan, robproduce.xuantie, 802)
			LOG_INFO("ROBMINE|ROBREWARD|".. main_data1.user_name.. " gold:"..robproduce.gold.. " jinjiedan:".. robproduce.jinjiedan.. " xuantie:"..robproduce.xuantie)
			resp.addgold = robproduce.gold
			mineinfo.atkdata.robot = nil
			mineinfo.atkdata.robotdefinfo = nil
			mineinfo.atkdata.robproduce = nil
		end

		resp.enemyinfo.lockendtime = -1			

		local t = {}
		if mineinfo.atkdata.last_atk_list then
			t = clonetab(mineinfo.atkdata.last_atk_list)
		end
		mineinfo.atkdata = {}
		mineinfo.atkdata.last_atk_list = t
		resp.win = 1
	else
		resp.win = 0

		if robot then
			resp.enemyinfo.robproduce = mineinfo.atkdata.robproduce
			local robotdata = get_robot_data(mineinfo.atkdata.robot)

		    resp.fightdata.enemydeflist = zhanwei_to_enemylist( robotdata.zhenxing.zhanwei_list, mineinfo.atkdata.robot)
		    

		else
			local enemydata = Mine_Data.mines[main_data2.user_name]
			local enemyinfo = main_data2.mineinfo
			assert(enemydata and enemyinfo)

		    resp.fightdata.enemydeflist = zhanwei_to_enemylist(enemyinfo.def_knight_list, enemydata.user)

			--刷新产量
			resp.enemyinfo.robproduce = update_produce(enemyinfo.begintime, enemyinfo.produce, enemyinfo.nowpower, main_data2.user_name, 1)
			
		end	

		resp.enemyinfo.lockendtime = mineinfo.atkdata.robendtime

		--记录enemy血量
        for k,v in ipairs(fight.role_list) do
	        local f = {knightid = -1, knighthp = -1}
	        local posi = v.posi
	        if posi < 1000 and posi >= 100 then
	        	f.knightid = v.id
	        	if v.hp < 0 then 
	        		f.knighthp = 0 
	        	else
	            	f.knighthp = v.hp
	            end
	            LOG_INFO("enemyhp|new|posi:" ..posi.. " id:"..v.id.. " hp:" .. v.hp)
	        
		        local found = false
		        if hpdata then
			        for k1,v1 in ipairs(hpdata) do
			        	if v1.knightid == f.knightid then
			        		found = true
			        		LOG_INFO("enemyhp|old|".. posi .." ".. k1 .. " id:".. v1.knightid .. " hp:" .. v1.knighthp)
			        		hpdata[k1] = f
			        		break
			        	end
			        end
			    end
		
		        if not found then
		        	LOG_INFO("enemyhp|cre|".. posi.. " id:"..v.id.. " hp:".. v.hp)
		        	table.insert(hpdata, f)
		        end
	        end
	    end  
	    if not robot then
	    	main_data2.mineinfo.defdata.hpdata = hpdata
	    else
	    	mineinfo.atkdata.robotdefinfo.hpdata = hpdata
	    end

	    for k,v in ipairs(hpdata) do
	    	LOG_INFO("hpdata2:".. v.knightid.." ".. v.knighthp)
	    end

	    --记录自己的死亡列表
	    local t = {}
	    if not rawget(mineinfo.atkdata, "deadlist") then mineinfo.atkdata.deadlist = {} end
	   	for k,v in ipairs(mineinfo.atkdata.last_atk_list) do
	   		if v ~= -2 then
	   			local found = false
		   		for k1,v1 in ipairs(mineinfo.atkdata.deadlist) do  			
		   			if v1 == v then
		   				found = true
		   				break
		   			end
		   		end
		   		if not found then
		   			table.insert(t, v)
		   		end
		   	end
	   	end
   	
	   	for k,v in ipairs(t) do
	   		LOG_INFO("selfdead|add ".. " id:"..v)
	   		table.insert(mineinfo.atkdata.deadlist, v)
	   	end

	   	t = {}
		for k,v in ipairs (hpdata) do
			if v.knighthp == 0 then 
				LOG_INFO("enemydead|id:"..v.knightid)
				table.insert(t, v.knightid)
			end
		end
		resp.fightdata.enemydeadlist = t

	   	resp.fightdata.last_atk_list = mineinfo.atkdata.last_atk_list
		resp.fightdata.selfdeadlist = mineinfo.atkdata.deadlist	
		resp.rsync = nil
	end	
	LOG_INFO("endfight:".. win)
	local tmp = mineinfo.atkdata.last_atk_list

	if not robot then
		--记录索引
	    local rcd_t = rawget(Mine_Data, "rcd")
	    rcd_t[rcd_idx] = {idx = rcd_idx, timestamp = nowtime}

		--写回录像
		local pb = require "protobuf"
		local k = {
			fight_rcd = rcd,
			timestamp = nowtime,
		}
	    local t = pb.encode("MineFightRcd", k)
	    local ret = Mine_Data.db:set(flag_rcd..rcd_idx, t)

	    Mine_Data.rcd_idx = rcd_idx

	    Mine_Data.db:set(flag_rcdidx, rcd_idx)
	end

    return resp, main_data1, main_data2, item_list1
end

local function do_robfight(main_data1, knight_list1, item_list1, main_data2, knight_list2, user_name, req, robot_idx)
	local Mine_Data = gmine_data
	local nowtime = os.time()
	local level = main_data1.lead.level
	assert(level >= 40)
	local mineinfo = get_mineinfo(main_data1)
	
	local resp = {
		result = "OK",
		win = 0,
		fight_rcd = {},
		rsync = {},
		enemyinfo = {},
		fightdata = {},
		jinglirsync = {},
	}
	
	assert(mineinfo.jingli >= 4)
	mineinfo.jingli = mineinfo.jingli - 4
	local jinglirsync = {
		jingli = mineinfo.jingli,
		jinglitimestamp = mineinfo.jinglitimestamp + 1200,
	}

	resp.jinglirsync = jinglirsync

	assert(main_data2 or robot_idx)
	local enemylist = req.enemylist.fightlist
	local fightlist = req.zhenxing
	assert(enemylist and fightlist and #enemylist == 7 and #fightlist == 7)

	for k,v in ipairs (fightlist) do
		if v >= -1 then
			if v >= 0 then
				local t = core_user.get_knight_by_guid(v, main_data1, knight_list1)
	            assert(t and t[2], v.."not in bag")
	            local jiban = rawget(t[2].data, "jiban_list")
	            assert(not t[2].data.master or t[2].data.master == 0, t[2].guid.." this knight has master")
	            assert(t[2].data.level >= 30, "level < 30")
	        end

			if rawget(mineinfo.atkdata, "deadlist") then
				for k1,v1 in ipairs (mineinfo.atkdata.deadlist) do
					assert(v1 ~= v, v.." is dead!")
				end
			end
		end
	end 
	local lal = clonetab(mineinfo.atkdata.last_atk_list)
	mineinfo.atkdata.last_atk_list = fightlist
	local change_list = check_knight_lock( main_data1, knight_list1, lal)
	resp.enemyinfo.searchtimes = mineinfo.searchtimes

	if nowtime > mineinfo.atkdata.robendtime then
		LOG_INFO("resp OUTTIME")
		resp.result = "OUTTIME"
		resp.enemyinfo.lockendtime = -1
		mineinfo.jingli = mineinfo.jingli + 4
		resp.jinglirsync.jingli = mineinfo.jingli
		resp.enemyinfo.rsyncjingli = resp.rsyncjingli
		resp.win = nil
		resp.fight_rcd = nil
		resp.rsync = nil
		resp.fightdata = nil
		resp.result2 = 2
		return resp
	end

	if main_data2 then
		assert(rawget(main_data2, "mineinfo"))
		local enemyid = main_data2.user_name
		local enemyinfo = get_mineinfo(main_data2)
		
		--更新enemy数据
		assert( enemyinfo.begintime > 0)

		local deflist = {}
		--刷新计算战斗力
		enemyinfo.nowpower, deflist = update_def_power(main_data2, knight_list2, enemyinfo.def_knight_list, 1)

		--刷新产量
		local robproduce = update_produce(enemyinfo.begintime, enemyinfo.produce, enemyinfo.nowpower, enemyid, 1)
		local enemydata = Mine_Data.mines[enemyid]

		--同步数据
		mine_rsync_data(Mine_Data, enemyinfo, enemyid, main_data2)

		assert(mineinfo.atkdata.robmineid == enemyid)
		assert(enemyid == main_data2.user_name)

		enemydata = Mine_Data.mines[enemyid]
		assert(enemydata)

		local modified = false
		for k,v in ipairs (enemylist) do
			if v ~= deflist[k] then 
				modified = true
				break 
			end
		end	

		if modified then 
			LOG_INFO("resp MODIFIED")
			resp.result = "MODIFIED"
			resp.result2 = 1
			resp.enemyinfo = {
				enemy = enemydata.user,
				lockendtime = nowtime + G_PER_HOUR_TIME,	--保护结束时间
				robproduce = robproduce,
				searchtimes = mineinfo.searchtimes,			
			}
			resp.fightdata = {
				last_atk_list = fightlist,
				selfdeadlist = mineinfo.atkdata.deadlist,
				nowpower = enemyinfo.nowpower,
			}
			resp.fightdata.enemydeflist = zhanwei_to_enemylist(enemyinfo.def_knight_list, enemydata.user )
			for k,v in ipairs(resp.fightdata.enemydeflist) do
				--print ("resp robdef|".. v.guid)
			end
			local t = {}
			for k,v in ipairs (enemyinfo.defdata.hpdata) do
				if v.knighthp == 0 then 
					table.insert(t, v.knightid)
				end
			end
			resp.fightdata.enemydeadlist = t

			mineinfo.jingli = mineinfo.jingli + 4
			resp.jinglirsync.jingli = mineinfo.jingli
			resp.enemyinfo.rsyncjingli = resp.rsyncjingli
			resp.win = nil
			resp.fight_rcd = nil
			resp.rsync = nil
			return resp
		end

		resp.fightdata.nowpower = enemyinfo.nowpower
		resp.enemyinfo.enemy = enemydata.user
		resp.enemyinfo.rsyncjingli = resp.rsyncjingli
		LOG_INFO("beginfight|".. enemyid)
		resp, main_data1, main_data2, item_list1 = do_fight(resp, main_data1, main_data2, knight_list1, item_list1, knight_list2, deflist)		
		check_hongdian( main_data2, enemyinfo)

	elseif robot_idx then
		assert(rawget(mineinfo.atkdata, "robot") and mineinfo.atkdata.robot.robot == robot_idx)
		local t = rawget(mineinfo.atkdata, "robot")
		resp.enemyinfo.enemy = clonetab(t)
		resp.enemyinfo.rsyncjingli = resp.rsyncjingli
		LOG_INFO("beginfight|".. t.uid)
		local confsize = Bao_Robot_conf.len
		local idx = Bao_Robot_conf.index[confsize]
		local conf = Bao_Robot_conf[idx] --如果下面循环没找到配置就以最后一个作为配置
		for i = 1, confsize do
			local x = Bao_Robot_conf.index[i]
			local t = Bao_Robot_conf[x]
			if mineinfo.atkdata.robot.level >= t.START_LV and mineinfo.atkdata.robot.level <= t.END_LV then
				conf = t
				break
			end
		end
		resp.fightdata.nowpower = conf.FIGHT

		resp, main_data1, main_data2, item_list1 = do_fight(resp, main_data1, nil, knight_list1, item_list1, nil, nil, robot_idx)
	end

	return resp
end

local function get_jingli(main_data, req)
	local nowtime = os.time()
	local level = main_data.lead.level
	assert(level >= 40)
	local mineinfo = get_mineinfo(main_data)
	local rcd = mineinfo.defrcd
	assert (rcd)
	local doAll = false
	local rcdno = req.rcdno
	local getmaxjingli = 20 - mineinfo.getjingli
	
	if mineinfo.jingli >= G_MAX_JINGLI or getmaxjingli <= 0 then 
		local ret = 0
		if getmaxjingli <= 0 then ret = 2 end
		if mineinfo.jingli >= G_MAX_JINGLI then ret = 1 end
		local t = remove_no_result_defrcd(mineinfo.defrcd)
		return ret, {jingli = mineinfo.jingli, jinglitimestamp = mineinfo.jinglitimestamp+1200}, t, 0, 0
	end

	local rsyncjingli = 0
	if rcdno < 0 then
		doAll = true
	end 
	local ret = 0

	if doAll then --一键
		if false then
			rsyncjingli = 1
		else
			for k,v in ipairs(rcd) do
				if v.jinglireward == 1 and mineinfo.jingli + rsyncjingli < G_MAX_JINGLI and rsyncjingli < getmaxjingli then
					rsyncjingli = rsyncjingli + 1
					v.jinglireward = 0

					if mineinfo.jingli + rsyncjingli >= G_MAX_JINGLI or rsyncjingli >= getmaxjingli then
						if mineinfo.jingli + rsyncjingli >= G_MAX_JINGLI then ret = 1 end
						if rsyncjingli >= getmaxjingli then ret = 2 end
						break
					end
				end
			end
		end
	else
		local found = false
		for k,v in ipairs(rcd) do
			if v.rcdno == rcdno then
				found = true
				assert(v.jinglireward == 1)
				rsyncjingli = rsyncjingli + 1
				v.jinglireward = 0
				break
			end
		end
		assert(found)
	end

	assert(mineinfo.jingli + rsyncjingli <= G_MAX_JINGLI and getmaxjingli >= rsyncjingli, "err:"..rsyncjingli.." "..mineinfo.getjingli)

	local jinglirsync = {
		jingli = mineinfo.jingli + rsyncjingli,
		jinglitimestamp = mineinfo.jinglitimestamp + 1200,
	}
	mineinfo.jingli = mineinfo.jingli + rsyncjingli
	mineinfo.getjingli = mineinfo.getjingli + rsyncjingli
	
	defflag = check_hongdian( main_data, mineinfo )

	local t = remove_no_result_defrcd(mineinfo.defrcd)

	return ret, jinglirsync, t, rsyncjingli,defflag
end

local function get_reward(main_data, item_list)
	local nowtime = os.time()
	local level = main_data.lead.level
	assert(level >= 40)
	assert(rawget(main_data, "mineinfo"))
	local mineinfo = get_mineinfo(main_data)
	assert(mineinfo.begintime == -2)
	local nowproduce, nextproduce = update_produce(mineinfo.begintime, mineinfo.produce, mineinfo.nowpower, main_data.user_name)
	assert(nowproduce)

	local jinglirsync = {
		jingli = mineinfo.jingli,
		jinglitimestamp = mineinfo.jinglitimestamp + 1200,
	}

	local buff = 100
	if main_data.vip_lev > 0 then buff = VIP_conf[main_data.vip_lev].BaoZang end
	nowproduce.gold = math.ceil(nowproduce.gold*buff/100)

	--添加物品
	local rsync = get_produce_to_bag( main_data, item_list, nowproduce.gold, nowproduce.jinjiedan, nowproduce.xuantie, 801)
	
	mineinfo.begintime = -1
	mineinfo.protectendtime = 0
	mineinfo.defdata = {}
	--mineinfo.def_knight_list = {}
	mineinfo.produce = {}
	mineinfo.nowpower = 0

	local deflist = {}
	for k,v in ipairs(mineinfo.def_knight_list) do
        if v.status == 1 then
        	table.insert(deflist, -1)
        	--print("zhenxing4: -1")
        elseif v.status == 2 then
        	table.insert(deflist, v.knight.guid)
            --print("zhenxing4: "..v.knight.guid)
        elseif v.status == 0 then
        	table.insert(deflist, -2)
            --print("zhenxing4: -2")
        end
    end
    local t = remove_no_result_defrcd(mineinfo.defrcd)
	respmine = {
		def_knight_list = deflist,
		begintime = -1,
		defrcd = t,
		endtime = -1,	
		jinglirsync = jinglirsync,		
	}
	
    LOG_INFO("ROBMINE|REWARD|".. main_data.user_name.. " gold:"..nowproduce.gold.. " jinjiedan:".. nowproduce.jinjiedan.. " xuantie:"..nowproduce.xuantie)
	return rsync, respmine , nowproduce.gold

end

local function set_fightlist(main_data, knight_list, req, user_name)
	local nowtime = os.time()
	local Mine_Data = gmine_data
	local deflist = req.deflist
	local resp = {
            result = "OK",
            mineinfo = {},
            change_list = {}
        }
    local level = main_data.lead.level
	assert(level >= 40)
    local mineinfo = get_mineinfo(main_data)

	local jinglirsync = {
		jingli = mineinfo.jingli,
		jinglitimestamp = mineinfo.jinglitimestamp + 1200,
	}

	--检查战将
	assert(deflist and #deflist == 7)
	local foundmain = false
	for k,v in ipairs(deflist) do
		if v == -1 then
			foundmain = true
		end
	end
	assert(foundmain, "main must in deflist")
	
	local lal = {}
	for k,v in ipairs(mineinfo.def_knight_list) do
        if v.status == 1 then
        	table.insert(lal, -1)
        elseif v.status == 2 then
        	table.insert(lal, v.knight.guid)
        elseif v.status == 0 then
        	table.insert(lal, -2)
        end
    end

	if mineinfo.begintime == -1 then
		--不管存不存在，都直接覆盖Mine_Data上的数据，以本地为准
		--刷新计算战斗力
		mineinfo.nowpower, mineinfo.def_knight_list = update_def_power(main_data, knight_list, deflist, 2)
		local nowpower = mineinfo.nowpower

		local g = {
			user = {
				uid = user_name,
				nick_name = main_data.nickname,
		        sex = main_data.lead.sex,
		        level = main_data.lead.level,
		        star = main_data.lead.star,
		        vip = main_data.vip_lev,
			},
			lockendtime = nowtime + G_PER_HOUR_TIME,--保护结束时间
			produce = {},							--每小时产量	
			begintime = nowtime,
			rober = nil,
			nowpower = nowpower,
			inithpflag = 0,
		}
		local p = get_produce_from_conf(nowpower)
		p.hour = 1

		LOG_INFO("ROBMINE|FIRSTHOUR|uid:"..user_name .." power:"..p.power .. " gold:" .. p.gold)
		table.insert(g.produce, p)

		if not Mine_Data.mines[user_name] then
			Mine_Data.totalnum = Mine_Data.totalnum + 1
			--print("add|totalnum:", Mine_Data.totalnum)
		end

		rawset(Mine_Data.mines, user_name, g)

		local pb = require "protobuf"
		local t = pb.encode("MineSingleInfo", g)

		Mine_Data.db:set(user_name, t)	

    	mineinfo.begintime = nowtime   	

		--刷新产量
		local nowproduce, nextproduce = update_produce(mineinfo.begintime, mineinfo.produce, mineinfo.nowpower, user_name)
	    t = remove_no_result_defrcd(mineinfo.defrcd)
		resp.mineinfo = {
			def_knight_list = deflist,
			begintime = mineinfo.begintime,
			defrcd = t,
			nowproduce = nowproduce,
			nextproduce = nextproduce,
			endtime = mineinfo.begintime + G_MAX_PRODUCE_TIME,
			jinglirsync = jinglirsync,
		}
    elseif mineinfo.begintime > 0 then
    	--刷新计算战斗力
		mineinfo.nowpower, mineinfo.def_knight_list = update_def_power(main_data, knight_list, deflist, 2)
		local nowpower = mineinfo.nowpower	
		
		mine_rsync_data(Mine_Data, mineinfo, user_name, main_data)
		
		--刷新产量
		local nowproduce, nextproduce = update_produce(mineinfo.begintime, mineinfo.produce, mineinfo.nowpower, user_name)
		local t = remove_no_result_defrcd(mineinfo.defrcd)
		resp.mineinfo = {
			def_knight_list = deflist,
			begintime = mineinfo.begintime,
			defrcd = t,
			nowproduce = nowproduce,
			nextproduce = nextproduce,
			endtime = mineinfo.begintime + G_MAX_PRODUCE_TIME,
			jinglirsync = jinglirsync,
		}
		
		local hours = math.floor((nowtime - mineinfo.begintime)/G_PER_HOUR_TIME) + 1
		resp.mineinfo.nextstatus = hours * G_PER_HOUR_TIME + resp.mineinfo.begintime

	elseif mineinfo.begintime == -2 then
		resp.result = "FINISH"

		--刷新计算战斗力
		mineinfo.nowpower, deflist = update_def_power(main_data, knight_list, mineinfo.def_knight_list, 1)

		--刷新产量
		local nowproduce, nextproduce = update_produce(mineinfo.begintime, mineinfo.produce, mineinfo.nowpower, user_name)
		local t = remove_no_result_defrcd(mineinfo.defrcd)
		resp.mineinfo = {
			def_knight_list = deflist,
			begintime = -2,
			defrcd = t,
			nowproduce = nowproduce,
			nextproduce = nextproduce,
			endtime = 0,
			jinglirsync = jinglirsync,
		}
	end
	assert(mineinfo.def_knight_list and #mineinfo.def_knight_list == 7)
	
	local change_list = check_knight_lock( main_data, knight_list, lal)
    resp.change_list = change_list
    check_hongdian( main_data, mineinfo )
	return resp
end

local function get_enemylist(main_data1, main_data2, knight_list2, robot)
	local Mine_Data = gmine_data
	assert(main_data2 or robot)
	local level = main_data1.lead.level
	assert(level >= 40)
	local nowtime = os.time()
	assert(rawget(main_data1, "mineinfo"))
	local mineinfo = get_mineinfo(main_data1)
	local modified = 0
	--assert(nowtime < mineinfo.atkdata.robendtime, "out of rob time" )
	local resp  = {
			result = "OK",
			fightdata = {
				last_atk_list = mineinfo.atkdata.last_atk_list,
				selfdeadlist = mineinfo.atkdata.deadlist,
			},
		}

	if robot then
		assert(rawget(mineinfo.atkdata, "robot") and mineinfo.atkdata.robot.robot == robot)
		local robotdata = get_robot_data(mineinfo.atkdata.robot)
		
	    resp.fightdata.enemydeflist = zhanwei_to_enemylist(robotdata.zhenxing.zhanwei_list, mineinfo.atkdata.robot )

	    local t = {}
	    if rawget(mineinfo.atkdata.robotdefinfo, "hpdata") then
		    for k,v in ipairs (mineinfo.atkdata.robotdefinfo.hpdata) do
				if v.knighthp == 0 then 
					table.insert(t, v.knightid)
				end
			end
		end
		resp.fightdata.enemydeadlist = clonetab(t)

		local confsize = Bao_Robot_conf.len
		local idx = Bao_Robot_conf.index[confsize]
		local conf = Bao_Robot_conf[idx] --如果下面循环没找到配置就以最后一个作为配置
		for i = 1, confsize do
			local x = Bao_Robot_conf.index[i]
			local t = Bao_Robot_conf[x]
			if level >= t.START_LV and level <= t.END_LV then
				conf = t
				break
			end
		end
		resp.fightdata.nowpower = conf.FIGHT
		
	elseif main_data2 then
		
		local enemyid = main_data2.user_name
		--print("getenemy|id: ", enemyid)
		assert(rawget(main_data2, "mineinfo"))
		local enemyinfo = get_mineinfo(main_data2)
		
		--更新enemy数据
		assert( enemyinfo.begintime > 0)

		local deflist = {}
		--刷新计算战斗力
		enemyinfo.nowpower, deflist = update_def_power(main_data2, knight_list2, enemyinfo.def_knight_list, 1)
		local change_list = check_knight_lock( main_data2, knight_list2)

		--刷新产量
		local robproduce = update_produce(enemyinfo.begintime, enemyinfo.produce, enemyinfo.nowpower, enemyid, 1)

		--同步数据
		mine_rsync_data(Mine_Data, enemyinfo, enemyid, main_data2)

		assert(mineinfo.atkdata.robmineid == enemyid)
		assert(enemyid == main_data2.user_name)
		assert(Mine_Data.mines[enemyid])
		resp.fightdata.enemydeflist = zhanwei_to_enemylist(enemyinfo.def_knight_list, Mine_Data.mines[enemyid].user )
	
		resp.fightdata.enemydeadlist = t
		resp.fightdata.nowpower = enemyinfo.nowpower
	end
	
	return resp
end

local function get_mine_info(main_data, knight_list, flag, user_name)
	local Mine_Data = gmine_data
	local nowtime = os.time()
	local ret = 0
	local status = 0
	local resp = {
            result = "OK",
            mineinfo = {},
            enemyinfo = {},
            change_list = {},
        }

    local level = main_data.lead.level
	assert(level >= 40)

    local mineinfo = get_mineinfo(main_data)
	
	local jinglirsync = {
		jingli = mineinfo.jingli,
		jinglitimestamp = mineinfo.jinglitimestamp + 1200,
	}

	for k,v in ipairs(mineinfo.defrcd) do
		--print("defrcd|", v.jinglireward, v.win, v.robuid)
	end

	--检查战将
	local foundmain = false
	for k,v in ipairs(mineinfo.def_knight_list) do
		if v.status == 1 then
			foundmain = true
		end
	end

	local t = {}
	if not foundmain then
		mineinfo.def_knight_list[1].status = 1
		table.insert(t, mineinfo.def_knight_list[1].knight.guid)
	end

	local change_list = check_knight_lock( main_data, knight_list, t)
	resp.change_list = change_list

	local deflist = {}
	--刷新计算战斗力
	mineinfo.nowpower, deflist = update_def_power(main_data, knight_list, mineinfo.def_knight_list, 1)
	
	--同步数据
	mine_rsync_data(Mine_Data, mineinfo, user_name, main_data)

	--刷新产量
	local nowproduce, nextproduce = update_produce(mineinfo.begintime, mineinfo.produce, mineinfo.nowpower, user_name)
	if flag == 0 then	
		local t = remove_no_result_defrcd(mineinfo.defrcd)
		resp.mineinfo = {
			def_knight_list = deflist,
			begintime = mineinfo.begintime,
			defrcd = t,
			nowproduce = nowproduce,
			nextproduce = nextproduce,
			endtime = mineinfo.begintime + G_MAX_PRODUCE_TIME,
			jinglirsync = jinglirsync,	
		}

		if mineinfo.begintime == -2 then
			resp.mineinfo.endtime = 0
		elseif mineinfo.begintime == -1 then
			resp.mineinfo.endtime = -1
		else
			local hours = math.floor((nowtime - mineinfo.begintime)/G_PER_HOUR_TIME) + 1
			resp.mineinfo.nextstatus = hours * G_PER_HOUR_TIME + resp.mineinfo.begintime
		end
		resp.enemyinfo = nil

		resp.defhongdian = check_hongdian( main_data, mineinfo )
		return resp
	elseif flag == 1 then
		if mineinfo.atkdata.robendtime and nowtime >= mineinfo.atkdata.robendtime then
			local last_atk_list = mineinfo.atkdata.last_atk_list
			mineinfo.atkdata = {}
			mineinfo.atkdata.last_atk_list = last_atk_list
			mineinfo.atkdata.robendtime = 0

			resp.enemyinfo = {
				lockendtime = -1,
				searchtimes = mineinfo.searchtimes,
				jinglirsync = jinglirsync,	
			}
		else
			local enemyid = rawget(mineinfo.atkdata, "robmineid")
			local enemyinfo = Mine_Data.mines[enemyid]
			

			if enemyid and string.sub(enemyid, 1, 6) == flag_robot then
					resp.enemyinfo = {
						enemy = mineinfo.atkdata.robot,
						lockendtime = mineinfo.atkdata.robendtime,
						robproduce = mineinfo.atkdata.robproduce,
						searchtimes = mineinfo.searchtimes,
						jinglirsync = jinglirsync,	
					}
			elseif enemyinfo and enemyid and enemyid ~= "" then

				local t = rawget(enemyinfo, "produce")
				local robproduce = update_produce(enemyinfo.begintime, t, enemyinfo.nowpower, enemyid, 1)
				resp.enemyinfo = {
					enemy = enemyinfo.user,
					lockendtime = enemyinfo.lockendtime,
					robproduce = robproduce,
					searchtimes = mineinfo.searchtimes,
					jinglirsync = jinglirsync,	
				}
			else
				resp.enemyinfo = {
					lockendtime = -1,
					searchtimes = mineinfo.searchtimes,
					jinglirsync = jinglirsync,	
				}
			end

		end

		resp.mineinfo = nil

		resp.defhongdian = check_hongdian( main_data, mineinfo )
		return resp
	elseif flag == 2 then
		resp.mineinfo = {
			jinglirsync = jinglirsync,
			begintime = mineinfo.begintime,
			endtime = mineinfo.begintime + G_MAX_PRODUCE_TIME,			
		}

		if mineinfo.begintime == -2 then
			resp.mineinfo.endtime = 0
		elseif mineinfo.begintime == -1 then
			resp.mineinfo.endtime = -1
		else
			local hours = math.floor((nowtime - mineinfo.begintime)/G_PER_HOUR_TIME) + 1
			resp.mineinfo.nextstatus = hours * G_PER_HOUR_TIME + resp.mineinfo.begintime
		end

		resp.enemyinfo = nil
		resp.defhongdian = check_hongdian( main_data, mineinfo )
		return resp
	end
end

local function remove_mine_by_uid( Mine_Data, uid )
	local success = false
	if Mine_Data.mines then
		for k,v in pairs(Mine_Data.mines) do
			if uid == k then			
				success = Mine_Data.db:remove(k)
				Mine_Data.mines[k] = nil
				Mine_Data.totalnum = Mine_Data.totalnum - 1
			end
		end
	end

	return success
end

local function check_time()
	local Mine_Data = gmine_data
	local nowtime = os.time()
	local removelist = {}

	if Mine_Data.mines then

		for k,v in pairs(Mine_Data.mines) do

			--LOG_INFO("list:".. k.. " nowtime:".. (nowtime - v.begintime) .. " lockend:".. (v.lockendtime - nowtime))
			if nowtime > v.begintime + G_MAX_PRODUCE_TIME or v.begintime <=0 then
				table.insert(removelist, k)
			end
		end
	end

	for k,v in ipairs(removelist) do	
		local ret = remove_mine_by_uid(Mine_Data, v)
		if ret then
			LOG_INFO("remove|"..v.." success!")
		else
			LOG_INFO("remove|"..v.." false!")
		end
	end

	local t = {}
	for k,v in pairs(Mine_Data.rcd) do		
		if v.timestamp + G_RCD_REMOVE_TIME + G_PER_HOUR_TIME < nowtime then
			table.insert(t, k)
		end
	end

	for k,v in ipairs(t) do
		remove_db_rcd(Mine_Data, v)
	end
end

--获取战斗rcd
local function get_rcd(req)
    --print("videoidx",req.videoidx)
    local rcd_idx = req.videoidx
    local rcd_list = gmine_data.rcd
    local rcd = rcd_list[rcd_idx]
    assert(rcd and rcd.idx and rcd.idx ~= 0)

    local rcd_buf = gmine_data.db:get(flag_rcd..rcd.idx)
    local pb = require "protobuf"
    rcd = pb.decode("MineFightRcd", rcd_buf)
    return rcd.fight_rcd
end

local robmine = {
    get_mine_info = get_mine_info,
    get_rcd = get_rcd,
    check_time = check_time,
    mine_research = mine_research,
    do_robfight = do_robfight,
    get_jingli = get_jingli,
    set_fightlist = set_fightlist,
    get_reward = get_reward,
    get_enemylist = get_enemylist,
    check_hongdian = check_hongdian,
    check_knight_lock = check_knight_lock,
}

return robmine