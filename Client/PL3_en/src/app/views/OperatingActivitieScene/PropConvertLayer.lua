
local PropConvertLayer = class("PropConvertLayer", cc.load("mvc").ViewBase)
local player = require("app.Player"):getInstance()
local gl = require("util.GlobalLoading"):getInstance()
local tips = require("util.TipsMessage"):getInstance()
local scheduler = cc.Director:getInstance():getScheduler()

PropConvertLayer.RESOURCE_FILENAME = "OperatingActivitieScene/PropConvertLayer.csb"
PropConvertLayer.NEED_ADJUST_POSITION = true
PropConvertLayer.conf_list = {}
PropConvertLayer.converttime_list = {}
PropConvertLayer.isover = false

function PropConvertLayer:onCreate( data )-- {id=,get=bool,new=bool}
	self.data_ = data
    local info = player:getActivity(self.data_)
    if info then
        self.converttime_list = info.change_item_data.item_list
    end
    self.conf_list = {}
    for i=1,CONF.CHANGEITEM.len do
        if tonumber(CONF.CHANGEITEM[i].TYPE) == 2 then
            table.insert(self.conf_list,CONF.CHANGEITEM[i])
        end
    end
end

function PropConvertLayer:onEnter()  
	printInfo("PropConvertLayer:onEnter()")

end

function PropConvertLayer:onEnterTransitionFinish()
	printInfo("PropConvertLayer:onEnterTransitionFinish()")
    self:ShowUI()
    self:Monitor()
    self:clock()
end

function PropConvertLayer:ShowUI()
    local rn = self:getResourceNode()
    rn:getChildByName("close"):addClickEventListener(function()
		self:removeFromParent()
	end)
    if Tools:isEmpty(self.conf_list) then
        return
    end
    self.convertlist = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(10,10), cc.size(898,116.00))
    rn:getChildByName("list"):setScrollBarEnabled(false)
    for k,v in ipairs(self.conf_list) do
        local time_num = self:SearchIDForTime(v.ID)
        local node_conf = require("app.views.OperatingActivitieScene.PropConvertNode"):create():init({time = time_num ,conf = v ,isOperat = true})
        node_conf:getChildByName("bg"):getChildByName("bt"):addClickEventListener(function ( sender )
            if self.isover then
                tips:tips(CONF:getStringValue("activity")..CONF:getStringValue("end"))
            else
                local strData = Tools.encode("ActivityExchangeItemReq", {
			    id = tonumber(v.ID)
		        })
		        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_EXCHANGE_ITEM_REQ"),strData)
            end
	    end)
        self.convertlist:addElement(node_conf)
    end
end

function PropConvertLayer:SearchIDForTime(id)
    local time = 0
    for k,v in pairs(self.converttime_list) do
        if v.key == id then
            time = v.value
        end
    end
    return time
end

function PropConvertLayer:Monitor()
    local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_EXCHANGE_ITEM_RESP") then
			local proto = Tools.decode("ActivityExchangeItemResp",strData)
			if proto.result == 0 then
                tips:tips(CONF:getStringValue("change_ok"))
                local timelist
            	for k,v in ipairs(proto.user_sync.activity_list) do
		            if self.data_ == v.id then
			            timelist = v.change_item_data.item_list
		            end
	            end
                if timelist ~= nil and Tools:isEmpty(timelist) == false then
                    self.converttime_list = timelist
                    self:UpdataInfo()
                end
			end
		end
	end
    local eventDispatcher = self:getEventDispatcher()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function PropConvertLayer:clock()
    local rn = self:getResourceNode()
	local starTime = getTime(tostring(CONF.ACTIVITY.get(self.data_).START_TIME))
	local endTime = getTime(tostring(CONF.ACTIVITY.get(self.data_).END_TIME))
    local function timer()
        if os.time() >= starTime and os.time() <= endTime then
            if self.isover then
                self.isover = false
            end
            rn:getChildByName("time"):setString(formatTime(endTime-os.time()))
        else
            if not self.isover then
                self.isover = true
            end
            rn:getChildByName("time"):setString(CONF:getStringValue("activity")..CONF:getStringValue("end"))
	    end
    end

    if self.schedulerInfo == nil then
        self.schedulerInfo = scheduler:scheduleScriptFunc(timer,0.033,false)
    end
end

function PropConvertLayer:UpdataInfo()
    printInfo("PropConvertLayer:UpdataInfo()")

    for k,v in ipairs(self.convertlist.elementList_) do
        local num = tonumber(self.conf_list[k].LIMIT) - tonumber(self:SearchIDForTime(self.conf_list[k].ID))
        v.obj:getChildByName("bg"):getChildByName("num"):setString(tostring(num))
        local hasitem = true
        for k2,v2 in ipairs(self.conf_list[k].COST_ITEM) do
            if player:getItemNumByID(v2) < self.conf_list[k].COST_NUM[k2] then
                hasitem = false
                break
            end
        end

        if num <= 0 then
            v.obj:getChildByName("bg"):getChildByName("num"):setColor(cc.c3b(255,0,0))
            v.obj:getChildByName("bg"):getChildByName("bt"):setEnabled(false)
        else
            v.obj:getChildByName("bg"):getChildByName("num"):setColor(cc.c3b(0,255,0))
            if hasitem then
                v.obj:getChildByName("bg"):getChildByName("bt"):setEnabled(true)
            else
                v.obj:getChildByName("bg"):getChildByName("bt"):setEnabled(false)
            end
        end
    end
end

function PropConvertLayer:onExitTransitionStart()
	printInfo("PropConvertLayer:onExitTransitionStart()")
    local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

function PropConvertLayer:onExit()
	printInfo("PropConvertLayer:onExit()")
    if self.schedulerInfo ~= nil then
	    scheduler:unscheduleScriptEntry(self.schedulerInfo)
	    self.schedulerInfo = nil
	end
end

return PropConvertLayer