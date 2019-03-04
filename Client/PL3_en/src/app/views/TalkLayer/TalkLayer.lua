local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local talkManager = require("app.views.TalkLayer.TalkManager")

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local TalkLayer = class("TalkLayer", cc.load("mvc").ViewBase)

TalkLayer.RESOURCE_FILENAME = "TalkLayer/TalkLayer.csb"

TalkLayer.RUN_TIMELINE = true

TalkLayer.NEED_ADJUST_POSITION = true

TalkLayer.RESOURCE_BINDING = {
    --["Button_1"]   = {["varname"] = "btn"},
}

local hero_id = {}

local schedulerEntry = nil

function TalkLayer:onEnter()
  
    printInfo("TalkLayer:onEnter()")

end

function TalkLayer:onExit()
    
    printInfo("TalkLayer:onExit()")
end

function TalkLayer:onCreate( data )
    if data then
        self.data_ = data
    end
end


function TalkLayer:onEnterTransitionFinish()
    printInfo("TalkLayer:onEnterTransitionFinish()")

    self.index_ = 1

    talkManager:setTalkType(true)

    print("talk_id",self.data_.talk_id)
    local conf = CONF.TALK.get(self.data_.talk_id)

    local rn = self:getResourceNode()
    local my = rn:getChildByName("my")
    local enemy = rn:getChildByName("enemy")

    local icon_id = math.floor(player:getPlayerIcon()/100)
    my:setTexture("HeroImage/"..icon_id..".png")

    local function resetInfo()
        rn:getChildByName("text"):setString(CONF:getStringValue(conf.TALK_KEY[self.index_]))
        -- rn:getChildByName("text"):setString(conf.TALK_KEY[self.index_])

        if conf.TARGET[self.index_] == 1 then
            my:setVisible(true)
            enemy:setVisible(false)
        else
            my:setVisible(false)
            enemy:setVisible(true)

            enemy:setTexture("RoleImage/"..conf.TARGET[self.index_]..".png")
        end
    end

    resetInfo()

    rn:getChildByName("background"):setSwallowTouches(true)


    -- rn:getChildByName("text_bg"):setSwallowTouches(true)
    rn:getChildByName("background"):addClickEventListener(function ( ... )
        self.index_ = self.index_ + 1

        if self.index_ <= #conf.TALK_KEY then
            resetInfo()
        else

                talkManager:addGuideStep(self.data_.talk_id)

        end
    end)

end

function TalkLayer:onExitTransitionStart()

    printInfo("TalkLayer:onExitTransitionStart()")

    if schedulerEntry ~= nil then
        scheduler:unscheduleScriptEntry(schedulerEntry)
    end

    talkManager:setTalkType(false)

end

return TalkLayer