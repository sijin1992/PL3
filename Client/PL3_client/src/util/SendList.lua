
local SendList = class("SendList")

function SendList:ctor()
	self.send_list = {}
end

function SendList:addSend( send ) -- send : {key define strData}
	if send.define == "CMD_PLANET_GET_REQ" and send.key == "planet_get_type_2"  then

		for i,v in ipairs(self.send_list) do
			if v.node_list and send.node_list then
				if v.key == send.key then
					if #v.node_list ~= #send.node_list then
						return
					end
					if Tools.isEmpty(send.node_list) == false then
						for k,l in ipairs(send.node_list) do
							if v.node_list[k] ~= l then
								table.remove(self.send_list,i)
								break
							end
						end
					end
					break
				end
			else
				if v.key == send.key then
					table.remove(self.send_list,i)
					break
				end
			end
		end

		table.insert(self.send_list, send)
	else
		for i,v in ipairs(self.send_list) do
			if v.key == send.key then
				return
			end
		end

		table.insert(self.send_list, send)
	end
end

function SendList:clear( )
	self.send_list = {}
end

function SendList:update()
	
	if Tools.isEmpty(self.send_list) then
		return
	else

		--print("send_list",self.send_list[1].define,self.send_list[1].key)

		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE", self.send_list[1].define),self.send_list[1].strData)

		table.remove(self.send_list, 1)
	end

end

function SendList:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end
		
	return self.instance
end



return SendList