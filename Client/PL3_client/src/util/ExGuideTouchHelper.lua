print( "###LUA ExGuideTouchHelper.lua" )
-- Coded by Wei Jingjun 20180620
local ExGuideTouchHelper = class("ExGuideTouchHelper")

ExGuideTouchHelper.IS_DEBUG_LOG_LOCAL = false

function ExGuideTouchHelper:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end
------------------------------------------------

ExGuideTouchHelper.bugHelper = require("util.ExGuideTouchBug"):getInstance()
ExGuideTouchHelper.timeHelper = require("util.ExTimeHelper"):getInstance()



-- ADDED BY WJJ 20180606
ExGuideTouchHelper.BUG_GUIDE_ID_XIANG_QING_BIAN_HE_CHENG = 34
ExGuideTouchHelper.BUG_GUIDE_ID_REN_WU_MEI_TAN_CHU = 80


-- TO FIX CLICK SO FAST BUG ON GUIDE
ExGuideTouchHelper.GUIDE_CLICK_SIZE_MULTIPLY = 1
local MIN_GUIDE_CLICK_DURATION = 0.05
local MIN_GUIDE_MULTIPLE_CLICK_DURATION = 0.19
local GUIDE_MULTIPLE_CLICK_TIMES = 1

local GUIDE_TIME_IN_RANGE_MAX = 8

local guideClickTimer = {}
guideClickTimer.lastTouchBeganTime = 0
guideClickTimer.lastClickOkTime = -1

local IS_GUIDE_CLICK_TIME_LIMITED = false

print( "###LUA ExGuideTouchHelper.lua 54"  )
function ExGuideTouchHelper:OnFixBugGuide(gId)
	self:_print("GuideLayer OnFixBugGuide gId: " .. tostring(gId) )
	local isNoBug = true


	local is_bug = self.bugHelper:OnGuideId(gId)

	if( is_bug ) then
		do return false end
	end

	if( gId == self.BUG_GUIDE_ID_REN_WU_MEI_TAN_CHU ) then
		self:_print("###LUA GuideLayer OnFixBugGuide BUG_GUIDE_ID_REN_WU_MEI_TAN_CHU " )
		-- local timeOnTaskSceneOK = cc.UserDefault:getInstance():getStringForKey("global_taskscene_ok_time")
		local timeOnTaskSceneOK = cc.exports.global_taskscene_ok_time or -1

		isNoBug = self.timeHelper:IsTimeInRange(timeOnTaskSceneOK,0,GUIDE_TIME_IN_RANGE_MAX)

		--[[
		if( (timeOnTaskSceneOK == nil) or (tonumber(timeOnTaskSceneOK) == nil) ) then
			do return false end
		end
		self:_print("###LUA timeOnTaskSceneOK = " .. tostring(timeOnTaskSceneOK))

		local timeNow = os.time()
		self:_print("###LUA timeNow = " .. tostring(timeNow))

		local passedTime_task = tonumber(timeNow) - tonumber(timeOnTaskSceneOK)
		self:_print("###LUA passedTime_task = " .. tostring(passedTime_task))

		if( ( (passedTime_task > 0) and ( (passedTime_task < 60) ) ) == false ) then
			self:_print("###LUA GuideLayer BUG_GUIDE_ID_REN_WU_MEI_TAN_CHU CANNOT GO NEXT GUIDE!!")
			isNoBug = false
			-- do return false end
		end
		--]]
	end

	if( gId == self.BUG_GUIDE_ID_XIANG_QING_BIAN_HE_CHENG ) then
		self:_print("GuideLayer OnFixBugGuide : gId: " .. tostring(self.BUG_GUIDE_ID_XIANG_QING_BIAN_HE_CHENG) )
		-- local _shipsDevelopScene = ShipsDevelopScene
		-- if ( _shipsDevelopScene == nil ) then
		--	print("GuideLayer END OnFixBugGuide : isNoBug: false " )
		--	do return false end
		-- end

		-- local sel = _shipsDevelopScene.selectedShip

		-- local timeOnSelectShipOK = cc.UserDefault:getInstance():getStringForKey("global_shipdevelopscene_selected_ship_time")
		local timeOnSelectShipOK = cc.exports.global_shipdevelopscene_selected_ship_time or -1

		local isTimeOk = self.timeHelper:IsTimeInRange(timeOnSelectShipOK,-1,GUIDE_TIME_IN_RANGE_MAX)

		if( isTimeOk == false ) then
			self:_print("GuideLayer END OnFixBugGuide : BUG_GUIDE_ID_XIANG_QING_BIAN_HE_CHENG false " )
			do return false end
		end


		-- local sel_ship = cc.UserDefault:getInstance():getStringForKey("global_shipdevelopscene_selected_ship")
		local sel_ship = cc.exports.global_shipdevelopscene_selected_ship
		if( sel_ship == nil ) then
			self:_print("GuideLayer END OnFixBugGuide : isNoBug: false " )
			do return false end
		end

		self:_print( "##LUA shipsDevelopScene : " .. tostring(sel_ship) )
		local isSelectOK = false
		isSelectOK = ( sel_ship == "111001" )
		--[[
	
		for _k,_v in pairs(sel) do
			if ( isSelectOK == false ) then
				self:_print( "## Lua GuideLayer.lua ShipsDevelopScene.selectedShip _k: " .. tostring(_k) )
				self:_print( "## Lua GuideLayer.lua ShipsDevelopScene.selectedShip _v: " .. tostring(_v) )
				isSelectOK = ( _k ==  "shipId" ) and ( _v == 111001 )

				-- cc.UserDefault:getInstance():setStringForKey("global_shipdevelopscene_selected_ship_time", tostring(os.time()))

			end
		end
		--]]
		isNoBug = isSelectOK
	end

	self:_print("GuideLayer END OnFixBugGuide : isNoBug: " .. tostring(isNoBug) )
	return isNoBug
