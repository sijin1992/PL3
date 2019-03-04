--根据通关关卡判断是否完成任务
local function check_task_event_stage(main_data, stage_info)
    local stage_id = stage_info.id
    local ret = nil
    local task_system = main_data.task_list
    local task_list = task_system.task_list
    for k,v in ipairs(task_list) do
        if v.status == 1 then
            local conf = Task_conf[v.id]
            assert(conf, "not find the task")
            if conf.PARA_TYPE == 1 or conf.PARA_TYPE == 2 then
                if conf.PARA == stage_id then
                    v.status = 2
                    if not ret then ret = {} end
                    table.insert(ret, v)
                end
            end
        end
    end
    return ret
end

local function check_task_by_task_stage(main_data, task_data, task_conf)
    local param = task_conf.PARA
    local f_idx = Stage_conf[param].BELONGS_FORTRESS
    local f = math.floor((f_idx - 70000000) / 10000)
    local s = param % 10000
    local f_data = main_data.PVE.fortress_list
    local t = f_data[1].stage_list[1].difficulty_list[1]
    if f > rawlen(f_data) then
        return false
    end
    local s_data = f_data[f].stage_list[s].difficulty_list[1]
    if s_data.pass_num > 0 then
        task_data.status = 2
        --LOG_EXT(string.format("TASK F:%s|%d",
            --main_data.user_name, task_data.id))
        return true
    end
    return false
end

local function check_task_by_task_jingstage(main_data, task_data, task_conf)
    local param = task_conf.PARA
    local jing_conf = Jing_Stage_conf[param]
    local f_idx = jing_conf.BELONGS_FORTRESS
    local f = math.floor((f_idx - 70000000) / 10000)
    local s = param % 10000
    local f_data = main_data.PVE.jingying
    local t = f_data[1].stage_list[1].pass_num
    if f > rawlen(f_data) then
        return false
    end
    t = f_data[f].stage_list[s].pass_num
    if t > 0 then
        task_data.status = 2
        return true
    end
    return false
end

local function check_task_by_event(main_data, event_type, event_data)
    if event_type == 1 or event_type == 2 then
        return check_task_event_stage(main_data, event_data)
    end
end

--直接判断某个任务是否完成
local function check_task_by_task(main_data, task_data, task_conf)
    if task_conf.PARA_TYPE == 1 then
        return check_task_by_task_stage(main_data, task_data, task_conf)
    elseif task_conf.PARA_TYPE == 2 then
        return check_task_by_task_jingstage(main_data, task_data, task_conf)
    end
    error("task type unknow")
end

local function reflesh_task_when_levelup(main_data, new_level)
    local ret = {}
    local has_something = false
    local task_system = main_data.task_list
    local task_list = task_system.task_list
    local task_chain_list = {}
    for k,v in ipairs(task_list) do
        local conf = Task_conf[v.id]
        table.insert(task_chain_list, conf.PARA_TYPE)
    end
    local new_task_chain = {}
    for k,v in ipairs(Task_conf.index) do
        if v % 1000 == 1 then
            local conf = Task_conf[v]
            local type = conf.PARA_TYPE
            local level = conf.TASK_LV
            if new_level >= level then
                local need_add = true
                for k1,v1 in ipairs(task_chain_list) do
                    if type == v1 then
                        need_add = false
                        break
                    end
                end
                if need_add then
                    local new_task = {id = v, status = 1}
                    check_task_by_task(main_data, new_task, conf)
                    table.insert(task_list, new_task)
                    table.insert(ret, new_task)
                    has_something = true
                end
            end
        end
    end
    
    if has_something then return ret
    else return nil end
end

----成就系统
--返回0没变化，1进度变化，2状态变化（完成）
--主角升级1
local function check_chengjiu_by_event_levelup(main_data, data, conf)
    local level = main_data.lead.level
    data.flag = level
    if level >= conf.Para[1] then
        data.status = 1
        return 2
    end
    return 0
end

