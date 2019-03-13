local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local animManager = require("app.AnimManager"):getInstance()

local TrialCopyScene = class("TrialCopyScene", cc.load("mvc").ViewBase)

TrialCopyScene.RESOURCE_FILENAME = "CopyScene/CopyScene.csb"

TrialCopyScene.RUN_TIMELINE = true

TrialCopyScene.NEED_ADJUST_POSITION = true

TrialCopyScene.RESOURCE_BINDING = {
    --["Button_1"]   = {["varname"] = "btn"},
    -- ["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function TrialCopyScene:onCreate(data)
	self.data_ = data

end

function TrialCopyScene:OnBtnClick(event)
    printInfo(event.name)

  --   if event.name == "ended" and event.target:getName() == "close" then
  --   	printInfo("close")

  --   	local stageStr = nil
		-- if self.data_.stage < 10 then
		-- 	stageStr = string.format("0%d", self.data_.stage)
		-- else
		-- 	stageStr = string.format("%d", self.data_.stage)
		-- end

		-- local modeStr = nil
		-- if self.data_.model == 1 then
		-- 	modeStr = "Easy"
		-- elseif self.data_.model == 2 then
		-- 	modeStr = "Normal"
		-- elseif self.data_.model == 3 then
		-- 	modeStr = "Hard"
		-- end

  --   	self:getApp():pushToRootView("StageScene/StageScene", {area = self.data_.area, stage = self.data_.stage, stageStr = stageStr, slPosX = self.data_.slPosX, modeStr = modeStr})
  --   end

end

function TrialCopyScene:onEnter()
  
    printInfo("TrialCopyScene:onEnter()")

end

function TrialCopyScene:onExit()
    
    printInfo("TrialCopyScene:onExit()")
end

function TrialCopyScene:onEnterTransitionFinish()

	printInfo("TrialCopyScene:onEnterTransitionFinish()")


	local conf = CONF.TRIAL_LEVEL.get(self.data_.level_id)

	local isBoss = false

	for i,v in ipairs(conf.MONSTER_ID) do
		
		if v < 0 then
			isBoss = true
			break
		end

	end


		-- if isBoss then
	 --    	self.uiLayer_ = self:getApp():createView("TrialScene/TrialCopyBossLayer", self.data_)
	 --   	    self:addChild(self.uiLayer_)
	 --   	else
	   		self.uiLayer_ = self:getApp():createView("TrialScene/TrialCopyOrdinaryLayer", self.data_)
	   	    self:addChild(self.uiLayer_)
	   	-- end

   	-- self:getResourceNode():getChildByName("close"):setLocalZOrder(100)

end


function TrialCopyScene:onExitTransitionStart()

    printInfo("TrialCopyScene:onExitTransitionStart()")

    if schedulerEntry ~= nil then
  	  scheduler:unscheduleScriptEntry(schedulerEntry)
  	end

end

return TrialCopyScene