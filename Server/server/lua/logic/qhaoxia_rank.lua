local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert
local tsort = table.sort

local kc = require "kyotocabinet"
local db = kc.DB:new()
local flag_rank = "rank"
local cur_subid = 0
local gQHaoXia_Rank = {
    rank = {},
    len = 0,
}   

local function close_db(subid)
    local rank_reward = {}
    for k,v  in ipairs(QiangHX_PaiMing_Reward_conf.index) do
        local conf = QiangHX_PaiMing_Reward_conf[v]
        if conf.Activity_ID == 680010000 + subid then
            local item_list = {}
            local t = 1
            while conf.Reward[t] do
                table.insert(item_list, {id = conf.Reward[t], num = conf.Reward[t + 1]})
                t = t + 2
            end

            table.insert(rank_reward, {item_list = item_list, top = conf.Rank_Top, bottom = conf.Rank_Bottom})
        end
    end

    for i = 1, 20 do
        local d = gQHaoXia_Rank.rank[i]
        if not d then break end
        local item_list = nil
        for k,v in ipairs(rank_reward) do
            if i >= v.bottom and i <= v.top then
                item_list = v.item_list
                break
            end
        end

        if not item_list then
            LOG_ERROR(string.format("qhaoxia_rank|%d|%s|%d item_list nil", subid,d.user_name,i))
            item_list = {}
        end

        local mail = {
            type = 10,
            from = "",
            subject = lang.qhaoxia_mail_title,
            message = string.format(lang.qhaoxia_mail_msg, d.point, i),
            stamp = os.time(),
            expiry_stamp = os.time() + 604800,
            item_list = item_list,
            guid = 0,
        }

        if d.getreward ~= 1 then
            redo_list.add_mail(d.user_name, mail)
            LOG_INFO(string.format("qhaoxia_rank|%d|%s|%d", subid,d.user_name,i))
            d.getreward = 1
        end
    end
    db:close()
    cur_subid = 0
end

local function load_db(subid)
    local filename = 'qhaoxia_rank_'..subid..'.kch'
    if cur_subid ~= 0 then
        close_db(cur_subid)
    end
    if not db:open(filename, kc.DB.OWRITER + kc.DB.OCREATE) then
        LOG_ERROR(filename.." open err")
    else
        db:iterate(
            function(k,v)
                if k == flag_rank then
                    local pb = require "protobuf"
                    local d = pb.decode("QHaoXiaRank_kch", v)
                    gQHaoXia_Rank = d
                    --print("tianjimsg|", k, gQHaoXia_Rank.msg, gQHaoXia_Rank.len)
                end
            end, false
        )
        cur_subid = subid
    end
end

local qhaoxia_rank = {}

function qhaoxia_rank.add_new_rank(main_data, subid, point)
    if cur_subid ~= subid then
        load_db(subid)
    end

    local new_rank = {
        user_name = main_data.user_name,
        nick_name = main_data.nickname,
        point = point,
        timestamp = os.time(),
    }
    if point < 500 then 
        return gQHaoXia_Rank.rank
    end
    function comps(a,b)
        if a.point ~= b.point then
            return a.point > b.point
        else
            return a.timestamp < b.timestamp
        end
    end
    
    local found = false
    for k,v in ipairs(gQHaoXia_Rank.rank) do
        if v.user_name == main_data.user_name then
            found = true
            if point > v.point then
                v.point = point
            end
            break
        end
    end

    if found then
        table.sort(gQHaoXia_Rank.rank, comps)
        --printtab(gQHaoXia_Rank.rank, "in rank")
    elseif gQHaoXia_Rank.len < 20 then 
        table.insert(gQHaoXia_Rank.rank, new_rank)
        table.sort(gQHaoXia_Rank.rank, comps)
        gQHaoXia_Rank.len = #gQHaoXia_Rank.rank
        --printtab(gQHaoXia_Rank.rank, "<20")
    else
        if point <= gQHaoXia_Rank.rank[gQHaoXia_Rank.len].point then
            return gQHaoXia_Rank.rank
        else
            table.remove(gQHaoXia_Rank.rank, gQHaoXia_Rank.len)
            table.insert(gQHaoXia_Rank.rank, new_rank)
            table.sort(gQHaoXia_Rank.rank, comps)
            gQHaoXia_Rank.len = #gQHaoXia_Rank.rank
            --printtab(gQHaoXia_Rank.rank, "=20")
        end
    end

    local pb = require "protobuf"
    local d = pb.encode("QHaoXiaRank_kch", gQHaoXia_Rank)
    db:set(flag_rank, d)

    return gQHaoXia_Rank.rank
end

function qhaoxia_rank.get_rank(subid)
    if cur_subid ~= subid then
        load_db(subid)
    end

    return gQHaoXia_Rank.rank
end

function qhaoxia_rank.do_timer()
    local subid = 0
    local data = global_huodong.get_huodong(nil, "qhaoxia")
    if data then
        subid = data.sub_id
    end
    if subid ~= cur_subid then
        close_db(cur_subid)
    end
end

return qhaoxia_rank