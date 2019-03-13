local player = require("app.Player"):getInstance()

local TipsInfoNode = class("TipsInfoNode")

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local app = require("app.MyApp"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local Bit = require "Bit"

function TipsInfoNode:ctor(node)
	self.node = node
    
end

local textLine = 8

--type:Config.ETipsType = {
--     kItem = 1,
--     kGem = 2,
--     kEquip = 3,
--     kSkill = 4,
-- }

-- data = {
--     ship_guid = ,
--     pos = ,    
-- }

function TipsInfoNode:chooseTips(id,type,takeoff,data)
    if type == CONF.ETipsType.kItem then
        return self:createItemNode(id,takeoff,data)
    elseif type == CONF.ETipsType.kGem then
        return self:createGemNode(id,takeoff,data)
    elseif type == CONF.ETipsType.kEquip then
        return self:createEquipNode(id,takeoff,data)
    elseif type == CONF.ETipsType.kSkill then
        return self:createSkillNode(id,takeoff,data)
    end
end

function TipsInfoNode:setPosition(node,x,y)

end

function TipsInfoNode:createItemNode(id,takeoff,data)
    local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/TipsInfoNode.csb")
    local cfg_item = CONF.ITEM.get(id)
    local type = cfg_item.TYPE
    local node_info = node:getChildByName("Node_info")
    node_info:getChildByName("name_bg"):getChildByName("title"):setString(CONF:getStringValue(cfg_item.NAME_ID))
    local bg_height = math.abs(node_info:getChildByName("start_pos"):getPositionY()) + node_info:getChildByName("name_bg"):getContentSize().height
    local label = cc.Label:createWithTTF(CONF:getStringValue("type")..":", "fonts/cuyabra.ttf", 16)
    label:setName("label")
    label:setAnchorPoint(cc.p(0,1))
    label:setPosition(node_info:getChildByName("start_pos"):getPosition())
    label:setTextColor(cc.c4b(237, 237, 193, 255))
    -- label:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
    node_info:addChild(label)
    local strType = ""
    if type >= 1 and type <= 8 then
        strType = CONF:getStringValue("IN_"..cfg_item.TYPE.."001")
    elseif type == 11 then
        strType = CONF:getStringValue("IN_11001")
    elseif type == 16 then
        strType = CONF:getStringValue("ship_bulepoint")
    else
        strType = CONF:getStringValue("prop")
    end

    local label1 = cc.Label:createWithTTF(strType, "fonts/cuyabra.ttf", 16)
    label1:setAnchorPoint(cc.p(0,1))
    label1:setPosition(node_info:getChildByName("label"):getPositionX()+node_info:getChildByName("label"):getContentSize().width,node_info:getChildByName("label"):getPositionY())
    -- label1:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    label1:setName("label1")
    node_info:addChild(label1)
    local height1 = math.max(node_info:getChildByName("label"):getContentSize().height + textLine,node_info:getChildByName("label1"):getContentSize().height + textLine)
    bg_height = bg_height + height1

    local label2 = cc.Label:createWithTTF(CONF:getStringValue("detail")..":", "fonts/cuyabra.ttf", 16)
    label2:setName("label2")
    label2:setAnchorPoint(cc.p(0,1))
    label2:setPosition(node_info:getChildByName("label"):getPositionX(),node_info:getChildByName("label"):getPositionY()-node_info:getChildByName("label"):getContentSize().height-textLine)
    label2:setTextColor(cc.c4b(237, 237, 193, 255))
    -- label2:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
    node_info:addChild(label2)

    local medo = CONF:getStringValue(cfg_item.MEMO_ID)
    if cfg_item.TYPE and cfg_item.TYPE == 16 then
        local strNum = CONF.AIRSHIP.get(cfg_item.SHIPID).BLUEPRINT_NUM[1]
        local strName = CONF:getStringValue(CONF.AIRSHIP.get(cfg_item.SHIPID).NAME_ID)
        medo = string.gsub(string.gsub(CONF:getStringValue(cfg_item.MEMO_ID),"%%d",strNum),"%%h",strName)
    end

    local label3 = cc.Label:createWithTTF(medo, "fonts/cuyabra.ttf", 16)
    label3:setAnchorPoint(cc.p(0,1))
    label3:setPosition(node_info:getChildByName("label2"):getPositionX()+node_info:getChildByName("label2"):getContentSize().width,node_info:getChildByName("label2"):getPositionY())
    label3:setLineBreakWithoutSpace(true)
    label3:setMaxLineWidth(math.abs(node_info:getChildByName("label2"):getPositionX()) - node_info:getChildByName("label2"):getContentSize().width - 3)
    label3:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    -- label3:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    label3:setName("label3")
    node_info:addChild(label3)
    local height2 = math.max(node_info:getChildByName("label2"):getContentSize().height + textLine,node_info:getChildByName("label3"):getContentSize().height + textLine)
    bg_height = bg_height + height2 + 8
    node_info:getChildByName("bg"):setContentSize(cc.size(node_info:getChildByName("bg"):getContentSize().width,bg_height))
    -- node_info:getChildByName("name_bg"):getChildByName("title"):setPosition(node_info:getChildByName("name_bg"):getContentSize().width/2,node_info:getChildByName("name_bg"):getContentSize().height/2)
    node_info:getChildByName("line"):setContentSize(cc.size(node_info:getChildByName("bg"):getContentSize().width+2,node_info:getChildByName("bg"):getContentSize().height+5))
    -- node:getChildByName("Image_44"):addClickEventListener(function()
    --     node:removeFromParent()
    --     end)
    node_info:getChildByName("line"):setVisible(false)
    node:getChildByName("touch"):addClickEventListener(function()
        node:removeFromParent()
        end)
    return node
end

function TipsInfoNode:createGemNode(id,takeoff,data)
    local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/TipsInfoNode.csb")
    local cfg_gem = CONF.GEM.get(id)
    local node_info = node:getChildByName("Node_info")
    node_info:getChildByName("name_bg"):getChildByName("title"):setString(CONF:getStringValue(cfg_gem.NAME_ID))
    local bg_height = math.abs(node_info:getChildByName("start_pos"):getPositionY()) + node_info:getChildByName("name_bg"):getContentSize().height
    local label = cc.Label:createWithTTF(CONF:getStringValue("type")..":", "fonts/cuyabra.ttf", 16)
    label:setName("label")
    label:setAnchorPoint(cc.p(0,1))
    label:setPosition(node_info:getChildByName("start_pos"):getPosition())
    label:setTextColor(cc.c4b(237, 237, 193, 255))
    -- label:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
    node_info:addChild(label)

    local label1 = cc.Label:createWithTTF(CONF:getStringValue("gem"), "fonts/cuyabra.ttf", 16)
    label1:setAnchorPoint(cc.p(0,1))
    label1:setPosition(node_info:getChildByName("label"):getPositionX()+node_info:getChildByName("label"):getContentSize().width,node_info:getChildByName("label"):getPositionY())
    -- label1:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    label1:setName("label1")
    node_info:addChild(label1)
    local height1 = math.max(node_info:getChildByName("label"):getContentSize().height + textLine,node_info:getChildByName("label1"):getContentSize().height + textLine)
    bg_height = bg_height + height1

    local label2 = cc.Label:createWithTTF(CONF:getStringValue("state")..":", "fonts/cuyabra.ttf", 16)
    label2:setName("label2")
    label2:setAnchorPoint(cc.p(0,1))
    label2:setPosition(node_info:getChildByName("label"):getPositionX(),node_info:getChildByName("label"):getPositionY()-node_info:getChildByName("label"):getContentSize().height-textLine)
    label2:setTextColor(cc.c4b(237, 237, 193, 255))
    -- label2:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
    node_info:addChild(label2)

   
    local strValue = cfg_gem.ATTR_VALUE
    for k,v in pairs(CONF.ShipPercentAttrs) do
        if cfg_gem.ATTR_KEY == v then
            strValue = strValue..'%'
        end
    end
    local medo = CONF:getStringValue("Attr_"..cfg_gem.ATTR_KEY)..'+'..strValue
    local label3 = cc.Label:createWithTTF(medo, "fonts/cuyabra.ttf", 16)
    label3:setAnchorPoint(cc.p(0,1))
    label3:setPosition(node_info:getChildByName("label2"):getPositionX()+node_info:getChildByName("label2"):getContentSize().width,node_info:getChildByName("label2"):getPositionY())
    label3:setLineBreakWithoutSpace(true)
    label3:setMaxLineWidth(node_info:getChildByName("bg"):getContentSize().width - node_info:getChildByName("label2"):getPositionX() - node_info:getChildByName("label2"):getContentSize().width - 3)
    label3:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    -- label3:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    label3:setName("label3")
    node_info:addChild(label3)
    local height2 = math.max(node_info:getChildByName("label2"):getContentSize().height + textLine,node_info:getChildByName("label3"):getContentSize().height + textLine)
    bg_height = bg_height + height2

    local line = node:getChildByName("line"):setVisible(false)
    line:setAnchorPoint(cc.p(0,1))
    line:setPosition(label2:getPositionX(),label3:getPositionY()-label3:getContentSize().height-textLine)
    line:setContentSize(cc.size(math.abs(node_info:getChildByName("label2"):getPositionX())*2 - math.abs(node_info:getChildByName("name_bg"):getPositionX()),2))
    bg_height = bg_height + line:getContentSize().height + textLine

    local btn = ccui.Button:create("Common/newUI/button_yellow.png","Common/newUI/button_yellow_light.png")
    btn:setAnchorPoint(cc.p(0.5,1))
    btn:setScale(0.7)
    btn:setPosition(line:getPositionX()+line:getContentSize().width/2,line:getPositionY()-line:getContentSize().height-textLine*2)
    node_info:addChild(btn)
    local btn_label = cc.Label:createWithTTF(CONF:getStringValue("IN_13005"), "fonts/cuyabra.ttf", 20)
    if takeoff then
        btn_label = cc.Label:createWithTTF(CONF:getStringValue("take off"), "fonts/cuyabra.ttf", 20)
    end
    btn:addClickEventListener(function()
        local info = player:getShipByGUID(data.ship_guid)
        local conf = CONF.AIRSHIP.get(info.id)
        local cfg_gem = CONF.GEM.get(id)
        if  not takeoff then
            local canEquip = false
            local lvEnough = false
            if conf.HOLE[data.pos] then
                local confGen
                if info.gem_list[data.pos] ~= 0 then
                    confGen = CONF.GEM.get(info.gem_list[data.pos])
                end
                if confGen then
                    if cfg_gem.TYPE == confGen.TYPE then
                        canEquip = true
                    end
                else
                    if cfg_gem.TYPE == conf.HOLE[data.pos] then
                        canEquip = true
                    end
                end
                if conf.HOLE[data.pos] == 6 then
                    canEquip = true
                end
                if canEquip then
                    if Bit:has(info.status, 4) == true then
                        tips:tips(CONF:getStringValue("ship lock"))
                        return
                    end
                    if conf.HOLEOPEN_LEVEL[data.pos] <= info.level then
                        -- tips:tips(CONF:getStringValue("level_not_enought"))
                        -- return
                        lvEnough = true
                        local strData = Tools.encode("GemEquipReq", {
                            type = 1,
                            ship_guid = data.ship_guid,
                            index = data.pos,
                            gem_id = id,
                        })

                        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GEM_EQUIP_REQ"),strData)
                        node:removeFromParent()
                        gl:retainLoading()
                    end
                end
            end
            if not lvEnough then
                tips:tips(CONF:getStringValue("level_not_enought"))
            end
            if not canEquip then
                tips:tips(CONF:getStringValue("no_other_gem"))
            end
        else
            if Bit:has(info.status, 4) == true then
                tips:tips(CONF:getStringValue("ship lock"))
                return
            end
            local strData = Tools.encode("GemEquipReq", {
                type = 2,
                ship_guid = info.guid,
                index = data.pos,
                gem_id = id,
            })

            GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GEM_EQUIP_REQ"),strData)
            node:removeFromParent()
            gl:retainLoading()
        end
        end)
    btn_label:setPosition(btn:getContentSize().width/2,btn:getContentSize().height/2)
    -- btn_label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    btn:addChild(btn_label)
    bg_height = bg_height + btn:getContentSize().height + textLine


    bg_height = bg_height + 8
    node_info:getChildByName("bg"):setContentSize(cc.size(node_info:getChildByName("bg"):getContentSize().width,bg_height))
    -- node_info:getChildByName("name_bg"):getChildByName("title"):setPosition(node_info:getChildByName("name_bg"):getContentSize().width/2,node_info:getChildByName("name_bg"):getContentSize().height/2)
    node_info:getChildByName("line"):setContentSize(cc.size(node_info:getChildByName("bg"):getContentSize().width+2,node_info:getChildByName("bg"):getContentSize().height+5))
    -- node:getChildByName("Image_44"):addClickEventListener(function()
    --     node:removeFromParent()
    --     end)
    node_info:getChildByName("line"):setVisible(false)
    node:getChildByName("touch"):addClickEventListener(function()
        node:removeFromParent()
        end)
    return node
end

function TipsInfoNode:createEquipNode(id,takeoff,data)
    local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/TipsInfoNode.csb")
    local equip = player:getEquipByGUID(id)
    if not equip then
        return
    end
    local cfg_equip = CONF.EQUIP.get(equip.equip_id)
    local ship = player:getShipByGUID(data.ship_guid)
    local node_info = node:getChildByName("Node_info")
    local maxLevel = CONF.EQUIP.get(equip.equip_id) and CONF.EQUIP.get(equip.equip_id).MAX_STRENGTH or 0
    node_info:getChildByName("name_bg"):getChildByName("title"):setString(CONF:getStringValue(cfg_equip.NAME_ID))
    local bg_height = math.abs(node_info:getChildByName("start_pos"):getPositionY())+ node_info:getChildByName("name_bg"):getContentSize().height
    local label = cc.Label:createWithTTF(CONF:getStringValue("equip_type")..":", "fonts/cuyabra.ttf", 16)
    label:setName("label")
    label:setAnchorPoint(cc.p(0,1))
    label:setPosition(node_info:getChildByName("start_pos"):getPosition())
    label:setTextColor(cc.c4b(237, 237, 193, 255))
    -- label:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
    node_info:addChild(label)
    local  strType = CONF:getStringValue("Equip_type_"..cfg_equip.TYPE)
    local label1 = cc.Label:createWithTTF(strType, "fonts/cuyabra.ttf", 16)
    label1:setAnchorPoint(cc.p(0,1))
    label1:setPosition(node_info:getChildByName("label"):getPositionX()+node_info:getChildByName("label"):getContentSize().width,node_info:getChildByName("label"):getPositionY())
    -- label1:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    label1:setName("label1")
    node_info:addChild(label1)
    local height1 = math.max(node_info:getChildByName("label"):getContentSize().height + textLine,node_info:getChildByName("label1"):getContentSize().height + textLine)
    bg_height = bg_height + height1

    local label2 = cc.Label:createWithTTF(CONF:getStringValue("break level")..":", "fonts/cuyabra.ttf", 16)
    label2:setName("label2")
    label2:setAnchorPoint(cc.p(0,1))
    label2:setPosition(node_info:getChildByName("label"):getPositionX(),node_info:getChildByName("label"):getPositionY()-node_info:getChildByName("label"):getContentSize().height-textLine)
    label2:setTextColor(cc.c4b(237, 237, 193, 255))
    -- label2:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
    node_info:addChild(label2)

    local strength_num = equip.strength or 0

    local label3 = cc.Label:createWithTTF(strength_num, "fonts/cuyabra.ttf", 16)
    label3:setAnchorPoint(cc.p(0,1))
    label3:setPosition(node_info:getChildByName("label2"):getPositionX()+node_info:getChildByName("label2"):getContentSize().width,node_info:getChildByName("label2"):getPositionY())
    -- label3:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    label3:setName("label3")

    if equip.strength >= maxLevel then
        local sprite = cc.Sprite:create("StarLeagueScene/ui/MAX.png")
        sprite:setAnchorPoint(cc.p(0,1))
        sprite:setPosition(label3:getPositionX()+label3:getContentSize().width+2,label3:getPositionY()+3)
        node_info:addChild(sprite)
        -- local label_3 = cc.Label:createWithTTF(CONF:getStringValue("icon max"), "fonts/cuyabra.ttf", 16)
        -- label_3:setAnchorPoint(cc.p(0,1))
        -- label_3:setPosition(label3:getPositionX()+label3:getContentSize().width+4,label3:getPositionY())
        -- node_info:addChild(label_3)
        -- label_3:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    end
    node_info:addChild(label3)
    local height2 = math.max(node_info:getChildByName("label2"):getContentSize().height + textLine,node_info:getChildByName("label3"):getContentSize().height + textLine)
    bg_height = bg_height + height2

    local i = 2
    for k,v in ipairs(cfg_equip.KEY) do
        i = i + 2
        local name = CONF:getStringValue("Attr_"..v)
        local attr_num = math.floor(cfg_equip.ATTR[k] + strength_num*cfg_equip.ATTR[k]*CONF.PARAM.get("equip_strength").PARAM)
        attr_num = "+"..attr_num
        for k2,v2 in pairs(CONF.ShipPercentAttrs) do
            if v2 == v then
                attr_num = "+"..attr_num.."%"
                break
            end
        end
        local label1 = cc.Label:createWithTTF(name..":", "fonts/cuyabra.ttf", 16)
        label1:setName("label"..i)
        label1:setAnchorPoint(cc.p(0,1))
        label1:setPosition(node_info:getChildByName("label"..(i-2)):getPositionX(),node_info:getChildByName("label"..(i-2)):getPositionY()-node_info:getChildByName("label"..(i-2)):getContentSize().height-textLine)
        label1:setTextColor(cc.c4b(237, 237, 193, 255))
        -- label1:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
        node_info:addChild(label1)

        local label2 = cc.Label:createWithTTF(attr_num, "fonts/cuyabra.ttf", 16)
        label2:setAnchorPoint(cc.p(0,1))
        label2:setPosition(node_info:getChildByName("label"..i):getPositionX()+node_info:getChildByName("label"..i):getContentSize().width,node_info:getChildByName("label"..i):getPositionY())
        -- label2:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
        label2:setName("label"..(i+1))
        node_info:addChild(label2) 
--        local height2 = math.max(node_info:getChildByName("label"..i):getContentSize().height + textLine,node_info:getChildByName("label"..(i+1)):getContentSize().height + textLine)
--        bg_height = bg_height + height2
    end
    bg_height = bg_height + height2*4
    i = i + 1

    local btn1 = ccui.Button:create("Common/newUI/button_yellow.png","Common/newUI/button_yellow_light.png")
    btn1:setAnchorPoint(cc.p(0.5,1))
    btn1:setScale(0.7)
    local ww =math.abs(node_info:getChildByName("name_bg"):getPositionX())-btn1:getContentSize().width
    btn1:setPosition(-ww,node_info:getChildByName("label4"):getPositionY()-(node_info:getChildByName("label4"):getContentSize().height+textLine)*4)
    node_info:addChild(btn1)
    local btn_label1 = cc.Label:createWithTTF(CONF:getStringValue("STRENGTHEN_TEXT_11"), "fonts/cuyabra.ttf", 20)
    if takeoff then
        btn_label1 = cc.Label:createWithTTF(CONF:getStringValue("take off")..CONF:getStringValue("equip"), "fonts/cuyabra.ttf", 20)
    end
    btn_label1:setPosition(btn1:getContentSize().width/2,btn1:getContentSize().height/2)
    -- btn_label1:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    btn1:addChild(btn_label1)

    bg_height = bg_height + btn1:getContentSize().height + textLine
    btn1:addClickEventListener(function()
        if not takeoff then
            if ship.level < player:getEquipByGUID(id).level then
                tips:tips(CONF:getStringValue("ship_level_not_enought"))
                return
            end
            if Bit:has(ship.status, 4) == true then
                tips:tips(CONF:getStringValue("ship lock"))
                return
            end
            local strData = Tools.encode("ShipEquipReq", {

                ship_guid = ship.guid,
                equip_index_list = {cfg_equip.TYPE},
                equip_guid_list = {id},
            })

            GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_EQUIP_REQ"),strData)
            node:removeFromParent()
            gl:retainLoading()
        else
            if guideManager:getGuideType() then
                return
            end
            if Bit:has(ship.status, 4) == true then
                tips:tips(CONF:getStringValue("ship lock"))
                return
            end
            local strData = Tools.encode("ShipEquipReq", {

                ship_guid = ship.guid,
                equip_index_list = {cfg_equip.TYPE},
                equip_guid_list = {0},
            })

            GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_EQUIP_REQ"),strData)
            node:removeFromParent()
            gl:retainLoading()
        end
        end)
    if equip.strength < maxLevel then
        local line = node:getChildByName("line"):setVisible(true)
        line:setAnchorPoint(cc.p(0,1))
        line:setPosition(node_info:getChildByName("label"..(i-1)):getPositionX(),btn1:getPositionY() - btn1:getContentSize().height*0.7 -textLine)
        -- line:setContentSize(cc.size(math.abs(node_info:getChildByName("label"..(i-1)):getPositionX())*2 - math.abs(node_info:getChildByName("name_bg"):getPositionX()),2))
        bg_height = bg_height + line:getContentSize().height + textLine

        -- local maxLevel = CONF.EQUIP.get(equip.equip_id) and CONF.EQUIP.get(equip.equip_id).MAX_STRENGTH or 0
        -- if equip.strength < maxLevel then
            
        -- end
        local img1 = cc.Sprite:create("ItemIcon/10001.png")
        local img2 = cc.Sprite:create("ItemIcon/13005.png")
        img1:setPosition(line:getPositionX()+img1:getContentSize().width*0.1,line:getPositionY()-line:getContentSize().height-textLine*4)
        img1:setScale(0.4)
        node_info:addChild(img1)
        local my_gold_num = player:getResByIndex(1)
        local my_item_num = player:getItemNumByID(13005)
        local maxLevel = CONF.EQUIP.get(equip.equip_id) and CONF.EQUIP.get(equip.equip_id).MAX_STRENGTH or 0
        local equipLevel = equip.strength + 1
        if equip.strength >= maxLevel then
            equipLevel = maxLevel
        end
        local need_gold_num = math.floor(CONF.EQUIP_STRENGTH.get(equipLevel).ITEM_NUM[1] * CONF.PARAM.get("equip_strength_"..equip.quality).PARAM)
        local need_item_num = math.floor(CONF.EQUIP_STRENGTH.get(equipLevel).ITEM_NUM[2] * CONF.PARAM.get("equip_strength_"..equip.quality).PARAM)
        
        local imglabel11 = cc.Label:createWithTTF(formatRes(need_gold_num).."/", "fonts/cuyabra.ttf", 14)
        local imglabel12 = cc.Label:createWithTTF(formatRes(my_gold_num), "fonts/cuyabra.ttf", 14)
        imglabel11:setAnchorPoint(cc.p(0,1))
        imglabel11:setPosition(img1:getPositionX()+img1:getContentSize().width/2*0.4,img1:getPositionY()+img1:getContentSize().height/2*0.3-3)
        imglabel11:setName("imglabel11")
        node_info:addChild(imglabel11) 
        if need_gold_num > my_gold_num then
            imglabel11:setTextColor(cc.c4b(233,50,59,255))
            -- imglabel11:enableShadow(cc.c4b(233,50,59,255),cc.size(0.2,0.2))
        else  
            imglabel11:setTextColor(cc.c4b(51,231,51,255)) 
            -- imglabel11:enableShadow(cc.c4b(51,231,51,255),cc.size(0.2,0.2))
        end

        imglabel12:setAnchorPoint(cc.p(0,1))
        imglabel12:setPosition(imglabel11:getPositionX()+imglabel11:getContentSize().width,imglabel11:getPositionY())
        -- imglabel12:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
        imglabel12:setName("imglabel12")
        node_info:addChild(imglabel12) 

        img2:setPosition(imglabel12:getPositionX()+imglabel12:getContentSize().width+14,line:getPositionY()-line:getContentSize().height-textLine*4)
        node_info:addChild(img2)
        img2:setScale(0.4)
        local imglabel21 = cc.Label:createWithTTF(formatRes(need_item_num).."/", "fonts/cuyabra.ttf", 14)
        local imglabel22 = cc.Label:createWithTTF(formatRes(my_item_num), "fonts/cuyabra.ttf", 14)
        imglabel21:setAnchorPoint(cc.p(0,1))
        imglabel21:setPosition(img2:getPositionX()+img2:getContentSize().width/2*0.4,img2:getPositionY()+img2:getContentSize().height/2*0.3-3)
        imglabel21:setName("imglabel21")
        node_info:addChild(imglabel21) 
        if need_item_num > my_item_num then
            imglabel21:setTextColor(cc.c4b(233,50,59,255))
            -- imglabel21:enableShadow(cc.c4b(233,50,59,255),cc.size(0.2,0.2))
        else  
            imglabel21:setTextColor(cc.c4b(51,231,51,255)) 
            -- imglabel21:enableShadow(cc.c4b(51,231,51,255),cc.size(0.2,0.2))
        end

        imglabel22:setAnchorPoint(cc.p(0,1))
        imglabel22:setPosition(imglabel21:getPositionX()+imglabel21:getContentSize().width,imglabel21:getPositionY())
        -- imglabel22:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
        imglabel22:setName("imglabel22")
        node_info:addChild(imglabel22)
        bg_height = bg_height + img2:getContentSize().height*0.4 + textLine

        local btn2 = ccui.Button:create("Common/newUI/button_yellow.png","Common/newUI/button_yellow_light.png")
        btn2:setAnchorPoint(cc.p(0.5,1))
        btn2:setScale(0.7)
        btn2:setPosition(line:getPositionX()+btn1:getContentSize().width/2*0.7+25,img2:getPositionY()-img2:getContentSize().height*0.4)
        node_info:addChild(btn2)
        local btn_label2 = cc.Label:createWithTTF(CONF:getStringValue("STRENGTHEN_TEXT_12"), "fonts/cuyabra.ttf", 20)
        btn_label2:setPosition(btn2:getContentSize().width/2,btn2:getContentSize().height/2)
        -- btn_label2:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
        btn2:addChild(btn_label2) 

        local btn3 = ccui.Button:create("Common/newUI/button_yellow.png","Common/newUI/button_yellow_light.png")
        btn3:setAnchorPoint(cc.p(0.5,1))
        btn3:setScale(0.7)
        btn3:setPosition(btn2:getPositionX()+btn2:getContentSize().width/3*2+7,img2:getPositionY()-img2:getContentSize().height*0.4)
        node_info:addChild(btn3)
        local btn_label3 = cc.Label:createWithTTF(CONF:getStringValue("fast_strengthen"), "fonts/cuyabra.ttf", 20)
        btn_label3:setPosition(btn3:getContentSize().width/2,btn3:getContentSize().height/2)
        -- btn_label3:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
        btn3:addChild(btn_label3)    

        btn2:addClickEventListener(function()
            if not CONF.EQUIP_STRENGTH.check(equip.strength+1) then
                return
            end
            local canUpgrade = true
            local my_gold_num = player:getResByIndex(1)
            local my_item_num = player:getItemNumByID(13005)
            local maxLevel = CONF.EQUIP.get(equip.equip_id) and CONF.EQUIP.get(equip.equip_id).MAX_STRENGTH or 0
            if equip.strength >= maxLevel then
                tips:tips(CONF:getStringValue("max_level"))
                return
            end
            for k,v in ipairs(CONF.EQUIP_STRENGTH.get(equip.strength+1).ITEM_ID) do
                local need = math.floor(CONF.EQUIP_STRENGTH.get(equip.strength+1).ITEM_NUM[k] * CONF.PARAM.get("equip_strength_"..equip.quality).PARAM)
                local have = player:getItemNumByID(v)
                if need > have then
                    canUpgrade = false
                end
            end

            if canUpgrade then
                if Bit:has(ship.status, 4) == true then
                    if takeoff then
                        tips:tips(CONF:getStringValue("ship lock"))
                        return
                    end
                end
                local strData = Tools.encode("StrengthEquipReq", {

                    equip_guid = id,
                    count = 1,
                })

                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_STRENGTH_EQUIP_REQ"),strData)
                node:removeFromParent()
                gl:retainLoading()
            else
                tips:tips(CONF:getStringValue("Material_not_enought")) 
                local jumpTab = {}
                for k,v in ipairs(CONF.EQUIP_STRENGTH.get(equip.strength+1).ITEM_ID) do
                    local need = math.floor(CONF.EQUIP_STRENGTH.get(equip.strength+1).ITEM_NUM[k] * CONF.PARAM.get("equip_strength_"..equip.quality).PARAM)
                    local have = player:getItemNumByID(v)
                    if need > have then
                        local cfg_item = CONF.ITEM.get(v)
                        if cfg_item and cfg_item.JUMP then
                            table.insert(jumpTab,cfg_item.JUMP)
                        end
                    end
                end
                if Tools.isEmpty(jumpTab) == false and not node:getParent():getChildByName("JumpChoseLayer") then
                    jumpTab.scene = "TipsInfoNode"
                    local center = cc.exports.VisibleRect:center()
                    local layer = app:createView("ShipsScene/JumpChoseLayer",jumpTab)
                    tipsAction(layer, cc.p(center.x + (node:getParent():getContentSize().width/2 - center.x), center.y + (node:getParent():getContentSize().height/2 - center.y)))
                    layer:setName("JumpChoseLayer")
                    node:getParent():addChild(layer)
                end  
            end
            end)
        btn3:addClickEventListener(function()
            if Bit:has(ship.status, 4) == true then
                if takeoff then
                    tips:tips(CONF:getStringValue("ship lock"))
                    return
                end
            end
            local level,isMax,enoughItem = player:canEquipStrongLv(equip)
            if level == 0 and isMax then
                tips:tips(CONF:getStringValue("max_level"))
            elseif level == 0 and enoughItem == false then
                tips:tips(CONF:getStringValue("Material_not_enought"))
                local jumpTab = {}
                for k,v in ipairs(CONF.EQUIP_STRENGTH.get(equip.strength+1).ITEM_ID) do
                    local cfg_item = CONF.ITEM.get(v)
                    if cfg_item and cfg_item.JUMP then
                        table.insert(jumpTab,cfg_item.JUMP)
                    end
                end
                if Tools.isEmpty(jumpTab) == false and not node:getParent():getChildByName("JumpChoseLayer") then
                    jumpTab.scene = "TipsInfoNode"
                    local center = cc.exports.VisibleRect:center()
                    local layer = app:createView("ShipsScene/JumpChoseLayer",jumpTab)
                    tipsAction(layer, cc.p(center.x + (node:getParent():getContentSize().width/2 - center.x), center.y + (node:getParent():getContentSize().height/2 - center.y)))
                    layer:setName("JumpChoseLayer")
                    node:getParent():addChild(layer)
                end  
            elseif level > 0 then
                local strData = Tools.encode("StrengthEquipReq", {

                    equip_guid = id,
                    count = level,
                })

                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_STRENGTH_EQUIP_REQ"),strData)
                node:removeFromParent()
                gl:retainLoading()
            end
            end)
        bg_height = bg_height + btn1:getContentSize().height + textLine
    end
    node_info:getChildByName("bg"):setContentSize(cc.size(node_info:getChildByName("bg"):getContentSize().width,bg_height))
    -- node_info:getChildByName("name_bg"):getChildByName("title"):setPosition(node_info:getChildByName("name_bg"):getContentSize().width/2,node_info:getChildByName("name_bg"):getContentSize().height/2)
    node_info:getChildByName("line"):setContentSize(cc.size(node_info:getChildByName("bg"):getContentSize().width+2,node_info:getChildByName("bg"):getContentSize().height+5))
    node_info:getChildByName("line"):setVisible(false)
    node:getChildByName("touch"):addClickEventListener(function()
        node:removeFromParent()
        end)
    return node
end

function TipsInfoNode:createSkillNode(id, takeoff,data)
    local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/TipsInfoNode.csb")
    
    local cfg_skill
    if Tools.isEmpty(data) == false then
        local skill = player:getWeaponByGUID(id)
        cfg_skill = CONF.WEAPON.get(skill.weapon_id)
    else
        cfg_skill = CONF.WEAPON.get(id)
    end
    local node_info = node:getChildByName("Node_info")
    node_info:getChildByName("name_bg"):getChildByName("title"):setString(CONF:getStringValue(cfg_skill.NAME_ID))
    local bg_height = math.abs(node_info:getChildByName("start_pos"):getPositionY())+ node_info:getChildByName("name_bg"):getContentSize().height
    local label = cc.Label:createWithTTF(CONF:getStringValue("level")..":", "fonts/cuyabra.ttf", 16)
    label:setName("label")
    label:setAnchorPoint(cc.p(0,1))
    label:setPosition(node_info:getChildByName("start_pos"):getPosition())
    label:setTextColor(cc.c4b(237, 237, 193, 255))
    -- label:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
    node_info:addChild(label)

    local label1 = cc.Label:createWithTTF(cfg_skill.LEVEL, "fonts/cuyabra.ttf", 16)
    label1:setAnchorPoint(cc.p(0,1))
    label1:setPosition(node_info:getChildByName("label"):getPositionX()+node_info:getChildByName("label"):getContentSize().width,node_info:getChildByName("label"):getPositionY())
    -- label1:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    label1:setName("label1")
    node_info:addChild(label1)
    local height1 = math.max(node_info:getChildByName("label"):getContentSize().height + textLine,node_info:getChildByName("label1"):getContentSize().height + textLine)
    bg_height = bg_height + height1


    local label2 = cc.Label:createWithTTF(CONF:getStringValue("target")..":", "fonts/cuyabra.ttf", 16)
    label2:setName("label2")
    label2:setAnchorPoint(cc.p(0,1))
    label2:setPosition(node_info:getChildByName("label"):getPositionX(),node_info:getChildByName("label"):getPositionY()-node_info:getChildByName("label"):getContentSize().height-textLine)
    label2:setTextColor(cc.c4b(237, 237, 193, 255))
    -- label2:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
    node_info:addChild(label2)

    local p1 = cfg_skill.TARGET_1
    local p2 = cfg_skill.TARGET_2

    local str1 = ""
    local str2 = ""
    if p1 == 0 then
        str1 = CONF:getStringValue("wu_text")
    else
        str1 = CONF:getStringValue("FightRange_1_"..p1)
        str2 = CONF:getStringValue("FightRange_2_"..p2)
    end

    local label3 = cc.Label:createWithTTF(str1..str2, "fonts/cuyabra.ttf", 16)
    label3:setName("label3")
    label3:setAnchorPoint(cc.p(0,1))
    label3:setPosition(node_info:getChildByName("label2"):getPositionX()+node_info:getChildByName("label2"):getContentSize().width,node_info:getChildByName("label2"):getPositionY())
    -- label3:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    node_info:addChild(label3)
    local height2 = math.max(node_info:getChildByName("label2"):getContentSize().height + textLine,node_info:getChildByName("label3"):getContentSize().height + textLine)
    bg_height = bg_height + height2

    local label4 = cc.Label:createWithTTF(CONF:getStringValue("power")..":", "fonts/cuyabra.ttf", 16)
    label4:setName("label4")
    label4:setAnchorPoint(cc.p(0,1))
    label4:setPosition(node_info:getChildByName("label2"):getPositionX(),node_info:getChildByName("label2"):getPositionY()-node_info:getChildByName("label2"):getContentSize().height-textLine)
    label4:setTextColor(cc.c4b(237, 237, 193, 255))
    -- label4:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
    node_info:addChild(label4)
    local str = cfg_skill.ATTR_PERCENT.."%"..CONF:getStringValue("Attr_3").."+"..cfg_skill.ENERGY_ATTR_PERCENT.."%"..CONF:getStringValue("Attr_20")
    local label5 = cc.Label:createWithTTF(str, "fonts/cuyabra.ttf", 16)
    label5:setAnchorPoint(cc.p(0,1))
    label5:setPosition(node_info:getChildByName("label4"):getPositionX()+node_info:getChildByName("label4"):getContentSize().width,node_info:getChildByName("label4"):getPositionY())
    label5:setLineBreakWithoutSpace(true)
    label5:setMaxLineWidth(math.abs(node_info:getChildByName("label4"):getPositionX()) - node_info:getChildByName("label4"):getContentSize().width - 3)
    label5:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    -- label5:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    label5:setName("label5")
    node_info:addChild(label5)

    local richText = createWeaponInfo(cfg_skill,16)
    richText:setPosition(label5:getPosition())
    richText:setContentSize(label5:getContentSize())
    richText:setAnchorPoint(cc.p(0,1))
    node_info:addChild(richText)
    label5:setVisible(false)
    local height3 = math.max(node_info:getChildByName("label4"):getContentSize().height + textLine,node_info:getChildByName("label5"):getContentSize().height + textLine)
    height3 = 56
    bg_height = bg_height + height3


    local label6 = cc.Label:createWithTTF(CONF:getStringValue("effect")..":", "fonts/cuyabra.ttf", 16)
    label6:setName("label6")
    label6:setAnchorPoint(cc.p(0,1))
    label6:setPosition(node_info:getChildByName("label4"):getPositionX(),node_info:getChildByName("label5"):getPositionY()-height3-textLine)
    label6:setTextColor(cc.c4b(237, 237, 193, 255))
    -- label6:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
    node_info:addChild(label6)
    local label7 = cc.Label:createWithTTF(setMemo( cfg_skill ,4), "fonts/cuyabra.ttf", 16)
    label7:setAnchorPoint(cc.p(0,1))
    label7:setPosition(node_info:getChildByName("label6"):getPositionX()+node_info:getChildByName("label6"):getContentSize().width,node_info:getChildByName("label6"):getPositionY())
    label7:setLineBreakWithoutSpace(true)
    label7:setMaxLineWidth(math.abs(node_info:getChildByName("label6"):getPositionX()) - node_info:getChildByName("label6"):getContentSize().width - 6)
    label7:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    -- label7:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
    label7:setName("label7")
    node_info:addChild(label7)

    local height4 = math.max(node_info:getChildByName("label6"):getContentSize().height + textLine,node_info:getChildByName("label7"):getContentSize().height + textLine)
    height4 = 128
    bg_height = bg_height + height4
    if Tools.isEmpty(data) == false then
        local line = node:getChildByName("line"):setVisible(true)
        line:setAnchorPoint(cc.p(0,1))
        line:setPosition(label6:getPositionX(),label7:getPositionY()-height4-textLine)
        line:setContentSize(cc.size(math.abs(node_info:getChildByName("label6"):getPositionX())*2 - math.abs(node_info:getChildByName("name_bg"):getPositionX()),2))
        bg_height = bg_height + line:getContentSize().height + textLine

        local btn = ccui.Button:create("Common/newUI/button_yellow.png","Common/newUI/button_yellow_light.png")
        btn:setAnchorPoint(cc.p(0.5,1))
        btn:setScale(0.7)
        btn:setPosition(line:getPositionX()+line:getContentSize().width/2,line:getPositionY()-line:getContentSize().height-textLine*2)
        node_info:addChild(btn)
        local btn_label = cc.Label:createWithTTF(CONF:getStringValue("STRENGTHEN_TEXT_13"), "fonts/cuyabra.ttf", 20)
        if takeoff then
            btn_label = cc.Label:createWithTTF(CONF:getStringValue("relieve"), "fonts/cuyabra.ttf", 20)
        end
        btn:addClickEventListener(function()
            if Tools.isEmpty(data) then return end
            local ship_info = player:getShipByGUID(data.ship_guid) 
            if Bit:has(ship_info.status, 4) == true then
                tips:tips(CONF:getStringValue("ship lock"))
                return
            end
            if takeoff then
                ship_info.weapon_list[data.pos] = 0
                local strData = Tools.encode("ChangeWeaponReq", {
                    type = 3,
                    ship_id = data.ship_guid,
                    weapon_list = ship_info.weapon_list,
                })
                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_WEAPON_REQ"),strData)
                node:removeFromParent()
                gl:retainLoading() 
            else
                if not data.pos then
                    tips:tips(CONF:getStringValue("choose weapon"))
                    return
                end
                if ship_info.level < CONF.PARAM.get("open_small_weapon").PARAM[data.pos] then
                    tips:tips(CONF:getStringValue("ship_level_not_enought"))
                    return
                end
                ship_info.weapon_list[data.pos] = id
                local strData = Tools.encode("ChangeWeaponReq", {
                    type = 3,
                    ship_id = data.ship_guid,
                    weapon_list = ship_info.weapon_list,
                })
                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_WEAPON_REQ"),strData)
                node:removeFromParent()
                gl:retainLoading() 
            end
            end)
        btn_label:setPosition(btn:getContentSize().width/2,btn:getContentSize().height/2)
        -- btn_label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
        btn:addChild(btn_label)
        bg_height = bg_height + btn:getContentSize().height + textLine
    else
        local label8 = cc.Label:createWithTTF(CONF:getStringValue("Attr_1")..":", "fonts/cuyabra.ttf", 16)
        label8:setName("label8")
        label8:setAnchorPoint(cc.p(0,1))
        label8:setPosition(node_info:getChildByName("label6"):getPositionX(),node_info:getChildByName("label7"):getPositionY()-node_info:getChildByName("label7"):getContentSize().height-textLine)
        label8:setTextColor(cc.c4b(237, 237, 193, 255))
        -- label8:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
        node_info:addChild(label8)
        local label9 = cc.Label:createWithTTF(cfg_skill.ENERGY..CONF:getStringValue("dot"), "fonts/cuyabra.ttf", 16)
        label9:setAnchorPoint(cc.p(0,1))
        label9:setPosition(node_info:getChildByName("label8"):getPositionX()+node_info:getChildByName("label8"):getContentSize().width,node_info:getChildByName("label8"):getPositionY())
        label9:setLineBreakWithoutSpace(true)
        label9:setMaxLineWidth(math.abs(node_info:getChildByName("label8"):getPositionX()) - node_info:getChildByName("label8"):getContentSize().width - 6)
        label9:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        -- label9:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
        label9:setName("label9")
        node_info:addChild(label9)
        local height5 = math.max(node_info:getChildByName("label8"):getContentSize().height + textLine,node_info:getChildByName("label9"):getContentSize().height + textLine)
        bg_height = bg_height + height5

        local label10 = cc.Label:createWithTTF(CONF:getStringValue("cd")..":", "fonts/cuyabra.ttf", 16)
        label10:setName("label10")
        label10:setAnchorPoint(cc.p(0,1))
        label10:setPosition(node_info:getChildByName("label8"):getPositionX(),node_info:getChildByName("label9"):getPositionY()-node_info:getChildByName("label9"):getContentSize().height-textLine)
        label10:setTextColor(cc.c4b(237, 237, 193, 255))
        -- label10:enableShadow(cc.c4b(237, 237, 193, 255),cc.size(0.2,0.2))
        node_info:addChild(label10)
        local label11 = cc.Label:createWithTTF(cfg_skill.CD.."S", "fonts/cuyabra.ttf", 16)
        label11:setAnchorPoint(cc.p(0,1))
        label11:setPosition(node_info:getChildByName("label10"):getPositionX()+node_info:getChildByName("label10"):getContentSize().width,node_info:getChildByName("label10"):getPositionY())
        label11:setLineBreakWithoutSpace(true)
        label11:setMaxLineWidth(math.abs(node_info:getChildByName("label10"):getPositionX()) - node_info:getChildByName("label10"):getContentSize().width - 6)
        label11:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
        -- label11:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.2,0.2))
        label11:setName("label11")
        node_info:addChild(label11)
        local height6 = math.max(node_info:getChildByName("label10"):getContentSize().height + textLine,node_info:getChildByName("label11"):getContentSize().height + textLine)
        bg_height = bg_height + height6
    end
    bg_height = bg_height + 8
    node_info:getChildByName("bg"):setContentSize(cc.size(node_info:getChildByName("bg"):getContentSize().width,bg_height))
    -- node_info:getChildByName("name_bg"):getChildByName("title"):setPosition(node_info:getChildByName("name_bg"):getContentSize().width/2,node_info:getChildByName("name_bg"):getContentSize().height/2)
    node_info:getChildByName("line"):setContentSize(cc.size(node_info:getChildByName("bg"):getContentSize().width+2,node_info:getChildByName("bg"):getContentSize().height+5))
    node_info:getChildByName("line"):setVisible(false)
    node:getChildByName("touch"):addClickEventListener(function()
        node:removeFromParent()
        end)
    return node
end

return TipsInfoNode