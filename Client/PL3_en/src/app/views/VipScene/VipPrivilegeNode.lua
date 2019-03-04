
local VipPrivilegeNode = class('VipPrivilegeNode',cc.load('mvc').ViewBase)
VipPrivilegeNode.RESOURCE_FILENAME = 'VipScene/VipPrivilegeNode.csb'

local player = require('app.Player'):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

VipPrivilegeNode.itemtable = {}

function VipPrivilegeNode:createNode(Viplevel)

end

function VipPrivilegeNode:onEnter()
    printInfo("VipPrivilegeNode:onEnter()")
end

function VipPrivilegeNode:onEnterTransitionFinish()

end

function VipPrivilegeNode:init(scene,data)      -- self.data_.index : 1 充值界面已存在  2 充值界面不存在
    self.scene_ = scene
    self.data_ = data
    self.award_list = player:getVipAwardList()
    self.pack_list = player:getVipPackList()
    --close
    local rn = self:getResourceNode()

    rn:getChildByName("close"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/return.mp3")
		self:removeFromParent()
	end)
    --recharge
    rn:getChildByName("recharge"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
        if self.data_.index == 2 then
            local rechargeNode = require("app.views.CityScene.RechargeNode"):create()
		    rechargeNode:init(display:getRunningScene(), {index = 1})
		    display:getRunningScene():addChild(rechargeNode)
        end
        self:removeFromParent()
	end)

    --Info
    local max_level = #CONF.VIP.getIDList() - 1
    local VipLevel = player:getVipLevel()
    self:showVipInfo(VipLevel)

    self.showLevel = VipLevel
    local function LRBtIsShow(showLevel)
        local b = true
        if showLevel <= 0 then 
            rn:getChildByName("left"):setVisible(false)
            if showLevel < 0 then
                b = false
            end
        elseif showLevel >= max_level then
            rn:getChildByName("right"):setVisible(false)
            if showLevel > max_level then
                b = false
            end
        else
            rn:getChildByName("left"):setVisible(true)
            rn:getChildByName("right"):setVisible(true)
        end
        return b
    end
    LRBtIsShow(self.showLevel)

    rn:getChildByName("left"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
        self.showLevel = self.showLevel - 1
        if LRBtIsShow(self.showLevel) then
            self:restInfo(self.showLevel)
        end
	end)

    rn:getChildByName("right"):addClickEventListener(function ( sender )
	    playEffectSound("sound/system/click.mp3")
        self.showLevel = self.showLevel + 1
        if LRBtIsShow(self.showLevel) then
            self:restInfo(self.showLevel)
        end
	end)
end

function VipPrivilegeNode:showVipInfo(VipLevel)
    local max_level = #CONF.VIP.getIDList() - 1
    local next_level = (VipLevel + 1 >= max_level and {max_level} or {VipLevel + 1})[1] --三目
    local rn = self:getResourceNode()

    --Top
    local node_head = rn:getChildByName('Node_head')
    local uiProgress = node_head:getChildByName("Image_jindu")
	local progress_ = require('util.ScaleProgressDelegate'):create(uiProgress, uiProgress:getTag())
	progress_:setPercentage(0)

    node_head:getChildByName("vip_lv"):setString("VIP"..VipLevel)
    local Vip_exp = player:getVipPresentExp()
    local Next_exp =  CONF.VIP.get(next_level).MONEY
    node_head:getChildByName("text_jindu"):setString(Vip_exp.."/"..Next_exp)
    --(a and {b} or {c})[1]    =>   a ? b :c
    progress_:setPercentage((Vip_exp/Next_exp*100 >= 100 and {100} or {Vip_exp/Next_exp*100})[1])
    local need_node = node_head:getChildByName("node_text"):getChildByName("text2")
    need_node:setString("x"..(Next_exp - Vip_exp))
    local text3_node = node_head:getChildByName("node_text"):getChildByName("text3")
    text3_node:setPosition(need_node:getPositionX() + need_node:getContentSize().width + 4 ,need_node:getPositionY())
    node_head:getChildByName("node_text"):getChildByName("text4"):setString("VIP"..next_level)
    node_head:getChildByName("node_text"):getChildByName("text4"):setPosition(text3_node:getPositionX() + text3_node:getContentSize().width + 4 ,text3_node:getPositionY())
    --main
    local Node_Explanin = require("app.ExResInterface"):getInstance():FastLoad("VipScene/VipExplainNode.csb")
	Node_Explanin:setPosition(rn:getChildByName("Explanin"):getPosition())
	Node_Explanin:setName("Node_Explanin")
	rn:addChild(Node_Explanin)
    self.text_list = require("util.ScrollViewDelegate"):create(Node_Explanin:getChildByName("text_list"),cc.size(5,5), cc.size(150,20))
    Node_Explanin:getChildByName("text_list"):setScrollBarEnabled(false)
    self.item_list = require("util.ScrollViewDelegate"):create(Node_Explanin:getChildByName("item_list"),cc.size(13,13), cc.size(75,75))
    Node_Explanin:getChildByName("item_list"):setScrollBarEnabled(false)

    self:restInfo(VipLevel)
