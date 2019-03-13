
local WinEvent = class("WinEvent",require("app.battle.event.BattleEvent"))

local tips = require("util.TipsMessage"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local talkManager = require("app.views.TalkLayer.TalkManager"):getInstance()

local player = require("app.Player"):getInstance()

WinEvent.IS_CLEAR_MEMORY_ON_BATTLE_END = true

function WinEvent:ctor(data,bm)

	self.bm = bm

	-- resultData[1] = isWin
	-- resultData[2] = self:getFightTime()
	-- resultData[3] = self:getHitValue(1)
	-- resultData[4] = self:getHitValue(2)
	-- resultData[5] = myShipLiveNum
	-- resultData[6] = self:getShipNum(1,false)
	-- resultData[7] = enemyShipLiveNum
	-- resultData[8] = self:getShipNum(2,false)
	-- resultData[9] = self.round_

	self.data = data.values
	self.data[10] = data.attack_hp_list
	self.data[11] = data.hurter_hp_list

	self.hp_list = nil
	if data.id == 1 then
		self.hp_list = data.attack_hp_list
	end

	self.talk_finish = false
end

function WinEvent:start()

	scheduler:setTimeScale(1)

	self.talkListener_ = cc.EventListenerCustom:create("talk_over", function ()

		self.talk_finish = true
	end)
	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.talkListener_, FixedPriority.kNormal)

	if self.bm:getBattleScene():getBattleType() == BattleType.kCheckPoint then
		local talk_id = talkManager:getPlayerTalkID()
		talk_id = talk_id and talk_id or 0
		local conf = CONF.TALK.check(talk_id+1)
	
		if self.data[1] == 1 and (talk_id == nil or conf ~= nil) then
			if player:isInited() then
				g_Player_Battle_Talk = 1
				talkManager:addTalkLayer(1, self.bm:getBattleScene():getData().checkpoint_id)
			end
		else
			self.talk_finish = true
		end
	else
		self.talk_finish = true
	end

end

function WinEvent:process(dt)
	
	return self.talk_finish
end

