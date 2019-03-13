local Config = {}

Config.EItemType = {
	kExp = 1,
	kShipExp = 2,
	kRes1 = 3,
	kRes2 = 4,
	kRes3 = 5,
	kRes4 = 6,
	kMoney = 7,
	kStrength = 8,--体力
	kGem = 9,
	kEquip = 10,
	kShipFragment = 11,
	kGiftBag = 12,
	kNormal = 13,
	kHonour = 14,
	kBadge = 15,
	kShipBulepoint = 16,
	kShipSuperBulepoint = 17,
	kShip = 18,
    kOther = 19,
}

Config.ERes = {
	kRes1 = 1,
	kRes2 = 2,
	kRes3 = 3,
	kRes4 = 4,
}

Config.EBuilding = {
	kMain = 1,--主城
	kShips = 2, -- 舰队机库
	kShipDevelop = 3, --图纸开发
	kWeaponDevelop = 4, -- 武器研究所
	kTechnology = 5, --科技实验室
	kHome = 6, -- 家园
	kGarage = 7, -- 修理厂
	kLottery = 8, -- 星际港
	kCopy = 9, -- 副本
	kWarehouse = 10,--仓库
	kSpy = 11,	-- 侦查塔
	kDefend = 12, -- 城防跑台
	kDiplomacy = 13, -- 外交局
	kWarWorkshop = 14, -- 战争工坊
	kTrade = 15,-- 贸易中心
	kForge = 16, -- 锻造车间
	count = 16,
}


Config.EBuildingICON = {
	"BuildingUpgradeScene/ui/buliding1.png",
	"CityScene/sfx/city_7/10001.png",
	"BuildingUpgradeScene/ui/buliding3.png",
	"BuildingUpgradeScene/ui/buliding4.png",
	"BuildingUpgradeScene/ui/buliding5.png",
	"CityScene/sfx/city_1/city_1.png",
	"BuildingUpgradeScene/ui/buliding7.png",
	"CityScene/sfx/city_2/xingjigang/1.png",
	"CityScene/sfx/changj/jd/71.png",
	"BuildingUpgradeScene/ui/buliding10.png",
	"BuildingUpgradeScene/ui/buliding11.png",
	"BuildingUpgradeScene/ui/buliding12.png",
	"BuildingUpgradeScene/ui/buliding13.png",
	"BuildingUpgradeScene/ui/buliding14.png",
	"CityScene/sfx/changj/City/12.png",
	"BuildingUpgradeScene/ui/buliding16.png",
}

Config.EShipType = {
	kAttack = 1,
	kDefense = 2,
	kCure = 3,
	kControl = 4,
}

Config.EShipQuality = {
	kSS = 5,
	kS = 4,
	kA = 3,
	kB = 2,
	kC = 1,
}

Config.EShipStatus = {
	kNil = 0,
	kDead = 1,
	kMiss = 2,
	kCrit = 4,
}

Config.EShipAttr = {
	kMaxHP = -2,
	kFightValue = -1,
	kNil = 0,
	kAnger = 1,
	kHP = 2,
	kAttack = 3,
	kDefence = 4,
	kSpeed = 5,
	kHit = 6,
	kDodge = 7,
	kCrit = 8,
	kAnticrit = 9,
	kAttackAddition = 10,
	kAttackDurationAddition = 11,
	kHurtSubtration = 12,
	kHurtDurationSubtration = 13,
	kShield = 14,
	kUseAngerAddition = 15,
	kBeCureAddition = 16,
	kAngerRestore = 17,
	kDefeceAddition = 18,
	kHurtAddition = 19,
	kEnergyAttack = 20,
	kEnergyAttackAddition = 21,
	kCritEffect = 22,
	kHurtRebound = 23,
	kPenetrate = 24,
	kVampire = 25,
	kLifeRate = 26,
	kAttackRate = 27,
	kEnergyAttackRate = 28,
	kDefenceRate = 29,
	kFinalProbabilityHit = 30,
	kFinalProbabilityDodge = 31,
	kFinalProbabilityCrit = 32,
	kFinalProbabilityAnticrit = 33,
	kHurtReboundSubtration = 34,
	kAttackValue = 35,
	kHurtValue = 36,
	kCount = 36,
}

