local player = require("app.Player"):getInstance()
local tips = require("util.TipsMessage"):getInstance()
local PlanetDetailType_cityReward = class("PlanetDetailType_cityReward", cc.load("mvc").ViewBase)

PlanetDetailType_cityReward.RESOURCE_FILENAME = "PlanetScene/detailNode/city_reward.csb"
PlanetDetailType_cityReward.NEED_ADJUST_POSITION = true


function PlanetDetailType_cityReward:onEnterTransitionFinish()
	local rn = self:getResourceNode()
	local list = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(3,3), cc.size(584,368))
	rn:getChildByName("list"):setScrollBarEnabled(false)
	rn:getChildByName("close"):addClickEventListener(function()
		self:removeFromParent()
		end)
	rn:getChildByName("name_bg"):getChildByName("title"):setString(CONF:getStringValue("occupy text 1"))
	for i =1,3 do
		local node,height = self:createNode(i)
		list:addElement(node,{size = cc.size(584 ,height)})
	end

	-- add wjj 20180731
	require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQMP_Judian_Jiangli(rn)
end

function PlanetDetailType_cityReward:onCreate( data )
	self.data_ = data
end

function PlanetDetailType_cityReward:createNode(rtype)
	local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/detailNode/city_rewardNode.csb")
	local title_text = CONF:getStringValue("occupy text 2")
	local str = CONF:getStringValue("occupy text 3")
	if rtype and rtype == 2 then
		str = CONF:getStringValue("occupy text 5")
		title_text = CONF:getStringValue("occupy text 4")
	end
	if rtype and rtype == 3 then
		str = CONF:getStringValue("occupy text 7")
		title_text = CONF:getStringValue("occupy text 6")
	end
	node:getChildByName("line"):getChildByName("title"):setString(title_text)
	node:getChildByName("des"):setVisible(false)

	local label = cc.Label:createWithTTF(str, s_default_font, 18 )
	label:setLineBreakWithoutSpace(true)
	label:setMaxLineWidth(node:getChildByName("des"):getContentSize().width)
	label:setPosition(node:getChildByName("des"):getPosition())
	label:setAnchorPoint(node:getChildByName("des"):getAnchorPoint())
	-- label:enableShadow(cc.c4b(255,255,255,255), cc.size(0.5,0.5))
	label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
	node:addChild(label)

	for i=1,6 do
		node:getChildByName("node"..i):setPositionY(label:getPositionY()-label:getContentSize().height-3)
	end

	local conf = CONF.PLANETCITY.get(self.data_)
	local conf_reward = CONF.REWARD.get(conf.FIRST_AWARD)
	if rtype and rtype == 2 then
		conf_reward = CONF.REWARD.get(conf.EVERYTIME_AWARD)
	end
	if rtype and rtype == 3 then
		conf_reward = CONF.REWARD.get(conf.PLAYER_AWARD)
	end

	local height = 0
	for k,v in ipairs(conf_reward.ITEM) do
		if k <= 6 then
			local itemNode = require("util.ItemNode"):create():init(v, conf_reward.COUNT[k])
			height = itemNode:getChildByName("background"):getContentSize().height + 10
			itemNode:setPosition(node:getChildByName("node"..k):getPosition())
			itemNode:setName("node_"..k)
			node:addChild(itemNode)
		else
			local itemNode = require("util.ItemNode"):create():init(v, conf_reward.COUNT[k])
			itemNode:setPosition(node:getChildByName("node"..(k-6)):getPositionX(),node:getChildByName("node"..(k-6)):getPositionY()-height)
			itemNode:setName("node_"..k)
			node:addChild(itemNode)
		end
	end

	local he = math.abs(node:getChildByName("node_"..#conf_reward.ITEM):getPositionY())+height
	return node,he
end

function PlanetDetailType_cityReward:onExitTransitionStart()
	printInfo("PlanetDetailType_cityReward:onExitTransitionStart()")
end

return PlanetDetailType_cityReward