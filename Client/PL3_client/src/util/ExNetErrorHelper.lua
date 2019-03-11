print( "###LUA ExNetErrorHelper.lua" )
-- Coded by Wei Jingjun 20180703
local ExNetErrorHelper = class("ExNetErrorHelper")

ExNetErrorHelper.IS_DEBUG_LOG_LOCAL = false

function ExNetErrorHelper:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

ExNetErrorHelper.config = require("util.ExConfig"):getInstance()
------------------------------------------------

ExNetErrorHelper.EVENT_GATEWAY_CONNECT_FAILED = "gateway_connect_failed"
ExNetErrorHelper.KEY_CHECK_CONNECT_GATEWAY = "net_isCheckConnectGateway"
ExNetErrorHelper.KEY_CONNECT_GATEWAY_BEGAN = "net_began_connect_gateway"
ExNetErrorHelper.KEY_CONNECT_GATEWAY_END = "net_end_connect_gateway"

ExNetErrorHelper.KEY_CHECK_LOGIN_CONNECT = "net_isCheckLoginConnect"
ExNetErrorHelper.KEY_LOGIN_CONNECT_BEGAN = "net_began_connect_login_server_in_cpp"
ExNetErrorHelper.KEY_LOGIN_CONNECT_END = "net_end_connect_login_server_in_cpp"
ExNetErrorHelper.TIME_MAX_LOGIN_CONNECT = 8

------------------------------------------------

ExNetErrorHelper.timeHelper =  require("util.ExTimeHelper"):getInstance()
ExNetErrorHelper.app = require("app.MyApp"):getInstance()

ExNetErrorHelper.exSchedulerHelper_single = require("util.ExSchedulerHelper")
ExNetErrorHelper.exSchedulerHelper = {}
ExNetErrorHelper.UPDATE_INTERVAL = 4
ExNetErrorHelper.UPDATE_INIT = 0
ExNetErrorHelper.UPDATE_MAX = 1

-- ExNetErrorHelper.isCheckLoginConnect = false

------------------------------------------------

ExNetErrorHelper.gateway_xhr = {}

function ExNetErrorHelper:getApp()
	return self.app
end



function ExNetErrorHelper:SetCheckConnectGateway(_value)
--	cc.UserDefault:getInstance():setStringForKey(self.KEY_CHECK_CONNECT_GATEWAY, _value)
--	cc.UserDefault:getInstance():flush()
	cc.exports[self.KEY_CHECK_CONNECT_GATEWAY] = _value
end
function ExNetErrorHelper:SetCheckLoginConnect(_value)
--	cc.UserDefault:getInstance():setStringForKey(self.KEY_CHECK_LOGIN_CONNECT, _value)
--	cc.UserDefault:getInstance():flush()
	cc.exports[self.KEY_CHECK_LOGIN_CONNECT] = _value
end
function ExNetErrorHelper:onCreate()
	self:_print( "###LUA ExNetErrorHelper.lua onCreate" )
	-- self.isCheckLoginConnect = false

	self:SetCheckLoginConnect("false")
	self:SetCheckConnectGateway(tostring(false))

	if( self.exSchedulerHelper.count_current == nil ) then
		self:InitScheduler()
	end

	self.timeHelper:SetGlobalVal_TimeNowOf(self.KEY_LOGIN_CONNECT_BEGAN, -1) 
	self.timeHelper:SetGlobalVal_TimeNowOf(self.KEY_LOGIN_CONNECT_END, -1) 

	self.timeHelper:SetGlobalVal_TimeNowOf(self.KEY_CONNECT_GATEWAY_BEGAN, -1, true) 
	self.timeHelper:SetGlobalVal_TimeNowOf(self.KEY_CONNECT_GATEWAY_END, -1, true) 

	return self
end

------------------------------------------------

function ExNetErrorHelper:GetCheckConnectGateway()
	-- return cc.UserDefault:getInstance():getStringForKey(self.KEY_CHECK_CONNECT_GATEWAY)
	return cc.exports[self.KEY_CHECK_CONNECT_GATEWAY] or "false"
end


-- setIntegerForKey
function ExNetErrorHelper:GetConnectGatewayBeganTime()
	-- return cc.UserDefault:getInstance():getIntegerForKey(self.KEY_CONNECT_GATEWAY_BEGAN)
	return cc.exports[self.KEY_CONNECT_GATEWAY_BEGAN] or -1
end

