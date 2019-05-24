local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local StarWinLayer = class("StarWinLayer", cc.load("mvc").ViewBase)

StarWinLayer.RESOURCE_FILENAME = "BattleScene/WinLayer/WinLayer.csb"

StarWinLayer.NEED_ADJUST_POSITION = true

StarWinLayer.RESOURCE_BINDING = {
	-- ["backk"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}


local schedulerEntry = nil

function StarWinLayer:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" and event.target:getName() == "backk" then

		playMusic("sound/main.mp3", true)
		playEffectSound("sound/system/click.mp3")

		local tips = ""

		if self.type_ == BattleType.kPlanetRuins then
			tips = CONF:getStringValue("destroy_end")
		end

		app:pushToRootView("LevelScene", {area = 1, stage = 10101, index = 1, go = "planet", tips = tips })
		
	end

end

function StarWinLayer:init(data,type, ship_list,area_id)
	self.data = data
	self.type_ = type
	self.ship_list = ship_list
	self.area_id = area_id
	print("aaaa",area_id)
end

function StarWinLayer:createLayer2( ... )
	local layer = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/WinLayer/WinLayer2.csb")

	layer:getChildByName("star_4"):setVisible(false)

	local star_num = self.star
	if star_num > 3 then
		star_num = 3
	end

	for i=1,star_num do
		layer:getChildByName("star_"..i):setTexture("BattleScene/WinLayer/ui_icon_start_1.png")
	end

	-- local conf = CONF.TRIAL_LEVEL.get(self.id)

	layer:getChildByName("lv_num"):setString(player:getLevel())
	layer:getChildByName("hasExp"):setString(player:getNowExp())
	layer:getChildByName("upExp"):setString(0)
	layer:getChildByName("gold"):setString(0)

	layer:getChildByName("ui_icon_arrow_40"):setPositionX(layer:getChildByName("hasExp"):getPositionX() + layer:getChildByName("hasExp"):getContentSize().width + 30)
	layer:getChildByName("upExp"):setPositionX(layer:getChildByName("ui_icon_arrow_40"):getPositionX() + 30)

	layer:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("fightAgain"))
	layer:getChildByName("end"):getChildByName("text"):setString(CONF:getStringValue("quit"))
	layer:getChildByName("Text_2"):setString(CONF:getStringValue("gain_award"))

	--progress
	local bs = cc.size(304, 9)
	local cap = cc.rect(0,0,5,10)
	self.progress = require("util.ClippingScaleProgressDelegate"):create("BattleScene/FailedLayer/ui/ui_progress_light2big.png", 311, {capinsets = cap, bg_size = bs, lightLength = 0})

	layer:addChild(self.progress:getClippingNode())
	self.progress:getClippingNode():setPosition(cc.p(layer:getChildByName("progress_back"):getPosition()))
	self.progress:setPercentage((player:getLevel() - CONF.PLAYERLEVEL.get(player:getLevel()).EXP_ALL + CONF.PLAYERLEVEL.get(player:getLevel()).EXP)/CONF.PLAYERLEVEL.get(player:getLevel()).EXP*100)

	-- local level_up = false
	-- if self.player_exp + self.win_info.char_exp_bonus >= CONF.PLAYERLEVEL.get(player:getLevel()).EXP_ALL then
	--     level_up = true
	-- end

	-- if level_up then
	--     --等级提升
	-- end

	--ship 

	self.ship_progress = {}
	local ship_num = 1
	for i,v in ipairs(self.ship_list) do

		local ship_info = player:getShipByGUID(v.guid)
		local ship_conf = CONF.AIRSHIP.get(ship_info.id)
		local node = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/WinLayer/ShipNode.csb")
		node:getChildByName("bg"):loadTexture("RankLayer/ui/ui_avatar_"..ship_conf.QUALITY..".png")
		node:getChildByName("icon"):loadTexture("RoleIcon/"..ship_conf.DRIVER_ID..".png")

