
local AdvancedGiftScene = class("AdvancedGiftScene", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local scheduleclock

AdvancedGiftScene.RESOURCE_FILENAME = "OperatingActivitieScene/AdvancedGiftScene.csb"

AdvancedGiftScene.NEED_ADJUST_POSITION = true

AdvancedGiftScene.isover = false

AdvancedGiftScene.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function AdvancedGiftScene:OnBtnClick(event)
	if event.name == 'ended' then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			self:getApp():popView()
		end
	end
end

function AdvancedGiftScene:onCreate(data)
	self._data = data

    self.AdvancedData = nil
    if player.data_.user_info.next_gift_bag_data then
        self.AdvancedData = player.data_.user_info.next_gift_bag_data
    end
    self:GetConf()
end

function AdvancedGiftScene:GetConf()
    self.ConfList = {}
    local confidlist = CONF.RECHARGE.getIDList()
	for k,v in ipairs(confidlist) do
		local conf = CONF.RECHARGE.get(v)
        local productId = conf.PRODUCT_ID
        if string.find(productId,"cost") ~= nil then
            table.insert(self.ConfList,conf)
        end
    end

    self.HandGiftList = {}
    local handidlist = CONF.NEWHANDGIFTBAG.getIDList()
    for k,v in ipairs(self.ConfList)do
        for k2,v2 in ipairs(handidlist) do
		    local conf = CONF.NEWHANDGIFTBAG.get(v2)
            if conf.ID == v.GIFT_ID then
                table.insert(self.HandGiftList,conf)
                break
            end
        end
    end

    self.RewardList = {}
    local rewardidlist = CONF.REWARD.getIDList()
    for k,v in ipairs(self.HandGiftList)do
        for k2,v2 in ipairs(rewardidlist) do
		    local conf = CONF.REWARD.get(v2)
            if conf.ID == v.REWARD[1] then
                table.insert(self.RewardList,conf)
                break
            end
        end
    end
end

function AdvancedGiftScene:onEnter()
	printInfo("AdvancedGiftScene:onEnter()")
end

function AdvancedGiftScene:onEnterTransitionFinish()
    printInfo("LuckyWheelLayer:onEnterTransitionFinish()")
    self:ShowUI()
    self:Clock()
    self:Monitor()
end

function AdvancedGiftScene:ShowUI()
    local rn = self:getResourceNode()
    self.gift_list = require("util.ScrollViewDelegate"):create(rn:getChildByName("giftlist"),cc.size(5,5), cc.size(455,600))
    rn:getChildByName("giftlist"):setScrollBarEnabled(false)

    self.gift_list:clear()
    for k,v in ipairs(self.ConfList)do
        local giftnode = require("app.ExResInterface"):getInstance():FastLoad('OperatingActivitieScene/AdvancedNode2.csb')
        self.gift_list:addElement(giftnode)
    end

    self.shownum = #self.AdvancedData.next_gift_bag + 1
    if self.shownum > #self.ConfList then
        self.shownum = #self.ConfList
    end
    for i=1,self.shownum do
        local giftnode = self.gift_list.elementList_[i].obj
        giftnode:getChildByName("Backcard"):setVisible(false)
        if i == 1 then
            giftnode:getChildByName("jiantou_2"):setVisible(false)
        else
            local arrow = cc.Director:getInstance():getTextureCache():addImage("OperatingActivitieScene/ui/jiantou.png")
            giftnode:getChildByName("jiantou_2"):setTexture(arrow)
        end
        local opennode = self:CreateOpenNode(i)
        opennode:setName("open"..i)
        giftnode:addChild(opennode)
        opennode:setPosition(giftnode:getChildByName("Backcard"):getPositionX() ,giftnode:getChildByName("Backcard"):getPositionY())
        if i <= #self.AdvancedData.next_gift_bag then
            opennode:getChildByName("buy"):setEnabled(false)
        end
    end
end

function AdvancedGiftScene:CreateOpenNode(index)
    local conf = self.RewardList[index]
    local opennode = require("app.ExResInterface"):getInstance():FastLoad('OperatingActivitieScene/AdvancedNode.csb')

    local price = tostring(self.ConfList[index].RECHARGE_0)
    local len = string.len(price)
    local numlist = {}
    for i=1,len do
        numlist[i]= string.sub(price,i,i)
    end
    if #numlist == 1 then
        opennode:getChildByName("pic_num1"):setVisible(false)
        opennode:getChildByName("pic_num3"):setVisible(false)
        opennode:getChildByName("pic_num2"):loadTexture("OperatingActivitieScene/ui/"..numlist[1]..".png")
    elseif #numlist == 2 then
        opennode:getChildByName("pic_num3"):setVisible(false)
        opennode:getChildByName("pic_num1"):loadTexture("OperatingActivitieScene/ui/"..numlist[1]..".png")
        opennode:getChildByName("pic_num2"):loadTexture("OperatingActivitieScene/ui/"..numlist[2]..".png")
    elseif #numlist == 3 then
        opennode:getChildByName("pic_num1"):loadTexture("OperatingActivitieScene/ui/"..numlist[1]..".png")
        opennode:getChildByName("pic_num2"):loadTexture("OperatingActivitieScene/ui/"..numlist[2]..".png")
        opennode:getChildByName("pic_num3"):loadTexture("OperatingActivitieScene/ui/"..numlist[3]..".png")
    end

    local box = cc.Director:getInstance():getTextureCache():addImage("OperatingActivitieScene/ui/".."gift"..index..".png")
    opennode:getChildByName("Sprite_gift"):setTexture(box)

    local item_list = require("util.ScrollViewDelegate"):create(opennode:getChildByName("list"),cc.size(5,10), cc.size(300,80))
    opennode:getChildByName("list"):setScrollBarEnabled(false)
    for k,v in ipairs(conf.ITEM)do
        local itemconf = CONF.ITEM.get(v)
        local itemnode = require("app.ExResInterface"):getInstance():FastLoad('OperatingActivitieScene/AdvancedItemNode.csb')
        local item = require("util.ItemNode"):create():init(v)
        itemnode:getChildByName("num"):setString(formatRes(conf.COUNT[k]))
        itemnode:getChildByName("name"):setString(CONF:getStringValue(itemconf.NAME_ID))
        itemnode:getChildByName("item"):getChildByName("icon"):setVisible(false)
        itemnode:getChildByName("item"):addChild(item)
        item:setPosition(0,0)
        item_list:addElement(itemnode)
        if k == 1 then
            itemnode:getChildByName("line"):setVisible(false)
        end
    end

    opennode:getChildByName("buy"):getChildByName("price"):setString(CONF:getStringValue("coin_sign")..tostring(self.ConfList[index].RECHARGE_0))
    opennode:getChildByName("buy"):addClickEventListener(function()
		print("device.platform  ",device.platform)
        if self.isover then
            tips:tips(CONF:getStringValue("activity")..CONF:getStringValue("end"))
        else
		    if device.platform == "ios" or device.platform == "android" then
                if(device.platform == "android" and require("util.ExSDK"):getInstance():IsQuickSDK() ) then
				    require("util.ExSDK"):getInstance():SDK_REQ_QuickPay(self.ConfList[index])
			    else
			        GameHandler.handler_c.payStart(self.ConfList[index].PRODUCT_ID)
			        gl:retainLoading()
                end
		    end
        end
	end)
    return opennode
end

function AdvancedGiftScene:Clock()
    local rn = self:getResourceNode()
	local starTime = getTime(tostring(CONF.ACTIVITY.get(self._data).START_TIME))
	local endTime = getTime(tostring(CONF.ACTIVITY.get(self._data).END_TIME))
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

    if scheduleclock == nil then
        scheduleclock = scheduler:scheduleScriptFunc(timer,0.033,false)
    end
end

function AdvancedGiftScene:Monitor()
    local function recvMsg()
        local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SDK_PAY_CALLBACK") then
			gl:releaseLoading()
			local output = json.decode(strData,1)
			if output.result == 0 then
                self.AdvancedData = player.data_.user_info.next_gift_bag_data
                self:Updata()
                cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("ResUpdated")
			    cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("MoneyUpdated")
                local items = {}
				for k,v in pairs(output.item_list) do
					table.insert(items,{id = v.id,num = v.num})
				end
				local node = require("util.RewardNode"):createGettedNodeWithList(items)
				tipsAction(node)
				node:setPosition(cc.exports.VisibleRect:center())
				self:addChild(node)
			else
				tips:tips(CONF:getStringValue("buy_error"))
			end
		end
    end
    local eventDispatcher = self:getEventDispatcher()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function AdvancedGiftScene:Updata()
    local giftnode = self.gift_list.elementList_[#self.AdvancedData.next_gift_bag].obj
    dump(#self.AdvancedData.next_gift_bag)
    giftnode:getChildByName("open"..#self.AdvancedData.next_gift_bag):getChildByName("buy"):setEnabled(false)

    self.shownum = #self.AdvancedData.next_gift_bag + 1
    if self.shownum > #self.ConfList then
        self.shownum = #self.ConfList
        return
    end
    local opennode = self:CreateOpenNode(self.shownum)
    local backnode = self.gift_list.elementList_[self.shownum].obj
    backnode:getChildByName("Backcard"):setVisible(false)
    local arrow = cc.Director:getInstance():getTextureCache():addImage("OperatingActivitieScene/ui/jiantou.png")
    backnode:getChildByName("jiantou_2"):setTexture(arrow)
    opennode:setName("open"..self.shownum)
    backnode:addChild(opennode)
    opennode:setPosition(backnode:getChildByName("Backcard"):getPositionX() ,backnode:getChildByName("Backcard"):getPositionY())
end

function AdvancedGiftScene:onExitTransitionStart()
    printInfo("AdvancedGiftScene:onExitTransitionStart()")

    local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

    if scheduleclock ~= nil then
        scheduler:unscheduleScriptEntry(scheduleclock)
        scheduleclock = nil
    end
end

function AdvancedGiftScene:onExit()
	printInfo("AdvancedGiftScene:onExit()")
end

return AdvancedGiftScene