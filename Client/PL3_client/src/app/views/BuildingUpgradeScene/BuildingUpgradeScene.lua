local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local BuildingUpgradeScene = class("BuildingUpgradeScene", cc.load("mvc").ViewBase)

BuildingUpgradeScene.RESOURCE_FILENAME = "NewBuildingUpgradeScene/NewBuildingUpgradeScene.csb"

BuildingUpgradeScene.RUN_TIMELINE = true

BuildingUpgradeScene.NEED_ADJUST_POSITION = true

BuildingUpgradeScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil

BuildingUpgradeScene.lagHelper = require("util.ExLagHelper"):getInstance()
BuildingUpgradeScene.IS_SCENE_TRANSFER_EFFECT = false

function BuildingUpgradeScene:onCreate( data )
	if( self.IS_SCENE_TRANSFER_EFFECT == false ) then
		self.data_ = data 
	else

	-- EDIT BY WJJ 180702
	if data then
		self.data_ = data
	end
	if ((data and data.sfx) or true ) then
		if( data and data.sfx ) then
			data.sfx = false
		end
		local view = self:getApp():createView("CityScene/TransferScene",{from = "BuildingUpgradeScene/BuildingUpgradeScene" ,state = "enter"})
		self:addChild(view)
	end
	end
end


function BuildingUpgradeScene:onEnter()
  
	printInfo("BuildingUpgradeScene:onEnter()")

end

function BuildingUpgradeScene:onExit()
	
	printInfo("BuildingUpgradeScene:onExit()")
end

function BuildingUpgradeScene:resetRes( ... )
	local rn = self:getResourceNode()
	local res_node = rn:getChildByName("res_node")
	for i=1,4 do
		res_node:getChildByName("res_text_"..i):setString(formatRes(player:getResByIndex(i)))
	end
	res_node:getChildByName("res_text_5"):setString(player:getMoney())
end

function BuildingUpgradeScene:createMainNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/MainNode.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local next_conf

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)
	if not is_max then
		next_conf =	CONF["BUILDING_"..self.data_.building_num].get(info.level+1)
	else
		next_conf = conf
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	if is_max then
		info_node:getChildByName("res_add"):setVisible(false)
		info_node:getChildByName("home_add"):setVisible(false)
		info_node:getChildByName("planet_add"):setVisible(false)
		info_node:getChildByName("army_add"):setVisible(false)
	end

	info_node:getChildByName("res"):setString(CONF:getStringValue("home_yield_addition"))
	info_node:getChildByName("home"):setString(CONF:getStringValue("opening_resource_fields"))
	info_node:getChildByName("planet"):setString(CONF:getStringValue("acquisition_addition"))
	info_node:getChildByName("base"):setString(CONF:getStringValue("space_appearance"))
	info_node:getChildByName("army"):setString(CONF:getStringValue("expedition_queue"))

	info_node:getChildByName("res_now"):setString((conf.HOME_PRODUCTION*100).."%")
	info_node:getChildByName("res_add"):setString("+"..((next_conf.HOME_PRODUCTION - conf.HOME_PRODUCTION)*100).."%")

	info_node:getChildByName("home_now"):setString(conf.RESOURCE_NUM)
	info_node:getChildByName("home_add"):setString("+"..(next_conf.RESOURCE_NUM - conf.RESOURCE_NUM))

	info_node:getChildByName("army_now"):setString(conf.ARMY_NUM)
	info_node:getChildByName("army_add"):setString("+"..(next_conf.ARMY_NUM - conf.ARMY_NUM))

	info_node:getChildByName("planet_now"):setString((conf.COLLECT*100).."%")
	info_node:getChildByName("planet_add"):setString("+"..((next_conf.COLLECT - conf.COLLECT)*100).."%")

	if next_conf.RESOURCE_NUM - conf.RESOURCE_NUM == 0 then
		info_node:getChildByName("home_add"):setVisible(false)
		info_node:getChildByName("home_now"):setPositionX(info_node:getChildByName("home_now"):getPositionX() + info_node:getChildByName("home_now"):getContentSize().width/2)
	end

	if next_conf.ARMY_NUM - conf.ARMY_NUM == 0 then
		info_node:getChildByName("army_add"):setVisible(false)
		info_node:getChildByName("army_now"):setPositionX(info_node:getChildByName("army_now"):getPositionX() + info_node:getChildByName("army_now"):getContentSize().width/2)
	end

	if next_conf.HOME_PRODUCTION - conf.HOME_PRODUCTION == 0 then
		info_node:getChildByName("res_add"):setVisible(false)
		info_node:getChildByName("res_now"):setPositionX(info_node:getChildByName("res_now"):getPositionX() + info_node:getChildByName("res_now"):getContentSize().width/2)
	end

	if next_conf.COLLECT - conf.COLLECT == 0 then
		info_node:getChildByName("planet_add"):setVisible(false)
		info_node:getChildByName("planet_now"):setPositionX(info_node:getChildByName("planet_now"):getPositionX() + info_node:getChildByName("planet_now"):getContentSize().width/2)
	end

	if next_conf.IMAGE ~= conf.IMAGE then
		info_node:getChildByName("base_now"):setString(CONF:getStringValue("space_change"))
	else
		info_node:getChildByName("base"):setVisible(false)
		info_node:getChildByName("base_now"):setVisible(false)
		info_node:getChildByName("ware_house_info_2_0_0_0"):setVisible(false)
		info_node:getChildByName("bg"):setContentSize(cc.size(info_node:getChildByName("bg"):getContentSize().width, info_node:getChildByName("bg"):getContentSize().height-100))
	end

	return info_node

end

function BuildingUpgradeScene:createRepairNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/RepairNode.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local next_conf

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	if not is_max then
		next_conf =	CONF["BUILDING_"..self.data_.building_num].get(info.level+1)
	else
		next_conf = conf
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)

	if is_max then
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	info_node:getChildByName("speed"):setString(CONF:getStringValue("repair_speed_add"))
	info_node:getChildByName("speed_now"):setString(conf.REPAIR_SPEED)
	info_node:getChildByName("speed_add"):setString("+"..(next_conf.REPAIR_SPEED - conf.REPAIR_SPEED))

	if is_max then
		info_node:getChildByName("speed_add"):setVisible(false)
		info_node:getChildByName("speed_now"):setPositionX(info_node:getChildByName("speed_now"):getPositionX() + info_node:getChildByName("speed_now"):getContentSize().width/2)
	end

	return info_node
end

