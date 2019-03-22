local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local Bit = require "Bit"

local ShipsDevelopScene = class("ShipsDevelopScene", cc.load("mvc").ViewBase)

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

ShipsDevelopScene.RESOURCE_FILENAME = "ShipsScene/ship/ShipsDevelopScene.csb"

ShipsDevelopScene.NEED_ADJUST_POSITION = true

ShipsDevelopScene.mode_ = 5

ShipsDevelopScene.allShipList = {}

-- ShipsDevelopScene.selectedShipID = nil

ShipsDevelopScene.selectedShip = {}

ShipsDevelopScene.haveShipNum = 0

ShipsDevelopScene.selectedShipNum = 0

ShipsDevelopScene.IS_DEBUG_LOG_LOCAL = false

ShipsDevelopScene.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="onBtnClick"}}},
}

-- ADD WJJ 180620
ShipsDevelopScene.guideHelper = require("util.ExGuideHelper"):getInstance()
ShipsDevelopScene.lagHelper = require("util.ExLagHelper"):getInstance()
ShipsDevelopScene.IS_SCENE_TRANSFER_EFFECT = false

function ShipsDevelopScene:_printGuideId()
	print("@@@@ guideManager.guide_id: " .. tostring(guideManager.guide_id))
end

function ShipsDevelopScene:_print(_log)
	if( self.IS_DEBUG_LOG_LOCAL ) then
		self:_printGuideId()
		print(_log)
	end
end



function ShipsDevelopScene:SetSelectedShip(v)
	self:_print("@@@@@@@ SetSelectedShip : " .. tostring(v or " nil"))
	if( v ~= nil ) then
		self:_print("@@@@@@@ SetSelectedShip shipId: " .. tostring(v["shipId"] or " nil"))
	end

	if( false == self.guideHelper:OnBugFix_XiangqingBianHecheng( guideManager.guide_id, v ) ) then
		self:_print("@@@@@ SetSelectedShip : BUG FIXED!! ")
		do return end
	end

	self.selectedShip = v
end

function ShipsDevelopScene:onCreate(data) -- id,type
	-- EDIT BY WJJ 180702
	self.data_ = data

	gl:retainLoading()
	self:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(function ( ... )
		gl:releaseLoading()
	end)))

end

function ShipsDevelopScene:onBtnClick(event)
	-- print ( "### LUA ShipsDevelopScene.lua onBtnClick : " .. tostring(event) )
	if event.name == "ended" then
		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			-- self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
			-- EDIT BY WJJ 20180702
			if ( self.IS_SCENE_TRANSFER_EFFECT ) then
				self.lagHelper:BeginTransferEffect("ShipsScene/ShipsDevelopScene")
			else
				self:getApp():popView()
			end
		end
	end
end

function ShipsDevelopScene:sortList(list)
	table.sort(list,function(a,b)
		if a.isHave == b.isHave then
			if a.isHave == 0 then
				if (a.haveBluePrintNum >= a.needBluePrintNum) and (b.haveBluePrintNum >= b.needBluePrintNum) then
					return a.shipId > b.shipId
				elseif (a.haveBluePrintNum < a.needBluePrintNum) and (b.haveBluePrintNum < b.needBluePrintNum) then
					return a.shipId > b.shipId
				else
					return a.haveBluePrintNum >= a.needBluePrintNum
				end
			else
				return a.shipId > b.shipId
			end
		else
			return a.isHave > b.isHave
		end
		end)
end

