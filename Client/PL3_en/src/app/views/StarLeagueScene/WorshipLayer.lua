local g_player = require("app.Player"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local WorshipLayer = class("WorshipLayer", cc.load("mvc").ViewBase)

WorshipLayer.RESOURCE_FILENAME = "StarLeagueScene/WorshipLayer.csb"
WorshipLayer.NEED_ADJUST_POSITION = true

WorshipLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function WorshipLayer:OnBtnClick(event)
	if event.name == "ended" then

		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			self:getApp():removeTopView()
    		end
	end
end

function WorshipLayer:resetInfo()

	local rn = self:getResourceNode()

	local group_main = g_player:getPlayerGroupMain()

	local group_data = g_player:getGroupData()

	local cur_worship = group_main.worship_value or 0
	rn:getChildByName("cur_progress_num"):setString(cur_worship)

	local getted_reward_list
	if Tools.isEmpty(group_data.getted_worship_reward) == true then
		getted_reward_list = {false, false, false}
	else
		getted_reward_list = group_data.getted_worship_reward
	end
	
	local rewardConf = CONF.WORSHIPREWARD.get(1)

	rn:getChildByName("active_progress"):setPercent(cur_worship / rewardConf.MAX * 100)

	for i=1,3 do
		local reward_icon = rn:getChildByName("rewards"):getChildByName("reward_"..i)

		local need = rewardConf["ACTIVE_POINT"..i]

		reward_icon:getChildByName("btn"):setTag(0)

		if cur_worship < need then --不能领

			animManager:runAnimOnceByCSB(reward_icon,"TaskScene/ActiveIcon.csb" ,"unopen")
			
		elseif cur_worship >= need and getted_reward_list[i] == false then --可以领取

			animManager:runAnimByCSB(reward_icon, "TaskScene/ActiveIcon.csb" , "get")
			reward_icon:getChildByName("btn"):setTag(1)
		else--已经领取
			animManager:runAnimOnceByCSB(reward_icon, "TaskScene/ActiveIcon.csb" , "getted")
		end
	end

	rn:getChildByName("today_worship_count_num"):setString(group_main.today_worship_times)
	rn:getChildByName("today_worship_count_num_max"):setString("/"..(#group_main.user_list))
	
	if group_data.today_worship_level then
		if group_data.today_worship_level > 0 then
			for i=1,3 do
				local node = rn:getChildByName("type_"..i)
				node:getChildByName("btn"):setEnabled(false)
				if i == group_data.today_worship_level then
					node:getChildByName("btn"):getChildByName("icon"):setVisible(false)
					node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("already_worship"))
				end
			end
		end
	end
	
	local my_contribute_num = rn:getChildByName("my_contribute_num")
	my_contribute_num:setString(tostring(group_data.contribute))
	rn:getChildByName("contribute_icon"):setPositionX(my_contribute_num:getPositionX() + my_contribute_num:getContentSize().width)
end


function WorshipLayer:clickReward(level)


	local group_main = g_player:getPlayerGroupMain()
	local group_data = g_player:getGroupData()
	
	local canGet = false

	local function func( )
		playEffectSound("sound/system/click.mp3")
		if canGet == true then
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_WORSHIP_REQ"), Tools.encode("GroupWorshipReq", {
				type = 2,
				level = level,
			}))
			gl:retainLoading()
		end
	end

	local rewardConf = CONF.WORSHIPREWARD.get(1)
	local node = require("util.RewardNode"):createNode(rewardConf["REWARD"..level], func)

	local cur_worship = group_main.worship_value or 0
	local need = rewardConf["ACTIVE_POINT"..level]

	local getted_reward_list
	if Tools.isEmpty(group_data.getted_worship_reward) == true then
		getted_reward_list = {false, false, false}
	else
		getted_reward_list = group_data.getted_worship_reward
	end

	if cur_worship < need then --不能领

		node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))
		
	elseif cur_worship >= need and getted_reward_list[i] == true then --已经领取
		node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("has_get"))
	else
		node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("Get"))
		canGet = true
	end

	tipsAction(node)
	node:setPosition(cc.exports.VisibleRect:center())
	node:setName("reward_node")
	self:addChild(node)
end

