local UserInfoNode = class("UserInfoNode", cc.load("mvc").ViewBase)

local animManager = require("app.AnimManager"):getInstance()

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local g_taskManager = require("app.TaskControl"):getInstance()

local app = require("app.MyApp"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()
local schedulerEntry1 = nil
local schedulerEntry2 = nil
local schedulerEntry4 = nil

-- buff 种类定义
local BFFFKIND_GREENHAND = 1004
local BFFFKIND_KARD_MONTH = 1003
local BFFFKIND_KARD_YEAR = 1002
local BFFFKIND_KARD_FOREVER = 1001
local STRONG = 1005

	--------------------------------------------------------------
UserInfoNode.RESOURCE_FILENAME = "Common/UserInfo.csb"
UserInfoNode.POS_X_QIANGZHE_JIANTOU_ADD = 247
-- UserInfoNode.isQiangzheJiantouShowDone = false
UserInfoNode.qiangzheJiantouAction = {}
	--------------------------------------------------------------
function UserInfoNode:IsGuideMode()
	local _player = require("app.Player"):getInstance()
	if _player:getGuideStep() < CONF.GUIDANCE.count() then
		return true
	end
	return false
end

function UserInfoNode:HideJiantou_Qiangzhe()

	local rn = self:getResourceNode()
	local _jiantou = rn:getChildByName("sfx_jiantou")
	if( (_jiantou == nil ) or (_jiantou:isVisible() == false) ) then
		return
	end

	_jiantou:stopAllActions()
	_jiantou:setVisible(false)
	-- _jiantou:removeFromParent()

	print(" ~~~~ HideJiantou_Qiangzhe! ")
end

function UserInfoNode:ShowJiantou_Qiangzhe()

	if( cc.exports.isQiangzheJiantouShowDone ) then
		return
	end
	local rn = self:getResourceNode()
	if not rn:getChildByTag(STRONG) then
		return
	end
	local is_enter = (cc.exports.lastEnterTime_CityScene ~= nil) and (cc.exports.lastEnterTime_CityScene > 0)

	if( is_enter == false ) then
		return
	end

	local time_passed = os.clock() - cc.exports.lastEnterTime_CityScene
	local is_time = (time_passed < 2) and (time_passed > -2)

	if( is_time == false ) then
		return
	end

	if( self:IsGuideMode() ) then
		return
	end
	

	-- ADD WJJ 20180712
	
	local buff_pos = rn:getChildByName("buff_pos");

	local _jiantou = rn:getChildByName("sfx_jiantou")
	local is_jiantou_qiangzhe = _jiantou:isVisible() == false
	if ( is_jiantou_qiangzhe ) then

		-- _jiantou:removeFromParent()
		-- buff_pos:addChild(_jiantou, 1)


		local is_ok, _act = animManager:runAnimByCSB(_jiantou, "GuideLayer/sfx/effect_0.csb", "1")
		self.qiangzheJiantouAction = _act
		-- _jiantou:setParent(buff_pos)

		local _x = _jiantou:getPositionX()
		local _y = _jiantou:getPositionY()
		-- print(string.format(" ~~~~ qiang zhe jian tou x:%s y:%s ", tostring(_x), tostring(_y)))
		-- _jiantou:setPositionX(_x + self.POS_X_QIANGZHE_JIANTOU_ADD)
		_jiantou:setPositionX(rn:getChildByTag("STRONG"):getPositionX())
		-- _jiantou:setPosition(0,0)
		_jiantou:setGlobalZOrder(1)
		_jiantou:setVisible(true)

		cc.exports.qiangzhe_jiantou = _jiantou
		cc.exports.isQiangzheJiantouShowDone = true
		-- print(" ~~~~ qiang zhe jian tou show! ")
	end
end

function UserInfoNode:matchviplevel(vip_node)
    if player:getVipLevel() > 9 then
        vip_node:getChildByName("vipnum"):setVisible(false)
        vip_node:getChildByName("vipnum1"):setVisible(true)
        vip_node:getChildByName("vipnum2"):setVisible(true)
        local str = tostring(player:getVipLevel())
        local nums = {}
        for i=1,string.len(str) do
            nums[i] = tonumber( string.sub(str,i,i))
        end
        vip_node:getChildByName("vipnum1"):setTexture("CityScene/ui3/vip"..nums[1]..".png")
        vip_node:getChildByName("vipnum2"):setTexture("CityScene/ui3/vip"..nums[2]..".png")
    else
        vip_node:getChildByName("vipnum"):setVisible(true)
        vip_node:getChildByName("vipnum1"):setVisible(false)
        vip_node:getChildByName("vipnum2"):setVisible(false)
	    vip_node:getChildByName("vipnum"):setTexture("CityScene/ui3/vip"..player:getVipLevel()..".png")
    end
end
	--------------------------------------------------------------

function UserInfoNode:init(scene,adventure) -- adventure奇遇标示（主城，大地图为true）
	-- WJJ 20180712
	cc.exports.isQiangzheJiantouShowDone = false
	cc.exports.qiangzhe_jiantou = nil

	self.showAdventure = true;
	self.adventure = adventure
	local rn = self:getResourceNode()
	rn:getChildByName("vip_btn"):setVisible(self.adventure)
	rn:getChildByName("vip_0"):setVisible(self.adventure)
	rn:getChildByName("vip_btn"):addClickEventListener(function()
		playEffectSound("sound/system/click.mp3")
		local VipPrivilegeNode = require("app.views.VipScene.VipPrivilegeNode"):create()
        VipPrivilegeNode:setAnchorPoint(cc.p(0.5,0.5))
		VipPrivilegeNode:init(display:getRunningScene(), {index = 2})
		display:getRunningScene():addChild(VipPrivilegeNode)
		VipPrivilegeNode:setPosition(cc.exports.VisibleRect:center())
		end)
    self:matchviplevel(rn:getChildByName("vip_btn"))
	rn:getChildByName("headImage"):loadTexture("HeroImage/"..player:getPlayerIcon()..".png")
	rn:getChildByName("player_bottom"):addClickEventListener(function ( sender )
		if cc.exports.g_activate_building then
			return
		end
		playEffectSound("sound/system/click.mp3")

		if player:getGuideStep() < CONF.GUIDANCE.count() then
			return
		end
		rn:getChildByName("sfx_jiantou"):setVisible(false)

		local layer = app:createView("TaskScene/AttributeLayer")
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
	self.level = player:getLevel()
	rn:getChildByName("lv"):setString("Lv."..player:getLevel())
    --mail
    rn:getChildByName("mailtop"):addClickEventListener(function ()
        if cc.exports.g_activate_building then
			return
		end
        rn:getChildByName("mailtop"):getChildByName("point"):setVisible(false)
        app:pushView("MailScene/MailScene",{from = 'city'})
    end)

	--set fight
   	rn:getChildByName("fight"):setString(CONF:getStringValue("sumPower")..":")
	rn:getChildByName("fight_num"):setString(player:getPower())

	local exp_bar = rn:getChildByName("exp_progress")
	self.expDelegate_ = require("util.ScaleProgressDelegate"):create(exp_bar, exp_bar:getTag())

	local p = player:getNextLevelExpPercent()
	if p > 100 then
		p = 100
	end

	self.expDelegate_:setPercentage(p)
	if CONF.FUNCTION_OPEN.get("achievement_open").OPEN_GUIDANCE == 1 then
		if player:getLevel() >= CONF.FUNCTION_OPEN.get("achievement_open").GRADE and player:getSystemGuideStep(math.floor(CONF.FUNCTION_OPEN.get("achievement_open").INTERFACE/100)) == 0 then
			animManager:runAnimByCSB(rn:getChildByName("sfx_jiantou"), "GuideLayer/sfx/effect_0.csb", "1")
			rn:getChildByName("sfx_jiantou"):setVisible(true)
		else
			rn:getChildByName("sfx_jiantou"):setVisible(false)
		end
	end


	--xsgh
	rn:getChildByName("xsgh"):addClickEventListener(function ( ... )
		printInfo("bingmeiyoushenemluanyong")
	end)

	local function onFrameEvent(frame)
		if nil == frame then
			return
		end
		local str = frame:getEvent()

		if str == "f" then
			rn:getChildByName("fight_num"):setPositionX(rn:getChildByName("fight"):getPositionX() + rn:getChildByName("fight"):getContentSize().width+5)
			rn:getChildByName("fight_num"):setOpacity(255)
			
		end
	end
	local BuffIconDetail = nil
	local function removeMySchedulerAndChild()
		if schedulerEntry1 ~= nil then
		 	scheduler:unscheduleScriptEntry(schedulerEntry1)
		 	schedulerEntry1 = nil
		end
		if schedulerEntry2 ~= nil then
		 	scheduler:unscheduleScriptEntry(schedulerEntry2)
		 	schedulerEntry2 = nil
		end
		if rn:getChildByName("tipcsb") then
			rn:getChildByName("tipcsb"):removeFromParent()
		end
		if rn:getChildByName('btn1') then
			rn:getChildByName('btn1'):removeFromParent()
			BuffIconDetail()
		end
	end
	-- 获取不同buff参数
	
	
	local function createDetailCSB(ui,buffid)
		local tipcsb = require("app.ExResInterface"):getInstance():FastLoad("Common/Buff_tip.csb")
		tipcsb:getChildByName("bkg"):setSwallowTouches(true)
		tipcsb:getChildByName("bkg"):addClickEventListener(function ( ... )
			if cc.exports.g_activate_building then
				return
			end
			tipcsb:removeFromParent()
			if schedulerEntry1 ~= nil then
			 	scheduler:unscheduleScriptEntry(schedulerEntry1)
			 	schedulerEntry1 = nil
			end
		end)
		local xx,yy = getScreenDiffLocation()
		
		local rate = cc.Director:getInstance():getWinSize().height/cc.Director:getInstance():getWinSize().width
		tipcsb:setPosition(ui:getPosition())
        	require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQuanmianping_GreenHandBuff(tipcsb)
		tipcsb:setName("tipcsb")
		local destab = {}
		if buffid == BFFFKIND_GREENHAND then
			local cids = CONF.PARAM.get("green_hand_buff").PARAM
			for k,id in ipairs(cids) do
				local cfgsign = CONF.TECHNOLOGY.get(id).MEMO_ID 
				local numstr = CONF.TECHNOLOGY.get(id).TECHNOLOGY_ATTR_PERCENT..'%'
				local cfgstr = CONF.STRING.get(cfgsign).VALUE
				local caninsert = true
				for o,p in ipairs(destab) do
					if p.str == cfgstr then
						caninsert = false
					end
				end
				if caninsert then
					local newtab = {}
					newtab.desstr = cfgstr
					newtab.numstr = numstr
					table.insert(destab,newtab)
				end
			end
		else

		end
		local posnode = tipcsb:getChildByName('Node_pos')
		local pos = {posnode:getPositionX(),posnode:getPositionY()}
		-- 第一列：
		-- 1.新手buff
		if buffid == BFFFKIND_GREENHAND then
			-- destab[CONF.STRING.get('reside_time').VALUE] = '0'
			local newtab = {}
			newtab.desstr = CONF.STRING.get('reside_time').VALUE
			newtab.numstr = '0'
			table.insert(destab,newtab)
			tipcsb:getChildByName('Text_1'):setString(CONF.STRING.get('KJ_N400000').VALUE)
			tipcsb:getChildByName('Text_2'):setVisible(false)
		end
		-- 后面列通用：
		local maxWidth
		local maxHeight = tipcsb:getChildByName('Text_2'):getContentSize().height
		table.sort(destab,function(a,b)
			return string.len(a.numstr) < string.len(b.numstr)
			end)
		for k,v in ipairs(destab) do
			local label1 = require("app.ExResInterface"):getInstance():FastLoad("Common/Buff_text.csb")
			label1:setName(v.desstr)
			tipcsb:addChild(label1)
			label1:setPosition(pos[1] + 80,pos[2])
			pos = {pos[1],pos[2]-10-label1:getChildByName('Text_2'):getContentSize().height}
			label1:getChildByName('Text_1'):setString(v.desstr..': ')
			label1:getChildByName('Text_2'):setString(v.numstr)
			label1:getChildByName('Text_2'):setPosition(label1:getChildByName('Text_1'):getPositionX()+label1:getChildByName('Text_1'):getContentSize().width,label1:getChildByName('Text_1'):getPositionY())
			if not maxWidth then
				maxWidth = label1:getChildByName('Text_1'):getContentSize().width + label1:getChildByName('Text_2'):getContentSize().width
			else
				maxWidth = math.max(maxWidth,label1:getChildByName('Text_1'):getContentSize().width + label1:getChildByName('Text_2'):getContentSize().width)
			end
		end
		-- 倒计时
		if buffid == BFFFKIND_GREENHAND then
			local birthtime = player:getRegistTime()
			local ctime = CONF.PARAM.get("green_hand_time").PARAM
			local updatetime = ctime + birthtime
			if tipcsb:getChildByName(CONF.STRING.get('reside_time').VALUE) then
				tipcsb:getChildByName(CONF.STRING.get('reside_time').VALUE):getChildByName('Text_1'):setString(CONF.STRING.get('reside_time').VALUE..': ')
			end
			if player:getServerTime() < updatetime then
				local totaltime = player:getServerTime() < updatetime and updatetime - player:getServerTime() or 0
				local function updateSecond()
			 		if totaltime > 0 then
			 			local totalmin = math.modf(totaltime/60)
			 			local hour = math.modf(totalmin/60)
			 			local sec = totaltime - totalmin*60
			 			local min = totalmin - hour*60
			 			if tipcsb:getChildByName(CONF.STRING.get('reside_time').VALUE) then
				 			tipcsb:getChildByName(CONF.STRING.get('reside_time').VALUE):getChildByName('Text_2'):setString( string.format('%.2d:%.2d:%.2d',hour,min,sec))
				 		end
			 			totaltime = totaltime - 1
					end
					if player:getPlayerState() ~= 1 or totaltime <= 0 then
						removeMySchedulerAndChild()
					end
				end
				updateSecond()
				if schedulerEntry1 == nil then
					schedulerEntry1 = scheduler:scheduleScriptFunc(updateSecond,1,false)
				end
				if not rn:getChildByName("tipcsb") then

					rn:addChild(tipcsb)
					tipcsb:setLocalZOrder(9999)
				end
				-- if not rn:getParent():getChildByName('tipcsb') then
					-- rn:getParent():addChild(tipcsb)
				-- end
			else
				removeMySchedulerAndChild()
			end
			if not tipcsb:getChildByName(CONF.STRING.get('reside_time').VALUE) then
				removeMySchedulerAndChild()
			end
			tipcsb:getChildByName('Text_2'):setPosition(posnode:getPositionX()+80,tipcsb:getChildByName('Text_2'):getPositionY())
			tipcsb:getChildByName('Text_2'):setPosition(tipcsb:getChildByName('Text_1'):getPositionX() + tipcsb:getChildByName('Text_1'):getContentSize().width,tipcsb:getChildByName('Text_1'):getPositionY())
		end
		maxHeight = (maxHeight)*(#destab + 1) + 20*(#destab) + 10
		if maxWidth then
			tipcsb:getChildByName('blue'):setContentSize(cc.size(maxWidth+150,maxHeight))
		end
	end
	function BuffIconDetail()
		local birthtime = player:getRegistTime()
		local ctime = CONF.PARAM.get("green_hand_time").PARAM
		local updatetime = ctime + birthtime
		local totaltime = player:getServerTime() < updatetime and updatetime - player:getServerTime() or 0
		-- 头像条界面获取buff（新手，卡）
		local bufftab = {}
		bufftab[#bufftab + 1] = STRONG
		local cardstate = player:getCardState()
		 -- have card buff
		if cardstate ~= 0 then

		end
		-- have greenhand card
		if player:getPlayerState() == 1 then
			if totaltime > 0 then
				bufftab[#bufftab + 1] = BFFFKIND_GREENHAND
			else
				if rn:getChildByName('btn1') then
					rn:getChildByName('btn1'):removeFromParent()
					BuffIconDetail()
				end
				-- if display:getRunningScene():getChildByName("tipcsb") then
				-- 	display:getRunningScene():getChildByName("tipcsb"):removeFromParent()
				-- end
				if rn:getParent():getChildByName("tipcsb") then
					rn:getParent():getChildByName("tipcsb"):removeFromParent()
				end
			end
		else
			removeMySchedulerAndChild()
		end
		table.sort(bufftab)
		local buff_node = rn:getChildByName('buff_pos')
		for k,v in ipairs(bufftab) do
			local btn1
			if v == BFFFKIND_GREENHAND then
				btn1 = ccui.Button:create("Common/newUI/icon_greenshou.png","Common/newUI/icon_greenshou_light.png")
				local cid = CONF.PARAM.get("green_hand_buff").PARAM[1]
				local cfgsign = CONF.TECHNOLOGY.get(cid).RES_ID
				btn1:addClickEventListener(function ( ... )
					if cc.exports.g_activate_building then
						return
					end
					createDetailCSB(btn1,BFFFKIND_GREENHAND)
				end)
				-- btn1:addTouchEventListener(function ( sender, eventType )
				-- 	if eventType == ccui.TouchEventType.began then 
				-- 		createDetailCSB(btn1,BFFFKIND_GREENHAND)
				-- 	elseif eventType == ccui.TouchEventType.ended then 
				-- 		-- if display:getRunningScene():getChildByName("tipcsb") then
				-- 		-- 	display:getRunningScene():getChildByName("tipcsb"):removeFromParent()
				-- 		-- end
				-- 		if rn:getParent():getChildByName("tipcsb") then
				-- 			rn:getParent():getChildByName("tipcsb"):removeFromParent()
				-- 		end
				-- 		if schedulerEntry1 ~= nil then
				-- 		 	scheduler:unscheduleScriptEntry(schedulerEntry1)
				-- 		 	schedulerEntry1 = nil
				-- 		end
				-- 	elseif eventType == ccui.TouchEventType.canceled then
				-- 		-- if display:getRunningScene():getChildByName("tipcsb") then
				-- 		-- 	display:getRunningScene():getChildByName("tipcsb"):removeFromParent()
				-- 		-- end
				-- 		if rn:getParent():getChildByName("tipcsb") then
				-- 			rn:getParent():getChildByName("tipcsb"):removeFromParent()
				-- 		end
				-- 		if schedulerEntry1 ~= nil then
				-- 		 	scheduler:unscheduleScriptEntry(schedulerEntry1)
				-- 		 	schedulerEntry1 = nil
				-- 		end
				-- 	end
				-- end)
				local updateSecond = function()
					local totaltime = player:getServerTime() < updatetime and updatetime - player:getServerTime() or 0
					if player:getServerTime() < updatetime then
						totaltime = totaltime - 1
					else
						removeMySchedulerAndChild()
					end
					if player:getPlayerState() ~= 1 then
						removeMySchedulerAndChild()
					end
				end
				if schedulerEntry2 == nil then
					schedulerEntry2 = scheduler:scheduleScriptFunc(updateSecond,1,false)
				end
			elseif v == STRONG then
				btn1 = ccui.Button:create("CityScene/ui3/icon_stronger.png");
				btn1:setTag(STRONG)
				btn1:addClickEventListener(function ()
					if(cc.exports.isQiangzheJiantouShowDone) then
						self:HideJiantou_Qiangzhe()
					end
					app:addView2Top("StrongLayer/StrongLayer");
				end)
                --- hidestrong
                btn1:setVisible(false)
			end
			if btn1 then
				if not rn:getChildByName('btn'..k) then
					rn:addChild(btn1)
				end
				btn1:setName('btn'..k)
				btn1:setPosition(buff_node:getPositionX()+k*45,buff_node:getPositionY())
			end
		end
	end
	animManager:runAnimOnceByCSB(rn, "Common/UserInfo.csb", "1", function ()
		animManager:runAnimByCSB(rn:getChildByName("zhanli"), "CityScene/sfx/zhanli/zhanli.csb",  "1")
		rn:getChildByName("head_sfx"):setVisible(false)
		if player:getLevel() >= CONF.FUNCTION_OPEN.get("achievement_open").GRADE and g_taskManager:hasCanGetAchievement() == true then
			rn:getChildByName("head_sfx"):setVisible(true)
			animManager:runAnimByCSB(rn:getChildByName("head_sfx"), "CityScene/sfx/lingqu/chengjiu.csb" ,"1")
		end

		rn:getChildByName("fight_num"):setPositionX(rn:getChildByName("fight"):getPositionX() + rn:getChildByName("fight"):getContentSize().width+5)
		
		BuffIconDetail()
	end, onFrameEvent)

	self.expListener_ = cc.EventListenerCustom:create("ExpUpdated", function ()
		local p = player:getNextLevelExpPercent()
		if p > 100 then
			p = 100
		end

		self.expDelegate_:setPercentage(p)

		
		if self.level ~= player:getLevel() then
            if cc.exports.clickTaskReward ~= nil and cc.exports.clickTaskReward then 
                cc.exports.levelup_param = {player:getLevel(),self.level}
            else
			    createLevelUpNode(player:getLevel(),self.level)
            end
		end

		rn:getChildByName("lv"):setString("Lv."..player:getLevel())
		self.level = player:getLevel()

		if player:getLevel() >= CONF.FUNCTION_OPEN.get("achievement_open").GRADE and player:getSystemGuideStep(math.floor(CONF.FUNCTION_OPEN.get("achievement_open").INTERFACE/100)) == 0 then
			rn:getChildByName("sfx_jiantou"):setVisible(true)
		else
			rn:getChildByName("sfx_jiantou"):setVisible(false)
		end
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

    local function updateHeadTipShow()
	    if g_taskManager:hasCanGetAchievement() == true then
		    -- animManager:runAnimByCSB(rn:getChildByName("info_node"):getChildByName("userInfoNode"):getChildByName("head_sfx"), "CityScene/sfx/lingqu/chengjiu.csb" ,"1")
		    rn:getChildByName("head_sfx"):setVisible(true)
		    self.showHeadSfx_ = true
	    else
		    rn:getChildByName("head_sfx"):setVisible(false)
	    end
    end
    if schedulerEntry4 ~= nil then
	    schedulerEntry4 = scheduler:scheduleScriptFunc(updateHeadTipShow, 1, false)
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

	self.payListener_ = cc.EventListenerCustom:create("payCallback", function (event)
        self:matchviplevel(rn:getChildByName("vip_btn"))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.payListener_, FixedPriority.kNormal)
	--------------------------------------------------------------
	self:ShowJiantou_Qiangzhe()
	--------------------------------------------------------------
    local function recvMsg()
        local cmd,strData = GameHandler.handler_c.recvProtobuf()

        if cmd == Tools.enum_id("CMD_DEFINE","CMD_MAIL_LIST_UPDATE") then
			-- self.btnList[BTN_TAG.TAG_MAIL]:getChildByName("red"):setVisible(true)
			if rn:getChildByName("mailtop") then
				rn:getChildByName("mailtop"):getChildByName("point"):setVisible(true)
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_NEW_GROUP_UPDATE") then
			-- self.btnList[BTN_TAG.TAG_MAIL]:getChildByName("red"):setVisible(true)
			if rn:getChildByName("mailtop") then
				rn:getChildByName("mailtop"):getChildByName("point"):setVisible(true)
			end
			
			tips:tips(CONF:getStringValue("new_invite_mail"))
        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_RESP") then
			local proto = Tools.decode("GetMailListResp",strData)
			if proto.result ~= 0 then
				print("proto error ",proto.result)  
			else
				player.mail_list_ = proto.user_sync.mail_list
				-- self.btnList[BTN_TAG.TAG_MAIL]:getChildByName("red"):setVisible(false)
				if rn:getChildByName("mailtop") then
					rn:getChildByName("mailtop"):getChildByName("point"):setVisible(false)
				end
				for i,v in ipairs(proto.user_sync.mail_list) do
					if v.type == 0 or v.type == 2 or v.type == 10 or v.type == 4 then 
						-- self.btnList[BTN_TAG.TAG_MAIL]:getChildByName("red"):setVisible(true)
						if rn:getChildByName("mailtop") then
							rn:getChildByName("mailtop"):getChildByName("point"):setVisible(true)
						end
						break
					end
				end
            end
        end
    end
    self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function UserInfoNode:onEnterTransitionFinish()


	-- local buff_pos = self:getResourceNode():getChildByName("buff_pos");
	-- local strongBtn = ccui.Button:create("CityScene/ui3/icon_stronger.png");
	-- buff_pos:addChild(strongBtn);
	-- strongBtn:setPosition(buff_pos:getPositionX()+80,buff_pos:getPositionY())
	-- strongBtn:addClickEventListener(function ()
	-- 	print(" ~~~~ strongBtn cc.exports.isQiangzheJiantouShowDone: " .. tostring(cc.exports.isQiangzheJiantouShowDone))
	-- 	if(cc.exports.isQiangzheJiantouShowDone) then
	-- 		self:HideJiantou_Qiangzhe()
	-- 	end
	-- 	app:addView2Top("StrongLayer/StrongLayer");
	-- end)

	-- 	print(" ~~~~ UserInfoNode onEnterTransitionFinish! ")
end

function UserInfoNode:onExitTransitionStart()
	printInfo("UserInfoNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.expListener_)
	eventDispatcher:removeEventListener(self.achievementlistener_)
	eventDispatcher:removeEventListener(self.payListener_)
    eventDispatcher:removeEventListener(self.recvlistener_)
	if schedulerEntry1 ~= nil then
	 	scheduler:unscheduleScriptEntry(schedulerEntry1)
	 	schedulerEntry1 = nil
	end
	if schedulerEntry2 ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry2)
		schedulerEntry2 = nil
	end
    if schedulerEntry4 ~= nil then
        scheduler:unscheduleScriptEntry(schedulerEntry4)
        schedulerEntry4 = nil
    end
end

function UserInfoNode:setAdventureShow(isShow)
	self.showAdventure = isShow;
end


return UserInfoNode