function BuildingUpgradeScene:createShipDevelopNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/TextNode.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local next_conf

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)
	if not is_max then
		next_conf =	CONF["BUILDING_"..self.data_.building_num].get(info.level+1)
	else
		next_conf = conf
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	if next_conf.BLUEPRINT_LIST then
		info_node:getChildByName("text"):setString(CONF:getStringValue("open_drawings"))
	else
		local has = false
		for i,v in ipairs(CONF["BUILDING_"..self.data_.building_num].getIDList()) do
			if v > info.level+1 then
				local conf = CONF["BUILDING_"..self.data_.building_num].get(v)
				if conf.BLUEPRINT_LIST then
					has = true
					info_node:getChildByName("text"):setString("Lv."..v..CONF:getStringValue("unlocked_drawings"))
					break
				end
			end
		end

		if not has then
			info_node:getChildByName("text"):setString(CONF:getStringValue("coming soon"))

		end

	end

	if is_max then
		info_node:getChildByName("text"):setString(CONF:getStringValue("coming soon"))
	end


	return info_node
end

function BuildingUpgradeScene:createWeaponDevelopNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/TextNode.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local next_conf

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)
	if not is_max then
		next_conf =	CONF["BUILDING_"..self.data_.building_num].get(info.level+1)
	else
		next_conf = conf
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	if next_conf.WEAPON_LIST then
		info_node:getChildByName("text"):setString(CONF:getStringValue("open_skills"))
	else
		local has = false
		for i,v in ipairs(CONF["BUILDING_"..self.data_.building_num].getIDList()) do
			if v > info.level+1 then
				local conf = CONF["BUILDING_"..self.data_.building_num].get(v)
				if conf.WEAPON_LIST then
					has = true
					info_node:getChildByName("text"):setString("Lv."..v..CONF:getStringValue("unlocked_skills"))
					break
				end
			end
		end

		if not has then
			info_node:getChildByName("text"):setString(CONF:getStringValue("coming soon"))

		end

	end

	if is_max then
		info_node:getChildByName("text"):setString(CONF:getStringValue("coming soon"))
	end


	return info_node
end

function BuildingUpgradeScene:createTechNologyNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/TextNode.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local next_conf

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)
	if not is_max then
		next_conf =	CONF["BUILDING_"..self.data_.building_num].get(info.level+1)
	else
		next_conf = conf
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	if next_conf.TECH_LIST then
		info_node:getChildByName("text"):setString(CONF:getStringValue("open_technology"))
	else
		local has = false
		for i,v in ipairs(CONF["BUILDING_"..self.data_.building_num].getIDList()) do
			if v > info.level+1 then
				local conf = CONF["BUILDING_"..self.data_.building_num].get(v)
				if conf.TECH_LIST then
					has = true
					info_node:getChildByName("text"):setString("Lv."..v..CONF:getStringValue("unlocked_technology"))
					break
				end
			end
		end

		if not has then
			info_node:getChildByName("text"):setString(CONF:getStringValue("coming soon"))

		end

	end

	if is_max then
		info_node:getChildByName("text"):setString(CONF:getStringValue("coming soon"))
	end


	return info_node
end

function BuildingUpgradeScene:createWareHouseNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/WareHouseNode.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	info_node:getChildByName("res_name"):setString(CONF:getStringValue("resource"))
	info_node:getChildByName("res_max_has_num"):setString(CONF:getStringValue("currency upper"))
	info_node:getChildByName("res_min_has_num"):setString(CONF:getStringValue("protect currency"))
	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)

	if is_max then
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	for i=1,4 do
		local res = info_node:getChildByName("res_"..i)
		res:getChildByName("name"):setString(CONF:getStringValue("IN_"..(i+2).."001"))

		if is_max then
			res:getChildByName("max_add_num"):setVisible(false)
			res:getChildByName("min_add_num"):setVisible(false)
		else
			local diff_max = CONF["BUILDING_"..self.data_.building_num].get(info.level+1).RESOURCE_UPPER_LIMIT[i] - conf.RESOURCE_UPPER_LIMIT[i]
			local diff_min = CONF["BUILDING_"..self.data_.building_num].get(info.level+1).RESOURCE_PROTECT_LIMIT[i] - conf.RESOURCE_PROTECT_LIMIT[i]
			res:getChildByName("max_add_num"):setString("+"..diff_max)
			res:getChildByName("min_add_num"):setString("+"..diff_min)

			if diff_max == 0 then
				res:getChildByName("max_add_num"):setVisible(false)
			end

			if diff_min == 0 then
				res:getChildByName("min_add_num"):setVisible(false)
			end
		end

		res:getChildByName('max_num'):setString(conf.RESOURCE_UPPER_LIMIT[i])
		res:getChildByName("min_num"):setString(conf.RESOURCE_PROTECT_LIMIT[i])
		if conf.RESOURCE_PROTECT_LIMIT[i] == 0 then
			res:getChildByName("min_num"):setVisible(false)
		end
		-- res:getChildByName("max_add_num"):setPositionX(res:getChildByName('max_num'):getPositionX() + res:getChildByName('max_num'):getContentSize().width)
		-- res:getChildByName("min_add_num"):setPositionX(res:getChildByName('min_num'):getPositionX() + res:getChildByName('min_num'):getContentSize().width)
	end

	return info_node
end

