local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local BlueprintScene = class("BlueprintScene", cc.load("mvc").ViewBase)

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

BlueprintScene.RESOURCE_FILENAME = "BlueprintScene/BlueprintScene.csb"

BlueprintScene.NEED_ADJUST_POSITION = true

BlueprintScene.mode_ = 1

BlueprintScene.selectedShip1 = nil
BlueprintScene.selectedShip2 = nil
BlueprintScene.selectedShip3 = nil
BlueprintScene.selectedShip4 = nil

BlueprintScene.schedulerSingles = {}
BlueprintScene.schedulerInfo = nil

BlueprintScene.closeBlueprint_list = {}
BlueprintScene.openBlueprint_list = {}
BlueprintScene.blueprint_list = {}
BlueprintScene.playership_Idlist = {}

BlueprintScene.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="onBtnClick"}}},
}

BlueprintScene.lagHelper = require("util.ExLagHelper"):getInstance()
BlueprintScene.IS_SCENE_TRANSFER_EFFECT = false

function BlueprintScene:onCreate(data)
	self.data_ = data
end

function BlueprintScene:onBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			-- self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})

			if( self.IS_SCENE_TRANSFER_EFFECT ) then
				self.lagHelper:BeginTransferEffect("BlueprintScene/BlueprintScene")
			else
				self:getApp():popView()
			end
		end
	end
end

function BlueprintScene:sortList()
	table.sort(self.blueprint_list,function(a,b)
		if a.isOpen == b.isOpen then
			if a.startTime == b.startTime then
				if a.openLevel == b.openLevel then
					return a.id > b.id
				else
					return a.openLevel < b.openLevel
				end
			else
				return a.startTime > b.startTime
			end
		else
			return a.isOpen > b.isOpen
		end
		end)
end

function BlueprintScene:getPieceList()
	local building3_level = player:getBuildingInfo(CONF.EBuilding.kShipDevelop).level
	local produce_list = player:getBlueprint_list()
	self.blueprint_list = {}
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
					table.insert(self.blueprint_list,list)
				else
					table.insert(self.blueprint_list,list) 
				end
			end
		end
	end
	self:sortList()
end

function BlueprintScene:setPointVisible()
	local rn = self:getResourceNode()
	for i=1,4 do
		rn:getChildByName("btn_all"):getChildByName("node_"..i):getChildByName("point"):setVisible(false)
		rn:getChildByName("sfx"..i):setVisible(false)
	end
	local type1 = {}
	local type2 = {}
	local type3 = {}
	local type4 = {}
	for i,v in ipairs(self.blueprint_list) do
		if v.type == 1 then
			table.insert(type1,v)
		elseif v.type == 2 then
			table.insert(type2,v)
		elseif v.type == 3 then
			table.insert(type3,v)
		elseif v.type == 4 then
			table.insert(type4,v)
		end
	end
	local function func(v)
		if v.isOpen == 1 then
			if v.startTime ~= 0 then
				rn:getChildByName("sfx"..v.type):setVisible(true)
				rn:getChildByName("btn_all"):getChildByName("node_"..v.type):getChildByName("point"):setVisible(true)
				rn:getChildByName("btn_all"):getChildByName("node_"..v.type):getChildByName("point"):setTexture("Common/ui/spherical_red.png")
				local cfg_blueprint = CONF.BLUEPRINT.get(v.id)
				local time =  cfg_blueprint.TIME + v.startTime - player:getServerTime()
				if time <= 0 then
					rn:getChildByName("btn_all"):getChildByName("node_"..v.type):getChildByName("point"):setTexture("Common/ui/spherical_green.png")
				end
			end
		end
	end
	for k,v in ipairs(type1) do
		func(v)
	end
	for k,v in ipairs(type2) do
		func(v)
	end
	for k,v in ipairs(type3) do
		func(v)
	end
	for k,v in ipairs(type4) do
		func(v)
	end
