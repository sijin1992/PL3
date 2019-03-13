local MailDetailAttackType_fail = class("MailDetailAttackType_fail")

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

local create_MailRichText = function(info,cfg_str,str)
	local richText = ccui.RichText:create()
	local s,e = string.find(cfg_str,'#1#')
	local s2,e2 = string.find(cfg_str,'#2#')
	local insert1 = function()
		if s and e then
			local start = 1
			if s2 and e2 and s2 < s then
				start = e2 + 1
			end
			local str1 = string.sub(cfg_str, start, s-1)..str
			local label1 = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, str1, s_default_font, 25, 2 ) 
			richText:pushBackElement(label1)
			if s2 and e2 and s2 < s then
				local str5 = string.sub(cfg_str,e+1,#cfg_str)
				local label5 = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, str5, s_default_font, 25, 2 ) 
				richText:pushBackElement(label5)
			end
		end
	end
	local insert2 = function()
		if s2 and e2 then
			if not e then e = 0 end
			local start = e + 1
			if s and e and s2 < s then
				start = 1
			end
			local str2 = string.sub(cfg_str,start,s2-1)
			local label2 = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, str2, s_default_font, 25, 2 ) 
			richText:pushBackElement(label2)
			if Tools.isEmpty(info.enemy_data_list) == false then
				local str3 = info.enemy_data_list[1].info.nickname
				local label3 = ccui.RichElementText:create( 1, cc.c3b(224, 31, 31), 255, str3, s_default_font, 25, 2 )
				richText:pushBackElement(label3)
			end
			if s and e and s2 < s then

			else
				local str4 = string.sub(cfg_str,e2+1,#cfg_str)
				local label4 = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, str4, s_default_font, 25, 2 )
				richText:pushBackElement(label4)
			end
		end
	end
	if s and e and s2 and e2 then
		if s < s2 then
			insert1()
			insert2()
		else
			insert2()
			insert1()
		end
	elseif s and e and not s2 and not e2 then
		insert1()
	elseif not s and not e and s2 and e2 then
		insert2()
	else
		local label5 = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, cfg_str..':'..str, s_default_font, 25, 2 )
		richText:pushBackElement(label5)
	end
	return richText
end

function MailDetailAttackType_fail:initMailDetail(mail_info,data)
	if Tools.isEmpty(mail_info) or  Tools.isEmpty(mail_info.planet_report) then
		return
	end
	if mail_info.planet_report.type ~= 16 and mail_info.planet_report.type ~= 17 then
		return
	end 
	local info = mail_info.planet_report
	local node = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/MailAttackFailNode.csb")
	local totalNode = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/MailDetailAttackNode.csb")
	setScreenPosition(node:getChildByName('closeNode'), "righttop")
	setScreenPosition(node:getChildByName('Node'), "lefttop")
	local str = ''
	local cfg_str = ''
	if mail_info.planet_report.type == 16 then
		cfg_str = CONF:getStringValue('collect_mail_2')
		str = CONF:getStringValue('city')
	elseif mail_info.planet_report.type == 17 then
		cfg_str = CONF:getStringValue('judian_mail')
		str = CONF:getStringValue(cfg_city.NAME)
	end

	local richText = create_MailRichText(info,cfg_str,str)
	richText:setAnchorPoint(cc.p(totalNode:getChildByName('Node'):getChildByName('Text_1'):getAnchorPoint()))
	richText:setPosition(totalNode:getChildByName('Node'):getChildByName('Text_1'):getPosition())
	
	totalNode:getChildByName('Node'):addChild(richText)

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
	if mail_info.planet_report.type == 16 then
		node:getChildByName('Node'):getChildByName('Text_6'):setString(CONF:getStringValue('base text'))
	elseif mail_info.planet_report.type == 17 then
		node:getChildByName('Node'):getChildByName('Text_6'):setString(CONF:getStringValue('judian text'))
	end
	local timeTab = os.date("*t", mail_info.stamp)
	if timeTab.day < 10 then timeTab.day = '0'..timeTab.day end
	if timeTab.month < 10 then timeTab.month = '0'..timeTab.month end
	if timeTab.hour < 10 then timeTab.hour = '0'..timeTab.hour end
	if timeTab.min < 10 then timeTab.min = '0'..timeTab.min end
	if timeTab.sec < 10 then timeTab.sec = '0'..timeTab.sec end
	node:getChildByName('Node'):getChildByName('Text_2'):setString('('..info.enemy_data_list[1].pos_list[1].x..','..info.enemy_data_list[1].pos_list[1].y..')  '..timeTab.day..'/'..timeTab.month..'/'..timeTab.year..'  '..timeTab.hour..':'..timeTab.min..':'..timeTab.sec)
	local posX = node:getChildByName('Node'):getChildByName('icon'):getPositionX()
	local nodeW = node:getChildByName('Node'):getChildByName('icon'):getContentSize().width
	node:getChildByName('Node'):getChildByName('Text_2'):setPositionX( posX+nodeW+17 )
	node:getChildByName('Node'):getChildByName('Image_icon'):getChildByName('icon'):loadTexture("HeroImage/"..info.enemy_data_list[1].info.icon_id..".png")
	node:getChildByName('Node'):getChildByName('Text_4'):setString(info.enemy_data_list[1].info.nickname)
	return node
end

return MailDetailAttackType_fail