-- Coded by Wei Jingjun 20180619
print( "###LUA ExConfig.lua" )
local ExConfig = class("ExConfig")

ExConfig.IS_RELOAD_DISABLED_BY_LIST = false

ExConfig.IS_OLD_LOGIN_MODE = true

ExConfig.IS_USE_FAKE_JSON_HTTP = false

ExConfig.FAKE_JSON = '{"errno":1,"server":[{"id":80003,"nm":"80003","st":0,"ip":"192.168.1.67","pt":7003,"vn":"1.0.5","hr":0,"rc":1},{"id":80002,"nm":"80002","st":2,"ip":"0.0.0.0","pt":0,"vn":"1.0.0","hr":0,"rc":0},{"id":80001,"nm":"80001","st":1,"ip":"192.168.1.67","pt":7001,"vn":"1.0.5","hr":0,"rc":0}],"cdn":"http://192.168.1.222:9096/update_package/","rc":1,"key":1,"wc":1,"hb":0}'
ExConfig.FAKE_JSON_WAI_WANG = ' {"errno":1,"server":[{"id":80002,"nm":"80002","st":0,"ip":"47.104.4.17","pt":7002,"vn":"1.0.5","hr":0,"rc":1},{"id":80001,"nm":"80001","st":1,"ip":"47.104.4.17","pt":7001,"vn":"1.0.5","hr":0,"rc":0}],"cdn":"http://47.104.217.78/update_package/","rc":1,"key":1,"wc":1,"hb":0}'


function ExConfig:IsNeiwang()
	local default_url = g_server_centre_url
	local pos_a, pos_b = string.find(default_url,'192.')
	print("@@@@@@@@@@",pos_a,pos_b)
	local is_neiwang = ( pos_a ~= nil ) or ( pos_b ~= nil )
	return is_neiwang
end

function ExConfig:GetFakeJson_Gateway()
	local is_neiwang = self:IsNeiwang()

	if( is_neiwang ) then
		local default_url = g_server_centre_url
		local pos_a, pos_b = string.find(default_url,'192.')
		is_neiwang = ( pos_a > 0 ) and ( pos_b > 0 )
	end

	if( is_neiwang == false ) then
		return self.FAKE_JSON_WAI_WANG
	end

	return self.FAKE_JSON
end

-- seconds of async loading fininsh
ExConfig.ASYNC_LOAD_DEFAULT_TIME = 0.001
-- must > 1

ExConfig.IS_EFFECT_ON_TILE_ENABLED = false
ExConfig.TILE_LOAD_INTERVAL = 0.25 * 1.7 * 0.4
ExConfig.TILE_MOVE_INTERVAL = 0.25 * 0.3 * 0.7

ExConfig.DELAY_RELOAD_TIME = 1

ExConfig.RES_REF_COUNT_NORMAL = 3

-- how long wait for begining load
ExConfig.DELAY_TIME_UPDATESCENE_PRELOAD = 2
ExConfig.PROGRESS_BAR_TIME = 55
if(  device.platform ~= "windows" ) then
	ExConfig.PROGRESS_BAR_TIME = 15
end

ExConfig.TOTAL_LOADING_TIME = ExConfig.PROGRESS_BAR_TIME + ExConfig.DELAY_TIME_UPDATESCENE_PRELOAD
ExConfig.TOTAL_LOADING_TIME2 = 9
ExConfig.isMainGameSceneEntered = false
ExConfig.DRAG_ZHUCHENG_FPS_INTERVAL = 0.013

ExConfig.MIN_TIME_LIMIT_PRELOAD = 2
ExConfig.DELAY_TO_PRELOAD = 0.4
ExConfig.INTERVAL_PER_PRELOAD = 0.05



function ExConfig:DebugLog()
	local cur_format = cc.Texture2D:getDefaultAlphaPixelFormat()
	--print( "###LUA getDefaultAlphaPixelFormat = " .. tostring(cur_format) )
end

function ExConfig:OnInit()
	--print( "###LUA ExConfig.lua OnInit" )

	cc.exports.musicVolume = 100
	cc.exports.effectVolume = 100

	self:DebugLog()
	-- cc.Texture2D:setDefaultAlphaPixelFormat(tonumber(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A4444))
	-- self:DebugLog()
end

function ExConfig:getInstance()
	--print( "###LUA ExConfig.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExConfig:onCreate(  )
	--print( "###LUA ExConfig.lua onCreate" )

	self:OnInit()

	return self
end

--print( "###LUA Return ExConfig.lua" )
return ExConfig