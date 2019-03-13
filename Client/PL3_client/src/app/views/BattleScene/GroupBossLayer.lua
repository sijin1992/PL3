local player = require("app.Player"):getInstance()

local app = require("app.MyApp"):getInstance()

local gl = require("util.GlobalLoading"):getInstance()

local animManager = require("app.AnimManager"):getInstance()

local scheduler = cc.Director:getInstance():getScheduler()

local GroupBossLayer = class("GroupBossLayer", cc.load("mvc").ViewBase)

GroupBossLayer.RESOURCE_FILENAME = "BattleScene/WinLayer/WinLayer.csb"

GroupBossLayer.NEED_ADJUST_POSITION = true

GroupBossLayer.RESOURCE_BINDING = {

}

local levelUp = false

local schedulerEntry = nil

function GroupBossLayer:OnBtnClick(event)
	printInfo(event.name)

end

function GroupBossLayer:init(id,data)
	self.id = id
	self.data = data
end


function GroupBossLayer:onEnterTransitionFinish()
	printInfo("GroupBossLayer:onEnterTransitionFinish()")

	playEffectSound("sound/system/win.mp3")

	self.touch_ = false

	-- resultData[1] = isWin
	-- resultData[2] = self:getFightTime()
	-- resultData[3] = self:getHitValue(1)
	-- resultData[4] = self:getHitValue(2)
	-- resultData[5] = self:getShipNum(1,true)
	-- resultData[6] = self:getShipNum(1,false)
	-- resultData[7] = self:getShipNum(2,true)
	-- resultData[8] = self:getShipNum(2,false)
	-- resultData[9] = self.round_

	local rn = self:getResourceNode()
	local center = cc.exports.VisibleRect:center()
	rn:setAnchorPoint(cc.p(0.5 ,0.5))
	rn:setPosition(center)

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

	if player:getCopyStar(self.id) ~= 0 then
		self.flag_ = true
	else
		self.flag_ = false
	end

	local shipNum = self.data[5]
	local shipNum_all = self.data[6]
	local round = self.data[9]


	for i=1,4 do
		rn:getChildByName("star_"..i):setVisible(false)
	end


	-- if self.star < 3 then

	--     for self.star,3 do
	--         rn:getChildByName("star_"..i):setTexture("BattleScene/WinLayer/ui_icon_start_0.png")
	--     end
	-- end

	rn:getChildByName("backk"):getChildByName("text"):setString(CONF:getStringValue("back"))

	rn:getChildByName("backk"):addClickEventListener(function ( sender )
		playEffectSound("sound/system/click.mp3")
		app:pushToRootView("StarLeagueScene/GroupBossScene", {group_list = player:getPlayerGroupMain()})
	end)

	local result = self.data[1]
	if result == 2 then
		result = 0
	end

	local strData = Tools.encode("GroupPVEOKReq", {
			group_boss_id = self.id,
			result = result,
			hurter_hp_list = self.data[11],
		})
	GameHandler.handler_c.send(Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_OK_REQ"),strData)

	gl:retainLoading()

	local function onTouchBegan(touch, event)

		return true
	end

	local listener = cc.EventListenerTouchOneByOne:create()
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )

	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

	local function recvMsg()
		print("GroupBossLayer:recvMsg")
		local cmd,strData = GameHandler.handler_c.recvProtobuf()

		if cmd == Tools.enum_id("CMD_DEFINE","CMD_GROUP_PVE_OK_RESP") then
			gl:releaseLoading()
			
			local proto = Tools.decode("GroupPVEOKResp",strData)
			printInfo("result"..proto.result)
		end

	end

	self.recvlistener_ = cc.EventListenerCustom:create(DEFINE_NET_ON_RECEVIE, recvMsg)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithFixedPriority(self.recvlistener_, FixedPriority.kNormal)

	animManager:runAnimOnceByCSB(rn, "BattleScene/WinLayer/WinLayer.csb", "intro")

	rn:getChildByName("ship2_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ship2"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ship1_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ship1"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht2_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht2"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht1_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("ht1"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("time"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2)))
	rn:getChildByName("time_num"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2), cc.CallFunc:create(function ( ... )
		
	end)))

	rn:getChildByName("backk"):runAction(cc.Sequence:create(cc.DelayTime:create(0.6), cc.FadeIn:create(0.2), cc.CallFunc:create(function ( ... )
		rn:getChildByName("backk"):setVisible(true)
	end)))

end

function GroupBossLayer:onExitTransitionStart()
	printInfo("GroupBossLayer:onExitTransitionStart()")

	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:removeEventListener(self.recvlistener_)

	if schedulerEntry ~= nil then
	  scheduler:unscheduleScriptEntry(schedulerEntry)
	end

end


return GroupBossLayer