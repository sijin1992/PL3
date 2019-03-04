
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local WangZuoState = class("WangZuoState", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

WangZuoState.RESOURCE_FILENAME = "PlanetScene/wangzuo/stateLayer.csb"

WangZuoState.RUN_TIMELINE = true

WangZuoState.NEED_ADJUST_POSITION = true

WangZuoState.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

WangZuoState.chooseTitle = 1

local schedulerEntry = nil


function WangZuoState:onCreate( data )
	self.data_ = data[1]
end

function WangZuoState:onEnter()

end

function WangZuoState:onExit()
	
end


function WangZuoState:onEnterTransitionFinish()
	printInfo("WangZuoState:onEnterTransitionFinish()")
	local rn = self:getResourceNode()
	rn:getChildByName("title"):setString(CONF:getStringValue("throne_state"))
	local wangzuo_data = self.data_
	local conf = CONF.PLANETCITY.get(wangzuo_data.id)
	local function updateTime()
		local addTime = 0
		local open_confWday = conf.TIME[1]
		local open_confHour = conf.TIME[2]
		if wangzuo_data.status == 1 then
			local first_openTime = wangzuo_data.create_time + CONF.PARAM.get("throne_first_open").PARAM
			if player:getServerTime() < first_openTime then	
				local open_date = os.date("*t",first_openTime)
				if open_date.wday ~= open_confWday then
					local addDay = 0
					local wday1 = open_date.wday - 1
					if wday1 == 0 then
						wday1 = 7 
					end
					local wday2 = open_confWday - 1
					if wday2 == 0 then
						wday2 = 7 
					end
					if wday2 - wday1 > 0 then
						addDay = wday2 - wday1
					else
						addDay = 7 - math.abs(wday2 - wday1)
					end
					addTime = os.time({year = open_date.year, month = open_date.month, day = open_date.day+addDay, hour = open_confHour}) - player:getServerTime()
				else
					if open_date.hour < open_confHour then
						addTime = os.time({year = open_date.year, month = open_date.month, day = open_date.day, hour = open_confHour}) - first_openTime
					else
						addTime = 7*24*3600 - math.abs(os.time({year = open_date.year, month = open_date.month, day = open_date.day, hour = open_confHour}) - first_openTime)
					end
				end
			else
				first_openTime = os.time()
				local open_date = os.date("*t",first_openTime)
				if open_date.wday ~= open_confWday then
					local addDay = 0
					local wday1 = open_date.wday - 1
					if wday1 == 0 then
						wday1 = 7 
					end
					local wday2 = open_confWday - 1
					if wday2 == 0 then
						wday2 = 7 
					end
					if wday2 - wday1 > 0 then
						addDay = wday2 - wday1
					else
						addDay = 7 - math.abs(wday2 - wday1)
					end
					addTime = os.time({year = open_date.year, month = open_date.month, day = open_date.day+addDay, hour = open_confHour}) - player:getServerTime()
				else
					if open_date.hour < open_confHour then
						addTime = os.time({year = open_date.year, month = open_date.month, day = open_date.day, hour = open_confHour}) - first_openTime
					else
						addTime = 7*24*3600 - math.abs(os.time({year = open_date.year, month = open_date.month, day = open_date.day, hour = open_confHour}) - first_openTime)
					end
				end
			end
		elseif wangzuo_data.status == 2 then
			local star_time = wangzuo_data.status_begin_time
			local attack_time = conf.DURATION
			if player:getServerTime() < (attack_time+star_time) then
				addTime = (attack_time+star_time) - player:getServerTime()
			else
				addTime = (attack_time+star_time+CONF.PARAM.get("throne_add_time").PARAM) - player:getServerTime()
			end
		end
		if wangzuo_data.status == 1 then
			rn:getChildByName("name_bg"):getChildByName("title"):setString(CONF:getStringValue("protect_remaining_time")..formatTime(addTime))
		elseif wangzuo_data.status == 2 then
			rn:getChildByName("name_bg"):getChildByName("title"):setString(CONF:getStringValue("contention_remaining_time")..formatTime(addTime))
		end
	end
	updateTime()
	schedulerEntry = scheduler:scheduleScriptFunc(updateTime, 1, false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName('list'),cc.size(0,1), cc.size(475,85))
	rn:getChildByName("list"):setScrollBarEnabled(false)
	rn:getChildByName("choose"):getChildByName("text1"):setString(CONF:getStringValue("conqueror"))
	rn:getChildByName("choose"):getChildByName("text2"):setString(CONF:getStringValue("hall_of_fame"))
	rn:getChildByName("no_overcome"):setString(CONF:getStringValue("no_conqueror"))
	rn:getChildByName("overcome"):setVisible(false)
	if self.chooseTitle == 1 then
		rn:getChildByName("no_overcome"):setVisible(true)
	end
	if self.data_.groupid and self.data_.groupid ~= "" then
		rn:getChildByName("no_overcome"):setVisible(false)
		rn:getChildByName("overcome"):setVisible(true)
		rn:getChildByName("overcome"):getChildByName("star_icon"):setTexture("StarLeagueScene/ui/icon_star_0"..self.data_.temp_info.icon_id..".png")
		rn:getChildByName("overcome"):getChildByName("star_name"):setString(self.data_.temp_info.nickname)
		rn:getChildByName("overcome"):getChildByName("role_name"):setString(self.data_.temp_info.leader_name)
	else
		rn:getChildByName("overcome"):getChildByName("star_icon"):setVisible(false)
		rn:getChildByName("overcome"):getChildByName("star_name"):setVisible(false)
		if self.data_.user_name then
			rn:getChildByName("no_overcome"):setVisible(false)
			rn:getChildByName("overcome"):setVisible(true)
			rn:getChildByName("overcome"):getChildByName("role_name"):setString(self.data_.user_info.nickname)
		end
	end
	if Tools.isEmpty(self.data_.user_info) == false then
		rn:getChildByName("overcome"):getChildByName("role"):getChildByName("role_icon"):setTexture("HeroImage/"..self.data_.user_info.icon_id..".png")
	end
	if wangzuo_data.status == 2 then
		rn:getChildByName("overcome"):getChildByName("star_icon"):setVisible(false)
		rn:getChildByName("overcome"):getChildByName("star_name"):setVisible(false)
		rn:getChildByName("overcome"):getChildByName("role_name"):setVisible(false)
		rn:getChildByName("overcome"):getChildByName("role"):setVisible(false)
		rn:getChildByName("no_overcome"):setVisible(true)
	end
	rn:getChildByName("choose"):getChildByName("line1"):setVisible(true)
	rn:getChildByName("choose"):getChildByName("line2"):setVisible(false)
	rn:getChildByName("choose"):getChildByName("bg1"):addClickEventListener(function()
		if self.chooseTitle == 1 then
			return
		end
		self.svd_:clear()
		self.chooseTitle = 1
		rn:getChildByName("choose"):getChildByName("bg1"):loadTexture("PlanetScene/wangzuo/ui/title_light.png")
		rn:getChildByName("choose"):getChildByName("bg2"):loadTexture("PlanetScene/wangzuo/ui/title_black.png")
		rn:getChildByName("choose"):getChildByName("line1"):setVisible(true)
		rn:getChildByName("choose"):getChildByName("line2"):setVisible(false)
		rn:getChildByName("choose"):getChildByName("text1"):setTextColor(cc.c4b(32,32,32,255))
		rn:getChildByName("choose"):getChildByName("text2"):setTextColor(cc.c4b(127,127,127,255))
		rn:getChildByName("overcome"):setVisible(true)
		rn:getChildByName("no_overcome"):setVisible(true)
		if self.data_.groupid and self.data_.groupid ~= "" then
			rn:getChildByName("no_overcome"):setVisible(false)
		else
			if self.data_.user_name then
				rn:getChildByName("no_overcome"):setVisible(false)
			end
		end
		if wangzuo_data.status == 2 then
			rn:getChildByName("no_overcome"):setVisible(true)
		end
		end)
	rn:getChildByName("choose"):getChildByName("bg2"):addClickEventListener(function()
		if self.chooseTitle == 2 then
			return
		end
		self.chooseTitle = 2
		rn:getChildByName("choose"):getChildByName("bg2"):loadTexture("PlanetScene/wangzuo/ui/title_light.png")
		rn:getChildByName("choose"):getChildByName("bg1"):loadTexture("PlanetScene/wangzuo/ui/title_black.png")
		rn:getChildByName("choose"):getChildByName("line2"):setVisible(true)
		rn:getChildByName("choose"):getChildByName("line1"):setVisible(false)
		rn:getChildByName("choose"):getChildByName("text1"):setTextColor(cc.c4b(127,127,127,255))
		rn:getChildByName("choose"):getChildByName("text2"):setTextColor(cc.c4b(32,32,32,255))
		rn:getChildByName("overcome"):setVisible(false)
		rn:getChildByName("no_overcome"):setVisible(false)
		local strData = Tools.encode("PlanetWangZuoTitleReq", {
				type = 4,
			})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PANET_WANGZUO_TITLE_REQ"),strData)
		gl:retainLoading()
		end)
	rn:getChildByName("Button_wen"):addClickEventListener(function()
		local node =  createIntroduceNode(CONF:getStringValue("throne_explain"))
		self:addChild(node)
		end)
	rn:getChildByName("close"):addClickEventListener(function()
		self:getApp():removeTopView()
		end)

	rn:getChildByName("list"):setScrollBarEnabled(false)
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName('list'),cc.size(5,10), cc.size(475,86))
	local function recvMsg()
		print("WangZuoState:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PANET_WANGZUO_TITLE_RESP") then

			local proto = Tools.decode("PLanetWangZuoTitleResp",strData)
			print("PLanetWangZuoTitleResp result",proto.result, proto.type)
			gl:releaseLoading()
			if proto.result == 0 then
				if proto.type == 4 then
					self.svd_:clear()
					if Tools.isEmpty(proto.occupy_list) == false then
						for k,v in ipairs(proto.occupy_list.occupy_list) do
							local node = cc.CSLoader:createNode("PlanetScene/wangzuo/stateNode.csb")
							node:getChildByName("head"):setTexture("HeroImage/"..v.info.icon_id..".png")
							node:getChildByName("des3"):setString(CONF:getStringValue("take_office_and")..os.date("%Y/%m/%d",v.create_time))
							local sss = string.gsub(CONF:getStringValue("a_few_lords") ,"#" ,k)
							node:getChildByName("des1"):setString(sss)
							local str = ""
							if v.info.group_nickname and v.info.group_nickname ~= "" then
								str = "["..v.info.group_nickname.."]"
							end
							str = str ..v.info.nickname
							node:getChildByName("des2"):setString(str)
							self.svd_:addElement(node)
						end
					end
				end
			else
				if proto.result == 1 and proto.type == 4 then
					self.svd_:clear()
					rn:getChildByName("no_overcome"):setVisible(true)
				end
        	end
			
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function WangZuoState:onExitTransitionStart()

	printInfo("WangZuoState:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end

return WangZuoState