end

function BlueprintScene:onEnterTransitionFinish()
	guideManager:checkInterface(CONF.EInterface.kShipFactory)
    self.playership_Idlist = {}
    local shipList = player:getShipList()
    for k,v in ipairs(shipList) do
        table.insert(self.playership_Idlist,v.id)
    end

	if self.data_ and self.data_.mode_ then
		self.mode_ = self.data_.mode_
	end
	self.schedulerSingles = {}
	local rn = self:getResourceNode()
	self:getPieceList()
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list") ,cc.size(15,15), cc.size(195 ,130)) 
	self.svd_:getScrollView():setScrollBarEnabled(false)
	if guideManager:getGuideType() then
   		rn:getChildByName("list"):setTouchEnabled(false)
    end
    for i=1,4 do
    	rn:getChildByName("sfx"..i):setVisible(false)
    	animManager:runAnimByCSB(rn:getChildByName("sfx"..i),"BlueprintScene/sfx/saoguang/saoguang.csb",  "1")
    end
	local type1 = {}
	local type2 = {}
	local type3 = {}
	local type4 = {}
	for i,v in ipairs(self.blueprint_list) do
		if v.type == 1 then
			table.insert(type1,v)
		elseif v.type == 2 then
			table.insert(type2,v)
		elseif v.type == 3 then
			table.insert(type3,v)
		elseif v.type == 4 then
			table.insert(type4,v)
		end
	end
	if not self.selectedShip1 then
		self.selectedShip1 = type1[1]
	end
	if not self.selectedShip2 then
		self.selectedShip2 = type2[1]
	end
	if not self.selectedShip3 then
		self.selectedShip3 = type3[1]
	end
	if not self.selectedShip4 then
		self.selectedShip4 = type4[1]
	end

	self:changeMode()
	self:setPointVisible()
	local label = {"attack","defense","control","treat"}
	rn:getChildByName("title"):setString(CONF:getStringValue("BuildingName_3"))
	-- rn:getChildByName("Image_22_0"):setPositionX(rn:getChildByName("title"):getPositionX()+rn:getChildByName("title"):getContentSize().width+5)
	for i=1,4 do
		rn:getChildByName("btn_all"):getChildByName("node_"..i):getChildByName("text"):setString(CONF:getStringValue(label[i]))
		rn:getChildByName("btn_all"):getChildByName("node_"..i):getChildByName("text_selected"):setString(CONF:getStringValue(label[i]))
		rn:getChildByName("btn_all"):getChildByName("node_"..i):getChildByName("btn"):addClickEventListener(function()
			playEffectSound("sound/system/tab.mp3")
			guideManager:checkInterface(CONF.EInterface.kShipFactory)
			self.mode_ = i
			self:changeMode()
		end)
	end
	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE", "CMD_BLUEPRINT_DEVELOPE_RESP") then 
			local proto = Tools.decode("BlueprintDevelopeResp",strData)
			gl:releaseLoading()
			print("BlueprintDevelopeResp result = ",proto.result)
			if proto.result ~= 0 then

			else

				if Tools.isEmpty(proto.user_sync.user_info.blueprint_list) then 
					player:setBlueprint_list(nil)
				end
				if proto.type == 2 then
					if guideManager:getGuideType() then
						self:getApp():removeTopView()
						if guideManager:getSelfGuideID()>94 then
							guideManager:addGuideStep(96)
						elseif guideManager:getSelfGuideID()>34 then
							guideManager:addGuideStep(91)
						else
							guideManager:addGuideStep(34)
						end
					end


					local function func( ... )
						local guide 
						if guideManager:getSelfGuideID() ~= 0 then
							guide = guideManager:getSelfGuideID()
						else
							guide = player:getGuideStep()
						end
						local teshuID = 1
						if guide > 34 then
							teshuID = 6
						end

						if guide == guideManager:getTeshuGuideId(teshuID) then
							
							guideManager:createGuideLayer(guide+1)
						end
					
					end
					local items = {}
					for i=1,proto.num do
						local t = {}
						t.id = proto.blueprint_id
						t.num = 1
						table.insert(items,t)
					end

					local node = require("util.RewardNode"):createGettedNodeWithList(items, func,nil,proto.crit)
					tipsAction(node)
					node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(node)
				elseif proto.type == 1 then
					if guideManager:getGuideType() then
						guideManager:doEvent("recv")
					end
				end
				self:changeMode()
				self:setPointVisible()
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_BUILDING_UPDATE_RESP") then
			local proto = Tools.decode("BuildingUpdateResp",strData)
			if proto.result == 0 and proto.index == 3 then
				self:changeMode()
				self:setPointVisible()
			end
		end
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local   eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	self:getFreshRES()

	
	-- WJJ 20180720
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Yanfa(self)

