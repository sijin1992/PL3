print(" ###LUA DBG AttributeLayer line: 1 ")
local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()
print(" ###LUA DBG AttributeLayer line: 7 ")
local animManager = require("app.AnimManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()
local g_taskManager = require("app.TaskControl"):getInstance()

local cfg_ship = require ("conf.AirShip")

local AttributeLayer = class("AttributeLayer", cc.load("mvc").ViewBase)

AttributeLayer.RESOURCE_FILENAME = "TaskScene/AttributeLayer.csb"

AttributeLayer.NEED_ADJUST_POSITION = true

AttributeLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

AttributeLayer.btnSelected = 1
print(" ###LUA DBG AttributeLayer line: 26 ")
function AttributeLayer:OnBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			self:removeFromParent()
		end
	end
end

function AttributeLayer:onEnterTransitionFinish()
	printInfo("AttributeLayer:onEnterTransitionFinish")

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
		if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kAchievement)== 0 and g_System_Guide_Id == 0 then
			systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("achievement_open").INTERFACE)
		else
			if g_System_Guide_Id ~= 0 then
				systemGuideManager:createGuideLayer(g_System_Guide_Id)
			end
		end

	local rn = self:getResourceNode()
	--rn:getChildByName("title"):setString(CONF.STRING.get("leader").VALUE)	Delete by JinXin 20180620

	if player:getLevel() < CONF.FUNCTION_OPEN.get("achievement_open").GRADE then
		rn:getChildByName("achieve"):setVisible(false)
	else
		rn:getChildByName("achieve"):addClickEventListener(function (sender)
			if self.btnSelected ~= 1 then return end
			
			self.btnSelected = 2
			playEffectSound("sound/system/tab.mp3")
			rn:getChildByName('state'):getChildByName('selected'):setVisible(false)
			rn:getChildByName('achieve'):getChildByName('selected'):setVisible(true)
			rn:getChildByName('state'):getChildByName('text_selected'):setVisible(false)
			rn:getChildByName('achieve'):getChildByName('text_selected'):setVisible(true)
			rn:getChildByName('state'):getChildByName('text'):setVisible(true)
			rn:getChildByName('achieve'):getChildByName('text'):setVisible(false)
			rn:getChildByName('Node_achi'):setVisible(true)
			rn:getChildByName('Node_hero'):setVisible(false)
			self:setData2()
			
		end)
	end
	rn:getChildByName("state"):addClickEventListener(function ( sender )
		if self.btnSelected == 1 then return end
		self.btnSelected = 1
		rn:getChildByName('state'):getChildByName('selected'):setVisible(true)
		rn:getChildByName('achieve'):getChildByName('selected'):setVisible(false)
		rn:getChildByName('state'):getChildByName('text_selected'):setVisible(true)
		rn:getChildByName('achieve'):getChildByName('text_selected'):setVisible(false)
		rn:getChildByName('state'):getChildByName('text'):setVisible(false)
		rn:getChildByName('achieve'):getChildByName('text'):setVisible(true)
		playEffectSound("sound/system/tab.mp3")
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListener(self.recvlistener2_)
		rn:getChildByName('Node_achi'):setVisible(false)
		rn:getChildByName('Node_hero'):setVisible(true)
		self:setData()
		
	end)

	rn:getChildByName("rank"):addClickEventListener(function ()
		-- self:getApp():addView2Top("RankLayer/RankLayer");
		self:getApp():pushView("RankLayer/RankLayer") 
	end)

	rn:getChildByName("setting"):addClickEventListener(function ()
		--local node = self:getApp():createView("CityScene/SiteLayer");
		self:getApp():addView2Top("CityScene/SiteLayer");
	end)

	self.selectedPiece = {}
	rn:getChildByName('Node_achi'):setVisible(false)
	rn:getChildByName('Node_hero'):setVisible(true)
	local icon = player:getPlayerIcon()
	rn:getChildByName('Node_hero'):getChildByName('Sprite_2'):setTexture('HeroImage/'..math.floor(tonumber(icon)/100)..'.png')
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("Node_hero"):getChildByName("list"),cc.size(5,10), cc.size(610,750))
	self.svd1_ = require("util.ScrollViewDelegate"):create(rn:getChildByName('Node_achi'):getChildByName("list"),cc.size(5,2), cc.size(610,110))
	self.svd_:getScrollView():setScrollBarEnabled(false)
	self.svd1_:getScrollView():setScrollBarEnabled(false)
	if g_taskManager:hasCanGetAchievement() == true then
		rn:getChildByName("achieve"):getChildByName("point"):setVisible(true)
	end
	self.starPower = nil

	self.num = 1
	self.rankingList ={}
	self.battleList = {0,0,0,0,0}
	self:getRanking()

	if player:getPlayerGroupMain() then
		self:getStarPower()
	end

	if g_taskManager:hasCanGetAchievement() == true then
		rn:getChildByName("achieve"):getChildByName("point"):setVisible(true)
	end
	
	self.m_groupList = g_taskManager:getAllAchievement()
	for k,v in pairs(self.m_groupList) do
		table.sort(self.m_groupList[k],function ( a,b )
			return a < b
		end)
	end


	local xingmeng = false
	local paihang = false
	local jingji = false
	if player:getGroupName() == "" or player:getGroupName() == nil then
		xingmeng = true
	end
	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		--获取星盟总战力
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_RESP") then        
			local proto = Tools.decode("CmdGetOtherUserInfoListResp",strData)         
			if proto.result ~= 0 then
				printInfo("proto error",proto.result)  
			else  
				local sumPower = 0
				for i,v in ipairs(proto.info_list) do
					sumPower = sumPower + v.power
				end
				self.starPower = sumPower
				xingmeng = true
				if xingmeng and paihang and jingji then
					self:setData()
				end
			end
		--获取排行
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_RANK_RESP") then          
			local proto = Tools.decode("RankResp",strData)
			if proto.result ~= 0 then
				printInfo("-------------proto error" ,proto.result)  
			else  
				if self.num == 2 then
					self.rankingList[1] = proto.my_user_rank.power_rank
					--攻击次数 防御次数 胜率
					self.battleList[1] = proto.my_user_rank.attack_count
					self.battleList[2] = proto.my_user_rank.defence_count
					self.battleList[3] = proto.my_user_rank.win_count
				elseif self.num == 3 then
					self.rankingList[2] = proto.my_user_rank.level_rank
				elseif self.num == 4 then
					self.rankingList[3] = proto.my_user_rank.main_city_level_rank
				elseif self.num == 5 then
					if player:getGroupName() == "" then
						--("未加入任何星盟")
						self.rankingList[4] = -1
					else 
						self.rankingList[4] = player:getPlayerGroupMain().rank
					end
					
				elseif self.num == 7 then
					if proto.my_user_rank.max_trial_level >0 then
						self.rankingList[6] = proto.my_user_rank.max_trial_level_rank
					else
						--("未上榜")
						self.rankingList[6] = -1
					end
				end
				self:getRanking()
				paihang = true
				if xingmeng and paihang and jingji then
					self:setData()
				end
			end
		--获取竞技场排名
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_RESP") then
			local proto = Tools.decode("ArenaInfoResp",strData)
			if proto.result ~= 0 then
				print("proto error CMD_ARENA_INFO_RESP" ,proto.result ,type(proto.result))  
			else 
				self.rankingList[self.num-1] = proto.my_info.rank
				self:getRanking()
				jingji = true
				if xingmeng and paihang and jingji then
					self:setData()
				end
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local   eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	animManager:runAnimOnceByCSB( rn, "TaskScene/AttributeLayer.csb", "animation")
	self:setData(  )
    require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Attribute(self) -- 全面屏适配
