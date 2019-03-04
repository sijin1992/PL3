local core_user = require "core_user_funcs"
local time_checking = require "time_checking"
local core_money = {}

function core_money.reflesh_m2g(num, money, level, vip_rate, vip_crit)
    local base = 0
    local splatform = 0
    if server_platform then splatform = server_platform end
    
    if server_platform == 0 then
        base = 30300 + level * 75 + (num - 1) * 2000
    else
        base = 20300 + level * 75 + (num - 1) * 1000
    end
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

-- 如何使用元宝。type=1，优先真元宝，type=0，优先假元宝
function core_money.use_money(value, user_info, type, where)
    assert(value <= user_info.money, "yuanbao not enough")
    local real_money = user_info.ext_data.real_money
    local money_1 = user_info.money - real_money
    local ret = {
        use_money = 0,  --真元宝
        use_money_1 = 0,--假元宝
    }
    type = 1--强制优先使用真元宝
    if type == 0 then
        if value <= money_1 then
            --money_1 = money_1 - value
            ret.use_money_1 = value
        else
            ret.use_money_1 = money_1
            ret.use_money = value - money_1
            --real_money = real_money - (value - money_1)
            --money_1 = 0
        end
    else
        if value <= real_money then
            --real_money = real_money - value
            ret.use_money = value
        else
            ret.use_money = real_money
            ret.use_money_1 = value - real_money
            --money_1 = money_1 - (value - real_money)
            --real_money = 0
        end
    end
    local cw_cost = 0
    local cw_cost_t = user_info.ext_data.cw_money
    if ret.use_money > 0 then
        core_user.expend_item(191010099, ret.use_money, user_info, where)
        cw_cost = user_info.ext_data.cw_money - cw_cost_t
    end
    if ret.use_money_1 > 0 then
        core_user.expend_item(191010003, ret.use_money_1, user_info, where)
    end
    
    local dayid = time_checking.get_dayid_from(os.time())
    time_checking.update_at_0am_1(user_info, dayid)
    --单日消费
    local s, t = global_huodong.check_xffl(user_info)
    if t then t.total_money = t.total_money + value end
    if t then
        local tt = 0
        for k,v in ipairs(t.reward_list) do
            if v.status == 0 and t.total_money >= v.conf then tt = tt + 1 end
        end
        user_info.ext_data.huodong.xffl = tt
        global_huodong.reflesh_hongdian_flag(user_info, 59001, tt)
    end
    --阶段消费
    local s, t = global_huodong.check_ljxffl(user_info)
    if t then t.total_money = t.total_money + value end
    if t then
        local tt = 0
        for k,v in ipairs(t.reward_list) do
            if v.status == 0 and t.total_money >= v.conf then tt = tt + 1 end
        end
        global_huodong.reflesh_hongdian_flag(user_info, 67001, tt)
    end
    
    LOG_STAT(string.format( "%s|%s|%d|%d|%d|%d|%d|%d|%d|%s|%s|%s", "CAST_YB", 
        user_info.user_name, where, value, ret.use_money, cw_cost,
        user_info.ext_data.cw_money, user_info.ext_data.real_money,
        user_info.money, user_info.account, user_info.ip, user_info.mcc))    
    return ret
end

return core_money