Config.ShipGrowthAttrs = {
	kHP = 2,
	kAttack = 3,
	kDefence = 4,
	kSpeed = 5,
	kHit = 6,
	kDodge = 7,
	kCrit = 8,
	kAnticrit = 9,
	kEnergyAttack = 20,
}

Config.ShipPercentAttrs = {
	kAttackAddition = 10,
	kAttackDurationAddition = 11,
	kHurtSubtration = 12,
	kHurtDurationSubtration = 13,
	kBeCureAddition = 16,
	kDefeceAddition = 18,
	kHurtAddition = 19,
	kEnergyAttackAddition = 21,
	kCritEffect = 22,
	kPenetrate = 24,
	kVampire = 25,
	kLifeRate = 26,
	kAttackRate = 27,
	kEnergyAttackRate = 28,
	kDefenceRate = 29,
	kFinalProbabilityHit = 30,
	kFinalProbabilityDodge = 31,
	kFinalProbabilityCrit = 32,
	kFinalProbabilityAnticrit = 33,
	kHurtReboundSubtration = 34,
}

Config.EShipSpecial = {
	kNil = 0,
	kCannotAttack = 1,
	kCannotSkill = 2,
	kFightBack = 4,
	kCannotBeFightBack = 5,
	kProvocation = 6,
	kAttackCannotGetAnger = 7,
	kImmuneDebuff = 8,
	kClearGoodBuff = 9,
	kGetAverageHurt = 10,
}

Config.EBuffCondition = {
	kNow = 1,
	kHited = 2,
	kKilled = 3,
}

Config.EBuffTrigger = {
	kCreate = 1,
	kAttack = 2,
	kKilled = 3,
	kHurt = 4,
	kAttacked = 5,
	kRoundStart = 6,
	kRoundEnd = 7,
}

Config.EShipTarget_1 = {
	kSelf = 0,
	kAttacker = 1,
	kHurter = 2,
	kOur = 3,
	kEnemy = 4,
	kAll = 5,
}

Config.EShipTarget_2 = {
	kOne = 1,
	kFrontCol = 2,
	kBackCol = 3,
	kRow = 4,
	kRand = 5,
	kValueMax = 6,
	kValueMin = 7,
	kAll = 8,
}

----------------------------------------------

Config.ETechTarget_1 = {
	kHomeRes = 1,
	kWorldRes = 2,
	kShipAttr = 3,
	kBuilding = 4,
	kReword = 5,
	kTechnology = 6,
	kGroup = 7,
	kUserInfo = 8,
	kFightShipAttr = 9,
	kHomeBuilding = 10,
	kRewordItem = 11,	--同kReword target_3为Item ID
	kPlanet = 12,
}

Config.ETechTarget_2_Reword = {
	kCopy = 1,
	kPvp = 2,
}

Config.ETechTarget_3_Reword = {
	kRole = 1,
	kShip = 2,
	kGold = 3,
}

Config.ETechTarget_3_Building = {
	kRes = 1,
	kCD = 2,
}

Config.ETechTarget_3_Res = {
	kProduction = 1,
	kStorage = 2,
	kCollect = 3,
}

Config.ETechTarget_3_Group = {
	kMaxUser = 1,
	kBossReward = 2,
	kBeHelpTimes = 3,
}

Config.ETechTarget_3_UserInfo = {
	kStrength = 1,
	kArmyLimit = 2,
	kLineupLimit = 3,
	kSubDurable = 4,	--降低飞船耐久度的损耗速度
	kFixSpeed = 5,		--飞船耐久度的修理速度
}

Config.ETechTarget_3_Planet = {
	kSpeed = 1,
}
----------------------------------------------
Config.ETaskTarget_1 = {
	kCheckpoint = 1,
	kBuilding = 2,
	kHome = 3,
	kUser = 4,
	kShip = 5,
	kArena = 6,
	kGroup = 7,
	kRecharge = 8,
	kSignIn = 9,
	kLottery = 10,
	kHomeRes = 11,
	kTrial = 12,
	kPlanet = 13,
	kTechnology = 14,
	kWeapon = 15,
	kTask = 16,
	kSlave = 17,
	kBlueprint = 18,
}

Config.ETaskTarget_2_Task = {
	kFinishTimes = 1,
}

Config.ETaskTarget_2_Slave = {
	kSlaveTimes = 1,
}

