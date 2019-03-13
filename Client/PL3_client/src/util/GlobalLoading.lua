local GlobalLoading = class("GlobalLoading")
local animManager = require("app.AnimManager"):getInstance()
local scheduler = cc.Director:getInstance():getScheduler()
local tips = require("util.TipsMessage"):getInstance()

local loading_layer_name = "g_GlobalLoading"

local schedulerShield = nil
local startTime = 0
local errorFunction = nil



function GlobalLoading:ctor()
	
	self.name_list_ = {}
	self.count_ = 0

	local function updateShield(...)
		if self.count_ > 0 then
			if startTime + 10 < os.time() then
				self:releaseLoading()
				tips:tips(CONF:getStringValue("network_error"))
				if errorFunction and type(errorFunction)=="function" then
					errorFunction()
				end
			end
		end
	end
	schedulerShield = scheduler:scheduleScriptFunc(updateShield, 1, false)
end

function GlobalLoading:retainLoading(name,errorFun)

	self.count_ = self.count_ + 1
	errorFunction = errorFun
	startTime = os.time()

	local scene = display.getRunningScene()
	local layer = scene:getChildByName(loading_layer_name)

	if layer == nil then

		local center = cc.exports.VisibleRect:center()

		layer = cc.LayerColor:create(cc.c4b( 16, 9, 2, 120))
		layer:setName(loading_layer_name)

		local function onTouchBegan(touch, event)

			return true
		end


		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

		local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)


		local node = require("app.ExResInterface"):getInstance():FastLoad("Common/loading.csb")
		layer:addChild(node)
		node:setPosition(cc.p(center.x-50, center.y - 15))

		animManager:runAnimByCSB(node, "Common/loading.csb", "1")

		scene:addChild(layer, SceneZOrder.kGlobalLoading)

	end	

end 

function GlobalLoading:releaseLoading(name)

	local scene = display.getRunningScene()
	local layer = scene:getChildByName(loading_layer_name)

	if self.count_ <= 0 then
		return
	end
	self.count_ = self.count_ - 1

	if self.count_ < 0 then
		self.count_ = 0
	end
	if self.count_ == 0 and layer ~= nil then
		errorFunction = nil
		layer:removeFromParent()
	end

end

function GlobalLoading:isLoading()
	return self.count_ > 0
end

function GlobalLoading:getInstance()
	if self.instance == nil then
		self.instance = self:create()
	end
		
	return self.instance
end


return GlobalLoading