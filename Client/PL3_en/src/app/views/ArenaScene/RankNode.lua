
local RankNode = class("RankNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

RankNode.RESOURCE_FILENAME = "ArenaScene/rank.csb"

function RankNode:onEnterTransitionFinish()

end

function RankNode:init(scene,data)

	self.scene_ = scene

    local rn = self:getResourceNode()

    rn:getChildByName("close"):addClickEventListener(function ( ... )
        self:removeFromParent()
    end)

    self.list_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(10,10), cc.size(700,70))
    
    local function createRankItem(info)
        local node = require("app.ExResInterface"):getInstance():FastLoad("ArenaScene/rank_item.csb")

        -- node:getChildByName("rank_num"):setString(info.rank)
        -- if info.rank <= 3 then
        -- end

        -- node:getChildByName("player_name"):setString()
        -- node:getChildByName("lv_num"):setString()
        -- node:getChildByName("fight_num"):setString()

        return node

    end

    for i=1,10 do
        local item = createRankItem()
        self.list_:addElement(item)
    end

end


function RankNode:onExitTransitionStart()
    printInfo("RankNode:onExitTransitionStart()")

end

return RankNode