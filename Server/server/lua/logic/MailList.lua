local MailList = {}

local MaxMailCount = 200

function MailList:getMailBuff()
	return Tools.encode("MailList", self.m_mail_list)
end

function MailList:getMailList()
	return rawget(self.m_mail_list, "mail_list")
end


function MailList:new(mail_buff)
	local mail_list
	if mail_buff then
		mail_list = Tools.decode("MailList", mail_buff)
	else
		mail_list = {}
	end
	if not rawget(mail_list, "mail_list") then
       		mail_list.mail_list = {}
    	end
    	self.m_mail_list = mail_list
end

function MailList:getMailByGUID( guid )
	for index,mail in ipairs(self:getMailList()) do
		if guid == mail.guid then
			return mail,index
		end
	end
	return nil
end


function MailList:limitMailCount(user_info, item_list)
	local mail_list = self:getMailList()
    	local num = #self:getMailList()
    	local t = false
    	while num > MaxMailCount do
       		t = true

       		if mail_list[1].item_list then
       			local items = {}
       			for i,v in ipairs(mail_list[1].item_list) do
       				items[v.id] = v.num
       			end
       			CoreItem.addItems(items, item_list, user_info)
       		end
       		table.remove(mail_list, 1)
       		num = num - 1
       	end
end

return MailList
