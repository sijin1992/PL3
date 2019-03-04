-- Coded by Wei Jingjun 20180702
print( "###LUA ExLagHelper.lua" )
local ExLagHelper = class("ExLagHelper")
ExLagHelper.app = require("app.MyApp"):getInstance()

ExLagHelper.oldSceneParams = {}

function ExLagHelper:getApp()
	return self.app
end
------------------------------------------------
function ExLagHelper:EndTransferEffect(data, old_data, _is_always, _z, _scene_name, _node)
	if( _z == nil ) then
		_z = 100
	end

	local _data = {}
	if data then
		_data = data
	else 
		return old_data
	end
	if ((data and data.sfx) or _is_always ) then
		if( data and data.sfx ) then
			data.sfx = false
		end
		local view = self:getApp():createView("CityScene/TransferScene",{from = _scene_name ,state = "enter"})
		_node:addChild(view, _z)
	end

	_data = data
	return _data
end

function ExLagHelper:BeginTransferEffect(_old_scene, _param)
	self:getApp():addView2Top("CityScene/TransferScene",{from = _old_scene ,state = "start"})
	self.oldSceneParams[_old_scene] = _param
end

------------------------------------------------

function ExLagHelper:getInstance()
	print( "###LUA ExLagHelper.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExLagHelper:onCreate()
	print( "###LUA ExLagHelper.lua onCreate" )


	return self.instance
end

print( "###LUA Return ExLagHelper.lua" )
return ExLagHelper