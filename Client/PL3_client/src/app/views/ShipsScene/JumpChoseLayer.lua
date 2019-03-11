local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local app = require("app.MyApp"):getInstance()

local JumpChoseLayer = class("JumpChoseLayer", cc.load("mvc").ViewBase)

JumpChoseLayer.RESOURCE_FILENAME = "ShipsScene/ship/JumpChoseLayer.csb"

JumpChoseLayer.NEED_ADJUST_POSITION = true

local jumpType = {
	SHIP = 0, --飞船开发工厂
	LOTTERY = 1, -- 星际港
	ACTIVITY = 2, --活动
	FIRST_RECHARGE = 3,--首冲
	SHOP = 4,--商城
	COPY = 5,--副本
	TRIAL = 6, --试炼
	TASK = 7, -- 任务
}
local jumpName = {
	SHIP = "BuildingName_3",
	LOTTERY = "BuildingName_8",
	ACTIVITY = "activity",
	FIRST_RECHARGE = "first_recharge",
	SHOP = "shop",
	COPY = "BuildingName_9",
	TRIAL = "trial",
	TASK = "task",
}
function JumpChoseLayer:onCreate(data)
	local tabId = {}
	local function insertTab(info)
		if info and Tools.isEmpty(info) == false then
			for _,id in ipairs(info) do
				local canins = true
				for _,v in ipairs(tabId) do
					if id == v then
						canins = false
					end
				end 
				if canins then
					table.insert(tabId,id)
				end
			end
		end
	end
	if data and Tools.isEmpty(data) == false then
		for _,info in ipairs(data) do
			insertTab(info)
		end 
	end
	self.data_ = tabId
	if data.scene then
		self.scene = data.scene
	end
end

