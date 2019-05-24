local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local Tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local RankLayer = class("RankLayer", cc.load("mvc").ViewBase)

RankLayer.RESOURCE_FILENAME = "RankLayer/RankLayer.csb"

RankLayer.NEED_ADJUST_POSITION = true

RankLayer.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
	--["btnReward"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function RankLayer:OnBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then 
			playEffectSound("sound/system/return.mp3")
			self:getApp():popView()
			
		end
	end
end

function RankLayer:onCreate(data) --{"player_power" ,"PlayerLevel" ,"CentreLevel" ,"leaguePower" ,"arena_rank" ,"trial_rank"}

	if data then 
		self.selectType = data.type 
	else 
		self.selectType = nil 
	end
end

function RankLayer:onEnterTransitionFinish()
	local rn = self:getResourceNode()
	self.labels = {"player_power" ,"PlayerLevel" ,"CentreLevel" ,"leaguePower" ,"arena_rank" ,"trial_rank"}

	self:setData()
	self:addTouch()

	--打开特定的排行榜
	if self.selectType == nil  then 
		self.selectType = self.labels[1]	
	end
	self:changeType()
	self.rankList = {}
	--播放进入动画
	-- animManager:runAnimOnceByCSB(rn,"RankLayer/RankLayer.csb" ,"intro")

	local function recvMsg()
		print("MailScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_RANK_RESP") then
			gl:releaseLoading()          
			local proto = Tools.decode("RankResp",strData)
		   
			if proto.result ~= 0 then
				printInfo("-------------proto error" ,proto.result)  
			else  
				self.rankList = proto
				self:resetList()
			end
		--获取工会总战力
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_RESP") then        
			local proto = Tools.decode("CmdGetOtherUserInfoListResp",strData)         
			if proto.result ~= 0 then
				printInfo("proto error",proto.result)  
			else  
				local sumPower = 0
				for i,v in ipairs(proto.info_list) do
					sumPower = sumPower + v.power
				end
				rn:getChildByName("textNode"):getChildByName("power_num"):setString(sumPower)
			end
		--获取竞技场排名
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_RESP") then
			local proto = Tools.decode("ArenaInfoResp",strData)
			if proto.result ~= 0 then
				printInfo("proto error ArenaInfoResp" ,proto.result)  
			else 
				rn:getChildByName("textNode"):getChildByName("rank_num"):setString(proto.my_info.rank)
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local   eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
end

--屏幕适配 和 关联 string表
function RankLayer:setData(  )
	local rn = self:getResourceNode()
	local leftPanel = rn:getChildByName("leftBg")
	local lineTop = rn:getChildByName("lineTop")
	local lineBottom = rn:getChildByName("lineBottom")
	-- leftPanel:setPositionY(lineTop:getPositionY() - 2)
	local list = rn:getChildByName("list")
	local listH = lineTop:getPositionY() - lineBottom:getPositionY() - 30
	-- list:setPositionY(lineTop:getPositionY() - 18)
	-- list:setContentSize(cc.size(list:getContentSize().width ,listH))
	self.svd_ = require("util.ScrollViewDelegate"):create(list ,cc.size(10,5), cc.size(815,110))
	self.svd_:getScrollView():setScrollBarEnabled(false)

	-- rn:getChildByName("btnReward"):setPositionY(lineBottom:getPositionY() - 10)

	for i,v in ipairs(self.labels) do
		leftPanel:getChildByName(v.."_text"):setString(CONF:getStringValue(v))		
	end

	rn:getChildByName("Image_18"):getChildByName("rank"):setString(CONF:getStringValue("RankList"))
end

function RankLayer:addTouchListener( node, func,node2)

	local isTouchMe = false

	local function onTouchBegan(touch, event)

		local target = event:getCurrentTarget()
		
		local locationInNode = node:convertToNodeSpace(touch:getLocation())

		local sv_s = node:getContentSize()
		local sv_rect = cc.rect(0, 0, sv_s.width, sv_s.height)

		if cc.rectContainsPoint(sv_rect, locationInNode) then

			local ln = target:convertToNodeSpace(touch:getLocation())

			local s = target:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)
			
			if cc.rectContainsPoint(rect, ln) then
				isTouchMe = true
				return true
			end

		end
		return false
	end

	local function onTouchMoved(touch, event)

		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			isTouchMe = false
		end
	end

	local function onTouchEnded(touch, event)
		if isTouchMe == true then
				
			func(node)
		end
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = node:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

