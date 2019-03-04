
local animManager = require("app.AnimManager"):getInstance()

local RewardNode = class("RewardNode")

local RUNTIME = 0.1

function RewardNode:ctor(node)
	self.node = node
end

function RewardNode:createNode( reward_id, func, rnNode )
	local node = require("app.ExResInterface"):getInstance():FastLoad("Common/RewardNode.csb")

	node:getChildByName("bg"):setSwallowTouches(true)
	node:getChildByName("bg"):addClickEventListener(function ( sender )
			node:removeFromParent()
			if rnNode ~= nil then
				local tip = self:createRewardTip(reward_id);
				tip:setPosition(cc.exports.VisibleRect:top());
				rnNode:addChild(tip);
			end
	end)

	node:getChildByName("blue"):setSwallowTouches(true)

	local reward_conf = CONF.REWARD.get(reward_id)

	local items = {}

	for i,v in ipairs(reward_conf.ITEM) do

		local itemNode = require("util.ItemNode"):create():init(v, reward_conf.COUNT[i])
		
		table.insert(items, itemNode)
		
	end

	if #items%2 == 0 then
		local x,y = node:getChildByName("item"):getPosition()
		for i,v in ipairs(items) do
			v:setPosition(cc.p(15 + (i-1)*100 - #items/2*100, y))
			node:addChild(v)
		end
	else
		local x,y = node:getChildByName("item"):getPosition()
		for i,v in ipairs(items) do
			v:setPosition(cc.p(x + (i-1)*100 - (#items-1)/2*100, y))
			node:addChild(v)
		end
	end 

	node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("Get"))
	node:getChildByName("yes"):addClickEventListener(function ( ... )
		if func then
			func()
		end

		node:removeFromParent()
	end)

	node:getChildByName("item"):removeFromParent()

	return node
end

function RewardNode:createNodeWithList( item_list, type, func, show_sfx, rnNode ) --1成功2失败
	local node = require("app.ExResInterface"):getInstance():FastLoad("Common/RewardNode.csb")

	node:getChildByName("bg"):setSwallowTouches(true)
	node:getChildByName("bg"):addClickEventListener(function ( sender )
			node:removeFromParent()
			if rnNode ~= nil then
				local tip = self:createRewardListTip(item_list, type, func, show_sfx);
				tip:setPosition(cc.exports.VisibleRect:top());
				rnNode:addChild(tip);
			end
	end)

	node:getChildByName("blue"):setSwallowTouches(true)

	local items = {}

	for i,v in ipairs(item_list) do

		local itemName 

		if type == 1 then
			itemName = v.id
		elseif type == 2 then
			itemName = v.key
		end

		if itemName ~= 0 then

			local conf = CONF.ITEM.get(itemName)

			local itemNode 

			if type == 1 then
				itemNode = require("util.ItemNode"):create():init(itemName, v.num)

			elseif type == 2 then
				itemNode = require("util.ItemNode"):create():init(itemName, v.value)
				
			end

			table.insert(items, itemNode)
		end
	end
	node:getChildByName("list"):setVisible(true)
	local svd =  require("util.ScrollViewDelegate"):create(node:getChildByName("list"),cc.size(7,3), cc.size(90,90))
	node:getChildByName("list"):setScrollBarEnabled(false)
	if #items <= 3 then
		if #items%2 == 0 then
			local x,y = node:getChildByName("item"):getPosition()
			for i,v in ipairs(items) do
				v:setPosition(cc.p(15 + (i-1)*100 - #items/2*100, y))
				node:addChild(v)
			end
		else
			local x,y = node:getChildByName("item"):getPosition()
			for i,v in ipairs(items) do
				v:setPosition(cc.p(x + (i-1)*100 - (#items-1)/2*100, y))
				node:addChild(v)
			end
		end 
	else
		for k,v in ipairs(items) do
			svd:addElement(v)
		end
	end
	node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("Get"))
	node:getChildByName("yes"):addClickEventListener(function ( sender )
		if func then
			func()
		end

		node:removeFromParent()
	end)

	node:getChildByName("item"):removeFromParent()


	

	if show_sfx ~= nil then
		if show_sfx then
			animManager:runAnimOnceByCSB(node:getChildByName("success"), "ForgeScene/sfx/Success.csb", "1")
			node:getChildByName("success"):getChildByName("hecheng_success"):setString(CONF:getStringValue("hecheng_success"))
			node:getChildByName("success"):getChildByName("hecheng_success"):setScale(0.5)
			node:getChildByName("success"):setVisible(true)
			node:getChildByName("success"):setLocalZOrder(10)
		else
			animManager:runAnimOnceByCSB(node:getChildByName("defeat"), "ForgeScene/sfx/Defeat.csb", "1")
			node:getChildByName("defeat"):getChildByName("hecheng_fail"):setString(CONF:getStringValue("hecheng_fail"))
			node:getChildByName("defeat"):getChildByName("hecheng_fail"):setScale(0.5)
			node:getChildByName("defeat"):setVisible(true)
			node:getChildByName("defeat"):setLocalZOrder(10)
		end
	end

	return node
end

function RewardNode:createGettedNodeWithList( item_list, func, rnNode,crit)
	local node = require("app.ExResInterface"):getInstance():FastLoad("Common/GettedRewardNode.csb")
	node:getChildByName("baoji"):setVisible(false)
	if crit then
		node:getChildByName("baoji"):setVisible(true)
		animManager:runAnimOnceByCSB(node:getChildByName("baoji"), "BlueprintScene/baoji.csb", "animation0")
	end
	node:getChildByName("bg"):setSwallowTouches(true)
	node:getChildByName("bg"):addClickEventListener(function ( sender )

			if func then
				func()
			end

			node:removeFromParent()
            cc.exports.clickTaskReward = false
            if cc.exports.levelup_param ~= nil then 
                createLevelUpNode(cc.exports.levelup_param[1],cc.exports.levelup_param[2])
                cc.exports.levelup_param = nil
            end
--            cc.exports.GettedRewardListNode = nil
			if rnNode ~= nil then
				local tip = self:createRewardTipFromList(item_list, type, func)
				tip:setPosition(cc.exports.VisibleRect:top())
				rnNode:addChild(tip)
			end
	end)

	node:getChildByName("title"):setString(CONF:getStringValue("get_reward"))

	node:getChildByName("text"):setString(CONF:getStringValue("click_continue"))
	
	local items = {}

	for i,v in ipairs(item_list) do

		local item_id = v.id


		if item_id ~= 0 then

			local conf = CONF.ITEM.get(item_id)

			local itemNode = require("util.ItemNode"):create():init(item_id, v.num)	
			

			table.insert(items, itemNode)
		end
	end

	if #items%2 == 0 then
		local x,y = node:getChildByName("item"):getPosition()
		for i,v in ipairs(items) do
			v:setPosition(cc.p(15 + (i-1)*100 - #items/2*100, y))
			node:addChild(v)
		end
	else
		local x,y = node:getChildByName("item"):getPosition()
		for i,v in ipairs(items) do
			v:setPosition(cc.p(x + (i-1)*100 - (#items-1)/2*100, y))
			node:addChild(v)
		end
	end 

	node:getChildByName("item"):removeFromParent()

	animManager:runAnimOnceByCSB(node, "Common/GettedRewardNode.csb", "1")
--    cc.exports.GettedRewardListNode = node
	return node
end

function RewardNode:createRewardTip(reward_id, func)
	local rewardTip = cc.Node:create()
	--local bg = rewardTip:getChildByName("bg");

	local reward_conf = CONF.REWARD.get(reward_id)
	local items = {}

	local action1 = cc.Spawn:create(cc.ScaleTo:create(RUNTIME, 1), cc.FadeIn:create(RUNTIME));
	local action2 = cc.Spawn:create(cc.ScaleTo:create(RUNTIME, 0.001), cc.FadeOut:create(RUNTIME));
	rewardTip:setScale(1.7);
	rewardTip:setOpacity(0);

	local action = cc.Sequence:create(action1, action2, cc.CallFunc:create(function ()
		rewardTip:removeFromParent();
	end))

	rewardTip:runAction(action);

	for i,v in ipairs(reward_conf.ITEM) do

		local itemNode = require("util.ItemNode"):create():init(v, reward_conf.COUNT[i])
		
		table.insert(items, itemNode)
		
	end
	
	if #items > 3 then
		--bg:setScale9Enabled(true);
		--bg:setContentSize({width = 92 * #items + 20 , height = 82});
	else

	end

	local startPos = #items / 2;
	for i=1,#items do
		rewardTip:addChild(items[i]);
		items[i]:setPosition(startPos * (-49) + (i-1) * 92 , -28)
	end

	if #items == 1 then
		items[1]:setPosition(-46, -28);
	end


	return rewardTip;
end

function RewardNode:createRewardListTip( item_list , type, func , show_sfx )
	local rewardTip = cc.Node:create();
	--local bg = rewardTip:getChildByName("bg");

	local action1 = cc.Spawn:create(cc.ScaleTo:create(RUNTIME, 1), cc.FadeIn:create(RUNTIME));
	local action2 = cc.Spawn:create(cc.ScaleTo:create(RUNTIME, 0.001), cc.FadeOut:create(RUNTIME));
	rewardTip:setScale(1.7);
	rewardTip:setOpacity(0);

	local action = cc.Sequence:create(action1, action2, cc.CallFunc:create(function ()
		rewardTip:removeFromParent();
	end))

	rewardTip:runAction(action);

	local items = {}

	for i,v in ipairs(item_list) do

		local itemName 

		if type == 1 then
			itemName = v.id
		elseif type == 2 then
			itemName = v.key
		end

		if itemName ~= 0 then

			local conf = CONF.ITEM.get(itemName)

			local itemNode 

			if type == 1 then
				itemNode = require("util.ItemNode"):create():init(itemName, v.num)

			elseif type == 2 then
				itemNode = require("util.ItemNode"):create():init(itemName, v.value)
				
			end

			table.insert(items, itemNode)
		end
	end

	local startPos = #items / 2;
	for i=1,#items do
		rewardTip:addChild(items[i]);
		items[i]:setPosition(startPos * (-49) + (i-1) * 92 , -28)
	end

	return rewardTip;
end

function RewardNode:createRewardTipFromList(item_list, func)
	local node = cc.Node:create();
	--local bg = node:getChildByName("bg");
	--bg:setSwallowTouches(true)
	--[[bg:addClickEventListener(function ( sender )

			if func then
				func()
			end

			node:removeFromParent()
	end)]]--

	--node:getChildByName("title"):setString(CONF:getStringValue("get_reward"))
	--node:getChildByName("text"):setString(CONF:getStringValue("click_continue"))
	local action1 = cc.Spawn:create(cc.ScaleTo:create(RUNTIME, 1), cc.FadeIn:create(RUNTIME));
	local action2 = cc.Spawn:create(cc.ScaleTo:create(RUNTIME, 0.001), cc.FadeOut:create(RUNTIME));
	node:setScale(1.7);
	node:setOpacity(0);

	local action = cc.Sequence:create(action1, action2, cc.CallFunc:create(function ()
		node:removeFromParent();
	end))

	node:runAction(action);

	local items = {}

	for i,v in ipairs(item_list) do

		local item_id = v.id


		if item_id ~= 0 then

			local conf = CONF.ITEM.get(item_id)

			local itemNode = require("util.ItemNode"):create():init(item_id, v.num)	
			

			table.insert(items, itemNode)
		end
	end

	local startPos = #items / 2;
	for i=1,#items do
		node:addChild(items[i]);
		items[i]:setPosition(startPos * (-49) + (i-1) * 92 , -28)
	end



	return node;
end

return RewardNode