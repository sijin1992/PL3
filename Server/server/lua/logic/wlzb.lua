--武林争霸
local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert
local core_fight = require "fight"
local kc = require "kyotocabinet"
local core_user = require "core_user_funcs"

local rcd_idx = 0--供快速索引rcd的编号
local rcd_temp = {}

local function get_dayid_from(time, hour, minute)
    local t = time + 28800
    local d = math.floor(t / 86400)
    local h = math.floor((t % 86400) / 3600)
    local m = nil
    if minute then
        m = math.floor((t % 3600) / 60)
    end
    --print("****************now time:", d, h, math.floor((t % 3600) / 60))
    
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

local function get_h_m_from(time)
    local t = time + 28800
    local h = math.floor((t % 86400) / 3600)
    local m = math.floor((t % 3600) / 60)
    return h, m
end

local NIL = 0
local REG = 1
local REG_END = 2
local SELECT = 3
local FIGHTING = 4
local FINISH = 5

local DB_S_NIL = 0      -- db文件不存在
local DB_S_ERR = 1      -- db文件错误
local DB_S_REGOK = 2    -- 报名阶段db文件正常
local DB_S_CLOSE = 3    -- db文件已关闭，等待计算
local DB_S_PKOK = 4     -- 战斗阶段，文件正常。此时db只读
local DB_S_RETRY = 5    -- 文件存在但是有问题，稍后重试

local flag_pk = "pk_"
local flag_rcd = "rcd"
local flag_status = "sta"
local flag_robot = "rob"

local t = os.time()
local t0 = get_dayid_from(t)
local t8 = get_dayid_from(t, 7)

local day_list = { -- 1 = 当天战斗记录，2 = 第二天报名列表
            {
                dayid = t0-1,
                status = NIL,
                player = {["len"] = 0},
                robot = {["len"] = 0},
                pk = {},
                rcd = {},
                db = kc.DB:new(),
                file = 'wlzb' .. t0-1 .. '.kch',
                db_status = DB_S_NIL
            },
            {
                dayid = t0,
                status = NIL,
                player = {["len"] = 0},
                robot = {["len"] = 0},
                pk = {},
                rcd = {},
                db = kc.DB:new(),
                file = 'wlzb' .. t0 .. '.kch',
                db_status = DB_S_NIL
            }
        }
--[[
    player{} 玩家数组，里面是玩家的{data= data1+data2， pk = {100001,200526...}}
    robot{} 机器人信息，里面是机器人的data1
    pk[][]  第一位是轮数，第二位是本轮的id
    rcd{} 
                    -- rcd:录像列表索引  pk:匹配列表 player:玩家列表 status:当前状态
]]

local function load_one_db(dayid, day_data, type)
    day_data.dayid = dayid
    day_data.file = 'wlzb' .. dayid .. '.kch'
    if day_data.db_status == DB_S_REGOK or day_data.db_status == DB_S_PKOK then
        day_data.db:close()
    end
    if not day_data.db:open(day_data.file, type) then
        LOG_ERROR(day_data.file.." open err")
        day_data.db_status = DB_S_ERR
    else
        local t = tonumber(day_data.db:get(flag_status))
        if type == kc.DB.OREADER and t ~= FINISH then   -- 只读的kch，读到的状态只能是FINISH
            day_data.db_status = DB_S_RETRY
            day_data.db:close()
        else
            day_data.db:iterate(
                function(k1,v1)
                    local flag = string.sub(k1, 1, 3)
                    if flag == flag_status then
                        day_data.status = tonumber(v1)
                    elseif flag == flag_rcd then
                        local rcd_idx = tonumber(string.sub(k1, 4))
                        --print("rcd", rcd_idx)
                        local pb = require "protobuf"
                        local d = pb.decode("FightRcd", v1)
                        day_data.rcd[rcd_idx] = rcd_idx
                    elseif flag == flag_pk then
                        local pk_idx = tonumber(string.sub(k1, 4))
                        --print("pk_idx", pk_idx)
                        local idx_1 = math.floor(pk_idx / 100000)
                        local idx_2 = pk_idx % 100000
                        local pb = require "protobuf"
                        local d = pb.decode("wlzb_pk_info", v1)
                        if day_data.pk[idx_1] then
                            day_data.pk[idx_1][idx_2] = d
                        else
                            day_data.pk[idx_1] = {}
                            day_data.pk[idx_1][idx_2] = d
                        end
                    elseif flag == flag_robot then
                        --print("robot", k1)
                        local pb = require "protobuf"
                        local d = pb.decode("wlzb_player_info", v1)
                        rawset(day_data.robot, k1, d)
                    else
                        --print("player", k1)
                        local pb = require "protobuf"
                        local d = pb.decode("wlzb_player_kch", v1)
                        rawset(day_data.player, k1, d)
                        day_data.player.len = day_data.player.len + 1
                    end
                end, false
            )
            day_data.db_status = DB_S_PKOK
        end
    end
    
