print( "###LUA ExViewInterface.lua" )
-- Coded by Wei Jingjun 20180620
local ExViewInterface = class("ExViewInterface")
ExViewInterface.app = require("app.MyApp"):getInstance()

ExViewInterface.IS_DEBUG_LOG_LOCAL = false
ExViewInterface.IS_SCENE_TRANSFER_EFFECT = false
ExViewInterface.lagHelper = require("util.ExLagHelper"):getInstance()

function ExViewInterface:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end
------------------------------------------------

function ExViewInterface:getApp()
	return self.app
end

function ExViewInterface:ShowUI(_path, _param, _is_effect_delay)

	if( _path == nil ) then
		do return false end
	end

	if( _is_effect_delay == nil ) then
		_is_effect_delay = self.IS_SCENE_TRANSFER_EFFECT
	end

	if( _param ~= nil ) then
		if( _is_effect_delay ) then
			self.lagHelper:BeginTransferEffect(_path, _param)
		else
			self:getApp():pushView(_path, _param)
		end
	else 
		if( _is_effect_delay ) then
			self.lagHelper:BeginTransferEffect(_path)
		else
			self:getApp():pushView(_path)
		end
	end

	return true
end
function ExViewInterface:ShowActivityUI(_param)
	self:ShowUI("ActivityScene/ActivityScene", _param)
end

function ExViewInterface:ShowShopUI(_param)
	self:getApp():addView2Top("ShopScene/ShopLayer")
--	self:ShowUI("ShopScene/ShopLayer", _param)
end

------------------------------------------------

function ExViewInterface:getInstance()
	--print( "###LUA ExViewInterface.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExViewInterface:onCreate()
	--print( "###LUA ExViewInterface.lua onCreate" )

	return self
end

--print( "###LUA Return ExViewInterface.lua" )
return ExViewInterface