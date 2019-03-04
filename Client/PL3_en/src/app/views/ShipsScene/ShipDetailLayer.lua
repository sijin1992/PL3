local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local ShipDetailLayer = class("ShipDetailLayer", cc.load("mvc").ViewBase)

ShipDetailLayer.RESOURCE_FILENAME = "ShipsScene/ship/ShipDetailNode.csb"

ShipDetailLayer.NEED_ADJUST_POSITION = true

function ShipDetailLayer:onCreate(data)
	self.data_ = data
end

function ShipDetailLayer:onEnterTransitionFinish()
	local rn = self:getResourceNode()

	rn:getChildByName("Image_44"):setSwallowTouches(false)
	rn:getChildByName("Image_44"):addClickEventListener(function()
		self:removeFromParent()
		end)
	rn:getChildByName("Button_close"):addClickEventListener(function()
		self:removeFromParent()
		end)
	local atk = rn:getChildByName("atk")
	local defence = rn:getChildByName("defence")
	local speed = rn:getChildByName("speed")
	local blood = rn:getChildByName("blood")
	local target = rn:getChildByName("target")
	local dodge = rn:getChildByName("dodge")
	local crit = rn:getChildByName("crit")
	local resist = rn:getChildByName("resist")
	local e_atk = rn:getChildByName("e_atk")
    local shipload = rn:getChildByName("load")
	rn:getChildByName("xinxi"):setString(CONF:getStringValue("information"))

	atk:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kAttack)..":")
	defence:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kDefence)..":")
	speed:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kSpeed)..":")
	blood:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kHP)..":")
	target:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kHit)..":")
	dodge:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kDodge)..":")
	crit:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kCrit)..":")
	resist:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kAnticrit)..":")
    shipload:getChildByName("text"):setString(CONF:getStringValue("Attr_37")..":")
	e_atk:getChildByName("text"):setString(CONF:getStringValue("Attr_"..CONF.EShipAttr.kEnergyAttack)..":")
	if self.data_.isHave == 1 then
		local calship = player:calShip(self.data_.guid,true)
		atk:getChildByName("num"):setString(calship.attr[CONF.EShipAttr.kAttack])
		defence:getChildByName("num"):setString(calship.attr[CONF.EShipAttr.kDefence])
		speed:getChildByName("num"):setString(calship.attr[CONF.EShipAttr.kSpeed])
		blood:getChildByName("num"):setString(calship.attr[CONF.EShipAttr.kHP])
		target:getChildByName("num"):setString(calship.attr[CONF.EShipAttr.kHit])
		dodge:getChildByName("num"):setString(calship.attr[CONF.EShipAttr.kDodge])
		crit:getChildByName("num"):setString(calship.attr[CONF.EShipAttr.kCrit])
		resist:getChildByName("num"):setString(calship.attr[CONF.EShipAttr.kAnticrit])
		e_atk:getChildByName("num"):setString(calship.attr[CONF.EShipAttr.kEnergyAttack])
        if calship.load then -- 新增飞船载重属性，防止老玩家飞船信息异常
            shipload:getChildByName("num"):setString(calship.load)
        else
            local ship = CONF.AIRSHIP.get(self.data_.shipId)
            shipload:getChildByName("num"):setString(ship.LOAD)
        end
	else
		local ship = CONF.AIRSHIP.get(self.data_.shipId)
		atk:getChildByName("num"):setString(ship.ATTACK)
		defence:getChildByName("num"):setString(ship.DEFENCE)
		speed:getChildByName("num"):setString(ship.SPEED)
		blood:getChildByName("num"):setString(ship.LIFE)
		target:getChildByName("num"):setString(ship.PROBABILITY_HIT)
		dodge:getChildByName("num"):setString(ship.PROBABILITY_DODGE)
		crit:getChildByName("num"):setString(ship.PROBABILITY_CRIT)
		resist:getChildByName("num"):setString(ship.PROBABILITY_ANTICRIT)
		e_atk:getChildByName("num"):setString(ship.ENERGY_ATTACK)
        shipload:getChildByName("num"):setString(ship.LOAD)
	end

	atk:getChildByName("num"):setPosition(atk:getChildByName("text"):getPositionX()+atk:getChildByName("text"):getContentSize().width+5,atk:getChildByName("text"):getPositionY())
	defence:getChildByName("num"):setPosition(defence:getChildByName("text"):getPositionX()+defence:getChildByName("text"):getContentSize().width+5,defence:getChildByName("text"):getPositionY())
	speed:getChildByName("num"):setPosition(speed:getChildByName("text"):getPositionX()+speed:getChildByName("text"):getContentSize().width+5,speed:getChildByName("text"):getPositionY())
	blood:getChildByName("num"):setPosition(blood:getChildByName("text"):getPositionX()+blood:getChildByName("text"):getContentSize().width+5,blood:getChildByName("text"):getPositionY())
	target:getChildByName("num"):setPosition(target:getChildByName("text"):getPositionX()+target:getChildByName("text"):getContentSize().width+5,target:getChildByName("text"):getPositionY())
	dodge:getChildByName("num"):setPosition(dodge:getChildByName("text"):getPositionX()+dodge:getChildByName("text"):getContentSize().width+5,dodge:getChildByName("text"):getPositionY())
	crit:getChildByName("num"):setPosition(crit:getChildByName("text"):getPositionX()+crit:getChildByName("text"):getContentSize().width+5,crit:getChildByName("text"):getPositionY())
	resist:getChildByName("num"):setPosition(resist:getChildByName("text"):getPositionX()+resist:getChildByName("text"):getContentSize().width+5,resist:getChildByName("text"):getPositionY())
	e_atk:getChildByName("num"):setPosition(e_atk:getChildByName("text"):getPositionX()+e_atk:getChildByName("text"):getContentSize().width+5,e_atk:getChildByName("text"):getPositionY())
    shipload:getChildByName("num"):setPosition(shipload:getChildByName("text"):getPositionX()+shipload:getChildByName("text"):getContentSize().width+5,shipload:getChildByName("text"):getPositionY())
end

function ShipDetailLayer:onExitTransitionStart()
	printInfo("ShipDetailLayer:onExitTransitionStart()")
end

return ShipDetailLayer