end


--加载数据
--[[
    4中可能：
    1，启动，0-8点，不读1（等待计算），读/建2
    2，启动，8点之后，读1，读/建2
    3，正常跨天，0-8点，关1，清1，关2，建3
    4，正常运行到8点，开1
]]
local function load_db(dayid, type)
    if type == 1 then
        --load_one_db(dayid, dayid-1, type)
        load_one_db(dayid, day_list[2], kc.DB.OWRITER + kc.DB.OCREATE)
    elseif type == 2 then
        load_one_db(dayid - 1, day_list[1], kc.DB.OREADER)
        load_one_db(dayid, day_list[2], kc.DB.OWRITER + kc.DB.OCREATE)
    elseif type == 3 then
        --load_one_db(dayid - 1, day_list[1], kc.DB.OREADER)
        load_one_db(dayid, day_list[2], kc.DB.OWRITER + kc.DB.OCREATE)
    else
        load_one_db(dayid - 1, day_list[1], kc.DB.OREADER)
        --load_one_db(dayid, dayid, kc.DB.OWRITER + kc.DB.OCREATE)
    end
end



if t8 ~= t0 then      --目前处在0点到8点
    load_db(t0, 1)
else        --目前处在8-24点
    load_db(t0, 2)
end



local function check_time()     -- 这里都是自然切换的时间，不是开服时切换的时间
    local now_time = os.time()
    local today_id = get_dayid_from(now_time)
    local today_id_8 = get_dayid_from(now_time, 7)
    
    if today_id_8 ~= today_id then      --目前处在0点到8点
        if day_list[2].dayid ~= today_id then -- 但是db还没切换，则换天
            --print("change day", today_id)
            table.remove(day_list, 1)
            local t = {
                dayid = today_id,
                status = NIL,
                player = {["len"] = 0},
                robot = {},
                pk = {},
                rcd = {},
                db = kc.DB:new(),
                file = 'wlzb' .. today_id .. '.kch',
                db_status = DB_S_NIL
            }
            table.insert(day_list, t)
            if day_list[1].status == REG then
                day_list[1].db:set(flag_status, REG_END)
            end
            day_list[1].db_status = DB_S_CLOSE
            day_list[1].db:close()
            load_db(today_id, 3)
        end
    else        --目前处在8-24点
        if day_list[1].dayid == today_id - 1 then   -- 昨天的db有意义（跳天的话没意义）
            if day_list[1].db_status == DB_S_NIL or day_list[1].db_status == DB_S_CLOSE or day_list[1].db_status == DB_S_RETRY then -- 昨天的db还没打开
                --print("open day", today_id - 1)
                load_db(today_id, 4)
            end
        else
        end
    end
end

