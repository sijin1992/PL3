local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local TrialWinLayer = class("TrialWinLayer", cc.load("mvc").ViewBase)

TrialWinLayer.RESOURCE_FILENAME = "BattleScene/WinLayer/WinLayer.csb"

TrialWinLayer.NEED_ADJUST_POSITION = true

TrialWinLayer.RESOURCE_BINDING = {
	-- ["backk"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}


local schedulerEntry = nil

function TrialWinLayer:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" and event.target:getName() == "backk" then
		playEffectSound("sound/system/click.mp3")
		local copy_id = CONF.TRIAL_LEVEL.get(g_Views_config.copy_id).T_COPY_ID

		local scene
		if copy_id ~= 0 then
			scene = CONF.TRIAL_COPY.get(copy_id).COPYMAP_ID
		else
			scene = g_Views_config. copy_id
		end

		app:pushToRootView("TrialScene/TrialStageScene", {scene = scene, slPosX = g_Views_config.slPosX, copy_id = copy_id})
		playMusic("sound/main.mp3", true)
	end

end

function TrialWinLayer:init(id,data,hp_list)
	self.id = id
	self.data = data
	self.hp_list_ = hp_list
end

function TrialWinLayer:createLayer2( ... )
	local layer = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/WinLayer/WinLayer2.csb")

	if CONF.TRIAL_LEVEL.get(self.id).START_MAX == 3 then
		layer:getChildByName("star_4"):setVisible(false)
	end

	local star_num = self.star
	-- if star_num > 3 then
	-- 	star_num = 3
	-- end

	for i=1,star_num do
		layer:getChildByName("star_"..i):setTexture("BattleScene/WinLayer/ui_icon_start_1.png")
	end

	local conf = CONF.TRIAL_LEVEL.get(self.id)

	layer:getChildByName("lv_num"):setString(player:getLevel())
	layer:getChildByName("hasExp"):setString(player:getNowExp())
	layer:getChildByName("upExp"):setString(conf.EXP1)
	layer:getChildByName("gold"):setString(conf.GOLD)

	layer:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("fightAgain"))
	layer:getChildByName("end"):getChildByName("text"):setString(CONF:getStringValue("quit"))
	layer:getChildByName("Text_2"):setString(CONF:getStringValue("gain_award"))
    layer:getChildByName("nextlevel"):setVisible(false)
    layer:getChildByName("account"):setVisible(false)
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
	for i,v in ipairs(player:getTrialLineup(CONF.TRIAL_LEVEL.get(self.id).AREA_ID)) do

		if v ~= 0 then

			local ship_info = player:getShipByGUID(v)
			local ship_conf = CONF.AIRSHIP.get(ship_info.id)
			local node = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/WinLayer/ShipNode.csb")
			node:getChildByName("bg"):loadTexture("RankLayer/ui/ui_avatar_"..ship_conf.QUALITY..".png")
--			node:getChildByName("icon"):loadTexture("RoleIcon/"..ship_conf.DRIVER_ID..".png")
            node:getChildByName("icon"):setVisible(false)
            node:getChildByName("icon2"):setVisible(true)
            node:getChildByName("icon2"):setTexture("ShipImage/"..ship_conf.DRIVER_ID..".png")

--			for i=ship_info.ship_break+1,6 do
--				node:getChildByName("star_"..i):removeFromParent()
--			end
            player:ShowShipStar(node,ship_info.ship_break,"star_")

			node:getChildByName("lv"):setString(ship_info.level)

			node:getChildByName("expNum"):setString(conf.EXP2)

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
	end

	if self.win_info.reward_flag then
		local rf = CONF.REWARD.get(CONF.TRIAL_LEVEL.get(self.id).REWARD_ID)
		for i,v in ipairs(rf.ITEM) do

			local node = require("util.ItemNode"):create():init(v, rf.COUNT[i])

			node:setPosition(cc.p(layer:getChildByName("itemPos"):getPositionX() + 120*(i-1), layer:getChildByName("itemPos"):getPositionY()))
			layer:addChild(node)

		end
	end

	layer:getChildByName("end"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local copy_id = CONF.TRIAL_LEVEL.get(g_Views_config.copy_id).T_COPY_ID

		local scene
		if copy_id ~= 0 then
			scene = CONF.TRIAL_COPY.get(copy_id).COPYMAP_ID
		else
			scene = g_Views_config. copy_id
		end

		app:pushToRootView("TrialScene/TrialStageScene", {scene = scene, slPosX = g_Views_config.slPosX, copy_id = copy_id})
		playMusic("sound/main.mp3", true)
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
		local posMid = (layer:getChildByName("star_2"):getPositionX()+layer:getChildByName("star_3"):getPositionX())/2
		local wid = math.abs(layer:getChildByName("star_2"):getPositionX()-layer:getChildByName("star_1"):getPositionX())
		if CONF.TRIAL_LEVEL.get(self.id).START_MAX == 3 then
			layer:getChildByName("star_2"):setPositionX(posMid)
			layer:getChildByName("star_1"):setPositionX(posMid-wid)
			layer:getChildByName("star_3"):setPositionX(posMid+wid)
		end
	end)
	local posMid = (layer:getChildByName("star_2"):getPositionX()+layer:getChildByName("star_3"):getPositionX())/2
	local wid = math.abs(layer:getChildByName("star_2"):getPositionX()-layer:getChildByName("star_1"):getPositionX())
	if CONF.TRIAL_LEVEL.get(self.id).START_MAX == 3 then
		layer:getChildByName("star_2"):setPositionX(posMid)
		layer:getChildByName("star_1"):setPositionX(posMid-wid)
		layer:getChildByName("star_3"):setPositionX(posMid+wid)
	end
	layer:getChildByName("ui_icon_arrow_40"):setPositionX(layer:getChildByName("hasExp"):getPositionX() + layer:getChildByName("hasExp"):getContentSize().width + layer:getChildByName("ui_icon_arrow_40"):getContentSize().width/2 + 10)
	layer:getChildByName("upExp"):setPositionX(layer:getChildByName("ui_icon_arrow_40"):getPositionX() + layer:getChildByName("ui_icon_arrow_40"):getContentSize().width/2 + 10)
	
	return layer

