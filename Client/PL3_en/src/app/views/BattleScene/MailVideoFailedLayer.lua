local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local MailVideoFailedLayer = class("MailVideoFailedLayer", cc.load("mvc").ViewBase)

MailVideoFailedLayer.RESOURCE_FILENAME = "BattleScene/FailedLayer/FailedLayer.csb"

MailVideoFailedLayer.NEED_ADJUST_POSITION = true

MailVideoFailedLayer.mail_info = {}

MailVideoFailedLayer.RESOURCE_BINDING = {
	["back_to_game"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}

function MailVideoFailedLayer:OnBtnClick(event)
	printInfo(event.name)


	if event.name == "ended" and event.target:getName() == "back_to_game" then
		local video = tonumber(Tools.split(g_MailGuid_VideoPosition,'_')[2])
		if Tools.isEmpty(self.mail_info) == false and Tools.isEmpty(self.mail_info.planet_report.video_key_list) == false and self.mail_info.planet_report.video_key_list[video+1] then
			g_MailGuid_VideoPosition = self.mail_info.guid..'_'..(video+1)
			local strData = Tools.encode("PvpVideoReq", {
				video_key = self.mail_info.planet_report.video_key_list[video+1],
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVP_VIDEO_REQ"),strData)
		else
			local from = ''
			playEffectSound("sound/system/click.mp3")
			if self.from == 'city' then
				from = 'city'
				app:pushToRootView("CityScene/CityScene", {pos = g_city_scene_pos})
			elseif self.from == 'Normal' then
				from = 'Normal'
				app:pushToRootView("PlanetScene/PlanetScene")
			end
			if from ~= '' then
				app:pushView("MailScene/MailScene",{from = from,type = 'video',id = self.mail_info.guid})
			end
			playMusic("sound/main.mp3", true)
		end
	end
end

function MailVideoFailedLayer:init(data,ship_list,from)
	self.ship_list = ship_list
	self.data_ = data
	self.from = from
end

function MailVideoFailedLayer:onEnterTransitionFinish()

	printInfo("MailVideoFailedLayer:onEnterTransitionFinish()")

	playEffectSound("sound/system/failed.mp3")
	local rn = self:getResourceNode()
	rn:getChildByName("sb_bq_bottom"):setVisible(false)
	for i=1,4 do
		rn:getChildByName("go_text_"..i):setString(CONF:getStringValue("failed_go_"..i))
		rn:getChildByName("go_"..i):setVisible(false)
		rn:getChildByName("go_text_"..i):setVisible(false)
		rn:getChildByName("go_"..i):addTouchEventListener(function ( sender, eventType )

			playEffectSound("sound/system/click.mp3")
			-- if eventType == ccui.TouchEventType.began then
			-- 	sender:setScale(0.9)
			-- elseif eventType == ccui.TouchEventType.canceled then
			-- 	sender:setScale(1)
			-- elseif eventType == ccui.TouchEventType.ended then
			-- 	sender:setScale(1)
			-- 	playMusic("sound/main.mp3", true)
			-- 	if i == 1 then
			-- 		app:pushToRootView("CityScene/CityScene", {pos = -350, go = "ShipsForm"})
			-- 	elseif i == 2 then
			-- 		goScene(18,2)
			-- 	elseif i == 3 then
			-- 		goScene(5)
			-- 	elseif i == 4 then
			-- 		goScene(6,1)
			-- 	end
			-- end

		end)
	end
	rn:getChildByName("go_4"):setVisible(false)
	rn:getChildByName("go_text_4"):setVisible(false)
	self:getResourceNode():getChildByName("back_to_game"):getChildByName("text"):setString(CONF:getStringValue("back"))
	local mail_list = player.mail_list_
	local guid = tonumber(Tools.split(g_MailGuid_VideoPosition,'_')[1])
	local video = tonumber(Tools.split(g_MailGuid_VideoPosition,'_')[2])
	for k,v in ipairs(mail_list) do
		if v.guid == guid then
			self.mail_info = v
			break
		end
	end
	if Tools.isEmpty(self.mail_info) == false and Tools.isEmpty(self.mail_info.planet_report.video_key_list) == false and self.mail_info.planet_report.video_key_list[video+1] then
		self:getResourceNode():getChildByName("back_to_game"):getChildByName("text"):setString(CONF:getStringValue("next_video"))
	end
	local function onTouchBegan(touch, event)

		return true
	end
	local getMail  = function(guid)
		if Tools.isEmpty(player.mail_list_) then return nil end
		for i,v in ipairs(player.mail_list_) do
			if v.guid == guid then
				return v
			end
		end
		return nil
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	local function recvMsg()
		print("StarWinLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id('CMD_DEFINE','CMD_PVP_VIDEO_RESP') then
			local proto = Tools.decode("PvpVideoResp",strData)
			if proto.result == 0 then
				if Tools.isEmpty(proto.data.resp.hurter_list) == false and Tools.isEmpty(proto.data.resp.attack_list) == false then
					local enemyName
					local enemyIconPath
					local myName
					local myIconPath
					local guid = tonumber(Tools.split(g_MailGuid_VideoPosition,'_')[1])
					local mail = getMail( guid )
					local switchGroup1 = false
					if Tools.isEmpty(mail) == false and Tools.isEmpty(mail.planet_report) == false then
						local exchange = false
						if mail.planet_report.type == 2 or mail.planet_report.type == 7 or  mail.planet_report.type == 9 or  mail.planet_report.type == 11 or  mail.planet_report.type == 13 then
							exchange = true
							switchGroup1 = true
						end
						if Tools.isEmpty(mail.planet_report.enemy_data_list) == false then
							if Tools.isEmpty(mail.planet_report.enemy_data_list[1].info) == false then
								enemyName = mail.planet_report.enemy_data_list[1].info.nickname
								enemyIconPath = "HeroImage/"..mail.planet_report.enemy_data_list[1].info.icon_id..".png"
							else
								if mail.planet_report.type == 14 then
									local cfg_boss = CONF.PLANETBOSS.get(mail.planet_report.id)
									enemyName = cfg_boss.NAME
									enemyIconPath = "PlanetIcon/"..cfg_boss.ICON..".png"
								end
							end
						else
							if mail.planet_report.type == 12 then
								local cfg_city = CONF.PLANETCITY.get(mail.planet_report.id)
								enemyIconPath = "PlanetIcon/"..cfg_city.ICON..".png"
								enemyName = cfg_city.NAME
							end
						end
						if Tools.isEmpty(mail.planet_report.my_data_list) == false and Tools.isEmpty(mail.planet_report.my_data_list[1].info) == false then
							myName = mail.planet_report.my_data_list[1].info.nickname
							myIconPath = "HeroImage/"..mail.planet_report.my_data_list[1].info.icon_id..".png"
						end
					end
					app:pushToRootView("BattleScene/BattleScene", { 
						from = self.from, 
						switchGroup = switchGroup1,
						BattleType.kMailVideo, 
						Tools.decode("PvpVideoResp",strData).data.resp, 
						false,
						enemyName,
						enemyIconPath,
						nil,
						myName,
						myIconPath,
					})
				else
					
				end
			end
		end
	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	animManager:runAnimOnceByCSB(self:getResourceNode(), "BattleScene/FailedLayer/FailedLayer.csb", "star_intro")

end

function MailVideoFailedLayer:onExitTransitionStart()
	printInfo("MailVideoFailedLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

end


return MailVideoFailedLayer