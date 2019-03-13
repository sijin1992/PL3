local player = require("app.Player"):getInstance()

local tips = require("util.TipsMessage"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local messageBox = require("util.MessageBox"):getInstance()

local guideManager = require("app.views.GuideLayer.GuideManager"):getInstance()

local talkManager = require("app.views.TalkLayer.TalkManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local ChapterScene = class("ChapterScene", cc.load("mvc").ViewBase)

ChapterScene.RESOURCE_FILENAME = "ChapterScene/ChapterScene.csb"

ChapterScene.RUN_TIMELINE = true

ChapterScene.NEED_ADJUST_POSITION = true

ChapterScene.RESOURCE_BINDING = {
	--["Button_1"]   = {["varname"] = "btn"},
	["close"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

local schedulerEntry = nil


function ChapterScene:onCreate(data)

	self.data_ = data

	self.areas = {}
	if data and data.sfx then
		data.sfx = false
		self:getApp():addView2Top("CityScene/TransferScene",{from = "ChapterScene" ,state = "enter"})
	end
end

function ChapterScene:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" and event.target:getName() == "close" then
		printInfo("close")
		playEffectSound("sound/system/return.mp3")
		-- self:getApp():pushToRootView("CityScene/CityScene", {pos = -350})
		self:getApp():addView2Top("CityScene/TransferScene",{from = "city2" ,state = "start"})
	end


end


function ChapterScene:onEnter()
  
	printInfo("ChapterScene:onEnter()")


	local function imageLoaded( texture )
		self:resetSfx()
	end

	cc.Director:getInstance():getTextureCache():addImageAsync("ChapterScene/guankada/guank/guank.png", imageLoaded)

end

function ChapterScene:resetSfx()

	local rn = self:getResourceNode()
	
	for i=1,6 do
		local texiao = require("app.ExResInterface"):getInstance():FastLoad(string.format("ChapterScene/guankada/%d.csb", i))

		texiao:setPosition(cc.p(rn:getChildByName("texiao_pos_"..i):getPosition()))

		texiao:setName("texiao_"..i)

		rn:addChild(texiao)
	end

	for i=1,5 do
		print(player:getMaxArea())
		if i > player:getMaxArea() then
			animManager:runAnimByCSB(rn:getChildByName("texiao_"..i), "ChapterScene/guankada/"..i..".csb",  "2")

		else
			animManager:runAnimByCSB(rn:getChildByName("texiao_"..i), "ChapterScene/guankada/"..i..".csb",  "1")
		end
	end

	animManager:runAnimByCSB(rn:getChildByName("texiao_6"), "ChapterScene/guankada/6.csb",  "1")

end

function ChapterScene:onExit()
	
	printInfo("ChapterScene:onExit()")
end

function ChapterScene:resetDownInfo( index )
	local conf = CONF.AREA.get(index)

	local rn = self:getResourceNode()

	if index > player:getMaxArea() + 1 then
		return
	end

	-- for i=1,5 do
	-- 	if i == index then
	-- 		rn:getChildByName("star_text_"..i):getChildByName("light"):setVisible(true)
	-- 		rn:getChildByName("star_text_"..i):getChildByName("line"):setVisible(true)
	-- 	else
	-- 		rn:getChildByName("star_text_"..i):getChildByName("light"):setVisible(false)
	-- 		rn:getChildByName("star_text_"..i):getChildByName("line"):setVisible(false)
	-- 	end
	-- end

	-- self.chooseNode:setPosition(cc.p(self:getResourceNode():getChildByName("stage_"..index):getPosition()))
	-- self.chooseNode:setTag(index)
	-- self.chooseNode:setLocalZOrder(2)

	-- if self.chooseNode:getChildByName("choose_ins") then
	-- 	self.chooseNode:getChildByName("choose_ins"):removeFromParent()
	-- end

	-- if self.chooseNode:getPositionX() >= rn:getContentSize().width then
	-- 	local ins_node = require("app.ExResInterface"):getInstance():FastLoad("Common/InsNode_left.csb")

	-- 	local choose_ins = require("app.ExResInterface"):getInstance():FastLoad("ChapterScene/choose_ins.csb")

	-- 	choose_ins:getChildByName("need"):setString(CONF:getStringValue("demand"))
	-- 	choose_ins:getChildByName("suggest"):setString(CONF:getStringValue("suggestion"))

	-- 	choose_ins:getChildByName("lv_num"):setString(conf.OPEN_LEVEL)
	-- 	choose_ins:getChildByName("fight_num"):setString(conf.RECOMMENDED)

	-- 	choose_ins:setPosition(cc.p(ins_node:getChildByName("node"):getPosition()))
	-- 	ins_node:addChild(choose_ins)

	-- 	ins_node:setName("choose_ins")
	-- 	ins_node:setPosition(cc.p(self.chooseNode:getChildByName("left_pos"):getPosition()))
	-- 	self.chooseNode:addChild(ins_node)
	-- else
	-- 	local ins_node = require("app.ExResInterface"):getInstance():FastLoad("Common/InsNode_right.csb")

	-- 	local choose_ins = require("app.ExResInterface"):getInstance():FastLoad("ChapterScene/choose_ins.csb")

	-- 	choose_ins:getChildByName("need"):setString(CONF:getStringValue("demand"))
	-- 	choose_ins:getChildByName("suggest"):setString(CONF:getStringValue("suggestion"))

	-- 	choose_ins:getChildByName("lv_num"):setString(conf.OPEN_LEVEL)
	-- 	choose_ins:getChildByName("fight_num"):setString(conf.RECOMMENDED)

	-- 	choose_ins:setPosition(cc.p(ins_node:getChildByName("node"):getPosition()))
	-- 	ins_node:addChild(choose_ins)

	-- 	ins_node:setName("choose_ins")
	-- 	ins_node:setPosition(cc.p(self.chooseNode:getChildByName("right_pos"):getPosition()))
	-- 	self.chooseNode:addChild(ins_node)
	-- end

	rn:getChildByName("btn_go"):setTag(index)

	local panel_down = self:getResourceNode():getChildByName("Panel_down")
	panel_down:getChildByName("ins"):setString("  "..CONF:getStringValue(conf.INTRODUCE_ID))

	self:resetStarText(index)


end

function ChapterScene:resetStar()
	local rn = self:getResourceNode()

	for i=1,5 do

		local star_text = rn:getChildByName("star_text_"..i)

		animManager:runAnimByCSB(star_text:getChildByName("texiao"), "ChapterScene/sfx/1.csb", "1")


		local conf = CONF.AREA.get(i)

		star_text:setTag(500+i)
		star_text:getChildByName("name"):setString(CONF:getStringValue(conf.NAME_ID))
		star_text:getChildByName("Lv_num"):setString("Lv."..conf.OPEN_LEVEL)
		
		if i > player:getMaxArea()+1 then
			star_text:getChildByName("name"):setTextColor(cc.c4b(214, 214, 215, 255))
			-- star_text:getChildByName("name"):enableShadow(cc.c4b(214, 214, 215, 255),cc.size(0.5,0.5))
			star_text:getChildByName("Lv_num"):setTextColor(cc.c4b(255, 255, 255, 255))
			-- star_text:getChildByName("Lv_num"):enableShadow(cc.c4b(255, 255, 255, 255),cc.size(0.5,0.5))

		else

			local star_now = 0
			local star_max = 0
			for i2,v2 in ipairs(conf.SIMPLE_COPY_ID) do
				for i3,v3 in ipairs(CONF.COPY.get(v2).LEVEL_ID) do
					local level_conf = CONF.CHECKPOINT.get(v3)
					star_now = star_now + player:getCopyStar(v3)
					star_max = star_max + level_conf.START_NUM
				end
			end

			star_text:getChildByName("star_now"):setString(star_now)
			star_text:getChildByName("star_max"):setString("/"..star_max)

			for i2,stage in ipairs(conf.SIMPLE_COPY_ID) do
				local conf_copy = CONF.COPY.get(stage)
				for i=1,3 do
					if conf_copy["SCORE"..i] <= player:getStageStar(conf_copy.ID) then
						if not player:getStageReward(conf_copy.ID)[i] then
							star_text:getChildByName("point"):setVisible(true)
						end
					end
				end
			end

			star_text:getChildByName("star_now"):setPositionX(star_text:getChildByName("star_max"):getPositionX() - star_text:getChildByName("star_max"):getContentSize().width)
			star_text:getChildByName("star"):setPositionX(star_text:getChildByName("star_now"):getPositionX() - star_text:getChildByName("star_now"):getContentSize().width - 5)

			star_text:getChildByName("star_now"):setVisible(true)
			star_text:getChildByName("star_max"):setVisible(true)
			star_text:getChildByName("star"):setVisible(true)
			star_text:getChildByName("Lv_num"):setVisible(false)

		end
	end

	-- for i=1,5 do
	-- 	if i > player:getMaxArea() then
	-- 		animManager:runAnimByCSB(rn:getChildByName("texiao_"..i), "ChapterScene/guankada/"..i..".csb",  "2")

	-- 	else
	-- 		animManager:runAnimByCSB(rn:getChildByName("texiao_"..i), "ChapterScene/guankada/"..i..".csb",  "1")
	-- 	end
	-- end

	-- animManager:runAnimByCSB(rn:gsetChildByName("texiao_5"), "ChapterScene/guankada/5.csb",  "2")	
	
end

function ChapterScene:resetStarText( index )
	
	for i=1,5 do

		local star_text = self:getResourceNode():getChildByName("star_text_"..i)

		local num = 1
		if player:getMaxArea() == 5 then
			num = 0
		end

		if i <= player:getMaxArea()+num then
			if i == index then
				star_text:getChildByName("bg"):setTexture("Common/newUI/fb0"..i.."_light.png")
				star_text:getChildByName("line"):setTexture("Common/newUI/gk_line_yellow.png")
				star_text:getChildByName("dian"):setTexture("Common/newUI/dian03.png")

				star_text:getChildByName("texiao"):setVisible(true)

				star_text:getChildByName("name"):setPosition(cc.p(star_text:getChildByName("pos_3"):getPosition()))

			else
				star_text:getChildByName("bg"):setTexture("Common/newUI/fb0"..i..".png")
				star_text:getChildByName("line"):setTexture("Common/newUI/gk_line_blue.png")
				star_text:getChildByName("dian"):setTexture("Common/newUI/dian04.png")

				star_text:getChildByName("texiao"):setVisible(false)

				star_text:getChildByName("name"):setPosition(cc.p(star_text:getChildByName("pos_2"):getPosition()))
			end
		end
	end 

end

function ChapterScene:resetTalk( ... )

	-- if guideManager:getGuideType() then
	--     return
	-- end

	local max_area = player:getMaxArea()
	local b_area = max_area - 1 

	if talkManager:getPlayerTalkID() ~= nil then
		-- print("heh",talkManager:getPlayerTalkID())

		-- if player:getMaxArea() > 1 then

		-- 	if talkManager:getPlayerTalkID() == CONF.TALK.get("TALK_"..b_area.."2").ID - 1 then
		-- 		talkManager:createTalkLayer(CONF.TALK.get("TALK_"..b_area.."2").KEY)

		-- 	elseif talkManager:getPlayerTalkID() == CONF.TALK.get("TALK_"..max_area.."1").ID - 1 then
		-- 		talkManager:createTalkLayer(CONF.TALK.get("TALK_"..max_area.."2").KEY)
		-- 	end

		-- else
		-- 	if talkManager:getPlayerTalkID() == CONF.TALK.get("TALK_12").ID - 1 then
		-- 		talkManager:createTalkLayer("TALK_12")
		-- 	end

		-- end

		talkManager:addTalkLayer(3)
		-- talkManager:addGuideStep("TALK_11")

	else
		talkManager:createTalkLayer(CONF.TALK.get(1).KEY)

	end


end

function ChapterScene:resetStrength( ... )

	local rn = self:getResourceNode()
	local you = rn:getChildByName("you"):getChildByName("res_node")

	-- local strenthBar = you:getChildByName("progress")
	-- self.strengthDelegate_ = require("util.ScaleProgressDelegate"):create(strenthBar, strenthBar:getTag())

	-- local p = player:getStrength() / player:getMaxStrength() * 100 
	-- if p > 100 then
	-- 	p = 100
	-- end
	-- self.strengthDelegate_:setPercentage(p)

	you:getChildByName("ev_num"):setString(player:getStrength() .. "/" .. player:getMaxStrength());
end

function ChapterScene:onEnterTransitionFinish()

	printInfo("ChapterScene:onEnterTransitionFinish()")

	guideManager:checkInterface(CONF.EInterface.kChapter)

	-- local systemGuideManager = require("app.views.SystemGuideLayer.SystemGuideManager"):getInstance()
	-- if player:getSystemGuideStep(CONF.ESystemGuideInterFace.kCopy) == 0 and g_System_Guide_Id == 0 then
	-- 	systemGuideManager:createGuideLayer(CONF.FUNCTION_OPEN.get("copy_open").INTERFACE)
	-- else
	-- 	if g_System_Guide_Id ~= 0 then
	-- 		systemGuideManager:createGuideLayer(g_System_Guide_Id)
	-- 	end
	-- end

	broadcastRun()

	self:resetTalk()

	self:resetStarText(player:getMaxArea())

	local strData = Tools.encode("GetChatLogReq", {

			chat_id = 0
		})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_REQ"),strData)

	gl:retainLoading()

	local rn = self:getResourceNode()

	local userInfoNode = require("util.UserInfoNode"):create()
	userInfoNode:init(self)
	rn:getChildByName("info_node"):addChild(userInfoNode)

	rn:getChildByName("btn_go"):getChildByName("text"):setString(CONF:getStringValue("go"))

	local you = rn:getChildByName("you"):getChildByName("res_node")
	rn:getChildByName("Panel_down"):getChildByName("synopsis"):setString(CONF:getStringValue("synopsis"))
	-- rn:getChildByName("Panel_down"):getChildByName("go"):getChildByName("text"):setString(CONF:getStringValue("go"))

	rn:getChildByName("Panel_down"):getChildByName("chat"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local layer = self:getApp():createView("ChatLayer/ChatLayer", {name = "world"})
		layer:setName("chatLayer")
		self:addChild(layer)

		rn:getChildByName("Panel_down"):getChildByName("chat"):getChildByName("point"):setVisible(false)

	end)

	-- local function fun1( ... )
	--     printInfo("xxxxx")
	-- end

	-- local function fun2( ... )
	--     printInfo("sssss")
	-- end

	-- local dele = require("util.LongPressDelegate"):create(rn:getChildByName("Panel_down"):getChildByName("chat"), fun1, fun2)

	-- self.chooseNode = require("app.ExResInterface"):getInstance():FastLoad("ChapterScene/choose.csb")
	-- self.chooseNode:getChildByName("text"):setString(CONF:getStringValue("go"))
	-- self.chooseNode:getChildByName("button"):addClickEventListener(function ( sender )
	-- 	playEffectSound("sound/system/click.mp3")
	-- 	local conf = CONF.AREA.get(self.chooseNode:getTag())
	-- 	local area = self.chooseNode:getTag()
	-- 	local index_ = player:getStageByArea(area)
	-- 	local stage = conf.SIMPLE_COPY_ID[index_]
	-- 	local copy = player:getCopyInStage(stage)
	-- 	self:getApp():pushToRootView("LevelScene", {area = area, stage = stage, index = copy})
	-- end)
	-- self:getResourceNode():addChild(self.chooseNode)
	-- self.chooseNode:setTag(player:getMaxArea())
	rn:getChildByName("btn_go"):setVisible(false)
	rn:getChildByName("btn_go"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local conf = CONF.AREA.get(sender:getTag())
		local area = sender:getTag()
		local index_ = player:getStageByArea(area)
		local stage = conf.SIMPLE_COPY_ID[index_]
		local copy = player:getCopyInStage(stage)
		self:getApp():pushToRootView("LevelScene", {area = area, stage = stage, index = copy})
	end)

	rn:getChildByName("btn_go"):setTag(player:getMaxArea())


	for i=1,5 do

		rn:getChildByName("star_text_"..i):getChildByName("touch"):addClickEventListener(function ( sender )
			playEffectSound("sound/system/tab.mp3")
			local conf = CONF.AREA.get(i)

			if conf.PRE_AREAID == 0 or player:getFinishArea(conf.PRE_AREAID) then
				self:resetDownInfo(i)
				local area = i
				local index_ = player:getStageByArea(area)
				local stage = conf.SIMPLE_COPY_ID[index_]
				local copy = player:getCopyInStage(stage)
				self:getApp():pushToRootView("LevelScene", {area = area, stage = stage, index = copy})            
			else

				if i <= player:getMaxArea() + 1 then
					if not player:getFinishArea(player:getMaxArea()) then
						tips:tips(CONF:getStringValue("need_finish_before_area"))
					else
						if player:getLevel() < conf.OPEN_LEVEL then
							tips:tips(CONF:getStringValue("level_not_enought"))
						end
					end
				end
			end
		end)

	end

	-- local clippingNode = require("util.ClippingNode"):createNode("CityScene/ui3/mask_player.png", "HeroImage/"..player:getPlayerIcon()..".png",{alpha = 0.5, pos = cc.p(30,0)})
	-- clippingNode:setPosition(cc.p(rn:getChildByName("headImage"):getPositionX()-23,rn:getChildByName("headImage"):getPositionY()+3))
	-- clippingNode:setScale(0.63)
	-- rn:addChild(clippingNode)

	-- rn:getChildByName("headImage"):removeFromParent()

	-- rn:getChildByName("player_mask_230"):setLocalZOrder(2)
	-- rn:getChildByName("exp_progress"):setLocalZOrder(3)
	-- rn:getChildByName("lv"):setLocalZOrder(2)

	-- rn:getChildByName("headImage"):loadTexture("HeroImage/"..player:getPlayerIcon()..".png")

	-- rn:getChildByName("reaper_aleriness"):setString(player:getNickName())
	-- rn:getChildByName("lv"):setString("Lv."..player:getLevel())
	-- rn:getChildByName("fight_num"):setString(CONF:getStringValue("combat")..":"..player:getPower())
	for i=1,4 do
		you:getChildByName(string.format("res_text_%d", i)):setString(formatRes(player:getResByIndex(i)))
	end
	--set credit

	you:getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()))


	you:getChildByName("money_add"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self:getParent(), {index = 1})
		self:getParent():addChild(rechargeNode)
	end)

	you:getChildByName("touch2"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		local rechargeNode = require("app.views.CityScene.RechargeNode"):create()

		rechargeNode:init(self:getParent(), {index = 1})
		self:getParent():addChild(rechargeNode)
	end)


	-- callback
	you:getChildByName("ev_num"):setString(player:getStrength() .. "/" .. player:getMaxStrength());

	you:getChildByName("strength_add"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		self:getApp():addView2Top("CityScene/AddStrenthLayer")
	end)

	you:getChildByName("touch1"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		self:getApp():addView2Top("CityScene/AddStrenthLayer")
	end)


	local function recvMsg()
		print("ChapterScene:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GET_CHAT_LOG_RESP") then

			local proto = Tools.decode("GetChatLogResp",strData)
			print("ChapterScene GetChatLogResp result",proto.result)

			gl:releaseLoading()

			if proto.result < 0 then
				print("error :",proto.result)
			else
				print("proto.log_list", #proto.log_list)
				
				local time = 0
				local str = ""
				local tt 

				for i,v in ipairs(proto.log_list) do
					if v.stamp > time then
						time = v.stamp
						local last = v.chat

						local strc = ""
						if v.group_name ~= "" then
							strc = string.format("[%s]%s:", v.group_name, v.nickname)
						else
							strc = string.format("%s:", v.nickname)
						end
						str = handsomeSubString(strc..v.chat, CONF.PARAM.get("chat number").PARAM)

						tt = {user_name = v.user_name, chat = v.chat, time = v.stamp}

					end
				end

				if player:getLastChat() == nil then
					rn:getChildByName("Panel_down"):getChildByName("chat"):getChildByName("point"):setVisible(true)
				else
					if player:getLastChat().user_name == tt.user_name and player:getLastChat().chat == tt.chat and player:getLastChat().time == tt.time then
						rn:getChildByName("Panel_down"):getChildByName("chat"):getChildByName("point"):setVisible(false)
					else
						rn:getChildByName("Panel_down"):getChildByName("chat"):getChildByName("point"):setVisible(true)
					end
				end

			end

		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	self.moneyListener_ = cc.EventListenerCustom:create("MoneyUpdated", function ()
		you:getChildByName("res_text_5"):setString(tostring(player:getMoney()))--formatRes(player:getMoney()) )                                                                                                                                                                                                                                                     
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.moneyListener_, FixedPriority.kNormal)

	self.talkListener_ = cc.EventListenerCustom:create("talk_over", function ()
		self:resetTalk()                                                                                                                                                                                                                                                 
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.talkListener_, FixedPriority.kNormal)

	self.strengthListener = cc.EventListenerCustom:create("StrengthUpdated", function ()
		self:resetStrength()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.strengthListener, FixedPriority.kNormal)

	self.broadcastListener_ = cc.EventListenerCustom:create("broadcastRun", function ()
		broadcastRun()
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.broadcastListener_, FixedPriority.kNormal)

	self.seeChatListener_ = cc.EventListenerCustom:create("seeChat", function ()
		rn:getChildByName("Panel_down"):getChildByName("chat"):getChildByName("point"):setVisible(false)
	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.seeChatListener_, FixedPriority.kNormal)

	self.worldListener_ = cc.EventListenerCustom:create("worldMsg", function (event)
		playEffectSound("sound/system/message_update.mp3")
		if self:getChildByName("chatLayer") then
			rn:getChildByName("Panel_down"):getChildByName("chat"):getChildByName("point"):setVisible(false)
		else
			rn:getChildByName("Panel_down"):getChildByName("chat"):getChildByName("point"):setVisible(true)
		end

	end)
	eventDispatcher:addEventListenerWithFixedPriority(self.worldListener_, FixedPriority.kNormal)

	--set strength
	-- local strenthBar = you:getChildByName("progress")
	-- self.strengthDelegate_ = require("util.ScaleProgressDelegate"):create(strenthBar, strenthBar:getTag())

	-- local p = player:getStrength() / player:getMaxStrength() * 100 
	-- if p > 100 then
	-- 	p = 100
	-- end
	-- self.strengthDelegate_:setPercentage(p)

	-- you:getChildByName("ev_num"):setString(player:getStrength().."/"..player:getMaxStrength())

	-- rn:getChildByName("light_top"):setPositionX(rn:getChildByName("progress"):getPositionX() + rn:getChildByName("progress"):getContentSize().width - 10)
	-- rn:getChildByName("light_back"):setPositionX(rn:getChildByName("progress"):getPositionX() + rn:getChildByName("progress"):getContentSize().width - 16)


	--set exp
	
	-- local exp_bar = rn:getChildByName("exp_progress")
	-- self.expDelegate_ = require("util.ScaleProgressDelegate"):create(exp_bar, exp_bar:getTag())

	-- local p = player:getNextLevelExpPercent()

	-- if p > 100 then
	-- 	p = 100
	-- end

	-- self.expDelegate_:setPercentage(p)

	-- rn:getChildByName("Panel_down"):getChildByName("go"):addClickEventListener(function ( ... )
	--     local conf = CONF.AREA.get(self.chooseNode:getTag())
	--     local area = self.chooseNode:getTag()
	--     local index_ = player:getStageByArea(area)
	--     local stage = conf.SIMPLE_COPY_ID[index_]
	--     local copy = player:getCopyInStage(stage)
	--     self:getApp():pushToRootView("LevelScene", {area = area, stage = stage, index = copy})
	-- end)

	self:resetStar()

	animManager:runAnimOnceByCSB(rn, "ChapterScene/ChapterScene.csb", "intro", function ( ... )
		self:resetDownInfo(player:getMaxArea())

		
	end)

	-- animManager:runAnimByCSB(rn:getChildByName("texiao_6"), "ChapterScene/guankada/6.csb",  "1")
	-- animManager:runAnimByCSB(rn:getChildByName("zhanli"), "CityScene/sfx/zhanli/zhanli.csb",  "1")

	-- for i=1,5 do
	-- 	animManager:runAnimOnceByCSB(rn:getChildByName("star_text_"..i), "ChapterScene/star_ins.csb", "1")
	-- end

	-- local function onTouchBegan(touch, event)

	-- 	return true
	-- end


	-- local function onTouchEnded(touch, event)

	-- 	local rn = self:getResourceNode()

	-- 	for i=1,5 do
	-- 		local stage = rn:getChildByName("stage_"..i)
	
	-- 		local conf = CONF.AREA.get(stage:getTag())

	-- 		local s = stage:getContentSize()
	-- 		local locationInNode = stage:convertToNodeSpace(touch:getLocation())
	-- 		local rect = cc.rect(0, 0, s.width, s.height)
	-- 		if cc.rectContainsPoint(rect, locationInNode) then

	-- 			if conf.PRE_AREAID == 0 or player:getFinishArea(conf.PRE_AREAID) then
	-- 				self:resetDownInfo(stage:getTag())            
	-- 				return 
	-- 			else

	-- 				if i <= player:getMaxArea() + 1 then
	-- 					if not player:getFinishArea(player:getMaxArea()) then
	-- 						tips:tips(CONF:getStringValue("need_finish_before_area"))
	-- 					else
	-- 						if player:getLevel() < conf.OPEN_LEVEL then
	-- 							tips:tips(CONF:getStringValue("level_not_enought"))
	-- 						end
	-- 					end
	-- 				end
	-- 			end
	-- 		end

	-- 	end

	-- end

	-- local listener = cc.EventListenerTouchOneByOne:create()
	-- listener:setSwallowTouches(true)
	-- listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	-- listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
	-- self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)

end

function ChapterScene:onExitTransitionStart()

	printInfo("ChapterScene:onExitTransitionStart()")

	if schedulerEntry ~= nil then
		scheduler:unscheduleScriptEntry(schedulerEntry)
	end

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)
	eventDispatcher:removeEventListener(self.moneyListener_)
	eventDispatcher:removeEventListener(self.talkListener_)
	eventDispatcher:removeEventListener(self.strengthListener)
	eventDispatcher:removeEventListener(self.broadcastListener_)
	eventDispatcher:removeEventListener(self.worldListener_)
	eventDispatcher:removeEventListener(self.seeChatListener_)
end

return ChapterScene