function ShipsDevelopScene:getShipList()
	-- print ( "### LUA ShipsDevelopScene.lua getShipList " )

	self.allShipList = {}
	local shipList = player:getShipList()
    if guideManager.guide_id  == 34 or guideManager.guide_id == 98 then
        if #shipList > #self.NoBugShipList then
            print("bugshiplist!!!")
            shipList = self.NoBugShipList
        end
    end
	for k,v in pairs(CONF.AIRSHIP.index) do
		-- print("...........",k)
		local cship = CONF.AIRSHIP.get(v)
		if cship.SHOW_ILLUSTRATED and cship.SHOW_ILLUSTRATED == 1 then
			local ship = {}
			ship.isHave = 0
			ship.shipId = cship.ID
			ship.breakNum = 0
			ship.guid = 0
			ship.haveBluePrintNum = player:getItemNumByID(cship.BLUEPRINT[1])
			ship.needBluePrintNum = cship.BLUEPRINT_NUM[1]
			ship.blueprintId = cship.BLUEPRINT[1]
			ship.type = cship.TYPE
			ship.power = player:getEnemyPower(cship.ID)
			table.insert(self.allShipList,ship)
		end
	end
	for k,ship1 in pairs(shipList) do
		for k,ship2 in ipairs(self.allShipList) do
			if ship1.id == ship2.shipId then
				ship2.isHave = 1
				ship2.guid = ship1.guid
				ship2.breakNum = ship1.ship_break
				ship2.power = player:calShipFightPower( ship1.guid )
			end 
		end
	end
	self:sortList(self.allShipList)
end

function ShipsDevelopScene:jindu(v)
	local rn = self:getResourceNode()
	local node_v = rn:getChildByName("info"):getChildByName("Node_1")
	node_v:setVisible(false)
	local cfg_item = CONF.ITEM.get(CONF.AIRSHIP.get(v.shipId).BLUEPRINT[1])
	node_v:getChildByName("blueprintNum1"):setString(CONF:getStringValue(cfg_item.NAME_ID)..":")
	node_v:getChildByName("blueprintNum2"):setString(v.haveBluePrintNum)
	node_v:getChildByName("blueprintNum3"):setString("/"..v.needBluePrintNum)
	node_v:getChildByName("blueprintNum2"):setPosition(node_v:getChildByName("blueprintNum1"):getPositionX()+node_v:getChildByName("blueprintNum1"):getContentSize().width+3,node_v:getChildByName("blueprintNum1"):getPositionY())
	node_v:getChildByName("blueprintNum3"):setPosition(node_v:getChildByName("blueprintNum2"):getPositionX()+node_v:getChildByName("blueprintNum2"):getContentSize().width,node_v:getChildByName("blueprintNum2"):getPositionY())
	local progress = require("util.ScaleProgressDelegate"):create(node_v:getChildByName("jindu"), 266)
	progress:setPercentage(v.haveBluePrintNum/v.needBluePrintNum*100)
	if v.needBluePrintNum <= v.haveBluePrintNum then
		node_v:getChildByName("blueprintNum2"):setTextColor(cc.c4b(51,231,51,255))
		-- node_v:getChildByName("blueprintNum2"):enableShadow(cc.c4b(51,231,51,255), cc.size(0.5,0.5))
	else
		node_v:getChildByName("blueprintNum2"):setTextColor(cc.c4b(233,50,59,255))
		-- node_v:getChildByName("blueprintNum2"):enableShadow(cc.c4b(233,50,59,255), cc.size(0.5,0.5))
	end
end 

