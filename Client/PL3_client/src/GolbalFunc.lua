local GlobalFunc_instance = {}

function print_t(table , level, key)
	level = level or 1
	local indent = ""
	for i = 1, level do
		indent = indent.."  "
	end

	if key ~= nil and type(key) == "string" then
		print(indent..key.." ".."=".." ".."{")
	else
		print(indent .. "{")
	end

	key = ""
	for k,v in pairs(table) do
		if type(v) == "table" then
			key = k
			print_t(v, level + 1, key)
		else
			local content = string.format("%s%s = %s", indent .. "  ",tostring(k), tostring(v))
			print(content)  
		end
	end
	print(indent .. "}")
end

-------- interface c++ --------------

function reqPaymentItemCallback(succeed)
	print("lua req_iap_callback:",succeed)

	g_Can_Pay = succeed

end


function payCallback(succeed, productID)
	print("lua payCallback : ",succeed)
	
	print("productID: ",productID)

	-- cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("payCallback")
	local event = cc.EventCustom:new("payCallback")

	local pcb = {productID = productID, succeed = succeed}

	event.info = pcb
	cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)

	if succeed then
		flurryLogEvent("recharge", {productID = tostring(productID)}, 2)
	end

end

local reconnectTimes = 0
function onConnected(flag)
	local gl = require("util.GlobalLoading"):getInstance()
	if gl:isLoading() then
		gl:releaseLoading()
	end
	if flag == false then
		if  reconnectTimes < 5 then
			reconnectTimes = reconnectTimes + 1
			GameHandler.handler_c.reconnect()
			require("util.GlobalLoading"):getInstance():retainLoading()
		else
			reconnectTimes = 0
			require("util.MessageBox"):getInstance():reset(CONF.STRING.get("want_reconnect").VALUE, function ()
				GameHandler.handler_c.reconnect()
				require("util.GlobalLoading"):getInstance():retainLoading()
			end,nil,true)
		end
	else
		require("app.Player"):getInstance():loginRequst()
	end
end

function onConnectError()
	local gl = require("util.GlobalLoading"):getInstance()
	if gl:isLoading() then
		gl:releaseLoading()
	end

	GameHandler.handler_c.reconnect()
	gl:retainLoading()
end

function flurryLogEvent( eventname, data_list, gb_type, gb_res_num )--data_list:{{key(string), value(string)}, {key(string), value(string)}}

	local g_player = require("app.Player"):getInstance()

	if not g_player:isInited() then
		return
	end

	local t = {}
	t.user_name = g_player:getName()
	t.UUID = GameHandler.handler_c.getUUID()
	t.level = tostring(g_player:getLevel())
	t.power = tostring(g_player:getPower())
	t.server_id = tostring(cc.UserDefault:getInstance():getIntegerForKey("server_id"))

	if data_list then
		for k,v in pairs(data_list) do
			if t[k] == nil and type(v) == "string" then
				t[k] = v
			end
		end
	end

	GameHandler.handler_c.flurryLogEvent(eventname, t)


	--gb_type 1.res 2jinbu

	if gb_type then

		local gg = {}
		if data_list then
			for k,v in pairs(data_list) do
				if type(v) == "string" then
					table.insert(gg, v)

				end
			end
		end

		if gb_type == 1 then

			GameHandler.handler_c.onGAAddResourceEvent(eventname, gb_res_num ,gg)
		elseif gb_type == 2 then
			GameHandler.handler_c.onGAAddProgressionEvent(eventname, gg)
		end
	end
end

-- Added by Wei Jingjun 20180607 for Dangle SDK bug
function Call_C_quickPay(recharge_conf, server_platform)
	print("###  Call_C_quickPay recharge_conf: " .. tostring(recharge_conf) .. " / server_platform: " .. tostring(server_platform) )

	local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
	local user_id = cc.UserDefault:getInstance():getStringForKey("user_id")

	-- Added by Wei Jingjun 20180531 for Dangle SDK bug
	local player = require("app.Player"):getInstance()
	local user_name = player:getNickName() -- WJJ: DO NOT USE getName()
	local balance = player:getMoney()
	local vipLv = player:getUserInfo().vip_level
	local userLv = player:getLevel()
	local party = player:getGroupName()
	local createTime = cc.UserDefault:getInstance():getIntegerForKey("user_create_time")
	local server_name = cc.UserDefault:getInstance():getStringForKey("server_name")

	print("###  Call_C_quickPay ", user_id,server_id,recharge_conf.PRODUCT_ID,recharge_conf.CREDIT_0,recharge_conf["RECHARGE_"..server_platform],user_name,balance,vipLv,userLv,party, createTime, server_name)
	GameHandler.handler_c.quickPay(user_id, server_id, recharge_conf.PRODUCT_ID, 1, recharge_conf["RECHARGE_"..server_platform],user_name,balance,vipLv,userLv,party, createTime, server_name)

end

-- Added by Wei Jingjun 20180601 for Dangle SDK bug
function Call_C_setQuickUserInfo()

	local now = os.time()
	local localTimeZone = os.difftime(now, os.time(os.date("!*t", now)))
	local date = os.date("*t", now - localTimeZone)--计算出服务端时区与客户端时区差值
	local date_str = string.format("year:%d/month:%d/day:%d/hour:%d/min:%d/sec:%d", date.year, date.month, date.day, date.hour, date.min, date.sec)

	flurryLogEvent("login", {time = date_str}, 2)

	-------------------------------------------------------------
	-- Added by Wei Jingjun 20180531 for Dangle SDK bug
	local player = require("app.Player"):getInstance()
	if( player == nil ) then
		print("##### lua Call_C_setQuickUserInfo player nil !!!")
		return
	end

	-- WJJ: recharge_conf is not useful here!!
	-- if( recharge_conf == nil ) then
	-- 	print("##### lua Call_C_setQuickUserInfo recharge_conf nil !!!")
	-- 	return
	-- end

	print("#### Call_C_setQuickUserInfo lua setQuickUserInfo")
	local ud = cc.UserDefault:getInstance()

	local user_id = ud:getStringForKey("user_id")
	local server_id = ud:getStringForKey("server_id")

	local user_name = player:getNickName() -- WJJ: DO NOT USE getName()
	local balance = player:getMoney()
	local vipLv = player:getUserInfo().vip_level
	local userLv = player:getLevel()
	local party = player:getGroupName()
	local createTime = cc.UserDefault:getInstance():getIntegerForKey("user_create_time")
	local server_name = cc.UserDefault:getInstance():getStringForKey("server_name")
	local isFirst = cc.UserDefault:getInstance():getIntegerForKey("is_first_on_login")

	print("##### lua Call_C_setQuickUserInfo", user_id,server_id,user_name,balance,vipLv,userLv,party, createTime, server_name)
	print("##### lua isFirst:" .. tostring(isFirst))

	GameHandler.handler_c.setQuickUserInfo(user_id, server_id, date_str, isFirst, user_name, balance, vipLv, userLv, party, createTime, server_name)

end

-- Added by Wei Jingjun 20180601 for Dangle SDK bug
function OnLoginReadyStateSuccess(output)
	print("output",output)
	local isFirst = output.type

	-- Added by Wei Jingjun 20180531 for Dangle SDK bug
	cc.UserDefault:getInstance():setIntegerForKey("is_first_on_login", tonumber(isFirst or 0) )

	local createTime = output.time
	cc.UserDefault:getInstance():setIntegerForKey("user_create_time", tonumber(createTime or 0) )
	print("### user_create_time:" .. tostring(createTime))

	if tonumber(output.result) > 0 then
		local ud = cc.UserDefault:getInstance()
		ud:setStringForKey("user_id", string.format("%d", output.result))
		ud:flush()

		cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventCustom:new("login_update_user_info"))
	else
		if device.platform ~= "windows" then
			print("### OnLoginReadyStateSuccess GameHandler.handler_c.sdkLogin ")
			GameHandler.handler_c.sdkLogin()
		else
			print("### OnLoginReadyStateSuccess windows ")
		-- 	registerGUID()
		end
	end
end

function onSDKLoginCallback( userid, username, token )
	print("onSDKLoginCallback")

	local app = require("app.MyApp"):getInstance()
	local scene_name = app:getTopViewName()
	if scene_name ~= "LoginScene/LoginScene" then
		app:pushToRootView("LoginScene/LoginScene")
		return
	end
	local gl = require("util.GlobalLoading"):getInstance()
	local server_id = cc.UserDefault:getInstance():getStringForKey("server_id")
	local url = string.format("%s?type=4&token=%s&uid=%s&product_code=%s&channel_id=%d&serverid=%s&lang=%d", g_login_server_url, token, userid, g_quick_product_code, GameHandler.handler_c.sdkGetChannelType(),server_id,server_platform,server_platform)

	print("url",url)

	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xhr:open("GET", url)

	local function onReadyStateChanged()

		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
	 
			print("Http Status Code:" .. xhr.statusText)

			local response = xhr.response
			local output = json.decode(response,1)

			if( output == nil ) then
				print("#### Lua GlobalFunc onSDKLoginCallback onReadyStateChanged output NULL")
			else
				OnLoginReadyStateSuccess(output)
			end
		else
			print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
		end

		gl:releaseLoading()
		xhr:unregisterScriptHandler()

		-- Added by Wei Jingjun 20180531 for Dangle SDK bug
		-- here,  do not call GameHandler.handler_c.setQuickUserInfo  in old code

		app:pushToRootView("UpdateScene")
	end

	xhr:registerScriptHandler(onReadyStateChanged)
	xhr:send()
	gl:retainLoading()
end

function onSDKLogoutCallback()
	print("onSDKLogoutCallback")
	local player = require("app.Player"):getInstance()
	player:initInfo()

	local app = require("app.MyApp"):getInstance()
	local scene_name = app:getTopViewName()
	if scene_name ~= "LoginScene/LoginScene" then
		app:pushToRootView("LoginScene/LoginScene")
	end
end

function onSDKPayCallback(result)
	if result ~= 0 then
		local gl = require("util.GlobalLoading"):getInstance()
		if gl:isLoading() == true then
			gl:releaseLoading()
		end
	end
end


------------------------

function playMusic(filename, loop)

	if cc.exports.g_background_music_id == nil then
		cc.exports.g_background_music_id = cc.AUDIO_INVAILD_ID
	end

	if cc.exports.g_background_music_id ~= cc.AUDIO_INVAILD_ID then

		ccexp.AudioEngine:stop(cc.exports.g_background_music_id)
	end

	-- BUG FIX WJJ 20180718
	-- local volume = cc.UserDefault:getInstance():getIntegerForKey("musicVolume")
	local volume = tonumber(cc.exports.musicVolume) or 0

	cc.exports.g_background_music_id = ccexp.AudioEngine:play2d(filename, loop, volume)

	cc.exports.g_background_music_name = filename
end

function playEffectSound( filename )

	-- local volume = cc.UserDefault:getInstance():getIntegerForKey("effectVolume")
	local volume = cc.exports.effectVolume
	volume = tonumber(volume) or 0

	local audio_id = ccexp.AudioEngine:play2d(filename, false, volume)

	if audio_id ~= cc.AUDIO_INVAILD_ID then
		table.insert(g_Effect_Sound, audio_id)

		ccexp.AudioEngine:setFinishCallback(audio_id, function ()

			for i,v in ipairs(g_Effect_Sound) do
				if v == audio_id then
					table.remove(g_Effect_Sound, i)
					break
				end
			end
		end)
	end

end

