local g_player = require("app.Player"):getInstance()
local DevelopSucessLayer = class("DevelopSucessLayer", cc.load("mvc").ViewBase)
local animManager = require("app.AnimManager"):getInstance()
local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

DevelopSucessLayer.RESOURCE_FILENAME = "ShipDevelopScene/DevelopSucessLayer.csb"

function DevelopSucessLayer:onCreate(data)
	self.conf = data.data
	self.type = nil
	if data.type then
		self.type = data.type
	end
end

function DevelopSucessLayer:onEnterTransitionFinish()
	
	local conf = self.conf
	local rn = self:getResourceNode()
	local hp = rn:getChildByName("hp")
	local def = rn:getChildByName("def")
	local at = rn:getChildByName("at")
	local sp = rn:getChildByName("sp")
	local hpText = rn:getChildByName("hpText")
	local defText = rn:getChildByName("defText")
	local atText = rn:getChildByName("atText")
	local spText = rn:getChildByName("spText")
	local shipDetail = rn:getChildByName("text")

	local et = rn:getChildByName("et")
	local etText = rn:getChildByName("etText")

	at:setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kAttack))
	def:setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kDefence))
	sp:setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kSpeed))
	hp:setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kHP))
	et:setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kEnergyAttack))
	self.over = false
	
	
	local weaponConf = CONF.WEAPON.get(conf.SKILL)
	local temp1 = rn:getChildByName("string_1")
	local temp2 = rn:getChildByName("string_1_")   
	local richText = createWeaponInfo(weaponConf, 20)
	richText:setPosition(cc.p(temp1:getPosition()))
	rn:addChild(richText)
	richText:setVisible(false)
	temp1:removeFromParent()
	temp2:removeFromParent()  

	local power = rn:getChildByName("power")
	local detail = rn:getChildByName("detail")
	local detailText = rn:getChildByName("prop_string")
	rn:getChildByName("shipIcon"):setTexture(string.format("ShipImage/%d.png", conf.ICON_ID))
	rn:getChildByName("weaponIcon"):loadTexture(string.format("WeaponIcon/%d.png", weaponConf.ICON_ID))
	rn:getChildByName("weaponName"):setString(CONF.STRING.get(weaponConf.NAME_ID).VALUE)
	power:setString(CONF:getStringValue("power"))
    rn:getChildByName("TitleName"):setString(CONF.STRING.get(conf.NAME_ID).VALUE)
    rn:getChildByName("Titlereward"):setString(CONF:getStringValue("get_reward")..":")
	rn:getChildByName("shipName"):setString(CONF.STRING.get(conf.NAME_ID).VALUE)
	detailText:setString(setMemo(weaponConf ,3))
	detail:setString(CONF.STRING.get("intro").VALUE)

	local function setData(  )
		local function setPos( left ,right )
			local x = left:getPositionX() + left:getContentSize().width + 30
			right:setPositionX(x)
		end 
		hpText:setString(conf.LIFE)
		atText:setString(conf.ATTACK)
		defText:setString(conf.DEFENCE)
		spText:setString(conf.SPEED)
		etText:setString(conf.ENERGY_ATTACK)

		detailText:setVisible(true)
		richText:setVisible(true)
		hpText:setVisible(true)
		atText:setVisible(true)
		defText:setVisible(true)
		spText:setVisible(true)
		etText:setVisible(true)
		
		setPos(hp ,hpText)
		setPos(def ,defText)
		setPos(at ,atText)
		setPos(sp ,spText)
		setPos(et, etText)
		detailText:setPositionX(detail:getPositionX() + detail:getContentSize().width + 5)       
		richText:setAnchorPoint(cc.p(0, 0.5))
		richText:setPositionX(power:getPositionX() + power:getContentSize().width + 5)
	end 

	local function onTouchBegan(touch, event)
		return true
	end

	local function onTouchEnded(touch, event)
		if self.over == true then 

			local guide 
			if guideManager:getSelfGuideID() ~= 0 then
				guide = guideManager:getSelfGuideID()
			else
				guide = g_player:getGuideStep()
			end
			print("ccccccccccccccc",guideManager:getTeshuGuideId(4),guide,guideManager:getTeshuGuideId(7))
			if guide > 38 then
				if guide == guideManager:getTeshuGuideId(7)-1 then
					guideManager:createGuideLayer(guideManager:getTeshuGuideId(7))
				end
			else
				if guide == guideManager:getTeshuGuideId(4)-1 then
					guideManager:createGuideLayer(guideManager:getTeshuGuideId(4))
				end
			end

			playEffectSound("sound/system/click.mp3")

			if self.type then
				cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("get_ship")

			else
				-- local scene = self:getParent()
				-- -- -- scene:changeType(conf.TYPE)
				-- local node =  scene:getResourceNode():getChildByName("node_list"):getChildByName("list"):getChildByTag(conf.ID)
				-- if node then 
				-- 	node:getChildByName("selectBg"):setVisible(true)      
				-- end
			end

			self:removeFromParent()

		end
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self:getResourceNode():getChildByName("bg"))



	animManager:runAnimOnceByCSB(self:getResourceNode(),"ShipDevelopScene/DevelopSucessLayer.csb" ,"intro" ,function (  )
		setData()
		self.over = true
	end)
end


function DevelopSucessLayer:onExitTransitionStart()
	printInfo("DevelopSucessLayer:onExitTransitionStart()")

end

return DevelopSucessLayer