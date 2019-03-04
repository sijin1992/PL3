
local LuckyWheelLayer = class("LuckyWheelLayer", cc.load("mvc").ViewBase)
local app = require("app.MyApp"):getInstance()
local player = require("app.Player"):getInstance()
local gl = require("util.GlobalLoading"):getInstance()
local tips = require("util.TipsMessage"):getInstance()
local scheduler = cc.Director:getInstance():getScheduler()
local scheduleID,scheduleclock
local isturn = false

LuckyWheelLayer.RESOURCE_FILENAME = "OperatingActivitieScene/LuckyWheelLayer.csb"
LuckyWheelLayer.NEED_ADJUST_POSITION = true
LuckyWheelLayer.conf = nil
LuckyWheelLayer.Startindex = 1
LuckyWheelLayer.StartSpeed = 0.16
LuckyWheelLayer.Startnum = 4
LuckyWheelLayer.ProcessSpeed = 0.08
LuckyWheelLayer.Processnum = 10
LuckyWheelLayer.ProcessSpeed2 = 0.04
LuckyWheelLayer.Processnum2 = 50
LuckyWheelLayer.EndSpeed = 0.16
LuckyWheelLayer.Endnum = 60
LuckyWheelLayer.Endindex = 1
LuckyWheelLayer.getship = {}
LuckyWheelLayer.isover = false

function LuckyWheelLayer:onCreate( data )-- {id=,get=bool,new=bool}
	self.data_ = data
    local info = player:getActivity(self.data_)
    if info then
        self.LuckyData = info.turntable_data
    end
    self.conf = CONF.ACTIVITY_TURNTABLE[1]
end

function LuckyWheelLayer:onEnter()  
	printInfo("LuckyWheelLayer:onEnter()")
end

function LuckyWheelLayer:onExit()
	printInfo("LuckyWheelLayer:onExit()")
end

function LuckyWheelLayer:onEnterTransitionFinish()
	printInfo("LuckyWheelLayer:onEnterTransitionFinish()")
    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_ACTIVITY_LIST_REQ")," ")
    self:ShowUI()
    self:Clock()
    self:Monitor()
end

function LuckyWheelLayer:ShowUI()
    local rn = self:getResourceNode()
    local wheel = rn:getChildByName("wheel")
    local right = rn:getChildByName("right")

    if Tools:isEmpty(self.conf_list) then
        return
    end
    -- Wheel
    for k,v in ipairs(self.conf.ITEM) do
        local itemNode = wheel:getChildByName("Item"..k)
        local item = require("util.ItemNode"):create():init(v, formatRes(self.conf.NUM[k]))
        itemNode:addChild(item)
        item:setPosition(0,0)
    end
    wheel:getChildByName("turn"):getChildByName("price"):setString(self.conf.SINGLE)
    -- Right
    right:getChildByName("Text_des1"):setString(CONF:getStringValue("Turntable_GZ_01"))
    right:getChildByName("Text_des3"):setString(CONF:getStringValue("Turntable_GZ_03"))
    local strlist = Split(CONF:getStringValue("Turntable_GZ_02"),"#")
    local str = strlist[1]..self.conf.COST_NUM..strlist[2]
    right:getChildByName("Text_des2"):setString(str)
    self:SetUserDataToUI()
    -- ClickEvent
    rn:getChildByName("close"):addClickEventListener(function()
		self:removeFromParent()
	end)
    wheel:getChildByName("turn"):addClickEventListener(function ( sender )
        if not isturn then
            if self.isover then
                tips:tips(CONF:getStringValue("activity")..CONF:getStringValue("end"))
            else
                if self:GetTurnNum() > 0 then
                    if player:getMoney() >= self.conf.SINGLE then
                        isturn = true
                        local strData = Tools.encode("ActivityTurntableReq", {
		                    activity_id = tonumber(self.data_),
                            id = 1
		                })
		                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_TURNTABLE_REQ"),strData)
                    else
                        tips:tips(CONF:getStringValue("no enought credit"))
                    end
                else
                    tips:tips(CONF:getStringValue("times_not_enought"))
                end
            end
        end
	end)
    right:getChildByName("recharge"):addClickEventListener(function()
        playEffectSound("sound/system/click.mp3")
        local rechargeNode = require("app.views.CityScene.RechargeNode"):create()
		rechargeNode:init(display:getRunningScene(), {index = 1})
		display:getRunningScene():addChild(rechargeNode)
    end)
end

function LuckyWheelLayer:GetTurnNum()
    local turnnum = CONF.PARAM.get("turntable_add_num").PARAM[1]
    if self.LuckyData and self.LuckyData.turntable_num then
        turnnum = self.LuckyData.turntable_num
    end
    return turnnum
end

function LuckyWheelLayer:SetUserDataToUI()
    local rn = self:getResourceNode()
    local right = rn:getChildByName("right")
    local turnnum = self:GetTurnNum()
    local addmoney = 0
    if self.LuckyData and self.LuckyData.add_money then
        addmoney = self.LuckyData.add_money
    end
    right:getChildByName("right_title2"):getChildByName("num"):setString(turnnum)
    right:getChildByName("totalnum"):setString(addmoney)
    right:getChildByName("money"):setString(player:getMoney())
