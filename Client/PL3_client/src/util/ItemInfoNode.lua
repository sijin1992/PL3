local player = require("app.Player"):getInstance()

local ItemInfoNode = class("ItemInfoNode")

function ItemInfoNode:ctor(node)
	self.node = node
    
end

function ItemInfoNode:createEquipNode(id, type, strength_num)

    local conf 
    if type == 10 then
        conf = CONF.EQUIP.get(id)
    elseif type == 9 then
        conf = CONF.GEM.get(id)
    end

    local node = require("app.ExResInterface"):getInstance():FastLoad("Common/EquipNode.csb")

    node:getChildByName("bg"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")

    if type == 10 then
        node:getChildByName("icon"):loadTexture("ItemIcon/"..conf.RES_ID..".png")
    elseif type == 9 then
        node:getChildByName("icon"):loadTexture("ItemIcon/"..conf.RES_ID..".png") 
    end

    node:getChildByName("lv_num"):setString(conf.LEVEL)

    node:getChildByName("name"):setString(CONF:getStringValue(conf.NAME_ID))

    if conf.QUALITY == 2 then
        node:getChildByName("name"):setTextColor(cc.c4b(33,255,70,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(33,255,70,255), cc.size(0.5,0.5))
    elseif conf.QUALITY == 3 then
        node:getChildByName("name"):setTextColor(cc.c4b(93,196,255,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(93,196,255,255), cc.size(0.5,0.5))
    elseif conf.QUALITY == 4 then
        node:getChildByName("name"):setTextColor(cc.c4b(236,79,255,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(236,79,255,255), cc.size(0.5,0.5))
    elseif conf.QUALITY == 5 then
        node:getChildByName("name"):setTextColor(cc.c4b(242,255,33,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(242,255,33,255), cc.size(0.5,0.5))
    end

    node:getChildByName("equip_type"):setString(CONF:getStringValue("type")..":")

    if type == 10 then
        node:getChildByName("type_name"):setString(CONF:getStringValue("Equip_type_"..conf.TYPE))
    elseif type == 9 then
        node:getChildByName("type_name"):setString(CONF:getStringValue("gem"))
    end

    node:getChildByName("type_name"):setPositionX(node:getChildByName("equip_type"):getPositionX() + node:getChildByName("equip_type"):getContentSize().width + 2)

    local x,y = node:getChildByName("node_pos"):getPosition()

    if type == 10 then
        for i,v in ipairs(conf.KEY) do
            local attr_node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ShipEquipNode.csb")

            attr_node:getChildByName("evolution"):removeFromParent()
            attr_node:getChildByName("up_num"):removeFromParent()

            attr_node:getChildByName("name"):setString(CONF:getStringValue("Attr_"..v))


            if strength_num == nil then
                strength_num = 0
            end

            local attr_num = math.floor(conf.ATTR[i] + strength_num*conf.ATTR[i]*CONF.PARAM.get("equip_strength").PARAM)
            attr_node:getChildByName("now_num"):setString("+"..attr_num)

            for k2,v2 in pairs(CONF.ShipPercentAttrs) do
                if v2 == v then
                    attr_node:getChildByName("now_num"):setString("+"..attr_num.."%")
                    break
                end
            end

            attr_node:getChildByName("now_num"):setPositionX(attr_node:getChildByName("name"):getPositionX() + attr_node:getChildByName("name"):getContentSize().width + 2)


            attr_node:setPosition(cc.p(x, y - (i-1)*32))

            node:addChild(attr_node)
            
        end
    elseif type == 9 then
        local attr_node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ShipEquipNode.csb")

        -- attr_node:getChildByName("flag_w_12_0"):removeFromParent()
        attr_node:getChildByName("evolution"):removeFromParent()
        attr_node:getChildByName("up_num"):removeFromParent()

        attr_node:getChildByName("name"):setString(CONF:getStringValue("Attr_"..conf.ATTR_KEY))
        attr_node:getChildByName("now_num"):setString("+"..conf.ATTR_VALUE)

        for k,v in pairs(CONF.ShipPercentAttrs) do
            if conf.ATTR_KEY == v then
                attr_node:getChildByName("now_num"):setString("+"..conf.ATTR_VALUE.."%")
                break
            end
        end

        attr_node:getChildByName("now_num"):setPositionX(attr_node:getChildByName("name"):getPositionX() + attr_node:getChildByName("name"):getContentSize().width + 2)


        attr_node:setPosition(cc.p(x, y))

        node:addChild(attr_node)
    end

    node:getChildByName("swallow"):setSwallowTouches(true)
    node:getChildByName("swallow"):addClickEventListener(function ( ... )
        node:removeFromParent()
    end)

	return node
end

function ItemInfoNode:createItemInfoNode(id, type)
    
    local conf = CONF.ITEM.get(id)

    local node = require("app.ExResInterface"):getInstance():FastLoad("Common/ItemInfoNode.csb")

    node:getChildByName("bg"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
    node:getChildByName("icon"):loadTexture("ItemIcon/"..conf.ICON_ID..".png")

    node:getChildByName("lv"):setString(CONF:getStringValue("type")..":")

    if type >= 1 and type <= 8 then
        node:getChildByName("lv_num"):setString(CONF:getStringValue("IN_"..type.."001"))
    elseif type == 11 then
        node:getChildByName("lv_num"):setString(CONF:getStringValue("IN_11001"))
    elseif type == 16 then
        node:getChildByName("lv_num"):setString(CONF:getStringValue("ship_bulepoint"))
    elseif type == 18 then
        node:getChildByName("lv_num"):setString(CONF:getStringValue("Airship"))
    else
        node:getChildByName("lv_num"):setString(CONF:getStringValue("prop"))
    end

    node:getChildByName("lv_num"):setPositionX(node:getChildByName("lv"):getPositionX() + node:getChildByName("lv"):getContentSize().width + 5)

    node:getChildByName("name"):setString(CONF:getStringValue(conf.NAME_ID))

    if conf.QUALITY == 2 then
        node:getChildByName("name"):setTextColor(cc.c4b(33,255,70,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(33,255,70,255), cc.size(0.5,0.5))
    elseif conf.QUALITY == 3 then
        node:getChildByName("name"):setTextColor(cc.c4b(93,196,255,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(93,196,255,255), cc.size(0.5,0.5))
    elseif conf.QUALITY == 4 then
        node:getChildByName("name"):setTextColor(cc.c4b(236,79,255,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(236,79,255,255), cc.size(0.5,0.5))
    elseif conf.QUALITY == 5 then
        node:getChildByName("name"):setTextColor(cc.c4b(242,255,33,255))
        -- node:getChildByName("name"):enableShadow(cc.c4b(242,255,33,255), cc.size(0.5,0.5))
    end
    local str = CONF:getStringValue(conf.MEMO_ID)
    str = string.gsub(str,"#",conf.VALUE)
    if conf.TYPE then
        if conf.TYPE == 16 then
            local strNum = CONF.AIRSHIP.get(conf.SHIPID).BLUEPRINT_NUM[1]
            local strName = CONF:getStringValue(CONF.AIRSHIP.get(conf.SHIPID).NAME_ID)
            str = string.gsub(string.gsub(CONF:getStringValue(conf.MEMO_ID),"%%d",strNum),"%%h",strName)
        elseif conf.TYPE == 12 then
            local reward_conf = CONF.REWARD.check(conf.KEY) and CONF.REWARD.check(conf.KEY)
            if reward_conf then
                for k,v in ipairs(reward_conf.ITEM) do
                    local item = CONF.ITEM.get(v)
                    if k ~= #reward_conf.ITEM then
                        str = str..CONF:getStringValue(item.NAME_ID).."*"..reward_conf.COUNT[k]..","
                    else
                        str = str..CONF:getStringValue(item.NAME_ID).."*"..reward_conf.COUNT[k]
                    end
                end
            end
        end
    end
    node:getChildByName('ins'):setString(str)
    node:getChildByName("swallow"):setSwallowTouches(true)
    node:getChildByName("swallow"):addClickEventListener(function ( ... )
        node:removeFromParent()
    end)
    node:getChildByName("ins"):setVisible(false)
    local contentLabel = cc.Label:createWithTTF("", "fonts/cuyabra.ttf", 20)
    contentLabel:setPosition(cc.p(node:getChildByName('ins'):getPosition()))
    contentLabel:setAnchorPoint(cc.p(node:getChildByName('ins'):getAnchorPoint()))
    contentLabel:setLineBreakWithoutSpace(true)
    contentLabel:setMaxLineWidth(node:getChildByName('ins'):getContentSize().width)
    contentLabel:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    contentLabel:setName("contentLabel")
    contentLabel:setTextColor(cc.c4b(255, 255, 255, 255))
    node:addChild(contentLabel)
    contentLabel:setString(str)

    local bigW = contentLabel:getContentSize().height - node:getChildByName("ins"):getContentSize().height
    if bigW > 0 then
        node:getChildByName("back"):setContentSize(cc.size(node:getChildByName("back"):getContentSize().width,node:getChildByName("back"):getContentSize().height+bigW))
    end

    return node
end

function ItemInfoNode:createShipInfoNode( id )
    local rn = require("app.ExResInterface"):getInstance():FastLoad("FormScene/FormShipInfo.csb")

    local conf = CONF.AIRSHIP.get(id)

    rn:getChildByName("Image_3"):loadTexture("ShipImage/"..conf.ICON_ID..".png")
    rn:getChildByName("ship_bg"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
--    rn:getChildByName("ship_icon"):loadTexture("RoleIcon/"..conf.ICON_ID..".png")
    rn:getChildByName("ship_icon"):setVisible(false)
    rn:getChildByName("ship_icon2"):setVisible(true)
    rn:getChildByName("ship_icon2"):setTexture("ShipImage/"..conf.DRIVER_ID..".png")
    rn:getChildByName("ship_name"):setString(CONF:getStringValue(conf.NAME_ID))
    rn:getChildByName("ship_fight_num"):setString(player:getEnemyPower(id))
    rn:getChildByName("quality"):setTexture("ShipQuality/quality_"..conf.QUALITY..".png")
    rn:getChildByName("ship_type"):loadTexture("ShipType/"..conf.TYPE..".png")
    rn:getChildByName("ship_lv_num"):removeFromParent()

    rn:getChildByName("ship_hp"):setString(CONF:getStringValue("Attr_2"))
    rn:getChildByName("ship_hp_num"):setString(conf.LIFE)
    rn:getChildByName("ship_atk"):setString(CONF:getStringValue("Attr_3"))
    rn:getChildByName("ship_atk_num"):setString(conf.ATTACK)
    rn:getChildByName("ship_def"):setString(CONF:getStringValue("Attr_4"))
    rn:getChildByName("ship_def_num"):setString(conf.DEFENCE)
    rn:getChildByName("ship_speed"):setString(CONF:getStringValue("Attr_5"))
    rn:getChildByName("ship_speed_num"):setString(conf.SPEED)
    rn:getChildByName("ship_e_atk"):setString(CONF:getStringValue("Attr_20"))
    rn:getChildByName("ship_e_atk_num"):setString(conf.ENERGY_ATTACK)
    rn:getChildByName("ship_dur"):setString(CONF:getStringValue("durable"))
    rn:getChildByName("ship_dur_num"):setString(conf.DURABLE)
    rn:getChildByName("ship_dur_max"):setString("/"..conf.DURABLE)

    local diff = 10
    rn:getChildByName("ship_hp_num"):setPositionX(rn:getChildByName("ship_hp"):getPositionX() + rn:getChildByName("ship_hp"):getContentSize().width + diff)
    rn:getChildByName("ship_atk_num"):setPositionX(rn:getChildByName("ship_atk"):getPositionX() + rn:getChildByName("ship_atk"):getContentSize().width + diff)
    rn:getChildByName("ship_def_num"):setPositionX(rn:getChildByName("ship_def"):getPositionX() + rn:getChildByName("ship_def"):getContentSize().width + diff)
    rn:getChildByName("ship_speed_num"):setPositionX(rn:getChildByName("ship_speed"):getPositionX() + rn:getChildByName("ship_speed"):getContentSize().width + diff)
    rn:getChildByName("ship_e_atk_num"):setPositionX(rn:getChildByName("ship_e_atk"):getPositionX() + rn:getChildByName("ship_e_atk"):getContentSize().width + diff)
    rn:getChildByName("ship_dur_num"):setPositionX(rn:getChildByName("ship_dur"):getPositionX() + rn:getChildByName("ship_dur"):getContentSize().width + diff)
    rn:getChildByName("ship_dur_max"):setPositionX(rn:getChildByName("ship_dur_num"):getPositionX() + rn:getChildByName("ship_dur_num"):getContentSize().width)

    rn:getChildByName("ship_upgrade"):removeFromParent()
    for i=1,6 do
        rn:getChildByName("star_"..i):removeFromParent()
    end

    self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"), cc.size(0,0), cc.size(386,480))

    local info_node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/FormShipInfoNode.csb")

    info_node:getChildByName("weapon_text"):setString(CONF:getStringValue("weapon"))
    info_node:getChildByName("equip_text"):setString(CONF:getStringValue("equip"))
    info_node:getChildByName("gem_text"):setString(CONF:getStringValue("gem"))

    --skill
    local skill_conf = CONF.WEAPON.get(conf.SKILL)
    info_node:getChildByName("skill_icon"):loadTexture("WeaponIcon/"..skill_conf.ICON_ID..".png")
    info_node:getChildByName("skill_name"):setString(CONF:getStringValue(skill_conf.NAME_ID))
    info_node:getChildByName("skill_ins"):setString("  "..setMemo(skill_conf, 4))

    for i=1,3 do
        info_node:getChildByName("weapon_bg_"..i):removeFromParent()
        info_node:getChildByName("weapon_icon_"..i):removeFromParent()
        info_node:getChildByName("weapon_name_"..i):removeFromParent()
        info_node:getChildByName("weapon_lv_"..i):removeFromParent()
        info_node:getChildByName("weapon_lv_num_"..i):removeFromParent()
        info_node:getChildByName("ui_brackets_weapon_"..i):removeFromParent()
    end

    info_node:getChildByName("ui_brackets_skill"):removeFromParent()
    info_node:getChildByName("weapon_text"):removeFromParent()
    info_node:getChildByName("weapon_line"):removeFromParent()

    local equip_ccs = {"equip_text", "equip_line", "ui_brackets_equip", "equip_item"}
    local gem_ccs = {"gem_text", "gem_line", "ui_brackets_gem", "gem_item"}

    for i,v in ipairs(equip_ccs) do
        info_node:getChildByName(v):removeFromParent()
    end

    for i,v in ipairs(gem_ccs) do
        info_node:getChildByName(v):removeFromParent()
    end

    self.svd_:addElement(info_node)

    rn:getChildByName("ok"):getChildByName("text"):setString(CONF:getStringValue("yes"))
    rn:getChildByName("ok"):addClickEventListener(function ( ... )
        rn:removeFromParent()

    end)

    rn:getChildByName("back"):setSwallowTouches(true)
    rn:getChildByName("back"):addClickEventListener(function ( ... )
        rn:removeFromParent()
    end)

    return rn
end

function ItemInfoNode:createShipInfoNodeByInfo(ship_info)

    local function createNode( ship_info )
        local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/FormShipInfoNode.csb")

        node:getChildByName("weapon_text"):setString(CONF:getStringValue("weapon"))
        node:getChildByName("equip_text"):setString(CONF:getStringValue("equip"))
        node:getChildByName("gem_text"):setString(CONF:getStringValue("gem"))

        local skill_conf = CONF.WEAPON.get(ship_info.skill)
        node:getChildByName("skill_icon"):loadTexture("WeaponIcon/"..skill_conf.ICON_ID..".png")
        node:getChildByName("skill_name"):setString(CONF:getStringValue(skill_conf.NAME_ID))
        -- rn:getChildByName("skill_ins"):setString("  "..setMemo(skill_conf, 4))

        local label = cc.Label:createWithTTF("  "..setMemo(skill_conf, 4), "fonts/cuyabra.ttf", 19)
        label:setAnchorPoint(cc.p(0,1))
        label:setPosition(cc.p(node:getChildByName("skill_ins"):getPosition()))
        label:setLineBreakWithoutSpace(true)
        label:setMaxLineWidth(300)
        label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        node:addChild(label)

        node:getChildByName("skill_ins"):removeFromParent()

        local weapon_ccs = {"ui_brackets_weapon_", "weapon_bg_", "weapon_icon_", "weapon_name_", "weapon_lv_", "weapon_lv_num_"}
        local equip_ccs = {"equip_text", "equip_line", "ui_brackets_equip", "equip_item"}
        local gem_ccs = {"gem_text", "gem_line", "ui_brackets_gem", "gem_item"}
        local hh = 86

        for i=1,3 do
            for i2,v2 in ipairs(weapon_ccs) do
                node:getChildByName(v2..i):setPositionY(node:getChildByName(v2..i):getPositionY() - (label:getContentSize().height - hh))
            end
        end

        for i,v in ipairs(equip_ccs) do
            node:getChildByName(v):setPositionY(node:getChildByName(v):getPositionY() - (label:getContentSize().height - hh))
        end

        for i,v in ipairs(gem_ccs) do
            node:getChildByName(v):setPositionY(node:getChildByName(v):getPositionY() - (label:getContentSize().height - hh))
        end
       
        local weapon_list = {}
        for i,v in ipairs(ship_info.weapon_list) do
            if v ~= 0 then
                table.insert(weapon_list, v)
            end
        end

        for i,v in ipairs(weapon_list) do
            if v ~= 0 then
                local weapon = player:getWeaponByID(v)
                local weapon_conf = CONF.WEAPON.get(weapon.weapon_id)
                node:getChildByName("weapon_icon_"..i):loadTexture("WeaponIcon/"..weapon_conf.ICON_ID..".png")
                node:getChildByName("weapon_name_"..i):setString(CONF:getStringValue(weapon_conf.NAME_ID))
                node:getChildByName("weapon_lv_num_"..i):setString(weapon_conf.LEVEL)

                node:getChildByName("weapon_lv_"..i):setPositionX(node:getChildByName("weapon_name_"..i):getPositionX() + node:getChildByName("weapon_name_"..i):getContentSize().width + 10)
                node:getChildByName("weapon_lv_num_"..i):setPositionX(node:getChildByName("weapon_lv_"..i):getPositionX() + node:getChildByName("weapon_lv_"..i):getContentSize().width )
            end
        end

        for i=#weapon_list+1,3 do
            for i2,v2 in ipairs(weapon_ccs) do
                node:getChildByName(v2..i):removeFromParent()
            end
        end

        local hh = 50 * (3-#weapon_list)

        for i,v in ipairs(equip_ccs) do
            node:getChildByName(v):setPositionY(node:getChildByName(v):getPositionY() +  hh)
        end

        for i,v in ipairs(gem_ccs) do
            node:getChildByName(v):setPositionY(node:getChildByName(v):getPositionY() +  hh)
        end

        -- for i=#weapon_list+1,3 do
        --     for i2,v2 in ipairs(weapon_ccs) do
        --         node:getChildByName(v2..i):setPositionY(node:getChildByName(v2..i):getPositionY() - (label:getContentSize().height - hh))
        --     end
        -- end

        local equip_list = {}
        for i,v in ipairs(ship_info.equip_list) do
            if v ~= 0 then
                table.insert(equip_list, v)
            end
        end

        local equip_item_pos = cc.p(node:getChildByName("equip_item"):getPosition())
        for i,v in ipairs(equip_list) do
            local equip_info = player:getEquipByGUID(v)
            if equip_info then
                local equip_conf = CONF.EQUIP.get(equip_info.equip_id)

                local equip_node = require("util.ItemNode"):create():init(equip_info.equip_id, nil, equip_info.strength)
                equip_node:setPosition(cc.p(equip_item_pos.x + (i-1)*65, equip_item_pos.y))
                equip_node:setScale(node:getChildByName("equip_item"):getScale())
                node:addChild(equip_node)
            end

        end

        node:getChildByName("equip_item"):setVisible(false)

        local gem_list = {}
        for i,v in ipairs(ship_info.gem_list) do
            if v ~= 0 then
                table.insert(gem_list, v)
            end
        end

        local gem_item_pos = cc.p(node:getChildByName("gem_item"):getPosition())
        for i,v in ipairs(gem_list) do
            local equip_node = require("util.ItemNode"):create():init(v, nil)
            equip_node:setPosition(cc.p(gem_item_pos.x + (i-1)*65, gem_item_pos.y))
            equip_node:setScale(node:getChildByName("gem_item"):getScale())
            node:addChild(equip_node)

        end

        node:getChildByName("gem_item"):setVisible(false)

        return node
    end

    
    local rn = require("app.ExResInterface"):getInstance():FastLoad("FormScene/FormShipInfo.csb")
    local conf = CONF.AIRSHIP.get(ship_info.id)

    rn:getChildByName("ship_upgrade"):setString(CONF:getStringValue("break")..":")
    for i=1,6 do
        rn:getChildByName("star_"..i):setPositionX(rn:getChildByName("ship_upgrade"):getContentSize().width + rn:getChildByName("ship_upgrade"):getPositionX() + 20 + (i-1)*20)
    end

    if ship_info.ship_break == nil then
        ship_info.ship_break = 0
    end

--    for i=ship_info.ship_break+1,6 do
        -- rn:getChildByName("star_"..i):setTexture("LevelScene/ui/star_outline.png")
        -- rn:getChildByName("star_"..i):setScale(1)
--        rn:getChildByName("star_"..i):removeFromParent()
--    end
    player:ShowShipStar(rn,ship_info.ship_break,"star_")

    rn:getChildByName("Image_3"):loadTexture("ShipImage/"..conf.ICON_ID..".png")
    rn:getChildByName("ship_bg"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
    rn:getChildByName("quality"):setTexture("ShipQuality/quality_"..conf.QUALITY..".png")
    rn:getChildByName("ship_icon"):loadTexture("RoleIcon/"..conf.ICON_ID..".png")
    rn:getChildByName("ship_name"):setString(CONF:getStringValue(conf.NAME_ID))
    rn:getChildByName("ship_lv_num"):setString("Lv."..ship_info.level)
    rn:getChildByName("ship_fight_num"):setString(player:calShipFightPowerByInfo(ship_info))
    rn:getChildByName("ship_type"):loadTexture("ShipType/"..conf.TYPE..".png")


    -- local cal_info = player:calShipByInfo(ship_info)
    local cal_info = ship_info
    rn:getChildByName("ship_hp"):setString(CONF:getStringValue("Attr_2")..":")
    rn:getChildByName("ship_hp_num"):setString(cal_info.attr[CONF.EShipAttr.kHP])
    rn:getChildByName("ship_atk"):setString(CONF:getStringValue("Attr_3")..":")
    rn:getChildByName("ship_atk_num"):setString(cal_info.attr[CONF.EShipAttr.kAttack])
    rn:getChildByName("ship_def"):setString(CONF:getStringValue("Attr_4")..":")
    rn:getChildByName("ship_def_num"):setString(cal_info.attr[CONF.EShipAttr.kDefence])
    rn:getChildByName("ship_speed"):setString(CONF:getStringValue("Attr_5")..":")
    rn:getChildByName("ship_speed_num"):setString(cal_info.attr[CONF.EShipAttr.kSpeed])
    rn:getChildByName("ship_e_atk"):setString(CONF:getStringValue("Attr_20")..":")
    rn:getChildByName("ship_e_atk_num"):setString(cal_info.attr[CONF.EShipAttr.kEnergyAttack])
    rn:getChildByName("ship_dur"):setString(CONF:getStringValue("durable")..":")
    rn:getChildByName("ship_dur_num"):setString(ship_info.durable)
    rn:getChildByName("ship_dur_max"):setString("/"..Tools.getShipMaxDurable(ship_info))

    if ship_info.durable < Tools.getShipMaxDurable(ship_info)/10 then
        rn:getChildByName("ship_dur_max"):setTextColor(cc.c4b(255,145,136,255))
        -- rn:getChildByName("ship_dur_max"):enableShadow(cc.c4b(255,145,136,255), cc.size(0.5,0.5))
    end

    local diff = 10
    rn:getChildByName("ship_hp_num"):setPositionX(rn:getChildByName("ship_hp"):getPositionX() + rn:getChildByName("ship_hp"):getContentSize().width + diff)
    rn:getChildByName("ship_atk_num"):setPositionX(rn:getChildByName("ship_atk"):getPositionX() + rn:getChildByName("ship_atk"):getContentSize().width + diff)
    rn:getChildByName("ship_def_num"):setPositionX(rn:getChildByName("ship_def"):getPositionX() + rn:getChildByName("ship_def"):getContentSize().width + diff)
    rn:getChildByName("ship_speed_num"):setPositionX(rn:getChildByName("ship_speed"):getPositionX() + rn:getChildByName("ship_speed"):getContentSize().width + diff)
    rn:getChildByName("ship_e_atk_num"):setPositionX(rn:getChildByName("ship_e_atk"):getPositionX() + rn:getChildByName("ship_e_atk"):getContentSize().width + diff)
    rn:getChildByName("ship_dur_num"):setPositionX(rn:getChildByName("ship_dur"):getPositionX() + rn:getChildByName("ship_dur"):getContentSize().width + diff)
    rn:getChildByName("ship_dur_max"):setPositionX(rn:getChildByName("ship_dur_num"):getPositionX() + rn:getChildByName("ship_dur_num"):getContentSize().width)

    -- local list = rn:getChildByName("list")
    self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"), cc.size(0,0), cc.size(386,480))

    local info_node = createNode(ship_info)

    self.svd_:addElement(info_node)

    rn:getChildByName("ok"):getChildByName("text"):setString(CONF:getStringValue("closed"))
    rn:getChildByName("ok"):addClickEventListener(function ( ... )
        rn:removeFromParent()
    end)

    rn:getChildByName("back"):setSwallowTouches(true)
    rn:getChildByName("back"):addClickEventListener(function ( ... )
        rn:removeFromParent()

    end)

    return rn

end

return ItemInfoNode