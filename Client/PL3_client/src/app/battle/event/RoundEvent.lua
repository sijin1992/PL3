
local RoundEvent = class("RoundEvent",require("app.battle.event.BattleEvent"))
local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()
local talkManager = require("app.views.TalkLayer.TalkManager"):getInstance()
local player = require("app.Player"):getInstance()

function RoundEvent:ctor(data,bm)
	self.bm = bm

	self.round_ = data.values[1]


	--assert(data.attack_list == nil,"error")
end

function RoundEvent:start()

	self.bm:getUINode():getChildByName("round"):setString(string.format("%d", self.round_))

end

function RoundEvent:process(dt)
	
	return true
end

function RoundEvent:finish()
	-- if self.bm:getBattleScene():getBattleType() == BattleType.kTest then
	-- 	if self.round_ == 5 and g_Player_Guide < 104 then
	-- 		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BattlePause")
	-- 		self.bm:getBattleScene():getApp():pushToRootView("TestFormScene")
	-- 	end

	-- 	if self.round_ == 2 then

	-- 		if g_Player_Guide < 104 then
	-- 			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BattlePause")
	-- 			guideManager:createGuideLayer(102)
	-- 		elseif g_Player_Guide > 104 then
	-- 			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BattlePause")
	-- 			guideManager:createGuideLayer(106)
	-- 		end
	-- 	end
	-- end

	if self.round_ == 1 then

		if player:isInited() then
			if self.bm:getBattleScene():getBattleType() == BattleType.kCheckPoint then
				local talk_id = talkManager:getPlayerTalkID()
				talk_id = talk_id and talk_id or 0
				local conf = CONF.TALK.check(talk_id+1)
				if conf == nil then

				else
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BattlePause")

					g_Player_Battle_Talk = 0
					talkManager:addTalkLayer(1,self.bm:getBattleScene():getData().checkpoint_id)
				end
			end
		end
	end

end

return RoundEvent