--装备强化2
local function check_chengjiu_by_event_equip_levelup(main_data, data, conf)
    local equip_level = conf.Para[1]
    local t = main_data.lead.equip_list[1].level
    local flag = true
    for k,v in ipairs(main_data.lead.equip_list) do
        if v.level < equip_level then
            flag = false
            break
        end
    end
    if flag then
        data.flag = 1
        data.status = 1
        return 2
    end
    return 0
end

--装备精炼3------这里逻辑不对了，以后改，星级要从配置表里读
local function check_chengjiu_by_event_equip_starup(main_data, data, conf)
    local equip_star = conf.Para[1]
    local t = main_data.lead.equip_list[1].level
    local flag = true
    for k,v in ipairs(main_data.lead.equip_list) do
        local level = math.floor(v.star/3)
        if level < equip_star then
            flag = false
            break
        end
    end
    if flag then
        data.flag = 1
        data.status = 1
        return 2
    end
    return 0
end

--装备套装(等级)4
local function check_chengjiu_by_event_equip_levelset(main_data, data, conf)
    local idx = conf.Para[1]
    local set_conf = Equipment_Set_conf[idx]
    assert(set_conf, "equipset not find")
    local limit = set_conf.GRADE
    local success = true
    local equip_list = main_data.lead.equip_list
    for k,v in ipairs(equip_list) do
        if v.level < limit then
            success = false
            break
        end
    end
    if success then
        data.status = 1
        return 2
    end
    return 0
end

--装备套装(星级)5
local function check_chengjiu_by_event_equip_starset(main_data, data, conf)
    local idx = conf.Para[1]
    local set_conf = Equipment_Set_conf[idx]
    assert(set_conf, "equipset not find")
    local limit = set_conf.GRADE
    local success = true
    local equip_list = main_data.lead.equip_list
    for k,v in ipairs(equip_list) do
        local idx = 140000000 + k * 10000 + v.star
        local conf = Equipment_Star_conf[idx]
        local level = conf.UPGRADE_CLASS
        if level < limit then
            success = false
            break
        end
    end
    if success then
        data.status = 1
        return 2
    end
    return 0
end

--收集指定星级侠客数量6
local function check_chengjiu_by_event_knight_star_num(main_data, data, conf, knight_list)
    local star = conf.Para[1]
    local num = conf.Para[2]
    local t_num = 0
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            local knight_id = v.knight.id
            local c_conf = Character_conf[knight_id]
            local t_star = c_conf.STAR_LEVEL
            if t_star == star then t_num = t_num + 1 end
        end
    end
    for k,v in ipairs(knight_list) do
        local knight_id = v.id
        local c_conf = Character_conf[knight_id]
        local t_star = c_conf.STAR_LEVEL
        if t_star == star then t_num = t_num + 1 end
    end
    local flag = data.flag
    if t_num >= num then
        data.status = 1
        data.flag = num
        return 2
    elseif t_num > flag then
        data.flag = t_num
        return 1
    end
    return 0
end

--收集指定侠客7
local function check_chengjiu_by_event_knight_special(main_data, data, conf, knight_list)
    local knight_id = conf.Para[1]
    local success = false
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            local t_knight_id = v.knight.id
            if knight_id == t_knight_id then
                success = true
                break
            end
        end
    end
    if not success then
        for k,v in ipairs(knight_list) do
            local t_knight_id = v.id
            if knight_id == t_knight_id then
                success = true
                break
            end
        end
    end
    if success then
        data.status = 1
        return 2
    end
    return 0
end

--收集指定等阶侠客数量8
local function check_chengjiu_by_event_knight_evo_num(main_data, data, conf, knight_list)
    local evo = conf.Para[1]
    local num = conf.Para[2]
    local t_num = 0
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            local t_evo = v.knight.data.evolution
            if t_evo >= evo then t_num = t_num + 1 end
        end
    end
    for k,v in ipairs(knight_list) do
        local t_evo = 1
        if v.data and v.data.level ~= 0 then t_evo = v.data.evolution end
        if t_evo >= evo then t_num = t_num + 1 end
    end
    local flag = data.flag
    if t_num >= num then
        data.status = 1
        data.flag = num
        return 2
    elseif t_num > flag then
        data.flag = t_num
        return 1
    end
    return 0
