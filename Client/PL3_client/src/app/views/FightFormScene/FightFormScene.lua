local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local FightFormScene = class("FightFormScene", cc.load("mvc").ViewBase)

FightFormScene.RESOURCE_FILENAME = "CopyScene/CopyScene.csb"

FightFormScene.RUN_TIMELINE = true

FightFormScene.NEED_ADJUST_POSITION = true

FightFormScene.RESOURCE_BINDING = {
}

local schedulerEntry = nil

function FightFormScene:onCreate(data)
	self.data_ = data

end

function FightFormScene:OnBtnClick(event)
    printInfo(event.name)

end

function FightFormScene:onEnter()
  
    printInfo("FightFormScene:onEnter()")

end

function FightFormScene:onExit()
    
    printInfo("FightFormScene:onExit()")
end

function FightFormScene:onEnterTransitionFinish()

	printInfo("FightFormScene:onEnterTransitionFinish()")

	-- if isBoss then
    -- 	self.uiLayer_ = self:getApp():createView("CopyScene/CopyBossLayer", self.data_)
   	--     self:addChild(self.uiLayer_)
   	-- else
   		self.uiLayer_ = self:getApp():createView("FightFormScene/FightFormLayer", self.data_)
   	    self:addChild(self.uiLayer_)
   	-- end

	print( string.format( "@@@@ FightFormScene from: %s", tostring(self.data_.from) ) )
   	if self.data_.from == "copy" then
		print(string.format( "@@@@ FightFormScene checkInterface: %s", tostring(CONF.EInterface.kCopy) ) )
   		guideManager:checkInterface(CONF.EInterface.kCopy)
   	end

end


function FightFormScene:onExitTransitionStart()

    printInfo("FightFormScene:onExitTransitionStart()")

    if schedulerEntry ~= nil then
  	  scheduler:unscheduleScriptEntry(schedulerEntry)
  	end

end

return FightFormScene