function setMusicVolume( volume )
	-- BUG FIX by WJJ 20180718
	local num = tonumber(volume)/100
	num = tonumber(num) or 0
	ccexp.AudioEngine:setVolume(cc.exports.g_background_music_id, num)

	
end

function setEffectVolume( volume )
	-- BUG FIX by WJJ 20180718
	local num = tonumber(volume)/100
	num = tonumber(num) or 0
	for i,v in ipairs(g_Effect_Sound) do
		ccexp.AudioEngine:setVolume(v, num)
	end

end

function sleep(n)
	if device.platform == "windows" then
		if n > 0 then os.execute("ping -n " .. tonumber(n + 1) .. " localhost > NUL") end
	else
		os.execute("sleep " .. n)
	end
end

function formatTime(time)
	
	if time < 0 then
		time = 0
	end

	time = math.floor(time)

	local hour = math.floor(time/3600);
	local minute = math.fmod(math.floor(time/60), 60)
	local second = math.fmod(time, 60)

	if hour<10 then
		hour = string.format("0%s",hour)
	end

	if minute<10 then
		minute = string.format("0%s",minute)
	end

	if second<10 then
		second = string.format("0%s",second)
	end

	local rtTime = string.format("%s:%s:%s", hour, minute, second)
	return rtTime
end

function formatTime2(time)
	
	if time < 0 then
		time = 0
	end

	local day = math.floor(time/86400)

	local hour = math.fmod(math.floor(time/3600), 24);
	local minute = math.fmod(math.floor(time/60), 60)
	local second = math.fmod(time, 60)

	if hour<10 then
		hour = string.format("0%s",hour)
	end

	if minute<10 then
		minute = string.format("0%s",minute)
	end

	if second<10 then
		second = string.format("0%s",second)
	end

    local rtTime
    if day ~= 0 and hour == "00" and minute == "00" and second == "00" then
        rtTime = string.format(" %s".."d", day)
    else
	    rtTime = string.format(" %s".."d".."%s:%s:%s", day, hour, minute, second)
    end
	return rtTime
end

function formatRes( res_num )
	if res_num == nil then
		return 0
	end
	if res_num < 0 then
		res_num = 0 
	end

	local res_str = ""
	if res_num < 1000 then
		res_str = tostring(res_num)
	elseif res_num >= 1000 and res_num < 1000000 then
		local k_num = math.floor(res_num/100)

		local zheng_num = math.floor(k_num/10)
		local dian_num = math.floor(k_num%10)

		res_str = zheng_num.."."..dian_num.."K"
	elseif res_num >= 1000000 and res_num < 1000000000 then
		local k_num = math.floor(res_num/100000)

		local zheng_num = math.floor(k_num/10)
		local dian_num = math.floor(k_num%10)

		res_str = zheng_num.."."..dian_num.."M"
	else
		local k_num = math.floor(res_num/100000000)

		local zheng_num = math.floor(k_num/10)
		local dian_num = math.floor(k_num%10)

		res_str = zheng_num.."."..dian_num.."G"
	end

	return res_str
end

---------- ui ------------

function createFightRangeString( weaponConf )
	local key1,key2
	if weaponConf.TARGET_1 ~= 0 then
		key1 = weaponConf.TARGET_1
		key2 = weaponConf.TARGET_2
	else 
		key1 = weaponConf.BUFF_TARGET_1[1]
		key2 = weaponConf.BUFF_TARGET_2[1]
	end

	local target_1 = CONF.STRING.get( string.format("FightRange_1_%d", key1) ).VALUE
	local target_2 = ""
	if key2 > 0 then
		target_2 = CONF.STRING.get( string.format("FightRange_2_%d", key2) ).VALUE
	end
	return string.format("%s %s", target_1,target_2)
end


function createWeaponPowerElements(typeStr, rt, conf, data1, data2, diffConf)--data={c = text:getTextColor(), fn = text:getFontName(), fs = text:getFontSize() , str = text:getString(), p = cc.p(text:getPosition()), ap = text:getAnchorPoint() }
	local flag
	if typeStr == "power" or typeStr == "" then

		print("diffConf", diffConf, type(diffConf))
		if diffConf == nil then
			flag = conf.ATTR_PERCENT > 0 or conf.ATTR_VALUE > 0

		else
			flag = diffConf.ATTR_PERCENT ~= conf.ATTR_PERCENT or diffConf.ATTR_VALUE ~= conf.ATTR_VALUE
		end

		if flag then

			if data1 then
				local attrStr = CONF.STRING.get(string.format("Attr_%d", CONF.EShipAttr.kAttack)).VALUE
				local re1 = ccui.RichElementText:create(1, cc.c3b(data1.c.r, data1.c.g, data1.c.b), data1.c.a, attrStr, data1.fn, data1.fs)
				rt:pushBackElement(re1)
			end

			if diffConf == nil then
				flag = conf.ATTR_PERCENT > 0
			else
				flag = diffConf.ATTR_PERCENT ~= conf.ATTR_PERCENT
			end

			if flag then

				local re2 = ccui.RichElementText:create(2, cc.c3b(data2.c.r, data2.c.g, data2.c.b), data2.c.a, string.format("%d%%  ", conf.ATTR_PERCENT), data2.fn, data2.fs)
				rt:pushBackElement(re2)
				return
			end

			if diffConf == nil then
				flag = conf.ATTR_VALUE > 0

			else
				flag = diffConf.ATTR_VALUE ~= conf.ATTR_VALUE
			end

			if flag then

				local re2 = ccui.RichElementText:create(2, cc.c3b(data2.c.r, data2.c.g, data2.c.b), data2.c.a, string.format("+%d  ", conf.ATTR_VALUE), data2.fn, data2.fs)
				rt:pushBackElement(re2)
			end

			return
		else
			if typeStr == "power" then
				if data1 then
					local re1 = ccui.RichElementText:create(1, cc.c3b(data1.c.r, data1.c.g, data1.c.b), data1.c.a, CONF.STRING.get("null").VALUE, data1.fn, data1.fs)
					rt:pushBackElement(re1)
				end
				return
			end
		end
	end

	local isAdded = false

	if conf.BIG ~= 1 and  (typeStr == "effect" or typeStr == "") then


		

		local percents = {}
		local adds = {}

		for i=1,#conf.BUFF_ID do
			if conf.BUFF_ID[i] == 0 then
				break
			end

			local buffConf =  CONF.BUFF.get(conf.BUFF_ID[i]) 

			if diffConf == nil then
				flag = conf.BUFF_ATTR_PERCENT[i] ~= 0

			else
				flag = diffConf.BUFF_ATTR_PERCENT[i] ~= conf.BUFF_ATTR_PERCENT[i]
			end

			if flag then
				percents[CONF.STRING.get(buffConf.MEMO_ID).VALUE] = conf.BUFF_ATTR_PERCENT[i]
			end

			if diffConf == nil then
				flag = conf.BUFF_ATTR_VALUE[i] ~= 0

			else
				flag = diffConf.BUFF_ATTR_VALUE[i] ~= conf.BUFF_ATTR_VALUE[i]
			end
			if flag then

				adds[CONF.STRING.get(buffConf.MEMO_ID).VALUE] = conf.BUFF_ATTR_VALUE[i]
			end
		
		end

		for k,v in pairs(percents) do

			local re1
			if data1 then 
				re1 = ccui.RichElementText:create(1, cc.c3b(data1.c.r, data1.c.g, data1.c.b), data1.c.a, k, data1.fn, data1.fs)
			end
			local re2 = ccui.RichElementText:create(2, cc.c3b(data2.c.r, data2.c.g, data2.c.b), data2.c.a, string.format("%d%%  ", v), data2.fn, data2.fs)

			if re1 then
				rt:pushBackElement(re1)
			end
			rt:pushBackElement(re2)

			isAdded = true
		end

		for k,v in pairs(adds) do
			if v ~= 0 then
				local re1
				if data1 then 
					re1 = ccui.RichElementText:create(1, cc.c3b(data1.c.r, data1.c.g, data1.c.b), data1.c.a, k, data1.fn, data1.fs)
				end
				local re2 = ccui.RichElementText:create(2, cc.c3b(data2.c.r, data2.c.g, data2.c.b), data2.c.a, string.format("%d  ", v), data2.fn, data2.fs)

				if re1 then
					rt:pushBackElement(re1)
				end
				rt:pushBackElement(re2)

				isAdded = true
			end
		end

		if diffConf == nil then
			flag = conf.BUFF_CONDITION_PERCENT[1] ~= 0

		else
			flag = conf.BUFF_CONDITION_PERCENT[1] ~= diffConf.BUFF_CONDITION_PERCENT[1]
		end
		
		if isAdded == false and flag then
			
			local re1 
			if data1 then
				re1 = ccui.RichElementText:create(1, cc.c3b(data1.c.r, data1.c.g, data1.c.b), data1.c.a, CONF.STRING.get("buff_condition").VALUE, data1.fn, data1.fs)
			end
			local re2 = ccui.RichElementText:create(2, cc.c3b(data2.c.r, data2.c.g, data2.c.b), data2.c.a, string.format("%d%% ", conf.BUFF_CONDITION_PERCENT[1]), data2.fn, data2.fs)

			if re1 then
				rt:pushBackElement(re1)
			end
			rt:pushBackElement(re2)

			isAdded = true
		end

		

	end

	if isAdded == false then
		local re1 
		if data1 then
			re1 = ccui.RichElementText:create(1, cc.c3b(data1.c.r, data1.c.g, data1.c.b), data1.c.a, CONF.STRING.get("null").VALUE, data1.fn, data1.fs)
		end
		if re1 then
			rt:pushBackElement(re1)
		end
	end

end

function createWeaponRichText(typeStr,conf,text1,text2, diffConf) -- typeStr: "power", "effect"

	local text = text1 or text2

	local richText = ccui.RichText:create()
	richText:setName(text:getName())
	richText:setPosition(cc.p(text:getPosition()))
	richText:setAnchorPoint(cc.p(text:getAnchorPoint()))
	richText:setContentSize(text:getContentSize())


	local data1 = text1 and {c = text1:getTextColor(), fn = text1:getFontName(), fs = text1:getFontSize() } or nil
	local data2 = text2 and {c = text2:getTextColor(), fn = text2:getFontName(), fs = text2:getFontSize() } or nil

	createWeaponPowerElements(typeStr,richText,conf,data1,data2, diffConf)

	return richText
end