end

function LuckyWheelLayer:Clock()
    local rn = self:getResourceNode()
	local starTime = getTime(tostring(CONF.ACTIVITY.get(self.data_).START_TIME))
	local endTime = getTime(tostring(CONF.ACTIVITY.get(self.data_).END_TIME))
    local function timer()
        if os.time() >= starTime and os.time() <= endTime then
            if self.isover then
                self.isover = false
            end
            rn:getChildByName("right"):getChildByName("right_title1"):getChildByName("time"):setString(formatTime(endTime-os.time()))
	    else
            if not self.isover then
                self.isover = true
            end
            rn:getChildByName("right"):getChildByName("right_title1"):getChildByName("time"):setString(CONF:getStringValue("activity")..CONF:getStringValue("end"))
        end
    end

    if scheduleclock == nil then
        scheduleclock = scheduler:scheduleScriptFunc(timer,0.033,false)
    end
end

function LuckyWheelLayer:Monitor()
    local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_TURNTABLE_RESP") then
			local proto = Tools.decode("ActivityTurntableResp",strData)
            print("------------LuckyWheelreceive",proto.result)
			if proto.result == 0 then
                self.lastindex = self.Endindex
                self.Endindex = proto.index
                self.getitemlist = {}
                if Tools.isEmpty(proto.get_item_list) then
                else
                    for k,v in ipairs(proto.get_item_list) do
                        table.insert(self.getitemlist, {id = v.key, num = v.value})
                    end
                end
                self.getship = {}
                if Tools.isEmpty(proto.user_sync.ship_list) then
                else
                    self.getship = proto.user_sync.ship_list
                end

                cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("MoneyUpdated")
                self:Turn(self.Endindex)
			end
         elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_GET_ACTIVITY_LIST_RESP") then
            local proto = Tools.decode("GetActivityListResp",strData)
            if proto.result ~= 0 then
                print("GetActivityListResp error", proto.result)
            else
                player:setPlayerActivityIDList(proto.id_list)
                local info = player:getActivity(self.data_)
                if info then
                    self.LuckyData = info.turntable_data
                end
                self:SetUserDataToUI()
                cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("updateCityActivityPoint")
            end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
    local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

    self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_ACTIVITY_LIST_REQ")," ")
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)
end

function LuckyWheelLayer:Turn(index)
    local rn = self:getResourceNode()
    local wheel = rn:getChildByName("wheel")
    local num = 1
    local function move(_last ,_next ,movespeed)
        local mtime = 0
        local function moveTimer(dt)
            mtime = mtime + dt
            if mtime >= movespeed and wheel:getChildByName("Item".._last) then
                wheel:getChildByName("Item".._last):getChildByName("selectbg"):setVisible(false)
                wheel:getChildByName("Item".._next):getChildByName("selectbg"):setVisible(true)
                scheduler:unscheduleScriptEntry(scheduleID)
                num = num + 1
                local _next2 = _next+1
                if _next2 >= 11 then
                    _next2 = 1
                end
                if num <= self.Startnum then
                    move(_next ,_next2 ,self.StartSpeed)
                elseif num <= self.Processnum then
                    move(_next ,_next2 ,self.ProcessSpeed)
                elseif num <= self.Processnum2 then
                    move(_next ,_next2 ,self.ProcessSpeed2)
                elseif num < (self.Endnum + index ) then
                    move(_next ,_next2 ,self.EndSpeed)
                else
                    if self.getitemlist then
                        isturn = false
                        self:ShowGetItem()
                    end
                end
            end
        end
        scheduleID = scheduler:scheduleScriptFunc(function(dt) moveTimer(dt) end , 0.033 ,false)
    end
    wheel:getChildByName("Item"..self.lastindex):getChildByName("selectbg"):setVisible(false)
    wheel:getChildByName("Item1"):getChildByName("selectbg"):setVisible(true)
    move(self.Startindex ,self.Startindex + 1 ,self.StartSpeed)
end

function LuckyWheelLayer:ShowGetItem()
    if not Tools.isEmpty(self.getitemlist) then
        local node = require("util.RewardNode"):createGettedNodeWithList(self.getitemlist, nil, nil)
		tipsAction(node)
		node:setPosition(cc.exports.VisibleRect:center())
		display:getRunningScene():addChild(node)
    end
    if not Tools.isEmpty(self.getship) then
        local showship = {}
        for k,v in ipairs(self.getship)do
    	    if CONF.ITEM.get(v.id).TYPE == 18 then
			    table.insert(showship, CONF.ITEM.get(v.id).KEY)
		    end
            showGetShip(showship,display:getRunningScene(),self)
            showship = {}
        end
    end
end

function LuckyWheelLayer:onExitTransitionStart()
	printInfo("LuckyWheelLayer:onExitTransitionStart()")

    if isturn then
        isturn = false
        self:ShowGetItem()
    end

    local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.moneyListener_)

    if scheduleID ~= nil then
        scheduler:unscheduleScriptEntry(scheduleID)
        scheduleID = nil
    end

    if scheduleclock ~= nil then
        scheduler:unscheduleScriptEntry(scheduleclock)
        scheduleclock = nil
    end
end

return LuckyWheelLayer