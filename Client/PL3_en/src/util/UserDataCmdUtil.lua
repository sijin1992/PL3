



local VisibleRect = cc.exports.VisibleRect


local UserDataCmdUtil = class("UserDataCmdUtil")

local default = cc.p(1136,768)

function UserDataCmdUtil:ctor()
    
    local winSize = cc.Director:getInstance():getWinSize()
    self.diffSize_ = cc.size((winSize.width - CC_DESIGN_RESOLUTION.width)/2,(winSize.height - CC_DESIGN_RESOLUTION.height)/2)
end

function UserDataCmdUtil:getInstance()
    if self.instance == nil then
        self.instance = self:create()
    end
        
    return self.instance
end



function UserDataCmdUtil:getDiffSize()
    return self.diffSize_
end

function UserDataCmdUtil:execute( children )


    -- local function setPos( cmd, node )
    --     local origin = nil

    --     local relativePos = nil

    --     local curOrigin = nil

    --     if cmd == "leftbottom" then

    --         origin = cc.p(0,0)
    --         curOrigin = VisibleRect:leftBottom()

    --     elseif cmd == "rightbottom"  then

    --         origin = cc.p(default.x,0)
    --         curOrigin = VisibleRect:rightBottom()

    --     elseif cmd == "righttop"  then

    --         origin = cc.p(default.x,default.y)
    --         curOrigin = VisibleRect:rightTop()

    --     elseif cmd == "lefttop"  then

    --         origin = cc.p(0,default.y)
    --         curOrigin = VisibleRect:leftTop()

    --     elseif cmd == "left"  then

    --         origin = cc.p(0,default.y/2)
    --         curOrigin = VisibleRect:left()

    --     elseif cmd == "bottom"  then

    --         origin = cc.p(default.x/2,0)
    --         curOrigin = VisibleRect:bottom()

    --     elseif cmd == "right"  then

    --         origin = cc.p(default.x,default.y/2)
    --         curOrigin = VisibleRect:right()
            
    --     elseif cmd == "top"  then

    --         origin = cc.p(default.x/2,default.y)
    --         curOrigin = VisibleRect:top()

    --     else
            
    --     end

    --     if nil ~= origin or nil ~= curOrigin then
    --         local x,y = node:getPosition()
    --         -- printInfo("diffsize %d %d",self.diffSize_.width,self.diffSize_.height)
    --         -- printInfo("pos %d %d",x,y)
    --         -- printInfo("origin %d %d",origin.x,origin.y)
    --         -- printInfo("curOrigin %d %d",curOrigin.x,curOrigin.y)
    --         relativePos = cc.pSub(cc.p(node:getPosition()),origin)
    --         -- printInfo("relativePos %d %d",relativePos.x,relativePos.y)
    --         local p  = cc.pAdd(curOrigin,relativePos)
    --         p = cc.p(p.x - self.diffSize_.width,p.y - self.diffSize_.height)
    --         node:setPosition(p)
    --         -- printInfo("p %d %d",p.x,p.y)
    --     end
    -- end

    local function setPos( cmd, node)
        setScreenPosition(node, cmd)
    end

    local cmdType = { 
    leftbottom = setPos,
    rightbottom = setPos,
    righttop = setPos,
    lefttop = setPos,
    left = setPos,
    bottom = setPos,
    right = setPos,
    top = setPos,
    }


    local function doCmd( cmd, node )
        assert(cmdType[cmd] ~= nil,string.format("error: no cmd : %s", cmd) )
        cmdType[cmd](cmd,node)
    end








    for i= 1, #children do

        local child = children[i]

        --self:execute( child )

        if nil ~= child then

            local userData = child:getCustomProperty()
            
            local t = Tools.split(userData, ",")

            for k,v in pairs(t) do
                doCmd(v,child)
            end


        end
    end
end

return UserDataCmdUtil