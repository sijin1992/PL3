local Fight = require "fight"
local Bit = require "Bit"

function client_gm_feature(step, req_buff, user_name)
	if step == 0 then

		local req = Tools.decode("CmdClientGMReq", req_buff)
		local resp =
		{
			result = -1,
		}
		return 1, Tools.encode("CmdClientGMResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.ship_list + datablock.item_list + datablock.save, user_name
	else
		error("something error");
	end
end

function client_gm_do_logic(req_buff, user_name, user_info_buff, ship_list_buff, item_list_buff)
	local userInfo = require "UserInfo"
	local shipList = require "ShipList"
	local itemList = require "ItemList"
	userInfo:new(user_info_buff)
	shipList:new(ship_list_buff , user_name)
	itemList:new(item_list_buff)
	
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	
	shipList:setUserInfo(user_info)
	shipList:setItemList(item_list)

	local user_sync = {
		user_info = {},
		ship_list = {},
		weapon_list = {},
		equip_list = {},
		item_list = {},
		gem_list = {},
	}

	local req = Tools.decode("CmdClientGMReq", req_buff)

	print(user_info.user_name,"client_gm_do_logic:",req.cmd)

	local cmd_list
	if req.cmd == "balabababa1" then
		cmd_list = {
			"addexp 12146200",
			"addbuildinglevel 1 29",
			"addbuildinglevel 3 29",
			"addbuildinglevel 4 29",
			"addbuildinglevel 5 29",
			"addbuildinglevel 7 29",
			"addship 111001",
			"addship 112001",
			"addship 112002",
			"addship 113001",
			"addship 113002",
			"addship 113003",
			"addship 114004",
			"addship 121001",
			"addship 122002",
			"addship 122002",
			"addship 123001",
			"addship 123002",
			"addship 123003",
			"addship 124003",
			"addship 131001",
			"addship 132001",
			"addship 132002",
			"addship 133001",
			"addship 133002",
			"addship 133003",
			"addship 135004",
			"addship 141001",
			"addship 142001",
			"addship 142002",
			"addship 143001",
			"addship 143002",
			"addship 143003",
			"addship 145004",
			"additem 11001 99999",
			"additem 11002 9999",
			"additem 11003 9999",
			"additem 11004 9999",
			"additem 11005 9999",
			"additem 13004 9999",
			"additem 13005 99999",
			"additem 15002 99",
			"additem 16004 99",
			"additem 11113 99 ",
			"additem 11114 99 ",
			"additem 11109 99",
			"additem 11110 99",
			"additem 11105 99",
			"additem 11106 99",
			"additem 11101 99",
			"additem 11102 99",
			"additem 11117 99",
			"additem 11118 99",
			"additem 11119 99",
			"additem 11120 99",
			"additem 900201 99",
			"additem 900401 99",
			"additem 902601 99",
			"additem 902901 99",
			"additem 900501 99",
			"additem 900801 99",
			"additem 900901 99",
			"additem 903201 99",
			"additem 903301 99",
			"additem 900301 99",
			"additem 902001 99",
			"additem 902701 99",
			"additem 902801 99",
			"additem 900601 99",
			"additem 900701 99",
			"additem 903001 99",
			"additem 903101 99",
			"additem 902201 99",
			"additem 901901 99",
			"additem 901201 99",	
			"additem 4010130 5",
			"additem 4020130 5",
			"additem 4030130 5",
			"additem 4040130 5",
			"additem 3010230 5",
			"additem 3020230 5",
			"additem 3030230 5",
			"additem 3040230 5",
			"additem 17001 99",
			"additem 17002 99",
			"additem 17003 99",
			"additem 17011 999",
			"additem 17012 999",
			"addres 1 9999999999",
			"addres 2 9999999999",
			"addres 3 9999999999",
			"addres 4 9999999999",
			"addcredit 99999999",
		}
	elseif req.cmd == "balabababa2" then
		cmd_list = {
			"addexp 232870",
			"addbuildinglevel 1 13",
			"addbuildinglevel 3 13",
			"addbuildinglevel 4 13",
			"addbuildinglevel 5 13",
			"addbuildinglevel 7 13",
			"addship 112001",
			"addship 122001",
			"addship 132001",
			"addship 142001",			
			"additem 11001 999",
			"additem 11002 999",
			"additem 11003 999",
			"additem 11004 99",
			"additem 11005 99",
			"additem 13004 99",
			"additem 13005 999",
			"additem 15002 10",
			"additem 900201 99",
			"additem 900401 99",
			"additem 902601 99",
			"additem 902901 99",
			"additem 900501 99",
			"additem 900801 99",
			"additem 900901 99",
			"additem 903201 99",
			"additem 903301 99",
			"additem 900301 99",
			"additem 902001 99",
			"additem 902701 99",
			"additem 902801 99",
			"additem 900601 99",
			"additem 900701 99",
			"additem 903001 99",
			"additem 903101 99",
			"additem 902201 99",
			"additem 901901 99",
			"additem 901201 99",
			"additem 3010110 5",
			"additem 3020110 5",
			"additem 3030110 5",
			"additem 3040110 5",
			"additem 2010115 5",
			"additem 2020115 5",
			"additem 2030115 5",
			"additem 2040115 5",
			"additem 16004 99",
			"additem 17001 99",
			"additem 17002 99",
			"additem 17003 99",
			"additem 17011 99",
			"additem 17012 99",
			"addres 1 9999999999",
			"addres 2 9999999999",
			"addres 3 9999999999",
			"addres 4 9999999999",
			"addcredit 9999999",
		}
	elseif req.cmd == "balabababa3" then
		cmd_list = {
			"additem 11001 99999",
			"additem 11002 9999",
			"additem 11003 9999",
			"additem 11004 9999",
			"additem 11005 9999",
			"additem 11101 999",
			"additem 13004 9999",
			"additem 13005 9999999",
			"additem 15002 99",
			"additem 900204 99",
			"additem 900404 99",
			"additem 902604 99",
			"additem 902904 99",
			"additem 900504 99",
			"additem 900804 99",
			"additem 900904 99",
			"additem 903204 99",
			"additem 903304 99",
			"additem 900304 99",
			"additem 902004 99",
			"additem 902704 99",
			"additem 902804 99",
			"additem 900604 99",
			"additem 900704 99",
			"additem 903004 99",
			"additem 903104 99",
			"additem 902204 99",
			"additem 901904 99",
			"additem 901204 99",
			"additem 4010150 5",
			"additem 4020150 5",
			"additem 4030150 5",
			"additem 4040150 5",
			"additem 4010250 5",
			"additem 4020250 5",
			"additem 4030250 5",
			"additem 4040250 5",
			"additem 16004 1000",
			"additem 17001 99",
			"additem 17002 99",
			"additem 17003 99",
			"additem 17011 999",
			"additem 17012 999",
			"addres 1 9999999999",
			"addres 2 9999999999",
			"addres 3 9999999999",
			"addres 4 9999999999",
			"addcredit 9999999",
		}
	elseif req.cmd == "balabababa4" then
		cmd_list = {
			"addship 111000",
			"addship 111001",
			"addship 112001",
			"addship 121000",
			"addship 121001",
			"addship 122001",
			"addship 131000",
			"addship 131001",
			"addship 132001",
			"addship 141000",
			"addship 141001",
			"addship 142001",
			"addship 112002",
			"addship 113001",
			"addship 113002",
			"addship 122002",
			"addship 123001",
			"addship 123002",
			"addship 132002",
			"addship 133001",
			"addship 133002",
			"addship 143001",
			"addship 143002",
			"addship 114001",
			"addship 113004",
			"addship 124001",
			"addship 114001",
			"addship 113004",
			"addship 114003",
			"addship 124001",
			"addship 123004",
			"addship 133004",
			"addship 134001",
			"addship 134003",
			"addship 144001",
			"addship 143004",
			"addship 144003",
			"addship 124003",
			"addship 115999",
			"addship 115004",
		}

	else
		cmd_list = {req.cmd}
	end

	Tools.print_t(cmd_list)

	local function doLogic( cmd_list )
		
		if user_info.gm_level ~= nil and user_info.gm_level > 0 then

		else
			return 1
		end

		for i,cmd in ipairs(cmd_list) do
			print("index", i)
			local arr = {}
			for w in string.gmatch(cmd, "%S+") do
				table.insert(arr,w)
			end
			Tools.print_t(arr)
			if arr[1] == "addexp" then
				if type(arr[2]) == "string" then

					CoreUser.addExp(tonumber(arr[2]), user_info)

					user_sync.user_info.exp = user_info.exp
					user_sync.user_info.level = user_info.level
				end
			elseif arr[1] == "addstrength" then
				if type(arr[2]) == "string" then
					userInfo:addStrength(tonumber(arr[2]))
					user_sync.user_info.strength = user_info.strength
				end
			elseif arr[1] == "setlevel" then

				if type(arr[2]) == "string" then

					userInfo:resetLevel(tonumber(arr[2]))

					user_sync.user_info.exp = user_info.exp
					user_sync.user_info.level = user_info.level
				end
			elseif arr[1] == "addcredit" then
				if type(arr[2]) == "string" then
					userInfo:addCredit(tonumber(arr[2]))
					user_sync.user_info.money = user_info.money
				end
			elseif arr[1] == "addmoney" then

				if type(arr[2]) == "string" then
					--core_recharge(userInfo, itemList,tonumber(arr[2]), arr[3], 0)
					--user_sync.user_info.achievement_data = user_info.achievement_data
					--user_sync.user_info.money = user_info.money

					platform_add_money(user_info_buff,  item_list_buff,tonumber(arr[2]), arr[3], 0)
				end

			elseif arr[1] == "addequip" then        

				if type(arr[2]) == "string" then

					local equip = require "Equip"
					local equip_info = equip:addEquip(tonumber(arr[2]), user_info)
					if equip_info then
						table.insert(user_sync.equip_list, equip_info)
					end
				end
			elseif arr[1] == "addgem" then        

				if type(arr[2]) == "string" then

					local count = 1
					if type(arr[3]) == "string" then
						count = tonumber(arr[3])
					end

					local equip = require "Equip"
					
					local gem_info = equip:addGem(tonumber(arr[2]), count, user_info)
					if gem_info then
						table.insert(user_sync.gem_list, gem_info)
					end
				end

			elseif arr[1] == "addship" then

				if type(arr[2]) == "string" then
					Tools._print("addship",arr[2])
					local ship_info = shipList:add(tonumber(arr[2]))
					if ship_info then
						table.insert(user_sync.ship_list, ship_info)
						ret = 0
					end
				end
			elseif arr[1] == "addshipexp" then

				if type(arr[2]) == "string" then

						shipList:addLineupExp(tonumber(arr[2]),user_sync)
						ret = 0
				end

			elseif arr[1] == "removeship" then

				if type(arr[2]) == "string" then

					local ship_info = Tools.clone(shipList:getShipInfoByID(tonumber(arr[2])))
					if ship_info then
						ret = shipList:shipRemove(ship_info.guid)
						ship_info.guid = -ship_info.guid
						table.insert(user_sync.ship_list, ship_info)
					end
					
				end
			elseif arr[1] == "initshipstatus" then
				 local ship_list = shipList:getShipList()
				 Tools._print("ship_list count ",#ship_list)
				 for _,ship_info in ipairs(ship_list) do
				 	if Bit:has(ship_info.status, CONF.EShipState.kOuting) then 
					 	ship_info.status = Bit:remove(ship_info.status, CONF.EShipState.kOuting)
					 	table.insert(user_sync.ship_list, Tools.clone(ship_info))
					 end
				 end
			-- elseif arr[1] == "addweapon" then

			--     if type(arr[2]) == "string" then
			--         local weapon_info = userInfo:addWeapon(tonumber(arr[2]))
			--         if weapon_info then
			--             table.insert(user_sync.weapon_list, weapon_info)
			--             ret = 0
			--         end
			--     end

			elseif arr[1] == "removeweapon" then
				if type(arr[2]) == "string" then
					userInfo:removeWeaponByID(tonumber(arr[2]))
				end

			elseif arr[1] == "addres" then
				if type(arr[2]) == "string" and type(arr[3]) == "string" and arr[2] ~= nil and arr[3] ~= nil then
					userInfo:addRes(tonumber(arr[2]),tonumber(arr[3]))
					user_sync.user_info.res = Tools.clone(user_info.res)
				end
			elseif arr[1] == "additem" then
				if type(arr[2]) == "string"  then
					local item_id = tonumber(arr[2])
					if CONF.ITEM[item_id] == nil then
						return 0
					end
					local count = 1
					if type(arr[3]) == "string" then
						count = tonumber(arr[3])
					end
					local items = {}
					items[item_id] = count
					CoreItem.addItems(items,  item_list, user_info)
					CoreItem.makeSync(items, item_list, user_info, user_sync)
				end
			elseif arr[1] == "maxlevel" then

				for i = 1 , 5 do
					for j=1,9 do

						local checkpoint_id = 1010000 + j + 100 * i
						if CONF.CHECKPOINT.check(checkpoint_id) then
							userInfo:setLevelStar(checkpoint_id,1)
						end
					end
				end
			elseif arr[1] == "addbuildinglevel" then
				local index = tonumber(arr[2])
				local building_info = userInfo:getBuildingInfo(index)
				if building_info == nil then
					return 11
				end

				local num = tonumber(arr[3])
				if num == nil then
					num = 1
				end
				for i=1,num do
					if userInfo:upgradeBuildingLevel(index,building_info)  == false then
						break
					end
				end
			elseif arr[1] == "viplevel" then
				user_info.vip_level = tonumber(arr[2])
				user_sync.user_info.vip_level = user_info.vip_level
			elseif arr[1] == "planetmonster" then
				print("gmgmgmgmgmgmgm planetmonster")
				local index = tonumber(arr[2])
				if index == 1 then
					PlanetCache.reflushMonster()
				elseif index == 2 then
					PlanetCache.ClearMonster()
				end
			elseif arr[1] == "cleardayinfo" then
				local timeChecker = require "TimeChecker"
				local dayid = math.random(10000,99999)
				timeChecker.update_at_0am(userInfo,dayid)
			elseif arr[1] == "gmupdatecity" then
				print("ssssssss",arr[1])
				local statu = 2
				if arr[2] ~= nil and arr[2] == "1" then
					statu = 1
				end
				print("ssssssss2222222")
				PlanetCache.gmupdateCity(statu)
			elseif arr[1] == "updatewangzuo" then
				print("updatewangzuo",arr[1])
				local statu = 2
				if arr[2] ~= nil and arr[2] == "1" then
					statu = 1
				end
				print("updatewangzuo end")
				PlanetCache.gmupdateWangZuo(statu)
			elseif arr[1] == "clearguide" then
				local guide_list = user_sync.user_info.achievement_data.guide_list
				if arr[2] == nil then
					for i=2,30 do
						guide_list[i] = 0
					end
				else
					local id = tonumber(arr[2])
					if id > 0 and id <= 30 then
						guide_list[id] = 0
					end
				end
				user_sync.user_info.achievement_data.guide_list = guide_list
 			end
		end

		return 0
	end

	local ret = doLogic(cmd_list)


	local resp =
	{
		result = ret,
		user_sync = user_sync,
	}

	user_info_buff = userInfo:getUserBuff()
	ship_list_buff = shipList:getShipBuff()
	item_list_buff = itemList:getItemBuff()

	local resp_buff = Tools.encode("CmdClientGMResp", resp)

	return resp_buff, user_info_buff, ship_list_buff, item_list_buff
end

function gm_fight_sim_feature(step, req_buf, user_name)
	if step == 0 then
		local pb = require "protobuf"
		local req = pb.decode("GMFightReq", req_buf)
		local resp = {
			result = "FAIL",
			user = req.user,
			battle = req.battle,
			num = req.num,
			difficult = req.difficult,
			fd = req.fd,
			session = req.session
		}
		return 1, pb.encode("GMFightResp", resp)
	elseif step == 1 then
		local pb = require "protobuf"
		local req = pb.decode("GMFightReq", req_buf)
		return datablock.main_data,req.user
	else
		error("something error");
	end
end

function gm_fight_sim_do_logic(req_buf, user_name, main_data_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", main_data_buf)
	local req = pb.decode("GMFightReq", req_buf);
	local resp = {
		result = "OK",
		user = req.user,
		battle = req.battle,
		num = req.num,
		difficult = req.difficult,
		win = 0,
		fd = req.fd,
		session = req.session,
	}
	local fight = Fight:new()
	
	
	fight:pve_sim(main_data, req.battle, req.difficult, req.num, resp)
	
	local resp_buf = pb.encode("GMFightResp", resp)
	return resp_buf,main_data_buf
end


function gm_add_item_feature(step, req_buf, user_name)
	if step == 0 then

		local req = Tools.decode("GMAddItemReq", req_buf)
		local resp = {
			result = "FAIL",
			fd = req.fd,
			session = req.session
		}
		return 1
	elseif step == 1 then

		local req = Tools.decode("GMAddItemReq", req_buf)
		LOG_DEBUG("gm_add_item_feature GMAddItemReq"..req.user)
		return datablock.main_data + datablock.item_package + datablock.save,req.user
	else
		error("something error");
	end
end

function gm_add_item_do_logic(req_buff, user_name, user_buff, item_buff)   
 
	local req = Tools.decode("GMAddItemReq", req_buff)

	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	
	userInfo:new(user_buff)
	itemList:new(item_buff)
	
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	
	local item_id = req.item_id
	local item_num = req.item_num    
	CoreItem.addItem(item_id, item_num, item_list, user_info)  
	local resp =
	{
		result = "OK",
		fd = req.fd,
		session = req.session,
	}
	if req.gm_user ~= "test" or req.gm_pswd ~= "test" then
		error("gm user err")
	end

	LOG_INFO("GMAddItemResp," .. Tools.toString(user_info))

	local resp_buff = Tools.encode("GMAddItemResp", resp)
	user_buff = userInfo:getUserBuff()
	item_buff = itemList:getItemBuff()
	return resp_buff, user_buff, item_buff
end