function ShipsDevelopScene:changeMode()
	print ( "### LUA ShipsDevelopScene.lua changeMode " )

	local rn = self:getResourceNode()
	self.selectedShipNum = 0
	self.haveShipNum = 0
	self:getShipList()
	self.svd_:clear()
	for i=1,5 do
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("selected"):setVisible(false)
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("text_selected"):setVisible(false)
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("text"):setVisible(true)
	end
	rn:getChildByName("all_btn"):getChildByName("node_"..self.mode_):getChildByName("selected"):setVisible(true)
	rn:getChildByName("all_btn"):getChildByName("node_"..self.mode_):getChildByName("text_selected"):setVisible(true)
	rn:getChildByName("info"):getChildByName("Button_wen"):addClickEventListener(function()
		local center = cc.exports.VisibleRect:center()
		local layer = self:getApp():createView("ShipsScene/ShipDetailLayer",self.selectedShip)
		tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
		self:addChild(layer)
		end)

	rn:getChildByName("detail"):addClickEventListener(function()
        if self.svd_.isTouch then
            return
        end

		if self.selectedShip.isHave == 0 then
			if self.selectedShip.needBluePrintNum <= self.selectedShip.haveBluePrintNum then
				local strData = Tools.encode("ShipDevelopeReq", {   
					type = 2,       
					ship_id = self.selectedShip.shipId,
				})
				GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_SHIP_DEVELOPE_REQ"),strData)
				gl:retainLoading()           
			else
				-- tips:tips(CONF:getStringValue("item not enought"))
				if not self:getChildByName("JumpChoseLayer") then
					local center = cc.exports.VisibleRect:center()
					local layer = self:getApp():createView("ShipsScene/JumpChoseLayer",{CONF.AIRSHIP.get(self.selectedShip.shipId).GET_TYPE,scene = "RepairScene"})
					layer:setName("JumpChoseLayer")
					tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))
					self:addChild(layer)
				end
			end
		else
			local layer = self:getApp():createView("ShipsScene/ShipInfoLayer",self.selectedShip)
			self:addChild(layer)
		end
	end)
	
	for i,v in ipairs(self.allShipList) do
		if v.type == self.mode_ or self.mode_ == 5 then
			if self.data_ and self.data_.id then
				if self.data_.id == v.shipId then
					self:SetSelectedShip(v)
				end
			end
			local node = self:creatShipNode(v)
			node:setName("node_"..i)
			node:setTag(v.shipId)
            local ship = CONF.AIRSHIP.get(v.shipId)
			local function func()
				-- print( "##LUA self.svd_:addElement(node,{callback = callback " )

				local children = rn:getChildByName("node_list"):getChildByName("list"):getChildren()
				for k,v in pairs(children) do
					v:getChildByName("selected"):setVisible(false)
				end
				node:getChildByName("selected"):setVisible(true)
                -- skill
                local cfg_skill = CONF.WEAPON.get(ship.SKILL)
--				rn:getChildByName("Skilldes"):setString(CONF:getStringValue("BUFF_M50017")..CONF:getStringValue("weapon")..":"..setMemo( cfg_skill ,4))
                self:setSkilldes(cfg_skill)
				if rn:getChildByName("roleNode"):getChildByName("node_ship") then
					rn:getChildByName("roleNode"):getChildByName("node_ship"):removeFromParent();
				end
				local node_ship = require("app.ExResInterface"):getInstance():FastLoad("sfx/"..ship.RES_ID);
				rn:getChildByName("roleNode"):addChild(node_ship);
				node_ship:setName("node_ship");
				node_ship:setScale(3,3);
				animManager:runAnimByCSB(node_ship, "sfx/"..ship.RES_ID, "attack_2");
				local info = rn:getChildByName("info")
				info:getChildByName("quality"):setTexture("ShipQuality/quality_"..ship.QUALITY..".png")
				info:getChildByName("pow"):setString(CONF:getStringValue("combat")..":")
				if v.guid ~= 0 then
					info:getChildByName("power"):setString(player:calShipFightPower( v.guid ))
				else
					info:getChildByName("power"):setString(v.power)
				end
				info:getChildByName("ship_name"):setString(CONF:getStringValue(ship.NAME_ID))
				local cfg_breakNum = CONF.SHIP_BREAK.get(ship.QUALITY).NUM
				for i=1,6 do
					info:getChildByName("star"..i):setVisible(i<=cfg_breakNum)
					info:getChildByName("star"..i):setTexture("Common/ui/ui_star_gray.png")
					if i <= v.breakNum then
						info:getChildByName("star"..i):setTexture("Common/ui/ui_star_light.png")
					end
				end
				self:jindu(v)
				-- local btnText = CONF:getStringValue("")
				local btnText = CONF:getStringValue("ships_details")
				-- rn:getChildByName("info"):getChildByName("Button"):setVisible(v.isHave == 1)
				if v.isHave == 0 then
					if v.needBluePrintNum <= v.haveBluePrintNum then
						-- print( "###LUA ShipsDevelopScene.lua 219 dianjihecheng" )
						btnText = CONF:getStringValue("clicking_synthesis")
						
					else
						rn:getChildByName("info"):getChildByName("Node_1"):setVisible(true)
						for i=1,6 do
							info:getChildByName("star"..i):setVisible(false)
						end
						btnText = CONF:getStringValue("get way")
					end
				end
				info:getChildByName("Button"):setVisible(false);
				rn:getChildByName("detail"):getChildByName("text"):setString(btnText);
				self:SetSelectedShip(v)

				
				self:_print( "## Lua ShipsDevelopScene.lua ship.RES_ID: " .. tostring(ship.RES_ID) )
				for _k,_v in pairs(self.selectedShip) do
					self:_print( "## Lua ShipsDevelopScene.lua self.selectedShip _k: " .. tostring(_k) )
					self:_print( "## Lua ShipsDevelopScene.lua self.selectedShip _v: " .. tostring(_v) )
					local isSelect = ( _k ==  "shipId" )
					if( isSelect ) then
						-- cc.UserDefault:getInstance():setStringForKey("global_shipdevelopscene_selected_ship", tostring(_v))
						-- cc.UserDefault:flush()
						-- cc.UserDefault:getInstance():setStringForKey("global_shipdevelopscene_selected_ship_time", tostring(os.time()))
						-- cc.UserDefault:flush()

						cc.exports.global_shipdevelopscene_selected_ship = tostring(_v)
						cc.exports.global_shipdevelopscene_selected_ship_time = tostring(os.time())
					end
				end

			end
			self.selectedShipNum = self.selectedShipNum + 1
			if v.isHave == 1 then
				self.haveShipNum = self.haveShipNum + 1
			end 
			local callback = {node = node:getChildByName("Image_select"), func = func}
            local power
            if v.guid ~= 0 then
                power = player:calShipFightPower( v.guid )
			else
                power = v.power
			end
            local shipinfo = {quality = ship.QUALITY , power = power , shipid = v.shipId , ishave = v.isHave}
			self.svd_:addElement(node,{callback = callback, shipinfo = shipinfo})
		end
	end
	self:refreshList(true)
