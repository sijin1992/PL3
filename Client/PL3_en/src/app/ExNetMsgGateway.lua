print( "###LUA ExNetMsgGateway.lua" )
-- Coded by Wei Jingjun 20180619
local ExNetMsgGateway = class("ExNetMsgGateway")
-- ExNetMsgGateway = require("app.ExNetMsgGateway")

local app = require("app.MyApp"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()
------------------------------------------------
ExNetMsgGateway.serverDataRetryCount = 0
ExNetMsgGateway.SERVER_RETRY_MAX = 15

-- ExNetMsgGateway.


function ExNetMsgGateway:SaveServerInfo(ud,v)
	local is_server_ok = false

	if( v == nil ) then
		do return false end
	end

	local is_server_bad = (v.nm == nil) or (v.id == nil) or (v.pt == nil) or (v.ip == nil) or (tostring(v.ip) == "0.0.0.0")
	if( is_server_bad == false ) then
		is_server_bad = is_server_bad or (tonumber(v.pt) <= 0)
	end

	is_server_ok = is_server_bad == false

	ud:setStringForKey("server_version", v.vn)
	ud:setStringForKey("server_address", v.ip)
	ud:setIntegerForKey("server_port", tonumber(v.pt or 0) )
	ud:setIntegerForKey("server_id", tonumber(v.id or 0) )
	-- Added by Wei Jingjun 20180531 for Dangle SDK bug
	ud:setStringForKey("server_name", v.nm)
	ud:flush()

	if( is_server_ok == false ) then
		print( " @@@@ SaveServerInfo FAILED!!" )
	else
		print( " @@@@ SaveServerInfo is_server_ok true!!" )
	end

	return is_server_ok
end


-- ADD WJJ 180703
function ExNetMsgGateway:OnGatewayResponse(response, xhr, _self)
	print(string.format("@@@@ xhr.response : %s", tostring(response or " JSON = NIL!!") ) )
	local _is_bug_statusText = ( xhr.statusText == nil ) or ( xhr.statusText == "" )
	local _is_bug_response = ( response == nil ) or ( response == "" )
	print(string.format("@@@ _is_bug_statusText : %s, _is_bug_response : %s ", tostring(_is_bug_statusText), tostring(_is_bug_response) ))

	if( _self == nil ) then
		print(("@@@@ OnGatewayResponse _self : nil 1") )
		_self = require("app.views.LoginScene/LoginScene")
	end


	if( _self == nil ) then
		print(("@@@@ OnGatewayResponse _self : nil 2") )
		do return end
	end

	if( _is_bug_response ) then
		-- self:StopHttp(xhr)

		_self:Retry(xhr)

		do return end
	end



	local output = json.decode(response,1)

	local _is_bug_output = ( output == nil )
	print(string.format("@@@@ _is_bug_output : %s", tostring(_is_bug_output) ) )
	if( _is_bug_output ) then
		_self:Retry(xhr)
		do return end
	end

	print(string.format("@@@@ json.decode : %s", tostring(output) ) )

	for _i2, _v2 in pairs( output ) do
		print(string.format("@@@@ output : [%s]=%s", tostring(_i2), tostring(_v2)))
	end

	if output.errno == 0 then
		_self.data_ = output
		if Tools.isEmpty(_self.data_.server) == false then


			local ud = cc.UserDefault:getInstance()
			local server_id = ud:getIntegerForKey("server_id")

			self.serverDataRetryCount = self.serverDataRetryCount + 1
			print( string.format(" @@@@ serverDataRetryCount : %s  ", tostring(self.serverDataRetryCount)) )
			local is_reset_server_id = (server_id == 0) or (self.serverDataRetryCount > self.SERVER_RETRY_MAX)
			if is_reset_server_id then
				local new_id = _self.data_.server[1].id
				print( string.format(" @@@@ reset_server_id !! new id: %s  ", tostring(new_id)) )
				server_id = new_id
			end

			local is_server_ok = false
			local first_server_id
			for i,v in ipairs(_self.data_.server) do
				for _i, _v in pairs( v ) do
					print(string.format("@@@@ data_.server : [%s]=%s", tostring(_i), tostring(_v)))
				end
				if first_server_id then
					first_server_id = v.id
				end

				print(string.format("@@@@ server_id : %s == v.id : %s", tostring(server_id), tostring(v.id) ) )

				if server_id == v.id then
					is_server_ok = self:SaveServerInfo(ud,v)
				end

				print(string.format("@@@@ is_server_ok : %s", tostring(is_server_ok) ) )
			end

			g_update_server_url = _self.data_.cdn

			g_rechange_rc = _self.data_.rc

			if( is_server_ok == false and first_server_id) then
				ud:setIntegerForKey("server_id",first_server_id)
				--_self:Retry(xhr)
				--do return end
			end
        else
            Tips:tips(CONF:getStringValue("The_server_is_not_open"))
		end

		-- ADD WJJ 20180703
		require("util.ExNetErrorHelper"):getInstance():OnConnectGatewayResponsed()
		if( _self == nil ) then
			return
		end
		if( _self.initScene == nil ) then
			return
		end
		_self:initScene()
	else
		print("server centre error:",output.errno)
        Tips:tips(CONF:getStringValue("The_server_is_not_open"))
	end

	xhr = self.gateway_xhr
	_self:StopHttp(xhr)
end

------------------------------------------------

function ExNetMsgGateway:getInstance()
	print( "###LUA ExNetMsgGateway.lua getInstance" )
	if self.instance == nil then
		self.instance = self:create()
	end

	return self.instance
end


function ExNetMsgGateway:onCreate()
	print( "###LUA ExNetMsgGateway.lua onCreate" )

	

	return self
end

print( "###LUA Return ExNetMsgGateway.lua" )
return ExNetMsgGateway