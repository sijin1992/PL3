local core_vip = {}

local function get_vip_conf(main_data)
    local vip = main_data.vip_lev
    local conf = VIP_conf[vip]
    assert(conf, "vip conf not find")
    return conf
end

function core_vip.money2hp_num(main_data)
    local conf = get_vip_conf(main_data)
    return conf.STA_TIMES
end

function core_vip.money2gold_num(main_data)
    local conf = get_vip_conf(main_data)
    return conf.BUYCOIN_TIMES
end

function core_vip.money2gold_rate(main_data)
    local conf = get_vip_conf(main_data)
    return conf.BUYCOIN_FACTOR
end

function core_vip.money2gold_crit(main_data)
    local conf = get_vip_conf(main_data)
    return conf.BUYCOIN_CRIT
end

function core_vip.equip_level_1key(main_data)
    local conf = get_vip_conf(main_data)
    return conf.EQ_AUTO
end

function core_vip.pve_clear10(main_data)
    local conf = get_vip_conf(main_data)
    return conf.WIPE_TEN
end

function core_vip.skill_auto(main_data)
    local conf = get_vip_conf(main_data)
    return conf.SKIL_AUTO
end

function core_vip.money2chance(main_data)
    local conf = get_vip_conf(main_data)
    return conf.PVP_TIMES
end

function core_vip.jingying_reset(main_data)
    local conf = get_vip_conf(main_data)
    return conf.ELITE_TIMES
end

function core_vip.pve2_reset(main_data)
    local conf = get_vip_conf(main_data)
    return conf.DISPUTE_TIMES
end

function core_vip.pve2_gold_rate(main_data)
    local conf = get_vip_conf(main_data)
    return conf.DISPUTE_COIN
end

local vip_goods = {}
local vip_version = 0
for k,v in ipairs(VIP_Shop_conf.index) do
    local conf = VIP_Shop_conf[v]
    if conf.Grid_ID >= 10000 then vip_version = conf.Grid_ID
    else
        local item = {id = conf.Good_Item[1], num = conf.Good_Item[2]}
        table.insert(vip_goods, {goods = {item = item, cost = conf.Price}, vip_level = conf.VIP_Limit,
            buy_limit = conf.Buy_Limit})
    end
end
core_vip.vip_goods = vip_goods

local vip_gift = {}
local vip_gift_version = 0
for k,v in ipairs(VIP_GIFT_conf.index) do
    local conf = VIP_GIFT_conf[v]
    if conf.Grid_ID >= 10000 then vip_gift_version = conf.Grid_ID
    else
        local item_list = {}
        local k = 1
        while conf.Good_Item[k] do
            local item = {id = conf.Good_Item[k], num = conf.Good_Item[k+1]}
            table.insert(item_list, item)
            k = k + 2
        end
        table.insert(vip_gift, {item_list = item_list, vip_level = conf.VIP_Limit,
            buy_num = 1, price = conf.Price})
    end
end
core_vip.vip_gift = vip_gift

function core_vip.reflesh_vip_goods_list(main_data)
    local ret = false
    local vip_goods_list = rawget(main_data, "vip_shoplist")
    local create_new = false
    if not vip_goods_list then
        create_new = true
    else
        local old_ver = vip_goods_list.ver
        if old_ver ~= vip_version then
            ret = true
            if math.floor(vip_version / 10000) ~= math.floor(old_ver/10000) then
                create_new = true
            else
                for k,v in ipairs(vip_goods_list.goods_list) do
                    v.buy_limit = vip_goods[k].buy_limit
                end
                vip_goods_list.ver = vip_version
            end
        end
    end
    if create_new then
        local t_list = {}
        for k,v in ipairs(vip_goods) do
            table.insert(t_list, {goods = v.goods, vip_level = v.vip_level, buy_limit = v.buy_limit, buy_num = 0})
        end
        vip_goods_list = {
            ver = vip_version,
            goods_list = t_list,
        }
        rawset(main_data, "vip_shoplist", vip_goods_list)
        ret = true
    end
    return ret
end

function core_vip.reflesh_vip_gift_list(main_data)
    local ret = false
    local vip_gift = rawget(main_data, "vip_gift")
    local create_new = false
    if not vip_gift then
        create_new = true
    else
        local old_ver = vip_gift.ver
        if old_ver ~= vip_gift_version then
            ret = true
            if math.floor(vip_gift_version / 10000) ~= math.floor(old_ver/10000) then
                create_new = true
            else
                for k,v in ipairs(vip_gift.gift_list) do
                    v.buy_num = 1
                end
                vip_gift.ver = vip_gift_version
            end
        end
    end
    if create_new then
        local t_list = clonetab(core_vip.vip_gift)
        vip_gift = {
            ver = vip_gift_version,
            gift_list = t_list,
        }
        rawset(main_data, "vip_gift", vip_gift)
        ret = true
    end
    return ret
end

return core_vip