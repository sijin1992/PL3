--local core_user = require "core_user_funcs"

function set_user_block(user_info_buff, block_type, block_time)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local user_info = userInfo:getUserInfo()

	if block_type == 0 then

		user_info.blocked = {
			type = block_time and 2 or 1,
			stamp = (block_time and block_time > 0) and (os.time() + block_time * 86400) or block_time,
		}

		ArenaCache.remove( user_info.user_name )

	elseif block_type == 1 then

		user_info.blocked = nil

	elseif block_type == 2 then

		user_info.gm_level = block_time
	end

	user_info_buff = userInfo:getUserBuff()
	return user_info_buff
end

function platform_add_money(user_info_buff, item_list_buff, money, extinfo, fake, od)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)

	local itemList = require "ItemList"
	itemList:new(item_list_buff)
	local result = core_recharge(userInfo, itemList, money, extinfo, fake)
	if not od then
		od = "other"
	end
	local user_info = userInfo:getUserInfo()
	LOG_STAT( string.format( "%s|%s|%d|%s|%d|%s|%d", "CAST_OD", user_info.user_name, -result, od , money, extinfo, user_info.money) )


	local user_name = user_info.user_name

	local multi_cast = 
	{
		recv_list = {user_name},
		cmd = 0x16fc,
		msg_buff = string.format("{\"result\":%d,\"productid\":\"%s\",\"vip_level\":%d,\"recharge_money\":%d}", result, extinfo,userInfo:getUserInfo().vip_level,userInfo:getAchievementData().recharge_money),
		--user_sync = 
		--{
			--user_info = userInfo:getUserInfo(),
			--item_list = itemList:getItemList(),
		--},
	}
  	local multi_buff = Tools.encode("Multicast", multi_cast)
  	activeSendMessage(user_name, 0x2100, multi_buff)

	local multi_cast2 = 
	{
		recv_list = {user_name},
		cmd = 0x16fd,
		user_sync = 
		{
			user_info = user_info,
			item_list = itemList:getItemList(),
		},
	}
  	local multi_buff2 = Tools.encode("Multicast", multi_cast2)
  	activeSendMessage(user_name, 0x2100, multi_buff2)

	local yuekaflag = 0
	local itemid = 0
	local new_itemid = 0
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	return user_info_buff, item_list_buff, yuekaflag, itemid, new_itemid
end