end

--侠客武学等级数量9
local function check_chengjiu_by_event_knight_gonglv_num(main_data, data, conf, knight_list)
    local gonglv = conf.Para[1]
    local num = conf.Para[2]
    local t_num = 0
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            local t_gonglv = v.knight.data.gong.level
            if t_gonglv >= gonglv then t_num = t_num + 1 end
        end
    end
    for k,v in ipairs(knight_list) do
        local t_gonglv = 1
        if v.data and v.data.level ~= 0 then t_gonglv = v.data.gong.level end
        if t_gonglv >= gonglv then t_num = t_num + 1 end
    end
    local flag = data.flag
    if t_num >= num then
        data.status = 1
        data.flag = num
        return 2
    elseif t_num > flag then
        data.flag = t_num
        return 1
    end
    return 0
end

--藏书收集10
local function check_chengjiu_by_event_book(main_data, data, conf)
    local bookid = math.floor((conf.Para[1] - 80000000)/ 10000)
    local book_list = rawget(main_data, "book_list")
    if book_list then
        for k,v in ipairs(book_list) do
            if v.id == bookid then
                data.status = 1
                return 2
            end
        end
    end
    return 0
end

--声望11
local function check_chengjiu_by_event_title(main_data, data, conf)
    local pvp_title = conf.Para[1]
    local title_conf = PVP_Title_conf[pvp_title]
    assert(title_conf, "PVP_Title conf not find")
    local reputation = main_data.PVP.reputation
    if reputation >= title_conf.POPULARITY[1] then
        data.status = 1
        return 2
    end
    return 0
end

--pvp相关次数12
local function check_chengjiu_by_event_pvp_count(main_data, data, conf)
    local total_count = main_data.PVP.total_count
    local total_win = main_data.PVP.total_win
    local total_lose = total_count - total_win
    local t = conf.Para[1]
    local v = conf.Para[2]
    local f = 0
    if t == 1 then f = total_count
    elseif t == 2 then f = total_win
    else f = total_lose end
    local flag = data.flag
    data.flag = f
    if f >= v then
        data.status = 1
        data.flag = v
        return 2
    elseif f > flag then
        data.flag = f
        return 1
    end
    return 0
end

--声望13
local function check_chengjiu_by_event_shengwang(main_data, data, conf)
    local shengwang = conf.Para[1]
    local reputation = main_data.PVP.reputation
    local flag = data.flag
    if reputation >= shengwang then
        data.status = 1
        data.flag = shengwang
        return 2
    elseif reputation > flag then
        data.flag = reputation
        return 1
    end
    return 0
end

--购买pvp挑战14
local function check_chengjiu_by_event_total_m2c(main_data, data, conf)
    local limit = conf.Para[1]
    local value = main_data.ext_data.total_m2c_num
    local flag = data.flag
    
    if value >= limit then
        data.status = 1
        data.flag = limit
        return 2
    elseif value > flag then
        data.flag = value
        return 1
    end
    return false
end

--金币15
local function check_chengjiu_by_event_total_gold(main_data, data, conf)
    local limit = conf.Para[1]
    local value = main_data.ext_data.total_gold
    local flag = data.flag
    if value >= limit then
        data.status = 1
        data.flag = limit
        return 2
    elseif value > flag then
        data.flag = value
        return 1
    end
    return 0
end

--hp消耗16
local function check_chengjiu_by_event_total_hp(main_data, data, conf)
    local limit = conf.Para[1]
    local value = main_data.ext_data.total_hp
    local flag = data.flag
    if value >= limit then
        data.status = 1
        data.flag = limit
        return 2
    elseif value > flag then
        data.flag = value
        return 1
    end
    return 0
end

--登录天数17
local function check_chengjiu_by_event_total_login(main_data, data, conf)
    local limit = conf.Para[1]
    local value = main_data.ext_data.total_login
    local flag = data.flag
    if value >= limit then
        data.status = 1
        data.flag = limit
        return 2
    elseif value > flag then
        data.flag = value
        return 1
    end
    return 0
