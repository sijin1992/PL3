local MailDetailAttackType_boss = class("MailDetailAttackType_boss")

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

function MailDetailAttackType_boss:initMailDetail(mail_info,data)
	-- 2,3,8,9,10,11
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
	if Tools.isEmpty(info.my_data_list) then
		print('~~~~~~my_data_list is empty~~~~~~')
		return
	end
	local sizeH = 550
	totalNode:getChildByName('Node'):getChildByName('Text_1'):setVisible(false)
	local str1 = ''
	local str2 = ''
	
	-- CONF:getStringValue(CONF.PLANET_RUINS.get(info.id).NAME
	local cfg_boss = CONF.PLANETBOSS.get(mail_info.planet_report.id)
	local str1 = CONF:getStringValue('attack ai base')
	local str2 = 'Lv.'..cfg_boss.LV..' '.. CONF:getStringValue(cfg_boss.NAME)
	local richText = create_MailRichText(str1,str2)
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
			myApp:pushView('PlanetScene/PlanetScene',{move_info = {pos = {x=info.pos_list[1].x,y=info.pos_list[1].y},node_id_list = {getNodeIDByGlobalPos(info.pos_list[1])}} })
		end)
	local node2 = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/DetailAttackSmallNode/BossNode.csb")
	node2:setName('node2')
	if Tools.isEmpty(mail_info.planet_report.video_key_list) then
		node2:getChildByName('Button_1'):setVisible(false)
	end
	local result = false
	if Tools.isEmpty(mail_info.planet_report.my_data_list) == false and Tools.isEmpty(mail_info.planet_report.enemy_data_list) == false then
		local can = false
		for k,v in ipairs(mail_info.planet_report.enemy_data_list) do
			if Tools.isEmpty(v.ship_list) == false then
				for k,ship in ipairs(v.ship_list) do
					if ship.id ~= 0 then
						can = true
						break
					end
				end
			end
		end
		if can then
			for k,v in ipairs(mail_info.planet_report.my_data_list) do
				if Tools.isEmpty(v.ship_list) == false then
					for k,ship in ipairs(v.ship_list) do
						if ship.id ~= 0 then
							result = true
							break
						end
					end
				end
			end
		end
	end
	node2:getChildByName('Button_1'):setVisible(result)
	node2:getChildByName('Button_1'):addClickEventListener(function()
		if Tools.isEmpty(mail_info.planet_report.video_key_list) == false then
			g_MailGuid_VideoPosition = mail_info.guid..'_1'
			local strData = Tools.encode("PvpVideoReq", {
				video_key = mail_info.planet_report.video_key_list[1],
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVP_VIDEO_REQ"),strData)
		end
		end)

	if info.result then
		node2:getChildByName('Text_huode'):setString(CONF:getStringValue('win')) -- 胜利
		node2:getChildByName('Text_huode'):setTextColor(cc.c4b(51,231,51,255))
		-- node2:getChildByName('Text_huode'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
	else
		node2:getChildByName('Text_huode'):setString(CONF:getStringValue('failed')) -- 失败
		node2:getChildByName('Text_huode'):setTextColor(cc.c4b(233,50,59,255))
		-- node2:getChildByName('Text_huode'):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
	end
	node2:getChildByName('Text_1'):setString(CONF:getStringValue('gain_award'))
	local list1 = require("util.ScrollViewDelegate"):create(node2:getChildByName("ship_list"),cc.size(0,10), cc.size(100,100))
	node2:getChildByName('ship_list'):setScrollBarEnabled(false)
	if Tools.isEmpty(mail_info.planet_report.item_list_list) == false then
		for k,item in ipairs(mail_info.planet_report.item_list_list[1].item_list) do
			if item.id ~= 0 then
				local itemNode = require("util.ItemNode"):create():init(item.id, item.num)
				list1:addElement(itemNode)
			end
		end
	end
	local item_count = node2:getChildByName("ship_list"):getChildrenCount()
	local size_width = node2:getChildByName("ship_list"):getContentSize().width
	local can_item_count = math.floor(size_width/100)
	if item_count <= can_item_count then
		node2:getChildByName("ship_list"):setTouchEnabled(false)
	end
	local node_mine = node2:getChildByName('Node_mine')
	local node_enemy = node2:getChildByName('Node_enemy')
	node_mine:getChildByName('Text_mine'):setString(CONF:getStringValue('my_forms')) -- 我方
	node_enemy:getChildByName('Text_enemy'):setString(CONF:getStringValue('enemyForm')) -- 敌方

	node2:getChildByName('team'):setString(CONF:getStringValue('combo attack'))
	node2:getChildByName('Text_lian'):setString(CONF:getStringValue('base_damage'))
	node2:getChildByName('Text_lian_0'):setString(CONF:getStringValue('Continuous attack')..':'..mail_info.planet_report.attack_count)
	if Tools.isEmpty(mail_info.planet_report.my_data_list) == false then
		local date_info = mail_info.planet_report.my_data_list[1]
		if Tools.isEmpty(date_info) == false then
			node_mine:getChildByName('Image_icon'):getChildByName('icon'):loadTexture("HeroImage/"..date_info.info.icon_id..".png")
			node_mine:getChildByName('Text_name'):setString(date_info.info.nickname)
			node_mine:getChildByName('Text_lv'):setString('Lv.'..date_info.info.level)
			node_mine:getChildByName('Text_vip'):setString('VIP '..0)
			node_mine:getChildByName('Text_xing'):setVisible(date_info.info.group_nickname ~= '')
			node_mine:getChildByName('Text_xing'):setString('【'..date_info.info.group_nickname..'】')
			node_mine:getChildByName('Text_pos'):setString('('..mail_info.planet_report.pos_list[1].x..','..mail_info.planet_report.pos_list[1].y..')')
		end
	end
	local totalHp = 0
	for i,ship_id in ipairs(cfg_boss.MONSTER_LIST) do
		if ship_id ~= 0 then
			local cfg_ship = CONF.AIRSHIP.get(math.abs(ship_id))
			totalHp = totalHp + cfg_ship.LIFE
			break
		end
	end
	if Tools.isEmpty(mail_info.planet_report.enemy_data_list) == false then
		local date_info = mail_info.planet_report.enemy_data_list[1]
		if Tools.isEmpty(date_info) == false then
			node_enemy:getChildByName('Text_name'):setString(CONF:getStringValue(cfg_boss.NAME))
			node_enemy:getChildByName('Text_lv'):setString('Lv.'..cfg_boss.LV)
			node_enemy:getChildByName('Text_xue'):setString(CONF:getStringValue('Attr_2'))
			local posX = node_enemy:getChildByName('Text_xue'):getPositionX()
			local posY = node_enemy:getChildByName('Text_xue'):getPositionY()
			local width = node_enemy:getChildByName('Text_xue'):getContentSize().width
			local progress = require("util.ScaleProgressDelegate"):create(node_enemy:getChildByName('progress'), 235)
			local nowHp = 0
			for k,hp in ipairs(date_info.ship_hp_list) do
				nowHp = nowHp + hp
			end
			local p1 = math.ceil(nowHp/totalHp*1000)/10
			progress:setPercentage(p1)
			local preHp = 0
			for k,hp in ipairs(mail_info.planet_report.pre_enemy_hp_list) do
				preHp = preHp + hp
			end
			node_enemy:getChildByName('Text_xuePe'):setString('-'..(math.floor((preHp-nowHp)/totalHp*1000)/10)..'%')
			node_enemy:getChildByName('Text_nai'):setString(p1..'%')
			node_enemy:getChildByName('progress'):setPosition(posX+width+5,posY)
			node_enemy:getChildByName('jdt_bottom02_53'):setPosition(posX+width+5,posY)
			node_enemy:getChildByName('Text_nai'):setPosition(node_enemy:getChildByName('progress'):getPositionX()+node_enemy:getChildByName('jdt_bottom02_53'):getContentSize().width/2,node_enemy:getChildByName('progress'):getPositionY())
			local res_name = cfg_boss.ICON..'.png'
			if res_name then
				node_enemy:getChildByName('Image_icon'):getChildByName('icon'):loadTexture(string.format("PlanetIcon/"..res_name))
			end
		end
	end
	local list = require("util.ScrollViewDelegate"):create(totalNode:getChildByName('Node'):getChildByName("ship_list"),cc.size(0,10), cc.size(820,sizeH))
	totalNode:getChildByName('Node'):getChildByName("ship_list"):setScrollBarEnabled(false)
	list:addElement(node2)
	return totalNode
end

return MailDetailAttackType_boss