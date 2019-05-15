
local PandectNode = class("PandectNode", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local app = require("app.MyApp"):getInstance()

local winSize = cc.Director:getInstance():getWinSize()

local animManager = require("app.AnimManager"):getInstance()

local g_sendList = require("util.SendList"):getInstance()

PandectNode.RESOURCE_FILENAME = "StarLeagueScene/league_pandect.csb"

function PandectNode:onEnterTransitionFinish()

end

function PandectNode:init(scene,data)

	self.scene_ = scene
	self.group_list = data.group 
	self.info_list = data.user_info
	self.isExit_ = false

	local rn = self:getResourceNode()
	rn:getChildByName("text"):setString(CONF:getStringValue("covenant_notice"))

	local label = cc.Label:createWithTTF("", "fonts/cuyabra.ttf", 18)
	label:setAnchorPoint(cc.p(0,1))
	label:setPosition(cc.p(rn:getChildByName("broadcast"):getPosition()))
	label:setLineBreakWithoutSpace(true)
	label:setMaxLineWidth(300)
	label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
	-- label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
	rn:addChild(label)

	-- rn:getChildByName("broadcast"):removeFromParent()
	label:setName("notice")

	label:setOpacity(0)
	label:setPositionX(label:getPositionX() - 34)
	label:runAction(cc.Spawn:create(cc.FadeIn:create(0.33), cc.MoveBy:create(0.33, cc.p(34, 0))))

	rn:getChildByName("broadcast"):setVisible(false)
	-- rn:getChildByName("broadcast"):setName("notice")
	rn:getChildByName("btn_worship"):getChildByName("point"):setVisible(false)
	rn:getChildByName("btn_help"):getChildByName("point"):setVisible(false)
	rn:getChildByName("btn_power"):getChildByName("point"):setVisible(false)
	rn:getChildByName("btn_shop"):getChildByName("point"):setVisible(false)
	rn:getChildByName("btn_site"):getChildByName("point"):setVisible(false)
	local group_main = player:getPlayerGroupMain()
	if Tools.isEmpty(group_main) == false then

		local num = #group_main.enlist_list + #group_main.attack_our_list

		rn:getChildByName("btn_diary"):getChildByName("point"):setVisible(num > 0)
	else
		rn:getChildByName("btn_diary"):getChildByName("point"):setVisible(false)
	end

	rn:getChildByName("btn_lv"):addClickEventListener(function ( ... )
		self:createMessage(1)
	end)

	rn:getChildByName("btn_exit"):addClickEventListener(function ( ... )
		self:createMessage(2)
	end)

	rn:getChildByName("btn_broadcast"):addClickEventListener(function ( ... )
		self:createMessage(3)
	end)

	rn:getChildByName("btn_site"):addClickEventListener(function ( ... )
		self:createMessage(4)
	end)

	rn:getChildByName("btn_shop"):addClickEventListener(function ( ... )
		-- self:createMessage(5)
		-- tips:tips(CONF:getStringValue("coming soon"))
		-- app:addView2Top("ShopScene/ShopLayer" , {type = 5})
		require("app.ExViewInterface"):getInstance():ShowShopUI({type = 5})
	end)

	rn:getChildByName("btn_diary"):addClickEventListener(function ( ... )
		-- tips:tips(CONF:getStringValue("coming soon"))
		rn:getChildByName("btn_diary"):getChildByName("point"):setVisible(false)
		app:pushView("WarScene/WarScene",{})
	end)

	rn:getChildByName("btn_worship"):getChildByName("text"):setString(CONF:getStringValue("worship_title"))
	rn:getChildByName("btn_worship"):addClickEventListener(function ( sender )
		self.scene_:getApp():addView2Top("StarLeagueScene/WorshipLayer")
	end)

	rn:getChildByName("btn_help"):addClickEventListener(function ( ... )
		gl:retainLoading()

		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_LIST_REQ"),"0") 
	end)

	rn:getChildByName("btn_chat"):addClickEventListener(function ( ... )
		local layer = self.scene_:getApp():createView("ChatLayer/ChatLayer", {name = "star"})
		self.scene_:addChild(layer)
	end)

	rn:getChildByName("boss_fight"):addClickEventListener(function ( ... )
		self.scene_:getApp():pushView("StarLeagueScene/GroupBossScene", {group_list = self.group_list})
	end)

	rn:getChildByName("btn_power"):addClickEventListener(function ( ... )
		self.scene_:getApp():pushView("RankLayer/RankLayer",{type = "leaguePower"}) 
	end)

	rn:getChildByName("league_fight"):addClickEventListener(function ( ... )
		-- tips:tips(CONF:getStringValue("coming soon"))
	end)

	--ui 本地化--disbandFail
	if player:getGroupData().job == 1 then
		rn:getChildByName("btn_exit"):getChildByName("text"):setString(CONF:getStringValue("disbandLeague"))
	else
		rn:getChildByName("btn_exit"):getChildByName("text"):setString(CONF:getStringValue("quitLeague"))
	end
	
	rn:getChildByName("btn_diary"):getChildByName("text"):setString(CONF:getStringValue("covenant war"))
	rn:getChildByName("btn_site"):getChildByName("text"):setString(CONF:getStringValue("leagueSite"))
	rn:getChildByName("btn_shop"):getChildByName("text"):setString(CONF:getStringValue("leagueShop"))
	rn:getChildByName("btn_help"):getChildByName("text"):setString(CONF:getStringValue("leagueHelp"))
	rn:getChildByName("text_0"):setString(CONF:getStringValue("notice"))
	-- rn:getChildByName("btn_broadcast"):getChildByName("text"):setString(CONF:getStringValue("modifyCast"))
	rn:getChildByName("member"):setString(CONF:getStringValue("sumMember"))
	rn:getChildByName("avalon"):setString(CONF:getStringValue("leader"))
	rn:getChildByName("military"):setString(CONF:getStringValue("sumContribution"))
	rn:getChildByName("chairman"):setString(CONF:getStringValue("chairman"))
	rn:getChildByName("power"):setString(CONF:getStringValue("combat"))
	rn:getChildByName("Text_69"):setString(CONF:getStringValue("leagueFight"))
	rn:getChildByName("Text_69_0"):setString(CONF:getStringValue("leagueBoss"))
	rn:getChildByName("btn_power"):getChildByName("rank"):setString(CONF:getStringValue("ranking")..":")
	self:resetInfo()

	textSetPos(rn:getChildByName("avalon_name"),rn:getChildByName("avalon"),2)
	textSetPos(rn:getChildByName("power_num"),rn:getChildByName("power"),2)
	textSetPos(rn:getChildByName("military_num"),rn:getChildByName("military"),2)
	textSetPos(rn:getChildByName("chairman_now"),rn:getChildByName("chairman"),2)
	textSetPos(rn:getChildByName("chairman_max"),rn:getChildByName("chairman_now"),0)
	textSetPos(rn:getChildByName("member_now"),rn:getChildByName("member"),2)
	textSetPos(rn:getChildByName("member_max"),rn:getChildByName("member_now"),0)
	-- self:nodeAni(rn:getChildByName("lv_num"))
	-- self:nodeAni(rn:getChildByName("avalon_name"))
	-- self:nodeAni(rn:getChildByName("power_num"))
	-- self:nodeAni(rn:getChildByName("military_num"))
	-- self:nodeAni(rn:getChildByName("member_now"))
	-- self:nodeAni(rn:getChildByName("member_max"))
	-- self:nodeAni(rn:getChildByName("chairman_now"))
	-- self:nodeAni(rn:getChildByName("chairman_max"))
	-- self:nodeAni(rn:getChildByName("btn_lv"))
	-- self:nodeAni(rn:getChildByName("btn_power"))
	-- self:nodeAni(rn:getChildByName("rank"))
	-- self:nodeAni(rn:getChildByName("rank_num"))

	local function recvMsg()
		print("PandectNode:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_EXIT_RESP") then
			gl:releaseLoading("CMD_GROUP_EXIT_RESP")

			local proto = Tools.decode("GroupExitGroupResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				self.isExit_ = false

				player.group_main_ = proto.user_sync.group_main
				self.scene_:getParent():getNoGroup()
			end
		

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_BROADCAST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupBroadcastResp",strData)

			if proto.result == "FAIL" then
				print("error :",proto.result)
			elseif proto.result == "OK" then
				if self.broadcast_edit then
					self.broadcast_edit:unregisterScriptEditBoxHandler()
					self.broadcast_edit = nil
				end

				if self.blurb_edit then
					self.blurb_edit:unregisterScriptEditBoxHandler()
					self.blurb_edit = nil
				end

				if self.scene_:getChildByName("message") then
					self.scene_:getChildByName("message"):removeFromParent()
				end
			elseif proto.result == "DIRTY" then
				tips:tips(CONF:getStringValue("dirty_message"))
			end
		

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOIN_CONDITION_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupJoinConditionResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				if self.setup_edit_1 then
					-- self.setup_edit_1:unregisterScriptEditBoxHandler()
					self.setup_edit_1 = nil
				end

				if self.setup_edit_2 then
					-- self.setup_edit_2:unregisterScriptEditBoxHandler()
					self.setup_edit_2 = nil
				end

				if self.scene_:getChildByName("message") then
					self.scene_:getChildByName("message"):removeFromParent()
				end
			end
		

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_DISBAND_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupDisbandResp",strData)
			if proto.result == "FAIL" then
				print("error :",proto.result)
			elseif proto.result == "OK" then
				tips:tips(CONF:getStringValue("disbandSucess"))

				player.group_main_ = proto.user_sync.group_main
				self.scene_:getParent():getNoGroup()
			else
			   print("error :",proto.result)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_LIST_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupHelpListResp",strData)

			if proto.result ~= "OK" then
				print("error :",proto.result)
			else
				self.help_list = proto.help_list
				self:createMessage(6)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_LEVELUP_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GroupLevelupResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				tips:tips(CONF:getStringValue("upSucess"))
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_RESP") then

			-- gl:releaseLoading()

			local proto = Tools.decode("GroupHelpResp",strData)

			if proto.result ~= "OK" then
				print("GroupHelpResp error :",proto.result)
			elseif proto.result == "NO_CD" then
				tips:tips(CONF:getStringValue("help_full"))
			elseif proto.result == "HELP_TIME_MAX" then
				tips:tips(CONF:getStringValue("help_full"))
			else
				tips:tips(CONF:getStringValue("help_people"))

				self.help_list = proto.help_list
				self:resetHelpList()
			end

		end

	end
	
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	-- animManager:runAnimOnceByCSB(rn, "StarLeagueScene/league_pandect.csb", "1", function ( ... )
		self:resetInfo()
	-- end)
	self.groupListener_ = cc.EventListenerCustom:create("update_group_main", function (event)
		local group_main = player:getPlayerGroupMain()
  		if Tools.isEmpty(group_main) == false then
	  		local num = #group_main.enlist_list + #group_main.attack_our_list

			rn:getChildByName("btn_diary"):getChildByName("point"):setVisible(num > 0)
	  	end
  		end)
	eventDispatcher:addEventListenerWithFixedPriority(self.groupListener_, FixedPriority.kNormal)
end

function PandectNode:getIsExit( ... )
	return self.isExit_
end

function PandectNode:updateUI( group_list, info_list, join_list )
	self.group_list = group_list
	self.info_list = info_list

	self:resetInfo()
end

function PandectNode:resetInfo()
	
	local rn = self:getResourceNode()

	local conf = CONF.GROUP.get(self.group_list.level)

	local next_conf = CONF.GROUP.check(self.group_list.level + 1)
	if rn:getChildByName("max_sprite") then
		rn:getChildByName("max_sprite"):removeFromParent()
	end
	if not next_conf then
		rn:getChildByName("btn_lv"):setVisible(false)
		local sp = cc.Sprite:create("StarLeagueScene/ui/MAX.png")
		sp:setName("max_sprite")
		sp:setPosition(rn:getChildByName("btn_lv"):getPosition())
		rn:addChild(sp)
	end
	rn:getChildByName("league_name"):setString(self.group_list.nickname)
	rn:getChildByName("icon"):setTexture("StarLeagueScene/ui/icon_star_0"..self.group_list.icon_id..".png")
	rn:getChildByName("lv_num"):setString(self.group_list.level)
	rn:getChildByName("notice"):setString(self.group_list.broadcast)

	local avalon = ""
	local num = 0
	for i,v in ipairs(self.group_list.user_list) do
		if v.job == 1 then
			avalon = v.nickname
		end

		if v.job == 2 then
			num = num + 1
		end
	end

	local power = 0
	for i,v in ipairs(self.info_list) do
		power = power + v.power
	end

	local military = rn:getChildByName("military")
	local military_num = rn:getChildByName("military_num")
	rn:getChildByName("avalon_name"):setString(avalon)
	rn:getChildByName("power_num"):setString(power)
	rn:getChildByName("btn_power"):getChildByName("rank_num"):setString(self.group_list.rank)
	rn:getChildByName("military_num"):setString(self.group_list.contribute)
	military_num:setPositionX(military:getPositionX() + military:getContentSize().width + 2)
	rn:getChildByName("member_now"):setString(table.getn(self.group_list.user_list))

	local job = player:getGroupData().job

	for k,v in ipairs(self.group_list.user_list) do
		if v.user_name == player:getName() then
			job = v.job
			break
		end
	end

	if job == 1 then
		rn:getChildByName("btn_exit"):getChildByName("text"):setString(CONF:getStringValue("disbandLeague"))
	else
		rn:getChildByName("btn_exit"):getChildByName("text"):setString(CONF:getStringValue("quitLeague"))
	end

	local max_user = conf.MAX_USER + Tools.getValueByTechnologyAddition(conf.MAX_USER, CONF.ETechTarget_1.kGroup, 0, CONF.ETechTarget_3_Group.kMaxUser, player:getTechnolgList(), player:getPlayerGroupTech())
	rn:getChildByName("member_max"):setString("/"..max_user)
	rn:getChildByName("chairman_now"):setString(num)
	rn:getChildByName("chairman_max"):setString("/"..conf.MANAGER)

	--setpos
	rn:getChildByName("btn_lv"):setPositionX(rn:getChildByName("lv_num"):getPositionX() + rn:getChildByName("lv_num"):getContentSize().width + rn:getChildByName("btn_lv"):getContentSize().width/2+ 10)

	local rank_pos = rn:getChildByName("btn_power"):getPositionX()
	-- rn:getChildByName("btn_power"):setPositionX(rn:getChildByName("power_num"):getPositionX() + rn:getChildByName("power_num"):getContentSize().width + rn:getChildByName("btn_power"):getContentSize().width/2 + 10)
	rn:getChildByName("btn_power"):getChildByName("rank_num"):setPositionX(rn:getChildByName("btn_power"):getChildByName("rank"):getPositionX() + rn:getChildByName("btn_power"):getChildByName("rank"):getContentSize().width)


	rn:getChildByName("member_now"):setPositionX(rn:getChildByName("member"):getPositionX() + rn:getChildByName("member"):getContentSize().width + 10)
	rn:getChildByName("member_max"):setPositionX(rn:getChildByName("member_now"):getPositionX() + rn:getChildByName("member_now"):getContentSize().width )
	rn:getChildByName("chairman_now"):setPositionX(rn:getChildByName("chairman"):getPositionX() + rn:getChildByName("chairman"):getContentSize().width + 10)
	rn:getChildByName("chairman_max"):setPositionX(rn:getChildByName("chairman_now"):getPositionX() + rn:getChildByName("chairman_now"):getContentSize().width )

	-- local line_diff = -80
	-- rn:getChildByName("line_1"):setContentSize(cc.size(rn:getChildByName("btn_lv"):getPositionX() + rn:getChildByName("btn_lv"):getContentSize().width/2 + line_diff, rn:getChildByName("line_1"):getContentSize().height))
	-- rn:getChildByName("line_2"):setContentSize(cc.size(rn:getChildByName("avalon_name"):getPositionX() + rn:getChildByName("avalon_name"):getContentSize().width + line_diff, rn:getChildByName("line_2"):getContentSize().height))
	-- rn:getChildByName("line_3"):setContentSize(cc.size(rn:getChildByName("btn_power"):getPositionX() + rn:getChildByName("btn_power"):getContentSize().width/2 + line_diff, rn:getChildByName("line_3"):getContentSize().height))
	-- rn:getChildByName("line_4"):setContentSize(cc.size(rn:getChildByName("military_num"):getPositionX() + rn:getChildByName("military_num"):getContentSize().width + line_diff, rn:getChildByName("line_4"):getContentSize().height))
	-- rn:getChildByName("line_5"):setContentSize(cc.size(rn:getChildByName("member_max"):getPositionX() + rn:getChildByName("member_max"):getContentSize().width + line_diff, rn:getChildByName("line_5"):getContentSize().height))
	-- rn:getChildByName("line_6"):setContentSize(cc.size(rn:getChildByName("chairman_max"):getPositionX() + rn:getChildByName("chairman_max"):getContentSize().width + line_diff, rn:getChildByName("line_6"):getContentSize().height))

end

function PandectNode:createMessage( type )  -- 1 升级 2 退出 3 修改公告和简介 4 进会要求设置 5 商店 6帮助
    local rn = self:getResourceNode()
	local msgNode = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/MessageNode.csb")
	msgNode:getChildByName("back"):setSwallowTouches(true)
	msgNode:getChildByName("close"):addClickEventListener(function ( ... )

		if self.broadcast_edit then
			self.broadcast_edit:unregisterScriptEditBoxHandler()
			self.broadcast_edit = nil
		end

		if self.blurb_edit then
			self.blurb_edit:unregisterScriptEditBoxHandler()
			self.blurb_edit = nil
		end

		if self.setup_edit_1 then
			-- self.setup_edit_1:unregisterScriptEditBoxHandler()
			self.setup_edit_1 = nil
		end

		if self.setup_edit_2 then
			-- self.setup_edit_2:unregisterScriptEditBoxHandler()
			self.setup_edit_2 = nil
		end

		msgNode:removeFromParent()
	end)
	msgNode:setName("message")

	if type == 1 then
		local node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/up_league.csb")

		node:getChildByName("lv_now"):setString(self.group_list.level)
		node:getChildByName("lv_up"):setString(self.group_list.level + 1)
		node:getChildByName("member_max_0"):setString(CONF:getStringValue("leaderPermission"))
		node:getChildByName("member_max_0_0"):setString(CONF:getStringValue("leagueMember"))
		node:getChildByName("member_max_0_0_1"):setString(CONF:getStringValue("leagueTechnologyNum"))
		node:getChildByName("member_max_0_0_1_0"):setString(CONF:getStringValue("leagueContribution"))
		node:getChildByName("Text_1"):setString(CONF:getStringValue("upLeague"))
		node:getChildByName("upgrade"):getChildByName("text"):setString(CONF:getStringValue("upgrade"))
		-- node:getChildByName("Text_1_0_0"):setString(CONF:getStringValue("sumMember"))
		node:getChildByName("Text_1_0_0_1"):setString(CONF:getStringValue("upgradeDemand"))
		--member_max_0_0_0_0
		node:getChildByName("member_max_0_0_0_0"):setString(CONF:getStringValue("achieve"))
		node:getChildByName("member_max_0_0_0"):setString(CONF:getStringValue("achieve"))
		node:getChildByName("member_max_0_0_0_0_0"):setString(CONF:getStringValue("Cost"))


		local conf = CONF.GROUP.get(self.group_list.level)

		local check = CONF.GROUP.check(self.group_list.level+1)

		if check then
			local up_conf = CONF.GROUP.get(self.group_list.level+1)

			node:getChildByName("member_now"):setString(conf.MAX_USER..CONF:getStringValue("sumMember2"))
			node:getChildByName("member_up"):setString(up_conf.MAX_USER..CONF:getStringValue("sumMember2"))

			--setpos 
			-- node:getChildByName("evolution_1"):setPositionX(node:getChildByName("lv_now"):getPositionX() + node:getChildBy	Name("lv_now"):getContentSize().width + node:getChildByName("evolution_1"):getContentSize().width/2 + 5)
			-- node:getChildByName("evolution_2"):setPositionX(node:getChildByName("member_now"):getPositionX() + node:getChildByName("member_now"):getContentSize().width + node:getChildByName("evolution_2"):getContentSize().width/2 + 5)
			-- node:getChildByName("member_up"):setPositionX(node:getChildByName("evolution_2"):getPositionX() + node:getChildByName("evolution_2"):getContentSize().width/2 + 5)

			local canUpgrade = true

			if player:getGroupData().job ~= 1 then
				node:getChildByName("icon_1"):setTexture("StarLeagueScene/ui/icon_no.png")
				canUpgrade = false
			end

			node:getChildByName("member_num"):setString(up_conf.LEVELUP_MEMBER_NUM)
			node:getChildByName("tech_num"):setString(up_conf.LEVELUP_TECH_NUM)
			node:getChildByName("gongxian_num"):setString(up_conf.CONTRIBUTE)

			if #self.group_list.user_list < up_conf.LEVELUP_MEMBER_NUM then
				node:getChildByName("icon_2"):setTexture("StarLeagueScene/ui/icon_no.png")
				canUpgrade = false
			end

			local tech_num = 0 
			for i,v in ipairs(self.group_list.tech_list) do
				if v.status == 3 then
					tech_num = tech_num + 1
				end
			end

			if tech_num < up_conf.LEVELUP_TECH_NUM then
				node:getChildByName("icon_3"):setTexture("StarLeagueScene/ui/icon_no.png")
				canUpgrade = false
			end

			if self.group_list.contribute < up_conf.CONTRIBUTE then
				node:getChildByName("icon_4"):setTexture("StarLeagueScene/ui/icon_no.png")
				canUpgrade = false
			end

			node:getChildByName("upgrade"):addClickEventListener(function ( ... )
				if player:getGroupData().job  ~= 1 then
					tips:tips(CONF:getStringValue("Permission denied"))
				end

				if canUpgrade == false then
					tips:tips(CONF:getStringValue("upFailedMsg"))
				else
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_LEVELUP_REQ"),"nil")
				end

				msgNode:removeFromParent()

			end)
		else
			node:getChildByName("Text_1_0_1"):setVisible(false)
			node:getChildByName("lv_up"):setVisible(false)
			node:getChildByName("evolution_2"):setVisible(false)
			node:getChildByName("member_up"):setVisible(false)
			node:getChildByName("ui_brackets_3"):setVisible(false)
			node:getChildByName("Text_1_0_0_1"):setVisible(false)
			for i=1,4 do
				node:getChildByName("icon_"..i):setVisible(false)
			end
			node:getChildByName("member_max_0"):setVisible(false)
			node:getChildByName("member_max_0_0"):setVisible(false)
			node:getChildByName("member_max_0_0_1"):setVisible(false)
			node:getChildByName("member_max_0_0_1_0"):setVisible(false)
			node:getChildByName("member_max_0_0_0"):setVisible(false)
			node:getChildByName("member_max_0_0_0_0"):setVisible(false)
			node:getChildByName("member_max_0_0_0_0_0"):setVisible(false)
			node:getChildByName("member_num"):setVisible(false)
			node:getChildByName("tech_num"):setVisible(false)
			node:getChildByName("gongxian_num"):setVisible(false)
			node:getChildByName("upgrade"):setVisible(false)
			node:getChildByName("evolution_1"):setTexture("StarLeagueScene/ui/MAX.png")
		end

		node:setName("node")
		msgNode:addChild(node)

	elseif type == 2 then
		local node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/exit_league.csb")
		-- local title = node:getChildByName("Text_1")
		local btnText = node:getChildByName("yes"):getChildByName("text")
		btnText:setString(CONF:getStringValue("yes"))

		node:getChildByName("back"):setSwallowTouches(true)
		node:getChildByName("back"):addClickEventListener(function ( ... )
			node:removeFromParent()
		end)

		node:getChildByName("yes_0"):getChildByName("text"):setString(CONF:getStringValue("cancel"))
		-- if player:getGroupData().job == 1 then
		--     title:setString(CONF:getStringValue("disbandLeague"))
		--     btnText:setString(CONF:getStringValue("doDisband"))
		-- else
		--     title:setString(CONF:getStringValue("quitLeague"))
		--     btnText:setString(CONF:getStringValue("doQuit"))
		-- end  

		local job = player:getGroupData().job

		for k,v in ipairs(self.group_list.user_list) do
			if v.user_name == player:getName() then
				job = v.job
				break
			end
		end

		node:getChildByName("league_name"):setString(self.group_list.nickname)
		node:getChildByName("Text_1_0_1"):setString(CONF:getStringValue("covenant").."?")
		if job == 1 then
			node:getChildByName("Text_1_0"):setString(CONF:getStringValue("AreYouSureToDisband"))
		else
			node:getChildByName("Text_1_0"):setString(CONF:getStringValue("AreYouSureToQuit"))
		end

		local string1 = "#FFFFFF02"
		local string2 = "#FFF4C602"
		local string3 = "#FFFFFF02"

		if job == 1 then
			string1 = string1..CONF:getStringValue("AreYouSureToDisband")
		else
			string1 = string1..CONF:getStringValue("AreYouSureToQuit")
		end

		string2 = string2..self.group_list.nickname
		string3 = string3..CONF:getStringValue("covenant").."?"

		local text_str = string1..string2..string3
		local richText = createRichTextNeedChangeColor(text_str,22)
		richText:setContentSize(cc.size(node:getChildByName("Text_1_0"):getContentSize().width, node:getChildByName("Text_1_0"):getContentSize().height))
		richText:ignoreContentAdaptWithSize(false)
		richText:setAnchorPoint(cc.p(0,1))
		richText:setPosition(cc.p(node:getChildByName("Text_1_0"):getPosition()))
		node:addChild(richText)

		node:getChildByName("yes"):addClickEventListener(function ( ... )

			if job == 1 then
				if table.getn(self.group_list.user_list) > 1 then
					tips:tips(CONF:getStringValue("disbandFail"))

				else
					-- local strData = Tools.encode(nil, nil)
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_DISBAND_REQ"),"nil")

					gl:retainLoading()
				end

				return

			end

			self.isExit_ = true
			local strData = Tools.encode("GroupExitGroupReq", {
				result = 0,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_EXIT_REQ"),strData)

			gl:retainLoading("CMD_GROUP_EXIT_REQ")
		end)

		node:getChildByName("yes_0"):addClickEventListener(function ( ... )
			-- msgNode:removeFromParent()
			node:removeFromParent()
		end)

		node:setName("node")
		self:getResourceNode():addChild(node)

		return
		-- msgNode:addChild(node)
	elseif type == 3 then
        if player:getGroupData().job == 3 then
		    tips:tips(CONF:getStringValue("Permission denied"))
            return
		end
		local node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/broadcast_and_blurb.csb")
		node:getChildByName("Text_1"):setString(CONF:getStringValue("BroadcastAndBlurb"))
		node:getChildByName("save"):getChildByName("text"):setString(CONF:getStringValue("Save"))
		node:getChildByName("mail"):getChildByName("text"):setString(CONF:getStringValue("mail"))

		node:getChildByName("Text_1_0"):setString(CONF:getStringValue("writeNewBroadcast"))
		node:getChildByName("Text_1_0_0"):setString(CONF:getStringValue("writeNewBlurb"))

		node:getChildByName("mail"):setEnabled(false)
		--------
		local broadcast_placeHolder = node:getChildByName("broadcast_text")
		local placeHolderColor = broadcast_placeHolder:getTextColor()
		local fontColor = broadcast_placeHolder:getTextColor()
		local fontName = broadcast_placeHolder:getFontName()
		local fontSize = broadcast_placeHolder:getFontSize()
		local maxLength = broadcast_placeHolder:getMaxLength()

		local broadcast_back = node:getChildByName(string.format("broadcast_back"))
		
		self.broadcast_edit = ccui.EditBox:create(broadcast_back:getContentSize(),"aa")
		self.broadcast_edit:setContentSize(cc.size(self.broadcast_edit:getContentSize().width+10000,self.broadcast_edit:getContentSize().height))
		node:addChild(self.broadcast_edit)
		self.broadcast_edit:setPosition(cc.p(broadcast_back:getPosition()))
		self.broadcast_edit:setPositionX(self.broadcast_edit:getPositionX()-5000)
		self.broadcast_edit:setPlaceHolder(CONF:getStringValue("writeNewBroadcast"))
		self.broadcast_edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
		self.broadcast_edit:setPlaceholderFont(fontName,fontSize)
		self.broadcast_edit:setFontSize(0)
		self.broadcast_edit:setPlaceholderFontColor(fontColor)
		self.broadcast_edit:setFont(fontName,fontSize)
		self.broadcast_edit:setFontColor(fontColor)
		self.broadcast_edit:setReturnType(1)
		self.broadcast_edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		self.broadcast_edit:setMaxLength(maxLength)
		self.broadcast_edit:setName("broadcast_text")

		-- broadcast_back:removeFromParent()
		
		broadcast_placeHolder:removeFromParent()

		------

		local blurb_placeHolder = node:getChildByName("blurb_text")
		local blurb_placeHolderColor = blurb_placeHolder:getTextColor()
		local blurb_fontColor = blurb_placeHolder:getTextColor()
		local blurb_fontName = blurb_placeHolder:getFontName()
		local blurb_fontSize = blurb_placeHolder:getFontSize()
		local blurb_maxLength = blurb_placeHolder:getMaxLength()

		local blurb_back = node:getChildByName(string.format("blurb_back"))
		

		self.blurb_edit = ccui.EditBox:create(blurb_back:getContentSize(),"aa")
		self.blurb_edit:setContentSize(cc.size(self.blurb_edit:getContentSize().width+10000,self.blurb_edit:getContentSize().height))
		node:addChild(self.blurb_edit)
		self.blurb_edit:setPosition(cc.p(blurb_back:getPosition()))
		self.blurb_edit:setPositionX(self.blurb_edit:getPositionX()-5000)
		self.blurb_edit:setPlaceHolder(CONF:getStringValue("writeNewBlurb"))
		self.blurb_edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
		self.blurb_edit:setPlaceholderFont(fontName,fontSize)
		self.blurb_edit:setPlaceholderFontColor(fontColor)
		self.blurb_edit:setFont(fontName,fontSize)
		self.blurb_edit:setFontColor(fontColor)
		self.blurb_edit:setReturnType(1)
		self.blurb_edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		self.blurb_edit:setMaxLength(blurb_maxLength)
		self.blurb_edit:setName("blurb_text")

		-- blurb_back:removeFromParent()
		
		blurb_placeHolder:removeFromParent()

		-------

		local broadcast_label = cc.Label:createWithTTF(self.group_list.broadcast, "fonts/cuyabra.ttf", 20)
		broadcast_label:setAnchorPoint(cc.p(0,1))
		broadcast_label:setPosition(cc.p(broadcast_placeHolder:getPosition()))
		broadcast_label:setLineBreakWithoutSpace(true)
		broadcast_label:setMaxLineWidth(600)
		broadcast_label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
		broadcast_label:setName("broadcast_label")

		if self.group_list.broadcast == "" or self.group_list.broadcast == nil then
			broadcast_label:setTextColor(cc.c4b(209,209,209,255))
			-- broadcast_label:enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
		else
			broadcast_label:setTextColor(cc.c4b(73,73,73,255))
			-- broadcast_label:enableShadow(cc.c4b(73, 73, 73, 255),cc.size(0.5,0.5))

		end

		node:addChild(broadcast_label)
		--
		local blurb_label = cc.Label:createWithTTF(self.group_list.blurb, "fonts/cuyabra.ttf", 20)
		blurb_label:setAnchorPoint(cc.p(0,1))
		blurb_label:setPosition(cc.p(blurb_placeHolder:getPosition()))
		blurb_label:setLineBreakWithoutSpace(true)
		blurb_label:setMaxLineWidth(600)
		blurb_label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
		blurb_label:setName("blurb_label")

		if self.group_list.blurb == "" or self.group_list.blurb == nil then
			blurb_label:setTextColor(cc.c4b(209,209,209,255))
			-- blurb_label:enableShadow(cc.c4b(209, 209, 209, 255),cc.size(0.5,0.5))
		else
			blurb_label:setTextColor(cc.c4b(73,73,73,255))
			-- blurb_label:enableShadow(cc.c4b(73, 73, 73, 255),cc.size(0.5,0.5))

		end
		
		node:addChild(blurb_label)


		----

		local broadcast_handler = function(event)  
			if event == "began" then  
				self.broadcast_edit:setText( broadcast_label:getString())  
			end  
			  
			if event == "changed" then  
				local str =  self.broadcast_edit:getText()  
				broadcast_label:setString(str)  
			end  
			  
			if event == "return" then  
			   local str =  self.broadcast_edit:getText()  
			   -- self.broadcast_edit:setText("")  
			   broadcast_label:setString(str)  
			end  
		end  
			
		self.broadcast_edit:registerScriptEditBoxHandler(broadcast_handler)  
		
		---
		local blurb_handler = function(event)  
			if event == "began" then  
				self.blurb_edit:setText( blurb_label:getString())  
			end  
			  
			if event == "changed" then  
				local str =  self.blurb_edit:getText()  
				blurb_label:setString(str)  
			end  
			  
			if event == "return" then  
			   local str =  self.blurb_edit:getText()  
			   -- self.blurb_edit:setText("")  
			   blurb_label:setString(str)  
			end  
		end  
			
		self.blurb_edit:registerScriptEditBoxHandler(blurb_handler)  

		----        

		node:getChildByName("save"):addClickEventListener(function ( ... )


 
			local change_bd = false
			local change_bb = false
			if blurb_label:getString() ~= self.group_list.blurb then
				change_bb = true
			end

			if broadcast_label:getString() ~= self.group_list.broadcast then
				change_bd = true
			end

			if self.broadcast_edit then
				self.broadcast_edit:unregisterScriptEditBoxHandler()
				self.broadcast_edit = nil
			end

			if self.blurb_edit then
				self.blurb_edit:unregisterScriptEditBoxHandler()
				self.blurb_edit = nil
			end

			if change_bb == false and change_bd == false then
				if self.scene_:getChildByName("message") then
					self.scene_:getChildByName("message"):removeFromParent()
				end

				return
			end

			for i=1,CONF.DIRTYWORD.len do
			  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
			  if string.find(broadcast_label:getString(), CONF.DIRTYWORD[i].KEY) then
			  	tips:tips(CONF:getStringValue("dirty_message"))
			  	return
			  end
			end

			local str = shuaiSubString(broadcast_label:getString())
			for i=1,CONF.DIRTYWORD.len do
			  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
			  if string.find(str, CONF.DIRTYWORD[i].KEY) then
			  	tips:tips(CONF:getStringValue("dirty_message"))
			  	return
			  end
			end

			for i=1,CONF.DIRTYWORD.len do
			  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
			  if string.find(blurb_label:getString(), CONF.DIRTYWORD[i].KEY) then
			  	tips:tips(CONF:getStringValue("dirty_message"))
			  	return
			  end
			end

			local str = shuaiSubString(blurb_label:getString())
			for i=1,CONF.DIRTYWORD.len do
			  -- assert(not string.find(self.edit:getText(), CONF.DIRTYWORD[i].KEY), "dirty word", self.edit:getText())
			  if string.find(str, CONF.DIRTYWORD[i].KEY) then
			  	tips:tips(CONF:getStringValue("dirty_message"))
			  	return
			  end
			end

			local strData = Tools.encode("GroupBroadcastReq", {
				broadcast = broadcast_label:getString(),
				blurb = blurb_label:getString(),
				})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_BROADCAST_REQ"),strData)

			gl:retainLoading()

			
		end)

		node:getChildByName("mail"):addClickEventListener(function ( ... )
			node:removeFromParent()

			local mail_node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_mail.csb")

			--------
			local broadcast_placeHolder = mail_node:getChildByName("broadcast_text")
			local placeHolderColor = broadcast_placeHolder:getTextColor()
			local fontColor = broadcast_placeHolder:getTextColor()
			local fontName = broadcast_placeHolder:getFontName()
			local fontSize = broadcast_placeHolder:getFontSize()
			local maxLength = broadcast_placeHolder:getMaxLength()

			local broadcast_back = mail_node:getChildByName(string.format("broadcast_back"))
			
			self.broadcast_edit = ccui.EditBox:create(broadcast_back:getContentSize(),"aa")
			self.broadcast_edit:setContentSize(cc.size(self.broadcast_edit:getContentSize().width+10000,self.broadcast_edit:getContentSize().height))
			mail_node:addChild(self.broadcast_edit)
			self.broadcast_edit:setPosition(cc.p(broadcast_back:getPosition()))
			self.broadcast_edit:setPositionX(self.broadcast_edit:getPositionX()-5000)
			self.broadcast_edit:setPlaceHolder(broadcast_placeHolder:getPlaceHolder())
			self.broadcast_edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
			self.broadcast_edit:setPlaceholderFont(fontName,fontSize)
			self.broadcast_edit:setFontSize(0)
			self.broadcast_edit:setPlaceholderFontColor(fontColor)
			self.broadcast_edit:setFont(fontName,fontSize)
			self.broadcast_edit:setFontColor(fontColor)
			self.broadcast_edit:setReturnType(1)
			self.broadcast_edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
			self.broadcast_edit:setMaxLength(maxLength)
			self.broadcast_edit:setName("broadcast_text")

			-- broadcast_back:removeFromParent()
			
			broadcast_placeHolder:removeFromParent()

			------

			local blurb_placeHolder = mail_node:getChildByName("blurb_text")
			local blurb_placeHolderColor = blurb_placeHolder:getTextColor()
			local blurb_fontColor = blurb_placeHolder:getTextColor()
			local blurb_fontName = blurb_placeHolder:getFontName()
			local blurb_fontSize = blurb_placeHolder:getFontSize()
			local blurb_maxLength = blurb_placeHolder:getMaxLength()

			local blurb_back = mail_node:getChildByName(string.format("blurb_back"))
			

			self.blurb_edit = ccui.EditBox:create(blurb_back:getContentSize(),"aa")
			self.blurb_edit:setContentSize(cc.size(self.blurb_edit:getContentSize().width+10000,self.blurb_edit:getContentSize().height))
			mail_node:addChild(self.blurb_edit)
			self.blurb_edit:setPosition(cc.p(blurb_back:getPosition()))
			self.blurb_edit:setPositionX(self.blurb_edit:getPositionX()-5000)
			self.blurb_edit:setPlaceHolder(blurb_placeHolder:getPlaceHolder())
			self.blurb_edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
			self.blurb_edit:setPlaceholderFont(fontName,fontSize)
			self.blurb_edit:setPlaceholderFontColor(fontColor)
			self.blurb_edit:setFont(fontName,fontSize)
			self.blurb_edit:setFontColor(fontColor)
			self.blurb_edit:setReturnType(1)
			self.blurb_edit:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
			self.blurb_edit:setMaxLength(blurb_maxLength)
			self.blurb_edit:setName("blurb_text")

			-- blurb_back:removeFromParent()
			
			blurb_placeHolder:removeFromParent()

			-------

			local broadcast_label = cc.Label:createWithTTF("", "fonts/cuyabra.ttf", 20)
			broadcast_label:setAnchorPoint(cc.p(0,1))
			broadcast_label:setPosition(cc.p(mail_node:getChildByName("broadcast_text"):getPosition()))
			broadcast_label:setLineBreakWithoutSpace(true)
			broadcast_label:setMaxLineWidth(500)
			broadcast_label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
			broadcast_label:setName("broadcast_label")
			-- broadcast_label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
			mail_node:addChild(broadcast_label)
			--
			local blurb_label = cc.Label:createWithTTF("", "fonts/cuyabra.ttf", 20)
			blurb_label:setAnchorPoint(cc.p(mail_node:getChildByName("blurb_text"):getPosition()))
			blurb_label:setPosition(cc.p(400, 445))
			blurb_label:setLineBreakWithoutSpace(true)
			blurb_label:setMaxLineWidth(500)
			blurb_label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
			blurb_label:setName("blurb_label")
			-- blurb_label:enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))
			mail_node:addChild(blurb_label)


			----

			local broadcast_handler = function(event)  

				if event == "began" then  
					self.broadcast_edit:setText( broadcast_label:getString())  
				end  
				  
				if event == "changed" then  
					local str =  self.broadcast_edit:getText()  
					broadcast_label:setString(str)  
				end  
				  
				if event == "return" then  
				   local str =  self.broadcast_edit:getText()  
				   -- self.broadcast_edit:setText("")  
				   broadcast_label:setString(str)  
				end  

				-- if event == "ended" then  
				--    local str =  self.blurb_edit:getText()  
				--    self.blurb_edit:setText("")  
				--    blurb_label:setString(str)  
				-- end 
			end  
				
			self.broadcast_edit:registerScriptEditBoxHandler(broadcast_handler)  
			
			---
			local blurb_handler = function(event)  

				if event == "began" then  
					self.blurb_edit:setText( blurb_label:getString())  
				end  
				  
				if event == "changed" then  
					local str =  self.blurb_edit:getText()  
					blurb_label:setString(str)  
				end  
				  
				if event == "return" then  
				   local str =  self.blurb_edit:getText()  
				   -- self.blurb_edit:setText("")  
				   blurb_label:setString(str)  
				end

				-- if event == "ended" then  
				--    local str =  self.blurb_edit:getText()  
				--    self.blurb_edit:setText("")  
				--    blurb_label:setString(str)  
				-- end  
			end  
				
			self.blurb_edit:registerScriptEditBoxHandler(blurb_handler)  

			----        

			mail_node:setName("node")
			msgNode:addChild(mail_node)

			mail_node:getChildByName("swallow"):addClickEventListener(function ( ... )
				-- body
			end)
			mail_node:getChildByName("swallow"):setLocalZOrder(10)

		end)

		node:setName("node")
		msgNode:addChild(node)

		node:getChildByName("swallow"):addClickEventListener(function ( ... )
			-- body
		end)
		node:getChildByName("swallow"):setLocalZOrder(10)
	elseif type == 4 then
		local node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_setup.csb")
		node:getChildByName("Text_1_0_0_0"):setString(CONF:getStringValue("approval"))
		node:getChildByName("Text_1_0_0"):setString(CONF:getStringValue("powerLimit"))
		node:getChildByName("Text_1_0"):setString(CONF:getStringValue("levelLimit"))
		node:getChildByName("Text_1"):setString(CONF:getStringValue("leagueSite"))
		node:getChildByName("save"):getChildByName("text"):setString(CONF:getStringValue("Save"))

		node:getChildByName("Button_left"):setLocalZOrder(2)
		node:getChildByName("Button_right"):setLocalZOrder(2)
		node:getChildByName("Button_jian_1"):setLocalZOrder(2)
		node:getChildByName("Button_add_1"):setLocalZOrder(2)
		node:getChildByName("Button_jian_2"):setLocalZOrder(2)
		node:getChildByName("Button_add_2"):setLocalZOrder(2)

		if self.group_list.join_condition.needAllow then
			node:getChildByName("need_text"):setString(CONF:getStringValue("need"))
		else
			node:getChildByName("need_text"):setString(CONF:getStringValue("needn't"))
		end

		
		self.edit1 = node:getChildByName("setup_text_1")
		self.edit2 = node:getChildByName("setup_text_2")

		self.setup_edit_1 = node:getChildByName("input_text_1")
		self.setup_edit_2 = node:getChildByName("input_text_2")

		self.setup_edit_1:setString(self.group_list.join_condition.level)
		self.setup_edit_2:setString(self.group_list.join_condition.power)

		self.setup_edit_1:setName("setup_label_1")
		self.setup_edit_2:setName("setup_label_2")

		self.setup_edit_1:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
		self.setup_edit_2:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)

		for i=1,2 do
			local edit = cc.EditBox:create(node:getChildByName("setup_text_"..i):getContentSize(),"aa")
			node:addChild(edit,self.setup_edit_1:getLocalZOrder()-1)
			edit:setPosition(cc.p(node:getChildByName("setup_text_"..i):getPosition()))
			local fontName =  node:getChildByName("setup_text_"..i):getFontName()
			local fontSize =  node:getChildByName("setup_text_"..i):getFontSize()
			edit:setPlaceholderFont(fontName,fontSize)
			edit:setFont(fontName,fontSize)
			edit:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)

			edit:setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
			edit:setName(string.format("editbox_%d", i))
			edit:setTag(i)
			edit:registerScriptEditBoxHandler(function(eventname,sender)
				 if eventname == "began" then  
				        sender:setText("")                                     
				    elseif eventname == "ended" then  
				    	local text = sender:getText()
				    	if text == "" then
				    		text = node:getChildByName("setup_label_"..i):getString()
				    	end
				        node:getChildByName("setup_label_"..i):setString(text)
				    elseif eventname == "return" then  
				    	local text = sender:getText()
				    	if text == "" then
				    		text = node:getChildByName("setup_label_"..i):getString()
				    	end
				        node:getChildByName("setup_label_"..i):setString(text)     
				    elseif eventname == "changed" then  
				        local text = sender:getText()
				    	if text == "" then
				    		text = node:getChildByName("setup_label_"..i):getString()
				    	end
				        node:getChildByName("setup_label_"..i):setString(text)     
				    end  
				end)
			if i == 1 then
				edit:setMaxLength(3)
			else
				edit:setMaxLength(8)
			end

			node:getChildByName("setup_text_"..i):removeFromParent()
		end

		if node:getChildByName("need_text"):getString() == CONF:getStringValue("needn't") then
			for i=1,2 do
				node:getChildByName("Button_jian_"..i):setEnabled(false)
				node:getChildByName("setup_label_"..i):setString("0") 
				node:getChildByName("editbox_"..i):setTouchEnabled(false)
				node:getChildByName("Button_add_"..i):setEnabled(false)
			end
		else
			for i=1,2 do
				node:getChildByName("Button_jian_"..i):setEnabled(true)
				node:getChildByName("editbox_"..i):setTouchEnabled(true)
				node:getChildByName("Button_add_"..i):setEnabled(true)
			end
		end

		-------------
		node:getChildByName("Button_left"):addClickEventListener(function ( ... )
			if node:getChildByName("need_text"):getString() == CONF:getStringValue("need") then
				node:getChildByName("need_text"):setString(CONF:getStringValue("needn't"))
			elseif node:getChildByName("need_text"):getString() == CONF:getStringValue("needn't") then
				node:getChildByName("need_text"):setString(CONF:getStringValue("need"))
			end
			if node:getChildByName("need_text"):getString() == CONF:getStringValue("needn't") then
				for i=1,2 do
					node:getChildByName("Button_jian_"..i):setEnabled(false)
					node:getChildByName("setup_label_"..i):setString("0") 
					node:getChildByName("editbox_"..i):setTouchEnabled(false)
					node:getChildByName("Button_add_"..i):setEnabled(false)
				end
			else
				for i=1,2 do
					node:getChildByName("Button_jian_"..i):setEnabled(true)
					node:getChildByName("editbox_"..i):setTouchEnabled(true)
					node:getChildByName("Button_add_"..i):setEnabled(true)
				end
				self.setup_edit_1:setString(self.group_list.join_condition.level)
				self.setup_edit_2:setString(self.group_list.join_condition.power)
			end
		end)

		node:getChildByName("Button_right"):addClickEventListener(function ( ... )
			if node:getChildByName("need_text"):getString() == CONF:getStringValue("need") then
				node:getChildByName("need_text"):setString(CONF:getStringValue("needn't"))
			elseif node:getChildByName("need_text"):getString() == CONF:getStringValue("needn't") then
				node:getChildByName("need_text"):setString(CONF:getStringValue("need"))
			end
			if node:getChildByName("need_text"):getString() == CONF:getStringValue("needn't") then
				for i=1,2 do
					node:getChildByName("Button_jian_"..i):setEnabled(false)
					node:getChildByName("setup_label_"..i):setString("0") 
					node:getChildByName("editbox_"..i):setTouchEnabled(false)
					node:getChildByName("Button_add_"..i):setEnabled(false)
				end
			else
				for i=1,2 do
					node:getChildByName("Button_jian_"..i):setEnabled(true)
					node:getChildByName("editbox_"..i):setTouchEnabled(true)
					node:getChildByName("Button_add_"..i):setEnabled(true)
				end
				self.setup_edit_1:setString(self.group_list.join_condition.level)
				self.setup_edit_2:setString(self.group_list.join_condition.power)
			end
		end)

		node:getChildByName("Button_jian_1"):addClickEventListener(function ( ... )
			if tonumber(node:getChildByName("setup_label_1"):getString())-1 < 0 then
				return
			end

			node:getChildByName("setup_label_1"):setString(tonumber(node:getChildByName("setup_label_1"):getString())-1)
		end)

		node:getChildByName("Button_add_1"):addClickEventListener(function ( ... )
			if tonumber(node:getChildByName("setup_label_1"):getString())+1 >= 1000000 then
				return
			end

			node:getChildByName("setup_label_1"):setString(tonumber(node:getChildByName("setup_label_1"):getString())+1)
		end)

		node:getChildByName("Button_jian_2"):addClickEventListener(function ( ... )
			if tonumber(node:getChildByName("setup_label_2"):getString())-1 < 0 then
				return
			end

			node:getChildByName("setup_label_2"):setString(tonumber(node:getChildByName("setup_label_2"):getString())-1)
		end)

		node:getChildByName("Button_add_2"):addClickEventListener(function ( ... )
			if tonumber(node:getChildByName("setup_label_2"):getString())+1 >= 1000000 then
				return
			end

			node:getChildByName("setup_label_2"):setString(tonumber(node:getChildByName("setup_label_2"):getString())+1)
		end)

		for i=1,2 do
			node:getChildByName("Button_jian_"..i):setLocalZOrder(2)
		end


		node:getChildByName("save"):addClickEventListener(function ( ... )

			if player:getGroupData().job == 3 then
				tips:tips(CONF:getStringValue("Permission denied"))
			end

			local change_level = false
			local change_power = false
			local flag = false

			if node:getChildByName("need_text"):getString() == CONF:getStringValue("need") then
				flag = true
			end

			if tonumber(node:getChildByName("setup_label_1"):getString()) ~= self.group_list.join_condition.level then
				change_level = true
			end

			if tonumber(node:getChildByName("setup_label_2"):getString()) ~= self.group_list.join_condition.power then
				change_power = true
			end

			local table_ = {}
			table_.needAllow = flag
			table_.level = tonumber(node:getChildByName("setup_label_1"):getString())
			table_.power = tonumber(node:getChildByName("setup_label_2"):getString())
			

			if flag == self.group_list.join_condition.needAllow and change_level == false and change_power == false then

				if self.setup_edit_1 then
					-- self.setup_edit_1:unregisterScriptEditBoxHandler()
					self.setup_edit_1 = nil
				end

				if self.setup_edit_2 then
					-- self.setup_edit_2:unregisterScriptEditBoxHandler()
					self.setup_edit_2 = nil
				end

				self.scene_:getChildByName("message"):removeFromParent()
				return
			end

			local strData = Tools.encode("GroupJoinConditionReq", table_)
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOIN_CONDITION_REQ"),strData)

			gl:retainLoading()
		end)

		node:getChildByName("swallow"):addClickEventListener(function ( ... )
			-- body
		end)

		node:setName("node")
		msgNode:addChild(node)

	elseif type == 5 then
		local node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_shop.csb")
	   node:getChildByName("Text_1"):setString(CONF:getStringValue("leagueShop"))
		node:getChildByName("buy"):getChildByName("text"):setString(CONF:getStringValue("Buy"))
		node:getChildByName("Text_10_0"):setString(CONF:getStringValue("Cost"))
		node:getChildByName("my_contribution_num"):setString(player:getGroupData().contribute)
		node:getChildByName("Text_10"):setString(CONF:getStringValue("sumNum"))
		local placeHolder = node:getChildByName("num_text")
		local placeHolderColor = placeHolder:getTextColor()
		local fontColor = placeHolder:getTextColor()
		local fontName = placeHolder:getFontName()
		local fontSize = placeHolder:getFontSize()
		local maxLength = placeHolder:getMaxLength()

		local back = node:getChildByName(string.format("text_back"))
		

		self.shop_edit = ccui.EditBox:create(placeHolder:getContentSize(),"aa")
		self.shop_edit:setContentSize(cc.size(self.shop_edit:getContentSize().width+10000, self.shop_edit:getContentSize().height))
		node:addChild(self.shop_edit)
		self.shop_edit:setPosition(cc.p(back:getPosition()))
		self.shop_edit:setPositionX(self.shop_edit:getPositionX()-5000)
		self.shop_edit:setInputFlag(cc.EDITBOX_INPUT_FLAG_INITIAL_CAPS_WORD)
		self.shop_edit:setPlaceHolder(placeHolder:getPlaceHolder())
		self.shop_edit:setPlaceholderFont(fontName,fontSize)
		self.shop_edit:setPlaceholderFontColor(fontColor)
		self.shop_edit:setFont(fontName,fontSize)
		self.shop_edit:setFontColor(fontColor)
		self.shop_edit:setReturnType(1)
		self.shop_edit:setInputMode(cc.EDITBOX_INPUT_MODE_DECIMAL)
		self.shop_edit:setMaxLength(maxLength)
		self.shop_edit:setName("num_text")

		-- back:removeFromParent()
		
		placeHolder:removeFromParent()

		-----
		local label = cc.Label:createWithTTF("1", "fonts/cuyabra.ttf", 16)

		label:setAnchorPoint(cc.p(0.5,0.5))
		label:setPosition(cc.p(back:getPositionX(), back:getPositionY() - 2))
		label:setLineBreakWithoutSpace(true)
		label:setMaxLineWidth(500)
		label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
		label:setName("num_label")
		-- label:enableShadow(cc.c4b(33, 255, 70, 255),cc.size(0.5,0.5))
		node:addChild(label)

		local handler = function(event)  
			if event == "began" then  
				self.shop_edit:setText( label:getString())  
			end  
			  
			if event == "changed" then  
				local str =  self.shop_edit:getText()  
				label:setString(str)  
			end  
			  
			if event == "return" then  
			   local str =  self.shop_edit:getText()  
			   -- self.shop_edit:setText("")  
			   label:setString(str)  
			end  
		end  
		
		self.shop_edit:registerScriptEditBoxHandler(handler)

		node:setName("node")
		msgNode:addChild(node)

	elseif type == 6 then
		local node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_help.csb")
		node:getChildByName("help"):getChildByName("text"):setString(CONF:getStringValue("a_key_to_help"))
		node:getChildByName("text"):setString(CONF:getStringValue("no_help"))
		node:getChildByName("Text_1"):setString(CONF:getStringValue("leagueHelp"))
		
		if #self.help_list > 0 then
			node:getChildByName("text"):setVisible(false)
		end

		self.help_svd = require("util.ScrollViewDelegate"):create(node:getChildByName("list"),cc.size(0,0), cc.size(560,67))
		self.help_svd:getScrollView():setScrollBarEnabled(false)

		local list = {}
		for i=#self.help_list,1,-1 do
			table.insert(list, self.help_list[i])
		end

		node:getChildByName("help"):addClickEventListener(function ( ... )
			-- if player:getGroupData().help_times == CONF.GROUP.get(self.group_list.level).HELP_TIME then
			-- 	tips:tips(CONF:getStringValue("help_full"))
			-- 	return
			-- end

			local index = 1
			local num 
			if CONF.GROUP.get(self.group_list.level).HELP_TIME > 0 then
				num = CONF.GROUP.get(self.group_list.level).HELP_TIME - player:getGroupData().help_times
			end

			local key_list = {}
			for i,v in ipairs(list) do
				if v.user_name ~= player:getName() and table.getn(v.help_user_name_list) <  CONF.GROUP_HELP.get(self.group_list.level).TIME then

					local has = false
					for i23,v23 in ipairs(v.help_user_name_list) do
						if v23 == player:getName() then
							has = true
						    break
						end
					end

					if not has then
						table.insert(key_list, v)
					end
				end
			end

			print("#key_list",#key_list,num)

			if #key_list == 0 then
				tips:tips(CONF:getStringValue("no_help"))
				return
			end

			local function keyHelp( index )
				local strData = Tools.encode("GroupHelpReq", {
					user_name = key_list[index].user_name,
					type = key_list[index].type,
					id = key_list[index].id,
				})

				g_sendList:addSend({define = "CMD_GROUP_HELP_REQ", strData = strData})
			end

			if num and num < #key_list then
				for i=1,num do

					local ishelp = false
					for i2,v2 in ipairs(key_list[i].help_user_name_list) do
						print("bbbbbbbbbb",v2,player:getName())
						if v2 ~= player:getName() then
							ishelp = true
							break
						end
					end

					if not ishelp then
						keyHelp(i)
					end
					
				end
			else
				for i,v in ipairs(key_list) do
					local ishelp = false
					for i2,v2 in ipairs(v.help_user_name_list) do
						print("bbbbbbbbbb222",v2,player:getName())
						if v2 ~= player:getName() then
							ishelp = true
							break
						end
					end 

					if not ishelp then
						keyHelp(i)
					end
				end

			end


		end)

		for i,v in ipairs(list) do
			local help_node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_help_item.csb")

			if i%2 == 0 then
				help_node:getChildByName("background"):setOpacity(255*0.03)
			else
				help_node:getChildByName("background"):setOpacity(255*0.1)
			end

			if v.user_name == player:getName() then
				help_node:getChildByName("button"):setVisible(false)
			end

			local ishelp = false
			for i2,v2 in ipairs(v.help_user_name_list) do
				if v2 == player:getName() then
					ishelp = true
					break
				end
			end

			if ishelp then
				help_node:getChildByName("button"):setEnabled(false)
				help_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("is_help"))
			end

			local nickname = ""
			for i2,v2 in ipairs(self.group_list.user_list) do
				if v2.user_name == v.user_name then
					nickname = v2.nickname
					break
				end
			end

			local fontName = "fonts/cuyabra.ttf"
			local fontSize = 20

			local help_num = table.getn(v.help_user_name_list)
			local help_max = string.format("/%d]", v.max_help_times)

			local type_name = ""
			local id_name = ""
			if v.type == CONF.EGroupHelpType.kBuilding then
				type_name = CONF:getStringValue("upgrade_now")
				id_name = CONF:getStringValue("BuildingName_"..v.id[1])
			elseif v.type == CONF.EGroupHelpType.kTechnology then
				type_name = CONF:getStringValue("tech_now")
				id_name = CONF:getStringValue(CONF.TECHNOLOGY.get(v.id[1]).TECHNOLOGY_NAME)
			elseif v.type == CONF.EGroupHelpType.kHome then  
				type_name = CONF:getStringValue("upgrade_now")
				id_name = CONF:getStringValue(CONF.RESOURCE.get(v.id[2]).NAME) 
			end


			local richText = ccui.RichText:create()
			richText:ignoreContentAdaptWithSize(false)  
			richText:setContentSize(cc.size(400,50))

			local re1 = ccui.RichElementText:create( 1, cc.c3b(175, 175, 175), 255, "[", fontName, fontSize , 2)  
			local re2 = ccui.RichElementText:create( 2, cc.c3b(255, 255, 255), 255, help_num, fontName, fontSize , 2)  
			local re3 = ccui.RichElementText:create( 3, cc.c3b(175, 175, 175), 255, help_max, fontName, fontSize , 2)  
			local re4 = ccui.RichElementText:create( 4, cc.c3b(34, 166, 168), 255, "["..nickname.."]", fontName, fontSize , 2)  
			local re5 = ccui.RichElementText:create( 5, cc.c3b(175,  175,   175), 255, type_name, fontName, fontSize , 2)  
			local re6 = ccui.RichElementText:create( 6, cc.c3b(99,  255,   169), 255, id_name, fontName, fontSize , 2)  

			richText:pushBackElement(re1)  
			richText:pushBackElement(re2)  
			richText:pushBackElement(re3)  
			richText:pushBackElement(re4)  
			richText:pushBackElement(re5)  
			richText:pushBackElement(re6) 

			richText:setPosition(cc.p(help_node:getChildByName("text"):getPosition()))
			help_node:addChild(richText)

			help_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("help"))
			help_node:getChildByName("button"):addClickEventListener(function ( ... )
				-- if player:getGroupData().help_times == CONF.GROUP.get(self.group_list.level).HELP_TIME then
				-- 	tips:tips(CONF:getStringValue("help_full"))
				-- 	return
				-- end
			
				local strData = Tools.encode("GroupHelpReq", {
					user_name = v.user_name,
					type = v.type,
					id = v.id,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_REQ"),strData)

				-- gl:retainLoading()
			end)

			self.help_svd:addElement(help_node)


		end

		node:setName("node")
		msgNode:addChild(node)

	end

	local center = cc.exports.VisibleRect:center()
--	msgNode:setPosition(cc.p(center.x - msgNode:getChildByName("back"):getContentSize().width/2, center.y - msgNode:getChildByName("back"):getContentSize().height/2))
--	self.scene_:addChild(msgNode)
    msgNode:setPosition(cc.exports.VisibleRect:leftBottom())
    rn:addChild(msgNode)
end

function PandectNode:resetHelpList()

	local node = self.scene_:getChildByName("message"):getChildByName("node")

	self.help_svd:clear()

	if #self.help_list > 0 then
		node:getChildByName("text"):setVisible(false)
	else
		node:getChildByName("text"):setVisible(true)
	end

	local list = {}
	for i=#self.help_list,1,-1 do
		table.insert(list, self.help_list[i])
	end

	node:getChildByName("help"):addClickEventListener(function ( ... )
		-- if player:getGroupData().help_times == CONF.GROUP.get(self.group_list.level).HELP_TIME then
		-- 	tips:tips(CONF:getStringValue("help_full"))
		-- 	return
		-- end
		local index = 1
		local num 
		if CONF.GROUP.get(self.group_list.level).HELP_TIME > 0 then
		 	num = CONF.GROUP.get(self.group_list.level).HELP_TIME - player:getGroupData().help_times
		end

		local key_list = {}
		for i,v in ipairs(list) do
			if v.user_name ~= player:getName() and table.getn(v.help_user_name_list) <  CONF.GROUP_HELP.get(self.group_list.level).TIME then
				local has = false
				for i23,v23 in ipairs(v.help_user_name_list) do
					if v23 == player:getName() then
						has = true
					    break
					end
				end

				if not has then
					table.insert(key_list, v)
				end
			end
		end
		if #key_list == 0 then
			tips:tips(CONF:getStringValue("no_help"))
			return
		end

		local function keyHelp( index )

			local strData = Tools.encode("GroupHelpReq", {
				user_name = key_list[index].user_name,
				type = key_list[index].type,
				id = key_list[index].id,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_REQ"),strData)

			g_sendList:addSend({define = "CMD_GROUP_HELP_REQ", strData = strData})

		end

		if num and num < #key_list then
			for i=1,num do

				local ishelp = false
				for i2,v2 in ipairs(key_list[i].help_user_name_list) do
					if v2 ~= player:getName() then
						ishelp = true
						break
					end
				end

				if not ishelp then
					keyHelp(i)
				end
				
			end
		else
			for i,v in ipairs(key_list) do
				local ishelp = false
				for i2,v2 in ipairs(v.help_user_name_list) do
					if v2 ~= player:getName() then
						ishelp = true
						break
					end
				end 

				if not ishelp then
					keyHelp(i)
				end
			end

		end
	end)

	for i,v in ipairs(list) do
		local help_node = require("app.ExResInterface"):getInstance():FastLoad("StarLeagueScene/league_help_item.csb")

		if i%2 == 0 then
			help_node:getChildByName("background"):setOpacity(255*0.03)
		else
			help_node:getChildByName("background"):setOpacity(255*0.1)
		end

		help_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("help"))
		help_node:getChildByName("button"):addClickEventListener(function ( ... )

			-- if player:getGroupData().help_times == CONF.GROUP.get(self.group_list.level).HELP_TIME then
			-- 	tips:tips(CONF:getStringValue("help_full"))
			-- 	return
			-- end

			local strData = Tools.encode("GroupHelpReq", {
				user_name = v.user_name,
				type = v.type,
				id = v.id,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_HELP_REQ"),strData)

			-- gl:retainLoading()
		end)

		if v.user_name == player:getName() then
			help_node:getChildByName("button"):setVisible(false)
		end

		local ishelp = false
		for i2,v2 in ipairs(v.help_user_name_list) do
			if v2 == player:getName() then
				ishelp = true
				break
			end
		end

		if ishelp then
			help_node:getChildByName("button"):setEnabled(false)
			help_node:getChildByName("button"):getChildByName("text"):setString(CONF:getStringValue("is_help"))
		end

		local nickname = ""
		for i2,v2 in ipairs(self.group_list.user_list) do
			if v2.user_name == v.user_name then
				nickname = v2.nickname
				break
			end
		end

		local fontName = "fonts/cuyabra.ttf"
		local fontSize = 20

		local help_num = table.getn(v.help_user_name_list)
		local help_max = string.format("/%d]", v.max_help_times)

		local type_name = ""
		local id_name = ""
		if v.type == CONF.EGroupHelpType.kBuilding then
			type_name = CONF:getStringValue("upgrade_now")
			id_name = CONF:getStringValue("BuildingName_"..v.id[1])
		elseif v.type == CONF.EGroupHelpType.kTechnology then
			type_name = CONF:getStringValue("tech_now")
			id_name = CONF:getStringValue(CONF.TECHNOLOGY.get(v.id[1]).TECHNOLOGY_NAME)
		elseif v.type == CONF.EGroupHelpType.kHome then  
			type_name = CONF:getStringValue("upgrade_now")
			id_name = CONF:getStringValue(CONF.RESOURCE.get(v.id[2]).NAME) 
		end


		local richText = ccui.RichText:create()
		richText:ignoreContentAdaptWithSize(false)  
		richText:setContentSize(cc.size(400,50))

		local re1 = ccui.RichElementText:create( 1, cc.c3b(175, 175, 175), 255, "[", fontName, fontSize , 2)  
		local re2 = ccui.RichElementText:create( 2, cc.c3b(255, 255, 255), 255, help_num, fontName, fontSize , 2)  
		local re3 = ccui.RichElementText:create( 3, cc.c3b(175, 175, 175), 255, help_max, fontName, fontSize , 2)  
		local re4 = ccui.RichElementText:create( 4, cc.c3b(34, 166, 168), 255, "["..nickname.."]", fontName, fontSize , 2)  
		local re5 = ccui.RichElementText:create( 5, cc.c3b(175,  175,   175), 255, type_name, fontName, fontSize , 2)  
		local re6 = ccui.RichElementText:create( 6, cc.c3b(99,  255,   169), 255, id_name, fontName, fontSize , 2)  

		richText:pushBackElement(re1)  
		richText:pushBackElement(re2)  
		richText:pushBackElement(re3)  
		richText:pushBackElement(re4)  
		richText:pushBackElement(re5)  
		richText:pushBackElement(re6) 

		richText:setPosition(cc.p(help_node:getChildByName("text"):getPosition()))
		help_node:addChild(richText)

		self.help_svd:addElement(help_node)


	end

end

function PandectNode:nodeAni( node )
	node:setOpacity(0)
	node:setPositionX(node:getPositionX() - 45)

	node:runAction(cc.Spawn:create(cc.FadeIn:create(0.33), cc.MoveBy:create(0.33, cc.p(45,0))))
end

function PandectNode:onExitTransitionStart()
	printInfo("PandectNode:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.groupListener_)
	
end

return PandectNode 