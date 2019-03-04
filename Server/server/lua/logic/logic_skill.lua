local Skill_Expend_conf = Skill_Expend_conf

local core_user = require "core_user_funcs"
local core_task = require "core_task"

local LogicSkill = {}

function LogicSkill.level_up(skill, add_level, max_level, main_data, task_struct)
    -- 技能和侠客等级必须相等
    assert(skill.id ~= 0)
    assert(add_level > 0)
    local old_level = skill.level
    local enable_auto = core_vip.skill_auto(main_data)
    if enable_auto == 0 then assert(add_level == 1) end
    assert((old_level + add_level) <= max_level)
    
    
    for k = old_level, old_level + add_level - 1 do
        local expend = Skill_Expend_conf[k].NEXT_LEVEL
        assert(expend > 0)
        core_user.expend_gold(expend, {main_data = main_data}, nil, 70)
    end
    skill.level = old_level + add_level
    --检测活跃
    core_task.check_daily_skill_levelup(task_struct, main_data, add_level)
    core_task.check_newtask_by_event(main_data, 2, add_level)
end

return LogicSkill