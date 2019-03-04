local g_player = require("app.Player"):getInstance()

local StrongLayer = class("StrongLayer", cc.load("mvc").ViewBase)

local tips = require("util.TipsMessage"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

StrongLayer.RESOURCE_FILENAME = "StrongLayer/StrongLayer.csb"

StrongLayer.RUN_TIMELINE = true

StrongLayer.NEED_ADJUST_POSITION = true

-- local StrongMainNode = class("StrongMainNode",function()
-- 	return require("app.ExResInterface"):getInstance():FastLoad("StrongLayer/StrongMainNode.csb")
-- end)

function StrongLayer:createStrongNode(id)
	local node = require("app.ExResInterface"):getInstance():FastLoad("StrongLayer/StrongItem.csb")
	local cfg_strong = CONF.STRONG.get(id)
	node:getChildByName("text"):setString(CONF:getStringValue(cfg_strong.NAME))
	node:getChildByName("icon"):setTexture("StrongIcon/"..cfg_strong.ICON)
	node:getChildByName("go"):getChildByName("text"):setString(CONF:getStringValue(cfg_strong.STRING))
	if g_player:isGroup() == false then
		node:getChildByName("go"):getChildByName("text"):setString(CONF:getStringValue(cfg_strong.STRING_2))
	end
	node:getChildByName("finish"):setTextColor(cc.c4b(255,255,255,255))
	-- node:getChildByName("finish"):enableShadow(cc.c4b(255,255,255,255), cc.size(0.5,0.5))
	if cfg_strong.CONDITION and cfg_strong.CONDITION ~= "" then
		local param = CONF.PARAM.get(cfg_strong.CONDITION).PARAM
		if g_player:getLevel() < param[1] or g_player:getBuildingInfo(CONF.EBuilding.kMain).level < param[2] then
			node:getChildByName("go"):setVisible(false)
			node:getChildByName("finish"):setVisible(true)
			local str = string.gsub(CONF:getStringValue("level_open"),"#",param[1])
			node:getChildByName("finish"):setString(str)
		end
	end
	if cfg_strong.FUNCTION_OPEN and cfg_strong.FUNCTION_OPEN ~= "" then
		if g_player:getSystemGuideStep(CONF.FUNCTION_OPEN.get(cfg_strong.FUNCTION_OPEN).ID) == 0 and g_player:getGuideStep() >= CONF.GUIDANCE.count() then
			node:getChildByName("progress_bottm"):setVisible(false)
			node:getChildByName("progress"):setVisible(false)
			node:getChildByName("cur_num"):setVisible(false)
			node:getChildByName("all_num"):setVisible(false)
			node:getChildByName("go"):setVisible(false)
			node:getChildByName("finish"):setVisible(true)
			local str = string.gsub(CONF:getStringValue("activation"),"#",CONF:getStringValue(cfg_strong.BUILDING_NAME))
			node:getChildByName("finish"):setString(str)
		end
	end
	local strongDelegate_ = require("util.ScaleProgressDelegate"):create(node:getChildByName("progress"), 251)
	if cfg_strong.SWITCHOVER then
		if cfg_strong.SWITCHOVER == 1 then
			node:getChildByName("progress_bottm"):setVisible(false)
			node:getChildByName("progress"):setVisible(false)
			node:getChildByName("cur_num"):setVisible(false)
			node:getChildByName("all_num"):setVisible(false)
			node:getChildByName("des"):setVisible(true)
			if cfg_strong.MEMO then
				node:getChildByName("des"):setString(CONF:getStringValue(cfg_strong.MEMO))
			end
		elseif cfg_strong.SWITCHOVER == 2 then
			node:getChildByName("progress_bottm"):setVisible(true)
			node:getChildByName("progress"):setVisible(true)
			node:getChildByName("cur_num"):setVisible(true)
			node:getChildByName("all_num"):setVisible(true)
			node:getChildByName("des"):setVisible(false)
			if cfg_strong.FUNCTION_OPEN and cfg_strong.FUNCTION_OPEN ~= "" then
				if g_player:getSystemGuideStep(CONF.FUNCTION_OPEN.get(cfg_strong.FUNCTION_OPEN).ID) == 0 and g_player:getGuideStep() >= CONF.GUIDANCE.count() then
					node:getChildByName("progress_bottm"):setVisible(false)
					node:getChildByName("progress"):setVisible(false)
					node:getChildByName("cur_num"):setVisible(false)
					node:getChildByName("all_num"):setVisible(false)
				end
			end
			local maxNum = 0
			local nowNum = 0
			if id == 1 then
				nowNum = CONF.BUILDING_14.get(g_player:getBuildingInfo(CONF.EBuilding.kWarWorkshop).level).AIRSHIP_NUM
				maxNum = CONF.BUILDING_14.get(CONF.BUILDING_14.len).AIRSHIP_NUM
			elseif id == 20 then
				local arena_data = g_player:getArenaData()
				if  Tools.isEmpty(arena_data) == false then
					if CONF.ARENATITLE.check(arena_data.title_level) then
						nowNum = CONF.ARENATITLE.get(arena_data.title_level).TITLE_LEVEL
					end
				end
				maxNum = CONF.ARENATITLE.get(CONF.ARENATITLE.len).TITLE_LEVEL
			end
			node:getChildByName("cur_num"):setString(nowNum)
			node:getChildByName("all_num"):setString("/"..maxNum)
			node:getChildByName("all_num"):setPositionX(node:getChildByName("cur_num"):getPositionX())
			strongDelegate_:setPercentage(nowNum/maxNum*100)
			if nowNum == maxNum then
				node:getChildByName("finish"):setVisible(true)
				node:getChildByName("finish"):setString(CONF:getStringValue("accomplish"))
				node:getChildByName("go"):setVisible(false)
				node:getChildByName("finish"):setTextColor(cc.c4b(255,244,156,255))
				-- node:getChildByName("finish"):enableShadow(cc.c4b(255,244,156,255), cc.size(0.5,0.5))
			end
		end
	end
	node:getChildByName("go"):addClickEventListener(function()
		playEffectSound("sound/system/click.mp3")
        if tonumber(cfg_strong.TURN_TYPE) == 11 or tonumber(cfg_strong.TURN_TYPE) == 18 or tonumber(cfg_strong.TURN_TYPE) == 21 then
            local name = "planet"
            local isOpen, heroLevel, centreLevel = self:isFuncOpen(name)
            if isOpen == false then
				local tipStr = ""
				if heroLevel ~= 0 then 
					tipStr = tipStr .. CONF:getStringValue("levelNum") .. tostring(heroLevel) .. "\n"
				end
				if centreLevel ~= 0 then 
					tipStr = tipStr .. CONF:getStringValue("CentreLevel") .. CONF:getStringValue("achieve") .. tostring(centreLevel)
				end
				tips:tips(tipStr)
                return
            elseif not cc.exports.isjihuoplanet then
                local str = CONF:getStringValue("plz_activation_universe")
                tips:tips(str)
                return
            end
        end
        self:removeFromParent()
		goScene(cfg_strong.TURN_TYPE,cfg_strong.TURN_ID)
		end)
	return node
end

function StrongLayer:isFuncOpen(name)
	local str = name .. "_open"
	local heroLevel = CONF.PARAM.get(str).PARAM[1]
	local centreLevel = CONF.PARAM.get(str).PARAM[2]

	if g_player:getLevel() < heroLevel or g_player:getBuildingInfo(1).level < centreLevel then
		return false, heroLevel, centreLevel
	end
	return true, heroLevel, centreLevel
end

function StrongLayer:createNode(index)

	printInfo("StrongNode:onEnterTransitionFinish()")
	local strongNode = require("app.ExResInterface"):getInstance():FastLoad("StrongLayer/Strong_2.csb")
	-- if self.data_ then
	-- 	self:changeTo("Strong_"..self.data_.index)
	-- else
	-- 	self:changeTo("StrongMainNode")
	-- end

	-- local function onTouchBegan(touch, event)
	-- 	return true
	-- end
	-- local listener = cc.EventListenerTouchOneByOne:create()
	-- listener:setSwallowTouches(true)
	-- listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	-- local eventDispatcher = self:getEventDispatcher()
	-- eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	local svd_ = require("util.ScrollViewDelegate"):create(strongNode:getChildByName("list"),cc.size(0,5), cc.size(661,102))
	strongNode:getChildByName("list"):setScrollBarEnabled(false)
    --change by JinXin 20180620
	--strongNode:getChildByName("title"):setString(CONF:getStringValue("strong_title0_"..index))
    strongNode:getChildByName("title"):setTexture("StrongLayer/ui/"..CONF.PARAM.get("strong title").PARAM[index]..".png")

	strongNode:getChildByName("Image_26"):loadTexture("StrongLayer/ui/"..CONF.PARAM.get("strong icon").PARAM[index]..".png")
	strongNode:getChildByName("close"):addClickEventListener(function()
		playEffectSound("sound/system/click.mp3")
			local info = self:createMainNode()
			info:setPosition(cc.exports.VisibleRect:center())
			self:addChild(info)
			strongNode:removeFromParent()
		end)
	local strong_tab = {}
	for k,v in pairs(CONF.STRONG) do
		if type(v) == "table" then
			if v.TAB == index then
				table.insert(strong_tab,v)
			end
		end
	end
	table.sort(strong_tab,function(a,b)
		return a.ORDER < b.ORDER
		end)
	for k,v in ipairs(strong_tab) do
		local node = self:createStrongNode(v.ID)
		svd_:addElement(node)
	end
	return strongNode
end

function StrongLayer:createMainNode()
	local node = require("app.ExResInterface"):getInstance():FastLoad("StrongLayer/StrongMainNode.csb")
	local rn = node
	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if g_player:getSystemGuideStep(CONF.ESystemGuideInterFace.kStrong)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("bq_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end
	--change by JinXin 20180620
	--rn:getChildByName("title"):setString(CONF:getStringValue("strong_title0"))
    rn:getChildByName("title"):loadTexture("StrongLayer/ui/strong.png")

	rn:getChildByName("title_0"):setString(CONF:getStringValue("strong_title0_0"))
	for i=1,4 do
		rn:getChildByName("frame_"..i):getChildByName("text"):setString(CONF:getStringValue("strong_title0_"..i))
	end
	rn:getChildByName("tips"):setString(CONF:getStringValue("strong_title0_tips"))
	

	rn:getChildByName("close"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/return.mp3")
		node:getParent():removeFromParent()
	end)
	for i=1,4 do
		rn:getChildByName("frame_"..i):getChildByName("button"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/click.mp3")
			local info = self:createNode(i)
			info:setPosition(cc.exports.VisibleRect:center())
			self:addChild(info)
			node:removeFromParent()
		end)
	end


	-- local ships = {}
	-- for _,guid in ipairs(g_player:getForms()) do
	-- 	if guid > 0 then
			
	-- 		table.insert(ships, guid)
	-- 	end
	-- end

	-- local stars_cur = {}
	-- local stars_all = {}
	-- for i=0,4 do
	-- 	stars_cur[i] = 0
	-- 	stars_all[i] = 0
	-- end
	
	-- for _,id in ipairs(CONF.STRONG.getIDList()) do
	-- 	local cur = 0
	-- 	local all = 0
	-- 	if id >20 and id < 30 then
	-- 		for _,guid in ipairs(ships) do
	-- 			local cur, all = self.layer_:calStrong(id, guid)
	-- 			if cur >= 0 then
	-- 				stars_cur[0] = stars_cur[0] + cur
	-- 				stars_all[0] = stars_all[0] + all

	-- 				local index = math.floor(id / 10)
	-- 				stars_cur[index] = stars_cur[index] + cur
	-- 				stars_all[index] = stars_all[index] + all
	-- 			end
	-- 		end
	-- 	else
	-- 		cur, all = self.layer_:calStrong(id)
	-- 		if cur >= 0 then
	-- 			stars_cur[0] = stars_cur[0] + cur
	-- 			stars_all[0] = stars_all[0] + all
	-- 			local index = math.floor(id / 10)
	-- 			stars_cur[index] = stars_cur[index] + cur
	-- 			stars_all[index] = stars_all[index] + all
	-- 		end
	-- 	end
	-- end

	-- local star_num0 = math.floor(stars_cur[0] / stars_all[0] * 5)
	-- for i=1,star_num0 do
	-- 	rn:getChildByName("star_"..i):setTexture("StrongLayer/ui/icon_star1.png")
	-- end

	-- for i=1,4 do
	-- 	local frame = rn:getChildByName("frame_"..i)
	-- 	local star_num = math.floor(stars_cur[i] / stars_all[i] * 5)
	-- 	for num=1,star_num do
	-- 		frame:getChildByName("star_"..num):setTexture("StrongLayer/ui/icon_star1.png")
	-- 	end
	-- end
	animManager:runAnimOnceByCSB(rn,"StrongLayer/StrongMainNode.csb" ,"animation")
	return node
end

function StrongLayer:onEnterTransitionFinish()
	printInfo("StrongLayer:init()")
	local info = self:createMainNode()
	info:setPosition(cc.exports.VisibleRect:center())
	self:addChild(info)
end


return StrongLayer