end

function ShipsDevelopScene:refreshList(flag)
	print ( "### LUA ShipsDevelopScene.lua refreshList : " .. tostring(flag) )
	local rn = self:getResourceNode()
	for i,v in ipairs(self.allShipList) do
		if (v.type == self.mode_ or self.mode_ == 5) then
			if Tools.isEmpty(self.selectedShip) then

				self:_printGuideId()
				self:SetSelectedShip(v)


			end
			if v.shipId == self.selectedShip.shipId then
				local children = rn:getChildByName("node_list"):getChildByName("list"):getChildren()
				for k,v in pairs(children) do
					v:getChildByName("selected"):setVisible(false)
				end
				rn:getChildByName("node_list"):getChildByName("list"):getChildByTag(self.selectedShip.shipId):getChildByName("selected"):setVisible(true)
				local ship = CONF.AIRSHIP.get(v.shipId)

                local cfg_skill = CONF.WEAPON.get(ship.SKILL)
--				rn:getChildByName("Skilldes"):setString(CONF:getStringValue("BUFF_M50017")..CONF:getStringValue("weapon")..":"..setMemo( cfg_skill ,4))
                self:setSkilldes(cfg_skill)
				if rn:getChildByName("roleNode"):getChildByName("node_ship") then
					rn:getChildByName("roleNode"):getChildByName("node_ship"):removeFromParent();
				end
				local node_ship = require("app.ExResInterface"):getInstance():FastLoad("sfx/"..ship.RES_ID);
				rn:getChildByName("roleNode"):addChild(node_ship);
				node_ship:setName("node_ship");
				node_ship:setScale(3,3);
				animManager:runAnimByCSB(node_ship, "sfx/"..ship.RES_ID, "attack_2");
				local info = rn:getChildByName("info")
				info:getChildByName("quality"):setTexture("ShipQuality/quality_"..ship.QUALITY..".png")
				info:getChildByName("ship_name"):setString(CONF:getStringValue(ship.NAME_ID))
				local cfg_breakNum = CONF.SHIP_BREAK.get(ship.QUALITY).NUM
				for i=1,6 do
					info:getChildByName("star"..i):setVisible(i<=cfg_breakNum)
					info:getChildByName("star"..i):setTexture("Common/ui/ui_star_gray.png")
					if i <= v.breakNum then
						info:getChildByName("star"..i):setTexture("Common/ui/ui_star_light.png")
					end
				end
				info:getChildByName("pow"):setString(CONF:getStringValue("combat")..":")
				if v.guid ~= 0 then
					info:getChildByName("power"):setString(player:calShipFightPower( v.guid ))
				else
					info:getChildByName("power"):setString(v.power)
				end
				-- local btnText = CONF:getStringValue("")
				local btnText = CONF:getStringValue("ships_details")
				-- rn:getChildByName("info"):getChildByName("Button"):setVisible(v.isHave == 1)
				self:jindu(v)
				if v.isHave == 0 then
					if v.needBluePrintNum <= v.haveBluePrintNum then
						self:_print( "###LUA ShipsDevelopScene.lua 291 dianjihecheng" )
						btnText = CONF:getStringValue("clicking_synthesis")
						
					else
						rn:getChildByName("info"):getChildByName("Node_1"):setVisible(true)
						for i=1,6 do
							info:getChildByName("star"..i):setVisible(false)
						end
						btnText = CONF:getStringValue("get way")
					end
				end
				info:getChildByName("Button"):setVisible(false)
				rn:getChildByName("detail"):getChildByName("text"):setString(btnText);
				break
			end
		end
	end
	local shipId = self.selectedShip.shipId
	if self.data_ and self.data_.id and flag then
		shipId = self.data_.id
	end
	rn:getChildByName("node_list"):getChildByName("list"):getInnerContainer():setPosition(0,-(rn:getChildByName("node_list"):getChildByName("list"):getChildByTag(shipId):getPositionY()-rn:getChildByName("node_list"):getChildByName("list"):getContentSize().height))
	rn:getChildByName("node_list"):getChildByName("ship_num"):setString(CONF:getStringValue("sumNum")..": ".. self.haveShipNum.."/"..self.selectedShipNum)

