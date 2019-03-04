 
function get_mail_list_feature(step, req_buff, user_name)
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("GetMailListResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_list + datablock.mail_list + datablock.save, user_name
	else
		error("something error")
	end
end

function get_mail_list_do_logic(req_buff, user_name, user_info_buff, item_list_buff, mail_list_buff)

	local req = Tools.decode("GetMailListReq", req_buff)

	local userInfo = require "UserInfo"
	userInfo:new(user_info_buff)
	local user_info = userInfo:getUserInfo()
	local itemList = require "ItemList"
	itemList:new(item_list_buff)

	local mailList = require "MailList"
	mailList:new(mail_list_buff)
	local mail_list = mailList:getMailList()

	local redo = RedoList.get(user_info.user_name)
	if redo then
		--重发之前错误的充值等请求
		if redo.recharge_list then
			for k,v in ipairs(redo.recharge_list) do
				core_recharge(userInfo, itemList, v.money, v.item_id, v.fake)
			end
		end
		--获取邮件
		if redo.mail_list then
			for k,mail in ipairs(redo.mail_list) do
				
				CoreMail.recvMail(mail, mail_list)
			end
		end
		RedoList.clear(user_info.user_name)
	end

	local resp = {
		result = 0,
		user_sync = {
			mail_list = mail_list,
		}
	}
	local resp_buff = Tools.encode("GetMailListResp", resp)
	user_info_buff = userInfo:getUserBuff()
	mail_list_buff = mailList:getMailBuff()
	item_list_buff = itemList:getItemBuff()
	return resp_buff, user_info_buff, item_list_buff, mail_list_buff
end


function send_mail_feature(step, req_buff, user_name)
	if step == 0 then

		local resp = {
			result = -1,
		}
		return 2, Tools.encode("SendMailResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_list + datablock.save, user_name
	elseif step == 2 then
		local req = Tools.decode("SendMailReq", req_buff)
		return datablock.mail_list + datablock.save, req.user_name
	else
		error("something error");
	end
end

function send_mail_do_logic(req_buff, user_name, user_info_buff, item_list_buff, mail_list_buff2)

	local req = Tools.decode("SendMailReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	local mailList2 = require "MailList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	mailList2:new(mail_list_buff2)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	local mail_list2 = mailList2:getMailList()

	local function doLogic(  )

		if req.subject == "" or req.message == "" then
			return 1
		end

		local dirty = false
		for i=1,CONF.DIRTYWORD.len do
			if string.find( req.subject, CONF.DIRTYWORD[i].KEY) ~= nil or string.find( req.message, CONF.DIRTYWORD[i].KEY) ~= nil then
				dirty = true
				break
			end
		end
		if dirty then
			return 2
		end

		local mail = {
			type = 2,
			from = user_info.nickname,
			subject = req.subject,
			message = req.message,
			stamp = os.time(),
			expiry_stamp = os.time() + 604800,
			guid = 0,
			from_user_name = user_name,
		}
	    	CoreMail.recvMail(mail, mail_list2)

		return 0
	end
    	
    	local ret = doLogic()

    	
	local resp = {
		result = ret, 
	}

	user_info_buff = userInfo:getUserBuff()
    	item_list_buff = itemList:getItemBuff()
	mail_list_buff2 = mailList2:getMailBuff()

	local resp_buff = Tools.encode("SendMailResp", resp)
	if ret == 0 then

		local mail_update = CoreMail.getMultiCast(req.user_name)
            		local mail_update_buff = Tools.encode("Multicast", mail_update)

		return resp_buff, user_info_buff, item_list_buff, mail_list_buff2, 0x2100, mail_update_buff
	end
	return resp_buff, user_info_buff, item_list_buff, mail_list_buff2
end

function read_mail_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("ReadMailResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_list + datablock.mail_list + datablock.save, user_name
	else
		error("something error")
	end
end

function read_mail_do_logic(req_buff, user_name, user_info_buff, item_list_buff, mail_list_buff)

	local req = Tools.decode("ReadMailReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	local mailList = require "MailList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	mailList:new(mail_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	local mail_list = mailList:getMailList()

	local get_item_list = {}

	local function doLogic(  )

		local mail,mail_idx = mailList:getMailByGUID(req.guid)

		if mail == nil then
			return 1
		end 

		local user_sync

		if mail.type == 10 then
			local items = {}
			for i,v in ipairs(mail.item_list) do
				items[v.id] = v.num
				table.insert(get_item_list, {key = v.id, value = v.num})
			end
			
			CoreItem.addItems(items, item_list, user_info)
			user_sync = CoreItem.makeSync(items, item_list, user_info)

			table.remove(mailList:getMailList(), mail_idx)


		elseif mail.type == 0 or mail.type == 2 or mail.type == 4 then

			user_sync = {}
			mail.type = mail.type + 1
		else 
			return 2
		end

		user_sync.mail_list = mail_list

		return 0,user_sync
	end
    	
    	local ret,user_sync = doLogic()
    	
	local resp = {
		result = ret,
		user_sync = user_sync,
		req = req,
		get_item_list = get_item_list,
	}

	user_info_buff = userInfo:getUserBuff()
    	item_list_buff = itemList:getItemBuff()
	mail_list_buff = mailList:getMailBuff()

	local resp_buff = Tools.encode("ReadMailResp", resp)
	return resp_buff, user_info_buff, item_list_buff, mail_list_buff
end

function read_mail_list_feature( step, req_buff, user_name )
	if step == 0 then
		local resp = {
			result = -1,
		}
		return 1, Tools.encode("ReadMailListResp", resp)
	elseif step == 1 then
		return datablock.main_data + datablock.item_list + datablock.mail_list + datablock.save, user_name
	else
		error("something error")
	end
end

function read_mail_list_do_logic(req_buff, user_name, user_info_buff, item_list_buff, mail_list_buff)
	local req = Tools.decode("ReadMailListReq", req_buff)
	local userInfo = require "UserInfo"
	local itemList = require "ItemList"
	local mailList = require "MailList"
	userInfo:new(user_info_buff)
	itemList:new(item_list_buff)
	mailList:new(mail_list_buff)
	local user_info = userInfo:getUserInfo()
	local item_list = itemList:getItemList()
	local mail_list = mailList:getMailList()

	local get_item_list = {}
	local function getItem(id)
		if Tools.isEmpty(get_item_list) then
			return nil
		end
		for _,v in ipairs(get_item_list) do
			if v.key == id then
				return v
			end
		end
		return nil
	end
	local function doLogic(  )

		local user_sync
		for _,id in ipairs(req.guid) do

			local mail,mail_idx = mailList:getMailByGUID(id)

			if mail ~= nil then
				if mail.type == 10 then
					local items = {}
					for i,v in ipairs(mail.item_list) do
						items[v.id] = v.num
						local itemlist = getItem(v.id)
						if itemlist then
							itemlist.value = itemlist.value + v.num
						else
							table.insert(get_item_list, {key = v.id, value = v.num})
						end
					end
					
					CoreItem.addItems(items, item_list, user_info)
					user_sync = CoreItem.makeSync(items, item_list, user_info, user_sync)

					table.remove(mailList:getMailList(), mail_idx)
				end		
			end	
		end
		user_sync.mail_list = mail_list
		return 0,user_sync
	end
    	
	local ret,user_sync = doLogic()
    	
	local resp = {
		result = ret,
		user_sync = user_sync,
		req = req,
		get_item_list = get_item_list,
	}
	user_info_buff = userInfo:getUserBuff()
	item_list_buff = itemList:getItemBuff()
	mail_list_buff = mailList:getMailBuff()

	local resp_buff = Tools.encode("ReadMailListResp", resp)
	return resp_buff, user_info_buff, item_list_buff, mail_list_buff
end

function del_mail_feature(step, req_buff, user_name)
	if step == 0 then
		local  resp = {
			result = -1,
		}
		return 1, Tools.encode("DelMailResp", resp)
	elseif step == 1 then
		return datablock.mail_list + datablock.save, user_name
	else
		error("something error")
	end
end

function del_mail_do_logic(req_buff, user_name, mail_list_buff)

	local req = Tools.decode("DelMailReq", req_buff)

	local mailList = require "MailList"

	mailList:new(mail_list_buff)

    	local mail_list = mailList:getMailList()

	local guids = req.guid_list
    	local remove_list = {}

    	for i,guid in ipairs(guids) do
    		for k,v in ipairs(mailList:getMailList()) do
			if v.guid == guid then
				if v.type < 10 then
					table.insert(remove_list, k)
				end
				break
			end
	    	end
    	end

    	table.sort(remove_list)

    	local ret = 0
    	local removeNum = #remove_list
    	if  removeNum < 1 then
    		ret = 1
    	else
    		for index = removeNum, 1, -1 do
        			table.remove(mailList:getMailList(), remove_list[index])
    		end
    	end

	local resp = {
		result = ret,
		user_sync = {
			mail_list = mailList:getMailList(),
		},
	}
	mail_list_buff = mailList:getMailBuff()
	local resp_buff = Tools.encode("DelMailResp", resp)
	return resp_buff, mail_list_buff
end
