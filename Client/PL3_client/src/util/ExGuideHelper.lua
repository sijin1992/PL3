print( "###LUA ExGuideHelper.lua" )
-- Coded by Wei Jingjun 20180620
local ExGuideHelper = class("ExGuideHelper")

ExGuideHelper.IS_DEBUG_LOG_LOCAL = false

function ExGuideHelper:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end
------------------------------------------------
--print( "###LUA Return ExGuideHelper.lua 13" )
-- ExGuideHelper.guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()
--print( "###LUA Return ExGuideHelper.lua 15" )
ExGuideHelper.touchHelper =  require("util.ExGuideTouchHelper"):getInstance()

ExGuideHelper.guideTools =  require("util.ExGuideTools"):getInstance()

--print( "###LUA Return ExGuideHelper.lua 16" )
-- ExGuideHelper.mainGuideLogic =  require("app.views.GuideLayer.GuideLayer")
--print( "###LUA Return ExGuideHelper.lua 18" )

------------------------------------------------

function ExGuideHelper:OnBug_JIAN_ZHU_AN_NIU_DUO_YU(guide_id, name)
	self:_print(string.format("@@@@ OnBug_JIAN_ZHU_AN_NIU_DUO_YU isBug guide_id: %s    name: %s" , tostring(guide_id), tostring(name) ))

	local isBug =  (tonumber(guide_id) >= 3) and (tonumber(guide_id) <= 11)
	if( isBug ) then
		self:_print("@@@@ OnBug_JIAN_ZHU_AN_NIU_DUO_YU isBug " .. tostring(isBug))
	end

	return isBug
end

ExGuideHelper.GUIDE_HECHENG_SHIP_ID = 111001

function ExGuideHelper:OnBugFix_KEHECHENG_VISIBLE(guide_id, _info)
	self:_print("@@@@ OnBugFix_KEHECHENG_VISIBLE guide_id " .. tostring(guide_id))
	if( tonumber(guide_id) ~= 34 ) then
		do return _info end
	end

	local ship_id = _info.shipId
	self:_print("@@@@ KEHECHENG_VISIBLE ship_id: " .. tostring(ship_id))

	local is_target = tonumber(ship_id) == self.GUIDE_HECHENG_SHIP_ID

	if( is_target == false ) then
		do return _info end
	end

	if(_info.needBluePrintNum > _info.haveBluePrintNum) then
		_info.haveBluePrintNum = _info.needBluePrintNum
		self:_print("@@@@ OnBugFix_KEHECHENG_VISIBLE FIXED! haveBluePrintNum " .. tostring(_info.haveBluePrintNum))
	end

	return _info
end

function ExGuideHelper:OnBugFix_XiangqingBianHecheng(guide_id, ship_data)
	self:_print("@@@@ OnBugFix_XiangqingBianHecheng id " .. tostring(guide_id))

	if( tonumber(guide_id) == 35 ) then
		local id = ship_data["shipId"]
		local isOK = tonumber(id) == 111001
		self:_print("@@@@ OnBugFix_XiangqingBianHecheng isOK " .. tostring(isOK))
		return isOK
	end
	return true
end
print( "###LUA Return ExGuideHelper.lua 28" )
function ExGuideHelper:OnTouchEndNoBug(this_id)
	local _self = ExGuideHelper
		_self:_print("@@@@ NoBug! go OnTouchEndNoBug ")
		local conf = CONF.GUIDANCE.get(this_id)
		local listener = cc.EventListenerTouchOneByOne:create()
		require("app.views.GuideLayer.GuideLayer"):OnTouchEndNoBug(conf, listener, nil, true, this_id)
end

function ExGuideHelper:TryAutoCursor(this_id)
	local _self = ExGuideHelper
	local isNoBug = _self.touchHelper:OnFixBugGuide(this_id)
	if( isNoBug == false ) then
		do return false end
	end

	_self:OnTouchEndNoBug(this_id)
	return true
end

function ExGuideHelper:OnBugFix_AutoCursor(guide_id)
	local _self = ExGuideHelper

	local is_id = (tonumber(guide_id) == _self.touchHelper.BUG_GUIDE_ID_XIANG_QING_BIAN_HE_CHENG)
			 or (tonumber(guide_id) == _self.touchHelper.BUG_GUIDE_ID_REN_WU_MEI_TAN_CHU)

	if( is_id ) then
		_self:TryAutoCursor(guide_id)
		return
	end

	local touch_bug_helper = require("util.ExGuideTouchBug"):getInstance()
	local id_fb = touch_bug_helper.BUG_GUIDE_ID_FU_BEN_MEI_TAN_CHU
	if( tonumber(guide_id) == id_fb ) then
		local is_bug = touch_bug_helper:OnGuideId(id_fb)
		if( is_bug ) then
			do return end
		end

		_self:OnTouchEndNoBug(id_fb)

		return
	end

end


function ExGuideHelper:OnUpdate()
	local _self = ExGuideHelper
	_self:_print("@@@@ ExGuideHelper OnUpdate " )
	local id_current = self.guideTools:GetGuideIdLocal()
	_self:_print("@@@@ id_current : "  .. tostring(id_current))

	_self:OnBugFix_AutoCursor(id_current)

end

------------------------------------------------

function ExGuideHelper:getInstance()
	print( "###LUA ExGuideHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExGuideHelper:onCreate()
	print( "###LUA ExGuideHelper.lua onCreate" )

	return self
end

print( "###LUA Return ExGuideHelper.lua" )
return ExGuideHelper