function core_recharge(userInfo, itemList, money, extinfo, fake)

	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()

	local splatform = server_platform
	if not splatform then 
		splatform = 0
	end
	LOG_INFO(string.format("core_recharge username:%s,money:%f,extinfo:%s,fake:%d", user_info.user_name, money, extinfo, fake))
	money = money * 0.01

	if fake and fake > 0 then
		return 1
	end

	local achievement_data = userInfo:getAchievementData()

	local function isRecharged( id )
		if Tools.isEmpty(achievement_data.recharge_list) == true then
			return false
		end
		for i,v in ipairs(achievement_data.recharge_list) do
			if v == id then
				return true
			end
		end
		return false
	end


	--添加游戏内货币
	local curConf
	local id_list = CONF.RECHARGE.getIDList()
	for _,id in ipairs(id_list) do
		local conf = CONF.RECHARGE.get(id)
		if extinfo == conf.PRODUCT_ID then
			curConf = conf
			break
		end
	end
	
	if curConf == nil then
		--TODO:
		LOG_ERROR("RECHARGE LIST error: no this PRODUCT_ID:"..extinfo)
		return 2
	end

	local isCard = (string.sub(extinfo,1,4) == "card")

	local isGift = (string.sub(extinfo,1,4) == "gold")

	local isCost = (string.sub(extinfo,1,4) == "cost")

	local extCredit = 0
	if not isCard and not isGift and isRecharged(curConf.ID) == false then
		extCredit = curConf["PRESENT_"..splatform]
	end

	if Tools.isEmpty(achievement_data.recharge_list) == true then
		achievement_data.recharge_list = {curConf.ID}
	else
		table.insert(achievement_data.recharge_list, curConf.ID)
	end
	local credit = curConf["CREDIT_"..splatform] + extCredit
	if credit > 0 then
		CoreUser.addMoney(credit, user_info)
	end

	local cur_time = os.time()

	if isCard then

		if user_info.timestamp.card_end_time == nil then
			user_info.timestamp.card_end_time = cur_time + curConf.TIME
		else
			if user_info.timestamp.card_end_time > 0 then
				user_info.timestamp.card_end_time = curConf.TIME
			end
		end

	elseif isGift then
		local eType 
		local remove_index

		if not Tools.isEmpty(user_info.new_hand_gift_bag_data) and not Tools.isEmpty(user_info.new_hand_gift_bag_data.new_hand_gift_bag_list) then
			for i,v in ipairs(user_info.new_hand_gift_bag_data.new_hand_gift_bag_list) do			
				if v.id == curConf.GIFT_ID then
					eType = 1
					remove_index = i
					break
				end
			end
		end
		if eType == nil and not Tools.isEmpty(user_info.gift_bag_list) then
			for i,v in ipairs(user_info.gift_bag_list) do			
				if v.id == curConf.GIFT_ID then
					eType = 2
					remove_index = i
					break
				end
			end
		end

		if eType == nil then
			LOG_ERROR("RECHARGE GIFT error: no gift data"..extinfo)
			return 3
		end

		if remove_index == nil then
			LOG_ERROR("RECHARGE GIFT error: no gift index"..extinfo)
			return 4
		end

		if eType == 1 then
			local gift_conf = CONF.NEWHANDGIFTBAG.get(curConf.GIFT_ID)
			if cur_time > user_info.new_hand_gift_bag_data.new_hand_gift_bag_list[remove_index].start_time + gift_conf.TIME then
				LOG_ERROR("RECHARGE NEW HAND GIFT error: out of time"..extinfo)
				return 5
			end
			for i=1,#gift_conf.REWARD do
				userInfo:getReward( gift_conf.REWARD[i], item_list)
			end

			table.remove(user_info.new_hand_gift_bag_data.new_hand_gift_bag_list, remove_index)

		elseif eType == 2 then
			local gift_conf = CONF.NEWHANDGIFTBAG.get(curConf.GIFT_ID)
			if cur_time > user_info.gift_bag_list[remove_index].start_time + gift_conf.TIME then
				LOG_ERROR("RECHARGE GIFT error: out of time"..extinfo)
				return 5
			end
			for i=1,#gift_conf.REWARD do
				userInfo:getReward( gift_conf.REWARD[i], item_list)
			end

			user_info.gift_bag_list[remove_index].count = user_info.gift_bag_list[remove_index].count + 1

			if curConf.GROUP_GIFT_ID > 0 
			and Tools.isEmpty( user_info.group_data) == false 
			and user_info.group_data.groupid ~= "" 
			and user_info.group_data.groupid ~= nil then

				local group_main = GroupCache.getGroupMain(user_info.group_data.groupid)
				if group_main ~= nil then

					local group_conf = CONF.GROUP_GIFT.get(curConf.GROUP_GIFT_ID)

					for i,v in ipairs(group_main.user_list) do

						if v.user_name ~= user_info.user_name then
							local items= Tools.getRewards( group_conf.REWARD_ID )

							if Tools.isEmpty(items) == false then
								local item_list = {}
								for key,value in pairs(items) do
									local item = {
										id = key,
										num = value,
										guid = 0,
									}
									table.insert(item_list, item)
								end

								RedoList.addGroupGiftMail(v.user_name, CONF.STRING.get(group_conf.TITLE_ID).VALUE, CONF.STRING.get(group_conf.MEMO).VALUE, item_list)
							end
						end
					end
					
				end
			end
		end		

		--更新总充值金额
		local totalrmb = achievement_data.recharge_money or 0
		achievement_data.recharge_money = totalrmb + curConf["CREDIT_"..splatform]
		GolbalActivity.AddActivityMoney(curConf["RECHARGE_"..splatform], cur_time, user_info)

	elseif isCost then
		local bAdd = false
		Tools._print("isCost start")
		local gift_conf = CONF.NEWHANDGIFTBAG.get(curConf.GIFT_ID)
		if Tools.isEmpty(user_info.next_gift_bag_data) or Tools.isEmpty(user_info.next_gift_bag_data.next_gift_bag) then
			if curConf.GIFT_ID%100 == 1 then
				bAdd = true
			end
		elseif gift_conf and gift_conf.TYPE == 2 then
			for i,v in ipairs(user_info.next_gift_bag_data.next_gift_bag) do
				if v.gift_id == curConf.GIFT_ID then
					bAdd = false
					break
				end
				if v.gift_id + 1 == curConf.GIFT_ID then
					bAdd = true
				end
			end
		end
		Tools._print("isCost add",bAdd,type(gift_conf),(curConf.GIFT_ID%100))
		if bAdd then
			for i=1,#gift_conf.REWARD do
				userInfo:getReward( gift_conf.REWARD[i], item_list)
			end
			if Tools.isEmpty(user_info.next_gift_bag_data) then
				user_info.next_gift_bag_data = {}
			end
			if Tools.isEmpty(user_info.next_gift_bag_data.next_gift_bag) then
				user_info.next_gift_bag_data.next_gift_bag = {}
			end
			local gift_bag = {
				id = curConf.ID,
				gift_id = curConf.GIFT_ID,
				start_time = os.time(),
			}
			table.insert(user_info.next_gift_bag_data.next_gift_bag, gift_bag)
			Tools._print("isCostisCostisCostisCost")
			Tools.print_t(user_info.next_gift_bag_data)
		end

	else
		--更新总充值信用点
		local totalmoney = achievement_data.recharge_money or 0
		achievement_data.recharge_money = totalmoney + curConf["CREDIT_"..splatform]
		GolbalActivity.AddActivityMoney(curConf["RECHARGE_"..splatform], cur_time, user_info)

		Tools._print("111vip_level",user_info.vip_level)
		--更新VIP等级
		if user_info.vip_level == nil then
			user_info.vip_level = 0
		end
		local vip_level = user_info.vip_level
		for i=1,100 do

			local conf = CONF.VIP.check(vip_level + 1)			
			if conf and achievement_data.recharge_money >= conf.MONEY  then
				Tools._print("vip_level",achievement_data.recharge_money,conf.MONEY)
				vip_level = vip_level + 1
			else
				break
			end
		end
		Tools._print("vip_level",vip_level)

		if vip_level > user_info.vip_level then

			user_info.vip_level = vip_level


			local tech_list = userInfo:getTechnologyList()
			local preVipConf = CONF.VIP.check(user_info.vip_level - 1)
			if preVipConf ~= nil then
				if Tools.isEmpty(preVipConf.TECHNOLOGY) == false then
					for i=#tech_list,1,-1 do
						for _,tech_id in ipairs(preVipConf.TECHNOLOGY) do
							if tech_list[i].tech_id == tech_id then
								table.remove(tech_list, i)
								break
							end
						end
					end
				end
			end

			local vipConf = CONF.VIP.get(user_info.vip_level)
			if Tools.isEmpty(vipConf.TECHNOLOGY) == false then
				for i,v in ipairs(vipConf.TECHNOLOGY) do
					if v >0 then
						local tech_info =
						{
							tech_id = v,
							begin_upgrade_time = 0,
						}
						table.insert(tech_list, tech_info)
					end
				end
			end

			if vipConf.QUEUE == 1 then
				-- if user_info.build_queue_list[2].open_time >= 0 then
				-- 	user_info.build_queue_list[2].open_time = -1
				-- end
			end
		end

		--同步viplevel到otheruserinfo
		local other_user_info = UserInfoCache.get(user_info.user_name)
		if other_user_info then

			other_user_info.vip_level = user_info.vip_level

			UserInfoCache.set(other_user_info.user_name, other_user_info)
		end

		--更新总充值金额
		local totalrmb = achievement_data.recharge_real_money or 0
		achievement_data.recharge_real_money = totalrmb + curConf["RECHARGE_"..splatform]

		--更新当前活动充值金额
		local activity_list = CoreUser.getActivityByType(CONF.EActivityType.kRecharge, user_info)
		if activity_list then
			for i,v in ipairs(activity_list) do
				if Tools.isEmpty(v.recharge_data) == true then
					v.recharge_data = {recharge_money = credit}
				else
					v.recharge_data.recharge_money = v.recharge_data.recharge_money + credit
				end
			end
		end

		activity_list = CoreUser.getActivityByType(CONF.EActivityType.kSevenDays, user_info)
		if activity_list then
			for i,v in ipairs(activity_list) do
				local count = v.seven_days_data.recharge_money or 0
				v.seven_days_data.recharge_money = count + credit
			end
		end

		local remove_index
		if not Tools.isEmpty(user_info.gift_bag_list) then
			for i,v in ipairs(user_info.gift_bag_list) do			
				if v.id == curConf.GIFT_ID then
					remove_index = i
					break
				end
			end
		end
		if (remove_index ~= nil) then
			local gift_conf = CONF.NEWHANDGIFTBAG.get(curConf.GIFT_ID)
			if cur_time <= user_info.gift_bag_list[remove_index].start_time + gift_conf.TIME then
				for i=1,#gift_conf.REWARD do
					userInfo:getReward( gift_conf.REWARD[i], item_list)
				end
				user_info.gift_bag_list[remove_index].count = user_info.gift_bag_list[remove_index].count + 1
			end
			
		end

		--充值送帮派成员奖励邮件
		if curConf.GROUP_GIFT_ID  
		and curConf.GROUP_GIFT_ID > 0 
		and Tools.isEmpty( user_info.group_data) == false 
		and user_info.group_data.groupid ~= "" 
		and user_info.group_data.groupid ~= nil then

			local group_main = GroupCache.getGroupMain(user_info.group_data.groupid)
			if group_main ~= nil then

				local gift_conf = CONF.GROUP_GIFT.get(curConf.GROUP_GIFT_ID)

				for i,v in ipairs(group_main.user_list) do

					if v.user_name ~= user_info.user_name then
						local items= Tools.getRewards( gift_conf.REWARD_ID )

						if Tools.isEmpty(items) == false then
							local item_list = {}
							for key,value in pairs(items) do
								local item = {
									id = key,
									num = value,
									guid = 0,
								}
								table.insert(item_list, item)
							end

							RedoList.addGroupGiftMail(v.user_name, CONF.STRING.get(gift_conf.TITLE_ID).VALUE, CONF.STRING.get(gift_conf.MEMO).VALUE, item_list)
						end
					end
				end
				
			end
		end
	end
	return 0 
