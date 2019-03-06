local MailDetailAttackType_others = class("MailDetailAttackType_others")

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

function MailDetailAttackType_others:initMailDetail(mail_info,data)
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
	if Tools.isEmpty(info.enemy_data_list) or  Tools.isEmpty(info.my_data_list) then
		return
	end
	local str = ''
	local sizeH = 330
	totalNode:getChildByName('Node'):getChildByName('Text_1'):setVisible(false)
	local cfg_str = ''
	
	-- CONF:getStringValue(CONF.PLANET_RUINS.get(info.id).NAME
	if mail_info.planet_report.type == 2 then
		cfg_str = CONF:getStringValue('collect_mail_3')
		str = CONF:getStringValue(CONF.PLANET_RES.get(info.id).NAME)
	elseif mail_info.planet_report.type == 3 then
		str = CONF:getStringValue(CONF.PLANET_RES.get(info.id).NAME)
		cfg_str = CONF:getStringValue('collect_mail_2')
	elseif mail_info.planet_report.type == 10 then
		cfg_str = CONF:getStringValue('base_mail')
	elseif mail_info.planet_report.type == 11 then
		cfg_str = CONF:getStringValue('base_mail_2')
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
		-- 	myApp:pushView('PlanetScene/PlanetScene',{move_info = {pos = {x=info.pos_list[1].x,y=info.pos_list[1].y},node_id_list = {getNodeIDByGlobalPos(info.pos_list[1])}} })
		-- end
		myApp:pushView('PlanetScene/PlanetScene',{move_info = {pos = {x=info.pos_list[1].x,y=info.pos_list[1].y},node_id_list = {getNodeIDByGlobalPos(info.pos_list[1])}} })
		end)
	local assembleNode = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/DetailAttackSmallNode/StateNode.csb")
	-- if mail_info.planet_report.type == 2 or mail_info.planet_report.type == 3 then
	-- 	assembleNode:getChildByName('Button_1'):setVisible(false)
	-- end
	if Tools.isEmpty(mail_info.planet_report.video_key_list) then
		assembleNode:getChildByName('Button_1'):setVisible(false)
	end
	-- local result = false
	-- if Tools.isEmpty(mail_info.planet_report.my_data_list) == false and Tools.isEmpty(mail_info.planet_report.enemy_data_list) == false then
	-- 	local can = false
	-- 	for k,v in ipairs(mail_info.planet_report.enemy_data_list) do
	-- 		if Tools.isEmpty(v.ship_list) == false then
	-- 			for k,ship in ipairs(v.ship_list) do
	-- 				if ship.id ~= 0 then
	-- 					can = true
	-- 					break
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- 	if can then
	-- 		for k,v in ipairs(mail_info.planet_report.my_data_list) do
	-- 			if Tools.isEmpty(v.ship_list) == false then
	-- 				for k,ship in ipairs(v.ship_list) do
	-- 					if ship.id ~= 0 then
	-- 						result = true
	-- 						break
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- assembleNode:getChildByName('Button_1'):setVisible(result)
	
	assembleNode:getChildByName('Button_1'):addClickEventListener(function()
		-- Tips:tips(CONF:getStringValue("coming soon"))
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
	local node1 = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/DetailAttackSmallNode/GetNode.csb")
	local node2 = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/DetailAttackSmallNode/MailDetailTeamInfo.csb")
	node1:setName('node1')
	node2:setName('node2')

	node1:getChildByName('Text_1'):setString(CONF:getStringValue('Get resources'))
	if mail_info.planet_report.type == 11 then
		node1:getChildByName('Text_1'):setString(CONF:getStringValue('loss'))
	end
	if Tools.isEmpty(info.my_data_list) == false and Tools.isEmpty(info.enemy_data_list) == false then
		if mail_info.planet_report.type ~= 2 and mail_info.planet_report.type ~= 3 then
			assembleNode:addChild(node1)
			node1:setPosition(assembleNode:getChildByName('Node_get'):getPosition())
			local resNode = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/ResNode.csb')
			resNode:setPosition(node1:getChildByName('Text_1'):getPositionX()+node1:getChildByName('Text_1'):getContentSize().width,node1:getChildByName('Text_1'):getPositionY())
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
			node1:addChild(resNode)
		end
		if assembleNode:getChildByName('node1') then
			node2:setPosition(node1:getPositionX(),node1:getPositionY()-68)
		else
			node2:setPosition(assembleNode:getChildByName('Node_get'):getPosition())
		end
		sizeH = sizeH + node2:getChildByName('Node_mine'):getChildByName('Image_bg'):getContentSize().height/2
		assembleNode:addChild(node2)
		local node_enemy = node2:getChildByName('Node_enemy')
		local node_mine = node2:getChildByName('Node_mine')
		node_mine:getChildByName('Text_mine'):setString(CONF:getStringValue('my_forms'))
		node_enemy:getChildByName('Text_enemy'):setString(CONF:getStringValue('enemyForm'))

		local enemy = info.enemy_data_list
		local mine = info.my_data_list
		node_mine:getChildByName('Image_icon'):getChildByName('icon'):loadTexture("HeroImage/"..mine[1].info.icon_id..".png")
		node_enemy:getChildByName('Image_icon'):getChildByName('icon'):loadTexture("HeroImage/"..enemy[1].info.icon_id..".png")
		node_mine:getChildByName('Text_name'):setString(mine[1].info.nickname)
		node_mine:getChildByName('Text_lv'):setString('Lv.'..mine[1].info.level)
		node_enemy:getChildByName('Text_lv'):setString('Lv.'..enemy[1].info.level)
        if mine[1].info.vip_level then
		    node_mine:getChildByName('Text_vip'):setString('VIP '..mine[1].info.vip_level)
         else
            node_mine:getChildByName('Text_vip'):setString('VIP '..0)
         end
        if enemy[1].info.vip_level then
		    node_enemy:getChildByName('Text_vip'):setString('VIP '..enemy[1].info.vip_level)
        else
            node_enemy:getChildByName('Text_vip'):setString('VIP '..0)
        end

		node_mine:getChildByName('Text_huzhao'):setVisible(false)
		node_mine:getChildByName('num_huzhao'):setVisible(false)
		node_mine:getChildByName('Text_cuihui'):setVisible(false)
		node_mine:getChildByName('num_cuihui'):setVisible(false)
		node_enemy:getChildByName('Text_huzhao'):setVisible(false)
		node_enemy:getChildByName('num_huzhao'):setVisible(false)
		node_enemy:getChildByName('Text_cuihui'):setVisible(false)
		node_enemy:getChildByName('num_cuihui'):setVisible(false)
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

		node_enemy:getChildByName('Text_name'):setString(enemy[1].info.nickname)
		node_enemy:getChildByName('Text_huzhao'):setString(CONF:getStringValue('shield')..':')
		node_enemy:getChildByName('num_huzhao'):setString(CONF:getStringValue('wu_text'))
		-- you设置红色
		-- node_enemy:getChildByName('num_huzhao'):setTextColor(cc.c4b(233,50,59,255))
		-- node_enemy:getChildByName('num_huzhao'):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
		node_enemy:getChildByName('Text_cuihui'):setString(CONF:getStringValue('cuihuidu')..':')
		--you设置绿色
		node_enemy:getChildByName('num_cuihui'):setString(CONF:getStringValue('wu_text'))
		-- node_enemy:getChildByName('num_cuihui'):setTextColor(cc.c4b(51,231,51,255))
		-- node_enemy:getChildByName('num_cuihui'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
		if enemy[1].info.group_nickname ~= '' then
			node_enemy:getChildByName('Text_xing'):setVisible(true)
			node_enemy:getChildByName('Text_xing'):setString('【'..enemy[1].info.group_nickname..'】')
		else
			node_enemy:getChildByName('Text_xing'):setVisible(false)
		end
		node_enemy:getChildByName('Text_pos'):setString('('..enemy[1].pos_list[1].x..','..enemy[1].pos_list[1].y..')')
		node_enemy:getChildByName('team'):setString(CONF:getStringValue('Team information'))
		node_enemy:getChildByName('Text_fightnum'):setString(enemy[1].info.power)
		node_mine:getChildByName('num_huzhao'):setPosition(node_mine:getChildByName('Text_huzhao'):getPositionX()+node_mine:getChildByName('Text_huzhao'):getContentSize().width,node_mine:getChildByName('Text_huzhao'):getPositionY())
		node_mine:getChildByName('num_cuihui'):setPosition(node_mine:getChildByName('Text_cuihui'):getPositionX()+node_mine:getChildByName('Text_cuihui'):getContentSize().width,node_mine:getChildByName('Text_cuihui'):getPositionY())
		node_enemy:getChildByName('num_huzhao'):setPosition(node_enemy:getChildByName('Text_huzhao'):getPositionX()+node_enemy:getChildByName('Text_huzhao'):getContentSize().width,node_enemy:getChildByName('Text_huzhao'):getPositionY())
		node_enemy:getChildByName('num_cuihui'):setPosition(node_enemy:getChildByName('Text_cuihui'):getPositionX()+node_enemy:getChildByName('Text_cuihui'):getContentSize().width,node_enemy:getChildByName('Text_cuihui'):getPositionY())
		local myTeamNum = 1
		local myHeight = 0
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
				node:getChildByName('Text_team11'):setString(CONF:getStringValue(teamName[myTeamNum]))
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
				node:getChildByName('Image_bg1'):setContentSize(cc.size(node:getChildByName('Image_bg1'):getContentSize().width,50))
				node:setPosition(node2:getPositionX(),node2:getPositionY()-node2:getChildByName('Node_mine'):getChildByName('Image_bg'):getContentSize().height-myHeight+30)
				for o,p in ipairs(shipInfo) do
					if node:getChildByName('node1'..o) then
						myHeight = myHeight + 90
						node:getChildByName('node1'..o):setVisible(true)
						node:getChildByName('Image_17_'..o):setVisible(true)
						local cfg_ship = CONF.AIRSHIP.get(math.abs(tonumber(p[1])))
						node:getChildByName('Image_bg1'):setContentSize(cc.size(node:getChildByName('Image_bg1'):getContentSize().width,50+90*o))
						local progress = require("util.ScaleProgressDelegate"):create(node:getChildByName('node1'..o):getChildByName('progress'), 235)
						local p1 = math.ceil(tonumber(p[2])/p[5]*1000)/10
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
--                        node:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):loadTexture('RoleIcon/'..cfg_ship.ICON_ID..'.png')
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
		sizeH = sizeH + myHeight
		local data_list = {}
		for m,n in ipairs(info.my_data_list) do
			if Tools.isEmpty(n.ship_list) == false then
				for i,v in ipairs(n.ship_list) do
					if v.id ~= 0 then
						table.insert(data_list,v.id)
					end
				end
			end 
		end
		local enemyTeamNum = 1
		local enemyHeight = 0
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
				node:getChildByName('Text_team11'):setString(CONF:getStringValue(teamName[enemyTeamNum]))
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
		if  enemyHeight > myHeight then
			sizeH = sizeH + (enemyHeight - myHeight)
		end
	end
	local list = require("util.ScrollViewDelegate"):create(totalNode:getChildByName('Node'):getChildByName("ship_list"),cc.size(0,10), cc.size(820,sizeH))
	totalNode:getChildByName('Node'):getChildByName("ship_list"):setScrollBarEnabled(false)
	list:addElement(assembleNode)
	return totalNode
end

return MailDetailAttackType_others