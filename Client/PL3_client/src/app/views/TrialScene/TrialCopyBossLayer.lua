local player = require("app.Player"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local TrialCopyBossLayer = class("TrialCopyBossLayer", cc.load("mvc").ViewBase)

TrialCopyBossLayer.RESOURCE_FILENAME = "CopyScene/CopyBossLayer.csb"

TrialCopyBossLayer.RUN_TIMELINE = true

TrialCopyBossLayer.NEED_ADJUST_POSITION = true

TrialCopyBossLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["form"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function TrialCopyBossLayer:onCreate(data)
	self.data_ = data

end

function TrialCopyBossLayer:OnBtnClick(event)
	printInfo(event.name)

	local conf = CONF.TRIAL_LEVEL.get(self.data_.level_id)
	
	if event.name == "ended" and event.target:getName() == "form" then
		if self.data_.name and self.data_.name ~= "" then
			self:getApp():addView2Top("NewFormLayer", {from = "trial_fight", id = self.data_.level_id, index = self.data_.index, target_name = self.data_.name, icon_id = self.data_.icon_id})
		else
		   self:getApp():addView2Top("NewFormLayer", {from = "trial_fight", id = self.data_.level_id, index = self.data_.index})
		end

		-- if player:getStrength() < CONF.TRIAL_LEVEL.get(self.data_.level_id).STRENGTH then
		--     tips:tips(CONF:getStringValue("strength_not_enought"))
		--     return
		-- end

		-- if self.data_.name then
			
		--     local strData = Tools.encode("TrialPveStartReq", {
		--         level_id = self.data_.level_id,
		--         target_name = self.data_.name,
		--     })
		--     GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)
		-- else

		--     local strData = Tools.encode("TrialPveStartReq", {
		--         level_id = self.data_.level_id,
		--     })
		--     GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)
		-- end

		-- gl:retainLoading()

	end

	if event.name == "ended" and event.target:getName() == "close" then
		printInfo("close")

		self:getApp():popView()   
	end

end

function TrialCopyBossLayer:onEnter()
  
	printInfo("TrialCopyBossLayer:onEnter()")

end

function TrialCopyBossLayer:onExit()
	
	printInfo("TrialCopyBossLayer:onExit()")
end

