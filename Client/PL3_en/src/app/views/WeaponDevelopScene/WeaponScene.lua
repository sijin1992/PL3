local g_player = require("app.Player"):getInstance()

local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local WeaponScene = class("WeaponScene", cc.load("mvc").ViewBase)

local animManager = require("app.AnimManager"):getInstance()

WeaponScene.RESOURCE_FILENAME = "WeaponDevelopScene/WeaponScene.csb"

WeaponScene.NEED_ADJUST_POSITION = true

WeaponScene.RESOURCE_BINDING = {
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function WeaponScene:OnBtnClick(event)
	if event.name == "ended" then
		if event.target:getName() == "close" then
			playEffectSound("sound/system/return.mp3")
			self:getApp():popView()
			-- self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
		end
	end
end

function WeaponScene:onCreate( data )
	if data and data.id then 
		self.id = data.id
	else
		self.id = nil
	end
end

function WeaponScene:onEnterTransitionFinish()

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	-- if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kWeaponDevelop)== 0 and g_System_Guide_Id == 0 then
	-- 	systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("wqyj_open").INTERFACE)
	-- else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	-- end

	
	local rn = self:getResourceNode()
	local title = rn:getChildByName("title")
	title:setString(CONF.STRING.get("BuildingName_4").VALUE)
	self.prePieceTag = -1  
	self:AddPiece()

	local eventDispatcher = self:getEventDispatcher()
	self.level_ = g_player:getBuildingInfo(CONF.EBuilding.kWeaponDevelop).level

	local strData = Tools.encode("WeaponUpgradeReq", {
		type = 1,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_WEAPON_UPGRADE_REQ"),strData)
	gl:retainLoading()

	local function recvMsg()
		local cmd,strData = GameHandler.handler_c.recvProtobuf()
		if cmd == Tools.enum_id("CMD_DEFINE","CMD_WEAPON_UPGRADE_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("WeaponUpgradeResp",strData)
			if proto.type == 1 then
				if proto.result == 0 then
					print("result",  proto.result)
				else
					print("CMD_WEAPON_UPGRADE_RESP error:",proto.result)
				end
				if self.id == nil then 
					self:ChangeState(1)
				else 
					self:ChooseWeapon()
				end               
			end
		end
	end
	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	local function updateList(  )
		self:resetItem()
	end
	self.updatelistener_ = cc.EventListenerCustom:create("update_weapon_list", updateList)
	eventDispatcher:addEventListenerWithFixedPriority(self.updatelistener_, FixedPriority.kNormal)

	animManager:runAnimOnceByCSB( self, "WeaponDevelopScene/WeaponScene.csb", "intro")
end

function WeaponScene:ChooseWeapon(  )
	local conf = CONF.WEAPON.get(self.id)
	self:ChangeState(conf.TYPE)
	local selectedNode = self.svd:getScrollView():getChildByTag(self.id)
	selectedNode:getChildByName("selectBg"):setVisible(true)
	self.selectedNodeTag = self.id
	
	local layer = self:getApp():createView("WeaponDevelopScene/UpgradeLayer",{id = self.id})
	local center = cc.exports.VisibleRect:center()
	tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))

	self:addChild(layer)


	local nextConf = CONF.WEAPON.check(conf.ID + 1)
	local lvText = selectedNode:getChildByName("lv")
	if nextConf then
		print("conf.LEVEL", conf.LEVEL)
		lvText:setString("Lv." .. conf.LEVEL)       
		if g_player:getBuildingInfo(CONF.EBuilding.kWeaponDevelop).level < nextConf.BUILDING_LEVEL then
			selectedNode:getChildByName("arrow"):setVisible(false)
		end
	else
		tips:tips(CONF.STRING.get("max_level").VALUE)
		selectedNode:getChildByName("arrow"):setVisible(false)
		selectedNode:getChildByName("white"):setVisible(false)
		--selectedNode:getChildByName("yellow"):setVisible(true)
		local max = selectedNode:getChildByName("max")
		max:setVisible(true)
		lvText:setString("Lv.")
		lvText:setPositionX(max:getPositionX() - lvText:getContentSize().width/2)
	end 
end

function WeaponScene:resetItem(  )
	local selectedNode = self.svd:getScrollView():getChildByTag(self.selectedNodeTag)
	local conf = CONF.WEAPON.get(self.selectedNodeTag + 1)
	local lvText = selectedNode:getChildByName("lv")
	selectedNode:setTag(conf.ID)
	self.selectedNodeTag = conf.ID

	local nextConf = CONF.WEAPON.check(conf.ID + 1)
	if nextConf then
		lvText:setString("Lv." .. conf.LEVEL)
		if g_player:getBuildingInfo(CONF.EBuilding.kWeaponDevelop).level < nextConf.BUILDING_LEVEL then
			selectedNode:getChildByName("arrow"):setVisible(false)
		end
	else
		selectedNode:getChildByName("arrow"):setVisible(false)
		selectedNode:getChildByName("white"):setVisible(false)
		--selectedNode:getChildByName("yellow"):setVisible(true)
		local max = selectedNode:getChildByName("max")
		max:setVisible(true)
		lvText:setString("Lv.")
		lvText:setPositionX(max:getPositionX() - lvText:getContentSize().width/2)
	end 
end

function WeaponScene:AddListItem( tag )
	self.svd:clear()
	local num = 1
	local currentText = require("app.ExResInterface"):getInstance():FastLoad("WeaponDevelopScene/TextNode.csb")
	currentText:getChildByName("text1"):setString(CONF:getStringValue("current"))
	currentText:getChildByName("text2"):setVisible(false)
	self.svd:addElement(currentText)
	self.svd:resetConfig(1,{size = cc.size(650 ,25)})

	local function onLevelUp( sender )

		local weapon_id = sender:getParent():getTag()
		local nextConf = CONF.WEAPON.check(weapon_id)
		if nextConf then
			local layer = self:getApp():createView("WeaponDevelopScene/UpgradeLayer",{id = weapon_id})
			local center = cc.exports.VisibleRect:center()
			tipsAction(layer, cc.p(center.x + (self:getResourceNode():getContentSize().width/2 - center.x), center.y + (self:getResourceNode():getContentSize().height/2 - center.y)))

			self:addChild(layer)
		else
			tips:tips(CONF.STRING.get("max_level").VALUE)
		end

		local node = sender:getParent()
		if self.selectedNodeTag ~= nil then 
			local selectedNode = self.svd:getScrollView():getChildByTag(self.selectedNodeTag)
			selectedNode:getChildByName("selectBg"):setVisible(false)
		end
		node:getChildByName("selectBg"):setVisible(true)
		self.selectedNodeTag = node:getTag() 
	end

	for i=1,self.level_ do
		local conf = CONF[string.format("BUILDING_%d", CONF.EBuilding.kWeaponDevelop)].get(i)
		if conf.WEAPON_LIST == nil or conf.WEAPON_LIST == "" then

		else
			for j=1,#conf.WEAPON_LIST do

				local weaponConf = CONF.WEAPON.get(conf.WEAPON_LIST[j])
				if weaponConf.TYPE == tag then
					local node = self:createWeaponElement(conf.WEAPON_LIST[j])
					num = num +1 
					self.svd:addElement(node)
					self.svd:addListener(node:getChildByName("weapon"), onLevelUp)
				end        
			end
		end
		
	end

	if num == 1 then 
		self.svd:removeElement( 1 )
		self.svd:resetAllElementPosition()
		num = 0
	end

	local buildingIDNum = #CONF[string.format("BUILDING_%d", CONF.EBuilding.kWeaponDevelop)].getIDList()

	local conf
	for i=self.level_ + 1,buildingIDNum do
		local tempConf = CONF[string.format("BUILDING_%d", CONF.EBuilding.kWeaponDevelop)].get(i)
		if tempConf and tempConf.WEAPON_LIST and tempConf.WEAPON_LIST ~= "" and Tools.isEmpty(tempConf.WEAPON_LIST) == false then
			conf = tempConf
			break
		end
	end

	local commandText = require("app.ExResInterface"):getInstance():FastLoad("WeaponDevelopScene/TextNode.csb")
	commandText:getChildByName("text1"):setString(CONF:getStringValue("toActivate"))
	local text2 = commandText:getChildByName("text2")
	local str = string.format("(%s  Lv. %d)",CONF.STRING.get("BuildingName_4").VALUE ,self.level_ + 1)
	text2:setString(str)
	--text2:setFontSize(20)
	self.svd:addElement(commandText)
	self.svd:resetConfig(num + 1 ,{size = cc.size(650 ,25)})
	
	local num2 = 0
	if conf then
		for j=1,#conf.WEAPON_LIST do

			local weaponConf = CONF.WEAPON.get(conf.WEAPON_LIST[j])
			if weaponConf.TYPE == tag then
				local node = self:createWeaponElement(conf.WEAPON_LIST[j], true)
				num2 = num2 + 1 
				self.svd:addElement(node)
				self.svd:addListener(node:getChildByName("weapon"), onLevelUp)
			end
		end
	end

	if num2 == 0 then 
		self.svd:removeElement(num + 1 )
	end
	self.svd:resetAllElementPosition()
end

function WeaponScene:createWeaponElement( weapon_id ,close )
	local node = require("app.ExResInterface"):getInstance():FastLoad("WeaponDevelopScene/WeaponNode.csb")
	local temp_id = math.floor(weapon_id / 10) *10
	local weapon = g_player:getWeaponByTemp(temp_id)
	local conf = CONF.WEAPON.get(weapon and weapon.weapon_id or weapon_id)

	if not weapon or (close and close == true) then--创建 即将开放的weapon
		node:getChildByName("white"):setLocalZOrder(10)
		local sprite = node:getChildByName("weapon")
		local pos = cc.p(sprite:getPosition())
		local width = sprite:getContentSize().width
		local lvText = node:getChildByName("lv")
		lvText:setString(string.format(lvText:getString(), 0))
		node:getChildByName("arrow"):setVisible(false)
		sprite:removeFromParent()

		local gray = mc.EffectGreyScale:create()
		sprite = mc.EffectSprite:create(string.format("WeaponIcon/%d.png", conf.ICON_ID))
		sprite:setName("weapon")
		sprite:setAnchorPoint(cc.p(0,1))
		--sprite:setScale(1.0 * width / sprite:getContentSize().width )
		sprite:setPosition(pos)
		sprite:setLocalZOrder(1)
		sprite:setEffect(gray)
		node:addChild(sprite)
		--node:getChildByName("weapon"):setTag(weapon_id)
		node:setTag(conf.ID)
	else
		node:getChildByName("weapon"):loadTexture(string.format("WeaponIcon/%d.png", conf.ICON_ID))
		local lvText = node:getChildByName("lv")
	   
		--node:getChildByName("weapon"):setTag(weapon.weapon_id)  
		node:setTag(conf.ID)  

		local nextConf = CONF.WEAPON.check(weapon_id + conf.LEVEL )
		if nextConf then
			lvText:setString(string.format(lvText:getString(), conf.LEVEL))
			if g_player:getBuildingInfo(CONF.EBuilding.kWeaponDevelop).level < nextConf.BUILDING_LEVEL then
				node:getChildByName("arrow"):setVisible(false)
			end
		else
			node:getChildByName("arrow"):setVisible(false)
			node:getChildByName("white"):setVisible(false)
			--node:getChildByName("yellow"):setVisible(true)
			local max = node:getChildByName("max")
			max:setVisible(true)
			lvText:setString("Lv.")
			lvText:setPositionX(max:getPositionX() - lvText:getContentSize().width/2)
		end   
	end
	return node
end

function WeaponScene:AddList( tag )
	self.pieceType = tag
	local rn = self:getResourceNode()
	rn:getChildByTag(tag):getChildByName("piece"):loadTexture("Common/newUI/bz_yq_light.png")

	local listPos = rn:getChildByName("title")
	local posX = listPos:getPositionX()
	local posY = listPos:getPositionY() - (tag - 1) * (rn:getChildByTag(tag):getChildByName("piece"):getContentSize().height+5) - 120
	local node = require("app.ExResInterface"):getInstance():FastLoad("WeaponDevelopScene/listNode.csb")   
	if self.listH == nil then 
	
		local pice1 = rn:getChildByTag(1)
		--self.listH = pice1:getPositionY()  - (rn:getChildByTag(tag):getChildByName("piece"):getContentSize().height+5) * 4  - 5
		self.listH = 290
	end
	local list = node:getChildByName("list")
	list:setScrollBarEnabled(false)
	list:setContentSize(cc.size(650 ,self.listH))
	rn:addChild(node)
	node:setPosition(cc.p(posX ,posY))
	node:setName("sv")
	self.svd = require("util.ScrollViewDelegate"):create( list,cc.size(30,10), cc.size(122 ,122))
	self:AddListItem( tag)
	if tag < 4 then 
		for i=tag + 1 ,4 do
			local node = rn:getChildByTag(i)
			node:setPositionY(node:getPositionY() - self.listH)
		end     
	end
end

function WeaponScene:RemoveList( tag )
	local rn = self:getResourceNode()
	self.svd = nil
	local node = rn:getChildByTag(tag)
	-- node:getChildByName("arrow"):setRotation(0)
	node:getChildByName("piece"):loadTexture("Common/newUI/bz_yq.png")

	if rn:getChildByName("sv") then 
		rn:getChildByName("sv"):removeFromParent()
		if tag < 4 then 
			for i=tag + 1 ,4 do
				local node = rn:getChildByTag(i)
				node:setPositionY(node:getPositionY() + self.listH)
			end     
		end
	end 

	if self.prePieceTag ~= -1 then 
		rn:getChildByName("title"..self.prePieceTag):getChildByName("list_open"):setVisible(false)
	end
end

function WeaponScene:ChangeState( tag )
	local rn = self:getResourceNode()
	for i=1,4 do
		rn:getChildByName("title"..i):getChildByName("list_open"):setVisible(tag == i)
	end

	self.selectedNodeTag = nil
	if self.prePieceTag == -1 then 
		self.prePieceTag = tag 
		self:AddList(tag)
	elseif self.prePieceTag == tag then
		self:RemoveList(tag)
		self.prePieceTag = -1
	else 
		self:RemoveList(self.prePieceTag)
		self.prePieceTag = tag
		self:AddList(self.prePieceTag)
	end
end

function WeaponScene:AddPiece()
	-- local isTouchMe = false
	-- local function onTouchBegan(touch, event)
	-- 	local target = event:getCurrentTarget()
	-- 		local locationInNode = target:convertToNodeSpace(touch:getLocation())
	-- 		local s = target:getContentSize()
	-- 		local rect = cc.rect(0, 0, s.width, s.height)
	-- 		if cc.rectContainsPoint(rect, locationInNode) then
	-- 			isTouchMe = true
	-- 			return true
	-- 		end
	-- 	return false
	-- end

	-- local function onTouchMoved( touch ,event )
	-- 	local delta = touch:getDelta()
	-- 	if math.abs(delta.x) > g_click_delta or math.abs(delta.x) > g_click_delta then
	-- 		isTouchMe = false
	-- 	end
	-- end

	-- local function onTouchEnded(touch, event)
	-- 	if isTouchMe == true then
	-- 		self:ChangeState(event:getCurrentTarget():getParent():getTag())
	-- 		playEffectSound("sound/system/tab.mp3")
	-- 	end
	-- end

	-- local eventDispatcher = self:getEventDispatcher()
	-- local listener = cc.EventListenerTouchOneByOne:create()
	-- listener:setSwallowTouches(false)
	-- listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	-- listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
	-- listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

	local function add(name ,index )
		local rn = self:getResourceNode()
		local piecePos = rn:getChildByName("title")
		local node = require("app.ExResInterface"):getInstance():FastLoad("TaskScene/PieceNode.csb")
		local posX = piecePos:getPositionX() + 5
		local posY = piecePos:getPositionY() - index * (node:getChildByName("piece"):getContentSize().height+5) -5
		node:getChildByName("text"):setString(name)
		-- eventDispatcher:addEventListenerWithSceneGraphPriority(listener:clone(), node:getChildByName("piece"))
		node:getChildByName("piece"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/tab.mp3")
			local curTag = sender:getParent():getTag()
			self:ChangeState(curTag)
			
		end)
		node:setTag(index)
		node:setName("title"..index)
		node:setPosition(cc.p(posX ,posY))
		rn:addChild(node ,0)
	end 

	add(CONF.STRING.get("attack").VALUE ,1)
	add(CONF.STRING.get("defense").VALUE ,2)
	add(CONF.STRING.get("treat").VALUE ,4)
	add(CONF.STRING.get("control").VALUE ,3)
end

function WeaponScene:onExitTransitionStart()
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.updatelistener_)
end

return WeaponScene