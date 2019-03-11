-- Coded by Wei Jingjun 20180709
print( "###LUA ExSDK.lua" )
local ExSDK = class("ExSDK")

------------------------------------------------
function ExSDK:IsWindows()
	return device.platform == "windows"
end

function ExSDK:IsQuickSDK()
	return g_is_quick_sdk and ( device.platform ~= "windows" )
end

-- server_platform is a global var in Common.lua !!
function ExSDK:SDK_REQ_QuickPay(recharge_conf)
	local player = require("app.Player"):getInstance()
	local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
	local user_id = cc.UserDefault:getInstance():getStringForKey("user_id")

	-- Added by Wei Jingjun 20180531 for Dangle SDK bug
	local user_name = player:getNickName() -- WJJ: DO NOT USE getName()
	local balance = player:getMoney()
	local vipLv = player:getUserInfo().vip_level
	local userLv = player:getLevel()
	local party = player:getGroupName()
	local createTime = cc.UserDefault:getInstance():getIntegerForKey("user_create_time")
	local server_name = cc.UserDefault:getInstance():getStringForKey("server_name")

	--print("lua quickPay", user_id,server_id,recharge_conf.PRODUCT_ID,1,recharge_conf["RECHARGE_"..server_platform],user_name,balance,vipLv,userLv,party, createTime, server_name)
	GameHandler.handler_c.quickPay(user_id, server_id, recharge_conf.PRODUCT_ID, 1, recharge_conf["RECHARGE_"..server_platform],user_name,balance,vipLv,userLv,party, createTime, server_name)

end

------------------------------------------------

function ExSDK:getInstance()
	print( "###LUA ExSDK.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExSDK:onCreate()
	print( "###LUA ExSDK.lua onCreate" )


	return self.instance
end

print( "###LUA Return ExSDK.lua" )
return ExSDK