end

function send_gmail(send_mail_buff)

	local pb = require "protobuf"
	local send_mail = pb.decode("DBSendMailReq", send_mail_buff)

	local t = send_mail.time
	if t == 0 then 
		send_mail.time = 1440 
	end
	local mail = {
		type = send_mail.type,
		from = send_mail.from,
		subject = send_mail.subject,
		message = string.gsub(string.gsub(send_mail.message, "\n", "<$>"),"\r",""),
		item_list = send_mail.item_list,
		stamp = 0,
		guid = 0,
		expiry_stamp = os.time() + send_mail.time * 60,
		buchang = send_mail.buchang,
		reg_time = send_mail.reg_time,
		lev_limit = send_mail.lev_limit,
		vip_limit = send_mail.vip_limit,
	}
	svr_info.add_gmail(mail)
end

function check_cdkey(main_data_buf, cdkey)
	local cdkey_sub = string.upper(string.sub(cdkey, 1, 3))
	local type = string.sub(cdkey_sub, 2,2)
	--Tools._print("cdkey_type = ",cdkey, cdkey_sub, type)
	if type ~= "S" then
		local pb = require "protobuf"
		local main_data = pb.decode("UserInfo", main_data_buf)
		
		local cdkey_struct = rawget(main_data, "cdkey")
		if cdkey_struct then
			if cdkey_struct.last_cdk == cdkey then
				return -5
			end
			for k,v in ipairs(cdkey_struct.cdk_list) do
				if v == cdkey_sub then
					return -3
				end
			end
		end
	end
	return 0