--设置技能的描述detail  （*  $ 只读 或 不读）
--type : 1，只显示大技能描述 *...*
--       2，只显示技能描述 没有数据
--       3，显示除了A之外的其他所有数据 B可能有两个
--       4，显示所有数据 B可能有两个
--       5, 只读$...$ 及$...$中的BCD
function setMemo( conf ,type)
	local memo = CONF.STRING.get(conf.MEMO_ID).VALUE
	local id_list = CONF.MEMO_PARAM.getIDList()
	if memo == nil or memo =="" or id_list == nil then
		print("error: empty")
		return
	end

	local function resetForBCD( memo )
		for i,v in ipairs(id_list) do
			local param = CONF.MEMO_PARAM.get(v)                                
			if param.KEY ~= "#A#" then  
				local percent = param.PARAM[1]
				local value = param.PARAM[2]
				local conf_percent = conf[percent]
				local conf_value = conf[value]
				local numPercent 
				local numValue 
				if conf_percent then 
					numPercent = #conf_percent
				else
					numPercent = 0
				end
				if conf_value then 
					numValue = #conf_value
				else
					numValue = 0
				end     

				local max = numPercent > numValue and numPercent or numValue
				for i=1,max do
					--准备替换字符串
					local reps = ""
					if value and value ~= 0 and conf_value then 
						if conf_value[i] and conf_value[i] ~= 0 then
							reps = reps .. tostring(math.abs(conf_value[i]))
						end
					end

					if percent ~= 0 and percent and conf_percent then 
						if conf_percent[i] and conf_percent[i] ~= 0 then
							if reps ~= "" then
								if conf.SPECIAL_DISPLAY and conf.SPECIAL_DISPLAY == 2 then
									reps = tostring(math.abs(conf_percent[i])) .. "%%".. "+" .. reps 
								else
									reps = reps .. "+" .. tostring(math.abs(conf_percent[i])) .. "%%"
								end
							else
								reps = tostring(math.abs(conf_percent[i])) .. "%%"
							end
						end
					end 
					----查找并分割字符串 替换之后再还原
					if reps ~= "" then
						local pos1,pos2 = string.find(memo ,param.KEY)
						if pos1 then 
							local memoCut = string.sub(memo ,1 ,pos2)
							memo = string.sub(memo ,pos2+1 ,-1)
							memoCut = string.gsub(memoCut ,param.KEY ,reps)
							memo = memoCut .. memo
						end 

					end
					
				end
			end
		end
		return memo 
	end

	if type == 1 then
		local pos = string.find(memo ,"%*" ,2)
		if pos then
			memo = string.sub(memo ,2 ,pos - 1)
			return memo
		else
			print("error: no * ")
			return
		end
	elseif type == 5 then 
		local pos1 = string.find(memo ,"%$" ,1)
		if pos1 then
			memo = string.sub(memo ,pos1 + 1 ,-2)
			return resetForBCD(memo)
		else
			print("error: no $ ")
			return
		end

	else
		--把* 和$ 里面的内容都裁掉
		local pos = string.find(memo ,"%*" ,2)
		if pos then
			memo = string.sub(memo ,pos + 1 ,-1)
		end
		local pos1 = string.find(memo ,"%$" ,1)
		if pos1  then
			memo = string.sub(memo ,1 ,pos1 - 1)
		end

		if type == 2 then
			for i,v in ipairs(id_list) do
				local param = CONF.MEMO_PARAM.get(v)
				if string.find(memo ,param.KEY) then            
					memo = string.gsub(memo ,param.KEY ,"")
				end
			end
			return memo     
		elseif type == 3 then 
			memo = string.gsub(memo ,"#A#" ,"")
		elseif type == 4 then 
			local param
			for i,v in ipairs(id_list) do
				param = CONF.MEMO_PARAM.get(v)
				if param.KEY == "#A#" then                  
					break 
				end
			end
			local reps = ""
			if param.KEY == "#A#" then              
				local percent = param.PARAM[1]
				local energy = param.PARAM[2]
				local value = param.PARAM[3]

				--%x物理
				if percent and percent ~= 0 then 
					if conf[percent] ~= 0 then
						reps = tostring(math.abs(conf[percent])) .. "%%" .. CONF:getStringValue("physical")
					end
				end
				-- + %x 能量
				if energy and energy ~= 0 then 
					if conf[energy] ~= 0 then
						if reps ~= "" then 
							reps =reps .. "+" .. tostring(math.abs(conf[energy])) .. "%%" .. CONF:getStringValue("energy")
						else
							reps = tostring(math.abs(conf[energy])) .. "%%" .. CONF:getStringValue("energy")
						end
					end
				end
				-- + value
				if value and value ~= 0 then 
					if conf[value] ~= 0 then
						if reps ~= "" then 
							reps = reps .. "+" .. reps .. tostring(math.abs(conf[value]))
						else
							reps = tostring(math.abs(conf[value]))
						end                       
					end
				end             
			end
			memo = string.gsub(memo ,"#A#" ,reps)
		end
		-- type 3 和 4 中BCD的显示方式一样 
		if type == 3 or type == 4 then          
			return resetForBCD(memo)
		end
	end
end

function tipsAction( node, pos, func )

	if pos == nil then
		local center = cc.exports.VisibleRect:center()
		node:setPosition(center)
	else
		node:setPosition(pos)
	end
	node:setScale(0.7)
	node:setOpacity(0)
	node:setCascadeOpacityEnabled(true)
	local fadeIn = cc.FadeIn:create(1/3)
	local scale = cc.ScaleTo:create(1/3 ,1.0)
	node:runAction(cc.Sequence:create(cc.Spawn:create(fadeIn ,scale), cc.CallFunc:create(function ( ... )
		if func then
			func()
		end
	end)))
end

