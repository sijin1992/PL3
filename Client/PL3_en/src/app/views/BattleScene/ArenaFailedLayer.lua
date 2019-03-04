local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local ArenaFailedLayer = class("ArenaFailedLayer", cc.load("mvc").ViewBase)

ArenaFailedLayer.RESOURCE_FILENAME = "BattleScene/FailedLayer/FailedLayer.csb"

ArenaFailedLayer.NEED_ADJUST_POSITION = true

ArenaFailedLayer.RESOURCE_BINDING = {
	["back_to_game"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function ArenaFailedLayer:OnBtnClick(event)

	if event.name == "ended" and event.target:getName() == "back_to_game" then
		playEffectSound("sound/system/click.mp3")
		
		playMusic("sound/main.mp3", true)

		if self.type_ == BattleType.kArena then
			app:pushToRootView("ArenaScene/ArenaScene")
		elseif self.type_ == BattleType.kSlave then
			app:pushToRootView("ColonizeScene/ColonizeScene", {type = "slave", result = "lose", nickname = self.info.nickname})
		elseif self.type_ == BattleType.kSlaveEnemy then
			app:pushToRootView("ColonizeScene/ColonizeScene", {type = "enemy", result = "lose", nickname = self.info.nickname})
		elseif self.type_ == BattleType.kSaveFriend then

			if self.data_.req.user_name == player:getName() then
				app:pushToRootView("SlaveScene/SlaveScene", {})
			else
				app:pushToRootView("ColonizeScene/ColonizeScene", {type = "save", result = "lose", nickname = self.info.nickname})
			end
		end
	end
end

function ArenaFailedLayer:init(type,data)
	self.data_ = data
	self.type_ = type
end

function ArenaFailedLayer:onEnterTransitionFinish()

	printInfo("ArenaFailedLayer:onEnterTransitionFinish()")
	local rn = self:getResourceNode()
	playEffectSound("sound/system/failed.mp3")

	rn:getChildByName("score"):setString("")
	rn:getChildByName("point"):setString("")
	for i=1,4 do
		rn:getChildByName("go_text_"..i):setString(CONF:getStringValue("failed_go_"..i))

		rn:getChildByName("go_"..i):addTouchEventListener(function ( sender, eventType )

			playEffectSound("sound/system/click.mp3")
			if eventType == ccui.TouchEventType.began then
				sender:setScale(0.9)
			elseif eventType == ccui.TouchEventType.canceled then
				sender:setScale(1)
			elseif eventType == ccui.TouchEventType.ended then
				sender:setScale(1)
				playMusic("sound/main.mp3", true)
				if self.type_ == BattleType.kArena then
					app:pushToRootView("ArenaScene/ArenaScene",{noRetain = true})
				elseif self.type_ == BattleType.kSlave then
					app:pushToRootView("ColonizeScene/ColonizeScene", {noRetain = true,type = "slave", result = "lose", nickname = self.info.nickname})
				elseif self.type_ == BattleType.kSlaveEnemy then
					app:pushToRootView("ColonizeScene/ColonizeScene", {noRetain = true,type = "enemy", result = "lose", nickname = self.info.nickname})
				elseif self.type_ == BattleType.kSaveFriend then

					if self.data_.req.user_name == player:getName() then
						app:pushToRootView("SlaveScene/SlaveScene", {noRetain = true})
					else
						app:pushToRootView("ColonizeScene/ColonizeScene", {noRetain = true,type = "save", result = "lose", nickname = self.info.nickname})
					end
				end
				if i == 1 then
					
					if self.type_ == BattleType.kArena then

					else
						app:addView2Top("NewFormLayer", {from = "special"})
					end
				elseif i == 2 then
					goScene(2,2)
				elseif i == 3 then
					goScene(2,2)
				elseif i == 4 then
					goScene(6,1)
				end
			end

		end)
	end
	rn:getChildByName("go_4"):setVisible(false)
	rn:getChildByName("go_text_4"):setVisible(false)
	animManager:runAnimOnceByCSB(rn, "BattleScene/FailedLayer/FailedLayer.csb", "arena_intro")

	rn:getChildByName("back_to_game"):getChildByName("text"):setString(CONF:getStringValue("quit"))
	

	if self.type_ == BattleType.kArena then
		local strData = Tools.encode("ArenaChallengeReq", {
			type = 1,
			result = 0,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_CHALLENGE_REQ"),strData)

		gl:retainLoading()	
	else
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
		print("ArenaFailedLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_CHALLENGE_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("ArenaChallengeResp",strData)
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
end

function ArenaFailedLayer:onExitTransitionStart()
	printInfo("ArenaFailedLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end


return ArenaFailedLayer