end

function VipPrivilegeNode:restInfo(VipLevel)
    local rn = self:getResourceNode()
    local VipInfo = CONF.VIP.get(VipLevel)
    local Node_Explanin = rn:getChildByName("Node_Explanin")
    --Left
    Node_Explanin:getChildByName("Text_title1"):setString(CONF:getStringValue('VIP_key_text_1')..VipLevel..CONF:getStringValue('VIP_key_text_2'))
    local textlist = { VipInfo.MONEY , VipInfo.EXTRA_HOME_RESOURCE , VipInfo.STRENGTH_TIMES , VipInfo.EXTRA_BLUEPRINT_CRIT , VipInfo.REDUCE_BUILDING_TIME , VipInfo.RESIGN , VipInfo.CREDIT_LOTTERY_TIMES , VipInfo.VIP_FREE_PACK_LEVEL , VipInfo.VIP_PERSONAL_PACK_LEVEL2 ,VipInfo.ADD_RAD_QUEUE }
    self.text_list:clear()
    for i=1,#textlist do
        local strlist = Split(CONF:getStringValue("VIP_text_"..i),"#")
        local str = strlist[1]..textlist[i]..strlist[2]
        local node_text = require("app.ExResInterface"):getInstance():FastLoad('VipScene/TextNode.csb')
        if string.find(str,"\n") == nil then
            node_text:getChildByName("Text"):setString(str)
            self.text_list:addElement(node_text)
        else
            local strbr = Split(str,"\n")
            node_text:getChildByName("Text"):setString(strbr[1])
            self.text_list:addElement(node_text)
            local node_text2 = require("app.ExResInterface"):getInstance():FastLoad('VipScene/TextNode.csb')
            node_text2:getChildByName("point"):setVisible(false)
            node_text2:getChildByName("Text"):setString(strbr[2])
            self.text_list:addElement(node_text2)
        end
    end

    --Right
    self.gifttype = 0
    Node_Explanin:getChildByName("get"):addClickEventListener(function ( ... )
        if self.gifttype ~= 0 then
            if self.gifttype == 1 then --免费礼包
                local strData = Tools.encode("ActivityVIPPackReq", { level = self.showLevel, type = self.gifttype })
                GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_VIP_PACK_REQ"),strData)
            else                       --专属礼包
                if player:getMoney() < CONF.VIP.get(self.showLevel).PRICE then
                    tips:tips(CONF:getStringValue("no enought credit"))
                else
                    local function func( ... )
                        local strData = Tools.encode("ActivityVIPPackReq", { level = self.showLevel, type = self.gifttype })
                        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_VIP_PACK_REQ"),strData)
                    end
                    local str = CONF:getStringValue('yes')..CONF:getStringValue('Buy')..CONF:getStringValue('current')..CONF:getStringValue('VIP_key_text_1')..CONF:getStringValue('libao').."?"
                    local node = require("util.TipsNode"):createWithBuyNode(str, VipInfo.PRICE, func)
                    node:setPosition(cc.exports.VisibleRect:center())
				    self:addChild(node)
                    local position = self:convertToNodeSpace(cc.p(node:getPosition()))
				    tipsAction(node,position)
                end
            end
            self.bt_send = true             --控制监听一次
        end
    end)

    local function recvMsg()
		-- print("VipPrivilegeNode:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_ACTIVITY_VIP_PACK_RESP") then
			local proto = Tools.decode("ActivityVIPPackResp",strData)
			if proto.result == 0 and self.bt_send then
                if self.gifttype == 2 then 
                    tips:tips(CONF:getStringValue("buy_success"))
                else
                    if self.itemtable then
                        local node = require("util.RewardNode"):createGettedNodeWithList(self.itemtable, nil, self)
					    tipsAction(node)
					    node:setPosition(cc.exports.VisibleRect:center())
					    self.scene_:addChild(node)
                    end
                end
                self.award_list = player:getVipAwardList()
                self.pack_list = player:getVipPackList()
                self:restRight(self.showLevel)
                self.bt_send = false
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

    self:restRight(VipLevel)