end

function BlueprintScene:creatPieceNode(pieceInfo)

	local node = require("app.ExResInterface"):getInstance():FastLoad("BlueprintScene/BlueprintNode.csb")
	animManager:runAnimByCSB(node:getChildByName("Node_shalou"), "BlueprintScene/sfx/shalou/shalou.csb", "1")
	node:setTag(pieceInfo.id)
	local cfg_blueprint = CONF.BLUEPRINT.get(pieceInfo.id)
	local cfg_item = CONF.ITEM.get(pieceInfo.id)
	local cfg_ship = CONF.AIRSHIP.get(pieceInfo.shipId)
	node:getChildByName("Image_black"):setVisible(false)
    node:getChildByName("Png_have"):setVisible(false)
	--node:getChildByName("Image_producing"):getChildByName("text"):setVisible(false)
	--node:getChildByName("Image_producing"):getChildByName("text"):setString("Lv."..pieceInfo.openLevel)
	--node:getChildByName("Node_shalou"):setVisible(false)
	if pieceInfo.isOpen == 0 then
		--node:getChildByName("Image_producing"):loadTexture("BuildingUpgradeScene/building/b3.png")
		--node:getChildByName("Image_producing"):getChildByName("text"):setVisible(true)
	else
		if pieceInfo.startTime == 0 then
			--node:getChildByName("Image_producing"):loadTexture("BlueprintScene/ui/small_icon.png")
		else
			--node:getChildByName("Image_producing"):loadTexture("Common/newUI/shalou.png")
			node:getChildByName("Node_shalou"):setVisible(true)
		end
	end
	local bg_show = pieceInfo.isOpen == 0
	local canProduce = true
	for k,v in ipairs(cfg_blueprint.MATERIAL_ID) do
		local haveNum = player:getItemNumByID(v)
		if haveNum < cfg_blueprint.MATERIAL_NUM[k] then
			canProduce = false
		end
	end
	local time =  cfg_blueprint.TIME + pieceInfo.startTime - player:getServerTime()
	if time <= 0 then
		node:getChildByName("Node_shalou"):setVisible(false)
	end
	if not bg_show and pieceInfo.startTime ~= 0 then
		if time <= 0 then
			bg_show = true
		end
	end
	if pieceInfo.isOpen == 1 then
        if TableFindValue(self.playership_Idlist,pieceInfo.shipId) ~= 0 then
            node:getChildByName("Png_have"):setVisible(true)
        end
		--node:getChildByName("Image_producing"):setVisible(canProduce)
	end
	node:getChildByName("Image_black"):setVisible(bg_show)
	node:getChildByName("ship_type"):setTexture(string.format("ShipType/%d.png", cfg_blueprint.TYPE))
	node:getChildByName("name"):setString(CONF:getStringValue(cfg_item.NAME_ID))
	node:getChildByName("Image_bg"):loadTexture("BlueprintScene/ui/kfgc_k_" .. cfg_item.QUALITY .. ".png")
	node:getChildByName("ship_icon"):setTexture("ShipImage/"..cfg_ship.ICON_ID..".png")
	node:getChildByName("text_click"):setVisible(false)
	node:getChildByName("Image_bg"):setTag(pieceInfo.id)

	node:getChildByName("type"):setVisible(true)
	node:getChildByName("type"):setTexture("ShipQuality/quality_"..cfg_ship.QUALITY..".png")

	local can_sch = false
	if pieceInfo.isOpen == 1 and pieceInfo.startTime > 0 then
		local time = cfg_blueprint.TIME + pieceInfo.startTime - player:getServerTime()
		if time > 0 or pieceInfo.startTime == 0 then
			can_sch = true
		end
	end
	local function update()
		if pieceInfo.isOpen == 1 and pieceInfo.startTime > 0 then		
			local time = cfg_blueprint.TIME + pieceInfo.startTime - player:getServerTime()
			if time <= 0 and pieceInfo.startTime ~= 0 then
				--node:getChildByName("Image_producing"):setVisible(false)
				node:getChildByName("Node_shalou"):setVisible(false)
				if self.schedulerSingles[pieceInfo.id] then
					scheduler:unscheduleScriptEntry(self.schedulerSingles[pieceInfo.id])
					self.schedulerSingles[pieceInfo.id] = nil
				end
				node:getChildByName('text_click'):setVisible(true)
				node:getChildByName('text_click'):setString(CONF:getStringValue("click_get"))
				node:getChildByName("Image_black"):setVisible(true)
				if can_sch then
					local node = require("util.UpgradeOverNode"):createNode(CONF:getStringValue("exploit complete"))
					node:setPosition(cc.exports.VisibleRect:center())
					self:addChild(node)
				end
			else
				node:getChildByName("Node_shalou"):setVisible(true)
				--node:getChildByName("Image_producing"):setVisible(false)
			end
		end
		self:setPointVisible()
	end
	update()
	if can_sch and not self.schedulerSingles[pieceInfo.id] then
		self.schedulerSingles[pieceInfo.id] = scheduler:scheduleScriptFunc(update,1,false)
	end
	return node