end
print( "###LUA ExGuideTouchHelper.lua 139"  )
function ExGuideTouchHelper:SetClickOkTimeNow()
	guideClickTimer.lastClickOkTime = os.clock()
	self:_print("GuideLayer SetClickOkTimeNow : " .. tostring(tonumber(guideClickTimer.lastClickOkTime)))
end

function ExGuideTouchHelper:SetTouchBeganTimeNow()
	guideClickTimer.lastTouchBeganTime = os.clock()
	self:_print("GuideLayer SetTouchBeganTimeNow : " .. tostring(tonumber(guideClickTimer.lastTouchBeganTime)))
end

function ExGuideTouchHelper:IsGuideMultipleClickOK()
	self:_print("GuideLayer IsGuideMultipleClickOK  " )
	local isMultipleClick = false
	if( (guideClickTimer.lastClickOkTime < 0) and ( GUIDE_MULTIPLE_CLICK_TIMES > 1 ) ) then
		isMultipleClick = false
	elseif( GUIDE_MULTIPLE_CLICK_TIMES > 1 ) then
		local passedTime = os.clock() - guideClickTimer.lastClickOkTime
		self:_print("GuideLayer MultipleClick passedTime : " .. tostring(passedTime ) ) 
		isMultipleClick = passedTime < MIN_GUIDE_MULTIPLE_CLICK_DURATION
	end

	self:SetClickOkTimeNow()

	self:_print("GuideLayer IsGuideMultipleClickOK : " .. tostring(isMultipleClick))
	return isMultipleClick
end

function ExGuideTouchHelper:IsGuideClickTimeOK()
	self:_print("@@@@ ExGuideTouchHelper IsGuideClickTimeOK : " .. tostring(tonumber( os.clock() ) ) )
	local passedTime = os.clock() - guideClickTimer.lastTouchBeganTime
	self:_print("@@@@ ExGuideTouchHelper passedTime : " .. tostring(passedTime ) ) 
	local isClick = passedTime >= MIN_GUIDE_CLICK_DURATION


	if ( (isClick == true) and (GUIDE_MULTIPLE_CLICK_TIMES > 1) )  then
		local isMultipleClick = self:IsGuideMultipleClickOK()
		isClick = isMultipleClick
	end
	self:_print("GuideLayer isClick : " .. tostring(isClick ) ) 
	return isClick
end

------------------------------------------------

function ExGuideTouchHelper:getInstance()
	--print( "###LUA ExGuideTouchHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExGuideTouchHelper:onCreate()
	--print( "###LUA ExGuideTouchHelper.lua onCreate" )

	return self
end

print( "###LUA Return ExGuideTouchHelper.lua" )
return ExGuideTouchHelper