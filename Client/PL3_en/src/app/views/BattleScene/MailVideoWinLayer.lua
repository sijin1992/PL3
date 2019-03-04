local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local MailVideoWinLayer = class("MailVideoWinLayer", cc.load("mvc").ViewBase)

MailVideoWinLayer.RESOURCE_FILENAME = "BattleScene/WinLayer/WinLayer.csb"

MailVideoWinLayer.NEED_ADJUST_POSITION = true

MailVideoWinLayer.mail_info = {}

MailVideoWinLayer.RESOURCE_BINDING = {
	["backk"]={["varname"]="",["events"]={{["event"]="touch",["method"]="OnBtnClick"}}},
}


local schedulerEntry = nil

function MailVideoWinLayer:OnBtnClick(event)
	printInfo(event.name)

	if event.name == "ended" and event.target:getName() == "backk" then

		playMusic("sound/main.mp3", true)
		playEffectSound("sound/system/click.mp3")
		local video = tonumber(Tools.split(g_MailGuid_VideoPosition,'_')[2])
		if Tools.isEmpty(self.mail_info) == false and Tools.isEmpty(self.mail_info.planet_report.video_key_list) == false and self.mail_info.planet_report.video_key_list[video+1] then
			g_MailGuid_VideoPosition = self.mail_info.guid..'_'..(video+1)
			local strData = Tools.encode("PvpVideoReq", {
				video_key = self.mail_info.planet_report.video_key_list[video+1],
			})
			GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_PVP_VIDEO_REQ"),strData)

		else
			playEffectSound("sound/system/click.mp3")
			local from = ''
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

function MailVideoWinLayer:init(data, ship_list,from)
	self.data = data
	self.from = from
	self.ship_list = ship_list
end

function MailVideoWinLayer:touchLayer()
	local function onTouchBegan(touch, event)

		return true
	end

	local function onTouchEnded( touch, event )

		if self:getParent():getChildByName("layer_2") == nil then
			-- local layer = self:createLayer2()
			-- self:getParent():addChild(layer)
			-- layer:setName("layer_2")
			-- local center = cc.exports.VisibleRect:center()
			-- layer:setAnchorPoint(cc.p(0.5 ,0.5))
			-- layer:setPosition(center)
			-- self:setVisible(false)

			-- self.touch_ = true
		end
	end


	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(false)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function MailVideoWinLayer:onEnterTransitionFinish()
	printInfo("WinLayer:onEnterTransitionFinish()")

	for i,v in pairs(g_Planet_Info) do
		print("g_Planet_Info",i,v)
	end

	playEffectSound("sound/system/win.mp3")

	self.ani_ = false

	local rn = self:getResourceNode()
	local center = cc.exports.VisibleRect:center()
	rn:setAnchorPoint(cc.p(0.5 ,0.5))
	rn:setPosition(center)
	self:getResourceNode():getChildByName("backk"):getChildByName("text"):setString(CONF:getStringValue("back"))
	local mail_list = player.mail_list_
	local video = tonumber(Tools.split(g_MailGuid_VideoPosition,'_')[2])
	local guid = tonumber(Tools.split(g_MailGuid_VideoPosition,'_')[1])
	for k,v in ipairs(mail_list) do
		if v.guid == guid then
			self.mail_info = v
			break
		end
	end
	if Tools.isEmpty(self.mail_info) == false and Tools.isEmpty(self.mail_info.planet_report.video_key_list) == false and self.mail_info.planet_report.video_key_list[video+1] then
		self:getResourceNode():getChildByName("backk"):getChildByName("text"):setString(CONF:getStringValue("next_video"))
	end
	rn:getChildByName("ht1"):setString(CONF:getStringValue("my_hit")..":")
	rn:getChildByName("ht2"):setString(CONF:getStringValue("enemy_hit")..":")
	rn:getChildByName("ship1"):setString(CONF:getStringValue("my_ship")..":")
	rn:getChildByName("ship2"):setString(CONF:getStringValue("enemy_ship")..":")
	rn:getChildByName("time"):setString(CONF:getStringValue("fight_time")..":")

	local diff = 10
	rn:getChildByName("ht1_num"):setPositionX(rn:getChildByName("ht1"):getPositionX() + rn:getChildByName("ht1"):getContentSize().width + diff)
	rn:getChildByName("ht2_num"):setPositionX(rn:getChildByName("ht2"):getPositionX() + rn:getChildByName("ht2"):getContentSize().width + diff)
	rn:getChildByName("ship1_num"):setPositionX(rn:getChildByName("ship1"):getPositionX() + rn:getChildByName("ship1"):getContentSize().width + diff)
	rn:getChildByName("ship2_num"):setPositionX(rn:getChildByName("ship2"):getPositionX() + rn:getChildByName("ship2"):getContentSize().width + diff)
	rn:getChildByName("time_num"):setPositionX(rn:getChildByName("time"):getPositionX() + rn:getChildByName("time"):getContentSize().width + diff)

	rn:getChildByName("ht1_num"):setString(string.format("%d",self.data[3]))
	rn:getChildByName("ht2_num"):setString(string.format("%d",self.data[4]))
	
	rn:getChildByName("ship1_num"):setString(string.format("%d/%d",self.data[5],self.data[6]))
	rn:getChildByName("ship2_num"):setString(string.format("%d/%d",self.data[8]-self.data[7],self.data[8]))

	rn:getChildByName("time_num"):setString(formatTime(self.data[2]))

	rn:getChildByName("star_4"):setVisible(false)

	self.star = 3
	for i=1,4 do
		rn:getChildByName("star_"..i):setVisible(false)
	end
	rn:getChildByName("back"):addClickEventListener(function (sender)
		playEffectSound("sound/system/click.mp3")
		-- if self.ani_ then
		-- 	-- local layer = self:createLayer2()
		-- 	self:getParent():addChild(layer)
		-- 	layer:setName("layer_2")
		-- 	local center = cc.exports.VisibleRect:center()
		-- 	layer:setAnchorPoint(cc.p(0.5 ,0.5))
		-- 	layer:setPosition(center)
		-- 	self:setVisible(false)
		-- end
	end)

	local getMail  = function(guid)
		if Tools.isEmpty(player.mail_list_) then return nil end
		for i,v in ipairs(player.mail_list_) do
			if v.guid == guid then
				return v
			end
		end
		return nil
	end
	local function recvMsg()
		print("MailVideoWinLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id('CMD_DEFINE','CMD_PVP_VIDEO_RESP') then
			local proto = Tools.decode("PvpVideoResp",strData)
			if proto.result == 0 then
				if Tools.isEmpty(proto.data.resp.hurter_list) == false and Tools.isEmpty(proto.data.resp.attack_list) == false then
					local enemyName
					local enemyIconPath
					local myName
					local myIconPath
					local switchGroup1 = false
					local guid = tonumber(Tools.split(g_MailGuid_VideoPosition,'_')[1])
					local mail = getMail(guid )
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

	animManager:runAnimOnceByCSB(rn, "BattleScene/WinLayer/WinLayer.csb", "intro", function ( ... )
		self.ani_ = true
	end)

	rn:getChildByName("ship2_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ship2"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ship1_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ship1"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht2_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht2"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht1_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht1"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("time"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("time_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName('backk'):setVisible(true)
	rn:getChildByName("time"):setVisible(false)
	rn:getChildByName("time_num"):setVisible(false)
end

function MailVideoWinLayer:onExitTransitionStart()
	printInfo("MailVideoWinLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end


return MailVideoWinLayer