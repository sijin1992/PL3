local ScrollViewDelegate = class("ScrollViewDelegate")


function ScrollViewDelegate:ctor( scrollView, diffSize, elementDefaultSize)
	self.sv_ = scrollView
	self.elementList_ = {}
	self.ds_ = diffSize

	self.eds_ = elementDefaultSize
	-- local function onEvent( event )
	-- 	--print(event.name)
	-- end
	-- self.sv_:onScroll(onEvent)
end


function ScrollViewDelegate:getScrollView()
	return self.sv_
end

function ScrollViewDelegate:setDiffSize(size)
	self.ds_ = size
end

function ScrollViewDelegate:clear()
	for i,v in ipairs(self.elementList_) do

		v.obj:removeFromParent()
	end

	self.elementList_ = {}

	self.sv_:setInnerContainerSize(self.sv_:getContentSize())
end

function ScrollViewDelegate:resetElement( index, newNode)
	
	assert(self.elementList_[index] ~= nil,"error")

	local pos = cc.p(self.elementList_[index].obj:getPosition())
	newNode:setPosition(pos)

	self.elementList_[index].obj:removeFromParent()

	self.elementList_[index].obj = newNode
	self.sv_:addChild(newNode)
end

function ScrollViewDelegate:_resetHorizontalElementPos( index )

	local pos = cc.p(self.ds_.width,self.ds_.height)
	local addtion = cc.p(0,0)


	for i=1, index - 1 do
		addtion.x = addtion.x + self.ds_.width + self.elementList_[i].config.size.width
	end

	
	pos = cc.pAdd(pos,addtion)


	local innerSize = cc.size(pos.x + self.ds_.width + self.elementList_[index].config.size.width,self.sv_:getContentSize().height)

	local cs = self.sv_:getContentSize()

	if innerSize.height < cs.height then
		innerSize.height = cs.height
	end

	if innerSize.width < cs.width then
		innerSize.width = cs.width
	end

	self.sv_:setInnerContainerSize(innerSize)

	self.elementList_[index].obj:setPosition(pos)
end

function ScrollViewDelegate:_resetVerticalElementPos( index, resetAll)


	local cs = self.sv_:getContentSize()
	local innerSize = cc.size( cs.width, self.ds_.height)

	local function needAddRow(curRowSize, config, perConfig)

		if config.newline == true or (perConfig and perConfig.nextNewline == true) then
			return true, cc.size(config.size.width + self.ds_.width*2,config.size.height) 
		end
	
		local width = curRowSize.width + config.size.width + self.ds_.width

		if width > innerSize.width then

			return true, cc.size(config.size.width + self.ds_.width*2,config.size.height) 
		else

			if config.size.height > curRowSize.height then
				curRowSize.height = config.size.height
			end
			curRowSize.width = width

			return false, curRowSize
		end
	end

	local rowSize = cc.size(self.ds_.width,0)
	for i=1,#self.elementList_ do

		local per = self.elementList_[i-1]
		
		local flag,newSize = needAddRow(rowSize, self.elementList_[i].config, per and per.config or nil)

		if flag == true then
			innerSize.height = innerSize.height + rowSize.height + self.ds_.height
		end
			
		rowSize = newSize
	end

	innerSize.height = innerSize.height + rowSize.height + self.ds_.height


	if innerSize.height < cs.height then
		innerSize.height = cs.height
	end

	if innerSize.width < cs.width then
		innerSize.width = cs.width
	end
	self.sv_:setInnerContainerSize(innerSize)


	local rowSize = cc.size(self.ds_.width,0)
	local curX = self.ds_.width
	local curY = innerSize.height - self.ds_.height


	for i=1,index do

		local per = self.elementList_[i-1]

		local flag,newSize = needAddRow(rowSize, self.elementList_[i].config, per and per.config or nil)

		local es = self.elementList_[i].config.size
		curX = newSize.width - es.width - self.ds_.width

		if flag == true then
			
			curY = curY - rowSize.height - self.ds_.height
			
		end



	
		if resetAll == true then
			self.elementList_[i].obj:setPosition(cc.p(curX,curY))
		end

		rowSize = newSize
	end

	if not resetAll or resetAll == false then
		self.elementList_[index].obj:setPosition(cc.p(curX,curY))
	end
end

function ScrollViewDelegate:resetAllElementPosition()

	if self.sv_:getDirection() == ccui.ScrollViewDir.horizontal then

		for i=1,#self.elementList_ do
			self:_resetHorizontalElementPos(#self.elementList_)
		end

	elseif self.sv_:getDirection() == ccui.ScrollViewDir.vertical then

		self:_resetVerticalElementPos(#self.elementList_, true)
	end
end

function ScrollViewDelegate:sortElement(func)
    local poslist = {}

    for k,v in ipairs(self.elementList_) do
        local pos = cc.p(v.obj:getPosition())
        table.insert(poslist,pos)
    end

    if func then
        table.sort(self.elementList_ , func)
    end

    for k,v in ipairs(self.elementList_) do
        v.obj:setPosition(poslist[k])
    end
end

function ScrollViewDelegate:addElement(node, config, nonPos)--config = {size, newline, nextNewline, callback = {node,func}}
	
	if self.sv_ == nil then
		return
	end

	if not config then
		config = {}
	end

	if not config.size then
		config.size = self.eds_
	end

	
	self.sv_:addChild(node)

	table.insert(self.elementList_,{obj = node,config = config})

	if nonPos and nonPos == true then
	
	else
		self:resetAllElementPosition()
	end


	if config.callback then
		if type(config.callback[1]) == "table" then
			for i,v in ipairs(config.callback) do
				self:addListener(v.node, v.func)
			end
		else
			self:addListener(config.callback.node, config.callback.func)
		end
	end

end

function ScrollViewDelegate:resetConfig( index, config )
	
	self.elementList_[index].config = config
end

function ScrollViewDelegate:removeElement(index)
	if self.sv_ == nil then
		return
	end


	if type(index) ~= "number" then
	
		for i,v in ipairs(self.elementList_) do
			if index == v.obj then
				index = i
				break
			end
		end
	end

	self.elementList_[index].obj:removeFromParent()
	self.elementList_[index].config = nil
	table.remove(self.elementList_,index)


	self:resetAllElementPosition()
end









function ScrollViewDelegate:addListener( node, func)

	local isTouchMe = false

	local function onTouchBegan(touch, event)

		local target = event:getCurrentTarget()
		
		local locationInNode = self.sv_:convertToNodeSpace(touch:getLocation())

		local sv_s = self.sv_:getContentSize()
		local sv_rect = cc.rect(0, 0, sv_s.width, sv_s.height)

		if cc.rectContainsPoint(sv_rect, locationInNode) then

			local ln = target:convertToNodeSpace(touch:getLocation())

			local s = target:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)
			
			if cc.rectContainsPoint(rect, ln) then
				isTouchMe = true
				return true
			end

		end

		return false
	end

	local function onTouchMoved(touch, event)

		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			isTouchMe = false
		end
	end

	local function onTouchEnded(touch, event)
		if isTouchMe == true then
				
			func(node)
		end
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self.sv_:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end







return ScrollViewDelegate