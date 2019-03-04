local animManager = require("app.AnimManager"):getInstance()

local g_player = require("app.Player"):getInstance()

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local path_reach = require('PathReach'):create()

local Bit = require "Bit"

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local planetManager = require('app.views.PlanetScene.Manager.PlanetManager'):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local messageBox = require("util.MessageBox"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local NewFormLayer = class("NewFormLayer", cc.load("mvc").ViewBase)

local self_ = nil

NewFormLayer.RESOURCE_FILENAME = "FormScene/NewFormLayer.csb"

NewFormLayer.NEED_ADJUST_POSITION = true

NewFormLayer.selectNode = 1 -- 标示舰队仓库队列默认选中1
NewFormLayer.selectTeam = 0 -- 标示其他界面队列默认0

NewFormLayer.selectPanNode = 1 -- 修改名字队列

NewFormLayer.RESOURCE_BINDING = {
	["save"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["fight"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	["max"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local team = {"Team a","Team b","Team c","Team d","Team e"}

local diff = 250

local piece_width = 530.5

local schedulerEntry = nil

local function sort( a,b )
	if a.quality ~= b.quality then
		return a.quality > b.quality
	else
		local af = g_player:calShipFightPower(a.guid)
		local bf = g_player:calShipFightPower(b.guid)
		if af ~= bf then
			return af > bf
		else
			if a.level > b.level then
				return a.level > b.level
			else
				if a.id ~= b.id then
					return a.id > b.id 
				end
			end
		end
	end
end

local function getTypeNum(type)
	if type == 1 then
		return 2
	elseif type == 2 then
		return 1
	elseif type == 4 then
		return 3
	else
		return 4
	end

end
local function sortByType( a,b )
	if a.quality ~= b.quality then
		return a.quality > b.quality
	else
		local af = g_player:calShipFightPower(a.guid)
		local bf = g_player:calShipFightPower(b.guid)
		if getTypeNum(a.type) ~= getTypeNum(b.type) then
			return getTypeNum(a.type) < getTypeNum(b.type)
		elseif af ~= bf then
			return af > bf
		else
			if a.level > b.level then
				return a.level > b.level
			else
				if a.id ~= b.id then
					return a.id > b.id 
				end
			end
		end
	end
end


local function getTime(data,type)
	
	local speeds = CONF.PARAM.get('planet_move_speed').PARAM

	local speed = speeds[3]
	if type == 'CITY' or type == 'BOSS' or type == 'BASE' or type == "TOWER" then
		speed = speeds[2]
	elseif type == 'RUINS' or type == 'RES' then
		speed = speeds[1]
	end

	if not planetManager:getUserBaseElementInfo( ) or not planetManager:getUserBaseElementInfo( ).global_key then
		return
	end
	local src_node_id = tonumber(Tools.split(planetManager:getUserBaseElementInfo( ).global_key,"_")[1])
	local dest_node_id = tonumber(Tools.split(data.global_key, "_")[1])
	local node_list = {}
	if src_node_id ~= dest_node_id then
		node_list = path_reach:getFindPathList(src_node_id, dest_node_id)
	end
	if node_list == nil then
	  	return nil
	end
	local dest_pos = data.pos_list[1]
	local src_pos = planetManager:getUserBaseElementInfo( ).pos_list[1]
	local nodeW = g_Planet_Grid_Info.row
	local nodeH = g_Planet_Grid_Info.col
	local function getRectInGlobal(row, col)

		local min = {x = row * nodeW - nodeW/2, y = col * nodeH - nodeH/2}
		local max = {x = row * nodeW + nodeW/2 - 1, y = col * nodeH + nodeH/2 - 1}

		return min, max
	end

	local function getGlobalPosByNode( node_id, diffX, diffY )

		local conf = CONF.PLANETWORLD.get(node_id)
		local min, max = getRectInGlobal(conf.ROW, conf.COL)

		return {x = min.x + diffX, y = min.y + diffY}
	end
	-- if #node_list < 3 then
	--   	return {src_pos, dest_pos}, {src_node_id, dest_node_id}
	-- end

	local pos_list = {src_pos}

	for i=2,#node_list-1 do
	 	local conf = CONF.PLANETWORLD.get(node_list[i])
		if conf.TYPE > 2 then
		  	local pos = getGlobalPosByNode(node_list[i], nodeW/2, nodeH/2)
		    table.insert(pos_list, pos)
		end
	end
	table.insert(pos_list, dest_pos)
	return Tools.getPlanetMoveTime( pos_list, speed )
end

local function getStrength()
	local strength
	if self_.data_.cfg_type == 'BASE' then
		strength = CONF.PARAM.get("galaxy_1").PARAM
	elseif self_.data_.cfg_type == 'RUINS' then
		local cfg_ruins = CONF.PLANET_RUINS.get(self_.data_.cfg_id)
		if cfg_ruins then
			strength = cfg_ruins.STRENGTH
		end
	elseif self_.data_.cfg_type == 'BOSS' then
		local cfg_boss = CONF.PLANETBOSS.get(self_.data_.cfg_id)
		if cfg_boss then
			strength = cfg_boss.STRENGTH
		end
	elseif self_.data_.cfg_type == 'CITY' then
		local cfg_city = CONF.PLANETCITY.get(self_.data_.cfg_id)
		if cfg_city then
			strength = cfg_city.STRENGTH
		end
	elseif self_.data_.cfg_type == 'TOWER' then
		local cfg_city = CONF.PLANETTOWER.get(self_.data_.cfg_id)
		if cfg_city then
			strength = cfg_city.STRENGTH
		end
	end
	return strength
end

local function fightfun()
    if self_.test_ship or self_.guide_ship then
		return
	end
	for i,v in ipairs(self_.forms) do
		if v ~= 0 then
			-- chuzhen_tips
			local info = player:getShipByGUID(v)
			if Bit:has(info.status, 4) == true then
				if self_.data_.from ~= "trial_fight"  and self_.data_.from ~= "continue" and self_.data_.from ~= "special" and self_.data_.from ~= "trial" then
					tips:tips(CONF:getStringValue("chuzhen_tips"))
					return
				end
			end
		end
	end
	local num = 0
	for i,v in ipairs(self_.forms) do
		if v~=0 then
			num = num + 1 
		end
	end

	if num > CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM then 
		tips:tips(CONF:getStringValue("lineup max five ships"))
		return
	elseif num == 0 then
		tips:tips(CONF:getStringValue("lineup no ships on"))

		return
	end

	for i,v in ipairs(self_.forms) do
		if v~=0 then
			local ship_info = player:getShipByGUID(v)
			if ship_info.durable < (Tools.getShipMaxDurable(ship_info)/10) then
				tips:tips(CONF:getStringValue("durable_not_enought"))
				return
			end

			if Bit:has(ship_info.status, 2) == true then
				tips:tips(CONF:getStringValue("has_fix_ship"))
				return
			end
		end
	end

	if self_.data_.from == "trial_start" then	

		local function func( ... )
			local strData = Tools.encode("TrialAreaReq", {
				type = 1,
				area_id = self_.data_.index,
				lineup = self_.forms
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)
					
			gl:retainLoading()
		end

		messageBox:reset(CONF.STRING.get("start tips").VALUE, func)

	elseif self_.data_.from == "trial_fight" then

		if player:getStrength() < CONF.TRIAL_LEVEL.get(self_.data_.id).STRENGTH then
			-- tips:tips(CONF:getStringValue("strength_not_enought"))

			self_:getApp():addView2Top("CityScene/AddStrenthLayer")
			return
		end 

		local strData = Tools.encode("TrialAreaReq", {
				type = 2,
				area_id = self_.data_.index,
				lineup = self_.forms
			})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

		gl:retainLoading()

	elseif self_.data_.from == "slave" then

		local strData = Tools.encode("SlaveAttackReq", {
				type = self_.data_.type,
				user_name = self_.data_.user_name,
				lineup = self_.forms
			})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SLAVE_ATTACK_REQ"),strData)

		gl:retainLoading()
	elseif self_.data_.from == 'bigMapCollct' then
		if Tools.isEmpty(planetManager:getPlanetUser( )) == true then
			if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false and #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
				tips:tips(CONF:getStringValue("no_planet_queue"))
				return
			end
		end
		local strength = getStrength()
		if strength and strength > player:getStrength() then
			tips:tips(CONF:getStringValue("strength_not_enought"))
			return
		end

		if self_.data_.type == "collect" then
			local strData = Tools.encode("PlanetCollectReq", {
				res_global_key = self_.data_.element_global_key,
				lineup = self_.forms,
				})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_COLLCT_REQ"),strData)

		elseif self_.data_.type == "fight" then

			if planetManager:getUserShield() then
				local messageBox = require("util.MessageBox"):getInstance()
				local function func( ... )
					local strData = Tools.encode("PlanetCollectReq", {
						res_global_key = self_.data_.element_global_key,
						lineup = self_.forms,
						})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_COLLCT_REQ"),strData)

				end
				messageBox:reset(CONF:getStringValue("shield vanish"), func)
			else
				local strData = Tools.encode("PlanetCollectReq", {
					res_global_key = self_.data_.element_global_key,
					lineup = self_.forms,
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_COLLCT_REQ"),strData)

			end
		end
	elseif self_.data_.from == 'bigMapRuins' then
		if Tools.isEmpty(planetManager:getPlanetUser( )) == true then
			if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false and #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
				tips:tips(CONF:getStringValue("no_planet_queue"))
				return
			end
		end
		local strength = getStrength()
		if strength and strength > player:getStrength() then
			tips:tips(CONF:getStringValue("strength_not_enought"))
			return
		end
		print('element_global_key..= ',self_.data_.element_global_key)
		local strData = Tools.encode('PlanetRuinsReq',{
			element_global_key = self_.data_.element_global_key,
			lineup = self_.forms,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RUINS_REQ"),strData)
	elseif self_.data_.from == 'bigMapRaid' then

		if Tools.isEmpty(planetManager:getPlanetUser( )) == true then
			if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false and #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
				tips:tips(CONF:getStringValue("no_planet_queue"))
				return
			end
		end
		local strength = getStrength()
		if strength and strength > player:getStrength() then
			tips:tips(CONF:getStringValue("strength_not_enought"))
			return
		end

		if self_.data_.type == 7 or self_.data_.type == 11 or self_.data_.type == 12 or self_.data_.type == 13 then
			local strData = Tools.encode("PlanetRaidReq", {
				type_list = {self_.data_.type},
				element_global_key = self_.data_.element_global_key,
				lineup = self_.forms,
				})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
		else
					
			if planetManager:getUserShield() then
				local messageBox = require("util.MessageBox"):getInstance()
				local function func( ... )
					print('type,element_global_key = ',self_.data_.type,self_.data_.element_global_key)
					local strData = Tools.encode("PlanetRaidReq", {
						type_list = {self_.data_.type},
						element_global_key = self_.data_.element_global_key,
						lineup = self_.forms,
						})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)

				end
				messageBox:reset(CONF:getStringValue("shield vanish"), func)
			else
				local strData = Tools.encode("PlanetRaidReq", {
					type_list = {self_.data_.type},
					element_global_key = self_.data_.element_global_key,
					lineup = self_.forms,
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
			end
		end
				

	elseif self_.data_.from == 'bigMapAllFight' then
		if Tools.isEmpty(planetManager:getPlanetUser( )) == true then
			if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false and #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
				tips:tips(CONF:getStringValue("no_planet_queue"))
				return
			end
		end
		local strength = getStrength()
		if strength and strength > player:getStrength() then
			tips:tips(CONF:getStringValue("strength_not_enought"))
			return
		end

		if planetManager:getUserShield() then
			local messageBox = require("util.MessageBox"):getInstance()
			local function func( ... )
				print('type,element_global_key = ',self_.data_.type,self_.data_.element_global_key)
				local strData = Tools.encode("PlanetRaidReq", {
					type_list = {4,self_.data_.type},
					element_global_key = self_.data_.element_global_key,
					lineup = self_.forms,
					mass_level = self_.data_.mass_level,
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
			end
			messageBox:reset(CONF:getStringValue("shield vanish"), func)
		else
			local strData = Tools.encode("PlanetRaidReq", {
				type_list = {4,self_.data_.type},
				element_global_key = self_.data_.element_global_key,
				lineup = self_.forms,
				mass_level = self_.data_.mass_level,
				})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)

		end

	elseif self_.data_.from == 'bigMapMass' then
		if planetManager:getPlanetUser( ) then
			if Tools.isEmpty(planetManager:getPlanetUser( )) == true then
				if Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false and #planetManager:getPlanetUser( ).army_list >= CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM then
					tips:tips(CONF:getStringValue("no_planet_queue"))
					return
				end
			end
		end
		local strength = getStrength()
		if strength and strength > player:getStrength() then
			tips:tips(CONF:getStringValue("strength_not_enought"))
			return
		end
				
		print("player:getPlanetElement()",player:getPlanetElement())
		if player:getPlanetElement().base_data.shield_start_time > 0 then
			local messageBox = require("util.MessageBox"):getInstance()
			local function func( ... )
				print('type,element_global_key = ',self_.data_.type,self_.data_.element_global_key)
				local strData = Tools.encode("PlanetRaidReq", {
					type_list = {self_.data_.type},
					element_global_key = self_.data_.element_global_key,
					lineup = self_.forms,
					army_key = self_.data_.army_key,
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
			end
			messageBox:reset(CONF:getStringValue("shield vanish"), func)
		else
			local strData = Tools.encode("PlanetRaidReq", {
					type_list = {self_.data_.type},
					element_global_key = self_.data_.element_global_key,
					lineup = self_.forms,
					army_key = self_.data_.army_key,
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
		end
	else

		if player:getStrength() < CONF.CHECKPOINT.get(self_.data_.id).STRENGTH then
			-- tips:tips(CONF:getStringValue("strength_not_enought"))

			self_:getApp():addView2Top("CityScene/AddStrenthLayer")
			return
		end 

		local strData = Tools.encode("ChangeLineupReq", {
				type = 1,
				lineup = self_.forms
			})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)

		gl:retainLoading()
				
	end
end

function NewFormLayer:OnBtnClick(event)

	printInfo(event.name)
	if event.name == "ended" then

		if event.target:getName() == "save" then
			playEffectSound("sound/system/click.mp3")

			if self.test_ship or self.guide_ship then
				return
			end

			local num = 0
			for i,v in ipairs(self.forms) do
				if v~=0 then
					num = num + 1 
				end
			end

			if num > CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM then 
				tips:tips(CONF:getStringValue("lineup max five ships"))
				return
			elseif num == 0 then
				tips:tips(CONF:getStringValue("lineup no ships on"))

				return
			end

			-- for i,v in ipairs(self.forms) do
			-- 	if v~=0 then
			-- 		local ship_info = player:getShipByGUID(v)
			-- 		if ship_info.durable < (Tools.getShipMaxDurable(ship_info)/10) then
			-- 			tips:tips(CONF:getStringValue("durable_not_enought"))
			-- 			return
			-- 		end
			-- 	end
			-- end
			if self.data_.scene and self.data_.scene == 'ShipsScene' then
				local strData = Tools.encode("ChangeLineupReq", {
							type = 2,
							lineup = self.forms,
							index = self.selectNode
						})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)

					gl:retainLoading()
			else
				if self.data_.from == "trial" then

					local strData = Tools.encode("TrialAreaReq", {
						type = 2,
						area_id = self.data_.index,
						lineup = self.forms
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

					gl:retainLoading()	
				elseif self.data_.from == "defensiveLineup" then

						local strData = Tools.encode("PlanetRaidReq", {
								type_list = {3},
								element_global_key = self.data_.element_global_key,
								lineup = self.forms,
							})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)

						-- gl:retainLoading()

				else
					for i,v in ipairs(self.forms) do
						if v ~= 0 then
							local calship = player:calShip(v)
							if calship and Bit:has(calship.status, 4) then
								if self.data_.from ~= "trial_fight"  and self.data_.from ~= "continue" and self.data_.from ~= "special" and self.data_.from ~= "trial" then
									tips:tips(CONF:getStringValue("chuzhen_tips"))
									return
								end
							end
						end
					end	
					local strData = Tools.encode("ChangeLineupReq", {
							type = 1,
							lineup = self.forms
						})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)

					gl:retainLoading()

				end
			end

		end

		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")

			if self.test_ship or self.guide_ship then
				return
			end

			for i=1,9 do
				self:resetFormByIndex(i, 0)
			end

			-- animManager:runAnimOnceByCSB(self:getResourceNode(), "FormScene/FormScene.csb", "outro", function ()
				-- self:getApp():removeViewByName("NewFormLayer")
			-- end)
			self:removeFromParent()
			
		end
		
		if event.target:getName() == "fight" then
			playEffectSound("sound/system/click.mp3")
            self_ = self
            fightfun()
			-- g_player:setForms(self.forms, {from = "copy"})
		end

		if event.target:getName() == "max" then
            self_ = self
			local ships = player:getShipList()
			if Tools.isEmpty(ships) then
				return
			end
			local ship_list = {}
			for _ , v in ipairs(ships) do
				if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
					local trialship = player:getTrialShipByGUID(self.data_.index,v.guid)
					if trialship~=nil and trialship.hp>0 then
						table.insert(ship_list , v)
					end
				elseif self.data_.scene and self.data_.scene == 'ShipsScene' then
		   			table.insert(ship_list , v)
				else
					if Bit:has(v.status, CONF.EShipState.kFix) == false and Bit:has(v.status, CONF.EShipState.kOuting) == false then
						table.insert(ship_list , v)
					end
				end
			end
			print("eeeeeeeeee",#ship_list)
			table.sort(ship_list,sort)

			local iCount = CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM
			if iCount > #ship_list then
				iCount = #ship_list
			end
			local ship_list_2 = {}
			for i = 1 , iCount do
				table.insert(ship_list_2 , ship_list[i])
			end
			table.sort(ship_list_2,sortByType)
			--if guideManager:getGuideType() then
			--	guideManager:setGuideType( false )
			--end

			self.forms = {}
			for i = 1, 9 do
				if i <= iCount then
					table.insert(self.forms , ship_list_2[i].guid)
				else
					table.insert(self.forms , 0)
				end
			end

			for i=1,9 do
				self:resetFormByIndex(i, self.forms[i] == nil and 0 or self.forms[i])
			end
			self:resetList()
			self:resetNumInfo()
			print("max ship list count",#self.forms,self.data_.from)

			if self.data_.from == "trial" then
				local strData = Tools.encode("TrialAreaReq", {
					type = 2,
					area_id = self.data_.index,
					lineup = self.forms
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

				gl:retainLoading()	
				print("max ship list 4")
			elseif self.data_.from == "defensiveLineup" then
				local strData = Tools.encode("PlanetRaidReq", {
						type_list = {3},
						element_global_key = self.data_.element_global_key,
						lineup = self.forms,
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)
				print("max ship list 3")
			elseif self.data_.scene and self.data_.scene == 'ShipsScene' then
				local strData = Tools.encode("ChangeLineupReq", {
						type = 2,
						lineup = self.forms,
						index = self.selectNode
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)

				gl:retainLoading()
				print("max ship list 2")
			else
				local strData = Tools.encode("ChangeLineupReq", {
						type = 1,
						lineup = self.forms
					})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)
				gl:retainLoading()
				print("max ship list 1")
			end
		end
	end
end

function NewFormLayer:onCreate(data)
	self.data_ = data
end

function NewFormLayer:onEnter()
	
	printInfo("NewFormLayer:onEnter()")
end

function NewFormLayer:onExit()
	
	printInfo("NewFormLayer:onExit()")

end

function NewFormLayer:resetList()
	
	self:addListItem(self.svd:getScrollView():getTag())

	self:resetShipNum()
end

function NewFormLayer:resetShipNum( ... )

	local function check( guid )
		local flag = false
		for i,v in ipairs(self.forms) do
			if v == guid then
				flag = true
				break
			end
		end

		return flag
	end

	for i=1,4 do

		local ship_list
		if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
			ship_list = player:getTrialShipByType(self.data_.index, i)
		else
			ship_list = player:getShipsByType(i)
		end

		local num = 0
		for ii,vv in ipairs(ship_list) do
			if not check(vv.guid) then
				num = num + 1
			end
		end
	end
	self:setAllkindNumString()
end

function NewFormLayer:setAllkindNumString()
	local rn = self:getResourceNode()
	local ships = player:getShipList()
	local totalNum = 0
	if self.mode_ == 5 then
		totalNum = ships and #ships or 0
	else
		local typeShips = player:getShipsByType(self.mode_)
		totalNum = typeShips and #typeShips or 0
	end
	
	if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
		local ship_list = {}
		if self.mode_ == 5 then
			for i=1,4 do
				for i,v in ipairs(g_player:getTrialShipByType(self.data_.index, i)) do
					if v ~= 0 then
						local info = g_player:getShipByGUID(v.guid)
						table.insert(ship_list, info)
					end
				end
			end
		else
			for i,v in ipairs(g_player:getTrialShipByType(self.data_.index, self.mode_)) do
				if v ~= 0 then
					local info = g_player:getShipByGUID(v.guid)
					table.insert(ship_list, info)
				end
			end
		end
		totalNum = #ship_list
	end
	local num = totalNum
	for k,v in ipairs(self.forms) do
		if self.mode_ == 5 then
			if v ~= 0 then
				num = num - 1
			end
		else
			if v ~= 0 then
				local ship = player:getShipByGUID(v)
				if Tools.isEmpty(ship) == false and ship.type == self.mode_ then
					num = num - 1
				end
			end
		end
	end
	rn:getChildByName("ship_num"):setString(CONF:getStringValue("sumNum")..":"..num.."/"..totalNum)
--	rn:getChildByName("list_des"):setPositionX(rn:getChildByName("ship_num"):getPositionX()+rn:getChildByName("ship_num"):getContentSize().width)
end

function NewFormLayer:addIconListener(node)
 

	local function onTouchBegan(touch, event)
		-- self:removeAction1()
		local target = event:getCurrentTarget()

		local ln = self.svd:getScrollView():convertToNodeSpace(touch:getLocation())

		local sv_s = self.svd:getScrollView():getContentSize()
		local sv_rect = cc.rect(0, 0, sv_s.width, sv_s.height)

		if cc.rectContainsPoint(sv_rect, ln) then
		
			local locationInNode = target:convertToNodeSpace(touch:getLocation())
			local s = target:getContentSize()

			local rect = cc.rect(0, 0, s.width, s.height)
			
			if cc.rectContainsPoint(rect, locationInNode) then

				print(string.format("sprite began... x = %f, y = %f", locationInNode.x, locationInNode.y))

				-- if self.test_ship then
					-- self.test_ship:removeFromParent()
					-- self.test_ship = nil

					-- guideManager:addGuideStep(907)

				-- 	self.test_ship:setOpacity(0)
				-- end


				local index = target:getTag()

				local guid = target:getParent():getTag()

				local ship = g_player:getShipByGUID(guid)
				self.long_ship = guid

				--self.shipsList_:resetElement(index, self:createNormal(index,ship))
				
				self.curSelectShip_ = self:createSelectShipNode(ship)

				local pos = cc.pAdd(touch:getLocation(),cc.p(-s.width*0.5,s.height*0.5))

				self.curSelectShip_:setPosition(pos)

				self.curSelectShip_:setVisible(false)

				self:addChild(self.curSelectShip_)

				-----
				self.isTouch = true
				

				return true
			end

		end

		return false
	end

	local function onTouchMoved(touch, event)

		local target = event:getCurrentTarget()
		local s = target:getContentSize()

		local pos = cc.pAdd(touch:getLocation(),cc.p(-s.width*0.5,s.height*0.5))

		self.curSelectShip_:setVisible(true)
		if self.curSelectShip_ then
			self.curSelectShip_:setPosition(pos)
		end

		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			self.isMoved = true
		end

		local in_form = false
		for i=1,9 do

			local form = self:getResourceNode():getChildByName(string.format("point_%d", i))
			local posInNode = form:convertToNodeSpace(touch:getLocation())
			local s = form:getContentSize()

			local rect = cc.rect(0, 0, s.width, s.height)

			if cc.rectContainsPoint(rect, posInNode) then
				-- if self.forms[i] == 0 then
					self.faguang:setPosition(cc.p(form:getPositionX() - 2, form:getPositionY() - 2))

					in_form = true
				-- end
			end
		end

		if not in_form then
			self.faguang:setPositionX(-10000)
		end

	end

	local function onTouchEnded(touch, event)
		print("onTouchEnded")

		self.faguang:setPositionX(-10000)

		local target = event:getCurrentTarget()

		local rn = self:getResourceNode()

		local index = target:getTag()
		local guid = target:getParent():getTag()
		local ship = g_player:getShipByGUID(guid)

		if self.curSelectShip_ then

			--self.shipsList_:resetElement(index, self:createNormal(index,ship))

			self.curSelectShip_:removeFromParent()
			
			self.curSelectShip_ = nil
		end

		self.isTouch = false


		if self.isMoved then
			self.isMoved = false

			for i=1,9 do

				local form = rn:getChildByName(string.format("point_%d", i))
				local posInNode = form:convertToNodeSpace(touch:getLocation())
				local s = form:getContentSize()

				local rect = cc.rect(0, 0, s.width, s.height)

				if cc.rectContainsPoint(rect, posInNode) then

					if self.data_.from == "trial" or self.data_.from == "trial_fight" then
						if player:getTrialShipHpByGUID(self.data_.index, guid) == 0 then
							tips:tips(CONF:getStringValue("ship hp zero"))
							return
						end
					end

					if self.test_ship then
						if i ~= 5 or guid ~= 2 then
							self.test_ship:setOpacity(255)
							return
						else
							self:removeAction1()
							-- guideManager:doEvent("move")
							guideManager:createGuideLayer(guideManager:getTeshuGuideId(3)+1)
							-- self:addAction2()
						end
					end

					if self.forms[i] == 0 then
						local num = 0
						for i,v in ipairs(self.forms) do
							if v~=0 then
								num = num + 1 
							end
						end

						local airship_num = CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM
						if num >= airship_num then

							if airship_num == 5 then
								tips:tips(CONF:getStringValue("lineup max five ships"))
								return
							else

								local add_level = 0

								for i,v in ipairs(CONF.BUILDING_14.getIDList()) do
									if CONF.BUILDING_14.get(v).AIRSHIP_NUM > airship_num then
										add_level = i
										break
									end
								end

								tips:tips(CONF:getStringValue("BuildingName_14")..add_level..CONF:getStringValue("level_2").. CONF:getStringValue("add_form_num"))
								return
							end
						else
							if self.data_.from ~= "special" and self.data_.scene ~= "ShipsScene" then
								if ship.durable < Tools.getShipMaxDurable(ship)/10 then
									tips:tips(CONF:getStringValue("durable_not_enought"))
									return
								else
									if Bit:has(ship.status, 2) == true then
										tips:tips(CONF:getStringValue("repair_now"))
										return
									elseif  Bit:has(ship.status, 4) == true then
										if self.data_.from ~= "trial_fight"  and self.data_.from ~= "continue" and self.data_.from ~= "special" and self.data_.from ~= "trial" then
											tips:tips(CONF:getStringValue("chuzhen_tips"))
											return
										else
											tips:tips(CONF:getStringValue("up_form"))
											self:resetForms(i, guid)
										end
									else
										tips:tips(CONF:getStringValue("up_form"))
										self:resetForms(i, guid)
									end
								end
							else
								self:resetForms(i, guid)
							end
						end
					else
						if self.data_.from ~= "special" and self.data_.scene ~= "ShipsScene" then
							if ship.durable < Tools.getShipMaxDurable(ship)/10 then
								tips:tips(CONF:getStringValue("durable_not_enought"))
								return
							else

								if Bit:has(ship.status, 2) == true then
									tips:tips(CONF:getStringValue("repair_now"))
									return
								elseif  Bit:has(ship.status, 4) == true then
									if self.data_.from ~= "trial_fight"  and self.data_.from ~= "continue" and self.data_.from ~= "special" and self.data_.from ~= "trial" then
										tips:tips(CONF:getStringValue("chuzhen_tips"))
										return
									else
										tips:tips(CONF:getStringValue("up_form"))
										self:resetForms(i, guid)
									end
								else
									tips:tips(CONF:getStringValue("up_form"))
									self:resetForms(i, guid)
								end
							end
						else
							self:resetForms(i, guid)
						end
					end

					self:resetFormByIndex(i, guid)

					self:resetList()
					self:resetNumInfo()
					break

				else
					if self.test_ship then
						self.test_ship:setOpacity(255)
					end

				end
			end
		else

			if self.test_ship then
				return
			end

			local node = require("app.views.StarOccupationLayer.FormShipInfoNode"):createNewShipInfoNode(ship)
			-- node:init(self, self.long_ship)
			node:setPosition(cc.p(rn:getChildByName("info_pos"):getPosition()))
			node:setLocalZOrder(20)
			rn:addChild(node)
			if Tools.isEmpty(self.svd:getScrollView():getChildren()) == false then
				for k,v in ipairs(self.svd:getScrollView():getChildren()) do	
					v:getChildByName("selected"):setVisible(false)
				end
			end
			target:getParent():getChildByName("selected"):setVisible(true)
		end
	   
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

function NewFormLayer:addFormListener(node)


	local function onTouchBegan(touch, event)
		self:removeAction2()
		if self.test_ship then
			return false
		end
		
		local target = event:getCurrentTarget()
		
		local locationInNode = target:convertToNodeSpace(touch:getLocation())
		local s = target:getContentSize()

		local rect = cc.rect(0, 0, s.width, s.height)
		
		if cc.rectContainsPoint(rect, locationInNode) then

			local rn = self:getResourceNode()

			local index = target:getTag() - 100
			local formShip = rn:getChildByName(string.format("form_ship_%d", index))
			if formShip == nil then
				return false
			end

			if self.guide_ship then
				if index ~= 1 then
					return false
				else
					-- self.guide_ship:setOpacity(0)
				end
			end

			local guid = formShip:getTag()
			assert(guid>0,"error")
			self.long_ship = guid

			local ship = g_player:getShipByGUID(guid)
			self.curSelectShip_ = self:createSelectShipNode(ship)
			local pos = cc.pAdd(touch:getLocation(),cc.p(-s.width*0.5,s.height*0.5))
			self.curSelectShip_:setPosition(pos)
			self:addChild(self.curSelectShip_)
			self.curSelectShip_:setVisible(false)

			self.isTouch = true

			return true
		end

		return false
	end

	local function onTouchMoved(touch, event)

		local target = event:getCurrentTarget()
		local s = target:getContentSize()

		local pos = cc.pAdd(touch:getLocation(),cc.p(-s.width*0.5,s.height*0.5))

		if self.curSelectShip_ then
			self.curSelectShip_:setPosition(pos)
		end

		self.curSelectShip_:setVisible(true)

		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			self.isMoved = true
		end

		local in_form = false
		for i=1,9 do

			local form = self:getResourceNode():getChildByName(string.format("point_%d", i))
			local posInNode = form:convertToNodeSpace(touch:getLocation())
			local s = form:getContentSize()

			local rect = cc.rect(0, 0, s.width, s.height)

			if cc.rectContainsPoint(rect, posInNode) then
				-- if self.forms[i] == 0 then
					self.faguang:setPosition(cc.p(form:getPositionX() - 2, form:getPositionY() - 2))

					in_form = true
				-- end
			
			end
		end

		if not in_form then
			self.faguang:setPositionX(-10000)
		end

	end

	local function onTouchEnded(touch, event)

		self.faguang:setPositionX(-10000)

		local target = event:getCurrentTarget()

		if self.curSelectShip_ then

			self.curSelectShip_:removeFromParent()
			
			self.curSelectShip_ = nil
		end

		local rn = self:getResourceNode()

		local list = rn:getChildByName("list")

		local locationInList = list:convertToNodeSpace(touch:getLocation())
		local s = list:getContentSize()
		local rect = cc.rect(0, 0, s.width, s.height)

		local index = target:getTag() - 100

		local formShip = rn:getChildByName(string.format("form_ship_%d", index))

		local guid = formShip:getTag()

		local ship_info = player:getShipByGUID(guid)

		if cc.rectContainsPoint(rect, locationInList) then

			if self.guide_ship then
				return
			end

			tips:tips(CONF:getStringValue("down_form"))

			self:resetForms(index, 0)
			
			self:resetFormByIndex(index, 0)
			self:resetList()
			self:resetNumInfo()
			--if self.svd and self.svd:getScrollView():getTag() ~= ship_info.type then
			--	self:refreshShipList(ship_info.type)
			--end
			self:refreshShipList()
		end

		self.isTouch = false
 
		if self.isMoved then
			self.isMoved = false

			for i=1,9 do
				if index ~= i then
					local form = rn:getChildByName(string.format("point_%d", i))
					local posInNode = form:convertToNodeSpace(touch:getLocation())
					local s = form:getContentSize()

					local rect = cc.rect(0, 0, s.width, s.height)

					if cc.rectContainsPoint(rect, posInNode) then     

						if self.guide_ship then
							if i ~= 5 then
								self.guide_ship:setOpacity(255)
								return
							else
								self:removeAction2()

								guideManager:doEvent("move")
								-- guideManager:addGuideStep(40)
								GameHandler.handler_c.adjustTrackEvent("598tzz")
								-- guideManager:addGuideStep(908)
							end  
						end

						tips:tips(CONF:getStringValue("switch_form"))

						self:switchFormByIndex(index, i)

						self:resetFormByIndex(i)
						self:resetFormByIndex(index)

						break

					else
						if self.guide_ship then
							self.guide_ship:setOpacity(255)
						end
					end
				end
			end
			self:setAllkindNumString()
		else

			if self.guide_ship then
				return
			end

			local node = require("app.views.StarOccupationLayer.FormShipInfoNode"):createNewShipInfoNode(ship_info)
			-- node:init(self, self.long_ship)
			node:setPosition(cc.p(rn:getChildByName("info_pos"):getPosition()))
			node:setLocalZOrder(20)
			rn:addChild(node)

			self.choose_ = require("app.ExResInterface"):getInstance():FastLoad("FormScene/choose.csb")
			self.choose_:setPosition(cc.p(rn:getChildByName("point_"..index):getPosition()))
			rn:addChild(self.choose_)

		end

	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)	
end

function NewFormLayer:createSelectShipNode( ship_info )
	local node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/ship_select.csb")

	local conf = CONF.AIRSHIP.get(ship_info.id)

	node:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")
--	node:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")
    node:getChildByName("icon"):setVisible(false)
    node:getChildByName("icon2"):setVisible(true)
    node:getChildByName("icon2"):setTexture("ShipImage/"..conf.DRIVER_ID..".png")
	if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
		local bs = cc.size(73.80, 6.4)
		local progress = require("util.ClippingScaleProgressDelegate"):create("CopyScene/ui/ui_progress_light2.png", 84, {bg_size = bs, lightLength = 4})

		node:addChild(progress:getClippingNode())
		progress:getClippingNode():setPosition(cc.p(node:getChildByName("progress_back"):getPosition()))

		local t_hp = player:getTrialShipHpByGUID(self.data_.index, ship_info.guid)
		local hp = player:calShip(ship_info.guid).attr[CONF.EShipAttr.kHP]
		progress:setPercentage(t_hp/hp*100)
	else
		node:getChildByName("progress_back"):removeFromParent()
	end

	return node
end

function NewFormLayer:addListItem( tag )

	self.svd:clear()
	
	local ship_list 
	if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then

		ship_list = {}
		if self.mode_ == 5 then
			for i=1,4 do
				for i,v in ipairs(g_player:getTrialShipByType(self.data_.index, i)) do
					if v ~= 0 then
						local info = g_player:getShipByGUID(v.guid)
						table.insert(ship_list, info)
					end
				end
			end
		else
			for i,v in ipairs(g_player:getTrialShipByType(self.data_.index, self.mode_)) do
				if v ~= 0 then
					local info = g_player:getShipByGUID(v.guid)
					table.insert(ship_list, info)
				end
			end
		end
	else
		ship_list = {}
		if self.mode_ == 5 then
			for i=1,4 do
				for k,info in ipairs(g_player:getShipsByType(i)) do
					if Tools.isEmpty(info) == false then
						table.insert(ship_list,info)
					end
				end
			end
		else
			ship_list = g_player:getShipsByType(self.mode_)
		end
	end

	table.sort( ship_list, sort )

	for i,v in ipairs(ship_list) do
		local onLine = false
		for i2,v2 in ipairs(self.forms) do
			if v.guid == v2 then 
				onLine = true
			end
		end

		if not onLine then

			local flag = false

			if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
				local ship_list = player:getTrialShipList(self.data_.index)
				for ii,vv in ipairs(ship_list) do
					if vv.guid == v.guid then
						if vv.hp == 0 then
							flag = true
							break
						end
					end
				end
			end

			local ship = self:creatShipNode(v, flag)
			ship:setTag(v.guid)
			if self.data_.from ~= "continue" then
				self:addIconListener(ship:getChildByName("bg"))
			end
			self.svd:addElement(ship)
		end
	end
end

function NewFormLayer:creatShipNode(info,flag)
	local cfg_ship = CONF.AIRSHIP.get(info.id)
	local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/shipNode1.csb")
	node:getChildByName("ship_state"):setVisible(false)
	node:getChildByName("state_bg_7"):setVisible(false)
	node:getChildByName("kehecheng"):setVisible(false)
	if self.data_.from ~= "special" and self.data_.scene ~= "ShipsScene" then
		if info.durable < Tools.getShipMaxDurable(info)/10 then
			node:getChildByName("kehecheng"):setString(CONF:getStringValue("no durable"))
			node:getChildByName("kehecheng"):setVisible(true)
			if Bit:has(info.status, 2) == true then
				node:getChildByName("ship_state"):setString(CONF:getStringValue("repairingTime"))
			elseif Bit:has(info.status, 4) == true then
				if self.data_.from ~= "trial_fight"  and self.data_.from ~= "continue" and self.data_.from ~= "special" and self.data_.from ~= "trial" then
					node:getChildByName("ship_state"):setString(CONF:getStringValue("planeting"))
				end
			end
			node:getChildByName("state_bg_7"):setVisible(true)
		elseif Bit:has(info.status, 2) == true then
			node:getChildByName("ship_state"):setString(CONF:getStringValue("repairingTime"))
			node:getChildByName("ship_state"):setVisible(true)
			node:getChildByName("state_bg_7"):setVisible(true)
		elseif Bit:has(info.status, 4) == true then
			if self.data_.from ~= "trial_fight"  and self.data_.from ~= "continue" and self.data_.from ~= "special" and self.data_.from ~= "trial" then
				node:getChildByName("ship_state"):setString(CONF:getStringValue("planeting"))
				node:getChildByName("ship_state"):setVisible(true)
				node:getChildByName("state_bg_7"):setVisible(true)
			end
		end
	end
	node:getChildByName("num"):setString(info.level)
	node:getChildByName("num"):setVisible(true)
	node:getChildByName("level"):setVisible(true)
	for i=1,6 do
		if i <= info.ship_break then
			node:getChildByName("star_"..i):setVisible(true)
		end
	end
	node:getChildByName("kehecheng"):setTextColor(cc.c4b(255,70,70,255))
	-- node:getChildByName("kehecheng"):enableShadow(cc.c4b(255,70,70,255),cc.size(0.2,0.2))
	
	node:getChildByName("black"):setVisible(flag)
	node:getChildByName("Sprite_type"):setTexture("ShipType/"..info.type..".png")
--	node:getChildByName("Sprite_role"):setTexture("RoleIcon/"..cfg_ship.ICON_ID..".png")
    node:getChildByName("Sprite_role"):setVisible(false)
    node:getChildByName("Sprite_role2"):setVisible(true)
    node:getChildByName("Sprite_role2"):setTexture("ShipImage/"..cfg_ship.ICON_ID..".png")
	node:getChildByName("bg"):setTexture("ShipsScene/ui/ui_avatar_"..cfg_ship.QUALITY..".png")
	node:getChildByName("selected"):setVisible(false)

	node:getChildByName("type"):setTexture("ShipQuality/quality_"..cfg_ship.QUALITY..".png")
	return node
end

function NewFormLayer:refreshShipList(mode)
	if mode then
		self.mode_ = mode
	end
	self.selectedShip = {}
	local rn = self:getResourceNode()
	for i=1,5 do
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("selected"):setVisible(false)
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("text_selected"):setVisible(false)
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("text"):setVisible(true)
	end
	rn:getChildByName("all_btn"):getChildByName("node_"..self.mode_):getChildByName("text"):setVisible(false)
	rn:getChildByName("all_btn"):getChildByName("node_"..self.mode_):getChildByName("selected"):setVisible(true)
	rn:getChildByName("all_btn"):getChildByName("node_"..self.mode_):getChildByName("text_selected"):setVisible(true)
	self:addListItem()
end

function NewFormLayer:teamIconSelected(scene)
	local node = self:getResourceNode():getChildByName("Node_team")
	local lineup_list = g_player:getAllPreset_lineup_list()	
	for i=1,5 do
		node:getChildByName("team"..i):getChildByName("Image"):loadTexture("FormScene/ui/normal.png")
		node:getChildByName("team"..i):getChildByName("line"):setVisible(false)

		if lineup_list[i] and lineup_list[i].line_name and lineup_list[i].line_name ~= "" then
			node:getChildByName('team'..i):getChildByName("text"):setString(lineup_list[i].line_name)
		else
			node:getChildByName("team"..i):getChildByName("text"):setString(CONF:getStringValue(team[i]))
		end

		
	end
	if scene and scene == "ShipsScene" then
		node:getChildByName("team"..self.selectNode):getChildByName("Image"):loadTexture("FormScene/ui/select.png")
		node:getChildByName("team"..self.selectNode):getChildByName("line"):setVisible(true)
	else
		if node:getChildByName("team"..self.selectTeam) then
			node:getChildByName("team"..self.selectTeam):getChildByName("Image"):loadTexture("FormScene/ui/select.png")
			node:getChildByName("team"..self.selectTeam):getChildByName("line"):setVisible(true)
		end
	end
end

function NewFormLayer:getFreshRES()
	local rn = self:getResourceNode()
	if rn:getChildByName('money_node') ~= nil then
		for i=1, 4 do
			if rn:getChildByName('money_node'):getChildByName(string.format("res_text_%d",i)) then
				rn:getChildByName('money_node'):getChildByName(string.format("res_text_%d",i)):setString(formatRes(player:getResByIndex(i)))
			end
		end
		rn:getChildByName('money_node'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
		rn:getChildByName('money_node'):getChildByName('money_add'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

			rechargeNode:init(self:getParent(), {index = 1})
			self:addChild(rechargeNode)
		end)
		rn:getChildByName('money_node'):getChildByName('touch1'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			local rechargeNode = require("app.views.CityScene.RechargeNode"):create()
			rechargeNode:init(self:getParent(), {index = 1})
			self:addChild(rechargeNode)
		end)
	end
	local eventDispatcher = self:getEventDispatcher()
	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		for i=1, 4 do
			if rn:getChildByName('money_node'):getChildByName(string.format("res_text_%d",i)) then
				rn:getChildByName('money_node'):getChildByName(string.format("res_text_%d",i)):setString(formatRes(player:getResByIndex(i)))
			end
		end
		rn:getChildByName('money_node'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		rn:getChildByName('money_node'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)
end

function NewFormLayer:onEnterTransitionFinish()
	printInfo("NewFormLayer:onEnterTransitionFinish()")
	if self.data_.from == "special" and self.data_.scene == "ShipsScene" then
		local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
		if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kForm)== 0 and g_System_Guide_Id == 0 then
			systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("ysdl_open").INTERFACE)
		else
			if g_System_Guide_Id ~= 0 then
				systemGuideManager:createGuideLayer(g_System_Guide_Id)
			end
		end
	end

	local guide 
	if guideManager:getSelfGuideID() ~= 0 then
		guide = guideManager:getSelfGuideID()
	else
		guide = player:getGuideStep()
	end
	if guide > 90 then
		guideManager:checkInterface(CONF.EInterface.kForms)
	end
				
	self.mode_ = 5
	local rn = self:getResourceNode()
	rn:getChildByName('background'):setSwallowTouches(true)
	self.fight_delegate_ = require("util.FightRunDelegate"):create(rn:getChildByName("power_num"))
	rn:getChildByName("list_des"):setString(CONF:getStringValue("formation text"))
	self.faguang = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/faguang.csb")
	animManager:runAnimByCSB(self.faguang, "FormScene/sfx/faguang.csb", "1")
	rn:addChild(self.faguang)
	self.faguang:setPositionX(-10000)

	--------
	self.isTouch = false
	self.isMoved = false
	--------
	rn:getChildByName("e_text"):setString(CONF:getStringValue("myTeam"))
	-- rn:getChildByName("Image_22"):setPositionX(rn:getChildByName("e_text"):getPositionX() + rn:getChildByName("e_text"):getContentSize().width +5)
	rn:getChildByName("form"):setString(CONF:getStringValue("formation time"))
	rn:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("Military"))
	if self.data_.from == 'bigMapRaid' or self.data_.from == "bigMapCollct" or self.data_.from == 'bigMapRuins' or self.data_.from == "bigMapAllFight" or self.data_.from == "bigMapMass" then
		rn:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("expedition"))
	end
	if self.data_.from == "slave" then
		rn:getChildByName("fight"):getChildByName("text"):setString(CONF:getStringValue("enter combat"))
	end

	rn:getChildByName("max"):setVisible(true)
	rn:getChildByName("max"):getChildByName("text"):setString(CONF:getStringValue("max combat"))	

	rn:getChildByName("save"):getChildByName("text"):setString(CONF:getStringValue("Save"))
	rn:getChildByName("power"):setString(CONF:getStringValue("ship_power")..":")
	rn:getChildByName("form_max_num"):setString("/"..CONF.BUILDING_14.get(player:getBuildingInfo(14).level).AIRSHIP_NUM)
	rn:getChildByName("form_now_num"):setPositionX(rn:getChildByName("form"):getPositionX()+rn:getChildByName("form"):getContentSize().width+rn:getChildByName("form_max_num"):getContentSize().width)
	rn:getChildByName("form_max_num"):setPositionX(rn:getChildByName("form_now_num"):getPositionX())
	self.svd = require("util.ScrollViewDelegate"):create( rn:getChildByName("list"),cc.size(5,5), cc.size(120 ,120))
	local save = rn:getChildByName("save")
	local fight = rn:getChildByName("fight")
	rn:getChildByName('Image_time'):setVisible(false)
	rn:getChildByName('Image_strength'):setVisible(false)
	if self.data_.cfg_type then
		local ids = Tools.split(self.data_.element_global_key, "_")
		local info = planetManager:getInfoByNodeGUID( tonumber(ids[1]), tonumber(ids[2]) )
		local time = getTime(info,self.data_.cfg_type)
		local strength
		if self.data_.cfg_type == 'BASE' then
			strength = CONF.PARAM.get("galaxy_1").PARAM
		elseif self.data_.cfg_type == 'RUINS' then
			local cfg_ruins = CONF.PLANET_RUINS.get(self.data_.cfg_id)
			if cfg_ruins then
				strength = cfg_ruins.STRENGTH
			end
		elseif self.data_.cfg_type == 'BOSS' then
			local cfg_boss = CONF.PLANETBOSS.get(self.data_.cfg_id)
			if cfg_boss then
				strength = cfg_boss.STRENGTH
			end
		elseif self.data_.cfg_type == 'CITY' then
			local cfg_city = CONF.PLANETCITY.get(self.data_.cfg_id)
			if cfg_city then
				strength = cfg_city.STRENGTH
			end
		elseif self.data_.cfg_type == "TOWER" then
			local cfg = CONF.PLANETTOWER.get(self.data_.cfg_id)
			if cfg then
				strength = cfg.STRENGTH
			end
		end
		if time and strength then
			rn:getChildByName('Image_time'):setVisible(true)
			rn:getChildByName('Image_strength'):setVisible(true)
			rn:getChildByName('Image_time'):getChildByName('text'):setString(formatTime(time))
			rn:getChildByName('Image_strength'):getChildByName('text'):setString(strength..'/'..player:getStrength())
		elseif time and not strength then
			rn:getChildByName('Image_time'):setPosition(rn:getChildByName('Image_strength'):getPosition())
			rn:getChildByName('Image_time'):setVisible(true)
			rn:getChildByName('Image_time'):getChildByName('text'):setString(formatTime(time))
		elseif strength and not time then
			rn:getChildByName('Image_strength'):setVisible(true)
			rn:getChildByName('Image_strength'):getChildByName('text'):setString(strength..'/'..player:getStrength())
		end
	end

	if self.data_.from == "copy" or self.data_.from == "trial_fight" then

		local conf 
		if self.data_.from == "copy" then
			conf = CONF.CHECKPOINT.get(self.data_.id)
		else 
			conf = CONF.TRIAL_LEVEL.get(self.data_.id)
		end
	end

	for i=1,9 do
		if self.data_.from ~= "continue"  then
			rn:getChildByName("point_"..i):setTag(100+i)
			self:addFormListener(rn:getChildByName("point_"..i))
		end
	end

	local ship_list_ = nil
	if self.data_.scene and self.data_.scene == 'ShipsScene' then
		ship_list_ = g_player:getPreset_lineup_list(self.selectNode)
	else
		if self.selectTeam == 0 then
			if self.data_.from == "trial" or self.data_.from == "continue" or self.data_.from == "trial_fight" then
				ship_list_ = g_player:getTrialLineup(self.data_.index)
			elseif self.data_.from == "defensiveLineup" then
				ship_list_ = {0,0,0,0,0,0,0,0,0}
			else
				ship_list_ = g_player:getForms()

			end
		else
			ship_list_ = g_player:getPreset_lineup_list(self.selectTeam)
		end
	end
	local function reSetTeam(ship_list_,first)
		if not ship_list_ or Tools.isEmpty(ship_list_) then return end
		self.forms = {}

		local num = 0 
		for i,v in ipairs(ship_list_) do
			if v ~= 0 then
				table.insert(self.forms, v)
			else
				table.insert(self.forms, 0)
			end
			
		end
		for index=1,9 do
			local name = string.format("form_ship_%d", index)
			if rn:getChildByName(name) then
				rn:removeChildByName(name)
			end
			local point = self:getResourceNode():getChildByName(string.format("point_%d", index))
			point:setColor(cc.c4b(255,255,255,255))
			point:setOpacity(78.5)
		end
		local power = 0
		local forms_num = 0
		for i,v in ipairs(self.forms) do
			if v ~= 0 then
				print("calShipFightPower",v,player:calShipFightPower(v))
				-- power = power + player:calShipFightPower(v)
				forms_num = forms_num + 1
			end
		end

		--do return
		-- 原来试炼战力显示是上阵战力与其他战力和，现在策划要队伍战力
		-- if self.data_.from == "trial_start"  then
		-- 	local cal_ship_list = {}
		-- 	 for i,v in ipairs(self.forms) do
		-- 	 	if v ~= 0 then
		-- 	 	 cal_ship_list[i] = player:calShip(v, false)
		-- 	 	end
		-- 	 end
	 -- 		 power = Tools.calAllFightPower(cal_ship_list, player:getUserInfo())
	 -- 	else
	 -- 		for i,v in ipairs(self.forms) do
		-- 		if v ~= 0 then
		-- 			power = power + player:calShipFightPower(v)
		-- 		end
		-- 	end
		-- end
		for i,v in ipairs(self.forms) do
			if v ~= 0 then
				power = power + player:calShipFightPower(v)
			end
		end
		rn:getChildByName("power_num"):setString(power)
		rn:getChildByName("form_now_num"):setString(forms_num)
		self.prePieceTag = -1  

		local function onFrameEvent(frame)
			if nil == frame then
				return
			end
			local str = frame:getEvent()

			if str == "f" then
				rn:getChildByName("power_num"):setOpacity(255)
				
			end
		end
		save:setVisible(false)
		fight:setVisible(false)
		for i,v in ipairs(self.forms) do
			if v ~= 0 then
				self:resetFormByIndex(i, v)
			end
		end

		if self.data_.from == "ships" or self.data_.from == "trial" or self.data_.from == "copy" or self.data_.from == "special" or self.data_.from == "defensiveLineup" then
			save:setVisible(true)
			fight:setVisible(false)
			if self.data_.scene and self.data_.scene == "ShipsScene" then
				rn:getChildByName("save"):getChildByName("text"):setString(CONF:getStringValue("Save"))
			else
				rn:getChildByName("save"):getChildByName("text"):setString(CONF:getStringValue("yes"))
			end
		elseif self.data_.from == "trial_start" or self.data_.from == "trial_fight" or self.data_.from == "slave" then	
			save:setVisible(false)
			fight:setVisible(true)
		elseif self.data_.from == 'bigMapRaid' or self.data_.from == "bigMapCollct" or self.data_.from == 'bigMapRuins' or self.data_.from == "bigMapAllFight" or self.data_.from == "bigMapMass" then
			save:setVisible(false)
			fight:setVisible(true)
		elseif self.data_.from == "continue" then
			save:setVisible(false)
			fight:setVisible(false)
		end
		onFrameEvent()
		self:resetList()
	end
	reSetTeam(ship_list_,true)
	local tttt = self
	local function recvMsg()
		print("NewFormLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("ChangeLineupResp",strData)

			if proto.result < 0 then
				print("error :",proto.result)
			else
				if proto.type == 3 then
					local lineup_list = g_player:getAllPreset_lineup_list()
					for i=1,5 do
						if lineup_list[i] and lineup_list[i].line_name and lineup_list[i].line_name ~= "" then
							rn:getChildByName('Node_team'):getChildByName('team'..i):getChildByName("text"):setString(lineup_list[i].line_name)
						end
					end
					return
				end

				if proto.type == 1 then
					g_player:setForms(proto.lineup, {from = "copy"})
				end

				local forms_num = 0
				local forms_str = ""
				for i,v in ipairs(proto.lineup) do
					if v ~= 0 then
						forms_num = forms_num + 1

						if forms_str ~= "" then
							forms_str = forms_str.."-"
						end

						forms_str = forms_str..player:getShipByGUID(v).id
					end
				end

				flurryLogEvent("lineup_ship_change", {ship_num = tostring(forms_num), ship_id = forms_str}, 2)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("formChange")
				if self.data_ and self.data_.scene and self.data_.scene == 'ShipsScene' then
					tips:tips(CONF:getStringValue('yushe succeed'))
				else
					-- self:getApp():removeTopView()
                                -- 宇宙行军提示是否直接出征
                    if self.data_ and (self.data_.from == "bigMapCollct" or self.data_.from == "bigMapRuins" or self.data_.from == "bigMapRaid" or self.data_.from == "bigMapAllFight" or self.data_.from == "bigMapMass") then
        --                local node = require("util.TipsNode"):createWithBuyNode(CONF:getStringValue("isfight"), 0, fightfun)
        --                node:getChildByName("queue_node"):getChildByName("ui_icon_money_27"):setVisible(false)
        --                node:getChildByName("queue_node"):getChildByName("money_num"):setVisible(false)
        --				self:addChild(node)
        --				tipsAction(node)
                        local messageBox = require("util.MessageBox"):getInstance()
        		        messageBox:reset(CONF:getStringValue("isfight"), fightfun)
                    else
                        self:removeFromParent()
                    end
				end

				if proto.type == 1 then
					guideManager:setGuideType(true)
					guideManager:checkInterface(CONF.EInterface.kCopy)					
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PVE_RESP") then
			
			local proto = Tools.decode("PveResp",strData)

			if proto.result == 2 then
					tips:tips(CONF:getStringValue("durable_not_enought"))

			elseif proto.result ~= 0 then
				print("error :",proto.result)
			else
				local strength = proto.user_sync.user_info.strength
				if strength == 0 then
					-- player:setStrength(strength)
					-- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
				end
				--存exp
				g_Player_OldExp.oldExp = 0
				g_Player_OldExp.oldExp = g_player:getNowExp()
				g_Player_OldExp.oldLevel = g_player:getLevel()

				--存stageInfo
				g_Views_config.copy_id = self.data_.id
				-- g_Views_config.slPosX = self.data_.slPosX
				local name = CONF:getStringValue(CONF.CHECKPOINT.get(self.data_.id).NAME_ID)
				local enemy_name = getEnemyIcon(CONF.CHECKPOINT.get(self.data_.id).MONSTER_LIST)
				self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kCheckPoint,Tools.decode("PveResp",strData),true,name,enemy_name})

			end	
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TrialAreaResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				if self.data_.from == "trial_start" then
					self:getApp():pushToRootView("TrialScene/TrialStageScene", {scene = g_player:getTrialScene(self.data_.index)})

				elseif self.data_.from == "trial_fight" then
					if self.data_.target_name then

						if self.data_.target_name == player:getName() then
							tips:tips(CONF:getStringValue("can't fight ziji"))
							return
						end
			
						local strData = Tools.encode("TrialPveStartReq", {
							level_id = self.data_.id,
							target_name = self.data_.target_name,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)
					else

						local strData = Tools.encode("TrialPveStartReq", {
							level_id = self.data_.id,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_REQ"),strData)
					end
					
					gl:retainLoading()
				else
					self:getApp():removeTopView()
				end
				
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_PVE_START_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("TrialPveStartResp",strData)

			if proto.result == 2 then
				tips:tips(CONF:getStringValue("durable_not_enought"))

			elseif proto.result ~= 0 then
				print("error :",proto.result)
			else
				local strength = proto.user_sync.user_info.strength
				if strength == 0 then
					g_player:setStrength(strength)
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
				end
				local hp = 0
				for i,v in ipairs(player:getTrialShipList(self.data_.index)) do
					hp = hp + v.hp
				end

				--存stageInfo
				g_Views_config.copy_id = self.data_.id
				g_Views_config.slPosX = self.data_.slPosX
				g_Views_config.hp = hp
				
				local name 
				local enemy_name

				if self.data_.name ~= "" and self.data_.name then
					name = self.data_.nickname
					enemy_name = "HeroImage/"..self.data_.icon_id..".png"
				else
					name = CONF.TRIAL_LEVEL.get(self.data_.id).Medt_LEVEL
					if name == 0 or name == "0" then
						name = CONF:getStringValue(CONF.TRIAL_SCENE.get(self.data_.id).BUILDING_NAME)
					else
						name = CONF:getStringValue(name)
					end

					enemy_name = getEnemyIcon(CONF.TRIAL_LEVEL.get(self.data_.id).MONSTER_ID)
				end
				
				self:getApp():pushToRootView("BattleScene/BattleScene", {BattleType.kTrial,Tools.decode("TrialPveStartResp",strData),true, name,enemy_name})

			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SLAVE_ATTACK_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("SlaveAttackResp",strData)

			if proto.result == 2 then
				tips:tips(CONF:getStringValue("durable_not_enought"))
			elseif proto.result == "NO_TIMES" then
				
				tips:tips(CONF:getStringValue("times_not_enought"))

			elseif proto.result ~= "OK" then
				print("SlaveAttackResp error :",proto.result)
			else
				-- local strength = proto.user_sync.user_info.strength
				-- if strength == 0 then
				-- 	g_player:setStrength(strength)
				-- 	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
				-- end
				g_player:setForms(self.forms, {from = "copy"})
				local name = self.data_.name
				local enemy_name = "HeroImage/"..self.data_.icon_id..".png"
				
				local battleType 
				if self.data_.layer == "enemy" then
					battleType = BattleType.kSlaveEnemy

					flurryLogEvent("touch_slave", {}, 2)
				elseif self.data_.layer == "save" then
					battleType = BattleType.kSaveFriend

					flurryLogEvent("save_slave_friend", {}, 2)
				elseif self.data_.layer == "slave" then
					battleType = BattleType.kSlave

					flurryLogEvent("touch_slave", {}, 2)
				end

				g_slave_form_data = self.data_

				self:getApp():pushToRootView("BattleScene/BattleScene", {battleType,Tools.decode("SlaveAttackResp",strData),false, name,enemy_name})

			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_COLLCT_RESP") then
			local proto = Tools.decode("PlanetCollectResp",strData)
			print('PlanetCollectResp..',proto.result)
			if proto.result == 'OK' then
				local event = cc.EventCustom:new("nodeUpdated")
				event.node_id_list = {tonumber(Tools.split(self.data_.element_global_key, "_")[1])}
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

				planetManager:setPlanetUser(proto.planet_user)

				local list = {proto.planet_user.base_global_key}

				for i,v in ipairs(proto.planet_user.army_list) do
					table.insert(list, v.element_global_key)
				end


				local strData = Tools.encode("PlanetGetReq", {
					element_global_key_list = list,
					type = 3,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)

				self:getApp():removeTopView()
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RUINS_RESP") then
			local proto = Tools.decode("PlanetRuinsResp",strData)
			print('PlanetRuinsResp..',proto.result)
			if proto.result == 'OK' then

				local event = cc.EventCustom:new("nodeUpdated")
				event.node_id_list = {tonumber(Tools.split(self.data_.element_global_key, "_")[1])}
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

				planetManager:setPlanetUser(proto.planet_user)

				local list = {proto.planet_user.base_global_key}

				for i,v in ipairs(proto.planet_user.army_list) do
					table.insert(list, v.element_global_key)
				end


				local strData = Tools.encode("PlanetGetReq", {
					element_global_key_list = list,
					type = 3,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)

				self:getApp():removeTopView()
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_RESP") then
			local proto = Tools.decode("PlanetRaidResp",strData)
			print('PlanetRaidResp..',proto.result)
			if proto.result == 'OK' then

				if self:getApp():getTopViewName() ~= "PlanetScene/PlanetScene" then
					local strData = Tools.encode("PlanetGetReq", {
						type = 1,
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
				end

				local time = "start_time:"..getNowDateString()
				
				local lineup_str = "form:"
				for i,v in ipairs(self.forms) do
					lineup_str = lineup_str..v..","
				end

				local str = time.."-"..lineup_str

				if self.data_.from == "bigMapAllFight" then
					local mass_time = "mass_time:"..self.data_.mass_level
					local str = time.."-"..mass_time.."-"..lineup_str
					tips:tips(CONF:getStringValue("start mass"))
					if self.data_.type == 1 then
						flurryLogEvent("planet_all_fight_base", {type = tostring(CONF:getStringValue("sponsor")), info = str}, 2)
					elseif self.data_.type == 6 then
						flurryLogEvent("planet_all_fight_city", {type = tostring(CONF:getStringValue("sponsor")), info = str}, 2)
					end
				elseif self.data_.from == "bigMapMass" then
					tips:tips(CONF:getStringValue("mass success"))
					if self.data_.type == 5 then
						flurryLogEvent("planet_mass", {type = tostring("not"..CONF:getStringValue("sponsor")), info = str}, 2)
					end
				end
				
				local is_guide = false
				if guideManager:getGuideType() then
					self:getApp():removeTopView()
					is_guide = true
				end

				self:getApp():removeTopView()

				if is_guide then
					guideManager:createGuideLayer(guideManager:getTeshuGuideId(3)+2)
				end
			elseif proto.result == "ARMY_MAX_NUM" then
				tips:tips(CONF:getStringValue("no_planet_queue"))
			elseif proto.result == "NO_STRENGTH" then
				tips:tips(CONF:getStringValue("strength_not_enought"))
			elseif proto.result == "NO_GROUP" then
				tips:tips(CONF:getStringValue("loading text 4"))
			elseif proto.result == "NO_LAST_CITY_1" then
				tips:tips(CONF:getStringValue("no_last_city_01"))
			elseif proto.result == "NO_LAST_CITY_2" then
				tips:tips(CONF:getStringValue("no_last_city_02"))
			elseif proto.result == "NO_LAST_CITY_3" then
				tips:tips(CONF:getStringValue("no_last_city_03"))
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SHIP_FIX_RESP") then
			local proto = Tools.decode("ShipFixResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				self:resetList()
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	if self.data_.from and (self.data_.from == "continue" or self.data_.from == "trial") then
		rn:getChildByName('Node_team'):setVisible(false)
		rn:getChildByName('pan_name'):setVisible(false)
	else
		rn:getChildByName('Node_team'):setVisible(true)
		rn:getChildByName('pan_name'):setVisible(true)
	end
	local teamNum = CONF.PLAYERLEVEL.get(g_player:getLevel()).DEFAULT_TEAM
	for i=1,5 do
		rn:getChildByName('Node_team'):getChildByName('team'..i):setVisible(false)
		rn:getChildByName('pan_name'):getChildByName('pan'..i):setVisible(false)
		if teamNum >= i then
			rn:getChildByName('Node_team'):getChildByName('team'..i):setVisible(true)
			rn:getChildByName('pan_name'):getChildByName('pan'..i):setVisible(true)
		end

	end
	if self.data_.from ~= "special" or self.data_.scene ~= "ShipsScene" then
		if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kForm)== 0 and g_System_Guide_Id == 0 then
			rn:getChildByName('Node_team'):setVisible(false)
			rn:getChildByName('pan_name'):setVisible(false)
		else
			if g_System_Guide_Id ~= 0 then
				rn:getChildByName('Node_team'):setVisible(false)
				rn:getChildByName('pan_name'):setVisible(true)
			end
		end
	end
	self:teamIconSelected(self.data_.scene)
	for i=1,5 do

		rn:getChildByName('Node_team'):getChildByName('team'..i):addClickEventListener(function()
			local ship_list_ = g_player:getPreset_lineup_list(i)
			if self.data_.scene and self.data_.scene == 'ShipsScene' then
				if self.selectNode == i then	
					return
				else
					self.selectNode = i
				end
			else
				if self.selectTeam == i then
					self.selectTeam = 0
					ship_list_ = g_player:getForms()
				else
					self.selectTeam = i
				end
			end
			reSetTeam(ship_list_)
			self:teamIconSelected(self.data_.scene)
			end)

		rn:getChildByName('pan_name'):getChildByName('pan'..i):addClickEventListener(function()
				self.selectPanNode = i
				local TeamName = require("app.ExResInterface"):getInstance():FastLoad("FormScene/TeamName.csb")
				rn:addChild(TeamName)

				local lineup_list = g_player:getAllPreset_lineup_list()
				local name 
				if lineup_list[i] and lineup_list[i].line_name and lineup_list[i].line_name ~= "" then
					name = lineup_list[i].line_name
				else
					name = CONF:getStringValue(team[i])
				end
				TeamName:getChildByName("TextField_1"):setString(name)

				TeamName:getChildByName("layer_name"):setString(CONF.STRING.get("modify").VALUE)
				TeamName:getChildByName("ok"):getChildByName("text"):setString(CONF.STRING.get("yes").VALUE)
				TeamName:getChildByName("clean"):getChildByName("text"):setString(CONF.STRING.get("cancel").VALUE)

				TeamName:getChildByName("ok"):addClickEventListener(function()
						if TeamName:getChildByName("TextField_1"):getString() == "" then
							return
						end
						
						local strData = Tools.encode("ChangeLineupReq", {
							type = 3,
							index = self.selectPanNode,
							line_name = TeamName:getChildByName("TextField_1"):getString()
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CHANGE_LINEUP_REQ"),strData)

						TeamName:removeFromParent()

					end)

				TeamName:getChildByName("clean"):addClickEventListener(function()
						TeamName:removeFromParent()
					end)

			end)
	end
	local label = {"attack","defense","control","treat","ships_whole"}
	for i=1,5 do
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("text"):setString(CONF:getStringValue(label[i]))
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("text_selected"):setString(CONF:getStringValue(label[i]))
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("btn"):addClickEventListener(function()
			playEffectSound("sound/system/tab.mp3")
			self:refreshShipList(i)
			self:setAllkindNumString()
		end)
	end
	self:refreshShipList()
	self:setAllkindNumString()
	self:getFreshRES()

	if guideManager:getShowGuide() and guideManager:getSelfGuideID()  == guideManager:getTeshuGuideId(3)-2 then
		guideManager:createGuideLayer(guideManager:getTeshuGuideId(3)-1)
	end
	self.specialGuide_ = cc.EventListenerCustom:create("special_guide", function (event)
		if guideManager:getShowGuide() and guideManager:getSelfGuideID()  == guideManager:getTeshuGuideId(3)-1 then
			self:addAction1()
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.specialGuide_, FixedPriority.kNormal)
end

function NewFormLayer:update( dt )

	if self.fight_delegate_:getFlag() then
		self.fight_delegate_:update()
	else
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil
	end
end

function NewFormLayer:resetNumInfo( ... )
	local rn = self:getResourceNode()

	local num = 0
	for i,v in ipairs(self.forms) do
		if v ~= 0 then
			num = num + 1
		end
	end

	rn:getChildByName("form_now_num"):setString(num)

	local power = 0
	for i,v in ipairs(self.forms) do
		if v ~= 0 then
			power = power + player:calShipFightPower(v)
		end
	end
	-- rn:getChildByName("power_num"):setString(power)

	self.fight_delegate_:setUpNum(power)

	local function update( ... )
		self:update()
	end

	if schedulerEntry == nil then
		schedulerEntry = scheduler:scheduleScriptFunc(update,0.01,false)
	end

end

function NewFormLayer:resetFormByIndex( index, guid )

	local rn = self:getResourceNode()


	local function createFormShip( shipId )

		local shipConf = CONF.AIRSHIP.get(shipId)

		local formship = require("app.ExResInterface"):getInstance():FastLoad("FormScene/FormShip.csb")
		-- formship:getChildByName("ship"):removeFromParent()

		local res = string.format("sfx/%s", shipConf.RES_ID)		
		local ship = require("app.ExResInterface"):getInstance():FastLoad(res)
		ship:setName("ship")
		formship:getChildByName("ship"):addChild(ship)

		animManager:runAnimByCSB(ship, res, "move_1")

		local icon = formship:getChildByName("icon")
		icon:setTexture(string.format("RoleIcon/%d.png", shipConf.ICON_ID))
		icon:setLocalZOrder(1)
		
		local t = formship:getChildByName("type")
		t:setTexture(string.format("ShipType/%d.png", shipConf.TYPE))
		t:setLocalZOrder(1)

		local ship_info = player:getShipByID(shipId)
		for i=ship_info.ship_break+1,6 do
			formship:getChildByName("star_"..i):removeFromParent()
		end
		
		return formship
	end


	local point = self:getResourceNode():getChildByName(string.format("point_%d", index))
	-- point:setOpacity(255)

	local name = string.format("form_ship_%d", index)

	if rn:getChildByName(name) then
		rn:removeChildByName(name)
	end


	if guid == nil then
	  
		guid = self:getFormByIndex(index)
		
	end

	if guid ~= 0 and guid then
		local ship = g_player:getShipByGUID(guid)
		assert(ship ~= nil,"error")

		local fs = createFormShip(ship.id)
		fs:setTag(guid)
		local pos = cc.p(rn:getChildByName(string.format("point_%d", index)):getPosition())
		fs:setPosition(pos)
		fs:setName(name)
		rn:addChild(fs)

		point:setOpacity(255)
		if ship.quality == 2 then
			point:setColor(cc.c4b(152,255,23,255))
		elseif ship.quality == 3 then
			point:setColor(cc.c4b(68,211,255,255))
		elseif ship.quality == 4 then
			point:setColor(cc.c4b(236,89,236,255))
		elseif ship.quality == 5 then
			point:setColor(cc.c4b(255,242,68,255))
		elseif ship.quality == 1 then
			point:setColor(cc.c4b(255,255,255,255))

		end
	else
		point:setColor(cc.c4b(255,255,255,255))
		point:setOpacity(78.5)

	end

end

function NewFormLayer:getFormByIndex( index ,lineup)
	assert(index > 0 and index < 10,"error")

	return self.forms[index]
end

function NewFormLayer:switchFormByIndex( index1, index2, lineup)
	assert(index1 > 0 and index1 < 10,"error")
	assert(index2 > 0 and index2 < 10,"error")

	local temp = self.forms[index1]
	self.forms[index1] = self.forms[index2]
	self.forms[index2] = temp
end


function NewFormLayer:resetForms( index, newShipGUID, lineup )

	print("resetForms", index, newShipGUID)

	assert(index > 0 and index < 10,"error")
	assert(newShipGUID > -1,"error")


	local oldGUID = self.forms[index]

	local oldShip = nil

	if oldGUID ~= 0 and oldGUID then
		oldShip = g_player:getShipByGUID(oldGUID)
		assert(oldShip,"error")
	end

	if newShipGUID ~= 0 then

		local newShip = g_player:getShipByGUID(newShipGUID)
		assert(newShip,"error")

		-- newShip.position = index
		self.forms[index] = newShip.guid
	else
		self.forms[index] = 0
	end

	-- if oldShip then
	--     oldShip.position = 0
	-- end
end

function NewFormLayer:onExitTransitionStart()
	printInfo("NewFormLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry) 
		schedulerEntry = nil
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.specialGuide_)
end


function NewFormLayer:addAction1( )

	if player:getShipByGUID(2) == nil then
		return
	end

	local ship = self:createSelectShipNode(player:getShipByGUID(2))
	ship:setPosition(cc.p(103,545))
	ship:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.MoveBy:create(1, cc.p(482,-155)), cc.CallFunc:create(function ( ... )
		ship:setVisible(false)
	end), cc.DelayTime:create(0.3), cc.CallFunc:create(function ( ... )
		ship:setVisible(true)
		ship:setPosition(cc.p(103,545))
	end))))
	self:getResourceNode():addChild(ship, 99)

	self.test_ship = ship

	local choose_node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/jianto.csb")
	animManager:runAnimByCSB(choose_node, "FormScene/sfx/jianto.csb", "1")
	choose_node:setPosition(cc.p(self:getResourceNode():getChildByName(string.format("point_%d", 5)):getPosition()))
	self:getResourceNode():addChild(choose_node)

	self.choose_ = choose_node

end

function NewFormLayer:removeAction1( ... )
	if self.test_ship then
		self.test_ship:removeFromParent()
		self.test_ship = nil
	end
	if self.choose_ then
		self.choose_:removeFromParent()
		self.choose_ = nil
	end

end

function NewFormLayer:addAction2( )

	if player:getShipByGUID(2) == nil then
		return
	end

	local ship = self:createSelectShipNode(player:getShipByGUID(1))
	ship:setPosition(cc.p(223,545))
	ship:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.MoveBy:create(1, cc.p(362,-155)), cc.CallFunc:create(function ( ... )
		ship:setVisible(false)
	end), cc.DelayTime:create(0.3), cc.CallFunc:create(function ( ... )
		ship:setVisible(true)
		ship:setPosition(cc.p(223,545))
	end))))
	self:getResourceNode():addChild(ship, 99)

	self.guide_ship = ship

	local choose_node = require("app.ExResInterface"):getInstance():FastLoad("FormScene/sfx/jianto.csb")
	animManager:runAnimByCSB(choose_node, "FormScene/sfx/jianto.csb", "1")
	choose_node:setPosition(cc.p(self:getResourceNode():getChildByName(string.format("point_%d", 5)):getPosition()))
	self:getResourceNode():addChild(choose_node)

	self.choose_ = choose_node

end

function NewFormLayer:removeAction2( ... )
	if self.guide_ship then
		self.guide_ship:removeFromParent()
		self.guide_ship = nil
	end
	if self.choose_ then
		self.choose_:removeFromParent()
		self.choose_ = nil
	end
end

return NewFormLayer