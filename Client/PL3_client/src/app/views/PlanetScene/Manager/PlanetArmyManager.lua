
local app = require("app.MyApp"):getInstance()

local player = require("app.Player"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local PlanetArmyManager = class("PlanetArmyManager")

PlanetArmyManager.army_list = {} -- info, line, ship
PlanetArmyManager.speed = 1

PlanetArmyManager.scene = nil
PlanetArmyManager.time = 0

PlanetArmyManager.isSend = false

-- message PlanetArmyLine{

-- 	required string user_key = 1;//(user_name)_(army_guid)
-- 	repeated int32 node_id_list = 2;
-- 	repeated PlanetPoint move_list = 3;
-- 	required int64 begin_time = 4;
-- 	repeated int64 need_time = 5;
-- };


function PlanetArmyManager:ctor(scene)
	self.scene = scene
end

function PlanetArmyManager:getDiamondLayer( ... )
	return self.scene:getParent():getDiamondLayer()
end

function PlanetArmyManager:getNowSeeIDList( ... )

	return self:getDiamondLayer():getNowSeeID()
end

function PlanetArmyManager:clearArmyList( ... )

	if Tools.isEmpty(self.army_list) then
		return
	end

	for i,v in ipairs(self.army_list) do
		if v.line then
			for i2,v2 in ipairs(v.line) do
				v2:removeFromParent()
				v2 = nil
			end	

			v.line = {}
		end

		if v.ship then
			v.ship:removeFromParent()
			v.ship = nil
		end
	end

	self.army_list = {}
end

function PlanetArmyManager:setArmyList( list )

	if Tools.isEmpty(list) then
		self:clearArmyList()
		return
	end

	local list_node_id = {}
	for i,v in ipairs(list) do

		if Tools.isEmpty(list_node_id) then
			list_node_id = v.node_id_list
		else

			for i2,v2 in ipairs(v.node_id_list) do
				
				local has = false
				for i3,v3 in ipairs(list_node_id) do
					if v3 == v2 then
						has = true
						break
					end
				end

				if not has then
					table.insert(list_node_id , v2)
				end

			end
		end
		
	end


	local function inListNode( info )
		for i,v in ipairs(info.node_id_list) do
			for i2,v2 in ipairs(list_node_id) do
				if v == v2 then
					return true
				end
			end
		end

		return false
	end


	if not Tools.isEmpty(self.army_list) then

		for i,v in ipairs(self.army_list) do

			local has_node = inListNode(v.info)
			local has = false

			for i2,v2 in ipairs(list) do
				if v2.user_key == v.info.user_key then
					has = true
					break
				end

			end

			if has_node and not has then
				self:removeArmyByUserKey(v.info.user_key)

			end

		end

	end


	if Tools.isEmpty(self.army_list) then

		for i,v in ipairs(list) do
			local diff = 0
			if v.begin_time > self.time then
				diff = v.begin_time - self.time
			end
			local tt = {info = v, diff = diff, line = {}}
			table.insert(self.army_list, tt)
		end

	else

		for i,v in ipairs(list) do
			local has = false
			local index = 0

			for i2,v2 in ipairs(self.army_list) do
				if v.user_key == v2.info.user_key then
					has = true
					index = i2
					break
				end
			end

			if has then
				self.army_list[index].info = {}
				self.army_list[index].info = v

				-- self.army_list[index].diff = v.begin_time - self.time
			else
				local diff = 0
				if v.begin_time > self.time then
					diff = v.begin_time - self.time
				end
				local tt = {info = v, diff = diff, line = {}}
				table.insert(self.army_list, tt)
			end

		end

	end

	self:removeNotSeeArmyLine()

end

function PlanetArmyManager:removeNotSeeArmyLine( ... )
	
	local see_id_list = self:getNowSeeIDList()

	local remove_index_list = {}

	for i,v in ipairs(self.army_list) do

		local has = false

		for i2,v2 in ipairs(v.info.node_id_list) do
			for i3,v3 in ipairs(see_id_list) do
				if v2 == v3 then
					has = true
					break
				end
			end

		end

		if not has then
			table.insert(remove_index_list, i)
		end
	end

	for i=#remove_index_list,1,-1 do
		-- self:removeArmyByUserKey(self.army_list[remove_index_list[i]].info.user_key)
	end

	for i,v in ipairs(self.army_list) do

		local move_num = #v.info.move_list
		if Split(v.info.user_key, "_")[1] == player:getName() and v.info.move_list[move_num].x == planetManager:getUserBaseElementPos().x and v.info.move_list[move_num].y == planetManager:getUserBaseElementPos().y then
			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("UserBaseUpdated")
		end

		if v.line == nil or Tools.isEmpty(v.line) then
			v.line = {}

			for i2,v2 in ipairs(self:createArmyLineByUserKey(v.info.user_key)) do

				v2:setLocalZOrder(self:getDiamondLayer():getNodeTag("kLine"))
				self.scene:getResourceNode():addChild(v2, self.scene:getNodeTag("kLine"))

				table.insert(v.line,v2)
			end
		-- else
		-- 	for i2,v2 in ipairs(v.line) do
		-- 		v2:removeFromParent()
		-- 		v2 = nil
		-- 	end

		-- 	v.line = {}

		-- 	for i2,v2 in ipairs(self:createArmyLineByUserKey(v.info.user_key)) do

		-- 		v2:setLocalZOrder(self:getDiamondLayer():getNodeTag("kLine"))
		-- 		self.scene:getResourceNode():addChild(v2, self.scene:getNodeTag("kLine"))

		-- 		table.insert(v.line,v2)
		-- 	end
			
		end

		if v.ship == nil then
			local ship = self:createLineShip(v.info.user_key)
			ship:setLocalZOrder(self:getDiamondLayer():getNodeTag("kShip"))
			ship:setName(v.info.user_key)
			self.scene:getResourceNode():addChild(ship, self.scene:getNodeTag("kShip"))

			v.ship = ship
		end
	end

end

function PlanetArmyManager:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end
		
	return self.instance
end

function PlanetArmyManager:getInfoByUserKey( user_key )
	for i,v in ipairs(self.army_list) do
		if v.info.user_key == user_key then
			return v.info
		end
	end

	return nil
end

function PlanetArmyManager:getDiffByUserKey( user_key )

	for i,v in ipairs(self.army_list) do
		if v.info.user_key == user_key then
			return v.diff
		end
	end

	return nil
end

function PlanetArmyManager:getPosByCoordinate( m,n )
	return self:getDiamondLayer():getPosByCoordinate(m,n)
end

function PlanetArmyManager:getMoveEndPos( pos )


	if planetManager:getInfoByRowCol(pos.x, pos.y) then
		local element_info = planetManager:getInfoByRowCol(pos.x, pos.y)
		if #element_info.pos_list == 1 then
			return self:getPosByCoordinate(pos.x, pos.y)
		else

			local rowcol_min = 0
			local rowcol_max = 0

			for i3,v3 in ipairs(element_info.pos_list) do
				if rowcol_min == 0 then
					rowcol_min = i3
				else
					if element_info.pos_list[rowcol_min].x + element_info.pos_list[rowcol_min].y > v3.x + v3.y then
						rowcol_min = i3
					end
				end

				if rowcol_max == 0 then
					rowcol_max = i3
				else
					if element_info.pos_list[rowcol_max].x + element_info.pos_list[rowcol_max].y < v3.x + v3.y then
						rowcol_max = i3
					end
				end
				
			end

			local pos = {}
			if rowcol_min == rowcol_max then
				pos = self:getPosByCoordinate(element_info.pos_list[rowcol_max].x, element_info.pos_list[rowcol_max].y)
			else

				local p1 = self:getPosByCoordinate(element_info.pos_list[rowcol_max].x, element_info.pos_list[rowcol_max].y)
				local p2 = self:getPosByCoordinate(element_info.pos_list[rowcol_min].x, element_info.pos_list[rowcol_min].y)

				pos.x = ( p1.x + p2.x )/2
				pos.y = ( p1.y + p2.y )/2
			end

			return pos
		end

	else
		return self:getPosByCoordinate(pos.x, pos.y)

	end
end

function PlanetArmyManager:createArmyLineByUserKey( user_key )

	local type
	local name = Split(user_key, "_")[1]

	if name == player:getName() then
		type = 1
	else
		if player:checkPlayerIsInGroup(name) then
			type = 2
		else
			type = 3
		end

	end

	local info = self:getInfoByUserKey(user_key)

	local pos_list = {}
	local line_list = {}
	for i,v in ipairs(info.move_list) do
		local pos = self:getMoveEndPos(v)
		table.insert(pos_list, pos)
	end

	for i=2,#pos_list do
		local line = self:createArmyLine(pos_list[i-1], pos_list[i], type )
		table.insert(line_list, line)
	end
	-- local move_1 = self:getMoveEndPos(info.move_list[1])
	-- local move_2 = self:getMoveEndPos(info.move_list[#info.move_list])

	-- return self:createArmyLine(move_1, move_2, type )

	return line_list
	
end

function PlanetArmyManager:createArmyLine( pos1, pos2, type )

	local line = mc.UVSprite:create("PlanetScene/ui/arrow.png")
    line:setAutoScrollU(false)
    line:setAutoScrollV(true)
    line:setScrollSpeedV(self.speed)
    line:setPosition(cc.p((pos1.x + pos2.x)/2, (pos1.y + pos2.y)/2))
    line:setRotation( 90 - getAngleByPos(pos1, pos2))

    local dis = cc.pGetDistance(pos1, pos2)
    line:setTextureRect(cc.rect(0, 0, 8, dis))

    if type == 1 then
    	line:setColor(cc.c3b(58,225,146))
    elseif type == 2 then
    	line:setColor(cc.c3b(58,188,155))
    elseif type == 3 then
    	line:setColor(cc.c3b(255,58,58))
    end
    
   	-- self.scene:getResourceNode():addChild(line)
    
   	return line

end

function PlanetArmyManager:getArmyLineRotation( pos1, pos2 )

	return 90 - getAngleByPos(pos1, pos2)
end

function PlanetArmyManager:getArmyList( ... )
	return self.army_list
end

function PlanetArmyManager:setArmyByUserKey( user_key, army_line )
	for i,v in ipairs(self.army_list) do
		if v.info.user_key == user_key then
			v.info = army_line
		end
	end
end

function PlanetArmyManager:removeArmyByUserKey( user_key )

	if user_key == nil or user_key == "" then
		return
	end

	for i,v in ipairs(self.army_list) do
		if v.info.user_key == user_key then
			if v.line then
				for i2,v2 in ipairs(v.line) do
					v2:removeFromParent()
					v2 = nil
				end
				v.line = {}
				
			end

			if v.ship then
				v.ship:removeFromParent()
				v.ship = nil 
			end

			table.remove(self.army_list, i)
			break
		end
	end
end

function PlanetArmyManager:update(dt)

	for i,v in ipairs(self.army_list) do

		if v.line then
			-- local move_1 = self:getMoveEndPos(v.info.move_list[1])
			-- local move_2 = self:getMoveEndPos(v.info.move_list[#v.info.move_list])


			-- v.line:setRotation(self:getArmyLineRotation(move_1, move_2))

			local pos_list = {}
			local line_list = {}
			for i2,v2 in ipairs(v.info.move_list) do
				local pos = self:getMoveEndPos(v2)
				table.insert(pos_list, pos)
			end

			for i,v in ipairs(v.line) do
				v:setRotation(self:getArmyLineRotation(pos_list[i], pos_list[i+1]))
			end

		end

		if v.ship then
			if self:getShipCome(v.info.user_key) then
				-- self:removeArmyByUserKey(v.info.user_key)

				--if self.isSend == false then
					if Split(v.info.user_key, "_")[1] == player:getName() then

						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("UserBaseUpdated")

						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("PlanetUpdateSelect")
					end

						if v.info.status == 1 and (v.info.status_machine == 1 or v.info.status_machine == 2 or v.info.status_machine == 6 or v.info.status_machine == 8 or v.info.status_machine == 9 or v.info.status_machine == 11) then
							if v.ship then
								self:getDiamondLayer():openResWarAnimation(v.info.move_list[#v.info.move_list], v.ship:getTag(), v.ship:getName())
							end
						end

						local event = cc.EventCustom:new("nodeUpdated")
						event.node_id_list = v.info.node_id_list
						cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)


					-- end
				--end

			else
				v.ship:setPosition(self:getShipPos(v.info.user_key))

				local rotation,sfx_index = self:getShipRotation(v.info.user_key)
				
				if v.ship:getTag() ~= sfx_index then
					v.ship:removeFromParent()
					v.ship = nil
					v.ship = require("app.ExResInterface"):getInstance():FastLoad(string.format("PlanetScene/sfx/ship/%d.csb", sfx_index))
					animManager:runAnimByCSB(v.ship, string.format("PlanetScene/sfx/ship/%d.csb", sfx_index), "1")

					v.ship:setTag(sfx_index)
					v.ship:setName(v.info.user_key.."_ship")

					self.scene:getResourceNode():addChild(v.ship, self.scene:getNodeTag("kShip"))
				end

				v.ship:setRotation(rotation)
			end
		end

	end

	self.time = self.time + dt
end

function PlanetArmyManager:setIsSend( flag )
	self.isSend = flag
end

function PlanetArmyManager:setTime( time )
	self.time = time
end

function PlanetArmyManager:createLineShip( user_key )
	
	local info = self:getInfoByUserKey(user_key)

	local move_1 = self:getMoveEndPos(info.move_list[1])
	local move_2 = self:getMoveEndPos(info.move_list[#info.move_list])

	local pos1 = move_1
	local pos2 = move_2

	local angle = getAngleByPos(pos1, pos2)

	local ship
	local ship_sfx_index

	local rotation = {90, -90, 0, 180, -45, 135, 225, 45, 270, -135, -180, -225, 315, -270, -315}

	local diff_angle = 0
	local index = 0
	for i,v in ipairs(rotation) do
		local diff = angle - v
		if i == 1 then
			diff_angle = diff
			index = i
		else
			if math.abs(diff) < math.abs(diff_angle) then
				diff_angle = diff 
				index = i
			end
		end
	end

	if index == 1 then
		ship_sfx_index = 2
	elseif index == 2 then 
		ship_sfx_index = 1
	elseif index == 3 then 
		ship_sfx_index = 3
	elseif index == 4 then 
		ship_sfx_index = 4
	elseif index == 5 then 
		ship_sfx_index = 8
	elseif index == 6 then 
		ship_sfx_index = 7
	elseif index == 7 then 
		ship_sfx_index = 6
	elseif index == 8 then 
		ship_sfx_index = 5
	elseif index == 9 then 
		ship_sfx_index = 1
	elseif index == 10 then 
		ship_sfx_index = 6
	elseif index == 11 then 
		ship_sfx_index = 4
	elseif index == 12 then 
		ship_sfx_index = 7
	elseif index == 13 then 
		ship_sfx_index = 8
	elseif index == 14 then 
		ship_sfx_index = 2
	elseif index == 15 then 
		ship_sfx_index = 5
	end

	ship = require("app.ExResInterface"):getInstance():FastLoad(string.format("PlanetScene/sfx/ship/%d.csb", ship_sfx_index))
	animManager:runAnimByCSB(ship, string.format("PlanetScene/sfx/ship/%d.csb", ship_sfx_index), "1")


	ship:setRotation(-diff_angle)
	ship:setTag(ship_sfx_index)
	ship:setName(user_key.."_ship")

	return ship

end

function PlanetArmyManager:getShipRotation( user_key )
	local info = self:getInfoByUserKey(user_key)

	local now_time = self.time - (info.begin_time - self:getDiffByUserKey(user_key))

	local param = now_time/(info.need_time - info.sub_time)

	if param < 0 then
		param = 0
	end

	if param > 1 then
		param = 1
	end

	local dis_list = {}
	local param_list = {}
	local move_list_num = #info.move_list
	for i=2,move_list_num do
		local distance = cc.pGetDistance(info.move_list[i-1], info.move_list[i])
		table.insert(dis_list, distance)
	end

	local max_distance = 0
	for i,v in ipairs(dis_list) do
		max_distance = v + max_distance
	end

	for i,v in ipairs(dis_list) do
		table.insert(param_list, v/max_distance)
	end

	local param_index = 0
	local now_param = 0
	local time_param = 0
	for i,v in ipairs(param_list) do
		if param <= now_param + v then
			param_index = i
			time_param = (param - now_param)/v
			break
		else
			now_param = now_param + v
		end
	end

	-- if param_index == 0 or param_index > move_list_num then
	-- 	return
	-- end
	local move_1 = self:getMoveEndPos(info.move_list[param_index])
	local move_2 = self:getMoveEndPos(info.move_list[param_index+1])

	local pos1 = move_1
	local pos2 = move_2

	local angle = getAngleByPos(pos1, pos2)

	local ship
	local ship_sfx_index

	local rotation = {90, -90, 0, 180, -45, 135, 225, 45, 270, -135, -180, -225, 315, -270, -315}

	local diff_angle = 0
	local index = 0
	for i,v in ipairs(rotation) do
		local diff = angle - v
		if i == 1 then
			diff_angle = diff
			index = i
		else
			if math.abs(diff) < math.abs(diff_angle) then
				diff_angle = diff 
				index = i
			end
		end
	end

	if index == 1 then
		ship_sfx_index = 2
	elseif index == 2 then 
		ship_sfx_index = 1
	elseif index == 3 then 
		ship_sfx_index = 3
	elseif index == 4 then 
		ship_sfx_index = 4
	elseif index == 5 then 
		ship_sfx_index = 8
	elseif index == 6 then 
		ship_sfx_index = 7
	elseif index == 7 then 
		ship_sfx_index = 6
	elseif index == 8 then 
		ship_sfx_index = 5
	elseif index == 9 then 
		ship_sfx_index = 1
	elseif index == 10 then 
		ship_sfx_index = 6
	elseif index == 11 then 
		ship_sfx_index = 4
	elseif index == 12 then 
		ship_sfx_index = 7
	elseif index == 13 then 
		ship_sfx_index = 8
	elseif index == 14 then 
		ship_sfx_index = 2
	elseif index == 15 then 
		ship_sfx_index = 5
	end

	return -diff_angle,ship_sfx_index
end

function PlanetArmyManager:getShipPos( user_key )

	local info = self:getInfoByUserKey(user_key)

	local now_time = self.time - (info.begin_time - self:getDiffByUserKey(user_key))

	local param = now_time/(info.need_time - info.sub_time)

	if Split(user_key, "_")[1] == player:getName() then
		-- print("param",param)
	end

	if param < 0 then
		param = 0
	end
	if param > 1 then
		param = 1
	end

	-- local move_1 = self:getMoveEndPos(info.move_list[1])
	-- local move_2 = self:getMoveEndPos(info.move_list[#info.move_list])

	-- local pos1 = move_1
	-- local pos2 = move_2

	-- local diff_x = (pos2.x - pos1.x) * param
	-- local diff_y = (pos2.y - pos1.y) * param

	-- return cc.p(pos1.x + diff_x, pos1.y + diff_y)


	local dis_list = {}
	local param_list = {}
	local move_list_num = #info.move_list
	for i=2,move_list_num do
		local distance = cc.pGetDistance(info.move_list[i-1], info.move_list[i])
		table.insert(dis_list, distance)
	end

	local max_distance = 0
	for i,v in ipairs(dis_list) do
		max_distance = v + max_distance
	end

	for i,v in ipairs(dis_list) do
		table.insert(param_list, v/max_distance)
	end

	local index = 0
	local now_param = 0
	local time_param = 0
	for i,v in ipairs(param_list) do
		if param <= now_param + v then
			index = i
			time_param = (param - now_param)/v
			break
		else
			now_param = now_param + v
		end
	end

	if index == 0 or index > move_list_num then
		return
	end

	local move_1 = self:getMoveEndPos(info.move_list[index])
	local move_2 = self:getMoveEndPos(info.move_list[index+1])

	local pos1 = move_1
	local pos2 = move_2

	local diff_x = (pos2.x - pos1.x) * time_param
	local diff_y = (pos2.y - pos1.y) * time_param

	return cc.p(pos1.x + diff_x, pos1.y + diff_y)


end

function PlanetArmyManager:getShipCome( user_key )
	local info = self:getInfoByUserKey(user_key)

	-- print("timeeeeeeeeeeeee", player:getServerTime(), info.begin_time, info.need_time, self.time)
	local now_time = player:getServerTime() - info.begin_time

	local param = now_time/(info.need_time - info.sub_time)

	return param > 1
end

function PlanetArmyManager:getShipSpeed( user_key )
	local info = self:getInfoByUserKey(user_key)

	
end


return PlanetArmyManager