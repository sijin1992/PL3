local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local WinLayer = class("WinLayer", cc.load("mvc").ViewBase)

WinLayer.RESOURCE_FILENAME = "BattleScene/WinLayer/WinLayer.csb"

WinLayer.NEED_ADJUST_POSITION = true

WinLayer.max_player_level = CONF.PLAYERLEVEL.count()

WinLayer.RESOURCE_BINDING = {

}

local levelUp = false

local schedulerEntry = nil

local schedulerGl = nil


WinLayer.lagHelper = require("util.ExLagHelper"):getInstance()
WinLayer.IS_SCENE_TRANSFER_EFFECT = false

WinLayer.allevels = {}

function WinLayer:OnBtnClick(event)
	printInfo(event.name)

end

function WinLayer:init(id,data, enemyname,ship_list)
	print("~~~ WinLayer init ")

	self.id = id
	self.data = data

	self.enemyName = enemyname
	self.ship_list = ship_list
end

function WinLayer:createLayer2( ... )
	local layer = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/WinLayer/WinLayer2.csb")

	if CONF.CHECKPOINT.get(self.id).START_NUM == 3 then
		layer:getChildByName("star_4"):setVisible(false)
	end

	for i=1,self.star do
		layer:getChildByName("star_"..i):setTexture("BattleScene/WinLayer/ui_icon_start_1.png")
	end

	layer:getChildByName("lv_num"):setString(self.player_level)
	layer:getChildByName("hasExp"):setString(self.player_exp)
	layer:getChildByName("upExp"):setString(self.win_info.char_exp_bonus)
	layer:getChildByName("gold"):setString(self.win_info.level_gold_bonus)

	layer:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("fightAgain"))
	layer:getChildByName("end"):getChildByName("text"):setString(CONF:getStringValue("quit"))
	layer:getChildByName("Text_2"):setString(CONF:getStringValue("gain_award"))

	--progress
	local bs = cc.size(304, 9)
	local cap = cc.rect(0,0,5,10)
	self.progress = require("util.ClippingScaleProgressDelegate"):create("BattleScene/FailedLayer/ui/ui_progress_light2big.png", 311, {capinsets = cap, bg_size = bs, lightLength = 0})

	layer:addChild(self.progress:getClippingNode())
	self.progress:getClippingNode():setPosition(cc.p(layer:getChildByName("progress_back"):getPosition()))
	self.progress:setPercentage((self.player_exp - CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL + CONF.PLAYERLEVEL.get(self.player_level).EXP)/CONF.PLAYERLEVEL.get(self.player_level).EXP*100)

	local level_up = false
	if self.player_exp + self.win_info.char_exp_bonus >= CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL then
		level_up = true
	end

	if level_up then
		--等级提升
		for i=1,8 do
			local conf = CONF.PARAM.get("levelup_"..i)
			if player:getLevel() == tonumber(conf.PARAM[1]) then
				layer:getChildByName("info"):setString(CONF:getStringValue(tostring(conf.PARAM[2])))
				break
			end
		end
	end

	--ship 

	self.ship_node = {}
	self.ship_progress = {}

	for i,v in ipairs(self.ship_list) do
		local ship_info = player:getShipByGUID(v.guid)
		local conf = CONF.AIRSHIP.get(ship_info.id)
		local node = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/WinLayer/ShipNode.csb")
		node:getChildByName("bg"):loadTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
--		node:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")
        node:getChildByName("icon"):setVisible(false)
        node:getChildByName("icon2"):setVisible(true)
        node:getChildByName("icon2"):setTexture("ShipImage/"..conf.DRIVER_ID..".png")

