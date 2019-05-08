
local app = require("app.MyApp"):getInstance()

local player = require("app.Player"):getInstance()

local PlanetManager = class("PlanetManager")

PlanetManager.info_list = {} -- id, info
PlanetManager.planet_user = nil
PlanetManager.planet_element = nil
PlanetManager.planet_group_info = {}


function PlanetManager:ctor()

	local function recvMsg()
		--printInfo("PlanetManager:recvMsg")

		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_RESP") then

			local proto = Tools.decode("PlanetRideBackResp",strData)
			printInfo("PlanetManager PlanetRideBackResp result :"..proto.result)

			if proto.result ~= 0 then
				printInfo(" error :"..proto.result)
			else

				print("#proto.planet_user.army_list",#proto.planet_user.army_list)
				for i,v in ipairs(proto.planet_user.army_list) do
					print(i,v.guid)
				end

				self:setPlanetUser(proto.planet_user)

				local event = cc.EventCustom:new("nodeUpdated")
				event.node_id_list = {}
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
				if cc.exports.new_hand_gift_bag_data then
					if Tools.isEmpty(player:getNewHandGift()) == false then
						local layer2 = app:createView("AdventureLayer/AdventureLayer",{new = true})
						layer2:setPosition(cc.exports.VisibleRect:leftBottom())
						self:addChild(layer2)
					end
				end
			end
		end
	
	end

	self.recvListener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

	eventDispatcher:addEventListenerWithFixedPriority(self.recvListener_, FixedPriority.kNormal)

end

function PlanetManager:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end
		
	return self.instance
end

function PlanetManager:clear( ... )
	self.info_list = {}
	self.planet_user = {}
	self.planet_element = {}
end

function PlanetManager:setInfoList( list )
	self.info_list = {}
	for i,v in ipairs(list) do
		local tt = {id = v.id, info = v.element_list}
		table.insert(self.info_list, tt)
	end
	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateInfoList")
end

function PlanetManager:getInfoList( ... )
	return self.info_list
end

function PlanetManager:getInfoByNodeID( node_id )
	for i,v in ipairs(self.info_list) do
		if v.id == node_id then
			return v.info
		end
	end

	return nil
end

function PlanetManager:getInfoByNodeGUID( node_id, guid )
	for i,v in ipairs(self.info_list) do
		if v.id == node_id then
			for i2,v2 in ipairs(v.info) do
				if v2.guid == guid then
					return v2
				end
			end
		end
	end


	return nil
end

function PlanetManager:GetNodeName(info)
	if info == nil then
		return ""
	end
	if info.type == 1 then
		local base_data = info.base_data
		return base_data.info.nickname
	elseif info.type == 2 then
		local res_data = info.res_data
		local conf = CONF.PLANET_RES.get(info.res_data.id)
		return "Lv."..conf.LEVEL.." "..CONF:getStringValue(conf.NAME)
	elseif info.type == 3 then
		local ruins_data = info.ruins_data
		local conf = CONF.PLANET_RUINS.get(info.ruins_data.id)
		return "Lv."..conf.LEVEL.." "..CONF:getStringValue(conf.NAME)
	elseif info.type == 4 then
		local boss_data = info.boss_data
		local boss_conf = CONF.PLANETBOSS.get(boss_data.id)
		return CONF:getStringValue(boss_conf.NAME)
	elseif info.type == 5 then
		local city_data = info.city_data
		local conf = CONF.PLANETCITY.get(city_data.id)
		return CONF:getStringValue(conf.NAME)
	elseif info.type == 6 then
		local city_res_data = info.city_res_data
		local conf = CONF.PLANET_RES.get(city_res_data.id)
		return "Lv."..conf.LEVEL.." "..CONF:getStringValue(conf.NAME)
	elseif info.type == 11 then  --ÐÇÏµÒ°¹Ö
		local monster_data = info.monster_data
		if monster_data.isDead == 1 then
			return "" --"X:"..info.pos[1].." Y:"..info.pos[2]
		else
			local monster_conf = CONF.PLANETCREEPS.get(monster_data.id)
			return "Lv"..monster_conf.LEVEL.."."..CONF:getStringValue(monster_conf.NAME)
		end
	elseif info.type == 12 then
		local wangzuo_data = info.wangzuo_data
    	local conf = CONF.PLANETCITY.get(wangzuo_data.id)
    	return CONF:getStringValue(CONF.PLANETCITY.get(wangzuo_data.id).NAME)
	end
	return ""
end

function PlanetManager:getInfoByRowCol( row, col )
	for i,v in ipairs(self.info_list) do
		for i2,v2 in ipairs(v.info) do
			for i3,v3 in ipairs(v2.pos_list) do
				if v3.x == row and v3.y == col then
					return v2
				end
			end
		end
	end

	return nil

end

function PlanetManager:getInfoByGroupId( group_id )
	for i,v in ipairs(self.info_list) do
		for i2,v2 in ipairs(v.info) do
			if v2.type == 5 then
				if v2.city_data.groupid == group_id then
					return v2
				end
			end
		end
	end

	return nil
end

function PlanetManager:getInfoListByUserName(user_name)
	for i,v in ipairs(self.info_list) do
		for i2,v2 in ipairs(v.info) do
			if v2.type == 1 and v2.base_data.user_name == user_name then
				return v2
			end
		end
	end
end

function PlanetManager:getCityByNodeId( node_id )
	for i,v in ipairs(self.info_list) do
		if v.id == node_id then
			for i2,v2 in ipairs(v.info) do
				if v2.type == 5 then
					return v2
				end
			end
		end
	end

	return nil
end

function PlanetManager:setPlanetUser( user_info )

	player:setPlayerPlanetUser(user_info)

	if self.planet_user == nil then
		self.planet_user = user_info
	else
		self.planet_user = nil
		self.planet_user = user_info
	end
	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updatePlanetUser")

end

function PlanetManager:getPlanetUser( )
	return self.planet_user
end

function PlanetManager:getPlanetUserBaseElementKey( ... )
    if self.planet_user and self.planet_user.base_global_key then
	    return self.planet_user.base_global_key
    else
        return nil
    end
end

function PlanetManager:setPlanetUserArmy( index, army )
	self.planet_user.army_list[index] = army
end

function PlanetManager:setPlanetUserMarkList( mark_list )
	self.planet_user.mark_list = mark_list
end

function PlanetManager:setPlanetElement( element_info )

	if self.planet_element == nil then
		self.planet_element = element_info
	else
		self.planet_element = nil
		self.planet_element = element_info
	end

	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updatePlanetUser")

end

function PlanetManager:getPlanetElement( ... )
	return self.planet_element
end

function PlanetManager:getUserBaseElementInfo( )

	for i,v in ipairs(self.planet_element) do
		if v.global_key == self:getPlanetUserBaseElementKey() then
			return v
		end
	end

	return nil
end

function PlanetManager:getUserBaseElementPos( ... )
	if Tools.isEmpty(self.planet_element) then
		return nil
	end
	for i,v in ipairs(self.planet_element) do
		if v.global_key == self:getPlanetUserBaseElementKey() then
			return v.pos_list[1]
		end
	end

	return nil
end

function PlanetManager:getUserArmyInfo( element_key )
	-- ADD WJJ 20180718
	if( self.planet_element == nil ) then
		return nil
	end

	for i,v in ipairs(self.planet_element) do
		if v.global_key == element_key then
			return v
		end
	end

	return nil
end

function PlanetManager:getUserShield( ... )

	if self:getUserBaseElementInfo() == nil then
		return false
	end

	if  self:getUserBaseElementInfo().base_data.shield_start_time == nil then
		return false
	end

	return self:getUserBaseElementInfo().base_data.shield_start_time > 0
end

function PlanetManager:getUserArmyInfoByPos( pos )
	for i,v in ipairs(self.planet_element) do
		if v.pos_list[1].x == pos.x and v.pos_list[1].y == pos.y then
			return v
		end
	end

	return nil
end

-------------group

function PlanetManager:setGroupInfo( group_info )
	

	local flag = false
	for i,v in ipairs(self.planet_group_info) do
		if v.groupid == group_info.groupid then
			v = group_info 
			flag = true
			break
		end
	end

	if not flag then
		table.insert(self.planet_group_info , group_info)
	end

end

function PlanetManager:getGroupInfoByGroupId( groupid )

	for i,v in ipairs(self.planet_group_info) do
		if v.groupid == groupid then
			return v
		end
	end

	return nil
end


return PlanetManager	