end

function TrialWinLayer:touchLayer()
	local function onTouchBegan(touch, event)

		return true
	end

	local function onTouchEnded( touch, event )

		if not self.touch_ then

			-- ADD WJJ 20180723
			local layer = require("util.UI_Helper_WinLayer"):getInstance():OnInitWinPopupPanel("layer_2", self:getParent(), self)
			--[[
			local layer = self:createLayer2()
			self:getParent():addChild(layer)
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

function TrialWinLayer:onEnterTransitionFinish()
	printInfo("WinLayer:onEnterTransitionFinish()")

	playEffectSound("sound/system/win.mp3")

	self.recv_ = false
	self.ani_ = false

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


	local round = self.data[9]

	local hp_before = g_Views_config.hp 
	local hp_now = 0
	for i,v in ipairs(self.hp_list_) do
		hp_now = hp_now + v
	end

	local round_num = 0 
	if round >= CONF.PARAM.get("star_round_param_1").PARAM and round < CONF.PARAM.get("star_round_param_2").PARAM then
		round_num = 1
	elseif round > CONF.PARAM.get("star_round_param_2").PARAM then
		round_num = 2
	end

	local hp_num = 0
	local hp_diff = hp_before - hp_now

	if hp_diff >= hp_before * CONF.PARAM.get("star_hp_param_1").PARAM and hp_diff < hp_before*CONF.PARAM.get("star_hp_param_2").PARAM then
		hp_num = 1
	elseif hp_diff >= hp_before*CONF.PARAM.get("star_hp_param_2").PARAM then
		hp_num = 2
	end

	if CONF.TRIAL_LEVEL.get(self.id).START_MAX == 3 then
		rn:getChildByName("star_4"):setVisible(false)
	end

	self.star = CONF.TRIAL_LEVEL.get(self.id).START_MAX - round_num - hp_num
	if self.star < 1 then
		self.star = 1
	end


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

	self.recv_msg = {
		level_id = self.id,
		result = self.data[1],
		star = self.star,
		hp_list = self.hp_list_,
	}

	local strData = Tools.encode("TrialPveEndReq", self.recv_msg)
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_END_REQ"),strData)

	gl:retainLoading()

	rn:getChildByName("back"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		if self.recv_ == false then
			local strData = Tools.encode("TrialPveEndReq", self.recv_msg)
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_END_REQ"),strData)

			gl:retainLoading()
		else

			if self.ani_ then
				return
			end

			if self:getParent():getChildByName("layer_2") == nil then
				-- ADD WJJ 20180723
				local layer = require("util.UI_Helper_WinLayer"):getInstance():OnInitWinPopupPanel("layer_2", self:getParent(), self)

				--[[
				local layer = self:createLayer2()
				layer:setName("layer_2")
				self:getParent():addChild(layer)
				local center = cc.exports.VisibleRect:center()
				layer:setAnchorPoint(cc.p(0.5 ,0.5))
				layer:setPosition(center)
				self:setVisible(false)
				]]
			end
		end
	end)


	local function recvMsg()
		print("TrialWinLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_END_RESP") then

			gl:releaseLoading()
			
			local proto = Tools.decode("TrialPveEndResp",strData)

			for k,v in pairs(proto) do
				print(k,v)
			end

			if proto.result ~= 0 then
				printInfo("proto error")
			else
				-- local levelInfo = {stage_id = self.id, stage_star = self.star}

				-- player:setLevelInfo(levelInfo)

				flurryLogEvent("trial", {result = "win-"..self.star, copy_id = tostring(self.id)}, 2)

				self.recv_ = true

				printInfo("win end")

				self.win_info = proto
				-- self:touchLayer()
                if self:getParent():getChildByName("layer_2") == nil then
				    local layer = require("util.UI_Helper_WinLayer"):getInstance():OnInitWinPopupPanel("layer_2", self:getParent(), self)
			    end
			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.ani_ = true
	animManager:runAnimOnceByCSB(rn, "BattleScene/WinLayer/WinLayer.csb", "intro", function ()
		self.ani_ = false
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

function TrialWinLayer:onExitTransitionStart()
	printInfo("TrialWinLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end


return TrialWinLayer