--{"player_power" ,"PlayerLevel" ,"CentreLevel" ,"leaguePower" ,"arena_rank" ,"trial_rank"}
function RankLayer:createElement( info )
	local node 
	local function setPosX( node1 ,node2 ,num)
		node2:setPositionX(node1:getPositionX() + node1:getContentSize().width + num)
	end 
	--个人战力
	if self.selectType == self.labels[1] then 
		node = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/player_arena_Node.csb")
		node:getChildByName("playerName"):setString(info.nickname)
		node:getChildByName("leagueName_0"):setString(CONF:getStringValue("covenant")..":")

		node:getChildByName("leagueName"):setPositionX(node:getChildByName("leagueName_0"):getPositionX() + node:getChildByName("leagueName_0"):getContentSize().width)

		local leagueName = info.group_nickname
		if leagueName and leagueName ~= "" then
			node:getChildByName("leagueName"):setString(info.group_nickname)
		else 
			node:getChildByName("leagueName"):setString(CONF:getStringValue("leagueNmae"))
		end

		setPosX(node:getChildByName("playerName") ,node:getChildByName("lv") ,15)
		setPosX(node:getChildByName("lv") ,node:getChildByName("lvNum") ,2)
		node:getChildByName("lvNum"):setString(info.level)
		node:getChildByName("powerNum"):setString(info.power)
		local ranking = info.power_rank
		local rankIcon = node:getChildByName("icon")
		if ranking == 1 then
			rankIcon:setTexture("RankLayer/ui/icon1st.png")
		elseif ranking == 2 then
			rankIcon:setTexture("RankLayer/ui/icon2nd.png")
		elseif ranking == 3 then
			rankIcon:setTexture("RankLayer/ui/icon3rd.png")
		else
			rankIcon:removeFromParent()
			local rankNum = node:getChildByName("ranking")
			rankNum:setVisible(true)
			rankNum:setString(ranking)
		end

		local shipList = info.id_lineup
		local lvList = info.lv_lineup
		local breList = info.break_lineup
		local nodePos = node:getChildByName("pos")
		local num = 0
		for k,v in pairs(shipList) do
			if v ~= 0 then
				local ship = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/ShipNode.csb")
				ship:getChildByName("lvNum"):setString(lvList[k])
				ship:setName("ship_ship"..k)
				print("breList[k]" ,k ,breList[k])
				--飞船突破次数显示
