local CoreShip = {}

function CoreShip.setExp(value, ship_info)

	if ship_info.energy_level == nil then
		ship_info.energy_level = 0
	end
	if ship_info.energy_exp == nil then
		ship_info.energy_exp = 0
	end

	ship_info.energy_exp = ship_info.energy_exp + value
	if ship_info.energy_exp < 0 then
		ship_info.energy_exp = 0
	end

	local sign = (value > 0 and 1) or -1

	for i = ship_info.energy_level, ship_info.energy_level + 2000 * sign, sign do
		if i > CONF.ENERGYLEVEL.len or i < 0 then
			return
		end
		local conf = CONF.ENERGYLEVEL.check(i)
		if not conf then
			return
		end

		if sign == 1 then
			if ship_info.energy_exp >= conf.ENERGY_EXP_ALL then

			else
				ship_info.energy_level = i - 1
				break
			end
		else

			if ship_info.energy_exp < conf.ENERGY_EXP_ALL then
				ship_info.energy_level = i - 1
			else
				break
			end
		end
	end
end

return CoreShip