function getEnemyIcon( monster_list )
	local monsterNums = {}
	for i,v in ipairs(monster_list) do
		if v ~= 0 then
			if monsterNums[1] then
				local has = false
				for i2,v2 in ipairs(monsterNums) do
					if v == v2 then
						has = true
					end
				end

				if not has then
					monsterNums[table.getn(monsterNums)+1] = v
				end
			else
				monsterNums[1] = v
			end
		end
	end


	local monster_id = math.abs(monsterNums[#monsterNums])
	local res_id = CONF.AIRSHIP.get(monster_id).ICON_ID
	local str = "RoleIcon/"..res_id..".png"
	return str
end

--技能描述
function createWeaponInfo( conf, size )
	if conf == nil then
		return nil
	end

	local fontName = s_default_font

	local fontSize = 20
	if size then
		fontSize = size
	end

	local string_1 = ""  -- skill_power_num
	local string_2 = ""     -- skill_power_type
	local string_3 = ""     -- skill_power_num_2
	local string_4 = ""     -- skill_power_type_2


	if conf.SIGN == 0 then

		string_1 = ""
		string_2 = CONF:getStringValue("null")
		string_3 = ""
		string_4 = ""

	else

		if conf.ATTR_PERCENT == 0 then

			string_1 = ""
			string_2 = ""
		else

			string_1 = conf.ATTR_PERCENT.."%"
			string_2 = CONF:getStringValue("Attr_3")
		end

		if conf.ATTR_PERCENT ~= 0 or conf.ATTR_VALUE ~= 0 then
			string_2 = string_2.."+"
		end

		if conf.ENERGY_ATTR_PERCENT == 0 then

			string_3 = ""
			string_4 = ""
		else

			string_3 = conf.ENERGY_ATTR_PERCENT.."%"
			string_4 = CONF:getStringValue("Attr_20")
		end

		local num = conf.ATTR_VALUE + conf.ENERGY_ATTR_VALUE

		if num ~= 0  then
			if conf.ATTR_PERCENT ~= 0 or conf.ENERGY_ATTR_PERCENT ~= 0 then

				string_4 = string_4.."+"
			end

			string_4 = string_4..num
		end

		if conf.SIGN == 1 then

--			string_4 = string_4..CONF:getStringValue("de_damage")
		elseif conf.SIGN == 2 then

--			string_4 = string_4..CONF:getStringValue("de_cure")
		end

	end


	local richText = ccui.RichText:create()
	-- richText:ignoreContentAdaptWithSize(false)  
	-- richText:setContentSize(cc.size(400,24))

	local re1 = ccui.RichElementText:create( 1, cc.c3b(33, 255, 70), 255, string_1, fontName, fontSize )  
	local re2 = ccui.RichElementText:create( 2, cc.c3b(255, 255, 255), 255, string_2, fontName, fontSize )  
	local re3 = ccui.RichElementText:create( 3, cc.c3b(255, 230, 18), 255, string_3, fontName, fontSize )  
	local re4 = ccui.RichElementText:create( 4, cc.c3b(255, 255, 255), 255, string_4, fontName, fontSize )  

	richText:pushBackElement(re1)  
	richText:pushBackElement(re2)  
	richText:pushBackElement(re3)  
	richText:pushBackElement(re4)  

	richText:setAnchorPoint(cc.p(0,0.5))

	return richText
end

function textSetPos( text1, text2, diff, direction) -- 1x 2y
	text1:setAnchorPoint(cc.p(0,0.5))
	text2:setAnchorPoint(cc.p(0,0.5))

	if direction == 1 then
		text2:setPositionX(text1:getPositionX() + text1:getContentSize().width + diff)
	elseif direction == 2 then
		text2:setPositionY(text1:getPositionY() + text1:getContentSize().height + diff)
	end
end

function numRound( num )
	
	if num*10%10 >= 5 then
		return math.ceil(num)
	else
		return math.floor(num)
	end

end

function setScreenPosition( node, cmd)

	local VisibleRect = cc.exports.VisibleRect
	local default = cc.p(1136,768)

	local winSize = cc.Director:getInstance():getWinSize()
	local diffSize_ = cc.size((winSize.width - CC_DESIGN_RESOLUTION.width)/2,(winSize.height - CC_DESIGN_RESOLUTION.height)/2)

	local origin = nil

	local relativePos = nil

	local curOrigin = nil

	if cmd == "leftbottom" then

		origin = cc.p(0,0)
		curOrigin = VisibleRect:leftBottom()

	elseif cmd == "rightbottom"  then

		origin = cc.p(default.x,0)
		curOrigin = VisibleRect:rightBottom()

	elseif cmd == "righttop"  then

		origin = cc.p(default.x,default.y)
		curOrigin = VisibleRect:rightTop()

	elseif cmd == "lefttop"  then

		origin = cc.p(0,default.y)
		curOrigin = VisibleRect:leftTop()

	elseif cmd == "left"  then

		origin = cc.p(0,default.y/2)
		curOrigin = VisibleRect:left()

	elseif cmd == "bottom"  then

		origin = cc.p(default.x/2,0)
		curOrigin = VisibleRect:bottom()

	elseif cmd == "right"  then

		origin = cc.p(default.x,default.y/2)
		curOrigin = VisibleRect:right()
		
	elseif cmd == "top"  then

		origin = cc.p(default.x/2,default.y)
		curOrigin = VisibleRect:top()
	elseif cmd == "center" then
		origin = cc.p(default.x/2,default.y/2)
		curOrigin = VisibleRect:center()
	else
		
	end

	if nil ~= origin or nil ~= curOrigin then
		print(node:getName()..":setPosition 1057 cmd "..cmd) 
		print(string.format("%s:setPosition 1057 origin x:%s, y:%s", node:getName(), tostring(origin.x), tostring(origin.y)))
		print(string.format("%s:setPosition 1057 curOrigin x:%s, y:%s", node:getName(), tostring(curOrigin.x), tostring(curOrigin.y)))
		local x,y = node:getPosition()
		print(string.format("%s:setPosition 1058 getPosition x:%s, y:%s", node:getName(), tostring(x), tostring(y)))
		relativePos = cc.pSub(cc.p(node:getPosition()),origin)
		print(string.format("%s:setPosition 1058 relativePos x:%s, y:%s", node:getName(), tostring(relativePos.x), tostring(relativePos.y)))
		local p  = cc.pAdd(curOrigin,relativePos)
		print(string.format("%s:setPosition 1060 x:%s, y:%s", node:getName(), tostring(p.x), tostring(p.y)))
		p = cc.p(p.x - diffSize_.width,p.y - diffSize_.height)
		print(string.format("%s:setPosition 1062 x:%s, y:%s", node:getName(), tostring(p.x), tostring(p.y)))
		node:setPosition(p)
	end

end

function setScreenPositionWin( node, cmd)
	local winSize = cc.Director:getInstance():getWinSize()
	local p 
	if cmd == "leftbottom" then

		p = cc.p(0,0)
	elseif cmd == "rightbottom"  then

		p = cc.p(winSize.width,0)
	elseif cmd == "righttop"  then

		p = cc.p(winSize.width,winSize.height)
	elseif cmd == "lefttop"  then

		p = cc.p(0,winSize.height)
	elseif cmd == "left"  then

		p = cc.p(0,winSize.height/2)
	elseif cmd == "bottom"  then

		p = cc.p(winSize.width/2,0)
	elseif cmd == "right"  then
	
		p = cc.p(winSize.width,winSize.height/2)
	elseif cmd == "top"  then

		p = cc.p(winSize.width/2,winSize.height)
	elseif cmd == "center" then

		p = cc.p(winSize.width/2,winSize.height/2)
	else
		
	end

	if p then
		print("setScreenPositionCenter", p.x, p.y)
		local x,y = node:getPosition()

		node:setPosition(cc.p(p.x + x, p.y + y))
	end
end

function getScreenDiffLocation( ... )
	
	local winSize = cc.Director:getInstance():getWinSize()

	local bili_x = CC_DESIGN_RESOLUTION.width/winSize.width
	local bili_y = CC_DESIGN_RESOLUTION.height/winSize.height

	local x = 0
	local y = 0
	if bili_x > bili_y then
		x = CC_DESIGN_RESOLUTION.width - (winSize.width*(CC_DESIGN_RESOLUTION.height/winSize.height))
	else
		y = CC_DESIGN_RESOLUTION.height - (winSize.height*(CC_DESIGN_RESOLUTION.width/winSize.width))
	end

	return x,y

end


function addItemInfoTips( conf,strength )
	if display:getRunningScene():getChildByName("info_node") then
		display:getRunningScene():getChildByName("info_node"):removeFromParent()
	end

	local info_node
	if conf.TYPE == 9 or conf.TYPE == 10 then
		info_node = require("util.ItemInfoNode"):createEquipNode(conf.ID, conf.TYPE, strength)
	else
		info_node = require("util.ItemInfoNode"):createItemInfoNode(conf.ID, conf.TYPE)
		
	end

	info_node:setPosition(cc.exports.VisibleRect:center())
	info_node:setName("info_node")
	display:getRunningScene():addChild(info_node, SceneZOrder.kItemInfo)
end

function createRichTextNeedChangeColor( str, size )

	local richText = ccui.RichText:create()
	-- richText:ignoreContentAdaptWithSize(false)  

	local fontName = s_default_font

	local fontSize = 20
	if size then
		fontSize = size
	end

	local function strNot(  )
		local strs = {}

		while true do
			if not string.find(str,"/n") then
			
				table.insert(strs,str)
				break
			end

			local pos1,pos2 = string.find(str,"/n")

			local sr = string.sub(str, 1, pos1-1)

			-- if sr ~= "" then
				table.insert(strs, sr)
			-- end

			local ssr = string.sub(str,pos1,pos1+1)
			table.insert(strs, ssr)

			str = string.sub(str, pos1+2)
		end

		for i,v in ipairs(strs) do
			if v ~= "/n" then
				local label = ccui.RichElementText:create( i, cc.c3b(255, 255, 255), 255, v, fontName, fontSize, 2 ) 
				richText:pushBackElement(label) 
			else
				local newLine = ccui.RichElementNewLine:create(i, cc.c3b(255, 255, 255), 255)
				richText:pushBackElement(newLine) 
			end
		end


		return richText


	end

	if not string.find(str,"#") then

		strNot()

	else
		if string.sub(str, 1,1) ~= "#" then
			strNot()

		end

	end

	
	local strs = {}

	while true do
		if not string.find(str,"#") then
		
			table.insert(strs,str)
			break
		end

		local pos1 = string.find(str,"#")

		local sr = string.sub(str, 1, pos1-1)

		-- if sr ~= "" then
			table.insert(strs, sr)
		-- end

		local ssr = string.sub(str,pos1,pos1+8)
		table.insert(strs, ssr)

		str = string.sub(str, pos1+9)
	end

	table.remove(strs,1)

	local labels = {}

	local num = 1
	for i=1,math.floor(#strs/2) do
		local v1 = strs[i*2-1]
		local v2 = strs[i*2]

		if v1 == nil or v2 == nil then
			break
		end

		local has_newLine = false

		if string.find(v2,"/n") then
			local pos = string.find(v2,"/n")
			v2 = string.sub(v2,1,pos-1)

			has_newLine = true
		end

		local sttr = string.sub(v1,2)

		local s1 = string.sub(sttr,1,2)
		local s2 = string.sub(sttr,3,4)
		local s3 = string.sub(sttr,5,6)
		local s4 = string.sub(sttr,7,8)

		local color1 = tonumber(s1, 16)
		local color2 = tonumber(s2, 16)
		local color3 = tonumber(s3, 16)
		local flags = tonumber(s4)

		local label = ccui.RichElementText:create( num, cc.c3b(color1, color2, color3), 255, v2, fontName, fontSize, flags ) 
		num = num + 1
		table.insert(labels,label)


		if has_newLine then
			local newLine = ccui.RichElementNewLine:create(num, cc.c3b(255, 255, 255), 255)
			num = num + 1
			table.insert(labels,newLine)
		end

	end

	for i,v in ipairs(labels) do

		richText:pushBackElement(v) 
	end

	-- local newLine = ccui.RichElementNewLine:create(#labels+1, cc.c3b(255, 255, 255), 255)
	-- richText:pushBackElement(newLine) 

	-- local label_2 = ccui.RichElementText:create( #labels+2, cc.c3b(255, 255, 255), 255, "ceshi huanhang hahahah ", fontName, fontSize, 2 ) 
	-- richText:pushBackElement(label_2) 

	return richText

end

function broadcastRun()

	local player = require("app.Player"):getInstance()
	local animManager = require("app.AnimManager"):getInstance()

	if player:getGuideStep() < CONF.GUIDANCE.count() then
		return
	end

	if player.broadcast_run_list == nil then
		return
	end

	print("#player.broadcast_run_list",#player.broadcast_run_list)
	if #player.broadcast_run_list == 0 then
		return
	end

	-- if g_broadcast_run then
	--  return
	-- end

	if display:getRunningScene():getChildByName("broadcast_clip") then
		display:getRunningScene():getChildByName("broadcast_clip"):removeFromParent()
	end

	local str = player.broadcast_run_list[1].str

	local clip = cc.ClippingNode:create()  
	clip:setInverted(false)  
	-- clip:setAlphaThreshold(0.5)  
	clip:setName("broadcast_clip")
	display:getRunningScene():addChild(clip)  

	local back = cc.LayerColor:create(cc.c4b(0, 0, 0, 155))  
	back:setContentSize(cc.size(1136,768))
	back:setOpacity(100)
	clip:addChild(back)

	local stencil = cc.Sprite:create("Common/newUI/gg_bottom.png")
	stencil:setAnchorPoint(cc.p(0.5,0.5))
	-- stencil:setScale(800/stencil:getContentSize().width, 50/stencil:getContentSize().height)
	clip:setStencil(stencil) 

	local center = cc.exports.VisibleRect:center()

	local yyy = 280
	local xxx = -10
	stencil:setPosition(cc.p(center.x + xxx, center.y + yyy))

	local di = cc.Sprite:create("Common/newUI/gg_bottom.png")
	di:setPosition(cc.p(center.x + xxx, center.y + yyy ))
	clip:addChild(di)
	
	local text = cc.Label:createWithTTF(str, "fonts/cuyabra.ttf", 22)
	-- label:setPosition(cc.p(center.x + label:getContentSize().width/2 + 400, center.y + yyy ))
	-- -- label:setAnchorPoint(cc.p(0,1))
	-- -- label:setLineBreakWithoutSpace(true)
	-- -- label:setMaxLineWidth(600)
	-- label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)

	local label = createRichTextNeedChangeColor(str, 22)
	label:setAnchorPoint(cc.p(0,0.5))
	label:setPosition(cc.p(center.x + di:getContentSize().width/2 + xxx, center.y + yyy - 4 ))
	clip:addChild(label)

	label:runAction(cc.Sequence:create(cc.CallFunc:create(function ( ... )
		g_broadcast_run = true
	end), cc.MoveBy:create(10, cc.p(-di:getContentSize().width-text:getContentSize().width, 0)), cc.CallFunc:create(function ( ... )
		clip:removeFromParent()
		g_broadcast_run = false

		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("broadcastRun")
	end)))

	setScreenPosition(clip, "top")

	if  player.broadcast_run_list[1].type == 2 then
		local yanhua = require("app.ExResInterface"):getInstance():FastLoad("Common/sfx/fireworks/fireworks.csb")
		animManager:runAnimOnceByCSB(yanhua, "Common/sfx/fireworks/fireworks.csb", "1", function ( ... )
			yanhua:removeFromParent()
		end)

		yanhua:setPosition(cc.exports.VisibleRect:center())
		display:getRunningScene():addChild(yanhua)

	end

	player:removeBroadcastList(str)

end

function getStringCount( str )
	local count = 0
	local index = 0
	for i=1,string.len(str) do
		
		local curByte = string.byte(str, i)
		local byteCount = 1
		if curByte>0 and curByte<=127 then
			byteCount = 1
		elseif curByte>=192 and curByte<=223 then
			byteCount = 2
		elseif curByte>=224 and curByte<=239 then
			byteCount = 3
		elseif curByte>=240 and curByte<=247 then
			byteCount = 4
		end

		if index < i then
			index = index + byteCount

			count = count + 1
		   
		end
	end

	return count
end

function shuaiSubString( str )
	local index = 0
	local sub_num_list = {}

	local chat = ""
	for i=1,string.len(str) do
		
		local curByte = string.byte(str, i)
		local byteCount = 1
		local need_change = true
		if curByte>0 and curByte<=127 then
			byteCount = 1
		elseif curByte>=192 and curByte<=223 then
			byteCount = 2
		elseif curByte>=224 and curByte<=239 then
			byteCount = 3
			need_change = false
		elseif curByte>=240 and curByte<=247 then
			byteCount = 4
		end

		if index < i then
			index = index + byteCount
			

			if need_change then
				-- chat = chat.."*"
			else
				table.insert(sub_num_list, i)
			end
		end
	end

	if not Tools.isEmpty(sub_num_list) then
		for i,v in ipairs(sub_num_list) do
			local r = string.sub(str, v )
			r =  string.sub(r, 1,3 )
			chat = chat..r
		end
		
	else
		return str

	end

	return chat,sub_num_list
end

function handsomeSubString( str, num )

	local chat = ""
	local count = 0
	local index = 0
	local pos = 0
	for i=1,string.len(str) do
		
		local curByte = string.byte(str, i)
		local byteCount = 1
		if curByte>0 and curByte<=127 then
			byteCount = 1
		elseif curByte>=192 and curByte<=223 then
			byteCount = 2
		elseif curByte>=224 and curByte<=239 then
			byteCount = 3
		elseif curByte>=240 and curByte<=247 then
			byteCount = 4
		end

		if index < i then
			index = index + byteCount

			if count < num then
				pos = index
			end

			count = count + 1
		   
		end
	end

	if count > num then
		chat = string.sub(str, 1, pos - string.len(str) - 1 ).."..."
	else
		chat = str
	end

	return chat
end

function changeChatString( str )
	local chat = str

	for i=1,CONF.DIRTYWORD.len do
		if string.find(chat, CONF.DIRTYWORD[i].KEY) then
			local count = getStringCount(CONF.DIRTYWORD[i].KEY)
			local r = ""
			for i=1,count do
				r = r.."*"
			end

			chat = string.gsub(chat, CONF.DIRTYWORD[i].KEY, r)
		end
	end

	local fuhao = {"。","，","：","；","【","】","（","）","！","￥"}
	local fuhao_en = {".",",",":",";","[","]","(",")","!","$"}
	local fuhao_pos = {}
	local fuhao_buff = {}
	for i,v in ipairs(fuhao) do
		if string.find(chat, v) then
			local count = getStringCount(v)

			local pos = string.find(chat,v)
			table.insert(fuhao_pos, pos)
			table.insert(fuhao_buff, v)

			chat = string.gsub(chat, v, fuhao_en[i])
		end
	end


	for i=1,CONF.DIRTYWORD.len do
		local s,sub_num_list = shuaiSubString(chat)
		if string.find(s, CONF.DIRTYWORD[i].KEY) then
			local dc = getStringCount(CONF.DIRTYWORD[i].KEY)
			local pos1,pos2 = string.find(s, CONF.DIRTYWORD[i].KEY)
			local sub1 = sub_num_list[(pos1-1)/3+1]
			local sub2 = sub_num_list[pos2/3]

			local str0 = string.sub(chat,1,sub1-1)
			local str1 = string.sub(chat,sub1)
			local str2 = string.sub(str1, (sub2-sub1+3+1))
			local count = sub2-sub1+3-(string.len(CONF.DIRTYWORD[i].KEY) - getStringCount(CONF.DIRTYWORD[i].KEY))

			local str3 = ""
			for i=1,count do
				str3 = str3.."*"
			end

			chat = str0..str3..str2

		end
	end 

	return chat

end

function beautiflySubString( str )

	local ss = str
	local xx = {}

	for i=1,string.len(ss) do
		
		local curByte = string.byte(ss, i)

		local byteCount = 1
		if curByte>0 and curByte<=127 then
			byteCount = 1
		elseif curByte>=192 and curByte<=223 then
			byteCount = 2
		elseif curByte>=224 and curByte<=239 then
			byteCount = 3
		elseif curByte>=240 and curByte<=247 then
			byteCount = 4
		end

		if #xx == 0 then
			table.insert(xx, byteCount)
		else
			if i > xx[#xx] then
				table.insert(xx, byteCount)
			end
		end
	end

	local strs = {}
	for i,v in ipairs(xx) do

		local sub_num = 0
		if i == 1 then
			sub_num = v
		else
			sub_num = v - xx[i-1]
		end

		local sr = string.sub(ss, 1, sub_num)

		ss = string.sub(ss,sub_num+1)

		table.insert(strs, sr)
	end

	return str
end

function getStringByte( str )
	local count = 0
	local index = 0
	for i=1,string.len(str) do
		
		local curByte = string.byte(str, i)
		local byteCount = 1
		if curByte>0 and curByte<=127 then
			byteCount = 1
		elseif curByte>=192 and curByte<=223 then
			byteCount = 2
		elseif curByte>=224 and curByte<=239 then
			byteCount = 3
		elseif curByte>=240 and curByte<=247 then
			byteCount = 4
		end

		if index < i then
			index = index + byteCount

			count = count + 1
		   
		end
	end

	return index
end

function checkFunc( name, showTip )
	local player =  require("app.Player"):getInstance()
	local str = name .. "_open"
	local heroLevel = CONF.PARAM.get(str).PARAM[1]
	local centreLevel = CONF.PARAM.get(str).PARAM[2]
	if player:getLevel() < heroLevel or player:getBuildingInfo(1).level < centreLevel then
		if showTip == true then
			local tips = require("util.TipsMessage"):getInstance()
			local tipStr = ""
			if heroLevel ~= 0 then 
				tipStr = tipStr .. CONF:getStringValue("levelNum") .. tostring(heroLevel) .. "\n"
			end
			if centreLevel ~= 0 then 
				tipStr = tipStr .. CONF:getStringValue("CentreLevel") .. CONF:getStringValue("achieve") .. tostring(centreLevel)
			end
			tips:tips(tipStr)
		end
		return false
	end   
	return true
end

function goScene( turn_type, turn_id, ship_guid ,data)

	local app = require("app.MyApp"):getInstance()

	local tips = require("util.TipsMessage"):getInstance()

	local player =  require("app.Player"):getInstance()

	local director = cc.Director:getInstance()

	if turn_type == 1 then --通关类型 跳转到关卡
		if chapterId then
			local chapterId = turn_id

			if chapterId == 0 then
				chapterId = player:getMaxCopy()
			end
			local stage = CONF.CHECKPOINT.get(chapterId).AREA_ID
			local area = CONF.COPY.get(stage).AREA
			local copy = chapterId % 100
			app:pushToRootView("LevelScene", {area = area, stage = stage, index = copy})
		else
			app:pushView("ChapterScene")
		end
	elseif turn_type == 2 then --建筑类 跳转到建筑
		if turn_id == 0 then 
			app:pushToRootView("CityScene/CityScene", {pos = -1350})
		elseif turn_id == 1 then 
			local b1,b2,b3 = isBuildingOpen(1,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 1})
		elseif turn_id == 2 then
			local b1,b2,b3 = isBuildingOpen(2,true)
			if not b1 or not b2 or not b3 then
				return
			end
			print(" go ShipsDevelopScene at 1504 GlobalFunc ")
			app:pushView("ShipsScene/ShipsDevelopScene")
		elseif turn_id == 3 then 
			local b1,b2,b3 = isBuildingOpen(3,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 3})
		elseif turn_id == 4 then 
			local b1,b2,b3 = isBuildingOpen(4,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 4})
		elseif turn_id == 5 then
			local b1,b2,b3 = isBuildingOpen(5,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 5})
		elseif turn_id == 6 then
			local b1,b2,b3 = isBuildingOpen(6,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("HomeScene/HomeScene",{})
		elseif turn_id == 7 then
			local b1,b2,b3 = isBuildingOpen(7,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 7})
		elseif turn_id == 8 then
			local b1,b2,b3 = isBuildingOpen(9,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushToRootView("ChapterScene")
		elseif turn_id == 9 then
			local b1,b2,b3 = isBuildingOpen(4,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("WeaponDevelopScene/WeaponScene")
		elseif turn_id == 10 then
			local b1,b2,b3 = isBuildingOpen(5,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("TechnologyScene/TechnologyScene")
		elseif turn_id == 11 then
			local can_upgrade_building_list = CONF.PARAM.get("building skip").PARAM
			local low_key = 1
			local level = player:getBuildingInfo(1).level
			for i,key in ipairs(can_upgrade_building_list) do
				local building_level = player:getBuildingInfo(key).level
				local can_upgrade_level = player:canBuildingCanUpgrade(key)
				if can_upgrade_level then
					local b1,b2,b3 = isBuildingOpen(key)
					if b1 and b2 and b3 then
						if building_level <= level then
							level = building_level
							low_key = key
							break
						end
					end
				end
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = low_key})
		elseif turn_id == 12 then -- 战争工坊升级
			local b1,b2,b3 = isBuildingOpen(14,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 14})
		elseif turn_id == 13 then -- 锻造中心
			local b1,b2,b3 = isBuildingOpen(16,true)
			if not b1 or not b2 or not b3 then
				return
			end
            if data then
                app:pushView("SmithingScene/SmithingScene",data)
            else
			    app:pushView("SmithingScene/SmithingScene")
            end
		elseif turn_id == 14 then -- 仓库升级界面
			local b1,b2,b3 = isBuildingOpen(10,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 10})
		elseif turn_id == 15 then -- 锻造中心升级界面
			local b1,b2,b3 = isBuildingOpen(16,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 16})
		elseif turn_id == 16 then -- 外交局升级界面
			local b1,b2,b3 = isBuildingOpen(13,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 13})
		elseif turn_id == 17 then -- 城防跑台升级界面
			local b1,b2,b3 = isBuildingOpen(12,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 12})
		elseif turn_id == 18 then -- 侦查塔升级界面
			local b1,b2,b3 = isBuildingOpen(11,true)
			if not b1 or not b2 or not b3 then
				return
			end
			app:pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = 11})
		end
	elseif turn_type == 3 then --家园类
		local b1,b2,b3 = isBuildingOpen(6,true)
		if not b1 or not b2 or not b3 then
			return
		end
		app:pushView("HomeScene/HomeScene",{})
	elseif turn_type == 4 then  --主角类
		local layer = app:createView("TaskScene/AttributeLayer")
		director:getRunningScene():addChild(layer)
	elseif turn_type == 5 then  --飞船类
		local b1,b2,b3 = isBuildingOpen(2,true)
		if not b1 or not b2 or not b3 then
			return
		end
		print(" go ShipsDevelopScene at 1629 GlobalFunc ")
		app:pushView("ShipsScene/ShipsDevelopScene",{type = 5})
	elseif turn_type == 6 then  --竞技场类
		local icon_open = isIconShow(216,true)
		if not icon_open then
			return
		end
		if turn_id == 1 then
			app:pushToRootView("ArenaScene/ArenaScene", {go = "title"})
		else
			app:pushToRootView("ArenaScene/ArenaScene")
		end
	elseif turn_type == 7 then -- 星盟类
		if isIconShow(204,true) then
			app:pushView("StarLeagueScene/StarLeagueScene")
		end
	elseif turn_type == 9 then  --星盟科技
		if isIconShow(204,true) then
			if player:isGroup() then
				app:pushView("StarLeagueScene/StarLeagueScene", {resetType = "technology"})
			else
				tips:tips(CONF:getStringValue("leagueNmae"))
			end
		end
	elseif turn_type == 10 then --星盟boss
		if isIconShow(204,true) then
			if player:isGroup() then
				app:pushView("StarLeagueScene/GroupBossScene", {group_list = player:getPlayerGroupMain()})
			else
				tips:tips(CONF:getStringValue("leagueNmae"))
			end
		end
	elseif turn_type == 11 then  --星球占领

		if player:isOpenPlanet() then

			-- local conf = CONF.AREA.get(player:getMaxArea())
			-- local area = player:getMaxArea()
			-- local index_ = player:getStageByArea(area)
			-- local stage = conf.SIMPLE_COPY_ID[index_]
			-- local copy = player:getCopyInStage(stage)
			-- app:pushToRootView("LevelScene", {area = area, stage = stage, index = copy, go = "planet"})
			-- local layer = app:createView("StarOccupationLayer/StarOccupationLayer", {area = player:getPlanetNum()})
			self:getApp():pushToRootView("PlanetScene/PlanetScene")
			

			-- director:getRunningScene():addChild(layer)
		end
	elseif turn_type == 12 then  --试炼
		if isIconShow(217,true) then
			app:pushToRootView("TrialScene/TrialAreaScene")
		end
		
	elseif turn_type == 13 then   --加体力
		app:addView2Top("CityScene/AddStrenthLayer")
	elseif turn_type == 14 then --抽奖
		local b1,b2,b3 = isBuildingOpen(8,true)
		if not b1 or not b2 or not b3 then
			return
		end
		app:pushView("LotteryScene/LotteryScene")
	elseif turn_type == 15 then --签到
		app:addView2Top("ActivityScene/ActivitySignin")

	elseif turn_type == 16 then
		print(" go ShipsDevelopScene at 1694 GlobalFunc ")
		app:pushView("ShipsScene/ShipsDevelopScene")
	elseif turn_type == 17 then --宝石融合
		local b1,b2,b3 = isBuildingOpen(16,true)
		if not b1 or not b2 or not b3 then
			return
		end
		app:pushView("SmithingScene/SmithingScene",{kind = 3})
	elseif turn_type == 18 then   --星系
		-- app:pushToRootView("CityScene/CityScene", {pos = -350, strong_index = turn_id})
		if not canEnterPlanet() then
            local str = CONF:getStringValue("plz_activation_universe")
            tips:tips(str)
            return
        end
        if not isIconShow(210,true) then
			return
		end
		app:pushToRootView("PlanetScene/PlanetScene", {come_in_type = 1})
	elseif turn_type == 19 then -- 商城
		require("app.ExViewInterface"):getInstance():ShowShopUI()
		-- app:addView2Top("ShopScene/ShopLayer")
	elseif turn_type == 20 then -- 任务
		app:addView2Top("TaskScene/TaskScene", 1)
	elseif turn_type == 21 then -- 特殊
		if player:isGroup() then -- 有星盟，跳转星系
            if not canEnterPlanet() then
                local str = CONF:getStringValue("plz_activation_universe")
                tips:tips(str)
                return
            end
			app:pushToRootView("PlanetScene/PlanetScene", {come_in_type = 1})
		else 
			if isIconShow(204,true) then
				app:pushView("StarLeagueScene/StarLeagueScene") -- 没有星盟，跳转星盟
			end
		end
    elseif turn_type == 22 then

		local rechargeNode = app:addView2Top("CityScene/RechargeNode")
		
	 	rechargeNode:init(display.getRunningScene(), {index = 1})
 	elseif turn_type == 23 then
        if turn_id ~= 0 then
		    app:pushView("BlueprintScene/BlueprintScene",{ mode_ = turn_id})
        else
            app:pushView("BlueprintScene/BlueprintScene")
        end
	end
