local MailDetailAttackType_city = class("MailDetailAttackType_city")

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
	str2 = str2
	local label1 = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, str1, s_default_font, 25, 2 ) 
	richText:pushBackElement(label1)
	local label2 = ccui.RichElementText:create( 1, cc.c3b(233,50,59), 255, str2, s_default_font, 25, 2 ) 
	richText:pushBackElement(label2)
	return richText
end

function MailDetailAttackType_city:initMailDetail(mail_info,data)
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
	local sizeH = 260
	totalNode:getChildByName('Node'):getChildByName('Text_1'):setVisible(false)
	local str1 = ''
	local str2 = ''
	
	-- CONF:getStringValue(CONF.PLANET_RUINS.get(info.id).NAME
	local cfg_city 
	if mail_info.planet_report.type == 12 or mail_info.planet_report.type == 13 or mail_info.planet_report.type == 19 or mail_info.planet_report.type == 20 then
		cfg_city = CONF.PLANETCITY.get(info.id)
	else
		cfg_city = CONF.PLANETTOWER.get(info.id)
	end
	if mail_info.planet_report.type == 12 then
		str1 = CONF:getStringValue('judian_mail')
		str2 = CONF:getStringValue(cfg_city.NAME)
	elseif mail_info.planet_report.type == 13 then
		str1 = CONF:getStringValue('judian_mail_1')
		str2 = CONF:getStringValue(cfg_city.NAME)
	elseif mail_info.planet_report.type == 19 then
		str1 = CONF:getStringValue("atk_throne")
		str2 = CONF:getStringValue(cfg_city.NAME)
	elseif mail_info.planet_report.type == 20 then
		str1 = CONF:getStringValue("df_throne")
		str2 = CONF:getStringValue(cfg_city.NAME)
	elseif mail_info.planet_report.type == 21 then
		str1 = CONF:getStringValue("atk_tower")
		str2 = CONF:getStringValue(cfg_city.NAME)
	elseif mail_info.planet_report.type == 22 then
		str1 = CONF:getStringValue("df_tower")
		str2 = CONF:getStringValue(cfg_city.NAME)
	end
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
	local assembleNode = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/DetailAttackSmallNode/StateNode.csb")
	if Tools.isEmpty(mail_info.planet_report.video_key_list) then
		assembleNode:getChildByName('Button_1'):setVisible(false)
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
	assembleNode:getChildByName('Button_1'):setVisible(result)
	if Tools.isEmpty(mail_info.planet_report.video_key_list) then
		assembleNode:getChildByName('Button_1'):setVisible(false)
	end
	assembleNode:getChildByName('Button_1'):addClickEventListener(function()
		if Tools.isEmpty(mail_info.planet_report.video_key_list) == false then
			g_MailGuid_VideoPosition = mail_info.guid..'_1'
			local strData = Tools.encode("PvpVideoReq", {
				video_key = mail_info.planet_report.video_key_list[1],
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVP_VIDEO_REQ"),strData)
		end
		end)

	if info.isWin then
		assembleNode:getChildByName('Text_huode'):setString(CONF:getStringValue('win')) -- 胜利
		assembleNode:getChildByName('Text_huode'):setTextColor(cc.c4b(51,231,51,255))
		-- assembleNode:getChildByName('Text_huode'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
	else
		assembleNode:getChildByName('Text_huode'):setString(CONF:getStringValue('failed')) -- 失败
		assembleNode:getChildByName('Text_huode'):setTextColor(cc.c4b(233,50,59,255))
		-- assembleNode:getChildByName('Text_huode'):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
	end
	local node2 = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/DetailAttackSmallNode/MailDetailTeamInfo.csb")
	node2:setName('node2')
	local myHeight = 0
	local enemyHeight = 0
	if Tools.isEmpty(info.my_data_list) == false then
		node2:getChildByName('Node_enemy'):setVisible(false)
		node2:getChildByName('Image_vs'):setVisible(false)
		node2:setPosition(assembleNode:getChildByName('Node_get'):getPosition())
		sizeH = sizeH + node2:getChildByName('Node_mine'):getChildByName('Image_bg'):getContentSize().height/3
		assembleNode:addChild(node2)
		local node_mine = node2:getChildByName('Node_mine')
		node_mine:getChildByName('Text_mine'):setString(CONF:getStringValue('my_forms'))

		local mine = info.my_data_list
		if mail_info.planet_report.type == 12 then
			node_mine:getChildByName('Image_icon'):getChildByName('icon'):loadTexture("HeroImage/"..mine[1].info.icon_id..".png")
			node_mine:getChildByName('Text_name'):setString(mine[1].info.nickname)
		elseif mail_info.planet_report.type == 13 then
			node_mine:getChildByName('Image_icon'):getChildByName('icon'):loadTexture("PlanetIcon/"..cfg_city.ICON..".png")
			node_mine:getChildByName('Text_name'):setString(CONF:getStringValue(cfg_city.NAME))
		end
		node_mine:getChildByName('Text_lv'):setVisible(false)
		node_mine:getChildByName('Text_vip'):setVisible(false)
		node_mine:getChildByName('Text_huzhao'):setVisible(false)
		node_mine:getChildByName('num_huzhao'):setVisible(false)
		node_mine:getChildByName('Text_cuihui'):setVisible(false)
		node_mine:getChildByName('num_cuihui'):setVisible(false)
		node_mine:getChildByName('Text_huzhao'):setString(CONF:getStringValue('shield')..':')
		node_mine:getChildByName('num_huzhao'):setString(CONF:getStringValue('wu_text'))
		-- you设置红色
		-- node_mine:getChildByName('num_huzhao'):setTextColor(cc.c4b(233,50,59,255))
		-- node_mine:getChildByName('num_huzhao'):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
		node_mine:getChildByName('Text_cuihui'):setString(CONF:getStringValue('cuihuidu')..':')
		--you设置绿色
		node_mine:getChildByName('num_cuihui'):setString(CONF:getStringValue('wu_text'))
		-- node_mine:getChildByName('num_cuihui'):setTextColor(cc.c4b(51,231,51,255))
		-- node_mine:getChildByName('num_cuihui'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
		if mine[1].info.group_nickname ~= '' then
			node_mine:getChildByName('Text_xing'):setVisible(true)
			node_mine:getChildByName('Text_xing'):setString('【'..mine[1].info.group_nickname..'】')
		else
			node_mine:getChildByName('Text_xing'):setVisible(false)
		end
		node_mine:getChildByName('Text_pos'):setString('('..mine[1].pos_list[1].x..','..mine[1].pos_list[1].y..')')
		node_mine:getChildByName('team'):setString(CONF:getStringValue('Team information'))
		node_mine:getChildByName('Text_fightnum'):setString(mine[1].info.power)


		node_mine:getChildByName('num_huzhao'):setPosition(node_mine:getChildByName('Text_huzhao'):getPositionX()+node_mine:getChildByName('Text_huzhao'):getContentSize().width,node_mine:getChildByName('Text_huzhao'):getPositionY())
		node_mine:getChildByName('num_cuihui'):setPosition(node_mine:getChildByName('Text_cuihui'):getPositionX()+node_mine:getChildByName('Text_cuihui'):getContentSize().width,node_mine:getChildByName('Text_cuihui'):getPositionY())
		local myTeamNum = 1
		for k,v in ipairs(info.my_data_list) do
			local can = false
			if Tools.isEmpty(v.ship_list) == false then
				for k,ship in ipairs(v.ship_list) do
					if ship.id ~= 0 then
						can = true
					end
				end
			end
			if can then
				myHeight = myHeight + 50
				local node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/TeamNode.csb')
				node:setName('TeamNode1'..k)
				assembleNode:addChild(node)
				node:getChildByName('Text_team11'):setString(CONF:getStringValue(teamName[myTeamNum])..':'..v.info.nickname)
				myTeamNum = myTeamNum + 1
				local shipInfo = {}
				for k,ship in ipairs(v.ship_list) do
					local hp = v.ship_hp_list[ship.position]
					if hp then
						local durable = Tools.getShipMaxDurable( ship )
						local maxHp = ship.attr[CONF.EShipAttr.kHP]
						local t = {ship.id,hp,ship.durable,durable,maxHp}
						shipInfo[#shipInfo + 1] = t
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
				-- 46/85
				node:getChildByName('Image_bg1'):setContentSize(cc.size(node:getChildByName('Image_bg1'):getContentSize().width,46))
				node:setPosition(node2:getPositionX(),node2:getPositionY()-node2:getChildByName('Node_mine'):getChildByName('Image_bg'):getContentSize().height-myHeight+30)
				for o,p in ipairs(shipInfo) do
					if node:getChildByName('node1'..o) then
						myHeight = myHeight + 90
						node:getChildByName('node1'..o):setVisible(true)
						node:getChildByName('Image_17_'..o):setVisible(true)
						local cfg_ship = CONF.AIRSHIP.get(math.abs(tonumber(p[1])))
						node:getChildByName('Image_bg1'):setContentSize(cc.size(node:getChildByName('Image_bg1'):getContentSize().width,46+85*o))
						local progress = require("util.ScaleProgressDelegate"):create(node:getChildByName('node1'..o):getChildByName('progress'), 235)
						local p1 = math.ceil(tonumber(p[2])/p[5]*1000)/10
						if p1 > 100 then p1 = 100 end
						progress:setPercentage(p1)
						node:getChildByName('node1'..o):getChildByName('Text_nai'):setString(p1..'%')
						node:getChildByName('node1'..o):getChildByName('Text_xue'):setString(CONF:getStringValue('Attr_2'))
						node:getChildByName('node1'..o):getChildByName('Text'):setString(CONF:getStringValue('durable'))
						local desT = (math.ceil(p[3]/p[4]*1000)/10)
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
--						node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):loadTexture('RoleIcon/'..cfg_ship.ICON_ID..'.png')
                        node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):setVisible(false)
                        node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon2'):setVisible(true)
                        node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon2'):setTexture("ShipImage/"..cfg_ship.ICON_ID..".png")
						node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('Image_1'):loadTexture("RankLayer/ui/ui_avatar_" .. cfg_ship.QUALITY .. ".png")
					end
				end
				sizeH = sizeH + node:getChildByName('Image_bg1'):getContentSize().height
			end
		end
	end
	local enemy_node = node2:getChildByName('Node_enemy')
	if Tools.isEmpty(info.enemy_data_list) then
		if mail_info.planet_report.type == 12 then
			enemy_node:setVisible(true)
			enemy_node:getChildByName('Image_icon'):getChildByName('icon'):loadTexture("PlanetIcon/"..cfg_city.ICON..".png")
			enemy_node:getChildByName('Text_name'):setString(CONF:getStringValue(cfg_city.NAME))
			enemy_node:getChildByName('Text_pos'):setString('('..info.pos_list[1].x..','..info.pos_list[1].y..')')
			node2:getChildByName('Image_vs'):setVisible(true)
			enemy_node:getChildByName('Text_lv'):setVisible(false)
			enemy_node:getChildByName('Text_vip'):setVisible(false)
			enemy_node:getChildByName('Text_huzhao'):setVisible(false)
			enemy_node:getChildByName('num_huzhao'):setVisible(false)
			enemy_node:getChildByName('Text_cuihui'):setVisible(false)
			enemy_node:getChildByName('num_cuihui'):setVisible(false)
			enemy_node:getChildByName('Image_47_0'):setVisible(false)
			enemy_node:getChildByName('Text_fightnum'):setVisible(false)
			enemy_node:getChildByName('Text_xing'):setVisible(false)
			enemy_node:getChildByName('Image_20_0'):setVisible(false)
		else
			print('~~~~~~~~enemy_data_list is empty,planet_report.type = 12~~~~~~~~~~~')
		end
	else
		if Tools.isEmpty(info.enemy_data_list[1].info) then -- 怪物
			enemy_node:setVisible(true)
			enemy_node:getChildByName('Image_icon'):getChildByName('icon'):loadTexture("PlanetIcon/"..cfg_city.ICON..".png")
			enemy_node:getChildByName('Text_name'):setString(CONF:getStringValue(cfg_city.NAME))
			enemy_node:getChildByName('Text_pos'):setString('('..info.pos_list[1].x..','..info.pos_list[1].y..')')
			node2:getChildByName('Image_vs'):setVisible(true)
			enemy_node:getChildByName('Text_lv'):setVisible(false)
			enemy_node:getChildByName('Text_vip'):setVisible(false)
			enemy_node:getChildByName('Text_huzhao'):setVisible(false)
			enemy_node:getChildByName('num_huzhao'):setVisible(false)
			enemy_node:getChildByName('Text_cuihui'):setVisible(false)
			enemy_node:getChildByName('num_cuihui'):setVisible(false)
			enemy_node:getChildByName('Image_47_0'):setVisible(false)
			enemy_node:getChildByName('Text_fightnum'):setVisible(false)
			enemy_node:getChildByName('Text_xing'):setVisible(false)
			enemy_node:getChildByName('Image_20_0'):setVisible(false)
		else
			enemy_node:setVisible(true)
			node2:getChildByName('Image_vs'):setVisible(true)
			enemy_node:getChildByName('Text_lv'):setVisible(false)
			enemy_node:getChildByName('Text_vip'):setVisible(false)
			enemy_node:getChildByName('Text_huzhao'):setVisible(false)
			enemy_node:getChildByName('num_huzhao'):setVisible(false)
			enemy_node:getChildByName('Text_cuihui'):setVisible(false)
			enemy_node:getChildByName('num_cuihui'):setVisible(false)
			local enemy = info.enemy_data_list
			if mail_info.planet_report.type == 13 then
				enemy_node:getChildByName('Image_icon'):getChildByName('icon'):loadTexture("HeroImage/"..enemy[1].info.icon_id..".png")
				enemy_node:getChildByName('Text_name'):setString(enemy[1].info.nickname)
			elseif mail_info.planet_report.type == 12 then
				enemy_node:getChildByName('Image_icon'):getChildByName('icon'):loadTexture("PlanetIcon/"..cfg_city.ICON..".png")
				enemy_node:getChildByName('Text_name'):setString(CONF:getStringValue(cfg_city.NAME))
			end
			if enemy[1].info.group_nickname ~= '' then
				enemy_node:getChildByName('Text_xing'):setVisible(true)
				enemy_node:getChildByName('Text_xing'):setString('【'..enemy[1].info.group_nickname..'】')
			else
				enemy_node:getChildByName('Text_xing'):setVisible(false)
			end
			enemy_node:getChildByName('Text_fightnum'):setString(enemy[1].info.power)
		end
		local enemyTeamNum = 1
		for k,v in ipairs(info.enemy_data_list) do
			local can = false
			if Tools.isEmpty(v.ship_list) == false then
				for k,ship in ipairs(v.ship_list) do
					if ship.id ~= 0 then
						can = true
					end
				end
			end
			if can then
				enemyHeight = enemyHeight + 50
				local node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/TeamNode.csb')
				node:getChildByName('Image_bg1'):loadTexture('MailLayer/ui/enemy_bg.png')
				-- node:getChildByName('Image_bg1'):setRotation(180)
				node:getChildByName('Image_bg1'):setContentSize(cc.size(391,510))
				node:setName('TeamNode2'..k)
				assembleNode:addChild(node)
				local name = ""
				if cfg_city.SHIP_NAME then
					name =	CONF:getStringValue(cfg_city.SHIP_NAME)
				end
				if v.info and Tools.isEmpty(v.info) == false then
					name = v.info.nickname
				end
				node:getChildByName('Text_team11'):setString(CONF:getStringValue(teamName[enemyTeamNum])..':'..name)
				enemyTeamNum = enemyTeamNum + 1
				local shipInfo = {}
				for k,ship in ipairs(v.ship_list) do
					local hp = v.ship_hp_list[ship.position]
					if hp then
						local durable = Tools.getShipMaxDurable( ship )
						local maxHp = ship.attr[CONF.EShipAttr.kHP]
						local t = {ship.id,hp,ship.durable,durable,maxHp}
						shipInfo[#shipInfo + 1] = t
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
				node:getChildByName('Image_bg1'):setContentSize(cc.size(node:getChildByName('Image_bg1'):getContentSize().width,50))
				node:setPosition(node2:getPositionX()+node:getChildByName('Image_bg1'):getContentSize().width+16,node2:getPositionY()-node2:getChildByName('Node_mine'):getChildByName('Image_bg'):getContentSize().height-enemyHeight+30)
				for o,p in ipairs(shipInfo) do
					if node:getChildByName('node1'..o) then
						enemyHeight = enemyHeight + 90
						node:getChildByName('node1'..o):setVisible(true)
						node:getChildByName('Image_17_'..o):setVisible(true)
						local cfg_ship = CONF.AIRSHIP.get(math.abs(tonumber(p[1])))
						node:getChildByName('Image_bg1'):setContentSize(cc.size(node:getChildByName('Image_bg1'):getContentSize().width,50+90*o))
						local progress = require("util.ScaleProgressDelegate"):create(node:getChildByName('node1'..o):getChildByName('progress'), 235)
						local p1 = math.ceil(tonumber(p[2])/p[5]*1000)/10
						progress:setPercentage(p1)
						node:getChildByName('node1'..o):getChildByName('Text_xue'):setString(CONF:getStringValue('Attr_2'))
						node:getChildByName('node1'..o):getChildByName('Text'):setString(CONF:getStringValue('durable'))
						local desT = (math.ceil(p[3]/p[4]*1000)/10)
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
--						node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):loadTexture('RoleIcon/'..cfg_ship.ICON_ID..'.png')
                        node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):setVisible(false)
                        node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon2'):setVisible(true)
                        node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon2'):setTexture("ShipImage/"..cfg_ship.ICON_ID..".png")
						-- if cfg_ship.QUALITY == EDevelopStatus.kHas then
							node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('Image_1'):loadTexture("RankLayer/ui/ui_avatar_" .. cfg_ship.QUALITY .. ".png")
						-- else
						-- 	node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('Image_1'):loadTexture("RankLayer/ui/ui_avatar2_" .. cfg_ship.QUALITY .. ".png")
						-- end
					end
				end
			end
		end
	end
	if  enemyHeight > myHeight then
		sizeH = sizeH + (enemyHeight - myHeight)
	end
	local list = require("util.ScrollViewDelegate"):create(totalNode:getChildByName('Node'):getChildByName("ship_list"),cc.size(0,10), cc.size(820,sizeH))
	totalNode:getChildByName('Node'):getChildByName("ship_list"):setScrollBarEnabled(false)
	list:addElement(assembleNode)
	return totalNode
end

return MailDetailAttackType_city