function TrialCopyBossLayer:onEnterTransitionFinish()

	printInfo("TrialCopyBossLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()
	
	local forms_num = 0
    for i,v in ipairs(player:getTrialLineup(self.data_.index)) do
        if v ~= 0 then
            forms_num = forms_num + 1
        end
    end

    local ship_num = 0
    for i,v in ipairs(player:getTrialShipList(self.data_.index)) do
        if v.hp ~= 0 then
            ship_num = ship_num + 1
        end
    end

    if forms_num < ship_num then
        rn:getChildByName("form"):getChildByName("point"):setVisible(true)
    end

	rn:getChildByName("e_text"):setString(CONF:getStringValue("EnemyInfo"))
	rn:getChildByName("form"):getChildByName("text"):setString(CONF:getStringValue("form"))
	rn:getChildByName("enemy_team"):setString(CONF:getStringValue("enemyForm"))
	rn:getChildByName("level_fight"):setString(CONF:getStringValue("combat"))
	
	local conf = CONF.TRIAL_LEVEL.get(self.data_.level_id)
	if conf.Medt_LEVEL == "0" or conf.Medt_LEVEL == 0 then
		rn:getChildByName("copy_name"):setString(CONF:getStringValue(CONF.TRIAL_SCENE.get(self.data_.level_id).BUILDING_NAME))
	else
		rn:getChildByName("copy_name"):setString(CONF.STRING.get(conf.Medt_LEVEL).VALUE)
	end

	if conf.INTRODUCE_ID == "0" or conf.INTRODUCE_ID == 0 then
		rn:getChildByName("ins"):setString(CONF:getStringValue("null"))
	else
		rn:getChildByName("ins"):setString(CONF.STRING.get(conf.INTRODUCE_ID).VALUE)
	end

	rn:getChildByName("level_fight_dnum"):setString(string.format("%d", conf.COMBAT))
	rn:getChildByName("level_fight_dnum"):setPositionX(rn:getChildByName("level_fight"):getPositionX() + rn:getChildByName("level_fight"):getContentSize().width)
	if tonumber(player:getPower()) < conf.COMBAT then
		rn:getChildByName("level_fight_dnum"):setTextColor(cc.c4b(255,0,0,255))
		-- rn:getChildByName("level_fight_dnum"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,-0.5))
	end

	-- rn:getChildByName("info"):getChildByName("text"):setString(CONF:getStringValue("information"))
	rn:getChildByName("drop"):getChildByName("text"):setString(CONF:getStringValue("dungeonDrop"))

	rn:getChildByName("strength"):setString(CONF:getStringValue("use strength"))
	rn:getChildByName("strength_num"):setString(conf.STRENGTH)
	rn:getChildByName("strength_num_my"):setString("/"..player:getStrength())

	if tonumber(player:getStrength()) < conf.STRENGTH then
		rn:getChildByName("strength_num"):setTextColor(cc.c4b(255,0,0,255))
		-- rn:getChildByName("strength_num"):enableShadow(cc.c4b(255, 0, 0, 255),cc.size(0.5,-0.5))
	end

	local x,y = rn:getChildByName("item_1"):getPosition()
	rn:getChildByName("item_1"):removeFromParent()

	--九宫格
	for i,v in ipairs(conf.MONSTER_ID) do
		if v == 0 then
			rn:getChildByName(string.format("cube_%d", i)):removeFromParent()
		else
			if v < 0 then
				rn:getChildByName(string.format("cube_%d", i)):setTexture("CopyScene/ui/red0"..i..".png")
			elseif v > 0 then
				rn:getChildByName(string.format("cube_%d", i)):setTexture("CopyScene/ui/yellow0"..i..".png")
			end
		end
	end

	--摆boss
	local function createEnemyShip( shipId )

		local shipConf = CONF.AIRSHIP.get(shipId)

		local enemyShip = require("app.ExResInterface"):getInstance():FastLoad("CopyScene/EnemyShip.csb")
		enemyShip:getChildByName("ship"):removeFromParent()

		local res = string.format("sfx/%s", shipConf.RES_ID)

		local ship = require("app.ExResInterface"):getInstance():FastLoad(res)
		ship:setName("ship")
		enemyShip:addChild(ship)

		animManager:runAnimByCSB(ship, res, "idle_2")

		local t = enemyShip:getChildByName("type")
		t:setTexture(string.format("ShipType/%d.png", shipConf.TYPE))
		t:setLocalZOrder(1)
		t:setVisible(false)


		return enemyShip
	end

	local monsterNums = {}
	for i,v in ipairs(conf.MONSTER_ID) do
		if v ~= 0 then
			if monsterNums[1] then
				local has = false
				for i2,v2 in ipairs(monsterNums) do
					if v == v2 then
						has = true
					end
				end

				if not has then
					monsterNums[table.getn(monsterNums)+1] = v
				end
			else
				monsterNums[1] = v
			end
		end
	end

	local function sort( a,b )
		if a < 0 or b < 0 then
			if a > b then
				return a > b
			end
		end
	end

	table.sort(monsterNums, sort)

	animManager:runAnimByCSB(rn:getChildByName("liuguang"), "Common/sfx/jiemianliuguang3.csb", "1")

	animManager:runAnimOnceByCSB(self:getResourceNode(),"CopyScene/CopyBossLayer.csb" ,"intro", function ( ... )
		for i,v in ipairs(conf.ITEMS_ID) do

			local itemNode = require("util.ItemNode"):create():init(v)

			rn:addChild(itemNode)
			itemNode:setPosition(cc.p(x+120*(i-1), y))
			itemNode:setName(string.format("item_%d", i))
		end

		for i,v in ipairs(monsterNums) do

			local isBoss = false
			if v < 0 then
				v = -v
				isBoss = true
			end

			local ship = createEnemyShip(v)
			
			if isBoss then
				ship:setPosition(cc.p(80+(150*i)+ 50, 300))
				self:addChild(ship)

				--圈
				-- local circle = require("app.ExResInterface"):getInstance():FastLoad("StageScene/sfx/UI_xuanzhe_1.csb")
				-- circle:setPosition(cc.p(ship:getPositionX()-40, ship:getPositionY()- 60))
				-- circle:setScale(2)
				-- self:addChild(circle)
				
				-- animManager:runAnimByCSB(circle, "StageScene/sfx/UI_xuanzhe_1.csb",  "1")

			else
				ship:setPosition(cc.p(80+(150*i), 300))
				self:addChild(ship)
			end
		end

		rn:getChildByName("strength_num"):setPositionX(rn:getChildByName("strength"):getPositionX() + rn:getChildByName("strength"):getContentSize().width + 5)
		rn:getChildByName("strength_num_my"):setPositionX(rn:getChildByName("strength_num"):getPositionX() + rn:getChildByName("strength_num"):getContentSize().width)
		rn:getChildByName("strength_icon"):setPositionX(rn:getChildByName("strength_num_my"):getPositionX() + rn:getChildByName("strength_num_my"):getContentSize().width + 2)
		rn:getChildByName("level_fight_dnum"):setPositionX(rn:getChildByName("level_fight"):getPositionX() + rn:getChildByName("level_fight"):getContentSize().width)
	end)

	local function recvMsg()
		print("TrialCopyBossLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("TrialPveStartResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				local strength = proto.user_sync.user_info.strength
				if strength == 0 then
					player:setStrength(strength)
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
				end
				local hp = 0
				for i,v in ipairs(player:getTrialShipList(self.data_.index)) do
					hp = hp + v.hp
				end

				--存exp
				-- g_Player_OldExp.oldExp = 0
				-- g_Player_OldExp.oldExp = player:getNowExp()
				-- g_Player_OldExp.oldLevel = player:getLevel()

				--存stageInfo
				g_Views_config.copy_id = self.data_.level_id
				g_Views_config.slPosX = self.data_.slPosX
				g_Views_config.hp = hp

				local name = CONF:getStringValue(CONF.TRIAL_LEVEL.get(self.data_.level_id).Medt_LEVEL)
				local enemy_name = getEnemyIcon(CONF.TRIAL_LEVEL.get(self.data_.level_id).MONSTER_ID)
				self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kTrial,Tools.decode("TrialPveStartResp",strData),true,name, enemy_name})

			end
			
		end
	end
		
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

end


function TrialCopyBossLayer:onExitTransitionStart()

	printInfo("TrialCopyBossLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)


end

return TrialCopyBossLayer