end

function canEnterPlanet()
    local player =  require("app.Player"):getInstance()
	local str = "planet_open"
	local heroLevel = CONF.PARAM.get(str).PARAM[1]
	local centreLevel = CONF.PARAM.get(str).PARAM[2]
    local isopen = true
	if player:getLevel() < heroLevel or player:getBuildingInfo(1).level < centreLevel then
        isopen = false
		return false
	end
    if isopen then
        if not cc.exports.isjihuoplanet then
            isopen = false
            return false
        end
    end
    return true
end

function showTaskNodeItem( id, node, flag)

	if not node then
		return
	end

	local task = CONF.TASK.get(id)

	if flag == true then
		local itemPos = node:getChildByName("itemPos")

		local scalX = 1
		local scalY = 1



		for i,v in ipairs(task.ITEM_ID) do
			local itemNode =require("util.ItemNode"):create():init(v, task.ITEM_NUM[i])
	
			node:addChild(itemNode)
			local posX = itemPos:getPositionX() + (itemPos:getContentSize().width + 15)* (i-1)
			itemNode:setPosition(cc.p(posX ,itemPos:getPositionY() ))
			itemNode:setName(tostring(v))
			itemNode:setScale(0.75)
		end
	else

		for i,v in ipairs(task.ITEM_ID) do
			node:getChildByName(tostring(v)):removeFromParent()
		end
	end