Config.ETaskTarget_2_Technology = {
	kLevelUpCount = 1,--activity
}

Config.ETaskTarget_2_Weapon = {
	kLevelUpCount = 1,--activity
}

Config.ETaskTarget_2_Planet = {
	kLevelCollectTimes = 1,
	kCollectCount = 2,
	kLevelRuinsTimes = 3,
	kLevelFishingTimes = 4,
	kBossTimes = 5,
	kAttackCityWinTimes = 6,
	kWinTims = 7,
	kBaseDefenseWinTimes = 8,
	kMoveBaseTimes = 9,
	kAttackMonsterTimes = 10,
 	kBaseAttackTimes = 11,
 	kLevelCollectTimesDay = 12, --每日采集资源
	kLevelRuinsTimesDay = 13, --每日摧毁行星带
	kLevelFishingTimesDay = 14, -- 每日打捞宇宙残骸
	kBossTimesDay = 15, --每日攻击人工智能基地
}

Config.ETaskTarget_2_Trial = {
	kDailyTimes = 1,--daily
	kPass = 2,--activity
}

Config.ETaskTarget_2_HomeRes = {
	kGetResTimes = 1,--daily
}

Config.ETaskTarget_2_Checkpoint = {
	kPass = 1,
	kFight = 2,--daily
	kWin = 3,--daily
}

Config.ETaskTarget_2_Building = {
	kLevelUpCount = 1,
	kLevelCount = 2,
	kLevelID = 3,
	kAllLevelUpCount = 4,--activity
	kActivation = 5,--激活
}

Config.ETaskTarget_2_User = {
	kLevel = 1,
	kBuyStrengthTimes = 2,--daily
}

Config.ETaskTarget_2_Ship = {
	kLevelUpCount = 1,--daily
	kGetID = 2,
	kQualityCount = 3,
	kLevelCount = 4,
	kPowerCount = 5,
	kEquipLevelUpCount = 6,--daily
	kBreakCount = 7,--daily
	kAllShipPower = 8,--activity
}

Config.ETaskTarget_2_Arena = {
	kChallengeCount = 1,--daily
	kWinCount = 2,--daily
	kTitleLevel = 3,
}

Config.ETaskTarget_2_Group = {
	kContributeCount = 1,
	kDailyContributeCount = 2,--daily
	kDailyBossTimes = 3,--daily
}

Config.ETaskTarget_2_Recharge = {
	kRechargeCount = 1,
	kConsumeCount = 2,
}

Config.ETaskTarget_2_Lottery = {
	kAllLotteryCount = 1,
	kMoneyLotteryCount = 2,--activity
}

Config.ETaskTarget_2_Blueprint = {
	kBlueprintAll = 1,
	kBlueprintTime = 2,
}
----------------------------------------------


Config.EGemType = {
	kType_1 = 1,
	kType_2 = 2,
	kType_3 = 3,
	kType_4 = 4,
	kType_5 = 5,
	kTypeAll = 6,
}

Config.EActivityType = {
	kChange = 1,
	kRecharge = 2,
	kConsume = 3,
	kSevenDays = 4,
	kOnline = 5,
	kLimitShip = 6,
	kFirstRecharge = 7,
	kSignIn = 8,
	kCreditReturn = 9,
	kPower = 10,
	kGrowthFund = 12,
	kInvest = 13,
	kMonthSign = 14,
	kChangeShip = 15,
}

Config.EActivityGroup = {
	kChange = 1,
	kRecharge = 2,
	kConsume = 3,
	kSevenDays = 4,
	kOnline = 5,
	kPower = 6,
	kGrowthFund = 7,
	kInvest = 8,
	kMonthSign = 9,
	kChangeShip = 10,
    kConvert = 11
}


Config.EActivityConf = {
	"ActivityChange",
	"ActivityRecharge",
	"ActivityConsume",
	"ActivitySevenDays",
	"ActivityOnline",
	"ActivityPower",
	"ActivityFund",
	"ActivityInvest",
	"ActivityMonthSign",
	"ActivityChangeShip",

}

Config.EActivityItemConf = {
	"ChangeItem",
	"RechargeItem",
	"ConsumeItem",
	"SevenDaysTask",
	"OnlineGroup",
	"PowerGroup",
	"FundGroup",
	"InvestGroup",
	"MonthSignGroup",
}