end


function ShipsDevelopScene:onEnterTransitionFinish()
	print ( "### LUA ShipsDevelopScene.lua onEnterTransitionFinish" )

	guideManager:checkInterface(CONF.EInterface.kShips)
	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

	if g_System_Guide_Id ~= 0 then
		print ( "### LUA ShipsDevelopScene.lua createGuideLayer: " .. tostring(g_System_Guide_Id) )
		systemGuideManager:createGuideLayer(g_System_Guide_Id)
	end

	-- GUIDE BUG! EDIT BY WJJ 180702
	--[[
	if self.data_ and self.data_.type then
		self.mode_ = self.data_.type
	end

	if not self.data_ or not self.data_.type then
		self.mode_ = 5
	end
	]]

	self.mode_ = 5

	local rn = self:getResourceNode()
    self.NoBugShipList = player:getShipList()
	self:getShipList()
	self.svd_ = require("util.ScrollViewDelegate"):create(rn:getChildByName("node_list"):getChildByName("list") ,cc.size(5,3), cc.size(140 ,105)) 
	self.svd_:getScrollView():setScrollBarEnabled(false)
	if guideManager:getGuideType() and guideManager:guideFinish() == false then
   		rn:getChildByName("node_list"):getChildByName("list"):setTouchEnabled(false)
    end
	self:changeMode()
	local label = {"attack","defense","control","treat","ships_whole"}
	rn:getChildByName("title"):setString(CONF:getStringValue("BuildingName_2"))
	-- rn:getChildByName("Image_22_0"):setPositionX(rn:getChildByName("title"):getPositionX()+rn:getChildByName("title"):getContentSize().width+5)
	for i=1,5 do
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("text"):setString(CONF:getStringValue(label[i]))
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("text_selected"):setString(CONF:getStringValue(label[i]))
		rn:getChildByName("all_btn"):getChildByName("node_"..i):getChildByName("btn"):addClickEventListener(function()
			playEffectSound("sound/system/tab.mp3")
			self.mode_ = i
			self:SetSelectedShip({})
			self:changeMode()
		end)
	end
    -- sortBy
    local function sortbyquality(a,b)
        if a.config.shipinfo.ishave == b.config.shipinfo.ishave then
            if a.config.shipinfo.quality == b.config.shipinfo.quality then
                return a.config.shipinfo.shipid > b.config.shipinfo.shipid
            else
                return a.config.shipinfo.quality > b.config.shipinfo.quality
            end
        else
            return a.config.shipinfo.ishave > b.config.shipinfo.ishave
        end
    end

    local function sortbypower(a,b)
        if a.config.shipinfo.ishave == b.config.shipinfo.ishave then
            if a.config.shipinfo.power == b.config.shipinfo.power then
                return a.config.shipinfo.shipid > b.config.shipinfo.shipid
            else
                return a.config.shipinfo.power > b.config.shipinfo.power
            end
        else
            return a.config.shipinfo.ishave > b.config.shipinfo.ishave
        end
    end

    rn:getChildByName("Button_1"):addClickEventListener(function()
        self:changeMode()
        self.svd_:sortElement(sortbyquality)
    end)
    rn:getChildByName("Button_2"):addClickEventListener(function()
        self:changeMode()
        self.svd_:sortElement(sortbypower)
    end)

	-- local animManager = require("app.AnimManager"):getInstance()
	animManager:runAnimByCSB(rn:getChildByName("texiao"), "ShipsScene/sfx/huoxing/huoxing.csb", "1")
	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_SHIP_DEVELOPE_RESP") then
			gl:releaseLoading()
			local proto = Tools.decode("ShipDevelopeResp",strData)
			if proto.result ~= 0 then
				self:_print("error: CMD_SHIP_DEVELOPE_RESP",proto.result)
				return
			else
				self:changeMode()
				if guideManager:getGuideType() then
					-- guideManager:doEvent("recv")
					self:getApp():removeTopView()

					if guideManager:getSelfGuideID() > 50 then
						guideManager:addGuideStep(98)
					else
						guideManager:addGuideStep(38)
					end
				end

				self:_print("CMD_SHIP_DEVELOPE_RESP ok: guid %d",proto.ship_guid)
				playEffectSound("sound/system/building_upgrade.mp3")

				local ship_str = ""
				for i,v in ipairs(player:getShipList()) do
					if ship_str ~= "" then
						ship_str = ship_str.."-"
					end 

					ship_str = ship_str..v.id
				end

				flurryLogEvent("get_new_ship", {ship_num = tostring(player:getShipListSize()), ship_id = ship_str}, 2)
				-- flurryLogEvent("get_new_ship", {ship_type = tostring(v.quality), ship_id = tostring(v.id)}, 2)

				local layer = self:getApp():createView("ShipDevelopScene/DevelopSucessLayer", {data = CONF.AIRSHIP.get(proto.ship_id)})
				self:addChild(layer)

				-- WJJ 20180727
				require("util.ExConfigScreenAdapterFixedHeight"):getInstance():onFixQuanMianPing_GetNewShip_Hecheng(layer)

				self:getShipList()
				if cc.exports.new_hand_gift_bag_data then
					if Tools.isEmpty(player:getNewHandGift()) == false then
						local layer2 = self:getApp():createView("AdventureLayer/AdventureLayer",{new = true})
						layer2:setPosition(cc.exports.VisibleRect:leftBottom())
						self:addChild(layer2)
					end
				end
			end
		end
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local   eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)
	local func = function()

		self:getShipList()
		for i,v in ipairs(self.allShipList) do
			if v.shipId == self.selectedShip.shipId then
				self:SetSelectedShip(v)
				break
			end
		end
		if Tools.isEmpty(self.selectedShip) then
			return
		end
		local ship = CONF.AIRSHIP.get(self.selectedShip.shipId)