end


-- self.num 记录次数
-- self.rankingList = {} 记录6个排行数据
function AttributeLayer:getRanking(  )
	if self.num > 6 then
		return
	else 
		local strData 
		if self.num == 1 then
			--printInfo("战力排行")
			strData = Tools.encode("RankReq", {
				rank_type = "PLAYER_POWER",
				start_rank = 1, 
				need_my = true,
			})
		elseif  self.num == 2 then
			strData = Tools.encode("RankReq", {
				rank_type = "PLAYER_LEVEL",
				start_rank = 1, 
				need_my = true,
			})
			--printInfo("等级排行")
		elseif  self.num == 3 then
			strData = Tools.encode("RankReq", {
				rank_type = "MAIN_CITY_LEVEL",
				start_rank = 1, 
				need_my = true,
			})
			--printInfo("主城等级")
		elseif  self.num == 4 then
			strData = Tools.encode("RankReq", {
				rank_type = "GROUP_POWER",
				start_rank = 1, 
				need_my = true,
			})
			--printInfo("星盟排行")
		elseif  self.num == 6 then
			strData = Tools.encode("RankReq", {
				rank_type = "TRIAL",
				start_rank = 1, 
				need_my = true,
			})
			--printInfo("试炼排行")
		end

		if self.num == 5 then
			strData = Tools.encode("ArenaInfoReq", {
					type = 1,
				})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_REQ"),strData)
		else 
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_RANK_REQ"),strData)
		end
	end
	self.num = self.num + 1 
