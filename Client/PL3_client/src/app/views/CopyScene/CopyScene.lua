local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local CopyScene = class("CopyScene", cc.load("mvc").ViewBase)

CopyScene.RESOURCE_FILENAME = "CopyScene/CopyScene.csb"

CopyScene.RUN_TIMELINE = true

CopyScene.NEED_ADJUST_POSITION = true

CopyScene.RESOURCE_BINDING = {
    --["Button_1"]   = {["varname"] = "btn"},
    -- ["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function CopyScene:onCreate(data)
	self.data_ = data

end

function CopyScene:OnBtnClick(event)
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

function CopyScene:onEnter()
  
    printInfo("CopyScene:onEnter()")

end

function CopyScene:onExit()
    
    printInfo("CopyScene:onExit()")
end

function CopyScene:onEnterTransitionFinish()

	printInfo("CopyScene:onEnterTransitionFinish()")


	local conf = CONF.CHECKPOINT.get(tonumber(string.format("%d", self.data_.copy_id)))

	local isBoss = false

	for i,v in ipairs(conf.MONSTER_LIST) do
		
		if v < 0 then
			isBoss = true
		end

	end

	-- if isBoss then
    -- 	self.uiLayer_ = self:getApp():createView("CopyScene/CopyBossLayer", self.data_)
   	--     self:addChild(self.uiLayer_)
   	-- else
   		self.uiLayer_ = self:getApp():createView("CopyScene/CopyOrdinaryLayer", self.data_)
   	    self:addChild(self.uiLayer_)
   	-- end

   	guideManager:checkInterface(CONF.EInterface.kCopy)

   	-- self:getResourceNode():getChildByName("close"):setLocalZOrder(100)

end


function CopyScene:onExitTransitionStart()

    printInfo("CopyScene:onExitTransitionStart()")

    if schedulerEntry ~= nil then
  	  scheduler:unscheduleScriptEntry(schedulerEntry)
  	end

end

return CopyScene