--        local cfg_skill = CONF.WEAPON.get(ship.SKILL)
--		rn:getChildByName("Skilldes"):setString(CONF:getStringValue("BUFF_M50017")..CONF:getStringValue("weapon")..":"..setMemo( cfg_skill ,4))
--        self:setSkilldes(cfg_skill)
		if rn:getChildByName("roleNode"):getChildByName("node_ship") == nil then
			local node_ship = require("app.ExResInterface"):getInstance():FastLoad("sfx/"..ship.RES_ID);
			rn:getChildByName("roleNode"):addChild(node_ship);
			node_ship:setName("node_ship");
			node_ship:setScale(3,3);
			animManager:runAnimByCSB(node_ship, "sfx/"..ship.RES_ID, "attack_2");
		end

		local info = rn:getChildByName("info")
		info:getChildByName("quality"):setTexture("ShipQuality/quality_"..ship.QUALITY..".png")
		info:getChildByName("ship_name"):setString(CONF:getStringValue(ship.NAME_ID))
		local cfg_breakNum = CONF.SHIP_BREAK.get(ship.QUALITY).NUM
		for i=1,6 do
			info:getChildByName("star"..i):setVisible(i<=cfg_breakNum)
			info:getChildByName("star"..i):setTexture("Common/ui/ui_star_gray.png")
			if i <= self.selectedShip.breakNum then
				info:getChildByName("star"..i):setTexture("Common/ui/ui_star_light.png")
			end
		end
		info:getChildByName("pow"):setString(CONF:getStringValue("combat")..":")
		if self.selectedShip.guid ~= 0 then
			info:getChildByName("power"):setString(player:calShipFightPower( self.selectedShip.guid ))
		else
			info:getChildByName("power"):setString(self.selectedShip.power)
		end
		local btnText = CONF:getStringValue("ships_details")
		self:jindu(self.selectedShip)
		if self.selectedShip.isHave == 0 then
			if self.selectedShip.needBluePrintNum <= self.selectedShip.haveBluePrintNum then
				self:_print( "###LUA ShipsDevelopScene.lua 443 dianjihecheng" )
				btnText = CONF:getStringValue("clicking_synthesis")
				
			else
				rn:getChildByName("info"):getChildByName("Node_1"):setVisible(true)
				for i=1,6 do
					info:getChildByName("star"..i):setVisible(false)
				end
				btnText = CONF:getStringValue("get way")
			end
		end
		info:getChildByName("Button"):setVisible(false)
		rn:getChildByName("detail"):getChildByName("text"):setString(btnText);
	end
	self.scheduler = scheduler:scheduleScriptFunc(func,1,false)  

	-- ADD WJJ 20180723
	require("util.ExConfigScreenAdapter"):getInstance():onFixQuanmianping_Jiku(self)
