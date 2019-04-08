
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local player = require("app.Player"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local planetManager = require('app.views.PlanetScene.Manager.PlanetManager'):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local PlanetUILayer = class("PlanetUILayer", cc.load("mvc").ViewBase)

local app = require("app.MyApp"):getInstance()

PlanetUILayer.RESOURCE_FILENAME = "PlanetScene/PlanetUILayer.csb"

PlanetUILayer.RUN_TIMELINE = true

PlanetUILayer.NEED_ADJUST_POSITION = true

PlanetUILayer.accompany_army = {}

local schedulerSingles = {}
local schedulerWarning = nil
local schedulerEntry_Adventure = nil

-- PlanetUILayer.RESOURCE_BINDING = {
-- 	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
-- }

-- local openMenu = false

-- function PlanetUILayer:OnBtnClick(event)
-- 	if event.name == 'ended' then
-- 		if event.target:getName() == "close" then 
-- 			playEffectSound("sound/system/return.mp3")
-- 			-- self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
-- 			self:getApp():popView()
-- 		end
-- 	end
-- end

local Status = {
  kMove = 1,
  kMoveBack = 2,
  kMoveEnd = 3,
  kCollect = 4,
  kFishing = 5, -- 打捞
  kGuarde = 6, -- 驻扎
  kAccompany = 7, -- 陪同
  kEnlist = 8, -- 集结
}

local tagsTab = {}

PlanetUILayer.IS_DEBUG_VERBOSE = false


local function IsInTime(starttime,endtime)
	starttime = starttime/100
	local year = math.floor(starttime/10000)
	local month = math.floor(starttime/100%100)
	local day = math.floor(starttime%100)

	local tab = {year = year, month = month, day = day, hour =0, min = 0, sec = 0}
	local start_time = os.time(tab)

	endtime = endtime/100
	year = math.floor(endtime/10000)
	month = math.floor(endtime/100%100)
	day = math.floor(endtime%100)

	local tab2 = {year = year, month = month, day = day, hour =0, min = 0, sec = 0}
	local end_time = os.time(tab2)
	return (player:getServerTime() > start_time ) and (player:getServerTime() < end_time )
end
function PlanetUILayer:onCreate(data)
	self._data = data
end

function PlanetUILayer:onEnter()
  
	printInfo("PlanetUILayer:onEnter()")
	local strData = Tools.encode("GetMailListReq", {
		num = 0,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)

end

function PlanetUILayer:onExit()
	
	printInfo("PlanetUILayer:onExit()")
end


function PlanetUILayer:resetFindText( str )
	local rn = self:getResourceNode()
	local node_menu = rn:getChildByName('node_menu')

	if node_menu:getChildByName("find_richText") then
		node_menu:getChildByName("find_richText"):removeFromParent()
	end

	local richText = createRichTextNeedChangeColor(str)
	richText:setAnchorPoint(cc.p(0,0.5))
	richText:setPosition(cc.p(node_menu:getChildByName("find_text"):getPosition()))
	richText:setName("find_richText")
	node_menu:addChild(richText)

end

function PlanetUILayer:setLoadingVisible( flag )
	if( self.IS_DEBUG_VERBOSE ) then
		print("###LUA                                                       ")
		print("###LUA PlanetUILayer setLoadingVisible: " .. tostring(flag))
		print("###LUA                                                       ")
	end

	-- ADD WJJ 20180620 
	-- always hide 
	flag = false

	self:getResourceNode():getChildByName("loading"):setVisible(flag)
end

function PlanetUILayer:iconOpen()
	local rn = self:getResourceNode()
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
			local id = math.floor( conf.COUNT/100)
			if player:getSystemGuideStep(id) == 0  then
				if math.floor(systemGuideManager:getSelfGuideID()/100) == math.floor(conf.COUNT/100) then
					if systemGuideManager:getSelfGuideID()>=conf.COUNT then
						show = true
					end
				end
			else
				show = true
			end
		elseif conf.CONDITION == 3 then
			if player:getBuildingInfo(1).level >= conf.COUNT then
				show = true
			end
		end
		for k,v1 in ipairs(conf.BUILDING) do
			if v1 == 301 then
				rn:getChildByName("zc_bottom_chat_34"):setVisible(show)
				rn:getChildByName("chat_img"):setVisible(show)
				rn:getChildByName("di_text"):setVisible(show)
				rn:getChildByName("chat"):setVisible(show)
			elseif v1 == 302 then
				rn:getChildByName("league"):setVisible(show)
			elseif v1 == 303 then
				rn:getChildByName("league"):setVisible(show)
			elseif v1 == 304 then
				rn:getChildByName("bag"):setVisible(show)
			elseif v1 == 305 then
--				rn:getChildByName("mail"):setVisible(show)
			elseif v1 == 306 then
				rn:getChildByName("starRange"):setVisible(show)
			elseif v1 == 307 then
				rn:getChildByName("sfx"):setVisible(show)
				rn:getChildByName("home"):setVisible(show)
            elseif v1 == 102 then -- jiku
--                rn:getChildByName("ship"):setVisible(show)
--                print("11111",show)
			end
		end
	end
end

function PlanetUILayer:onEnterTransitionFinish()
	printInfo("PlanetUILayer:onEnterTransitionFinish()")
	local doShipListInfo = false
	local rn = self:getResourceNode()
	animManager:runAnimByCSB(rn:getChildByName("loading"), "PlanetScene/sfx/loading/loading.csb", "1")

	animManager:runAnimByCSB(rn:getChildByName("league"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
--	animManager:runAnimByCSB(rn:getChildByName("mail"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
    animManager:runAnimByCSB(rn:getChildByName("ship"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
	animManager:runAnimByCSB(rn:getChildByName("marker"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
	animManager:runAnimByCSB(rn:getChildByName("bag"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")
	animManager:runAnimByCSB(rn:getChildByName("starRange"):getChildByName("sfx"), "CityScene/sfx/huxi/Node.csb", "1")

	rn:getChildByName('bottom_top3'):setSwallowTouches(true)
	rn:getChildByName("Button_fanhui"):addClickEventListener(function ( ... )
		self:getParent():getDiamondLayer():moveBackUserBase()
	end)

	rn:getChildByName("btn_jinggao"):addClickEventListener(function ( ... )
		if planetManager:getPlanetUser() then
			self:getApp():addView2Top("PlanetScene/PlanetWarningLayer")
		end
	end)

	rn:getChildByName("runis_act"):setVisible(false)
	local actconf = CONF.ACTIVITY.get(16001)
	if actconf then
		if IsInTime(actconf.START_TIME ,actconf.END_TIME) then
			rn:getChildByName("runis_act"):setVisible(true)
			rn:getChildByName("runis_act"):getChildByName("runis_act"):setString(CONF:getStringValue("activity_006"))
		end
	end

	local node_menu = rn:getChildByName('node_menu')
	local function createMarkerNode( ... )
		local marker_node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/marker.csb")
		marker_node:setName("marker_node")

		local udcu = require("util.UserDataCmdUtil"):getInstance()
		local diffSize = udcu:getDiffSize()
		marker_node:setPosition(diffSize.width,diffSize.height)
		
		marker_node:getChildByName("title"):setString(CONF:getStringValue("bookmark"))

		marker_node:getChildByName("close"):addClickEventListener(function ( ... )
			marker_node:removeFromParent()
		end)
        marker_node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("skip"))
		marker_node:getChildByName("btn"):addClickEventListener(function ( ... )
			if tonumber(marker_node:getChildByName("shuru_x"):getString()) == nil or marker_node:getChildByName("shuru_y"):getString() == nil then
				tips:tips(CONF:getStringValue("coordinate mistake"))
				return
			end
			if tonumber(marker_node:getChildByName("shuru_x"):getString()) == "" or marker_node:getChildByName("shuru_y"):getString() == "" then
				tips:tips(CONF:getStringValue("coordinate mistake"))
				return
			end
			local pos =  {x = tonumber(marker_node:getChildByName("shuru_x"):getString()), y = tonumber(marker_node:getChildByName("shuru_y"):getString())}

			if checkNodeIDByGlobalPos(pos) then

				local event = cc.EventCustom:new("moveToUserRes")
				event.pos = pos
				event.node_id = getNodeIDByGlobalPos(pos)
				cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

				marker_node:removeFromParent()
			else
				tips:tips(CONF:getStringValue("coordinate mistake"))
			end

		end)

		local svd = require("util.ScrollViewDelegate"):create(marker_node:getChildByName("list"),cc.size(0,10), cc.size(445,70))
		marker_node:getChildByName("list"):setScrollBarEnabled(false)
		if planetManager:getPlanetUser() then
			for i,v in ipairs(planetManager:getPlanetUser().mark_list) do
				local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/marker_item.csb")
				node:getChildByName("name"):setString(v.name)
				node:getChildByName("pos"):setString("("..v.pos.x..","..v.pos.y..")")
				node:getChildByName("Button_share"):setPositionX(node:getChildByName("pos"):getPositionX() + node:getChildByName("pos"):getContentSize().width + 20)

				node:getChildByName("jump"):addClickEventListener(function ( ... )
					marker_node:removeFromParent()

					local event = cc.EventCustom:new("moveToUserRes")
					event.pos = v.pos
					event.node_id = getNodeIDByGlobalPos(v.pos)
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 
				end)

                node:getChildByName("share"):addClickEventListener(function ( ... )
					playEffectSound("sound/system/click.mp3")
                    marker_node:removeFromParent()
		            local msg = v.name .."  ".. "X:"..v.pos.x.." Y:"..v.pos.y
		            local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world",msg = msg})
		            layer:setName("chatLayer")
		            self:addChild(layer)
		            rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
				end)

				node:getChildByName("btn"):addClickEventListener(function ( ... )
					local strData = Tools.encode("PlanetMarkReq", {
						type = 2,
						name = v.name,
						pos = v.pos,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_MARK_REQ"),strData)
				end)

				svd:addElement(node)
			end
		end

		self:addChild(marker_node)
	end

	local function func_find(sender, eventType )
		if eventType == ccui.TouchEventType.began then 
			playEffectSound("sound/system/click.mp3")
			sender:loadTexture("PlanetScene/ui/pos_light.png")
			sender:getParent():getChildByName("find_icon"):setTexture("PlanetScene/ui/find_light.png")
		elseif eventType == ccui.TouchEventType.ended then 
			sender:loadTexture("ShopScene/ui/bottom_bg5.png")
			sender:getParent():getChildByName("find_icon"):setTexture("PlanetScene/ui/find.png")
			
			createMarkerNode()
		elseif eventType == ccui.TouchEventType.canceled then
			sender:loadTexture("ShopScene/ui/bottom_bg5.png")
			sender:getParent():getChildByName("find_icon"):setTexture("PlanetScene/ui/find.png") 
		end
	end
	node_menu:getChildByName("find_bg"):addTouchEventListener(func_find)

	local userInfoNode = require("util.UserInfoNode"):create()
	local canclick = false
	userInfoNode:init(self,true)
	userInfoNode:setName("userInfoNode")
	if rn:getChildByName("info_node"):getChildByName('userInfoNode') == nil then
		rn:getChildByName("info_node"):addChild(userInfoNode)
	end
	rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('league'):addClickEventListener(function(sender) 
		if not canclick then return end 
		local isOpen, heroLevel, centreLevel = IsFuncOpen('league')
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
		playEffectSound("sound/system/click.mp3")
		local event = cc.EventCustom:new("changeCT")
		cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
		self:getApp():pushView("StarLeagueScene/StarLeagueScene",{from = 'PlanetUILayer'})
	end)
	rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('sign'):addClickEventListener(function(sender) 
		if not canclick then return end  
		playEffectSound("sound/system/click.mp3")
		-- self:getApp():pushView("PlanetScene/SegmentumScene")
		self:getParent():createWorldLayer()
		rn:getChildByName("open_node"):getChildByName("node_open"):setVisible(false)
		canclick = false
	end)
	rn:getChildByName("open_node"):getChildByName("node_open"):setVisible(false)
	rn:getChildByName("home"):addTouchEventListener(function ( sender, eventType )
		if eventType == ccui.TouchEventType.began then
			
		elseif eventType == ccui.TouchEventType.moved then
			
		elseif eventType == ccui.TouchEventType.ended then
			
			playEffectSound("sound/system/return.mp3")
--			local enteranim = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/sfx/enteranim/enteranim.csb")
--		        animManager:runAnimOnceByCSB(enteranim,"PlanetScene/sfx/enteranim/enteranim.csb" ,"1", function ( )
--                enteranim:removeFromParent()
                self:getApp():addView2Top("CityScene/TransferScene",{from = "city" ,state = "start"})
                --app:pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos,sfx = false})
                -- self:getApp():pushToRootView("CityScene/TransferScene",{from = "city" ,state = "start"})
--            end)
--            enteranim:setName("enteranim")
--            local center = cc.exports.VisibleRect:center()
--            enteranim:setPosition(cc.p(center.x + (rn:getContentSize().width/2 - center.x), center.y + (rn:getContentSize().height/2 - center.y)))
--		    rn:addChild(enteranim)
--			self:getApp():addView2Top("CityScene/TransferScene",{from = "city" ,state = "start"})
		elseif eventType == ccui.TouchEventType.canceled then
			
		end
	end)
	rn:getChildByName("home"):getChildByName("text_miao"):setString(CONF:getStringValue("city"))

	local function judge( name )
		local node = rn:getChildByName(name)

		local isOpen = true
		if name == "mail" then
			local heroLevel = CONF.PARAM.get("mail_open").PARAM[1]
			local centreLevel = CONF.PARAM.get("mail_open").PARAM[2]

			if player:getLevel() < heroLevel or player:getBuildingInfo(1).level < centreLevel then
				isOpen = false
			end
		end

		node:addTouchEventListener(function ( sender, eventType )
			playEffectSound("sound/system/click.mp3")
			if isOpen == false then
				local tipStr = ""
				if CONF.PARAM.get("mail_open").PARAM[1] ~= 0 then 
					tipStr = tipStr .. CONF:getStringValue("levelNum") .. tostring(CONF.PARAM.get("mail_open").PARAM[1]) .. "\n"
				end
				if CONF.PARAM.get("mail_open").PARAM[2] ~= 0 then 
					tipStr = tipStr .. CONF:getStringValue("CentreLevel") .. CONF:getStringValue("achieve") .. tostring(CONF.PARAM.get("mail_open").PARAM[2])
				end

				tips:tips(tipStr)
			else
				if eventType == ccui.TouchEventType.began then
					rn:getChildByName(name):loadTexture("CityScene/ui3/icon_light.png")
				elseif eventType == ccui.TouchEventType.moved then
					rn:getChildByName(name):loadTexture("CityScene/ui3/icon_gray.png")
				elseif eventType == ccui.TouchEventType.ended then
					rn:getChildByName(name):loadTexture("CityScene/ui3/icon_gray.png")
					if name == "bag" then
						local event = cc.EventCustom:new("changeCT")
						cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
						self:getApp():pushView("ItemBagScene/ItemBagScene", {from = "planet"})
					elseif name == "marker" then
						local function createTiaoNode( ... )
							local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/tiaozhuan.csb")
							node:getChildByName("title"):setString(CONF:getStringValue("coord"))
							node:getChildByName("ins"):setString(CONF:getStringValue("import coordinate"))

							node:getChildByName("close"):addClickEventListener(function ( ... )
								node:removeFromParent()
							end)

							node:getChildByName("Button_3"):addClickEventListener(function ( ... )
								if tonumber(node:getChildByName("shuru_x"):getString()) == nil or node:getChildByName("shuru_y"):getString() == nil then
									tips:tips(CONF:getStringValue("coordinate mistake"))
									return
								end
								local pos =  {x = tonumber(node:getChildByName("shuru_x"):getString()), y = tonumber(node:getChildByName("shuru_y"):getString())}

								if checkNodeIDByGlobalPos(pos) then

									local event = cc.EventCustom:new("moveToUserRes")
									event.pos = pos
									cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 

									node:removeFromParent()
								else
									tips:tips(CONF:getStringValue("coordinate mistake"))
								end

							end)

							self:addChild(node)
						end
						createMarkerNode()
					elseif name == "mail" then
						local event = cc.EventCustom:new("changeCT")
						cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
						self:getApp():pushView("MailScene/MailScene",{from = 'Normal'})
                    elseif name == "ship" then
                        self:getApp():pushView("ShipsScene/ShipsDevelopScene",{type = 5})
					elseif name == "league" then
						self:getApp():pushView("StarLeagueScene/StarLeagueScene", {from = "PlanetUILayer"})
					elseif name == "starRange" then
                        if planetManager:getUserBaseElementInfo() and planetManager:getUserBaseElementInfo().global_key then
                            self:getParent():createWorldLayer()
                        end
					end

				elseif eventType == ccui.TouchEventType.canceled then
					rn:getChildByName(name):loadTexture("CityScene/ui3/icon_gray.png")
				end      		
			end
		end)
	end 

	judge("bag")
	judge("marker")
	judge("mail")
    judge("ship")
	judge("league")
	judge("starRange")
	rn:getChildByName("marker"):getChildByName("text_miao"):setString(CONF:getStringValue("bookmark"))
	rn:getChildByName("bag"):getChildByName("text_miao"):setString(CONF:getStringValue("knapsack"))
	rn:getChildByName("mail"):getChildByName("text_miao"):setString(CONF:getStringValue("mail"))
    rn:getChildByName("ship"):getChildByName("text_miao"):setString(CONF:getStringValue("Airship"))
	rn:getChildByName("league"):getChildByName("text_miao"):setString(CONF:getStringValue("covenant"))
	rn:getChildByName("starRange"):getChildByName("text_miao"):setString(CONF:getStringValue("map"))
	rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('sign'):getChildByName('text'):setString(CONF:getStringValue('map'))
	rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('league'):getChildByName('text'):setString(CONF:getStringValue('covenant'))
	animManager:runAnimByCSB(rn:getChildByName("sfx"), "CityScene/sfx/star/star.csb","1")

	rn:getChildByName('Button_chuzheng'):setVisible(false)
	rn:getChildByName('Node_list'):setVisible(false)
	self.size = rn:getChildByName('Node_list'):getChildByName('Image_16'):getContentSize()
	local btnShou = rn:getChildByName('Node_list'):getChildByName('Button_czshou')
	btnShou:addClickEventListener(function()
		if btnShou:getTag() == 326 then
			btnShou:setRotation(90)
			btnShou:setTag(327)
			rn:getChildByName('Node_list'):getChildByName('Text_chuzheng'):setVisible(false)
			rn:getChildByName('Node_list'):getChildByName('Image_16'):setVisible(false)
			for k,v in ipairs(tagsTab) do
				if rn:getChildByTag(v) then
					rn:getChildByTag(v):setVisible(false)
				end
			end
		elseif btnShou:getTag() == 327 then
			btnShou:setRotation(-90)
			btnShou:setTag(326)
			rn:getChildByName('Node_list'):getChildByName('Text_chuzheng'):setVisible(true)
			rn:getChildByName('Node_list'):getChildByName('Image_16'):setVisible(true)
			for k,v in ipairs(tagsTab) do
				if rn:getChildByTag(v) then
					rn:getChildByTag(v):setVisible(true)
				end
			end
		end
		end)
	self:updateChat()
	self:getFreshRES()
	if Tools.isEmpty(planetManager:getInfoList()) == false then
		self:shipListInfo()
	end
	local eventDispatcher = self:getEventDispatcher()
	-- self.list = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(3,3), cc.size(250,55))
	self.planetUserListener_ = cc.EventListenerCustom:create("updatePlanetUser", function (event)
		print("updatePlanetUser")
		if Tools.isEmpty(planetManager:getInfoList()) == false then
			self:accompany_armyRec()
			self:shipListInfo()
			doShipListInfo = true
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.planetUserListener_, FixedPriority.kNormal)
	self.infoListListener_ = cc.EventListenerCustom:create("updateInfoList", function (event)
		print("updateInfoList")
		if doShipListInfo == false then
			if Tools.isEmpty(planetManager:getPlanetUser( )) == false then
				self:accompany_armyRec()
				self:shipListInfo()
				doShipListInfo = true
			end
		end
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.infoListListener_, FixedPriority.kNormal)
	self.planetCloseMenuListener_ = cc.EventListenerCustom:create("PlanetSelectNodeOpen", function (event)

	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.planetCloseMenuListener_ , FixedPriority.kNormal)

	local function changeWarningInfo( ... )
		if planetManager:getPlanetUser() then
			if planetManager:getPlanetUser().attack_me_list then
				if #planetManager:getPlanetUser().attack_me_list > 0 then
					rn:getChildByName("btn_jinggao"):getChildByName("text"):setString(#planetManager:getPlanetUser().attack_me_list)
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

    local function UpdateLeague_Redpoint()
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
    end

	local function update( ... )
		changeWarningInfo()
		local bagShow = false
		local newItems = player:getItemUpdateTab()
		for k,v in pairs(newItems) do
			if next(v) then
				bagShow = true
			end
		end
		rn:getChildByName('bag'):getChildByName('point'):setVisible(bagShow)
        -- 
        UpdateLeague_Redpoint()

		local mailShow = false
		if player.mail_list_ then
			for k,mail in ipairs(player.mail_list_) do
				if mail.type == 0 or mail.type == 2 or mail.type == 4 then
					mailShow = true
					break
				end
			end
		end
--		rn:getChildByName('mail'):getChildByName('point'):setVisible(mailShow)
		local group_main = player:getPlayerGroupMain()
		if Tools.isEmpty(group_main) == false then
			rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('league'):getChildByName('notice_point'):setVisible(#group_main.enlist_list > 0)
		else
			rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('league'):getChildByName('notice_point'):setVisible(false)
		end
		local isOpen, heroLevel, centreLevel = IsFuncOpen('league')
		if isOpen == false then
			rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('league'):getChildByName('icon'):setTexture(string.format("CityScene/ui3/icon_%s_gray.png" ,'league'))
			rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('league'):getChildByName("text"):setTextColor(cc.c4b(209,209,209,255))
			rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('league'):getChildByName("text"):enableOutline(cc.c4b(209,209,209,255))
		end 
	end
	schedulerWarning = scheduler:scheduleScriptFunc(update,1,false)

	local function recvMsg()
		--print("PlanetAddSpeedLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_SPEED_UP_RESP") then

			local proto = Tools.decode("PlanetSpeedUpResp",strData)
			print("PlanetSpeedUpResp", proto.result)

			if proto.result == 0 then
                local strData = Tools.encode("PlanetGetReq", {
				    type = 1,
			    })
			    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData)
				self:accompany_armyRec()
				self:shipListInfo()
                player:userSync(proto.user_sync)
				if proto.type then
					tips:tips(CONF:getStringValue("use_speed_item_"..proto.type))
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_MAIL_LIST_UPDATE") then
			local strData = Tools.encode("GetMailListReq", {
				num = 0,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_REQ"),strData)
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_MAIL_LIST_RESP") then
			local proto = Tools.decode("GetMailListResp",strData)
			if proto.result == 0 then
				player.mail_list_ = proto.user_sync.mail_list
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_RESP") then
			local proto = Tools.decode("PlanetGetResp",strData)
			if proto.result ~= 0 then
				print("error :",proto.result, proto.type)
			else
				if proto.type == 6 then
					if Tools.isEmpty(proto.army_list) == false then
						table.insert(self.accompany_army,proto.army_list)
						self:shipListInfo()
					end
				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_PLANET_MARK_RESP") then
			local proto = Tools.decode("PlanetMarkResp",strData)
			if proto.result == 0 then
				if self:getChildByName("marker_node") then
					local marker_node = self:getChildByName("marker_node")
					local svd = require("util.ScrollViewDelegate"):create(marker_node:getChildByName("list"),cc.size(0,10), cc.size(445,70))
					for i,v in ipairs(marker_node:getChildByName("list"):getChildren()) do
						v:removeFromParent()
					end
					for i,v in ipairs(proto.mark_list) do
						local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/marker_item.csb")
						node:getChildByName("name"):setString(v.name)
						node:getChildByName("pos"):setString("("..v.pos.x..","..v.pos.y..")")
						node:getChildByName("btn"):addClickEventListener(function ( ... )
							local strData = Tools.encode("PlanetMarkReq", {
								type = 2,
								name = v.name,
								pos = v.pos,
							})
							GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_MARK_REQ"),strData)
						end)
						svd:addElement(node)
					end 
					tips:tips(CONF:getStringValue("Deleted_Successfully"))
					planetManager:setPlanetUserMarkList(proto.mark_list)
					
				else
					tips:tips(CONF:getStringValue("add_success"))
					planetManager:setPlanetUserMarkList(proto.mark_list)
				end
			end
		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	self.groupListener_ = cc.EventListenerCustom:create("update_group_main", function (event)
		local group_main = player:getPlayerGroupMain()
		if Tools.isEmpty(group_main) == false then
			local flag = false
			if player:hasGroupBossChallengeTimes(player:getGroupBossDays()[1].index) then
				flag = true
			end

			if player:getGroupHasWar() then
				flag = true
			end

			rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('league'):getChildByName('notice_point'):setVisible(flag)
			rn:getChildByName("open_node"):getChildByName("node_open"):getChildByName('league'):getChildByName('notice_point'):setVisible(#group_main.enlist_list > 0 )
		end
		end)
	eventDispatcher:addEventListenerWithFixedPriority(self.groupListener_, FixedPriority.kNormal)
	self.levelupListener_ = cc.EventListenerCustom:create("playerLevelUp", function ()
		self:iconOpen()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.levelupListener_, FixedPriority.kNormal)
	self.guideListener_ = cc.EventListenerCustom:create("GuideOver", function ()
		self:iconOpen()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.guideListener_, FixedPriority.kNormal)
	self.accompany_army = {}
	self:iconOpen()

	rn:getChildByName("Image_1"):setVisible(false)
	rn:getChildByName("Image_1"):getChildByName("text"):setString(CONF:getStringValue("adventure_gift"))
	animManager:runAnimByCSB(rn:getChildByName("Image_1"), "AdventureLayer/sfx/qiyu/UIeffect.csb", "1")
	rn:getChildByName("Image_1"):getChildByName("adventure_Btn"):addClickEventListener(function()
		if cc.exports.g_activate_building then
			return
		end
		if not display:getRunningScene():getChildByName("AdventureLayer") then
			local layer2 = self:getApp():createView("AdventureLayer/AdventureLayer")
			layer2:setPosition(cc.exports.VisibleRect:leftBottom())
			display:getRunningScene():addChild(layer2)
			layer2:setName("AdventureLayer")
		end
		end)
	local function updateAdventure()
		local newHandGigt = player:getNewHandGift()
		if newHandGigt.new_hand_gift_bag_list ~= nil and Tools.isEmpty(newHandGigt.new_hand_gift_bag_list) == false then
			rn:getChildByName("Image_1"):setVisible(true)
			rn:getChildByName("Image_1"):getChildByName("num"):setString(#newHandGigt.new_hand_gift_bag_list)
		else
			rn:getChildByName("Image_1"):setVisible(false)
		end
	end
	if schedulerEntry_Adventure == nil then
		schedulerEntry_Adventure = scheduler:scheduleScriptFunc(updateAdventure,1,false)
	end
end

function PlanetUILayer:accompany_armyRec()
	if planetManager:getPlanetUser( ) and Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
		for k,v in ipairs(planetManager:getPlanetUser( ).army_list) do
			if v.status ~= Status.kMoveEnd and v.accompany_army_key and v.accompany_army_key ~= '' then
				local strData = Tools.encode("PlanetGetReq", {
					army_key_list = {v.accompany_army_key},
					type = 6,
				 })
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_GET_REQ"),strData) 
			end
		end
	end

end

function PlanetUILayer:shipListInfo()
	local rn = self:getResourceNode()
	-- 326
		-- if self.list then
	-- 	self.list:clear()
	-- end
	-- for i=1,#self.accompany_army do
		
	-- end
	-- for i,v in ipairs(self.accompany_army) do
	-- 	print(i,v)
	-- end
	for i = #self.accompany_army ,1,-1 do
		for k,v in ipairs(self.accompany_army) do
			if self.accompany_army[i] and self.accompany_army[i][1] and v[1] then
				if self.accompany_army[i][1].army_key == v[1].army_key and k ~= i then
					table.remove(self.accompany_army,k)
				end
			end
		end
	end
	for k,v in ipairs(schedulerSingles) do
		if v ~= nil then
			scheduler:unscheduleScriptEntry(v)
			v = nil
		end
	end
	schedulerSingles = {}
	for k,v in ipairs(tagsTab) do
		if rn:getChildByTag(v) then
			rn:getChildByTag(v):removeFromParent()
		end
	end
	tagsTab = {}
	local res_change_time = {}
	local accompany_armys = {}
	if planetManager:getPlanetUser( ) and Tools.isEmpty(planetManager:getPlanetUser( ).army_list) == false then
		rn:getChildByName('Node_list'):getChildByName('Text_chuzheng'):setString(CONF:getStringValue('To limit')..':'..#planetManager:getPlanetUser( ).army_list..'/'..CONF.BUILDING_1.get(player:getBuildingInfo(1).level).ARMY_NUM)
		local noMoveEnd_army_list = {}
		for k,v in ipairs(planetManager:getPlanetUser( ).army_list) do
			if v.status ~= Status.kMoveEnd then
				table.insert(noMoveEnd_army_list,v)
			end
			if v.status == Status.kAccompany and (v.accompany_army_key and  v.accompany_army_key ~= '') then
				for o,p in ipairs(self.accompany_army) do
					for o1,p1 in pairs(p) do
						 if v.accompany_army_key == p1.army_key then
							local user_name = Tools.split(p1.army_key,'_')[1]
							if planetManager:getInfoListByUserName(user_name) then
								table.insert(accompany_armys,{p,planetManager:getInfoListByUserName(user_name).global_key})
							end
						 end
					end
				end 
			end
		end
		for k,v in ipairs(noMoveEnd_army_list) do
			local node = require("app.ExResInterface"):getInstance():FastLoad("PlanetScene/chuzheng.csb")
			local posX = rn:getChildByName('Node_shipPos'):getPositionX()
			local posY = rn:getChildByName('Node_shipPos'):getPositionY()
			local str = ''
			node:getChildByName('Text'):setString('')
			node:getChildByName('Image_jindu'):setVisible(true)
			node:getChildByName('jdt_bottom'):setVisible(true)
			node:getChildByName('text_jindu'):setVisible(true)
			local progress = require("util.ScaleProgressDelegate"):create(node:getChildByName('Image_jindu'), 137)
			local split = Tools.split(v.element_global_key,"_")
			-- local infos = planetManager:getInfoByNodeGUID( tonumber(split[1]),  tonumber(split[2]) )
			local infos
			if Tools.isEmpty(v.line.move_list) == false then
				infos = planetManager:getUserArmyInfoByPos( v.line.move_list[#v.line.move_list] )
			else
				infos = planetManager:getUserArmyInfo(v.element_global_key)
			end
			if not infos or Tools.isEmpty(infos) then
				if  v.status ~= Status.kMove and v.status ~= Status.kMoveBack and v.status ~= Status.kMoveEnd then
					print('not such planet info ',v.element_global_key)
					print('ship status ',v.status)
					print('ship status_machine ',v.status_machine)
					if Tools.isEmpty(v.line.move_list) == false then
						dump(v.line.move_list[#v.line.move_list])
					end
					break
				end
			end
			res_change_time[k] = 1
			node:getChildByName('Button_state'):setVisible(true)
			node:getChildByName('Button_state'):loadTextures('PlanetScene/ui/jiashu_btn1.png','PlanetScene/ui/jiashu_btn2.png')
			node:getChildByName('Button_state'):addClickEventListener(function()
				if v.status == Status.kMove or v.status == Status.kMoveBack then
					
					local event = cc.EventCustom:new("seeShipUpdated")
					event.guid = v.guid
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 
					
					self:getApp():addView2Top("PlanetScene/PlanetAddSpeedLayer",{army_info = v})
				elseif v.status == Status.kEnlist or v.status == Status.kAccompany then
					self:getApp():pushView("WarScene/WarScene",{from = 'PlanetUILayer'})
				else
                    local function click()
					    local strData = Tools.encode("PlanetRideBackReq", {
						    type = 2,
						    army_guid = {v.guid},
					     })
					    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PLANET_RIDE_BACK_REQ"),strData)
                    end
                    local messageBox = require("util.MessageBox"):getInstance()
			        messageBox:reset(CONF:getStringValue("ishuicheng"), click)
				end
				end)
			local addList = false
			node:getChildByName('Button_1'):addClickEventListener(function()
				if v.status == Status.kMove or v.status == Status.kMoveBack then
					local event = cc.EventCustom:new("seeShipUpdated")
					event.guid = v.guid
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 
				elseif v.status == Status.kEnlist then
					local my_info = planetManager:getUserBaseElementInfo().pos_list
					local event = cc.EventCustom:new("moveToUserRes")
					event.pos = my_info[1]
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 
				elseif v.status == Status.kAccompany then
					local accompany_army
					local base_global_key
					for m,p in ipairs(accompany_armys) do
						for m1,p1 in pairs(p[1]) do
							if p1.army_key == v.accompany_army_key then
								accompany_army = p1
								base_global_key = p[2]
							end
						end
					end
					if accompany_army and base_global_key then
						local infos_other = planetManager:getUserArmyInfo(base_global_key)
						if accompany_army.status == Status.kEnlist then
							local my_info = infos_other.pos_list
							local event = cc.EventCustom:new("moveToUserRes")
							event.pos = my_info[1]
							cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 
						else
							local event = cc.EventCustom:new("seeShipUpdated")
							event.guid = accompany_army.guid
							cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 
						end
					end
				else
					local event = cc.EventCustom:new("moveToUserRes")
					event.pos = infos.pos_list[1]
					cc.Director:getInstance():getEventDispatcher():dispatchEvent(event) 
				end
				end)
			local function needUpdate()
				if not node or type(node) ~= 'userdata' then return end
				local infos
				if Tools.isEmpty(v.line.move_list) == false then
					infos = planetManager:getUserArmyInfoByPos( v.line.move_list[#v.line.move_list] )
				else
					infos = planetManager:getUserArmyInfo(v.element_global_key)
				end
				if  v.status ~= Status.kMove and v.status ~= Status.kMoveBack and v.status ~= Status.kMoveEnd then
					if Tools.isEmpty(infos) then
						return
					end
				end
				if v.status == Status.kMove then
					str = CONF:getStringValue('go')..'('..v.line.move_list[#v.line.move_list].x..','..v.line.move_list[#v.line.move_list].y..')'
					if Tools.isEmpty(v.army_key_list) == false then
						str = CONF:getStringValue('go mass')..'('..v.line.move_list[#v.line.move_list].x..','..v.line.move_list[#v.line.move_list].y..')'
					end
					if (Tools.isEmpty(v.army_key_list) == false and v.status_machine == 10 )  or (v.accompany_army_key ~= '' and v.status_machine == 7 ) then
						str = CONF:getStringValue('participate mass')..'('..v.line.move_list[#v.line.move_list].x..','..v.line.move_list[#v.line.move_list].y..')'
					end
					local time = v.line.need_time - player:getServerTime() + v.line.begin_time - v.line.sub_time
					if time == v.line.need_time then
						tips:tips(CONF:getStringValue("go_go"))
					elseif time == 0 then
						tips:tips(CONF:getStringValue("reach"))
					end
					if time < 0 then time = 0 end
					if time > v.line.need_time then time = v.line.need_time end
					local p = time/v.line.need_time*100
					node:getChildByName('text_jindu'):setString(formatTime(time))
					progress:setPercentage(100-p)
					if time <= 0 then
						-- node:setVisible(false)
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("UserBaseUpdated")
					end
					addList = true
				elseif v.status == Status.kMoveBack then
					str = CONF:getStringValue('back')..'('..v.line.move_list[#v.line.move_list].x..','..v.line.move_list[#v.line.move_list].y..')'
					if (Tools.isEmpty(v.army_key_list) == false and v.status_machine == 10 )  or (v.accompany_army_key ~= '' and v.status_machine == 7 ) then
						str = CONF:getStringValue('mass return')..'('..v.line.move_list[#v.line.move_list].x..','..v.line.move_list[#v.line.move_list].y..')'
					end
					local time = v.line.need_time - player:getServerTime() + v.line.begin_time - v.line.sub_time
					if time == v.line.need_time then
						tips:tips(CONF:getStringValue("back_back"))
					elseif time == 0 then
						tips:tips(CONF:getStringValue("ride_back_success"))
					end
					if time < 0 then time = 0 end
					if time > v.line.need_time then time = v.line.need_time end
					local p = time/v.line.need_time*100
					node:getChildByName('text_jindu'):setString(formatTime(time))
					progress:setPercentage(100-p)
					if time <= 0 then
						-- node:setVisible(false)
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("UserBaseUpdated")
					end
					addList = true
				elseif v.status == Status.kCollect then
					node:getChildByName('Button_state'):loadTextures('PlanetScene/ui/fancheng_btn1.png','PlanetScene/ui/fancheng_btn2.png')
					res_change_time[k] = res_change_time[k] + 1
					str = CONF:getStringValue('caijizhong')
					local collect_speed = infos.res_data.collect_speed
					local res_conf = CONF.PLANET_RES.get(infos.res_data.id)
					if res_conf then
						collect_speed =  player:getValueByTechnologyAdditionGroup(collect_speed, CONF.ETechTarget_1.kWorldRes, res_conf.TYPE, CONF.ETechTarget_3_Res.kCollect)
					end

					local resTotal = infos.res_data.cur_storage 
					local speed =  collect_speed
					local begin_time = infos.res_data.begin_time
					if infos.type == 6 then
						local cfg = CONF.PLANET_RES.get(infos.city_res_data.id)
						for k,v in ipairs(infos.city_res_data.user_list) do
							if v.user_name == player:getName() then

								local collect_speed2 = v.collect_speed
								local res_conf = CONF.PLANET_RES.get(v.id)
								if res_conf then
									collect_speed2 =  player:getValueByTechnologyAdditionGroup(collect_speed2, CONF.ETechTarget_1.kWorldRes, res_conf.TYPE, CONF.ETechTarget_3_Res.kCollect)
								end

								speed = collect_speed2
								begin_time = v.begin_time
								break
							end
						end
						resTotal = infos.city_res_data.cur_storage
					end
                    -- 队伍载重
                    local shiplist_load = 0
                    if player:getPlayerPlanetUser() and player:getPlayerPlanetUser().army_list then
                        local shiplist = {}
                        for k,v in ipairs(player:getPlayerPlanetUser().army_list) do
                            if v.guid == infos.res_data.army_guid then
                               shiplist_load = Tools.GetAllShipLoad(v.ship_list)
                            end
                        end
                    end
                    local Mostload = math.min(shiplist_load,resTotal)

					local totaltime = Mostload/speed
					local time = totaltime - player:getServerTime() + begin_time
					if time == totaltime then
						tips:tips(CONF:getStringValue("collect_start"))
					elseif time == 0 then
						tips:tips(CONF:getStringValue("collect_end"))
					end
					if time < 0 then time = 0 end
					if time > totaltime then time = totaltime end
					if res_change_time[k] > 5 then
						node:getChildByName('text_jindu'):setString(formatTime(time))
						if res_change_time[k] > 10 then
							res_change_time[k] = 1
						end
					else
						node:getChildByName('text_jindu'):setString(math.ceil(time*speed)..'/'..Mostload)
					end
					if time <= 0 then
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("UserBaseUpdated")
						local event = cc.EventCustom:new("nodeUpdated")
						event.node_id_list = {}
						cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
					end
					progress:setPercentage(100-time/totaltime*100)
					addList = true
				elseif v.status == Status.kFishing then
					node:getChildByName('Button_state'):loadTextures('PlanetScene/ui/fancheng_btn1.png','PlanetScene/ui/fancheng_btn2.png')
					str = CONF:getStringValue('salvage_centre')
					local time = infos.ruins_data.need_time + infos.ruins_data.begin_time - player:getServerTime()
					if time == infos.ruins_data.need_time then
						tips:tips(CONF:getStringValue("salvage_start"))
					elseif time == 0 then
						tips:tips(CONF:getStringValue("salvage_end"))
					end
					if time < 0 then time = 0 end
					if time > infos.ruins_data.need_time then time = infos.ruins_data.need_time end
					local p = time/infos.ruins_data.need_time*100
					node:getChildByName('text_jindu'):setString(formatTime(time))
					progress:setPercentage(100-p)
					if time <= 0 then
						-- node:setVisible(false)
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("UserBaseUpdated")
					end
					addList = true
				elseif v.status == Status.kGuarde then
					if planetManager:getPlanetUser( ).base_global_key == v.element_global_key then
						node:getChildByName('Button_state'):setVisible(false)
					end
					node:getChildByName('Button_state'):loadTextures('PlanetScene/ui/fancheng_btn1.png','PlanetScene/ui/fancheng_btn2.png')
					if planetManager:getPlanetUser( ).base_global_key ~= v.element_global_key then
						str = CONF:getStringValue('station_centre')..'('..infos.pos_list[1].x..','..infos.pos_list[1].y..')'
					else
						str = CONF:getStringValue('defense in')..'('..infos.pos_list[1].x..','..infos.pos_list[1].y..')'
					end
					node:getChildByName('Image_jindu'):setVisible(false)
					node:getChildByName('jdt_bottom'):setVisible(false)
					node:getChildByName('text_jindu'):setVisible(false)
					addList = true
				elseif v.status == Status.kEnlist then
					node:getChildByName('Button_state'):loadTextures('PlanetScene/ui/chakan.png','PlanetScene/ui/chakanliang.png')
					str = CONF:getStringValue('mass count down')
					local time = v.mass_time - player:getServerTime() + v.begin_time
					node:getChildByName('text_jindu'):setString(formatTime(time))
					local p = time/v.mass_time*100
					progress:setPercentage(100-p)
					if time <= 0 then
						-- node:setVisible(false)
						cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("UserBaseUpdated")
					end
					addList = true
				elseif v.status == Status.kAccompany then
					node:getChildByName('Button_state'):loadTextures('PlanetScene/ui/chakan.png','PlanetScene/ui/chakanliang.png')
					local accompany_army
					node:getChildByName('Image_jindu'):setVisible(false)
					node:getChildByName('jdt_bottom'):setVisible(false)
					node:getChildByName('text_jindu'):setVisible(false)
					for m,p in ipairs(accompany_armys) do
						for m1,p1 in pairs(p[1]) do
							if p1.army_key == v.accompany_army_key then
								accompany_army = p1
							end
						end
					end
					str = CONF:getStringValue('mass in')
					node:getChildByName('text_jindu'):setString('00:00:00')
					if Tools.isEmpty(accompany_army) == false then
						local time = accompany_army.mass_time - player:getServerTime() + accompany_army.begin_time
						node:getChildByName('text_jindu'):setString(formatTime(time))
						local p = time/accompany_army.mass_time*100
						progress:setPercentage(100-p)
						if time <= 0 then
							cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("UserBaseUpdated")
						else
							node:getChildByName('Image_jindu'):setVisible(true)
							node:getChildByName('jdt_bottom'):setVisible(true)
							node:getChildByName('text_jindu'):setVisible(true)
						end
						if accompany_army.status == Status.kMove then
							str = CONF:getStringValue('go mass')..'('..accompany_army.line.move_list[#accompany_army.line.move_list].x..','..accompany_army.line.move_list[#accompany_army.line.move_list].y..')'
							local time = accompany_army.line.need_time - player:getServerTime() + accompany_army.line.begin_time
							if time < 0 then time = 0 end
							if time > accompany_army.line.need_time then time = accompany_army.line.need_time end
							local p = time/accompany_army.line.need_time*100
							node:getChildByName('text_jindu'):setString(formatTime(time))
							progress:setPercentage(100-p)
							node:getChildByName('Image_jindu'):setVisible(true)
							node:getChildByName('jdt_bottom'):setVisible(true)
							node:getChildByName('text_jindu'):setVisible(true)
							if time <= 0 then
								-- node:setVisible(false)
								cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("UserBaseUpdated")
							end
						end
					end
					addList = true
				end	
			end
			needUpdate()
			if schedulerSingles[#schedulerSingles + 1] == nil then
				schedulerSingles[#schedulerSingles + 1] = scheduler:scheduleScriptFunc(needUpdate,1,false)
			end
			node:getChildByName('Text'):setString(str)
			-- self.list:addElement(node)
			if addList == true then
				node:setTag(1000+k)
				table.insert(tagsTab,1000+k)
				rn:addChild(node)
			end
			if rn:getChildByTag(1000+k-1) then
				posX = rn:getChildByTag(1000+k-1):getPositionX()
				posY = rn:getChildByTag(1000+k-1):getPositionY() - 45
			end
			node:setPosition(posX,posY)
			if node:isVisible() then
				node:setVisible(rn:getChildByName('Node_list'):getChildByName('Image_16'):isVisible())
			end
			local width = 45
			-- if #tagsTab < 3 then
			-- 	width = 60
			-- else
			-- 	width = 30
			-- end
			rn:getChildByName('Node_list'):getChildByName('Image_16'):setContentSize(cc.size(self.size.width,80 + #tagsTab*width))
		end
		local list = rn:getChildByName("Node_list")
		list:getChildByName("line1"):setContentSize(1,list:getChildByName("Image_16"):getContentSize().height-list:getChildByName("Image_15"):getContentSize().height)
		list:getChildByName("line2"):setPositionY(-list:getChildByName("Image_16"):getContentSize().height)
		if #tagsTab == 0 then
			rn:getChildByName('Node_list'):setVisible(false)
		else
			rn:getChildByName('Node_list'):setVisible(true)
		end
	end
end

function PlanetUILayer:updateChat()
	local rn = self:getResourceNode()
	rn:getChildByName("chat"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		layer:setName("chatLayer")
		self:addChild(layer)
		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
	end)
	rn:getChildByName('chat_img'):addClickEventListener(function()
		playEffectSound("sound/system/click.mp3")
		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		layer:setName("chatLayer")
		self:addChild(layer)

		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
	end)
	self.show_di_text = false
	local strData = Tools.encode("GetChatLogReq", {
			chat_id = 0,
		})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)
	local function recvMsg( )
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_RESP") then

			local proto = Tools.decode("GetChatLogResp",strData)
			print("city GetChatLogResp result",proto.result)

			-- gl:releaseLoading()

			if proto.result < 0 then
				print("error :",proto.result)
			else
				
				if not self.show_di_text then
					self.show_di_text = true

					local time = 0
					local str = ""
					local tt 

					for i,v in ipairs(proto.log_list) do
						if v.stamp > time and v.user_name ~= "0" and not player:isBlack(v.user_name) then
							time = v.stamp

							local strc = ""
							if v.group_name ~= "" then
								strc = string.format("[%s]%s:", v.group_name, v.nickname)
							else
								strc = string.format("%s:", v.nickname)
							end
							str = handsomeSubString(strc..v.chat, CONF.PARAM.get("chat number").PARAM)
							tt = {user_name = v.user_name, chat = v.chat, time = v.stamp}

						end
					end

					if player:getLastChat() == nil then
						rn:getChildByName("chat"):getChildByName("point"):setVisible(true)
					else
						if player:getLastChat().user_name == tt.user_name and player:getLastChat().chat == tt.chat and player:getLastChat().time == tt.time then
							rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
						else
							rn:getChildByName("chat"):getChildByName("point"):setVisible(true)
						end
					end

					rn:getChildByName("di_text"):setString(str)

				end
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE", "CMD_ADD_STRENGTH_RESP") then
			local proto = Tools.decode("AddStrengthResp",strData)
			if proto.result == 'OK' then
				self:setStrengthPercent( )
			end
		end
	end
	self.chatRecvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.chatRecvlistener_, FixedPriority.kNormal)

	self.seeChatListener_ = cc.EventListenerCustom:create("seeChat", function ()
		rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.seeChatListener_, FixedPriority.kNormal)
	self.worldListener_ = cc.EventListenerCustom:create("worldMsg", function (event)
		playEffectSound("sound/system/message_update.mp3")
		local table_ = {stamp = player:getServerTime(), chat = event.chat.msg, nickname = event.chat.sender.nickname, user_name = event.chat.sender.uid, group_name = event.chat.sender.group_nickname}
		
		local strc = ""
		if event.chat.sender.group_nickname ~= "" then
			strc = string.format("[%s]%s:", event.chat.sender.group_nickname, event.chat.sender.nickname)
		else
			strc = string.format("%s:", event.chat.sender.nickname)
		end
		local chat = handsomeSubString(strc..event.chat.msg, CONF.PARAM.get("chat number").PARAM)
		rn:getChildByName("di_text"):setString(chat)

		if self:getChildByName("chatLayer") then
			rn:getChildByName("chat"):getChildByName("point"):setVisible(false)
		else
			rn:getChildByName("chat"):getChildByName("point"):setVisible(true)
		end

	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.worldListener_, FixedPriority.kNormal)
end

function PlanetUILayer:setStrengthPercent( )

	local rn = self:getResourceNode()

	local you = rn:getChildByName('AllMoneyAndEnergy')

	local strenthBar = you:getChildByName("progress")
	self.strengthDelegate_ = require("util.ScaleProgressDelegate"):create(strenthBar, 100)

	you:getChildByName("ev_num"):setString(player:getStrength().."/"..player:getMaxStrength())

	local p = player:getStrength()/player:getMaxStrength() * 100
	if p > 100 then
		p = 100
	end

	self.strengthDelegate_:setPercentage(p)
end

function PlanetUILayer:getFreshRES()
	local rn = self:getResourceNode()
	if rn:getChildByName('AllMoneyAndEnergy') ~= nil then
		for i=1, 4 do
			if rn:getChildByName('AllMoneyAndEnergy'):getChildByName(string.format("res_text_%d",i)) then
				rn:getChildByName('AllMoneyAndEnergy'):getChildByName(string.format("res_text_%d",i)):setString(formatRes(player:getResByIndex(i)))
			end
		end
		rn:getChildByName("AllMoneyAndEnergy"):getChildByName("res_touch"):addClickEventListener(function()
			playEffectSound("sound/system/click.mp3")
			self:getApp():addView2Top("CityScene/MoneyInfoLayer")
			end)
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName('money_add'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

			rechargeNode:init(self:getParent(), {index = 1})
			self:addChild(rechargeNode)
		end)
		self:setStrengthPercent( )
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName('strength_add'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			self:getApp():addView2Top("CityScene/AddStrenthLayer")
		end)
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName('touch2'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			local rechargeNode = require("app.views.CityScene.RechargeNode"):create()
			rechargeNode:init(self:getParent(), {index = 1})
			self:addChild(rechargeNode)
		end)
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName('touch1'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			self:getApp():addView2Top("CityScene/AddStrenthLayer")
		end)

	end
	local eventDispatcher = self:getEventDispatcher()
	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		for i=1, 4 do
			if rn:getChildByName('AllMoneyAndEnergy'):getChildByName(string.format("res_text_%d",i)) then
				rn:getChildByName('AllMoneyAndEnergy'):getChildByName(string.format("res_text_%d",i)):setString(formatRes(player:getResByIndex(i)))
			end
		end
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	self.strengthListener_ = cc.EventListenerCustom:create("StrengthUpdated", function ()
		self:setStrengthPercent( )
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)
	eventDispatcher:addEventListenerWithFixedPriority(self.strengthListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		rn:getChildByName('AllMoneyAndEnergy'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)
end

function PlanetUILayer:onExitTransitionStart()

	printInfo("PlanetUILayer:onExitTransitionStart()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.chatRecvlistener_)
	eventDispatcher:removeEventListener(self.seeChatListener_)
	eventDispatcher:removeEventListener(self.resListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.strengthListener_)
	eventDispatcher:removeEventListener(self.planetUserListener_)
	eventDispatcher:removeEventListener(self.infoListListener_)
	eventDispatcher:removeEventListener(self.worldListener_)
	eventDispatcher:removeEventListener(self.planetCloseMenuListener_)
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.groupListener_)
	eventDispatcher:removeEventListener(self.levelupListener_)
	eventDispatcher:removeEventListener(self.guideListener_)

	for k,v in ipairs(schedulerSingles) do
		if v ~= nil then
			scheduler:unscheduleScriptEntry(v)
			v = nil
		end
	end
	schedulerSingles = {}

	if schedulerWarning ~= nil then
		scheduler:unscheduleScriptEntry(schedulerWarning)
		schedulerWarning = nil
	end
	if schedulerEntry_Adventure ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry_Adventure)
		schedulerEntry_Adventure = nil
	end
end

return PlanetUILayer