Config.EGroupHelpType = {
	kBuilding = 1,
	kTechnology = 2,
	kHome = 3,
}

Config.ESlaveNoteKey = {
	kSlave = 1,	--#1.奴隶
	kItem = 2,	--#2.ItemID
	kNum = 3,	--#3.数量
	kMaster = 4,	--#4.奴隶主
	kCatchSlave = 5,	--#5.要抢的人
	kWatcher = 6,	--#6围观的人
	kAttacker = 7, --#7抢夺者
	kMax = 7,
}

Config.ESlaveNoteType = {
	WORK_ADD = 1,
	WORK_SUB = 2,
	FAWN_ON_ADD = 3,
	FAWN_ON_SUB = 4,
	ROB_SUCCESS = 5,
	SAVE_SUCCESS = 6,
	SHOW = 7,
	BE_SHOW = 8,
	WATCH = 9,
	BE_ROB_SUCCESS = 10,
	BE_SAVE_SUCCESS = 11,
	SLAVE_BE_SAVE_SUCCESS = 12,
	SAVE_SELF_SUCCESS = 13,
	FREE = 14,
	BE_FREE = 15,
	BE_CATCH = 16,
}

Config.EShipState = {
	kNormal = 0,
	kLineup = 1,
	kFix = 2,
	kOuting = 4,
}

Config.EInterface = {
	kMain = 1,
	kChapter = 2,
	kLevel = 3,
	kCopy = 4,
	kBattleOver = 5,
	kShips = 6,
	kBuildingUpgrade = 7,
	kShipFactory = 8,
	kShipDevelop = 9,
	kTask = 10,
	kWeaponDevelop = 11,
	kTechnology = 12,
	kPlanet = 13,
	kHome = 14,
	kTrialArea = 15,
	kArena = 16,
	kGroup = 17,
	kLottery = 18,
	kBattle = 19,
	kForms = 20,
	kRegister = 21,
	kTrialStage = 22,
	kBattle = 23,
	kBattleEnd = 24,
	kTp = 26,
	kFightLose = 27,
}

Config.ETipsType = {
	kItem = 1,
	kGem = 2,
	kEquip = 3,
	kSkill = 4,
}

Config.ETextColor = {
	kRed = {r = 255, g = 70, b = 70},
	kBlue = {r = 156, g = 217, b = 255},
	kGreen = {r = 156, g = 255, b = 182},
	kYellow = {r = 255, g = 244, b = 156},
}

-- Config.EMainBuildingPos = {
-- 	kMain = -700,
-- 	kShips = -800,
-- 	kShipFactory = -280,
-- 	kWeaponDevelop = -1042,
-- 	kTechnology = -1042,
-- 	kHome = 0,
-- 	kRepair = -1042,
-- 	kStarPort = -300,
-- 	kLottery = 0,
-- }

Config.EMainBuildingPos = {
	-1500,  --指挥中心
	-1600,
	-700,   --图纸开发
	-1642,  --
	-1350,  --科技实验室
	-350,  --
	-1800,  --
	-1300,   --星际港
	-200,  --副本
	-950,  --仓库
	-1050, --侦查塔
	-650,  --城防炮台
	-20,  --外交局
	-450, --战争工坊
	-1150, --贸易中心
	-50, --锻造车间
}

Config.ESystemGuideInterFace = {
	kCopy = 1,
	kAchievement = 2,
	kLottery = 3,
	kWarWorkshop = 4,
	kRepair = 5,
	kForge = 6,
	kArena = 7,
	kStarLeague = 8,
	kWeaponDevelop = 9,
	kFriend = 10,
	kStrong = 11,
	kActivity = 12,
	kDiplomacy = 13,
	kTrade = 14,
	kGem = 15,
	kEnergy = 16,
	kSlave = 17,
	kPlanetBoss = 18,
	kPlanetCity = 19,
	kForm = 20,
	kTrial = 21,
	kSpy = 22,
	kWarehouse = 23,
	kDayTask = 24,
	kTp = 25,
	kTechnology = 26,
	kPlanetStar = 28, --行星带
	kPlanetRuins = 29, -- 废墟
}