end

function ShipsDevelopScene:creatShipNode(info)
	local cfg_ship = CONF.AIRSHIP.get(info.shipId)
	local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/shipNode2.csb")
	node:getChildByName("ship_state"):setVisible(false)
	node:getChildByName("state_bg_7"):setVisible(false)
	node:getChildByName("redpoint"):setVisible(false)
	local ship = player:getShipByGUID(info.guid)
	if ship then		
		if Bit:has(ship.status, 4) == true then
			node:getChildByName("ship_state"):setVisible(true)
			node:getChildByName("state_bg_7"):setVisible(true)
			node:getChildByName("ship_state"):setString(CONF:getStringValue("planeting"))
		end
	end

	print("info.guid",info.guid)
	if info.guid > 0 and player:IsInForms(info.guid) then
		node:getChildByName("ship_state"):setVisible(true)
		node:getChildByName("state_bg_7"):setVisible(true)
		node:getChildByName("ship_state"):setString(CONF:getStringValue("Go_to_battle"))
	end

	node:getChildByName("black"):setVisible(info.isHave == 0)
	node:getChildByName("Sprite_type"):setTexture("ShipType/"..info.type..".png")
	
	self:_print( "###LUA ShipsDevelopScene.lua 479 kehecheng " )
	node:getChildByName("kehecheng"):setString(CONF:getStringValue("can_synthesis"))
	node:getChildByName("kehecheng"):setVisible(false)
	if info.isHave == 0 then
		node:getChildByName("Sprite_type"):setTexture("ShipType/"..info.type.."gray.png")
		-- ADD WJJ 20180702
		info = self.guideHelper:OnBugFix_KEHECHENG_VISIBLE( guideManager.guide_id, info )
		if info.needBluePrintNum <= info.haveBluePrintNum then
			node:getChildByName("kehecheng"):setVisible(true)
		end
	else
		if ship then
			local cfg_break = CONF.SHIP_BREAK.get(cfg_ship.QUALITY)
			local nextLevel = ship.ship_break + 1
			local up = true
			local item = {}
			for k,v in ipairs(cfg_break["ITEM_ID"..nextLevel]) do
				local t = {}
				t.id = v
				t.num = cfg_break["ITEM_NUM"..nextLevel][k]
				table.insert(item,t)
			end
			local t = {}
			t.num = CONF.SHIP_BLUEPRINTBREAK.get(cfg_ship.QUALITY)["ITEM_NUM"..nextLevel]
			t.id = info.blueprintId
			table.insert(item,t)
			for k,v in ipairs(item) do
				if player:getItemNumByID(v.id) < v.num then
					up = false
				end
			end

            if up then
                local cfg_ship = CONF.AIRSHIP.get(ship.id)
                local cfg_break = CONF.SHIP_BREAK.get(cfg_ship.QUALITY)
                if ship.level < cfg_break["NEED_LEVEL"..(ship.ship_break+1)] then
                    up = false
                end
            end

			if not up then--比装备
                local param = CONF.PARAM.get("city_16_open").PARAM
		        if player:getLevel() >= param[1] then
				    local haveType = {}
				    for k,v in ipairs(ship.equip_list) do
					    if v ~= 0 and player:getEquipByGUID(v) then
						    local ec = CONF.EQUIP.get(player:getEquipByGUID(v).equip_id)
						    table.insert(haveType,ec)
					    end
				    end
				    for i=1,4 do
					    local ec 
					    for k,v in ipairs(haveType) do
						    if i == v.TYPE then
							    ec = v
						    end
					    end
					    local equips = player:getAllUnequipListWithType(i,info.guid)
					    if ec then
						    for k,v in ipairs(equips) do
							    if v.level <= ship.level and v.level > ec.LEVEL and v.ship_id ~= ship.guid then
								    up = true
								    print("@@@@@@@@@@@@@@@@@",v.level,ec.LEVEL)
								    break
							    end
						    end
					    else
						    if Tools.isEmpty(equips) == false then
	                            local function sort( a,b )
                                    if a.level < b.level then
                                        return true
                                    end
	                            end
	                            table.sort(equips, sort)
                                if equips[1].level <= ship.level and equips[1].ship_id ~= ship.guid then
							        up = true
							        print("@@@@@@@@@@@@@@@@@ no")
                                end
						    end
					    end
					    if up then
						    break
					    end
				    end
                end
			end
			node:getChildByName("redpoint"):setVisible(up)
		end

	end
	node:getChildByName("Sprite_role"):setTexture("ShipImage/"..cfg_ship.ICON_ID..".png")
	node:getChildByName("bg"):setTexture("ShipsScene/ui/ui_avatar_"..cfg_ship.QUALITY..".png")
	node:getChildByName("type"):setTexture("ShipQuality/quality_"..cfg_ship.QUALITY..".png")
	return node