function WorshipLayer:onEnterTransitionFinish()
	printInfo("WorshipLayer:onEnterTransitionFinish()")

	local rn = self:getResourceNode()
	rn:getChildByName("my_contribute_0"):setString(CONF:getStringValue("worship_time"))

	rn:getChildByName("title"):setString(CONF:getStringValue("worship_title"))
	local cur_progress = rn:getChildByName("cur_progress")
	cur_progress:setString(CONF:getStringValue("cur_progress"))
	rn:getChildByName("cur_progress_num"):setPositionX(cur_progress:getPositionX() + cur_progress:getContentSize().width)

	local today_worship_count = rn:getChildByName("today_worship_count")
	today_worship_count:setString(CONF:getStringValue("today_worship_count"))
	local today_worship_count_num = rn:getChildByName("today_worship_count_num")
	today_worship_count_num:setPositionX(today_worship_count:getPositionX() + today_worship_count:getContentSize().width)

	rn:getChildByName("today_worship_count_num_max"):setPositionX(today_worship_count_num:getPositionX() + today_worship_count_num:getContentSize().width)

	

	local rewardConf = CONF.WORSHIPREWARD.get(1)
	local reward_length = rn:getChildByName("active_progress_buttom"):getContentSize().width
	for i=1,3 do
		local reward_icon = rn:getChildByName("rewards"):getChildByName("reward_"..i)
		local need = rewardConf["ACTIVE_POINT"..i]

		reward_icon:setPositionX(need / rewardConf.MAX * reward_length)
		reward_icon:getChildByName("num"):setString(tostring(need))

		reward_icon:getChildByName("btn"):loadTextures("TaskScene/ui/active_"..i..".png", "TaskScene/ui/active_select_"..i..".png", "TaskScene/ui/active_gray_"..i..".png")
		reward_icon:getChildByName("get"):setTexture("TaskScene/ui/active_gray_"..i..".png")
		reward_icon:getChildByName("btn"):setTag(i)
		
		reward_icon:getChildByName("btn"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/click.mp3")
			self:clickReward(i)
		end)
	end


	for i=1,3 do
		local conf = CONF.WORSHIP.get(i)
		local node = rn:getChildByName("type_"..i)

		node:getChildByName("progress"):setString(CONF:getStringValue("progress"))
		node:getChildByName("contribute"):setString(CONF:getStringValue("prosonal_contribute"))

		node:getChildByName("progress_num"):setString("+"..conf.SCHEDULE)
		node:getChildByName("contribute_num"):setString("+"..conf.CONTRIBUTION)
		
		local itemConf = CONF.ITEM.get(conf.TYPE)
		if itemConf.TYPE ~= CONF.EItemType.kRes1 then
			node:getChildByName("btn"):loadTextures("Common/newUI/button_yellow.png", "Common/newUI/button_yellow_light.png", "Common/newUI/button_blue_grray.png")
		end
		node:getChildByName("btn"):getChildByName("text"):setString(tostring(conf.NUM))
		node:getChildByName("btn"):getChildByName("icon"):setTexture("ItemIcon/"..itemConf.ICON_ID..".png")
		node:getChildByName("btn"):setTag(i)
		node:getChildByName("btn"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/click.mp3")

			if itemConf.TYPE == CONF.EItemType.kRes1 then
				
				if g_player:getResByIndex(1) < conf.NUM then
					Tips:tips(CONF:getStringValue("notEnoughGold"))
					return
				end
			else
				if g_player:getMoney() < conf.NUM then
					Tips:tips(CONF:getStringValue("no enought credit"))
					return
				end
			end
			
			self.worship_index = i
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_WORSHIP_REQ"), Tools.encode("GroupWorshipReq", {
				type = 1,
				level = i,
			}))
			gl:retainLoading()
		end)
	end
	local my_contribute = rn:getChildByName("my_contribute")
	my_contribute:setString(CONF:getStringValue("my_contribute"))
	rn:getChildByName("my_contribute_num"):setPositionX(my_contribute:getPositionX() + my_contribute:getContentSize().width)
	self:resetInfo()

	local function recvMsg()
		--print("WorshipLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_WORSHIP_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("GroupWorshipResp",strData)

			if proto.req.type == 1 then
				if proto.result ~= "OK" then
					print("msg error:",proto.result)
					return
				end
				self:resetInfo()
				Tips:tips(CONF:getStringValue("worship_success"))
	
				local conf = CONF.WORSHIP.get(self.worship_index)
				flurryLogEvent("group_worship", {id = tostring(self.worship_index), cost = tostring(conf.NUM)}, 2)

			elseif proto.req.type == 2 then

				if proto.result ~= "OK" then
					print("msg error:", proto.result)
					return
				end
				self:resetInfo()
				Tips:tips(CONF:getStringValue("getSucess"))
			end
		end
	end
	local eventDispatcher = self:getEventDispatcher()
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

function WorshipLayer:onExitTransitionStart()
	printInfo("WorshipLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return WorshipLayer