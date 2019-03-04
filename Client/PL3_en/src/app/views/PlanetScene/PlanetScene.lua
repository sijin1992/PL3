
local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local planetMachine = require("app.views.PlanetScene.Manager.PlanetMachine"):getInstance()

local g_sendList = require("util.SendList"):getInstance()

local planetManager = require("app.views.PlanetScene.Manager.PlanetManager"):getInstance()

local planetArmyManager = require("app.views.PlanetScene.Manager.PlanetArmyManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local PlanetScene = class("PlanetScene", cc.load("mvc").ViewBase)

PlanetScene.RESOURCE_FILENAME = "PlanetScene/PlanetScene.csb"

PlanetScene.RUN_TIMELINE = true

PlanetScene.NEED_ADJUST_POSITION = true

PlanetScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
}

local schedulerEntry = nil


local layer_tag = {
	kDiamond = 2,
	kArmy = 3,
	kWorld = 4,
	kUI = 5,
	kSFX = 6,
}

function PlanetScene:onCreate( data )
	self.data_ = data
	if data and data.sfx then
		data.sfx = false
		local node = self:getApp():createView("CityScene/TransferScene",{from = "planet",state = "enter"})
		self:addChild(node,100)
	end
end

function PlanetScene:onEnter()
	printInfo("PlanetScene:onEnter()")
	-- ADD WJJ 20180705
	require("app.ExMemoryInterface"):getInstance():OnDisableMemoryReleaseAsync()

end

function PlanetScene:onExit()
	
	printInfo("PlanetScene:onExit()")
end

function PlanetScene:createWorldLayer( ... )
	self.worldLayer_ = self:getApp():createView("PlanetScene/PlanetWorldLayer")
	self:addChild(self.worldLayer_,layer_tag.kWorld)
end

function PlanetScene:removeWorldLayer( ... )
	self.worldLayer_:removeFromParent()
	self.worldLayer_ = nil
end

function PlanetScene:createLine( ... )
	local rn = self:getResourceNode()

	local function randowRGB( ... )
		local r = 0
		local g = 0
		local b = 0

		for i=1,10 do
			r = math.random(1,255)
			g = math.random(1,255)
			b = math.random(1,255)
		end

		return r,g,b

	end

	self.rot = 0
	self.speed = 1
	self.sps = {}
	for i=1,20 do
		local pSprite = mc.UVSprite:create("PlanetScene/ui/arrow.png")
	    pSprite:setAutoScrollU(false)
	    pSprite:setAutoScrollV(true)
	    pSprite:setScrollSpeedV(self.speed)
	    pSprite:setPosition(cc.p(168+(i-1)*40,384))
	    pSprite:setTextureRect(cc.rect(0, 0, 8, 4800))
	    pSprite:setRotation(0*(i-1))
	    self:addChild(pSprite)

	    local r,g,b = randowRGB()
	   	pSprite:setColor(cc.c3b(r,g,b))

	    table.insert(self.sps, pSprite)
	end

	rn:getChildByName("Button_6"):addClickEventListener(function ( ... )
		self.rot = self.rot + 5

		for i,v in ipairs(self.sps) do
			v:setRotation(self.rot*(i-1))
		end
	end)

	rn:getChildByName("Button_8"):addClickEventListener(function ( ... )

		for i,v in ipairs(self.sps) do
			local r,g,b = randowRGB()
	   		v:setColor(cc.c3b(r,g,b))
		end
	end)

	rn:getChildByName("Button_6_0"):addClickEventListener(function ( ... )
		for i,v in ipairs(self.sps) do
			v:setScrollSpeedV(self.speed)
		end
	end)

	rn:getChildByName("Button_6_1"):addClickEventListener(function ( ... )
		for i,v in ipairs(self.sps) do
			v:setScrollSpeedV(self.speed*2)
		end
	end)

	rn:getChildByName("Button_6_2"):addClickEventListener(function ( ... )
		for i,v in ipairs(self.sps) do
			v:setScrollSpeedV(self.speed*3)
		end
	end)

	rn:getChildByName("Button_7"):addClickEventListener(function ( ... )
		for i,v in ipairs(self.sps) do
			v:removeFromParent()
		end

		rn:getChildByName("Button_6"):removeFromParent()
		rn:getChildByName("Button_7"):removeFromParent()
		rn:getChildByName("Button_6_1"):removeFromParent()
		rn:getChildByName("Button_6_0"):removeFromParent()
		rn:getChildByName("Button_6_2"):removeFromParent()
		rn:getChildByName("Button_8"):removeFromParent()

		self.diamondLayer_ = self:getApp():createView("PlanetScene/PlanetDiamondLayer")
		self:addChild(self.diamondLayer_,2)

		-- self.worldLayer_ = self:getApp():createView("PlanetScene/PlanetWorldLayer")
		-- self:addChild(self.worldLayer_,3)
	end)
end

function PlanetScene:removeBtn( ... )
	local rn = self:getResourceNode()
	rn:getChildByName("Button_6"):removeFromParent()
	rn:getChildByName("Button_7"):removeFromParent()
	rn:getChildByName("Button_6_1"):removeFromParent()
	rn:getChildByName("Button_6_0"):removeFromParent()
	rn:getChildByName("Button_6_2"):removeFromParent()
	rn:getChildByName("Button_8"):removeFromParent()
