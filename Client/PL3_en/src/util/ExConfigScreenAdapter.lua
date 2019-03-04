-- Coded by Wei Jingjun 20180619
print( "###LUA ExConfigScreenAdapter.lua" )
local ExConfigScreenAdapter = class("ExConfigScreenAdapter")

---------------------------------------------------------------------------------------

-- zhu cheng jian zhu cai dan
ExConfigScreenAdapter.BUTTON_ZHU_CHENG_BUILDING_MENU_OFFSET_X = 0
ExConfigScreenAdapter.BUTTON_ZHU_CHENG_BUILDING_MENU_OFFSET_Y = 195

-- jiayuan
ExConfigScreenAdapter.JIAYUAN_SCENE_ANCHOR_POINT_Y = 0.04
ExConfigScreenAdapter.JIAYUAN_PANEL_LEFT_TOP_ANCHOR_POINT_Y = 0.36
ExConfigScreenAdapter.JIAYUAN_BANNER_ANCHOR_POINT_Y = 0.55
ExConfigScreenAdapter.JIAYUAN_PANEL_SHUZI_ANCHOR_POINT_Y = 0.5
ExConfigScreenAdapter.JIAYUAN_QIU_ANCHOR_Y = 0.5
ExConfigScreenAdapter.JIAYUAN_NULI_ANCHOR_Y = 0.5
ExConfigScreenAdapter.JIAYUAN_PANEL_TOP_RIGHT_ANCHOR_POINT_Y = -0.85

-- yanfa
ExConfigScreenAdapter.YANFA_TYPE_SELECT_ANCHOR_X = -0.37
ExConfigScreenAdapter.YANFA_TYPE_SELECT_ANCHOR_Y = -2.05
ExConfigScreenAdapter.YANFA_BUTTON_OK_AP_X = 0.5
ExConfigScreenAdapter.YANFA_BUTTON_OK_AP_Y = 3.1
ExConfigScreenAdapter.YANFA_TEXT_TIME_NEED_AP_Y = 4.3

-- jiku
ExConfigScreenAdapter.JIKU_TEXT_AMOUNT_AP_X = -1
ExConfigScreenAdapter.JIKU_TEXT_AMOUNT_AP_Y = 0.5
ExConfigScreenAdapter.JIKU_BUTTON_TYPE_AP_X = 0.5
ExConfigScreenAdapter.JIKU_BUTTON_TYPE_AP_Y = 2.2

-- logo
ExConfigScreenAdapter.LOGO_SCENE_AP_Y = 0.12

-- denglu
ExConfigScreenAdapter.LOGIN_MAIN_SCENE_AP_Y = 0.12
ExConfigScreenAdapter.LOGIN_YONGHU_AP_X = 1
ExConfigScreenAdapter.LOGIN_YONGHU_AP_Y = 1
ExConfigScreenAdapter.LOGIN_GONGGAO_AP_X = 1
ExConfigScreenAdapter.LOGIN_GONGGAO_AP_Y = 1

-- battle win
ExConfigScreenAdapter.BATTLE_WIN_2_AP_X = 0.5
ExConfigScreenAdapter.BATTLE_WIN_2_AP_Y = 0.4
ExConfigScreenAdapter.BATTLE_WIN_2_BUTTON_END_AP_X = 0.5
ExConfigScreenAdapter.BATTLE_WIN_2_BUTTON_END_AP_Y = -1
ExConfigScreenAdapter.BATTLE_WIN_2_BUTTON_FIGHT_AP_X = 0.5
ExConfigScreenAdapter.BATTLE_WIN_2_BUTTON_FIGHT_AP_Y = -1


-- shengji
ExConfigScreenAdapter.JIANZHU_SHENGJI_IMAGE_AP_X = 0.5
ExConfigScreenAdapter.JIANZHU_SHENGJI_IMAGE_AP_Y = 0.5

-- renwu
ExConfigScreenAdapter.RENWU_AP_X = 0
ExConfigScreenAdapter.RENWU_AP_Y = -0.15


-- libao
ExConfigScreenAdapter.LIBAO_AP_X = 0.5
ExConfigScreenAdapter.LIBAO_AP_Y = 0


