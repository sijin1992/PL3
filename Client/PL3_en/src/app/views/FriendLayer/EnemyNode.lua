
local EnemyNode = class("EnemyNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

EnemyNode.RESOURCE_FILENAME = "FriendLayer/enemy_list.csb"

function EnemyNode:onEnterTransitionFinish()

end

function EnemyNode:init(scene,data)

	self.scene_ = scene

	self.select_index = 0

	local rn = self:getResourceNode()
	rn:getChildByName("text"):setVisible(false)
    rn:getChildByName("Text_1"):setString(CONF:getStringValue("sumNum"))
    --rn:getChildByName("text"):setString(CONF:getStringValue("ListIsEmpty"))

	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(2,10), cc.size(584,66))

    local function createListItem( ... )
        local node = require("app.ExResInterface"):getInstance():FastLoad("FriendLayer/enemy_list_item.csb")

        node:getChildByName("botton"):getChildByName("text"):setString(CONF:getStringValue("delete"))
        node:getChildByName("xingmeng"):setString(CONF:getStringValue("covenant")..":")
        node:getChildByName("botton"):addClickEventListener(function( ... )
            print("shanchu")
        end)

        return node
    end

	for i=1,20 do
		local item = createListItem()
        item:setTag(i)
        item:setName("item_"..i)

        local func = function( ... )
            if self.select_index ~= 0 then 

                self:selectItem(self.svd_:getScrollView():getChildByName("item_"..self.select_index), false)

                if item:getTag() == self.select_index then
                    self.select_index = 0
                    return
                else 
                    self:selectItem(item, true)

                    self.select_index = item:getTag()
                end
            else
                self:selectItem(item, true)

                self.select_index = item:getTag()
            end
        end

        local callback = {node = item:getChildByName("background"), func = func}

        self.svd_:addElement(item, {callback = callback})

	end
    
end

function EnemyNode:selectItem(item, flag)
    if flag then

        item:getChildByName("select"):setVisible(true)
        item:getChildByName("select_front"):setVisible(true)

        item:getChildByName("kuang"):setTexture("FriendLayer/ui/player_light.png")
        item:getChildByName("background"):loadTexture("FriendLayer/ui/player_botton_light.png")

        item:getChildByName("name"):setScale(1.1)
        item:getChildByName("lv"):setScale(1.1)
        item:getChildByName("lv_num"):setScale(1.1)
        item:getChildByName("fight"):setScale(0.33)
        item:getChildByName("fight_num"):setScale(1.1)
        item:getChildByName("xingmeng"):setScale(1.1)
        item:getChildByName("xingmeng_name"):setScale(1.1)
        item:getChildByName("head"):setScale(0.955)
        
    else
        item:getChildByName("select"):setVisible(false)
        item:getChildByName("select_front"):setVisible(false)

        item:getChildByName("kuang"):setTexture("FriendLayer/ui/player_dark.png")
        item:getChildByName("background"):loadTexture("FriendLayer/ui/player_botton_drak.png")       

        item:getChildByName("name"):setScale(1)
        item:getChildByName("lv"):setScale(1)
        item:getChildByName("lv_num"):setScale(1)
        item:getChildByName("fight"):setScale(0.3)
        item:getChildByName("fight_num"):setScale(1)
        item:getChildByName("xingmeng"):setScale(1)
        item:getChildByName("xingmeng_name"):setScale(1)
        item:getChildByName("head"):setScale(0.945)

    end

    --item:getChildByName("lv"):setPositionX(item:getChildByName("name"):getPositionX() + item:getChildByName("name"):getContentSize().width*item:getChildByName("name"):getScale() + 20)
    --item:getChildByName("lv_num"):setPositionX(item:getChildByName("lv"):getPositionX() + item:getChildByName("lv"):getContentSize().width*item:getChildByName("lv"):getScale() + 10)
    item:getChildByName("fight_num"):setPositionX(item:getChildByName("fight"):getPositionX() + item:getChildByName("fight"):getContentSize().width/2*item:getChildByName("fight"):getScale() + 10)
    item:getChildByName("xingmeng_name"):setPositionX(item:getChildByName("xingmeng"):getPositionX() + item:getChildByName("xingmeng"):getContentSize().width*item:getChildByName("xingmeng"):getScale() + 5)
end

function EnemyNode:onExitTransitionStart()
    printInfo("EnemyNode:onExitTransitionStart()")

end

return EnemyNode