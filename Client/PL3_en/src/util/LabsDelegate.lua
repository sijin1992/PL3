local LabsDelegate = class("LabsDelegate")

local function resetTexture(obj, textureName, size, textColor)
    if tolua.type(obj) == "cc.Sprite" then
        obj:setTexture(textureName)
    elseif tolua.type(obj) == "ccui.ImageView" then
 
        obj:loadTexture(textureName)
        if size then
            obj:setContentSize(size)
        end
    end

    local text = obj:getChildByName("text")
    if text ~= nil and textColor ~= nil then
        text:setTextColor(textColor)
        print("textColor",textColor.r,textColor.g,textColor.b)

        -- text:enableShadow(textColor,cc.size(0.5,0.5))
    end
end

function LabsDelegate:select( targetName )



    for i,v in ipairs(self.labs_) do
        if v[1]:getName() ~= targetName then
            local str = v[3] and v[3] or self.normal_
            if str then
                resetTexture(v[1], str, v[5], self._normalColor)
            end
            
        else
            local str = v[2] and v[2] or self.select_
            if str then
                resetTexture(v[1], str, v[4], self._selectColor)
            end
            self.callback_(v[1])
        end
    end

    
end

function LabsDelegate:ctor( callback, select, normal, eventDispatcher, ... )
    self.labs_ = {...} --{{obj,select,normal,selectsize, normalsize},{obj,select,normal,selectsize, normalsize}}

    self.callback_ = callback

    self.select_ = select
    self.normal_ = normal

    local function onTouchBegan(touch, event)

    local target = event:getCurrentTarget()

    if tolua.type(target) ~= "cc.Sprite" and tolua.type(target) ~= "ccui.ImageView" then
        return
    end



    local locationInNode = target:convertToNodeSpace(touch:getLocation())
    local s = target:getContentSize()
    local rect = cc.rect(0, 0, s.width, s.height)

    if cc.rectContainsPoint(rect, locationInNode) then

        self:select(target:getName())

        return true
    end

        return false
    end


    for i,v in ipairs(self.labs_) do

        assert(v[1] ~= nil, "no this child")

        local listener = cc.EventListenerTouchOneByOne:create()
        listener:setSwallowTouches(true)
        listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

        eventDispatcher:addEventListenerWithSceneGraphPriority(listener, v[1])
    end

end


function LabsDelegate:setTextColor( selectColor, normalColor )
    self._selectColor = selectColor
    self._normalColor = normalColor
end

return LabsDelegate