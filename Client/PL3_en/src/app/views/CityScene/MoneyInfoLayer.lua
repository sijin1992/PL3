local player = require("app.Player"):getInstance()
local tips = require("util.TipsMessage"):getInstance()
local MoneyInfoLayer = class("MoneyInfoLayer", cc.load("mvc").ViewBase)

MoneyInfoLayer.RESOURCE_FILENAME = "MoneyNode/MoneyInfoLayer.csb"
MoneyInfoLayer.NEED_ADJUST_POSITION = true

function MoneyInfoLayer:onEnterTransitionFinish()

	local rn = self:getResourceNode()

	rn:getChildByName("bg"):getChildByName("name"):setString(CONF:getStringValue("my resource"))
	rn:getChildByName('text_des'):setString(CONF:getStringValue("currency text"))
	local updateRes = function()
		for i=3,6 do
			local resNode = rn:getChildByName("Node_res"..i)
			local conf = CONF.ITEM.get(i*1000+1)
			resNode:getChildByName('Sprite_9'):setTexture("ItemIcon/" .. conf.ICON_ID .. ".png")
			resNode:getChildByName("name_des"):setVisible(false)
			resNode:getChildByName("name"):setString(CONF:getStringValue(conf.NAME_ID))
			resNode:getChildByName("have"):setString(CONF:getStringValue("own currency")..': '..formatRes(player:getResByIndex(i-2)))
			local conf_build = CONF.BUILDING_10.get(player:getBuildingInfo(CONF.EBuilding.kWarehouse).level)
			if i == 3 then
				resNode:getChildByName("have_max"):setVisible(false)
				resNode:getChildByName("make_hour"):setVisible(false)
				resNode:getChildByName("protect_text"):setVisible(false)
			else
				resNode:getChildByName("have_max"):setString(CONF:getStringValue("currency upper")..': '..formatRes(conf_build.RESOURCE_UPPER_LIMIT[i-2]))
				resNode:getChildByName("protect_text"):setString(CONF:getStringValue("protect currency")..': '..formatRes(conf_build.RESOURCE_PROTECT_LIMIT[i-2]))
				local hourNum = {}
				if Tools.isEmpty(player:getUserInfo(  ).home_info) == false then
					hourNum = player:getLandInfo()
				end
				local info = {{num = 0, pro = 0},{num = 0, pro = 0},{num = 0, pro = 0}}

				local add = 1+(CONF.VIP.get(player:getVipLevel()).EXTRA_HOME_RESOURCE/100)

				local build_info = player:getBuildingInfo(CONF.EBuilding.kMain)
				add = add + CONF.BUILDING_1.get(build_info.level).HOME_PRODUCTION

				for i,v in ipairs(hourNum) do
					local conf = CONF.RESOURCE.get(v.resource_type)
					if conf.TYPE == 1 then
						info[1].num = info[1].num + 1

						info[1].pro = info[1].pro + (conf.PRODUCTION_NUM*add + Tools.getValueByTechnologyAddition(CONF.RESOURCE.get(v.resource_type).PRODUCTION_NUM*add, CONF.ETechTarget_1.kHomeRes, conf.TYPE, CONF.ETechTarget_3_Res.kProduction, player:getTechnolgList(), player:getPlayerGroupTech()))
					elseif conf.TYPE == 2 then
						info[2].num = info[2].num + 1
						info[2].pro = info[2].pro + (conf.PRODUCTION_NUM*add + Tools.getValueByTechnologyAddition(CONF.RESOURCE.get(v.resource_type).PRODUCTION_NUM*add, CONF.ETechTarget_1.kHomeRes, conf.TYPE, CONF.ETechTarget_3_Res.kProduction, player:getTechnolgList(), player:getPlayerGroupTech()))
					elseif conf.TYPE == 3 then
						info[3].num = info[3].num + 1
						info[3].pro = info[3].pro + (conf.PRODUCTION_NUM*add + Tools.getValueByTechnologyAddition(CONF.RESOURCE.get(v.resource_type).PRODUCTION_NUM*add, CONF.ETechTarget_1.kHomeRes, conf.TYPE, CONF.ETechTarget_3_Res.kProduction, player:getTechnolgList(), player:getPlayerGroupTech()))
					end
				end
				resNode:getChildByName("make_hour"):setString(CONF:getStringValue("base output")..': '.. math.floor(info[i-3].pro))
			end
		end
	end
	updateRes()
	rn:getChildByName("bg"):getChildByName("close"):addClickEventListener(function ( sender )
		local app = self:getApp()
		app:removeTopView()
	end )

	local function recvMsg( )
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_HOME_STATUS_RESP") then
			local proto = Tools.decode("GetHomeSatusResp",strData)
			print("GetHomeSatusResp result...", proto.result)

			if proto.result == 0 then
				updateRes()
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_UPGRADE_RESOURCE_RESP") then
			local proto = Tools.decode("UpgradeResLandResp",strData)
			if proto.result == 0 then
				updateRes()
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		updateRes()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)
end

function MoneyInfoLayer:onExitTransitionStart()
	printInfo("MoneyInfoLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.resListener_)
end

return MoneyInfoLayer