
local FormShipInfoNode = class("FormShipInfoNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

FormShipInfoNode.RESOURCE_FILENAME = "FormScene/FormShipInfo.csb"

function FormShipInfoNode:onEnterTransitionFinish()

end

function FormShipInfoNode:createInfoNode(ship_info)
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
    -- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
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
        local weapon = player:getWeaponByGUID(v)
        local weapon_conf = CONF.WEAPON.get(weapon.weapon_id)
        node:getChildByName("weapon_icon_"..i):loadTexture("WeaponIcon/"..weapon_conf.ICON_ID..".png")
        node:getChildByName("weapon_name_"..i):setString(CONF:getStringValue(weapon_conf.NAME_ID))
        node:getChildByName("weapon_lv_num_"..i):setString(weapon_conf.LEVEL)

        node:getChildByName("weapon_lv_"..i):setPositionX(node:getChildByName("weapon_name_"..i):getPositionX() + node:getChildByName("weapon_name_"..i):getContentSize().width + 10)
        node:getChildByName("weapon_lv_num_"..i):setPositionX(node:getChildByName("weapon_lv_"..i):getPositionX() + node:getChildByName("weapon_lv_"..i):getContentSize().width )
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

function FormShipInfoNode:init(scene,guid)

    self.scene_ = scene

    local rn = self:getResourceNode()

    local ship_info = player:getShipByGUID(guid)
    local conf = CONF.AIRSHIP.get(ship_info.id)

    rn:getChildByName("ship_upgrade"):setString(CONF:getStringValue("break")..":")
    for i=1,6 do
        rn:getChildByName("star_"..i):setPositionX(rn:getChildByName("ship_upgrade"):getContentSize().width + rn:getChildByName("ship_upgrade"):getPositionX() + 20 + (i-1)*20)
    end

    if ship_info.ship_break == nil then
        ship_info.ship_break = 0
    end

    for i=ship_info.ship_break+1,6 do
        -- rn:getChildByName("star_"..i):setTexture("LevelScene/ui/star_outline.png")
        -- rn:getChildByName("star_"..i):setScale(1)
        rn:getChildByName("star_"..i):removeFromParent()
    end

    rn:getChildByName("Image_3"):loadTexture("ShipImage/"..conf.ICON_ID..".png")
    rn:getChildByName("ship_bg"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
    rn:getChildByName("quality"):setTexture("ShipQuality/quality_"..conf.QUALITY..".png")
    rn:getChildByName("ship_icon"):loadTexture("RoleIcon/"..conf.ICON_ID..".png")
    rn:getChildByName("ship_icon"):setVisible(false)
    rn:getChildByName("ship_icon2"):setVisible(true)
    rn:getChildByName("ship_icon2"):setTexture("ShipImage/"..conf.DRIVER_ID..".png")
    rn:getChildByName("ship_name"):setString(CONF:getStringValue(conf.NAME_ID))
    rn:getChildByName("ship_lv_num"):setString("Lv."..ship_info.level)
    rn:getChildByName("ship_fight_num"):setString(player:calShipFightPower(guid))
    rn:getChildByName("ship_type"):loadTexture("ShipType/"..conf.TYPE..".png")


    local cal_info = player:calShip(guid)
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
    local svd_hight = 480
    if scene.name_ == "RepairScene/RepairScene" then
        svd_hight = 600
    end
    self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"), cc.size(0,0), cc.size(386,svd_hight))

    local info_node = self:createInfoNode(ship_info)

    self.svd_:addElement(info_node)


    rn:getChildByName("ok"):getChildByName("text"):setString(CONF:getStringValue("more_info"))
    rn:getChildByName("ok"):addClickEventListener(function ( ... )

        self:removeFromParent()

        if scene.choose_ then
            scene.choose_:removeFromParent()
            scene.choose_ = nil
        end

        if scene.light_ then
            scene.light_:setVisible(false)
        end
	print(" go ShipsDevelopScene at 221 FormShipInfoNode ")
        scene:getApp():pushView("ShipsScene/ShipsDevelopScene",{type = ship_info.kind,id =ship_info.id })
    end)

    rn:getChildByName("back"):setSwallowTouches(true)
    rn:getChildByName("back"):addClickEventListener(function ( ... )
        self:removeFromParent()

        if scene.choose_ then
            scene.choose_:removeFromParent()
            scene.choose_ = nil
        end

        if scene.light_ then
            scene.light_:setVisible(false)
        end
    end)
    
end

function FormShipInfoNode:createNewShipInfoNode(info)
    local nodeInfo = require("app.ExResInterface"):getInstance():FastLoad("FormScene/InfoNode.csb")
    local function createWearInfoNode(info)
        local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/ShipInfoNode.csb")
        node:getChildByName("weapon_text"):setString(CONF:getStringValue("weapon"))
        node:getChildByName("equip_text"):setString(CONF:getStringValue("equip"))
        node:getChildByName("gem_text"):setString(CONF:getStringValue("gem"))
        local skill_conf = CONF.WEAPON.get(info.skill)
        node:getChildByName("skill_icon"):loadTexture("WeaponIcon/"..skill_conf.ICON_ID..".png")
        node:getChildByName("skill_name"):setString(CONF:getStringValue(skill_conf.NAME_ID))
        local label = cc.Label:createWithTTF("  "..setMemo(skill_conf, 4), "fonts/cuyabra.ttf", 19)
        label:setAnchorPoint(cc.p(0,1))
        label:setPosition(cc.p(node:getChildByName("skill_ins"):getPosition()))
        label:setLineBreakWithoutSpace(true)
        label:setMaxLineWidth(300)
        label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        -- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
        node:addChild(label)

        node:getChildByName("skill_ins"):removeFromParent()
        local weapon_ccs = {"weapon_bg_", "weapon_icon_", "weapon_name_", "weapon_lv_", "weapon_lv_num_"}
        local equip_ccs = {"equip_text", "equip_line", "equip_item"}
        local gem_ccs = {"gem_text", "gem_line","gem_item"}
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
        for i,v in ipairs(info.weapon_list) do
            if v ~= 0 then
                table.insert(weapon_list, v)
            end
        end

        for i,v in ipairs(weapon_list) do
            local weapon = player:getWeaponByGUID(v)
            local weapon_conf = CONF.WEAPON.get(weapon.weapon_id)
            node:getChildByName("weapon_icon_"..i):loadTexture("WeaponIcon/"..weapon_conf.ICON_ID..".png")
            node:getChildByName("weapon_name_"..i):setString(CONF:getStringValue(weapon_conf.NAME_ID))
            node:getChildByName("weapon_lv_num_"..i):setString(weapon_conf.LEVEL)

            node:getChildByName("weapon_lv_"..i):setPositionX(node:getChildByName("weapon_name_"..i):getPositionX() + node:getChildByName("weapon_name_"..i):getContentSize().width + 10)
            node:getChildByName("weapon_lv_num_"..i):setPositionX(node:getChildByName("weapon_lv_"..i):getPositionX() + node:getChildByName("weapon_lv_"..i):getContentSize().width )
        end

        local hh = 50 * (3-#weapon_list)
        for i=#weapon_list+1,3 do
            for i2,v2 in ipairs(weapon_ccs) do
                node:getChildByName(v2..i):removeFromParent()
            end
        end

        for i,v in ipairs(equip_ccs) do
            node:getChildByName(v):setPositionY(node:getChildByName(v):getPositionY() +  hh)
        end

        for i,v in ipairs(gem_ccs) do
            node:getChildByName(v):setPositionY(node:getChildByName(v):getPositionY() +  hh)
        end

        local equip_list = {}
        for i,v in ipairs(info.equip_list) do
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
        for i,v in ipairs(info.gem_list) do
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


        node:getChildByName("weapon_line"):setPositionX(node:getChildByName("weapon_text"):getPositionX()+6+node:getChildByName("weapon_text"):getContentSize().width)
        node:getChildByName("equip_line"):setPositionX(node:getChildByName("equip_text"):getPositionX()+6+node:getChildByName("equip_text"):getContentSize().width)
        node:getChildByName("gem_line"):setPositionX(node:getChildByName("gem_text"):getPositionX()+6+node:getChildByName("gem_text"):getContentSize().width)
        return node
    end
    nodeInfo:getChildByName("close"):addClickEventListener(function()
        nodeInfo:removeFromParent()
        end)
    local rn = nodeInfo
    local ship = info
    local calship = player:calShip(ship.guid)
    local ship_power = player:calShipFightPower( ship.guid )
    local ship_hp = calship.attr[CONF.EShipAttr.kHP]
    local ship_defence = calship.attr[CONF.EShipAttr.kDefence]
    local ship_speed = calship.attr[CONF.EShipAttr.kSpeed]
    local ship_atk = calship.attr[CONF.EShipAttr.kAttack]
    local ship_eatk = calship.attr[CONF.EShipAttr.kEnergyAttack]
    local airship = CONF.AIRSHIP.get(ship.id)
    local ship_load = airship.LOAD
    if calship.load then
        ship_load = calship.load
    end
    local ship_durable = ship.durable.."/"..Tools.getShipMaxDurable(ship)
    local atk = rn:getChildByName("atk")
    local defence = rn:getChildByName("defence")
    local speed = rn:getChildByName("speed")
    local blood = rn:getChildByName("blood")
    local e_atk = rn:getChildByName("e_atk")
    local durable = rn:getChildByName("durable")
    local shipload = rn:getChildByName("load")

    atk:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kAttack)..":")
    defence:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kDefence)..":")
    speed:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kSpeed)..":")
    blood:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kHP)..":")
    e_atk:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kEnergyAttack)..":")
    shipload:getChildByName("text"):setString(CONF:getStringValue("Attr_37")..":")
    durable:getChildByName("text"):setString(CONF:getStringValue("durable")..":")
    atk:getChildByName("num"):setString(ship_atk)
    defence:getChildByName("num"):setString(ship_defence)
    speed:getChildByName("num"):setString(ship_speed)
    blood:getChildByName("num"):setString(ship_hp)
    e_atk:getChildByName("num"):setString(ship_eatk)
    durable:getChildByName("num"):setString(ship_durable)
    shipload:getChildByName("num"):setString(ship_load)
    rn:getChildByName("title"):setString(CONF:getStringValue("information"))

    atk:getChildByName("num"):setPosition(atk:getChildByName("text"):getPositionX()+atk:getChildByName("text"):getContentSize().width+5,atk:getChildByName("text"):getPositionY())
    defence:getChildByName("num"):setPosition(defence:getChildByName("text"):getPositionX()+defence:getChildByName("text"):getContentSize().width+5,defence:getChildByName("text"):getPositionY())
    speed:getChildByName("num"):setPosition(speed:getChildByName("text"):getPositionX()+speed:getChildByName("text"):getContentSize().width+5,speed:getChildByName("text"):getPositionY())
    blood:getChildByName("num"):setPosition(blood:getChildByName("text"):getPositionX()+blood:getChildByName("text"):getContentSize().width+5,blood:getChildByName("text"):getPositionY())
    e_atk:getChildByName("num"):setPosition(e_atk:getChildByName("text"):getPositionX()+e_atk:getChildByName("text"):getContentSize().width+5,e_atk:getChildByName("text"):getPositionY())
    durable:getChildByName("num"):setPosition(durable:getChildByName("text"):getPositionX()+durable:getChildByName("text"):getContentSize().width+5,durable:getChildByName("text"):getPositionY())
    shipload:getChildByName("num"):setPosition(shipload:getChildByName("text"):getPositionX()+shipload:getChildByName("text"):getContentSize().width+5,shipload:getChildByName("text"):getPositionY())

    local cfg_ship = CONF.AIRSHIP.get(info.id)
    rn:getChildByName("quality"):setTexture("ShipQuality/quality_"..cfg_ship.QUALITY..".png")
    rn:getChildByName("ship_type"):setTexture(string.format("ShipType/%d.png", cfg_ship.TYPE))
    rn:getChildByName("shipName"):setString("Lv."..ship.level.." "..CONF:getStringValue(cfg_ship.NAME_ID))
    rn:getChildByName("power"):setString(ship_power)
    rn:getChildByName("power_des"):setString(CONF:getStringValue("combat")..":")
    rn:getChildByName("power"):setPositionX(rn:getChildByName("power_des"):getPositionX())

    rn:getChildByName("break"):setString(CONF:getStringValue("break")..":")

    local breakX = rn:getChildByName("break"):getPositionX()+rn:getChildByName("break"):getContentSize().width
    local starX = rn:getChildByName("star_1"):getPositionX()
    local addX = 0
    if starX < breakX then
        addX = breakX - starX
    end
    for i=1,6 do
        rn:getChildByName("star_"..i):setPositionX(rn:getChildByName("star_"..i):getPositionX()+addX)
        rn:getChildByName("star_"..i):setVisible(i <= CONF.SHIP_BREAK.get(cfg_ship.QUALITY).NUM)
        rn:getChildByName("star_"..i):setTexture("Common/ui/ui_star_gray.png")
        if i <= ship.ship_break then
            if rn:getChildByName("star_"..i) then
                rn:getChildByName("star_"..i):setTexture("Common/ui/ui_star_light.png")
            end
        end
    end


    local svd = require("util.ScrollViewDelegate"):create( nodeInfo:getChildByName("list"),cc.size(5,5), cc.size(120 ,450))
    svd:getScrollView():setScrollBarEnabled(false)
    svd:clear()
    local node = createWearInfoNode(info)
    local height = math.abs(node:getChildByName("gem_item"):getPositionY()) + 90
    svd:addElement(createWearInfoNode(info),{size = cc.size(120,height)})
    return nodeInfo
end

function FormShipInfoNode:onExitTransitionStart()
    printInfo("FormShipInfoNode:onExitTransitionStart()")

end

return FormShipInfoNode