--		for i=ship_info.ship_break+1,6 do
--			node:getChildByName("star_"..i):removeFromParent()
--		end
        player:ShowShipStar(node,ship_info.ship_break,"star_")

		node:getChildByName("lv"):setString(ship_info.level)

		node:getChildByName("expNum"):setString(0)

		--progress
		local bs = cc.size(77, 7)
		local cap = cc.rect(1,1,23,16)
		local progress = require("util.ClippingScaleProgressDelegate"):create("Common/ui/ui_progress_light2.png", 80, {capinsets = cap, bg_size = bs, lightLength = 0})

		node:addChild(progress:getClippingNode())
		progress:getClippingNode():setPosition(cc.p(node:getChildByName("progress_back"):getPosition()))

		local cur = ship_info.exp - CONF.SHIPLEVEL.get(ship_info.level).EXP_ALL + CONF.SHIPLEVEL.get(ship_info.level).EXP
		progress:setPercentage(cur/CONF.SHIPLEVEL.get(ship_info.level).EXP*100)

		node:setPosition(cc.p(layer:getChildByName("shipPos"):getPositionX() + 120*(ship_num-1), layer:getChildByName("shipPos"):getPositionY()))
		node:setName("ship_node_"..i)
		layer:addChild(node)

		ship_num = ship_num + 1
		table.insert(self.ship_progress, progress)
		
	end

	-- for i,v in ipairs(self.win_info.user_sync.equip_list) do

	-- 	local node = require("util.ItemNode"):create():init(v.equip_id, 1)

	-- 	node:setPosition(cc.p(layer:getChildByName("itemPos"):getPositionX() + 120*(i-1), layer:getChildByName("itemPos"):getPositionY()))
	-- 	layer:addChild(node)

	-- end

	layer:getChildByName("end"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")

		playMusic("sound/main.mp3", true)
		-- local copy_id = CONF.TRIAL_LEVEL.get(g_Views_config.copy_id).T_COPY_ID

		-- local scene
		-- if copy_id ~= 0 then
		--     scene = CONF.TRIAL_COPY.get(copy_id).COPYMAP_ID
		-- else
		--     scene = g_Views_config. copy_id
		-- end

		-- app:pushToRootView("TrialScene/TrialStageScene", {scene = scene, slPosX = g_Views_config.slPosX, copy_id = copy_id})

		local tips = ""

		if self.type_ == BattleType.kPlanetRuins then
			tips = CONF:getStringValue("destroy_end")
		elseif self.type_ == BattleType.kPlanetRes then
			tips = CONF:getStringValue("collect_start")
		end

		app:pushToRootView("LevelScene", {area = self.area_id, stage = CONF.AREA.get(self.area_id).SIMPLE_COPY_ID[1], index = 1, go = "planet", tips = tips })
	end)

	layer:getChildByName("fight"):addClickEventListener(function ()
		playEffectSound("sound/system/click.mp3")
		-- local strData = Tools.encode("PveReq", {
		--     checkpoint_id = self.id,
		--     type = 0,
		--     result = 0,
		-- })
		-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

		-- gl:retainLoading()
		-- app:pushToRootView("CopyScene/CopyScene", {copy_id = self.id})

	end)

	layer:getChildByName("fight"):removeFromParent()

	local function onTouchBegan(touch, event)

		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)


	animManager:runAnimOnceByCSB(layer, "BattleScene/WinLayer/WinLayer2.csb", "intro", function ( ... )
		layer:getChildByName("ui_icon_arrow_40"):setPositionX(layer:getChildByName("hasExp"):getPositionX() + layer:getChildByName("hasExp"):getContentSize().width + layer:getChildByName("ui_icon_arrow_40"):getContentSize().width/2 + 10)
		layer:getChildByName("upExp"):setPositionX(layer:getChildByName("ui_icon_arrow_40"):getPositionX() + layer:getChildByName("ui_icon_arrow_40"):getContentSize().width/2 + 10)
	end)

	return layer

end

