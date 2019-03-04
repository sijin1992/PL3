
local MailDetailAttackType_ruins = class("MailDetailAttackType_ruins")

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
	end
	return richText
end
function MailDetailAttackType_ruins:initMailDetail(mail_info,data)
	-- 5/6
	if Tools.isEmpty(mail_info) or  Tools.isEmpty(mail_info.planet_report) then
		return
	end
	local info = mail_info.planet_report
	local totalNode = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/MailDetailAttackNode.csb")
	setScreenPosition(totalNode:getChildByName('closeNode'), "righttop")
	setScreenPosition(totalNode:getChildByName('Node'), "lefttop")

	totalNode:getChildByName('closeNode'):setSwallowTouches(true)
	totalNode:getChildByName('Node'):getChildByName('Image_light'):setSwallowTouches(true)
	totalNode:getChildByName('closeNode'):addClickEventListener(function()
		totalNode:removeFromParent()
		end)
	if Tools.isEmpty(info.my_data_list) and mail_info.planet_report.type == 5 then
		return
	end
	if Tools.isEmpty(info.enemy_data_list) and mail_info.planet_report.type == 6 then
		return
	end
	local str = ''
	local sizeH = 250
	totalNode:getChildByName('Node'):getChildByName('Text_1'):setVisible(false)
	local cfg_str = ''
	local str = ''
	if mail_info.planet_report.type == 6 then
		cfg_str = CONF:getStringValue('scout_mail')
	else
		cfg_str = CONF:getStringValue('destroy_mail')
		str = CONF.PLANET_RUINS.get(info.id).NAME
	end 
	local richText = create_MailRichText(info,cfg_str,str)
	richText:setAnchorPoint(cc.p(totalNode:getChildByName('Node'):getChildByName('Text_1'):getAnchorPoint()))
	richText:setPosition(totalNode:getChildByName('Node'):getChildByName('Text_1'):getPosition())

	totalNode:getChildByName('Node'):addChild(richText)
	local timeTab = os.date("*t", mail_info.stamp)
	if timeTab.day < 10 then timeTab.day = '0'..timeTab.day end
	if timeTab.month < 10 then timeTab.month = '0'..timeTab.month end
	if timeTab.hour < 10 then timeTab.hour = '0'..timeTab.hour end
	if timeTab.min < 10 then timeTab.min = '0'..timeTab.min end
	if timeTab.sec < 10 then timeTab.sec = '0'..timeTab.sec end
	totalNode:getChildByName('Node'):getChildByName('Text_2'):setString('('..info.pos_list[1].x..','..info.pos_list[1].y..')  '..timeTab.day..'/'..timeTab.month..'/'..timeTab.year..'  '..timeTab.hour..':'..timeTab.min..':'..timeTab.sec)
	totalNode:getChildByName('Node'):getChildByName('Button_pos'):setPosition(totalNode:getChildByName('Node'):getChildByName('Text_2'):getPosition())
	totalNode:getChildByName('Node'):getChildByName('Button_pos'):addClickEventListener(function()
		-- if data and data.from and data.from == 'Normal' then
		-- 	local event = cc.EventCustom:new("moveToUserRes")
		-- 	event.pos = info.pos_list[1]
		-- 	cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
		-- 	myApp:popView()
		-- else
			myApp:pushView('PlanetScene/PlanetScene',{move_info = {pos = {x=info.pos_list[1].x,y=info.pos_list[1].y},node_id_list = {getNodeIDByGlobalPos(info.pos_list[1])}} })
		-- end
		end)
	local node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/RuinsNode.csb')
	if Tools.isEmpty(mail_info.planet_report.video_key_list) then
		node:getChildByName('Button_1'):setVisible(false)
	end
	node:getChildByName('Button_1'):addClickEventListener(function()
		if Tools.isEmpty(mail_info.planet_report.video_key_list) == false then
			g_MailGuid_VideoPosition = mail_info.guid..'_1'
			local strData = Tools.encode("PvpVideoReq", {
				video_key = mail_info.planet_report.video_key_list[1],
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVP_VIDEO_REQ"),strData)
		end
		end)
	if info.isWin then
		node:getChildByName('Text_huode'):setString(CONF:getStringValue('Destroy success')) -- 胜利
		if mail_info.planet_report.type == 6 then
			node:getChildByName('Text_huode'):setString(CONF:getStringValue('scout_report')) -- 侦察报告
		end
		node:getChildByName('Text_huode'):setTextColor(cc.c4b(51,231,51,255))
		-- node:getChildByName('Text_huode'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
	else
		node:getChildByName('Text_huode'):setString(CONF:getStringValue('ruins_fail')) -- 失败
		node:getChildByName('Text_huode'):setTextColor(cc.c4b(233,50,59,255))
		-- node:getChildByName('Text_huode'):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
	end
	node:getChildByName('Text_1'):setString(CONF:getStringValue('Get resources'))
    node:getChildByName('Text_3'):setString(CONF:getStringValue('Team information'))
	node:getChildByName('ship_list'):setPositionX(node:getChildByName('Text_1'):getPositionX()+20+node:getChildByName('Text_1'):getContentSize().width)
	local list = require("util.ScrollViewDelegate"):create(node:getChildByName("ship_list"),cc.size(7,3), cc.size(90,90))
	node:getChildByName('ship_list'):setScrollBarEnabled(false)
	if mail_info.planet_report.type == 5 then
		node:getChildByName('ship_list'):setVisible(true)
		if Tools.isEmpty(mail_info.planet_report.item_list_list) == false then
			for k,item in ipairs(mail_info.planet_report.item_list_list[1].item_list) do
				if item.id ~= 0 then
					local itemNode = require("util.ItemNode"):create():init(item.id, item.num)
					list:addElement(itemNode)
				end
			end
		end
	end
	local item_count = node:getChildByName("ship_list"):getChildrenCount()
	local size_width = node:getChildByName("ship_list"):getContentSize().width
	local can_item_count = math.floor(size_width/90)
	if item_count <= can_item_count then
		node:getChildByName("ship_list"):setTouchEnabled(false)
	end
	-- 3001,4001,5001,6001
	if mail_info.planet_report.type == 6 then
		node:getChildByName('Text_1'):setString(CONF:getStringValue('get_resources'))
		node:getChildByName('ship_list'):setVisible(false)
		local resNode = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/ResNode.csb')
		resNode:setPosition(node:getChildByName('Text_1'):getPositionX()+node:getChildByName('Text_1'):getContentSize().width,node:getChildByName('Text_1'):getPositionY())
		for i=1,4 do
			resNode:getChildByName('Text_'..i):setString('0')
		end
		for k,item in ipairs(mail_info.planet_report.item_list_list[1].item_list) do
			if item.id == 3001 then
				resNode:getChildByName('Text_1'):setString(item.num)
			elseif item.id == 4001 then
				resNode:getChildByName('Text_2'):setString(item.num)
			elseif item.id == 5001 then
				resNode:getChildByName('Text_3'):setString(item.num)
			elseif item.id == 6001 then
				resNode:getChildByName('Text_4'):setString(item.num)
			end
		end
		node:addChild(resNode)
	end
	local shipInfo = {}
	if mail_info.planet_report.type == 5 then
		for k,ship in ipairs(info.my_data_list[1].ship_list) do
			if ship.id ~= 0 and info.my_data_list[1].ship_hp_list[ship.position] then
				local durable = Tools.getShipMaxDurable( ship )
				local maxHp = ship.attr[CONF.EShipAttr.kHP]
				local t = {ship.id,info.my_data_list[1].ship_hp_list[ship.position],ship.durable,durable,maxHp}
				shipInfo[#shipInfo + 1] = t
			end
		end
	elseif mail_info.planet_report.type == 6 then
		for k,ship in ipairs(info.enemy_data_list[1].ship_list) do
			if ship.id ~= 0 and info.enemy_data_list[1].ship_hp_list[ship.position] then
				local durable = Tools.getShipMaxDurable( ship )
				local maxHp = ship.attr[CONF.EShipAttr.kHP]
				local t = {ship.id,info.enemy_data_list[1].ship_hp_list[ship.position],ship.durable,durable,maxHp}
				shipInfo[#shipInfo + 1] = t
			end
		end
	end
	for i=0,5 do
		node:getChildByName('Image_17_'..i):setVisible(false)
		if Tools.isEmpty(shipInfo) == false then
			node:getChildByName('Image_17_0'):setVisible(true)
		end
	end
	for i=1,5 do
		node:getChildByName('node1'..i):setVisible(false)
	end
	node:getChildByName('Image_7'):setVisible(Tools.isEmpty(shipInfo) == false)
	node:getChildByName('Text_3'):setVisible(Tools.isEmpty(shipInfo) == false)
	local height = 50
	for o,p in ipairs(shipInfo) do
		if node:getChildByName('node1'..o) then
			node:getChildByName('node1'..o):setVisible(true)
			node:getChildByName('Image_17_'..o):setVisible(true)
			local cfg_ship = CONF.AIRSHIP.get(math.abs(tonumber(p[1])))
			local progress = require("util.ScaleProgressDelegate"):create(node:getChildByName('node1'..o):getChildByName('progress'), 235)
			local p1 =math.ceil(tonumber(p[2])/p[5]*1000)/10
			progress:setPercentage(p1)
			node:getChildByName('node1'..o):getChildByName('Text_xue'):setString(CONF:getStringValue('Attr_2'))
			node:getChildByName('node1'..o):getChildByName('Text'):setString(CONF:getStringValue('durable'))
			local desT = (math.ceil(p[3]/p[4]*1000)/10)
			if desT > 100 then desT = 100 end
			node:getChildByName('node1'..o):getChildByName('Text_num'):setString(desT..'%')
			node:getChildByName('node1'..o):getChildByName('Text_num'):setPositionY(node:getChildByName('node1'..o):getChildByName('Text'):getPositionY())
			node:getChildByName('node1'..o):getChildByName('Text_num'):setPositionX(node:getChildByName('node1'..o):getChildByName('Text'):getPositionX()+node:getChildByName('node1'..o):getChildByName('Text'):getContentSize().width + 5)
			if math.ceil(p[3]/p[4]*100) < 50 then
				node:getChildByName('node1'..o):getChildByName('Text_num'):setTextColor(cc.c4b(233,50,59,255))
				-- node:getChildByName('node1'..o):getChildByName('Text_num'):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
			else
				node:getChildByName('node1'..o):getChildByName('Text_num'):setTextColor(cc.c4b(51,231,51,255))
				-- node:getChildByName('node1'..o):getChildByName('Text_num'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
			end
			node:getChildByName('node1'..o):getChildByName('progress'):setPositionX(node:getChildByName('node1'..o):getChildByName('Text_xue'):getPositionX()+10+node:getChildByName('node1'..o):getChildByName('Text_xue'):getContentSize().width)
			node:getChildByName('node1'..o):getChildByName('jdt_bottom02_53'):setPositionX(node:getChildByName('node1'..o):getChildByName('Text_xue'):getPositionX()+10+node:getChildByName('node1'..o):getChildByName('Text_xue'):getContentSize().width)
			node:getChildByName('node1'..o):getChildByName('Text_nai'):setString(p1..'%')
			node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):loadTexture('RoleIcon/'..cfg_ship.ICON_ID..'.png')
			-- if cfg_ship.QUALITY == EDevelopStatus.kHas then
				node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('Image_1'):loadTexture("RankLayer/ui/ui_avatar_" .. cfg_ship.QUALITY .. ".png")
			-- else
				-- node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('Image_1'):loadTexture("RankLayer/ui/ui_avatar2_" .. cfg_ship.QUALITY .. ".png")
			-- end
			height = height + 90
		end
	end
	sizeH = sizeH + height
	local list = require("util.ScrollViewDelegate"):create(totalNode:getChildByName('Node'):getChildByName("ship_list"),cc.size(0,10), cc.size(820,sizeH))
	totalNode:getChildByName('Node'):getChildByName("ship_list"):setScrollBarEnabled(false)
	list:addElement(node)
	return totalNode
end

return MailDetailAttackType_ruins