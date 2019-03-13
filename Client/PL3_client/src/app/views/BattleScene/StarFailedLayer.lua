local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local StarFailedLayer = class("StarFailedLayer", cc.load("mvc").ViewBase)

StarFailedLayer.RESOURCE_FILENAME = "BattleScene/FailedLayer/FailedLayer.csb"

StarFailedLayer.NEED_ADJUST_POSITION = true

StarFailedLayer.RESOURCE_BINDING = {
	["back_to_game"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function StarFailedLayer:OnBtnClick(event)
	printInfo(event.name)


	if event.name == "ended" and event.target:getName() == "back_to_game" then
		playEffectSound("sound/system/click.mp3")
		local tips = ""
		if self.type_ == BattleType.kPlanetRaid then
			tips = CONF:getStringValue("raid_fail")
		elseif self.type_ == BattleType.kPlanetRes then
			tips = CONF:getStringValue("collect_fail")
		elseif self.type_ == BattleType.kPlanetRuins then
			tips = CONF:getStringValue("ruins_fail")
		end

		app:pushToRootView("LevelScene", {area = self.area_id, stage = CONF.AREA.get(self.area_id).SIMPLE_COPY_ID[1], index = 1, go = "planet" , tips = tips})
		playMusic("sound/main.mp3", true)
	end


end

function StarFailedLayer:init(data,type,ship_list,area_id)
	self.ship_list = ship_list
	self.data_ = data
	self.type_ = type
	self.area_id = area_id
end

function StarFailedLayer:onEnterTransitionFinish()

	printInfo("StarFailedLayer:onEnterTransitionFinish()")

	g_Raid_Reward.flag = false

	if self.type_ == BattleType.kPlanetRaid then
		flurryLogEvent("attack_raid", {result = "lose", raid_name = tostring(g_Planet_Info.info.user_name)}, 2)
	elseif self.type_ == BattleType.kPlanetRes then

		local res_id = g_Planet_Info.info.res_index 
		if g_Planet_Info.target_name == "" then
			flurryLogEvent("collect_res", {result = "lose", res_id = tostring(res_id)}, 2)
		else

			local res_str = string.format("%d-%s",res_id,g_Planet_Info.target_name)
			flurryLogEvent("attack_res", {result = "lose", res_str = res_str}, 2)
		end
	elseif self.type_ == BattleType.kPlanetRuins then
		flurryLogEvent("attack_ruins", {result = "lose", ruins_id = tostring(g_Planet_Info.info.ruins_id )}, 2)
	end

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
				playMusic("sound/main.mp3", true)
				if i == 1 then
					app:addView2Top("NewFormLayer",{})
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
	-- if self.type_ == BattleType.kPlanetRes then
	-- 	local strData = Tools.encode("PlanetAttackResOKReq", {
	-- 			result = 0,
	-- 			attack_req = g_Planet_Info,
	-- 		})
	-- 	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_ATTACK_RES_OK_REQ"),strData)

	-- 	gl:retainLoading()

	-- elseif self.type_ == BattleType.kPlanetRuins then
	-- 	local strData = Tools.encode("PlanetRuinsOKReq", {
	-- 			area_id = g_Planet_Info.area_id,
	-- 			info = g_Planet_Info.info,
	-- 			result = 0,
	-- 		})
	-- 	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RUINS_OK_REQ"),strData)

	-- 	gl:retainLoading()
	-- elseif self.type_ == BattleType.kPlanetRaid then
	-- 	local table_ = {
	-- 		type = 1,
	-- 		area_id = self.data_.area_id,
	-- 		info = self.data_.planetInfo,
	-- 		lineup = self.forms,
	-- 		result = 0,
	-- 	 }

	-- 	local strData = Tools.encode("PlanetRaidReq", table_)
	-- 	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)

	-- 	gl:retainLoading()

	-- end

	self:getResourceNode():getChildByName("back_to_game"):getChildByName("text"):setString(CONF:getStringValue("back"))

	local function onTouchBegan(touch, event)

		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	local function recvMsg()
		print("StarWinLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RUINS_OK_RESP") then

			gl:releaseLoading()
			
			local proto = Tools.decode("PlanetRuinsOKResp",strData)

			for k,v in pairs(proto) do
				print(k,v)
			end

			if proto.result ~= 0 then
				printInfo("proto error")
			else
				-- local levelInfo = {stage_id = self.id, stage_star = self.star}

				-- player:setLevelInfo(levelInfo)

				printInfo("win end")
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_ATTACK_RES_OK_RESP") then

			gl:releaseLoading()
			
			local proto = Tools.decode("PlanetAttackResOKResp",strData)

			for k,v in pairs(proto) do
				print(k,v)
			end

			if proto.result ~= 0 then
				printInfo("proto error")
			else
				-- local levelInfo = {stage_id = self.id, stage_star = self.star}

				-- player:setLevelInfo(levelInfo)

				printInfo("win end")
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("PlanetRaidResp",strData)
			printInfo("PlanetRaidResp")
			print(proto.result)
			if proto.result ~= 0 then
				print("PlanetRaidResp error :",proto.result)
			else
			   
			end

		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	animManager:runAnimOnceByCSB(self:getResourceNode(), "BattleScene/FailedLayer/FailedLayer.csb", "star_intro")

end

function StarFailedLayer:onExitTransitionStart()
	printInfo("StarFailedLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end


return StarFailedLayer