local scheduler = cc.Director:getInstance():getScheduler()

local LongPressDelegate = class("LongPressDelegate")


function LongPressDelegate:ctor(node, fun1, fun2)

	self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
    self.count = 0
    self.isTouch = false
    self.longPress = false
    self.isMoved = false

	self.node_ = node

	local function beginhandle()
        if self.isTouch then
            self.count = self.count + 1
            if self.count >= 2 then
                self.longPress = true
                self.count = 0
                fun2()
                print("long press handle")
            end
        end
    end
   
    local function singleClick()
        scheduler:unscheduleScriptEntry(self.oneHandle)   
        self.count = 0
        fun1()
        print("single click handle")
    end
   
    local function doubleClick()
        scheduler:unscheduleScriptEntry(self.twoHandle)
        self.count = 0
        fun1()
        print("double click handle")
    end
   
    local function threeClick()
        self.count = 0
        fun1()
     	print("tree click handle")
    end

    local function eventTouch(ref, type)
        if ref == node then
            if type == ccui.TouchEventType.began then
                self.isTouch = true
                self.beginHandle = scheduler:scheduleScriptFunc(beginhandle,1,false)    
           
            elseif type == ccui.TouchEventType.moved then
                self.isMoved = true
               
            elseif type == ccui.TouchEventType.ended then
                scheduler:unscheduleScriptEntry(self.beginHandle)
                self.isTouch = false
                if self.longPress then
                    self.longPress = false
                    self.count = 0
                    return false
                    -- fun2()
                end
                if self.isMoved then
                 self.isMoved = false
                 return false
                end
                if self.count == 2 then
                 threeClick()
                 self.count = 0
                    scheduler:unscheduleScriptEntry(self.oneHandle)
                    scheduler:unscheduleScriptEntry(self.twoHandle)
                   
                elseif self.count == 1 then
                    scheduler:unscheduleScriptEntry(self.oneHandle)
                    self.twoHandle = scheduler:scheduleScriptFunc(doubleClick,0.25,false)
                    self.count = self.count + 1
                elseif self.count == 0 then
                    self.oneHandle = scheduler:scheduleScriptFunc(singleClick,0.25,false)
                    self.count = self.count + 1
                end       
            end
        end
    end
    node:addTouchEventListener(eventTouch)

end

function LongPressDelegate:getNode( ... )
	return self.node_
end

return LongPressDelegate