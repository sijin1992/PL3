local core_fight = require "fight"
local core_task = require "core_task"
local pvp_rcd = pvp_rcd
local rank = rank

local core_user = require "core_user_funcs"
local core_money = require "core_money"
local core_drop = require "core_drop"
local core_mail = require "core_send_mail"

local PVP_Shop_conf = PVP_Shop_conf

local PVP = {}

function PVP.do_pvp(user_data1, knight_list1, mail_list1, user_data2, knight_list2, self_name, req, task_struct, robot, notify_struct)
    -- 开启条件
    local lev = user_data1.lead.level
    assert(user_data1.lead.level >= Open_conf[1].OPEN_PARA, "lead.level:"..user_data1.lead.level.."<12")
    
    local today_count = user_data1.PVP.today_count
    local total_count = user_data1.PVP.total_count
    local total_win = user_data1.PVP.total_win
    user_data1.PVP.total_count = total_count + 1
    if not robot then
        local total_count1 = user_data2.PVP.total_count
        user_data2.PVP.total_count = total_count1 + 1
    end
    assert(today_count < 5, "today_count:"..today_count.." >= 5" )
    user_data1.PVP.today_count = today_count + 1
    local tag_idx = req.target.idx
    local tag_name = req.target.entry.name
    
    local tag_entry = rawget(rank.rank_list_id,tag_idx)
    local tag_entry1 = rawget(rank.rank_list_name, tag_name)
    -- 必须保证对手排名没变更
    if tag_entry.name ~= tag_name or tag_entry1.idx ~= tag_idx then
        return nil, nil, nil, nil, nil, 1
    end
    
    local delta_rank = 0
    
    local tt, old_self = rank.get_self(self_name, user_data1)
    
    local fight = core_fight:new()
    local rcd = fight.rcd
    local preview = rcd.preview
    fight:get_player_data(user_data1, knight_list1)
    fight:get_player_data(user_data2, knight_list2, true)
    fight:get_attrib()
    -- 这里必须先获取原始preview，排序之后顺序就乱了
    fight:get_preview_role_list()    
    fight:play(rcd)

    local winner = fight.winner
    local new_target = nil
    local new_self = nil
    local new_rank_idx = nil
    if winner == 1 then
        if tag_idx == 1 then
            notify_struct.ret = true
            notify_struct.data = notify_sys.add_message(user_data1.user_name, user_data1.nickname, 4)
        end
        new_self, delta_rank = rank.change_rank(tag_idx, self_name, user_data1)
        new_target = rank.get_target(self_name, user_data1)
        new_rank_idx = new_self.idx
        local highest_rank = user_data1.PVP.highest_rank
        if new_rank_idx < highest_rank or highest_rank == 0 then
            user_data1.PVP.highest_rank = new_rank_idx
            core_mail.send_pvp_rank_reward_mail(highest_rank, new_rank_idx, user_data1, mail_list1)
        end
        LOG_INFO(string.format("PVP W:%s|%d", self_name, new_rank_idx))
    else
        local t
        t, new_self = rank.get_self(self_name, user_data1)
        --LOG_EXT(string.format("PVP L:%s|%d)",
            --self_name, new_self.idx))
    end
    -- 处理战斗录像
    local time = os.time()
    local p1 = {nickname = user_data1.nickname,
                sex = user_data1.lead.sex,
                star = user_data1.lead.star,
                level = user_data1.lead.level,
                power = user_data1.power}
    local p2 = {nickname = user_data2.nickname,
                sex = user_data2.lead.sex,
                star = user_data2.lead.star,
                level = user_data2.lead.level,
                power = user_data2.power}
    if robot then p2.power = user_data2.power10 end
    local rcd_entry1 = {
        rcd_idx = 0,
        player_list = {p1, p2},
        is_win = rcd.preview.winner,
        stamp = time,
        is_left = 1,
        delta_rank = delta_rank
        }
    local rcd_entry2 = {
        rcd_idx = 0,
        player_list = {p1, p2},
        is_win = rcd.preview.winner,
        stamp = time,
        is_left = 2,
        delta_rank = -delta_rank
        }
    local pb = require "protobuf"
    local rcd_buf = pb.encode("FightRcd", rcd)
    --挑战者
    local self_pvp = user_data1.PVP
    local self_rcd_list = self_pvp.pvp_rcd_list
    self_rcd_list = rawget(self_pvp, "pvp_rcd_list")
    if self_rcd_list == nil then
        self_rcd_list = {}
        rawset(self_pvp, "pvp_rcd_list", self_rcd_list)
    end
    local new_idx = nil
    if #self_rcd_list < 10 then
        new_idx = pvp_rcd.add_rcd(rcd_buf, -1)
    else
        new_idx = pvp_rcd.add_rcd(rcd_buf, self_rcd_list[1].rcd_idx)
        table.remove(self_rcd_list,1)
    end
    rcd_entry1.rcd_idx = new_idx
    table.insert(self_rcd_list,rcd_entry1)
    --被挑战者
    if not robot then
        self_pvp = user_data2.PVP
        self_rcd_list = self_pvp.pvp_rcd_list
        self_rcd_list = rawget(self_pvp, "pvp_rcd_list")
        if self_rcd_list == nil then
            self_rcd_list = {}
            rawset(self_pvp, "pvp_rcd_list", self_rcd_list)
        end
        if #self_rcd_list < 10 then
            new_idx = pvp_rcd.add_rcd(rcd_buf, -1)
        else
            new_idx = pvp_rcd.add_rcd(rcd_buf, self_rcd_list[1].rcd_idx)
            table.remove(self_rcd_list,1)
        end
        rcd_entry2.rcd_idx = new_idx
        table.insert(self_rcd_list,rcd_entry2)
    end
    
    local get_reputation = 0
    local get_pvp_gold = 0
    if winner == 1 then
        user_data1.PVP.total_win = total_win + 1
        get_reputation = 10
        core_user.get_item(191040210, get_reputation, user_data1, 110)
        -- 检测成就
        core_task.check_chengjiu_title(task_struct, user_data1)
        core_task.check_chengjiu_pvp_count(task_struct, user_data1)
        core_task.check_chengjiu_shengwang(task_struct, user_data1)
        -- 检测开服任务
        core_task.check_newtask_by_event(user_data1, 7)
        --user_data1.PVP.pvp_gold = user_data1.PVP.pvp_gold + get_pvp_gold
    else
        if not robot then
            local t = user_data2.PVP.today_count
            --user_data2.PVP.today_count = t + 1
            user_data2.PVP.total_win = user_data2.PVP.total_win + 1
        end
    end
    
    core_task.check_daily_pvp(task_struct, user_data1)
    local rsync = {
        get_reputation = get_reputation,
        get_pvp_gold = get_pvp_gold,
        now_reputation = user_data1.PVP.reputation,
        now_pvp_gold = user_data1.PVP.pvp_gold,
    }
    
    return rcd, new_target, new_self, rsync, winner, nil, old_self