function ExNetErrorHelper:GetConnectGatewayEndTime()
	-- return cc.UserDefault:getInstance():getIntegerForKey(self.KEY_CONNECT_GATEWAY_END)
	return cc.exports[self.KEY_CONNECT_GATEWAY_END] or -1
end
------------------------------------------------


function ExNetErrorHelper:GetCheckLoginConnect()
	-- return cc.UserDefault:getInstance():getStringForKey(self.KEY_CHECK_LOGIN_CONNECT)
	return cc.exports[self.KEY_CHECK_LOGIN_CONNECT] or "false"
end


print( "###LUA ExNetErrorHelper.lua 53" )
function ExNetErrorHelper:GetLoginConnectBeganTime()
	-- return cc.UserDefault:getInstance():getStringForKey(self.KEY_LOGIN_CONNECT_BEGAN)
	return cc.exports[self.KEY_LOGIN_CONNECT_BEGAN] or -1
end

function ExNetErrorHelper:GetLoginConnectEndTime()
	-- return cc.UserDefault:getInstance():getStringForKey(self.KEY_LOGIN_CONNECT_END)
	return cc.exports[self.KEY_LOGIN_CONNECT_END] or -1
end

------------------------------------------------

function ExNetErrorHelper:OnConnectGatewayResponsed()
	self.timeHelper:SetGlobalVal_TimeNowOf(self.KEY_CONNECT_GATEWAY_END,nil, true) 
end

function ExNetErrorHelper:OnFailedConnectGateway()
	self:_print("@@@ OnFailedConnectGateway")
	self:SetCheckConnectGateway(tostring(false))
	--TODO USE FAKE JSON
	
	--print("@@@ OnFailedConnectGateway event_name : " .. tostring(self.EVENT_GATEWAY_CONNECT_FAILED))
	-- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent(self.EVENT_GATEWAY_CONNECT_FAILED)
	

	-- local _login_scene = require("app.views.LoginScene/LoginScene")
	local netGateway = require("app.ExNetMsgGateway"):getInstance()
	local _instance = netGateway.instance_LoginScene
	netGateway:OnGatewayResponse( self.config:GetFakeJson_Gateway(), self.gateway_xhr, _instance)

end

function ExNetErrorHelper:OnCheckConnectGateway()
	local is_check = self:GetCheckConnectGateway()
	--self:_print("@@@@ GetCheckConnectGateway now: " .. tostring(os.time()))
	--self:_print("@@@@ is_check: " .. tostring(is_check))
	if( is_check ~= "true" ) then
		return
	end


	local now = os.time()
	local began_time = self:GetConnectGatewayBeganTime()
	local end_time = self:GetConnectGatewayEndTime()

	local is_failed = ( (end_time == nil) or ( tonumber(end_time) == nil ) or (began_time == nil) or (tonumber(began_time) == nil)  )

	--print( "~~~~ is_failed  BEGIN  >>> >>> " )
	--print( is_failed )
	--print( (end_time == nil),( tonumber(end_time) == nil ),(began_time == nil), (tonumber(began_time) == nil))
	--print( "~~~~ is_failed  END  >>> >>> " )

	if( is_failed == false ) then
		is_failed = ( ( tonumber(end_time) < 0 )  or ( tonumber(began_time) < 0 ) )
	end

	--print( "~~~~ began_time,end_time,is_failed  BEGIN  >>> >>> " )
	--print( began_time,end_time,is_failed )
	--print( "~~~~ began_time,end_time  END  >>> >>> " )

	if( is_failed == false ) then
		local passed = tonumber(end_time) - tonumber(began_time)
		self:_print(string.format("@@@@ OnCheckConnectGateway  SUCCESS !  passed time : %s", tostring(passed)))
		self:SetCheckConnectGateway(tostring(false))
		return
	end

	self:_print(string.format("@@@@ began_time : %s", tostring(tonumber(began_time))))
	if( is_failed and ( tonumber(began_time) > 0 )) then
		local passed_time = now - tonumber(began_time)
		self:_print("@@@@  passed_time: " .. tostring(passed_time))
		local is_time_out = passed_time >= self.TIME_MAX_LOGIN_CONNECT

		if( is_time_out ) then
			self:OnFailedConnectGateway()
		end
	end

	self:_print("@@@@ OnCheckConnectLogin_CPP is_failed: " .. tostring(is_failed))

end


