
local PropConvertNode = class("PropConvertNode")
local player = require("app.Player"):getInstance()
local interval = 70
function PropConvertNode:ctor()
    printInfo("PropConvertNode:ctor()")
end

function PropConvertNode:init(data)
    printInfo("PropConvertNode:init()")
    local rnnode = nil
    if data.isOperat then
        rnnode = require("app.ExResInterface"):getInstance():FastLoad("OperatingActivitieScene/PropConvertNode.csb")
    else
        interval = 56
        rnnode = require("app.ExResInterface"):getInstance():FastLoad("ActivityScene/ConvertNode.csb")
    end
    self.node_ = rnnode
    self.data_ = data
    local conf = self.data_.conf
    local Node_convert = self.node_:getChildByName("bg"):getChildByName("Node_convert")
    local Node_get = self.node_:getChildByName("bg"):getChildByName("Node_get")

    local function getFirstPoX(totalnum)
        local firPosX
        local intnum = math.floor(totalnum/2)
        if totalnum%2 == 0 then
            firPosX = 0 - ((intnum-1+0.5)*interval)
        else
            firPosX = 0 - (intnum*interval)
        end
        return firPosX
    end
    local firPosX_convert = getFirstPoX(#conf.COST_ITEM)
    local firPosX_get = getFirstPoX(#conf.GET_ITEM)
    -- needitems
    local hasitem = true
    for k,v in ipairs(conf.COST_ITEM) do
        local itemNode = require("util.ItemNode"):create():init(v, formatRes(conf.COST_NUM[k]))
        if not self.data_.isOperat then
            itemNode:setScale(0.8)
        end
        local pos = cc.p(firPosX_convert + (k-1)*interval,itemNode:getPositionY())
        itemNode:setPosition(pos)
        Node_convert:addChild(itemNode)
        if player:getItemNumByID(v) < conf.COST_NUM[k] then
            hasitem = false
        end
    end
    -- getitems
    for k,v in ipairs(conf.GET_ITEM) do
        local itemNode = require("util.ItemNode"):create():init(v, formatRes(conf.GET_NUM[k]))
        if not self.data_.isOperat then
            itemNode:setScale(0.8)
        end
        local pos = cc.p(firPosX_get + (k-1)*interval,itemNode:getPositionY())
        itemNode:setPosition(pos)
        Node_get:addChild(itemNode)
    end
    -- text¡¢button
    local num = tonumber(self.data_.conf.LIMIT) - tonumber(self.data_.time)
    self.node_:getChildByName("bg"):getChildByName("num"):setString(tostring(num))
    self.node_:getChildByName("bg"):getChildByName("Text"):setString(CONF:getStringValue("residue degree"))
    self.node_:getChildByName("bg"):getChildByName("bt"):getChildByName("Bt_Text"):setString(CONF:getStringValue("DUIHUAN"))
    if num <= 0 then
        self.node_:getChildByName("bg"):getChildByName("num"):setColor(cc.c3b(255,0,0))
        self.node_:getChildByName("bg"):getChildByName("bt"):setEnabled(false)
    else
        self.node_:getChildByName("bg"):getChildByName("num"):setColor(cc.c3b(0,255,0))
        if hasitem then
            self.node_:getChildByName("bg"):getChildByName("bt"):setEnabled(true)
        else
            self.node_:getChildByName("bg"):getChildByName("bt"):setEnabled(false)
        end
    end
    return self.node_
end

return PropConvertNode