local player = require("app.Player"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local CopyBossLayer = class("CopyBossLayer", cc.load("mvc").ViewBase)

CopyBossLayer.RESOURCE_FILENAME = "CopyScene/CopyBossLayer.csb"

CopyBossLayer.RUN_TIMELINE = true

CopyBossLayer.NEED_ADJUST_POSITION = true

CopyBossLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["form"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

function CopyBossLayer:onCreate(data)
	self.data_ = data

end

function CopyBossLayer:OnBtnClick(event)
	printInfo(event.name)

	local conf = CONF.CHECKPOINT.get(tonumber(string.format("%d", self.data_.copy_id)))
	local name = CONF:getStringValue(conf.NAME_ID)
	
	if event.name == "ended" and event.target:getName() == "form" then
		playEffectSound("sound/system/click.mp3")
		self:getApp():addView2Top("NewFormLayer",{from = "copy", id = conf.ID, stageInfo = self.data_})

	end

	if event.name == "ended" and event.target:getName() == "close" then
		playEffectSound("sound/system/return.mp3")

		self:getApp():pushToRootView("LevelScene", {area = math.floor(self.data_.copy_id/1000000), stage = math.floor(self.data_.copy_id/100), index = self.data_.copy_id%100})   
	end

end

function CopyBossLayer:onEnter()
  
	printInfo("CopyBossLayer:onEnter()")

end

function CopyBossLayer:onExit()
	
	printInfo("CopyBossLayer:onExit()")
end

function CopyBossLayer:onEnterTransitionFinish()

	printInfo("CopyBossLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()

	rn:getChildByName("e_text"):setString(CONF:getStringValue("EnemyInfo"))
	rn:getChildByName("enemy_team"):setString(CONF:getStringValue("enemyForm"))
	rn:getChildByName("level_fight"):setString(CONF:getStringValue("recommendPower"))
	

	local forms_num = 0
	for i,v in ipairs(player:getForms()) do
		if v ~= 0 then
			forms_num = forms_num + 1
		end
	end

	if forms_num < CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM then
		rn:getChildByName("form"):getChildByName("point"):setVisible(true)
	end

	local conf = CONF.CHECKPOINT.get(tonumber(string.format("%d", self.data_.copy_id)))
	rn:getChildByName("copy_name"):setString(CONF.STRING.get(conf.NAME_ID).VALUE)
	rn:getChildByName("ins"):setString(CONF.STRING.get(conf.INTRODUCE_ID).VALUE)
	rn:getChildByName("form"):getChildByName("text"):setString(CONF:getStringValue("form"))

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

	rn:getChildByName("item_1"):setVisible(false)

	--九宫格
	for i,v in ipairs(conf.MONSTER_LIST) do
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
	for i,v in ipairs(conf.MONSTER_LIST) do
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

	local x,y = rn:getChildByName("item_1"):getPosition()

	animManager:runAnimByCSB(rn:getChildByName("liuguang"), "Common/sfx/jiemianliuguang3.csb", "1")
	
	animManager:runAnimOnceByCSB(self:getResourceNode(),"CopyScene/CopyBossLayer.csb" ,"intro", function (  )
		for i,v in ipairs(conf.ITEMS_LIST) do
			
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
				-- ship:setPosition(cc.p(80+(150*i)+ 50, 240))
				ship:setPosition(cc.p(rn:getChildByName("Node_5"):getPosition()))
				rn:addChild(ship)

				--圈
				-- local circle = require("app.ExResInterface"):getInstance():FastLoad("StageScene/sfx/UI_xuanzhe_1.csb")
				-- circle:setPosition(cc.p(ship:getPositionX()-40, ship:getPositionY()- 60))
				-- circle:setScale(2)
				-- self:addChild(circle)
				
				-- animManager:runAnimByCSB(circle, "StageScene/sfx/UI_xuanzhe_1.csb",  "1")

			else
				ship:setPosition(cc.p(rn:getChildByName("Node_"..i):getPosition()))
				rn:addChild(ship)
			end
		end

		rn:getChildByName("strength_num"):setPositionX(rn:getChildByName("strength"):getPositionX() + rn:getChildByName("strength"):getContentSize().width + 5)
		rn:getChildByName("strength_num_my"):setPositionX(rn:getChildByName("strength_num"):getPositionX() + rn:getChildByName("strength_num"):getContentSize().width)
		rn:getChildByName("strength_icon"):setPositionX(rn:getChildByName("strength_num_my"):getPositionX() + rn:getChildByName("strength_num_my"):getContentSize().width + 2)
		rn:getChildByName("level_fight_dnum"):setPositionX(rn:getChildByName("level_fight"):getPositionX() + rn:getChildByName("level_fight"):getContentSize().width)
	end)
end


function CopyBossLayer:onExitTransitionStart()

	printInfo("CopyBossLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return CopyBossLayer