local scheduler = cc.Director:getInstance():getScheduler()

local Tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local winSize = cc.Director:getInstance():getWinSize()

local animManager = require("app.AnimManager"):getInstance()

local g_sendList = require("util.SendList"):getInstance()

local Player = class("Player")

local schedulerEntry = nil

local g_updateTimeStamp = 60
local g_timeStamp = 0

local itemUpdateTab = {
	equip = {},
	gem = {},
	drawing = {},
	item = {},
} 

function Player:getItemUpdateTab()
	return itemUpdateTab
end

function Player:initInfo( protoData )

	g_sendList:clear()
	
	self.data_ = protoData


	self.mail_list_ = nil

	self.group_main_ = nil

	self.planet_info_ = nil

	self.ride_res_info_ = nil

	self.planet_user = nil
	self.planet_element = nil
	self.planet_node_army_list = nil
	self.activity_id_list = nil
	self.chat_star_point = false

	self.broadcast_run_list = {
	-- "澳门首家线上赌场上线了,美女荷官真人在线发牌……",
	-- "九蒸一饭会制裁你",
	-- "我的炒蛋会把你撕成碎片",
	-- "你无法抵挡金排骨的力量",
	-- "香菇蒸鸡会将你吞没",
	-- "你的灵魂将受到折磨",
	-- "你将成为我的猎物",
	-- "屠龙宝刀，点击就送",
	-- "皇城PK，胜者为王",
	-- "我不断的寻找，油腻的师姐在哪里",
	-- "我是黄渤我在九蒸一饭等你",
	{str = CONF:getStringValue("HERO_LEVEL_1"), type = 1},
	}
	self.last_chat = nil

	if self.data_ ~= nil then
		local list = {1,3,4,5,7,10,11,12,13,14,15,16}
		for i,v in ipairs(list) do
			if self.data_.user_info.building_list[v] == nil then
				local strData = Tools.encode("BuildingUpdateReq", {
				   index = v,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPDATE_REQ"),strData)

			end
		end
	end

end


function Player:isInited()
	return self.data_ ~= nil
end

function Player:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end
		
	return self.instance
end

function Player:getServerTime()
	if self.data_ then
		return self.data_.nowtime
	end
	return nil
end

function Player:getServerDate()
	-- local now = os.time()
	-- local localTimeZone = os.difftime(now, os.time(os.date("!*t", now)))
	-- return os.date("*t", self:getServerTime() - localTimeZone)--计算出服务端时区与客户端时区差值
	if g_is_global_server then
		return os.date("!*t",self:getServerTime())
	else
		return os.date("*t",self:getServerTime())
	end
end

function Player:getIsTodayOne( ... )
	-- BUG WJJ 20180718
	-- local time = cc.UserDefault:getInstance():getIntegerForKey("PlanetJumpTime")
	local time = cc.exports.PlanetJumpTime
	if not time then
		return true
	end
	local localTimeZone = os.difftime(time, os.time(os.date("!*t", time)))
	local default_date = os.date("*t", self:getServerTime() - localTimeZone)

	local server_date = self:getServerDate()

	if default_date.year == server_date.year and default_date.month == server_date.month and default_date.day == server_date.day then
		return false
	else
		return true
	end
end

function Player:getServerDateString()

	if self.data_ == nil then
		return ""
	end

	local date = self:getServerDate()

	local date_str = string.format("year:%d/month:%d/day:%d/hour:%d/min:%d/sec:%d", date.year, date.month, date.day, date.hour, date.min, date.sec)

	return date_str

end

function Player:getPlayerState( ... )
	return self.data_.user_info.state
end

function Player:getPlayerIcon()
	return self.data_.user_info.icon_id
end

function Player:getName()
	return self.data_.user_info.user_name
end

function Player:getNickName()
	return self.data_.user_info.nickname
end

function Player:getVipLevel()
	return self.data_.user_info.vip_level
end

function Player:getLevel()
	return self.data_.user_info.level
end

function Player:getStrength()
	return self.data_.user_info.strength
end

function Player:setStrength(value)
	self.data_.user_info.strength = value
end

function Player:getMaxStrength()

	if self.group_main_ ~= nil then
		return Tools.getMaxStrength(self:getLevel(), self.group_main_.tech_list)
	else
		return Tools.getMaxStrength(self:getLevel())
	end
end

function Player:getExp()
	return self.data_.user_info.exp
end

function Player:getNowExp()
	
	local exp = 0

	if self:getLevel() == 1 then
		exp = self:getExp()
	else
		exp = self:getExp() - CONF.PLAYERLEVEL.get(self:getLevel()-1).EXP_ALL
	end
	
	return exp
end

function Player:getNextLevelExpPercent()

	local conf = CONF.PLAYERLEVEL.get(self:getLevel())

	if not conf then
		return nil
	end

	local cur = self:getExp() - conf.EXP_ALL + conf.EXP
	

	return cur / conf.EXP * 100
end

function Player:getResByIndex( index )
 
	if index < 1 or index > #self.data_.user_info.res then
		return nil
	end

	return self.data_.user_info.res[index]
end

function Player:setResByIndex(index, num)
	if index < 1 or index > #self.data_.user_info.res then
		return 
	end

	self.data_.user_info.res[index] = self.data_.user_info.res[index] + num
end

function Player:getMoney()
	return self.data_.user_info.money
end

function Player:setMoney( credit )
	self.data_.user_info.money = credit
end

function Player:getBagItems()
	return self.data_.item_list.item_list
end

function Player:getBagEquips()
	return self.data_.user_info.equip_list
end


function Player:getGroupName( )

	if self.data_.user_info.group_data.groupid == nil or self.data_.user_info.group_data.groupid == "" then
		return ""
	else
		if self.group_main_ then
			return self.group_main_.nickname
		else
			return ""
		end
	end
end

function Player:getGroupHasWar( ... )
	if self.group_main_ then
		local num = #self.group_main_.enlist_list + #self.group_main_.attack_our_list

		return num > 0 and true or false
	end

	return false
end

function Player:getBuildingInfo(index)
	if index < 1 or index > CONF.EBuilding.count then
		return nil
	end

	return self.data_.user_info.building_list[index]
end

function Player:setBuildingInfo(index , info)
	if index < 1 or index > CONF.EBuilding.count then
		return
	end

	self.data_.user_info.building_list[index] = info

end

function Player:getBuildingList(  )
	return self.data_.user_info.building_list
end

function Player:getBlueprint_list()
	return self.data_.user_info.blueprint_list
end

function Player:setBlueprint_list(list)
	self.data_.user_info.blueprint_list = list
end

function Player:getShipEnergyEndTime()
	return self.data_.user_info.ship_energy_end_time
end

function Player:getShipEnergyTimeLock()
	return self.data_.user_info.ship_energy_time_lock
end

function Player:getBuildingPower( ... )
	local list = {1,3,4,5,7}

	local power = 0
	for i,v in ipairs(self.data_.user_info.building_list) do
		local has = false
		for i2,v2 in ipairs(list) do
			if v2 == i then
				has = true
				break
			end
		end

		if has then
			power = CONF["BUILDING_"..i].get(v.level).FIGHT_POWER + power
		end
	end

	return power
end

local function syncInfo( list, info, id_name )

	local has = false

	local key = id_name or "guid"

	local id = info[key] > 0 and info[key] or -info[key]
	
	for i=1, #list do
		if id == list[i][key] then

			has = true

			if info[key] > 0 then
	
				list[i] = info
			else
	
				table.remove(list, i)
			end
			
			break
		end
	end

	if has == false then
		table.insert(list, info)

	end

	return flag
end

function Player:userSync( user_sync )
	if user_sync.user_info then
		--printInfo("user_info")
		local level = self.data_.user_info.level
		local level_info = self.data_.user_info.stage_data.level_info -- level_id 

		for k,v in pairs(user_sync.user_info) do
			print("userSync name", k)
			self.data_.user_info[k] = v

			if (type(v)=="number" or type(v)=="string") then
				print(k,v,type(v))
			end
			
			if k == "new_hand_gift_bag_data" then
				-- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("new_hand_gift")
				cc.exports.new_hand_gift_bag_data = true
			end

			if k == "level" then

			elseif k == "exp" then
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("ExpUpdated")
			elseif k == "res" then
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("ResUpdated")
			elseif k == "money" then

				local money_num = 0

				if v == nil then
					money_num = 0
				else
					money_num = v
				end

				flurryLogEvent("player_money_info", {money = tostring(money_num)}, 1, money_num)

				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("MoneyUpdated")
			elseif k == "tech_data" then
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("TechUpdated")
			elseif k == "strength" then 
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
			elseif k == "stage_data" then
				local level_id = {1010305,2010407,3010509,4010709,5010809,6010909,7010909}
				local index = 0

				for i2,v2 in ipairs(level_id) do

					local fight = false
					for i3,v3 in ipairs(level_info) do
						if v3.level_id == v2 then
							fight = true
							break
						end
					end

					if not fight then
						index = i2 
						break
					end
				end
				

				local fight = false
				for i2,v2 in ipairs(v.level_info) do
					if v2.level_id == level_id[index] then
						fight = true
						break
					end
				end

				if fight then
					-- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("tongguan")

					local event = cc.EventCustom:new("tongguan")
					event.index = index
					event.flag = fight
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

				end

			end
		end
		
	end

	if not Tools.isEmpty(user_sync.group_main) then
		printInfo("group_main")
		local event = cc.EventCustom:new("group_main")
		event.group_main = user_sync.group_main
		cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
	end

	if not Tools.isEmpty(user_sync.ship_list)  then
		printInfo("ship_list")
		for i,v in ipairs(user_sync.ship_list) do
			syncInfo(self.data_.ship_list.ship_list,v)
		end
	end

	if not Tools.isEmpty(user_sync.weapon_list) then
		printInfo("weapon_list")
		for i,v in ipairs(user_sync.weapon_list) do
			syncInfo(self.data_.user_info.weapon_list,v)
		end
	end

	if not Tools.isEmpty(user_sync.equip_list) then
		printInfo("equip_list")
		for i,v in ipairs(user_sync.equip_list) do
			if v.guid < 0 then
				if itemUpdateTab.equip[math.abs(v.guid)] then
					itemUpdateTab.equip[math.abs(v.guid)] = nil
				end
			else
				if not itemUpdateTab.equip[v.guid] then
					local nohave = true
					for k,equip in ipairs(self.data_.user_info.equip_list) do
						if equip.guid == v.guid then
							nohave = false
							break
						end
					end
					if nohave and v.ship_id == 0 then
						--itemUpdateTab.equip[v.guid] = v.equip_id
					end
				else
					if v.ship_id > 0 and itemUpdateTab.equip[v.guid] then
						itemUpdateTab.equip[v.guid] = nil
					end
				end
			end	
			syncInfo(self.data_.user_info.equip_list,v)
		end
	end
	if not Tools.isEmpty(user_sync.gem_list) then
		printInfo("gem_list")
		for i,v in ipairs(user_sync.gem_list) do
			local id  = math.abs(v.id)
			if v.id > 0 then
				if not itemUpdateTab.gem[id] then
					if self:getItemNumByID(id) < v.num then
						--itemUpdateTab.gem[id] = v.num
					end
				end
			else
				if itemUpdateTab.gem[id] then
					itemUpdateTab.gem[id] = nil
				end
			end
			syncInfo(self.data_.user_info.gem_list,v, "id")
		end
	end

	if not Tools.isEmpty(user_sync.activity_list) then
		printInfo("activity_list")
		for i,v in ipairs(user_sync.activity_list) do
			syncInfo(self.data_.user_info.activity_list,v, "id")
		end
	end
	if not Tools.isEmpty(user_sync.item_list) then
		printInfo("item_list")

		local str = ""
		for i,v in ipairs(user_sync.item_list) do

			str = str.."id:"..v.id.."num:"..v.num..","

			local itemConf = CONF.ITEM.get(v.id)
			if itemConf.BAG_TYPE == 1 then
				if not itemUpdateTab.item[v.id] then
					if self:getItemNumByID(v.id) < v.num then
						--itemUpdateTab.item[v.id] = v.num
					end
				else
					if v.num <= itemUpdateTab.item[v.id] then
						itemUpdateTab.item[v.id] = nil
					end
				end
			elseif itemConf.BAG_TYPE == 4 then
				if not itemUpdateTab.drawing[v.id] then
					if self:getItemNumByID(v.id) < v.num then
						--itemUpdateTab.drawing[v.id] = v.num
					end
				else
					if v.num <= itemUpdateTab.drawing[v.id] then
						itemUpdateTab.drawing[v.id] = nil
					end
				end
			end
			syncInfo(self.data_.item_list.item_list,v)
		end

		flurryLogEvent("user_item_list_update", {info = str}, 2)

	end

	if not Tools.isEmpty(user_sync.task_list) then
		printInfo("task_list")
		for i,v in ipairs(user_sync.task_list) do
			syncInfo(self.data_.user_info.task_list, v, "task_id")
		end
	end

	if not Tools.isEmpty(user_sync.slave_data) then
		printInfo("slave_data")
	
		self.slave_data_ = user_sync.slave_data
	end

	if not Tools.isEmpty(user_sync.forge_equip_list) then
		printInfo("forge_equip_list")
		for i,v in ipairs(user_sync.forge_equip_list) do
			syncInfo(self.data_.user_info.forge_equip_list, v)
		end
	end

	--[[if not Tools.isEmpty(user_sync.friends_data) then
		printInfo("friends_data")
		self.data_.user_info.friends_data = user_sync.friends_data
	end]]
end

function Player:ctor()

	local function recvMsg()
		

		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		printInfo("Player:recvMsg:"..cmd)

		if not self:isInited() then
			return
		end


		if cmd == Tools.enum_id("CMD_DEFINE","CMD_LOGIN_RESP") then

			local proto = Tools.decode("LoginResp",strData)
			printInfo("login result:"..proto.result)
			if gl:isLoading() == true then
				gl:releaseLoading()
			end
			return
		end

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_HEART_BEAT_RESP") then

			local proto = Tools.decode("HeartBeatResp",strData)
			if proto.result == "OK" then
				self.data_.nowtime = proto.nowtime
				printInfo("update time:",self.data_.nowtime)
			end
			return
		end
	
		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_CHAT_MSG") then
			local proto = Tools.decode("ChatMsg", strData)
			if proto.channel == 2 then  --公会

				printInfo("公会")

				self.chat_star_point = true

				local event = cc.EventCustom:new("leagueMsg")
				event.chat = proto
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

				return
			end

			if proto.sender.uid == "" and proto.recver.uid ~= "" then  --公告 有收件人 无发件人
				printInfo("公告")

				local event = cc.EventCustom:new("announcementMsg")
				event.chat = proto
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

			elseif (proto.sender.uid ~= "" and proto.recver.uid == "") or (proto.sender.uid == "" and proto.recver.uid == "") then -- 世界or广播 有发件人 无收件人

				if proto.type == 0 then
					if proto.minor[1] and proto.minor then
						
						if proto.minor[1] == 2 then
							Tips:tips(CONF:getStringValue("res_bei_plunder"))

							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("res_bei_plunder")
						elseif proto.minor[1] == 1 then

							printInfo("星球占领")

							local event = cc.EventCustom:new("planetMsg")
							event.chat = proto
							cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
						elseif proto.minor[1] == 3 then
							printInfo("殖民消息")

							local event = cc.EventCustom:new("slaveMsg")
							event.chat = proto.minor
							cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

						elseif proto.minor[1] == 4 then
							printInfo("新星球占领")

							local node_id_list = {}
							for i,v in ipairs(proto.minor) do
								if i >= 2 then
									table.insert(node_id_list, v)
								end
							end

							local app = require("app.MyApp"):getInstance()
							local scene_name = app:getTopViewName()
							if scene_name ~= "PlanetScene/PlanetScene" and scene_name ~= "BattleScene/BattleScene" then

								if self.planet_user then
									local has = false
									for i,v in ipairs(node_id_list) do
										if tonumber(v) == tonumber(Split(self.planet_user.base_global_key,"_")[1]) then
											has = true
											break
										end 
									end

									if has then
										local strData = Tools.encode("PlanetGetReq", {
											type = 1,
										 })
										GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
									end
								end
							else
								local event = cc.EventCustom:new("newPlanetMsg")
								event.node_id_list = node_id_list
								cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 
							end

						end
					else
						printInfo("世界")

						local event = cc.EventCustom:new("worldMsg")
						event.chat = proto
						cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
					end

				elseif proto.type == 1 or proto.type == 2 then
					printInfo("广播")

					self:addBroadcastList(proto.msg, proto.type)

					if not g_broadcast_run then
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("broadcastRun")
					end

					local event = cc.EventCustom:new("broadcastMsg")
					event.chat = proto
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

				end

			elseif proto.sender.uid ~= "" and proto.recver.uid ~= "" then

				printInfo("私聊")

				local event = cc.EventCustom:new("chatMsg")
				event.chat = proto
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

			end

			return 
		end

		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_GROUP_UPDATE") then
			local proto = Tools.decode("GroupUpdate", strData)
			--print("CMD_GROUP_UPDATE111111111111111")
			--dump(proto)
			for i,v in ipairs(proto.user_update_list) do
				if v.user_name == self:getName() then
					dump(v)
					if v.user_sync ~= nil then
						self.data_.user_info.group_data = v.user_sync.user_info.group_data
						self:userSync(v.user_sync)
					end
				end
			end
			if proto.group_main ~= nil then
				if self:getPlayerGroupMain() and self:getPlayerGroupMain().groupid and self:getPlayerGroupMain().groupid ~= "" then
					if proto.group_main.groupid == self:getPlayerGroupMain().groupid then
						self:setPlayerGroupMain(proto.group_main)

						local event = cc.EventCustom:new("group_main")
						event.group_main = proto.group_main
						cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
					end
				else
					self:setPlayerGroupMain(proto.group_main)

					local event = cc.EventCustom:new("group_main_noGroupid")
					event.group_main = proto.group_main
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
				end
			end

			return
		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_NEW_GROUP_UPDATE") then

			local proto = Tools.decode("NewGroupUpdate", strData)
			Tips:tips(CONF:getStringValue("group_invite_mail"))

			return
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_RESP") then
			local proto = Tools.decode("PlanetRideBackResp", strData)
			if proto.result == "OK" then
				-- self:userSync(proto.user_sync)
				print("@player reset ship_list")
				player:setShipList(proto.user_sync.ship_list)				
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_USER_SYNC_UPDATE") then

			printInfo("CMD_USER_SYNC_UPDATE")
			local user_sync = Tools.decode("UserSync", strData)
			Tools.extract(user_sync)
			self:userSync(user_sync)
			return

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_MAIL_LIST_UPDATE") then

			return
		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_FRIEND_APPLY_UPDATE") then
			

			local proto = Tools.decode("NewFriendUpdate", strData)

			printInfo("NewFriendUpdate sender "..proto.sender)
			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("NewFriendUpdate")

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_BE_FRIEND_UPDATE") then
			local proto = Tools.decode("BeFriendUpdate", strData)

			printInfo("BeFriendUpdate")
			-- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("BeFriendUpdate")

			local strData = Tools.encode("GetFriendsInfoReq", {
				type = 1,
				index = 1,
				num = 999,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_REQ"),strData)

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_FRIENDS_INFO_RESP") then

			local proto = Tools.decode("GetFriendsInfoResp",strData)
			printInfo("update friend")

			local friends_list = {}
			for i,v in ipairs(proto.list) do
				table.insert(friends_list, v.user_name)
			end

			if proto.type == 1 then
				if proto.result == 2 then
					self.data_.user_info.friends_data.friends_list = {}
				elseif proto.result == 0 then
					self.data_.user_info.friends_data.friends_list = friends_list
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_GET_TECH_RESP") then
			local proto = Tools.decode("GroupGetTechResp",strData)

			if proto.result ~= 0 then
				printInfo("error :"..proto.result)
			else
				printInfo("tech upgrade finish")

				self.group_main_ = proto.user_sync.group_main

				local tech_str = ""
				local tech_num = 0
				for i,v in ipairs(self.group_main_.tech_list) do
					if v.status == 1 then
						if v.tech_id%10 > 1 then
							if tech_str ~= "" then
								tech_str = tech_str.."-"
							end

							tech_str = tech_str..v.tech_id
							tech_num = tech_num + 1
						end

					end
				end

				flurryLogEvent("group_tech_info",{tech_str = tech_str, tech_num = tostring(tech_num)}, 2)

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SHIP_FIX_RESP") then
			local proto = Tools.decode("ShipFixResp",strData)

			print("CMD_SHIP_FIX_RESP result", proto.result)

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_LIST_RESP") then
			local proto = Tools.decode("GroupHelpListResp",strData)

			if proto.result ~= "OK" then
				printInfo("error :"..proto.result)
			else
				if self.group_main_ then
					self.group_main_.help_list = proto.help_list
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPDATE_RESP") then

			local proto = Tools.decode("BuildingUpdateResp",strData)
	
			if proto.result == 0 then

				if proto.index == 4 then
					local strData = Tools.encode("WeaponUpgradeReq", {
							type = 1,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_WEAPON_UPGRADE_REQ"),strData)
				end

				flurryLogEvent("build_level_up", {build_num = tostring(proto.index), build_level = tostring(self:getBuildingInfo(proto.index).level)}, 2)
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_TECHNOLOGY_RESP") then
			local proto = Tools.decode("GetTechnologyResp",strData)
					if proto.result == 0 then
						if proto.hasUpgrade == true then
							flurryLogEvent("technology", {tech_num = tostring( self:getTechnolgListNum()), tech_power = tostring(self:getTechPower()) , 2})
				end
					end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_UPDATE_TIMESTAMP_RESP") then

			local proto = Tools.decode("UpdateTimeStampResp",strData)

			if proto.result == 0 then
				if self.data_.user_info.blocked.type == 1 then
					local app = require("app.MyApp"):getInstance()
					app:pushToRootView("LoginScene/LoginScene")
				end
					end
				elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SERVER_RES_UPDATE") then

			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPDATE_RES_REQ"),"0")

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_UPDATE_RES_RESP") then

			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("ResUpdated")

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_USER_UPDATE") then

			local strData = Tools.encode("PlanetGetReq", {
				type = 1,
			 })
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then
			local proto = Tools.decode("PlanetGetResp",strData)
		
			if proto.result == 0 then

				local app = require("app.MyApp"):getInstance()
				local scene_name = app:getTopViewName()

				if proto.type == 1 then
					self:setPlayerPlanetUser(proto.planet_user)	

					if scene_name ~= "PlanetScene/PlanetScene" and scene_name ~= "BattleScene/BattleScene" then
						local strData = Tools.encode("PlanetGetReq", {
							type = 3,
							element_global_key_list = {proto.planet_user.base_global_key},
						 })
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
					end
				elseif proto.type == 2 then
					if scene_name ~= "PlanetScene/PlanetScene" and scene_name ~= "BattleScene/BattleScene" then

						if not Tools.isEmpty(proto.node_list[1].army_line_key_list) then
							local strData = Tools.encode("PlanetGetReq", {
								type = 4,
								army_line_key_list = proto.node_list[1].army_line_key_list,
							 })
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
						end
					end
				elseif proto.type == 3 then
					self.planet_element = Tools.isEmpty(proto.element_list) == false and proto.element_list[1]
					if not self.planet_element then
						return
					end
					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("planetUserUpdate")
					if scene_name ~= "PlanetScene/PlanetScene" and scene_name ~= "BattleScene/BattleScene" then
						local strData = Tools.encode("PlanetGetReq", {
							type = 2,
							node_id_list = {Split(proto.element_list[1].global_key, "_")[1]},
						 })
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
					end
				elseif proto.type == 4 then
					if scene_name ~= "PlanetScene/PlanetScene" and scene_name ~= "BattleScene/BattleScene" then
						self.planet_node_army_list = proto.planet_army_line_list
					end
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_RESP") then

			local proto = Tools.decode("PlanetRideBackResp",strData)

			if proto.result == "OK" then
				self.planet_user = proto.planet_user

			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SDK_PAY_CALLBACK") then

			printInfo("CMD_SDK_PAY_CALLBACK", strData)
			printInfo(string.len(strData))
			-- local proto = Tools.decode("PlanetRideBackResp",strData)

			-- if proto.result == "OK" then
			-- 	self.planet_user = proto.planet_user

  			 --end
			local output = json.decode(strData,1)
			local event = cc.EventCustom:new("payCallback")
			dump(output)
			local succeed = false
			if output.result == 0 then
				succeed = true
			end
			local productID = output.productid

			local pcb = {productID = productID, succeed = succeed}

			self.data_.user_info.vip_level = output.vip_level
			--if self.data_.user_info.achievement_data and output.recharge_money then
			--	self.data_.user_info.achievement_data.recharge_money = output.recharge_money
			--end

			event.info = pcb
			cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("ExpUpdated")
			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("ResUpdated")
			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("MoneyUpdated")
			print("CMD_SDK_PAY_CALLBACK end")
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_TOWER_RESP") then
			return
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_FRIEND_TILI_UPDATE") then
			print("CMD_FRIEND_TILI_UPDATE",strData)
			return
		end
		

		local resp = Tools.decode("UserSyncResp", strData)
		if type(resp) == "table" and resp.user_sync ~= nil and (resp.result == 0 or resp.result == "OK") then
			Tools.extract(resp)
			self:userSync(resp.user_sync)
		end	
	end

	self.recvListener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

	eventDispatcher:addEventListenerWithFixedPriority(self.recvListener_, FixedPriority.kFirst)


	-- update player info functions
	local function updateBuildings()

		local list = {1,3,4,5,7,10,11,12,13,14,16}
		for i,v in ipairs(list) do

			local buildingInfo = self:getBuildingInfo(v)
			if buildingInfo then
				if buildingInfo.upgrade_begin_time and buildingInfo.upgrade_begin_time > 0 then

					local cdTime =  CONF[string.format("BUILDING_%d",v)].get(buildingInfo.level).CD + Tools.getValueByTechnologyAddition(CONF[string.format("BUILDING_%d",v)].get(buildingInfo.level).CD, CONF.ETechTarget_1.kBuilding, v, CONF.ETechTarget_3_Building.kCD, self:getTechnolgList(), self:getPlayerGroupTech())

					if (self:getServerTime() - cdTime) > buildingInfo.upgrade_begin_time then

						local strData = Tools.encode("BuildingUpdateReq", {
						   index = v,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPDATE_REQ"),strData)
					 end

				end
	
			end
			
		end
 
	end

	local function updateTrade( ... )
		local buildingInfo = self:getBuildingInfo(CONF.EBuilding.kTrade)
		if buildingInfo then
			if buildingInfo.upgrade_exp and CONF.BUILDING_15.get(buildingInfo.level).EXP then
				if buildingInfo.upgrade_exp > CONF.BUILDING_15.get(buildingInfo.level).EXP  then
					local strData = Tools.encode("BuildingUpdateReq", {
					   index = CONF.EBuilding.kTrade,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPDATE_REQ"),strData)
				end
				
			end

		end
	end



	local function updateTechnologys( )

		for i,v in ipairs(self.data_.user_info.tech_data.tech_info) do

			if v.begin_upgrade_time and v.begin_upgrade_time > 0 then

				local cdTime =  CONF.TECHNOLOGY.get(v.tech_id).CD

				if (self:getServerTime() - cdTime) >= v.begin_upgrade_time then

					local strData = Tools.encode("GetTechnologyReq", {
					   tech_id = v.tech_id,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_TECHNOLOGY_REQ"),strData)
				end

			end

		end

	end

	local function updateGroupTech( )

		if self.group_main_ then
			for i,v in ipairs(self.group_main_.tech_list) do
				if v.status == 2 then
					local conf = CONF.GROUP_TECH.get(v.tech_id)
					if self:getServerTime() - v.begin_upgrade_time >= conf.CD then
						local strData = Tools.encode("GroupGetTechReq", {
							tech_id = v.tech_id,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_GET_TECH_REQ"),strData)
					end

					break
				end
			end
		end
	end

	local function updatePlanet( )

		if self.ride_res_info_ then

			for i,v in ipairs(self.ride_res_info_) do
				local collect_speed = v.collect_speed
				local res_conf = CONF.PLANET_RES.get(v.id)
				if res_conf then
					collect_speed =  self:getValueByTechnologyAdditionGroup(collect_speed, CONF.ETechTarget_1.kWorldRes, res_conf.TYPE, CONF.ETechTarget_3_Res.kCollect)
				end

				if ((v.cur_storage/collect_speed) - (self:getServerTime() - v.begin_time)) <= 0 then
					local strData = Tools.encode("PlanetRideBackReq", {
						ride_guid = {v.ride_guid},
						type = 1,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData)

					for i2,v2 in ipairs(self.data_.user_info.planet_data.ride_list) do
						if v2.guid == v.ride_guid then
							self.data_.user_info.planet_data.ride_list[i2] = {}
						end
					end
					

					table.remove(self.ride_res_info_, i)
				end
			end
		end
	end

	local strengthTimer = 0
	local function updateStrength( )
		
		if strengthTimer > 300 or strengthTimer == 0 then
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_STRENGTH_REQ"),0)
			strengthTimer = 0
			
			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("StrengthUpdated")
		end
		strengthTimer = strengthTimer + 1
		
	end

	local function updateQueue( )

		if self.data_.user_info.build_queue_list[2] then

			if self.data_.user_info.build_queue_list[2].open_time > 0 then

				local info = self.data_.user_info.build_queue_list[2]				
				local time = info.duration_time - (self:getServerTime() - info.open_time)
				if time <= 0 then

					local strData = Tools.encode("BuildQueueRemoveReq", {
						index = 2,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BUILD_QUEUE_REMOVE_REQ"),strData)
				end
			end
		end
	end

	local function updateRepairing(  )

		local Bit = require "Bit"

		for k,v in pairs(self.data_.ship_list.ship_list) do

			if Bit:has(v.status, 2) == true then
				local totleTime = Tools.getFixShipDurableTime(v ,self.data_.user_info ) 
				local needTime = totleTime - (self:getServerTime() - v.start_fix_time)
				if needTime <= 0 then ---修理完毕
					local strData = Tools.encode("ShipFixReq", {
						type = 1 ,
						guids ={v.guid},
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_FIX_REQ"),strData) 
				end
			end
		end
	end


	local function updateTimeStamp()
		local cur_time = self:getServerTime()
		if cur_time - g_timeStamp > g_updateTimeStamp then
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPDATE_TIMESTAMP_REQ"),"0")
			g_timeStamp = cur_time
		end
	end

	local function updatePlanetUser( ... )
		if self.planet_user and self.planet_user.army_list then
			for i,v in ipairs(self.planet_user.army_list) do

				if v.status == 3 then--Status.kMoveEnd then

					local strData = Tools.encode("PlanetRideBackReq", {
						army_guid = {v.guid},
						type = 1,
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData) 

					local event = cc.EventCustom:new("nodeUpdated")
					event.node_id_list = {tonumber(Tools.split(v.element_global_key, "_")[1])}
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

					
					if v.status_machine == 2 or v.status_machine == 3 or v.status_machine == 6 then

						for i2,v2 in ipairs(v.item_list) do
							if v2.id == 3001 then
								flurryLogEvent("get_gold_by_planet", {machine = v.status_machine, info = "before_use:"..self:getResByIndex(1)..",after_use:"..(self:getResByIndex(1) + v2.num)}, 1, v2.num)
							elseif v2.id == 7001 then
								flurryLogEvent("get_credit_by_planet", {machine = v.status_machine, info = "before_use:"..self:getResByIndex(1)..",after_use:"..(self:getResByIndex(1) + v2.num)}, 1, v2.num)
							end
						end
						
					end

					local lineup_power = 0
					for i2,v2 in ipairs(v.ship_list) do
						lineup_power = lineup_power + self:calShipFightPowerByInfo(v2)
					end

					local time = getNowDateString()

					local item_str = "item:"
					for i2,v2 in ipairs(v.item_list) do
						item_str = item_str.."id:"..v2.id.."num:"..v2.num.." "
					end

					local lineup_str = "form:"
					for i2,v2 in ipairs(v.lineup) do
						lineup_str = lineup_str..v2..","
					end

					local str = "lineup_power:"..lineup_power.."-".."time:"..time.."-"..item_str.."-"..lineup_str
					if v.status_machine == 1 then
						flurryLogEvent("planet_res_back", {machine = v.status_machine, info = str}, 2)
					elseif v.status_machine == 2 then
						flurryLogEvent("planet_runis_back", {machine = v.status_machine, info = str}, 2)
					elseif v.status_machine == 3 then
						flurryLogEvent("planet_fishing_back", {machine = v.status_machine, info = str}, 2)
					elseif v.status_machine == 4 then
						flurryLogEvent("planet_spy_back", {machine = v.status_machine, info = str}, 2)
					elseif v.status_machine == 5 then
						flurryLogEvent("planet_be_stationed_back", {machine = v.status_machine, info = str}, 2)
					elseif v.status_machine == 6 then
						flurryLogEvent("planet_atk_base_back", {machine = v.status_machine, info = str}, 2)
					elseif v.status_machine == 7 then
						flurryLogEvent("planet_mass_back", {machine = v.status_machine, info = str}, 2)
					elseif v.status_machine == 8 then
						flurryLogEvent("planet_atk_city_back", {machine = v.status_machine, info = str}, 2)
					elseif v.status_machine == 9 then
						flurryLogEvent("planet_atk_boss_back", {machine = v.status_machine, info = str}, 2)
					elseif v.status_machine == 10 then

						if v.next_status_machine == 6 then
							flurryLogEvent("planet_all_atk_base_back", {machine = v.status_machine, info = str}, 2)
						elseif v.next_status_machine == 8 then
							flurryLogEvent("planet_all_atk_city_back", {machine = v.status_machine, info = str}, 2)
						end
					end

				end
			end

		end
	end

	local function updatePlanetArmy( ... )
		-- if self.planet_node_army_list and self.planet_element then
		-- 	local app = require("app.MyApp"):getInstance()
		-- 	local scene_name = app:getTopViewName()
		-- 	if scene_name ~= "PlanetScene/PlanetScene" and scene_name ~= "BattleScene/BattleScene" then
		-- 		local view = app:getTopView()

		-- 		local base_x = self.planet_element.pos_list[1].x 
		-- 		local base_y = self.planet_element.pos_list[1].y

		-- 		local has = false
		-- 		for i,v in ipairs(self.planet_node_army_list) do
		-- 			local move_list_num = #v.move_list
		-- 			local name = Split(v.user_key,"_")[1]
		-- 			if name ~= self:getName() then
		-- 				if v.move_list[move_list_num].x == base_x and v.move_list[move_list_num].y == base_y then
		-- 					if (v.need_time - v.sub_time) - ( self:getServerTime() - v.begin_time) >= 0 then
		-- 						if self:checkPlayerIsInGroup(name) then
		-- 						else
		-- 							has = true
		-- 							break
		-- 						end
		-- 					end
		-- 				end
		-- 			end
		-- 		end

		-- 		if has then
		-- 			if view:getChildByName("red_sfx") then
									
		-- 			else
		-- 				local red_sfx = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/sfx/shanping/shanping.csb")
		-- 				red_sfx:setLocalZOrder(SceneZOrder.kRedSfx)
		-- 				red_sfx:getChildByName("Sprite_1"):setScale(winSize.width/red_sfx:getChildByName("Sprite_1"):getContentSize().width, winSize.height/red_sfx:getChildByName("Sprite_1"):getContentSize().height)
		-- 				animManager:runAnimByCSB(red_sfx, "PlanetScene/sfx/shanping/shanping.csb", "1")
		-- 				red_sfx:setName("red_sfx")
		-- 				red_sfx:setPosition(cc.p(winSize.width/2, winSize.height/2))
		-- 				view:addChild(red_sfx)
		-- 			end
		-- 		else
		-- 			if view:getChildByName("red_sfx") then
		-- 				view:getChildByName("red_sfx"):removeFromParent()							
		-- 			end
		-- 		end

		-- 	end
		-- end

		if self.planet_user then
			local app = require("app.MyApp"):getInstance()
			local view = app:getTopView()
			if view then
				if #self.planet_user.attack_me_list > 0 then
					if view:getChildByName("red_sfx") then
										
					else
						local red_sfx = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/sfx/shanping/shanping.csb")
						red_sfx:setLocalZOrder(SceneZOrder.kRedSfx)
						red_sfx:getChildByName("Sprite_1"):setScale(winSize.width/red_sfx:getChildByName("Sprite_1"):getContentSize().width, winSize.height/red_sfx:getChildByName("Sprite_1"):getContentSize().height)
						animManager:runAnimByCSB(red_sfx, "PlanetScene/sfx/shanping/shanping.csb", "1")
						red_sfx:setName("red_sfx")
						red_sfx:setPosition(cc.p(winSize.width/2, winSize.height/2))
						view:addChild(red_sfx)
					end
				else
					if view:getChildByName("red_sfx") then
						view:getChildByName("red_sfx"):removeFromParent()							
					end
				end
			end
		end
	end


	-------------------------------------------------------------
	local function updateSecond()
		if self.data_ then
			self.data_.nowtime = self.data_.nowtime + 1
			updateBuildings()

			updateTechnologys()

			updateGroupTech()

			-- updatePlanet()

			updateStrength()

			updateQueue()
			
			updateRepairing()

			updateTimeStamp()

			updatePlanetUser()

			updatePlanetArmy()

			updateTrade()

			local app = require("app.MyApp"):getInstance()
			local scene_name = app:getTopViewName()
			-- print("hehehhehe", scene_name)

			g_sendList:update()

			-- for i,v in ipairs(self.data_.user_info.achievement_data.guide_list) do
			-- 	print("guide_list",i,v)
			-- end
		end
 
	end

	schedulerEntry = scheduler:scheduleScriptFunc(updateSecond,1,false)

end

function Player:desctroy()
	self.data_ = nil

	scheduler:unscheduleScriptEntry(schedulerEntry)
	schedulerEntry = nil
end


function Player:registerRequst()
	local user_str = cc.UserDefault:getInstance():getStringForKey("user_id")
	if user_str == nil or user_str == "" then
		Tips:tips("user name is null, please register it!")
		return
	end

	local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
	if server_id == nil or server_id == "" then
		Tips:tips("please select server first")
		return
	end

	local strData = Tools.encode("RegistReq", {
		roleName = user_str,
		lead = 1,
		server = server_id,
		platform = g_platform,
		device_type = device.platform,
		resolution = "resolution",
		os_type = "os_type",
		ISP = "ISP",
		net = "net",
		MCC = "MCC",
		account = user_str,
	})

	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_REGIST_REQ"),strData)
end

function Player:loginRequst()

	local user_str = cc.UserDefault:getInstance():getStringForKey("user_id")
	if user_str == nil or userName == "" then
		Tips:tips("user name is null, please register it!")
		return
	end

	local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
	if server_id == nil or server_id == "" then
		Tips:tips("please select server first")
		return
	end

	-- local server_version = cc.UserDefault:getInstance():getStringForKey("server_version")
	-- if server_version == nil or server_version == "" then
	-- 	Tips:tips("server_version error")
	-- 	return
	-- end
	
	local client_version = cc.UserDefault:getInstance():getStringForKey("client_version")

	local strData = Tools.encode("LoginReq", {
		user_name = user_str,
		key = user_str,
		server = server_id,
		platform = g_platform,
		domain = "1234",
		device_type = device.model,
		resolution = "resolution",
		os_type = device.platform,
		ISP = "ISP",
		net = "net",
		MCC = "MCC",
		sid = tostring(server_id),
		version = client_version,
	})

	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_LOGIN_REQ"),strData)

	gl:retainLoading()

end


function Player:getShipListSize()
	return table.getn(self.data_.ship_list.ship_list)
end

function Player:getShipList()
	return self.data_.ship_list.ship_list
end

function Player:clearShipList()
	cleartable(self.data_.ship_list.ship_list)
end

function Player:setShipList(list)
	self.data_.ship_list.ship_list = list
end

function Player:getShipByGUID(guid)

	for i,v in ipairs(self.data_.ship_list.ship_list) do
 
		if guid == v.guid then
			return v
		end
	end
	return nil
end

function Player:getShipByID(id)

	for i,v in ipairs(self.data_.ship_list.ship_list) do
 
		if id == v.id then
			return v
		end
	end
	return nil
end


function Player:getShipsByType(typeNum)

	local ships = {}

	for k,v in pairs(self.data_.ship_list.ship_list) do

		if typeNum == v.type then
			table.insert(ships,v)
		end
	end
	
	return ships
end

function Player:getTypeToShipsScene()
	local typeNum = 0
	for i=1,4 do
		if #self:getShipsByType(i) > 0 then
			return i 
		end
	end

	return 0
end

function Player:getAllDrawing() --所有图纸

	local list = {}

	for i,v in ipairs(self.data_.item_list.item_list) do
		local conf = CONF.ITEM.get(v.id)
		if conf.TYPE == CONF.EItemType.kShipBulepoint then
			table.insert(list, v)
		end
	end

	if Tools.isEmpty(list) then
		return nil
	end

	return list
end

function Player:getGemByID( id )
	for i,v in ipairs(self.data_.user_info.gem_list) do
		if v == id then

			return v
		end
	end
	return nil
end

function Player:getAllUnGemList()
	return self.data_.user_info.gem_list
end

function Player:getAllUnGemListWithType(type, id)

	local list = {}

	if type == CONF.EGemType.kTypeAll then
		return self:getAllUnGemList()
	else
		for i,v in ipairs(self.data_.user_info.gem_list) do
			local conf = CONF.GEM.get(v.id)

			

			if conf.TYPE == type then
				if id then
					-- if v.id ~= id then
						table.insert(list,v)
					-- end
				else
					table.insert(list,v)
				end
			end
		end
	end

	if Tools.isEmpty(list) then
		return nil
	end

	return list
end

function Player:getEquipByGUID( guid )
	for i,v in ipairs(self.data_.user_info.equip_list) do
		if v.guid == guid then
			return v
		end
	end
	return nil
end

function Player:getAllUnequipList()
	local list = {}

	for i,v in ipairs(self.data_.user_info.equip_list) do

		if v.ship_id == 0 then

			table.insert(list,v)
		end
	end

	if Tools.isEmpty(list) then
		return nil
	end

	return list
end

function Player:getAllUnequipListWithType(type,ship_id)

	local list = {}

	for i,v in ipairs(self.data_.user_info.equip_list) do

		if (v.ship_id == 0 or (ship_id and v.ship_id == ship_id)) and type == v.type then

			table.insert(list,v)
		end
	end

	if Tools.isEmpty(list) then
		return nil
	end

	return list
end

function Player:getWeaponListWithoutId(id)

	if CONF.PARAM.get("city_6_open").PARAM[1] > self:getLevel() or CONF.PARAM.get("city_6_open").PARAM[2] > self:getBuildingInfo(1).level then
		return {}
	end

	local list = {}

	for i,v in ipairs(self.data_.user_info.weapon_list) do

		if v.weapon_id ~= id then

			table.insert(list,v)
		end
	end

	if Tools.isEmpty(list) then
		return nil
	end

	return list
end

function Player:getWeaponByGUID( guid )

	for i,v in ipairs(self.data_.user_info.weapon_list) do
		if v.guid == guid then
			return v
		end
	end

	return nil
end

function Player:getWeaponByID( weapon_id )

	for i,v in ipairs(self.data_.user_info.weapon_list) do
		if v.weapon_id == weapon_id then
			return v
		end
	end

	return nil
end

function Player:getWeaponByTemp( temp_id )

	for i,v in ipairs(self.data_.user_info.weapon_list) do
		local t_id = math.floor(v.weapon_id / 10) * 10
		if t_id == temp_id then
			return v
		end
	end
	return nil
end

function Player:getWeaponList()
	return self.data_.user_info.weapon_list
end


function Player:getAllShipsNum()

	local function getAllShipsNum()
		local count = 0
		for k,v in pairs(CONF.AIRSHIP) do
			if type(k) == "number" and k < 10990000 then

				count = count + 1  
			end
		end
		return count
	end

	if self.allShipsNum_ == nil then
		self.allShipsNum_ = getAllShipsNum()
	end

	return self.allShipsNum_
end


function Player:getFormByIndex( index ,lineup)
	assert(index > 0 and index < 10,"error")

	local forms
	if lineup then
		forms = lineup
	else
		forms= self:getForms()
	end

	return forms[index]
end

function Player:switchFormByIndex( index1, index2, lineup)
	assert(index1 > 0 and index1 < 10,"error")
	assert(index2 > 0 and index2 < 10,"error")

	local forms
	if lineup then
		forms = lineup
	else
		forms= self:getForms()
	end

	local temp = forms[index1]
	forms[index1] = forms[index2]
	forms[index2] = temp
end


function Player:resetFormByIndex( index, newShipGUID, lineup )

	assert(index > 0 and index < 10,"error")
	assert(newShipGUID > -1,"error")

	local forms
	if lineup then
		forms = lineup
	else
		forms= self:getForms()
	end

	local oldGUID = forms[index]

	local oldShip = nil

	if oldGUID ~= 0 and oldGUID then
		oldShip = self:getShipByGUID(oldGUID)
		assert(oldShip,"error")
	end

	if newShipGUID ~= 0 then

		local newShip = self:getShipByGUID(newShipGUID)
		assert(newShip,"error")

		newShip.position = index
		forms[index] = newShip.guid
	else
		forms[index] = 0
	end

	if oldShip then
		oldShip.position = 0
	end
end

function Player:setForms( lineup, config )

	if config.from == "trial" then

		self.data_.user_info.trial_data.area_list[config.index].lineup = lineup
		
	elseif config.from == "copy" then
	
		self.data_.user_info.lineup = lineup
		
	end

end

function Player:getForms()

	if not self.data_.user_info.lineup then
		self.data_.user_info.lineup = {0,0,0,0,0,0,0,0,0}
	end
	return self.data_.user_info.lineup
end

function Player:IsInForms(guid)
	if Tools.isEmpty(self.data_.user_info.lineup) == false then
		for _, v in ipairs(self.data_.user_info.lineup) do
			if v == guid then
				return true
			end
		end
	end
	return false
end

function Player:getPreset_lineup_list(num)
	for k,v in pairs(self.data_.user_info.preset_lineup_list) do
		if k == num then
			return v.ship_guid_list
		end
	end
	return {0,0,0,0,0,0,0,0,0}
end
function Player:getAllPreset_lineup_list()
	return self.data_.user_info.preset_lineup_list
end

function Player:getItemByID( id )
	for i,v in ipairs(self.data_.item_list.item_list) do
		if id == v.id then
			return v
		end
	end

	return nil    
end

function Player:getItemNumByID( id )
	if id == 3001 then
		return self:getResByIndex(1)
	elseif id == 4001 then
		return self:getResByIndex(2)
	elseif id == 5001 then
		return self:getResByIndex(3)
	elseif id == 6001 then
		return self:getResByIndex(4)
	elseif id == 7001 then
		return self:getMoney()
	else
		local conf = CONF.ITEM.get(id)

		local type_ = conf.TYPE

		if type_ >= CONF.EItemType.kRes1 and type_ <= CONF.EItemType.kRes4 then
			return self:getResByIndex(type_-2)

		elseif type_ == CONF.EItemType.kMoney then
			return self:getMoney()

		elseif (type_ >= CONF.EItemType.kGem and type_ <= CONF.EItemType.kShipSuperBulepoint and (type_ ~= CONF.EItemType.kHonour and type_ ~= CONF.EItemType.kBadge)) or type_ == CONF.EItemType.kOther then
			for i,v in ipairs(self.data_.item_list.item_list) do
				if id == v.id then
					return v.num
				end
			end

		else
            print("----------Itemid",id)
			assert(false, "error")
		end
	end

	return 0
end

function Player:checkItem( id, num )

	local conf = CONF.ITEM.get(id)
	
	if conf.TYPE >= CONF.EItemType.kRes1 and conf.TYPE <= CONF.EItemType.kRes4 then

		return self:getResByIndex(conf.TYPE - 2) >= num

	elseif conf.TYPE == CONF.EItemType.kMoney then

		return self:getMoney() >= num
		
	else
		local item = self:getItemByID(id)
		if not item then
			return false
		end

		return item.num >= num
	end

	return false
end

function Player:checkItems( items )--{[id] = num,[id] = num}
	for k,v in pairs(items) do
		if not self:checkItem(k,v) then
			return false
		end
	end
	return true
end

function Player:calShip(ship_guid, isFight)

	local info = self:getShipByGUID(ship_guid)
	if not info then
		return nil
	end

	local flag = false
	if isFight then
		flag = isFight
	end

	return Tools.calShip( info, self:getUserInfo(), self.group_main_, flag)
end

function Player:calShipByInfo( info, isFight )
	if not info then
		return nil
	end

	local flag = false
	if isFight then
		flag = isFight
	end

	return Tools.calShip( info, self:getUserInfo(), self.group_main_, flag)
end

function Player:calShipFightPower(ship_guid, isFight)
	local calShip = self:calShip(ship_guid,isFight)

	if not calShip then
		return 0
	end

	local weapon_id_list = {}

	for i,v in ipairs(calShip.weapon_list) do

		if v ~= 0 then
			local tt = self:getWeaponByGUID(v)
			local id = 0
			if tt then
				id = tt.weapon_id
			end

			table.insert(weapon_id_list, id)
		else
			table.insert(weapon_id_list, 0)
		end
	end

	return Tools.calShipFightPower(calShip, weapon_id_list)
end

function Player:calShipFightPowerByInfo( info )
	return Tools.calShipFightPower(info)
end

function Player:getAllShipFightPower()
	local totalPower = 0
	local shipList = self:getShipList()
	for k,info in ipairs(shipList) do
		totalPower = totalPower + self:calShipFightPower( info.guid )
	end
	return totalPower
end

--关卡
function Player:getMaxArea()
	local copyId = 0

	for k,v in pairs(self.data_.user_info.stage_data.level_info) do
		
		if copyId < v.level_id then
			copyId = v.level_id
		end

	end

	local area = math.floor(copyId/1000000)

	if area == 0 then
		return 1
	else

		local areaConf = CONF.AREA.get(area)
		local stageConf = CONF.COPY.get(areaConf.SIMPLE_COPY_ID[areaConf.SIMPLE_COPYNUM])
	
		local finish = self:getCopyFinish(stageConf.LEVEL_ID[stageConf.COPY_NUM])

		if finish then
			area = area+1  
		end
	end

	if area > 5 then
		area = 5 
	end

	return area
end

function Player:getStageByArea(area)

	local area = area
	local stage = 1

	for k,v in pairs(self.data_.user_info.stage_data.level_info) do
		
		if math.floor(v.level_id/1000000) == area then

			local model = math.floor((v.level_id/10000)%(area*100))

			if model == 1 then

				local stage_ = math.floor((v.level_id/100)%(area*10000+model*100))

				if stage < stage_ then
					stage = stage_
				end

			end

		end

	end

	local areaConf = CONF.AREA.get(area)
	local conf = CONF.COPY.get(CONF.AREA.get(area).SIMPLE_COPY_ID[stage])
	local finish = self:getCopyFinish(conf.LEVEL_ID[conf.COPY_NUM])

	if finish then
		stage = stage + 1
		if stage > areaConf.SIMPLE_COPYNUM then
			stage = areaConf.SIMPLE_COPYNUM
		end
	end


	return stage

end

function Player:getCopyInStage( stage )
	local index = 1

	local conf = CONF.COPY.get(stage)

	for k,v in pairs(conf.LEVEL_ID) do
		
		if self:getCopyStar(v) ~= 0 then
			index = index + 1

		else
			return index

		end

	end

	if index > table.getn(conf.LEVEL_ID) then
		index = table.getn(conf.LEVEL_ID)
	end

	return index
end

function Player:getStageStar(stageId)

	local starNum = 0

	local conf = CONF.COPY.get(stageId)

	for k,v in pairs(conf.LEVEL_ID) do
		
		starNum = starNum + self:getCopyStar(v)

	end

	return starNum
end

function Player:getCopyFinish(copyId)

	for k,v in pairs(self.data_.user_info.stage_data.level_info) do
		
		if v.level_id == copyId then
			return true
		end
		
	end

	return false

end

function Player:getCopyStar(copyId)

	for k,v in pairs(self.data_.user_info.stage_data.level_info) do
		if v.level_id == copyId then
			return v.level_star
		end
		
	end

	return 0
	
end


function Player:getFinishCopyNum(stageId)

	local conf = CONF.COPY.get(stageId)

	local num = 0

	for k,v in pairs(conf.LEVEL_ID) do
		
		if self:getCopyStar(v) ~= 0 then
			num = num + 1
		end

	end

	if num > table.getn(conf.LEVEL_ID) then
		num = table.getn(conf.LEVEL_ID)
	end

	return num
	
end

function Player:getFinishCopy( stage_id )

	local conf = CONF.COPY.get(stage_id)

	local num = self:getFinishCopyNum(stage_id)
	if num == table.getn(conf.LEVEL_ID) then
		return true
	end

	return false
end

function Player:getFinishArea( area_id )
	local conf = CONF.AREA.get(area_id)

	local flag = true

	for i,v in ipairs(conf.SIMPLE_COPY_ID) do
		if self:getFinishCopy(v) == false then
			flag = false
			break
		end
	end

	return flag
end

function Player:getAreaStarNum( area_id )
	local star_num = 0

	for i,v in ipairs(CONF.AREA.get(area_id).SIMPLE_COPY_ID) do
		for i2,v2 in ipairs(CONF.COPY.get(v).LEVEL_ID) do
			star_num = star_num + self:getCopyStar(v2)
		end
	end

	return star_num
end

function Player:getStageReward( stage )
	for i,v in ipairs(self.data_.user_info.stage_data.copy_data) do
		if v.copy_id == stage then
			return v.got_reward
		end
	end

	return {false,false,false}
end

function Player:setLevelInfo( level_info )
	self.data_.user_info.stage_data.level_info[#self.data_.user_info.stage_data.level_info+1] = level_info
end

function Player:getMaxCopy()

	local chapterId = 0
	for i,v in ipairs(self.data_.user_info.stage_data.level_info) do
		if v.level_id > chapterId then
			chapterId = v.level_id
		end
	end

	local max_level = 0
	for i,v in ipairs(CONF.CHECKPOINT.getIDList()) do
		local conf = CONF.CHECKPOINT.get(v)
		if conf.PRE_COPYID == chapterId then
			max_level = v
			break
		end
	end

	if max_level == 0 then
		max_level = chapterId
	end

	return max_level
end

--战力
function Player:getPower()
	-- local shipList = self:getForms()
	local shipList = self:getShipList()
 
	local ships = {}

	for k,v in pairs(shipList) do
		if v ~= 0 then
			local ship_info = self:calShip(v.guid)

			local wl = {}
			for i,v2 in ipairs(ship_info.weapon_list) do
				if v2 ~= 0 then
					local tt = self:getWeaponByGUID(v2) 
					local id = 0
					if tt then
						id = tt.weapon_id
					end

					table.insert(wl, id)
				else
					table.insert(wl, 0)
				end
			end

			ship_info.weapon_list = {}

			for i,v in ipairs(wl) do
				table.insert(ship_info.weapon_list, v)
			end

			table.insert(ships, ship_info)
		end
	end

	return Tools.calAllFightPower(ships, self.data_.user_info)
end

function Player:getLineupPower(  )
	local shipList = self:getForms()

	local power = 0 

	for k,v in pairs(shipList) do
		if v ~= 0 then
			power = power + self:calShipFightPower(v)
		end
	end

	return power
end

function Player:getTechPower( )
	return Tools.calTechPower(self.data_.user_info)
end

--technology

function Player:getTechnolgyData( )
	return self.data_.user_info.tech_data
end
function Player:getTechnolgList( )
	return self.data_.user_info.tech_data.tech_info
end

function Player:getTechnolgListNum( )
	return #self.data_.user_info.tech_data.tech_info
end

function Player:getUsedTechnologyCount()
	local count = 0
	for i,v in ipairs(self.data_.user_info.tech_data.tech_info) do
		if v.begin_upgrade_time == 0 then
			count = count + 1
		end
	end
	return count
end

function Player:getUsedTechnologyLevelCount()
	local count = 0
	for i,v in ipairs(self.data_.user_info.tech_data.tech_info) do
		if v.begin_upgrade_time == 0 then
			local conf = CONF.TECHNOLOGY.get(v.tech_id)
			if conf then
				count = count + conf.TECHNOLOGY_LEVEL
			end
		end
	end
	return count
end
function Player:getCanUpgradeTechnologyLevelCount()
	local building_level = self:getBuildingInfo(CONF.EBuilding.kTechnology).level
	local tech_list = {}
	for level=1,building_level do
		local conf = CONF.BUILDING_5.get(level)
		if Tools.isEmpty(conf.TECH_LIST) == false then
			for i,v in ipairs(conf.TECH_LIST) do
				tech_list[v] = true
			end
		end
	end
	local count = 0
	for tech_id,_ in pairs(tech_list) do

		local high_conf = CONF.TECHNOLOGY.get(tech_id)
		local max_level = high_conf.TECHNOLOGY_MAX_LEVEL
		for i=1, max_level do
			local conf = CONF.TECHNOLOGY.check(tech_id + i)
			if conf == nil or building_level < conf.TECHNOLOGY_BUILDING_LEVEL then
				break
			end
			high_conf = conf
		end
		count = count + high_conf.TECHNOLOGY_LEVEL
	end
	return count
end

function Player:getUsedTechnologyByTemp(temp_id)
	for i,v in ipairs(self.data_.user_info.tech_data.tech_info) do
		local t_id = math.floor(v.tech_id / 100) * 100
		if t_id == temp_id and v.begin_upgrade_time == 0 then
			return v
		end
	end

	return nil
end

function Player:getTechnologyByID(id)
	for i,v in ipairs(self.data_.user_info.tech_data.tech_info) do
		if v.tech_id == id then
			return v
		end
	end
	return nil
end

--家园

function Player:getLandType( index )
	for k,v in pairs(self.data_.user_info.home_info.land_info) do
		if v.land_index == index then
			return v
		end
	end

	return nil
end

function Player:getMaxLandNum()

	return CONF.BUILDING_1.get(self:getBuildingInfo(CONF.EBuilding.kMain).level).RESOURCE_NUM
end

function Player:getLandInfo()
	
	return self.data_.user_info.home_info.land_info

end

function Player:resetResourceNum( index )
	for i,v in ipairs(self.data_.user_info.home_info.land_info) do
		if v.land_index == index then
			v.resource_num = 0
		end
	end
end

function Player:getMaxLevelByLandType( index )
	
	local max_level = 0
	for i,v in ipairs(self.data_.user_info.home_info.land_info) do
		local conf = CONF.RESOURCE.get(v.resource_type)
		if conf.TYPE == index then
			if conf.LEVEL > max_level then
				max_level = conf.LEVEL 
			end
		end
	end

	return max_level

end

--试炼

function Player:setTrialAreaData(data)
	self.data_.user_info.trial_data.area_list = data
end

function Player:getTrialTicketNum()
	return self.data_.user_info.trial_data.ticket_num
end

function Player:setTrialTicketNum(num)
	self.data_.user_info.trial_data.ticket_num = num
end

function Player:getTrialAreaType(index)
	for k,v in pairs(self.data_.user_info.trial_data.area_list) do
		if v.area_id == index then
			return v.status
		end
	end

	return 0
end

function Player:setTrialAreaType(index)
	for k,v in pairs(self.data_.user_info.trial_data.area_list) do
		if v.area_id == index then
			v.status = 0
		end
	end

end

function Player:getTrialLineup(index)

	for i,v in ipairs(self.data_.user_info.trial_data.area_list) do
		if v.area_id == index then
			if v.lineup then
				return v.lineup
			end
		end
	end

	return nil
end

function Player:getTrialShipList(index)
	for i,v in ipairs(self.data_.user_info.trial_data.area_list) do
		if v.area_id == index then
			if v.ship_list then
				return v.ship_list
			end
		end
	end

	return nil
end

function Player:getTrialShipByGUID( index, guid)
	for i,v in ipairs(self:getTrialShipList(index)) do
		if v.guid == guid then
			return v 
		end
	end
	return nil
end

function Player:getTrialShipHpByGUID( index, guid)
	for i,v in ipairs(self:getTrialShipList(index)) do
		if v.guid == guid then
			return v.hp 
		end
	end

	return 0
end

function Player:getTrialShipByType(index,typeNum)
	
	local ships = {}

	for i,v in ipairs(self:getTrialShipList(index)) do
		if v.guid ~= 0 then
			local info = self:getShipByGUID(v.guid)
			if info.type == typeNum then
				table.insert(ships, v)
			end
		end
	end

	return ships
end

function Player:getTrialPower(index)

	local lineup = self:getTrialLineup(index)

	if lineup ~= nil then
		local power = 0

		for i,v in ipairs(lineup) do
			if v ~= 0 then
				power = power + self:calShipFightPower(v)
			end
		end

		return math.floor(power)
	end

	return 0 

end

function Player:getTrialScene( area )
	local levelId = 0
	local scene

	for i,v in ipairs(self.data_.user_info.trial_data.level_list) do
		if math.floor(v.level_id/1000000) == area then
			if levelId < v.level_id then
				levelId = v.level_id
			end
		end
	end

	if levelId ~= 0 then
		local copy = CONF.TRIAL_LEVEL.get(levelId).T_COPY_ID
		scene = CONF.TRIAL_COPY.get(copy).COPYMAP_ID
		return scene
	else
		scene = area*100+1
	end

	return scene
end

function Player:getTrialLevelStar(level_id)
	for i,v in ipairs(self.data_.user_info.trial_data.level_list) do
		if level_id == v.level_id then
			return v.star
		end
	end

	return 0
end

function Player:getTrialDoorType( scene )
	local copy = CONF.TRIAL_SCENE.get(scene).T_COPY_LIST[table.getn(CONF.TRIAL_SCENE.get(scene).T_COPY_LIST)]
	local level = CONF.TRIAL_COPY.get(copy).LEVEL_ID[table.getn(CONF.TRIAL_COPY.get(copy).LEVEL_ID)]

	local star = self:getTrialLevelStar(level)
	if star > 0 then
		return true
	else
		return false
	end
end

function Player:getTrialLevelPre(level_id)
	local conf = CONF.TRIAL_LEVEL.get(level_id)

	if conf.PRE_COPYID ~= 0 then
		local star = self:getTrialLevelStar(conf.PRE_COPYID)

		if star == 0 then
			return false
		end
	end


	return true
end

function Player:getTrialCopyReward(copy_id) -- 0：未领取 1：领取
	for i,v in ipairs(self.data_.user_info.trial_data.copy_list) do
		if v.copy_id == copy_id then
			return v.reward_flag
		end
	end

	return 0
end

function Player:setTrialCopyReward(copy_id)

	local index = 0

	for i,v in ipairs(self.data_.user_info.trial_data.copy_list) do
		if v.copy_id == copy_id then
			index = i
			break
		end
	end

	if index ~= 0 then
		self.data_.user_info.trial_data.copy_list[index].reward_flag = 1
	else

		local tt = {reward_flag = 1, copy_id = copy_id}
		
		table.insert(self.data_.user_info.trial_data.copy_list, tt)
	end

end

--arena
function Player:getArenaData()
	if not self.data_.user_info.arena_data then
		return nil
	end

	return self.data_.user_info.arena_data
end

function Player:getTodayWinLose( ... )
	local today_all_num = self.data_.user_info.arena_data.already_challenge_times
	local today_win_num = self.data_.user_info.arena_data.win_challenge_times
	local today_lose_num = today_all_num - today_win_num

	return today_win_num,today_lose_num
end

function Player:getArenaisChallenged( rank )
	for i,v in ipairs(self.data_.user_info.arena_data.challenge_list) do
		if rank == v.rank then
			return v.isChallenged
		end
	end

	return false
end

function Player:setArenaDailyReward( ... )
	self.data_.user_info.arena_data.daily_reward = 2
end

--加速
function Player:getSpeedUpNeedMoney(second)

	return Tools.getSpeedUpNeedMoney(second)
end

--增加量 --建筑
function Player:getValueByTechnologyAddition( value, tech_1, tech_2, tech_3 )
	return Tools.getValueByTechnologyAddition(value, tech_1, tech_2, tech_3, self.data_.user_info.tech_data.tech_info)
end

function Player:getValueByTechnologyAdditionGroup( value, tech_1, tech_2, tech_3 )
	return value + Tools.getValueByTechnologyAddition(value, tech_1, tech_2, tech_3, self:getTechnolgList(), self:getPlayerGroupTech())
end


--建筑队列
function Player:getMoneyBuildingQueueOpen()

	for i,v in ipairs(self.data_.user_info.build_queue_list) do
		if v.open_time > 0 then
			return true
		end
	end

	return false
end

function Player:getNormalBuildingQueueNow()

	local list = self.data_.user_info.build_queue_list[1]
	if list.index ~= 0 and list.type ~= 0 then
		return true
	end

	return false

end

function Player:getMoneyBuildingQueueNow()

	local list = self.data_.user_info.build_queue_list[2]
	if list.index ~= 0 and list.type ~= 0 then
		return true
	end

	return false

end

function Player:getBuildQueueNow(index )
	if index == 1 then
		return self:getNormalBuildingQueueNow()
	elseif index == 2 then
		return self:getMoneyBuildingQueueNow()
	end
end

function Player:getBuildingQueueBuild(index)
	if table.getn(self.data_.user_info.build_queue_list) < index then
		return
	end

	return self.data_.user_info.build_queue_list[index]
end

function Player:getBuildingQueueBuilds( ... )
	return self.data_.user_info.build_queue_list
end

--friend
function Player:getFriendsNum( type )
	if type == 1 then
		return table.getn(self.data_.user_info.friends_data.friends_list)
	elseif type == 2 then
		return table.getn(self.data_.user_info.friends_data.black_list)
	end
end

function Player:isFriend(user_name)

	for i,v in ipairs(self.data_.user_info.friends_data.friends_list) do
		if user_name == v then
			return true
		end
	end

	return false
end

function Player:isBlack( user_name )
	for i,v in ipairs(self.data_.user_info.friends_data.black_list) do
		if user_name == v then
			return true
		end
	end

	return false
end

function Player:removeFriend( user_name )
	local index = 0

	for i,v in ipairs(self.data_.user_info.friends_data.friends_list) do
		if user_name == v then
			index = i 
		end
	end

	table.remove(self.data_.user_info.friends_data.friends_list, index)
end

function Player:addFriend( user_name )
	table.insert(self.data_.user_info.friends_data.friends_list, user_name)
end

function Player:addBlack( user_name )
	table.insert(self.data_.user_info.friends_data.black_list, user_name)
end

function Player:removeBlack( user_name )
	local index = 0

	for i,v in ipairs(self.data_.user_info.friends_data.black_list) do
		if user_name == v then
			index = i 
		end
	end

	table.remove(self.data_.user_info.friends_data.black_list, index)
end

function Player:isFriendAddTili(user_name)
	if Tools.isEmpty(self.data_.user_info.friends_data) == true or Tools.isEmpty(self.data_.user_info.friends_data.add_tili) == true then
		return false
	end
	print("isFriendAddTili count",#self.data_.user_info.friends_data.add_tili)
	for _ , v in ipairs(self.data_.user_info.friends_data.add_tili) do
		print("isFriendAddTili",v,user_name)
		if v == user_name then
			return true
		end
	end
	return false
end
function Player:isFriendReadTili(user_name)
	if Tools.isEmpty(self.data_.user_info.friends_data) == true or Tools.isEmpty(self.data_.user_info.friends_data.read_tili) == true then
		return false
	end
	print("isFriendReadTili count",#self.data_.user_info.friends_data.read_tili)
	for _ , v in ipairs(self.data_.user_info.friends_data.read_tili) do
		print("isFriendReadTili",v,user_name)
		if user_name == nil or v == user_name then
			return true
		end
	end
	return false
end
function Player:GetFriendReadTiliCount()
	if self.data_.user_info.friends_data then
		return self.data_.user_info.friends_data.read_tili_count
	end
	return 0
end
function Player:GetFriendReadTili()
	if self.data_.user_info.friends_data then
		return self.data_.user_info.friends_data.read_tili
	end
	return nil
end
function Player:GetFriendFamiliarity(user_name)
	if self.data_.user_info.friends_data then
		if Tools.isEmpty(self.data_.user_info.friends_data.friends_familiarity) == false then
			for _ , v in ipairs(self.data_.user_info.friends_data.friends_familiarity) do
				if v.user_name == tostring(user_name) then
					return v.familiarity
				end
			end
		end
	end
	return 0
end

--星盟
function Player:isGroup()

	if self.data_.user_info.group_data == nil then
		return false
	else
		if self.data_.user_info.group_data.groupid == "" or self.data_.user_info.group_data.job == 0 then

			return false
		end

	end

	return true
end

function Player:getGroupData()
	return self.data_.user_info.group_data
end

function Player:setGroupData(group_main)
	self.data_.user_info.group_data = group_main
end

function Player:getGroupTechItemIndex(id, type) 

	for i,v in ipairs(self.data_.user_info.group_data.tech_contribute_list) do
		if v.tech_id == id then
			return v.item_index_list[type]
		end
	end

	return nil
end

function Player:setPlayerGroupMain( group_main )
	self.group_main_ = group_main
	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("update_group_main")
end

function Player:getPlayerGroupMain(  )
	return self.group_main_
end

function Player:checkPlayerIsInGroup( user_name )
	
	if self:isGroup() then
		if self.group_main_ then
			for i,v in ipairs(self.group_main_.user_list) do
				if v.user_name == user_name then
					return true
				end
			end
		end
	end

	return false
end

function Player:getPlayerGroupTech( ... )
	if self.group_main_ then
		return self.group_main_.tech_list
	end

	return nil
end

function Player:getGroupHelpList()
	return self.group_main_.help_list
end

function Player:getGroupHelp( type, index )

	if self.group_main_ == nil then
		return nil
	end

	for i,v in ipairs(self.group_main_.help_list) do
		if v.user_name == self:getName() then
			if v.type == type and v.id[1] == index then
				return v
			end
		end
	end

	return nil
end

function Player:getUsedGroupTechnologyLevelCount()
	if self.group_main_ == nil then
		return 0
	end
	if Tools.isEmpty(self.group_main_.tech_list) == true then
		return 0
	end
	local count = 0
	for i,v in ipairs(self.group_main_.tech_list) do
		if v.begin_upgrade_time == 0 then
			local conf = CONF.GROUP_TECH.get(v.tech_id)
			if conf then
				count = count + conf.LEVEL
			end
		end
	end
	return count
end
function Player:getCanUpgradeGroupTechnologyLevelCount()
	if self.group_main_ == nil then
		return 0
	end
	
	local tech_list = {}
	for level=1,self.group_main_.level do
		local conf = CONF.GROUP.get(level)
		if Tools.isEmpty(conf.OPEN_TECH_ID) == false then
			for i,v in ipairs(conf.OPEN_TECH_ID) do
				tech_list[v] = true
			end
		end
	end
	local count = 0
	for tech_id,_ in pairs(tech_list) do

		local high_conf = CONF.GROUP_TECH.get(tech_id)
		for i=1, 100 do
			local conf = CONF.GROUP_TECH.check(tech_id + i)
			if conf == nil or self.group_main_.level < conf.OPEN_GROUP_LEVEL then
				break
			end
			high_conf = conf
		end
		count = count + high_conf.LEVEL
	end
	return count
end

----------------星球占领
function Player:getPlanetData( )
	return self.data_.user_info.planet_data
end

function Player:getPlanetLineupList( )
	local id_list = {}

	for i,v in ipairs(self.data_.user_info.planet_data.ride_list) do
		for i2,v2 in ipairs(v.lineup) do
			if v2 ~= 0 then
				table.insert(id_list, v2)
			end
		end
	end

	return id_list
end

function Player:getRaidDataByIndex( index )
	for i,v in ipairs(self.data_.user_info.planet_data.ride_list) do
		if v.info.res_index == index then
			return v
		end
	end

	return nil
end

function Player:getRaidDataByID( id )
	for i,v in ipairs(self.data_.user_info.planet_data.ride_list) do
		if v.info.ruins_id == id then
			return v
		end
	end

	return nil
end

function Player:getRaidDataByGUID( guid )
	for i,v in ipairs(self.data_.user_info.planet_data.ride_list) do
		if v.guid == guid then
			return v
		end
	end

	return nil
end

function Player:getEnemyPower( enemy_id )
	local conf = CONF.AIRSHIP.get(enemy_id)

	local info = Tools.createShipByConf( enemy_id)
	-- local param = CONF.PARAM

	-- local power = conf.LIFE*param.get("fight_power_hp").PARAM + conf.ATTACK*param.get("fight_power_attack").PARAM + conf.DEFENCE*param.get("fight_power_defence").PARAM + conf.SPEED*param.get("fight_power_speed").PARAM + conf.PROBABILITY_HIT*param.get("fight_power_hit").PARAM + conf.PROBABILITY_DODGE*param.get("fight_power_dodge").PARAM + conf.PROBABILITY_CRIT*param.get("fight_power_crit").PARAM + conf.PROBABILITY_ANTICRIT*param.get("fight_power_anticrit").PARAM

	-- for i,v in ipairs(conf.WEAPON_LIST) do
	-- 	power = power + CONF.WEAPON.get(v).FIGHT_POWER
	-- end

	return Tools.calShipFightPower(info, conf.WEAPON_LIST)

end

function Player:getPlanetUpdate( info_list )

	local res_list = {}
	local ruins_list = {}
	local raid_list = {}

	for i,v in ipairs(self.planet_info_) do
		if v.type == "res" then
			table.insert(res_list, v)
		elseif v.type == "ruins" then
			table.insert(ruins_list, v)
		elseif v.type == "raid" then
			table.insert(raid_list, v)
		end
	end

	for i,v in ipairs(info_list) do
		if v.type == "res" then
			local num = 0
			for ii,vv in ipairs(res_list) do
				if v.info.index ~= vv.info then
					num = num + 1
				end
			end

			if num == #res_list then
				return true
			end

		elseif v.type == "ruins" then
			local num = 0 
			for ii,vv in ipairs(ruins_list) do
				if vv.info ~= v.info then
					num = num + 1
				end
			end

			if num == #ruins_list then
				return true
			end 

		elseif v.type == "raid" then
			local num = 0 
			for ii,vv in ipairs(raid_list) do
				if vv.info ~= v.info.user_name then
					num = num + 1
				end
			end

			if num == #ruins_list then
				return true
			end
		end
	end

	return false
	 
end

function Player:setPlanetInfo( info_list )
	self.planet_info_ = {}
	self.planet_info_ = info_list
end

function Player:setRideResInfo( info_list )
	self.ride_res_info_ = {}
	self.ride_res_info_ = info_list
end

function Player:getPlanetPos( type, info )
	for i,v in ipairs(self.planet_info_) do
		if v.type == type then
			if v.info == info then
				return v.pos 
			end             
		end
	end

	return 0
end

-----------------
function Player:getDailyActive()
	return self.data_.user_info.daily_data.active
end
function Player:isGetDailyActiveReward(index)
	if Tools.isEmpty(self.data_.user_info.daily_data.get_active_level) == true then
		return false
	end
	return self.data_.user_info.daily_data.get_active_level[index]
end

function Player:getDailyLotteryCount( ... )
	return self.data_.user_info.daily_data.lottery_count
end

function Player:IsTaskGetedReward( taskConf )
	for i,v in ipairs(self.data_.user_info.task_list) do
		if v.task_id == taskConf.ID then
			return v.finished
		end
	end
	return false
end

function Player:IsTaskOpen(taskConf)
	return self:getLevel() >= taskConf.OPEN_LEVEL
end

function Player:IsTaskAchieved(taskConf)
	return Tools.calTask( taskConf, self.data_.user_info, self.data_.ship_list.ship_list,self.planet_user )
end

function Player:IsActivityAchieved(taskConf, activity)
	return Tools.calTask( taskConf, self.data_.user_info, self.data_.ship_list.ship_list,self.planet_user, activity)
end

function Player:getTaskList(  )
	return self.data_.user_info.task_list
end

function Player:setTaskList( taskList )
	 self.data_.user_info.task_list = taskList
end

function Player:getUserInfo(  )
	return self.data_.user_info
end


--抽奖
function Player:getLotteryInfo(index)

	return self.data_.user_info.ship_lottery_data.info_list[index]
end

function Player:getGemListRate( gem_list )  --id, num
	local list = {}
	for i,v in ipairs(gem_list) do
		for j=1,v.num do
			table.insert(list, v.id)
		end
	end

	return Tools.getGemListRate(list)
end

function Player:getActivity( id )

	for k,v in ipairs(self.data_.user_info.activity_list) do
		if id == v.id then
			return v
		end 
	end
	
	return nil
end

function Player:isFighting(type, index) --1副本 2试炼 3竞技场 

	local forms = nil

	if type == 1 then
		forms = self:getForms()	
	elseif type == 2 then
		forms = self:getTrialLineup(index)
	end

	local num = 0

	local Bit = require "Bit"

	for i,v in ipairs(forms) do
		if v ~= 0 then
			local ship = self:getShipByGUID(v)

			if Bit:has(ship.status, 2) then
				Tips:tips(CONF:getStringValue("has_fix_ship"))
				return 3
			end

			--if ship.durable < Tools.getShipMaxDurable(ship)/10 then
			--	Tips:tips(CONF:getStringValue("can't fight"))
			--	return 1
			--end

			num = num + 1
		end
	end

	if num == 0 then
		Tips:tips(CONF:getStringValue("lineup no ships on"))
		return 2
	end
	
	return 0
end


function Player:isRecharge( id )

	for i,v in ipairs(self.data_.user_info.achievement_data.recharge_list) do
		if v == id then
			return true
		end
	end

	return false
end

function Player:getRechargeNum()
	return table.getn(self.data_.user_info.achievement_data.recharge_list)
end

function Player:getRechargeTotal()
	return self.data_.user_info.achievement_data.recharge_money
end

function Player:getConsumeTotal()
	return self.data_.user_info.achievement_data.consume_money
end

function Player:isGetFirstRechargeReward()
	if Tools.isEmpty(self.data_.user_info.activity_list) then

		return false
	end

	for i,activity in ipairs(self.data_.user_info.activity_list) do
		if activity.type == CONF.EActivityType.kFirstRecharge then
			return activity.first_recharge_data.getted_reward
		end
	end
	return false
end

function Player:getGuideStep()

	if not self.data_ or self.data_.user_info.achievement_data.guide_list[1] == nil then
		return 0
	end

	return self.data_.user_info.achievement_data.guide_list[1]
end

function Player:getSystemGuideStep(index)

	if self.data_.user_info.achievement_data.guide_list[index+1] == nil then
		return 0
	end

	return self.data_.user_info.achievement_data.guide_list[index+1]
end

function Player:setGuideStep( id )
	self.data_.user_info.achievement_data.guide_list[1] = id
end

function Player:getTalkKey()
	if self.data_.user_info.achievement_data.talk_key == nil then
		return ""
	end

	return self.data_.user_info.achievement_data.talk_key
end

function Player:setTalkKey( id )
	self.data_.user_info.achievement_data.talk_key = id
end

function Player:addBroadcastList( str, type )
	local tt = {str = str, type = type}
	table.insert(self.broadcast_run_list,tt)
end

function Player:removeBroadcastList( str )
	for i,v in ipairs(self.broadcast_run_list) do
		if v.str == str then
			table.remove(self.broadcast_run_list, i)
			break
		end
	end
end

function Player:getLastChat()
	return self.last_chat
end

function Player:setLastChat( chat )
	self.last_chat = chat
end

function Player:getMaxPlanet()

	for i=self:getMaxArea(),1,-1 do
		local conf = CONF.AREA.get(i)

		local planet_conf = CONF.PLANET.get(conf.PLANET_ID)

		local star_now = 0
		for i,v in ipairs(conf.SIMPLE_COPY_ID) do
			for i2,v2 in ipairs(CONF.COPY.get(v).LEVEL_ID) do
				local num = self:getCopyStar(v2)
				star_now = star_now + num
			end
		end

		if planet_conf.OPEN_TYPE == 1 then
			if star_now >= planet_conf.OPEN_VALUE then
				return conf.PLANET_ID
			end
		elseif planet_conf.OPEN_TYPE == 2 then
			if self:getCopyStar(planet_conf.OPEN_VALUE) > 0 then
				return conf.PLANET_ID
			end
		end
	end

end

function Player:getRegistTime()
	return self.data_.user_info.timestamp.regist_time
end

function Player:getArenaHonour()
	if Tools.isEmpty(self.data_.user_info.arena_data) == true then
		return 0
	end
	return self.data_.user_info.arena_data.honour_point
end

function Player:hasArenaChallengeTimes()
	if Tools.isEmpty(self.data_.user_info.arena_data) == true then
		return false
	end
	local arena_data = self.data_.user_info.arena_data
	if self:getServerTime() - arena_data.last_failed_time < 120 then
		return false
	end
	return arena_data.challenge_times > 0
end

function Player:getGroupBossDays( )

	local wday = self:getServerDate().wday

	local days = {}
	for i=1,CONF.GROUP_BOSS.count() do

		local is = 1
		local open = CONF.GROUP_BOSS.get(i).OPEN

		if open == wday then
			is = 2
		end

		local tt = {index = i, open = open, wday = is}
		table.insert(days,tt)
	end

	local function sort( a,b )

		if a.wday ~= b.wday then
			return a.wday > b.wday 
		else
			if a.open ~= b.open then

				if (a.open > wday) and (b.open > wday) then
					return a.open < b.open 
				elseif (a.open < wday) and (b.open < wday) then
					return a.open < b.open 
				elseif (a.open < wday) and (b.open > wday) then
					return a.open > b.open
				elseif (a.open > wday) and (b.open < wday) then
					return a.open > b.open
				end
			else
				return a.index < b.index 
			end
		end
	end

	table.sort(days, sort)

	return days
end

function Player:hasGroupBossChallengeTimes( index )
	local bossConf = CONF.GROUP_BOSS.get(index)
	local user_info = self:getUserInfo()

	if user_info.group_data.groupid == nil or user_info.group_data.groupid == "" then
		return false
	end

	if self.group_main_ == nil then
		return false
	end

	if bossConf.LEVEL > self.group_main_.level then
		return false
	end

	local group_boss_info
	if Tools.isEmpty(user_info.group_data.pve_checkpoint_list) == false then
		for i,v in ipairs(user_info.group_data.pve_checkpoint_list) do
			if v.group_boss_id == bossConf.ID then
				group_boss_info = v
				break
			end
		end
	end

	if group_boss_info == nil then
		return false
	end
	if group_boss_info.challenge_times < 1 then
		return false
	end
	local cur_time = self:getServerTime()
	local date = self:getServerDate()
	local start_time = os.time({year = date.year, month = date.month, day = date.day, hour = bossConf.START_TIME})
	local end_time = start_time + bossConf.END_TIME

	if cur_time < start_time or cur_time > end_time then
		return false
	end

	local alive = false
	for i,v in ipairs(group_boss_info.hurter_hp_list) do
		if v > 0 then
			alive = true
			break
		end
	end
	if alive == false then
		return false
	end

	return true
end

function Player:canBuildingCanUpgrade( index )
	local bi = self:getBuildingInfo(index)
	
	local high_conf = CONF[string.format("BUILDING_%d",index)].check(bi.level)
	if high_conf then
		local next_conf = CONF[string.format("BUILDING_%d",index)].check(bi.level + 1)
		if next_conf then
			local build_up = true
			if Tools.isEmpty(high_conf.BUILDING_TYPE) == false then
				for k,v in ipairs(high_conf.BUILDING_TYPE) do
					if self:getBuildingInfo(v).level < high_conf.BUILDING_LEVEL[k] then
						build_up = false
					end
				end
			end
			local home_up = true
			if Tools.isEmpty(high_conf.HOME_BUILDING_TYPE) == false then
				for k,v in ipairs(high_conf.HOME_BUILDING_TYPE) do
					if self:getMaxLevelByLandType(v) < high_conf.HOME_BUILDING_LEVEL[k] then
						home_up = false
					end
				end
			end
			local enough_res = true
			if Tools.isEmpty(high_conf.ITEM_ID) == false then
				for k,v in ipairs(high_conf.ITEM_ID) do
					if self:getItemNumByID(v) < high_conf.ITEM_NUM[k] then
						enough_res = false
					end
				end
			end
			if build_up and home_up and enough_res then
				return true
			end
		end
	end

	return false
end

function Player:canUpgradeBuilding( index )
	if index == 15 then return false end
	local bi = self:getBuildingInfo(index)
	if bi ~= nil then
		if bi.upgrade_begin_time > 0 then
			return false
		end
	end

	local level = bi.level

	local conf = CONF[string.format("BUILDING_%d",index)].get(level)

	if index == CONF.EBuilding.kMain then
		if self:getLevel() < conf.PLAYER_LEVEL then
			return false
		end
	else
		if conf.BUILDING_TYPE then
			for k,v in ipairs(conf.BUILDING_TYPE) do
				if self:getBuildingInfo(v).level < conf.BUILDING_LEVEL[k] then
					return false
				end
			end
		end

		if conf.HOME_BUILDING_TYPE then
			for k,v in ipairs(conf.HOME_BUILDING_TYPE) do
				if self:getMaxLevelByLandType(v) < conf.HOME_BUILDING_LEVEL[k] then
					return false
				end
			end
		end
	end

	for i,v in ipairs(conf.ITEM_ID) do
		if self:getItemNumByID(conf.ITEM_ID[i]) < conf.ITEM_NUM[i] then
			return false
		end
	end

	if index == CONF.EBuilding.kForge then
		if Tools.isEmpty(self:getForgeEquipList()) == false then
			return false
		end
	end

	return true
end

function Player:isOpenPlanet()
	
	local area = 1

	local conf = CONF.AREA.get(area)

	local planet_conf = CONF.PLANET.get(conf.PLANET_ID)

	local star_now = 0
	for i,v in ipairs(conf.SIMPLE_COPY_ID) do
		for i2,v2 in ipairs(CONF.COPY.get(v).LEVEL_ID) do
			local num = self:getCopyStar(v2)
			star_now = star_now + num
		end
	end

	if planet_conf.OPEN_TYPE == 1 then
		if star_now < planet_conf.OPEN_VALUE then
			Tips:tips(CONF:getStringValue("no enough star"))
			return false
		end
	elseif planet_conf.OPEN_TYPE == 2 then
		if self:getCopyStar(planet_conf.OPEN_VALUE) == 0 then
			Tips:tips(CONF:getStringValue("no finish copy").." "..CONF:getStringValue(CONF.CHECKPOINT.get(planet_conf.OPEN_VALUE).NAME_ID))
			return false
		end
	end

	return true
end

function Player:getPlanetNum()
	for i=self:getMaxArea(),1,-1 do
		local conf = CONF.AREA.get(i)

		local planet_conf = CONF.PLANET.get(conf.PLANET_ID)

		local star_now = 0
		for i,v in ipairs(conf.SIMPLE_COPY_ID) do
			for i2,v2 in ipairs(CONF.COPY.get(v).LEVEL_ID) do
				local num = self:getCopyStar(v2)
				star_now = star_now + num
			end
		end

		local is = true
		if planet_conf.OPEN_TYPE == 1 then
			if star_now < planet_conf.OPEN_VALUE then
				is = false
			end
		elseif planet_conf.OPEN_TYPE == 2 then
			if self:getCopyStar(planet_conf.OPEN_VALUE) == 0 then
				is = false
			end
		end

		if is then
			return i
		end

	end
end

function Player:getCardState()
	return self.data_.user_info.timestamp.card_end_time -- 0:null <0 终身 >0倒计时
end

function Player:getSlaveData()
	return self.slave_data_
end

function Player:getPlayerPlanetUser( ... )
	return self.planet_user
end

function Player:setPlayerPlanetUser( planet_user )
	self.planet_user = planet_user
end


function Player:canEquipStrongLv(equip) -- 0 ,false,false(为0，后面标示不为满级、物品情况)
	local my_gold_num = self:getResByIndex(1)
	local my_item_num = self:getItemNumByID(13005)
	local maxLevel = CONF.EQUIP.get(equip.equip_id) and CONF.EQUIP.get(equip.equip_id).MAX_STRENGTH or 0
	if equip.strength >= maxLevel then
		return 0,true,false
	end
	if math.floor(CONF.EQUIP_STRENGTH.get(equip.strength+1).ITEM_NUM[1] * CONF.PARAM.get("equip_strength_"..equip.quality).PARAM) > my_gold_num then
		return 0,false,false
	end
	if math.floor(CONF.EQUIP_STRENGTH.get(equip.strength+1).ITEM_NUM[2] * CONF.PARAM.get("equip_strength_"..equip.quality).PARAM) > my_item_num then
		return 0,false,false
	end
	local i = 0
	local gold_loop = true

	local total_gold = 0
	local total_item = 0
	while gold_loop do
		i = i+1
		total_gold =  total_gold + math.floor(CONF.EQUIP_STRENGTH.get(equip.strength+i).ITEM_NUM[1] * CONF.PARAM.get("equip_strength_"..equip.quality).PARAM)
		total_item = total_item + math.floor(CONF.EQUIP_STRENGTH.get(equip.strength+i).ITEM_NUM[2] * CONF.PARAM.get("equip_strength_"..equip.quality).PARAM)
		if total_gold > my_gold_num or total_item > my_item_num then
			i = i - 1
			gold_loop = false
		end
		if (equip.strength+i) >= maxLevel then
			gold_loop = false
		end
	end
	return i,false,true
end

function Player:setChatStarPoint( flag )
	self.chat_star_point = flag
end

function Player:getChatStarPoint( )
	return self.chat_star_point
end

function Player:getPlanetElement( ... )
	return self.planet_element
end

function Player:getForgeEquipList()
	return self.data_.user_info.forge_equip_list
end

function Player:getTradeData( ... )
	return self.data_.user_info.trade_data
end

function Player:getNewHandGift()
	local tab = {}
	tab.times = self.data_.user_info.new_hand_gift_bag_data.times
	tab.new_hand_gift_bag_list = {}
	for k,v in ipairs(self.data_.user_info.new_hand_gift_bag_data.new_hand_gift_bag_list) do
		local confTime = CONF.NEWHANDGIFTBAG.get(v.id).TIME
		if confTime - (self:getServerTime() - v.start_time) > 0 then
			table.insert(tab.new_hand_gift_bag_list,{id = v.id,gift_id = v.gift_id,start_time = v.start_time})
		end
	end
	table.sort(tab,function(a,b)
		return a.start_time > b.start_time
		end)
	return tab
end

function Player:getGiftData()
	local tab = {}
	if Tools.isEmpty(self.data_.user_info.gift_bag_list) == false then
		for k,v in ipairs(self.data_.user_info.gift_bag_list) do
			local confTime = CONF.NEWHANDGIFTBAG.get(v.id).TIME
			if confTime - (self:getServerTime() - v.start_time) > 0 then
				table.insert(tab,v)
			end
		end
	end
	return tab
end

function Player:getSerNewHand()
	return self.data_.user_info.new_hand_gift_bag_data
end
function Player:setSerNewHand(tab)
	self.data_.user_info.new_hand_gift_bag_data = tab
end

-- 保存一个活动列表
function Player:setPlayerActivityIDList(list)
	if Tools.isEmpty(list) == false then
		self.activity_id_list = list
	end
end
function Player:getPlayerActivityIDList()
	return self.activity_id_list
end

-- 获取当前vip经验
function Player:getVipPresentExp()
	local expTotal = self:getRechargeTotal()
--	local vipPresentLv = self:getVipLevel()
--	local consume_exp = 0
--	for i,lv in ipairs(conf.vip.getidlist()) do
--		if lv <= vippresentlv then
--			consume_exp = consume_exp + conf.vip.get(lv).money
--		end
--	end
--	local exp = expTotal - consume_exp
--	if exp < 0 then exp = 0 end
--	print("getVipPresentExp",expTotal,exp,consume_exp)
--	return exp
    if expTotal > CONF.VIP.get(#CONF.VIP).MONEY then
        expTotal = CONF.VIP.get(#CONF.VIP).MONEY
    end
    return expTotal
end
--Vip已领取的免费礼包
function Player:getVipAwardList()
    return self.data_.user_info.vip_award_list
end
--Vip已购买的专属礼包
function Player:getVipPackList()
    return self.data_.user_info.vip_pack_list
end

return Player
