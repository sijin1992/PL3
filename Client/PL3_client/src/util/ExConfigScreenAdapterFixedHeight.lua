-- Coded by Wei Jingjun 20180619
--print( "###LUA ExConfigScreenAdapterFixedHeight.lua" )
local ExConfigScreenAdapterFixedHeight = class("ExConfigScreenAdapterFixedHeightFixedHeight")

---------------------------------------------------------------------------------------
-- shi lian
ExConfigScreenAdapterFixedHeight.SHI_LIAN_LAYER_AP_X = 0
ExConfigScreenAdapterFixedHeight.SHI_LIAN_LAYER_AP_Y = 0

-- he cheng chuan 
ExConfigScreenAdapterFixedHeight.HE_CHENG_GET_NEW_SHIP_OFFSET_X = 273
ExConfigScreenAdapterFixedHeight.HE_CHENG_GET_NEW_SHIP_OFFSET_Y = 0

-- yu zhou xin xi
ExConfigScreenAdapterFixedHeight.YU_ZHOU_XIN_XI_OFFSET_X = 0
ExConfigScreenAdapterFixedHeight.YU_ZHOU_XIN_XI_OFFSET_Y = -60

---------------------------------------------------------------------------------------

ExConfigScreenAdapterFixedHeight.SCREEN_FIX_W_H_RATE = 1.9

-- SeeStationedArmyLayer 
ExConfigScreenAdapterFixedHeight.SEESTATIONED_NODE_X = 250
ExConfigScreenAdapterFixedHeight.SEESTATIONED_NODE_Y = 125
-- CityGetReward
ExConfigScreenAdapterFixedHeight.CITYGETREWARD_NODE_X = -254
-- HomeBuildUpInfo
ExConfigScreenAdapterFixedHeight.HOMEBUILDUPINFO_NODE_X = -254
-- GreenHandBuff
ExConfigScreenAdapterFixedHeight.GREENHANDBUFF_NODE_Y = -30
--------------------------------------------------------------------------------------
ExConfigScreenAdapterFixedHeight.BATTLE_SHOW_SHIP_DELAY = 1

--------------------------------------------------------------------------------------

function ExConfigScreenAdapterFixedHeight:IsFixScreenEnabled()
	-- do return false end
	return require("util.ExConfigScreenAdapter"):getInstance():IsFixScreenEnabled_Base()
end

function ExConfigScreenAdapterFixedHeight:SetPosXY_Offset(_node, _x, _y)
	require("util.ExConfigScreenAdapter"):getInstance():SetPosXY_Offset(_node, _x, _y)
end

function ExConfigScreenAdapterFixedHeight:SetListPosXY_Offset(_parent, _list, _x, _y)
	require("util.ExConfigScreenAdapter"):getInstance():SetListPosXY_Offset(_parent, _list, _x, _y)
end

----------------------------------------------------------------------------------------

function ExConfigScreenAdapterFixedHeight:Util_AlignToCenter(_node, _width, _height)

	if ( _width == nil ) then
		_width = 1136
	end

	if ( _height == nil ) then
		_height = 781
	end

	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()

	-- _node:setAnchorPoint(0, 0)
	-- setScreenPosition( _node, "center")
	--print("~~~  _node word pos")

	local x_offset_to_mid = 0
	if( _cfg:IsFixScreenEnabled() ) then
		x_offset_to_mid = ( display.size.width - _width ) / 2
	end


	local y_offset_to_mid = ( display.size.height - _height ) / 2
	local pos_zero_w2n = _node:getParent():convertToNodeSpace(cc.p(x_offset_to_mid,y_offset_to_mid))

	_node:setPosition(pos_zero_w2n)

	local x,y = _node:getPosition()
	local pos_world = _node:getParent():convertToWorldSpace(cc.p(x,y))
	--print("~~~ pos_world x y ")
	--print(pos_world.x,pos_world.y)

	-- 640 - 781
end

function ExConfigScreenAdapterFixedHeight:Util_SetShipVisible(_ship, _visible)
	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()

	local opa = 0
	if( _visible == true ) then
		opa = 255
	end

	_ship.renderer:setOpacity(opa)

	if( _visible ) then

		_ship.ui:runAction(cc.Sequence:create(cc.DelayTime:create(_cfg.BATTLE_SHOW_SHIP_DELAY), cc.CallFunc:create(function ( ... )
			local ui = _ship.ui
			ui:setOpacity(255)
		end)))

	else

		-- local ui = _ship.ui:getChildByName("loadingbar")
		local ui = _ship.ui
		ui:setOpacity(opa)
	end
end

function ExConfigScreenAdapterFixedHeight:onFixQMP_Duanzao_PayCD(_node)
	--print("~~~ onFixQMP_Duanzao_PayCD ")

	self:Util_AlignToCenter(_node)
end