--				if breList[k] then 
--					for i=1,breList[k] do
--						if ship:getChildByName("star_" .. i) then
--							ship:getChildByName("star_" .. i):setVisible(true)
--						end
--					end
--				end
                player:ShowShipStar(ship,breList[k],"star_")

				local conf = CONF.AIRSHIP.get(v)
				ship:getChildByName("bg"):loadTexture("RankLayer/ui/ui_avatar_" .. conf.QUALITY ..".png")
				ship:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")
                ship:getChildByName("icon"):setVisible(false)
                ship:getChildByName("icon2"):setVisible(true)
                ship:getChildByName("icon2"):setTexture("ShipImage/"..conf.DRIVER_ID..".png")
				local posX = nodePos:getPositionX() + num * 88
				num = num + 1
				local posY = nodePos:getPositionY()
				ship:setPosition(cc.p(posX ,posY))

				local shipType = "Common/ui/ui_icon_"
				if conf.TYPE == 1 then 
					shipType = shipType .. "attack.png"
				elseif conf.TYPE == 2 then
					shipType = shipType .. "defense.png"
				elseif conf.TYPE == 3 then
					shipType = shipType .. "control.png"
				elseif conf.TYPE == 4 then
					shipType = shipType .. "cure.png"
				end                
				ship:getChildByName("shipType"):setTexture(shipType)
				ship:getChildByName("event"):setSwallowTouches(true)
				-- ship:getChildByName("event"):addClickEventListener(function()
				-- 	self:setSelectedVisible(ship:getParent():getTag(),k)
				-- 	end)
				local function func()
					if not self:getResourceNode():getChildByName("PlayerInfoNode") then
						self:setSelectedVisible(ship:getParent():getTag(),k)
						local info_node = require("util.ItemInfoNode"):createShipInfoNode(conf.ID,lvList[k])
				        local center = cc.exports.VisibleRect:center()
				        local bg = info_node:getChildByName("landi")
				        info_node:setPosition(cc.p(center.x - bg:getContentSize().width/2*bg:getScaleX(), center.y + bg:getContentSize().height/2*bg:getScaleY()+50))
				        info_node:setName("ItemInfoNode")
				        self:getResourceNode():addChild(info_node,11)
				    end
				end
				-- self:addTouchListener(ship:getChildByName("event"),func,ship)
				node:addChild(ship)
			end
		end

	--个人等级
	elseif self.selectType == self.labels[2] then 
		node = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/player_level_Node.csb")
		node:getChildByName("leagueName_0"):setString(CONF:getStringValue("covenant")..":")

		node:getChildByName("leagueName"):setPositionX(node:getChildByName("leagueName_0"):getPositionX() + node:getChildByName("leagueName_0"):getContentSize().width)

		node:getChildByName("playerName"):setString(info.nickname)
		local leagueName = info.group_nickname
		if leagueName and leagueName ~= "" then
			node:getChildByName("leagueName"):setString(info.group_nickname)
		else 
			node:getChildByName("leagueName"):setString(CONF:getStringValue("leagueNmae"))
		end
		node:getChildByName("lvNum"):setString(info.level)
		local ranking = info.level_rank
		local rankIcon = node:getChildByName("icon")
		if ranking == 1 then
			rankIcon:setTexture("RankLayer/ui/icon1st.png")
		elseif ranking == 2 then
			rankIcon:setTexture("RankLayer/ui/icon2nd.png")
		elseif ranking == 3 then
			rankIcon:setTexture("RankLayer/ui/icon3rd.png")
		else
			rankIcon:removeFromParent()
			local rankNum = node:getChildByName("ranking")
			rankNum:setVisible(true)
			rankNum:setString(ranking)
		end
	--主城等级
	elseif self.selectType == self.labels[3] then 
		node = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/player_level_Node.csb")
		node:getChildByName("leagueName_0"):setString(CONF:getStringValue("covenant")..":")

		node:getChildByName("leagueName"):setPositionX(node:getChildByName("leagueName_0"):getPositionX() + node:getChildByName("leagueName_0"):getContentSize().width)

		node:getChildByName("playerName"):setString(info.nickname)
		node:getChildByName("center"):setVisible(true)
		local leagueName = info.group_nickname
		if leagueName and leagueName ~= "" then
			node:getChildByName("leagueName"):setString(info.group_nickname)
		else 
			node:getChildByName("leagueName"):setString(CONF:getStringValue("leagueNmae"))
		end
		node:getChildByName("lvNum"):setString(info.building_level_list[1])
		local ranking = info.main_city_level_rank
		local rankIcon = node:getChildByName("icon")
		if ranking == 1 then
			rankIcon:setTexture("RankLayer/ui/icon1st.png")
		elseif ranking == 2 then
			rankIcon:setTexture("RankLayer/ui/icon2nd.png")
		elseif ranking == 3 then
			rankIcon:setTexture("RankLayer/ui/icon3rd.png")
		else
			rankIcon:removeFromParent()
			local rankNum = node:getChildByName("ranking")
			rankNum:setVisible(true)
			rankNum:setString(ranking)
		end
	--工会战力        
	elseif self.selectType == self.labels[4] then 
		node = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/player_league_Node.csb")
		node:getChildByName("leaderName"):setString(CONF:getStringValue("leader")..":")

		node:getChildByName("leaderName_0"):setString(CONF:getStringValue("leader_xm")..":")
		node:getChildByName("leaderName"):setPositionX(node:getChildByName("leaderName_0"):getPositionX() + node:getChildByName("leaderName_0"):getContentSize().width)

		node:getChildByName("leagueName"):setString(info.nickname)
		node:getChildByName("leaderName"):setString(info.leader_name)
		node:getChildByName("lvNum"):setString(info.level)
		node:getChildByName("powerNum"):setString(info.power)

	--竞技场        
	elseif self.selectType == self.labels[5] then 
		node = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/player_arena_Node.csb")
		node:getChildByName("playerName"):setString(info.nickname)
		node:getChildByName("leagueName_0"):setString(CONF:getStringValue("covenant")..":")

		node:getChildByName("leagueName"):setPositionX(node:getChildByName("leagueName_0"):getPositionX() + node:getChildByName("leagueName_0"):getContentSize().width)

		local leagueName = info.group_nickname
		if leagueName and leagueName ~= "" then
			node:getChildByName("leagueName"):setString(info.group_nickname)
		else 
			node:getChildByName("leagueName"):setString(CONF:getStringValue("leagueNmae"))
		end
		node:getChildByName("lvNum"):setString(info.level)
		node:getChildByName("powerNum"):setString(info.power)

		setPosX(node:getChildByName("playerName") ,node:getChildByName("lv") ,15)
		setPosX(node:getChildByName("lv") ,node:getChildByName("lvNum") ,2)

		local shipList = info.id_lineup
		local lvList = info.lv_lineup
		local breList = info.break_lineup
		local nodePos = node:getChildByName("pos")
		local num = 0
		for k,v in pairs(shipList) do
			if v ~= 0 then
				local ship = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/ShipNode.csb")
				ship:getChildByName("lvNum"):setString(lvList[k])
				ship:setName("ship_ship"..k)
				local conf = CONF.AIRSHIP.get(v)
				ship:getChildByName("bg"):loadTexture("RankLayer/ui/ui_avatar_" .. conf.QUALITY ..".png")
				ship:getChildByName("icon"):loadTexture("RoleIcon/"..conf.DRIVER_ID..".png")
                ship:getChildByName("icon"):setVisible(false)
                ship:getChildByName("icon2"):setVisible(true)
                ship:getChildByName("icon2"):setTexture("ShipImage/"..conf.DRIVER_ID..".png")
				local posX = nodePos:getPositionX() + num * 88
				num = num + 1
				local posY = nodePos:getPositionY()
				ship:setPosition(cc.p(posX ,posY))

				--飞船突破次数显示
