local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local ArenaWinLayer = class("TrialWinLayer", cc.load("mvc").ViewBase)

ArenaWinLayer.RESOURCE_FILENAME = "BattleScene/WinLayer/WinLayer.csb"

ArenaWinLayer.NEED_ADJUST_POSITION = true

ArenaWinLayer.RESOURCE_BINDING = {
	["backk"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}


local schedulerEntry = nil

function ArenaWinLayer:OnBtnClick(event)

	if event.name == "ended" and event.target:getName() == "backk" then

		playEffectSound("sound/system/click.mp3")
		playMusic("sound/main.mp3", true)

		if self.type_ == BattleType.kArena then
			app:pushToRootView("ArenaScene/ArenaScene")
		elseif self.type_ == BattleType.kSlave then
			app:pushToRootView("SlaveScene/SlaveScene", {type = "slave", result = "win", isCatch = self.data_.isCatch, nickname = self.info.nickname})
		elseif self.type_ == BattleType.kSlaveEnemy then
			app:pushToRootView("SlaveScene/SlaveScene", {type = "enemy", result = "win", isCatch = self.data_.isCatch, nickname = self.info.nickname})
		elseif self.type_ == BattleType.kSaveFriend then
			if self.data_.req.user_name == player:getName() then
				app:pushToRootView("SlaveScene/SlaveScene", {type = "save", result = "win", item_list = self.data_.get_item_list, nickname = self.info.nickname})
			else
				app:pushToRootView("SlaveScene/SlaveScene", {type = "save", result = "win", item_list = self.data_.get_item_list, nickname = self.info.nickname})
			end
		end
	end

end

function ArenaWinLayer:init(type, data)
	self.type_ = type

	if data then
		self.data_ = data
	end
end

function ArenaWinLayer:onEnterTransitionFinish()
	printInfo("ArenaWinLayer:onEnterTransitionFinish()")

	playEffectSound("sound/system/win.mp3")

	local rn = self:getResourceNode()
	rn:getChildByName("score"):setString("")
	rn:getChildByName("point"):setString("")
	rn:getChildByName("backk"):getChildByName("text"):setString(CONF:getStringValue("yes"))

	for i=1,4 do
		rn:getChildByName("star_"..i):setVisible(false)
	end

	if self.type_ == BattleType.kArena then
		local strData = Tools.encode("ArenaChallengeReq", {
			type = 1,
			rank = 1,
			result = 1,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_CHALLENGE_REQ"),strData)

		gl:retainLoading()

	else

		print("get info")

		local strData = Tools.encode("CmdGetOtherUserInfoReq", {
			user_name = self.data_.req.user_name,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_REQ"),strData)

		gl:retainLoading()
	end

	local function onTouchBegan(touch, event)

		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	local function recvMsg()
		print("ArenaWinLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_CHALLENGE_RESP") then

			gl:releaseLoading()
			
			local proto = Tools.decode("ArenaChallengeResp",strData)

			for k,v in pairs(proto) do
				print(k,v)
			end

			if proto.result ~= 0 then
				printInfo("proto error")
			else
				local win,lose = player:getTodayWinLose()
				flurryLogEvent("arena", {result = string.format("W%d-L%d",win,lose), rank = tostring(player:getArenaData().target_rank)}, 2)

				rn:getChildByName("score"):setString(CONF:getStringValue("get score")..":  "..proto.get_score)
				rn:getChildByName("point"):setString(CONF:getStringValue("get_honer")..":  "..proto.add_point)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("CmdGetOtherUserInfoResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")   

			else 
				self.info = proto.info    
			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	animManager:runAnimOnceByCSB(rn, "BattleScene/WinLayer/WinLayer.csb", "arena_intro")
end

function ArenaWinLayer:onExitTransitionStart()
	printInfo("ArenaWinLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end


return ArenaWinLayer