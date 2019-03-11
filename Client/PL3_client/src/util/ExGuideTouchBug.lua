print( "###LUA ExGuideTouchBug.lua" )
-- Coded by Wei Jingjun 20180620
local ExGuideTouchBug = class("ExGuideTouchBug")

ExGuideTouchBug.IS_DEBUG_LOG_LOCAL = false

function ExGuideTouchBug:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end
------------------------------------------------

ExGuideTouchBug.timeHelper = require("util.ExTimeHelper"):getInstance()

ExGuideTouchBug.BUG_GUIDE_ID_DianJianZhu_Tuzhi = 14
ExGuideTouchBug.BUG_GUIDE_ID_DianJianZhu = { ExGuideTouchBug.BUG_GUIDE_ID_DianJianZhu_Tuzhi,
26,40,54
 }
ExGuideTouchBug.BUG_GUIDE_ID_FU_BEN_MEI_TAN_CHU = 96

ExGuideTouchBug.GUIDE_TANCHU_JIANZHU_CAIDAN_TIME_MAX = 4
ExGuideTouchBug.GUIDE_TANCHU_JIANZHU_CAIDAN_TIME_MIN = -2

ExGuideTouchBug.KEY_OnCitySceneTouchEnd = "global_time_last_dian_jian_zhu"

function ExGuideTouchBug:GetGuideId()
	-- do not use userdefault, slow!
	-- local id_current = tonumber( cc.UserDefault:getInstance():getStringForKey("global_guide_id_last") or -1 )
	local id_current = tonumber( cc.exports.global_guide_id_last or -1 )
	return id_current
end

function ExGuideTouchBug:OnCitySceneTouchEnd()
	local _now = tostring(os.time())

	cc.exports[self.KEY_OnCitySceneTouchEnd] = _now

	self:_print(string.format("@@@ OnCitySceneTouchEnd: %s", _now ) )
end

function ExGuideTouchBug:OnBug_Building_DianJianZhu()
	local _now = tostring(os.time())
	self:_print(string.format("@@@ OnBug_Building_DianJianZhu: %s", _now ) )
	local time_last_dian_jian_zhu = cc.exports[self.KEY_OnCitySceneTouchEnd] or -1


	local is_time = self.timeHelper:IsTimeInRange(time_last_dian_jian_zhu, 0, self.GUIDE_TANCHU_JIANZHU_CAIDAN_TIME_MAX)

	-- true is bug
	self:_print(string.format("@@@ true is bug: %s", tostring(is_time) ) )
	return (is_time)
end

function ExGuideTouchBug:OnBug_Cursor_FU_BEN_MEI_TAN_CHU()
	-- local time = cc.UserDefault:getInstance():getStringForKey("global_time_last_tanchu_fuben_jinru_ui")
	local time = cc.exports.global_time_last_tanchu_fuben_jinru_ui
	local is_time_ok = self.timeHelper:IsTimeInRange(time,-1, 25)

	return (is_time_ok == false)
end

function ExGuideTouchBug:OnBug_Cursor_DianJianZhu()

	-- local time_last_tanchu_jianzhu_caidan = cc.UserDefault:getInstance():getStringForKey("global_time_last_tanchu_jianzhu_caidan")
	local time_last_tanchu_jianzhu_caidan = cc.exports.global_time_last_tanchu_jianzhu_caidan or -1
	local is_time_ok = self.timeHelper:IsTimeInRange(time_last_tanchu_jianzhu_caidan,self.GUIDE_TANCHU_JIANZHU_CAIDAN_TIME_MIN,self.GUIDE_TANCHU_JIANZHU_CAIDAN_TIME_MAX)

	return (is_time_ok == false)
end

function ExGuideTouchBug:IsInArray( _id, _arr)
	local has_id = false
	for _k,_v in pairs(_arr) do
		has_id = tonumber(_v) == tonumber(_id)
		if(has_id) then
			do return true end
		end
	end
	return has_id
end

function ExGuideTouchBug:OnGuideId_Building(gId)
	self:_print( "@@@@ ExGuideTouchBug OnGuideId_Building " .. tostring(gId) )

	local is_bug = false

	if( self:IsInArray( gId, self.BUG_GUIDE_ID_DianJianZhu )  ) then
		is_bug = self:OnBug_Building_DianJianZhu()
	end

	return is_bug
end

function ExGuideTouchBug:OnGuideId(gId)
	self:_print( "@@@@ ExGuideTouchBug OnGuideId " .. tostring(gId) )

	local is_bug = false
	--if( gId == self.BUG_GUIDE_ID_FU_BEN_MEI_TAN_CHU ) then
	--	self:_print("###LUA ExGuideTouchBug BUG_GUIDE_ID_FU_BEN_MEI_TAN_CHU : gId: " .. tostring(self.BUG_GUIDE_ID_FU_BEN_MEI_TAN_CHU) )
	--	is_bug = self:OnBug_Cursor_FU_BEN_MEI_TAN_CHU()
		-- do return false end
	--end


	if( self:IsInArray( gId, self.BUG_GUIDE_ID_DianJianZhu )  ) then
		is_bug = self:OnBug_Cursor_DianJianZhu()
	end

	return is_bug
end

------------------------------------------------

function ExGuideTouchBug:getInstance()
	--print( "###LUA ExGuideTouchBug.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExGuideTouchBug:onCreate()
	--print( "###LUA ExGuideTouchBug.lua onCreate" )

	return self
end

print( "###LUA Return ExGuideTouchBug.lua" )
return ExGuideTouchBug