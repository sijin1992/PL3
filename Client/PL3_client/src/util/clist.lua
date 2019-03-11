local CList = class("CList") 
function CList:ctor()
        self.m_list = { first = 0, last = -1 } 
end 
function CList:pushFront(value)
        local first = self.m_list.first - 1 
        self.m_list.first = first 
        self.m_list[first] = value 
end 
function CList:pushBack(value)
        local last = self.m_list.last + 1 
        self.m_list.last = last 
        self.m_list[last] = value 
end 
function CList:popFront()
        local first = self.m_list.first 
        if first > self.m_list.last then return nil end 
        local value = self.m_list[first] 
        self.m_list[first] = nil 
        self.m_list.first = first + 1 
        return value 
end 
function CList:popBack()
        local last = self.m_list.last 
        if self.m_list.first > last then return nil end 
        local value = self.m_list[last] 
        self.m_list[last] = nil 
        self.m_list.last = last - 1 
        return value 
end 
function CList:getSize()
        if self.m_list.first > self.m_list.last then 
                return 0 
        else 
                return math.abs(self.m_list.last - self.m_list.first) + 1 
        end 
end

function CList:empty()
        
        if self.m_list.first > self.m_list.last then 
                return true
        end 
        return false
end

function CList:front()
        if self:getSize() == 0 then
                return nil
        end
        return self.m_list[self.m_list.first]
end
function CList:back()
        if self:getSize() == 0 then
                return nil
        end
        return self.m_list[self.m_list.last]
end

return CList