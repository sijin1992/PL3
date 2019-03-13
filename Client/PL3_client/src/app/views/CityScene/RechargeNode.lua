
local RechargeNode = class("RechargeNode", cc.load("mvc").ViewBase)

local app = require("app.MyApp"):getInstance()

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

RechargeNode.RESOURCE_FILENAME = "CityScene/RechargeNode.csb"

function RechargeNode:onEnterTransitionFinish()

end

function RechargeNode:createNode( id )
	local conf = CONF.RECHARGE.get(id)

	local node = require("app.ExResInterface"):getInstance():FastLoad("CityScene/RechargeItem.csb")
	node:getChildByName("get_num"):setString("+"..conf["CREDIT_"..server_platform])
	node:getChildByName("song_num"):setString(CONF:getStringValue("first_get")..conf["PRESENT_"..server_platform])
	node:getChildByName("buy_num"):setString(conf["RECHARGE_"..server_platform])
	node:getChildByName("buy_num_0"):setString(CONF:getStringValue("coin_sign"))
	node:getChildByName("icon"):setTexture("Common/ui/ui_icon_money.png")

	node:setName("item_"..id)
	node:setTag(id)

	if player:isRecharge(id) then
		node:getChildByName("song_num"):setVisible(false)
	end

	return node
end

function RechargeNode:resetList()

	self.svd_:clear()

	local id_list = CONF.RECHARGE.getIDList()

	for i,v in ipairs(id_list) do
		local conf = CONF.RECHARGE.get(v)
		if conf.TYPE == 0 then
			local node = self:createNode(v)


			local function func()

				playEffectSound("sound/system/click.mp3")

				if g_rechange_rc == nil or g_rechange_rc == 0 then
					tips:tips(CONF:getStringValue("coming soon"))
					return
				end

				if g_Can_Pay == false then
					tips:tips(CONF:getStringValue("buy_error"))
					return
				end

				-- WJJ 20180717
				-- should send gm add money , even on mobile phone, no sdk payment
				if require("util.ExSDK"):getInstance():IsWindows() then
					--gm

					local money_num = conf["RECHARGE_"..server_platform]*100
					-- wrong gm command ...
					-- local str = "addmoney "..money_num..conf.PRODUCT_ID
					local str = "addcredit " .. money_num

					local strData = Tools.encode("CmdClientGMReq", {
						cmd = str
					})

					print(string.format("~~~~~ fake pay:  %s",strData))

					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_CLIENT_GM_REQ"),strData)

					gl:retainLoading()

				elseif device.platform == "ios" or device.platform == "android" then
					if(device.platform == "android" and require("util.ExSDK"):getInstance():IsQuickSDK() ) then
						require("util.ExSDK"):getInstance():SDK_REQ_QuickPay(conf)
					else
						GameHandler.handler_c.payStart(conf.PRODUCT_ID)
						-- gl:retainLoading()
					end
				end
			end

			local callback = {node = node:getChildByName("touch"), func = func}

			self.svd_:addElement(node, {callback = callback})
		end
	end
end


