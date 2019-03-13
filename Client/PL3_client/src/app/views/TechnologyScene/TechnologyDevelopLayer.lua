local g_player = require("app.Player"):getInstance()

local player = require("app.Player"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local app = require("app.MyApp"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local TechnologyDevelopLayer = class("TechnologyDevelopLayer", cc.load("mvc").ViewBase)

TechnologyDevelopLayer.RESOURCE_FILENAME = "TechnologyScene/TechnologyDevelopLayer.csb"

TechnologyDevelopLayer.NEED_ADJUST_POSITION = true

local schedulerEntry = nil

function TechnologyDevelopLayer:onCreate(data)--{techID = X}
	self.data_ = data
end

function TechnologyDevelopLayer:findTechInHelpList( )
	local user_name = g_player:getName()
	if Tools.isEmpty(self.help_list) == false then
		for i,v in ipairs(self.help_list) do
			if v.user_name == user_name then
				if v.type == CONF.EGroupHelpType.kTechnology and v.id[1] == self.data_.techID then
					return true
				end
			end
		end
	end
	return false
end

function TechnologyDevelopLayer:onEnterTransitionFinish()
	printInfo("TechnologyDevelopLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()
	rn:getChildByName("develop"):getChildByName("text"):setString(CONF:getStringValue("Develop"))


	local grayLayer = cc.LayerColor:create(cc.c4b( 16, 9, 2, 150))
	self:addChild(grayLayer)
	grayLayer:setLocalZOrder(-1)

	local conf = CONF.TECHNOLOGY.get(self.data_.techID)
	if conf == nil then
		return
	end

	rn:getChildByName("name"):setString(CONF.STRING.get(conf.TECHNOLOGY_NAME).VALUE)
	rn:getChildByName("effect"):setString(CONF:getStringValue("effect"))
	rn:getChildByName("cost"):setString(CONF:getStringValue("Cost"))
	rn:getChildByName("need"):setString(CONF:getStringValue("demand"))
	rn:getChildByName("lv"):setString(CONF:getStringValue("level"))


	rn:getChildByName("icon"):setTexture(string.format("TechnologyIcon/%d.png",conf.RES_ID))



	rn:getChildByName("cur_lv_num"):setString(string.format("%d",conf.TECHNOLOGY_LEVEL-1))

	rn:getChildByName("next_lv_num"):setString(string.format("%d",conf.TECHNOLOGY_LEVEL))

	rn:getChildByName("power_num"):setString(string.format("%d",conf.FIGHT_POWER))


	rn:getChildByName("memo"):setString(CONF.STRING.get(conf.MEMO_ID).VALUE)

	local preConf = CONF.TECHNOLOGY.check(self.data_.techID - 1)

	local value1Str,value2Str
	if conf.TECHNOLOGY_ATTR_PERCENT > 0 then
		value2Str = string.format("%d%%",conf.TECHNOLOGY_ATTR_PERCENT)
		value1Str = string.format("%d%%",preConf and preConf.TECHNOLOGY_ATTR_PERCENT or 0)
	else
		value2Str =  string.format("%d",conf.TECHNOLOGY_ATTR_VALUE)
		value1Str =  string.format("%d", preConf and preConf.TECHNOLOGY_ATTR_VALUE or 0)
	end
	rn:getChildByName("cur_effect"):setString(value1Str)
	rn:getChildByName("next_effect"):setString(value2Str)


	

	local costPos = cc.p(rn:getChildByName("cost_node"):getPosition())
	local costDiffX = 100

	local function createCostTab( id, num )
		local tab = require("app.ExResInterface"):getInstance():FastLoad("TechnologyScene/NeedRes.csb")

		local itemConf  = CONF.ITEM.get(id)

		tab:getChildByName("icon"):setTexture(string.format("ItemIcon/%d.png",itemConf.ICON_ID))

		tab:getChildByName("num"):setString(formatRes(num))

		return tab
	end

	for index,v in ipairs(conf.ITEM_ID) do
		local costTab = createCostTab(conf.ITEM_ID[index], conf.ITEM_NUM[index])
		rn:addChild(costTab)
		costTab:setPosition(costPos.x + (index-1) * costDiffX, costPos.y)
	end


	
	local needList = {}

	local function createNeedTab(name, lv, flag)
		local tab = require("app.ExResInterface"):getInstance():FastLoad("TechnologyScene/NeedTechnology.csb")
		tab:getChildByName("name"):setString(name)

		local lv_num_name = string.format("lv_num%d",flag == true and 1 or 0)


		tab:getChildByName(lv_num_name):setString(string.format("%d",lv))

		tab:getChildByName(string.format("lv_num%d",flag == false and 1 or 0)):setVisible(false)

		return tab
	end

	--NEED加入建筑需求
	needList[1] = createNeedTab(CONF:getStringValue("BuildingName_5"), conf.TECHNOLOGY_BUILDING_LEVEL, g_player:getBuildingInfo(CONF.EBuilding.kTechnology).level >= conf.TECHNOLOGY_BUILDING_LEVEL)

	--NEED加入科技需求

	local groupTechID = math.floor(self.data_.techID*0.01)
	local preTechCount = 4
	for index=1,preTechCount do
		if Tools.isEmpty(conf.PRE_TECHNOLOGY) == true then
			break
		end
		local preTechID = conf.PRE_TECHNOLOGY[index]
		if preTechID and preTechID > 0 then

			local preGroupTechID = math.floor(preTechID*0.01)

			if preGroupTechID ~= groupTechID then 

				local preConf = CONF.TECHNOLOGY.get(conf.PRE_TECHNOLOGY[index])

				local flag = false

				local cur_tech = g_player:getUsedTechnologyByTemp(math.floor(conf.PRE_TECHNOLOGY[index] / 100) * 100)
				if cur_tech then
					flag = Tools.mod(cur_tech.tech_id, 100) >= preConf.TECHNOLOGY_LEVEL
				end

				local techTab = createNeedTab(CONF:getStringValue(preConf.TECHNOLOGY_NAME), preConf.TECHNOLOGY_LEVEL, flag)

				table.insert(needList, techTab)
			end
		else
			break
		end

	end



	local needPos = cc.p(rn:getChildByName("need_node"):getPosition())
	local needDiffY = 30

	for i,v in ipairs(needList) do

		rn:addChild(needList[i])
		needList[i]:setPosition(needPos.x, needPos.y - (i-1)*needDiffY)
	end



	local function checkCanDevelop(  )

		local techData = g_player:getTechnolgyData()
		if techData.upgrade_busy == 1 then
			tips:tips(CONF.STRING.get("develop_tech_busy").VALUE)
			return false
		end

		if g_player:getBuildingInfo(CONF.EBuilding.kTechnology).level < conf.TECHNOLOGY_BUILDING_LEVEL then
			tips:tips(CONF.STRING.get("Building_lvl_not_enought").VALUE)
			return false
		end
		local jumpTab = {}
		local enough = true
		for i=1,#conf.ITEM_ID do
			if g_player:getItemNumByID(conf.ITEM_ID[i]) < conf.ITEM_NUM[i] then
	            local cfg_item = CONF.ITEM.get(conf.ITEM_ID[i])
	            if cfg_item and cfg_item.JUMP then
	                table.insert(jumpTab,cfg_item.JUMP)
	            end
				enough = false
			end
		end
		if not enough then
			if Tools.isEmpty(jumpTab) == false and not self:getChildByName("JumpChoseLayer") then
				jumpTab.scene = "TechnologyDevelopLayer"
                local center = cc.exports.VisibleRect:center()
                local layer = app:createView("ShipsScene/JumpChoseLayer",jumpTab)
                tipsAction(layer, cc.p(center.x + (rn:getContentSize().width/2 - center.x), center.y + (rn:getContentSize().height/2 - center.y)))
                layer:setName("JumpChoseLayer")
                self:addChild(layer)
            end 
            tips:tips(CONF.STRING.get("res_not_enough").VALUE) 
			return false
		end


		if  Tools.isEmpty(conf.PRE_TECHNOLOGY) == false then
			for i,v in ipairs(conf.PRE_TECHNOLOGY) do
				if v > 0 then
					local curTech= g_player:getUsedTechnologyByTemp(math.floor(v / 100) * 100)
					if curTech == nil or curTech.tech_id < v then
						tips:tips(CONF.STRING.get("pre_technology_no_enough").VALUE)
						return false
					end
				end
			end
		end

		return true
	end

	local function getSpeedUpNeedMoney(  )
		local conf = CONF.TECHNOLOGY.get(self.data_.techID)
		local info = g_player:getTechnologyByID(self.data_.techID)
		--检查是否有技能减少CD
		local cd = conf.CD + g_player:getValueByTechnologyAddition(conf.CD, CONF.ETechTarget_1.kTechnology, 0, CONF.ETechTarget_3_Building.kCD)

		local diff = cd + info.begin_upgrade_time - g_player:getServerTime()
		if diff <= 0 then
			return 0
		end
		return Tools.getSpeedUpNeedMoney(diff)
	end

	local function checkCanSpeedUp( )
		

		local needMoney = getSpeedUpNeedMoney()

		if g_player:getMoney() < needMoney then
			-- tips:tips(CONF.STRING.get("no enought credit").VALUE)
			local function func()
				local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

				rechargeNode:init(self, {index = 1})
				self:addChild(rechargeNode)
			end

			local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
			return false
		end

		return true
	end

	local info = g_player:getTechnologyByID(self.data_.techID)

	if info and info.begin_upgrade_time > 0 then

		rn:getChildByName("cd_time"):setString(formatTime(info.begin_upgrade_time + conf.CD - g_player:getServerTime()))

		local function update(dt)
			local time = info.begin_upgrade_time + conf.CD - g_player:getServerTime()
			if time <= 0 then
				self:getApp():removeTopView()
				if schedulerEntry ~= nil then
			  		scheduler:unscheduleScriptEntry(schedulerEntry)
			  	end
				return
			end
			local cdTime = rn:getChildByName("cd_time")
			if cdTime then
				cdTime:setString(formatTime(time))
			end
		end

		schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)


		rn:getChildByName("develop"):setVisible(false)
		rn:getChildByName("group_help"):setVisible(false)

		local function clickSpeedUp(  )
			if checkCanSpeedUp() == true then

				-- if guideManager:getGuideType() then
				-- 	guideManager:doEvent("click")
				-- end

				self.speed_up_money = getSpeedUpNeedMoney()
				playEffectSound("sound/system/upgrade_skill.mp3")
        				local strData = Tools.encode("SpeedUpTechnologyReq", {
					tech_id =  self.data_.techID,         
				})
	     	    		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SPEED_UP_TECHNOLOGY_REQ"), strData)

	     	    		gl:retainLoading()
            			end
		end

		local speed_up = rn:getChildByName("speed_up")

		speed_up:setVisible(true)

		speed_up:addClickEventListener(function (sender)
            			
            if g_speed_up_need == false then
                local messageBoxSpeed = require("util.MessageBoxSpeed"):getInstance()
                local strinfo = CONF.STRING.get("technology_speed_up").VALUE
                messageBoxSpeed:reset(strinfo, clickSpeedUp)
                if display.getRunningScene():getChildByName("TopMessageBoxSpeed") then
                    display.getRunningScene():getChildByName("TopMessageBoxSpeed"):getChildByName("MessageBoxSpeed"):getChildByName("point"):setVisible(false)
                end
--            if g_technology_speed_up_flag == false then
--				messageBox:reset(CONF.STRING.get("technology_speed_up").VALUE, clickSpeedUp)
--				g_technology_speed_up_flag = true

				-- if guideManager:getGuideType() then
				-- 	guideManager:doEvent("click")
				-- end
			else
				clickSpeedUp()
			end
    			
		end)
		speed_up:getChildByName("num"):setString(string.format("%d",getSpeedUpNeedMoney()))
	else
		rn:getChildByName("cd_time"):setString(formatTime(conf.CD))
		rn:getChildByName("speed_up"):setVisible(false)
		rn:getChildByName("group_help"):setVisible(false)

		rn:getChildByName("develop"):addClickEventListener(function (sender)

			if checkCanDevelop() == true then 

				playEffectSound("sound/system/click.mp3")
            		
				local strData = Tools.encode("UpgradeTechReq", {
					tech_id =  self.data_.techID,         
				})
	     	    		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_UPGRADE_TECHNOLOGY_REQ"), strData)

	     	    		gl:retainLoading()
     	    		end
   			
		end)
	end
	

	local function onTouchBegan(touch, event)
		
		performWithDelay(self, function ()
			self:getApp():removeTopView() 
		end, 0.0001)

		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)


	local function recvMsg()



		local cmd,strData = GameHandler.handler_c.recvProtobuf()


        		if cmd == Tools.enum_id("CMD_DEFINE","CMD_UPGRADE_TECHNOLOGY_RESP") then

        			gl:releaseLoading()

        			local proto = Tools.decode("UpgradeTechResp",strData)
        	
        			if proto.result == 0 then
        				local tech_id = self.data_.techID

        				local num = 0
						for i,v in ipairs(CONF.TECHNOLOGY.get(tech_id).ITEM_ID) do
							if v == 3001 then
								num = CONF.TECHNOLOGY.get(tech_id).ITEM_NUM[i]
								break
							end
						end

        				flurryLogEvent("use_gold_upgrade_tech", {tech_id = tech_id, info = "before_use:"..(player:getResByIndex(1) + num)..",after_use:"..player:getResByIndex(1)}, 1, num)

        				local app = require("app.MyApp"):getInstance()

        				local is_guide = false
        				if guideManager:getGuideType() then
        					app:removeTopView()
							is_guide = true
						end

        				app:removeTopView()

        				if is_guide then
							guideManager:createGuideLayer(101)
						else
							app:addView2Top("TechnologyScene/TechnologyDevelopLayer", {techID = tech_id})
						end
        				

        				tips:tips(CONF.STRING.get("BuildingUp").VALUE)

        				
        			end
        		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SPEED_UP_TECHNOLOGY_RESP") then

        			gl:releaseLoading()

        			local proto = Tools.decode("SpeedUpTechnologyResp",strData)
        
        			if proto.result == 0 then
        				flurryLogEvent("speed_technology_cd",{tech_id = self.data_.techID, cost = self.speed_up_money},2)

        				local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("UpgradeSucess"))
						node:setPosition(cc.exports.VisibleRect:center())
						self:getParent():addChild(node)
        				flurryLogEvent("use_credit_speed_up_tech", {tech_id = tech_id, info = "before_use:"..(player:getMoney() + self.speed_up_money)..",after_use:"..player:getMoney()}, 1, self.speed_up_money)
        				local tech_id = self.data_.techID
        				local app = require("app.MyApp"):getInstance()
        				app:removeTopView()

      --   				if guideManager:getGuideType() then
						-- 	guideManager:doEvent("recv")
						-- end
        			end

        		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_LIST_RESP") then

        			gl:releaseLoading()
        			local proto = Tools.decode("GroupHelpListResp",strData)
        			if proto.result == "OK" then
        				self.help_list = proto.help_list
        			end

        			local info = g_player:getTechnologyByID(self.data_.techID)
					if info and info.begin_upgrade_time > 0 then
	        			local function clickGroupHelp( )
	        				local user_name = g_player:getName()
	        				local help_info = false

	        				

	        				if self:findTechInHelpList() == true then
	        					tips:tips(CONF.STRING.get("requested_group_help").VALUE)
	        					return
	        				end

	        				local strData = Tools.encode("GroupRequestHelpReq", {
						type =  CONF.EGroupHelpType.kTechnology,
						id = {self.data_.techID},
					})
	        				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_REQUEST_HELP_REQ"), strData)
					gl:retainLoading()
				end
				if self:findTechInHelpList() == false then
					local help = rn:getChildByName("group_help")
					help:setVisible(true)
					help:getChildByName("text"):setString(CONF:getStringValue("ask_help"))
					help:addClickEventListener(function (sender)
						clickGroupHelp()
					end)
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_REQUEST_HELP_RESP") then

			gl:releaseLoading()
        			local proto = Tools.decode("GroupRequestHelpResp",strData)

        			if proto.result == "HELPED" then
						tips:tips(CONF:getStringValue("requested_help"))
						return
					end
        			if proto.result == "REQUESTED" then
        				tips:tips(CONF.STRING.get("requested_group_help").VALUE)
	        			return
        			end
        			if proto.result == "NO_CD" then
						tips:tips(CONF:getStringValue("help_full"))
						return	
					end
        			if proto.result ~= "OK" then
 
        				return
        			end

        			self.help_list = proto.help_list
        			if self:findTechInHelpList() == true then
        				rn:getChildByName("group_help"):setVisible(false)
				rn:getChildByName("group_help"):setEnabled(false)
        			end
							

        			tips:tips(CONF.STRING.get("request_help_succeed").VALUE)
        		end

        		
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	if g_player:isGroup() == true then
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_LIST_REQ"), "1")
		gl:retainLoading()
	end
end

function TechnologyDevelopLayer:onExitTransitionStart()
	printInfo("TechnologyDevelopLayer:onExitTransitionStart()")

	if schedulerEntry ~= nil then
  		scheduler:unscheduleScriptEntry(schedulerEntry)
  	end

  	local eventDispatcher = self:getEventDispatcher()
    	eventDispatcher:removeEventListener(self.recvlistener_)
end

return TechnologyDevelopLayer