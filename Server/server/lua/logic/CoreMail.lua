

local CoreMail = {}

function CoreMail.recvMail(mail, mail_list)

	local guid = Tools.getGuid(mail_list, "guid")
	if mail.stamp == 0 then 
		mail.stamp = os.time() 
	end
	mail.guid = guid
	if mail.type == 10 then 
		mail.expiry_stamp = 0
	else
		local validity = mail.expiry_stamp
		if validity < 1000 then
			mail.expiry_stamp = mail.stamp + 86400 * validity
		end
	end
	table.insert(mail_list, mail)

	CoreMail.CheckUpMail(mail_list)
end

local MAX_MAIL_COUNT = 60
local MAX_OTHER_MAIL_COUNT = 30
function CoreMail.CheckUpMail(mail_list)
	Tools._print("start remove mail")
	if Tools.isEmpty(mail_list) then
		return
	end
	local function GetPlanteMailCount(mail_list)
		local numpl = 0
		for i,mail in ipairs(mail_list) do
			if mail.type == 4 or mail.type == 5 then
				numpl = numpl + 1
			end
		end
		return numpl
	end
	local nowtime = os.time()
	--优先删除超时的
	for i=#mail_list, 1, -1 do
		local mail = mail_list[i]
		if mail.expiry_stamp ~= 0 and nowtime > mail.expiry_stamp then
			table.remove(mail_list, i)
		end
	end

	local plcount = GetPlanteMailCount(mail_list)
	if #mail_list < MAX_MAIL_COUNT and plcount < MAX_OTHER_MAIL_COUNT then
		Tools._print("remove mail no num")
		return
	end
	local remove = 0
	--优先删除已读的宇宙邮件
	for i = #mail_list , 1, -1 do
		local mail = mail_list[i]
		if mail.type == 5 or mail.type == 1 or mail.type == 3 then
			table.remove(mail_list, i)
			if mail.type == 5 then
				plcount = plcount - 1
			end
			remove = remove + 1
		end
	end
	if #mail_list < MAX_MAIL_COUNT and plcount < MAX_OTHER_MAIL_COUNT then
		Tools._print("remove mail1",remove)
		return
	end
	--再删除未读的宇宙邮件
	local i = 1
	while i < #mail_list do
		local mail = mail_list[i]
		if mail.type == 4 or mail.type == 0 then
			table.remove(mail_list, i)
			if mail.type == 4 then
				plcount = plcount - 1
			end
			remove = remove + 1
		else
			i = i + 1
		end
		if #mail_list < MAX_MAIL_COUNT and plcount < MAX_OTHER_MAIL_COUNT then
			Tools._print("remove mail2",remove)
			return
		end
	end
	--在不行就自动领取附件邮件
	--希望不要进这里
	i = 1
	while i < #mail_list do
		local mail = mail_list[i]
		if mail.type == 10 then
			table.remove(mail_list, i)
			remove = remove + 1
		else
			i = i + 1
		end
		if #mail_list < MAX_MAIL_COUNT then
			Tools._print("remove mail3",remove)
			return
		end
	end
	Tools._print("end remove mail")
end

function CoreMail.getMultiCast( recver )
	local list
	if type(recver) == "table" then
		list = recver
	else
		list = {recver}
	end

	local multi_cast =
	{
		recv_list = list,
		cmd = 0x13ff,
		msg_buff = "0",
	}
	return multi_cast
end


function CoreMail.recvMakeFriendMail(sender_info, sender_power, mail_list)

	for i,mail in ipairs(mail_list) do
		if mail.type == 9 and mail.from == sender_info.user_name then
			return false
		end
	end

	local mail = {
		type = 9,
		from = sender_info.user_name,
		subject = "",
		message = "",
		stamp = 0,
		expiry_stamp = 30,
	}

	CoreMail.recvMail(mail, mail_list)
	return true
end

function CoreMail.recvGroupInviteMail(sender_info, mail_list)

	if Tools.isEmpty(sender_info.group_data) == true or sender_info.group_data.groupid == "" or sender_info.group_data.groupid == nil then
		return false
	end

	for i,mail in ipairs(mail_list) do
		if mail.type == 8 and mail.from == sender_info.nickname then
			return false
		end
	end
	
	local main_group = GroupCache.getGroupMain(sender_info.group_data.groupid)
	local mail = {
		type = 8,
		from = sender_info.nickname,
		subject = string.format(Lang.invite_group_msg, sender_info.nickname, main_group.nickname),
		message = sender_info.group_data.groupid,
		stamp = 0,
		expiry_stamp = 30,
	}
	CoreMail.recvMail(mail, mail_list)
	return true
end

return CoreMail