end

--充值总额18
local function check_chengjiu_by_event_total_money(main_data, data, conf)
    local limit = conf.Para[1]
    local value = main_data.ext_data.total_money
    local flag = data.flag
    if value >= limit then
        data.status = 1
        data.flag = limit
        return 2
    elseif value > flag then
        data.flag = value
        return 1
    end
    return 0
end

--pve次数19，pve精英挑战次数20，扫荡次数22
local function check_chengjiu_by_event_total_pve(main_data, data, conf, num)
    local limit = conf.Para[1]
    local value = data.flag
    local n = 1
    if num then n = num end
    data.flag = value + n
    value = value + 1
    if value >= limit then
        data.status = 1
        return 2
    end
    return 1
end

--持有银两(金币)最大值21
local function check_chengjiu_by_event_max_gold(main_data, data, conf)
    local limit = conf.Para[1]
    local cur_gold = main_data.gold
    local value = data.flag
    if cur_gold > value then
        value = cur_gold
        if value >= limit then
            data.status = 1
            data.flag = limit
            return 2
        else
            data.flag = value
            return 1
        end
    else
        return 0
    end
end

--通关指定关卡23
local function check_chengjiu_by_event_stage(main_data, data, conf, stage_id)
    local s = conf.Para[1]
    if s == stage_id then
        data.status = 1
        return 2
    else
        return 0
    end
end

local check_chengjiu_by_event_funcs = {
    check_chengjiu_by_event_levelup,            --1
    check_chengjiu_by_event_equip_levelup,      --2
    check_chengjiu_by_event_equip_starup,       --3
    check_chengjiu_by_event_equip_levelset,     --4
    check_chengjiu_by_event_equip_starset,      --5
    check_chengjiu_by_event_knight_star_num,    --6
    check_chengjiu_by_event_knight_special,     --7
    check_chengjiu_by_event_knight_evo_num,     --8
    check_chengjiu_by_event_knight_gonglv_num,  --9
    check_chengjiu_by_event_book,               --10
    check_chengjiu_by_event_title,              --11
    check_chengjiu_by_event_pvp_count,          --12
    check_chengjiu_by_event_shengwang,          --13
    check_chengjiu_by_event_total_m2c,          --14
    check_chengjiu_by_event_total_gold,         --15
    check_chengjiu_by_event_total_hp,           --16
    check_chengjiu_by_event_total_login,        --17
    check_chengjiu_by_event_total_money,        --18
    check_chengjiu_by_event_total_pve,          --19
    check_chengjiu_by_event_total_pve,          --20
    check_chengjiu_by_event_max_gold,           --21
    check_chengjiu_by_event_total_pve,          --22
    check_chengjiu_by_event_stage,              --23
}

local function check_chengjiu_by_event(main_data, event_type, event_data)
    local ret_chengjius = {}
    local ret = false
    local chengjiu_list = main_data.chengjiu.chengjiu_list
    for k,v in ipairs(chengjiu_list) do
        if v.status == 0 then
            local cj_type = math.floor((v.id % 100000) / 1000)
            local cj_mtype = math.floor((v.id % 1000000) / 100000)
            if event_type == cj_type then
                local conf = Achievement_conf[v.id]
                assert(conf, string.format("achievement %d not find", v.id))
                local func = check_chengjiu_by_event_funcs[cj_type]
                assert(func, "some chengjiu func not find")
                local r = func(main_data, v, conf, event_data)
                if r == 2 or (r == 1 and conf.Process_Dsc == 1) then   --r = 0,没改变，1，flag变，2，状态变
                    if r == 2 and cj_mtype == 6 then v.status = 2 end
                    table.insert(ret_chengjius, v)
                    ret = true
                    if r == 2 then
                        --LOG_EXT(string.format("CHENGJIU F:%s|%d",
                            --main_data.user_name, v.id))
                    end
                end
            end
        end
    end
    if ret then return ret_chengjius
    else return nil end
end

