local OpenCollectMail = class("OpenCollectMail", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

OpenCollectMail.RESOURCE_FILENAME = "MailLayer/CollectLayer.csb"

OpenCollectMail.RESOURCE_BINDING = {
    ["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
    ["btnGet"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function OpenCollectMail:OnBtnClick(event)
    local rn = self:getResourceNode()
    if event.name == "ended" then

        if event.target:getName() == "close" then

            self:removeFromParent()           
        end
    end
end

function OpenCollectMail:onEnterTransitionFinish()

end

function OpenCollectMail:init(mailList, id)
    local rn = self:getResourceNode()
    -- self.mail ={}
    -- for i,v in ipairs(mailList) do
    --     if v.guid == id then 
    --         self.mail = v
    --         break
    --     end
    -- end

    local function onTouchBegan( event, touch )
        return true
    end
    local eventDispatcher = self:getEventDispatcher()
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, rn)
end

function OpenCollectMail:createItem( item , num , index , id)

end

function OpenCollectMail:onExitTransitionStart()
    print("OpenCollectMail:onExitTransitionStart()")

end

return OpenCollectMail