--玩家报名
local function regist(main_data, knight_list)
    assert(main_data.lead.level >= 30)
    local t_time = os.time()
    local t_hour = get_h_m_from(t_time)
    assert(t_hour >= 8)
    assert(day_list[2].db_status == DB_S_PKOK)  --kch必须是打开状态
    local uid = main_data.user_name
    local dayid = day_list[1].dayid
    --确认是否报名
    local reg = 0
    local p = day_list[1].player[uid]
    if p then reg = 1 end
    local t = main_data.PVP.reputation
    local new_wlzb = false  --wlzb结构是否需要重置
    local wlzb = rawget(main_data.PVP, "wlzb")
    if not wlzb then
        wlzb = {reg = reg, pk_list = {}, dayid = dayid, new_reg = 0}
        rawset(main_data.PVP, "wlzb", wlzb)
        new_wlzb = true
    else
        if wlzb.dayid ~= dayid then
            wlzb.dayid = dayid
            wlzb.pk_list = {}
            wlzb.reg = reg
            wlzb.new_reg = 0
            new_wlzb = true
        end
    end
    if new_wlzb and p then
        for k,v in ipairs(p.pk) do
            table.insert(wlzb.pk_list, {pk_id = v, reward = 0})
        end
    end
    
    local day_data = day_list[2]
    local player = day_data.player
    
    assert(not rawget(player, uid), "already regist")
    local t_knight_list = {}
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            local t = v.knight.data.level
            local jiban_list = rawget(v.knight.data, "jiban_list")
            if jiban_list then
                for k1,v1 in ipairs(jiban_list) do
                    if v1 >= 0 then
                        local t = core_user.get_knight_from_bag_by_guid(v1, knight_list)
                        assert(t, "knight not find")
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
            uid = uid,
            nick_name = main_data.nickname,
            sex = main_data.lead.sex,
            level = main_data.lead.level,
            star = main_data.lead.star,
            vip = main_data.vip_lev,
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
    local p = {data = player_data, pk = {}}
    rawset(player, uid, p)
    player.len = player.len + 1
    local pb = require "protobuf"
    local t = pb.encode("wlzb_player_kch", p)
    day_data.db:set(uid, t)
    if day_data.status ~= REG then
        day_data.status = REG
        day_data.db:set(flag_status, REG)
    end
    wlzb.new_reg = 1
    LOG_INFO("wlzb|reg|"..main_data.user_name)
    return 2
end

local function check_reg(user_name)
    local reg_list = day_list[2].player
    if not reg_list then
        return 0
    end
    local t = rawget(reg_list, user_name)
    if t then return 1
    else return 0 end
end

local function get_fight_list_by(pk_list, player_list, robot_list)
    -- pk_list是100001,200002等id号
    -- t_pk_list是total_pk_list,是当天的完整pk列表
    local ret_list = {}
    for k,v in ipairs(pk_list) do
        local t_pk_info = {player = {}, rcd_idx = 0, winner = 0}
        local p_uid = {v.pk1, v.pk2}
        for k1,v1 in ipairs(p_uid) do
            if string.sub(v1, 1, 3) == flag_robot then
                local t = robot_list[v1]
                table.insert(t_pk_info.player, t)
            else
                local t = player_list[v1].data.data1
                table.insert(t_pk_info.player, t)
            end
        end
        t_pk_info.rcd_idx = v.rcd_idx
        t_pk_info.winner = v.winner
        table.insert(ret_list, t_pk_info)
    end
    return ret_list