--				if breList[k] and breList[k] > 0 then 
--					for i=1,breList[k] do
--						if ship:getChildByName("star_" .. i) then
--							ship:getChildByName("star_" .. i):setVisible(true)
--						end
--					end
--				end
                player:ShowShipStar(ship,breList[k],"star_")

				local shipType = "Common/ui/ui_icon_"
				if conf.TYPE == 1 then 
					shipType = shipType .. "attack.png"
				elseif conf.TYPE == 2 then
					shipType = shipType .. "defense.png"
				elseif conf.TYPE == 3 then
					shipType = shipType .. "control.png"
				elseif conf.TYPE == 4 then
					shipType = shipType .. "cure.png"
				end                
				ship:getChildByName("shipType"):setTexture(shipType)
				local function func()
					if not self:getResourceNode():getChildByName("PlayerInfoNode") then
						self:setSelectedVisible(ship:getParent():getTag(),k)
						local info_node = require("util.ItemInfoNode"):createShipInfoNode(conf.ID,lvList[k])
				        local center = cc.exports.VisibleRect:center()
				        local bg = info_node:getChildByName("landi")
				        info_node:setPosition(cc.p(center.x - bg:getContentSize().width/2*bg:getScaleX(), center.y + bg:getContentSize().height/2*bg:getScaleY()+50))
				        info_node:setName("ItemInfoNode")
				        self:getResourceNode():addChild(info_node,11)
				    end
				end
				-- self:addTouchListener(ship:getChildByName("event"),func,ship)
				node:addChild(ship)
			end
		end

	--试炼        
	elseif self.selectType == self.labels[6] then 
		node = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/player_trial_Node.csb")
		node:getChildByName("leagueName_0"):setString(CONF:getStringValue("covenant")..":")
		node:getChildByName("leagueName"):setPositionX(node:getChildByName("leagueName_0"):getPositionX() + node:getChildByName("leagueName_0"):getContentSize().width)

		node:getChildByName("playerName"):setString(info.nickname)
		local leagueName = info.group_nickname
		if leagueName and leagueName ~= "" then
			node:getChildByName("leagueName"):setString(info.group_nickname)
		else 
			node:getChildByName("leagueName"):setString(CONF:getStringValue("leagueNmae"))
		end
		node:getChildByName("lvNum"):setString(info.level)
		node:getChildByName("powerNum"):setString(info.power)
		node:getChildByName("starNum"):setString(info.max_trial_star)

		setPosX(node:getChildByName("playerName") ,node:getChildByName("lv") ,15)
		setPosX(node:getChildByName("lv") ,node:getChildByName("lvNum") ,2)

		local trial = CONF.TRIAL_LEVEL.get(info.max_trial_level)
		local tiral_area = CONF.TRIAL_AREA.get(trial.AREA_ID)
		local trial_copy = CONF.TRIAL_COPY.get(trial.T_COPY_ID)
		node:getChildByName("trialArea"):setString(CONF:getStringValue(tiral_area.NAME_ID))
		local str = string.gsub(tostring(trial_copy.COPYMAP_ID) ,"0" ,"-")
		node:getChildByName("trialName"):setString(str)

		local ranking = info.max_trial_level_rank
		local rankIcon = node:getChildByName("icon")
		if ranking == 1 then
			rankIcon:setTexture("RankLayer/ui/icon1st.png")
		elseif ranking == 2 then
			rankIcon:setTexture("RankLayer/ui/icon2nd.png")
		elseif ranking == 3 then
			rankIcon:setTexture("RankLayer/ui/icon3rd.png")
		else
			rankIcon:removeFromParent()
			local rankNum = node:getChildByName("ranking")
			rankNum:setVisible(true)
			rankNum:setString(ranking)
		end

	end