function JumpChoseLayer:onEnterTransitionFinish()
	local func = function(typ)
		local str = CONF:getStringValue("no_open")
		for k,v in pairs(jumpType) do
			if typ == v then
				str = CONF:getStringValue(jumpName[k])
			end
		end
		return str
	end
    local buildinfo = CONF.GOTO
    local function findbuildicon(typ)
        local iconstr = "SketchIcon/noopen.png"
        for k,v in ipairs(buildinfo) do
            if v.GET_TYPE and typ == v.GET_TYPE then
                iconstr = v.ICON
                break
            end
        end
        return iconstr
    end
	local info = self.data_
	local rn = self:getResourceNode()
	rn:getChildByName("Image_44"):addClickEventListener(function()
		self:removeFromParent()
		end)
	rn:getChildByName("title"):setString(CONF:getStringValue("get way"))
	local sv = require("util.ScrollViewDelegate"):create(rn:getChildByName("list"),cc.size(7,0), cc.size(410 ,70)) 
	sv:getScrollView():setScrollBarEnabled(false)
	local nodeTab = {}
	if Tools.isEmpty(info) == false then
		for k,v in ipairs(info) do
			local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/JumpChoseNode.csb")
			node:getChildByName("buildingName"):setString(func(v))
            if findbuildicon(v) ~= nil then
                node:getChildByName("icon"):loadTexture(findbuildicon(v))
            end
            node:getChildByName("Button"):getChildByName("text"):setString(CONF:getStringValue("skip"))
			node:getChildByName("Button"):addClickEventListener(function()
				if v == jumpType.SHIP then
					app:pushView("BlueprintScene/BlueprintScene")
				elseif v == jumpType.LOTTERY then
					if player:getLevel() < CONF.FUNCTION_OPEN.get(3).GRADE then
						local str = string.gsub(CONF:getStringValue("level_open"),"#",CONF.FUNCTION_OPEN.get(3).GRADE)
						tips:tips(str)
						return
					end
					if player:getSystemGuideStep(CONF.FUNCTION_OPEN.get("city_2_open").ID) == 0 and player:getGuideStep() >= CONF.GUIDANCE.count() then
						tips:tips(CONF:getStringValue("starport activation"))
						return
					end
					if self.scene then
						if self.scene == "ShipInfoLayer" or self.scene == "TechnologyNode" or self.scene == "TipsInfoNode" or self.scene == "TechnologyDevelopLayer" then
							self:getParent():removeFromParent()
						else
							self:removeFromParent()
						end
					end
					app:pushView("LotteryScene/LotteryScene")
				elseif v == jumpType.ACTIVITY then
					if player:getLevel() < CONF.FUNCTION_OPEN.get(12).GRADE then
						local str = string.gsub(CONF:getStringValue("level_open"),"#",CONF.FUNCTION_OPEN.get(12).GRADE)
						tips:tips(str)
						return
					end
					if self.scene then
						if self.scene == "ShipInfoLayer" then
							self:getParent():removeFromParent()
						else
							self:removeFromParent()
						end
					end
					app:addView2Top("ActivityScene/ActivityScene",{from = "ship"})
				elseif v == jumpType.FIRST_RECHARGE then
					if self.scene then
						if self.scene == "ShipInfoLayer" then
							self:getParent():removeFromParent()
						else
							self:removeFromParent()
						end
					end
					app:addView2Top("ActivityScene/ActivityFirstRechargeNode")
				elseif v == jumpType.SHOP then
					if self.scene then
						if self.scene == "ShipInfoLayer" then
							self:getParent():removeFromParent()
                        elseif self.scene == "TechnologyDevelopLayer" then
                            local parentlayer = self:getParent()
                            self:removeFromParent()
                            parentlayer:removeFromParent()
						else
							self:removeFromParent()
						end
					end
					require("app.ExViewInterface"):getInstance():ShowShopUI()
					-- app:addView2Top("ShopScene/ShopLayer")
				elseif v == jumpType.COPY then
					app:pushToRootView("ChapterScene")
				elseif v == jumpType.TASK then
					local layer = self:getApp():createView("TaskScene/TaskScene",1)
					if self.scene and (self.scene == "TechnologyNode" or self.scene == "TipsInfoNode") then
						layer:setPosition(cc.p(0 , 50))
					end
					if self.scene and self.scene == "UpgradeLayer" then
						local center = cc.exports.VisibleRect:center()
						layer:setPosition(cc.p(-center.x,-center.y-54))
					end
                    if self.scene == "TechnologyDevelopLayer" then
                        self:removeFromParent()
                        app:pushToRootView("CityScene/CityScene", {pos = -1350})
                        local scene = display.getRunningScene()
                        scene:addChild(layer)
                    else
                        self:getParent():addChild(layer,100)
                        self:removeFromParent()
                    end
				elseif v == jumpType.TRIAL then
					if player:getLevel() < CONF.FUNCTION_OPEN.get(21).GRADE then
						local str = string.gsub(CONF:getStringValue("level_open"),"#",CONF.FUNCTION_OPEN.get(21).GRADE)
						tips:tips(str)
						return
					end
					app:pushToRootView("TrialScene/TrialAreaScene")
				else
					tips:tips(CONF:getStringValue("no_open"))
				end
				end)
			table.insert(nodeTab,node)
		end
	else
		local node = require("app.ExResInterface"):getInstance():FastLoad("ShipsScene/ship/JumpChoseNode.csb")
		node:getChildByName("Button"):setVisible(false)
        node:getChildByName("icon"):loadTexture("SketchIcon/noopen.png")
		node:getChildByName("buildingName"):setString(CONF:getStringValue("no_open"))
		table.insert(nodeTab,node)
	end
	for k,v in ipairs(nodeTab) do
		sv:addElement(v)
	end
	if #nodeTab*65 <= rn:getChildByName("list"):getContentSize().height then
		rn:getChildByName("list"):setTouchEnabled(false)
	end
end

function JumpChoseLayer:onExitTransitionStart()
	printInfo("JumpChoseLayer:onExitTransitionStart()")
end

return JumpChoseLayer