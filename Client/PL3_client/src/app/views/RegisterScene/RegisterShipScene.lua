
local FileUtils = cc.FileUtils:getInstance()

local VisibleRect = cc.exports.VisibleRect

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local RegisterShipScene = class("RegisterShipScene", cc.load("mvc").ViewBase)

RegisterShipScene.RESOURCE_FILENAME = "RegisterScene/RegisterShipScene.csb"

RegisterShipScene.RUN_TIMELINE = true

RegisterShipScene.NEED_ADJUST_POSITION = true

RegisterShipScene.RESOURCE_BINDING = {
}

local headIcon = {141001,115002,111001,111000,142002}

local type_color = {cc.c4b(156,226,255,255), cc.c4b(247,255,165,255), cc.c4b(166,255,227,255), cc.c4b(188,211,255,255)}

RegisterShipScene.lagHelper = require("util.ExLagHelper"):getInstance()
RegisterShipScene.IS_SCENE_TRANSFER_EFFECT = false

function RegisterShipScene:onCreate()

end


function RegisterShipScene:onEnter()
    
    printInfo("RegisterShipScene:onEnter()")
end

function RegisterShipScene:onExit()
    
    printInfo("RegisterShipScene:onExit()")

end

function RegisterShipScene:clickHead( index )

    self.index_ = index 

    local rn = self:getResourceNode()
    local conf = CONF.PARAM.get("start_ships_"..index)
    local res_id = CONF.AIRSHIP.get(conf.PARAM[1]).ICON_ID
    rn:getChildByName("ship"):setTexture("ShipImage/"..res_id..".png")

    if index == 1 then
        rn:getChildByName("pic"):setTexture("RegisterScene/ui/atk_pic.png")
    elseif index == 2 then
        rn:getChildByName("pic"):setTexture("RegisterScene/ui/def_pic.png")
    elseif index == 3 then
        rn:getChildByName("pic"):setTexture("RegisterScene/ui/fz_pic.png")
    elseif index == 4 then
        rn:getChildByName("pic"):setTexture("RegisterScene/ui/tre_pic.png")
    end

    for i=1,4 do
        local driverNode = rn:getChildByName("driverNode_"..i)
        if i == index then
            -- driverNode:getChildByName("select_1"):setVisible(true)
            -- driverNode:getChildByName("select_2"):setVisible(true)
            driverNode:getChildByName("background"):loadTexture("Common/newUI/cj_button_light.png")

--            driverNode:getChildByName("clippingNode"):getChildByName("sprite"):setTexture("RoleIcon/"..res_id..".png")
            driverNode:getChildByName("clippingNode"):getChildByName("sprite"):setTexture("ShipType/"..i..".png")

            self:resetInfo(index)
        else
            -- driverNode:getChildByName("select_1"):setVisible(false)
            -- driverNode:getChildByName("select_2"):setVisible(false)
            driverNode:getChildByName("background"):loadTexture("Common/newUI/cj_button.png")

            driverNode:getChildByName("clippingNode"):getChildByName("sprite"):setTexture("ShipType/"..i..".png")
        end
    end
end

function RegisterShipScene:resetInfo( index )
    local conf = CONF.AIRSHIP.get(CONF.PARAM.get("start_ships_"..index).PARAM[1])
    local lightAttr = CONF.PARAM.get("start_ships_Attr_"..index).PARAM

    local rn = self:getResourceNode()
    rn:getChildByName("name"):setString(CONF:getStringValue(conf.NAME_ID))

    if index == 1 then
        rn:getChildByName("type"):setTextColor(cc.c4b(156,226,255,255))
    elseif index == 2 then
        rn:getChildByName("type"):setTextColor(cc.c4b(247,255,165,255))
    elseif index == 3 then
        rn:getChildByName("type"):setTextColor(cc.c4b(188,211,255,255))
    elseif index == 4 then
        rn:getChildByName("type"):setTextColor(cc.c4b(166,255,227,255))
    end

    rn:getChildByName("type"):setString(CONF:getStringValue("ship_type_"..index))
    rn:getChildByName("ins"):setString("  "..CONF:getStringValue("ship_type_"..index.."_memo"))

    rn:getChildByName("big"):setString(CONF:getStringValue("weapon_text_1"))
    rn:getChildByName("skill_icon"):loadTexture("WeaponIcon/"..conf.SKILL..".png")
    rn:getChildByName("skill_icon"):addClickEventListener(function ( ... )
        self:createInfoNode()
    end)

    rn:getChildByName("atk"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kAttack))
    rn:getChildByName("treatment"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kSpeed))
    rn:getChildByName("def"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kDefence))
    rn:getChildByName("hp"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kHP))
    rn:getChildByName("crit"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kCrit))
    rn:getChildByName("dodge"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kDodge))
    rn:getChildByName("target"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kHit))
    rn:getChildByName("e_atk"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kEnergyAttack))
    --lightAttr
    local Attrtab = {"atk","treatment","def","hp","crit","dodge","target","e_atk"}
    local Attrtabid = {CONF.EShipAttr.kAttack,CONF.EShipAttr.kSpeed,CONF.EShipAttr.kDefence,CONF.EShipAttr.kHP,CONF.EShipAttr.kCrit,CONF.EShipAttr.kDodge,CONF.EShipAttr.kHit,CONF.EShipAttr.kEnergyAttack}
    for k,v in ipairs(Attrtab) do
        if TableFindValue(lightAttr,Attrtabid[k]) == 0 then
            rn:getChildByName(v):setTextColor(cc.c4b(219,231,235,255))
        else
            rn:getChildByName(v):setTextColor(cc.c4b(0,255,0,255))
        end
    end