--		for i=ship_info.ship_break+1,6 do
--			node:getChildByName("star_"..i):removeFromParent()
--		end
        player:ShowShipStar(node,ship_info.ship_break,"star_")
		print(self.ship_exp[i], ship_info.exp)

		node:getChildByName("lv"):setString(self.ship_level[i])
		node:getChildByName("expNum"):setString(self.win_info.ship_exp_bonus)

		node:getChildByName("text"):setString(CONF:getStringValue("upgrade"))

		--progress
		local bs = cc.size(77, 7)
		local cap = cc.rect(1,1,23,16)
		local progress = require("util.ClippingScaleProgressDelegate"):create("Common/ui/ui_progress_light2.png", 80, {capinsets = cap, bg_size = bs, lightLength = 0})

		node:addChild(progress:getClippingNode())
		progress:getClippingNode():setPosition(cc.p(node:getChildByName("progress_back"):getPosition()))

		local cur = self.ship_exp[i] - CONF.SHIPLEVEL.get(ship_info.level).EXP_ALL + CONF.SHIPLEVEL.get(ship_info.level).EXP
		progress:setPercentage(cur/CONF.SHIPLEVEL.get(ship_info.level).EXP*100)

		node:setPosition(cc.p(layer:getChildByName("shipPos"):getPositionX() + 120*(i-1), layer:getChildByName("shipPos"):getPositionY()))
		node:setName("ship_node_"..i)
		layer:addChild(node)

		table.insert(self.ship_node, node)
		table.insert(self.ship_progress, progress)
	end

    local checkconf = CONF.CHECKPOINT.get(self.id)
    local itemlist = {}
    for k,v in ipairs(self.win_info.get_item_list) do
        table.insert(itemlist,v)
    end
    if tonumber(self.win_info.level_gold_bonus) > 0 then
        table.insert(itemlist,1,{key = 3001 ,value = tonumber(self.win_info.level_gold_bonus) })
    end
    if tonumber(checkconf.SCIENCE) > 0 then
        table.insert(itemlist,1,{key = 7001 ,value = tonumber(checkconf.SCIENCE) })
    end

	for i,v in ipairs(itemlist) do
		local node = require("util.ItemNode"):create():init(v.key, v.value)

		node:setPosition(cc.p(layer:getChildByName("itemPos"):getPositionX() + 120*(i-1), layer:getChildByName("itemPos"):getPositionY()))
		layer:addChild(node)

	end

	-- for i,v in ipairs(self.win_info.user_sync.equip_list) do

	-- 	local node = require("util.ItemNode"):create():init(v.equip_id, 1)

	-- 	node:setPosition(cc.p(layer:getChildByName("itemPos"):getPositionX() + 120*(#self.win_info.user_sync.item_list + i-1), layer:getChildByName("itemPos"):getPositionY()))
	-- 	layer:addChild(node)

	-- end

	local guide 
	if guideManager:getSelfGuideID() ~= 0 then
		guide = guideManager:getSelfGuideID()
	else
		guide = player:getGuideStep()
	end

	if guide < CONF.GUIDANCE.count() then
		layer:getChildByName("fight"):setVisible(false)
	end

    local function getnextlevel()
        -- nextlevel
        local isfind = 0
        local nextlevel = g_Views_config.copy_id
        for k,v in ipairs(self.allevels) do
            if g_Views_config.copy_id == v then
                isfind = k
            end
        end
        if isfind ~= 0 and isfind < #self.allevels then
            nextlevel = self.allevels[isfind + 1]
        end
        return nextlevel
    end

    local function out(isnext)
        local guide 
		if guideManager:getSelfGuideID() ~= 0 then
			guide = guideManager:getSelfGuideID()
		else
			guide = player:getGuideStep()
		end

		if guide < CONF.PARAM.get("guidance combat").PARAM then
			return
		end
		playEffectSound("sound/system/click.mp3")

		if self.xxx_ == false then
			return
		end

		local area = math.floor(g_Views_config.copy_id/1000000)
		local conf = CONF.AREA.get(area)
		local index_ = player:getStageByArea(area)
		local stage = conf.SIMPLE_COPY_ID[index_]
		local copy = player:getCopyInStage(stage)

		playMusic("sound/main.mp3", true)

		if guideManager:getGuideType() then
			print(" @@@ GO CITY SCENE at WinLayer 184 ")

			-- EDIT BY WJJ 20180702
			if( self.IS_SCENE_TRANSFER_EFFECT ) then
				self.lagHelper:BeginTransferEffect("BattleScene/WinLayer")
			else
				app:pushToRootView("CityScene/CityScene", {pos = -1350})
			end
		else
            if isnext then
                local nextlevel = getnextlevel()
                app:pushToRootView("LevelScene", {area = math.floor(nextlevel/1000000), stage = math.floor(nextlevel/100), index = nextlevel%100 , tongguan = self.tongguan, isnext = isnext, nextlevel = nextlevel})
            else
			    app:pushToRootView("LevelScene", {area = area, stage = stage, index = copy, tongguan = self.tongguan, isnext = isnext})
            end
		end
    end

	layer:getChildByName("end"):addClickEventListener(function ( sender )
		out(false)
	end)
    self.allevels = GetAllLevels()

    local nowarea = math.floor(g_Views_config.copy_id/1000000)
    local nextarea = math.floor(getnextlevel()/1000000)
    if nowarea ~= nextarea then
        layer:getChildByName("nextlevel"):setVisible(false)
    else
        layer:getChildByName("nextlevel"):setVisible(true)
    end
    layer:getChildByName("nextlevel"):getChildByName("text"):setString(CONF:getStringValue("nex_checkpoint"))
    layer:getChildByName("nextlevel"):addClickEventListener(function ( sender )
		out(true)
	end)

	layer:getChildByName("fight"):addClickEventListener(function ()
		playEffectSound("sound/system/click.mp3")

		if self.xxx_ == false then
			return
		end
		-- local strData = Tools.encode("PveReq", {
		--     checkpoint_id = self.id,
		--     type = 0,
		--     result = 0,
		-- })
		-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

		-- gl:retainLoading()
		app:pushToRootView("FightFormScene/FightFormScene", {copy_id = self.id, from = "copy"})
		playMusic("sound/main.mp3", true)
	end)
    layer:getChildByName("account"):getChildByName("text"):setString(CONF:getStringValue("Statistics"))
    layer:getChildByName("account"):addClickEventListener(function ()
		playEffectSound("sound/system/click.mp3")
        local accountnode = require("app.ExResInterface"):getInstance():FastLoad("BattleScene/WinLayer/AccountNode.csb")
        accountnode:getChildByName("title"):setString(CONF:getStringValue("Statistics"))
        accountnode:getChildByName("ht1"):setString(CONF:getStringValue("my_hit")..":")
	    accountnode:getChildByName("ht2"):setString(CONF:getStringValue("enemy_hit")..":")
	    accountnode:getChildByName("ship1"):setString(CONF:getStringValue("my_ship")..":")
	    accountnode:getChildByName("ship2"):setString(CONF:getStringValue("enemy_ship")..":")
	    accountnode:getChildByName("time"):setString(CONF:getStringValue("fight_time")..":")

        accountnode:getChildByName("ht1_num"):setString(string.format("%d",self.data[3]))
	    accountnode:getChildByName("ht2_num"):setString(string.format("%d",self.data[4]))
	    accountnode:getChildByName("ship1_num"):setString(string.format("%d/%d",self.data[5],self.data[6]))
	    accountnode:getChildByName("ship2_num"):setString(string.format("%d/%d",self.data[8]-self.data[7],self.data[8]))
	    accountnode:getChildByName("time_num"):setString(formatTime(self.data[2]))
        
        accountnode:getChildByName("close"):addClickEventListener(function ()
            accountnode:removeFromParent()
        end)
        local center = cc.exports.VisibleRect:center()
        accountnode:setPosition(cc.p(center.x + (layer:getContentSize().width/2 - center.x), center.y + (layer:getContentSize().height/2 - center.y)))
        layer:addChild(accountnode)
	end)

	local function onTouchBegan(touch, event)

		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)
	
	animManager:runAnimOnceByCSB(layer, "BattleScene/WinLayer/WinLayer2.csb", "intro", function ( ... )
		local posMid = (layer:getChildByName("star_2"):getPositionX()+layer:getChildByName("star_3"):getPositionX())/2
		local wid = math.abs(layer:getChildByName("star_2"):getPositionX()-layer:getChildByName("star_1"):getPositionX())
		if CONF.CHECKPOINT.get(self.id).START_NUM == 3 then
			layer:getChildByName("star_2"):setPositionX(posMid)
			layer:getChildByName("star_1"):setPositionX(posMid-wid)
			layer:getChildByName("star_3"):setPositionX(posMid+wid)
		end
		layer:getChildByName("ui_icon_arrow_40"):setPositionX(layer:getChildByName("hasExp"):getPositionX() + layer:getChildByName("hasExp"):getContentSize().width + layer:getChildByName("ui_icon_arrow_40"):getContentSize().width/2 + 10)
		layer:getChildByName("upExp"):setPositionX(layer:getChildByName("ui_icon_arrow_40"):getPositionX() + layer:getChildByName("ui_icon_arrow_40"):getContentSize().width/2 + 10)
	end)

	local posMid = (layer:getChildByName("star_2"):getPositionX()+layer:getChildByName("star_3"):getPositionX())/2
	local wid = math.abs(layer:getChildByName("star_2"):getPositionX()-layer:getChildByName("star_1"):getPositionX())
	if CONF.CHECKPOINT.get(self.id).START_NUM == 3 then
		layer:getChildByName("star_2"):setPositionX(posMid)
		layer:getChildByName("star_1"):setPositionX(posMid-wid)
		layer:getChildByName("star_3"):setPositionX(posMid+wid)
	end

	layer:getChildByName("ui_icon_arrow_40"):setPositionX(layer:getChildByName("hasExp"):getPositionX() + layer:getChildByName("hasExp"):getContentSize().width + layer:getChildByName("ui_icon_arrow_40"):getContentSize().width/2 + 10)
	layer:getChildByName("upExp"):setPositionX(layer:getChildByName("ui_icon_arrow_40"):getPositionX() + layer:getChildByName("ui_icon_arrow_40"):getContentSize().width/2 + 10)
	return layer

end

function WinLayer:touchLayer()
	local function onTouchBegan(touch, event)

		return true
	end

	local function onTouchEnded( touch, event )

		if self:getParent():getChildByName("layer_2") == nil then
			-- ADD WJJ 20180723
			local layer = require("util.UI_Helper_WinLayer"):getInstance():OnInitWinPopupPanel("layer_2", self:getParent(), self)

			local upNum = self.win_info.char_exp_bonus/10
			local ship_upNum = self.win_info.ship_exp_bonus/10
			local function update()

				if upNum < self.win_info.char_exp_bonus then

					if self.player_exp + upNum < CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL then
						local cur = self.player_exp + upNum - CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL + CONF.PLAYERLEVEL.get(self.player_level).EXP
						self.progress:setPercentage(cur/CONF.PLAYERLEVEL.get(self.player_level).EXP*100)
					else
						layer:getChildByName("info"):setVisible(false)

						if self.player_exp + upNum < CONF.PLAYERLEVEL.get(math.min(self.max_player_level,self.player_level+1)).EXP_ALL then
							local cur = self.player_exp + upNum - CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL
							self.progress:setPercentage(cur/CONF.PLAYERLEVEL.get(self.player_level+1).EXP*100)
							layer:getChildByName("lv_num"):setString(math.min(self.max_player_level,self.player_level+1))
						end
					end
					
					upNum = upNum + self.win_info.char_exp_bonus/10

					for i,v in ipairs(self.ship_list) do
						if self.ship_exp[i] + ship_upNum < CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL then
							local cur = self.ship_exp[i] + ship_upNum - CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL + CONF.SHIPLEVEL.get(self.ship_level[i]).EXP
							self.ship_progress[i]:setPercentage(cur/CONF.SHIPLEVEL.get(self.ship_level[i]).EXP*100)
						else
							if self.ship_exp[i] + ship_upNum < CONF.SHIPLEVEL.get(self.ship_level[i]+1).EXP_ALL then

								if self.ship_level[i]+1 < (player:getLevel()) then
									local cur = self.ship_exp[i]  + ship_upNum - CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL
									self.ship_progress[i]:setPercentage(cur/CONF.SHIPLEVEL.get(self.ship_level[i]+1).EXP*100)
									layer:getChildByName("ship_node_"..i):getChildByName("lv"):setString(self.ship_level[i]+1)
								else
									self.ship_progress[i]:setPercentage(100)
								end
							end
						end
					end

					ship_upNum = ship_upNum + self.win_info.ship_exp_bonus/10

				else
					scheduler:unscheduleScriptEntry(schedulerEntry)
				end

			end

			schedulerEntry = scheduler:scheduleScriptFunc(update,0.1,false)

			self.touch_ = true

			-- if player:getGuideStep() < 60 then
			-- 	guideManager:checkInterface(CONF.EInterface.kBattleOver)
			-- end
		end
	end


	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function WinLayer:onEnterTransitionFinish()
	printInfo("WinLayer:onEnterTransitionFinish()")
    self:setVisible(false)
	playEffectSound("sound/system/win.mp3")

	--if player:getGuideStep() < 60 then
	--	guideManager:checkInterface(CONF.EInterface.kBattleEnd)
	--end

	self.player_exp = player:getExp()
	self.player_level = player:getLevel()

	self.ship_exp = {}
	self.ship_level = {}
	self.ship_break = {}
	for i,v in ipairs(self.ship_list) do
		table.insert(self.ship_exp, v.exp)
		table.insert(self.ship_level, v.level)
		table.insert(self.ship_break, v.ship_break)
	end

	self.touch_ = false
	self.recv_ = false
	self.ani_ = false
	self.xxx_ = false

	-- resultData[1] = isWin
	-- resultData[2] = self:getFightTime()
	-- resultData[3] = self:getHitValue(1)
	-- resultData[4] = self:getHitValue(2)
	-- resultData[5] = self:getShipNum(1,true)
	-- resultData[6] = self:getShipNum(1,false)
	-- resultData[7] = self:getShipNum(2,true)
	-- resultData[8] = self:getShipNum(2,false)
	-- resultData[9] = self.round_

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

	if player:getCopyStar(self.id) ~= 0 then
		self.flag_ = true
	else
		self.flag_ = false
	end

	local shipNum = self.data[5]
	local shipNum_all = self.data[6]
	local round = self.data[9]

	-- local fen = (shipNum/shipNum_all)*50 + (52 - 2*round)

	-- self.star = 3
	-- local n = 3
	-- for i=n,2,-1 do
	--     if fen <= 50 + (50/(n-1))*(i-1) and fen >= 50 + (50/(n-1))*(i-2) then
	--         self.star = i 
	--         break
	--     end
	-- end

	local round_num = 0
	if round >= CONF.PARAM.get("star_round_param_1").PARAM and round < CONF.PARAM.get("star_round_param_2").PARAM then
		round_num = 1
	elseif round > CONF.PARAM.get("star_round_param_2").PARAM then
		round_num = 2
	end

	self.star = CONF.CHECKPOINT.get(self.id).START_NUM
    local totalnum = self.star
	if CONF.CHECKPOINT.get(self.id).START_NUM == 3 then
		rn:getChildByName("star_4"):setVisible(false)
	end

	self.star = self.star - round_num - (shipNum_all - shipNum)

	if self.star < 1 then
		self.star = 1
	end

    --Add By Jinxin
    local midPosX = rn:getChildByName("Node_star"):getPositionX()
    local intnum = math.floor(totalnum/2)
    local firPosX
    if totalnum%2 == 0 then
        firPosX = midPosX - ((intnum-1+0.5)*90)
    else
        firPosX = midPosX - (intnum*90)
    end
    for i = 1,totalnum do
        local pos = cc.p(firPosX + (i-1)*90,rn:getChildByName("star_"..i):getPositionY())
        rn:getChildByName("star_"..i):setPosition(pos)
    end
    ---------------
	print(self.star)

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
		checkpoint_id = self.id,
		type = 1,
		result = 1,
		star = self.star,
	}


	self.time = 0

	local strData = Tools.encode("PveReq", self.recv_msg)
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

	gl:retainLoading()

	rn:getChildByName("back"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		if self.recv_ == false then
			if not gl:isLoading() then
				self.time = 0

				local strData = Tools.encode("PveReq", self.recv_msg)
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

				gl:retainLoading()
			end
		else

			if self.ani_ then
				return
			end

			if self:getParent():getChildByName("layer_2") == nil then
				guideManager:checkInterface(CONF.EInterface.kBattleOver)
				if player:getGuideStep() > 60 then
					guideManager:setGuideType( false)
				end

				-- ADD WJJ 20180723
				local layer = require("util.UI_Helper_WinLayer"):getInstance():OnInitWinPopupPanel("layer_2", self:getParent(), self)

				for i,v in ipairs(self.ship_list) do
					if self.ship_level[i] < player:getLevel() then
						if self.ship_exp[i] + self.win_info.ship_exp_bonus > CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL then
							layer:getChildByName("ship_node_"..i):getChildByName("text"):setVisible(true)
							layer:getChildByName("ship_node_"..i):getChildByName("text"):runAction(cc.MoveBy:create(2, cc.p(0,50)))
						end
					end
				end

				local upNum = self.win_info.char_exp_bonus/10
				local ship_upNum = self.win_info.ship_exp_bonus/10
				local function update()
					if upNum <= self.win_info.char_exp_bonus then
						if self.player_exp + upNum < CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL then
							local cur = self.player_exp + upNum - CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL + CONF.PLAYERLEVEL.get(self.player_level).EXP
							self.progress:setPercentage(cur/CONF.PLAYERLEVEL.get(self.player_level).EXP*100)
						else
							layer:getChildByName("info"):setVisible(false)

							if self.player_exp + upNum < CONF.PLAYERLEVEL.get(math.min(self.max_player_level,self.player_level+1)).EXP_ALL then
								local cur = self.player_exp + upNum - CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL
								self.progress:setPercentage(cur/CONF.PLAYERLEVEL.get(math.min(self.max_player_level,self.player_level+1)).EXP*100)
								layer:getChildByName("lv_num"):setString(math.min(self.max_player_level,self.player_level+1))
							end
						end
						
						upNum = upNum + self.win_info.char_exp_bonus/10

						for i,v in ipairs(self.ship_list) do
							if self.ship_exp[i] + ship_upNum < CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL then
								local cur = self.ship_exp[i] + ship_upNum - CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL + CONF.SHIPLEVEL.get(self.ship_level[i]).EXP
								self.ship_progress[i]:setPercentage(cur/CONF.SHIPLEVEL.get(self.ship_level[i]).EXP*100)
							else

								if self.ship_exp[i] + ship_upNum < CONF.SHIPLEVEL.get(self.ship_level[i]+1).EXP_ALL then

									if self.ship_level[i]+1 < player:getLevel() then
										local cur = self.ship_exp[i]  + ship_upNum - CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL
										self.ship_progress[i]:setPercentage(cur/CONF.SHIPLEVEL.get(self.ship_level[i]+1).EXP*100)
										layer:getChildByName("ship_node_"..i):getChildByName("lv"):setString(self.ship_level[i]+1)

										-- layer:getChildByName("ship_node_"..i):getChildByName("text"):setVisible(true)
										-- layer:getChildByName("ship_node_"..i):getChildByName("text"):runAction(cc.MoveBy:create(3, cc.p(0,30)))
									else
										self.ship_progress[i]:setPercentage(100)
									end
								end
							end
						end

						ship_upNum = ship_upNum + self.win_info.ship_exp_bonus/10

					else
						scheduler:unscheduleScriptEntry(schedulerEntry)


						if self.player_exp + self.win_info.char_exp_bonus > CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL then
							local up_level = 0
							for i,v in ipairs(CONF.PLAYERLEVEL.getIDList()) do
								if self.player_exp + self.win_info.char_exp_bonus < CONF.PLAYERLEVEL.get(v).EXP_ALL then
									up_level = i
									break
								end
							end

							createLevelUpNode(up_level, self.player_level)

							self.xxx_ = true
						else
							self.xxx_ = true


						end

					end

				end

				schedulerEntry = scheduler:scheduleScriptFunc(update,0.1,false)

				

				self.touch_ = true

				-- if player:getGuideStep() < 805 then
				-- 	guideManager:checkInterface(CONF.EInterface.kBattleOver)
				-- end
			end
		end
	end)

	local function updateGl( ... )
		self.time = self.time + 1 
		if self.time > 5 then
			if gl:isLoading() then
				gl:releaseLoading()
			end
			self.time = 0
		end
	end


	schedulerGl = scheduler:scheduleScriptFunc(updateGl,0.1,false)


	local function recvMsg()
		print("WinLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PVE_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("PveResp",strData)
			print(proto.result)
			if proto.result ~= 0 then
				printInfo("proto error")
			else

				self.recv_ = true

				flurryLogEvent("pve", {result = "win-"..self.star, copy_id = tostring(self.id)}, 2)

				local gold_num = CONF.CHECKPOINT.get(self.id).GOLD
				flurryLogEvent("get_gold_by_pve", {copy_id = tostring(self.id), gold_num = gold_num}, 1, gold_num)


				local area_idd = CONF.COPY.get(CONF.CHECKPOINT.get(self.id).AREA_ID).AREA
				flurryLogEvent("area_star_info", {area_id = tostring(area_idd), area_star = tostring(player:getAreaStarNum(area_idd)) }, 2)

				if proto.type == 0 then
					--存exp
					g_Player_OldExp.oldExp = 0
					g_Player_OldExp.oldExp = player:getNowExp()
					g_Player_OldExp.oldLevel = player:getLevel()


					local name = CONF:getStringValue(CONF.TRIAL_LEVEL.get(self.id).Medt_LEVEL)
					local enemy_name = getEnemyIcon(CONF.TRIAL_LEVEL.get(self.id).MONSTER_ID)
					app:pushToRootView("BattleScene/BattleScene", {BattleType.kCheckPoint,Tools.decode("PveResp",strData),true,name,enemy_name})

				elseif proto.type == 1 then

					print("fight over..win")

					-- local levelInfo = {level_id = self.id, level_star = self.star}

					-- player:setLevelInfo(levelInfo)		

					if player:getGuideStep() < 900 then
						-- guideManager:addGuideStep(player:getGuideStep())
					end			



					self.win_info = proto
					-- self:touchLayer()
                    self:skipScene()

				end
			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.tongguanListener_ = cc.EventListenerCustom:create("tongguan", function (event)
		self.tongguan = {index = event.index, flag = event.flag}
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.tongguanListener_, FixedPriority.kNormal)

	--self.levelListener_ = cc.EventListenerCustom:create("levelupOver", function (event)
	--	print("aaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
	--	if player:getGuideStep() < 60 then
	--		guideManager:checkInterface(CONF.EInterface.kBattleOver)
	--	end
	--end)
--	eventDispatcher:addEventListenerWithFixedPriority(self.levelListener_, FixedPriority.kNormal)

	self.ani_ = true
	animManager:runAnimOnceByCSB(rn, "BattleScene/WinLayer/WinLayer.csb", "intro", function ( ... )
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

function WinLayer:onExitTransitionStart()
	printInfo("WinLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.tongguanListener_)
	eventDispatcher:removeEventListener(self.levelListener_)

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	if schedulerGl ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerGl)
	end

end

function WinLayer:onCreate(data)
	print("~~~ WinLayer onCreate ")
	if data then
		self.data_ = data

		local is_data_ok = data["checkpoint_id"] ~= nil
		if(is_data_ok) then
			local id = data["checkpoint_id"]
			local init_data = data["data"]
			local enemyname = data["enemyName"]
			local ship_list = data["ship_list"]
			self:init(id,init_data, enemyname,ship_list)
		end
	end


end

function WinLayer:skipScene()

	if self.recv_ == false then
		if not gl:isLoading() then
			self.time = 0

			local strData = Tools.encode("PveReq", self.recv_msg)
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVE_REQ"),strData)

			gl:retainLoading()
		end
	else

--		if self.ani_ then
--			return
--		end

		if self:getParent():getChildByName("layer_2") == nil then
			guideManager:checkInterface(CONF.EInterface.kBattleOver)
			if player:getGuideStep() > 60 then			
				guideManager:setGuideType( false)
			end

			-- ADD WJJ 20180723
			local layer = require("util.UI_Helper_WinLayer"):getInstance():OnInitWinPopupPanel("layer_2", self:getParent(), self)

			for i,v in ipairs(self.ship_list) do
				if self.ship_level[i] < player:getLevel() then
					if self.ship_exp[i] + self.win_info.ship_exp_bonus > CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL then
						layer:getChildByName("ship_node_"..i):getChildByName("text"):setVisible(true)
						layer:getChildByName("ship_node_"..i):getChildByName("text"):runAction(cc.MoveBy:create(2, cc.p(0,50)))
					end
				end
			end

			local upNum = self.win_info.char_exp_bonus/10
			local ship_upNum = self.win_info.ship_exp_bonus/10
			local function update()
				if upNum <= self.win_info.char_exp_bonus then
					if self.player_exp + upNum < CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL then
						local cur = self.player_exp + upNum - CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL + CONF.PLAYERLEVEL.get(self.player_level).EXP
						self.progress:setPercentage(cur/CONF.PLAYERLEVEL.get(self.player_level).EXP*100)
					else
						layer:getChildByName("info"):setVisible(false)
						if self.player_exp + upNum < CONF.PLAYERLEVEL.get(math.min(self.max_player_level,self.player_level+1)).EXP_ALL then
							local cur = self.player_exp + upNum - CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL
							self.progress:setPercentage(cur/CONF.PLAYERLEVEL.get(math.min(self.max_player_level,self.player_level+1)).EXP*100)
							layer:getChildByName("lv_num"):setString(math.min(self.max_player_level,self.player_level+1))
						end
					end
						
					upNum = upNum + self.win_info.char_exp_bonus/10

					for i,v in ipairs(self.ship_list) do
						if self.ship_exp[i] + ship_upNum < CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL then
							local cur = self.ship_exp[i] + ship_upNum - CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL + CONF.SHIPLEVEL.get(self.ship_level[i]).EXP
							self.ship_progress[i]:setPercentage(cur/CONF.SHIPLEVEL.get(self.ship_level[i]).EXP*100)
						else

							if self.ship_exp[i] + ship_upNum < CONF.SHIPLEVEL.get(self.ship_level[i]+1).EXP_ALL then

								if self.ship_level[i]+1 < player:getLevel() then
									local cur = self.ship_exp[i]  + ship_upNum - CONF.SHIPLEVEL.get(self.ship_level[i]).EXP_ALL
									self.ship_progress[i]:setPercentage(cur/CONF.SHIPLEVEL.get(self.ship_level[i]+1).EXP*100)
									layer:getChildByName("ship_node_"..i):getChildByName("lv"):setString(self.ship_level[i]+1)

									-- layer:getChildByName("ship_node_"..i):getChildByName("text"):setVisible(true)
									-- layer:getChildByName("ship_node_"..i):getChildByName("text"):runAction(cc.MoveBy:create(3, cc.p(0,30)))
								else
									self.ship_progress[i]:setPercentage(100)
								end
							end
						end
					end

					ship_upNum = ship_upNum + self.win_info.ship_exp_bonus/10

				else
					scheduler:unscheduleScriptEntry(schedulerEntry)


					if self.player_exp + self.win_info.char_exp_bonus > CONF.PLAYERLEVEL.get(self.player_level).EXP_ALL then
						local up_level = 0
						for i,v in ipairs(CONF.PLAYERLEVEL.getIDList()) do
							if self.player_exp + self.win_info.char_exp_bonus < CONF.PLAYERLEVEL.get(v).EXP_ALL then
								up_level = i
								break
							end
						end

						createLevelUpNode(up_level, self.player_level)

						self.xxx_ = true
					else
						self.xxx_ = true


					end

				end

			end

			schedulerEntry = scheduler:scheduleScriptFunc(update,0.1,false)

				

			self.touch_ = true

			-- if player:getGuideStep() < 805 then
			-- 	guideManager:checkInterface(CONF.EInterface.kBattleOver)
			-- end
		end
	end
end


return WinLayer