end


function AttributeLayer:setData(  )
	local  rn = self:getResourceNode()
	self.svd_:clear()
	local node_info = require("app.ExResInterface"):getInstance():FastLoad('TaskScene/HeroInfoNode.csb')
	self.svd_:addElement(node_info)
	-- heroinfo
	local heroinfo = node_info:getChildByName('Node_hero_info')
	rn:getChildByName("state"):getChildByName("text"):setString(CONF.STRING.get("state").VALUE)
	rn:getChildByName("achieve"):getChildByName("text"):setString(CONF.STRING.get("achievement").VALUE)
	rn:getChildByName("state"):getChildByName("text_selected"):setString(CONF.STRING.get("state").VALUE)
	rn:getChildByName("achieve"):getChildByName("text_selected"):setString(CONF.STRING.get("achievement").VALUE)
	--rn:getChildByName("rank"):getChildByName("text"):setString(CONF.STRING.get("rank").VALUE);
	--rn:getChildByName("rank"):getChildByName("text_selected"):setString(CONF.STRING.get("rank").VALUE);
	--rn:getChildByName("setting"):getChildByName("text"):setString(CONF.STRING.get("setting").VALUE);
	--rn:getChildByName("setting"):getChildByName("text_selected"):setString(CONF.STRING.get("setting").VALUE);
	rn:getChildByName("rank"):getChildByName("text"):setString(CONF.STRING.get("RankList").VALUE);
	rn:getChildByName("rank"):getChildByName("text_selected"):setString(CONF.STRING.get("RankList").VALUE);
	heroinfo:getChildByName("lv"):setString("LV." .. player:getLevel())
	heroinfo:getChildByName("playerName"):setString(player:getNickName())
	heroinfo:getChildByName("setName"):setPositionX(heroinfo:getChildByName("playerName"):getPositionX() + heroinfo:getChildByName("playerName"):getContentSize().width + 5)
	heroinfo:getChildByName("icon"):setContentSize(cc.size(67,67))
	heroinfo:getChildByName("icon"):loadTexture("HeroImage/".. player:getPlayerIcon() .. ".png")
	--成就达成数量
	local achiNum = 0
	local task_list = player:getTaskList()
	for i,v in ipairs(task_list) do
		if CONF.TASK.get(v.task_id).TYPE == 3 then
			achiNum = achiNum + 1 
	   end
	end
	heroinfo:getChildByName("achieveNum"):setString(achiNum)
	local fight = heroinfo:getChildByName("fight")
	local energy = heroinfo:getChildByName("energy")
	local Adscription = heroinfo:getChildByName("Adscription")
	local exp = heroinfo:getChildByName("exp")
	energy:setString(CONF.STRING.get("IN_8001").VALUE)
	Adscription:setString(CONF.STRING.get("covenant").VALUE)
	fight:setString(CONF.STRING.get("sumPower").VALUE)
	exp:setString(CONF.STRING.get("exp").VALUE)

	local fightNum = heroinfo:getChildByName("fightNum")
	local AdscriptionText = heroinfo:getChildByName("AdscriptionText")
	local energyNum = heroinfo:getChildByName("energyNum")
	local energySum = heroinfo:getChildByName("enerySum")
	local expNum = heroinfo:getChildByName("expNum")
	local expSum = heroinfo:getChildByName("expSum")
	if player:getGroupName() == "" or player:getGroupName() == nil then 
		AdscriptionText:setString(CONF:getStringValue("notInLeague"))
	else
		AdscriptionText:setString(player:getGroupName())
	end
	expNum:setString(player:getNowExp())
	expSum:setString("/" .. CONF.PLAYERLEVEL.get(player:getLevel()).EXP)
	energyNum:setString(player:getStrength())
	energySum:setString("/" .. player:getMaxStrength())
	fightNum:setString(player:getPower())
	local width1 =  (fight:getContentSize().width > Adscription:getContentSize().width and fight:getContentSize().width ) or Adscription:getContentSize().width
	local width2 = (energy:getContentSize().width > exp:getContentSize().width and energy:getContentSize().width ) or exp:getContentSize().width
	fightNum:setPositionX(fight:getPositionX() + width1 + 10)
	AdscriptionText:setPositionX(fightNum:getPositionX())
	energyNum:setPositionX(energy:getPositionX() + width2 + 10)
	expNum:setPositionX(energyNum:getPositionX())
	energySum:setPositionX(energyNum:getPositionX() + energyNum:getContentSize().width)
	expSum:setPositionX(expNum:getPositionX() + expNum:getContentSize().width)
	
	-- star_info
	local star_info = node_info:getChildByName('Node_star_info')
	local fight = star_info:getChildByName('fight')
	local fightnum = star_info:getChildByName('fightNum')
	local total = star_info:getChildByName('total')
	local totalnum = star_info:getChildByName('totalnum')
	local ranking = star_info:getChildByName('ranking')
	local rankingnum = star_info:getChildByName('rankingnum')
	local contribute = star_info:getChildByName('contribute')
	local contributenum = star_info:getChildByName('contributenum')
	fight:setString(CONF:getStringValue('leaguePower'))
	if self.starPower == nil then 
		self:getStarPower()
	else
		fightnum:setString(self.starPower)
	end
	total:setString(CONF:getStringValue('leagueTechnologyNum'))
	totalnum:setString(self:getStarTechNum())
	ranking:setString(CONF.STRING.get("rank").VALUE)
	rankingnum:setString(self.rankingList[4])
	contribute:setString(CONF.STRING.get("player'sContribution").VALUE)
	contributenum:setString(player:getGroupData().contribute)

	if player:getGroupName() == "" or player:getGroupName() == nil then 
		star_info:getChildByName('nostar'):setVisible(false)
		star_info:getChildByName('nostar'):setString(CONF:getStringValue('notInLeague'))
		fightnum:setString(CONF:getStringValue('notInLeague'))
		total:setVisible(false)
		totalnum:setVisible(false)
		ranking:setVisible(false)
		rankingnum:setVisible(false)
		contribute:setVisible(false)
		contributenum:setVisible(false)
	end

	fightnum:setPositionY(fight:getPositionY())
	fightnum:setPositionX(fight:getPositionX()+fight:getContentSize().width + 6)
	totalnum:setPositionY(total:getPositionY())
	totalnum:setPositionX(total:getPositionX()+total:getContentSize().width + 6)
	rankingnum:setPositionY(ranking:getPositionY())
	rankingnum:setPositionX(ranking:getPositionX()+ranking:getContentSize().width + 6)
	contributenum:setPositionY(contribute:getPositionY())
	contributenum:setPositionX(contribute:getPositionX()+contribute:getContentSize().width + 6)

	-- ship_info
	local ship_info = node_info:getChildByName('Node_ship_info')
	ship_info:getChildByName('ship'):setString(CONF:getStringValue('Airship'))
	local shipd = ship_info:getChildByName('shipd')
	local shipnum = ship_info:getChildByName('shipnum')
	local text1 = ship_info:getChildByName('text1')
	local text2 = ship_info:getChildByName('text2')
	local text3 = ship_info:getChildByName('text3')
	local text4 = ship_info:getChildByName('text4')
	local have1 = ship_info:getChildByName('have1')
	local have2 = ship_info:getChildByName('have2')
	local have3 = ship_info:getChildByName('have3')
	local have4 = ship_info:getChildByName('have4')
	local shipList = player:getShipList()
	local attNum,defNum,treNum,conNum = 0,0,0,0
	local totalAttNum,totalDefNum,totalTreNum,totalConNum = 0,0,0,0
	for i,v in ipairs(shipList) do
		if v.type == 1 then 
			attNum = attNum + 1
		elseif v.type == 2 then 
			defNum = defNum + 1
		elseif v.type == 3 then 
			treNum = treNum + 1
		elseif v.type == 4 then 
			conNum = conNum + 1
		end
	end
	for k,v in pairs(cfg_ship) do
		if type(k) == 'number' and v.KIND == 1 then
			if v.TYPE == 1 then
				totalAttNum = totalAttNum + 1
			elseif v.TYPE == 2 then
				totalDefNum = totalDefNum + 1
			elseif v.TYPE == 3 then
				totalTreNum = totalTreNum + 1
			elseif v.TYPE == 4 then
				totalConNum = totalConNum + 1
			end
		end
	end
	have1:setString(CONF:getStringValue('knapsack_have')..' '..attNum)
	have2:setString(CONF:getStringValue('knapsack_have')..' '..defNum)
	have3:setString(CONF:getStringValue('knapsack_have')..' '..treNum)
	have4:setString(CONF:getStringValue('knapsack_have')..' '..conNum)
	text1:setString(CONF:getStringValue('attack'))
	text2:setString(CONF:getStringValue('defense'))
	text3:setString(CONF:getStringValue('control'))
	text4:setString(CONF:getStringValue('treat'))
	shipd:setString(CONF:getStringValue('totalNum')..':')
	shipnum:setString(#shipList)
	local progress1 = require("util.ScaleProgressDelegate"):create(ship_info:getChildByName('jindu_1'),ship_info:getChildByName('jindu_bg1'):getContentSize().width)
	local progress2 = require("util.ScaleProgressDelegate"):create(ship_info:getChildByName('jindu_2'),ship_info:getChildByName('jindu_bg2'):getContentSize().width)
	local progress3 = require("util.ScaleProgressDelegate"):create(ship_info:getChildByName('jindu_3'),ship_info:getChildByName('jindu_bg3'):getContentSize().width)
	local progress4 = require("util.ScaleProgressDelegate"):create(ship_info:getChildByName('jindu_4'),ship_info:getChildByName('jindu_bg4'):getContentSize().width)
	progress1:setPercentage(attNum/totalAttNum*100)
	progress2:setPercentage(defNum/totalDefNum*100)
	progress3:setPercentage(treNum/totalTreNum*100)
	progress4:setPercentage(conNum/totalConNum*100)
	local maxWidth = 0
	for i=1,4 do
		maxWidth = math.max(maxWidth,ship_info:getChildByName('text'..i):getContentSize().width+ship_info:getChildByName('text'..i):getPositionX())
	end
	for i=1,4 do
		ship_info:getChildByName('jindu_'..i):setPositionY(ship_info:getChildByName('text'..i):getPositionY())
		ship_info:getChildByName('jindu_'..i):setPositionX(maxWidth+5)
		ship_info:getChildByName('jindu_bg'..i):setPosition(ship_info:getChildByName('jindu_'..i):getPosition())
		ship_info:getChildByName('have'..i):setPositionY(ship_info:getChildByName('text'..i):getPositionY())
		ship_info:getChildByName('have'..i):setPositionX(ship_info:getChildByName('jindu_bg'..i):getPositionX()+ship_info:getChildByName('jindu_bg'..i):getContentSize().width+5)
	end
	shipnum:setPosition(shipd:getPositionX()+shipd:getContentSize().width+5,shipd:getPositionY())

	-- other_info
	local other_info = node_info:getChildByName('Node_other_info')
	other_info:getChildByName('jianzhu'):setString(CONF:getStringValue('buildingPower'))
	other_info:getChildByName('shangzhen'):setString(CONF:getStringValue('all_ship_power'))
	other_info:getChildByName('keji'):setString(CONF:getStringValue('techPower'))
	other_info:getChildByName('jianzhu_power'):setString(CONF:getStringValue('combat')..' '..self:getBuildPower())
	other_info:getChildByName('shangzhen_power'):setString(CONF:getStringValue('sumPower')..' '..player:getAllShipFightPower())
	other_info:getChildByName('keji_power'):setString(CONF:getStringValue('sumPower')..' '..self:getTechPower())
	other_info:getChildByName('paihang'):setString(CONF:getStringValue('rank'))
	other_info:getChildByName('zhandou'):setString(CONF:getStringValue('BattleList'))
	local labels = {"player_power" ,"PlayerLevel" ,"CentreLevel" ,"leaguePower" ,"arena_rank" ,"trial_rank"}
	local nums = {"powerNum" ,"levelNum" ,"centreNum" ,"leagueNum" ,"arenaNum" ,"trialNum"}
	local maxPaihangWidth = 0
	for i=1,6 do
		other_info:getChildByName('paihang_text'..i):setString(CONF:getStringValue(labels[i]))
		other_info:getChildByName('paihang_num'..i):setString(self.rankingList[i])
		maxPaihangWidth = math.max(other_info:getChildByName('paihang_text'..i):getContentSize().width+other_info:getChildByName('paihang_text'..i):getPositionX())
	end
	if self.rankingList[4] == -1 then
		other_info:getChildByName('paihang_num4'):setString(CONF:getStringValue("notInLeague"))
	end 
	if self.rankingList[6] == -1 then
		other_info:getChildByName('paihang_num6'):setString(CONF:getStringValue("notInRanking"))
	end
	for i=1,6 do
		other_info:getChildByName('paihang_num'..i):setPositionX(maxPaihangWidth+50)
		other_info:getChildByName('paihang_num'..i):setPositionY(other_info:getChildByName('paihang_text'..i):getPositionY())
	end

	local labels2 = {"winRate","attackTime" ,"defenseTime" ,"winTime","battleTime"} 
	for i=1,5 do
		other_info:getChildByName('zhandou_text'..i):setString(CONF:getStringValue(labels2[i]))
	end
	self.battleList[5] = self.battleList[1] + self.battleList[2]
	if self.battleList[5] ==0 then
		self.battleList[4] = 0
	else 
		self.battleList[4] = math.floor(self.battleList[3] / self.battleList[5]*100 )
	end

	other_info:getChildByName('zhandou_num1'):setString(self.battleList[4] .. "%")
	other_info:getChildByName('zhandou_num2'):setString(self.battleList[1])
	other_info:getChildByName('zhandou_num3'):setString(self.battleList[2])
	other_info:getChildByName('zhandou_num4'):setString(self.battleList[3])
	other_info:getChildByName('zhandou_num5'):setString(self.battleList[5])
	local maxZhandouWidth = 0
	for i=1,5 do
		maxZhandouWidth = math.max(maxZhandouWidth,other_info:getChildByName('zhandou_text'..i):getContentSize().width+other_info:getChildByName('zhandou_text'..i):getPositionX())
	end
	for i=1,5 do
		other_info:getChildByName('zhandou_num'..i):setPositionX(maxZhandouWidth+25)
		other_info:getChildByName('zhandou_num'..i):setPositionY(other_info:getChildByName('zhandou_text'..i):getPositionY())
	end
end

function AttributeLayer:getStarPower(  )
	local name_list = {}
	if Tools.isEmpty(player:getPlayerGroupMain()) then return end
	for i,v in ipairs(player:getPlayerGroupMain().user_list) do
		table.insert(name_list, v.user_name)
	end
	if Tools.isEmpty(name_list) then return end
	local strData = Tools.encode("CmdGetOtherUserInfoListReq", {
		user_name_list = name_list,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_REQ"),strData)
end

function AttributeLayer:getStarTechNum(  )
	local sum = 0
	if Tools.isEmpty(player:getPlayerGroupTech()) then
		return 0
	end
	for k,v in pairs(player:getPlayerGroupTech()) do
		if v.status == 3 then 
			sum = sum + 1 
		end
	end
	return sum
end

function AttributeLayer:getTechPower(  )
	local sumPower = 0
	for i,v in ipairs(player:getUserInfo().tech_data.tech_info) do

		local conf = CONF.TECHNOLOGY.check(v.tech_id)
		if conf then
			sumPower = sumPower + conf.FIGHT_POWER
		end
	end
	return sumPower
end

function AttributeLayer:getBuildPower( )
	local sumPower = 0
	for i,v in ipairs(player:getUserInfo().home_info.land_info) do
		local conf = CONF.RESOURCE.check(v.resource_type)
		if conf then
			sumPower = sumPower + conf.FIGHT_POWER
		end
	end
	for i,v in ipairs(player:getUserInfo().building_list) do
		if CONF[string.format("BUILDING_%d",i)] then
			local conf = CONF[string.format("BUILDING_%d",i)].check(v.level)
			if conf then
				sumPower = sumPower + conf.FIGHT_POWER
			end
		end
	end
	return sumPower
end

function AttributeLayer:resetList()

	local getedList = g_taskManager:getGettedAchievement()

	local rn = self:getResourceNode()
	if player:getTaskList() == nil then
		return
	end   
	local isTouchMe = false
	self.selcetedTaskTag = -1 
	self.svd1_:clear()
	self.listDoing = {}
	self.listDoen = {}
	self.listDid = {}
	self.listUnopen = {}

	local itemIndex = 0
	for k,v in pairs(self.m_groupList) do
		itemIndex = itemIndex + 1 

		if getedList[k] then
			--print("有领取历史信息，则传递最后一个self.getedList[k][#self.getedList[k]]")
			self:createAchievement(getedList[k][#getedList[k]].task_id, true)
		else
			--print("没有领取历史信息，传递第一个 self.m_groupList[k][1]", k)
			self:createAchievement(self.m_groupList[k][1], false)  
		end  
	end

	local function addItem( list )
		table.sort(list , function (a ,b )
			return a:getTag() < b:getTag()
		end)
		for i,v in ipairs(list) do
			self.svd1_:addElement(v)
		end
	end 

	addItem(self.listDid)
	addItem(self.listUnopen)
	addItem(self.listDoen)
	addItem(self.listDoing)
end

function AttributeLayer:setProgress(node, percent) 
	local progress = node:getChildByName("introduction"):getChildByName("progress")
	local pd = require("util.ScaleProgressDelegate"):create(progress, progress:getTag())
	pd:setPercentage(percent)
end

function AttributeLayer:showTaskNodeItem(id,node)
	local task = CONF.TASK.get(id)
	local itemPos = node:getChildByName("itemPos")
	for i,v in ipairs(task.ITEM_ID) do
		local itemNode = require("app.ExResInterface"):getInstance():FastLoad('TaskScene/ItemRewardNode.csb')

		node:addChild(itemNode)
		local posX = itemPos:getPositionX() + (itemPos:getContentSize().width + 25)* (i-1)
		itemNode:setPosition(cc.p(posX ,itemPos:getPositionY() ))
		itemNode:setName(tostring(v))
		itemNode:getChildByName('Text_num'):setString('x'..task.ITEM_NUM[i])
		local item = CONF.ITEM.get(tonumber(v))
		itemNode:getChildByName('Image1'):addClickEventListener(function()
			addItemInfoTips( item )
			end)
		local picBg = 'gray.png'
		if item.QUALITY == 2 then
			picBg = 'green.png'
		elseif item.QUALITY == 3 then
			picBg = 'blue.png'
		elseif item.QUALITY == 4 then
			picBg = 'purple.png'
		elseif item.QUALITY == 5 then
			picBg = 'yellow.png'
		end
		itemNode:getChildByName('Image1'):loadTexture('TaskScene/ui/'..picBg)
		itemNode:getChildByName('Image2'):setTexture('ItemIcon/'..item.ICON_ID..'.png')
	end
end

function AttributeLayer:createAchievement(id, hasData)
	local achievement = CONF.TASK.get(id)
	local finished = false --奖励是否领取
	if hasData then 
		for i,v in ipairs(player:getTaskList()) do
			if id == v.task_id then 
				finished = v.finished
			   	break 
			end
		end
	end

	
	local function setBaseInfo( node, conf )
		local rn = self:getResourceNode()   
		local iconPath = "TaskScene/achievement/" .. conf.ICON .. ".png"
		local taskName = CONF.STRING.get(conf.NAME).VALUE
		local taskIntro = CONF.STRING.get(conf.MEMO).VALUE
		if conf.SHOW and conf.SHOW == 1 then
			local value = conf.VALUES
			if value[1] then
				local vv = value[1]
				if conf.TARGET_1 == 2 and conf.TARGET_2 == 3 then
					vv = CONF:getStringValue("BuildingName_"..value[1])
				elseif conf.TARGET_1 == 3 and conf.TARGET_2 == 3 then
					vv = CONF:getStringValue("HomeBuildingName_"..value[1])
				elseif conf.TARGET_1 == 6 and conf.TARGET_2 == 3 then
					vv = CONF:getStringValue("ARENA_TITLE_"..value[1])
				elseif conf.TARGET_1 == 1 and conf.TARGET_2 == 1 then
					vv = CONF:getStringValue("Level_N"..value[1])
				end
				taskName = string.gsub(taskName,"#",vv)
				taskIntro = string.gsub(taskIntro,"#",vv)
			end
			if value[2] then
				taskName = string.gsub(taskName,"*",value[2])
				taskIntro = string.gsub(taskIntro,"*",value[2])
			end
			if value[3] then
				taskName = string.gsub(taskName,"&",value[3])
				taskIntro = string.gsub(taskIntro,"&",value[3])
			end
		end
		node:getChildByName("icon"):setTexture(iconPath)
		node:getChildByName("introduction"):setString(taskIntro)
		local isAchieved , completeNum, needNum = player:IsTaskAchieved(achievement)
		if isAchieved == nil then
			isAchieved = false
		end
		local isOpen = player:IsTaskOpen(achievement)
		if completeNum == nil then 
			completeNum = 0
		end
		if needNum == nil then 
			needNum = 1
		end
		node:getChildByName("taskName"):setString(taskName..'('..tostring(completeNum)..string.format("/%d",needNum)..')')

		node:getChildByName("btnGet"):getChildByName("btnText"):setString(CONF:getStringValue("Get"))
	end

	local node = require("app.ExResInterface"):getInstance():FastLoad("TaskScene/AchievementItem.csb")
	node:getChildByName("btnGet"):setVisible(false)
	if finished == true then
		if Tools.isEmpty(achievement.NEXT_ID) == true then 
			table.insert(self.listDid ,node)
			--print("这是本组的 最后一个成就,且已经领取")
			-- animManager:runAnimOnceByCSB(node,"TaskScene/AchievementItem.csb" ,"end")
			setBaseInfo(node, achievement)
			return
		else
			--print("显示下一个成就") 
			achievement = CONF.TASK.get(achievement.NEXT_ID[1])
		end
	end

	setBaseInfo(node, achievement)
	
	local isAchieved , completeNum, needNum = player:IsTaskAchieved(achievement)
	if isAchieved == nil then
		isAchieved = false
	end
	local isOpen = player:IsTaskOpen(achievement)
	if completeNum == nil then 
		completeNum = 0
	end
	if needNum == nil then 
		needNum = 1
	end
	node:setTag(achievement.ID)
	self:showTaskNodeItem(achievement.ID, node)
	if isOpen == false then
		node:getChildByName("introduction"):setTag(1)
		--table.insert(self.listUnopen ,node)

	elseif isAchieved then
		node:getChildByName("btnGet"):setVisible(true)
		table.insert(self.listDoen ,node)
		node:getChildByName("btnGet"):addClickEventListener(function ( sender )
			self.selectedId = node:getTag()

			local strData = Tools.encode("TaskRewardReq", {
				task_id = self.selectedId,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_REWARD_REQ"),strData)
			gl:retainLoading()
		end)
		node:getChildByName("introduction"):setTag(0)

	else
		-- animManager:runAnimOnceByCSB(node,"TaskScene/AchievementItem.csb" ,"open")
		table.insert(self.listDoing ,node)
		node:getChildByName("introduction"):setTag(1)
	end
end

function AttributeLayer:setData2()
	local rn = self:getResourceNode()
	self.svd1_:clear()
	self:resetList()
	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

	
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_REWARD_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("TaskRewardResp",strData)
			if proto.result ~= 0 then
				printInfo("get TaskRewardResp error :"..proto.result)
			else
				if proto.task_id > 0 then
					flurryLogEvent("task", {task_id = tostring(proto.task_id) }, 2)
					local gold_num = 0
					local credit_num = 0
					for i,v in ipairs(CONF.TASK.get(proto.task_id).ITEM_ID) do
						if v == 3001 then
							gold_num = CONF.TASK.get(proto.task_id).ITEM_NUM[i]
							
						elseif v == 7001 then
							credit_num = CONF.TASK.get(proto.task_id).ITEM_NUM[i]
						end
					end
					flurryLogEvent("get_gold_by_task", {task_id = tostring(proto.task_id), gold_num = gold_num}, 1, gold_num)

					if credit_num > 0 then
						flurryLogEvent("get_credit_by_task", {task_id = tostring(proto.task_id), credit_num = credit_num}, 1, credit_num)
					end
				end

				playEffectSound("sound/system/reward.mp3")
				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)         
				self:resetList()

				local event = cc.EventCustom:new("AchievementUpdate")

				if player:getLevel() >= CONF.FUNCTION_OPEN.get("achievement_open").GRADE and g_taskManager:hasCanGetAchievement() == true then
					event._usedata = true
					self:getResourceNode():getChildByName("achieve"):getChildByName("point"):setVisible(true)
				else
					event._usedata = false
					self:getResourceNode():getChildByName("achieve"):getChildByName("point"):setVisible(false)
				end
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

				local taskConf = CONF.TASK.get(proto.task_id)
				local items = {}
				for i,v in ipairs(taskConf.ITEM_ID) do
					table.insert(items, {id = v, num = taskConf.ITEM_NUM[i]})
				end
				if self.scene_ then
					local node = require("util.RewardNode"):createGettedNodeWithList(items, nil , display:getRunningScene())
					tipsAction(node)
					node:setPosition(cc.exports.VisibleRect:center())
					display:getRunningScene():addChild(node)

					--local getTip = require("util.RewardNode"):createRewardTipFromList(items)
					--getTip:setPosition(cc.exports.VisibleRect:top())
					--self.scene_:addChild(getTip)
				end
			end
		end

	end
	local eventDispatcher = self:getEventDispatcher()
	self.recvlistener2_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener2_, FixedPriority.kNormal)

	self.upgradeOverListener_ = cc.EventListenerCustom:create("upgradeOver", function ()
		if g_Player_Level ~= player:getLevel() then
			createLevelUpNode(player:getLevel(), g_Player_Level)
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.upgradeOverListener_, FixedPriority.kNormal)
end


function AttributeLayer:onExitTransitionStart()
	printInfo("AttributeLayer:onExitTransitionStart()")
	self.starPower = nil 
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.recvlistener2_)
	eventDispatcher:removeEventListener(self.upgradeOverListener_)
end

print(" ###LUA DBG AttributeLayer line: 853 ")
return AttributeLayer