function ExNetErrorHelper:OnConnectGatewayBegin()
	self:onCreate()
	self:SetCheckConnectGateway(tostring(false))
	self.timeHelper:SetGlobalVal_TimeNowOf(self.KEY_CONNECT_GATEWAY_BEGAN, nil, true) 
end

------------------------------------------------

print( "###LUA ExNetErrorHelper.lua 61" )
function ExNetErrorHelper:OnLoginConnectResponsed()
	self.timeHelper:SetGlobalVal_TimeNowOf(self.KEY_LOGIN_CONNECT_END) 
end

function ExNetErrorHelper:OnFailedConnectLogin_CPP()
	self:_print("@@@ OnFailedConnectLogin_CPP")
	self:SetCheckLoginConnect("false")
	self:getApp():pushToRootView("LoginScene/LoginScene")
end
print( "###LUA ExNetErrorHelper.lua 69" )

function ExNetErrorHelper:OnCheckConnectLogin_CPP()
	local is_check = self:GetCheckLoginConnect()
	--self:_print("@@@@ OnCheckConnectLogin_CPP now: " .. tostring(os.time()))
	--self:_print("@@@@ isCheckLoginConnect: " .. tostring(is_check))
	if( is_check ~= "true" ) then
		return
	end


	local now = os.time()
	local began_time = self:GetLoginConnectBeganTime()
	local end_time = self:GetLoginConnectEndTime()

	local is_failed = ( (end_time == nil) or ( tonumber(end_time) < 0 )  or (began_time == nil) or ( tonumber(began_time) < 0 ) )

	if( is_failed == false ) then
		local passed = tonumber(end_time) - tonumber(began_time)
		self:_print(string.format("@@@@ OnhCeckConnectLogin_CPP  SUCCESS !  passed time : %s", tostring(passed)))
		self:SetCheckLoginConnect("false")
		return
	end

	self:_print(string.format("@@@@ began_time : %s", tostring(tonumber(began_time))))
	if( is_failed and ( tonumber(began_time) > 0 )) then
		local passed_time = now - tonumber(began_time)
		self:_print("@@@@  passed_time: " .. tostring(passed_time))
		local is_time_out = passed_time >= self.TIME_MAX_LOGIN_CONNECT

		if( is_time_out ) then
			self:OnFailedConnectLogin_CPP()
		end
	end

	self:_print("@@@@ OnCheckConnectLogin_CPP is_failed: " .. tostring(is_failed))

end

print( "###LUA ExNetErrorHelper.lua 102" )
function ExNetErrorHelper:OnConnectLoginServerBegin_CPP(_node)
	self:onCreate()
	self:SetCheckLoginConnect("true")

	self.timeHelper:SetGlobalVal_TimeNowOf(self.KEY_LOGIN_CONNECT_BEGAN) 

	-- _node:runAction(cc.Sequence:create(cc.DelayTime:create(self.TIME_MAX_LOGIN_CONNECT), cc.CallFunc:create(function ( ... )
		
	-- end)))

end

------------------------------------------------

function ExNetErrorHelper:OnSchedulerUpdate()
	local _self = ExNetErrorHelper
	if( _self.exSchedulerHelper.ScheduleState ~= _self.exSchedulerHelper.E_LOADING_STATE.RUNNING ) then
		--print( "###LUA NOT RUNNING !! ExNetErrorHelper State: " .. ( tostring(_self.exSchedulerHelper.ScheduleState) or " nil " ) )
		do return end
	end

	_self:OnCheckConnectLogin_CPP()
	_self:OnCheckConnectGateway()
	--_self:_print( "###LUA ExNetErrorHelper RUNNING !!")
end

function ExNetErrorHelper:OnSchedulerEnd()
	self:_print("@@@@ ExNetErrorHelper:OnSchedulerEnd")
end

function ExNetErrorHelper:InitScheduler()
	self:_print( "###LUA ExNetErrorHelper.lua InitScheduler" )
	self.exSchedulerHelper = self.exSchedulerHelper_single:new(self.exSchedulerHelper, self.UPDATE_INTERVAL, self.UPDATE_INIT, self.UPDATE_MAX )
	self.exSchedulerHelper:RegisterCallBack(self.OnSchedulerEnd)
	self.exSchedulerHelper:OnBegin(self.OnSchedulerUpdate)
end

function ExNetErrorHelper:getInstance()
	self:_print( "###LUA ExNetErrorHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end



print( "###LUA Return ExNetErrorHelper.lua" )
return ExNetErrorHelper