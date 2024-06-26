local MailDetailType_spy = class("MailDetailType_spy")

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
function MailDetailType_spy:initMailDetail(mail_info,data)
	if Tools.isEmpty(mail_info) or  Tools.isEmpty(mail_info.planet_report) then
		return
	end
	if mail_info.planet_report.type ~= 4 and mail_info.planet_report.type ~= 5 then
		return
	end 
	local info = mail_info.planet_report
	local node = require("app.ExResInterface"):getInstance():FastLoad("MailLayer/MailDetailRuinsNode.csb")
	setScreenPosition(node:getChildByName('closeNode'), "righttop")
	setScreenPosition(node:getChildByName('Node'), "lefttop")

	node:getChildByName('closeNode'):setSwallowTouches(true)
	node:getChildByName('Node'):getChildByName('Image_light'):setSwallowTouches(true)
	node:getChildByName('closeNode'):addClickEventListener(function()
		node:removeFromParent()
		end)
	if info.result and info.result == true then
		node:getChildByName('Node'):getChildByName('Text_huode'):setString(CONF:getStringValue('Salvage success'))
		node:getChildByName('Node'):getChildByName('Text_huode'):setTextColor(cc.c4b(51,231,51,255))
		-- node:getChildByName('Node'):getChildByName('Text_huode'):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
	else
		node:getChildByName('Node'):getChildByName('Text_huode'):setString(CONF:getStringValue('Salvage failure'))
		node:getChildByName('Node'):getChildByName('Text_huode'):setTextColor(cc.c4b(233,50,59,255))
		-- node:getChildByName('Node'):getChildByName('Text_huode'):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
	end
	local cfg_info = CONF.PLANET_RUINS.get(info.id)
	local timeTab = os.date("*t", mail_info.stamp)
	node:getChildByName('Node'):getChildByName('Text_1'):setString('Lv.'..cfg_info.LEVEL..' '..CONF:getStringValue(cfg_info.NAME))
	if timeTab.day < 10 then timeTab.day = '0'..timeTab.day end
	if timeTab.month < 10 then timeTab.month = '0'..timeTab.month end
	if timeTab.hour < 10 then timeTab.hour = '0'..timeTab.hour end
	if timeTab.min < 10 then timeTab.min = '0'..timeTab.min end
	if timeTab.sec < 10 then timeTab.sec = '0'..timeTab.sec end
	node:getChildByName('Node'):getChildByName('Text_2'):setString('('..info.pos_list[1].x..','..info.pos_list[1].y..')  '..timeTab.day..'/'..timeTab.month..'/'..timeTab.year..'  '..timeTab.hour..':'..timeTab.min..':'..timeTab.sec)
	node:getChildByName('Node'):getChildByName('Button_pos'):setPosition(node:getChildByName('Node'):getChildByName('Text_2'):getPosition())
	node:getChildByName('Node'):getChildByName('Button_pos'):addClickEventListener(function()
			myApp:pushView('PlanetScene/PlanetScene',{move_info = {pos = {x=info.pos_list[1].x,y=info.pos_list[1].y},node_id_list = {getNodeIDByGlobalPos(info.pos_list[1])}} })
		end)
	local posX = node:getChildByName('Node'):getChildByName('Text_1'):getPositionX()
	local conW = node:getChildByName('Node'):getChildByName('Text_1'):getContentSize().width
	local nodeW = node:getChildByName('Node'):getChildByName('icon'):getContentSize().width
	node:getChildByName('Node'):getChildByName('icon'):setPositionX( posX+conW+nodeW+15 )
	node:getChildByName('Node'):getChildByName('Text_2'):setPositionX( posX+conW+nodeW+17 )
	local sizeH = 0
	
	node:getChildByName('Node'):getChildByName("ship_list"):setScrollBarEnabled(false)
	local new_node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/RuinsGetNode.csb')
	local list = require("util.ScrollViewDelegate"):create(new_node:getChildByName("ship_list"),cc.size(0,10), cc.size(100,100))
	local add_node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/RuinsGetNode.csb')
	local add_list = require("util.ScrollViewDelegate"):create(add_node:getChildByName("ship_list"),cc.size(0,10), cc.size(100,100))
	new_node:getChildByName("ship_list"):setScrollBarEnabled(false)
	new_node:getChildByName('Text_des'):setVisible(false)
	new_node:getChildByName('Text_1'):setString("没有获得物品")
	if Tools.isEmpty(info.item_list_list) == false then
		local noReward = true
		if Tools.isEmpty(info.item_list_list[1]) == false and Tools.isEmpty(info.item_list_list[1].item_list) == false then
			for k,v in ipairs(info.item_list_list[1].item_list) do
				if v.id ~= 0 then
					noReward = false
					break
				end
			end
		end
		if not  noReward then
			new_node:getChildByName('Text_1'):setString(CONF:getStringValue('salvage_finish_string5'))
			new_node:getChildByName('Text_des'):setVisible(false)
			for k,v in ipairs(info.item_list_list[1].item_list) do
				if v.id ~= 0 then
					local itemNode = require("util.ItemNode"):create():init(v.id, v.num)
					list:addElement(itemNode)
				end
			end
		end
		if Tools.isEmpty(info.item_list_list[2]) == false then
			if Tools.isEmpty(info.item_list_list[2].item_list) then -- 没有工会
				if noReward then -- 没有奖励
					new_node:getChildByName('Text_des'):setVisible(true)
					new_node:getChildByName('Text_1'):setVisible(false)
					new_node:getChildByName('ship_list'):setVisible(false)
					new_node:getChildByName('Text_des'):setString(CONF:getStringValue('salvage_finish_string1')..'\n\n'..CONF:getStringValue('salvage_finish_string2'))
				else
					local add_node = require("app.ExResInterface"):getInstance():FastLoad('MailLayer/DetailAttackSmallNode/RuinsGetNode.csb')
					add_node:setPosition(new_node:getChildByName('ship_list'):getPositionX()-10,new_node:getChildByName('ship_list'):getPositionY()-new_node:getChildByName('ship_list'):getContentSize().height)
					add_node:getChildByName('Text_des'):setVisible(false)
					add_node:getChildByName('Text_1'):setString(CONF:getStringValue('salvage_string1'))
					new_node:addChild(add_node)
				end
			else
				if noReward then
					new_node:getChildByName('Text_des'):setVisible(false)
					new_node:getChildByName('ship_list'):setVisible(false)
					new_node:getChildByName('Text_1'):setString(CONF:getStringValue('salvage_finish_string1'))
					add_node:getChildByName("ship_list"):setScrollBarEnabled(false)
					for k,v in ipairs(info.item_list_list[2].item_list) do
						if v.id ~= 0 then
							local itemNode = require("util.ItemNode"):create():init(v.id, v.num)
							itemNode:getChildByName('Image_1'):setVisible(true)
							add_list:addElement(itemNode)
						end
					end
					add_node:getChildByName('Text_des'):setVisible(false)
					add_node:getChildByName('Text_1'):setString(CONF:getStringValue('salvage_string2')..CONF:getStringValue('salvage_finish_string2'))
					add_node:setPosition(new_node:getChildByName('ship_list'):getPositionX()-24,new_node:getChildByName('ship_list'):getPositionY()-5)
					new_node:addChild(add_node)
				else
					add_node:setPosition(new_node:getChildByName('ship_list'):getPositionX()-24,new_node:getChildByName('ship_list'):getPositionY()-new_node:getChildByName('ship_list'):getContentSize().height)
					add_node:getChildByName("ship_list"):setScrollBarEnabled(false)
					for k,v in ipairs(info.item_list_list[2].item_list) do
						if v.id ~= 0 then
							local itemNode = require("util.ItemNode"):create():init(v.id, v.num)
							itemNode:getChildByName('Image_1'):setVisible(true)
							add_list:addElement(itemNode)
						end
					end
					add_node:getChildByName('Text_des'):setVisible(false)
					add_node:getChildByName('Text_1'):setString(CONF:getStringValue('salvage_string3'))
					new_node:addChild(add_node)
				end
			end
		end
	end
	local item_count = new_node:getChildByName("ship_list"):getChildrenCount()
	local size_width = new_node:getChildByName("ship_list"):getContentSize().width
	local can_item_count = math.floor(size_width/100)
	if item_count <= can_item_count then
		new_node:getChildByName("ship_list"):setTouchEnabled(false)
	end
	local item_count = add_node:getChildByName("ship_list"):getChildrenCount()
	local size_width = add_node:getChildByName("ship_list"):getContentSize().width
	local can_item_count = math.floor(size_width/100)
	if item_count <= can_item_count then
		add_node:getChildByName("ship_list"):setTouchEnabled(false)
	end
	local list_big = require("util.ScrollViewDelegate"):create(node:getChildByName('Node'):getChildByName("ship_list"),cc.size(0,10), cc.size(700,sizeH))
	node:getChildByName('Node'):getChildByName("ship_list"):setScrollBarEnabled(false)
	list_big:addElement(new_node)
	return node
end

return MailDetailType_spy