-- 主城建筑1-16开启条件key对应param表
Config.EParamOpenKey = {
	"building_1 open",
	"building_2 open",
	"city_3_open",
	"city_6_open",
	"city_5_open",
	"city_1_open",
	"city_8_open",
	"city_2_open",
	"building_9 open",
	"city_10_open",
	"city_11_open",
	"building_12 open",
	"city_13_open",
	"city_14_open",
	"",
	"city_16_open",
}

-- 主城建筑系统引导key对应function_open表
Config.EFunctionOpenKey = {
	"building_1 open",
	"building_2 open",
	"",
	"wqyj_open",
	"city_5_open",
	"city_1_open",
	"city_8_open",
	"city_2_open", 
	"", 
	"ck_open", 
	"zct_open", 
	"building_12 open", 
	"wjj_open", 
	"zzgf_open", 
	"", 
	"dzgc_open",
}

function Config:getActivityConf(type)
	return self[string.upper(Config.EActivityConf[type])]
end

function Config:getActivityItemConf(type)
	return self[string.upper(Config.EActivityItemConf[type])]
end


function Config:load(preload)

	local conf_list

	if preload == true then
		conf_list = {
			"String",
		}
	else
		conf_list =
		{
			"String",
			"Weapon",
			"Buff",
			"Item",
			"Checkpoint",
			"String",
			"Equip",
			"PlayerLevel",
			"ShipLevel",
			"Building_1",
			"Building_3",
			"Building_4",
			"Building_5",
			"Building_7",
			"Building_10",
			"Building_11",
			"Building_12",
			"Building_13",
			"Building_14",
			"Building_15",
			"Building_16",
			"Copy",
			"Area",
			"Resource",
			"Ship_Break",
			"Technology",
			"Strength",
			"Trial_Area",
			"Trial_Copy",
			"Trial_Level",
			"Trial_Scene",
			"Trial_Store",
			"Param",
			"Memo_Param",
			"Group",
			"Group_Tech",
			"Task",
			"DailyTask",
			"Planet",
			"Planet_Res",
			"Planet_Raid",
			"Planet_Ruins",
			"AirShip",
			"Reward",
			"Arena_Reward",
			"Shop",
			"Ship_Lottery",
			"Role_Creation",
			"Name",
			"Ship_Lottery",
			"Ship_Blueprint",
			"Ship_BlueprintBreak",
			"Gem",
			"Activity",
			"ActivitySignIn",
			"ActivityChange",
			"ActivityGroup",
			"ChangeItem",
			"ActivityConsume",
			"ActivityRecharge",
			"ActivitySevenDays",
			"SevenDaysTask",
			"ActivityFirstRecharge",
			"Group_Boss",
			"Group_Help",
			"Group_Checkpoint",
			"Equip_Strength",
			"Recharge",
			"Talk",
			"ActivityCreditReturn",
			"ConsumeItem",
			"RechargeItem",
			"Guidance",
			"ArenaTitle",
			"Strong",
			"Function_Open",
			"Worship",
			"WorshipReward",
			"System_Guidance",
			"Slave_Note",
			"Slave_Award",
			"OnlineGroup",
			"ActivityOnline",
			"PowerGroup",
			"ActivityPower",
			"ActivityFund",
			"FundGroup",
			"ActivityMonthSign",
			"MonthSignGroup",
			"ActivityChangeShip",
			"ActivityInvest",
			"InvestGroup",
			"PlanetWorld",
			"PlanetCity",
			"PlanetBoss",
			"DirtyWord",
			"Open_icon",
			"VIP",
			"Blueprint",
			"EnergyLevel",
			"ForgeEquip",
			"PlanetCityRes",
			"NewHandGiftBag",
			"PlanetCreeps",
			"Title_Buff",
			"PlanetTower",
			"Activity_Turntable",
			"Recharge_Gift_bag",
			"ChangeItem",
            "Goto",
		}
	end


	for _,name in ipairs(conf_list) do

		print("ttttt",name)
		local CONF_NAME = string.upper(name)

		if server_platform == 1 then
			if name == "String" then
				name = "String_en"
			end
			if name == "Name" then
				name = "Name_en"
			end
		end

		local conf = require ("conf/"..name)
		if CONF_NAME == "STRING" 
		or CONF_NAME == "PARAM"
		or CONF_NAME == "MEMO_PARAM" 
		or CONF_NAME == "FUNCTION_OPEN"
		or CONF_NAME == "TALK" then
			for i=1,conf.len do
				local v = conf[conf.index[i]]
				if v.KEY ~= nil then
					conf[v.KEY] = v
				end
			end
		end
		if CONF_NAME == 'AIRSHIP' then
			for i=1,conf.len do
				local v = conf[conf.index[i]]
				if v.BLUEPRINT and v.BLUEPRINT[1] then
					conf[v.BLUEPRINT[1]..'BLUEPRINT'] = v
				end
			end
		end
		if CONF_NAME == 'PLANETWORLD' then
			for i=1,conf.len do
				local v = conf[conf.index[i]]
				if v.ROW and v.COL then
					conf[v.ROW..'_'..v.COL] = v
				end
			end
		end
		conf.get = function (id)
			if type(id) == "number" then
				return assert(conf[id], string.format("CONF.%s.ID,%d", CONF_NAME, id))
			elseif type(id) == "string" then
				return assert(conf[id], string.format("CONF.%s key:%s", CONF_NAME, id))
			end	
		end

		conf.check = function (id)
			return conf[id]
		end

		conf.count = function ()
			return conf.len
		end

		conf.getIDList = function ()

			return Tools.clone(conf.index) 
		end

		self[CONF_NAME] = conf
	end
