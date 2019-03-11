local MessageBoxSpeed = class("MessageBoxSpeed")

function MessageBoxSpeed:ctor()

end

function MessageBoxSpeed:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end
		
	return self.instance
end

function MessageBoxSpeed:reset(str, okfunc, cancelfunc, noCancel)

	local scene = display.getRunningScene()

	local layer = scene:getChildByName("TopMessageBoxSpeed")
	if layer ~= nil then
		layer:removeFromParent()
	end 

	layer = cc.LayerColor:create(cc.c4b( 16, 9, 2, 120))
	layer:setName("TopMessageBoxSpeed")
	scene:addChild(layer, SceneZOrder.kMessageBoxSpeed)


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


	local messageBox = require("app.ExResInterface"):getInstance():FastLoad("Common/MessageBoxSpeed.csb")
	messageBox:setPosition(cc.exports.VisibleRect:center())
    messageBox:setName("MessageBoxSpeed")
	layer:addChild(messageBox)

	messageBox:getChildByName("back"):addClickEventListener(function ( ... )

		local scene = display.getRunningScene()
		local layer = scene:getChildByName("TopMessageBoxSpeed")
		layer:removeFromParent()
	end)

	messageBox:getChildByName("text"):setString(str)

	local confirm = messageBox:getChildByName("yes")
	confirm:getChildByName("text"):setString(CONF:getStringValue("yes"))
	confirm:addClickEventListener(function ( sender )

		local scene = display.getRunningScene()
		local layer = scene:getChildByName("TopMessageBoxSpeed")

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
		local layer = scene:getChildByName("TopMessageBoxSpeed")

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

	local box = messageBox:getChildByName("CheckBox")
	box:getChildByName("text"):setString(CONF:getStringValue("check_tips"))
	local function funcbox(node,checktype)
		print("checktypechecktypechecktype",checktype)
		g_speed_up_need = checktype==0 and true or false
	end
	box:addEventListener(funcbox)

	tipsAction(messageBox)
end

return MessageBoxSpeed	