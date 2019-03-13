local MailDetailAttackType_spy = class("MailDetailAttackType_spy")

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

function MailDetailAttackType_spy:initMailDetail(mail_info,data)
	-- 6
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
	if Tools.isEmpty(info.enemy_data_list) or mail_info.planet_report.type ~= 6 then
		return
	end
	local str = ''
	local sizeH = 250
	totalNode:getChildByName('Node'):getChildByName('Text_1'):setVisible(false)
	local cfg_str = CONF:getStringValue('scout_mail')
	local str = ''
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
			myApp:pushView('PlanetScene/PlanetScene',{move_info = {pos = {x=info.pos_list[1].x,y=info.pos_list[1].y},node_id_list = {getNodeIDByGlobalPos(info.pos_list[1])}} })
		end)
	local cfg_building11 = CONF.BUILDING_11.get(player:getBuildingInfo(CONF.EBuilding.kSpy).level)
	local showRes = false
	local showShipNum = false
	local showBatteryInfo = false
	local showShipHP = false
	local showShipLevel = false
	local showShipStar = false
	local showPNameAndLevel = false
	local showShipInfo = false
	local showBuildingLevel = false
	local showGenius = false
	for k,v in ipairs(cfg_building11.SCOUT) do
		if v >= 1 then
			showRes = true
		end
		if v >= 2 then
			showShipNum = true
		end
		if v >= 3 then
			showBatteryInfo = true
		end
		if v >= 4 then
			showShipHP = true
		end
		if v >= 5 then
			showShipLevel = true
		end
		if v >= 6 then
			showShipStar = true
		end
		if v >= 7 then
			showPNameAndLevel = true
		end
		if v >= 8 then
			showShipInfo = true
		end
		if v >= 9 then
			showBuildingLevel = true
		end
		if v >= 10 then
			showGenius = true
		end
	end
	local b1,b2,b3= isBuildingOpen(11)
	totalNode:getChildByName('Node'):getChildByName("ship_list"):setScrollBarEnabled(false)
	if not showRes or (not b1 or not b2 or not b3) then
		local node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/NotOpenNode.csb')
		local list = require("util.ScrollViewDelegate"):create(totalNode:getChildByName('Node'):getChildByName("ship_list"),cc.size(0,10), cc.size(820,sizeH))
		list:addElement(node)
		return totalNode
	end

	local node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/SpyNode.csb')
	node:getChildByName('Button_1'):setVisible(false)
	node:getChildByName('Button_1'):addClickEventListener(function()
		Tips:tips(CONF:getStringValue("coming soon"))
		end)

	-- if info.isWin then
		node:getChildByName('Text_huode'):setString(CONF:getStringValue('scout_report')) -- 侦察报告
		node:getChildByName('Text_huode'):setTextColor(cc.c4b(51,231,51,255))
		-- node:getChildByName('Text_huode'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
	-- else
	-- 	node:getChildByName('Text_huode'):setString(CONF:getStringValue('scout_report')) -- 失败
	-- 	node:getChildByName('Text_huode'):setTextColor(cc.c4b(233,50,59,255))
	-- 	node:getChildByName('Text_huode'):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
	-- end
	node:getChildByName('Text_1'):setString(CONF:getStringValue('Get resources'))
    node:getChildByName('Text_3'):setString(CONF:getStringValue('Team information'))
	node:getChildByName('ship_list'):setPositionX(node:getChildByName('Text_1'):getPositionX()+20+node:getChildByName('Text_1'):getContentSize().width)
	local list = require("util.ScrollViewDelegate"):create(node:getChildByName("ship_list"),cc.size(7,3), cc.size(90,90))
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
	node:getChildByName('Text_3'):setString(CONF:getStringValue("Team information"))
	if not showShipNum then
		local num = 0
		for k,shiplist in ipairs(info.enemy_data_list) do
			if k ~= 1 then
				for ki,ship in ipairs(shiplist.ship_list) do
					if ship.id ~= 0 then
						num = num + 1
					end
				end
			end
		end
		node:getChildByName("Text_3_0"):setVisible(false)
		node:getChildByName("Text_3_0"):setString(CONF:getStringValue("airship quantity")..":"..num)
		local nopeople_node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/NotOpenNode.csb')
		nopeople_node:setPosition(node:getChildByName('Node_pos'):getPositionX(),node:getChildByName('Node_pos'):getPositionY())
		local h = 354 + node:getChildByName('Node_pos'):getPositionY()
		nopeople_node:getChildByName("Image_1"):setContentSize(820,h)
		nopeople_node:getChildByName("Text_1"):setPositionY(-nopeople_node:getChildByName("Image_1"):getContentSize().height/2)
		nopeople_node:getChildByName("Image_2"):setPositionY(nopeople_node:getChildByName("Text_1"):getPositionY())
		node:addChild(nopeople_node)
		local list = require("util.ScrollViewDelegate"):create(totalNode:getChildByName('Node'):getChildByName("ship_list"),cc.size(0,10), cc.size(820,sizeH))
		list:addElement(node)
		return totalNode
	end
	if mail_info.planet_report.type == 6 then
		local height = 0
		local myTeamNum = 1
		for k,shiplist in ipairs(info.enemy_data_list) do
			if k ~= 1 then
				local shipInfo = {}
				local can = false
				for ki,ship in ipairs(shiplist.ship_list) do
					if ship.id ~= 0 then
						can = true
						local durable = Tools.getShipMaxDurable( ship )
						local maxHp = ship.attr[CONF.EShipAttr.kHP]
						local t = {ship.id,info.enemy_data_list[k].ship_hp_list[ship.position],ship.durable,durable,maxHp,ship.ship_break,ship.level}
						shipInfo[#shipInfo + 1] = t
					end
				end
				if can then
					local teamNode = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/TeamNode.csb')
					teamNode:setPosition(node:getChildByName('Node_pos'):getPositionX(),node:getChildByName('Node_pos'):getPositionY()-height)
					if showPNameAndLevel then
						teamNode:getChildByName('Text_team11'):setString(CONF:getStringValue(teamName[myTeamNum]).."    "..shiplist.info.nickname.." Lv."..shiplist.info.level)
					else
						teamNode:getChildByName('Text_team11'):setString(CONF:getStringValue(teamName[myTeamNum]))
					end
					myTeamNum = myTeamNum + 1
					teamNode:getChildByName('Image_bg1'):setVisible(false)
					for i=0,5 do
						teamNode:getChildByName('Image_17_'..i):setVisible(false)
						if Tools.isEmpty(shipInfo) == false then
							teamNode:getChildByName('Image_17_0'):setVisible(true)
						end
					end
					for i=1,5 do
						teamNode:getChildByName('node1'..i):setVisible(false)
					end
					height =  height + 50 
					for o,p in ipairs(shipInfo) do
						if teamNode:getChildByName('node1'..o) then
							teamNode:getChildByName('node1'..o):setVisible(true)
							teamNode:getChildByName('Image_17_'..o):setVisible(true)
							local cfg_ship = CONF.AIRSHIP.get(math.abs(tonumber(p[1])))
							local progress = require("util.ScaleProgressDelegate"):create(teamNode:getChildByName('node1'..o):getChildByName('progress'), 235)
							local p1 = math.ceil(tonumber(p[2])/p[5]*1000)/10
							progress:setPercentage(p1)
							teamNode:getChildByName('node1'..o):getChildByName('Text_xue'):setString(CONF:getStringValue('Attr_2'))
							teamNode:getChildByName('node1'..o):getChildByName('Text'):setString(CONF:getStringValue('durable'))
							local desT = (math.ceil(p[3]/p[4]*1000)/10)
							teamNode:getChildByName('node1'..o):getChildByName('Text_num'):setString(desT..'%')
							teamNode:getChildByName('node1'..o):getChildByName('Text_num'):setPositionY(teamNode:getChildByName('node1'..o):getChildByName('Text'):getPositionY())
							teamNode:getChildByName('node1'..o):getChildByName('Text_num'):setPositionX(teamNode:getChildByName('node1'..o):getChildByName('Text'):getPositionX()+teamNode:getChildByName('node1'..o):getChildByName('Text'):getContentSize().width + 5)
							if math.ceil(p[3]/p[4]*100) < 50 then
								teamNode:getChildByName('node1'..o):getChildByName('Text_num'):setTextColor(cc.c4b(233,50,59,255))
								-- teamNode:getChildByName('node1'..o):getChildByName('Text_num'):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
							else
								teamNode:getChildByName('node1'..o):getChildByName('Text_num'):setTextColor(cc.c4b(51,231,51,255))
								-- teamNode:getChildByName('node1'..o):getChildByName('Text_num'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
							end
							teamNode:getChildByName('node1'..o):getChildByName('progress'):setPositionX(teamNode:getChildByName('node1'..o):getChildByName('Text_xue'):getPositionX()+10+teamNode:getChildByName('node1'..o):getChildByName('Text_xue'):getContentSize().width)
							teamNode:getChildByName('node1'..o):getChildByName('jdt_bottom02_53'):setPositionX(teamNode:getChildByName('node1'..o):getChildByName('Text_xue'):getPositionX()+10+teamNode:getChildByName('node1'..o):getChildByName('Text_xue'):getContentSize().width)
							teamNode:getChildByName('node1'..o):getChildByName('Text_nai'):setString(p1..'%')
--							teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):loadTexture('RoleIcon/'..cfg_ship.ICON_ID..'.png')
                            teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):setVisible(false)
                            teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon2'):setVisible(true)
                            teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon2'):setTexture("ShipImage/"..cfg_ship.ICON_ID..".png")
							-- if cfg_ship.QUALITY == EDevelopStatus.kHas then
								teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('Image_1'):loadTexture("RankLayer/ui/ui_avatar_" .. cfg_ship.QUALITY .. ".png")
							-- else
							-- 	teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('Image_1'):loadTexture("RankLayer/ui/ui_avatar2_" .. cfg_ship.QUALITY .. ".png")
							-- end
							teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("shipType"):setTexture("ShipType/"..cfg_ship.TYPE..".png")
							teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("level"):setString(p[7])

							teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("shipType"):setVisible(true)
							teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("level"):setVisible(true)
							for i=1,5 do
								teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("star_"..i):setVisible(i <= p[6])
							end


							if not showBatteryInfo or not showShipHP then
								teamNode:getChildByName("node1"..o):getChildByName("Text_xue"):setVisible(false)
								-- teamNode:getChildByName("node1"..o):getChildByName("Text"):setVisible(false)
								teamNode:getChildByName("node1"..o):getChildByName("jdt_bottom02_53"):setVisible(false)
								teamNode:getChildByName("node1"..o):getChildByName("progress"):setVisible(false)
								teamNode:getChildByName("node1"..o):getChildByName("Text_nai"):setVisible(false)
								-- teamNode:getChildByName("node1"..o):getChildByName("Text_num"):setVisible(false)
								teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("level"):setVisible(false)
								for i=1,5 do
									teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("star_"..i):setVisible(false)
								end
							end
							if not showShipLevel then
								teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("level"):setVisible(false)
								for i=1,5 do
									teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("star_"..i):setVisible(false)
								end
							end
							if not showShipStar then
								for i=1,5 do
									teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("star_"..i):setVisible(false)
								end
							end


							teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("Sprite_2"):setVisible(teamNode:getChildByName("node1"..o):getChildByName("shipIcon"):getChildByName("level"):isVisible())
							height = height + 90
						end
					end 
					node:addChild(teamNode)
				end
			end
		end
		sizeH = sizeH + height
	end
	node:getChildByName('Image_7'):setVisible(Tools.isEmpty(info.enemy_data_list[2]) == false)
	node:getChildByName('Text_3'):setVisible(Tools.isEmpty(info.enemy_data_list[2]) == false) 
	local list = require("util.ScrollViewDelegate"):create(totalNode:getChildByName('Node'):getChildByName("ship_list"),cc.size(0,10), cc.size(820,sizeH))
	totalNode:getChildByName('Node'):getChildByName("ship_list"):setScrollBarEnabled(false)
	list:addElement(node)
	return totalNode
end

return MailDetailAttackType_spy