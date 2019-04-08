local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local FailedLayer = class("FailedLayer", cc.load("mvc").ViewBase)

FailedLayer.RESOURCE_FILENAME = "BattleScene/FailedLayer/FailedLayer.csb"
FailedLayer.NEED_ADJUST_POSITION = true

FailedLayer.RESOURCE_BINDING = {
	["fight_again"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["back_to_game"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function FailedLayer:OnBtnClick(event)

	if event.name == "ended" then
		playEffectSound("sound/system/click.mp3")
		if event.target:getName() == "back_to_game" then

			local area = math.floor(g_Views_config.copy_id/1000000)
			local stage = math.floor(g_Views_config.copy_id/100)
			local index = g_Views_config.copy_id%100

			app:pushToRootView("LevelScene", {area = area, stage = stage, index = index })
			playMusic("sound/main.mp3", true)

		elseif event.target:getName() == "fight_again" then

			app:pushToRootView("FightFormScene/FightFormScene", {copy_id = g_Views_config.copy_id, from = "copy"})
			playMusic("sound/main.mp3", true)
		end
	end
	
end

function FailedLayer:init(id)
	self.id = id
end

function FailedLayer:touchFunc()
	local rn = self:getResourceNode()
	local name = rn:getChildByName("player_name")
	local demand = rn:getChildByName("commend_fight")
	local lv = rn:getChildByName("lv")
	local fight = rn:getChildByName("player_fight")
	local fightNum = rn:getChildByName("player_fight_num")
	local demandNum = rn:getChildByName("commend_fight_num")

	name:setString(player:getNickName())
	demand:setString(CONF:getStringValue("recommendPower"))
	fight:setString(CONF:getStringValue("combat"))
	fightNum:setString(GetCurrentShipsPower())
	fightNum:setPositionX(fight:getPositionX() + fight:getContentSize().width + 5)
	demandNum:setString(CONF.CHECKPOINT.get(self.id).COMBAT)  
	demandNum:setPositionX(demand:getPositionX() + demand:getContentSize().width + 5)
	lv:setString(string.format("Lv.%d", player:getLevel()))
	lv:setPositionX(name:getPositionX() + name:getContentSize().width + 5)

	rn:getChildByName("fight_again"):getChildByName("Text_2"):setString(CONF:getStringValue("fightAgain"))
	rn:getChildByName("back_to_game"):getChildByName("text"):setString(CONF:getStringValue("quit"))

	local center = cc.exports.VisibleRect:center()
	rn:setAnchorPoint(cc.p(0.5 ,0.5))
	rn:setPosition(center)

	local function onTouchBegan(touch, event)
		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function FailedLayer:onEnterTransitionFinish()

	printInfo("FailedLayer:onEnterTransitionFinish()")
	guideManager:checkInterface(CONF.EInterface.kFightLose)
	playEffectSound("sound/system/failed.mp3")

	local rn = self:getResourceNode()

	rn:getChildByName("player_head"):getChildByName("image"):setTexture("HeroImage/"..player:getPlayerIcon()..".png")
	rn:getChildByName("player_name"):setString(player:getNickName())
	rn:getChildByName("lv"):setString("Lv."..player:getLevel())
	rn:getChildByName("player_fight"):setString(CONF:getStringValue("combat")..":")
	rn:getChildByName("player_fight_num"):setString(player:getPower())
	rn:getChildByName("commend_fight"):setString(CONF:getStringValue("recommendPower")..":")
	rn:getChildByName("commend_fight_num"):setString(CONF.CHECKPOINT.get(self.id).COMBAT)

	rn:getChildByName("lv"):setPositionX(rn:getChildByName("player_name"):getPositionX() + rn:getChildByName("player_name"):getContentSize().width + 30)
	rn:getChildByName("player_fight_num"):setPositionX(rn:getChildByName("player_fight"):getPositionX() + rn:getChildByName("player_fight"):getContentSize().width + 10)
	rn:getChildByName("commend_fight_num"):setPositionX(rn:getChildByName("commend_fight"):getPositionX() + rn:getChildByName("commend_fight"):getContentSize().width + 10)

	rn:getChildByName("fight_again"):getChildByName("Text_2"):setString(CONF:getStringValue("fightAgain"))
	rn:getChildByName("back_to_game"):getChildByName("text"):setString(CONF:getStringValue("quit"))

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
				playMusic("sound/mian.mp3", true)
				app:pushToRootView("FightFormScene/FightFormScene", {copy_id = g_Views_config.copy_id, from = "copy",noRetain = true})
				if i == 1 then
					app:addView2Top("NewFormLayer",{from = "copy"})
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

    rn:getChildByName("account"):setVisible(true)
    rn:getChildByName("account"):getChildByName("text"):setString(CONF:getStringValue("Statistics"))
    rn:getChildByName("account"):addClickEventListener(function ()
		playEffectSound("sound/system/click.mp3")
        local accountnode = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/WinLayer/AccountNode.csb")
        accountnode:getChildByName("title"):setString(CONF:getStringValue("Statistics"))
        accountnode:getChildByName("ht1"):setString(CONF:getStringValue("my_hit")..":")
	    accountnode:getChildByName("ht2"):setString(CONF:getStringValue("enemy_hit")..":")
	    accountnode:getChildByName("ship1"):setString(CONF:getStringValue("my_ship")..":")
	    accountnode:getChildByName("ship2"):setString(CONF:getStringValue("enemy_ship")..":")
	    accountnode:getChildByName("time"):setString(CONF:getStringValue("fight_time")..":")
        local data = self.data_["data"]
        accountnode:getChildByName("ht1_num"):setString(string.format("%d",data[3]))
	    accountnode:getChildByName("ht2_num"):setString(string.format("%d",data[4]))
	    accountnode:getChildByName("ship1_num"):setString(string.format("%d/%d",data[5],data[6]))
	    accountnode:getChildByName("ship2_num"):setString(string.format("%d/%d",data[8]-data[7],data[8]))
	    accountnode:getChildByName("time_num"):setString(formatTime(data[2]))
        
        accountnode:getChildByName("close"):addClickEventListener(function ()
            accountnode:removeFromParent()
        end)
        local center = cc.exports.VisibleRect:center()
        accountnode:setPosition(cc.p(center.x + (rn:getContentSize().width/2 - center.x), center.y + (rn:getContentSize().height/2 - center.y)))
        rn:addChild(accountnode)
	end)

	local strData = Tools.encode("PveReq", {
			checkpoint_id = self.id,
			type = 1,
			result = 0,
			star = player:getCopyStar(self.id),
		})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

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
		print("FailedLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PVE_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("PveResp",strData)

			if proto.result ~= 0 then
				printInfo("proto error")
			else
				flurryLogEvent("pve", {result = "lose", copy_id = tostring(self.id)}, 2)
                if device.platform == "ios" or device.platform == "android" then
                    TDGAMission:onFailed(tostring(self.id), "PVEFailed")
                end

				if proto.type == 0 then
					
					local name = CONF:getStringValue(CONF.TRIAL_LEVEL.get(self.id).Medt_LEVEL)
					local enemy_name = getEnemyIcon(CONF.TRIAL_LEVEL.get(self.id).MONSTER_ID)
					app:pushToRootView("BattleScene/BattleScene", {BattleType.kCheckPoint,Tools.decode("PveResp",strData),true,name,enemy_name})

				elseif proto.type == 1 then

					self:touchFunc()

				end
			end

		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	animManager:runAnimOnceByCSB(rn, "BattleScene/FailedLayer/FailedLayer.csb", "intro",function()
		-- print ("#### FailedLayer cc.exports.new_hand_gift_bag_data: " .. tostring(cc.exports.new_hand_gift_bag_data))
		if cc.exports.new_hand_gift_bag_data then
			-- print ("#### FailedLayer Tools.isEmpty(player:getNewHandGift()) " .. tostring(Tools.isEmpty(player:getNewHandGift())))
			if Tools.isEmpty(player:getNewHandGift()) == false then
				local layer2 = self:getApp():createView("AdventureLayer/AdventureLayer",{new = true})
				layer2:setPosition(cc.exports.VisibleRect:leftBottom())
				self:addChild(layer2)
			end
		end
		end)

end

function FailedLayer:onExitTransitionStart()
	printInfo("FailedLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end


function FailedLayer:onCreate(data)
	print("~~~ FailedLayer onCreate ")
	if data then
		self.data_ = data

		local is_data_ok = data["checkpoint_id"] ~= nil
		if(is_data_ok) then
			local id = data["checkpoint_id"]
			local init_data = data["data"]
			self:init(id,init_data)
		end
	end


end

return FailedLayer