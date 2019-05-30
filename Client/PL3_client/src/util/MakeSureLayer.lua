local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local MakeSureLayer = class("MakeSureLayer")

function MakeSureLayer:createNormal(func,str)
	local node = require("app.ExResInterface"):getInstance():FastLoad("Common/makeSure.csb")
	-- node:getChildByName("uibg"):addClickEventListener(function ( sender )
	-- 	self:removeFromParent()
	-- end)
	node:getChildByName("uibg"):setSwallowTouches(true)
	node:getChildByName("Text_1_0_0_0"):setString(str)
	node:getChildByName("buy_SureBtn"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	node:getChildByName("cancel"):getChildByName("text"):setString(CONF:getStringValue("cancel"))
	node:getChildByName("buy_SureBtn"):addClickEventListener(function()
		func()
		node:removeFromParent()
		end)
	node:getChildByName("cancel"):addClickEventListener(function()
		node:removeFromParent()
		end)
	return node
end

function MakeSureLayer:createOneBtn(func,str)
	local node = require("app.ExResInterface"):getInstance():FastLoad("Common/makeSure.csb")
	node:getChildByName("uibg"):setSwallowTouches(true)
	node:getChildByName("Text_1_0_0_0"):setString(str)
    node:getChildByName("OneBtn"):getChildByName("text"):setString(CONF:getStringValue("yes"))
    node:getChildByName("buy_SureBtn"):setVisible(false)
    node:getChildByName("cancel"):setVisible(false)
    node:getChildByName("OneBtn"):setVisible(true)
	node:getChildByName("OneBtn"):addClickEventListener(function()
		func()
		node:removeFromParent()
		end)
	return node
end


function MakeSureLayer:onExitTransitionStart()
	printInfo("MakeSureLayer:onExitTransitionStart()")
end

return MakeSureLayer