--	node:getChildByName("selected_1"):setVisible(false)
	return node
end


function RankLayer:setSelectedVisible(nodePos,shipPos)--种类，第几个长条，第几艘飞船
	local function setScale9(node,selected)
		if selected then
			node:getChildByName("selected"):setVisible(true)
--			node:getChildByName("selected_1"):setVisible(true)
			node:getChildByName("background"):setVisible(false)
		else
			node:getChildByName("background"):setVisible(true)
			node:getChildByName("selected"):setVisible(false)
--			node:getChildByName("selected_1"):setVisible(false)
		end
	end
	if shipPos then
		setScale9(self.svd_:getScrollView():getChildByName("node_node"..nodePos):getChildByName("ship_ship"..shipPos),true)
		if self.nodePos then
			setScale9(self.svd_:getScrollView():getChildByName("node_node"..self.nodePos),false)
			if self.shipPos then
				if self.shipPos ~= shipPos or self.nodePos ~= nodePos then
					setScale9(self.svd_:getScrollView():getChildByName("node_node"..self.nodePos):getChildByName("ship_ship"..self.shipPos),false)
				end 
			end
		end
	else
		if nodePos then
			setScale9(self.svd_:getScrollView():getChildByName("node_node"..nodePos),true)
			if self.shipPos then
				setScale9(self.svd_:getScrollView():getChildByName("node_node"..self.nodePos):getChildByName("ship_ship"..self.shipPos),false)
			end
			if self.nodePos and self.nodePos ~= nodePos then
				setScale9(self.svd_:getScrollView():getChildByName("node_node"..self.nodePos),false)
			end
		end
	end
	self.shipPos = shipPos
	self.nodePos = nodePos
end