function RechargeNode:init(scene,data)

	self.scene_ = scene
	self.data_ = data

	local rn = self:getResourceNode()

	rn:getChildByName("vip_text"):setString(CONF:getStringValue("vip_not"))
	--rn:getChildByName("text"):setString(CONF:getStringValue("Recharge"))	Delete By JinXin 20180620
	-- rn:getChildByName("vip_text_0"):setString(CONF:getStringValue("first_recharge_text"))
	rn:getChildByName("Text_credit"):setString(CONF:getStringValue("shop text"))

	rn:getChildByName("back"):setSwallowTouches(true)
	rn:getChildByName("back"):addClickEventListener(function ( sender )
		-- playEffectSound("sound/system/return.mp3")
		-- self:removeFromParent()
	end)
    -------------add by JinXin-------
    self:UpdateVipInfo()
    rn:getChildByName("FileNode_1"):getChildByName("btn"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local VipPrivilegeNode = require("app.views.VipScene.VipPrivilegeNode"):create()
        VipPrivilegeNode:setAnchorPoint(cc.p(0.5,0.5))
		VipPrivilegeNode:init(self:getParent(), {index = 1})
		self:addChild(VipPrivilegeNode)
        local locationInNode = self:convertToNodeSpace(cc.p(VipPrivilegeNode:getPosition()))
	end)
    ---------------------------------
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(1,3), cc.size(160,250))
	self.svd_:getScrollView():setScrollBarEnabled(false)

	self:resetList()

	rn:getChildByName("closeBtn"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/return.mp3")
		self:removeFromParent()
	end)

	tipsAction(self)

	local function recvMsg()
		print("RechargeNode:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_CLIENT_GM_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("CmdClientGMResp",strData)
			print("CMD_CLIENT_GM_RESP strData ",strData)
			print("CMD_CLIENT_GM_RESP result",proto.result)

			for k,v in pairs(proto) do
				print(string.format("proto[%s] = %s", tostring(k), tostring(v) ) )
			end

			tips:tips(CONF:getStringValue("buy_success"))	
            self:UpdateVipInfo()
			self:resetList()

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_UPDATE_RES_RESP") then

			local proto = Tools.decode("UpdateResResp",strData)

			if proto.result ~= 0 then
				print("error:", proto.result)
			else
				player:setMoney(proto.credit)
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("MoneyUpdated")
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("recharge")
                self:UpdateVipInfo()
				self:resetList()
			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.payListener_ = cc.EventListenerCustom:create("payCallback", function (event)
		gl:releaseLoading()
		if event.info.succeed then
			tips:tips(CONF:getStringValue("buy_success"))

			cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("recharge")

			local strData = Tools.encode("UpdateResReq", {
				type = 1.
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPDATE_RES_REQ"),strData)
		else
			tips:tips(CONF:getStringValue("buy_error"))
		end

		self:resetList()

	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.payListener_, FixedPriority.kNormal)
	
end

function RechargeNode:UpdateVipInfo()
    local rn = self:getResourceNode()
    local VipLevel = player:getVipLevel()
    local max_level = #CONF.VIP.getIDList() - 1
    local next_level = (VipLevel + 1 >= max_level and {max_level} or {VipLevel + 1})[1] --锟斤拷目
    local node_head = rn:getChildByName("FileNode_1"):getChildByName("FileNode_1")
    local uiProgress = node_head:getChildByName("Image_jindu")
    if self.progress_ == nil then
	    self.progress_ = require('util.ScaleProgressDelegate'):create(uiProgress, uiProgress:getTag())
	    self.progress_:setPercentage(0)
    end

    node_head:getChildByName("vip_lv"):setString("VIP"..VipLevel)
    local Vip_exp = player:getVipPresentExp()
    local Next_exp =  CONF.VIP.get(next_level).MONEY
    node_head:getChildByName("text_jindu"):setString(Vip_exp.."/"..Next_exp)
    --(a and {b} or {c})[1]    =>   a ? b :c
    self.progress_:setPercentage((Vip_exp/Next_exp*100 >= 100 and {100} or {Vip_exp/Next_exp*100})[1])
    local need_node = node_head:getChildByName("node_text"):getChildByName("text2")
    need_node:setString("x"..(Next_exp - Vip_exp))
    local text3_node = node_head:getChildByName("node_text"):getChildByName("text3")
    text3_node:setPosition(need_node:getPositionX() + need_node:getContentSize().width + 4 ,need_node:getPositionY())
    node_head:getChildByName("node_text"):getChildByName("text4"):setString("VIP"..next_level)
    node_head:getChildByName("node_text"):getChildByName("text4"):setPosition(text3_node:getPositionX() + text3_node:getContentSize().width + 4 ,text3_node:getPositionY())
end

function RechargeNode:onExitTransitionStart()
	printInfo("RechargeNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.payListener_)

end

return RechargeNode