function StarWinLayer:touchLayer()
	local function onTouchBegan(touch, event)

		return true
	end

	local function onTouchEnded( touch, event )

		if self:getParent():getChildByName("layer_2") == nil then

			-- ADD WJJ 20180723
			local layer = require("util.UI_Helper_WinLayer"):getInstance():OnInitWinPopupPanel("layer_2", self:getParent(), self)

			--[[
			local layer = self:createLayer2()
			self:getParent():addChild(layer)
			layer:setName("layer_2")
			local center = cc.exports.VisibleRect:center()
			layer:setAnchorPoint(cc.p(0.5 ,0.5))
			layer:setPosition(center)
			self:setVisible(false)
			]]

			-- local upNum = self.win_info.char_exp_bonus/10
			-- local ship_upNum = self.win_info.ship_exp_bonus/10
			-- local function update()

			--     if upNum < self.win_info.char_exp_bonus then

			--         if self.player_exp + upNum < CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL then
			--             local cur = self.player_exp + upNum - CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL + CONF.PLAYERLEVEL.get(self.player_level).EXP
			--             self.progress:setPercentage(cur/CONF.PLAYERLEVEL.get(self.player_level).EXP*100)
			--         else
			--             layer:getChildByName("info"):setVisible(true)

			--             if self.player_exp + upNum < CONF.PLAYERLEVEL.get(self.player_level+1).EXP_ALL then
			--                 local cur = self.player_exp + upNum - CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL
			--                 self.progress:setPercentage(cur/CONF.PLAYERLEVEL.get(self.player_level+1).EXP*100)
			--                 layer:getChildByName("lv_num"):setString(self.player_level+1)
			--             end
			--         end
					
			--         upNum = upNum + self.win_info.char_exp_bonus/10

			--         for i,v in ipairs(self.ship_list) do
			--             if self.ship_exp[i] + ship_upNum < CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL then
			--                 local cur = self.ship_exp[i] + ship_upNum - CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL + CONF.SHIPLEVEL.get(self.ship_level[i]).EXP
			--                 self.ship_progress[i]:setPercentage(cur/CONF.SHIPLEVEL.get(self.ship_level[i]).EXP*100)
			--             else
			--                 if self.ship_exp[i] + ship_upNum < CONF.SHIPLEVEL.get(self.ship_level[i]+1).EXP_ALL then
			--                     local cur = self.ship_exp[i]  + ship_upNum - CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL
			--                     self.ship_progress[i]:setPercentage(cur/CONF.SHIPLEVEL.get(self.ship_level[i]+1).EXP*100)
			--                     layer:getChildByName("ship_node_"..i):getChildByName("lv"):setString(self.ship_level[i]+1)
			--                 end
			--             end
			--         end

			--         ship_upNum = ship_upNum + self.win_info.ship_exp_bonus/10

			--     else
			--         scheduler:unscheduleScriptEntry(schedulerEntry)
			--     end

			-- end

			-- schedulerEntry = scheduler:scheduleScriptFunc(update,0.1,false)

			self.touch_ = true
		end
	end


	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function StarWinLayer:onEnterTransitionFinish()
	printInfo("WinLayer:onEnterTransitionFinish()")

