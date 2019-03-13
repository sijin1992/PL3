local MessageBox = class("MessageBox")

function MessageBox:ctor()

end

function MessageBox:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end
		
	return self.instance
end

function MessageBox:reset(str, okfunc, cancelfunc, noCancel)

	local scene = display.getRunningScene()

	local layer = scene:getChildByName("TopMessageBox")
	if layer ~= nil then
		layer:removeFromParent()
	end 

	layer = cc.LayerColor:create(cc.c4b( 16, 9, 2, 120))
	layer:setName("TopMessageBox")
	scene:addChild(layer, SceneZOrder.kMessageBox)


	-- local function onTouchBegan(touch, event)

	-- 	return true
	-- end

	-- local function onTouchEnded( touch, event )
	-- 	local scene = display.getRunningScene()
	-- 	local layer = scene:getChildByName("TopMessageBox")
	-- 	layer:removeFromParent()
	-- end


	-- local listener = cc.EventListenerTouchOneByOne:create()
	-- listener:setSwallowTouches(true)
	-- listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	-- listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

	-- local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	-- eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)


	local messageBox = require("app.ExResInterface"):getInstance():FastLoad("Common/MessageBox.csb")
	messageBox:setPosition(cc.exports.VisibleRect:center())
	layer:addChild(messageBox)

	messageBox:getChildByName("back"):addClickEventListener(function ( ... )

		local scene = display.getRunningScene()
		local layer = scene:getChildByName("TopMessageBox")
		layer:removeFromParent()
	end)

	messageBox:getChildByName("text"):setString(str)

	local confirm = messageBox:getChildByName("yes")
	confirm:getChildByName("text"):setString(CONF:getStringValue("yes"))
	confirm:addClickEventListener(function ( sender )

		local scene = display.getRunningScene()
		local layer = scene:getChildByName("TopMessageBox")

		if layer ~= nil then
			layer:removeFromParent()
		end

		if okfunc then
			okfunc()
		end
		
	end)

	local cancel = messageBox:getChildByName("cancel")
	cancel:getChildByName("text"):setString(CONF:getStringValue("cancel"))
	cancel:addClickEventListener(function ( sender )
		local scene = display.getRunningScene()
		local layer = scene:getChildByName("TopMessageBox")

		if layer ~= nil then
			layer:removeFromParent()
		end
		
		if cancelfunc then
			cancelfunc()
		end
		
	end)

	if noCancel ~= nil and noCancel == true then
		cancel:setVisible(false)
		confirm:setPositionX(0)
	end

	tipsAction(messageBox)
end

return MessageBox	