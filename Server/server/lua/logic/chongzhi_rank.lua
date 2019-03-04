local mrandom = math.random
local mfloor = math.floor
local tinsert = table.insert
local tsort = table.sort

local cur_subid = 0
local rank_list = {}        -- 排名数组
local player_list = {}      -- 名字列表

local MIN_SCORE = 500

if server_platform == 1 then
	MIN_SCORE = 100
end

local kc = require "kyotocabinet"
local db = kc.DB:new()

local function sort_func(a, b)
    if a.score == b.score then
        return a.timestamp < b.timestamp
    end
    return a.score > b.score
end

local reward_list = {}
for k = 1,10 do
    for k1 = Activity_Jifen_conf.len, 1, -1 do
        local conf = Activity_Jifen_conf[k1]
        if k == conf.RANK then
            local k2 = 1
            local item_list = {}
            while conf.REWARD[k2] do
                table.insert(item_list, {id = conf.REWARD[k2], num = conf.REWARD[k2 + 1]})
                k2 = k2 + 2
            end
            tinsert(reward_list, item_list)
            break
        elseif k > conf.RANK then
            tinsert(reward_list, reward_list[conf.RANK])
            break
        end
    end
end

local function close_db(subid)
    for k = 1, 10 do
        local d = rank_list[k]
        if not d then break end
        local mail = {
            type = 10,
            from = "",
            subject = lang.cz_rank_mail_title,
            message = string.format(lang.cz_rank_mail_msg, d.score, k),
            stamp = os.time(),
            expiry_stamp = os.time() + 604800,
            item_list = reward_list[k],
            guid = 0,
        }
        redo_list.add_mail(d.username, mail)
        LOG_INFO(string.format("cz_rank|%d|%s|%d", subid,d.username,k))
    end
    db:close()
    cur_subid = 0
    rank_list = {}
    player_list = {}
end

local function load_one_db(subid)
    local filename = 'cz_rank' .. subid .. '.kch'
    if cur_subid ~= 0 then
        close_db(cur_subid)
    end
    if not db:open(filename, kc.DB.OWRITER + kc.DB.OCREATE) then
        LOG_ERROR(filename.." open err")
    else
        db:iterate(
            function(k,v)
                local pb = require "protobuf"
                local d = pb.decode("ChongzhiHongbaoEntry", v)
                rawset(player_list, k, d)
                if d.score >= MIN_SCORE then
                    tinsert(rank_list, d)
                end
            end, false
        )
        tsort(rank_list, sort_func)
        cur_subid = subid
    end
end

local cz_rank = {}

function cz_rank.add_value(main_data, subid, value)
    if cur_subid ~= subid then
        load_one_db(subid)
    end
    
    local data = rawget(player_list, main_data.user_name)
    local old_score = 0
    local new_score = value
    if not data then
        data = {
            username = main_data.user_name,
            nickname = main_data.nickname,
            score = value,
            timestamp = os.time()
        }
        rawset(player_list, main_data.user_name, data)
    else
        old_score = data.score
        new_score = old_score + value
        data.score = new_score
        data.timestamp = os.time()
    end
    if old_score < MIN_SCORE and new_score >= MIN_SCORE then
        tinsert(rank_list, data)
    end
    tsort(rank_list, sort_func)
    local pb = require "protobuf"
    local d = pb.encode("ChongzhiHongbaoEntry", data)
    db:set(main_data.user_name, d)
end

function cz_rank.get_topn(user_name, subid)
    if cur_subid ~= subid then
        load_one_db(subid)
    end
    local self = rawget(player_list, user_name)
    local self_rank = -1
    local top10 = {}
    for k = 1, 10 do
        local t = rank_list[k]
        if not t then break end
        if t.username == user_name then self_rank = k end
        tinsert(top10, t)
    end
    -- 如果自己已达上榜条件但没到前10，则固定为0，否则为1-10的有效数字
    if self and self_rank == -1 then
        if self.score >= MIN_SCORE then
            self_rank = 0
        end
    end
    return top10, self, self_rank
end

--正常10秒刷新时会检测活动是否失效。另外如果没到时间，但是有充值等活动，也会提前刷新
function cz_rank.do_timer()
    local subid = 0
    local data = global_huodong.get_huodong(nil, "cz_rank")
    if data then
        subid = data.sub_id
    end
    if subid ~= cur_subid then
        close_db(cur_subid)
    end
end

return cz_rank