function ExConfigScreenAdapterFixedHeight:onFixQMP_Xingmeng_Chuangjian(_node)
	--print("~~~ onFixQMP_Xingmeng_Chuangjian ")

	self:Util_AlignToCenter(_node)

end

function ExConfigScreenAdapterFixedHeight:onFixQMP_Judian_Jiangli(_rn)
	--print("~~~ onFixQMP_Judian_Jiangli ")
	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false ) then
		return
	end

	local bg = _rn:getChildByName("uibg")
	bg:setContentSize(cc.size(2048,1080))

end


function ExConfigScreenAdapterFixedHeight:onFixQMP_Battle_ShowEnemyShip(_list)
	--print("~~~ onFixQMP_Battle_ShowEnemyShip ")
	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false ) then
		return
	end

	for k,v in pairs(_list) do
		if v ~= nil then
			_cfg:Util_SetShipVisible(v, true)
		end
	end

end

function ExConfigScreenAdapterFixedHeight:onFixQMP_Battle_ShowMyShip(_ship)
	--print("~~~ onFixQMP_Battle_ShowMyShip ")
	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false ) then
		return
	end

	_cfg:Util_SetShipVisible(_ship, true)
end

function ExConfigScreenAdapterFixedHeight:onFixQMP_Battle_DelayShowShip(_ship)
	--print("~~~ onFixQMP_Battle_DelayShowShip ")
	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false ) then
		return
	end

	_cfg:Util_SetShipVisible(_ship, false)

	-- table.insert(pool_battle_ships, _attackers)
	-- local attack_list_pos = rn:getChildByName("attack_list_pos")
	-- _cfg:SetPosXY_Offset(_attackers, 1000,0)

	-- _attackers:setVisible(false)
	--[[ 
	_attackers:runAction(cc.Sequence:create(cc.DelayTime:create(_cfg.BATTLE_SHOW_SHIP_DELAY), cc.CallFunc:create(function ( ... )
		_attackers:setOpacity(100)
	end)))
	--]]
end

function ExConfigScreenAdapterFixedHeight:onFixQMP_Battle(_self)
	--print("~~~ onFixQMP_Battle ")
	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false ) then
		-- return
		-- fix all ! or bug
	end

	

	local rn = _self:getResourceNode()
	local ui_layer = rn:getChildByName("ui_layer")
	local Image_bottom_back = ui_layer:getChildByName("Image_bottom_back")
	local Image_top_back = ui_layer:getChildByName("Image_top_back")
	-- local world_zero = cc.p(0,0)
	-- local local_screen_zero = _layer:convertToNodeSpace(world_zero)
	local screen_width = display.size.width
	local screen_height = display.size.height
	local size_bottom = Image_bottom_back:getContentSize()
	local size_top = Image_top_back:getContentSize()
	Image_bottom_back:setContentSize(cc.size(screen_width,size_bottom.height))
	Image_top_back:setContentSize(cc.size(screen_width,size_top.height))

	--print(string.format("~~~ onFixQMP_Battle screen_width : %s  screen_height : %s ", tostring(screen_width), tostring(screen_height) ))

	local world_bottom = cc.p(screen_width * 0.5,0)
	local world_top = cc.p(screen_width * 0.5,screen_height)
	local local_pos_bottom = rn:convertToNodeSpace(world_bottom)
	local local_pos_top = rn:convertToNodeSpace(world_top)
	Image_bottom_back:setPosition( local_pos_bottom )
	Image_top_back:setPosition( local_pos_top )


	local world_pos_bottom = Image_bottom_back:convertToWorldSpace(cc.p(Image_bottom_back:getPositionX(),Image_bottom_back:getPositionY()))
	local world_pos_top = Image_top_back:convertToWorldSpace(cc.p(Image_top_back:getPositionX(),Image_top_back:getPositionY()))
	--print(string.format("~~~ onFixQMP_Battle world_pos_bottom x : %s  y : %s ", tostring(world_pos_bottom.x), tostring(world_pos_bottom.y) ))
	--print(string.format("~~~ onFixQMP_Battle world_pos_top x : %s  y : %s ", tostring(world_pos_top.x), tostring(world_pos_top.y) ))

	

end

function ExConfigScreenAdapterFixedHeight:onFixQMP_Shilian(_layer)
	--print("~~~ onFixQMP_Shilian ")
	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false ) then
		return
	end

	-- _layer:setAnchorPoint(_cfg.SHI_LIAN_LAYER_AP_X, _cfg.SHI_LIAN_LAYER_AP_Y)
	-- setScreenPosition( _layer, "leftbottom")

	local world_zero = cc.p(0,0)
	local local_screen_zero = _layer:convertToNodeSpace(world_zero)
	--print(string.format("~~~ local_screen_zero x: %s  y : %s ", tostring( local_screen_zero.x ), tostring( local_screen_zero.y )) )

	_cfg:SetPosXY_Offset(_layer, local_screen_zero.x,local_screen_zero.y)
	
	-- local o = cc.exports.VisibleRect:leftBottom()

	-- print(string.format("~~~ o.x: %s  o.y : %s ", tostring( o.x ), tostring( o.y )) )