end

function RegisterShipScene:createDriverNode( id,index )
    local driverNode = require("app.ExResInterface"):getInstance():FastLoad("RegisterScene/DriverNode.csb")

    local icon = driverNode:getChildByName("icon")
    local bg = driverNode:getChildByName("background")

    local sprite = cc.Sprite:create("RoleIcon/"..id..".png")
    sprite:setScale(1.1)
    sprite:setName("sprite")

    local sp = cc.Sprite:create("StarOccupationLayer/ui/mask_black.png")
    sp:setScale(1.53)

    local clippingNode = cc.ClippingNode:create()
    clippingNode:setStencil(sp)
    clippingNode:setInverted(false)
    clippingNode:setAlphaThreshold(0.5)
    clippingNode:addChild(sprite)
    clippingNode:setName("clippingNode")

    driverNode:addChild(clippingNode)
    clippingNode:setPosition(cc.p(icon:getPositionX(),icon:getPositionY()))

    icon:removeFromParent()

    driverNode:setTag(id)

    bg:addClickEventListener(function ( ... )
        self:clickHead(index)
    end)

    return driverNode
end

function RegisterShipScene:createInfoNode()
    local conf = CONF.AIRSHIP.get(CONF.PARAM.get("start_ships_"..self.index_).PARAM[1])

    local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/FormShipInfo.csb")
    node:getChildByName("Image_3"):loadTexture("ShipImage/"..conf.ICON_ID..".png")
    node:getChildByName("ship_bg"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
--    node:getChildByName("ship_icon"):loadTexture("RoleIcon/"..conf.ICON_ID..".png")
    node:getChildByName("ship_icon"):setVisible(false)
    node:getChildByName("ship_icon2"):setVisible(true)
    node:getChildByName("ship_icon2"):setTexture("ShipImage/"..conf.DRIVER_ID..".png")
    node:getChildByName("ship_name"):setString(CONF:getStringValue(conf.NAME_ID))
    node:getChildByName("ship_fight_num"):setString(player:getEnemyPower(conf.ID))
    node:getChildByName("quality"):setTexture("ShipQuality/quality_"..conf.QUALITY..".png")
    node:getChildByName("ship_type"):loadTexture("ShipType/"..conf.TYPE..".png")
    node:getChildByName("ship_lv_num"):removeFromParent()

    node:getChildByName("ship_hp"):setString(CONF:getStringValue("Airship")..CONF:getStringValue("Attr_2"))
    node:getChildByName("ship_hp_num"):setString(conf.LIFE)
    node:getChildByName("ship_atk"):setString(CONF:getStringValue("Attr_3"))
    node:getChildByName("ship_atk_num"):setString(conf.ATTACK)
    node:getChildByName("ship_def"):setString(CONF:getStringValue("Airship")..CONF:getStringValue("Attr_4"))
    node:getChildByName("ship_def_num"):setString(conf.DEFENCE)
    node:getChildByName("ship_speed"):setString(CONF:getStringValue("Attr_5"))
    node:getChildByName("ship_speed_num"):setString(conf.SPEED)
    node:getChildByName("ship_e_atk"):setString(CONF:getStringValue("Attr_20"))
    node:getChildByName("ship_e_atk_num"):setString(conf.ENERGY_ATTACK)
    node:getChildByName("ship_dur"):setString(CONF:getStringValue("durable_2"))
    node:getChildByName("ship_dur_num"):setString(conf.DURABLE)
    node:getChildByName("ship_dur_max"):setString("/"..conf.DURABLE)

    local diff = 100
    node:getChildByName("ship_hp_num"):setPositionX(node:getChildByName("ship_hp"):getPositionX() + diff)
    node:getChildByName("ship_atk_num"):setPositionX(node:getChildByName("ship_atk"):getPositionX() + diff)
    node:getChildByName("ship_def_num"):setPositionX(node:getChildByName("ship_def"):getPositionX() + diff)
    node:getChildByName("ship_speed_num"):setPositionX(node:getChildByName("ship_speed"):getPositionX() + diff)
    node:getChildByName("ship_e_atk_num"):setPositionX(node:getChildByName("ship_e_atk"):getPositionX() + diff)
    node:getChildByName("ship_dur_num"):setPositionX(node:getChildByName("ship_dur"):getPositionX() + diff)
    node:getChildByName("ship_dur_max"):setPositionX(node:getChildByName("ship_dur_num"):getPositionX() + node:getChildByName("ship_dur_num"):getContentSize().width)

    node:getChildByName("ship_upgrade"):removeFromParent()
    for i=1,6 do
        node:getChildByName("star_"..i):removeFromParent()
    end

    self.svd_ = require("util.ScrollViewDelegate"):create(node:getChildByName("list"), cc.size(0,0), cc.size(386,480))

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

    node:getChildByName("ok"):getChildByName("text"):setString(CONF:getStringValue("yes"))
    node:getChildByName("ok"):addClickEventListener(function ( ... )
        node:removeFromParent()

    end)

    node:getChildByName("back"):setSwallowTouches(true)
    node:getChildByName("back"):addClickEventListener(function ( ... )
        node:removeFromParent()
    end)

    local rn = self:getResourceNode()
    node:setPosition(cc.p(rn:getChildByName("node_pos"):getPosition()))
    node:setName("info_node")
    rn:addChild(node)
end

function RegisterShipScene:onEnterTransitionFinish()
    printInfo("RegisterShipScene:onEnterTransitionFinish()")

    if device.platform == "ios" or device.platform == "android" then
        TDGAMission:onBegin("RegisterShip")
        buglySetTag(6)
    end

    local rn = self:getResourceNode()

    animManager:runAnimOnceByCSB(rn, "RegisterScene/RegisterShipScene.csb", "intro", function ( ... )
        guideManager:checkInterface(25)
    end)

    rn:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("departure"))
    rn:getChildByName("xxx"):setString(CONF:getStringValue("recruit ship"))

    rn:getChildByName("wen"):addClickEventListener(function ( ... )
        self:createInfoNode()
    end)

    for i=1,4 do
        local conf = CONF.PARAM.get("start_ships_"..i)
        local driverNode = self:createDriverNode(conf.PARAM[1], i)
        driverNode:setName("driverNode_"..i)
        driverNode:setPosition(cc.p(rn:getChildByName("player"..i):getPosition()))
        rn:addChild(driverNode)
        driverNode:setOpacity(0)

        rn:getChildByName("player"..i):setVisible(false)
    end

    for i=1,4 do
        local dn = rn:getChildByName("driverNode_"..i)
        dn:runAction(cc.Sequence:create(cc.DelayTime:create(0.1*(i-1)), cc.FadeIn:create(0.2)))
    end

    self:clickHead(1)

    rn:getChildByName("btn"):addClickEventListener(function ( ... )

        -- self.type = "reg"
        print("index,",self.index_)
        local strData = Tools.encode("RegistInitShipReq", {
            init_index = self.index_,
        })

        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_REG_INIT_SHIP_REQ"),strData)

        gl:retainLoading()
    end)

    local function recvMsg()
        --print("CityScene:recvMsg")
        local cmd,strData = GameHandler.handler_c.recvProtobuf()

        if cmd == Tools.enum_id("CMD_DEFINE","CMD_REG_INIT_SHIP_RESP") then

            gl:releaseLoading()

            local proto = Tools.decode("RegistInitShipResp",strData)
            printInfo("RegistInitShipResp")
            printInfo(proto.result)

            if proto.result == 0 then

                if device.platform == "ios" or device.platform == "android" then
                    TDGAMission:onCompleted("RegisterShip")
                    TDGAMission:onBegin("GreenHand")
                end
                -- if self.type == "reg" then
                --     self.type = "log"
                --     GameHandler.handler_c.connect()
                -- else
                guideManager:addGuideStep(2)

		if(self.IS_SCENE_TRANSFER_EFFECT) then
			-- EDIT BY WJJ 20180702
			self.lagHelper:BeginTransferEffect("RegisterScene/RegisterShipScene")
		else
                        self:getApp():pushToRootView("CityScene/CityScene", {pos = -1350})
		end
                -- end
            end

        end

    end

    self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)


	-- ADD WJJ 20180723
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_SelectShipScene(self)
end

function RegisterShipScene:onExitTransitionStart()
    printInfo("RegisterShipScene:onExitTransitionStart()")
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListener(self.recvlistener_)

    
end

return RegisterShipScene