end

function ShipsDevelopScene:setSkilldes(cfg_skill)
    local rn = self:getResourceNode()
    local str = CONF:getStringValue("BUFF_M50017")..CONF:getStringValue("weapon")..":"..setMemo( cfg_skill ,4)
    local skilllist = rn:getChildByName("SkillScrollview")
    skilllist:removeAllChildren()
    skilllist:setScrollBarEnabled(false)
    local listSize = skilllist:getContentSize()
    local label = cc.Label:createWithTTF(str, s_default_font, 16)
    label:setLineBreakWithoutSpace(true)
	label:setMaxLineWidth(listSize.width)
    local inner_height
    if label:getContentSize().height > listSize.height then
		inner_height = label:getContentSize().height
		label:setPosition(0, inner_height)
        skilllist:setTouchEnabled(true)
	else
		inner_height = listSize.height
		label:setPosition(0, inner_height - (inner_height-label:getContentSize().height)*0.5)
		skilllist:setTouchEnabled(false)
	end
    label:setAnchorPoint(cc.p(0, 1))
    label:setHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    skilllist:setInnerContainerSize(cc.size(listSize.width, inner_height))
    label:setName("label")
    skilllist:addChild(label)
end


function ShipsDevelopScene:onExitTransitionStart()
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	scheduler:unscheduleScriptEntry(self.scheduler)
	
	if self.svd_ then
		self.svd_:clear()
	end
end

return ShipsDevelopScene