end

function createIntroduceNode( str )

	local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/WeaponStateNode.csb")
	local text_list = node:getChildByName("text_list")
	text_list:setScrollBarEnabled(false)
	local listSize = text_list:getContentSize()
	local label = cc.Label:createWithTTF(str, s_default_font, 20, cc.size(listSize.width, 0))
	local inner_height
	if label:getContentSize().height > listSize.height then
		inner_height = label:getContentSize().height
		label:setPosition(0, inner_height)
	else
		inner_height = listSize.height
		label:setPosition(0, inner_height - (inner_height-label:getContentSize().height)*0.5)
		text_list:setTouchEnabled(false)
	end
	label:setAnchorPoint(cc.p(0, 1))
	-- label:enableShadow(cc.c4b(255,255,255,255), cc.size(0.5,0.5))
	text_list:setInnerContainerSize(cc.size(listSize.width, inner_height))
	text_list:addChild(label)

	node:getChildByName("bg"):setSwallowTouches(true)
	node:getChildByName("bg"):addClickEventListener(function ( sender )
		node:removeFromParent()
	end)
	tipsAction(node)
	return node
end

function createLevelUpNode( level,level_now )

	cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("playerLevelUp")

	local player =  require("app.Player"):getInstance()
	local animManager = require("app.AnimManager"):getInstance()

    if device.platform == "ios" or device.platform == "android" then
        TDGAAccount:setLevel(player:getLevel())
    end

	flurryLogEvent("player_level_up", {lineup_id =  player:getForms(), lineup_power = player:getLineupPower(), res = player:getUserInfo().res})
	
	local conf = CONF.PLAYERLEVEL.get(level)

	local now_conf = CONF.PLAYERLEVEL.get(level_now)

	local node = require("app.ExResInterface"):getInstance():FastLoad("Common/LevelUpNode.csb")

	node:getChildByName("level"):setString(CONF:getStringValue("grade")..":")
	node:getChildByName("level_now"):setString(now_conf.ID)
	node:getChildByName("level_next"):setString(conf.ID)

	node:getChildByName("ship"):setString(CONF:getStringValue("ship_max")..":")
	node:getChildByName("ship_now"):setString(now_conf.ID)
	node:getChildByName("ship_next"):setString(conf.ID)

	node:getChildByName("building"):setString(CONF:getStringValue("zhihuizhongxin")..":")

	local now_blv = 0
	local next_blv = 0
	for i,v in ipairs(CONF.BUILDING_1.getIDList()) do
		if now_blv == 0 then
			if CONF.BUILDING_1.get(v).PLAYER_LEVEL > now_conf.ID then
				now_blv = i
			end
		end

		if next_blv == 0 then
			if CONF.BUILDING_1.get(v).PLAYER_LEVEL > conf.ID then
				next_blv = i
			end
		end

		if now_blv ~= 0 and next_blv ~= 0 then
			break
		end

	end

	node:getChildByName("building_now"):setString(now_blv)
	node:getChildByName("building_next"):setString(next_blv)

	node:getChildByName("strength"):setString(CONF:getStringValue("tili")..":")
	node:getChildByName("strength_now"):setString(now_conf.STRENGTH)
	node:getChildByName("strength_next"):setString(conf.STRENGTH)

	node:getChildByName("friend"):setString(CONF:getStringValue("haoyou")..":")
	node:getChildByName("friend_now"):setString(now_conf.FRIEND_NUM)
	node:getChildByName("friend_next"):setString(conf.FRIEND_NUM)

	node:getChildByName("sudu1"):setString(CONF:getStringValue("hejin")..":")
	node:getChildByName("sudu1_now"):setString(now_conf.COLLECT_SPEED.."/h")
	node:getChildByName("sudu1_next"):setString(conf.COLLECT_SPEED.."/h")

	node:getChildByName("sudu2"):setString(CONF:getStringValue("jingti")..":")
	node:getChildByName("sudu2_now"):setString(now_conf.COLLECT_SPEED_1.."/h")
	node:getChildByName("sudu2_next"):setString(conf.COLLECT_SPEED_1.."/h")

	node:getChildByName("sudu3"):setString(CONF:getStringValue("nengyuan")..":")
	node:getChildByName("sudu3_now"):setString(now_conf.COLLECT_SPEED_2.."/h")
	node:getChildByName("sudu3_next"):setString(conf.COLLECT_SPEED_2.."/h")

	local texts = {"level", "ship", "building", "strength", "friend", "sudu3", "sudu2", "sudu1"}

	-- local function setPos( name )
	--  local text = node:getChildByName(name)
	--  local text_now = node:getChildByName(name.."_now")
	--  local text_next = node:getChildByName(name.."_next")
	--  local text_jt = node:getChildByName(name.."_jt")

	--  text_jt:setPositionX(text_now:getPositionX() + text_now:getContentSize().width + 5)
	--  text_next:setPositionX(text_jt:getPositionX() + text_jt:getContentSize().width + 5)

	-- end

	-- for i,v in ipairs(texts) do
	--  setPos(v)
	-- end

	local isOpen = false
	local func_open = 0
	for i,v in ipairs(CONF.FUNCTION_OPEN.getIDList()) do
		local grade = CONF.FUNCTION_OPEN.get(v).GRADE

		if grade > level_now and grade <= level then
			isOpen = true
			func_open = i
			break
		end
	end

	-- if isOpen then

	--  local cconf = CONF.FUNCTION_OPEN.get(func_open)

	--  node:getChildByName("open"):setString(CONF:getStringValue("jiesuo")..":")
	--  node:getChildByName("open_text"):setString(CONF:getStringValue(cconf.NAME_KEY))
	-- else
	--  node:getChildByName("open"):setVisible(false)
	--  node:getChildByName("open_text"):setVisible(false)
	-- end

	node:getChildByName("back"):setTag(0)

	node:getChildByName("back"):setSwallowTouches(true)
	node:getChildByName("back"):addClickEventListener(function ( ... )

		if node:getChildByName("back"):getTag() == 0 then
			return
		end

		node:removeFromParent()

		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("levelupOver")

		if isOpen then
			local cconf = CONF.FUNCTION_OPEN.get(func_open) 

			local open_node = require("app.ExResInterface"):getInstance():FastLoad("Common/OpenSystemNode.csb")

			open_node:getChildByName("title"):setString(CONF:getStringValue("jiesuo"))

			open_node:getChildByName("name"):setString(CONF:getStringValue(cconf.NAME_KEY))
            ----------Add and Revise By JinXin 20180720
            local build_pos = -350
            if cconf.NAME_KEY and string.find(cconf.NAME_KEY,"_") ~= nil then
                local str = Split(cconf.NAME_KEY,"_")
                if str[1] == "BuildingName" then
                    build_pos = CONF.EMainBuildingPos[tonumber(str[2])]
                end
            end
            open_node:getChildByName("btn_tiao"):getChildByName("text"):setString(CONF:getStringValue("skip"))
			open_node:getChildByName("btn_tiao"):addClickEventListener(function ( ... )
--                if cc.exports.GettedRewardListNode ~= nil then
--                    cc.exports.GettedRewardListNode:removeFromParent()
--                    cc.exports.GettedRewardListNode = nil
--                end
				local app = require("app.MyApp"):getInstance()
				app:pushToRootView("CityScene/CityScene", {pos = build_pos})
			end)
            ----------------------------------
			if cconf.MEMO_KEY then
				open_node:getChildByName("ins"):setString(CONF:getStringValue(cconf.MEMO_KEY))
			else
				open_node:getChildByName("ins"):setString("")
			end

			if cconf.ICON then 
				open_node:getChildByName("icon"):setTexture("CityScene/ui3/"..cconf.ICON)
			else
				open_node:getChildByName("icon"):setVisible(false)
			end

			open_node:getChildByName("back"):setTag(0)

			open_node:getChildByName("back"):setSwallowTouches(true)

			open_node:getChildByName("icon"):setPositionX(0 - open_node:getChildByName("name"):getContentSize().width/2 - open_node:getChildByName("icon"):getContentSize().width/2 - 5)

			open_node:getChildByName("back"):addClickEventListener(function ( ... )

				if open_node:getChildByName("back"):getTag() == 0 then
					return
				end

				open_node:removeFromParent()

				if cconf.FUNCTION == 1 then
					local app = require("app.MyApp"):getInstance()

					if cconf.KEY ~= "star_open" then
						app:pushToRootView("CityScene/CityScene", {pos = -1350, function_id = cconf.FUNCTION_ID})

					else

						local stage = CONF.CHECKPOINT.get(player:getMaxCopy()).AREA_ID
						local area = CONF.COPY.get(stage).AREA
						local copy = player:getMaxCopy() % 100
						app:pushToRootView("LevelScene", {area = area, stage = stage, index = copy, function_id = cconf.FUNCTION_ID})
					end

					playMusic("sound/main.mp3", true)

				end

			end)

			tipsAction(open_node, nil, function ( ... )
				open_node:getChildByName("back"):setTag(1)
			end)

			open_node:setPosition(cc.exports.VisibleRect:center())

			display:getRunningScene():addChild(open_node, SceneZOrder.kLevelUp)

		end
	end)

	-- tipsAction(node, nil, function ( ... )
	--  node:getChildByName("back"):setTag(1)
	-- end)

	local function setPos( name )
		local now = node:getChildByName(name.."_now")
		local jt = node:getChildByName(name.."_jt")
		local next = node:getChildByName(name.."_next")

