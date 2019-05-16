local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local Bit = require "Bit"

local ShipInfoLayer = class("ShipInfoLayer", cc.load("mvc").ViewBase)

local animManager = require("app.AnimManager"):getInstance()

ShipInfoLayer.RESOURCE_FILENAME = "ShipsScene/ship/ShipInfoLayer.csb"

ShipInfoLayer.NEED_ADJUST_POSITION = true

ShipInfoLayer.selectType = 1

ShipInfoLayer.selectedSkillBigPos = nil
ShipInfoLayer.selectedEquipBigPos = nil
ShipInfoLayer.selectedGemBigPos = nil
ShipInfoLayer.selectedEquipGuid = nil

local starPos = {{111.5},
{101, 122}, {90.5, 111.5, 132.5}, {80, 101, 122, 143}, {69.5, 90.5, 111.5, 132.5, 154.5}, {59, 80, 101, 122, 143, 164}}

local schedulers = nil

local cfg_ship = nil
local ship = nil

ShipInfoLayer.IS_DEBUG_LOG_LOCAL = false
function ShipInfoLayer:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		print(_log)
	end
end

function ShipInfoLayer:onCreate(data)
	self.data_ = data -- shipId,guid
end

function ShipInfoLayer:refreshTotal()
	self.isTouch = false
	self.count = 0
	self.longPress = false
	self.isMoved = false
	-- shipId,ship_break,guid,power,blueprintId
	if self.data_.selectType then
		self.selectType = self.data_.selectType
	end
	local rn = self:getResourceNode()

	cfg_ship = CONF.AIRSHIP.get(self.data_.shipId)
	ship = player:getShipByGUID(self.data_.guid)
	self.data_.blueprintId = cfg_ship.BLUEPRINT[1]
	self.data_.power = player:calShipFightPower( self.data_.guid )
	self:addBgListener(rn:getChildByName("bg"))
	rn:getChildByName("close"):addClickEventListener(function()
		self:removeFromParent()
		end)
	rn:getChildByName("title"):setString(CONF:getStringValue("my ships"))
	rn:getChildByName("title"):getChildByName("Image_22_0"):setPositionX(rn:getChildByName("title"):getPositionX()+rn:getChildByName("title"):getContentSize().width+5)
	local left = rn:getChildByName("left")

	local cfg_breakNum = CONF.SHIP_BREAK.get(cfg_ship.QUALITY).NUM
	left:getChildByName("quality"):setTexture("ShipQuality/quality_"..cfg_ship.QUALITY..".png")
	left:getChildByName("name"):setString(CONF:getStringValue(cfg_ship.NAME_ID))
--	local cfg_breakNum = CONF.SHIP_BREAK.get(cfg_ship.QUALITY).NUM
--	local isShow = 0
--	for i=1,6 do
--		left:getChildByName("star"..i):setVisible(i<=cfg_breakNum)
--		if i<=cfg_breakNum then
--			isShow = isShow + 1
--		end
--		left:getChildByName("star"..i):setTexture("Common/ui/ui_star_gray.png")
--		if i <= ship.ship_break then
--			left:getChildByName("star"..i):setTexture("Common/ui/ui_star_light.png")
--		end
--	end
	
--	self:resetNodePos(isShow)
    ShowShipStar(left,ship.ship_break,"star")
	left:getChildByName("zhanli"):setString(self.data_.power)

	local node2 = require("app.ExResInterface"):getInstance():FastLoad("sfx/"..cfg_ship.RES_ID)
	node2:setName("sfxShip2")
	node2:setScale(-2,2)
	animManager:runAnimByCSB(node2,"sfx/"..cfg_ship.RES_ID, "attack_2") 

	for i=1,3 do
		if self.back:getChildByName("Image_1"):getChildByName("sfxShip"..i) then
			self.back:getChildByName("Image_1"):getChildByName("sfxShip"..i):removeFromParent()
		end
	end


	self.back:getChildByName("Image_1"):addChild(node2)
	self.back:setPosition(0,0)

	node2:setPosition(self.back:getChildByName("Image_1"):getChildByName("Node_2"):getPosition())

end