end

function ExConfigScreenAdapterFixedHeight:onFixQuanMianPing_Yuzhou_Xinxi(_self)
	--print("~~~ onFixQuanMianPing_Yuzhou_Xinxi ")
	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false ) then
		return
	end


	local rn = _self:getResourceNode()
	local icon = rn:getChildByName("Image_2")
	local text = rn:getChildByName("planteName")

	_cfg:SetPosXY_Offset(icon, _cfg.YU_ZHOU_XIN_XI_OFFSET_X, _cfg.YU_ZHOU_XIN_XI_OFFSET_Y)
	-- _cfg:SetPosXY_Offset(text, _cfg.YU_ZHOU_XIN_XI_OFFSET_X, _cfg.YU_ZHOU_XIN_XI_OFFSET_Y)

	--[[
	rn:setAnchorPoint(_cfg.HE_CHENG_GET_NEW_SHIP_AP_X, _cfg.HE_CHENG_GET_NEW_SHIP_AP_Y)
	setScreenPosition( rn, "center")
	]]
end

function ExConfigScreenAdapterFixedHeight:onFixQuanMianPing_GetNewShip_Hecheng(_node)
	--print("~~~ onFixQuanMianPing_GetNewShip_Hecheng ")
	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false ) then
		return
	end

		_cfg:SetPosXY_Offset(_node, _cfg.HE_CHENG_GET_NEW_SHIP_OFFSET_X, _cfg.HE_CHENG_GET_NEW_SHIP_OFFSET_Y)

	-- local rn = _self:getResourceNode()
	-- _node:setAnchorPoint(_cfg.HE_CHENG_GET_NEW_SHIP_AP_X, _cfg.HE_CHENG_GET_NEW_SHIP_OFFSET_Y)
	-- setScreenPosition( _node, "center")
end

----------------------------------------------------------------------------------------

function ExConfigScreenAdapterFixedHeight:getInstance()
	--print( "###LUA ExConfigScreenAdapterFixedHeight.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExConfigScreenAdapterFixedHeight:onCreate(  )
	--print( "###LUA ExConfigScreenAdapterFixedHeight.lua onCreate" )


	return self
end

function ExConfigScreenAdapterFixedHeight:onFixQuanmianping_SeeStationedArmy(_self)

	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

    self:SetPosXY_Offset(_self, self.SEESTATIONED_NODE_X, self.SEESTATIONED_NODE_Y)
end

function ExConfigScreenAdapterFixedHeight:onFixQuanmianping_CityGetReward(_self)

	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

    self:SetPosXY_Offset(_self, self.CITYGETREWARD_NODE_X, 0)
end


function ExConfigScreenAdapterFixedHeight:onFixQuanmianping_GreenHandBuff(_self)

	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		-- return
		-- fix all , or bug
	end

    self:SetPosXY_Offset(_self, 0, self.GREENHANDBUFF_NODE_Y)
end

function ExConfigScreenAdapterFixedHeight:onFixQuanmianping_HomeBuildUpInfo(_self)

	local _cfg = require("util.ExConfigScreenAdapterFixedHeight"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

    self:SetPosXY_Offset(_self, self.HOMEBUILDUPINFO_NODE_X, 0)
end

----------------------------------------------------------------------------------------
-- ADD WJJ 20180730
function ExConfigScreenAdapterFixedHeight:Shipei_SetMode(_mode)



	-- shi pei v2
	local conf = {
		width = 1136,
		height = 768,
		autoscale = "FIXED_WIDTH",
		callback = function(framesize)
			local ratio = framesize.width / framesize.height
			--print( string.format("~~~config.lua framesize: ", tostring(framesize.width), tostring(framesize.height)) )
			--print( "~~~config.lua ratio: " .. tostring(ratio) )
			if ratio <= 1.34 then
				-- iPad 768*1024(1536*2048) is 4:3 screen
				return {autoscale = "FIXED_HEIGHT"}
			elseif( ratio > 1.9 ) then
				-- quan mian ping
				return {autoscale = _mode}
			end
		end
	}
	display.setAutoScale(conf)
	--print(" ~~~~ shi pei v2  FIXED_WIDTH !")
end
function ExConfigScreenAdapterFixedHeight:Shipei_FixedHeight(_self)
	-- cc.Director:getInstance():setContentScaleFactor(1)
	self:Shipei_SetMode("FIXED_HEIGHT")
end
function ExConfigScreenAdapterFixedHeight:Shipei_FixedWidth(_self)
	-- cc.Director:getInstance():setContentScaleFactor(0.7)
	self:Shipei_SetMode("FIXED_WIDTH")
end

----------------------------------------------------------------------------------------
print( "###LUA Return ExConfigScreenAdapterFixedHeight.lua" )
return ExConfigScreenAdapterFixedHeight