function BuildingUpgradeScene:createSpyNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/SpyNode.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local next_conf

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)
	if not is_max then
		next_conf =	CONF["BUILDING_"..self.data_.building_num].get(info.level+1)
	else
		next_conf = conf
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	local str = ""
	for i,v in ipairs(conf.BE_ATTACK) do
		str = str..CONF:getStringValue("atk_"..v).."\n"
	end


	-- str = ""
	for i,v in ipairs(conf.SCOUT) do
		str = str..CONF:getStringValue("hit_"..v).."\n"
	end

	info_node:getChildByName("text"):setString(str)
	info_node:getChildByName("text"):ignoreContentAdaptWithSize(false)
	
	info_node:getChildByName("text"):getVirtualRenderer():setLineBreakWithoutSpace(true)
	info_node:getChildByName("text"):getVirtualRenderer():setMaxLineWidth(460) 
	info_node:getChildByName("text"):setContentSize(info_node:getChildByName("text"):getVirtualRenderer():getContentSize())
	-- info_node:getChildByName("text_2"):setString(str)


	local ssr = ""

	for i,v in ipairs(next_conf.BE_ATTACK ) do
		if i > #conf.BE_ATTACK then
			ssr = ssr..CONF:getStringValue("atk_"..v).."\n"
		end
	end

	local ssr_2 = ""

	for i,v in ipairs(next_conf.SCOUT ) do
		if i > #conf.SCOUT then
			ssr = ssr..CONF:getStringValue("hit_"..v).."\n"
		end
	end


	if ssr ~= "" then
		info_node:getChildByName("green_text"):setVisible(true)
	end

	info_node:getChildByName("green_text"):setString(ssr)
	info_node:getChildByName("green_text"):getVirtualRenderer():setLineBreakWithoutSpace(true)
	info_node:getChildByName("green_text"):getVirtualRenderer():setMaxLineWidth(460) 
	info_node:getChildByName("green_text"):setContentSize(info_node:getChildByName("green_text"):getVirtualRenderer():getContentSize())
	info_node:getChildByName("green_text"):setPositionY(info_node:getChildByName("text"):getPositionY() - info_node:getChildByName("text"):getVirtualRenderer():getContentSize().height + 20)

	info_node:getChildByName("text_2"):setPositionY(info_node:getChildByName("green_text"):getPositionY() - info_node:getChildByName("green_text"):getVirtualRenderer():getContentSize().height)

	if ssr_2 ~= "" then
		info_node:getChildByName("green_text_2"):setVisible(true)
		info_node:getChildByName("green_text_2"):setString(ssr_2)
		info_node:getChildByName("green_text_2"):getVirtualRenderer():setLineBreakWithoutSpace(true)
		info_node:getChildByName("green_text_2"):getVirtualRenderer():setMaxLineWidth(460) 
		info_node:getChildByName("green_text_2"):setContentSize(info_node:getChildByName("green_text_2"):getVirtualRenderer():getContentSize())
		info_node:getChildByName("green_text_2"):setPositionY(info_node:getChildByName("text_2"):getPositionY() - info_node:getChildByName("text_2"):getVirtualRenderer():getContentSize().height + 20)
	end

	info_node:getChildByName("bg"):setContentSize(cc.size(info_node:getChildByName("bg"):getContentSize().width, -(info_node:getChildByName("text"):getPositionY() - info_node:getChildByName("text"):getVirtualRenderer():getContentSize().height - info_node:getChildByName("green_text"):getVirtualRenderer():getContentSize().height - info_node:getChildByName("text_2"):getVirtualRenderer():getContentSize().height - info_node:getChildByName("green_text_2"):getVirtualRenderer():getContentSize().height)))

	return info_node
end

function BuildingUpgradeScene:createDefendNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/DefendNode.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local next_conf

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)
	if not is_max then
		next_conf =	CONF["BUILDING_"..self.data_.building_num].get(info.level+1)
	else
		next_conf = conf
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	info_node:getChildByName("army"):setString(CONF:getStringValue("turret_force"))
	info_node:getChildByName("res"):setString(CONF:getStringValue("value"))

	info_node:getChildByName("army_now"):setString((conf.SHOW_POWER))
	info_node:getChildByName("army_add"):setString("+"..((next_conf.SHOW_POWER - conf.SHOW_POWER)))

	info_node:getChildByName("res_now"):setString(conf.CITY_DEFENCE)
	info_node:getChildByName("res_add"):setString("+"..(next_conf.CITY_DEFENCE - conf.CITY_DEFENCE))

	if next_conf.SHOW_POWER - conf.SHOW_POWER == 0 then
		info_node:getChildByName("army_add"):setVisible(false)
		info_node:getChildByName("army_now"):setPositionX(info_node:getChildByName("army_now"):getPositionX() + info_node:getChildByName("army_now"):getContentSize().width/2)
	end

	if next_conf.CITY_DEFENCE - conf.CITY_DEFENCE == 0 then
		info_node:getChildByName("res_add"):setVisible(false)
		info_node:getChildByName("res_now"):setPositionX(info_node:getChildByName("res_now"):getPositionX() + info_node:getChildByName("res_now"):getContentSize().width/2)
	end


	return info_node
end

function BuildingUpgradeScene:createDiplomacyNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/DiplomacyNode.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local next_conf

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)
	if not is_max then
		next_conf =	CONF["BUILDING_"..self.data_.building_num].get(info.level+1)
	else
		next_conf = conf
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	info_node:getChildByName("army"):setString(CONF:getStringValue("number_helped"))
	info_node:getChildByName("res"):setString(CONF:getStringValue("upper_limit"))
	info_node:getChildByName("planet"):setString(CONF:getStringValue("reduce_time"))

	info_node:getChildByName("res_now"):setString((conf.GUARDE_NUM))
	info_node:getChildByName("res_add"):setString("+"..((next_conf.GUARDE_NUM - conf.GUARDE_NUM)))

	info_node:getChildByName("army_now"):setString(conf.HELP_TIMES)
	info_node:getChildByName("army_add"):setString("+"..(next_conf.HELP_TIMES - conf.HELP_TIMES))

	info_node:getChildByName("planet_now"):setString(conf.HELP_SUB_TIME)
	info_node:getChildByName("planet_add"):setString("+"..(next_conf.HELP_SUB_TIME - conf.HELP_SUB_TIME))

	if next_conf.HELP_TIMES - conf.HELP_TIMES == 0 then
		info_node:getChildByName("army_add"):setVisible(false)
		info_node:getChildByName("army_now"):setPositionX(info_node:getChildByName("army_now"):getPositionX() + info_node:getChildByName("army_now"):getContentSize().width/2)
	end

	if next_conf.GUARDE_NUM - conf.GUARDE_NUM == 0 then
		info_node:getChildByName("res_add"):setVisible(false)
		info_node:getChildByName("res_now"):setPositionX(info_node:getChildByName("res_now"):getPositionX() + info_node:getChildByName("res_now"):getContentSize().width/2)
	end

	if next_conf.HELP_SUB_TIME - conf.HELP_SUB_TIME == 0 then
		info_node:getChildByName("planet_add"):setVisible(false)
		info_node:getChildByName("planet_now"):setPositionX(info_node:getChildByName("planet_now"):getPositionX() + info_node:getChildByName("planet_now"):getContentSize().width/2)
	end


	return info_node
end

function BuildingUpgradeScene:createWarWorkshopNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/WarWorkshopNode.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local next_conf

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)
	if not is_max then
		next_conf =	CONF["BUILDING_"..self.data_.building_num].get(info.level+1)
	else
		next_conf = conf
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	info_node:getChildByName("res"):setString(CONF:getStringValue("limit_resources"))
	info_node:getChildByName("army"):setString(CONF:getStringValue("spaceships_num"))

	info_node:getChildByName("army_now"):setString(conf.AIRSHIP_NUM)
	info_node:getChildByName("army_add"):setString("+"..(next_conf.AIRSHIP_NUM - conf.AIRSHIP_NUM))


	if next_conf.AIRSHIP_NUM - conf.AIRSHIP_NUM == 0 then
		info_node:getChildByName("army_add"):setVisible(false)
		info_node:getChildByName("army_now"):setPositionX(info_node:getChildByName("army_now"):getPositionX() + info_node:getChildByName("army_now"):getContentSize().width/2)
	end

	local item_list = {3001,4001,5001,6001}

	for i,v in ipairs(conf.CARRYING_RESOURCES) do
		if i > 1 then
			local item_conf = CONF.ITEM.get(item_list[i])
			info_node:getChildByName("res_"..(i-1).."_name"):setString(CONF:getStringValue(item_conf.NAME_ID))
			info_node:getChildByName("res_"..(i-1).."_icon"):setTexture("ItemIcon/"..item_conf.ICON_ID..".png")
			info_node:getChildByName("res_"..(i-1).."_add"):setString("+"..(next_conf.CARRYING_RESOURCES[i] - v))
			info_node:getChildByName("res_"..(i-1).."_now"):setString(v)

			info_node:getChildByName("res_"..(i-1).."_add"):setPositionX(info_node:getChildByName("res_"..(i-1).."_now"):getPositionX() + info_node:getChildByName("res_"..(i-1).."_now"):getContentSize().width)

			if next_conf.CARRYING_RESOURCES[i] - v == 0 then
				info_node:getChildByName("res_"..(i-1).."_add"):setVisible(false)
			end

		end
	end


	return info_node
