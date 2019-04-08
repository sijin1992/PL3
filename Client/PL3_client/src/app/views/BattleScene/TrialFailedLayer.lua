local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local TrialFailedLayer = class("TrialFailedLayer", cc.load("mvc").ViewBase)

TrialFailedLayer.RESOURCE_FILENAME = "BattleScene/FailedLayer/FailedLayer.csb"

TrialFailedLayer.NEED_ADJUST_POSITION = true

TrialFailedLayer.RESOURCE_BINDING = {
	["back_to_game"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function TrialFailedLayer:OnBtnClick(event)
	printInfo(event.name)


	if event.name == "ended" and event.target:getName() == "back_to_game" then
		playEffectSound("sound/system/click.mp3")
		
		-- local scene = CONF.TRIAL_COPY.get(CONF.TRIAL_LEVEL.get(g_Views_config.copy_id).T_COPY_ID).COPYMAP_ID
		-- local area = CONF.TRIAL_SCENE.get(scene).AREA

		--player:setTrialAreaType(area)
		app:pushToRootView("TrialScene/TrialAreaScene",{})
		playMusic("sound/main.mp3", true)
	end


end

function TrialFailedLayer:init(id,data,hp_list)
	self.id = id
	self.data_ = data
	self.hp_list_ = hp_list
end


function TrialFailedLayer:onEnterTransitionFinish()
	printInfo("FailedLayer:onEnterTransitionFinish()")

	playEffectSound("sound/system/failed.mp3")
	local rn = self:getResourceNode()
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
				app:pushToRootView("TrialScene/TrialAreaScene",{noRetain = true})
				playMusic("sound/main.mp3", true)
				if i == 1 then
					app:addView2Top("NewFormLayer",{from = "trial", index = 1})
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
	local strData = Tools.encode("TrialPveEndReq", {
			level_id = self.id,
			result = self.data_[1],
			star = player:getTrialLevelStar(self.id),
			hp_list = self.hp_list_
		})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_END_REQ"),strData)

	gl:retainLoading()

	local function onTouchBegan(touch, event)

		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)


	local function recvMsg()
		print("TrialFailedLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_END_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("TrialPveEndResp",strData)
			printInfo("TrialPveEndResp")
			printInfo(proto.result)
			if proto.result ~= 0 then
				printInfo("proto error")     
			else
				flurryLogEvent("trial", {result = "lose", copy_id = tostring(self.id)}, 2)           
                if device.platform == "ios" or device.platform == "android" then
                    TDGAMission:onFailed(tostring(self.id), "TrialFailed")
                end
			end

		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	self:getResourceNode():getChildByName("back_to_game"):getChildByName("text"):setString(CONF:getStringValue("quit"))

	animManager:runAnimOnceByCSB(rn, "BattleScene/FailedLayer/FailedLayer.csb", "trial_intro")
end

function TrialFailedLayer:onExitTransitionStart()
	printInfo("TrialFailedLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end


return TrialFailedLayer