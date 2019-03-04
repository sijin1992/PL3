local player = require("app.Player"):getInstance()
local animManager = require("app.AnimManager"):getInstance()
local tips = require("util.TipsMessage"):getInstance()
local gl = require("util.GlobalLoading"):getInstance()
local scheduler = cc.Director:getInstance():getScheduler()
local StarLeagueLayer = class("StarLeagueLayer", cc.load("mvc").ViewBase)

StarLeagueLayer.RESOURCE_FILENAME = "StarLeagueScene/StarLeagueLayer.csb"
StarLeagueLayer.NEED_ADJUST_POSITION = true
StarLeagueLayer.RESOURCE_BINDING = {
	-- ["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil

local check_tech = false

function StarLeagueLayer:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" then

		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			if self.data_.from and self.data_.from == 'PlanetUILayer' then
				self:getApp():pushToRootView("PlanetScene/PlanetScene")
			else
				self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
			end
		end

	end

end

function StarLeagueLayer:resetNode( typeName, data )

	if self.typeName_ == typeName then
		return
	end

	self.typeName_ = typeName

	local rn = self:getResourceNode()

	for i,v in ipairs(self.labs) do
		local text = rn:getChildByName(v.."_text")
		if v == typeName then
			rn:getChildByName(v):setOpacity(255)

			text:setFontSize(26)
			text:setTextColor(cc.c4b(255,244,198,255))
			-- text:enableShadow(cc.c4b(255,244,198,255), cc.size(0.5,0.5))
		else
			rn:getChildByName(v):setOpacity(0)

			text:setFontSize(24)
			text:setTextColor(cc.c4b(209,209,209,255))
			-- text:enableShadow(cc.c4b(209,209,209,255), cc.size(0.5,0.5))
		end
	end

	if self:getChildByName("click_node") then
		self:getChildByName("click_node"):removeFromParent()
	end

	-- rn:getChildByName("line_left"):setContentSize(cc.size(rn:getChildByName(typeName):getPositionX(), rn:getChildByName("line_left"):getContentSize().height))
	-- rn:getChildByName("line_right"):setContentSize(cc.size(rn:getContentSize().width - rn:getChildByName("line_left"):getContentSize().width - rn:getChildByName(typeName):getContentSize().width +6, rn:getChildByName("line_right"):getContentSize().height))

	local perNode = rn:getChildByName("node")
	if perNode == nil then
		return
	end
	local nodePos = cc.p(perNode:getPosition())
	perNode:removeFromParent()

	local node
	if typeName == "pandect" then
		node = require("app.views.StarLeagueScene.PandectNode"):create()
	elseif typeName == "member" then
		node = require("app.views.StarLeagueScene.MemberNode"):create()
	elseif typeName == "technology" then
		node = require("app.views.StarLeagueScene.TechnologyNode"):create()
	end

	rn:addChild(node)
	node:setName("node")
	node:setPosition(nodePos)

	node:init(self,data)

end

function StarLeagueLayer:onCreate(data)

	if data then
		self.data_ = data
	else
		self.data_ = {}
	end
end

function StarLeagueLayer:init( scene )
	self.scene_ = scene
end

function StarLeagueLayer:onEnterTransitionFinish()

	printInfo("StarLeagueLayer:onEnterTransitionFinish()")

	print("StarLeagueLayer, ", self.data_.resetType)

	self.labs = {"pandect", "member", "technology"}

	local rn = self:getResourceNode()

	rn:getChildByName("close"):addClickEventListener(function ( ... )
		if self.data_.from and self.data_.from == 'PlanetUILayer' then
			self:getApp():pushToRootView("PlanetScene/PlanetScene")
		else
			self:getApp():pushToRootView("CityScene/CityScene", {pos = -1350})
		end
	end)

	rn:getChildByName("pandect_text"):setString(CONF:getStringValue("pandect"))
	rn:getChildByName("member_text"):setString(CONF:getStringValue("member"))
	rn:getChildByName("technology_text"):setString(CONF:getStringValue("technology"))
	rn:getChildByName("left_di"):getChildByName("title"):setString(CONF:getStringValue("covenant"))
	rn:getChildByName("background"):addClickEventListener(function ( ... )
		if self:getChildByName("click_node") then

			rn:getChildByName("node"):unLightItem()
		end
	end)

	self.isUpgrade_ = false
	self.isJoin = false

	-- self.typeName_ = ""
	-- self:resetNode("pandect", {index = 0})

	local strData = Tools.encode("GetGroupReq", {
		-- groupid = player:getGroupData().groupid,
		groupid = ""
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_REQ"),strData)

	gl:retainLoading("CMD_GET_GROUP_REQ")

	animManager:runAnimOnceByCSB(rn, "StarLeagueScene/StarLeagueLayer.csb", "intro", function ( ... )
		
	end)

	animManager:runAnimByCSB(rn:getChildByName("liuguang"), "Common/sfx/jiemianliuguang1.csb", "1")

	local function update( dt )
		if not player:isGroup() and (not rn:getChildByName("node") or not not rn:getChildByName("node"):getIsExit() ) then
			self:getParent():getNoGroup()
		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	-- local eventDispatcher = self:getEventDispatcher()

	-- self.td_ = require("util.LabsDelegate"):create(
	-- 	function (target)
	-- 		self:resetNode(target:getName(),{group = self.group_list, user_info = self.user_info_list, join_list = self.group_join_list})
				
	-- 	end, nil, nil, eventDispatcher, 
	-- 	{rn:getChildByName("pandect"), "LevelScene/ui/anniu_standby_select.png", "LevelScene/ui/anniu_standby.png"}, 
	-- 	{rn:getChildByName("member"), "LevelScene/ui/anniu_standby_select.png", "LevelScene/ui/anniu_standby.png"}, 
	-- 	{rn:getChildByName("technology"), "LevelScene/ui/anniu_standby_select.png", "LevelScene/ui/anniu_standby.png"})

	for i,v in ipairs(self.labs) do
		rn:getChildByName(v):addClickEventListener(function ( ... )
			self:resetNode(v,{group = self.group_list, user_info = self.user_info_list, join_list = self.group_join_list})
		end)
	end

	local function recvMsg()
		print("StarLeagueLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_GROUP_RESP") then
			printInfo("GetGroupResp")
			gl:releaseLoading("CMD_GET_GROUP_REQ")

			local proto = Tools.decode("GetGroupResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				-- self:setInfo(proto.user_sync.group_main)
				player:setPlayerGroupMain(proto.user_sync.group_main)

				self.group_list = proto.user_sync.group_main

				self:resetInfo()
				
				self:getOtherInfo(proto.user_sync.group_main)

				if not check_tech then

					local gg_conf = CONF.GROUP.get(self.group_list.level)

					if gg_conf then
						if player:getGroupTechItemIndex(gg_conf.OPEN_TECH_ID[1],1) == nil then
							local strData = Tools.encode("GroupContributeReq", {
					            type = 0,
					            tech_id = gg_conf.OPEN_TECH_ID[1],
					        })
					        GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_CONTRIBUTE_REQ"),strData)
						end
					end

					check_tech = true
				end
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_RESP") then
			-- if self.typeName_ ~= "member" then
				-- gl:releaseLoading()

				local proto = Tools.decode("CmdGetOtherUserInfoListResp",strData)

				if proto.result ~= 0 then
					print("error :",proto.result)
				else
					if not self.isUpgrade_ then
						if self.isJoin then
							self.group_join_list = proto.info_list

							self.isUpgrade_ = true
							
							self.typeName_ = ""


							self:resetNode("pandect", {group = self.group_list, user_info = self.user_info_list, join_list = self.group_join_list})
							
						else
							self.user_info_list = proto.info_list

							self:getJoinInfo(self.group_list)
						end
						
						
					else
						if self.isJoin then
							self.group_join_list = proto.info_list

							self:updateUI()
						else
							self.user_info_list = proto.info_list

							self:getJoinInfo(self.group_list)
						end
					end
					
				end
			-- end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_JOIN_RESP") then
			gl:releaseLoading()
		end

	end

	local eventDispatcher = self:getEventDispatcher()	
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.chatListener_ = cc.EventListenerCustom:create("group_main", function (event)
		print("group_main gengxinxnxinxin")
		if event.group_main.groupid == "" or event.group_main == nil then
			return
		end

		self.group_list = event.group_main

		self:getOtherInfo(event.group_main)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.chatListener_, FixedPriority.kNormal)

end

function StarLeagueLayer:resetInfo()

	if #self.group_list.join_list ~= 0 then
		self:getResourceNode():getChildByName("green_icon"):setVisible(true)
	else
		self:getResourceNode():getChildByName("green_icon"):setVisible(false)
	end
end

function StarLeagueLayer:updateUI( ... )
	self:resetInfo()

	self:getResourceNode():getChildByName("node"):updateUI(self.group_list, self.user_info_list, self.group_join_list)
end

function StarLeagueLayer:getOtherInfo( group_list )
	printInfo("getOtherInfo")
	local user_name_list = {}
	for i,v in ipairs(group_list.user_list) do
		table.insert(user_name_list, v.user_name)
	end

	self.isJoin = false
	local strData = Tools.encode("CmdGetOtherUserInfoListReq", {
		user_name_list = user_name_list,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_REQ"),strData)

	-- gl:retainLoading()
end

function StarLeagueLayer:getJoinInfo( group_list )
	printInfo("getJoinInfo")

	local rn = self:getResourceNode()

	local user_name_list = {}
	for i,v in ipairs(group_list.join_list) do
		table.insert(user_name_list, v.user_name)
	end

	if table.getn(user_name_list) == 0 then
		self.group_join_list = {}
		if not self.isUpgrade_ then
			self.isUpgrade_ = true
							
			self.typeName_ = ""

			if self.data_.resetType then
				self:resetNode(self.data_.resetType, {group = self.group_list, user_info = self.user_info_list, join_list = self.group_join_list})

				-- rn:getChildByName("pandect"):setTexture("LevelScene/ui/anniu_standby.png")
				-- rn:getChildByName(self.data_.resetType):setTexture("LevelScene/ui/anniu_standby_select.png")

			else

				self:resetNode("pandect", {group = self.group_list, user_info = self.user_info_list, join_list = self.group_join_list})
			end
		else
			self:updateUI()
		end

	else
		self.isJoin = true
		local strData = Tools.encode("CmdGetOtherUserInfoListReq", {
			user_name_list = user_name_list,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_REQ"),strData)

		-- gl:retainLoading()
	end
end

function StarLeagueLayer:setGroupData( group )
	self.group_list = {}
	self.group_list = group
end


function StarLeagueLayer:onExitTransitionStart()
	printInfo("StarLeagueLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.chatListener_)
	

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end


return StarLeagueLayer