function WinEvent:finish()

	scheduler:setTimeScale(1)

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:removeEventListener(self.talkListener_)
	self.talkListener_ = nil

	local battleType = self.bm:getBattleScene():getBattleType()
	local enemyName = self.bm:getBattleScene():getEnemyName()
	local ship_list = self.bm:getBattleScene():getAttackList()

	print("WinEvent, battleType",battleType)
	if battleType == BattleType.kTrial then

		local level_id = self.bm:getBattleScene():getData().level_id

		if self.data[1] == 1 then
			local layer = require("app.views.BattleScene.TrialWinLayer"):create()
			layer:init(level_id,self.data, self.hp_list)
			self.bm:getBattleScene():addChild(layer)
			layer:setLocalZOrder(100)
		else
			local layer = require("app.views.BattleScene.TrialFailedLayer"):create()
			layer:init(level_id,self.data, self.hp_list)
			self.bm:getBattleScene():addChild(layer)
			layer:setLocalZOrder(100)
		end
	elseif battleType == BattleType.kCheckPoint then

		local checkpoint_id = self.bm:getBattleScene():getData().checkpoint_id
		if self.data[1] == 1 then
			-- ADD WJJ 20180713
			if( self.IS_CLEAR_MEMORY_ON_BATTLE_END ) then
				local _data = { ["checkpoint_id"] = checkpoint_id,
					["data"] = self.data,
					["enemyName"] = enemyName,
					["ship_list"] = ship_list }
				cc.exports.isTotalReleaseMemoryOnce = true
				local layer = require("app.MyApp"):getInstance():pushToRootView("BattleScene/WinLayer", _data)
				-- layer:init(checkpoint_id,self.data,enemyName,ship_list)
			else
				local layer = require("app.views.BattleScene.WinLayer"):create()
				layer:init(checkpoint_id,self.data,enemyName,ship_list)
				self.bm:getBattleScene():addChild(layer)
				layer:setLocalZOrder(100)
			end
		else
			-- ADD WJJ 20180713
			if( self.IS_CLEAR_MEMORY_ON_BATTLE_END ) then
				local _data = { ["checkpoint_id"] = checkpoint_id,
					["data"] = self.data }
				cc.exports.isTotalReleaseMemoryOnce = true
				local layer = require("app.MyApp"):getInstance():pushToRootView("BattleScene/FailedLayer", _data)
				-- layer:init(checkpoint_id,self.data)
			else
				local layer = require("app.views.BattleScene.FailedLayer"):create()
				layer:init(checkpoint_id,self.data)
				self.bm:getBattleScene():addChild(layer)
				layer:setLocalZOrder(100)
			end
		end
	elseif battleType == BattleType.kTest then

		guideManager:createGuideLayer(117)
		-- self.bm:getBattleScene():getApp():pushToRootView("RegisterScene/RegisterPlayerScene")
		
	elseif battleType == BattleType.kArena then

		if self.data[1] == 1 then
			local layer = require("app.views.BattleScene.ArenaWinLayer"):create()
			layer:init(battleType)
			self.bm:getBattleScene():addChild(layer)
			layer:setLocalZOrder(100)
		else
			local layer = require("app.views.BattleScene.ArenaFailedLayer"):create()
			layer:init(battleType)
			self.bm:getBattleScene():addChild(layer)	
			layer:setLocalZOrder(100)
		end

	elseif battleType == BattleType.kPlanetRes or battleType == BattleType.kPlanetRuins or battleType == BattleType.kPlanetRaid then

		local area_id = self.bm:getBattleScene():getData().area_id
		if self.data[1] == 1 then
			local layer = require("app.views.BattleScene.StarWinLayer"):create()
			layer:init(self.data,battleType,ship_list, area_id)
			self.bm:getBattleScene():addChild(layer)
			layer:setLocalZOrder(100)
		else
			local layer = require("app.views.BattleScene.StarFailedLayer"):create()
			layer:init(self.data, battleType,ship_list, area_id)
			self.bm:getBattleScene():addChild(layer)
			layer:setLocalZOrder(100)
		end

	elseif battleType == BattleType.kGroupBoss then

		local id = self.bm:getBattleScene():getData().group_boss_id

		local layer = require("app.views.BattleScene.GroupBossLayer"):create()
		layer:init( id, self.data)
		self.bm:getBattleScene():addChild(layer)
		layer:setLocalZOrder(100)

	elseif battleType == BattleType.kSlave or battleType == BattleType.kSaveFriend or battleType == BattleType.kSlaveEnemy then

		local data = self.bm:getBattleScene():getData()

		print("WinEvent, getData", data)

		print("data.result",data.result)

		print("data req", data.req.user_name)

		if self.data[1] == 1 then

			local layer = require("app.views.BattleScene.ArenaWinLayer"):create()
			layer:init(battleType, data)
			self.bm:getBattleScene():addChild(layer)
			layer:setLocalZOrder(100)
		else
			local layer = require("app.views.BattleScene.ArenaFailedLayer"):create()
			layer:init(battleType, data)
			self.bm:getBattleScene():addChild(layer)	
			layer:setLocalZOrder(100)
		end

	elseif battleType == BattleType.kMailVideo then
		local data = self.bm:getBattleScene():getData()
		if self.data[1] == 1 then

			local layer = require("app.views.BattleScene.MailVideoWinLayer"):create()
			layer:init(self.data,ship_list,data.from)
			self.bm:getBattleScene():addChild(layer)
			layer:setLocalZOrder(100)
		else
			local layer = require("app.views.BattleScene.MailVideoFailedLayer"):create()
			layer:init(self.data,ship_list,data.from)
			self.bm:getBattleScene():addChild(layer)	
			layer:setLocalZOrder(100)
		end
	end

	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BattlePause")
end


return WinEvent