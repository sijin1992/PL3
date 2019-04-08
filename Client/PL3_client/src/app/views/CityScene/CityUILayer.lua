local player = require("app.Player"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local messageBox = require("util.MessageBox"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local g_taskManager = require("app.TaskControl"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local Bit = require "Bit"

local CityUILayer = class("CityUILayer", cc.load("mvc").ViewBase)

CityUILayer.RESOURCE_FILENAME = "CityScene/UILayer.csb"

CityUILayer.NEED_ADJUST_POSITION = true

local app = require("app.MyApp"):getInstance()

CityUILayer.guideHelper = require("util.ExGuideHelper"):getInstance()
CityUILayer.IS_SCALE_BUILDING_MENU = false

CityUILayer.RESOURCE_BINDING = {

}

CityUILayer.isBuildingOn_ = false

--CityUILayer.iconlist = {"strong","huodong","daily_task","advancedgift","shouchong","gift","sevenDay","growthfund","invest","changeship","everyday","propconvert","luckywheel"}
CityUILayer.iconlist = {"strong","huodong","sevenDay","awardonline","advancedgift","gift","invest","everyday","luckywheel"}

local schedulerEntry = nil
local schedulerEntry_Adventure = nil


local other_node_pos = {}
local other_node_pos2 = {}

local BTN_TAG =
{
	TAG_SIGNIN = 1,
	TAG_FRIEND = 2,
    TAG_SHIP = 3,
--	TAG_MAIL = 3,
	TAG_FORGE = 4,
	TAG_RANKING = 5,
	TAG_SERVICE = 6,
	TAG_SETTING = 7,
}

-- add by jinxin 20180726
CityUILayer.isOpenRetract = true
CityUILayer.isShow = false
local Retract_node = {}
local RetractTab = {}

CityUILayer.allShipList = {}

-------------------------

----------------------------------------------------



-- ADD WJJ 180622
CityUILayer.lagHelper = require("util.ExLagHelper"):getInstance()
CityUILayer.IS_DEBUG_LOG_LOCAL = false
CityUILayer.IS_SCENE_TRANSFER_EFFECT = false

function CityUILayer:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

function CityUILayer:SetGlobalVal_TimeNowOf(_key) 
	local _now = os.time() + 1
	-- cc.UserDefault:getInstance():setStringForKey(_key, tostring(_now))
	-- cc.UserDefault:getInstance():flush()
	cc.exports[_key] = tostring(_now)
	self:_print(string.format("global_time_last_tanchu_jianzhu_caidan _now : %s", tostring(_now)))
end

function CityUILayer:ScaleOpenBuildingMenu(infoNode) 
	if( self.IS_SCALE_BUILDING_MENU ) then
		infoNode:setScale(0)
		infoNode:runAction(cc.Sequence:create(cc.DelayTime:create(0.4), cc.ScaleTo:create(0.1,scale)))
	end
end

----------------------------------------------------

function CityUILayer:openUI( ... )
    if cc.exports.isHidActivityIcon == nil then
        cc.exports.isHidActivityIcon = false
    end
	self:iconOpen()

	self:reSetOtherNode_posAndAction()
end


function CityUILayer:onEnterTransitionFinish()
	printInfo("CityUILayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()

	animManager:runAnimByCSB(rn:getChildByName("kt_node"):getChildByName("fangkuai"), "CityScene/sfx/new UIeffect/fangkuai.csb", "1")

	animManager:runAnimByCSB(rn:getChildByName("league"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
	animManager:runAnimByCSB(rn:getChildByName("form"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
	animManager:runAnimByCSB(rn:getChildByName("mission"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
	animManager:runAnimByCSB(rn:getChildByName("backpack"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
	animManager:runAnimByCSB(rn:getChildByName("mail"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
    animManager:runAnimByCSB(rn:getChildByName("ship"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
	animManager:runAnimByCSB(rn:getChildByName("friend"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")

	-- rn:getChildByName("planet"):addClickEventListener(function ( ... )
	-- 	app:pushToRootView("PlanetScene/PlanetScene")
	-- end)

	local userInfoNode = require("util.UserInfoNode"):create()
	userInfoNode:init(self,true)
	userInfoNode:setName("userInfoNode")
	rn:getChildByName("info_node"):addChild(userInfoNode)
	local you = rn:getChildByName("you")
	rn:getChildByName("planet"):getChildByName("text_miao"):setString(CONF.STRING.get("planetOccupation").VALUE)
	you:getChildByName("shopBtn"):addClickEventListener(function ()
		playEffectSound("sound/system/click.mp3")
		-- self:getApp():addView2Top("ShopScene/ShopLayer");
		require("app.ExViewInterface"):getInstance():ShowShopUI()
	end)


	local other_node = rn:getChildByName("other_node")
	--set you xia 
	other_node_pos = {}
--	table.insert(other_node_pos,{other_node:getChildByName("shop"):getPositionX(),other_node:getChildByName("shop"):getPositionY()})
    table.insert(other_node_pos,{other_node:getChildByName("strong"):getPositionX(),other_node:getChildByName("strong"):getPositionY()})
	table.insert(other_node_pos,{other_node:getChildByName("huodong"):getPositionX(),other_node:getChildByName("huodong"):getPositionY()})
    table.insert(other_node_pos,{other_node:getChildByName("sevenDay"):getPositionX(),other_node:getChildByName("sevenDay"):getPositionY()}) 
    table.insert(other_node_pos,{other_node:getChildByName("awardonline"):getPositionX(),other_node:getChildByName("awardonline"):getPositionY()}) 
	table.insert(other_node_pos,{other_node:getChildByName("advancedgift"):getPositionX(),other_node:getChildByName("advancedgift"):getPositionY()})
    table.insert(other_node_pos,{other_node:getChildByName("gift"):getPositionX(),other_node:getChildByName("gift"):getPositionY()}) 
    table.insert(other_node_pos,{other_node:getChildByName("invest"):getPositionX(),other_node:getChildByName("invest"):getPositionY()})
    table.insert(other_node_pos,{other_node:getChildByName("everyday"):getPositionX(),other_node:getChildByName("everyday"):getPositionY()})
    table.insert(other_node_pos,{other_node:getChildByName("luckywheel"):getPositionX(),other_node:getChildByName("luckywheel"):getPositionY()})
--    table.insert(other_node_pos,{other_node:getChildByName("daily_task"):getPositionX(),other_node:getChildByName("daily_task"):getPositionY()})
--    table.insert(other_node_pos,{other_node:getChildByName("growthfund"):getPositionX(),other_node:getChildByName("growthfund"):getPositionY()})
--    table.insert(other_node_pos,{other_node:getChildByName("changeship"):getPositionX(),other_node:getChildByName("changeship"):getPositionY()})
--    table.insert(other_node_pos,{other_node:getChildByName("propconvert"):getPositionX(),other_node:getChildByName("propconvert"):getPositionY()})
--    table.insert(other_node_pos,{other_node:getChildByName("shouchong"):getPositionX(),other_node:getChildByName("shouchong"):getPositionY()}) 
	local nameTab2 = {"backpack","ship","mission","league","friend","form","arena","trial"}
	other_node_pos2 = {}
	for i=1,#nameTab2 do
		table.insert(other_node_pos2,{rn:getChildByName(nameTab2[i]):getPositionX(),rn:getChildByName(nameTab2[i]):getPositionY()})
	end
	self:openUI()

--	rn:getChildByName("planet"):addClickEventListener(function ()
--		if cc.exports.g_activate_building then
--			return
--		end
--		if not self:ClickPlanet() then
--			return
--		end
--        local enteranim = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/sfx/enteranim/enteranim.csb")
--		animManager:runAnimOnceByCSB(enteranim,"PlanetScene/sfx/enteranim/enteranim.csb" ,"1", function ( )
--            enteranim:removeFromParent()
--            self:getApp():addView2Top("CityScene/TransferScene",{from = "planet" ,state = "start"})
            --app:pushToRootView("PlanetScene/PlanetScene", {come_in_type = 1,sfx = true})
--            self:getApp():pushToRootView("CityScene/TransferScene",{from = "planet" ,state = "start"})
--        end)
--        enteranim:setName("enteranim")
--        local center = cc.exports.VisibleRect:center()
--        enteranim:setPosition(cc.p(center.x + (rn:getContentSize().width/2 - center.x), center.y + (rn:getContentSize().height/2 - center.y)))
--		rn:addChild(enteranim)

--	end)
	rn:getChildByName("planet"):getChildByName("jihuo"):getChildByName("btn"):addClickEventListener(function ()
		if cc.exports.g_activate_building then
			return
		end
		self:ClickPlanet()

	end)
    --------- add by jinxin 20180726
    if self.isOpenRetract and self.Retract_node ~= nil then 
--        local Movetime = 0.33
        local OpacityValue

        local function SetOpac(Value)
            for k,v in pairs(self.RetractTab) do
                rn:getChildByName(v):setOpacity(Value)
                rn:getChildByName(v):setEnabled(not cc.exports.Retractnode_Isshow)
	        end
        end

--        local function timer()
--            if self.begintime == nil then
--                return
--            end

--            local deltime = os.clock() - self.begintime
--            if deltime >= Movetime then
--                SetOpac(OpacityValue)
--                self.begintime = nil
--                rn:getChildByName("Node_retract"):setOpacity(0)
--                cc.exports.Retractnode_Isshow = not cc.exports.Retractnode_Isshow
--            end
--        end
--        if self.retractscheduler == nil then
--            self.retractscheduler = scheduler:scheduleScriptFunc(timer,0.033,false)
--        end
        rn:getChildByName("more"):addClickEventListener(function ()
--            local ScaleX = 1
            local txt,uistr
--            local action1,action2
            if cc.exports.Retractnode_Isshow then
--                ScaleX = 1
                OpacityValue = 0
                txt = CONF:getStringValue("more")
                uistr = "CityScene/ui3/icon_more.png"
--                action1 = cc.FadeOut:create(Movetime)
--                action2 = cc.MoveBy:create(Movetime, cc.p(88.02, 0))
            else
--                ScaleX = -1
                OpacityValue = 255
                txt = CONF:getStringValue("take_up")
                uistr = "CityScene/ui3/icon_packup.png"
--                action1 = cc.FadeIn:create(Movetime)
--                action2 = cc.MoveBy:create(Movetime, cc.p(-88.02, 0))
            end
            rn:getChildByName("more"):getChildByName("text_miao"):setString(txt)
            rn:getChildByName("more"):getChildByName("more"):loadTexture(uistr)
--            rn:getChildByName("more"):getChildByName("more"):setScaleX(ScaleX)

--            if not cc.exports.Retractnode_Isshow then
--                rn:getChildByName("Node_retract"):setPosition(other_node_pos2[4][1],other_node_pos2[4][2])
--                rn:getChildByName("Node_retract"):runAction(cc.Spawn:create(action1, action2))
--                self.begintime = os.clock()
--            else
                SetOpac(OpacityValue)
--                rn:getChildByName("Node_retract"):setPosition(other_node_pos2[4][1] - 88.02,other_node_pos2[4][2])
--                rn:getChildByName("Node_retract"):setOpacity(255)
--                rn:getChildByName("Node_retract"):runAction(cc.Spawn:create(action1, action2))
                cc.exports.Retractnode_Isshow = not cc.exports.Retractnode_Isshow
--            end
        end)
    end
    ------------------------------
	rn:getChildByName("mail"):getChildByName("text_miao"):setString(CONF.STRING.get("mail").VALUE)
    rn:getChildByName("mail"):addClickEventListener(function()
    	if cc.exports.g_activate_building then
			return
		end
        rn:getChildByName("mail"):getChildByName("point"):setVisible(false)
        self:getApp():pushView("MailScene/MailScene",{from = 'city'})
    end)

    rn:getChildByName("ship"):getChildByName("text_miao"):setString(CONF.STRING.get("Airship").VALUE)
    rn:getChildByName("ship"):addClickEventListener(function()
    	if cc.exports.g_activate_building then
			return
		end
        rn:getChildByName("ship"):getChildByName("point"):setVisible(false)
        self:getApp():pushView("ShipsScene/ShipsDevelopScene",{type = 5})
    end)

    rn:getChildByName("mission"):getChildByName("text_miao"):setString(CONF.STRING.get("task").VALUE)
    rn:getChildByName("mission"):addClickEventListener(function ()
    	if cc.exports.g_activate_building then
			return
		end
		local layer = self:getApp():createView("TaskScene/TaskScene",1)
		self:addChild(layer)
    end)

    rn:getChildByName("backpack"):getChildByName("text_miao"):setString(CONF.STRING.get("knapsack").VALUE);
    rn:getChildByName("backpack"):addClickEventListener(function ()
    	if cc.exports.g_activate_building then
			return
		end
    	self:getApp():pushView("ItemBagScene/ItemBagScene", {from = "city"})
    end)
    rn:getChildByName("trial"):getChildByName("text_miao"):setString(CONF.STRING.get("trial").VALUE);
    rn:getChildByName("trial"):addClickEventListener(function ()
    	if cc.exports.g_activate_building then
			return
		end
    	self:getApp():pushToRootView("TrialScene/TrialAreaScene")
    end)
    rn:getChildByName("arena"):getChildByName("text_miao"):setString(CONF.STRING.get("arena").VALUE);
    rn:getChildByName("arena"):addClickEventListener(function ()
    	if cc.exports.g_activate_building then
			return
		end
    	self:getApp():pushToRootView("ArenaScene/ArenaScene")
    end)
    rn:getChildByName("totalNode"):getChildByName("totalBtn"):addClickEventListener(function ()
    	if cc.exports.g_activate_building then
			return
		end
		--rn:getChildByName("totalNode"):setVisible(false)
    	self:getApp():addView2Top("CityScene/BuildTotalLayer");

    end)


	local p = player:getStrength() / player:getMaxStrength() * 100 
	if p > 100 then
		p = 100
	end
	-- self.strengthDelegate_:setPercentage(p)

	you:getChildByName("ev_num"):setString(player:getStrength().."/"..player:getMaxStrength())


	for i=1,4 do
		you:getChildByName(string.format("res_text_%d", i)):setString(formatRes(player:getResByIndex(i)))
	end
	--set credit

	you:getChildByName("money_num"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))


	you:getChildByName("money_add"):addClickEventListener(function ( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self:getParent(), {index = 1})
		self:getParent():addChild(rechargeNode)
	end)

	you:getChildByName("money_touch"):addClickEventListener(function ( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self:getParent(), {index = 1})
		self:getParent():addChild(rechargeNode)
	end)

	you:getChildByName("res_touch"):addClickEventListener(function()
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
		self:getApp():addView2Top("CityScene/MoneyInfoLayer")
	end)

	---settouch

	you:getChildByName("open"):addClickEventListener(function ( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
		if sender:getTag() == 370 then
			you:setPositionX(you:getPositionX() - 240)
			sender:getChildByName("icon"):setRotation(180)
			sender:setTag(371)
		elseif sender:getTag() == 371 then
			you:setPositionX(you:getPositionX() + 240)
			sender:getChildByName("icon"):setRotation(0)
			sender:setTag(370)
		end
	end)

	-- callback

	you:getChildByName("strength_add"):addClickEventListener(function ( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
		self:getApp():addView2Top("CityScene/AddStrenthLayer")
	end)

	you:getChildByName("st_touch"):addClickEventListener(function ( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
		self:getApp():addView2Top("CityScene/AddStrenthLayer")
	end)


	if player:isGetFirstRechargeReward() then
		other_node:getChildByName("shouchong"):setVisible(false)
	end

	local recharge = other_node:getChildByName("shouchong")
	local function shouchong(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			-- sender:setOpacity(255*0.7)

			local layer = self:getApp():createView("ActivityScene/ActivityFirstRechargeNode")

			self:addChild(layer)
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end

	recharge:getChildByName("bg"):addTouchEventListener(shouchong)
	recharge:getChildByName("shouchong_text"):setString(CONF:getStringValue("first_recharge"))
	animManager:runAnimByCSB(recharge:getChildByName("sfx"), "CityScene/sfx/shouchong/shouchong.csb", "1")

	local activity = other_node:getChildByName("huodong")
	local function huodong(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			-- sender:setOpacity(255*0.7)
			-- EDIT WJJ 20180625
			-- self:getApp():addView2Top("ActivityScene/ActivityScene")

			require("app.ExViewInterface"):getInstance():ShowActivityUI()
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end

	activity:getChildByName("bg"):addTouchEventListener(huodong)
	activity:getChildByName("huodong_text"):setString(CONF:getStringValue("activity"))
	animManager:runAnimByCSB(activity:getChildByName("sfx"), "CityScene/sfx/huodong/huodong.csb", "1")

	local gift = other_node:getChildByName("gift")
	local function fun_gift(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			self:getApp():pushView("GiftScene/GiftScene")
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end
	gift:getChildByName("bg"):addTouchEventListener(fun_gift)
	gift:getChildByName("text_miao"):setString(CONF:getStringValue("libao"))

	local sevenDay = other_node:getChildByName("sevenDay")
	local function fun_sevenDay(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			local haveSevenDay = false
			if Tools.isEmpty(player:getPlayerActivityIDList()) == false then
				-- for i,v in ipairs(CONF:getActivityConf(CONF.EActivityGroup.kSevenDays).getIDList()) do
					for i2,v2 in ipairs(player:getPlayerActivityIDList()) do
						if 4001 == v2 then
							haveSevenDay = true
							break
						end
					end
				-- end
			end
			if haveSevenDay then
				require("app.ExViewInterface"):getInstance():ShowActivityUI({group_id = CONF.EActivityGroup.kSevenDays})
			else
				tips:tips("该活动已结束")
			end
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end
	sevenDay:getChildByName("bg"):addTouchEventListener(fun_sevenDay)
	sevenDay:getChildByName("text"):setString(CONF:getStringValue("ACTI_4"))

    local awardonline = other_node:getChildByName("awardonline")
	local function fun_awardonline(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			local haveawardonline = false
			if Tools.isEmpty(player:getPlayerActivityIDList()) == false then
				-- for i,v in ipairs(CONF:getActivityConf(CONF.EActivityGroup.kSevenDays).getIDList()) do
					for i2,v2 in ipairs(player:getPlayerActivityIDList()) do
						if 5001 == v2 then
							haveawardonline = true
							break
						end
					end
				-- end
			end
			if haveawardonline then
				require("app.ExViewInterface"):getInstance():ShowActivityUI({group_id = CONF.EActivityGroup.kOnline})
			else
				tips:tips("该活动已结束")
			end
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end
	awardonline:getChildByName("bg"):addTouchEventListener(fun_awardonline)
	awardonline:getChildByName("text"):setString(CONF:getStringValue("ACTI_5"))

    local growthfund = other_node:getChildByName("growthfund")
    local function fun_growthfund(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			local havegrowthfund = false
			if Tools.isEmpty(player:getPlayerActivityIDList()) == false then
				-- for i,v in ipairs(CONF:getActivityConf(CONF.EActivityGroup.kSevenDays).getIDList()) do
					for i2,v2 in ipairs(player:getPlayerActivityIDList()) do
						if 12001 == v2 then
							havegrowthfund = true
							break
						end
					end
				-- end
			end
			if havegrowthfund then
				require("app.ExViewInterface"):getInstance():ShowActivityUI({group_id = CONF.EActivityGroup.kGrowthFund})
			else
				tips:tips("该活动已结束")
			end
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end
	growthfund:getChildByName("bg"):addTouchEventListener(fun_growthfund)
	growthfund:getChildByName("text"):setString(CONF:getStringValue("ACTI_7"))

    local invest = other_node:getChildByName("invest")
    local function fun_invest(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			local haveinvest = false
			if Tools.isEmpty(player:getPlayerActivityIDList()) == false then
				-- for i,v in ipairs(CONF:getActivityConf(CONF.EActivityGroup.kSevenDays).getIDList()) do
					for i2,v2 in ipairs(player:getPlayerActivityIDList()) do
						if 13001 == v2 then
							haveinvest = true
							break
						end
					end
				-- end
			end
			if haveinvest then
				require("app.ExViewInterface"):getInstance():ShowActivityUI({group_id = CONF.EActivityGroup.kInvest})
			else
				tips:tips("该活动已结束")
			end
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end
	invest:getChildByName("bg"):addTouchEventListener(fun_invest)
	invest:getChildByName("text"):setString(CONF:getStringValue("ACTI_8"))

    local changeship = other_node:getChildByName("changeship")
    local function fun_changeship(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			local havechangeship = false
			if Tools.isEmpty(player:getPlayerActivityIDList()) == false then
				-- for i,v in ipairs(CONF:getActivityConf(CONF.EActivityGroup.kSevenDays).getIDList()) do
					for i2,v2 in ipairs(player:getPlayerActivityIDList()) do
						if 15001 == v2 then
							havechangeship = true
							break
						end
					end
				-- end
			end
			if havechangeship then
				require("app.ExViewInterface"):getInstance():ShowActivityUI({group_id = CONF.EActivityGroup.kChangeShip})
			else
				tips:tips("该活动已结束")
			end
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end
	changeship:getChildByName("bg"):addTouchEventListener(fun_changeship)
	changeship:getChildByName("text"):setString(CONF:getStringValue("ACTI_11"))

    local everyday = other_node:getChildByName("everyday")
	local function fun_everyday(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			-- sender:setOpacity(255*0.7)

			local layer = self:getApp():createView("OperatingActivitieScene/EveryDayLayer",17001)

			self:addChild(layer)
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end

	everyday:getChildByName("bg"):addTouchEventListener(fun_everyday)
	everyday:getChildByName("text"):setString(CONF:getStringValue("activity_001"))

    local propconvert = other_node:getChildByName("propconvert")
	local function fun_propconvert(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			-- sender:setOpacity(255*0.7)

			local layer = self:getApp():createView("OperatingActivitieScene/PropConvertLayer",20001)

			self:addChild(layer)
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end

	propconvert:getChildByName("bg"):addTouchEventListener(fun_propconvert)
	propconvert:getChildByName("text"):setString(CONF:getStringValue("activity_005"))

    local luckywheel = other_node:getChildByName("luckywheel")
	local function fun_luckywheel(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			-- sender:setOpacity(255*0.7)

			local layer = self:getApp():createView("OperatingActivitieScene/LuckyWheelLayer",18001)

			self:addChild(layer)
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end

	luckywheel:getChildByName("bg"):addTouchEventListener(fun_luckywheel)
	luckywheel:getChildByName("text"):setString(CONF:getStringValue("activity_002"))

    local advancedgift = other_node:getChildByName("advancedgift")
	local function fun_advancedgift(sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			-- sender:setOpacity(255*0.7)

			self:getApp():pushView("OperatingActivitieScene/AdvancedGiftScene",19001)

		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end

	advancedgift:getChildByName("bg"):addTouchEventListener(fun_advancedgift)
	advancedgift:getChildByName("text"):setString(CONF:getStringValue("activity_003"))

	--改成在线奖励，暂未有功能
	local strong = other_node:getChildByName("strong")
	strong:getChildByName("bg"):addTouchEventListener(function (sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			-- sender:setOpacity(255*0.7)
			self:getApp():addView2Top("StrongLayer/StrongLayer")
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end)
	strong:getChildByName("text"):setString(CONF:getStringValue("strong"))

	--打开改成贸易中心，贸易中心open逻辑不变
	local shop = other_node:getChildByName("shop")
	shop:getChildByName("bg"):addTouchEventListener(function (sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			-- sender:setOpacity(255*0.7)
			-- self:getApp():pushToRootView("ShopScene/ShopScene")
			-- self:getApp():addView2Top("ShopScene/ShopLayer")
			require("app.ExViewInterface"):getInstance():ShowShopUI()
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end)
	shop:getChildByName("text_miao"):setString(CONF:getStringValue("shop"))



	local daily_task = other_node:getChildByName("daily_task")
	daily_task:getChildByName("bg"):addTouchEventListener(function (sender, eventType )
		if cc.exports.g_activate_building then
			return
		end
		if eventType == ccui.TouchEventType.began then 
			-- sender:setOpacity(255)
			playEffectSound("sound/system/click.mp3")
		elseif eventType == ccui.TouchEventType.ended then 
			-- sender:setOpacity(255*0.7)

			-- self:getApp():addView2Top("TaskScene/TaskScene", 3)
			local layer = self:getApp():createView("TaskScene/TaskScene",3)
			self:addChild(layer)
		elseif eventType == ccui.TouchEventType.canceled then 
			-- sender:setOpacity(255*0.7)
		end
	end)
	daily_task:getChildByName("text"):setString(CONF:getStringValue("daily_task"))

	if g_taskManager:hasUnfinishDailyTask() == true then
		daily_task:getChildByName("point"):setVisible(true)
	end

	rn:getChildByName("league"):getChildByName("text_miao"):setString(CONF.STRING.get("covenant").VALUE)
	rn:getChildByName("form"):getChildByName("text_miao"):setString(CONF.STRING.get("yushe").VALUE);
    rn:getChildByName("friend"):getChildByName("text_miao"):setString(CONF.STRING.get("friend").VALUE);

	rn:getChildByName("chat"):addClickEventListener(function ( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		layer:setName("chatLayer")
		self:getParent():addChild(layer)

		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
	end)

	rn:getChildByName("chat_img"):addClickEventListener(function ( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		layer:setName("chatLayer")
		self:getParent():addChild(layer)

		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
	end)
	--

	--跳转关卡
	self:createTaskBar()
	--设置?
	self:setState()

	--播放进入动画
	animManager:runAnimOnceByCSB(self:getResourceNode(), "CityScene/UILayer.csb", "intro")

	animManager:runAnimByCSB(rn:getChildByName("sfx"), "CityScene/sfx/star/star.csb","1")
	self:receiveMessage()

	rn:getChildByName("btn_jinggao"):addClickEventListener(function ( ... )
		if cc.exports.g_activate_building then
			return
		end
		if player:getPlayerPlanetUser() then
			self:getApp():addView2Top("PlanetScene/PlanetWarningLayer")
		end
	end)

	local function changeWarningInfo( ... )
		if player:getPlayerPlanetUser() then
			if player:getPlayerPlanetUser().attack_me_list then
				if #player:getPlayerPlanetUser().attack_me_list > 0 then
					rn:getChildByName("btn_jinggao"):getChildByName("text"):setString(#player:getPlayerPlanetUser().attack_me_list)
					rn:getChildByName("btn_jinggao"):getChildByName("text"):setVisible(true)
					rn:getChildByName("warning_sfx"):setVisible(true)
					rn:getChildByName("btn_jinggao"):setVisible(true)
				else
					rn:getChildByName("btn_jinggao"):getChildByName("text"):setVisible(false)
					rn:getChildByName("warning_sfx"):setVisible(false)
					rn:getChildByName("btn_jinggao"):setVisible(false)
				end
			end
		end
	end

	changeWarningInfo()

	animManager:runAnimByCSB(rn:getChildByName("warning_sfx"), "PlanetScene/sfx/warning/warning.csb", "1")

    self:getParent():getResourceNode():getChildByName("text_2"):getChildByName("shiptip"):addClickEventListener(function()
        playEffectSound("sound/system/click.mp3")
        self:getApp():pushView("ShipsScene/ShipsDevelopScene",{type = 5})
	end)

    local function showshiptip()
        local allshipList = getAllShipList()
        local canCompound = false
        local canBreak = false
        for k,v in ipairs(allshipList) do
            if v.isHave == 0 then
                if v.needBluePrintNum <= v.haveBluePrintNum then
                    canCompound = true
                    break
                end
            else
                local cfg_break = CONF.SHIP_BREAK.get(v.quality)
                local nextlevel = v.breakNum + 1
                if v.breakNum < cfg_break.NUM and v.level >= cfg_break["NEED_LEVEL"..nextlevel] then
                    local item = {}
                    for k2,v2 in ipairs(cfg_break["ITEM_ID"..nextlevel]) do
		                local t = {}
		                t.id = v2
		                t.num = cfg_break["ITEM_NUM"..nextlevel][k2]
		                table.insert(item,t)
	                end
                    local t = {}
                    t.num = CONF.SHIP_BLUEPRINTBREAK.get(v.quality)["ITEM_NUM"..nextlevel]
                    t.id = v.blueprintId
	                table.insert(item,t)
                    local enough = true
                    for k2,v2 in ipairs(item) do
			            if player:getItemNumByID(v2.id) < v2.num then
				            enough = false
				            break
			            end
		            end
                    if enough then
                        canBreak = true
                        break
                    end
                end
            end
        end
        self:getParent():getResourceNode():getChildByName("text_2"):getChildByName("shiptip"):setVisible(false)
        rn:getChildByName("ship"):getChildByName("point"):setVisible(false)
        if canCompound or canBreak then
            self:getParent():getResourceNode():getChildByName("text_2"):getChildByName("shiptip"):setVisible(true)
            rn:getChildByName("ship"):getChildByName("point"):setVisible(true)
        end
    end

	local function update(dt)
		self:updateTaskBar(dt)
		self:UpdateTotalStatus(dt)
		changeWarningInfo()
        showshiptip()

		local rn = self:getResourceNode()
		local bagShow = false
		local newItems = player:getItemUpdateTab()
		for k,v in pairs(newItems) do
			if next(v) then
				bagShow = true
			end
		end
		rn:getChildByName('backpack'):getChildByName('point'):setVisible(bagShow)
		if IsFuncOpen("arena") == true then
			--rn:getChildByName("arena"):getChildByName("point"):setVisible(player:hasArenaChallengeTimes())
		end
		if IsFuncOpen("trial") == true then
			--rn:getChildByName("trial"):getChildByName("point"):setVisible(player:getTrialTicketNum() > 0)
		end
		if IsFuncOpen("league") == true then

			local flag = false
			if player:hasGroupBossChallengeTimes(player:getGroupBossDays()[1].index) then
			    flag = true
			end
			if player:getGroupHasWar() then
			    flag = true
			end

			rn:getChildByName("league"):getChildByName("point"):setVisible(flag)


		end
		self:getResourceNode():getChildByName("other_node"):getChildByName("huodong"):getChildByName("point"):setVisible(self:showAvRed(player:getPlayerActivityIDList()))
	end
	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	local eventDispatcher = self:getEventDispatcher()
	self.maintasklistener_ = cc.EventListenerCustom:create("TaskUpdate", function ( event )
		self:createTaskBar()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.maintasklistener_, FixedPriority.kNormal)

	self.dailytasklistener_ = cc.EventListenerCustom:create("DailyTaskUpdate", function ( event )
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.dailytasklistener_, FixedPriority.kNormal)
	
	self.normaltasklistener_ = cc.EventListenerCustom:create("NormalTaskUpdate", function ( event )
		-- self:createNormalTaskBar()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.normaltasklistener_, FixedPriority.kNormal)

	self.levelupListener_ = cc.EventListenerCustom:create("playerLevelUp", function ()
		self:setState()
		self:openUI()
        self:HidActivityIcon(cc.exports.isHidActivityIcon)
		self:createTaskBar()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.levelupListener_, FixedPriority.kNormal)

	self.updateCityActivityPoint = cc.EventListenerCustom:create("updateCityActivityPoint", function ()
		-- self:getResourceNode():getChildByName("other_node"):getChildByName("huodong"):getChildByName("point"):setVisible(self:showAvRed(CONF.ACTIVITY.getIDList()))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.updateCityActivityPoint, FixedPriority.kNormal)
	self.guideListener_ = cc.EventListenerCustom:create("GuideOver", function ()
		self:setState()
		self:openUI()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.guideListener_, FixedPriority.kNormal)
	self:reSetOtherNode_posAndAction()
	rn:getChildByName("mission"):getChildByName("point"):setVisible(self:showTaskRed())

	rn:getChildByName("Image_1"):setVisible(false)
	rn:getChildByName("Image_1"):getChildByName("text"):setString(CONF:getStringValue("adventure_gift"))
	animManager:runAnimByCSB(rn:getChildByName("Image_1"), "AdventureLayer/sfx/qiyu/UIeffect.csb", "1")
	rn:getChildByName("Image_1"):getChildByName("adventure_Btn"):addClickEventListener(function()
		if cc.exports.g_activate_building then
			return
		end
		if not display:getRunningScene():getChildByName("AdventureLayer") then
			local layer2 = app:createView("AdventureLayer/AdventureLayer")
			layer2:setPosition(cc.exports.VisibleRect:leftBottom())
			display:getRunningScene():addChild(layer2)
			layer2:setName("AdventureLayer")
		end
		end)
	local function updateAdventure()
		local newHandGigt = player:getNewHandGift()
		if newHandGigt.new_hand_gift_bag_list ~= nil and Tools.isEmpty(newHandGigt.new_hand_gift_bag_list) == false then
			if player:isGetFirstRechargeReward() then
                rn:getChildByName("Image_1"):setPosition(cc.p(rn:getChildByName("other_node"):getChildByName("shouchong"):convertToWorldSpace(cc.p(-50,-10))))
            end
            rn:getChildByName("Image_1"):setVisible(true)
			rn:getChildByName("Image_1"):getChildByName("num"):setString(#newHandGigt.new_hand_gift_bag_list)
		else
			rn:getChildByName("Image_1"):setVisible(false)
		end
	end
	if schedulerEntry_Adventure == nil then
		schedulerEntry_Adventure = scheduler:scheduleScriptFunc(updateAdventure,1,false)
	end
    ----活动icon隐藏
    local function showbttexture()
        if cc.exports.isHidActivityIcon then
            rn:getChildByName("activity_show_bt"):loadTextureNormal("CityScene/ui3/activity_show2_bt1.png")
            rn:getChildByName("activity_show_bt"):loadTexturePressed("CityScene/ui3/activity_show2_bt2.png")
        else
            rn:getChildByName("activity_show_bt"):loadTextureNormal("CityScene/ui3/activity_show_bt1.png")
            rn:getChildByName("activity_show_bt"):loadTexturePressed("CityScene/ui3/activity_show_bt2.png")
        end
    end
    showbttexture()
    rn:getChildByName("activity_show_bt"):addClickEventListener(function ()
        cc.exports.isHidActivityIcon = not cc.exports.isHidActivityIcon
        showbttexture()
        self:HidActivityIcon(cc.exports.isHidActivityIcon)
	end)

    if self:IsGuideMode() then 
        rn:getChildByName("activity_show_bt"):setVisible(false)
    else
        rn:getChildByName("activity_show_bt"):setVisible(true)
    end
    --------------

    self:UpdateTotalStatus(0)

	-- WJJ 20180724
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Zhucheng_Ui(self)
end

function CityUILayer:setStrengthPercent( )

	local rn = self:getResourceNode()

	local you = rn:getChildByName("you")

	-- local strenthBar = you:getChildByName("progress")
	-- self.strengthDelegate_ = require("util.ScaleProgressDelegate"):create(strenthBar, strenthBar:getTag())

	you:getChildByName("ev_num"):setString(player:getStrength().."/"..player:getMaxStrength())

	local p = player:getStrength()/player:getMaxStrength() * 100
	if p > 100 then
		p = 100
	end

	-- self.strengthDelegate_:setPercentage(p)
end

function CityUILayer:setData(  )
	--先创建所有的按钮，统一放入self.btnList备用
	--参数 name 文字对应strign表，对应 图片?
	local rn = self:getResourceNode():getChildByName("RotatePanel"):getChildByName("rotateNode")
	local function createBtn( name ,tag )       
		local node = require("app.ExResInterface"):getInstance():FastLoad("CityScene/ButtonNode.csb")
		local iconName = "CityScene/ui3/icon_" .. name ..".png"
		node:getChildByName("icon"):setTexture(iconName)
		node:getChildByName("text"):setString(CONF:getStringValue(name))
		--node:getChildByName("text"):setString(tag)
		node:getChildByName("red"):setVisible(false)
		node:setTag(tag)
		node:setName(name)
		self.btnList[tag] = node
		node:retain()
		self.isClicked = true

		local function touchBegan(touch,event)   
			self.isClicked = true
			local target = event:getCurrentTarget()       
			local point = target:convertToNodeSpace(touch:getLocation())
			local s = target:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)
			if cc.rectContainsPoint(rect,point) then
				return true
			end
			return false
		end

		local function touchMoved(touch,event)
			self.isClicked = false
		end

		local function touchEnded(touch,event)       
			local target = event:getCurrentTarget()
			local tag = target:getParent():getTag()
			if self.isClicked == true then
				playEffectSound("sound/system/click.mp3")
				print("ckicked tag ======",tag)
				if tag == BTN_TAG.TAG_FRIEND then 
					local layer = self:getApp():createView("FriendLayer/FriendLayer", {has = rn:getChildByName("friend"):getChildByName("red"):isVisible()})
					self:getParent():addChild(layer)
				elseif tag == BTN_TAG.TAG_MAIL then 
					rn:getChildByName("mail"):getChildByName("red"):setVisible(false)
					self:getApp():pushView("MailScene/MailScene",{from = 'city'})
                elseif tag == BTN_TAG.TAG_SHIP then
                    rn:getChildByName("ship"):getChildByName("red"):setVisible(false)
                    self:getApp():pushView("ShipsScene/ShipsDevelopScene",{type = 5})
				elseif tag == BTN_TAG.TAG_RANKING then 
					
					self:getApp():pushView("RankLayer/RankLayer")
				elseif tag == BTN_TAG.TAG_SETTING then 
					self:getApp():addView2Top("CityScene/SiteLayer")
				elseif tag == BTN_TAG.TAG_FORGE then 
					-- self:getApp():pushView("ForgeScene/ForgeScene")
					self:getApp():pushView("SmithingScene/SmithingScene",{kind = 2})
				elseif tag == BTN_TAG.TAG_SIGNIN then 
					local layer = self:getApp():createView("ActivityScene/ActivitySignin")
					self:getParent():addChild(layer)
				elseif tag == BTN_TAG.TAG_SERVICE then

						tips:tips(CONF:getStringValue("coming soon"))

				end

			end 

		end

		local listener = cc.EventListenerTouchOneByOne:create();
		local dispatcher = self:getEventDispatcher()
		listener:setSwallowTouches(false)
		listener:registerScriptHandler(touchBegan,cc.Handler.EVENT_TOUCH_BEGAN);
		listener:registerScriptHandler(touchEnded,cc.Handler.EVENT_TOUCH_ENDED);
		listener:registerScriptHandler(touchMoved,cc.Handler.EVENT_TOUCH_MOVED);
		dispatcher:addEventListenerWithSceneGraphPriority(listener, node:getChildByName("bg"));
	end

	createBtn("friend" ,BTN_TAG.TAG_FRIEND)
	createBtn("service" ,BTN_TAG.TAG_SERVICE)
	createBtn("forge" ,BTN_TAG.TAG_FORGE)
--	createBtn("mail" ,BTN_TAG.TAG_MAIL)
    createBtn("ship" ,BTN_TAG.TAG_MAIL)
	createBtn("ranking" ,BTN_TAG.TAG_RANKING)
	createBtn("signIn" ,BTN_TAG.TAG_SIGNIN)
	createBtn("setting" ,BTN_TAG.TAG_SETTING)

	self.sumbtn = #self.btnList
	if self.sumbtn == 3 then
		self.itemList = self.btnList
		self.sita = {270 ,225 ,180}
		self.head = nil
		for i=1,3 do
			self.itemList[i] = self.btnList[i]
			rn:addChild(self.itemList[i])
		end
	elseif self.sumbtn >= 5 then
		for i=1,5 do
			self.itemList[i] = self.btnList[i]
			rn:addChild(self.itemList[i])
		end
		self.head = 1 
		self.sita[1] = 315 
		for i=1,4 do
			table.insert( self.sita ,315 - 45 * i)
		end
		self.checkAngle = {}
		for i=1,8 do
			table.insert( self.checkAngle ,45 * (i-1))
		end
	end     
end

-- 活动红点
function CityUILayer:showAvRed( id_list )
	if Tools.isEmpty(id_list) then
		return false
	end
	local function getLimitNum( info,id )

		if info == nil then
			return 0 
		end

		for ii,vv in ipairs(info.change_data.limit_list) do
			if vv.key == id then
				return vv.value 
			end
		end

		return 0
	end

	local function getIsRecharge( info, id )
		if info == nil then
			return false
		end

		for i,v in ipairs(info.recharge_data.getted_id_list) do
			if v == id then
				return true
			end
		end

		return false
	end

	local function getIsConsume( info, id )
		if info == nil then
			return false
		end

		for i,v in ipairs(info.consume_data.getted_id_list) do
			if v == id then
				return true
			end
		end

		return false
	end

	local function getSevenDay( info, id, planet_user)
		if info == nil then
			return false
		end

		for i,v in ipairs(info.getted_reward_list) do
			if v == id then
				return false
			end
		end

		local conf = CONF.SEVENDAYSTASK.get(id)

		if conf.TARGET_1 == 9 then
			if info.sign_in_days >= conf.VALUES[1] then
				return true
			end
		elseif conf.TARGET_1 == 1 then
			for i,v in ipairs(info.level_info) do
				if v.level_id == conf.VALUES[1] then
					if v.level_star >= conf.VALUES[2] then
						return true
					end
				end
			end
		elseif conf.TARGET_1 == 2 then
			if conf.TARGET_2 == 1 then
				if info.building_levelup_count >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 2 then
				if info.building_levelup_count + info.home_levelup_count >= conf.VALUES[1] then
					return true
				end
			end
		elseif conf.TARGET_1 == 3 then
			if info.home_levelup_count >= conf.VALUES[1] then
				return true
			end
		elseif conf.TARGET_1 == 4 then
			if player:getLevel() >= conf.VALUES[1] then
				return true
			end
		elseif conf.TARGET_1 == 5 then
			if conf.TARGET_2 == 1 then
				if info.ship_levelup_count >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 6 then
				if info.equip_strength_count >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 7 then
				if info.ship_break_count >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 3 then
				local ship_num = 0
				for ii,vv in ipairs(player:getShipList()) do
					if vv.quality == conf.VALUES[1] then
						ship_num = ship_num + 1
					end
				end

				if ship_num >= conf.VALUES[2] then
					return true
				end
			end
		elseif conf.TARGET_1 == 6 then
			if conf.TARGET_2 == 1 then
				if info.already_challenge_times >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 2 then
				if info.win_challenge_times >= conf.VALUES[1] then
					return true
				end
			end
		elseif conf.TARGET_1 == 7 then
			if info.contribute_times >= conf.VALUES[1] then
				return true
			end
		elseif conf.TARGET_1 == 8 then
			if conf.TARGET_2 == 1 then
				if info.recharge_money >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 2 then
				if info.consume_money >= conf.VALUES[1] then
					return true
				end
			end
		elseif conf.TARGET_1 == 10 then
			if conf.TARGET_2 == 1 then
				if info.lottery_count >= conf.VALUES[1] then
					return true
				end
			elseif conf.TARGET_2 == 2 then
				if info.money_lottery_count >= conf.VALUES[1] then
					return true
				end
			end
		elseif conf.TARGET_1 == 12 then
			for i,v in ipairs(info.trial_level_list) do
				if v.level_id == conf.VALUES[1] then
					if v.star >= conf.VALUES[2] then
						return true
					end
				end
			end
		elseif conf.TARGET_1 == 13 then
			if not planet_user or not planet_user.seven_days_data then
				return false
			end
			if conf.TARGET_2 == 10 then
				return planet_user.seven_days_data.attack_monster_times >= conf.VALUES[1]
			elseif conf.TARGET_2 == 11 then
				return planet_user.seven_days_data.base_attack_times >= conf.VALUES[1]
			elseif conf.TARGET_2 == 12 then
				return planet_user.seven_days_data.colloct_level_times_list_day >= conf.VALUES[1]
			elseif conf.TARGET_2 == 13 then
				return planet_user.seven_days_data.ruins_level_times_list_day >= conf.VALUES[1]
			elseif conf.TARGET_2 == 14 then
				return planet_user.seven_days_data.fishing_level_times_list_day >= conf.VALUES[1]
			elseif conf.TARGET_2 == 15 then
				return planet_user.seven_days_data.boss_level_times_list_day >= conf.VALUES[1]
			end
		elseif conf.TARGET_1 == 14 then
			if info.technology_levelup_count >= conf.VALUES[1] then
				return true
			end
		elseif conf.TARGET_1 == 15 then
			if info.weapon_levelup_count >= conf.VALUES[1] then
				return true
			end
		end

		return false
		
	end

	local function getOnline( info, index )
		if info == nil then
			return false
		end

		for i,v in ipairs(info.online_data.get_indexs) do
			if v == index then
				return true
			end
		end

		return false
	end

	local function getIsPower( info, index )
		if info == nil then
			return false
		end

		for i,v in ipairs(info.power_data.get_indexs) do
			if v == index then
				return true
			end
		end

		return false
	end

	local function getIsSetIn( info )
		if info == nil then
			return false
		end

		return info.change_ship_data.getted_reward
	end
	local function getSignInToday(info)
		if not info or not info.month_sign_data or not info.month_sign_data.get_nums then
			return true
		end
		if info.month_sign_data.get_nums[player:getServerDate().day] == 0 then
			return true
		end
		return false
	end
	for i,v in ipairs(id_list) do
		if CONF.ACTIVITY.check(v) then
			local av_type = CONF.ACTIVITY.get(v).TYPE
			local av_info = player:getActivity(v)
			if av_type == 1 then
				for i2,v2 in ipairs(CONF.ACTIVITYCHANGE.get(v).GROUP) do
					local conf = CONF.CHANGEITEM.get(v2)

					local limit_num = getLimitNum(av_info, v2)

					if limit_num < conf.LIMIT then
						local can = true
						for ii,vv in ipairs(conf.COST_ITEM) do
							if player:getItemNumByID(vv) < conf.COST_NUM[ii] then
								can = false
								break
							end
						end

						if can then
							return true
						end
					end
				
				end
			elseif av_type == 2 then
				for i2,v2 in ipairs(CONF.ACTIVITYRECHARGE.get(v).GROUP) do
					local conf = CONF.RECHARGEITEM.get(v2)

					if av_info ~= nil then
						if av_info.recharge_data.recharge_money >= conf.COST then
							if not getIsRecharge(av_info, v2) then
								return true
							end
						end
					end
				end
			elseif av_type == 3 then
				for i2,v2 in ipairs(CONF.ACTIVITYCONSUME.get(v).GROUP) do
					local conf = CONF.CONSUMEITEM.get(v2)

					if av_info ~= nil then
						if av_info.consume_data.consume >= conf.CONSUME then
							if not getIsConsume(av_info, v2) then
								return true
							end
						end
					end
				end
			elseif av_type == 4 then
				local regist_time = player:getRegistTime()


				local time = player:getServerTime() - regist_time

				local day_now = 0
				if time < 0 then
					day_now = 7
				else

					day_now = math.ceil(time / 86400)
				end
				for j=1,day_now do
					for i2,v2 in ipairs(CONF.ACTIVITYSEVENDAYS.get(v)["DAY"..j]) do
						if getSevenDay(av_info.seven_days_data, v2 ,player:getPlayerPlanetUser()) then
							return true
						end
					end
				end
				
			elseif av_type == 5 then
				for i2,v2 in ipairs(CONF.ACTIVITYONLINE.get(v).GROUP) do
					local conf = CONF.ONLINEGROUP.get(v2)

					-- if av_info ~= nil then
						if type(conf.TIME) ~= "table" then
							if player:getUserInfo().timestamp.today_online_time >= conf.TIME then
								if not getOnline(av_info, v2) then
									return true
								end
							end
						else 
							local hh = player:getServerDate().hour

							if hh >= conf.TIME[1] and hh <= conf.TIME[2] then
								if not getOnline(av_info, v2) then
									return true
								end
							end

						end
					-- end
				end
			elseif av_type == 10 then
				for i2,v2 in ipairs(CONF.ACTIVITYPOWER.get(v).GROUP) do
					local conf = CONF.POWERGROUP.get(v2)
					-- if av_info ~= nil then
						if player:getPower() >= conf.POWER then
							if not getIsPower(av_info, v2) then
								return true
							end
						end
					
					-- end
				end
			elseif av_type == 15 then
				local all_get = true
				for i,v in ipairs(CONF.ACTIVITYCHANGESHIP.get(v).CHANGE_LIST) do
					if player:getShipByID(v) == nil then
						all_get = false
						break
					end
				end

				if all_get then
					if not getIsSetIn(av_info) then

						return true
					end
				end
			elseif av_type == 14 then
				return getSignInToday(av_info)
			end
		end
	end

	return false
end
-- 任务红点
function CityUILayer:showTaskRed()
	local tasks = player:getTaskList()
	if Tools.isEmpty(tasks) then
		return false
	end
	for k,v in ipairs(tasks) do
		local conf = CONF.TASK.get(v.task_id)
		if conf.TYPE == 0 or conf.TYPE == 1 or conf.TYPE == 2 then
			local isOpen = player:IsTaskOpen(conf)
			if conf.TYPE == 1 then
				if player:getLevel() < CONF.PARAM.get("task_open").PARAM[1] or player:getBuildingInfo(1).level < CONF.PARAM.get("task_open").PARAM[2] then
					isOpen = false
				end 
			end
			local isAchieved = player:IsTaskAchieved(conf)
			if isOpen and isAchieved and not v.finished then
				return true
			end
		end
	end
	return false
end


--消息更新 ，红点显示，
function CityUILayer:receiveMessage(  )
	local open_node = self:getResourceNode():getChildByName("open_node"):getChildByName("node_open")
	local rn = self:getResourceNode()
	local eventDispatcher = self:getEventDispatcher()
	local strData = Tools.encode("GetMailListReq", {
		num = 0,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)

	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_ACTIVITY_LIST_REQ")," ")

	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_GET_ACTIVITY_LIST_RESP") then 
			local proto = Tools.decode("GetActivityListResp",strData)
			if proto.result ~= 0 then 
				print("GetActivityListResp error", proto.result)
			else 
				player:setPlayerActivityIDList(proto.id_list)

                print("@@@@@@@@@@Activity",type(self))
                self:iconOpen()
                self:HidActivityIcon(cc.exports.isHidActivityIcon)
                local iconlist = self:GetIconlist(rn:getChildByName("other_node"):getChildren())
                if Tools.isEmpty(iconlist) then
                    rn:getChildByName("activity_show_bt"):setVisible(false)
                else
                    rn:getChildByName("activity_show_bt"):setVisible(true)
                end
				-- self:getResourceNode():getChildByName("other_node"):getChildByName("huodong"):getChildByName("point"):setVisible(self:showAvRed(proto.id_list))
			end
		-- 未读邮件，及新邮件，显示红点提示
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_MAIL_LIST_UPDATE") then
			-- self.btnList[BTN_TAG.TAG_MAIL]:getChildByName("red"):setVisible(true)
			if rn:getChildByName("mail") then
				rn:getChildByName("mail"):getChildByName("point"):setVisible(true)
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_NEW_GROUP_UPDATE") then
			-- self.btnList[BTN_TAG.TAG_MAIL]:getChildByName("red"):setVisible(true)
			if rn:getChildByName("mail") then
				rn:getChildByName("mail"):getChildByName("point"):setVisible(true)
			end
			
			tips:tips(CONF:getStringValue("new_invite_mail"))

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_RESP") then
			local proto = Tools.decode("GetMailListResp",strData)
			if proto.result ~= 0 then
				print("proto error ",proto.result)  
			else  

				player.mail_list_ = proto.user_sync.mail_list
				-- self.btnList[BTN_TAG.TAG_MAIL]:getChildByName("red"):setVisible(false)
				if rn:getChildByName("mail") then
					rn:getChildByName("mail"):getChildByName("point"):setVisible(false)
				end
				for i,v in ipairs(proto.user_sync.mail_list) do
					if v.type == 0 or v.type == 2 or v.type == 10 or v.type == 4 then 
						-- self.btnList[BTN_TAG.TAG_MAIL]:getChildByName("red"):setVisible(true)
						if rn:getChildByName("mail") then
							rn:getChildByName("mail"):getChildByName("point"):setVisible(true)
						end
						break
					end
				end

				--好友请求 
				local hasApply = false
				for i,v in ipairs(player.mail_list_) do
					if v.type == 9 then
						hasApply = true
						break
					end
				end

				if hasApply == false then
					hasApply = player:isFriendReadTili(nil)
				end

				if rn:getChildByName("friend") then
					rn:getChildByName("friend"):getChildByName("point"):setVisible(false)
				end

				if hasApply then
					-- self.btnList[BTN_TAG.TAG_FRIEND]:getChildByName("red"):setVisible(true)
					if rn:getChildByName("friend") then
						rn:getChildByName("friend"):getChildByName("point"):setVisible(true)
					end
				else
					-- self.btnList[BTN_TAG.TAG_FRIEND]:getChildByName("red"):setVisible(false)
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ACTIVITY_FIRST_RECHARGE_RESP") then 
			gl:releaseLoading()

			local proto = Tools.decode("ActivityFirstRechargeResp",strData)

			print("ActivityFirstRechargeResp", proto.result)
			if proto.result ~= 0 then 
				print("ActivityFirstRechargeResp error", proto.result)
			else 
				rn:getChildByName("other_node"):getChildByName("shouchong"):setVisible(false)
                rn:getChildByName("Image_1"):setPosition(cc.p(rn:getChildByName("other_node"):getChildByName("shouchong"):getPosition()))
				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"))
				node:setPosition(cc.exports.VisibleRect:center())
				self:getParent():addChild(node,3)
				self:reSetOtherNode_posAndAction()
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_REWARD_RESP") then
			local proto = Tools.decode("TaskRewardResp",strData)
			if proto.other and proto.other == 1 then
				gl:releaseLoading()
				if proto.result ~= 0 then
					print("get task error :",proto.result)
				else
					self:createTaskBar()
					if proto.task_id > 0 then
						flurryLogEvent("task", {task_id = tostring(proto.task_id)}, 2)
                        if device.platform == "ios" or device.platform == "android" then
                            TDGAMission:onCompleted("Task:"..proto.task_id)
                        end
						local gold_num = 0
						local credit_num = 0
						for i,v in ipairs(CONF.TASK.get(proto.task_id).ITEM_ID) do
							if v == 3001 then
								gold_num = CONF.TASK.get(proto.task_id).ITEM_NUM[i]
								
							elseif v == 7001 then
								credit_num = CONF.TASK.get(proto.task_id).ITEM_NUM[i]
							end
						end
						flurryLogEvent("get_gold_by_task", {task_id = tostring(proto.task_id), gold_num = gold_num}, 1, gold_num)

						if credit_num > 0 then
							flurryLogEvent("get_credit_by_task", {task_id = tostring(proto.task_id), credit_num = credit_num}, 1, credit_num)
						end
					end

					if guideManager:getShowGuide() then
						if guideManager:getGuideType() then
							guideManager:doEvent("recv")
						end
					end
                    local taskConf = CONF.TASK.get(proto.task_id)
					local items = {}
					for i,v in ipairs(taskConf.ITEM_ID) do
						table.insert(items, {id = v, num = taskConf.ITEM_NUM[i]})
					end
					local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("getSucess"),items)
					node:setPosition(cc.p(display.cx,display.cy))
                    setScreenPosition(node,"leftbottom")
					rn:addChild(node)  

					cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("TaskUpdate")
				end
			end
			self:getResourceNode():getChildByName("mission"):getChildByName("point"):setVisible(self:showTaskRed())
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then
			local proto = Tools.decode("PlanetGetResp",strData)
			print("PlanetGetResp result",proto.result, proto.type)
			if not self.building13Click then return end
			if proto.result ~= 0 then
				print("error :",proto.result, proto.type)
			else
				if proto.type == 5 then
					local info = player:getPlanetElement()

					local english = {"a", "b", "c", "d", "e"}

					local station_amry_layer = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/otherNodeLayer/SeeStationedArmyLayer.csb")
					station_amry_layer:setName("station_amry_layer")
					station_amry_layer:getChildByName("title"):setString(CONF:getStringValue("team_browse"))
					station_amry_layer:getChildByName("close"):addClickEventListener(function ( ... )
						station_amry_layer:removeFromParent()
					end)
					station_amry_layer:getChildByName("wenzi"):setString(CONF:getStringValue("no fleet"))
					local svd = require("util.ScrollViewDelegate"):create(station_amry_layer:getChildByName("list"),cc.size(0,0), cc.size(662,143))
					station_amry_layer:getChildByName("list"):setScrollBarEnabled(false)
--                    require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQuanmianping_SeeStationedArmy(station_amry_layer)
					if info.type == 1 then

						local num = 0
						for i,v in ipairs(proto.mail_user_list) do

							local flag = true
							if v.info.user_name == info.base_data.info.user_name then
								flag = false
							end

							if flag then

								num = num + 1
								local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/otherNodeLayer/SeeStationedArmyNode.csb")
								node:getChildByName("army_num"):setString(CONF:getStringValue("Team "..english[num]))
								node:getChildByName("name"):setString(v.info.nickname)
								node:getChildByName("lv"):setString("Lv."..v.info.level)
								node:getChildByName("power"):setString(CONF:getStringValue("combat")..":"..v.info.power)

								node:getChildByName("lv"):setPositionX(node:getChildByName("name"):getPositionX() + node:getChildByName("name"):getContentSize().width)

								local item_pos = cc.p(node:getChildByName("item_pos"):getPosition())

								for i2,v2 in ipairs(v.ship_list) do
									local conf = CONF.AIRSHIP.get(v2.id)

									local ship_item = require("app.ExResInterface"):getInstance():FastLoad("Common/ItemNode.csb")
									ship_item:setScale(0.9)
									ship_item:getChildByName("icon"):loadTexture("RoleIcon/"..conf.ICON_ID..".png")
									ship_item:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..conf.QUALITY..".png")

									ship_item:getChildByName("icon"):addClickEventListener(function ( ... )
										-- local node = self:createInfoNode(v2)
										-- node:setPosition(cc.p(station_amry_layer:getChildByName("back"):getPositionX() - node:getChildByName("landi"):getContentSize().width/2, station_amry_layer:getChildByName("back"):getPositionY() + node:getChildByName("landi"):getContentSize().height/4 + 20))
										-- station_amry_layer:addChild(node)
									end)

									ship_item:setPosition(cc.p(item_pos.x + (i2-1)*80, item_pos.y))

									node:addChild(ship_item)
								end

								node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("disband"))
								if info.global_key ~= player:getPlayerPlanetUser().base_global_key then
									if v.info.user_name ~= player:getName() then
										node:getChildByName("btn"):setVisible(false)
									else
										node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("huicheng"))
									end
								end

								node:getChildByName("btn"):addClickEventListener(function ( ... )
									if player:getName() == Split(info.base_data.guarde_list[i], "_")[1] then
										local strData = Tools.encode("PlanetRideBackReq", {
											army_guid = {tonumber(Split(info.base_data.guarde_list[i], "_")[2])},
											type = 2,
										 })
										GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData)

										station_amry_layer:removeFromParent()
									else

										local strData = Tools.encode("PlanetRaidReq", {
											type_list = {8},
											element_global_key = info.global_key,
											army_key = info.base_data.guarde_list[i],
										 })
										GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RAID_REQ"),strData)

										station_amry_layer:removeFromParent()
									end
								end)

								svd:addElement(node)
							end
						end
						if num == 0 then
							station_amry_layer:getChildByName("wenzi"):setVisible(true)
						end
					end

					local function onTouchBegan(touch, event)

						return true
					end

					local function onTouchEnded(touch, event)
						
					end
					local listener = cc.EventListenerTouchOneByOne:create()
					listener:setSwallowTouches(true)
					listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
					listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
					local eventDispatcher = station_amry_layer:getEventDispatcher()
					eventDispatcher:addEventListenerWithSceneGraphPriority(listener, station_amry_layer)

					local xx,yy = getScreenDiffLocation()
--					station_amry_layer:setPosition(cc.p(-xx/2,-yy/2))
                    station_amry_layer:setPosition(cc.exports.VisibleRect:leftBottom())
--					display:getRunningScene():addChild(station_amry_layer)
                    rn:addChild(station_amry_layer)
					-- self:addChild(station_amry_layer, node_tag.kChoose)
					self.building13Click = false
				end

			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GUIDE_STEP_RESP") then

			local proto = Tools.decode("GuideStepResp",strData)
			if proto.result == 0 then
				self:openUI()
                self:HidActivityIcon(cc.exports.isHidActivityIcon)
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local   eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.rechargeListener_ = cc.EventListenerCustom:create("recharge", function ()
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_ACTIVITY_LIST_REQ")," ")
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.rechargeListener_, FixedPriority.kNormal)
end

function CityUILayer:addTouch(  )
	local rotatePanel = self:getResourceNode():getChildByName("RotatePanel")
	local function touchBegan( touch,event )
		 local rect = cc.rect(0, 0, 200, 200)
		 local point = rotatePanel:convertToNodeSpace(touch:getLocation())
		 if cc.rectContainsPoint(rect,point) then      
			  return true
		 end
		 return false
	end

	local function touchMoved( touch,event )
		if #self.itemList == 3 then
			return true
		end
		 
		 local point = touch:getDelta();--当前两点的增?
		 if math.abs(point.x) > math.abs(point.y) then
			if point.x > 0 then 
				self.dir = 3
				self.changeAngel = self.changeAngel + 3
			else 
				self.dir = -3
				self.changeAngel = self.changeAngel - 3
			end
		 else 
			if point.y > 0 then 
				self.dir = 3
				self.changeAngel = self.changeAngel + 3
			else 
				self.dir = -3
				self.changeAngel = self.changeAngel - 3
			end
		 end

		 self.angle=self.angle + self.dir;
		 if self.angle>360 then
			  self.angle=0;
			  elseif self.angle<0 then
				   self.angle=360;
		 end
		 self:updateUI(); 
	end

	if self.sumbtn >=5 then
		local lis = cc.EventListenerTouchOneByOne:create();
		local dispatcher = self:getEventDispatcher()
		lis:setSwallowTouches(true)
		lis:registerScriptHandler(touchBegan,cc.Handler.EVENT_TOUCH_BEGAN);
		lis:registerScriptHandler(touchMoved,cc.Handler.EVENT_TOUCH_MOVED);
		dispatcher:addEventListenerWithSceneGraphPriority(lis, rotatePanel);
	end
end
------信息提示--------------add by JinXin 20180713
function CityUILayer:IsGuideMode()
	if player:getGuideStep() < CONF.GUIDANCE.count() then
		return true
	end
	return false
end

function CityUILayer:findValueFromList(value,list)
    if list == nil then
        return -1
    end
    for k,v in ipairs(list) do
      if v == value then
        return k
      end
    end
    return -1
end

function CityUILayer:HideInfoKuang(node_arrows)
	if node_arrows == nil then
		return
	end
    node_arrows:stopAllActions()
	node_arrows:setVisible(false)
    local str = Split(self.buildingName_,"_")
    local num = tonumber(str[2])
    local k = self:findValueFromList(num,cc.exports.FirstTouchlist)
    if k ~= -1 then
        table.remove(cc.exports.FirstTouchlist,k)
    end
end

function CityUILayer:ShowInfoKuang(node_arrows)
    if node_arrows == nil then
		return
	end
    local str = Split(self.buildingName_,"_")
    local num = tonumber(str[2])
    local isShow = self:IsGuideMode() == false and systemGuideManager:getGuideType() == false and self:findValueFromList(num,cc.exports.FirstTouchlist) ~= -1
    node_arrows:setVisible(isShow)
    if isShow then
        node_arrows:setGlobalZOrder(1)
        animManager:runAnimByCSB(node_arrows, "GuideLayer/sfx/effect_0.csb", "1")
        if cc.exports.isQiangzheJiantouShowDone and cc.exports.qiangzhe_jiantou:isVisible() then
            cc.exports.qiangzhe_jiantou:setVisible(false)
        end
    end
end
-------------------------------------------------
function CityUILayer:updateUI(  )
	local rn = self:getResourceNode():getChildByName("RotatePanel"):getChildByName("rotateNode")
	if self.changeAngel and  math.abs(self.changeAngel) >= 45 then
		if self.changeAngel > 0 then 
			self.itemList[1]:removeFromParent()
			for i=1,4 do
				self.itemList[i] = self.itemList[i+1]
			end

			for i=1,5 do
				self.sita[i] = self.sita[i] - 45
			end

			self.head = (self.head + 1) % self.sumbtn
			if self.head == 0 then 
				self.head = self.sumbtn
			end

			local num 
			if self.head + 4 > self.sumbtn then 
				num =(self.head + 4)% self.sumbtn
			else
				num = self.head + 4
			end
			self.itemList[5] = self.btnList[num]  
			rn:addChild(self.itemList[5])
			self.itemList[5]:setScale(1)
			self.itemList[1]:setScale(0.1)
		else 
			 self.itemList[5]:removeFromParent()
			for i=5,2,-1 do
				self.itemList[i] = self.itemList[i-1]
			end

			for i=1,5 do
				self.sita[i] = self.sita[i] + 45
			end

			self.head = self.head - 1
			if self.head == 0 then  
				self.head = self.sumbtn
			end 
			self.itemList[1] = self.btnList[self.head]
			rn:addChild(self.itemList[1])
			self.itemList[1]:setScale(0.1)
		end
		self.changeAngel = 0
	end

	for i=1,#self.itemList do
		local r = self.angle + self.sita[i] 
		local offset = r%360 - 280 
		
		if offset > 0 then
			self.itemList[i]:setPositionY(self.center.y + self.r)

			if offset < 45 then 
				self.itemList[i]:setScale((45 - offset)/45)
			else 
				self.itemList[i]:setScale(0.1)
			end         
		else 
			self.itemList[i]:setPositionY(self.center.y - self.r * math.sin(math.rad(r)));
		end
		self.itemList[i]:setPositionX(self.center.x + self.r * math.cos(math.rad(r)));        
	end
	rn:getChildByName("circle"):setRotation(self.angle)
	--system_m_201
	rn:getChildByName("system_m_201"):setRotation(-self.angle)
end

function CityUILayer:updateTaskBar(dt)
	if self.firstTask_ == nil then
		return
	end
	self.firstTaskAchieved_ = player:IsTaskAchieved(self.firstTask_)
	self.firstTaskOpen_  = player:IsTaskOpen(self.firstTask_)
	local  rn  = self:getResourceNode():getChildByName("kt_node")
	if self.firstTaskOpen_ == false then 
		local str = " "
		if self.firstTask_.OPEN_LEVEL > player:getLevel() then 
			local s = string.gsub(CONF:getStringValue("level_open"),"#",self.firstTask_.OPEN_LEVEL)
			str = str .. s
		elseif self.firstTask_.OPEN_POWER > player:getPower() then
			local s = string.gsub(CONF:getStringValue("power_open"),"#",self.firstTask_.OPEN_POWER)
			str = str .. s
		end
		rn:getChildByName("task"):getChildByName("quick_1"):setString(handsomeSubString(str, 10))
		rn:getChildByName("task"):getChildByName("text"):setVisible(false)
        rn:getChildByName("task"):getChildByName("lingqu"):setVisible(false)
	    rn:getChildByName("task"):getChildByName("qianwang"):setVisible(true)
	else
		if self.firstTaskAchieved_ == true then 
			rn:getChildByName("task"):getChildByName("text"):setString(CONF:getStringValue("Get"))
			rn:getChildByName("task"):getChildByName("text"):setTextColor(cc.c4b(255, 255, 0, 255))
			rn:getChildByName("task"):loadTextures("CityScene/ui3/lingqu.png","CityScene/ui3/lingqu.png")
			rn:getChildByName("task"):getChildByName("Image_jian"):loadTexture("CityScene/ui3/jian1.png")
            rn:getChildByName("task"):getChildByName("lingqu"):setVisible(true)
	        rn:getChildByName("task"):getChildByName("qianwang"):setVisible(false)
        else
            rn:getChildByName("task"):getChildByName("lingqu"):setVisible(false)
	        rn:getChildByName("task"):getChildByName("qianwang"):setVisible(true)
		end
	end
end

function CityUILayer:createTaskBar()

	local function getNoTaskString( ... )

		local level = 0
		for i,v in ipairs(CONF.TASK.getIDList()) do
			local conf = CONF.TASK.get(v)
			if conf.TYPE == 0 then 
				if conf.OPEN_LEVEL > player:getLevel() then
					if level == 0 then
						level = conf.OPEN_LEVEL
					else
						if level > conf.OPEN_LEVEL then
							level = conf.OPEN_LEVEL
						end
					end
				end
		   	end
		end

		local str = ""
		if level == 0 then
			str = CONF:getStringValue("all task finish")	
		else
			str = CONF:getStringValue("hero")..CONF:getStringValue("level")..level..CONF:getStringValue("Can pick up")
		end

		return str
	end
	local  rn  = self:getResourceNode():getChildByName("kt_node")
	local taskBg = rn:getChildByName("task")	
	local taskList = player:getTaskList()
	--rn:getChildByName("task"):getChildByName("text"):setString(CONF:getStringValue("hint"))
	--rn:getChildByName("task"):getChildByName("text"):setTextColor(cc.c4b(255, 255, 255, 255))
	taskBg:getChildByName("quick_1"):setString(handsomeSubString(getNoTaskString(), 10))
	
	taskBg:getChildByName("lingqu"):setVisible(true)
	taskBg:getChildByName("qianwang"):setVisible(false)
	if Tools.isEmpty(taskList) then
		-- rn:getChildByName("task"):setVisible(false)
		return  
	end 
	--分组
	local groupList ={}
	for i,v in ipairs(taskList) do
		local conf = CONF.TASK.get(v.task_id)
		groupList[conf.GROUP] = groupList[conf.GROUP] or {}

		if conf.TYPE == 0 then
			table.insert(groupList[conf.GROUP] , conf)
		end
	end

	local function sort(a, b)

		local isOpenA = player:IsTaskOpen(a)
		local isOpenB = player:IsTaskOpen(b)
		if isOpenA == false and isOpenB == true then
			return false
		elseif isOpenA == true and isOpenB == false then
			return true
		else
			local isAchievedA = player:IsTaskAchieved(a)
			local isAchievedB = player:IsTaskAchieved(b)
			if isAchievedA == false and isAchievedB == true then
				return false
			elseif isAchievedA == true and isAchievedB == false then
				return true
			else
				if a.TYPE < b.TYPE then
					return true
				elseif a.TYPE > b.TYPE then
					return false
				else
					return a.ID < b.ID
				end
			end
		end
	end

	local tasks = {}
	for k,v in pairs(groupList) do
		table.sort(groupList[k], sort)
		table.insert(tasks , groupList[k][1])
	end
	table.sort( tasks, sort)
	for i,v in ipairs(tasks) do
		print("task",i, v.ID)
	end

	self.firstTask_ = tasks[1]

	taskBg:addClickEventListener(function ( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")
        if player:getLevel() < self.firstTask_.OPEN_LEVEL then
            local layer = self:getApp():createView("TaskScene/TaskScene",1)
		    self:addChild(layer)
            return
        end
		if not player:IsTaskAchieved(self.firstTask_) then
			if self.firstTask_ ~= nil then 
				local isAchieved = player:IsTaskAchieved(self.firstTask_)
				local isOpen = player:IsTaskOpen(self.firstTask_)
				if isAchieved == true or isOpen == false then
					-- self:getApp():addView2Top("TaskScene/TaskScene", 1)
					local layer = self:getApp():createView("TaskScene/TaskScene",1)
					layer:setPosition(cc.exports.VisibleRect:center())
					self:addChild(layer)
				else
					goScene( self.firstTask_.TURN_TYPE, self.firstTask_.TURN_ID )
				end
			else
				-- self:getApp():addView2Top("TaskScene/TaskScene", 1)
				local layer = self:getApp():createView("TaskScene/TaskScene",1)
				self:addChild(layer)
			end
		else
            cc.exports.clickTaskReward = true
			local id = self.firstTask_.ID
			local function func( ... )
				local strData = Tools.encode("TaskRewardReq", {
					task_id = id,
					other = 1,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_TASK_REWARD_REQ"),strData)
				gl:retainLoading()
			end
			if checkRewardBeMax(CONF.TASK.get(id).ITEM_ID, CONF.TASK.get(id).ITEM_NUM) then
				func()
			else
				local messageBox = require("util.MessageBox"):getInstance()

				messageBox:reset(CONF.STRING.get("resource upper").VALUE, func)
			end
		end
	end)
	--taskBg:loadTextures("CityScene/ui3/tishi.png","CityScene/ui3/tishi.png")
	if self.firstTask_ == nil then
		print("error: no task!")
		return
	end
	self.firstTaskAchieved_ = player:IsTaskAchieved(self.firstTask_)

	self.firstTaskOpen_  = player:IsTaskOpen(self.firstTask_)
	local taskName = CONF.STRING.get(self.firstTask_.NAME).VALUE
	if self.firstTask_.SHOW and self.firstTask_.SHOW == 1 then
		local value = self.firstTask_.VALUES
		if value[1] then
			local vv = value[1]
			if self.firstTask_.TARGET_1 == 2 and self.firstTask_.TARGET_2 == 3 then
				vv = CONF:getStringValue("BuildingName_"..value[1])
			elseif self.firstTask_.TARGET_1 == 3 and self.firstTask_.TARGET_2 == 3 then
				vv = CONF:getStringValue("HomeBuildingName_"..value[1])
			elseif self.firstTask_.TARGET_1 == 6 and self.firstTask_.TARGET_2 == 3 then
				vv = CONF:getStringValue("ARENA_TITLE_"..value[1])
			elseif self.firstTask_.TARGET_1 == 1 and self.firstTask_.TARGET_2 == 1 then
				vv = CONF:getStringValue("Level_N"..value[1])
			end
			taskName = string.gsub(taskName,"#",vv)
		end
		if value[2] then
			taskName = string.gsub(taskName,"*",value[2])
		end
		if value[3] then
			taskName = string.gsub(taskName,"&",value[3])
		end
	end
	local quickName = taskBg:getChildByName("quick_1")
	quickName:setString(handsomeSubString(taskName, 10))

	if taskBg:getChildByName("task_open_label") then
		taskBg:getChildByName("task_open_label"):removeFromParent()
	end

	if taskBg:getChildByName("spr_yes") then
		taskBg:getChildByName("spr_yes"):removeFromParent()
	end
	taskBg:getChildByName("Image_jian"):loadTexture("CityScene/ui3/jian2.png")
	--askBg:getChildByName("text"):setVisible(true)
	if self.firstTaskOpen_ == false then 
		local str = " "
		if self.firstTask_.OPEN_LEVEL > player:getLevel() then 
			local s = string.gsub(CONF:getStringValue("level_open"),"#",self.firstTask_.OPEN_LEVEL)
			str = str .. s
		elseif self.firstTask_.OPEN_POWER > player:getPower() then
			local s = string.gsub(CONF:getStringValue("power_open"),"#",self.firstTask_.OPEN_POWER)
			str = str .. s
		end

		-- local label = cc.Label:createWithTTF(str, "fonts/cuyabra.ttf", 19)
		-- label:setName('task_open_label')
		-- label:setAnchorPoint(cc.p(0,0.5))
		-- label:setPosition(cc.p(quickName:getPositionX() + quickName:getContentSize().width , quickName:getPositionY()))
		-- label:setTextColor(cc.c4b(255, 145, 136, 255))
		-- label:enableShadow(cc.c4b(255, 145, 136, 255),cc.size(0.5,0.5))
		-- taskBg:addChild(label)
		quickName:setString(handsomeSubString(str, 10))
		-- taskBg:getChildByName("text"):setVisible(false)
		rn:getChildByName("task"):getChildByName("text"):setString(CONF:getStringValue("hint"))
		taskBg:getChildByName("lingqu"):setVisible(false)
		taskBg:getChildByName("qianwang"):setVisible(true)
	else
		if self.firstTaskAchieved_ == true then 
			--rn:getChildByName("task"):getChildByName("text"):setString(CONF:getStringValue("Get"))
			--rn:getChildByName("task"):getChildByName("text"):setTextColor(cc.c4b(255, 255, 0, 255))
			--taskBg:loadTextures("CityScene/ui3/lingqu.png","CityScene/ui3/lingqu.png")
			taskBg:getChildByName("Image_jian"):loadTexture("CityScene/ui3/jian1.png")
			taskBg:getChildByName("lingqu"):setVisible(true)
			taskBg:getChildByName("qianwang"):setVisible(false)
        else
            taskBg:getChildByName("lingqu"):setVisible(false)
			taskBg:getChildByName("qianwang"):setVisible(true)
		end
	end
	-- if self.firstTaskOpen_ then
	--	taskBg:getChildByName("sfx"):setVisible(true)
	--	animManager:runAnimByCSB(taskBg:getChildByName("sfx"), "CityScene/sfx/new UIeffect/di.csb" ,"1")
	-- end
end


function CityUILayer:ClickPlanet()
	local rn = self:getResourceNode()
	for i,v in ipairs(CONF.OPEN_ICON.getIDList()) do
		local conf = CONF.OPEN_ICON.get(v)
		if conf.CONDITION == 4 then
			for k,v1 in ipairs(conf.BUILDING) do
				if v1 == 210 then
					local fun_cfg = CONF.FUNCTION_OPEN.get("planet_open")
					if fun_cfg then
						if player:getLevel() < fun_cfg.GRADE then
							--local tipStr = CONF:getStringValue("planetOccupation").."\n"
							--tipStr = tipStr .. CONF:getStringValue("levelNum") .. tostring(fun_cfg.GRADE) .. CONF:getStringValue("open") .."\n"
							--tips:tips(tipStr)
							return false
						else
							local confsys = CONF.SYSTEM_GUIDANCE.get(conf.COUNT)
							if confsys then
								local id = math.floor(confsys.SAVE/100)
								print("ClickPlanet",id)
								if player:getSystemGuideStep(id) == 0  then
									if fun_cfg.OPEN_GUIDANCE == 1 then
										systemGuideManager:createGuideLayer(fun_cfg.INTERFACE)
									end
									rn:getChildByName("planet"):getChildByName("suo_icon"):setVisible(false)
									rn:getChildByName("planet"):getChildByName("jihuo"):setVisible(false)
									rn:getChildByName("sfx"):setVisible(true)
                                    cc.exports.isjihuoplanet = true
								end		
							end
						end
					end
					return true
				end
			end
		end
	end

	return true
end

function CityUILayer:iconOpen()
	local rn = self:getResourceNode()
	rn:getChildByName("totalNode"):setVisible(false)
	rn:getChildByName("kt_node"):getChildByName("task"):setVisible(false)
	rn:getChildByName("zc_bottom_chat_34"):setVisible(false)
	rn:getChildByName("chat_img"):setVisible(false)
	rn:getChildByName("di_text"):setVisible(false)
	rn:getChildByName("chat"):setVisible(false)
	rn:getChildByName("league"):setVisible(false)
	rn:getChildByName("form"):setVisible(false)
	rn:getChildByName("mission"):setVisible(false)
	rn:getChildByName("backpack"):setVisible(false)
	rn:getChildByName("mail"):setVisible(false)
    rn:getChildByName("ship"):setVisible(false)
	rn:getChildByName("friend"):setVisible(false)
	rn:getChildByName("sfx"):setVisible(false)
	rn:getChildByName("planet"):setVisible(false)
	rn:getChildByName("arena"):setVisible(false)
	rn:getChildByName("trial"):setVisible(false)
    rn:getChildByName("other_node"):getChildByName("strong"):setVisible(not self:IsGuideMode())
	rn:getChildByName("other_node"):getChildByName("huodong"):setVisible(false)
	rn:getChildByName("other_node"):getChildByName("shouchong"):setVisible(false)
	rn:getChildByName("other_node"):getChildByName("gift"):setVisible(false)
	rn:getChildByName("other_node"):getChildByName("sevenDay"):setVisible(false)
    rn:getChildByName("other_node"):getChildByName("awardonline"):setVisible(true)
    rn:getChildByName("other_node"):getChildByName("growthfund"):setVisible(false)
    rn:getChildByName("other_node"):getChildByName("invest"):setVisible(false)
    rn:getChildByName("other_node"):getChildByName("changeship"):setVisible(false)
    rn:getChildByName("other_node"):getChildByName("everyday"):setVisible(false)
    rn:getChildByName("other_node"):getChildByName("propconvert"):setVisible(false)
    rn:getChildByName("other_node"):getChildByName("luckywheel"):setVisible(false)
    rn:getChildByName("other_node"):getChildByName("advancedgift"):setVisible(false)
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
			local confsys = CONF.SYSTEM_GUIDANCE.get(conf.COUNT)
			if confsys then
				local id = math.floor( confsys.SAVE/100)
				if player:getSystemGuideStep(id) == 0  then
					if math.floor(systemGuideManager:getSelfGuideID()/100) == math.floor(conf.COUNT/100) then
						if systemGuideManager:getSelfGuideID()>=conf.COUNT then
							show = true
						end
					end
				else
					show = true
				end
			else
				show = true
			end
		elseif conf.CONDITION == 3 then
			if player:getBuildingInfo(1).level >= conf.COUNT then
				show = true
			end
		end

        local function isfindActivityID(key)
            local isfind = false
            if Tools.isEmpty(player:getPlayerActivityIDList()) == false then
				for i,v in ipairs(player:getPlayerActivityIDList()) do
					if key == v then
						isfind = true
						break
					end
				end
			end
            return isfind
        end

		if show then
			for k,v1 in ipairs(conf.BUILDING) do
				if v1 == 201 then
					rn:getChildByName("totalNode"):setVisible(show)
				elseif v1 == 202 then
					rn:getChildByName("kt_node"):getChildByName("task"):setVisible(show)
				elseif v1 == 203 then
					rn:getChildByName("zc_bottom_chat_34"):setVisible(show)
					rn:getChildByName("chat_img"):setVisible(show)
					rn:getChildByName("di_text"):setVisible(show)
					rn:getChildByName("chat"):setVisible(show)
				elseif v1 == 204 then
					rn:getChildByName("league"):setVisible(show)
				elseif v1 == 205 then
					rn:getChildByName("form"):setVisible(show)
				elseif v1 == 206 then
					rn:getChildByName("mission"):setVisible(show)
				elseif v1 == 207 then
					rn:getChildByName("backpack"):setVisible(show)
				elseif v1 == 208 then
					rn:getChildByName("mail"):setVisible(show)
                elseif v1 == 102 then -- jiku
                    rn:getChildByName("ship"):setVisible(show)
				elseif v1 == 209 then
					rn:getChildByName("friend"):setVisible(show)
				elseif v1 == 210 then
					rn:getChildByName("sfx"):setVisible(show)
					rn:getChildByName("planet"):setVisible(show)
                    cc.exports.isjihuoplanet = true
				elseif v1 == 211 then -- 变强

				elseif v1 == 212 then -- 奇遇礼包

				elseif v1 == 213 then
					rn:getChildByName("other_node"):getChildByName("huodong"):setVisible(show)
				elseif v1 == 214 and not player:isGetFirstRechargeReward() then
					rn:getChildByName("other_node"):getChildByName("shouchong"):setVisible(show)
				elseif v1 == 215 then
					if Tools.isEmpty(player:getGiftData()) == false then
						rn:getChildByName("other_node"):getChildByName("gift"):setVisible(show)
					end
				elseif v1 == 216 then
					rn:getChildByName("arena"):setVisible(show)
				elseif v1 == 217 then
					rn:getChildByName("trial"):setVisible(show)
				elseif v1 == 218 then
					local  haveSevenDay = isfindActivityID(4001)
					if show then
						rn:getChildByName("other_node"):getChildByName("sevenDay"):setVisible(haveSevenDay)
					end
                elseif v1 == 219 then
                    local havegrowthfund = isfindActivityID(12001)
					if show then
--						rn:getChildByName("other_node"):getChildByName("growthfund"):setVisible(havegrowthfund)
					end
                elseif v1 == 220 then
                    local haveinvest = isfindActivityID(13001)
					if show then
						rn:getChildByName("other_node"):getChildByName("invest"):setVisible(haveinvest)
					end
                elseif v1 == 221 then
--                    local changeship = isfindActivityID(15001)
--                    if show then
--                        local info = player:getActivity(15001)
--                        if info ~= nil and info.change_ship_data.getted_reward then
--                            rn:getChildByName("other_node"):getChildByName("changeship"):setVisible(false)
--                        else
--                            rn:getChildByName("other_node"):getChildByName("changeship"):setVisible(changeship)
--                        end
--					end
                elseif v1 == 222 then
                    local everyday = isfindActivityID(17001)
					if show then
						rn:getChildByName("other_node"):getChildByName("everyday"):setVisible(everyday)
					end
                elseif v1 == 225 then
                    local propconvert = isfindActivityID(20001)
					if show then
--						rn:getChildByName("other_node"):getChildByName("propconvert"):setVisible(propconvert)
					end
                elseif v1 == 223 then
                    local luckywheel = isfindActivityID(18001)
					if show then
						rn:getChildByName("other_node"):getChildByName("luckywheel"):setVisible(luckywheel)
					end
                elseif v1 == 224 then
                    local advancedgift = isfindActivityID(19001)
					if show then
						rn:getChildByName("other_node"):getChildByName("advancedgift"):setVisible(advancedgift)
					end
				end

			end
		else
			for k,v1 in ipairs(conf.BUILDING) do
				if v1 == 210 then
					if guide >= CONF.GUIDANCE.len then
						local fun_cfg = CONF.FUNCTION_OPEN.get("planet_open")
						if fun_cfg then
							if player:getLevel() >= fun_cfg.GRADE then
								rn:getChildByName("sfx"):setVisible(false)
								rn:getChildByName("planet"):setVisible(true)
								rn:getChildByName("planet"):getChildByName("suo_icon"):setVisible(false)
								rn:getChildByName("planet"):getChildByName("jihuo"):setVisible(true)
								animManager:runAnimByCSB(rn:getChildByName("planet"):getChildByName("jihuo"), "CityScene/BtnActivateNode.csb", "1")
							else
								rn:getChildByName("sfx"):setVisible(false)
								rn:getChildByName("planet"):setVisible(true)
								rn:getChildByName("planet"):getChildByName("suo_icon"):setVisible(true)
							end
						end
					end
				end
			end
		end
	end
end

function CityUILayer:GetIconlist(node_children)
    local iconlist = {}
    for k,v in pairs(node_children) do
        if v:isVisible() then
            if v:getName() ~= "strong" and v:getName() ~= "shouchong" then
                table.insert(iconlist ,v:getName())
            end
        end
    end
    return iconlist
end

function CityUILayer:HidActivityIcon(isHid)
    local rn = self:getResourceNode()
    local node_children = rn:getChildByName("other_node"):getChildren()
    local iconlist = self:GetIconlist(node_children)
    if isHid then
        if Tools.isEmpty(iconlist) == false then
            for k,v in pairs(iconlist) do
                rn:getChildByName("other_node"):getChildByName(v):setOpacity(0)
                if rn:getChildByName("other_node"):getChildByName(v):getChildByName("bg") then
                    rn:getChildByName("other_node"):getChildByName(v):getChildByName("bg"):setEnabled(false)
                end
            end
        end
        local nameTab = {"strong"}
        for k,v in pairs(nameTab) do
            rn:getChildByName("other_node"):getChildByName(v):setPosition(other_node_pos[k][1],other_node_pos[k][2])
        end
        -- 奇遇礼包
        if not player:isGetFirstRechargeReward() then
            rn:getChildByName("Image_1"):setOpacity(0)
            rn:getChildByName("Image_1"):setEnabled(false)
        end
    else
        self:reSetOtherNode_posAndAction()
        if Tools.isEmpty(iconlist) == false then
            for k,v in pairs(iconlist) do
                rn:getChildByName("other_node"):getChildByName(v):setOpacity(255)
                if rn:getChildByName("other_node"):getChildByName(v):getChildByName("bg") then
                    rn:getChildByName("other_node"):getChildByName(v):getChildByName("bg"):setEnabled(true)
                end
            end
        end

        if not player:isGetFirstRechargeReward() then
            rn:getChildByName("Image_1"):setOpacity(255)
            rn:getChildByName("Image_1"):setEnabled(true)
        end
    end
end

function CityUILayer:setState(  )
	local rn = self:getResourceNode()
	local function judge( name )
		local node = rn:getChildByName(name)
		local isOpen, heroLevel, centreLevel = IsFuncOpen(name)

		node:addTouchEventListener(function ( sender, eventType )
			if cc.exports.g_activate_building then
				return
			end
			if isOpen == false then
				local tipStr = ""
				if heroLevel ~= 0 then 
					tipStr = tipStr .. CONF:getStringValue("levelNum") .. tostring(heroLevel) .. "\n"
				end
				if centreLevel ~= 0 then 
					tipStr = tipStr .. CONF:getStringValue("CentreLevel") .. CONF:getStringValue("achieve") .. tostring(centreLevel)
				end

				tips:tips(tipStr)
			else
				if eventType == ccui.TouchEventType.began then
					playEffectSound("sound/system/click.mp3")
				elseif eventType == ccui.TouchEventType.moved then
				elseif eventType == ccui.TouchEventType.ended then
					if name == "planet" then
						if self:ClickPlanet() then
							-- self:getApp():pushToRootView("PlanetScene/PlanetScene", {come_in_type = 1})
--                                    local enteranim = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/sfx/enteranim/enteranim.csb")
--		                            animManager:runAnimOnceByCSB(enteranim,"PlanetScene/sfx/enteranim/enteranim.csb" ,"1", function ( )
--                                        enteranim:removeFromParent()
--                                        self:getApp():addView2Top("CityScene/TransferScene",{from = "planet" ,state = "start"})
                                        --app:pushToRootView("PlanetScene/PlanetScene", {come_in_type = 1,sfx = true})
                                        self:getApp():pushToRootView("CityScene/TransferScene",{from = "planet" ,state = "start"})
--                                    end)
--                                    enteranim:setName("enteranim")
--                                    local center = cc.exports.VisibleRect:center()
--                                    enteranim:setPosition(cc.p(center.x + (rn:getContentSize().width/2 - center.x), center.y + (rn:getContentSize().height/2 - center.y)))
--		                            rn:addChild(enteranim)
						end
					elseif name == "league" then
						self:getApp():pushView("StarLeagueScene/StarLeagueScene")
					elseif name == "form" then
						self:getApp():addView2Top("NewFormLayer", {from = "special",scene = "ShipsScene"})
					elseif name == "friend" then
						local layer = self:getApp():createView("FriendLayer/FriendLayer", {has = rn:getChildByName("friend"):getChildByName("point"):isVisible()})
						self:getParent():addChild(layer)
					elseif name == "mail" then

					elseif name == "mission" then

					elseif name == "backpack" then 
					end

				elseif eventType == ccui.TouchEventType.canceled then
					--rn:getChildByName(string.format("%s_light", name)):setVisible(false)
				end      		
			end
		end)
	end 

	judge("planet")
	judge("league")
	judge("form")
	judge("friend");
end

function CityUILayer:reSetOtherNode_posAndAction(name)
	local other_node = self:getResourceNode():getChildByName("other_node")
--	local nameTab = {"strong","huodong","daily_task","advancedgift","shouchong","gift","sevenDay","growthfund","invest","changeship","everyday","propconvert","luckywheel"}
	local nameTab = {"strong","huodong","sevenDay","awardonline","advancedgift","gift","invest","everyday","luckywheel"}
    other_node:getChildByName("daily_task"):setVisible(false)
	other_node:getChildByName("shop"):setVisible(false)
	local canSee_node = {}
	for i=1,#nameTab do
		local see = other_node:getChildByName(nameTab[i]):isVisible()
		if see then
			table.insert(canSee_node,i)
		end
	end
	if name == nil then
		for k,v in ipairs(canSee_node) do
			other_node:getChildByName(nameTab[v]):setPosition(other_node_pos[k][1],other_node_pos[k][2])
		end
	end

	local nameTab2 = {"backpack","ship","mission","league","friend","form","arena","trial"}
	local canSee_node2 = {}
	for i=1,#nameTab2 do
		local see = self:getResourceNode():getChildByName(nameTab2[i]):isVisible()
		if see then
			table.insert(canSee_node2,i)
		end
	end
    --------- add by jinxin 20180726
    if self.isOpenRetract and #canSee_node2 > 3 then
        self.isShow = true
        self:getResourceNode():getChildByName("more"):setVisible(self.isShow)
        self:getResourceNode():getChildByName("Node_retract"):setVisible(false)
        self.Retract_node = canSee_node2
        if cc.exports.Retractnode_Isshow == nil then
            cc.exports.Retractnode_Isshow = true
        end

        for k,v in ipairs(self.Retract_node) do
		    self:getResourceNode():getChildByName(nameTab2[v]):setPosition(other_node_pos2[k][1] - 86.93,other_node_pos2[k][2])
	    end
--        self:getResourceNode():getChildByName("Node_retract"):setPosition(other_node_pos2[4][1],other_node_pos2[4][2])
--        self:getResourceNode():getChildByName("Node_retract"):setOpacity(0)
        local OpacityValue,txt,uistr
--        local ScaleX = 1
        if cc.exports.Retractnode_Isshow then
--            ScaleX = -1
            OpacityValue = 255
            txt = CONF:getStringValue("take_up")
            uistr = "CityScene/ui3/icon_packup.png"
        else
--            ScaleX = 1
            OpacityValue = 0
            txt = CONF:getStringValue("more")
            uistr = "CityScene/ui3/icon_more.png"
        end
--        self:getResourceNode():getChildByName("more"):getChildByName("more"):setScaleX(ScaleX)
        self:getResourceNode():getChildByName("more"):getChildByName("text_miao"):setString(txt)
        self:getResourceNode():getChildByName("more"):getChildByName("more"):loadTexture(uistr)
        self.RetractTab = {"league","friend","form","arena","trial"}
        for k,v in pairs(self.RetractTab) do
            self:getResourceNode():getChildByName(v):setOpacity(OpacityValue)
            self:getResourceNode():getChildByName(v):setEnabled(cc.exports.Retractnode_Isshow)
        end

    else
        self.isShow = false
        self:getResourceNode():getChildByName("Node_retract"):setVisible(self.isShow)
        self:getResourceNode():getChildByName("more"):setVisible(self.isShow)
        for k,v in ipairs(canSee_node2) do
		    self:getResourceNode():getChildByName(nameTab2[v]):setPosition(other_node_pos2[k][1],other_node_pos2[k][2])
	    end
    end
    ------------------------------------
end

function CityUILayer:onExitTransitionStart()

	printInfo("CityUILayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.rechargeListener_)
	eventDispatcher:removeEventListener(self.normaltasklistener_)
	eventDispatcher:removeEventListener(self.dailytasklistener_)
	eventDispatcher:removeEventListener(self.maintasklistener_)
	eventDispatcher:removeEventListener(self.guideListener_)
	eventDispatcher:removeEventListener(self.levelupListener_)
	eventDispatcher:removeEventListener(self.updateCityActivityPoint)

	-- for i,v in ipairs(self.btnList) do
	-- 	v:release()
	-- end

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil
	end
	if schedulerEntry_Adventure ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry_Adventure)
		schedulerEntry_Adventure = nil
	end

    if self.retractscheduler ~= nil then
	    scheduler:unscheduleScriptEntry(self.retractscheduler)
	    self.retractscheduler = nil
	end
end

function CityUILayer:getIsBuildingOn()
	return self.isBuildingOn_
end

function CityUILayer:switchBuildingBtn(flag, name, pos, scale)
	if cc.exports.g_activate_building then
		return
	end

	local infoNode_last = nil


	local isOpen, heroLevel, centreLevel
	if name == "building_10" then
		isOpen, heroLevel, centreLevel = IsFuncOpen("city_10")
	elseif name == "building_11" then 
		isOpen, heroLevel, centreLevel = IsFuncOpen("city_11")
	elseif name == "building_13" then 
		isOpen, heroLevel, centreLevel = IsFuncOpen("city_13")
	elseif name == "building_14" then
		isOpen, heroLevel, centreLevel = IsFuncOpen("city_14")
	elseif name == "building_16" then
		isOpen, heroLevel, centreLevel = IsFuncOpen("city_16")
	end 
	if isOpen ~= nil and heroLevel ~= nil and centreLevel ~= nil then
		if isOpen == false then
			local tipStr = ""
			if heroLevel ~= 0 then 
				tipStr = tipStr .. CONF:getStringValue("levelNum") .. tostring(heroLevel) .. "\n"
			end
			if centreLevel ~= 0 then 
				tipStr = tipStr .. CONF:getStringValue("CentreLevel") .. CONF:getStringValue("achieve") .. tostring(centreLevel)
			end

			tips:tips(tipStr)
			return
		end
	end
	self.isBuildingOn_ = flag
	self.buildingName_ = name

	local rn = self:getResourceNode()
	local userInfoNode = rn:getChildByName("info_node"):getChildByName("userInfoNode")
	print("userInfoNode is ", userInfoNode);
	-- animManager:runAnimOnceByCSB(self:getResourceNode(), "CityScene/UILayer.csb", flag and "building_on" or "building_off")

	if flag == false then
		if rn:getChildByName("infoNode") ~= nil then
			rn:getChildByName("infoNode"):removeFromParent()
		end
		
		if player:getGuideStep() >= CONF.GUIDANCE.len then
            if self.isShow then ---------缩进
                rn:getChildByName("more"):setVisible(true)
            end
			rn:getChildByName("form"):setVisible(true)
			--rn:getChildByName("trial"):setVisible(true)
			--rn:getChildByName("arena"):setVisible(true)
			rn:getChildByName("mission"):setVisible(true)
			rn:getChildByName("friend"):setVisible(true)
			rn:getChildByName("backpack"):setVisible(true)
			rn:getChildByName("mail"):setVisible(true)
            rn:getChildByName("ship"):setVisible(true)
			rn:getChildByName("trial"):setVisible(true)
			rn:getChildByName("arena"):setVisible(true)
			rn:getChildByName("league"):setVisible(true)	
			-- rn:getChildByName("Image_2"):setVisible(true)	
			rn:getChildByName("zc_bottom_chat_34"):setVisible(true)		
			rn:getChildByName("chat_img"):setVisible(true)		
			rn:getChildByName("di_text"):setVisible(true)	
			rn:getChildByName("chat"):setVisible(true)
			rn:getChildByName("planet"):setVisible(true)
			rn:getChildByName("sfx"):setVisible(true)
			rn:getChildByName("kt_node"):setVisible(true)
			rn:getChildByName("Image_1"):setVisible(false);
			userInfoNode:setAdventureShow(true);
		end
		self:iconOpen()
        self:HidActivityIcon(cc.exports.isHidActivityIcon)
		for i=1,CONF.EBuilding.count do
			self:getParent():getResourceNode():getChildByName("text_"..i):runAction(cc.ScaleTo:create(0.1, 1))
		end
	else
		if rn:getChildByName("open_node"):getChildByName("node_open"):isVisible() then
			rn:getChildByName("open_node"):getChildByName("node_open"):setVisible(false)

			--rn:getChildByName("zhankai"):loadTexture("Common/newUI/zc_button_zk.png")
			--rn:getChildByName("zhankai"):setTag(309)
		end

		if rn:getChildByName("other_node"):isVisible() then
			rn:getChildByName("other_node"):setVisible(false)
		end
        if self.isShow then
            rn:getChildByName("more"):setVisible(false)
        end
		rn:getChildByName("form"):setVisible(false)
		--rn:getChildByName("trial"):setVisible(false)
		--rn:getChildByName("arena"):setVisible(false)
		rn:getChildByName("mission"):setVisible(false)
		rn:getChildByName("friend"):setVisible(false)
		rn:getChildByName("backpack"):setVisible(false)
		rn:getChildByName("mail"):setVisible(false)
        rn:getChildByName("ship"):setVisible(false)
		rn:getChildByName("league"):setVisible(false)	
		-- rn:getChildByName("Image_2"):setVisible(false)	
		rn:getChildByName("zc_bottom_chat_34"):setVisible(false)		
		rn:getChildByName("chat_img"):setVisible(false)		
		rn:getChildByName("di_text"):setVisible(false)	
		rn:getChildByName("chat"):setVisible(false)		
		rn:getChildByName("planet"):setVisible(false)
		rn:getChildByName("sfx"):setVisible(false)
		rn:getChildByName("trial"):setVisible(false)
		rn:getChildByName("arena"):setVisible(false)
		rn:getChildByName("kt_node"):setVisible(false)
		rn:getChildByName("Image_1"):setVisible(false);	
		userInfoNode:setAdventureShow(false);
	end

	------------------------------------------------------
		self:_print(string.format("@@@@ BuildingInfo.csb self.buildingName_ : %s ", tostring(name or " NIL!") ) )
		
		local isBug = self.guideHelper:OnBug_JIAN_ZHU_AN_NIU_DUO_YU(require("app.views.GuideLayer.GuideManager"):getInstance().guide_id, name)
		if( isBug ) then
			do return end
		end
	------------------------------------------------------

	if name == "building_2" or name == "building_8"  or name == "building_6" or name == "building_9" or name == "building_15" then
		if self.buildingName_ == nil then
			return
		end

			-- ADD WJJ 10705 no suo xiao
		-- self:runAction(cc.Sequence:create(cc.DelayTime:create(0.4), cc.CallFunc:create(function (sender)
				
			if self.buildingName_ == "building_2" then
				print(" go ShipsDevelopScene at 1906 CityUILayer ")

				-- ADD WJJ 180702
				if( self.IS_SCENE_TRANSFER_EFFECT ) then
					self.lagHelper:BeginTransferEffect("CitySceneGoShipsForm")
				else
					self:getApp():pushView("ShipsScene/ShipsDevelopScene",{type = 5})
				end
				-- self:getApp():pushView("ShipsScene",{type = player:getTypeToShipsScene()})
			elseif self.buildingName_ == "building_9" then
				self:getApp():addView2Top("CityScene/TransferScene",{from = "ChapterScene" ,state = "start"})
				-- self:getApp():pushToRootView("ChapterScene")
				
			elseif self.buildingName_ == "building_6" then
				if player:getBuildingInfo(CONF.EBuilding.kHome).level >= CONF.PARAM.get("city_1_open").PARAM[2] and player:getLevel() >= CONF.PARAM.get("city_1_open").PARAM[2] then
					-- self:getApp():pushView("HomeScene/HomeScene",{})
					self:getApp():addView2Top("CityScene/TransferScene",{from = "home" ,state = "start"})
				else
					tips:tips(CONF:getStringValue("main level not enought"))
				end
			elseif self.buildingName_ == "building_8" then
				self:getApp():pushView("LotteryScene/LotteryScene")
			elseif self.buildingName_ == "building_15" then
				self:getApp():pushView("TradeScene/TradeScene")

			end

		-- end)))
		-- end of 1906 runaction , wjj

	elseif name == "building_10" then
		if self.buildingName_ == nil then
			return
		end
		
		self:_print("@@@@ BuildingInfo.csb building_10")

		local infoNode = require("app.ExResInterface"):getInstance():FastLoad("CityScene/BuildingInfo.csb")
		infoNode_last = infoNode


		infoNode:setPosition(pos)
		infoNode:getChildByName("upgrade"):getChildByName("text"):setString(CONF:getStringValue("upgrade"))
		infoNode:getChildByName("function"):getChildByName("text"):setString(CONF:getStringValue("function"))
		infoNode:getChildByName("info"):getChildByName("text"):setString(CONF:getStringValue("information"))
		
		-- infoNode:getChildByName("upgrade"):getChildByName("point"):setVisible(player:canUpgradeBuilding(tonumber(string.match(self.buildingName_,"(%d+)"))))
		infoNode:getChildByName("function"):setVisible(false)
		infoNode:getChildByName("upgrade"):getChildByName("point"):setVisible(player:canUpgradeBuilding(tonumber(string.match(self.buildingName_,"(%d+)"))));

		infoNode:getChildByName("upgrade"):addClickEventListener(function () 
			playEffectSound("sound/system/click.mp3")
			self:getApp():pushView("BuildingUpgradeScene/BuildingUpgradeScene", {building_num = CONF.EBuilding.kWarehouse})

		end)
		infoNode:getChildByName("function"):addClickEventListener(function () 
			playEffectSound("sound/system/click.mp3")

		end)
        self:ShowInfoKuang(infoNode:getChildByName("node_arrows"))
		infoNode:getChildByName("info"):addClickEventListener(function () 
            ------------add by JinXin----------------
		    self:HideInfoKuang(infoNode:getChildByName("node_arrows"))
            -----------------------------------------
			playEffectSound("sound/system/click.mp3")
			local layer = self:getApp():createView("CityScene/BuildInfo",  { BuildName = name})
			self:addChild(layer)
		end)

		infoNode:getChildByName("mid"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/click.mp3")
			infoNode:removeFromParent()

			-- no scale effect, wjj 180705
			--[[

			for i=1,CONF.EBuilding.count do
				local node = self:getParent():getResourceNode()
				local child = node:getChildByName(string.format("text_%d", i))
				if child ~= nil then
					child:runAction(cc.ScaleTo:create(0.1, 1))
				end
			end
			]]

			self:switchBuildingBtn(false, "")
		end)

		-- infoNode:getChildByName("info"):setVisible(false)

		rn:addChild(infoNode)
		infoNode:setName("infoNode")


		self:ScaleOpenBuildingMenu(infoNode)
		-- infoNode:setScale(0)
		-- infoNode:runAction(cc.Sequence:create(cc.DelayTime:create(0.4), cc.ScaleTo:create(0.1,scale)))
	elseif name == "building_15" then
		

	elseif name == "building_1" or name == "building_3" or name == "building_4" or name == "building_5" or name == "building_1_1" or name == "building_7" or name == "building_11" or name == "building_12" or name == "building_13" or name == "building_14" or name == "building_16" then

		if self.buildingName_ == nil then
			do return end
		end


		self:_print("@@@@ BuildingInfo.csb not 10 ... ")


		local infoNode = require("app.ExResInterface"):getInstance():FastLoad("CityScene/BuildingInfo.csb")
		infoNode_last = infoNode
		
		infoNode:setPosition(pos)
		infoNode:getChildByName("upgrade"):getChildByName("text"):setString(CONF:getStringValue("upgrade"))
		infoNode:getChildByName("function"):getChildByName("text"):setString(CONF:getStringValue("function"))
		infoNode:getChildByName("info"):getChildByName("text"):setString(CONF:getStringValue("information"))

		if name == "building_14" then
			infoNode:getChildByName("function"):setVisible(false)
		end
		
		infoNode:getChildByName("upgrade"):getChildByName("point"):setVisible(player:canUpgradeBuilding(tonumber(string.match(self.buildingName_,"(%d+)"))))

		infoNode:getChildByName("upgrade"):addClickEventListener(function () 
			playEffectSound("sound/system/click.mp3")
			self:getApp():pushView("BuildingUpgradeScene/BuildingUpgradeScene",{building_num = tonumber(Split(name, "_")[2])})
		end)
		infoNode:getChildByName("function"):addClickEventListener(function () 
			playEffectSound("sound/system/click.mp3")

			-- add wjj 20180807
			-- system guide 
			-- ADD WJJ 20180806
			require("util.ExGuideBugHelper_SystemGuide"):getInstance():CheckSystemGuideNextCursor()

			print("self.buildingName_",self.buildingName_)
			if self.buildingName_ == "building_2" then
				
				self:getApp():pushView("ShipsScene",{})

			elseif self.buildingName_ == "building_3" then

				self:getApp():pushView("BlueprintScene/BlueprintScene")
				
			elseif self.buildingName_ == "building_4" then
				self:getApp():pushView("WeaponDevelopScene/WeaponScene")

			elseif self.buildingName_ == "building_5" then
				
				self:getApp():pushView("TechnologyScene/TechnologyScene")

			elseif self.buildingName_ == "building_8" then

				self:getApp():pushView("ChapterScene")
			elseif self.buildingName_ == "building_1" then
				-- self:getApp():addView2Top("TaskScene/TaskScene", 1)
				local layer = self:getApp():createView("TaskScene/TaskScene",1)
				self:addChild(layer)

				if guideManager:getGuideType() then
					guideManager:doEvent("click")
				end

				if self:getIsBuildingOn() then
					self:switchBuildingBtn(false, "")
				end

			elseif self.buildingName_ == "building_7" then
				self:getApp():pushView("RepairScene/RepairScene")
			elseif self.buildingName_ == "building_11" then
				if player:getPlayerPlanetUser() then
					self:getApp():addView2Top("PlanetScene/PlanetWarningLayer")
				end
			elseif self.buildingName_ == "building_12" then
				if guideManager:getGuideType() then
					self:getApp():removeTopView()
				end

				local info = player:getPlanetElement()
				self:getApp():addView2Top("PlanetScene/DefensiveLineupNode", {info = info, isPlanet = false})

				if guideManager:getSelfGuideID() == guideManager:getTeshuGuideId(2) then
					self:_print("## LUA CityUILayer 2016 createGuideLayer : getTeshuGuideId " .. tostring(guideManager:getTeshuGuideId(2)+1) )
					guideManager:createGuideLayer(guideManager:getTeshuGuideId(2)+1)
				end
			elseif self.buildingName_ == "building_13" then
				local info = player:getPlanetElement()
				-- self:getApp():addView2Top("PlanetScene/DefensiveLineupNode", {info = info, isPlanet = false})
				local flag = false
				for i,v in ipairs( info.base_data.guarde_list) do
					if info.global_key == player:getPlayerPlanetUser().base_global_key and Split(v,"_")[1] == player:getName() then
						flag = true
					end
				end

				if Tools.isEmpty(info.base_data.guarde_list) then
					-- tips:tips(CONF:getStringValue("no fleet"))
				 -- if not display:getRunningScene():getChildByName("station_amry_layer") then
					if not rn:getChildByName("station_amry_layer") then
						local station_amry_layer = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/otherNodeLayer/SeeStationedArmyLayer.csb")
						station_amry_layer:setName("station_amry_layer")
						station_amry_layer:getChildByName("title"):setString(CONF:getStringValue("team_browse"))
						station_amry_layer:getChildByName("close"):addClickEventListener(function ( ... )
							station_amry_layer:removeFromParent()
						end)
						station_amry_layer:getChildByName("wenzi"):setString(CONF:getStringValue("no fleet"))
						station_amry_layer:getChildByName("wenzi"):setVisible(true)
						local xx,yy = getScreenDiffLocation()
					--	station_amry_layer:setPosition(cc.p(-xx/2,-yy/2))
						station_amry_layer:setPosition(cc.exports.VisibleRect:leftBottom())
						station_amry_layer:getChildByName("list"):setScrollBarEnabled(false)
					--	display:getRunningScene():addChild(station_amry_layer)
						rn:addChild(station_amry_layer)

--                        require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQuanmianping_SeeStationedArmy(station_amry_layer)
					end
				else
					self.building13Click = true
					local strData = Tools.encode("PlanetGetReq", {
						army_key_list = info.base_data.guarde_list,
						type = 5,
					 })
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 

				end
			elseif self.buildingName_ == "building_16" then
				self:getApp():pushView("SmithingScene/SmithingScene")
			end
		end)

        self:ShowInfoKuang(infoNode:getChildByName("node_arrows"))
		infoNode:getChildByName("info"):addClickEventListener(function () 
            ------------add by JinXin----------------
		    self:HideInfoKuang(infoNode:getChildByName("node_arrows"))
            -----------------------------------------
			playEffectSound("sound/system/click.mp3")
			local layer = self:getApp():createView("CityScene/BuildInfo",  { BuildName = self.buildingName_})
			self:addChild(layer)
		end)

		infoNode:getChildByName("mid"):addClickEventListener(function ( sender )


			-- BUG FIX BY WJJ 20180622
			if( self == nil ) then
				do return end
			elseif( self:getParent() == nil ) then
				do return end
			elseif( self:getParent():getResourceNode() == nil ) then
				do return end
			end

			playEffectSound("sound/system/click.mp3")
			infoNode:removeFromParent()
			-- no scale effect, wjj 180705
			--[[
			for i=1,CONF.EBuilding.count do
				local node = self:getParent():getResourceNode()
				local child = node:getChildByName(string.format("text_%d", i))
				if child ~= nil then
					child:runAction(cc.ScaleTo:create(0.1, 1))
				end
			end
			]]

			self:switchBuildingBtn(false, "")
		end)

		-- infoNode:getChildByName("info"):setVisible(false)

		rn:addChild(infoNode)
		infoNode:setName("infoNode")

		if( self.IS_SCALE_BUILDING_MENU ) then
			self:ScaleOpenBuildingMenu(infoNode)
			-- infoNode:setScale(0)
			-- infoNode:runAction(cc.Sequence:create(cc.DelayTime:create(0.4), cc.ScaleTo:create(0.1,scale)))
		end

		self:SetGlobalVal_TimeNowOf("global_time_last_tanchu_jianzhu_caidan")
		self:_print("@@@@ CityUILayer.lua BuildingInfo.csb  END 2097")
	end

	-- TODO
	-- name
	if(self._print ~= nil) then
		self:_print(string.format("@@@@ CityUILayer.lua 2359 name: %s", name))
	end
	-- WJJ 180724
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Zhucheng_BuildingMenu(self,name,infoNode_last)
end

function CityUILayer:CloseTotalBut()
	--self:getResourceNode():getChildByName("totalNode"):setVisible(true)
end
function CityUILayer:UpdateTotalStatus(dt)
	local num = 0
	local totalCD 
	local localTime
	--建筑
	local count = 1
	if player:getMoneyBuildingQueueOpen() then
		count = 2
	end
	for i = 1 , count do
		local isWorking = player:getBuildQueueNow(i)
		if isWorking then
			local info = player:getBuildingQueueBuild(i)
			if info.type == 1 then
				local building_info = player:getBuildingInfo(info.index)
				local conf = CONF[string.format("BUILDING_%d",info.index)].get(building_info.level)
				totalCD = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
				localTime =  totalCD - (player:getServerTime() - building_info.upgrade_begin_time)

				if localTime <= CONF.VIP.get(player:getVipLevel()).BUILDING_FREE then
					num = num + 1
				else
					if player:isGroup() and player:getGroupHelp(CONF.EGroupHelpType.kBuilding, info.index) == nil then
						num = num + 1
					end
				end

			elseif info.type == 2 then
                local landInfo = player:getLandType(info.index)
		        local conf = CONF.RESOURCE.get(landInfo.resource_type)
		        totalCD = conf.CD + Tools.getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kHomeBuilding, info.index, CONF.ETechTarget_3_Building.kCD, player:getTechnolgList(), 	player:getPlayerGroupTech())
		        localTime = totalCD - (player:getServerTime() - landInfo.res_refresh_times)
                if localTime <= 0 then
                    num = num + 1
                end
            else
				num = num + 1
			end
		else
			num = num + 1
		end
	end

	--科研
	local param1, param2, param3 = isBuildingOpen(5, false);
	if param3 and param2 and param1 then  --判断是否开放科技队列
		local techData = player:getTechnolgyData()
		if techData.upgrade_busy == 0 then
			num = num + 1
		else
			local info = player:getTechnologyByID(techData.tech_id)
			local conf = CONF.TECHNOLOGY.get(techData.tech_id)
			localTime = info.begin_upgrade_time + conf.CD - player:getServerTime()
			if localTime <= 0 then  --已完成
				num = num + 1
			else
				if player:isGroup() and player:getGroupHelp(CONF.EGroupHelpType.kTechnology, techData.tech_id) == nil then
					num = num + 1
				end
			end
		end
	end

	--图纸
	local param1, param2, param3 = isBuildingOpen(3 ,false);
	if param3 and param2 and param1 then
		local building3_level = player:getBuildingInfo(CONF.EBuilding.kShipDevelop).level
		local produce_list = player:getBlueprint_list()
		local blueprint_list = {}
		for k,v in ipairs(CONF.BUILDING_3) do
			if v.BLUEPRINT_LIST then
				for i,pieceID in ipairs(v.BLUEPRINT_LIST) do
					local conf = CONF.BLUEPRINT.get(pieceID)
					local list = {}
					list.isOpen = 0
					list.id = pieceID
					list.openLevel = k
					list.startTime = 0
					list.shipId = conf.AIRSHIP
					list.type = conf.TYPE
					if building3_level >= k then
						list.isOpen = 1
						for ii,blist in ipairs(produce_list) do
							if pieceID == blist.blueprint_id then
								list.startTime = blist.start_time
								break
							end
						end
						table.insert(blueprint_list,list)
					else
						table.insert(blueprint_list,list) 
					end
				end
			end
		end
		local isWorking = false
		local runningData = nil
		for k, value in ipairs(blueprint_list) do
			if value.isOpen == 1 and value.startTime ~= 0 then
				isWorking = true;
				runningData = value;
			end
		end
		if not isWorking then
			num = num + 1
		else
			if runningData then
				totalCD = CONF.BLUEPRINT.get(runningData.id).TIME
				localTime =  totalCD + runningData.startTime - player:getServerTime()
				if localTime <= 0 then
					num = num + 1
				end
			end
		end
	end

	--装备
	local param1, param2, param3 = isBuildingOpen(16, false);
	if param3 and param2 and param1 then
		local isWorking = false
		local runningData = nil
		local forge_list = player:getForgeEquipList()
		local state = "NotWorking"
		for i=1,4 do
			for k,v in ipairs(forge_list) do
				local cfg_equip = CONF.EQUIP.get(v.equip_id)
				if cfg_equip.TYPE == i then
					runningData = cfg_equip;
					isWorking = true;
					state = "InWorking";
					totalCD = CONF.FORGEEQUIP.get(v.equip_id).EQUIP_TIME
					local need_time = totalCD - CONF.BUILDING_16.get(player:getBuildingInfo(CONF.EBuilding.kForge).level).EQUIP_FORGE_SPEED
					localTime = v.start_time + need_time - player:getServerTime()
					if localTime <= 0 then
						isWorking = false;
						state = "Completed";
					end
				end
			end
		end

		if state == "NotWorking" then
			num = num + 1
		elseif state == "Completed" then
			num = num + 1
		end
	end

	--修理
	local param1, param2, param3 = isBuildingOpen(7, false);
	if param3 and param2 and param1 then
		for i,v in ipairs(player:getShipList()) do
			if Bit:has(v.status, 4) then

			else
				if Bit:has(v.status, 2) == true then
					localTime = Tools.getFixShipDurableTime(v ,player:getUserInfo() , player:getTechnolgList(), player:getPlayerGroupTech()) 
					totalCD = localTime - (player:getServerTime() - v.start_fix_time)
					if player:getSpeedUpNeedMoney(totalCD) == 0 then
						num = num + 1
						break
					end
				else
					if v.durable < Tools.getShipMaxDurable(v) then
						num = num + 1
						break
					end
				end
			end
		end
	end

	--统计
	local sp = self:getResourceNode():getChildByName("totalNode"):getChildByName("totalpng"):getChildByName("Sprite_1")
	if num > 0 then
		sp:setVisible(true)
		sp:getChildByName("Text_1"):setString(num)
	else
		sp:setVisible(false)
	end
end

return CityUILayer
