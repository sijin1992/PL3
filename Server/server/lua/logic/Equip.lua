local Equip = {}

function Equip:getConfEquip(equip_id)
	local conf = CONF.EQUIP.get(equip_id)
	-- if conf.STATUS == 0 then
	-- 	conf = nil
	-- end
	return conf
end


function Equip:getAttributes(conf)
	local values = {}
	local iMax = 0

	for i,key in ipairs(conf.KEY) do

		values[key] = conf.ATTR[i]

		if key > iMax then
			iMax = key
		end
	end
	for i = 1, iMax do
		if not values[i] then
			values[i] = 0
		end
	end

	return values
end

function Equip:addEquip(equip_id, user_info)
	local equip_conf = self:getConfEquip(equip_id)
	if not equip_conf then
		return nil
	end

	local equip_list = user_info.equip_list or {}
	local guid = self:getGuid(equip_list)
	local equip_info =
	{
		guid = guid,
		equip_id = equip_conf.ID,
		ship_id = 0,
		type = equip_conf.TYPE,
		quality = equip_conf.QUALITY,
		status = 0,
		level = equip_conf.LEVEL,
		strength = 0,
		attributes_base = self:getAttributes(equip_conf),
	}
	table.insert(equip_list, equip_info)
	user_info.equip_list = equip_list
	return equip_info
end

function Equip:levelUp(id, add_value, user_info)

end


function Equip:getEquipInfo(guid, user_info)

	for k,v in ipairs(user_info.equip_list) do
		if v.guid == guid then
			return v
		end
	end
	return nil
end

function Equip:getEquipByID( equip_id, user_info )

	local list = {}
	for k,v in ipairs(user_info.equip_list) do
		if v.equip_id == equip_id then
			table.insert(list, v)
		end
	end
	if Tools.isEmpty(list) then
		return nil
	end
	return list
end

function Equip:getGuid(t)
	if Tools.isEmpty(t) then
		return 1
	else
		return t[#t].guid + 1
	end
end

function Equip:removeEquip(guid, user_info)

	local equip_list = user_info.equip_list
	for i = #equip_list, 1, -1 do
		if equip_list[i].guid == guid then
			table.remove(equip_list, i)
			return true
		end
	end
	return false
end


function Equip:getGemInfo(id, user_info)

	if not Tools.isEmpty(user_info.gem_list) then
		for k,v in ipairs(user_info.gem_list) do
			if v.id == id then
				return v, k
			end
		end
	end
	return nil
end

function Equip:removeGem(id, num, user_info, sync_list)


	local gem_info, index = self:getGemInfo(id, user_info)
	if not gem_info then
		return false
	end

	if gem_info.num < num then
		return false
	end

	gem_info.num = gem_info.num - num
	if gem_info.num <= 0 then
		gem_info.id = - gem_info.id
		table.remove(user_info.gem_list, index)
	end
	if type(sync_list) == "table" then
		for i,v in ipairs(sync_list) do
			if v.id == gem_info.id then
				sync_list[i] = gem_info
				return true
			end
		end
		table.insert(sync_list, gem_info)
	end
	return true
end

function Equip:addGem(gem_id, num, user_info, sync_list)

	if num <= 0 then
		return nil
	end

	local gem_info, index = self:getGemInfo(gem_id, user_info)

	if gem_info ~= nil then
		gem_info.num = gem_info.num + num
	else

		local conf = CONF.GEM.get(gem_id)
		if not conf then
			return nil
		end
		
		gem_info = {
			id = conf.ID,
			num = num,
		}
		if Tools.isEmpty(user_info.gem_list) == true then
			user_info.gem_list = {gem_info,}
		else
			table.insert(user_info.gem_list, gem_info)
		end
	end

	if type(sync_list) == "table" then
		for i,v in ipairs(sync_list) do
			if v.id == gem_info.id then
				sync_list[i] = gem_info
				return gem_info
			end
		end
		table.insert(sync_list, gem_info)
	end
	return gem_info
end

return Equip