--更新list的同时， 还要更新 下方个人相关排行数据
function RankLayer:resetList(  )
	self.svd_:clear()
	self.nodePos = nil
	self.shipPos = nil
	local rn = self:getResourceNode()
	local pos = rn:getChildByName("pos")
	local btnReward = rn:getChildByName("btnReward")
	btnReward:setVisible(false)
	local textNode

	local function setPosX(node1 ,node2 ,num)
		node2:setPositionX(node1:getPositionX() + node1:getContentSize().width + num)
	end 
	if self.selectType == self.labels[1] then
		print("战力排行")
		textNode = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/rank_power.csb")
		textNode:getChildByName("time"):removeFromParent()
		textNode:getChildByName("time_num"):removeFromParent()
		local ranking = textNode:getChildByName("rank")
		local rankingNum = textNode:getChildByName("rank_num")
		local power = textNode:getChildByName("power")
		local powerNum = textNode:getChildByName("power_num")
		ranking:setString(CONF:getStringValue("myRanking"))

		local myRanking = self.rankList.my_user_rank
		if myRanking  then
			rankingNum:setString(myRanking.power_rank)
		else 
			rankingNum:setString(CONF:getStringValue("notInRanking"))
		end
		powerNum:setString(myRanking.power)

		setPosX(ranking ,rankingNum ,20)
		power:setPositionX(rankingNum:getPositionX() + rankingNum:getContentSize().width / 2 + 40)
		powerNum:setPositionX(power:getPositionX() + 20)

		local powerRankList = self.rankList.user_rank
		table.sort( powerRankList, function(a ,b )
			if a.power_rank < b.power_rank then 
				return true
			else 
				return false
			end
		end )

		for k,v in pairs(powerRankList) do
			local node = self:createElement(v)
			node:getChildByName("selected"):setVisible(false)
			local function func()
				if not rn:getChildByName("ItemInfoNode") then
					self:setSelectedVisible(k,nil)
					local node = require("app.views.RankLayer.PlayerInfoNode"):create(v)
					node:setName("PlayerInfoNode")
					rn:addChild(node,11)
				end
			end
			node:setName("node_node"..k)
			node:setTag(k)
			local callback = {node = node:getChildByName("background"), func = func}
			self.svd_:addElement(node,{callback = callback})
		end

	elseif self.selectType == self.labels[2] then 
		print("等级排行")
		textNode = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/rank_level.csb")
		local ranking = textNode:getChildByName("rank")
		local rankingNum = textNode:getChildByName("rank_num")
		local lv = textNode:getChildByName("lv")
		local lvNum = textNode:getChildByName("lv_num")
		ranking:setString(CONF:getStringValue("myRanking"))

		local myRanking = self.rankList.my_user_rank
		if myRanking  then
			rankingNum:setString(myRanking.level_rank)
		else 
			rankingNum:setString(CONF:getStringValue("notInRanking"))
		end

		lvNum:setString(myRanking.level) 

		setPosX(ranking ,rankingNum ,10)
		setPosX(rankingNum ,lv ,40)
		setPosX(lv ,lvNum ,2)

		for k,v in pairs(self.rankList.user_rank) do
			local node = self:createElement(v)
			local function func()
				self:setSelectedVisible(k,nil)
				local node = require("app.views.RankLayer.PlayerInfoNode"):create(v)
				rn:addChild(node,11)
			end
			node:setName("node_node"..k)
			node:setTag(k)
			local callback = {node = node:getChildByName("background"), func = func}
			self.svd_:addElement(node,{callback = callback})
			-- self.svd_:addElement(node)
		end

	elseif self.selectType == self.labels[3] then 
		print("主城等级")
		textNode = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/rank_level.csb")
		local ranking = textNode:getChildByName("rank")
		local rankingNum = textNode:getChildByName("rank_num")
		local lv = textNode:getChildByName("lv")
		local lvNum = textNode:getChildByName("lv_num")
		ranking:setString(CONF:getStringValue("myRanking"))

		rankingNum:setString(self.rankList.my_user_rank.main_city_level_rank)
		lvNum:setString(self.rankList.my_user_rank.building_level_list[1]) 

		rankingNum:setPositionX(ranking:getPositionX() + ranking:getContentSize().width + 10)
		lv:setPositionX(rankingNum:getPositionX() +rankingNum:getContentSize().width + 40 )
		lvNum:setPositionX(lv:getPositionX() + lv:getContentSize().width + 2)

		setPosX(ranking ,rankingNum ,10)
		setPosX(rankingNum ,lv ,40)
		setPosX(lv ,lvNum ,2)

		local CenterRankList = self.rankList.user_rank
		table.sort( CenterRankList, function(a ,b )
			if a.main_city_level_rank < b.main_city_level_rank then 
				return true
			else 
				return false
			end
		end )

		for k,v in pairs(CenterRankList) do
			local node = self:createElement(v)
			local function func()
				self:setSelectedVisible(k,nil)
				local node = require("app.views.RankLayer.PlayerInfoNode"):create(v)
				rn:addChild(node,11)
			end
			node:setName("node_node"..k)
			node:setTag(k)
			local callback = {node = node:getChildByName("background"), func = func}
			self.svd_:addElement(node,{callback = callback})
		end

	elseif self.selectType == self.labels[4] then 
		print("--------工会战力")
		textNode = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/rank_power.csb")
		textNode:getChildByName("time"):removeFromParent()
		textNode:getChildByName("time_num"):removeFromParent()

		local ranking = textNode:getChildByName("rank")
		local rankingNum = textNode:getChildByName("rank_num")
		local power = textNode:getChildByName("power")
		local powerNum = textNode:getChildByName("power_num")
		ranking:setString(CONF:getStringValue("leagueRanking"))
		  
		if player:getGroupName() == "" then
			ranking:removeFromParent()
			rankingNum:removeFromParent()
			power:removeFromParent()
			powerNum:removeFromParent()
			local text = textNode:getChildByName("text")
			text:setVisible(true)
			text:setString(CONF:getStringValue("notInLeague"))

		else 
			rankingNum:setString(player:getPlayerGroupMain().rank)
			self:getStarPower() 
			setPosX(ranking ,rankingNum ,20)
			power:setPositionX(rankingNum:getPositionX() + rankingNum:getContentSize().width / 2 + 40)
			powerNum:setPositionX(power:getPositionX() + 20)
		end

		local group_rank = self.rankList.group_rank

		-- local function sort( a,b )
		-- 	if a.power ~= b.power then
		-- 		return a.power > b.power
		-- 	else
		-- 		if a.level ~= b.level then
		-- 			return a.level > b.level 
		-- 		else
		-- 			return tonumber(a.groupid) < tonumber(b.groupid)
		-- 		end
		-- 	end
		-- end

		-- table.sort(group_rank, sort)

		for k,v in ipairs(group_rank) do
			local node = self:createElement(v)
			local rankIcon = node:getChildByName("icon")
			if k == 1 then
				rankIcon:setTexture("RankLayer/ui/icon1st.png")
			elseif k == 2 then
				rankIcon:setTexture("RankLayer/ui/icon2nd.png")
			elseif k == 3 then
				rankIcon:setTexture("RankLayer/ui/icon3rd.png")
			else
				rankIcon:removeFromParent()
				local rankNum = node:getChildByName("ranking")
				rankNum:setVisible(true)
				rankNum:setString(k)
			end
			self.svd_:addElement(node)
		end

	elseif self.selectType == self.labels[5] then 
		print("竞技排行")
		textNode = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/rank_power.csb")
		local ranking = textNode:getChildByName("rank")
		local rankingNum = textNode:getChildByName("rank_num")
		local power = textNode:getChildByName("power")
		local powerNum = textNode:getChildByName("power_num")
		local time = textNode:getChildByName("time")
		local timeNum = textNode:getChildByName("time_num")
		ranking:setString(CONF:getStringValue("myRanking"))
		time:setString(CONF:getStringValue("rewardTime") .. ":")

		self:getMyRanking()
		powerNum:setString(player:getPower())
		setPosX(ranking ,rankingNum ,20)
		power:setPositionX(rankingNum:getPositionX() + rankingNum:getContentSize().width / 2 + 40)
		powerNum:setPositionX(power:getPositionX() + 20)
		setPosX(time ,timeNum ,30)
		--计算时间

		time:setVisible(false)
		timeNum:setVisible(false)

		btnReward:setVisible(true)
		btnReward:getChildByName("text"):setString(CONF:getStringValue("rankingReward"))
		btnReward:addClickEventListener(function (  )
			print("打开奖励界面")
			local layer = self:getApp():createView("RankLayer/RewardLayer")
			self:addChild(layer)
		end)


		for k,v in pairs(self.rankList.user_rank) do
			local node = self:createElement(v)
			local rankIcon = node:getChildByName("icon")
			if k == 1 then
				rankIcon:setTexture("RankLayer/ui/icon1st.png")
			elseif k == 2 then
				rankIcon:setTexture("RankLayer/ui/icon2nd.png")
			elseif k == 3 then
				rankIcon:setTexture("RankLayer/ui/icon3rd.png")
			else
				rankIcon:removeFromParent()
				local rankNum = node:getChildByName("ranking")
				rankNum:setVisible(true)
				rankNum:setString(k)
			end
			local function func()
				if not rn:getChildByName("ItemInfoNode") then
					self:setSelectedVisible(k,nil)
					local node = require("app.views.RankLayer.PlayerInfoNode"):create(v)
					node:setName("PlayerInfoNode")
					rn:addChild(node,11)
				end
			end
			node:setName("node_node"..k)
			node:setTag(k)
			local callback = {node = node:getChildByName("background"), func = func}
			self.svd_:addElement(node,{callback = callback})
		end


	elseif self.selectType == self.labels[6] then 
		print("试炼排行")
		textNode = require("app.ExResInterface"):getInstance():FastLoad("RankLayer/rank_trial.csb")
		local ranking = textNode:getChildByName("rank")
		local rankingNum = textNode:getChildByName("rank_num")
		local star = textNode:getChildByName("star")
		local starNum = textNode:getChildByName("starNum")
		local trialArea = textNode:getChildByName("trialArea")
		local trialName = textNode:getChildByName("trialName")
		ranking:setString(CONF:getStringValue("myRanking"))

		local myRanking = self.rankList.my_user_rank
		if myRanking.max_trial_level > 0 then 
			rankingNum:setString(myRanking.max_trial_level_rank)
			starNum:setString(myRanking.max_trial_star)
			local trial = CONF.TRIAL_LEVEL.get(myRanking.max_trial_level)
			local tiral_area = CONF.TRIAL_AREA.get(trial.AREA_ID)
			local trial_copy = CONF.TRIAL_COPY.get(trial.T_COPY_ID)
			trialArea:setString(CONF:getStringValue(tiral_area.NAME_ID))
			local str = string.gsub(tostring(trial_copy.COPYMAP_ID) ,"0" ,"-")
			trialName:setString(str)

			-- star:setPositionX(rankingNum:getPositionX() + rankingNum:getContentSize().width + 40)
			starNum:setPositionX(star:getPositionX() + 2)
			-- setPosX(starNum ,trialArea ,40)
			setPosX(trialArea ,trialName ,2)
		else 
			star:removeFromParent()
			starNum:removeFromParent()
			trialArea:removeFromParent()
			trialName:removeFromParent()
			rankingNum:setString(CONF:getStringValue("notInRanking"))
		end 
		setPosX(ranking ,rankingNum ,0)

		local trialRankList = self.rankList.user_rank

		table.sort( trialRankList, function(a ,b )
			if a.max_trial_level_rank < b.max_trial_level_rank then 
				return true
			else 
				return false
			end
		end )

		for k,v in pairs(trialRankList) do
			local node = self:createElement(v)
			local function func()
				self:setSelectedVisible(k,nil)
				local node = require("app.views.RankLayer.PlayerInfoNode"):create(v)
				rn:addChild(node,11)
			end
			node:setName("node_node"..k)
			node:setTag(k)
			local callback = {node = node:getChildByName("background"), func = func}
			self.svd_:addElement(node,{callback = callback})
		end

	end

	textNode:setPositionX(pos:getPositionX())
	textNode:setPositionY(pos:getPositionY())
	textNode:setName("textNode")
	rn:addChild(textNode ,10)
	if self.textNode then
		self.textNode:removeFromParent()
	end
	self.textNode = textNode
