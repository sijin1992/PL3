local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local app = require("app.MyApp"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local ActivityFirstRechargeNode = class("ActivityFirstRechargeNode", cc.load("mvc").ViewBase)

ActivityFirstRechargeNode.RESOURCE_FILENAME = "ActivityScene/FirstRecharge.csb"

ActivityFirstRechargeNode.RUN_TIMELINE = true

ActivityFirstRechargeNode.NEED_ADJUST_POSITION = true

ActivityFirstRechargeNode.RESOURCE_BINDING = {
    --["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

function ActivityFirstRechargeNode:onEnter()
  
    printInfo("ActivityFirstRechargeNode:onEnter()")

end

function ActivityFirstRechargeNode:onExit()
    
    printInfo("ActivityFirstRechargeNode:onExit()")
end


function ActivityFirstRechargeNode:onEnterTransitionFinish()
    printInfo("ActivityFirstRechargeNode:onEnterTransitionFinish()")

    local rn = self:getResourceNode()

    local idd = 0
    for i,v in ipairs(CONF.ACTIVITY.getIDList()) do
        if CONF.ACTIVITY.get(v).TYPE == 7 then
            idd = v
        end
    end

    local conf = CONF.ACTIVITYFIRSTRECHARGE.get(idd)

    rn:getChildByName('Text_3'):setString(CONF:getStringValue('close_click'))
    rn:getChildByName("background"):setSwallowTouches(true)
    rn:getChildByName("background"):addClickEventListener(function ( ... )
        -- app:removeTopView()
        self:removeFromParent()
    end)


    if player:getRechargeNum() == 0 then
        rn:getChildByName("go_ToRecharge"):loadTextures("ActivityScene/ui/btn_buy_black.png","ActivityScene/ui/btn_buy_light.png")
        rn:getChildByName("go_ToRecharge"):addClickEventListener(function ( ... )
            -- app:removeTopView()
            self:removeFromParent()

            cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("firstRecharge")
        end)
    else

        local info = player:getActivity(idd)
        rn:getChildByName("go_ToRecharge"):loadTextures("ActivityScene/ui/btn_get_black.png","ActivityScene/ui/btn_get_light.png")
        rn:getChildByName("go_ToRecharge"):addClickEventListener(function ( ... )
            local strData = Tools.encode("ActivityFirstRechargeReq", {
                activity_id = idd,
            })
            GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_FIRST_RECHARGE_REQ"),strData)

            gl:retainLoading()
        end)

        if info then
            if info.first_recharge_data.getted_reward then
                rn:getChildByName("go_ToRecharge"):setEnabled(false)
            else


            end
        else
            
        end
    end

    local x,y = rn:getChildByName("itemNode"):getPosition()

    local shipNode = require("app.ExResInterface"):getInstance():FastLoad("Common/ItemNode.csb")
    shipNode:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..CONF.AIRSHIP.get(conf.SHIP).QUALITY..".png")
    shipNode:getChildByName("icon"):loadTexture("ShipImage/"..CONF.AIRSHIP.get(conf.SHIP).ICON_ID..".png")

    shipNode:getChildByName("icon"):addClickEventListener(function ( ... )
        if display:getRunningScene():getChildByName("info_node") then
            display:getRunningScene():getChildByName("info_node"):removeFromParent()
        end

        local info_node = require("util.ItemInfoNode"):createShipInfoNode(conf.SHIP)

        local center = cc.exports.VisibleRect:center()
        local bg = info_node:getChildByName("landi")
        info_node:setPosition(cc.p(center.x - bg:getContentSize().width/2*bg:getScaleX(), center.y + bg:getContentSize().height/2*bg:getScaleY()))
        info_node:setName("info_node")
        display:getRunningScene():addChild(info_node, SceneZOrder.kItemInfo)
    end)

    shipNode:setPosition(cc.p(x,y))
    rn:addChild(shipNode)

    for i,v in ipairs(conf.ITEM) do
        local itemNode = require("util.ItemNode"):create():init(v, conf.NUM[i])
        itemNode:setPosition(cc.p(x + i*100, y))
        rn:addChild(itemNode)
    end

    tipsAction(self, cc.p(0,0))


    local function recvMsg( )
        local cmd,strData = GameHandler.handler_c.recvProtobuf()
        if cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_FIRST_RECHARGE_RESP") then 
            gl:releaseLoading()

            local proto = Tools.decode("ActivityFirstRechargeResp",strData)

            print("ActivityFirstRechargeResp", proto.result)
            if proto.result ~= 0 then 
                print("ActivityFirstRechargeResp error", proto.result)
            else 
                rn:getChildByName("go_ToRecharge"):setEnabled(false)
            end
        end
    end

    self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
    animManager:runAnimByCSB(rn:getChildByName("ship_sfx"), "ActivityScene/sfx/shouchong/shouchong.csb", "1")
end

function ActivityFirstRechargeNode:onExitTransitionStart()

    printInfo("ActivityFirstRechargeNode:onExitTransitionStart()")
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListener(self.recvlistener_)

    if schedulerEntry ~= nil then
        scheduler:unscheduleScriptEntry(schedulerEntry)
    end

end

return ActivityFirstRechargeNode