end

function VipPrivilegeNode:restRight(showLevel)
    local rn = self:getResourceNode()
    local VipInfo = CONF.VIP.get(showLevel)
    local Node_Explanin = rn:getChildByName("Node_Explanin")

    if self:findValueFromList(showLevel,self.award_list) then
        self.gifttype = 2
    else
        self.gifttype = 1
    end

    if self.gifttype == 1 then                                                                          -- 领取免费礼包
        self.itemIDs = VipInfo.AWARD
        self.itemNums = VipInfo.AWARD_NUM
        Node_Explanin:getChildByName("Text_title2"):setString(CONF:getStringValue('VIP_key_text_1')..showLevel..CONF:getStringValue('free')..CONF:getStringValue('libao'))
        Node_Explanin:getChildByName("node_price"):setVisible(false)
        Node_Explanin:getChildByName("get"):getChildByName("bt_Txt"):setString(CONF:getStringValue('Get'))
    else                                                                                                -- 购买专属礼包
        self.itemIDs = VipInfo.PACKS
	    self.itemNums = VipInfo.PACKS_NUM
        Node_Explanin:getChildByName("Text_title2"):setString(CONF:getStringValue('VIP_key_text_1')..showLevel..CONF:getStringValue('VIP_key_text_3'))
        Node_Explanin:getChildByName("node_price"):setVisible(true)
        Node_Explanin:getChildByName("get"):getChildByName("bt_Txt"):setString(CONF:getStringValue('Buy'))
        Node_Explanin:getChildByName("node_price"):getChildByName("Text_12"):setString(CONF:getStringValue('Oprice'))
        Node_Explanin:getChildByName("node_price"):getChildByName("Text_20"):setString(CONF:getStringValue('Cprice'))
        Node_Explanin:getChildByName("node_price"):getChildByName("original"):setString(VipInfo.SHOW_PRICE)
        Node_Explanin:getChildByName("node_price"):getChildByName("current"):setString(VipInfo.PRICE)
    end
    --items
    self.item_list:clear()
    self.itemtable = {}
    for i=1,#self.itemIDs do
        if self.itemNums[i] then
			table.insert(self.itemtable, {id = self.itemIDs[i], num = self.itemNums[i]})
            local itemNode = require("util.ItemNode"):create():init(self.itemIDs[i], formatRes(self.itemNums[i]))
            self.item_list:addElement(itemNode)
        end
    end
    --bt
    if showLevel > player:getVipLevel() then
        Node_Explanin:getChildByName("get"):setEnabled(false)
    elseif self:findValueFromList(showLevel,self.pack_list) then
        Node_Explanin:getChildByName("get"):setEnabled(false)
        Node_Explanin:getChildByName("get"):getChildByName("bt_Txt"):setString(CONF:getStringValue('yi_buy'))
    else
        Node_Explanin:getChildByName("get"):setEnabled(true)
    end

end

function VipPrivilegeNode:findValueFromList(value,list)
    if list == nil then
        return false
    end
    for k,v in ipairs(list) do
      if v == value then
        return true
      end
    end
    return false
end

function VipPrivilegeNode:onExitTransitionStart()
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

function VipPrivilegeNode:onExit()
    printInfo("VipPrivilegeNode:onExit()")
end

return VipPrivilegeNode