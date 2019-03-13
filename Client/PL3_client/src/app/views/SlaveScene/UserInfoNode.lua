local UserInfoNode = class("UserInfoNode", cc.load("mvc").ViewBase)

local animManager = require("app.AnimManager"):getInstance()

local player = require("app.Player"):getInstance()
local g_taskManager = require("app.TaskControl"):getInstance()

local app = require("app.MyApp"):getInstance()


UserInfoNode.RESOURCE_FILENAME = "SlaveScene/userInfo.csb"

function UserInfoNode:onEnterTransitionFinish()

end

function UserInfoNode:init(scene)

	local rn = self:getResourceNode()

	rn:getChildByName("headImage"):loadTexture("HeroImage/"..player:getPlayerIcon()..".png")
	rn:getChildByName("player_bottom"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local layer = app:createView("TaskScene/AttributeLayer",{})
		scene:addChild(layer)
	end)

	-- rn:getChildByName("vip"):addClickEventListener(function ( ... )
	--     local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

	--     rechargeNode:init(self:getParent(), {index = 1})
	--     self:getParent():addChild(rechargeNode)

	--     playEffectSound("sound/system/click.mp3")
	-- end)

	rn:getChildByName("jindu_di"):setLocalZOrder(2)
	rn:getChildByName("exp_progress"):setLocalZOrder(3)
	rn:getChildByName("lv"):setLocalZOrder(2)

	--set name
	rn:getChildByName("reaper_aleriness"):setString(player:getNickName())

	--set vip level
	-- local pos = cc.p(roleInfoBack:getChildByName("vip_num"):getPosition())
	-- roleInfoBack:getChildByName("vip_num"):removeFromParent()

	-- local vip_level = string.format("%d", player:getVipLevel()) 
	-- local num = require("util.MapLabel"):create("CityScene/ui", vip_level)
	-- roleInfoBack:addChild(num)
	-- num:setPosition(pos)
	-- num:setName("vip_num")

	-- rn:getChildByName("vip_bg"):getChildByName("text"):setString(player:getVipLevel())

	--set level
	rn:getChildByName("lv"):setString("Lv."..player:getLevel())


	--set fight
 --   	rn:getChildByName("fight"):setString(CONF:getStringValue("combat")..":")
	-- rn:getChildByName("fight_num"):setString(player:getPower())

	--setslave
	if player:getSlaveData() ~= nil then
		if player:getSlaveData().master == nil or player:getSlaveData().master == "" then
			if #player:getSlaveData().slave_list > 0 then
				rn:getChildByName("icon"):setTexture("Common/newUI/icon_ruler.png")
				rn:getChildByName("icon_di"):setTexture("Common/newUI/icon_ruler_bottom.png")
				rn:getChildByName("fight_num"):setString(CONF:getStringValue("host"))
			else
				rn:getChildByName("fight_num"):setString(CONF:getStringValue("free_man"))
			end
		else
			rn:getChildByName("icon"):setTexture("Common/newUI/icon_slave.png")
			rn:getChildByName("icon_di"):setTexture("Common/newUI/icon_slave_bottom.png")
			rn:getChildByName("fight_num"):setString(CONF:getStringValue("slave"))
		end
	else
		rn:getChildByName("fight_num"):setString(CONF:getStringValue("free_man"))
	end

	local exp_bar = rn:getChildByName("exp_progress")
	self.expDelegate_ = require("util.ScaleProgressDelegate"):create(exp_bar, exp_bar:getTag())

	local p = player:getNextLevelExpPercent()
	if p > 100 then
		p = 100
	end

	self.expDelegate_:setPercentage(p)

	animManager:runAnimOnceByCSB(rn, "SlaveScene/userInfo.csb", "1", function ()
		rn:getChildByName("head_sfx"):setVisible(false)
		if player:getLevel() >= CONF.FUNCTION_OPEN.get("achievement_open").GRADE and g_taskManager:hasCanGetAchievement() == true then
			rn:getChildByName("head_sfx"):setVisible(true)
			animManager:runAnimByCSB(rn:getChildByName("head_sfx"), "CityScene/sfx/lingqu/chengjiu.csb" ,"1")
		end
	end)

	self.expListener_ = cc.EventListenerCustom:create("ExpUpdated", function ()
		local p = player:getNextLevelExpPercent()
		if p > 100 then
			p = 100
		end

		self.expDelegate_:setPercentage(p)

		rn:getChildByName("lv"):setString("Lv."..player:getLevel())
	end)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.expListener_, FixedPriority.kNormal)

	self.showHeadSfx_ = false

	if g_taskManager:hasCanGetAchievement() == true then
		-- animManager:runAnimByCSB(rn:getChildByName("info_node"):getChildByName("userInfoNode"):getChildByName("head_sfx"), "CityScene/sfx/lingqu/chengjiu.csb" ,"1")
		rn:getChildByName("head_sfx"):setVisible(true)
		self.showHeadSfx_ = true
	else
		rn:getChildByName("head_sfx"):setVisible(false)
	end

	self.achievementlistener_ = cc.EventListenerCustom:create("AchievementUpdate", function ( event )
		if event._usedata == true then
			if self.showHeadSfx_ == false then
				-- animManager:runAnimByCSB(rn:getChildByName("info_node"):getChildByName("userInfoNode"):getChildByName("head_sfx"), "CityScene/sfx/lingqu/chengjiu.csb" ,"1")
				rn:getChildByName("head_sfx"):setVisible(true)
			end
		else
			if self.showHeadSfx_ == true then
				rn:getChildByName("head_sfx"):setVisible(false)
			end
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.achievementlistener_, FixedPriority.kNormal)

end

function UserInfoNode:onExitTransitionStart()
	printInfo("WorldNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.expListener_)
	eventDispatcher:removeEventListener(self.achievementlistener_)

end


return UserInfoNode