end

function PlanetScene:getDiamondMidNodeId( ... )
	return self.diamondLayer_:getMidNodeID()
end

function PlanetScene:onEnterTransitionFinish()
	printInfo("PlanetScene:onEnterTransitionFinish()")

	cc.SpriteFrameCache:getInstance():addSpriteFrames("PlanetScene/Bg_Plist.plist")  
	cc.SpriteFrameCache:getInstance():addSpriteFrames("PlanetScene/Bg_Plist2.plist")  

	guideManager:checkInterface(13)

	local rn = self:getResourceNode()

	self:removeBtn()

	local textureCache = cc.Director:getInstance():getTextureCache()

	self.diamondLayer_ = self:getApp():createView("PlanetScene/PlanetDiamondLayer", self.data_)
	self:addChild(self.diamondLayer_,layer_tag.kDiamond)

	-- self.worldLayer_ = self:getApp():createView("PlanetScene/PlanetWorldLayer")
	-- self:addChild(self.worldLayer_,layer_tag.kWorld)

	-- self.armyLayer_ = self:getApp():createView("PlanetScene/PlanetArmyLayer")
	-- self:addChild(self.armyLayer_,layer_tag.kArmy)

	self.uiLayer_ = self:getApp():createView("PlanetScene/PlanetUILayer")
	self:addChild(self.uiLayer_,layer_tag.kUI)
	local name1 = self.uiLayer_:getResourceNode():getChildByName('Image_name1')
	name1:setVisible(false)
	self.uiLayer_:getResourceNode():getChildByName('Image_name2'):setVisible(false)
	local function update(  )	
		planetMachine:update()
		if self:getDiamondMidNodeId() and self:getDiamondMidNodeId() ~= 0 then
			local cfg_word = CONF.PLANETWORLD.get(self:getDiamondMidNodeId())
			local city_info = planetManager:getCityByNodeId( self:getDiamondMidNodeId() )
			if cfg_word then
				name1:setVisible(true)
				local labelName = name1:getChildByName('text')
				labelName:setString(CONF:getStringValue(cfg_word.NAME))
				local label = name1:getChildByName('text2')
				label:setVisible(false)
				labelName:setAnchorPoint(cc.p(0.5,0.5))
				labelName:setPosition(cc.p(name1:getContentSize().width/2,name1:getContentSize().height/2))
				if CONF.PLANETCITY.check(cfg_word.ID) then
					local cfg_city = CONF.PLANETCITY.get(cfg_word.ID)
					for i,v in ipairs(planetManager:getInfoList()) do
						if v.info then
							for i2,v2 in ipairs(v.info) do
								if v2.type == 5 then
									labelName:setAnchorPoint(cc.p(1,0.5))
									--if v2.city_data.status == 1 then -- he
									--	label:setString(CONF:getStringValue("protect"))
									--	label:setTextColor(cc.c4b(156,255,182,255))
										-- label:enableShadow(cc.c4b(156,255,182,255), cc.size(0.2,0.2))
									--else
										label:setString(CONF:getStringValue("race"))
										label:setTextColor(cc.c4b(255,70,70,255))
										-- label:enableShadow(cc.c4b(255,70,70,255), cc.size(0.2,0.2))
									--end
									labelName:setPosition(label:getPosition())
									label:setVisible(true)
									break
								end
							end
						end
					end
				end

			end
			if Tools.isEmpty(city_info) == false and Tools.isEmpty(city_info.city_data.temp_info) == false and city_info.city_data.groupid ~= '' then
				self.uiLayer_:getResourceNode():getChildByName('Image_name2'):setVisible(true)
				self.uiLayer_:getResourceNode():getChildByName('Image_name2'):getChildByName('text'):setString(CONF:getStringValue('zhanlingzhe')..':'.. city_info.city_data.temp_info.nickname)
			else
				self.uiLayer_:getResourceNode():getChildByName('Image_name2'):setVisible(true)
				self.uiLayer_:getResourceNode():getChildByName('Image_name2'):getChildByName('text'):setString(CONF:getStringValue('no occupy'))
			end
			if cfg_word.TYPE ~= 2 then
				self.uiLayer_:getResourceNode():getChildByName('Image_name2'):setVisible(false)
			end
		else
			--name1:setVisible(false)
			name1:setVisible(true)
			local labelName = name1:getChildByName('text')
			labelName:setString(CONF:getStringValue("hao_other"))
			self.uiLayer_:getResourceNode():getChildByName('Image_name2'):setVisible(false)
		end
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update, 1, false)

end

function PlanetScene:getDiamondLayer( ... )
	return self.diamondLayer_
end

function PlanetScene:getWorldLayer( ... )
	return self.worldLayer_
end

function PlanetScene:getUILayer( ... )
	return self.uiLayer_
end

function PlanetScene:getArmyLayer( ... )
	return self.armyLayer_
end

function PlanetScene:onExitTransitionStart()

	printInfo("PlanetScene:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	planetManager:clear()
	g_sendList:clear()
end

return PlanetScene