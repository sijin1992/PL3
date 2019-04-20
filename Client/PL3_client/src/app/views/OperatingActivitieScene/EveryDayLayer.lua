
local EveryDayLayer = class("EveryDayLayer", cc.load("mvc").ViewBase)
local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local player = require("app.Player"):getInstance()


local scheduler = cc.Director:getInstance():getScheduler()

local winSize = cc.Director:getInstance():getWinSize()

local app = require("app.MyApp"):getInstance()

EveryDayLayer.RESOURCE_FILENAME = "OperatingActivitieScene/EveryDayLayer.csb"

EveryDayLayer.NEED_ADJUST_POSITION = true



function EveryDayLayer:onCreate( data )-- {id=,get=bool,new=bool}
	self.data_ = data
end

function EveryDayLayer:onEnter()  
	printInfo("PlanetScene:onEnter()")

end

function EveryDayLayer:onExit()
	
	printInfo("PlanetScene:onExit()")
end

function EveryDayLayer:onEnterTransitionFinish()
	printInfo("EveryDayLayer:onEnterTransitionFinish()",self.data_)
	local center = cc.exports.VisibleRect:center()
	local rn = self:getResourceNode()
	local days = {}
	local function IsInDay(day)
		if Tools.isEmpty(days) then
			table.insert(days,day)
			return false
		end

		for _,v in ipairs(days) do
			if v == day then
				return  true 
			end
		end
		table.insert(days,day)
		return false
	end
	local butlist = {}
	local info = player:getActivity(self.data_)

	local nowday = 0
	if info then
		local date1 = os.date("*t",os.time())
		local date2 = os.date("*t",info.every_day_get_day.start_time)
		nowday = date1.yday - date2.yday 
		if nowday < 0 then
			nowday = nowday + 365 --要算闰年，先不加
		end
		nowday = nowday + 1
	end
	local s = string.gsub(CONF:getStringValue("Activity_description_001"),"#",tostring(nowday))
	rn:getChildByName("bg"):getChildByName("daytext"):setString(s)

	local conftt = CONF.RECHARGE_GIFT_BAG.get(CONF.RECHARGE_GIFT_BAG.index[1])
	s = string.gsub(CONF:getStringValue("Activity_description_002"),"#",tostring(conftt.COST))
	rn:getChildByName("bg"):getChildByName("tishitext"):setString(s)

	local function getTime(str) -- 1999112100（年月日时）
		local nyear = tonumber(string.sub(str,1,4))
		local nmonth = tonumber(string.sub(str,5,6))
		local nday = tonumber(string.sub(str,7,8))
		local nhour = tonumber(string.sub(str,9,10))
		return os.time{year=nyear, month=nmonth, day=nday, hour=nhour,min=0,sec=0}
	end


	local start_time = 0
	local end_time = 0
    local confa = CONF.ACTIVITY.get(self.data_)
	if info ~= nil then
        if confa.START_TIME ~= 0 then
		    start_time = info.start_time
		    end_time = info.end_time
        end
	else
		if confa ~= nil then
            if confa.START_TIME ~= 0 then 
                start_time = getTime(confa.START_TIME)
			    end_time = getTime(confa.END_TIME)
            end
		end
	end

	local dates1 = os.date("*t",start_time)
	local dates2 = os.date("*t",end_time)
	s = string.gsub(CONF:getStringValue("Activity_description_003"),"#1",tostring(dates1.month))
	s = string.gsub(s,"#2",tostring(dates1.day))
	s = string.gsub(s,"#3",tostring(dates2.month))
	s = string.gsub(s,"#4",tostring(dates2.day))
	rn:getChildByName("bg"):getChildByName("timetext"):setString(s)
	if start_time == 0 then
        rn:getChildByName("bg"):getChildByName("timetext"):setString(CONF:getStringValue("forever"))
    end 

	local bLook = false	
	for i=1,CONF.RECHARGE_GIFT_BAG.len do
		local conf = CONF.RECHARGE_GIFT_BAG.get(CONF.RECHARGE_GIFT_BAG.index[i])
		if IsInDay(conf.DAY) == false then
			local node = require("app.views.OperatingActivitieScene.EveryDayNode"):creatNode(conf.ITEM,conf.NUM ,conf.DAY)
			node:setName(i)
			node:setPosition(cc.p(center.x + 30 + (i-2)*280, center.y ))
			table.insert(butlist,{node , conf.ID})

			if info == nil then
				node:getChildByName("ok"):setEnabled(false)
			else
				local time = os.time()
				local date1 = os.date("*t",time)
				local date2 = os.date("*t",info.every_day_get_day.start_time)
				local day = date1.yday - date2.yday
				if day < 0 then
					day = day + 365 --要算闰年，先不加
				end
				day = day + 1
				print("every day",date1.yday , date2.yday)
				print("every day",conf.DAY,info.every_day_get_day.get_day,day,info.every_day_get_day.add_money)
				if bLook == false and info.every_day_get_day.get_day < conf.DAY and day >= conf.DAY and info.every_day_get_day.add_money >= conf.COST then
					bLook = true
					node:getChildByName("ok"):setEnabled(true)
					node:getChildByName("ok"):addClickEventListener(function()
						local strData = Tools.encode("ActivityEveryDayReq", {
							activity_id = self.data_,
							id = conf.ID ,
						})
						GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_EVERYDAY_REQ"),strData)
					end)
				else
					node:getChildByName("ok"):setEnabled(false)
				end
			end
			self:addChild(node)
		end
	end


	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_EVERYDAY_RESP") then
			local proto = Tools.decode("ActivityEveryDayResp",strData)
			if proto.result == 0 then
				if proto.user_sync.activity_list then
					local bLook2 = false
					print("butlist = ",#butlist)
					for i,v in ipairs(butlist) do
						--[[local conf = CONF.RECHARGE_GIFT_BAG.get(v[2])
						local time = os.time()
						local date1 = os.date("*t",time)
						local date2 = os.date("*t",proto.user_sync.activity_list.every_day_get_day.start_time)
						local day = date1.yday - date2.yday
						if day < 0 then
							day = day + 365 --要算闰年，先不加
						end

						print("type",i,type(v[1]),v[2])
						if bLook2 == false and proto.user_sync.activity_list.every_day_get_day.get_day < conf.DAY and day >= conf.DAY and proto.user_sync.activity_list.every_day_get_day.add_money >= conf.COST then
							bLook2 = true
							v[1]:getChildByName("ok"):setEnabled(true)
							v[1]:getChildByName("ok"):addClickEventListener(function()
								local strData = Tools.encode("ActivityEveryDayReq", {
									activity_id = self.data_,
									id = v[2] ,
								})
								GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_EVERYDAY_REQ"),strData)
							end)
						else]]							
							v[1]:getChildByName("ok"):setEnabled(false)
						--end

					end
				else
					print("every day no info ",self.data_,type(info))
				end
			end
		end
	end

	local eventDispatcher = self:getEventDispatcher()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)


	
    rn:getChildByName("closeBtn"):addClickEventListener(function()
		self:removeFromParent()
	end)
    rn:getChildByName("chongzhi"):getChildByName("Text"):setString(CONF:getStringValue("Recharge"))
	rn:getChildByName("chongzhi"):addClickEventListener(function()
		playEffectSound("sound/system/click.mp3")
        local rechargeNode = require("app.views.CityScene.RechargeNode"):create()
		rechargeNode:init(display:getRunningScene(), {index = 1})
		display:getRunningScene():addChild(rechargeNode)
	end)
end

function EveryDayLayer:onExitTransitionStart()
	printInfo("EveryDayLayer:onExitTransitionStart()")
end

return EveryDayLayer