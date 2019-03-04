
local ShopNode = class("ShopNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

ShopNode.RESOURCE_FILENAME = "ArenaScene/shop.csb"

function ShopNode:onEnterTransitionFinish()

end

function ShopNode:resetList(typeName)

	self.svd_:clear()


	local num = 0
	if typeName == "circle_1" then
		num = 2
	elseif typeName == "circle_2" then
		num = 5
	elseif typeName == "circle_3" then
		num = 20
	elseif typeName == "circle_4" then
		num = 10 
	end

	for i=1,num do
		local node = require("app.ExResInterface"):getInstance():FastLoad("ArenaScene/shop_item.csb")
		self.svd_:addElement(node)
	end

end

function ShopNode:init(scene,data)

	self.scene_ = scene

	local rn = self:getResourceNode()
	local eventDispatcher = self:getEventDispatcher()

	rn:getChildByName("close"):addClickEventListener(function ( ... )
		self:removeFromParent()
	end)

	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(10,10), cc.size(100,160))
	

	self:resetList("circle_1")

	self.td_ = require("util.LabsDelegate"):create(function (target)

			self:resetList(target:getName())
		
	end, nil, nil, eventDispatcher, 
	{rn:getChildByName("circle_1"), "ArenaScene/red_circle.png", "ArenaScene/white_circle.png"}, 
	{rn:getChildByName("circle_2"), "ArenaScene/red_circle.png", "ArenaScene/white_circle.png"}, 
	{rn:getChildByName("circle_3"), "ArenaScene/red_circle.png", "ArenaScene/white_circle.png"}, 
	{rn:getChildByName("circle_4"), "ArenaScene/red_circle.png", "ArenaScene/white_circle.png"})

end


function ShopNode:onExitTransitionStart()
	printInfo("ShopNode:onExitTransitionStart()")

end

return ShopNode