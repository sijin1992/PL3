local TipsNode = class("TipsNode")

local player = require("app.Player"):getInstance()

function TipsNode:createWithBuyNode( text, num, func )
	local node = require("app.ExResInterface"):getInstance():FastLoad("Common/BuyNode.csb")

    node:getChildByName("queue_node"):getChildByName("open"):setString(text)
    node:getChildByName("queue_node"):getChildByName("use"):setString(CONF:getStringValue("need")..":")
    node:getChildByName("queue_node"):getChildByName("money_num"):setString(num)

    node:getChildByName("cancel"):getChildByName("text"):setString(CONF:getStringValue("cancel"))
    node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))

    node:getChildByName("cancel"):addClickEventListener(function ( ... )
        node:removeFromParent()
    end)

    node:getChildByName("yes"):addClickEventListener(function ( ... )

        if func() then
        	func()
        end

        node:removeFromParent()
    end)

    node:getChildByName("bg"):setSwallowTouches(true)
    node:getChildByName("bg"):addClickEventListener(function ( ... )
        node:removeFromParent()
    end)

    node:getChildByName("di_3"):setSwallowTouches(true)
    node:getChildByName("di_3"):addClickEventListener(function ( ... )
        -- body
    end)

    return node
end

function TipsNode:createWithUseNode( text, item_id, item_num, func )

    local type_ = 1
    if type(item_id) == "table" then
        type_ = 2
    end

    local node = require("app.ExResInterface"):getInstance():FastLoad("Common/UseNode.csb")

    node:getChildByName("queue_node"):getChildByName("open"):setString(text)

    if type_ == 1 then
        local conf = CONF.ITEM.get(item_id)

        local itemNode = require("util.ItemNode"):create():init(item_id, item_num)

        itemNode:getChildByName("num"):setString(player:getItemNumByID(item_id).."/"..item_num)
        itemNode:getChildByName("num_m"):setString(player:getItemNumByID(item_id).."/"..item_num)

        itemNode:setPosition(cc.p(node:getChildByName("item"):getPosition()))

        node:getChildByName("item"):removeFromParent()

        node:addChild(itemNode)

    else

        local items = {}

        local x,y = node:getChildByName("item"):getPosition()
        for i,v in ipairs(item_id) do

            local itemNode = require("util.ItemNode"):create():init(v, item_num[i])

            itemNode:setScale(0.8)

            table.insert(items, itemNode)

        end

        if #items%2 == 0 then
            local x,y = node:getChildByName("item"):getPosition()
            for i,v in ipairs(items) do
                v:setPosition(15 + (i-1)*100 - #items/2*100, y)
                node:addChild(v)
            end
        else
            local x,y = node:getChildByName("item"):getPosition()
            for i,v in ipairs(items) do
                v:setPosition(x + (i-1)*100 - (#items-1)/2*100, y)
                node:addChild(v)
            end
        end

        node:getChildByName("item"):removeFromParent()

    end

    node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))

    node:getChildByName("yes"):addClickEventListener(function ( ... )

        if func() then
            func()
        end

        node:removeFromParent()
    end)

    node:getChildByName("bg"):setSwallowTouches(true)
    node:getChildByName("bg"):addClickEventListener(function ( ... )
        node:removeFromParent()
    end)

    return node
end


return TipsNode