-- zonglan
ExConfigScreenAdapter.ZONGLAN_OFFSET_X = 60
ExConfigScreenAdapter.ZONGLAN_OFFSET_Y = -55
-- ExConfigScreenAdapter.BUTTON_ZONGLAN_AP_X = -2.5
-- ExConfigScreenAdapter.BUTTON_ZONGLAN_AP_Y = 0.5
ExConfigScreenAdapter.BUTTON_ZONGLAN_OFFSET_X = 70 
ExConfigScreenAdapter.BUTTON_ZONGLAN_OFFSET_Y = -40 - 103

-- select ship
ExConfigScreenAdapter.SELECT_SHIP_BUTTON_OK_AP_Y = 0



-- chou jiang
ExConfigScreenAdapter.CHOU_JIANG_AP_X = 0
ExConfigScreenAdapter.CHOU_JIANG_AP_Y = 0.1
ExConfigScreenAdapter.CHOU_JIANG_BUTTON_JIANG_CHI_AP_X = 0
ExConfigScreenAdapter.CHOU_JIANG_BUTTON_JIANG_CHI_AP_Y = 0.1
ExConfigScreenAdapter.CHOU_JIANG_WINDOW_JIANG_CHI_OFFSET_X = 0
ExConfigScreenAdapter.CHOU_JIANG_WINDOW_JIANG_CHI_OFFSET_Y = -12
ExConfigScreenAdapter.CHOU_JIANG_TOP_BANNER_OFFSET_X = 0
ExConfigScreenAdapter.CHOU_JIANG_TOP_BANNER_OFFSET_Y = -50


ExConfigScreenAdapter.ZHU_CHENG_BUILDING_MENU_NAMES = { 
"info"
,"node_arrows"
,"upgrade"
,"function"
}

-- Attribute
ExConfigScreenAdapter.ATTRIBUTE_AP_X = 0
ExConfigScreenAdapter.ATTRIBUTE_AP_Y = -23

-- Mail
ExConfigScreenAdapter.MAIL_NUM_X = 200
ExConfigScreenAdapter.MAIL_NUM_Y = 0

ExConfigScreenAdapter.MAIL_GET_X = 0
ExConfigScreenAdapter.MAIL_GET_Y = 100

-- Chat
ExConfigScreenAdapter.CHAT_AP_X = 0
ExConfigScreenAdapter.CHAT_AP_Y = 15

-- Slave
ExConfigScreenAdapter.NOSLAVE_GUIZE_X = -20
ExConfigScreenAdapter.NOSLAVE_MYSLAVE_Y = -30
ExConfigScreenAdapter.NOSLAVE_JIEJIU_Y = 30

---------------------------------------------------------------------------------------

function ExConfigScreenAdapter:DebugChilds(_node)
	
end

---------------------------------------------------------------------------------------

ExConfigScreenAdapter.SCREEN_FIX_W_H_RATE = 1.9

function ExConfigScreenAdapter:IsFixScreenEnabled_Base()
	local winSize = cc.Director:getInstance():getWinSize()
	--print( string.format("~~~ winSize w: %s h: %s", tostring(winSize.width), tostring(winSize.height)) )
	local _rate = winSize.width / winSize.height
	--print( string.format("~~~ _rate: %s SCREEN_FIX_W_H_RATE: %s", tostring(_rate), tostring(self.SCREEN_FIX_W_H_RATE)) )
	if (_rate > self.SCREEN_FIX_W_H_RATE) then
		return true
	end
	return false
end

function ExConfigScreenAdapter:IsFixScreenEnabled()
	do return false end
	-- DISABLE ALL 20180726

	return self:IsFixScreenEnabled_Base()
end

function ExConfigScreenAdapter:SetPosXY_Offset(_node, _x, _y)
	local old_pos_x = _node:getPositionX()
	local new_pos_x = old_pos_x + _x
	_node:setPositionX(new_pos_x)

	local old_pos_y = _node:getPositionY()
	local new_pos_y = old_pos_y + _y
	_node:setPositionY(new_pos_y)
end

function ExConfigScreenAdapter:SetListPosXY_Offset(_parent, _list, _x, _y)
	for k,v in pairs(_list) do
		--print(string.format("~~~ SetListPosXY_Offset : %s ", v))
		local child = _parent:getChildByName(v)
		self:SetPosXY_Offset(child, _x, _y)
	end