--		jt:setPositionX(now:getPositionX() + now:getContentSize().width + 5)
--		next:setPositionX(jt:getPositionX() + jt:getContentSize().width + 5)

		now:setOpacity(255)
		jt:setOpacity(255)
		next:setOpacity(255)
	end

	local function onFrameEvent(frame)
		if nil == frame then
			return
		end
		local str = frame:getEvent()

		if str == "1" then

			local nn = frame:getNode()

			if nn:getName() ~= "open" then
				setPos(nn:getName())
			else
				if isOpen then

					local cconf = CONF.FUNCTION_OPEN.get(func_open)

					node:getChildByName("open"):setString(CONF:getStringValue("jiesuo")..":")
					node:getChildByName("open_text"):setString(CONF:getStringValue(cconf.NAME_KEY))

					node:getChildByName("open"):setVisible(true)
					node:getChildByName("open_text"):setVisible(true)

					node:getChildByName("open_text"):setOpacity(255)
				else
					node:getChildByName("open"):setVisible(false)
					node:getChildByName("open_text"):setVisible(false)
				end
			end
		end
	end

	local function actionOver( ... )
		node:getChildByName("back"):setTag(1)
	end

	animManager:runAnimOnceByCSB(node, "Common/LevelUpNode.csb",  "1", actionOver, onFrameEvent)


	node:setPosition(cc.exports.VisibleRect:center())

	display:getRunningScene():addChild(node,SceneZOrder.kLevelUp)

	g_Player_Level = level
end

function fightNumRun( text, num, up_num )

	local scheduler = cc.Director:getInstance():getScheduler()
	
	local diff = up_num - num

	-- if diff < 0 then
	--  return
	-- end

	local schedulerEntry
	local update_num = 1

	local diff_num = diff/20
	local function update( ... )

		if text then
			text:setString(math.floor(num+diff_num))

			if math.floor(num+diff_num) < 0 then
				text:setString(0)
			end

			if update_num < 20 then
				diff_num = diff_num + diff/20
				update_num = update_num + 1
			else
				scheduler:unscheduleScriptEntry(schedulerEntry)
			end
		else
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end

		schedulerEntry = scheduler:scheduleScriptFunc(update,0.01,false)

end

function Split(szFullString, szSeparator)  
	local nFindStartIndex = 1  
	local nSplitIndex = 1  
	local nSplitArray = {}  
	while true do  
	   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
	   if not nFindLastIndex then  
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
		break  
	   end  
	   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
	   nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
	   nSplitIndex = nSplitIndex + 1  
	end  
	return nSplitArray  
end  

function createSlaveNote( size, type, index ,param_list )

	print("createSlaveNote", type, index, param_list) 

	local fontName = s_default_font

	local fontSize = size

	local richText = ccui.RichText:create()
	-- richText:ignoreContentAdaptWithSize(false)  
	-- richText:setContentSize(cc.size(400,24))
	-- richText:setAnchorPoint(cc.p(0,1))

	local conf = CONF.SLAVE_NOTE.get(CONF.ESlaveNoteType[type])

	local labels = {}
	local string_len = 0

	for i,v in ipairs(conf["TEXT_"..index]) do

		local texts = Split(v, "|")

		if #texts > 1 then

			-- local text = string.sub(texts[1],1,string.len(texts[1])-1)
			local num = tonumber(string.sub(texts[1],2))

			local str
			if num == 2 then
				str = CONF:getStringValue(CONF.ITEM.get(tonumber(param_list[num])).NAME_ID)
			else
				str = param_list[num]
			end

			local label = ccui.RichElementText:create( i, cc.c3b(texts[2], texts[3], texts[4]), 255, str, fontName, fontSize, 2 )

			string_len = string_len + getStringByte(str)

			table.insert(labels, label)  
		else
			local label = ccui.RichElementText:create( i, cc.c3b(255, 255, 255), 255, CONF:getStringValue(v), fontName, fontSize, 2 )  

			string_len = string_len + getStringByte(CONF:getStringValue(v))

			table.insert(labels, label)

		end
	end

	for i,v in ipairs(labels) do
		richText:pushBackElement(v) 
	end

	return richText,string_len
end

function createSlaveNoteNode( size, type, index ,param_list )
	local richText = createSlaveNote(size, type, index ,param_list)

	local node = require("app.ExResInterface"):getInstance():FastLoad("SlaveScene/content.csb")
	node:getChildByName("confirm"):setString(CONF:getStringValue("yes"))

	node:getChildByName("back"):addClickEventListener(function ( ... )
		node:removeFromParent()
	end)

	node:getChildByName("confirm_button"):addClickEventListener(function ( ... )
		node:removeFromParent()
	end)

	local size = node:getChildByName("text"):getContentSize()

	richText:ignoreContentAdaptWithSize(false)  
	richText:setContentSize(cc.size(size.width,size.height))
	richText:setAnchorPoint(cc.p(0.5,0.5))
	richText:setPosition(cc.p(node:getChildByName("text"):getPosition()))

	node:addChild(richText)

	node:getChildByName("text"):removeFromParent()

	return node

end

function changeSlaveChat( str )

	if not string.find(str,"#") then

		return str

	else
		if string.sub(str, 1,1) ~= "#" then

			return str
		end

	end

	local chat = ""

	
	local strs = {}

	while true do
		if not string.find(str,"#") then
		
			table.insert(strs,str)
			break
		end

		local pos1 = string.find(str,"#")

		local sr = string.sub(str, 1, pos1-1)

		if sr ~= "" then
			table.insert(strs, sr)
		end

		local ssr = string.sub(str,pos1,pos1+8)
		table.insert(strs, ssr)

		str = string.sub(str, pos1+9)
	end

	local labels = {}

	for i=1,#strs/2 do
		local v1 = strs[i*2-1]
		local v2 = strs[i*2]

		local sttr = string.sub(v1,2)

		local s1 = string.sub(sttr,1,2)
		local s2 = string.sub(sttr,3,4)
		local s3 = string.sub(sttr,5,6)
		local s4 = string.sub(sttr,7,8)

		local color1 = tonumber(s1, 16)
		local color2 = tonumber(s2, 16)
		local color3 = tonumber(s3, 16)
		local flags = tonumber(s4)

		-- local label = ccui.RichElementText:create( i, cc.c3b(color1, color2, color3), 255, v2, fontName, fontSize, flags ) 

		table.insert(labels,v2)
	end

	for i,v in ipairs(labels) do
		chat = chat..v
	end

	chat = chat..CONF:getStringValue("visit_button")

	return chat
end

function getAngleByPos(p1,p2)  
	local p = {}  
	p.x = p2.x - p1.x  
	p.y = p2.y - p1.y  
			 
	local r = math.atan2(p.y,p.x)*180/math.pi  
	-- print("夹角[-180 - 180]:",r)  
	return r  
end 


function getNodeIDByGlobalPos( pos )

	local nodeW = g_Planet_Grid_Info.row
	local nodeH = g_Planet_Grid_Info.col

	local row = ((pos.x > 0 and pos.x + 1) or pos.x)  / (nodeW/2)

	if (row > 0 and math.abs(row) < 1) or (row < 0 and math.abs(row) <= 1) then
		row = 0
	else
		if row > 0 then
			row = math.ceil((row - 1)/2)
		else
			row = math.floor((row + 1)/2)
		end
	end

	local col = ((pos.y > 0 and pos.y + 1) or pos.y) / (nodeH/2)


	if (col > 0 and math.abs(col) < 1) or (col < 0 and math.abs(col) <= 1) then
		col = 0
	else
		if col > 0 then
			col = math.ceil((col - 1)/2)
		else
			col = math.floor((col + 1)/2)
		end
	end
	return  CONF.PLANETWORLD.get(row..'_'..col).ID
end

function checkNodeIDByGlobalPos( pos )
	local nodeW = g_Planet_Grid_Info.row
	local nodeH = g_Planet_Grid_Info.col

	local row = ((pos.x > 0 and pos.x + 1) or pos.x)  / (nodeW/2)

	if (row > 0 and math.abs(row) < 1) or (row < 0 and math.abs(row) <= 1) then
		row = 0
	else
		if row > 0 then
			row = math.ceil((row - 1)/2)
		else
			row = math.floor((row + 1)/2)
		end
	end

	local col = ((pos.y > 0 and pos.y + 1) or pos.y) / (nodeH/2)


	if (col > 0 and math.abs(col) < 1) or (col < 0 and math.abs(col) <= 1) then
		col = 0
	else
		if col > 0 then
			col = math.ceil((col - 1)/2)
		else
			col = math.floor((col + 1)/2)
		end
	end
	if not CONF.PLANETWORLD.check(row..'_'..col) then
		return nil
	end
	return  CONF.PLANETWORLD.check(row..'_'..col).ID
end

function checkRewardBeMax( reward_id_list, reward_num_list )

	local g_player = require("app.Player"):getInstance()

	if not g_player:isInited() then
		return 
	end
	
	local check_id_list = {3001,4001,5001,6001}
	for i,v in ipairs(check_id_list) do
		for i2,v2 in ipairs(reward_id_list) do
			if v == v2 then
				if v + v2 > CONF.BUILDING_1.get(g_player:getBuildingInfo(1).level).RES_LIMIT[i] then
					return false
				end
				break
			end
		end
	end

	return true

end

function getNowDateString( time )
	local g_player = require("app.Player"):getInstance()
	
	local now 
	if time then
		now = time
	else
		now = os.time()
	end
	local localTimeZone = os.difftime(now, os.time(os.date("!*t", now)))
	local date = os.date("*t", g_player:getServerTime() - localTimeZone)--计算出服务端时区与客户端时区差值
	local date_str = string.format("year:%d/month:%d/day:%d/hour:%d/min:%d/sec:%d", date.year, date.month, date.day, date.hour, date.min, date.sec)

	return date_str

end

function setTop2Position(marker_node)
	local udcu = require("util.UserDataCmdUtil"):getInstance()
  	local diffSize = udcu:getDiffSize()
  	marker_node:setPosition(diffSize.width,diffSize.height)
end