end

function PVP.reflesh_shop(main_data, item_list, free)
    -- 开启条件
    local lev = main_data.lead.level
    assert(lev >= Open_conf[2].OPEN_PARA)
    
    local rsync = {item_list = {}, cur_money = main_data.money}
    if free ~= 1 then
        local ret = core_user.expend_sxl(1, {main_data = main_data, item_list = item_list}, rsync.item_list, 107)
        if ret == -1 then
            core_money.use_money(20, main_data, 0, 107)
            rsync.cur_money = main_data.money
        end
    end
    local shop_list = nil
    local pvp_info = main_data.PVP
    local t = pvp_info.reputation
    shop_list = rawget(pvp_info, "shopping_list")
    if free ~= 1 then
        shop_list = core_user.reflesh_shopping_list(100014)
        pvp_info.shopping_list = shop_list
    end

    return shop_list, rsync
end

function PVP.shopping(user_info, item_list, idx)
    -- 开启条件
    local lev = user_info.lead.level
    assert(user_info.lead.level >= Open_conf[2].OPEN_PARA)
    
    local pvp = user_info.PVP
    local shopping_list = pvp.shopping_list
    local item = rawget(shopping_list, idx)
    assert(item, "item not exist")
    assert(item.num > 0, "item num is 0")
    local cost = item.price * item.num
    
    core_user.expend_item(191010056, cost, user_info, 111)

    local ret_struct = {
        item_list = {},
        cost = cost,
        token = pvp.pvp_gold
    }
    local item_id = item.id
    if item.id > 10000000 and item.id < 20000000 then item_id = 193010007 end
    core_user.get_item(item_id, item.num, user_info, 111, nil, item_list, ret_struct, nil)
    item.num = 0
    return ret_struct
end

function PVP.money2chance(user_data, task_struct)
    local total_m2c_num = user_data.ext_data.total_m2c_num
    local today_reset_count = user_data.PVP.today_reset_count
    local max_num = core_vip.money2chance(user_data)
    assert(today_reset_count < max_num, "no more chance")
    user_data.ext_data.total_m2c_num = total_m2c_num + 1
    user_data.PVP.today_reset_count = today_reset_count + 1
    core_money.use_money(50, user_data, 0, 108)
    local today_count = user_data.PVP.today_count
    user_data.PVP.today_count = 0
    -- 检测成就。这个成就已经取消
    --core_task.check_chengjiu_total_m2c(task_struct, user_data)
    local ret = {money = user_data.money}
    return ret
end

function PVP.get_wlzb_reward(main_data, item_list, reward_id)
    local t = main_data.PVP.reputation
    local wlzb_info = rawget(main_data.PVP, "wlzb")
    assert(wlzb_info, "has no wlzb info")
    
    local real_reward_id = wlzb.get_real_reward(wlzb_info, reward_id)
    assert(wlzb_info.pk_list[reward_id].reward == 0)
    wlzb_info.pk_list[reward_id].reward = 1
    local conf = War_conf[real_reward_id]
    local reward_tab = conf.Reward
    local ret_struct = {
        item_list = {},
        cur_gold = 0,
        cur_money = 0,
    }
    local k = 1
    while reward_tab[k] do
        core_user.get_item(reward_tab[k], reward_tab[k+1], main_data, 120, nil, item_list, ret_struct)
        k = k + 2
    end
    ret_struct.cur_gold = main_data.gold
    ret_struct.cur_money = main_data.money
    return ret_struct, wlzb_info
end

function PVP.get_wlzb_fight(main_data)
    local ret, wlzb_info = wlzb.get_self_pk_list(main_data.user_name, main_data)
    local first8 = wlzb.get_8_list()
    local round_num = wlzb.get_round_num()
    return ret, first8, round_num, wlzb_info
end

return PVP