-- Coded by Wei Jingjun 20180723
print( "###LUA UI_Helper_WinLayer.lua" )
local UI_Helper_WinLayer = class("UI_Helper_WinLayer")


------------------------------------------------

function UI_Helper_WinLayer:OnInitWinPopupPanel(_name, _parent, _self)
	local layer = _self:createLayer2()
	layer:setName(_name)
	_parent:addChild(layer)

	local center = cc.exports.VisibleRect:center()
	layer:setAnchorPoint(cc.p(0.5 ,0.5))
	layer:setPosition(center)

		-- ADD WJJ 20180723
	layer = require("util.ExConfigScreenAdapter"):getInstance():onFixWinLayer2(layer)

	_self:setVisible(false)

	return layer
end

------------------------------------------------

function UI_Helper_WinLayer:getInstance()
	print( "###LUA UI_Helper_WinLayer.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function UI_Helper_WinLayer:onCreate()
	print( "###LUA UI_Helper_WinLayer.lua onCreate" )


	return self.instance
end

print( "###LUA Return UI_Helper_WinLayer.lua" )
return UI_Helper_WinLayer