local function fill_chengjiu_check_list(check_list, ret_list)
    check_list.ret = true
    check_list.data.chengjiu = 1
    if not check_list.data.chengjiu_list then
        check_list.data.chengjiu_list = ret_list
    else
        for k,v in ipairs(ret_list) do
            table.insert(check_list.data.chengjiu_list, v)
        end
    end
end

--封装一下成就
local function check_chengjiu_levelup(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 1, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_equip_levelup(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 2, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_equip_starup(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 3, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_equip_levelset(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 4, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_equip_starset(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 5, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_knight_star_num(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 6, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_knight_special(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 7, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_knight_evo_num(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 8, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_knight_gonglv_num(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 9, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_book(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 10, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_title(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 11, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_pvp_count(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 12, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_shengwang(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 13, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_total_m2c(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 14, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_total_gold(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 15, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_total_hp(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 16, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_total_login(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 17, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_total_money(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 18, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_total_pve(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 19, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_total_jingying(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 20, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_max_gold(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 21, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_total_clear(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 22, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end
local function check_chengjiu_stage(check_list, main_data, event_data)
    local ret = check_chengjiu_by_event(main_data, 23, event_data)
    if check_list and ret then
        fill_chengjiu_check_list(check_list, ret)        
    end
end

----每日活跃
--1技能升级
--2通关普通关卡
--3点石成金
--4比武类型
--5抽奖
--6月卡
--7领取体力
--8乱世纷争
--9购买体力
--10签到
local function do_daily_by_event_func(data, conf, ext_data)
    local ret = 1
    local count = 1
    if (conf.Para_Type == 5 or conf.Para_Type == 1 or conf.Para_Type == 2) and ext_data then count = ext_data end
    --if rawlen(conf.Para) == 1 then
        local flag = data.flag
        flag = flag + count
        data.flag = flag
        --if flag < conf.Para then ret = 1 end
    --end
    if flag >= conf.Para[1] then
        data.status = 1
        ret = 2
    end
    return ret
end

local function do_daily7_func(data, conf, main_data, time_slice, hour)
    local id = data.id % 10
    if time_slice > id then
        if data.status ~= 3 then
            data.status = 3
            data.flag = 1
            return 1
        end
    elseif time_slice == id then
        if hour < conf.Para[1] then
            if data.status ~= 0 then
                data.status = 0
                return 1
            end
        elseif data.status ~= 1 and data.status ~= 2 and data.flag == 0 then
            data.status = 1
            return 2
        end
    end
end

local function do_daily_by_event(main_data, event_type, ext_data)
    local ret_dailys = {}
    local ret = false
    local time_slice = 0
    local hour = 0
    if event_type == 7 then
        local tm = os.date("*t")
        hour = tm.hour
        time_slice = 1
        if hour >= 5 and hour < 14 then time_slice = 1
        elseif hour >= 14 and hour < 20 then time_slice = 2
        elseif hour >= 20 and hour < 24 then time_slice = 3
        else time_slice = 4 end
    end
    local daily_list = main_data.daily.daily_list
    for k,v in ipairs(daily_list) do
        if event_type == 7 then
            local d_type = math.floor((v.id % 100000) / 1000)
            if event_type == d_type then
                local conf = Daily_conf[v.id]
                assert(conf, "some daily not find")
                local func = do_daily_by_event_func
                assert(func, "some daily func not find")
                local r = do_daily7_func(v, conf, main_data, time_slice, hour)
                if r == 2 or (r == 1 and conf.Process_Dsc[1] == 1) then
                    table.insert(ret_dailys, v)
                    ret = true
                    if r == 2 then
                        --LOG_EXT(string.format("DAILY F:%s|%d",
                            --main_data.user_name, v.id))
                    end
                end
            end
        else
            if v.status == 0 then
                local d_type = math.floor((v.id % 100000) / 1000)
                if event_type == d_type then
                    local conf = Daily_conf[v.id]
                    assert(conf, "some daily not find")
                    local func = do_daily_by_event_func
                    assert(func, "some daily func not find")
                    local r = func(v, conf, ext_data)
                    if r == 2 or (r == 1 and conf.Process_Dsc[1] == 1) then
                        table.insert(ret_dailys, v)
                        ret = true
                        if r == 2 then
                            --LOG_EXT(string.format("DAILY F:%s|%d",
                                --main_data.user_name, v.id))
                        end
                    end
                end
            end
        end
    end
    if ret then return ret_dailys
    else return nil end
end

local function fill_daily_check_list(check_list, ret_list)
    check_list.ret = true
    check_list.data.huoyue = 1
    if not check_list.data.daily_list then
        check_list.data.daily_list = ret_list
    else
        for k,v in ipairs(ret_list) do
            table.insert(check_list.data.daily_list, v)
        end
    end
end

--封装一下daily
local function check_daily_skill_levelup(check_list, main_data, event_data)
    local ret = do_daily_by_event(main_data, 1, event_data)
    if check_list and ret then
        fill_daily_check_list(check_list, ret)        
    end
end
local function check_daily_pve(check_list, main_data, event_data)
    local ret = do_daily_by_event(main_data, 2, event_data)
    if check_list and ret then
        fill_daily_check_list(check_list, ret)        
    end
end
local function check_daily_m2g(check_list, main_data, event_data)
    local ret = do_daily_by_event(main_data, 3, event_data)
    if check_list and ret then
        fill_daily_check_list(check_list, ret)        
    end
end
local function check_daily_pvp(check_list, main_data, event_data)
    local ret = do_daily_by_event(main_data, 4, event_data)
    if check_list and ret then
        fill_daily_check_list(check_list, ret)        
    end
end
local function check_daily_choujiang(check_list, main_data, event_data)
    local ret = do_daily_by_event(main_data, 5, event_data)
    if check_list and ret then
        fill_daily_check_list(check_list, ret)        
    end
end
local function check_daily_tili(check_list, main_data, event_data)
    local ret = do_daily_by_event(main_data, 7, event_data)
    if check_list and ret then
        fill_daily_check_list(check_list, ret)        
    end
end
local function check_daily_fengzheng(check_list, main_data, event_data)
    local ret = do_daily_by_event(main_data, 8, event_data)
    if check_list and ret then
        fill_daily_check_list(check_list, ret)        
    end
end
local function check_daily_m2h(check_list, main_data, event_data)
    local ret = do_daily_by_event(main_data, 9, event_data)
    if check_list and ret then
        fill_daily_check_list(check_list, ret)        
    end
end
local function check_daily_qiandao(check_list, main_data, event_data)
    local ret = do_daily_by_event(main_data, 10, event_data)
    if check_list and ret then
        fill_daily_check_list(check_list, ret)        
    end
end

local function reflesh_daily_when_levelup(main_data, new_level, old_level)
    local ret = {}
    local has_something = false
    local daily_system = main_data.daily
    local daily_list = daily_system.daily_list
    local t = daily_list[1].id
    
    for k,v in ipairs(Daily_conf.index) do
        local conf = Daily_conf[v]
        local lev_limit = conf.Daily_Lv
        if old_level < lev_limit and new_level >= lev_limit  then
            local data = {id = v, status = 0, flag = 0, tag = 0}
            local t = conf.Para_Type
            if t == 7 then
                data.tag = 1
            else
                data.tag = conf.Para[1]
            end
            table.insert(daily_list, data)
            has_something = true
        end
    end
    if has_something then return ret
    else return nil end
end

-- 开服任务
--主角升级1
local function check_newtask_by_event_levelup(main_data, data, conf)
    local level = main_data.lead.level
    data.flag = level
    if level >= conf.PARA[1] then
        data.status = 1
        return 2
    end
    return 0
end
--技能升级2
local function check_newtask_by_event_skilllevelup(main_data, data, conf, ext_data)
    local add = 1
    if ext_data then add = ext_data end
    local flag = data.flag + add
    data.flag = flag
    if flag >= conf.PARA[1] then
        data.status = 1
        return 2
    end
    return 0
end
-- 藏书开启3
local function check_newtask_by_event_book(main_data, data, conf)
    local bookid = math.floor((conf.PARA[1] - 80000000)/ 10000)
    local book_list = rawget(main_data, "book_list")
    if book_list then
        for k,v in ipairs(book_list) do
            if v.id == bookid then
                data.status = 1
                return 2
            end
        end
    end
    return 0
end
--武学境界4
local function check_newtask_by_event_knight_gonglv_num(main_data, data, conf, knight_list)
    local gonglv = conf.PARA[1]
    local num = conf.PARA[2]
    local t_num = 0
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            local t_gonglv = v.knight.data.gong.level
            if t_gonglv >= gonglv then t_num = t_num + 1 end
        end
    end
    for k,v in ipairs(knight_list) do
        local t_gonglv = 1
        if v.data and v.data.level ~= 0 then t_gonglv = v.data.gong.level end
        if t_gonglv >= gonglv then
            t_num = t_num + 1
            if t_num >= num then
                break
            end
        end
    end
    local flag = data.flag
    if t_num >= num then
        data.status = 1
        data.flag = num
        return 2
    elseif t_num > flag then
        data.flag = t_num
        return 1
    end
    return 0
end
--通关关卡5
local function check_newtask_by_event_stage(main_data, data, conf, stage_id)
    if stage_id == conf.PARA[1] then
        data.status = 1
        return 2
    end
    return 0
end
--装备强化6
local function check_newtask_by_event_equip_levelup(main_data, data, conf)
    local equip_id = conf.PARA[1]
    local equip_level = conf.PARA[2]
    local t = main_data.lead.equip_list[equip_id].level
    data.flag = t
    if t >= equip_level then
        data.status = 1
        return 2
    end
    return 0
end
--声望7
local function check_newtask_by_event_shengwang(main_data, data, conf)
    local shengwang = conf.PARA[1]
    local reputation = main_data.PVP.reputation
    local flag = data.flag
    if reputation >= shengwang then
        data.status = 1
        data.flag = shengwang
        return 2
    elseif reputation > flag then
        data.flag = reputation
        return 1
    end
    return 0
end
--侠侣开启8
local function check_newtask_by_event_lover(main_data, data, conf)
    local loverid = conf.PARA[1]
    local lover_list = rawget(main_data, "lover_list")
    if lover_list then
        for k,v in ipairs(lover_list) do
            if v.id == loverid then
                data.status = 1
                return 2
            end
        end
    end
    return 0
end
--收集指定等阶侠客数量9
local function check_new_by_event_knight_evo_num(main_data, data, conf, knight_list)
    local evo = conf.PARA[1]
    local num = conf.PARA[2]
    local t_num = 0
    for k,v in ipairs(main_data.zhenxing.zhanwei_list) do
        if v.status == 2 then
            local t_evo = v.knight.data.evolution
            if t_evo >= evo then t_num = t_num + 1 end
        end
    end
    for k,v in ipairs(knight_list) do
        local t_evo = 1
        if v.data and v.data.level ~= 0 then t_evo = v.data.evolution end
        if t_evo >= evo then
            t_num = t_num + 1
            if t_num >= num then break end
        end
    end
    local flag = data.flag
    if t_num >= num then
        data.status = 1
        data.flag = num
        return 2
    elseif t_num > flag then
        data.flag = t_num
        return 1
    end
    return 0
end

local check_newtask_by_event_funcs = {
    check_newtask_by_event_levelup,
    check_newtask_by_event_skilllevelup,
    check_newtask_by_event_book,
    check_newtask_by_event_knight_gonglv_num,
    check_newtask_by_event_stage,
    check_newtask_by_event_equip_levelup,
    check_newtask_by_event_shengwang,
    check_newtask_by_event_lover,
    check_new_by_event_knight_evo_num,
}

local function check_newtask_by_event(main_data, event_type, event_data)
    local t = main_data.huodong.new_task_list.regist_dayid
    local new_task_list = rawget(main_data.huodong, "new_task_list")
    if not new_task_list then return nil end
    for k,v in ipairs(new_task_list.event_list) do
        if v.status == 0 then
            for k1,v1 in ipairs(v.task_list) do
                if v1.status == 0 then
                    local type = math.floor((v1.id - 500000000)/10000)
                    if type == event_type then
                        local func = check_newtask_by_event_funcs[type]
                        local conf = NewTask_conf[v1.id]
                        assert(func, "some chengjiu func not find")
                        local r = func(main_data, v1, conf, event_data)
                    end
                end
            end
        end
    end
end

--封装一下升级的任务成就每日活跃检测
local function reflesh_all_when_levelup(check_list, main_data, levelup_struct)
    local reflesh_task_list = reflesh_task_when_levelup(main_data, levelup_struct.data.new_level)
    local reflesh_daily_list = reflesh_daily_when_levelup(main_data, levelup_struct.data.new_level, levelup_struct.data.old_level)
    if reflesh_task_list then
        check_list.ret = true
        check_list.data.task = 1
        if not check_list.data.task_list then
            check_list.data.task_list = reflesh_task_list
        else
            for k,v in ipairs(reflesh_task_list) do
                table.insert(check_list.data.task_list, v)
            end
        end
    end
    if reflesh_daily_list then
        check_list.ret = true
        check_list.data.huoyue = 1
        if not check_list.data.daily_list then
            check_list.data.daily_list = reflesh_daily_list
        else
            for k,v in ipairs(reflesh_daily_list) do
                table.insert(check_list.data.daily_list, v)
            end
        end
    end
end


local core_task = {
    check_task_by_event = check_task_by_event,
    check_task_by_task = check_task_by_task,
    reflesh_task_when_levelup = reflesh_task_when_levelup,
    check_chengjiu_by_event = check_chengjiu_by_event,
    do_daily_by_event = do_daily_by_event,
    reflesh_daily_when_levelup = reflesh_daily_when_levelup,
    check_newtask_by_event = check_newtask_by_event,
    --封装的成就接口
    check_chengjiu_levelup = check_chengjiu_levelup,
    check_chengjiu_equip_levelup = check_chengjiu_equip_levelup,
    check_chengjiu_equip_starup = check_chengjiu_equip_starup,
    check_chengjiu_equip_levelset = check_chengjiu_equip_levelset,
    check_chengjiu_equip_starset = check_chengjiu_equip_starset,
    check_chengjiu_knight_star_num = check_chengjiu_knight_star_num,
    check_chengjiu_knight_special = check_chengjiu_knight_special,
    check_chengjiu_knight_evo_num = check_chengjiu_knight_evo_num,
    check_chengjiu_knight_gonglv_num =  check_chengjiu_knight_gonglv_num,
    check_chengjiu_book = check_chengjiu_book,
    check_chengjiu_title = check_chengjiu_title,
    check_chengjiu_pvp_count = check_chengjiu_pvp_count,
    check_chengjiu_shengwang = check_chengjiu_shengwang,
    check_chengjiu_total_m2c = check_chengjiu_total_m2c,
    check_chengjiu_total_gold = check_chengjiu_total_gold,
    check_chengjiu_total_hp = check_chengjiu_total_hp,
    check_chengjiu_total_login = check_chengjiu_total_login,
    check_chengjiu_total_money = check_chengjiu_total_money,
    check_chengjiu_total_pve = check_chengjiu_total_pve,
    check_chengjiu_total_jingying = check_chengjiu_total_jingying,
    check_chengjiu_max_gold = check_chengjiu_max_gold,
    check_chengjiu_total_clear = check_chengjiu_total_clear,
    check_chengjiu_stage = check_chengjiu_stage,
    --封装的活跃接口
    check_daily_skill_levelup = check_daily_skill_levelup,
    check_daily_pve = check_daily_pve,
    check_daily_m2g = check_daily_m2g,
    check_daily_pvp = check_daily_pvp,
    check_daily_choujiang = check_daily_choujiang,
    check_daily_tili = check_daily_tili,
    check_daily_fengzheng = check_daily_fengzheng,
    check_daily_m2h = check_daily_m2h,
    check_daily_qiandao = check_daily_qiandao,
    --封装升级时的所有事情
    reflesh_all_when_levelup = reflesh_all_when_levelup,
}

return core_task