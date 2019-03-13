
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local PlanetAllFightLayer = class("PlanetAllFightLayer", cc.load("mvc").ViewBase)

local player = require("app.Player"):getInstance()

PlanetAllFightLayer.RESOURCE_FILENAME = "PlanetScene/allFightLayer.csb"

PlanetAllFightLayer.RUN_TIMELINE = true

PlanetAllFightLayer.NEED_ADJUST_POSITION = true

PlanetAllFightLayer.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}


function PlanetAllFightLayer:onCreate( data )
	self.data_ = data
end

function PlanetAllFightLayer:onEnter()

end

function PlanetAllFightLayer:onExit()
	
end


function PlanetAllFightLayer:onEnterTransitionFinish()
	printInfo("PlanetAllFightLayer:onEnterTransitionFinish()")
	local all_layer = self:getResourceNode()
	all_layer:getChildByName("title"):setString(CONF:getStringValue("mass"))
	all_layer:getChildByName("pos_text"):setString("("..self.data_.pos_list[1].x..", "..self.data_.pos_list[1].y..")")
	all_layer:getChildByName("ins"):setString(CONF:getStringValue("setting mass time"))

	all_layer:getChildByName("close"):addClickEventListener(function ( ... )
		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
		all_layer:removeFromParent()
	end)

	for i=1,4 do
		all_layer:getChildByName("choose_"..i):getChildByName("text"):setString(CONF.PARAM.get("mass_time").PARAM[i]..CONF:getStringValue("minutes"))
		all_layer:getChildByName("choose_"..i):getChildByName("box"):addEventListener(function ( ... )

			for j=1,4 do
				if i ~= j then
					all_layer:getChildByName("choose_"..j):getChildByName("box"):setSelected(false)
				end
			end
		end)

		if i == 1 then
			all_layer:getChildByName("choose_"..i):getChildByName("box"):setSelected(true)
		end
	end

	all_layer:getChildByName("btn"):getChildByName("text"):setString(CONF:getStringValue("yes"))
	all_layer:getChildByName("btn"):addClickEventListener(function ( ... )

		if self.data_.status == 1 then
			tips:tips(CONF:getStringValue('peacet_notice1'))
			return
		elseif self.data_.status == 3 then
			tips:tips(CONF:getStringValue("shield text"))
			return
		end
		local flag = false
		local index = 0
		for i=1,4 do
			if all_layer:getChildByName("choose_"..i):getChildByName("box"):isSelected() == true then
				flag = true
				index = i
				break
			end
		end

		if not flag or index == 0 then
			tips:tips("xuanyige")
			return
		end

		cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("resetCanTouch")
		all_layer:removeFromParent()

		self:getApp():addView2Top("NewFormLayer",{from="bigMapAllFight",element_global_key=self.data_.element_global_key,type=self.data_.type,cfg_type = self.data_.cfg_type,cfg_id = self.data_.cfg_id, mass_level = index})
	end)

	local function onTouchBegan(touch, event)
		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	local eventDispatcher = all_layer:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, all_layer)
end

function PlanetAllFightLayer:onExitTransitionStart()

	printInfo("PlanetAllFightLayer:onExitTransitionStart()")

end

return PlanetAllFightLayer