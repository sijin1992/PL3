print( "###LUA ExTimeHelper.lua" )
-- Coded by Wei Jingjun 20180620
local ExTimeHelper = class("ExTimeHelper")

ExTimeHelper.IS_DEBUG_LOG_LOCAL = false

function ExTimeHelper:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

------------------------------------------------

function ExTimeHelper:SetGlobalVal_TimeNowOf(_key, _time, _is_int) 

	local _now = os.time()

	if( _time ~= nil ) then
		_now = _time
	end

	if( _is_int == nil ) then
		_is_int = false
	end

	if( _is_int ) then
		cc.exports[_key] = tonumber(_now)
		-- cc.UserDefault:getInstance():setIntegerForKey(_key, tonumber(_now))
	else
		cc.exports[_key] = tostring(_now)
		-- cc.UserDefault:getInstance():setStringForKey(_key, tostring(_now))
	end

	-- cc.UserDefault:getInstance():flush()
	self:_print(string.format("@@@@ SetGlobalVal_TimeNowOf %s    _now : %s", _key, tostring(_now)))
end

function ExTimeHelper:IsTimeOutRange(timeOld, min, max)
	self:_print("###LUA ExTimeHelper IsTimeOutRange timeOld = " .. tostring(timeOld))
	local isTimeOk = true

	if( (timeOld == nil) or (tonumber(timeOld) == nil) ) then
		do return false end
	end

	local timeNow = os.time()
	self:_print("###LUA timeNow = " .. tostring(timeNow))
	local passedTime = tonumber(timeNow) - tonumber(timeOld)
	self:_print("###LUA passedTime = " .. tostring(passedTime))

	if( ( (passedTime < min) or ( (passedTime > max) ) ) == false ) then
		self:_print("###LUA ExTimeHelper sTimeInRange false !!")
		isTimeOk = false
	end

	return isTimeOk
end

function ExTimeHelper:IsTimeInRange(timeOld, min, max)
	self:_print("###LUA ExTimeHelper IsTimeInRange timeOld = " .. tostring(timeOld))
	local isTimeOk = true

	if( (timeOld == nil) or (tonumber(timeOld) == nil) ) then
		do return false end
	end

	local timeNow = os.time()
	self:_print("###LUA timeNow = " .. tostring(timeNow))
	local passedTime = tonumber(timeNow) - tonumber(timeOld)
	self:_print("###LUA passedTime = " .. tostring(passedTime))

	if( ( (passedTime > min) and ( (passedTime < max) ) ) == false ) then
		self:_print("###LUA ExTimeHelper sTimeInRange false !!")
		isTimeOk = false
	end

	return isTimeOk
end

------------------------------------------------

function ExTimeHelper:getInstance()
	--print( "###LUA ExTimeHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExTimeHelper:onCreate()
	--print( "###LUA ExTimeHelper.lua onCreate" )

	return self
end

print( "###LUA Return ExTimeHelper.lua" )
return ExTimeHelper