end

function BuildingUpgradeScene:createForgeNode( ... )
	local info_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/ForgeNode2.csb")
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local next_conf

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	info_node:getChildByName("next_level"):setString(CONF:getStringValue("next level").." Lv."..info.level+1)
	if not is_max then
		next_conf =	CONF["BUILDING_"..self.data_.building_num].get(info.level+1)
	else
		next_conf = conf
		info_node:getChildByName("next_level"):setString(CONF:getStringValue("build max"))
	end

	info_node:getChildByName("res"):setString(CONF:getStringValue("depletion_of_resources"))
	info_node:getChildByName("army"):setString(CONF:getStringValue("reduce_forging_time"))
	info_node:getChildByName("equip"):setString(CONF:getStringValue("activating_equip"))

	info_node:getChildByName("army_now"):setString(conf.EQUIP_FORGE_SPEED)
	info_node:getChildByName("army_add"):setString("+"..(next_conf.EQUIP_FORGE_SPEED - conf.EQUIP_FORGE_SPEED))


	if next_conf.EQUIP_FORGE_SPEED - conf.EQUIP_FORGE_SPEED == 0 then
		info_node:getChildByName("army_add"):setVisible(false)
		info_node:getChildByName("army_now"):setPositionX(info_node:getChildByName("army_now"):getPositionX() + info_node:getChildByName("army_now"):getContentSize().width/2)
	end

	local item_list = {3001,4001,5001,6001}

	for i,v in ipairs(conf.RES) do
		local item_conf = CONF.ITEM.get(item_list[i])
		info_node:getChildByName("res_"..(i).."_name"):setString(CONF:getStringValue(item_conf.NAME_ID))
		info_node:getChildByName("res_"..(i).."_icon"):setTexture("ItemIcon/"..item_conf.ICON_ID..".png")
		info_node:getChildByName("res_"..(i).."_add"):setString("+"..(next_conf.RES[i] - v))
		info_node:getChildByName("res_"..(i).."_now"):setString(v)

		info_node:getChildByName("res_"..(i).."_add"):setPositionX(info_node:getChildByName("res_"..(i).."_now"):getPositionX() + info_node:getChildByName("res_"..(i).."_now"):getContentSize().width)

		if next_conf.RES[i] - v == 0 then
			info_node:getChildByName("res_"..(i).."_add"):setVisible(false)
		end
	end

	local str = ""
	for i,v in ipairs(next_conf.DEBLOCKING_EQUIP) do
		local equip_conf = CONF.EQUIP.get(v)
		str = str.."("..CONF:getStringValue("Equip_type_"..equip_conf.TYPE)..")Lv."..equip_conf.LEVEL..CONF:getStringValue(equip_conf.NAME_ID).."\n"
	end

	info_node:getChildByName("equip_text"):setString(str)
--	info_node:getChildByName("bg"):setContentSize(cc.size(info_node:getChildByName("bg"):getContentSize().width, info_node:getChildByName("bg"):getContentSize().height + info_node:getChildByName("equip_text"):getContentSize().height))

	return info_node
end

function BuildingUpgradeScene:resetUI( ... )
	local rn = self:getResourceNode()
	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)

	rn:getChildByName("building"):setTexture(CONF.EBuildingICON[self.data_.building_num])

	rn:getChildByName("title"):setString(CONF:getStringValue("BuildingName_"..self.data_.building_num)) 

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	if is_max then
		rn:getChildByName("time"):setVisible(false)
		rn:getChildByName("btn_upgrade"):setVisible(false)
		rn:getChildByName("auto_upgrade"):setVisible(false)
		rn:getChildByName("auto_upgrade2"):setVisible(false)
		
	else
		rn:getChildByName("time"):setVisible(true)

		rn:getChildByName("auto_upgrade"):setVisible(false)
		rn:getChildByName("auto_upgrade2"):setVisible(false)

		local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, self.data_.building_num, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), player:getPlayerGroupTech())
		if info.upgrade_begin_time > 0 then 
			cd = cd - (player:getServerTime() - info.upgrade_begin_time)
		end
		local bFree = cd <= CONF.VIP.get(player:getVipLevel()).BUILDING_FREE

		local auto_upgrade = rn:getChildByName("auto_upgrade")
		if player:isGroup() and info.upgrade_begin_time > 0 and not self.isHelp and not bFree then
			auto_upgrade = rn:getChildByName("auto_upgrade2")
		end


		if info.upgrade_begin_time > 0 then
			rn:getChildByName("btn_upgrade"):setVisible(false)
			auto_upgrade:setVisible(true)
		else
			rn:getChildByName("btn_upgrade"):setVisible(true)
			auto_upgrade:setVisible(false)
		end

	
		rn:getChildByName("time"):setString(CONF:getStringValue("time")..":"..formatTime(cd))

		if bFree then
			auto_upgrade:getChildByName("point"):setVisible(false)
			-- rn:getChildByName("auto_upgrade"):getChildByName("pointnum"):setString(CONF:getStringValue("free"))
			auto_upgrade:getChildByName("text_0"):setString(CONF:getStringValue("free"))
			auto_upgrade:getChildByName("text_0"):setVisible(true)
			auto_upgrade:getChildByName("pointnum"):setVisible(false)
		else
			auto_upgrade:getChildByName("text_0"):setVisible(false)
			auto_upgrade:getChildByName("pointnum"):setVisible(true)
			auto_upgrade:getChildByName("point"):setVisible(true)
			auto_upgrade:getChildByName("pointnum"):setString(player:getSpeedUpNeedMoney(cd))

		end

		if player:isGroup() then
			if info.upgrade_begin_time > 0 and not bFree then
				if self.isHelp then
					rn:getChildByName("help"):setVisible(false)
				else
					rn:getChildByName("help"):setVisible(true)
				end
			else
				rn:getChildByName("help"):setVisible(false)
			end
		else
			rn:getChildByName("help"):setVisible(false)
		end

	end

	-- self:resetList()
