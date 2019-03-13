
local OldConfig = {}

-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = false

-- disable create unexpected global variable
CC_DISABLE_GLOBAL = true

-- for module display
CC_DESIGN_RESOLUTION = {
	width = 1136,
	height = 768,
	autoscale = "FIXED_HEIGHT",
	--callback = function(framesize)
	--	local ratio = framesize.width / framesize.height
	--	print( "~~~config.lua ratio: " .. tostring(ratio) )
	--	if ratio <= 1.34 then
			-- iPad 768*1024(1536*2048) is 4:3 screen
	--		return {autoscale = "FIXED_HEIGHT"}
	--	elseif( ratio > 1.9 ) then
			-- quan mian ping
	--		return {autoscale = "FIXED_HEIGHT"}
	--	end
	--end
}

require "Common"

require "GolbalFunc"

--在CC_DISABLE_GLOBAL = true的情况下可以通过cc.exports.XXX声明全局变量
GameHandler = {}
GameHandler.handler_c = require "LuaHandler.c"

DEFINE_NET_ON_RECEVIE = "ClientConnect::onReceviePacket"

Tools = require "Tools"

CONF = require "configuration"

s_default_font = "fonts/cuyabra.ttf" 

s_event_step = 0

g_click_delta = 2

g_technology_speed_up_flag = false

g_Views_config = {
	copy_id = 0,
	slPosX = 0,
	hp = 0,
}

SceneZOrder = {
	kItemInfo = 90,
	kLevelUp = 996,
	kGuide = 997,
	kMessageBox = 998,
	kGlobalLoading = 999,
	kTips = 1000,
	kRedSfx = 1001,
	kMessageBoxSpeed = 1002,
}

BattleZOrder = {
	kShip = -2,
	kNormal = 0,
	kShipUI = 1,
	kSfxGrayLayer = 2,
	kSfxShip = 3,
	kSfxShipUI = 4,
	kSfxWeapon = 5,
}

BattleType = {
	kCheckPoint = 1,
	kTrial = 2,
	kArena = 3,
	kPlanetRes = 4,
	kPlanetRuins = 5,
	kPlanetRaid = 6,
	kGroupBoss = 7,
	kTest = 8,
	kSlave = 9,
	kSaveFriend = 10,
	kSlaveEnemy = 11,
	kMailVideo = 12,
}

FixedPriority = {
	kFirst = 1,
	kNormal = 2,
}

OldConfig.FixedPriority = {
	kFirst = 1,
	kNormal = 2,
}

g_Player_OldExp = {
	oldExp = 0,
	oldLevel = 0,
}

g_Planet_Info = {}

g_Can_Pay = true

g_Player_Battle_Talk = 0 
g_Player_Guide = 0
g_Player_Guide_Atk_List = {4,5,9,6,3}

g_guiding_can_skill = false

g_broadcast_run = false

g_Effect_Sound = {}

g_city_scene_pos = -1350

g_arena_rank_reflesh_time = 1800

g_Player_Level = 0

g_Guide_Max_Id = 909

g_Guide_Form_Id = 408

g_Player_Fight = 0

g_Ruins_Reward = {}

g_Raid_Reward = {id = 0, flag = false}

g_System_Guide_Id = 0

g_System_Guide_Id_T = 0

g_guide_hero_active = 0

g_Planet_Grid_Info = {
	row = 16,
	col = 16,
	cube_w = 229,
	cube_h = 130,
}
g_MailGuid_VideoPosition = ''	

g_rechange_rc = 0

g_slave_form_data = {}

g_speed_up_need = false

g_city_scene_width = 2937

return OldConfig