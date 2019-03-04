local core_user = require "core_user_funcs"
local logic_skill = require "logic_skill"
local logic_knight = require "logic_knight"

function skill_levelup_feature(step, req, user_name)
    if step == 0 then
        local pb = require "protobuf"
		local resp = {
            result = "FAIL",
        }
        return 1, pb.encode("SkillLevelUpResp", resp)
    elseif step == 1 then
        return datablock.main_data + datablock.knight_bag + datablock.save, user_name
    else
        LOG_ERR("something error");
        return nil,nil
    end
end

function skill_levelup_do_logic(req_buf, user_name, main_data_buf, knight_bag_buf)
    local pb = require "protobuf"
    local req = pb.decode("SkillLevelUpReq", req_buf)
    local main_data = pb.decode("UserInfo", main_data_buf)
    local knight_bag = pb.decode("KnightList", knight_bag_buf)
    if rawget(knight_bag, "knight_list") == nil then knight_bag = {knight_list = {}} end
    local guid = req.guid
    local level = 0
    local skill = nil
    if guid == -1 then
        skill = main_data.lead.skill
        level = main_data.lead.level
    else
        local t = core_user.get_knight_by_guid(guid, main_data, knight_bag.knight_list)
        assert(t)
        assert(t[2])
        core_user.init_knight(t[2])
        skill = t[2].data.skill
        level = t[2].data.level
    end
    assert(skill)
    local task_struct = {ret = false, data = {task = 0, chengjiu = 0, huoyue = 0,task_list = nil, chengjiu_list = nil, daily_list = nil}}
    logic_skill.level_up(skill, req.add_level, level, main_data, task_struct)
    local ext_cmd = nil
    local ext_buf = nil
    if task_struct.ret then
        ext_buf = pb.encode("TaskRefleshResp", task_struct.data)
        ext_cmd = 0x1035
    end
    if req.add_new_player > 0 then
        local t = main_data.ext_data.new_player
        main_data.ext_data.new_player = req.add_new_player;
    end
    local resp = {
        result = "OK",
        skill = skill,
        req = req,
		rsync = {
		    gold = main_data.gold,
		},
		add_new_player = core_user.set_anp_skill_level(main_data)
    }
    local resp_buf = pb.encode("SkillLevelUpResp", resp)
    local main_data_buf = pb.encode("UserInfo", main_data)
    local knight_bag_buf = pb.encode("KnightList", knight_bag)
    return resp_buf, main_data_buf, knight_bag_buf,ext_cmd, ext_buf
end