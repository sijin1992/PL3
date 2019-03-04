local animManager = require("app.AnimManager"):getInstance()


local UpgradeOverNode = class("UpgradeOverNode")

function UpgradeOverNode:ctor(node)
	self.node = node
	
end

function UpgradeOverNode:createNode(text,items)

	local str = ""
	if text then
		str = tostring(text)
	end

	playEffectSound("sound/system/upgrade_skill.mp3")
	
	local node = require("app.ExResInterface"):getInstance():FastLoad("Common/upgrade_over.csb")

	animManager:runAnimOnceByCSB(node:getChildByName("texiao"), "Common/sfx/3.csb", "1")

	local text = node:getChildByName("text")
	text:setString(str)

	text:runAction(cc.Sequence:create(cc.DelayTime:create(0.25), cc.CallFunc:create(function ( ... )
		text:setVisible(true)
	end), cc.DelayTime:create(0.25), cc.FadeOut:create(0.25), cc.CallFunc:create(function ( ... )
        if Tools.isEmpty(items) == false then
            local node2 = require("util.RewardNode"):createGettedNodeWithList(items)
--		    tipsAction(node2)
            local center = cc.exports.VisibleRect:center()
	        tipsAction(node2, cc.p(center.x + (node:getParent():getContentSize().width/2 - center.x), center.y + (node:getParent():getContentSize().height/2 - center.y)))
--            require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQuanmianping_CityGetReward(node2)
	        node:getParent():addChild(node2)
        end
        node:removeFromParent()
		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("upgradeOver")
	end)))
	
	return node
end


return UpgradeOverNode