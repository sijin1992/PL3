local PanelDelegate = class("PanelDelegate")

function PanelDelegate:ctor(panel)

	self.panel_ = panel
    self.elementList_ = {}


end

function PanelDelegate:getVerticalMidElementIndex()
    local posY = self.panel_:getPositionY()
    local children = self.panel_:getChildren()
    local index = 0
    local diffY = 10000000
    for k,v in pairs(children) do
        if v:getTag() ~= 0 then
            local y = math.abs(v:convertToWorldSpace(cc.p(0,0)).y - posY)
            if y < diffY then
                diffY = y
                index = v:getTag()
            end
        end
    end

    return index
end

function PanelDelegate:getHorizontalMidElementIndex()
    local posX = self.panel_:getPositionX()
    local children = self.panel_:getChildren()
    local index = 0
    local diffX = 10000000
    for k,v in pairs(children) do
        if v:getTag() ~= 0 then
            local x = math.abs(v:convertToWorldSpace(cc.p(0,0)).x - posX)
            if x < diffX then
                diffX = x
                index = v:getTag()
            end
        end
    end

    if index < 3 then
        index = 3
    end

    if index > table.getn(children)-2 then
        index = table.getn(children) - 2
    end
    

    return index
end

function PanelDelegate:clear()
    for i,v in ipairs(self.elementList_) do

        v.obj:removeFromParent()
    end

    self.elementList_ = {}
end

function PanelDelegate:getPanel()
    return self.panel_
end


function PanelDelegate:setDirection( index,dir ) --dir  左 == 1 ，右 == 2
    self.elementList_[index].dir = dir
end

function PanelDelegate:getDirection( index )
    return self.elementList_[index].dir
end

function PanelDelegate:addElement(node, type, callback)
    
    if self.panel_ == nil then
        return
    end
 
    self.panel_:addChild(node)

    local dir = 0

    if type then
        if type == 1 then
            dir = 2
        elseif type == 0 then
            dir = 1
        end
    end

    table.insert(self.elementList_,{obj = node, dir = dir })


    if callback then
        self:addListener(callback.node, callback.func)
    end

end

function PanelDelegate:removeElement(index)
    if self.panel_ == nil then
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
    self.elementList_[index].type = nil
    table.remove(self.elementList_,index)


    -- self:resetAllElementPosition()
end

function PanelDelegate:addListener( node, func)

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

        isTouchMe = false
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
    local eventDispatcher = self.panel_:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end


return PanelDelegate