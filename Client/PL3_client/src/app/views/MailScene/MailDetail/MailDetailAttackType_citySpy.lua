local MailDetailAttackType_citySpy = class("MailDetailAttackType_citySpy")

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

local create_MailRichText = function(str)
	local richText = ccui.RichText:create()
	local str1 = CONF:getStringValue('zhencha')
	local label1 = ccui.RichElementText:create( 1, cc.c3b(255, 255, 255), 255, str1, s_default_font, 25, 2 ) 
	richText:pushBackElement(label1)
	local label2 = ccui.RichElementText:create( 1, cc.c3b(233,50,59), 255, str, s_default_font, 25, 2 ) 
	richText:pushBackElement(label2)
	return richText
end

function MailDetailAttackType_citySpy:initMailDetail(mail_info,data)
	if Tools.isEmpty(mail_info) or  Tools.isEmpty(mail_info.planet_report) then
		return
	end
	local b1,b2,b3= isBuildingOpen(11)

	local info = mail_info.planet_report
	local totalNode = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/MailDetailAttackNode.csb")
	setScreenPosition(totalNode:getChildByName('closeNode'), "righttop")
	setScreenPosition(totalNode:getChildByName('Node'), "lefttop")

	totalNode:getChildByName('closeNode'):setSwallowTouches(true)
	totalNode:getChildByName('Node'):getChildByName('Image_light'):setSwallowTouches(true)
	totalNode:getChildByName('closeNode'):addClickEventListener(function()
		totalNode:removeFromParent()
		end)
	if mail_info.planet_report.type ~= 15 then
		return
	end
	local sizeH = 250
	totalNode:getChildByName('Node'):getChildByName('Text_1'):setVisible(false)
	local cfg_city = CONF.PLANETCITY.get(info.id)
	local richText = create_MailRichText(CONF:getStringValue(cfg_city.NAME))
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
	totalNode:getChildByName('Node'):getChildByName("ship_list"):setScrollBarEnabled(false)
	local node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/CitySpyNode.csb')
	node:getChildByName('Button_1'):setVisible(false)
	node:getChildByName('Button_1'):addClickEventListener(function()
		Tips:tips(CONF:getStringValue("coming soon"))
		end)
	node:getChildByName('Text_huode'):setString(CONF:getStringValue('scout_report')) -- 侦察报告
	node:getChildByName('Text_huode'):setTextColor(cc.c4b(51,231,51,255))
	-- node:getChildByName('Text_huode'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))

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
	if Tools.isEmpty(info.enemy_data_list) == false then
		if not showShipNum or (not b1 or not b2 or not b3 ) then
			local node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/NotOpenNode.csb')
			local list = require("util.ScrollViewDelegate"):create(totalNode:getChildByName('Node'):getChildByName("ship_list"),cc.size(0,10), cc.size(820,sizeH))
			list:addElement(node)
			return totalNode
		end
	end
	if mail_info.planet_report.type == 15 then
		local height = 0
		local teamNum = 1
		for k,shiplist in ipairs(info.enemy_data_list) do
			local shipInfo = {}
			for ki,ship in ipairs(shiplist.ship_list) do
				if ship.id ~= 0 then
					local durable = Tools.getShipMaxDurable( ship )
					local maxHp = ship.attr[CONF.EShipAttr.kHP]
					local t = {ship.id,info.enemy_data_list[k].ship_hp_list[ship.position],ship.durable,durable,maxHp,ship.ship_break,ship.level}
					shipInfo[#shipInfo + 1] = t
				end
			end
			local teamNode = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/TeamNode.csb')
			teamNode:setPosition(node:getChildByName('Node_pos'):getPositionX(),node:getChildByName('Node_pos'):getPositionY()-height)
			local name = CONF:getStringValue(cfg_city.SHIP_NAME)
			if shiplist.info and Tools.isEmpty(shiplist.info) == false then
				name = shiplist.info.nickname .. " Lv."..shiplist.info.level
			end
			teamNode:getChildByName('Text_team11'):setString(CONF:getStringValue(teamName[teamNum])..':'..name)
			teamNum = teamNum + 1
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
--					teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):loadTexture('RoleIcon/'..cfg_ship.ICON_ID..'.png')
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
		sizeH = sizeH + height
	end
	if Tools.isEmpty(info.enemy_data_list) and info.result then
		local monster_ids = {}
		for k,v in ipairs(cfg_city.MONSTER_LIST) do
			if v ~= 0 then
				table.insert(monster_ids,v)
			end
		end
		local height = 50
		local teamNum = 1
		local teamNode = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/TeamNode.csb')
		teamNode:setPosition(node:getChildByName('Node_pos'):getPositionX(),node:getChildByName('Node_pos'):getPositionY()+50)
		local name = CONF:getStringValue(cfg_city.SHIP_NAME)
		teamNode:getChildByName('Text_team11'):setString(CONF:getStringValue(teamName[teamNum])..':'..name)
		teamNode:getChildByName('Image_bg1'):setVisible(false)
		for i=0,5 do
			teamNode:getChildByName('Image_17_'..i):setVisible(false)
			if Tools.isEmpty(monster_ids) == false then
				teamNode:getChildByName('Image_17_0'):setVisible(true)
			end
		end
		for i=1,5 do
			teamNode:getChildByName('node1'..i):setVisible(false)
		end
		for o,v in ipairs(monster_ids) do
			if teamNode:getChildByName('node1'..o) then
				teamNode:getChildByName('node1'..o):setVisible(true)
				teamNode:getChildByName('Image_17_'..o):setVisible(true)
				local cfg_ship = CONF.AIRSHIP.get(math.abs(v))
				local progress = require("util.ScaleProgressDelegate"):create(teamNode:getChildByName('node1'..o):getChildByName('progress'), 235)
				progress:setPercentage(100)
				teamNode:getChildByName('node1'..o):getChildByName('Text_xue'):setString(CONF:getStringValue('Attr_2'))
				teamNode:getChildByName('node1'..o):getChildByName('Text'):setString(CONF:getStringValue('durable'))
				local desT = 100
				teamNode:getChildByName('node1'..o):getChildByName('Text_num'):setString(desT..'%')
				teamNode:getChildByName('node1'..o):getChildByName('Text_num'):setPositionY(teamNode:getChildByName('node1'..o):getChildByName('Text'):getPositionY())
				teamNode:getChildByName('node1'..o):getChildByName('Text_num'):setPositionX(teamNode:getChildByName('node1'..o):getChildByName('Text'):getPositionX()+teamNode:getChildByName('node1'..o):getChildByName('Text'):getContentSize().width + 5)
				if desT < 50 then
					teamNode:getChildByName('node1'..o):getChildByName('Text_num'):setTextColor(cc.c4b(233,50,59,255))
					-- teamNode:getChildByName('node1'..o):getChildByName('Text_num'):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
				else
					teamNode:getChildByName('node1'..o):getChildByName('Text_num'):setTextColor(cc.c4b(51,231,51,255))
					-- teamNode:getChildByName('node1'..o):getChildByName('Text_num'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
				end
				teamNode:getChildByName('node1'..o):getChildByName('progress'):setPositionX(teamNode:getChildByName('node1'..o):getChildByName('Text_xue'):getPositionX()+10+teamNode:getChildByName('node1'..o):getChildByName('Text_xue'):getContentSize().width)
				teamNode:getChildByName('node1'..o):getChildByName('jdt_bottom02_53'):setPositionX(teamNode:getChildByName('node1'..o):getChildByName('Text_xue'):getPositionX()+10+teamNode:getChildByName('node1'..o):getChildByName('Text_xue'):getContentSize().width)
				teamNode:getChildByName('node1'..o):getChildByName('Text_nai'):setString('100%')
--				teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):loadTexture('RoleIcon/'..cfg_ship.ICON_ID..'.png')
                teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon'):setVisible(false)
                teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon2'):setVisible(true)
                teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('icon2'):setTexture("ShipImage/"..cfg_ship.ICON_ID..".png")
				teamNode:getChildByName('node1'..o):getChildByName('shipIcon'):getChildByName('Image_1'):loadTexture("RankLayer/ui/ui_avatar_" .. cfg_ship.QUALITY .. ".png")
				height = height + 90
			end
		end
		sizeH = sizeH + height
		node:addChild(teamNode)
	end
	node:getChildByName('Image_7'):setVisible(Tools.isEmpty(info.enemy_data_list[2]) == false)
	node:getChildByName('Text_3'):setVisible(Tools.isEmpty(info.enemy_data_list[2]) == false)
	local list = require("util.ScrollViewDelegate"):create(totalNode:getChildByName('Node'):getChildByName("ship_list"),cc.size(0,10), cc.size(820,sizeH))
	list:addElement(node)
	
	return totalNode
end

return MailDetailAttackType_citySpy