end

--获取 对应排行的列表
function RankLayer:requireList( )
	local strData 
	if self.selectType == self.labels[1] then
		print("战力排行")
		strData = Tools.encode("RankReq", {
			rank_type = "PLAYER_POWER",
			start_rank = 1, 
			need_my = true,
		})

	elseif self.selectType == self.labels[2] then 
		strData = Tools.encode("RankReq", {
			rank_type = "PLAYER_LEVEL",
			start_rank = 1, 
			need_my = true,
		})
		print("等级排行")
	elseif self.selectType == self.labels[3] then 
		print("主城等级")
		strData = Tools.encode("RankReq", {
			rank_type = "MAIN_CITY_LEVEL",
			start_rank = 1, 
			need_my = true,
		})

	elseif self.selectType == self.labels[4] then 
		print("工会等级")
		strData = Tools.encode("RankReq", {
			rank_type = "GROUP_POWER",
			start_rank = 1, 
			need_my = true,
		})

	elseif self.selectType == self.labels[5] then 
		print("竞技排行")
		strData = Tools.encode("RankReq", {
			rank_type = "ARENA",
			start_rank = 1, 
			need_my = true,
		})

	elseif self.selectType == self.labels[6] then 
		print("试炼排行")
		strData = Tools.encode("RankReq", {
			rank_type = "TRIAL",
			start_rank = 1, 
			need_my = true,
		})

	end	
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_RANK_REQ"),strData)
	gl:retainLoading()