end

function Config:getStringValue( strKey )
	-- ADD WJJ 20180724
	--print( string.format( "~~~~~ configuration.lua 838 getStringValue strKey: %s", strKey or "nil" ) )
	if( (strKey == nil) or ( strKey == "" )  ) then
		return nil
	end

	return self.STRING.get(strKey).VALUE
end


function Config:debug()

	local failed = false
	
	--验证 武器库里的ID 是否在 WEAPON表里存在
	local building_4 = Config.BUILDING_4.getIDList()
	for _,id in ipairs(building_4) do
		local conf = Config.BUILDING_4.get(id)
		if conf.WEAPON_LIST and type(conf.WEAPON_LIST) == "table" then
			for _,weaponID in ipairs(conf.WEAPON_LIST) do
				local weaponConf = Config.WEAPON.get(weaponID)
				if not weaponConf then
					print("building_4 error")
					failed = true
				end
			end
		end
	end

	--验证 TASK表中 ITEM_ID 和 ITEM_NUM 是否数量一致
	local task_id_list = Config.TASK.getIDList()
	for _,id in ipairs(task_id_list) do
		local conf = Config.TASK.get(id)
		if conf.ITEM_ID ~= nil then
			if #conf.ITEM_ID ~= #conf.ITEM_NUM then
				print("task error", id)
				failed = true
			end
		end
	end


	local group_id_list = Config.GROUP.getIDList()
	for _,id in ipairs(group_id_list) do
		local conf = Config.GROUP.get(id)
		if Tools.isEmpty(conf.SUP_PACK) == false then
			for i,v in ipairs(conf.SUP_PACK) do
				local rewardConf = Config.REWARD.get(v)
				if rewardConf == nil then
					print("GROUP rewardConf error", v)
					failed = true
				end
			end
		end
		if Tools.isEmpty(conf.CON_PACK) == false then
			for i,v in ipairs(conf.CON_PACK) do
				local rewardConf = Config.REWARD.get(v)
				if rewardConf == nil then
					print("GROUP rewardConf error", v)
					failed = true
				end
			end
		end
	end

	local ruins_id_list = Config.PLANET_RUINS.getIDList()
	for _,id in ipairs(ruins_id_list) do
		local conf = Config.PLANET_RUINS.get(id)
		if conf.REWARD_ID ~= nil then
			local rewardConf = Config.REWARD.get(conf.REWARD_ID)
			if rewardConf == nil then
				print("PLANET_RUINS rewardConf error", v)
				failed = true
			end
		end
	end

	local reward_id_list = Config.REWARD.getIDList()
	for _,id in ipairs(reward_id_list) do
		local conf = Config.REWARD.get(id)
		local count = #conf.ITEM
		if count ~= #conf.WEIGHT or count ~= #conf.COUNT then

			print("REWARD rewardConf error", id)
			failed = true
		end
	end
	assert(failed == false, "configuration debug failed!")
end

return Config
