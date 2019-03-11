local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local animManager = require("app.AnimManager"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local winSize = cc.Director:getInstance():getWinSize()

local TrialAreaScene = class("TrialAreaScene", cc.load("mvc").ViewBase)

TrialAreaScene.RESOURCE_FILENAME = "TrialScene/TrialAreaScene/TrialAreaScene.csb"

TrialAreaScene.RUN_TIMELINE = true

TrialAreaScene.NEED_ADJUST_POSITION = true

TrialAreaScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil
local itemPos = {x = 33, y = 60}

function TrialAreaScene:onCreate(data)

	self.data_ = data

end

function TrialAreaScene:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" and event.target:getName() == "close" then
		printInfo("close")
		playEffectSound("sound/system/return.mp3")
		self:getApp():pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
		
	end

end

function TrialAreaScene:resetDownPanel( index )
	local rn = self:getResourceNode()

	-- if index == self.chooseNode:getTag() then
	--     return
	-- end

	--
	local areaType = player:getTrialAreaType(index)

	------
	self.chooseNode:getChildByName("button"):setScale(CONF.PARAM.get("trial button").PARAM[index])

	self.chooseNode:setPosition(cc.p(rn:getChildByName("stage_"..index):getPosition()))

	if self.canIn_[index] then
		-- self.chooseNode:getChildByName("button"):loadTextures("StarOccupationLayer/ui/cj_case.png", "StarOccupationLayer/ui/cj_case_light.png", "")
		-- self.chooseNode:getChildByName("button"):setContentSize(cc.size(114,113))
		if areaType == 0 then
			self.chooseNode:getChildByName("text"):setString(CONF:getStringValue("start"))
		elseif areaType == 1 then
			self.chooseNode:getChildByName("text"):setString(CONF:getStringValue("continue"))
		end
	else
		-- self.chooseNode:getChildByName("button"):loadTextures("StarOccupationLayer/ui/ld_case.png", "StarOccupationLayer/ui/ld_case_light.png", "")
		-- self.chooseNode:getChildByName("button"):setContentSize(cc.size(168,168))
		self.chooseNode:getChildByName("text"):setString(CONF:getStringValue("start"))
		
	end

	self.chooseNode:setTag(index)

	---
	self.times = {}

	local ins_node = rn:getChildByName("ins_node")
	if ins_node then
		ins_node:removeFromParent()
	end

	local bgNode 
	if index == 1 or index == 2 or index == 3 then
		bgNode = require("app.ExResInterface"):getInstance():FastLoad("Common/InsNode_left.csb")
	else
		bgNode = require("app.ExResInterface"):getInstance():FastLoad("Common/InsNode_right.csb")
	end

	local insNode
	if (player:getLevel() < CONF.TRIAL_AREA.get(index).ROLE_LEVEL or player:getPower() < CONF.TRIAL_AREA.get(index).ROLE_COMBAT) and areaType ~= 1 then
		insNode = require("app.ExResInterface"):getInstance():FastLoad("TrialScene/TrialAreaScene/introduce_notFight.csb")
		insNode:getChildByName("lv_num"):setString(CONF.TRIAL_AREA.get(index).ROLE_LEVEL)
		insNode:getChildByName("fight_num"):setString(CONF.TRIAL_AREA.get(index).ROLE_COMBAT)

		insNode:getChildByName("need"):setString(CONF:getStringValue("need"))
		insNode:getChildByName("role"):setString(CONF:getStringValue("level"))
		insNode:getChildByName("fight"):setString(CONF:getStringValue("combat"))

		bgNode:getChildByName("line"):setTexture("StarOccupationLayer/ui/tq_red.png")

	else

		local cengNowNum = 0 
		local cengMaxNum = 0
		local starNowNum = 0
		local starMaxNum = 0

		for i,v in ipairs(CONF.TRIAL_AREA.get(index).SCENE_ID) do
			for ii,vv in ipairs(CONF.TRIAL_SCENE.get(v).T_COPY_LIST) do
				local conf = CONF.TRIAL_COPY.get(vv)
				cengMaxNum = cengMaxNum + conf.LEVEL_NUM
				starMaxNum = starMaxNum + conf.START_NUM
				for iii,vvv in ipairs(conf.LEVEL_ID) do
					local star = player:getTrialLevelStar(vvv)
					starNowNum = starNowNum + star

					if star ~= 0 then
						cengNowNum = cengNowNum + 1
					end

				end
			end
		end

		if areaType == 0 then
			insNode = require("app.ExResInterface"):getInstance():FastLoad("TrialScene/TrialAreaScene/introduce_endFight.csb")

			insNode:getChildByName("ceng_now_num"):setString(cengNowNum)
			insNode:getChildByName("ceng_max_num"):setString("/"..cengMaxNum)
			insNode:getChildByName("star_now_num"):setString(starNowNum)
			insNode:getChildByName("star_max_num"):setString("/"..starMaxNum)

			insNode:getChildByName("Text_1"):setString(CONF:getStringValue("history"))

		elseif areaType == 1 then
			insNode = require("app.ExResInterface"):getInstance():FastLoad("TrialScene/TrialAreaScene/introduce_nowFight.csb")
			insNode:getChildByName("time_num"):setString(formatTime(86400 - player:getServerTime()%86400))

			insNode:getChildByName("ceng_now_num"):setString(cengNowNum)
			insNode:getChildByName("ceng_max_num"):setString("/"..cengMaxNum)
			insNode:getChildByName("star_now_num"):setString(starNowNum)
			insNode:getChildByName("star_max_num"):setString("/"..starMaxNum)

			insNode:getChildByName("time"):setString(CONF:getStringValue("reset"))
			insNode:getChildByName("checkpoint"):setString(CONF:getStringValue("scheduler"))

			textSetPos(insNode:getChildByName("time"),insNode:getChildByName("time_num"), 5, 1)
			textSetPos(insNode:getChildByName("checkpoint"),insNode:getChildByName("ceng_now_num"), 5, 1)
			textSetPos(insNode:getChildByName("ceng_now_num"),insNode:getChildByName("ceng_max_num"), 0, 1)

			insNode:getChildByName("btn_reset"):setPositionX(insNode:getChildByName("time_num"):getPositionX() + insNode:getChildByName("time_num"):getContentSize().width + insNode:getChildByName("btn_reset"):getContentSize().width/2 - 2)

			insNode:getChildByName("ui_icon_star"):setPositionX(insNode:getChildByName("checkpoint"):getPositionX() + insNode:getChildByName("checkpoint"):getContentSize().width - insNode:getChildByName("ui_icon_star"):getContentSize().width/2)
			insNode:getChildByName("star_now_num"):setPositionX(insNode:getChildByName("ceng_now_num"):getPositionX())
			textSetPos(insNode:getChildByName("star_now_num"),insNode:getChildByName("star_max_num"), 0, 1)

			insNode:getChildByName("btn_reset"):addClickEventListener(function ( ... )
				-- local node = require("app.ExResInterface"):getInstance():FastLoad("CityScene/QueueNode.csb")

				-- node:getChildByName("queue_node"):removeFromParent()
				-- node:getChildByName("text"):setString(CONF:getStringValue("reset tips"))
				-- node:getChildByName("cancel"):getChildByName("text"):setString(CONF:getStringValue("cancel"))
				-- node:getChildByName("yes"):getChildByName("text"):setString(CONF:getStringValue("yes"))
				-- node:getChildByName("cancel"):addClickEventListener(function ( ... )
				--     node:removeFromParent()
				-- end)

				-- node:getChildByName("yes"):addClickEventListener(function ( ... )
				--     local strData = Tools.encode("TrialAreaReq", {
				--         type = 3,
				--         area_id = self.chooseNode:getTag(),
				--     })
				--     GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

				--     gl:retainLoading()

				--     node:removeFromParent()
				-- end)

				-- node:getChildByName("bg"):setSwallowTouches(true)
				-- node:getChildByName("bg"):addClickEventListener(function ( ... )
				--     node:removeFromParent()
				-- end)

				-- node:setPosition(cc.exports.VisibleRect:center())
				-- rn:addChild(node)

				local function resetTrial( ... )
					playEffectSound("sound/system/click.mp3")
					local strData = Tools.encode("TrialAreaReq", {
						type = 3,
						area_id = self.chooseNode:getTag(),
					})
					GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

					gl:retainLoading()
					

					-- node:removeFromParent()
				end

				messageBox:reset(CONF.STRING.get("reset tips").VALUE, resetTrial)
				playEffectSound("sound/system/click.mp3")
			end)

			table.insert(self.times, insNode)
		end

	end

	bgNode:addChild(insNode)
	insNode:setPosition(cc.p(bgNode:getChildByName("node"):getPosition()))

	local ins = rn:getChildByName("ins_"..index)
	bgNode:setPosition(cc.p(ins:getPosition()))
	bgNode:setName("ins_node")
	rn:addChild(bgNode)

	--
	local conf = CONF.TRIAL_AREA.get(index)

	-- local panel_down = rn:getChildByName("Panel_down")
	rn:getChildByName("ins"):setString("    "..CONF:getStringValue(conf.INTRODUCE_ID))
	rn:getChildByName("Text_6"):setString(CONF:getStringValue("intro"))

	for i=1,10 do
		local item = self:getChildByName("item_"..i)
		if item then
			item:removeFromParent()
		end
	end

	if self.ani_ then
		for i,v in ipairs(conf.ITEMS_ID) do

			local node = require("util.ItemNode"):create():init(v)

			node:setPosition(cc.p(itemPos.x + 60*(i-1), itemPos.y))
			node:setName("item_"..i)
			node:setScale(0.7)
			self:addChild(node,9)

		end
	end
	
end

function TrialAreaScene:resetAreaInfo()

	local rn = self:getResourceNode()

	self.canIn_ = {}
	self.times = {}
	for i=1,3 do

		local areaType = player:getTrialAreaType(i)

		if (player:getLevel() < CONF.TRIAL_AREA.get(i).ROLE_LEVEL or player:getPower() < CONF.TRIAL_AREA.get(i).ROLE_COMBAT) and areaType ~= 1 then

			rn:getChildByName("name_"..i):getChildByName("xxx"):setVisible(false)
			rn:getChildByName("name_"..i):getChildByName("now_num"):setVisible(false)
			rn:getChildByName("name_"..i):getChildByName("max_num"):setVisible(false)
			rn:getChildByName("name_"..i):getChildByName("not"):setVisible(true)

			table.insert(self.canIn_, false)
		else

			rn:getChildByName("name_"..i):getChildByName("xxx"):setVisible(true)
			rn:getChildByName("name_"..i):getChildByName("now_num"):setVisible(true)
			rn:getChildByName("name_"..i):getChildByName("max_num"):setVisible(true)
			rn:getChildByName("name_"..i):getChildByName("not"):setVisible(false)

			local cengNowNum = 0 
			local cengMaxNum = 0
			local starNowNum = 0
			local starMaxNum = 0

			for i,v in ipairs(CONF.TRIAL_AREA.get(i).SCENE_ID) do
				for ii,vv in ipairs(CONF.TRIAL_SCENE.get(v).T_COPY_LIST) do
					local conf = CONF.TRIAL_COPY.get(vv)
					cengMaxNum = cengMaxNum + conf.LEVEL_NUM
					starMaxNum = starMaxNum + conf.START_NUM
					for iii,vvv in ipairs(conf.LEVEL_ID) do
						local star = player:getTrialLevelStar(vvv)
						starNowNum = starNowNum + star

						if star ~= 0 then
							cengNowNum = cengNowNum + 1
						end

					end
				end
			end

			rn:getChildByName("name_"..i):getChildByName("now_num"):setString(cengNowNum)
			rn:getChildByName("name_"..i):getChildByName("max_num"):setString("/"..cengMaxNum)
			rn:getChildByName("name_"..i):getChildByName("max_num"):setPositionX(rn:getChildByName("name_"..i):getChildByName("now_num"):getPositionX() + rn:getChildByName("name_"..i):getChildByName("now_num"):getContentSize().width)

			if areaType == 0 then
				rn:getChildByName("name_"..i):getChildByName("xxx"):setString("History")

			elseif areaType == 1 then
				rn:getChildByName("name_"..i):getChildByName("xxx"):setString("scheduler")
			end

			table.insert(self.canIn_, true)

		end
	end
end

function TrialAreaScene:onEnter()
	printInfo("TrialAreaScene:onEnter()")

end

function TrialAreaScene:onExit()
	
	printInfo("TrialAreaScene:onExit()")
end

function TrialAreaScene:onEnterTransitionFinish()
	printInfo("TrialAreaScene:onEnterTransitionFinish()")

	broadcastRun()

	guideManager:checkInterface(CONF.EInterface.kTrialArea)

	local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kTrial)== 0 and g_System_Guide_Id == 0 then
		systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("trial_open").INTERFACE)
	else
		if g_System_Guide_Id ~= 0 then
			systemGuideManager:createGuideLayer(g_System_Guide_Id)
		end
	end

	self.canIn_ = {}
	self.times = {}

	--getcishu
	local strData = Tools.encode("TrialGetTimesReq", {
		type = 1,
	})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_GET_TIMES_REQ"),strData)
	if self.data_ and self.data_.noRetain then

	else
		gl:retainLoading()
	end
	--setInfo
	local rn = self:getResourceNode()

	local userInfoNode = require("util.UserInfoNode"):create()
	userInfoNode:init(self)
	rn:getChildByName("info_node"):addChild(userInfoNode)

	rn:getChildByName("wen"):addClickEventListener(function ( sender )

		self:addChild(createIntroduceNode(CONF:getStringValue("Trial_introduce")))
	end)

	-- rn:getChildByName("btn_reward"):addClickEventListener(function ( ... )
	--     -- body
	-- end)

	-- rn:getChildByName("reward_get_num"):setString()
	-- rn:getChildByName("reward_next_num"):setString()

	--
   
	-- local Panel_top = rn:getChildByName("Panel_top")
	-- Panel_top:getChildByName("headImage"):loadTexture("HeroImage/"..player:getPlayerIcon()..".png")
	-- Panel_top:getChildByName("reaper_aleriness"):setString(player:getNickName())
	-- Panel_top:getChildByName("lv"):setString("Lv."..player:getLevel())
	-- Panel_top:getChildByName("fight_num"):setString(CONF:getStringValue("combat")..":"..player:getPower())

	rn:getChildByName("money_num"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	rn:getChildByName("cishu"):setString(CONF:getStringValue("residue degree"))

	--set strength
	-- local strenthBar = rn:getChildByName("progress")
	-- self.strengthDelegate_ = require("util.ScaleProgressDelegate"):create(strenthBar, strenthBar:getTag())

	-- local p = player:getStrength() / player:getMaxStrength() * 100 
	-- if p > 100 then
	-- 	p = 100
	-- end
	-- self.strengthDelegate_:setPercentage(p)

	-- rn:getChildByName("ev_num"):setString(player:getStrength().."/"..player:getMaxStrength())

	-- rn:getChildByName("light_top"):setPositionX(rn:getChildByName("progress"):getPositionX() + rn:getChildByName("progress"):getContentSize().width - 10)
	-- rn:getChildByName("light_back"):setPositionX(rn:getChildByName("progress"):getPositionX() + rn:getChildByName("progress"):getContentSize().width - 16)


	--set exp
	
	-- local exp_bar = Panel_top:getChildByName("exp_progress")
	-- self.expDelegate_ = require("util.ScaleProgressDelegate"):create(exp_bar, exp_bar:getTag())

	-- local p = player:getNextLevelExpPercent()

	-- self.expDelegate_:setPercentage(p)

	--
	self.chooseNode = require("app.ExResInterface"):getInstance():FastLoad("TrialScene/TrialAreaScene/choose.csb")
	self.chooseNode:setPositionX(-1000)

	self.chooseNode:getChildByName("button"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")
		if self.chooseNode:getChildByName("text"):getString() == CONF:getStringValue("start") then
			if player:getLevel() >= CONF.TRIAL_AREA.get(self.chooseNode:getTag()).ROLE_LEVEL and player:getPower() >= CONF.TRIAL_AREA.get(self.chooseNode:getTag()).ROLE_COMBAT then
				if tonumber(self:getResourceNode():getChildByName("cishu_num"):getString()) >= 1 then

					self:getApp():addView2Top("NewFormLayer", {from = "trial_start", index = self.chooseNode:getTag()})
				else
					tips:tips(CONF:getStringValue("no ticket"))
					
				end
			else
				tips:tips(CONF:getStringValue("level or power not enough"))
			end

		elseif self.chooseNode:getChildByName("text"):getString() == CONF:getStringValue("continue") then
			self:getApp():pushView("TrialScene/TrialStageScene", {scene = player:getTrialScene(self.chooseNode:getTag()), slPosX = 0})
		else
			tips:tips("can't in")
		end

	end)
	rn:addChild(self.chooseNode)

	for i=1,3 do
		rn:getChildByName("name_"..i):getChildByName("name"):setString(CONF:getStringValue(CONF.TRIAL_AREA.get(i).NAME_ID))
	end

	--setClick

	rn:getChildByName("btn_cishu"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")
		local function func( ... )
			playEffectSound("sound/system/click.mp3")
			if player:getItemNumByID(CONF.PARAM.get("add_trial_times_id").PARAM[1]) < 1 then
				tips:tips(CONF:getStringValue("item not enought"))
				return
			end

			local strData = Tools.encode("TrialAddTicketReq", {
				item_id = CONF.PARAM.get("add_trial_times_id").PARAM[1],
				num = 1,
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_ADD_TICKET_REQ"),strData)

			gl:retainLoading()

		end

		local item_num = {}
		for i,v in ipairs(CONF.PARAM.get("add_trial_times_id").PARAM) do
			table.insert(item_num, 1)
		end

		-- local node = require("util.TipsNode"):createWithUseNode(CONF:getStringValue("add trial times"), CONF.PARAM.get("add_trial_times_id").PARAM, item_num, func)
		local node = require("util.TipsNode"):createWithUseNode(CONF:getStringValue("add trial times"), CONF.PARAM.get("add_trial_times_id").PARAM[1], 1, func)

		tipsAction(node)
		self:addChild(node)
	end)

	rn:getChildByName("form"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")
		if player:getTrialAreaType(self.chooseNode:getTag()) == 0 then
			self:getApp():addView2Top("NewFormLayer", {from = "ships"})
		elseif player:getTrialAreaType(self.chooseNode:getTag()) == 1 then
			self:getApp():addView2Top("NewFormLayer", {from = "continue", index = self.chooseNode:getTag()})
		end
	end)

	rn:getChildByName("rank"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")
		self:getApp():pushView("RankLayer/RankLayer",{type = "trial_rank"}) 
	end)

	-- rn:getChildByName("Panel_top"):getChildByName("reset"):addClickEventListener(function ( ... )
	--     local strData = Tools.encode("TrialAreaReq", {
	--         type = 3,
	--         area_id = self.chooseNode:getTag(),
	--     })
	--     GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_REQ"),strData)

	--     gl:retainLoading()
	-- end)

	--
	local choose = {index = 1, flag = false}
	for i=1,3 do
		local areaType = player:getTrialAreaType(i)

		if (player:getLevel() < CONF.TRIAL_AREA.get(i).ROLE_LEVEL or player:getPower() < CONF.TRIAL_AREA.get(i).ROLE_COMBAT) and areaType ~= 1 then
			rn:getChildByName("name_"..i):getChildByName("xxx"):setVisible(false)
			rn:getChildByName("name_"..i):getChildByName("now_num"):setVisible(false)
			rn:getChildByName("name_"..i):getChildByName("max_num"):setVisible(false)
			rn:getChildByName("name_"..i):getChildByName("not"):setVisible(true)

			rn:getChildByName("name_"..i):getChildByName("not"):setString(CONF:getStringValue("notOpen"))

			table.insert(self.canIn_, false)
		else

			local cengNowNum = 0 
			local cengMaxNum = 0
			local starNowNum = 0
			local starMaxNum = 0

			for i,v in ipairs(CONF.TRIAL_AREA.get(i).SCENE_ID) do
				for ii,vv in ipairs(CONF.TRIAL_SCENE.get(v).T_COPY_LIST) do
					local conf = CONF.TRIAL_COPY.get(vv)
					cengMaxNum = cengMaxNum + conf.LEVEL_NUM
					starMaxNum = starMaxNum + conf.START_NUM
					for iii,vvv in ipairs(conf.LEVEL_ID) do
						local star = player:getTrialLevelStar(vvv)
						starNowNum = starNowNum + star

						if star ~= 0 then
							cengNowNum = cengNowNum + 1
						end

					end
				end
			end

			rn:getChildByName("name_"..i):getChildByName("now_num"):setString(cengNowNum)
			rn:getChildByName("name_"..i):getChildByName("max_num"):setString("/"..cengMaxNum)
			rn:getChildByName("name_"..i):getChildByName("max_num"):setPositionX(rn:getChildByName("name_"..i):getChildByName("now_num"):getPositionX() + rn:getChildByName("name_"..i):getChildByName("now_num"):getContentSize().width)

			if areaType == 0 then
				rn:getChildByName("name_"..i):getChildByName("xxx"):setString(CONF:getStringValue("history"))

				if not choose then
					choose.index = i
				end

			elseif areaType == 1 then
				rn:getChildByName("name_"..i):getChildByName("xxx"):setString(CONF:getStringValue("scheduler"))

				choose.index = i
				choose.flag = true

			end

			table.insert(self.canIn_, true)

		end
	end

	-- if player:getLevel() >= 10 then
		self:resetDownPanel(choose.index)  
	-- end


	rn:getChildByName("money_touch"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self, {index = 1})
		self:addChild(rechargeNode)
	end)

	rn:getChildByName("money_add"):addClickEventListener(function ( ... )
		playEffectSound("sound/system/click.mp3")

		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self, {index = 1})
		self:addChild(rechargeNode)
	end)

	--
	local children = rn:getChildren()

	-- for ii,vv in ipairs(children) do

	--     local name = vv:getName()
	--     local filePath = string.format("ChapterScene/Chanjing/1/%s.csb", name)

	--     local file = cc.FileUtils:getInstance():isFileExist(filePath)
	--     if file then
	--         animManager:runAnimByCSB(vv, filePath,  "1")
	--     end

	--     local filePath_X = string.format("ChapterScene/Chanjing/1/%s_X.csb", name)
	--     local file_X = cc.FileUtils:getInstance():isFileExist(filePath_X)
	--     if file_X then
	--         animManager:runAnimOnceByCSB(vv, filePath_X,  "1", function()
	--             animManager:runAnimByCSB(vv, filePath_X,  "2")
	--         end)
	--     end
	
	-- end

	for ii,vv in ipairs(children) do

		local name = vv:getName()
		local filePath = string.format("TrialScene/TrialAreaScene/guanka1/%s.csb", name)

		local file = cc.FileUtils:getInstance():isFileExist(filePath)
		if file then
			animManager:runAnimByCSB(vv, filePath,  "1")
		end

		local filePath_X = string.format("TrialScene/TrialAreaScene/guanka1/%s_X.csb", name)
		local file_X = cc.FileUtils:getInstance():isFileExist(filePath_X)
		if file_X then
			animManager:runAnimOnceByCSB(vv, filePath_X,  "1", function()
				animManager:runAnimByCSB(vv, filePath_X,  "2")
			end)
		end
	
	end

	for i=1,3 do
		local areaType = player:getTrialAreaType(i)

		if areaType == 1 then
			animManager:runAnimByCSB(rn:getChildByName("Star_"..i), "TrialScene/TrialAreaScene/guanka1/Star_"..i..".csb",  "2")
		end

		-- if i == 2 then
		--     animManager:runAnimByCSB(rn:getChildByName("guangyun"), "TrialScene/TrialAreaScene/guanka1/guangyun.csb",  "2")
		-- end
	end

	--

	local function onTouchBegan(touch, event)

		return true
	end


	local function onTouchEnded(touch, event)

		local rn = self:getResourceNode()

		for i=1,3 do
			local stage = rn:getChildByName("stage_"..i)

			if i == 1 then
				local s = stage:getContentSize()
				local locationInNode = stage:convertToNodeSpace(touch:getLocation())
				local rect = cc.rect(0, 0, s.width, s.height)
				if cc.rectContainsPoint(rect, locationInNode) then
					self:resetDownPanel(i)
		
					return 
				end
			else
				if self.canIn_[i] or self.canIn_[i-1] then
					if stage == nil then
								
					else
				
						local s = stage:getContentSize()
						local locationInNode = stage:convertToNodeSpace(touch:getLocation())
						local rect = cc.rect(0, 0, s.width, s.height)
						if cc.rectContainsPoint(rect, locationInNode) then
							self:resetDownPanel(i)
				
							return 
						end
				
					end
				else
					-- tips:tips(CONF:getStringValue("level or power not enough"))

				end
			end
	
			
		end

	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)

	self.ani_ = false
	animManager:runAnimOnceByCSB(rn, "TrialScene/TrialAreaScene/TrialAreaScene.csb", "intro", function ( )
		self.ani_ = true
		self:resetDownPanel(self.chooseNode:getTag())
	end)

	-- animManager:runAnimByCSB(Panel_top:getChildByName("zhanli"), "CityScene/sfx/zhanli/zhanli.csb",  "1")

	local function update(dt)

		-- rn:getChildByName("Panel_top"):getChildByName("continue_time"):setString(formatTime(86400 - player:getServerTime()%86400))

		for i,v in ipairs(self.times) do
			v:getChildByName("time_num"):setString(formatTime(86400 - player:getServerTime()%86400))
		end
		
	end

	schedulerEntry = scheduler:scheduleScriptFunc(update,1,false)

	local function recvMsg()
		print("TrialAreaScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_GET_TIMES_RESP") then
			if self.data_ and self.data_.noRetain then
			else
				gl:releaseLoading()
			end

			local proto = Tools.decode("TrialGetTimesResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result) 
			else
				print("cishu: ",proto.ticket_num)
				self:getResourceNode():getChildByName("cishu_num"):setString(proto.ticket_num)
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_OPEN_ATEA_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TrialAreaResp",strData)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				-- self:getApp():pushView("TrialScene/TrialStageScene", {scene = player:getTrialScene(self.chooseNode:getTag()), slPosX = 0})
				self:resetDownPanel(self.chooseNode:getTag())
				self:resetAreaInfo()
				
			end

		elseif cmd == Tools.enum_id("CMD_DEFINE","CMD_TRIAL_ADD_TICKET_RESP") then
			gl:releaseLoading()

			local proto = Tools.decode("TrialAddTicketResp",strData)
			printInfo("TrialAddTicketResp")
			printInfo(proto.result)

			if proto.result ~= 0 then
				print("error :",proto.result)
			else
				printInfo("cishu s: "..proto.ticket_num)
				player:setTrialTicketNum(proto.ticket_num)
				self:getResourceNode():getChildByName("cishu_num"):setString(player:getTrialTicketNum())
				
			end
		end
	   
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.broadcastListener_ = cc.EventListenerCustom:create("broadcastRun", function ()
		broadcastRun()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.broadcastListener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		rn:getChildByName("money_num"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)
 
end

function TrialAreaScene:onExitTransitionStart()
	printInfo("TrialAreaScene:onExitTransitionStart()")

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.broadcastListener_)
	eventDispatcher:removeEventListener(self.moneyListener_)

end

return TrialAreaScene