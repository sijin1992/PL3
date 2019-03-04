local kc = require "kyotocabinet"
local db = kc.DB:new()

local RedoList = {}

local redo_list = {}


if not db:open("RedoList.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
	error("RedoList.lua open err")
else
	db:iterate(
		function(k,v)

			local t = Tools.decode("RedoEntry", v)
			redo_list[k] = t
			
		end, false
	)
end


function RedoList.addMail(user_name, mail)

	local entry = redo_list[user_name]
	if not entry then
		entry = {user_name = user_name, mail_list = {}}
		redo_list[user_name] = entry
	else
		if entry.mail_list == nil then
			entry.mail_list = {}
		end
	end
	
	table.insert(entry.mail_list, mail)


	local buff = Tools.encode("RedoEntry", entry)
	db:set(user_name, buff)
end

function RedoList.addPlanetMail(user_name, report)
	local mail = {
		type = 4,
		from = Lang.planet_mail_sender,
		subject = "",
		message = "",
		stamp = os.time(),
		expiry_stamp = os.time() + 604800,
		guid = 0,
		planet_report = report,
	}
	--print("addMailaddMailaddMailaddMail")
	--Tools.print_t(mail)

	RedoList.addMail(user_name, mail)

	--print("addMailaddMailaddMailaddMail end")
end

function RedoList.addGroupGiftMail(user_name, title, message, item_list)
	local mail = {
		type = 10,
		from = Lang.group_mail_sender,
		subject = title,
		message = message,
		stamp = os.time(),
		expiry_stamp = os.time() + 604800,
		guid = 0,
		item_list = item_list,
	}
	RedoList.addMail(user_name, mail)
end

function RedoList.addMailBuff(user_name, mail_buff)
	local entry = redo_list[user_name]
	if not entry then
		entry = {user_name = user_name, recharge_list = {}, mail_list = {}}
		redo_list[user_name] = entry
	else
		local t = entry.mail_list
		if entry.mail_list == nil then
			entry.mail_list = {}
		end
	end
	local t = entry.mail_list[1]
	local mail_list = entry.mail_list
	if not mail_list then
		mail_list = {}
		entry.mail_list = mail_list
	end

	local mail_req = Tools.decode("DBSendMailReq", mail_buff)

	local t_mail = {
		type = mail_req.type,
		from = mail_req.from,
		subject = mail_req.subject,
		message = mail_req.message,
		item_list = mail_req.item_list,
		stamp = mail_req.time,
		guid = 0,
		expiry_stamp = 0,
	}
	table.insert(mail_list, t_mail)

	db:set(user_name, Tools.encode("RedoEntry", entry))
end

function RedoList.addRecharge(user_name, money, item_id, fake, od)
	local entry = redo_list[user_name]
	if not entry then
		entry = {user_name = user_name, recharge_list = {}}
		redo_list[user_name] = entry
	end

	local recharge_list = entry.recharge_list
	if not recharge_list then
		recharge_list = {}
		entry.recharge_list = recharge_list
	end
	table.insert(recharge_list, {money = money, item_id = item_id, fake = fake, od = od})
	
	db:set(uid, Tools.encode("RedoEntry", entry))
end


function RedoList.get(user_name)

	local ret = redo_list[user_name]

	return ret
end

function RedoList.clear(user_name)
	redo_list[user_name] = nil
	db:remove(user_name)
end

return RedoList