end

----------------------------------------------------------------------------------------

function ExConfigScreenAdapter:onFixQuanmianping_Zhucheng_BuildingMenu(_self ,_name,_infoNode_last)
	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	if(_infoNode_last == nil) then
		return
	end

	if(_name == nil) then
		return
	elseif( (_name ~= "building_16") and (_name ~= "building_5") ) then
		return
	end

	_cfg:SetListPosXY_Offset(_infoNode_last, _cfg.ZHU_CHENG_BUILDING_MENU_NAMES, _cfg.BUTTON_ZHU_CHENG_BUILDING_MENU_OFFSET_X, _cfg.BUTTON_ZHU_CHENG_BUILDING_MENU_OFFSET_Y)
end

function ExConfigScreenAdapter:onFixQuanmianping_Zhucheng_Ui(_self)
	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()
	local btn_zonglan = rn:getChildByName("totalNode")
	self:SetPosXY_Offset(btn_zonglan, _cfg.BUTTON_ZONGLAN_OFFSET_X, _cfg.BUTTON_ZONGLAN_OFFSET_Y)

	-- btn_zonglan:setAnchorPoint(_cfg.BUTTON_ZONGLAN_AP_X, _cfg.BUTTON_ZONGLAN_AP_Y)
	-- setScreenPosition( btn_zonglan, "leftbottom")
end

function ExConfigScreenAdapter:onFixQuanmianping_Zonglan(_self)
		-- do return end

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()
	self:SetPosXY_Offset(rn, _cfg.ZONGLAN_OFFSET_X, _cfg.ZONGLAN_OFFSET_Y)

	-- rn:setAnchorPoint(_cfg.ZONGLAN_AP_X, _cfg.ZONGLAN_AP_Y)
	-- setScreenPosition( rn, "lefttop")
end


function ExConfigScreenAdapter:onFixQuanmianping_Battle(_self)
	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end
	local rn = _self:getResourceNode()
	for i=1,9 do
		rn:getChildByName("object_layer"):getChildByName("ship_2_"..i):setPositionY(rn:getChildByName("object_layer"):getChildByName("ship_2_"..i):getPositionY()-50)
		rn:getChildByName("object_layer"):getChildByName("ship_1_"..i):setPositionY(rn:getChildByName("object_layer"):getChildByName("ship_1_"..i):getPositionY()+50)
	end
	
end


-- self = itemNode
function ExConfigScreenAdapter:onFixQuanmianping_JiangChi(_self)
	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end 
	local rn = _self:getResourceNode()

	self:SetPosXY_Offset(rn, _cfg.CHOU_JIANG_WINDOW_JIANG_CHI_OFFSET_X, _cfg.CHOU_JIANG_WINDOW_JIANG_CHI_OFFSET_Y)

end