end

function BuildingUpgradeScene:resetList( ... )
	self.svd_:clear()

	local info = player:getBuildingInfo(self.data_.building_num)
	local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
	local node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/ListNode.csb")
	node:getChildByName("right_title"):setString(CONF:getStringValue("level condition"))
	node:getChildByName("build_text"):setString(CONF:getStringValue("build in"))
	node:getChildByName("max_text"):setString(CONF:getStringValue("build max"))
	animManager:runAnimByCSB(node:getChildByName("build_sfx"), "NewBuildingUpgradeScene/sfx/jianzaozhong/jianzaozhong.csb", "1")

	local is_max = false
	if info.level == CONF["BUILDING_"..self.data_.building_num].get(#CONF["BUILDING_"..self.data_.building_num].getIDList()).ID then
		is_max = true
	end

	local pos = cc.p(node:getChildByName("build_pos"):getPosition())
	local num = 0

	if not is_max then
		if info.upgrade_begin_time > 0 then
			node:getChildByName("build_text"):setVisible(true)
			node:getChildByName("build_sfx"):setVisible(true)
		else
			local diff_x = 220
			local diff_y = 50
			if self.data_.building_num == CONF.EBuilding.kMain then
				if conf.PLAYER_LEVEL and conf.PLAYER_LEVEL ~= 0 then
					local build_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/ListBuildItem.csb")
					build_node:getChildByName("btn"):setVisible(false)
					build_node:getChildByName("info"):setString(CONF:getStringValue("grade").." Lv."..conf.PLAYER_LEVEL)
					if player:getLevel() < conf.PLAYER_LEVEL then
						build_node:getChildByName("info"):setTextColor(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255))
						-- build_node:getChildByName("info"):enableShadow(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255), cc.size(0.5,0.5))
					end
					build_node:setPosition(cc.p(pos.x + (num%2)*diff_x, pos.y - (math.floor(num/2))*diff_y))
					node:addChild(build_node)

					num = num + 1
				end
			end
			if num % 2 == 1 then
				num = num + 1
			end
			if conf.BUILDING_TYPE then
				local build_nums = {13,16,14,10,11,4,7}
				local openfunc_key = {"wjj_open","dzgc_open","zzgf_open","ck_open","zct_open","wqyj_open","city_8_open"}
				for i,v in ipairs(conf.BUILDING_TYPE) do
					if v ~= nil  then
						if v ~= 0 then
							local build_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/ListBuildItem.csb")
							build_node:getChildByName("info"):setString(CONF:getStringValue('BuildingName_'..v).." Lv."..conf.BUILDING_LEVEL[i])
							build_node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("skip"))
							build_node:getChildByName("btn"):addClickEventListener(function ( ... )
								-- self:getApp():pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = v})
								local b1,b2,b3 = isBuildingOpen(v,true)
								if not b1 or not b2 or not b3 then
									return
								end
								self.data_.building_num = v 
								self:resetUI()
								self:resetList()
							end)

							build_node:getChildByName("btn"):setPositionX(build_node:getChildByName("info"):getPositionX() + build_node:getChildByName("info"):getContentSize().width + 10)

							if player:getBuildingInfo(v).level < conf.BUILDING_LEVEL[i] then
								build_node:getChildByName("info"):setTextColor(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255))
								-- build_node:getChildByName("info"):enableShadow(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255), cc.size(0.5,0.5))
							else
								build_node:getChildByName("btn"):setVisible(false)
							end

							build_node:setPosition(cc.p(pos.x + (num%2)*diff_x, pos.y - (math.floor(num/2))*diff_y))
							node:addChild(build_node)

							num = num + 1
						end
					end
				end
			end

			if num % 2 == 1 then
				num = num + 1
			end

			if conf.HOME_BUILDING_TYPE then
				for i,v in ipairs(conf.HOME_BUILDING_TYPE) do
					if v ~= 0 then
						local build_node = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/ListBuildItem.csb")
						build_node:getChildByName("info"):setString(CONF:getStringValue('HomeBuildingName_'..(v)).." Lv."..conf.HOME_BUILDING_LEVEL[i])
						build_node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("skip"))
						build_node:getChildByName("btn"):addClickEventListener(function ( ... )
							self:getApp():pushView("HomeScene/HomeScene",{})
						end)

						build_node:getChildByName("btn"):setPositionX(build_node:getChildByName("info"):getPositionX() + build_node:getChildByName("info"):getContentSize().width + 10)

						if player:getMaxLevelByLandType(v) < conf.HOME_BUILDING_LEVEL[i] then
							build_node:getChildByName("info"):setTextColor(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255))
							-- build_node:getChildByName("info"):enableShadow(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255), cc.size(0.5,0.5))
						else
							build_node:getChildByName("btn"):setVisible(false)
						end

						build_node:setPosition(cc.p(pos.x + (num%2)*diff_x, pos.y - (math.floor(num/2))*diff_y))
						node:addChild(build_node)

						num = num + 1
					end
				end

			end

			if num % 2 == 1 then
				num = num + 1
			end

			for i,v in ipairs(conf.ITEM_ID) do
				local item = require("app.ExResInterface"):getInstance():FastLoad("NewBuildingUpgradeScene/ListItem.csb")

				local item_conf = CONF.ITEM.get(v)
				item:getChildByName("icon"):setTexture("ItemIcon/"..item_conf.ICON_ID..".png")
				item:getChildByName("name"):setString(CONF:getStringValue(item_conf.NAME_ID))
				item:getChildByName("num"):setString(conf.ITEM_NUM[i])

				if player:getItemNumByID(v) < conf.ITEM_NUM[i] then
					item:getChildByName("num"):setTextColor(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255))
					-- item:getChildByName("num"):enableShadow(cc.c4b(CONF.ETextColor.kRed.r, CONF.ETextColor.kRed.g, CONF.ETextColor.kRed.b, 255), cc.size(0.5,0.5))
				end

				item:getChildByName("num"):setPositionX(item:getChildByName('name'):getPositionX() + item:getChildByName('name'):getContentSize().width+10)
				item:setPosition(cc.p(pos.x + (num%2)*diff_x, pos.y - (math.floor(num/2))*diff_y))
				node:addChild(item)

				num = num + 1

			end


			node:getChildByName("build_di"):setContentSize(cc.size(node:getChildByName("build_di"):getContentSize().width, 10+math.ceil(num/2)*50))
			node:getChildByName("build_bg"):setContentSize(cc.size(node:getChildByName("build_bg"):getContentSize().width, 70+math.ceil(num/2)*50))
			node:getChildByName("fenge"):setPositionY(-(node:getChildByName("build_bg"):getContentSize().height+10))
			node:getChildByName("info_pos"):setPositionY(-(node:getChildByName("build_bg"):getContentSize().height+20))
		end
	else
		node:getChildByName("max_text"):setVisible(true)
	end

	local info_height = 0
	local info_node
	local info_pos = cc.p(node:getChildByName("info_pos"):getPosition())

	if self.data_.building_num == CONF.EBuilding.kMain then
		info_node = self:createMainNode()
	elseif self.data_.building_num == CONF.EBuilding.kGarage then
		info_node = self:createRepairNode()
	elseif self.data_.building_num == CONF.EBuilding.kWarehouse then
		info_node = self:createWareHouseNode()
	elseif self.data_.building_num == CONF.EBuilding.kShipDevelop then
		info_node = self:createShipDevelopNode()
	elseif self.data_.building_num == CONF.EBuilding.kWeaponDevelop then
		info_node = self:createWeaponDevelopNode()
	elseif self.data_.building_num == CONF.EBuilding.kTechnology then
		info_node = self:createTechNologyNode()
	elseif self.data_.building_num == CONF.EBuilding.kSpy then
		info_node = self:createSpyNode()
	elseif self.data_.building_num == CONF.EBuilding.kDefend then
		info_node = self:createDefendNode()
	elseif self.data_.building_num == CONF.EBuilding.kDiplomacy then
		info_node = self:createDiplomacyNode()
	elseif self.data_.building_num == CONF.EBuilding.kWarWorkshop then
		info_node = self:createWarWorkshopNode()
	elseif self.data_.building_num == CONF.EBuilding.kForge then
		info_node = self:createForgeNode()
	end

	if info_node then
		info_node:setPosition(cc.p(info_pos.x, info_pos.y))
		node:addChild(info_node)

		info_height = info_node:getChildByName("bg"):getContentSize().height
	end

	self.svd_:addElement(node, {size = {width = 508, height = -(node:getChildByName("info_pos"):getPositionY())+info_height+10}})