function isBuildingOpen(building_num,showTip) -- 返回3个bool值，param表开启？，open_icon表开启？，function_open表开启？
	local player = require("app.Player"):getInstance()
	local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()
	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	local tips = require("util.TipsMessage"):getInstance()
	local param_open = false
	local icon_open = false
	local function_open = false
	local param_open_key = CONF.EParamOpenKey
	local function_open_key = CONF.EFunctionOpenKey
	if not param_open_key[building_num] or not function_open_key[building_num] or building_num == 15 then
		print("error:  building_num should 1-16 !!!")
		return false,false,false
	end
	-- param
	local heroLevel
	if param_open_key[building_num] ~= "" then
		local cfg_param = CONF.PARAM.get(param_open_key[building_num]).PARAM
		heroLevel = cfg_param[1]
		if player:getLevel() >= cfg_param[1] and player:getBuildingInfo(1).level >= cfg_param[2] then
			param_open = true
		end
	else
		param_open = true
	end
	-- icon
	local guide 
	if guideManager:getSelfGuideID() ~= 0 then
		guide = guideManager:getSelfGuideID()
	else
		guide = player:getGuideStep()
	end
	for i,v in ipairs(CONF.OPEN_ICON.getIDList()) do
		local conf = CONF.OPEN_ICON.get(v)

		local show = false
		if conf.CONDITION == 1 then
			if guide >= conf.COUNT then
				show = true
			end
		elseif conf.CONDITION == 2 then
			if player:getLevel() >= conf.COUNT then
				show = true
			end
		elseif conf.CONDITION == 4 then
			local id = math.floor( conf.COUNT/100)
			if player:getSystemGuideStep(id) == 0  then
				if math.floor(systemGuideManager:getSelfGuideID()/100) == math.floor(conf.COUNT/100) then
					if systemGuideManager:getSelfGuideID()>=conf.COUNT then
						show = true
					end
				end
			else
				show = true
			end
		elseif conf.CONDITION == 3 then
			if player:getBuildingInfo(1).level >= conf.COUNT then
				show = true
			end
		end
		if show then
			for k1,v1 in ipairs(conf.BUILDING) do
				if (v1-100) == building_num then
					icon_open = true
					break
				end
			end
		end
	end

	-- sys
	if function_open_key[building_num] ~= "" then
		if player:getSystemGuideStep(CONF.FUNCTION_OPEN.get(function_open_key[building_num]).ID) == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() then
			if CONF.FUNCTION_OPEN.get(function_open_key[building_num]).OPEN_GUIDANCE ~= 1 then
				function_open = true
			end
		else
			function_open = true
		end
	else
		function_open = true
	end
	if showTip then
		if not icon_open then
			tips:tips(CONF:getStringValue("function_not_open"))
		else
			if not param_open then
				tips:tips(CONF:getStringValue("levelNum") .. tostring(heroLevel))
			else
				if not function_open then
					local buildingName = "BuildingName_"..building_num
					local str = string.gsub(CONF:getStringValue("not activate"),"#",CONF:getStringValue(buildingName))
					tips:tips(str)
				end
			end
		end
	end

	return param_open,icon_open,function_open
end


function isIconShow(confTag,showTips)
	local player = require("app.Player"):getInstance()
	local tips = require("util.TipsMessage"):getInstance()
	local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()
	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	local buildingTab = {}
	local guide 
	if guideManager:getSelfGuideID() ~= 0 then
		guide = guideManager:getSelfGuideID()
	else
		guide = player:getGuideStep()
	end
	for i,v in ipairs(CONF.OPEN_ICON.getIDList()) do
		local conf = CONF.OPEN_ICON.get(v)
		local show = false
		if conf.CONDITION == 1 then
			if guide >= conf.COUNT then
				show = true
			end
		elseif conf.CONDITION == 2 then
			if player:getLevel() >= conf.COUNT then
				show = true
			end
		elseif conf.CONDITION == 4 then
			local id = math.floor( conf.COUNT/100)
			if player:getSystemGuideStep(id) == 0  then
				if math.floor(systemGuideManager:getSelfGuideID()/100) == math.floor(conf.COUNT/100) then
					if systemGuideManager:getSelfGuideID()>=conf.COUNT then
						show = true
					end
				end
			else
				show = true
			end
		elseif conf.CONDITION == 3 then
			if player:getBuildingInfo(1).level >= conf.COUNT then
				show = true
			end
		end
		-- print("###Lua show: " .. tostring(show))
		if show then
			for i2,v2 in ipairs(conf.BUILDING) do
				local ins = true
				for o,p in ipairs(buildingTab) do
					if v2 == p then
						ins = false
						break
					end
				end
				if ins then
					table.insert(buildingTab,v2)
				end
			end
			
		end
	end
	for k,v in ipairs(buildingTab) do
		if confTag == v then
			return true
		end
	end
	if showTips then
		tips:tips(CONF:getStringValue("function_not_open"))
	end
	return false
end

function TableFindIdFromValue(_table,_Id)
    if Tools.isEmpty(_table) then
        return 0
    end
    for k,v in pairs(_table) do
        if v.id == _Id then
            return k
        end
    end
    return 0
end

function TableFindValue(_table,_v)
    if Tools.isEmpty(_table) then
        return 0
    end
    for k,v in pairs(_table) do
        if v == _v then
            return k
        end
    end
    return 0
end

function SendCDKEY(code)
	print("SendCDKEY")
    local tips = require("util.TipsMessage"):getInstance()
	local gl = require("util.GlobalLoading"):getInstance()
    local ud = cc.UserDefault:getInstance()
	local userid = ud:getStringForKey("user_id")
    local severid = ud:getStringForKey("server_id")
    local qudao_id = GameHandler.handler_c.sdkGetChannelType()
    local pintai = 2
    if device.platform == "android" then
        pintai = 0
    elseif device.platform == "ios" then
        pintai = 1
    end

	local url = string.format("%s?userid=%s&code=%s&sid=%s&pintai=%s&qudao_id=%s", g_cdkey_url, userid, code, severid, pintai, qudao_id)
	print("url",url)

	local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	xhr:open("GET", url)

	local function sendCdkeyCallback()

		if xhr.status >= 200 and xhr.status < 207 then
	 
			print("sendCdkeyCallbackstatus:" .. xhr.statusText)

            local response = xhr.response
			local result = json.decode(response,1)

			if( result == nil ) then
				print("#### Lua GlobalFunc SendCDKEY sendCdkeyCallback result NULL")
			else
                print("sendCdkeyCallback".."errno:"..result.errno.."errmsg:"..result.errmsg)
				if result.errno == 0 then
                    tips:tips(CONF:getStringValue("change_ok"),cc.c4b(0, 255, 0, 255),"PlanetScene/ui/dalaodi.png")
                elseif result.errno == 2 then
                    tips:tips(CONF:getStringValue("code_use"),cc.c4b(255, 0, 0, 255),"PlanetScene/ui/dalaodi.png")
                else
                    tips:tips(CONF:getStringValue("code_error"),cc.c4b(255, 0, 0, 255),"PlanetScene/ui/dalaodi.png")
                end
			end
		else
			print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
		end
		gl:releaseLoading()
		xhr:unregisterScriptHandler()
	end

	xhr:registerScriptHandler(sendCdkeyCallback)
	xhr:send()
	gl:retainLoading()
end

function getTime(str) -- 1999112100（年月日时）
	local nyear = tonumber(string.sub(str,1,4))
	local nmonth = tonumber(string.sub(str,5,6))
	local nday = tonumber(string.sub(str,7,8))
	local nhour = tonumber(string.sub(str,9,10))
	return os.time{year=nyear, month=nmonth, day=nday, hour=nhour,min=0,sec=0}
end

function showGetShip(shiplist,runscene,runlayer)
	if Tools.isEmpty(shiplist) then
		return
	end
    local layer = runlayer:getApp():createView("ShipDevelopScene/DevelopSucessLayer", {data = CONF.AIRSHIP.get(shiplist[1]), type = "lottery"})
	runscene:addChild(layer)
end

function getAllShipList()
    local player = require("app.Player"):getInstance()
    local allShipList = {}
	local shipList = player:getShipList()
	for k,v in pairs(CONF.AIRSHIP.index) do
        local cship = CONF.AIRSHIP.get(v)
		if cship.SHOW_ILLUSTRATED and cship.SHOW_ILLUSTRATED == 1 then
			local ship = {}
            ship.level = 0
			ship.isHave = 0
			ship.shipId = cship.ID
			ship.breakNum = 0
			ship.guid = 0
			ship.haveBluePrintNum = player:getItemNumByID(cship.BLUEPRINT[1])
			ship.needBluePrintNum = cship.BLUEPRINT_NUM[1]
			ship.blueprintId = cship.BLUEPRINT[1]
			ship.type = cship.TYPE
			ship.power = player:getEnemyPower(cship.ID)
            ship.quality = cship.QUALITY
			table.insert(allShipList,ship)
		end
	end
	for k,ship1 in pairs(shipList) do
		for k,ship2 in ipairs(allShipList) do
			if ship1.id == ship2.shipId then
				ship2.isHave = 1
				ship2.guid = ship1.guid
				ship2.breakNum = ship1.ship_break
                ship2.level = ship1.level
				ship2.power = player:calShipFightPower( ship1.guid )
			end 
		end
	end
	return allShipList
end

function GetCurrentShipsPower()
    local player = require("app.Player"):getInstance()
    local power = 0
    local ship_list = player:getForms()
    for i,v in ipairs(ship_list) do
		if v ~= 0 then
			power = power + player:calShipFightPower(v)
		end
	end
    return power
end

function GetAllLevels()
    local alllevels = {}
    local confidlist = CONF.COPY.getIDList()
    for k,v in ipairs(confidlist) do
        local conf = CONF.COPY.get(v)
        for k2,v2 in ipairs(conf.LEVEL_ID) do
            table.insert(alllevels,v2)
        end
    end
    table.sort(alllevels)
    return alllevels
end

function GetGemType(hole)
    local str = "null"
    if hole == 1 then
        str = CONF:getStringValue("Attr_26").."/"..CONF:getStringValue("Attr_29")
    elseif hole == 2 then
        str = CONF:getStringValue("Attr_8").."/"..CONF:getStringValue("Attr_9")
    elseif hole == 3 then
        str = CONF:getStringValue("physical").."/"..CONF:getStringValue("energy")
    elseif hole == 4 then
        str = CONF:getStringValue("Attr_6").."/"..CONF:getStringValue("Attr_7")
    elseif hole == 5 then
        str = CONF:getStringValue("hurt").."/"..CONF:getStringValue("BUFF_M50019")
    elseif hole == 6 then
        str = CONF:getStringValue("any")
    else
    end
    return str
end

function IsFuncOpen(name)
    local player = require("app.Player"):getInstance()
    local str = name .. "_open"
	local heroLevel = CONF.PARAM.get(str).PARAM[1]
	local centreLevel = CONF.PARAM.get(str).PARAM[2]

	if player:getLevel() < heroLevel or player:getBuildingInfo(1).level < centreLevel then
		return false, heroLevel, centreLevel
	end
	return true, heroLevel, centreLevel
end

function cleartable(list)
    if list == nil or #list <= 0 then
        return
    end

    for i = #list, 1, -1 do
        table.remove(list,i)
    end
end

function ShowShipStar(node,ship_break,star)
    if ship_break == nil then
        ship_break = 0
    end
    local isgray = math.modf(tonumber(ship_break)/6)
    local num = math.fmod(tonumber(ship_break),6)
    for i=1,6 do
        local str = "ui_star_gray.png"
        if isgray == 0 then
            if i <= num then
                str = "ui_star_light.png"
--          else
--              str = "ui_star_gray.png"
            end
        elseif isgray == 1 then
            if i <= num then
                str = "ui_star_gold.png"
            else
                str = "ui_star_light.png"
            end
        elseif isgray == 2 then
            if i <= num then
            else
                str = "ui_star_gold.png"
            end
        end
        node:getChildByName(star..i):setVisible(true)
        node:getChildByName(star..i):setTexture("Common/ui/"..str)
    end
end
GlobalFunc_instance.playMusic = playMusic

return GlobalFunc_instance