local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local InfoLayer = class("InfoLayer", cc.load("mvc").ViewBase)

InfoLayer.RESOURCE_FILENAME = "BlueprintScene/InfoNode.csb"

InfoLayer.NEED_ADJUST_POSITION = true

function InfoLayer:onCreate(data)
	self.data_ = data
end

function InfoLayer:onEnterTransitionFinish()
	local info = self.data_
	local isHave = false
	for k,v in ipairs(player:getShipList()) do
		if info.shipId == v.id then
			isHave = true
			break
		end
	end
	local rn = self:getResourceNode()
	local cfg_ship = CONF.AIRSHIP.get(info.shipId)
	local ship_power = player:getEnemyPower(info.shipId)
	local ship_hp = cfg_ship.LIFE
	local ship_defence = cfg_ship.DEFENCE
	local ship_speed = cfg_ship.SPEED
	local ship_atk = cfg_ship.ATTACK
	local ship_eatk = cfg_ship.ENERGY_ATTACK
	local ship_durable = cfg_ship.DURABLE.."/"..cfg_ship.DURABLE
	if isHave then
		local ship = player:getShipByID(info.shipId)
		local calship = player:calShip(ship.guid)
		ship_power = player:calShipFightPower( ship.guid )
		ship_hp = calship.attr[CONF.EShipAttr.kHP]
		ship_defence = calship.attr[CONF.EShipAttr.kDefence]
		ship_speed = calship.attr[CONF.EShipAttr.kSpeed]
		ship_atk = calship.attr[CONF.EShipAttr.kAttack]
		ship_eatk = calship.attr[CONF.EShipAttr.kEnergyAttack]
		ship_durable = ship.durable.."/"..Tools.getShipMaxDurable(ship)
	end
	local atk = rn:getChildByName("atk")
	local defence = rn:getChildByName("defence")
	local speed = rn:getChildByName("speed")
	local blood = rn:getChildByName("blood")
	local e_atk = rn:getChildByName("e_atk")
	local durable = rn:getChildByName("durable")

	atk:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kAttack)..":")
	defence:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kDefence)..":")
	speed:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kSpeed)..":")
	blood:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kHP)..":")
	e_atk:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kEnergyAttack)..":")
	durable:getChildByName("text"):setString(CONF:getStringValue("durable")..":")
	atk:getChildByName("num"):setString(ship_atk)
	defence:getChildByName("num"):setString(ship_defence)
	speed:getChildByName("num"):setString(ship_speed)
	blood:getChildByName("num"):setString(ship_hp)
	e_atk:getChildByName("num"):setString(ship_eatk)
	durable:getChildByName("num"):setString(ship_durable)


	atk:getChildByName("num"):setPosition(atk:getChildByName("text"):getPositionX()+atk:getChildByName("text"):getContentSize().width+5,atk:getChildByName("text"):getPositionY())
	defence:getChildByName("num"):setPosition(defence:getChildByName("text"):getPositionX()+defence:getChildByName("text"):getContentSize().width+5,defence:getChildByName("text"):getPositionY())
	speed:getChildByName("num"):setPosition(speed:getChildByName("text"):getPositionX()+speed:getChildByName("text"):getContentSize().width+5,speed:getChildByName("text"):getPositionY())
	blood:getChildByName("num"):setPosition(blood:getChildByName("text"):getPositionX()+blood:getChildByName("text"):getContentSize().width+5,blood:getChildByName("text"):getPositionY())
	e_atk:getChildByName("num"):setPosition(e_atk:getChildByName("text"):getPositionX()+e_atk:getChildByName("text"):getContentSize().width+5,e_atk:getChildByName("text"):getPositionY())
	durable:getChildByName("num"):setPosition(durable:getChildByName("text"):getPositionX()+durable:getChildByName("text"):getContentSize().width+5,durable:getChildByName("text"):getPositionY())

	rn:getChildByName("quality"):setTexture("ShipQuality/quality_"..cfg_ship.QUALITY..".png")
	rn:getChildByName("ship_type"):setTexture(string.format("ShipType/%d.png", cfg_ship.TYPE))
	rn:getChildByName("shipName"):setString(CONF:getStringValue(cfg_ship.NAME_ID))
	rn:getChildByName("power"):setString(ship_power)
    rn:getChildByName("develop"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	rn:getChildByName("develop"):addClickEventListener(function()
		self:removeFromParent()
		end)
	rn:getChildByName("shipIcon"):setTexture("WeaponIcon/"..cfg_ship.SKILL..".png")
	rn:getChildByName("skillName"):setString(CONF:getStringValue(CONF.WEAPON.get(cfg_ship.SKILL).NAME_ID))
	rn:getChildByName("skilldes"):setString(setMemo( CONF.WEAPON.get(cfg_ship.SKILL) ,4))
end

function InfoLayer:onExitTransitionStart()
	printInfo("InfoLayer:onExitTransitionStart()")
end

return InfoLayer