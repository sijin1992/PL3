local Equipment_Upgrade_conf = Equipment_Upgrade_conf
local Equipment_Star_conf = Equipment_Star_conf

local core_user = require "core_user_funcs"
local core_power = require "core_calc_power"
local core_task = require "core_task"

local LogicEquip = {}
local rank = rank
function LogicEquip.level_up(equip, id, add_level, main_data, username, item_list, task_struct)
    -- 开启条件
    local lev = main_data.lead.level
    local enable_1key = core_vip.equip_level_1key(main_data)
    if enable_1key == 0 then assert(add_level == 1) end
    -- 最多比玩家等级高5级
    local max_level = lev + 5
    assert(add_level > 0)
    local old_level = equip.level
    assert(old_level + add_level <= max_level)
    local idx = 130000000 + id * 10000 + equip.level
    local expend = 0
    local iron = 0
    for k = 1, add_level do
        local data = Equipment_Upgrade_conf[idx]
        assert(data)
        assert(data.EXPEND_ID ~= 0)
        expend = expend + data.EXPEND_ID
        iron = iron + data.NEXT_IRON
        idx = idx + 1
    end
    
    -- 检查资源够不够
    local used_item_list = {}
    core_user.expend_item(191010001, expend, main_data, 30, nil, used_item_list)
    if iron > 0 then
        core_user.expend_item(193010004, iron, main_data, 30, item_list, used_item_list)
    end
    equip.level = old_level + add_level
    -- 刷新战斗力
    core_power.reflesh_knight_power(main_data, nil, 0, core_power.create_modify_power(rank.modify_power, username))
    core_task.check_chengjiu_equip_levelup(task_struct, main_data)
    core_task.check_chengjiu_equip_levelset(task_struct, main_data)
    
    local rsync = {
        gold = main_data.gold,
        item_list = used_item_list,
    }
    core_task.check_newtask_by_event(main_data, 6)
    --LOG_EXT(string.format("EQUIP L:%s|%d  %d--->%d)",
            --main_data.user_name, id, old_level, old_level + add_level))
    return rsync
end

function LogicEquip.star_up(equip, id, main_data, item_list, username, task_struct)
    local old_star = equip.star
    local idx = 140000000 + id * 10000 + old_star
    local data = Equipment_Star_conf[idx]
    assert(data)
    local expend = data.EXPEND_ID
    assert(expend[1] ~= 0)
    -- 检查资源够不够
    local k = 1
    local ret_struct = {}
    while expend[k] do
        core_user.expend_item(expend[k], expend[k + 1], main_data, 31, item_list, ret_struct)
        k = k + 2
    end
    equip.star = old_star + 1
    -- 刷新战斗力
    core_power.reflesh_knight_power(main_data, nil, 0, core_power.create_modify_power(rank.modify_power, username))
    -- 检测成就
    core_task.check_chengjiu_equip_starup(task_struct, main_data)
    core_task.check_chengjiu_equip_starset(task_struct, main_data)
    local rsync = {
        gold = main_data.gold,
        item_list = ret_struct,
        --chengjiu_list = chengjiu_list,
    }
    --LOG_EXT(string.format("EQUIP E:%s|%d  %d--->%d)",
            --main_data.user_name, id, old_star, old_star + 1))
    return rsync
end

return LogicEquip