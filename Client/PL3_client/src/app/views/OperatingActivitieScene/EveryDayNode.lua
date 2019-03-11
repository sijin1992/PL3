
local EveryDayNode = class("EevryDayNode")


local player = require("app.Player"):getInstance()

function EveryDayNode:creatNode(info,num ,day) -- get:boollocal newHand = CONF.NEWHANDGIFTBAG.get(info.id)
	local node = require("app.ExResInterface"):getInstance():FastLoad("OperatingActivitieScene/EveryDatNode.csb")
	node:getChildByName("giftBagName"):setTexture("OperatingActivitieScene/ui/tt"..day..".png")
	if Tools.isEmpty(info) == false then
		for i,v in ipairs(info) do
--			local itemConf = CONF.ITEM.get(v)
            local item_node = require("util.ItemNode"):create():init(v, formatRes(num[i]))
--			local item_node = require("app.ExResInterface"):getInstance():FastLoad("ItemBag/ItemNode.csb")
			node:addChild(item_node)

			item_node:setPosition(cc.p(i%2*100 - 85  , math.floor(i/2+0.5)*-80 + 235))
	
--			item_node:getChildByName('Sprite_32'):setVisible(false)
--			item_node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..itemConf.QUALITY..".png")
--			local icon = itemConf.ICON_ID
--			item_node:getChildByName("icon"):loadTexture("ItemIcon/"..icon..".png")
--			item_node:getChildByName("level_num"):setVisible(false)
--			item_node:getChildByName("level"):setVisible(false)
--			item_node:getChildByName("num"):setString(formatRes(num[i]))
			if i >= 6 then
				break
			end
		end
	end
	
	return node
end

return EveryDayNode