local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert
local tsort = table.sort

local kc = require "kyotocabinet"
local db = kc.DB:new()
local flag_msg = "msg"
local cur_subid = 0
local gTianJi_Msg = {
    msg = {},
    len = 0,
}   

local function close_db()
    db:close()
    cur_subid = 0
end

local function load_db(subid)
    local filename = 'tianji_msg_'..subid..'.kch'
    if cur_subid ~= 0 then
        close_db(cur_subid)
    end
    if not db:open(filename, kc.DB.OWRITER + kc.DB.OCREATE) then
        LOG_ERROR(filename.." open err")
    else
        db:iterate(
            function(k,v)
                if k == flag_msg then
                    local pb = require "protobuf"
                    local d = pb.decode("TianJiMsg", v)
                    gTianJi_Msg = d
                    --print("tianjimsg|", k, gTianJi_Msg.msg, gTianJi_Msg.len)
                end
            end, false
        )
        cur_subid = subid
    end
end

local tianji_msg = {}

function tianji_msg.add_new_msg(main_data, subid, item)
    if cur_subid ~= subid then
        load_db(subid)
    end
    local new_msg = {
        nickname = main_data.nickname,
        special_item = item,
    }

    LOG_INFO("tianjimsg|add ".. main_data.user_name.." "..new_msg.special_item.id.." "..new_msg.special_item.num)
    local needremove = true
    if gTianJi_Msg.len < 6 then needremove = false end
    if not needremove then
        table.insert(gTianJi_Msg.msg, new_msg)
        gTianJi_Msg.len = gTianJi_Msg.len + 1
    else
        table.remove(gTianJi_Msg.msg, 1)
        table.insert(gTianJi_Msg.msg, new_msg)        
    end
    
    local pb = require "protobuf"
    local d = pb.encode("TianJiMsg", gTianJi_Msg)
    db:set(flag_msg, d)

    return gTianJi_Msg.msg
end

function tianji_msg.get_all_msg(subid)
    if cur_subid ~= subid then
        load_db(subid)
    end

    return gTianJi_Msg.msg
end

function tianji_msg.do_timer()
    local subid = 0
    local data = global_huodong.get_huodong(nil, "tianji")
    if data then
        subid = data.sub_id
    end
    if subid ~= cur_subid then
        close_db(cur_subid)
    end
end

return tianji_msg