end
--获取指定玩家的pk日志
local function get_self_pk_list(uid, main_data)
    local day_data = day_list[1]
    --确认是否报名
    local p = day_data.player[uid]
    local reg = 0
    if day_data.status == FINISH then
        if p then reg = 1 end
    end
        
    local dayid = day_data.dayid
    local t = main_data.PVP.reputation
    local new_wlzb = false  --wlzb结构是否需要重置
    local wlzb = rawget(main_data.PVP, "wlzb")
    if not wlzb then
        wlzb = {reg = reg, pk_list = {}, dayid = dayid, new_reg = 0}
        rawset(main_data.PVP, "wlzb", wlzb)
        new_wlzb = true
    else
        if wlzb.dayid ~= dayid then
            wlzb.dayid = dayid
            wlzb.pk_list = {}
            wlzb.reg = reg
            wlzb.new_reg = 0
            new_wlzb = true
        else
            local t = wlzb.pk_list[1]
            t = rawget(wlzb, "pk_list")
            if  reg ~= 0 and (not t or rawlen(t) == 0) then
                wlzb.reg = reg
                wlzb.pk_list = {}
                new_wlzb = true
            end
        end
    end

    if reg == 0 then
        return nil, wlzb
    end
    
    local t_pk_list = day_data.pk       -- 当天的总pklist
    local pk_list = {}
    
    for k,v in ipairs(p.pk) do
        local idx1 = math.floor(v / 100000)
        local idx2 = math.floor(v % 100000)
        local pk_info = t_pk_list[idx1][idx2]
        assert(pk_info)
        table.insert(pk_list, pk_info)
        local reward = 0
        if (pk_info.winner == 2 and pk_info.pk1 == uid)
            or (pk_info.winner == 1 and pk_info.pk2 == uid) then
            reward = 1
        end
        if new_wlzb then
            table.insert(wlzb.pk_list, {pk_id = v, reward = reward})
        end
    end
    
    local ret_list = get_fight_list_by(pk_list, day_data.player, day_data.robot)
    return ret_list, wlzb
end

--获取8强日志
local function get_8_list()
    local day_data = day_list[1]
    if day_data.status ~= FINISH then
        return nil
    end
    local t_pk_list = day_data.pk       -- 当天的总pklist
    local round = rawlen(t_pk_list)
    assert(round >= 12, "round less then 12")
    local pk_list = {}
    for k = round - 2, round do
        for k1, v1 in ipairs(t_pk_list[k]) do
            table.insert(pk_list, v1)
        end
    end
    local ret_list = get_fight_list_by(pk_list, day_data.player, day_data.robot)
    return ret_list
end

--获取战斗轮数
local function get_round_num()
    local day_data = day_list[1]
    local t_pk_list = day_data.pk       -- 当天的总pklist
    local round = rawlen(t_pk_list)
    return round
end

--获取战斗rcd
local function get_rcd(rcd_idx)
    local day_data = day_list[1]
    local rcd_list = day_data.rcd
    local rcd = rcd_list[rcd_idx]
    assert(rcd and rcd ~= 0)
    local rcd_buf = day_data.db:get(flag_rcd..rcd)
    local pb = require "protobuf"
    rcd = pb.decode("FightRcd", rcd_buf)
    return rcd
end

--
local function get_real_reward(wlzb_info, reward_id)
    local dayid = wlzb_info.dayid
    assert(dayid == day_list[1].dayid and wlzb_info.reg == 1, "wlzb info err")
    local round_num = rawlen(day_list[1].pk)
    local t = wlzb_info.pk_list[1]
    local reward_len = rawlen(wlzb_info.pk_list)
    assert(reward_id <= reward_len, "reward_id err")
    local real_idx = round_num - reward_id + 1
    return real_idx
end

-- 这里事先生成奖励列表，便于随时获取
local reward_list = {}
local len = War_conf.len
for k = 1, len do
    local conf = War_conf[k]
    local t = 1
    local t_list = {}
    while conf.Reward[t] do
        table.insert(t_list, {id = conf.Reward[t], num = conf.Reward[t + 1]})
        t = t + 2
    end
    table.insert(reward_list, {item_list = t_list})
end

local function get_reward_list()
    return reward_list
end

local wlzb = {
    check_reg = check_reg,
    regist = regist,
    get_self_pk_list = get_self_pk_list,
    get_8_list = get_8_list,
    get_rcd = get_rcd,
    get_round_num = get_round_num,
    get_real_reward = get_real_reward,
    get_reward_list = get_reward_list,
    check_time = check_time
}

return wlzb