function ExConfigScreenAdapter:onFixQuanmianping_Choujiang(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end 

	local rn = _self:getResourceNode()
	local btn_show = rn:getChildByName("btn_show")

	btn_show:setAnchorPoint(_cfg.CHOU_JIANG_BUTTON_JIANG_CHI_AP_X, _cfg.CHOU_JIANG_BUTTON_JIANG_CHI_AP_Y)
	rn:setAnchorPoint(_cfg.CHOU_JIANG_AP_X, _cfg.CHOU_JIANG_AP_Y)

	setScreenPosition( rn, "bottom")
	setScreenPosition( btn_show, "lefttop")

	--print("~~~ ExConfigScreenAdapter 200")

	-- self:SetListPosXY_Offset(rn, self.CHOU_JIANG_TOP_BANNER_NAMES, self.CHOU_JIANG_TOP_BANNER_OFFSET_X, self.CHOU_JIANG_TOP_BANNER_OFFSET_Y)

	local top_panel = rn:getChildByName("SHIPEI_TOP_BANNER")
	self:SetPosXY_Offset(top_panel, self.CHOU_JIANG_TOP_BANNER_OFFSET_X, self.CHOU_JIANG_TOP_BANNER_OFFSET_Y)

	--print("~~~ ExConfigScreenAdapter 205")
end

function ExConfigScreenAdapter:onFixQuanmianping_Libao(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end 

	local rn = _self:getResourceNode()
	rn:getChildByName("FileNode_1"):setScale(0.8)
end


function ExConfigScreenAdapter:onFixQuanmianping_Renwu(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()

	rn:setAnchorPoint(_cfg.RENWU_AP_X, _cfg.RENWU_AP_Y)
	setScreenPosition( rn, "top")
end

function ExConfigScreenAdapter:onFixQuanmianping_Jianzhu_Shengji(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()
	local building = rn:getChildByName("building")

	building:setAnchorPoint(_cfg.JIANZHU_SHENGJI_IMAGE_AP_X, _cfg.JIANZHU_SHENGJI_IMAGE_AP_Y)
	setScreenPosition( building, "bottom")
end

function ExConfigScreenAdapter:onFixWinLayer2(_layer)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		-- do not forget  _layer
		return _layer
	end

	local end_btn = _layer:getChildByName("end")
	local fight_btn = _layer:getChildByName("fight")

	fight_btn:setAnchorPoint(_cfg.BATTLE_WIN_2_BUTTON_FIGHT_AP_X, _cfg.BATTLE_WIN_2_BUTTON_FIGHT_AP_Y)
	end_btn:setAnchorPoint(_cfg.BATTLE_WIN_2_BUTTON_END_AP_X, _cfg.BATTLE_WIN_2_BUTTON_END_AP_Y)
	_layer:setAnchorPoint(_cfg.BATTLE_WIN_2_AP_X, _cfg.BATTLE_WIN_2_AP_Y)

	setScreenPosition( _layer, "top")
	setScreenPosition( fight_btn, "top")
	setScreenPosition( end_btn, "top")

	return _layer
end

function ExConfigScreenAdapter:onFixQuanmianping_LoginMainScene(_self)
	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()
	local yonghu = rn:getChildByName("gate_1")
	local gonggao = rn:getChildByName("notive")
	
	rn:setAnchorPoint(0, _cfg.LOGIN_MAIN_SCENE_AP_Y)
	yonghu:setAnchorPoint(_cfg.LOGIN_YONGHU_AP_X, _cfg.LOGIN_YONGHU_AP_Y)
	gonggao:setAnchorPoint(_cfg.LOGIN_GONGGAO_AP_X, _cfg.LOGIN_GONGGAO_AP_Y)


	setScreenPosition( rn, "bottom")
	setScreenPosition( yonghu, "righttop")
	setScreenPosition( gonggao, "righttop")

end

function ExConfigScreenAdapter:onFixQuanmianping_SelectShipScene(_self)
	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()
	local ok_btn = rn:getChildByName("btn")

	ok_btn:setAnchorPoint(0, _cfg.SELECT_SHIP_BUTTON_OK_AP_Y)
	setScreenPosition( ok_btn, "bottom")
end

function ExConfigScreenAdapter:onFixQuanmianping_Logo(_self)
	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()

	rn:setAnchorPoint(0, _cfg.LOGO_SCENE_AP_Y)
	setScreenPosition( rn, "bottom")
end

function ExConfigScreenAdapter:onFixQuanmianping_Jiku(_self)
	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()
	-- node_list ship_num
	local node_list = rn:getChildByName("node_list")
	local ship_num = node_list:getChildByName("ship_num")
	-- all_btn
	local all_btn = rn:getChildByName("all_btn")

	ship_num:setAnchorPoint(_cfg.JIKU_TEXT_AMOUNT_AP_X, _cfg.JIKU_TEXT_AMOUNT_AP_Y)
	all_btn:setAnchorPoint(_cfg.JIKU_BUTTON_TYPE_AP_X, _cfg.JIKU_BUTTON_TYPE_AP_Y)
	setScreenPosition( ship_num, "left")
	setScreenPosition( all_btn, "leftbottom")
	-- node_list:setPositionY(node_list:getPositionY()-50)
	node_list:getChildByName("list"):setContentSize(node_list:getChildByName("list"):getContentSize().width,node_list:getChildByName("list"):getContentSize().height-50)
	node_list:getChildByName("Image_83"):setContentSize(node_list:getChildByName("Image_83"):getContentSize().width,node_list:getChildByName("Image_83"):getContentSize().height-42)
	-- rn:getChildByName("info"):setPositionY(rn:getChildByName("info"):getPositionY()-50)
end

function ExConfigScreenAdapter:onFixQuanmianping_Yanfa(_self)
	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()
	local panel_right = rn:getChildByName("right")
	local panel_right_node1 = panel_right:getChildByName("node1")

	local all_btn = rn:getChildByName("btn_all")
-- need_time
	local text_need_time = panel_right_node1:getChildByName("need_time")
-- btn
	local btn_yanfa = panel_right:getChildByName("btn")

	all_btn:setAnchorPoint(_cfg.YANFA_TYPE_SELECT_ANCHOR_X, _cfg.YANFA_TYPE_SELECT_ANCHOR_Y)
	btn_yanfa:setAnchorPoint(_cfg.YANFA_BUTTON_OK_AP_X, _cfg.YANFA_BUTTON_OK_AP_Y)
	text_need_time:setAnchorPoint(0, _cfg.YANFA_TEXT_TIME_NEED_AP_Y)

	setScreenPosition( all_btn, "lefttop")
	setScreenPosition( btn_yanfa, "rightbottom")
	setScreenPosition( text_need_time, "bottom")
end

function ExConfigScreenAdapter:onFixQuanmianping_Jiayuan(_self)
	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	-- fix pos on quan mian ping 
	-- WJJ 20180719
	local rn = _self:getResourceNode()

	--[[
	local _rn_oigin_y = rn:getPositionY()
	local _rn_fixed_y = rn:getPositionY()
	local _rn_offset_y = _rn_fixed_y - _rn_oigin_y
	--]]

	local p3 = rn:getChildByName("Panel_3")
	local p2 = rn:getChildByName("Panel_2")
	local p1 = rn:getChildByName("Panel_1")
	local qiu = rn:getChildByName("qiu")
	local top_banner = rn:getChildByName("right_bottom_60")
	local btn_slave = rn:getChildByName("btn_slave")
    local slave_text_bg = rn:getChildByName("world_select_bottom_19")
    local slave_text = rn:getChildByName("slave_text")
    p1:setPosition(p1:getPosition().x,p1:getPosition().y)
	rn:setAnchorPoint(0, _cfg.JIAYUAN_SCENE_ANCHOR_POINT_Y)
	top_banner:setAnchorPoint(0, _cfg.JIAYUAN_BANNER_ANCHOR_POINT_Y)
	p3:setAnchorPoint(0, _cfg.JIAYUAN_PANEL_SHUZI_ANCHOR_POINT_Y)
	p2:setAnchorPoint(0, _cfg.JIAYUAN_PANEL_TOP_RIGHT_ANCHOR_POINT_Y)
--	local panel_1_fix_anchorPoint = _cfg.JIAYUAN_PANEL_LEFT_TOP_ANCHOR_POINT_Y
--	p1:setAnchorPoint(0, panel_1_fix_anchorPoint)
--	qiu:setAnchorPoint(0, _cfg.JIAYUAN_QIU_ANCHOR_Y)
--	btn_slave:setAnchorPoint(0, _cfg.JIAYUAN_NULI_ANCHOR_Y)

	--print(string.format("~~~ p1 pos: %s, %s", tostring(p1:getPositionX()), tostring(p1:getPositionY())))

	-- p1:setPositionY(0)

	setScreenPosition( rn, "bottom")
	setScreenPosition( top_banner, "top")
	setScreenPosition( qiu, "top")
	setScreenPosition( p1, "lefttop")
	setScreenPosition( p2, "righttop")
	setScreenPosition( p3, "leftbottom")
	setScreenPosition( btn_slave, "top")
    setScreenPosition( slave_text_bg, "top")
    setScreenPosition( slave_text, "top")


	-- print(string.format("~~~  _rn_offset_y: %s", tostring(_rn_offset_y) ) )
	-- p1:setPositionY(p1:getPositionY() + _rn_offset_y)
	-- p1:setGlobalZOrder(9999)

end

function ExConfigScreenAdapter:onFixQuanmianping_Attribute(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()
	self:SetPosXY_Offset(rn, _cfg.ATTRIBUTE_AP_X, _cfg.ATTRIBUTE_AP_Y)

end

function ExConfigScreenAdapter:onFixQuanmianping_Mail(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()
	local mailNum = rn:getChildByName("mailNum")
    local textMailNum = rn:getChildByName("textMailNum")
    local sumMail = rn:getChildByName("sumMail")

    self:SetPosXY_Offset(mailNum, _cfg.MAIL_NUM_X, _cfg.MAIL_NUM_Y)
    self:SetPosXY_Offset(textMailNum, _cfg.MAIL_NUM_X, _cfg.MAIL_NUM_Y)
    self:SetPosXY_Offset(sumMail, _cfg.MAIL_NUM_X, _cfg.MAIL_NUM_Y)
end

function ExConfigScreenAdapter:onFixQuanmianping_MailGET(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end
    -- ¡Ï»°∞¥≈•
    local btnGet = _self:getChildByName('btnGet')
    if btnGet ~= nil and btnGet:isVisible() then
        self:SetPosXY_Offset(btnGet, _cfg.MAIL_GET_X, _cfg.MAIL_GET_Y)
    end
end

function ExConfigScreenAdapter:onFixQuanmianping_Chat(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

	local rn = _self:getResourceNode()
    local send = rn:getChildByName("send")
    local text_back = rn:getChildByName("text_back")
    local send_text = rn:getChildByName("send_text")
    self:SetPosXY_Offset(send, _cfg.CHAT_AP_X, _cfg.CHAT_AP_Y)
    self:SetPosXY_Offset(text_back, _cfg.CHAT_AP_X, _cfg.CHAT_AP_Y)
    self:SetPosXY_Offset(send_text, _cfg.CHAT_AP_X, _cfg.CHAT_AP_Y)
end

function ExConfigScreenAdapter:SlaveCommon(rn,index)

    local prompt_bottom_15 = rn:getChildByName("prompt_bottom_15")
    local my_slave = rn:getChildByName("my_slave")
    local my_slave_ins = rn:getChildByName("my_slave_ins")

    local chat_bottom = rn:getChildByName("chat_bottom")
    local btn_chat = rn:getChildByName("btn_chat")
    local di_text = rn:getChildByName("di_text")

    local myslaveY = self.NOSLAVE_MYSLAVE_Y
    local chatY = self.NOSLAVE_JIEJIU_Y
    if index == 2 then
        myslaveY = myslaveY - 30
        chatY = chatY + 35
    end
    self:SetPosXY_Offset(prompt_bottom_15, 0, myslaveY)
    self:SetPosXY_Offset(my_slave, 0, myslaveY)
    self:SetPosXY_Offset(my_slave_ins, 0, myslaveY)

    self:SetPosXY_Offset(chat_bottom, 0, chatY)
    self:SetPosXY_Offset(btn_chat, 0, chatY)
    self:SetPosXY_Offset(di_text, 0, chatY)
end

function ExConfigScreenAdapter:onFixQuanmianping_NoSlave(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

    local rn = _self:getResourceNode()
    self:SlaveCommon(rn,1)

    local guize = rn:getChildByName("guize")
    local jiejiu = rn:getChildByName("jiejiu")
    local jilu = rn:getChildByName("jilu")

    self:SetPosXY_Offset(guize, _cfg.NOSLAVE_GUIZE_X, 0)
    self:SetPosXY_Offset(jiejiu, 0, _cfg.NOSLAVE_JIEJIU_Y)
    self:SetPosXY_Offset(jilu, 0, _cfg.NOSLAVE_JIEJIU_Y)
end

function ExConfigScreenAdapter:onFixQuanmianping_EnemySlave(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

    local rn = _self:getResourceNode()
    self:SlaveCommon(rn,2)

    local shuaxin_di = rn:getChildByName("shuaxin_di")
    local jjc_sx_120 = rn:getChildByName("jjc_sx_120")
    local shuaxin_text = rn:getChildByName("shuaxin_text")
    local shuaxin = rn:getChildByName("shuaxin")

    local jiejiu = _cfg.NOSLAVE_JIEJIU_Y + 30
    self:SetPosXY_Offset(shuaxin_di, 0, jiejiu)
    self:SetPosXY_Offset(jjc_sx_120, 0, jiejiu)
    self:SetPosXY_Offset(shuaxin_text, 0, jiejiu)
    self:SetPosXY_Offset(shuaxin, 0, jiejiu)

    local zhua_di = rn:getChildByName("zhua_di")
    local icon_dbzd_118 = rn:getChildByName("icon_dbzd_118") 
    local zhua_text = rn:getChildByName("zhua_text")
    local zhua = rn:getChildByName("zhua")

    self:SetPosXY_Offset(zhua_di, 0, jiejiu)
    self:SetPosXY_Offset(icon_dbzd_118, 0, jiejiu)
    self:SetPosXY_Offset(zhua_text, 0, jiejiu)
    self:SetPosXY_Offset(zhua, 0, jiejiu)
end

function ExConfigScreenAdapter:onFixQuanmianping_SaveFriend(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

    local rn = _self:getResourceNode()
    self:SlaveCommon(rn,2)

    local shuaxin_di = rn:getChildByName("shuaxin_di")
    local jjc_sx_120 = rn:getChildByName("jjc_sx_120")
    local shuaxin_text = rn:getChildByName("shuaxin_text")
    local shuaxin = rn:getChildByName("shuaxin")

    local jiejiu = _cfg.NOSLAVE_JIEJIU_Y + 30
    self:SetPosXY_Offset(shuaxin_di, 0, jiejiu)
    self:SetPosXY_Offset(jjc_sx_120, 0, jiejiu)
    self:SetPosXY_Offset(shuaxin_text, 0, jiejiu)
    self:SetPosXY_Offset(shuaxin, 0, jiejiu)
end

function ExConfigScreenAdapter:onFixQuanmianping_SlaveLayer(_self)

	local _cfg = require("util.ExConfigScreenAdapter"):getInstance()
	if( _cfg:IsFixScreenEnabled() == false )then
		return
	end

    local rn = _self:getResourceNode()
    self:SlaveCommon(rn,2)

    local guize = rn:getChildByName("guize")
    self:SetPosXY_Offset(guize, _cfg.NOSLAVE_GUIZE_X, 0)

    local shuaxin_di = rn:getChildByName("shuaxin_di")
    local jjc_sx_120 = rn:getChildByName("jjc_sx_120")
    local shuaxin_text = rn:getChildByName("shuaxin_text")
    local shuaxin = rn:getChildByName("shuaxin")

    local jiejiu = _cfg.NOSLAVE_JIEJIU_Y + 30
    self:SetPosXY_Offset(shuaxin_di, 0, jiejiu)
    self:SetPosXY_Offset(jjc_sx_120, 0, jiejiu)
    self:SetPosXY_Offset(shuaxin_text, 0, jiejiu)
    self:SetPosXY_Offset(shuaxin, 0, jiejiu)

    local duo_di = rn:getChildByName("duo_di")
    local icon_dbzd_118 = rn:getChildByName("icon_dbzd_118") 
    local duo_text = rn:getChildByName("duo_text")
    local duo = rn:getChildByName("duo")

    self:SetPosXY_Offset(duo_di, 0, jiejiu)
    self:SetPosXY_Offset(icon_dbzd_118, 0, jiejiu)
    self:SetPosXY_Offset(duo_text, 0, jiejiu)
    self:SetPosXY_Offset(duo, 0, jiejiu)

    local find_di = rn:getChildByName("find_di")
    if find_di ~= nil and find_di:isVisible() then
        local search_dark_119 = rn:getChildByName("search_dark_119") 
        local find_text = rn:getChildByName("find_text")
        local find = rn:getChildByName("find")

        self:SetPosXY_Offset(find_di, 0, jiejiu)
        self:SetPosXY_Offset(search_dark_119, 0, jiejiu)
        self:SetPosXY_Offset(find_text, 0, jiejiu)
        self:SetPosXY_Offset(find, 0, jiejiu)
    end
end

function ExConfigScreenAdapter:getInstance()
	--print( "###LUA ExConfigScreenAdapter.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end

function ExConfigScreenAdapter:onCreate(  )
	--print( "###LUA ExConfigScreenAdapter.lua onCreate" )


	return self
end

--print( "###LUA Return ExConfigScreenAdapter.lua" )
return ExConfigScreenAdapter