end

function BuildingUpgradeScene:resetBuildQueue()

	if player:getNormalBuildingQueueNow() then

		local info = player:getBuildingQueueBuild(1)
		if info.type == 1 then
			

		elseif info.type == 2 then

			local landInfo = player:getLandType(info.index)

			local conf = CONF.RESOURCE.get(landInfo.resource_type)

			local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kHomeBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
			local time = cd - (player:getServerTime() - landInfo.res_refresh_times)

			if time <= 0 then
				local strData = Tools.encode("GetHomeSatusReq", {
					home_type = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)
			end

		end
		
	end

	if player:getMoneyBuildingQueueOpen() then

		local info = player:getBuildingQueueBuild(2)

		if player:getMoneyBuildingQueueNow() then


			if info.type == 1 then
				

			elseif info.type == 2 then

				local landInfo = player:getLandType(info.index)

				local conf = CONF.RESOURCE.get(landInfo.resource_type)

				local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kHomeBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
				local time = cd - (player:getServerTime() - landInfo.res_refresh_times)

				if time <= 0 then
					local strData = Tools.encode("GetHomeSatusReq", {
						home_type = 1,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_REQ"),strData)
				end

			end
			
		end
	end

end

function BuildingUpgradeScene:onEnterTransitionFinish()
	printInfo("BuildingUpgradeScene:onEnterTransitionFinish()")

	if player:isGroup() then
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_LIST_REQ"),"0") 
	end

	guideManager:checkInterface(CONF.EInterface.kBuildingUpgrade)

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

	if self.data_.building_num == 14 then
		-- local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
		-- if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kWarWorkshop)== 0 and g_System_Guide_Id == 0 then
		-- 	systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("zzgf_open").INTERFACE)
		-- else
			if g_System_Guide_Id ~= 0 then
				systemGuideManager:createGuideLayer(g_System_Guide_Id)
			end
		-- end
	elseif self.data_.building_num == 13 then
		-- if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kWarehouse)== 0 and g_System_Guide_Id == 0 then
		-- 	systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("wjj_open").INTERFACE)
		-- else
			if g_System_Guide_Id ~= 0 then
				systemGuideManager:createGuideLayer(g_System_Guide_Id)
			end
		-- end
	elseif self.data_.building_num == 10 or self.data_.building_num == 11 then
		if g_System_Guide_Id ~= 0 then
				systemGuideManager:createGuideLayer(g_System_Guide_Id)
			end
	end

	local rn = self:getResourceNode()

	rn:getChildByName("btn_upgrade"):getChildByName("text"):setString(CONF:getStringValue("upgrade"))
	rn:getChildByName("auto_upgrade"):getChildByName("text"):setString(CONF:getStringValue("completeQuickly"))
	rn:getChildByName("title"):setString(CONF:getStringValue("BuildingName_"..self.data_.building_num)) 
	rn:getChildByName("help"):getChildByName("text"):setString(CONF:getStringValue("ask_help"))
	-- rn:getChildByName("Image_22"):setPositionX(rn:getChildByName("title"):getPositionX()+rn:getChildByName("title"):getContentSize().width/2+5)
	rn:getChildByName("close"):addClickEventListener(function ( ... )
		-- EDIT BY WJJ 20180702
		if( self.IS_SCENE_TRANSFER_EFFECT ) then
			self.lagHelper:BeginTransferEffect("BuildingUpgradeScene/BuildingUpgradeScene")
		else
			self:getApp():popView()
		end
	end)
	local res_node = rn:getChildByName("res_node")
	res_node:getChildByName("money_add"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self:getParent(), {index = 1})
		self:getParent():addChild(rechargeNode)
	end)

	res_node:getChildByName("touch1"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self:getParent(), {index = 1})
		self:getParent():addChild(rechargeNode)
	end)

	rn:getChildByName("help"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local strData = Tools.encode("GroupRequestHelpReq", {
			type = CONF.EGroupHelpType.kBuilding,
			id = {self.data_.building_num},
		})
		print("CMD_GROUP_REQUEST_HELP_REQ",self.data_.building_num)
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_REQUEST_HELP_REQ"),strData)

		gl:retainLoading()
	end)

	rn:getChildByName("btn_upgrade"):addClickEventListener(function ( ... )

		if self.data_.building_num == CONF.EBuilding.kForge then
			if Tools.isEmpty(player:getForgeEquipList()) == false then
				tips:tips(CONF:getStringValue("equip forge"))
				return
			end
		end

		local info = player:getBuildingInfo(self.data_.building_num)
		local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
		
		if self.data_.building_num == CONF.EBuilding.kMain then
			if player:getLevel() < conf.PLAYER_LEVEL then
				-- local str = string.gsub(CONF:getStringValue("level_open"),"#",conf.PLAYER_LEVEL)
				tips:tips(CONF:getStringValue("level_not_enought"))
				return
			end
		end

		if conf.BUILDING_TYPE then
			for i,v in ipairs(conf.BUILDING_TYPE) do
				if v ~= 0 then
					if player:getBuildingInfo(v).level < conf.BUILDING_LEVEL[i] then
						tips:tips(CONF:getStringValue("level condition dissatisfy"))
						return
					end
				end
			end
		end

		if conf.HOME_BUILDING_TYPE then
			for i,v in ipairs(conf.HOME_BUILDING_TYPE) do
				if player:getMaxLevelByLandType(v) < conf.HOME_BUILDING_LEVEL[i] then
					tips:tips(CONF:getStringValue("level condition dissatisfy"))
					return
				end
			end
		end

		local enough = true
		local jumpTab = {}
		for i,v in ipairs(conf.ITEM_ID) do
			if player:getItemNumByID(v) < conf.ITEM_NUM[i] then
				enough = false
				local cfg_item = CONF.ITEM.get(v)
				if cfg_item and cfg_item.JUMP then
					table.insert(jumpTab,cfg_item.JUMP)
				end
			end
		end
		if not enough and Tools.isEmpty(jumpTab) == false then
			tips:tips(CONF:getStringValue("res_not_enough"))
			jumpTab.scene = "BuildingUpgradeScene"
			if not self:getChildByName("JumpChoseLayer") then
				local center = cc.exports.VisibleRect:center()
				local layer = self:getApp():createView("ShipsScene/JumpChoseLayer",jumpTab)
				tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
				layer:setName("JumpChoseLayer")
				self:addChild(layer)
			end
			return
		end

		local can_upgrade = true

		local nh = true
		if player:getNormalBuildingQueueNow() then

		else
			nh = false
		end

		if nh then

			if player:getMoneyBuildingQueueOpen() then
				if player:getMoneyBuildingQueueNow() then
					tips:tips(CONF:getStringValue("has build upgrade now"))
					can_upgrade = false
				else
					local queue_info = player:getBuildingQueueBuild(2)

					local time = queue_info.duration_time - (player:getServerTime() - queue_info.open_time)

					local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, self.data_.building_num, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), player:getPlayerGroupTech())

					if time < cd then
						-- tips:tips(CONF:getStringValue("money build queue not enought time,please buy"))
						local p_time = (cd - time)/3600
						local num = math.ceil(p_time/CONF.PARAM.get("queue_buy_time").PARAM)

						local function func( ... )
							playEffectSound("sound/system/click.mp3")
							if player:getMoney() < CONF.PARAM.get("queue_buy_num").PARAM*num then
								-- tips:tips(CONF:getStringValue("no enought credit"))

								local function func()
									local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

									rechargeNode:init(self, {index = 1})
									self:addChild(rechargeNode)
								end

								local messageBox = require("util.MessageBox"):getInstance()
								messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
								return
							end

							local strData = Tools.encode("BuildQueueAddReq", {
								num = num,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_ADD_REQ"),strData)

							gl:retainLoading()

							-- node:removeFromParent()
						end

						local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("open_queue").." "..formatTime2(CONF.PARAM.get("queue_buy_time").PARAM*3600*num), CONF.PARAM.get("queue_buy_num").PARAM*num, func)

						self:addChild(node)
						tipsAction(node)

						can_upgrade = false

					end
				end
			else

				-- tips:tips(CONF:getStringValue("money build queue not open"))

				local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, self.data_.building_num, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), player:getPlayerGroupTech())
				local time = cd/3600

				local num = math.ceil(time/CONF.PARAM.get("queue_buy_time").PARAM)

				local function func()
					playEffectSound("sound/system/click.mp3")

					local need_money = CONF.PARAM.get("queue_buy_num").PARAM*num
					--VIP减少元宝
					--[[local vip_conf  = CONF.VIP.get(player:getVipLevel())
					if vip_conf then
						if cd <= vip_conf.BUILDING_FREE then
							need_money = 0
						end
					end]]--

					if player:getMoney() < need_money then
						-- tips:tips(CONF:getStringValue("no enought credit"))
						local function func()
							local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

							rechargeNode:init(self, {index = 1})
							self:addChild(rechargeNode)
						end

						local messageBox = require("util.MessageBox"):getInstance()
						messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
						return
					end

					local strData = Tools.encode("BuildQueueAddReq", {
						num = num,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_ADD_REQ"),strData)

					gl:retainLoading()

					-- node:removeFromParent()
				end

				local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("open_queue").." "..formatTime2(CONF.PARAM.get("queue_buy_time").PARAM*3600*num), CONF.PARAM.get("queue_buy_num").PARAM*num, func)

				self:addChild(node)
				tipsAction(node)

				can_upgrade = false
			end

		end

		if can_upgrade then
			local confP = CONF.PARAM.get("shield_break_building_level").PARAM
			if self.data_.building_num == confP[1] then
				if info.level == confP[2]-1 then
					local function func()
						local strData = Tools.encode("BuildingUpgradeReq", {
							index = self.data_.building_num,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPGRADE_REQ"),strData)

						gl:retainLoading()
					end

					local messageBox = require("util.MessageBox"):getInstance()
					messageBox:reset(CONF.STRING.get("levelup_broken_shield").VALUE, func)

					can_upgrade = false
				end
			end
		end

		if can_upgrade then
			local strData = Tools.encode("BuildingUpgradeReq", {
				index = self.data_.building_num,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPGRADE_REQ"),strData)

			gl:retainLoading()
		end
	end)

	local function clickAutoUpgrade( ... )
		playEffectSound("sound/system/building_upgrade.mp3")
		local info = player:getBuildingInfo(self.data_.building_num)
		local conf = CONF["BUILDING_"..self.data_.building_num].get(info.level)
		
		local cd = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, self.data_.building_num, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), player:getPlayerGroupTech())
		cd = cd - (player:getServerTime() - player:getBuildingInfo(self.data_.building_num).upgrade_begin_time)

		if cd <= CONF.VIP.get(player:getVipLevel()).BUILDING_FREE then
			rn:getChildByName("auto_upgrade"):getChildByName("point"):setVisible(false)
			rn:getChildByName("auto_upgrade"):getChildByName("pointnum"):setString(CONF:getStringValue("free"))
		else
			rn:getChildByName("auto_upgrade"):getChildByName("point"):setVisible(true)
			rn:getChildByName("auto_upgrade"):getChildByName("pointnum"):setString(player:getSpeedUpNeedMoney(cd))
		end
		
		if cd > CONF.VIP.get(player:getVipLevel()).BUILDING_FREE and player:getMoney() < player:getSpeedUpNeedMoney(cd) then
			-- tips:tips(CONF:getStringValue("no enought credit"))
			local function func()
				local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

				rechargeNode:init(self, {index = 1})
				self:addChild(rechargeNode)
			end

			local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
		else

			self.cdNum = player:getSpeedUpNeedMoney(cd)

			if not g_speed_up_need and cd > CONF.VIP.get(player:getVipLevel()).BUILDING_FREE then
				local messageBoxSpeed = require("util.MessageBoxSpeed"):getInstance()
				local strinfo = CONF.STRING.get("levelup_cost").VALUE
				strinfo = string.gsub(strinfo,"#1",self.cdNum)
				messageBoxSpeed:reset(strinfo, function()
					local strData = Tools.encode("BuildingUpgradeSpeedUpReq", {
						index = self.data_.building_num,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPGRADE_SPEED_UP_REQ"),strData)

					gl:retainLoading()
				end)

			else
				local strData = Tools.encode("BuildingUpgradeSpeedUpReq", {
					index = self.data_.building_num,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPGRADE_SPEED_UP_REQ"),strData)

				gl:retainLoading()
			end
		end
	end

	rn:getChildByName("auto_upgrade"):addClickEventListener(clickAutoUpgrade)
	rn:getChildByName("auto_upgrade2"):addClickEventListener(clickAutoUpgrade)

	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"), cc.size(0,5), cc.size(508,500))
	self:resetRes()

	self:resetUI()

	self:resetList()

	local function update(dt)
		self:resetUI()	
		self:resetBuildQueue()
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)
	

	local function recvMsg()
		print("BuildingUpgradeScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPGRADE_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("BuildingUpgradeResp",strData)

			if proto.result ~= 0 then
			print("error :",proto.result)
			else
				print("BuildingUpgrade ok")
				print(proto.result)
				print(proto.info.level)
				player:setBuildingInfo(self.data_.building_num, proto.info)

				self.isHelp = false
				self:resetUI()
				self:resetList()

				flurryLogEvent(CONF:getStringValue("BuildingName_"..self.data_.building_num).."_upgrade", {build_type = "start" , data = player:getServerDateString().."-before_level"..player:getBuildingInfo(self.data_.building_num).level.."-after_level"..player:getBuildingInfo(self.data_.building_num).level}, 2)

				local num = 0
				for i,v in ipairs(CONF["BUILDING_"..self.data_.building_num].get(player:getBuildingInfo(self.data_.building_num).level).ITEM_ID) do
					if v == 3001 then
						num = CONF["BUILDING_"..self.data_.building_num].get(player:getBuildingInfo(self.data_.building_num).level).ITEM_NUM[i]
						break

					end
				end
				flurryLogEvent("use_gold_upgrade_build", {building_name = CONF:getStringValue("BuildingName_"..self.data_.building_num), info = "before_use:"..(player:getResByIndex(1) + num)..",after_use:"..player:getResByIndex(1)}, 1, num)


				if guideManager:getGuideType() then
					guideManager:doEvent("recv")
				end
				
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_ADD_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("BuildQueueAddResp",strData)
			if proto.result == 0 then
				-- self:resetBuildQueue()
				tips:tips(CONF:getStringValue("open_queue_success"))
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_LIST_RESP") then
			local proto = Tools.decode("GroupHelpListResp",strData)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else
				if player:getGroupHelp(CONF.EGroupHelpType.kBuilding, self.data_.building_num) ~= nil then
					self.isHelp = true
				end

				self:resetUI()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_REQUEST_HELP_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("GroupRequestHelpResp",strData)

			if proto.result == "HELPED" then
				tips:tips(CONF:getStringValue("requested_help"))
			elseif proto.result == "REQUESTED" then
				tips:tips(CONF:getStringValue("requested_group_help"))
			elseif proto.result == "NO_CD" then
				tips:tips(CONF:getStringValue("help_full"))
			elseif proto.result ~= "OK" then
				print("GroupRequestHelpResp error :",proto.result)
			else
				tips:tips(CONF:getStringValue("request_help_succeed"))

				self.isHelp = true
				self:resetUI()
				self:resetList()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_BUILDING_UPGRADE_SPEED_UP_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("BuildingUpgradeSpeedUpResp",strData)
			printInfo("BuildingUpgradeSpeedUpResp " .. proto.result)

			if proto.result ~= 0 then
				print("error :",proto.result)      
			else 
				if proto.user_sync.user_info.money == nil then
					player:setMoney(0)
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("MoneyUpdated")
				end

				player:setBuildingInfo(self.data_.building_num, proto.info)

				flurryLogEvent(CONF:getStringValue("BuildingName_"..self.data_.building_num).."_upgrade", {build_type = "speed_up" , data = player:getServerDateString().."-before_level"..(player:getBuildingInfo(self.data_.building_num).level-1).."-after_level"..player:getBuildingInfo(self.data_.building_num).level}, 2)

				flurryLogEvent("use_credit_speed_up_build", {building_name = CONF:getStringValue("BuildingName_"..self.data_.building_num), credit_info = "before_use:"..(player:getMoney() + self.cdNum)..",after_use:"..player:getMoney()}, 1, self.cdNum)
                if device.platform == "ios" or device.platform == "android" then
                    TDGAItem:onPurchase("speed_up_buildBuildingName_"..self.data_.building_num, 1, tonumber(self.cdNum))
                end

				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("BuildingName_"..self.data_.building_num).."Lv."..proto.info.level..CONF:getStringValue("UpgradeSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)

				self.isHelp = false
				self:resetUI()
				self:resetList()

				if guideManager:getGuideType() then
					guideManager:doEvent("recv")
				end
	

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPDATE_RESP") then

			local proto = Tools.decode("BuildingUpdateResp",strData)
			print("CMD_BUILDING_UPDATE_RESP result",proto.result)

			if proto.result == 0 then

				if proto.index == self.data_.building_num then
                    local buildinginfo = player:getBuildingInfo(proto.index)
                    local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("BuildingName_"..self.data_.building_num).."Lv."..buildinginfo.level..CONF:getStringValue("UpgradeSucess"))
					node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(node)

					self:resetUI()
					self:resetList()

					flurryLogEvent(CONF:getStringValue("BuildingName_"..self.data_.building_num).."_upgrade", {build_type = "ended" , data = player:getServerDateString().."-before_level"..(player:getBuildingInfo(self.data_.building_num).level-1).."-after_level"..player:getBuildingInfo(self.data_.building_num).level}, 2)

					if guideManager:getGuideType() then
						guideManager:doEvent("recv")
						guideManager:doEvent("specialEvent")
					end
				end
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		self:resetRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		self:resetRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)

	-- ADD WJJ 20180723
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Jianzhu_Shengji(self)

	-- ADD WJJ 20180806
	require("util.ExGuideBugHelper_SystemGuide"):getInstance():CheckSystemGuideNextCursor()
end

function BuildingUpgradeScene:onExitTransitionStart()

	printInfo("BuildingUpgradeScene:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)


	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return BuildingUpgradeScene