-- 	message PlanetInfo{
-- 	required int32 type = 1;            //1：资源矿 2：废墟  3：突袭
-- 	optional int32 res_index = 2;     //1:资源矿INDEX
-- 	optional int32 ruins_id = 3;	//2:废墟ID    
-- 	optional string user_name = 4; //3:敌方玩家
-- }

	for i,v in pairs(g_Planet_Info) do
		print("g_Planet_Info",i,v)
	end

	g_Raid_Reward.flag = true

	playEffectSound("sound/system/win.mp3")

	self.ani_ = false

	if self.type_ == BattleType.kPlanetRaid then
		flurryLogEvent("attack_raid", {result = "win", raid_name = tostring(g_Planet_Info.info.user_name)}, 2)
	elseif self.type_ == BattleType.kPlanetRes then

		local res_id = g_Planet_Info.info.res_index 
		if g_Planet_Info.target_name == "" then
			flurryLogEvent("collect_res", {result = "win", res_id = tostring(res_id)}, 2)
		else

			local res_str = string.format("%d-%s",res_id,g_Planet_Info.target_name)
			flurryLogEvent("attack_res", {result = "win", res_str = res_str}, 2)
		end
	elseif self.type_ == BattleType.kPlanetRuins then
		flurryLogEvent("attack_ruins", {result = "win", ruins_id = tostring(g_Planet_Info.info.ruins_id )}, 2)
	end

	local rn = self:getResourceNode()
	local center = cc.exports.VisibleRect:center()
	rn:setAnchorPoint(cc.p(0.5 ,0.5))
	rn:setPosition(center)

	rn:getChildByName("ht1"):setString(CONF:getStringValue("my_hit")..":")
	rn:getChildByName("ht2"):setString(CONF:getStringValue("enemy_hit")..":")
	rn:getChildByName("ship1"):setString(CONF:getStringValue("my_ship")..":")
	rn:getChildByName("ship2"):setString(CONF:getStringValue("enemy_ship")..":")
	rn:getChildByName("time"):setString(CONF:getStringValue("fight_time")..":")

	local diff = 10
	rn:getChildByName("ht1_num"):setPositionX(rn:getChildByName("ht1"):getPositionX() + rn:getChildByName("ht1"):getContentSize().width + diff)
	rn:getChildByName("ht2_num"):setPositionX(rn:getChildByName("ht2"):getPositionX() + rn:getChildByName("ht2"):getContentSize().width + diff)
	rn:getChildByName("ship1_num"):setPositionX(rn:getChildByName("ship1"):getPositionX() + rn:getChildByName("ship1"):getContentSize().width + diff)
	rn:getChildByName("ship2_num"):setPositionX(rn:getChildByName("ship2"):getPositionX() + rn:getChildByName("ship2"):getContentSize().width + diff)
	rn:getChildByName("time_num"):setPositionX(rn:getChildByName("time"):getPositionX() + rn:getChildByName("time"):getContentSize().width + diff)

	rn:getChildByName("ht1_num"):setString(string.format("%d",self.data[3]))
	rn:getChildByName("ht2_num"):setString(string.format("%d",self.data[4]))
	
	rn:getChildByName("ship1_num"):setString(string.format("%d/%d",self.data[5],self.data[6]))
	rn:getChildByName("ship2_num"):setString(string.format("%d/%d",self.data[8]-self.data[7],self.data[8]))

	rn:getChildByName("time_num"):setString(formatTime(self.data[2]))

	rn:getChildByName("star_4"):setVisible(false)

	self.star = 3

	local function runStarAnim( index )
		local pos = cc.p(rn:getChildByName("star_"..index):getPosition())
		local anim = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/star_1.csb")
		rn:addChild(anim)
		anim:setPosition(pos)
		animManager:runAnimOnceByCSB(anim, "BattleScene/star_1.csb", "1", function ()
			
			if index >= self.star then
				return
			end
			runStarAnim(index + 1)
		end)
	end
	runStarAnim(1)

	print("type", self.type_)

	rn:getChildByName("back"):addClickEventListener(function (sender)
		playEffectSound("sound/system/click.mp3")
		if self.ani_ then

			-- ADD WJJ 20180723
			local layer = require("util.UI_Helper_WinLayer"):getInstance():OnInitWinPopupPanel("layer_2", self:getParent(), self)

			--[[
			local layer = self:createLayer2()
			self:getParent():addChild(layer)
			layer:setName("layer_2")
			local center = cc.exports.VisibleRect:center()
			layer:setAnchorPoint(cc.p(0.5 ,0.5))
			layer:setPosition(center)
			self:setVisible(false)
			]]
		end
	end)

	-- self:touchLayer()

	-- if self.type_ == BattleType.kPlanetRes then
	-- 	local strData = Tools.encode("PlanetAttackResOKReq", {
	-- 			result = 1,
	-- 			attack_req = g_Planet_Info,
	-- 		})
	-- 	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_ATTACK_RES_OK_REQ"),strData)

	-- 	gl:retainLoading()

	-- elseif self.type_ == BattleType.kPlanetRuins then
	-- 	local strData = Tools.encode("PlanetRuinsOKReq", {
	-- 			area_id = g_Planet_Info.area_id,
	-- 			info = g_Planet_Info.info,
	-- 			result = 1,
	-- 		})
	-- 	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RUINS_OK_REQ"),strData)

	-- 	gl:retainLoading()
	-- elseif self.type_ == BattleType.kPlanetRaid then
	-- 	local table_ = {
	-- 		type = 1,
	-- 		area_id = g_Planet_Info.area_id,
	-- 		info = g_Planet_Info.info,
	-- 		lineup = g_Planet_Info.lineup,
	-- 		result = 1,
	-- 	 }

	-- 	local strData = Tools.encode("PlanetRaidReq", table_)
	-- 	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)

	-- 	gl:retainLoading()

	-- end


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
				self.win_info = proto
				self:touchLayer()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_ATTACK_RES_OK_RESP") then

			gl:releaseLoading()
			
			local proto = Tools.decode("PlanetAttackResOKResp",strData)

			if proto.result ~= 0 then
				printInfo("proto error")
			else
				-- local levelInfo = {stage_id = self.id, stage_star = self.star}

				-- player:setLevelInfo(levelInfo)


				printInfo("win end")
				self.win_info = proto
				self:touchLayer()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("PlanetRaidResp",strData)
			printInfo("PlanetRaidResp")
			print(proto.result)
			if proto.result ~= 0 then
				print("PlanetRaidResp error :",proto.result)
			else
				self.win_info = proto
				self:touchLayer()
			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	animManager:runAnimOnceByCSB(rn, "BattleScene/WinLayer/WinLayer.csb", "intro", function ( ... )
		self.ani_ = true
	end)

	rn:getChildByName("ship2_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ship2"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ship1_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ship1"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht2_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht2"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht1_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht1"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("time"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("time_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))

end

function StarWinLayer:onExitTransitionStart()
	printInfo("StarWinLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end


return StarWinLayer