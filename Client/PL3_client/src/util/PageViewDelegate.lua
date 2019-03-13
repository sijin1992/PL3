local PageViewDelegate = class("PageViewDelegate")

function PageViewDelegate:ctor(pageView)

	self.pv_ = pageView
	-- self.layoutList_ = {}

end

function PageViewDelegate:getPageView()
	return self.pv_
end

function PageViewDelegate:addNode(node)

	if self.pv_ == nil then
		return
	end

	local layout = ccui.Layout:create()
	layout:setContentSize(self.pv_:getContentSize())

	layout:addChild(node)

	self.pv_:addPage(layout)

end

function PageViewDelegate:insertNode(node, index)
	if self.pv_ == nil then
		return
	end

	local layout = ccui.Layout:create()
	layout:setContentSize(self.pv_:getContentSize())

	layout:addChild(node)

	self.pv_:insertPage(layout, index)
end

function PageViewDelegate:addListener(node, func)

	local isTouchMe = false

	local function onTouchBegan(touch, event)

		local target = event:getCurrentTarget()
		
		local locationInNode = target:convertToNodeSpace(touch:getLocation())
		local s = target:getContentSize()
		local rect = cc.rect(0, 0, s.width, s.height)
		
		if cc.rectContainsPoint(rect, locationInNode) then
			isTouchMe = true
			return true
		end

		return false
	end

	local function onTouchMoved(touch, event)

		local diff = touch:getDelta()
		if math.abs(diff.x) < g_click_delta and math.abs(diff.y) < g_click_delta then
			
		else
			isTouchMe = false
		end
	end

	local function onTouchEnded(touch, event)
		if isTouchMe == true then
				
			func(node)
		end
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self.pv_:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)

end

return PageViewDelegate