local MailDetailAttackType_bossFail = class("MailDetailAttackType_bossFail")

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local EDevelopStatus = require("app.views.ShipDevelopScene.DevelopStatus")

local Tips = require("util.TipsMessage"):getInstance()

local myApp = require("app.MyApp"):getInstance()

local teamName = {
	[1] = 'Team a',
	[2] = 'Team b',
	[3] = 'Team c',
	[4] = 'Team d',
	[5] = 'Team e',
}

local create_MailRichText = function(str1,str2)
	local richText = ccui.RichText:create()
	str1 = str1..':'
	local label1 = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, str1, s_default_font, 25, 2 ) 
	richText:pushBackElement(label1)
	local label2 = ccui.RichElementText:create( 1, cc.c3b(233,50,59), 255, str2, s_default_font, 25, 2 ) 
	richText:pushBackElement(label2)
	return richText
end

function MailDetailAttackType_bossFail:initMailDetail(mail_info,data)
	if Tools.isEmpty(mail_info) or  Tools.isEmpty(mail_info.planet_report) then
		return
	end
	if not (mail_info.planet_report.type == 14 and mail_info.planet_report.result == false)  then
		return
	end
	local info = mail_info.planet_report
	local node = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/MailDetailBossFailNode.csb")

	setScreenPosition(node:getChildByName('closeNode'), "righttop")
	setScreenPosition(node:getChildByName('Node'), "lefttop")

	node:getChildByName('closeNode'):setSwallowTouches(true)
	node:getChildByName('Node'):getChildByName('Image_light'):setSwallowTouches(true)
	node:getChildByName('closeNode'):addClickEventListener(function()
		node:removeFromParent()
		end)
	node:getChildByName('Node'):getChildByName('Button_pos'):setPosition(node:getChildByName('Node'):getChildByName('Text_2'):getPosition())
	node:getChildByName('Node'):getChildByName('Button_pos'):addClickEventListener(function()
			myApp:pushView('PlanetScene/PlanetScene',{move_info = {pos = {x=info.pos_list[1].x,y=info.pos_list[1].y},node_id_list = {getNodeIDByGlobalPos(info.pos_list[1])}} })
		end)
	node:getChildByName('Node'):getChildByName('Text_1'):setString(CONF:getStringValue('base_scout'))
	node:getChildByName('Node'):getChildByName('Text_3'):setString(CONF:getStringValue('scout'))

	local cfg = CONF.PLANETBOSS.get(mail_info.planet_report.id)
	local str1 = CONF:getStringValue('attack ai base')
	local str2 = 'Lv.'..cfg.LV .. CONF:getStringValue(cfg.NAME)
	local richText = create_MailRichText(str1,str2)
	richText:setAnchorPoint(cc.p(node:getChildByName('Node'):getChildByName('Text_1'):getAnchorPoint()))
	richText:setPosition(node:getChildByName('Node'):getChildByName('Text_1'):getPosition())
	richText:setName('richText')
	node:getChildByName('Node'):addChild(richText)
	node:getChildByName('Node'):getChildByName('Text_1'):setVisible(false)
	node:getChildByName('Node'):getChildByName('Text_4'):setString(CONF:getStringValue('base mail'))

	local timeTab = os.date("*t", mail_info.stamp)
	if timeTab.day < 10 then timeTab.day = '0'..timeTab.day end
	if timeTab.month < 10 then timeTab.month = '0'..timeTab.month end
	if timeTab.hour < 10 then timeTab.hour = '0'..timeTab.hour end
	if timeTab.min < 10 then timeTab.min = '0'..timeTab.min end
	if timeTab.sec < 10 then timeTab.sec = '0'..timeTab.sec end
	node:getChildByName('Node'):getChildByName('Text_2'):setString('('..info.pos_list[1].x..','..info.pos_list[1].y..')  '..timeTab.day..'/'..timeTab.month..'/'..timeTab.year..'  '..timeTab.hour..':'..timeTab.min..':'..timeTab.sec)
	local posX = node:getChildByName('Node'):getChildByName('icon'):getPositionX()
	local conW = node:getChildByName('Node'):getChildByName('icon'):getContentSize().width
	local nodeW = node:getChildByName('Node'):getChildByName('icon'):getContentSize().width
	node:getChildByName('Node'):getChildByName('Text_2'):setPositionX( posX+conW+nodeW+17 )
	node:getChildByName('Node'):getChildByName('Image_icon'):getChildByName('icon'):loadTexture("HeroImage/"..info.enemy_data_list[1].info.icon_id..".png")
	return node
end

return MailDetailAttackType_bossFail