end

--进入界面时打开特定的排行榜
function RankLayer:changeType()
	local leftPanel = self:getResourceNode():getChildByName("leftBg")
	local node = leftPanel:getChildByName(self.selectType)
	-- node:getChildByName("light1"):setVisible(true)
	-- node:getChildByName("light2"):setVisible(true)
	node:setOpacity(255)
	leftPanel:getChildByName(self.selectType.."_text"):setTextColor(cc.c4b(205, 235, 247,255))
	-- leftPanel:getChildByName(self.selectType.."_text"):setPositionX(leftPanel:getChildByName("Image_23"):getPositionX()+18)
	self:requireList()
end

--切换排行榜
function RankLayer:addTouch(  )
	local leftPanel = self:getResourceNode():getChildByName("leftBg")
	for i,v in ipairs(self.labels) do
		local node = leftPanel:getChildByName(v)
		node:addTouchEventListener(function ( sender, eventType )        	
			if  self.selectType == node:getName() then
				return
			else
				playEffectSound("sound/system/tab.mp3")
				local preNode = leftPanel:getChildByName(self.selectType)
				-- preNode:getChildByName("light1"):setVisible(false)
				-- preNode:getChildByName("light2"):setVisible(false)
				-- node:getChildByName("light1"):setVisible(true)
				-- node:getChildByName("light2"):setVisible(true)
				node:setOpacity(255)
				leftPanel:getChildByName(node:getName().."_text"):setTextColor(cc.c4b(205, 235, 247,255))
				-- leftPanel:getChildByName(node:getName().."_text"):setPositionX(leftPanel:getChildByName("Image_23"):getPositionX()+18)

				leftPanel:getChildByName(self.selectType.."_text"):setTextColor(cc.c4b(209, 209, 209,255))
				-- leftPanel:getChildByName(self.selectType.."_text"):setPositionX(leftPanel:getChildByName("Image_23"):getPositionX())
				preNode:setOpacity(0)
				self.selectType = node:getName()
				self:requireList()
			end
		end)
	end
end

function RankLayer:getStarPower(  )
	local name_list = {}
	for i,v in ipairs(player:getPlayerGroupMain().user_list) do
		table.insert(name_list, v.user_name)
	end
	local strData = Tools.encode("CmdGetOtherUserInfoListReq", {
		user_name_list = name_list,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_OTHER_USER_INFO_LIST_REQ"),strData)
end

function RankLayer:getMyRanking(  )
	local strData = Tools.encode("ArenaInfoReq", {
				type = 1,
			})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_ARENA_INFO_REQ"),strData)
end

function RankLayer:onExitTransitionStart()
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
end

return RankLayer