end

function do_cdkey(main_data_buf, item_buf, cdkey, reward_id)
	--Tools._print("do cdkey, reward_id = ", reward_id)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", main_data_buf)
	local item_list = pb.decode("ItemList", item_buf)
	if not rawget(item_list, "item_list") then item_list = {item_list = {}} end
	--[[
	local cdkey_sub = string.upper(string.sub(cdkey, 1, 3))
	local type = string.sub(cdkey, 2,1)
	local cdkey_struct = rawget(main_data, "cdkey")
	if not cdkey_struct then
		cdkey_struct = {last_cdk = "", cdk_list = {}}
		rawset(main_data, "cdkey", cdkey_struct)
	end
	local t = cdkey_struct.last_cdk
	cdkey_struct.last_cdk = cdkey
	local cdkey_list = rawget(cdkey_struct, "cdk_list")
	if not cdkey_list then
		cdkey_list = {}
		rawset(cdkey_struct, "cdkey_list", cdkey_list)
	end
	if type ~= "S" then
		table.insert(cdkey_list, cdkey_sub)
	end
	]]
	local reward_list = svr_info.get_cdk_reward(reward_id)
	assert(reward_list)
	local rsync = {item_list = {},cur_gold = 0, cur_money = 0}
	local k = 1
	while reward_list[k] do
		core_user.get_item(reward_list[k], reward_list[k+1], main_data, 409, nil, item_list.item_list, rsync)
		k = k + 2
	end
	rsync.cur_gold = main_data.gold
	rsync.cur_money = main_data.money
	main_data_buf = pb.encode("UserInfo", main_data)
	item_buf = pb.encode("ItemList", item_list)
	local rsync_buf = pb.encode("CDKEY_Resp.CDKEYRsync", rsync)
	return main_data_buf, item_buf, rsync_buf
end

function get_huodong_list(main_data_buf)
	local pb = require "protobuf"
	local main_data = pb.decode("UserInfo", main_data_buf)
	local list = global_huodong.get_all_huodong(main_data)
	
	local resp = {huodong_list = list}
	local resp_buf = pb.encode("HuodongList", resp)
	return resp_buf
end