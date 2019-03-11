

local TechnologyMaxLayer = class("TechnologyMaxLayer", cc.load("mvc").ViewBase)

TechnologyMaxLayer.RESOURCE_FILENAME = "TechnologyScene/TechnologyMaxLayer.csb"

TechnologyMaxLayer.NEED_ADJUST_POSITION = true


TechnologyMaxLayer.RESOURCE_BINDING = {
	["ok"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function TechnologyMaxLayer:onCreate(data)--{techID = X}

	self.data_ = data

end

function TechnologyMaxLayer:OnBtnClick(event)
	if event.name == "ended" then

		if event.target:getName() == "ok" then
			playEffectSound("sound/system/return.mp3")
			self:getApp():removeTopView() 
			
		end
	end

end

function TechnologyMaxLayer:onEnterTransitionFinish()
	printInfo("TechnologyMaxLayer:onEnterTransitionFinish()")


	local rn = self:getResourceNode()

	local grayLayer = cc.LayerColor:create(cc.c4b( 16, 9, 2, 150))
	self:addChild(grayLayer)
	grayLayer:setLocalZOrder(-1)

	local conf = CONF.TECHNOLOGY.get(self.data_.techID)
	if conf == nil then
		return
	end

	rn:getChildByName("name"):setString(CONF.STRING.get(conf.TECHNOLOGY_NAME).VALUE)

	rn:getChildByName("icon"):setTexture(string.format("TechnologyIcon/%d.png",conf.RES_ID))

	rn:getChildByName("power_num"):setString(string.format("%d",conf.FIGHT_POWER))

	rn:getChildByName("lv_num"):setString(string.format("%d",conf.TECHNOLOGY_LEVEL))

	rn:getChildByName("memo"):setString(CONF.STRING.get(conf.MEMO_ID).VALUE)

	rn:getChildByName("effect"):setString(CONF:getStringValue("effect")..":")

	local valueStr
	if conf.TECHNOLOGY_ATTR_PERCENT > 0 then
		valueStr = string.format("+%d%%",conf.TECHNOLOGY_ATTR_PERCENT)
	else
		valueStr =  string.format("+%d",conf.TECHNOLOGY_ATTR_VALUE)
	end
	rn:getChildByName("cur_effect"):setString(valueStr)

	rn:getChildByName("cur_effect"):setPositionX(rn:getChildByName("effect"):getPositionX()+rn:getChildByName("effect"):getContentSize().width)




	local function onTouchBegan(touch, event)
		performWithDelay(self, function ()
			self:getApp():removeTopView() 
		end, 0.0001)
		
		return true
	end
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function TechnologyMaxLayer:onExitTransitionStart()
	printInfo("TechnologyMaxLayer:onExitTransitionStart()")

end

return TechnologyMaxLayer