end

function BlueprintScene:refreshInfo(v)
	local cfg_blueprint = CONF.BLUEPRINT.get(v.id)
	local cfg_ship = CONF.AIRSHIP.get(v.shipId)
	local time =  cfg_blueprint.TIME + v.startTime - player:getServerTime()
	local right = self:getResourceNode():getChildByName("right")
	right:getChildByName("type_icon"):setTexture(string.format("ShipType/%d.png", cfg_blueprint.TYPE))
	right:getChildByName("piece_name"):setString(CONF:getStringValue(CONF.ITEM.get(v.id).NAME_ID))
	right:getChildByName("piece_num"):setString(CONF:getStringValue("have")..":"..player:getItemNumByID(v.id))
	right:getChildByName("piece_bg"):loadTexture("ShipsScene/ui/ui_avatar_"..CONF.ITEM.get(v.id).QUALITY..".png")
	right:getChildByName("piece_icon"):setTexture("ItemIcon/"..CONF.ITEM.get(v.id).ICON_ID..".png")
	local strNum = CONF.AIRSHIP.get(CONF.ITEM.get(v.id).SHIPID).BLUEPRINT_NUM[1]
	local strName = CONF:getStringValue(CONF.AIRSHIP.get(CONF.ITEM.get(v.id).SHIPID).NAME_ID)
	local str = string.gsub(string.gsub(CONF:getStringValue(CONF.ITEM.get(v.id).MEMO_ID),"%%d",strNum),"%%h",strName)
	if right:getChildByName("richTxt") then
		right:getChildByName("richTxt"):removeFromParent()
	end
	local richTxt = ccui.RichText:create();
	local richEleTxt1 = ccui.RichElementText:create(1, {r=255,g=255,b=255}, 255,str, s_default_font, 19);
	--local richEleName = ccui.RichElementText:create(1, {r=255,g=0,b=0}, 255, strName, s_default_font, 19);
	--local richEleTxt2 = ccui.RichElementText:create(1, {r=255,g=255,b=255}, 255,str, s_default_font, 19);
	--local richEleTxt3 = ccui.RichElementText:create(1, {r=255,g=0,b=0}, 255, strName, s_default_font, 19);
	--right:getChildByName("piece_des"):setString(str)
	right:getChildByName("piece_des"):setVisible(false);
	local size = right:getChildByName("piece_des"):getContentSize();
	richTxt:setContentSize(size.width, size.height);
	richTxt:setAnchorPoint(0,1);
	richTxt:setPosition(right:getChildByName("piece_des"):getPosition());
	richTxt:pushBackElement(richEleTxt1);
	--richTxt:pushBackElement(richEleName);
	richTxt:ignoreContentAdaptWithSize(false);
	richTxt:formatText();
	right:addChild(richTxt);
	richTxt:setName("richTxt")
	richTxt:setTag(1001);

    local function showjumplayer(jumpTab)
        if Tools.isEmpty(jumpTab) == false and not self:getChildByName("JumpChoseLayer") then
			jumpTab.scene = "BlueprintScene"
			local center = cc.exports.VisibleRect:center()
			local layer = app:createView("ShipsScene/JumpChoseLayer",jumpTab)
			layer:setName("JumpChoseLayer")
			tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
			self:addChild(layer)
		end
    end
	right:getChildByName("btn"):setVisible(false)
	right:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("exploit"))
	local node1 = right:getChildByName("node1")
	local node2 = right:getChildByName("node2")
	local node3 = right:getChildByName("node3")
	node1:setVisible(false)
	node2:setVisible(false)
	node3:setVisible(false)
	node2:getChildByName("btn1"):getChildByName("text1"):setString(CONF:getStringValue("expedite"))
    local needmoney = Tools.getSpeedShipNeedMoney(cfg_blueprint.TIME + v.startTime - player:getServerTime())
	node2:getChildByName("btn1"):getChildByName("text2"):setString(needmoney)
	node2:getChildByName("btn1"):getChildByName("icon"):setPositionX(node2:getChildByName("btn1"):getChildByName("text1"):getPositionX()+node2:getChildByName("btn1"):getChildByName("text1"):getContentSize().width)
	node2:getChildByName("btn1"):getChildByName("text2"):setPositionX(node2:getChildByName("btn1"):getChildByName("icon"):getPositionX()+node2:getChildByName("btn1"):getChildByName("icon"):getContentSize().width)
	node2:getChildByName("btn1"):addClickEventListener(function()
        if player:getMoney() < needmoney then
        	local function func()
				local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

				rechargeNode:init(self, {index = 1})
				self:addChild(rechargeNode)
			end

			local messageBox = require("util.MessageBox"):getInstance()
			messageBox:reset(CONF.STRING.get("no_credit_message").VALUE, func)
        else
		    if v.startTime ~= 0 then
			    local strData = Tools.encode("BlueprintDevelopeReq", {   
				    type = 3,
				    blueprint_id = v.id,
			    })
			    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BLUEPRINT_DEVELOPE_REQ"),strData)
			    gl:retainLoading()
		    end
        end
		end)
	node2:getChildByName("btn_2"):getChildByName("text"):setString(CONF:getStringValue("cancel"))
	node2:getChildByName("btn_2"):addClickEventListener(function()
		if v.startTime ~= 0 then
			local strData = Tools.encode("BlueprintDevelopeReq", {   
				type = 4,
				blueprint_id = v.id,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BLUEPRINT_DEVELOPE_REQ"),strData)
			gl:retainLoading()
		end
		end)
	if v.isOpen == 0 then
		node3:setVisible(true)
		node3:getChildByName("text1"):setString(CONF:getStringValue("BuildingName_3"))
		node3:getChildByName("text2"):setString("Lv."..v.openLevel)
		node3:getChildByName("text3"):setString(CONF:getStringValue("deblocking blueprint"))
		node3:getChildByName("text2"):setPositionX(node3:getChildByName("text1"):getPositionX()+node3:getChildByName("text1"):getContentSize().width)
		node3:getChildByName("text3"):setPositionX(node3:getChildByName("text2"):getPositionX()+node3:getChildByName("text2"):getContentSize().width)
	else
		if v.startTime == 0 then
			node1:setVisible(true)
			node1:getChildByName("cost"):setString(CONF:getStringValue("Cost")..":")
			node1:getChildByName("need_time"):setString(CONF:getStringValue("need time")..":"..formatTime(cfg_blueprint.TIME))
			local res1 = node1:getChildByName("res1")
			local res2 = node1:getChildByName("res2")
			local res3 = node1:getChildByName("res3")
			local res4 = node1:getChildByName("res4")
			for k,v in ipairs(cfg_blueprint.MATERIAL_ID) do
				local item = CONF.ITEM.get(v)
				if node1:getChildByName("res"..k) then
					node1:getChildByName("res"..k):getChildByName("name"):setString(CONF:getStringValue(item.NAME_ID))
					node1:getChildByName("res"..k):loadTexture("ItemIcon/"..item.ICON_ID..".png")
					-- node1:getChildByName("res"..k):getChildByName("have"):setString(formatRes(player:getItemNumByID(v)))
					node1:getChildByName("res"..k):getChildByName("have"):setString(cfg_blueprint.MATERIAL_NUM[k])
					node1:getChildByName("res"..k):getChildByName("need"):setString("/"..formatRes(cfg_blueprint.MATERIAL_NUM[k]))
					if cfg_blueprint.MATERIAL_NUM[k] <= player:getItemNumByID(v) then
						node1:getChildByName("res"..k):getChildByName("have"):setTextColor(cc.c4b(51,231,51,255))
						-- node1:getChildByName("res"..k):getChildByName("have"):enableShadow(cc.c4b(51,231,51,255), cc.size(0.2,0.2))
					else
						node1:getChildByName("res"..k):getChildByName("have"):setTextColor(cc.c4b(233,50,59,255))
						-- node1:getChildByName("res"..k):getChildByName("have"):enableShadow(cc.c4b(233,50,59,255), cc.size(0.2,0.2))
					end
					node1:getChildByName("res"..k):getChildByName("have"):setPositionX(node1:getChildByName("res"..k):getChildByName("name"):getPositionX()+node1:getChildByName("res"..k):getChildByName("name"):getContentSize().width+8)
					node1:getChildByName("res"..k):getChildByName("need"):setPositionX(node1:getChildByName("res"..k):getChildByName("have"):getPositionX()+node1:getChildByName("res"..k):getChildByName("have"):getContentSize().width)
				end
			end
			right:getChildByName("btn"):setVisible(true)
			right:getChildByName("btn"):addClickEventListener(function()
				local vipnum = CONF.VIP.get(player:getVipLevel()).ADD_RAD_QUEUE

				if #player:getBlueprint_list() >= CONF.BUILDING_3.get(player:getBuildingInfo(CONF.EBuilding.kShipDevelop).level).QUEUE+vipnum then
					tips:tips(CONF:getStringValue("airship blueprint queue"))
					return
				end
				for i=1,4 do
					if player:getItemNumByID(cfg_blueprint.MATERIAL_ID[i]) < cfg_blueprint.MATERIAL_NUM[i] then
						tips:tips(CONF:getStringValue("Material_not_enought"))
                        local jumpTab = {}
                        local cfg_item = CONF.ITEM.get(cfg_blueprint.MATERIAL_ID[i])
                        if cfg_item and cfg_item.JUMP then
						    table.insert(jumpTab,cfg_item.JUMP)
					    end
                        showjumplayer(jumpTab)
						return
					end
				end
				local strData = Tools.encode("BlueprintDevelopeReq", {   
					type = 1,
					blueprint_id = v.id,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BLUEPRINT_DEVELOPE_REQ"),strData)
				gl:retainLoading()
				end)
		else
			if time > 0 then
				local function update()
					node2:getChildByName("btn1"):getChildByName("text2"):setString(Tools.getSpeedShipNeedMoney(cfg_blueprint.TIME + v.startTime - player:getServerTime()))
					local time =  cfg_blueprint.TIME + v.startTime - player:getServerTime()
					if time <= 0 then
						if self.schedulerInfo ~= nil then
							scheduler:unscheduleScriptEntry(self.schedulerInfo)
							self.schedulerInfo = nil
						end
						node2:setVisible(false)
					else
						node2:setVisible(true)
						node2:getChildByName("text"):setString(CONF:getStringValue("exploit in"))
						node2:getChildByName("text_jindu"):setString(formatTime(time))
						local progress = require("util.ScaleProgressDelegate"):create(node2:getChildByName("Image_jindu"), 264)
						local time = player:getServerTime() - v.startTime
						if time < 0 then time = 0 end
						local pro = time/cfg_blueprint.TIME
						progress:setPercentage(pro*100)
					end
				end
				update()
				self.schedulerInfo = scheduler:scheduleScriptFunc(update,1,false)
			end
		end
	end
	right:getChildByName("piece_bg"):addClickEventListener(function()
		local center = cc.exports.VisibleRect:center()
		local layer = self:getApp():createView("BlueprintScene/InfoLayer",v)
		tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
		self:addChild(layer)
		end)
end

function BlueprintScene:changeMode()
	local rn = self:getResourceNode()
	self:getPieceList()
	self.svd_:clear()
	for i=1,4 do
		rn:getChildByName("btn_all"):getChildByName("node_"..i):getChildByName("selected"):setVisible(false)
		rn:getChildByName("btn_all"):getChildByName("node_"..i):getChildByName("text_selected"):setVisible(false)
		rn:getChildByName("btn_all"):getChildByName("node_"..i):getChildByName("text"):setVisible(true)
	end
	rn:getChildByName("btn_all"):getChildByName("node_"..self.mode_):getChildByName("selected"):setVisible(true)
	rn:getChildByName("btn_all"):getChildByName("node_"..self.mode_):getChildByName("text_selected"):setVisible(true)
	for k,v in pairs(self.schedulerSingles) do
		if v ~= nil then
			scheduler:unscheduleScriptEntry(v)
		end
	end
	if self.schedulerInfo ~= nil then
		scheduler:unscheduleScriptEntry(self.schedulerInfo)
		self.schedulerInfo = nil
	end
	rn:getChildByName("right"):getChildByName("produce_num"):setString(CONF:getStringValue("exploit in")..": ".. #player:getBlueprint_list().."/"..CONF.BUILDING_3.get(player:getBuildingInfo(CONF.EBuilding.kShipDevelop).level).QUEUE+CONF.VIP.get(player:getVipLevel()).ADD_RAD_QUEUE)
	self.schedulerSingles = {}

	local function setSelectedShip(v)
		if v.type == self.mode_ then
			if self.mode_ == 1 then
				self.selectedShip1 = v
			elseif self.mode_ == 2 then
				self.selectedShip2 = v
			elseif self.mode_ == 3 then
				self.selectedShip3 = v
			elseif self.mode_ == 4 then
				self.selectedShip4 = v
			end
		end
	end
	animManager:runAnimByCSB(rn:getChildByName("right"):getChildByName("node2"):getChildByName("shalou"), "BlueprintScene/sfx/shalou/shalou.csb", "1")
	local selectedInfo = self.selectedShip1
	if self.mode_ == 2 then
		selectedInfo = self.selectedShip2
	elseif self.mode_ == 3 then
		selectedInfo = self.selectedShip3
	elseif self.mode_ == 4 then
		selectedInfo = self.selectedShip4
	end
	for i,v in ipairs(self.blueprint_list) do
		if selectedInfo.id == v.id then
			selectedInfo = v
		end
		if v.type == self.mode_ then
			local node = self:creatPieceNode(v)
			local function func()
				if self.schedulerInfo ~= nil then
					scheduler:unscheduleScriptEntry(self.schedulerInfo)
					self.schedulerInfo = nil
				end
				local cfg_blueprint = CONF.BLUEPRINT.get(v.id)
				local time =  cfg_blueprint.TIME + v.startTime - player:getServerTime()
				if time <= 0 and v.startTime ~= 0 and node:getChildByName("Image_black"):isVisible() then 
					local strData = Tools.encode("BlueprintDevelopeReq", {   
						type = 2,
						blueprint_id = v.id,
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_BLUEPRINT_DEVELOPE_REQ"),strData)
					gl:retainLoading()
				end
				local children = rn:getChildByName("list"):getChildren()
				for k,v in pairs(children) do
					v:getChildByName("Image_selected"):setVisible(false)
				end
				node:getChildByName("Image_selected"):setVisible(true)
				setSelectedShip(v)
				self:refreshInfo(v)
			end
			local callback = {node = node:getChildByName("touch"), func = func}
			self.svd_:addElement(node,{callback = callback})
		end
	end
	local children = rn:getChildByName("list"):getChildren()
	for k,v in pairs(children) do
		if v:getChildByName("Image_bg"):getTag() == selectedInfo.id then
			v:getChildByName("Image_selected"):setVisible(true)
		else
			v:getChildByName("Image_selected"):setVisible(false)
		end
	end
	self:refreshInfo(selectedInfo)
end

function BlueprintScene:getFreshRES()
	local rn = self:getResourceNode()
	if rn:getChildByName('Node_money') ~= nil then
		for i=1, 4 do
			if rn:getChildByName('Node_money'):getChildByName(string.format("res_text_%d",i)) then
				rn:getChildByName('Node_money'):getChildByName(string.format("res_text_%d",i)):setString(formatRes(player:getResByIndex(i)))
			end
		end
		rn:getChildByName('Node_money'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
		rn:getChildByName('Node_money'):getChildByName('money_add'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

			rechargeNode:init(self:getParent(), {index = 1})
			self:addChild(rechargeNode)
		end)
		rn:getChildByName('Node_money'):getChildByName('touch1'):addClickEventListener(function ( sender ) 
			playEffectSound("sound/system/click.mp3")
			local rechargeNode = require("app.views.CityScene.RechargeNode"):create()
			rechargeNode:init(self:getParent(), {index = 1})
			self:addChild(rechargeNode)
		end)
	end
	local eventDispatcher = self:getEventDispatcher()
	self.resListener_ = cc.EventListenerCustom:create("ResUpdated", function ()
		for i=1, 4 do
			if rn:getChildByName('Node_money'):getChildByName(string.format("res_text_%d",i)) then
				rn:getChildByName('Node_money'):getChildByName(string.format("res_text_%d",i)):setString(formatRes(player:getResByIndex(i)))
			end
		end
		rn:getChildByName('Node_money'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.resListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		rn:getChildByName('Node_money'):getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)
end

function BlueprintScene:onExitTransitionStart()
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.resListener_)
	for k,v in pairs(self.schedulerSingles) do
		if v ~= nil then
			scheduler:unscheduleScriptEntry(v)
		end
	end
	if self.schedulerInfo ~= nil then
		scheduler:unscheduleScriptEntry(self.schedulerInfo)
		self.schedulerInfo = nil
	end
	self.schedulerSingles = {}
	if self.svd_ then
		self.svd_:clear()
	end
end

return BlueprintScene