function ShipInfoLayer:resetNodePos(list)
	--[[local originPos = {}
	local showID = 0
	for i=1, #list do
		if list[i]:isVisible() then
			originPos[i] = list[i]:getPositionX();
			showID = showID + 1;
		end
	end

	--print_t(originPos);

	local middlePos = originPos[1] + (originPos[#originPos] - originPos[1]) /2 ;
	local width = list[1]:getContentSize().width
	local firstPos = middlePos - width * (showID / 2);
	for i=1, showID do
		list[i]:setPositionX(firstPos + width * (i - 2))
	end]]--
	local left = self:getResourceNode():getChildByName("left")
	for i=1,list do
		left:getChildByName("star"..i):setPositionX(starPos[list][i]);
	end
end

function ShipInfoLayer:clickLeft(flag)
	self:_print("@@@@@ ShipInfoLayer:clickLeft " .. tostring(flag or " nil"))

	self.selectedSkillBigPos = nil
	self.selectedEquipBigPos = nil
	self.selectedGemBigPos = nil
	self.selectedEquipGuid = nil
	self:removeTips()
	local haveShipList = {}
	for i,v in ipairs(self:getParent().allShipList) do
		if v.type == self:getParent().mode_ or self:getParent().mode_ == 5 then
			if v.isHave == 1 then
				table.insert(haveShipList,v)
			end
		end
	end
	for i=1,#haveShipList do
		if self.data_.shipId == haveShipList[i].shipId then
			if not flag then
				if haveShipList[i+1] then
					self.data_ = haveShipList[i+1]
					break
				else
					self.data_ = haveShipList[1]
					break
				end
			else

				if haveShipList[i-1] then
					self.data_ = haveShipList[i-1]
					break
				else
					self.data_ = haveShipList[#haveShipList]
					break
				end
			end
		end
	end
	-- self:getParent().selectedShip = self.data_
	self:getParent():SetSelectedShip(self.data_)
	self:getParent():refreshList()
	self:refreshTotal()
	self:changeBtnType()
	cfg_ship = CONF.AIRSHIP.get(self.data_.shipId)
	ship = player:getShipByGUID(self.data_.guid)
end


function ShipInfoLayer:addIconListener(node)
	local rn = self:getResourceNode()
 	local left = rn:getChildByName("left")
 	local move_left = false
 	local move_right = false
 	local haveShipList = {}
	local nextShip = {}
	local lastShip = {}
	local function onTouchBegan(touch, event)
		move_left = false
		move_right = false
		local target = event:getCurrentTarget()

		local ln = left:getChildByName("Image"):convertToNodeSpace(touch:getLocation())

		local sv_s = left:getChildByName("Image"):getContentSize()
		local sv_rect = cc.rect(0, 0, sv_s.width, sv_s.height)

		if cc.rectContainsPoint(sv_rect, ln) then
		
			local locationInNode = target:convertToNodeSpace(touch:getLocation())
			local s = target:getContentSize()

			local rect = cc.rect(0, 0, s.width, s.height)
			
			if cc.rectContainsPoint(rect, locationInNode) then
				for i,v in ipairs(self:getParent().allShipList) do
					if v.type == self:getParent().mode_ or self:getParent().mode_ == 5 then
						if v.isHave == 1 then
							table.insert(haveShipList,v)
						end
					end
				end
				for i=1,#haveShipList do
					if self.data_.shipId == haveShipList[i].shipId then
						if haveShipList[i+1] then
							lastShip = haveShipList[i+1]
							break
						else
							lastShip = haveShipList[1]
							break
						end
					end
				end
				for i=1,#haveShipList do
					if self.data_.shipId == haveShipList[i].shipId then
						if haveShipList[i-1] then
							nextShip = haveShipList[i-1]
							break
						else
							nextShip = haveShipList[#haveShipList]
							break
						end
					end
				end
				
				return true
			end

		end

		return false
	end

	local function onTouchMoved(touch, event)

		local target = event:getCurrentTarget()
		local s = target:getContentSize()
		local delta = touch:getDelta()
		local starLocation =  touch:getStartLocation()
		local nowLocation = touch:getLocation()
		local delta_x = nowLocation.x - starLocation.x
		if math.abs(delta_x) < left:getChildByName("Image"):getContentSize().width*2/3 then
			if math.abs(delta.x) > g_click_delta then
				if delta.x > 0 then
					if math.abs(delta_x) > left:getChildByName("Image"):getContentSize().width/3 then
						move_right = true
						move_left = false
					else
						move_right = false
						move_left = false
					end
					if not self.back:getChildByName("Image_1"):getChildByName("sfxShip1") then
						local node1 = require("app.ExResInterface"):getInstance():FastLoad("sfx/"..CONF.AIRSHIP.get(nextShip.shipId).RES_ID)
						node1:setName("sfxShip1")
						node1:setScale(-2,2)
						animManager:runAnimByCSB(node1,"sfx/"..CONF.AIRSHIP.get(nextShip.shipId).RES_ID, "attack_2")
						self.back:getChildByName("Image_1"):addChild(node1)
						node1:setPosition(self.back:getChildByName("Image_1"):getChildByName("Node_1"):getPosition())
					end
					self.back:setPositionX(delta_x)
				else
					if math.abs(delta_x) > left:getChildByName("Image"):getContentSize().width/3 then
						move_left = true
						move_right = false
					else
						move_right = false
						move_left = false
					end
					if not self.back:getChildByName("Image_1"):getChildByName("sfxShip3") then
						local node3 = require("app.ExResInterface"):getInstance():FastLoad("sfx/"..CONF.AIRSHIP.get(lastShip.shipId).RES_ID)
						node3:setName("sfxShip3")
						node3:setScale(-2,2)
						animManager:runAnimByCSB(node3,"sfx/"..CONF.AIRSHIP.get(lastShip.shipId).RES_ID, "attack_2")
						self.back:getChildByName("Image_1"):addChild(node3)
						node3:setPosition(self.back:getChildByName("Image_1"):getChildByName("Node_3"):getPosition())
					end
					self.back:setPositionX(delta_x)
				end
			end
		end

	end

	local function onTouchEnded(touch, event)
	    if self.back:getChildByName("Image_1"):getChildByName("sfxShip1") then
	    	self.back:getChildByName("Image_1"):getChildByName("sfxShip1"):removeFromParent()
	    end
	    if self.back:getChildByName("Image_1"):getChildByName("sfxShip3") then
	    	self.back:getChildByName("Image_1"):getChildByName("sfxShip3"):removeFromParent()
	    end
	    if move_left then
	    	self:clickLeft(false)
	    elseif move_right then
	    	self:clickLeft(true)
	    elseif not move_left and not move_right then
	    	self:refreshTotal()
	    end
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end


function ShipInfoLayer:onEnterTransitionFinish()
	guideManager:checkInterface(CONF.EInterface.kTp)
	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if CONF.FUNCTION_OPEN.get("tp_open").OPEN_GUIDANCE == 1 then
		if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kTp)== 0 and g_System_Guide_Id == 0 then
			systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("tp_open").INTERFACE)
		else
			if g_System_Guide_Id ~= 0 then
				systemGuideManager:createGuideLayer(g_System_Guide_Id)
			end
		end
	end
	

	local rn = self:getResourceNode()
	self:addBgListener(rn:getChildByName("bg"))
	rn:getChildByName("close"):addClickEventListener(function()
		self:removeFromParent()
		end)
	rn:getChildByName("title"):setString(CONF:getStringValue("my ships"))
	rn:getChildByName("title"):getChildByName("Image_22_0"):setPositionX(rn:getChildByName("title"):getPositionX()+rn:getChildByName("title"):getContentSize().width+5)
	
	local left = rn:getChildByName("left")

	self.clip = cc.ClippingNode:create()  
	self.clip:setInverted(false)  
	self.clip:setAlphaThreshold(1)  
	self.clip:setPosition(left:getChildByName("ship_sfx"):getPosition())
	left:addChild(self.clip,rn:getChildByName("left"):getLocalZOrder() - 1)  

	self.back =  require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/sfxNode.csb")  
	self.clip:addChild(self.back)
	self.stencil = cc.Sprite:create("ShipsScene/ui/2222.png")
	self.stencil:setAnchorPoint(cc.p(0.5,0.5))
	self.stencil:setPosition(self.back:getPosition())
	self.clip:setStencil(self.stencil)


	self:addIconListener(left:getChildByName("Image"))

	animManager:runAnimByCSB(left:getChildByName("left_btn"),"ShipsScene/ship/ShipInfoLayer.csb", "animation0")
	animManager:runAnimByCSB(left:getChildByName("right_btn"),"ShipsScene/ship/ShipInfoLayer.csb", "animation0")

	self:refreshTotal()

	
	local btn = rn:getChildByName("btn")
	btn:getChildByName("total"):getChildByName("text"):setString(CONF:getStringValue("pandect"))
	btn:getChildByName("total"):addClickEventListener(function()
		self:removeTips()
		if self.selectType ~= 1 then
			self.selectType = 1
			self:changeBtnType()
		end
		end)
	btn:getChildByName("skill"):getChildByName("text"):setString(CONF:getStringValue("weapon"))
	btn:getChildByName("skill"):addClickEventListener(function()
		local param = CONF.PARAM.get("city_6_open").PARAM
		if player:getLevel() < param[1] then
			tips:tips(CONF:getStringValue("skill open"))
			return
		end
		if player:getBuildingInfo(1).level < param[2] then
			tips:tips(CONF:getStringValue("BuildingName_1")..param[2]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
			return
		end
		if CONF.FUNCTION_OPEN.get("wqyj_open").OPEN_GUIDANCE == 1 then
			if player:getSystemGuideStep(CONF.FUNCTION_OPEN.get("wqyj_open").ID) == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() then
				tips:tips(CONF:getStringValue("skill open"))
				return
			end
		end
		self:removeTips()
		if self.selectType ~= 2 then
			self.selectType = 2
			self:changeBtnType()
		end
		end)
	btn:getChildByName("equip"):getChildByName("text"):setString(CONF:getStringValue("equip"))
	btn:getChildByName("equip"):addClickEventListener(function()
		local param = CONF.PARAM.get("city_16_open").PARAM
		if player:getLevel() < param[1] then
			tips:tips(CONF:getStringValue("equip open"))
			return
		end
		if player:getBuildingInfo(1).level < param[2] then
			tips:tips(CONF:getStringValue("BuildingName_1")..param[2]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
			return
		end
		if CONF.FUNCTION_OPEN.get("dzgc_open").OPEN_GUIDANCE == 1 then
			if player:getSystemGuideStep(CONF.FUNCTION_OPEN.get("dzgc_open").ID) == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() then
				tips:tips(CONF:getStringValue("equip open"))
				return
			end
		end
		self:removeTips()
		if self.selectType ~= 3 then
			self.selectType = 3
			self:changeBtnType()
		end
		end)

	btn:getChildByName("energy"):getChildByName("text"):setString(CONF:getStringValue("energy groove"))
	local energyParam = CONF.PARAM.get("nlc_open").PARAM;
	local left = self:getResourceNode():getChildByName("left");
	local shipTotalNode = self:getResourceNode():getChildByName("list"):getChildByName("shipTotalNode");
	if player:getLevel() < energyParam[1] or player:getBuildingInfo(1).level < energyParam[2] then
		btn:getChildByName("energy"):setVisible(false);

    	self:refreshNodePos(false)
	else
		btn:getChildByName("energy"):setVisible(true);

    	self:refreshNodePos(true)
	end

	btn:getChildByName("energy"):addClickEventListener(function()
		if player:getLevel() < energyParam[1] then
			tips:tips(CONF:getStringValue("grade")..energyParam[1]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
			return
		end
		if player:getBuildingInfo(1).level < energyParam[2] then
			tips:tips(CONF:getStringValue("BuildingName_1")..energyParam[2]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
			return
		end
		self:removeTips()
		if self.selectType ~= 4 then
			self.selectType = 4
			self:changeBtnType()
		end
		end)
	btn:getChildByName("gem"):getChildByName("text"):setString(CONF:getStringValue("shop_mode_4"))
	btn:getChildByName("gem"):addClickEventListener(function()
		local param = CONF.PARAM.get("smelter_open").PARAM
		if player:getLevel() < param[1] then
			tips:tips(CONF:getStringValue("grade")..param[1]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
			return
		end
		if player:getBuildingInfo(1).level < param[2] then
			tips:tips(CONF:getStringValue("BuildingName_1")..param[2]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
			return
		end
		self:removeTips()
		if self.selectType ~= 5 then
			self.selectType = 5
			self:changeBtnType()
		end
		end)
	cfg_ship = CONF.AIRSHIP.get(self.data_.shipId)
	ship = player:getShipByGUID(self.data_.guid)
	rn:getChildByName("left"):getChildByName("right_btn"):addClickEventListener(function()
		self:clickLeft(false)
		end)
	rn:getChildByName("left"):getChildByName("left_btn"):addClickEventListener(function()
		self:clickLeft(true)
		end)
	local list = rn:getChildByName("list")
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("list") ,cc.size(7,0), cc.size(504 ,630)) 
	rn:getChildByName("list"):addClickEventListener(function()
		self:removeTips()
		end)
	rn:getChildByName("total"):setString(CONF:getStringValue("pandect"))
	self:changeBtnType()

	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SHIP_ADD_EXP_RESP") then
			
			playEffectSound("sound/system/use_item.mp3")
			gl:releaseLoading()

			local proto = Tools.decode("ShipAddExpResp",strData)
			printInfo("ShipAddExpResp result  "..proto.result)
			if proto.result ~= 0 then
				print("error: CMD_SHIP_ADD_EXP_RESP",proto.result)
				return
			end

			tips:tips(CONF:getStringValue("successful operation"))

			if player:calShipFightPowerByInfo(player:calShipByInfo(ship)) ~= player:calShipFightPower(self.data_.guid) then
				if shipTotalNode ~= nil then
					shipTotalNode:getChildByName("infoBg"):getChildByName("zhanli"):setString(player:calShipFightPower(self.data_.guid));
				end
				flurryLogEvent("ship_power_change", {ship_id = tostring(self.data_.shipId)}, 2)
			end

			local guid = self.data_.guid

			if ship.level ~= player:getShipByGUID(guid).level then
				self:createShipLevelUpNode(self.data_.shipId, player:calShipByInfo(ship), player:calShipByInfo(player:getShipByGUID(guid)))
				flurryLogEvent("ship_level_up", {ship_id = tostring(self.data_.shipId), info = "before_level:"..ship.level.."-after_level:"..player:getShipByGUID(guid).level}, 2)
			    if device.platform == "ios" or device.platform == "android" then
                    TDGAMission:onCompleted("ShipLevelUP:"..self.data_.shipId.."("..ship.level.."-"..player:getShipByGUID(guid).level..")")
                end
            end

			local ship_info = player:getShipByGUID(guid)
			local exp_node = rn:getChildByName("exp_node")
			exp_node:getChildByName("lv"):setString("Lv."..ship_info.level)

			if ship_info.level == 1 then
				exp_node:getChildByName("break_now_num"):setString(ship_info.exp)
				exp_node:getChildByName("break_max_num"):setString("/"..CONF.SHIPLEVEL.get(1).EXP_ALL)
			else
				exp_node:getChildByName("break_now_num"):setString(ship_info.exp - CONF.SHIPLEVEL.get(ship_info.level-1).EXP_ALL)
				exp_node:getChildByName("break_max_num"):setString("/"..CONF.SHIPLEVEL.get(ship_info.level).EXP_ALL - CONF.SHIPLEVEL.get(ship_info.level-1).EXP_ALL)
			end
			exp_node:getChildByName("break_max_num"):setPositionX(exp_node:getChildByName("break_now_num"):getPositionX() + exp_node:getChildByName("break_now_num"):getContentSize().width)

			if ship_info.level == 1 then
				self.progress:setPercentage(ship_info.exp/CONF.SHIPLEVEL.get(1).EXP_ALL*100)
			else
				self.progress:setPercentage((ship_info.exp - CONF.SHIPLEVEL.get(ship_info.level-1).EXP_ALL)/(CONF.SHIPLEVEL.get(ship_info.level).EXP_ALL - CONF.SHIPLEVEL.get(ship_info.level-1).EXP_ALL)*100)
			end

			for i=1,4 do
				local exp = exp_node:getChildByName("exp_"..i)
				local item_conf = CONF.ITEM.get(13000+i)

				exp:getChildByName("have_num"):setString(player:getItemNumByID(item_conf.ID))

				if tonumber(exp:getChildByName("have_num"):getString()) == 0 then
					exp:getChildByName("have_num"):setTextColor(cc.c4b(255,145,136,255))
					-- exp:getChildByName("have_num"):enableShadow(cc.c4b(255,145,136,255), cc.size(0.5,0.5))
				end

				if exp:getChildByName("bg_light"):isVisible() then
					if player:getItemNumByID(13000+i) == 0 or player:getItemNumByID(13000+i) == nil then
						exp:getChildByName("bg_light"):setVisible(false)
						exp_node:getChildByName("use"):setEnabled(false)
					end
				end
			end

			-- 加经�?

			ship = player:getShipByGUID(self.data_.guid)
			if rn:getChildByName("list"):getChildByName("shipTotalNode") then
				self:refreshInfoNode(rn:getChildByName("list"):getChildByName("shipTotalNode"))

			end
			if rn:getChildByName("SkillNode") then
				self:refreshSkillNode(rn:getChildByName("SkillNode"))
			end
			if rn:getChildByName("EnergyNode") then
				self:refreshEnergyNode(rn:getChildByName("EnergyNode"))
			end
			if rn:getChildByName("EquipNode") then
				self:refreshEquipNode(rn:getChildByName("EquipNode"))
			end
			if rn:getChildByName("GemNode") then
				self:refreshGemNode(rn:getChildByName("GemNode"))
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SHIP_BREAK_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("ShipBreakResp",strData)

			if proto.result < 0 then
				print("ShipBreakResp error :",proto.result)
				return
			else
				tips:tips(CONF:getStringValue("break ok"))

				if guideManager:getGuideType() then
					guideManager:doEvent("recv")
				end

				local before_ship_info = ship
				if player:calShipFightPowerByInfo(player:calShipByInfo(before_ship_info)) ~= player:calShipFightPower(before_ship_info.guid) then
					flurryLogEvent("ship_power_change", {ship_id = tostring(self.data_.shipId)}, 2)
				end

				local break_num = 0
				if player:calShip(before_ship_info.guid).ship_break then
					break_num = player:calShip(before_ship_info.guid).ship_break
				end

				local break_num_1 = 0
				if player:calShipByInfo(ship).ship_break then
					break_num_1 = player:calShipByInfo(ship).ship_break
				end
				local break_num_2 = 0
				if player:calShipByInfo(player:getShipByGUID(self.data_.guid)).ship_break then
					break_num_2 = player:calShipByInfo(player:getShipByGUID(self.data_.guid)).ship_break
				end
				flurryLogEvent("ship_break_up", {ship_id = string.format("id:%d",before_ship_info.id), info = "before_break:"..break_num_1..",after_break:"..break_num_2}, 2)
                if device.platform == "ios" or device.platform == "android" then
                    TDGAMission:onCompleted("ShipBreakUP:"..before_ship_info.id.."("..break_num_1.."-"..break_num_2..")")
                end
				for i,v in ipairs(CONF.SHIP_BREAK.get(ship.quality)["ITEM_ID"..(ship.ship_break+1)]) do
					if v == 3001 then
						flurryLogEvent("use_gold_break_ship", {ship_id = string.format("id:%d",before_ship_info.id), info = "before_use:"..player:getResByIndex(1)..",after_use:"..(player:getResByIndex(1) + CONF.SHIP_BREAK.get(ship.quality)["ITEM_NUM"..(ship.ship_break+1)][i])}, 1,  CONF.SHIP_BREAK.get(ship.quality)["ITEM_NUM"..(ship.ship_break+1)][i])
					end
				end
				self:createShipUpgradeNode(self.data_.shipId, player:calShipByInfo(ship), player:calShipByInfo(player:getShipByGUID(self.data_.guid)))
                self:refreshTotal()
			end
			ship = player:getShipByGUID(self.data_.guid)
			if rn:getChildByName("list"):getChildByName("shipTotalNode") then
				self:refreshInfoNode(rn:getChildByName("list"):getChildByName("shipTotalNode"))
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_CHANGE_WEAPON_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("ChangeWeaponResp",strData)

			if proto.result ~= 0 then
				print("ChangeWeaponResp error :",proto.result)
				return
			else 
				tips:tips(CONF:getStringValue("successful operation"))
				if player:calShipFightPowerByInfo(player:calShipByInfo(ship)) ~= player:calShipFightPower(ship.guid) then
					flurryLogEvent("ship_power_change", {ship_id = tostring(self.data_.shipId)}, 2)
				end


			end
			local before_ship_info = ship
			ship = player:getShipByGUID(self.data_.guid)

			local equip_str = ""
			for i,v in ipairs(ship.weapon_list) do

				if equip_str ~= "" then
					equip_str = equip_str.."-"
				end

				if v == 0 then
					equip_str = equip_str.."0"
				else
					equip_str = equip_str..player:getWeaponByGUID(v).weapon_id
				end

			end

			local equip_str_2 = ""
			for i,v in ipairs(player:calShip(ship.guid).weapon_list) do

				if equip_str_2 ~= "" then
					equip_str_2 = equip_str_2.."-"
				end

				if v == 0 then
					equip_str_2 = equip_str_2.."0"
				else
					equip_str_2 = equip_str_2..player:getWeaponByGUID(v).weapon_id
				end

			end


			flurryLogEvent("ship_weapon_change", {ship_id = string.format("id:%d", before_ship_info.id), info = "before_weapon:"..equip_str..",after_weapon:"..equip_str_2}, 2)
			if rn:getChildByName("SkillNode") then
				self:refreshSkillNode(rn:getChildByName("SkillNode"))
			end
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SHIP_ADD_ENERGY_EXP_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("ShipAddEnergyExpResp",strData)

			if proto.result ~= 0 then
				print("ShipAddEnergyExpResp error :",proto.result)
			else 
				tips:tips(CONF:getStringValue("successful operation"))
				-- return
				-- if player:calShipFightPowerByInfo(player:calShipByInfo(ship)) ~= player:calShipFightPower(ship.guid) then

				-- 	flurryLogEvent("ship_power_change", {ship_id = tostring(ship.id)}, 2)
				-- end
				if player:calShipFightPowerByInfo(player:calShipByInfo(ship)) ~= player:calShipFightPower(ship.guid) then
					flurryLogEvent("ship_power_change", {ship_id = tostring(self.data_.shipId)}, 2)
				end
				if rn:getChildByName("EnergyNode") then
					self:refreshEnergyNode(rn:getChildByName("EnergyNode"))
				end

			end
			ship = player:getShipByGUID(self.data_.guid)
        elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOCK_ENERGY_TIME_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("ShipLockEnergyTimeResp",strData)

			if proto.result ~= 0 then
				print("ShipLockEnergyTimeResp error :",proto.result)
			else 
				tips:tips(CONF:getStringValue("successful operation"))

				if proto.user_sync then
					player:userSync(proto.user_sync)
				end
                if rn:getChildByName("EnergyNode") then
					self:refreshEnergyNode(rn:getChildByName("EnergyNode"))
				end

			end
			ship = player:getShipByGUID(self.data_.guid)
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_SHIP_EQUIP_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("ShipEquipResp",strData)

			if not proto then
				print("error: CMD_SHIP_EQUIP_RESP")
				return
			end
			if proto.result ~= 0 then
				print("error: CMD_SHIP_EQUIP_RESP",proto.result)
			end
			local before_ship_info = ship

			if player:calShipFightPowerByInfo(player:calShipByInfo(before_ship_info)) ~= player:calShipFightPower(before_ship_info.guid) then
				flurryLogEvent("ship_power_change", {ship_id = tostring(self.data_.shipId)}, 2)
			end
			local equip_str = ""
			for i,v in ipairs(before_ship_info.equip_list) do

				if equip_str ~= "" then
					equip_str = equip_str.."-"
				end

				if v == 0 then
					equip_str = equip_str.."0"
				elseif player:getEquipByGUID(v) then
					equip_str = equip_str..player:getEquipByGUID(v).equip_id
				end

			end

			local equip_str_2 = ""
			for i,v in ipairs(player:calShip(before_ship_info.guid).equip_list) do

				if equip_str_2 ~= "" then
					equip_str_2 = equip_str_2.."-"
				end

				if v == 0 then
					equip_str_2 = equip_str_2.."0"
				elseif player:getEquipByGUID(v) then
					equip_str_2 = equip_str_2..player:getEquipByGUID(v).equip_id
				end

			end


			flurryLogEvent("ship_equip_change", {ship_id = string.format("id:%d", before_ship_info.id), info = "before_equip:"..equip_str..",after_equip:"..equip_str_2}, 2)
			if guideManager:getGuideType() then
				guideManager:doEvent("recv")
			end 
			self.selectedEquipGuid = nil
			if rn:getChildByName("EquipNode") then
				self:refreshEquipNode(rn:getChildByName("EquipNode"))
			end
			tips:tips(CONF:getStringValue("successful operation"))
			ship = player:getShipByGUID(self.data_.guid)
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_GEM_EQUIP_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("GemEquipResp",strData)
			print("GemEquipResp")
			print(proto.result)

			if not proto then
				print("error: CMD_GEM_EQUIP_RESP")
				return
			end
			if proto.result ~= 0 then
				print("error: CMD_GEM_EQUIP_RESP",proto.result)
				return
			end

			local before_ship_info = ship

			if player:calShipFightPowerByInfo(player:calShipByInfo(before_ship_info)) ~= player:calShipFightPower(before_ship_info.guid) then
				flurryLogEvent("ship_power_change", {ship_id = tostring(before_ship_info.id)}, 2)
			end

			local gem_str = ""
			for i,v in ipairs(before_ship_info.gem_list) do

				if gem_str ~= "" then
					gem_str = gem_str.."-"
				end

				if v == 0 then
					gem_str = gem_str.."0"	
				else
					gem_str = gem_str..v
				end

			end

			local gem_str_2 = ""
			for i,v in ipairs(player:calShip(before_ship_info.guid).gem_list) do

				if gem_str_2 ~= "" then
					gem_str_2 = gem_str_2.."-"
				end

				if v == 0 then
					gem_str_2 = gem_str_2.."0"
				else
					gem_str_2 = gem_str_2..v
				end

			end

			flurryLogEvent("ship_gem_change", {ship_id = string.format("id:%d", before_ship_info.id), info = "before_gem:"..gem_str..",after_gem:"..gem_str_2}, 2)
			ship = player:getShipByGUID(self.data_.guid)
			if rn:getChildByName("GemNode") then
				self:refreshGemNode(rn:getChildByName("GemNode"))
			end
			tips:tips(CONF:getStringValue("successful operation"))
		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_STRENGTH_EQUIP_RESP") then

			gl:releaseLoading()

			local proto = Tools.decode("StrengthEquipResp",strData)
			printInfo("result  "..proto.result)
			if proto.result ~= 0 then
				print("error: CMD_STRENGTH_EQUIP_RESP",proto.result)
				return
			end

			if guideManager:getGuideType() then 
				guideManager:doEvent("recv")
			end

			local before_ship_info = ship

			if player:calShipFightPowerByInfo(player:calShipByInfo(before_ship_info)) ~= player:calShipFightPower(before_ship_info.guid) then
				flurryLogEvent("ship_power_change", {ship_id = tostring(before_ship_info.id)}, 2)
			end

			local equip_str = ""
			for i,v in ipairs(player:calShip(before_ship_info.guid).equip_list) do

				if equip_str ~= "" then
					equip_str = equip_str.."-"
				end

				if v == 0 then
					equip_str = equip_str.."0"
				elseif player:getEquipByGUID(v) then
					equip_str = equip_str..player:getEquipByGUID(v).equip_id.."("..player:getEquipByGUID(v).strength..")"
				end

			end

			flurryLogEvent("ship_equip_break", {ship_id = string.format("id:%d-equip:%s", before_ship_info.id, equip_str), power = tostring(player:calShipFightPower(before_ship_info.guid))}, 2)

			local equip_info = player:getEquipByGUID(proto.equip_guid)
			if equip_info then
				for i,v in ipairs(CONF.EQUIP_STRENGTH.get(equip_info.strength).ITEM_ID) do
					if v == 3001 then
						flurryLogEvent("use_gold_break_equip", {info = "before_use:"..player:getResByIndex(1)..",after_use:"..(player:getResByIndex(1) + CONF.EQUIP_STRENGTH.get(equip_info.strength).ITEM_NUM[i])}, 1,  CONF.EQUIP_STRENGTH.get(equip_info.strength).ITEM_NUM[i])
					end
				end
			end

			local texiao_node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/qianghua.csb")
			texiao_node:getChildByName("text"):setString(CONF:getStringValue("strength_success"))


			texiao_node:getChildByName("text"):runAction(cc.Sequence:create(cc.DelayTime:create(0.2), cc.CallFunc:create(function ( ... )
				texiao_node:getChildByName("text"):setVisible(true)
			end)))
			animManager:runAnimOnceByCSB(texiao_node:getChildByName("texiao"), "ShipsScene/sfx/qianghua.csb", "1", function ( ... )
				texiao_node:removeFromParent()
			end)
			texiao_node:setPosition(cc.exports.VisibleRect:center())
			self:addChild(texiao_node)

			if rn:getChildByName("EquipNode") then
				self:refreshEquipNode(rn:getChildByName("EquipNode"))
			end
			ship = player:getShipByGUID(self.data_.guid)
--			tips:tips(CONF:getStringValue("successful operation"))
		end
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	local function setVisibleAndAnim(cfg,ui)
		ui:getChildByName("yindao_1"):setVisible(false)
		ui:getChildByName("yindao_2"):setVisible(false)
		if Tools.isEmpty(cfg.HINT) == false then
			if player:getLevel() >= cfg.GRADE then
				if player:getSystemGuideStep(cfg.ID)== 0 and g_System_Guide_Id == 0 then
					for k,v in ipairs(cfg.HINT) do
						if v == 1 then
							local jiantou = ui:getChildByName("yindao_1")
							jiantou:setVisible(true)
							animManager:runAnimByCSB(jiantou, "GuideLayer/sfx/effect_0.csb", "1")
						elseif v == 2 then
							local jiantou = ui:getChildByName("yindao_2")
							jiantou:setVisible(true)
							animManager:runAnimByCSB(jiantou, "GuideLayer/sfx/Kuang/Kuang.csb", "1")
						end
					end
				else
					if g_System_Guide_Id ~= 0 then
						for k,v in ipairs(cfg.HINT) do
							if v == 1 then
								local jiantou = ui:getChildByName("yindao_1")
								jiantou:setVisible(true)
								animManager:runAnimByCSB(jiantou, "GuideLayer/sfx/effect_0.csb", "1")
							elseif v == 2 then
								local jiantou = ui:getChildByName("yindao_2")
								jiantou:setVisible(true)
								animManager:runAnimByCSB(jiantou, "GuideLayer/sfx/Kuang/Kuang.csb", "1")
							end
						end
					end
				end
			end
		end
	end
	local function updataSysguide()
		-- 氪晶
		local cfg_gem_open = CONF.FUNCTION_OPEN.get("kj_open")
		if cfg_gem_open.OPEN_GUIDANCE == 1 then
			setVisibleAndAnim(cfg_gem_open,btn:getChildByName("gem"))
		end
		-- 能量�?
		local cfg_energy_open = CONF.FUNCTION_OPEN.get("nlc_open")
		if cfg_energy_open.OPEN_GUIDANCE == 1 then
			setVisibleAndAnim(cfg_energy_open,btn:getChildByName("energy"))
		end
	end
	if schedulers == nil then
		schedulers = scheduler:scheduleScriptFunc(updataSysguide,1,false)
	end
end

function ShipInfoLayer:changeBtnType()
	local rn = self:getResourceNode()
	self.svd_:clear()
	self.equipList = nil
	self.skillList = nil
	self.gemList = nil

    if self.energyscheduler ~= nil then
	    scheduler:unscheduleScriptEntry(self.energyscheduler)
	    self.energyscheduler = nil
	end

	if self.selectType == 1 then
		if rn:getChildByName("list"):getChildByName("shipTotalNode") then
			rn:getChildByName("list"):getChildByName("shipTotalNode"):removeFromParent()
		end
		local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/shipTotalNode.csb")
		node:setName("shipTotalNode")
		self:refreshInfoNode(node)
		self.svd_:addElement(node)
	else
		if rn:getChildByName("list"):getChildByName("shipTotalNode") then
			rn:getChildByName("list"):getChildByName("shipTotalNode"):removeFromParent()
		end
	end

	if self.selectType == 2 then
		if rn:getChildByName("SkillNode") then
			rn:getChildByName("SkillNode"):removeFromParent()
		end
		local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/SkillNode.csb")
		node:setName("SkillNode")
		node:setPosition(rn:getChildByName("Node_pos"):getPosition())
		self:refreshSkillNode(node)
		rn:addChild(node)
	else
		if rn:getChildByName("SkillNode") then
			rn:getChildByName("SkillNode"):removeFromParent()
		end
	end

	if self.selectType == 3 then
		if rn:getChildByName("EquipNode") then
			rn:getChildByName("EquipNode"):removeFromParent()
		end
		local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/EquipNode.csb")
		node:setName("EquipNode")
		node:setPosition(rn:getChildByName("Node_pos"):getPosition())
		self:refreshEquipNode(node)
		rn:addChild(node)
	else
		if rn:getChildByName("EquipNode") then
			rn:getChildByName("EquipNode"):removeFromParent()
		end
	end

	if self.selectType == 5 then
		if rn:getChildByName("GemNode") then
			rn:getChildByName("GemNode"):removeFromParent()
		end
		local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/GemNode.csb")
		node:setName("GemNode")
		node:setPosition(rn:getChildByName("Node_pos"):getPosition())
		self:refreshGemNode(node)
		rn:addChild(node)
	else
		if rn:getChildByName("GemNode") then
			rn:getChildByName("GemNode"):removeFromParent()
		end
	end

	if self.selectType == 4 then
		if rn:getChildByName("EnergyNode") then
			rn:getChildByName("EnergyNode"):removeFromParent()
		end
		local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/ShipEnergy.csb")
		node:setName("EnergyNode")
		node:setPosition(rn:getChildByName("Node_pos"):getPosition())
		self:refreshEnergyNode(node)
		rn:addChild(node)
	else
		if rn:getChildByName("EnergyNode") then
			rn:getChildByName("EnergyNode"):removeFromParent()
		end
	end

end

function ShipInfoLayer:createShipUpgradeNode( id, now_info, info)
	local conf = CONF.AIRSHIP.get(id)
    local cfg_breakNum = CONF.SHIP_BREAK.get(conf.QUALITY).NUM
	local node = require("app.ExResInterface"):getInstance():FastLoad("Common/ShipLevelUpNode.csb")
    node:getChildByName("sj_bt_5"):setVisible(false)
	local attr_type = {CONF.EShipAttr.kAttack, CONF.EShipAttr.kEnergyAttack, CONF.EShipAttr.kDefence, CONF.EShipAttr.kHP, CONF.EShipAttr.kSpeed}

	for i,v in ipairs(attr_type) do
		node:getChildByName("text"..i):setString(CONF:getStringValue("Attr_"..v)..":")
		node:getChildByName("text"..i.."_now"):setString(now_info.attr[v])
		node:getChildByName("text"..i.."_next"):setString(info.attr[v])
	end

	for i=1,#attr_type do
		self:setPos(node,"text"..i)
	end

	for i=#attr_type+1,6 do
		node:getChildByName("text"..i):setVisible(false)
		node:getChildByName("text"..i.."_now"):setVisible(false)
		node:getChildByName("text"..i.."_next"):setVisible(false)
		node:getChildByName("text"..i.."_jt"):setVisible(false)
	end
--	if info.ship_break and info.ship_break > 0 then
--		for i=1,info.ship_break do
--            if node:getChildByName("star_"..i) then
--			    node:getChildByName("star_"..i):setTexture("Common/ui/ui_star_light.png")
--            end
--		end
--	end
    ShowShipStar(node,info.ship_break,"star_")

	node:getChildByName("back"):setSwallowTouches(true)
	node:getChildByName("back"):addClickEventListener(function ( ... )
		node:removeFromParent()
	end)

	local function setPos( name )
		local nn = node:getChildByName(name)
		local now = node:getChildByName(name.."_now")
		local jt = node:getChildByName(name.."_jt")
		local next = node:getChildByName(name.."_next")

--		now:setPositionX(nn:getPositionX() + nn:getContentSize().width)
--		jt:setPositionX(now:getPositionX() + now:getContentSize().width + 5)
--		next:setPositionX(jt:getPositionX() + jt:getContentSize().width + 5)

		now:setOpacity(255)
		jt:setOpacity(255)
		next:setOpacity(255)
	end

	local function onFrameEvent(frame)
		if nil == frame then
			return
		end
		local str = frame:getEvent()

		if str == "1" then

			local f_node = frame:getNode()

			if f_node:getName() ~= "sj_bottom03_4" then
				setPos(f_node:getName())
			else
--				for i=1,6 do
--					if node:getChildByName("star_"..i) then
--						node:getChildByName("star_"..i):setVisible(i <= cfg_breakNum)
--					end
--				end
			end
			
		end
	end

	local function actionOver( ... )
		print("actionOver")
	end

	animManager:runAnimOnceByCSB(node, "Common/ShipLevelUpNode.csb",  "1", actionOver, onFrameEvent)

	node:setPosition(cc.exports.VisibleRect:center())
	self:addChild(node)

end
function ShipInfoLayer:setPos(node, name )
	local text = node:getChildByName(name)
	local text_now = node:getChildByName(name.."_now")
	local text_next = node:getChildByName(name.."_next")
	local text_jt = node:getChildByName(name.."_jt")

--	text_jt:setPositionX(text_now:getPositionX() + text_now:getContentSize().width + 5)
--	text_next:setPositionX(text_jt:getPositionX() + text_jt:getContentSize().width + 5)

end

function ShipInfoLayer:createShipLevelUpNode( id, now_info, info )
	local conf = CONF.AIRSHIP.get(id)

	local node = require("app.ExResInterface"):getInstance():FastLoad("Common/ShipLevelUpNode.csb")

	local attr_type = {CONF.EShipAttr.kAttack, CONF.EShipAttr.kEnergyAttack, CONF.EShipAttr.kDefence, CONF.EShipAttr.kHP, CONF.EShipAttr.kSpeed}

	node:getChildByName("text1"):setString(CONF:getStringValue("ship_level")..":")
	node:getChildByName("text1_now"):setString(now_info.level)
	node:getChildByName("text1_next"):setString(info.level)

	for i,v in ipairs(attr_type) do
		node:getChildByName("text"..(i+1)):setString(CONF:getStringValue("Attr_"..v)..":")
		node:getChildByName("text"..(i+1).."_now"):setString(now_info.attr[v])
		node:getChildByName("text"..(i+1).."_next"):setString(info.attr[v])
	end

	for i=1,#attr_type do
		self:setPos(node,"text"..i)
	end

	node:getChildByName("back"):setSwallowTouches(true)
	node:getChildByName("back"):addClickEventListener(function ( ... )
		node:removeFromParent()
	end)

	-- tipsAction(node)

	local function setPos( name )
		local nn = node:getChildByName(name)
		local now = node:getChildByName(name.."_now")
		local jt = node:getChildByName(name.."_jt")
		local next = node:getChildByName(name.."_next")

--		now:setPositionX(nn:getPositionX() + nn:getContentSize().width)
--		jt:setPositionX(now:getPositionX() + now:getContentSize().width + 5)
--		next:setPositionX(jt:getPositionX() + jt:getContentSize().width + 5)

		now:setOpacity(255)
		jt:setOpacity(255)
		next:setOpacity(255)
	end

	local function onFrameEvent(frame)
		if nil == frame then
			return
		end
		local str = frame:getEvent()

		if str == "1" then

			local f_node = frame:getNode()

			if f_node:getName() ~= "sj_bottom03_4" then
				setPos(f_node:getName())
			end
		end
	end

	local function actionOver( ... )
		print("actionOver")
	end

	animManager:runAnimOnceByCSB(node, "Common/ShipLevelUpNode.csb",  "1", actionOver, onFrameEvent)

	node:setPosition(cc.exports.VisibleRect:center())
	self:addChild(node)

end


function ShipInfoLayer:refreshInfoNode(node)
	local rn = node
	self.selectedSkillBigPos = nil
	self.selectedEquipBigPos = nil
	self.selectedGemBigPos = nil
	self.selectedEquipGuid = nil
	local cfg_ship = CONF.AIRSHIP.get(self.data_.shipId)
	local ship = player:getShipByGUID(self.data_.guid)

	self:getResourceNode():getChildByName("list"):setVisible(true)

	rn:getChildByName("infoBg"):getChildByName("zhanli"):setString(player:calShipFightPower( self.data_.guid ))

	local energy_name = { {key = "blood", value = CONF.ShipGrowthAttrs.kHP},{key = "atk", value = CONF.ShipGrowthAttrs.kAttack},{key = "defence", value = CONF.ShipGrowthAttrs.kDefence},{key = "e_atk", value = CONF.ShipGrowthAttrs.kEnergyAttack}}
	local attr_name = { {key = "blood", value = CONF.EShipAttr.kHP},{key = "atk", value = CONF.EShipAttr.kAttack},{key = "defence", value = CONF.EShipAttr.kDefence},{key = "e_atk", value = CONF.EShipAttr.kEnergyAttack}}
	local calship = player:calShip(self.data_.guid,true)

	local energy_level = 0
	if ship.energy_exp ~= nil and ship.energy_exp ~= 0 then
		for i,v in ipairs(CONF.ENERGYLEVEL.getIDList()) do
			if ship.energy_exp < CONF.ENERGYLEVEL.get(v).ENERGY_EXP_ALL then
				energy_level = v - 1
				break
			end
		end
	end
	for k,v in pairs(attr_name) do
		local nn = rn:getChildByName(v.key)
		nn:getChildByName("text"):setString(CONF:getStringValue("Attr_"..v.value)..":")
		nn:getChildByName("num"):setString(calship.attr[v.value])
		--nn:getChildByName("num"):setPositionX(nn:getChildByName("text"):getPositionX()+nn:getChildByName("text"):getContentSize().width+5)
	end
	
	for k,v in pairs(energy_name) do
		local nn = rn:getChildByName(v.key)
		nn:getChildByName("add_num"):setString("+"..Tools.getEnergyAddition(ship.id, energy_level, v.value))
		if Tools.getEnergyAddition(ship.id, energy_level, v.value) > 0 then
			-- nn:getChildByName("add_num"):setVisible(true)
		end
		--nn:getChildByName("add_num"):setPositionX(nn:getChildByName("num"):getPositionX()+nn:getChildByName("num"):getContentSize().width+5)
	end

    rn:getChildByName("Text_38"):setString(CONF:getStringValue("state"))
	rn:getChildByName("break"):setString(CONF:getStringValue("break"))
	self:getResourceNode():getChildByName("total"):setString(CONF:getStringValue("pandect"))
	rn:getChildByName("infoBg"):getChildByName("name"):setString(CONF:getStringValue(cfg_ship.NAME_ID))
	rn:getChildByName("infoBg"):getChildByName("quality"):setTexture("ShipQuality/quality_"..cfg_ship.QUALITY..".png")

	rn:getChildByName("text_des1"):setString(CONF:getStringValue("break_level")..":")

	local cfg_break = CONF.SHIP_BREAK.get(cfg_ship.QUALITY)
	local nextLevel = ship.ship_break + 1
	rn:getChildByName("break_num"):setVisible(true)
	if nextLevel > cfg_break.NUM then
		rn:getChildByName("break_num"):setVisible(false)
		rn:getChildByName("break_btn"):setEnabled(false)
		rn:getChildByName("break_btn"):setTouchEnabled(false)
		rn:getChildByName("res1"):setVisible(false)
		rn:getChildByName("res2"):setVisible(false)
		rn:getChildByName("res3"):setVisible(false)
		rn:getChildByName("break_btn"):setVisible(false)
--		rn:getChildByName("stand_bg_1"):setVisible(false)
		rn:getChildByName("text_des1"):setString(CONF:getStringValue("break_now")..":"..ship.ship_break)
		nextLevel = cfg_break.NUM
	else
		rn:getChildByName("break_btn"):setEnabled(true)
		rn:getChildByName("break_btn"):setTouchEnabled(true)
	end
	rn:getChildByName("break_num"):setString(cfg_break["NEED_LEVEL"..nextLevel])
	if ship.level >= cfg_break["NEED_LEVEL"..nextLevel] then
		rn:getChildByName("break_num"):setTextColor(cc.c4b(51,231,51,255))
		-- rn:getChildByName("break_num"):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
	else
		rn:getChildByName("break_num"):setTextColor(cc.c4b(233,50,59,255))
		-- rn:getChildByName("break_num"):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
	end
	rn:getChildByName("break_num"):setPositionX(rn:getChildByName("text_des1"):getPositionX()+rn:getChildByName("text_des1"):getContentSize().width+5)
	local item = {}
	for k,v in ipairs(cfg_break["ITEM_ID"..nextLevel]) do
		local t = {}
		t.id = v
		t.num = cfg_break["ITEM_NUM"..nextLevel][k]
		table.insert(item,t)
	end
	local t = {}
	t.num = CONF.SHIP_BLUEPRINTBREAK.get(cfg_ship.QUALITY)["ITEM_NUM"..nextLevel]
	t.id = self.data_.blueprintId
	table.insert(item,t)
	for k,v in ipairs(item) do
		if rn:getChildByName("res"..k) then
			local item = CONF.ITEM.get(v.id)
			rn:getChildByName("res"..k):getChildByName("Sprite_2"):setTexture("RankLayer/ui/ui_avatar_" .. item.QUALITY .. ".png")
			rn:getChildByName("res"..k):getChildByName("icon"):setTexture("ItemIcon/"..item.ICON_ID..".png")
			rn:getChildByName("res"..k):getChildByName("num"):setString(formatRes(player:getItemNumByID(v.id)))
			if player:getItemNumByID(v.id) >= v.num then
				rn:getChildByName("res"..k):getChildByName("num"):setTextColor(cc.c4b(51,231,51,255))
				-- rn:getChildByName("res"..k):getChildByName("num"):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
			else
				rn:getChildByName("res"..k):getChildByName("num"):setTextColor(cc.c4b(233,50,59,255))
				-- rn:getChildByName("res"..k):getChildByName("num"):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
			end
			rn:getChildByName("res"..k):getChildByName("text"):setString("/"..formatRes(v.num))
			--rn:getChildByName("res"..k):getChildByName("text"):setPositionX(rn:getChildByName("res"..k):getChildByName("num"):getPositionX()+rn:getChildByName("res"..k):getChildByName("num"):getContentSize().width+2)
			rn:getChildByName("res"..k):getChildByName("Image_1"):addClickEventListener(function()
				self:removeTips()
				local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(v.id,CONF.ETipsType.kItem)
				info_node:setPosition(self:getResourceNode():getChildByName("Node_pos"):getPosition())
				info_node:setName("info_node")
				self:getResourceNode():addChild(info_node)
				end)
		end
	end
	rn:getChildByName("break_num"):setString(cfg_break["NEED_LEVEL"..nextLevel])
	rn:getChildByName("break_btn"):getChildByName("text"):setString(CONF:getStringValue("break"))
	rn:getChildByName("break_btn"):addClickEventListener(function()
		self:removeTips()
		local canBreak = true
		for k,v in ipairs(item) do
			if player:getItemNumByID(v.id) < v.num then
				canBreak = false
				break
			end
		end
		if ship.ship_break >=  cfg_break.NUM then
			tips:tips(CONF:getStringValue("max_level"))
			return
		end
		if ship.level < cfg_break["NEED_LEVEL"..(ship.ship_break+1)] then
			tips:tips(CONF:getStringValue("ship_level_not_enought"))
			return
		end 
		if canBreak then
			if Bit:has(ship.status, 4) == true then
				tips:tips(CONF:getStringValue("ship lock"))
				return
			end
			local strData = Tools.encode("ShipBreakReq", {
				ship_guid = ship.guid,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_BREAK_REQ"),strData)

			gl:retainLoading()
		else
			tips:tips(CONF:getStringValue("Material_not_enought"))
			local jumpTab = {}
			for k,v in ipairs(item) do
				if player:getItemNumByID(v.id) < v.num then
					local cfg_item = CONF.ITEM.get(v.id)
					if cfg_item and cfg_item.JUMP then
						table.insert(jumpTab,cfg_item.JUMP)
					end
				end
			end
			if Tools.isEmpty(jumpTab) == false and not self:getChildByName("JumpChoseLayer") then
				jumpTab.scene = "ShipInfoLayer"
				local center = cc.exports.VisibleRect:center()
				local layer = app:createView("ShipsScene/JumpChoseLayer",jumpTab)
				layer:setName("JumpChoseLayer")
				tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
				self:addChild(layer)
			end
		end
		end)
	local param 
	if ship.ship_break == 0 then
		param = 0
	else
		param = CONF.PARAM.get("ship_break_"..ship.ship_break).PARAM
	end

	local shipNow = player:calShipByInfo(ship,true)
	local cloneShip = Tools.clone(ship)
	cloneShip.ship_break = cloneShip.ship_break and cloneShip.ship_break + 1 or 1
	local shipBreak = player:calShipByInfo(cloneShip,true)

	local cfg_breakNum = CONF.SHIP_BREAK.get(cfg_ship.QUALITY).NUM

	local ship = player:getShipByGUID(self.data_.guid)
	local maxEnemy = CONF.ENERGYLEVEL.get(CONF.ENERGYLEVEL.count()-1).ENERGY_EXP_ALL
	local energy_level = 0
	if ship.energy_exp ~= nil and ship.energy_exp ~= 0 then
		for i,v in ipairs(CONF.ENERGYLEVEL.getIDList()) do
			if ship.energy_exp < CONF.ENERGYLEVEL.get(v).ENERGY_EXP_ALL then
				energy_level = v - 1
				break
			end
		end
		if ship.energy_exp >= maxEnemy then
			energy_level = CONF.ENERGYLEVEL.count()-1
		end
	end
	local energy_conf = CONF.ENERGYLEVEL.get(energy_level)
	local now_percent
	if energy_level ~= 0 then
	 	now_percent= math.floor(ship.energy_exp - CONF.ENERGYLEVEL.get(energy_level).ENERGY_EXP_ALL)
	else
		now_percent= math.floor(ship.energy_exp)
	end

	local energyPro = require("util.ScaleProgressDelegate"):create(rn:getChildByName("infoBg"):getChildByName("energy_jindu"), 240)
	local p = now_percent/energy_conf.ENERGY_EXP*100
	if p < 0 then p = 0 end
	if p > 100 then p = 100 end
	energyPro:setPercentage(p)

	rn:getChildByName("infoBg"):getChildByName("energyLv"):setString(energy_level) 

	if rn:getChildByName("infoBg"):getChildByName("energy_jindu"):getChildByName("max_sprite") then
		rn:getChildByName("infoBg"):getChildByName("energy_jindu"):getChildByName("max_sprite"):removeFromParent()
	end

	if ship.energy_exp and ship.energy_exp ~= 0 then
		local maxEnemy = CONF.ENERGYLEVEL.get(CONF.ENERGYLEVEL.count()-1).ENERGY_EXP_ALL
		if ship.energy_exp >= maxEnemy then
			local sprite = cc.Sprite:create("StarLeagueScene/ui/MAX.png")

			sprite:setPosition(rn:getChildByName("infoBg"):getChildByName("energy_jindu"):getContentSize().width/2, rn:getChildByName("energy_jindu"):getContentSize().height /2)
			sprite:setName("max_sprite")
			rn:getChildByName("infoBg"):getChildByName("energy_jindu"):addChild(sprite)
		end	
	end

	local energyParam = CONF.PARAM.get("nlc_open").PARAM;
	if player:getLevel() < energyParam[1] or player:getBuildingInfo(1).level < energyParam[2] then
		--rn:getChildByName("infoBg"):getChildByName("energylv"):setVisible(false);
		--rn:getChildByName("infoBg"):getChildByName("energy_bg"):setVisible(false);
		--rn:getChildByName("infoBg"):getChildByName("energy_jindu"):setVisible(false);
		--rn:getChildByName("infoBg"):getChildByName("add_energy"):setVisible(false);
		rn:getChildByName("infoBg"):getChildByName("open"):setVisible(true)
	else
		rn:getChildByName("infoBg"):getChildByName("open"):setVisible(true);
		--rn:getChildByName("infoBg"):getChildByName("energylv"):setVisible(true);
		--rn:getChildByName("infoBg"):getChildByName("energy_bg"):setVisible(true);
		--rn:getChildByName("infoBg"):getChildByName("energy_jindu"):setVisible(true);
		--rn:getChildByName("infoBg"):getChildByName("add_energy"):setVisible(true);
	end

	local function addExp( ... )
		local exp_node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ShipAddExp.csb")
		exp_node:getChildByName("name"):setString(CONF:getStringValue("FullLevelToBreakthrough"))
		exp_node:getChildByName("yijian_use"):getChildByName("text"):setString(CONF:getStringValue("fast_use"))
		exp_node:getChildByName("bg"):setSwallowTouches(true)
		exp_node:getChildByName("bg"):addClickEventListener(function ( ... )
			exp_node:removeFromParent()
		end)

		exp_node:getChildByName("m_bottom2_17"):setSwallowTouches(true)

		exp_node:getChildByName("use"):getChildByName("text"):setString(CONF:getStringValue("use"))

		local info = player:getShipByGUID(self.data_.guid)

		exp_node:getChildByName("lv"):setString("Lv."..info.level)

		if info.level == 1 then
			exp_node:getChildByName("break_now_num"):setString(info.exp)
			exp_node:getChildByName("break_max_num"):setString("/"..CONF.SHIPLEVEL.get(1).EXP_ALL)
		else
			exp_node:getChildByName("break_now_num"):setString(info.exp - CONF.SHIPLEVEL.get(info.level-1).EXP_ALL)
			exp_node:getChildByName("break_max_num"):setString("/"..CONF.SHIPLEVEL.get(info.level).EXP_ALL - CONF.SHIPLEVEL.get(info.level-1).EXP_ALL)
		end
		exp_node:getChildByName("break_max_num"):setPositionX(exp_node:getChildByName("break_now_num"):getPositionX() + exp_node:getChildByName("break_now_num"):getContentSize().width)

		local bs = cc.size(11*24.985, 12)
		local cap = cc.rect(6,6,7,19)
		self.progress = require("util.ClippingScaleProgressDelegate"):create("Common/ui/ui_progress_light1.png", 292, {capinsets = cap, bg_size = bs, lightLength = 3})

		exp_node:addChild(self.progress:getClippingNode())
		self.progress:getClippingNode():setPosition(cc.p(exp_node:getChildByName("progress_back"):getPosition()))

		if info.level == 1 then
			self.progress:setPercentage(info.exp/CONF.SHIPLEVEL.get(1).EXP_ALL*100)
		else
			self.progress:setPercentage((info.exp - CONF.SHIPLEVEL.get(info.level-1).EXP_ALL)/(CONF.SHIPLEVEL.get(info.level).EXP_ALL - CONF.SHIPLEVEL.get(info.level-1).EXP_ALL)*100)
		end

		local function clickExp( sender )

			local item_id = sender:getParent():getTag()
			if player:getItemNumByID(item_id) == 0 then
				tips:tips(CONF:getStringValue("item not enought"))
				return
			end

			for i=1,4 do
				if i == sender:getTag() then
					exp_node:getChildByName("exp_"..i):getChildByName("bg_light"):setVisible(true)
				else
					exp_node:getChildByName("exp_"..i):getChildByName("bg_light"):setVisible(false)
				end
			end

			exp_node:getChildByName("use"):setEnabled(true)
			exp_node:getChildByName("use"):setTouchEnabled(true)
			exp_node:getChildByName("yijian_use"):setEnabled(true)
			exp_node:getChildByName("yijian_use"):setTouchEnabled(true)
		end

		for i=1,4 do
			local exp = exp_node:getChildByName("exp_"..i)
			local item_conf = CONF.ITEM.get(13000+i)

			exp:getChildByName("icon_di"):loadTexture("RankLayer/ui/ui_avatar_"..item_conf.QUALITY..".png")
			exp:getChildByName("icon"):loadTexture("ItemIcon/"..item_conf.ICON_ID..".png")
			exp:getChildByName("exp_num"):setString("+"..item_conf.VALUE)
			exp:getChildByName("name"):setString(CONF:getStringValue(item_conf.NAME_ID))

			exp:getChildByName("have_num"):setString(player:getItemNumByID(item_conf.ID))

			if tonumber(exp:getChildByName("have_num"):getString()) == 0 then
				exp:getChildByName("have_num"):setTextColor(cc.c4b(255,145,136,255))
				-- exp:getChildByName("have_num"):enableShadow(cc.c4b(255,145,136,255), cc.size(0.5,0.5))
			end

			exp:getChildByName("bg"):setTag(i)
			exp:setTag(13000+i)

			exp:getChildByName("bg"):addClickEventListener(clickExp)
		end

		exp_node:getChildByName("use"):setEnabled(false)
		exp_node:getChildByName("use"):setTouchEnabled(false)
		exp_node:getChildByName("yijian_use"):setEnabled(false)
		exp_node:getChildByName("yijian_use"):setTouchEnabled(false)
		exp_node:getChildByName("yijian_use"):addClickEventListener(function()
			if player:getShipByGUID(info.guid).exp == CONF.SHIPLEVEL.get(player:getLevel()).EXP_ALL then
				tips:tips(CONF:getStringValue("ship exp full"))
				return
			end

			local item_id = 0 
			for i=1,4 do
				local exp = exp_node:getChildByName("exp_"..i)
				if exp:getChildByName("bg_light"):isVisible() then
					item_id = exp:getTag()
					break
				end
			end
			if item_id == 0 then
				return
			end
			local conf_oneItemExp = CONF.ITEM.get(item_id).VALUE
			local maxTotalExp = CONF.SHIPLEVEL.get(player:getLevel()).EXP_ALL
			local nowExp = player:getShipByGUID(info.guid).exp
			local needNum = math.ceil((maxTotalExp - nowExp)/conf_oneItemExp)
			if needNum >= player:getItemNumByID(item_id) then
				needNum = player:getItemNumByID(item_id)
			end


			local item_id_list = {item_id}
			local item_num_list = {needNum}

			local strData = Tools.encode("ShipAddExpReq", {
				ship_guid = info.guid,
				item_id_list = item_id_list,
				item_num_list = item_num_list,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_ADD_EXP_REQ"),strData)

			gl:retainLoading() 

			end)
		exp_node:getChildByName("use"):addClickEventListener(function ( ... )

			if player:getShipByGUID(info.guid).exp == CONF.SHIPLEVEL.get(player:getLevel()).EXP_ALL then
				tips:tips(CONF:getStringValue("ship exp full"))
				return
			end

			local item_id = 0 
			for i=1,4 do
				local exp = exp_node:getChildByName("exp_"..i)
				if exp:getChildByName("bg_light"):isVisible() then
					item_id = exp:getTag()
					break
				end
			end
			if item_id == 0 then
				return
			end
			local item_id_list = {item_id}
			local item_num_list = {1}

			local strData = Tools.encode("ShipAddExpReq", {
				ship_guid = info.guid,
				item_id_list = item_id_list,
				item_num_list = item_num_list,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_ADD_EXP_REQ"),strData)

			gl:retainLoading()  
		end)

		-- exp_node:setPosition(cc.exports.VisibleRect:center())
		exp_node:setPosition(cc.p(self:getResourceNode():getChildByName("ui_icon_ship"):getPositionX() - 80, self:getResourceNode():getChildByName("ui_icon_ship"):getPositionY()))
		exp_node:setName("exp_node")
		self:getResourceNode():addChild(exp_node,2)
	end

	rn:getChildByName("infoBg"):getChildByName("add_exp"):addClickEventListener(function()
		local ship = player:getShipByGUID(self.data_.guid)
		playEffectSound("sound/system/click.mp3")
		self:removeTips()
		if Bit:has(ship.status, 4) == true then
			tips:tips(CONF:getStringValue("ship lock"))
			return
		end
		addExp()
	end)

	rn:getChildByName("infoBg"):getChildByName("add_energy"):addClickEventListener(function ()
		if player:getLevel() < energyParam[1] then
			tips:tips(CONF:getStringValue("grade")..energyParam[1]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
			return
		end
		if player:getBuildingInfo(1).level < energyParam[2] then
			tips:tips(CONF:getStringValue("BuildingName_1")..energyParam[2]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
			return
		end
		self:removeTips()
		if self.selectType ~= 4 then
			self.selectType = 4
			self:changeBtnType()
		end
	end)

	rn:getChildByName("detail"):addClickEventListener(function ()
		local center = cc.exports.VisibleRect:center()
		local layer = self:getApp():createView("ShipsScene/ShipDetailLayer",self.data_)
		tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
		self:addChild(layer)
	end)
	rn:getChildByName("detail"):getChildByName("text"):setString(CONF:getStringValue("ships_details"))

	local expProgressNode = require("util.ScaleProgressDelegate"):create(rn:getChildByName("infoBg"):getChildByName("exp_jindu"), 300)

	local expNum = 0
	local param = CONF.PARAM.get("nlc_open").PARAM
	if ship.exp == nil then
		ship.exp = 0
	end
	if ship.level > 1 then
		expNum = ship.exp - CONF.SHIPLEVEL.get(ship.level-1).EXP_ALL
	else
		expNum = ship.exp
	end
	expProgressNode:setPercentage(expNum/CONF.SHIPLEVEL.get(ship.level).EXP*100)
	local s = string.gsub(CONF:getStringValue("foster open"),"#",param[1])
	rn:getChildByName("infoBg"):getChildByName("expNum"):setString(tostring(expNum).."/"..tostring(CONF.SHIPLEVEL.get(ship.level).EXP))
	rn:getChildByName("infoBg"):getChildByName("dengji"):setString(CONF:getStringValue("level") ..":");
	rn:getChildByName("infoBg"):getChildByName("ship_lv"):setString(ship.level);
	rn:getChildByName("infoBg"):getChildByName("open"):setString(s);
	rn:getChildByName("infoBg"):getChildByName("peiyang"):setString(CONF:getStringValue("ship_develop")..":");
	self:getResourceNode():getChildByName("left"):getChildByName("zhanli"):setString( player:calShipFightPower( self.data_.guid ))

end

function ShipInfoLayer:refreshSkillNode(node)

	local rn = self:getResourceNode()
	rn:getChildByName("total"):setString(CONF:getStringValue("weapon"))
	rn:getChildByName("list"):setVisible(false)
	if Tools.isEmpty(node:getChildByName("Weapon_bag_list"):getChildren()) == false then
		for k,v in ipairs(node:getChildByName("Weapon_bag_list"):getChildren()) do
			v:getChildByName("select_light"):setVisible(false)
		end
	end
	local info = player:getShipByGUID(self.data_.guid)
	for i =1,4 do
		 node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..i):getChildByName("select_light"):setVisible(false)
	end

	self.selectedGemBigPos = nil
	self.selectedEquipBigPos = nil
	self.selectedEquipGuid = nil
	if self.selectedSkillBigPos then
		node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..(self.selectedSkillBigPos+1)):getChildByName("select_light"):setVisible(true)
		if info.weapon_list[self.selectedSkillBigPos] ~= 0 then
			local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(info.weapon_list[self.selectedSkillBigPos],CONF.ETipsType.kSkill,true,{ship_guid = self.data_.guid,pos = self.selectedSkillBigPos})
			info_node:setPosition(rn:getChildByName("Node_pos"):getPosition())
			info_node:setName("info_node")
			rn:addChild(info_node)
		end
	end
	
	local skill1 = node:getChildByName("Weapon_list"):getChildByName("WeaponNode_1")
	skill1:getChildByName("icon"):loadTexture("WeaponIcon/"..CONF.WEAPON.get(info.skill).ICON_ID..".png")
	skill1:getChildByName("ban"):getChildByName("lv_num"):setString(CONF.WEAPON.get(info.skill).LEVEL)
	node:getChildByName("Weapon_list"):getChildByName("text_1"):setString(CONF:getStringValue("weapon_text_1"))
	node:getChildByName("Weapon_list"):getChildByName("text_2"):setString(CONF:getStringValue("weapon_text_2"))
	node:getChildByName("Weapon_list"):getChildByName("text_3"):setString(CONF:getStringValue("weapon_text_3"))
	node:getChildByName("Weapon_list"):getChildByName("text_4"):setString(CONF:getStringValue("weapon_text_4"))

	if self.skillList == nil then
		self.skillList = require("util.ScrollViewDelegate"):create(node:getChildByName("Weapon_bag_list") ,cc.size(3,0), cc.size(75 ,75)) 
	else
		self.skillList:clear()
	end
	self.skillList:getScrollView():setScrollBarEnabled(false)
	local function createSkill(info,node)
		node:getChildByName("icon"):loadTexture("WeaponIcon/"..CONF.WEAPON.get(player:getWeaponByGUID(info.guid).weapon_id).ICON_ID..".png")
		node:getChildByName("ban"):getChildByName("lv_num"):setString(CONF.WEAPON.get(player:getWeaponByGUID(info.guid).weapon_id).LEVEL)
	end
	local refreshSkillList = function()
		self.skillList:clear()
		local info = player:getShipByGUID(self.data_.guid)
		local list = player:getWeaponList()
		node:getChildByName("Text"):setVisible(false)
		if not Tools.isEmpty(list) then 
			for k,v in ipairs(list) do
				if CONF.WEAPON.get(v.weapon_id).TYPE == info.type then
					local nohave = true
					for k1,v1 in ipairs(info.weapon_list) do
						if k1 and info.weapon_list[k1] ~= 0 then
							if v.weapon_id == player:getWeaponByGUID(info.weapon_list[k1]).weapon_id then
								nohave = false
							end
						end
					end
					if nohave then
						local node1 = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/ShipWeaponNode.csb")
						node1:getChildByName("bg"):setTag(v.guid)
						createSkill(v,node1)
						local function func()
							self:removeTips()
							local list = node:getChildByName("Weapon_bag_list")
							if Tools.isEmpty(list:getChildren()) == false then
								for k,v in ipairs(list:getChildren()) do
									v:getChildByName("select_light"):setVisible(false)
								end
							end
							node1:getChildByName("select_light"):setVisible(true)
							local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(v.guid,CONF.ETipsType.kSkill,false,{ship_guid = self.data_.guid,pos = self.selectedSkillBigPos})
							info_node:setPosition(rn:getChildByName("Node_pos"):getPositionX(),rn:getChildByName("Node_pos"):getPositionY())
							info_node:setName("info_node")
							rn:addChild(info_node)
						end
						local callback = {node = node1:getChildByName("bg"), func = func}
						self.skillList:addElement(node1,{callback = callback})
					end
				end
			end
		else
			node:getChildByName("Text"):setVisible(true)
			node:getChildByName("Text"):setString(CONF:getStringValue("no_weapon_now"))
		end
	end

	refreshSkillList()

	for i=1,4 do
		node:getChildByName("Weapon_list"):getChildByName("selected_"..i):setVisible(false)
		node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..i):getChildByName("ban"):setVisible(false)
	end
	node:getChildByName("go"):getChildByName("Text"):setString(CONF:getStringValue("weapon_research"))
	node:getChildByName("go"):addClickEventListener(function()
		self:removeTips()
		self:getApp():pushView("WeaponDevelopScene/WeaponScene")
		-- self:removeFromParent()
		end)
	skill1:getChildByName("ban"):setVisible(true)
	for i,v in ipairs(info.weapon_list) do
		local index = i+1
		node:getChildByName("Weapon_list"):getChildByName("suo_"..index):setVisible(false)
		node:getChildByName("Weapon_list"):getChildByName("add_"..index):setVisible(false)
		if v ~= 0 then
			node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..index):getChildByName("icon"):setVisible(true)
			node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..index):getChildByName("icon"):loadTexture("WeaponIcon/"..CONF.WEAPON.get(player:getWeaponByGUID(v).weapon_id).ICON_ID..".png")
			node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..index):getChildByName("ban"):setVisible(true)
			node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..index):getChildByName("ban"):getChildByName("lv_num"):setString(CONF.WEAPON.get(player:getWeaponByGUID(v).weapon_id).LEVEL)
			node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..index):getChildByName("bg"):setTag(i)
		else
			node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..index):getChildByName("icon"):setVisible(false)
			if info.level < CONF.PARAM.get("open_small_weapon").PARAM[i] then
				node:getChildByName("Weapon_list"):getChildByName("suo_"..index):setVisible(true)
				node:getChildByName("Weapon_list"):getChildByName("add_"..index):setVisible(false)
			else
				node:getChildByName("Weapon_list"):getChildByName("add_"..index):setVisible(true)
				node:getChildByName("Weapon_list"):getChildByName("suo_"..index):setVisible(false)
			end
		end
		node:getChildByName("Weapon_list"):getChildByName("bg_"..index):addClickEventListener(function()
			if node:getChildByName("Weapon_list"):getChildByName("suo_"..index):isVisible() then
				if info.level < CONF.PARAM.get("open_small_weapon").PARAM[i] then
					tips:tips(CONF:getStringValue("Airship")..CONF.PARAM.get("open_small_weapon").PARAM[i]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
					return
				end
			end
			local info = player:getShipByGUID(self.data_.guid)
			self.selectedSkillBigPos = i
			self:removeTips()
			refreshSkillList()
			local list = node:getChildByName("Weapon_bag_list")
			if Tools.isEmpty(list:getChildren()) == false then
				for k,v in ipairs(list:getChildren()) do
					v:getChildByName("select_light"):setVisible(false)
				end
			end
			for i =1,4 do
				 node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..i):getChildByName("select_light"):setVisible(false)
			end
			node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..index):getChildByName("select_light"):setVisible(true)
			if info.weapon_list[i] == 0 then
				return
			end
			local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(info.weapon_list[i],CONF.ETipsType.kSkill,true,{ship_guid = self.data_.guid,pos = index-1})
			info_node:setPosition(rn:getChildByName("Node_pos"):getPosition())
			info_node:setName("info_node")
			rn:addChild(info_node)
			end)
		node:getChildByName("Weapon_list"):getChildByName("bg_"..index):setTag(v)
	end
	-- bg_1
	node:getChildByName("Weapon_list"):getChildByName("bg_1"):addClickEventListener(function()
		self:removeTips()
		self.skillList:clear()
		self.selectedSkillBigPos = nil
		local list = node:getChildByName("Weapon_bag_list")
		if Tools.isEmpty(list:getChildren()) == false then
			for k,v in ipairs(list:getChildren()) do
				v:getChildByName("select_light"):setVisible(false)
			end
		end
		for i =1,4 do
			 node:getChildByName("Weapon_list"):getChildByName("WeaponNode_"..i):getChildByName("select_light"):setVisible(false)
		end
		node:getChildByName("Weapon_list"):getChildByName("WeaponNode_1"):getChildByName("select_light"):setVisible(true)
		local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(CONF.AIRSHIP.get(self.data_.shipId).SKILL,CONF.ETipsType.kSkill,false)
		info_node:setPosition(rn:getChildByName("Node_pos"):getPosition())
		info_node:setName("info_node")
		rn:addChild(info_node)
		end)
	node:getChildByName("Weapon_list"):getChildByName("Text"):setString(CONF:getStringValue("hint_weapon"))
    node:getChildByName("Weapon_list"):getChildByName("Text_0"):setString(CONF:getStringValue("Skill_order"))
	rn:getChildByName("left"):getChildByName("zhanli"):setString( player:calShipFightPower( self.data_.guid ))
end


function ShipInfoLayer:refreshEquipNode(node)

	local rn = self:getResourceNode()
	local ship = player:getShipByGUID(self.data_.guid)
	self:getResourceNode():getChildByName("total"):setString(CONF:getStringValue("equip"))
	self:getResourceNode():getChildByName("list"):setVisible(false)
	node:getChildByName("Text"):setString(CONF:getStringValue("no_equip_now"))
	node:getChildByName("equip_list"):getChildByName("Text_0"):setString(CONF:getStringValue("hint_equip"))
	if self.equipList == nil then
		self.equipList = require("util.ScrollViewDelegate"):create(node:getChildByName("equip_bag_list") ,cc.size(3,0), cc.size(75 ,75))
	else
		self.equipList:clear()
	end
	for i=1,4 do
		node:getChildByName("equip_list"):getChildByName("EquipNode_"..i):getChildByName("selected"):setVisible(false)
	end
	self.selectedSkillBigPos = nil
	self.selectedGemBigPos = nil
	if self.selectedEquipBigPos then
		node:getChildByName("equip_list"):getChildByName("EquipNode_"..self.selectedEquipBigPos):getChildByName("selected"):setVisible(true)
	end
	node:getChildByName("equip_bag_list"):setScrollBarEnabled(false)
	node:getChildByName("strong"):getChildByName("Text"):setString(CONF:getStringValue("fast_equip"))
	node:getChildByName("strong"):addClickEventListener(function()

		local myinfo = player:getShipByGUID(self.data_.guid)
		if Bit:has(myinfo.status, 4) == true then
			tips:tips(CONF:getStringValue("ship lock"))
			return
		end
		local haveType = {}
		for k,v in ipairs(myinfo.equip_list) do
			if v ~= 0 and player:getEquipByGUID(v) then
				local ec = CONF.EQUIP.get(player:getEquipByGUID(v).equip_id)
				table.insert(haveType,ec.TYPE)
			end
		end
		local canEquipGuidList = {}
		local canEquipTypeList = {}
		for i=1,4 do
			local noHave = true
			for k,v in ipairs(haveType) do
				if i == v then
					noHave = false
				end
			end
			if true or noHave then
				local equips = player:getAllUnequipListWithType(i,self.data_.guid)
				if Tools.isEmpty(equips) == false then
					local function sort( a,b )
						if a.level ~= b.level then
							return a.level > b.level
						else
							if a.quality ~= b.quality then
								return a.quality > b.quality 
							else
								if a.strength ~= b.strength then
									return a.strength > b.strength
								else
									return a.guid < b.guid
								end
							end
						end
					end

					table.sort( equips, sort )
					for k,v in ipairs(equips) do
						if v.level <= myinfo.level then
							if v.ship_id ~= self.data_.guid then
								table.insert(canEquipGuidList,v.guid)
								table.insert(canEquipTypeList,i)
							end
							break
						end
					end
				end
			end
		end
		if Tools.isEmpty(canEquipGuidList) == false then
			local strData = Tools.encode("ShipEquipReq", {

				ship_guid = myinfo.guid,
				equip_index_list = canEquipTypeList,
				equip_guid_list = canEquipGuidList,
			})

			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_EQUIP_REQ"),strData)
			self:removeTips()
			gl:retainLoading()
		else
			tips:tips(CONF:getStringValue("no_other_equip"))
		end
		end)
	local equips = player:getBagEquips()
	table.sort(equips,function(a,b)
		if a.type == b.type then
			if a.equip_id == b.equip_id then
				return a.guid < b.guid
			else
				return a.equip_id > b.equip_id
			end
		else
			return a.type < b.type
		end
		end)
	local function createItem(item,equip)
		local cfg_item = CONF.ITEM.get(item.equip_id)
		equip:getChildByName("icon"):setVisible(true)
		equip:getChildByName("shadow"):setVisible(true)
		equip:getChildByName("num"):setVisible(true)
		equip:getChildByName("icon"):loadTexture("ItemIcon/"..cfg_item.ICON_ID..".png")
		equip:getChildByName("num"):setString("Lv."..item.level)
		equip:getChildByName("level_num"):setString("+"..item.strength)
		equip:getChildByName("level_num"):setVisible(item.strength > 0)
		equip:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_" .. cfg_item.QUALITY .. ".png")
	end 
	local refreshEquip = function()
		local show = true
		self.equipList:clear()
		local equips = player:getBagEquips()
		table.sort(equips,function(a,b)
			if a.type == b.type then
				if a.equip_id == b.equip_id then
					return a.guid < b.guid
				else
					return a.equip_id > b.equip_id
				end
			else
				return a.type < b.type
			end
			end)
		for k,v in ipairs(equips) do
			if v.ship_id == 0 and (self.selectedEquipBigPos and self.selectedEquipBigPos == v.type) then
				show = false
				local equip = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/Item.csb")
				createItem(v,equip)
				equip:setTag(v.guid)
				local function func()
					self:removeTips()
					local list = node:getChildByName("equip_bag_list")
					if Tools.isEmpty(list:getChildren()) == false then
						for k,v in ipairs(list:getChildren()) do
							v:getChildByName("selected"):setVisible(false)
						end
					end
					equip:getChildByName("selected"):setVisible(true)
					local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(v.guid,CONF.ETipsType.kEquip,false,{ship_guid = self.data_.guid,pos = 0})
					info_node:setPosition(rn:getChildByName("Node_pos"):getPositionX(),rn:getChildByName("Node_pos"):getPositionY())
					info_node:setName("info_node")
					rn:addChild(info_node)
					self.selectedEquipGuid = v.guid
				end
				
				if not systemGuideManager:getGuideType() then
					local callback = {node = equip:getChildByName("background"), func = func}
					self.equipList:addElement(equip,{callback = callback})
				else
					equip:getChildByName("Image_1"):setVisible(true)
					equip:getChildByName("Image_1"):addClickEventListener(function()
						func()
						end)
					self.equipList:addElement(equip)
					node:getChildByName("equip_bag_list"):setTouchEnabled(false)
				end
			end
		end
		node:getChildByName("Text"):setVisible(show)
	end
	refreshEquip()
	for i=1,4 do
		local equip = node:getChildByName("equip_list"):getChildByName("EquipNode_"..i)
		equip:getChildByName("text"):setVisible(true)
		equip:getChildByName("text"):setString(CONF:getStringValue("Equip_type_"..i))
		equip:getChildByName("background"):setVisible(true)
		equip:getChildByName("icon"):loadTexture("ShipsScene/ui2/hole_3.png")
		equip:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_3.png")
		equip:getChildByName("shadow"):setVisible(false)
		equip:getChildByName("num"):setVisible(false)
		equip:getChildByName("level_num"):setVisible(false)
	end
	for k,v in ipairs(equips) do
		if v.ship_id and v.ship_id == self.data_.guid then
			if self.selectedEquipBigPos and self.selectedEquipBigPos == v.type and not self.selectedEquipGuid then
				local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(v.guid,CONF.ETipsType.kEquip,true,{ship_guid = self.data_.guid,pos = 0})
				info_node:setPosition(rn:getChildByName("Node_pos"):getPositionX(),rn:getChildByName("Node_pos"):getPositionY())
				info_node:setName("info_node")
				rn:addChild(info_node)
			end
			local equip = node:getChildByName("equip_list"):getChildByName("EquipNode_"..v.type)
			createItem(v,equip)
			equip:getChildByName("text"):setVisible(false)
		end
	end
	if self.selectedEquipGuid then
		node:getChildByName("equip_bag_list"):getChildByTag(self.selectedEquipGuid):getChildByName("selected"):setVisible(true)
		local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(self.selectedEquipGuid,CONF.ETipsType.kEquip,false,{ship_guid = self.data_.guid,pos = 0})
		info_node:setPosition(rn:getChildByName("Node_pos"):getPositionX(),rn:getChildByName("Node_pos"):getPositionY())
		info_node:setName("info_node")
		rn:addChild(info_node)
	end
	for i=1,4 do
		node:getChildByName("equip_list"):getChildByName("Image_"..i):addClickEventListener(function()
			self.selectedEquipGuid = nil
			self.selectedEquipBigPos = i
			self:removeTips()
			refreshEquip()
			local list = node:getChildByName("equip_bag_list")
			if Tools.isEmpty(list:getChildren()) == false then
				for k,v in ipairs(list:getChildren()) do
					v:getChildByName("selected"):setVisible(false)
				end
                node:getChildByName("forge"):setVisible(false)
			else
				node:getChildByName("Text"):setString(CONF:getStringValue("no_equip_now"))
                node:getChildByName("forge"):setVisible(true)
                node:getChildByName("forge"):getChildByName("Text"):setString(CONF:getStringValue("equip")..CONF:getStringValue("forge_title"))
                node:getChildByName("forge"):addClickEventListener(function()
                    goScene(2,13,nil,{kind = 1,mode = i}) -- gotoforge
                end)
			end
			for i=1,4 do
				node:getChildByName("equip_list"):getChildByName("EquipNode_"..i):getChildByName("selected"):setVisible(false)
			end
			node:getChildByName("equip_list"):getChildByName("EquipNode_"..i):getChildByName("selected"):setVisible(true)
			local equips = player:getBagEquips()
			table.sort(equips,function(a,b)
				if a.type == b.type then
					if a.equip_id == b.equip_id then
						return a.guid < b.guid
					else
						return a.equip_id > b.equip_id
					end
				else
					return a.type < b.type
				end
				end)
			for k,v in ipairs(equips) do
				if v.ship_id and v.ship_id == self.data_.guid and v.type == i then
					local equip = node:getChildByName("equip_list"):getChildByName("EquipNode_"..v.type)
					equip:getChildByName("text"):setVisible(false)
					local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(v.guid,CONF.ETipsType.kEquip,true,{ship_guid = self.data_.guid,pos = 0})
					info_node:setPosition(rn:getChildByName("Node_pos"):getPositionX(),rn:getChildByName("Node_pos"):getPositionY())
					info_node:setName("info_node")
					rn:addChild(info_node)
				end
			end
		end)
	end
	if not self.selectedEquipBigPos then
		local list = node:getChildByName("equip_bag_list")
		if Tools.isEmpty(list:getChildren()) then
			node:getChildByName("Text"):setString(CONF:getStringValue("choose equip"))
            node:getChildByName("forge"):setVisible(false)
		end
	end
	rn:getChildByName("left"):getChildByName("zhanli"):setString( player:calShipFightPower( self.data_.guid ))
end

function ShipInfoLayer:refreshGemNode(node)


	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kGem)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("kj_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end

	local rn = self:getResourceNode()
	self.selectedEquipBigPos = nil
	self.selectedSkillBigPos = nil
	self.selectedEquipGuid = nil
	rn:getChildByName("list"):setVisible(false)
	rn:getChildByName("total"):setString(CONF:getStringValue("gem"))
	local ship = player:getShipByGUID(self.data_.guid)
	local gems = player:getAllUnGemList()
	local conf = CONF.AIRSHIP.get(self.data_.shipId)
	node:getChildByName("Text"):setString(CONF:getStringValue("no_gem_now"))
	if self.gemList == nil then
		self.gemList = require("util.ScrollViewDelegate"):create(node:getChildByName("gem_bag_list") ,cc.size(3,0), cc.size(75 ,75))
	else
		self.gemList:clear()
	end
	node:getChildByName("gem_bag_list"):setScrollBarEnabled(false)
	table.sort(gems,function(a,b)
		local cfg_gemA = CONF.GEM.get(a.id)
		local cfg_gemB = CONF.GEM.get(b.id)
		if cfg_gemA.QUALITY == cfg_gemB.QUALITY then
			if cfg_gemA.LEVEL == cfg_gemB.LEVEL then
				if cfg_gemA.TYPE == cfg_gemB.TYPE then
					return a.id > b.id
				else
					return cfg_gemA.TYPE > cfg_gemB.TYPE
				end
			else
				return cfg_gemA.LEVEL > cfg_gemB.LEVEL
			end
		else
			return cfg_gemA.QUALITY > cfg_gemB.QUALITY
		end
		end)
	for i=1,4 do
		node:getChildByName("gem_list"):getChildByName("GemNode_"..i):getChildByName("selected"):setVisible(false)
	end
	if self.selectedGemBigPos then
		node:getChildByName("gem_list"):getChildByName("GemNode_"..self.selectedGemBigPos):getChildByName("selected"):setVisible(true)
		if ship.gem_list[self.selectedGemBigPos] and ship.gem_list[self.selectedGemBigPos] ~= 0 then
			local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(ship.gem_list[self.selectedGemBigPos],CONF.ETipsType.kGem,true,{ship_guid = self.data_.guid,pos = self.selectedGemBigPos})
			info_node:setPosition(rn:getChildByName("Node_pos"):getPositionX(),rn:getChildByName("Node_pos"):getPositionY())
			info_node:setName("info_node")
			rn:addChild(info_node)
		end
	end
	node:getChildByName("gem_list"):getChildByName("Text"):setString(CONF:getStringValue("hint_gem"))
	local list = node:getChildByName("gem_list")
	local refreshGem = function()
		self.gemList:clear()
		local show = true
		local gems = player:getAllUnGemList()
		table.sort(gems,function(a,b)
			local cfg_gemA = CONF.GEM.get(a.id)
			local cfg_gemB = CONF.GEM.get(b.id)
			if cfg_gemA.QUALITY == cfg_gemB.QUALITY then
				if cfg_gemA.LEVEL == cfg_gemB.LEVEL then
					if cfg_gemA.TYPE == cfg_gemB.TYPE then
						return a.id > b.id
					else
						return cfg_gemA.TYPE > cfg_gemB.TYPE
					end
				else
					return cfg_gemA.LEVEL > cfg_gemB.LEVEL
				end
			else
				return cfg_gemA.QUALITY > cfg_gemB.QUALITY
			end
			end)
		for k,v in ipairs(gems) do
			local node1 = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/Item.csb")
			local cfg_gem = CONF.GEM.get(v.id)
			if (self.selectedGemBigPos and conf.HOLE[self.selectedGemBigPos] and cfg_gem.TYPE == conf.HOLE[self.selectedGemBigPos]) or conf.HOLE[self.selectedGemBigPos] == 6 then
				node1:getChildByName("level"):setVisible(true)
				node1:getChildByName("level_num"):setVisible(true)
				node1:getChildByName("level_num"):setString(cfg_gem.LEVEL)
				node1:getChildByName("num"):setString(v.num)
				node1:getChildByName("icon"):setVisible(true)
				node1:getChildByName("icon"):loadTexture("ItemIcon/"..cfg_gem.RES_ID..".png")
				node1:getChildByName("background"):setTag(v.id)
				node1:getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..cfg_gem.QUALITY..".png")
				local function func()
					self:removeTips()
					local list = node:getChildByName("gem_bag_list")
					if Tools.isEmpty(list:getChildren()) == false then
						for k,v in ipairs(list:getChildren()) do
							v:getChildByName("selected"):setVisible(false)
						end
					end
					node1:getChildByName("selected"):setVisible(true)
					local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(v.id,CONF.ETipsType.kGem,false,{ship_guid = self.data_.guid,pos = self.selectedGemBigPos})
					info_node:setPosition(rn:getChildByName("Node_pos"):getPositionX(),rn:getChildByName("Node_pos"):getPositionY())
					info_node:setName("info_node")
					rn:addChild(info_node)
				end
				local callback = {node = node1:getChildByName("background"), func = func}
				self.gemList:addElement(node1,{callback = callback})
				show = false
			end
		end
		node:getChildByName("Text"):setVisible(show)
	end
	refreshGem()
	for i=1,4 do
		list:getChildByName("GemNode_"..i):getChildByName("icon"):setVisible(false)
		list:getChildByName("GemNode_"..i):setVisible(true)
		list:getChildByName("GemNode_"..i):getChildByName("Image_2"):setVisible(true)
		list:getChildByName("GemNode_"..i):getChildByName("shadow"):setVisible(false)
		list:getChildByName("GemNode_"..i):getChildByName("num"):setVisible(false)
		list:getChildByName("suo_"..i):setVisible(false)

        list:getChildByName("name"..i):setString(GetGemType(conf.HOLE[i]))
        if i == 1 or i == 3 then
            list:getChildByName("name"..i):getVirtualRenderer():setLineBreakWithoutSpace(true)
            list:getChildByName("name"..i):getVirtualRenderer():setMaxLineWidth(110)
            list:getChildByName("name"..i):setContentSize(list:getChildByName("name"..i):getVirtualRenderer():getContentSize())
        end
	end
	if Tools.isEmpty(conf.HOLE) == false then
		for i=1,#conf.HOLE do
			list:getChildByName("GemNode_"..i):getChildByName("Image_2"):setVisible(false)
			print("ship.gem_list",ship.gem_list[i])
			list:getChildByName("GemNode_"..i):getChildByName("icon"):setVisible(true)
			list:getChildByName("GemNode_"..i):setVisible(true)
			list:getChildByName("suo_"..i):setVisible(false)
			list:getChildByName("GemNode_"..i):getChildByName("level"):setVisible(false)
			list:getChildByName("GemNode_"..i):getChildByName("level_num"):setVisible(false)
			if ship.gem_list[i] == 0 then
				list:getChildByName("GemNode_"..i):getChildByName("icon"):loadTexture("ShipsScene/ui2/hole_"..conf.HOLE[i]..".png")
				list:getChildByName("GemNode_"..i):getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_3.png")
				list:getChildByName("GemNode_"..i):getChildByName("shadow"):setVisible(false)
				list:getChildByName("GemNode_"..i):getChildByName("num"):setVisible(false)
			else
				local cfg_gem = CONF.GEM.get(ship.gem_list[i])
				list:getChildByName("GemNode_"..i):getChildByName("background"):setTag(ship.gem_list[i])
				list:getChildByName("GemNode_"..i):getChildByName("background"):setTexture("RankLayer/ui/ui_avatar_"..cfg_gem.QUALITY..".png")
				list:getChildByName("GemNode_"..i):getChildByName("icon"):loadTexture("ItemIcon/"..cfg_gem.RES_ID..".png")
				list:getChildByName("GemNode_"..i):getChildByName("shadow"):setVisible(true)
				list:getChildByName("GemNode_"..i):getChildByName("level"):setVisible(true)
				list:getChildByName("GemNode_"..i):getChildByName("level_num"):setVisible(true)
				list:getChildByName("GemNode_"..i):getChildByName("level_num"):setString(cfg_gem.LEVEL)
				list:getChildByName("GemNode_"..i):getChildByName("num"):setVisible(true)
			end
			if ship.level < conf.HOLEOPEN_LEVEL[i] then
				list:getChildByName("suo_"..i):setVisible(true)
			end
			list:getChildByName("Image_"..i):addClickEventListener(function()
				local ship = player:getShipByGUID(self.data_.guid)
				if list:getChildByName("suo_"..i):isVisible() then
					tips:tips(CONF:getStringValue("Airship")..conf.HOLEOPEN_LEVEL[i]..CONF:getStringValue("level_2")..CONF:getStringValue("open"))
					return
				end
				self.selectedGemBigPos = i
				refreshGem()
				self:removeTips()
				local list = node:getChildByName("gem_bag_list")
				if Tools.isEmpty(list:getChildren()) == false then
					for k,v in ipairs(list:getChildren()) do
						v:getChildByName("selected"):setVisible(false)
					end
				end
				for i=1,4 do
					node:getChildByName("gem_list"):getChildByName("GemNode_"..i):getChildByName("selected"):setVisible(false)
				end
				node:getChildByName("gem_list"):getChildByName("GemNode_"..i):getChildByName("selected"):setVisible(true)
				if ship.gem_list[i] ~= 0 then
					local info_node = require("app.views.ShipsScene.TipsInfoNode"):chooseTips(ship.gem_list[i],CONF.ETipsType.kGem,true,{ship_guid = self.data_.guid,pos = i})
					info_node:setPosition(rn:getChildByName("Node_pos"):getPositionX(),rn:getChildByName("Node_pos"):getPositionY())
					info_node:setName("info_node")
					rn:addChild(info_node)
				end
				if self.selectedGemBigPos then
					node:getChildByName("Text"):setString(CONF:getStringValue("no_gem_now"))
				else
					node:getChildByName("Text"):setString(CONF:getStringValue("choose gem"))
				end
				end)
		end
	end
	node:getChildByName("go"):getChildByName("Text"):setString(CONF:getStringValue("go_gem_fuse"))
	node:getChildByName("go"):addClickEventListener(function()
		self:removeTips()
		self:getApp():pushView("SmithingScene/SmithingScene",{kind = 3})
		-- self:removeFromParent()
		end)
    node:getChildByName("go_shop"):getChildByName("Text"):setString(CONF:getStringValue("shop"))
	node:getChildByName("go_shop"):addClickEventListener(function()
		if self.scene then
			if self.scene == "ShipInfoLayer" then
				self:getParent():removeFromParent()
			else
				self:removeFromParent()
			end
		end
		require("app.ExViewInterface"):getInstance():ShowShopUI()
	end)
	if self.selectedGemBigPos then
		node:getChildByName("Text"):setString(CONF:getStringValue("no_gem_now"))
        node:getChildByName("go_shop"):setVisible(true)
	else
		node:getChildByName("Text"):setString(CONF:getStringValue("choose gem"))
        node:getChildByName("go_shop"):setVisible(false)
	end
	rn:getChildByName("left"):getChildByName("zhanli"):setString( player:calShipFightPower( self.data_.guid ))
end

function ShipInfoLayer:refreshNodePos(isShow)
	local btn = self:getResourceNode():getChildByName("btn")
	if isShow then
		btn:getChildByName("total"):setPositionX(44)
		btn:getChildByName("skill"):setPositionX(134)
		btn:getChildByName("equip"):setPositionX(224)
		btn:getChildByName("gem"):setPositionX(314)
		btn:getChildByName("energy"):setPositionX(404)
	else
		btn:getChildByName("total"):setPositionX(20)
		btn:getChildByName("skill"):setPositionX(164)
		btn:getChildByName("equip"):setPositionX(284)
		btn:getChildByName("gem"):setPositionX(404)
		--btn:getChildByName("energy"):setPositionX(373.79)
	end
end

function ShipInfoLayer:removeTips()
	if self:getResourceNode():getChildByName("info_node") then
		self:getResourceNode():getChildByName("info_node"):removeFromParent()
	end
end

function ShipInfoLayer:addBgListener( node)

	local function onTouchBegan(touch, event)
		local target = event:getCurrentTarget()
		local locationInNode = target:convertToNodeSpace(touch:getLocation())
		local s = target:getContentSize()

		local rect = cc.rect(0, 0, s.width, s.height)
		
		if cc.rectContainsPoint(rect, locationInNode) then
			return true
		end
		return false
	end

	local function onTouchMoved(touch, event)

	end

	local function onTouchEnded(touch, event)
		self:removeTips()
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = node:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

function ShipInfoLayer:addLongListener( node, fun1, fun2)

	local function beginhandle()
		if self.isTouch then
			self.count = self.count + 1
			if self.count >= 2 then
				self.longPress = true
				self.count = 0
				if fun2 then
					fun2()
				end
			end
		end
	end

	local function onTouchBegan(touch, event)

		local target = event:getCurrentTarget()
		
		-- local locationInNode = self.svd_:getScrollView():convertToNodeSpace(touch:getLocation())

		-- local sv_s = self.svd_:getScrollView():getContentSize()
		-- local sv_rect = cc.rect(0, 0, sv_s.width, sv_s.height)

		-- if cc.rectContainsPoint(sv_rect, locationInNode) then

			local ln = target:convertToNodeSpace(touch:getLocation())

			local s = target:getContentSize()
			local rect = cc.rect(0, 0, s.width, s.height)

			if cc.rectContainsPoint(rect, ln) then
				if target:getTag() == 157 then
					target:loadTexture("Common/newUI/btn_sub_light.png")
				elseif target:getTag() == 158 then
					target:loadTexture("Common/newUI/btn_add_light.png")
				end
				self.isTouch = true
				self.beginHandle = scheduler:scheduleScriptFunc(beginhandle,0.1,false)   
				return true
			end

		-- end

		return false
	end

	local function onTouchMoved(touch, event)

		local delta = touch:getDelta()
		if math.abs(delta.x) > g_click_delta or math.abs(delta.y) > g_click_delta then
			self.isMoved = true
		end
	end

	local function onTouchEnded(touch, event)
		local target = event:getCurrentTarget()

		if target:getTag() == 157 then
			target:loadTexture("Common/newUI/btn_sub.png")
		elseif target:getTag() == 158 then
			target:loadTexture("Common/newUI/btn_add_black.png")
		end

		scheduler:unscheduleScriptEntry(self.beginHandle)
		self.isTouch = false

		if self.isMoved then
			self.isMoved = false
			return false
		end

		if self.longPress then
			self.longPress = false
			self.count = 0
			return false
			-- fun2()
		end
		
		self.longPress = false
		self.count = 0
		if fun1 then
			fun1()
		end

	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = node:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
end

function ShipInfoLayer:refreshEnergyNode(node)
	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kEnergy)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("nlc_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end
	local maxEnemy = CONF.ENERGYLEVEL.get(CONF.ENERGYLEVEL.count()-1).ENERGY_EXP_ALL
	self.selectedEquipBigPos = nil
	self.selectedSkillBigPos = nil
	self.selectedGemBigPos = nil
	self.selectedEquipGuid = nil
	local ship = player:getShipByGUID(self.data_.guid)
	local energy_level = 0
	if ship.energy_exp ~= nil and ship.energy_exp ~= 0 then
		for i,v in ipairs(CONF.ENERGYLEVEL.getIDList()) do
			if ship.energy_exp < CONF.ENERGYLEVEL.get(v).ENERGY_EXP_ALL then
				energy_level = v - 1
				break
			end
		end
		if ship.energy_exp >= maxEnemy then
			energy_level = CONF.ENERGYLEVEL.count()-1
		end
	end
    local energy_nextlevel = math.min(energy_level + 1,CONF.ENERGYLEVEL.count())

	self:getResourceNode():getChildByName("total"):setString(CONF:getStringValue("energy groove"))

	node:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("ship_develop"))

	local attr_name = { {key = "blood", value = CONF.ShipGrowthAttrs.kHP},{key = "atk", value = CONF.ShipGrowthAttrs.kAttack},{key = "defence", value = CONF.ShipGrowthAttrs.kDefence},{key = "speed", value = CONF.ShipGrowthAttrs.kSpeed},{key = "target", value = CONF.ShipGrowthAttrs.kHit},{key = "dodge", value = CONF.ShipGrowthAttrs.kDodge},{key = "crit", value = CONF.ShipGrowthAttrs.kCrit},{key = "resist", value = CONF.ShipGrowthAttrs.kAnticrit},{key = "e_atk", value = CONF.ShipGrowthAttrs.kEnergyAttack}}

	local atk = node:getChildByName("atk")
	local defence = node:getChildByName("defence")
	local speed = node:getChildByName("speed")
	local blood = node:getChildByName("blood")
	local target = node:getChildByName("target")
	local dodge = node:getChildByName("dodge")
	local crit = node:getChildByName("crit")
	local resist = node:getChildByName("resist")
	local e_atk = node:getChildByName("e_atk")


	local calship = player:calShip(self.data_.guid)
	for i,v in ipairs(attr_name) do
		local nn = node:getChildByName(v.key)
		nn:getChildByName("text"):setString(CONF:getStringValue("Attr_"..v.value)..":")
		nn:getChildByName("num"):setString(Tools.getEnergyAddition(ship.id, energy_level, v.value))
--		nn:getChildByName("add_num"):setString("+0")
		local numm = Tools.getEnergyAddition(ship.id, energy_nextlevel, v.value) - Tools.getEnergyAddition(ship.id, energy_level, v.value)
		nn:getChildByName("add_num"):setString("+"..numm)
		--nn:getChildByName("num"):setPositionX(nn:getChildByName("text"):getPositionX()+nn:getChildByName("text"):getContentSize().width+5)
		nn:getChildByName("add_num"):setPositionX(nn:getChildByName("num"):getPositionX()+nn:getChildByName("num"):getContentSize().width+5)

		nn:getChildByName("add_num"):setVisible(true)
        if energy_level == CONF.ENERGYLEVEL.count()-1 then
            nn:getChildByName("add_num"):setVisible(false)
        end
	end

	local energy_conf = CONF.ENERGYLEVEL.get(energy_level)
    local energy_nextconf = CONF.ENERGYLEVEL.get(energy_nextlevel)
	local now_percent
	if energy_level ~= 0 then
	 	now_percent= math.floor((ship.energy_exp - CONF.ENERGYLEVEL.get(energy_level).ENERGY_EXP_ALL)/energy_nextconf.ENERGY_EXP*100)
	else
		now_percent= math.floor((ship.energy_exp)/energy_nextconf.ENERGY_EXP*100)
	end
	node:getChildByName("energy_now"):setString(CONF:getStringValue("energy_level")..energy_level.."("..now_percent.."%)")
	node:getChildByName("energy_max"):setString(CONF:getStringValue("energy_level")..energy_level.."("..now_percent.."%)")

	--
	local res_table = {0,0,0}

	local function changeEnergyInfo( ... )
		local ship = player:getShipByGUID(self.data_.guid)
		local energy_level = 0
		if ship.energy_exp ~= nil and ship.energy_exp ~= 0 then
			for i,v in ipairs(CONF.ENERGYLEVEL.getIDList()) do
				if ship.energy_exp < CONF.ENERGYLEVEL.get(v).ENERGY_EXP_ALL then
					energy_level = v - 1
					break
				end
			end
			if ship.energy_exp >= maxEnemy then
				energy_level = CONF.ENERGYLEVEL.count()-1
			end
		end
        local energy_nextlevel = math.min(energy_level + 1,CONF.ENERGYLEVEL.count()-1)
		
		local exp = ship.energy_exp
		for i,v in ipairs(res_table) do
			exp = exp + math.floor(v*CONF.PARAM.get("energy_res_param").PARAM[i+1])
		end

		local el = 0
		local has = false
		if exp ~= nil and exp ~= 0 then
			for i,v in ipairs(CONF.ENERGYLEVEL.getIDList()) do
				if exp < CONF.ENERGYLEVEL.get(v).ENERGY_EXP_ALL then
					el = v - 1
					has = true
					break
				end
			end
		end

		if has then
			local ec = CONF.ENERGYLEVEL.get(el)
            local e_nc = CONF.ENERGYLEVEL.get(energy_nextlevel)
			local pp 
			if el ~= 0 then
			 	pp= math.floor((exp - CONF.ENERGYLEVEL.get(el).ENERGY_EXP_ALL)/ec.ENERGY_EXP*100)
			else
				pp= math.floor((exp)/energy_conf.ENERGY_EXP*100)
			end
			node:getChildByName("energy_max"):setString(CONF:getStringValue("energy_level")..el.."("..pp.."%)")
		else
			local el = CONF.ENERGYLEVEL.getIDList()[#CONF.ENERGYLEVEL.getIDList()]
			local pp = 100
			node:getChildByName("energy_max"):setString(CONF:getStringValue("energy_level")..el.."("..pp.."%)")
		end

		for i,v in ipairs(attr_name) do
			local nn = node:getChildByName(v.key)
			local numm = Tools.getEnergyAddition(ship.id, energy_nextlevel, v.value) - Tools.getEnergyAddition(ship.id, energy_level, v.value)
			nn:getChildByName("add_num"):setString("+"..numm)

			if el > energy_level then
				nn:getChildByName("add_num"):setVisible(true)
			else
				nn:getChildByName("add_num"):setVisible(true)
			end
            if energy_level == CONF.ENERGYLEVEL.count()-1 then
                nn:getChildByName("add_num"):setVisible(false)
            end
		end
        node:getChildByName("txt_des"):setString(CONF:getStringValue("culture_tips"))
		if exp > ship.energy_exp then
			node:getChildByName("energy_max"):setVisible(true)
			node:getChildByName("zengjia_46"):setVisible(true)
            node:getChildByName("txt_des"):setVisible(false)
		else
			node:getChildByName("energy_max"):setVisible(false)
			node:getChildByName("zengjia_46"):setVisible(false)
            node:getChildByName("txt_des"):setVisible(true)
		end
	end

    local maxnumlist = {}

	for i=1,3 do

		local res_node = node:getChildByName("res"..i.."_node")
--		res_node:getChildByName("max_num"):setString("/"..player:getResByIndex(i+1))
        local res_param_list = CONF.PARAM.get("energy_res_param").PARAM
        local next_exp = energy_nextconf.ENERGY_EXP_ALL - ship.energy_exp
        local res_maxnum = math.floor(next_exp / res_param_list[i+1])
        table.insert(maxnumlist,res_maxnum)
        res_node:getChildByName("max_num"):setString("/"..res_maxnum)
--		res_node:getChildByName("now_num"):setString(0)
        res_node:getChildByName("now_num"):setString(player:getResByIndex(i+1))
		res_node:getChildByName("now_num"):setPositionX(res_node:getChildByName("max_num"):getPositionX() - res_node:getChildByName("max_num"):getContentSize().width)

		local text_num = 3+i
		res_node:getChildByName("text"):setString(CONF:getStringValue("IN_"..text_num.."001"))

		local energy_line = res_node:getChildByName("energy_line")
		local energy_hd = res_node:getChildByName("energy_hd")
		local min_x = energy_line:getPositionX()
		local max_x = energy_line:getPositionX() + energy_line:getTag()
		local res_num = 0
		local hd_began_pos = energy_hd:getPositionX()

		local function changeInfoByBtn( ... )
--			local percent = math.floor(res_table[i]/player:getResByIndex(i+1)*100)
            local percent = math.floor(player:getResByIndex(i+1)/res_maxnum*100)
			if percent < 0 then
				percent = 0
			end

			if percent > 100 then
				percent = 100
			end

			energy_hd:setPositionX((max_x - min_x)*percent/100 + min_x)
--			res_node:getChildByName("now_num"):setString(res_table[i])
            res_node:getChildByName("now_num"):setString(player:getResByIndex(i+1))
			local width = energy_line:getTag() * percent/100
			local height = energy_line:getContentSize().height
			energy_line:setContentSize(cc.size(width, height))

			changeEnergyInfo()

		end

		local function subBtnFunc1( ... )
			if res_table[i]== 0 then
				tips:tips(CONF:getStringValue("res_not_enough"))
				return
			end

			res_table[i] = res_table[i]-1
			changeInfoByBtn()
		end

		local function subBtnFunc2( ... )
			if res_table[i] == 0 then
				tips:tips(CONF:getStringValue("res_not_enough"))
				return
			end

			res_table[i] = res_table[i] - math.floor(player:getResByIndex(i+1)/100)

			if res_table[i] < 0 then
				res_table[i] = 0
			end
			changeInfoByBtn()
		end

		local function addBtnFunc1( ... )
			local ship = player:getShipByGUID(self.data_.guid)
			if res_table[i] == player:getResByIndex(i+1) then
				tips:tips(CONF:getStringValue("res_not_enough"))
				return
			end

			res_table[i] = res_table[i] + 1

			local exp = ship.energy_exp 
			for i,v in ipairs(res_table) do
				exp = exp + math.floor(v*CONF.PARAM.get("energy_res_param").PARAM[i+1])
			end
			local maxEnemy = CONF.ENERGYLEVEL.get(CONF.ENERGYLEVEL.count()-1).ENERGY_EXP_ALL
			if exp >= maxEnemy then
				res_table[i] = res_table[i] - 1
				-- return
				tips:tips(CONF:getStringValue("max_level"))
			end

			changeInfoByBtn()
		end

		local function addBtnFunc2( ... )
			local ship = player:getShipByGUID(self.data_.guid)
			if res_table[i] == player:getResByIndex(i+1) then
				tips:tips(CONF:getStringValue("res_not_enough"))
				return
			end
			local exp = ship.energy_exp 
			for i,v in ipairs(res_table) do
				exp = exp + math.floor(v*CONF.PARAM.get("energy_res_param").PARAM[i+1])
			end
			local maxEnemy = CONF.ENERGYLEVEL.get(CONF.ENERGYLEVEL.count()-1).ENERGY_EXP_ALL
			if exp >= maxEnemy then
				changeInfoByBtn()
				tips:tips(CONF:getStringValue("max_level"))
				return
			else
				local needExp = maxEnemy - exp
				local needRes = needExp/CONF.PARAM.get("energy_res_param").PARAM[i+1]
				if needRes < 1 then
					changeInfoByBtn()
					tips:tips(CONF:getStringValue("max_level"))
					return
				end
			end
			if exp >= maxEnemy then
				local other_exp = 0
				for k,v in ipairs(res_table) do
					if k ~= i then
						other_exp = other_exp + math.floor(v*CONF.PARAM.get("energy_res_param").PARAM[k+1])
					end
				end
				local needExp = maxEnemy - ship.energy_exp - other_exp
				local needRes = math.floor(needExp/CONF.PARAM.get("energy_res_param").PARAM[i+1])
				res_table[i] = needRes
				tips:tips(CONF:getStringValue("max_level"))
				-- return
			else
				local needExp = maxEnemy - exp
				local needRes = needExp/CONF.PARAM.get("energy_res_param").PARAM[i+1]
				if needRes >= 1 then
					if math.floor(player:getResByIndex(i+1)/100) < math.floor(needRes) then
						res_table[i] = res_table[i] + math.floor(player:getResByIndex(i+1)/100)
					else
						res_table[i] = res_table[i] + math.floor(needRes)
					end
				end
			end
			if res_table[i] > player:getResByIndex(i+1) then
				res_table[i] = player:getResByIndex(i+1)
			end
			if res_table[i] < 0 then
				res_table[i] = 0
			end
			changeInfoByBtn()
		end

		changeInfoByBtn()

		-- if i == 1 then
--		self:addLongListener(res_node:getChildByName("icon_sub"), subBtnFunc1, subBtnFunc2)
--		self:addLongListener(res_node:getChildByName("icon_add"), addBtnFunc1, addBtnFunc2)
		-- end

		local function setPos( delta )
			local ship = player:getShipByGUID(self.data_.guid)
			local posX = delta + hd_began_pos

			if posX < min_x then
				-- energy_hd:setPositionX(min_x)
				-- res_node:getChildByName("now_num"):setString("0")
				res_table[i] = 0
			else
				if posX > max_x then
					res_table[i] = player:getResByIndex(i+1)
				end
				local num = math.floor((posX - min_x)/(max_x - min_x)*100)
				local addRes = math.floor(player:getResByIndex(i+1)*num/100)
				local maxEnemy = CONF.ENERGYLEVEL.get(CONF.ENERGYLEVEL.count()-1).ENERGY_EXP_ALL
				local exp = ship.energy_exp 
				for i,v in ipairs(res_table) do
					exp = exp + math.floor(v*CONF.PARAM.get("energy_res_param").PARAM[i+1])
				end	
				if exp < maxEnemy then
					res_table[i] = addRes
				end

				local new_exp = ship.energy_exp 
				for i,v in ipairs(res_table) do
					new_exp = new_exp + math.floor(v*CONF.PARAM.get("energy_res_param").PARAM[i+1])
				end
				if new_exp >= maxEnemy then
					local over_exp =  new_exp - maxEnemy
					local over_res = math.ceil(over_exp/CONF.PARAM.get("energy_res_param").PARAM[i+1])
					res_table[i] = res_table[i] - over_res
				end

				if res_table[i] > player:getResByIndex(i+1) then
					res_table[i] = player:getResByIndex(i+1)
				end
				if res_table[i] < 0 then
					res_table[i] = 0
				end
			end

			changeInfoByBtn()
			
		end

		local function hd_touch( sender, eventType )
			if eventType == ccui.TouchEventType.began then

				hd_began_pos = energy_hd:getPositionX()
				-- setPos(sender:getTouchBeganPosition().x)

			elseif eventType == ccui.TouchEventType.moved then

				-- setPos(sender:getTouchMovePosition().x)
				local delta = cc.pSub(sender:getTouchMovePosition(), sender:getTouchBeganPosition())
				setPos(delta.x)

			elseif eventType == ccui.TouchEventType.ended then

				-- setPos(sender:getTouchEndPosition().x)

			elseif eventType == ccui.TouchEventType.canceled then

				-- setPos(sender:getTouchCancelPosition().x)
			end
		end

		energy_hd:addTouchEventListener(hd_touch)

	end

	node:getChildByName("btn"):addClickEventListener(function ( ... )

		if Bit:has(ship.status, 4) then
			tips:tips(CONF:getStringValue("planeting"))
			return
		end

		local flag = false
		for i,v in ipairs(res_table) do
			if v >= CONF.PARAM.get("energy_res_min").PARAM[i+1] then
				flag = true
				break
			end
		end

		if not flag then
			tips:tips(CONF:getStringValue("no resource"))
			return			
		end

		local exp = 0
		for i,v in ipairs(res_table) do
			exp = exp + math.floor(v*CONF.PARAM.get("energy_res_param").PARAM[i+1])
		end

		if ship.energy_exp and ship.energy_exp ~= 0 then
			local maxEnemy = CONF.ENERGYLEVEL.get(CONF.ENERGYLEVEL.count()-1).ENERGY_EXP_ALL
			if ship.energy_exp + exp >= maxEnemy then
				tips:tips(CONF:getStringValue("energy max"))
				return
			end
		end

		local tt = {0}
		for i,v in ipairs(res_table) do
			table.insert(tt, v)
		end

		res_table = {0,0,0}
		print("ShipAddEnergyExpReq")
		local strData = Tools.encode("ShipAddEnergyExpReq", {
			ship_guid = self.data_.guid,
			res_list = tt,
		})
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_ADD_ENERGY_EXP_REQ"),strData)


	end)

    local function timer()
        local endTime = player:getServerTime()
        if player:getShipEnergyEndTime() then
            endTime = player:getShipEnergyEndTime()
        end

        if endTime - player:getServerTime() >= 0 then
            node:getChildByName("time"):setVisible(true)
            node:getChildByName("time"):setString(formatTime(endTime - player:getServerTime()))
            if player:getShipEnergyTimeLock() and player:getShipEnergyTimeLock() > 0 then
                for i = 1,3 do
                    node:getChildByName("btn"..i):setEnabled(false)
                end
                node:getChildByName("auto_upgrade"):setVisible(true)
                node:getChildByName("auto_upgrade"):getChildByName("pointnum"):setString(Tools.getSpeedEnergyMoney(endTime - player:getServerTime()))
            else
                for i = 1,3 do
                    node:getChildByName("btn"..i):setEnabled(true)
                end
                node:getChildByName("auto_upgrade"):setVisible(false)
            end
        else
            node:getChildByName("time"):setVisible(false)
            node:getChildByName("auto_upgrade"):setVisible(false)
            for i = 1,3 do
                node:getChildByName("btn"..i):setEnabled(true)
            end
	    end
    end

    if self.energyscheduler == nil then
        self.energyscheduler = scheduler:scheduleScriptFunc(timer,0.033,false)
    end

    for i = 1,3 do
        node:getChildByName("btn"..i):getChildByName("text"):setString(CONF:getStringValue("ship_develop"))
        node:getChildByName("btn"..i):addClickEventListener(function ()
            if energy_level == CONF.ENERGYLEVEL.count()-1 then
                tips:tips(CONF:getStringValue("energy max"))
                return
            end

            if Bit:has(ship.status, 4) then
			    tips:tips(CONF:getStringValue("planeting"))
			    return
		    end

		    if player:getResByIndex(i+1) < maxnumlist[i] then
			    tips:tips(CONF:getStringValue("res_not_enough"))
			    return			
		    end

		    local tt = {0,0,0,0}
            tt[i+1] = maxnumlist[i]
		    print("ShipAddEnergyExpReq")
		    local strData = Tools.encode("ShipAddEnergyExpReq", {
			    ship_guid = self.data_.guid,
			    res_list = tt,
		    })
		    GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_ADD_ENERGY_EXP_REQ"),strData)
        end)
    end

    node:getChildByName("auto_upgrade"):addClickEventListener(function ()
		GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_LOCK_ENERGY_TIME_REQ"),"0")
    end)

	self:getResourceNode():getChildByName("left"):getChildByName("zhanli"):setString( player:calShipFightPower( self.data_.guid ))
end

function ShipInfoLayer:onExitTransitionStart()
	printInfo("ShipInfoLayer:onExitTransitionStart()")
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	if schedulers ~= nil then
		scheduler:unscheduleScriptEntry(schedulers)
		schedulers = nil
	end
    if self.energyscheduler ~= nil then
	    scheduler:unscheduleScriptEntry(self.energyscheduler)
	    self.energyscheduler = nil
	end
	if self.svd_ then
		self.svd_:clear()
	end
end

return ShipInfoLayer