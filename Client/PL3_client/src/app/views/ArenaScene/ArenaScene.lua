local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local messageBox = require("util.MessageBox"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local ArenaScene = class("ArenaScene", cc.load("mvc").ViewBase)

ArenaScene.RESOURCE_FILENAME = "ArenaScene/ArenaScene.csb"

ArenaScene.NEED_ADJUST_POSITION = true

ArenaScene.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["task"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["shop"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["rank"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["form"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["record"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["btn_cishu"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["change"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["go"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}


local schedulerEntry = nil

local touchMove = false

local touchHead = false

function ArenaScene:OnBtnClick(event)

	if event.name == "ended" and event.target:getName() == "close" then
		playEffectSound("sound/system/return.mp3")
		self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
		return
	end

	playEffectSound("sound/system/click.mp3")

	if event.name == "ended" and event.target:getName() == "task" then
		local rn = self:getResourceNode()
		local function getRewardID( )
			local rank =rn:getChildByName("rank_num"):getTag()

			if rank >= 1 and rank <= 10 then
				return 10001
			elseif rank >= 11 and rank <= 50 then
				return 10011
			elseif rank >= 51 and rank <= 100 then
				return 10051
			elseif rank >= 101 and rank <= 500 then
				return 10101
			else
				return 10501
			end
		end


		local node = require("app.ExResInterface"):getInstance():FastLoad("Common/RewardNode.csb")

		node:getChildByName("bg"):setSwallowTouches(true)
		node:getChildByName("bg"):addClickEventListener(function ()
			playEffectSound("sound/system/return.mp3")
			node:removeFromParent()
		end)

		local rf = CONF.ARENA_REWARD.get(getRewardID())
		local items = {}

		for i=1,6 do

			local itemName = rf["ITEM_ID"..i]

			if itemName ~= 0 then

				local item_conf = CONF.ITEM.get(itemName)

				local itemNode = require("util.ItemNode"):create():init(itemName, rf["ITEM_NUM"..i])

				table.insert(items, itemNode)
			end
		end

		local x,y = node:getChildByName("item"):getPosition()

		if #items%2 == 0 then
			for i,v in ipairs(items) do
					v:setPosition(15 + (i-1)*100 - #items/2*100, y)
					node:addChild(v)
			end
		else
			for i,v in ipairs(items) do
					v:setPosition(x + (i-1)*100 - (#items-1)/2*100, y)
					node:addChild(v)
			end
		end 

		node:getChildByName("item"):removeFromParent()

		if player:getArenaData().daily_reward == 1 then

			node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("Get"))

			node:getChildByName("yes"):addClickEventListener(function ( sender )
				playEffectSound("sound/system/click.mp3")
				local strData = Tools.encode("ArenaGetDailyRewardReq", {
					result = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_GET_DAILY_REWARD_REQ"),strData)

				gl:retainLoading()

				node:removeFromParent()
			end)

		elseif player:getArenaData().daily_reward == 0 then
			node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("closed"))

			node:getChildByName("yes"):addClickEventListener(function ( sender )
				playEffectSound("sound/system/return.mp3")
				node:removeFromParent()
			end)

		elseif player:getArenaData().daily_reward == 2 then
			node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("has_get"))

			node:getChildByName("yes"):addClickEventListener(function ( sender )
				playEffectSound("sound/system/return.mp3")
				node:removeFromParent()
			end)
		end

		self:addChild(node)
		tipsAction(node)
  		
	elseif event.name == "ended" and event.target:getName() == "shop" then

		self:getApp():addView2Top("ArenaScene/ArenaTitleLayer")
		
	elseif event.name == "ended" and event.target:getName() == "rank" then
		if self:getResourceNode():getChildByName("rank_node") then
			return
		end

		-- self.rank_ = require("app.views.ArenaScene.RankNode"):create()
		-- self.rank_:init(self, {})
		-- self:getResourceNode():addChild(self.rank_)
		-- self.rank_:setPosition(cc.p(568,384))
		-- self.rank_:setName("rank_node")

		self:getApp():pushView("RankLayer/RankLayer",{type = "arena_rank"}) 
	
	elseif event.name == "ended" and event.target:getName() == "form" then

		-- self:getApp():pushView("NewFormScene", {from = "ships"})
		self:getApp():addView2Top("NewFormLayer", {from = "special"})

	elseif event.name == "ended" and event.target:getName() == "record" then

		self:getApp():addView2Top("ArenaScene/ArenaRecordLayer")

	elseif event.name == "ended" and event.target:getName() == "btn_cishu" then

		self.type = 1
		local function func(  )
			if player:getMoney() < Tools.calAddArenaTimesNeedMoney(player:getArenaData().purchased_challenge_times) then
				-- tips:tips(CONF:getStringValue("no enought credit"))

				local function func()
					local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

					rechargeNode:init(self, {index = 1})
					self:addChild(rechargeNode)
				end

				local messageBox = require("util.MessageBox"):getInstance()
				messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
				return
			end

			local strData = Tools.encode("ArenaAddTimesReq", {
				type = 1,
				times = 1,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_TIMES_REQ"),strData)
			
			gl:retainLoading()
		end

		local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("buy arena times"), Tools.calAddArenaTimesNeedMoney(player:getArenaData().purchased_challenge_times), func)

		self:addChild(node)
		tipsAction(node)

	elseif event.name == "ended" and event.target:getName() == "change" then
		local function resetArena()
			if player:getMoney() < Tools.calArenaUpdateMoney(1) then 
				-- tips:tips(CONF:getStringValue("no enought credit"))

				local function func()
					local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

					rechargeNode:init(self, {index = 1})
					self:addChild(rechargeNode)
				end

				local messageBox = require("util.MessageBox"):getInstance()
				messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
			else
				if self.select_index ~= 0 then
					self:resetEnemy(self.select_index, false)
				end

				self.refresh = true
				local strData = Tools.encode("ArenaInfoReq", {
					type = 2,
					-- user_name = player:getName(),
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_REQ"),strData)

				gl:retainLoading()
				
			end
		end

		messageBox:reset(CONF.STRING.get("arena_update").VALUE, resetArena)

	elseif event.name == "ended" and event.target:getName() == "go" then

		local function func()
			self.type = 2
			local strData = Tools.encode("ArenaAddTimesReq", {
				type = 2,
				times = 5,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_TIMES_REQ"),strData)
			
			gl:retainLoading()
		end
		
		local time = 120 - (player:getServerTime() - player:getArenaData().last_failed_time)

		local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("arena_reset_cd"), Tools.getSpeedUpNeedMoney(time), func)

		self:addChild(node)
		tipsAction(node)

	end

end

function ArenaScene:resetInfo()

	local rn = self:getResourceNode()

	rn:getChildByName("point_text"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))

	if player:getArenaData().last_failed_time > 0 then
		if 120 - (player:getServerTime() - player:getArenaData().last_failed_time) > 0 then
			rn:getChildByName("time"):setString(formatTime(120 - (player:getServerTime() - player:getArenaData().last_failed_time)))
			rn:getChildByName("time"):setVisible(true)
			rn:getChildByName("go"):setVisible(true)
			-- rn:getChildByName("time_icon"):setVisible(true)
			-- rn:getChildByName("time_back"):setVisible(true)

			-- rn:getChildByName("cishu"):setPosition(self.time_pos.times)
			-- rn:getChildByName("cishu_num"):setPosition(self.time_pos.time_num)
			-- rn:getChildByName("btn_cishu"):setPosition(self.time_pos.time_btn)
		else
			rn:getChildByName("time"):setVisible(false)
			rn:getChildByName("go"):setVisible(false)
			-- rn:getChildByName("time_icon"):setVisible(false)
			-- rn:getChildByName("time_back"):setVisible(false)

			-- rn:getChildByName("cishu"):setPosition(cc.p(rn:getChildByName("time_icon"):getPosition()))
			-- rn:getChildByName("cishu_num"):setPosition(cc.p(rn:getChildByName("time"):getPosition()))
			-- rn:getChildByName("btn_cishu"):setPosition(cc.p(rn:getChildByName("go"):getPosition()))
		end
	else
		rn:getChildByName("time"):setVisible(false)
		rn:getChildByName("go"):setVisible(false)
		-- rn:getChildByName("time_icon"):setVisible(false)
		-- rn:getChildByName("time_back"):setVisible(false)

		-- rn:getChildByName("cishu"):setPosition(cc.p(rn:getChildByName("time_icon"):getPosition()))
		-- rn:getChildByName("cishu_num"):setPosition(cc.p(rn:getChildByName("time"):getPosition()))
		-- rn:getChildByName("btn_cishu"):setPosition(cc.p(rn:getChildByName("go"):getPosition()))
	end
	
	rn:getChildByName("fight_num"):setString(player:getPower())
	rn:getChildByName("honor_num"):setString(player:getArenaData().honour_point)   

	local shipNum = 0
	for i,v in ipairs(player:getForms()) do
		if v ~= 0 then
			shipNum = shipNum + 1
		end
	end
	rn:getChildByName("form"):getChildByName("form_on_num"):setString(shipNum)
	rn:getChildByName("form"):getChildByName("form_max_num"):setString("/"..CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM)

	rn:getChildByName("cishu_num"):setString(player:getArenaData().challenge_times)


	if self.their_list_ then

		if player:getArenaData().daily_reward == 2 then
			-- rn:getChildByName("task"):setTouchEnabled(false)
			-- rn:getChildByName("task"):getChildByName("grey"):setVisible(true)

			rn:getChildByName("task_num"):setVisible(false)
			rn:getChildByName("task_max_num"):setVisible(false)

			rn:getChildByName("liuguang"):setVisible(false)
		else

			if player:getArenaData().daily_reward == 0 then
				-- rn:getChildByName("task"):setTouchEnabled(false)
				-- rn:getChildByName("task"):getChildByName("grey"):setVisible(true)
				-- rn:getChildByName("task"):getChildByName("icon"):setTexture("Common/ui/ui_icon_box_gray.png")

				local num = 0
				for i,v in ipairs(player:getArenaData().challenge_list) do
					if v.isChallenged then
						num = num + 1
					end
				end

				rn:getChildByName("task_num"):setString(num)

				rn:getChildByName("liuguang"):setVisible(false)
				
			elseif player:getArenaData().daily_reward == 1 then
				-- rn:getChildByName("task"):setTouchEnabled(true)
				-- rn:getChildByName("task"):getChildByName("grey"):setVisible(false)
				-- rn:getChildByName("task"):getChildByName("icon"):setTexture("Common/ui/ui_icon_box.png")

				rn:getChildByName("task_num"):setString(5)

				rn:getChildByName("liuguang"):setVisible(true)
			end

		end
		
	end

	-- local ok = true

	-- for i,v in ipairs(player:getArenaData().challenge_list) do
	--     if v.isChallenged == false then 
	--         ok = false
	--         break
	--     end
	-- end

	-- local type_ = 1
	-- if ok then
	--     type_ = 2
	-- end

	

end


function ArenaScene:createEnemyLineup(info)
	local node = require("app.ExResInterface"):getInstance():FastLoad("ArenaScene/enemy_lineup.csb")
	-- node:getChildByName("Text_First"):setString(CONF:getStringValue("front_row"))
	-- node:getChildByName("Text_Second"):setString(CONF:getStringValue("middle_row"))
	-- node:getChildByName("Text_Third"):setString(CONF:getStringValue("back_row"))
	node:getChildByName("Text_1"):setString(CONF:getStringValue("enemyForm"))

	local function createEnemyShip( shipId, lv )

		local shipConf = CONF.AIRSHIP.get(shipId)

		local enemyShip = require("app.ExResInterface"):getInstance():FastLoad("ArenaScene/lineup_ship.csb")
		enemyShip:getChildByName("ship"):removeFromParent()

		local res = string.format("sfx/%s", shipConf.RES_ID)

		local ship = require("app.ExResInterface"):getInstance():FastLoad(res)
		ship:setName("ship")
		enemyShip:addChild(ship)

		animManager:runAnimByCSB(ship, res, "idle_1")
		animManager:runAnimByCSB(ship, res, "idle_2")

		local t = enemyShip:getChildByName("type")
		t:setTexture(string.format("ShipType/%d.png", shipConf.TYPE))
		t:setLocalZOrder(1)

		local q = enemyShip:getChildByName("quality")
		q:setTexture(string.format("ShipQuality/quality_%d.png", shipConf.QUALITY))
		q:setLocalZOrder(2)

		enemyShip:getChildByName("lv"):setString("Lv."..lv)

		return enemyShip
	end

	if info then

		-- for i,v in ipairs(info.id_lineup) do
		--     if v ~= 0 then
		--         local ship = createEnemyShip(v, info.lv_lineup[i])
		--         ship:setPosition(cc.p(node:getChildByName("Panel"):getChildByName("ship_"..i):getPosition()))
		--         node:getChildByName("Panel"):addChild(ship)
		--     end
		-- end


		for i,v in ipairs(info.ship_id_list) do
			if v ~= 0 then
				local ship = createEnemyShip(v, info.ship_level_list[i])
				ship:setPosition(cc.p(node:getChildByName("Panel"):getChildByName("ship_"..i):getPosition()))
				node:getChildByName("Panel"):addChild(ship)
			end
		end
	end

	return node

end

function ArenaScene:resetEnemy(index, flag)
	local rn = self:getResourceNode()
	local node = rn:getChildByName("arena_enemy_"..index)

	if flag then

		-- node:getChildByName("bg"):loadTexture("ArenaScene/ui/ui_light_long.png")
		-- node:getChildByName("kuang"):setTexture("ArenaScene/ui/ui_selection.png")
		node:getChildByName("light"):setVisible(true)
		node:setPositionX(node:getPositionX()-20)

		self.select_index = node:getTag()

		rn:getChildByName("ui_plaer_light_6"):setVisible(true)

	else
		-- node:getChildByName("bg"):loadTexture("ArenaScene/ui/ui_back_Bottom_box.png")
		-- node:getChildByName("kuang"):setTexture("ArenaScene/ui/ui_back_bottom.png")
		node:getChildByName("light"):setVisible(false)
		node:setPositionX(node:getPositionX()+20)

		self.select_index = 0

		rn:getChildByName("ui_plaer_light_6"):setVisible(true)
		
	end

	if self.enemy_lineup then
		self.enemy_lineup:removeFromParent()
		self.enemy_lineup = nil

		local role_id = math.floor(player:getPlayerIcon()/100)
		rn:getChildByName("role"):setTexture("HeroImage/"..role_id..".png")
	end
end

function ArenaScene:resetEnemyInfo()

	local rn = self:getResourceNode()

	rn:getChildByName("point_text"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))

	print("self.their_list_ num", #self.their_list_)
	if table.getn(self.their_list_) < 5 then
		return
	end


	for i,v in ipairs(self.their_list_) do
		local node = self:getResourceNode():getChildByName("arena_enemy_"..i)

		node:getChildByName("rank_num"):setString(v.rank == 0 and CONF:getStringValue("notInRanking") or tostring(v.rank))
		node:getChildByName("rank_num"):setTag(v.rank)

		node:getChildByName("jifen_text"):setString(CONF:getStringValue("score")..":")
		node:getChildByName("jifen_num"):setString(v.score)

		node:getChildByName("jifen_num"):setPositionX(node:getChildByName("jifen_text"):getPositionX() + node:getChildByName("jifen_text"):getContentSize().width)

		local iconID = v.icon_id
		if v.icon_id < 10 then 
			iconID = 100*v.icon_id+1
		end

		node:getChildByName("head_icon"):setTexture("HeroImage/"..iconID..".png")
		node:getChildByName("ships_name"):setString(v.nickname)

		node:getChildByName("ships_lv"):setPositionX(node:getChildByName("ships_name"):getPositionX() + node:getChildByName("ships_name"):getContentSize().width + 10)

		node:getChildByName("ships_lv_num"):setString(v.level)
		node:getChildByName("ships_lv_num"):setPositionX(node:getChildByName("ships_lv"):getPositionX() + node:getChildByName("ships_lv"):getContentSize().width + 2)

		node:getChildByName("fight_num"):setString(v.power) 
		node:setTag(i)
		node:getChildByName("bg"):setTag(i)
		node:getChildByName("light"):setVisible(false)

		local function fight( sender )
			playEffectSound("sound/system/return.mp3")
			if 120 - (player:getServerTime() - player:getArenaData().last_failed_time) > 0 then
				-- tips:tips(CONF:getStringValue("pleaseWait"))

				local function func()
					self.type = 2
					local strData = Tools.encode("ArenaAddTimesReq", {
						type = 2,
						times = 5,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_TIMES_REQ"),strData)
					
					gl:retainLoading()
				end
				
				local time = 120 - (player:getServerTime() - player:getArenaData().last_failed_time)

				local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("arena_reset_cd"), Tools.getSpeedUpNeedMoney(time), func)

				self:addChild(node)
				tipsAction(node)


			elseif player:getArenaData().challenge_times == 0 then
				-- tips:tips(CONF:getStringValue("noTimeToChallenge"))

				self.type = 1
				local function func(  )
					if player:getMoney() < Tools.calAddArenaTimesNeedMoney(player:getArenaData().purchased_challenge_times) then
						-- tips:tips(CONF:getStringValue("no enought credit"))

						local function func()
							local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

							rechargeNode:init(self, {index = 1})
							self:addChild(rechargeNode)
						end

						local messageBox = require("util.MessageBox"):getInstance()
						messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
						return
					end

					local strData = Tools.encode("ArenaAddTimesReq", {
						type = 1,
						times = 1,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_TIMES_REQ"),strData)
					
					gl:retainLoading()
				end

				local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("buy arena times"), Tools.calAddArenaTimesNeedMoney(player:getArenaData().purchased_challenge_times), func)

				self:addChild(node)
				tipsAction(node)

			else

				-- local num = 0 
				-- for i,v in ipairs(player:getForms()) do
				-- 	if v ~= 0 then
				-- 		num = num + 1
				-- 	end
				-- end

				-- if num == 0 then
				-- 	tips:tips(CONF:getStringValue("lineup no ships on"))
				-- 	return
				-- end

				if player:isFighting(1) ~= 0 then
					return
				end


				-- self.challenge_name = v.nickname
				-- self.challenge_power = v.power

				-- self.challenge_icon = "HeroImage/"..v.icon_id..".png"
				-- local strData = Tools.encode("ArenaChallengeReq", {
				-- 	type = 0,
				-- 	rank = self.their_list_[node:getChildByName("bg"):getTag()].rank,
				-- })
				-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_CHALLENGE_REQ"),strData)

				-- gl:retainLoading()

				self:getApp():pushView("FightFormScene/FightFormScene", {from = "arena", info = v})


			end
		end

		local function click( sender )
			printInfo("click")
		end

		node:getChildByName("fight"):addClickEventListener(fight)
		node:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("challenge"))

		if not player:getArenaisChallenged(v.rank) then
			node:getChildByName("fight"):setEnabled(true)
			node:getChildByName("fight"):setTouchEnabled(true)
		else
			node:getChildByName("fight"):setEnabled(false)
			node:getChildByName("fight"):setTouchEnabled(false)
		end

	end

	for i=1,5 do
		local node = rn:getChildByName("arena_enemy_"..i)

		node:setLocalZOrder(9)

		node:getChildByName("Panel"):setSwallowTouches(false)
		node:getChildByName("Panel"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/click.mp3")

			touchHead = true

			if self.select_index == node:getTag() then
				self:resetEnemy(self.select_index, false)
				return
			end


			if self.select_index ~= 0 then
				self:resetEnemy(self.select_index, false)
			end

			-- self.enemy_lineup = self:createEnemyLineup()
			-- rn:addChild(self.enemy_lineup)
			-- self.enemy_lineup:setPosition(cc.p(self:getResourceNode():getChildByName("role"):getPosition()))

			self:resetEnemy(i, true)

			-- local strData = Tools.encode("CmdGetOtherUserInfoReq", {
			--     user_name = self.their_list_[node:getChildByName("bg"):getTag()].user_name,
			-- })
			-- GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_REQ"),strData)

			-- gl:retainLoading()

			local role_id = math.floor(self.their_list_[node:getChildByName("bg"):getTag()].icon_id/100)

			-- rn:getChildByName("role"):setVisible(true)
			rn:getChildByName("role"):setTexture("HeroImage/"..role_id..".png")

			self.enemy_lineup = self:createEnemyLineup(self.their_list_[node:getChildByName("bg"):getTag()])
			rn:addChild(self.enemy_lineup)
			self.enemy_lineup:setPosition(cc.p(rn:getChildByName("lineup_pos"):getPosition()))

		end)
	end
	
end

function ArenaScene:onCreate( data )
	if data then
		self.data_ = data
	end
end

function ArenaScene:onEnterTransitionFinish()
	printInfo("ArenaScene:onEnterTransitionFinish()")

	if self.data_ and self.data_.go == "form" then
		self:getApp():getTopViewData().go = nil
		-- self:getApp():pushView("NewFormScene", {from = "ships"})
		self:getApp():addView2Top("NewFormLayer", {from = "special"})
		-- return
	end

	broadcastRun()

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kArena)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("arena_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end


	local rn = self:getResourceNode()

	local forms_num = 0
	for i,v in ipairs(player:getForms()) do
		if v ~= 0 then
			forms_num = forms_num + 1
		end
	end

	if forms_num < CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM then
		rn:getChildByName("form"):getChildByName("point"):setVisible(true)
	end

	rn:getChildByName("rank"):getChildByName("text"):setString(CONF:getStringValue("rankingList"))
	rn:getChildByName("rank_text"):setString(CONF:getStringValue("ranking"))
	rn:getChildByName("honor"):setString(CONF:getStringValue("honor"))
	rn:getChildByName("score"):setString(CONF:getStringValue("score"))
	rn:getChildByName("power_text"):setString(CONF:getStringValue("combat"))
	rn:getChildByName("cishu"):setString(CONF:getStringValue("challenge_num"))
	rn:getChildByName("arena_node"):getChildByName("aaaa"):setString(CONF:getStringValue("arena"))
	rn:getChildByName("form"):getChildByName("text"):setString(CONF:getStringValue("form"))
	rn:getChildByName("record"):getChildByName("text"):setString(CONF:getStringValue("arena_record_title"))
	rn:getChildByName("time_text"):setString(CONF:getStringValue("cd_time"))
	rn:getChildByName("shop"):getChildByName("text"):setString(CONF:getStringValue("the_title"))

	rn:getChildByName("change"):getChildByName("change_num"):setString(CONF.PARAM.get("arena_update_param_1").PARAM)
	
	rn:getChildByName("reward_time_text"):setString(CONF:getStringValue("rewardTime"))

	rn:getChildByName("rank_time_text"):setString(CONF:getStringValue("rankTime"))

	local  role_id = math.floor(player:getPlayerIcon()/100)
	rn:getChildByName("role"):setTexture("HeroImage/"..role_id..".png")

	rn:getChildByName("point_btn"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self, {index = 1})
		self:addChild(rechargeNode)

	end)


	self.select_index = 0

	self.time_pos = {times = {x = rn:getChildByName("cishu"):getPositionX(), y = rn:getChildByName("cishu"):getPositionY()}, time_num = {x = rn:getChildByName("cishu_num"):getPositionX(), y = rn:getChildByName("cishu_num"):getPositionY()}, time_btn = {x = rn:getChildByName("btn_cishu"):getPositionX(), y = rn:getChildByName("btn_cishu"):getPositionY()}}

	local strData = Tools.encode("ArenaInfoReq", {
		type = 1,
		-- user_name = player:getName(),
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_REQ"),strData)
	if self.data_ and self.data_.noRetain then
	else
		gl:retainLoading()
	end

	self:resetInfo()

	local function onTouchBegan(touch, event)
		touchHead = false

		return true
	end

	local function onTouchEnded(touch, event)
		if touchHead then 
			return
		end
		playEffectSound("sound/system/click.mp3")
		if self.select_index ~= 0 then
			self:resetEnemy(self.select_index, false)
		end

	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	animManager:runAnimOnceByCSB(rn, "ArenaScene/ArenaScene.csb",  "intro")
	animManager:runAnimByCSB(rn:getChildByName("liuguang"), "ArenaScene/sfx/jingjichanglibao.csb",  "1")

	local function update(dt)

		if player:getArenaData().last_failed_time > 0 then
			if 120 - (player:getServerTime() - player:getArenaData().last_failed_time) > 0 then
				rn:getChildByName("time"):setString(formatTime(120 - (player:getServerTime() - player:getArenaData().last_failed_time)))
				rn:getChildByName("time"):setVisible(true)
				rn:getChildByName("time_text"):setVisible(true)
				rn:getChildByName("line_1_1"):setVisible(true)
				rn:getChildByName("go"):setVisible(true)
				-- rn:getChildByName("time_icon"):setVisible(true)
				-- rn:getChildByName("time_back"):setVisible(true)

				rn:getChildByName("cishu"):setPosition(self.time_pos.times)
				rn:getChildByName("cishu_num"):setPosition(self.time_pos.time_num)
				rn:getChildByName("btn_cishu"):setPosition(self.time_pos.time_btn)
			else
				rn:getChildByName("time"):setVisible(false)
				rn:getChildByName("time_text"):setVisible(false)
				rn:getChildByName("line_1_1"):setVisible(false)
				rn:getChildByName("go"):setVisible(false)
				-- rn:getChildByName("time_icon"):setVisible(false)
				-- rn:getChildByName("time_back"):setVisible(false)

				-- rn:getChildByName("cishu"):setPosition(cc.p(rn:getChildByName("time_icon"):getPosition()))
				-- rn:getChildByName("cishu_num"):setPosition(cc.p(rn:getChildByName("time"):getPosition()))
				-- rn:getChildByName("btn_cishu"):setPosition(cc.p(rn:getChildByName("go"):getPosition()))
			end
		else
			rn:getChildByName("time"):setVisible(false)
			rn:getChildByName("time_text"):setVisible(false)
			rn:getChildByName("go"):setVisible(false)
			rn:getChildByName("line_1_1"):setVisible(false)
			-- rn:getChildByName("time_icon"):setVisible(false)
			-- rn:getChildByName("time_back"):setVisible(false)

			-- rn:getChildByName("cishu"):setPosition(cc.p(rn:getChildByName("time_icon"):getPosition()))
			-- rn:getChildByName("cishu_num"):setPosition(cc.p(rn:getChildByName("time"):getPosition()))
			-- rn:getChildByName("btn_cishu"):setPosition(cc.p(rn:getChildByName("go"):getPosition()))
		end

		if self.cur_3_times then
			local time = self.cur_3_times - player:getServerTime()
			if time < 0 then
				local strData = Tools.encode("ArenaInfoReq", {
					type = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_REQ"),strData)
				gl:retainLoading()
				self:resetInfo()
			else
				rn:getChildByName("reward_time"):setString(formatTime(time))
			end
		end

		if self.last_reflesh then
			local time = g_arena_rank_reflesh_time - (player:getServerTime() - self.last_reflesh)
			if time < 0 then
				local strData = Tools.encode("ArenaInfoReq", {
					type = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_REQ"),strData)
				gl:retainLoading()
				self:resetInfo()
			else
				rn:getChildByName("rank_time"):setString(formatTime(time))
			end
		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)


	local function recvMsg()
		print("ArenaScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_RESP") then
			if self.data_ and self.data_.noRetain then
			else
				gl:releaseLoading()
			end

			
			local proto = Tools.decode("ArenaInfoResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
			else 
				if self.refresh == true then 
					tips:tips(CONF:getStringValue("RefreshSucess"))
					self.refresh = false

					flurryLogEvent("credit_set_arena_update", {cost = tostring(Tools.calArenaUpdateMoney(1))}, 2)
				end
				
				local rn = self:getResourceNode()

				self.cur_3_times = proto.cur_3_day
				self.last_reflesh = proto.last_reflesh

				local rank = proto.my_info == nil and 0 or proto.my_info.rank
				local score = proto.my_info == nil and 0 or proto.my_info.score

				print("score", score)

				rn:getChildByName("score_num"):setString(tostring(score))
				rn:getChildByName("rank_num"):setString(rank == 0 and CONF:getStringValue("notInRanking") or tostring(rank))
				rn:getChildByName("rank_num"):setTag(rank)

				local function sort( a,b )
					return a.rank < b.rank
				end

				self.their_list_ = proto.their_info

				table.sort(self.their_list_, sort)

				self:resetInfo()


				self:resetEnemyInfo()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("CmdGetOtherUserInfoResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
			else 

				local node = self:getResourceNode():getChildByName("arena_enemy_"..self.select_index)
				node:getChildByName("ships_lv_num"):setString(proto.info.level)
				node:getChildByName("fight_num"):setString(proto.info.power)

				local role_id = math.floor(proto.info.icon_id/100)

				-- rn:getChildByName("role"):setVisible(true)
				rn:getChildByName("role"):setTexture("HeroImage/"..role_id..".png")

				self.enemy_lineup = self:createEnemyLineup(proto.info)
				rn:addChild(self.enemy_lineup)
				self.enemy_lineup:setPosition(cc.p(self:getResourceNode():getChildByName("lineup_pos"):getPosition()))

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_TIMES_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("ArenaAddTimesResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
                if proto.result == 12 then
                    tips:tips(CONF:getStringValue("no_cd"))
                end
			else    

				if self.type == 1 then 
					tips:tips(CONF:getStringValue("buySucess"))

					flurryLogEvent("credit_buy_arena_time", {time = tostring(player:getArenaData().purchased_challenge_times), cost = tostring(Tools.calAddArenaTimesNeedMoney(player:getArenaData().purchased_challenge_times-1))}, 2)
				elseif self.type == 2 then 
					tips:tips(CONF:getStringValue("ResetCDSucess"))
				else
					print("error")
				end
				self.type = nil
				self:resetInfo()

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_CHALLENGE_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("ArenaChallengeResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
			else 
				self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kArena,Tools.decode("ArenaChallengeResp",strData),true, self.challenge_name, self.challenge_icon, self.challenge_power})
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_GET_DAILY_REWARD_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("ArenaGetDailyRewardResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error")  
			else 
				-- tips:tips(CONF:getStringValue("GetRewardSucess"))
				playEffectSound("sound/system/reward.mp3")
				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)
				
				player:setArenaDailyReward()
				self:resetInfo()

			end

		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local   eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.broadcastListener_ = cc.EventListenerCustom:create("broadcastRun", function ()
		broadcastRun()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.broadcastListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		self:resetInfo()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)

	rn:getChildByName("wen"):addClickEventListener(function (sender)
		
		self:addChild(createIntroduceNode(CONF:getStringValue("Arena_introduce")))
	end)

	if self.data_ and self.data_.go == "title" then
		self.data_.go = nil
		self:getApp():addView2Top("ArenaScene/ArenaTitleLayer")
	end
end


function ArenaScene:onExitTransitionStart()
	printInfo("ArenaScene:onExitTransitionStart()")

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.broadcastListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)

end


return ArenaScene