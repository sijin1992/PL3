local kc = require "kyotocabinet"
local db = kc.DB:new()

local redo_list = {}

if not db:open("redo_list.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
    error("redo_list.lua open err")
else
    db:iterate(
        function(k,v)
            local pb = require "protobuf"
            local t = pb.decode("redo_entry", v)
            rawset(redo_list, k, t)
        end, false
    )
end

local function add_recharge(uid, money, item_id, fake, selfdef, gamemoney, basemoney, monthcard)
    local entry = rawget(redo_list, uid)
    if not entry then
        entry = {uid = uid, recharge_list = {}}
        rawset(redo_list, uid, entry)
    end
    local t = entry.recharge_list[1]
    local recharge_list = rawget(entry, "recharge_list")
    if not recharge_list then
        recharge_list = {}
        rawset(entry, "recharge_list", recharge_list)
    end
    table.insert(recharge_list, {money = money, item_id = item_id, fake = fake,
		selfdef = selfdef, gamemoney = gamemoney, basemoney = basemoney, monthcard = monthcard})
    
    local pb = require "protobuf"
    t = pb.encode("redo_entry", entry)
    db:set(uid, t)
end

local function add_mail_buf(uid, mail_buf)
    local entry = rawget(redo_list, uid)
    if not entry then
        entry = {uid = uid, recharge_list = {}, remail_list = {}}
        rawset(redo_list, uid, entry)
    else
        local t = entry.remail_list
        if rawget(entry, "remail_list") == nil then
            entry.remail_list = {}
        end
    end
    local t = entry.remail_list[1]
    local remail_list = rawget(entry, "remail_list")
    if not remail_list then
        remail_list = {}
        rawset(entry, "remail_list", remail_list)
    end
    local pb = require "protobuf"
    local mail_req = pb.decode("DBSendMailReq", mail_buf)
    local t_mail = {
        type = mail_req.type,
        from = mail_req.from,
        subject = mail_req.subject,
        message = mail_req.message,
        item_list = mail_req.item_list,
        stamp = mail_req.time,
        guid = 0,
        expiry_stamp = 0,
    }
    table.insert(remail_list, t_mail)
    local pb = require "protobuf"
    t = pb.encode("redo_entry", entry)
    db:set(uid, t)
end

local function add_mail(uid, mail)
    local entry = rawget(redo_list, uid)
    if not entry then
        entry = {uid = uid, recharge_list = {}, remail_list = {}}
        rawset(redo_list, uid, entry)
    else
        local t = entry.remail_list
        if rawget(entry, "remail_list") == nil then
            entry.remail_list = {}
        end
    end
    table.insert(entry.remail_list, mail)
    local pb = require "protobuf"
    local t = pb.encode("redo_entry", entry)
    db:set(uid, t)
end

local function get_redo_list(uid)
    local ret = rawget(redo_list, uid)
    if ret then
        local t = ret.recharge_list[1]
    end
    return ret
end

local function clear_redo_list(uid)
    rawset(redo_list, uid, nil)
    db:remove(uid)
end

local redo = {
    add_recharge = add_recharge,
    add_remail = add_mail_buf,
    add_mail = add_mail,
    get_redo_list = get_redo_list,
    clear_redo_list = clear_redo_list,
}

return redo